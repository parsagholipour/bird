// The campaign's screens once the build opens New York (3-1 to 3-4) ahead of
// Paris: the star total, the map's Coming soon ribbons, and a locked Paris
// node. The build ships closed (campaign_screens_test covers that); these
// tests open it through `Campaign.openedForTest`.
@Timeout(Duration(minutes: 4))
library;

import 'dart:io';

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
import 'package:push_up_bird/ui/campaign_keepsake_art.dart'
    show CampaignHeadwear;
import 'package:push_up_bird/ui/components.dart' show birdAssets;
import 'package:push_up_bird/ui/level_intro.dart';

import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio;
import 'bird_unlocks.dart';

/// Every level of chapters 1 and 2 finished, their postcards seen.
Future<void> seedTwoChapters(ProgressRepository repo) async {
  var n = 0;
  for (final chapter in Campaign.chapters.take(2)) {
    for (final level in chapter.levels) {
      await repo.saveRun(
        levelRun(
          'seed-${n++}',
          level.id,
          stars: level.marks.two,
          score: 400 + n * 30,
          at: DateTime(2026, 9, 20, 12, n),
        ),
      );
    }
    await repo.markPostcardSeen(chapter);
  }
}

Future<void> open(
  WidgetTester tester,
  Size size, {
  String at = '/',
  bool twoChapters = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  final folder = Directory.systemTemp.createTempSync('campaign-opening');
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, true);
    await unlockBirds(repo);
    await repo.equipBird(0);
    if (twoChapters) await seedTwoChapters(repo);
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
  await settle(tester);
}

Future<void> settle(WidgetTester tester, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
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
  setUp(() => Campaign.openedForTest = true);
  tearDown(() => Campaign.openedForTest = false);

  const phone = Size(800, 360);

  testWidgets('Home and the map count the campaign\'s 63 stars in the build', (
    tester,
  ) async {
    await open(tester, phone);
    expect(find.text('0 / 63'), findsOneWidget);
    expect(find.text('0 / 51'), findsNothing);
    appRouter.go('/campaign');
    await settle(tester);
    expect(find.bySemanticsLabel('0 of 63 campaign stars'), findsOneWidget);
  });

  // Every stop still to come has its ribbon (they all sit in the map's tree):
  // six stops, not seven, with New York open.
  int soonStops() => Campaign.journey.where(Campaign.comingSoon).length;

  testWidgets('New York is a normal stop: no ribbon, and its card opens', (
    tester,
  ) async {
    expect(Campaign.journey.length - soonStops(), 7);
    expect(soonStops(), 6);
    await open(tester, phone, at: '/campaign', twoChapters: true);
    final map = tester.state<ScrollableState>(find.byType(Scrollable));
    map.position.jumpTo(6 * phone.width);
    await settle(tester, 2);
    expect(
      find.bySemanticsLabel(RegExp('^New York. Chapter 3, .*Coming soon')),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel(RegExp('^New York. Chapter 3, The Lamplight Line')),
      findsOneWidget,
    );
    // Paris names itself; the stops of the later chapters keep the plain one.
    expect(find.text('Coming soon'), findsNWidgets(soonStops() - 1));
    expect(find.text('Paris — coming soon'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('campaign-node-3-1')));
    await settle(tester, 2);
    expect(find.byType(LevelIntroCard), findsOneWidget);
  });

  testWidgets('Paris keeps its Coming soon ribbon and says nothing else', (
    tester,
  ) async {
    await open(tester, phone, at: '/campaign', twoChapters: true);
    final map = tester.state<ScrollableState>(find.byType(Scrollable));
    map.position.jumpTo(7 * phone.width);
    await settle(tester, 2);
    expect(
      find.bySemanticsLabel(RegExp('^Paris. Chapter 3, .*Coming soon')),
      findsOneWidget,
    );
    // Tapping a Paris node pokes the ribbon: no unlock hint, and no card.
    await tester.tap(find.byKey(const ValueKey('campaign-node-3-5')));
    await settle(tester, 2);
    expect(find.byType(LevelIntroCard), findsNothing);
    expect(find.text('Finish 3-4 to unlock'), findsNothing);
    expect(find.text('Coming soon'), findsNWidgets(soonStops() - 1));
    expect(find.text('Paris — coming soon'), findsOneWidget);
  });

  testWidgets('a locked New York node still says what unlocks it', (
    tester,
  ) async {
    await open(tester, phone, at: '/campaign', twoChapters: true);
    final map = tester.state<ScrollableState>(find.byType(Scrollable));
    map.position.jumpTo(6 * phone.width);
    await settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('campaign-node-3-3')));
    await settle(tester, 2);
    // 3-2 is the level before it: a boss level (King Coo, once the level data
    // gives him the level) is beaten, any other finished.
    final before = Campaign.level('3-2')!;
    expect(
      find.text(
        before.isBoss
            ? 'Beat ${CampaignHeadwear.name(before.boss!)} to unlock'
            : 'Finish 3-2 to unlock',
      ),
      findsOneWidget,
    );
    expect(find.byType(LevelIntroCard), findsNothing);
  });
}
