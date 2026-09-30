import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/dragon_kit.dart';

/// The palette is the contract every part paints with: the value ladder
/// (CIE L*) that keeps the face above the horns and the body under any sky,
/// the tone rules (flash, fury, heat, sky light) and the sky-light mapping.

/// CIE L* (0 black .. 100 white) of an opaque colour.
double _lstar(Color c) {
  final y = c.computeLuminance();
  return y > 0.008856 ? 116 * math.pow(y, 1 / 3) - 16 : 903.3 * y;
}

void main() {
  group('the value ladder (bible 4.1)', () {
    void near(Color c, double lstar, [double tol = 1.5]) =>
        expect(_lstar(c), closeTo(lstar, tol), reason: '#${c.toARGB32().toRadixString(16)}');

    test('ink and creases sit at the bottom', () {
      near(DragonPalette.ink, 6);
      near(DragonPalette.inkCool, 10);
      near(DragonPalette.scaleCore, 10);
      near(DragonPalette.scaleDark, 13);
    });

    test('the scale ramp: crease < shade < body < crest < sheen', () {
      near(DragonPalette.scaleDeep, 20);
      near(DragonPalette.scale, 29);
      near(DragonPalette.scaleLit, 45);
      near(DragonPalette.scaleSheen, 66);
      final ramp = [
        DragonPalette.scaleCore,
        DragonPalette.scaleDark,
        DragonPalette.scaleDeep,
        DragonPalette.scale,
        DragonPalette.scaleLit,
        DragonPalette.scaleSheen,
      ].map(_lstar).toList();
      for (var i = 1; i < ramp.length; i++) {
        expect(ramp[i], greaterThan(ramp[i - 1]));
      }
    });

    test('the membrane\'s lit half is >= 50 and >= 15 above the body', () {
      near(DragonPalette.membraneGlow, 75);
      near(DragonPalette.membraneLit, 64);
      near(DragonPalette.membrane, 52);
      near(DragonPalette.membraneDeep, 38);
      near(DragonPalette.membraneDark, 24);
      expect(_lstar(DragonPalette.membrane), greaterThanOrEqualTo(50));
      expect(
        _lstar(DragonPalette.membrane) - _lstar(DragonPalette.scale),
        greaterThanOrEqualTo(15),
      );
      // Bones are darker than the membrane they hold up (back-lit skin).
      expect(_lstar(DragonPalette.scaleDeep), lessThan(_lstar(DragonPalette.membraneDeep)));
    });

    test('bone is mid-toned: the face outranks the horns', () {
      near(DragonPalette.bone, 76);
      near(DragonPalette.boneLit, 90);
      near(DragonPalette.boneDeep, 55);
      near(DragonPalette.boneShade, 36);
      // Nothing bigger than a tooth is above L* 80: the body colour of bone
      // is the 76 one; boneLit is for edges and tips.
      expect(_lstar(DragonPalette.bone), lessThan(80));
    });

    test('fire is the brightest thing, gold reads after the eye', () {
      near(DragonPalette.flameCore, 95, 2.5);
      expect(_lstar(DragonPalette.flameCore), greaterThan(_lstar(DragonPalette.goldLit)));
      expect(_lstar(DragonPalette.flameYellow), greaterThan(_lstar(DragonPalette.gold) + 5));
      near(DragonPalette.goldLit, 93);
      near(DragonPalette.gold, 80);
      near(DragonPalette.goldDeep, 55);
      near(DragonPalette.goldShade, 38);
      // The circlet's gold is never brighter than the iris core.
      expect(_lstar(DragonPalette.gold), lessThan(_lstar(DragonPalette.flameCore)));
    });

    test('oxblood fury plate and the amber belly', () {
      near(DragonPalette.furyPlate, 24);
      near(DragonPalette.furyPlateLit, 44);
      // Round 2 (colour review D5): the belly came down to L* 80 / 68 / 50
      // (it was 88 / 74 / 55) so it no longer out-shouts the face and the
      // heart; the darkest band is unchanged.
      near(DragonPalette.bellyDark, 36);
      near(DragonPalette.bellyDeep, 50);
      near(DragonPalette.belly, 68);
      near(DragonPalette.bellyLit, 80);
      expect(
        _lstar(DragonPalette.bellyLit),
        lessThan(_lstar(DragonPalette.flameYellow)),
      );
    });

    test('the swarm call is cool: blue beats red, never fire', () {
      for (final c in [DragonPalette.call, DragonPalette.callDeep]) {
        expect(c.b, greaterThan(c.r));
        expect(c.b, greaterThan(c.g));
      }
      for (final c in [DragonPalette.flame, DragonPalette.flameGold, DragonPalette.seam]) {
        expect(c.r, greaterThan(c.b));
      }
    });

    test('every colour is opaque and the old names survive', () {
      for (final c in [
        DragonPalette.ink, DragonPalette.scale, DragonPalette.belly,
        DragonPalette.membrane, DragonPalette.bone, DragonPalette.flame,
        DragonPalette.seam, DragonPalette.gold, DragonPalette.ruby,
        DragonPalette.rimSky, DragonPalette.rimFire, DragonPalette.call,
        DragonPalette.smoke, DragonPalette.ash, DragonPalette.white,
      ]) {
        expect(c.a, 1);
      }
    });
  });

  group('DragonTone', () {
    test('a hit goes near-white, lights a little further than darks', () {
      const tone = DragonTone(flash: .55);
      // How far (0..1) each colour was pulled toward the white-hot cream it
      // bleaches to (round 2: it used to stop at a lilac-grey, L* 51).
      double pulled(Color c) {
        final r = tone.lit(c);
        final to = DragonPalette.flameCore;
        return (r.g - c.g) / (to.g - c.g);
      }

      expect(pulled(DragonPalette.scale), closeTo(.55 * 1.8 * (.8 + .2 * math.sqrt(DragonPalette.scale.computeLuminance())), 1e-2));
      expect(pulled(DragonPalette.bone), greaterThan(pulled(DragonPalette.scale)));
      expect(pulled(DragonPalette.scale), greaterThan(pulled(DragonPalette.scaleCore)));
      // The plum body at the peak is bone-white, on any sky.
      expect(_lstar(tone.lit(DragonPalette.scale)), greaterThan(80));
      // Darks still read darker than lights after the flash, and the weight
      // is clamped so the form never washes out to the target.
      expect(
        _lstar(tone.lit(DragonPalette.scaleCore)),
        lessThan(_lstar(tone.lit(DragonPalette.scaleLit))),
      );
      for (final c in [DragonPalette.scaleCore, DragonPalette.bone, DragonPalette.flameCore]) {
        expect(tone.lit(c).a, 1);
      }
      const full = DragonTone(flash: 1);
      final w = full.lit(DragonPalette.scaleCore);
      // (clamp .95: 5% of the plate's own colour always survives)
      expect((w.r - DragonPalette.flameCore.r).abs(), greaterThan(.001));
      // No flash, no change.
      expect(const DragonTone().lit(DragonPalette.bone), DragonPalette.bone);
    });

    test('fury turns the plates oxblood iron, a visible change of the body', () {
      const calm = DragonTone(), fury = DragonTone(fury: 1);
      final plum = calm.plate(DragonPalette.scale);
      final iron = fury.plate(DragonPalette.scale);
      // Redder: red over blue by a margin it did not have (plum leans blue).
      expect(plum.b, greaterThan(plum.r));
      expect(iron.r, greaterThan(iron.b + .1));
      expect(iron.r, greaterThan(plum.r + .1));
      // The lit plates go to lit iron, the deep ones to oxblood, and a lit
      // plate is still lighter than a dark one.
      expect(_lstar(fury.plate(DragonPalette.scaleLit)), greaterThan(_lstar(fury.plate(DragonPalette.scaleDark))));
      // Even the darkest crease is oxblood, no longer aubergine-black.
      final crease = fury.plate(DragonPalette.scaleCore);
      expect(crease.r, greaterThan(crease.b));
      expect(calm.plate(DragonPalette.scale), DragonPalette.scale);
      expect(fury.burn(DragonPalette.membrane, DragonPalette.flame), DragonPalette.flame);
      // It builds with the blend, not in a step.
      var prev = -1.0;
      for (var f = 0.0; f <= 1.0; f += .1) {
        final r = DragonTone(fury: f).plate(DragonPalette.scale).r;
        expect(r, greaterThanOrEqualTo(prev));
        prev = r;
      }
    });

    test('dusk and night deepen the body toward the crease, saturation kept', () {
      const night = DragonTone(dark: 1), dusk = DragonTone(dark: .41);
      final plum = DragonPalette.scale;
      // A bright sky (dark 0) leaves the plum alone; the darkness reaches the
      // parts in thirds, so a plate deepens by .4 at the first third (Paris,
      // Mexico) and .62 from the second (New York, cyberpunk).
      expect(const DragonTone().plate(plum), plum);
      expect(DragonTone(dark: 1 / 3).depth, closeTo(.4, 1e-9));
      expect(DragonTone(dark: 2 / 3).depth, closeTo(.62, 1e-9));
      expect(DragonTone(dark: 1).depth, closeTo(.62, 1e-9));
      // Night: the plum drops from L* 29 to about 17 (the crease colour's
      // pull is capped at .62), and a dusk is in between.
      final n = _lstar(night.plate(plum));
      final d = _lstar(dusk.plate(plum));
      expect(n, closeTo(17, 2));
      expect(d, inExclusiveRange(n, _lstar(plum)));
      // A darker VALUE, not a greyer colour: the saturation does not fall.
      double sat(Color c) {
        final mx = math.max(c.r, math.max(c.g, c.b)), mn = math.min(c.r, math.min(c.g, c.b));
        return mx == 0 ? 0 : (mx - mn) / mx;
      }

      expect(sat(night.plate(plum)), greaterThanOrEqualTo(sat(plum) - .03));
      expect(sat(dusk.plate(plum)), greaterThanOrEqualTo(sat(plum) - .03));
      // It deepens monotonically with the darkness.
      var prev = 99.0;
      for (var k = 0.0; k <= 1.0; k += .05) {
        final l = _lstar(DragonTone(dark: k).plate(plum));
        expect(l, lessThanOrEqualTo(prev + 1e-9));
        prev = l;
      }
    });

    test('glow, seam colour, rims respond to heat, fury and darkness', () {
      const calm = DragonTone(), hot = DragonTone(heat: 1), fury = DragonTone(fury: 1);
      // The seams glow at rest (round 2: .5, was .35, a brown crack).
      expect(calm.glow, closeTo(.5, 1e-12));
      expect(hot.glow, greaterThan(calm.glow));
      expect(fury.glow, 1);
      expect(hot.seam, isNot(calm.seam));
      // A resting seam is already lighter than the base seam colour.
      expect(_lstar(calm.seam), greaterThan(_lstar(DragonPalette.seam)));
      expect(_lstar(hot.seam), greaterThan(_lstar(calm.seam)));
      // The sky rim is stronger at night and weaker in fury; the fire rim
      // grows with the glow.
      expect(const DragonTone(dark: 1).skyRim, greaterThan(calm.skyRim));
      expect(fury.skyRim, lessThan(calm.skyRim));
      expect(hot.fireRim, greaterThan(calm.fireRim));
      for (final t in [calm, hot, fury, const DragonTone(dark: 1, flash: .5)]) {
        expect(t.glow, inInclusiveRange(0, 1));
        expect(t.skyRim, inInclusiveRange(0, 1));
        expect(t.fireRim, inInclusiveRange(0, 1));
      }
    });

    test('key quantises to 1/8 steps so caches stay small', () {
      expect(const DragonTone(fury: .51).key, const DragonTone(fury: .52).key);
      expect(const DragonTone(fury: .1).key, isNot(const DragonTone(fury: .9).key));
      final keys = {
        for (var i = 0; i <= 100; i++) DragonTone(fury: i / 100, heat: i / 100).key,
      };
      expect(keys.length, lessThanOrEqualTo(12));
    });
  });

  group('DragonSkyLight', () {
    test('dark runs 0 (bright) .. 1 (night) and tints the rim by the haze', () {
      const day = Color(0xff9fd8f0), horizon = Color(0xffe9f5df);
      const night = Color(0xff0a0c1c), nightHorizon = Color(0xff1a1f3c);
      final bright = DragonSkyLight.fromSky(top: day, horizon: horizon, haze: horizon);
      final dark = DragonSkyLight.fromSky(
        top: night,
        horizon: nightHorizon,
        haze: const Color(0xff3a4270),
      );
      expect(bright.dark, 0);
      expect(dark.dark, closeTo(1, .05));
      expect(dark.sky, isNot(bright.sky));
      expect(dark.sky, Color.lerp(const Color(0xff3a4270), DragonPalette.rimSky, .5));
      // A mid dusk is in between.
      final dusk = DragonSkyLight.fromSky(
        top: const Color(0xff485584),
        horizon: const Color(0xffadb6da),
        haze: const Color(0xffadb6da),
      );
      expect(dusk.dark, inExclusiveRange(0, 1));
      expect(DragonSkyLight.neutral.dark, 0);
    });
  });

  group('helpers', () {
    test('turn/heading/unit/mix/bezier behave', () {
      final r = DragonKit.turn(const Offset(1, 0), math.pi / 2);
      expect(r.dx, closeTo(0, 1e-12));
      expect(r.dy, closeTo(1, 1e-12));
      expect(DragonKit.heading(0), const Offset(1, 0));
      expect(DragonKit.unit(Offset.zero), Offset.zero);
      expect(DragonKit.unit(const Offset(3, 4)).distance, closeTo(1, 1e-12));
      expect(DragonKit.mix(2, 4, .25), 2.5);
      const a = Offset(0, 0), b = Offset(1, 2), c = Offset(3, 2), d = Offset(4, 0);
      expect(DragonKit.bezier(a, b, c, d, 0), a);
      expect(DragonKit.bezier(a, b, c, d, 1), d);
      expect(DragonKit.hash(3, 1), inInclusiveRange(0, 1));
      expect(DragonKit.hash(3, 1), DragonKit.hash(3, 1));
      expect(DragonKit.hash(3, 1), isNot(DragonKit.hash(4, 1)));
    });

    test('tube and spline close their outline', () {
      final tube = DragonKit.tube(
        const [Offset(0, 0), Offset(1, 0), Offset(2, 0)],
        const [1, .8, .4],
      );
      final b = tube.getBounds();
      expect(b.width, greaterThan(1.9));
      expect(b.height, closeTo(1, .35));
    });

    test('cached paints are kept, least-recently-used, and never cleared', () {
      var built = 0;
      Paint make() {
        built++;
        return Paint();
      }

      final p1 = DragonKit.cached(('kit-test', 1), make);
      final p2 = DragonKit.cached(('kit-test', 1), make);
      expect(identical(p1, p2), isTrue);
      expect(built, 1);
      // Fill it well past its capacity while one key is used all along: the
      // oldest entries go one at a time, the used one stays, and the whole set
      // is never dropped at once (that rebuilt every paint in one frame).
      final keep = DragonKit.cached(('kit-keep', 0), make);
      for (var i = 0; i < DragonKit.cacheCapacity * 2; i++) {
        DragonKit.cached(('kit-test-many', i), make);
        expect(DragonKit.cacheSize, lessThanOrEqualTo(DragonKit.cacheCapacity));
        expect(identical(DragonKit.cached(('kit-keep', 0), make), keep), isTrue);
      }
      expect(DragonKit.cacheSize, DragonKit.cacheCapacity);
      // A key from the last hundred is still there (one build to check it).
      final before = built;
      DragonKit.cached(('kit-test-many', DragonKit.cacheCapacity * 2 - 5), make);
      expect(built, before);
      // The very first ones are gone.
      DragonKit.cached(('kit-test-many', 0), make);
      expect(built, before + 1);
    });

    test('shade pulls toward the ink, not to mud', () {
      final far = DragonKit.shade(DragonPalette.membrane, .74);
      expect(_lstar(far), lessThan(_lstar(DragonPalette.membrane)));
      expect(_lstar(far), greaterThan(_lstar(DragonPalette.ink)));
      expect(far.r, greaterThan(far.g)); // still red
    });
  });
}
