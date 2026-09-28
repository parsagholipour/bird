import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_designs/aimed_enemy.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/ui/theme.dart';

const _folder = 'build/visual-review/enemy-polish/spitter-beetle';

/// One scripted attack loop: cruise, a full .75 s warning, the .24 s recoil
/// after the shot, then a short recovery back into cruise.
const _cruise = .7, _loop = 2.3;
final _shotAt = _cruise + SkyEnemy.warningSeconds;

(double charge, double recoil) _attack(double clock) {
  final t = clock % _loop;
  if (t < _cruise) return (0, 0);
  if (t < _shotAt) return ((t - _cruise) / SkyEnemy.warningSeconds, 0);
  return (0, (1 - (t - _shotAt) / .24).clamp(0.0, 1.0));
}

String _stage(double clock) {
  final t = clock % _loop;
  if (t < _cruise) return 'CRUISE';
  if (t < _shotAt) return 'CHARGE';
  if (t < _shotAt + .1) return 'SPIT';
  if (t < _shotAt + .24) return 'RECOIL';
  return 'RECOVER';
}

SkyEnemy _enemy(double x, double y, double clock, {double? phase = 2.399963}) {
  final t = clock % _loop;
  final (charge, _) = _attack(clock);
  return SkyEnemy(x: x, y: y, appearance: 1, flightPhase: phase)
    ..age = 3 + clock
    ..preparing = true
    ..fireIn = charge > 0
        ? SkyEnemy.warningSeconds * (1 - charge)
        : t < _cruise
        ? SkyEnemy.warningSeconds + (_cruise - t)
        : 2.4
    ..lastShotAt = t >= _shotAt ? 3 + clock - (t - _shotAt) : -10;
}

/// Paints the real [EnemyArt] (flip, bank, charge and recoil included) with
/// the hit centre at [at], plus the aimed seed once it has been spat.
void _paintAt(
  Canvas c,
  Offset at,
  double height,
  double clock, {
  double look = 0,
  bool reduced = false,
}) {
  final enemy = _enemy(2, .5, clock);
  c.save();
  c.translate(at.dx - 2 * height, at.dy - enemy.y * height);
  EnemyArt.paint(
    c,
    height,
    enemy,
    birdY: enemy.y + look,
    reducedMotion: reduced,
  );
  final t = (clock % _loop) - _shotAt;
  if (t >= 0 && t < 1.2) {
    final shooter = _enemy(2, .5, clock - t);
    EnemyArt.ammo(
      c,
      height,
      EnemyAmmo(
        x: enemy.muzzleX - t * .44,
        y: shooter.y,
        vx: -.44,
        vy: 0,
        attack: EnemyAttack.aimed,
      ),
      seconds: 3 + clock,
      reducedMotion: reduced,
    );
  }
  c.restore();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('spitter beetle fills its box, telegraphs and stays exact', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final family in ['Fredoka', 'Nunito']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
      }
      final folder = Directory(_folder)..createSync(recursive: true);
      Future<ui.Image> image(void Function(Canvas) draw, int w, int h) {
        final recorder = ui.PictureRecorder();
        draw(Canvas(recorder));
        final picture = recorder.endRecording();
        return picture.toImage(w, h).whenComplete(picture.dispose);
      }

      Future<List<int>> pixels(
        void Function(Canvas) draw, {
        int w = 480,
        int h = 300,
      }) async {
        final img = await image(draw, w, h);
        final bytes = (await img.toByteData())!.buffer.asUint8List();
        img.dispose();
        return bytes;
      }

      Future<void> save(
        String name,
        void Function(Canvas) draw,
        int w,
        int h,
      ) async {
        final img = await image(draw, w, h);
        File('${folder.path}/$name.png').writeAsBytesSync(
          (await img.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List(),
        );
        img.dispose();
      }

      // Painted bounds in hit-radius units, measured on a 100 px radius.
      const unit = 100.0, cx = 240.0, cy = 150.0;
      var solid = 0;
      Future<Rect> bounds({
        required double seconds,
        double charge = 0,
        double recoil = 0,
        double lookY = 0,
        bool reduced = false,
      }) async {
        final data = await pixels((c) {
          c.translate(cx, cy);
          AimedEnemyArt.paint(
            c,
            unit,
            seconds: seconds,
            reducedMotion: reduced,
            lookY: lookY,
            charge: charge,
            recoil: recoil,
          );
        });
        var l = 480, t = 300, r = -1, b = -1;
        solid = 0;
        for (var y = 0; y < 300; y++) {
          for (var x = 0; x < 480; x++) {
            final alpha = data[(y * 480 + x) * 4 + 3];
            if (alpha > 240) solid++;
            if (alpha > 10) {
              l = math.min(l, x);
              r = math.max(r, x);
              t = math.min(t, y);
              b = math.max(b, y);
            }
          }
        }
        return Rect.fromLTRB(
          (l - cx) / unit,
          (t - cy) / unit,
          (r + 1 - cx) / unit,
          (b + 1 - cy) / unit,
        );
      }

      var union = Rect.zero;
      var narrowest = double.infinity;
      final report = StringBuffer();
      for (var i = 0; i < 24; i++) {
        final box = await bounds(seconds: 5 + i * .0137);
        union = union.expandToInclude(box);
        narrowest = math.min(narrowest, box.width);
      }
      report.writeln(
        'cruise wing cycle: $union  narrowest ${narrowest.toStringAsFixed(2)}r',
      );
      for (final look in [-1.0, 1.0]) {
        union = union.expandToInclude(await bounds(seconds: 5, lookY: look));
      }
      for (var i = 0; i <= 10; i++) {
        final charge = await bounds(seconds: 5.3 + i * .07, charge: i / 10);
        final recoil = await bounds(seconds: 6.1 + i * .02, recoil: i / 10);
        report.writeln(
          'charge ${i / 10}: ${_fmt(charge)}   recoil ${i / 10}: ${_fmt(recoil)}',
        );
        union = union.expandToInclude(charge).expandToInclude(recoil);
        for (final reduced in [true]) {
          union = union
              .expandToInclude(
                await bounds(seconds: 5, charge: i / 10, reduced: reduced),
              )
              .expandToInclude(
                await bounds(seconds: 5, recoil: i / 10, reduced: reduced),
              );
        }
      }
      report.writeln('union of every pose: ${_fmt(union)}');
      await bounds(seconds: 5);
      report.writeln(
        'opaque cruise area: ${(solid / unit / unit).toStringAsFixed(2)} r²',
      );
      // ignore: avoid_print
      print(report);
      File('${folder.path}/bounds.txt').writeAsStringSync('$report');
      // Review sheets are written before any assertion so a failing pose can
      // still be inspected.
      await save('detail-states', _detailStates, 1500, 700);
      await save('sequence-strip', _sequenceStrip, 1560, 760);
      await save('wing-cycle', _wingCycle, 1500, 330);
      await save('gameplay-skies', _gameplaySkies, 1200, 560);
      await save('spitter-sequence', (c) => _sequence(c, 1.3), 1000, 520);
      // 60 fps frames of one full attack loop for motion review.
      const movie = bool.fromEnvironment('CAPTURE_SPITTER_BEETLE_MOVIE');
      if (movie) {
        final frames = Directory('${folder.path}/movie')
          ..createSync(recursive: true);
        for (var frame = 0; frame < 150; frame++) {
          final img = await image((c) => _sequence(c, frame / 60), 1000, 520);
          File(
            '${frames.path}/frame-${frame.toString().padLeft(4, '0')}.png',
          ).writeAsBytesSync(
            (await img.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List(),
          );
          img.dispose();
        }
      }
      expect(union.left, greaterThanOrEqualTo(-1.9));
      expect(union.right, lessThanOrEqualTo(1.9));
      expect(union.top, greaterThanOrEqualTo(-1.2));
      expect(union.bottom, lessThanOrEqualTo(1.2));

      // Determinism, reduced motion and readable telegraph.
      Future<List<int>> pose({
        double seconds = 5,
        double charge = 0,
        double recoil = 0,
        bool reduced = false,
      }) => pixels((c) {
        c.translate(cx, cy);
        AimedEnemyArt.paint(
          c,
          40,
          seconds: seconds,
          reducedMotion: reduced,
          charge: charge,
          recoil: recoil,
        );
      });
      expect(await pose(seconds: 7.31), await pose(seconds: 7.31));
      expect(
        await pose(seconds: 7.31),
        isNot(equals(await pose(seconds: 7.33))),
      );
      for (final (charge, recoil) in [(0.0, 0.0), (.6, 0.0), (0.0, .7)]) {
        expect(
          await pose(seconds: 2, charge: charge, recoil: recoil, reduced: true),
          await pose(seconds: 9, charge: charge, recoil: recoil, reduced: true),
          reason: 'Reduced Motion freezes decoration ($charge, $recoil)',
        );
      }
      final calm = await pose(reduced: true);
      expect(await pose(charge: .5, reduced: true), isNot(equals(calm)));
      expect(await pose(charge: .95, reduced: true), isNot(equals(calm)));
      expect(await pose(recoil: 1, reduced: true), isNot(equals(calm)));
    });
  });

  testWidgets('spitter beetle renders in the actual game, day and dusk', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
      ..phase = RunPhase.playing
      ..birdY = .5;
    // Cruise, mid charge, about to fire, the spit frame and recoil.
    final clocks = [
      .3,
      _cruise + .4,
      _cruise + .7,
      _shotAt + .01,
      _shotAt + .1,
    ];
    for (var i = 0; i < clocks.length; i++) {
      sim.enemies.add(
        _enemy(.95 + i * .26, .2 + (i % 3) * .24, clocks[i], phase: i * 1.7),
      );
    }
    final spitter = sim.enemies[3];
    final aim = math.atan2(
      sim.birdY - spitter.y,
      FlightSimulation.birdX - spitter.muzzleX,
    );
    sim.enemyAmmo.add(
      EnemyAmmo(
        x: spitter.muzzleX + math.cos(aim) * .44 * .01,
        y: spitter.y + math.sin(aim) * .44 * .01,
        vx: math.cos(aim) * .44,
        vy: math.sin(aim) * .44,
        attack: EnemyAttack.aimed,
      ),
    );
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: false,
      playback: true,
      onChanged: () {},
    );
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() async {
      await game.loaded;
      game.pauseEngine();
      final folder = Directory(_folder)..createSync(recursive: true);
      for (final (name, elapsed) in [
        ('in-game-day', 5.0),
        ('in-game-dusk', 25.0),
        ('in-game-twilight', 47.0),
      ]) {
        sim.elapsed = elapsed;
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final img = await picture.toImage(800, 360);
        final bytes = (await img.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        File('${folder.path}/$name.png').writeAsBytesSync(bytes);
        expect(bytes.length, greaterThan(2000));
        img.dispose();
        picture.dispose();
      }
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

String _fmt(Rect r) =>
    'x ${r.left.toStringAsFixed(2)}..${r.right.toStringAsFixed(2)} '
    '(${r.width.toStringAsFixed(2)}) y ${r.top.toStringAsFixed(2)}..'
    '${r.bottom.toStringAsFixed(2)}';

void _text(
  Canvas c,
  String text,
  Offset at,
  double size, {
  Color color = SkyColors.ink,
  FontWeight weight = FontWeight.w700,
}) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: weight,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

void _panel(Canvas c, Rect rect, {required bool dusk}) {
  c.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(14)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dusk
            ? const [Color(0xffaaa9e0), Color(0xffffdfc3)]
            : const [Color(0xffbde9f6), Color(0xfff9efd8)],
      ).createShader(rect),
  );
}

/// Real sky scenery behind a panel, so value contrast is judged honestly.
void _sky(Canvas c, Rect rect, double elapsed, Offset scenery) {
  c.save();
  c.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
  c.translate(rect.left - scenery.dx, rect.top - scenery.dy);
  SkyScenery.paint(
    c,
    Size(math.max(800, rect.width + scenery.dx), 360),
    seconds: elapsed,
    distance: 3,
  );
  c.restore();
}

void _muzzleMark(Canvas c, Offset center, double radius) {
  final m = center + Offset(-1.05 * radius, 0);
  final p = Paint()
    ..color = const Color(0xffe0455a)
    ..strokeWidth = 1;
  c.drawLine(m + const Offset(-6, 0), m + const Offset(6, 0), p);
  c.drawLine(m + const Offset(0, -6), m + const Offset(0, 6), p);
}

void _box(Canvas c, Offset center, double radius) {
  c.drawRect(
    Rect.fromCenter(center: center, width: 3.8 * radius, height: 2.4 * radius),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x55203b45),
  );
  c.drawCircle(
    center,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x33e0455a),
  );
}

void _detailStates(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'SPITTER BEETLE · POSES (box ±1.9r × ±1.2r, muzzle +)',
    const Offset(24, 16),
    22,
  );
  const poses = [
    ('Cruise A', 5.0, 0.0, 0.0, 0.0),
    ('Cruise B', 5.021, 0.0, 0.0, 0.0),
    ('Look up', 5.04, 0.0, 0.0, -1.0),
    ('Look down', 5.06, 0.0, 0.0, 1.0),
    ('Charge .35', 5.0, .35, 0.0, 0.0),
    ('Charge .7', 5.0, .7, 0.0, 0.0),
    ('Charge .95', 5.0, .95, 0.0, 0.0),
    ('SPIT 1.0', 5.0, 0.0, 1.0, 0.0),
    ('Recoil .75', 5.0, 0.0, .75, 0.0),
    ('Recoil .4', 5.0, 0.0, .4, 0.0),
  ];
  for (var i = 0; i < poses.length; i++) {
    final (label, seconds, charge, recoil, look) = poses[i];
    final col = i % 5, row = i ~/ 5;
    final rect = Rect.fromLTWH(20 + col * 294.0, 60 + row * 318.0, 282, 306);
    _panel(c, rect, dusk: row == 1 && col > 3);
    _text(c, label, rect.topLeft + const Offset(12, 8), 15);
    final center = rect.center + const Offset(0, 14);
    const radius = 70.0;
    _box(c, center, radius);
    c.save();
    c.translate(center.dx, center.dy);
    AimedEnemyArt.paint(
      c,
      radius,
      seconds: seconds,
      reducedMotion: false,
      lookY: look,
      charge: charge,
      recoil: recoil,
    );
    c.restore();
    _muzzleMark(c, center, radius);
  }
}

void _wingCycle(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(c, 'WING BUZZ · consecutive 60 fps frames', const Offset(24, 12), 20);
  for (var i = 0; i < 10; i++) {
    final rect = Rect.fromLTWH(12 + i * 148.0, 48, 140, 130);
    _panel(c, rect, dusk: false);
    final center = rect.center;
    c.save();
    c.translate(center.dx, center.dy);
    AimedEnemyArt.paint(c, 34, seconds: 5 + i / 60, reducedMotion: false);
    c.restore();
    final small = Rect.fromLTWH(12 + i * 148.0, 188, 140, 130);
    _sky(c, small, 25, const Offset(300, 60));
    c.save();
    c.translate(small.center.dx, small.center.dy);
    AimedEnemyArt.paint(c, 16.2, seconds: 5 + i / 60, reducedMotion: false);
    c.restore();
  }
}

void _sequenceStrip(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'CRUISE > CHARGE > SPIT > RECOVER · real EnemyArt, 1 row per sky',
    const Offset(24, 14),
    20,
  );
  const times = [
    .30,
    .85,
    1.0,
    1.15,
    1.30,
    1.40,
    1.44,
    1.45,
    1.47,
    1.50,
    1.54,
    1.60,
    1.68,
    1.9,
  ];
  for (var i = 0; i < times.length; i++) {
    final clock = times[i];
    final (charge, recoil) = _attack(clock);
    final label = charge > 0
        ? 'charge ${charge.toStringAsFixed(2)}'
        : recoil > 0
        ? 'recoil ${recoil.toStringAsFixed(2)}'
        : _stage(clock).toLowerCase();
    final x = 12 + i * 110.0;
    _text(c, label, Offset(x + 4, 46), 11);
    final detail = Rect.fromLTWH(x, 66, 104, 150);
    _panel(c, detail, dusk: false);
    c.save();
    c.translate(detail.center.dx, detail.center.dy);
    AimedEnemyArt.paint(
      c,
      26,
      seconds: 3 + clock,
      reducedMotion: false,
      charge: charge,
      recoil: recoil,
    );
    c.restore();
    _muzzleMark(c, detail.center, 26);
    for (var sky = 0; sky < 3; sky++) {
      final rect = Rect.fromLTWH(x, 226 + sky * 130.0, 104, 120);
      _sky(
        c,
        rect,
        const [5.0, 25.0, 47.0][sky],
        Offset(560 - (i % 4) * 30, 40 + sky * 30),
      );
      c.save();
      c.clipRect(rect);
      _paintAt(c, rect.center, 360, clock, look: .02);
      c.restore();
    }
  }
  _text(c, 'REDUCED MOTION', const Offset(24, 620), 14);
  for (var i = 0; i < times.length; i++) {
    final clock = times[i];
    final rect = Rect.fromLTWH(12 + i * 110.0, 640, 104, 110);
    _panel(c, rect, dusk: true);
    final (charge, recoil) = _attack(clock);
    c.save();
    c.translate(rect.center.dx, rect.center.dy);
    AimedEnemyArt.paint(
      c,
      22,
      seconds: 3 + clock,
      reducedMotion: true,
      charge: charge,
      recoil: recoil,
    );
    c.restore();
  }
}

void _gameplaySkies(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'ACTUAL SIZE (r = 16.2 px) ON REAL SKIES · cruise / charge .6 / charge .95 / spit / recoil',
    const Offset(24, 14),
    17,
  );
  const elapsed = [5.0, 25.0, 47.0];
  const names = ['DAY', 'DUSK', 'TWILIGHT'];
  const clocks = [.3, 1.15, 1.41, 1.451, 1.53];
  for (var row = 0; row < 3; row++) {
    final rect = Rect.fromLTWH(20, 50 + row * 170.0, 1160, 160);
    _sky(c, rect, elapsed[row], Offset(0, 40 + row * 40));
    _text(c, names[row], rect.topLeft + const Offset(10, 6), 12);
    for (var i = 0; i < clocks.length; i++) {
      final at = rect.topLeft + Offset(120 + i * 225.0, 88);
      _paintAt(c, at, 360, clocks[i], look: .05);
      // A 2.2× enlargement of the same frame for inspection next to it.
      c.save();
      c.translate(at.dx + 100, at.dy);
      c.scale(2.2);
      c.translate(-at.dx, -at.dy);
      _paintAt(c, at, 360, clocks[i], look: .05);
      c.restore();
    }
  }
}

/// A 60 fps capture-friendly sheet like the older `_spitter` scene.
void _sequence(Canvas c, double seconds) {
  c.drawRect(
    const Rect.fromLTWH(0, 0, 1000, 520),
    Paint()..color = const Color(0xfff2eedf),
  );
  _text(c, 'SPITTER BEETLE', const Offset(32, 20), 26, weight: FontWeight.w900);
  final stage = _stage(seconds);
  final (charge, recoil) = _attack(seconds);
  _text(
    c,
    '$stage   charge ${charge.toStringAsFixed(2)}   recoil ${recoil.toStringAsFixed(2)}   t ${seconds.toStringAsFixed(3)}',
    const Offset(32, 58),
    16,
  );
  for (final (rect, height, elapsed) in [
    (const Rect.fromLTWH(24, 96, 560, 400), 1800.0, 5.0),
    (const Rect.fromLTWH(604, 96, 372, 190), 360.0, 5.0),
    (const Rect.fromLTWH(604, 306, 372, 190), 360.0, 25.0),
  ]) {
    if (height > 1000) {
      _panel(c, rect, dusk: false);
    } else {
      _sky(c, rect, elapsed, const Offset(300, 60));
    }
    c.save();
    c.clipRect(rect);
    _paintAt(
      c,
      rect.center + Offset(height > 1000 ? 60 : 90, 0),
      height,
      seconds,
    );
    c.restore();
  }
}
