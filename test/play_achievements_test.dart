import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/passport_progress.dart';
import 'package:push_up_bird/data/play_achievements.dart';
import 'package:push_up_bird/data/play_games_ids.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/sky_passport.dart';

typedef A = PlayAchievement;

ProgressSnapshot cleared(Iterable<CampaignLevel> levels, {int stars = 1}) =>
    ProgressSnapshot(
      campaign: CampaignProgress([
        for (final level in levels)
          LevelRecord(levelId: level.id, bestStars: stars),
      ]),
    );

void main() {
  test('42 achievements: the 24 passport medals, then 18 more', () {
    expect(A.values, hasLength(42));
    final medals = A.values.where((a) => a.stamp != null).toList();
    expect(medals, hasLength(24));
    expect(A.values.take(24), medals);
    var i = 0;
    for (final stamp in SkyStamp.values) {
      for (final medal in StampMedal.values) {
        expect((medals[i].stamp, medals[i].medal), (stamp, medal));
        i++;
      }
    }
    // Every one has its line in the one file of Play ids.
    expect(playAchievementIds.keys.toSet(), A.values.toSet());
  });

  test('incremental where it counts, standard for streaks, bests and 1s', () {
    expect(A.frequentFlyerGold.steps, 500);
    expect(A.starChaserGold.steps, 5000);
    expect(A.onTheDotSilver.steps, 200);
    expect(A.trailblazerBronze.steps, 5);
    expect(A.flockTogetherBronze.steps, 2);
    expect(A.flockTogetherGold.steps, 25);
    expect(A.constellationGold.steps, isNull);
    expect(A.skyCaptainBronze.steps, isNull);
    expect(A.allRounderBronze.steps, isNull);
    expect(A.allRounderSilver.steps, 3);
    expect(A.allRounderGold.steps, 10);
    expect(A.wholeKit.steps, 16);
    expect(A.penPal.steps, 10);
    for (final a in A.values) {
      if (a.steps case final steps?) {
        expect(steps, inInclusiveRange(2, 10000), reason: a.name);
      }
    }
  });

  test('a new player has earned nothing', () {
    const p = ProgressSnapshot();
    for (final a in A.values) {
      expect(a.progress(p), 0, reason: a.name);
    }
  });

  test('a medal ladder fills bronze, then silver, then gold', () {
    ProgressSnapshot stars(int n) =>
        ProgressSnapshot(campaignFlights: ModeRecord(stars: n));
    expect(A.starChaserBronze.progress(stars(30)), 30);
    expect(A.starChaserSilver.progress(stars(30)), 30);
    expect(A.starChaserBronze.progress(stars(50)), 50);
    expect(A.starChaserBronze.earned(stars(50)), isTrue);
    expect(A.starChaserSilver.progress(stars(120)), 120);
    expect(A.starChaserSilver.earned(stars(120)), isFalse);
    expect(A.starChaserGold.progress(stars(120)), 120);
    expect(A.starChaserSilver.earned(stars(500)), isTrue);
    expect(A.starChaserGold.progress(stars(9000)), 5000);
  });

  test('the medals always agree with the passport', () {
    final samples = [
      const ProgressSnapshot(),
      const ProgressSnapshot(
        touch: ModeRecord(runs: 70, stars: 3400, perfectPasses: 20),
        trailTouch: ModeRecord(runs: 50, best: 640, completions: 60),
        campaignFlights: ModeRecord(bestCombo: 45, perfectPasses: 190),
        birdsFlown: {0, 1, 2, 3},
        birdFlights: {0: 30, 1: 25, 2: 80, 3: 24},
      ),
      const ProgressSnapshot(
        pushUp: ModeRecord(runs: 4),
        trailSquat: ModeRecord(runs: 12, best: 2100),
        jump: ModeRecord(runs: 10),
        squat: ModeRecord(runs: 1),
        birdsFlown: {2, 1},
        birdFlights: {1: 30, 2: 30},
      ),
    ];
    for (final p in samples) {
      for (final a in A.values.where((a) => a.stamp != null)) {
        final held = p.passport[a.stamp!.index].medal;
        expect(
          a.earned(p),
          held != null && held.index >= a.medal!.index,
          reason: '${a.name} in $samples',
        );
      }
    }
  });

  test('flock gold waits for the least flown bird; all-rounder for tries', () {
    const p = ProgressSnapshot(
      birdsFlown: {0, 1, 2, 3},
      birdFlights: {0: 30, 1: 25, 2: 80, 3: 24},
      pushUp: ModeRecord(runs: 3),
      squat: ModeRecord(runs: 9),
    );
    expect(A.flockTogetherBronze.earned(p), isTrue);
    expect(A.flockTogetherSilver.earned(p), isTrue);
    expect(A.flockTogetherGold.progress(p), 24);
    expect(A.allRounderBronze.progress(p), 1);
    expect(A.allRounderSilver.progress(p), 2);
    // Gold counts the least flown mini game: jump, never tried.
    expect(A.allRounderGold.progress(p), 0);
  });

  test('bosses and gold sets read the campaign', () {
    final canopy = Campaign.chapters[0], road = Campaign.chapters[1];
    expect(canopy.bossLevel.id, '1-8');
    expect(road.bossLevel.id, '2-9');
    final p = cleared([canopy.bossLevel, road.bossLevel]);
    expect(A.canopyBoss.earned(p), isTrue);
    expect(A.roadBoss.earned(p), isTrue);
    expect(A.neferhoo.earned(p), isFalse);
    expect(A.kingCoo.earned(cleared([Campaign.level('3-2')!])), isTrue);
    expect(A.gargoyle.earned(cleared([Campaign.level('3-4')!])), isTrue);
    expect(A.neferhoo.earned(cleared([Campaign.level('2-6')!])), isTrue);

    expect(A.goldCanopy.earned(cleared(canopy.levels, stars: 2)), isFalse);
    expect(A.goldCanopy.earned(cleared(canopy.levels, stars: 3)), isTrue);
    expect(A.goldRoad.earned(cleared(road.levels, stars: 3)), isTrue);
    final newYork = Campaign.levels.where(
      (l) => l.region == WorldRegion.newYork,
    );
    expect(newYork, hasLength(4));
    expect(A.brightLights.earned(cleared(newYork, stars: 3)), isTrue);
    expect(A.brightLights.earned(cleared(newYork.skip(1), stars: 3)), isFalse);
  });

  test('feats, co-op, the builder and the shop', () {
    const p = ProgressSnapshot(
      feats: {
        'boss:duskMoth',
        'boss:dragon',
        'night',
        'pigeonFreed',
        'day:2026-10-01',
        'day:2026-10-02',
        'day:2026-10-03',
      },
      coop: CoopProgress(records: {CoopMode.duel: CoopRecord(flights: 2)}),
      builtCleared: true,
      upgrades: PowerUps(shot: 4, sprint: 2, magnet: 1),
    );
    expect(A.lamplighter.earned(p), isTrue);
    expect(A.harbourBells.earned(p), isFalse);
    expect(A.edgeOfTheMap.earned(p), isTrue);
    expect(A.nightMail.earned(p), isTrue);
    expect(A.specialDelivery.earned(p), isTrue);
    expect(A.friendlyRivals.earned(p), isTrue);
    expect(A.twoOnOnePhone.earned(p), isFalse);
    expect(A.routePlanner.earned(p), isTrue);
    expect(A.wholeKit.progress(p), 7);
    expect(
      A.wholeKit.earned(const ProgressSnapshot(upgrades: PowerUps.max)),
      isTrue,
    );
    expect(A.penPal.progress(p), 3);
  });
}
