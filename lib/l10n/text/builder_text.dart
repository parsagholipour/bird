import 'package:intl/intl.dart' show NumberFormat;

import '../../domain/built_plan.dart' show BuiltPace, BuiltPlan;
import '../../domain/built_reach.dart';
import '../../domain/obstacle.dart' show ObstacleKind;
import '../../domain/sky_boss.dart' show BossKind;
import '../../domain/sky_enemy.dart' show EnemyKind;
import '../../domain/tracking.dart' show PlayMode;
import '../generated/app_localizations.dart';
import 'shared_text.dart';

/// The Level Builder's words (MASTER-PLAN.md, slice S4): the domain keeps
/// its ids and English twins ([ObstacleKind.title], [BuiltIssue.message],
/// [BuiltCode.message]); the editor, its sheets and the built flight's
/// result word them here. test/l10n_builder_test.dart keeps the English ARB
/// equal to the twins.
///
/// A level's name is the player's own text: it is never translated, and in
/// a right-to-left language it is set apart from the sentence around it
/// ([playerText]) so its own letters keep their order.
extension BuilderText on AppLocalizations {
  /// A short name for [mode] on a chip: "Tap & Fly", "Push-ups".
  String builtModeShort(PlayMode mode) => switch (mode) {
    PlayMode.touch => playMode_touch,
    PlayMode.pushUp => builderMode_pushUp,
    PlayMode.squat => builderMode_squat,
    PlayMode.jump => builderMode_jump,
  };

  /// A gate family's name: "Garden gate", "Wind lift"… (slice S2's
  /// `obstacle_*_name` keys, the same as its `l.obstacleName`).
  String gateFamilyName(ObstacleKind kind) => switch (kind) {
    ObstacleKind.garden => obstacle_garden_name,
    ObstacleKind.windLift => obstacle_windLift_name,
    ObstacleKind.petalGate => obstacle_petalGate_name,
    ObstacleKind.switchback => obstacle_switchback_name,
    ObstacleKind.lanternDrift => obstacle_lanternDrift_name,
    ObstacleKind.sunWheels => obstacle_sunWheels_name,
    ObstacleKind.crystalSteps => obstacle_crystalSteps_name,
  };

  /// What a gate family does, for its card.
  String gateFamilyDetail(ObstacleKind kind) => switch (kind) {
    ObstacleKind.garden => builderFamily_garden_detail,
    ObstacleKind.windLift => builderFamily_windLift_detail,
    ObstacleKind.petalGate => builderFamily_petalGate_detail,
    ObstacleKind.switchback => builderFamily_switchback_detail,
    ObstacleKind.lanternDrift => builderFamily_lanternDrift_detail,
    ObstacleKind.sunWheels => builderFamily_sunWheels_detail,
    ObstacleKind.crystalSteps => builderFamily_crystalSteps_detail,
  };

  /// An enemy kind as the builder names it: "Purple bat".
  String builtEnemyName(EnemyKind kind) => switch (kind) {
    EnemyKind.simpleBat => builderEnemy_simpleBat,
    EnemyKind.caveBat => builderEnemy_caveBat,
    EnemyKind.spitterBeetle => builderEnemy_spitterBeetle,
    EnemyKind.duskMoth => builderEnemy_duskMoth,
    EnemyKind.alleyPigeon => builderEnemy_alleyPigeon,
    EnemyKind.mummyBat => builderEnemy_mummyBat,
  };

  String builtPaceName(BuiltPace pace) => switch (pace) {
    BuiltPace.relaxed => builderPace_relaxed,
    BuiltPace.steady => builderPace_steady,
    BuiltPace.brisk => builderPace_brisk,
  };

  /// A boss finale's name on a narrow key: "Baron", "Spitter"…
  String builtBossShort(BossKind kind) => switch (kind) {
    BossKind.baronBat => builderBossShort_baronBat,
    BossKind.spitterBeetle => builderBossShort_spitterBeetle,
    BossKind.duskMoth => builderBossShort_duskMoth,
    BossKind.pirate => builderBossShort_pirate,
    BossKind.dragon => builderBossShort_dragon,
    _ => bossName(kind),
  };

  /// What [issue] tells the level's maker.
  String builtIssueMessage(BuiltIssue issue) {
    final movement = _movement(issue.movement);
    return switch (issue.kind) {
      BuiltIssueKind.name => reach_name(issue.limit ?? BuiltPlan.maxName),
      BuiltIssueKind.tooShort => reach_tooShort,
      BuiltIssueKind.tooLong => reach_tooLong,
      BuiltIssueKind.tooMany => reach_tooMany(
        issue.limit ?? BuiltPlan.maxItems,
      ),
      BuiltIssueKind.bossNeedsTap => reach_bossNeedsTap,
      BuiltIssueKind.noGates => reach_noGates,
      BuiltIssueKind.startZone => reach_startZone,
      BuiltIssueKind.finishRoom => reach_finishRoom,
      BuiltIssueKind.overlap => reach_overlap,
      BuiltIssueKind.gateHeight => reach_gateHeight,
      BuiltIssueKind.gateMotion => reach_gateMotion,
      BuiltIssueKind.gateLook => reach_gateLook,
      BuiltIssueKind.gateNarrow => reach_gateNarrow,
      BuiltIssueKind.gateWide => reach_gateWide,
      BuiltIssueKind.doorNeedsShoot => reach_doorNeedsShoot,
      BuiltIssueKind.doorNeedsGarden => reach_doorNeedsGarden,
      BuiltIssueKind.tightSwitch => reach_tightSwitch(movement),
      BuiltIssueKind.steepClimb => reach_steepClimb,
      BuiltIssueKind.enemyNeedsTap => reach_enemyNeedsTap,
      BuiltIssueKind.outsideSky => reach_outsideSky,
      BuiltIssueKind.pastFinish => reach_pastFinish,
      BuiltIssueKind.outOfReach => reach_outOfReach(movement),
      BuiltIssueKind.inWall => reach_inWall,
      BuiltIssueKind.noStars => reach_noStars,
      BuiltIssueKind.marks => reach_marks,
      BuiltIssueKind.cannotFly => reach_cannotFly(issue.problem ?? ''),
    };
  }

  /// The `select` case for a push-up or squat level's movement.
  static String _movement(PlayMode? mode) =>
      mode == PlayMode.squat ? 'squat' : 'pushUp';

  /// [mode]'s movement as an ICU `select` case: `squat` or `pushUp`.
  String builtMovement(PlayMode mode) => _movement(mode);

  /// [value] with [digits] decimals and the language's decimal mark;
  /// digits stay Western in every language, as on the HUD.
  String builtDecimal(num value, {int digits = 0}) {
    final text = value.toStringAsFixed(digits);
    if (digits == 0) return text;
    final mark = NumberFormat.decimalPattern(localeName).symbols.DECIMAL_SEP;
    return mark == '.' ? text : text.replaceFirst('.', mark);
  }

  /// [seconds] as "12.4 s" (with [digits] decimals).
  String builtSeconds(num seconds, {int digits = 0}) =>
      builderSeconds(builtDecimal(seconds, digits: digits));

  /// "42 s" or "1 min 05 s": how long a level of [seconds] takes.
  String builtLength(int seconds) => seconds < 60
      ? builderSeconds('$seconds')
      : builderMinutesSeconds(
          seconds ~/ 60,
          (seconds % 60).toString().padLeft(2, '0'),
        );

  /// "12 push-ups", "1 squat": what a level of [mode] asks for.
  String builtReps(PlayMode mode, int reps) =>
      mode == PlayMode.squat ? builderRepsSquat(reps) : builderRepsPushUp(reps);

  /// The name a new level of [mode] starts with: "My tap level".
  String builtNewLevelName(PlayMode mode) => switch (mode) {
    PlayMode.touch => builderNewLevel_touch,
    PlayMode.pushUp => builderNewLevel_pushUp,
    PlayMode.squat => builderNewLevel_squat,
    PlayMode.jump => builderNewLevel_jump,
  };

  /// [text], typed by a player, ready to sit inside one of this language's
  /// sentences: in a right-to-left language it is isolated (FSI … PDI), so
  /// a name in Latin letters, digits or punctuation keeps its own order and
  /// does not carry the sentence's punctuation off with it. Left-to-right
  /// languages get it unchanged.
  String playerText(String text) =>
      _rtl.contains(localeName.split(RegExp('[_-]')).first)
      ? '\u2068$text\u2069'
      : text;

  static const _rtl = {'ar'};
}
