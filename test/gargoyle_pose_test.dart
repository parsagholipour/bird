import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'proof/gargoyle_stage.dart';

/// `GargoylePose`: every channel is a pure function of the boss clock and its
/// latches, continuous at every beat, and Reduced Motion settles the motion
/// channels into one still frame while the state channels keep showing.
GargoylePose _p(double combat, {bool rm = false, double? gap, double look = 0, SkyBoss Function(SkyBoss)? edit, bool fury = false, BeamSide side = BeamSide.high, bool slit = false, double? hitAgo, double? enragedAgo, double? glanceAgo, double? deadFor}) {
  final b = gBoss(combat, fury: fury, side: side, slit: slit, hitAgo: hitAgo, enragedAgo: enragedAgo, glanceAgo: glanceAgo, deadFor: deadFor);
  edit?.call(b);
  return GargoylePose(b, BossMotion(b, reducedMotion: rm), lookY: look, gap: gap ?? GargoylePose.defaultGap);
}

extension on GargoylePose {
  double operator [](String k) => channels[k]!;
}

double _maxJump(GargoylePose a, GargoylePose b, {Set<String> except = const {}}) {
  var worst = 0.0;
  final x = a.channels, y = b.channels;
  for (final k in x.keys) {
    if (except.contains(k)) continue;
    worst = math.max(worst, (x[k]! - y[k]!).abs());
  }
  return worst;
}

String _worstKey(GargoylePose a, GargoylePose b, {Set<String> except = const {}}) {
  var worst = 0.0;
  var key = '';
  final x = a.channels, y = b.channels;
  for (final k in x.keys) {
    if (except.contains(k)) continue;
    final d = (x[k]! - y[k]!).abs();
    if (d > worst) {
      worst = d;
      key = k;
    }
  }
  return '$key ${worst.toStringAsFixed(3)}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('purity', () {
    test('identical inputs give identical channels, whatever was built before', () {
      final a = _p(4.3).channels;
      // Build a lot of other poses in between.
      for (var i = 0; i < 200; i++) {
        _p(i * .37, fury: i.isEven, slit: i % 3 == 0, hitAgo: i % 5 == 0 ? .1 : null);
      }
      expect(_p(4.3).channels, a);
    });

    test('a pose does not depend on the wall clock or a frame counter', () {
      final a = _p(5.5, fury: true, slit: true).channels;
      final start = DateTime.now();
      while (DateTime.now().difference(start).inMilliseconds < 5) {}
      expect(_p(5.5, fury: true, slit: true).channels, a);
    });

    test('every channel is finite and bounded over whole cycles, every look', () {
      for (final rm in [false, true]) {
        for (final (fury, slit, side) in const [
          (false, false, BeamSide.high),
          (false, false, BeamSide.low),
          (true, false, BeamSide.high),
          (true, false, BeamSide.low),
          (true, true, BeamSide.high),
        ]) {
          for (var k = 0; k < 18 * 20; k++) {
            final t = -4.6 + k * .05;
            final p = _p(t, rm: rm, fury: fury, slit: slit, side: side, hitAgo: k % 40 == 0 ? .05 : null);
            final why = '${rm ? 'RM ' : ''}t$t fury $fury slit $slit $side';
            for (final e in p.channels.entries) {
              expect(e.value.isFinite, isTrue, reason: '$why ${e.key}');
            }
            for (final k in const ['lamp', 'flare', 'brow', 'iris', 'gape', 'roar', 'fury', 'furyBlend', 'flash', 'hit', 'wince', 'crack', 'crumble', 'warning', 'steam', 'grip', 'dust', 'shatter', 'glance', 'stone', 'spread', 'visor']) {
              expect(p[k], inInclusiveRange(0, 1), reason: '$why $k');
            }
            expect(p.lean, inInclusiveRange(-.8, .8), reason: why);
            expect(p.pitch, inInclusiveRange(-.22, .5), reason: why);
            expect(p.tail, inInclusiveRange(-1, 1), reason: why);
            for (final s in [...p.nearFan.strokes, ...p.farFan.strokes]) {
              expect(s, inInclusiveRange(-1, 1), reason: why);
            }
            expect(p.shedTau == -1 || (p.shedTau >= 0 && p.shedTau <= .6), isTrue, reason: '$why shedTau ${p.shedTau}');
            expect(p.beams.length, lessThanOrEqualTo(2), reason: why);
          }
        }
      }
    });

    test('NaN and infinite times give finite channels', () {
      for (final mutate in <void Function(SkyBoss)>[
        (b) => b.age = double.nan,
        (b) => b.lastHitAt = double.nan,
        (b) => b.lastHitAt = double.infinity,
        (b) => b.enragedAt = double.nan,
        (b) => b.lastGlanceAt = double.nan,
        (b) => b.defeatedAt = double.nan,
        (b) => b.defeatedAt = double.infinity,
        (b) => b.age = 1e12,
      ]) {
        final b = gBoss(3.0, fury: true);
        mutate(b);
        final p = GargoylePose(b, BossMotion(b, reducedMotion: false), light: const GargoyleSkyLight(dark: double.nan));
        for (final e in p.channels.entries) {
          expect(e.value.isFinite, isTrue, reason: e.key);
        }
        expect(p.tone.dark.isFinite, isTrue);
      }
    });

    test('a NaN look or gap does not poison the pose', () {
      final p = _p(1.0, look: double.nan, gap: double.nan);
      for (final e in p.channels.entries) {
        expect(e.value.isFinite, isTrue, reason: e.key);
      }
    });

    test('finite bosses are used as they are', () {
      final b = gBoss(3.0, hitAgo: .1);
      final p = GargoylePose(b, BossMotion(b, reducedMotion: false));
      expect(p.age, b.age);
      expect(p.defeated, isFalse);
    });

    test('withTone changes the look and nothing else', () {
      final p = _p(4.5);
      final q = p.withTone(const GargoyleTone(flash: .5, fury: 1, stone: .5));
      expect(q.channels, p.channels);
      expect(q.tone.flash, .5);
      expect(q.tone.stone, .5);
      expect(q.beams, p.beams);
    });

    test('custom poses default to the calm idle', () {
      final p = GargoylePose.custom();
      final idle = GargoylePose.still;
      for (final k in ['lamp', 'flare', 'brow', 'iris', 'gape', 'fury', 'crack', 'lean', 'pitch', 'wing', 'spread']) {
        expect(p[k], idle[k], reason: k);
      }
    });
  });

  group('the cycle (Reduced Motion shows the pure keys)', () {
    test('lamp, warning and beam come from the rules', () {
      for (var k = 0; k < 18 * 10; k++) {
        final t = k * .1;
        final b = gBoss(t);
        final p = GargoylePose(b, BossMotion(b, reducedMotion: false));
        expect(p.lamp, closeTo(b.lampOpenness, 1e-12), reason: 't$t');
        expect(p.warning, closeTo(b.sweepWarning, 1e-12), reason: 't$t');
        // A beam is drawn for every moment the rules hurt with it (and for .1 s
        // after the vent closes it).
        if (b.beamOn) expect(p.beams, isNotEmpty, reason: 't$t');
        if (!b.beamOn && p.beams.isNotEmpty) {
          expect(b.gargoyleCycle, inInclusiveRange(SearchlightGargoyle.ventAt, SearchlightGargoyle.ventAt + GargoyleBeamLook.fadeSeconds), reason: 't$t');
        }
      }
    });

    test('the drawn band IS the rules\' band (centres and half), zone and slit, calm and fury', () {
      for (final (fury, slit, side) in const [
        (false, false, BeamSide.high),
        (false, false, BeamSide.low),
        (true, false, BeamSide.low),
        (true, true, BeamSide.high),
      ]) {
        for (var x = 3.5; x < 6.4; x += .05) {
          final b = gBoss(x, fury: fury, slit: slit, side: side);
          final p = GargoylePose(b, BossMotion(b, reducedMotion: false));
          expect(p.beams.length, slit ? 2 : 1, reason: 'x$x');
          final rules = b.beamCentres;
          for (var i = 0; i < rules.length; i++) {
            expect(p.beams[i].centre, closeTo(rules[i], 1e-9), reason: 'x$x beam $i');
            expect(p.beams[i].half, b.beamHalf);
            expect(p.beams[i].fury, fury);
          }
          if (slit) {
            expect(p.beams[0].far, isTrue);
            expect(p.beams[1].far, isFalse);
          } else {
            expect(p.beams[0].far, isFalse);
          }
        }
      }
    });

    test('ignition: on from the very first frame, edges at full, body ramping from .7 to full in .10 s', () {
      final at = _p(3.5);
      expect(at.beams, hasLength(1));
      expect(at.beams.first.intensity, closeTo(GargoyleBeamLook.igniteFloor, 1e-9));
      expect(_p(3.5 + .04).beams.first.intensity, inExclusiveRange(GargoyleBeamLook.igniteFloor, 1));
      expect(_p(3.5 + GargoyleBeamLook.igniteSeconds).beams.first.intensity, closeTo(1, 1e-9));
      expect(_p(3.49).beams, isEmpty);
      // The vent fades it .1 s after the rules switch it off.
      expect(_p(6.4 + .05).beams.first.intensity, inExclusiveRange(0, 1));
      expect(_p(6.4 + .11).beams, isEmpty);
      // Reduced Motion: instant.
      expect(_p(3.5, rm: true).beams.first.intensity, 1);
      expect(_p(6.41, rm: true).beams, isEmpty);
    });

    test('the keys: lean, flare, brow, gape, wing and spread at the rules\' edges', () {
      double at(double x, String k) => _p(x, rm: true)[k];
      expect(at(1.0, 'lean'), closeTo(0, 1e-9));
      expect(at(2.5, 'lean'), closeTo(-.45, 1e-9));
      expect(at(3.05, 'lean'), closeTo(-.45, 1e-9));
      expect(at(3.5, 'lean'), closeTo(.7, 1e-9));
      expect(at(6.4, 'lean'), closeTo(.7, 1e-9));
      expect(at(6.75, 'lean'), closeTo(-.6, 1e-9));
      expect(at(8.7, 'lean'), closeTo(-.6, 1e-9));
      expect(at(8.999, 'lean'), closeTo(0, 2e-3));
      expect(at(1.0, 'flare'), closeTo(.3, 1e-9));
      expect(at(3.5, 'flare'), closeTo(1, 1e-9));
      expect(at(5.0, 'flare'), closeTo(1, 1e-9));
      expect(at(6.65, 'flare'), closeTo(.2, 1e-9));
      expect(at(8.7, 'flare'), closeTo(.2, 1e-9));
      expect(at(1.0, 'brow'), closeTo(.3, 1e-9));
      expect(at(2.4, 'brow'), closeTo(1, 1e-9));
      expect(at(6.75, 'brow'), closeTo(.5, 1e-9));
      expect(at(1.0, 'gape'), 0);
      expect(at(6.75, 'gape'), closeTo(.55, 1e-9));
      expect(at(6.4, 'wing'), closeTo(-.2, 1e-9));
      expect(at(6.75, 'wing'), closeTo(-1, 1e-9));
      expect(at(6.75, 'spread'), closeTo(.6, 1e-9));
    });

    test('eyes climb from .3 to 1 through the warning and stay there for the sweep', () {
      var last = .3;
      for (var x = 2.0; x <= 3.5; x += .05) {
        final f = _p(x, rm: true).flare;
        expect(f, greaterThanOrEqualTo(last - 1e-9), reason: 'x$x');
        last = f;
      }
    });

    test('the head follows the beam: pitch is .40 x its angle, -.35 .. +.5 (here -.22 .. +.5)', () {
      for (final side in BeamSide.values) {
        for (final gap in const [.51, .96]) {
          for (var x = 3.5; x < 6.4; x += .1) {
            final b = gBoss(x, side: side);
            final p = GargoylePose(b, BossMotion(b, reducedMotion: true), gap: gap);
            final centre = b.beamCentres.single;
            expect(p.pitch, closeTo(GargoylePose.beamPitch(centre, gap: gap).clamp(-.22, .5), 1e-9), reason: '$side gap $gap x$x');
          }
        }
      }
      // High beams (above the lenses) look up, low beams look down.
      expect(GargoylePose.beamPitch(.16), lessThan(0));
      expect(GargoylePose.beamPitch(.84), greaterThan(.3));
      expect(GargoylePose.beamPitch(.84, gap: .96), lessThan(GargoylePose.beamPitch(.84)));
      // A slit looks at the middle.
      final slit = _p(4.5, rm: true, fury: true, slit: true);
      expect(slit.pitch, closeTo(GargoylePose.beamPitch(.5), .1));
    });

    test('a LOW sweep bows the head, a HIGH one raises it, from the warning\'s lock-on', () {
      expect(_p(3.5, rm: true, side: BeamSide.low).pitch, greaterThan(.3));
      expect(_p(3.5, rm: true, side: BeamSide.high).pitch, lessThan(0));
      expect(_p(2.8, rm: true).pitch, lessThan(-.1)); // rears back first
    });

    test('the warning brings the tag inputs: progress, side and kind, only while it lasts', () {
      expect(_p(1.0).warnSide, isNull);
      final w = _p(2.75, side: BeamSide.low);
      expect(w.warning, closeTo(.5, 1e-9));
      expect(w.warnSide, BeamSide.low);
      expect(w.warnSlit, isFalse);
      expect(_p(2.75, fury: true, slit: true).warnSlit, isTrue);
      expect(_p(5.0, side: BeamSide.low).warnSide, BeamSide.low); // the sweep keeps it
      expect(_p(7.0).warnSide, isNull);
    });

    test('the vent: lamp open, head back, beak open, steam for 1.2 s (motion), fan thrown up', () {
      final v = _p(6.4 + .35);
      expect(v.lamp, 1);
      expect(v.gape, greaterThan(.4));
      expect(v.steam, greaterThan(0));
      expect(v.wing, lessThan(-.9));
      expect(_p(6.4 + 1.3).steam, 0);
      expect(_p(6.4 + .35, rm: true).steam, 0);
      expect(v.lean, lessThan(0));
    });

    test('the brow drops as he gets angry and lifts with a wince', () {
      expect(_p(1.0, rm: true).brow, closeTo(.3, 1e-9));
      expect(_p(3.0, rm: true).brow, closeTo(1, 1e-9));
      expect(_p(1.0, rm: true, hitAgo: .2).brow, lessThan(.3));
    });

    test('idle life (motion): sway, lens pulse and blink vanish under Reduced Motion', () {
      final live = <double>{};
      for (var t = .5; t < 1.9; t += .07) {
        live.add(_p(t)['lean']);
      }
      expect(live.length, greaterThan(5));
      final still = <double>{};
      for (var t = .5; t < 1.9; t += .07) {
        still.add(_p(t, rm: true)['lean']);
      }
      expect(still.length, 1);
      // A blink irises the lenses every 4.3 s (BossMotion.blink: age % 4.3 in
      // 3.1 .. 3.26, i.e. combat 2.8 .. 2.96 in the first cycle).
      final blink = <double>[for (var t = 2.75; t < 3.0; t += .01) _p(t)['iris']];
      expect(blink.reduce(math.min), lessThan(.1));
      expect([for (var t = 2.75; t < 3.0; t += .01) _p(t, rm: true)['iris']].reduce(math.min), 1);
    });
  });

  group('the stone feather shrug', () {
    test('wind-up .25 s (lean -.8, head up), flick .15 s, the blade leaves at the launch, settle .3 s', () {
      // The rules launch at cycle time .2 (first cycle) and 4.6.
      for (final e in const [.2, 4.6, 9.2]) {
        final wind = _p(e - .16);
        final without = _p(e - .16, rm: true);
        expect(wind.lean, lessThan(without.lean - .5), reason: 'wind-up at $e');
        expect(wind.pitch, lessThan(without.pitch - .04), reason: 'head up at $e');
        // The blade is whole before the launch and gone at it.
        expect(_p(e - .01).shedTau, -1);
        expect(_p(e + .001).shedTau, closeTo(.001, 1e-6));
        expect(_p(e + .001).nearFan.shed, closeTo(1, .02));
        // Regrown by e + .55.
        expect(_p(e + .56).nearFan.shed, closeTo(0, 1e-9));
        expect(_p(e + .56).shedTau, -1);
        // The fan is flicked up at the launch.
        expect(_p(e).wing, lessThan(-.9), reason: 'flick at $e');
        // Dust falls from the cornice in the .45 s before.
        expect(_p(e - .3).dust, inExclusiveRange(0, 1));
        expect(_p(e + .01).dust, 0);
      }
    });

    test('the fury schedule adds 4.5 and 5.2 and the slit cycle only .2', () {
      expect(_p(4.5 + .001, fury: true).shedTau, closeTo(.001, 1e-6));
      expect(_p(5.2 + .001, fury: true).shedTau, closeTo(.001, 1e-6));
      // (the calm 4.6 launch is not in the fury schedule: what flies at 4.601 is
      // the 4.5 blade, .101 s out)
      expect(_p(4.6 + .001, fury: true).shedTau, closeTo(.101, 1e-6));
      expect(_p(4.5 + .001, fury: true, slit: true).shedTau, -1);
      expect(_p(9.2 + .001, fury: true, slit: true).shedTau, closeTo(.001, 1e-6));
    });

    test('the fan RIPPLES: blade 0 leads, each blade follows by .028 s, the far fan a tenth behind', () {
      final p = _p(4.6 - .07);
      final s = p.nearFan.strokes;
      for (var i = 1; i < s.length; i++) {
        expect(s[i], greaterThanOrEqualTo(s[i - 1] - 2e-3), reason: 'blade $i');
      }
      expect(s.last - s.first, greaterThan(.05));
      expect(p.farFan.strokes.first, greaterThan(p.nearFan.strokes.first - .3));
    });

    test('Reduced Motion: no shrug, no ripple, no flying blade, no dust', () {
      for (var t = 0.0; t < 9.5; t += .03) {
        final p = _p(t, rm: true);
        expect(p.shedTau, -1, reason: 't$t');
        expect(p.nearFan.shed, 0, reason: 't$t');
        expect(p.dust, 0, reason: 't$t');
        expect(p.nearFan.strokes.toSet().length, 1, reason: 't$t');
      }
    });
  });

  group('hit, glance and fury', () {
    test('a hit: flash bites in .03 s (peak .12, .06 in Reduced Motion), pulse .28 s, wince after', () {
      final peak = [for (var a = 0.0; a < .3; a += .005) _p(1.0, hitAgo: a).flash].reduce(math.max);
      expect(peak, closeTo(GargoyleTimeline.hitFlashPeak, .005));
      expect(_p(1.0, hitAgo: .03).flash, closeTo(GargoyleTimeline.hitFlashPeak, .005));
      expect(_p(1.0, hitAgo: .3).flash, 0);
      expect([for (var a = 0.0; a < .3; a += .005) _p(1.0, rm: true, hitAgo: a).flash].reduce(math.max), closeTo(GargoyleTimeline.hitFlashPeakReduced, .005));
      expect(_p(1.0, hitAgo: .14).hit, closeTo(1, 1e-9));
      expect(_p(1.0, hitAgo: .29).hit, 0);
      expect(_p(1.0, hitAgo: .25).wince, greaterThan(0));
    });

    test('the flinch (lean back, head up) is motion; the flash and the wince stay', () {
      final live = _p(1.0, hitAgo: .14);
      final rm = _p(1.0, rm: true, hitAgo: .14);
      final calm = _p(1.0);
      expect(live.head.dx, greaterThan(calm.head.dx + .1));
      expect(rm.head.dx, closeTo(_p(1.0, rm: true).head.dx, 1e-9));
      expect(rm.flash, greaterThan(0));
      expect(rm.wince, greaterThan(0));
    });

    test('a glance: a .15 s pulse, the spark stays under Reduced Motion', () {
      expect(_p(1.0, glanceAgo: .075).glance, closeTo(1, 1e-9));
      expect(_p(1.0, glanceAgo: .2).glance, 0);
      expect(_p(1.0, rm: true, glanceAgo: .075).glance, closeTo(1, 1e-9));
    });

    test('fury: plates and stance change over .45 s, eased; the eyes stay hot, the brow down, seams cracked', () {
      expect(_p(1.0, fury: true, enragedAgo: 0).furyBlend, 0);
      final mid = _p(1.0, fury: true, enragedAgo: .225).furyBlend;
      expect(mid, closeTo(.5, .01));
      expect(_p(1.0, fury: true, enragedAgo: .45).furyBlend, 1);
      final f = _p(1.0, fury: true, rm: true);
      expect(f.fury, closeTo(.8, .01));
      expect(f.flare, greaterThanOrEqualTo(.8 - 1e-9));
      expect(f.brow, greaterThanOrEqualTo(.9 - 1e-9));
      expect(f.crack, closeTo(.6, 1e-9));
      expect(f.spread, greaterThanOrEqualTo(.55 - 1e-9));
      expect(_p(1.0, rm: true).crack, 0);
    });

    test('the fury roar: a beat after the blow, thrown by .30 s, held, falling to 1.1 s; Reduced Motion shows none', () {
      expect(_p(1.0, fury: true, enragedAgo: .05).roar, 0);
      expect(_p(1.0, fury: true, enragedAgo: .35).roar, closeTo(1, 1e-9));
      expect(_p(1.0, fury: true, enragedAgo: .8).roar, inExclusiveRange(0, 1));
      expect(_p(1.0, fury: true, enragedAgo: 1.2).roar, 0);
      expect(_p(1.0, fury: true, enragedAgo: .35, rm: true).roar, 0);
      expect(_p(1.0, fury: true, enragedAgo: .35).gape, greaterThan(.8));
    });

    test('nothing pops as fury begins', () {
      var last = _p(1.0, fury: true, enragedAgo: -0.0001);
      for (var a = 0.0; a < 1.3; a += 1 / 240) {
        final now = _p(1.0, fury: true, enragedAgo: a);
        expect(_maxJump(last, now, except: {'flash', 'dust'}), lessThan(.12), reason: 'enragedAgo $a: ${_worstKey(last, now)}');
        last = now;
      }
    });
  });

  group('continuity', () {
    test('no channel jumps between frames (1/120 s) through two whole cycles, every look', () {
      // Hard edges by design: the beam's edges at the launch, the visor and the
      // dust's end.
      // (the blink's pulse is .16 s wide: up to .163 of an iris per frame; the
      // warning's progress is the rules' and ends at 3.5 s)
      const hard = {'flash', 'dust', 'beams', 'shedTau', 'shed', 'visor', 'iris', 'warning'};
      for (final (fury, slit, side) in const [
        (false, false, BeamSide.high),
        (false, false, BeamSide.low),
        (true, false, BeamSide.low),
        (true, true, BeamSide.high),
      ]) {
        for (final rm in [false, true]) {
          var last = _p(0, rm: rm, fury: fury, slit: slit, side: side);
          for (var k = 1; k < 18 * 120; k++) {
            final now = _p(k / 120, rm: rm, fury: fury, slit: slit, side: side);
            expect(_maxJump(last, now, except: hard), lessThan(.13),
                reason: '${rm ? 'RM ' : ''}fury $fury slit $slit $side t${k / 120}: ${_worstKey(last, now, except: hard)}');
            last = now;
          }
        }
      }
    });

    test('the arrival hands over to the fight without a pop (4.6 s)', () {
      final a = _p(-.0001);
      final b = _p(.0001);
      expect(_maxJump(a, b, except: {'dust', 'flash'}), lessThan(.03), reason: _worstKey(a, b));
      expect(a.arriving, isTrue);
      expect(b.arriving, isFalse);
    });

    test('the killing blow freezes the pose, then the throes take over by .32 s', () {
      for (final t in const [1.0, 3.0, 4.5, 7.0]) {
        final alive = _p(t);
        final dead = _p(t, deadFor: 0);
        expect(_maxJump(alive, dead, except: {'flash', 'hit', 'wince', 'dust', 'steam', 'beams', 'shed', 'shedTau', 'iris', 'fury', 'furyBlend', 'lamp', 'warning', 'glance', 'grip', 'crack', 'flare', 'brow', 'gape', 'roar', 'rage'}),
            lessThan(.05), reason: 't$t ${_worstKey(alive, dead)}');
        expect(dead.defeated, isTrue);
      }
    });

    test('the defeat, frame by frame, never jumps except at the visor', () {
      var last = _p(1.0, deadFor: 0);
      for (var d = 1 / 120; d < 3.9; d += 1 / 120) {
        final now = _p(1.0, deadFor: d);
        expect(_maxJump(last, now, except: {'visor', 'beams', 'flash'}), lessThan(.16), reason: 'death $d: ${_worstKey(last, now, except: {'visor', 'beams'})}');
        last = now;
      }
    });
  });

  group('arrival and defeat', () {
    test('stone: 1 until the lightning (1.65 s), cool to colour by 2.10 s; Reduced Motion fades in .25 s', () {
      double stone(double age, {bool rm = false}) => _p(age - 4.6, rm: rm).stone;
      expect(stone(.5), 1);
      expect(stone(1.65), closeTo(1, 1e-9));
      expect(stone(1.875), closeTo(.5, .02));
      expect(stone(2.10), closeTo(0, 1e-9));
      expect(stone(3.0), 0);
      expect(stone(1.775, rm: true), closeTo(.5, .02));
      expect(stone(1.90, rm: true), closeTo(0, 1e-9));
    });

    test('the dormant statue: fan mantled, head bowed, lenses dark; the lenses spark at 1.68 and 1.78', () {
      final d = _p(1.0 - 4.6);
      expect(d.wing, greaterThan(.9));
      expect(d.pitch, greaterThan(.15));
      expect(d.flare, lessThan(.05));
      // Two sparks of .10 s: they start at 1.68 and 1.78 and peak .05 s in.
      expect(_p(1.73 - 4.6).flare, greaterThan(.9));
      expect(_p(1.83 - 4.6).flare, greaterThan(.9));
      expect(_p(1.78 - 4.6).flare, lessThan(.4));
      expect(_p(1.60 - 4.6).flare, lessThan(.05));
    });

    test('the fan unfolds 2.0 .. 2.65, the intake, then the ROAR: full 2.81 .. 3.11, gone by 3.56', () {
      expect(_p(2.0 - 4.6).spread, lessThan(.05));
      expect(_p(2.65 - 4.6).spread, greaterThan(.9));
      expect(_p(2.65 - 4.6).wing, lessThan(-.9));
      expect(_p(2.5 - 4.6).wind, greaterThan(0));
      expect(_p(2.81 - 4.6).roar, closeTo(1, .01));
      expect(_p(3.0 - 4.6).roar, 1);
      expect(_p(3.11 - 4.6).roar, closeTo(1, .01));
      expect(_p(3.56 - 4.6).roar, 0);
      expect(_p(3.0 - 4.6).gape, greaterThan(.8));
      expect(_p(3.0 - 4.6, rm: true).roar, 1, reason: 'the roar pose is a state');
    });

    test('defeat: cracks race .12 .. .8, the visor is knocked loose at .3, the glass shatters at .6, the body crumbles .85 .. 1.1', () {
      expect(_p(1.0, deadFor: .05).crack, 0);
      expect(_p(1.0, deadFor: .46).crack, closeTo(.5, .02));
      expect(_p(1.0, deadFor: .8).crack, closeTo(1, 1e-9));
      expect(_p(1.0, deadFor: .29).visor, 1);
      expect(_p(1.0, deadFor: .31).visor, 0);
      expect(_p(1.0, deadFor: .55).shatter, 0);
      expect(_p(1.0, deadFor: .75).shatter, 1);
      expect(_p(1.0, deadFor: .8).crumble, 0);
      expect(_p(1.0, deadFor: 1.1).crumble, closeTo(1, 1e-9));
      expect(_p(1.0, deadFor: 1.0).crumble, inExclusiveRange(0, 1));
      expect(_p(1.0, deadFor: .6).pitch, greaterThan(.4));
      expect(_p(1.0, deadFor: .6).iris, lessThan(.3));
      // Reduced Motion: a static slump, cracks at .8, no crumble animation.
      final rm = _p(1.0, deadFor: .4, rm: true);
      expect(rm.crack, closeTo(.8, 1e-9));
      expect(rm.crumble, 0);
      expect(rm.pitch, greaterThan(.4));
    });

    test('a beam burning at the killing blow stutters out over .3 s (none in Reduced Motion)', () {
      final d0 = _p(4.5, deadFor: .01);
      expect(d0.beams, isNotEmpty);
      expect(_p(4.5, deadFor: .35).beams, isEmpty);
      expect(_p(4.5, deadFor: .01, rm: true).beams, isEmpty);
      expect(_p(1.0, deadFor: .05).beams, isEmpty);
      expect(_p(4.5, deadFor: .1, slit: true, fury: true).beams, hasLength(2));
    });

    test('atDeath(t) is the defeat t seconds in; the visor leaves exactly on the slumped head', () {
      final a = GargoylePose.atDeath(.3);
      expect(a.defeated, isTrue);
      expect(a.death, closeTo(.3, 1e-9));
      expect(GargoylePose.atDeath(.29).visor, 1);
      expect(GargoylePose.atDeath(.31).visor, 0);
    });
  });

  group('story poses', () {
    test('every mood is distinct from the others and from idle; talk opens the beak, blink shuts the lenses', () {
      final poses = {for (final m in GargoyleMood.values) m: GargoylePose.story(m)};
      for (final a in GargoyleMood.values) {
        for (final b in GargoyleMood.values) {
          if (a == b) continue;
          expect(poses[a]!.channels, isNot(poses[b]!.channels), reason: '$a vs $b');
        }
      }
      expect(poses[GargoyleMood.plain]!.channels, GargoylePose.story(GargoyleMood.plain).channels);
      expect(GargoylePose.story(GargoyleMood.plain, talk: 1).gape, greaterThan(.4));
      expect(GargoylePose.story(GargoyleMood.plain, blink: 1).iris, 0);
      expect(GargoylePose.story(GargoyleMood.beaten).visor, 0);
      expect(GargoylePose.story(GargoyleMood.beaten).shatter, 1);
      expect(GargoylePose.story(GargoyleMood.angry).fury, 1);
      expect(GargoylePose.story(GargoyleMood.happy).brow, lessThan(.1));
      expect(GargoylePose.story(GargoyleMood.plain).reduced, isTrue);
    });
  });

  group('Reduced Motion', () {
    test('idle frames are identical across ages (perch, every cycle)', () {
      final first = _p(.6, rm: true).channels;
      for (final t in const [.6, 1.0, 1.5, 1.9, 9.6, 10.5, 10.9, 18.7, 19.5]) {
        expect(_p(t, rm: true).channels, first, reason: 't$t');
      }
    });

    test('every non-idle state is distinguishable from idle', () {
      final idle = _p(1.0, rm: true).channels;
      final states = <String, GargoylePose>{
        'warning HIGH': _p(3.0, rm: true),
        'warning LOW': _p(3.0, rm: true, side: BeamSide.low),
        'sweep HIGH': _p(5.0, rm: true),
        'sweep LOW': _p(5.0, rm: true, side: BeamSide.low),
        'slit': _p(5.0, rm: true, fury: true, slit: true),
        'vent': _p(7.0, rm: true),
        'hit': _p(1.0, rm: true, hitAgo: .1),
        'glance': _p(1.0, rm: true, glanceAgo: .07),
        'fury': _p(1.0, rm: true, fury: true),
        'stone': _p(-3.6, rm: true),
        'roar': _p(-1.5, rm: true),
        'defeat': _p(1.0, rm: true, deadFor: .7),
      };
      for (final e in states.entries) {
        expect(e.value.channels, isNot(idle), reason: e.key);
      }
    });

    test('motion channels are zero, state channels keep showing', () {
      for (var t = 0.0; t < 18; t += .1) {
        final p = _p(t, rm: true, hitAgo: .1);
        expect(p.steam, 0);
        expect(p.dust, 0);
        expect(p.time, 0);
        expect(p.reduced, isTrue);
      }
      expect(_p(5.0, rm: true).beams, isNotEmpty);
      expect(_p(6.9, rm: true).lamp, 1);
      expect(_p(3.0, rm: true).warning, greaterThan(0));
    });
  });

  group('anchors through the pose', () {
    test('headPoint is the layout\'s, lean and pitch included; bodyPoint turns about the lamp', () {
      final p = _p(5.0, side: BeamSide.low);
      for (final local in [GargoyleLayout.eyeNear, GargoyleLayout.eyeFar, GargoyleLayout.beakTip]) {
        expect(p.headPoint(local), GargoyleLayout.headPoint(local, pitch: p.pitch, nudge: p.head, lean: p.lean));
      }
      expect(p.bodyPoint(Offset.zero), Offset.zero);
      final q = p.bodyPoint(const Offset(0, -2));
      expect(q.distance, closeTo(2, 1e-9));
    });

    test('a LOW sweep lowers the beak and a HIGH one raises it (nose down is positive pitch)', () {
      final low = _p(3.5, rm: true, side: BeamSide.low);
      final high = _p(3.5, rm: true, side: BeamSide.high);
      expect(low.headPoint(GargoyleLayout.beakTip).dy, greaterThan(high.headPoint(GargoyleLayout.beakTip).dy + .5));
    });
  });
}
