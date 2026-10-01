import 'dart:io';
import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/ui/flight_score.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'package:push_up_bird/ui/ui_sounds.dart';
import 'campaign_flight.dart' show obstacleSignature;
import 'play_session_test.dart' show SessionSource, SilentAudio;
import 'recorded_flight.dart' show rideTheSky;

class CueAudio extends SilentAudio {
  final cues = <String>[];
  @override
  void effect(String name, {int? variant}) => cues.add(name);
}

CampaignLevel level(String id) => Campaign.level(id)!;

PlayController levelController(
  CampaignLevel? level, {
  CueAudio? audio,
  List<RunResult>? runs,
}) => PlayController(
  mode: PlayMode.touch,
  level: level,
  source: null,
  audio: audio ?? CueAudio(),
  saveRun: (run) async => runs?.add(run),
  saveSession: (_) async {},
  clock: () => DateTime(2026, 9, 30, 12),
);

/// Flies [controller]'s flight the way a player's taps do: the shared bot
/// flaps through [PlayController.flap], shoots and sprints when the level
/// offers it, and the game loop's frames go through
/// [PlayController.advance]. [keepAlive] tops the hearts up. Stops once
/// [until] holds or the flight ends.
void flyController(
  PlayController controller, {
  bool keepAlive = true,
  bool Function(FlightSimulation sim)? until,
  double width = 2.2,
  double seconds = 200,
}) {
  final sim = controller.simulation!;
  for (var frame = 1; frame <= seconds * 50; frame++) {
    if (sim.phase == RunPhase.ended || (until?.call(sim) ?? false)) break;
    if (keepAlive && sim.hearts < 2) sim.hearts = 3;
    if (rideTheSky(sim)) controller.flap();
    if (sim.canSprint) controller.sprint();
    if (frame % 90 == 0) controller.startCharge();
    if (frame % 90 == 30 || (frame % 9 == 0 && sim.canShoot)) {
      controller.shoot();
    }
    controller.advance(.02, 0, width);
    controller.tick();
  }
}

/// A play screen flying [level] (endless when null) at [size], its game
/// loaded and paused so a test can stage the flight and redraw it.
Future<({PlayController controller, BirdGame game})> launchLevel(
  WidgetTester tester,
  CampaignLevel? level, {
  Size size = const Size(800, 360),
  bool reduced = true,
  int bird = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await repo.setSetting(SettingKey.reducedMotion, reduced);
  await repo.equipBird(bird);
  final folder = Directory.systemTemp.createTempSync('campaign-play');
  final source = SessionSource();
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(SilentAudio.new),
      trackingSourceFactoryProvider.overrideWithValue(() => source),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await repo.close();
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });
  await container.read(progressProvider.future);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            PlayScreen(mode: PlayMode.touch, level: level),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: const ValueKey('visual-capture'),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: skyTheme(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: UiSounds(play: (_) {}, child: child!),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  final dynamic state = tester.state(find.byType(PlayScreen));
  final controller = state.controller as PlayController;
  await tester.runAsync(controller.fly);
  await tester.pump();
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  await tester.pump();
  return (controller: controller, game: game);
}

/// Rebuilds the HUD and repaints the paused game with the staged state.
Future<void> redraw(WidgetTester tester, PlayController controller) async {
  controller.notify();
  await tester.pump();
  for (final box in tester.allRenderObjects) {
    if (box.runtimeType.toString() == 'GameRenderBox') box.markNeedsPaint();
  }
  await tester.pump();
  expect(tester.takeException(), isNull);
}

Future<void> loadFonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

void main() {
  setUpAll(loadFonts);

  group('PlayController', () {
    test(
      'a level flies its own plan and seed, and the tape keeps it',
      () async {
        final bat = level('1-3');
        final controller = levelController(bat);
        await controller.fly();
        final sim = controller.simulation!;
        expect(controller.campaign, isTrue);
        expect(sim.plan, same(bat.plan));
        expect(sim.levelId, '1-3');
        expect(sim.region, bat.region);
        expect(sim.rulesVersion, FlightSimulation.currentRulesVersion);
        final tape = controller.recorder!.tape;
        expect(tape.plan, same(bat.plan));
        expect(tape.levelId, '1-3');
        expect(tape.toJson()['level'], '1-3');
        expect(
          ReplayTape.fromJson(tape.toJson()).plan!.toJson(),
          bat.plan.toJson(),
        );

        // A retry flies the same route, although every tape draws a new seed.
        flyController(controller, until: (sim) => sim.obstacles.length >= 3);
        final first = [
          for (final o in sim.obstacles) obstacleSignature(sim, o),
        ];
        await controller.retry();
        final again = controller.simulation!;
        expect(again, isNot(same(sim)));
        expect(again.plan, same(bat.plan));
        flyController(controller, until: (sim) => sim.obstacles.length >= 3);
        expect([
          for (final o in again.obstacles) obstacleSignature(again, o),
        ], first);
        controller.dispose();
      },
    );

    test(
      'crossing the finish line completes the level with its stars',
      () async {
        final audio = CueAudio();
        final runs = <RunResult>[];
        final first = level('1-1');
        final controller = levelController(first, audio: audio, runs: runs);
        await controller.fly();
        flyController(controller);
        final sim = controller.simulation!;
        expect(sim.finishLine!.crossed, isTrue);
        await controller.finish();
        final result = controller.result!;
        expect(result.reason, EndReason.completed);
        expect(result.levelId, '1-1');
        expect(result.course, FlightCourse.starTrail);
        expect(result.practice, isFalse);
        expect(controller.stage, PlayStage.results);
        expect(controller.levelComplete, isTrue);
        expect(
          controller.levelStars,
          first.marks.rate(finished: true, stars: result.stars),
        );
        expect(controller.levelStars, inInclusiveRange(1, 3));
        expect(controller.nextLevel, same(level('1-2')));
        expect(runs.single.levelId, '1-1');
        // Crossing the line plays the victory fanfare.
        expect(audio.cues, contains('complete'));
        expect(audio.cues, isNot(contains('game_over')));
        controller.dispose();
      },
    );

    test('a knockout fails the level: no stars, same level to retry', () async {
      final controller = levelController(level('1-4'));
      await controller.fly();
      // A few passages in, the player stops flapping and falls.
      flyController(controller, until: (sim) => sim.gates >= 2);
      final sim = controller.simulation!;
      for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
        controller.advance(.02, 0, 2.2);
        controller.tick();
      }
      await controller.finish();
      expect(controller.result!.reason, EndReason.collision);
      expect(controller.stage, PlayStage.fallen);
      expect(controller.levelComplete, isFalse);
      expect(controller.levelStars, 0);
      expect(controller.result!.levelId, '1-4');
      controller.skipKnockout();
      await controller.retry();
      expect(controller.simulation!.levelId, '1-4');
      expect(controller.stage, PlayStage.flying);
      controller.dispose();
    });

    test('the last level has no next one; endless has no level', () async {
      expect(levelController(Campaign.levels.last).nextLevel, isNull);
      expect(
        levelController(level('1-8')).nextLevel,
        same(Campaign.chapters[1].levels.first),
      );
      final endless = levelController(null);
      await endless.fly();
      expect(endless.campaign, isFalse);
      expect(endless.nextLevel, isNull);
      expect(endless.simulation!.levelId, isNull);
      expect(endless.recorder!.tape.plan, isNull);
      expect(endless.recorder!.tape.toJson().containsKey('level'), isFalse);
      endless.endFlight();
      await endless.finish();
      expect(endless.result!.levelId, isNull);
      expect(endless.levelStars, 0);
      expect(endless.levelComplete, isFalse);
      endless.dispose();
    });
  });

  group('campaign HUD', () {
    for (final (id, shoot, sprint) in [
      ('1-1', false, false),
      ('1-3', true, false),
      ('2-1', true, true),
    ]) {
      testWidgets(
        '$id shows its stars and route; Shoot $shoot, Sprint $sprint',
        (tester) async {
          final (:controller, game: _) = await launchLevel(tester, level(id));
          final sim = controller.simulation!;
          sim.phase = RunPhase.playing;
          await redraw(tester, controller);
          expect(find.byKey(const ValueKey('level-stars')), findsOneWidget);
          expect(find.byKey(const ValueKey('level-route')), findsOneWidget);
          expect(find.byType(FlightScore), findsNothing);
          expect(
            find.byKey(const ValueKey('touch-shoot')),
            shoot ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('touch-sprint')),
            sprint ? findsOneWidget : findsNothing,
          );
          // Readouts are passive: touches reach the sky and flap the bird.
          for (final key in ['level-stars', 'level-route']) {
            expect(
              find.ancestor(
                of: find.byKey(ValueKey(key)),
                matching: find.byWidgetPredicate(
                  (w) => w is IgnorePointer && w.ignoring,
                ),
              ),
              findsWidgets,
            );
          }
          // Collecting stars and passing a mark stay still under Reduced
          // Motion.
          sim.collectedStars = level(id).marks.two;
          await redraw(tester, controller);
          expect(tester.hasRunningAnimations, isFalse);
          await tester.runAsync(controller.exit);
        },
      );
    }

    testWidgets('endless keeps its score and both controls', (tester) async {
      final (:controller, game: _) = await launchLevel(tester, null);
      controller.simulation!.phase = RunPhase.playing;
      await redraw(tester, controller);
      expect(find.byType(FlightScore), findsOneWidget);
      expect(find.byKey(const ValueKey('level-stars')), findsNothing);
      expect(find.byKey(const ValueKey('level-route')), findsNothing);
      expect(find.byKey(const ValueKey('touch-shoot')), findsOneWidget);
      expect(find.byKey(const ValueKey('touch-sprint')), findsOneWidget);
      await tester.runAsync(controller.exit);
    });

    testWidgets('a boss hides the level readouts until it falls', (
      tester,
    ) async {
      final (:controller, game: _) = await launchLevel(tester, level('1-8'));
      final sim = controller.simulation!;
      sim.phase = RunPhase.playing;
      sim.boss = SkyBoss(number: 1, x: 1.5, kind: BossKind.baronBat)..age = 10;
      await redraw(tester, controller);
      expect(find.byKey(const ValueKey('level-stars')), findsNothing);
      expect(find.byKey(const ValueKey('level-route')), findsNothing);
      sim.boss = null;
      await redraw(tester, controller);
      expect(find.byKey(const ValueKey('level-stars')), findsOneWidget);
      await tester.runAsync(controller.exit);
    });
  });
}
