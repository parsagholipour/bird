import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/obstacle.dart';
import 'package:push_up_bird/game/obstacle_art.dart';
import 'package:push_up_bird/game/obstacle_designs/garden_gate.dart';
import 'package:push_up_bird/game/obstacle_designs/kit.dart';
import 'package:push_up_bird/game/obstacle_designs/regional.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = 200;

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

  test('refined and legacy art differ for every family', () async {
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
    }
  });

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
      for (final frame in frames) {
        expect(frame.any((pixel) => pixel != 0), isTrue, reason: '$kind');
      }
      for (var i = 0; i < 3; i++) {
        expect(
          differingPixels(frames[i], frames[(i + 1) % 3]),
          greaterThan(0),
          reason: '$kind appearance',
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
      for (final region in WorldRegion.values) {
        for (final kind in ObstacleKind.values) {
          if (kind.floating) continue;
          RegionalObstacles.column(
            region,
            canvas,
            rect,
            kind: kind,
            top: top,
            seconds: 5,
            reducedMotion: kind.index.isEven,
            pass: PassState(cleared: top, perfect: kind.index.isOdd),
            appearance: kind.index,
          );
        }
      }
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final top in [true, false]) {
      for (final rect in const [
        Rect.fromLTWH(1, 1, .7, 30),
        Rect.fromLTWH(8, 4, 24, .4),
        Rect.fromLTWH(40, 40, .25, .35),
        Rect.fromLTWH(0, 0, 0, 12),
        Rect.fromLTWH(2, 2, 14, 9),
      ]) {
        paintThin(canvas, rect, top);
      }
    }
    for (final region in WorldRegion.values) {
      for (final kind in ObstacleKind.values) {
        final narrow = Obstacle(
          x: .2,
          center: .5,
          gap: .2,
          width: .003,
          kind: kind,
          amplitude: 0,
          bornAt: region.index * WorldTour.leg + 1,
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
      }
      for (final radius in const [.2, 3.0, 9.0]) {
        for (final kind in [
          ObstacleKind.lanternDrift,
          ObstacleKind.sunWheels,
        ]) {
          RegionalObstacles.orb(
            region,
            canvas,
            radius,
            kind: kind,
            upper: radius > 1,
            seconds: 5,
            reducedMotion: false,
            pass: const PassState(cleared: true, perfect: true),
            appearance: 1,
          );
        }
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    image.dispose();
    picture.dispose();

    for (final region in WorldRegion.values) {
      for (final kind in [ObstacleKind.garden, ObstacleKind.switchback]) {
        final bytes = await raster((canvas) {
          RegionalObstacles.column(
            region,
            canvas,
            const Rect.fromLTWH(4, 2, .8, 36),
            kind: kind,
            top: kind == ObstacleKind.garden,
            seconds: 5,
            reducedMotion: true,
            pass: const PassState(cleared: false, perfect: false),
            appearance: 1,
          );
        }, 48);
        expect(
          bytes.any((pixel) => pixel != 0),
          isTrue,
          reason: '\${region.name} \${kind.name} still paints a thin solid',
        );
      }
    }
  });

  test('refined circles are filled with a drawn edge', () async {
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
            expect(alphaAt(bytes, outwardX, outwardY), 0, reason: '$kind edge');
          }
          if (channelGap(bytes, centerX, centerY, inwardX, inwardY) >= 12) {
            drawnEdges++;
          }
        }
        expect(drawnEdges, greaterThanOrEqualTo(4), reason: '$kind rim');
      }
    }
  });
}
