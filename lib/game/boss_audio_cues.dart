import '../domain/sky_boss.dart';

/// Edge-triggered cues shared by live play and replay. Seeking is silent.
class BossAudioCues {
  int? _number;
  double _age = -1, _death = -1, _hit = double.negativeInfinity;
  double _shieldHit = double.negativeInfinity;
  int _volleys = 0, _summons = 0;
  bool _charging = false, _enraged = false, _shielded = false;

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
          _age < SkyBoss.revealAt &&
          boss.age >= SkyBoss.revealAt &&
          !fresh) {
        cues.add('boss_reveal');
      }
      if (boss.cinematic &&
          _age < SkyBoss.roarAt &&
          boss.age >= SkyBoss.roarAt &&
          !fresh) {
        cues.add('boss_roar');
      }
      if (boss.phase == BossPhase.attacking) {
        if (!_enraged && boss.enraged && !fresh) cues.add('boss_enrage');
        if (!_charging && boss.charge > 0) cues.add('boss_charge');
        if (boss.volleys > _volleys && !fresh) cues.add('boss_volley');
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
      if (_death < SkyBoss.burstAt && death >= SkyBoss.burstAt) {
        cues.add('boss_burst');
      }
      if (_death < 1.8 && death >= 1.8) cues.add('boss_victory');
    }
    _number = boss.number;
    _age = boss.age;
    _death = death;
    _hit = boss.lastHitAt;
    _volleys = boss.volleys;
    _summons = boss.summons;
    _shieldHit = boss.lastShieldHitAt;
    _shielded = boss.shielded;
    _charging = boss.charge > 0;
    _enraged = boss.enraged;
    return cues;
  }
}
