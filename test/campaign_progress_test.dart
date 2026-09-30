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

void main() {
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

  test('beating a boss opens the next chapter; 3 to 5 stay locked', () {
    var progress = CampaignProgress(finished(ids('1-1', '1-7')));
    expect(progress.unlocked(level('1-8')), isTrue);
    expect(progress.unlocked(level('2-1')), isFalse);
    expect(progress.chapterComplete(Campaign.chapters[0]), isFalse);
    expect(progress.chapterUnlocked(Campaign.chapters[1]), isFalse);
    progress = CampaignProgress(finished(ids('1-1', '1-8')));
    expect(progress.chapterComplete(Campaign.chapters[0]), isTrue);
    expect(progress.chapterUnlocked(Campaign.chapters[1]), isTrue);
    expect(progress.current.id, '2-1');
    progress = CampaignProgress(finished(ids('1-1', '2-8')));
    expect(progress.chapterComplete(Campaign.chapters[1]), isTrue);
    for (final chapter in Campaign.chapters.skip(2)) {
      expect(progress.chapterUnlocked(chapter), isFalse);
      for (final level in chapter.levels) {
        expect(progress.unlocked(level), isFalse, reason: level.id);
      }
    }
    // Even a stray record cannot open a locked chapter.
    progress = CampaignProgress(finished(ids('1-1', '3-3')));
    expect(progress.unlocked(level('3-1')), isFalse);
  });

  test('the current level is the first unfinished one, then the last '
      'played', () {
    // A gap left by a stray record: the first unfinished unlocked level.
    var progress = CampaignProgress(finished(['1-1', '1-2', '1-4']));
    expect(progress.current.id, '1-3');
    final all = finished(ids('1-1', '2-8'));
    progress = CampaignProgress(all);
    expect(progress.current.id, '2-8');
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
    // Without play times, the furthest finished level.
    progress = CampaignProgress([
      for (final id in ids('1-1', '2-8'))
        LevelRecord(levelId: id, bestStars: 2),
    ]);
    expect(progress.current.id, '2-8');
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
