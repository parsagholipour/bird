import '../domain/sky_boss.dart';

/// Neferhoo's edge-triggered cues (design `01-egypt-guardian.md` section 6:
/// 13 cues, seeds 501-619, made by `tool/prepare_sound_effects.py`), held by
/// `BossAudioCues` and advanced once per frame for a Neferhoo boss. Every
/// cue is one edge of what the rules latched, sounded exactly once; a seek,
/// a rewind and a new boss only follow the counters ([advance] with
/// `silent`), so scrubbing a replay is quiet.
///
/// What `BossAudioCues` itself rings for him, by the names below: the generic
/// `boss_warning` as he starts, `boss_reveal` at 1.65 s (the picture's
/// flash), [roarCue] at 2.65 s (the arrival's HOO-POO-POO, whose three
/// notes follow the picture's beak pulses) and again at the full fight's
/// stage-up, [furyCue] at fury, `boss_break` at the defeat, [burstCue] at
/// the burst (.85 s), `boss_victory` at 1.55 s; never the generic `boss_hit`
/// (a rock on his padded wraps is only [wrapScuff], deliberately small; a
/// letter home is [postageDue], the payoff).
/// This class adds the rest, in the order they sound in a frame:
///
///  * [devilCue] 0.1 s into the arrival (the sand devil swelling);
///  * [mailCall] when a mail call locks, [letterFlick] for each letter that
///    leaves his hand (the same instant the picture draws it), and
///    [letterReturn] when a rock sends one home;
///  * [postageDue] when a returned letter lands (the payoff; as
///    [postageDueDucked] in a frame that also rings his roar or fury's cry,
///    so the cry always reads over the jackpot), with
///    [wrapScuff] for a rock on his wraps (played as [wrapScuffDucked] when
///    it lands within [duckWindow] of a postage due, so the small thud never
///    hides the jackpot);
///  * [ankhRaise] when the ankh locks, [ankhWhir] for each throw (the sound
///    bank's 2 s cooldown makes fury's two ankhs, thrown 0.5 s apart, share
///    one whir) and [ankhCatch] for each ankh home;
///  * [lostLetter] [lostLetterAt] after the defeat, once the victory
///    stinger has rung out (the lost letter flares then).
///
/// Nothing here keys on "a hazard exists": the ankh's cue is its LOCK
/// (`NeferhooFight.ankhLockedAt`, latched only when a signature lock really
/// happens, never in the warm-up), the letters' and the throws' cues are the
/// letters and ankhs whose release time has come while he is attacking (so a
/// defeat that leaves a letter unreleased never plays it; the lists are never
/// pruned while he fights, as the contract says).
///
/// The open-sky gag (the wing buffing his pad) is art only and silent.
class NeferhooAudioCues {
  /// The arrival's roar (also the stage-up's), fury's cry and the defeat's
  /// burst: `BossAudioCues` rings them in place of `boss_roar`,
  /// `boss_enrage` and `boss_burst`.
  static const roarCue = 'hoopoe_roar';
  static const furyCue = 'mummy_fury';
  static const burstCue = 'mask_pop';

  static const devilCue = 'sand_devil';
  static const mailCall = 'mail_call';
  static const letterFlick = 'letter_flick';
  static const letterReturn = 'letter_return';
  static const postageDue = 'postage_due';
  static const postageDueDucked = 'postage_due_duck';
  static const wrapScuff = 'wrap_scuff';
  static const wrapScuffDucked = 'wrap_scuff_duck';
  static const ankhRaise = 'ankh_raise';
  static const ankhWhir = 'ankh_whir';
  static const ankhCatch = 'ankh_catch';
  static const lostLetter = 'lost_letter';

  /// Every cue he plays (the sound bank must hold each).
  static const all = [
    roarCue,
    furyCue,
    burstCue,
    devilCue,
    mailCall,
    letterFlick,
    letterReturn,
    postageDue,
    postageDueDucked,
    wrapScuff,
    wrapScuffDucked,
    ankhRaise,
    ankhWhir,
    ankhCatch,
    lostLetter,
  ];

  /// Boss age at which the sand devil's cue starts (design: 0.1 s), and how
  /// long after that a first sight of him may still ring it.
  static const devilAt = .1, devilWindow = .5;

  /// Seconds after the defeat at which the lost letter's cue rings: after
  /// `boss_victory` (1.55 s + its 1.65 s), not over it; the picture's lost
  /// letter flares then (`NeferhooEncounterArt.lostLetterFlare`).
  static const lostLetterAt = 3.2;

  /// A scuff this soon after (or in the same frame as) a postage due is
  /// ducked: the same file 6 dB lower.
  static const duckWindow = .25;

  double _age = -1, _death = -1;
  double _mailLockedAt = double.negativeInfinity;
  double _ankhLockedAt = double.negativeInfinity;
  int _released = 0, _thrown = 0;
  int _returned = 0, _landed = 0, _caught = 0, _scuffs = 0;
  double _landedAt = double.negativeInfinity;

  /// Forgets everything: the boss has gone.
  void reset() {
    _age = _death = -1;
    _mailLockedAt = _ankhLockedAt = double.negativeInfinity;
    _released = _thrown = 0;
    _returned = _landed = _caught = _scuffs = 0;
    _landedAt = double.negativeInfinity;
  }

  /// Adds his fight's cues for this frame to [cues] and follows his counters.
  /// [fresh] is a new boss (nothing sounds from its first frame but the
  /// sand devil, if that frame is still within [devilWindow] of its start);
  /// [silent] a seek or a rewind (follow, never sound).
  void advance(
    SkyBoss boss,
    List<String> cues, {
    required bool fresh,
    required bool silent,
  }) {
    final fight = boss.neferhoo;
    final attacking = boss.phase == BossPhase.attacking;
    final death = boss.defeatedAt == null ? -1.0 : boss.age - boss.defeatedAt!;
    // Letters and ankhs are listed from their lock, with the time they leave
    // his hand: count those whose time has come, but only while he fights.
    final released = attacking
        ? fight.letters.where((letter) => letter.dealtBy(boss.age)).length
        : _released;
    final thrown = attacking
        ? fight.ankhs.where((ankh) => boss.age >= ankh.thrownAt).length
        : _thrown;
    if (fresh || silent) _landedAt = double.negativeInfinity;
    if (!silent) {
      final before = fresh ? -1.0 : _age;
      if (before < devilAt &&
          boss.age >= devilAt &&
          boss.age < devilAt + devilWindow) {
        cues.add(devilCue);
      }
    }
    if (!fresh && !silent) {
      if (fight.mailLockedAt > _mailLockedAt) cues.add(mailCall);
      if (released > _released) cues.add(letterFlick);
      if (fight.lettersReturned > _returned) cues.add(letterReturn);
      final landed = fight.returnsLanded > _landed;
      if (landed) {
        // (the shared chain has already added this frame's roar or cry)
        final cry = cues.contains(furyCue) || cues.contains(roarCue);
        cues.add(cry ? postageDueDucked : postageDue);
        _landedAt = boss.age;
      }
      if (fight.wrapScuffs > _scuffs) {
        final near = boss.age - _landedAt;
        cues.add(near >= 0 && near <= duckWindow ? wrapScuffDucked : wrapScuff);
      }
      if (fight.ankhLockedAt > _ankhLockedAt) cues.add(ankhRaise);
      if (thrown > _thrown) cues.add(ankhWhir);
      if (fight.ankhCatches > _caught) cues.add(ankhCatch);
      if (_death < lostLetterAt && death >= lostLetterAt) cues.add(lostLetter);
    }
    _age = boss.age;
    _death = death;
    _mailLockedAt = fight.mailLockedAt;
    _ankhLockedAt = fight.ankhLockedAt;
    _released = released;
    _thrown = thrown;
    _returned = fight.lettersReturned;
    _landed = fight.returnsLanded;
    _caught = fight.ankhCatches;
    _scuffs = fight.wrapScuffs;
  }
}
