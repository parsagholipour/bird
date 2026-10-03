// The map plays a guardian's lair scene before its card (once) and its last
// word once its level is beaten (the hook in `CampaignScreen`, merged from the
// UI step's optional patch), and the Gargoyle's ends on the "To be continued"
// card. Runs on the catalog's real data: 3-2 and 3-4 end in a guardian. The
// scenes of the story are marked watched unless a test leaves them fresh
// (`heard`, `fresh`), so a flow test that exercises one says so.
@Timeout(Duration(minutes: 4))
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/components.dart' show birdAssets;
import 'package:push_up_bird/ui/level_intro.dart';
import 'package:push_up_bird/ui/story_to_be_continued.dart';

import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio;

Future<ProviderContainer> _open(
  WidgetTester tester,
  String at,
  Set<String> beaten, {
  Set<String> heard = const {},
  Set<String> fresh = const {},
}) async {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  final folder = Directory.systemTemp.createTempSync('ny-last-word');
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, true);
    var n = 0;
    for (final level in Campaign.levels) {
      if (!beaten.contains(level.id)) continue;
      await repo.saveRun(
        levelRun(
          'seed-${n++}',
          level.id,
          stars: level.marks.two,
          at: DateTime(2026, 9, 20, 12, n),
        ),
      );
    }
    for (final chapter in Campaign.chapters.take(2)) {
      await repo.markPostcardSeen(chapter);
    }
    // Everything has been watched but New York's guardians' last words (and
    // the scenes a test asks to meet fresh). Egypt's guardian (2-6) was
    // beaten and heard long before.
    for (final scene in CampaignStory.scenes) {
      if (fresh.contains(scene.id)) continue;
      if (!scene.id.startsWith('last-3-') || heard.contains(scene.id)) {
        await repo.markStoryWatched(scene);
      }
    }
  });
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(() => SilentAudio()),
      trackingSourceFactoryProvider.overrideWithValue(
        () => throw StateError('Tap & Fly never opens the camera'),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(repo.close);
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });
  await tester.runAsync(() => container.read(progressProvider.future));
  appRouter.go(at);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PushUpBirdApp(),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in [...birdAssets, 'island']) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _chapters = {
  '1-1', '1-2', '1-3', '1-4', '1-5', '1-6', '1-7', '1-8', //
  '2-1', '2-2', '2-3', '2-4', '2-5', '2-6', '2-7', '2-8', '2-9',
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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
  setUp(() => Campaign.openedForTest = true);
  tearDown(() => Campaign.openedForTest = false);

  // The guardians' lair scenes (their voices are pending recording, so the
  // lines are written out at the pace of voices off): each plays ahead of its
  // level's card the first time, and never by itself again.
  for (final (id, boss, beaten) in [
    ('3-2', 'King Coo', {'3-1'}),
    ('3-4', 'the Searchlight Gargoyle', {'3-1', '3-2', '3-3'}),
  ]) {
    testWidgets('$boss\'s lair scene plays once before the level card of $id',
        (tester) async {
      final scene = CampaignStory.before(Campaign.level(id)!)!;
      expect(scene.id, 'before-$id');
      final container = await _open(
        tester,
        '/campaign?level=$id',
        {..._chapters, ...beaten},
        heard: {'last-3-2'},
        fresh: {scene.id},
      );
      expect(find.byKey(ValueKey('story-scene-${scene.id}')), findsOneWidget);
      expect(find.byType(LevelIntroCard), findsNothing);
      for (var i = 0; i < scene.lines.length; i++) {
        await tester.tap(find.byKey(const ValueKey('story-advance')));
        await tester.pump();
      }
      await _settle(tester);
      expect(find.byKey(ValueKey('story-scene-${scene.id}')), findsNothing);
      expect(find.byType(LevelIntroCard), findsOneWidget);
      expect(
        container.read(progressProvider).value!.campaign.storyWatched,
        contains(scene.id),
      );
    });
  }

  testWidgets('King Coo\'s last word plays once, ahead of the next card', (
    tester,
  ) async {
    final container = await _open(tester, '/campaign?level=3-3', {
      ..._chapters,
      '3-1',
      '3-2',
    });
    final scene = CampaignStory.lastWord(Campaign.level('3-2')!)!;
    expect(find.byKey(ValueKey('story-scene-${scene.id}')), findsOneWidget);
    expect(find.byType(LevelIntroCard), findsNothing);
    for (var i = 0; i < scene.lines.length; i++) {
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
    }
    await _settle(tester);
    expect(find.byKey(ValueKey('story-scene-${scene.id}')), findsNothing);
    expect(find.byType(LevelIntroCard), findsOneWidget);
    expect(
      container.read(progressProvider).value!.campaign.storyWatched,
      contains(scene.id),
    );
  });

  testWidgets('the Gargoyle\'s last word ends on the To be continued card', (
    tester,
  ) async {
    await _open(
      tester,
      '/campaign',
      {..._chapters, '3-1', '3-2', '3-3', '3-4'},
      heard: {'last-3-2'},
    );
    final scene = CampaignStory.lastWord(Campaign.level('3-4')!)!;
    expect(find.byKey(ValueKey('story-scene-${scene.id}')), findsOneWidget);
    for (var i = 0; i < scene.lines.length - 1; i++) {
      expect(find.byType(ToBeContinued), findsNothing);
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
    }
    expect(find.byType(ToBeContinued), findsOneWidget);
    expect(find.text(scene.lines.last.text), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('story-advance')));
    await _settle(tester);
    expect(find.byKey(ValueKey('story-scene-${scene.id}')), findsNothing);
    // Back on the map; its card's story key replays the scenes again.
    await tester.tap(find.byKey(const ValueKey('campaign-node-3-4')));
    await _settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('level-intro-story')));
    await _settle(tester, 2);
    expect(find.byKey(ValueKey('story-scene-${scene.id}')), findsNothing);
    expect(find.byKey(ValueKey('story-scene-before-3-4')), findsOneWidget);
  });
}
