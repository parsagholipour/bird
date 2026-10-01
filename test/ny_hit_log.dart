import 'dart:math' as math;

import 'package:push_up_bird/domain/game_rules.dart';

/// What hurt a pilot's bird, frame by frame: a port of the review harness's
/// `classify` (`reports/21-review-play/scripts/rv_lib.dart`), used by
/// `ny_pilots.dart` so a test can assert EVERY damage source of a flight, not
/// just the ones its author thought of. A bird that loses its shield or a
/// heart on a frame is one [NyHit]; the cause is read from the state just
/// before the frame (what stood next to the bird and vanished) and the
/// counters just after.
///
/// Causes: `steam` (a scald), `crumb-cloud` (King Coo's bomb), `beam` (the
/// Gargoyle's light), `moth-fan`, `beetle-seed`, `feather` (a boss shot),
/// `squad-pigeon` (King Coo's squadron), `pigeon-body` (a raider touched),
/// `enemy-<kind>` (a bat, moth or beetle touched), `door`, `wall`, `edge`,
/// `other`.
class NyHit {
  const NyHit(this.at, this.cause, this.lost, this.inFight);

  /// Simulation seconds, the cause, whether it cost a heart (else the
  /// shield) and whether a guardian was fighting.
  final double at;
  final String cause;
  final bool lost, inFight;

  @override
  String toString() =>
      '${at.toStringAsFixed(1)} s $cause (${lost ? 'heart' : 'shield'}'
      '${inFight ? ', fight' : ''})';
}

/// A copy of what [HitLog] needs from the state before a frame.
class HitSnap {
  HitSnap(FlightSimulation sim)
    : hearts = sim.hearts,
      shield = sim.shield,
      birdY = sim.birdY,
      time = sim.elapsed,
      scalds = sim.steamScalds,
      crumbs = sim.boss?.crumbHits ?? 0,
      spots = sim.boss?.spots ?? 0,
      enemies = [
        for (final e in sim.enemies)
          (e.x, e.y, e.kind.name, e.squad, identityHashCode(e)),
      ],
      ammo = [
        for (final a in sim.bossAmmo)
          (a.x, a.y, a.feather, identityHashCode(a)),
      ],
      hitGates = {
        for (final o in sim.obstacles)
          if (o.hit) identityHashCode(o),
      },
      doorGates = {
        for (final o in sim.obstacles)
          if (o.door != null && !o.door!.destroyed) identityHashCode(o),
      },
      fighting = sim.boss?.phase == BossPhase.attacking;

  final int hearts, scalds, crumbs, spots;
  final double time, birdY;
  final bool shield, fighting;
  final List<(double, double, String, bool, int)> enemies;
  final List<(double, double, bool, int)> ammo;
  final Set<int> hitGates, doorGates;
}

/// Records the hits of a flight: call [before] ahead of each tick and
/// [after] behind it.
class HitLog {
  final hits = <NyHit>[];
  HitSnap? _snap;

  void before(FlightSimulation sim) => _snap = HitSnap(sim);

  void after(FlightSimulation sim) {
    final snap = _snap!;
    final lostHeart = sim.hearts < snap.hearts;
    final lostShield = snap.shield && !sim.shield && sim.hearts == snap.hearts;
    if (!lostHeart && !lostShield) return;
    hits.add(NyHit(sim.elapsed, _cause(sim, snap), lostHeart, snap.fighting));
  }

  static String _cause(FlightSimulation sim, HitSnap before) {
    const birdX = FlightSimulation.birdX, birdR = FlightSimulation.birdRadius;
    if (sim.steamScalds > before.scalds) return 'steam';
    final boss = sim.boss;
    if ((boss?.crumbHits ?? 0) > before.crumbs) return 'crumb-cloud';
    if ((boss?.spots ?? 0) > before.spots) return 'beam';
    for (final impact in sim.enemyAmmoImpacts) {
      if (impact.at > before.time - 1e-9 && impact.stop == AmmoStop.struck) {
        return impact.attack == EnemyAttack.fan ? 'moth-fan' : 'beetle-seed';
      }
    }
    final ammoNow = {for (final a in sim.bossAmmo) identityHashCode(a)};
    for (final a in before.ammo) {
      if (ammoNow.contains(a.$4)) continue;
      final dx = a.$1 - birdX, dy = a.$2 - sim.birdY;
      if (math.sqrt(dx * dx + dy * dy) < .16) {
        return a.$3 ? 'feather' : 'boss-shot';
      }
    }
    final enemiesNow = {for (final e in sim.enemies) identityHashCode(e)};
    for (final e in before.enemies) {
      if (enemiesNow.contains(e.$5)) continue;
      final dx = e.$1 - birdX, dy = e.$2 - before.birdY;
      if (math.sqrt(dx * dx + dy * dy) < .20) {
        if (e.$4) return 'squad-pigeon';
        if (e.$3 == 'alleyPigeon') return 'pigeon-body';
        return 'enemy-${e.$3}';
      }
    }
    for (final o in sim.obstacles) {
      if (o.hit && !before.hitGates.contains(identityHashCode(o))) {
        return before.doorGates.contains(identityHashCode(o)) ? 'door' : 'wall';
      }
    }
    if (sim.birdY <= birdR + .002 || sim.birdY >= 1 - birdR - .002) {
      return 'edge';
    }
    if (before.birdY <= birdR + .01 || before.birdY >= 1 - birdR - .01) {
      return 'edge';
    }
    return 'other';
  }

  /// The hits by cause, optionally only those in a guardian's fight.
  Map<String, int> byCause({bool? inFight}) {
    final out = <String, int>{};
    for (final h in hits) {
      if (inFight != null && h.inFight != inFight) continue;
      out[h.cause] = (out[h.cause] ?? 0) + 1;
    }
    return out;
  }
}
