import '../../domain/campaign.dart';
import '../../domain/rush_path.dart' show RushPathKind;
import '../../domain/sky_boss.dart';
import '../generated/app_localizations.dart';
import 'campaign_text.dart';

/// The bosses' and the flight set-pieces' words (slice S3, MASTER-PLAN.md
/// "Slices"): the domain keeps ids and its English twins ([SkyBoss.title],
/// [BossHint.english], [BossVanguard.titleOf], ...), which tests, logs and
/// the rules read; screens and the canvas show these.
/// test/l10n_boss_text_test.dart keeps the English ARB equal to the twins.
extension BossText on AppLocalizations {
  /// The epithet under a boss's name on its card ("LORD OF THE STORM").
  String bossTitle(BossKind kind, {bool upgraded = false}) => switch (kind) {
    BossKind.baronBat =>
      upgraded ? boss_baronBat_returnTitle : boss_baronBat_title,
    BossKind.spitterBeetle => boss_spitterBeetle_title,
    BossKind.duskMoth => boss_duskMoth_title,
    BossKind.pirate => boss_pirate_title,
    BossKind.dragon => boss_dragon_title,
    BossKind.kingCoo => boss_kingCoo_title,
    BossKind.searchlightGargoyle => boss_searchlightGargoyle_title,
    BossKind.neferhoo => boss_neferhoo_title,
  };

  /// [boss]'s epithet as it is now (the returning Baron's own).
  String bossTitleOf(SkyBoss boss) =>
      bossTitle(boss.kind, upgraded: boss.upgraded);

  /// The name in the health bar's small name field, in capitals.
  String bossBarName(BossKind kind) => switch (kind) {
    BossKind.baronBat => boss_baronBat_barName,
    BossKind.spitterBeetle => boss_spitterBeetle_barName,
    BossKind.duskMoth => boss_duskMoth_barName,
    BossKind.pirate => boss_pirate_barName,
    BossKind.dragon => boss_dragon_barName,
    BossKind.kingCoo => boss_kingCoo_barName,
    BossKind.searchlightGargoyle => boss_searchlightGargoyle_barName,
    BossKind.neferhoo => boss_neferhoo_barName,
  };

  /// "BARON BAT DEFEATED", under a victory card's title.
  String bossDefeated(BossKind kind) => bossDefeatedBanner(kind.name);

  /// The small gold words over a boss's name on its card: GUARDIAN for a
  /// guardian, the numbered encounter for a chapter boss.
  String bossEyebrow(SkyBoss boss) => boss.isMiniBoss
      ? bossGuardianEyebrow
      : bossEncounterEyebrow(boss.number.toString().padLeft(2, '0'));

  /// The victory card's big title.
  String bossVictoryTitle(SkyBoss boss) =>
      boss.isMiniBoss ? bossGuardianDown : bossSkyReclaimed;

  /// A boss's story line for its name card, without quotation marks: the
  /// campaign's own (S1's [CampaignText.bossLine]) for [level], else the
  /// line of the chapter [kind] ends. Null when the campaign has none.
  String? bossLineFor(BossKind kind, {CampaignLevel? level}) {
    if (level != null && level.boss == kind) {
      final line = bossLine(level);
      if (line != null) return line;
    }
    for (final chapter in Campaign.chapters) {
      if (chapter.boss == kind) return bossLine(chapter.bossLevel);
    }
    return null;
  }

  /// A guardian's own line (its campaign level's), for its card when the
  /// flight brings none.
  String? guardianLine(BossKind kind) {
    for (final level in Campaign.levels) {
      if (level.boss == kind && level.bossLine != null) return bossLine(level);
    }
    return null;
  }

  /// What a fight's hint says, in the current language.
  String bossHint(BossHint hint) => switch (hint) {
    BossHint.strongerBaronBat => bossHint_strongerBaronBat,
    BossHint.strongerSpitterBeetle => bossHint_strongerSpitterBeetle,
    BossHint.strongerDuskMoth => bossHint_strongerDuskMoth,
    BossHint.strongerPirate => bossHint_strongerPirate,
    BossHint.strongerDragon => bossHint_strongerDragon,
    BossHint.strongerKingCoo => bossHint_strongerKingCoo,
    BossHint.strongerGargoyleFierce => bossHint_strongerGargoyleFierce,
    BossHint.strongerGargoyle => bossHint_strongerGargoyle,
    BossHint.strongerNeferhooTougher => bossHint_strongerNeferhooTougher,
    BossHint.strongerNeferhoo => bossHint_strongerNeferhoo,
    BossHint.tideRising => bossHint_tideRising,
    BossHint.highTide => bossHint_highTide,
    BossHint.tideFury => bossHint_tideFury,
    BossHint.tideCalm => bossHint_tideCalm,
    BossHint.breathWarningHigh => bossHint_breathWarning('high'),
    BossHint.breathWarningMiddle => bossHint_breathWarning('middle'),
    BossHint.breathWarningLow => bossHint_breathWarning('low'),
    BossHint.breathFireHigh => bossHint_breathFire('high'),
    BossHint.breathFireMiddle => bossHint_breathFire('middle'),
    BossHint.breathFireLow => bossHint_breathFire('low'),
    BossHint.dragonSwarm => bossHint_dragonSwarm,
    BossHint.dragonFuryDebut => bossHint_dragonFuryDebut,
    BossHint.dragonFury => bossHint_dragonFury,
    BossHint.dragonCalm => bossHint_dragonCalm,
    BossHint.screechWarningHigh => bossHint_screechWarning('high'),
    BossHint.screechWarningMiddle => bossHint_screechWarning('middle'),
    BossHint.screechWarningLow => bossHint_screechWarning('low'),
    BossHint.screechHoldHigh => bossHint_screechHold('high'),
    BossHint.screechHoldMiddle => bossHint_screechHold('middle'),
    BossHint.screechHoldLow => bossHint_screechHold('low'),
    BossHint.screechFury => bossHint_screechFury,
    BossHint.screechCalm => bossHint_screechCalm,
    BossHint.cooPopped => bossHint_cooPopped,
    BossHint.cooSquadron => bossHint_cooSquadron,
    BossHint.cooPuffed => bossHint_cooPuffed,
    BossHint.cooCrumbBomb => bossHint_cooCrumbBomb,
    BossHint.cooFury => bossHint_cooFury,
    BossHint.cooCalm => bossHint_cooCalm,
    BossHint.beamOn => bossHint_beamOn,
    BossHint.beamFury => bossHint_beamFury,
    BossHint.beamIncomingHigh => bossHint_beamIncomingHigh,
    BossHint.beamIncomingLow => bossHint_beamIncomingLow,
    BossHint.lampOpen => bossHint_lampOpen,
    BossHint.shuttersClosed => bossHint_shuttersClosed,
    BossHint.mothFuryNoVeil => bossHint_mothFuryNoVeil,
    BossHint.mothNoVeil => bossHint_mothNoVeil,
    BossHint.mothShielded => bossHint_mothShielded,
    BossHint.mothShieldForming => bossHint_mothShieldForming,
    BossHint.mothFury => bossHint_mothFury,
    BossHint.mothCalm => bossHint_mothCalm,
    BossHint.neferhooMailCall => bossHint_neferhooMailCall,
    BossHint.neferhooReturn => bossHint_neferhooReturn,
    BossHint.neferhooReturnFaster => bossHint_neferhooReturnFaster,
    BossHint.neferhooAnkh => bossHint_neferhooAnkh,
    BossHint.neferhooExpress => bossHint_neferhooExpress,
    BossHint.neferhooTwoAnkhs => bossHint_neferhooTwoAnkhs,
    BossHint.neferhooBats => bossHint_neferhooBats,
    BossHint.neferhooScuff => bossHint_neferhooScuff,
    BossHint.neferhooWarmUp => bossHint_neferhooWarmUp,
    BossHint.neferhooCalm => bossHint_neferhooCalm,
    BossHint.neferhooFury => bossHint_neferhooFury,
  };

  /// A hint getter's English ([SkyBoss.stageHint], [SkyBoss.tideHint],
  /// [NeferhooBoss.neferhooHint], ...) in the current language; words that
  /// are no hint come back as they are. For the play screen's flight label:
  /// `l.bossHintText(sim.boss!.tideHint)`.
  String bossHintText(String english) {
    final hint = BossHint.of(english);
    return hint == null ? english : bossHint(hint);
  }

  /// The title of the banner the vanguard of [kind] flies in under.
  String vanguardTitle(BossKind kind) => switch (kind) {
    BossKind.baronBat => vanguard_baronBat_title,
    BossKind.spitterBeetle => vanguard_spitterBeetle_title,
    BossKind.duskMoth => vanguard_duskMoth_title,
    BossKind.kingCoo => vanguard_kingCoo_title,
    BossKind.pirate ||
    BossKind.dragon ||
    BossKind.searchlightGargoyle ||
    BossKind.neferhoo => '',
  };

  /// The line under [vanguardTitle] (King Coo's when his squadron throws
  /// [crusts], and when the escapees [returns] in his fight).
  String vanguardCall(
    BossKind kind, {
    bool crusts = false,
    bool returns = false,
  }) => switch (kind) {
    BossKind.baronBat => vanguard_baronBat_call,
    BossKind.spitterBeetle => vanguard_spitterBeetle_call,
    BossKind.duskMoth => vanguard_duskMoth_call,
    BossKind.kingCoo =>
      returns
          ? vanguard_kingCoo_callReturns
          : crusts
          ? vanguard_kingCoo_callCrusts
          : vanguard_kingCoo_call,
    BossKind.pirate ||
    BossKind.dragon ||
    BossKind.searchlightGargoyle ||
    BossKind.neferhoo => '',
  };

  /// "WILDFIRE!": a rush begins.
  String rushWarningTitle(RushPathKind kind) => encounterRushWarning(kind.name);

  /// How to survive the rush of [kind].
  String rushWarningDetail(RushPathKind kind) => encounterRushDetail(kind.name);

  /// "You outran the wildfire".
  String rushEscapedDetail(RushPathKind kind) =>
      encounterRushEscapedDetail(kind.name);
}
