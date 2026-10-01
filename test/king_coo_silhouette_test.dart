import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

import 'king_coo_test_kit.dart';

/// The silhouette study: King Coo must read as a charming, funny, fierce
/// pouter-pigeon commissioner in black at 250 px (41.4 px per unit) and at
/// 120 px (19 px per unit), in every pose a player sees.
///
/// What must read (the pillars of `KingCooLayout`):
///  * a pouter: the chest is a GLOBE in front of a slim body that tapers to a
///    narrow wedge tail (the torso is at most `bodyDepthMax` deep at x = 1.5,
///    a hunched back read as a hen),
///  * a head on a neck above the chest, and a BEAK that leads the face (the
///    cap's visor must not stack on it),
///  * long thin legs, a crumb sack, a whistle on its chain,
///  * three negative spaces stay open at 120 px in the calm poses (the throat
///    notch under the beak, the legs-to-sack gap, the wing-to-tail pocket).
/// The test prints the numbers and writes the sheets to `build/king-coo-review/`.

/// The silhouette of [pose] in a [ppu] picture, origin at [origin].
Future<ui.Image> _sil(KingCooPose pose, double ppu, int w, int h, Offset origin,
    {Set<String>? only}) =>
    silhouetteImage(pose, ppu: ppu, w: w, h: h, origin: origin, only: only);

Future<List<bool>> _mask(KingCooPose pose, double ppu, int w, int h, Offset origin,
    {Set<String>? only}) async {
  final img = await _sil(pose, ppu, w, h, origin, only: only);
  final data = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  return [for (var i = 3; i < data.length; i += 4) data[i] > 0];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 420, h = 360;
  const origin = Offset(170, 180);

  Future<double> filled(List<bool> mask, Rect probe, double ppu) async {
    var inside = 0, total = 0;
    for (var y = (origin.dy + probe.top * ppu).floor();
        y < (origin.dy + probe.bottom * ppu).ceil();
        y++) {
      for (var x = (origin.dx + probe.left * ppu).floor();
          x < (origin.dx + probe.right * ppu).ceil();
          x++) {
        if (x < 0 || y < 0 || x >= w || y >= h) continue;
        total++;
        if (mask[y * w + x]) inside++;
      }
    }
    return total == 0 ? 0 : inside / total;
  }

  testWidgets('the negative spaces stay open at 120 px in the calm poses', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const ppu = 19.0;
      final calm = <(String, KingCooPose)>[
        ('rest', KingCooPose.still),
        ('wing up', idleWithWing(-.7)),
        ('wing down', idleWithWing(.7)),
        ('hover', poseOf(cooBoss(combat: 2.0))),
      ];
      final report = StringBuffer();
      final closed = <String>[];
      for (final (name, pose) in calm) {
        final mask = await _mask(pose, ppu, w, h, origin);
        for (final MapEntry(:key, :value) in KingCooLayout.negativeSpaces.entries) {
          final share = await filled(mask, value, ppu);
          report.writeln('$name / $key: ${(share * 100).toStringAsFixed(1)}% filled');
          if (share > KingCooLayout.openShare) {
            closed.add('$name / $key: ${(share * 100).round()}% filled (limit ${(KingCooLayout.openShare * 100).round()}%)');
          }
        }
      }
      // ignore: avoid_print
      print(report);
      expect(closed, isEmpty, reason: 'a closed negative space reads as a blob');
    });
  });

  testWidgets('the beak leads the face: nothing else is as far forward', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const ppu = 41.4;
      for (final (name, pose) in [
        ('rest', KingCooPose.still),
        ('hover', poseOf(cooBoss(combat: 2.0))),
        ('fury', poseOf(cooBoss(combat: 1.2, fury: true))),
        ('whistle', poseOf(cooBoss(combat: 9.3))),
        ('inhale', poseOf(cooBoss(combat: 8.2))),
        ('arrival rear', poseOf(arrivingBoss(2.5))),
      ]) {
        final mask = await _mask(pose, ppu, w, h, origin);
        // Leftmost solid pixel per row, in units.
        double left(double y) {
          final row = (origin.dy + y * ppu).round();
          if (row < 0 || row >= h) return 99;
          for (var x = 0; x < w; x++) {
            if (mask[row * w + x]) return (x - origin.dx) / ppu;
          }
          return 99;
        }

        final beakY = KingCooBossRig.beakAt(pose).dy;
        final tip = KingCooBossRig.beakAt(pose).dx;
        var beakLeft = 99.0;
        for (var y = beakY - .12; y <= beakY + .12; y += .02) {
          beakLeft = math.min(beakLeft, left(y));
        }
        // The rows above (cap, visor) and below (ruff, chest) the beak.
        var other = 99.0;
        for (var y = beakY - 1.4; y <= beakY + 1.4; y += .02) {
          if ((y - beakY).abs() < .35) continue;
          other = math.min(other, left(y));
        }
        // ignore: avoid_print
        print('$name: beak tip x ${tip.toStringAsFixed(2)}, leftmost at the beak ${beakLeft.toStringAsFixed(2)}, leftmost elsewhere on the head ${other.toStringAsFixed(2)}');
        expect(beakLeft, closeTo(tip, .12), reason: '$name: the beak is the leftmost thing on its rows');
        expect(other - beakLeft, greaterThan(.28), reason: '$name: the beak leads by .28 or more');
      }
    });
  });

  testWidgets('a pouter, not a hen: the chest is a globe, the body tapers, the legs are long', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const ppu = 41.4;
      final pose = KingCooPose.still;
      final torso = await _mask(pose, ppu, w, h, origin, only: {'torso'});
      int col(double x) => (origin.dx + x * ppu).round();
      (double, double) extent(List<bool> mask, double x) {
        final c = col(x);
        var top = h, bottom = -1;
        for (var y = 0; y < h; y++) {
          if (mask[y * w + c]) {
            top = math.min(top, y);
            bottom = math.max(bottom, y);
          }
        }
        return ((top - origin.dy) / ppu, (bottom + 1 - origin.dy) / ppu);
      }

      final (t, b) = extent(torso, KingCooLayout.bodyDepthAt);
      // ignore: avoid_print
      print('torso at x ${KingCooLayout.bodyDepthAt}: y ${t.toStringAsFixed(2)} .. ${b.toStringAsFixed(2)} = ${(b - t).toStringAsFixed(2)} deep (chest diameter 2)');
      expect(b - t, lessThanOrEqualTo(KingCooLayout.bodyDepthMax));
      // The chest is the biggest circle: its puffed diameter beats every other
      // mass's depth (head + ruff, tail, sack).
      expect(KingCooLayout.chestRadiusAt(1) * 2, greaterThan(KingCooLayout.bodyDepthMax));
      // The legs reach well below the belly: a pouter stands on long legs.
      final legs = await _mask(pose, ppu, w, h, origin, only: {'nearLeg', 'farLeg'});
      final (lt, lb) = extent(legs, .10);
      expect(lb, greaterThan(2.0));
      expect(lb - 1.05, greaterThan(.9), reason: 'legs are at least .9 long below the belly');
      expect(lt, lessThan(1.4));
    });
  });

  testWidgets('the silhouette reads in every pose a player sees (sheets)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await loadFonts();
      final poses = sheetPoses();
      for (final (name, ppu, cols) in const [
        ('sil-250', 41.4, 4),
        ('sil-120', 19.0, 8),
      ]) {
        const x0 = -3.6, y0 = -4.0, wU = 9.2, hU = 7.6;
        final cw = (wU * ppu).round(), ch = (hU * ppu).round();
        final rows = (poses.length / cols).ceil();
        final images = <ui.Image>[];
        for (final (_, pose) in poses) {
          images.add(
            await _sil(pose, ppu, cw, ch, Offset(-x0 * ppu, -y0 * ppu)),
          );
        }
        await savePng(name, cw * cols, ch * rows, (c) {
          c.drawRect(
            Rect.fromLTWH(0, 0, (cw * cols).toDouble(), (ch * rows).toDouble()),
            Paint()
              ..shader = ui.Gradient.linear(
                Offset.zero,
                Offset(0, (ch * rows).toDouble()),
                const [Color(0xffc9c3e8), Color(0xffe8d6e0)],
              ),
          );
          for (var i = 0; i < poses.length; i++) {
            final cx = (i % cols) * cw.toDouble(), cy = (i ~/ cols) * ch.toDouble();
            c.save();
            c.clipRect(Rect.fromLTWH(cx, cy, cw.toDouble(), ch.toDouble()));
            c.translate(cx, cy);
            c.drawImage(images[i], Offset.zero, Paint());
            // The hit circle, the screen edges and the envelope.
            c.save();
            c.translate(-x0 * ppu, -y0 * ppu);
            c.scale(ppu);
            final g = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3 / ppu;
            g.color = const Color(0xffd03030);
            c.drawLine(Offset(KingCooLayout.screenRight, -9), Offset(KingCooLayout.screenRight, 9), g);
            c.drawLine(Offset(-9, KingCooLayout.visibleWorst.top), Offset(9, KingCooLayout.visibleWorst.top), g);
            g.color = const Color(0xff2060d0);
            c.drawCircle(Offset.zero, 1, g);
            g.color = const Color(0xff30a030);
            c.drawRect(KingCooLayout.envelope, g);
            c.restore();
            c.restore();
            label(c, poses[i].$1, Offset(cx + 4, cy + 2), size: ppu > 30 ? 13 : 9);
          }
        });
        for (final i in images) {
          i.dispose();
        }
      }
    });
  });

  testWidgets('at least 40% of the contour holds against New York at night', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The acceptance: in the night backdrop >= 40% of the figure's contour
      // has a value difference (CIE L*) of 25 or more against the hazed
      // backdrop just outside it.
      const wpx = 640, hpx = 360;
      final light = newYorkLight();
      final report = StringBuffer();
      final failures = <String>[];
      for (final (name, pose) in [
        ('rest', poseOf(cooBoss(combat: 1.2), light: light)),
        ('puffed', poseOf(cooBoss(combat: 9.0), light: light)),
        ('whistle', poseOf(cooBoss(combat: 9.3), light: light)),
        ('fury', poseOf(cooBoss(combat: 1.2, fury: true), light: light)),
      ]) {
        final boss = bossAnchor(640.0);
        final backdrop = await rawPixels(wpx, hpx, (c) {
          nyFrame(c, 640, pose: pose, bird: false, under: (c, b, h) {}, above: null, silhouette: false);
        });
        // The figure alone gives the mask; the same frame without him gives
        // the backdrop.
        final empty = await rawPixels(wpx, hpx, (c) {
          nyFrame(c, 640, pose: pose, bird: false, bossAt: const Offset(-9000, -9000));
        });
        final figure = await rawPixels(wpx, hpx, (c) {
          c.translate(boss.dx, boss.dy);
          c.scale(hpx * SkyBoss.radius);
          KingCooBossRig.paintPose(c, pose);
        });
        double lstar(Uint8List px, int x, int y) {
          final i = (y * wpx + x) * 4;
          double lin(int v) {
            final s = v / 255;
            return s <= .04045 ? s / 12.92 : math.pow((s + .055) / 1.055, 2.4).toDouble();
          }
          final yv = .2126 * lin(px[i]) + .7152 * lin(px[i + 1]) + .0722 * lin(px[i + 2]);
          return yv > .008856 ? 116 * math.pow(yv, 1 / 3) - 16 : 903.3 * yv;
        }

        var contour = 0, strong = 0;
        for (var y = 3; y < hpx - 3; y++) {
          for (var x = 3; x < wpx - 3; x++) {
            final a = figure[(y * wpx + x) * 4 + 3];
            if (a < 200) continue;
            // An edge pixel: a neighbour two pixels away is outside the figure.
            var outside = -1;
            for (final (dx, dy) in const [(-2, 0), (2, 0), (0, -2), (0, 2)]) {
              if (figure[((y + dy) * wpx + x + dx) * 4 + 3] < 40) {
                outside = (y + dy) * wpx + x + dx;
                break;
              }
            }
            if (outside < 0) continue;
            contour++;
            final fig = lstar(backdrop, x, y);
            final back = lstar(empty, outside % wpx, outside ~/ wpx);
            if ((fig - back).abs() >= 25) strong++;
          }
        }
        final share = contour == 0 ? 0 : strong / contour;
        report.writeln('$name: ${(share * 100).toStringAsFixed(0)}% of $contour contour pixels have dL >= 25');
        if (share < .40) failures.add('$name ${(share * 100).round()}%');
      }
      // ignore: avoid_print
      print(report);
      expect(failures, isEmpty);
    });
  });
}
