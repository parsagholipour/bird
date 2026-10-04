// Polish captures for Home's Campaign key: Home with each of the four birds
// at the three phone sizes, a zoomed view of the key, its pressed state, and
// the key with everything finished.
//
// Run with `--dart-define=CAPTURE_POLISH=true` to write PNGs to
// build/visual-review/campaign/polish/home-campaign/.
@Timeout(Duration(minutes: 8))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/components.dart';

import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio;
import 'bird_unlocks.dart';

const _capture = bool.fromEnvironment('CAPTURE_POLISH');
const _folder = 'build/visual-review/campaign/polish/home-campaign';

/// Chapter 1 finished up to its boss, and two levels into chapter 2.
const _midway = {
  '1-1': 3,
  '1-2': 2,
  '1-3': 3,
  '1-4': 1,
  '1-5': 2,
  '1-6': 3,
  '1-7': 2,
  '1-8': 2,
  '2-1': 3,
  '2-2': 2,
};

/// Every level of both chapters, three stars each.
final _all = {
  for (final chapter in [1, 2])
    for (var n = 1; n <= 8; n++) '$chapter-$n': 3,
};

Future<void> _seed(ProgressRepository repo, Map<String, int> stars) async {
  var n = 0;
  for (final MapEntry(key: id, value: rating) in stars.entries) {
    final marks = Campaign.level(id)!.marks;
    await repo.saveRun(
      levelRun(
        'seed-${n++}',
        id,
        stars: switch (rating) {
          3 => marks.three,
          2 => marks.two,
          _ => marks.two - 5,
        },
        score: 400 + n * 30,
        at: DateTime(2026, 9, 20, 12, n),
      ),
    );
  }
}

Future<void> _open(
  WidgetTester tester,
  Size size, {
  int bird = 0,
  bool reduced = true,
  Map<String, int> stars = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  final folder = Directory.systemTemp.createTempSync('polish-home');
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, reduced);
    await unlockBirds(repo);
    await repo.equipBird(bird);
    await _seed(repo, stars);
  });
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(() => SilentAudio()),
      trackingSourceFactoryProvider.overrideWithValue(
        () => throw StateError('Tap & Fly never opens the camera'),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(repo.close);
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });
  await tester.runAsync(() => container.read(progressProvider.future));
  appRouter.go('/');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: ValueKey('visual-capture'),
        child: PushUpBirdApp(),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in [...birdAssets, 'island']) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// The key and its surroundings, magnified [zoom] times.
Future<void> _zoom(WidgetTester tester, String name, {double zoom = 4}) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  final key = tester.getRect(find.byKey(const ValueKey('campaign')));
  final crop = Rect.fromLTRB(
    (key.left - 24).clamp(0, double.infinity),
    (key.top - 20).clamp(0, double.infinity),
    key.right + 24,
    key.bottom + 20,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: zoom);
    final src = Rect.fromLTRB(
      crop.left * zoom,
      crop.top * zoom,
      crop.right * zoom,
      crop.bottom * zoom,
    );
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      image,
      src,
      Offset.zero & src.size,
      Paint()..filterQuality = FilterQuality.high,
    );
    final cut = await recorder.endRecording().toImage(
      src.width.round(),
      src.height.round(),
    );
    final bytes = await cut.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    cut.dispose();
  });
}

void main() {
  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  group('capture', skip: !_capture, () {
    for (final size in const [
      Size(640, 360),
      Size(800, 360),
      Size(1000, 450),
    ]) {
      final w = size.width.round();
      for (final (bird, name) in const [
        (0, 'pip'),
        (1, 'peaches'),
        (2, 'minty'),
        (3, 'orbit'),
      ]) {
        testWidgets('home with $name at $w', (tester) async {
          await _open(tester, size, bird: bird, stars: _midway);
          await _shot(tester, '$name-$w');
          if (bird == 0) await _zoom(tester, 'zoom-$name-$w');
          expect(tester.takeException(), isNull);
        });
      }
      testWidgets('finished, large text and motion at $w', (tester) async {
        await _open(tester, size, stars: _all);
        await _shot(tester, 'finished-pip-$w');
        await _zoom(tester, 'zoom-finished-$w');
        await tester.pumpWidget(const SizedBox());
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _open(tester, size, stars: _midway);
        await _zoom(tester, 'zoom-large-text-$w');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        // Motion on: the pin hops a little way into each cycle.
        await _open(tester, size, stars: _midway, reduced: false);
        for (var i = 0; i < 31; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        for (final name in ['a', 'b', 'c']) {
          await tester.pump(const Duration(milliseconds: 200));
          await _zoom(tester, 'zoom-hop-$name-$w');
        }
        expect(tester.takeException(), isNull);
      });
      testWidgets('fresh and pressed at $w', (tester) async {
        await _open(tester, size);
        await _shot(tester, 'fresh-pip-$w');
        await _zoom(tester, 'zoom-fresh-$w');
        final press = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('campaign'))),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await _zoom(tester, 'zoom-pressed-$w');
        await press.cancel();
      });
    }
  });
}
