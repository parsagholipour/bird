import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/built_level_repository.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/built_level.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/builder/builder_canvas.dart';
import 'package:push_up_bird/ui/builder/builder_controller.dart';

import 'play_session_test.dart' show SessionSource, SilentAudio;

/// The Level Builder's UI tests open the whole app (its router, frame and
/// providers) on an in-memory save, as `menu_flow_test.dart` does.

Future<void> loadBuilderFonts() async {
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

/// The app as a test drives it: its save and its providers.
class BuilderApp {
  BuilderApp(this.repo, this.container);
  final SqliteProgressRepository repo;
  final ProviderContainer container;
  BuiltLevelStore get store => repo.builtLevels;

  String get location =>
      appRouter.routerDelegate.currentConfiguration.uri.toString();
  Uri get uri => appRouter.routerDelegate.currentConfiguration.uri;
}

/// Opens the app at [at] on a [size] display (logical pixels at [dpr]),
/// with [levels] already kept, Reduced Motion on unless [reduced] is false.
Future<BuilderApp> pumpBuilderApp(
  WidgetTester tester, {
  String at = '/builder',
  Size size = const Size(800, 360),
  double dpr = 1,
  EdgeInsets? insets,
  List<BuiltPlan> levels = const [],
  bool reduced = true,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  if (insets != null) {
    final padding = FakeViewPadding(
      left: insets.left * dpr,
      top: insets.top * dpr,
      right: insets.right * dpr,
      bottom: insets.bottom * dpr,
    );
    tester.view.padding = padding;
    tester.view.viewPadding = padding;
  }
  addTearDown(tester.view.reset);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  await repo.setSetting(SettingKey.reducedMotion, reduced);
  for (final plan in levels) {
    await repo.builtLevels.create(plan);
  }
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      audioFactoryProvider.overrideWithValue(SilentAudio.new),
      trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await repo.close();
  });
  await container.read(progressProvider.future);
  appRouter.go(at);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: ValueKey('visual-capture'),
        child: PushUpBirdApp(),
      ),
    ),
  );
  await settle(tester);
  return BuilderApp(repo, container);
}

/// Lets the save's queries and the screens' frames finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// Saves the screen to `build/visual-review/<folder>/<name>.png` when run
/// with `--dart-define=CAPTURE_VISUALS=true`.
Future<void> snap(
  WidgetTester tester,
  String name, {
  double ratio = 2,
  String folder = 'builder',
}) async {
  if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/visual-review/$folder')
      ..createSync(recursive: true);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// The system clipboard, kept in memory.
class FakeClipboard {
  String? text;

  void install(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            text = (call.arguments as Map)['text'] as String?;
            return null;
          case 'Clipboard.getData':
            return text == null ? null : {'text': text};
          case 'Clipboard.hasStrings':
            return {'value': text != null};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}

/// A level of [mode] as a player might build it: gates every so often with
/// a trio before each, a heart halfway, and (Tap & Fly) a bat.
BuiltPlan builtLevel(
  PlayMode mode, {
  required String id,
  String? name,
  int gates = 6,
  WorldRegion region = WorldRegion.jungle,
  List<BuiltItem> extra = const [],
  BossKind? boss,
}) {
  final step = switch (mode) {
    PlayMode.touch => 1100,
    PlayMode.jump => 1300,
    PlayMode.pushUp || PlayMode.squat => 1300,
  };
  final items = <BuiltItem>[];
  var x = BuiltPlan.firstX + 600;
  for (var i = 0; i < gates; i++) {
    final y = mode.controlsHeight
        ? (i.isEven ? BuiltPlan.highLane : BuiltPlan.lowLane)
        : const [450, 560, 380, 600][i % 4];
    final aim = (BuiltPlan.laneTarget(mode, y / BuiltPlan.unit) * 1000).round();
    final kind = mode == PlayMode.touch && i % 3 == 2
        ? ObstacleKind.windLift
        : ObstacleKind.garden;
    items
      ..add(BuiltTrio(x: x - 300, y: aim))
      ..add(
        BuiltGate(
          x: x,
          y: y,
          gap: mode.controlsHeight ? 460 : 420,
          kind: kind,
          amp: kind == ObstacleKind.garden ? 0 : 50,
          phase: 90,
          look: i % 3,
        ),
      );
    if (i == gates ~/ 2) items.add(BuiltHeart(x: x + 450, y: aim));
    x += step;
  }
  if (mode == PlayMode.touch) {
    items.add(
      BuiltEnemy(x: BuiltPlan.firstX + 1150, y: 300, kind: EnemyKind.caveBat),
    );
  }
  items.addAll(extra);
  return BuiltPlan(
    id: id,
    name: name ?? 'My ${mode.name} level',
    mode: mode,
    region: region,
    finish: x + 300,
    marks: BuiltPlan.suggestMarks(3 * gates),
    items: items,
    boss: boss,
  );
}

/// A level kept with its origin, as the shelf lists it.
Future<BuiltLevel> keep(
  BuilderApp app,
  BuiltPlan plan, {
  BuiltOrigin origin = BuiltOrigin.created,
}) => app.store.create(plan, origin: origin);

/// The editor on screen.
BuilderController editorOf(WidgetTester tester) =>
    tester.widget<BuilderCanvas>(find.byType(BuilderCanvas)).controller;

/// Where the world point ([worldX], [worldY]) shows on the editor's sky, in
/// the test's global coordinates.
Offset skyPoint(WidgetTester tester, double worldX, double worldY) {
  final rect = tester.getRect(find.byKey(const ValueKey('builder-canvas')));
  final h = rect.height;
  return rect.topLeft +
      Offset((worldX - editorOf(tester).scroll) * h, worldY * h);
}
