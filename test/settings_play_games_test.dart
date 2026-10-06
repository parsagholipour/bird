import 'dart:async';
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

class _NoSessions extends SessionRepository {
  @override
  Future<void> reset() async {}
}

/// The sync, held at [status]; Connect waits for [answer].
class _Held extends PlayGamesSync {
  _Held(this.status, {this.answer});
  final PlayGamesStatus status;
  final Completer<bool>? answer;
  int shown = 0, connects = 0;

  @override
  PlayGamesStatus build() => status;
  @override
  Future<bool> connect() async {
    connects++;
    return answer?.future ?? Future.value(false);
  }

  @override
  Future<void> showAchievements() async => shown++;
}

final _now = DateTime(2026, 10, 6, 15);
const _capture = bool.fromEnvironment('CAPTURE_VISUALS');

/// Writes build/visual-review/settings-play-games/NAME.png when run with
/// --dart-define=CAPTURE_VISUALS=true.
Future<void> _snap(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/visual-review/settings-play-games')
      ..createSync(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<_Held> _pump(
  WidgetTester tester,
  _Held sync, {
  bool synced = false,
}) async {
  tester.view.physicalSize = ScreenFrame.design * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  if (synced) await repo.importLogbook(null);
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(_NoSessions()),
      playGamesProvider.overrideWith(() => sync),
      appClockProvider.overrideWithValue(() => _now),
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
  return sync;
}

/// Nothing scrolls or overflows, and every key stays a 48-unit target on
/// the 1000×450 canvas.
void _fits(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    expect(s.position.maxScrollExtent, 0);
  }
  final scale = ScreenFrame.design.height / 450;
  for (final target in find.byType(InkWell).evaluate()) {
    final rect = tester.getRect(find.byWidget(target.widget));
    expect(rect.height / scale, greaterThanOrEqualTo(47.5));
    expect(rect.width / scale, greaterThanOrEqualTo(38));
  }
}

/// The strip's status [line] shows whole, never cut off.
void _whole(WidgetTester tester, String line) => expect(
  tester.renderObject<RenderParagraph>(find.text(line)).didExceedMaxLines,
  isFalse,
  reason: '"$line" fits the strip',
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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

  testWidgets('connected: cloud status and Google achievements', (
    tester,
  ) async {
    final sync = await _pump(
      tester,
      _Held(
        PlayGamesStatus(
          available: true,
          connected: true,
          savedAt: _now.subtract(const Duration(minutes: 2)),
        ),
      ),
    );
    _fits(tester);
    expect(find.text('Play Games'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Saved to cloud · 2 min ago'), findsOneWidget);
    // The lab and About share a row with the strip shown.
    Finder key(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(InkWell));
    expect(
      tester.getRect(key('Camera & tracking lab')).top,
      tester.getRect(key('About & licenses')).top,
    );
    await _snap(tester, '1-connected');
    await tester.tap(find.text('Achievements'));
    await tester.pump();
    expect(sync.shown, 1);
  });

  testWidgets('connected but offline, saving, and just restored', (
    tester,
  ) async {
    await _pump(
      tester,
      _Held(
        PlayGamesStatus(
          available: true,
          connected: true,
          offline: true,
          savedAt: _now.subtract(const Duration(hours: 3)),
        ),
      ),
    );
    _fits(tester);
    expect(find.text('Offline · saved 3 h ago'), findsOneWidget);
    await _snap(tester, '3-offline');
  });

  testWidgets('restored from the cloud', (tester) async {
    await _pump(
      tester,
      _Held(
        PlayGamesStatus(
          available: true,
          connected: true,
          restored: true,
          savedAt: _now,
        ),
      ),
    );
    _fits(tester);
    expect(find.text('Cloud restored · just now'), findsOneWidget);
    await _snap(tester, '4-restored');
  });

  testWidgets('a cloud save from a newer Beakbound: still connected', (
    tester,
  ) async {
    await _pump(
      tester,
      _Held(
        PlayGamesStatus(
          available: true,
          connected: true,
          updateNeeded: true,
          savedAt: _now.subtract(const Duration(hours: 3)),
        ),
      ),
    );
    _fits(tester);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Update Beakbound to sync'), findsOneWidget);
    await _snap(tester, '9-update-needed');
  });

  testWidgets('not connected: Connect, busy, then a quiet failure', (
    tester,
  ) async {
    final answer = Completer<bool>();
    final sync = await _pump(
      tester,
      _Held(const PlayGamesStatus(available: true), answer: answer),
    );
    _fits(tester);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Cloud save & achievements'), findsOneWidget);
    await _snap(tester, '2-not-connected');
    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(sync.connects, 1);
    expect(find.text('Connecting…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Busy: a second tap does nothing.
    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(sync.connects, 1);
    await _snap(tester, '5-connecting');
    answer.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t connect'), findsOneWidget);
    _whole(tester, 'Couldn’t connect');
    _fits(tester);
    await _snap(tester, '6-could-not-connect');
  });

  group('every status line shows whole', () {
    PlayGamesStatus on({
      bool saving = false,
      bool offline = false,
      bool restored = false,
      bool resetElsewhere = false,
      bool updateNeeded = false,
      bool unreadable = false,
      Duration? ago,
    }) => PlayGamesStatus(
      available: true,
      connected: true,
      saving: saving,
      offline: offline,
      restored: restored,
      resetElsewhere: resetElsewhere,
      updateNeeded: updateNeeded,
      unreadable: unreadable,
      savedAt: ago == null ? null : _now.subtract(ago),
    );
    const late = Duration(minutes: 59), days = Duration(days: 30);
    final lines = {
      'Cloud save & achievements': const PlayGamesStatus(available: true),
      'Saving to cloud…': on(saving: true),
      'Offline · not saved yet': on(offline: true),
      'Offline · saved 59 min ago': on(offline: true, ago: late),
      'Update Beakbound to sync': on(updateNeeded: true, ago: late),
      'Cloud save can’t be read': on(unreadable: true, ago: late),
      'Cloud save is on': on(),
      'Reset on another phone': on(
        restored: true,
        resetElsewhere: true,
        ago: Duration.zero,
      ),
      'Cloud restored · 59 min ago': on(restored: true, ago: late),
      'Saved to cloud · 59 min ago': on(ago: late),
      'Saved to cloud · 30 d ago': on(ago: days),
    };
    for (final MapEntry(key: line, value: status) in lines.entries) {
      testWidgets(line, (tester) async {
        await _pump(tester, _Held(status));
        expect(find.text(line), findsOneWidget);
        _whole(tester, line);
        final name = line.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
        await _snap(tester, 'line-$name');
      });
    }
  });

  testWidgets('unavailable: no strip, the old layout', (tester) async {
    await _pump(tester, _Held(const PlayGamesStatus()));
    _fits(tester);
    expect(find.text('Play Games'), findsNothing);
    expect(
      tester.getTopLeft(find.text('About & licenses')).dy,
      greaterThan(tester.getTopLeft(find.text('Camera & tracking lab')).dy),
    );
    await _snap(tester, '7-hidden');
  });

  testWidgets('the reset dialog says the cloud save goes too', (tester) async {
    await _pump(
      tester,
      _Held(const PlayGamesStatus(available: true, connected: true)),
      synced: true,
    );
    await tester.tap(find.text('Reset local progress'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('and your Play Games cloud save'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _snap(tester, '8-reset-dialog');
  });

  testWidgets('the strip is labelled for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pump(tester, _Held(const PlayGamesStatus(available: true)));
      final data = tester
          .getSemantics(find.bySemanticsLabel('Connect Play Games'))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(
        find.bySemanticsLabel('About & licenses, version 1.0.0'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });
}
