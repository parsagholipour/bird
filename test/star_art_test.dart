import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/game/star_art.dart';
import 'package:push_up_bird/game/star_pickup_art.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'star_magnet_test.dart' show FlightHarness;

const _folder = 'build/visual-review/star-design';

/// Phone landscape height, where a star is only about 25 px across.
const _height = 393.0;
const _box = 160;
const _center = Offset(_box / 2, _box / 2);

Future<List<int>> _pixels(
  void Function(Canvas) draw, {
  int width = _box,
  int height = _box,
}) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

/// Bounds of everything more opaque than [alpha] as [left, top, right,
/// bottom], or null when nothing is painted.
List<int>? _bounds(List<int> rgba, {int alpha = 0, int width = _box}) {
  int? left, top, right, bottom;
  for (var i = 0; i < rgba.length ~/ 4; i++) {
    if (rgba[i * 4 + 3] <= alpha) continue;
    final x = i % width, y = i ~/ width;
    left = left == null || x < left ? x : left;
    right = right == null || x > right ? x : right;
    top ??= y;
    bottom = y;
  }
  return left == null ? null : [left, top!, right!, bottom!];
}

Future<List<int>> _star({
  double? seconds,
  bool reduced = false,
  double phase = 0,
  bool glow = true,
}) => _pixels(
  (c) => StarArt.paint(
    c,
    _center,
    _height * StarArt.radius,
    seconds: seconds,
    reducedMotion: reduced,
    phase: phase,
    glow: glow,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the idle star replays exactly and rests in Reduced Motion', () async {
    final frame = await _star(seconds: 1.3);
    expect(await _star(seconds: 1.3), frame, reason: 'same clock, same pose');
    expect(await _star(seconds: 1.9), isNot(equals(frame)), reason: 'idles');
    expect(
      await _star(seconds: 1.3, phase: .5),
      isNot(equals(frame)),
      reason: 'neighbouring stars keep their own rhythm',
    );
    final still = await _star();
    for (final seconds in [0.0, 1.3, 2.05, 7.7]) {
      expect(await _star(seconds: seconds, reduced: true), still);
    }
  });

  test('the star keeps the pickup footprint and its culling reach', () async {
    // Across a full glint cycle nothing, glow included, passes [reach].
    final reach = _height * StarArt.reach + 1;
    for (var i = 0; i < 40; i++) {
      final all = _bounds(
        await _star(seconds: i * StarArt.glintPeriod / 40, phase: .4),
      )!;
      expect(all[0], greaterThanOrEqualTo(_center.dx - reach));
      expect(all[1], greaterThanOrEqualTo(_center.dy - reach));
      expect(all[2], lessThanOrEqualTo(_center.dx + reach));
      expect(all[3], lessThanOrEqualTo(_center.dy + reach));
    }
    // The solid body stays close to the size of the old sharp star.
    final body = _bounds(await _star(glow: false), alpha: 127)!;
    const sharp = 2 * SkyStar.radius * _height;
    expect(body[2] - body[0], inInclusiveRange(sharp * .95, sharp * 1.25));
    expect(body[3] - body[1], inInclusiveRange(sharp * .9, sharp * 1.2));
    expect((body[0] + body[2]) / 2, closeTo(_center.dx, 1));
  });

  test(
    'a pickup shrinks into the bird, or fades in place in Reduced Motion',
    () async {
      const width = 640, height = 360;
      final sim = FlightHarness().sim
        ..elapsed = 10
        ..birdY = .5;
      final star = SkyStar(x: .7, y: .35)
        ..collected = true
        ..collectedAt = 9.95
        ..collectedY = .35;
      Future<List<int>?> frame(double at, {bool reduced = false}) async {
        sim.elapsed = at;
        return _bounds(
          await _pixels(
            (c) => StarPickupArt.paint(
              c,
              height.toDouble(),
              star,
              sim,
              reducedMotion: reduced,
            ),
            width: width,
            height: height,
          ),
          alpha: 127,
          width: width,
        );
      }

      double mid(List<int> b) => (b[0] + b[2]) / 2;
      final start = (await frame(9.96))!;
      final late = (await frame(10.1))!;
      expect(mid(late), lessThan(mid(start)), reason: 'toward the bird');
      expect(late[2] - late[0], lessThan(start[2] - start[0]));
      expect(await frame(9.95 + StarPickupArt.duration + .001), isNull);
      final resting = (await frame(10.1, reduced: true))!;
      expect(mid(resting), closeTo(.7 * height, 1.5));
      expect(await frame(10.1, reduced: true), resting);
    },
  );

  test('render the star family for visual review', () async {
    if (!const bool.fromEnvironment('CAPTURE_STAR_DESIGN')) return;
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    const phone = Size(852, _height);
    Future<ui.Image> image(Size size, double scale, void Function(Canvas) d) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(scale);
      d(canvas);
      return recorder.endRecording().toImage(
        (size.width * scale).round(),
        (size.height * scale).round(),
      );
    }

    Future<void> save(ui.Image shot, String name) async {
      final png = await shot.toByteData(format: ui.ImageByteFormat.png);
      Directory(_folder).createSync(recursive: true);
      File('$_folder/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }

    void label(Canvas c, String text, Offset at) => (TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 15,
          color: SkyColors.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout()).paint(c, at);

    // Every region at a sky and a horizon height, at dpr 3 and at dpr 1
    // scaled up without smoothing to show the real pixels.
    for (final (scale, box, zoom) in [(3.0, 40.0, 2.0), (1.0, 30.0, 8.0)]) {
      final cell = box * scale * zoom;
      final rows = <List<ui.Image>>[];
      for (final region in WorldRegion.values) {
        final at = region.index * WorldTour.leg + 8;
        final row = <ui.Image>[];
        for (final y in [.26, .6]) {
          final center = Offset(560, _height * y);
          final scene = await image(phone, scale, (c) {
            SkyScenery.paint(
              c,
              phone,
              seconds: at,
              distance: at * .36,
              reducedMotion: true,
            );
            StarArt.paint(
              c,
              center,
              _height * StarArt.radius,
              seconds: .3,
              phase: 1,
            );
          });
          row.add(
            await image(Size(cell, cell), 1, (c) {
              c.drawImageRect(
                scene,
                Rect.fromCenter(
                  center: center * scale,
                  width: box * scale,
                  height: box * scale,
                ),
                Rect.fromLTWH(0, 0, cell, cell),
                Paint()..filterQuality = FilterQuality.none,
              );
            }),
          );
          scene.dispose();
        }
        rows.add(row);
      }
      const left = 110.0;
      final sheet = Size(left + 2 * (cell + 6), rows.length * (cell + 6));
      await save(
        await image(sheet, 1, (c) {
          c.drawRect(Offset.zero & sheet, Paint()..color = SkyColors.cream);
          for (final (i, row) in rows.indexed) {
            label(
              c,
              WorldRegion.values[i].title,
              Offset(6, i * (cell + 6) + cell / 2 - 9),
            );
            for (final (j, cellImage) in row.indexed) {
              c.drawImage(
                cellImage,
                Offset(left + j * (cell + 6), i * (cell + 6)),
                Paint(),
              );
            }
          }
        }),
        'regions-dpr${scale.round()}',
      );
    }

    // Idle life over one glint cycle, on a day and a night sky, then the
    // family: collectible, mini, sparkle and the Reduced Motion rest.
    final radius = _height * StarArt.radius;
    const size = Size(16 * 60, 190);
    await save(
      await image(size, 3, (c) {
        for (var i = 0; i < 16; i++) {
          for (final (row, sky) in [
            (0, const Color(0xff7db3dd)),
            (1, const Color(0xff222c55)),
          ]) {
            final cell = Rect.fromLTWH(i * 60.0, row * 60.0, 60, 60);
            c.drawRect(cell, Paint()..color = sky);
            StarArt.paint(
              c,
              cell.center,
              radius,
              seconds: StarArt.glintPeriod - .52 + i * .1,
              phase: .4,
            );
          }
        }
        c.drawRect(
          const Rect.fromLTWH(0, 120, 960, 70),
          Paint()..color = SkyColors.sky,
        );
        StarArt.paint(c, const Offset(40, 155), radius);
        StarArt.mini(c, const Offset(100, 155), radius * .5);
        StarArt.mini(c, const Offset(140, 155), _height * .015);
        StarArt.sparkle(c, const Offset(180, 155), 5, SkyColors.gold);
        StarArt.mini(c, const Offset(240, 155), 13, outline: 1.6);
        StarArt.paint(c, const Offset(320, 155), 30, rotation: -.2);
      }),
      'idle-and-family',
    );
  });
}
