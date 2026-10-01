@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_head_art.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'proof/counting_canvas.dart';
import 'proof/gargoyle_raster.dart';
import 'proof/gargoyle_stage.dart';

/// The Searchlight Gargoyle's HEAD (G1): the skull, the hooked beak and its
/// jaw, the two brow hoods, the crest, the lens-eyes.
///
/// Every gate is measured on the art, never on layout numbers: the scowl slope
/// and the lens cover, the hook, the crest, the extremes, the jaw's sweep, the
/// brow's drop, the lens glow against the pose's own beam channels, the
/// expressions told apart (live and under Reduced Motion), the budget (70 ops,
/// 3 shaders, 2 clips; no saveLayer, no blur), pixels that never depend on the
/// order frames are drawn in, bounded caches, non-finite safety.
///
/// The review sheets (close-ups, the expression sheets at phone size and at
/// 120 px, silhouettes at 250 and 120 px, the head in New York's night at 640
/// and 800) are written only with
///   flutter test --dart-define=GARGOYLE_HEAD_REVIEW=true test/gargoyle_head_test.dart
/// to build/visual-review/gargoyle-head (or $GARGOYLE_OUT).
const _review = bool.fromEnvironment('GARGOYLE_HEAD_REVIEW');
const _outEnv = String.fromEnvironment('GARGOYLE_OUT');
final _out = _outEnv.isEmpty ? 'build/visual-review/gargoyle-head' : _outEnv;

// ------------------------------------------------------------- helpers --

const _calm = GargoyleTone();

GargoyleHeadPose _head({
  GargoyleTone tone = _calm,
  double gape = 0,
  double flare = .3,
  double brow = .3,
  double iris = 1,
  double fury = 0,
  double crack = 0,
  double wince = 0,
  bool visor = true,
  bool defeated = false,
  double crumble = 0,
  double time = 0,
}) => GargoyleHeadPose(
  tone: tone,
  gape: gape,
  flare: flare,
  brow: brow,
  iris: iris,
  fury: fury,
  crack: crack,
  wince: wince,
  visor: visor,
  defeated: defeated,
  crumble: crumble,
  time: time,
);

/// The head in its own frame (head-local units), rasterised.
Future<Mask> _local(GargoyleHeadPose h, {double ppu = 60, int solid = 200}) => rasterize(
  (c) => GargoyleHeadArt.paint(c, h),
  ppu: ppu,
  region: const ui.Rect.fromLTRB(-4.3, -3.7, -.1, -.8),
  solid: solid,
);

/// RGBA at a head-local point.
(int, int, int, int) _px(Mask m, double x, double y) {
  final ix = ((x - m.x0) * m.ppu).floor(), iy = ((y - m.y0) * m.ppu).floor();
  final i = (iy * m.w + ix) * 4;
  return (m.data[i], m.data[i + 1], m.data[i + 2], m.data[i + 3]);
}

double _lum((int, int, int, int) p) => .2126 * p.$1 + .7152 * p.$2 + .0722 * p.$3;

int _diff(Mask a, Mask b, [int tol = 24]) {
  var n = 0;
  for (var i = 0; i < a.data.length; i += 4) {
    final d = math.max(
      (a.data[i] - b.data[i]).abs(),
      math.max((a.data[i + 1] - b.data[i + 1]).abs(), (a.data[i + 2] - b.data[i + 2]).abs()),
    );
    if (d > tol || (a.data[i + 3] - b.data[i + 3]).abs() > 80) n++;
  }
  return n;
}

/// A frame's pixels. [draw] paints in head-local units (the default frame) or,
/// for the rig's head part, rig units ([rig]).
Future<Uint8List> _bytes(void Function(ui.Canvas) draw, {bool rig = false}) async {
  const w = 360, h = 300;
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  if (rig) {
    c.translate(300, 220);
    c.scale(48);
  } else {
    c.translate(320, 280);
    c.scale(80);
  }
  draw(c);
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  final data = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return Uint8List.fromList(data);
}

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

({int ops, int clips, int layers, int blurs, int shaders}) _count(GargoyleHeadPose h) {
  final before = GargoyleKit.shadersBuilt;
  final c = Counting(ui.Canvas(ui.PictureRecorder()));
  GargoyleHeadArt.paint(c, h);
  return (ops: c.draws, clips: c.clips, layers: c.layers, blurs: c.blurs, shaders: GargoyleKit.shadersBuilt - before);
}

/// The expression states the head must tell apart: the contract's "state ->
/// brow / lid / lens" matrix as REAL poses of a REAL boss.
List<(String, GargoylePose Function(bool reduced))> _states() => [
  ('stone', (r) => poseOf(gBoss(-3.6), reduced: r)),
  ('wake', (r) => poseOf(gBoss(1.72 - 4.6), reduced: r)),
  ('idle', (r) => poseOf(gBoss(1.0), reduced: r)),
  ('warning', (r) => poseOf(gBoss(3.2), reduced: r)),
  ('sweep', (r) => poseOf(gBoss(4.8), reduced: r)),
  ('vent', (r) => poseOf(gBoss(7.2), reduced: r)),
  ('roar', (r) => poseOf(gBoss(-1.6), reduced: r)),
  ('fury', (r) => poseOf(gBoss(5.0, fury: true, slit: true), reduced: r)),
  ('hit', (r) => poseOf(gBoss(1.0, hitAgo: .06), reduced: r)),
  ('defeat', (r) => poseOf(gBoss(1.0, deadFor: .7), reduced: r)),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  // ---------------------------------------------------------------- gates --

  group('the anchors and the silhouette gates, measured on the art', () {
    test('the lens, beak and hinge anchors are the layout\'s (nothing moved)', () {
      expect(GargoyleHeadArt.eyeNear, GargoyleLayout.eyeNear);
      expect(GargoyleHeadArt.eyeFar, GargoyleLayout.eyeFar);
      expect(GargoyleHeadArt.eyeNearRadius, GargoyleLayout.eyeNearRadius);
      expect(GargoyleHeadArt.eyeFarRadius, GargoyleLayout.eyeFarRadius);
      expect(GargoyleHeadArt.beakTip, GargoyleLayout.beakTip);
      expect(GargoyleHeadArt.jawHinge, GargoyleLayout.jawHinge);
    });

    test('the scowl: the near hood\'s lower edge slopes >= 25 degrees toward the beak and covers >= 25% of the lens', () {
      for (final brow in const [0.0, .3, .6, 1.0]) {
        final e = GargoyleHeadArt.visorEdge(brow);
        final slope = math.atan2(e.outer.dy - e.inner.dy, e.inner.dx - e.outer.dx) * 180 / math.pi;
        // ignore: avoid_print
        print('brow $brow: slope ${slope.toStringAsFixed(1)} deg, covers ${(GargoyleHeadArt.nearLensCover(brow) * 100).round()}% of the near lens');
        expect(slope, greaterThanOrEqualTo(GargoyleGates.scowlDegrees));
        expect(e.outer.dx, lessThan(e.inner.dx), reason: 'the tip is toward the beak');
      }
      expect(GargoyleHeadArt.nearLensCover(.3), greaterThanOrEqualTo(GargoyleGates.visorCover));
      expect(GargoyleHeadArt.nearLensCover(1), greaterThan(GargoyleHeadArt.nearLensCover(.3) + .1));
      expect(GargoyleHeadArt.nearLensCover(1), lessThan(.9), reason: 'never shut');
      // the same inner end as the layout's reference, and at full scowl exactly its drop;
      // a relaxed brow lifts the hoods (awake eyes at idle), never lower than the layout's
      final e = GargoyleHeadArt.visorEdge(.3);
      expect(e.inner.dx, GargoyleLayout.visorInner.dx);
      expect(GargoyleHeadArt.visorEdge(1).inner.dy, closeTo(GargoyleLayout.visorInner.dy + GargoyleLayout.visorDrop(1), 1e-9));
      expect(GargoyleHeadArt.hoodDrop(1), GargoyleLayout.visorDrop(1));
      for (final b in const [0.0, .3, .6]) {
        expect(GargoyleHeadArt.hoodDrop(b), lessThan(GargoyleLayout.visorDrop(b)), reason: 'brow $b lifts the hood');
      }
      expect(e.inner.dy, lessThan(GargoyleLayout.visorInner.dy + GargoyleLayout.visorDrop(.3)));
    });

    testWidgets('the beak hooks: tip no further forward than (-3.85,-1.8), hook >= .70 below the near lens and >= .55 beyond the brow', (tester) async {
      await tester.runAsync(() async {
        final m = await _local(_head(), ppu: 80);
        final b = m.bounds!;
        expect(b.rect.left, greaterThanOrEqualTo(-3.85), reason: 'the most forward point incl. ink');
        expect(b.atLeft.dy, inInclusiveRange(-2.4, -1.5), reason: 'the beak tip is at the beak, around y -1.9');
        expect(b.rect.bottom - GargoyleLayout.eyeNear.dy, greaterThanOrEqualTo(GargoyleGates.beakDrop + .3));
        final browFront = GargoyleHeadArt.visorEdge(.3).outer.dx;
        expect(browFront - b.rect.left, greaterThanOrEqualTo(GargoyleGates.beakProjection));
        // The hook hangs BELOW the jaw: the lowest solid pixel of the hook is
        // lower than the lowest of the jaw's front.
        double lowestIn(double x0, double x1) {
          var low = -9.0;
          for (var x = x0; x < x1; x += 1 / m.ppu) {
            for (var y = -1.0; y > -2.0; y -= 1 / m.ppu) {
              if (_px(m, x, y).$4 > 200) {
                low = math.max(low, y);
                break;
              }
            }
          }
          return low;
        }

        expect(lowestIn(-3.62, -3.52), greaterThan(lowestIn(-3.30, -3.10) + .15), reason: 'the hook overhangs the jaw');
      });
    });

    test('the crest: >= 3 swept blades, every tip behind its root, none above the crown by more than .35', () {
      expect(GargoyleHeadArt.crestBlades.length, greaterThanOrEqualTo(3));
      var top = 0.0;
      for (final (root, tip, w) in GargoyleHeadArt.crestBlades) {
        expect(tip.dx, greaterThan(root.dx), reason: 'raked back');
        expect(w, greaterThan(.05));
        top = math.min(top, tip.dy);
      }
      expect(top, greaterThanOrEqualTo(-3.10 - .35));
      expect(top, lessThanOrEqualTo(-3.10), reason: 'the crest crowns the head');
    });

    testWidgets('the extremes: skull back, crown and chin where the layout says, nothing past the beak or the crest', (tester) async {
      await tester.runAsync(() async {
        final m = await _local(_head(), ppu: 80);
        final r = m.bounds!.rect;
        // ignore: avoid_print
        print('head bounds (head-local, incl. ink): $r');
        expect(r.left, greaterThanOrEqualTo(-3.85));
        expect(r.top, greaterThanOrEqualTo(-3.30), reason: 'crest top');
        expect(r.right, lessThanOrEqualTo(-.30), reason: 'crest tips');
        expect(r.bottom, lessThanOrEqualTo(-1.05), reason: 'the hook');
        expect(r.bottom, greaterThanOrEqualTo(-1.15));
        // the skull itself reaches its back (a solid column at x -.80, y -2.3)
        expect(_px(m, -.80, -2.3).$4, greaterThan(200));
      });
    });

    testWidgets('the throat notch stays open under the head (the contract\'s throat gate, head alone, at rest)', (tester) async {
      await tester.runAsync(() async {
        final m = await rasterize(
          (c) => GargoyleBossRig.paintPose(c, GargoylePose.still, only: {'head'}, plinth: false),
          ppu: 12.4,
          solid: 128,
        );
        final d = m.largestEmptyDisc(const ui.Rect.fromLTRB(-3.6, -1.4, -1.45, -.15));
        // ignore: avoid_print
        print('throat notch, head alone: ${d.toStringAsFixed(2)} (gate ${GargoyleGates.throatNotch})');
        expect(d, greaterThanOrEqualTo(1.0));
      });
    });
  });

  group('the jaw and the mouth', () {
    testWidgets('the jaw opens by rotate(-gape * .5) about the hinge: its tip sweeps down, monotonically', (tester) async {
      await tester.runAsync(() async {
        final hinge = GargoyleLayout.jawHinge;
        // The jaw's front tip (the art's jaw point 4) at each gape, by the formula:
        const tip = ui.Offset(-3.42, -1.52);
        double tipY(double gape) => GargoyleKit.turn(tip - hinge, -gape * .5).dy + hinge.dy;
        var last = -1e9;
        final lows = <double>[];
        for (final g in const [0.0, .2, .4, .55, .75, 1.0]) {
          final m = await _local(_head(gape: g), ppu: 60);
          // the lowest solid pixel in the jaw's front band (right of the hook)
          var low = -9.0;
          for (var x = -3.34; x < -3.0; x += 1 / 60) {
            for (var y = -0.9; y > -2.4; y -= 1 / 60) {
              if (_px(m, x, y).$4 > 200) {
                low = math.max(low, y);
                break;
              }
            }
          }
          lows.add(low);
          expect(low, greaterThanOrEqualTo(last - .03), reason: 'gape $g: the jaw never rises');
          last = low;
          expect(tipY(g), greaterThanOrEqualTo(tipY(0) - 1e-9));
        }
        // ignore: avoid_print
        print('lowest jaw pixel by gape (0 .2 .4 .55 .75 1): ${lows.map((v) => v.toStringAsFixed(2)).join(' ')}');
        expect(lows.last - lows.first, greaterThan(.25), reason: 'a wide gape visibly drops the jaw');
        expect(tipY(1) - tipY(0), greaterThan(.35));
      });
    });

    testWidgets('an open mouth shows its warm dark interior; a shut beak shows none', (tester) async {
      await tester.runAsync(() async {
        // The interior is a dark plum under the lamp's warm light: red over blue
        // and dark, where the steel jaw and beak are blue and the ink is cold.
        int throat(Mask m) {
          var n = 0;
          for (var y = -1.95; y < -1.05; y += 1 / m.ppu) {
            for (var x = -3.62; x < -2.95; x += 1 / m.ppu) {
              final p = _px(m, x, y);
              if (p.$4 > 200 && p.$1 > p.$3 + 8 && _lum(p) < 135) n++;
            }
          }
          return n;
        }

        final shut = throat(await _local(_head(gape: 0)));
        final vent = throat(await _local(_head(gape: .55)));
        final roar = throat(await _local(_head(gape: .9)));
        // ignore: avoid_print
        print('throat pixels (60 ppu): shut $shut, vent $vent, roar $roar');
        expect(shut, lessThan(60), reason: 'a shut beak shows no throat');
        expect(vent, greaterThan(shut + 300));
        expect(roar, greaterThan(vent));
      });
    });

    testWidgets('an open mouth stays inside the head\'s extremes', (tester) async {
      await tester.runAsync(() async {
        for (final g in const [.55, .9, 1.0]) {
          final r = (await _local(_head(gape: g), ppu: 60)).bounds!.rect;
          expect(r.left, greaterThanOrEqualTo(-3.85), reason: 'gape $g');
          expect(r.bottom, lessThanOrEqualTo(-.55), reason: 'gape $g');
        }
      });
    });
  });

  group('the brow hoods', () {
    testWidgets('the hoods drop with the brow: the near hood\'s lower edge is where visorEdge says, at every step', (tester) async {
      await tester.runAsync(() async {
        var last = -9.0;
        for (final brow in const [0.0, .25, .5, .75, 1.0]) {
          final m = await _local(_head(brow: brow, flare: 1), ppu: 80);
          // Scan down x = -2.55 from above the hood: steel is blue (b > r + 25);
          // the first brass below the steel is the trim that sits on its edge.
          double? edge;
          var seenSteel = false;
          for (var y = -3.0; y < -2.0; y += 1 / 80) {
            final p = _px(m, -2.55, y);
            final steel = p.$3 > p.$1 + 25;
            if (steel) seenSteel = true;
            if (seenSteel && !steel && p.$1 > p.$3) {
              edge = y;
              break;
            }
          }
          expect(edge, isNotNull, reason: 'brow $brow');
          final e = GargoyleHeadArt.visorEdge(brow);
          final t = (-2.55 - e.inner.dx) / (e.outer.dx - e.inner.dx);
          final want = e.inner.dy + (e.outer.dy - e.inner.dy) * t;
          expect(edge!, closeTo(want, .12), reason: 'brow $brow (the trim sits on the edge)');
          expect(edge, greaterThan(last), reason: 'brow $brow drops it further');
          last = edge;
        }
      });
    });

    testWidgets('a lost visor takes the steel hoods away: the lens shows whole', (tester) async {
      await tester.runAsync(() async {
        final on = await _local(_head(flare: 1, brow: 1));
        final off = await _local(_head(flare: 1, brow: 1, visor: false));
        expect(_diff(on, off), greaterThan(1500));
        final p = _px(off, GargoyleLayout.eyeNear.dx, GargoyleLayout.eyeNear.dy);
        expect(p.$1, greaterThan(225), reason: 'the near lens\' centre shows white-hot with no hood');
      });
    });
  });

  group('the lenses', () {
    testWidgets('the lens centre is bright glass at full flare, in fury too (the beam sources stay visible: the eyeAt contract)', (tester) async {
      await tester.runAsync(() async {
        for (final fury in const [0.0, 1.0]) {
          final m = await _local(_head(flare: 1, brow: 0, fury: fury), ppu: 80);
          for (final eye in [GargoyleLayout.eyeNear, GargoyleLayout.eyeFar]) {
            final p = _px(m, eye.dx, eye.dy);
            expect(p.$1, greaterThan(225), reason: 'fury $fury $eye (r ${p.$1})');
            expect(p.$2, greaterThan(200));
          }
        }
      });
    });

    testWidgets('the lens glow follows the flare: the glass brightens monotonically with it', (tester) async {
      await tester.runAsync(() async {
        var last = -1.0;
        final seen = <String>[];
        for (final f in const [0.0, .15, .3, .5, .75, 1.0]) {
          final m = await _local(_head(flare: f, brow: 0), ppu: 80);
          final l = _lum(_px(m, GargoyleLayout.eyeNear.dx - .12, GargoyleLayout.eyeNear.dy + .12));
          seen.add(l.toStringAsFixed(0));
          expect(l, greaterThanOrEqualTo(last - 1), reason: 'flare $f');
          last = l;
        }
        // ignore: avoid_print
        print('near-lens luminance by flare 0 .15 .3 .5 .75 1: ${seen.join(' ')}');
        expect(last, greaterThan(220));
      });
    });

    testWidgets('the head agrees with the beam channels: the lens burns hotter while a beam burns than in idle or in the vent', (tester) async {
      await tester.runAsync(() async {
        Future<double> glow(GargoylePose p) async {
          final m = await _local(GargoyleHeadPose.of(p), ppu: 80);
          // the slit that shows under the hood, in the lens' lower half
          return _lum(_px(m, GargoyleLayout.eyeNear.dx, GargoyleLayout.eyeNear.dy + .20));
        }

        final idle = poseOf(gBoss(1.0));
        final sweep = poseOf(gBoss(4.8));
        final vent = poseOf(gBoss(7.2));
        expect(idle.beams, isEmpty);
        expect(vent.beams, isEmpty);
        expect(sweep.beams, isNotEmpty);
        expect(sweep.flare, greaterThan(.9));
        final gi = await glow(idle), gs = await glow(sweep), gv = await glow(vent);
        // ignore: avoid_print
        print('lens slit luminance: idle ${gi.toStringAsFixed(0)}, sweep ${gs.toStringAsFixed(0)}, vent ${gv.toStringAsFixed(0)}');
        expect(gs, greaterThan(gi + 25));
        expect(gv, lessThanOrEqualTo(gi + 2));
      });
    });

    testWidgets('a blink and the knock-out shut the lens behind steel lids; a half-open lens and a wince differ from both', (tester) async {
      await tester.runAsync(() async {
        final open = await _local(_head(flare: 1, brow: 0), ppu: 80);
        final shut = await _local(_head(flare: 1, brow: 0, iris: 0), ppu: 80);
        final c = GargoyleLayout.eyeNear;
        final po = _px(open, c.dx, c.dy), ps = _px(shut, c.dx, c.dy + .06);
        expect(po.$1, greaterThan(225));
        expect(_lum(ps), lessThan(_lum(po) - 60));
        final half = await _local(_head(flare: 1, brow: 0, iris: .5), ppu: 80);
        final wince = await _local(_head(flare: 1, brow: 0, wince: 1), ppu: 80);
        expect(_diff(open, half), greaterThan(300));
        expect(_diff(half, shut), greaterThan(300));
        expect(_diff(open, wince), greaterThan(500));
      });
    });

    testWidgets('the glass stays inside its brass ring: no amber leaks past it', (tester) async {
      await tester.runAsync(() async {
        final m = await _local(_head(flare: 1, brow: 0), ppu: 80);
        for (final (c, r) in [(GargoyleLayout.eyeNear, GargoyleLayout.eyeNearRadius), (GargoyleLayout.eyeFar, GargoyleLayout.eyeFarRadius)]) {
          var amber = 0;
          const n = 24;
          for (var i = 0; i < n; i++) {
            final a = i * 2 * math.pi / n;
            final p = _px(m, c.dx + math.cos(a) * (r + .17), c.dy + math.sin(a) * (r + .17));
            if (p.$1 > 240 && p.$2 > 190 && p.$3 < 140) amber++;
          }
          expect(amber, lessThanOrEqualTo(2), reason: 'lens $c');
        }
      });
    });
  });

  group('the face: a wink, a crease, gloss on the planes (the review\'s D1)', () {
    testWidgets('the wink: the live idle blink shuts the NEAR lens and leaves the far one burning; held still, both shut', (tester) async {
      await tester.runAsync(() async {
        final live = poseOf(gBoss(28.68)); // the peak of a blink, mid-perch
        expect(live.iris, lessThan(.05), reason: 'the pose is at the blink\'s peak');
        expect(live.time, greaterThan(0));
        double lum(Mask m, ui.Offset e, double dy) => _lum(_px(m, e.dx, e.dy + dy));
        final wink = await _local(GargoyleHeadPose.of(live), ppu: 80);
        final near = lum(wink, GargoyleLayout.eyeNear, .08), far = lum(wink, GargoyleLayout.eyeFar, .08);
        // ignore: avoid_print
        print('wink: near lens ${near.toStringAsFixed(0)}, far lens ${far.toStringAsFixed(0)}');
        expect(far, greaterThan(near + 30), reason: 'one eye shut, one burning');
        // the same blink with the clock stopped (a story\'s blink, Reduced Motion's frame): both shut
        final still = await _local(_head(iris: 0, flare: .3, brow: .3), ppu: 80);
        final bothNear = lum(still, GargoyleLayout.eyeNear, .08), bothFar = lum(still, GargoyleLayout.eyeFar, .08);
        expect(bothFar, lessThan(far - 25));
        expect((bothNear - bothFar).abs(), lessThan(50));
        // and the blink in a story pose shuts both too
        final story = await _local(GargoyleHeadPose.of(GargoylePose.story(GargoyleMood.plain, blink: 1)), ppu: 80);
        expect(lum(story, GargoyleLayout.eyeFar, .08), lessThan(far - 25));
        // stone and the knock-out never wink
        final dead = GargoyleHeadPose.of(poseOf(gBoss(1.0, deadFor: .7)));
        expect(dead.defeated, isTrue);
      });
    });

    testWidgets('an inked crease cuts the cheek at the beak\'s hinge', (tester) async {
      await tester.runAsync(() async {
        final m = await _local(_head(), ppu: 80);
        // on the crease (mid-segment of the first cut) the stone is ink-dark ...
        expect(_lum(_px(m, -1.99, -1.83)), lessThan(85));
        expect(_lum(_px(m, -1.87, -1.63)), lessThan(85));
        // ... and a hand-width beside it, the stone is light
        expect(_lum(_px(m, -1.72, -1.78)), greaterThan(110));
      });
    });

    testWidgets('gloss: hard cream streaks and a moon rim on the limestone planes; the shade side is violet', (tester) async {
      await tester.runAsync(() async {
        final m = await _local(_head(tone: const GargoyleTone(dark: 1)), ppu: 80);
        // a cream streak along the cheek ridge's upper bevel, brighter than the plane beside it
        final streak = _px(m, -1.80, -1.973), beside = _px(m, -1.80, -1.86);
        expect(_lum(streak), greaterThan(_lum(beside) + 25));
        expect(streak.$1, greaterThan(195));
        // a back-dome streak, a dot after it
        expect(_lum(_px(m, -.885, -2.235)), greaterThan(205));
        // the moon rim: a cool tint (blue over red) on the plane's upper-right edge, where plain cream has red over blue
        final rim = _px(m, -.96, -1.945);
        expect(rim.$3, greaterThanOrEqualTo(rim.$1 - 6), reason: 'cool, not cream (r ${rim.$1}, b ${rim.$3})');
        // the shade side is the violet, deeper than the palette's limeShade
        expect(GargoyleHeadArt.shadeViolet.computeLuminance(), lessThan(GargoylePalette.limeShade.computeLuminance()));
        final low = _px(m, -1.52, -1.40);
        expect(low.$3, greaterThan(low.$2 - 2), reason: 'violet: blue not under green (g ${low.$2}, b ${low.$3})');
      });
    });

    testWidgets('the far hood arches while the brow is relaxed and comes down in the scowl', (tester) async {
      await tester.runAsync(() async {
        // Scan UP the far lens' column from its middle: the first steel is the far hood's lower edge.
        double? edgeAt(Mask m) {
          for (var y = -2.50; y > -3.1; y -= 1 / 80) {
            final p = _px(m, -1.45, y);
            if (p.$3 > p.$1 + 25 && p.$4 > 200) return y;
          }
          return null;
        }

        final relaxed = edgeAt(await _local(_head(brow: 0), ppu: 80));
        final idle = edgeAt(await _local(_head(brow: .3), ppu: 80));
        final scowl = edgeAt(await _local(_head(brow: 1), ppu: 80));
        // ignore: avoid_print
        print('far hood\'s lower edge at the far lens: relaxed $relaxed, idle $idle, scowl $scowl');
        expect(relaxed, isNotNull);
        expect(idle, isNotNull);
        expect(scowl, isNotNull);
        expect(scowl!, greaterThan(idle! + .1));
        expect(idle, greaterThan(relaxed!));
        expect(idle - relaxed, greaterThan(.03), reason: 'the arch is a visible lift');
      });
    });

    test('a relaxed brow lifts the hoods (awake eyes at idle) yet the idle still covers the gate\'s quarter of the lens', () {
      expect(GargoyleHeadArt.nearLensCover(.3), inInclusiveRange(GargoyleGates.visorCover, .42));
      expect(GargoyleHeadArt.nearLensCover(.3), lessThan(.46), reason: 'the first delivery covered 46%');
      expect(GargoyleHeadArt.nearLensCover(1), closeTo(.67, .01), reason: 'the full scowl is untouched');
    });
  });

  group('the looks: flash, stone, fury, defeat', () {
    testWidgets('the hit flash goes near-white on the stone and the steel, and the ink holds', (tester) async {
      await tester.runAsync(() async {
        final plain = await _local(_head(), ppu: 60);
        final hit = await _local(_head(tone: const GargoyleTone(flash: .55)), ppu: 60);
        double mean(Mask m, ui.Rect r) {
          var s = 0.0, n = 0;
          for (var y = r.top; y < r.bottom; y += 1 / 60) {
            for (var x = r.left; x < r.right; x += 1 / 60) {
              s += _lum(_px(m, x, y));
              n++;
            }
          }
          return s / n;
        }

        const cheek = ui.Rect.fromLTRB(-1.9, -1.9, -1.2, -1.45);
        const beakFront = ui.Rect.fromLTRB(-3.7, -2.4, -3.45, -2.1);
        // ignore: avoid_print
        print('flash: cheek ${mean(plain, cheek).toStringAsFixed(0)} -> ${mean(hit, cheek).toStringAsFixed(0)}, beak ${mean(plain, beakFront).toStringAsFixed(0)} -> ${mean(hit, beakFront).toStringAsFixed(0)}');
        expect(mean(hit, cheek), greaterThan(mean(plain, cheek) + 18));
        expect(mean(hit, beakFront), greaterThan(mean(plain, beakFront) + 40));
        // the contour holds: the skull's back edge and the lens ring stay ink-dark
        expect(_lum(_px(hit, -.755, -2.3)), lessThan(90), reason: 'the ink holds under the flash');
        final ringBottom = _px(hit, GargoyleLayout.eyeNear.dx, GargoyleLayout.eyeNear.dy + GargoyleLayout.eyeNearRadius + .075);
        expect(_lum(ringBottom), lessThan(140));
      });
    });

    testWidgets('dormant stone greys the head (the lens too) and goes dark', (tester) async {
      await tester.runAsync(() async {
        final live = await _local(_head(flare: .3), ppu: 60);
        final stone = await _local(_head(flare: 0, tone: const GargoyleTone(stone: 1)), ppu: 60);
        int chroma((int, int, int, int) p) => math.max(p.$1, math.max(p.$2, p.$3)) - math.min(p.$1, math.min(p.$2, p.$3));
        for (final (x, y) in const [(-1.5, -1.6), (-3.65, -2.3), (-3.15, -2.6), (-2.40, -2.10)]) {
          expect(chroma(_px(stone, x, y)), lessThanOrEqualTo(math.max(14, chroma(_px(live, x, y)) ~/ 2) + 1), reason: 'at ($x,$y)');
        }
        expect(_lum(_px(stone, GargoyleLayout.eyeNear.dx, GargoyleLayout.eyeNear.dy + .12)), lessThan(150));
      });
    });

    testWidgets('the wake sheds grit while the stone is changing and the clock runs; nothing under Reduced Motion', (tester) async {
      await tester.runAsync(() async {
        const waking = GargoyleTone(stone: .5);
        final live = await _local(_head(tone: waking, time: 1.9), ppu: 60);
        final still = await _local(_head(tone: waking, time: 0), ppu: 60);
        expect(_diff(live, still), greaterThan(8));
        // a finished wake (no stone) sheds none even with the clock running
        final done = await _local(_head(time: 5), ppu: 60);
        expect(_diff(done, await _local(_head(time: 0), ppu: 60)), 0);
      });
    });

    testWidgets('fury: seams open from the lens rims in amber and white-hot', (tester) async {
      await tester.runAsync(() async {
        int hotPixels(Mask m) {
          var n = 0;
          for (var i = 0; i < m.data.length; i += 4) {
            if (m.data[i] > 235 && m.data[i + 1] > 150 && m.data[i + 1] < 235 && m.data[i + 2] < 140 && m.data[i + 3] > 200) n++;
          }
          return n;
        }

        final calm = await _local(_head(crack: 0, brow: 0, flare: .3), ppu: 80);
        final cracked = await _local(_head(crack: .6, brow: 0, flare: .3), ppu: 80);
        final deep = await _local(_head(crack: 1, brow: 0, flare: .3), ppu: 80);
        expect(hotPixels(cracked), greaterThan(hotPixels(calm) + 40));
        expect(hotPixels(deep), greaterThan(hotPixels(cracked) - 1));
        expect(_diff(calm, deep), greaterThan(600), reason: 'a deep crack covers the head');
        // a seam starts at a lens rim (the art's first seam point lies on the near lens' ring)
        const seamStart = ui.Offset(-2.68, -2.12);
        final d = (seamStart - GargoyleLayout.eyeNear).distance;
        expect(d, inInclusiveRange(GargoyleLayout.eyeNearRadius, GargoyleLayout.eyeNearRadius + .15));
      });
    });

    testWidgets('the defeat: the visor is off, the lenses are shut and uneven, the stone cracked', (tester) async {
      await tester.runAsync(() async {
        final pose = GargoylePose.atDeath(.7);
        final h = GargoyleHeadPose.of(pose);
        expect(h.visor, isFalse);
        expect(h.defeated, isTrue);
        expect(h.iris, lessThan(.2));
        expect(h.crack, greaterThan(.8));
        final live = await _local(GargoyleHeadPose.of(GargoylePose.still), ppu: 60);
        final dead = await _local(h, ppu: 60);
        expect(_diff(live, dead), greaterThan(3000));
      });
    });

    testWidgets('the crumble droops the crest and drops the jaw; the head still keeps its extremes', (tester) async {
      await tester.runAsync(() async {
        final whole = await _local(_head(crack: 1, visor: false), ppu: 60);
        final falling = await _local(_head(crack: 1, visor: false, crumble: 1), ppu: 60);
        expect(_diff(whole, falling), greaterThan(800));
        expect(falling.bounds!.rect.left, greaterThanOrEqualTo(-3.9));
      });
    });
  });

  group('the expressions are told apart (live and Reduced Motion)', () {
    for (final reduced in const [false, true]) {
      testWidgets('every pair of ${_states().length} expression states differs ${reduced ? 'under Reduced Motion' : 'live'}', (tester) async {
        await tester.runAsync(() async {
          final states = _states();
          final shots = <Mask>[];
          for (final (_, mk) in states) {
            shots.add(await rasterize((c) => GargoyleBossRig.paintPose(c, mk(reduced), only: {'head'}, plinth: false), ppu: 40, solid: 200));
          }
          final problems = <String>[];
          var least = 1 << 30;
          for (var i = 0; i < states.length; i++) {
            for (var j = i + 1; j < states.length; j++) {
              final d = _diff(shots[i], shots[j], 28);
              least = math.min(least, d);
              if (d < 120) problems.add('${states[i].$1} vs ${states[j].$1}: only $d pixels differ');
            }
          }
          // ignore: avoid_print
          print('${reduced ? 'RM' : 'live'}: the two most alike expressions still differ in $least px (at 40 ppu)');
          expect(problems, isEmpty);
        });
      });
    }

    testWidgets('Reduced Motion still frames: the idle head is identical at any age and carries no time; live idle moves', (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> shot(double t, {required bool reduced}) async {
          final p = poseOf(gBoss(t), reduced: reduced);
          if (reduced) expect(GargoyleHeadPose.of(p).time, 0);
          return _bytes((c) => GargoyleBossRig.paintPose(c, p, only: {'head'}, plinth: false), rig: true);
        }

        final a = await shot(1.0, reduced: true);
        expect(_same(await shot(1.6, reduced: true), a), isTrue);
        expect(_same(await shot(10.37, reduced: true), a), isTrue);
        var moved = false;
        for (final t in const [1.0, 1.9, 4.28, 8.5]) {
          if (!_same(await shot(t, reduced: false), a)) moved = true;
        }
        expect(moved, isTrue);
      });
    });

    test('Reduced Motion frames of the stone fade, the wake, the roar and the defeat carry no clock', () {
      for (final t in const [-3.6, -2.88, -2.6, -1.6]) {
        expect(GargoyleHeadPose.of(poseOf(gBoss(t), reduced: true)).time, 0, reason: 't $t');
      }
      expect(GargoyleHeadPose.of(poseOf(gBoss(1.0, deadFor: .7), reduced: true)).time, 0);
    });
  });

  group('the budget: 70 ops, 3 shaders, 2 clips; no saveLayer, no blur', () {
    test('every combination of the channels stays inside it', () {
      GargoyleKit.clearCaches();
      var worst = 0, clips = 0;
      var at = '';
      for (final gape in const [0.0, .55, 1.0]) {
        for (final flare in const [0.0, .3, 1.0]) {
          for (final brow in const [0.0, .5, 1.0]) {
            for (final fury in const [0.0, 1.0]) {
              for (final crack in const [0.0, .6, 1.0]) {
                for (final iris in const [0.0, .5, 1.0]) {
                  for (final (wince, visor, defeated, crumble) in const [(0.0, true, false, 0.0), (1.0, true, false, 0.0), (0.0, false, true, 1.0)]) {
                    final tone = GargoyleTone(flash: fury > 0 ? .5 : 0, fury: fury, heat: flare, stone: flare == 0 ? .5 : 0);
                    final n = _count(
                      _head(
                        tone: tone,
                        gape: gape,
                        flare: flare,
                        brow: brow,
                        fury: fury,
                        crack: crack,
                        iris: iris,
                        wince: wince,
                        visor: visor,
                        defeated: defeated,
                        crumble: crumble,
                        time: 1.8,
                      ),
                    );
                    if (n.ops > worst) {
                      worst = n.ops;
                      at = 'gape $gape flare $flare brow $brow fury $fury crack $crack iris $iris wince $wince';
                    }
                    clips = math.max(clips, n.clips);
                    expect(n.layers, 0);
                    expect(n.blurs, 0);
                  }
                }
              }
            }
          }
        }
      }
      final shaders = GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).toList();
      // ignore: avoid_print
      print('head worst case: $worst ops ($at), $clips clips; distinct shaders built: $shaders');
      expect(worst, lessThanOrEqualTo(70));
      expect(clips, lessThanOrEqualTo(2));
      expect(shaders.length, lessThanOrEqualTo(3));
      expect(GargoyleKit.built.where((k) => '$k'.startsWith('glow:')).length, lessThanOrEqualTo(2));
    });

    test('every real state is inside it, through the rig\'s own head part', () {
      GargoyleKit.clearCaches();
      for (final reduced in const [false, true]) {
        for (final (name, mk) in _states()) {
          final pose = mk(reduced);
          final c = Counting(ui.Canvas(ui.PictureRecorder()));
          GargoyleBossRig.paintPose(c, pose, only: {'head'});
          expect(c.draws, lessThanOrEqualTo(70), reason: '$name ${reduced ? 'RM' : ''}');
          expect(c.clips, lessThanOrEqualTo(2), reason: name);
          expect(c.layers + c.blurs, 0, reason: name);
        }
      }
    });

    test('a warm frame builds no shader, whatever the look (flash, fury and stone are colour, not shaders)', () {
      for (final tone in const [
        GargoyleTone(),
        GargoyleTone(flash: .55),
        GargoyleTone(fury: 1, heat: .6),
        GargoyleTone(stone: 1),
        GargoyleTone(dark: 0),
      ]) {
        _count(_head(tone: tone, gape: .5, crack: .8));
        final warm = _count(_head(tone: tone, gape: .9, crack: .3, flare: 1));
        expect(warm.shaders, 0);
      }
    });
  });

  group('determinism, caches and safety', () {
    testWidgets('pixels never depend on the order frames are drawn in: forward, then reversed with every cache flooded', (tester) async {
      await tester.runAsync(() async {
        final rnd = math.Random(5);
        final hs = <GargoyleHeadPose>[
          for (var i = 0; i < 36; i++)
            _head(
              tone: GargoyleTone(
                flash: rnd.nextInt(9) / 8 * .6,
                fury: rnd.nextBool() ? rnd.nextInt(9) / 8 : 0,
                heat: rnd.nextInt(9) / 8,
                stone: i % 7 == 0 ? rnd.nextInt(9) / 8 : 0,
                dark: rnd.nextInt(5) / 4,
              ),
              gape: rnd.nextDouble(),
              flare: rnd.nextDouble(),
              brow: rnd.nextDouble(),
              iris: i % 4 == 0 ? rnd.nextDouble() : 1,
              fury: rnd.nextBool() ? rnd.nextDouble() : 0,
              crack: rnd.nextBool() ? rnd.nextDouble() : 0,
              wince: i % 5 == 0 ? rnd.nextDouble() : 0,
              visor: i % 9 != 0,
              defeated: i % 11 == 0,
              crumble: i % 13 == 0 ? rnd.nextDouble() : 0,
              time: i % 3 == 0 ? 1.7 + rnd.nextDouble() : 0,
            ),
        ];
        final forward = <Uint8List>[];
        for (final h in hs) {
          forward.add(await _bytes((c) => GargoyleHeadArt.paint(c, h)));
        }
        // flood every cache with junk, then go through the states backwards
        for (var i = 0; i < GargoyleKit.cacheCapacity + 40; i++) {
          GargoyleKit.cached('junk$i', ui.Paint.new);
        }
        GargoyleKit.clearCaches();
        for (var i = hs.length - 1; i >= 0; i--) {
          final again = await _bytes((c) => GargoyleHeadArt.paint(c, hs[i]));
          expect(_same(again, forward[i]), isTrue, reason: 'state $i differs when drawn after others');
        }
      });
    });

    test('the caches stay bounded: thousands of looks build only the head\'s three shaders, once each', () {
      GargoyleKit.clearCaches();
      final rnd = math.Random(8);
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      for (var i = 0; i < 3000; i++) {
        GargoyleHeadArt.paint(
          c,
          _head(
            tone: GargoyleTone(flash: rnd.nextDouble(), fury: rnd.nextDouble(), heat: rnd.nextDouble(), stone: rnd.nextDouble(), dark: rnd.nextDouble()),
            gape: rnd.nextDouble(),
            flare: rnd.nextDouble(),
            brow: rnd.nextDouble(),
            iris: rnd.nextDouble(),
            crack: rnd.nextDouble(),
          ),
        );
      }
      rec.endRecording().dispose();
      expect(GargoyleKit.cacheSize, lessThanOrEqualTo(GargoyleKit.cacheCapacity));
      final own = GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).toList();
      expect(own.toSet(), {'head.skull', 'head.steel', 'head.glass'});
      expect(own.length, 3, reason: 'each shader once');
    });

    testWidgets('non-finite channels are harmless: they paint exactly the neutral head', (tester) async {
      await tester.runAsync(() async {
        const nan = double.nan, inf = double.infinity;
        for (final bad in const [nan, inf, -inf]) {
          final rec = ui.PictureRecorder();
          expect(
            () => GargoyleHeadArt.paint(
              ui.Canvas(rec),
              _head(gape: bad, flare: bad, brow: bad, iris: bad, fury: bad, crack: bad, wince: bad, time: bad, crumble: bad),
            ),
            returnsNormally,
          );
          rec.endRecording().dispose();
        }
        final neutral = await _bytes((c) => GargoyleHeadArt.paint(c, _head()));
        final broken = await _bytes(
          (c) => GargoyleHeadArt.paint(
            c,
            const GargoyleHeadPose(
              tone: GargoyleTone(flash: nan, fury: inf, heat: nan, stone: -inf),
              gape: nan,
              flare: nan,
              brow: nan,
              iris: nan,
              fury: inf,
              crack: nan,
              wince: nan,
              roar: nan,
              glance: nan,
              hit: nan,
              wind: nan,
              crumble: nan,
              time: nan,
            ),
          ),
        );
        expect(_same(broken, neutral), isTrue, reason: 'every NaN / infinite channel falls back to the neutral value');
        // a boss with NaN clocks still gives a finite head
        final b = gBoss(3.0, fury: true)..age = nan;
        final h = GargoyleHeadPose.of(GargoylePose(b, BossMotion(b, reducedMotion: false)));
        for (final v in [h.gape, h.flare, h.brow, h.iris, h.fury, h.crack, h.wince, h.roar, h.glance, h.hit, h.wind, h.crumble]) {
          expect(v.isFinite, isTrue);
        }
      });
    });
  });

  group('the head in the rig', () {
    testWidgets('the lens anchors are bright glass in the real rig at lean +-.6 and pitch -.2..+.3, in fury too', (tester) async {
      await tester.runAsync(() async {
        for (final fury in const [0.0, 1.0]) {
          for (final (lean, pitch, head) in const [(0.0, 0.0, ui.Offset.zero), (.6, .3, ui.Offset(.1, .1)), (-.6, -.2, ui.Offset(.2, -.05)), (-.6, .3, ui.Offset.zero)]) {
            final pose = GargoylePose.custom(brow: 0, flare: 1, fury: fury, lean: lean, pitch: pitch, head: head);
            final m = await rasterize((c) => GargoyleBossRig.paintPose(c, pose, only: {'head'}, plinth: false), ppu: 24, solid: 1);
            for (final far in [false, true]) {
              final e = GargoyleBossRig.eyeAt(pose, far: far);
              final x = ((e.dx - m.x0) * m.ppu).round(), y = ((e.dy - m.y0) * m.ppu).round();
              final i = (y * m.w + x) * 4;
              expect(m.data[i], greaterThan(225), reason: 'lens ${far ? 'far' : 'near'} fury $fury lean $lean pitch $pitch');
              expect(m.data[i + 1], greaterThan(200));
            }
          }
        }
      });
    });

    testWidgets('the loose visor (what the defeat knocks off and the keepsake shows) is a flat steel hood around its seat', (tester) async {
      await tester.runAsync(() async {
        const region = ui.Rect.fromLTRB(-1.4, -.8, 1.4, 1.2);
        final before = GargoyleKit.shadersBuilt;
        final m = await rasterize(GargoyleHeadArt.visorPaint, ppu: 80, region: region, solid: 200);
        expect(GargoyleKit.shadersBuilt, before, reason: 'no shader');
        final r = m.bounds!.rect;
        // ignore: avoid_print
        print('loose visor bounds around its seat: $r (the layout\'s visorBounds ${GargoyleLayout.visorBounds})');
        expect(r.width, inInclusiveRange(1.4, 2.0));
        expect(r.height, inInclusiveRange(.7, 1.1));
        // the layout's box (what the tumble and the story art fit) holds the drawn hood
        const box = GargoyleLayout.visorBounds;
        expect(r.left, greaterThanOrEqualTo(box.left));
        expect(r.top, greaterThanOrEqualTo(box.top));
        expect(r.right, lessThanOrEqualTo(box.right));
        expect(r.bottom, lessThanOrEqualTo(box.bottom));
        expect(r.left, greaterThanOrEqualTo(-1.0));
        expect(r.right, lessThanOrEqualTo(1.0));
        final flashed = await rasterize((c) => GargoyleHeadArt.visorPaint(c, const GargoyleTone(flash: .55)), ppu: 80, region: region, solid: 200);
        expect(_lum(_px(flashed, -.3, .35)), greaterThan(_lum(_px(m, -.3, .35)) + 30));
        // calling it twice paints the same pixels (no state)
        final again = await rasterize(GargoyleHeadArt.visorPaint, ppu: 80, region: region, solid: 200);
        expect(_diff(m, again), 0);
      });
    });

    test('the beak tip and the lenses keep the contract\'s places in a real pose', () {
      final p = poseOf(gBoss(4.8));
      final tip = GargoyleBossRig.beakTipAt(p), near = GargoyleBossRig.eyeAt(p), far = GargoyleBossRig.eyeAt(p, far: true);
      expect(tip.dx, lessThan(near.dx - 1.0));
      expect(near.dx, lessThan(far.dx));
      expect(near.dy, greaterThan(far.dy));
    });
  });

  // ------------------------------------------------------------- reviews --

  group('review sheets (off unless GARGOYLE_HEAD_REVIEW=true)', () {
    Future<void> save(ui.Image image, String name) async {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    }

    Future<ui.Image> render(int w, int h, void Function(ui.Canvas) draw) async {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec)..clipRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
      draw(c);
      final pic = rec.endRecording();
      final img = await pic.toImage(w, h);
      pic.dispose();
      return img;
    }

    List<(String, GargoylePose Function())> states({bool reduced = false}) => [
      ('stone', () => poseOf(gBoss(-3.6), reduced: reduced)),
      ('wake spark', () => poseOf(gBoss(1.72 - 4.6), reduced: reduced)),
      ('idle', () => poseOf(gBoss(1.0), reduced: reduced)),
      ('warning', () => poseOf(gBoss(3.2), reduced: reduced)),
      ('sweep', () => poseOf(gBoss(4.8), reduced: reduced)),
      ('sweep LOW', () => poseOf(gBoss(5.0, side: BeamSide.low), reduced: reduced)),
      ('vent (smug)', () => poseOf(gBoss(7.2), reduced: reduced)),
      ('fury slit', () => poseOf(gBoss(5.0, fury: true, slit: true), reduced: reduced)),
      ('fury roar', () => poseOf(gBoss(1.0, fury: true, enragedAgo: .4), reduced: reduced)),
      ('hit flash', () => poseOf(gBoss(1.0, hitAgo: .04), reduced: reduced)),
      ('hit wince', () => poseOf(gBoss(1.0, hitAgo: .16), reduced: reduced)),
      ('arrival roar', () => poseOf(gBoss(-1.6), reduced: reduced)),
      ('wink (live blink)', () => poseOf(gBoss(28.68), reduced: reduced)),
      ('blink (story)', () => GargoylePose.story(GargoyleMood.plain, blink: .85)),
      ('dizzy (.30 s)', () => poseOf(gBoss(1.0, deadFor: .30), reduced: reduced)),
      ('defeat (.70 s)', () => poseOf(gBoss(1.0, deadFor: .70), reduced: reduced)),
      ('story plain', () => GargoylePose.story(GargoyleMood.plain)),
      ('story happy', () => GargoylePose.story(GargoyleMood.happy)),
      ('story sad', () => GargoylePose.story(GargoyleMood.sad)),
      ('story angry', () => GargoylePose.story(GargoyleMood.angry)),
      ('story beaten', () => GargoylePose.story(GargoyleMood.beaten)),
    ];

    void paintHeadAt(ui.Canvas c, GargoylePose pose, ui.Offset origin, double ppu) {
      c.save();
      c.translate(origin.dx, origin.dy);
      c.scale(ppu);
      GargoyleBossRig.paintPose(c, pose, only: {'ruff', 'head'}, plinth: false);
      c.restore();
    }

    Future<ui.Image> headSheet(
      List<(String, GargoylePose Function())> list, {
      required double ppu,
      int cols = 3,
      int cellW = 520,
      int cellH = 400,
      ui.Color bg = const ui.Color(0xff2a2746),
      ui.Color? bg2,
    }) {
      final rows = (list.length / cols).ceil();
      return render(cols * cellW, rows * cellH, (c) {
        for (var i = 0; i < list.length; i++) {
          final x0 = (i % cols) * cellW.toDouble(), y0 = (i ~/ cols) * cellH.toDouble();
          c.save();
          c.clipRect(ui.Rect.fromLTWH(x0, y0, cellW.toDouble(), cellH.toDouble()));
          c.drawRect(
            ui.Rect.fromLTWH(x0, y0, cellW.toDouble(), cellH.toDouble()),
            ui.Paint()..shader = ui.Gradient.linear(ui.Offset(x0, y0), ui.Offset(x0, y0 + cellH), [bg, bg2 ?? bg]),
          );
          final pose = list[i].$2();
          // centre each cell on where THIS pose carries the head
          final mid = pose.headPoint(const ui.Offset(-2.2, -2.2));
          paintHeadAt(c, pose, ui.Offset(x0 + cellW / 2 - mid.dx * ppu, y0 + cellH / 2 - mid.dy * ppu), ppu);
          text(c, list[i].$1, ui.Offset(x0 + 6, y0 + 4), 13, const ui.Color(0xffffffff), outline: true);
          c.restore();
        }
      });
    }

    Future<ui.Image> creatureSheet(List<(String, GargoylePose Function())> list, {required int cell, int cols = 5, bool flat = false}) {
      const label = 20;
      final rows = (list.length / cols).ceil();
      final w = cols * cell, h = rows * (cell + label);
      const fx0 = -5.0, fy0 = -4.6, span = 9.7;
      final scale = cell / span;
      return render(w, h, (c) {
        c.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = flat ? const ui.Color(0xffe9dfd2) : const ui.Color(0xff14122a));
        for (var i = 0; i < list.length; i++) {
          final x0 = (i % cols) * cell.toDouble(), y0 = (i ~/ cols) * (cell + label).toDouble() + label;
          c.save();
          c.clipRect(ui.Rect.fromLTWH(x0, y0 - label, cell.toDouble(), cell.toDouble() + label));
          text(c, list[i].$1, ui.Offset(x0 + 4, y0 - label + 2), cell >= 200 ? 12 : 9, flat ? const ui.Color(0xff222222) : const ui.Color(0xffffffff), bold: false);
          c.clipRect(ui.Rect.fromLTWH(x0, y0, cell.toDouble(), cell.toDouble()));
          if (!flat) {
            c.drawRect(
              ui.Rect.fromLTWH(x0, y0, cell.toDouble(), cell.toDouble()),
              ui.Paint()..shader = ui.Gradient.linear(ui.Offset(0, y0), ui.Offset(0, y0 + cell), const [ui.Color(0xff3a3768), ui.Color(0xff6a5b8c)]),
            );
          }
          c.translate(x0 - fx0 * scale, y0 - fy0 * scale);
          c.scale(scale);
          final pose = list[i].$2();
          if (flat) {
            c.saveLayer(null, ui.Paint()..colorFilter = const ui.ColorFilter.mode(ui.Color(0xff000000), ui.BlendMode.srcIn));
            GargoyleBossRig.paintPose(c, pose, plinth: false);
            c.restore();
          } else {
            GargoyleBossRig.paintPose(c, pose);
          }
          c.restore();
        }
      });
    }

    test('close-ups (3x and 6x phone size) on dark and light', skip: !_review, () async {
      final s = states(reduced: true);
      final live = states();
      (String, GargoylePose Function()) pick(String n) => (n.startsWith('wink') ? live : s).firstWhere((e) => e.$1 == n);
      final a = [for (final n in ['idle', 'warning', 'sweep', 'vent (smug)', 'fury slit', 'hit flash']) pick(n)];
      final b = [for (final n in ['hit wince', 'arrival roar', 'wink (live blink)', 'dizzy (.30 s)', 'stone', 'wake spark']) pick(n)];
      await save(await headSheet(a, ppu: 125), 'a-closeups-dark');
      await save(await headSheet(b, ppu: 125), 'a-closeups-dark2');
      await save(await headSheet(a, ppu: 125, bg: const ui.Color(0xffe8d9b8), bg2: const ui.Color(0xfff6eed8)), 'a-closeups-light');
      await save(await headSheet([pick('idle'), pick('sweep')], ppu: 248, cols: 2, cellW: 1000, cellH: 720), 'a-closeups-6x');
    });

    test('expression sheets at phone size, 120 px and under Reduced Motion; silhouettes at 250 and 120 px', skip: !_review, () async {
      final all = states();
      const sky1 = ui.Color(0xff3a3768), sky2 = ui.Color(0xff6a5b8c);
      await save(await creatureSheet(all, cell: 120, cols: 10), 'b-expressions-120');
      await save(await headSheet(all, ppu: 46, cols: 5, cellW: 230, cellH: 170, bg: sky1, bg2: sky2), 'b-expressions-phone');
      await save(await headSheet(states(reduced: true), ppu: 46, cols: 5, cellW: 230, cellH: 170, bg: sky1, bg2: sky2), 'b-expressions-reduced-motion');
      await save(await creatureSheet(all.take(10).toList(), cell: 250, cols: 5, flat: true), 'c-silhouette-250');
      await save(await creatureSheet(all, cell: 120, cols: 10, flat: true), 'c-silhouette-120');
    });

    test('in game over New York\'s night at 640 and 800', skip: !_review, () async {
      for (final w in [640, 800]) {
        final s = ui.Size(w.toDouble(), 360);
        final aspect = w / 360;
        final shots = <(String, SkyBoss, double)>[
          ('perch', gBoss(1.0, aspect: aspect), .65),
          ('warning', gBoss(3.1, aspect: aspect), .7),
          ('sweep', gBoss(4.6, aspect: aspect), .78),
          ('vent', gBoss(7.1, aspect: aspect), .5),
          ('fury slit', gBoss(5.0, fury: true, slit: true, aspect: aspect), .5),
          ('hit', gBoss(1.0, hitAgo: .05, aspect: aspect), .5),
        ];
        final img = await render(w * 2, 360 * 3, (c) {
          for (var i = 0; i < shots.length; i++) {
            c.save();
            c.translate((i % 2) * s.width, (i ~/ 2) * s.height);
            c.clipRect(ui.Offset.zero & s);
            paintFrame(c, s, shots[i].$2, FrameOptions(birdY: shots[i].$3, label: shots[i].$1));
            c.restore();
          }
        });
        await save(img, 'd-ingame-$w');
      }
    });
  });
}
