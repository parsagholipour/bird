import '../domain/game_rules.dart';

/// Reads combat outcomes, never guesses a death from a disappearing enemy.
/// A silent snapshot after seeking prevents historical sounds playing again.
class CombatAudioCues {
  // Weaker charged rocks keep the ordinary shot; strong ones sound heavier,
  // and those are the ones that shatter enemy pellets.
  static const powerShotCharge = PowerShot.shatterCharge;
  FlightSimulation? _simulation;
  int _shots = 0, _deaths = 0, _impacts = 0, _deflections = 0, _enemyShots = 0;
  int _shatters = 0;
  int _dryFires = 0, _sprints = 0;
  int _ringSprints = 0, _smashes = 0, _rushWarnings = 0, _rushEscapes = 0;
  int _eruptions = 0, _gusts = 0, _galeWarnings = 0, _galesWeathered = 0;
  int _splashes = 0, _emberSplits = 0;
  final Set<SkyEnemy> _charging = {};
  double _elapsed = 0;
  bool _magnet = false;

  /// Per bird, so either co-op player's charge and recharge chime.
  List<bool> _fullCharge = const [], _sprintReady = const [];
  int _doorsDestroyed = 0;

  List<String> advance(FlightSimulation sim, {bool silent = false}) {
    final fresh = !identical(_simulation, sim);
    final backwards = !fresh && sim.elapsed < _elapsed;
    final fullCharge = [
      for (final bird in sim.flock)
        sim.viewing(bird, () => sim.shotCharge >= 1),
    ];
    // Only a recharge after a used sprint chimes, never the flight start.
    final sprintReady = [
      for (final bird in sim.flock)
        sim.viewing(
          bird,
          () =>
              (sim.paired ? bird.sprints : sim.sprints) > 0 &&
              sim.sprintCooldownRemaining == 0,
        ),
    ];
    bool rose(List<bool> now, List<bool> before) => [
      for (var i = 0; i < now.length; i++)
        now[i] && !(i < before.length && before[i]),
    ].any((risen) => risen);
    final cues = <String>[];
    if (!fresh && !silent && !backwards) {
      if (sim.shots > _shots) {
        cues.add(
          sim.lastShotCharge >= powerShotCharge ? 'power_shot' : 'shoot',
        );
      }
      if (sim.dryFires > _dryFires) cues.add('ammo_empty');
      if (rose(fullCharge, _fullCharge)) cues.add('shot_charged');
      if (sim.sprints > _sprints) cues.add('sprint');
      if (rose(sprintReady, _sprintReady)) cues.add('sprint_ready');
      if (sim.ringSprints > _ringSprints) {
        cues.add('sprint_ring');
        // Only the start of a chain gets the sprint's whoosh and voice.
        if (sim.ringChain == 1) cues.add('sprint');
      }
      if (sim.smashes + sim.meteorsSmashed > _smashes) {
        cues.add('rubble_smash');
      }
      if (sim.ventsErupted > _eruptions) cues.add('lava_burst');
      if (sim.rushWarnings > _rushWarnings) cues.add('rush_alarm');
      if (sim.rushPathsEscaped > _rushEscapes) cues.add('rush_clear');
      // A gale shares the rush alarm and fanfare; each gust whistles as
      // its warning goes up.
      if (sim.galeWarnings > _galeWarnings) cues.add('rush_alarm');
      if (sim.gusts > _gusts) cues.add('gust_warning');
      if (sim.galesWeathered > _galesWeathered) cues.add('rush_clear');
      // Swarm bats go down like any bat.
      if (sim.enemiesDefeated + sim.swarmSmashed > _deaths) {
        cues.add('enemy_death');
      }
      if (sim.rockImpacts > _impacts) cues.add('rock_hit');
      // Cannonballs and the bird hitting the Pirate Captain's sea.
      if (sim.cannonSplashes + sim.birdSplashes > _splashes) {
        cues.add('sea_splash');
      }
      // An Ember Dragon fireball bursting into embers.
      if (sim.emberSplits > _emberSplits) cues.add('ember_split');
      if (sim.projectilesDeflected > _deflections) cues.add('deflect');
      // A shattered pellet also bursts under the deflect's ping.
      if (sim.ammoShattered > _shatters) cues.add('lava_burst');
      if (sim.enemyShots > _enemyShots) cues.add('enemy_shoot');
      if (sim.doorsDestroyed > _doorsDestroyed) {
        cues.addAll(['boss_break', 'unlock']);
      }
      if (_magnet && !sim.magnetActive && sim.phase == RunPhase.playing) {
        cues.add('magnet_end');
      }
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
    _ringSprints = sim.ringSprints;
    _smashes = sim.smashes + sim.meteorsSmashed;
    _rushWarnings = sim.rushWarnings;
    _rushEscapes = sim.rushPathsEscaped;
    _eruptions = sim.ventsErupted;
    _gusts = sim.gusts;
    _galeWarnings = sim.galeWarnings;
    _galesWeathered = sim.galesWeathered;
    _deaths = sim.enemiesDefeated + sim.swarmSmashed;
    _impacts = sim.rockImpacts;
    _splashes = sim.cannonSplashes + sim.birdSplashes;
    _emberSplits = sim.emberSplits;
    _deflections = sim.projectilesDeflected;
    _shatters = sim.ammoShattered;
    _enemyShots = sim.enemyShots;
    _magnet = sim.magnetActive;
    _doorsDestroyed = sim.doorsDestroyed;
    _charging
      ..clear()
      ..addAll(sim.enemies.where((e) => e.charge > 0));
    return cues;
  }
}
