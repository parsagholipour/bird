import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/cloud_logbook.dart';
import 'package:push_up_bird/data/providers.dart';

import 'play_games_sync_test.dart' show FakePlayGames, Phone;

/// A logbook from a future build.
class _Newer extends Logbook {
  const _Newer();
  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'schema': 99};
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

  test('a cloud save from a newer build: connected, quiet, and throttled '
      'like any sync', () async {
    final play = FakePlayGames()..cloud = const _Newer().encode();
    final newer = play.cloud;
    final p = await phone(play);
    expect(p.status.connected, isTrue);
    expect(p.status.offline, isFalse);
    expect(p.status.updateNeeded, isTrue);
    expect(play.loads, 1);

    // New progress: not again within the minute, then once.
    await p.fly();
    p.wait(const Duration(seconds: 20));
    await p.sync.calmMoment();
    expect(play.loads, 1);
    p.wait(const Duration(minutes: 1));
    await p.sync.calmMoment();
    expect(play.loads, 2);

    // Calm moments with nothing new here leave the cloud alone.
    for (var i = 0; i < 3; i++) {
      p.wait(const Duration(minutes: 2));
      await p.sync.calmMoment();
    }
    await p.sync.paused();
    expect(play.loads, 2);
    expect(p.status.updateNeeded, isTrue);
    expect(play.saves, 0);
    expect(play.cloud, newer);
  });

  test('an empty phone and an empty cloud claim no save', () async {
    final play = FakePlayGames();
    final p = await phone(play);
    expect(play.saves, 0);
    expect(p.status.connected, isTrue);
    expect(p.status.savedAt, isNull, reason: 'the strip says Cloud save is on');
    final memory = jsonDecode((await p.repo.loadPlayGamesMemory())!) as Map;
    expect(memory.containsKey('savedAt'), isFalse);

    // The first real progress is saved, and says so.
    await p.fly();
    p.wait(const Duration(minutes: 2));
    await p.sync.calmMoment();
    expect(play.saves, 1);
    expect(p.status.savedAt, p.now);
  });

  test('the launch and the first screen share one pop-up', () async {
    final play = FakePlayGames();
    final p = await phone(play, start: false);
    // Star Chaser bronze (60 stars) and Sky Captain bronze (score 120).
    await p.fly(stars: 60, score: 120);

    // As the app does: start() in initState, and the router announces home
    // while it runs.
    final launch = p.sync.start();
    final home = p.sync.calmMoment();
    await Future.wait([launch, home]);
    expect(play.unlocks, hasLength(1));

    // The next calm moment shows the next one.
    await p.sync.calmMoment();
    expect(play.unlocks, hasLength(2));
  });

  test('a launch with no calm moment behind it still reports', () async {
    final play = FakePlayGames();
    final p = await phone(play, start: false);
    await p.fly(stars: 60);
    await p.sync.start();
    expect(play.unlocks, ['id.starChaserBronze']);
  });
}
