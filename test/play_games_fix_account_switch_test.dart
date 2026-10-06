import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/cloud_logbook.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'play_games_sync_test.dart' show FakePlayGames;

// Switching Play Games accounts never loses anyone's progress (re-review
// N1): this phone's sync flag and epoch belong to the player it last synced
// with, so another player's cloud is merged with, never wiped from or
// replaced by.

/// Play's saved games: one cloud per player id.
typedef _Google = Map<String, String?>;

/// One phone's Play Games: the cloud is the signed-in player's.
class _Account extends FakePlayGames {
  _Account(this.google);
  final _Google google;

  @override
  String? get cloud => google[player];
  @override
  set cloud(String? data) => google[player!] = data;
}

class _NoSessions extends SessionRepository {
  @override
  Future<void> reset() async {}
}

/// A phone running the app: its own save, which outlives each launch.
class _Phone {
  _Phone(_Google google) : play = _Account(google);
  final _Account play;
  DateTime now = DateTime(2026, 10, 6, 15);
  late final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
    clock: () => now,
  );
  ProviderContainer? _container;
  ProviderContainer get container => _container!;

  PlayGamesSync get sync => container.read(playGamesProvider.notifier);
  PlayGamesStatus get status => container.read(playGamesProvider);
  ProgressController get progress => container.read(progressProvider.notifier);
  Future<int> get stars async =>
      (await container.read(progressProvider.future)).starsEarned;

  /// Opens the app (again) signed in as [player] (null: Play does not say
  /// who): the launch check and its sync.
  Future<void> launch(String? player) async {
    _container?.dispose();
    play.player = player;
    now = now.add(const Duration(minutes: 5));
    _container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(_NoSessions()),
        playGamesServiceProvider.overrideWithValue(play),
        playAchievementIdsProvider.overrideWithValue(const {}),
        appClockProvider.overrideWithValue(() => now),
      ],
    );
    await container.read(progressProvider.future);
    await sync.start();
  }

  int _n = 0;

  /// One flight worth [stars], saved to the cloud as the app is paused.
  Future<void> fly(int stars) async {
    now = now.add(const Duration(minutes: 2));
    await progress.save(
      RunResult(
        id: 'run-${_n++}',
        mode: PlayMode.touch,
        course: FlightCourse.starTrail,
        practice: false,
        score: 20,
        stars: stars,
        repetitions: 0,
        flaps: 5,
        durationSeconds: 30,
        reason: EndReason.collision,
        finishedAt: now,
        bird: 2,
      ),
    );
    await sync.paused();
  }

  /// Resets, then lets the cloud follow.
  Future<void> reset() async {
    await progress.reset();
    await sync.paused();
  }

  Future<void> dispose() async {
    _container?.dispose();
    await repo.close();
  }
}

/// The stars in a cloud save: every phone's row added up.
int _stars(String? cloud) =>
    Logbook.decode(cloud)?.devices.values
        .expand((d) => d.records.values)
        .fold<int>(0, (n, r) => n + r.stars) ??
    0;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late List<_Phone> phones;
  late _Google google;
  _Phone phone() {
    final p = _Phone(google);
    phones.add(p);
    return p;
  }

  setUp(() {
    phones = [];
    google = {};
  });
  tearDown(() async {
    for (final p in phones) {
      await p.dispose();
    }
  });

  /// Y's cloud: 21 stars, after a reset (a higher epoch than X's).
  Future<_Phone> resetAccountY() async {
    final y = phone();
    await y.launch('Y');
    await y.fly(50);
    await y.reset();
    await y.fly(21);
    expect(_stars(google['Y']), 21);
    expect(Logbook.decode(google['Y'])!.epoch, greaterThan(0));
    return y;
  }

  test('the reviewer\'s steps: X keeps its 300 stars, on the phone and in '
      'its cloud', () async {
    final y = await resetAccountY();
    // 1. The phone has 300 stars, synced to X.
    final a = phone();
    await a.launch('X');
    await a.fly(300);
    expect(_stars(google['X']), 300);

    // 2. Signed in as Y, whose cloud was reset once: no fresh start, the
    // phone's progress joins Y's, and X's cloud is left alone.
    await a.launch('Y');
    expect(a.status.resetElsewhere, isFalse);
    expect(await a.stars, 321);
    expect(_stars(google['Y']), 321);
    expect(_stars(google['X']), 300);

    // 3. Back to X: its cloud is merged with, not replaced.
    await a.launch('X');
    expect(a.status.resetElsewhere, isFalse);
    expect(await a.stars, 321);
    expect(_stars(google['X']), 321);

    // Y's own phone keeps what it had.
    await y.launch('Y');
    expect(y.status.resetElsewhere, isFalse);
    expect(await y.stars, 321);
  });

  test('a fresh account takes the phone\'s progress, not its reset: that '
      'account\'s other phone is never wiped', () async {
    final a = phone(), b = phone();
    await a.launch('X');
    await a.fly(300);
    await a.reset();
    await a.fly(30);
    expect(Logbook.decode(google['X'])!.epoch, greaterThan(0));
    // B belongs to a new account Z: synced once, nothing to save yet.
    await b.launch('Z');
    expect(google['Z'], isNull);

    await a.launch('Z');
    expect(await a.stars, 30);
    expect(_stars(google['Z']), 30);
    expect(Logbook.decode(google['Z'])!.epoch, 0);

    await b.fly(40);
    expect(b.status.resetElsewhere, isFalse);
    expect(await b.stars, 70);
    expect(_stars(google['Z']), 70);
    expect(_stars(google['X']), 30);
  });

  test('back and forth: everything is kept, and it settles', () async {
    await resetAccountY();
    final a = phone();
    await a.launch('X');
    await a.fly(100);
    await a.launch('Y');
    await a.fly(20);
    for (var i = 0; i < 3; i++) {
      await a.launch('X');
      expect(a.status.resetElsewhere, isFalse);
      await a.launch('Y');
      expect(a.status.resetElsewhere, isFalse);
    }
    expect(await a.stars, 141);
    expect(_stars(google['X']), 141);
    expect(_stars(google['Y']), 141);

    // Nothing new: no more cloud writes either way.
    final saves = a.play.saves;
    await a.launch('X');
    await a.launch('Y');
    expect(a.play.saves, saves);
    expect(await a.stars, 141);
  });

  test('a reset on X still reaches X\'s other phone, and only X', () async {
    final a = phone(), b = phone();
    await a.launch('X');
    await a.fly(100);
    await b.launch('X');
    expect(await b.stars, 100);
    await b.fly(10);
    // A visits Y and comes back to X.
    await a.launch('Y');
    expect(_stars(google['Y']), 100);
    await a.launch('X');
    expect(await a.stars, 110);

    await a.reset();
    expect(await a.stars, 0);
    expect(_stars(google['X']), 0);
    await b.launch('X');
    expect(b.status.resetElsewhere, isTrue);
    expect(await b.stars, 0);
    // Y's cloud is another player's: the reset leaves it alone.
    expect(_stars(google['Y']), 100);
    // And A back on X keeps the fresh start.
    await a.launch('X');
    expect(await a.stars, 0);
  });

  test('no player id: no sync this round, and nothing is lost', () async {
    await resetAccountY();
    final a = phone();
    await a.launch('X');
    await a.fly(100);
    final (loads, saves) = (a.play.loads, a.play.saves);

    await a.launch(null);
    await a.fly(20);
    await a.sync.calmMoment();
    expect((a.play.loads, a.play.saves), (loads, saves));
    expect(await a.stars, 120);
    expect(_stars(google['X']), 100);

    // Play says who again: the sync goes on as before.
    await a.launch('X');
    expect(await a.stars, 120);
    expect(_stars(google['X']), 120);
  });
}
