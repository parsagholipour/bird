// The results stage's calm moment ends with the stage: leaving it for the
// campaign map (where a fallen boss's story scene plays) never leaves the map
// marked calm, even when the stage's settle timer runs out after the tap,
// while the page is still on its way out.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/story_scene.dart';

import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio;

/// Records the calm moments the app asks for, and sends nothing.
class _Spy extends PlayGamesSync {
  int calmMoments = 0;
  @override
  Future<void> calmMoment() async => calmMoments++;
  @override
  Future<void> paused() async {}
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  final chapter = Campaign.chapters.first;

  /// Chapter 1 beaten to its boss, whose story scene is still due on the
  /// map; the boss's level is open again on screen.
  Future<_Spy> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    final folder = Directory.systemTemp.createTempSync('calm-route');
    await tester.runAsync(() async {
      await repo.setSetting(SettingKey.reducedMotion, true);
      var n = 0;
      for (final level in chapter.levels) {
        await repo.saveRun(
          levelRun(
            'seed-${n++}',
            level.id,
            stars: level.marks.three,
            at: DateTime(2026, 10, 6, 12, n),
          ),
        );
      }
      for (final scene in CampaignStory.scenes) {
        if (scene.id != CampaignStory.after(chapter).id) {
          await repo.markStoryWatched(scene);
        }
      }
    });
    final spy = _Spy();
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
        audioFactoryProvider.overrideWithValue(() => SilentAudio()),
        trackingSourceFactoryProvider.overrideWithValue(
          () => throw StateError('Tap & Fly never opens the camera'),
        ),
        playGamesProvider.overrideWith(() => spy),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.runAsync(repo.close);
      if (folder.existsSync()) folder.deleteSync(recursive: true);
    });
    final progress = await tester.runAsync(
      () => container.read(progressProvider.future),
    );
    expect(progress!.campaign.sceneAfter(chapter), isNotNull);
    appRouter.go('/play/touch?level=${chapter.bossLevel.id}');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PushUpBirdApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return spy;
  }

  dynamic screen(WidgetTester tester) => tester.state(find.byType(PlayScreen));
  PlayController controller(WidgetTester tester) =>
      screen(tester).controller as PlayController;

  /// Ends the flight from its pause card and waits out its save.
  Future<void> finish(WidgetTester tester) async {
    final c = controller(tester);
    expect(c.stage, PlayStage.flying);
    c.endFlight();
    for (var i = 0; i < 20 && !c.saved; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(c.stage, PlayStage.results);
    expect(c.saved, isTrue);
  }

  /// Leaves the results stage for the map: [first] passes before the map's
  /// first frame, then the map's story scene plays for a while.
  Future<void> toMap(WidgetTester tester, Duration first) async {
    final out = screen(tester).leave('/campaign') as Future<void>;
    await tester.pump(first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await out;
    expect(find.byType(PlayScreen), findsNothing);
    expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/campaign');
    expect(
      find.byKey(ValueKey('story-scene-${CampaignStory.after(chapter).id}')),
      findsOneWidget,
      reason: "the fallen boss's story plays on the map",
    );
    expect(find.byType(StoryScenePlayer), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets("the stage settling as its page leaves for the boss's story "
      'never marks the map calm', (tester) async {
    final spy = await open(tester);
    await finish(tester);
    // Just short of the 2.5 s settle: the moment has not begun.
    await tester.pump(const Duration(milliseconds: 2300));
    expect(spy.calm, isFalse);
    expect(spy.calmMoments, 0);

    // Map: the settle time runs out after the tap, before the page is gone.
    await toMap(tester, const Duration(milliseconds: 400));
    expect(spy.calm, isFalse, reason: 'the story scene is not calm');
    expect(spy.calmMoments, 0, reason: 'no sync or pop-up on the way out');
  });

  testWidgets('leaving a settled results stage for the map ends its calm '
      'moment', (tester) async {
    final spy = await open(tester);
    await finish(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(spy.calm, isTrue, reason: 'the settled stage is calm');
    expect(spy.calmMoments, 1);

    await toMap(tester, Duration.zero);
    expect(spy.calm, isFalse, reason: 'the story scene is not calm');
    expect(spy.calmMoments, 1);
  });
}
