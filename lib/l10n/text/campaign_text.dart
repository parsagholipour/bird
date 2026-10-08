import '../../domain/campaign.dart';
import '../../domain/campaign_story.dart';
import '../generated/app_localizations.dart';
import '../l10n.dart' show L10n;

/// The campaign's data text (owner: slice S1, MASTER-PLAN.md "Domain
/// data"): level names, cargo, senders and hints, route names and the
/// chapter postcards, as ARB keys (`level_1_1_name`, `chapter_1_route`, ...).
///
/// The domain keeps the ids and their English as the English twins
/// ([CampaignLevel.name], [Delivery.cargo], [CampaignChapter.route], ...),
/// which tests, logs and tools still read; test/l10n_campaign_test.dart keeps
/// the English ARB equal to them. A level or chapter whose English differs
/// from the catalog's (a test's own, even under a catalog id) shows its own
/// words.
///
/// The story's lines and the thank-you notes are not here: they are
/// captions, keyed by voice clip ([StoryCaptions]). The boss lines are the
/// one place both meet, and [bossLine] reads them from the captions, so the
/// name card and the lair scene always say the same words.
extension CampaignText on AppLocalizations {
  /// "First Delivery".
  String levelName(CampaignLevel level) => _catalog(level)?.name != level.name
      ? level.name
      : switch (level.id) {
          '1-1' => level_1_1_name,
          '1-2' => level_1_2_name,
          '1-3' => level_1_3_name,
          '1-4' => level_1_4_name,
          '1-5' => level_1_5_name,
          '1-6' => level_1_6_name,
          '1-7' => level_1_7_name,
          '1-8' => level_1_8_name,
          '2-1' => level_2_1_name,
          '2-2' => level_2_2_name,
          '2-3' => level_2_3_name,
          '2-4' => level_2_4_name,
          '2-5' => level_2_5_name,
          '2-6' => level_2_6_name,
          '2-7' => level_2_7_name,
          '2-8' => level_2_8_name,
          '2-9' => level_2_9_name,
          '3-1' => level_3_1_name,
          '3-2' => level_3_2_name,
          '3-3' => level_3_3_name,
          '3-4' => level_3_4_name,
          '3-5' => level_3_5_name,
          '3-6' => level_3_6_name,
          '3-7' => level_3_7_name,
          '3-8' => level_3_8_name,
          '4-1' => level_4_1_name,
          '4-2' => level_4_2_name,
          '4-3' => level_4_3_name,
          '4-4' => level_4_4_name,
          '4-5' => level_4_5_name,
          '4-6' => level_4_6_name,
          '4-7' => level_4_7_name,
          '4-8' => level_4_8_name,
          '5-1' => level_5_1_name,
          '5-2' => level_5_2_name,
          '5-3' => level_5_3_name,
          '5-4' => level_5_4_name,
          '5-5' => level_5_5_name,
          '5-6' => level_5_6_name,
          '5-7' => level_5_7_name,
          '5-8' => level_5_8_name,
          _ => level.name,
        };

  /// "A birthday card for the toucan twins".
  String levelCargo(CampaignLevel level) =>
      _catalog(level)?.delivery.cargo != level.delivery.cargo
      ? level.delivery.cargo
      : switch (level.id) {
          '1-1' => level_1_1_cargo,
          '1-2' => level_1_2_cargo,
          '1-3' => level_1_3_cargo,
          '1-4' => level_1_4_cargo,
          '1-5' => level_1_5_cargo,
          '1-6' => level_1_6_cargo,
          '1-7' => level_1_7_cargo,
          '1-8' => level_1_8_cargo,
          '2-1' => level_2_1_cargo,
          '2-2' => level_2_2_cargo,
          '2-3' => level_2_3_cargo,
          '2-4' => level_2_4_cargo,
          '2-5' => level_2_5_cargo,
          '2-6' => level_2_6_cargo,
          '2-7' => level_2_7_cargo,
          '2-8' => level_2_8_cargo,
          '2-9' => level_2_9_cargo,
          '3-1' => level_3_1_cargo,
          '3-2' => level_3_2_cargo,
          '3-3' => level_3_3_cargo,
          '3-4' => level_3_4_cargo,
          '3-5' => level_3_5_cargo,
          '3-6' => level_3_6_cargo,
          '3-7' => level_3_7_cargo,
          '3-8' => level_3_8_cargo,
          '4-1' => level_4_1_cargo,
          '4-2' => level_4_2_cargo,
          '4-3' => level_4_3_cargo,
          '4-4' => level_4_4_cargo,
          '4-5' => level_4_5_cargo,
          '4-6' => level_4_6_cargo,
          '4-7' => level_4_7_cargo,
          '4-8' => level_4_8_cargo,
          '5-1' => level_5_1_cargo,
          '5-2' => level_5_2_cargo,
          '5-3' => level_5_3_cargo,
          '5-4' => level_5_4_cargo,
          '5-5' => level_5_5_cargo,
          '5-6' => level_5_6_cargo,
          '5-7' => level_5_7_cargo,
          '5-8' => level_5_8_cargo,
          _ => level.delivery.cargo,
        };

  /// Who signs the thank-you: "The toucan twins".
  String levelSender(CampaignLevel level) =>
      _catalog(level)?.delivery.from != level.delivery.from
      ? level.delivery.from
      : switch (level.id) {
          '1-1' => level_1_1_sender,
          '1-2' => level_1_2_sender,
          '1-3' => level_1_3_sender,
          '1-4' => level_1_4_sender,
          '1-5' => level_1_5_sender,
          '1-6' => level_1_6_sender,
          '1-7' => level_1_7_sender,
          '1-8' => level_1_8_sender,
          '2-1' => level_2_1_sender,
          '2-2' => level_2_2_sender,
          '2-3' => level_2_3_sender,
          '2-4' => level_2_4_sender,
          '2-5' => level_2_5_sender,
          '2-6' => level_2_6_sender,
          '2-7' => level_2_7_sender,
          '2-8' => level_2_8_sender,
          '2-9' => level_2_9_sender,
          '3-1' => level_3_1_sender,
          '3-2' => level_3_2_sender,
          '3-3' => level_3_3_sender,
          '3-4' => level_3_4_sender,
          '3-5' => level_3_5_sender,
          '3-6' => level_3_6_sender,
          '3-7' => level_3_7_sender,
          '3-8' => level_3_8_sender,
          '4-1' => level_4_1_sender,
          '4-2' => level_4_2_sender,
          '4-3' => level_4_3_sender,
          '4-4' => level_4_4_sender,
          '4-5' => level_4_5_sender,
          '4-6' => level_4_6_sender,
          '4-7' => level_4_7_sender,
          '4-8' => level_4_8_sender,
          '5-1' => level_5_1_sender,
          '5-2' => level_5_2_sender,
          '5-3' => level_5_3_sender,
          '5-4' => level_5_4_sender,
          '5-5' => level_5_5_sender,
          '5-6' => level_5_6_sender,
          '5-7' => level_5_7_sender,
          '5-8' => level_5_8_sender,
          _ => level.delivery.from,
        };

  /// The intro card's hint, if any.
  String? levelHint(CampaignLevel level) =>
      level.hint == null || _catalog(level)?.hint != level.hint
      ? level.hint
      : switch (level.id) {
          '1-1' => level_1_1_hint,
          '1-2' => level_1_2_hint,
          '1-3' => level_1_3_hint,
          '1-4' => level_1_4_hint,
          '1-5' => level_1_5_hint,
          '2-1' => level_2_1_hint,
          '2-2' => level_2_2_hint,
          '2-3' => level_2_3_hint,
          '2-5' => level_2_5_hint,
          '2-6' => level_2_6_hint,
          '3-1' => level_3_1_hint,
          '3-2' => level_3_2_hint,
          '3-3' => level_3_3_hint,
          '3-4' => level_3_4_hint,
          '3-6' => level_3_6_hint,
          '3-7' => level_3_7_hint,
          '4-2' => level_4_2_hint,
          '4-4' => level_4_4_hint,
          '4-5' => level_4_5_hint,
          '5-1' => level_5_1_hint,
          _ => level.hint,
        };

  /// "The Canopy Route".
  String chapterRoute(CampaignChapter chapter) =>
      _chapter(chapter)?.route != chapter.route
      ? chapter.route
      : switch (chapter.number) {
          1 => chapter_1_route,
          2 => chapter_2_route,
          3 => chapter_3_route,
          4 => chapter_4_route,
          5 => chapter_5_route,
          _ => chapter.route,
        };

  /// The route as the postcard's postmark prints it: "CANOPY ROUTE".
  String chapterPostmark(CampaignChapter chapter) =>
      _chapter(chapter)?.route != chapter.route
      ? L10n.upper(chapter.route)
      : switch (chapter.number) {
          1 => chapter_1_postmark,
          2 => chapter_2_postmark,
          3 => chapter_3_postmark,
          4 => chapter_4_postmark,
          5 => chapter_5_postmark,
          _ => L10n.upper(chapter.route),
        };

  /// The boss's line on its entrance name card, without quotes: the
  /// caption of the same words in its lair scene ([CampaignStory.before]),
  /// so the card and the scene always agree; English until the current
  /// language's captions are loaded ([L10n.captions]). Null for a level
  /// without a boss.
  String? bossLine(CampaignLevel level) {
    final english = Campaign.bossLine(level);
    if (english == null) return null;
    final scene = CampaignStory.before(level);
    if (scene == null) return english;
    for (var i = 0; i < scene.lines.length; i++) {
      final line = scene.lines[i];
      if (line.speaker == StorySpeaker.boss && line.text == english) {
        return L10n.captions.line(scene, i, bird: 0);
      }
    }
    return english;
  }

  /// The message on [chapter]'s postcard, after its greeting
  /// ([campaignPostcardGreeting], "Dear courier,"), which the card writes on
  /// its own line: "Letters are landing in the treetops again! …".
  String chapterPostcard(CampaignChapter chapter) =>
      _chapter(chapter)?.postcard != chapter.postcard
      ? chapter.postcard
      : switch (chapter.number) {
          1 => chapter_1_postcard,
          2 => chapter_2_postcard,
          3 => chapter_3_postcard,
          4 => chapter_4_postcard,
          5 => chapter_5_postcard,
          _ => chapter.postcard,
        };

  /// The postcard's P.S., without its label ([campaignPostcardPs]).
  String chapterPostscript(CampaignChapter chapter) =>
      _chapter(chapter)?.postscript != chapter.postscript
      ? chapter.postscript
      : switch (chapter.number) {
          1 => chapter_1_postscript,
          2 => chapter_2_postscript,
          3 => chapter_3_postscript,
          4 => chapter_4_postscript,
          5 => chapter_5_postscript,
          _ => chapter.postscript,
        };

  /// "Postmaster Bill".
  String get postmasterName => storyPostmasterName;

  /// "Every letter lands."
  String get motto => campaignMotto;

  /// The catalog's level of [level]'s id, whose words the ARB holds.
  static CampaignLevel? _catalog(CampaignLevel level) =>
      Campaign.level(level.id);

  /// The catalog's chapter of [chapter]'s number.
  static CampaignChapter? _chapter(CampaignChapter chapter) =>
      chapter.number >= 1 && chapter.number <= Campaign.chapters.length
      ? Campaign.chapters[chapter.number - 1]
      : null;
}
