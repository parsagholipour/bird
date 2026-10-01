import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'ny_hit_log.dart';
import 'gargoyle_pilot.dart' as gargoyle;
import 'king_coo_helpers.dart' as coo;
import 'recorded_flight.dart' show rideTheSky;
import 'steam_bot.dart' show steamTapper;

/// Whole-level pilots for New York's four levels (the catalog's 3-1 to 3-4),
/// used by `ny_levels_flight_test.dart`, `ny_star_marks_test.dart` and the
/// frozen New York tapes.
///
/// A pilot flies a level the way a player who reads the screen would, at a
/// chosen [Skill]:
///
/// - the run-up and the ordinary levels: [steamTapper] (the shared
///   `rideTheSky` bot that also hops hot vents), tapping at most 2.5 to 5
///   times a second, shooting at its cadence, sprinting whenever the level
///   allows it;
/// - a guardian's fight: King Coo's `CooBot` (R2) or the Gargoyle's `Pilot`
///   (R3), each of which dodges every telegraphed hazard and shoots when it
///   can; the skill sets how soon it reacts and how often it shoots;
/// - after the guardian falls the bird coasts to the line.
///
/// It is mortal: nothing tops the hearts up unless told to, so a level it
/// completes is a level a player of that skill can complete.
enum Skill { sharp, average, casual }

/// One frame of input: the two ways to drive a flight, straight through the
/// simulation or through a [FlightRecorder] (a saved tape).
abstract class Driver {
  FlightSimulation get sim;

  /// One frame: a tap if [flap], then the simulation ticks [dt].
  void frame({required bool flap, required double width});
  void startCharge();
  void shoot();
  void sprint();
}

TrackingSample _touch(double now) => TrackingSample(
  mode: PlayMode.touch,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);

/// Frames are 1/60 s: the Gargoyle pilot's search plans in frames of that
/// size.
const frameSeconds = 1 / 60;

class DirectDriver implements Driver {
  /// Drives [sim] on from where its clock stands (a fresh flight: from 0).
  DirectDriver(this.sim)
    : _now = sim.lastValidMs.isFinite ? sim.lastValidMs : 0;
  @override
  final FlightSimulation sim;
  double _now;

  @override
  void frame({required bool flap, required double width}) {
    _now += frameSeconds * 1000;
    sim.apply(
      MovementInput(valid: true, height: .5, flap: flap),
      _touch(_now),
      _now,
    );
    sim.tick(frameSeconds, _now, viewportWidth: width);
  }

  @override
  void startCharge() => sim.startCharge();
  @override
  void shoot() => sim.shoot();
  @override
  void sprint() => sim.sprint();
}

/// Drives a flight through a recorder, so the whole flight is a tape.
class RecordingDriver implements Driver {
  RecordingDriver(this.tape) {
    recorder = FlightRecorder(tape, () => _now);
  }
  final ReplayTape tape;
  late final FlightRecorder recorder;
  double _now = 0;

  @override
  FlightSimulation get sim => recorder.simulation;

  @override
  void frame({required bool flap, required double width}) {
    _now += frameSeconds * 1000;
    recorder.apply(
      MovementInput(valid: true, height: .5, flap: flap),
      _touch(_now),
      _now,
    );
    recorder.tick(frameSeconds, _now, width);
  }

  @override
  void startCharge() => recorder.command('charge');
  @override
  void shoot() => recorder.command('shoot');
  @override
  void sprint() => recorder.command('sprint');
}

/// What a flight of a level showed, for the tests' tables.
class NyRun {
  NyRun(this.sim);
  final FlightSimulation sim;

  /// The boss's combat seconds, control back to the killing blow (without
  /// the 4.6 s arrival and the 3.8 s defeat), or null in a level without one
  /// or when he was not beaten.
  double? fight;

  /// Seconds the flight took, from its start to its end.
  double get seconds => sim.elapsed;

  /// Stars collected and hearts left when the guardian arrived (the run-up's
  /// whole harvest: the level lays no star after it), or null.
  int? starsAtBoss, heartsAtBoss, shieldsAtBoss;

  /// The guardian (the simulation drops it once he has gone).
  SkyBoss? boss;

  /// The lowest hearts count during the flight.
  int minHearts = 3;
  bool get finished => sim.endReason == EndReason.completed;

  /// Every hit the bird took, with its cause ([HitLog]).
  final log = HitLog();

  /// The hits in the run-up and the ordinary levels, and in the fight.
  List<NyHit> get fightHits => [
    for (final h in log.hits)
      if (h.inFight) h,
  ];
  List<NyHit> get runHits => [
    for (final h in log.hits)
      if (!h.inFight) h,
  ];
}

/// The run-up's pilot: how a skill taps and shoots.
class _RunUp {
  _RunUp(this.skill, {required this.shoots});
  final Skill skill;
  final bool shoots;

  double get react => switch (skill) {
    Skill.sharp => .4,
    Skill.average => .6,
    Skill.casual => .9,
  };
  double get taps => switch (skill) {
    Skill.sharp => 5,
    Skill.average => 3.5,
    Skill.casual => 2.5,
  };

  /// Frames between tapped shots, and a charged shot's period in frames (0
  /// for a player who never charges).
  int get tapEvery => switch (skill) {
    Skill.sharp => 11,
    Skill.average => 22,
    Skill.casual => 45,
  };
  int get chargeEvery => switch (skill) {
    Skill.sharp => 108,
    Skill.average => 144,
    Skill.casual => 0,
  };

  bool flap(FlightSimulation sim) =>
      steamTapper(sim, react: react, taps: taps, clearance: .10);

  void fire(Driver d, int frame) {
    final sim = d.sim;
    if (!shoots || !sim.offersShoot) return;
    if (chargeEvery > 0) {
      final at = frame % chargeEvery;
      if (at == 0) {
        d.startCharge();
        return;
      }
      if (at == chargeEvery ~/ 3) {
        d.shoot();
        return;
      }
    }
    if (frame % tapEvery == 0 && !sim.charging && sim.canShoot) d.shoot();
  }
}

/// Flies New York's level [id] with a pilot of [skill] at [width] screen
/// heights wide, and returns what happened. [weaponDamage] is what the
/// campaign really gives (the base 10); [shoots] false is a player who never
/// fires; [keepAlive] tops the hearts up (a pilot that cannot lose);
/// [sprints] false never sprints, [sprintsInFights] also presses it in a
/// guardian's fight, whenever it is ready (a player who hammers the key);
/// [stopAtBoss] returns as a guardian begins
/// to fight (the run-up's harvest is then in the run). [phase] shifts the
/// pilot's shooting by that many frames (a player does not press Shoot on a
/// beat the level knows) and holds it idle for `phase % 30` frames when a
/// guardian begins to fight; 0, the default, is the flight every frozen
/// fixture was recorded with. [plan] flies another plan than the catalog's
/// (a re-seeded layout, see [reseeded]); its guardian, if any, decides the
/// fight. [driver] takes over the flight's input, so a
/// test can record it.
NyRun flyNewYork(
  String id, {
  Skill skill = Skill.sharp,
  double width = 2.2,
  int weaponDamage = BirdRock.baseDamage,
  bool shoots = true,
  bool keepAlive = false,
  bool sprints = true,
  bool sprintsInFights = false,
  bool stopAtBoss = false,
  int phase = 0,
  LevelPlan? plan,
  double seconds = 400,
  Driver? driver,
  void Function(FlightSimulation sim)? watch,
}) {
  final level = Campaign.level(id)!;
  final d =
      driver ??
      DirectDriver(
        FlightSimulation(
          rules: TapFlyMode(),
          practice: false,
          course: FlightCourse.starTrail,
          weaponDamage: weaponDamage,
          plan: plan ?? level.plan,
        ),
      );
  final sim = d.sim;
  final run = NyRun(sim);
  final runUp = _RunUp(skill, shoots: shoots);
  coo.CooBot? cooBot;
  gargoyle.Pilot? warden;
  double? fightStart;
  var fightFrames = 0;
  for (var frame = 1; frame <= seconds * 60; frame++) {
    if (keepAlive && sim.hearts < 2) sim.hearts = 3;
    final boss = sim.boss;
    var flap = false;
    if (boss != null && boss.phase == BossPhase.attacking) {
      run.boss ??= boss;
      if (run.heartsAtBoss == null) {
        run.starsAtBoss ??= sim.collectedStars;
        run.heartsAtBoss = sim.hearts;
        run.shieldsAtBoss = sim.shield ? 1 : 0;
      }
      fightStart ??= sim.elapsed;
      if (stopAtBoss) break;
      if (sprintsInFights && sprints && sim.canSprint) d.sprint();
      // A player takes a moment to find the fight's rhythm: idle for the
      // first `phase % 30` frames (a bird that is held reads nothing).
      if (fightFrames++ >= phase % 30) {
        if (boss.isKingCoo) {
          cooBot ??= _cooBot(skill);
          flap = cooBot.flap(sim);
          if (shoots && cooBot.shoot(sim)) d.shoot();
        } else {
          warden ??= _warden(skill);
          flap = warden.flap(sim);
          if (shoots && warden.shoot(sim)) d.shoot();
        }
      }
    } else if (boss != null && boss.phase == BossPhase.defeated) {
      run.fight ??= sim.elapsed - fightStart!;
      // The bird coasts to the line; a player lets go.
    } else if (sim.victoryGlide) {
      // The boss has gone: nothing to do but coast.
    } else if (boss == null) {
      flap = runUp.flap(sim);
      runUp.fire(d, frame + phase);
      if (sprints && sim.canSprint) d.sprint();
    } else {
      // The guardian is arriving: the bird is held, nothing to do.
      run.starsAtBoss ??= sim.collectedStars;
    }
    run.log.before(sim);
    d.frame(flap: flap, width: width);
    run.log.after(sim);
    if (sim.hearts < run.minHearts) run.minHearts = sim.hearts;
    watch?.call(sim);
    if (sim.phase == RunPhase.ended) break;
  }
  return run;
}

coo.CooBot _cooBot(Skill skill) => switch (skill) {
  // R2's 'practised', 'family' and 'novice' bots (they react to a telegraph
  // after .3, .55 and .8 s, shoot every .5, .8 and 1.3 s and tap at most 5,
  // 3.5 and 2.5 times a second).
  Skill.sharp => coo.CooBot(react: .3, margin: .07, gap: .5, aim: .08),
  Skill.average => coo.CooBot(
    react: .55,
    margin: .07,
    gap: .8,
    aim: .07,
    tapsPerSecond: 3.5,
  ),
  // The novice plans a squadron one formation at a time (`sequential`, the R2
  // fix round): fury's V and picket together shade the whole sky for a bot
  // that lists every lane at once, so the shared policy, not the rules, was
  // what hit it (31 of 32 fights with the policy this bot had; 0 of 32 now).
  // The family bot stays as it was: it was hit in 0 or 1 of 32, and the same
  // flag at this margin would make it worse (hit in 32 of 32; at margin .05,
  // 0 of 32).
  Skill.casual => coo.CooBot(
    react: .8,
    margin: .07,
    gap: 1.3,
    aim: .06,
    tapsPerSecond: 2.5,
    sequential: true,
  ),
};

gargoyle.Pilot _warden(Skill skill) => switch (skill) {
  // R3's three pilots (`searchlight_gargoyle_fight_test.dart`): they dodge
  // everything and differ in when and how well they shoot the lamp. The lamp
  // is judged as a rock leaves, so each fires from the moment it opens (a
  // reaction later for the slower two) until it shuts.
  Skill.sharp => gargoyle.Pilot(cadence: .3, fireFrom: 0, window: .09),
  Skill.average => gargoyle.Pilot(
    cadence: .45,
    fireFrom: .6,
    window: .3,
    offTarget: .3,
  ),
  Skill.casual => gargoyle.Pilot(
    cadence: .8,
    fireFrom: 1.0,
    window: .35,
    offTarget: .3,
  ),
};

/// The shared bot's flap, for plain comparisons.
bool sharedBot(FlightSimulation sim) => rideTheSky(sim);

/// [count] shoot phases spread over the cadences of every skill (frames; see
/// the `phase` argument of [flyNewYork]). 13 is coprime with every cadence the
/// pilots use (11, 22, 45, 108, 144), so the phases never repeat one.
List<int> spreadPhases([int count = 8]) => [
  for (var i = 0; i < count; i++) i * 13,
];

/// [plan] with its layout seed moved by [k] steps: another stone-door,
/// opening and enemy layout of the same level, as the review's
/// "re-seeded layouts" (`seed + 101 k`). Everything else is the plan's.
LevelPlan reseeded(LevelPlan plan, int k) => LevelPlan(
  id: plan.id,
  region: plan.region,
  length: plan.length,
  start: plan.start,
  seed: plan.seed + 101 * k,
  families: plan.families,
  lineup: plan.lineup,
  cadence: plan.cadence,
  toughness: plan.toughness,
  shoot: plan.shoot,
  sprint: plan.sprint,
  panels: plan.panels,
  pieces: plan.pieces,
  boss: plan.boss,
  marks: plan.marks,
  flocks: plan.flocks,
  steam: plan.steam,
);
