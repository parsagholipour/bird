import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

/// The games_services plugin's Android side, as its SaveGame.kt answers:
/// `loadGame` fails with the same code whether the snapshot is missing or
/// unreachable. The list comes from PlayGamesGate.kt's `listed`, which
/// says null when Play could answer only from its cache.
class _PlayCloud {
  /// The `logbook` snapshot Play's servers hold.
  String? logbook;

  /// Opening the snapshot fails (offline, a conflict, a timeout).
  bool loadFails = false;

  /// Play answers the list from its cache, which was taken before the
  /// snapshot existed (offline: AnnotatedData.isStale).
  bool staleCache = false;
  bool listFails = false;
  final calls = <MethodCall>[];

  Iterable<String> get methods => calls.map((c) => c.method);

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    final args = (call.arguments as Map?) ?? const {};
    switch (call.method) {
      case 'loadGame':
        if (loadFails || logbook == null) {
          throw PlatformException(code: 'failed_to_load_game');
        }
        return logbook;
      case 'listed':
        if (listFails) throw PlatformException(code: 'failed_to_list');
        if (staleCache) return null;
        return logbook != null && args['name'] == 'logbook';
      case 'saveGame':
        logbook = args['data'] as String;
        return 'success';
    }
    return null;
  }
}

/// The real wrapper, on an Android phone with Play services, signed in.
class _Android extends GooglePlayGames {
  @override
  Future<bool> available() async => true;
  @override
  Future<bool> signedIn() async => true;
  @override
  Future<String?> playerId() async => 'player-1';
}

class _NoSessions extends SessionRepository {
  @override
  Future<void> reset() async {}
}

class _Phone {
  _Phone() {
    container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        sessionRepositoryProvider.overrideWithValue(_NoSessions()),
        playGamesServiceProvider.overrideWithValue(_Android()),
        // No achievement ids: only the logbook talks to Play.
        playAchievementIdsProvider.overrideWithValue(const {}),
        appClockProvider.overrideWithValue(() => now),
      ],
    );
  }
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  late final ProviderContainer container;
  DateTime now = DateTime(2026, 10, 6, 15);

  PlayGamesSync get sync => container.read(playGamesProvider.notifier);
  PlayGamesStatus get status => container.read(playGamesProvider);
  Future<int> stars() async =>
      (await container.read(progressProvider.future)).starsEarned;

  int _n = 0;
  Future<void> fly({int stars = 10}) => container
      .read(progressProvider.notifier)
      .save(
        RunResult(
          id: 'run-${_n++}',
          mode: PlayMode.touch,
          course: FlightCourse.starTrail,
          practice: false,
          score: 5,
          stars: stars,
          repetitions: 0,
          flaps: 3,
          durationSeconds: 20,
          reason: EndReason.collision,
          finishedAt: now,
          bird: 2,
        ),
      );

  Future<void> dispose() async {
    container.dispose();
    await repo.close();
  }
}

/// The plugin's channel, and the app's own gate (PlayGamesGate.kt).
const _channels = [
  MethodChannel('games_services'),
  MethodChannel('push_up_bird/play_games'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late _PlayCloud cloud;
  late List<_Phone> phones;

  Future<_Phone> phone() async {
    final p = _Phone();
    phones.add(p);
    await p.container.read(progressProvider.future);
    return p;
  }

  /// Another phone's 300-star logbook, already in the cloud.
  Future<String> otherPhonesSave() async {
    final other = await phone();
    await other.fly(stars: 300);
    return (await other.repo.exportLogbook()).encode();
  }

  setUp(() {
    phones = [];
    cloud = _PlayCloud();
    for (final channel in _channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, cloud.handle);
    }
  });
  tearDown(() async {
    for (final channel in _channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
    for (final p in phones) {
      await p.dispose();
    }
  });

  group('loading the cloud logbook', () {
    test('a failed load with a stale list is an error, not "none"', () async {
      cloud
        ..logbook = 'saved elsewhere'
        ..loadFails = true
        ..staleCache = true;
      await expectLater(
        GooglePlayGames().loadLogbook(),
        throwsA(isA<PlatformException>()),
      );
      final list = cloud.calls.singleWhere((c) => c.method == 'listed');
      expect((list.arguments as Map)['name'], 'logbook');
    });

    test('only a refreshed list without it means there is none', () async {
      expect(await GooglePlayGames().loadLogbook(), isNull);
    });

    test('a list that cannot load is an error', () async {
      cloud
        ..loadFails = true
        ..listFails = true;
      await expectLater(GooglePlayGames().loadLogbook(), throwsA(anything));
    });
  });

  group('syncing never loses the cloud', () {
    test('a failed load never writes this phone over the cloud', () async {
      final saved = await otherPhonesSave();
      cloud
        ..logbook = saved
        ..loadFails = true
        ..staleCache = true;
      final p = await phone();
      await p.fly(stars: 4);
      await p.sync.start();
      expect(cloud.methods, isNot(contains('saveGame')));
      expect(cloud.logbook, saved);
      expect(p.status.offline, isTrue);
      expect(await p.stars(), 4);

      // Back online: the next calm moment restores and saves the union.
      cloud.loadFails = false;
      p.now = p.now.add(const Duration(minutes: 2));
      await p.fly(stars: 1);
      await p.sync.calmMoment();
      expect(cloud.methods, contains('saveGame'));
      expect(await p.stars(), 305);
    });

    test('an unreadable cloud save is never written over', () async {
      cloud.logbook = 'not a logbook this build can read';
      final p = await phone();
      await p.fly(stars: 7);
      await p.sync.start();
      expect(cloud.methods, isNot(contains('saveGame')));
      expect(cloud.logbook, 'not a logbook this build can read');
      expect(p.status.unreadable, isTrue);
      expect(await p.stars(), 7, reason: 'local progress stays');
    });

    test('no cloud save and no progress here: nothing goes up', () async {
      final p = await phone();
      await p.sync.start();
      expect(cloud.methods, contains('loadGame'));
      expect(cloud.methods, isNot(contains('saveGame')));
      expect(cloud.logbook, isNull);
      expect(p.status.offline, isFalse);

      // The first real progress is saved at the next calm moment.
      await p.fly();
      p.now = p.now.add(const Duration(minutes: 2));
      await p.sync.calmMoment();
      expect(cloud.methods, contains('saveGame'));
      expect(cloud.logbook, isNotNull);
    });
  });
}
