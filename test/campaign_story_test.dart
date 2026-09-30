import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_progress_test.dart' show finished, ids, level;

/// Typewriter quotes and three dots have no place in text the game prints.
final _plain = RegExp('[\'"]|\\.\\.\\.');

void main() {
  test('every level carries a delivery that fits its card and result', () {
    for (final level in Campaign.levels) {
      final delivery = level.delivery, id = level.id;
      expect(delivery.cargo, isNotEmpty, reason: id);
      expect(delivery.cargo.length, lessThanOrEqualTo(42), reason: id);
      expect(delivery.from.length, inInclusiveRange(1, 24), reason: id);
      expect(delivery.thanks.length, inInclusiveRange(1, 48), reason: id);
      for (final text in [delivery.cargo, delivery.from, delivery.thanks]) {
        expect(text, isNot(contains(_plain)), reason: '$id: $text');
        expect(text, text.trim(), reason: id);
      }
      // The cargo names the parcel; the thank-you is a sentence.
      expect(delivery.cargo, isNot(endsWith('.')), reason: id);
      expect(delivery.thanks, matches(RegExp(r'[.!?]$')), reason: id);
      // A lair's letter is for its boss, who signs the grumble back.
      if (level.isBoss) {
        final boss = SkyBoss(number: 1, x: 0, kind: level.boss!).name;
        expect(delivery.from, boss, reason: id);
        expect(delivery.cargo, contains(boss.split(' ').last), reason: id);
      }
    }
    expect(Campaign.levels.map((l) => l.delivery.cargo).toSet(), hasLength(40));
    expect(
      Campaign.levels.map((l) => l.delivery.thanks).toSet(),
      hasLength(40),
    );
  });

  test('scenes open the campaign, each route and each new region, and meet '
      'each boss at its lair', () {
    final before = {
      for (final level in Campaign.levels)
        if (CampaignStory.before(level) != null) level.id,
    };
    expect(before, {
      for (final chapter in Campaign.chapters) ...[
        // The first level of each of the chapter's regions…
        for (final region in chapter.regions)
          chapter.levels.firstWhere((l) => l.region == region).id,
        // …and its boss.
        chapter.bossLevel.id,
      ],
    });
    expect(before, hasLength(18));
    expect(CampaignStory.prologue, same(CampaignStory.before(level('1-1'))));
    expect(CampaignStory.prologue.region, isNull);

    for (final level in Campaign.levels) {
      final scene = CampaignStory.before(level);
      if (scene == null) continue;
      expect(scene.id, 'before-${level.id}');
      // It happens where the level flies; only the prologue is at the club.
      expect(scene.region, level.id == '1-1' ? null : level.region);
      expect(scene.boss, level.boss, reason: scene.id);
    }
    for (final chapter in Campaign.chapters) {
      final scene = CampaignStory.after(chapter);
      expect(scene.id, 'after-${chapter.number}');
      expect(scene.region, chapter.bossLevel.region);
      expect(scene.boss, chapter.boss);
    }
    expect(CampaignStory.scenes, hasLength(23));
    expect(CampaignStory.scenes.map((s) => s.id).toSet(), hasLength(23));
    expect(CampaignStory.scene('after-3'), same(CampaignStory.scenes[13]));
    expect(CampaignStory.scene('nope'), isNull);
    // In the order the story tells them.
    expect(CampaignStory.scenes.take(6).map((s) => s.id), [
      'before-1-1',
      'before-1-4',
      'before-1-6',
      'before-1-8',
      'after-1',
      'before-2-1',
    ]);
  });

  test('scenes are short, and every line fits the speech panel', () {
    for (final scene in CampaignStory.scenes) {
      expect(scene.lines.length, inInclusiveRange(3, 9), reason: scene.id);
      for (final line in scene.lines) {
        final where = '${scene.id}: ${line.text}';
        expect(line.text.length, inInclusiveRange(1, 100), reason: where);
        expect(line.text, isNot(contains(_plain)), reason: where);
        expect(line.text, line.text.trim(), reason: where);
        expect(line.text, matches(RegExp(r'[.!?…”]$')), reason: where);
        // Only a scene with a boss can give it a line.
        if (line.speaker == StorySpeaker.boss) {
          expect(scene.boss, isNotNull, reason: where);
        }
        if (line.speaker == StorySpeaker.caption) {
          expect(line.mood, StoryMood.plain, reason: where);
        }
      }
      // A conversation: never one voice alone (captions aside).
      final voices = {
        for (final line in scene.lines)
          if (line.speaker != StorySpeaker.caption) line.speaker,
      };
      expect(voices.length, greaterThanOrEqualTo(2), reason: scene.id);
      expect(voices, contains(StorySpeaker.courier), reason: scene.id);
      // A scene with a boss lets it speak.
      if (scene.boss != null) {
        expect(voices, contains(StorySpeaker.boss), reason: scene.id);
      }
      // No two lines alike in one scene.
      expect(
        scene.lines.map((l) => l.text).toSet(),
        hasLength(scene.lines.length),
        reason: scene.id,
      );
    }
  });

  test('each boss says its line at the lair, as it does in the flight', () {
    for (final chapter in Campaign.chapters) {
      final scene = CampaignStory.before(chapter.bossLevel)!;
      final taunts = scene.lines.where((l) => l.speaker == StorySpeaker.boss);
      expect(taunts.map((l) => l.text), contains(chapter.bossLine));
      expect(scene.lines.last.speaker, StorySpeaker.postmaster);
      // Beaten, it opens the scene that follows.
      expect(
        CampaignStory.after(chapter).lines.first.speaker,
        StorySpeaker.boss,
      );
      expect(CampaignStory.after(chapter).lines.first.mood, StoryMood.sad);
    }
  });

  test('the story opens and closes on the club rule', () {
    final prologue = CampaignStory.prologue.lines;
    final ending = CampaignStory.after(Campaign.chapters.last).lines;
    expect(prologue.first.speaker, StorySpeaker.caption);
    expect(prologue.last.text, contains(CampaignStory.motto));
    expect(ending.last.text, CampaignStory.motto);
    expect(ending.last.speaker, StorySpeaker.courier);
    // Every boss but the last was sent a letter with a flame seal; the
    // trail is picked up in each scene after a fall.
    for (final chapter in Campaign.chapters.take(4)) {
      final text = CampaignStory.after(chapter).lines.map((l) => l.text);
      expect(text.join(' '), contains('seal'), reason: '${chapter.number}');
    }
  });

  group('what plays by itself', () {
    test('the prologue, until it is watched or 1-1 is finished', () {
      final prologue = CampaignStory.prologue;
      expect(CampaignProgress(const []).prologueDue, same(prologue));
      expect(
        CampaignProgress(const [], storyWatched: {prologue.id}).prologueDue,
        isNull,
      );
      expect(CampaignProgress(finished(['1-1'])).prologueDue, isNull);
      // A failed first flight leaves it to play: nothing is finished yet.
      expect(
        CampaignProgress([LevelRecord(levelId: '1-1', plays: 2)]).prologueDue,
        same(prologue),
      );
    });

    test('a level\'s scene, once, before its first finish', () {
      var progress = CampaignProgress(finished(ids('1-1', '1-3')));
      final scene = CampaignStory.before(level('1-4'))!;
      expect(progress.sceneBefore(level('1-4')), same(scene));
      expect(progress.sceneBefore(level('1-2')), isNull);
      expect(progress.sceneBefore(level('1-5')), isNull);
      progress = CampaignProgress(
        finished(ids('1-1', '1-3')),
        storyWatched: {scene.id},
      );
      expect(progress.sceneBefore(level('1-4')), isNull);
      // Finished before the story was told: its card's key tells it.
      progress = CampaignProgress(finished(ids('1-1', '1-4')));
      expect(progress.sceneBefore(level('1-4')), isNull);
    });

    test('a boss\'s last scene, with its postcard', () {
      final chapter = Campaign.chapters[0];
      final scene = CampaignStory.after(chapter);
      var progress = CampaignProgress(finished(ids('1-1', '1-7')));
      expect(progress.sceneAfter(chapter), isNull);
      final records = finished(ids('1-1', '1-8'));
      progress = CampaignProgress(records);
      expect(progress.sceneAfter(chapter), same(scene));
      progress = CampaignProgress(records, storyWatched: {scene.id});
      expect(progress.sceneAfter(chapter), isNull);
      expect(progress.postcardDue(chapter), isTrue);
      // Once the postcard has been seen, the scene no longer arrives.
      progress = CampaignProgress([
        ...records.take(7),
        records.last.withPostcardSeen(),
      ]);
      expect(progress.sceneAfter(chapter), isNull);
    });
  });
}
