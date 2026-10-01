import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

import 'king_coo_test_kit.dart';

/// King Coo's pose channels: pure functions of the boss state, continuous (no
/// pops), bounded, finite, and still readable under Reduced Motion. See the
/// table in `king_coo_pose.dart`.

typedef _Scenario = (String name, SkyBoss Function(double t) at, double from, double to);

/// A boss at boss age [age] in a scenario whose history is fixed by [setup].
SkyBoss _at(double age, {bool fury = false, Setup? setup}) {
  final b = SkyBoss(number: 6, x: 2, kind: BossKind.kingCoo, cinematic: true);
  if (fury) {
    b.hp = b.maxHp ~/ 2;
    b.enragedAt = 4.6 + 3.0;
  }
  setup?.call(b);
  b.age = age;
  return b;
}

List<_Scenario> _scenarios() {
  const a = 4.6;
  return [
    ('arrival and calm', (t) => _at(t), 0, a + 15),
    (
      'lobs',
      (t) => _at(
        t,
        setup: (b) => b.lobs.addAll([
          lobAt(a + .6),
          lobAt(a + 3.0),
          lobAt(a + 14 + .6, y: .3),
        ]),
      ),
      a,
      a + 22,
    ),
    (
      'fury lobs',
      (t) => _at(
        t,
        fury: true,
        setup: (b) => b.lobs.addAll([
          lobAt(a + .6, fury: true),
          lobAt(a + 2.4, fury: true),
          lobAt(a + 4.2, fury: true),
        ]),
      ),
      a,
      a + 15,
    ),
    ('fury', (t) => _at(t, fury: true), a, a + 16),
    (
      'hits',
      (t) => _at(t, setup: (b) => b.lastHitAt = a + 2.0),
      a + 1.5,
      a + 4,
    ),
    (
      'hit in the window',
      (t) => _at(t, setup: (b) => b.lastHitAt = a + 9.0),
      a + 8.5,
      a + 10,
    ),
    (
      'pop before the whistle',
      (t) => _at(t, setup: (b) => b.poppedAt = a + 8.3),
      a + 7,
      a + 14.5,
    ),
    (
      'pop after the whistle',
      (t) => _at(t, setup: (b) => b.poppedAt = a + 9.5),
      a + 7,
      a + 14.5,
    ),
    (
      'fury pop',
      (t) => _at(
        t,
        fury: true,
        setup: (b) => b.poppedAt = a + 8.9,
      ),
      a + 7,
      a + 14.5,
    ),
    (
      'defeat from calm',
      (t) => _at(t, setup: (b) => b.defeatedAt = a + 1.2),
      a + 1.2,
      a + 1.2 + 3.8,
    ),
    (
      'defeat from the window',
      (t) => _at(
        t,
        fury: true,
        setup: (b) {
          b.defeatedAt = a + 9.0;
          b.lobs.add(lobAt(a + 8.0));
        },
      ),
      a + 9.0,
      a + 9.0 + 3.8,
    ),
    (
      'defeat mid throw',
      (t) => _at(
        t,
        setup: (b) {
          b.lobs.add(lobAt(a + 1.0));
          b.defeatedAt = a + 1.6;
        },
      ),
      a + 1.6,
      a + 1.6 + 3.8,
    ),
  ];
}

/// The most a channel may move per second before it is a pop (radians or rig
/// units per second). The designed snaps are fast but not instant: the toss
/// swings 3.3 rad in .14 s (38 rad/s at the end), the stomp drops the body
/// .14 in .125 s, the hit's bite is .03 s.
const _maxSlope = <String, double>{
  'wingNear': 50,
  'wingFar': 50,
  'flash': 30,
  'wince': 60,
  'eyeGlint': 45,
  'beak': 40,
  'dizzy': 40,
  'squint': 60,
  'whistleAt.x': 40,
  'whistleAt.y': 40,
};
const _defaultSlope = 25.0;

// Channels that change hands at a designed instant (and are exempt).
// `shock` is the progress of a one-shot ring (it ends at 1 and is gone).
const _event = <String>{'bombSpin', 'shock'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('purity', () {
    test('the same state gives the same channels, every time', () {
      for (final (name, at, from, to) in _scenarios()) {
        for (var i = 0; i <= 40; i++) {
          final t = from + (to - from) * i / 40;
          final boss = at(t);
          final a = poseOf(boss).values, b = poseOf(boss).values;
          expect(a, b, reason: '$name at $t');
        }
      }
    });

    test('a pose does not depend on what was asked before it', () {
      final forward = <double, Map<String, double>>{};
      final ages = [for (var i = 0; i < 60; i++) 4.6 + i * .37];
      for (final t in ages) {
        forward[t] = poseOf(_at(t, fury: t > 20)).values;
      }
      for (final t in ages.reversed) {
        expect(poseOf(_at(t, fury: t > 20)).values, forward[t], reason: '$t');
      }
    });

    test('`at` asks the same boss at another age', () {
      final base = _at(4.6 + 3.0, setup: (b) => b.lobs.add(lobAt(4.6 + 2.5)));
      for (final when in [4.6 + 2.6, 4.6 + 3.3, 4.6 + 3.45, 4.6 + 6.0]) {
        final other = _at(when, setup: (b) => b.lobs.add(lobAt(4.6 + 2.5)));
        expect(poseOf(base, at: when).values, poseOf(other).values, reason: '$when');
      }
    });

    test('a boss the clock has broken still gets a finite pose', () {
      for (final mutate in <void Function(SkyBoss)>[
        (b) => b.age = double.nan,
        (b) => b.age = double.infinity,
        (b) => b.lastHitAt = double.nan,
        (b) => b.lastHitAt = double.infinity,
        (b) => b.enragedAt = double.nan,
        (b) => b.poppedAt = double.nan,
        (b) => b.defeatedAt = double.nan,
        (b) => b.lobs.add(CrumbLob(lockedAt: double.nan, lockX: .47, lockY: .5)),
        (b) => b.lobs.add(CrumbLob(lockedAt: 5, lockX: double.infinity, lockY: .5)),
      ]) {
        final boss = _at(4.6 + 5.0);
        mutate(boss);
        final pose = poseOf(boss);
        for (final MapEntry(:key, :value) in pose.values.entries) {
          expect(value.isFinite, isTrue, reason: key);
        }
        expect(pose.bob.distance.isFinite, isTrue);
      }
    });
  });

  group('ranges', () {
    test('every channel is finite and bounded across the whole fight', () {
      for (final reduced in [false, true]) {
        for (final (name, at, from, to) in _scenarios()) {
          for (var i = 0; i <= 600; i++) {
            final t = from + (to - from) * i / 600;
            final p = poseOf(at(t), reduced: reduced);
            final why = '$name t=${t.toStringAsFixed(2)} reduced=$reduced';
            for (final MapEntry(:key, :value) in p.values.entries) {
              expect(value.isFinite, isTrue, reason: '$key $why');
            }
            expect(p.bob.distance, lessThanOrEqualTo(.3001), reason: why);
            for (final (n, v) in [
              ('beak', p.beak),
              ('cheek', p.cheek),
              ('squint', p.squint),
              ('anger', p.anger),
              ('worry', p.worry),
              ('dizzy', p.dizzy),
              ('whistle', p.whistle),
              ('blast', p.blast),
              ('squadCue', p.squadCue),
              ('sirenGlow', p.sirenGlow),
              ('fury', p.fury),
              ('heat', p.heat),
              ('steam', p.steam),
              ('silhouette', p.silhouette),
              ('opacity', p.opacity),
              ('armThrow', p.armThrow),
              ('windup', p.windup),
              ('follow', p.follow),
              ('roar', p.roar),
              ('stomp', p.stomp),
            ]) {
              expect(v, inInclusiveRange(-1e-9, 1 + 1e-9), reason: '$n $why');
            }
            expect(p.wingStretch, inInclusiveRange(1, 1.26), reason: why);
            expect(p.pitch.abs(), lessThan(.25), reason: why);
            expect(p.roll.abs(), lessThan(.25), reason: why);
            expect(p.swell, inInclusiveRange(1, 1.1201), reason: why);
            if (!p.defeated) {
              expect(p.puff, inInclusiveRange(0, 1.04), reason: 'puff $why');
            }
            expect(p.puff, inInclusiveRange(0, 1.3001), reason: 'puff $why');
            expect(p.siren, inInclusiveRange(0, 2));
          }
        }
      }
    });

    test('the chest is the hit circle exactly when puffed, .84 fluffed', () {
      expect(KingCooLayout.chestRadiusAt(0), .84);
      expect(KingCooLayout.chestRadiusAt(1), 1.0);
      expect(KingCooPose.still.puff, 0);
      // Taut before the whistle (front-loaded swell): at 8.6 s (1 s into the
      // 1.6 s inhale) the chest is past 90% of the way.
      final p = poseOf(cooBoss(combat: 8.6), reduced: true);
      expect(p.chestRadius, greaterThan(.98));
      expect(poseOf(cooBoss(combat: 9.2), reduced: true).chestRadius, 1.0);
      expect(poseOf(cooBoss(combat: 7.5), reduced: true).puff, 0);
      // Released by 10.4.
      expect(poseOf(cooBoss(combat: 10.45), reduced: true).puff, 0);
    });
  });

  group('continuity (no pops)', () {
    test('no channel jumps: every scenario, sampled every 1/480 s', () {
      const dt = 1 / 480;
      final worst = <String, (double, String)>{};
      final failures = <String>[];
      for (final reduced in [false, true]) {
        for (final (name, at, from, to) in _scenarios()) {
          Map<String, double>? last;
          Offset? lastCap;
          var t = from;
          while (t <= to) {
            final p = poseOf(at(t), reduced: reduced);
            final v = p.values;
            final cap = p.capLift;
            if (last != null) {
              for (final MapEntry(:key, :value) in v.entries) {
                if (_event.contains(key)) continue;
                final step = (value - last[key]!).abs();
                final slope = step / dt;
                final limit = _maxSlope[key] ?? _defaultSlope;
                final tag = '$name t=${t.toStringAsFixed(3)} reduced=$reduced';
                if (slope > (worst[key]?.$1 ?? 0)) worst[key] = (slope, tag);
                if (slope > limit) {
                  failures.add('$key jumps ${step.toStringAsFixed(3)} in 1/480 s at $tag');
                }
              }
              expect((cap - lastCap!).distance / dt, lessThan(40), reason: name);
            }
            last = v;
            lastCap = cap;
            t += dt;
          }
        }
      }
      // ignore: avoid_print
      print(
        'fastest channels (per s): ${(worst.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1))).take(8).map((e) => '${e.key} ${e.value.$1.toStringAsFixed(1)} @ ${e.value.$2}').join('; ')}',
      );
      expect(failures.take(12), isEmpty);
    });

    test('the cap spins continuously (modulo a full turn)', () {
      const dt = 1 / 480;
      for (final reduced in [false, true]) {
        double? last;
        var t = 4.6 + 8.0;
        while (t < 4.6 + 13) {
          final p = poseOf(
            _at(t, setup: (b) => b.poppedAt = 4.6 + 8.3),
            reduced: reduced,
          );
          final a = p.capSpin;
          if (last != null) {
            final d = math.atan2(math.sin(a - last), math.cos(a - last)).abs();
            expect(d / dt, lessThan(60), reason: 't=$t');
          }
          last = a;
          t += dt;
        }
      }
    });

    test('the throw: the wing tip reaches the release anchor AT the launch', () {
      for (final y in [.2, .5, .8]) {
        final launch = 4.6 + 1.4;
        final boss = _at(
          launch,
          setup: (b) => b.lobs.add(lobAt(launch - .8, y: y)),
        );
        for (final reduced in [false, true]) {
          final p = poseOf(boss, reduced: reduced);
          final tip = p.handAt;
          expect(
            (tip - KingCooLayout.lobRelease).distance,
            lessThan(KingCooLayout.lobReleaseTolerance),
            reason: 'tip $tip at launch',
          );
          expect(p.wingStretch, closeTo(1, 1e-9));
          // The same point through the rig, asked at the launch from later.
          final later = _at(
            launch + .05,
            setup: (b) => b.lobs.add(lobAt(launch - .8, y: y)),
          );
          final q = poseOf(later, reduced: reduced, at: launch);
          expect(KingCooBossRig.bombOrigin(q), KingCooBossRig.bombOrigin(p));
        }
      }
    });

    test('the throw order: dip into the sack, backswing, hold, swing, whip, home', () {
      const launch = 4.6 + 1.4;
      double angleAt(double ago) => poseOf(
        _at(launch - ago, setup: (b) => b.lobs.add(lobAt(launch - .8))),
        reduced: true,
      ).wingNear;
      // RM: the hover is still, so the angles are the pure throw.
      expect(angleAt(.8), closeTo(KingCooLayout.restWingNear, 1e-6));
      expect(angleAt(.56), closeTo(KingCooLayout.windupDip, .05)); // the dip's end
      expect(angleAt(.34), closeTo(KingCooLayout.windupBack, .05)); // backswing
      expect(angleAt(.25), closeTo(KingCooLayout.windupBack, .05)); // hold
      expect(angleAt(0), closeTo(KingCooLayout.tossRelease, 1e-6)); // release
      expect(angleAt(-.12), greaterThan(KingCooLayout.tossRelease)); // overshoot
      expect(angleAt(-.9), closeTo(KingCooLayout.restWingNear, 1e-6)); // home
      // The bomb is in his hand from the dip's end until the release.
      bool held(double ago) => poseOf(
        _at(launch - ago, setup: (b) => b.lobs.add(lobAt(launch - .8))),
        reduced: true,
      ).bombHeld >
          0;
      expect(held(.7), isFalse);
      expect(held(.4), isTrue);
      expect(held(.001), isTrue);
      expect(held(-.05), isFalse);
    });

    test('the pop: before the whistle it cancels the lanes, after it keeps them', () {
      const a = 4.6;
      double cue(double pop, double when) => poseOf(
        _at(a + when, setup: (b) => b.poppedAt = pop < 0 ? null : a + pop),
      ).squadCue;
      expect(cue(-1, 9.6), greaterThan(.9));
      expect(cue(8.0, 9.6), 0);
      expect(cue(9.4, 9.6), greaterThan(.9));
      // The puff collapses with the pop; a squashed chest recovers by ~4 s.
      final popped = poseOf(_at(a + 9.0, setup: (b) => b.poppedAt = a + 8.5));
      expect(popped.puff, lessThan(.05));
      expect(popped.deflate, greaterThan(.4));
      expect(popped.dizzy, 1);
      final later = poseOf(_at(a + 12.5, setup: (b) => b.poppedAt = a + 8.5));
      expect(later.deflate, 0);
      expect(later.dizzy, 0);
      // The next cycle's window starts fresh.
      final next = poseOf(_at(a + 14 + 9.0, setup: (b) => b.poppedAt = a + 8.5));
      expect(next.puff, greaterThan(.9));
      expect(next.dizzy, 0);
    });

    test('fury eases in over .45 s, the stomp lasts .25 s, the beat stays in phase', () {
      const a = 4.6;
      final start = a + 3.0;
      double fury(double after) => poseOf(_at(start + after, fury: true)).fury;
      expect(fury(-.01), 0);
      expect(fury(.225), closeTo(.5, .03));
      expect(fury(.45), closeTo(1, 1e-9));
      double stomp(double after) => poseOf(_at(start + after, fury: true)).stomp;
      expect(stomp(.125), closeTo(1, 1e-9));
      expect(stomp(.3), 0);
      // The beat's phase is continuous through the onset.
      final before = poseOf(_at(start - 1e-6, fury: true)).beatPhase;
      final after = poseOf(_at(start + 1e-6, fury: true)).beatPhase;
      expect((after - before).abs(), lessThan(1e-3));
      // ...and runs 2.1/1.6 faster afterwards.
      final p1 = poseOf(_at(start + 1.0, fury: true)).beatPhase;
      final p2 = poseOf(_at(start + 2.0, fury: true)).beatPhase;
      expect(p2 - p1, closeTo(2 * math.pi * 2.1, 1e-6));
    });
  });

  group('Reduced Motion', () {
    test('the motion channels are zero, the figure holds still', () {
      for (final t in [1.2, 2.0, 3.3, 5.0, 6.1]) {
        final p = poseOf(cooBoss(combat: t), reduced: true);
        final rest = KingCooPose.still;
        expect(p.bob, Offset.zero);
        expect(p.roll, 0);
        expect(p.beatPhase, 0);
        expect(p.pedal, 0);
        expect(p.tailWag, 0);
        expect(p.sackSwing, 0);
        expect(p.blink, 0);
        expect(p.steam, 0);
        expect(p.head, Offset.zero);
        expect(p.capTilt, -.05);
        expect(p.values, rest.values, reason: 'idle frames identical at $t');
        expect(p.beatAt(.1), 0);
      }
    });

    test('...and every non-idle state is still distinguishable from idle', () {
      final rest = KingCooPose.still.values;
      Map<String, double> vals(SkyBoss b) => poseOf(b, reduced: true).values;
      final states = <String, SkyBoss>{
        'wind-up': cooBoss(
          combat: 1.0,
          setup: (b) => b.lobs.add(lobAt(b.age - .5)),
        ),
        'hold': cooBoss(
          combat: 1.0,
          setup: (b) => b.lobs.add(lobAt(b.age - .7)),
        ),
        'whip': cooBoss(
          combat: 1.0,
          setup: (b) => b.lobs.add(lobAt(b.age - .95)),
        ),
        'inhale': cooBoss(combat: 8.3),
        'puffed': cooBoss(combat: 9.0),
        'whistle raised': cooBoss(combat: 8.9),
        'whistle blown': cooBoss(combat: 9.3),
        'pop': cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .6),
        'fury': cooBoss(combat: 1.2, fury: true),
        'hit': cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .1),
        'arrival roar': arrivingBoss(3.0),
        'arrival rear': arrivingBoss(2.55),
        'arrival silhouette': arrivingBoss(1.0),
        'defeat inflating': dyingBoss(.6),
        'defeat popped': dyingBoss(1.0),
      };
      for (final MapEntry(:key, :value) in states.entries) {
        final v = vals(value);
        var worst = 0.0;
        for (final k in rest.keys) {
          worst = math.max(worst, (v[k]! - rest[k]!).abs());
        }
        expect(worst, greaterThan(.05), reason: '$key looks like idle');
      }
    });

    test('state survives: siren colour, flash at .3, fury at once, lanes up', () {
      expect(poseOf(cooBoss(combat: 8.4), reduced: true).siren, 2);
      expect(poseOf(cooBoss(combat: 9.4), reduced: true).siren, 1);
      final hit = cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .14);
      expect(poseOf(hit, reduced: true).flash, closeTo(.3, 1e-9));
      expect(poseOf(hit, reduced: false).flash, lessThan(.56));
      expect(poseOf(cooBoss(combat: 1.2, fury: true), reduced: true).fury, 1);
      expect(poseOf(cooBoss(combat: 9.0), reduced: true).squadCue, 1);
      expect(poseOf(cooBoss(combat: 9.2), reduced: true).puff, 1);
    });

    test('Reduced Motion and motion agree on state (same puff, whistle, cue)', () {
      for (final t in [7.7, 8.4, 8.8, 9.0, 9.5, 10.2]) {
        final a = poseOf(cooBoss(combat: t), reduced: true);
        final b = poseOf(cooBoss(combat: t));
        expect(a.whistle, b.whistle, reason: '$t');
        expect(a.squadCue, b.squadCue, reason: '$t');
        expect(a.puff, closeTo(b.puff, .031), reason: '$t (3% overshoot)');
      }
    });
  });

  group('anchors', () {
    test('the rest pose sits on the layout numbers', () {
      final p = KingCooPose.still;
      expect(KingCooBossRig.chestCenter(p), Offset.zero);
      expect(
        (KingCooBossRig.eyeAt(p) - KingCooLayout.eyeRest).distance,
        lessThan(.01),
      );
      expect(
        (KingCooBossRig.beakAt(p) - KingCooLayout.beakTipRest).distance,
        lessThan(.01),
      );
      expect(
        (p.capPoint(KingCooLayout.headCapSeat) - KingCooLayout.capSeatRest)
            .distance,
        lessThan(.01),
      );
      expect(
        (KingCooBossRig.sirenAt(p) - KingCooLayout.sirenRest).distance,
        lessThan(.01),
      );
      // The whistle hangs at its resting place, and is in the beak when raised.
      expect(
        (KingCooBossRig.whistleAt(p) - KingCooLayout.whistleRest).distance,
        lessThan(.01),
      );
      final blown = poseOf(cooBoss(combat: 9.0), reduced: true);
      expect(blown.whistle, 1);
      expect(
        (blown.whistleAt - (blown.headPoint(KingCooLayout.headWhistle) + const Offset(-.02, .05))).distance,
        lessThan(.01),
      );
    });

    test('anchors move with the figure (bob, roll, pitch, swell, squash)', () {
      final p = poseOf(arrivingBoss(2.9));
      expect(p.swell, greaterThan(1.05));
      final eye = KingCooBossRig.eyeAt(p);
      final manual = p.toRig(p.headPoint(KingCooLayout.headEye));
      expect(eye, manual);
      // toRig is exactly the canvas transform the rig paints under.
      final local = const Offset(1.3, -.7);
      final expected = KingCooLayout.turn(
            Offset(local.dx * p.scaleX, local.dy * p.scaleY),
            p.roll + p.pitch,
          ) +
          p.bob;
      expect(p.toRig(local), expected);
    });

    test('the eye, beak and whistle never go under the health bar', () {
      var highestEye = 99.0, highestBeak = 99.0;
      final offenders = <String>[];
      for (final reduced in [false, true]) {
        for (final (name, at, from, to) in _scenarios()) {
          for (var i = 0; i <= 300; i++) {
            final t = from + (to - from) * i / 300;
            final p = poseOf(at(t), reduced: reduced);
            if (p.arriving || p.defeated) continue;
            final eye = KingCooBossRig.eyeAt(p),
                beak = KingCooBossRig.beakAt(p),
                whistle = KingCooBossRig.whistleAt(p);
            highestEye = math.min(highestEye, eye.dy);
            highestBeak = math.min(highestBeak, beak.dy);
            if (eye.dx < KingCooLayout.healthBarRight &&
                eye.dy - .14 < KingCooLayout.healthBarClearance) {
              offenders.add('$name ${t.toStringAsFixed(2)}: eye ${eye.dy}');
            }
            if (beak.dy - .12 < KingCooLayout.healthBarClearance ||
                whistle.dy - .12 < KingCooLayout.healthBarClearance) {
              offenders.add('$name ${t.toStringAsFixed(2)}: beak/whistle');
            }
          }
        }
      }
      // ignore: avoid_print
      print(
        'eye top ${highestEye.toStringAsFixed(2)}, beak top ${highestBeak.toStringAsFixed(2)}, '
        'bar clearance ${KingCooLayout.healthBarClearance}',
      );
      expect(offenders.take(8), isEmpty);
    });

    test('the falling cap starts exactly where the cap is', () {
      for (final reduced in [false, true]) {
        final boss = dyingBoss(0, at: 1.2);
        final died = boss.defeatedAt!;
        // The exact way: the pose of the boss that really died, at .3 s.
        final exact = KingCooBossRig.capAt(
          poseOf(boss, reduced: reduced, at: died + .3),
        );
        final real = dyingBoss(.3, at: 1.2);
        final cap = KingCooBossRig.capAt(poseOf(real, reduced: reduced));
        expect((cap.at - exact.at).distance, lessThan(1e-9));
        expect(cap.angle, closeTo(exact.angle, 1e-9));
        expect(poseOf(dyingBoss(.35), reduced: reduced).capOff, isTrue);
        expect(poseOf(dyingBoss(.25), reduced: reduced).capOff, isFalse);
        // The generic helper is the same place for any boss, however he died.
        final drop = KingCooBossRig.capDrop(.3, reduced: reduced);
        expect((cap.at - drop.at).distance, lessThan(1e-6));
        expect((cap.angle - drop.angle).abs(), lessThan(1e-6));
        for (final state in [
          dyingBoss(.3, at: 9.0, fury: true),
          dyingBoss(.3, at: 7.2),
        ]) {
          final c = KingCooBossRig.capAt(poseOf(state, reduced: reduced));
          expect((c.at - drop.at).distance, lessThan(1e-6));
        }
      }
    });
  });

  group('story poses', () {
    test('every mood and the beaten pose are finite and distinct', () {
      final seen = <String>{};
      for (final mood in KingCooMood.values) {
        for (final beaten in [false, true]) {
          final p = KingCooPose.story(mood, beaten: beaten, talk: .5);
          for (final MapEntry(:key, :value) in p.values.entries) {
            expect(value.isFinite, isTrue, reason: '$mood $key');
          }
          expect(p.capOff, beaten);
          expect(p.bob, Offset.zero);
          expect(seen.add(p.values.toString()), isTrue, reason: '$mood $beaten');
        }
      }
      final talk = KingCooPose.story(KingCooMood.plain, talk: 1);
      expect(talk.beak, greaterThan(.4));
      expect(KingCooPose.story(KingCooMood.plain, blink: 1).blink, 1);
    });
  });

  test('BossMotion and the pose agree on the hit and the roar', () {
    final boss = cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .1);
    final m = BossMotion(boss, reducedMotion: false);
    expect(poseOf(boss).wince, closeTo(BossMotion.ramp(m.hit, .2, .5), 1e-9));
    final arriving = arrivingBoss(3.0);
    expect(
      poseOf(arriving).roar,
      closeTo(BossMotion(arriving, reducedMotion: false).roar, 1e-9),
    );
  });
}
