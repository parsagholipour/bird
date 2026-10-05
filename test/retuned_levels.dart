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
CampaignLevel asRecorded(CampaignLevel level) => switch (level.id) {
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
