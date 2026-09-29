import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/bird_motion.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/bird_trail.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/game/star_art.dart';
import 'package:push_up_bird/ui/theme.dart';

/// Review renders of every bird trail, written to
/// build/visual-review/bird-trail/ with `--dart-define=CAPTURE_VISUALS=true`.
/// `--dart-define=TRAIL_REVIEW=before` names a baseline set.
const _capture = bool.fromEnvironment('CAPTURE_VISUALS');
const _set = String.fromEnvironment('TRAIL_REVIEW', defaultValue: 'after');

/// A landscape phone viewport in logical pixels, drawn at its device ratio.
const _phone = Size(844, 390), _ratio = 2.75;

/// A recorded stretch of flight: the bird's height over the last seconds.
class Flight {
  const Flight(this.name, this.speed, this.height);
  final String name;
  final double speed;
  final double Function(double t) height;

  /// Samples the bird the way the simulation records it, ending at [now].
  ({List<Offset> path, double flown, double tilt, double y}) at(
    double h, {
    double now = 0,
  }) {
    // Recording from a fixed start keeps the odometer continuous across
    // frames of the same flight.
    final record = FlightPath();
    for (var i = 0; i <= ((now + 3) * 120).round(); i++) {
      final t = -3 + i / 120;
      record.record(t * speed, height(t));
    }
    final x = FlightSimulation.birdX * h;
    final path = [
      for (final p in record.recent)
        Offset(x + (p.distance - now * speed) * h, p.y * h),
    ];
    final dy = (height(now) - height(now - 1 / 120)) * 120;
    return (
      path: path,
      flown: record.flown * h,
      tilt: BirdFlightMotion.tilt(dy),
      y: height(now) * h,
    );
  }
}

double _ease(double t) {
  final u = t.clamp(0.0, 1.0);
  return u * u * (3 - 2 * u);
}

/// Touch arcade physics: a flap every [every] seconds from a steady height.
double Function(double) _flapping(double every, double base) => (t) {
  const g = 1.1, impulse = -.54;
  final since = (t % every + every) % every;
  // Each hop ends where it started so the sawtooth stays level.
  final drift = impulse * every + g * every * every / 2;
  return base + impulse * since + g * since * since / 2 - drift * since / every;
};

final flights = [
  Flight('level', .36, (t) => .46),
  Flight('climb', .33, (t) => .62 - .3 * _ease((t + .55) / .8)),
  Flight('dive', .33, (t) => .3 + .3 * _ease((t + .55) / .8)),
  Flight('flap-rise', .44, (t) => _flapping(.8, .5)(t + .07)),
  Flight('flap-top', .44, (t) => _flapping(.8, .5)(t + .3)),
];

void trail(
  Canvas c, {
  required int bird,
  required Offset anchor,
  required double unit,
  double seconds = 3,
  bool animate = true,
  bool empowered = false,
  List<Offset>? path,
  double? flown,
}) => BirdTrail.paint(
  c,
  bird: bird,
  anchor: anchor,
  unit: unit,
  seconds: seconds,
  animate: animate,
  empowered: empowered,
  path: path,
  flown: flown,
);

void puppet(Canvas c, int bird, Offset center, double h, {double tilt = 0}) {
  final bw = h * BirdFlightMotion.size;
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(tilt);
  BirdPuppet.paint(
    c,
    Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
    bird: bird,
    wing: .1,
  );
  c.restore();
}

/// The collectible star as the game draws it, for comparison.
void pickup(Canvas c, Offset center, double h) =>
    StarArt.paint(c, center, h * StarArt.radius, seconds: 3);

void skyWash(Canvas c, Rect r) => c.drawRect(
  r,
  Paint()
    ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [
      SkyColors.skyDeep,
      SkyColors.sky,
    ]),
);

void label(Canvas c, String text, Offset at, {Color color = SkyColors.ink}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: bodyText(11, color: color, weight: FontWeight.w800),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
  painter.dispose();
}

/// Lays out cells of [cell] logical size at [scale] pixels per point.
Future<void> sheet(
  String name, {
  required int columns,
  required Size cell,
  required double scale,
  required List<void Function(Canvas c)> cells,
}) async {
  const gap = 6.0;
  final rows = (cells.length / columns).ceil();
  final size = Size(
    columns * (cell.width + gap) - gap,
    rows * (cell.height + gap) - gap,
  );
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder)..scale(scale);
  c.drawRect(Offset.zero & size, Paint()..color = const Color(0xff2a2f3a));
  for (final (i, paint) in cells.indexed) {
    c.save();
    c.translate(
      (i % columns) * (cell.width + gap),
      (i ~/ columns) * (cell.height + gap),
    );
    c.clipRect(Offset.zero & cell);
    paint(c);
    c.restore();
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (size.width * scale).round(),
    (size.height * scale).round(),
  );
  picture.dispose();
  if (_capture) {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/visual-review/bird-trail/$_set-$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  }
  image.dispose();
}

/// A crop of the phone viewport around the bird: [crop] in viewport points.
void Function(Canvas) flightCell({
  required int bird,
  required Flight flight,
  required Rect crop,
  double h = 390,
  double now = 0,
  double seconds = 3,
  WorldRegion? region,
  bool empowered = false,
  bool reduced = false,
  bool star = false,
  String? caption,
}) => (c) {
  final shot = flight.at(h, now: now);
  final center = Offset(FlightSimulation.birdX * h, shot.y);
  c.save();
  c.translate(-crop.left, -crop.top);
  final view = Rect.fromLTWH(0, 0, _phone.width * h / _phone.height, h);
  if (region == null) {
    skyWash(c, view);
  } else {
    final at = region.index * WorldTour.leg + 8;
    SkyScenery.paint(c, view.size, seconds: at, distance: at * .36);
  }
  if (star) pickup(c, center + Offset(h * .2, -h * .02), h);
  trail(
    c,
    bird: bird,
    anchor: center,
    unit: h * .014,
    seconds: seconds,
    animate: !reduced,
    empowered: empowered,
    path: reduced ? null : shot.path,
    flown: shot.flown,
  );
  puppet(c, bird, center, h, tilt: reduced ? 0 : shot.tilt);
  c.restore();
  if (caption != null) {
    label(c, caption, const Offset(6, 4), color: SkyColors.ink);
  }
};

Rect around(Flight flight, double h, {double w = 260, double hh = 150}) {
  final y = flight.at(h).y;
  final x = FlightSimulation.birdX * h;
  return Rect.fromLTWH(math.max(0, x - w * .72), y - hh / 2, w, hh);
}

const _birds = ['Pip', 'Peaches', 'Minty', 'Orbit'];

/// Mirrors the crew card's trail placement in the collection screen.
abstract final class _CardTrail {
  static const x = .46, unit = 4.6;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  test(
    'each trail along level, climbing, diving and flapping flight',
    () async {
      for (final empowered in [false, true]) {
        await sheet(
          empowered ? 'paths-empowered' : 'paths',
          columns: flights.length,
          cell: const Size(230, 150),
          scale: _ratio,
          cells: [
            for (var bird = 0; bird < 4; bird++)
              for (final flight in flights)
                flightCell(
                  bird: bird,
                  flight: flight,
                  crop: around(flight, 390, w: 230),
                  empowered: empowered,
                  caption: '${_birds[bird]} · ${flight.name}',
                ),
          ],
        );
      }
      // Phone size glance: what a player actually sees, one point per pixel.
      await sheet(
        'glance',
        columns: 2,
        cell: const Size(420, 200),
        scale: 1,
        cells: [
          for (var bird = 0; bird < 4; bird++)
            for (final (region, flight) in [
              (WorldRegion.brazil, flights[3]),
              (WorldRegion.paris, flights[1]),
            ])
              flightCell(
                bird: bird,
                flight: flight,
                region: region,
                star: true,
                crop: around(flight, 390, w: 420, hh: 200),
              ),
        ],
      );
    },
  );

  test('each trail over light, busy and dark regions', () async {
    const stops = [
      (WorldRegion.antarctica, .66),
      (WorldRegion.brazil, .3),
      (WorldRegion.jungle, .68),
      (WorldRegion.egypt, .64),
      (WorldRegion.sea, .7),
      (WorldRegion.mexico, .5),
      (WorldRegion.newYork, .55),
      (WorldRegion.paris, .38),
    ];
    for (var bird = 0; bird < 4; bird++) {
      await sheet(
        'regions-${_birds[bird].toLowerCase()}',
        columns: 2,
        cell: const Size(260, 140),
        scale: _ratio,
        cells: [
          for (final (region, y) in stops)
            if (Flight('flap', .44, (t) => _flapping(.8, y)(t + .12))
                case final flight)
              flightCell(
                bird: bird,
                flight: flight,
                region: region,
                star: true,
                crop: around(flight, 390, hh: 140),
                caption: region.title,
              ),
        ],
      );
    }
  });

  test('motion frames, animated and still', () async {
    for (var bird = 0; bird < 4; bird++) {
      final flight = flights[3];
      await sheet(
        'motion-${_birds[bird].toLowerCase()}',
        columns: 4,
        cell: const Size(200, 130),
        scale: 2,
        cells: [
          for (var f = 0; f < 8; f++)
            flightCell(
              bird: bird,
              flight: flight,
              now: f / 20,
              seconds: 3 + f / 20,
              crop: around(flight, 390, w: 200, hh: 130),
              caption: 't+${f * 50}ms',
            ),
        ],
      );
    }
    await sheet(
      'reduced-motion',
      columns: 2,
      cell: const Size(230, 110),
      scale: _ratio,
      cells: [
        for (var bird = 0; bird < 4; bird++)
          for (final seconds in [0.0, 5.0])
            flightCell(
              bird: bird,
              flight: flights[0],
              reduced: true,
              seconds: seconds,
              crop: around(flights[0], 390, w: 230, hh: 110),
              caption: '${_birds[bird]} · still · ${seconds}s',
            ),
      ],
    );
  });

  test('crew card previews', () async {
    // The crew card: a 188 × 120 box with the 132-wide bird art at its right
    // and the trail painted underneath, never animated.
    const anchor = Offset(188 * _CardTrail.x, 60);
    void card(
      Canvas c,
      int bird, {
      bool empowered = false,
      bool locked = false,
    }) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 188, 120),
          const Radius.circular(12),
        ),
        Paint()..color = bird == 0 ? const Color(0xfffff2c9) : SkyColors.cream,
      );
      if (locked) c.saveLayer(null, Paint()..color = const Color(0x6b000000));
      c.save();
      c.clipRect(const Rect.fromLTWH(0, 0, 188, 120));
      trail(
        c,
        bird: bird,
        anchor: anchor,
        unit: _CardTrail.unit,
        animate: false,
        empowered: empowered,
      );
      c.restore();
      const art = 132.0;
      puppet(
        c,
        bird,
        Offset(188 - art + art * .48, (120 - art * 224 / 256) / 2 + art * .43),
        art / BirdFlightMotion.size,
      );
      if (locked) c.restore();
    }

    for (final scale in [1.0, 3.0]) {
      await sheet(
        'crew-card-${scale.toInt()}x',
        columns: 4,
        cell: const Size(188, 120),
        scale: scale,
        cells: [
          for (var bird = 0; bird < 4; bird++) (c) => card(c, bird),
          for (var bird = 0; bird < 4; bird++)
            (c) => card(c, bird, locked: true),
          for (var bird = 0; bird < 4; bird++)
            (c) => card(c, bird, empowered: true),
        ],
      );
    }
  });

  test('mark studies at poster size', () async {
    const grounds = [
      Color(0xffbde9f6),
      Color(0xffeef4fa),
      Color(0xffd9a86c),
      Color(0xff3f8d62),
      Color(0xff222c55),
    ];
    await sheet(
      'studies',
      columns: 5,
      cell: const Size(300, 110),
      scale: 2,
      cells: [
        for (final (bird, empowered) in [
          (0, false),
          (1, false),
          (2, false),
          (3, false),
          (3, true),
        ])
          for (final ground in grounds)
            (c) {
              c.drawRect(
                const Rect.fromLTWH(0, 0, 300, 110),
                Paint()..color = ground,
              );
              trail(
                c,
                bird: bird,
                anchor: const Offset(330, 55),
                unit: 14,
                seconds: 1.3,
                empowered: empowered,
                path: [for (var x = 5.0; x < 400; x += 5) Offset(330 - x, 55)],
                flown: 0,
              );
            },
      ],
    );
  });

  test('close zoom on each trail at a tablet height', () async {
    await sheet(
      'zoom',
      columns: 2,
      cell: const Size(200, 110),
      scale: 4,
      cells: [
        for (var bird = 0; bird < 4; bird++)
          for (final flight in [flights[0], flights[3]])
            flightCell(
              bird: bird,
              flight: flight,
              crop: around(flight, 390, w: 200, hh: 110),
            ),
      ],
    );
    await sheet(
      'tablet',
      columns: 2,
      cell: const Size(420, 220),
      scale: 1.5,
      cells: [
        for (var bird = 0; bird < 4; bird++)
          flightCell(
            bird: bird,
            flight: flights[3],
            h: 800,
            region: WorldRegion.aztec,
            crop: around(flights[3], 800, w: 420, hh: 220),
          ),
      ],
    );
  });

  test('a trail never reaches past the front of the bird', () async {
    const h = 390.0;
    for (var bird = 0; bird < 4; bird++) {
      for (final flight in flights) {
        for (final (seconds, empowered) in [(0.0, false), (2.7, true)]) {
          final shot = flight.at(h, now: seconds);
          final anchor = Offset(FlightSimulation.birdX * h, shot.y);
          final recorder = ui.PictureRecorder();
          trail(
            Canvas(recorder),
            bird: bird,
            anchor: anchor,
            unit: h * .014,
            seconds: seconds,
            empowered: empowered,
            path: shot.path,
            flown: shot.flown,
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(844, 390);
          final bytes = (await image.toByteData())!.buffer.asUint8List();
          image.dispose();
          picture.dispose();
          // Under the body is fine, the bird is drawn on top. Past its
          // collision circle the trail could cover what lies ahead.
          final front = (anchor.dx + h * FlightSimulation.birdRadius).ceil();
          var ahead = 0;
          for (var y = 0; y < 390; y++) {
            for (var x = front; x < 844; x++) {
              if (bytes[(y * 844 + x) * 4 + 3] > 0) ahead++;
            }
          }
          expect(ahead, 0, reason: '${_birds[bird]} ${flight.name}');
        }
      }
    }
  });
}
