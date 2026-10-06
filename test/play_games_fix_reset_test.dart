import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/cloud_logbook.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/ui/screen_frame.dart';
import 'package:push_up_bird/ui/settings_screen.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'built_pilot.dart';

// Reset wipes everywhere: a reset on a phone that has synced with the cloud
// starts a fresh adventure on every phone that has synced too (review
// findings #2 and #6).

SqliteProgressRepository _repo([DateTime Function()? clock]) =>
    SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
      clock: clock,
    );

RunResult _flight(
  String id, {
  int stars = 10,
  String? level,
  EndReason reason = EndReason.collision,
  Set<String> feats = const {},
  DateTime? at,
}) => RunResult(
  id: id,
  mode: PlayMode.touch,
  course: FlightCourse.starTrail,
  practice: false,
  score: 20,
  stars: stars,
  repetitions: 0,
  flaps: 5,
  durationSeconds: 30,
  reason: reason,
  finishedAt: at ?? DateTime(2026, 10, 6, 14),
  bird: 2,
  levelId: level,
  feats: feats,
);

/// One sync against the [cloud] string: load, merge, save back.
Future<String> _sync(ProgressRepository repo, String? cloud) async {
  final (merged, _) = await repo.importLogbook(Logbook.decode(cloud));
  return merged.encode();
}

/// Nothing from before a reset: no levels, purchases, birds, story, feats,
/// built levels, co-op, carried rows or flights.
Future<void> _fresh(SqliteProgressRepository repo) async {
  final p = await repo.load();
  expect(p.starsEarned, 0);
  expect(p.starsSpent, 0);
  expect(p.upgrades.shot, 0);
  expect(p.unlockedBirds, isNot(contains(0)));
  expect(p.campaign.cleared(Campaign.level('1-1')!), isFalse);
  expect(p.campaign.storyWatched, isEmpty);
  expect(p.feats, isEmpty);
  expect(p.coop.record(CoopMode.roped).flights, 0);
  expect(p.flightsFlown, 0);
  expect(await repo.builtLevels.level('u-loop000001'), isNull);
}

/// The cloud in memory, shared by every phone.
class _Cloud {
  String? logbook;
}

/// One phone's Play Games: its own sign-in, the shared cloud, no
/// achievements.
class _Play implements PlayGamesService {
  _Play(this.cloud);
  final _Cloud cloud;
  bool signedInAtLaunch = true;

  @override
  Future<bool> available() async => true;
  @override
  Future<bool> signedIn() async => signedInAtLaunch;
  @override
  Future<bool> signIn() async => true;
  @override
  Future<String?> playerId() async => 'player-1';
  @override
  Future<void> showAchievements() async {}
  @override
  Future<Map<String, PlayAchievementState>> achievements() async => {};
  @override
  Future<void> unlock(String id) async {}
  @override
  Future<void> setSteps(String id, int steps) async {}
  @override
  Future<String?> loadLogbook() async => cloud.logbook;
  @override
  Future<void> saveLogbook(String data, String description) async =>
      cloud.logbook = data;
}

class _Sessions extends SessionRepository {
  int resets = 0;
  @override
  Future<void> reset() async => resets++;
}

/// A phone running the app: its own save, which outlives each launch.
class _Phone {
  _Phone(_Cloud cloud) : play = _Play(cloud);
  final _Play play;
  final sessions = _Sessions();
  DateTime now = DateTime(2026, 10, 6, 15);
  late final repo = _repo(() => now);
  ProviderContainer? _container;
  ProviderContainer get container => _container!;

  PlayGamesSync get sync => container.read(playGamesProvider.notifier);
  PlayGamesStatus get status => container.read(playGamesProvider);
  ProgressController get progress => container.read(progressProvider.notifier);
  Future<ProgressSnapshot> get snapshot =>
      container.read(progressProvider.future);

  /// Opens the app (again): the launch check and its sync.
  Future<void> launch({bool signedIn = true}) async {
    _container?.dispose();
    play.signedInAtLaunch = signedIn;
    _container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(sessions),
        playGamesServiceProvider.overrideWithValue(play),
        playAchievementIdsProvider.overrideWithValue(const {}),
        appClockProvider.overrideWithValue(() => now),
      ],
    );
    await snapshot;
    await sync.start();
  }

  int _n = 0;
  Future<void> fly({int stars = 10}) {
    now = now.add(const Duration(minutes: 2));
    return progress.save(_flight('run-${_n++}', stars: stars, at: now));
  }

  Future<void> dispose() async {
    _container?.dispose();
    await repo.close();
  }
}

/// The sync, held at [status].
class _Held extends PlayGamesSync {
  _Held(this.status);
  final PlayGamesStatus status;
  @override
  PlayGamesStatus build() => status;
}

/// Settings on a phone that has [synced] with the cloud before, or not.
Future<void> _settings(
  WidgetTester tester,
  PlayGamesStatus status, {
  required bool synced,
}) async {
  tester.view.physicalSize = ScreenFrame.design * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _repo();
  if (synced) await repo.importLogbook(null);
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(_Sessions()),
      playGamesProvider.overrideWith(() => _Held(status)),
      appClockProvider.overrideWithValue(() => DateTime(2026, 10, 6, 15)),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await repo.close();
  });
  await container.read(progressProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: skyTheme(), home: const SettingsScreen()),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
}

Future<void> _openReset(WidgetTester tester) async {
  await tester.tap(find.text('Reset local progress'));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
  expect(find.text('Start a fresh adventure?'), findsOneWidget);
}

const _cloudSentence = 'and your Play Games cloud save';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('#2 a reset reaches every phone that synced', () {
    test(
      'the reviewer\'s steps: nothing comes back from before the reset',
      () async {
        var now = DateTime(2026, 10, 6, 12);
        final a = _repo(() => now), b = _repo(() => now);
        addTearDown(a.close);
        addTearDown(b.close);
        // 1. A plays, buys an upgrade and a bird, and syncs.
        await a.saveRun(_flight('a1', stars: 700));
        await a.saveRun(
          _flight(
            'a2',
            stars: 40,
            level: '1-1',
            reason: EndReason.completed,
            feats: {'pigeonFreed'},
          ),
        );
        await a.buyUpgrade(PowerUp.shot);
        await a.unlockBird(0);
        await a.markStoryWatched(CampaignStory.prologue);
        await a.saveCoop(CoopMode.roped, _flight('c1'));
        await a.builtLevels.create(
          sampleLevel(PlayMode.touch, id: 'u-loop000001'),
        );
        var cloud = await _sync(a, null);
        // 2. B restores, and flies once itself.
        cloud = await _sync(b, cloud);
        expect((await b.load()).upgrades.shot, 1);
        await b.saveRun(_flight('b1', stars: 30));
        cloud = await _sync(b, cloud);
        // 3. A resets while connected.
        now = now.add(const Duration(minutes: 5));
        await a.reset(cloud: true);
        cloud = await _sync(a, cloud);
        final epoch = Logbook.decode(cloud)!.epoch;
        // 4. B syncs, then A syncs.
        cloud = await _sync(b, cloud);
        cloud = await _sync(a, cloud);
        await _fresh(a);
        await _fresh(b);
        final last = Logbook.decode(cloud)!;
        expect(last.epoch, epoch);
        expect(last.upgrades.shot, 0);
        expect(last.levels, isEmpty);
        expect(
          last.devices.values
              .expand((d) => d.records.values)
              .map((r) => r.runs),
          everyElement(0),
        );
      },
    );

    test('a fresh start on another phone keeps this phone\'s settings and '
        'voice-over memory', () async {
      var now = DateTime(2026, 10, 6, 12);
      final a = _repo(() => now), b = _repo(() => now);
      addTearDown(a.close);
      addTearDown(b.close);
      await a.saveRun(_flight('a1', stars: 70));
      var cloud = await _sync(b, await _sync(a, null));
      await b.saveRun(_flight('b1', stars: 30));
      await b.setSetting(SettingKey.music, false);
      await b.setSetting(SettingKey.reducedMotion, true);
      await b.saveFlightVoices('memory');
      now = now.add(const Duration(minutes: 5));
      await a.reset(cloud: true);
      cloud = await _sync(b, await _sync(a, cloud));
      await _fresh(b);
      final settings = (await b.load()).settings;
      expect(settings.music, isFalse);
      expect(settings.reducedMotion, isTrue);
      expect(await b.loadFlightVoices(), 'memory');
    });

    test(
      'it happens once: later syncs merge again, with no ping-pong',
      () async {
        var now = DateTime(2026, 10, 6, 12);
        final a = _repo(() => now), b = _repo(() => now);
        addTearDown(a.close);
        addTearDown(b.close);
        await a.saveRun(_flight('a1', stars: 70));
        var cloud = await _sync(b, await _sync(a, null));
        now = now.add(const Duration(minutes: 5));
        await a.reset(cloud: true);
        cloud = await _sync(a, cloud);
        final epoch = Logbook.decode(cloud)!.epoch;
        await a.saveRun(_flight('a2', stars: 20));
        cloud = await _sync(a, cloud);
        cloud = await _sync(b, cloud);
        expect((await b.load()).starsEarned, 20);
        await b.saveRun(_flight('b1', stars: 10));
        for (var i = 0; i < 3; i++) {
          cloud = await _sync(b, cloud);
          cloud = await _sync(a, cloud);
        }
        for (final repo in [a, b]) {
          expect((await repo.load()).starsEarned, 30);
        }
        expect(Logbook.decode(cloud)!.epoch, epoch);
      },
    );

    test('a phone that never synced keeps its own progress', () async {
      var now = DateTime(2026, 10, 6, 12);
      final a = _repo(() => now), c = _repo(() => now);
      addTearDown(a.close);
      addTearDown(c.close);
      await a.saveRun(_flight('a1', stars: 70));
      var cloud = await _sync(a, null);
      now = now.add(const Duration(minutes: 5));
      await a.reset(cloud: true);
      cloud = await _sync(a, cloud);
      // C was played offline and connects for the first time.
      await c.saveRun(_flight('c1', stars: 60));
      await c.buyUpgrade(PowerUp.shot);
      cloud = await _sync(c, cloud);
      expect((await c.load()).starsEarned, 60);
      expect((await c.load()).upgrades.shot, 1);
      await _sync(a, cloud);
      expect((await a.load()).starsEarned, 60);
    });

    test(
      'a stale cloud copy (a lower epoch) never resets this phone',
      () async {
        var now = DateTime(2026, 10, 6, 12);
        final a = _repo(() => now);
        addTearDown(a.close);
        await a.saveRun(_flight('a1', stars: 70));
        final old = await _sync(a, null);
        now = now.add(const Duration(minutes: 5));
        await a.reset(cloud: true);
        await a.saveRun(_flight('a2', stars: 20));
        await _sync(a, old);
        // The old copy comes back once more, as a lost write might.
        final cloud = await _sync(a, old);
        expect((await a.load()).starsEarned, 20);
        expect(Logbook.decode(cloud)!.epoch, greaterThan(0));
      },
    );
  });

  group('#6 the reset follows "synced before", not this session', () {
    // The real fonts, so the strip's line is measured as on a phone.
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
    late List<_Phone> phones;
    setUp(() => phones = []);
    tearDown(() async {
      for (final p in phones) {
        await p.dispose();
      }
    });
    _Phone phone(_Cloud cloud) {
      final p = _Phone(cloud);
      phones.add(p);
      return p;
    }

    test(
      'a reset while the launch sign-in failed still clears the cloud',
      () async {
        final cloud = _Cloud();
        final a = phone(cloud);
        await a.launch();
        await a.fly(stars: 100);
        await a.sync.paused();
        // Next launch the automatic sign-in times out, and the player resets.
        await a.launch(signedIn: false);
        expect(a.status.connected, isFalse);
        await a.progress.reset();
        expect((await a.snapshot).starsEarned, 0);
        // The launch after that syncs: the cloud is cleared, not restored.
        await a.launch();
        expect((await a.snapshot).starsEarned, 0);
        final fresh = Logbook.decode(cloud.logbook)!;
        expect(
          fresh.devices.values
              .expand((d) => d.records.values)
              .map((r) => r.runs),
          everyElement(0),
        );
      },
    );

    test('the other phone starts afresh at its next sync; its saved '
        'sessions stay', () async {
      final cloud = _Cloud();
      final a = phone(cloud), b = phone(cloud);
      await a.launch();
      await a.fly(stars: 100);
      await a.progress.buyUpgrade(PowerUp.shot);
      await a.sync.paused();
      await b.launch();
      expect((await b.snapshot).upgrades.shot, 1);
      await a.progress.reset();
      await a.sync.paused();
      await b.launch();
      final p = await b.snapshot;
      expect(p.starsEarned, 0);
      expect(p.upgrades.shot, 0);
      expect(b.sessions.resets, 0);
      expect(b.status.resetElsewhere, isTrue);
      await a.launch();
      expect((await a.snapshot).upgrades.shot, 0);
      expect(a.status.resetElsewhere, isFalse);
      // B's next save is an ordinary one again.
      await b.fly();
      await b.sync.paused();
      expect(b.status.resetElsewhere, isFalse);
    });

    test(
      'a first connect to a cloud reset earlier says nothing of a reset',
      () async {
        final cloud = _Cloud();
        final a = phone(cloud), c = phone(cloud);
        await a.launch();
        await a.fly(stars: 100);
        await a.progress.reset();
        await a.sync.paused();
        await c.launch(signedIn: false);
        await c.fly(stars: 60);
        await c.sync.connect();
        expect(c.status.resetElsewhere, isFalse);
        expect((await c.snapshot).starsEarned, 60);
      },
    );

    testWidgets('the dialog names the cloud on a phone that synced, even '
        'when not connected now', (tester) async {
      await _settings(
        tester,
        const PlayGamesStatus(available: true),
        synced: true,
      );
      await _openReset(tester);
      expect(find.textContaining(_cloudSentence), findsOneWidget);
    });

    testWidgets('a phone that never synced leaves the cloud out, even when '
        'connected', (tester) async {
      await _settings(
        tester,
        const PlayGamesStatus(available: true, connected: true),
        synced: false,
      );
      await _openReset(tester);
      expect(find.textContaining(_cloudSentence), findsNothing);
    });

    testWidgets('the strip says when another phone reset the progress', (
      tester,
    ) async {
      await _settings(
        tester,
        PlayGamesStatus(
          available: true,
          connected: true,
          restored: true,
          resetElsewhere: true,
          savedAt: DateTime(2026, 10, 6, 15),
        ),
        synced: true,
      );
      expect(find.text('Reset on another phone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
