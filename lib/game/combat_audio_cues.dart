import '../domain/game_rules.dart';

/// Reads combat outcomes, never guesses a death from a disappearing enemy.
/// A silent snapshot after seeking prevents historical sounds playing again.
class CombatAudioCues {
  // Weaker charged rocks keep the ordinary shot; strong ones sound heavier.
  static const powerShotCharge = .35;
  FlightSimulation? _simulation;
  int _shots = 0, _deaths = 0, _impacts = 0, _deflections = 0, _enemyShots = 0;
  int _dryFires = 0, _sprints = 0;
  final Set<SkyEnemy> _charging = {};
  double _elapsed = 0;
  bool _magnet = false, _fullCharge = false, _sprintReady = false;
  int _lettersDropped = 0;
  int _doorsDestroyed = 0;

  List<String> advance(FlightSimulation sim, {bool silent = false}) {
    final fresh = !identical(_simulation, sim);
    final backwards = !fresh && sim.elapsed < _elapsed;
    final fullCharge = sim.shotCharge >= 1;
    // Only a recharge after a used sprint chimes, never the flight start.
    final sprintReady = sim.sprints > 0 && sim.sprintCooldownRemaining == 0;
    final cues = <String>[];
    if (!fresh && !silent && !backwards) {
      if (sim.shots > _shots) {
        cues.add(
          sim.lastShotCharge >= powerShotCharge ? 'power_shot' : 'shoot',
        );
      }
      if (sim.dryFires > _dryFires) cues.add('ammo_empty');
      if (fullCharge && !_fullCharge) cues.add('shot_charged');
      if (sim.sprints > _sprints) cues.add('sprint');
      if (sprintReady && !_sprintReady) cues.add('sprint_ready');
      if (sim.enemiesDefeated > _deaths) cues.add('enemy_death');
      if (sim.rockImpacts > _impacts) cues.add('rock_hit');
      if (sim.projectilesDeflected > _deflections) cues.add('deflect');
      if (sim.enemyShots > _enemyShots) cues.add('enemy_shoot');
      if (sim.doorsDestroyed > _doorsDestroyed) {
        cues.addAll(['boss_break', 'unlock']);
      }
      if (_magnet && !sim.magnetActive && sim.phase == RunPhase.playing) {
        cues.add('magnet_end');
      }
      if (sim.lettersDropped > _lettersDropped) cues.add('letter_lost');
      if (sim.enemies.any((e) => e.charge > 0 && !_charging.contains(e))) {
        cues.add('enemy_charge');
      }
    }
    _simulation = sim;
    _elapsed = sim.elapsed;
    _shots = sim.shots;
    _dryFires = sim.dryFires;
    _fullCharge = fullCharge;
    _sprints = sim.sprints;
    _sprintReady = sprintReady;
    _deaths = sim.enemiesDefeated;
    _impacts = sim.rockImpacts;
    _deflections = sim.projectilesDeflected;
    _enemyShots = sim.enemyShots;
    _magnet = sim.magnetActive;
    _lettersDropped = sim.lettersDropped;
    _doorsDestroyed = sim.doorsDestroyed;
    _charging
      ..clear()
      ..addAll(sim.enemies.where((e) => e.charge > 0));
    return cues;
  }
}
