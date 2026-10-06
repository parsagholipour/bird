import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/cloud_logbook.dart';
import 'package:push_up_bird/data/providers.dart';

import 'play_games_sync_test.dart' show FakePlayGames, Phone;

// A reset asks for the cloud save to go (its dialog says so), so its fresh
// logbook replaces even a cloud save this phone cannot read: a damaged one,
// or a newer Beakbound's, which then reads the higher epoch and starts
// afresh too. Normal syncs still never write over either.

const _garbage = 'not a logbook this build can read';

/// A logbook from a future build.
class _Newer extends Logbook {
  const _Newer();
  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'schema': 99};
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late List<Phone> phones;
  Future<Phone> phone(FakePlayGames play) async {
    final p = Phone(play);
    phones.add(p);
    await p.container.read(progressProvider.future);
    await p.sync.start();
    return p;
  }

  setUp(() => phones = []);
  tearDown(() async {
    for (final p in phones) {
      await p.dispose();
    }
  });

  Future<int> stars(Phone p) async =>
      (await p.container.read(progressProvider.future)).starsEarned;

  /// A phone that synced 30 stars, whose cloud then turned to [cloud]; a
  /// sync since showed it cannot read it.
  Future<(Phone, FakePlayGames)> stuck(String cloud) async {
    final play = FakePlayGames();
    final p = await phone(play);
    await p.fly(stars: 30);
    await p.sync.paused();
    expect(Logbook.decode(play.cloud), isNotNull);
    play.cloud = cloud;
    await p.fly();
    p.wait(const Duration(minutes: 2));
    await p.sync.calmMoment();
    expect(play.cloud, cloud, reason: 'a normal sync never writes over it');
    return (p, play);
  }

  /// Resets from Settings, and waits for the cloud to follow.
  Future<void> reset(Phone p) async {
    await p.progress.reset();
    await p.sync.calmMoment();
  }

  test('a damaged cloud save goes with a reset, and only with one', () async {
    final (p, play) = await stuck(_garbage);
    expect(p.status.unreadable, isTrue);

    await reset(p);
    final fresh = Logbook.decode(play.cloud)!;
    expect(fresh.isEmpty, isTrue);
    expect(fresh.epoch, greaterThan(0));
    expect(p.status.unreadable, isFalse);
    expect(p.status.offline, isFalse);
    expect(p.status.savedAt, p.now);
    expect(await stars(p), 0);

    // Damaged again later: normal syncs leave it alone once more.
    play.cloud = _garbage;
    await p.fly();
    p.wait(const Duration(minutes: 2));
    await p.sync.calmMoment();
    await p.fly();
    await p.sync.paused();
    expect(play.cloud, _garbage);
    expect(p.status.unreadable, isTrue);
  });

  test('a newer build\'s cloud save goes with a reset, and that phone '
      'starts afresh too', () async {
    // B shares the account; it updates to a newer Beakbound later.
    final play = FakePlayGames();
    final a = await phone(play);
    await a.fly(stars: 30);
    await a.sync.paused();
    final b = await phone(play);
    expect(await stars(b), 30);
    await b.fly(stars: 5);
    await b.sync.paused();

    // B's newer build saved a logbook A cannot read.
    play.cloud = const _Newer().encode();
    await a.fly();
    a.wait(const Duration(minutes: 2));
    await a.sync.calmMoment();
    expect(a.status.updateNeeded, isTrue);

    await reset(a);
    final fresh = Logbook.decode(play.cloud)!;
    expect(fresh.isEmpty, isTrue);
    expect(fresh.epoch, greaterThan(0));
    expect(a.status.updateNeeded, isFalse);

    // B reads the higher epoch at its next sync: a fresh adventure there.
    await b.fly(stars: 3);
    await b.sync.paused();
    expect(b.status.resetElsewhere, isTrue);
    expect(await stars(b), 0);
  });

  test(
    'a reset made offline still replaces it once the cloud answers',
    () async {
      final (p, play) = await stuck(_garbage);
      play.offline = true;
      await reset(p);
      expect(p.status.offline, isTrue);
      expect(play.cloud, _garbage);

      play.offline = false;
      p.wait(const Duration(minutes: 2));
      await p.sync.calmMoment();
      expect(Logbook.decode(play.cloud)!.isEmpty, isTrue);
      expect(p.status.unreadable, isFalse);
    },
  );

  test('another player\'s unreadable cloud is never replaced, even by a '
      'reset', () async {
    final play = FakePlayGames();
    final p = await phone(play);
    await p.fly(stars: 30);
    await p.sync.paused();
    // Now signed in as someone this phone never synced with.
    play
      ..player = 'player-2'
      ..cloud = _garbage;
    await reset(p);
    expect(play.cloud, _garbage);
    expect(p.status.unreadable, isTrue);
  });
}
