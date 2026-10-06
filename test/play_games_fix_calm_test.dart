import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/passport_progress.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/sky_passport.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/play_screen.dart';

import 'play_games_sync_test.dart' show FakePlayGames, Phone;
import 'play_session_test.dart' show SilentAudio;

/// [FakePlayGames] whose cloud can be held mid-call: the call named
/// [holdAt] waits for [release], and [reached] completes once it waits.
class _Slow extends FakePlayGames {
  String? holdAt;
  var reached = Completer<void>();
  var release = Completer<void>();
  final attempts = <String, int>{};

  void hold(String call) {
    holdAt = call;
    reached = Completer();
    release = Completer();
  }

  Future<void> _gate(String call) async {
    attempts[call] = (attempts[call] ?? 0) + 1;
    if (holdAt != call) return;
    holdAt = null;
    reached.complete();
    await release.future;
  }

  @override
  Future<String?> loadLogbook() async {
    await _gate('load');
    return super.loadLogbook();
  }

  @override
  Future<Map<String, PlayAchievementState>> achievements() async {
    await _gate('achievements');
    return super.achievements();
  }
}

/// Records what the app asks of Play Games, and sends nothing.
class _Spy extends PlayGamesSync {
  int calmMoments = 0, pauses = 0;
  @override
  Future<void> calmMoment() async => calmMoments++;
  @override
  Future<void> paused() async => pauses++;
}

RunResult _run(String id, {int stars = 0, int score = 5}) => RunResult(
  id: id,
  mode: PlayMode.touch,
  course: FlightCourse.starTrail,
  practice: false,
  score: score,
  stars: stars,
  repetitions: 0,
  flaps: 3,
  durationSeconds: 20,
  reason: EndReason.collision,
  finishedAt: DateTime(2026, 10, 6, 15),
  bird: 2,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('the sync re-checks the calm moment', () {
    late List<Phone> phones;
    Future<Phone> phone(FakePlayGames play, {bool start = true}) async {
      final p = Phone(play);
      phones.add(p);
      await p.container.read(progressProvider.future);
      if (start) await p.sync.start();
      return p;
    }

    Future<int> stars(Phone p) async =>
        (await p.container.read(progressProvider.future)).starsEarned;

    setUp(() => phones = []);
    tearDown(() async {
      for (final p in phones) {
        await p.dispose();
      }
    });

    test(
      'a restore waits when a flight begins while the cloud answers',
      () async {
        final play = _Slow();
        final a = await phone(play);
        await a.fly(stars: 300);
        a.wait(const Duration(minutes: 2));
        await a.sync.calmMoment();
        final saves = play.saves;

        final b = await phone(play, start: false);
        play.hold('load');
        final launch = b.sync.start();
        await play.reached.future;
        b.sync.calm = false; // The player took off from home.
        play.release.complete();
        await launch;
        expect(await stars(b), 0, reason: 'no restore mid-flight');
        expect(b.status.restored, isFalse);
        expect(b.status.saving, isFalse);
        expect(play.saves, saves);
        expect(play.unlocks, hasLength(1), reason: "only phone a's");

        // The next calm moment restores at once, throttle or not.
        b.wait(const Duration(seconds: 5));
        b.sync.calm = true;
        await b.sync.calmMoment();
        expect(await stars(b), 300);
        expect(b.status.restored, isTrue);
        expect(play.saves, saves + 1);
      },
    );

    test('an unlock waits when the moment ends before it is sent', () async {
      final play = _Slow();
      final p = await phone(play, start: false);
      // Star Chaser bronze (50 stars) is due.
      await p.fly(stars: 60);
      play.hold('achievements');
      final launch = p.sync.start();
      await play.reached.future;
      p.sync.calm = false;
      play.release.complete();
      await launch;
      expect(play.unlocks, isEmpty);
      expect(play.calls.where((c) => c.startsWith('steps')), isEmpty);

      p.sync.calm = true;
      await p.sync.calmMoment();
      expect(play.unlocks, ['id.starChaserBronze']);
    });

    test('calm moments join one waiting job instead of piling up', () async {
      final play = _Slow();
      final p = await phone(play);
      play.offline = true;
      p.wait(const Duration(minutes: 2));
      await p.fly();
      play.hold('load');
      final first = p.sync.calmMoment();
      await play.reached.future;
      // Home, Settings, home, Settings... while the first job waits.
      final waiting = [for (var i = 0; i < 5; i++) p.sync.calmMoment()];
      for (final job in waiting) {
        expect(identical(job, waiting.first), isTrue);
      }
      expect(identical(first, waiting.first), isFalse);
      play.release.complete();
      await first;
      await Future.wait(waiting);
      expect(play.attempts['load'], 1 + 1 + 1, reason: 'launch, then two');
      // A later calm moment queues afresh.
      p.wait(const Duration(seconds: 5));
      await p.sync.calmMoment();
      expect(play.attempts['load'], 4);
    });

    test('going to the background saves from any off-flight screen', () async {
      final play = _Slow();
      final p = await phone(play);
      final saves = play.saves;
      p.sync.calm = false; // The campaign map: off-flight, not calm.
      await p.fly();
      p.wait(const Duration(seconds: 5));
      await p.sync.paused();
      expect(play.saves, saves + 1);
    });

    test('a background save waits if the app comes back to a flight', () async {
      final play = _Slow();
      final p = await phone(play);
      final saves = play.saves;
      p.sync.calm = false;
      await p.fly();
      play.hold('load');
      final away = p.sync.paused();
      await play.reached.future;
      p.sync.resumed(); // Back, and still not calm.
      play.release.complete();
      await away;
      expect(play.saves, saves);

      p.sync.calm = true;
      await p.sync.calmMoment();
      expect(play.saves, saves + 1);
    });
  });

  group('in the app', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUpAll(() async {
      for (final family in ['Fredoka', 'Nunito']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
      }
    });

    Future<(ProviderContainer, SqliteProgressRepository, _Spy)> open(
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await repo.setSetting(SettingKey.reducedMotion, true);
      final folder = Directory.systemTemp.createTempSync('calm-results');
      final spy = _Spy();
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(folder),
          ),
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
      await tester.runAsync(() => container.read(progressProvider.future));
      appRouter.go('/play/touch');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const PushUpBirdApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return (container, repo, spy);
    }

    dynamic screen(WidgetTester tester) =>
        tester.state(find.byType(PlayScreen));
    PlayController controller(WidgetTester tester) =>
        screen(tester).controller as PlayController;

    Future<void> lifecycle(WidgetTester tester, AppLifecycleState s) async {
      tester.binding.handleAppLifecycleStateChanged(s);
      await tester.pump();
    }

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

    testWidgets('a settled results stage is calm: leaving the app there '
        'saves, flying again ends the moment', (tester) async {
      final (_, _, spy) = await open(tester);
      // Mid-flight, going to the background never saves.
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(spy.pauses, 0);

      await finish(tester);
      await tester.pump(const Duration(seconds: 1));
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(spy.pauses, 0, reason: 'not settled yet');

      await tester.pump(const Duration(seconds: 2));
      expect(spy.calmMoments, 1);
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(spy.pauses, 1, reason: 'the settled results stage saves');

      // Fly again: the moment is over.
      await tester.runAsync(controller(tester).retry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller(tester).stage, isNot(PlayStage.results));
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(spy.pauses, 1);
    });

    testWidgets('a cloud restore is never a medal this flight won', (
      tester,
    ) async {
      final (container, repo, _) = await open(tester);
      await finish(tester);
      await tester.pump(const Duration(seconds: 3));
      ProgressSnapshot progress() => container.read(progressProvider).value!;
      Set<SkyStamp> won() => {
        for (final s in progress().medalsWonSince(
          screen(tester).initialStamps as Map<SkyStamp, StampMedal>,
        ))
          s.stamp,
      };
      expect(won(), isEmpty);

      // The settled stage's sync brings 60 stars from another phone: Star
      // Chaser bronze, which this flight did not win.
      await tester.runAsync(() async {
        await repo.saveRun(_run('restored', stars: 60));
        await container.read(progressProvider.notifier).refresh();
      });
      await tester.pump();
      expect(progress().medals[SkyStamp.starChaser], StampMedal.bronze);
      expect(won(), isEmpty);

      // The flight's own save still counts (Sky Captain bronze at 100).
      await tester.runAsync(
        () => controller(tester).saveRun(_run('own', score: 120)),
      );
      await tester.pump();
      expect(won(), {SkyStamp.skyCaptain});
    });
  });
}
