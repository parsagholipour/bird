/// Mix values are relative to assets mastered with headroom. Short actions are
/// quiet; danger and cinematic cues have priority over incidental feedback.
class SoundSpec {
  const SoundSpec({
    this.volume = .42,
    this.priority = 2,
    this.seconds = .65,
    this.cooldownMs = 100,
    this.variants = 1,
    this.file,
    this.duck,
  });
  final double volume, seconds;
  final int priority, cooldownMs, variants;

  /// The name of the cue whose WAV this one plays, when it is only another
  /// level of it (the cue layer ducks and lifts cues this way): the files are
  /// [file]'s, and `tool/prepare_sound_effects.py` renders nothing for it.
  final String? file;

  /// The music's level while this cue plays, as a multiplier of its usual
  /// level, or null to leave the music alone. The music comes back up when
  /// the cue's [seconds] have passed; a later ducking cue extends that.
  final double? duck;
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
  // Chained rings climb in pitch: the variant follows the chain, not rotation.
  'sprint_ring': SoundSpec(
    volume: .34,
    priority: 3,
    seconds: .42,
    cooldownMs: 90,
    variants: 3,
  ),
  'rubble_smash': SoundSpec(
    volume: .46,
    priority: 3,
    seconds: .40,
    cooldownMs: 60,
    variants: 3,
  ),
  'lava_burst': SoundSpec(
    volume: .40,
    seconds: .70,
    cooldownMs: 150,
    variants: 2,
  ),
  'rush_alarm': SoundSpec(
    volume: .60,
    priority: 4,
    seconds: 1.3,
    cooldownMs: 1000,
  ),
  // A rising whistle as each gust's warning goes up.
  'gust_warning': SoundSpec(
    volume: .30,
    priority: 3,
    seconds: .45,
    cooldownMs: 120,
  ),
  'rush_clear': SoundSpec(
    volume: .48,
    priority: 4,
    seconds: 1.1,
    cooldownMs: 1000,
  ),
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
  // Pirate Captain: fuse, cannon boom, the tide's bell and surge, splashes.
  'cannon_fuse': SoundSpec(
    volume: .30,
    priority: 3,
    seconds: .60,
    cooldownMs: 300,
  ),
  'cannon_fire': SoundSpec(
    volume: .55,
    priority: 3,
    seconds: .90,
    cooldownMs: 120,
    variants: 2,
  ),
  'tide_warning': SoundSpec(
    volume: .62,
    priority: 4,
    seconds: 1.30,
    cooldownMs: 1000,
  ),
  'tide_surge': SoundSpec(
    volume: .50,
    priority: 4,
    seconds: 1.10,
    cooldownMs: 1000,
  ),
  'sea_splash': SoundSpec(
    volume: .36,
    seconds: .55,
    cooldownMs: 90,
    variants: 2,
  ),
  // Ember Dragon: the inhale before its breath, the flame's roar, and a
  // fireball bursting into embers.
  'dragon_inhale': SoundSpec(
    volume: .62,
    priority: 4,
    seconds: 1.45,
    cooldownMs: 1000,
  ),
  'dragon_breath': SoundSpec(
    volume: .58,
    priority: 4,
    seconds: 1.60,
    cooldownMs: 1000,
  ),
  'ember_split': SoundSpec(volume: .34, seconds: .45, cooldownMs: 120),
  // Baron Bat, upgraded: sonar chirps quickening as his ears flare, then the
  // screech that sweeps the sky.
  'screech_warning': SoundSpec(
    volume: .52,
    priority: 4,
    seconds: 1.45,
    cooldownMs: 1000,
  ),
  'sonic_screech': SoundSpec(
    volume: .46,
    priority: 4,
    seconds: 1.20,
    cooldownMs: 1000,
  ),
  // ---- New York (rules version 43) -------------------------------------
  // Alley Pigeon: a coo as it marks its star, a flap as it dives, the snatch,
  // the pigeon's own defeat and the freed star's chime. Takes rotate; the
  // second coo is a whole tone higher.
  'pigeon_coo': SoundSpec(
    volume: .30,
    priority: 1,
    seconds: .55,
    cooldownMs: 180,
    variants: 2,
  ),
  'pigeon_flap': SoundSpec(
    volume: .42,
    priority: 1,
    seconds: .34,
    cooldownMs: 80,
    variants: 2,
  ),
  'pigeon_snatch': SoundSpec(
    volume: .60,
    priority: 3,
    seconds: .42,
    cooldownMs: 120,
  ),
  'pigeon_defeat': SoundSpec(
    volume: .34,
    priority: 2,
    seconds: .50,
    cooldownMs: 65,
    variants: 2,
  ),
  'star_rescue': SoundSpec(
    volume: .34,
    priority: 3,
    seconds: .45,
    cooldownMs: 100,
  ),
  // Steam Geysers: the hiss builds for the vent's whole warning, the burst
  // and the grate's clang land together, the puff lifts the bird.
  'steam_hiss': SoundSpec(
    volume: .40,
    priority: 3,
    seconds: 1.50,
    cooldownMs: 500,
  ),
  'steam_burst': SoundSpec(
    volume: .52,
    priority: 3,
    seconds: .80,
    cooldownMs: 250,
    variants: 2,
  ),
  'pipe_clang': SoundSpec(
    volume: .26,
    priority: 1,
    seconds: .45,
    cooldownMs: 250,
    variants: 2,
  ),
  'steam_ride': SoundSpec(
    volume: .40,
    priority: 2,
    seconds: .60,
    cooldownMs: 400,
  ),
  // Searchlight Gargoyle: lightning on the rod and the stone waking (they
  // replace the reveal and the roar), the warning before a sweep, the sweep's
  // buzz, the bird caught, the lamp opening, rocks glancing off the shuttered
  // lamp and a stone feather dropping.
  'gargoyle_strike': SoundSpec(
    volume: .85,
    priority: 4,
    seconds: 1.10,
    cooldownMs: 1000,
  ),
  'gargoyle_awaken': SoundSpec(
    volume: .85,
    priority: 4,
    seconds: 2.00,
    cooldownMs: 1000,
  ),
  'beam_warning': SoundSpec(
    volume: .65,
    priority: 4,
    seconds: 1.50,
    cooldownMs: 1000,
  ),
  'beam_sweep': SoundSpec(
    volume: .42,
    priority: 3,
    seconds: 2.90,
    cooldownMs: 1000,
  ),
  'beam_spot': SoundSpec(
    volume: .55,
    priority: 3,
    seconds: .40,
    cooldownMs: 400,
  ),
  'lamp_vent': SoundSpec(
    volume: .40,
    priority: 3,
    seconds: 1.30,
    cooldownMs: 1000,
  ),
  'lamp_glance': SoundSpec(
    volume: .30,
    priority: 2,
    seconds: .25,
    cooldownMs: 75,
    variants: 2,
  ),
  'feather_drop': SoundSpec(
    volume: .28,
    priority: 2,
    seconds: .55,
    cooldownMs: 150,
    variants: 2,
  ),
  // King Coo: his roar (arrival and fury), the pea whistle, the crumb bomb's
  // toss and splat, the squadron's take-off, the chest puffing and popping,
  // and the deflating defeat.
  'coo_roar': SoundSpec(
    volume: .95,
    priority: 4,
    seconds: 1.60,
    cooldownMs: 600,
  ),
  'coo_whistle': SoundSpec(
    volume: .30,
    priority: 4,
    seconds: .85,
    cooldownMs: 500,
  ),
  'crumb_throw': SoundSpec(
    volume: .40,
    priority: 3,
    seconds: .36,
    cooldownMs: 150,
  ),
  'crumb_splat': SoundSpec(
    volume: .45,
    priority: 3,
    seconds: .60,
    cooldownMs: 150,
  ),
  'squad_flutter': SoundSpec(
    volume: .42,
    priority: 3,
    seconds: .95,
    cooldownMs: 500,
  ),
  'coo_puff': SoundSpec(
    volume: .42,
    priority: 4,
    seconds: 1.50,
    cooldownMs: 800,
  ),
  'coo_pop': SoundSpec(volume: .55, priority: 4, seconds: .75, cooldownMs: 400),
  'coo_defeat': SoundSpec(
    volume: .85,
    priority: 4,
    seconds: 1.60,
    cooldownMs: 1000,
  ),
  // ---- Audio fix round ---------------------------------------------------
  // King Coo's arrival shout is cut to his beak's 0.8 s swell (the 1.6 s
  // coo_roar is his fury's); the Gargoyle gets his own fury and his own
  // shattering in the mids a phone plays; King Coo's chest inflates under the
  // hit-stop before the pop.
  'coo_shout': SoundSpec(
    volume: .95,
    priority: 4,
    seconds: .85,
    cooldownMs: 600,
  ),
  'gargoyle_fury': SoundSpec(
    volume: .45,
    priority: 4,
    seconds: 1.20,
    cooldownMs: 800,
  ),
  'gargoyle_shatter': SoundSpec(
    volume: .45,
    priority: 4,
    seconds: 1.20,
    cooldownMs: 1000,
  ),
  'coo_inflate': SoundSpec(
    volume: .45,
    priority: 3,
    seconds: .75,
    cooldownMs: 1000,
  ),
  // A steam burst that lands within 0.3 s of a pigeon's snatch or a rescued
  // star is played lower (the burst 5 dB, its clang 8 dB) so the 2.8 kHz
  // onset of the snatch is not hidden under its 5-6 kHz hiss; a snatch that
  // follows a burst is lifted 3 dB instead. Same WAVs, other levels.
  'steam_burst_duck': SoundSpec(
    volume: .29,
    priority: 3,
    seconds: .80,
    cooldownMs: 250,
    variants: 2,
    file: 'steam_burst',
  ),
  'pipe_clang_duck': SoundSpec(
    volume: .10,
    priority: 1,
    seconds: .45,
    cooldownMs: 250,
    variants: 2,
    file: 'pipe_clang',
  ),
  'pigeon_snatch_lift': SoundSpec(
    volume: .85,
    priority: 3,
    seconds: .42,
    cooldownMs: 120,
    file: 'pigeon_snatch',
  ),
  // ---- Campaign finish line ----------------------------------------------
  // The gate's "almost there" sting as its lights chase in (2.6 s before the
  // crossing), the tape snapping with the two confetti cannons, the birds'
  // cheer (the music ducks under it) and the swoop onto the result cloud.
  'finish_near': SoundSpec(
    volume: .30,
    priority: 3,
    seconds: 1.45,
    cooldownMs: 1000,
  ),
  'finish_snap': SoundSpec(
    volume: .45,
    priority: 4,
    seconds: .90,
    cooldownMs: 1000,
  ),
  'finish_cheer': SoundSpec(
    volume: .28,
    priority: 4,
    seconds: 2.30,
    cooldownMs: 1000,
    duck: .45,
  ),
  'finish_swoop': SoundSpec(
    volume: .45,
    priority: 3,
    seconds: .75,
    cooldownMs: 1000,
  ),
  // ---- Egypt (rules version 50) --------------------------------------------
  // Neferhoo, the Mummy Courier (design 01 section 6; tool/prepare_sound_effects.py
  // seeds 501-619). He roars HOO-POO-POO on arrival (and at the full fight's
  // stage-up) in place of boss_roar, with a sand devil under the arrival; the
  // mail call locks, a letter is flicked, a rock sends one back, it lands for
  // the payoff (the loudest hit), a rock only scuffs his wraps; the ankh
  // rises, whirs and is caught; fury has his own cry, the defeat's golden
  // mask pops, and the lost letter glows.
  // The design's .55 played about 4 dB under the other guardians' roars
  // (measured against the boss roar and reveal): .65.
  'hoopoe_roar': SoundSpec(
    volume: .65,
    priority: 4,
    seconds: 1.40,
    cooldownMs: 600,
  ),
  'sand_devil': SoundSpec(
    volume: .40,
    priority: 3,
    seconds: 1.60,
    cooldownMs: 1000,
  ),
  'mail_call': SoundSpec(
    volume: .40,
    priority: 3,
    seconds: 1.00,
    cooldownMs: 500,
  ),
  'letter_flick': SoundSpec(
    volume: .30,
    priority: 2,
    seconds: .25,
    cooldownMs: 120,
  ),
  'letter_return': SoundSpec(
    volume: .45,
    priority: 3,
    seconds: .40,
    cooldownMs: 100,
  ),
  'postage_due': SoundSpec(
    volume: .70,
    priority: 4,
    seconds: .70,
    cooldownMs: 150,
  ),
  'wrap_scuff': SoundSpec(
    volume: .22,
    priority: 1,
    seconds: .16,
    cooldownMs: 80,
  ),
  'ankh_raise': SoundSpec(
    volume: .40,
    priority: 3,
    seconds: 1.40,
    cooldownMs: 1000,
  ),
  // One whir covers fury's two ankhs: the second is thrown 0.5 s later.
  'ankh_whir': SoundSpec(
    volume: .35,
    priority: 2,
    seconds: 2.60,
    cooldownMs: 2000,
  ),
  'ankh_catch': SoundSpec(
    volume: .40,
    priority: 3,
    seconds: .35,
    cooldownMs: 300,
  ),
  'mummy_fury': SoundSpec(
    volume: .55,
    priority: 4,
    seconds: 1.30,
    cooldownMs: 1000,
  ),
  'mask_pop': SoundSpec(
    volume: .60,
    priority: 4,
    seconds: 1.30,
    cooldownMs: 1000,
  ),
  'lost_letter': SoundSpec(
    volume: .45,
    priority: 3,
    seconds: 1.40,
    cooldownMs: 1000,
  ),
  // A letter landing in the frame of Neferhoo's roar or fury cry is played
  // 8 dB lower, so the cry reads (the same WAV).
  'postage_due_duck': SoundSpec(
    volume: .28,
    priority: 4,
    seconds: .70,
    cooldownMs: 150,
    file: 'postage_due',
  ),
  // A scuff within 0.25 s of a returned letter landing is played 6 dB lower
  // under postage_due (the same WAV, as the steam burst ducks under a snatch).
  'wrap_scuff_duck': SoundSpec(
    volume: .11,
    priority: 1,
    seconds: .16,
    cooldownMs: 80,
    file: 'wrap_scuff',
  ),
};

String soundAsset(String name, int variant) =>
    'audio/${soundBank[name]?.file ?? name}'
    '${variant == 0 ? '' : '_${variant + 1}'}.wav';
