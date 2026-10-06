import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

/// Levels whose data changed after the frozen fixtures were recorded, as the
/// fixtures recorded them. The frozen suites (rules 41, 45 and 49) fly these
/// instead of the catalog's, so they go on proving that the rules fly every
/// recorded plan the same and their fixtures stay untouched; a saved tape
/// carries its own plan, so a retuned level still replays the way it was
/// flown. The catalog's new data is pinned by `campaign_catalog_test.dart`.
///
/// - 1-4 Carnival Skies gained Brazil's gale (2026-10-06): 80 s, a gale at
///   30 s, the gale's NEW hint and marks 30 / 50. It was 70 s with no set
///   piece, no hint and marks 45 / 70.
/// - 1-1 First Delivery (2026-10-06): 30 s with Shoot, marks 15 / 25. It was
///   60 s without Shoot, marks 35 / 60.
/// - 1-2 Star Streak (2026-10-06): 45 s with a small bat on every fourth
///   passage and Shoot, marks 25 / 45. It was 60 s with no enemies and no
///   Shoot, marks 35 / 60.
CampaignLevel asRecorded(CampaignLevel level) => switch (level.id) {
  '1-1' => CampaignLevel(
    name: level.name,
    delivery: level.delivery,
    hint: level.hint,
    plan: const LevelPlan(
      id: '1-1',
      region: WorldRegion.jungle,
      length: 60,
      start: 0,
      seed: 1101,
      families: [ObstacleKind.garden],
      shoot: false,
      sprint: false,
      marks: StarMarks(35, 60),
    ),
  ),
  '1-2' => CampaignLevel(
    name: level.name,
    delivery: level.delivery,
    hint: level.hint,
    plan: const LevelPlan(
      id: '1-2',
      region: WorldRegion.jungle,
      length: 60,
      start: 0,
      seed: 1102,
      families: [ObstacleKind.garden, ObstacleKind.windLift],
      shoot: false,
      sprint: false,
      marks: StarMarks(35, 60),
    ),
  ),
  '1-4' => CampaignLevel(
    name: level.name,
    delivery: level.delivery,
    plan: const LevelPlan(
      id: '1-4',
      region: WorldRegion.brazil,
      length: 70,
      start: 20,
      seed: 1104,
      families: [
        ObstacleKind.garden,
        ObstacleKind.windLift,
        ObstacleKind.petalGate,
      ],
      lineup: [EnemyKind.simpleBat, EnemyKind.caveBat],
      sprint: false,
      marks: StarMarks(45, 70),
    ),
  ),
  _ => level,
};
