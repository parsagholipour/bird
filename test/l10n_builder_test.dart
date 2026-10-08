import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/built_code.dart';
import 'package:push_up_bird/domain/built_reach.dart';
import 'package:push_up_bird/domain/built_templates.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/language_providers.dart';
import 'package:push_up_bird/l10n/pseudo.dart';
import 'package:push_up_bird/l10n/text/builder_text.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/builder/builder_canvas.dart';
import 'package:push_up_bird/ui/builder/builder_chrome.dart';
import 'package:push_up_bird/ui/builder/builder_inspector.dart';
import 'package:push_up_bird/ui/builder/builder_timeline.dart';
import 'package:push_up_bird/ui/builder/built_result_stage.dart';
import 'package:push_up_bird/ui/campaign_chrome.dart' show MapKey;
import 'package:push_up_bird/ui/fit_text.dart';
import 'package:push_up_bird/ui/stage_key.dart';

import 'builder_ui_harness.dart'
    show BuilderApp, builtLevel, editorOf, loadBuilderFonts, settle;
import 'built_play_flow_test.dart' show flyBuiltController;
import 'built_result_stage_test.dart'
    show crash, flightController, flightGame, paintFlight, toResult;
import 'play_session_test.dart' show SessionSource, SilentAudio;

/// The Level Builder's editor, sheets and built flight's result in other
/// languages (MASTER-PLAN.md, slice S4): the English ARB stays word for
/// word the domain's English twins; share codes and level names are the
/// player's data in every language; the screens fit the reference phone
/// in the pseudo-locale; and under Arabic the menus mirror while the sky,
/// the route and the result's stars keep the flight's left to right.
void main() {
  setUpAll(loadBuilderFonts);
  tearDown(L10n.debugReset);

  final en = lookupAppLocalizations(const Locale('en'));

  group('English ARB and the domain twins', () {
    test('gate families, enemies, modes, paces and bosses', () {
      for (final kind in ObstacleKind.values) {
        expect(en.gateFamilyName(kind), kind.title, reason: kind.name);
      }
      expect(familyLine(ObstacleKind.garden, en), contains('stone door'));
      expect({
        for (final kind in EnemyKind.values) en.builtEnemyName(kind),
      }, hasLength(EnemyKind.values.length));
      expect(en.builtEnemyName(EnemyKind.simpleBat), 'Purple bat');
      expect(
        [for (final mode in PlayMode.values) builtModeName(mode, en)],
        [
          for (final mode in PlayMode.values)
            switch (mode) {
              PlayMode.touch => 'Tap & Fly',
              PlayMode.pushUp => 'Push-ups',
              PlayMode.squat => 'Squats',
              PlayMode.jump => 'Jumps',
            },
        ],
      );
      expect(
        [for (final pace in BuiltPace.values) en.builtPaceName(pace)],
        ['Relaxed', 'Steady', 'Brisk'],
      );
      for (final kind in BossKind.values) {
        expect(bossName(kind, en), en.bossName(kind));
      }
      expect(en.builtBossShort(BossKind.duskMoth), 'Empress');
      expect(en.builtBossShort(BossKind.kingCoo), 'King Coo');
      expect(
        BuiltResultStage.wordFor(finished: true, bumped: false, l: en),
        'Cleared!',
      );
      expect(
        BuiltResultStage.wordFor(finished: false, bumped: true, l: en),
        'Bonk!',
      );
    });

    test('every problem and tip reads as its English twin', () {
      for (final kind in BuiltIssueKind.values) {
        for (final mode in [PlayMode.pushUp, PlayMode.squat]) {
          final issue = BuiltIssue(
            kind,
            limit: 24,
            movement: mode,
            problem: 'marks',
          );
          expect(en.builtIssueMessage(issue), issue.message, reason: '$kind');
        }
      }
    });

    test('the issues found on real levels read the same', () {
      final plans = [
        for (final level in BuiltTemplates.all) level.plan,
        // A level with a bit of everything wrong.
        builtLevel(PlayMode.squat, id: 'u-issuelevl1', gates: 4).copyWith(
          name: '',
          marks: const StarMarks(40, 50),
          items: [
            BuiltStar(x: BuiltPlan.firstX - 300, y: 40),
            const BuiltGate(x: 4000, y: BuiltPlan.highLane, gap: 460),
            const BuiltGate(x: 4300, y: BuiltPlan.lowLane, gap: 460),
          ],
        ),
      ];
      var issues = 0;
      for (final plan in plans) {
        for (final issue in BuiltReach.check(plan)) {
          issues++;
          expect(en.builtIssueMessage(issue), issue.message);
        }
      }
      expect(issues, greaterThan(3));
    });

    test('times, workouts and new names read as before', () {
      expect(en.builtLength(42), '42 s');
      expect(en.builtLength(65), '1 min 05 s');
      expect(en.builtSeconds(12.44, digits: 1), '12.4 s');
      expect(en.builtReps(PlayMode.pushUp, 1), '1 push-up');
      expect(en.builtReps(PlayMode.squat, 12), '12 squats');
      expect(newLevelName(PlayMode.touch, const [], en), 'My tap level');
      expect(
        newLevelName(PlayMode.jump, const ['My jump level'], en),
        'My jump level 2',
      );
      expect(
        suffixedName('x' * 30, ' ${en.builderShelfRemixSuffix}', en),
        hasLength(24),
      );
    });

    test('the share line is the domain\'s, word for word', () {
      for (final level in BuiltTemplates.all) {
        for (final cleared in [false, true]) {
          expect(
            shareMessage(level.plan, cleared: cleared, l: en),
            BuiltCode.message(level.plan, cleared: cleared),
          );
        }
      }
    });
  });

  group('the player\'s own words', () {
    // A name as a player might type it: several scripts, digits, a mark.
    const name = 'قفزة Sky 2 空!';

    test('a share line in any language carries the name and the code '
        'untouched, and reads back on any phone', () {
      final plan = builtLevel(
        PlayMode.touch,
        id: 'u-sharelevl1',
      ).copyWith(name: name);
      final code = BuiltCode.encode(plan, cleared: true);
      for (final locale in L10n.supportedLocales) {
        final l = lookupAppLocalizations(locale);
        final line = shareMessage(plan, cleared: true, l: l);
        expect(line, contains(name), reason: '$locale');
        expect(line, contains(code), reason: '$locale');
        final read = BuiltCode.decode(line, id: 'u-readback01');
        expect(read.plan.name, name, reason: '$locale');
        expect(read.plan.fingerprint, plan.fingerprint, reason: '$locale');
        expect(read.cleared, isTrue);
      }
      // Arabic sets the name and the code apart from its sentence.
      final ar = lookupAppLocalizations(AppLanguage.ar.locale);
      expect(ar.playerText(name), '\u2068$name\u2069');
      expect(en.playerText(name), name);
    });

    test('a new level\'s name always leaves room for a number', () {
      for (final locale in L10n.supportedLocales) {
        final l = lookupAppLocalizations(locale);
        for (final mode in PlayMode.values) {
          final first = newLevelName(mode, const [], l);
          final second = newLevelName(mode, [first], l);
          expect(BuiltPlan.validName(first), isTrue, reason: '$locale $mode');
          expect(BuiltPlan.validName(second), isTrue, reason: '$locale $mode');
          expect(second, isNot(first));
        }
      }
    });

    test('decimal marks follow the language; digits stay Western', () {
      final de = lookupAppLocalizations(AppLanguage.de.locale);
      final ar = lookupAppLocalizations(AppLanguage.ar.locale);
      expect(de.builtSeconds(12.44, digits: 1), '12,4 s');
      expect(de.builtSeconds(12), '12 s');
      for (final locale in L10n.supportedLocales) {
        final text = lookupAppLocalizations(
          locale,
        ).builtSeconds(1234.56, digits: 1);
        expect(text, contains('1234'), reason: '$locale');
        expect(text, contains('6'), reason: '$locale');
      }
      expect(ar.builtSeconds(7.5, digits: 1), contains('7'));
    });
  });

  group('pseudo-locale fit at 792 × 360', () {
    testWidgets('an empty level\'s first steps and its summary', (
      tester,
    ) async {
      await pumpIn(
        tester,
        '/builder/edit/u-pseudoempt',
        levels: [
          builtLevel(
            PlayMode.touch,
            id: 'u-pseudoempt',
            name: 'Sky Hop',
          ).copyWith(items: const []),
        ],
        pseudo: true,
      );
      expect(find.byKey(const ValueKey('editor-coach')), findsOneWidget);
      expect(find.text(ps.builderCoachTitle), findsOneWidget);
      // The player's name is theirs: never pseudo-localized.
      expect(find.text('Sky Hop'), findsOneWidget);
      expectFits(tester, 'empty level');
    });

    testWidgets('a gate\'s, a star\'s and an enemy\'s panels', (tester) async {
      await pumpIn(
        tester,
        '/builder/edit/u-pseudogate',
        levels: [builtLevel(PlayMode.touch, id: 'u-pseudogate')],
        pseudo: true,
      );
      expectFits(tester, 'summary');
      final c = editorOf(tester);
      for (final what in <String, bool Function(BuiltItem)>{
        'moving gate': (i) => i is BuiltGate && i.moving,
        'garden gate': (i) => i is BuiltGate && !i.moving,
        'trio': (i) => i is BuiltTrio,
        'heart': (i) => i is BuiltHeart,
        'enemy': (i) => i is BuiltEnemy,
      }.entries) {
        final entry = c.draft.items.firstWhere((e) => what.value(e.item));
        c.scrollTo(entry.item.x / BuiltPlan.unit - .8);
        c.select(entry.key);
        await settle(tester);
        expectFits(tester, what.key);
        // The rest of the panel, a scroll away.
        await tester.drag(
          find
              .descendant(
                of: find.byType(BuilderInspector),
                matching: find.byType(Scrollable),
              )
              .first,
          const Offset(0, -600),
        );
        await settle(tester);
        expectFits(tester, '${what.key}, scrolled');
      }
      expect(
        find.descendant(
          of: find.byType(BuilderInspector),
          matching: find.text(ps.builderItemEnemy),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the settings, problems and gate family sheets', (
      tester,
    ) async {
      final level = builtLevel(PlayMode.touch, id: 'u-pseudoshet');
      await pumpIn(
        tester,
        '/builder/edit/u-pseudoshet',
        levels: [
          level.copyWith(
            items: [
              ...level.items,
              // A problem and a tip for the problems sheet.
              BuiltStar(x: level.finish + 100, y: 500),
              BuiltStar(x: level.gates.first.x + 20, y: 30),
            ],
          ),
        ],
        pseudo: true,
      );
      await tester.tap(find.byTooltip(ps.builderSettingsSemantics));
      await settle(tester);
      expect(find.byKey(const ValueKey('settings-sheet')), findsOneWidget);
      expectFits(tester, 'settings');
      Navigator.of(
        tester.element(find.byKey(const ValueKey('settings-sheet'))),
      ).pop();
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('editor-issues')));
      await settle(tester);
      expect(find.text(ps.builderIssuesFixTitle), findsOneWidget);
      expectFits(tester, 'problems and tips');
      await tester.tap(find.byTooltip(ps.builderIssuesCloseSemantics));
      await settle(tester);

      final c = editorOf(tester);
      c.select(c.draft.items.firstWhere((e) => e.item is BuiltGate).key);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('gate-family')));
      await settle(tester);
      expect(find.byKey(const ValueKey('family-crystalSteps')), findsOneWidget);
      expectFits(tester, 'gate families');
    });

    testWidgets('a push-up level\'s lanes, panels and settings', (
      tester,
    ) async {
      await pumpIn(
        tester,
        '/builder/edit/u-pseudopush',
        levels: [builtLevel(PlayMode.pushUp, id: 'u-pseudopush')],
        pseudo: true,
      );
      expectFits(tester, 'push-up summary');
      final c = editorOf(tester);
      c.select(c.draft.items.firstWhere((e) => e.item is BuiltGate).key);
      await settle(tester);
      expect(find.text(L10n.upper(ps.builderLane)), findsOneWidget);
      expectFits(tester, 'push-up gate');
      c.select(c.draft.items.firstWhere((e) => e.item is BuiltTrio).key);
      await settle(tester);
      expectFits(tester, 'push-up trio');
      await tester.tap(find.byTooltip(ps.builderSettingsSemantics));
      await settle(tester);
      expectFits(tester, 'push-up settings');
    });

    testWidgets('a starter level to look at and remix', (tester) async {
      await pumpIn(tester, '/builder/edit/t-tap-boss', pseudo: true);
      expect(find.byKey(const ValueKey('starter-banner')), findsOneWidget);
      expectFits(tester, 'starter level');
    });

    testWidgets('a test flight\'s clear and a bumped flight\'s result', (
      tester,
    ) async {
      final level = builtLevel(
        PlayMode.touch,
        id: 'u-pseudoflt1',
        name: 'Sky Hop',
      );
      var (c, game) = await flyIn(
        tester,
        '/play/touch?built=u-pseudoflt1&test=1',
        levels: [level],
        pseudo: true,
      );
      flyBuiltController(c);
      await toResult(tester, c);
      await paintFlight(tester, game);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(BuiltResultStage), findsOneWidget);
      expect(find.text(ps.builtResultClearedByYou), findsOneWidget);
      expect(find.text('Sky Hop'), findsOneWidget);
      expectFits(tester, 'test cleared');

      await tester.runAsync(c.retry);
      game = await flightGame(tester);
      flyBuiltController(c, seconds: 8);
      crash(c);
      await tester.runAsync(c.finish);
      c.knockout = 99;
      c.skipKnockout();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await paintFlight(tester, game);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(ps.builtResultTestNothingSaved), findsOneWidget);
      expectFits(tester, 'test bumped');
    });

    testWidgets('a squat level\'s test flight from a place', (tester) async {
      final level = builtLevel(PlayMode.squat, id: 'u-pseudoflt2');
      final (c, game) = await flyIn(
        tester,
        '/play/squat?built=u-pseudoflt2&test=1&from=4000',
        levels: [level],
        pseudo: true,
      );
      flyBuiltController(c);
      await toResult(tester, c);
      await paintFlight(tester, game);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(ps.builtResultAsksFor), findsOneWidget);
      expectFits(tester, 'squat test result');
    });
  });

  group('Arabic', () {
    testWidgets('the editor\'s menus mirror; the sky, the route strip and '
        'the place keys run left to right; the name is the player\'s', (
      tester,
    ) async {
      const name = 'قفزة Sky 2';
      await pumpIn(
        tester,
        '/builder/edit/u-arabiclvl1',
        levels: [
          builtLevel(
            PlayMode.touch,
            id: 'u-arabiclvl1',
            name: name,
            region: WorldRegion.china,
          ),
        ],
        language: AppLanguage.ar,
      );
      final ar = lookupAppLocalizations(AppLanguage.ar.locale);
      expect(L10n.language.value, AppLanguage.ar);
      expect(
        Directionality.of(tester.element(find.byType(BuilderInspector))),
        TextDirection.rtl,
      );
      expect(
        Directionality.of(tester.element(find.byType(BuilderCanvas))),
        TextDirection.ltr,
      );
      expect(
        Directionality.of(tester.element(find.byType(BuilderTimeline))),
        TextDirection.ltr,
      );
      // The back key leads the top bar from the right.
      final back = tester.getCenter(
        find.byWidgetPredicate(
          (w) => w is MapKey && w.label == ar.builderEditorBackSemantics,
        ),
      );
      expect(back.dx, greaterThan(792 / 2));
      expect(find.text(name), findsOneWidget);

      final c = editorOf(tester);
      c.select(c.draft.items.firstWhere((e) => e.item is BuiltGate).key);
      await settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('place-less')));
      await settle(tester);
      // Earlier is to the left, as on the sky.
      expect(
        tester.getCenter(find.byKey(const ValueKey('place-less'))).dx,
        lessThan(tester.getCenter(find.byKey(const ValueKey('place-more'))).dx),
      );
      // The opening's keys mirror with the menus.
      expect(
        tester.getCenter(find.byKey(const ValueKey('opening-less'))).dx,
        greaterThan(
          tester.getCenter(find.byKey(const ValueKey('opening-more'))).dx,
        ),
      );
      expect(tester.takeException(), isNull);

      // The settings' region strip runs the reading way and opens on the
      // level's own region.
      await tester.tap(find.byTooltip(ar.builderSettingsSemantics));
      await settle(tester);
      final strip = tester.getRect(
        find
            .ancestor(
              of: find.byKey(const ValueKey('settings-region-china')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final china = tester.getRect(
        find.byKey(const ValueKey('settings-region-china')),
      );
      expect(strip.contains(china.center), isTrue, reason: '$china in $strip');
      expect(
        tester
            .getCenter(find.byKey(const ValueKey('settings-region-cyberpunk')))
            .dx,
        greaterThan(china.center.dx),
      );
      expect(tester.takeException(), isNull);
      Navigator.of(
        tester.element(find.byKey(const ValueKey('settings-sheet'))),
      ).pop();
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('editor-issues')));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the result\'s word drops in whole and its goals keep the '
        'stars\' order', (tester) async {
      final level = builtLevel(PlayMode.touch, id: 'u-arabicflt1');
      final (c, game) = await flyIn(
        tester,
        '/play/touch?built=u-arabicflt1',
        levels: [level],
        language: AppLanguage.ar,
      );
      flyBuiltController(c);
      await toResult(tester, c);
      await paintFlight(tester, game);
      await tester.pump(const Duration(seconds: 2));
      final ar = lookupAppLocalizations(AppLanguage.ar.locale);
      // Shadow, outline and fill: one piece each, not letter by letter.
      expect(find.text(ar.builtResultCleared), findsNWidgets(3));
      final finish = tester.getCenter(find.text(ar.builtResultGoalFinish));
      final marks = find.text('${level.marks.three}');
      expect(finish.dx, lessThan(tester.getCenter(marks.last).dx));
      expect(tester.takeException(), isNull);
    });
  });
}

/// The pseudo-locale's words.
final ps = lookupAppLocalizations(pseudoLocale);

/// Opens the app at [at] on the reference phone with [levels] kept, in
/// [language] (or the pseudo-locale), Reduced Motion on.
Future<BuilderApp> pumpIn(
  WidgetTester tester,
  String at, {
  List<BuiltPlan> levels = const [],
  AppLanguage? language,
  bool pseudo = false,
}) async {
  tester.view.physicalSize = const Size(792, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await repo.setSetting(SettingKey.reducedMotion, true);
  if (language != null) await repo.setLanguage(language);
  for (final plan in levels) {
    await repo.builtLevels.create(plan);
  }
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      audioFactoryProvider.overrideWithValue(SilentAudio.new),
      trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
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
  await settle(tester);
  return BuilderApp(repo, container);
}

/// Opens a built level's flight at [at], its game loaded and stopped.
Future<(PlayController, BirdGame)> flyIn(
  WidgetTester tester,
  String at, {
  required List<BuiltPlan> levels,
  AppLanguage? language,
  bool pseudo = false,
}) async {
  await pumpIn(
    tester,
    '/builder',
    levels: levels,
    language: language,
    pseudo: pseudo,
  );
  appRouter.go(at);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  final game = await flightGame(tester);
  return (flightController(tester), game);
}

/// What a screen in the pseudo-locale keeps to: no overflow or other
/// error, no [FitText] shrunk below [FitText.minScale], no cut paragraph,
/// and no key whose label has to shrink past [keys] of its size.
void expectFits(WidgetTester tester, String where, {double keys = .5}) {
  final error = tester.takeException();
  expect(error, isNull, reason: '$where: $error ${overflowing(tester)}');
  final root = tester.binding.rootElement!;
  for (final MapEntry(key: text, value: scale) in FitText.scaleIn(
    root,
  ).entries) {
    expect(
      scale,
      greaterThanOrEqualTo(FitText.minScale),
      reason: '$where: shrunk too far to fit: $text',
    );
  }
  for (final fit in tester.renderObjectList<RenderFitParagraph>(
    find.byType(FitParagraph),
  )) {
    expect(fit.cut, isFalse, reason: '$where: cut: ${fit.text}');
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
  for (final MapEntry(key: label, value: scale) in keyLabelScales(
    tester,
  ).entries) {
    expect(
      scale,
      greaterThanOrEqualTo(keys),
      reason: '$where: key label shrunk to ${scale.toStringAsFixed(2)}: $label',
    );
  }
}

/// How far each key's label (a [BuilderKey], [StageKey] or the result's
/// small keys) shrinks to fit its key, by its words.
Map<String, double> keyLabelScales(WidgetTester tester) {
  final out = <String, double>{};
  bool icon(String text) =>
      text.runes.every((r) => (r >= 0xe000 && r <= 0xf8ff) || r >= 0xf0000);
  for (final type in [BuilderKey, StageKey]) {
    for (final key in find.byType(type).evaluate()) {
      void visit(Element e) {
        final box = e.renderObject;
        if (e.widget is FittedBox &&
            box is RenderFittedBox &&
            box.hasSize &&
            box.child != null &&
            box.child!.hasSize &&
            box.child!.size.width > 0) {
          final words = <String>[];
          void texts(Element t) {
            final w = t.widget;
            if (w is RichText) {
              final text = w.text.toPlainText();
              if (text.trim().isNotEmpty && !icon(text)) words.add(text);
            }
            t.visitChildren(texts);
          }

          e.visitChildren(texts);
          if (words.isNotEmpty) {
            final scale = (box.size.width / box.child!.size.width).clamp(
              0.0,
              1.0,
            );
            final label = words.join(' ');
            out[label] = math.min(out[label] ?? 1, scale);
          }
        }
        e.visitChildren(visit);
      }

      visit(key);
    }
  }
  return out;
}

/// The rows and columns whose children run past them, by their words.
List<String> overflowing(WidgetTester tester) {
  final out = <String>[];
  for (final flex in tester.renderObjectList<RenderFlex>(
    find.byWidgetPredicate((w) => w is Flex),
  )) {
    if (!flex.hasSize) continue;
    var used = 0.0;
    var child = flex.firstChild;
    while (child != null) {
      if (child.hasSize) {
        used += flex.direction == Axis.horizontal
            ? child.size.width
            : child.size.height;
      }
      child = flex.childAfter(child);
    }
    final room = flex.direction == Axis.horizontal
        ? flex.size.width
        : flex.size.height;
    if (used > room + .5) {
      final words = <String>[];
      void visit(RenderObject r) {
        if (r is RenderParagraph) words.add(r.text.toPlainText());
        r.visitChildren(visit);
      }

      visit(flex);
      out.add(
        '${used.toStringAsFixed(0)} > ${room.toStringAsFixed(0)}: '
        '${words.join(' | ')}',
      );
    }
  }
  return out;
}
