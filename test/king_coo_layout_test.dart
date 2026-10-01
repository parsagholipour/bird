import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';

import 'king_coo_test_kit.dart';
import 'ny_plans.dart';

/// The contract's numbers agree with each other, with the rules and with the
/// palette they document.

double _lstar(Color c) {
  double lin(double v) =>
      v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  final y = .2126 * lin(c.r) + .7152 * lin(c.g) + .0722 * lin(c.b);
  return y > .008856 ? 116 * math.pow(y, 1 / 3) - 16 : 903.3 * y;
}

void main() {
  test('the layout mirrors the rules\' anchor for him', () {
    final plan = nyPlan(
      lineup: const [EnemyKind.simpleBat, EnemyKind.alleyPigeon],
      boss: BossKind.kingCoo,
    );
    var fights = 0;
    for (final width in [1.778, 2.222]) {
      flyNy(
        plan,
        viewportWidth: width,
        watch: (sim) {
          final boss = sim.boss;
          if (boss == null || boss.phase != BossPhase.attacking) return;
          fights++;
          expect(boss.x, closeTo(KingCooLayout.anchorX(FlightSimulation.birdX, width), 1e-9));
          expect(boss.y, closeTo(KingCooLayout.hoverY(boss.combatTime), 1e-9));
        },
      );
    }
    expect(fights, greaterThan(0));
    expect(KingCooLayout.screenRight, closeTo(.55 / SkyBoss.radius, .01));
  });

  test('the boxes nest: rest < envelope < layer bounds, and hold the anchors', () {
    final e = KingCooLayout.envelope, r = KingCooLayout.restEnvelope;
    final l = KingCooLayout.layerBounds;
    bool inside(Rect a, Rect b) =>
        a.left >= b.left && a.top >= b.top && a.right <= b.right && a.bottom <= b.bottom;
    expect(inside(r, e), isTrue);
    expect(inside(e, l), isTrue);
    for (final p in [
      KingCooLayout.eyeRest,
      KingCooLayout.beakTipRest,
      KingCooLayout.whistleMouthRest,
      KingCooLayout.capSeatRest,
      KingCooLayout.sirenRest,
      KingCooLayout.whistleRest,
      KingCooLayout.lobRelease,
      KingCooLayout.sackCentre,
      KingCooLayout.tailRoot,
    ]) {
      expect(r.contains(p), isTrue, reason: '$p');
    }
    for (final MapEntry(:key, :value) in KingCooLayout.negativeSpaces.entries) {
      expect(e.contains(value.center), isTrue, reason: key);
    }
    // The screen: the envelope leaves room to the edge and under the bar.
    expect(KingCooLayout.screenRight - e.right, greaterThan(.5));
    expect(e.top, greaterThan(KingCooLayout.visibleWorst.top));
    expect(e.top - KingCooLayout.healthBarClearance, greaterThan(.2));
    expect(e.bottom, lessThan(KingCooLayout.visibleWorst.bottom));
  });

  test('the parts sit inside the body where they must', () {
    final torso = KingCooKit.spline(KingCooLayout.bodyOutline);
    for (final (name, p) in [
      ('near hip', KingCooLayout.nearHip),
      ('far hip', KingCooLayout.farHip),
      ('tail root', KingCooLayout.tailRoot),
      ('near shoulder', KingCooLayout.nearShoulder),
      ('far shoulder', KingCooLayout.farShoulder),
      ('sack mouth', KingCooLayout.sackMouth),
      ('neck base', KingCooLayout.neckBase),
      ('chest', KingCooLayout.chest),
    ]) {
      expect(torso.contains(p), isTrue, reason: name);
    }
    // The rump ends where the tail root is, the strap comes down onto the back.
    expect(torso.contains(KingCooLayout.strapTo), isTrue);
    // The skull's centre is above the chest globe, on a neck.
    expect(KingCooLayout.headRest.dy, lessThan(-KingCooLayout.hitRadius));
    expect((KingCooLayout.headRest - KingCooLayout.chest).distance, greaterThan(1.8));
    // The far leg clears the sack by the documented gap.
    final sack = KingCooKit.spline(KingCooLayout.sackOutline);
    // (The leg is a line .21 wide from the hip to a foot that swings left.)
    final farLegRight = KingCooLayout.farHip.dx + .105;
    final sackLeft = sack.getBounds().left;
    expect(sackLeft - farLegRight, greaterThan(KingCooLayout.legSackGap));
  });

  test('the wing tip is at the release anchor at the release angle', () {
    final s = KingCooLayout.wingScale;
    final tip = KingCooLayout.nearShoulder +
        KingCooLayout.turn(
          Offset(KingCooLayout.wingTipLocal.dx * s, KingCooLayout.wingTipLocal.dy * s),
          KingCooLayout.tossRelease,
        );
    expect((tip - KingCooLayout.lobRelease).distance, lessThan(KingCooLayout.lobReleaseTolerance));
  });

  test('the z-order names every part the rig paints, once, in order', () {
    final order = KingCooLayout.zOrder;
    expect(order.toSet().length, order.length);
    final owned = [
      ...KingCooLayout.headParts,
      ...KingCooLayout.bodyParts,
      ...KingCooLayout.wingParts,
      ...KingCooLayout.crumbParts,
    ];
    expect(owned.toSet().length, owned.length, reason: 'one owner per part');
    expect(order.toSet(), owned.toSet());
    // A pose that uses every part (a bomb in hand, the steam of the fury).
    final pose = poseOf(
      cooBoss(
        combat: 1.0,
        fury: true,
        setup: (b) => b.lobs.add(lobAt(b.age - .6, fury: true)),
      ),
    );
    final seen = <String>[];
    KingCooBossRig.paintPose(Canvas(ui.PictureRecorder()), pose, trace: seen.add);
    expect(seen, order);
  });

  test('the palette keeps its documented values (CIE L*)', () {
    const p = KingCooPalette.ink;
    expect(_lstar(p), closeTo(9, 4));
    for (final (name, c, l) in <(String, Color, double)>[
      ('featherLit', KingCooPalette.featherLit, 87),
      ('feather', KingCooPalette.feather, 65),
      ('featherDeep', KingCooPalette.featherDeep, 47),
      ('featherDark', KingCooPalette.featherDark, 31),
      ('breastHi', KingCooPalette.breastHi, 96),
      ('breastLit', KingCooPalette.breastLit, 90),
      ('breast', KingCooPalette.breast, 79),
      ('breastDeep', KingCooPalette.breastDeep, 61),
      ('navyLit', KingCooPalette.navyLit, 42),
      ('navy', KingCooPalette.navy, 25),
      ('navyDeep', KingCooPalette.navyDeep, 14),
      ('brass', KingCooPalette.brass, 81),
      ('crumb', KingCooPalette.crumb, 82),
    ]) {
      expect(_lstar(c), closeTo(l, 4), reason: name);
    }
    // The chest (the target) is the brightest big shape, the ink the darkest.
    expect(_lstar(KingCooPalette.breastHi), greaterThan(_lstar(KingCooPalette.featherLit)));
    expect(_lstar(KingCooPalette.ink), lessThan(_lstar(KingCooPalette.featherCore)));
  });

  test('the tone bleaches, flushes and never builds a paint', () {
    const t = KingCooTone(flash: .55, fury: 1, heat: 1, dark: 1, siren: 2, sirenGlow: 1);
    expect(t.washAlpha, inInclusiveRange(.3, .6));
    expect(t.furyAlpha, lessThanOrEqualTo(.16));
    expect(t.lit(KingCooPalette.navy), isNot(KingCooPalette.navy));
    expect(KingCooTone.calm.lit(KingCooPalette.navy), KingCooPalette.navy);
    expect(KingCooTone.calm.plate(KingCooPalette.feather), KingCooPalette.feather);
    expect(t.sirenColor, KingCooPalette.sirenBlue);
    expect(t.skyRim, lessThan(KingCooTone.calm.skyRim + 1));
    // A dark sky lights the rim harder than a bright one.
    expect(const KingCooTone(dark: 1).skyRim, greaterThan(const KingCooTone().skyRim));
    final night = KingCooSkyLight.fromSky(
      top: const Color(0xff222255),
      horizon: const Color(0xffbd7a89),
      haze: const Color(0xff6c5f92),
    );
    final day = KingCooSkyLight.fromSky(
      top: const Color(0xff78bddc),
      horizon: const Color(0xfffae6bf),
      haze: const Color(0xfff1cf9c),
    );
    expect(night.dark, greaterThan(.4));
    expect(day.dark, lessThan(.1));
  });
}
