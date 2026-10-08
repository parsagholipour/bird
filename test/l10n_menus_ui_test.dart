import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/language_providers.dart';
import 'package:push_up_bird/l10n/pseudo.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/fit_text.dart';
import 'package:push_up_bird/ui/mini_chrome.dart';

import 'campaign_save_test.dart' show levelRun, trailRun;
import 'play_session_test.dart' show SilentAudio;
import 'replay_highlights_test.dart' show recordRoute;

/// Slice S6's screens (title screen, mini games, birds, upgrades, passport,
/// daily Adventure, records, saved sessions and a replay with its
/// highlights) at the reference phone's 792 × 360: English keeps its exact
/// look, the pseudo-locale's longer words fit, and Arabic mirrors the menus
/// while the replay's timeline keeps running left to right.
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

  late Directory sessions;
  setUpAll(() async {
    sessions = Directory.systemTemp.createTempSync('l10n-menus');
    // One saved endless flight, long enough to have highlights.
    final tape = recordRoute(FlightCourse.starTrail, seconds: 25);
    await SessionRepository(sessions).save(
      SavedSession(
        result: trailRun('qa-endless', at: DateTime(2026, 10, 1, 18, 5)),
        tape: tape,
        clips: const [],
      ),
    );
  });
  tearDownAll(() => sessions.deleteSync(recursive: true));

  /// The real app on [route] in [locale] (English, the pseudo-locale or a
  /// language's own), with the Canopy Route flown up to its boss and a
  /// couple of endless flights.
  Future<void> pumpApp(
    WidgetTester tester,
    String route, {
    Locale? locale,
    AppLanguage? language,
  }) async {
    tester.view.physicalSize = const Size(792, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    await repo.setSetting(SettingKey.reducedMotion, true);
    await repo.setSetting(SettingKey.voices, false);
    if (language != null) await repo.setLanguage(language);
    final canopy = Campaign.chapters[0].levels;
    for (final (n, level) in canopy.indexed) {
      if (level == canopy.last) break;
      await repo.saveRun(
        levelRun(
          'qa-$n',
          level.id,
          stars: level.marks.three,
          score: 400 + n * 40,
          at: DateTime(2026, 10, 1, 12, n),
        ),
      );
    }
    await repo.saveRun(trailRun('qa-trail', score: 1240, stars: 900));
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(
          SessionRepository(sessions),
        ),
        audioFactoryProvider.overrideWithValue(() => SilentAudio()),
        trackingSourceFactoryProvider.overrideWithValue(
          () => throw StateError('menus never open the camera'),
        ),
        if (locale != null) appLocaleProvider.overrideWithValue(locale),
      ],
    );
    addTearDown(() async {
      appRouter.go('/');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
    });
    await container.read(progressProvider.future);
    appRouter.go(route);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PushUpBirdApp(),
      ),
    );
    await settle(tester);
  }

  /// Nothing scrolls that should fit, nothing is cut, and no single-line
  /// label shrinks below [minScale] ([FitText.minScale] in the
  /// pseudo-locale; 1, i.e. not at all, in English).
  void expectFits(WidgetTester tester, String where, {double? minScale}) {
    expect(tester.takeException(), isNull, reason: where);
    // The screen has loaded: no spinner left.
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: where);
    for (final s in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      if (s.widget.axisDirection == AxisDirection.down &&
          s.context.findAncestorWidgetOfExactType<ListView>() != null) {
        continue; // A list of sessions or highlights scrolls by design.
      }
      expect(
        s.position.maxScrollExtent,
        0,
        reason: '$where: a panel needs scrolling',
      );
    }
    for (final MapEntry(key: text, value: scale) in FitText.scaleIn(
      tester.binding.rootElement!,
    ).entries) {
      expect(
        scale,
        greaterThanOrEqualTo((minScale ?? FitText.minScale) - .001),
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
  }

  /// Each screen, and what to do on it before looking.
  final screens = <(String, String, Future<void> Function(WidgetTester)?)>[
    ('home', '/', null),
    (
      'mini games',
      '/',
      (t) => tap(t, find.byKey(const ValueKey('mini-games'))),
    ),
    ('daily', '/daily', null),
    ('passport', '/passport', null),
    ('birds', '/birds', null),
    (
      'birds: locked Pip',
      '/birds',
      (t) => tap(t, find.byKey(const ValueKey('bird-card-0'))),
    ),
    (
      'birds: Peaches',
      '/birds',
      (t) => tap(t, find.byKey(const ValueKey('bird-card-1'))),
    ),
    ('upgrades', '/upgrades', null),
    (
      'upgrades: magnet',
      '/upgrades',
      (t) => tap(t, find.byKey(const ValueKey('upgrade-card-magnet'))),
    ),
    ('records', '/records', null),
    ('sessions', '/sessions', null),
    ('replay', '/replay/qa-endless', null),
    ('replay highlights', '/replay/qa-endless', openHighlights),
  ];

  for (final (name, route, act) in screens) {
    testWidgets('$name: English keeps its look', (tester) async {
      await pumpApp(tester, route);
      await act?.call(tester);
      // The English words fit as they always have: nothing shrinks.
      expectFits(tester, name, minScale: 1);
    });

    testWidgets('$name fits in the pseudo-locale', (tester) async {
      await pumpApp(tester, route, locale: pseudoLocale);
      await act?.call(tester);
      expectFits(tester, name);
    });

    testWidgets('$name in Arabic', (tester) async {
      await pumpApp(tester, route, language: AppLanguage.ar);
      await act?.call(tester);
      expectFits(tester, name);
    });
  }

  testWidgets('Arabic menus mirror; the replay timeline does not', (
    tester,
  ) async {
    await pumpApp(tester, '/passport', language: AppLanguage.ar);
    final header = find.byType(MiniHeader);
    expect(Directionality.of(tester.element(header)), TextDirection.rtl);
    // The back key leads the header from the right.
    expect(
      tester
          .getCenter(
            find.bySemanticsLabel(
              lookupAppLocalizations(AppLanguage.ar.locale).commonBackHome,
            ),
          )
          .dx,
      greaterThan(792 / 2),
    );

    appRouter.go('/replay/qa-endless');
    await settle(tester);
    final controls = find.byKey(const ValueKey('replay-controls'));
    expect(Directionality.of(tester.element(controls)), TextDirection.ltr);
    final slider = tester.getRect(find.byType(Slider));
    final restart = tester.getCenter(find.byIcon(Icons.replay));
    expect(restart.dx, lessThan(slider.center.dx));
  });

  testWidgets('the pseudo-locale reaches the records and sessions', (
    tester,
  ) async {
    final pseudo = lookupAppLocalizations(pseudoLocale);
    await pumpApp(tester, '/records', locale: pseudoLocale);
    expect(find.text(pseudo.recordsRecentTitle), findsOneWidget);
    expect(find.text('Recent flights'), findsNothing);
    appRouter.go('/sessions');
    await settle(tester);
    expect(find.text(pseudo.replaySavedSessions), findsOneWidget);
    // The date and numbers stay; the words around them are the pseudo ones.
    expect(find.textContaining('2026-10-01 18:05 · 40 '), findsOneWidget);
    expect(find.textContaining('star points'), findsNothing);
  });
}

/// Lets file loads (saved sessions) finish and animations end; a ticker
/// that never stops (the replay's) ends it after three seconds of frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  for (var i = 0; i < 30 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder.first);
  await settle(tester);
}

/// Waits for the replay's highlights, then opens them.
Future<void> openHighlights(WidgetTester tester) async {
  final button = find.byIcon(Icons.movie_filter_rounded);
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    final enabled =
        tester
            .widget<IconButton>(
              find.ancestor(of: button, matching: find.byType(IconButton)),
            )
            .onPressed !=
        null;
    if (enabled) break;
  }
  await tap(tester, button);
  expect(find.byKey(const ValueKey('replay-highlight-0')), findsOneWidget);
}
