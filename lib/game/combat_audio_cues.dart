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
  int _allRings = 0;
  int _eruptions = 0, _gusts = 0, _galeWarnings = 0, _galesWeathered = 0;
  int _splashes = 0, _emberSplits = 0;
  // New York: Alley Pigeon raids and Steam Geysers.
  int _pigeonWarnings = 0, _pigeonDives = 0, _snatches = 0, _freed = 0;
  int _pigeonDefeats = 0;
  int _steamHisses = 0, _steamBursts = 0, _steamRides = 0;
  // When (flight seconds) a pigeon last landed a snatch or a rescued star
  // sounded, and a steam burst last sounded: they mask each other.
  double _landedAt = double.negativeInfinity,
      _burstAt = double.negativeInfinity;
  final Set<SkyEnemy> _charging = {}, _winding = {};
  double _elapsed = 0;
  bool _magnet = false;

  /// Whether the flight's boss had sent its vanguard: the boss's warning
  /// sounds as the vanguard begins, and again as the boss arrives.
  bool _vanguard = false;

  /// Per bird, so either co-op player's charge and recharge chime.
  List<bool> _fullCharge = const [], _sprintReady = const [];
  int _doorsDestroyed = 0;

  /// A vent only sounds while it is near the bird: between a little behind it
  /// and just past the right edge of the screen (report 03 §4). With no live
  /// vent listed the rules' counters are taken at their word.
  static bool _ventAudible(FlightSimulation sim) =>
      sim.steamVents.isEmpty ||
      sim.steamVents.any(
        (vent) =>
            vent.x >= FlightSimulation.birdX - .1 &&
            vent.x <= FlightSimulation.birdX + 1.8,
      );

  /// A steam burst and a pigeon's snatch (or a star won back) within this
  /// many seconds of each other would hide one another: the burst's 5-6 kHz
  /// hiss masks the snatch's 2.8 kHz onset (the review measured them 33 ms
  /// apart at the same loudness). The cue layer plays the burst and its clang
  /// ducked (`steam_burst_duck`, `pipe_clang_duck`: 5 and 8 dB lower) when the
  /// snatch is first or at the same step, and lifts the snatch
  /// (`pigeon_snatch_lift`: 3 dB) when the burst was first.
  static const duckWindow = .3;
  static bool _near(double now, double then) =>
      now - then >= 0 && now - then <= duckWindow;

  /// Pigeons never ring the shooters' `enemy_charge`: their telegraph is the
  /// coo that [advance] plays for each warning.
  static bool _chargesUp(SkyEnemy e) =>
      e.charge > 0 && e.kind != EnemyKind.alleyPigeon;

  /// King Coo's vanguard pigeons (rules 45) coo as they wind up a throw.
  static bool _windsUp(SkyEnemy e) => e.charge > 0 && e.throwsCrumbs;

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
    // A seek or a new flight forgets the last snatch and burst.
    if (fresh || silent || backwards) {
      _landedAt = _burstAt = double.negativeInfinity;
    }
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
      // Every ring of a run: the power-up chime and a fresh turbo whoosh.
      if (sim.allRingsBonuses > _allRings) cues.addAll(['streak', 'sprint']);
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
      if (sim.vanguard != null && !_vanguard) cues.add('boss_warning');
      // Swarm bats go down like any bat; a pigeon has its own defeat.
      if (sim.enemiesDefeated - sim.pigeonsDefeated + sim.swarmSmashed >
          _deaths) {
        cues.add('enemy_death');
      }
      // Alley Pigeon: the coo as it marks its star, the flap as it dives,
      // the snatch, the star won back, its own defeat.
      if (sim.pigeonWarnings > _pigeonWarnings) cues.add('pigeon_coo');
      if (sim.pigeonDives > _pigeonDives) cues.add('pigeon_flap');
      final snatched = sim.starsSnatched > _snatches;
      final landed = snatched || sim.starsFreed > _freed;
      if (snatched) {
        cues.add(
          _near(sim.elapsed, _burstAt) ? 'pigeon_snatch_lift' : 'pigeon_snatch',
        );
      }
      if (sim.starsFreed > _freed) cues.add('star_rescue');
      if (sim.pigeonsDefeated > _pigeonDefeats) cues.add('pigeon_defeat');
      // Steam Geysers: the hiss of the warning, the burst (with the grate's
      // clang), the updraft that catches the bird.
      if (_ventAudible(sim)) {
        if (sim.steamHisses > _steamHisses) cues.add('steam_hiss');
        if (sim.steamBursts > _steamBursts) {
          final ducked = landed || _near(sim.elapsed, _landedAt);
          cues.addAll(
            ducked
                ? ['steam_burst_duck', 'pipe_clang_duck']
                : ['steam_burst', 'pipe_clang'],
          );
          _burstAt = sim.elapsed;
        }
        if (sim.steamRides > _steamRides) cues.add('steam_ride');
      }
      if (landed) _landedAt = sim.elapsed;
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
      if (sim.enemies.any((e) => _chargesUp(e) && !_charging.contains(e))) {
        cues.add('enemy_charge');
      }
      if (sim.enemies.any((e) => _windsUp(e) && !_winding.contains(e))) {
        cues.add('pigeon_coo');
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
    _allRings = sim.allRingsBonuses;
    _smashes = sim.smashes + sim.meteorsSmashed;
    _rushWarnings = sim.rushWarnings;
    _rushEscapes = sim.rushPathsEscaped;
    _eruptions = sim.ventsErupted;
    _gusts = sim.gusts;
    _galeWarnings = sim.galeWarnings;
    _vanguard = sim.vanguard != null;
    _galesWeathered = sim.galesWeathered;
    _deaths = sim.enemiesDefeated - sim.pigeonsDefeated + sim.swarmSmashed;
    _pigeonWarnings = sim.pigeonWarnings;
    _pigeonDives = sim.pigeonDives;
    _snatches = sim.starsSnatched;
    _freed = sim.starsFreed;
    _pigeonDefeats = sim.pigeonsDefeated;
    _steamHisses = sim.steamHisses;
    _steamBursts = sim.steamBursts;
    _steamRides = sim.steamRides;
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
      ..addAll(sim.enemies.where(_chargesUp));
    _winding
      ..clear()
      ..addAll(sim.enemies.where(_windsUp));
    return cues;
  }
}
