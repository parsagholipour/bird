// Renders the campaign map's chrome (back key, star total, stop arrows,
// chapter ribbon and region title, locked nudge, Coming soon ribbon, loading
// and error states) on the real screen, over bright and dark regions.
//
// Run with `--dart-define=CAPTURE_POLISH=true` to write review PNGs to
// build/visual-review/campaign/polish/map-chrome/.
@Timeout(Duration(minutes: 8))
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/ui/campaign_chrome.dart';
import 'package:push_up_bird/ui/campaign_screen.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/level_intro.dart' show LevelIntroCard;
import 'package:push_up_bird/ui/theme.dart';

import 'campaign_save_test.dart' show levelRun;

const _capture = bool.fromEnvironment('CAPTURE_POLISH');
const _folder = 'build/visual-review/campaign/polish/map-chrome';

CampaignLevel _level(String id) => Campaign.level(id)!;

/// Chapter 1 beaten, chapter 2 under way, as the player sees it midway.
const _midway = {
  '1-1': 3,
  '1-2': 2,
  '1-3': 3,
  '1-4': 1,
  '1-5': 2,
  '1-6': 3,
  '1-7': 2,
  '1-8': 2,
  '2-1': 3,
  '2-2': 2,
};

/// Only the first two levels flown.
const _early = {'1-1': 3, '1-2': 1};

/// Both playable chapters finished.
final _done = {
  for (final chapter in Campaign.chapters.where((c) => c.playable))
    for (final level in chapter.levels) level.id: 2,
};

const _someStops = {
  'done-jungle',
  'done-brazil',
  'soon-paris',
  'soon-antarctica',
};

class _SlowRepo extends SqliteProgressRepository {
  _SlowRepo(super.db);
  Completer<ProgressSnapshot>? hold;
  @override
  Future<ProgressSnapshot> load() => hold?.future ?? super.load();
}

Future<void> _seed(ProgressRepository repo, Map<String, int> stars) async {
  var n = 0;
  for (final MapEntry(key: id, value: rating) in stars.entries) {
    final marks = _level(id).marks;
    await repo.saveRun(
      levelRun(
        'seed-${n++}',
        id,
        stars: switch (rating) {
          3 => marks.three,
          2 => marks.two,
          _ => marks.two - 5,
        },
        score: 400 + n * 30,
        at: DateTime(2026, 9, 20, 12, n),
      ),
    );
  }
  for (final chapter in Campaign.chapters) {
    if (stars.containsKey(chapter.levels.last.id)) {
      await repo.markPostcardSeen(chapter);
    }
  }
  // The story has been told, so no scene covers the map's chrome.
  for (final scene in CampaignStory.scenes) {
    await repo.markStoryWatched(scene);
  }
}

/// The real screen at [size], over an in-memory save seeded with [stars].
Future<void> _open(
  WidgetTester tester,
  Size size, {
  Map<String, int> stars = const {},
  bool reduced = true,
  int bird = 0,
  EdgeInsets padding = EdgeInsets.zero,
  SqliteProgressRepository Function(ProgressDatabase db)? repoOf,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = ProgressDatabase(NativeDatabase.memory());
  final repo = repoOf?.call(db) ?? SqliteProgressRepository(db);
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, reduced);
    await repo.equipBird(bird);
    await _seed(repo, stars);
  });
  final container = ProviderContainer(
    overrides: [progressRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(repo.close);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: skyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: padding, viewPadding: padding),
          child: RepaintBoundary(
            key: const ValueKey('polish-capture'),
            child: child,
          ),
        ),
        home: const CampaignScreen(),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in birdAssets) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Jumps the map to [stop] (0 is the Jungle), the way a swipe would end.
Future<void> _goTo(WidgetTester tester, int stop, Size size) async {
  final map = tester.state<ScrollableState>(find.byType(Scrollable));
  map.position.jumpTo(stop * size.width);
  await _settle(tester, 3);
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('polish-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
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
  // New York is open in the build as it ships (`NEW_YORK_OPEN` defaults to
  // true); a test that reads the star total forces the state it means.
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  group('chrome', () {
    const phone = Size(640, 360);

    testWidgets('the keys and the star total are full-size touch targets', (
      tester,
    ) async {
      Campaign.openedForTest = true;
      await _open(tester, phone, stars: _midway);
      await _goTo(tester, 4, phone);
      final keys = find.byType(MapKey);
      expect(keys, findsNWidgets(3));
      for (final key in keys.evaluate()) {
        final size = tester.getSize(find.byElementPredicate((e) => e == key));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(
        tester
            .getSize(find.byKey(const ValueKey('campaign-star-total')))
            .height,
        MapKey.size,
      );
      // Open, as the build ships: 20 playable levels, 60 stars.
      expect(find.bySemanticsLabel('23 of 60 campaign stars'), findsOneWidget);
    });

    testWidgets('with New York closed (NEW_YORK_OPEN=false) the star total is '
        'of 48', (tester) async {
      Campaign.closedForTest = true;
      await _open(tester, phone, stars: _midway);
      await _goTo(tester, 4, phone);
      expect(find.bySemanticsLabel('23 of 48 campaign stars'), findsOneWidget);
      expect(find.byType(MapKey), findsNWidgets(3));
    });

    testWidgets('a locked level says what unlocks it, and says it again '
        'when tapped again', (tester) async {
      await _open(tester, phone, stars: _midway, reduced: false);
      await _goTo(tester, 4, phone);
      final locked = find.byKey(const ValueKey('campaign-node-2-4'));
      await tester.tap(locked);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Finish 2-3 to unlock'), findsOneWidget);
      // Nearly gone, then tapped again: it comes back for a full stay.
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.tap(locked);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('Finish 2-3 to unlock'), findsOneWidget);
      final notice = tester.widget<Opacity>(
        find.ancestor(
          of: find.byKey(const ValueKey('campaign-nudge')),
          matching: find.byType(Opacity),
        ),
      );
      expect(notice.opacity, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Finish 2-3 to unlock'), findsNothing);
    });

    testWidgets('a stop that is not in this build answers on its ribbon, '
        'never with a second notice over it', (tester) async {
      await _open(tester, phone, stars: _done);
      await _goTo(tester, 6, phone);
      await tester.tap(find.byKey(const ValueKey('campaign-node-3-1')));
      await _settle(tester, 2);
      expect(find.byKey(const ValueKey('campaign-nudge')), findsNothing);
      // Every unreleased stop carries its ribbon; none of them is a toast.
      expect(find.text('Coming soon'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a level card takes the corner keys off the map, and closing '
        'it brings them back', (tester) async {
      await _open(tester, phone, stars: _midway);
      await _goTo(tester, 3, phone);
      expect(find.byType(MapKey), findsNWidgets(3));
      expect(find.byType(CampaignStarTotal), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('campaign-node-2-3')));
      await _settle(tester, 2);
      expect(find.byType(LevelIntroCard), findsOneWidget);
      // Cream keys would glow brighter than the dimmed scenery.
      expect(find.byType(MapKey), findsNothing);
      expect(find.byType(CampaignStarTotal), findsNothing);
      // A tap beside the card closes it.
      await tester.tapAt(const Offset(4, 180));
      await _settle(tester, 2);
      expect(find.byType(MapKey), findsNWidgets(3));
      expect(find.byType(CampaignStarTotal), findsOneWidget);
    });

    testWidgets('the notice holds still under Reduced Motion', (tester) async {
      await _open(tester, phone, stars: _midway);
      await _goTo(tester, 4, phone);
      await tester.tap(find.byKey(const ValueKey('campaign-node-2-4')));
      await tester.pump();
      expect(find.text('Finish 2-3 to unlock'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('campaign-nudge')),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Finish 2-3 to unlock'), findsNothing);
    });
  });

  group('capture', skip: !_capture, () {
    for (final size in const [
      Size(640, 360),
      Size(800, 360),
      Size(1000, 450),
    ]) {
      final w = size.width.round();

      testWidgets('bright and dark stops at $w', (tester) async {
        await _open(tester, size, stars: _done, bird: 2);
        // Every stop of the trip, so the ribbon and title meet each
        // scenery: jungle, brazil, aztec, rome, egypt, arabia, then the
        // coming-soon regions under cloud.
        for (final (name, stop) in const [
          ('done-jungle', 0),
          ('done-brazil', 1),
          ('done-aztec', 2),
          ('done-rome', 3),
          ('done-egypt', 4),
          ('done-arabia', 5),
          ('soon-new-york', 6),
          ('soon-paris', 7),
          ('soon-mexico', 8),
          ('soon-sea', 9),
          ('soon-antarctica', 10),
          ('soon-cyberpunk', 11),
          ('soon-china', 12),
        ]) {
          // The other sizes only need a bright, a dark and a snowy stop.
          if (w != 800 && !_someStops.contains(name)) continue;
          await _goTo(tester, stop, size);
          await _shot(tester, '$name-$w');
        }
      });

      testWidgets('open, locked and nudge at $w', (tester) async {
        await _open(tester, size, stars: _midway, bird: 1);
        await _goTo(tester, 3, size);
        await _shot(tester, 'midway-rome-$w');
        // A card over the map takes the keys off it.
        await tester.tap(find.byKey(const ValueKey('campaign-node-2-3')));
        await _settle(tester, 3);
        await _shot(tester, 'card-over-map-$w');
        await tester.tapAt(const Offset(2, 2));
        await _settle(tester, 2);
        // A locked level on an open chapter asks for the level before it.
        await _goTo(tester, 4, size);
        await tester.tap(find.byKey(const ValueKey('campaign-node-2-4')));
        await _settle(tester, 2);
        await _shot(tester, 'nudge-finish-$w');
        // A locked level on a coming-soon stop answers on its ribbon.
        await tester.pump(const Duration(seconds: 3));
        await _goTo(tester, 6, size);
        await tester.tap(find.byKey(const ValueKey('campaign-node-3-1')));
        await _settle(tester, 2);
        await _shot(tester, 'nudge-soon-$w');
      });

      testWidgets('motion and pressed keys at $w', (tester) async {
        await _open(tester, size, stars: _midway, reduced: false);
        await _goTo(tester, 4, size);
        // The nudge pops in, holds and fades.
        await tester.tap(find.byKey(const ValueKey('campaign-node-2-4')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));
        await _shot(tester, 'motion-nudge-pop-$w');
        await tester.pump(const Duration(milliseconds: 1000));
        await _shot(tester, 'motion-nudge-hold-$w');
        await tester.pump(const Duration(milliseconds: 1270));
        await _shot(tester, 'motion-nudge-fade-$w');
        await tester.pump(const Duration(seconds: 1));
        // The coming-soon ribbon flutters at a tap on its locked level.
        await _goTo(tester, 6, size);
        await tester.tap(find.byKey(const ValueKey('campaign-node-3-1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));
        await _shot(tester, 'motion-soon-flutter-$w');
        expect(find.byKey(const ValueKey('campaign-nudge')), findsNothing);
        await tester.pump(const Duration(seconds: 1));
        // A held press sinks the key into its lip.
        final press = await tester.startGesture(
          tester.getCenter(find.bySemanticsLabel('Next stop')),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await _shot(tester, 'motion-key-pressed-$w');
        await press.cancel();
        await tester.pump(const Duration(milliseconds: 150));
      });

      testWidgets('still pressed key at $w', (tester) async {
        await _open(tester, size, stars: _midway);
        await _goTo(tester, 4, size);
        final press = await tester.startGesture(
          tester.getCenter(find.bySemanticsLabel('Next stop')),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await _shot(tester, 'still-key-pressed-$w');
        await press.cancel();
        await tester.pump();
      });

      testWidgets('a boss in the nudge at $w', (tester) async {
        await _open(tester, size, stars: _early);
        await _goTo(tester, 3, size);
        await tester.tap(find.byKey(const ValueKey('campaign-node-2-1')));
        await _settle(tester, 2);
        await _shot(tester, 'nudge-boss-$w');
      });

      testWidgets('fresh save at $w', (tester) async {
        await _open(tester, size, reduced: false);
        await _shot(tester, 'fresh-motion-$w');
        await tester.pumpWidget(const SizedBox());
        await _open(tester, size, stars: _early);
        await _shot(tester, 'early-$w');
      });

      testWidgets('loading and error at $w', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _SlowRepo(ProgressDatabase(NativeDatabase.memory()))
          ..hold = Completer();
        final container = ProviderContainer(
          overrides: [progressRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(() async {
          container.dispose();
          await tester.runAsync(repo.close);
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: skyTheme(),
              home: RepaintBoundary(
                key: const ValueKey('polish-capture'),
                child: const CampaignScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        await _shot(tester, 'loading-$w');
        if (w == 640) {
          // With animations off the ring holds still, part filled.
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          await tester.pump();
          await _shot(tester, 'loading-still-$w');
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        }
        repo.hold!.completeError(StateError('unreadable'));
        await tester.pump();
        await tester.pump();
        await _shot(tester, 'error-$w');
      });
    }

    testWidgets('a notch and a gesture bar at 800', (tester) async {
      const size = Size(800, 360);
      await _open(
        tester,
        size,
        stars: _midway,
        padding: const EdgeInsets.fromLTRB(44, 0, 44, 20),
      );
      await _goTo(tester, 3, size);
      await _shot(tester, 'notch-rome-800');
      await _goTo(tester, 6, size);
      await _shot(tester, 'notch-soon-800');
    });
  });
}
