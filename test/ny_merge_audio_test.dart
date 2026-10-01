// M1 integration: the audio cue classes against the REAL rules of rules
// version 42. The audio agent wired every New York cue to a counter that the
// rules agents (R1 pigeon and steam, R2 King Coo, R3 Gargoyle) were still to
// write, and tested it by bumping the counters by hand. Here real flights
// raise them: after every step of the simulation the cue classes are fed the
// way SkyAudio feeds them, and for each counter the test demands that its cue
// plays on the frame the counter rises and on no other (so a counter the rules
// never raise, or raise under another name, fails here).
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';

import 'campaign_flight.dart' show flyLevel;
import 'gargoyle_pilot.dart' as garg;
import 'king_coo_helpers.dart' as coo;
import 'ny_arena.dart' as arena;
import 'ny_plans.dart';

/// One cue and the counter whose rise it stands for.
typedef Edge = (String cue, int Function(FlightSimulation sim) counter);

final List<Edge> pigeonEdges = [
  ('pigeon_coo', (s) => s.pigeonWarnings),
  ('pigeon_flap', (s) => s.pigeonDives),
  ('pigeon_snatch', (s) => s.starsSnatched),
  ('star_rescue', (s) => s.starsFreed),
  ('pigeon_defeat', (s) => s.pigeonsDefeated),
  // A bat's death is what is left after the pigeons are taken out.
  (
    'enemy_death',
    (s) => s.enemiesDefeated - s.pigeonsDefeated + s.swarmSmashed,
  ),
];

final List<Edge> steamEdges = [
  ('steam_hiss', (s) => s.steamHisses),
  ('steam_burst', (s) => s.steamBursts),
  ('pipe_clang', (s) => s.steamBursts),
  ('steam_ride', (s) => s.steamRides),
];

final List<Edge> cooEdges = [
  ('boss_charge', (s) => s.boss?.lobsLocked ?? 0),
  ('crumb_throw', (s) => s.boss?.lobsLaunched ?? 0),
  ('crumb_splat', (s) => s.boss?.lobBursts ?? 0),
  ('coo_puff', (s) => s.boss?.puffs ?? 0),
  ('coo_whistle', (s) => s.boss?.whistles ?? 0),
  ('coo_pop', (s) => s.boss?.pops ?? 0),
];

final List<Edge> gargoyleEdges = [
  ('beam_warning', (s) => s.boss?.sweepWarnings ?? 0),
  ('beam_sweep', (s) => s.boss?.sweepIgnitions ?? 0),
  ('lamp_vent', (s) => s.boss?.lampOpens ?? 0),
  ('beam_spot', (s) => s.boss?.spots ?? 0),
  ('feather_drop', (s) => s.boss?.feathersLaunched ?? 0),
];

/// The cue classes SkyAudio owns, fed after every step of a real flight.
/// With [edges], each step is checked: a cue plays exactly when its counter
/// rose in that step. [bossEdges] are a boss's: they are only heard while he
/// fights (the killing blow can raise one, as a pop, in the step that ends
/// the fight, and his defeat has its own sound).
class Ear {
  Ear(this.sim, {this.edges = const [], this.bossEdges = const []}) {
    _combat.advance(sim, silent: true);
    _boss.advance(sim.boss, silent: true);
    _seen = [
      for (final (_, counter) in [...edges, ...bossEdges]) counter(sim),
    ];
  }

  final FlightSimulation sim;
  final List<Edge> edges, bossEdges;
  final _combat = CombatAudioCues();
  final _boss = BossAudioCues();
  final List<String> played = [];

  /// The highest value each cue's counter reached (the boss's clock
  /// counters read 0 again once he is defeated).
  final Map<String, int> peak = {};
  late List<int> _seen;

  /// Plays the step the simulation has just made.
  void listen([FlightSimulation? _]) {
    final cues = [..._combat.advance(sim), ..._boss.advance(sim.boss)];
    played.addAll(cues);
    final fighting = sim.boss?.phase == BossPhase.attacking;
    for (final (i, (cue, counter)) in [...edges, ...bossEdges].indexed) {
      final now = counter(sim);
      if (i < edges.length || fighting) {
        // The cue layer plays a burst lower (`_duck`) when a snatch is near
        // it and a snatch higher (`_lift`) when a burst is: the same edge.
        expect(
          cues.contains(cue) ||
              cues.contains('${cue}_duck') ||
              cues.contains('${cue}_lift'),
          now > _seen[i],
          reason:
              '$cue at ${sim.elapsed.toStringAsFixed(3)} s: counter '
              '${_seen[i]} -> $now, played $cues',
        );
      }
      _seen[i] = now;
      if (now > (peak[cue] ?? 0)) peak[cue] = now;
    }
  }

  int count(String cue) => played.where((c) => c == cue).length;
}

void main() {
  group('Alley Pigeon against the real rules', () {
    test('a level flock: every counter edge is one cue, bats keep their '
        'death', () {
      final sim = arena.arenaOf(
        arena.rulesPlan(
          lineup: const [EnemyKind.alleyPigeon, EnemyKind.simpleBat],
          length: 40,
          flocks: const [2, 1, 3],
        ),
      );
      final ear = Ear(sim, edges: pigeonEdges);
      final phases = <PigeonPhase>{};
      arena.runUntil(
        sim,
        (s) => s.elapsed > 60 || s.phase == RunPhase.ended,
        // A collector that never shoots: the pigeons raid, and every star
        // they take is gone for good.
        steer: arena.vacuumY,
        immortal: true,
        allowEnd: true,
        watch: (s) {
          ear.listen();
          for (final e in s.enemies) {
            final raid = e.pigeon;
            if (raid != null) phases.add(raid.phase);
          }
        },
      );
      expect(sim.pigeonWarnings, greaterThan(0), reason: 'they raided');
      expect(sim.pigeonDives, greaterThan(0));
      expect(sim.starsSnatched, greaterThan(0));
      expect(phases, containsAll([PigeonPhase.glide, PigeonPhase.warning]));
      expect(ear.count('pigeon_coo'), greaterThan(0));
      expect(ear.count('pigeon_snatch'), greaterThan(0));
      // The telegraph is the coo, never the shooters' charge.
      expect(ear.count('enemy_charge'), 0);
    });

    test('shooting a thief wins the star back, then the pigeon goes down '
        'with its own sound', () {
      final sim = arena.arenaOf(arena.rulesPlan());
      final ear = Ear(sim, edges: pigeonEdges);
      arena.runUntil(
        sim,
        (s) =>
            arena.raiders(s).isNotEmpty &&
            arena.raiders(s).first.pigeon!.carrying,
        holdY: .5,
        immortal: true,
        watch: ear.listen,
      );
      expect(ear.count('pigeon_snatch'), 1);
      final thief = arena.raiders(sim).first;
      // Shot once (a hit that leaves it alive): the star is freed.
      sim.rocks.add(
        BirdRock(x: thief.x - .03, y: thief.y, damage: thief.hp - 1),
      );
      arena.runUntil(
        sim,
        (s) => s.starsFreed > 0,
        holdY: .5,
        immortal: true,
        watch: ear.listen,
      );
      expect(ear.count('star_rescue'), 1);
      expect(ear.count('pigeon_defeat'), 0);
      // Shot again: it is defeated (counted in both the enemy and pigeon
      // counters, played once, as the pigeon's).
      final again = arena.raiders(sim).firstOrNull ?? thief;
      sim.rocks.add(BirdRock(x: again.x - .03, y: again.y, damage: 50));
      arena.runUntil(
        sim,
        (s) => s.pigeonsDefeated > 0,
        holdY: .5,
        immortal: true,
        watch: ear.listen,
      );
      expect(ear.count('pigeon_defeat'), 1);
      expect(ear.count('enemy_death'), 0);
      expect(sim.enemiesDefeated, sim.pigeonsDefeated);
    });
  });

  group('Steam Geysers against the real rules', () {
    test('the hiss, the burst and the ride of a whole Steam Alley sound '
        'once per vent', () {
      final plan = arena.rulesPlan(
        id: '3-3',
        length: 80,
        start: 100,
        seed: 3103,
        lineup: const [],
        steam: SteamPlan.steady,
        marks: const StarMarks(55, 90),
      );
      final sim = arena.arenaOf(plan);
      final ear = Ear(sim, edges: steamEdges);
      final vents = sim.route!.geysers.length;
      expect(vents, greaterThan(4));
      arena.runUntil(
        sim,
        (s) => s.phase == RunPhase.ended,
        immortal: true,
        seconds: 200,
        // Over a hop vent's plume, under a ride vent's line, else for the
        // stars.
        steer: (s) {
          for (final vent in s.steamVents) {
            final away = vent.x - FlightSimulation.birdX;
            if (away < -.25 || away > .6) continue;
            return vent.kind == SteamKind.ride
                ? vent.top + .10
                : vent.top - .12;
          }
          return arena.vacuumY(s);
        },
        watch: ear.listen,
      );
      expect(sim.steamHisses, vents, reason: 'one hiss per vent passed');
      expect(sim.steamBursts, vents);
      expect(ear.count('steam_hiss'), vents);
      expect(ear.count('steam_burst'), vents);
      expect(ear.count('pipe_clang'), vents);
      expect(ear.count('steam_ride'), sim.steamRides);
      expect(sim.steamRides, greaterThan(0), reason: 'a ride vent lifted it');
    });
  });

  group('King Coo against the real rules', () {
    test('a whole fight: the arrival, every bomb, the puff, the whistle, '
        'the squadron, the defeat', () {
      final sim = nyFlight(coo.cooPlan(), weaponDamage: BirdRock.baseDamage);
      final ear = Ear(sim, edges: pigeonEdges, bossEdges: cooEdges);
      flyLevel(
        sim,
        until: (s) => s.boss?.phase == BossPhase.attacking,
        watch: ear.listen,
      );
      expect(ear.count('coo_shout'), 1, reason: 'his arrival shout');
      expect(ear.count('coo_roar'), 0, reason: 'the long roar is his fury');
      // A novice of the fight-length tests: slow enough for whole cycles, the
      // whistle and the fury.
      coo.fightBot(
        sim,
        coo.CooBot(
          react: .8,
          margin: .07,
          gap: 1.3,
          aim: .06,
          tapsPerSecond: 2.5,
        ),
        each: ear.listen,
      );
      final boss = sim.boss!;
      expect(boss.phase, BossPhase.defeated);
      // Keep playing the defeat: the burst and the victory.
      coo.run(sim, 5, protect: true, each: ear.listen);
      // Every step was checked counter against cue; the fight had them all.
      expect(ear.count('boss_charge'), greaterThan(1));
      expect(ear.count('crumb_throw'), greaterThan(1));
      expect(ear.count('crumb_splat'), greaterThan(1));
      expect(ear.count('coo_puff'), greaterThan(0));
      expect(ear.count('coo_pop') + ear.count('coo_whistle'), greaterThan(0));
      expect(ear.count('coo_defeat'), 1);
      expect(ear.count('coo_inflate'), 1, reason: 'the chest inflates, once');
      // His own cues replace the generic ones.
      expect(ear.count('boss_burst'), 0);
      expect(ear.count('boss_roar'), 0);
      expect(ear.count('boss_enrage'), 0);
      expect(ear.count('coo_roar'), 1, reason: 'his fury');
    });

    test('the squadron: a whistle, the flutter, and a pigeon shot down has '
        'the pigeon defeat, never a bat death', () {
      final sim = coo.cooFight(weaponDamage: BirdRock.baseDamage);
      final ear = Ear(sim, edges: pigeonEdges, bossEdges: cooEdges);
      final boss = sim.boss!;
      coo.runTo(sim, 9.3, hold: .5, protect: true, each: ear.listen);
      expect(ear.count('coo_whistle'), 1);
      expect(ear.count('squad_flutter'), 1);
      expect(boss.whistles, 1);
      final squad = sim.enemies.where((e) => e.squad).toList();
      expect(squad, isNotEmpty);
      final pigeonsBefore = sim.pigeonsDefeated;
      // Wait for a pigeon to reach shooting range, then shoot it: the rock
      // leaves the bird at the lane's height.
      final lane = squad.first.y;
      coo.run(
        sim,
        4,
        hold: lane,
        protect: true,
        each: ear.listen,
        until: (s) => s.enemies.any((e) => e.squad && e.x < birdXHalf),
      );
      final before = sim.enemiesDefeated;
      coo.run(
        sim,
        3,
        hold: lane,
        protect: true,
        shootWhen: (s) => s.canShoot,
        each: ear.listen,
        until: (s) => s.enemiesDefeated > before,
      );
      expect(sim.enemiesDefeated, greaterThan(before));
      // Both counters rise together for a squadron pigeon.
      expect(sim.pigeonsDefeated - pigeonsBefore, sim.enemiesDefeated - before);
      expect(ear.count('pigeon_defeat'), greaterThan(0));
      expect(ear.count('enemy_death'), 0);
      // No pigeon raid sound: they are gliders.
      expect(ear.count('pigeon_coo'), 0);
      expect(ear.count('pigeon_flap'), 0);
      expect(ear.count('pigeon_snatch'), 0);
    });

    test('a pop before the whistle cancels the whistle and its cue', () {
      final sim = coo.cooFight(weaponDamage: BirdRock.baseDamage);
      final ear = Ear(sim, bossEdges: cooEdges);
      final boss = sim.boss!;
      coo.runTo(sim, 7.7, hold: .5, protect: true, each: ear.listen);
      expect(boss.puffWindow, isTrue);
      // Three puffed chest hits (x2 each): 60 damage pops him.
      while (boss.pops == 0) {
        sim.rocks.add(BirdRock(x: boss.x - .04, y: boss.y, damage: 30));
        coo.run(sim, .1, hold: .5, protect: true, each: ear.listen);
      }
      coo.runTo(sim, 10.5, hold: .5, protect: true, each: ear.listen);
      expect(ear.count('coo_pop'), 1);
      expect(ear.count('coo_whistle'), 0);
      expect(boss.whistles, 0);
    });
  });

  group('Searchlight Gargoyle against the real rules', () {
    test('a whole fight with a pilot: every warning, beam, lamp opening '
        'and feather', () {
      final sim = nyFlight(
        garg.gargoylePlan(),
        weaponDamage: BirdRock.baseDamage,
      );
      final ear = Ear(sim, bossEdges: gargoyleEdges);
      flyLevel(
        sim,
        sprintWhen: (s, f) => false,
        until: (s) => s.boss?.phase == BossPhase.attacking,
        watch: ear.listen,
      );
      expect(ear.count('gargoyle_strike'), 1, reason: 'the reveal');
      expect(ear.count('gargoyle_awaken'), 1, reason: 'the awakening');
      sim
        ..birdY = .5
        ..velocity = 0
        ..hearts = 3
        ..shield = true
        ..invulnerableUntil = 0;
      final pilot = garg.Pilot();
      final boss = sim.boss!;
      var guard = 0;
      while (boss.phase != BossPhase.defeated &&
          sim.phase == RunPhase.playing &&
          guard++ < 60 * 400) {
        pilot.fly(sim);
        ear.listen();
      }
      expect(boss.phase, BossPhase.defeated);
      for (var i = 0; i < 60 * 5; i++) {
        garg.frame(sim);
        ear.listen();
      }
      expect(ear.peak['beam_warning'], greaterThan(2));
      expect(ear.count('beam_warning'), ear.peak['beam_warning']);
      expect(ear.count('beam_sweep'), ear.peak['beam_sweep']);
      expect(ear.count('lamp_vent'), ear.peak['lamp_vent']);
      expect(boss.feathersLaunched, greaterThan(2));
      expect(ear.count('feather_drop'), boss.feathersLaunched);
      expect(ear.played, contains('boss_break'));
      expect(ear.count('gargoyle_shatter'), 1);
      expect(ear.count('gargoyle_fury'), 1);
      // His own reveal, roar, fury and burst replace the generic ones.
      expect(ear.count('boss_burst'), 0);
      expect(ear.count('boss_enrage'), 0);
      expect(ear.count('boss_reveal'), 0);
      expect(ear.count('boss_roar'), 0);
    });

    test('a bird caught in the beam: one beam_spot per real hurt', () {
      final sim = garg.arena();
      final ear = Ear(sim, bossEdges: gargoyleEdges);
      final boss = sim.boss!;
      // A bird that hovers at mid-height through warnings and sweeps.
      var guard = 0;
      while (boss.spots < 2 && guard++ < 60 * 60) {
        sim.hearts = 3;
        sim.shield = true;
        garg.frame(sim, flap: sim.birdY > .5 && sim.velocity > -.25);
        ear.listen();
      }
      expect(boss.spots, greaterThanOrEqualTo(2), reason: 'he spotted it');
      expect(ear.count('beam_spot'), greaterThanOrEqualTo(2));
      expect(ear.count('beam_spot'), boss.spots);
    });

    test('a rock on the shuttered lamp clinks once', () {
      final sim = garg.arena();
      final ear = Ear(sim, bossEdges: gargoyleEdges);
      final boss = sim.boss!;
      garg.fightAt(boss, 1.0);
      expect(boss.lampOpen, isFalse);
      sim.rocks.add(BirdRock(x: boss.x - .04, y: boss.y, damage: 10));
      var guard = 0;
      while (boss.lastGlanceAt == double.negativeInfinity && guard++ < 120) {
        sim
          ..hearts = 3
          ..shield = true
          ..birdY = .5
          ..velocity = 0;
        garg.frame(sim);
        ear.listen();
      }
      expect(boss.lastGlanceAt, isNot(double.negativeInfinity));
      expect(ear.count('lamp_glance'), 1);
      expect(boss.hp, boss.maxHp, reason: 'a glance costs nothing');
    });
  });
}

/// King Coo's squadron is within a rock's reach of the bird's column.
const birdXHalf = FlightSimulation.birdX + 1.2;
