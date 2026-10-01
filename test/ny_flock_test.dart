import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'alley_pigeon_rules_test.dart' show until;
import 'coop_flight_test.dart' show pair, step;
import 'gargoyle_pilot.dart' as garg;
import 'king_coo_helpers.dart' as coo;
import 'ny_arena.dart' as ny;
import 'steam_test.dart' show alley, clearAway;

/// New York (rules version 43) and Fly Together (rules version 42) in one
/// codebase. Co-op and duel are endless-only and refuse a level plan, so
/// nothing New York can ever reach their flights; this file proves that, and
/// then, so the code composes anyway, puts a second bird in a level's flock
/// and checks that every new hazard looks at EVERY bird, aims at the birds in
/// turn (`_target`), reads a bird's own column (`bird.x`) and hurts the bird
/// it found (`_hurt(bird)`), exactly as the old hazards do.

const _spread = Tether.spread;

/// Flies the pair through [seconds] of an endless co-op/duel flight with
/// both birds held level and untouchable, and collects what they met.
({Set<EnemyKind> enemies, Set<BossKind> bosses, int vents, int pigeonStars})
meet(CoopMode coop, {double seconds = 160}) {
  final sim = pair(coop: coop);
  final enemies = <EnemyKind>{};
  final bosses = <BossKind>{};
  var vents = 0, pigeonStars = 0;
  for (var i = 0; i < seconds / .02; i++) {
    for (final bird in sim.flock) {
      bird
        ..y = .5
        ..velocity = 0
        ..invulnerableUntil = double.infinity;
    }
    step(sim, .02);
    if (sim.phase != RunPhase.playing) break;
    enemies.addAll(sim.enemies.map((e) => e.kind));
    if (sim.boss case final boss?) bosses.add(boss.kind);
    vents += sim.steamVents.length;
    pigeonStars += sim.stars.where((s) => s.carried || s.thief != null).length;
  }
  expect(sim.elapsed, greaterThan(seconds / 2), reason: '$coop flew on');
  return (
    enemies: enemies,
    bosses: bosses,
    vents: vents,
    pigeonStars: pigeonStars,
  );
}

/// A second bird in [sim]'s flock, [dx] behind the lead's column, held
/// wherever the test says (nothing flaps it).
FlightBird withPartner(FlightSimulation sim, {double dx = _spread}) {
  final partner = FlightBird(homeX: FlightSimulation.birdX + dx)..y = .5;
  sim.flock.add(partner);
  return partner;
}

void hold(FlightSimulation sim, double lead, double partner) {
  sim.lead
    ..y = lead
    ..velocity = 0;
  sim.partner!
    ..y = partner
    ..velocity = 0
    ..x = sim.partner!.homeX;
}

void main() {
  group('New York cannot reach a co-op or duel flight', () {
    final plans = <String, LevelPlan>{
      'a pigeon level': ny.rulesPlan(flocks: [1, 2]),
      'steam': alley(),
      'King Coo': ny.rulesPlan(
        lineup: const [EnemyKind.simpleBat],
        boss: BossKind.kingCoo,
      ),
      'the Gargoyle': ny.rulesPlan(
        id: '3-4',
        lineup: const [EnemyKind.simpleBat],
        boss: BossKind.searchlightGargoyle,
      ),
      'Moth Light': Campaign.level('3-1')!.plan,
      'a chapter 1 level': Campaign.level('1-1')!.plan,
    };

    for (final coop in CoopMode.values) {
      test('a ${coop.name} flight refuses every level plan', () {
        for (final MapEntry(:key, :value) in plans.entries) {
          expect(
            () => FlightSimulation(
              rules: TapFlyMode(),
              practice: false,
              course: FlightCourse.starTrail,
              coop: coop,
              plan: value,
            ),
            throwsArgumentError,
            reason: key,
          );
        }
      });

      test('a ${coop.name} flight at 43 and at 42 lays no pigeon, vent or '
          'guardian', () {
        final met = meet(coop);
        expect(met.enemies.where((kind) => kind.campaignOnly), isEmpty);
        expect(met.bosses.where((kind) => kind.campaignOnly), isEmpty);
        expect(met.vents, 0);
        expect(met.pigeonStars, 0);
      });
    }

    test('co-op and duel stay at rules 42, New York at 43', () {
      expect(FlightSimulation.coopRulesVersion, 42);
      expect(FlightSimulation.newYorkRulesVersion, 43);
      for (final coop in CoopMode.values) {
        expect(pair(coop: coop).rulesVersion, FlightSimulation.currentRulesVersion);
        expect(pair(coop: coop).supportsAlleyPigeon, isTrue,
            reason: 'a version flag, not content: no plan lays a pigeon');
      }
    });
  });

  group('steam looks at every bird', () {
    /// A level sim with its first vent of [kind] on screen and a partner
    /// bird in the flock, the route clock set [at] seconds after the burst.
    ({FlightSimulation sim, SteamVent vent, FlightBird partner}) scene(
      SteamKind kind,
      double at, {
      double dx = _spread,
    }) {
      final sim = ny.arenaOf(alley());
      final geyser = sim.route!.geysers.firstWhere((g) => g.kind == kind);
      ny.runUntil(
        sim,
        (s) => s.steamVents.any((v) => v.geyser == geyser),
        holdY: .3,
        immortal: true,
        watch: clearAway,
      );
      final partner = withPartner(sim, dx: dx);
      sim
        ..shield = false
        ..hearts = 3
        ..invulnerableUntil = 0
        ..steamScalds = 0
        ..routeSeconds = geyser.burstAt + at;
      final vent = sim.steamVents.firstWhere((v) => v.geyser == geyser);
      return (sim: sim, vent: vent, partner: partner);
    }

    /// One frame with the vent's column over the partner's.
    void frameOverPartner(FlightSimulation sim, SteamVent vent, double lead, double partner) {
      sim.distance = vent.geyser.x - sim.partner!.homeX;
      hold(sim, lead, partner);
      ny.frame(sim);
    }

    test('a burst on the partner scalds the pair, once', () {
      final (:sim, :vent, :partner) = scene(SteamKind.hop, .25);
      for (var i = 0; i < 8; i++) {
        // The lead flies high above the plume; the partner is in the column.
        frameOverPartner(sim, vent, .08, vent.mouth - .06);
      }
      expect(vent.touched, isTrue);
      expect(vent.scalded, isTrue);
      expect(sim.steamScalds, 1, reason: 'one burst, one scald');
      expect(sim.hearts, 2, reason: 'a heart (the shield was already down)');
    });

    test('a burst between the birds scalds neither: each is tested at its '
        'own column', () {
      // The partner flies a quarter screen height behind the lead.
      final (:sim, :vent, :partner) = scene(SteamKind.hop, .25, dx: .25);
      for (var i = 0; i < 8; i++) {
        // The vent sits halfway between the columns: further than a hit box
        // and a bird's radius from both.
        sim.distance = vent.geyser.x - (sim.lead.x + sim.partner!.x) / 2;
        hold(sim, vent.mouth - .06, vent.mouth - .06);
        ny.frame(sim);
      }
      expect(vent.touched, isFalse);
      expect(sim.steamScalds, 0);
      expect(sim.shield, isFalse);
      expect(sim.hearts, 3);
    });

    test('the lead beside the vent is scalded too, with the partner clear', () {
      final (:sim, :vent, :partner) = scene(SteamKind.hop, .25);
      for (var i = 0; i < 8; i++) {
        sim.distance = vent.geyser.x - sim.lead.x;
        hold(sim, vent.mouth - .06, .08);
        ny.frame(sim);
      }
      expect(sim.steamScalds, 1);
      expect(vent.scalded, isTrue);
    });

    test('the billow lifts the bird in its column and no other', () {
      final (:sim, :vent, :partner) = scene(SteamKind.ride, .8);
      final y = (vent.top + vent.mouth) / 2;
      frameOverPartner(sim, vent, y, y);
      expect(partner.velocity, lessThan(0), reason: 'the partner is lifted');
      expect(
        sim.lead.velocity,
        greaterThanOrEqualTo(0),
        reason: 'the lead is a bird-width away: gravity only',
      );
      expect(vent.lifted, greaterThan(0));
    });
  });

  group('the pigeons look at every bird', () {
    test('a partner\'s ram hands the freed star to the partner\'s beak', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      final partner = withPartner(sim);
      sim.lead
        ..y = .9
        ..velocity = 0;
      partner
        ..y = .4
        ..velocity = 0
        ..lastSprintAt = sim.elapsed;
      pigeon.placeAt(partner.x + .03, partner.y);
      ny.frame(sim);
      expect(sim.enemies, isNot(contains(pigeon)));
      expect(sim.starsFreed, 1);
      expect(prey.carried, isFalse);
      // The star fell in front of the partner, not the lead.
      expect(
        prey.x,
        closeTo(partner.x + AlleyPigeon.dropX, .03),
        reason: 'beside the partner',
      );
      expect(prey.y, closeTo(partner.y, .05));
    });

    test('a touch frees the star to the bird that was touched', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      final partner = withPartner(sim);
      sim.lead
        ..y = .9
        ..velocity = 0;
      partner
        ..y = .35
        ..velocity = 0;
      sim.invulnerableUntil = 0;
      pigeon.placeAt(partner.x + .03, partner.y);
      ny.frame(sim);
      expect(sim.starsFreed, 1);
      expect(sim.shield, isFalse, reason: 'a touch costs the shield');
      expect(prey.x, closeTo(partner.x + AlleyPigeon.dropX, .03));
    });
  });

  group('King Coo looks at every bird', () {
    /// King Coo's fight with a partner bird, to the first two crumb locks.
    FlightSimulation twoLocks({
      required double lead,
      required double partner,
      void Function(FlightSimulation sim)? each,
    }) {
      final sim = coo.cooFight();
      withPartner(sim);
      sim.invulnerableUntil = double.infinity;
      var guard = 0;
      while ((sim.boss?.lobs.length ?? 0) < 2) {
        hold(sim, lead, partner);
        coo.tick(sim);
        each?.call(sim);
        if (++guard > 120 * 20) fail('no second ring locked');
      }
      return sim;
    }

    test('crumb rings lock on the birds in turn', () {
      final sim = twoLocks(lead: .25, partner: .75);
      final first = sim.boss!.lobs[0], second = sim.boss!.lobs[1];
      expect(first.lockY, closeTo(.25, 1e-9), reason: 'the first ring: lead');
      expect(first.lockX, closeTo(sim.lead.x, 1e-9));
      expect(second.lockY, closeTo(.75, 1e-9), reason: 'the next: partner');
      expect(second.lockX, closeTo(sim.partner!.x, 1e-9));
      expect(second.lockX - first.lockX, closeTo(_spread, 1e-9));
    });

    test('a cloud on the partner hurts the pair; one it left does not', () {
      for (final stays in [true, false]) {
        final sim = twoLocks(lead: .25, partner: .75);
        final boss = sim.boss!;
        sim
          ..shield = true
          ..hearts = 3
          ..invulnerableUntil = 0;
        // The lead leaves its own ring (the cloud will fall there empty).
        final cloud = boss.lobs[1];
        var guard = 0;
        while (cloud.cloudEndsAt > boss.age) {
          hold(sim, .5, stays ? cloud.lockY : .5);
          coo.tick(sim);
          if (++guard > 120 * 12) fail('the cloud never passed');
        }
        expect(boss.crumbHits, stays ? 1 : 0, reason: 'stays $stays');
        expect(sim.shield, !stays, reason: 'the shared shield, stays $stays');
        expect(sim.hearts, 3);
      }
    });
  });

  group('the Gargoyle looks at every bird', () {
    /// The dark side of this cycle's sweep: a bird in the upper half draws
    /// the beam from above, so its safe place is below, and the other way
    /// round (`SearchlightGargoyle.aimAt`; the side is latched at the warning,
    /// a second and a half before the beam lights).
    double dark(SkyBoss boss) => boss.beamSide == BeamSide.high ? .9 : .1;

    test('a beam on the partner spots the pair', () {
      final sim = garg.arena();
      withPartner(sim);
      final boss = sim.boss!;
      sim
        ..shield = true
        ..hearts = 3
        ..invulnerableUntil = 0;
      var guard = 0;
      while (boss.spots == 0 && sim.phase == RunPhase.playing) {
        // The lead stays in the dark; the partner flies into the light.
        final lit = boss.beamCentres.isEmpty ? null : boss.beamCentres.first;
        hold(sim, dark(boss), lit ?? dark(boss));
        garg.frame(sim, dt: 1 / 120);
        if (++guard > 120 * 14) break;
      }
      expect(boss.spots, greaterThan(0), reason: 'the partner was spotted');
      expect(sim.shield, isFalse, reason: 'a spot costs the shield first');
    });

    test('birds in the dark are never spotted', () {
      final sim = garg.arena();
      withPartner(sim);
      final boss = sim.boss!;
      sim.invulnerableUntil = 0;
      for (var i = 0; i < 120 * 10; i++) {
        final y = dark(boss);
        hold(sim, y, y);
        garg.frame(sim, dt: 1 / 120);
        if (sim.phase != RunPhase.playing) break;
      }
      expect(boss.spots, 0);
    });

    test('stone feathers are aimed at the birds in turn', () {
      final sim = garg.arena();
      final partner = withPartner(sim);
      final boss = sim.boss!;
      sim.invulnerableUntil = double.infinity;
      final aimedAt = <FlightBird>[];
      var seen = 0, guard = 0;
      while (aimedAt.length < 2 && ++guard < 120 * 14) {
        hold(sim, dark(boss), dark(boss));
        garg.frame(sim, dt: 1 / 120);
        if (boss.feathersLaunched > seen) {
          seen = boss.feathersLaunched;
          final feather = sim.bossAmmo.where((a) => a.feather).last;
          // It left the cornice `featherOffsetX` ahead of its target's column.
          final lead = (feather.x - sim.lead.x - SearchlightGargoyle.featherOffsetX)
              .abs();
          final other =
              (feather.x - partner.x - SearchlightGargoyle.featherOffsetX).abs();
          aimedAt.add(lead < other ? sim.lead : partner);
        }
      }
      expect(aimedAt, hasLength(2));
      expect(aimedAt[0], same(sim.lead), reason: 'the first feather: lead');
      expect(aimedAt[1], same(partner), reason: 'the second: partner');
      expect(math.max(sim.lead.x, partner.x) - math.min(sim.lead.x, partner.x),
          closeTo(_spread, 1e-9));
    });
  });
}
