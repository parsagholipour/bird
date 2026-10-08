import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/knockout_art.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/language_providers.dart';
import 'package:push_up_bird/l10n/pseudo.dart';
import 'package:push_up_bird/l10n/text/coop_text.dart';
import 'package:push_up_bird/l10n/text/flight_text.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/components.dart' show SceneLayout;
import 'package:push_up_bird/ui/fit_text.dart';
import 'package:push_up_bird/ui/game_over_stage.dart';
import 'package:push_up_bird/ui/level_result.dart';
import 'package:push_up_bird/ui/mini_results.dart';
import 'package:push_up_bird/ui/pause_card.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'play_session_test.dart' show SessionSource, SilentAudio;
import 'recorded_flight.dart' show rideTheSky;

/// Slice S2 of the localization (MASTER-PLAN.md): the flight, its HUD and
/// its results. The English ARB stays equal to the domain's English twins;
/// the flight screens fit the reference phone (792 × 360) in the
/// pseudo-locale; under Arabic the flight and its HUD stay left to right
/// while the pause card and the results mirror.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pseudo = lookupAppLocalizations(pseudoLocale);

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

  group('English twins', () {
    test('every flight note is its English key', () {
      for (final note in FlightNote.values) {
        expect(FlightNote.of(note.english), note, reason: note.name);
        expect(en.flightNote(note.english), note.english, reason: note.name);
        expect(
          pseudo.flightNote(note.english),
          isNot(note.english),
          reason: '${note.name} must reach its key',
        );
      }
      // A simulation's feedback before any tracker speaks is a note.
      expect(
        FlightSimulation(rules: TapFlyMode(), practice: true).trackingFeedback,
        FlightNote.findPosition.english,
      );
    });

    test('words the flight does not know pass through as they are', () {
      // A tracker's feedback (TrackingText's, until slice S5 words it) and
      // an error's own text.
      expect(pseudo.flightNote('Disk full'), 'Disk full');
      expect(
        en.flightNote('Keep both shoulders in view'),
        'Keep both shoulders in view',
      );
    });

    test('courses, gate families, rush paths and co-op modes', () {
      for (final course in FlightCourse.values) {
        expect(en.courseTitle(course), course.title, reason: course.name);
        expect(
          en.courseInstructions(course),
          course.instructions,
          reason: course.name,
        );
        expect(
          en.courseScoreLabel(course),
          course.scoreLabel,
          reason: course.name,
        );
        expect(
          en.courseScoreUnit(course, 12),
          course.scoreUnit,
          reason: course.name,
        );
      }
      for (final kind in ObstacleKind.values) {
        expect(en.obstacleName(kind), kind.title, reason: kind.name);
      }
      for (final kind in RushPathKind.values) {
        expect(en.rushName(kind), kind.title, reason: kind.name);
        expect(en.rushEscape(kind), kind.escape, reason: kind.name);
      }
      for (final mode in CoopMode.values) {
        expect(en.coopModeName(mode), mode.title, reason: mode.name);
      }
    });

    test('the level result words stay word for word', () {
      final boss = Campaign.level('1-8')!;
      final plain = Campaign.level('1-3')!;
      expect(LevelResultStage.wordFor(boss, complete: true), 'Victory!');
      expect(LevelResultStage.wordFor(plain, complete: true), 'Delivered!');
      expect(LevelResultStage.wordFor(plain, complete: false), 'Try again!');
      expect(
        LevelResultStage.wordFor(plain, complete: true, l: pseudo),
        pseudo.levelResultDelivered,
      );
      expect(en.flightRank(30), 'Sky captain');
      expect(en.flightRank(12), 'Cloud explorer');
      expect(en.flightRank(5), 'First wings');
      expect(en.flightMoves(PlayMode.touch, 40), 'flaps');
      expect(en.flightMoves(PlayMode.pushUp, 1), 'push-ups');
      expect(
        en.flightEndReason(EndReason.collision),
        en.flightResultBumpClouds,
      );
    });

    test('a title drops whole letters, or a joining script whole', () {
      expect(dropLetters('Bonk!'), ['B', 'o', 'n', 'k', '!']);
      // Accents stay on their letters.
      expect(dropLetters('Pláf!'), ['P', 'l', 'á', 'f', '!']);
      expect(dropLetters('ポチャン!'), ['ポ', 'チ', 'ャ', 'ン', '!']);
      // Arabic letters join: the word is shaped as one.
      expect(dropLetters('بونك!'), ['بونك!']);
    });

    test('HUD words are made once per language and value', () {
      var made = 0;
      String hearts(AppLocalizations l, int n) => HudWords.of(l, ('t', n), () {
        made++;
        return l.hudHeartsSemantics(n);
      });
      expect(hearts(en, 3), '3 hearts remaining');
      expect(hearts(en, 3), '3 hearts remaining');
      expect(made, 1);
      expect(hearts(pseudo, 3), pseudo.hudHeartsSemantics(3));
      expect(made, 2);
      // A language switch empties the cache.
      L10n.apply(AppLanguage.de);
      expect(hearts(en, 3), '3 hearts remaining');
      expect(made, 3);
    });
  });

  group('pseudo-locale fits the reference phone', () {
    testWidgets('the pause card, with each set of keys', (tester) async {
      _phone(tester);
      L10n.apply(AppLanguage.en, locale: pseudoLocale);
      for (final (subtitle, actions) in [
        (
          pseudo.flightPausedLevel('3-4', 'Steam Alley'),
          [pseudo.commonMap, pseudo.commonRetry],
        ),
        (pseudo.flightPausedCamera, [pseudo.flightPauseFinish]),
        (
          pseudo.flightPausedTest('A very long level name'),
          [pseudo.flightPauseEdit, pseudo.commonRetry],
        ),
      ]) {
        await tester.pumpWidget(
          _localized(
            pseudoLocale,
            Scaffold(
              backgroundColor: SkyColors.sky,
              // The flight's HUD sets the card on its scene.
              body: SceneLayout(
                child: PauseCard(
                  reducedMotion: true,
                  subtitle: subtitle,
                  actions: [
                    for (final label in actions)
                      PauseAction(
                        label: label,
                        icon: Icons.map_rounded,
                        onPressed: () {},
                      ),
                  ],
                  onResume: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(pseudo.flightPauseTitle), findsOneWidget);
        expect(find.text(pseudo.flightPauseKeepFlying), findsOneWidget);
        _expectFits(tester);
      }
    });

    for (final splash in [false, true]) {
      testWidgets('the game-over stage (${splash ? 'sea' : 'bump'})', (
        tester,
      ) async {
        _phone(tester);
        L10n.apply(AppLanguage.en, locale: pseudoLocale);
        final controller = await _ended(tester, EndReason.collision, 31);
        await tester.pumpWidget(
          _localized(
            pseudoLocale,
            Scaffold(
              body: GameOverStage(
                controller: controller,
                progress: const ProgressSnapshot(),
                mode: PlayMode.touch,
                course: FlightCourse.starTrail,
                initialBest: 10,
                initialStamps: const {},
                initialDailyKey: null,
                initialDailyComplete: false,
                onLeave: ([_ = '/']) async {},
                splash: splash,
              ),
            ),
          ),
        );
        await _settle(tester);
        final word = splash ? pseudo.gameOverSplash : pseudo.gameOverBonk;
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == word,
          ),
          findsOneWidget,
        );
        expect(find.text(pseudo.flightResultFlyAgain), findsOneWidget);
        _expectFits(tester, display: _display);
      });
    }

    testWidgets('the endless results', (tester) async {
      _phone(tester);
      L10n.apply(AppLanguage.en, locale: pseudoLocale);
      final controller = await _ended(tester, EndReason.quit, 42);
      await tester.pumpWidget(
        _localized(
          pseudoLocale,
          Scaffold(
            // The play screen sets the results on its scene.
            body: SceneLayout(
              child: MiniResults(
                controller: controller,
                progress: const ProgressSnapshot(),
                mode: PlayMode.touch,
                course: FlightCourse.starTrail,
                initialBest: 10,
                initialStamps: const {},
                initialDailyKey: null,
                initialDailyComplete: false,
                onLeave: ([_ = '/']) async {},
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text(pseudo.miniResultTitle), findsOneWidget);
      expect(find.text(pseudo.miniResultCheerBest), findsOneWidget);
      _expectFits(tester, display: _display);
    });

    testWidgets('a level flight: countdown, HUD, pause and its result', (
      tester,
    ) async {
      final app = await _App.open(tester, '/play/touch?level=1-1');
      final controller = app.controller(tester);
      // The countdown card and its hint.
      expect(find.text(pseudo.flightCountdownReady), findsOneWidget);
      _expectFits(tester);
      // The pause card over the flight.
      _fly(controller, until: (sim) => sim.gates >= 2);
      controller.pause();
      await _settle(tester);
      expect(
        find.text(
          pseudo.flightPausedLevel(
            '1-1',
            pseudo.levelName(Campaign.level('1-1')!),
          ),
        ),
        findsOneWidget,
      );
      _expectFits(tester);
      await controller.resume();
      await _settle(tester);
      // The result after the finish.
      _fly(controller);
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.byType(LevelResultStage), findsOneWidget);
      expect(find.text(pseudo.flightResultStarsCollected), findsOneWidget);
      _expectFits(tester, display: _display);
      await app.close(tester);
    });

    testWidgets('a level that ended in a bump', (tester) async {
      final app = await _App.open(tester, '/play/touch?level=1-1');
      final controller = app.controller(tester);
      _fly(controller, until: (sim) => sim.gates >= 6);
      controller.simulation!.collectedStars = 4;
      _crash(controller);
      await _settle(tester);
      controller.knockout = KnockoutArt.skipAfter + .01;
      controller.skipKnockout();
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.byType(GameOverStage), findsOneWidget);
      expect(find.text(pseudo.gameOverRouteFlown), findsOneWidget);
      _expectFits(tester, display: _display);
      await app.close(tester);
    });

    for (final (route, mode) in [
      ('/play/push-up', PlayMode.pushUp),
      ('/play/squat', PlayMode.squat),
      ('/play/jump', PlayMode.jump),
    ]) {
      testWidgets('camera setup and calibration (${mode.name})', (
        tester,
      ) async {
        final source = SessionSource();
        final app = await _App.open(tester, route, source: source);
        expect(find.text(pseudo.flightSetupHowToFly), findsOneWidget);
        _expectFits(tester);
        final controller = app.controller(tester);
        await tester.runAsync(controller.startCamera);
        await _settle(tester);
        expect(
          find.text(
            mode.controlsHeight
                ? pseudo.flightCalibrationTitleRange
                : pseudo.flightCalibrationTitleStill,
          ),
          findsWidgets,
        );
        _expectFits(tester);
        await app.close(tester);
      });
    }
  });

  group('Arabic', () {
    testWidgets('the HUD stays left to right; the pause card mirrors', (
      tester,
    ) async {
      final app = await _App.open(
        tester,
        '/play/touch',
        language: AppLanguage.ar,
      );
      final controller = app.controller(tester);
      _fly(controller, until: (sim) => sim.gates >= 1);
      await _settle(tester);
      for (final key in ['match-health', 'touch-shoot', 'touch-sprint']) {
        expect(
          Directionality.of(tester.element(find.byKey(ValueKey(key)))),
          TextDirection.ltr,
          reason: key,
        );
      }
      expect(
        Directionality.of(tester.element(find.byType(GameWidget<BirdGame>))),
        TextDirection.ltr,
      );
      controller.pause();
      await _settle(tester);
      expect(
        Directionality.of(tester.element(find.byType(PauseCard))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      // The results are a menu: they mirror; the dropping title keeps its
      // letters in order.
      controller.endFlight();
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 2400));
      expect(
        Directionality.of(tester.element(find.byType(MiniResults))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      await app.close(tester);
    });

    testWidgets('the game-over title keeps its letters in order', (
      tester,
    ) async {
      _phone(tester);
      L10n.apply(AppLanguage.ar);
      final controller = await _ended(tester, EndReason.collision, 3);
      await tester.pumpWidget(
        _localized(
          AppLanguage.ar.locale,
          Scaffold(
            body: GameOverStage(
              controller: controller,
              progress: const ProgressSnapshot(),
              mode: PlayMode.touch,
              course: FlightCourse.starTrail,
              initialBest: 10,
              initialStamps: const {},
              initialDailyKey: null,
              initialDailyComplete: false,
              onLeave: ([_ = '/']) async {},
            ),
          ),
        ),
      );
      await _settle(tester);
      // Arabic letters join, so the Arabic word drops in whole; a Latin
      // word (one a language keeps, or English) drops letter by letter,
      // which only reads B-o-n-k when the row runs left to right.
      final ar = lookupAppLocalizations(AppLanguage.ar.locale);
      expect(dropLetters(ar.gameOverBonk), [ar.gameOverBonk]);
      expect(find.text(ar.gameOverBonk), findsWidgets);
      expect(dropLetters('Bonk!'), ['B', 'o', 'n', 'k', '!']);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Big display words that are designed to scale down to their stage
/// (they drop in letter by letter at 78–96 pt).
final _display = {
  for (final l in [
    lookupAppLocalizations(pseudoLocale),
    lookupAppLocalizations(const Locale('en')),
  ]) ...{
    l.gameOverBonk,
    l.gameOverSplash,
    l.levelResultTryAgain,
    l.levelResultVictory,
    l.levelResultDelivered,
    l.levelResultGuardianDown,
  },
};

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(792, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _localized(Locale locale, Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: skyTheme(),
  locale: locale,
  supportedLocales: L10n.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

/// A touch flight that ended for [reason] with [score], saved.
Future<PlayController> _ended(
  WidgetTester tester,
  EndReason reason,
  int score,
) async {
  final controller = PlayController(
    mode: PlayMode.touch,
    source: null,
    audio: SilentAudio(),
    saveRun: (_) async {},
    saveSession: (_) async {},
  );
  await tester.runAsync(() async {
    await controller.fly();
    controller.simulation!
      ..started = true
      ..score = score;
    controller.simulation!.end(reason);
    await controller.finish();
  });
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void _fly(
  PlayController controller, {
  bool Function(FlightSimulation sim)? until,
}) {
  final sim = controller.simulation!;
  for (var frame = 1; frame <= 400 * 50; frame++) {
    if (sim.phase == RunPhase.ended || (until?.call(sim) ?? false)) break;
    if (sim.hearts < 2) sim.hearts = 3;
    if (rideTheSky(sim)) controller.flap();
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
  while (!controller.celebrationSettled) {
    controller.advance(.02, 0, 2.2);
  }
}

void _crash(PlayController controller) {
  final sim = controller.simulation!
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0;
  for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
}

/// The real app on the reference phone, in the pseudo-locale (or
/// [language]), at [route].
class _App {
  _App(this.container, this.repo, this.folder);
  final ProviderContainer container;
  final SqliteProgressRepository repo;
  final Directory folder;

  static Future<_App> open(
    WidgetTester tester,
    String route, {
    SessionSource? source,
    AppLanguage? language,
  }) async {
    _phone(tester);
    if (const bool.fromEnvironment('L10N_DEBUG')) {
      final report = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint('L10N_DEBUG ${details.toString()}');
        report?.call(details);
      };
      addTearDown(() => FlutterError.onError = report);
    }
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    final folder = Directory.systemTemp.createTempSync('l10n-flight');
    await tester.runAsync(() async {
      await repo.setSetting(SettingKey.reducedMotion, true);
      if (language != null) await repo.setLanguage(language);
      for (final scene in CampaignStory.scenes) {
        await repo.markStoryWatched(scene);
      }
    });
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
        audioFactoryProvider.overrideWithValue(() => SilentAudio()),
        trackingSourceFactoryProvider.overrideWithValue(
          () => source ?? (throw StateError('Touch never opens the camera')),
        ),
        if (language == null) appLocaleProvider.overrideWithValue(pseudoLocale),
      ],
    );
    await tester.runAsync(() => container.read(progressProvider.future));
    appRouter.go(route);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PushUpBirdApp(),
      ),
    );
    await _settle(tester, 3);
    if (find.byType(GameWidget<BirdGame>).evaluate().isNotEmpty) {
      final game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(
        () => game.loaded.timeout(const Duration(seconds: 5)),
      );
      game.pauseEngine();
      await tester.pump();
    }
    return _App(container, repo, folder);
  }

  PlayController controller(WidgetTester tester) =>
      (tester.state(find.byType(PlayScreen)) as dynamic).controller
          as PlayController;

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(repo.close);
    if (folder.existsSync()) folder.deleteSync(recursive: true);
    appRouter.go('/');
  }
}

/// Nothing overflows, no text is cut, and no fitted label had to shrink
/// below [FitText.minScale] (but the [display] words, which are drawn to
/// scale to their stage).
void _expectFits(WidgetTester tester, {Set<String> display = const {}}) {
  // --dart-define=L10N_DEBUG=true leaves an overflow to the framework,
  // which reports the widget that overflowed.
  if (!const bool.fromEnvironment('L10N_DEBUG')) {
    expect(tester.takeException(), isNull);
  }
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  )) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'cut: ${paragraph.text.toPlainText()}',
    );
  }
  for (final box in tester.renderObjectList<RenderFittedBox>(
    find.byType(FittedBox),
  )) {
    final child = box.child;
    if (!box.hasSize || child == null || !child.hasSize) continue;
    if (child.size.width <= 0 || child.size.height <= 0) continue;
    final words = _words(box).trim();
    if (words.isEmpty || display.contains(words)) continue;
    final scale = math.min(
      box.size.width / child.size.width,
      box.size.height / child.size.height,
    );
    // A label built of messages inside messages ("Next: {stamp · medal}")
    // is padded +40 % once per message in the pseudo-locale, about twice
    // a real language's growth: it may shrink further.
    final nested = _bracketDepth(words) >= 3;
    expect(
      scale,
      greaterThanOrEqualTo((nested ? .5 : FitText.minScale) - .005),
      reason: 'shrunk to ${scale.toStringAsFixed(2)} to fit: $words',
    );
  }
}

/// How deep pseudo-locale messages nest in [words] (`[a [b] c]` is 2).
int _bracketDepth(String words) {
  var depth = 0, deepest = 0;
  for (final c in words.split('')) {
    if (c == '[') deepest = math.max(deepest, ++depth);
    if (c == ']') depth = math.max(0, depth - 1);
  }
  return deepest;
}

/// The words a render subtree sets, joined.
String _words(RenderObject root) {
  final out = <String>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      out.add(node.text.toPlainText());
      return;
    }
    node.visitChildren(visit);
  }

  visit(root);
  // A word dropped letter by letter is one word, each letter drawn three
  // times (shadow, outline, fill).
  if (out.length % 3 == 0 && out.every((s) => s.characters.length <= 1)) {
    return [for (var i = 0; i < out.length; i += 3) out[i]].join();
  }
  return out.join(' ');
}
