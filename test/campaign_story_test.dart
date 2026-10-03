import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/neferhoo_encounter_art.dart';

import 'campaign_progress_test.dart' show finished, ids, level;

/// Typewriter quotes and three dots have no place in text the game prints.
final _plain = RegExp('[\'"]|\\.\\.\\.');

/// The guardians: Egypt's Neferhoo on 2-6 (rules 50) and New York's
/// mini-bosses of 3-2 and 3-4, who meet the courier at their lair and have a
/// last word, but are no chapter's boss (no flame seal, no postcard).
const _guardians = {
  '2-6': BossKind.neferhoo,
  '3-2': BossKind.kingCoo,
  '3-4': BossKind.searchlightGargoyle,
};

/// New York's two. Their last words keep the pattern every chapter boss's
/// `after-…` scene has: the beaten guardian opens, sad, and Bill has the last
/// spoken word, offering it a place at the club.
const _newYork = {'3-2', '3-4'};

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
      // A chapter boss's letter is for the boss, who signs the grumble
      // back. A guardian only stands in the way of an ordinary delivery,
      // whose sender thanks the courier as usual.
      if (level.boss != null) {
        final boss = SkyBoss(
          number: 1,
          x: 0,
          kind: level.boss!,
          cinematic: true,
        ).name;
        if (level.isChapterBoss) {
          expect(delivery.from, boss, reason: id);
          expect(delivery.cargo, contains(boss.split(' ').last), reason: id);
        } else {
          expect(delivery.from, isNot(boss), reason: id);
        }
      }
    }
    expect(Campaign.levels.map((l) => l.delivery.cargo).toSet(), hasLength(41));
    expect(
      Campaign.levels.map((l) => l.delivery.thanks).toSet(),
      hasLength(41),
    );
  });

  test('scenes open the campaign, each route and each new region, and meet '
      'each boss and each guardian at its lair', () {
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
      // …and each guardian, whose lair is not the chapter's.
      ..._guardians.keys,
    });
    expect(before, hasLength(21));
    expect(CampaignStory.prologue, same(CampaignStory.before(level('1-1'))));
    expect(CampaignStory.prologue.region, isNull);

    for (final level in Campaign.levels) {
      final scene = CampaignStory.before(level);
      if (scene == null) continue;
      expect(scene.id, 'before-${level.id}');
      // It happens where the level flies; only the prologue is at the club.
      expect(scene.region, level.id == '1-1' ? null : level.region);
      expect(scene.boss, _guardians[level.id] ?? level.boss, reason: scene.id);
      // Whatever boss the level data names is the one the scene meets.
      if (level.boss != null) expect(scene.boss, level.boss, reason: scene.id);
      // A level with a mini-boss is one of the guardians the story knows.
      if (level.isGuardian) {
        expect(_guardians, contains(level.id), reason: level.id);
      }
      expect(scene.bossBeaten, isFalse, reason: scene.id);
    }
    for (final chapter in Campaign.chapters) {
      final scene = CampaignStory.after(chapter);
      expect(scene.id, 'after-${chapter.number}');
      expect(scene.region, chapter.bossLevel.region);
      expect(scene.boss, chapter.boss);
      expect(scene.bossBeaten, isTrue, reason: scene.id);
    }
    expect(CampaignStory.scenes, hasLength(29));
    expect(CampaignStory.scenes.map((s) => s.id).toSet(), hasLength(29));
    expect(CampaignStory.scene('after-3'), same(CampaignStory.scenes[19]));
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
    // Egypt and Arabia since Egypt's guardian took 2-6: his last word
    // follows his lair, before Arabia's arrival.
    expect(CampaignStory.scenes.skip(5).take(7).map((s) => s.id), [
      'before-2-1',
      'before-2-4',
      'before-2-6',
      'last-2-6',
      'before-2-7',
      'before-2-9',
      'after-2',
    ]);
    // New York: a guardian's last word follows its lair, before the next
    // level's scene.
    expect(CampaignStory.scenes.skip(12).map((s) => s.id), [
      'before-3-1',
      'before-3-2',
      'last-3-2',
      'before-3-4',
      'last-3-4',
      'before-3-5',
      'before-3-8',
      'after-3',
      'before-4-1',
      'before-4-4',
      'before-4-8',
      'after-4',
      'before-5-1',
      'before-5-3',
      'before-5-6',
      'before-5-8',
      'after-5',
    ]);
  });

  test(
    'a guardian has a last word after its fall, and no other level does',
    () {
      final last = {
        for (final level in Campaign.levels)
          if (CampaignStory.lastWord(level) != null) level.id,
      };
      expect(last, _guardians.keys.toSet());
      for (final MapEntry(key: id, value: boss) in _guardians.entries) {
        final scene = CampaignStory.lastWord(level(id))!;
        expect(scene.id, 'last-$id');
        expect(scene.region, level(id).region);
        expect(scene.boss, boss);
        expect(scene.bossBeaten, isTrue);
        expect(scene, isNot(same(CampaignStory.before(level(id)))));
        // Beaten, it speaks first.
        expect(scene.lines.first.speaker, StorySpeaker.boss, reason: id);
        final spoken = scene.lines
            .where((l) => l.speaker != StorySpeaker.caption)
            .toList();
        // Bill offers it a place at the club, near the end.
        final offer = spoken.lastIndexWhere(
          (l) => l.speaker == StorySpeaker.postmaster,
        );
        expect(offer, greaterThanOrEqualTo(spoken.length - 2), reason: id);
        if (_newYork.contains(id)) {
          // New York's two are sad about it, as a chapter boss is, and Bill
          // has the last spoken word.
          expect(scene.lines.first.mood, StoryMood.sad, reason: id);
          expect(spoken.last.speaker, StorySpeaker.postmaster, reason: id);
        } else {
          // Neferhoo (2-6) is the exception the owner-approved script makes,
          // on purpose: his fall is the story's reveal (the mask that hid
          // the door comes off), so he opens surprised, not sad; and his
          // answer to Bill's offer closes the talk ("…Then I start with this
          // one"), before the Sphinx's note is read aloud.
          expect(scene.lines.first.mood, StoryMood.surprised, reason: id);
          expect(scene.lines.first.text, contains('I can see'), reason: id);
          expect(spoken.last.speaker, StorySpeaker.boss, reason: id);
          expect(spoken.last.mood, StoryMood.happy, reason: id);
          expect(spoken[offer].text, contains('Care to apply?'), reason: id);
        }
        // No flame seal comes up: a guardian was sent no letter.
        final text = scene.lines.map((l) => l.text).join(' ');
        expect(text, isNot(contains('seal')), reason: id);
      }
      // A chapter's boss has the after scene, which brings the postcard.
      for (final chapter in Campaign.chapters) {
        expect(CampaignStory.lastWord(chapter.bossLevel), isNull);
      }
      // Bill tells the courier up front that it is not a seal fight.
      for (final id in ['2-6', '3-2']) {
        expect(
          CampaignStory.before(level(id))!.lines.map((l) => l.text).join(' '),
          contains('No flame seal'),
          reason: id,
        );
      }
      // The chapter's own trail still counts three seals after its boss.
      expect(
        CampaignStory.after(Campaign.chapters[2]).lines.map((l) => l.text),
        contains(
          'Three seals now. And every one posted from the edge of the map.',
        ),
      );
    },
  );

  test('the guardians\' scenes read as one story, and no line outruns the '
      'recorded ones', () {
    String text(String scene, int line) =>
        CampaignStory.scene(scene)!.lines[line].text;
    StoryMood mood(String scene, int line) =>
        CampaignStory.scene(scene)!.lines[line].mood;
    // He is a stone eagle: his beak, not a nose, is chipped; and the courier
    // does not hold back the bread cart until the fight is over.
    expect(
      text('last-3-4', 0),
      allOf(contains('beak'), isNot(contains('nose'))),
    );
    expect(
      text('last-3-2', 1),
      startsWith('Commissioner, I remember a bread cart'),
    );
    // The vane is the tower's (the keeper's thank-you on 3-4), the courier
    // gives the Gargoyle what he asked for, and "You looked" answers it.
    expect(text('before-3-4', 2), contains('the tower’s weather vane'));
    expect(text('last-3-4', 1), contains('I couldn’t look away'));
    expect(text('last-3-4', 1), contains('the tower’s new weather vane'));
    expect(text('last-3-4', 2), startsWith('You looked.'));
    expect(mood('last-3-4', 2), StoryMood.happy);
    // King Coo's job is his own title, offered in the pigeonholes.
    expect(text('last-3-2', 5), contains('Commissioner wanted'));
    expect(text('last-3-2', 6), contains('The Commissioner accepts'));
    // "Guardian" is the word the map and the card use, so Bill says it; the
    // steam is "vents" everywhere, and the squadron's open lane is the HUD's.
    expect(text('before-3-2', 5), contains('this guardian'));
    expect(text('before-3-2', 7), contains('open lane'));
    expect(
      text('last-3-2', 7),
      allOf(contains('Vents hiss'), contains('burst')),
    );
    // The gag that pays off, and the recorded term for the mail.
    expect(text('before-3-4', 5), contains('Don’t mention pigeons'));
    expect(text('last-3-4', 5), contains('the pigeons may stay'));
    expect(text('last-3-4', 3), contains('night mail'));
    for (final id in [
      'before-2-6',
      'last-2-6',
      'before-3-2',
      'last-3-2',
      'before-3-4',
      'last-3-4',
    ]) {
      for (final line in CampaignStory.scene(id)!.lines) {
        final lowered = line.text.toLowerCase();
        expect(lowered, isNot(contains('pipes')), reason: line.text);
        expect(lowered, isNot(contains('night post')), reason: line.text);
        expect(lowered, isNot(contains('green lane')), reason: line.text);
        // The longest recorded line is 82 characters; the new ones stay
        // within a few of it, so no line is a mouthful for the voice.
        expect(line.text.length, lessThanOrEqualTo(85), reason: line.text);
      }
    }
  });

  test('Neferhoo\'s scenes pay off the letter Egypt lost', () {
    StoryLine line(String scene, int i) => CampaignStory.scene(scene)!.lines[i];
    String text(String scene, int i) => line(scene, i).text;
    final lair = CampaignStory.before(level('2-6'))!;
    final last = CampaignStory.lastWord(level('2-6'))!;
    expect(lair.lines, hasLength(9));
    expect(last.lines, hasLength(9));
    // Set up on arrival in Egypt (recorded): one letter lost, and the Sphinx
    // won't say which.
    expect(text('before-2-4', 0), contains('lost one letter'));
    expect(text('before-2-4', 2), startsWith('The Sphinx won’t say.'));
    // Why now: the caretaker's feather duster, the level's own delivery.
    final delivery = level('2-6').delivery;
    expect(text('before-2-6', 0), contains('feather duster for the pyramid'));
    expect(delivery.cargo, contains('feather duster'));
    expect(delivery.from, 'The pyramid caretaker');
    expect(delivery.thanks, 'Four thousand years of dust, gone by lunch!');
    // Who he is, why he fights (his pride: the card line, line 7, which the
    // flight's `neferhoo-card` pool plays as clip `before-2-6-7`).
    expect(line('before-2-6', 3).speaker, StorySpeaker.boss);
    expect(
      text('before-2-6', 3),
      startsWith('${Neferhoo.name}, Royal Courier.'),
    );
    expect(text('before-2-6', 7), CampaignStory.guardianLines['2-6']);
    expect(Campaign.bossLine(level('2-6')), text('before-2-6', 7));
    // Why the letter was lost: he could not find its door (through his
    // mask), paid off when the mask comes off.
    expect(text('before-2-6', 4), contains('cannot find its door'));
    expect(text('before-2-6', 5), contains('the letter we lost'));
    expect(
      text('last-2-6', 0),
      allOf(startsWith('My mask!'), endsWith('I can see!')),
    );
    // Who knew: the addressee, too polite to complain.
    expect(text('last-2-6', 2), startsWith('“To the Sphinx, Giza.”'));
    expect(text('last-2-6', 3), contains('too polite to complain'));
    // The club rule, and a job that matches his title.
    expect(text('last-2-6', 5), contains('Every letter lands'));
    expect(Neferhoo.title, 'KEEPER OF THE LOST LETTER');
    expect(text('last-2-6', 6), contains('Keeper of Lost Letters'));
    expect(text('last-2-6', 7), contains('Off to the Sphinx'));
    // The Sphinx's note closes it: a letter read aloud (a caption on
    // airmail paper, in the Sphinx's voice), signed as the Dragon's is.
    final note = last.lines.last;
    expect(note.speaker, StorySpeaker.caption);
    expect(note.endOfStop, isFalse);
    expect(
      note.text,
      '“Delivered at last. Worth the wait. Signed: the Sphinx.”',
    );
    expect(last.endsStop, isFalse);
    // The arrival banner says the same dust is stirring.
    expect(NeferhooEncounterArt.omenLine, 'The pyramid’s dust is stirring…');
  });

  test('the stop ends on a To be continued caption, until Paris opens', () {
    final ending = CampaignStory.lastWord(level('3-4'))!;
    expect(ending.endsStop, isTrue);
    final line = ending.lines.last;
    expect(line.endOfStop, isTrue);
    // Nobody says it: it is a caption, and it names the next stop.
    expect(line.speaker, StorySpeaker.caption);
    expect(line.mood, StoryMood.plain);
    expect(line.text, startsWith('To be continued…'));
    expect(line.text, contains('Paris'));
    // It is the only one, and it is always a scene's very last line.
    final marked = [
      for (final scene in CampaignStory.scenes)
        for (final (i, l) in scene.lines.indexed)
          if (l.endOfStop) (scene.id, i == scene.lines.length - 1),
    ];
    expect(marked, [('last-3-4', true)]);
    for (final scene in CampaignStory.scenes) {
      expect(scene.endsStop, scene.id == 'last-3-4', reason: scene.id);
    }
    // An ordinary caption is not one.
    expect(const StoryLine.caption('Somewhere.').endOfStop, isFalse);
    expect(const StoryLine.bill('Hello.').endOfStop, isFalse);
    // Paris's own arrival scene is still there for the day it opens.
    expect(CampaignStory.before(level('3-5'))!.id, 'before-3-5');
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

  test('each guardian says its card line at the lair, as it does in the '
      'flight', () {
    expect(CampaignStory.guardianLines.keys.toSet(), _guardians.keys.toSet());
    expect(_newYork, everyElement(isIn(_guardians.keys)));
    for (final MapEntry(key: id, value: card)
        in CampaignStory.guardianLines.entries) {
      // What the entrance name card prints: short, in the level's data.
      expect(card.length, lessThanOrEqualTo(43), reason: id);
      expect(card, isNot(contains(_plain)), reason: id);
      if (level(id).boss != null) {
        expect(Campaign.bossLine(level(id)), card, reason: id);
      }
      final scene = CampaignStory.before(level(id))!;
      final taunts = scene.lines.where((l) => l.speaker == StorySpeaker.boss);
      expect(taunts.map((l) => l.text), contains(card), reason: id);
      // Bill has the last word of the lair scene: the fight's tip.
      expect(scene.lines.last.speaker, StorySpeaker.postmaster, reason: id);
      // The card line is the boss's last, right before Bill's tip.
      expect(scene.lines[scene.lines.length - 2].text, card, reason: id);
    }
    // Three mechanics are explained where Bill already speaks.
    String bill(String id, int line) =>
        CampaignStory.before(level(id))!.lines[line].text;
    expect(bill('3-2', 5), contains('star-grabbing'));
    expect(
      bill('3-2', 7),
      allOf(contains('puffs up'), contains('crumb bombs')),
    );
    expect(
      bill('3-4', 5),
      allOf(contains('Stay in the dark'), contains('lamp')),
    );
    expect(
      CampaignStory.lastWord(level('3-2'))!.lines.last.text,
      contains('Steam Alley'),
    );
    expect(
      CampaignStory.lastWord(level('3-2'))!.lines.last.text,
      contains('hiss'),
    );
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

    test('a guardian\'s last word, once, after its first finish', () {
      final l = level('3-2');
      final scene = CampaignStory.lastWord(l)!;
      // Until the guardian is beaten there is nothing to say.
      var progress = CampaignProgress(finished(['3-1']));
      expect(progress.sceneLast(l), isNull);
      final records = finished(ids('1-1', '3-2'));
      progress = CampaignProgress(records);
      expect(progress.sceneLast(l), same(scene));
      // Watched once, it does not come again.
      progress = CampaignProgress(records, storyWatched: {scene.id});
      expect(progress.sceneLast(l), isNull);
      // Neither its lair scene nor anything else stands in for it.
      progress = CampaignProgress(records, storyWatched: {'before-3-2'});
      expect(progress.sceneLast(l), same(scene));
      // A level with no last word has none to play.
      expect(CampaignProgress(records).sceneLast(level('3-1')), isNull);
      expect(CampaignProgress(records).sceneLast(level('1-8')), isNull);
      // A guardian brings no postcard and does not finish the chapter: only
      // the chapter's boss does.
      final chapter = Campaign.chapters[2];
      expect(progress.chapterComplete(chapter), isFalse);
      expect(progress.postcardDue(chapter), isFalse);
      expect(progress.sceneAfter(chapter), isNull);
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
