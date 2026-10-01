import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/gargoyle_beam_art.dart';
import 'package:push_up_bird/game/gargoyle_encounter_art.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/gargoyle_story_art.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'gargoyle_stage_support.dart';

/// The Searchlight Gargoyle's fix round (G8): his hit flash cannot strobe, the
/// warning dissolves under the beam, his blades do not snap on a re-hit, the
/// letterbox is the dragon's, and his emblem reads at 22 to 29 px.
///
/// The measures are the reviewers' (reports 22 and 20): the share of the screen
/// whose relative luminance rises by .10 or more within a tenth of a second
/// (the photosensitivity test), and the left strip's frame-to-frame difference
/// at the beam's ignition.

double _lin(int v) {
  final c = v / 255;
  return c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
}

Float64List _luminance(Uint8List px) {
  final o = Float64List(px.length ~/ 4);
  for (var i = 0; i < o.length; i++) {
    o[i] = .2126 * _lin(px[i * 4]) + .7152 * _lin(px[i * 4 + 1]) + .0722 * _lin(px[i * 4 + 2]);
  }
  return o;
}

double _lumOf(ui.Color c) => .2126 * _lin((c.r * 255).round()) + .7152 * _lin((c.g * 255).round()) + .0722 * _lin((c.b * 255).round());

/// WCAG contrast ratio of two colours.
double _contrast(ui.Color a, ui.Color b) {
  final x = _lumOf(a), y = _lumOf(b);
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

/// The boss at [t] seconds into combat with hits landing [gap] seconds apart
/// from 7.0 s (the vent): the last hit and the one before it as the rules
/// latch them (`previousHitAt` unless [latch] is false: the rules before the
/// fix).
SkyBoss _rapid(double t, double gap, {bool latch = true, int count = 8}) {
  final b = bossAt(t);
  final hits = [for (var k = 0; k < count; k++) 7.0 + k * gap].where((h) => h <= t).toList();
  if (hits.isNotEmpty) {
    b.lastHitAt = b.age - (t - hits.last);
    b.lastDamage = 10;
    if (latch && hits.length > 1) b.previousHitAt = b.age - (t - hits[hits.length - 2]);
  }
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('the hit flash cannot strobe', () {
    /// The worst share of the screen that brightens by >= .10 of relative
    /// luminance within .1 s, over rapid fire, rendered by the real encounter
    /// over a flat dark sky (so only his own light moves).
    Future<({double worst, int over5, int events})> measure(double gap, {required bool reduced, double width = 640}) async {
      final frames = <Float64List>[];
      const fps = 30.0;
      for (var t = 6.8; t < 7.0 + 8 * gap + .3; t += 1 / fps) {
        final b = _rapid(t, gap);
        frames.add(_luminance(await raster((c) => encounter(c, b, width, reduced: reduced), width)));
      }
      final n = frames.first.length;
      var worst = 0.0, over5 = 0, events = 0;
      var inside = false;
      for (var i = 3; i < frames.length; i++) {
        var cnt = 0;
        for (var p = 0; p < n; p++) {
          if (frames[i][p] - frames[i - 3][p] >= .10) cnt++;
        }
        final a = cnt / n;
        worst = math.max(worst, a);
        if (a > .05) over5++;
        if (a >= .10 && !inside) events++;
        inside = a >= .10;
      }
      return (worst: worst, over5: over5, events: events);
    }

    testWidgets('rapid fire (3.3 hits a second and slower): never 10% of the screen at a time, never a large-area flash', (tester) async {
      await tester.runAsync(() async {
        for (final reduced in const [false, true]) {
          for (final gap in const [.28, .3, .5]) {
            final r = await measure(gap, reduced: reduced);
            // ignore: avoid_print
            print('hit flash, gap $gap s, reduced $reduced: worst ${(r.worst * 100).toStringAsFixed(1)}% of the screen, ${r.events} large-area flashes');
            expect(r.worst, lessThan(.10), reason: 'gap $gap reduced $reduced: the reviewers measured 21 to 23% before');
            expect(r.events, 0, reason: 'no flash of 10% or more of the screen, so none of large area at all (the limit is 3 a second)');
          }
        }
      });
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('a re-hit flashes by how soon it comes: 1 - e^(-gap / .45) of the peak; the peak is .12 (.06 under Reduced Motion)', () {
      double peak(double gap, {bool rm = false}) {
        var best = 0.0;
        for (var a = 0.0; a < .3; a += .005) {
          final b = bossAt(8.0)..lastHitAt = 8.0 + 4.6 - a;
          b.previousHitAt = b.lastHitAt - gap;
          best = math.max(best, GargoylePose(b, motion(b, reduced: rm)).flash);
        }
        return best;
      }

      double first({bool rm = false}) {
        var best = 0.0;
        for (var a = 0.0; a < .3; a += .005) {
          final b = bossAt(8.0)..lastHitAt = 8.0 + 4.6 - a;
          best = math.max(best, GargoylePose(b, motion(b, reduced: rm)).flash);
        }
        return best;
      }

      expect(first(), closeTo(GargoyleTimeline.hitFlashPeak, .005));
      expect(first(rm: true), closeTo(GargoyleTimeline.hitFlashPeakReduced, .005));
      // The flash of the hit BEFORE is still draining when a quick re-hit lands: it carries on rather than restarting.
      for (final gap in const [.1, .28, .5, 1.0, 3.0]) {
        final k = 1 - math.exp(-gap / GargoyleTimeline.hitFlashRecover);
        final p = peak(gap);
        final expected = math.max(GargoyleTimeline.hitFlashPeak * k, 0.0);
        expect(p, lessThanOrEqualTo(GargoyleTimeline.hitFlashPeak + 1e-9), reason: 'gap $gap never above the peak');
        expect(p, greaterThanOrEqualTo(expected - .005), reason: 'gap $gap: its share');
      }
      expect(peak(.3) * 1.0, lessThanOrEqualTo(GargoyleTimeline.hitFlashPeak));
      // Three hits a second: every flash after the first is under .55 of the peak (it was the full .55 before the fix).
      var worstAfter = 0.0;
      for (var k = 1; k < 8; k++) {
        var best = 0.0;
        for (var a = 0.0; a < .3; a += .005) {
          final t = 7.0 + k * .3 + a;
          best = math.max(best, GargoylePose(_rapid(t, .3), motion(_rapid(t, .3))).flash);
        }
        worstAfter = math.max(worstAfter, best);
      }
      expect(worstAfter, lessThan(GargoyleTimeline.hitFlashPeak * .85), reason: 'the second hit at .3 s and every later one');
    });

    testWidgets('the hit still reads: his lamp bursts, he recoils and winces, and the frame differs from the calm one (with or without Reduced Motion)', (tester) async {
      await tester.runAsync(() async {
        for (final reduced in const [false, true]) {
          final calm = bossAt(7.05);
          final hit = _rapid(7.05, .3, count: 1)..lastHitAt = 7.05 + 4.6 - .04;
          final a = await raster((c) => encounter(c, calm, 640, reduced: reduced), 640);
          final b = await raster((c) => encounter(c, hit, 640, reduced: reduced), 640);
          expect(changed(a, b), greaterThan(reduced ? 1500 : 4000), reason: 'reduced $reduced: a hit is visible');
          // The lamp's own burst: the brightest thing on screen at the hit (the flash lives at the lamp, not on the whole statue).
          final la = _luminance(a), lb = _luminance(b);
          var rise = 0.0;
          final lampX = (calm.x * 360).round(), lampY = 180;
          for (var y = lampY - 30; y < lampY + 30; y++) {
            for (var x = lampX - 30; x < lampX + 30; x++) {
              rise = math.max(rise, lb[y * 640 + x] - la[y * 640 + x]);
            }
          }
          expect(rise, greaterThan(.3), reason: 'reduced $reduced: the lamp flares white-hot');
        }
      });
    });
  });

  group('the warning dissolves under the beam', () {
    testWidgets('on the beam\'s first frame the screen shows MORE danger, not less, and nothing pops (the strip diff falls from 23-25 to under 12)', (tester) async {
      await tester.runAsync(() async {
        const w = 640.0;
        final base = await raster((c) {}, w);
        for (final reduced in const [false, true]) {
          Uint8List? last;
          final energy = <double>[];
          var worstDiff = 0.0;
          for (var i = 0; i < 24; i++) {
            final t = 3.42 + i / 60;
            final b = bossAt(t, width: w);
            final px = await raster((c) => encounter(c, b, w, reduced: reduced), w);
            var e = 0.0, d = 0.0, n = 0;
            for (var y = 0; y < 360; y++) {
              for (var x = 0; x < 300; x++) {
                final p = (y * 640 + x) * 4;
                e += (px[p] - base[p]).abs() + (px[p + 1] - base[p + 1]).abs() + (px[p + 2] - base[p + 2]).abs();
                if (last != null) d += (px[p] - last[p]).abs() + (px[p + 1] - last[p + 1]).abs() + (px[p + 2] - last[p + 2]).abs();
                n++;
              }
            }
            energy.add(e / n / 3);
            if (last != null) worstDiff = math.max(worstDiff, d / n / 3);
            last = px;
          }
          // Frames 0..4 are the warning (3.42 to 3.49), frame 5 is 3.503 (the ignition).
          final before = energy[4], ignite = energy[5];
          // ignore: avoid_print
          print('hand-off reduced $reduced: danger ${before.toStringAsFixed(1)} -> ${ignite.toStringAsFixed(1)} at the ignition, worst strip diff ${worstDiff.toStringAsFixed(1)}');
          expect(ignite, greaterThanOrEqualTo(before * .98), reason: 'reduced $reduced: the beam\'s first frame shows no less danger than the warning\'s last');
          expect(worstDiff, lessThan(12), reason: 'reduced $reduced: the fan used to vanish in one frame (23 to 25)');
          // And the fan then thins smoothly: no frame loses more than a quarter of the danger before it.
          for (var i = 6; i < 14; i++) {
            expect(energy[i], greaterThanOrEqualTo(energy[i - 1] * .75), reason: 'reduced $reduced: frame $i (it fell to .16 of the frame before at the ignition)');
          }
        }
      });
    });

    test('the pose: the beam starts at .7 and reaches full in .10 s; the warning\'s tail is 1 at the ignition and 0 by .15 s, never outside it', () {
      GargoylePose at(double x, {bool rm = false}) => GargoylePose(bossAt(x), motion(bossAt(x), reduced: rm));
      expect(GargoyleBeamLook.igniteFloor, .7);
      expect(GargoyleBeamLook.igniteSeconds, .10);
      expect(at(3.4).warnRelease, 0);
      expect(at(3.4999).warning, greaterThan(.99));
      expect(at(3.5).warning, 0, reason: 'the rules\' warning ends at the sweep');
      expect(at(3.5).warnRelease, closeTo(1, 1e-9));
      expect(at(3.5).beams.first.intensity, closeTo(.7, 1e-9));
      expect(at(3.5 + .075).warnRelease, closeTo(.5, .05));
      expect(at(3.5 + GargoyleBeamLook.warnReleaseSeconds).warnRelease, 0);
      expect(at(4.5).warnRelease, 0);
      expect(at(3.5, rm: true).warnRelease, closeTo(1, 1e-9), reason: 'it dissolves under Reduced Motion too: the safety cue is a state');
      // A beam is on while the fan is still there: the danger never drops.
      for (var x = 3.5; x < 3.65; x += .01) {
        final p = at(x);
        expect(p.beams, isNotEmpty);
        expect(p.warnRelease + p.beams.first.intensity, greaterThanOrEqualTo(1.0 + .0), reason: 'x $x');
      }
    });

    test('the dissolving frame draws the warning (veil, fan, tag) under the beam: more ops than a beam alone, within the 60-op frame', () {
      int ops(double x) {
        final b = bossAt(x);
        final rec = Rec();
        GargoyleBeamArt.under(rec, const ui.Size(640, 360), GargoylePose(b, motion(b)), ui.Offset(b.x * 360, 180));
        return rec.draws;
      }

      expect(ops(3.5), greaterThan(ops(4.5) + 8), reason: 'the fan is still there at the ignition');
      expect(ops(3.5 + .05), greaterThan(ops(4.5)));
      expect(ops(3.5 + .16), ops(4.5), reason: 'gone by .15 s');
      for (var x = 3.5; x < 3.66; x += .01) {
        expect(ops(x), lessThanOrEqualTo(60), reason: 'x $x');
      }
    });
  });

  group('a re-hit does not snap his blades', () {
    double worstJump(double gap, {required bool latch}) {
      var worst = 0.0;
      List<double>? last;
      for (var t = 6.9; t < 8.4; t += 1 / 120) {
        final b = _rapid(t, gap, latch: latch);
        final p = GargoylePose(b, motion(b));
        final now = [...p.nearFan.strokes, ...p.farFan.strokes];
        if (last != null) {
          for (var i = 0; i < now.length; i++) {
            worst = math.max(worst, (now[i] - last[i]).abs());
          }
        }
        last = now;
      }
      return worst;
    }

    test('hits .28 s (the weapon\'s cooldown) to .5 s apart: no blade of either fan moves more than .12 of its 2.0 stroke in a 120 Hz tick (without the latch: more than .3)', () {
      // The latch holds the hit before the last; a blade lags up to .27 s (the far fan's .1 s plus
      // the last blade's .17), so it covers every gap the cooldown allows (.28 s and up).
      for (final gap in const [.28, .3, .4, .5]) {
        expect(worstJump(gap, latch: true), lessThan(.12), reason: 'gap $gap');
        expect(worstJump(gap, latch: false), greaterThan(.3), reason: 'gap $gap: the test would pass without the fix');
      }
    });

    test('the rules latch it: the last hit and the one before (render only; the first hit leaves it at negative infinity)', () {
      final boss = SkyBoss(number: 6, x: 1, kind: BossKind.searchlightGargoyle, cinematic: true);
      expect(boss.previousHitAt, double.negativeInfinity);
      boss.age = 20;
      boss.takeDamage(10);
      expect(boss.lastHitAt, 20);
      expect(boss.previousHitAt, double.negativeInfinity);
      boss.age = 20.3;
      boss.takeDamage(10);
      expect(boss.lastHitAt, 20.3);
      expect(boss.previousHitAt, 20);
      boss.age = 20.5;
      expect(boss.takeDamage(0 + 1), 1);
      expect(boss.previousHitAt, 20.3);
    });

    test('a broken latch is harmless', () {
      for (final v in [double.nan, double.infinity, 1e300]) {
        final b = bossAt(7.1, hitAgo: .05)..previousHitAt = v;
        final p = GargoylePose(b, motion(b));
        for (final x in p.channels.values) {
          expect(x.isFinite, isTrue);
        }
      }
    });
  });

  group('the letterbox is the dragon\'s', () {
    test('open to 30% for the roar (2.5 to 3.6 s), out 0.2 s earlier than the shared one; the numbers King Coo\'s rule must match', () {
      double bar(double age) => GargoyleEncounterArt.focus(motion(bossAt(age - 4.6)));
      // base * (1 - .7 * open): base = ease(0..0.65) * (1 - ease(3.8..4.4)), open = ease(2.5..2.75) * (1 - ease(3.2..3.6)).
      expect(bar(2.0), closeTo(1, 1e-9));
      expect(bar(2.75), closeTo(.3, 1e-9));
      expect(bar(3.0), closeTo(.3, 1e-9));
      expect(bar(3.2), closeTo(.3, 1e-9));
      expect(bar(3.7), closeTo(1, 1e-9));
      expect(bar(4.1), lessThan(.6));
      expect(bar(4.4), closeTo(0, 1e-9));
      expect(motion(bossAt(4.1 - 4.6)).focus, greaterThan(bar(4.1) + .3), reason: 'the shared bars are still nearly full at 4.1 s (.93), his are half gone');
    });
  });

  group('his emblem reads at 22 to 29 px', () {
    final field = GargoyleStoryArt.stampField;

    /// The emblem in a [w] x [h] box on [ground] at [k]x, as RGBA, fitted the way
    /// `CampaignHeadwear.paint` fits it (its reach scaled to the box); [lensOnly]
    /// is the flag the UI passes under `lensOnlyBelow` px.
    Future<Uint8List> shot(double w, double h, ui.Color ground, {double k = 8, bool lensOnly = false, bool viaKeepsake = true}) async {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.scale(k);
      c.drawRect(ui.Rect.fromLTWH(0, 0, w + 8, h + 8), ui.Paint()..color = ground);
      if (viaKeepsake && !lensOnly) {
        CampaignHeadwear.paint(c, ui.Rect.fromLTWH(4, 4, w, h), BossKind.searchlightGargoyle);
      } else {
        final reach = GargoyleStoryArt.visorReach;
        final scale = math.min(w / reach.width, h / reach.height);
        c.translate(4 + w / 2, 4 + h / 2);
        c.scale(scale);
        c.translate(-reach.center.dx, -reach.center.dy);
        GargoyleStoryArt.visor(c, const GargoyleTone(), lensOnly);
      }
      final pic = rec.endRecording();
      final image = await pic.toImage(((w + 8) * k).round(), ((h + 8) * k).round());
      final data = await rgba(image);
      image.dispose();
      pic.dispose();
      return data;
    }

    ({double brass, double amber, double ink, double light, double lensH}) measureEmblem(Uint8List px, double w, double h, ui.Color ground, double k) {
      final pw = ((w + 8) * k).round(), ph = ((h + 8) * k).round();
      var brass = 0, amber = 0, ink = 0, light = 0, minY = ph, maxY = 0;
      for (var y = 0; y < ph; y++) {
        for (var x = 0; x < pw; x++) {
          final i = (y * pw + x) * 4;
          final r = px[i], g = px[i + 1], b = px[i + 2];
          if (r > 200 && g > 150 && g < 215 && b < 120) brass++;
          if (r > 240 && g > 160 && b < 100) amber++;
          if (r < 40 && g < 40 && b < 70) ink++;
          if (r > 205 && g > 205 && b > 190) light++;
          // The brass-or-amber of the lens: its vertical extent.
          if (r > 200 && g > 150 && b < 140) {
            minY = math.min(minY, y);
            maxY = math.max(maxY, y);
          }
        }
      }
      final px2 = k * k;
      return (brass: brass / px2, amber: amber / px2, ink: ink / px2, light: light / px2, lensH: maxY >= minY ? (maxY - minY + 1) / k : 0);
    }

    test('the field: an indigo (L about 24, no amber) the brass lens, the amber glass and the pale hood stand out on', () {
      expect(field, const ui.Color(0xff2f3a6b));
      expect(_contrast(GargoylePalette.brass, field), greaterThan(4.5));
      expect(_contrast(GargoylePalette.lampAmber, field), greaterThan(4.5));
      expect(_contrast(const ui.Color(0xffe6e6da), field), greaterThan(6));
      expect(_lumOf(field), lessThan(.06));
      // The old placeholder: a steel visor on `#6f86a8` was a grey wedge.
      expect(_contrast(GargoylePalette.steelMid, const ui.Color(0xff6f86a8)), lessThan(2.2));
      // ... and King Coo owns the brass field.
      expect(field, isNot(const ui.Color(0xffe0a93a)));
    });

    testWidgets('at 22 x 17, 26 x 20 and 29 x 22 the emblem is a big brass lens with a lit glass and an ink ring under a pale hood', (tester) async {
      await tester.runAsync(() async {
        for (final (w, h) in const [(22.0, 17.0), (26.0, 20.0), (29.0, 22.0)]) {
          final m = measureEmblem(await shot(w, h, field), w, h, field, 8);
          // ignore: avoid_print
          print('emblem $w x $h: brass ${m.brass.toStringAsFixed(0)} amber ${m.amber.toStringAsFixed(0)} ink ${m.ink.toStringAsFixed(0)} hood ${m.light.toStringAsFixed(0)} px, lens ${m.lensH.toStringAsFixed(1)} px tall');
          expect(m.lensH, greaterThan(h * .52), reason: '$w x $h: the lens is more than half the box high');
          expect(m.brass, greaterThan(w * h * .06), reason: '$w x $h: brass rim');
          expect(m.amber, greaterThan(w * h * .09), reason: '$w x $h: lit glass');
          expect(m.ink, greaterThan(w * h * .05), reason: '$w x $h: ink');
          expect(m.light, greaterThan(w * h * .05), reason: '$w x $h: the pale hood and the glass\'s glint');
        }
      });
    });

    testWidgets('with lensOnly (the flag the UI passes under 34 px) the lens fills the box: brass on indigo, an ink ring, a lit glass', (tester) async {
      await tester.runAsync(() async {
        for (final (w, h) in const [(22.0, 17.0), (26.0, 20.0), (29.0, 22.0)]) {
          final m = measureEmblem(await shot(w, h, field, lensOnly: true), w, h, field, 8);
          expect(m.lensH, greaterThan(h * .8), reason: '$w x $h: the lens fills the box');
          expect(m.lensH, lessThan(h + .6));
          expect(m.brass, greaterThan(w * h * .12), reason: '$w x $h');
          expect(m.amber, greaterThan(w * h * .15), reason: '$w x $h');
          expect(m.ink, greaterThan(w * h * .08), reason: '$w x $h');
        }
        expect(GargoyleStoryArt.lensOnlyBelow, 34);
      });
    });

    testWidgets('large (48 px and up) the hooded lens: brass, amber, ink AND the pale hood; fitted into its box', (tester) async {
      await tester.runAsync(() async {
        for (final (w, h) in const [(48.0, 36.0), (96.0, 72.0), (200.0, 160.0)]) {
          final px = await shot(w, h, field, k: 3);
          final m = measureEmblem(px, w, h, field, 3);
          expect(m.brass, greaterThan(w * h * .07), reason: '$w x $h brass lens');
          expect(m.light, greaterThan(w * h * .05), reason: '$w x $h pale hood');
          var outside = 0;
          final pw = ((w + 8) * 3).round(), ph = ((h + 8) * 3).round();
          for (var y = 0; y < ph; y++) {
            for (var x = 0; x < pw; x++) {
              final inside = x >= 4 * 3 && x < (4 + w) * 3 && y >= 4 * 3 && y < (4 + h) * 3;
              final i = (y * pw + x) * 4;
              if (!inside && (px[i] != 0x2f || px[i + 1] != 0x3a)) outside++;
            }
          }
          expect(outside, lessThan(w * h * 9 * .002), reason: '$w x $h stays in its box');
        }
      });
    });

    testWidgets('on the route mark\'s cream plate (22 x 17) the ink ring and the lens still read', (tester) async {
      await tester.runAsync(() async {
        const plate = ui.Color(0xfffff2d6);
        for (final lensOnly in const [false, true]) {
          final m = measureEmblem(await shot(22, 17, plate, lensOnly: lensOnly), 22, 17, plate, 8);
          expect(m.ink, greaterThan(22 * 17 * .05), reason: 'lensOnly $lensOnly: an ink ring on cream');
          expect(m.amber, greaterThan(22 * 17 * .08), reason: 'lensOnly $lensOnly: the glass');
        }
        expect(_contrast(SkyColors.ink, plate), greaterThan(10));
      });
    });

    test('a recording canvas never throws', () {
      expect(() => GargoyleStoryArt.visor(Rec()), returnsNormally);
      expect(() => GargoyleStoryArt.visor(Rec(), const GargoyleTone(), true), returnsNormally);
      expect(GargoyleStoryArt.visorReach.shortestSide, greaterThan(1));
    });
  });
}
