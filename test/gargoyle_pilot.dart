import 'dart:math' as math;

import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'campaign_flight.dart';
import 'gargoyle_viability.dart';
import 'ny_plans.dart';

/// Test pilots for the Searchlight Gargoyle: players that tap no faster than
/// five times a second, dodge his beams and feathers, and shoot when his lamp
/// is open. The shared `rideTheSky` bot has no notion of a beam.

const birdX = FlightSimulation.birdX, birdR = FlightSimulation.birdRadius;

/// The plan the New York program will ship for 3-4: a 30 s run-up and the
/// Searchlight Gargoyle (simplified: the catalog's real 3-4 adds the alley's
/// lineup, pigeon flocks and a steam layer; see ny_campaign_data_test).
LevelPlan gargoylePlan({
  List<EnemyKind> lineup = const [EnemyKind.simpleBat, EnemyKind.caveBat],
}) => nyPlan(
  id: '3-4',
  seed: 3104,
  lineup: lineup,
  boss: BossKind.searchlightGargoyle,
);

/// Sets the boss's combat clock to [t] seconds into the fight.
void fightAt(SkyBoss boss, double t) => boss.age = boss.arrivalDuration + t;

/// Each flight's own clock for [frame], in ms: a sample's time must only
/// ever increase, even across a pause.
final _clocks = Expando<double>('gargoyle test clocks');

/// One frame of [dt]: a tap if [flap], then the simulation.
void frame(
  FlightSimulation sim, {
  bool flap = false,
  double dt = 1 / 60,
  double width = 2.2,
}) {
  final now =
      (_clocks[sim] ?? (sim.lastValidMs.isFinite ? sim.lastValidMs : 0.0)) +
      dt * 1000;
  _clocks[sim] = now;
  sim.apply(
    MovementInput(valid: true, flap: flap),
    TrackingSample(
      mode: PlayMode.touch,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
  sim.tick(dt, now, viewportWidth: width);
}

/// A level flight of [plan] stopped as the Gargoyle begins to fight (combat
/// time 0, control just back), the run-up flown by the shared bot with no
/// sprint. The bird sits at mid-height with the shield up and three hearts.
FlightSimulation arena({
  double width = 2.2,
  int weaponDamage = BirdRock.baseDamage,
  LevelPlan? plan,
  int version = FlightSimulation.currentRulesVersion,
}) {
  final sim = nyFlight(
    plan ?? gargoylePlan(),
    weaponDamage: weaponDamage,
    version: version,
  );
  flyLevel(
    sim,
    viewportWidth: width,
    sprintWhen: (sim, frame) => false,
    until: (sim) => sim.boss?.phase == BossPhase.attacking,
  );
  final boss = sim.boss;
  if (boss == null || !boss.isGargoyle || boss.phase != BossPhase.attacking) {
    throw StateError('the flight did not reach the Gargoyle');
  }
  sim
    ..rocks.clear()
    ..bossAmmo.clear()
    ..birdY = .5
    ..velocity = 0
    ..hearts = 3
    ..shield = true
    ..invulnerableUntil = 0;
  return sim;
}

/// A pilot: a player who taps no faster than five times a second (the search
/// below plans within that), dodges the Gargoyle's beams and feathers, and
/// shoots when his lamp is open.
///
/// Through each cycle's perch, warning and sweep it re-plans every few frames
/// with the same exhaustive search the fairness proof uses ([Search]), from
/// the live state: a player who always finds a safe path. Outside the plan
/// (before the perch feather leaves, and in the vent) it hovers at the lamp's
/// height by flapping when below its target.
class Pilot {
  Pilot({
    this.cadence = .3,
    this.fireFrom = 0,
    this.window = .09,
    this.offTarget = 0,
    this.careful = true,
    this.lagFrames = 0,
    int seed = 1,
  }) : _random = math.Random(seed);

  /// Seconds between shots; when to start firing, in seconds from the lamp's
  /// opening (the lamp is judged as a rock leaves, so firing before it opens
  /// glances: 0 is the earliest that counts); how far from the lamp's height
  /// the pilot still fires; and how far off it the pilot's hover wanders (its
  /// misses).
  final double cadence, fireFrom, window, offTarget;

  /// Whether the pilot plans its dodges; a careless one only hovers.
  final bool careful;

  /// Frames (1/60 s) between the pilot deciding to tap and the tap landing: a
  /// thumb's and a screen's lag. The pilot knows it: it plans from where the
  /// bird will be once the taps already on their way have landed, and each tap
  /// it chooses reaches the bird this much late. (A player with a jittery,
  /// unknown lag and no plan is the Monte Carlo of `gargoyle_lag.dart`.)
  final int lagFrames;
  final _decisions = <int, bool>{};
  int _frame = 0;
  final math.Random _random;
  double _aimError = 0, _lastShotAt = double.negativeInfinity;
  int _aimedCycle = -1, _plannedCycle = -1, _plannedAt = -1000;
  int get plannedAt => _plannedAt;
  Set<int> _taps = const {};

  /// Frames of [dt] in a cycle where the plan ends: the vent's start plus a
  /// tail long enough for the last feather to have crossed.
  static const tail = .45;

  /// Hover target when nothing burns: at the lamp's height, wandering.
  double target(FlightSimulation sim) {
    final boss = sim.boss!;
    if (boss.phase == BossPhase.attacking && boss.lampOpen) {
      if (boss.gargoyleCycleNumber != _aimedCycle) {
        _aimedCycle = boss.gargoyleCycleNumber;
        _aimError = (_random.nextDouble() * 2 - 1) * offTarget;
      }
      return .56 + _aimError;
    }
    return .5;
  }

  bool _hover(FlightSimulation sim) =>
      sim.birdY > target(sim) && sim.velocity > -.25;

  /// Re-plans from the live state; false when no safe path exists.
  bool _plan(FlightSimulation sim, SkyBoss boss, int now) {
    // Where the bird will be, and when, as the tap decided now lands: after
    // the taps already decided have landed one by one.
    var y = sim.birdY, v = sim.velocity;
    var since = ((sim.elapsed - sim.lastFlapAt) / dt).round().clamp(0, 15);
    var aimedSide = boss.sweepsAimed > boss.gargoyleCycleNumber
        ? boss.beamSide
        : null;
    for (var j = 0; j < lagFrames; j++) {
      if (aimedSide == null && now + j >= Search.warnStep) {
        aimedSide = SearchlightGargoyle.aimAt(y);
      }
      final tap = _decisions[_frame + j - lagFrames] ?? false;
      if (tap) v = flapImpulse;
      since = tap ? 1 : math.min(since + 1, 15);
      v += gravity * dt / 2;
      y += v * dt / 2;
      v += gravity * dt / 2;
      y += v * dt / 2;
    }
    final step = now + lagFrames;
    final aimed = aimedSide != null;
    final slit = aimed
        ? boss.slitSweep
        : SearchlightGargoyle.slitAt(
            enraged: boss.enraged,
            furySweeps: boss.furySweeps,
          );
    final sweep = slit
        ? Sweep.furySlit
        : boss.enraged
        ? Sweep.furyZone
        : Sweep.calm;
    final flying = <(int, double)>[];
    final flyingFury = <bool>[];
    for (final f in sim.bossAmmo.where((a) => a.feather && a.x > birdX - .15)) {
      final speed = -f.vx;
      final age = (SearchlightGargoyle.featherOffsetX - (f.x - birdX)) / speed;
      final flight = SearchlightGargoyle.featherOffsetX / speed;
      final vy0 = f.vy - f.gravity * age;
      final lane =
          SearchlightGargoyle.featherY +
          vy0 * flight +
          .5 * f.gravity * flight * flight;
      flying.add((now - (age / dt).round(), lane));
      flyingFury.add(speed > SearchlightGargoyle.featherSpeed + .01);
    }
    // A comfortable margin first; a tighter one if the pilot has put itself
    // in a corner.
    SearchResult? result;
    for (final margin in const [.012, .002]) {
      final search = Search(sweep, margin: margin, tail: tail, substeps: 2);
      result = search.fromState(
        step,
        y,
        v,
        since,
        aimedSide,
        flying,
        inFlightFury: flyingFury,
      );
      if (result.safe) break;
    }
    _taps = result!.taps.toSet();
    _plannedAt = now;
    _plannedCycle = boss.gargoyleCycleNumber;
    return result.safe;
  }

  /// Whether to tap this frame.
  bool flap(FlightSimulation sim) {
    final boss = sim.boss!;
    if (careful &&
        boss.phase == BossPhase.attacking &&
        boss.featherCycle == boss.gargoyleCycleNumber &&
        boss.featherSlot >= 1) {
      final step = (boss.gargoyleCycle / dt).round();
      final end = ((SearchlightGargoyle.ventAt + tail) / dt).round();
      if (step < end) {
        if (_plannedCycle != boss.gargoyleCycleNumber ||
            step - _plannedAt >= 8) {
          if (!_plan(sim, boss, step)) {
            _plannedAt = -1000;
            return _hover(sim);
          }
        }
        // The tap decided now lands [lagFrames] frames on.
        return _taps.contains(step + lagFrames);
      }
    }
    return _hover(sim);
  }

  /// Whether to fire now: from [fireFrom] after the lamp opens until it
  /// closes (a rock that leaves while it is open counts however long it
  /// flies), when level with the lamp.
  bool shoot(FlightSimulation sim) {
    final boss = sim.boss;
    if (boss == null || boss.phase != BossPhase.attacking) return false;
    final x = boss.gargoyleCycle;
    if (x < SearchlightGargoyle.ventAt + fireFrom) return false;
    if ((sim.birdY - SearchlightGargoyle.anchorY).abs() > window) return false;
    if (sim.elapsed - _lastShotAt < cadence || !sim.canShoot) return false;
    _lastShotAt = sim.elapsed;
    return true;
  }

  /// One frame: the pilot's tap and shot.
  void fly(FlightSimulation sim, {double width = 2.2}) {
    _frame++;
    final decided = flap(sim);
    _decisions[_frame] = decided;
    // The tap that reaches the bird this frame was decided [lagFrames] ago.
    final tap = lagFrames == 0 ? decided : _decisions[_frame - lagFrames] ?? false;
    _decisions.remove(_frame - lagFrames - 1);
    if (shoot(sim)) sim.shoot();
    frame(sim, flap: tap, width: width);
  }
}
