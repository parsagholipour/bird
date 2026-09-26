/// Mix values are relative to assets mastered with headroom. Short actions are
/// quiet; danger and cinematic cues have priority over incidental feedback.
class SoundSpec {
  const SoundSpec({
    this.volume = .42,
    this.priority = 2,
    this.seconds = .65,
    this.cooldownMs = 100,
    this.variants = 1,
  });
  final double volume, seconds;
  final int priority, cooldownMs, variants;
}

const soundBank = <String, SoundSpec>{
  'flap': SoundSpec(volume: .22, priority: 0, seconds: .30, variants: 3),
  'shoot': SoundSpec(volume: .32, priority: 3, seconds: .24, cooldownMs: 65),
  'power_shot': SoundSpec(
    volume: .38,
    priority: 3,
    seconds: .42,
    cooldownMs: 65,
  ),
  'shot_charged': SoundSpec(volume: .22, seconds: .38, cooldownMs: 250),
  'ammo_empty': SoundSpec(volume: .30, seconds: .20, cooldownMs: 150),
  'sprint': SoundSpec(volume: .40, priority: 3, seconds: .55, cooldownMs: 500),
  'sprint_ready': SoundSpec(volume: .24, seconds: .45, cooldownMs: 500),
  'rock_hit': SoundSpec(volume: .23, priority: 1, seconds: .20),
  'deflect': SoundSpec(volume: .40, seconds: .35),
  'enemy_charge': SoundSpec(
    volume: .22,
    priority: 1,
    seconds: .45,
    cooldownMs: 250,
  ),
  'enemy_shoot': SoundSpec(volume: .30, seconds: .30),
  'enemy_death': SoundSpec(
    volume: .48,
    seconds: .55,
    cooldownMs: 65,
    variants: 3,
  ),
  'bump': SoundSpec(volume: .55, priority: 3, seconds: .38, cooldownMs: 200),
  'heart': SoundSpec(volume: .48, priority: 3, seconds: .75),
  'shield_pop': SoundSpec(volume: .50, priority: 3, seconds: .42),
  'shield': SoundSpec(volume: .42, priority: 3, seconds: .65),
  'star': SoundSpec(
    volume: .08,
    priority: 1,
    seconds: .28,
    cooldownMs: 75,
    variants: 3,
  ),
  'point': SoundSpec(volume: .30, priority: 1, seconds: .35),
  'perfect': SoundSpec(volume: .20, seconds: .45),
  'streak': SoundSpec(volume: .22, seconds: .65, cooldownMs: 300),
  'magnet': SoundSpec(volume: .42, seconds: .80),
  'magnet_end': SoundSpec(volume: .24, priority: 1, seconds: .40),
  'letter': SoundSpec(volume: .32, seconds: .40),
  'letter_lost': SoundSpec(volume: .42, priority: 3, seconds: .45),
  'delivery': SoundSpec(volume: .40, seconds: .65),
  'cloud': SoundSpec(volume: .36, seconds: .80),
  'wing': SoundSpec(volume: .42, seconds: .80, cooldownMs: 500),
  'final_stretch': SoundSpec(volume: .42, priority: 3, seconds: .65),
  'ready': SoundSpec(volume: .35, priority: 3, seconds: .18, cooldownMs: 400),
  'go': SoundSpec(volume: .45, priority: 3, seconds: .60),
  'finish': SoundSpec(volume: .40, priority: 4, seconds: 1.1),
  'complete': SoundSpec(volume: .46, priority: 4, seconds: 1.2),
  'game_over': SoundSpec(volume: .70, priority: 5, seconds: 2.98),
  'record': SoundSpec(volume: .46, priority: 3, seconds: 1.0, cooldownMs: 500),
  'unlock': SoundSpec(volume: .46, priority: 4, seconds: 1.2, cooldownMs: 500),
  'ui_tap': SoundSpec(volume: .30, priority: 1, seconds: .32, cooldownMs: 85),
  'ui_back': SoundSpec(volume: .27, priority: 1, seconds: .27),
  'ui_toggle': SoundSpec(volume: .30, priority: 1, seconds: .34),
  'pause': SoundSpec(volume: .28, priority: 3, seconds: .34),
  'resume': SoundSpec(volume: .32, priority: 3, seconds: .43),
  'boss_warning': SoundSpec(
    volume: 1.0,
    priority: 4,
    seconds: 1.6,
    cooldownMs: 500,
  ),
  'boss_reveal': SoundSpec(volume: .90, priority: 4, seconds: .85),
  'boss_roar': SoundSpec(
    volume: .88,
    priority: 4,
    seconds: 1.35,
    cooldownMs: 600,
  ),
  'boss_charge': SoundSpec(
    volume: .36,
    priority: 3,
    seconds: .60,
    cooldownMs: 300,
  ),
  'boss_volley': SoundSpec(volume: .44, priority: 3, seconds: .35, variants: 2),
  'boss_hit': SoundSpec(volume: .35, seconds: .22, cooldownMs: 75, variants: 2),
  'boss_block': SoundSpec(volume: .34, seconds: .30, cooldownMs: 100),
  'boss_shield': SoundSpec(
    volume: .36,
    priority: 3,
    seconds: .55,
    cooldownMs: 500,
  ),
  'boss_summon': SoundSpec(
    volume: .40,
    priority: 3,
    seconds: .65,
    cooldownMs: 500,
  ),
  'boss_enrage': SoundSpec(
    volume: .58,
    priority: 4,
    seconds: 1.2,
    cooldownMs: 800,
  ),
  'boss_break': SoundSpec(
    volume: .58,
    priority: 4,
    seconds: .85,
    cooldownMs: 500,
  ),
  'boss_burst': SoundSpec(
    volume: .65,
    priority: 4,
    seconds: 1.2,
    cooldownMs: 500,
  ),
  'boss_victory': SoundSpec(
    volume: .52,
    priority: 4,
    seconds: 1.65,
    cooldownMs: 1000,
  ),
};

String soundAsset(String name, int variant) =>
    'audio/$name${variant == 0 ? '' : '_${variant + 1}'}.wav';
