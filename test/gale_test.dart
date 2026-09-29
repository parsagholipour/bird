import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/replay_highlights.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'boss_fight_test.dart' show arena, step, hover, hitBoss;
import 'power_shot_test.dart' show flight;
import 'recorded_flight.dart';

const birdX = FlightSimulation.birdX;

/// A current touch flight the moment the boss numbered [bossesDefeated] + 1
/// has flown off after its defeat.
FlightSimulation bossDown({int bossesDefeated = 2}) {
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..bossesDefeated = bossesDefeated;
  step(sim);
  final boss = sim.boss!;
  hover(sim, boss.arrivalDuration + .1);
  hitBoss(sim, count: boss.hp ~/ BirdRock.baseDamage + 2);
  for (var i = 0; i < 500 && sim.boss != null; i++) {
    hover(sim, .02);
  }
  expect(sim.boss, isNull);
  return sim;
}

/// Flies level at [y], untouchable, until [until] or [seconds] pass.
void cruise(
  FlightSimulation sim,
  double seconds, {
  double y = .5,
  bool Function()? until,
}) {
  sim.invulnerableUntil = double.infinity;
  for (var i = 0; i < (seconds / .02).round(); i++) {
    if (until?.call() ?? false) return;
    sim.birdY = y;
    sim.velocity = 0;
    step(sim);
  }
}

/// A flight whose gale has just started blowing.
FlightSimulation blowing() {
  final sim = bossDown();
  cruise(sim, 40, until: () => sim.gale?.phase == GalePhase.blowing);
  expect(sim.gale!.phase, GalePhase.blowing);
  sim.invulnerableUntil = 0;
  return sim;
}

/// Holds the bird clear of every piece of debris, as a sharp player would.
void dodge(FlightSimulation sim, double seconds, {bool Function()? until}) {
  for (var i = 0; i < (seconds / .02).round(); i++) {
    if (until?.call() ?? false) return;
    final threats = sim.galeDebris.where(
      (d) => d.hitAt == null && !d.dodged && d.x > birdX - .1,
    );
    double clearance(double lane) => threats.fold(
      1.0,
      (least, d) => (lane - d.y).abs() < least ? (lane - d.y).abs() : least,
    );
    var best = sim.birdY, room = clearance(best);
    for (var lane = .15; lane <= .85; lane += .05) {
      if (clearance(lane) > room + .02) {
        best = lane;
        room = clearance(lane);
      }
    }
    sim.birdY = best;
    sim.velocity = 0;
    step(sim);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gales belong to current touch Star Trail flights only', () {
    expect(flight().supportsGales, isTrue);
    expect(flight(version: 32).supportsGales, isFalse);
    for (final rules in [JumpFlyMode(), PushUpFlightMode(cycleSeconds: 3)]) {
      expect(
        FlightSimulation(
          rules: rules,
          practice: true,
          course: FlightCourse.starTrail,
        ).supportsGales,
        isFalse,
      );
    }
    expect(
      FlightSimulation(rules: TapFlyMode(), practice: true).supportsGales,
      isFalse,
    );
  });

  test('only the Dusk Empress brings a gale, after a stretch of walls', () {
    for (final defeated in [0, 1]) {
      final sim = bossDown(bossesDefeated: defeated);
      cruise(sim, 30);
      expect(sim.galesBlown, 0, reason: 'boss ${defeated + 1}');
      expect(sim.rushPathsRun, 1, reason: 'boss ${defeated + 1}');
    }
    final sim = bossDown();
    final leftAt = sim.elapsed;
    cruise(sim, Gale.afterBoss - .1);
    expect(sim.gale, isNull);
    expect(sim.gates + sim.obstacles.length, greaterThanOrEqualTo(4));
    cruise(sim, .2);
    final gale = sim.gale!;
    expect(sim.elapsed - leftAt, closeTo(Gale.afterBoss, .1));
    expect(gale.phase, GalePhase.approach);
    // The wind rises only once the last wall is behind the bird.
    final last = sim.obstacles.last;
    expect(
      gale.startDistance,
      greaterThanOrEqualTo(
        sim.distance + last.x + last.width + Gale.clearance - 1e-9,
      ),
    );
    final walls = sim.obstacles.length;
    cruise(sim, 3);
    expect(sim.obstacles.length, lessThanOrEqualTo(walls));
    expect(sim.rushPath, isNull);
  });

  test('a banner warns ahead of the start, then the tailwind surges', () {
    final sim = bossDown();
    cruise(sim, 30, until: () => sim.galeWarnings > 0);
    final gale = sim.gale!;
    expect(sim.events.last.kind, FlightEventKind.galeWarning);
    expect(
      gale.startDistance - sim.distance - birdX,
      closeTo(Gale.warningLead, .02),
    );
    expect(sim.courseBoost, 1);
    cruise(sim, 10, until: () => gale.phase == GalePhase.blowing);
    expect(sim.obstacles.where((o) => o.x + o.width > birdX), isEmpty);
    cruise(sim, Gale.riseSeconds + .05);
    expect(sim.courseBoost, closeTo(Gale.peakBoost, 1e-6));
    expect(sim.galeBoost, closeTo(Gale.peakBoost, 1e-6));
  });

  test('each gust is warned off screen and aimed at the bird; odd gusts '
      'close off one side', () {
    final sim = blowing();
    final gale = sim.gale!;
    for (var gust = 0; gust < 6; gust++) {
      final y = gust.isEven ? .3 : .7;
      final before = sim.galeDebris.toSet();
      for (var i = 0; i < 200 && gale.gusts == gust; i++) {
        sim.birdY = y;
        sim.velocity = 0;
        sim.invulnerableUntil = double.infinity;
        step(sim);
      }
      final fresh = [
        for (final d in sim.galeDebris)
          if (!before.contains(d)) d,
      ];
      expect(fresh, hasLength(gust.isOdd ? 2 : 1), reason: 'gust $gust');
      expect(fresh.first.y, closeTo(y, .005));
      final scroll = sim.speed * sim.courseBoost;
      expect(
        fresh.first.entersIn(2.2, scroll),
        closeTo(GaleDebris.warningSeconds, .03),
      );
      if (gust.isOdd) {
        final spread = (fresh.last.y - fresh.first.y).abs();
        expect(spread, greaterThanOrEqualTo(Gale.pairSpread - 1e-9));
        expect(fresh.last.y, inInclusiveRange(Gale.top, Gale.bottom));
      }
    }
  });

  test('the walls stay away while it blows, then return as it calms', () {
    final sim = blowing();
    final gale = sim.gale!;
    final startedAt = gale.startedAt!;
    cruise(sim, Gale.seconds - .1);
    expect(sim.obstacles.where((o) => o.x + o.width > birdX), isEmpty);
    expect(gale.phase, GalePhase.blowing);
    final lastGust = sim.galeDebris.isEmpty ? null : sim.galeDebris.last;
    cruise(sim, .2);
    expect(gale.phase, GalePhase.weathered);
    expect(gale.weatheredAt! - startedAt, closeTo(Gale.seconds, .02));
    // Gusts stop before the end so the last pieces clear the screen.
    if (lastGust != null) expect(lastGust.age, greaterThan(1));
    cruise(sim, Gale.fallSeconds * .5);
    expect(sim.courseBoost, inExclusiveRange(1, Gale.peakBoost));
    expect(sim.obstacles, isNotEmpty);
    cruise(sim, Gale.fallSeconds);
    expect(sim.gale, isNull);
    expect(sim.courseBoost, 1);
  });

  test('debris hurts on contact, even while sprinting; dodges score and a '
      'clean gale earns the flawless bonus', () {
    final hit = blowing()..shield = false;
    final hearts = hit.hearts;
    cruise(hit, 5, y: .5, until: () => hit.galeDebris.isNotEmpty);
    expect(hit.sprint(), isTrue);
    hit.invulnerableUntil = 0;
    for (var i = 0; i < 200 && hit.gale!.hits == 0; i++) {
      hit.birdY = hit.galeDebris.first.y;
      hit.velocity = 0;
      step(hit);
    }
    expect(hit.gale!.hits, 1);
    expect(hit.hearts, hearts - 1);
    expect(hit.gale!.hurt, isTrue);
    dodge(hit, 20, until: () => hit.gale!.phase == GalePhase.weathered);
    expect(hit.gale!.bonus, Gale.weatherBonus);

    final clean = blowing();
    final score = clean.score;
    dodge(clean, 20, until: () => clean.gale!.phase == GalePhase.weathered);
    final gale = clean.gale!;
    expect(gale.hits, 0);
    expect(gale.hurt, isFalse);
    expect(gale.dodges, greaterThanOrEqualTo(12));
    expect(gale.bonus, Gale.weatherBonus + Gale.flawlessBonus);
    expect(clean.score - score, gale.dodges * Gale.dodgePoints + gale.bonus);
    expect(clean.events.last.kind, FlightEventKind.galeWeathered);
    expect(clean.events.last.value, gale.bonus);
  });

  test('a rock glances off debris', () {
    final sim = blowing();
    cruise(sim, 5, until: () => sim.galeDebris.any((d) => d.x < 1.6));
    final piece = sim.galeDebris.firstWhere((d) => d.x < 1.6);
    sim.rocks.add(BirdRock(x: piece.x - .06, y: piece.y));
    final impacts = sim.rockImpacts;
    step(sim);
    expect(sim.rocks.single.rebounding, isTrue);
    expect(sim.rockImpacts, impacts + 1);
    expect(sim.galeDebris, contains(piece));
  });

  test('the rush path follows the gale and the boss waits for both', () {
    final sim = bossDown();
    final dueAt = sim.elapsed + FlightSimulation.bossInterval;
    cruise(sim, 60, until: () => sim.galesWeathered > 0);
    final weatheredAt = sim.elapsed;
    expect(sim.rushPathsRun, 0);
    cruise(sim, Gale.rushAfter - .1);
    expect(sim.rushPathsRun, 0);
    cruise(sim, .2);
    expect(sim.rushPathsRun, 1);
    cruise(sim, 90, until: () => sim.boss != null);
    // The Pirate Captain follows the Dusk Empress from rules 34.
    expect(sim.boss!.kind, BossKind.pirate);
    expect(sim.elapsed, greaterThan(dueAt));
    expect(
      sim.elapsed,
      greaterThan(weatheredAt + Gale.rushAfter + Rush.bossLead),
    );
  });

  test('gale audio cues follow the warning, each gust and the calm', () {
    final cues = CombatAudioCues();
    final sim = flight(practice: true);
    expect(cues.advance(sim), isEmpty);
    sim.galeWarnings++;
    expect(cues.advance(sim), ['rush_alarm']);
    sim.gusts++;
    expect(cues.advance(sim), ['gust_warning']);
    sim.galesWeathered++;
    expect(cues.advance(sim), ['rush_clear']);
    sim.gusts += 3;
    expect(cues.advance(sim, silent: true), isEmpty);
    expect(cues.advance(sim), isEmpty);
  });

  test(
    'a gale replays exactly across seeks and becomes a highlight',
    () {
      // The autopilot flies past three bosses and through the gale.
      var now = 0.0;
      final recorder = FlightRecorder(
        ReplayTape(
          mode: PlayMode.touch,
          course: FlightCourse.starTrail,
          practice: true,
          seed: 7,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: false,
          originMs: 0,
          // A heavier weapon gets the autopilot through three bosses.
          weaponDamage: 60,
        ),
        () => now,
      );
      final sim = recorder.simulation;
      Object state(FlightSimulation s) => [
        s.elapsed,
        s.score,
        s.hearts,
        s.birdY,
        s.bossesDefeated,
        s.galesBlown,
        s.galesWeathered,
        s.galeDodges,
        s.gusts,
        s.gale?.phase,
        s.gale?.hits,
        s.courseBoost,
        s.galeDebris.map((d) => [d.x, d.y, d.hitAt, d.dodged]).toList(),
        s.obstacles.map((o) => o.x).toList(),
      ];
      final checkpoints = <double, Object>{};
      for (var frame = 1; frame <= 8000; frame++) {
        now = frame * 50.0;
        recorder.apply(
          MovementInput(valid: true, flap: rideTheSky(sim)),
          TrackingSample(
            mode: PlayMode.touch,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        if (sim.canShoot && (sim.boss != null || sim.enemies.isNotEmpty)) {
          recorder.command('shoot');
        }
        recorder.tick(.05, now, 2.2);
        if (frame % 250 == 0) checkpoints[now] = state(sim);
        if (sim.phase == RunPhase.ended || sim.galesWeathered > 0) break;
      }
      expect(sim.phase, RunPhase.playing);
      expect(sim.bossesDefeated, 3);
      expect(sim.galesWeathered, 1);
      final tape = ReplayTape.fromJson(recorder.tape.toJson());
      final replay = ReplayPlayer(tape);
      final times = checkpoints.keys.toList();
      for (final time in [times.last, times.first, times[times.length ~/ 2]]) {
        replay.seek(time);
        expect(state(replay.simulation), checkpoints[time]);
      }
      final gale = buildReplayHighlights(
        tape,
      ).where((m) => m.kind == ReplayMomentKind.gale);
      expect(gale, hasLength(1));
      expect(gale.single.title, 'Weathered the gale');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets('a gale renders, with and without Reduced Motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => (FontLoader(
        'Fredoka',
      )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load(),
    );
    // [skyAt] paints the world tour at another clock under the flight, so
    // the warnings and wind can be checked against a bright day or snow.
    Future<List<int>> render(
      FlightSimulation sim,
      bool reducedMotion, {
      double? skyAt,
    }) async {
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: reducedMotion,
        playback: true,
        transparent: skyAt != null,
        onChanged: () {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      late List<int> png;
      await tester.runAsync(() async {
        await game.loaded;
        game.pauseEngine();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        if (skyAt != null) {
          SkyScenery.paint(
            canvas,
            const Size(800, 360),
            seconds: skyAt,
            distance: sim.distance,
            reducedMotion: reducedMotion,
          );
        }
        game.render(canvas);
        final picture = recorder.endRecording();
        final image = await picture.toImage(800, 360);
        png = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
      });
      return png;
    }

    final scenes = <String, FlightSimulation>{};
    final skies = <String, double>{};
    final warning = bossDown();
    cruise(warning, 30, until: () => warning.galeWarnings > 0);
    cruise(warning, .4);
    scenes['warning'] = warning;
    // Mid-gale: a pair warned at the edge and pieces tumbling in.
    final storm = blowing();
    dodge(
      storm,
      10,
      until: () =>
          storm.gale!.gusts >= 4 &&
          storm.galeDebris.any((d) => d.entersIn(800 / 360, 1) > .3) &&
          storm.galeDebris.any((d) => d.x < 1.6),
    );
    scenes['blowing'] = storm;
    // A piece striking the bird.
    final struck = blowing();
    cruise(struck, 5, until: () => struck.galeDebris.isNotEmpty);
    struck.invulnerableUntil = 0;
    for (var i = 0; i < 200 && struck.gale!.hits == 0; i++) {
      struck.birdY = struck.galeDebris.first.y;
      struck.velocity = 0;
      step(struck);
    }
    cruise(struck, .1);
    scenes['struck'] = struck;
    final calm = blowing();
    dodge(calm, 20, until: () => calm.galesWeathered > 0);
    dodge(calm, .35);
    scenes['weathered'] = calm;
    // A pair about to break in, over a bright desert day: the warnings
    // have to shout off a pale sky as well as a dusk one.
    final pair = blowing();
    dodge(
      pair,
      12,
      until: () {
        final coming = pair.galeDebris.where((d) {
          final enter = d.entersIn(800 / 360, pair.speed * pair.courseBoost);
          return enter > 0 && enter < .35;
        });
        return pair.gale!.gusts >= 4 && coming.length >= 2;
      },
    );
    scenes['pair'] = pair;
    skies['pair'] = WorldTour.leg * 4 + 8;
    // Mid-gale over the ice, the palest sky on the tour.
    scenes['snow'] = storm;
    skies['snow'] = WorldTour.leg + 8;

    for (final MapEntry(key: name, value: sim) in scenes.entries) {
      final moving = await render(sim, false, skyAt: skies[name]);
      final still = await render(sim, true, skyAt: skies[name]);
      expect(moving.length, greaterThan(2000));
      expect(still.length, greaterThan(2000));
      expect(moving, isNot(still), reason: name);
      if (const bool.fromEnvironment('CAPTURE_VISUALS')) {
        Directory('build/visual-review').createSync(recursive: true);
        File('build/visual-review/gale-$name.png').writeAsBytesSync(moving);
        File(
          'build/visual-review/gale-$name-reduced.png',
        ).writeAsBytesSync(still);
      }
    }
    expect(tester.takeException(), isNull);
  });
}
