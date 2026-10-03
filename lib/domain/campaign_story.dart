import 'campaign.dart';
import 'sky_boss.dart' show BossKind;
import 'world_region.dart';

/// Who says a line. The courier is the equipped bird, under its own name;
/// the boss is the scene's [StoryScene.boss]. A caption is nobody's voice:
/// where the scene is, or the words of a letter being read.
enum StorySpeaker { courier, postmaster, boss, caption }

/// How a line is said, for the speaker's face.
enum StoryMood { plain, happy, surprised, angry, sad }

/// One line of a scene.
class StoryLine {
  const StoryLine.courier(this.text, [this.mood = StoryMood.plain])
    : speaker = StorySpeaker.courier,
      endOfStop = false;
  const StoryLine.bill(this.text, [this.mood = StoryMood.plain])
    : speaker = StorySpeaker.postmaster,
      endOfStop = false;
  const StoryLine.boss(this.text, [this.mood = StoryMood.plain])
    : speaker = StorySpeaker.boss,
      endOfStop = false;
  const StoryLine.caption(this.text)
    : speaker = StorySpeaker.caption,
      mood = StoryMood.plain,
      endOfStop = false;

  /// The caption that closes a stop whose chapter is not finished yet:
  /// "To be continued…". It is a caption (nobody's voice, no mood) that the
  /// scene player may set as an end card instead of a place plate.
  const StoryLine.endOfStop(this.text)
    : speaker = StorySpeaker.caption,
      mood = StoryMood.plain,
      endOfStop = true;
  final StorySpeaker speaker;
  final String text;
  final StoryMood mood;

  /// Whether this is the closing caption of a stop ([StoryLine.endOfStop]).
  final bool endOfStop;
}

/// A short conversation on the campaign map: the courier, Postmaster Bill
/// and, at a lair, its boss.
class StoryScene {
  const StoryScene({
    required this.id,
    required this.lines,
    this.region,
    this.boss,
  });

  /// Saved once the scene has been watched, so it plays by itself once.
  final String id;

  /// Where it happens: a stop on the journey, or the Sky Club post when
  /// null.
  final WorldRegion? region;

  /// The boss who speaks in it, if one does.
  final BossKind? boss;
  final List<StoryLine> lines;

  /// Whether the boss has been beaten by now: the scenes after a chapter
  /// boss (`after-…`) and a guardian's last word (`last-…`). It has lost its
  /// headwear and looks sheepish.
  bool get bossBeaten => id.startsWith('after-') || id.startsWith('last-');

  /// Whether the scene ends on the closing caption of a stop that leaves
  /// its chapter unfinished ([StoryLine.endOfStop]): New York's last scene,
  /// until Paris opens.
  bool get endsStop => lines.isNotEmpty && lines.last.endOfStop;
}

/// The campaign's story, told in scenes between flights. See
/// docs/campaign.md.
///
/// Five mail routes fall quiet on the courier's first day. Each boss took
/// its route after a warm letter with a flame seal told it to; the letters
/// came from the Ember Dragon, who lives past the end of every route and
/// has never been sent one himself. The last delivery is the first letter
/// addressed to him.
///
/// Three guardians stand in the way of a chapter's boss: Neferhoo, the
/// Mummy Courier, on Egypt's 2-6, and in New York King Coo on 3-2 and the
/// Searchlight Gargoyle on 3-4. Each has a scene at the lair
/// ([before]) and a last word after its fall ([lastWord]), but no flame seal
/// and no postcard: only a chapter's boss brings those. The Gargoyle's last
/// word closes the stop on a "To be continued…" caption
/// ([StoryScene.endsStop]) until Paris opens.
abstract final class CampaignStory {
  /// The name under the Postmaster's lines.
  static const postmaster = 'Postmaster Bill';

  /// The Sky Club's rule, which opens and closes the story.
  static const motto = 'Every letter lands.';

  /// The scene that comes before [level]: the prologue before 1-1, a
  /// route's opening before its first level, an arrival at the first level
  /// of each later region, and the words at the lair before a boss or a
  /// guardian. Null for every other level.
  static StoryScene? before(CampaignLevel level) => _before[level.id];

  /// The scene after a guardian's fall: its last word at the lair, which
  /// plays on the map once [level] has been beaten for the first time. Null
  /// for every other level (a chapter's boss has [after]).
  static StoryScene? lastWord(CampaignLevel level) => _last[level.id];

  /// The line on each guardian's entrance name card, by level id, without
  /// quotes. It is also the guardian's last word in its lair scene, and
  /// `CampaignLevel.bossLine` in the level data says the same.
  static const guardianLines = <String, String>{
    '2-6': 'Return to sender! This route has a courier.',
    '3-2': 'Nobody flies till the bread cart is found!',
    '3-4': 'Hold still! Nobody ever stays in the light.',
  };

  /// The scene after [chapter]'s boss falls, ahead of its postcard.
  static StoryScene after(CampaignChapter chapter) =>
      _after[chapter.number - 1];

  /// The scene that opens the campaign, on the map's first visit.
  static StoryScene get prologue => _before['1-1']!;

  /// Every scene, in the order the story tells them.
  static final List<StoryScene> scenes = [
    for (final chapter in Campaign.chapters) ...[
      for (final level in chapter.levels) ...[?before(level), ?lastWord(level)],
      after(chapter),
    ],
  ];

  static StoryScene? scene(String id) {
    for (final scene in scenes) {
      if (scene.id == id) return scene;
    }
    return null;
  }

  static const _happy = StoryMood.happy, _sad = StoryMood.sad;
  static const _surprised = StoryMood.surprised, _angry = StoryMood.angry;

  static const _before = <String, StoryScene>{
    // Chapter 1: The Canopy Route.
    '1-1': StoryScene(
      id: 'before-1-1',
      lines: [
        StoryLine.caption('The Sky Club post. Sunrise. Your first day.'),
        StoryLine.bill(
          'There you are, rookie! Postmaster Bill. Welcome to the Sky Club '
          'post.',
          _happy,
        ),
        StoryLine.courier('Ready to fly! Where does the mail go?', _happy),
        StoryLine.bill(
          'Everywhere. That’s the trouble. All five routes went quiet last '
          'night.',
          _sad,
        ),
        StoryLine.bill(
          'Somebody has moved in on every one of them, and my couriers '
          'can’t get through.',
        ),
        StoryLine.courier('Who would steal a mail route?', _surprised),
        StoryLine.bill(
          'Five somebodies. The nearest roosts in the jungle and calls '
          'himself a Baron.',
        ),
        StoryLine.bill(
          'Start small: one birthday card, one jungle. Club rule: every '
          'letter lands.',
          _happy,
        ),
        StoryLine.courier('Every letter lands. Got it!', _happy),
      ],
    ),
    '1-4': StoryScene(
      id: 'before-1-4',
      region: WorldRegion.brazil,
      lines: [
        StoryLine.bill(
          'Brazil! It’s carnival week, so half the mail is confetti.',
          _happy,
        ),
        StoryLine.courier('And the other half?'),
        StoryLine.bill(
          'Bats. The Baron’s cousins never miss a party. Keep your beak up.',
        ),
        StoryLine.bill(
          'And mind the petal gates. They open and shut to the music.',
        ),
      ],
    ),
    '1-6': StoryScene(
      id: 'before-1-6',
      region: WorldRegion.aztec,
      lines: [
        StoryLine.bill(
          'The temple steps. The Baron roosts at the top, where the sun '
          'comes up.',
        ),
        StoryLine.courier('He took a whole route just to roost?', _surprised),
        StoryLine.bill(
          'He says the morning post wakes him. His bedtime is our rush hour.',
        ),
        StoryLine.courier('Then we knock politely. With rocks.', _happy),
      ],
    ),
    '1-8': StoryScene(
      id: 'before-1-8',
      region: WorldRegion.aztec,
      boss: BossKind.baronBat,
      lines: [
        StoryLine.boss('WHO is flapping on my doorstep at sunrise?', _angry),
        StoryLine.courier(
          'Sky Club post! I have a letter for you, sir.',
          _happy,
        ),
        StoryLine.boss('A letter? For me? …What does it say?', _surprised),
        StoryLine.courier('Final notice. You’re roosting on a mail route.'),
        StoryLine.boss('This route is my roost now, little courier!', _angry),
        StoryLine.bill(
          'He’s all screech, rookie. Dodge the fireballs and shoot back!',
        ),
      ],
    ),

    // Chapter 2: The Ancient Road.
    '2-1': StoryScene(
      id: 'before-2-1',
      region: WorldRegion.rome,
      lines: [
        StoryLine.bill(
          'The ancient road: Rome to the desert bazaars. The oldest route on '
          'the map.',
        ),
        StoryLine.courier('What is that smell?', _surprised),
        StoryLine.bill(
          'Brewing. A beetle who calls himself King is boiling our letters.',
          _sad,
        ),
        StoryLine.bill(
          'And look what the Baron left behind: a scorched envelope with a '
          'flame seal.',
        ),
        StoryLine.courier('So somebody is giving our routes away.'),
        StoryLine.bill(
          'One mystery at a time. His beetles spit seeds, so shoot them '
          'down.',
        ),
      ],
    ),
    '2-4': StoryScene(
      id: 'before-2-4',
      region: WorldRegion.egypt,
      lines: [
        StoryLine.bill(
          'Egypt! We’ve delivered here for four thousand years and lost one '
          'letter.',
          _happy,
        ),
        StoryLine.courier('Which one?'),
        StoryLine.bill(
          'The Sphinx won’t say. Mind the switchbacks: up one gap, down the '
          'next.',
        ),
      ],
    ),
    // Egypt's guardian (rules version 50): Neferhoo, the Mummy Courier,
    // who pays off "lost one letter… The Sphinx won't say" (before-2-4). The
    // seventh line is his name-card line (`guardianLines`, the flight's
    // `neferhoo-card` pool plays clip `before-2-6-7`); Bill closes on the tip.
    '2-6': StoryScene(
      id: 'before-2-6',
      region: WorldRegion.egypt,
      boss: BossKind.neferhoo,
      lines: [
        StoryLine.bill(
          'One feather duster for the pyramid caretaker. She says the dust '
          'talks back.',
        ),
        StoryLine.boss(
          'HALT! No courier flies the Pharaoh’s post but me!',
          _angry,
        ),
        StoryLine.courier('A mummy? With a mailbag?', _surprised),
        StoryLine.boss(
          'Neferhoo, Royal Courier. Four thousand years on this route.',
          _happy,
        ),
        StoryLine.boss(
          'One letter left in my bag… and I cannot find its door.',
          _sad,
        ),
        StoryLine.courier('Bill… is that the letter we lost?', _surprised),
        StoryLine.bill(
          'No flame seal on this guardian. Just a very old, very stubborn '
          'postman.',
        ),
        StoryLine.boss('Return to sender! This route has a courier.', _angry),
        StoryLine.bill(
          'Shoot his letters back, rookie. And mind the ankh: it comes back!',
        ),
      ],
    ),
    // Ancient Arabia's arrival and the Spitter King's lair: 2-6 and 2-8
    // until Egypt's guardian took 2-6 (see CampaignIds; the scene ids, the
    // saves that watched them and their clips moved with the levels).
    '2-7': StoryScene(
      id: 'before-2-7',
      region: WorldRegion.arabia,
      lines: [
        StoryLine.bill(
          'The bazaar at dawn. You can smell the King’s brew from here.',
        ),
        StoryLine.courier('What does he want with letters?'),
        StoryLine.bill(
          'Ink, they say. He boils the words right off the page.',
          _sad,
        ),
        StoryLine.courier('Not on my route.', _angry),
      ],
    ),
    '2-9': StoryScene(
      id: 'before-2-9',
      region: WorldRegion.arabia,
      boss: BossKind.spitterBeetle,
      lines: [
        StoryLine.boss(
          'A courier! Splendid. Is that fresh mail I smell?',
          _happy,
        ),
        StoryLine.courier(
          'One letter, and it’s for you. It says: stop boiling the post.',
        ),
        StoryLine.boss(
          'But the recipe! One “Dear Grandma”, two “Wish you were here”, '
          'stir…',
        ),
        StoryLine.courier('You’re cooking people’s words?', _surprised),
        StoryLine.boss('Every letter on my road goes in the brew!', _angry),
        StoryLine.bill(
          'Shoot the seeds down, rookie. And don’t drink anything!',
        ),
      ],
    ),

    // Chapter 3: The Lamplight Line.
    '3-1': StoryScene(
      id: 'before-3-1',
      region: WorldRegion.newYork,
      lines: [
        StoryLine.bill(
          'New York, and not one lamp lit. The night mail can’t find a '
          'single door.',
          _sad,
        ),
        StoryLine.courier('Who puts a whole city to bed?', _surprised),
        StoryLine.bill(
          'The Dusk Empress. Her moths fire pollen in fans of three.',
        ),
        StoryLine.courier('And the flame seal?'),
        StoryLine.bill('I’d bet my cap she has one. Fly by starlight, rookie.'),
      ],
    ),
    '3-2': StoryScene(
      id: 'before-3-2',
      region: WorldRegion.newYork,
      boss: BossKind.kingCoo,
      lines: [
        StoryLine.boss(
          'HALT! By order of the Commissioner, nothing with wheels or wings '
          'passes!',
          _angry,
        ),
        StoryLine.courier(
          'Sky Club post! Umbrellas for the newsstand pigeons.',
          _happy,
        ),
        StoryLine.boss(
          'Umbrellas? A likely story! You’re the one who moved my bread '
          'cart!',
          _angry,
        ),
        StoryLine.courier('Your bread cart?', _surprised),
        StoryLine.boss(
          'Every night, same corner, same crumbs. Tonight: not a crumb, only '
          'wheel tracks.',
          _sad,
        ),
        StoryLine.bill(
          'No flame seal on this guardian. Just a hungry pigeon and his '
          'star-grabbing gang.',
        ),
        StoryLine.boss('Nobody flies till the bread cart is found!', _angry),
        StoryLine.bill(
          'Shoot him when he puffs up to whistle. Dodge stale crumb bombs, fly '
          'the open lane!',
        ),
      ],
    ),
    '3-4': StoryScene(
      id: 'before-3-4',
      region: WorldRegion.newYork,
      boss: BossKind.searchlightGargoyle,
      lines: [
        StoryLine.bill(
          'The tower keeper says something up on the ledge shines lights at '
          'the night mail.',
        ),
        StoryLine.boss(
          'A visitor! Step into the light, darling, let me look at you!',
          _happy,
        ),
        StoryLine.courier(
          'Sky Club post! We have the tower’s weather vane. Please stop '
          'shining that at us.',
        ),
        StoryLine.boss(
          'Ninety-odd years on this ledge. Everyone admires the skyline. '
          'Nobody looks up.',
          _sad,
        ),
        StoryLine.boss('Hold still! Nobody ever stays in the light.', _angry),
        StoryLine.bill(
          'Stay in the dark, rookie, and shoot when his lamp opens. Don’t '
          'mention pigeons.',
        ),
      ],
    ),
    '3-5': StoryScene(
      id: 'before-3-5',
      region: WorldRegion.paris,
      lines: [
        StoryLine.bill(
          'Paris, the City of Light. Or it was, until last night.',
        ),
        StoryLine.courier('The rooftops look like crystal!', _happy),
        StoryLine.bill(
          'They are. Steps of it, three at a time. Pretty, and very pointy.',
        ),
      ],
    ),
    '3-8': StoryScene(
      id: 'before-3-8',
      region: WorldRegion.paris,
      boss: BossKind.duskMoth,
      lines: [
        StoryLine.boss('Shh. You will wake the lamps.'),
        StoryLine.courier('That’s the idea. The night mail can’t see a thing.'),
        StoryLine.boss(
          'My moths kept bumping into them. Bonk. Bonk. All night long.',
          _sad,
        ),
        StoryLine.courier(
          'So you put the lamps to bed? We could just add lampshades…',
        ),
        StoryLine.boss('Hush now. The night mail is sleeping.', _angry),
        StoryLine.bill('Here come the fans, rookie. Slip between them!'),
      ],
    ),

    // Chapter 4: The Tide Route.
    '4-1': StoryScene(
      id: 'before-4-1',
      region: WorldRegion.mexico,
      lines: [
        StoryLine.bill(
          'The tide route. Harbour bells ring when the post comes in. None '
          'has rung all week.',
          _sad,
        ),
        StoryLine.courier('Pirates?'),
        StoryLine.bill(
          'One pirate, one parrot, and every mailbag between here and the '
          'horizon.',
        ),
        StoryLine.bill('Volcanoes first, then open water. Stay dry, rookie.'),
      ],
    ),
    '4-4': StoryScene(
      id: 'before-4-4',
      region: WorldRegion.sea,
      lines: [
        StoryLine.bill('Open water. Nowhere to land, and the sea bites.'),
        StoryLine.courier('What does a pirate want with mailbags?'),
        StoryLine.bill(
          'That’s the odd part. He throws the letters back and keeps the '
          'envelopes.',
        ),
        StoryLine.courier('The envelopes?', _surprised),
        StoryLine.bill(
          'Ask him when you meet him. Until then, don’t touch the water.',
        ),
      ],
    ),
    '4-8': StoryScene(
      id: 'before-4-8',
      region: WorldRegion.sea,
      boss: BossKind.pirate,
      lines: [
        StoryLine.boss(
          'Ahoy! A mailbag, flyin’ itself straight to me ship!',
          _happy,
        ),
        StoryLine.courier(
          'It’s staying with me. What do you want with the mail?',
        ),
        StoryLine.boss(
          'Not the mail, lad. The STAMPS. Tiny paper treasure from every '
          'port!',
        ),
        StoryLine.courier('You’re a stamp collector?', _surprised),
        StoryLine.boss('Arr! Every mailbag on these waves be mine!', _angry),
        StoryLine.bill('Mind the cannon, rookie, and stay out of the water!'),
      ],
    ),

    // Chapter 5: The Edge of the Map.
    '5-1': StoryScene(
      id: 'before-5-1',
      region: WorldRegion.antarctica,
      lines: [
        StoryLine.bill('The edge of the map. No route has ever run past here.'),
        StoryLine.courier('Then who lives out there?'),
        StoryLine.bill(
          'Somebody who has never been sent a letter. I checked the books '
          'twice.',
          _sad,
        ),
        StoryLine.courier(
          'The dragon wrote to four strangers, and nobody ever wrote to him.',
        ),
        StoryLine.bill(
          'Then we had better write one. You fly. I’ll find a pen.',
          _happy,
        ),
      ],
    ),
    '5-3': StoryScene(
      id: 'before-5-3',
      region: WorldRegion.cyberpunk,
      lines: [
        StoryLine.bill('The neon city. Everything here is sent by wire.'),
        StoryLine.courier('So nobody needs a courier?'),
        StoryLine.bill(
          'A wire can’t carry a parcel, rookie. Or a hug. Or noodles.',
          _happy,
        ),
      ],
    ),
    '5-6': StoryScene(
      id: 'before-5-6',
      region: WorldRegion.china,
      lines: [
        StoryLine.bill(
          'Red sun, red sky. His lair is just beyond those mountains.',
        ),
        StoryLine.courier('I have the letter. Everybody signed it.'),
        StoryLine.bill(
          'Even the Baron. He dotted his “i” with a tiny bat.',
          _happy,
        ),
        StoryLine.courier(motto, _happy),
      ],
    ),
    '5-8': StoryScene(
      id: 'before-5-8',
      region: WorldRegion.china,
      boss: BossKind.dragon,
      lines: [
        StoryLine.boss('A courier, at the edge of the map. How unusual.'),
        StoryLine.courier('You sent four letters. You gave our routes away.'),
        StoryLine.boss(
          'No route ever reached ME. If the mail can’t find me, let it find '
          'no one!',
          _angry,
        ),
        StoryLine.courier('Wait! I have something for you…', _surprised),
        StoryLine.boss('The sky is mine. Your letters are kindling.', _angry),
        StoryLine.bill(
          'He won’t listen yet. Get through the fire first, rookie!',
        ),
      ],
    ),
  };

  /// A guardian's last word, after its fall (see [lastWord]). The ids start
  /// with `last-` so that their clips (`last-3-2-0`, …) cannot be taken for
  /// a line of `after-3`.
  static const _last = <String, StoryScene>{
    // Neferhoo's last word. His fall is the reveal: the mask that hid the
    // door comes off, so he opens surprised (not sad), and the scene ends on
    // him taking the job and on the Sphinx's note, read aloud in the voice
    // of its writer, after Bill's offer (campaign_story_test says why).
    '2-6': StoryScene(
      id: 'last-2-6',
      region: WorldRegion.egypt,
      boss: BossKind.neferhoo,
      lines: [
        StoryLine.boss('My mask! …Oh. Oh my. I can see!', _surprised),
        StoryLine.courier('Sir, who is your last letter for?'),
        StoryLine.boss(
          '“To the Sphinx, Giza.” …It was right outside the whole time.',
          _surprised,
        ),
        StoryLine.bill(
          'So that’s the letter we lost! The Sphinx was too polite to '
          'complain.',
          _happy,
        ),
        StoryLine.boss(
          'Four thousand years late. Not my finest delivery.',
          _sad,
        ),
        StoryLine.courier('It still counts. Every letter lands!', _happy),
        StoryLine.bill(
          'Neferhoo, the club needs a Keeper of Lost Letters. Care to apply?',
          _happy,
        ),
        StoryLine.boss(
          'Lost letters? …Then I start with this one. Off to the Sphinx!',
          _happy,
        ),
        StoryLine.caption(
          '“Delivered at last. Worth the wait. Signed: the Sphinx.”',
        ),
      ],
    ),
    '3-2': StoryScene(
      id: 'last-3-2',
      region: WorldRegion.newYork,
      boss: BossKind.kingCoo,
      lines: [
        StoryLine.boss(
          'My cap! …It was the only thing that made them listen.',
          _sad,
        ),
        StoryLine.courier(
          'Commissioner, I remember a bread cart under the theatre marquee, '
          'out of the rain.',
        ),
        StoryLine.boss(
          'The marquee? It was under the marquee. Out of the rain. All night.',
          _surprised,
        ),
        StoryLine.courier(
          'Nobody stole it, sir. It just wanted to stay dry.',
          _happy,
        ),
        StoryLine.boss(
          'And I closed the whole sky. …I may have overreacted.',
          _sad,
        ),
        StoryLine.bill(
          'Our pigeonholes have never had a pigeon. Commissioner wanted. Pay: a '
          'hot bagel a day.',
          _happy,
        ),
        StoryLine.boss('A bagel a day? …The Commissioner accepts.', _happy),
        StoryLine.bill(
          'Next, rookie: Steam Alley. Vents hiss before they burst. Every '
          'letter lands!',
          _happy,
        ),
      ],
    ),
    '3-4': StoryScene(
      id: 'last-3-4',
      region: WorldRegion.newYork,
      boss: BossKind.searchlightGargoyle,
      lines: [
        StoryLine.boss(
          'Ah, the curtain falls. …You chipped my beak. It was my best '
          'feature.',
          _sad,
        ),
        StoryLine.courier(
          'Sorry! I couldn’t look away. And look: the tower’s new weather vane '
          'is spinning.',
        ),
        StoryLine.boss('You looked. That’s all I ever wanted.', _happy),
        StoryLine.bill(
          'Stoneface, the night mail needs a landing light. Every courier will '
          'look up!',
          _happy,
        ),
        StoryLine.boss(
          'A nightly audience! …Darling, I was born for this. The Gargoyle '
          'accepts.',
          _happy,
        ),
        StoryLine.bill(
          'Welcome to the club, Stoneface. And yes, the pigeons may stay.',
          _happy,
        ),
        StoryLine.endOfStop(
          'To be continued… Next stop: Paris, the City of Light.',
        ),
      ],
    ),
  };

  static const _after = [
    StoryScene(
      id: 'after-1',
      region: WorldRegion.aztec,
      boss: BossKind.baronBat,
      lines: [
        StoryLine.boss('My crown! …Oh, keep it. It always pinched.', _sad),
        StoryLine.courier('Why did you take the route, Baron?'),
        StoryLine.boss(
          'Every dawn: flap, thump, “POST!” A bat needs his beauty sleep.',
          _sad,
        ),
        StoryLine.boss(
          'Then a letter came, warm as toast. “The canopy is yours. Take it.”',
        ),
        StoryLine.courier('Who sent it?', _surprised),
        StoryLine.boss('No name. Only a seal shaped like a flame.'),
        StoryLine.bill(
          'Tell you what, Baron. From now on, we deliver the canopy at dusk.',
          _happy,
        ),
        StoryLine.boss('Dusk! How civilised. …You may go.', _happy),
      ],
    ),
    StoryScene(
      id: 'after-2',
      region: WorldRegion.arabia,
      boss: BossKind.spitterBeetle,
      lines: [
        StoryLine.boss('My brew! It has gone all… minty.', _sad),
        StoryLine.courier('What were you making?'),
        StoryLine.boss(
          'The perfect ink. One that never fades. I only needed a few '
          'thousand letters.',
        ),
        StoryLine.courier('Did a warm letter tell you the road was yours?'),
        StoryLine.boss('With a flame seal! How did you know?', _surprised),
        StoryLine.bill(
          'Two routes, two seals. Somebody is writing to every troublemaker '
          'on the map.',
        ),
        StoryLine.bill(
          'King, the club needs an ink-maker. No boiling the post. Tea is '
          'allowed.',
          _happy,
        ),
        StoryLine.boss('Royal ink-maker! I shall need a bigger flask.', _happy),
      ],
    ),
    StoryScene(
      id: 'after-3',
      region: WorldRegion.paris,
      boss: BossKind.duskMoth,
      lines: [
        StoryLine.boss('My crown has slipped. How very undignified.', _sad),
        StoryLine.courier(
          'Empress, did you get a warm letter with a flame seal?',
        ),
        StoryLine.boss(
          'It promised me a city without lamps. It did not mention couriers.',
        ),
        StoryLine.bill(
          'Three seals now. And every one posted from the edge of the map.',
        ),
        StoryLine.courier(
          'About those lampshades. Soft ones. Would they help?',
          _happy,
        ),
        StoryLine.boss(
          'Shades… Yes. And I shall light the lamps myself, each dusk.',
          _happy,
        ),
      ],
    ),
    StoryScene(
      id: 'after-4',
      region: WorldRegion.sea,
      boss: BossKind.pirate,
      lines: [
        StoryLine.boss('Me hat! Me ship! Me stamp album… it’s soggy.', _sad),
        StoryLine.courier('Let me guess. A warm letter. A flame seal.'),
        StoryLine.boss(
          'Aye. “The tide is yours,” it said. Fine stamp on it, too: a little '
          'dragon.',
        ),
        StoryLine.bill('A dragon! At the edge of the map…', _surprised),
        StoryLine.courier(
          'Captain, give the mail back and the club will send you a stamp '
          'from every route.',
        ),
        StoryLine.boss(
          'Every route? …Parrot, strike the colours. We be collectors now!',
          _happy,
        ),
      ],
    ),
    StoryScene(
      id: 'after-5',
      region: WorldRegion.china,
      boss: BossKind.dragon,
      lines: [
        StoryLine.boss('Enough. I yield. Burn your own letters.', _sad),
        StoryLine.courier('This one isn’t for burning. It’s addressed to you.'),
        StoryLine.boss(
          '“The Ember Dragon, Edge of the Map.” That… is me.',
          _surprised,
        ),
        StoryLine.caption(
          '“Dear Dragon. The Sky Club has a new route, and no one to light '
          'the way.”',
        ),
        StoryLine.caption(
          '“Come and keep our beacon. Signed: everyone. Even the Baron.”',
        ),
        StoryLine.boss(
          'I wrote four letters, to feel part of the mail. This is the first '
          'one back.',
          _sad,
        ),
        StoryLine.bill(
          'Route six, Dragon: the Edge of the Map. You light it. We deliver '
          'it.',
          _happy,
        ),
        StoryLine.boss('Then I had better learn to write back.', _happy),
        StoryLine.courier(motto, _happy),
      ],
    ),
  ];
}
