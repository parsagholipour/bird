import '../domain/sky_boss.dart';
import 'king_coo_layout.dart';

/// Edge-triggered cues shared by live play and replay. Seeking is silent.
class BossAudioCues {
  int? _number;
  double _age = -1, _death = -1, _hit = double.negativeInfinity;
  double _shieldHit = double.negativeInfinity;
  int _volleys = 0, _summons = 0, _tideSurges = 0, _tideRises = 0;
  int _breaths = 0, _breathBlasts = 0;
  int _screechWarnings = 0, _screechBlasts = 0;
  bool _charging = false, _enraged = false, _shielded = false;
  // King Coo: rings locked, bombs tossed and burst, chests puffed, whistles
  // blown, chests popped; and the boss ages at which a fury picket's
  // squadron still owes its take-off flutter.
  int _lobLocks = 0, _lobLaunches = 0, _lobBursts = 0;
  int _puffs = 0, _whistles = 0, _pops = 0;
  final List<double> _flutters = [];
  // Searchlight Gargoyle: warnings, ignitions, lamp openings, times the bird
  // was caught, feathers dropped, and the last rock glancing off the lamp.
  int _sweepWarnings = 0, _sweepIgnitions = 0, _lampOpens = 0;
  int _spots = 0, _feathers = 0;
  double _glance = double.negativeInfinity;

  /// The mini-bosses replace the generic cues with their own: the Gargoyle's
  /// lightning strike for the reveal, his awakening for the roar, his fury and
  /// his shattering; King Coo's shout (cut to the 0.8 s his beak is open),
  /// his roar at fury, his chest inflating under the hit-stop and his
  /// deflating defeat.
  static String _reveal(SkyBoss boss) =>
      boss.isGargoyle ? 'gargoyle_strike' : 'boss_reveal';
  static String _roar(SkyBoss boss) => boss.isGargoyle
      ? 'gargoyle_awaken'
      : boss.isKingCoo
      ? 'coo_shout'
      : 'boss_roar';
  static String _fury(SkyBoss boss) => boss.isGargoyle
      ? 'gargoyle_fury'
      : boss.isKingCoo
      ? 'coo_roar'
      : 'boss_enrage';

  /// Where the reveal cue sounds. The generic encounter shows its reveal from
  /// [SkyBoss.revealAt] (1.65 s) and its crack is the file's first sample, but
  /// the dragon and King Coo hold a silhouette until a flash at 1.9 s
  /// ([KingCooTimeline.flashAt]): the cue rings 0.03 s ahead of that flash
  /// (it was 0.25 s early). The Gargoyle's strike is his own cue at 1.65 s,
  /// the instant of his lightning.
  static const flashAt = 1.9, flashLead = .03;
  static double _revealAt(SkyBoss boss) =>
      boss.isDragon || boss.isKingCoo ? flashAt - flashLead : SkyBoss.revealAt;

  /// The victory cue: 1.8 s after the last blow, but the mini-bosses' victory
  /// card begins at 1.55 s, so theirs rings with it.
  static double _victoryAt(SkyBoss boss) => boss.isMiniBoss ? 1.55 : 1.8;

  List<String> advance(SkyBoss? boss, {bool silent = false}) {
    if (boss == null) {
      _number = null;
      _age = -1;
      _death = -1;
      _charging = false;
      _enraged = false;
      _hit = double.negativeInfinity;
      _volleys = 0;
      _summons = 0;
      _tideSurges = 0;
      _tideRises = 0;
      _breaths = 0;
      _breathBlasts = 0;
      _screechWarnings = 0;
      _screechBlasts = 0;
      _lobLocks = _lobLaunches = _lobBursts = 0;
      _puffs = _whistles = _pops = 0;
      _flutters.clear();
      _sweepWarnings = _sweepIgnitions = _lampOpens = 0;
      _spots = _feathers = 0;
      _glance = double.negativeInfinity;
      _shielded = false;
      _shieldHit = double.negativeInfinity;
      return const [];
    }
    final fresh = _number != boss.number;
    final backwards = !fresh && boss.age < _age;
    final death = boss.defeatedAt == null ? -1.0 : boss.age - boss.defeatedAt!;
    final cues = <String>[];
    if (!silent && !backwards) {
      if (fresh && boss.age < .5) cues.add('boss_warning');
      if (boss.cinematic &&
          _age < _revealAt(boss) &&
          boss.age >= _revealAt(boss) &&
          !fresh) {
        cues.add(_reveal(boss));
      }
      if (boss.cinematic &&
          _age < SkyBoss.roarAt &&
          boss.age >= SkyBoss.roarAt &&
          !fresh) {
        cues.add(_roar(boss));
      }
      if (boss.phase == BossPhase.attacking) {
        if (!_enraged && boss.enraged && !fresh) cues.add(_fury(boss));
        // The Pirate Captain lights a fuse and fires a cannon.
        if (!_charging && boss.charge > 0) {
          cues.add(boss.isPirate ? 'cannon_fuse' : 'boss_charge');
        }
        if (boss.volleys > _volleys && !fresh) {
          cues.add(boss.isPirate ? 'cannon_fire' : 'boss_volley');
        }
        if (boss.tideSurges > _tideSurges && !fresh) cues.add('tide_warning');
        if (boss.tideRises > _tideRises && !fresh) cues.add('tide_surge');
        // The Ember Dragon draws a rumbling breath, then looses the flame.
        if (boss.breaths > _breaths && !fresh) cues.add('dragon_inhale');
        if (boss.breathBlasts > _breathBlasts && !fresh) {
          cues.add('dragon_breath');
        }
        // The upgraded Baron Bat's ears flare, then he screeches.
        if (boss.screechWarnings > _screechWarnings && !fresh) {
          cues.add('screech_warning');
        }
        if (boss.screechBlasts > _screechBlasts && !fresh) {
          cues.add('sonic_screech');
        }
        if (boss.isKingCoo) _kingCoo(boss, cues, fresh);
        if (boss.isGargoyle) _gargoyle(boss, cues, fresh);
        if (boss.summons > _summons && !fresh) cues.add('boss_summon');
        if (boss.shielded && !_shielded && !fresh) cues.add('boss_shield');
        if (boss.lastShieldHitAt > _shieldHit &&
            boss.age - boss.lastShieldHitAt < .2) {
          cues.add('boss_block');
        }
        if (boss.lastHitAt > _hit && boss.age - boss.lastHitAt < .2) {
          cues.add('boss_hit');
        }
      }
      if (_death < 0 && death >= 0) cues.add('boss_break');
      // King Coo's chest inflates from the end of the hit-stop to the pop.
      if (boss.isKingCoo &&
          _death < KingCooTimeline.hitStop &&
          death >= KingCooTimeline.hitStop) {
        cues.add('coo_inflate');
      }
      if (_death < SkyBoss.burstAt && death >= SkyBoss.burstAt) {
        // King Coo pops and deflates instead of bursting; the Gargoyle's
        // burst is limestone and glass in the mids, not the generic thump.
        cues.add(
          boss.isKingCoo
              ? 'coo_defeat'
              : boss.isGargoyle
              ? 'gargoyle_shatter'
              : 'boss_burst',
        );
      }
      if (_death < _victoryAt(boss) && death >= _victoryAt(boss)) {
        cues.add('boss_victory');
      }
    }
    _number = boss.number;
    _age = boss.age;
    _death = death;
    _hit = boss.lastHitAt;
    _volleys = boss.volleys;
    _summons = boss.summons;
    _tideSurges = boss.tideSurges;
    _tideRises = boss.tideRises;
    _breaths = boss.breaths;
    _breathBlasts = boss.breathBlasts;
    _screechWarnings = boss.screechWarnings;
    _screechBlasts = boss.screechBlasts;
    _lobLocks = boss.lobsLocked;
    _lobLaunches = boss.lobsLaunched;
    _lobBursts = boss.lobBursts;
    _puffs = boss.puffs;
    _whistles = boss.whistles;
    _pops = boss.pops;
    _sweepWarnings = boss.sweepWarnings;
    _sweepIgnitions = boss.sweepIgnitions;
    _lampOpens = boss.lampOpens;
    _spots = boss.spots;
    _feathers = boss.feathersLaunched;
    _glance = boss.lastGlanceAt;
    // A silent step or a rewind forgets take-offs that were still to come.
    if (silent || backwards) _flutters.clear();
    _shieldHit = boss.lastShieldHitAt;
    _shielded = boss.shielded;
    _charging = boss.charge > 0;
    _enraged = boss.enraged;
    return cues;
  }

  /// King Coo: the ring locks (the wind-up), the bomb is tossed and bursts,
  /// the chest puffs, the whistle blows (and the squadron takes off), and a
  /// pop. Whistles are counted by the rules, so a pop before the whistle
  /// cancels both cues. A fury picket follows its V by `delay` seconds and
  /// gets its own take-off flutter then.
  void _kingCoo(SkyBoss boss, List<String> cues, bool fresh) {
    if (fresh) return;
    if (boss.lobsLocked > _lobLocks) cues.add('boss_charge');
    if (boss.lobsLaunched > _lobLaunches) cues.add('crumb_throw');
    if (boss.lobBursts > _lobBursts) cues.add('crumb_splat');
    if (boss.puffs > _puffs) cues.add('coo_puff');
    if (boss.whistles > _whistles) {
      cues
        ..add('coo_whistle')
        ..add('squad_flutter');
      for (final plan in boss.squad) {
        if (plan.delay > 0) _flutters.add(boss.age + plan.delay);
      }
    }
    if (boss.pops > _pops) cues.add('coo_pop');
    if (_flutters.isNotEmpty) {
      final due = _flutters.where((at) => at <= boss.age).length;
      _flutters.removeWhere((at) => at <= boss.age);
      if (due > 0) cues.add('squad_flutter');
    }
  }

  /// Searchlight Gargoyle: the warning before a sweep, the beam's ignition,
  /// the lamp opening, the bird caught, a feather dropped, and a rock
  /// clinking off the shuttered lamp.
  void _gargoyle(SkyBoss boss, List<String> cues, bool fresh) {
    if (fresh) return;
    if (boss.sweepWarnings > _sweepWarnings) cues.add('beam_warning');
    if (boss.sweepIgnitions > _sweepIgnitions) cues.add('beam_sweep');
    if (boss.lampOpens > _lampOpens) cues.add('lamp_vent');
    if (boss.spots > _spots) cues.add('beam_spot');
    if (boss.feathersLaunched > _feathers) cues.add('feather_drop');
    if (boss.lastGlanceAt > _glance && boss.age - boss.lastGlanceAt < .2) {
      cues.add('lamp_glance');
    }
  }
}
