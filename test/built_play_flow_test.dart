import 'dart:io';

import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:push_up_bird/data/builder_providers.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/built_level.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/ui/builder/built_result_stage.dart';
import 'package:push_up_bird/ui/level_result.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'package:push_up_bird/ui/ui_sounds.dart';

import 'built_pilot.dart';
import 'campaign_play_test.dart' show CueAudio, loadFonts;
import 'play_session_test.dart' show SessionSource, SilentAudio;
import 'recorded_flight.dart' show rideTheSky;

PlayController builtController(
  BuiltFlight flight, {
  List<RunResult>? runs,
  CueAudio? audio,
}) => PlayController(
  mode: flight.plan.mode,
  built: flight,
  source: null,
  audio: audio ?? CueAudio(),
  saveRun: (run) async => runs?.add(run),
  saveSession: (_) async {},
  clock: () => DateTime(2026, 10, 6, 12),
);

/// Flies a built level through its controller as a player's taps (or, on
/// a test flight of a height mode, a finger's height) do.
void flyBuiltController(PlayController controller, {double seconds = 300}) {
  final sim = controller.simulation!;
  for (var frame = 1; frame <= seconds * 50; frame++) {
    if (sim.phase == RunPhase.ended) break;
    if (sim.hearts < 2) sim.hearts = 3;
    if (controller.mode.controlsHeight) {
      final aim = BuiltPilot.aim(sim);
      controller.standIn((.85 - aim) / .70);
    } else if (rideTheSky(sim)) {
      controller.flap();
    }
    if (frame % 9 == 0 && sim.canShoot) controller.shoot();
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
}

void main() {
  setUpAll(loadFonts);

  group('PlayController', () {
    test('a built level flies its plan and saves its flight', () async {
      final plan = sampleLevel(PlayMode.touch, id: 'u-tapflight1');
      final runs = <RunResult>[];
      final audio = CueAudio();
      final controller = builtController(
        BuiltFlight(BuiltLevel(plan: plan)),
        runs: runs,
        audio: audio,
      );
      expect(controller.routed, isTrue);
      expect(controller.campaign, isFalse);
      await controller.fly();
      final sim = controller.simulation!;
      expect(sim.plan, same(plan));
      expect(controller.recorder!.tape.built, same(plan));
      expect(controller.recorder!.tape.practice, isFalse);
      expect(controller.marks, same(plan.marks));
      flyBuiltController(controller);
      expect(sim.finishLine!.crossed, isTrue);
      await controller.finish();
      expect(controller.stage, PlayStage.celebrating);
      for (var i = 0; i < 100; i++) {
        controller.advance(.02, 0, 2.2);
      }
      expect(controller.stage, PlayStage.results);
      expect(controller.levelComplete, isTrue);
      final run = runs.single;
      expect(run.levelId, plan.id);
      expect(run.levelName, plan.name);
      expect(run.practice, isFalse);
      expect(audio.cues, containsAllInOrder(['finish_snap', 'complete']));
      expect(controller.canSaveSession, isTrue);
      controller.dispose();
    });

    test(
      'a test flight steers a push-up level by touch and keeps nothing',
      () async {
        final plan = sampleLevel(PlayMode.pushUp, id: 'u-pushtest01');
        final runs = <RunResult>[];
        final controller = builtController(
          BuiltFlight(BuiltLevel(plan: plan), test: true),
          runs: runs,
        );
        expect(controller.isTouch, isTrue);
        expect(controller.testFly, isTrue);
        await controller.fly();
        final sim = controller.simulation!;
        expect(controller.recorder!.tape.practice, isTrue);
        expect(
          controller.recorder!.tape.cycleSeconds,
          BuiltPlan.referenceCycle,
        );
        expect(sim.rules.mode, PlayMode.pushUp);
        // The finger's height is the push-up's: the top lifts the bird.
        controller.standIn(1);
        for (var i = 0; i < 200; i++) {
          controller.advance(.02, 0, 2.2);
        }
        expect(sim.birdY, closeTo(.15, 1e-9));
        flyBuiltController(controller);
        expect(sim.endReason, EndReason.completed);
        expect(sim.gates, plan.gates.length);
        await controller.finish();
        expect(controller.result!.practice, isTrue);
        expect(controller.canSaveSession, isFalse);
        // The play screen decides what a test keeps; the run is still handed
        // over so a whole one can mark the level cleared.
        expect(runs.single.practice, isTrue);
        controller.dispose();
      },
    );

    test('a built boss level tells no story', () async {
      final plan = sampleLevel(
        PlayMode.touch,
        id: 'u-bosslevel1',
        gates: 3,
        boss: BossKind.spitterBeetle,
      );
      expect(plan.problem, isNull);
      final controller = builtController(BuiltFlight(BuiltLevel(plan: plan)));
      await controller.fly();
      final voices = controller.audio.voices!;
      expect(voices.level, isNull);
      expect(voices.route, isTrue);
      expect(voices.best, 0);
      final sim = controller.simulation!;
      flyBuiltController(controller, seconds: 60);
      expect(sim.boss ?? sim.vanguard, isNotNull);
      while (sim.boss == null && sim.phase != RunPhase.ended) {
        flyBuiltController(controller, seconds: 1);
      }
      expect(sim.boss, isNotNull);
      expect(BossEncounterArt.bossLine(sim), isNull);
      controller.dispose();
    });
  });

  testWidgets('a built flight ends on its own result, saved to its level', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    await repo.setSetting(SettingKey.reducedMotion, true);
    final plan = sampleLevel(PlayMode.touch, id: 'u-tapwidget1', gates: 4);
    final level = await tester.runAsync(() => repo.builtLevels.create(plan));
    final folder = Directory.systemTemp.createTempSync('built-play');
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
        audioFactoryProvider.overrideWithValue(SilentAudio.new),
        trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repo.close();
      if (folder.existsSync()) folder.deleteSync(recursive: true);
    });
    await tester.runAsync(() => container.read(progressProvider.future));
    await tester.runAsync(() => container.read(builtShelfProvider.future));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              PlayScreen(mode: PlayMode.touch, built: BuiltFlight(level!)),
        ),
        GoRoute(
          path: '/builder',
          builder: (context, state) => const Text('builder'),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: skyTheme(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: UiSounds(play: (_) {}, child: child!),
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
    await tester.runAsync(
      () => game.loaded.timeout(const Duration(seconds: 5)),
    );
    game.pauseEngine();
    expect(find.byKey(const ValueKey('level-stars')), findsOneWidget);
    expect(find.byKey(const ValueKey('level-route')), findsOneWidget);
    flyBuiltController(controller);
    await tester.runAsync(controller.finish);
    for (var i = 0; i < 120; i++) {
      controller.advance(.02, 0, 2.2);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.stage, PlayStage.results);
    expect(find.byType(BuiltResultStage), findsOneWidget);
    expect(find.byType(LevelResultStage), findsNothing);
    // The word drops in letter by letter; it is read out whole.
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('built-result-word')))
          .properties
          .label,
      'Cleared!',
    );
    expect(find.text(plan.name), findsOneWidget);
    // Saved to its level, not to the records.
    await tester.runAsync(() async {
      for (var i = 0; i < 20 && !controller.saved; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    final bests = await tester.runAsync(repo.builtLevels.bests);
    expect(bests!.single.level, plan.id);
    expect(bests.single.stars, greaterThan(0));
    final p = await tester.runAsync(repo.load);
    expect(p!.totalRuns + p.campaignFlights.runs, 0);
    await tester.tap(find.byKey(const ValueKey('built-result-builder')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('builder'), findsOneWidget);
  });
}
