import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'play_games_sync_test.dart' show FakePlayGames, Phone;

/// Play turning down single achievements, the way the games_services plugin
/// reports it: a PlatformException whose message starts with Play's status
/// code.
class _Picky extends FakePlayGames {
  /// What Play answers for an id instead of taking it.
  final refuse = <String, Object>{};

  /// Every unlock or steps call, failed or not.
  final tried = <String>[];

  void _check(String id) {
    tried.add(id);
    if (refuse[id] case final e?) throw e;
  }

  @override
  Future<void> unlock(String id) async {
    _check(id);
    await super.unlock(id);
  }

  @override
  Future<void> setSteps(String id, int steps) async {
    _check(id);
    await super.setSteps(id, steps);
  }
}

/// GamesClientStatusCodes.ACHIEVEMENT_NOT_INCREMENTAL: made "standard" in
/// Play Console while the code sends steps.
final _notIncremental = PlatformException(
  code: 'failed_to_set_achievement_steps',
  message: '26562: ',
);

/// GamesClientStatusCodes.ACHIEVEMENT_UNKNOWN: a mistyped id.
final _unknown = PlatformException(
  code: 'failed_to_send_achievement',
  message: '26561: ',
);

/// CommonStatusCodes.NETWORK_ERROR.
final _network = PlatformException(
  code: 'failed_to_send_achievement',
  message: '7: ',
);

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

  // Earns Star Chaser, Constellation and Sky Captain bronze, and partial
  // steps toward the Frequent Flyer tiers and Star Chaser silver.
  Future<void> bigFlight(Phone p) => p.progress.save(
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

  test('ids Play turns down are skipped for the session, the rest go on, '
      'one pop-up a calm moment', () async {
    // A whole family made "standard" by mistake, and a mistyped id.
    final play = _Picky()
      ..refuse['id.frequentFlyerBronze'] = _notIncremental
      ..refuse['id.frequentFlyerSilver'] = _notIncremental
      ..refuse['id.frequentFlyerGold'] = _notIncremental
      ..refuse['id.starChaserSilver'] = _unknown;
    final p = await phone(play);
    await bigFlight(p);

    await p.sync.calmMoment();
    expect(play.unlocks, ['id.starChaserBronze']);
    await p.sync.calmMoment();
    await p.sync.calmMoment();
    await p.sync.calmMoment();
    expect(play.unlocks, [
      'id.starChaserBronze',
      'id.constellationBronze',
      'id.skyCaptainBronze',
    ]);
    // Each rejected id was tried once, not at every calm moment.
    for (final id in play.refuse.keys) {
      expect(play.tried.where((t) => t == id), hasLength(1), reason: id);
    }
  });

  test('an unfamiliar error skips only that id, and it is tried again '
      'next time', () async {
    final play = _Picky()
      ..refuse['id.frequentFlyerBronze'] = PlatformException(
        code: 'failed_to_set_achievement_steps',
        message: '8: ',
      );
    final p = await phone(play);
    await bigFlight(p);

    await p.sync.calmMoment();
    expect(play.unlocks, ['id.starChaserBronze']);

    play.refuse.clear();
    await p.sync.calmMoment();
    expect(play.calls, contains('steps id.frequentFlyerBronze 1'));
  });

  test('offline: a few tries, then the rest waits, and nothing is '
      'skipped for good', () async {
    final play = _Picky();
    final p = await phone(play);
    await bigFlight(p);

    for (final a in ['frequentFlyerBronze', 'frequentFlyerSilver']) {
      play.refuse['id.$a'] = _network;
    }
    play.offline = true;
    await p.sync.calmMoment();
    expect(play.tried, hasLength(3));
    expect(play.unlocks, isEmpty);

    play.offline = false;
    play.refuse.clear();
    p.wait(const Duration(minutes: 2));
    await p.sync.calmMoment();
    expect(play.unlocks, ['id.starChaserBronze']);
    expect(play.calls, contains('steps id.frequentFlyerBronze 1'));
    expect(play.calls, contains('steps id.frequentFlyerSilver 1'));
  });

  test('a call Play never answers stops the round at once', () async {
    final play = _Picky()
      ..refuse['id.frequentFlyerBronze'] = TimeoutException('no answer');
    final p = await phone(play);
    await bigFlight(p);

    await p.sync.calmMoment();
    expect(play.tried, ['id.frequentFlyerBronze']);
    expect(play.unlocks, isEmpty);
  });
}
