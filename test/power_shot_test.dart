import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'package:push_up_bird/ui/match_hud.dart';
import 'boss_fight_test.dart' show arena, step, hover, snapshot;
import 'touch_combat_test.dart' show tick;
import 'touch_mode_test.dart' show touchController, advance;

FlightSimulation flight({
  int version = FlightSimulation.currentRulesVersion,
  bool practice = false,
}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: version),
    practice: practice,
    course: FlightCourse.starTrail,
    rulesVersion: version,
    random: Random(4),
  );
  tick(sim, 3);
  sim.obstacles.clear();
  sim.stars.clear();
  sim.starTrios.clear();
  sim.enemies.clear();
  return sim;
}

/// Hovers in place so long holds never touch the ground.
void hold(FlightSimulation sim, double seconds) {
  for (var i = 0; i < (seconds / .02).round(); i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    tick(sim, .02);
  }
}

void main() {
  test('held charge is a spectrum of size, damage and reserve cost', () {
    final rocks = <BirdRock>[];
    final spent = <double>[];
    for (final seconds in [0.0, .2, .4, .6, .8, 1.0]) {
      final sim = flight();
      expect(sim.startCharge(), isTrue);
      hold(sim, seconds);
      expect(sim.shotCharge, closeTo(seconds, 1e-9));
      expect(sim.shoot(), isTrue);
      final rock = sim.rocks.single;
      rocks.add(rock);
      spent.add(1 - sim.ammo);
      expect(rock.charge, closeTo(seconds, 1e-9));
      expect(rock.damage, (10 * (1 + 3 * seconds)).round());
      expect(
        rock.radius,
        closeTo(BirdRock.baseRadius * (1 + 1.4 * seconds), 1e-12),
      );
      expect(1 - sim.ammo, closeTo(.10 + .35 * seconds, 1e-9));
      expect(sim.charging, isFalse);
    }
    expect(rocks.first.damage, BirdRock.baseDamage);
    expect(rocks.first.radius, BirdRock.baseRadius);
    expect(rocks.last.damage, 40);
    for (var i = 1; i < rocks.length; i++) {
      expect(rocks[i].damage, greaterThan(rocks[i - 1].damage));
      expect(rocks[i].radius, greaterThan(rocks[i - 1].radius));
      expect(spent[i], greaterThan(spent[i - 1]));
    }
  });

  test('charging past a full second stays at full power', () {
    final sim = flight()..startCharge();
    hold(sim, 1.2);
    expect(sim.shotCharge, 1);
    expect(sim.shots, 0);
    expect(sim.fullHoldLeft, closeTo(.6, .02));
    sim.shoot();
    expect(sim.rocks.single.damage, 40);
    expect(sim.ammo, closeTo(.55, 1e-9));
  });

  test('a full charge fires itself after 500 ms', () {
    final sim = flight()..startCharge();
    hold(sim, 1.4);
    expect(sim.shotCharge, 1);
    expect(sim.shots, 0);
    expect(sim.fullHoldLeft, closeTo(.2, .02));
    hold(sim, .2);
    expect(sim.shots, 1);
    expect(sim.rocks.single.charge, 1);
    expect(sim.rocks.single.damage, 40);
    expect(sim.ammo, closeTo(.55, 1e-9));
    expect(sim.charging, isFalse);
    expect(sim.shoot(), isFalse);
    expect(sim.dryFires, 0);
    hold(sim, 1);
    expect(sim.shots, 1, reason: 'The press already spent its rock');
  });

  test('the 500 ms window starts when the charge reaches full', () {
    final sim = flight()..ammo = 0;
    sim.lastShotAt = sim.elapsed;
    expect(sim.startCharge(), isTrue);
    hold(sim, 1.4);
    expect(sim.shotCharge, lessThan(1));
    expect(sim.shots, 0);
    hold(sim, .3);
    expect(sim.shotCharge, 1);
    expect(sim.shots, 0);
    hold(sim, .3);
    expect(sim.shots, 0);
    expect(sim.charging, isTrue);
    hold(sim, .2);
    expect(sim.shots, 1);
    expect(sim.rocks.single.charge, closeTo(1, 1e-9));
  });

  test('upgraded weapons scale every charge from the upgraded base', () {
    final sim = flight()..setWeaponDamage(25);
    sim.startCharge();
    hold(sim, .5);
    sim.shoot();
    expect(sim.rocks.single.damage, (25 * 2.5).round());
  });

  test('rapid fire drains the reserve; only a pause in firing refills it', () {
    final sim = flight();
    var fired = 0;
    for (var frame = 0; frame < 300 && !sim.outOfAmmo; frame++) {
      final before = sim.ammo;
      if (sim.canShoot) {
        expect(sim.shoot(), isTrue);
        fired++;
      }
      hold(sim, .02);
      expect(sim.ammo, lessThanOrEqualTo(before));
    }
    expect(fired, 10);
    expect(sim.ammo, closeTo(0, 1e-9));
    expect(sim.canShoot, isFalse);
    expect(sim.shoot(), isFalse);
    expect(sim.dryFires, 1);
    expect(sim.shots, 10);

    // The loop has already hovered 20 ms since the final shot.
    hold(sim, PowerShot.refillDelay - .04);
    expect(sim.ammo, closeTo(0, 1e-9));
    hold(sim, .30);
    expect(sim.ammo, closeTo(.28 * PowerShot.refillPerSecond, .006));
    expect(sim.canShoot, isTrue);
    hold(sim, 3);
    expect(sim.ammo, 1);
  });

  test('a low reserve caps the charge, and holding while empty refills', () {
    final sim = flight()
      ..ammo = .2
      ..lastShotAt = 0;
    sim.startCharge();
    hold(sim, .4);
    final affordable = (.2 - .1) / .35;
    expect(sim.shotCharge, closeTo(affordable, 1e-9));
    expect(sim.shotCost, closeTo(.2, 1e-9));
    sim.shoot();
    expect(sim.rocks.single.charge, closeTo(affordable, 1e-9));
    expect(sim.ammo, closeTo(0, 1e-9));

    // A press held through an empty reserve grows with the refill instead of
    // locking the weapon until the player lets go.
    sim.startCharge();
    hold(sim, PowerShot.refillDelay);
    expect(sim.shotCharge, 0);
    hold(sim, .5);
    expect(sim.ammo, closeTo(.2, .01));
    expect(sim.shotCharge, closeTo((sim.ammo - .1) / .35, 1e-9));
    expect(sim.shoot(), isTrue);
    expect(sim.rocks.last.charge, greaterThan(.2));
  });

  test('charges need active combat; pauses and boss cutscenes cancel them', () {
    final countdown = FlightSimulation(
      rules: TapFlyMode(),
      practice: true,
      course: FlightCourse.starTrail,
    );
    expect(countdown.startCharge(), isFalse);

    final sim = flight(practice: true);
    expect(sim.startCharge(), isTrue);
    expect(sim.startCharge(), isFalse, reason: 'One press at a time');
    hold(sim, .5);
    sim.takeBreak();
    expect(sim.phase, RunPhase.paused);
    expect(sim.charging, isFalse);
    expect(sim.shotCharge, 0);
    expect(sim.canCharge, isFalse);
    expect(sim.shoot(), isFalse);
    expect(sim.rocks, isEmpty);
    expect(sim.dryFires, 0);
    sim.resume();
    tick(sim, 3);
    expect(sim.phase, RunPhase.playing);
    expect(sim.charging, isFalse, reason: 'A pause never revives a charge');

    final encounter = arena(version: FlightSimulation.currentRulesVersion);
    expect(encounter.startCharge(), isTrue);
    step(encounter);
    expect(encounter.bossCutscene, isTrue);
    expect(encounter.charging, isFalse);
    expect(encounter.canCharge, isFalse);
    hover(encounter, encounter.boss!.arrivalDuration + .05);
    expect(encounter.bossCutscene, isFalse);
    expect(encounter.startCharge(), isTrue);
  });

  test('a charged rock is big enough to hit what a tap would miss', () {
    for (final charge in [0.0, 1.0]) {
      final sim = flight();
      final moth = SkyEnemy(
        x: 1.3,
        y: .57,
        appearance: EnemyKind.duskMoth.index,
      );
      sim.enemies.add(moth);
      sim.rocks.add(
        BirdRock(
          x: 1.0,
          y: .5,
          damage: PowerShot.damage(10, charge),
          charge: charge,
        ),
      );
      tick(sim, .3);
      expect(sim.enemiesDefeated, charge == 1 ? 1 : 0);
      expect(moth.hp, charge == 1 ? 0 : moth.maxHp);
    }
    expect(() => BirdRock(x: 1, y: .5, charge: 1.01), throwsArgumentError);
    expect(() => BirdRock(x: 1, y: .5, charge: -.01), throwsArgumentError);
    expect(
      () => BirdRock(x: 1, y: .5, charge: double.nan),
      throwsArgumentError,
    );
  });

  test('version 27 keeps unlimited cooldown shots and rejects charges', () {
    final sim = flight(version: 27);
    expect(sim.supportsPowerShots, isFalse);
    expect(sim.startCharge(), isFalse);
    var fired = 0;
    for (var frame = 0; frame < 200; frame++) {
      if (sim.canShoot && sim.shoot()) fired++;
      hold(sim, .02);
    }
    expect(fired, greaterThan(12), reason: 'More than a full reserve');
    expect(sim.ammo, 1);
    expect(sim.shots, fired);

    for (final version in [27, 28]) {
      final tape = ReplayTape(
        mode: PlayMode.touch,
        practice: false,
        seed: 2,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: false,
        originMs: 0,
        recordedVersion: version,
      )..events.add([0.0, 'charge']);
      if (version == 27) {
        expect(() => ReplayTape.fromJson(tape.toJson()), throwsFormatException);
      } else {
        expect(ReplayTape.fromJson(tape.toJson()).events, hasLength(1));
        tape.events.add([0.0, 'charge', 1]);
        expect(() => ReplayTape.fromJson(tape.toJson()), throwsFormatException);
      }
    }
  });

  for (final reduced in [false, true]) {
    test(
      'held shots of every length replay exactly across seeks ($reduced)',
      () {
        var now = 0.0;
        final recorder = FlightRecorder(
          ReplayTape(
            mode: PlayMode.touch,
            course: FlightCourse.skyCourier,
            practice: true,
            seed: 7,
            cycleSeconds: 3,
            bird: 0,
            reducedMotion: reduced,
            originMs: 0,
          ),
          () => now,
        );
        final sim = recorder.simulation;
        Object state(FlightSimulation s) => [
          snapshot(s),
          s.ammo,
          s.charging,
          s.shotCharge,
          s.dryFires,
          s.rocks.map((r) => [r.x, r.y, r.damage, r.charge]).toList(),
          s.enemies.map((e) => e.hp).toList(),
          if (s.boss case final b?) b.hp,
        ];
        // Frames of 50 ms: taps, partial holds, a full charge and overholds.
        const holds = [0, 3, 8, 14, 20, 27, 1, 0, 0];
        final checkpoints = <double, Object>{};
        final charges = <double>{};
        var next = 0, pressedAt = 0;
        void release() {
          final before = sim.shots;
          recorder.command('shoot');
          if (sim.shots > before) charges.add(sim.lastShotCharge);
          next++;
        }

        for (var frame = 1; frame <= 1800; frame++) {
          now = frame * 50.0;
          recorder.apply(
            MovementInput(
              valid: true,
              flap: sim.birdY > .5 && sim.velocity > 0,
            ),
            TrackingSample(
              mode: PlayMode.touch,
              timestampMs: now,
              receivedMs: now,
              joints: const [],
            ),
            now,
          );
          if (sim.charging) {
            if (frame - pressedAt >= holds[next % holds.length]) release();
          } else if (sim.canCharge && frame % 4 == 0) {
            recorder.command('charge');
            pressedAt = frame;
            if (holds[next % holds.length] == 0) release();
          }
          recorder.tick(.05, now, 2.2);
          if (frame % 150 == 0) checkpoints[now] = state(sim);
        }
        expect(charges.length, greaterThanOrEqualTo(6), reason: '$charges');
        expect(charges, contains(0));
        expect(charges.reduce(max), greaterThan(.95));
        expect(sim.dryFires, greaterThan(0), reason: 'Quick taps empty it');
        expect(sim.bossesDefeated, greaterThan(0));
        final replay = ReplayPlayer(
          ReplayTape.fromJson(recorder.tape.toJson()),
        );
        for (final time in [90000.0, 30000.0, 60000.0, 15000.0, 90000.0]) {
          replay.seek(time);
          expect(state(replay.simulation), checkpoints[time]);
        }
      },
    );
  }

  test(
    'the controller journals a press, its release and a paused release',
    () async {
      final controller = touchController(
        course: FlightCourse.skyCourier,
        practice: true,
      );
      addTearDown(controller.dispose);
      await controller.fly();
      controller.startCharge();
      advance(controller, 150);
      final sim = controller.simulation!;
      expect(sim.phase, RunPhase.playing);
      expect(sim.charging, isFalse, reason: 'Countdown presses do not queue');

      controller.startCharge();
      expect(sim.charging, isTrue);
      advance(controller, 25);
      controller.shoot();
      expect(sim.shots, 1);
      expect(sim.rocks.single.charge, closeTo(.5, 1e-9));
      expect(sim.rocks.single.damage, 25);

      controller.startCharge();
      controller.shoot();
      expect(sim.shots, 1, reason: 'A tap during the cooldown is dropped');
      expect(sim.charging, isFalse);

      advance(controller, 20);
      controller.startCharge();
      advance(controller, 10);
      controller.pause();
      expect(sim.charging, isFalse);
      controller.shoot();
      expect(sim.shots, 1);
      final kinds = [
        for (final e in controller.recorder!.tape.events)
          if (e[1] == 'charge' || e[1] == 'shoot') e[1],
      ];
      expect(kinds, ['charge', 'shoot', 'charge', 'shoot', 'charge']);

      final tape = ReplayTape.fromJson(controller.recorder!.tape.toJson());
      final replay = ReplayPlayer(tape)..seek(tape.durationMs);
      expect(
        replay.simulation.rocks.map((r) => (r.x, r.y, r.damage, r.charge)),
        sim.rocks.map((r) => (r.x, r.y, r.damage, r.charge)),
      );
      expect(replay.simulation.ammo, sim.ammo);
      expect(replay.simulation.charging, isFalse);
    },
  );

  test(
    'holding a full charge fires once, and lifting does not fire again',
    () async {
      final controller = touchController(
        course: FlightCourse.starTrail,
        practice: true,
      );
      addTearDown(controller.dispose);
      await controller.fly();
      final sim = controller.simulation!;
      advance(controller, 160);
      expect(sim.phase, RunPhase.playing);
      controller.startCharge();
      for (var i = 0; i < 70; i++) {
        if (sim.birdY < .55) controller.flap();
        advance(controller, 1);
      }
      expect(sim.shots, 0, reason: 'Still inside the 500 ms window');
      expect(sim.charging, isTrue);
      for (var i = 0; i < 15; i++) {
        if (sim.birdY < .55) controller.flap();
        advance(controller, 1);
      }
      expect(sim.shots, 1);
      expect(sim.lastShotCharge, closeTo(1, 1e-6));
      expect(sim.charging, isFalse);
      controller.shoot();
      expect(sim.shots, 1);
      expect(
        controller.recorder!.tape.events.where((event) => event[1] == 'shoot'),
        isEmpty,
      );
      final replay = ReplayPlayer(
        ReplayTape.fromJson(controller.recorder!.tape.toJson()),
      )..seek(controller.recorder!.tape.durationMs);
      expect(replay.simulation.shots, 1);
      expect(replay.simulation.lastShotCharge, closeTo(1, 1e-6));
      expect(replay.simulation.ammo, closeTo(sim.ammo, 1e-9));
      expect(replay.simulation.charging, isFalse);
    },
  );

  test('strong releases, a full charge and a dry fire have their own cues', () {
    const shotCues = {'shoot', 'power_shot', 'shot_charged', 'ammo_empty'};
    final sim = flight();
    final audio = CombatAudioCues()..advance(sim, silent: true);
    List<String> cues() => audio.advance(sim).where(shotCues.contains).toList();

    sim.startCharge();
    hold(sim, .2);
    expect(cues(), isEmpty);
    sim.shoot();
    expect(cues(), ['shoot']);
    hold(sim, .3);
    sim.startCharge();
    hold(sim, .5);
    expect(cues(), isEmpty);
    hold(sim, .56);
    expect(cues(), ['shot_charged']);
    hold(sim, .2);
    expect(cues(), isEmpty, reason: 'The full-charge chime plays once');
    sim.shoot();
    expect(cues(), ['power_shot']);

    sim
      ..ammo = 0
      ..lastShotAt = sim.elapsed;
    sim.startCharge();
    sim.shoot();
    expect(cues(), ['ammo_empty']);
    sim.shots += 3;
    sim.dryFires += 3;
    expect(audio.advance(sim, silent: true), isEmpty);
  });

  group('Shoot button', () {
    Widget app({
      required VoidCallback? onPress,
      required VoidCallback onRelease,
      required VoidCallback onSky,
      double reserve = .8,
      double charge = 0,
      double hold = 1,
      bool charging = false,
      bool empty = false,
    }) => MaterialApp(
      home: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => onSky(),
            ),
          ),
          Center(
            child: MatchShotButton(
              key: const ValueKey('shoot'),
              label: 'Shoot',
              reserve: reserve,
              charge: charge,
              spend: charging ? PowerShot.cost(charge) : 0,
              hold: hold,
              charging: charging,
              empty: empty,
              onPress: onPress,
              onRelease: onRelease,
              reducedMotion: false,
            ),
          ),
        ],
      ),
    );

    testWidgets('holds one finger, releases on lift or cancel, never flaps', (
      tester,
    ) async {
      var presses = 0, releases = 0, flaps = 0;
      await tester.pumpWidget(
        app(
          onPress: () => presses++,
          onRelease: () => releases++,
          onSky: () => flaps++,
        ),
      );
      final shoot = find.byKey(const ValueKey('shoot'));
      final first = await tester.startGesture(
        tester.getCenter(shoot),
        pointer: 1,
      );
      await tester.pump();
      expect((presses, releases), (1, 0));
      final second = await tester.startGesture(
        tester.getCenter(shoot),
        pointer: 2,
      );
      await second.up();
      expect((presses, releases), (1, 0), reason: 'Second finger ignored');
      await first.moveBy(const Offset(220, 0));
      await first.up();
      expect((presses, releases), (1, 1), reason: 'Sliding off still fires');

      final cancelled = await tester.startGesture(tester.getCenter(shoot));
      await cancelled.cancel();
      expect((presses, releases), (2, 2));
      await tester.tap(shoot);
      expect((presses, releases, flaps), (3, 3, 0));

      await tester.pumpWidget(
        app(onPress: null, onRelease: () => releases++, onSky: () => flaps++),
      );
      await tester.tap(shoot);
      expect((presses, releases, flaps), (3, 3, 0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard holds and semantic taps use the same press', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        var presses = 0, releases = 0;
        await tester.pumpWidget(
          app(
            onPress: () => presses++,
            onRelease: () => releases++,
            onSky: () {},
            reserve: .62,
          ),
        );
        final shoot = find.byKey(const ValueKey('shoot'));
        expect(
          tester.getSemantics(shoot),
          isSemantics(
            label: 'Shoot',
            value: 'Ammo 62%',
            hint: 'Hold to charge a bigger rock',
            isButton: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
        expect((presses, releases), (1, 0));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        expect((presses, releases), (1, 1));
        tester.semantics.performAction(
          find.semantics.byLabel('Shoot'),
          SemanticsAction.tap,
        );
        expect((presses, releases), (2, 2));

        await tester.pumpWidget(
          app(
            onPress: () {},
            onRelease: () {},
            onSky: () {},
            charge: .5,
            charging: true,
          ),
        );
        expect(tester.getSemantics(shoot).value, 'Charging 50%');
        await tester.pumpWidget(
          app(
            onPress: () {},
            onRelease: () {},
            onSky: () {},
            charge: 1,
            charging: true,
            hold: .5,
          ),
        );
        expect(tester.getSemantics(shoot).value, 'Full charge, 250 ms left');
        await tester.pumpWidget(
          app(
            onPress: () {},
            onRelease: () {},
            onSky: () {},
            reserve: .04,
            empty: true,
          ),
        );
        expect(tester.getSemantics(shoot).value, 'Reloading…');
      } finally {
        semantics.dispose();
      }
    });
  });
}
