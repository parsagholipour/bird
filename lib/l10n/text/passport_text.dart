import '../../domain/sky_passport.dart';
import '../generated/app_localizations.dart';
import 'shared_text.dart';

/// The Sky Passport's words (slice S6): stamp names, medals and goals. The
/// domain keeps its English twins ([SkyStamp.title], [StampMedal.label],
/// [SkyStamp.goal], [StampProgress.medalTitle]); every screen shows these.
/// test/l10n_menus_test.dart keeps the English ARB equal to the twins
/// and the stamp and medal names equal to the Play achievement names in
/// l10n/store/en.json ("Frequent Flyer · Bronze").
extension PassportText on AppLocalizations {
  /// "Frequent flyer".
  String stampName(SkyStamp stamp) => switch (stamp) {
    SkyStamp.frequentFlyer => stamp_frequentFlyer_name,
    SkyStamp.onTheDot => stamp_onTheDot_name,
    SkyStamp.starChaser => stamp_starChaser_name,
    SkyStamp.constellation => stamp_constellation_name,
    SkyStamp.skyCaptain => stamp_skyCaptain_name,
    SkyStamp.trailblazer => stamp_trailblazer_name,
    SkyStamp.flockTogether => stamp_flockTogether_name,
    SkyStamp.allRounder => stamp_allRounder_name,
  };

  /// "Bronze".
  String medalName(StampMedal medal) => switch (medal) {
    StampMedal.bronze => passportMedal_bronze,
    StampMedal.silver => passportMedal_silver,
    StampMedal.gold => passportMedal_gold,
  };

  /// What [medal] of [stamp] asks for: "Collect 5,000 stars."
  String stampGoal(SkyStamp stamp, StampMedal medal) {
    final count = stamp.target(medal);
    final n = formatCount(count);
    return switch (stamp) {
      SkyStamp.frequentFlyer => stamp_frequentFlyer_goal(count, n),
      SkyStamp.onTheDot => stamp_onTheDot_goal(count, n),
      SkyStamp.starChaser => stamp_starChaser_goal(count, n),
      SkyStamp.constellation => stamp_constellation_goal(count, n),
      SkyStamp.skyCaptain => stamp_skyCaptain_goal(count, n),
      SkyStamp.trailblazer => stamp_trailblazer_goal(count, n),
      SkyStamp.flockTogether => switch (medal) {
        StampMedal.bronze => stamp_flockTogether_goalBronze,
        StampMedal.silver => stamp_flockTogether_goalSilver,
        StampMedal.gold => stamp_flockTogether_goalGold(count, n),
      },
      SkyStamp.allRounder => switch (medal) {
        StampMedal.bronze => stamp_allRounder_goalBronze,
        StampMedal.silver => stamp_allRounder_goalSilver,
        StampMedal.gold => stamp_allRounder_goalGold(count, n),
      },
    };
  }

  /// The goal [progress] measures now (its next medal, or gold).
  String stampProgressGoal(StampProgress progress) =>
      stampGoal(progress.stamp, progress.aim);

  /// "Star chaser: Silver" for the medal held (results after a flight).
  String stampMedalTitle(StampProgress progress) {
    final medal = progress.medal;
    final stamp = stampName(progress.stamp);
    return medal == null
        ? passportMedalTitleNone(stamp)
        : passportMedalTitle(stamp, medalName(medal));
  }

  /// "Star chaser · Silver" for the medal still to earn: the pattern of
  /// the stamp's Play achievement names.
  String stampNextTitle(StampProgress progress) =>
      passportNextTitle(stampName(progress.stamp), medalName(progress.aim));

  /// "1,200/5,000", toward the next medal.
  String stampTally(StampProgress progress) =>
      '${formatCount(progress.current)}/${formatCount(progress.target)}';
}
