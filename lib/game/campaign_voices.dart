import '../domain/campaign.dart';
import '../domain/campaign_story.dart';
import 'campaign_voice_clips.dart';

/// The campaign's recorded voices: every line of the story scenes, each
/// level's thank-you, and each bird's sprint calls, all in
/// assets/audio/story/ (see docs/story-voices.md).
///
/// The courier's lines are recorded once per bird, in that bird's voice.
/// A clip that has not been recorded gives null, and the game stays silent
/// for it.
abstract final class CampaignVoices {
  static const _folder = 'audio/story';

  /// The birds' names in clip names, in the order of the birds.
  static const birds = ['pip', 'peaches', 'minty', 'orbit'];

  /// What a bird calls out as it sprints.
  static const _sprints = ['woohoo', 'turbo', 'gravity', 'whee'];

  /// Line [index] of [scene], spoken by its speaker; a courier's line in
  /// [bird]'s voice.
  static String? line(StoryScene scene, int index, {required int bird}) {
    final base = '${scene.id}-$index';
    return scene.lines[index].speaker == StorySpeaker.courier
        ? _asset('$base-${birds[bird % birds.length]}')
        : _asset(base);
  }

  /// [level]'s thank-you, in the voice of whoever signs it.
  static String? thanks(CampaignLevel level) => _asset('thanks-${level.id}');

  /// [bird]'s sprint calls, in its own voice.
  static List<String> sprints(int bird) => [
    for (final call in _sprints)
      ?_asset('sprint-${birds[bird % birds.length]}-$call'),
  ];

  /// How long [asset] plays, or null for a clip that is not recorded.
  static Duration? length(String asset) {
    final ms = campaignVoiceClips[_name(asset)];
    return ms == null ? null : Duration(milliseconds: ms);
  }

  static String _name(String asset) =>
      asset.substring(asset.lastIndexOf('/') + 1).replaceAll('.ogg', '');

  static String? _asset(String name) =>
      campaignVoiceClips.containsKey(name) ? '$_folder/$name.ogg' : null;
}
