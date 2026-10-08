import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/built_level.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/domain/tutorial.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/language_providers.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/home_screen.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'package:push_up_bird/ui/tutorial_finale.dart';
import 'package:push_up_bird/ui/tutorial_screen.dart';
import 'package:push_up_bird/ui/ui_sounds.dart';
import 'package:push_up_bird/ui/welcome_screen.dart';

import 'campaign_play_test.dart' show CueAudio, loadFonts;
import 'play_session_test.dart' show SessionSource, SilentAudio;
import 'recorded_flight.dart' show rideTheSky;

/// Renders to build/visual-review/tutorial/ when set (for a look by eye).
final _capture = Platform.environment['TUTORIAL_CAPTURE'] == '1';

Future<void> _save(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('tutorial-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/visual-review/tutorial/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

PlayController _controller({List<RunResult>? runs, CueAudio? audio}) =>
    PlayController(
      mode: PlayMode.touch,
      built: BuiltFlight(TutorialPlan.level),
      coach: TutorialCoach(),
      source: null,
      audio: audio ?? CueAudio(),
      saveRun: (run) async => runs?.add(run),
      saveSession: (_) async {},
      clock: () => DateTime(2026, 10, 8, 9),
    );

/// Advances a tutorial controller through the countdown.
void _launch(PlayController controller) {
  for (var i = 0; i < 200 && !controller.simulation!.started; i++) {
    controller.advance(.02, 0, 2.2);
  }
}

/// Plays flight school through its controller as a new player would: does
/// what each held lesson asks, a beat later, and flies the campaign bot's
/// lane in between, shooting now and then. Stops at the end or after
/// [seconds] of frames.
void _flyLesson(
  PlayController controller, {
  double seconds = 400,
  bool Function()? stop,
}) {
  final sim = controller.simulation!;
  final coach = controller.coach!;
  var held = 0, charging = 0;
  for (var frame = 1; frame <= seconds * 50; frame++) {
    if (sim.phase == RunPhase.ended || (stop?.call() ?? false)) break;
    if (coach.holding && ++held >= 25) {
      held = 0;
      switch (coach.waitingFor) {
        case CoachGesture.tap:
          controller.flap();
        case CoachGesture.shoot:
          controller.startCharge();
          controller.shoot();
        case CoachGesture.holdShoot:
          controller.startCharge();
          charging = 1;
        case CoachGesture.sprint:
          controller.sprint();
        case CoachGesture.none:
          break;
      }
    } else if (!coach.holding) {
      if (rideTheSky(sim)) controller.flap();
      if (charging > 0 && ++charging > 60) {
        controller.shoot();
        charging = 0;
      } else if (charging == 0 && frame % 9 == 0 && sim.canShoot) {
        controller.startCharge();
        controller.shoot();
      }
    }
    controller.advance(.02, 0, 2.2);
    controller.tick();
  }
}

void main() {
  setUpAll(loadFonts);

  group('the flight school controller', () {
    test(
      'a held lesson stops time until the player does what it asks',
      () async {
        final audio = CueAudio();
        final controller = _controller(audio: audio);
        expect(controller.tutorial, isTrue);
        await controller.fly();
        _launch(controller);
        final sim = controller.simulation!;
        final coach = controller.coach!;
        // The first lesson holds at once: tap to flap.
        controller.advance(.02, 0, 2.2);
        controller.tick();
        expect(coach.holding, isTrue);
        expect(coach.waitingFor, CoachGesture.tap);
        expect(coach.line, CoachLine.flap);
        for (var i = 0; i < 50; i++) {
          controller.advance(.02, 0, 2.2);
        }
        final frozen = sim.elapsed;
        expect(coach.timeScale, 0);
        for (var i = 0; i < 100; i++) {
          controller.advance(.02, 0, 2.2);
        }
        expect(sim.elapsed, frozen, reason: 'time stands still');
        // Only what the lesson asks for lets it go: Shoot does not.
        controller.startCharge();
        expect(coach.holding, isTrue);
        expect(sim.charging, isFalse);
        controller.flap();
        expect(coach.holding, isFalse);
        controller.advance(.02, 0, 2.2);
        expect(sim.elapsed, greaterThan(frozen));
        expect(sim.flaps, 1);
        controller.dispose();
      },
    );

    test(
      'the whole lesson flies to the rookie captain and saves nothing',
      () async {
        final runs = <RunResult>[];
        final audio = CueAudio();
        final controller = _controller(runs: runs, audio: audio);
        await controller.fly();
        _launch(controller);
        _flyLesson(controller);
        final sim = controller.simulation!;
        expect(sim.endReason, EndReason.completed);
        expect(controller.coach!.lesson, TutorialLesson.victory);
        await controller.finish();
        for (var i = 0; i < 150; i++) {
          controller.advance(.02, 0, 2.2);
        }
        expect(controller.stage, PlayStage.results);
        expect(runs, hasLength(1), reason: 'handed to saveRun, which drops it');
        // The bird's own chatter makes way for Bill.
        expect(controller.audio.voices, isNull);
        controller.dispose();
      },
    );
  });

  group('screens', () {
    late SqliteProgressRepository repo;
    late ProviderContainer container;

    Future<void> boot(
      WidgetTester tester, {
      required String at,
      bool firstLaunch = true,
      bool done = false,
    }) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await tester.runAsync(() async {
        await repo.setSetting(SettingKey.reducedMotion, true);
        if (done) await repo.setSetting(SettingKey.tutorialDone, true);
      });
      container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          audioFactoryProvider.overrideWithValue(SilentAudio.new),
          trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
          firstLaunchTutorialProvider.overrideWithValue(firstLaunch),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        await tester.runAsync(repo.close);
        L10n.debugReset();
      });
      await tester.runAsync(() => container.read(progressProvider.future));
      final router = GoRouter(
        initialLocation: at,
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/welcome',
            builder: (context, state) => const WelcomeScreen(),
          ),
          GoRoute(
            path: '/tutorial',
            builder: (context, state) => const TutorialScreen(),
            routes: [
              GoRoute(
                path: 'fly',
                builder: (context, state) => PlayScreen(
                  key: ValueKey(state.uri.toString()),
                  mode: PlayMode.touch,
                  tutorial: true,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/campaign',
            builder: (context, state) => const Text('campaign map'),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              theme: skyTheme(),
              locale: ref.watch(appLocaleProvider),
              supportedLocales: L10n.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: RepaintBoundary(
                  key: const ValueKey('tutorial-capture'),
                  child: UiSounds(play: (_) {}, child: child!),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('a new player starts at the language screen', (tester) async {
      await boot(tester, at: '/');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      // English on an English phone, marked as the phone's.
      expect(find.text('Choose your language'), findsOneWidget);
      expect(find.text('Your phone’s language'), findsOneWidget);
      await tester.runAsync(() async {
        final context = tester.element(find.byType(WelcomeScreen));
        for (final asset in birdAssets) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pump(const Duration(milliseconds: 300));
      await _save(tester, 'welcome-en');
      // A tap switches the whole screen to that language.
      await tester.tap(find.byKey(const ValueKey('welcome-fr')));
      await settle(tester);
      expect(container.read(appLanguageProvider), AppLanguage.fr);
      expect(
        find.text(
          lookupAppLocalizations(AppLanguage.fr.locale).welcomeContinue,
        ),
        findsOneWidget,
      );
      await _save(tester, 'welcome-fr');
      await tester.tap(find.byKey(const ValueKey('welcome-go')));
      await settle(tester);
      expect(find.byType(TutorialScreen), findsOneWidget);
      await _save(tester, 'intro');
    });

    testWidgets('a player who has flown before goes straight Home', (
      tester,
    ) async {
      await boot(tester, at: '/', done: true);
      await settle(tester);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('tests keep Home unless they ask for the first launch', (
      tester,
    ) async {
      await boot(tester, at: '/', firstLaunch: false);
      await settle(tester);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('skipping flight school is asked once and remembered', (
      tester,
    ) async {
      await boot(tester, at: '/tutorial');
      await tester.tap(find.byKey(const ValueKey('tutorial-skip')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Skip flight school?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tutorial-skip-cancel')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TutorialScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tutorial-skip')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('tutorial-skip-confirm')));
      await settle(tester);
      expect(find.text('campaign map'), findsOneWidget);
      final saved = await tester.runAsync(repo.load);
      expect(saved!.settings.tutorialDone, isTrue);
    });

    testWidgets('the lesson coaches, ends on the licence and opens the map', (
      tester,
    ) async {
      await boot(tester, at: '/tutorial/fly');
      final dynamic state = tester.state(find.byType(PlayScreen));
      final controller = state.controller as PlayController;
      await tester.runAsync(() async {
        for (var i = 0; i < 50 && controller.simulation == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();
      final game = tester
          .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
          .game!;
      await tester.runAsync(
        () => game.loaded.timeout(const Duration(seconds: 5)),
      );
      game.pauseEngine();
      _launch(controller);
      controller.advance(.02, 0, 2.2);
      for (var i = 0; i < 30; i++) {
        controller.advance(.02, 0, 2.2);
      }
      await tester.pump();
      expect(find.text('Tap anywhere to flap your wings!'), findsOneWidget);
      expect(find.byKey(const ValueKey('coach-prompt')), findsOneWidget);
      await _save(tester, 'hold-tap');
      // On to the shoot lesson, and its spotlight on Shoot.
      _flyLesson(
        controller,
        stop: () => controller.coach!.waitingFor == CoachGesture.shoot,
      );
      for (var i = 0; i < 30; i++) {
        controller.advance(.02, 0, 2.2);
      }
      await tester.pump();
      expect(find.text('A bat! Tap Shoot to throw a pebble.'), findsOneWidget);
      await _save(tester, 'hold-shoot');
      _flyLesson(
        controller,
        stop: () => controller.coach!.waitingFor == CoachGesture.sprint,
      );
      for (var i = 0; i < 30; i++) {
        controller.advance(.02, 0, 2.2);
      }
      await tester.pump();
      await _save(tester, 'hold-sprint');
      _flyLesson(controller, stop: () => controller.simulation!.boss != null);
      _flyLesson(controller, seconds: 12);
      await tester.pump();
      await _save(tester, 'boss');
      // The pause card offers the way out.
      controller.pause();
      await tester.pump();
      expect(find.byKey(const ValueKey('pause-skip-lesson')), findsOneWidget);
      await _save(tester, 'paused');
      await tester.runAsync(controller.resume);
      _flyLesson(controller);
      await tester.runAsync(controller.finish);
      for (var i = 0; i < 150; i++) {
        controller.advance(.02, 0, 2.2);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TutorialFinale), findsOneWidget);
      await _save(tester, 'outro');
      // Through the pirate's retreat to the licence.
      for (
        var i = 0;
        i < 12 && find.byType(CourierLicence).evaluate().isEmpty;
        i++
      ) {
        await tester.tap(find.byKey(const ValueKey('tutorial-outro')));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(CourierLicence), findsOneWidget);
      expect(find.text('Courier licence'), findsOneWidget);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await _save(tester, 'licence');
      final saved = await tester.runAsync(repo.load);
      expect(saved!.settings.tutorialDone, isTrue);
      expect(saved.flightsFlown, 0, reason: 'flight school is saved nowhere');
      await tester.tap(find.byKey(const ValueKey('licence-start')));
      await settle(tester);
      expect(find.text('campaign map'), findsOneWidget);
    });
  });
}
