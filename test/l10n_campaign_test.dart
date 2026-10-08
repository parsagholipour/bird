// The campaign and its story in other languages (slice S1,
// l10n-ws/MASTER-PLAN.md): the campaign's ARB words stay equal to the
// domain's English twins, the story scenes show each language's captions by
// voice clip (with the bird's own wording and English to fall back on) while
// the scene's own data decides what a line does, the campaign map keeps its
// world left to right under Arabic, and the campaign's screens fit the
// reference phone in the pseudo-locale.
@Timeout(Duration(minutes: 6))
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/campaign_voices.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/pseudo.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/campaign_map.dart';
import 'package:push_up_bird/ui/campaign_postcard.dart';
import 'package:push_up_bird/ui/campaign_screen.dart';
import 'package:push_up_bird/ui/delivery_art.dart';
import 'package:push_up_bird/ui/fit_text.dart';
import 'package:push_up_bird/ui/launch_screen.dart';
import 'package:push_up_bird/ui/level_intro.dart';
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/story_speech.dart';
import 'package:push_up_bird/ui/story_stage.dart';
import 'package:push_up_bird/ui/story_to_be_continued.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'campaign_save_test.dart' show levelRun;

CampaignLevel _level(String id) => Campaign.level(id)!;

final _en = lookupAppLocalizations(const Locale('en'));
final _fr = lookupAppLocalizations(const Locale('fr'));
final _ar = lookupAppLocalizations(const Locale('ar'));

/// Every clip of [scene], captioned `<prefix><clip>`.
Map<String, String> _tagged(StoryScene scene, String prefix) => {
  for (var i = 0; i < scene.lines.length; i++)
    for (final clip in CampaignVoices.lineNames(scene, i)) clip: '$prefix$clip',
};

/// The real campaign screen at 792 × 360 in [language] (or [locale]), every
/// scene and postcard seen, with the levels in [cleared] flown.
Future<void> _pumpMap(
  WidgetTester tester, {
  Map<String, int> cleared = const {},
  AppLanguage language = AppLanguage.ar,
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(792, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, true);
    var n = 0;
    for (final MapEntry(key: id, value: stars) in cleared.entries) {
      await repo.saveRun(
        levelRun(
          'ar-${n++}',
          id,
          stars: stars,
          score: 400,
          at: DateTime(2026, 10, 1, 12, n),
        ),
      );
    }
    for (final scene in CampaignStory.scenes) {
      await repo.markStoryWatched(scene);
    }
    for (final chapter in Campaign.chapters) {
      await repo.markPostcardSeen(chapter);
    }
  });
  final container = ProviderContainer(
    overrides: [progressRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(repo.close);
  });
  L10n.apply(language, locale: locale);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: skyTheme(language),
        locale: locale ?? language.locale,
        supportedLocales: L10n.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const CampaignScreen(),
      ),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  tearDown(L10n.debugReset);

  group('the campaign words: ARB = English twin', () {
    test('every level: name, cargo, sender, hint', () {
      expect(Campaign.levels, hasLength(41));
      for (final level in Campaign.levels) {
        expect(_en.levelName(level), level.name, reason: level.id);
        expect(_en.levelCargo(level), level.delivery.cargo, reason: level.id);
        expect(_en.levelSender(level), level.delivery.from, reason: level.id);
        expect(_en.levelHint(level), level.hint, reason: level.id);
      }
    });

    test('every chapter: route, postmark, postcard, P.S.', () {
      for (final letter in CampaignPostcard.letters) {
        final chapter = letter.chapter;
        expect(_en.chapterRoute(chapter), chapter.route);
        expect(letter.routeIn(_en), letter.route);
        expect(letter.postmarkIn(_en), letter.postmarkName);
        expect(letter.bodyIn(_en), letter.body);
        expect(letter.postscriptIn(_en), letter.postscript);
        // The card writes the greeting and the label itself.
        expect(
          chapter.postcard,
          startsWith('${_en.campaignPostcardGreeting} '),
        );
        expect(chapter.postscript, startsWith('${_en.campaignPostcardPs} '));
      }
    });

    test('the story\'s names and motto, and the boss names', () {
      expect(_en.postmasterName, CampaignStory.postmaster);
      expect(_en.motto, CampaignStory.motto);
      for (final kind in BossKind.values) {
        expect(_en.bossName(kind), CampaignHeadwear.name(kind));
      }
    });

    test('a level the ARB does not know shows its own words', () {
      const level = CampaignLevel(
        name: 'Test Run',
        delivery: Delivery('A test parcel', from: 'Tests', thanks: 'Ta.'),
        hint: 'Just a test.',
        plan: LevelPlan(
          id: '9-9',
          region: WorldRegion.jungle,
          length: 30,
          start: 0,
          seed: 1,
          families: [ObstacleKind.garden],
          marks: StarMarks(1, 2),
        ),
      );
      expect(_en.levelName(level), 'Test Run');
      expect(_en.levelCargo(level), 'A test parcel');
      expect(_en.levelSender(level), 'Tests');
      expect(_en.levelHint(level), 'Just a test.');
    });

    test('the goals and lock notes read as before in English', () {
      expect(LevelIntroCard.goals(_level('1-8')), [
        'Beat Baron Bat',
        'Collect 15 stars',
        'Collect 25 stars',
      ]);
      expect(
        LevelIntroCard.goals(_level('1-1'), _en).first,
        'Reach the finish',
      );
      expect(lockedNudge(_level('3-3'), _en), 'Beat King Coo to unlock');
      expect(lockedNudge(_level('1-2'), _en), 'Finish 1-1 to unlock');
    });
  });

  group('boss lines come from the lair scene\'s captions', () {
    test('English: the name card says the lair line', () {
      final bosses = Campaign.levels.where((l) => l.isBoss).toList();
      expect(bosses, hasLength(8));
      for (final level in bosses) {
        expect(_en.bossLine(level), Campaign.bossLine(level), reason: level.id);
      }
      expect(_en.bossLine(_level('1-1')), isNull);
    });

    test('a language\'s captions word the card the same as the scene', () {
      L10n.apply(AppLanguage.fr);
      L10n.applyCaptions(
        StoryCaptions.of(AppLanguage.fr, {
          for (final scene in CampaignStory.scenes) ..._tagged(scene, 'FR '),
        }),
      );
      final fr = L10n.strings;
      for (final level in Campaign.levels.where((l) => l.isBoss)) {
        final scene = CampaignStory.before(level)!;
        final i = scene.lines.indexWhere(
          (line) =>
              line.speaker == StorySpeaker.boss &&
              line.text == Campaign.bossLine(level),
        );
        expect(i, isNonNegative, reason: 'the lair scene of ${level.id}');
        expect(
          fr.bossLine(level),
          'FR ${CampaignVoices.lineName(scene, i, bird: 0)}',
          reason: level.id,
        );
      }
    });
  });

  group('story scenes show the language\'s captions', () {
    Future<void> pumpScene(
      WidgetTester tester,
      StoryScene scene,
      StoryCaptions captions, {
      int bird = 0,
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(792, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // A fresh player for each scene, from its first line.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: skyTheme(),
          locale: locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: StoryScenePlayer(
              scene: scene,
              bird: bird,
              reducedMotion: true,
              captions: captions,
              onDone: () {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> next(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
    }

    String shown(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const ValueKey('story-line')))
        .textSpan!
        .toPlainText();

    testWidgets('by clip, the bird\'s own wording, then English', (
      tester,
    ) async {
      final scene = CampaignStory.prologue;
      // Line 2 is the courier's: Peaches has her own words, Pip's stand in
      // for Minty, line 3 has none and stays English.
      expect(scene.lines[2].speaker, StorySpeaker.courier);
      final captions = StoryCaptions.of(AppLanguage.fr, {
        'before-1-1-0': 'La Poste du Club du Ciel. L’aube.',
        'before-1-1-1': 'Te voilà, la recrue !',
        'before-1-1-2-pip': 'Prêt à voler !',
        'before-1-1-2-peaches': 'Prête à voler !',
      });
      await pumpScene(tester, scene, captions, bird: 1);
      expect(shown(tester), 'La Poste du Club du Ciel. L’aube.');
      await next(tester);
      expect(shown(tester), 'Te voilà, la recrue !');
      expect(find.text('Postmaster Bill'), findsOneWidget);
      await next(tester);
      expect(shown(tester), 'Prête à voler !');
      expect(find.text('Peaches'), findsOneWidget);
      await next(tester);
      expect(shown(tester), scene.lines[3].text);

      await pumpScene(tester, scene, captions, bird: 2);
      await next(tester);
      await next(tester);
      expect(shown(tester), 'Prêt à voler !');
      // The screen reader hears the caption with its speaker.
      expect(find.bySemanticsLabel('Minty: Prêt à voler !'), findsOneWidget);
    });

    testWidgets('the end card follows the scene, not the caption', (
      tester,
    ) async {
      final scene = CampaignStory.lastWord(_level('3-4'))!;
      final last = scene.lines.length - 1;
      expect(scene.lines[last].endOfStop, isTrue);
      final endClip = CampaignVoices.lineName(scene, last, bird: 0);
      // Scene data decides: the stop's closing line, whatever its words.
      expect(ToBeContinued.matches(scene.lines[last]), isTrue);
      expect(
        ToBeContinued.matches(const StoryLine.endOfStop('Continua…')),
        isTrue,
      );
      expect(ToBeContinued.headEnd('다음 편에 계속… 다음 정거장'), '다음 편에 계속…'.length);
      expect(ToBeContinued.headEnd('未完待續。下一站：巴黎'), '未完待續。'.length);
      for (final (language, caption) in [
        (AppLanguage.ptBR, 'Continua… Próxima parada: Paris, a Cidade Luz.'),
        (AppLanguage.id, 'Bersambung… Perhentian berikutnya: Paris.'),
        (AppLanguage.ko, '다음 편에 계속… 다음 정거장: 빛의 도시 파리.'),
      ]) {
        await pumpScene(
          tester,
          scene,
          StoryCaptions.of(language, {
            // A translated line that happens to begin like the English end
            // card must not become one.
            CampaignVoices.lineName(scene, 0, bird: 0):
                'To be continued, he said.',
            endClip: caption,
          }),
        );
        expect(
          find.byKey(const ValueKey('story-to-be-continued')),
          findsNothing,
          reason: language.tag,
        );
        for (var i = 0; i < last; i++) {
          await next(tester);
        }
        expect(
          find.byKey(const ValueKey('story-to-be-continued')),
          findsOneWidget,
          reason: language.tag,
        );
        expect(shown(tester), caption);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('a letter is read on paper whatever its quotes', (
      tester,
    ) async {
      StoryScene? scene;
      var index = -1;
      for (final s in CampaignStory.scenes) {
        final i = s.lines.indexWhere(
          (l) => l.speaker == StorySpeaker.caption && l.text.startsWith('“'),
        );
        if (i >= 0) {
          scene = s;
          index = i;
          break;
        }
      }
      expect(scene, isNotNull);
      await pumpScene(
        tester,
        scene!,
        StoryCaptions.of(AppLanguage.fr, {
          CampaignVoices.lineName(scene, index, bird: 0): '« Livré, enfin. »',
        }),
      );
      for (var i = 0; i < index; i++) {
        await next(tester);
      }
      final speech = tester.widget<StorySpeech>(find.byType(StorySpeech));
      expect(speech.text, '« Livré, enfin. »');
      expect(speech.voice, StoryVoice.letter);
    });

    testWidgets('the thank-you note is the clip\'s caption', (tester) async {
      L10n.apply(AppLanguage.fr);
      L10n.applyCaptions(
        StoryCaptions.of(AppLanguage.fr, {
          'thanks-1-1': 'Notre plus bel anniversaire !',
        }),
      );
      final level = _level('1-1');
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: DeliveryNote(delivery: level.delivery, boss: null, seal: 1),
          ),
        ),
      );
      expect(
        find.text(_fr.campaignThanksQuoted('Notre plus bel anniversaire !')),
        findsOneWidget,
        reason: 'the caption in French quotation marks',
      );
      expect(
        find.text(_fr.campaignThanksSignature(_fr.levelSender(level))),
        findsOneWidget,
      );
    });
  });

  group('Arabic: the map stays a left-to-right world', () {
    Rect stop(WidgetTester tester, int i) =>
        tester.getRect(find.byKey(ValueKey('campaign-stop-$i')));

    testWidgets('it opens on the first stop, the Jungle', (tester) async {
      await _pumpMap(tester);
      expect(tester.takeException(), isNull);
      final screen = tester.element(find.byType(CampaignScreen));
      expect(Directionality.of(screen), TextDirection.rtl);
      // The pager is a piece of the world: left to right.
      final pager = find.byKey(const ValueKey('campaign-map-pager'));
      expect(Directionality.of(tester.element(pager)), TextDirection.ltr);
      expect(stop(tester, 0).left, 0);
      expect(stop(tester, 1).left, 792, reason: 'Brazil waits to the east');
      // The first stop's banner is the one in view.
      expect(
        find.bySemanticsLabel(
          RegExp('^${RegExp.escape(_ar.region_jungle)}\\. '),
        ),
        findsOneWidget,
      );
      // West and east: only Next stop, on the right.
      expect(find.bySemanticsLabel(_ar.campaignMapPreviousStop), findsNothing);
      expect(
        tester.getCenter(find.bySemanticsLabel(_ar.campaignMapNextStop)).dx,
        greaterThan(792 / 2),
      );
      // The menu chrome mirrors: the way back leads from the right.
      expect(
        tester.getCenter(find.bySemanticsLabel(_ar.commonBackHome)).dx,
        greaterThan(792 / 2),
      );
      expect(
        tester.getCenter(find.bySemanticsLabel(RegExp('في الحملة\$'))).dx,
        lessThan(792 / 2),
      );
      // A stop's words still run right to left.
      final banner = find
          .textContaining(_ar.campaignMapChapterBanner(1, '').trim())
          .first;
      expect(Directionality.of(tester.element(banner)), TextDirection.rtl);
    });

    testWidgets('it opens on the stop of the level to fly', (tester) async {
      // 1-1 to 1-3 flown: the courier perches on Brazil's 1-4.
      await _pumpMap(
        tester,
        cleared: {
          for (final id in ['1-1', '1-2', '1-3']) id: _level(id).marks.three,
        },
      );
      expect(stop(tester, 1).left, 0);
      expect(
        find.bySemanticsLabel(_ar.campaignMapPreviousStop),
        findsOneWidget,
      );
      expect(
        tester.getCenter(find.bySemanticsLabel(_ar.campaignMapPreviousStop)).dx,
        lessThan(792 / 2),
      );
      // The arrows still turn the map west and east.
      await tester.tap(find.bySemanticsLabel(_ar.campaignMapNextStop));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(stop(tester, 2).left, 0);
    });

    testWidgets('the level card mirrors, keys and all', (tester) async {
      await _pumpMap(tester);
      await tester.tap(find.byKey(const ValueKey('campaign-node-1-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      final card = tester.getRect(
        find.byKey(const ValueKey('level-intro-1-1')),
      );
      final fly = tester.getRect(find.byKey(const ValueKey('level-intro-fly')));
      final close = tester.getRect(
        find.byKey(const ValueKey('level-intro-close')),
      );
      final tag = tester.getRect(find.byKey(const ValueKey('level-intro-tag')));
      // The picture (and its parcel tag) on the right, the keys on the left
      // over the details, clear of the picture.
      expect(tag.center.dx, greaterThan(card.center.dx));
      expect(fly.center.dx, lessThan(card.center.dx));
      expect(close.center.dx, lessThan(card.center.dx));
      expect(fly.overlaps(tag), isFalse);
    });
  });

  group('the pseudo-locale fits the reference phone', () {
    setUp(() {
      L10n.apply(AppLanguage.en, locale: pseudoLocale);
      L10n.applyCaptions(StoryCaptions.pseudo());
    });

    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(792, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: skyTheme(),
          locale: pseudoLocale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(backgroundColor: SkyColors.sky, body: child),
        ),
      );
      await tester.pump();
    }

    /// No overflow, no label shrunk past [FitText.minScale], no text cut.
    void expectFits(WidgetTester tester, String where) {
      expect(tester.takeException(), isNull, reason: where);
      for (final MapEntry(key: text, value: scale) in FitText.scaleIn(
        tester.binding.rootElement!,
      ).entries) {
        expect(
          scale,
          greaterThanOrEqualTo(FitText.minScale),
          reason: '$where: shrunk too far: $text',
        );
      }
      for (final paragraph in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      )) {
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '$where: cut: ${paragraph.text.toPlainText()}',
        );
      }
    }

    final l = lookupAppLocalizations(pseudoLocale);

    testWidgets('level cards: plain, NEW and TIP hints, lair, guardians', (
      tester,
    ) async {
      for (final id in [
        '1-1',
        '1-2',
        '1-6',
        '1-8',
        '2-6',
        '3-2',
        '3-4',
        '5-1',
      ]) {
        final level = _level(id);
        await pump(
          tester,
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(LevelIntroCard.size),
              child: LevelIntroCard(
                level: level,
                record: LevelRecord(levelId: id),
                onFly: () {},
                onClose: () {},
                onStory: () {},
              ),
            ),
          ),
        );
        // The pseudo words are on the card.
        expect(find.text(l.levelName(level)), findsWidgets, reason: id);
        expect(find.text(l.levelIntroFly), findsOneWidget, reason: id);
        expectFits(tester, id);
      }
    });

    testWidgets('the five postcards', (tester) async {
      for (var chapter = 1; chapter <= 5; chapter++) {
        await pump(
          tester,
          Center(
            child: SizedBox(
              width: 760,
              child: CampaignPostcard(chapter: chapter, bird: 0),
            ),
          ),
        );
        final letter = CampaignPostcard.letters[chapter - 1];
        expect(find.text(letter.bodyIn(l)), findsOneWidget);
        expectFits(tester, 'postcard $chapter');
        // The message keeps above the signature, measured along the card
        // (which lies a little turned on the table).
        final message = tester.renderObject<RenderBox>(
          find.byKey(const ValueKey('campaign-postcard-message')),
        );
        final signature = tester.renderObject<RenderBox>(
          find.ancestor(
            of: find.text(l.campaignPostcardSignature(letter.routeIn(l))),
            matching: find.byType(IntrinsicWidth),
          ),
        );
        final foot = signature.globalToLocal(
          message.localToGlobal(Offset(0, message.size.height)),
        );
        expect(foot.dy, lessThanOrEqualTo(.5), reason: 'postcard $chapter');
      }
    });

    testWidgets('thank-you notes keep to their lines', (tester) async {
      for (final level in Campaign.levels) {
        await pump(
          tester,
          Center(
            child: DeliveryNote(
              delivery: level.delivery,
              boss: level.isChapterBoss ? level.boss : null,
              seal: 1,
            ),
          ),
        );
        expectFits(tester, level.id);
      }
    });

    testWidgets('story lines: written in, still two rows', (tester) async {
      final panel = StoryLayout(
        const Size(792, 360),
        EdgeInsets.zero,
        lair: false,
      ).panel;
      for (final scene in [
        CampaignStory.prologue,
        CampaignStory.after(Campaign.chapters[0]),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await pump(
          tester,
          StoryScenePlayer(
            scene: scene,
            bird: 0,
            reducedMotion: true,
            onDone: () {},
          ),
        );
        for (var i = 0; i < scene.lines.length; i++) {
          final line = scene.lines[i];
          final caption = pseudoLocalize(line.text);
          final speech = tester.widget<StorySpeech>(find.byType(StorySpeech));
          expect(speech.text, caption, reason: '${scene.id}-$i');
          expect(
            StorySpeech.fit(
              caption,
              speech.voice,
              StorySpeech.room(speech.voice, panel.width),
            ),
            isNotNull,
            reason: '${scene.id}-$i runs past two rows: $caption',
          );
          expectFits(tester, '${scene.id}-$i');
          if (i + 1 < scene.lines.length) {
            await tester.tap(find.byKey(const ValueKey('story-advance')));
            await tester.pump();
          }
        }
      }
    });

    testWidgets('the map: every stop, a guardian, a lock note', (tester) async {
      // Chapters 1 and 2 and 3-1 flown: New York's guardians are on the map.
      await _pumpMap(
        tester,
        language: AppLanguage.en,
        locale: pseudoLocale,
        cleared: {
          for (final level in [
            ...Campaign.chapters[0].levels,
            ...Campaign.chapters[1].levels,
            _level('3-1'),
          ])
            level.id: level.marks.three,
        },
      );
      expectFits(tester, 'map at New York');
      expect(
        find.text(l.campaignGuardian),
        findsWidgets,
        reason: 'the guardians\' plaques',
      );
      // A locked level answers with its lock note.
      await tester.tap(find.byKey(const ValueKey('campaign-node-3-3')));
      await tester.pump();
      expect(
        find.text(
          l.campaignLockedBeat(
            l.bossName(BossKind.kingCoo),
            BossKind.kingCoo.name,
          ),
        ),
        findsOneWidget,
      );
      expectFits(tester, 'lock note');
      final map = tester.state<ScrollableState>(find.byType(Scrollable).first);
      for (var i = 0; i < Campaign.journey.length; i++) {
        map.position.jumpTo(i * 792.0);
        await tester.pump();
        expectFits(tester, 'stop $i');
      }
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('the launch lockup', (tester) async {
      await pump(tester, const Center(child: LaunchLockup()));
      expect(find.text(l.motto), findsOneWidget);
      expectFits(tester, 'launch');
    });
  });

  test('campaign stops are worded in the language asked', () {
    final progress = CampaignProgress(const []);
    final stops = campaignStops(progress, lookupAppLocalizations(pseudoLocale));
    final jungle = stops.first;
    expect(jungle.route, lookupAppLocalizations(pseudoLocale).chapter_1_route);
    expect(
      jungle.nodes.first.name,
      lookupAppLocalizations(pseudoLocale).level_1_1_name,
    );
    final english = campaignStops(progress);
    expect(english.first.route, 'The Canopy Route');
    expect(english.last.soonNote, 'Coming soon');
    expect(english.first, isA<CampaignMapStop>());
  });
  // Integration (M1): the translators' voice scripts bundled with
  // tool/l10n/build_captions.py, read from the real asset bundle.
  group('every language\'s bundled captions load', () {
    final script = <AppLanguage, RegExp>{
      AppLanguage.ja: RegExp('[\u3040-\u30ff\u4e00-\u9fff]'),
      AppLanguage.ko: RegExp('[\uac00-\ud7af]'),
      AppLanguage.zhHant: RegExp('[\u4e00-\u9fff]'),
      AppLanguage.ru: RegExp('[\u0400-\u04ff]'),
      AppLanguage.ar: RegExp('[\u0600-\u06ff]'),
    };
    for (final language in AppLanguage.values) {
      if (language == AppLanguage.en) continue;
      test(language.tag, () async {
        final captions = await StoryCaptions.load(language);
        expect(captions.language, language);
        // Every story clip and thank-you note (all but the optional,
        // unwired in-flight "coo-pop").
        expect(captions.length, greaterThanOrEqualTo(386));
        var lines = 0, english = 0;
        for (final scene in CampaignStory.scenes) {
          for (var i = 0; i < scene.lines.length; i++) {
            for (var bird = 0; bird < 4; bird++) {
              final text = captions.line(scene, i, bird: bird);
              expect(text.trim(), isNotEmpty, reason: '${scene.id} $i');
              lines++;
              if (text == scene.lines[i].text) english++;
            }
            if (scene.lines[i].endOfStop) {
              // The end card still finds where "To be continued" ends.
              final text = captions.line(scene, i, bird: 0);
              expect(
                ToBeContinued.headEnd(text),
                inInclusiveRange(1, text.length),
              );
            }
          }
        }
        for (final level in Campaign.levels) {
          final text = captions.thanks(level);
          expect(text.trim(), isNotEmpty, reason: level.id);
          lines++;
          if (text == level.delivery.thanks) english++;
        }
        // A few lines may read the same in both (a name, an interjection).
        expect(
          english,
          lessThan(lines * .03),
          reason: '$english of $lines captions are the English words',
        );
        final letters = script[language];
        if (letters != null) {
          final first = CampaignStory.scenes.first;
          expect(captions.line(first, 0, bird: 0), contains(letters));
        }
      });
    }
  });
}
