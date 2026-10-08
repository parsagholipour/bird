import '../../domain/game_rules.dart'
    show CoopMode, EndReason, FlightCourse, RushPathKind;
import '../../domain/replay_highlights.dart';
import '../generated/app_localizations.dart';
import 'coop_text.dart';
import 'flight_text.dart';

/// The flight highlights' words (slice S6). [ReplayHighlight.title] and
/// [ReplayHighlight.detail] stay the English twins; the highlights sheet
/// shows these. test/l10n_menus_test.dart keeps them equal.
extension ReplayText on AppLocalizations {
  /// "Takeoff", "3× star power", "Outran the wildfire"…
  String momentTitle(ReplayHighlight moment) => switch (moment.kind) {
    ReplayMomentKind.start => replayMomentTakeoff,
    ReplayMomentKind.magnet => replayMomentMagnet,
    ReplayMomentKind.starTrio => replayMomentStarTrio,
    ReplayMomentKind.streak => replayMomentStreak(moment.value),
    ReplayMomentKind.shield => replayMomentShield,
    ReplayMomentKind.perfect => replayMomentPerfect,
    ReplayMomentKind.milestone => replayMomentGates(moment.value),
    ReplayMomentKind.rush => rushEscape(moment.rush ?? RushPathKind.wildfire),
    ReplayMomentKind.gale => replayMomentGale,
    ReplayMomentKind.finish =>
      moment.endReason == EndReason.completed
          ? replayMomentRouteComplete
          : replayMomentFinal,
  };

  /// The line under [momentTitle].
  String momentDetail(ReplayHighlight moment) => switch (moment.kind) {
    ReplayMomentKind.start => replayMomentTakeoffDetail,
    ReplayMomentKind.magnet => replayMomentMagnetDetail,
    ReplayMomentKind.starTrio =>
      moment.subtleStars
          ? replayMomentStarTrioSubtleDetail
          : replayMomentStarTrioDetail,
    ReplayMomentKind.streak => replayMomentStreakDetail,
    ReplayMomentKind.shield => replayMomentShieldDetail,
    ReplayMomentKind.perfect => replayMomentPerfectDetail,
    ReplayMomentKind.milestone => replayMomentGatesDetail,
    ReplayMomentKind.rush =>
      moment.flawless
          ? replayMomentFlawlessDetail(moment.value)
          : replayMomentRushDetail(moment.value),
    ReplayMomentKind.gale =>
      moment.flawless
          ? replayMomentFlawlessDetail(moment.value)
          : replayMomentGaleDetail(moment.value),
    ReplayMomentKind.finish => switch (moment.endReason) {
      EndReason.completed => replayMomentCompleteDetail,
      EndReason.collision => replayMomentCollisionDetail,
      _ => replayMomentEndDetail,
    },
  };

  /// A two-player mode in records and saved sessions: "Fly Together ·
  /// Roped" (the mode name is [CoopText.coopModeName]).
  String flyTogetherName(CoopMode mode) => recordsCoopName(coopModeName(mode));

  /// The small capital label over a replay's score: "STAR POINTS"
  /// ([FlightText.courseScoreLabel]).
  String replayScoreLabel(FlightCourse course) => courseScoreLabel(course);
}
