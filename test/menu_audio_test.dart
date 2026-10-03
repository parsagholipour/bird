import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/world_region.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/game/audio.dart';
import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio, SessionSource;

class MenuAudioSpy extends SilentAudio {
  bool playing = false;
  SkyMusic? track;
  @override
  Future<void> configure(
    GameSettings settings, {
    bool active = true,
    SkyMusic track = SkyMusic.flight,
  }) async {
    playing = settings.music && active;
    this.track = track;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });
  testWidgets('menu music follows navigation, setting and app visibility', (
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
    final players = <MenuAudioSpy>[];
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        audioFactoryProvider.overrideWithValue(() {
          final audio = MenuAudioSpy();
          players.add(audio);
          return audio;
        }),
        trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
    });
    await container.read(progressProvider.future);
    appRouter.go('/');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PushUpBirdApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(players, isNotEmpty, reason: 'The home menu must have a soundtrack');
    final menu = players.first;
    expect(menu.playing, isTrue);
    expect(menu.track, SkyMusic.menu);
    appRouter.go('/settings');
    await tester.pumpAndSettle();
    expect(menu.playing, isTrue);
    await container
        .read(progressProvider.notifier)
        .setting(SettingKey.music, false);
    await tester.pumpAndSettle();
    expect(menu.playing, isFalse);
    await container
        .read(progressProvider.notifier)
        .setting(SettingKey.music, true);
    await tester.pumpAndSettle();
    expect(menu.playing, isTrue);
    appRouter.go('/play/touch');
    // Flight hosts a live game loop, which never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      menu.playing,
      isFalse,
      reason: 'Do not layer the menu track over gameplay',
    );
    expect(players.last.playing, isTrue);
    expect(players.last.track, SkyMusic.flight);
    appRouter.go('/');
    await tester.pumpAndSettle();
    expect(menu.playing, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(menu.playing, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(menu.playing, isTrue);
  });

  testWidgets('a campaign level flies to its region\'s song', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    // The jungle's three levels are cleared, so Brazil's first one opens.
    await tester.runAsync(() async {
      await repo.setSetting(SettingKey.reducedMotion, true);
      for (final scene in CampaignStory.scenes) {
        await repo.markStoryWatched(scene);
      }
      for (final id in ['1-1', '1-2', '1-3']) {
        await repo.saveRun(
          levelRun('seed-$id', id, stars: Campaign.level(id)!.marks.two),
        );
      }
    });
    final players = <MenuAudioSpy>[];
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        audioFactoryProvider.overrideWithValue(() {
          final audio = MenuAudioSpy();
          players.add(audio);
          return audio;
        }),
        trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.runAsync(repo.close);
    });
    await tester.runAsync(() => container.read(progressProvider.future));
    final brazil = Campaign.level('1-4')!;
    expect(brazil.region, WorldRegion.brazil);
    appRouter.go('/play/touch?level=${brazil.id}');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PushUpBirdApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(players.last.playing, isTrue);
    expect(players.last.track, SkyMusic.brazil);

    // The jungle keeps the original flight song.
    appRouter.go('/play/touch?level=1-1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(players.last.track, SkyMusic.flight);
  });
}
