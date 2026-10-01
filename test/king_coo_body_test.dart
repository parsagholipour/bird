import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/king_coo_body_art.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

import 'king_coo_test_kit.dart';

/// King Coo's body (K3): the chest (the hit circle), the torso, the legs, the
/// tail and the crumb sack, each painted alone (the joined hide has its own
/// test, `king_coo_hide_test.dart`).
///
/// Pinned here: every channel is sanitised (a NaN pose paints the rest pose);
/// the chest's outline is the hit circle when puffed (within .05, read off the
/// pixels of an isolated chest) and never pops as it swells (15 bumps that
/// flatten); the tail is a narrow wedge that fans; the legs are long, stay
/// clear of the sack and stamp; fury changes the body, not only the wings; the
/// sack sways about its mouth; nothing pose-independent is built per frame and
/// the caches stay bounded; frames do not depend on what was drawn before. The
/// review renders (chest swell strip, leg strip, fury against calm, sack
/// close-up) go to `build/king-coo-review/`.

KingCooBodyPose bodyPose({
  double puff = 0,
  double tailFan = .42,
  double tailWag = 0,
  double pedal = 0,
  double sackSwing = 0,
  double stomp = 0,
  KingCooTone tone = KingCooTone.calm,
}) => KingCooBodyPose(
  puff: puff,
  tailFan: tailFan,
  tailWag: tailWag,
  pedal: pedal,
  sackSwing: sackSwing,
  stomp: stomp,
  tone: tone,
);

const _part = {
  'chest': KingCooBodyArt.chest,
  'torso': KingCooBodyArt.torso,
  'tail': KingCooBodyArt.tail,
  'sack': KingCooBodyArt.sack,
  'nearLeg': KingCooBodyArt.nearLeg,
  'farLeg': KingCooBodyArt.farLeg,
};

/// The alpha channel of [draw] at [ppu] pixels per rig unit over a canvas
/// whose origin is at ([ox], [oy]) rig units from its top left.
Future<({Uint8List px, int w, int h})> _alpha(
  void Function(Canvas) draw, {
  double ppu = 60,
  double x0 = -3.0,
  double y0 = -3.0,
  double x1 = 4.6,
  double y1 = 3.0,
}) async {
  final w = ((x1 - x0) * ppu).round(), h = ((y1 - y0) * ppu).round();
  final px = await rawPixels(w, h, (c) {
    c.scale(ppu);
    c.translate(-x0, -y0);
    draw(c);
  });
  return (px: px, w: w, h: h);
}

/// The distance from the origin to the last solid pixel along [angle] (the
/// figure is drawn around the origin), in rig units.
double _reach(({Uint8List px, int w, int h}) img, double angle, {double ppu = 60, double x0 = -3.0, double y0 = -3.0}) {
  var best = 0.0;
  for (var r = 0.0; r < 2.2; r += .01) {
    final x = ((math.cos(angle) * r - x0) * ppu).round();
    final y = ((math.sin(angle) * r - y0) * ppu).round();
    if (x < 0 || y < 0 || x >= img.w || y >= img.h) break;
    if (img.px[(y * img.w + x) * 4 + 3] >= 128) best = r;
  }
  return best;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('every channel is finite, always', () {
    test('a valid pose is returned as it is, a bad one is repaired', () {
      final ok = bodyPose(puff: .5, pedal: 7, sackSwing: .2);
      expect(identical(ok.finite, ok), isTrue);
      final bad = KingCooBodyPose(
        puff: double.nan,
        tailFan: double.infinity,
        tailWag: double.negativeInfinity,
        pedal: double.nan,
        sackSwing: 9,
        stomp: -3,
        tone: const KingCooTone(flash: double.nan, fury: double.infinity, heat: -1, dark: double.nan),
      ).finite;
      for (final v in [bad.puff, bad.tailFan, bad.tailWag, bad.pedal, bad.sackSwing, bad.stomp]) {
        expect(v.isFinite, isTrue);
      }
      expect(bad.puff, 0);
      expect(bad.tailFan, 0);
      expect(bad.sackSwing, .8);
      expect(bad.stomp, 0);
      expect(bad.tone.flash.isFinite && bad.tone.fury.isFinite && bad.tone.dark.isFinite, isTrue);
    });

    testWidgets('a NaN pose paints exactly the repaired pose', (tester) async {
      await tester.runAsync(() async {
        final nan = KingCooBodyPose(
          puff: double.nan,
          tailFan: double.nan,
          tailWag: double.nan,
          pedal: double.nan,
          sackSwing: double.nan,
          stomp: double.nan,
          tone: const KingCooTone(flash: double.nan, fury: double.nan),
        );
        final fixed = nan.finite;
        for (final MapEntry(:key, :value) in _part.entries) {
          final a = await rawPixels(300, 300, (c) {
            c.translate(150, 130);
            c.scale(40);
            value(c, nan);
          });
          final b = await rawPixels(300, 300, (c) {
            c.translate(150, 130);
            c.scale(40);
            value(c, fixed);
          });
          expect(a, b, reason: '$key paints the repaired pose');
          expect(a.any((v) => v != 0), isTrue, reason: '$key paints something');
        }
      });
    });
  });

  group('the chest is the hit circle', () {
    test('15 bumps in every state, and they flatten as it swells', () {
      int peaks(double puff) {
        final r = KingCooLayout.chestRadiusAt(puff);
        final path = KingCooBodyArt.chestPath(r, puff.clamp(0.0, 1.0));
        final m = path.computeMetrics().first;
        final n = 720;
        final rad = [
          for (var i = 0; i < n; i++)
            m.getTangentForOffset(m.length * i / n)!.position.distance,
        ];
        // A peak is the first sample of a run that is the highest within a
        // quarter of a bump either side (the top of a bump is flat).
        var count = 0;
        for (var i = 0; i < n; i++) {
          final q = rad[i];
          if (q <= r * 1.004 || q <= rad[(i + n - 1) % n] + 1e-7) continue;
          var top = true;
          for (var k = -10; k <= 10; k++) {
            if (rad[(i + k + n) % n] > q + 1e-9) top = false;
          }
          if (top) count++;
        }
        return count;
      }

      for (final puff in [0.0, .25, .5, .75]) {
        expect(peaks(puff), KingCooLayout.chestBumps, reason: 'puff $puff');
      }
      double depth(double puff) {
        final r = KingCooLayout.chestRadiusAt(puff);
        final m = KingCooBodyArt.chestPath(r, puff.clamp(0.0, 1.0)).computeMetrics().first;
        var hi = 0.0, lo = 9.0;
        for (var i = 0; i < 720; i++) {
          final d = m.getTangentForOffset(m.length * i / 720)!.position.distance;
          hi = math.max(hi, d);
          lo = math.min(lo, d);
        }
        return (hi - lo) / r;
      }

      expect(depth(0), greaterThan(.05), reason: 'fluffed: clear scallops');
      expect(depth(1), lessThan(.03), reason: 'puffed: smooth');
      var last = 9.0;
      for (final puff in [0.0, .25, .5, .75, 1.0]) {
        final d = depth(puff);
        expect(d, lessThanOrEqualTo(last + 1e-9), reason: 'depth never grows while swelling');
        last = d;
      }
    });

    testWidgets('puffed, the drawn outline is the hit circle within .05 (isolated chest scan)', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final report = StringBuffer();
        for (final puff in [0.0, .25, .5, .75, 1.0, 1.3]) {
          final body = bodyPose(puff: puff);
          final img = await _alpha((c) => KingCooBodyArt.chest(c, body));
          var worst = 0.0, sum = 0.0, n = 0;
          final target = KingCooLayout.chestRadiusAt(puff);
          for (var a = 0.0; a < 2 * math.pi; a += math.pi / 90) {
            // The ink is centred on the outline: its outer edge is half the
            // hero stroke past it.
            final r = _reach(img, a) - KingCooLayout.inkHero / 2;
            worst = math.max(worst, (r - target).abs());
            sum += r;
            n++;
          }
          report.writeln(
            'puff ${puff.toStringAsFixed(2)}: outline radius mean ${(sum / n).toStringAsFixed(3)} '
            '(target ${target.toStringAsFixed(3)}), worst deviation ${worst.toStringAsFixed(3)}',
          );
          if (puff >= 1) {
            expect(worst, lessThan(.05), reason: 'puff $puff: a taut chest is the circle');
            expect(sum / n, closeTo(target, .03));
          } else {
            // Fluffed, the scallops' peaks stand out of the circle by their depth.
            expect(worst, lessThan(target * KingCooLayout.chestFluffDepth * 2.6 + .05));
          }
        }
        // ignore: avoid_print
        print(report);
        // The puffed chest is exactly the hit radius.
        expect(KingCooLayout.chestRadiusAt(1), KingCooLayout.hitRadius);
      });
    });

    testWidgets('the outline never pops as the chest swells', (tester) async {
      await tester.runAsync(() async {
        List<double>? prev;
        var worst = 0.0;
        for (var i = 0; i <= 52; i++) {
          final puff = i / 40; // 0 .. 1.3
          final img = await _alpha(
            (c) => KingCooBodyArt.chest(c, bodyPose(puff: puff)),
            ppu: 60,
          );
          final p = [
            for (var a = 0.0; a < 2 * math.pi; a += math.pi / 45) _reach(img, a),
          ];
          if (prev != null) {
            for (var k = 0; k < p.length; k++) {
              worst = math.max(worst, (p[k] - prev[k]).abs());
            }
          }
          prev = p;
        }
        // ignore: avoid_print
        print('largest radial step between 1/40 swell steps: ${worst.toStringAsFixed(3)}');
        expect(worst, lessThan(.08));
      });
    });

    testWidgets('a taut chest wears the gold ring and the badge glows; a fluffed one does not', (
      tester,
    ) async {
      await tester.runAsync(() async {
        Future<double> goldAt(double puff) async {
          final img = await _alpha((c) => KingCooBodyArt.chest(c, bodyPose(puff: puff)));
          // Samples along the ring's radius (.80 of the skin radius).
          var gold = 0;
          for (var a = math.pi * .35; a < math.pi * 1.0; a += .05) {
            final r = KingCooLayout.chestRadiusAt(puff) * .80 - .02;
            final x = ((math.cos(a) * r + 3.0) * 60).round();
            final y = ((math.sin(a) * r + 3.0) * 60).round();
            final i = (y * img.w + x) * 4;
            if (img.px[i] > 200 && img.px[i + 1] > 170 && img.px[i + 2] < 170) gold++;
          }
          return gold.toDouble();
        }

        expect(await goldAt(1.0), greaterThan(await goldAt(0.0)));
      });
    });
  });

  group('the tail', () {
    test('a narrow wedge at rest, a fan when it opens, inside the envelope', () {
      double height(double fan) =>
          KingCooBodyArt.tailUnion(bodyPose(tailFan: fan)).getBounds().height;
      expect(height(0), lessThan(height(.42)));
      expect(height(.42), lessThan(height(1)));
      expect(height(.42), lessThan(1.25), reason: 'the rest tail is a narrow wedge');
      expect(height(1), greaterThan(height(.42) + .35), reason: 'the fan is visibly wider');
      for (final fan in [0.0, .42, 1.0]) {
        for (final wag in [-.3, 0.0, .3]) {
          final b = KingCooBodyArt.tailUnion(bodyPose(tailFan: fan, tailWag: wag)).getBounds();
          expect(b.right, lessThan(KingCooLayout.envelope.right - .15), reason: 'fan $fan wag $wag');
          expect(b.bottom, lessThan(KingCooLayout.envelope.bottom));
          expect(b.top, greaterThan(KingCooLayout.envelope.top));
        }
      }
      // Four feathers, from the contract's root.
      expect(KingCooBodyArt.tailFeathers, hasLength(4));
    });

    test('the four feathers wind the same way: the union fills', () {
      final b = bodyPose(tailFan: 1);
      final union = KingCooBodyArt.tailUnion(b);
      final root = KingCooLayout.tailRoot;
      // A point on the axis of each feather, near its root (inside all four).
      for (var i = 0; i < 4; i++) {
        final a = KingCooBodyArt.featherAngle(b, i);
        final p = root + Offset(math.cos(a), math.sin(a)) * .3;
        expect(union.contains(p), isTrue, reason: 'feather $i');
      }
      expect(union.contains(root + const Offset(.25, 0)), isTrue);
    });
  });

  group('the legs', () {
    test('long, swinging, stamping, and clear of the sack', () {
      for (final far in [false, true]) {
        var lo = 9.0, hi = -9.0;
        for (var i = 0; i < 64; i++) {
          final b = bodyPose(pedal: i / 64 * 2 * math.pi);
          final l = KingCooBodyArt.legAt(b, far);
          expect(l.foot.dy, greaterThan(KingCooLayout.footY - KingCooLayout.footLift - .05));
          expect(l.foot.dy, lessThan(KingCooLayout.footY + .05));
          expect(l.foot.dy - 1.05, greaterThan(.9), reason: 'long legs');
          lo = math.min(lo, l.foot.dx);
          hi = math.max(hi, l.foot.dx);
        }
        expect(hi - lo, closeTo(2 * KingCooLayout.footReach, .02), reason: 'far $far swings by the reach');
      }
      final stamp = KingCooBodyArt.legAt(bodyPose(stomp: 1), false).foot.dy;
      expect(stamp, closeTo(KingCooLayout.footY - .30, .02));
      final hipsFar = KingCooBodyArt.legAt(bodyPose(), true);
      expect(hipsFar.hip, KingCooLayout.farHip);
    });

    testWidgets('the far leg stays clear of the sack by the layout\'s gap, at every step', (
      tester,
    ) async {
      await tester.runAsync(() async {
        var worst = 9.0;
        for (var i = 0; i < 16; i++) {
          final b = bodyPose(pedal: i / 16 * 2 * math.pi, sackSwing: (i.isEven ? -1 : 1) * .05);
          final leg = await scan((c) => KingCooBodyArt.farLeg(c, b), solid: 128);
          // The layout's negative space: y 1.36-1.90, the shank and foot against
          // the bag (the thigh tuft above is the skin's).
          const band = Rect.fromLTRB(-3, 1.36, 4, 1.90);
          final below = await scan((c) {
            c.clipRect(band);
            KingCooBodyArt.farLeg(c, b);
          }, solid: 128);
          final sack = await scan((c) {
            c.clipRect(band);
            KingCooBodyArt.sack(c, b);
          }, solid: 128);
          worst = math.min(worst, sack.left - below.right);
          expect(leg.bottom, greaterThan(2.0));
        }
        // ignore: avoid_print
        print('the far leg (below the thigh) clears the sack by ${worst.toStringAsFixed(2)} at its closest');
        expect(worst, greaterThanOrEqualTo(KingCooLayout.legSackGap - .03));
      });
    });
  });

  group('the sack swings with the throw', () {
    test('it sways toward the bird while the arm is back, is slung back at the release and settles', () {
      double kick(double afterLock, {bool reduced = false}) {
        final b = cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - afterLock)));
        return KingCooBodyPose.of(poseOf(b, reduced: reduced)).sackKick;
      }

      expect(kick(0), closeTo(0, 1e-9), reason: 'nothing before the lock');
      final hold = kick(.45); // the backswing with the bomb in hand
      expect(hold, greaterThan(.08), reason: 'toward the bird while the arm is back');
      expect(kick(.80), closeTo(0, .03), reason: 'the release starts from nothing');
      var low = 0.0, high = 0.0;
      for (var t = .80; t <= 1.5; t += .01) {
        final k = kick(t);
        low = math.min(low, k);
        high = math.max(high, k);
      }
      expect(low, lessThan(-.08), reason: 'slung back by the release');
      expect(kick(1.6), closeTo(0, .02), reason: 'settled');
      expect(low, greaterThan(-.35));
      expect(high, lessThan(.35));
    });

    test('continuous: no step between 1/480 s samples through the throw', () {
      var worst = 0.0;
      double? last;
      for (var t = 0.0; t <= 1.8; t += 1 / 480) {
        final b = cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - t)));
        final k = KingCooBodyPose.of(poseOf(b)).sackKick;
        if (last != null) worst = math.max(worst, (k - last).abs());
        last = k;
      }
      expect(worst, lessThan(.02), reason: 'the sack never jumps');
    });

    test('Reduced Motion keeps the pose (the hold) and drops the rocking', () {
      final b = cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .45)));
      final rm = KingCooBodyPose.of(poseOf(b, reduced: true)).sackKick;
      expect(rm, greaterThan(.08));
      var rock = 0.0;
      for (var t = .80; t <= 1.5; t += .01) {
        final a = cooBoss(combat: 1.0, setup: (a) => a.lobs.add(lobAt(a.age - t)));
        rock = math.max(rock, KingCooBodyPose.of(poseOf(a, reduced: true)).sackKick.abs());
      }
      expect(rock, lessThan(.16), reason: 'no rocking after the release');
    });
  });

  group('the sack', () {
    testWidgets('it sways about its mouth: the mouth stays, the bottom swings', (tester) async {
      await tester.runAsync(() async {
        Future<Scan> bag(double swing) => scan((c) {
          c.clipRect(const Rect.fromLTRB(-3, 1.0, 4, 3));
          KingCooBodyArt.sack(c, bodyPose(sackSwing: swing));
        }, solid: 128);
        final a = await bag(-.3), b = await bag(.3);
        // The bag swings sideways about its mouth, in the swing's direction.
        expect(b.rect.center.dx, lessThan(a.rect.center.dx - .25));
        final mouth = KingCooLayout.sackMouth;
        Future<int> alphaAt(double sw) async {
          final img = await _alpha((c) => KingCooBodyArt.sack(c, bodyPose(sackSwing: sw)));
          final x = ((mouth.dx + 3.0) * 60).round(), y = ((mouth.dy + .12 + 3.0) * 60).round();
          return img.px[(y * img.w + x) * 4 + 3];
        }

        expect(await alphaAt(-.3), greaterThan(200));
        expect(await alphaAt(.3), greaterThan(200));
      });
    });

    testWidgets('it stays inside the layout\'s sack extremes, swung or not', (tester) async {
      await tester.runAsync(() async {
        final s = await scan((c) {
          c.clipRect(const Rect.fromLTRB(-3, .75, 4, 3));
          KingCooBodyArt.sack(c, bodyPose());
        }, solid: 128);
        // The layout's sack spans x 1.02-2.24, y .56-1.68; the ink adds a little.
        expect(s.left, greaterThan(.92));
        expect(s.left, lessThan(1.06));
        expect(s.right, lessThan(2.4));
        expect(s.bottom, lessThan(1.80));
      });
    });
  });

  group('the tone changes the body', () {
    testWidgets('fury flushes the chest pink and fans the tail; a hit bleaches the plumage', (
      tester,
    ) async {
      await tester.runAsync(() async {
        Future<List<int>> colour(KingCooTone tone, double puff, Offset at, String part) async {
          final img = await _alpha(
            (c) => _part[part]!(c, bodyPose(puff: puff, tone: tone)),
          );
          final x = ((at.dx + 3.0) * 60).round(), y = ((at.dy + 3.0) * 60).round();
          final i = (y * img.w + x) * 4;
          return [img.px[i], img.px[i + 1], img.px[i + 2]];
        }

        const at = Offset(-.45, .35);
        final calm = await colour(KingCooTone.calm, 0, at, 'chest');
        final fury = await colour(const KingCooTone(fury: 1), 0, at, 'chest');
        // Pinker: the red pulls ahead of the green.
        expect(fury[0] - fury[1], greaterThan(calm[0] - calm[1] + 6));
        // A hit goes near-white on the plumage.
        const torsoAt = Offset(1.0, .3);
        final plain = await colour(KingCooTone.calm, 0, torsoAt, 'torso');
        final hit = await colour(const KingCooTone(flash: .55), 0, torsoAt, 'torso');
        int lum(List<int> c) => c[0] + c[1] + c[2];
        expect(lum(hit), greaterThan(lum(plain) + 150));
        // The fury's fan (the pose's own channel is 1 in fury).
        final calmTail = KingCooBodyArt.tailUnion(bodyPose(tailFan: .42)).getBounds();
        final furyTail = KingCooBodyArt.tailUnion(bodyPose(tailFan: 1)).getBounds();
        expect(furyTail.height, greaterThan(calmTail.height + .3));
      });
    });

    testWidgets('through the real pose: fury and puff change what the body paints', (tester) async {
      await tester.runAsync(() async {
        final calm = KingCooBodyPose.of(poseOf(cooBoss(combat: 1.2)));
        final fury = KingCooBodyPose.of(poseOf(cooBoss(combat: 1.2, fury: true)));
        final puffed = KingCooBodyPose.of(poseOf(cooBoss(combat: 9.0)));
        expect(fury.tone.fury, greaterThan(.9));
        expect(fury.tailFan, greaterThan(calm.tailFan));
        expect(puffed.puff, greaterThan(.95));
        expect(calm.puff, lessThan(.05));
      });
    });
  });

  group('no shader per frame, bounded caches, order-independent pixels', () {
    test('a warm body builds no shader, however the chest swells', () {
      final c = Canvas(ui.PictureRecorder());
      void frame(double puff, KingCooTone tone) {
        final b = bodyPose(puff: puff, tone: tone, pedal: puff * 9, tailFan: puff);
        for (final f in _part.values) {
          f(c, b);
        }
      }

      for (var i = 0; i <= 56; i++) {
        frame(i / 40, KingCooTone.calm);
      }
      frame(.5, const KingCooTone(fury: 1, flash: .5, heat: 1, dark: 1, siren: 1, sirenGlow: 1));
      final before = KingCooKit.shadersBuilt;
      for (var i = 0; i <= 560; i++) {
        frame(i / 400, i.isEven ? KingCooTone.calm : const KingCooTone(fury: .5, flash: .3, heat: .5));
      }
      expect(KingCooKit.shadersBuilt, before);
    });

    test('the kit\'s caches stay bounded under a long run of varied poses', () {
      final c = Canvas(ui.PictureRecorder());
      for (var i = 0; i < 3000; i++) {
        final b = bodyPose(
          puff: (i % 97) / 70,
          tailFan: (i % 13) / 13,
          tailWag: math.sin(i * .1) * .1,
          pedal: i * .37,
          sackSwing: math.sin(i * .2) * .2,
          stomp: (i % 7) / 7,
          tone: KingCooTone(flash: (i % 5) / 9, fury: (i % 11) / 11, heat: (i % 3) / 3, dark: (i % 4) / 4),
        );
        for (final f in _part.values) {
          f(c, b);
        }
      }
      expect(KingCooKit.cacheSize, lessThanOrEqualTo(2 * KingCooKit.cacheCapacity));
    });

    testWidgets('pixels do not depend on what was drawn before', (tester) async {
      await tester.runAsync(() async {
        final poses = [
          for (var i = 0; i < 10; i++)
            bodyPose(
              puff: i / 7,
              tailFan: i / 10,
              pedal: i * 1.1,
              sackSwing: (i - 5) * .05,
              tone: i.isOdd ? const KingCooTone(fury: 1, flash: .2) : KingCooTone.calm,
            ),
        ];
        Future<List<Uint8List>> run(List<int> order) async {
          KingCooKit.clearCaches();
          final out = List<Uint8List?>.filled(poses.length, null);
          for (final i in order) {
            out[i] = await rawPixels(260, 260, (c) {
              c.translate(90, 100);
              c.scale(36);
              for (final f in _part.values) {
                f(c, poses[i]);
              }
            });
          }
          return out.cast<Uint8List>();
        }

        final forward = await run([for (var i = 0; i < 10; i++) i]);
        final backward = await run([for (var i = 9; i >= 0; i--) i]);
        for (var i = 0; i < 10; i++) {
          expect(forward[i], backward[i], reason: 'pose $i');
        }
      });
    });
  });

  group('review renders', () {
    testWidgets('the chest swell strip, the leg strip, fury against calm, the sack', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await loadFonts();
        final light = newYorkLight();
        // The chest swell strip: 0, .25, .5, .75, 1, 1.3 through the real rig.
        final swells = [0.0, .25, .5, .75, 1.0, 1.3];
        await savePng('body-chest-swell', 6 * 190, 190, (c) {
          for (var i = 0; i < swells.length; i++) {
            c.save();
            c.clipRect(Rect.fromLTWH(i * 190.0, 0, 190, 190));
            c.drawRect(
              Rect.fromLTWH(i * 190.0, 0, 190, 190),
              Paint()..color = const Color(0xff1f2044),
            );
            c.translate(i * 190 + 95.0, 95);
            c.scale(62);
            final body = bodyPose(puff: swells[i]);
            KingCooBodyArt.chest(c, body);
            c.drawCircle(
              Offset.zero,
              1,
              Paint()
                ..color = const Color(0xff4aa8ff)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2 / 62,
            );
            c.restore();
            label(c, 'puff ${swells[i]}', Offset(i * 190.0 + 6, 4), color: const Color(0xffffffff));
          }
        });
        // The leg strip over a waddle: eight phases.
        await savePng('body-leg-strip', 8 * 120, 230, (c) {
          for (var i = 0; i < 8; i++) {
            c.save();
            c.clipRect(Rect.fromLTWH(i * 120.0, 0, 120, 230));
            c.drawRect(
              Rect.fromLTWH(i * 120.0, 0, 120, 230),
              Paint()..color = const Color(0xffe6dfd6),
            );
            c.translate(i * 120 + 50.0, -40);
            c.scale(62);
            final body = bodyPose(pedal: i / 8 * 2 * math.pi, stomp: i == 7 ? 1 : 0);
            KingCooBodyArt.farLeg(c, body);
            KingCooBodyArt.nearLeg(c, body);
            c.restore();
          }
        });
        // Fury against calm, hit and puffed, through the real rig.
        final states = <(String, KingCooPose)>[
          ('calm', poseOf(cooBoss(combat: 1.2), light: light)),
          ('fury', poseOf(cooBoss(combat: 1.2, fury: true), light: light)),
          ('hit', poseOf(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .09), light: light)),
          ('puffed', poseOf(cooBoss(combat: 9.0), light: light)),
        ];
        await savePng('body-tone-strip', 4 * 330, 290, (c) {
          for (var i = 0; i < states.length; i++) {
            c.save();
            c.clipRect(Rect.fromLTWH(i * 330.0, 0, 330, 290));
            c.drawRect(
              Rect.fromLTWH(i * 330.0, 0, 330, 290),
              Paint()..color = const Color(0xff2a2a52),
            );
            c.translate(i * 330 + 120.0, 152);
            c.scale(41.4);
            KingCooBossRig.paintPose(c, states[i].$2);
            c.restore();
            label(c, states[i].$1, Offset(i * 330.0 + 6, 4), color: const Color(0xffffffff));
          }
        });
        // The sack, close up, at three sways.
        await savePng('body-sack', 3 * 330, 330, (c) {
          for (var i = 0; i < 3; i++) {
            c.save();
            c.clipRect(Rect.fromLTWH(i * 330.0, 0, 330, 330));
            c.drawRect(
              Rect.fromLTWH(i * 330.0, 0, 330, 330),
              Paint()..color = const Color(0xffcfc6d8),
            );
            c.translate(i * 330 - 1.0 * 190 + 40, -.1 * 190 + 30);
            c.scale(190);
            KingCooBodyArt.sack(c, bodyPose(sackSwing: (i - 1) * .3));
            c.restore();
          }
        });
      });
    });
  });
}
