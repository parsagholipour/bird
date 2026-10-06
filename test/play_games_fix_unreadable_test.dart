import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/ui/screen_frame.dart';
import 'package:push_up_bird/ui/settings_screen.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'play_games_sync_test.dart' show FakePlayGames, Phone;

const _garbage = 'not a logbook this build can read';
const _line = 'Cloud save can’t be read';

class _NoSessions extends SessionRepository {
  @override
  Future<void> reset() async {}
}

/// The sync, held at [status].
class _Held extends PlayGamesSync {
  _Held(this.status);
  final PlayGamesStatus status;
  @override
  PlayGamesStatus build() => status;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late List<Phone> phones;
  Future<Phone> phone(FakePlayGames play) async {
    final p = Phone(play);
    phones.add(p);
    await p.container.read(progressProvider.future);
    await p.sync.start();
    return p;
  }

  setUp(() => phones = []);
  tearDown(() async {
    for (final p in phones) {
      await p.dispose();
    }
  });

  test('an unreadable cloud save: its own quiet state, retried like any '
      'sync, never written over', () async {
    final play = FakePlayGames()..cloud = _garbage;
    final p = await phone(play);
    expect(p.status.connected, isTrue);
    expect(p.status.offline, isFalse);
    expect(p.status.unreadable, isTrue);
    expect(play.loads, 1);

    // New progress: not again within the minute, then once.
    await p.fly();
    p.wait(const Duration(seconds: 20));
    await p.sync.calmMoment();
    expect(play.loads, 1);
    p.wait(const Duration(minutes: 1));
    await p.sync.calmMoment();
    expect(play.loads, 2);

    // Calm moments with nothing new here leave the cloud alone.
    for (var i = 0; i < 3; i++) {
      p.wait(const Duration(minutes: 2));
      await p.sync.calmMoment();
    }
    await p.sync.paused();
    expect(play.loads, 2);
    expect(p.status.unreadable, isTrue);
    expect(play.saves, 0);
    expect(play.cloud, _garbage);
  });

  test('a read that failed once: the next retry restores and saves', () async {
    // Another phone's real save.
    final other = FakePlayGames();
    final a = await phone(other);
    await a.fly(stars: 30);
    await a.sync.paused();
    final saved = other.cloud!;

    final play = FakePlayGames()..cloud = _garbage;
    final p = await phone(play);
    expect(p.status.unreadable, isTrue);

    // The cloud reads fine now.
    play.cloud = saved;
    await p.fly(stars: 4);
    p.wait(const Duration(minutes: 2));
    await p.sync.calmMoment();
    expect(p.status.unreadable, isFalse);
    expect(p.status.restored, isTrue);
    expect(play.saves, 1);
    final stars = (await p.container.read(progressProvider.future)).starsEarned;
    expect(stars, 34);
  });

  group('the Settings strip', () {
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

    testWidgets('an unreadable cloud save: still connected, says so, fits', (
      tester,
    ) async {
      tester.view.physicalSize = ScreenFrame.design * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime(2026, 10, 6, 15);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          sessionRepositoryProvider.overrideWithValue(_NoSessions()),
          playGamesProvider.overrideWith(
            () => _Held(
              PlayGamesStatus(
                available: true,
                connected: true,
                unreadable: true,
                savedAt: now.subtract(const Duration(hours: 3)),
              ),
            ),
          ),
          appClockProvider.overrideWithValue(() => now),
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
          child: RepaintBoundary(
            key: const ValueKey('visual-capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: skyTheme(),
              home: const SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text(_line), findsOneWidget);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(_line))
            .didExceedMaxLines,
        isFalse,
        reason: 'the whole line shows',
      );

      // build/visual-review/settings-play-games/9-unreadable.png with
      // --dart-define=CAPTURE_VISUALS=true.
      if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('visual-capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('build/visual-review/settings-play-games')
          ..createSync(recursive: true);
        await File(
          '${folder.path}/9-unreadable.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  });
}
