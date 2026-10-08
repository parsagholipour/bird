import 'campaign_story.dart';
import 'sky_boss.dart' show BossKind;
import 'tutorial.dart';
import 'world_region.dart';

// l10n-english-twin: every line here is the English caption of its voice
// clip, like the campaign's story (campaign_story.dart): a language's words
// come from assets/l10n/story/<slug>.json by clip name.

/// What is said in flight school (docs/tutorial.md): the scene before the
/// lesson, Postmaster Bill's coaching in flight and the scene after the
/// rookie Pirate Captain's retreat. Every line is a voice clip like the
/// campaign's ([CampaignVoices]), named `school-<scene>-<line>` and
/// `coach-<line>-0`, pending recording in docs/story-voices-sources.json
/// until its take exists; a line without a take shows its words alone.
///
/// It comes before the campaign's prologue: the lesson is flown over the
/// Sky Club's bay before sunrise, and Bill sends the new courier inside to
/// the post, where the prologue opens at sunrise.
abstract final class TutorialStory {
  static const _happy = StoryMood.happy, _surprised = StoryMood.surprised;
  static const _angry = StoryMood.angry;

  /// Before the lesson, at the Sky Club post.
  static const intro = StoryScene(
    id: 'school-intro',
    lines: [
      StoryLine.caption('The Sky Club post. Before sunrise.'),
      StoryLine.bill(
        'Morning, rookie! Before you carry a single letter, let’s see you '
        'fly.',
        _happy,
      ),
      StoryLine.courier('Right now? I was born ready!', _happy),
      StoryLine.bill(
        'Ha! Then follow my lead. One short lesson, and the sky is yours.',
      ),
    ],
  );

  /// After the rookie captain sails off, over the bay.
  static const outro = StoryScene(
    id: 'school-outro',
    region: WorldRegion.sea,
    boss: BossKind.pirate,
    beaten: true,
    lines: [
      StoryLine.boss('Arr! Ye sting like a jellyfish, postie!', _angry),
      StoryLine.boss(
        'Keep yer little letters. The open sea be mine, and we’ll meet '
        'again!',
      ),
      StoryLine.bill(
        'The Pirate Captain, raiding my bay! Rookie, you were '
        'magnificent.',
        _surprised,
      ),
      StoryLine.courier('Did I pass? Did I really pass?', _happy),
      StoryLine.bill(
        'With flying colours. Here’s your courier licence. Now, inside: the '
        'mail is waiting!',
        _happy,
      ),
    ],
  );

  /// Bill's coaching in flight, one line per [CoachLine].
  static const _coach = <CoachLine, String>{
    CoachLine.flap: 'Tap anywhere to flap your wings!',
    CoachLine.air:
        'Keep tapping to stay up. Don’t touch the top or the '
        'bottom!',
    CoachLine.stars: 'Stars! Fly right through them.',
    CoachLine.streak: 'A streak! Keep chaining stars to multiply your score.',
    CoachLine.gates: 'Here come the gates. Fly through the gaps!',
    CoachLine.hit:
        'Ouch! A bump breaks your shield first, then costs a '
        'heart.',
    CoachLine.safe: 'Don’t worry, nobody falls in flight school. Keep going!',
    CoachLine.shoot: 'A bat! Tap Shoot to throw a pebble.',
    CoachLine.shootMore: 'Got him! Knock out the others.',
    CoachLine.power: 'A stone door! Hold Shoot to charge, then let go.',
    CoachLine.powerDone: 'Smashed! Charged shots hit hardest.',
    CoachLine.sprint:
        'Now tap Sprint to zoom ahead. It smashes right '
        'through bats!',
    CoachLine.together: 'Now put it all together!',
    CoachLine.heart: 'A heart! Catch it to get one back.',
    CoachLine.pirate:
        'Pirates! Dodge the cannonballs and shoot the '
        'Captain!',
    CoachLine.stronger: 'He’s getting angry. Grab that heart!',
    CoachLine.tide: 'The tide is rising! Fly high!',
    CoachLine.victory: 'You did it! Now that’s a courier!',
  };

  /// [line] as a one-line scene of Bill's, so it is voiced and captioned
  /// the way every story line is: clip `coach-<line>-0`.
  static StoryScene coach(CoachLine line) => _coachScenes[line]!;

  static final _coachScenes = {
    for (final MapEntry(:key, :value) in _coach.entries)
      key: StoryScene(
        id: 'coach-${_slug(key)}',
        lines: [StoryLine.bill(value)],
      ),
  };

  /// `shootMore` → `shoot-more`.
  static String _slug(CoachLine line) => line.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '-${m[0]!.toLowerCase()}',
  );

  /// Every scene flight school plays, in order: the intro, each coach line
  /// and the outro.
  static final List<StoryScene> scenes = [
    intro,
    for (final line in CoachLine.values) coach(line),
    outro,
  ];
}
