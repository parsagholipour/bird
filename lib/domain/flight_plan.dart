import 'dart:math' as math;

import 'gale.dart';
import 'level_plan.dart';
import 'obstacle.dart';
import 'rush_path.dart';
import 'sky_boss.dart';
import 'sky_enemy.dart';
import 'world_region.dart';

/// The boss a flight meets next: its kind, its encounter number (which sets
/// its health) and whether it fights its gentler debut version.
typedef BossEncounter = ({BossKind kind, int number, bool debut});

/// A shuffle bag of obstacle families. The bag refills whenever [tier]
/// changes.
typedef FamilyBag = ({int tier, List<ObstacleKind> kinds});

/// What a flight lays and when: every schedule knob the rules used to
/// hard-code. The simulation asks its plan instead of checking what kind of
/// flight it is.
///
/// [FlightPlan.endless] is the endless flight exactly as every rules version
/// flew it before plans existed, so saved replays re-simulate unchanged. A
/// campaign level supplies a [LevelPlan], which also fixes the region, the
/// controls, the set pieces and the finish line.
///
/// Schedules run on [scheduleClock]; the pace and openings follow
/// [paceClock]. Both read the flight's elapsed time and its route clock, which
/// runs with the course: it equals elapsed time while cruising and runs ahead
/// while a sprint, ring sprint or gale speeds the course up.
abstract class FlightPlan {
  const FlightPlan();

  static const endless = EndlessPlan();

  /// The endless pace multiplier at a clock second. Time, not points, gently
  /// increases the pace; the asymptote keeps long flights physically
  /// playable.
  static double pace(double clock) => 1 + .65 * (1 - math.exp(-clock / 240));

  /// The campaign level this plan flies, or null for endless.
  String? get levelId;

  /// The lowest rules version that can fly this plan. Endless flies any; a
  /// level plan that uses rules 43's additions needs 43 (see
  /// [LevelPlan.minRulesVersion]).
  int get minRulesVersion => 0;

  /// The random an Alley Pigeon formation draws its prey from, for the
  /// [entry]th pigeon entry of a lineup. Endless has no pigeons; it would
  /// share the flight's random.
  math.Random flockRandom(int entry, math.Random flight) => flight;

  /// The one region the flight holds, or null to tour the world.
  WorldRegion? get region;

  /// Whether the Shoot and Sprint controls exist. The rules version and
  /// play mode still decide whether the flight supports them at all.
  bool get shoot;
  bool get sprint;

  /// The endless-clock second the pace and openings follow.
  double paceClock({required double elapsed, required double route});

  /// The clock the boss, rush path and gale timers run on.
  double scheduleClock({required double elapsed, required double route});

  /// The families the passage numbered [passage] (from 1) draws from, or
  /// null for a garden gate.
  FamilyBag? familyBag({
    required int passage,
    required double elapsed,
    required int rulesVersion,
  });

  /// Chance that an eligible wall carries a stone panel.
  double panelChance(int bossesDefeated);

  /// The lineup position of the enemy leading the passage numbered
  /// [passage] (from 1), or null for a passage without one.
  int? enemyIndex(int passage);

  /// The enemy appearance at a lineup position. Boss helpers draw from the
  /// same lineup.
  int enemyAppearance(int index, {required bool bossHelper});

  /// How many bosses' worth of health small enemies gain.
  int enemyToughness(int bossesDefeated);

  /// When the first boss arrives, and how long after a victory the next
  /// one follows, on the schedule clock.
  double get firstBossAt;
  double get bossInterval;
  BossEncounter bossEncounter(int bossesDefeated, int rulesVersion);

  /// Whether a heart pickup follows each boss victory.
  bool get heartPickups;

  /// When the first rush path runs and how long one waits after a boss or
  /// a gale, on the schedule clock.
  double get firstRushAt;
  double get rushAfterBoss;
  double get rushAfterGale;

  /// How long after beating [kind] a gale follows, or null for none.
  double? galeAfter(BossKind kind);

  /// Where ordinary passages resume after a boss or a gale.
  double resumeCenter(double birdY);

  /// The random the passages draw from. Endless flights use the random
  /// they are given, falling back to an unseeded one.
  math.Random courseRandom(math.Random? given);

  /// The random a set piece draws from: [piece] 0 is the boss, 1 and up the
  /// level's set pieces in order. Endless draws everything from the
  /// flight's own [flight] random.
  math.Random setPieceRandom(int piece, math.Random flight);

  /// A fixed route of passages, set pieces and a finish line, or null when
  /// passages follow the spawn timer. [baseSpeed] is the course speed before
  /// the pace multiplier and [interval] the cruising seconds between
  /// passages.
  LevelRoute? route({required double baseSpeed, required double interval});

  /// Level stars (0–3) for a flight that collected [stars]; 0 unless it
  /// [finished]. Endless flights earn none.
  int rate({required bool finished, required int stars});
}

/// The endless Star Trail and every older flight, as they flew before
/// plans existed.
class EndlessPlan extends FlightPlan {
  const EndlessPlan();

  /// A full normal-flight interval separates bosses.
  static const secondsBetweenBosses = 45.0;

  /// Baron Bat's smaller relatives lead the lineup. The natural cave bat
  /// stays a distinct fourth character in normal flight.
  static const enemyLineup = [3, 1, 2, 0];

  @override
  String? get levelId => null;
  @override
  WorldRegion? get region => null;
  @override
  bool get shoot => true;
  @override
  bool get sprint => true;

  @override
  double paceClock({required double elapsed, required double route}) => elapsed;
  @override
  double scheduleClock({required double elapsed, required double route}) =>
      elapsed;

  /// Families unlock with time: a tier every 18 seconds from version 13,
  /// after the opening three garden gates.
  @override
  FamilyBag? familyBag({
    required int passage,
    required double elapsed,
    required int rulesVersion,
  }) {
    if (rulesVersion < 12 || passage <= 3 || elapsed < 18) return null;
    final tier = rulesVersion >= 13
        ? (elapsed / 18).floor().clamp(1, ObstacleKind.values.length - 1)
        : elapsed < 36
        ? 1
        : elapsed < 54
        ? 2
        : 3;
    return (tier: tier, kinds: ObstacleKind.values.take(tier + 1).toList());
  }

  /// After boss 2, occasional ordinary walls have a shootable opening.
  @override
  double panelChance(int bossesDefeated) => bossesDefeated >= 2 ? .25 : 0;

  /// Alternate approaches leave room to learn the tighter gate rhythm.
  @override
  int? enemyIndex(int passage) => passage.isOdd ? passage ~/ 2 : null;

  @override
  int enemyAppearance(int index, {required bool bossHelper}) {
    final appearance =
        enemyLineup[index % (bossHelper ? 3 : enemyLineup.length)];
    assert(!EnemyKind.values[appearance].campaignOnly);
    return appearance;
  }

  /// Later encounters toughen the lineup without changing enemies in flight.
  @override
  int enemyToughness(int bossesDefeated) => bossesDefeated;

  @override
  double get firstBossAt => secondsBetweenBosses;
  @override
  double get bossInterval => secondsBetweenBosses;

  /// The cycle starts at the first kind, so a kind first appears once as
  /// many bosses have fallen as its position in the cycle.
  @override
  BossEncounter bossEncounter(int bossesDefeated, int rulesVersion) {
    // Campaign-only kinds (index >= BossKind.endlessCycle) never appear here:
    // the cycle is the first five, at every rules version.
    final kind = rulesVersion >= 38
        ? BossKind.values[bossesDefeated % BossKind.endlessCycle]
        : rulesVersion >= 34
        ? BossKind.values[bossesDefeated % 4]
        : rulesVersion >= 22
        ? BossKind.values[bossesDefeated % 3]
        : rulesVersion >= 21 && bossesDefeated.isOdd
        ? BossKind.spitterBeetle
        : BossKind.baronBat;
    assert(!kind.campaignOnly, 'a mini-boss entered the endless cycle');
    return (
      kind: kind,
      number: bossesDefeated + 1,
      debut: rulesVersion >= 37 && bossesDefeated == kind.index,
    );
  }

  @override
  bool get heartPickups => true;

  @override
  double get firstRushAt => Rush.firstAt;
  @override
  double get rushAfterBoss => Rush.afterBoss;
  @override
  double get rushAfterGale => Gale.rushAfter;

  /// A gale follows the Dusk Empress, and the rush path waits for it.
  @override
  double? galeAfter(BossKind kind) =>
      kind == BossKind.duskMoth ? Gale.afterBoss : null;

  @override
  double resumeCenter(double birdY) => birdY.clamp(.28, .72);

  @override
  math.Random courseRandom(math.Random? given) => given ?? math.Random();

  @override
  math.Random setPieceRandom(int piece, math.Random flight) => flight;

  @override
  LevelRoute? route({required double baseSpeed, required double interval}) =>
      null;

  @override
  int rate({required bool finished, required int stars}) => 0;
}
