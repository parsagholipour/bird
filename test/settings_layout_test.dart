import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/ui/settings_screen.dart';
import 'package:push_up_bird/ui/theme.dart';

class _Repo extends SqliteProgressRepository {
  _Repo({this.gate, this.fail = false})
    : super(ProgressDatabase(NativeDatabase.memory()));
  final Completer<void>? gate;
  final bool fail;

  @override
  Future<ProgressSnapshot> load() async {
    await gate?.future;
    if (fail) throw StateError('database unavailable');
    return super.load();
  }
}

class _NoSessions extends SessionRepository {
  @override
  Future<void> reset() async {}
}

const _capture = bool.fromEnvironment('CAPTURE_VISUALS');
const _phone = Size(800, 360);

/// Writes build/visual-review/settings/NAME.png when run with
/// --dart-define=CAPTURE_VISUALS=true, and does nothing otherwise.
Future<void> _snap(WidgetTester tester, String name, double ratio) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/visual-review/settings')
      ..createSync(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<(ProviderContainer, _Repo)> _pump(
  WidgetTester tester,
  Size size, {
  double dpr = 2,
  double textScale = 1,
  bool disableAnimations = false,
  Completer<void>? gate,
  bool fail = false,
  Map<SettingKey, bool> settings = const {},
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final repo = _Repo(gate: gate, fail: fail);
  if (gate == null && !fail) {
    for (final e in settings.entries) {
      await repo.setSetting(e.key, e.value);
    }
  }
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(_NoSessions()),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await repo.close();
  });
  if (gate == null && !fail) await container.read(progressProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: const ValueKey('visual-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: skyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
          home: const SettingsScreen(),
        ),
      ),
    ),
  );
  // Let the bird art decode before a frame is captured.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
  return (container, repo);
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

  for (final (name, size, dpr) in [
    ('640x360', const Size(640, 360), 2.0),
    ('800x360', _phone, 2.0),
    ('1000x450', const Size(1000, 450), 2.0),
    ('915x412', const Size(915, 412), 2.0),
    // A 20:9 phone: 2400x1080 physical pixels at 2.625 dpr.
    ('2400x1080', const Size(2400, 1080) / 2.625, 2.625),
  ]) {
    testWidgets('settings fit a $name screen at full size', (tester) async {
      await _pump(tester, size, dpr: dpr);
      expect(tester.takeException(), isNull);
      expect(find.byType(Switch), findsNWidgets(4));
      // Nothing may need scrolling, and every target must stay 48 canvas
      // pixels once the 1000x450 canvas is scaled to the screen.
      for (final s in tester.stateList<ScrollableState>(
        find.byType(Scrollable),
      )) {
        expect(s.position.maxScrollExtent, 0);
      }
      final scale = [
        size.width / 1000,
        size.height / 450,
      ].reduce((a, b) => a < b ? a : b);
      for (final target in find.byType(InkWell).evaluate()) {
        final rect = tester.getRect(find.byWidget(target.widget));
        expect(rect.height / scale, greaterThanOrEqualTo(47.5));
        expect(rect.width / scale, greaterThanOrEqualTo(38));
      }
      await _snap(tester, 'on-$name', dpr);
    });
  }

  testWidgets('settings states stay legible when switched off or mixed', (
    tester,
  ) async {
    await _pump(
      tester,
      _phone,
      settings: {
        SettingKey.music: false,
        SettingKey.effects: false,
        SettingKey.voices: false,
        SettingKey.reducedMotion: false,
      },
    );
    expect(find.text('OFF'), findsNWidgets(4));
    await _snap(tester, 'off-800x360', 2);
    await tester.tap(find.text('Sound effects'));
    await tester.pumpAndSettle();
    expect(find.text('ON'), findsOneWidget);
    expect(find.text('OFF'), findsNWidgets(3));
    await _snap(tester, 'mixed-800x360', 2);
    await tester.tap(find.text('Sky Club soundtrack'));
    await tester.tap(find.text('Character voices'));
    await tester.tap(find.text('Reduced motion'));
    await tester.pumpAndSettle();
    expect(find.text('ON'), findsNWidgets(4));
    await _snap(tester, 'all-on-800x360', 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard focus is drawn as a ring on rows and actions', (
    tester,
  ) async {
    await _pump(tester, _phone);
    List<BoxShadow> shadowsOf(String text) =>
        (tester
                    .widget<AnimatedContainer>(
                      find
                          .ancestor(
                            of: find.text(text),
                            matching: find.byType(AnimatedContainer),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration)
            .boxShadow!;
    expect(shadowsOf('Sky Club soundtrack'), hasLength(1));
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    // Back button, then the first row.
    expect(shadowsOf('Sky Club soundtrack'), hasLength(3));
    await _snap(tester, 'focus-row-800x360', 2);
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    await _snap(tester, 'focus-action-800x360', 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pressing sinks a row and hovering tints an action', (
    tester,
  ) async {
    await _pump(tester, _phone);
    final row = find.ancestor(
      of: find.text('Sound effects'),
      matching: find.byType(InkWell),
    );
    final resting = tester.getTopLeft(row).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Sound effects')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(row).dy, greaterThan(resting));
    await _snap(tester, 'pressed-800x360', 2);
    await gesture.up();
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('About & licenses')));
    await tester.pumpAndSettle();
    await _snap(tester, 'hover-800x360', 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading looks intentional and unlocks when settings arrive', (
    tester,
  ) async {
    final gate = Completer<void>();
    await _pump(tester, _phone, gate: gate);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Sky Club soundtrack'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(tester.widget<Switch>(find.byType(Switch).at(i)).onChanged, null);
    }
    await _snap(tester, 'loading-800x360', 2);
    gate.complete();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      expect(
        tester.widget<Switch>(find.byType(Switch).at(i)).onChanged,
        isNotNull,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed load offers a way to try again', (tester) async {
    await _pump(tester, _phone, fail: true);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Reset local progress'), findsOneWidget);
    await _snap(tester, 'error-800x360', 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large system text scrolls instead of overflowing', (
    tester,
  ) async {
    await _pump(tester, _phone, textScale: 1.3);
    expect(tester.takeException(), isNull);
    await _snap(tester, 'scale130-800x360', 2);
    await tester.ensureVisible(find.text('Reduced motion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reduced motion'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).at(3)).value, isTrue);
    await tester.ensureVisible(find.text('Reset local progress'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion removes the settings transitions', (
    tester,
  ) async {
    await _pump(tester, _phone, disableAnimations: true);
    for (final box in tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    )) {
      expect(box.duration, Duration.zero);
    }
    await tester.tap(find.text('Sound effects'));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actions are labelled buttons', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pump(tester, _phone);
      for (final label in [
        'Camera & tracking lab',
        'About & licenses, version 1.0.0',
        'Reset local progress',
      ]) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        final data = node.getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue, reason: label);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }
      expect(find.byTooltip('Back home'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reset always asks first and keeping progress is the default', (
    tester,
  ) async {
    final (container, repo) = await _pump(
      tester,
      _phone,
      settings: {SettingKey.music: false},
    );
    await tester.tap(find.text('Reset local progress'));
    await tester.pumpAndSettle();
    expect(find.text('Start a fresh adventure?'), findsOneWidget);
    await _snap(tester, 'dialog-800x360', 2);
    // Enter activates the focused button, which must be the safe one.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Start a fresh adventure?'), findsNothing);
    expect(container.read(progressProvider).requireValue.settings.music, false);
    expect((await repo.load()).settings.music, false);

    await tester.tap(find.text('Reset local progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep my progress'));
    await tester.pumpAndSettle();
    expect((await repo.load()).settings.music, false);

    await tester.tap(find.text('Reset local progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset everything'));
    await tester.pumpAndSettle();
    expect(find.text('A fresh start. Pip is ready for you.'), findsOneWidget);
    expect((await repo.load()).settings.music, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the reset dialog fits a very small phone', (tester) async {
    await _pump(tester, const Size(640, 360));
    await tester.tap(find.text('Reset local progress'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _snap(tester, 'dialog-640x360', 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await _snap(tester, 'dialog-focus-reset-640x360', 2);
  });
}
