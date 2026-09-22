import '../domain/game_rules.dart';

/// Reads combat outcomes, never guesses a death from a disappearing enemy.
/// A silent snapshot after seeking prevents historical sounds playing again.
class CombatAudioCues {
  FlightSimulation? _simulation;
  int _shots = 0, _deaths = 0, _impacts = 0, _deflections = 0, _enemyShots = 0;
  final Set<SkyEnemy> _charging = {};
  double _elapsed = 0;
  bool _magnet = false;
  int _lettersDropped = 0;
  int _doorsDestroyed = 0;

  List<String> advance(FlightSimulation sim, {bool silent = false}) {
    final fresh = !identical(_simulation, sim);
    final backwards = !fresh && sim.elapsed < _elapsed;
    final cues = <String>[];
    if (!fresh && !silent && !backwards) {
      if (sim.shots > _shots) cues.add('shoot');
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
