import '../domain/campaign.dart';
import '../domain/campaign_story.dart';
import 'campaign_voice_clips.dart';

/// The campaign's recorded voices: every line of the story scenes, each
/// level's thank-you, and each bird's sprint calls, all in
/// assets/audio/story/ (see docs/story-voices.md).
///
/// The courier's lines are recorded once per bird, in that bird's voice.
///
/// A line can be written and not yet recorded ("pending recording" in
/// docs/story-voices-sources.json): the New York guardians' scenes were
/// added that way. Such a clip is not in [campaignVoiceClips], so [line],
/// [thanks] and [sprints] give nothing for it and the game stays silent: the
/// scene still shows its text, paced by the text alone exactly as with
/// Settings → Character voices off. Recording it later changes no code
/// except the generated clip table.
abstract final class CampaignVoices {
  static const _folder = 'audio/story';

  /// The birds' names in clip names, in the order of the birds.
  static const birds = ['pip', 'peaches', 'minty', 'orbit'];

  /// What a bird calls out as it sprints.
  static const _sprints = ['woohoo', 'turbo', 'gravity', 'whee'];

  /// Line [index] of [scene], spoken by its speaker; a courier's line in
  /// [bird]'s voice. Null for a line that is not recorded.
  static String? line(StoryScene scene, int index, {required int bird}) {
    final name = lineName(scene, index, bird: bird);
    return _asset(name);
  }

  /// [level]'s thank-you, in the voice of whoever signs it. Null for one
  /// that is not recorded.
  static String? thanks(CampaignLevel level) => _asset(thanksName(level));

  /// [bird]'s sprint calls, in its own voice, leaving out any that is not
  /// recorded.
  static List<String> sprints(int bird) => [
    for (final name in sprintNames(bird)) ?_asset(name),
  ];

  /// How long [asset] plays, or null for a clip that is not recorded.
  static Duration? length(String asset) {
    final ms = campaignVoiceClips[_name(asset)];
    return ms == null ? null : Duration(milliseconds: ms);
  }

  /// The clip name of line [index] of [scene] for [bird]: `<scene>-<line>`,
  /// with `-<bird>` after it for the courier, who is recorded once per
  /// bird. Recorded or not.
  static String lineName(StoryScene scene, int index, {required int bird}) {
    final base = '${scene.id}-$index';
    return scene.lines[index].speaker == StorySpeaker.courier
        ? '$base-${birds[bird % birds.length]}'
        : base;
  }

  /// Every clip name line [index] of [scene] can have: one, or one for each
  /// bird for a courier's line. Recorded or not.
  static List<String> lineNames(StoryScene scene, int index) => {
    for (var bird = 0; bird < birds.length; bird++)
      lineName(scene, index, bird: bird),
  }.toList();

  /// The clip name of [level]'s thank-you. Recorded or not.
  static String thanksName(CampaignLevel level) => 'thanks-${level.id}';

  /// The clip names of [bird]'s sprint calls. Recorded or not.
  static List<String> sprintNames(int bird) => [
    for (final call in _sprints) 'sprint-${birds[bird % birds.length]}-$call',
  ];

  /// Every clip the game can ask for, recorded or not: the lines of every
  /// scene (a courier's for every bird), every level's thank-you and every
  /// bird's sprint calls. A recording the game has no name for is never
  /// played, and a name without a recording is a pending clip.
  static Set<String> get wanted => {
    for (final scene in CampaignStory.scenes)
      for (var i = 0; i < scene.lines.length; i++) ...lineNames(scene, i),
    for (final level in Campaign.levels) thanksName(level),
    for (var bird = 0; bird < birds.length; bird++) ...sprintNames(bird),
  };

  static String _name(String asset) =>
      asset.substring(asset.lastIndexOf('/') + 1).replaceAll('.ogg', '');

  static String? _asset(String name) =>
      campaignVoiceClips.containsKey(name) ? '$_folder/$name.ogg' : null;
}
