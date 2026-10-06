import 'dart:math' as math;

import '../domain/campaign.dart';
import '../domain/game_rules.dart';
import '../domain/sky_passport.dart';
import 'passport_progress.dart';
import 'progress_repository.dart';

/// The 42 Google Play Games achievements (docs/specification.md, "Google
/// Play Games"). Each is a pure function of the progress snapshot, which
/// carries the small feats set, so a cloud restore earns them again on a new
/// phone. The first 24 mirror the Sky Passport's medals one for one and read
/// it ([PassportProgress.passport]), so they follow its targets. Their Play
/// ids are in play_games_ids.dart. Append, never reorder: the sync reports
/// in this order, so a stamp's bronze comes before its silver and gold.
enum PlayAchievement {
  frequentFlyerBronze(SkyStamp.frequentFlyer, StampMedal.bronze),
  frequentFlyerSilver(SkyStamp.frequentFlyer, StampMedal.silver),
  frequentFlyerGold(SkyStamp.frequentFlyer, StampMedal.gold),
  onTheDotBronze(SkyStamp.onTheDot, StampMedal.bronze),
  onTheDotSilver(SkyStamp.onTheDot, StampMedal.silver),
  onTheDotGold(SkyStamp.onTheDot, StampMedal.gold),
  starChaserBronze(SkyStamp.starChaser, StampMedal.bronze),
  starChaserSilver(SkyStamp.starChaser, StampMedal.silver),
  starChaserGold(SkyStamp.starChaser, StampMedal.gold),
  constellationBronze(SkyStamp.constellation, StampMedal.bronze),
  constellationSilver(SkyStamp.constellation, StampMedal.silver),
  constellationGold(SkyStamp.constellation, StampMedal.gold),
  skyCaptainBronze(SkyStamp.skyCaptain, StampMedal.bronze),
  skyCaptainSilver(SkyStamp.skyCaptain, StampMedal.silver),
  skyCaptainGold(SkyStamp.skyCaptain, StampMedal.gold),
  trailblazerBronze(SkyStamp.trailblazer, StampMedal.bronze),
  trailblazerSilver(SkyStamp.trailblazer, StampMedal.silver),
  trailblazerGold(SkyStamp.trailblazer, StampMedal.gold),
  flockTogetherBronze(SkyStamp.flockTogether, StampMedal.bronze),
  flockTogetherSilver(SkyStamp.flockTogether, StampMedal.silver),
  flockTogetherGold(SkyStamp.flockTogether, StampMedal.gold),
  allRounderBronze(SkyStamp.allRounder, StampMedal.bronze),
  allRounderSilver(SkyStamp.allRounder, StampMedal.silver),
  allRounderGold(SkyStamp.allRounder, StampMedal.gold),

  /// Mail Through the Canopy: Baron Bat's lair (1-8).
  canopyBoss,

  /// Return to Sender: Neferhoo, Egypt's guardian (2-6).
  neferhoo,

  /// Mint Tea Again: the Spitter King's lair (2-9).
  roadBoss,

  /// Crumbs Cleared: King Coo (3-2).
  kingCoo,

  /// Out of the Spotlight: the Searchlight Gargoyle (3-4).
  gargoyle,

  /// Gold Canopy: three stars on every Canopy Route level.
  goldCanopy,

  /// Gold Road: three stars on every Ancient Road level.
  goldRoad,

  /// Bright Lights: three stars on every New York level.
  brightLights,

  /// Lamplighter: the Dusk Empress beaten.
  lamplighter,

  /// Harbour Bells: the Pirate Captain beaten.
  harbourBells,

  /// Edge of the Map: the Ember Dragon beaten.
  edgeOfTheMap,

  /// Two on One Phone: a roped Fly Together flight.
  twoOnOnePhone,

  /// Friendly Rivals: a 1 v 1 duel.
  friendlyRivals,

  /// Route Planner: a level built and flown to the finish.
  routePlanner,

  /// The Whole Kit: all 16 upgrade levels (incremental).
  wholeKit,

  /// Pen Pal: 10 daily postcards (incremental).
  penPal,

  /// Night Mail (hidden): a scored flight finished between midnight and
  /// 4 a.m.
  nightMail,

  /// Special Delivery (hidden): a star won back from an Alley Pigeon.
  specialDelivery;

  const PlayAchievement([this.stamp, this.medal]);

  /// The passport medal this achievement mirrors, if it is one.
  final SkyStamp? stamp;
  final StampMedal? medal;

  /// Play's step count for an incremental achievement, or null for a
  /// standard one. Play takes 2 to 10,000 steps, so a target of 1 is
  /// standard; streaks and best scores are standard too.
  int? get steps => switch (this) {
    wholeKit => PowerUp.values.length * PowerUp.maxLevel,
    penPal => 10,
    _ when stamp == null => null,
    _ when stamp == SkyStamp.constellation || stamp == SkyStamp.skyCaptain =>
      null,
    _ => stamp!.target(medal!) >= 2 ? stamp!.target(medal!) : null,
  };

  /// What completes it: [steps], or 1 for a standard achievement.
  int get goal => steps ?? 1;

  /// How far [p] has come, from 0 to [goal]. A medal is complete only once
  /// the passport holds it, so its tiers complete in order.
  int progress(ProgressSnapshot p) {
    final stamp = this.stamp;
    if (stamp != null) {
      final s = p.passport[stamp.index];
      final held = s.medal;
      if (held != null && held.index >= medal!.index) return goal;
      if (steps == null) return 0;
      return math.min(s.counts[medal!.index], goal - 1);
    }
    int done(bool earned) => earned ? 1 : 0;
    final campaign = p.campaign;
    bool cleared(bool Function(CampaignLevel) which) =>
        Campaign.levels.where(which).any(campaign.cleared);
    bool allGold(Iterable<CampaignLevel> levels) =>
        levels.every((level) => campaign.stars(level) == 3);
    return switch (this) {
      canopyBoss => done(campaign.cleared(Campaign.chapters[0].bossLevel)),
      neferhoo => done(cleared((l) => l.boss == BossKind.neferhoo)),
      roadBoss => done(campaign.cleared(Campaign.chapters[1].bossLevel)),
      kingCoo => done(cleared((l) => l.boss == BossKind.kingCoo)),
      gargoyle => done(cleared((l) => l.boss == BossKind.searchlightGargoyle)),
      goldCanopy => done(allGold(Campaign.chapters[0].levels)),
      goldRoad => done(allGold(Campaign.chapters[1].levels)),
      brightLights => done(
        allGold(Campaign.levels.where((l) => l.region == WorldRegion.newYork)),
      ),
      lamplighter => done(p.feats.contains('boss:${BossKind.duskMoth.name}')),
      harbourBells => done(p.feats.contains('boss:${BossKind.pirate.name}')),
      edgeOfTheMap => done(p.feats.contains('boss:${BossKind.dragon.name}')),
      twoOnOnePhone => done(p.coop.record(CoopMode.roped).flights > 0),
      friendlyRivals => done(p.coop.duels > 0),
      routePlanner => done(p.builtCleared),
      wholeKit => math.min(
        goal,
        PowerUp.values.fold(0, (n, power) => n + p.upgrades[power]),
      ),
      penPal => math.min(
        goal,
        p.feats.where((f) => f.startsWith('day:')).length,
      ),
      nightMail => done(p.feats.contains('night')),
      specialDelivery => done(p.feats.contains('pigeonFreed')),
      _ => 0,
    };
  }

  bool earned(ProgressSnapshot p) => progress(p) >= goal;
}

/// The step count each incremental achievement has on Play Console; one
/// missing here is standard. Play can't change an achievement's steps or type
/// once it is published, so a new [PlayAchievement.goal], such as a new
/// passport target, needs a new Play achievement
/// (test/play_games_fix_step_counts_test.dart holds the two together).
const publishedPlaySteps = <PlayAchievement, int>{
  PlayAchievement.frequentFlyerBronze: 10,
  PlayAchievement.frequentFlyerSilver: 100,
  PlayAchievement.frequentFlyerGold: 500,
  PlayAchievement.onTheDotBronze: 25,
  PlayAchievement.onTheDotSilver: 200,
  PlayAchievement.onTheDotGold: 1000,
  PlayAchievement.starChaserBronze: 50,
  PlayAchievement.starChaserSilver: 500,
  PlayAchievement.starChaserGold: 5000,
  PlayAchievement.trailblazerBronze: 5,
  PlayAchievement.trailblazerSilver: 50,
  PlayAchievement.trailblazerGold: 250,
  PlayAchievement.flockTogetherBronze: 2,
  PlayAchievement.flockTogetherSilver: 4,
  PlayAchievement.flockTogetherGold: 25,
  PlayAchievement.allRounderSilver: 3,
  PlayAchievement.allRounderGold: 10,
  PlayAchievement.wholeKit: 16,
  PlayAchievement.penPal: 10,
};
