// The campaign's screens in the real app: Home's Campaign key, the map, the
// level card, a level's flight, its result, the failure stage and the
// chapter postcard, with progress saved through the in-memory database.
//
// Run with `--dart-define=CAPTURE_CAMPAIGN_SCREENS=true` to also write review
// PNGs to build/visual-review/campaign/screens/.
@Timeout(Duration(minutes: 8))
library;

import 'dart:async';
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
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/audio.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/knockout_art.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/campaign_map.dart';
import 'package:push_up_bird/ui/campaign_postcard.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/game_over_stage.dart';
import 'package:push_up_bird/ui/level_intro.dart';
import 'package:push_up_bird/ui/level_result.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/replay_screen.dart' show sessionTitle;
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/screen_frame.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'campaign_flight.dart' show recordLevel;
import 'campaign_save_test.dart' show levelRun;
import 'fake_video_platform.dart';
import 'play_session_test.dart' show SilentAudio;
import 'recorded_flight.dart' show rideTheSky;
import 'bird_unlocks.dart';

const _capture = bool.fromEnvironment('CAPTURE_CAMPAIGN_SCREENS');
const _folder = 'build/visual-review/campaign/screens';

CampaignLevel _level(String id) => Campaign.level(id)!;

/// A save where each level in [stars] was finished with that many stars.
/// Chapters in [postcards] have had their postcard shown.
Future<void> _seed(
  ProgressRepository repo,
  Map<String, int> stars, {
  Set<int> postcards = const {},
}) async {
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
  for (final chapter in postcards) {
    await repo.markPostcardSeen(Campaign.chapters[chapter - 1]);
  }
}

/// Chapter 1 done up to its boss, whose postcard waits.
const _bossBeaten = {
  '1-1': 3,
  '1-2': 2,
  '1-3': 3,
  '1-4': 1,
  '1-5': 2,
  '1-6': 3,
  '1-7': 2,
  '1-8': 2,
};

/// Partway through chapter 2, chapter 1's postcard already seen.
const _midway = {..._bossBeaten, '2-1': 3, '2-2': 2};

/// A save that loads only when [hold] completes, if it is set.
class _SlowRepo extends SqliteProgressRepository {
  _SlowRepo(super.db);
  Completer<ProgressSnapshot>? hold;
  @override
  Future<ProgressSnapshot> load() => hold?.future ?? super.load();
}

/// Keeps the name of every effect played.
class _HeardAudio extends SilentAudio {
  final heard = <String>[];

  /// The recorded lines spoken, in order.
  final said = <String>[];
  @override
  void effect(String name, {int? variant}) => heard.add(name);
  @override
  void speak(String asset, {double duck = .35}) => said.add(asset);
}

class _App {
  _App(this.container, this.repo);
  final ProviderContainer container;
  final SqliteProgressRepository repo;
  ProgressSnapshot get progress =>
      container.read(progressProvider).requireValue;
}

/// The whole app at [size], opened on [at], over an in-memory save seeded
/// with [stars]. The story's scenes have all been watched already unless
/// [story] is set, so a test of anything else meets no scene on the way.
Future<_App> _open(
  WidgetTester tester,
  Size size, {
  String at = '/',
  bool reduced = true,
  Map<String, int> stars = const {},
  Set<int> postcards = const {},
  bool story = false,
  int bird = 0,
  SkyAudio Function()? audio,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  final folder = Directory.systemTemp.createTempSync('campaign-screens');
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, reduced);
    await unlockBirds(repo);
    await repo.equipBird(bird);
    await _seed(repo, stars, postcards: postcards);
    if (!story) {
      for (final scene in CampaignStory.scenes) {
        await repo.markStoryWatched(scene);
      }
    }
  });
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(audio ?? () => SilentAudio()),
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
      child: const RepaintBoundary(
        key: ValueKey('visual-capture'),
        child: PushUpBirdApp(),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in [...birdAssets, 'island']) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await _settle(tester);
  return _App(container, repo);
}

/// Lets saves land and the screen catch up. The map never settles with
/// motion on, so this pumps a fixed while rather than settling.
Future<void> _settle(WidgetTester tester, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _path() => appRouter.routerDelegate.currentConfiguration.uri.toString();

PlayController _controller(WidgetTester tester) =>
    (tester.state(find.byType(PlayScreen)) as dynamic).controller
        as PlayController;

/// The level's game, loaded and with its loop stopped, so the test steps
/// the flight itself.
Future<BirdGame> _game(WidgetTester tester) async {
  await tester.pump();
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  await tester.pump();
  return game;
}

/// Flies the controller like a player's taps, hearts topped up, until
/// [until] holds or the flight ends. [collect] rewrites the stars collected
/// just before the finish, to stage a rating.
void _fly(
  PlayController controller, {
  bool Function(FlightSimulation sim)? until,
  int? collect,
}) {
  final sim = controller.simulation!;
  for (var frame = 1; frame <= 400 * 50; frame++) {
    if (sim.phase == RunPhase.ended || (until?.call(sim) ?? false)) break;
    if (sim.hearts < 2) sim.hearts = 3;
    if (collect != null && (sim.distanceToGo ?? 9) < .05) {
      sim.collectedStars = collect;
    }
    if (rideTheSky(sim)) controller.flap();
    if (sim.canSprint) controller.sprint();
    // Shoot is a press and a release: a charged rock now and then, taps
    // between.
    if (frame % 9 == 0 && sim.canCharge) controller.startCharge();
    if (frame % 9 == 3 && sim.charging) controller.shoot();
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
  // The game loop plays a finished level's celebration out before its
  // result.
  while (!controller.celebrationSettled) {
    controller.advance(.02, 0, 2.2);
  }
}

/// Crashes the bird on its last heart: it stops flapping and falls.
void _crash(PlayController controller) {
  final sim = controller.simulation!;
  sim
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0;
  for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
}

/// Taps through the rest of the knockout to its stage.
void _skipKnockout(PlayController controller) {
  controller.knockout = KnockoutArt.skipAfter + .01;
  controller.skipKnockout();
}

/// Paints one frame of the frozen flight under a stage.
Future<void> _paint(WidgetTester tester, BirdGame game) async {
  game.resumeEngine();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  game.pauseEngine();
  await tester.pump();
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester, 2);
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

  const phone = Size(800, 360);

  // New York is open in the build as it ships (`NEW_YORK_OPEN` defaults to
  // true); each test that depends on the state forces it with the hooks, so
  // the suite passes under either define.
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  group('flow', () {
    testWidgets('Home opens the map with the campaign\'s star total', (
      tester,
    ) async {
      // Open, as the build ships: 21 playable levels (Egypt's guardian is
      // 2-6), 63 stars.
      Campaign.openedForTest = true;
      await _open(tester, phone, stars: const {'1-1': 3, '1-2': 1});
      expect(find.byKey(const ValueKey('endless')), findsOneWidget);
      final key = find.byKey(const ValueKey('campaign'));
      expect(key, findsOneWidget);
      expect(find.text('4 / 63'), findsOneWidget);
      // The key says where the journey continues.
      expect(find.text('1-3 · ${Campaign.level('1-3')!.name}'), findsOneWidget);
      expect(tester.getSize(key).height, greaterThanOrEqualTo(48));
      await _tap(tester, key);
      expect(_path(), '/campaign');
      expect(find.byType(CampaignMap), findsOneWidget);
      expect(find.bySemanticsLabel('4 of 63 campaign stars'), findsOneWidget);
      // The back key returns Home.
      await _tap(tester, find.byTooltip('Back home'));
      expect(_path(), '/');
    });

    testWidgets('with New York closed (NEW_YORK_OPEN=false) the total is of '
        '51', (tester) async {
      Campaign.closedForTest = true;
      await _open(tester, phone, stars: const {'1-1': 3, '1-2': 1});
      expect(find.text('4 / 51'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('campaign')));
      expect(find.bySemanticsLabel('4 of 51 campaign stars'), findsOneWidget);
    });

    testWidgets('a closed build never shows more stars than its total', (
      tester,
    ) async {
      // A save that earned New York's stars, opened with New York closed.
      Campaign.closedForTest = true;
      await _open(
        tester,
        phone,
        stars: {
          for (final level in Campaign.chapters[0].levels) level.id: 3,
          for (final level in Campaign.chapters[1].levels) level.id: 3,
          '3-1': 3,
          '3-2': 3,
          '3-3': 3,
          '3-4': 3,
        },
      );
      expect(find.text('51 / 51'), findsOneWidget);
      expect(find.text('63 / 51'), findsNothing);
    });

    // Campaign and Endless, the main game, share the row under the title at
    // the same size: 250 × 108 at 50 and 310, 128 down the 1000 × 450
    // canvas, with the 76-tall Mini games and Level Builder keys under them,
    // half the row each. The reference phone shows that canvas at .792,
    // 1.8 dp down, and every display shows the phone scaled.
    for (final size in const [
      Size(640, 360),
      Size(800, 360),
      Size(1000, 450),
    ]) {
      testWidgets('Campaign and Endless lead Home side by side at '
          '${size.width.round()}; Mini games and the Level Builder sit under '
          'them', (tester) async {
        await _open(tester, size);
        final shown = ScreenFrame.shownIn(size);
        final s = ScreenFrame.scaleFor(size);
        Rect canvas(double left, double top, double width, double height) =>
            Rect.fromLTWH(
              shown.left + left * .792 * s,
              shown.top + (1.8 + top * .792) * s,
              width * .792 * s,
              height * .792 * s,
            );
        void same(Rect actual, Rect expected, String name) {
          for (final (a, b) in [
            (actual.left, expected.left),
            (actual.top, expected.top),
            (actual.width, expected.width),
            (actual.height, expected.height),
          ]) {
            expect(a, closeTo(b, .001), reason: '$name $actual');
          }
        }

        final campaign = tester.getRect(find.byKey(const ValueKey('campaign')));
        final endless = tester.getRect(find.byKey(const ValueKey('endless')));
        final mini = tester.getRect(find.byKey(const ValueKey('mini-games')));
        final builder = tester.getRect(
          find.byKey(const ValueKey('level-builder')),
        );
        same(campaign, canvas(50, 128, 250, 108), 'Campaign');
        same(endless, canvas(310, 128, 250, 108), 'Endless');
        same(mini, canvas(50, 246, 250, 76), 'Mini games');
        same(builder, canvas(310, 246, 250, 76), 'Level Builder');
        for (final (name, key) in [
          ('Campaign', campaign),
          ('Endless', endless),
          ('Mini games', mini),
          ('Level Builder', builder),
        ]) {
          expect(key.height, greaterThanOrEqualTo(48), reason: name);
          expect(key.width, greaterThanOrEqualTo(48), reason: name);
          expect((Offset.zero & size).contains(key.topLeft), isTrue);
          expect((Offset.zero & size).contains(key.bottomRight), isTrue);
        }
        expect(campaign.overlaps(endless), isFalse);
        expect(mini.overlaps(builder), isFalse);
        expect(mini.top, greaterThan(campaign.bottom));
        expect(builder.top, greaterThan(endless.bottom));
        for (final key in [
          'campaign',
          'endless',
          'mini-games',
          'level-builder',
        ]) {
          expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the map leads back Home while its save loads, or when it '
        'cannot be read', (tester) async {
      tester.view.physicalSize = phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _SlowRepo(ProgressDatabase(NativeDatabase.memory()))
        ..hold = Completer();
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          audioFactoryProvider.overrideWithValue(() => SilentAudio()),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.runAsync(repo.close);
      });
      appRouter.go('/campaign');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const PushUpBirdApp(),
        ),
      );
      await tester.pump();
      // Loading: the system back and the back key both go Home.
      expect(find.byType(CampaignMap), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(_path(), '/');
      appRouter.go('/campaign');
      await tester.pump();
      await tester.tap(find.byTooltip('Back home'));
      await tester.pump();
      expect(_path(), '/');
      // A save that cannot be read offers Home beside Try again.
      appRouter.go('/campaign');
      await tester.pump();
      repo.hold!.completeError(StateError('unreadable'));
      await tester.pump();
      await tester.pump();
      expect(find.text('The map needs a moment.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('campaign-home')));
      await tester.pump();
      expect(_path(), '/');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a campaign flight counts as flown on Home', (tester) async {
      await _open(tester, phone, stars: const {'1-1': 1});
      expect(find.textContaining('Ready to fly?'), findsNothing);
    });

    testWidgets('map → card → flight → finish → result → Next → next card', (
      tester,
    ) async {
      final app = await _open(tester, phone, at: '/campaign');
      // The first level is current and opens its card.
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-1')));
      expect(find.byType(LevelIntroCard), findsOneWidget);
      expect(find.text('First Delivery'), findsWidgets);
      expect(find.text('Reach the finish'), findsOneWidget);
      expect(find.text('Collect 15 stars'), findsOneWidget);
      expect(find.text('Collect 25 stars'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('Tap to flap. Fly through the stars.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('level-intro-fly')));
      expect(_path(), '/play/touch?level=1-1');

      // Straight to the countdown: no setup card.
      final game = await _game(tester);
      final controller = _controller(tester);
      expect(controller.level, same(_level('1-1')));
      expect(controller.stage, PlayStage.flying);
      expect(find.text('Start touch flight'), findsNothing);
      _fly(controller, collect: 20);
      expect(controller.simulation!.endReason, EndReason.completed);
      await _settle(tester);
      expect(controller.stage, PlayStage.results);
      expect(controller.saved, isTrue);
      expect(find.byType(LevelResultStage), findsOneWidget);
      expect(find.byType(GameOverStage), findsNothing);
      // The result's courier on its cloud is the only bird: the frozen
      // finish leaves the flight's bird out.
      expect(game.hideBird, isTrue);
      expect(controller.levelStars, 2);
      expect(find.bySemanticsLabel('2 of 3 stars'), findsOneWidget);
      // The save merged the level: two stars, and 1-2 is open.
      final campaign = app.progress.campaign;
      expect(campaign.stars(_level('1-1')), 2);
      expect(campaign.unlocked(_level('1-2')), isTrue);
      await tester.pump(const Duration(milliseconds: 1600));
      await _tap(tester, find.byKey(const ValueKey('level-result-next')));
      expect(_path(), '/campaign?level=1-2');
      expect(find.byKey(const ValueKey('level-intro-1-2')), findsOneWidget);
      expect(find.text('Star Streak'), findsWidgets);
      // Under the card the map is out of the semantics tree, so a screen
      // reader meets the card first (see ny_ui_a11y_test.dart); the map's
      // state is read from its stops.
      final stops = tester.widget<CampaignMap>(find.byType(CampaignMap)).stops;
      final nodes = [for (final stop in stops) ...stop.nodes];
      expect(nodes.firstWhere((n) => n.id == '1-1').stars, 2);
      expect(nodes.firstWhere((n) => n.id == '1-2').isCurrent, isTrue);
      // Closing the card leaves the map: it shows 1-1's stars and perches the
      // bird on 1-2; the card shows the earned star when it opens again.
      await _tap(tester, find.byKey(const ValueKey('level-intro-close')));
      expect(find.byType(LevelIntroCard), findsNothing);
      expect(
        find.bySemanticsLabel('Level 1-1, First Delivery. 2 of 3 stars.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Level 1-2, Star Streak. Next up. 0 of 3 stars.'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-1')));
      expect(
        find.bySemanticsLabel('Two stars: Collect 15 stars. Earned.'),
        findsOneWidget,
      );
      expect(find.text('Best: 20 stars'), findsOneWidget);
    });

    testWidgets('with motion, the map holds still under its card', (
      tester,
    ) async {
      await _open(tester, phone, at: '/campaign', reduced: false);
      // The courier bobs and glows on its own ticker.
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('campaign-node-1-1')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LevelIntroCard), findsOneWidget);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'nothing animates under the card',
      );
      await tester.tap(find.byKey(const ValueKey('level-intro-close')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LevelIntroCard), findsNothing);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('a locked level cannot be started: it only nudges', (
      tester,
    ) async {
      await _open(tester, phone, at: '/campaign', stars: const {'1-1': 2});
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-3')));
      expect(find.byType(LevelIntroCard), findsNothing);
      expect(find.text('Finish 1-2 to unlock'), findsOneWidget);
      expect(_path(), '/campaign');
      // The nudge fades on its own.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Finish 1-2 to unlock'), findsNothing);
      // Nor can a link fly it.
      appRouter.go('/play/touch?level=1-3');
      await _settle(tester);
      expect(_path(), '/campaign');
      expect(find.byType(PlayScreen), findsNothing);
      appRouter.go('/play/touch?level=9-9');
      await _settle(tester);
      expect(_path(), '/campaign');
    });

    testWidgets('with New York closed, chapters 3 to 5 say Coming soon', (
      tester,
    ) async {
      Campaign.closedForTest = true;
      await _open(
        tester,
        phone,
        at: '/campaign',
        stars: {for (final level in Campaign.chapters[0].levels) level.id: 1},
        postcards: const {1},
      );
      final map = tester.state<ScrollableState>(find.byType(Scrollable));
      map.position.jumpTo(6 * phone.width);
      await _settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('campaign-node-3-1')));
      await _settle(tester, 2);
      expect(find.text('Coming soon'), findsWidgets);
      expect(find.byType(LevelIntroCard), findsNothing);
    });

    testWidgets('a knockout plays the game-over stage; Retry flies the same '
        'level again', (tester) async {
      await _open(
        tester,
        phone,
        at: '/play/touch?level=1-4',
        stars: const {'1-1': 3, '1-2': 3, '1-3': 3},
      );
      final game = await _game(tester);
      final controller = _controller(tester);
      _fly(controller, until: (sim) => sim.gates >= 3);
      _crash(controller);
      await _settle(tester);
      expect(controller.result!.reason, EndReason.collision);
      _skipKnockout(controller);
      await _settle(tester);
      expect(find.byType(GameOverStage), findsOneWidget);
      expect(find.byType(LevelResultStage), findsNothing);
      // The knockout keeps its own tumbling bird.
      expect(game.hideBird, isFalse);
      await tester.pump(const Duration(milliseconds: 1600));
      // Campaign keys; no endless best.
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Fly again'), findsNothing);
      expect(find.text('Home'), findsNothing);
      expect(find.text('NEW PERSONAL BEST!'), findsNothing);
      expect(find.text('PERSONAL BEST'), findsNothing);
      expect(find.byKey(const ValueKey('result-flight-goals')), findsNothing);
      expect(find.text('STARS COLLECTED'), findsOneWidget);
      expect(find.text('ROUTE FLOWN'), findsOneWidget);
      final failed = controller.simulation;
      await _tap(tester, find.byKey(const ValueKey('game-over-fly-again')));
      expect(controller.stage, PlayStage.flying);
      expect(controller.simulation, isNot(same(failed)));
      expect(controller.simulation!.levelId, '1-4');
      expect(find.text('Ready, steady…'), findsNothing);
      controller.advance(.02, controller.nowMs, 2.2);
      expect(controller.simulation!.phase, RunPhase.playing);
      expect(_path(), '/play/touch?level=1-4');
      // The failed attempt counts as a play, with no stars.
      final record = _app(tester).progress.campaign.record(_level('1-4'));
      expect(record.plays, 1);
      expect(record.bestStars, 0);
    });

    testWidgets('the pause card offers Retry and Map; both save the attempt', (
      tester,
    ) async {
      await _open(tester, phone, at: '/play/touch?level=1-1');
      await _game(tester);
      final controller = _controller(tester);
      _fly(controller, until: (sim) => sim.gates >= 2);
      await tester.tap(find.bySemanticsLabel('Pause flight'));
      await _settle(tester, 2);
      expect(find.text('Take a breather.'), findsOneWidget);
      expect(find.text('Finish flight'), findsNothing);
      expect(find.byKey(const ValueKey('pause-retry')), findsOneWidget);
      final first = controller.simulation;
      await _tap(tester, find.byKey(const ValueKey('pause-retry')));
      expect(controller.stage, PlayStage.flying);
      expect(controller.simulation, isNot(same(first)));
      expect(find.byType(LevelResultStage), findsNothing);
      expect(find.text('Ready, steady…'), findsNothing);
      controller.advance(.02, controller.nowMs, 2.2);
      expect(controller.simulation!.phase, RunPhase.playing);
      _fly(controller, until: (sim) => sim.gates >= 1);
      await tester.tap(find.bySemanticsLabel('Pause flight'));
      await _settle(tester, 2);
      await _tap(tester, find.byKey(const ValueKey('pause-map')));
      expect(_path(), '/campaign');
      final record = _app(tester).progress.campaign.record(_level('1-1'));
      expect(record.plays, 2);
      expect(record.cleared, isFalse);
      // Unfinished attempts set no best: the card says so rather than
      // showing their stars as one.
      expect(record.bestCollected, 0);
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-1')));
      expect(find.text('Not delivered yet'), findsOneWidget);
      expect(find.textContaining('Best:'), findsNothing);
    });

    testWidgets('the first boss clear brings the postcard, then the next '
        'chapter', (tester) async {
      final stars = {..._bossBeaten}..remove('1-8');
      final app = await _open(
        tester,
        phone,
        at: '/play/touch?level=1-8',
        stars: stars,
      );
      await _game(tester);
      final controller = _controller(tester);
      _fly(controller, until: (sim) => sim.boss != null);
      // Skip the fight itself: the boss falls, and the victory glide
      // crosses the finish line.
      final sim = controller.simulation!;
      sim.boss!.hp = 1;
      _fly(controller);
      expect(sim.endReason, EndReason.completed);
      await _settle(tester);
      expect(find.byType(LevelResultStage), findsOneWidget);
      expect(app.progress.campaign.postcardDue(Campaign.chapters[0]), isTrue);
      await tester.pump(const Duration(milliseconds: 1600));
      await _tap(tester, find.byKey(const ValueKey('level-result-next')));
      expect(_path(), '/campaign?level=2-1');
      // The postcard arrives before the map and the next card.
      expect(find.byType(CampaignPostcard), findsOneWidget);
      expect(find.byType(LevelIntroCard), findsNothing);
      expect(find.text(CampaignPostcard.letters[0].body), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('campaign-postcard-continue')),
      );
      expect(find.byType(CampaignPostcard), findsNothing);
      expect(app.progress.campaign.postcardDue(Campaign.chapters[0]), isFalse);
      expect(find.byKey(const ValueKey('level-intro-2-1')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('level-intro-close')));
      // Chapter 2 is open, and the postcard waits on the route to be seen
      // again.
      expect(
        find.bySemanticsLabel(RegExp('^Level 2-1, Beetle Road. Next up.')),
        findsOneWidget,
      );
      appRouter.go('/campaign');
      await _settle(tester);
      final map = tester.state<ScrollableState>(find.byType(Scrollable));
      map.position.jumpTo(2 * phone.width);
      await _settle(tester, 2);
      await _tap(tester, find.byKey(const ValueKey('campaign-postcard-1')));
      expect(find.byType(CampaignPostcard), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('campaign-postcard-continue')),
      );
      expect(find.byType(CampaignPostcard), findsNothing);
    });

    /// Beats 2-9 (the last chapter-2 boss) and continues past the postcard.
    Future<void> beatTheDragon(WidgetTester tester) async {
      final stars = {
        for (final level in [
          ...Campaign.chapters[0].levels,
          ...Campaign.chapters[1].levels,
        ])
          level.id: 2,
      }..remove('2-9');
      await _open(
        tester,
        phone,
        at: '/play/touch?level=2-9',
        stars: stars,
        postcards: const {1},
      );
      await _game(tester);
      final controller = _controller(tester);
      _fly(controller, until: (sim) => sim.boss != null);
      controller.simulation!.boss!.hp = 1;
      _fly(controller);
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 1600));
    }

    testWidgets('with New York closed (NEW_YORK_OPEN=false) the last playable '
        'boss leads back to the map, where chapter 3 is coming soon', (
      tester,
    ) async {
      Campaign.closedForTest = true;
      await beatTheDragon(tester);
      expect(find.byKey(const ValueKey('level-result-next')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('level-result-map')));
      expect(find.byType(CampaignPostcard), findsOneWidget);
      expect(find.text('— The Ancient Road'), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('campaign-postcard-continue')),
      );
      expect(
        find.bySemanticsLabel(RegExp('^New York. Chapter 3, .*Coming soon')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Level 3-1, Moth Light. Locked.'),
        findsOneWidget,
      );
    });

    testWidgets('open, as the build ships, the last chapter-2 boss leads on '
        'to New York: 3-1 is next up and only Paris is coming soon', (
      tester,
    ) async {
      Campaign.openedForTest = true;
      await beatTheDragon(tester);
      // 3-1 is playable now, so the result offers it as the next level.
      expect(find.byKey(const ValueKey('level-result-next')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('level-result-map')));
      expect(find.byType(CampaignPostcard), findsOneWidget);
      expect(find.text('— The Ancient Road'), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('campaign-postcard-continue')),
      );
      expect(
        find.bySemanticsLabel(RegExp('^New York. Chapter 3, .*Coming soon')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('^New York. Chapter 3, The Lamplight Line'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Level 3-1, Moth Light. Next up. 0 of 3 stars.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Paris. Chapter 3, .*Coming soon')),
        findsOneWidget,
      );
    });

    testWidgets('a finished level reads its thank-you aloud as the note '
        'lands; a knockout says nothing', (tester) async {
      final audio = _HeardAudio();
      await _open(
        tester,
        phone,
        at: '/play/touch?level=1-1',
        reduced: false,
        audio: () => audio,
      );
      await _game(tester);
      final controller = _controller(tester);
      _fly(controller, collect: 40);
      await _settle(tester);
      expect(find.byType(LevelResultStage), findsOneWidget);
      await tester.pump(LevelResultStage.entrance);
      expect(audio.said, ['audio/story/thanks-1-1.ogg']);
      // Once only, however long the result stays up.
      await tester.pump(LevelResultStage.entrance);
      expect(audio.said, hasLength(1));

      // A lost flight delivers nothing, so nobody says thank you.
      audio.said.clear();
      await tester.pumpWidget(const SizedBox());
      await _open(
        tester,
        phone,
        at: '/play/touch?level=1-1',
        audio: () => audio,
      );
      await _game(tester);
      final lost = _controller(tester);
      _crash(lost);
      await _settle(tester);
      _skipKnockout(lost);
      await _settle(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(GameOverStage), findsOneWidget);
      expect(audio.said, isEmpty);
    });

    testWidgets('a replayed level chimes at its own marks', (tester) async {
      VideoPlayerPlatform.instance = FakeVideoPlatform();
      final audio = _HeardAudio();
      final app = await _open(tester, phone, audio: () => audio);
      // A short 1-1 whose first mark is low and second out of reach. The
      // tape keeps this plan, so the replay rates and chimes by it.
      final base = _level('1-1').plan;
      final plan = LevelPlan(
        id: base.id,
        region: base.region,
        length: 25,
        start: base.start,
        seed: base.seed,
        families: base.families,
        shoot: false,
        sprint: false,
        marks: const StarMarks(5, 200),
      );
      final (:tape, :simulation) = recordLevel(_level('1-1'), plan: plan);
      final sim = simulation;
      expect(sim.endReason, EndReason.completed);
      final marks = plan.marks.reached(sim.collectedStars);
      expect(marks, 1);
      final run = levelRun(
        'chime',
        '1-1',
        stars: sim.collectedStars,
        score: sim.score,
        duration: sim.elapsed,
      );
      await tester.runAsync(
        () => app.container
            .read(sessionRepositoryProvider)
            .save(SavedSession(result: run, tape: tape, clips: const [])),
      );
      appRouter.go('/replay/chime');
      for (
        var i = 0;
        i < 20 && find.byTooltip('Play replay').evaluate().isEmpty;
        i++
      ) {
        await _settle(tester, 1);
      }
      audio.heard.clear();
      await tester.tap(find.byTooltip('Play replay'));
      for (var ms = 0.0; ms < tape.durationMs + 2000; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(audio.heard, contains('complete'));
      expect(audio.heard.where((e) => e == 'wing'), hasLength(marks));
      expect(tester.takeException(), isNull);
    });

    test('saved sessions are named after their level', () {
      expect(sessionTitle(levelRun('a', '1-3')), '1-3 · Bat Patrol');
      expect(
        sessionTitle(levelRun('b', '1-3').copyWithoutLevel()),
        'Tap & Fly · Endless',
      );
    });
  });

  group('story', () {
    /// The scene on screen, or null.
    StoryScene? playing(WidgetTester tester) {
      final players = tester.widgetList<StoryScenePlayer>(
        find.byType(StoryScenePlayer),
      );
      return players.isEmpty ? null : players.single.scene;
    }

    Future<void> next(WidgetTester tester) =>
        _tap(tester, find.byKey(const ValueKey('story-advance')));

    testWidgets('the first visit opens on the prologue, line by line, and '
        'only once', (tester) async {
      final app = await _open(tester, phone, at: '/campaign', story: true);
      final prologue = CampaignStory.prologue;
      expect(playing(tester), same(prologue));
      // The map waits underneath: nothing on it can be tapped yet.
      expect(find.byType(LevelIntroCard), findsNothing);
      for (final (i, line) in prologue.lines.indexed) {
        expect(find.text(line.text), findsOneWidget, reason: 'line $i');
        final name = StoryScenePlayer.speakerName(prologue, line, 0);
        if (name != null) expect(find.text(name), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            name == null ? line.text : '$name: ${line.text}',
          ),
          findsOneWidget,
        );
        await next(tester);
      }
      expect(playing(tester), isNull);
      expect(app.progress.campaign.storyWatched, {prologue.id});
      expect(app.progress.campaign.prologueDue, isNull);
      // The courier speaks under its own name.
      expect(
        StoryScenePlayer.speakerName(prologue, prologue.lines[2], 0),
        'Pip',
      );
      // The map is free again, and a second visit goes straight to it.
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-1')));
      expect(find.byType(LevelIntroCard), findsOneWidget);
      appRouter.go('/');
      await _settle(tester);
      appRouter.go('/campaign');
      await _settle(tester);
      expect(playing(tester), isNull);
    });

    testWidgets('Skip and the back button both end a scene and save it', (
      tester,
    ) async {
      final app = await _open(tester, phone, at: '/campaign', story: true);
      expect(playing(tester), isNotNull);
      await _tap(tester, find.byKey(const ValueKey('story-skip')));
      expect(playing(tester), isNull);
      expect(app.progress.campaign.prologueDue, isNull);
      expect(_path(), '/campaign');

      // 1-4 opens Brazil with a scene; back skips it and lands on the card.
      await tester.runAsync(
        () => _seed(app.repo, const {'1-1': 1, '1-2': 1, '1-3': 1}),
      );
      await tester.runAsync(
        () => app.container.read(progressProvider.notifier).refresh(),
      );
      await _settle(tester);
      final map = tester.state<ScrollableState>(find.byType(Scrollable));
      map.position.jumpTo(phone.width);
      await _settle(tester, 2);
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-4')));
      expect(playing(tester)?.id, 'before-1-4');
      expect(find.byType(LevelIntroCard), findsNothing);
      await tester.binding.handlePopRoute();
      await _settle(tester, 2);
      expect(playing(tester), isNull);
      expect(find.byKey(const ValueKey('level-intro-1-4')), findsOneWidget);
      expect(app.progress.campaign.storyWatched, contains('before-1-4'));
      expect(_path(), '/campaign');
    });

    testWidgets('a level\'s scene plays before its card once; the card\'s '
        'story key plays it again', (tester) async {
      final app = await _open(
        tester,
        phone,
        at: '/campaign?level=1-6',
        stars: const {'1-1': 1, '1-2': 1, '1-3': 1, '1-4': 1, '1-5': 1},
        story: true,
      );
      // The prologue belongs to a level already finished, so it stays away.
      final scene = CampaignStory.before(_level('1-6'))!;
      expect(playing(tester), same(scene));
      await _tap(tester, find.byKey(const ValueKey('story-skip')));
      expect(find.byKey(const ValueKey('level-intro-1-6')), findsOneWidget);
      // Closing and reopening the card does not play it again.
      await _tap(tester, find.byKey(const ValueKey('level-intro-close')));
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-6')));
      expect(playing(tester), isNull);
      expect(find.byKey(const ValueKey('level-intro-1-6')), findsOneWidget);
      // The story key does, and leaves the card where it was.
      await _tap(tester, find.byKey(const ValueKey('level-intro-story')));
      expect(playing(tester), same(scene));
      expect(find.text(scene.lines.first.text), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('story-skip')));
      expect(playing(tester), isNull);
      expect(find.byKey(const ValueKey('level-intro-1-6')), findsOneWidget);
      expect(app.progress.campaign.storyWatched, {scene.id});
      // A level with no scene has no story key; a finished one that has a
      // scene keeps its key without playing the scene by itself.
      await _tap(tester, find.byKey(const ValueKey('level-intro-close')));
      final map = tester.state<ScrollableState>(find.byType(Scrollable));
      map.position.jumpTo(phone.width);
      await _settle(tester, 2);
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-5')));
      expect(find.byKey(const ValueKey('level-intro-story')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('level-intro-close')));
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-4')));
      expect(playing(tester), isNull);
      expect(find.byKey(const ValueKey('level-intro-story')), findsOneWidget);
    });

    testWidgets('a fallen boss has the last word before its postcard, then '
        'the next route opens with its own scene', (tester) async {
      final app = await _open(
        tester,
        phone,
        at: '/campaign?level=2-1',
        stars: _bossBeaten,
        story: true,
      );
      final chapter = Campaign.chapters[0];
      final after = CampaignStory.after(chapter);
      expect(playing(tester), same(after));
      expect(find.byType(CampaignPostcard), findsNothing);
      expect(find.text('Baron Bat'), findsWidgets);
      await _tap(tester, find.byKey(const ValueKey('story-skip')));
      // The postcard follows, then the next chapter's opening, then its card.
      expect(playing(tester), isNull);
      expect(find.byType(CampaignPostcard), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const ValueKey('campaign-postcard-continue')),
      );
      expect(find.byType(CampaignPostcard), findsNothing);
      expect(playing(tester)?.id, 'before-2-1');
      expect(find.byType(LevelIntroCard), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('story-skip')));
      expect(find.byKey(const ValueKey('level-intro-2-1')), findsOneWidget);
      expect(app.progress.campaign.storyWatched, {after.id, 'before-2-1'});
      // The beaten lair's story key tells both of its scenes again.
      await _tap(tester, find.byKey(const ValueKey('level-intro-close')));
      final map = tester.state<ScrollableState>(find.byType(Scrollable));
      map.position.jumpTo(2 * phone.width);
      await _settle(tester, 2);
      await _tap(tester, find.byKey(const ValueKey('campaign-node-1-8')));
      await _tap(tester, find.byKey(const ValueKey('level-intro-story')));
      expect(playing(tester)?.id, 'before-1-8');
      // Two taps as the first scene ends must not skip the second.
      await tester.tap(find.byKey(const ValueKey('story-skip')));
      await tester.tap(find.byKey(const ValueKey('story-skip')));
      await _settle(tester, 2);
      expect(playing(tester), same(after));
      await _tap(tester, find.byKey(const ValueKey('story-skip')));
      expect(playing(tester), isNull);
      expect(find.byKey(const ValueKey('level-intro-1-8')), findsOneWidget);
    });

    testWidgets('with motion a line writes itself out; a tap finishes it, '
        'the next tap moves on', (tester) async {
      await _open(tester, phone, at: '/campaign', story: true, reduced: false);
      final lines = CampaignStory.prologue.lines;
      final cue = find.byKey(const ValueKey('story-cue'));
      await tester.pump(const Duration(milliseconds: 400));
      // Part-way through its first line: no cue to move on yet.
      expect(find.text(lines[0].text), findsOneWidget);
      expect(cue, findsNothing);
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      expect(find.text(lines[0].text), findsOneWidget);
      expect(cue, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      expect(find.text(lines[1].text), findsOneWidget);
      expect(cue, findsNothing);
      // Left alone, the line finishes writing itself, at the pace of its
      // voice (never more than 8 s).
      await tester.pump(const Duration(seconds: 9));
      expect(cue, findsOneWidget);
      // Nothing under the scene animates: the map holds its frame.
      await tester.tap(find.byKey(const ValueKey('story-skip')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(playing(tester), isNull);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });
  });

  group('capture', skip: !_capture, () {
    for (final size in const [
      Size(800, 360),
      Size(640, 360),
      Size(1000, 450),
    ]) {
      final w = size.width.round();
      testWidgets('home and map at $w', (tester) async {
        await _open(tester, size);
        await _shot(tester, 'home-fresh-$w');
        await tester.pumpWidget(const SizedBox());
        await _open(
          tester,
          size,
          stars: _midway,
          postcards: const {1},
          bird: 2,
        );
        await _shot(tester, 'home-midway-$w');
        await _tap(tester, find.byKey(const ValueKey('campaign')));
        await _settle(tester, 4);
        await _shot(tester, 'map-midway-$w');
        await tester.tap(find.bySemanticsLabel('Next stop'));
        await _settle(tester, 2);
        await tester.tap(find.byKey(const ValueKey('campaign-node-2-4')));
        await _settle(tester, 2);
        expect(find.text('Finish 2-3 to unlock'), findsOneWidget);
        await _shot(tester, 'map-nudge-$w');
      });
    }

    for (final size in const [
      Size(800, 360),
      Size(640, 360),
      Size(1000, 450),
    ]) {
      final w = size.width.round();
      testWidgets('story scenes at $w', (tester) async {
        Future<void> advance(int lines) async {
          for (var i = 0; i < lines; i++) {
            await _tap(tester, find.byKey(const ValueKey('story-advance')));
          }
        }

        // The prologue on a fresh save: its caption, Bill, the courier.
        await _open(tester, size, at: '/campaign', story: true, bird: 1);
        await _shot(tester, 'story-prologue-caption-$w');
        await advance(1);
        await _shot(tester, 'story-prologue-bill-$w');
        await advance(1);
        await _shot(tester, 'story-prologue-courier-$w');
        await tester.pumpWidget(const SizedBox());

        // The lair before the first boss, then its last word and postcard.
        await _open(
          tester,
          size,
          at: '/campaign?level=1-8',
          stars: {..._bossBeaten}..remove('1-8'),
          story: true,
        );
        await _shot(tester, 'story-lair-boss-$w');
        await advance(1);
        await _shot(tester, 'story-lair-courier-$w');
        await tester.pumpWidget(const SizedBox());
        await _open(
          tester,
          size,
          at: '/campaign',
          stars: _bossBeaten,
          story: true,
          bird: 3,
        );
        await _shot(tester, 'story-after-boss-$w');
        await advance(6);
        await _shot(tester, 'story-after-bill-$w');
        await tester.pumpWidget(const SizedBox());

        // An arrival, and the card it leads to with its story key.
        await _open(
          tester,
          size,
          at: '/campaign?level=2-4',
          stars: {..._midway, '2-3': 2},
          postcards: const {1},
          story: true,
          bird: 2,
        );
        await _shot(tester, 'story-arrival-egypt-$w');
        await _tap(tester, find.byKey(const ValueKey('story-skip')));
        await _shot(tester, 'story-card-after-$w');
      });
    }

    for (final size in const [Size(800, 360), Size(640, 360)]) {
      final w = size.width.round();
      testWidgets('level cards at $w', (tester) async {
        final app = await _open(
          tester,
          size,
          at: '/campaign',
          stars: _midway,
          postcards: const {1},
        );
        expect(app.progress.campaign.totalStars, greaterThan(0));
        for (final (id, name) in [
          ('1-4', 'normal'),
          ('1-3', 'new'),
          ('1-8', 'boss'),
          ('1-2', 'earned'),
          ('2-3', 'new-open'),
        ]) {
          appRouter.go('/campaign?level=$id');
          await _settle(tester, 4);
          await _shot(tester, 'intro-$name-$id-$w');
        }
      });

      testWidgets('results at $w', (tester) async {
        for (final (stars, collect) in [(1, 20), (2, 50), (3, 75)]) {
          await _open(
            tester,
            size,
            at: '/play/touch?level=1-4',
            // The three-star flight beats an earlier one-star best.
            stars: {'1-1': 3, '1-2': 3, '1-3': 3, if (stars == 3) '1-4': 1},
            bird: stars,
          );
          final game = await _game(tester);
          final controller = _controller(tester);
          _fly(controller, collect: collect);
          await _settle(tester);
          await _paint(tester, game);
          expect(controller.levelStars, stars);
          await tester.pump(const Duration(milliseconds: 700));
          await _shot(tester, 'result-$stars-stars-entrance-$w');
          await tester.pump(const Duration(milliseconds: 1400));
          await _shot(tester, 'result-$stars-stars-$w');
          await tester.pumpWidget(const SizedBox());
        }
        // With motion, the stars pop in one by one.
        await _open(
          tester,
          size,
          at: '/play/touch?level=1-4',
          reduced: false,
          stars: const {'1-1': 3, '1-2': 3, '1-3': 3},
          bird: 2,
        );
        var game = await _game(tester);
        var controller = _controller(tester);
        _fly(controller, collect: 80);
        await _settle(tester, 1);
        await _paint(tester, game);
        for (final ms in [500, 800, 1100, 1400]) {
          await tester.pump(const Duration(milliseconds: 300));
          await _shot(tester, 'result-motion-$ms-$w');
        }
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox());

        // A boss beaten for the first time: its postcard waits on the map.
        await _open(
          tester,
          size,
          at: '/play/touch?level=1-8',
          stars: {..._bossBeaten}..remove('1-8'),
        );
        game = await _game(tester);
        controller = _controller(tester);
        _fly(controller, until: (sim) => sim.boss != null);
        controller.simulation!.boss!.hp = 1;
        _fly(controller);
        await _settle(tester);
        await _paint(tester, game);
        await tester.pump(const Duration(milliseconds: 2100));
        await _shot(tester, 'result-boss-1-8-$w');
        await tester.pumpWidget(const SizedBox());

        // An interrupted flight: no stars, Retry leads.
        await _open(tester, size, at: '/play/touch?level=1-1');
        game = await _game(tester);
        controller = _controller(tester);
        _fly(controller, until: (sim) => sim.gates >= 6);
        controller.advance(.8, 0, 2.2);
        controller.tick();
        await _settle(tester);
        await _paint(tester, game);
        await tester.pump(const Duration(milliseconds: 2100));
        expect(controller.result!.reason, EndReason.stalled);
        await _shot(tester, 'result-0-stars-$w');
      });

      testWidgets('game over, pause and postcard at $w', (tester) async {
        await _open(
          tester,
          size,
          at: '/play/touch?level=1-4',
          stars: const {'1-1': 3, '1-2': 3, '1-3': 3},
          bird: 1,
        );
        var game = await _game(tester);
        var controller = _controller(tester);
        _fly(controller, until: (sim) => sim.gates >= 8);
        await tester.tap(find.bySemanticsLabel('Pause flight'));
        await _settle(tester, 2);
        await _paint(tester, game);
        await _shot(tester, 'pause-$w');
        await tester.tap(find.text('Keep flying'));
        await _settle(tester, 2);
        _fly(controller, until: (sim) => sim.phase == RunPhase.playing);
        _crash(controller);
        await _settle(tester);
        _skipKnockout(controller);
        await _settle(tester);
        await _paint(tester, game);
        await tester.pump(const Duration(milliseconds: 2400));
        await _shot(tester, 'game-over-$w');
        await tester.pumpWidget(const SizedBox());

        await _open(tester, size, at: '/campaign', stars: _bossBeaten, bird: 3);
        await _settle(tester, 4);
        await _shot(tester, 'postcard-1-$w');
        // Reduced Motion off: the card eases in over the moving map.
        await tester.pumpWidget(const SizedBox());
        await _open(
          tester,
          size,
          at: '/campaign?level=1-3',
          reduced: false,
          stars: const {'1-1': 3, '1-2': 1},
        );
        await tester.pump(const Duration(milliseconds: 600));
        await _shot(tester, 'intro-motion-1-3-$w');
      });
    }
  });
}

_App _app(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(PushUpBirdApp)),
  );
  return _App(
    container,
    container.read(progressRepositoryProvider) as SqliteProgressRepository,
  );
}

extension on RunResult {
  RunResult copyWithoutLevel() => RunResult(
    id: id,
    mode: mode,
    practice: practice,
    course: course,
    score: score,
    gates: gates,
    stars: stars,
    bestCombo: bestCombo,
    perfectPasses: perfectPasses,
    repetitions: repetitions,
    flaps: flaps,
    durationSeconds: durationSeconds,
    reason: reason,
    finishedAt: finishedAt,
    bird: bird,
  );
}
