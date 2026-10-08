// Integration (M1, l10n-ws/MASTER-PLAN.md §6): the six extraction slices'
// screens agree on the back key under Arabic. Every round back key
// ([MapGlyph.back]) points the way back in the reading direction, so it
// sits in a right-to-left context, and on the screens whose header mirrors
// it moves to the right-hand corner; in English it stays top left.
// (Material's back arrow, on the saved sessions' app bar, counts too.)
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/campaign_chrome.dart';

import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio;

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

  Future<void> pumpApp(
    WidgetTester tester,
    String route,
    AppLanguage language,
  ) async {
    tester.view.physicalSize = const Size(792, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    await repo.setSetting(SettingKey.reducedMotion, true);
    await repo.setSetting(SettingKey.voices, false);
    await repo.setLanguage(language);
    for (final scene in CampaignStory.scenes) {
      await repo.markStoryWatched(scene);
    }
    final canopy = Campaign.chapters[0].levels;
    for (final (n, level) in canopy.indexed) {
      if (level == canopy.last) break;
      await repo.saveRun(
        levelRun(
          'qa-$n',
          level.id,
          stars: level.marks.three,
          score: 400,
          at: DateTime(2026, 10, 1, 12, n),
        ),
      );
    }
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        audioFactoryProvider.overrideWithValue(() => SilentAudio()),
        trackingSourceFactoryProvider.overrideWithValue(
          () => throw StateError('menus never open the camera'),
        ),
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
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var i = 0; i < 30 && tester.binding.hasScheduledFrame; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // Every screen with a round back key, from every slice.
  const routes = {
    '/campaign': 'S1 campaign map',
    '/coop': 'S5 Fly Together',
    '/builder': 'S5 builder shelf',
    '/builder/edit/t-tap-boss': 'S4 builder editor',
    '/daily': 'S6 daily',
    '/passport': 'S6 passport',
    '/birds': 'S6 birds',
    '/upgrades': 'S6 upgrades',
    '/records': 'S6 records',
    '/sessions': 'S6 sessions',
  };

  for (final MapEntry(key: route, value: screen) in routes.entries) {
    for (final language in [AppLanguage.en, AppLanguage.ar]) {
      testWidgets('$screen: the back key reads ${language.tag}', (
        tester,
      ) async {
        await pumpApp(tester, route, language);
        expect(tester.takeException(), isNull);
        // The round back key, or Material's back arrow (which mirrors
        // itself: matchTextDirection).
        final backs = find.byWidgetPredicate(
          (w) =>
              (w is MapKey && w.glyph == MapGlyph.back) ||
              (w is Icon && w.icon == Icons.arrow_back),
        );
        expect(backs, findsWidgets, reason: screen);
        for (final element in backs.evaluate()) {
          expect(
            Directionality.of(element),
            language.textDirection,
            reason: '$screen: the back arrow points the wrong way',
          );
        }
        final key = tester.getCenter(backs.first);
        if (language.isRtl) {
          expect(key.dx, greaterThan(396), reason: '$screen: back key side');
        } else {
          expect(key.dx, lessThan(396), reason: '$screen: back key side');
        }
      });
    }
  }
}
