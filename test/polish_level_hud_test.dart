import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart'
    show BossKind, FlightSimulation;
import 'package:push_up_bird/ui/level_hud.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'campaign_play_test.dart'
    show flyController, launchLevel, level, loadFonts, redraw;

/// Review frames of the in-flight level HUD (the star track and the route
/// bar): every state on bright, dark and busy backgrounds at 2x, the pop
/// when a mark is reached frame by frame, and the real play screen at
/// 640×360 and 800×360.
///
/// Run with `--dart-define=CAPTURE_POLISH=true` to write PNGs to
/// build/visual-review/campaign/polish/level-hud/. Without it the frames
/// still render, so the suite checks that none of them throws or overflows.
const _capture = bool.fromEnvironment('CAPTURE_POLISH');
const _folder = 'build/visual-review/campaign/polish/level-hud';

/// Backdrops a plate has to hold on: bright beach, snow, neon night, jungle.
const _backdrops = [
  Color(0xfff2d98a),
  Color(0xfff4f8fb),
  Color(0xff1b1f47),
  Color(0xff3f8a4a),
];

Future<void> _save(ui.Image image, String name) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

Future<void> _shot(WidgetTester tester, String name, {double ratio = 2}) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('sheet')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    await _save(image, name);
    image.dispose();
  });
}

Future<void> _sheet(
  WidgetTester tester,
  Size size,
  Widget Function(BuildContext context) build, {
  bool reduced = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: skyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: Material(
        child: RepaintBoundary(
          key: const ValueKey('sheet'),
          child: SizedBox.fromSize(
            size: size,
            child: Builder(builder: build),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// [plate] on each backdrop in a row of strips, [rows] high.
Widget _strips(List<Widget> plates, {double width = 400, double height = 82}) =>
    Column(
      children: [
        for (var i = 0; i < plates.length; i++)
          Container(
            width: width,
            height: height,
            color: _backdrops[i % _backdrops.length],
            alignment: Alignment.center,
            child: plates[i],
          ),
      ],
    );

Widget _stars(int stars, {int two = 45, int three = 70, bool reduced = true}) =>
    MatchLevelStars(
      stars: stars,
      two: two,
      three: three,
      reducedMotion: reduced,
    );

Widget _route(double progress, {int bird = 0, BossKind? boss, double? width}) =>
    width == null
    ? MatchRoute(progress: progress, bird: bird, boss: boss)
    : MatchRoute(progress: progress, bird: bird, boss: boss, width: width);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(loadFonts);

  testWidgets('the star track in every state', (tester) async {
    const counts = [0, 12, 33, 44, 45, 60, 69, 70, 84];
    await _sheet(
      tester,
      const Size(1240, 82 * 5),
      (context) => Row(
        children: [
          for (var column = 0; column < 3; column++)
            _strips([
              for (var row = 0; row < 5; row++)
                if (column * 5 + row < counts.length)
                  _stars(counts[column * 5 + row])
                else
                  const SizedBox.shrink(),
            ], width: 413),
        ],
      ),
    );
    await _shot(tester, 'stars-states');
    // Short marks, as on a boss level.
    await _sheet(
      tester,
      const Size(1240, 82 * 3),
      (context) => Row(
        children: [
          for (final count in [6, 19, 30])
            _strips([
              _stars(count, two: 20, three: 30),
              _stars(count + 1, two: 20, three: 30),
              _stars(count + 5, two: 20, three: 30),
            ], width: 413),
        ],
      ),
    );
    await _shot(tester, 'stars-short-marks');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the route bar in every state', (tester) async {
    const progress = [0.0, .12, .35, .5, .78, 1.0];
    await _sheet(
      tester,
      // Two strips taller for New York's two mini-boss lairs (rules 43), and
      // one more for Egypt's guardian (rules 50).
      const Size(1200, 82 * 9),
      (context) => Row(
        children: [
          _strips([
            for (var i = 0; i < progress.length; i++)
              _route(progress[i], bird: i % 4),
          ], width: 400),
          _strips([
            for (final at in [.05, .4, .8, .86, .93, 1.0])
              _route(at, bird: 1, boss: BossKind.baronBat),
          ], width: 400),
          _strips([
            for (final (i, boss) in BossKind.values.indexed)
              _route(.6, bird: i % 4, boss: boss),
            _route(.3, bird: 2, width: 236),
          ], width: 400),
        ],
      ),
    );
    await _shot(tester, 'route-states');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a mark is reached', (tester) async {
    // A star reaching ★★, then ★★★, frame by frame.
    Future<void> film(String name, int from, int to) async {
      var stars = from;
      late StateSetter update;
      await _sheet(
        tester,
        const Size(400, 82),
        (context) => StatefulBuilder(
          builder: (context, set) {
            update = set;
            return Container(
              color: _backdrops[0],
              alignment: Alignment.center,
              child: _stars(stars, reduced: false),
            );
          },
        ),
        reduced: false,
      );
      const times = [0, 60, 120, 200, 300, 450];
      final frames = <ui.Image>[];
      Future<void> grab() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('sheet')),
        );
        await tester.runAsync(() async {
          frames.add(await boundary.toImage(pixelRatio: 2));
        });
      }

      update(() => stars = to);
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      var last = 0;
      for (final t in times) {
        await tester.pump(Duration(milliseconds: t - last));
        last = t;
        await grab();
      }
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
      if (_capture) {
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          for (final (i, frame) in frames.indexed) {
            canvas.drawImage(frame, Offset(0, i * 164.0), Paint());
          }
          final image = await recorder.endRecording().toImage(
            800,
            164 * frames.length,
          );
          await _save(image, name);
        });
      }
      for (final frame in frames) {
        frame.dispose();
      }
    }

    await film('pop-two', 44, 45);
    await film('pop-three', 69, 70);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced Motion stills a reached mark', (tester) async {
    late StateSetter update;
    var stars = 44;
    await _sheet(
      tester,
      const Size(400, 82),
      (context) => StatefulBuilder(
        builder: (context, set) {
          update = set;
          return Center(child: _stars(stars));
        },
      ),
    );
    update(() => stars = 45);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    update(() => stars = 70);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('MAX'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the readouts are as wide as the HUD leaves room for', (
    tester,
  ) async {
    // The score plate keeps to the middle 400 units, and the route plate
    // sits from the right edge; the two must not meet.
    await _sheet(
      tester,
      const Size(1000, 200),
      (context) => Stack(
        children: [
          Positioned(
            left: 300,
            right: 300,
            top: 12,
            child: _stars(88, two: 55, three: 90),
          ),
          Positioned(right: 84, top: 16, child: _route(.5)),
        ],
      ),
    );
    final plate = tester.getRect(
      find
          .descendant(
            of: find.byType(MatchLevelStars),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    final route = tester.getRect(find.byType(MatchRoute));
    expect(plate.right + 30, lessThanOrEqualTo(route.left));
    // The route plate is as tall as Pause, so the two sit on one line.
    expect(route.height, MatchRoute.plateHeight);
  });

  for (final size in const [Size(640, 360), Size(800, 360)]) {
    final w = size.width.toInt();
    testWidgets('level HUD frames at $w', (tester) async {
      Future<void> frame(
        String id,
        String name, {
        int bird = 0,
        double? route,
        int? stars,
        bool Function(FlightSimulation sim)? until,
      }) async {
        final (:controller, game: _) = await launchLevel(
          tester,
          level(id),
          size: size,
          bird: bird,
        );
        final sim = controller.simulation!;
        flyController(
          controller,
          until: (sim) => until != null
              ? until(sim)
              : route != null && sim.routeProgress > route,
        );
        if (stars != null) sim.collectedStars = stars;
        await redraw(tester, controller);
        if (_capture) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('visual-capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            await _save(image, '$name-$w');
            image.dispose();
          });
        }
        await tester.runAsync(controller.exit);
      }

      await frame('1-2', 'game-start-1-2', route: .04, stars: 0);
      await frame('1-2', 'game-close-1-2', bird: 1, route: .4, stars: 31);
      await frame('1-4', 'game-reached-1-4', bird: 2, route: .6, stars: 46);
      await frame('2-1', 'game-all-2-1', bird: 3, route: .82, stars: 74);
      await frame('3-5', 'game-night-3-5', bird: 1, route: .5, stars: 62);
      await frame('5-1', 'game-snow-5-1', bird: 0, route: .3, stars: 20);
      await frame('5-3', 'game-neon-5-3', bird: 2, route: .7, stars: 44);
      await frame('1-8', 'game-boss-1-8', bird: 1, route: .5, stars: 12);
      await frame(
        '1-8',
        'game-glide-1-8',
        bird: 3,
        until: (sim) => sim.victoryGlide && sim.routeProgress > .93,
        stars: 22,
      );
    });
  }
}
