import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

/// Every table of the design bible's section 5 (animation spec) as a test of
/// the pure `DragonPose` channels: the wing chain and its lags, the body's
/// counter-motion, the 11 s breath beat by beat, the fireball volley, the
/// swarm call, the fury onset, the hit, the arrival, the defeat and Reduced
/// Motion; plus purity, ranges and continuity (no pops) over whole cycles.

const _arrival = 4.6;

/// A cinematic dragon [combat] seconds into the fight (so its age is
/// `4.6 + combat`), with no fireball anywhere near ready.
SkyBoss _boss(
  double combat, {
  bool fury = false,
  double? enragedAt,
  BreathLane lane = BreathLane.middle,
  bool debut = false,
  bool calls = true,
  void Function(SkyBoss)? setup,
}) {
  final b =
      SkyBoss(
          number: 5,
          x: 2,
          kind: BossKind.dragon,
          cinematic: true,
          debut: debut,
          callsSwarm: calls,
        )
        ..fireIn = 5
        ..breathLane = lane;
  if (fury) b.hp = b.maxHp ~/ 3;
  if (enragedAt != null) b.enragedAt = enragedAt;
  b.age = _arrival + combat;
  setup?.call(b);
  return b;
}

SkyBoss _arriving(double age) => SkyBoss(
  number: 5,
  x: 2,
  kind: BossKind.dragon,
  cinematic: true,
)..age = age;

DragonPose _pose(SkyBoss b, {bool reduced = false, double lookY = 0}) =>
    DragonPose(b, BossMotion(b, reducedMotion: reduced), lookY: lookY);

/// The pose [combat] seconds in (the shorthand most tests use).
DragonPose _at(
  double combat, {
  bool fury = false,
  bool reduced = false,
  BreathLane lane = BreathLane.middle,
  bool debut = false,
  bool calls = true,
  void Function(SkyBoss)? setup,
}) => _pose(
  _boss(
    combat,
    fury: fury,
    lane: lane,
    debut: debut,
    calls: calls,
    setup: setup,
  ),
  reduced: reduced,
);

/// The wingbeat waveform the bible fixes: 37% down / 63% up.
double _wave(double phi) => math.sin(phi + .45 * math.sin(phi));

/// The beat's phase in calm combat (the arrival's slow start has left
/// 4.225 rad behind by 2.65 s: 2.6 * (.6 + 2.05 * .5 * ...) in closed form).
double _calmPhase(double age) => age * 5.4 - 4.225;

double _ramp(double v, double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);

/// Every scalar a part can read, by name, for whole-pose comparisons.
Map<String, double> _channels(DragonPose p) => {
  'inhale': p.inhale,
  'blast': p.blast,
  'alert': p.alert,
  'hold': p.hold,
  'wind': p.wind,
  'roar': p.roar,
  'call': p.call,
  'lunge': p.lunge,
  'brace': p.brace,
  'settle': p.settle,
  'charge': p.charge,
  'gape': p.gape,
  'glare': p.glare,
  'heart': p.heart,
  'throat': p.throat,
  'smoke': p.smoke,
  'clutch': p.clutch,
  'neckCoil': p.neckCoil,
  'chest': p.chest,
  'pitch': p.pitch,
  'bob.x': p.bob.dx,
  'bob.y': p.bob.dy,
  'head.x': p.head.at.dx,
  'head.y': p.head.at.dy,
  'head.angle': p.head.angle,
  'drag.x': p.neckDrag.dx,
  'drag.y': p.neckDrag.dy,
  'stroke': p.stroke,
  'elbow': p.nearWing.elbow,
  'wrist': p.nearWing.wrist,
  'tip0': p.nearWing.tips[0],
  'tip1': p.nearWing.tips[1],
  'tip2': p.nearWing.tips[2],
  'tip3': p.nearWing.tips[3],
  'flex0': p.nearWing.flex[0],
  'flex3': p.nearWing.flex[3],
  'sag': p.nearWing.sag,
  'spread': p.nearWing.spread,
  'farElbow': p.farWing.elbow,
  'farWrist': p.farWing.wrist,
  'farTip3': p.farWing.tips[3],
  'tail.5': p.tailBend(.5),
  'tail.1': p.tailBend(1),
  'thump': p.thump,
  'legKick': p.legKick,
  'fold': p.nearWing.fold,
  'slump': p.slump,
  'crack': p.crack,
  'flash': p.flash,
  'fury': p.fury,
  'furyBlend': p.furyBlend,
  'wince': p.wince,
  'time': p.time,
};

void main() {
  group('purity and ranges', () {
    test('identical inputs give identical channels, whatever was built before',
        () {
      final states = <(String, SkyBoss Function())>[
        for (var i = 0; i < 44; i++)
          ('t=${i * .25}', () => _boss(i * .25)),
        for (var i = 0; i < 44; i++)
          ('fury t=${i * .25}', () => _boss(i * .25, fury: true)),
        ('hit', () => _boss(1.2, setup: (b) => b.lastHitAt = b.age - .1)),
        ('volley', () => _boss(1.2, setup: (b) => b.lastVolleyAt = b.age - .1)),
        ('charge', () => _boss(1.2, setup: (b) => b.fireIn = .2)),
        ('summon', () => _boss(1.2, setup: (b) => b.lastSummonAt = b.age - .3)),
      ];
      for (final reduced in [false, true]) {
        final first = <String, Map<String, double>>{};
        for (final (name, make) in states) {
          first[name] = _channels(_pose(make(), reduced: reduced));
        }
        // Build them again in reverse: a pose keeps no history.
        for (final (name, make) in states.reversed) {
          expect(
            _channels(_pose(make(), reduced: reduced)),
            first[name],
            reason: '$name reduced=$reduced',
          );
        }
      }
    });

    test('a pose does not depend on the wall clock or a frame counter', () {
      final a = _channels(_at(5.05));
      final b = _channels(_at(5.05));
      expect(a, b);
    });

    test('every channel is finite and bounded over whole cycles', () {
      void check(DragonPose p, String at) {
        final ch = _channels(p);
        for (final e in ch.entries) {
          expect(e.value.isFinite, isTrue, reason: '${e.key} at $at');
        }
        for (final k in [
          'inhale', 'blast', 'alert', 'hold', 'wind', 'roar', 'call', 'brace',
          'settle', 'charge', 'gape', 'glare', 'heart', 'throat', 'smoke',
          'clutch', 'neckCoil', 'sag', 'spread', 'slump', 'crack', 'flash',
          'fury', 'furyBlend', 'wince', 'fold',
        ]) {
          expect(ch[k], inInclusiveRange(0, 1), reason: '$k at $at');
        }
        expect(ch['lunge'], inInclusiveRange(-.3, 1), reason: 'lunge at $at');
        expect(ch['thump'], inInclusiveRange(-1, 1), reason: 'thump at $at');
        expect(ch['legKick'], inInclusiveRange(-1, 1), reason: 'kick at $at');
        for (final k in [
          'stroke', 'elbow', 'wrist', 'tip0', 'tip1', 'tip2', 'tip3',
          'farElbow', 'farWrist', 'farTip3',
        ]) {
          expect(ch[k], inInclusiveRange(-1, 1), reason: '$k at $at');
        }
        expect(ch['flex0']!.abs(), lessThanOrEqualTo(.2001), reason: at);
        expect(ch['flex3']!.abs(), lessThanOrEqualTo(.2001), reason: at);
        // Combat pitch stays under .2; the defeat's nose-down goes to -.35.
        expect(ch['pitch']!.abs(), lessThan(at.startsWith('defeat') ? .4 : .2),
            reason: 'pitch at $at');
        expect(p.bob.distance, lessThanOrEqualTo(.3001), reason: 'bob at $at');
        expect(p.neckDrag.distance, lessThanOrEqualTo(.5001), reason: at);
        for (final u in [0.0, .25, .5, .75, 1.0]) {
          expect(p.tailBend(u).abs(), lessThanOrEqualTo(.5001), reason: at);
        }
        expect(ch['chest'], inInclusiveRange(-.05, .4), reason: 'chest at $at');
        // The head stays near its rest pose.
        expect(
          (p.head.at - DragonLayout.headRest).distance,
          lessThan(1.6),
          reason: 'head at $at',
        );
      }

      for (final reduced in [false, true]) {
        for (final fury in [false, true]) {
          for (final lane in BreathLane.values) {
            for (var i = 0; i <= 1210; i += 3) {
              final t = i * .01 - .0;
              check(
                _at(t, fury: fury, reduced: reduced, lane: lane),
                't=$t fury=$fury reduced=$reduced $lane',
              );
            }
          }
        }
      }
      // The arrival, and the defeat from every kind of moment.
      for (final reduced in [false, true]) {
        for (var i = 0; i <= 470; i += 2) {
          check(_pose(_arriving(i * .01), reduced: reduced), 'arrival ${i * .01}');
        }
        for (final combat in const [1.2, 3.7, 5.05, 5.24, 5.9, 7.45, 7.9]) {
          for (var i = 0; i <= 300; i += 5) {
            check(
              _at(combat, reduced: reduced, setup: (b) => b.defeatedAt = b.age - i * .01),
              'defeat +${i * .01} from $combat',
            );
          }
        }
      }
    });

    test('a NaN or infinite look direction does not poison the pose', () {
      for (final look in [double.nan, double.infinity, -double.infinity]) {
        final p = _pose(_boss(1.2), lookY: look);
        expect(p.aim, 0);
        expect(p.head.at.isFinite && p.head.angle.isFinite, isTrue);
      }
      expect(_pose(_boss(1.2), lookY: 7).aim, 1);
      expect(_pose(_boss(1.2), lookY: -7).aim, -1);
    });
  });

  group('5.2 the wing chain', () {
    test('the beat runs at 5.4 rad/s (0.86 Hz), fury at 7.2 (1.15 Hz)', () {
      double period(bool fury) {
        // Local maxima of the elbow's stroke (the bottom of each downstroke).
        final maxima = <double>[];
        const dt = .0005;
        double s(double t) => _at(t, fury: fury).stroke;
        var prev2 = s(0), prev1 = s(dt);
        for (var t = 2 * dt; t < 3.2; t += dt) {
          final v = s(t);
          if (prev1 > prev2 && prev1 >= v && prev1 > .5) maxima.add(t - dt);
          prev2 = prev1;
          prev1 = v;
        }
        expect(maxima.length, greaterThanOrEqualTo(2), reason: 'fury=$fury');
        return (maxima.last - maxima.first) / (maxima.length - 1);
      }

      expect(period(false), closeTo(2 * math.pi / 5.4, .003));
      // A fury that has fully blended in runs at 7.2 rad/s.
      final b = _at(1.0, fury: true);
      expect(b.furyBlend, 1);
      expect(period(true), closeTo(2 * math.pi / 7.2, .003));
    });

    test('the waveform is 37% down / 63% up and spans [-1.0, +.70]', () {
      var down = 0, n = 0;
      var lo = 9.0, hi = -9.0;
      const dt = 1 / 4000;
      var prev = _at(1.0).stroke;
      for (var t = 1.0 + dt; t < 1.0 + 2 * math.pi / 5.4; t += dt) {
        final v = _at(t).stroke;
        if (v > prev) down++;
        n++;
        lo = math.min(lo, v);
        hi = math.max(hi, v);
        prev = v;
      }
      expect(down / n, closeTo(.37, .015));
      expect(lo, closeTo(-1.0, .012));
      expect(hi, closeTo(.70, .012));
    });

    test('stroke = -.15 + .85 s(phase): the exact formula in calm combat', () {
      for (var t = 0.0; t < 3.3; t += .037) {
        final p = _at(t);
        expect(
          p.stroke,
          closeTo(-.15 + .85 * _wave(_calmPhase(_arrival + t)), 1e-9),
        );
      }
    });

    test('Reduced Motion holds every joint at -.25 and stays still', () {
      for (var t = 0.0; t < 3.3; t += .29) {
        final p = _at(t, reduced: true);
        expect(p.stroke, -.25);
        expect(p.nearWing.elbow, -.25);
        expect(p.nearWing.wrist, -.25);
        expect(p.nearWing.tips, everyElement(-.25));
        expect(p.nearWing.flex, everyElement(0));
        expect(p.farWing.elbow, closeTo(-.25 * .88, 1e-12));
        expect(p.nearWing.sag, 0);
      }
    });

    /// Compares two joints of the same wing at the same clock, [lag] apart.
    void lagsHold(String name, SkyBoss Function(double combat) make) {
      for (var t = 0.4; t < 13.0; t += .0937) {
        for (final far in [false, true]) {
          final now = _pose(make(t));
          double elbowAgo(double lag) {
            final w = _pose(make(t - lag));
            return far ? w.farWing.elbow : w.nearWing.elbow;
          }

          final wing = far ? now.farWing : now.nearWing;
          expect(wing.wrist, closeTo(elbowAgo(.045), 1e-9), reason: '$name wrist t=$t far=$far');
          for (var i = 0; i < 4; i++) {
            expect(
              wing.tips[i],
              closeTo(elbowAgo(.075 + .03 * i), 1e-9),
              reason: '$name tip $i t=$t far=$far',
            );
          }
        }
      }
    }

    test('the wrist follows the elbow by 45 ms, fingers by 75/105/135/165 ms',
        () {
      lagsHold('calm', (t) => _boss(t));
    });

    test('the lags hold through the whole breath, call and fury too', () {
      // Rules-independent absolute moments (a hit and a summon) included.
      lagsHold('fury', (t) => _boss(t, fury: true));
      lagsHold(
        'hit',
        (t) => _boss(t, setup: (b) => b.lastHitAt = _arrival + 5.1),
      );
      lagsHold(
        'lane low',
        (t) => _boss(t, lane: BreathLane.low),
      );
      lagsHold(
        'enrage',
        (t) => _boss(
          t,
          fury: true,
          enragedAt: _arrival + 2.0,
          setup: (b) => b.lastHitAt = _arrival + 2.0,
        ),
      );
    });

    test('the far wing beats 0.55 rad (~100 ms) behind at 88% of the stroke',
        () {
      for (var t = 0.2; t < 3.2; t += .041) {
        final p = _at(t);
        final phi = _calmPhase(_arrival + t);
        expect(
          p.farWing.elbow,
          closeTo(((-.15 + .85 * _wave(phi - .55)) * .88).clamp(-1.0, 1.0), 1e-9),
        );
      }
      // It is behind, not ahead: the far elbow reaches its top later.
      double topAt(bool far) {
        var best = 9.0, at = 0.0;
        for (var t = 1.0; t < 1.0 + 2 * math.pi / 5.4; t += .001) {
          final p = _at(t);
          final v = far ? p.farWing.elbow / .88 : p.nearWing.elbow;
          if (v < best) {
            best = v;
            at = t;
          }
        }
        return at;
      }

      expect(topAt(true) - topAt(false), closeTo(.55 / 5.4, .01));
    });

    test('finger flex follows (s(t) - s(t - 60 ms)) / .35 and is at most .2', () {
      var checked = 0, up = 0, down = 0;
      for (var t = 0.3; t < 3.3; t += .011) {
        final p = _at(t);
        final lead = p.nearWing.elbow;
        final trail = _at(t - .06).nearWing.elbow;
        final push = ((lead - trail) / .35).clamp(-1.0, 1.0);
        for (var i = 0; i < 4; i++) {
          final fade = push > 0 ? _ramp(p.nearWing.tips[i], -.95, -.6) : 1.0;
          expect(
            p.nearWing.flex[i],
            closeTo(push * .2 * (.4 + .2 * i) * fade, 1e-9),
            reason: 'tip $i at $t',
          );
          expect(p.nearWing.flex[i].abs(), lessThanOrEqualTo(.2001));
        }
        expect(p.nearWing.sag, closeTo(push.abs(), 1e-9));
        if (push > .2) up++;
        if (push < -.2) down++;
        checked++;
      }
      expect(checked, greaterThan(100));
      // Positive on the downstroke (tips drag UP), negative on the upstroke.
      expect(up, greaterThan(10));
      expect(down, greaterThan(10));
    });

    test('an upward flex fades to nothing as the tip nears the top of the beat',
        () {
      for (var t = 0.3; t < 3.3; t += .003) {
        final p = _at(t);
        for (var i = 0; i < 4; i++) {
          if (p.nearWing.tips[i] <= -.95) {
            expect(p.nearWing.flex[i], lessThanOrEqualTo(1e-12), reason: 't=$t tip $i');
          }
        }
      }
    });

    test('the fan spreads for the inhale, fury, the roar and the intake', () {
      expect(_at(1.2).nearWing.spread, 0);
      expect(_at(6.0).nearWing.spread, closeTo(.5, 1e-9)); // inhale 1 * .5
      expect(_at(1.2, fury: true).nearWing.spread, closeTo(.4 * _at(1.2, fury: true).fury, 1e-9));
      expect(_at(7.9).nearWing.spread, closeTo(.6 * _at(7.9).roar, 1e-9));
      // The intake alone (before the jaws roar) fans it a little.
      final wind = _at(7.55, debut: true);
      expect(wind.wind, greaterThan(.5));
      expect(wind.nearWing.spread, greaterThanOrEqualTo(wind.wind * .3 - 1e-9));
    });
  });

  group('5.2 the body follows the wings', () {
    test('idle bob is .05 - .13 * s(t - 40 ms): the body rises on the downstroke',
        () {
      for (var t = 0.3; t < 3.3; t += .043) {
        final p = _at(t);
        expect(p.bob.dy, closeTo(.05 - .13 * _wave(_calmPhase(_arrival + t - .04)), 1e-9));
        expect(p.bob.dx, 0);
      }
    });

    test('the head counter-beats: y -= .16 s(t - 140 ms), angle += .08 s(t - 200 ms)',
        () {
      for (var t = 0.3; t < 3.3; t += .047) {
        final p = _at(t);
        final age = _arrival + t;
        final sway =
            math.sin(age * 1.1 + 1) * .025 + math.sin(age * 2.2) * .03 * 1.2;
        expect(
          p.head.at.dy,
          closeTo(
            DragonLayout.headRest.dy +
                sway -
                .16 * _wave(_calmPhase(age - .14)),
            1e-9,
          ),
        );
        expect(
          p.head.at.dx,
          closeTo(DragonLayout.headRest.dx + math.sin(age * 1.3) * .03, 1e-9),
        );
        expect(
          p.head.angle,
          closeTo(
            DragonLayout.headRestAngle + .08 * _wave(_calmPhase(age - .20)),
            1e-9,
          ),
        );
      }
    });

    test('idle sway: pitch (1.1 rad/s, .012), chest sin(2.2 t) * .03', () {
      for (var t = 0.3; t < 3.3; t += .053) {
        final p = _at(t);
        final age = _arrival + t;
        expect(p.pitch, closeTo(math.sin(age * 1.1) * .012, 1e-9));
        expect(p.chest, closeTo(math.sin(age * 2.2) * .03, 1e-9));
        expect(p.sway(1.3, .03), closeTo(math.sin(age * 1.3) * .03, 1e-9));
      }
    });

    test('the tail is a travelling wave: (.04+.16u^2)(.6 sin(phi-1.6u)+.4 sin(1.4t-2.2u+1))',
        () {
      for (var t = 0.3; t < 3.3; t += .061) {
        final p = _at(t);
        final age = _arrival + t;
        for (final u in [0.0, .3, .6, 1.0]) {
          final wave =
              math.sin(_calmPhase(age) - 1.6 * u) * .6 +
              math.sin(age * 1.4 - 2.2 * u + 1) * .4;
          expect(p.tailBend(u), closeTo(wave * (.04 + .16 * u * u), 1e-9));
        }
      }
    });

    test('the legs pendulum on beatAt: the waveform, gated by the settle', () {
      for (var t = 0.3; t < 3.3; t += .067) {
        final p = _at(t);
        final age = _arrival + t;
        expect(p.beatAt(0), closeTo(_wave(_calmPhase(age)), 1e-9));
        expect(p.beatAt(.25), closeTo(_wave(_calmPhase(age - .25)), 1e-9));
      }
      // Nothing bobs to a beat that has stopped: wings pinned, legs still
      // (a lag looks that far back, so it stills that much later).
      for (var t = 4.4; t < 7.0; t += .13) {
        expect(_at(t).beatAt(0), 0, reason: 't=$t');
        if (t > 4.6) expect(_at(t).beatAt(.25), 0, reason: 't=$t');
      }
      expect(_at(1.2, reduced: true).beatAt(.25), 0);
    });

    test('the neck drags: head(t - 90 ms) - head(t), at most .5 long', () {
      for (var t = 0.4; t < 11.0; t += .0731) {
        final p = _at(t);
        final was = _at(t - .09).head.at;
        final expected = was - p.head.at;
        final len = expected.distance;
        final clamped = len <= .5 ? expected : expected * (.5 / len);
        expect((p.neckDrag - clamped).distance, lessThan(1e-9), reason: 't=$t');
      }
      // During the snap the head lunges left and down; the neck lags behind
      // it (to the right and up).
      final snap = _at(5.25);
      expect(snap.neckDrag.dx, greaterThan(.2));
      expect(snap.neckDrag.dy, lessThan(0));
    });

    test('idle motion all stops under Reduced Motion', () {
      final a = _at(1.2, reduced: true), b = _at(2.9, reduced: true);
      expect(a.bob, Offset.zero);
      expect(a.breath, 0);
      expect(a.time, 0);
      expect(a.sway(1, 1), 0);
      expect(a.beatAt(0), 0);
      expect(a.neckDrag, Offset.zero);
      expect(a.head.at, b.head.at);
      expect(a.head.angle, b.head.angle);
      expect(a.pitch, b.pitch);
      expect(a.chest, b.chest);
      expect(a.tailBend(1), b.tailBend(1));
      expect(a.thump, 0);
      expect(a.hold, 0);
      expect(a.wind, 0);
      expect(a.impact, 0);
      expect(a.legKick, 0);
      expect(a.recoil, 0);
    });
  });

  group('5.3 the breath, beat by beat', () {
    test('the timeline constants are hung on the rules\' clocks', () {
      expect(DragonTimeline.sniffAt, DragonBreath.warnAt);
      expect(DragonTimeline.snapAt, lessThan(DragonBreath.blastAt));
      expect(DragonTimeline.holdEnd, DragonTimeline.snapAt);
      expect(DragonTimeline.igniteAt, closeTo(DragonTimeline.snapAt + DragonTimeline.snapSeconds, 1e-12));
      expect(DragonTimeline.igniteAt, lessThan(DragonBreath.blastAt));
      expect(DragonTimeline.holdAt, lessThan(DragonTimeline.holdEnd));
      expect(DragonTimeline.callAt, SkyBoss.swarmCallAt);
      expect(DragonTimeline.call2At, SkyBoss.swarmCallAt + SkyBoss.swarmFollowAfter);
      expect(DragonTimeline.recoverEnd, DragonBreath.endAt + .5);
      expect(DragonTimeline.callWindAt, DragonTimeline.callAt - .3);
      expect(DragonTimeline.arrivalWindAt, SkyBoss.roarAt - .3);
    });

    test('alert: 0 at 3.40, eased to 1 by 3.95, held to 7.1, out by 7.6', () {
      expect(_at(3.39).alert, 0);
      expect(_at(3.40).alert, closeTo(0, 1e-12));
      expect(_at(3.95).alert, closeTo(1, 1e-12));
      var prev = 0.0;
      for (var t = 3.4; t <= 3.95; t += .01) {
        final v = _at(t).alert;
        expect(v, greaterThanOrEqualTo(prev - 1e-12));
        prev = v;
      }
      for (var t = 3.95; t <= 7.1; t += .05) {
        expect(_at(t).alert, closeTo(1, 1e-12), reason: 't=$t');
      }
      expect(_at(7.35).alert, inExclusiveRange(0, 1));
      expect(_at(7.6).alert, closeTo(0, 1e-12));
      // What alert does: the head dips .05, the smoke rises, the eyes narrow
      // (glare .6), the heart warms, the beat settles high and slow.
      final calm = _at(3.0, reduced: true), alert = _at(3.95, reduced: true);
      expect(alert.head.at.dy - calm.head.at.dy, closeTo(.05, 1e-9));
      expect(alert.smoke, greaterThan(calm.smoke));
      expect(alert.glare, closeTo(.6, 1e-9));
      expect(alert.heart - calm.heart, closeTo(.2, 1e-9));
      expect(alert.nearWing.elbow, lessThan(calm.nearWing.elbow));
    });

    test('inhale: 0 at 4.0, 1 at 4.95, held to 7.1, released over .5 s', () {
      expect(_at(3.99).inhale, 0);
      expect(_at(4.0).inhale, 0);
      expect(_at(4.475).inhale, closeTo(.5, 1e-9)); // smoothstep midpoint
      expect(_at(4.95).inhale, closeTo(1, 1e-12));
      for (var t = 4.95; t <= 7.1; t += .05) {
        expect(_at(t).inhale, closeTo(1, 1e-12), reason: 't=$t');
      }
      expect(_at(7.35).inhale, closeTo(.5, 1e-9));
      expect(_at(7.6).inhale, closeTo(0, 1e-12));
    });

    test('the HOLD lasts .25 s (4.95 .. 5.20) and freezes the head', () {
      double above(double level) {
        var n = 0;
        const dt = .0005;
        for (var t = 4.8; t < 5.4; t += dt) {
          if (_at(t).hold > level) n++;
        }
        return n * dt;
      }

      expect(above(.5), closeTo(.25, .015));
      expect(above(.999), closeTo(.22, .015));
      expect(_at(4.90).hold, 0);
      expect(_at(4.95).hold, closeTo(1, 1e-9));
      expect(_at(5.10).hold, closeTo(1, 1e-9));
      expect(_at(5.20).hold, 0);
      expect(_at(5.30).hold, 0);
      // In the hold only the jitter moves the head: +-.025 at 26 / 29 Hz.
      final still = _at(5.0);
      var maxDx = 0.0, maxDy = 0.0;
      final xs = <double>[], ys = <double>[];
      for (var t = 4.96; t < 5.16; t += .001) {
        final p = _at(t);
        xs.add(p.head.at.dx);
        ys.add(p.head.at.dy);
      }
      final mx = (xs.reduce(math.max) + xs.reduce(math.min)) / 2;
      final my = (ys.reduce(math.max) + ys.reduce(math.min)) / 2;
      for (var i = 0; i < xs.length; i++) {
        maxDx = math.max(maxDx, (xs[i] - mx).abs());
        maxDy = math.max(maxDy, (ys[i] - my).abs());
      }
      expect(maxDx, closeTo(.025, .004));
      expect(maxDy, closeTo(.025, .004));
      expect(still.head.angle, closeTo(_at(5.1).head.angle, 1e-12));
      // Reduced Motion: no jitter, same pose.
      final r = <double>{
        for (var t = 4.96; t < 5.16; t += .01)
          _at(t, reduced: true).head.at.dx,
      };
      expect(r.length, 1);
    });

    test('the rear-back: head to rest + (.36,-.17), angle -.52, by 4.95', () {
      // The animation strips out everything but the rear so it can be read.
      final rest = _at(1.2, reduced: true);
      final rear = _at(5.0, reduced: true);
      final dx = rear.head.at.dx - rest.head.at.dx;
      final dy = rear.head.at.dy - rest.head.at.dy;
      // (the head goes back and up as the spec has it: the wing arm behind it
      // leaves no room for more - the body carries the rest of the gesture)
      expect(dx, closeTo(.36, .001));
      expect(dy, closeTo(-.17, .001));
      expect(rear.head.angle - rest.head.angle, closeTo(-.52, .001));
      // It starts at 4.30, not before (the sniff nudge and the alert dip are
      // the only earlier moves), and eases: slow away, slow in.
      Offset red(double t) => _at(t, reduced: true).head.at;
      expect((red(4.32) - red(4.30)).distance, lessThan(.003));
      expect((red(4.95) - red(4.94)).distance, lessThan(.005));
      expect(red(4.94).dx, greaterThan(red(4.30).dx));
      expect(red(4.95).dx, greaterThan(red(4.6).dx));
      // Gape .15 -> .35 as it rears, dipping to .23 at the hold.
      expect(_at(4.0).gape, closeTo(0, 1e-9));
      expect(_at(4.9).gape, inInclusiveRange(.3, .36));
      expect(_at(5.1).gape, closeTo(.15 + .2 - .12, 1e-6));
      // The body takes part: chest +.20, pitch +.06, sinks .12, tail lifts .42.
      final calm = _at(1.2, reduced: true);
      expect(rear.chest - calm.chest, closeTo(.20, .003));
      expect(rear.pitch - calm.pitch, closeTo(.06, .0005));
      expect(rear.tailBend(1), lessThan(-.35));
      final live = _at(5.05);
      final flat = _at(5.05, calls: false);
      expect(live.bob.dy, closeTo(flat.bob.dy, 1e-12));
      // (the hold is frozen: sink .12, and nothing else moves the body)
      expect(live.bob.dy, closeTo(.12, 1e-9));
    });

    test('the inhale is three gulps (4.33 .. 4.93): wings, chest and head each beat',
        () {
      // Three separate beats of the wings, from the flare toward -.55 and back.
      double elbow(double t) => _at(t).nearWing.elbow;
      var peaks = 0;
      var prev = elbow(4.33), prev2 = elbow(4.332);
      for (var t = 4.334; t < 4.96; t += .002) {
        final v = elbow(t);
        // A gulp is a rise (the elbow goes up the screen's stroke value).
        if (prev > prev2 && prev >= v && prev > -.75) peaks++;
        prev2 = prev;
        prev = v;
      }
      expect(peaks, 3);
      // Each reaches -.55 (.35 above the flare) and returns to -.9.
      expect(elbow(4.43), closeTo(-.55, .03));
      expect(elbow(4.63), closeTo(-.55, .03));
      expect(elbow(4.83), closeTo(-.55, .03));
      expect(elbow(4.53), closeTo(-.9, .02));
      expect(elbow(4.73), closeTo(-.9, .02));
      expect(elbow(4.95), closeTo(-.9, 1e-9));
      // The chest heaves with each (+.03), the head jerks back (.05, .025).
      final still = _at(4.53, reduced: true);
      expect(_at(4.43).chest - still.chest, greaterThan(.015));
      // Reduced Motion has no gulps: one still pose.
      expect(
        _at(4.43, reduced: true).nearWing.elbow,
        closeTo(_at(4.63, reduced: true).nearWing.elbow, 1e-9),
      );
    });

    test('the snap: 0.08 s, ease-out-cubic, the head lands on the lane', () {
      final lanes = {
        BreathLane.high: (DragonLayout.headHigh, DragonLayout.headHighAngle, .03),
        BreathLane.middle: (DragonLayout.headMiddle, DragonLayout.headMiddleAngle, -.02),
        BreathLane.low: (DragonLayout.headLow, DragonLayout.headLowAngle, -.05),
      };
      for (final lane in BreathLane.values) {
        final (at, angle, pitch) = lanes[lane]!;
        expect(_at(5.19, lane: lane).blast, 0);
        expect(_at(5.20, lane: lane).blast, closeTo(0, 1e-12));
        expect(_at(5.28, lane: lane).blast, closeTo(1, 1e-12));
        // ease-out-cubic: halfway through the time, 87.5% of the way.
        expect(_at(5.24, lane: lane).blast, closeTo(.875, 1e-9));
        // The lane pose, reached and held (the scan sweeps +-.12 in y).
        for (final t in [5.5, 6.0, 6.3]) {
          final p = _at(t, lane: lane);
          expect(p.head.at.dx, closeTo(at.dx, .003), reason: '$lane t=$t');
          expect(p.head.at.dy, closeTo(at.dy, .126), reason: '$lane t=$t');
          expect(p.head.angle, closeTo(angle, 1e-9), reason: '$lane t=$t');
        }
        // (the scan crosses zero at 6.30 s)
        expect(_at(6.30, lane: lane).head.at.dy, closeTo(at.dy, .004));
        expect(_at(6.0, lane: lane).pitch, closeTo(pitch, .004), reason: '$lane');
        // In 0.08 s: within the overshoot (10%) of the pose.
        final landed = _at(5.28, lane: lane).head;
        final rest = _at(1.2, reduced: true, lane: lane).head;
        final reach = at - rest.at;
        expect(
          (landed.at - at).distance,
          lessThanOrEqualTo(reach.distance * .11),
          reason: '$lane',
        );
        expect(landed.angle, closeTo(angle, .011));
      }
    });

    test('the snap overshoots the lane reach by 10%, peaking after it lands',
        () {
      final rest = _at(1.2, reduced: true).head.at;
      var best = 0.0, bestAt = 0.0;
      for (var t = 5.2; t < 5.5; t += .002) {
        final p = _at(t);
        // The reach along the pose's own direction (the scan is tiny).
        final reach = (p.head.at - rest).distance;
        if (reach > best) {
          best = reach;
          bestAt = t;
        }
      }
      final settled = (_at(5.6).head.at - rest).distance;
      expect(best / settled, closeTo(1.10, .02));
      expect(bestAt, closeTo(5.33, .03));
      // ... and Reduced Motion lands without it.
      final r = <double>{
        for (var t = 5.28; t < 7.0; t += .05)
          double.parse(_at(t, reduced: true).head.at.dx.toStringAsFixed(9)),
      };
      expect(r.length, 1);
    });

    test('the wings: flare to -.9 by 4.30, whip +.6 (held 50 ms), rebound -.3 by 5.42, pin +.15',
        () {
      double elbow(double t) => _at(t).nearWing.elbow;
      expect(elbow(4.30), closeTo(-.9, 1e-9));
      // Ease-out-cubic flare from the beat: 87.5% of the way at the middle
      // of the 4.0 .. 4.3 window.
      final beat = _at(4.15, calls: false).nearWing.elbow;
      final calmBeat = -.15 + .85 * _wave(_calmPhase(_arrival + 4.15));
      expect(beat, closeTo(calmBeat + (-.9 - calmBeat) * .875 * 1, .1));
      // Frozen in the hold (no tremble any more: the gulps are before it).
      for (var t = 4.95; t < 5.20; t += .01) {
        expect(elbow(t), closeTo(-.9, 1e-9), reason: 't=$t');
      }
      expect(elbow(5.20), closeTo(-.9, 1e-9));
      // The whip down to +.6 by 5.25, held to 5.30, the rebound to -.3 by
      // 5.42 and the pin at +.15 by 5.8.
      expect(elbow(5.25), closeTo(.6, 1e-9));
      expect(elbow(5.28), closeTo(.6, 1e-9));
      expect(elbow(5.30), closeTo(.6, 1e-9));
      expect(elbow(5.42), closeTo(-.3, 1e-9));
      expect(elbow(5.80), closeTo(.15, .001));
      // The burn pumps the wings slowly and heavily: .22 at 0.7 Hz from 5.9.
      var lo = 9.0, hi = -9.0;
      for (var t = 6.0; t < 6.9; t += .01) {
        lo = math.min(lo, elbow(t));
        hi = math.max(hi, elbow(t));
      }
      expect(hi - lo, greaterThan(.25));
      expect(hi, lessThan(.15 + .23));
      expect(lo, greaterThan(.15 - .23));
      expect(elbow(7.1), closeTo(.15, 1e-9));
      // The wrist lags the elbow by 45 ms through the whip.
      expect(_at(5.25 + .045).nearWing.wrist, closeTo(.6, 1e-9));
      // Back on the beat by 7.6 (nothing calls the swarm on this boss).
      final calm = _at(7.6, calls: false);
      expect(calm.nearWing.elbow, closeTo(-.15 + .85 * _wave(_calmPhase(_arrival + 7.6)), 1e-9));
    });

    test('Reduced Motion keeps the wings where the breath leaves them', () {
      double elbow(double t) => _at(t, reduced: true).nearWing.elbow;
      expect(elbow(1.2), -.25);
      expect(elbow(4.6), closeTo(-.9, 1e-9));
      expect(elbow(5.05), closeTo(-.9, 1e-9));
      expect(elbow(6.0), closeTo(.15, 1e-9));
      expect(elbow(6.6), closeTo(.15, 1e-9));
      // Still: no gulps, whip, pump or drift; and the snap settles over
      // 0.25 s, not 80 ms (the review's Reduced Motion complaint).
      final v = <double>{
        for (var t = 4.4; t < 5.15; t += .013)
          double.parse(elbow(t).toStringAsFixed(9)),
      };
      expect(v.length, 1);
      expect(elbow(5.20 + .04), greaterThan(-.9));
      expect(elbow(5.20 + .04), lessThan(-.7));
      expect(elbow(5.20 + .25), closeTo(.15, 1e-9));
      // Every joint at the same stroke: no ripple down the fingers.
      for (var t = 5.2; t < 5.6; t += .02) {
        final w = _at(t, reduced: true).nearWing;
        expect(w.wrist, w.elbow);
        expect(w.tips, everyElement(w.elbow));
      }
    });

    test('the thump: a damped spring exp(-9 dt) cos(2 pi dt / .30) from 5.28', () {
      expect(_at(5.19).thump, 0);
      expect(_at(5.20).thump, closeTo(0, 1e-12));
      expect(_at(5.28).thump, closeTo(1, 1e-9));
      // It builds over the snap (no pop) ...
      expect(_at(5.24).thump, closeTo(.5, 1e-9));
      // ... and rings out.
      for (var dt = 0.0; dt < 1.1; dt += .031) {
        expect(
          _at(5.28 + dt).thump,
          closeTo(math.exp(-9 * dt) * math.cos(2 * math.pi * dt / .30), 1e-9),
        );
      }
      expect(_at(5.28 + .075).thump.abs(), lessThan(.2)); // a quarter period
      expect(_at(5.28 + .15).thump, lessThan(0)); // swung through
      expect(_at(6.4).thump, closeTo(0, 1e-9));
      expect(_at(6.41).thump, 0);
      // The hind legs kick with it; only during the blast.
      expect(_at(5.35).legKick, closeTo(_at(5.35).thump, 1e-12));
      expect(_at(4.5).legKick, 0);
      expect(_at(7.3).legKick, 0);
    });

    test('impact is the event at the ignite: 1 at 5.28, exp(-9 dt) to 0', () {
      expect(_at(5.27).impact, 0);
      expect(_at(5.2801).impact, closeTo(1, 2e-3));
      expect(_at(5.28 + .1).impact, closeTo(math.exp(-.9), 1e-9));
      expect(_at(5.28 + .2).impact, closeTo(math.exp(-1.8), 1e-9));
      expect(_at(5.70).impact, 0);
      expect(_at(1.2).impact, 0);
      expect(_at(5.3, reduced: true).impact, 0);
    });

    test('the burn moves the body: 17 Hz rumble, a wide scan, a wing pump, a heaving chest',
        () {
      // Rumble: 17 Hz, +-.05 with a 0.9 Hz swell, once the thump has rung out.
      var amp = 0.0, crossings = 0;
      var prev = _at(6.5, lane: BreathLane.high).bob.dy;
      for (var t = 6.5; t < 7.0; t += .0005) {
        final v = _at(t).bob.dy;
        amp = math.max(amp, v.abs());
        if ((v > 0) != (prev > 0)) crossings++;
        prev = v;
      }
      expect(amp, closeTo(.05, .012));
      expect(crossings, closeTo(2 * 17 * .5, 3)); // 17 Hz over half a second
      // The scan: the head sweeps +-.12 (5 px) about the lane pose, one whole
      // sweep in the burn.
      var lo = 9.0, hi = -9.0;
      for (var t = 5.6; t < 7.0; t += .01) {
        final y = _at(t).head.at.dy;
        lo = math.min(lo, y);
        hi = math.max(hi, y);
      }
      expect(hi - lo, inInclusiveRange(.20, .27));
      expect(_at(5.5).head.at.dy, closeTo(_at(5.6).head.at.dy, .13));
      // The chest heaves (+-.04 at 1.1 Hz) inside the burn.
      var clo = 9.0, chi = -9.0;
      for (var t = 5.9; t < 6.8; t += .01) {
        clo = math.min(clo, _at(t).chest);
        chi = math.max(chi, _at(t).chest);
      }
      expect(chi - clo, greaterThan(.05));
      // Peak-to-peak over 5.7 .. 7.0 the whole figure moves in px at 250 px:
      // tail tip, head and the wing elbow all travel well over 3 px.
      double travel(double Function(DragonPose) f) {
        var a = 9.0, b = -9.0;
        for (var t = 5.7; t < 7.0; t += .01) {
          final v = f(_at(t));
          a = math.min(a, v);
          b = math.max(b, v);
        }
        return (b - a) * 41.4 * 250 / 290;
      }

      expect(travel((p) => p.head.at.dy), greaterThan(8));
      expect(travel((p) => p.tailBend(1)), greaterThan(8));
      expect(travel((p) => p.bob.dy), greaterThan(3));
      expect(travel((p) => p.nearWing.elbow * 2.5), greaterThan(8));
    });

    test('the gutter: the jet ends at 7.10, the body exhales by 7.55', () {
      expect(_at(7.09).blast, closeTo(1, 1e-12));
      expect(_at(7.1).blast, closeTo(1, 1e-12));
      expect(_at(7.325).blast, closeTo(.5, 1e-9));
      expect(_at(7.55).blast, closeTo(0, 1e-12));
      // The head sinks a little as it comes home, tail sags, smoke puffs.
      final calm = _at(7.6, calls: false);
      final mid = _at(7.35, calls: false);
      expect(mid.head.at.dy, greaterThan(calm.head.at.dy - .01));
      expect(mid.tailBend(1), greaterThan(calm.tailBend(1)));
      expect(_at(7.35, calls: false).smoke, greaterThan(_at(6.5).smoke));
      expect(_at(6.5).smoke, lessThanOrEqualTo(1));
    });

    test('the throat and heart burn from the alert until the flame is out', () {
      expect(_at(1.2).throat, 0);
      expect(_at(3.9).throat, closeTo(.3, .01));
      expect(_at(5.0).throat, 1);
      expect(_at(6.0).throat, 1);
      expect(_at(1.2).heart, lessThan(.32));
      expect(_at(3.95).heart, greaterThan(.35));
      expect(_at(5.0).heart, 1);
      expect(_at(6.0).heart, closeTo(1, 1e-9));
      expect(_at(7.7, calls: false).heart, lessThan(.33));
    });

    test('the heart keeps a small heartbeat in calm and none when open', () {
      final lo = <double>[], hi = <double>[];
      for (var t = 1.0; t < 2.6; t += .005) {
        lo.add(_at(t).heart);
      }
      hi.addAll(lo);
      final range = hi.reduce(math.max) - lo.reduce(math.min);
      expect(range, inInclusiveRange(.03, .085));
      expect(_at(1.2, reduced: true).heart, closeTo(.2, 1e-12));
      expect(_at(5.5).heart, closeTo(1, 1e-9));
    });

    test('lane pitch: nose up for the high band, down chasing the low', () {
      expect(_at(6.0, lane: BreathLane.high).pitch, greaterThan(.02));
      expect(_at(6.0, lane: BreathLane.low).pitch, lessThan(-.04));
    });
  });

  group('5.3 the swarm call', () {
    test('wind 7.3 .. 7.6, roar from 7.6, gone by 8.6', () {
      expect(_at(7.29).wind, 0);
      expect(_at(7.3).wind, 0);
      expect(_at(7.45).wind, closeTo(.5, 1e-9));
      expect(_at(7.599).wind, closeTo(1, 1e-3));
      expect(_at(7.599).roar, closeTo(0, 1e-3));
      expect(_at(7.75).wind, 0);
      expect(_at(7.6).roar, 0);
      expect(_at(7.675).roar, closeTo(.85 * .5, 1e-9));
      for (final t in [7.75, 7.9, 8.04]) {
        expect(_at(t).roar, closeTo(.85, 1e-9), reason: 't=$t');
      }
      expect(_at(8.325).roar, closeTo(.85 * .5, 1e-2));
      expect(_at(8.6).roar, closeTo(0, 1e-12));
      expect(_at(8.7).roar, 0);
      // The whole envelope for the call effect.
      expect(_at(7.45).call, closeTo(.55 * .5, 1e-9));
      expect(_at(7.9).call, closeTo(1, 1e-9));
      expect(_at(9.0, calls: false).call, 0);
    });

    test('the roar throws the head up, opens the jaws, flings the wings up',
        () {
      final calm = _at(7.6, calls: false);
      final roar = _at(7.9);
      expect(roar.roar, greaterThan(.8));
      expect(roar.head.angle, lessThan(calm.head.angle - .3));
      expect(roar.head.at.dy, lessThan(calm.head.at.dy - .05));
      expect(roar.gape, greaterThan(.8));
      expect(roar.nearWing.elbow, closeTo(-1, .01));
      expect(roar.nearWing.tips[3], closeTo(-1, .01));
      expect(roar.farWing.elbow, closeTo(-.88, .02));
      expect(roar.chest, greaterThan(calm.chest + .05));
      expect(roar.pitch, greaterThan(calm.pitch + .03));
      expect(roar.tailBend(1), lessThan(calm.tailBend(1) - .2));
      // Eyes squeezed, jaws wide: the state the head art reads.
      expect(roar.glare, lessThanOrEqualTo(1));
    });

    test('the throw overshoots by up to 18% in the first 0.35 s and settles',
        () {
      double reach(double t) {
        final p = _at(t);
        final calm = _at(t, calls: false);
        return calm.head.angle - p.head.angle; // radians of nose-up turn
      }

      // Settled (7.9 s): the roar pose. Just after the throw (7.775): more.
      final settled = reach(7.9);
      var best = 0.0;
      for (var t = 7.6; t < 7.96; t += .005) {
        best = math.max(best, reach(t));
      }
      expect(best, greaterThan(settled * 1.05));
      expect(best, lessThan(settled * 1.30));
      // Reduced Motion has no overshoot: the still roar pose only.
      final r = <double>{
        for (var t = 7.75; t < 8.04; t += .03)
          double.parse(_at(t, reduced: true).head.angle.toStringAsFixed(9)),
      };
      expect(r.length, 1);
    });

    test('a roar shakes the chest at 20 Hz, but the arrival\'s does not', () {
      // Project the roar's own contribution to bob.y (the pose with the roar
      // minus the same clock without it) on a 20 Hz sine over four whole
      // periods (0.2 s).
      double shake(double Function(double t) y, double from) {
        var re = 0.0, im = 0.0;
        const dt = .0005;
        for (var t = from; t < from + .2 - 1e-9; t += dt) {
          re += y(t) * math.sin(2 * math.pi * 20 * t) * dt;
          im += y(t) * math.cos(2 * math.pi * 20 * t) * dt;
        }
        return 2 / .2 * math.sqrt(re * re + im * im);
      }

      final call = shake(
        (t) => _pose(_boss(t)).bob.dy - _pose(_boss(t, calls: false)).bob.dy,
        7.78,
      );
      expect(call, closeTo(.016 * .85, .002));
      // The arrival roar: the screen shakes there; the chest does not add to it.
      expect(_pose(_arriving(3.05)).roar, closeTo(1, 1e-9));
      // Its whole bob is the slow beat and the lift of the roar - no buzz.
      final buzz = shake((t) => _pose(_arriving(t)).bob.dy, 2.9);
      expect(buzz, lessThan(.6 * call));
    });

    test('the intake before it: the head draws back, chest swells, wings rise',
        () {
      // (the same clock without the call: the difference is the intake alone)
      final calm = _at(7.58, calls: false);
      final wind = _at(7.58);
      expect(wind.head.at.dx, greaterThan(calm.head.at.dx + .05));
      expect(wind.head.angle, lessThan(calm.head.angle - .1));
      expect(wind.nearWing.elbow, closeTo(-.5, .06));
      expect(wind.chest, greaterThan(calm.chest));
    });

    test('rules 38 replays and calm bosses call nothing', () {
      for (var t = 7.0; t < 9.6; t += .05) {
        final p = _at(t, calls: false);
        expect(p.wind, 0, reason: 't=$t');
        expect(p.call, 0, reason: 't=$t');
      }
      // (Their roar is only the rules' own pulse, absent here.)
      expect(_at(7.9, calls: false).roar, 0);
    });

    test('the other session\'s roar = max(m.roar, m.summon * .7) is preserved',
        () {
      final b = _boss(1.2, calls: false)..lastSummonAt = _arrival + 1.2 - .35;
      final m = BossMotion(b, reducedMotion: false);
      final p = DragonPose(b, m);
      expect(m.summon, closeTo(1, 1e-9));
      expect(p.summon, closeTo(1, 1e-9));
      expect(p.roar, closeTo(.7, 1e-9)); // summon * .7
      expect(p.call, closeTo(.7, 1e-9));
      // Later in the pulse it follows the rules' own pulse down.
      final b2 = _boss(1.2, calls: false)..lastSummonAt = _arrival + 1.2 - .6;
      final m2 = BossMotion(b2, reducedMotion: false);
      expect(DragonPose(b2, m2).roar, closeTo(BossMotion.pulse(.6, .7) * .7, 1e-9));
      // With the clock calling as well, the louder of the two wins.
      final b3 = _boss(7.9)..lastSummonAt = _arrival + 7.9 - .1;
      expect(_pose(b3).roar, closeTo(.85, 1e-9));
    });

    test('fury: a second, smaller call at 9.0 (not on the debut)', () {
      expect(_at(8.69, fury: true).wind, lessThan(.01));
      expect(_at(8.85, fury: true).wind, closeTo(.8 * .5, 1e-2));
      expect(_at(9.0, fury: true).wind, closeTo(.8, 1e-2));
      for (final t in [9.2, 9.3, 9.4]) {
        expect(_at(t, fury: true).roar, closeTo(.68, 1e-9), reason: 't=$t');
      }
      expect(_at(10.1, fury: true).roar, 0);
      // The debut dragon (and any that has not enraged) does not follow up.
      expect(_at(9.3, fury: true, debut: true).roar, 0);
      expect(_at(9.3).roar, 0);
    });

    test('Reduced Motion: the intake is motion, the roar is a still pose', () {
      expect(_at(7.45, reduced: true).wind, 0);
      final roar = _at(7.9, reduced: true);
      expect(roar.roar, closeTo(.85, 1e-9));
      expect(roar.nearWing.elbow, closeTo(-1, .01));
      expect(roar.head.angle, lessThan(_at(7.6, reduced: true, calls: false).head.angle - .3));
      // ... the same at every instant of the plateau.
      final a = _at(7.8, reduced: true), b = _at(8.0, reduced: true);
      expect(a.head.at, b.head.at);
      expect(a.nearWing.elbow, b.nearWing.elbow);
    });
  });

  group('5.4 the fireball volley', () {
    SkyBoss charging(double charge) => _boss(
      1.2,
      setup: (b) => b.fireIn = .65 * (1 - charge),
    );

    test('the charge is 0.65 s, eased; the head lunges onto the rules\' mouth',
        () {
      for (final lookY in [-1.0, 0.0, 1.0]) {
        for (final fury in [false, true]) {
          final b = _boss(
            1.2,
            fury: fury,
            setup: (b) => b.fireIn = 1e-6,
          );
          final p = _pose(b, lookY: lookY);
          expect(p.charge, closeTo(1, 1e-6));
          final mouth = p.headPoint(DragonLayout.headMouth);
          expect(
            (mouth - DragonLayout.rulesMouth).distance,
            lessThan(.01),
            reason: 'look $lookY fury $fury',
          );
        }
      }
      // Reduced Motion shows the state: the head at the anchor, jaws .55.
      final r = _pose(_boss(1.2, setup: (b) => b.fireIn = 1e-6), reduced: true);
      expect(
        (r.headPoint(DragonLayout.headMouth) - DragonLayout.rulesMouth).distance,
        lessThan(.01),
      );
      expect(r.gape, closeTo(.55, 1e-3));
    });

    test('pull-back (.14,.06) peaks at charge .275, then the lunge', () {
      // head = rest + (anchor - rest) * charge          (the lunge)
      //      + (.14, .06) * (1 - cos(2 pi min(charge / .55, 1))) / 2  (pull-back)
      //      + idle * (1 - charge)                       (settle)
      double bump(double charge) =>
          (1 - math.cos(2 * math.pi * math.min(charge / .55, 1))) / 2;
      expect(bump(.275), closeTo(1, 1e-12));
      expect(bump(0), 0);
      expect(bump(.55), closeTo(0, 1e-12));
      expect(bump(.9), closeTo(0, 1e-12));
      final free = _at(1.2).head;
      const rest = DragonLayout.headRest;
      for (final raw in [.05, .2, .35, .5, .7, .9, 1.0]) {
        final p = _pose(charging(raw));
        final c = p.charge;
        final expected =
            rest +
            (DragonLayout.headCharge - rest) * c +
            const Offset(.14, .06) * bump(c) +
            (free.at - rest) * (1 - c);
        // (headCharge is the layout's 3-decimal rounding of the exact anchor)
        expect((p.head.at - expected).distance, lessThan(1e-3), reason: 'raw $raw');
        final angle =
            DragonLayout.headRestAngle +
            (DragonLayout.headChargeAngle - DragonLayout.headRestAngle) * c +
            (free.angle - DragonLayout.headRestAngle) * (1 - c);
        expect(p.head.angle, closeTo(angle, 1e-9), reason: 'raw $raw');
      }
      // Reduced Motion has no pull-back or idle: the pure lunge.
      final r = _pose(charging(.35), reduced: true);
      expect(
        (r.head.at - (rest + (DragonLayout.headCharge - rest) * r.charge)).distance,
        lessThan(1e-3),
      );
    });

    test('at launch the head is continuous: the lunge spring exp(-9 tau) cos(14 tau)',
        () {
      final before = _pose(_boss(1.2, setup: (b) => b.fireIn = 1e-6));
      final after = _pose(
        _boss(1.2, setup: (b) => b.lastVolleyAt = b.age - 1e-6),
      );
      expect(after.lunge, closeTo(1, 1e-4));
      expect((before.head.at - after.head.at).distance, lessThan(.002));
      expect((before.head.angle - after.head.angle).abs(), lessThan(.002));
      for (var tau = 0.0; tau < .6; tau += .023) {
        final p = _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - tau));
        // (its last 0.15 s are folded away so the tail ends at exactly 0)
        expect(
          p.lunge,
          closeTo(
            math.exp(-9 * tau) * math.cos(14 * tau) * (1 - _ramp(tau, .45, .6)),
            1e-9,
          ),
        );
      }
      // It dips below zero on the way home and is gone by 0.6 s.
      final dip = _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - .22));
      expect(dip.lunge, lessThan(0));
      expect(dip.lunge, greaterThan(-.3));
      // No spring under Reduced Motion.
      expect(
        _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - .1), reduced: true).lunge,
        0,
      );
    });

    test('nothing else pops at launch: wings, claws, neck, glow, jaws', () {
      final before = _channels(_pose(_boss(1.2, setup: (b) => b.fireIn = 1e-6)));
      final after = _channels(
        _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - 1e-6)),
      );
      for (final k in before.keys) {
        if (k == 'charge' || k == 'flash') continue;
        expect(
          after[k]! - before[k]!,
          closeTo(0, k == 'settle' ? .002 : .004),
          reason: 'channel $k jumped at the launch',
        );
      }
      expect(before['charge'], closeTo(1, 1e-6));
      expect(after['charge'], 0);
      expect(after['brace'], closeTo(1, 1e-4));
    });

    test('the jaws snap to 1.0 at launch and close over 0.3 s', () {
      double gape(double tau) =>
          _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - tau)).gape;
      expect(gape(0), closeTo(.55, 1e-6));
      expect(gape(.05), closeTo(1, 1e-9));
      expect(gape(.2), inExclusiveRange(.2, .9));
      expect(gape(.36), 0);
      // Kept under Reduced Motion (the shot's state).
      expect(
        _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - .05), reduced: true).gape,
        closeTo(1, 1e-9),
      );
    });

    test('the wings brace to +.05 x .6 and the shot kicks them +.25 over .3 s',
        () {
      final free = _at(1.2).nearWing.elbow;
      final braced = _pose(_boss(1.2, setup: (b) => b.fireIn = 1e-6));
      expect(braced.nearWing.elbow, closeTo(free + (.05 - free) * .6, .003));
      for (var tau = .02; tau < .3; tau += .07) {
        final p = _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - tau));
        final expected =
            free +
            (.05 - free) * p.brace * .6 +
            .25 * math.sin(math.pi * tau / .3);
        expect(p.nearWing.elbow, closeTo(expected, 1e-9), reason: 'tau $tau');
      }
      // The brace lets go over 0.45 s, the kick over 0.3 s.
      expect(
        _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - .5)).nearWing.elbow,
        closeTo(free, 1e-9),
      );
    });

    test('the tail counter-whips after the launch and the claws let go slowly',
        () {
      final calm = _at(1.2);
      final whip = _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - .2));
      expect(whip.tailBend(1), isNot(closeTo(calm.tailBend(1), .03)));
      expect(_pose(_boss(1.2, setup: (b) => b.fireIn = 1e-6)).clutch, closeTo(1, 1e-3));
      expect(_pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - .15)).clutch, inExclusiveRange(.2, .9));
      expect(_pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - .5)).clutch, 0);
    });

    test('the ball leaves and the head rocks back and up (.14,-.05), then home',
        () {
      SkyBoss shot(double tau) =>
          _boss(1.2, setup: (b) => b.lastVolleyAt = b.age - tau);
      final rest = DragonLayout.headRest;
      final p = _pose(shot(.14));
      expect(p.head.at.dx - rest.dx, inInclusiveRange(.10, .25));
      // (it starts from zero: continuous with the lunge at the launch)
      expect(
        (_pose(shot(1e-6)).head.at - _pose(_boss(1.2, setup: (b) => b.fireIn = 1e-6)).head.at).distance,
        lessThan(.002),
      );
      // It is over by 0.28 s, and Reduced Motion never rocks.
      final late = _pose(shot(.29));
      final none = _pose(_boss(1.2));
      expect((late.head.at - none.head.at).distance, lessThan(.06));
      final r = _pose(shot(.14), reduced: true);
      expect(r.head.at, _pose(_boss(1.2), reduced: true).head.at);
    });

    test('idle life fades back in over 0.5 s after the shot (settle)', () {
      double settle(double tau) =>
          _pose(_boss(1.2, setup: (b) => b.lastVolleyAt = b.age - tau)).settle;
      expect(settle(0), closeTo(0, 1e-9));
      expect(settle(.25), closeTo(.5, 1e-9));
      expect(settle(.5), closeTo(1, 1e-9));
      expect(_pose(_boss(1.2, setup: (b) => b.fireIn = .3)).settle, lessThan(1));
    });

    test('a volley during the roar leaves the jaws on the anchor', () {
      // The rules launch a ball 0.9 s after the flame, in the middle of the
      // swarm call: the roar gives way as the charge builds.
      final b = _boss(7.9, setup: (b) => b.fireIn = 1e-6);
      final p = _pose(b);
      expect(p.roar, greaterThan(.8));
      expect(
        (p.headPoint(DragonLayout.headMouth) - DragonLayout.rulesMouth).distance,
        lessThan(.01),
      );
    });
  });

  group('5.5 the fury onset', () {
    SkyBoss enraged(double since) => _boss(
      3.0,
      fury: true,
      setup: (b) {
        b.enragedAt = b.age - since;
        b.lastHitAt = b.enragedAt;
      },
    );

    test('plates, seams and stance transform over 0.45 s, eased', () {
      expect(_pose(enraged(0)).furyBlend, 0);
      expect(_pose(enraged(.225)).furyBlend, closeTo(.5, 1e-9));
      expect(_pose(enraged(.45)).furyBlend, 1);
      expect(_pose(enraged(.6)).furyBlend, 1);
      var prev = 0.0;
      for (var s = 0.0; s <= .45; s += .01) {
        final v = _pose(enraged(s)).furyBlend;
        expect(v, greaterThanOrEqualTo(prev - 1e-12));
        prev = v;
      }
      // fury = (.8 + .2 rage) * blend, never above 1.
      for (var s = 0.0; s < 2; s += .05) {
        final p = _pose(enraged(s));
        expect(p.fury, closeTo((.8 + p.rage * .2) * p.furyBlend, 1e-12));
        expect(p.fury, lessThanOrEqualTo(1));
      }
      expect(_pose(enraged(3)).fury, closeTo(.8, 1e-12));
    });

    test('the roar: a beat after the blow, thrown by 0.30 s, held, then falls',
        () {
      expect(_pose(enraged(0)).roar, 0);
      expect(_pose(enraged(.1)).roar, 0);
      expect(_pose(enraged(.3)).roar, closeTo(.9, 1e-9));
      expect(_pose(enraged(.45)).roar, closeTo(.9, 1e-9));
      expect(_pose(enraged(.6)).roar, closeTo(.9, 1e-9));
      expect(_pose(enraged(.85)).roar, closeTo(.9 * .5, 1e-9));
      expect(_pose(enraged(1.1)).roar, 0);
      // The head is up, the jaws wide, the wings thrown up at its peak.
      final calm = _pose(enraged(3));
      final roar = _pose(enraged(.45));
      expect(roar.head.angle, lessThan(calm.head.angle - .3));
      expect(roar.gape, greaterThan(.85));
      expect(roar.nearWing.elbow, closeTo(-1, .01));
      expect(roar.chest, greaterThan(calm.chest));
    });

    test('nothing pops as the fury begins or blends in', () {
      final a = _channels(_pose(_boss(3.0, fury: true, setup: (b) {
        b.enragedAt = b.age + 1e-6;
      })));
      final b = _channels(_pose(enraged(1e-6)));
      for (final k in a.keys) {
        if (k == 'hold' || k == 'time' || k == 'flash') continue;
        expect(b[k]! - a[k]!, closeTo(0, .01), reason: 'channel $k at the enrage');
      }
    });

    test('the beat quickens 5.4 -> 7.2 rad/s without a jump in phase', () {
      // No hit and no roar in the way: the wings alone, before and through
      // the blend. The stroke's acceleration stays smooth (no lurch as the
      // rate changes) and its phase is the calm phase plus a smooth extra.
      SkyBoss bare(double since) => _boss(
        3.0,
        fury: true,
        setup: (b) => b.enragedAt = b.age - since,
      );
      var prev = _pose(bare(-.3)).stroke;
      var prevV = 0.0, maxJerk = 0.0;
      for (var s = -.3 + .001; s < .1; s += .001) {
        final v = _pose(bare(s)).stroke;
        final vel = (v - prev) / .001;
        if (s > -.29) maxJerk = math.max(maxJerk, (vel - prevV).abs());
        prevV = vel;
        prev = v;
      }
      expect(maxJerk, lessThan(.12));
      // The phase difference against the calm beat grows smoothly to
      // 1.8 * (since - .225) once the blend is over.
      for (final since in [1.2, 2.0, 3.0]) {
        final f = _pose(bare(since));
        final age = _arrival + 3.0;
        final extra = 1.8 * (since - .225);
        expect(
          f.stroke,
          closeTo(-.15 + .85 * _wave(_calmPhase(age) + extra), 1e-9),
          reason: 'since $since',
        );
      }
    });

    test('the stance: head lower, spines and wings more open', () {
      // (Reduced Motion strips the idle life so the stance reads alone.)
      final calm = _at(1.2, reduced: true);
      final fury = _at(1.2, fury: true, reduced: true);
      expect(fury.head.at.dy - calm.head.at.dy, closeTo(.10, 1e-9));
      expect(fury.head.at.dx, calm.head.at.dx);
      expect(fury.nearWing.spread, closeTo(.4 * fury.fury, 1e-9));
      expect(fury.pitch - calm.pitch, closeTo(.015, 1e-9));
      final live = _at(1.2, fury: true);
      expect(live.nearWing.spread, closeTo(.4 * live.fury, 1e-9));
    });

    test('Reduced Motion: the transformation is instant and the roar a pose', () {
      final r = _pose(enraged(0), reduced: true);
      expect(r.furyBlend, 1);
      expect(r.fury, closeTo(.8 + r.rage * .2, 1e-12));
      expect(_pose(enraged(.45), reduced: true).roar, closeTo(.9, 1e-9));
    });
  });

  group('5.6 the hit', () {
    SkyBoss hit(double tau) =>
        _boss(1.2, setup: (b) => b.lastHitAt = b.age - tau);

    test('flash bites in two frames, peaks at .55 (.45 Reduced) and drains', () {
      double peak(bool reduced) {
        var best = 0.0;
        for (var t = 0.0; t <= .3; t += .002) {
          best = math.max(best, _pose(hit(t), reduced: reduced).flash);
        }
        return best;
      }

      expect(peak(false), closeTo(.55, 1e-9));
      expect(peak(true), closeTo(.45, 1e-9));
      expect(_pose(hit(0)).flash, 0);
      expect(_pose(hit(.03)).flash, closeTo(.55, 1e-9));
      expect(_pose(hit(.28)).flash, closeTo(0, 1e-12));
      expect(_pose(hit(.4)).flash, 0);
      expect(_pose(hit(.5)).flash, 0);
      // Reduced Motion keeps the slow pulse (nothing strobes).
      expect(_pose(hit(.14), reduced: true).flash, closeTo(.45, 1e-9));
    });

    test('the head snaps back (.06,-.03) and -.12 rad, the body nudges', () {
      final calm = _at(1.2);
      // The kick peaks at its attack's end (0.05 s).
      final p = _pose(hit(.05));
      final dHead = p.head.at - _pose(_boss(1.2)).head.at;
      expect(dHead.dx, closeTo(.06, .01));
      expect(dHead.dy, closeTo(-.03, .01));
      expect(p.head.angle - calm.head.angle, closeTo(-.12, .01));
      expect(p.bob.dx, closeTo(.05, .003));
      expect(p.pitch - calm.pitch, closeTo(.01, .003));
      // ... and it is home by 0.32 s.
      expect(_pose(hit(.33)).head.at, _pose(_boss(1.2)).head.at);
      // Wings pump +.2 with it; the tail flicks up a moment later (the
      // blade feels the blow about 0.11 s after the root).
      expect(p.nearWing.elbow - calm.nearWing.elbow, closeTo(.2, .05));
      final flick = _pose(hit(.16));
      final none = _pose(_boss(1.2));
      expect(flick.tailBend(1), lessThan(none.tailBend(1) - .2));
      expect(_pose(hit(.05)).tailBend(0), closeTo(none.tailBend(0), 1e-9));
    });

    test('the expression (wince) is the rules\' 0.28 s pulse', () {
      for (var t = 0.0; t < .35; t += .02) {
        final b = hit(t);
        expect(_pose(b).wince, closeTo(BossMotion.pulse(t, .28), 1e-12));
      }
    });

    test('Reduced Motion: flash and expression stay, the flinch does not', () {
      final calm = _at(1.2, reduced: true);
      final p = _pose(hit(.05), reduced: true);
      expect(p.head.at, calm.head.at);
      expect(p.head.angle, calm.head.angle);
      expect(p.bob, Offset.zero);
      expect(p.pitch, calm.pitch);
      expect(p.flash, greaterThan(0));
      expect(_pose(hit(.14), reduced: true).wince, closeTo(1, 1e-9));
    });

    test('a hit on the open heart glows for 0.45 s', () {
      final p = _pose(
        _boss(5.6, setup: (b) => b.lastCoreHitAt = b.age - .1),
      );
      expect(p.crit, closeTo(1 - .1 / .45, 1e-12));
      expect(_at(5.6).crit, 0);
      expect(
        _pose(_boss(5.6, setup: (b) => b.lastCoreHitAt = b.age - .5)).crit,
        0,
      );
    });
  });

  group('5.7 the arrival', () {
    test('the wings are spread, never folded', () {
      for (var age = 0.0; age < 4.7; age += .1) {
        final p = _pose(_arriving(age));
        expect(p.fold, 0, reason: 'age $age');
        expect(p.nearWing.fold, 0);
        expect(p.farWing.fold, 0);
      }
    });

    test('a slow majestic beat (2.8 rad/s) that quickens to 5.4 by 2.65 s', () {
      // Peak-to-peak spacing of the elbow's stroke through the arrival.
      final peaks = <double>[];
      const dt = .001;
      var p2 = _pose(_arriving(0.02)).stroke;
      var p1 = _pose(_arriving(0.02 + dt)).stroke;
      for (var t = 0.02 + 2 * dt; t < 2.6; t += dt) {
        final v = _pose(_arriving(t)).stroke;
        if (p1 > p2 && p1 >= v && p1 > .55) peaks.add(t - dt);
        p2 = p1;
        p1 = v;
      }
      final gaps = [for (var i = 1; i < peaks.length; i++) peaks[i] - peaks[i - 1]];
      expect(gaps, isNotEmpty);
      // The first beat is slow (about 2 pi / 2.8 = 2.2 s), each is quicker.
      expect(gaps.first, greaterThan(1.6));
      for (var i = 1; i < gaps.length; i++) {
        expect(gaps[i], lessThan(gaps[i - 1]), reason: 'beat $i');
      }
      // From 2.65 s on it is the calm beat.
      final later = <double>[];
      p2 = _pose(_arriving(2.7)).stroke;
      p1 = _pose(_arriving(2.7 + dt)).stroke;
      for (var t = 2.7 + 2 * dt; t < 4.5; t += dt) {
        final v = _pose(_arriving(t)).stroke;
        if (p1 > p2 && p1 >= v && p1 > .1) later.add(t - dt);
        p2 = p1;
        p1 = v;
      }
      // (the roar holds the wings up until 3.45 s: take the beats after it)
      final calm = later.where((t) => t > 3.6).toList();
      if (calm.length >= 2) {
        expect(calm[1] - calm[0], closeTo(2 * math.pi / 5.4, .01));
      }
    });

    test('the wind (2.35 .. 2.65) then the roar: full by 2.81, held to 3.11, gone by 3.56',
        () {
      expect(_pose(_arriving(2.34)).wind, 0);
      expect(_pose(_arriving(2.35)).wind, closeTo(0, 1e-9));
      expect(_pose(_arriving(2.5)).wind, closeTo(.5, 1e-9));
      expect(_pose(_arriving(2.649)).wind, closeTo(1, 1e-3));
      expect(_pose(_arriving(2.85)).wind, 0);
      // The attack is fast (0.16 s), so the jaws are open when the plume is.
      expect(_pose(_arriving(2.649)).roar, closeTo(0, 1e-3));
      expect(_pose(_arriving(2.73)).roar, closeTo(.5, 1e-9));
      expect(_pose(_arriving(2.81)).roar, closeTo(1, 1e-9));
      for (final t in [2.85, 3.05, 3.10]) {
        expect(_pose(_arriving(t)).roar, closeTo(1, 1e-9), reason: 't=$t');
      }
      expect(_pose(_arriving(3.335)).roar, closeTo(.5, 1e-9));
      expect(_pose(_arriving(3.56)).roar, closeTo(0, 1e-12));
      expect(_pose(_arriving(3.7)).roar, 0);
      // The jaws are (nearly) as open at the plume's peak (2.83) as at the
      // old bell's peak (3.05).
      expect(_pose(_arriving(2.83)).gape, greaterThan(.95));
      // Head thrown up (-.56 rad), jaws wide, wings thrown up at the peak.
      final calm = _pose(_arriving(2.0));
      final peak = _pose(_arriving(3.05));
      expect(peak.head.angle - DragonLayout.headRestAngle, closeTo(-.56, .3));
      expect(peak.head.angle, lessThan(calm.head.angle - .4));
      expect(peak.gape, closeTo(1, 1e-9));
      expect(peak.nearWing.elbow, closeTo(-1, 1e-9));
      expect(peak.chest, greaterThan(calm.chest + .05));
      // The roar is still a pose under Reduced Motion; the wind is not.
      final r = _pose(_arriving(3.05), reduced: true);
      expect(r.roar, closeTo(1, 1e-9));
      expect(_pose(_arriving(2.5), reduced: true).wind, 0);
    });

    test('the arrival hands over to the fight without a pop (4.6 s)', () {
      final a = _channels(_pose(_arriving(_arrival - 1e-6)));
      final b = _channels(_pose(_boss(0, setup: (b) => b.age = _arrival + 1e-6)));
      for (final k in a.keys) {
        if (k == 'time') continue;
        expect(b[k]! - a[k]!, closeTo(0, .002), reason: 'channel $k at 4.6 s');
      }
    });
  });

  group('5.8 the defeat', () {
    SkyBoss killed(double combat, double since, {bool fury = false}) =>
        _boss(
          combat,
          fury: fury,
          setup: (b) => b.defeatedAt = b.age - since,
        );

    test('nose-down -.35 by .55 s, wings fold to .3, the tail goes limp', () {
      final calm = _at(1.2);
      final p = _pose(killed(1.2, .55));
      expect(p.pitch, closeTo(-.35, .01));
      expect(p.fold, closeTo(.3, 1e-9));
      expect(p.nearWing.fold, closeTo(.3, 1e-9));
      expect(p.slump, closeTo(1, 1e-9));
      // (the blade droops about 0.11 s after the root.)
      expect(_pose(killed(1.2, .8)).tailBend(1), closeTo(.5, 1e-9));
      expect(p.tailBend(0.5), greaterThan(.1));
      expect(p.head.angle - calm.head.angle, greaterThan(.3));
      expect(p.head.at.dy, greaterThan(calm.head.at.dy + .9));
      // The dead weight sinks.
      expect(_pose(killed(1.2, .9)).bob.dy, closeTo(.3, 1e-9));
    });

    test('the seam cracks spread from the heart (.08 .. 0.8)', () {
      expect(_pose(killed(1.2, .05)).crack, 0);
      expect(_pose(killed(1.2, .08)).crack, closeTo(0, 1e-9));
      expect(_pose(killed(1.2, .44)).crack, closeTo(.5, 1e-9));
      expect(_pose(killed(1.2, .8)).crack, closeTo(1, 1e-9));
      expect(_at(1.2).crack, 0);
    });

    test('the throes: the head is flung back (+.35,-.25) and then droops', () {
      // (Reduced Motion strips the idle life so the rest pose reads alone.)
      final calm = _at(1.2, reduced: true).head;
      final fling = _pose(killed(1.2, .10)).head;
      final droop = _pose(killed(1.2, .6)).head;
      // At .10 the fling is at its peak; the slump is only starting.
      expect(fling.at.dx - calm.at.dx, greaterThan(.25));
      expect(fling.angle, lessThan(calm.angle));
      // The droop: head down and turned by .45 rad.
      expect(droop.at.dy - calm.at.dy, closeTo(1.2, .2));
      expect(droop.angle - calm.angle, closeTo(.45, .1));
    });

    test('the wings splay in four irregular beats (.45) and are limp by .9', () {
      var lo = 9.0, hi = -9.0;
      for (var d = .18; d < .5; d += .004) {
        final v = _pose(killed(1.2, d)).nearWing.elbow;
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
      // A visible flutter around the slump, then nothing.
      expect(hi - lo, greaterThan(.35));
      final limp = <double>{
        for (var d = .95; d < 1.4; d += .05)
          double.parse(_pose(killed(1.2, d)).nearWing.elbow.toStringAsFixed(9)),
      };
      expect(limp.length, 1);
      expect(limp.single, closeTo(-.1 + .9, .001));
    });

    test('the killing blow freezes the pose (hit-stop) then it blends out', () {
      for (final (name, combat) in const [
        ('idle', 1.2),
        ('rear', 4.6),
        ('hold', 5.05),
        ('blast', 5.9),
        ('call', 7.9),
      ]) {
        final before = _channels(_pose(_boss(combat, setup: (b) {})));
        final at = _channels(_pose(killed(combat, 0)));
        final after = _channels(_pose(killed(combat, 1e-6)));
        // The geometry is continuous through the killing blow.
        for (final k in [
          'head.x', 'head.y', 'head.angle', 'elbow', 'wrist', 'tip3',
          'farElbow', 'pitch', 'bob.x', 'bob.y', 'tail.1', 'gape',
        ]) {
          expect(
            after[k]! - at[k]!,
            closeTo(0, .002),
            reason: '$name: $k at the death',
          );
          expect(
            at[k]! - before[k]!,
            closeTo(0, .06),
            reason: '$name: $k across the death',
          );
        }
      }
    });

    test('the pose it died in has faded by 0.3 s (the crown leaves exactly)', () {
      final a = _pose(killed(1.2, .3));
      for (final combat in const [5.05, 5.9, 7.9, 4.6]) {
        final b = _pose(killed(combat, .3));
        expect((a.head.at - b.head.at).distance, lessThan(1e-9), reason: '$combat');
        expect(a.head.angle, closeTo(b.head.angle, 1e-9));
        expect(a.pitch, closeTo(b.pitch, 1e-9));
        expect((a.bob - b.bob).distance, lessThan(1e-9));
      }
      // atDeath is the same as any real defeat by then.
      final ad = DragonPose.atDeath(.3);
      expect((ad.head.at - a.head.at).distance, lessThan(1e-9));
      expect(ad.pitch, closeTo(a.pitch, 1e-9));
    });

    test('Reduced Motion: one still defeat pose', () {
      final a = _pose(killed(1.2, .1), reduced: true);
      final b = _pose(killed(1.2, .9), reduced: true);
      expect(a.head.at, b.head.at);
      expect(a.pitch, b.pitch);
      expect(a.nearWing.elbow, b.nearWing.elbow);
      expect(a.slump, .7);
      expect(a.fold, .3);
      expect(a.crack, .8);
      expect(a.bob, Offset.zero);
    });
  });

  group('5.9 Reduced Motion, once', () {
    test('motion channels are zero, state channels keep showing', () {
      for (final combat in const [1.2, 3.7, 4.6, 5.05, 5.6, 7.9]) {
        final n = _at(combat), r = _at(combat, reduced: true);
        expect(r.time, 0);
        expect(r.bob, Offset.zero);
        expect(r.hold, 0);
        expect(r.thump, 0);
        expect(r.impact, 0);
        expect(r.wind, 0);
        expect(r.neckDrag, Offset.zero);
        expect(r.legKick, 0);
        expect(r.breath, 0);
        // State: identical.
        expect(r.inhale, n.inhale, reason: 't=$combat');
        expect(r.blast, n.blast);
        expect(r.alert, n.alert);
        expect(r.roar, n.roar);
        expect(r.throat, n.throat);
        expect(r.charge, n.charge);
        expect(r.furyBlend, n.furyBlend);
      }
      final f = _at(1.2, fury: true, reduced: true);
      expect(f.furyBlend, 1);
      expect(f.fury, closeTo(.8, 1e-12));
      expect(_at(5.0, reduced: true).inhale, 1);
      expect(_at(5.6, reduced: true).blast, 1);
    });

    test('each non-idle state differs from idle in Reduced Motion', () {
      final idle = _channels(_at(1.2, reduced: true));
      for (final (name, p) in <(String, DragonPose)>[
        ('alert', _at(3.7, reduced: true)),
        ('sniff', _at(4.15, reduced: true)),
        ('rear', _at(4.6, reduced: true)),
        ('hold', _at(5.05, reduced: true)),
        ('snap', _at(5.24, reduced: true)),
        ('blast', _at(5.6, reduced: true)),
        ('gutter', _at(7.3, reduced: true)),
        ('call', _at(7.9, reduced: true)),
        ('fury', _at(1.2, fury: true, reduced: true)),
        ('charge', _pose(_boss(1.2, setup: (b) => b.fireIn = .05), reduced: true)),
        ('hit', _pose(_boss(1.2, setup: (b) => b.lastHitAt = b.age - .14), reduced: true)),
      ]) {
        expect(_channels(p), isNot(idle), reason: name);
      }
    });
  });

  group('no pops: dense sweeps of the whole cycle', () {
    /// Walks the clock in 1 ms steps and flags every channel that JUMPS: a
    /// step whose size is far above both its neighbours (a fast but smooth
    /// move, like the snap, or a change of speed, like a beat beginning,
    /// shows in the neighbours too and is not a pop).
    List<String> pops(
      SkyBoss Function(double t) make,
      double from,
      double to, {
      double dt = 1 / 1000,
      bool reduced = false,
      Set<String> skip = const {},
    }) {
      final rows = <Map<String, double>>[];
      for (var t = from; t <= to + 1e-9; t += dt) {
        rows.add(_channels(_pose(make(t), reduced: reduced)));
      }
      final out = <String>[];
      for (final key in rows.first.keys) {
        if (skip.contains(key)) continue;
        double d(int i) => (rows[i + 1][key]! - rows[i][key]!).abs();
        for (var i = 1; i < rows.length - 2; i++) {
          final here = d(i);
          if (here < .0015) continue;
          final around = math.max(d(i - 1), d(i + 1));
          if (here > 2.5 * around) {
            out.add(
              '$key jumps ${here.toStringAsFixed(4)} in 1 ms at '
              't=${(from + (i + 1) * dt).toStringAsFixed(3)} '
              '(neighbours ${d(i - 1).toStringAsFixed(4)}, ${d(i + 1).toStringAsFixed(4)})',
            );
            break;
          }
        }
      }
      return out;
    }

    // Channels that are events by design: the impact starts at 1 when the
    // jet leaves the jaws; charge is the rules' own countdown and drops to 0
    // at a launch (everything the body does with it goes through `brace`).
    const events = {'impact', 'time', 'charge'};

    test('two whole breath cycles, calm', () {
      expect(pops((t) => _boss(t), 0, 22.5, skip: events), isEmpty);
    });

    test('two whole breath cycles in fury (both calls)', () {
      expect(pops((t) => _boss(t, fury: true), 0, 22.5, skip: events), isEmpty);
    });

    test('every lane, and the same beats in Reduced Motion', () {
      for (final lane in BreathLane.values) {
        expect(
          pops((t) => _boss(t, lane: lane), 3.0, 10.0, skip: events),
          isEmpty,
          reason: 'lane ${lane.name}',
        );
      }
      expect(
        pops((t) => _boss(t), 3.0, 10.0, reduced: true, skip: events),
        isEmpty,
      );
    });

    test('the arrival, to the end of the cinematic', () {
      expect(pops((t) => _arriving(t), 0.001, 4.75, skip: events), isEmpty);
      expect(
        pops((t) => _arriving(t), 0.001, 4.75, reduced: true, skip: events),
        isEmpty,
      );
    });

    test('the fury onset', () {
      SkyBoss onset(double t) => _boss(3.0, fury: true, setup: (b) {
        b.enragedAt = b.age - (t - 3.0);
        b.lastHitAt = b.enragedAt;
      });
      // From before the blow (calm) to well after the roar.
      expect(
        pops(onset, 2.9, 5.0, skip: {...events, 'flash', 'wince'}),
        isEmpty,
      );
    });

    test('a volley: charge, launch and the spring home', () {
      SkyBoss volley(double t) => _boss(1.2, setup: (b) {
        if (t < 0) {
          b.fireIn = -t;
        } else {
          b.fireIn = 1.8;
          b.lastVolleyAt = b.age - t;
        }
      });
      expect(pops(volley, -.7, 1.0, skip: events), isEmpty);
      // (Reduced Motion swaps between still poses at the launch, by design:
      // the head goes from the anchor to rest with no spring in between.)
    });

    test('a volley launched in the middle of the swarm call (the rules do it at 8.0)',
        () {
      // The review found the head's angle popping 27 degrees in one tick at
      // 7.992: the roar's weight followed the raw charge, which the rules
      // reset at the launch. Every channel, at every launch moment of the
      // call (calm 8.0 and fury's second call 9.4, and mid-roar 7.8), is now
      // continuous.
      for (final (base, fury) in const [(8.0, false), (7.8, false), (9.4, true)]) {
        SkyBoss volley(double t) => _boss(base, fury: fury, setup: (b) {
          if (t < 0) {
            b.fireIn = -t;
          } else {
            b.fireIn = 1.8;
            b.lastVolleyAt = b.age - t;
          }
        });
        expect(
          pops(volley, -.7, 1.0, skip: events),
          isEmpty,
          reason: 'launch at $base fury $fury',
        );
        // The head itself, either side of the launch tick.
        final before = _pose(volley(-1e-4));
        final after = _pose(volley(1e-4));
        expect(
          (before.head.angle - after.head.angle).abs(),
          lessThan(.01),
          reason: 'head angle at $base',
        );
        expect((before.head.at - after.head.at).distance, lessThan(.01));
        expect((before.pitch - after.pitch).abs(), lessThan(.005));
        expect((before.bob - after.bob).distance, lessThan(.01));
      }
      // ... and the roar owns the head until the charge is well along, then
      // gives it back after the launch instead of snapping.
      final early = _pose(_boss(7.7, setup: (b) => b.fireIn = .55));
      final free = _pose(_boss(7.7));
      // (a ball only just begun: the roar still has the head)
      expect((early.head.angle - free.head.angle).abs(), lessThan(.05));
      final full = _pose(_boss(7.9, setup: (b) => b.fireIn = .02));
      expect(full.roar, greaterThan(.8));
      // ... a ball nearly out: the head is on the rules' anchor, roar or not.
      expect(full.head.angle, greaterThan(_pose(_boss(7.9)).head.angle + .3));
    });

    test('a hit', () {
      expect(
        pops(
          (t) => _boss(1.2, setup: (b) => b.lastHitAt = b.age - t),
          -.05,
          .5,
          skip: {...events, 'wince'},
        ),
        isEmpty,
      );
    });

    test('a defeat from a calm dragon, mid-hold, mid-blast and mid-roar', () {
      for (final combat in const [1.2, 4.6, 5.05, 5.24, 5.9, 7.9]) {
        expect(
          pops(
            (t) => _boss(combat, setup: (b) => b.defeatedAt = b.age - t),
            -.05,
            2.0,
            // The killing blow ends the rules' state channels outright (the
            // effects layer whitens the frame); the geometry must not jump.
            skip: {
              ...events, 'flash', 'wince', 'inhale', 'blast', 'alert', 'hold',
              'wind', 'roar', 'call', 'lunge', 'brace', 'settle', 'glare',
              'heart', 'throat', 'smoke', 'clutch', 'neckCoil', 'chest',
              'thump', 'legKick', 'spread', 'sag', 'flex0', 'flex3',
              'furyBlend', 'fury', 'drag.x', 'drag.y',
            },
          ),
          isEmpty,
          reason: 'from $combat',
        );
      }
    });
  });

  group('round 2: the body has weight (review of the motion, D3 D4 D5)', () {
    test('idle counter-motion is twice what it was: body .13, head .16 / .08', () {
      double range(double Function(DragonPose) f) {
        var lo = 9.0, hi = -9.0;
        for (var t = 0.4; t < 3.2; t += .004) {
          final v = f(_at(t));
          lo = math.min(lo, v);
          hi = math.max(hi, v);
        }
        return hi - lo;
      }

      // Peak to peak, in rig units (41 px each at 360 px; 250 px dragon).
      expect(range((p) => p.bob.dy), closeTo(.26, .02));
      expect(range((p) => p.head.at.dy), inInclusiveRange(.32, .46));
      expect(range((p) => p.head.angle), inInclusiveRange(.15, .22));
      // The torso's 6 px against a 44 px wing sweep became 11 px.
      expect(range((p) => p.bob.dy) * 41.4 * 250 / 290, greaterThan(9));
    });

    test('the rear-back gathers the whole body, not only the head', () {
      final rest = _at(1.2, reduced: true), rear = _at(5.05, reduced: true);
      final px = 41.4 * 250 / 290;
      expect((rear.head.at.dx - rest.head.at.dx) * px, greaterThan(11));
      expect(rear.bob.dy, 0); // (Reduced Motion: no motion)
      final live = _at(5.05);
      expect(live.bob.dy * px, greaterThan(4)); // sinks
      expect(rear.chest - rest.chest, greaterThan(.19));
      expect(rear.pitch - rest.pitch, greaterThan(.05));
      expect(rear.tailBend(1), lessThan(-.35)); // tail up
      expect(rear.head.angle - rest.head.angle, lessThan(-.5));
    });

    test('the neck shows: chin to chest in the calm poses and the strikes', () {
      // (The fully painted figure is measured in dragon_rig_test.)
      final high = DragonLayout.headHigh, mid = DragonLayout.headMiddle;
      final low = DragonLayout.headLow;
      expect(low.dy, greaterThan(mid.dy));
      expect(mid.dy, greaterThan(high.dy));
      // Each lane's pose is where the layout says and the head keeps clear of
      // the chest front (x -1.38): the lower the strike, the further out.
      expect(low.dx, lessThanOrEqualTo(-1.6));
      expect(mid.dx, lessThanOrEqualTo(-1.5));
      final p = _at(6.3, lane: BreathLane.low);
      expect((p.head.at - low).distance, lessThan(.01));
      expect(p.head.angle, closeTo(DragonLayout.headLowAngle, 1e-9));
    });

    test('the swell of the burn and the wing pump stay inside their windows', () {
      // Nothing of the burn's extra life leaks outside 5.5 .. 7.1.
      final before = _at(5.5), quiet = _at(7.1);
      expect(before.chest - _at(5.49).chest, closeTo(0, .01));
      final a = _at(7.1).nearWing.elbow, b = _at(7.1 + 1e-6).nearWing.elbow;
      expect((a - b).abs(), lessThan(1e-3));
      expect(quiet, isNotNull);
    });
  });

  group('robustness: no time can poison the pose', () {
    test('NaN and infinite timestamps give finite channels', () {
      const bad = [double.nan, double.infinity, double.negativeInfinity];
      final setups = <(String, void Function(SkyBoss, double))>[
        ('age', (b, v) => b.age = v),
        ('fireIn', (b, v) => b.fireIn = v),
        ('lastHitAt', (b, v) => b.lastHitAt = v),
        ('lastVolleyAt', (b, v) => b.lastVolleyAt = v),
        ('lastSummonAt', (b, v) => b.lastSummonAt = v),
        ('enragedAt', (b, v) => b.enragedAt = v),
        ('lastCoreHitAt', (b, v) => b.lastCoreHitAt = v),
        ('defeatedAt', (b, v) => b.defeatedAt = v),
      ];
      for (final (name, set) in setups) {
        for (final v in bad) {
          for (final fury in [false, true]) {
            for (final reduced in [false, true]) {
              final b = _boss(5.3, fury: fury);
              set(b, v);
              final p = _pose(b, reduced: reduced);
              for (final e in _channels(p).entries) {
                expect(
                  e.value.isFinite,
                  isTrue,
                  reason: '${e.key} with $name=$v fury=$fury reduced=$reduced',
                );
              }
              expect(p.tone.key, isA<int>());
              expect(p.head.at.isFinite, isTrue);
              expect(p.toRig(const Offset(1, 1)).isFinite, isTrue);
            }
          }
        }
      }
    });

    test('a NaN sky does not poison the tone', () {
      final b = _boss(1.2);
      final p = DragonPose(
        b,
        BossMotion(b, reducedMotion: false),
        light: const DragonSkyLight(dark: double.nan),
      );
      expect(p.light.dark, 0);
      expect(p.tone.dark.isFinite, isTrue);
      // ... and the sanitised boss paints the same as the one it stands for.
      final ok = _boss(1.2);
      final bad = _boss(1.2)..lastHitAt = double.nan;
      expect(_channels(_pose(bad)), _channels(_pose(ok)));
    });

    test('finite bosses are used as they are, and huge ages stay finite', () {
      for (final age in [-1e6, -5.0, 0.0, 1e3, 1e9, 1e15]) {
        final b = _boss(0)..age = age;
        final p = _pose(b);
        for (final e in _channels(p).entries) {
          expect(e.value.isFinite, isTrue, reason: '${e.key} at age $age');
        }
      }
    });
  });

  group('tone override (the prewarm)', () {
    test('withTone changes the look and nothing else', () {
      final p = _at(5.6);
      const t = DragonTone(flash: .5, fury: .25, heat: .75, dark: .5);
      final q = p.withTone(t);
      // The parts always see a tone on the ladder (DragonTone.snapped).
      expect(q.tone.key, t.snapped().key);
      expect(q.tone.flash, .5);
      expect(q.tone.fury, .25);
      expect(q.tone.heat, .75);
      expect(q.light.dark, .5);
      final a = _channels(p), c = _channels(q);
      for (final k in a.keys) {
        if (k == 'flash' || k == 'fury' || k == 'furyBlend') continue;
        expect(c[k], a[k], reason: k);
      }
      expect(p.tone.key, isNot(q.tone.key));
    });

    test('arriving is the first four seconds only', () {
      expect(_pose(_arriving(1)).arriving, isTrue);
      expect(_pose(_arriving(4.5)).arriving, isTrue);
      expect(_pose(_boss(0)).arriving, isFalse);
      expect(_at(1.2).arriving, isFalse);
      expect(_at(1.2, setup: (b) => b.defeatedAt = b.age - .1).arriving, isFalse);
    });
  });

  group('the seams between rules and pose', () {
    test('the pose reads the rules\' own clocks and no other', () {
      // Lane, look and light are the only inputs beyond the boss and its
      // BossMotion; two BossMotions with the same reducedMotion agree.
      final b = _boss(5.05);
      final p1 = DragonPose(b, BossMotion(b, reducedMotion: false));
      final p2 = DragonPose(b, BossMotion(b, reducedMotion: false));
      expect(_channels(p1), _channels(p2));
    });

    test('older replays without swarm calls get no call clock', () {
      for (var t = 7.0; t < 9.9; t += .1) {
        final p = _at(t, calls: false);
        expect(p.wind, 0);
        expect(p.call, 0);
      }
    });

    test('the mouth anchor holds in every state the rules can charge in', () {
      // The rules hold fireballs from 3.0 to 8.0 (quiet, then the refire),
      // so those are the only moments a ball can leave.
      for (final combat in const [0.5, 1.2, 2.5, 2.95, 8.0, 8.4, 9.5, 10.9]) {
        for (final fury in [false, true]) {
          final p = _pose(
            _boss(combat, fury: fury, setup: (b) => b.fireIn = 1e-6),
          );
          expect(
            (p.headPoint(DragonLayout.headMouth) - DragonLayout.rulesMouth).distance,
            lessThan(.011),
            reason: 'combat $combat fury $fury',
          );
        }
      }
    });
  });
}
