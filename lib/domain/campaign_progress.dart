import 'campaign.dart';
import 'campaign_story.dart';
import 'world_region.dart';

/// A level's best results, as saved. Level stars stay stored so a future
/// upgrade shop can spend them.
class LevelRecord {
  const LevelRecord({
    required this.levelId,
    this.bestStars = 0,
    this.bestCollected = 0,
    this.bestScore = 0,
    this.plays = 0,
    this.firstClearedAt,
    this.lastPlayedAt,
    this.postcardSeen = false,
  });
  final String levelId;

  /// Best level stars (0–3) and the most stars collected in one finished
  /// flight; [bestScore] is that kind of best too.
  final int bestStars, bestCollected;
  final int bestScore, plays;

  /// When the level was first finished, and last flown.
  final DateTime? firstClearedAt, lastPlayedAt;

  /// Only read on a boss level: whether its chapter's postcard has been
  /// shown.
  final bool postcardSeen;

  /// Finished at least once, which unlocks the next level.
  bool get cleared => bestStars > 0;

  /// Folds in a flight that earned [stars] level stars (0 when it failed),
  /// collected [collected] stars and scored [score]. Every flight counts as
  /// a play, but only a finished one (1 star or more) can set a best, so the
  /// best star count always belongs to a delivered flight.
  LevelRecord merge({
    required int stars,
    required int collected,
    required int score,
    required DateTime at,
  }) {
    final finished = stars > 0;
    return LevelRecord(
      levelId: levelId,
      bestStars: stars > bestStars ? stars : bestStars,
      bestCollected: finished && collected > bestCollected
          ? collected
          : bestCollected,
      bestScore: finished && score > bestScore ? score : bestScore,
      plays: plays + 1,
      firstClearedAt: firstClearedAt ?? (finished ? at : null),
      lastPlayedAt: at,
      postcardSeen: postcardSeen,
    );
  }

  LevelRecord withPostcardSeen() => LevelRecord(
    levelId: levelId,
    bestStars: bestStars,
    bestCollected: bestCollected,
    bestScore: bestScore,
    plays: plays,
    firstClearedAt: firstClearedAt,
    lastPlayedAt: lastPlayedAt,
    postcardSeen: true,
  );
}

/// Where the courier stands on the map, from the saved [LevelRecord]s.
///
/// The first level is open from the start. Finishing a level unlocks the
/// next one, so beating a chapter's boss opens the next chapter; a guardian
/// ([CampaignLevel.isGuardian]) opens only the next level. A level once
/// finished stays open, so a level added before it later (Egypt's 2-6,
/// rules version 50) never locks what a player has already flown. Levels
/// that are not [Campaign.playable] in this build stay locked.
class CampaignProgress {
  CampaignProgress(
    Iterable<LevelRecord> records, {
    this.storyWatched = const {},
  }) : records = {for (final record in records) record.levelId: record};

  /// Saved records by level id. Levels never flown have none.
  final Map<String, LevelRecord> records;

  /// The ids of the story scenes already watched ([StoryScene.id]).
  final Set<String> storyWatched;

  LevelRecord record(CampaignLevel level) =>
      records[level.id] ?? LevelRecord(levelId: level.id);

  bool cleared(CampaignLevel level) => record(level).cleared;
  int stars(CampaignLevel level) => record(level).bestStars;

  bool unlocked(CampaignLevel level) {
    if (!Campaign.playable(level)) return false;
    final previous = Campaign.before(level);
    return cleared(level) || previous == null || cleared(previous);
  }

  bool chapterUnlocked(CampaignChapter chapter) =>
      unlocked(chapter.levels.first);

  /// A chapter is complete once its boss is beaten.
  bool chapterComplete(CampaignChapter chapter) => cleared(chapter.bossLevel);

  /// The postcard arrives after a chapter's boss is first beaten.
  bool postcardDue(CampaignChapter chapter) =>
      chapterComplete(chapter) && !record(chapter.bossLevel).postcardSeen;

  /// The scene that opens the campaign, until it has been watched: the map
  /// plays it on its first visit, before anything else.
  StoryScene? get prologueDue => sceneBefore(Campaign.levels.first);

  /// The scene to play before [level]'s card. It plays by itself once, and
  /// only ahead of the level's first finish; after that the card's story
  /// key replays it.
  StoryScene? sceneBefore(CampaignLevel level) {
    final scene = CampaignStory.before(level);
    return scene == null || storyWatched.contains(scene.id) || cleared(level)
        ? null
        : scene;
  }

  /// The scene to play before [chapter]'s postcard arrives.
  StoryScene? sceneAfter(CampaignChapter chapter) {
    final scene = CampaignStory.after(chapter);
    return postcardDue(chapter) && !storyWatched.contains(scene.id)
        ? scene
        : null;
  }

  /// The scene to play once a guardian ([CampaignLevel.isGuardian]) has
  /// been beaten: its last word at the lair ([CampaignStory.lastWord]). It
  /// plays by itself once, after the level's first finish; a level with no
  /// last word gives null.
  StoryScene? sceneLast(CampaignLevel level) {
    final scene = CampaignStory.lastWord(level);
    return scene == null || !cleared(level) || storyWatched.contains(scene.id)
        ? null
        : scene;
  }

  /// The first unlocked level not yet finished or, once every unlocked
  /// level is finished, the one last flown.
  CampaignLevel get current {
    CampaignLevel? latest;
    for (final level in Campaign.levels) {
      if (!unlocked(level)) continue;
      if (!cleared(level)) return level;
      if (latest == null || !_playedAt(level).isBefore(_playedAt(latest))) {
        latest = level;
      }
    }
    return latest ?? Campaign.levels.first;
  }

  DateTime _playedAt(CampaignLevel level) =>
      record(level).lastPlayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Level stars earned across the campaign: 3 per level at most, over the
  /// levels this build can fly ([Campaign.playable]), so the total never
  /// exceeds the "N / 48" or "N / 60" it is shown against (a build with New
  /// York closed ignores stars a save earned in it).
  int get totalStars => _sum(Campaign.levels);
  int starsInChapter(CampaignChapter chapter) => _sum(chapter.levels);
  int starsInRegion(WorldRegion region) =>
      _sum(Campaign.levels.where((level) => level.region == region));

  int _sum(Iterable<CampaignLevel> levels) => levels
      .where(Campaign.playable)
      .fold(0, (sum, level) => sum + stars(level));
}
