// Every region and crossing is rendered at full phone size, so the work
// grows with the tour.
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/bird_motion.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/obstacle_art.dart';
import 'package:push_up_bird/game/regions/region_burst.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

const _capture = bool.fromEnvironment('CAPTURE_VISUALS');

/// Mid-hold second of a region on the first lap.
double holdOf(WorldRegion r) => r.index * WorldTour.leg + 8;

/// The clock second where a crossing out of [r] reaches progress [t].
double crossingOf(WorldRegion r, double t) =>
    r.index * WorldTour.leg + WorldTour.hold + WorldTour.crossing * t;

/// An obstacle with the pass state it should be drawn in.
typedef Staged = (Obstacle, {bool cleared, bool perfect});

/// Every kind spread across a phone screen, born in the region at [seconds].
List<Staged> lineup(double seconds, {int variant = 0, bool orbs = false}) {
  Obstacle make(ObstacleKind kind, double x, double center, int i) => Obstacle(
    x: x,
    center: center,
    gap: .4,
    width: kind.width,
    kind: kind,
    amplitude: kind == ObstacleKind.garden ? 0 : .05,
    appearance: variant + i,
    bornAt: seconds,
  );
  if (orbs) {
    return [
      (
        make(ObstacleKind.lanternDrift, .66, .42, 0),
        cleared: false,
        perfect: false,
      ),
      (
        make(ObstacleKind.sunWheels, .98, .58, 1),
        cleared: false,
        perfect: false,
      ),
      (
        make(ObstacleKind.lanternDrift, 1.38, .5, 2),
        cleared: true,
        perfect: false,
      ),
      (
        make(ObstacleKind.sunWheels, 1.72, .46, 0),
        cleared: true,
        perfect: true,
      ),
      (make(ObstacleKind.garden, 2.05, .56, 1), cleared: true, perfect: true),
    ];
  }
  return [
    (make(ObstacleKind.garden, .64, .56, 0), cleared: false, perfect: false),
    (make(ObstacleKind.windLift, .9, .44, 1), cleared: false, perfect: false),
    (make(ObstacleKind.petalGate, 1.16, .52, 2), cleared: true, perfect: false),
    (
      make(ObstacleKind.switchback, 1.42, .5, 0),
      cleared: false,
      perfect: false,
    ),
    (
      make(ObstacleKind.crystalSteps, 1.78, .48, 1),
      cleared: false,
      perfect: false,
    ),
  ];
}

Future<ui.Image> render(
  Size size,
  double seconds, {
  bool reducedMotion = false,
  List<Staged> obstacles = const [],
  bool bird = true,
  void Function(Canvas canvas)? extra,
}) async {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.clipRect(Offset.zero & size);
  SkyScenery.paint(
    c,
    size,
    seconds: seconds,
    distance: seconds * .36,
    reducedMotion: reducedMotion,
  );
  final h = size.height;
  for (final (o, :cleared, :perfect) in obstacles) {
    o.advance(seconds);
    ObstacleArt.paint(
      c,
      o,
      h,
      seconds: seconds,
      reducedMotion: reducedMotion,
      cleared: cleared,
      perfect: perfect,
    );
    if (cleared) {
      ObstacleArt.seal(
        c,
        Offset((o.x + o.width / 2) * h, o.target * h),
        h,
        WorldTour.of(o),
        perfect: perfect,
      );
    }
  }
  if (bird) {
    final bw = h * BirdFlightMotion.size;
    c.save();
    c.translate(FlightSimulation.birdX * h, h * .44);
    BirdPuppet.paint(
      c,
      Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
      bird: 0,
      wing: .3,
    );
    c.restore();
  }
  extra?.call(c);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  picture.dispose();
  return image;
}

Future<void> save(ui.Image image, String name) async {
  if (_capture) {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/visual-review/regions/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  }
  image.dispose();
}

/// Paints a grid of scaled-down frames into one review sheet.
Future<void> sheet(
  String name,
  int columns,
  Size cell,
  List<(double seconds, List<Staged> obstacles)> frames,
) async {
  const full = Size(1000, 450);
  final rows = (frames.length / columns).ceil();
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  final scale = cell.width / full.width;
  for (var i = 0; i < frames.length; i++) {
    final (seconds, obstacles) = frames[i];
    c.save();
    c.translate(
      (i % columns) * (cell.width + 6),
      (i ~/ columns) * (cell.height + 6),
    );
    c.clipRect(Offset.zero & cell);
    c.scale(scale);
    final image = await render(full, seconds, obstacles: obstacles);
    c.drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );
    image.dispose();
    c.restore();
  }
  final picture = recorder.endRecording();
  await save(
    await picture.toImage(
      (columns * (cell.width + 6) - 6).round(),
      (rows * (cell.height + 6) - 6).round(),
    ),
    name,
  );
  picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('close-ups at twice phone scale', () async {
    for (final region in WorldRegion.values) {
      final at = holdOf(region);
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      const h = 900.0;
      c.clipRect(const Rect.fromLTWH(0, 0, 1000, 450));
      c.translate(0, -225);
      SkyScenery.paint(c, const Size(1000, 900), seconds: at, distance: at * .36);
      final kinds = [
        (ObstacleKind.garden, .04, false, false),
        (ObstacleKind.windLift, .21, true, false),
        (ObstacleKind.petalGate, .38, true, true),
        (ObstacleKind.switchback, .56, false, false),
        (ObstacleKind.crystalSteps, .82, true, true),
      ];
      for (final (i, (kind, x, cleared, perfect)) in kinds.indexed) {
        final o = Obstacle(
          x: x,
          center: .5,
          gap: .32,
          width: kind.width,
          kind: kind,
          amplitude: 0,
          appearance: i,
          bornAt: at,
        )..advance(at);
        ObstacleArt.paint(c, o, h, seconds: at, reducedMotion: false, cleared: cleared, perfect: perfect);
      }
      final picture = recorder.endRecording();
      await save(await picture.toImage(1000, 450), '${region.name}-closeup');
      picture.dispose();
    }
  });

  test('overview sheets', () async {
    await sheet('overview-regions', 2, const Size(500, 225), [
      for (final region in WorldRegion.values)
        (holdOf(region), lineup(holdOf(region), variant: region.index)),
    ]);
    await sheet('overview-crossings', 5, const Size(300, 135), [
      for (final region in WorldRegion.values)
        for (final t in const [0.0, .25, .5, .75, 1.0])
          (crossingOf(region, t), const <Staged>[]),
    ]);
  });

  test('every region and crossing renders at phone sizes', () async {
    for (final region in WorldRegion.values) {
      for (final size in const [Size(1000, 450), Size(800, 450)]) {
        await save(
          await render(size, holdOf(region)),
          '${region.name}-bg-${size.width.toInt()}',
        );
      }
      for (final variant in const [0, 1, 2]) {
        final at = holdOf(region);
        await save(
          await render(
            const Size(1000, 450),
            at,
            obstacles: lineup(at, variant: variant),
          ),
          '${region.name}-kinds-$variant',
        );
      }
      await save(
        await render(
          const Size(1000, 450),
          holdOf(region),
          obstacles: lineup(holdOf(region), orbs: true),
        ),
        '${region.name}-orbs',
      );
      await save(
        await render(
          const Size(800, 450),
          holdOf(region),
          obstacles: lineup(holdOf(region), variant: 1),
        ),
        '${region.name}-kinds-800',
      );
      for (final t in const [.25, .5, .75]) {
        await save(
          await render(const Size(1000, 450), crossingOf(region, t)),
          'cross-${region.name}-${region.next.name}-${(t * 100).toInt()}',
        );
      }
      await save(
        await render(
          const Size(1000, 450),
          crossingOf(region, .5),
          reducedMotion: true,
        ),
        'still-cross-${region.name}-${region.next.name}-50',
      );
      await save(
        await render(
          const Size(1000, 450),
          holdOf(region),
          extra: (c) {
            for (final (i, t) in const [.2, .45, .7].indexed) {
              RegionBurst.paint(
                c,
                region,
                Offset(420 + i * 220.0, 200),
                450,
                t: t,
                alpha: 1 - t * t,
                perfect: i == 1,
              );
            }
          },
        ),
        '${region.name}-burst',
      );
    }
  });
}
