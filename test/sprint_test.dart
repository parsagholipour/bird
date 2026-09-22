import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'package:push_up_bird/ui/match_hud.dart';
import 'boss_fight_test.dart' show arena, step, hover, snapshot;
import 'power_shot_test.dart' show flight;
import 'touch_combat_test.dart' show tick;
import 'touch_mode_test.dart' show touchController, advance;

/// Holds the bird at one height, so a test chooses what it flies into.
void fly(FlightSimulation sim, double seconds, {double y = .5}) {
  for (var i = 0; i < (seconds / .02).round(); i++) {
    sim.birdY = y;
    sim.velocity = 0;
    step(sim);
  }
}

/// When each passage spawned, and its spacing from the one before it.
List<({double at, double? gap})> spawns(FlightSimulation sim, double seconds) {
  final spawned = <({double at, double? gap})>[];
  for (var i = 0; i < (seconds / .02).round(); i++) {
    final last = sim.obstacles.lastOrNull;
    fly(sim, .02);
    final newest = sim.obstacles.lastOrNull;
    if (newest != null && !identical(last, newest)) {
      spawned.add((
        at: sim.elapsed,
        gap: last == null ? null : newest.x - last.x,
      ));
    }
  }
  return spawned;
}

void main() {
  test('the burst surges to 2.5x, holds, then eases back to course speed', () {
    expect(Sprint.boost(-.01), 1);
    expect(Sprint.boost(0), 1);
    expect(Sprint.boost(Sprint.surgeSeconds / 2), closeTo(1.75, 1e-9));
    for (final age in [.15, .4, .8]) {
      expect(Sprint.boost(age), Sprint.peakBoost);
    }
    expect(Sprint.boost(Sprint.seconds - .2), closeTo(1.75, 1e-9));
    expect(Sprint.boost(Sprint.seconds), 1);
    expect(Sprint.boost(double.nan), 1);
    var previous = 1.0;
    for (var age = 0.0; age < Sprint.seconds; age += .01) {
      final boost = Sprint.boost(age);
      if (age <= .8) {
        expect(boost, greaterThanOrEqualTo(previous));
      } else {
        expect(boost, lessThanOrEqualTo(previous));
      }
      previous = boost;
    }
  });

  test('a sprint covers the same course sooner and keeps passage spacing', () {
    final calm = flight()..invulnerableUntil = double.infinity;
    final rushed = flight()..invulnerableUntil = double.infinity;
    expect(rushed.sprint(), isTrue);
    var extra = 0.0;
    for (var t = 0.0; t < Sprint.seconds; t += 1e-4) {
      extra += (Sprint.boost(t) - 1) * 1e-4;
    }
    fly(calm, Sprint.seconds + .02);
    fly(rushed, Sprint.seconds + .02);
    expect(rushed.sprinting, isFalse);
    expect(rushed.sprintBoost, 1);
    expect(rushed.distance - calm.distance, closeTo(extra * calm.speed, .005));
    expect(rushed.speed, closeTo(calm.speed, 1e-9));

    final a = flight()..invulnerableUntil = double.infinity;
    final b = flight()..invulnerableUntil = double.infinity;
    final calmSpawns = spawns(a, 6);
    b.sprint();
    final rushedSpawns = spawns(b, 6);
    expect(rushedSpawns.first.at, lessThan(calmSpawns.first.at - .8));
    for (final (sim, spawned) in [(a, calmSpawns), (b, rushedSpawns)]) {
      final gaps = [for (final s in spawned) ?s.gap];
      expect(gaps, hasLength(2));
      for (final gap in gaps) {
        expect(gap, closeTo(sim.speed * sim.spawnInterval, .015));
      }
    }
  });

  test('the cooldown runs 15 s from the press; pauses freeze both clocks', () {
    final sim = flight(practice: true)..invulnerableUntil = double.infinity;
    expect(sim.canSprint, isTrue);
    expect(sim.sprint(), isTrue);
    expect(sim.sprinting, isTrue);
    expect(sim.sprint(), isFalse, reason: 'One sprint per cooldown');
    expect(sim.sprints, 1);
    fly(sim, .5);
    final remaining = sim.sprintRemaining;
    final cooldown = sim.sprintCooldownRemaining;
    expect(remaining, closeTo(Sprint.seconds - .5, 1e-6));
    expect(cooldown, closeTo(Sprint.cooldown - .5, 1e-6));
    sim.takeBreak();
    expect(sim.canSprint, isFalse);
    tick(sim, .4);
    sim.resume();
    tick(sim, 3);
    expect(sim.phase, RunPhase.playing);
    expect(sim.sprintRemaining, remaining);
    expect(sim.sprintCooldownRemaining, cooldown);
    fly(sim, remaining + .02);
    expect(sim.sprinting, isFalse);
    fly(sim, cooldown - remaining - .1);
    expect(sim.canSprint, isFalse);
    expect(sim.sprintCooldownRemaining, closeTo(.08, 1e-6));
    fly(sim, .1);
    expect(sim.canSprint, isTrue);
    expect(sim.sprint(), isTrue);
    expect(sim.sprints, 2);
  });

  test('a countdown or boss cutscene blocks a sprint', () {
    final countdown = FlightSimulation(
      rules: TapFlyMode(),
      practice: true,
      course: FlightCourse.starTrail,
    );
    expect(countdown.sprint(), isFalse);

    final encounter = arena(version: FlightSimulation.currentRulesVersion);
    step(encounter);
    expect(encounter.bossCutscene, isTrue);
    expect(encounter.canSprint, isFalse);
    expect(encounter.sprint(), isFalse);
    hover(encounter, encounter.boss!.arrivalDuration + .05);
    expect(encounter.bossCutscene, isFalse);
    expect(encounter.sprint(), isTrue);
  });

  test(
    'a sprinting bird smashes an enemy of any health for the usual reward',
    () {
      for (final sprinting in [false, true]) {
        final sim = flight()..shield = false;
        final moth = SkyEnemy(
          x: FlightSimulation.birdX + .12,
          y: .5,
          appearance: EnemyKind.duskMoth.index,
          maxHp: 1000,
        );
        sim.enemies.add(moth);
        if (sprinting) expect(sim.sprint(), isTrue);
        fly(sim, .4);
        expect(sim.enemies, isEmpty);
        expect(sim.enemiesDefeated, sprinting ? 1 : 0);
        expect(sim.hearts, sprinting ? 3 : 2);
        expect(sim.score, sprinting ? 3 : 0);
        expect(sim.shots, 0);
        final kinds = sim.events.map((e) => e.kind);
        expect(
          kinds,
          sprinting ? [FlightEventKind.enemyRammed] : [FlightEventKind.hit],
        );
      }
    },
  );

  test('sprinting smashes stone panels; the walls around them still hurt', () {
    for (final (sprinting, y, panel, hurt) in [
      (false, .5, true, true),
      (true, .5, true, false),
      (true, .15, true, true),
      (true, .15, false, true),
    ]) {
      final sim = flight()..shield = false;
      final o = Obstacle(
        x: FlightSimulation.birdX + .06,
        center: .5,
        gap: .34,
        door: panel ? SkyDoor() : null,
      );
      sim.obstacles.add(o);
      if (sprinting) expect(sim.sprint(), isTrue);
      fly(sim, .8, y: y);
      final label = '$sprinting at $y, panel: $panel';
      expect(sim.hearts, hurt ? 2 : 3, reason: label);
      expect(o.hit, hurt, reason: label);
      expect(o.scored, isTrue, reason: label);
      expect(sim.gates, hurt ? 0 : 1, reason: label);
      final smashed = sprinting && y == .5;
      if (panel) expect(o.door!.destroyed, smashed, reason: label);
      expect(sim.doorsDestroyed, smashed ? 1 : 0, reason: label);
      if (smashed) expect(o.door!.lastHitY, closeTo(.5, .005));
    }
  });

  test('enemy and boss ammo still hurt a sprinting bird', () {
    for (final fromBoss in [false, true]) {
      final sim = flight()..shield = false;
      const x = FlightSimulation.birdX + .08;
      if (fromBoss) {
        sim.bossAmmo.add(BossAmmo(x: x, y: .5, vx: -.5, vy: 0));
      } else {
        sim.enemyAmmo.add(
          EnemyAmmo(x: x, y: .5, vx: -.44, vy: 0, attack: EnemyAttack.aimed),
        );
      }
      expect(sim.sprint(), isTrue);
      fly(sim, .3);
      final label = 'boss ammo: $fromBoss';
      expect(sim.sprinting, isTrue, reason: label);
      expect(sim.bossAmmo, isEmpty, reason: label);
      expect(sim.enemyAmmo, isEmpty, reason: label);
      expect(sim.hearts, 2, reason: label);
    }
  });

  test('in a boss fight a sprint rushes the ammo past; the boss holds', () {
    ({FlightSimulation sim, BossAmmo volley, EnemyAmmo pellet}) fight({
      required bool sprint,
    }) {
      final sim = arena(version: FlightSimulation.currentRulesVersion)
        ..invulnerableUntil = double.infinity;
      step(sim);
      hover(sim, sim.boss!.arrivalDuration + .05);
      expect(sim.boss!.phase, BossPhase.attacking);
      final volley = BossAmmo(x: 1.6, y: .2, vx: -.5, vy: 0);
      final pellet = EnemyAmmo(
        x: 1.6,
        y: .8,
        vx: -.44,
        vy: 0,
        attack: EnemyAttack.aimed,
      );
      sim
        ..bossAmmo.add(volley)
        ..enemyAmmo.add(pellet);
      if (sprint) expect(sim.sprint(), isTrue);
      return (sim: sim, volley: volley, pellet: pellet);
    }

    final calm = fight(sprint: false), rushed = fight(sprint: true);
    for (final (seconds, sprinting) in [(.5, true), (.8, false)]) {
      hover(calm.sim, seconds);
      hover(rushed.sim, seconds);
      expect(rushed.sim.sprinting, sprinting);
      // Ammo rushes by exactly the extra course the sprint has covered.
      final extra = rushed.sim.distance - calm.sim.distance;
      expect(extra, greaterThan(.1));
      expect(rushed.sim.bossAmmo, contains(rushed.volley));
      expect(rushed.sim.enemyAmmo, contains(rushed.pellet));
      expect(calm.volley.x - rushed.volley.x, closeTo(extra, 1e-9));
      expect(calm.pellet.x - rushed.pellet.x, closeTo(extra, 1e-9));
      expect(rushed.volley.y, calm.volley.y);
      expect(rushed.pellet.y, calm.pellet.y);
      expect(rushed.sim.boss!.x, calm.sim.boss!.x);
      expect(rushed.sim.boss!.y, calm.sim.boss!.y);
    }
  });

  test('rules before 29, camera controls and Cloud Cruise have no sprint', () {
    final old = flight(version: 28);
    expect(old.supportsSprint, isFalse);
    expect(old.sprint(), isFalse);
    expect(old.canSprint, isFalse);
    expect(old.sprinting, isFalse);
    expect(old.sprintBoost, 1);
    expect(old.sprintCooldownRemaining, 0);
    for (final (rules, course) in <(GameMode, FlightCourse)>[
      (PushUpFlightMode(cycleSeconds: 3), FlightCourse.starTrail),
      (JumpFlyMode(), FlightCourse.starTrail),
      (TapFlyMode(), FlightCourse.cloudCruise),
    ]) {
      final sim = FlightSimulation(rules: rules, practice: true, course: course)
        ..phase = RunPhase.playing;
      expect(sim.supportsSprint, isFalse);
      expect(sim.sprint(), isFalse);
    }
    for (final version in [28, 29]) {
      final tape = ReplayTape(
        mode: PlayMode.touch,
        practice: false,
        seed: 2,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: false,
        originMs: 0,
        recordedVersion: version,
      )..events.add([0.0, 'sprint']);
      if (version == 28) {
        expect(() => ReplayTape.fromJson(tape.toJson()), throwsFormatException);
      } else {
        expect(ReplayTape.fromJson(tape.toJson()).events, hasLength(1));
        tape.events.add([0.0, 'sprint', 1]);
        expect(() => ReplayTape.fromJson(tape.toJson()), throwsFormatException);
      }
    }
  });

  for (final reduced in [false, true]) {
    test('sprints and rams replay exactly across seeks ($reduced)', () {
      var now = 0.0;
      final recorder = FlightRecorder(
        ReplayTape(
          mode: PlayMode.touch,
          course: FlightCourse.skyCourier,
          practice: true,
          seed: 11,
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
        s.distance,
        s.sprints,
        s.lastSprintAt,
        s.sprintBoost,
        s.doorsDestroyed,
        s.obstacles.map((o) => [o.x, o.hit, o.scored, o.door?.hp]).toList(),
        s.enemies.map((e) => [e.x, e.hp]).toList(),
        s.bossAmmo.map((a) => [a.x, a.y]).toList(),
        s.enemyAmmo.map((a) => [a.x, a.y]).toList(),
      ];
      final checkpoints = <double, Object>{};
      final rams = <FlightEvent>{};
      var bossSprints = 0;
      for (var frame = 1; frame <= 1800; frame++) {
        now = frame * 50.0;
        final prey = sim.enemies
            .where((e) => e.x > FlightSimulation.birdX)
            .firstOrNull;
        final gate = sim.obstacles
            .where((o) => o.x + o.width > FlightSimulation.birdX)
            .firstOrNull;
        final aim = (sim.sprinting ? prey?.y : null) ?? gate?.target ?? .5;
        recorder.apply(
          MovementInput(valid: true, flap: sim.birdY > aim && sim.velocity > 0),
          TrackingSample(
            mode: PlayMode.touch,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        final incoming = sim.bossAmmo.any(
          (a) => a.x - FlightSimulation.birdX < .5,
        );
        if (sim.canSprint &&
            (incoming ||
                prey != null && prey.x - FlightSimulation.birdX < .7)) {
          if (sim.boss != null) bossSprints++;
          recorder.command('sprint');
        }
        if (sim.boss != null && sim.canShoot) recorder.command('shoot');
        recorder.tick(.05, now, 2.2);
        rams.addAll(
          sim.events.where((e) => e.kind == FlightEventKind.enemyRammed),
        );
        if (frame % 150 == 0) checkpoints[now] = state(sim);
      }
      expect(sim.sprints, greaterThanOrEqualTo(4));
      expect(bossSprints, greaterThan(0));
      expect(rams, isNotEmpty);
      final replay = ReplayPlayer(ReplayTape.fromJson(recorder.tape.toJson()));
      for (final time in [90000.0, 30000.0, 60000.0, 15000.0, 90000.0]) {
        replay.seek(time);
        expect(state(replay.simulation), checkpoints[time]);
      }
    });
  }

  test('the controller journals accepted sprints only', () async {
    final controller = touchController(
      course: FlightCourse.skyCourier,
      practice: true,
    );
    addTearDown(controller.dispose);
    await controller.fly();
    controller.sprint();
    advance(controller, 150);
    final sim = controller.simulation!;
    expect(sim.phase, RunPhase.playing);
    expect(sim.sprints, 0, reason: 'Countdown presses do not queue');

    controller.sprint();
    expect(sim.sprinting, isTrue);
    advance(controller, 10);
    controller.sprint();
    expect(sim.sprints, 1, reason: 'A press during the cooldown is dropped');
    controller.pause();
    controller.sprint();
    expect(sim.sprints, 1);
    final kinds = [
      for (final e in controller.recorder!.tape.events)
        if (e[1] == 'sprint') e[1],
    ];
    expect(kinds, ['sprint']);

    final tape = ReplayTape.fromJson(controller.recorder!.tape.toJson());
    final replay = ReplayPlayer(tape)..seek(tape.durationMs);
    expect(replay.simulation.lastSprintAt, sim.lastSprintAt);
    expect(replay.simulation.distance, sim.distance);
    expect(replay.simulation.sprintRemaining, sim.sprintRemaining);
  });

  test('a sprint whooshes once and chimes once when it recharges', () {
    const sprintCues = {'sprint', 'sprint_ready'};
    final sim = flight()..invulnerableUntil = double.infinity;
    final audio = CombatAudioCues()..advance(sim, silent: true);
    List<String> cues() =>
        audio.advance(sim).where(sprintCues.contains).toList();

    fly(sim, .5);
    expect(cues(), isEmpty, reason: 'A flight starts ready without a chime');
    sim.sprint();
    expect(cues(), ['sprint']);
    fly(sim, Sprint.cooldown - .1);
    expect(cues(), isEmpty);
    fly(sim, .2);
    expect(cues(), ['sprint_ready']);
    fly(sim, 1);
    expect(cues(), isEmpty);
    sim.sprint();
    expect(audio.advance(sim, silent: true), isEmpty);
    expect(cues(), isEmpty);
  });

  testWidgets('a sprint renders streaks, a bow wave and a smash', (
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
    final sim = flight()..sprint();
    fly(sim, .3);
    sim.obstacles.add(
      Obstacle(
        x: FlightSimulation.birdX + .30,
        center: .5,
        gap: .34,
        door: SkyDoor(),
      ),
    );
    sim.enemies.add(SkyEnemy(x: FlightSimulation.birdX + .6, y: .3));
    sim.events.add(
      FlightEvent(
        FlightEventKind.enemyRammed,
        sim.elapsed - .1,
        .5,
        value: 3,
        gateWorldX: sim.distance + FlightSimulation.birdX + .05,
      ),
    );
    for (final reducedMotion in [false, true]) {
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: reducedMotion,
        playback: true,
        onChanged: () {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      await tester.runAsync(() async {
        await game.loaded;
        game.pauseEngine();
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(800, 360);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        expect(bytes.length, greaterThan(2000));
        if (const bool.fromEnvironment('CAPTURE_VISUALS')) {
          Directory('build/visual-review').createSync(recursive: true);
          File(
            'build/visual-review/sprint${reducedMotion ? '-reduced' : ''}.png',
          ).writeAsBytesSync(bytes);
        }
        image.dispose();
        picture.dispose();
      });
    }
    expect(tester.takeException(), isNull);
  });

  group('Sprint button', () {
    Widget app({
      required VoidCallback? onPressed,
      required VoidCallback onSky,
      double recharge = 1,
      double burst = 0,
      int secondsLeft = 0,
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
            child: MatchSprintButton(
              key: const ValueKey('sprint'),
              label: 'Sprint',
              recharge: recharge,
              burst: burst,
              secondsLeft: secondsLeft,
              onPressed: onPressed,
              reducedMotion: false,
            ),
          ),
        ],
      ),
    );

    testWidgets('a tap sprints; a recharging button still never flaps', (
      tester,
    ) async {
      var sprints = 0, flaps = 0;
      await tester.pumpWidget(
        app(onPressed: () => sprints++, onSky: () => flaps++),
      );
      final sprint = find.byKey(const ValueKey('sprint'));
      expect(tester.getSize(sprint), const Size(80, 80));
      await tester.tap(sprint);
      await tester.pumpAndSettle();
      expect((sprints, flaps), (1, 0));

      await tester.pumpWidget(
        app(
          onPressed: null,
          onSky: () => flaps++,
          recharge: .2,
          secondsLeft: 12,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
      await tester.tap(sprint);
      await tester.pumpAndSettle();
      expect((sprints, flaps), (1, 0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics and the keyboard report and trigger a sprint', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        var sprints = 0;
        await tester.pumpWidget(app(onPressed: () => sprints++, onSky: () {}));
        final sprint = find.byKey(const ValueKey('sprint'));
        expect(
          tester.getSemantics(sprint),
          isSemantics(
            label: 'Sprint',
            value: 'Ready',
            hint: 'Rush ahead to smash bats and stone panels',
            isButton: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
        tester.semantics.performAction(
          find.semantics.byLabel('Sprint'),
          SemanticsAction.tap,
        );
        expect(sprints, 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(sprints, 2);

        await tester.pumpWidget(
          app(onPressed: null, onSky: () {}, burst: .5, secondsLeft: 15),
        );
        expect(tester.getSemantics(sprint).value, 'Sprinting');
        await tester.pumpWidget(
          app(onPressed: null, onSky: () {}, recharge: .2, secondsLeft: 12),
        );
        expect(tester.getSemantics(sprint).value, 'Recharging, 12 seconds');
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });
  });
}
