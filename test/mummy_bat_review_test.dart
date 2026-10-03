// Visual review sheets for Neferhoo's mummy bats (T2): close-ups, the wing
// cycle, silhouettes next to the simple bat, the bats at the gameplay radius
// over the real Egypt backdrop and next to Neferhoo and the player's bird
// (a real game of level 2-6), day and dusk, a pair and a trio in flight.
// Writes PNGs to build/visual-review/mummy-bat/ (MUMMY_OUT overrides).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/enemy_defeat_art.dart';
import 'package:push_up_bird/game/enemy_designs/mummy_bat.dart';
import 'package:push_up_bird/game/enemy_hit_art.dart';
import 'package:push_up_bird/game/enemy_designs/simple_bat.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'neferhoo_stage_support.dart';

const _outEnv = String.fromEnvironment('MUMMY_OUT');
final _dir = Directory(
  _outEnv.isEmpty ? 'build/visual-review/mummy-bat' : _outEnv,
);

typedef BatPainter =
    void Function(
      Canvas c,
      double radius, {
      required double seconds,
      required bool reducedMotion,
      double lookY,
      double charge,
      double recoil,
    });

const _mummy = MummyBatArt.paint;
const _simple = SimpleBatArt.paint;

Future<ui.Image> render(
  double w,
  double h,
  void Function(Canvas c) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w.round(), h.round());
  picture.dispose();
  return image;
}

Future<void> save(ui.Image image, String name) async {
  _dir.createSync(recursive: true);
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  File('${_dir.path}/$name.png').writeAsBytesSync(bytes);
}

/// [image]'s [src] region scaled by [k] with no smoothing: real pixels.
Future<ui.Image> crop(ui.Image image, Rect src, double k) => render(
  src.width * k,
  src.height * k,
  (c) => c.drawImageRect(
    image,
    src,
    Rect.fromLTWH(0, 0, src.width * k, src.height * k),
    Paint()..filterQuality = FilterQuality.none,
  ),
);

/// What EnemyArt.paint does around the painter, for a bat at (x, y) screen
/// heights, [age] seconds old, flying on [phase]: its own bank and wing time,
/// turned toward the bird.
void placeBat(
  Canvas c,
  double height,
  BatPainter painter, {
  required double x,
  required double y,
  required double age,
  double phase = 0,
  double birdY = .5,
  bool reduced = false,
}) {
  final enemy = SkyEnemy(x: x, y: y, appearance: 3, flightPhase: phase)
    ..age = age;
  final radius = height * SkyEnemy.radius;
  c.save();
  c.translate(enemy.x * height, enemy.y * height);
  if (enemy.x < FlightSimulation.birdX) c.scale(-1, 1);
  if (!reduced) c.rotate(enemy.flightBank);
  painter(
    c,
    radius,
    seconds: enemy.wingTime,
    reducedMotion: reduced,
    lookY: ((birdY - enemy.y) * 3).clamp(-1.0, 1.0),
  );
  c.restore();
}

Paint _guide() => Paint()
  ..style = PaintingStyle.stroke
  ..color = const Color(0x40203b45);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('close-up poses (8x and bigger)', () async {
    final image = await render(1260, 590, (c) {
      c.drawPaint(Paint()..color = const Color(0xfff2eedf));
      final poses = <(double, double, double, double, bool)>[
        (.1, 0, 0, 0, false),
        (.1, -1, 0, 0, false),
        (.1, 1, 0, 0, false),
        (.1, 0, 1, 0, false),
        (.1, 0, 0, 1, false),
        (.1, 0, 0, 0, true),
      ];
      for (var i = 0; i < poses.length; i++) {
        final (s, look, charge, recoil, reduced) = poses[i];
        c.save();
        c.translate(220 + (i % 3) * 420.0, 150 + (i ~/ 3) * 290.0);
        c.drawRect(const Rect.fromLTRB(-190, -120, 190, 120), _guide());
        _mummy(
          c,
          100,
          seconds: s,
          reducedMotion: reduced,
          lookY: look,
          charge: charge,
          recoil: recoil,
        );
        c.restore();
      }
    });
    await save(image, 'close-up-poses');

    final hero = await render(900, 640, (c) {
      SkyScenery.paint(
        c,
        const Size(900, 640),
        seconds: 5,
        held: WorldRegion.egypt,
      );
      c.translate(450, 330);
      _mummy(c, 260, seconds: 1.55, reducedMotion: false, lookY: .2);
    });
    await save(hero, 'hero');
  });

  test('wing cycle strip and glide strip', () async {
    Future<void> strip(String name, List<double> times) async {
      final image = await render(times.length * 220.0, 300, (c) {
        c.drawPaint(Paint()..color = const Color(0xfff2eedf));
        for (var i = 0; i < times.length; i++) {
          c.save();
          c.translate(110 + i * 220.0, 120);
          c.drawRect(
            const Rect.fromLTRB(-1.9 * 50, -1.2 * 50, 1.9 * 50, 1.2 * 50),
            _guide(),
          );
          _mummy(c, 50, seconds: times[i], reducedMotion: false);
          c.restore();
          c.save();
          c.translate(110 + i * 220.0, 250);
          _mummy(c, 16, seconds: times[i], reducedMotion: false);
          c.restore();
        }
      });
      await save(image, name);
    }

    await strip('wing-cycle-strip', [
      for (var i = 0; i < 13; i++) .8 + i / 12 * MummyBatArt.cycleSeconds,
    ]);
    await strip('glide-strip', [for (var i = 0; i < 14; i++) 1.6 + i * .1]);
  });

  test('silhouette next to the simple bat, 120 px', () async {
    const times = [.1, .3, .5, 1.6];
    final sheet = await render(times.length * 240.0, 600, (c) {
      SkyScenery.paint(
        c,
        const Size(960, 600),
        seconds: 5,
        held: WorldRegion.egypt,
      );
      for (var i = 0; i < times.length; i++) {
        for (final (row, painter, flat) in [
          (0, _simple, true),
          (1, _mummy, true),
          (2, _simple, false),
          (3, _mummy, false),
        ]) {
          c.save();
          c.translate(120 + i * 240.0, 75 + row * 150.0);
          if (flat) {
            c.saveLayer(
              const Rect.fromLTRB(-120, -75, 120, 75),
              Paint()
                ..colorFilter = const ColorFilter.matrix([
                  0, 0, 0, 0, 24, //
                  0, 0, 0, 0, 24,
                  0, 0, 0, 0, 40,
                  0, 0, 0, 1, 0,
                ]),
            );
          }
          painter(c, 60, seconds: times[i], reducedMotion: false);
          if (flat) c.restore();
          c.restore();
        }
      }
    });
    await save(sheet, 'silhouette-120');
  });

  test('over the real Egypt sky at the gameplay radius', () async {
    for (final (label, secs, w) in [
      ('day-640', 5.0, 640.0),
      ('day-792', 5.0, 792.0),
    ]) {
      final image = await render(w, 360, (c) {
        SkyScenery.paint(
          c,
          Size(w, 360),
          seconds: secs,
          held: WorldRegion.egypt,
        );
        for (var i = 0; i < 4; i++) {
          placeBat(
            c,
            360,
            i.isEven ? _mummy : _simple,
            x: .6 + i * .35,
            y: .3 + (i % 2) * .22,
            age: 1.8 + i * .13,
            phase: i * 2.4,
          );
        }
      });
      await save(image, 'sky-$label');
      await save(
        await crop(image, Rect.fromLTWH(0, 40, w * .8, 200), 3),
        'sky-$label-3x',
      );
    }
  });

  test(
    'real pixels: 8x of the gameplay radius, mummy next to simple',
    () async {
      for (final (label, secs) in [('day', 5.0)]) {
        final image = await render(240, 60, (c) {
          SkyScenery.paint(
            c,
            const Size(240, 160),
            seconds: secs,
            held: WorldRegion.egypt,
          );
          for (var i = 0; i < 3; i++) {
            placeBat(
              c,
              360,
              i == 1 ? _simple : _mummy,
              x: (40 + i * 70) / 360,
              y: 30 / 360,
              age: 1.8 + i * .2,
              phase: i * 2.4,
            );
          }
        });
        await save(
          await crop(image, const Rect.fromLTWH(0, 0, 240, 60), 6),
          'pixels-6x-$label',
        );
      }
    },
  );

  test('the defeat pop and the hit flash, mummy next to simple', () async {
    // The ghost of the enemy as EnemyDefeatArt draws it (a white flash, the
    // knock, the squash into the poof) around the given painter, with the
    // simple bat's cloud (the mummy bat's own tint is the dispatch's).
    ColorFilter whiten(double w) {
      const k = 3.4, b = -95.0;
      final keep = 1 - w;
      return ColorFilter.matrix([
        keep + w * .3 * k, w * .59 * k, w * .11 * k, 0, w * b, //
        w * .3 * k, keep + w * .59 * k, w * .11 * k, 0, w * b,
        w * .3 * k, w * .59 * k, keep + w * .11 * k, 0, w * b,
        0, 0, 0, 1, 0,
      ]);
    }

    double outCubic(double t) {
      final x = 1 - t.clamp(0.0, 1.0);
      return 1 - x * x * x;
    }

    void pop(
      Canvas c,
      BatPainter painter,
      double radius,
      double age, {
      bool rammed = false,
    }) {
      EnemyDefeatArt.paint(
        c,
        Offset.zero,
        radius,
        age: age,
        reducedMotion: false,
        rammed: rammed,
        kind: EnemyKind.simpleBat,
        ghost: false,
        seed: 7,
      );
      const life = .17;
      if (age >= life) return;
      final knock = rammed ? const Offset(1.15, -.78) : const Offset(.78, -.2);
      final at = knock * outCubic(age / .22);
      final swallow = ((age - .06) / (life - .06)).clamp(0.0, 1.0);
      final scale = 1 - .72 * swallow * swallow;
      final settle = (1 - age / life) * (1 - age / life);
      final wobble = -math.cos(age / .12 * math.pi * 2) * settle;
      final flash = age < .02 ? 1.0 : (1 - (age - .02) / .055).clamp(0.0, 1.0);
      c.save();
      c.scale(radius);
      c.translate(at.dx, at.dy);
      c.rotate((rammed ? 1.5 : .6) * outCubic(age / .22));
      c.scale(scale * (1 + .2 * wobble), scale * (1 - .16 * wobble));
      if (flash > 0) {
        c.saveLayer(
          const Rect.fromLTRB(-2.2, -1.6, 2.2, 1.6),
          Paint()..colorFilter = whiten(flash),
        );
      }
      c.scale(1 / radius);
      painter(c, radius, seconds: 0, reducedMotion: true);
      if (flash > 0) c.restore();
      c.restore();
    }

    const ages = [.0, .02, .05, .09, .14, .22, .34, .5];
    for (final (name, radius) in [('big', 46.0), ('real', 16.2)]) {
      final cell = radius * 5.2;
      final image = await render(cell * ages.length, cell * 2, (c) {
        SkyScenery.paint(
          c,
          Size(cell * ages.length, cell * 2),
          seconds: 5,
          held: WorldRegion.egypt,
        );
        for (var i = 0; i < ages.length; i++) {
          for (final (row, painter) in [(0, _simple), (1, _mummy)]) {
            c.save();
            c.translate(cell * (i + .4), cell * (row + .55));
            pop(c, painter, radius, ages[i]);
            c.restore();
          }
        }
      });
      await save(
        name == 'real'
            ? await crop(
                image,
                Rect.fromLTWH(
                  0,
                  0,
                  image.width.toDouble(),
                  image.height.toDouble(),
                ),
                4,
              )
            : image,
        'defeat-pop-$name',
      );
    }

    // The same in the real frame (a hit that does not kill: the flash).
    final hitFrames = [.0, .03, .06, .09, .12];
    final hit = await render(hitFrames.length * 110.0, 220, (c) {
      SkyScenery.paint(
        c,
        Size(hitFrames.length * 110.0, 220),
        seconds: 5,
        held: WorldRegion.egypt,
      );
      for (var i = 0; i < hitFrames.length; i++) {
        for (final (row, painter) in [(0, _simple), (1, _mummy)]) {
          c.save();
          c.translate(55 + i * 110.0, 55 + row * 110.0);
          final pose = EnemyHitArt.pose(hitFrames[i], reducedMotion: false);
          if (pose != null) {
            c.translate(24 * pose.shift, 0);
            c.rotate(pose.tilt);
            c.scale(pose.scaleX, pose.scaleY);
          }
          final flash = pose != null && pose.flash > 0;
          if (flash) {
            c.saveLayer(
              Rect.fromCircle(center: Offset.zero, radius: 80),
              Paint()..colorFilter = EnemyHitArt.flashFilter(pose.flash),
            );
          }
          painter(c, 24, seconds: 1.0, reducedMotion: false);
          if (flash) c.restore();
          c.restore();
        }
      }
    });
    await save(hit, 'hit-flash');
  });

  test('a pair and a trio in flight, and Reduced Motion', () async {
    // Frames every .12 s of a pair (then a trio, a bit faster) sweeping in
    // from the right toward the bird over the Egypt sky at 640 x 360.
    const w = 640.0;
    final frames = [0, 1, 2, 3, 4, 5];
    Future<void> sweep(
      String name,
      int count,
      double speed,
      double yBase,
    ) async {
      final image = await render(w, 360, (c) {
        SkyScenery.paint(
          c,
          const Size(w, 360),
          seconds: 5,
          held: WorldRegion.egypt,
        );
        // ghost trails: every frame drawn at a fading alpha, newest last
        for (final f in frames) {
          for (var i = 0; i < count; i++) {
            final t = 1.5 + f * .14;
            c.saveLayer(
              null,
              Paint()
                ..color = Color.fromRGBO(
                  255,
                  255,
                  255,
                  .35 + .65 * f / (frames.length - 1),
                ),
            );
            placeBat(
              c,
              360,
              _mummy,
              x: 1.45 - (t - 1.5) * speed - i * .08,
              y: yBase + i * .17 + i * .01,
              age: t,
              phase: i * 2.4 + count,
              birdY: .5,
            );
            c.restore();
          }
        }
      });
      await save(image, name);
    }

    await sweep('flight-pair', 2, 1.0, .28);
    await sweep('flight-trio', 3, 1.3, .22);

    final still = await render(400, 120, (c) {
      SkyScenery.paint(
        c,
        const Size(400, 120),
        seconds: 5,
        held: WorldRegion.egypt,
      );
      for (var i = 0; i < 3; i++) {
        placeBat(
          c,
          360,
          _mummy,
          x: (60 + i * 100) / 360,
          y: 60 / 360,
          age: 1.8 + i,
          phase: i * 2.4,
          reduced: true,
        );
      }
    });
    await save(
      await crop(still, const Rect.fromLTWH(0, 0, 400, 120), 3),
      'reduced-motion-3x',
    );
  });

  for (final width in const [640.0, 792.0]) {
    testWidgets('in the real game at $width', (tester) async {
      await tester.runAsync(() async {
        final stage = await neferhooStage(tester, width);
        stage.fightTo(7.0);
        for (final dusk in const [false, true]) {
          Future<ui.Image> frame(void Function(Canvas c, double h) over) async {
            final recorder = ui.PictureRecorder();
            final c = Canvas(recorder);
            if (dusk) {
              final size = Size(width, 360);
              SkyScenery.paint(
                c,
                size,
                seconds: stage.sim.elapsed,
                distance: stage.sim.distance,
                reducedMotion: false,
                held: stage.sim.region,
              );
              duskOver(c, size);
              stage.game.transparent = true;
            }
            stage.game.render(c);
            stage.game.transparent = false;
            over(c, 360);
            final picture = recorder.endRecording();
            final image = await picture.toImage(width.toInt(), 360);
            picture.dispose();
            return image;
          }

          final tag = '${width.toInt()}-${dusk ? 'dusk' : 'day'}';
          // A pair with the mail call (stage 2), a trio at fury.
          final image = await frame((c, h) {
            for (var i = 0; i < 3; i++) {
              placeBat(
                c,
                h,
                _mummy,
                x: .78 + i * .2,
                y: .26 + i * .17,
                age: 2 + i * .17,
                phase: i * 2.4,
                birdY: stage.birdY,
              );
            }
          });
          await save(image, 'game-$tag');
          await save(
            await crop(image, Rect.fromLTWH(60, 20, 330, 300), 3),
            'game-$tag-3x',
          );
          await save(
            await crop(image, Rect.fromLTWH(210, 30, 440, 270), 3),
            'game-$tag-boss-3x',
          );
        }
      });
    });
  }
}
