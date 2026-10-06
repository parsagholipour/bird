import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/cloud_logbook.dart';
import 'package:push_up_bird/data/play_achievements.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

/// Play Games in memory: one cloud, one achievements list, and a log of
/// every call that would reach Google.
class FakePlayGames implements PlayGamesService {
  FakePlayGames({this.ready = true, this.signedInAtLaunch = true});
  bool ready, signedInAtLaunch, offline = false, signInWorks = true;
  String? cloud;

  /// The signed-in Play player's id; null when Play does not say.
  String? player = 'player-1';
  final held = <String, PlayAchievementState>{};
  final calls = <String>[];
  int saves = 0, loads = 0;

  void _reach() {
    if (offline) throw StateError('offline');
  }

  @override
  Future<bool> available() async => ready;
  @override
  Future<bool> signedIn() async {
    calls.add('signedIn');
    return signedInAtLaunch;
  }

  @override
  Future<bool> signIn() async {
    calls.add('signIn');
    return signInWorks;
  }

  @override
  Future<String?> playerId() async => player;

  @override
  Future<void> showAchievements() async => calls.add('show');
  @override
  Future<Map<String, PlayAchievementState>> achievements() async {
    _reach();
    calls.add('achievements');
    return {...held};
  }

  @override
  Future<void> unlock(String id) async {
    _reach();
    calls.add('unlock $id');
    _set(id, 0, unlocked: true);
  }

  /// Like Play: steps never go down, and reaching the total unlocks.
  @override
  Future<void> setSteps(String id, int steps) async {
    _reach();
    calls.add('steps $id $steps');
    final total = PlayAchievement.values.byName(id.substring(3)).goal;
    _set(id, steps, unlocked: steps >= total);
  }

  void _set(String id, int steps, {required bool unlocked}) {
    final old = held[id];
    if (old?.unlocked != true && unlocked) unlocks.add(id);
    held[id] = (
      steps: old == null || steps > old.steps ? steps : old.steps,
      unlocked: unlocked || old?.unlocked == true,
    );
  }

  @override
  Future<String?> loadLogbook() async {
    _reach();
    loads++;
    return cloud;
  }

  @override
  Future<void> saveLogbook(String data, String description) async {
    _reach();
    saves++;
    cloud = data;
    calls.add('save $description');
  }

  /// The unlocks Google showed its pop-up for, in order.
  final unlocks = <String>[];
}

class _NoSessions extends SessionRepository {
  @override
  Future<void> reset() async {}
}

/// Every achievement gets the id `id.<name>`.
final ids = {for (final a in PlayAchievement.values) a: 'id.${a.name}'};

class Phone {
  Phone(this.play, {Map<PlayAchievement, String>? achievementIds}) {
    container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(_NoSessions()),
        playGamesServiceProvider.overrideWithValue(play),
        playAchievementIdsProvider.overrideWithValue(achievementIds ?? ids),
        appClockProvider.overrideWithValue(() => now),
      ],
    );
  }
  final FakePlayGames play;
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  late final ProviderContainer container;
  DateTime now = DateTime(2026, 10, 6, 15);

  PlayGamesSync get sync => container.read(playGamesProvider.notifier);
  PlayGamesStatus get status => container.read(playGamesProvider);
  ProgressController get progress => container.read(progressProvider.notifier);

  void wait(Duration d) => now = now.add(d);

  int _n = 0;
  Future<void> fly({int stars = 10, int score = 5}) => progress.save(
    RunResult(
      id: 'run-${_n++}',
      mode: PlayMode.touch,
      course: FlightCourse.starTrail,
      practice: false,
      score: score,
      stars: stars,
      repetitions: 0,
      flaps: 3,
      durationSeconds: 20,
      reason: EndReason.collision,
      finishedAt: now,
      bird: 2,
    ),
  );

  Future<void> dispose() async {
    container.dispose();
    await repo.close();
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late List<Phone> phones;
  Future<Phone> phone(FakePlayGames play, {bool start = true}) async {
    final p = Phone(play);
    phones.add(p);
    await p.container.read(progressProvider.future);
    if (start) await p.sync.start();
    return p;
  }

  setUp(() => phones = []);
  tearDown(() async {
    for (final p in phones) {
      await p.dispose();
    }
  });

  test('unconfigured or unavailable: hidden and silent', () async {
    final play = FakePlayGames(ready: false);
    final p = await phone(play);
    await p.fly();
    await p.sync.calmMoment();
    await p.sync.paused();
    expect(p.status.available, isFalse);
    expect(p.status.connected, isFalse);
    expect(play.calls, isEmpty);
    expect(play.loads + play.saves, 0);
  });

  test('a declined automatic sign-in only shows Not connected', () async {
    final play = FakePlayGames(signedInAtLaunch: false);
    final p = await phone(play);
    await p.fly();
    await p.sync.calmMoment();
    expect(p.status.available, isTrue);
    expect(p.status.connected, isFalse);
    expect(play.calls, ['signedIn']);
  });

  test('launch restores, saves back and reports what is due', () async {
    final play = FakePlayGames();
    final p = await phone(play, start: false);
    await p.fly();
    await p.sync.start();
    expect(p.status.connected, isTrue);
    expect(play.loads, 1);
    expect(play.saves, 1);
    expect(p.status.savedAt, p.now);
    expect(Logbook.decode(play.cloud)!.devices, hasLength(1));
  });

  test('calm moments save at most once a minute, and only changes', () async {
    final play = FakePlayGames();
    final p = await phone(play);
    play.saves = 0;
    await p.sync.calmMoment();
    expect(play.saves, 0, reason: 'nothing changed');

    await p.fly();
    p.wait(const Duration(seconds: 20));
    await p.sync.calmMoment();
    expect(play.saves, 0, reason: 'too soon after the launch save');

    p.wait(const Duration(seconds: 41));
    await p.sync.calmMoment();
    expect(play.saves, 1);
    expect(p.status.savedAt, p.now);

    // The app going to the background saves at once.
    await p.fly();
    p.wait(const Duration(seconds: 5));
    await p.sync.paused();
    expect(play.saves, 2);
    expect(
      Logbook.decode(
        play.cloud,
      )!.devices.values.single.record('trailTouch').runs,
      2,
    );
  });

  test('one unlock pop-up per calm moment, silent steps every time', () async {
    final play = FakePlayGames();
    final p = await phone(play);
    // 60 stars: Star Chaser bronze (50); 15 in a streak would be
    // Constellation bronze, so add one long flight's best combo too.
    await p.progress.save(
      RunResult(
        id: 'big',
        mode: PlayMode.touch,
        course: FlightCourse.starTrail,
        practice: false,
        score: 120,
        stars: 60,
        bestCombo: 20,
        repetitions: 0,
        flaps: 3,
        durationSeconds: 70,
        reason: EndReason.collision,
        finishedAt: p.now,
        bird: 2,
      ),
    );
    play.calls.clear();
    await p.sync.calmMoment();
    expect(play.unlocks, hasLength(1));
    // Partial progress went out silently: flights, stars toward silver.
    expect(play.calls, contains('steps id.frequentFlyerBronze 1'));
    expect(play.calls, contains('steps id.starChaserSilver 60'));
    final first = play.unlocks.single;

    await p.sync.calmMoment();
    expect(play.unlocks, hasLength(2));
    expect(play.unlocks.last, isNot(first));
    await p.sync.calmMoment();
    expect(play.unlocks, hasLength(3));
    final before = play.calls.length;
    await p.sync.calmMoment();
    // Nothing new: nothing sent.
    expect(play.calls.length, before);
    // In table order, one a moment.
    expect(play.unlocks, [
      'id.starChaserBronze',
      'id.constellationBronze',
      'id.skyCaptainBronze',
    ]);
  });

  test('what Play already holds is never sent again', () async {
    final play = FakePlayGames()
      ..held['id.starChaserBronze'] = (steps: 50, unlocked: true);
    final p = await phone(play, start: false);
    await p.fly(stars: 55);
    await p.sync.start();
    await p.sync.calmMoment();
    expect(play.unlocks, isNot(contains('id.starChaserBronze')));
  });

  test('Connect catches up: merge, then every unlock at once', () async {
    final play = FakePlayGames(signedInAtLaunch: false);
    final p = await phone(play);
    await p.progress.save(
      RunResult(
        id: 'big',
        mode: PlayMode.touch,
        course: FlightCourse.starTrail,
        practice: false,
        score: 600,
        stars: 60,
        bestCombo: 20,
        repetitions: 0,
        flaps: 3,
        durationSeconds: 70,
        reason: EndReason.collision,
        finishedAt: p.now,
        bird: 2,
      ),
    );
    play.signInWorks = false;
    expect(await p.sync.connect(), isFalse);
    expect(p.status.connected, isFalse);

    play.signInWorks = true;
    expect(await p.sync.connect(), isTrue);
    expect(p.status.connected, isTrue);
    expect(play.saves, 1);
    expect(play.unlocks.toSet(), {
      'id.starChaserBronze',
      'id.constellationBronze',
      'id.skyCaptainBronze',
      'id.skyCaptainSilver',
    });
    expect(
      play.unlocks.indexOf('id.skyCaptainBronze'),
      lessThan(play.unlocks.indexOf('id.skyCaptainSilver')),
    );
  });

  test('offline: the change waits and goes at the next calm moment', () async {
    final play = FakePlayGames();
    final p = await phone(play);
    play.saves = 0;
    play.offline = true;
    p.wait(const Duration(minutes: 2));
    await p.fly();
    await p.sync.calmMoment();
    expect(play.saves, 0);
    expect(p.status.offline, isTrue);
    expect(p.status.connected, isTrue);

    play.offline = false;
    p.wait(const Duration(seconds: 5));
    await p.sync.calmMoment();
    expect(play.saves, 1);
    expect(p.status.offline, isFalse);
    expect(
      Logbook.decode(
        play.cloud,
      )!.devices.values.single.record('trailTouch').runs,
      1,
    );
  });

  test('a second phone restores, and a reset clears the cloud', () async {
    final play = FakePlayGames();
    final a = await phone(play);
    await a.fly(stars: 300);
    a.wait(const Duration(minutes: 2));
    await a.sync.calmMoment();

    final b = await phone(play);
    expect(b.status.restored, isTrue);
    expect((await b.container.read(progressProvider.future)).starsEarned, 300);

    b.wait(const Duration(minutes: 3));
    await b.progress.reset();
    // Runs after the reset's own sync.
    await b.sync.paused();
    // The fresh logbook has gone up at once.
    final cloud = Logbook.decode(play.cloud)!;
    expect(
      cloud.devices.values.every(
        (d) => d.records.values.every((r) => r.runs == 0),
      ),
      isTrue,
    );
    expect((await b.container.read(progressProvider.future)).starsEarned, 0);
  });

  test('a newer logbook format is never written over', () async {
    final play = FakePlayGames();
    final p = await phone(play, start: false);
    play.cloud = const _Newer().encode();
    await p.sync.start();
    expect(play.saves, 0);
    // Connected, not offline: the strip asks for an update.
    expect(p.status.offline, isFalse);
    expect(p.status.updateNeeded, isTrue);
  });
}

/// A logbook from a future build.
class _Newer extends Logbook {
  const _Newer();
  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'schema': 99};
}
