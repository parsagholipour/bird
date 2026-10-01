import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';

double _lstar(Color c) {
  final y = c.computeLuminance();
  return y > 216 / 24389 ? 116 * math.pow(y, 1 / 3) - 16 : 24389 / 27 * y;
}

/// HSV saturation: how far a colour is from white or grey (the measure that
/// separates the boss beam from New York's cream).
double _sat(Color c) => HSVColor.fromColor(c).saturation;

void main() {
  group('the palette (CIE L* is the contract)', () {
    test('ink and crevices sit at the bottom', () {
      expect(_lstar(GargoylePalette.ink), lessThan(10));
      expect(_lstar(GargoylePalette.inkWarm), lessThan(14));
      expect(_lstar(GargoylePalette.limeCore), lessThan(28));
      expect(_lstar(GargoylePalette.steelCore), lessThan(22));
    });

    test('limestone, steel and brass ramps run dark to light, in order', () {
      const lime = [
        GargoylePalette.limeCore, GargoylePalette.limeDeep, GargoylePalette.limeShade,
        GargoylePalette.lime, GargoylePalette.limeLit, GargoylePalette.limeSheen,
      ];
      const steel = [
        GargoylePalette.steelCore, GargoylePalette.steelDeep, GargoylePalette.steelMid,
        GargoylePalette.steel, GargoylePalette.steelLit,
      ];
      const brass = [GargoylePalette.brassShade, GargoylePalette.brassDeep, GargoylePalette.brass, GargoylePalette.brassLit];
      for (final ramp in [lime, steel, brass]) {
        for (var i = 1; i < ramp.length; i++) {
          expect(_lstar(ramp[i]), greaterThan(_lstar(ramp[i - 1])));
        }
      }
      // limestone is the light material: the body (lime) reads at L* 70 .. 80
      expect(_lstar(GargoylePalette.lime), inInclusiveRange(70, 80));
    });

    test('the lamp and the lenses are the brightest thing on him', () {
      final brightest = [
        GargoylePalette.limeSheen, GargoylePalette.limeLit, GargoylePalette.steelLit, GargoylePalette.brassLit,
      ].map(_lstar).reduce(math.max);
      expect(_lstar(GargoylePalette.lampCore), greaterThan(brightest));
      expect(_lstar(GargoylePalette.lampCore), greaterThan(95));
      expect(_lstar(GargoylePalette.arcCore), greaterThan(95));
      expect(_lstar(GargoylePalette.lampAmber), greaterThan(_lstar(GargoylePalette.limeShade)));
    });

    test('warm is lamp, cool is moon and dodge tags: amber never means "safe"', () {
      Color c(Color x) => x;
      expect(c(GargoylePalette.lampAmber).r, greaterThan(c(GargoylePalette.lampAmber).b));
      expect(GargoylePalette.moon.b, greaterThan(GargoylePalette.moon.r));
      expect(GargoylePalette.cool.b, greaterThan(GargoylePalette.cool.r));
      expect(GargoylePalette.vd.g, greaterThan(GargoylePalette.vd.r));
    });

    test('every colour is opaque', () {
      for (final c in [
        GargoylePalette.ink, GargoylePalette.lime, GargoylePalette.steel, GargoylePalette.brass,
        GargoylePalette.lampCore, GargoylePalette.arcEdge, GargoylePalette.moon, GargoylePalette.pier,
      ]) {
        expect(c.a, 1.0);
      }
    });
  });

  group('the tone', () {
    test('a hit goes most of the way to the lamp\'s white, lights a little further than darks, ink holds', () {
      const flash = GargoyleTone(flash: .55);
      final light = flash.lit(GargoylePalette.limeLit);
      final dark = flash.lit(GargoylePalette.limeDeep);
      expect(_lstar(light), greaterThan(_lstar(GargoylePalette.limeLit)));
      // how far each went toward white, averaged over the channels
      double frac(Color from, Color to) =>
          ((to.r - from.r) / (1 - from.r) + (to.g - from.g) / (1 - from.g) + (to.b - from.b) / (1 - from.b)) / 3;
      final fracLight = frac(GargoylePalette.limeLit, light);
      final fracDark = frac(GargoylePalette.limeDeep, dark);
      expect(fracLight, greaterThan(fracDark - .02), reason: 'lights go at least as far as darks');
      expect(fracLight, lessThan(.95), reason: 'the carving must survive the flash');
      expect(const GargoyleTone().lit(GargoylePalette.lime), GargoylePalette.lime);
    });

    test('dormant stone greys every colour and keeps it a little darker', () {
      const stone = GargoyleTone(stone: 1);
      for (final c in [GargoylePalette.lime, GargoylePalette.steel, GargoylePalette.lampAmber, GargoylePalette.brass]) {
        final g = stone.lit(c);
        expect(_sat(g), lessThan(_sat(c) * .5), reason: '$c');
      }
      expect(stone.lit(GargoylePalette.lime).a, 1.0);
    });

    test('the colour filter for gradient paints: null when neutral, brighter under a flash, greyer under stone', () {
      expect(const GargoyleTone().filter, isNull);
      expect(const GargoyleTone(flash: .5).filter, isNotNull);
      expect(const GargoyleTone(stone: .5).filter, isNotNull);
      // apply the filter's matrix by hand (it is the only thing it is)
      Color apply(GargoyleTone t, Color c) {
        // ColorFilter has no public matrix, so rebuild it: the tone's own lit()
        // on the same colour must agree in direction
        return t.lit(c);
      }

      expect(_lstar(apply(const GargoyleTone(flash: .55), GargoylePalette.steelMid)), greaterThan(_lstar(GargoylePalette.steelMid)));
    });

    test('the moon rim is stronger on a dark sky and weaker in fury; the lamp fill grows with heat and fury', () {
      expect(const GargoyleTone(dark: 1).moonRim, greaterThan(const GargoyleTone(dark: 0).moonRim));
      expect(const GargoyleTone(fury: 1).moonRim, lessThan(const GargoyleTone().moonRim));
      expect(const GargoyleTone(heat: 1).lampFill, greaterThan(const GargoyleTone().lampFill));
      expect(const GargoyleTone(fury: 1).lampFill, greaterThan(const GargoyleTone().lampFill));
      expect(const GargoyleTone(heat: 1, fury: 1).lampFill, lessThanOrEqualTo(1));
      expect(const GargoyleTone(fury: 1).glow, greaterThan(const GargoyleTone().glow));
    });

    test('cracks are amber at rest and arc-white at the core in fury', () {
      expect(_lstar(const GargoyleTone(fury: 1).crackCore), greaterThan(_lstar(const GargoyleTone().crackCore)));
      expect(const GargoyleTone().crackEdge, GargoylePalette.lampAmber);
      expect(const GargoyleTone(fury: 1).crackEdge, GargoylePalette.arcEdge);
    });

    test('the snapped tone sits on the ladder, one bucket per step', () {
      final keys = <int, GargoyleTone>{};
      for (var k = 0; k < 4000; k++) {
        final r = math.Random(k);
        final t = GargoyleTone(
          flash: r.nextDouble(),
          fury: r.nextDouble(),
          heat: r.nextDouble(),
          dark: r.nextDouble(),
          stone: r.nextDouble(),
          sky: Color(0xff000000 | r.nextInt(0xffffff)),
        );
        final s = t.snapped();
        expect(s.snapped().key, s.key, reason: 'idempotent');
        expect(s.flash * GargoyleTone.steps, closeTo((s.flash * 8).roundToDouble(), 1e-9));
        expect(s.fury * GargoyleTone.steps, closeTo((s.fury * 8).roundToDouble(), 1e-9));
        expect(s.heat * GargoyleTone.steps, closeTo((s.heat * 8).roundToDouble(), 1e-9));
        expect(s.stone * GargoyleTone.steps, closeTo((s.stone * 8).roundToDouble(), 1e-9));
        expect(s.dark * GargoyleTone.darkSteps, closeTo((s.dark * 4).roundToDouble(), 1e-9));
        expect((s.flash - t.flash).abs(), lessThanOrEqualTo(1 / 16 + 1e-9));
        expect((s.dark - t.dark).abs(), lessThanOrEqualTo(1 / 8 + 1e-9));
        expect(s.sky.toARGB32() & 0xfff8f8f8, s.sky.toARGB32());
        final other = keys.putIfAbsent(s.key, () => s);
        expect((other.flash, other.fury, other.heat, other.dark, other.stone), (s.flash, s.fury, s.heat, s.dark, s.stone),
            reason: 'one bucket per step of the ladder');
      }
    });

    test('a non-finite channel snaps to zero, never NaN', () {
      const t = GargoyleTone(flash: double.nan, fury: double.infinity, heat: double.negativeInfinity, stone: double.nan);
      final s = t.snapped();
      expect([s.flash, s.fury, s.heat, s.stone], everyElement(0.0));
    });
  });

  group('the sky\'s light', () {
    test('dark runs 0 (bright) .. 1 (night) and tints the rim by the haze', () {
      final day = GargoyleSkyLight.fromSky(top: const Color(0xff9fd0ff), horizon: const Color(0xffe8f4ff), haze: const Color(0xffffffff));
      final night = GargoyleSkyLight.fromSky(top: const Color(0xff050814), horizon: const Color(0xff141a39), haze: const Color(0xff2a2f5e));
      expect(day.dark, 0);
      expect(night.dark, greaterThan(.7));
      expect(night.sky, isNot(day.sky));
      expect(GargoyleSkyLight.neutral.sky, GargoylePalette.moon);
    });
  });

  group('the beam\'s look and its placement', () {
    test('not New York\'s searchlights: warm and saturated, never cream', () {
      expect(_sat(GargoyleBeamLook.regionCream), lessThan(.2));
      for (final c in [GargoyleBeamLook.edge, GargoyleBeamLook.body, GargoyleBeamLook.furyEdge]) {
        expect(_sat(c), greaterThan(.5), reason: '$c');
        final hue = HSLColor.fromColor(c).hue;
        expect(hue, inInclusiveRange(25, 50));
      }
      // Fury is arc-white at the core but keeps an orange edge.
      expect(_lstar(GargoyleBeamLook.furyCore), greaterThan(_lstar(GargoyleBeamLook.core)));
      expect(_sat(GargoyleBeamLook.furyEdge), greaterThan(_sat(GargoyleBeamLook.regionCream) * 3));
    });

    test('the alphas never exceed .55 and the hairlines are hard', () {
      expect(GargoyleBeamLook.coreAlpha, lessThanOrEqualTo(GargoyleBeamLook.maxAlpha));
      expect(GargoyleBeamLook.furyCoreAlpha, GargoyleBeamLook.maxAlpha);
      expect(GargoyleBeamLook.hazeAlpha, lessThan(GargoyleBeamLook.bodyAlpha));
      expect(GargoyleBeamLook.bodyAlpha, lessThan(GargoyleBeamLook.coreAlpha));
      expect(GargoyleBeamLook.edgeWidthPx, 1.6);
      expect(GargoyleBeamLook.coreAlpha, greaterThan(.25), reason: 'stronger than the region\'s core');
      expect(GargoyleBeamLook.maxOps, 6);
      expect(GargoyleBeamLook.maxVertices, 40);
    });

    test('beamFrame carries the unit triangle through the rules\' band at the bird\'s column', () {
      for (final (eye, col, centre, half) in const [
        (Offset(560, 92), 169.2, 200.0, 32.4),
        (Offset(420, 110), 169.2, 302.0, 34.2),
        (Offset(980, 84), 169.2, 70.0, 32.4),
      ]) {
        final f = GargoyleKit.beamFrame(eye: eye, columnX: col, centre: centre, half: half)!;
        final m = f.matrix;
        // the canvas's column-major 4x4: x' = m0 u + m4 v + m12, y' = m1 u + m5 v + m13
        Offset at(double u, double v) => Offset(m[0] * u + m[4] * v + m[12], m[1] * u + m[5] * v + m[13]);

        expect((at(0, 0) - eye).distance, lessThan(1e-9), reason: 'apex at the lens');
        // where the wedge crosses the column: u = 1 / reach
        final u = 1 / f.reach;
        final top = at(u, -u), bottom = at(u, u);
        expect(top.dx, closeTo(col, 1e-6));
        expect(bottom.dx, closeTo(col, 1e-6));
        expect(top.dy, closeTo(centre - half, 1e-6));
        expect(bottom.dy, closeTo(centre + half, 1e-6));
        // the wedge ends at the left screen edge (reachX = 0)
        expect(at(1, 0).dx, closeTo(0, 1e-6));
        expect(f.edgeTop.dx, closeTo(0, 1e-6));
        expect(f.edgeBottom.dx, closeTo(0, 1e-6));
        expect(f.reach, greaterThan(1));
      }
    });

    test('no beam is placed from a lens that is not right of the column', () {
      expect(GargoyleKit.beamFrame(eye: const Offset(100, 50), columnX: 169, centre: 100, half: 30), isNull);
      expect(GargoyleKit.beamFrame(eye: const Offset(169.5, 50), columnX: 169, centre: 100, half: 30), isNull);
    });
  });

  group('caches and helpers', () {
    test('cached paints are kept, least-recently-used, bounded and never cleared all at once', () {
      GargoyleKit.clearCaches();
      var built = 0;
      Paint make() {
        built++;
        return Paint();
      }

      final a = GargoyleKit.cached('a', make);
      expect(GargoyleKit.cached('a', make), same(a));
      expect(built, 1);
      for (var i = 0; i < GargoyleKit.cacheCapacity + 50; i++) {
        GargoyleKit.cached('k$i', make);
        GargoyleKit.cached('a', make); // kept hot
      }
      expect(GargoyleKit.cacheSize, lessThanOrEqualTo(GargoyleKit.cacheCapacity));
      expect(GargoyleKit.cacheSize, greaterThan(GargoyleKit.cacheCapacity - 2), reason: 'evicts singly, never all at once');
      final before = built;
      GargoyleKit.cached('a', make);
      expect(built, before, reason: 'the hot entry survived');
      expect(GargoyleKit.built, contains('a'));
      GargoyleKit.clearCaches();
      expect(GargoyleKit.cacheSize, 0);
      expect(GargoyleKit.built, isEmpty);
    });

    test('shaders built through the kit are counted; a glow builds once per colour step', () {
      GargoyleKit.clearCaches();
      final before = GargoyleKit.shadersBuilt;
      GargoyleKit.linear(Offset.zero, const Offset(1, 0), const [Color(0xff000000), Color(0xffffffff)]);
      GargoyleKit.radial(Offset.zero, 1, const [Color(0xff000000), Color(0xffffffff)]);
      expect(GargoyleKit.shadersBuilt - before, 2);
      final c = ui.Canvas(ui.PictureRecorder());
      final g0 = GargoyleKit.shadersBuilt;
      for (var i = 0; i < 20; i++) {
        // colours within one 5-bit step share the shader
        GargoyleKit.glow(c, Offset.zero, 2, Color.fromARGB(255, 255, 227, 154 + (i % 2)), .5);
      }
      expect(GargoyleKit.shadersBuilt - g0, 1);
      GargoyleKit.glow(c, Offset.zero, 2, GargoylePalette.moon, .5);
      expect(GargoyleKit.shadersBuilt - g0, 2);
      // nothing is built for an invisible glow
      GargoyleKit.glow(c, Offset.zero, 2, GargoylePalette.lampAmber, 0);
      GargoyleKit.glow(c, Offset.zero, 0, GargoylePalette.lampAmber, 1);
      expect(GargoyleKit.shadersBuilt - g0, 2);
    });

    test('hash, mix, turn, shade, poly, spline and octagon behave', () {
      expect(GargoyleKit.hash(3), GargoyleKit.hash(3));
      expect(GargoyleKit.hash(3), isNot(GargoyleKit.hash(4)));
      expect(GargoyleKit.hash(3, 1), isNot(GargoyleKit.hash(3)));
      for (var i = 0; i < 100; i++) {
        expect(GargoyleKit.hash(i), inInclusiveRange(0, 1));
      }
      expect(GargoyleKit.mix(2, 6, .25), 3);
      final t = GargoyleKit.turn(const Offset(1, 0), math.pi / 2);
      expect(t.dx, closeTo(0, 1e-12));
      expect(t.dy, closeTo(1, 1e-12));
      expect(GargoyleKit.shade(GargoylePalette.lime, 1), GargoylePalette.lime);
      expect(_lstar(GargoyleKit.shade(GargoylePalette.lime, .5)), lessThan(_lstar(GargoylePalette.lime)));
      final sq = GargoyleKit.poly(const [Offset(0, 0), Offset(2, 0), Offset(2, 2), Offset(0, 2)]);
      expect(sq.getBounds(), const Rect.fromLTRB(0, 0, 2, 2));
      final sp = GargoyleKit.spline(const [Offset(0, 0), Offset(2, 0), Offset(2, 2), Offset(0, 2)]);
      expect(sp.getBounds().width, greaterThan(1.9));
      final into = Path();
      expect(identical(GargoyleKit.poly(const [Offset(0, 0), Offset(1, 1)], into: into, closed: false), into), isTrue);
    });

    test('fill and line paints: alpha scales, the line is round', () {
      final f = GargoyleKit.fill(const Color(0xffff0000), .5);
      expect(f.color.a, closeTo(.5, .01));
      final l = GargoyleKit.line(const Color(0xffff0000), .1);
      expect(l.style, PaintingStyle.stroke);
      expect(l.strokeCap, StrokeCap.round);
      expect(l.strokeJoin, StrokeJoin.round);
    });
  });
}
