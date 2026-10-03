import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/star_group_aura.dart';
import 'star_magnet_test.dart' show FlightHarness;
import 'replay_highlights_test.dart' show recordRoute;

Future<List<int>> pixels(void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(640, 360);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Future<List<int>> aura(StarTrio group, double time, {bool reduced = false}) =>
    pixels(
      (canvas) => StarGroupAura.paint(
        canvas,
        360,
        group,
        seconds: time,
        reducedMotion: reduced,
      ),
    );

BirdGame gameFor(FlightSimulation sim) {
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 2,
    reducedMotion: false,
    onChanged: () {},
    playback: true,
  );
  game.onGameResize(Vector2(640, 360));
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('partial and missed groups paint nothing at all', () async {
    final group = StarTrio(x: 1, y: .5);
    for (final mask in [0, 1, 3, 5, 6, 7]) {
      group.collectedMask = mask;
      expect((await aura(group, 10)).every((v) => v == 0), isTrue);
    }
    group.completedAt = 10;
    group.missed = true;
    expect((await aura(group, 10.1)).every((v) => v == 0), isTrue);
  });

  test(
    'a complete group paints only around its last star, then expires',
    () async {
      final group = StarTrio(x: 1, y: .5)
        ..collectedMask = 7
        ..completedAt = 10
        ..completedY = .5;
      for (final reduced in [true, false]) {
        final first = await aura(group, 10.1, reduced: reduced);
        expect(first.any((v) => v != 0), isTrue);
        // The last star is at x=1.17, y=.5; nothing may be drawn elsewhere.
        for (var y = 0; y < 360; y++) {
          for (var x = 0; x < 640; x++) {
            if ((Offset(x.toDouble(), y.toDouble()) - const Offset(421.2, 180))
                    .distance >
                28) {
              expect(first[(y * 640 + x) * 4 + 3], 0);
            }
          }
        }
        expect(await aura(group, 10.4, reduced: reduced), isNot(equals(first)));
        expect(await aura(group, 10.1, reduced: reduced), first);
        for (final time in [9.9, 10.66, 20.0]) {
          expect(
            (await aura(group, time, reduced: reduced)).every((v) => v == 0),
            isTrue,
          );
        }
        group.x -= .1;
        expect(await aura(group, 10.1, reduced: reduced), isNot(equals(first)));
        group.x += .1;
      }
    },
  );

  test(
    'the halo stays at the collected height when its passage moves',
    () async {
      final passage = Obstacle(x: 1.25, center: .5, gap: .4);
      final group = StarTrio(x: 1, y: .5, passage: passage)
        ..collectedMask = 7
        ..completedAt = 10
        ..completedY = .35;
      final frozen = await aura(group, 10.2);
      final detached = StarTrio(x: 1, y: .35)
        ..collectedMask = 7
        ..completedAt = 10;
      expect(await aura(detached, 10.2), frozen);
    },
  );

  test(
    'star rewards and multipliers do not alter the bird or add labels',
    () async {
      final sim = FlightHarness().sim..elapsed = 10;
      final game = gameFor(sim);
      final before = await pixels(game.render);
      sim.combo = 12;
      sim.events.addAll([
        const FlightEvent(FlightEventKind.star, 9.9, .5, value: 3),
        const FlightEvent(FlightEventKind.starTrio, 9.9, .5, value: 5),
        const FlightEvent(FlightEventKind.streak, 9.9, .5, value: 3),
      ]);
      expect(await pixels(game.render), before);
      final group = StarTrio(x: 1, y: .5)
        ..collectedMask = 7
        ..completedAt = 9.9
        ..completedY = .5;
      sim.starTrios.add(group);
      final complete = await pixels(game.render);
      expect(complete, isNot(equals(before)));
      // A wide rectangle around and below the bird must remain pixel-identical.
      for (var y = 115; y < 245; y++) {
        for (var x = 85; x < 280; x++) {
          final at = (y * 640 + x) * 4;
          expect(complete.sublist(at, at + 4), before.sublist(at, at + 4));
        }
      }
    },
  );

  test('version 30 restores the same complete-group scoring as version 29', () {
    final tape = recordRoute(FlightCourse.starTrail, rulesVersion: 30);
    final old = ReplayTape.fromJson(tape.toJson()..['version'] = 29);
    final current = ReplayPlayer(tape)..seek(tape.durationMs);
    final legacy = ReplayPlayer(old)..seek(old.durationMs);
    List<Object> state(FlightSimulation s) => [
      s.score,
      s.collectedStars,
      s.completedTrios,
      s.combo,
      s.bestCombo,
      s.birdY,
      s.distance,
      s.hearts,
      for (final o in s.obstacles) [o.x, o.target, o.kind, o.scored],
    ];
    expect(state(current.simulation), state(legacy.simulation));
    expect(current.simulation.subtleStarRewards, isTrue);
    expect(legacy.simulation.subtleStarRewards, isFalse);
  });

  test('render actual group collection at phone scale', () async {
    if (!const bool.fromEnvironment('CAPTURE_STAR_AURA')) return;
    final h = FlightHarness(practice: true);
    h.step();
    h.sim.obstacles.clear();
    h.sim.stars.clear();
    h.sim.starTrios.clear();
    final group = StarTrio(x: .83, y: .5);
    h.sim.starTrios.add(group);
    h.sim.stars.addAll([
      for (var i = 0; i < 3; i++)
        SkyStar(x: group.x + (i - 1) * .17, y: .5, trio: group, trioSlot: i),
    ]);
    h.sim.obstacles.add(Obstacle(x: 1.45, center: .5, gap: .46));
    final game = gameFor(h.sim);
    final dir = Directory('build/visual-review/star-aura')
      ..createSync(recursive: true);
    for (var frame = 0; frame < 120; frame++) {
      h.step(1 / 30);
      final recorder = ui.PictureRecorder();
      game.render(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(640, 360);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${dir.path}/frame-${frame.toString().padLeft(3, '0')}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      if (group.completedAt != null &&
          h.sim.elapsed - group.completedAt! < .04) {
        File(
          '${dir.path}/completed.png',
        ).writeAsBytesSync(bytes.buffer.asUint8List());
      }
      image.dispose();
      picture.dispose();
    }
    expect(h.sim.completedTrios, 1);
  });
}
