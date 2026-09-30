import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/arrival_art.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'campaign_flight.dart' show levelFlight;
import 'campaign_play_test.dart' show launchLevel, level, loadFonts, redraw;
import 'recorded_flight.dart' show rideTheSky;

/// Review frames of a campaign flight: the level HUD (stars, marks, route
/// and the controls a level offers), the finish line's approach and
/// crossing, and each boss's name card with its campaign line, at 800×360
/// and 640×360.
///
/// Run with `--dart-define=CAPTURE_CAMPAIGN_FLIGHT=true` to write PNGs to
/// build/visual-review/campaign/flight/. Without it the frames still render,
/// so the suite checks that none of them throws or overflows.
const _capture = bool.fromEnvironment('CAPTURE_CAMPAIGN_FLIGHT');
const _folder = 'build/visual-review/campaign/flight';
const _sizes = [Size(800, 360), Size(640, 360)];

TrackingSample _touch(double now) => TrackingSample(
  mode: PlayMode.touch,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);

/// Flies [sim] with the shared bot, hearts topped up, until [until] holds
/// or the flight ends.
void _fly(
  FlightSimulation sim,
  bool Function(FlightSimulation sim) until, {
  double width = 2.2,
  bool sprint = true,
}) {
  var now = sim.elapsed * 1000;
  for (var frame = 1; frame <= 400 * 50; frame++) {
    if (sim.phase == RunPhase.ended || until(sim)) return;
    now += 20;
    if (sim.hearts < 2) sim.hearts = 3;
    sim.apply(
      MovementInput(valid: true, height: .5, flap: rideTheSky(sim)),
      _touch(now),
      now,
    );
    if (sprint && sim.canSprint) sim.sprint();
    switch (frame % 90) {
      case 0:
        sim.startCharge();
      case 30:
        sim.shoot();
      default:
        if (frame % 9 == 0 && !sim.charging && sim.canShoot) sim.shoot();
    }
    sim.tick(.02, now, viewportWidth: width);
  }
}

/// Holds the bird still in the middle of the sky for [seconds].
void _hover(FlightSimulation sim, double seconds, {double width = 2.2}) {
  var now = sim.elapsed * 1000;
  for (var i = 0; i < (seconds / .02).round(); i++) {
    now += 20;
    sim
      ..birdY = .5
      ..velocity = 0
      ..hearts = 3;
    sim.apply(const MovementInput(valid: true), _touch(now), now);
    sim.tick(.02, now, viewportWidth: width);
  }
}

Future<void> _screen(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    await _save(image, name);
    image.dispose();
  });
}

Future<void> _save(ui.Image image, String name) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

/// A loaded, paused game for [sim] at [size], rendered by hand.
Future<BirdGame> _game(
  WidgetTester tester,
  FlightSimulation sim,
  Size size, {
  bool reduced = false,
  int bird = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: bird,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  return game;
}

Future<void> _frame(
  WidgetTester tester,
  BirdGame game,
  Size size,
  String name,
) async {
  if (!_capture) {
    game.render(ui.Canvas(ui.PictureRecorder()));
    return;
  }
  await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    await _save(image, name);
    image.dispose();
    picture.dispose();
  });
}

/// Only the name card layer (letterbox, card and caption), as raw RGBA.
Future<Uint8List> _card(
  FlightSimulation sim,
  Size size, {
  bool reduced = false,
}) async {
  final recorder = ui.PictureRecorder();
  BossEncounterArt.foreground(
    ui.Canvas(recorder),
    size,
    sim,
    BossMotion(sim.boss!, reducedMotion: reduced),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

/// A flight of a chapter's boss level with its boss at [age] into its
/// entrance, or an endless flight with the same boss when [campaign] is
/// false.
FlightSimulation _encounter(
  CampaignChapter chapter, {
  required double age,
  bool campaign = true,
}) {
  final sim = campaign
      ? levelFlight(chapter.bossLevel)
      : FlightSimulation(
          rules: TapFlyMode(),
          practice: false,
          course: FlightCourse.starTrail,
        );
  sim
    ..phase = RunPhase.playing
    ..started = true
    ..birdY = .52
    ..boss = (SkyBoss(
      number: chapter.boss.index + 1,
      x: 1.5,
      kind: chapter.boss,
      cinematic: true,
      debut: true,
    )..age = age);
  return sim;
}

void main() {
  setUpAll(() async {
    await loadFonts();
    // Each capture launches its own in-memory play screen.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('boss lines', () {
    test('only campaign boss levels carry a line, in quotes', () {
      for (final chapter in Campaign.chapters) {
        final line = BossEncounterArt.bossLine(_encounter(chapter, age: 3));
        expect(line, '“${chapter.bossLine}”');
        expect(
          BossEncounterArt.bossLine(
            _encounter(chapter, age: 3, campaign: false),
          ),
          isNull,
        );
      }
    });

    for (final size in _sizes) {
      final w = size.width.toInt();
      test('each line sits under the epithet and fits at $w', () async {
        for (final chapter in Campaign.chapters) {
          for (final reduced in [false, true]) {
            final campaign = await _card(
              _encounter(chapter, age: 3.2),
              size,
              reduced: reduced,
            );
            final endless = await _card(
              _encounter(chapter, age: 3.2, campaign: false),
              size,
              reduced: reduced,
            );
            // Where the two cards visibly differ: the line and its deeper
            // shade. The soft shade's blur may round a level apart anywhere.
            var top = size.height.toInt(), bottom = -1, right = -1;
            for (var y = 0; y < size.height; y++) {
              for (var x = 0; x < w; x++) {
                final i = (y * w + x) * 4;
                var apart = 0;
                for (var k = 0; k < 4; k++) {
                  apart = math.max(
                    apart,
                    (campaign[i + k] - endless[i + k]).abs(),
                  );
                }
                if (apart <= 6) continue;
                if (y < top) top = y;
                if (y > bottom) bottom = y;
                if (x > right) right = x;
              }
            }
            final name = '${chapter.boss.name} reduced: $reduced';
            expect(bottom, greaterThan(0), reason: '$name shows no line');
            // Everything down to the epithet is untouched (the Pirate
            // Captain's scroll widens around the line instead), and the
            // line stays clear of the caption's letterbox bar.
            if (chapter.boss != BossKind.pirate) {
              expect(top, greaterThan(size.height * .29), reason: name);
            }
            expect(bottom, lessThan(size.height * .9), reason: name);
            expect(right, lessThan(w - 24), reason: name);
          }
        }
      });
    }

    test('lines fade with the card', () async {
      final chapter = Campaign.chapters.first;
      for (final age in [1.2, 4.6]) {
        expect(
          await _card(_encounter(chapter, age: age), _sizes.first),
          await _card(
            _encounter(chapter, age: age, campaign: false),
            _sizes.first,
          ),
          reason: 'at $age s',
        );
      }
    });
  });

  group('finish line', () {
    test('it scrolls in and meets the bird as the level completes', () {
      final sim = levelFlight(level('1-1'));
      final xs = <double>[];
      _fly(sim, (sim) {
        if (sim.finishLine != null) xs.add(ArrivalPose.forFlight(sim)!.x);
        return false;
      });
      expect(sim.endReason, EndReason.completed);
      // Laid beyond the right edge, it only ever moves left.
      expect(xs.first, greaterThan(2.2 + .16));
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], lessThanOrEqualTo(xs[i - 1]));
      }
      final pose = ArrivalPose.forFlight(sim)!;
      expect(pose.arrived, isTrue);
      expect(pose.reveal, 1);
      expect(pose.x, closeTo(FlightSimulation.birdX, .02));
      expect(pose.x, sim.finishLine!.x);
    });

    test('Reduced Motion stills the pennants', () async {
      final sim = levelFlight(level('1-2'));
      _fly(sim, (sim) => (sim.finishLine?.x ?? 9) < 1.4);
      Future<Uint8List> pixels({required bool reduced}) async {
        final recorder = ui.PictureRecorder();
        ArrivalArt.gate(ui.Canvas(recorder), 360, sim, reducedMotion: reduced);
        final picture = recorder.endRecording();
        final image = await picture.toImage(800, 360);
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        return bytes;
      }

      final line = sim.finishLine!;
      final still = await pixels(reduced: true);
      final moving = await pixels(reduced: false);
      // The same place a moment later: only the flutter differs.
      sim.elapsed += .4;
      expect(await pixels(reduced: true), still);
      expect(await pixels(reduced: false), isNot(moving));
      expect(line.x, sim.finishLine!.x);
    });

    test('a knockout leaves the line in the world, not arrived', () {
      final sim = levelFlight(level('1-1'));
      _fly(sim, (sim) => (sim.finishLine?.x ?? 9) < 1.2);
      sim.end(EndReason.collision);
      final pose = ArrivalPose.forFlight(sim)!;
      expect(pose.arrived, isFalse);
      expect(pose.x, sim.finishLine!.x);
    });
  });

  for (final size in _sizes) {
    final w = size.width.toInt();

    testWidgets('level HUD frames at $w', (tester) async {
      // The whole kit: stars and marks, the route and both controls.
      var f = await launchLevel(tester, level('2-1'), size: size);
      var sim = f.controller.simulation!;
      _fly(sim, (sim) => sim.elapsed > 3.4);
      await redraw(tester, f.controller);
      await _screen(tester, 'hud-start-2-1-$w');
      _fly(sim, (sim) => sim.routeProgress > .55);
      sim.collectedStars = level('2-1').marks.two + 7;
      await redraw(tester, f.controller);
      await _screen(tester, 'hud-mid-2-1-$w');
      await tester.runAsync(f.controller.exit);

      // The first level holds Shoot and Sprint back.
      f = await launchLevel(tester, level('1-1'), size: size, bird: 1);
      sim = f.controller.simulation!;
      _fly(sim, (sim) => sim.countdown < 2.5);
      await redraw(tester, f.controller);
      await _screen(tester, 'hud-countdown-1-1-$w');
      _fly(sim, (sim) => sim.routeProgress > .3);
      sim.collectedStars = 18;
      await redraw(tester, f.controller);
      await _screen(tester, 'hud-no-controls-1-1-$w');
      await tester.runAsync(f.controller.exit);

      // Shoot arrives first; every mark reached.
      f = await launchLevel(tester, level('1-3'), size: size, bird: 2);
      sim = f.controller.simulation!;
      _fly(sim, (sim) => sim.routeProgress > .8);
      sim.collectedStars = level('1-3').marks.three + 4;
      await redraw(tester, f.controller);
      await _screen(tester, 'hud-shoot-only-1-3-$w');
      await tester.runAsync(f.controller.exit);

      // The finish line scrolls in, then reaches the bird.
      f = await launchLevel(tester, level('1-4'), size: size, bird: 3);
      sim = f.controller.simulation!;
      _fly(sim, (sim) => (sim.finishLine?.x ?? 9) < 1.55);
      await redraw(tester, f.controller);
      await _screen(tester, 'finish-approach-1-4-$w');
      _fly(sim, (sim) => (sim.finishLine?.x ?? 9) < .72);
      await redraw(tester, f.controller);
      await _screen(tester, 'finish-near-1-4-$w');
      await tester.runAsync(f.controller.exit);

      // A boss level marks the lair on its route; after the fight the
      // victory glide fills the rest, and the bird coasts without controls.
      f = await launchLevel(tester, level('1-8'), size: size, bird: 1);
      sim = f.controller.simulation!;
      _fly(sim, (sim) => sim.routeProgress > .5);
      await redraw(tester, f.controller);
      expect(find.byKey(const ValueKey('touch-shoot')), findsOneWidget);
      await _screen(tester, 'hud-boss-run-up-1-8-$w');
      _fly(sim, (sim) => (sim.finishLine?.x ?? 9) < 1.2);
      expect(sim.victoryGlide, isTrue);
      await redraw(tester, f.controller);
      expect(find.byKey(const ValueKey('level-route')), findsOneWidget);
      expect(find.byKey(const ValueKey('touch-shoot')), findsNothing);
      expect(find.byKey(const ValueKey('touch-sprint')), findsNothing);
      await _screen(tester, 'hud-victory-glide-1-8-$w');
      await tester.runAsync(f.controller.exit);
    });

    testWidgets('a level result hides only the bird in the frozen finish at '
        '$w', (tester) async {
      final sim = levelFlight(level('1-4'));
      _fly(sim, (_) => false);
      expect(sim.endReason, EndReason.completed);
      final game = await _game(tester, sim, size, bird: 3);
      Future<Uint8List> pixels() async => (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        return bytes;
      }))!;
      final shown = await pixels();
      game.hideBird = true;
      final hidden = await pixels();
      await _frame(tester, game, size, 'finish-crossed-no-bird-1-4-$w');
      final h = size.height;
      final bird = Offset(FlightSimulation.birdX * h, sim.birdY * h);
      var near = 0, far = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < size.width; x++) {
          final i = (y * size.width.toInt() + x) * 4;
          var same = true;
          for (var c = 0; c < 4; c++) {
            same &= shown[i + c] == hidden[i + c];
          }
          if (same) continue;
          (Offset(x + .5, y + .5) - bird).distance < h * .15 ? near++ : far++;
        }
      }
      expect(near, greaterThan(500), reason: 'the bird is gone');
      expect(far, 0, reason: 'the finish and scenery stay');
    });

    testWidgets('finish crossing and victory glide frames at $w', (
      tester,
    ) async {
      // The crossing's last frame, as the result screen will freeze it.
      var sim = levelFlight(level('1-4'));
      _fly(sim, (_) => false);
      expect(sim.endReason, EndReason.completed);
      var game = await _game(tester, sim, size, bird: 3);
      await _frame(tester, game, size, 'finish-crossed-1-4-$w');

      // With motion, over another region.
      sim = levelFlight(level('2-4'));
      _fly(sim, (sim) => (sim.finishLine?.x ?? 9) < 1.1);
      game = await _game(tester, sim, size);
      await _frame(tester, game, size, 'finish-motion-2-4-$w');

      // A boss level: the line follows the fallen boss.
      sim = levelFlight(level('1-8'));
      _fly(sim, (sim) => sim.finishLine != null && sim.finishLine!.x < 1.3);
      expect(sim.bossesDefeated, 1);
      game = await _game(tester, sim, size, bird: 1);
      await _frame(tester, game, size, 'finish-after-boss-1-8-$w');
    });

    testWidgets('name cards with lines at $w', (tester) async {
      for (final chapter in Campaign.chapters) {
        // Fly the real run-up so the boss arrives over its own sky.
        final sim = levelFlight(chapter.bossLevel);
        _fly(sim, (sim) => sim.boss != null, width: size.width / 360);
        _hover(sim, 3.2 - sim.boss!.age, width: size.width / 360);
        final game = await _game(tester, sim, size, bird: chapter.number % 4);
        final tag = '${chapter.number}-${chapter.boss.name}';
        await _frame(tester, game, size, 'card-$tag-$w');
        if (chapter.number <= 2) {
          final still = await _game(
            tester,
            sim,
            size,
            reduced: true,
            bird: chapter.number % 4,
          );
          await _frame(tester, still, size, 'card-$tag-reduced-$w');
        }
      }
    });
  }
}
