import 'dart:io';
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
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/language_providers.dart';
import 'package:push_up_bird/l10n/pseudo.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/fit_text.dart';
import 'package:push_up_bird/ui/language_picker.dart';
import 'package:push_up_bird/ui/settings_screen.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'play_session_test.dart' show SilentAudio;

/// The localization's reference slice on screen: Settings and its language
/// picker in the pseudo-locale and in Arabic at the reference phone's
/// 792 × 360, and the flight staying left to right under Arabic menus.
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

  Future<(ProviderContainer, SqliteProgressRepository)> pumpSettings(
    WidgetTester tester,
    Locale locale, {
    AppLanguage language = AppLanguage.en,
  }) async {
    tester.view.physicalSize = const Size(792, 360) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    final container = ProviderContainer(
      overrides: [progressRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
    });
    await container.read(progressProvider.future);
    L10n.apply(language, locale: locale);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: const ValueKey('visual-capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: skyTheme(language),
            locale: locale,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pumpAndSettle();
    return (container, repo);
  }

  /// Nothing scrolls that should fit, and no text is cut.
  void expectFits(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    for (final s in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
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
      expect(
        fit.scale,
        greaterThanOrEqualTo(FitText.minScale),
        reason: fit.text,
      );
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

  testWidgets('Settings fit the reference phone in the pseudo-locale', (
    tester,
  ) async {
    await pumpSettings(tester, pseudoLocale);
    // The words are the stretched pseudo ones, all of them.
    expect(
      find.text(lookupAppLocalizations(pseudoLocale).settingsTitle),
      findsOneWidget,
    );
    expect(find.text('Sound effects'), findsNothing);
    await _snap(tester, 'settings-en_XA');
    expectFits(tester);
  });

  testWidgets('the language picker fits in the pseudo-locale', (tester) async {
    await pumpSettings(tester, pseudoLocale);
    await tester.tap(find.byKey(const ValueKey('language-key')));
    await tester.pumpAndSettle();
    expect(find.byType(LanguagePicker), findsOneWidget);
    await _snap(tester, 'picker-en_XA');
    expectFits(tester);
    for (final language in AppLanguage.values) {
      expect(find.byKey(ValueKey('language-${language.slug}')), findsOne);
    }
  });

  testWidgets('Arabic mirrors Settings and keeps them whole', (tester) async {
    await pumpSettings(tester, AppLanguage.ar.locale, language: AppLanguage.ar);
    final context = tester.element(find.byType(SettingsScreen));
    expect(Directionality.of(context), TextDirection.rtl);
    // The back key leads the header from the right.
    final back = tester.getCenter(
      find.bySemanticsLabel(
        lookupAppLocalizations(AppLanguage.ar.locale).commonBackHome,
      ),
    );
    expect(back.dx, greaterThan(792 / 2));
    await _snap(tester, 'settings-ar');
    expectFits(tester);
  });

  testWidgets('choosing a language saves it, System default clears it', (
    tester,
  ) async {
    final (container, repo) = await pumpSettings(tester, const Locale('en'));
    await tester.tap(find.byKey(const ValueKey('language-key')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-de')));
    await tester.pumpAndSettle();
    expect(find.byType(LanguagePicker), findsNothing);
    expect((await repo.load()).settings.language, AppLanguage.de);
    expect(container.read(appLanguageProvider), AppLanguage.de);
    expect(find.text('Deutsch'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('language-key')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-system')));
    await tester.pumpAndSettle();
    expect((await repo.load()).settings.language, isNull);
    expect(container.read(appLanguageProvider), AppLanguage.en);
  });

  testWidgets('Arabic menus mirror while the flight stays left to right', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(792, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    await repo.setSetting(SettingKey.reducedMotion, true);
    await repo.setLanguage(AppLanguage.ar);
    final folder = Directory.systemTemp.createTempSync('l10n-flight');
    addTearDown(() => folder.deleteSync(recursive: true));
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
        audioFactoryProvider.overrideWithValue(() => SilentAudio()),
        trackingSourceFactoryProvider.overrideWithValue(
          () => throw StateError('Touch must not create a camera'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(progressProvider.future);
    appRouter.go('/settings');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PushUpBirdApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The app root keeps the global (canvas) language in step.
    expect(L10n.language.value, AppLanguage.ar);
    expect(L10n.textDirection, TextDirection.rtl);
    expect(
      Directionality.of(tester.element(find.byType(SettingsScreen))),
      TextDirection.rtl,
    );

    appRouter.go('/play/touch');
    await tester.pump();
    await tester.pump();
    final view = find.byType(GameWidget<BirdGame>);
    expect(Directionality.of(tester.element(view)), TextDirection.ltr);
    final game = tester.widget<GameWidget<BirdGame>>(view).game!;
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    expect(tester.takeException(), isNull);
    appRouter.go('/');
    await tester.pumpAndSettle();
  });
}

/// Writes build/visual-review/l10n/NAME.png with
/// --dart-define=CAPTURE_VISUALS=true; nothing otherwise.
Future<void> _snap(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/visual-review/l10n')
      ..createSync(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
