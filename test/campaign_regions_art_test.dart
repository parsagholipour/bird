// Every region is rendered at phone size at several moments of a level.
@Timeout(Duration(minutes: 8))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/gale_art.dart';
import 'package:push_up_bird/game/obstacle_art.dart';
import 'package:push_up_bird/game/regions/region_scene.dart';
import 'package:push_up_bird/game/regions/world_backdrop.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'campaign_flight.dart';

/// Campaign flights hold one region for the whole level. With
/// `--dart-define=CAPTURE_CAMPAIGN_REGIONS=true` every region is written to
/// build/visual-review/campaign/regions/ at the start of a 90 s level, at
/// 30, 60 and 90 s and after a 300 s hold, with and without Reduced Motion,
/// with obstacles (and a gale at 60 s), plus the moments each repeated
/// band's seam crosses the screen, a sheet per region, and real game frames
/// of each region's first level (`play-*`).
const _capture = bool.fromEnvironment('CAPTURE_CAMPAIGN_REGIONS');
const _phone = Size(1000, 450);
const _times = [0.0, 30.0, 60.0, 90.0, 300.0];

/// One of each obstacle kind across the screen, born at [seconds].
List<(Obstacle, bool, bool)> _lineup(double seconds, int variant) {
  Obstacle make(ObstacleKind kind, double x, double center, int i) => Obstacle(
    x: x,
    center: center,
    gap: .4,
    width: kind.width,
    kind: kind,
    amplitude: kind == ObstacleKind.garden ? 0 : .05,
    appearance: variant + i,
    bornAt: seconds,
  )..advance(seconds);
  return [
    (make(ObstacleKind.garden, .62, .56, 0), false, false),
    (make(ObstacleKind.windLift, .9, .44, 1), true, false),
    (make(ObstacleKind.petalGate, 1.16, .52, 2), true, true),
    (make(ObstacleKind.lanternDrift, 1.42, .46, 1), false, false),
    (make(ObstacleKind.crystalSteps, 1.74, .48, 0), false, false),
    (make(ObstacleKind.sunWheels, 2.02, .56, 2), true, false),
  ];
}

/// A campaign flight in [region] with a gale blowing, [seconds] in.
FlightSimulation _galeIn(WorldRegion region, double seconds) =>
    FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
        plan: Campaign.levels.firstWhere((l) => l.region == region).plan,
      )
      ..elapsed = seconds
      ..distance = seconds * WorldBackdrop.cruise
      ..gale = (Gale(number: 0, startDistance: 0)
        ..phase = GalePhase.blowing
        ..startedAt = 0);

Future<ui.Image> _frame(
  WorldRegion? region,
  double seconds, {
  bool reducedMotion = false,
  bool obstacles = false,
  bool gale = false,
  Size size = _phone,
}) async {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder)..clipRect(Offset.zero & size);
  SkyScenery.paint(
    c,
    size,
    seconds: seconds,
    distance: seconds * WorldBackdrop.cruise,
    reducedMotion: reducedMotion,
    held: region,
  );
  final h = size.height;
  if (gale && region != null) {
    GaleArt.backdrop(
      c,
      size,
      _galeIn(region, seconds),
      reducedMotion: reducedMotion,
    );
  }
  if (obstacles) {
    for (final (o, cleared, perfect) in _lineup(seconds, region?.index ?? 0)) {
      ObstacleArt.paint(
        c,
        o,
        h,
        seconds: seconds,
        reducedMotion: reducedMotion,
        cleared: cleared,
        perfect: perfect,
        held: region,
      );
      if (cleared) {
        ObstacleArt.seal(
          c,
          Offset((o.x + o.width / 2) * h, o.target * h),
          h,
          WorldTour.of(o, held: region),
          perfect: perfect,
        );
      }
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  picture.dispose();
  return image;
}

Future<Uint8List> _pixels(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
        .asUint8List();

Future<void> _save(ui.Image image, String name) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('build/visual-review/campaign/regions/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

/// Seconds into a level at which the overlap between the first two copies
/// of timed band [d] stands mid-screen, or null past ten minutes.
double? _seamAt(WorldRegion region, Depth d) {
  for (var t = 0.0; t < 600; t += .5) {
    final f = SceneFrame(
      _phone,
      seconds: t,
      distance: 0,
      reducedMotion: false,
      region: region,
    );
    final seam = _phone.height * .35;
    if (WorldBackdrop.copies(f, d).any(
      (copy) => copy.shift > 0 && copy.from + seam / 2 < _phone.width / 2,
    )) {
      return t;
    }
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a campaign level holds its one region at every moment', () {
    for (final region in WorldRegion.values) {
      for (final t in [0.0, 16.0, 19.0, 22.0, 90.0, 300.0, 1e5, -1.0]) {
        final blend = WorldTour.at(t, held: region);
        expect((blend.from, blend.to), (region, region));
        expect(blend.crossing, isFalse);
        expect(blend.held, isTrue);
        expect(blend.weight(region), 1);
        expect(SkyPalette.at(t, held: region).top, region.palette.top);
        final o = Obstacle(x: 1, center: .5, gap: .4, bornAt: t);
        expect(WorldTour.of(o, held: region), region);
      }
      final level = Campaign.levels.where((l) => l.region == region);
      expect(level, isNotEmpty, reason: '${region.title} has no level');
      expect(_galeIn(region, 60).region, region);
    }
    // Endless flights keep the tour.
    expect(WorldTour.at(19).crossing, isTrue);
    expect(WorldTour.at(19).held, isFalse);
  });

  test('a level opens on the still the tour composes for its region', () async {
    // Reduced Motion holds the bands where the tour composed them, so a
    // campaign level, a map stop and the tour's own region agree.
    for (final region in WorldRegion.values) {
      final tour = await _frame(
        null,
        region.index * WorldTour.leg + 8,
        reducedMotion: true,
      );
      final expected = await _pixels(tour);
      tour.dispose();
      for (final t in [0.0, 90.0, 300.0]) {
        final held = await _frame(region, t, reducedMotion: true);
        expect(
          await _pixels(held),
          orderedEquals(expected),
          reason: '${region.title} at $t s',
        );
        held.dispose();
      }
      final recorder = ui.PictureRecorder();
      WorldBackdrop.still(Canvas(recorder), _phone, region);
      final picture = recorder.endRecording();
      final still = await picture.toImage(1000, 450);
      picture.dispose();
      expect(await _pixels(still), orderedEquals(expected));
      still.dispose();
    }
  });

  test('band copies come and go without a jump', () async {
    // Each moment a copy of a repeated band starts or stops counting, the
    // frames a tenth of a millisecond apart must match: nothing may pop in
    // or out.
    const size = Size(400, 180);
    String copies(WorldRegion region, double t) {
      final f = SceneFrame(
        size,
        seconds: t,
        distance: 0,
        reducedMotion: false,
        region: region,
      );
      return [
        for (final d in [Depth.far, Depth.mid])
          WorldBackdrop.copies(f, d).map((c) => c.shift).join(','),
      ].join('|');
    }

    for (final region in WorldRegion.values) {
      var events = 0;
      for (var t = 0.0; t < 480; t += .25) {
        if (copies(region, t) == copies(region, t + .25)) continue;
        var (a, b) = (t, t + .25);
        while (b - a > 1e-4) {
          final m = (a + b) / 2;
          (a, b) = copies(region, a) == copies(region, m) ? (m, b) : (a, m);
        }
        final before = await _frame(region, a, size: size);
        final after = await _frame(region, b, size: size);
        final x = await _pixels(before), y = await _pixels(after);
        var jumps = 0;
        for (var i = 0; i < x.length; i++) {
          if ((x[i] - y[i]).abs() > 24) jumps++;
        }
        // A blinking sign may switch in the gap; a copy or a ridge popping
        // would change thousands of values.
        expect(jumps, lessThan(240), reason: '${region.title} at $a s');
        before.dispose();
        after.dispose();
        events++;
      }
      expect(events, greaterThan(2), reason: region.title);
    }
  });

  test('every region renders through a long level', () async {
    for (final region in WorldRegion.values) {
      final seams = {
        for (final d in [Depth.far, Depth.mid]) d: ?_seamAt(region, d),
      };
      final frames = <String, ui.Image>{};
      for (final t in _times) {
        frames['${t.toInt()}s'] = await _frame(
          region,
          t,
          obstacles: true,
          gale: t == 60,
        );
      }
      for (final t in const [0.0, 300.0]) {
        frames['${t.toInt()}s-still'] = await _frame(
          region,
          t,
          reducedMotion: true,
          obstacles: true,
        );
      }
      for (final MapEntry(key: d, value: t) in seams.entries) {
        frames['seam-${d.name}-${t.toInt()}s'] = await _frame(region, t);
      }
      if (_capture) {
        for (final MapEntry(key: name, value: image) in frames.entries) {
          await _save(image, '${region.name}-$name');
        }
        await _sheet(region, frames);
      }
      for (final image in frames.values) {
        image.dispose();
      }
    }
  });
  testWidgets('a campaign flight holds its region in play', (tester) async {
    for (final family in ['Fredoka', 'Nunito']) {
      await tester.runAsync(
        () => (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load(),
      );
    }
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final region in WorldRegion.values) {
      final level = Campaign.levels.firstWhere((l) => l.region == region);
      final sim = levelFlight(level);
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: false,
        onChanged: () {},
        playback: true,
      );
      await tester.pumpWidget(GameWidget(game: game));
      await tester.runAsync(() => game.loaded);
      game.pauseEngine();
      final shots = [12.0, 50.0];
      final pictures = <double, ui.Picture>{};
      var dressed = 0;
      flyLevel(
        sim,
        seconds: 55,
        watch: (sim) {
          for (final o in sim.obstacles) {
            expect(WorldTour.of(o, held: sim.region), region);
            dressed++;
          }
          if (shots.isEmpty || sim.elapsed < shots.first) return;
          final recorder = ui.PictureRecorder();
          game.render(Canvas(recorder));
          pictures[shots.removeAt(0)] = recorder.endRecording();
        },
      );
      expect(sim.region, region);
      expect(dressed, greaterThan(0));
      for (final MapEntry(key: t, value: picture) in pictures.entries) {
        await tester.runAsync(() async {
          final image = await picture.toImage(1000, 450);
          picture.dispose();
          if (_capture) await _save(image, 'play-${region.name}-${t.toInt()}s');
          image.dispose();
        });
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
}

/// All of a region's frames on one sheet, half size, for a quick look.
Future<void> _sheet(WorldRegion region, Map<String, ui.Image> frames) async {
  const cell = Size(500, 225), columns = 3;
  final rows = (frames.length / columns).ceil();
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.drawColor(const Color(0xff222222), BlendMode.src);
  final label = TextPainter(textDirection: TextDirection.ltr);
  for (final (i, MapEntry(key: name, value: image)) in frames.entries.indexed) {
    final at = Offset((i % columns) * (cell.width + 6), (i ~/ columns) * 245.0);
    c.drawImageRect(
      image,
      Offset.zero & _phone,
      at & cell,
      Paint()..filterQuality = FilterQuality.medium,
    );
    label
      ..text = TextSpan(
        text: name,
        style: const TextStyle(fontSize: 13, color: Color(0xffffffff)),
      )
      ..layout();
    label.paint(c, at + const Offset(4, 227));
  }
  final picture = recorder.endRecording();
  final sheet = await picture.toImage(
    (columns * (cell.width + 6) - 6).round(),
    rows * 245,
  );
  picture.dispose();
  await _save(sheet, '${region.name}-sheet');
  sheet.dispose();
}
