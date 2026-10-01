import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

/// The Searchlight Gargoyle's pure pieces (R0's scaffold, kept by R3): the
/// enum value, health, the pure 9 s cycle (`SearchlightGargoyle`) and the boss
/// getters art, audio and UI read. The fight itself (spotted hurt, lamp gate,
/// feathers, aim latch) is in `searchlight_gargoyle_test`; the R0 STUB test
/// that pinned the inert fight is replaced there.

SkyBoss gargoyle({
  double combat = 0,
  bool enraged = false,
  BeamSide side = BeamSide.high,
  bool slit = false,
}) {
  final boss = SkyBoss(
    number: 7,
    x: 1.7,
    kind: BossKind.searchlightGargoyle,
    cinematic: true,
  );
  boss
    ..age = boss.arrivalDuration + combat
    ..beamSide = side
    ..slitSweep = slit;
  if (enraged) {
    boss
      ..hp = SearchlightGargoyle.furyHp
      ..enragedAt = 0;
  }
  return boss;
}

void main() {
  test('health 160 at every encounter number, fury at half', () {
    for (final number in [1, 3, 7, 9, 40]) {
      expect(SkyBoss.healthFor(BossKind.searchlightGargoyle, number), 160);
    }
    final boss = gargoyle();
    expect(boss.maxHp, 160);
    boss.hp = 81;
    expect(boss.enraged, isFalse);
    boss.hp = 80;
    expect(boss.enraged, isTrue);
    expect(SearchlightGargoyle.maxHp ~/ 2, SearchlightGargoyle.furyHp);
    expect(boss.isGargoyle, isTrue);
    expect(boss.isMiniBoss, isTrue);
    expect(boss.isKingCoo, isFalse);
    expect(boss.name, 'Searchlight Gargoyle');
    expect(boss.title, 'WATCHMAN OF THE TALLEST TOWER');
  });

  test('no volleys or helpers; feathers fly at .36 (fury .44)', () {
    final boss = gargoyle();
    expect(boss.fireIn, double.infinity);
    expect(boss.summonIn, double.infinity);
    expect(boss.volleyInterval, double.infinity);
    expect(boss.summonInterval, double.infinity);
    expect(boss.volleyOffsets, isEmpty);
    expect(boss.projectileSpeed, .36);
    expect(gargoyle(enraged: true).projectileSpeed, .44);
  });

  test('the 9 s cycle: perch, a 1.5 s warning, the sweep, the vent', () {
    final g = SearchlightGargoyle.phase;
    expect(g(0), GargoylePhase.perch);
    expect(g(1.99), GargoylePhase.perch);
    expect(g(2.0), GargoylePhase.warning);
    expect(g(3.49), GargoylePhase.warning);
    expect(g(3.5), GargoylePhase.sweep);
    expect(g(6.39), GargoylePhase.sweep);
    expect(g(6.4), GargoylePhase.vent);
    expect(g(8.99), GargoylePhase.vent);
    expect(SearchlightGargoyle.warnSeconds, closeTo(1.5, 1e-12));
    expect(SearchlightGargoyle.lampOpen(6.39), isFalse);
    expect(SearchlightGargoyle.lampOpen(6.4), isTrue);
    expect(SearchlightGargoyle.lampOpen(8.99), isTrue);
    expect(SearchlightGargoyle.beamOn(3.49), isFalse);
    expect(SearchlightGargoyle.beamOn(3.5), isTrue);
    expect(SearchlightGargoyle.beamOn(6.4), isFalse, reason: 'the vent is quiet');
    expect(SearchlightGargoyle.cycleTime(-1), 0);
    expect(SearchlightGargoyle.cycleTime(10), closeTo(1, 1e-12));
    expect(SearchlightGargoyle.cycleNumber(10), 1);
    expect(SearchlightGargoyle.count(1.9, 2), 0);
    expect(SearchlightGargoyle.count(2, 2), 1);
    expect(SearchlightGargoyle.count(12, 2), 2);
    // The warning must stay at least as long as the viability search proved.
    expect(
      SearchlightGargoyle.warnSeconds,
      greaterThan(SearchlightGargoyle.minWarnSeconds),
    );
  });

  test('the lamp opens over 0.3 s at the vent and closes by the cycle\'s end', () {
    expect(SearchlightGargoyle.lampOpenness(6.39), 0);
    expect(SearchlightGargoyle.lampOpenness(6.4), 0);
    expect(SearchlightGargoyle.lampOpenness(6.55), closeTo(.5, 1e-9));
    expect(SearchlightGargoyle.lampOpenness(6.7), 1);
    expect(SearchlightGargoyle.lampOpenness(8.5), 1);
    expect(SearchlightGargoyle.lampOpenness(8.85), closeTo(.5, 1e-9));
    expect(SearchlightGargoyle.lampOpenness(9.0), 0);
    expect(SearchlightGargoyle.lampOpenness(1), 0);
    expect(SearchlightGargoyle.warning(1.9), 0);
    expect(SearchlightGargoyle.warning(2.75), closeTo(.5, 1e-9));
    expect(SearchlightGargoyle.warning(3.5), 0);
  });

  test('the sweep is aimed at the bird: the upper half draws it from above', () {
    expect(SearchlightGargoyle.aimAt(.3), BeamSide.high);
    expect(SearchlightGargoyle.aimAt(.499), BeamSide.high);
    expect(SearchlightGargoyle.aimAt(.5), BeamSide.low);
    expect(SearchlightGargoyle.aimAt(.9), BeamSide.low);
  });

  test('a beam glides .16 to .42 from above, .84 to .58 from below, for 1.8 s', () {
    const ignite = SearchlightGargoyle.sweepAt;
    expect(SearchlightGargoyle.centre(BeamSide.high, ignite - .01), isNull);
    expect(SearchlightGargoyle.centre(BeamSide.high, ignite), closeTo(.16, 1e-12));
    expect(SearchlightGargoyle.centre(BeamSide.low, ignite), closeTo(.84, 1e-12));
    expect(
      SearchlightGargoyle.centre(BeamSide.high, ignite + .9),
      closeTo((.16 + .42) / 2, 1e-12),
    );
    expect(
      SearchlightGargoyle.centre(BeamSide.high, ignite + 1.8),
      closeTo(.42, 1e-12),
    );
    expect(
      SearchlightGargoyle.centre(BeamSide.low, ignite + 1.8),
      closeTo(.58, 1e-12),
    );
    // It holds at the inner end until the vent, and is off after.
    expect(SearchlightGargoyle.centre(BeamSide.high, 6.3), closeTo(.42, 1e-12));
    expect(SearchlightGargoyle.centre(BeamSide.high, 6.4), isNull);
    // The glide never outruns .25 screen heights per second.
    for (final side in BeamSide.values) {
      var last = SearchlightGargoyle.centre(side, ignite)!;
      for (var t = ignite + .01; t < 6.4; t += .01) {
        final c = SearchlightGargoyle.centre(side, t)!;
        expect((c - last).abs() / .01, lessThan(.25 * 1.01), reason: '$t');
        last = c;
      }
    }
  });

  test('the dark side is where the bird is safe', () {
    const bird = .038;
    final high = SearchlightGargoyle.darkSide(
      BeamSide.high,
      half: SearchlightGargoyle.litHalf,
      radius: bird,
    );
    expect(high.$1, closeTo(.548, 1e-9));
    expect(high.$2, closeTo(.962, 1e-9));
    final low = SearchlightGargoyle.darkSide(
      BeamSide.low,
      half: SearchlightGargoyle.litHalf,
      radius: bird,
    );
    expect(low.$1, closeTo(.038, 1e-9));
    expect(low.$2, closeTo(.452, 1e-9));
    // A bird at the edge of the dark side just escapes the held beam, and a
    // step further in is spotted.
    expect(SearchlightGargoyle.lit(.42, .09, high.$1 + 1e-6, bird), isFalse);
    expect(SearchlightGargoyle.lit(.42, .09, high.$1 - 1e-3, bird), isTrue);
    expect(SearchlightGargoyle.lit(.58, .09, low.$2 - 1e-6, bird), isFalse);
    expect(SearchlightGargoyle.lit(.58, .09, low.$2 + 1e-3, bird), isTrue);
  });

  test('fury: every second fury sweep is a slit of two beams', () {
    expect(SearchlightGargoyle.slitAt(enraged: false, furySweeps: 1), isFalse);
    expect(SearchlightGargoyle.slitAt(enraged: true, furySweeps: 0), isFalse);
    expect(SearchlightGargoyle.slitAt(enraged: true, furySweeps: 1), isTrue);
    expect(SearchlightGargoyle.slitAt(enraged: true, furySweeps: 2), isFalse);
    expect(SearchlightGargoyle.slitAt(enraged: true, furySweeps: 3), isTrue);
    const ignite = SearchlightGargoyle.sweepAt;
    final start = SearchlightGargoyle.slitCentres(ignite)!;
    expect(start.$1, closeTo(.12, 1e-12));
    expect(start.$2, closeTo(.88, 1e-12));
    final end = SearchlightGargoyle.slitCentres(ignite + 1.5)!;
    // The inner ends moved from .26/.74 to .21/.79 in the fix round (the
    // corridor from .214 to .314: see searchlight_gargoyle_fairness_test).
    expect(end.$1, closeTo(.21, 1e-12));
    expect(end.$2, closeTo(.79, 1e-12));
    expect(SearchlightGargoyle.slitCentres(6.4), isNull);
    // The dark slit between the inner ends is .343 to .657 (fury half .095).
    const bird = .038;
    expect(.21 + SearchlightGargoyle.furyLitHalf + bird, closeTo(.343, 1e-9));
    expect(.79 - SearchlightGargoyle.furyLitHalf - bird, closeTo(.657, 1e-9));
    expect(SearchlightGargoyle.slitTop, .343);
    expect(SearchlightGargoyle.slitBottom, .657);
    expect(SearchlightGargoyle.half(enraged: true), .095);
    expect(SearchlightGargoyle.half(enraged: false), .09);
  });

  test('stone feathers: launch times and an aimed fall through the bird\'s column', () {
    expect(SearchlightGargoyle.feathers(enraged: false, slit: false), [.2, 4.6]);
    expect(
      SearchlightGargoyle.feathers(enraged: true, slit: false),
      [.2, 4.5, 5.2],
    );
    expect(SearchlightGargoyle.feathers(enraged: true, slit: true), [.2]);
    for (final enraged in [false, true]) {
      for (final birdY in [.1, .3, .5, .8, .95]) {
        final shot = SearchlightGargoyle.featherShot(birdY, enraged: enraged);
        expect(shot.flight, closeTo(.62 / (enraged ? .44 : .36), 1e-12));
        expect(shot.vx, enraged ? -.44 : -.36);
        // Integrating the fall from the top edge reaches the bird's height
        // exactly when the feather crosses its column.
        final y =
            SearchlightGargoyle.featherY +
            shot.vy * shot.flight +
            SearchlightGargoyle.featherGravity / 2 * shot.flight * shot.flight;
        expect(y, closeTo(birdY, 1e-9), reason: '$birdY $enraged');
      }
    }
    expect(
      SearchlightGargoyle.featherShot(.5, enraged: false).flight,
      closeTo(1.72, .01),
    );
    expect(
      SearchlightGargoyle.featherShot(.5, enraged: true).flight,
      closeTo(1.41, .01),
    );
  });

  test('the anchor stands clear of the bird and never hovers', () {
    expect(SearchlightGargoyle.anchorX(.22, 1.6), closeTo(1.10, 1e-12));
    expect(SearchlightGargoyle.anchorX(.22, 2.2), closeTo(1.70, 1e-12));
    expect(SearchlightGargoyle.anchorY, .5);
  });

  test('the clock drives his getters; before combat nothing is on', () {
    final arriving = gargoyle(combat: -1);
    expect(arriving.gargoylePhase, GargoylePhase.perch);
    expect(arriving.gargoyleCycle, 0);
    expect(arriving.gargoyleCycleNumber, -1);
    expect(arriving.lampOpen, isFalse);
    expect(arriving.lampOpenness, 0);
    expect(arriving.beamOn, isFalse);
    expect(arriving.beamCentres, isEmpty);
    expect(arriving.sweepWarnings, 0);
    expect(arriving.sweepIgnitions, 0);
    expect(arriving.lampOpens, 0);

    final perched = gargoyle(combat: 1);
    expect(perched.gargoylePhase, GargoylePhase.perch);
    expect(perched.lampOpen, isFalse);
    expect(perched.sweepWarning, 0);
    expect(perched.gargoyleHint, 'SHUTTERS CLOSED · Save your shots');

    final warning = gargoyle(combat: 2.75, side: BeamSide.high);
    expect(warning.gargoylePhase, GargoylePhase.warning);
    expect(warning.sweepWarning, closeTo(.5, 1e-9));
    expect(warning.sweepWarnings, 1);
    expect(warning.sweepIgnitions, 0);
    expect(warning.gargoyleHint, 'BEAM INCOMING · Fly low!');
    expect(
      gargoyle(combat: 2.75, side: BeamSide.low).gargoyleHint,
      'BEAM INCOMING · Fly high!',
    );
    expect(
      gargoyle(combat: 2.75, slit: true, enraged: true).gargoyleHint,
      'FURY · Slip between the beams',
    );

    final sweep = gargoyle(combat: 5, side: BeamSide.low);
    expect(sweep.gargoylePhase, GargoylePhase.sweep);
    expect(sweep.beamOn, isTrue);
    expect(sweep.sweepIgnitions, 1);
    expect(sweep.beamCentres, hasLength(1));
    expect(sweep.beamCentres.single, inInclusiveRange(.58, .84));
    expect(sweep.gargoyleHint, 'BEAM · Stay in the dark');
    // Lit at the beam's height, dark beyond its half-height plus the bird.
    final centre = sweep.beamCentres.single;
    expect(sweep.beamLit(centre, .038), isTrue);
    expect(sweep.beamLit(centre - .13, .038), isFalse);
    expect(sweep.beamLit(centre + .2, .038), isFalse);

    final vent = gargoyle(combat: 7);
    expect(vent.gargoylePhase, GargoylePhase.vent);
    expect(vent.lampOpen, isTrue);
    expect(vent.lampOpenness, 1);
    expect(vent.beamOn, isFalse);
    expect(vent.beamLit(.5, .038), isFalse);
    expect(vent.lampOpens, 1);
    expect(vent.gargoyleHint, 'LAMP OPEN · Shoot the lamp!');

    final second = gargoyle(combat: 9 + 5);
    expect(second.gargoyleCycleNumber, 1);
    expect(second.sweepWarnings, 2);
    expect(second.sweepIgnitions, 2);
  });

  test('a slit sweep burns two beams at the bird\'s column', () {
    final boss = gargoyle(combat: 5.2, enraged: true, slit: true);
    expect(boss.beamOn, isTrue);
    expect(boss.beamCentres, hasLength(2));
    expect(boss.beamCentres[0], lessThan(.5));
    expect(boss.beamCentres[1], greaterThan(.5));
    // Between the beams is dark, outside them is lit.
    expect(boss.beamLit(.5, .038), isFalse);
    expect(boss.beamLit(boss.beamCentres[0], .038), isTrue);
    expect(boss.beamLit(boss.beamCentres[1], .038), isTrue);
    expect(boss.beamHalf, .095);
    expect(boss.featherSchedule, [.2], reason: 'a slit cycle drops one');
    expect(
      gargoyle(enraged: true, slit: false).featherSchedule,
      [.2, 4.5, 5.2],
    );
    expect(gargoyle().featherSchedule, [.2, 4.6]);
  });

  test('a stone feather is a BossAmmo that falls', () {
    final feather = BossAmmo(
      x: 1,
      y: -.06,
      vx: -.36,
      vy: .1,
      gravity: SearchlightGargoyle.featherGravity,
      radius: SearchlightGargoyle.featherRadius,
      feather: true,
    );
    expect(feather.feather, isTrue);
    expect(feather.cannonball, isTrue, reason: 'it has gravity like one');
    expect(BossAmmo(x: 1, y: .5, vx: -.5, vy: 0).feather, isFalse);
  });
}
