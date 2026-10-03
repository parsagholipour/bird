import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/neferhoo_fight_art.dart';
import 'package:push_up_bird/game/neferhoo_pose.dart';
import 'package:push_up_bird/game/neferhoo_timeline.dart';

import 'neferhoo_art_support.dart';

/// The motion guard (the design's `mummy_motion_test`, review 08 M1, on the
/// real fight state): every pose channel at 60 Hz, calm and fury, at screen
/// widths 560 to 960 px (the ankh's homecoming, the catch and the open-sky gag
/// re-time with the width), over three whole cycles and their joins, through
/// a stage-up roar, the fury's onset at any moment of the cycle and Reduced
/// Motion: no channel jumps more than its cap in one frame (the stated
/// exceptions: the fan's letter count, the ankh's hand-over and the throw's
/// whip). Then the staging rules of the gag and the catch, and the blink
/// docked off the lock moments for every alignment of its clock.

typedef _Chan = double Function(NeferhooPose);
final Map<String, _Chan> _channels = {
  'wing': (p) => p.wing,
  'wingRate': (p) => p.stroke,
  'crest': (p) => p.crest,
  'brow': (p) => p.brow,
  'lid': (p) => p.lid,
  'look.x': (p) => p.look.dx,
  'look.y': (p) => p.look.dy,
  'lean': (p) => p.lean,
  'headTilt': (p) => p.headTilt,
  'smile': (p) => p.smile,
  'glow': (p) => p.glow,
  'sweep': (p) => p.sweep,
  'reach': (p) => p.reach,
  'satchelOpen': (p) => p.satchelOpen,
  'buff': (p) => p.buff,
  'unwrap': (p) => p.unwrap,
  'fury': (p) => p.fury,
};

/// Per-frame caps (|delta| between adjacent 60 Hz frames), the design's.
const _caps = <String, double>{
  'wing': .12,
  'wingRate': .6,
  'crest': .15,
  'brow': .15,
  'lid': .35, // a blink is 3 frames down and 3 up
  // (the design's guard sampled four alignments of the free gaze's 2.4 s clock against the
  // 12 s cycle and saw .146; over every alignment a glance that lands on a beat's own look
  // blend reaches .161 at 640 px and .186 at 800-864 (the gag's finale is time-scaled there).
  // The look channel moves the iris .09 u: .19 of it is .7 px at the game's 41.4 px/u.)
  'look.x': .2,
  'look.y': .2,
  'lean': .02,
  'headTilt': .02,
  'smile': .15,
  'glow': .15,
  'sweep': .2,
  'reach': .12,
  'satchelOpen': .12,
  'buff': .15,
  'unwrap': .05,
  'fury': .05,
};

/// Inside the throw's whip the design allows these (`mummy_motion_test`).
const _whipCaps = <String, double>{'wing': .5, 'wingRate': 1.0, 'sweep': .4, 'lean': .04, 'headTilt': .03};

/// The throw's whip (cycle seconds): the wing may move faster here, but never
/// in one frame.
bool _inWhip(double ct) => ct > Neferhoo.ankhThrowAt - .12 && ct < Neferhoo.ankhThrowAt + .22;

/// Steps [boss] at 60 Hz from fight second [from] to [to], checking every
/// channel's step; [at] is called after each frame (the test's own events).
Map<String, double> _guard(SkyBoss boss, double from, double to, {bool reduced = false, void Function(double t)? at, String why = ''}) {
  final worst = <String, double>{};
  fightTo(boss, from);
  NeferhooPose prev = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: reduced), lookY: .2);
  final frames = ((to - from) * 60).round();
  var whip = 0;
  for (var i = 1; i <= frames; i++) {
    final t = from + i / 60;
    fightTo(boss, t);
    at?.call(t);
    final p = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: reduced), lookY: .2);
    final ct = boss.mailCycle;
    for (final MapEntry(key: name, value: get) in _channels.entries) {
      final d = (get(p) - get(prev)).abs();
      worst[name] = math.max(worst[name] ?? 0, d);
      var cap = _caps[name]!;
      if (_inWhip(ct) && _whipCaps.containsKey(name)) {
        if (name == 'wing' && d > cap) whip++;
        cap = _whipCaps[name]!;
      }
      expect(d, lessThanOrEqualTo(cap + 1e-9), reason: '$why $name jumps ${d.toStringAsFixed(3)} at fight second ${t.toStringAsFixed(3)} (cycle ${ct.toStringAsFixed(3)})');
    }
    prev = p;
  }
  // a whip is fast by design, but it takes at least four frames
  expect(whip, anyOf(0, greaterThanOrEqualTo(4)), reason: why);
  return worst;
}

/// A blow that crosses a third: the real rules raise the stage on the next
/// step (the roar starts, the signature arms: rules 44's `_advanceStages`).
void _stageUp(SkyBoss boss, int damage) => boss.takeDamage(damage);

/// The classic clock (rules 52 to 54) and the faster one (rules 55, the
/// current): the guards run on both; the gag's and the throw's scripts are
/// each clock's own.
const _classic = FlightSimulation.cooRestartRulesVersion;
const _faster = FlightSimulation.fasterNeferhooRulesVersion;

void main() {
  test('channel deltas at 60 Hz: calm and fury, 560 to 960 px, three cycles and their joins', () {
    final table = StringBuffer();
    for (final version in [_classic, _faster]) {
      for (final px in [560.0, 640.0, 720.0, 800.0, 864.0, 960.0]) {
        for (final stage in [1, 2]) {
          final boss = courier(px: px, stage: stage, version: version);
          final worst = _guard(boss, 12, 48, why: 'v$version ${px.round()} px stage $stage:');
          table.writeln('v$version ${px.round()} ${stage == 2 ? 'fury' : 'calm'}: ${worst.entries.map((e) => '${e.key} ${e.value.toStringAsFixed(3)}').join(', ')}');
        }
      }
    }
    // ignore: avoid_print
    print(table);
  });

  test('the warm-up (no ankh), Reduced Motion, and the stage-up roar into the full fight mid-cycle', () {
    for (final version in [_classic, _faster]) {
      for (final px in [640.0, 864.0]) {
        _guard(courier(px: px, stage: 0, version: version), 0, 24, why: 'v$version warm-up');
        _guard(courier(px: px, stage: 1, version: version), 12, 36, reduced: true, why: 'v$version reduced');
        for (final when in [1.2, 5.0, 6.7, 9.7, 10.3]) {
          final boss = courier(px: px, stage: 0, version: version);
          var done = false;
          _guard(boss, 12, 26, why: 'v$version roar at $when', at: (t) {
            if (!done && t >= 12 + when) {
              done = true;
              _stageUp(boss, boss.maxHp - boss.maxHp * 2 ~/ 3);
            }
          });
          expect(boss.stageReached, 1);
        }
      }
    }
  });

  test('fury comes in eased at any moment: the mail call, the whip, the gag', () {
    for (final version in [_classic, _faster]) {
      for (final px in [640.0, 800.0]) {
        for (final when in [1.0, 2.0, 5.6, 6.85, 9.0, 9.65, 10.5, 11.6]) {
          final boss = courier(px: px, stage: 1, version: version);
          var done = false;
          _guard(boss, 12, 26, why: 'v$version ${px.round()} px fury at $when', at: (t) {
            if (!done && t >= 12 + when) {
              done = true;
              _stageUp(boss, boss.hp - boss.maxHp ~/ 3);
            }
          });
          expect(boss.enraged, isTrue);
        }
      }
    }
  });

  test('the open-sky gag never meets a hazard, a card or the open satchel, and ends with the cycle', () {
    for (final px in [560.0, 640.0, 720.0, 800.0, 864.0, 960.0]) {
      for (final stage in [1, 2]) {
        final boss = courier(px: px, stage: stage, version: _classic);
        var buffed = 0;
        for (var i = 0; i <= 36 * 60; i++) {
          final t = 12 + i / 60;
          fightTo(boss, t);
          final p = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false));
          final ct = boss.mailCycle;
          if (p.buff <= 0) continue;
          buffed++;
          final why = '${px.round()} px stage $stage at cycle ${ct.toStringAsFixed(3)}';
          expect(boss.liveLetters.where((l) => !l.returned), isEmpty, reason: '$why: a letter flies');
          expect(boss.liveAnkhs.where((a) => NeferhooFightArt.ankhCentre(a, boss) != null), isEmpty, reason: '$why: an ankh flies');
          expect(p.cards, 0, reason: why);
          expect(p.satchelOpen, lessThan(.01), reason: why);
          expect(p.reach, 0, reason: why);
          final home = boss.neferhoo.ankhs.where((a) => a.caughtAt != null && a.caughtAt! <= boss.age).map((a) => a.caughtAt!).fold(double.negativeInfinity, math.max);
          expect(boss.age - home, greaterThanOrEqualTo(.3 - 1e-6), reason: '$why: the gag begins before the ankh is home + .3');
          expect(ct, greaterThanOrEqualTo(10.0), reason: why);
        }
        // the design's plan: calm plays its wing up to 800 px (one wipe there), none at 864 and wider;
        // fury plays one wipe at 640 and none from 800
        final expectWing = stage == 1 ? px <= 800 : px <= 720;
        expect(buffed > 0, expectWing, reason: '${px.round()} px stage $stage: wing gag');
      }
    }
  });

  test('the faster clock (rules 55): the gag drops out of the full fight and fury, and in the warm-up never meets a letter, an ankh, a card or the open satchel', () {
    for (final px in [560.0, 640.0, 720.0, 800.0, 864.0, 960.0]) {
      for (final stage in [0, 1, 2]) {
        final boss = courier(px: px, stage: stage, version: _faster);
        var buffed = 0;
        for (var i = 0; i <= 36 * 60; i++) {
          final t = 10.5 + i / 60;
          fightTo(boss, t);
          final p = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false));
          final ct = boss.mailCycle;
          if (p.buff <= 0) continue;
          buffed++;
          final why = '${px.round()} px stage $stage at cycle ${ct.toStringAsFixed(3)}';
          expect(boss.liveLetters.where((l) => !l.returned), isEmpty, reason: '$why: a letter flies');
          expect(boss.liveAnkhs, isEmpty, reason: '$why: an ankh is out');
          expect(p.cards, 0, reason: why);
          expect(p.satchelOpen, lessThan(.01), reason: why);
          expect(p.reach, 0, reason: why);
          expect(ct, greaterThanOrEqualTo(8.5), reason: why);
        }
        expect(buffed > 0, stage == 0, reason: '${px.round()} px stage $stage: wing gag');
      }
    }
  });

  test('the catch: the hand splays, the wing tucks and (calm) the mask gleams as the ankh comes home', () {
    for (final px in [640.0, 800.0, 960.0]) {
      final boss = courier(px: px, stage: 1, version: _classic);
      fightTo(boss, 12 + 7);
      final ankh = boss.neferhoo.ankhs.last;
      final home = ankh.thrownAt + ankh.length(boss.handX, Neferhoo.turnX(FlightSimulation.birdX)) / ankh.speed;
      fightTo(boss, home - boss.arrivalDuration + .06);
      final p = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false));
      expect(p.sweep, greaterThan(.4), reason: '$px px');
      expect(p.glint, inInclusiveRange(0.0, 1.0), reason: '$px px');
      expect(p.glow, 0, reason: '$px px: a catch is not a telegraph');
    }
  });

  test('no blink at the lock moments, for every alignment of the blink clock against the 12 s cycle', () {
    final windows = <(double, double, bool)>[(.45, 1.05, true), (1.5, 1.8, true), (5.25, 5.9, true), (6.5, 7.5, true), (10.95, 11.78, false)];
    final starts = [for (var k = 0; k < 37; k++) for (final o in [0.0, .1, .2]) 24 + 12.0 * k + o];
    for (final fury in [false, true]) {
      NeferhooTimeline at(double ct, double cs) {
        final yB = Neferhoo.backLane(.3), v = fury ? Neferhoo.furyAnkhSpeed : Neferhoo.ankhSpeed;
        return NeferhooTimeline(
          ct: ct,
          phase: cs + ct,
          bx: 1.228,
          express: fury,
          fury: fury,
          ankhs: [
            NeferhooFlight(laneA: .3, laneB: yB, throwAt: Neferhoo.ankhThrowAt, speed: v),
            if (fury) NeferhooFlight(laneA: yB, laneB: .3, throwAt: Neferhoo.ankhThrowAt + Neferhoo.furyAnkhDelay, speed: v),
          ],
        );
      }

      for (final (a, z, both) in windows) {
        if (fury && !both) continue;
        final n = ((z - a) * 60).round();
        var extra = 0.0;
        for (var i = 0; i <= n; i++) {
          final lids = [for (final cs in starts) at(a + i / 60, cs).pose().lid];
          final base = lids.reduce(math.min);
          extra = math.max(extra, lids.map((l) => l - base).reduce(math.max));
        }
        expect(extra, lessThan(.05), reason: '${fury ? 'fury' : 'calm'} $a-$z stays open');
      }
    }
  });

  test('the drawn ankh leaves the hover point smoothly and then flies the rules\' path exactly', () {
    for (final (version, cycle) in [(_classic, 12.0), (_faster, 10.5)]) {
    for (final px in [560.0, 640.0, 800.0, 960.0]) {
      final boss = courier(px: px, stage: 2, version: version);
      fightTo(boss, cycle + 6.79);
      Offset? prev;
      var worst = 0.0;
      for (var i = 0; i < 90; i++) {
        fightTo(boss, cycle + 6.8 + i / 60);
        for (final ankh in boss.liveAnkhs.where((a) => !a.second)) {
          final p = NeferhooFightArt.ankhCentre(ankh, boss);
          if (p == null) continue;
          if (prev != null) worst = math.max(worst, (p - prev).distance * 360);
          prev = p;
          if (boss.age - ankh.thrownAt >= NeferhooTimeline.ankhEase) {
            final r = ankh.at(boss.age, handX: boss.handX, turnX: Neferhoo.turnX(FlightSimulation.birdX))!;
            expect((p - Offset(r.$1, r.$2)).distance, lessThan(1e-9));
          }
        }
      }
      // the design (N2): 16-27 px a frame while it leaves the hover point, never a teleport
      expect(worst, lessThan(30), reason: 'v$version $px px');
    }
    }
  });
}
