import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import 'package:push_up_bird/domain/built_code.dart';
import 'package:push_up_bird/domain/built_reach.dart';
import 'package:push_up_bird/domain/built_templates.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/language_providers.dart';
import 'package:push_up_bird/l10n/pseudo.dart';
import 'package:push_up_bird/l10n/text/builder_shelf_text.dart';
import 'package:push_up_bird/l10n/text/coop_text.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/builder/builder_name_dialog.dart';
import 'package:push_up_bird/ui/fit_text.dart';
import 'package:push_up_bird/ui/mini_calibration.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'builder_ui_harness.dart' show FakeClipboard, builtLevel;
import 'play_session_test.dart' show SilentAudio;

/// Slice S5 of the localization (MASTER-PLAN.md, "Slices"): the Level
/// Builder shelf, Fly Together and 1 v 1, the camera lab and the tracking
/// coaching. The domain keeps its English as twins; these tests keep the
/// English ARB equal to them, check every tracker line reaches a key, and
/// pump the screens in the pseudo-locale (+40 %) and in Arabic at the
/// reference phone's 792 x 360.
void main() {
  final en = lookupAppLocalizations(AppLanguage.en.locale);
  final ar = lookupAppLocalizations(AppLanguage.ar.locale);
  final pseudo = lookupAppLocalizations(pseudoLocale);

  group('tracking coaching', () {
    String sample(TrackingCue cue, {int step = 1}) =>
        cue.counted ? cue.englishWith(step: step, total: 2) : cue.english;

    test('every cue reads as its English twin in English', () {
      for (final cue in TrackingCue.values) {
        final english = sample(cue);
        expect(TrackingCue.parse(english)?.$1, cue, reason: english);
        expect(en.trackingFeedback(english), english);
      }
      expect(TrackingCue.parse('Lower comfortably · 2 of 2'), (
        TrackingCue.lowerComfortably,
        2,
        2,
      ));
      expect(
        en.trackingFeedback('Match your first comfortable range · 2 of 2'),
        'Match your first comfortable range · 2 of 2',
      );
    });

    test('every cue has its own words in another language', () {
      for (final cue in TrackingCue.values) {
        final english = sample(cue, step: 2);
        final words = pseudo.trackingFeedback(english);
        expect(words, isNot(english), reason: '${cue.name} has no key');
        expect(words, startsWith('['));
        if (cue.counted) expect(words, contains('2'));
      }
    });

    test('words that are not a tracker\'s pass through', () {
      for (final text in ['', 'CameraAccessException: busy', 'Jump!']) {
        expect(TrackingCue.parse(text), isNull);
        expect(pseudo.trackingFeedback(text), text);
      }
    });

    test('every coaching line the trackers write has a cue', () {
      // String literals of the trackers that read as a sentence to the
      // player: everything but the mode titles (playModeName) and the
      // camera lab's technical readout.
      const notCoaching = {
        'Push-Up Flight',
        'Jump & Fly',
        'Tap & Fly',
        'Squat & Fly',
        'No pose detected',
      };
      final literal = RegExp(r"'((?:[^'\\\n]|\\.)*)'");
      final found = <String>{};
      for (final file in [
        'lib/domain/tracking.dart',
        'lib/domain/squat_tracking.dart',
        'lib/domain/jump_tracking.dart',
      ]) {
        for (final line in File(file).readAsLinesSync()) {
          if (line.trimLeft().startsWith('//')) continue;
          for (final match in literal.allMatches(line)) {
            final text = match[1]!;
            if (!text.contains(' ') || !RegExp('^[A-Z]').hasMatch(text)) {
              continue;
            }
            if (notCoaching.contains(text)) continue;
            // An interpolated line is a counted calibration step, or the
            // lab's readout.
            final counted = text.replaceAll(RegExp(r'\$\{[^}]*\}'), '1');
            if (counted.contains(r'$')) continue;
            if (text.contains(r'$') && !counted.contains(' of ')) continue;
            found.add(counted);
          }
        }
      }
      expect(found.length, greaterThan(35), reason: 'the scan found $found');
      final orphans = [
        for (final text in found)
          if (TrackingCue.parse(text) == null) text,
      ];
      expect(orphans, isEmpty, reason: 'coaching lines without a cue');
    });

    test('the simulation\'s and the camera\'s own lines have cues', () {
      expect(
        File('lib/domain/game_rules.dart').readAsStringSync(),
        contains("trackingFeedback = '${TrackingCue.findPosition.english}'"),
      );
      final activity = File(
        'android/app/src/main/kotlin/com/ravanix/push_up_bird/MainActivity.kt',
      ).readAsStringSync();
      for (final cue in [
        TrackingCue.trackingInterrupted,
        TrackingCue.cameraInterrupted,
        TrackingCue.cameraAway,
      ]) {
        expect(activity, contains('"${cue.english}"'));
      }
    });
  });

  group('domain twins', () {
    test('co-op modes and duel prizes', () {
      for (final mode in CoopMode.values) {
        expect(en.coopModeName(mode), mode.title);
        expect(pseudo.coopModeName(mode), isNot(mode.title));
      }
      for (final prize in BoxPrize.values) {
        expect(en.duelPrizeName(prize), prize.title);
        expect(pseudo.duelPrizeName(prize), isNot(prize.title));
      }
      expect(en.coopPlayerTag(0), 'P1');
      expect(en.coopPlayerTag(1), 'P2');
    });

    test('starter level names; a player\'s own name stays theirs', () {
      for (final level in BuiltTemplates.all) {
        expect(en.builtLevelName(level.plan), level.plan.name);
        expect(en.starterLevelName(level.id), level.plan.name);
        expect(pseudo.builtLevelName(level.plan), isNot(level.plan.name));
      }
      final mine = builtLevel(PlayMode.touch, id: 'u-mylevel123', name: 'Hop');
      expect(pseudo.builtLevelName(mine), 'Hop');
      expect(en.starterLevelName('u-mylevel123'), isNull);
    });

    test('plural counts keep the English as it was', () {
      expect(en.builderShelfToFixInEditor(1), '1 thing to fix in the editor');
      expect(en.builderShelfToFixInEditor(3), '3 things to fix in the editor');
      expect(en.builderShelfStars(24), '24 stars');
      expect(en.duelCountTag('1 V 1', 5), '1 V 1 · 5 DUELS');
      expect(en.coopMagnetSemantics(4), 'Star magnet: 4 seconds remaining');
      expect(en.cameraLabTestPushUps(3), 'CONTROL TEST\n3 push-ups');
      expect(en.coopPlayerFlaps(40, 2), 'P2 flaps');
      expect(en.coopStatStars(1), 'stars');
    });
  });

  group('on the reference phone', () {
    setUpAll(_loadFonts);
    tearDown(L10n.debugReset);

    testWidgets('the builder shelf, empty, fits the pseudo-locale', (
      tester,
    ) async {
      await _pumpApp(tester, '/builder', pseudo: true);
      expect(find.text(pseudo.builderShelfTitle), findsOneWidget);
      expect(find.text(pseudo.builderShelfEmptyTitle), findsOneWidget);
      expect(find.text('Level Builder'), findsNothing);
      await _snap(tester, 'shelf-empty-en_XA');
      _expectFits(tester);
    });

    testWidgets('the shelf with levels and its sheets fit the pseudo-locale', (
      tester,
    ) async {
      final clipboard = FakeClipboard()..install(tester);
      final ready = builtLevel(PlayMode.touch, id: 'u-readylevel', name: 'Hop');
      final broken = builtLevel(
        PlayMode.squat,
        id: 'u-brokenlevl',
        name: 'Half built',
        gates: 0,
      );
      await _pumpApp(tester, '/builder', pseudo: true, levels: [ready, broken]);
      expect(find.text(pseudo.builderShelfNeedsWork), findsOneWidget);
      final fix = math.max(
        1,
        BuiltReach.check(broken).where((issue) => issue.blocking).length,
      );
      expect(find.text(pseudo.builderShelfToFixInEditor(fix)), findsOneWidget);
      for (final level in BuiltTemplates.all) {
        expect(find.text(pseudo.builtLevelName(level.plan)), findsOneWidget);
      }
      await _snap(tester, 'shelf-en_XA');
      _expectFits(tester);

      // A level's More sheet.
      await tester.tap(find.byKey(const ValueKey('more-u-readylevel')));
      await _settle(tester);
      expect(find.text(pseudo.builderPickDuplicate), findsOneWidget);
      await _snap(tester, 'more-en_XA');
      _expectFits(tester);
      await _tapClose(tester, pseudo.builderPickClose);
      await _settle(tester);

      // The new level sheet: modes, then regions.
      await tester.tap(find.byKey(const ValueKey('new-level')));
      await _settle(tester);
      expect(find.text(pseudo.builderPickModeTitle), findsOneWidget);
      await _snap(tester, 'new-level-en_XA');
      _expectFits(tester);
      await tester.tap(find.byKey(const ValueKey('new-mode-pushUp')));
      await _settle(tester);
      expect(find.text(pseudo.builderPickSuggested), findsOneWidget);
      await _snap(tester, 'new-level-region-en_XA');
      _expectFits(tester);
      await _tapClose(tester, pseudo.builderPickCloseNewLevel);
      await _settle(tester);

      // A friend's code, and codes that cannot be read.
      clipboard.text = BuiltCode.message(
        builtLevel(
          PlayMode.squat,
          id: 'u-friendslvl',
          name: 'From Ana',
          gates: 9,
          region: WorldRegion.paris,
        ),
        cleared: true,
      );
      await tester.tap(find.byKey(const ValueKey('paste-code')));
      await _settle(tester);
      expect(find.text(pseudo.builderPickImportTitle), findsOneWidget);
      await _snap(tester, 'import-en_XA');
      _expectFits(tester);
      await tester.tap(find.byKey(const ValueKey('import-keep')));
      await _settle(tester);
      expect(find.text(pseudo.builderShelfImported('From Ana')), findsOne);

      clipboard.text = 'nothing to see here';
      await tester.tap(find.byKey(const ValueKey('paste-code')));
      await _settle(tester);
      expect(find.text(pseudo.builderShelfPasteMissingTitle), findsOneWidget);
      _expectFits(tester);
    });

    testWidgets('the rename card fits the pseudo-locale', (tester) async {
      await _pumpBare(
        tester,
        pseudoLocale,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showBuilderNameDialog(context, 'Hop'),
              child: const Text('rename'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('rename'));
      await tester.pumpAndSettle();
      expect(find.text(pseudo.builderShelfRenameTitle), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('name-field')), ' ');
      await tester.pump();
      expect(find.text(pseudo.builderShelfRenameEmpty), findsOneWidget);
      _expectFits(tester);
    });

    testWidgets('the camera badge says each state in the pseudo-locale', (
      tester,
    ) async {
      await _pumpBare(
        tester,
        pseudoLocale,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final state in CameraState.values)
              CameraBadge(state: state, still: true),
          ],
        ),
      );
      for (final words in [
        pseudo.cameraBadgeWaking,
        pseudo.cameraBadgeLive,
        pseudo.cameraBadgeLockedOn,
        pseudo.cameraBadgeOffline,
      ]) {
        expect(find.text(words), findsOneWidget);
      }
      _expectFits(tester);
    });

    testWidgets('Fly Together\'s setup fits the pseudo-locale in every mode', (
      tester,
    ) async {
      await _pumpApp(tester, '/coop', pseudo: true);
      expect(find.text(pseudo.coopTitle), findsOneWidget);
      for (final mode in CoopMode.values) {
        await tester.tap(find.byKey(ValueKey('coop-mode-${mode.name}')));
        await tester.pumpAndSettle();
        expect(find.text(pseudo.coopModeName(mode)), findsOneWidget);
        await _snap(tester, 'coop-${mode.name}-en_XA');
        _expectFits(tester);
      }
    });

    testWidgets('a roped flight, its pause and its results fit the '
        'pseudo-locale', (tester) async {
      await _pumpApp(tester, '/coop', pseudo: true);
      await tester.tap(find.byKey(const ValueKey('coop-mode-roped')));
      await tester.pumpAndSettle();
      final (game, sim) = await _start(tester);
      expect(find.text(pseudo.coopCountdownRoped), findsOneWidget);
      expect(find.text(pseudo.coopSideHint(1)), findsOneWidget);
      await _snap(tester, 'coop-countdown-en_XA');
      _expectFits(tester);
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(sim.phase, RunPhase.playing);
      await tester.tap(find.bySemanticsLabel(pseudo.coopPauseSemantics));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(pseudo.coopFinishFlight), findsOneWidget);
      await _snap(tester, 'coop-pause-en_XA');
      _expectFits(tester);
      await tester.tap(find.text(pseudo.coopFinishFlight));
      for (var i = 0; i < 20; i++) {
        game.update(.1);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text(pseudo.coopTeamScore), findsOneWidget);
      expect(find.text(pseudo.coopFlyAgain), findsOneWidget);
      await _snap(tester, 'coop-results-en_XA');
      _expectFits(tester);
    });

    testWidgets('a duel, its prizes and its results fit the pseudo-locale', (
      tester,
    ) async {
      await _pumpApp(tester, '/coop', pseudo: true);
      await tester.tap(find.byKey(const ValueKey('coop-mode-duel')));
      await tester.pumpAndSettle();
      final (game, sim) = await _start(tester);
      expect(find.text(pseudo.duelCountdown), findsOneWidget);
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      await tester.pump();
      sim.boxes.add(MysteryBox(x: sim.lead.x + .01, y: sim.lead.y, phase: 0));
      sim.partner!.starPowerUntil = sim.elapsed + Duel.starPowerSeconds;
      for (var i = 0; i < 3; i++) {
        game.update(.02);
      }
      await tester.pump();
      expect(find.byKey(const ValueKey('duel-prize-0')), findsOneWidget);
      expect(find.text(pseudo.coopPlayerCaps(2)), findsOneWidget);
      await _snap(tester, 'duel-flight-en_XA');
      _expectFits(tester);
      await _knockOut(tester, game, sim, 1);
      expect(find.text(pseudo.duelWinner(1)), findsOneWidget);
      expect(find.text(pseudo.duelHitsLanded), findsOneWidget);
      await _snap(tester, 'duel-results-en_XA');
      _expectFits(tester);
    });

    testWidgets('in Arabic the menus mirror but each player keeps their '
        'side', (tester) async {
      await _pumpApp(tester, '/coop', language: AppLanguage.ar);
      final screen = tester.element(find.text(ar.coopTitle));
      expect(Directionality.of(screen), TextDirection.rtl);
      // The header mirrors: its back key leads from the right.
      final back = tester.getCenter(find.bySemanticsLabel(ar.commonBackHome));
      expect(back.dx, greaterThan(792 / 2));
      // Player 1's card stays on the left, where they tap.
      expect(
        tester.getCenter(find.byKey(const ValueKey('coop-pick-0-2'))).dx,
        lessThan(792 / 2),
      );
      expect(
        tester.getCenter(find.byKey(const ValueKey('coop-pick-1-2'))).dx,
        greaterThan(792 / 2),
      );
      await tester.tap(find.byKey(const ValueKey('coop-mode-duel')));
      await tester.pumpAndSettle();
      await _snap(tester, 'coop-duel-ar');
      _expectFits(tester);

      final (game, sim) = await _start(tester);
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      await tester.pump();
      // Each rival's hearts stay in their own top corner.
      expect(
        tester.getCenter(find.byKey(const ValueKey('duel-health-0'))).dx,
        lessThan(792 / 4),
      );
      expect(
        tester.getCenter(find.byKey(const ValueKey('duel-health-1'))).dx,
        greaterThan(792 * 3 / 4),
      );
      final hud = tester.element(find.byKey(const ValueKey('duel-health-0')));
      expect(Directionality.of(hud), TextDirection.ltr);
      await _knockOut(tester, game, sim, 1);
      // Player 1's side of the scoreboard stays on the left.
      final names = find.text(ar.coopPlayerCaps(1));
      final rivals = find.text(ar.coopPlayerCaps(2));
      expect(
        tester.getCenter(names.last).dx,
        lessThan(tester.getCenter(rivals.last).dx),
      );
      await _snap(tester, 'duel-results-ar');
      _expectFits(tester);
    });

    testWidgets('the builder shelf in Arabic', (tester) async {
      final ready = builtLevel(PlayMode.touch, id: 'u-readylevel', name: 'Hop');
      await _pumpApp(
        tester,
        '/builder',
        language: AppLanguage.ar,
        levels: [ready],
      );
      final screen = tester.element(find.text(ar.builderShelfTitle));
      expect(Directionality.of(screen), TextDirection.rtl);
      final back = tester.getCenter(find.bySemanticsLabel(ar.commonBackHome));
      expect(back.dx, greaterThan(792 / 2));
      await _snap(tester, 'shelf-ar');
      _expectFits(tester);
      await tester.tap(find.byKey(const ValueKey('new-level')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('new-mode-touch')));
      await _settle(tester);
      await _snap(tester, 'new-level-region-ar');
      _expectFits(tester);
    });
  });
}

const _snapDir = String.fromEnvironment('L10N_S5_SNAP');

/// Saves the screen to `$L10N_S5_SNAP/<name>.png` when that is set.
Future<void> _snap(WidgetTester tester, String name) async {
  if (_snapDir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')).first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_snapDir/$name.png')
      ..parent.createSync(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _loadFonts() async {
  final families = {
    'Fredoka': ['assets/fonts/Fredoka.ttf'],
    'Nunito': ['assets/fonts/Nunito.ttf'],
    LanguageFonts.baloo: ['assets/fonts/l10n/BalooBhaijaan2.ttf'],
    'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load(file));
    }
    await loader.load();
  }
}

/// Opens the whole app at [at] at 792 x 360: in the pseudo-locale, or in
/// [language], with [levels] on the builder shelf.
Future<void> _pumpApp(
  WidgetTester tester,
  String at, {
  bool pseudo = false,
  AppLanguage language = AppLanguage.en,
  List<BuiltPlan> levels = const [],
}) async {
  tester.view.physicalSize = const Size(792, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await repo.setSetting(SettingKey.reducedMotion, true);
  await repo.setSetting(SettingKey.voices, false);
  if (language != AppLanguage.en) await repo.setLanguage(language);
  for (final plan in levels) {
    await repo.builtLevels.create(plan);
  }
  final folder = Directory.systemTemp.createTempSync('l10n-s5');
  addTearDown(() => folder.deleteSync(recursive: true));
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(() => SilentAudio()),
      trackingSourceFactoryProvider.overrideWithValue(
        () => throw StateError('these screens fly by touch'),
      ),
      if (pseudo) appLocaleProvider.overrideWithValue(pseudoLocale),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await repo.close();
  });
  await container.read(progressProvider.future);
  appRouter.go(at);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: ValueKey('visual-capture'),
        child: PushUpBirdApp(),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(PushUpBirdApp));
    for (final asset in ['pip', 'peaches', 'minty', 'orbit', 'island']) {
      await precacheImage(
        AssetImage('assets/images/$asset.png'),
        context,
      ).catchError((Object _) {});
    }
  });
  await _settle(tester);
}

/// [child] alone under a localized MaterialApp in [locale], at 792 x 360.
Future<void> _pumpBare(WidgetTester tester, Locale locale, Widget child) async {
  tester.view.physicalSize = const Size(792, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  L10n.apply(AppLanguage.en, locale: locale);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('visual-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: skyTheme(AppLanguage.en),
        locale: locale,
        supportedLocales: L10n.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// Starts the chosen co-op flight and holds its game for the test to step.
Future<(BirdGame, FlightSimulation)> _start(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('coop-start')));
  await tester.pump();
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded);
  await tester.pump();
  game.pauseEngine();
  return (game, game.simulation);
}

/// Taps a sheet's close key: the smallest thing a screen reader calls
/// [label] (the dimmed sky around the sheet answers to it too).
Future<void> _tapClose(WidgetTester tester, String label) async {
  final candidates = find.bySemanticsLabel(label).evaluate().toList();
  expect(candidates, isNotEmpty, reason: 'nothing is called $label');
  Rect rect(Element e) =>
      tester.getRect(find.byElementPredicate((x) => x == e));
  candidates.sort((a, b) {
    final ra = rect(a), rb = rect(b);
    return (ra.width * ra.height).compareTo(rb.width * rb.height);
  });
  await tester.tapAt(rect(candidates.first).center);
  await _settle(tester);
}

/// Knocks [player]'s bird out of a duel and lets the results settle.
Future<void> _knockOut(
  WidgetTester tester,
  BirdGame game,
  FlightSimulation sim,
  int player,
) async {
  final bird = sim.flock[player];
  sim.flock[1 - player].starPowerUntil = double.negativeInfinity;
  bird
    ..starPowerUntil = double.negativeInfinity
    ..invulnerableUntil = 0
    ..hearts = 1
    ..shield = false
    ..y = 1;
  game.update(.02);
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    game.update(.1);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Nothing overflows, no menu that should fit needs scrolling, no
/// shrink-to-fit label went below [FitText.minScale], and no text is cut.
void _expectFits(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    // The shelf of levels scrolls sideways by design.
    if (s.position.axis == Axis.horizontal) continue;
    expect(
      s.position.maxScrollExtent,
      0,
      reason: 'a panel needs scrolling: its words do not fit',
    );
  }
  for (final MapEntry(key: text, value: scale) in FitText.scaleIn(
    tester.binding.rootElement!,
  ).entries) {
    expect(
      scale,
      greaterThanOrEqualTo(FitText.minScale),
      reason: 'shrunk too far to fit: $text',
    );
  }
  for (final fit in tester.renderObjectList<RenderFitParagraph>(
    find.byType(FitParagraph),
  )) {
    expect(fit.cut, isFalse, reason: 'cut: ${fit.text}');
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
}
