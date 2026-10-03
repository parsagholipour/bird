import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/ui/campaign_screen.dart'
    show campaignStarsInBuild, campaignStops;
import 'package:push_up_bird/ui/level_intro.dart' show lockedNudge;

import 'ny_plans.dart';

/// Partial chapter opening: New York (3-1 to 3-4) is opened ahead of Paris
/// and the Dusk Empress through `Campaign.playable(level)` and
/// `CampaignChapter.opened`. The build ships OPEN (`NEW_YORK_OPEN` defaults to
/// true; `NEW_YORK_OPEN=false` is the rollback); these tests force a state
/// with `Campaign.openedForTest` / `Campaign.closedForTest`, so they pass
/// under either define, and one test pins the build's own default. Also the
/// guardian rules: a mini-boss level ends no chapter, earns no seal and
/// brings no postcard.

CampaignLevel level(String id) => Campaign.level(id)!;

LevelRecord cleared(String id, {int stars = 1}) => LevelRecord(
  levelId: id,
  bestStars: stars,
  plays: 1,
  firstClearedAt: DateTime(2026, 9, 20),
  // Played in level order through the day.
  lastPlayedAt: DateTime(
    2026,
    9,
    20,
    int.parse(id.split('-').first),
    int.parse(id.split('-').last),
  ),
);

/// Records for every level of chapters 1 and 2.
List<LevelRecord> twoChapters() => [
  for (final chapter in Campaign.chapters.take(2))
    for (final level in chapter.levels) cleared(level.id),
];

void main() {
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  group('the build default', () {
    test('New York is open unless NEW_YORK_OPEN says false', () {
      const defined = bool.hasEnvironment('NEW_YORK_OPEN');
      const value = bool.fromEnvironment('NEW_YORK_OPEN');
      // No define (`make build`, `make install`, `flutter run`): open.
      expect(Campaign.openingEnabled, defined ? value : isTrue);
      expect(Campaign.stopsOpen, Campaign.openingEnabled);
      expect(campaignStarsInBuild, Campaign.openingEnabled ? 63 : 51);
    });

    test('the test hooks override the build, and false hands it back', () {
      final build = Campaign.openingEnabled;
      Campaign.closedForTest = true;
      expect(Campaign.stopsOpen, isFalse);
      Campaign.openedForTest = true;
      expect(Campaign.stopsOpen, isFalse, reason: 'closed wins');
      Campaign.closedForTest = false;
      expect(Campaign.stopsOpen, isTrue);
      Campaign.openedForTest = false;
      expect(Campaign.stopsOpen, build);
    });
  });

  group('closed, as a build made with NEW_YORK_OPEN=false', () {
    setUp(() => Campaign.closedForTest = true);

    test('chapters 1 and 2 are playable and nothing else is', () {
      expect(Campaign.stopsOpen, isFalse);
      for (final level in Campaign.levels) {
        expect(Campaign.playable(level), level.chapter <= 2, reason: level.id);
      }
      // Chapter 2 has nine levels since Egypt's guardian (2-6, rules 50).
      expect(Campaign.playableLevels, hasLength(17));
      expect(campaignStarsInBuild, 51);
      // Every region of chapters 3 to 5 says Coming soon.
      for (final region in Campaign.journey) {
        final soon = Campaign.comingSoon(region);
        final playable = Campaign.levels.any(
          (l) => l.region == region && l.chapter <= 2,
        );
        expect(soon, !playable, reason: region.name);
      }
    });

    test('2-9 does not open 3-1', () {
      final progress = CampaignProgress(twoChapters());
      expect(progress.unlocked(level('2-9')), isTrue);
      expect(progress.unlocked(level('3-1')), isFalse);
      expect(progress.chapterUnlocked(Campaign.chapters[2]), isFalse);
      expect(lockedNudge(level('3-1')), 'Coming soon');
    });

    test('chapter 3 lists New York as its opened stop, and only that', () {
      expect(Campaign.chapters[2].opened, {WorldRegion.newYork});
      expect(Campaign.chapters[2].playable, isFalse);
      for (final chapter in Campaign.chapters) {
        if (chapter.number != 3) expect(chapter.opened, isEmpty);
      }
      expect(Campaign.chapters[0].playable, isTrue);
      expect(Campaign.chapters[1].playable, isTrue);
    });
  });

  group('open, as the build ships', () {
    setUp(() => Campaign.openedForTest = true);

    test('3-1 to 3-4 are playable; Paris and later chapters are not', () {
      for (final level in Campaign.levels) {
        final expected =
            level.chapter <= 2 ||
            (level.chapter == 3 && level.region == WorldRegion.newYork);
        expect(Campaign.playable(level), expected, reason: level.id);
      }
      expect([for (final l in Campaign.playableLevels) l.id].skip(17), [
        '3-1',
        '3-2',
        '3-3',
        '3-4',
      ]);
      expect(campaignStarsInBuild, 63);
    });

    test('the map keeps Coming soon on Paris, not on New York', () {
      expect(Campaign.comingSoon(WorldRegion.newYork), isFalse);
      expect(Campaign.comingSoon(WorldRegion.paris), isTrue);
      expect(Campaign.comingSoon(WorldRegion.mexico), isTrue);
      expect(Campaign.comingSoon(WorldRegion.jungle), isFalse);
      final stops = campaignStops(CampaignProgress(twoChapters()));
      final soon = {for (final s in stops) s.region: s.comingSoon};
      expect(soon[WorldRegion.newYork], isFalse);
      expect(soon[WorldRegion.paris], isTrue);
      expect(soon.values.where((s) => s), hasLength(6));
      // New York is open (not dimmed) once chapter 2 is done.
      final ny = stops.firstWhere((s) => s.region == WorldRegion.newYork);
      expect(ny.locked, isFalse);
      expect(ny.nodes.first.id, '3-1');
      expect(
        stops.firstWhere((s) => s.region == WorldRegion.paris).locked,
        isTrue,
      );
    });

    test('2-8 opens 3-1; each level opens the next; 3-4 opens nothing', () {
      var progress = CampaignProgress(twoChapters());
      expect(progress.unlocked(level('3-1')), isTrue);
      expect(progress.unlocked(level('3-2')), isFalse);
      expect(progress.chapterUnlocked(Campaign.chapters[2]), isTrue);
      expect(progress.current.id, '3-1');
      for (final id in ['3-1', '3-2', '3-3']) {
        progress = CampaignProgress([...twoChapters(), cleared(id)]);
        expect(
          progress.unlocked(Campaign.after(level(id))!),
          isTrue,
          reason: id,
        );
      }
      progress = CampaignProgress([
        ...twoChapters(),
        for (final id in ['3-1', '3-2', '3-3', '3-4']) cleared(id),
      ]);
      expect(progress.unlocked(level('3-4')), isTrue);
      expect(progress.unlocked(level('3-5')), isFalse, reason: 'Paris waits');
      // The courier stays on the last New York level.
      expect(progress.current.id, '3-4');
      expect(Campaign.playable(Campaign.after(level('3-4'))!), isFalse);
      expect(lockedNudge(level('3-5')), 'Coming soon');
    });

    test('New York counts its stars, and no chapter is finished', () {
      final progress = CampaignProgress([
        ...twoChapters(),
        cleared('3-1', stars: 3),
        cleared('3-2', stars: 2),
      ]);
      expect(progress.starsInChapter(Campaign.chapters[2]), 5);
      expect(progress.starsInRegion(WorldRegion.newYork), 5);
      expect(progress.starsInRegion(WorldRegion.paris), 0);
      expect(progress.chapterComplete(Campaign.chapters[2]), isFalse);
      expect(progress.postcardDue(Campaign.chapters[2]), isFalse);
    });

    test('a locked New York node says what unlocks it', () {
      expect(lockedNudge(level('3-2')), 'Finish 3-1 to unlock');
      // 3-2 is King Coo's lair, so the note on 3-3 names him.
      expect(lockedNudge(level('3-3')), 'Beat King Coo to unlock');
      expect(lockedNudge(level('3-4')), 'Finish 3-3 to unlock');
      // Paris is not in the build: 3-5 says so, not "Beat the Searchlight
      // Gargoyle to unlock".
      expect(lockedNudge(level('3-5')), 'Coming soon');
    });
  });

  group('chapter bosses and guardians', () {
    test('only the last level of a chapter is its chapter boss', () {
      for (final chapter in Campaign.chapters) {
        for (final level in chapter.levels) {
          expect(
            level.isChapterBoss,
            level.id == chapter.bossLevel.id,
            reason: level.id,
          );
          // `isBoss` is any boss: a chapter's, or a guardian (Egypt's
          // Neferhoo, New York's two).
          final guardian = const {'2-6', '3-2', '3-4'}.contains(level.id);
          expect(
            level.isBoss,
            level.id == chapter.bossLevel.id || guardian,
            reason: level.id,
          );
          expect(level.isGuardian, guardian, reason: level.id);
          expect(level.isMiniBoss, guardian, reason: level.id);
        }
        expect(chapter.bossLevel.boss, chapter.boss);
      }
    });

    test(
      'a level with a mini-boss before its chapter\'s end is a guardian',
      () {
        const delivery = Delivery(
          'A parcel',
          from: 'Someone',
          thanks: 'Thanks',
        );
        final coo = CampaignLevel(
          name: 'Wheels in the Rain',
          delivery: delivery,
          bossLine: 'Nobody flies till the bread cart is found!',
          plan: nyPlan(
            lineup: const [EnemyKind.simpleBat],
            boss: BossKind.kingCoo,
          ),
        );
        expect(coo.id, '3-2');
        expect(coo.isBoss, isTrue);
        expect(coo.isChapterBoss, isFalse);
        expect(coo.isGuardian, isTrue);
        expect(coo.isMiniBoss, isTrue);
        expect(coo.boss, BossKind.kingCoo);
        expect(
          Campaign.bossLine(coo),
          'Nobody flies till the bread cart is found!',
        );
        // The chapter's own boss is untouched by the guardian.
        expect(Campaign.chapterOf(coo).bossLevel.id, '3-8');
        expect(Campaign.chapterOf(coo).boss, BossKind.duskMoth);
        final gargoyle = CampaignLevel(
          name: 'Storm Warning',
          delivery: delivery,
          plan: nyPlan(
            id: '3-4',
            lineup: const [EnemyKind.simpleBat],
            boss: BossKind.searchlightGargoyle,
          ),
        );
        expect(gargoyle.isGuardian, isTrue);
        // (The synthetic level carries no line of its own, like the real
        // 3-4 before it was given one.)
        expect(Campaign.bossLine(gargoyle), isNull, reason: 'no line given');
        // A level without a boss is neither.
        final plain = level('3-1');
        expect(
          plain.isBoss || plain.isChapterBoss || plain.isGuardian,
          isFalse,
        );
      },
    );

    test('a boss line per level: a guardian\'s own, else its chapter\'s', () {
      for (final chapter in Campaign.chapters) {
        for (final level in chapter.levels) {
          expect(
            Campaign.bossLine(level),
            level.isChapterBoss
                ? chapter.bossLine
                : level.isGuardian
                ? level.bossLine
                : isNull,
            reason: level.id,
          );
        }
      }
      // The guardians speak on their own cards, in the story's words.
      expect(
        Campaign.bossLine(level('2-6')),
        'Return to sender! This route has a courier.',
      );
      expect(
        Campaign.bossLine(level('3-2')),
        'Nobody flies till the bread cart is found!',
      );
      expect(
        Campaign.bossLine(level('3-4')),
        'Hold still! Nobody ever stays in the light.',
      );
      for (final chapter in Campaign.chapters) {
        for (final level in chapter.levels) {
          // Only a guardian carries a line of its own.
          expect(level.bossLine != null, level.isGuardian, reason: level.id);
        }
      }
      expect(
        Campaign.bossLine(level('1-8')),
        'This route is my roost now, little courier!',
      );
      expect(
        Campaign.bossLine(level('3-8')),
        'Hush now. The night mail is sleeping.',
      );
      expect(Campaign.bossLine(level('3-1')), isNull);
    });

    test('a chapter ends, unlocks and posts a card only at its boss level', () {
      setOpen(true);
      addTearDown(() => setOpen(false));
      for (final chapter in Campaign.chapters.take(3)) {
        // Every level but the boss's cleared: the chapter is not finished.
        final almost = [
          for (final level in chapter.levels)
            if (level.id != chapter.bossLevel.id) cleared(level.id),
        ];
        final before = CampaignProgress([
          ...twoChaptersBefore(chapter),
          ...almost,
        ]);
        expect(
          before.chapterComplete(chapter),
          isFalse,
          reason: '${chapter.number}',
        );
        expect(
          before.postcardDue(chapter),
          isFalse,
          reason: '${chapter.number}',
        );
        expect(before.sceneAfter(chapter), isNull, reason: '${chapter.number}');
        // The boss level finishes it.
        final done = CampaignProgress([
          ...twoChaptersBefore(chapter),
          ...almost,
          cleared(chapter.bossLevel.id),
        ]);
        expect(done.chapterComplete(chapter), isTrue);
        expect(done.postcardDue(chapter), isTrue);
      }
    });

    test(
      'clearing the New York levels finishes no chapter and no postcard',
      () {
        setOpen(true);
        addTearDown(() => setOpen(false));
        final progress = CampaignProgress([
          ...twoChapters(),
          for (final id in ['3-1', '3-2', '3-3', '3-4']) cleared(id, stars: 3),
        ]);
        final chapter = Campaign.chapters[2];
        expect(progress.chapterComplete(chapter), isFalse);
        expect(progress.postcardDue(chapter), isFalse);
        expect(progress.sceneAfter(chapter), isNull);
        expect(progress.chapterUnlocked(Campaign.chapters[3]), isFalse);
        // Only Paris's Dusk Empress level could (3-8), and it is not playable.
        expect(Campaign.playable(chapter.bossLevel), isFalse);
      },
    );
  });
}

void setOpen(bool open) => Campaign.openedForTest = open;

/// Records for every level of the chapters before [chapter].
List<LevelRecord> twoChaptersBefore(CampaignChapter chapter) => [
  for (final earlier in Campaign.chapters.take(chapter.number - 1))
    for (final level in earlier.levels) cleared(level.id),
];
