import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/obstacle.dart';
import 'package:push_up_bird/game/obstacle_art.dart';
import 'package:push_up_bird/game/obstacle_designs/crystal_steps.dart';
import 'package:push_up_bird/game/obstacle_designs/garden_gate.dart';
import 'package:push_up_bird/game/obstacle_designs/petal_shutters.dart';
import 'package:push_up_bird/game/obstacle_designs/switchback.dart';
import 'package:push_up_bird/game/obstacle_designs/wind_lift.dart';
import 'package:push_up_bird/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = 200;
  final ring = Rect.fromCenter(
    center: const Offset(100, 100),
    width: 46,
    height: 96,
  );

  Obstacle sample(ObstacleKind kind, {int appearance = 0}) {
    return Obstacle(
      x: .28,
      center: .5,
      gap: .34,
      width: kind.width,
      kind: kind,
      amplitude: 0,
      appearance: appearance,
    )..advance(1.2);
  }

  List<Rect> collisionRects(Obstacle obstacle) {
    final rects = <Rect>[];
    for (final passage in obstacle.passages) {
      for (final top in [true, false]) {
        final rect = Rect.fromLTRB(
          passage.x * size,
          top ? -10 : passage.bottom * size,
          (passage.x + passage.width) * size,
          top ? passage.top * size : size + 10,
        );
        if (!rect.isEmpty) rects.add(rect);
      }
    }
    return rects;
  }

  Future<Uint8List> raster(
    void Function(Canvas canvas) draw, [
    int extent = size,
  ]) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(extent, extent);
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
    return bytes;
  }

  Future<Uint8List> paintObstacle(
    Obstacle obstacle, {
    required bool refined,
    required double seconds,
    required bool reducedMotion,
  }) {
    return raster(
      (canvas) => ObstacleArt.paint(
        canvas,
        obstacle,
        size.toDouble(),
        seconds: seconds,
        reducedMotion: reducedMotion,
        cleared: false,
        perfect: false,
        refined: refined,
      ),
    );
  }

  Future<Uint8List> paintRing(
    Obstacle obstacle, {
    required bool refined,
    required double seconds,
    required bool reducedMotion,
  }) {
    return raster(
      (canvas) => ObstacleArt.ring(
        canvas,
        ring,
        obstacle,
        seconds: seconds,
        reducedMotion: reducedMotion,
        cleared: false,
        refined: refined,
      ),
    );
  }

  int differingPixels(Uint8List a, Uint8List b) {
    expect(a.length, b.length);
    var count = 0;
    for (var i = 0; i < a.length; i += 4) {
      if (a[i] != b[i] ||
          a[i + 1] != b[i + 1] ||
          a[i + 2] != b[i + 2] ||
          a[i + 3] != b[i + 3]) {
        count++;
      }
    }
    return count;
  }

  int alphaAt(Uint8List bytes, int x, int y, [int extent = size]) {
    return bytes[(y * extent + x) * 4 + 3];
  }

  int channelGap(Uint8List bytes, int x0, int y0, int x1, int y1) {
    final i = (y0 * size + x0) * 4;
    final j = (y1 * size + x1) * 4;
    var gap = 0;
    for (var channel = 0; channel < 3; channel++) {
      final delta = (bytes[i + channel] - bytes[j + channel]).abs();
      if (delta > gap) gap = delta;
    }
    return gap;
  }

  test(
    'refined and legacy art differ for every family and cruise rings',
    () async {
      for (final kind in ObstacleKind.values) {
        final obstacle = sample(kind);
        final refined = await paintObstacle(
          obstacle,
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        final legacy = await paintObstacle(
          obstacle,
          refined: false,
          seconds: 5,
          reducedMotion: true,
        );
        expect(
          differingPixels(refined, legacy),
          greaterThan(24),
          reason: '$kind artwork',
        );
        final refinedRing = await paintRing(
          obstacle,
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        final legacyRing = await paintRing(
          obstacle,
          refined: false,
          seconds: 5,
          reducedMotion: true,
        );
        expect(
          differingPixels(refinedRing, legacyRing),
          greaterThan(24),
          reason: '$kind ring',
        );
      }
    },
  );

  test(
    'fixed refined art repeats and Reduced Motion freezes animation at the same sky',
    () async {
      for (final kind in ObstacleKind.values) {
        final obstacle = sample(kind);
        expect(
          ObstacleArt.accent(obstacle, 5),
          ObstacleArt.accent(obstacle, 9),
        );
        final first = await paintObstacle(
          obstacle,
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        final repeat = await paintObstacle(
          obstacle,
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        final later = await paintObstacle(
          obstacle,
          refined: true,
          seconds: 9,
          reducedMotion: true,
        );
        expect(differingPixels(first, repeat), 0, reason: '$kind repeat');
        expect(
          differingPixels(first, later),
          0,
          reason: '$kind reduced motion',
        );
        final firstRing = await paintRing(
          obstacle,
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        final repeatRing = await paintRing(
          obstacle,
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        final laterRing = await paintRing(
          obstacle,
          refined: true,
          seconds: 9,
          reducedMotion: true,
        );
        expect(
          differingPixels(firstRing, repeatRing),
          0,
          reason: '$kind ring repeat',
        );
        expect(
          differingPixels(firstRing, laterRing),
          0,
          reason: '$kind ring reduced motion',
        );
      }
    },
  );

  test('every appearance variant renders', () async {
    for (final kind in ObstacleKind.values) {
      final frames = [
        for (var appearance = 0; appearance < 3; appearance++)
          await paintObstacle(
            sample(kind, appearance: appearance),
            refined: true,
            seconds: 5,
            reducedMotion: true,
          ),
      ];
      final rings = [
        for (var appearance = 0; appearance < 3; appearance++)
          await paintRing(
            sample(kind, appearance: appearance),
            refined: true,
            seconds: 5,
            reducedMotion: true,
          ),
      ];
      for (final frame in [...frames, ...rings]) {
        expect(frame.any((pixel) => pixel != 0), isTrue, reason: '$kind');
      }
      for (var i = 0; i < 3; i++) {
        expect(
          differingPixels(frames[i], frames[(i + 1) % 3]),
          greaterThan(0),
          reason: '$kind appearance',
        );
        expect(
          differingPixels(rings[i], rings[(i + 1) % 3]),
          greaterThan(0),
          reason: '$kind ring appearance',
        );
      }
    }
  });

  test(
    'refined solids stay opaque inside collision rects and clear outside',
    () async {
      const families = [
        ObstacleKind.garden,
        ObstacleKind.windLift,
        ObstacleKind.petalGate,
        ObstacleKind.switchback,
        ObstacleKind.crystalSteps,
      ];
      for (final kind in families) {
        final obstacle = sample(kind);
        final rects = collisionRects(obstacle);
        expect(rects, isNotEmpty);
        final bytes = await paintObstacle(
          obstacle,
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        var inside = 0;
        var outside = 0;
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            final px = x + .5;
            final py = y + .5;
            final covered = rects.any(
              (rect) =>
                  px >= rect.left + 2 &&
                  px < rect.right - 2 &&
                  py >= rect.top + 2 &&
                  py < rect.bottom - 2,
            );
            final clear = rects.every(
              (rect) =>
                  px < rect.left - 2 ||
                  px >= rect.right + 2 ||
                  py < rect.top - 2 ||
                  py >= rect.bottom + 2,
            );
            final alpha = alphaAt(bytes, x, y);
            if (covered) {
              inside++;
              expect(alpha, 255, reason: '$kind interior ($x, $y)');
            } else if (clear) {
              outside++;
              expect(alpha, 0, reason: '$kind exterior ($x, $y)');
            }
          }
        }
        expect(inside, greaterThan(40), reason: '$kind');
        expect(outside, greaterThan(40), reason: '$kind');
      }
    },
  );

  test('tiny short rectangles do not crash', () async {
    void paintThin(Canvas canvas, Rect rect, bool top) {
      const accent = SkyColors.teal;
      GardenGateDesign.paint(
        canvas,
        rect,
        top: top,
        seconds: 5,
        reducedMotion: true,
        cleared: top,
        perfect: top,
        appearance: 2,
        accent: accent,
      );
      WindLiftDesign.paint(
        canvas,
        rect,
        top: top,
        seconds: 5,
        reducedMotion: false,
        cleared: false,
        perfect: true,
        appearance: 1,
        accent: accent,
      );
      PetalShuttersDesign.paint(
        canvas,
        rect,
        top: top,
        seconds: 9,
        reducedMotion: true,
        cleared: true,
        perfect: false,
        appearance: 0,
        accent: accent,
      );
      SwitchbackDesign.paint(
        canvas,
        rect,
        top: top,
        seconds: 5,
        reducedMotion: false,
        cleared: false,
        perfect: false,
        appearance: 2,
        accent: accent,
      );
      CrystalStepsDesign.paint(
        canvas,
        rect,
        top: top,
        seconds: 5,
        reducedMotion: true,
        cleared: true,
        perfect: true,
        appearance: 1,
        accent: accent,
      );
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final top in [true, false]) {
      for (final rect in const [
        Rect.fromLTWH(1, 1, .7, 30),
        Rect.fromLTWH(8, 4, 24, .4),
        Rect.fromLTWH(40, 40, .25, .35),
        Rect.fromLTWH(0, 0, 0, 12),
      ]) {
        paintThin(canvas, rect, top);
      }
    }
    for (final kind in ObstacleKind.values) {
      final narrow = Obstacle(
        x: .2,
        center: .5,
        gap: .2,
        width: .003,
        kind: kind,
        amplitude: 0,
      );
      ObstacleArt.paint(
        canvas,
        narrow,
        80,
        seconds: 5,
        reducedMotion: true,
        cleared: false,
        perfect: false,
      );
      ObstacleArt.ring(
        canvas,
        const Rect.fromLTWH(2, 2, 3, 8),
        narrow,
        seconds: 5,
        reducedMotion: true,
        cleared: false,
      );
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    image.dispose();
    picture.dispose();

    for (final (label, paint) in [
      (
        'garden',
        (Canvas canvas, Rect rect) => GardenGateDesign.paint(
          canvas,
          rect,
          top: true,
          seconds: 5,
          reducedMotion: true,
          cleared: false,
          perfect: false,
          appearance: 0,
          accent: SkyColors.teal,
        ),
      ),
      (
        'switchback',
        (Canvas canvas, Rect rect) => SwitchbackDesign.paint(
          canvas,
          rect,
          top: false,
          seconds: 5,
          reducedMotion: true,
          cleared: false,
          perfect: false,
          appearance: 1,
          accent: SkyColors.purple,
        ),
      ),
    ]) {
      final bytes = await raster((canvas) {
        paint(canvas, const Rect.fromLTWH(4, 2, .8, 36));
      }, 48);
      expect(
        bytes.any((pixel) => pixel != 0),
        isTrue,
        reason: '$label still paints a thin collision solid',
      );
    }
  });

  test(
    'refined circles are filled with a drawn edge and rings stay open',
    () async {
      for (final kind in [ObstacleKind.lanternDrift, ObstacleKind.sunWheels]) {
        final obstacle = sample(kind);
        final bytes = await paintObstacle(
          obstacle,
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        expect(obstacle.orbs, isNotEmpty);
        for (final orb in obstacle.orbs) {
          final cx = orb.x * size;
          final cy = orb.y * size;
          final radius = orb.radius * size;
          final centerX = cx.round();
          final centerY = cy.round();
          expect(alphaAt(bytes, centerX, centerY), 255, reason: '$kind center');
          var drawnEdges = 0;
          for (var step = 0; step < 8; step++) {
            final angle = step * math.pi / 4;
            final inwardX = (cx + math.cos(angle) * (radius - 1.6)).round();
            final inwardY = (cy + math.sin(angle) * (radius - 1.6)).round();
            final outwardX = (cx + math.cos(angle) * (radius + 3)).round();
            final outwardY = (cy + math.sin(angle) * (radius + 3)).round();
            expect(alphaAt(bytes, inwardX, inwardY), 255, reason: '$kind fill');
            final tether =
                kind == ObstacleKind.lanternDrift && (step == 2 || step == 6);
            if (!tether) {
              expect(
                alphaAt(bytes, outwardX, outwardY),
                0,
                reason: '$kind edge',
              );
            }
            if (channelGap(bytes, centerX, centerY, inwardX, inwardY) >= 12) {
              drawnEdges++;
            }
          }
          expect(drawnEdges, greaterThanOrEqualTo(4), reason: '$kind rim');
        }
      }

      for (final kind in ObstacleKind.values) {
        final bytes = await paintRing(
          sample(kind),
          refined: true,
          seconds: 5,
          reducedMotion: true,
        );
        for (var dy = -6; dy <= 6; dy++) {
          for (var dx = -6; dx <= 6; dx++) {
            expect(
              alphaAt(bytes, 100 + dx, 100 + dy),
              0,
              reason: '$kind center',
            );
          }
        }
        var rim = 0;
        for (var step = 0; step < 36; step++) {
          final angle = step * math.pi * 2 / 36;
          for (final scale in [.9, 1.0]) {
            final x = (100 + math.cos(angle) * 23 * scale).round();
            final y = (100 + math.sin(angle) * 48 * scale).round();
            if (alphaAt(bytes, x, y) > 40) rim++;
          }
        }
        expect(rim, greaterThan(8), reason: '$kind ring');
      }
    },
  );
}
