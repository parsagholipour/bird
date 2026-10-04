import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/sound_bank.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/ui_sounds.dart';
import 'play_session_test.dart' show SessionSource, SilentAudio;

class CueAudio extends SilentAudio {
  final cues = <String>[];
  @override
  void effect(String name, {int? variant}) => cues.add(name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  /// Opens [route] over a save with [stars] picked up, and returns the
  /// repository, the cues played and a way to wait for a save to land.
  Future<(SqliteProgressRepository, CueAudio)> open(
    WidgetTester tester,
    String route, {
    required int stars,
    Future<void> Function(SqliteProgressRepository)? prepare,
  }) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    await repo.setSetting(SettingKey.reducedMotion, true);
    await repo.saveRun(
      RunResult(
        id: 'trail',
        mode: PlayMode.touch,
        practice: false,
        course: FlightCourse.starTrail,
        score: stars,
        stars: stars,
        repetitions: 0,
        flaps: 10,
        durationSeconds: 30,
        reason: EndReason.collision,
        finishedAt: DateTime(2026, 10, 4),
      ),
    );
    await prepare?.call(repo);
    final audio = CueAudio();
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        audioFactoryProvider.overrideWithValue(() => audio),
        trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(progressProvider.future);
    appRouter.go(route);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PushUpBirdApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    audio.cues.clear();
    return (repo, audio);
  }

  /// Presses [key]; a save, if it starts one, has landed once this returns.
  Future<void> press(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
  }

  /// The cues besides the key click every HomeKey makes as it is pressed.
  List<String> played(CueAudio audio) => [
    for (final cue in audio.cues)
      if (cue != 'ui_tap') cue,
  ];

  testWidgets('the Upgrades screen sounds a choice, a purchase and a no', (
    tester,
  ) async {
    final (repo, audio) = await open(tester, '/upgrades', stars: 130);
    // Looking at another socket sounds; looking at the same one again
    // does not.
    await press(tester, 'upgrade-card-sprint');
    expect(played(audio), [ShopCues.select]);
    await press(tester, 'upgrade-card-sprint');
    expect(played(audio), [ShopCues.select]);
    audio.cues.clear();

    // A purchase sounds once it has gone through.
    await press(tester, 'buy-sprint');
    expect((await tester.runAsync(repo.load))!.upgrades.sprint, 1);
    expect(played(audio), [ShopCues.upgrade]);
    audio.cues.clear();

    // 80 stars cannot pay for level 2 (120): the locked key says no.
    await press(tester, 'buy-sprint');
    expect(played(audio), [ShopCues.denied]);
    expect((await tester.runAsync(repo.load))!.upgrades.sprint, 1);
  });

  testWidgets('the last level of an upgrade gets the bigger cue', (
    tester,
  ) async {
    final (repo, audio) = await open(
      tester,
      '/upgrades',
      stars: 1270,
      prepare: (repo) async {
        for (var i = 0; i < 3; i++) {
          await repo.buyUpgrade(PowerUp.magnet);
        }
      },
    );
    await press(tester, 'upgrade-card-magnet');
    audio.cues.clear();
    await press(tester, 'buy-magnet');
    expect((await tester.runAsync(repo.load))!.upgrades.magnet, 4);
    expect(played(audio), [ShopCues.maxed]);
  });

  testWidgets('the crew screen sounds a look, a pick, a purchase and a no', (
    tester,
  ) async {
    final (repo, audio) = await open(tester, '/birds', stars: 600);
    await press(tester, 'bird-card-1');
    expect(played(audio), [ShopCues.select]);
    audio.cues.clear();

    // Flying with a free bird sounds once the save has gone through.
    await press(tester, 'fly-with-1');
    expect((await tester.runAsync(repo.load))!.settings.bird, 1);
    expect(played(audio), [ShopCues.birdEquip]);
    audio.cues.clear();

    // Orbit costs 1000 and the wallet holds 600: the locked key says no.
    await press(tester, 'bird-card-3');
    audio.cues.clear();
    await press(tester, 'unlock-3');
    expect(played(audio), [ShopCues.denied]);
    expect((await tester.runAsync(repo.load))!.birdUnlocked(3), isFalse);
    audio.cues.clear();

    // Pip costs 500, which it can pay.
    await press(tester, 'bird-card-0');
    audio.cues.clear();
    await press(tester, 'unlock-0');
    expect((await tester.runAsync(repo.load))!.birdUnlocked(0), isTrue);
    expect(played(audio), [ShopCues.birdUnlock]);
  });

  test('every shop cue is in the sound bank', () {
    for (final cue in [
      ShopCues.select,
      ShopCues.upgrade,
      ShopCues.maxed,
      ShopCues.birdUnlock,
      ShopCues.birdEquip,
      ShopCues.denied,
    ]) {
      expect(soundBank, contains(cue), reason: cue);
    }
  });
}
