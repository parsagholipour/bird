import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/campaign.dart';
import '../domain/campaign_story.dart';
import '../domain/tutorial_story.dart';
import '../game/campaign_voices.dart';
import 'app_language.dart';
import 'pseudo.dart';

/// The story's words in one language: every scene line and thank-you note,
/// by its voice clip's name (docs/story-voices-sources.json), so a caption
/// and its recording always belong to the same clip.
///
/// The English words stay in the domain ([StoryLine.text],
/// [Delivery.thanks]) and are the fallback for any clip a language has not
/// translated. A language's captions ship in the base bundle (they are text,
/// not voice) as `assets/l10n/story/<slug>.json`: a flat
/// `{"<clip>": "<caption>"}` object written by `tool/l10n/build_captions.py`
/// from the translators' `l10n-ws/voice/<slug>/story.json`. Keys starting
/// with `@@` are metadata.
///
/// A courier's line has a clip per bird (`<scene>-<line>-<bird>`), so a
/// language whose grammar changes with the speaker can word each bird's
/// line its own way; a missing bird falls back to any other bird's caption,
/// then to English.
@immutable
class StoryCaptions {
  const StoryCaptions._(this.language, this._texts);

  /// No translations: every caption is the English line.
  static const english = StoryCaptions._(AppLanguage.en, {});

  /// Where a language's captions live in the bundle.
  static String assetFor(AppLanguage language) =>
      'assets/l10n/story/${language.slug}.json';

  /// The languages whose captions are bundled (`index.json`).
  static const indexAsset = 'assets/l10n/story/index.json';

  final AppLanguage language;
  final Map<String, String> _texts;

  /// How many clips this language has words for.
  int get length => _texts.length;

  /// Captions from a decoded asset ([assetFor]).
  factory StoryCaptions.fromJson(AppLanguage language, String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return StoryCaptions._(language, {
      for (final MapEntry(:key, :value) in decoded.entries)
        if (!key.startsWith('@@') && value is String && value.isNotEmpty)
          key: value,
    });
  }

  /// Captions from a plain map, for tests and tools.
  factory StoryCaptions.of(AppLanguage language, Map<String, String> texts) =>
      StoryCaptions._(language, Map.unmodifiable(texts));

  /// Every English line and thank-you, pseudo-localized ([pseudoLocalize]):
  /// the story's longest-case stand-in before translations exist.
  factory StoryCaptions.pseudo() => StoryCaptions._(AppLanguage.en, {
    for (final scene in [...TutorialStory.scenes, ...CampaignStory.scenes])
      for (var i = 0; i < scene.lines.length; i++)
        for (final name in CampaignVoices.lineNames(scene, i))
          name: pseudoLocalize(scene.lines[i].text),
    for (final level in Campaign.levels)
      CampaignVoices.thanksName(level): pseudoLocalize(level.delivery.thanks),
  });

  /// Loads [language]'s captions, or [english] when it has none bundled
  /// (English itself, or a language still being translated).
  static Future<StoryCaptions> load(
    AppLanguage language, {
    AssetBundle? bundle,
  }) async {
    if (language == AppLanguage.en) return english;
    final assets = bundle ?? rootBundle;
    try {
      final index =
          jsonDecode(await assets.loadString(indexAsset))
              as Map<String, dynamic>;
      final bundled = (index['languages'] as List?)?.cast<String>() ?? [];
      if (!bundled.contains(language.slug)) return english;
      return StoryCaptions.fromJson(
        language,
        await assets.loadString(assetFor(language), cache: false),
      );
    } catch (error) {
      debugPrint('Story captions for ${language.tag}: $error');
      return english;
    }
  }

  /// The words of clip [name], or [english] when it has none.
  String clip(String name, String english) => _texts[name] ?? english;

  /// Line [index] of [scene] as [bird] hears it.
  String line(StoryScene scene, int index, {required int bird}) {
    final own = _texts[CampaignVoices.lineName(scene, index, bird: bird)];
    if (own != null) return own;
    for (final name in CampaignVoices.lineNames(scene, index)) {
      final other = _texts[name];
      if (other != null) return other;
    }
    return scene.lines[index].text;
  }

  /// [level]'s thank-you note.
  String thanks(CampaignLevel level) =>
      clip(CampaignVoices.thanksName(level), level.delivery.thanks);
}
