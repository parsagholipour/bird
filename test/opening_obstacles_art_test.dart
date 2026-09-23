import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/obstacle_art.dart';

import 'experience_ui_test.dart' show capture;

const _phone = Size(1000, 450);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  test(
    'fresh flights use the current rules and garden gates for 18 seconds',
    () {
      for (final course in FlightCourse.values) {
        for (final mode in PlayMode.values) {
          final flight = _fly(mode, course, seconds: 18);
          final sim = flight.sim;
          final label = '${course.name}/${mode.name}';
          expect(
            sim.rulesVersion,
            FlightSimulation.currentRulesVersion,
            reason: label,
          );
          expect(sim.rulesVersion, greaterThanOrEqualTo(14), reason: label);
          expect(flight.openingKinds, {ObstacleKind.garden}, reason: label);
          expect(flight.spawnX, greaterThan(_phone.width / _phone.height));
          expect(
            sim.phase,
            RunPhase.playing,
            reason: '$label ${sim.endReason}',
          );
          expect(sim.elapsed, greaterThanOrEqualTo(18), reason: label);
          expect(sim.boss, isNull, reason: label);
          expect(flight.sawStars, course.collectsStars, reason: label);
          expect(flight.sawEnemy, mode == PlayMode.touch, reason: label);
        }
      }
    },
  );

  testWidgets('opening scenes render refined garden art at phone size', (
    tester,
  ) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const scenes = [
      ('opening-classic', PlayMode.pushUp, FlightCourse.classic),
      ('opening-touch-combat', PlayMode.touch, FlightCourse.starTrail),
      ('opening-star-trail', PlayMode.pushUp, FlightCourse.starTrail),
    ];
    for (final (name, mode, course) in scenes) {
      final flight = _fly(mode, course, seconds: 12, untilGateOnScreen: true);
      final sim = flight.sim;
      expect(sim.rulesVersion, FlightSimulation.currentRulesVersion);
      expect(flight.openingKinds, {ObstacleKind.garden});
      expect(sim.phase, RunPhase.playing, reason: '$name ${sim.endReason}');
      expect(sim.elapsed, lessThan(18));
      expect(sim.boss, isNull);
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: false,
        onChanged: () {},
        playback: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('visual-capture'),
            child: GameWidget(game: game),
          ),
        ),
      );
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(game.size.x, _phone.width);
      expect(game.size.y, _phone.height);
      final gate = sim.obstacles.firstWhere(
        (o) =>
            o.x > FlightSimulation.birdX &&
            (o.x + o.width) * game.size.y < game.size.x,
      );
      expect(gate.kind, ObstacleKind.garden);
      await _expectRefinedRoute(tester, game, gate, name);
      await capture(tester, name);
      await tester.pumpWidget(const SizedBox());
    }
  });
}

class _Flight {
  const _Flight({
    required this.sim,
    required this.openingKinds,
    required this.spawnX,
    required this.sawStars,
    required this.sawEnemy,
  });
  final FlightSimulation sim;
  final Set<ObstacleKind> openingKinds;
  final double spawnX;
  final bool sawStars, sawEnemy;
}

_Flight _fly(
  PlayMode mode,
  FlightCourse course, {
  required double seconds,
  bool untilGateOnScreen = false,
}) {
  var now = 0.0;
  final recorder = FlightRecorder(
    ReplayTape(
      mode: mode,
      course: course,
      practice: false,
      seed: 7,
      cycleSeconds: 3,
      bird: 0,
      reducedMotion: false,
      originMs: 0,
    ),
    () => now,
  );
  final sim = recorder.simulation;
  final aspect = _phone.width / _phone.height;
  final opening = <ObstacleKind>{};
  double? spawnX;
  var sawStars = false, sawEnemy = false;
  for (
    var frame = 0;
    frame < 2500 && sim.phase != RunPhase.ended && sim.elapsed < seconds;
    frame++
  ) {
    now += 20;
    final overlapping = sim.obstacles.where(
      (o) =>
          o.x < FlightSimulation.birdX + FlightSimulation.birdRadius &&
          o.x + o.width > FlightSimulation.birdX - FlightSimulation.birdRadius,
    );
    final upcoming = overlapping.isNotEmpty
        ? overlapping
        : sim.obstacles.where((o) => o.x > FlightSimulation.birdX);
    final aim = upcoming.isEmpty ? .5 : upcoming.first.target;
    recorder.apply(
      MovementInput(
        valid: true,
        height: (.85 - aim) / .7,
        flap: !mode.controlsHeight && sim.birdY > aim + .06 && sim.velocity > 0,
      ),
      TrackingSample(
        mode: mode,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    if (!untilGateOnScreen && sim.canShoot) recorder.command('shoot');
    recorder.tick(.02, now, aspect);
    spawnX ??= sim.obstacles.isEmpty ? null : sim.obstacles.first.x;
    for (final obstacle in sim.obstacles) {
      if (obstacle.bornAt < 18) opening.add(obstacle.kind);
    }
    if (sim.stars.isNotEmpty) sawStars = true;
    if (sim.enemies.isNotEmpty) sawEnemy = true;
    if (untilGateOnScreen &&
        sim.obstacles.any(
          (o) =>
              o.x > FlightSimulation.birdX + .25 &&
              o.x + o.width < aspect - .02,
        )) {
      break;
    }
  }
  return _Flight(
    sim: sim,
    openingKinds: opening,
    spawnX: spawnX ?? 0,
    sawStars: sawStars,
    sawEnemy: sawEnemy,
  );
}

Future<void> _expectRefinedRoute(
  WidgetTester tester,
  BirdGame game,
  Obstacle gate,
  String name,
) async {
  final size = game.size;
  final sim = game.simulation;
  Future<Uint8List> raster(void Function(Canvas canvas) draw) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final bytes = await tester.runAsync(() async {
      final image = await picture.toImage(size.x.ceil(), size.y.ceil());
      final data = (await image.toByteData())!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
      return data;
    });
    return bytes!;
  }

  void paintArt(Canvas canvas, {required bool refined}) {
    final h = size.y;
    ObstacleArt.paint(
      canvas,
      gate,
      h,
      seconds: sim.elapsed,
      reducedMotion: false,
      cleared: false,
      perfect: false,
      refined: refined,
    );
  }

  final scene = await raster(game.render);
  final refined = await raster((canvas) => paintArt(canvas, refined: true));
  final legacy = await raster((canvas) => paintArt(canvas, refined: false));
  final h = size.y;
  late final Rect probe;
  {
    final passage = gate.passages.reduce(
      (a, b) => (b.bottom - b.top) > (a.bottom - a.top) ? a : b,
    );
    // The taller solid is the lower tower when the opening sits high.
    final lower = passage.bottom * h;
    final upper = passage.top * h;
    if (size.y - lower > upper) {
      probe = Rect.fromLTRB(
        (passage.x + passage.width * .45) * h,
        lower + 10,
        (passage.x + passage.width * .92) * h,
        math.min(size.y - 6, lower + 70),
      );
    } else {
      probe = Rect.fromLTRB(
        (passage.x + passage.width * .45) * h,
        math.max(4, upper * .25),
        (passage.x + passage.width * .92) * h,
        upper - 6,
      );
    }
  }
  final width = size.x.ceil();
  var solid = 0, refinedHits = 0, legacyHits = 0;
  for (var y = probe.top.ceil(); y < probe.bottom.floor(); y += 2) {
    for (var x = probe.left.ceil(); x < probe.right.floor(); x += 2) {
      if (x < 0 || y < 0 || x >= width || y >= size.y) continue;
      final i = (y * width + x) * 4;
      if (refined[i + 3] != 255) continue;
      solid++;
      if (_same(scene, refined, i)) refinedHits++;
      if (_same(scene, legacy, i)) legacyHits++;
    }
  }
  expect(solid, greaterThan(8), reason: '$name art probe was empty');
  expect(
    refinedHits,
    greaterThan(solid ~/ 2),
    reason: '$name bypassed refined ObstacleArt ($refinedHits/$solid)',
  );
  expect(
    refinedHits,
    greaterThan(legacyHits),
    reason: '$name matched the pre-14 fallback ($legacyHits) at least as often',
  );
}

bool _same(Uint8List a, Uint8List b, int i) =>
    a[i] == b[i] &&
    a[i + 1] == b[i + 1] &&
    a[i + 2] == b[i + 2] &&
    a[i + 3] == b[i + 3];
