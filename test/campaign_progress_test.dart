import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/world_region.dart';

CampaignLevel level(String id) => Campaign.level(id)!;

final day = DateTime(2026, 9, 30, 12);

/// Records for levels finished with [stars] each, played a minute apart
/// in the order given.
List<LevelRecord> finished(Iterable<String> ids, {int stars = 1}) => [
  for (final (i, id) in ids.indexed)
    LevelRecord(
      levelId: id,
      bestStars: stars,
      plays: 1,
      firstClearedAt: day,
      lastPlayedAt: day.add(Duration(minutes: i)),
    ),
];

List<String> ids(String from, String to) {
  final all = Campaign.levels.map((l) => l.id).toList();
  return all.sublist(all.indexOf(from), all.indexOf(to) + 1);
}

/// New York (3-1 to 3-4) is open in the build as it ships (`NEW_YORK_OPEN`
/// defaults to true); a build made with `NEW_YORK_OPEN=false` closes it. Each
/// test that depends on the state forces it with the test hooks, so the suite
/// passes under either define.
void main() {
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  test('only the first level is open at the start', () {
    final progress = CampaignProgress(const []);
    expect(progress.unlocked(level('1-1')), isTrue);
    for (final level in Campaign.levels.skip(1)) {
      expect(progress.unlocked(level), isFalse, reason: level.id);
    }
    expect(progress.current.id, '1-1');
    expect(progress.totalStars, 0);
    expect(progress.record(level('1-1')).plays, 0);
  });

  test('finishing a level unlocks the next; failing it does not', () {
    final failed = const LevelRecord(
      levelId: '1-1',
    ).merge(stars: 0, collected: 20, score: 40, at: day);
    var progress = CampaignProgress([failed]);
    expect(progress.unlocked(level('1-2')), isFalse);
    expect(progress.current.id, '1-1');
    progress = CampaignProgress(finished(['1-1']));
    expect(progress.unlocked(level('1-2')), isTrue);
    expect(progress.unlocked(level('1-3')), isFalse);
    expect(progress.current.id, '1-2');
    // Any unlocked level can be replayed.
    expect(progress.unlocked(level('1-1')), isTrue);
  });

  test('beating a boss opens the next chapter; 4 and 5 stay locked', () {
    var progress = CampaignProgress(finished(ids('1-1', '1-7')));
    expect(progress.unlocked(level('1-8')), isTrue);
    expect(progress.unlocked(level('2-1')), isFalse);
    expect(progress.chapterComplete(Campaign.chapters[0]), isFalse);
    expect(progress.chapterUnlocked(Campaign.chapters[1]), isFalse);
    progress = CampaignProgress(finished(ids('1-1', '1-8')));
    expect(progress.chapterComplete(Campaign.chapters[0]), isTrue);
    expect(progress.chapterUnlocked(Campaign.chapters[1]), isTrue);
    expect(progress.current.id, '2-1');
    progress = CampaignProgress(finished(ids('1-1', '2-9')));
    expect(progress.chapterComplete(Campaign.chapters[1]), isTrue);
    // Open, as the build ships: the Dragon opens New York, and only New York
    // (3-1 now, the rest of the stop level by level); Paris and chapters 4
    // and 5 stay locked.
    Campaign.openedForTest = true;
    expect(progress.chapterUnlocked(Campaign.chapters[2]), isTrue);
    for (final level in Campaign.chapters[2].levels) {
      expect(progress.unlocked(level), level.id == '3-1', reason: level.id);
    }
    for (final chapter in Campaign.chapters.skip(3)) {
      expect(progress.chapterUnlocked(chapter), isFalse);
      for (final level in chapter.levels) {
        expect(progress.unlocked(level), isFalse, reason: level.id);
      }
    }
    // Paris waits, however much of New York is cleared.
    progress = CampaignProgress(finished(ids('1-1', '3-4')));
    expect(progress.unlocked(level('3-5')), isFalse, reason: 'Paris waits');
    // Closed (NEW_YORK_OPEN=false): the Dragon opens nothing, chapters 3 to 5
    // all stay locked and even a stray record cannot open one.
    Campaign.openedForTest = false;
    Campaign.closedForTest = true;
    progress = CampaignProgress(finished(ids('1-1', '2-9')));
    for (final chapter in Campaign.chapters.skip(2)) {
      expect(progress.chapterUnlocked(chapter), isFalse);
      for (final level in chapter.levels) {
        expect(progress.unlocked(level), isFalse, reason: level.id);
      }
    }
    progress = CampaignProgress(finished(ids('1-1', '3-3')));
    expect(progress.unlocked(level('3-1')), isFalse);
  });

  test('the current level is the first unfinished one, then the last '
      'played', () {
    // A gap left by a stray record: the first unfinished unlocked level.
    var progress = CampaignProgress(finished(['1-1', '1-2', '1-4']));
    expect(progress.current.id, '1-3');
    final all = finished(ids('1-1', '2-9'));
    // Closed (NEW_YORK_OPEN=false), chapters 1 and 2 are the whole campaign:
    // once every level is finished the courier is on the last one flown (a
    // replayed 1-5), and without play times on 2-9.
    Campaign.closedForTest = true;
    progress = CampaignProgress([
      for (final record in all)
        record.levelId == '1-5'
            ? record.merge(
                stars: 1,
                collected: 0,
                score: 0,
                at: day.add(const Duration(days: 1)),
              )
            : record,
    ]);
    expect(progress.current.id, '1-5');
    progress = CampaignProgress(all);
    expect(progress.current.id, '2-9');
    progress = CampaignProgress([
      for (final id in ids('1-1', '2-9')) LevelRecord(levelId: id, bestStars: 2),
    ]);
    expect(progress.current.id, '2-9');
    // Open, as the build ships: the Dragon's win leads on to New York's
    // 3-1, the first unfinished level, and a finished stop leaves the
    // courier on its last level, 3-4 (without play times too).
    Campaign.closedForTest = false;
    Campaign.openedForTest = true;
    progress = CampaignProgress(all);
    expect(progress.current.id, '3-1');
    progress = CampaignProgress(finished(ids('1-1', '3-4')));
    expect(progress.current.id, '3-4');
    progress = CampaignProgress([
      for (final id in ids('1-1', '3-4')) LevelRecord(levelId: id, bestStars: 2),
    ]);
    expect(progress.current.id, '3-4');
  });

  test('the star total counts only levels the build can fly', () {
    // A save that earned stars in New York (an open build) and is opened by a
    // build with it closed must not show more stars than the "N / 51" it is
    // set against; the open build counts them against "N / 63" (chapter 2
    // has nine levels since Egypt's guardian, rules 50).
    final records = [
      ...finished(ids('1-1', '2-9'), stars: 3),
      ...finished(['3-1', '3-2', '3-3', '3-4'], stars: 3),
    ];
    final progress = CampaignProgress(records);
    Campaign.openedForTest = true;
    expect(progress.totalStars, 63);
    expect(progress.starsInChapter(Campaign.chapters[2]), 12);
    expect(progress.starsInRegion(WorldRegion.newYork), 12);
    Campaign.openedForTest = false;
    Campaign.closedForTest = true;
    expect(progress.totalStars, 51);
    expect(progress.starsInChapter(Campaign.chapters[2]), 0);
    expect(progress.starsInRegion(WorldRegion.newYork), 0);
    expect(progress.starsInChapter(Campaign.chapters[1]), 27);
    // Stars in levels no build can fly never count (Paris): a stray record.
    Campaign.closedForTest = false;
    Campaign.openedForTest = true;
    final stray = CampaignProgress([...records, ...finished(['3-5'], stars: 3)]);
    expect(stray.totalStars, 63);
  });

  test('a result keeps the bests and counts the play', () {
    var record = const LevelRecord(levelId: '1-4');
    // A failed flight counts as a play but sets no best.
    record = record.merge(stars: 0, collected: 30, score: 90, at: day);
    expect(record.plays, 1);
    expect(record.bestStars, 0);
    expect(record.bestCollected, 0);
    expect(record.bestScore, 0);
    expect(record.firstClearedAt, isNull);
    expect(record.lastPlayedAt, day);
    expect(record.cleared, isFalse);
    final cleared = day.add(const Duration(hours: 1));
    record = record.merge(stars: 2, collected: 50, score: 80, at: cleared);
    expect(record.bestStars, 2);
    expect(record.bestCollected, 50);
    expect(record.bestScore, 80);
    expect(record.firstClearedAt, cleared);
    expect(record.lastPlayedAt, cleared);
    final later = cleared.add(const Duration(hours: 1));
    record = record.merge(stars: 1, collected: 20, score: 120, at: later);
    expect(record.plays, 3);
    expect(record.bestStars, 2);
    expect(record.bestCollected, 50);
    expect(record.bestScore, 120);
    expect(record.firstClearedAt, cleared);
    expect(record.lastPlayedAt, later);
    // A failed flight that collected more still leaves the bests alone.
    final lost = later.add(const Duration(hours: 1));
    record = record.merge(stars: 0, collected: 72, score: 300, at: lost);
    expect(record.plays, 4);
    expect(record.bestStars, 2);
    expect(record.bestCollected, 50);
    expect(record.bestScore, 120);
    expect(record.lastPlayedAt, lost);
    expect(record.postcardSeen, isFalse);
    expect(record.withPostcardSeen().postcardSeen, isTrue);
    expect(record.withPostcardSeen().plays, 4);
  });

  test('stars add up by level, chapter and region', () {
    final progress = CampaignProgress([
      ...finished(ids('1-1', '1-8'), stars: 3),
      ...finished(['2-1', '2-2'], stars: 2),
    ]);
    expect(progress.totalStars, 28);
    expect(progress.starsInChapter(Campaign.chapters[0]), 24);
    expect(progress.starsInChapter(Campaign.chapters[1]), 4);
    expect(progress.starsInRegion(WorldRegion.jungle), 9);
    expect(progress.starsInRegion(WorldRegion.brazil), 6);
    expect(progress.starsInRegion(WorldRegion.rome), 4);
    expect(progress.starsInRegion(WorldRegion.egypt), 0);
    expect(progress.stars(level('2-1')), 2);
  });

  test("a chapter's postcard is due once its boss first falls", () {
    final chapter = Campaign.chapters[0];
    var progress = CampaignProgress(finished(ids('1-1', '1-7')));
    expect(progress.postcardDue(chapter), isFalse);
    final records = finished(ids('1-1', '1-8'));
    progress = CampaignProgress(records);
    expect(progress.postcardDue(chapter), isTrue);
    progress = CampaignProgress([
      ...records.take(7),
      records.last.withPostcardSeen(),
    ]);
    expect(progress.postcardDue(chapter), isFalse);
    expect(progress.chapterComplete(chapter), isTrue);
  });
}
