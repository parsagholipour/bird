import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'boss_polish_health_bar_art_test.dart' show bossAfter;
import 'play_session_test.dart' show SessionSource, SilentAudio, startFlight;

/// Review frames of the in-flight HUD over the real play screen: every
/// readout and control in its states, over bright, dark and busy regions,
/// at phone and tablet widths.
///
/// Run with `--dart-define=HUD_REVIEW=after` (or `before`) to write PNGs to
/// build/visual-review/hud-redesign/`phase`/. Without it the states still
/// render, so the suite checks that none of them throws or overflows.
const _phase = String.fromEnvironment('HUD_REVIEW');

/// Mid-flight seconds that show each region fully (16 s hold per 22 s leg).
const _jungle = 5.0, _antarctica = 27.0, _aztec = 49.0, _paris = 71.0;
const _egypt = 93.0, _cyberpunk = 115.0, _brazil = 159.0, _mexico = 247.0;
const _sea = 269.0;

class _Flight {
  _Flight(this.tester, this.controller, this.game, this.source, this.width);
  final WidgetTester tester;
  final PlayController controller;
  BirdGame game;
  final SessionSource source;
  final int width;
  FlightSimulation get sim => controller.simulation!;

  /// Repaints the paused game with the staged state, without advancing the
  /// simulation (the scenery follows its clock), and rebuilds the HUD.
  Future<void> redraw({Duration after = Duration.zero}) async {
    controller.notify();
    await tester.pump();
    for (final box in tester.allRenderObjects) {
      if (box.runtimeType.toString() == 'GameRenderBox') box.markNeedsPaint();
    }
    await tester.pump(after);
    expect(tester.takeException(), isNull);
  }

  Future<void> capture(String name) async {
    if (_phase.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('visual-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/visual-review/hud-redesign/$_phase/$name.png')
        ..parent.createSync(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  /// A calm mid-flight: two passages ahead, nothing that can hit the bird
  /// during the single frame each capture advances.
  void scene(double elapsed, {double birdY = .5}) {
    sim
      ..phase = RunPhase.playing
      ..elapsed = elapsed
      ..birdY = birdY
      ..velocity = 0
      ..boss = null;
    sim.obstacles
      ..clear()
      ..addAll([
        Obstacle(x: 1.05, center: .42, gap: .46, bornAt: elapsed),
        Obstacle(x: 1.85, center: .58, gap: .46, bornAt: elapsed),
      ]);
    sim.enemies.clear();
    sim.enemyAmmo.clear();
    sim.bossAmmo.clear();
    sim.rocks.clear();
    sim.heartPickups.clear();
    sim.stars
      ..clear()
      ..addAll([for (var i = 0; i < 3; i++) SkyStar(x: .72 + .16 * i, y: .42)]);
  }
}

Future<_Flight> _launch(
  WidgetTester tester, {
  required String mode,
  required Size size,
  bool reduced = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await repo.setSetting(SettingKey.reducedMotion, reduced);
  final folder = Directory.systemTemp.createTempSync('hud-review');
  final source = SessionSource();
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(SilentAudio.new),
      trackingSourceFactoryProvider.overrideWithValue(() => source),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await repo.close();
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });
  await container.read(progressProvider.future);
  appRouter.go('/play/$mode?course=starTrail');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: ValueKey('visual-capture'),
        child: PushUpBirdApp(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  final dynamic state = tester.state(find.byType(PlayScreen));
  final controller = state.controller as PlayController;
  if (mode == 'touch') {
    await tester.runAsync(controller.fly);
  } else {
    await tester.runAsync(() => startFlight(controller, source));
  }
  await tester.pump();
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  await tester.pump();
  return _Flight(tester, controller, game, source, size.width.toInt());
}

/// Swaps in a pre-endless Star Trail, the only flight with a countdown clock.
Future<void> _timedTrail(_Flight f, double elapsed) async {
  final sim = FlightSimulation(
    rules: TapFlyMode(),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: 11,
  );
  f.controller.simulation = sim;
  f.controller.notify();
  await f.tester.pump();
  f.game = f.tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await f.tester.runAsync(
    () => f.game.loaded.timeout(const Duration(seconds: 5)),
  );
  f.game.pauseEngine();
  f.scene(elapsed);
  sim
    ..started = true
    ..score = 38
    ..combo = 7
    ..collectedStars = 21;
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  const sizes = [Size(640, 360), Size(800, 360), Size(1000, 450)];

  for (final size in sizes) {
    final w = size.width.toInt();
    testWidgets('touch combat HUD states at $w', (tester) async {
      final f = await _launch(tester, mode: 'touch', size: size);
      final sim = f.sim;

      // Full health over the busy jungle, a live 2× streak, both actions ready.
      f.scene(_jungle);
      sim
        ..hearts = 3
        ..shield = true
        ..score = 26
        ..combo = 8
        ..ammo = 1;
      await f.redraw();
      await f.capture('touch-jungle-full-$w');

      // Top of a push-up over bright snow: two hearts, the shield charging,
      // 3× streak, a held shot and the sprint cooling down.
      f.scene(_antarctica, birdY: .15);
      sim
        ..hearts = 2
        ..shield = false
        ..collectedStars = 14
        ..score = 142
        ..combo = 14
        ..ammo = .7
        ..lastSprintAt = _antarctica - 6;
      sim.startCharge();
      sim.elapsed += .55;
      await f.redraw();
      await f.capture('touch-snow-partial-$w');
      sim.shoot();

      // The last heart at neon night, recovering after a hit, out of ammo
      // and mid-sprint.
      f.scene(_cyberpunk);
      sim
        ..hearts = 1
        ..shield = false
        ..collectedStars = 2
        ..invulnerableUntil = _cyberpunk + 1
        ..score = 87
        ..combo = 0
        ..ammo = 0
        ..lastShotAt = _cyberpunk
        ..lastSprintAt = _cyberpunk - .3;
      await f.redraw();
      await f.capture('touch-night-last-heart-$w');

      // Bonus hearts and an active magnet under a bright tropical sky.
      f.scene(_brazil, birdY: .82);
      sim
        ..hearts = 5
        ..shield = true
        ..invulnerableUntil = 0
        ..score = 1234
        ..combo = 12
        ..ammo = .45
        ..lastShotAt = -10
        ..lastSprintAt = -100
        ..magnetUntil = _brazil + 5.2;
      await f.redraw();
      await f.capture('touch-bright-bonus-$w');

      // No hearts left at dusk, the shield one star away and a magnet
      // two perfect gates in.
      f.scene(_mexico);
      sim
        ..hearts = 0
        ..shield = false
        ..collectedStars = 17
        ..score = 9
        ..combo = 0
        ..ammo = 1
        ..magnetUntil = 0
        ..magnetCharge = 2;
      await f.redraw();
      await f.capture('touch-dusk-empty-$w');

      // Countdown and pause over a Paris night.
      f.scene(_paris);
      sim
        ..hearts = 3
        ..shield = true
        ..score = 0
        ..magnetCharge = 0
        ..phase = RunPhase.countdown
        ..countdown = 2.6;
      await f.redraw();
      await f.capture('touch-countdown-$w');
      f.scene(_paris);
      sim
        ..score = 64
        ..phase = RunPhase.paused;
      await f.redraw();
      await f.capture('touch-paused-$w');

      // A boss fight: the boss plate replaces the score at the top.
      f.scene(_aztec);
      sim
        ..hearts = 2
        ..shield = true
        ..score = 212;
      final boss = bossAfter(BossKind.baronBat, 1, hits: [.2], since: .22)
        ..y = .5
        ..x = 1.45;
      sim.boss = boss;
      sim.obstacles.clear();
      await f.redraw();
      await f.capture('touch-boss-fight-$w');
      f.scene(_sea);
      sim
        ..hearts = 5
        ..shield = false
        ..collectedStars = 4;
      sim.boss = bossAfter(BossKind.pirate, 4, fight: 2, hits: [.3, .32])
        ..y = .5
        ..x = 1.45;
      sim.obstacles.clear();
      await f.redraw();
      await f.capture('touch-boss-pirate-$w');

      // During a boss cutscene only the pause button stays.
      f.scene(_aztec);
      sim.boss = SkyBoss(number: 1, x: 1.5, cinematic: true)..age = 1.2;
      sim.obstacles.clear();
      await f.redraw();
      await f.capture('touch-boss-cutscene-$w');
      sim.boss = null;

      // The legacy timed trail: a calm clock, then the final ten seconds.
      await _timedTrail(f, 18);
      await f.redraw();
      await f.capture('touch-clock-$w');
      f.scene(52);
      f.sim.score = 57;
      await f.redraw();
      await f.capture('touch-clock-final-$w');
    });

    testWidgets('camera HUD states at $w', (tester) async {
      final f = await _launch(tester, mode: 'pushup', size: size);
      final sim = f.sim;
      // Tracking stalls for a moment over the bright desert noon.
      f.scene(_egypt, birdY: .15);
      sim
        ..hearts = 3
        ..shield = false
        ..collectedStars = 7
        ..score = 48
        ..combo = 3;
      f.source.time += 300;
      await f.redraw();
      await f.capture('camera-finding-you-$w');
      f.scene(_egypt);
      sim
        ..phase = RunPhase.countdown
        ..countdown = 3;
      await f.redraw();
      await f.capture('camera-find-position-$w');
    });

    testWidgets('jump glide HUD states at $w', (tester) async {
      final f = await _launch(tester, mode: 'jump', size: size);
      final sim = f.sim;
      f.scene(_sea, birdY: .82);
      sim
        ..hearts = 3
        ..shield = true
        ..score = 18
        ..magnetCharge = 1;
      await f.redraw();
      await f.capture('jump-idle-$w');
      f.scene(_jungle, birdY: .82);
      f.source.time += 1;
      sim.apply(
        const MovementInput(valid: true, flap: true),
        TrackingSample(
          mode: PlayMode.jump,
          timestampMs: f.source.time,
          receivedMs: f.source.time,
          joints: const [],
        ),
        f.source.time,
      );
      sim.velocity = .05;
      await f.redraw();
      await f.capture('jump-gliding-magnet-$w');
      // The glide runs low and the plate warms.
      for (var i = 0; i < 100; i++) {
        f.source.time += 20;
        sim.apply(
          const MovementInput(valid: true),
          TrackingSample(
            mode: PlayMode.jump,
            timestampMs: f.source.time,
            receivedMs: f.source.time,
            joints: const [],
          ),
          f.source.time,
        );
        sim.tick(.02, f.source.time);
        sim
          ..birdY = .5
          ..velocity = .05;
        sim.obstacles.clear();
        sim.stars.clear();
      }
      expect(
        sim.glideRemaining,
        lessThan(FlightSimulation.glideEaseOutSeconds),
      );
      f.scene(_jungle, birdY: .6);
      await f.redraw();
      await f.capture('jump-glide-ending-$w');
    });
  }

  testWidgets('a notch inset keeps the bird clear at the top', (tester) async {
    tester.view.padding = const FakeViewPadding(left: 40);
    addTearDown(tester.view.resetPadding);
    final f = await _launch(tester, mode: 'touch', size: const Size(800, 360));
    f.scene(_antarctica, birdY: .15);
    f.sim
      ..hearts = 3
      ..shield = true
      ..score = 31
      ..combo = 7;
    await f.redraw();
    await f.capture('touch-notch-800');
  });

  testWidgets('finite HUD reactions with motion at 800', (tester) async {
    final f = await _launch(
      tester,
      mode: 'touch',
      size: const Size(800, 360),
      reduced: false,
    );
    final sim = f.sim;
    f.scene(_jungle);
    sim
      ..hearts = 3
      ..shield = false
      ..collectedStars = 8
      ..score = 40
      ..combo = 5;
    await f.redraw(after: const Duration(milliseconds: 600));
    // A heart breaks: caught mid-reaction, then settled.
    sim
      ..hearts = 2
      ..invulnerableUntil = sim.elapsed + 1.2;
    await f.redraw(after: const Duration(milliseconds: 70));
    await f.capture('motion-heart-lost-early');
    await f.tester.pump(const Duration(milliseconds: 90));
    await f.capture('motion-heart-lost-mid');
    await f.tester.pump(const Duration(milliseconds: 700));
    await f.capture('motion-heart-lost-settled');
    // Star, streak and shield in one beat.
    sim
      ..score = 43
      ..combo = 6
      ..collectedStars = 9
      ..shield = true
      ..invulnerableUntil = 0;
    await f.redraw(after: const Duration(milliseconds: 80));
    await f.capture('motion-score-pop');
    await f.tester.pump(const Duration(milliseconds: 700));
    // A heart pickup.
    sim.hearts = 3;
    await f.redraw(after: const Duration(milliseconds: 90));
    await f.capture('motion-heart-gained');
    await f.tester.pump(const Duration(milliseconds: 700));
    // Final seconds of a timed trail tick with a pop.
    await _timedTrail(f, 50.5);
    await f.redraw(after: const Duration(milliseconds: 600));
    f.scene(51.2);
    await f.redraw(after: const Duration(milliseconds: 80));
    await f.capture('motion-clock-tick');
    await f.tester.pump(const Duration(milliseconds: 700));
  });
}
