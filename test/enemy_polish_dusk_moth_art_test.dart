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
import 'package:push_up_bird/game/enemy_designs/spread_enemy.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/ui/theme.dart';

/// Visual review for the dusk moth: art-box bounds across every pose,
/// deterministic/reduced-motion guarantees, close-ups, gameplay-size panels,
/// an attack frame strip and real 800x360 game frames at day and dusk.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final folder = Directory('build/visual-review/enemy-polish/dusk-moth');

  testWidgets('dusk moth stays in its art box and renders deterministically', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _fonts();
      folder.createSync(recursive: true);

      // Rasterize the bare character at radius 100 and measure its painted
      // bounds through a full wing cycle and every attack pose.
      const r = 100.0, w = 500, h = 300;
      var box = Rect.zero;
      var minWidth = double.infinity;
      final poses = <(double, double)>[
        (0, 0),
        (.2, 0),
        (.45, 0),
        (.7, 0),
        (.9, 0),
        (1, 0),
        (0, 1),
        (0, .75),
        (0, .5),
        (0, .25),
      ];
      await _save(folder, 'closeup-cycle', 1600, 560, _cycleSheet);
      await _save(folder, 'closeup-attack', 1600, 560, _attackSheet);
      await _save(folder, 'gameplay-size', 1200, 700, _gameplaySheet);
      await _save(folder, 'strip-dusk', 1200, 640, (c) => _strip(c, 1));
      await _save(folder, 'strip-day', 1200, 640, (c) => _strip(c, 0));
      await _save(folder, 'strip-closeup', 1600, 900, _closeStrip);
      await _save(folder, 'reduced-motion', 1200, 300, _reducedSheet);
      await _save(folder, 'hero', 1500, 520, _heroSheet);
      if (const bool.fromEnvironment('CAPTURE_DUSK_MOTH_MOVIE')) {
        // 60 fps frames of cruise, windup, volley and recovery.
        for (var frame = 0; frame < 120; frame++) {
          await _save(
            folder,
            'movie-${frame.toString().padLeft(4, '0')}',
            400,
            260,
            (c) => _movieFrame(c, frame / 60),
          );
        }
      }
      for (final (charge, recoil) in poses) {
        var poseBox = Rect.zero;
        for (final look in [-1.0, 0.0, 1.0]) {
          for (var i = 0; i < 24; i++) {
            final seconds = 3 + i * .037;
            final pixels = await _raster(
              (c) {
                c.translate(w / 2, h / 2);
                SpreadEnemyArt.paint(
                  c,
                  r,
                  seconds: seconds,
                  reducedMotion: false,
                  lookY: look,
                  charge: charge,
                  recoil: recoil,
                );
              },
              w,
              h,
            );
            final b = _bounds(pixels, w, h).shift(const Offset(-w / 2, -h / 2));
            final unit = Rect.fromLTRB(
              b.left / r,
              b.top / r,
              b.right / r,
              b.bottom / r,
            );
            box = box == Rect.zero ? unit : box.expandToInclude(unit);
            poseBox = poseBox == Rect.zero
                ? unit
                : poseBox.expandToInclude(unit);
            minWidth = math.min(minWidth, unit.width);
          }
        }
        // ignore: avoid_print
        print(
          '  charge $charge recoil $recoil: '
          'x ${poseBox.left.toStringAsFixed(2)}..'
          '${poseBox.right.toStringAsFixed(2)} '
          'y ${poseBox.top.toStringAsFixed(2)}..'
          '${poseBox.bottom.toStringAsFixed(2)}',
        );
      }
      // ignore: avoid_print
      print(
        'dusk moth painted bounds (r units): '
        'x ${box.left.toStringAsFixed(3)}..${box.right.toStringAsFixed(3)} '
        '(width ${box.width.toStringAsFixed(2)}, narrowest pose '
        '${minWidth.toStringAsFixed(2)}), '
        'y ${box.top.toStringAsFixed(3)}..${box.bottom.toStringAsFixed(3)}',
      );
      // One anti-aliased pixel (.01r) of tolerance at radius 100.
      expect(box.left, greaterThanOrEqualTo(-1.91));
      expect(box.right, lessThanOrEqualTo(1.91));
      expect(box.top, greaterThanOrEqualTo(-1.21));
      expect(box.bottom, lessThanOrEqualTo(1.21));
      expect(box.width, greaterThan(3.2), reason: 'fills its art box');

      Future<Uint8List> pose({
        double seconds = 2,
        bool reduced = false,
        double charge = 0,
        double recoil = 0,
        double look = 0,
      }) => _raster(
        (c) {
          c.translate(w / 2, h / 2);
          SpreadEnemyArt.paint(
            c,
            40,
            seconds: seconds,
            reducedMotion: reduced,
            lookY: look,
            charge: charge,
            recoil: recoil,
          );
        },
        w,
        h,
      );

      // Pure function of its inputs: repeated frames are identical.
      expect(await pose(seconds: 2.37), await pose(seconds: 2.37));
      expect(
        await pose(seconds: 2.37, charge: .6),
        await pose(seconds: 2.37, charge: .6),
      );
      // Motion is visible, and Reduced Motion freezes only decoration.
      expect(await pose(seconds: 2), isNot(equals(await pose(seconds: 2.3))));
      final still = await pose(seconds: 2, reduced: true);
      expect(await pose(seconds: 2.3, reduced: true), still);
      expect(await pose(seconds: 7.9, reduced: true), still);
      for (final charge in [.2, .5, .9]) {
        expect(
          await pose(reduced: true, charge: charge),
          isNot(equals(still)),
          reason: 'charge $charge readable under Reduced Motion',
        );
      }
      expect(
        await pose(reduced: true, charge: .9),
        isNot(equals(await pose(reduced: true, charge: .5))),
      );
      expect(await pose(reduced: true, recoil: .8), isNot(equals(still)));
      expect(await pose(look: 1), isNot(equals(await pose(look: -1))));
    });
  });

  testWidgets('dusk moth in real 800x360 game frames', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
      ..phase = RunPhase.playing
      ..elapsed = 21;
    final cruising = SkyEnemy(x: 1.22, y: .28, appearance: 2, flightPhase: .4)
      ..age = 1.8;
    final charging = SkyEnemy(x: 1.62, y: .50, appearance: 2, flightPhase: 1.9)
      ..age = 2.6
      ..preparing = true
      ..fireIn = .22;
    final fired = SkyEnemy(x: 1.98, y: .74, appearance: 2, flightPhase: 3.1)
      ..age = 3.3
      ..preparing = true
      ..fireIn = 3.1
      ..lastShotAt = 3.3 - .07;
    final bat = SkyEnemy(x: .98, y: .62, appearance: 3, flightPhase: 2.1)
      ..age = 1.8;
    sim.enemies.addAll([cruising, charging, fired, bat]);
    sim.birdY = .5;
    for (final angle in [-.3, 0.0, .3]) {
      final aim = math.atan2(.5 - fired.y, FlightSimulation.birdX - fired.x);
      final travel = .07 * .34;
      sim.enemyAmmo.add(
        EnemyAmmo(
          x: fired.muzzleX + math.cos(aim + angle) * travel,
          y: fired.y + math.sin(aim + angle) * travel,
          vx: math.cos(aim + angle) * .34,
          vy: math.sin(aim + angle) * .34,
          attack: EnemyAttack.fan,
        ),
      );
    }
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
      folder.createSync(recursive: true);
      Future<void> capture(String name) async {
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(800, 360);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        File('${folder.path}/$name.png').writeAsBytesSync(bytes);
        expect(bytes.length, greaterThan(2000));
        image.dispose();
        picture.dispose();
      }

      await capture('in-game-dusk');
      sim.elapsed = 5;
      await capture('in-game-day');
      sim.elapsed = 47;
      await capture('in-game-twilight');
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

Future<Uint8List> _raster(void Function(Canvas) draw, int w, int h) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final pixels = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return pixels;
}

Future<void> _save(
  Directory folder,
  String name,
  int w,
  int h,
  void Function(Canvas) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final png = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  File('${folder.path}/$name.png').writeAsBytesSync(png);
  image.dispose();
  picture.dispose();
}

Rect _bounds(Uint8List rgba, int w, int h) {
  var left = w, top = h, right = -1, bottom = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (rgba[(y * w + x) * 4 + 3] > 10) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  if (right < 0) return Rect.zero;
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right + 1.0,
    bottom + 1.0,
  );
}

void _text(
  Canvas c,
  String text,
  Offset at,
  double size, {
  Color color = SkyColors.ink,
  FontWeight weight = FontWeight.w800,
}) {
  final painter = TextPainter(
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
  )..layout();
  painter.paint(c, at);
}

void _artBox(Canvas c, Offset center, double r) {
  c.drawRect(
    Rect.fromCenter(center: center, width: 3.8 * r, height: 2.4 * r),
    Paint()
      ..color = const Color(0x55203b45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  c.drawCircle(
    center,
    r,
    Paint()
      ..color = const Color(0x33203b45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  c.drawCircle(
    center + Offset(-1.05 * r, 0),
    3,
    Paint()..color = const Color(0xffd75e4f),
  );
}

void _moth(
  Canvas c,
  Offset at,
  double r, {
  double seconds = 2,
  double charge = 0,
  double recoil = 0,
  double look = 0,
  bool reduced = false,
}) {
  c.save();
  c.translate(at.dx, at.dy);
  SpreadEnemyArt.paint(
    c,
    r,
    seconds: seconds,
    reducedMotion: reduced,
    lookY: look,
    charge: charge,
    recoil: recoil,
  );
  c.restore();
}

void _cycleSheet(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'DUSK MOTH · WING CYCLE (close-up, r = 56)',
    const Offset(24, 18),
    22,
  );
  for (var i = 0; i < 12; i++) {
    final col = i % 6, row = i ~/ 6;
    final center = Offset(140 + col * 260.0, 170 + row * 240.0);
    final t = 2 + i * .06;
    _artBox(c, center, 56);
    _moth(c, center, 56, seconds: t, look: row == 0 ? 0 : .8);
    _text(
      c,
      't = ${t.toStringAsFixed(2)}s',
      center + const Offset(-110, -100),
      13,
      color: SkyColors.purple,
    );
  }
}

const _attackPoses = <(String, double, double)>[
  ('cruise', 0, 0),
  ('charge .15', .15, 0),
  ('charge .35', .35, 0),
  ('charge .55', .55, 0),
  ('charge .75', .75, 0),
  ('charge .95', .95, 0),
  ('FIRE r1.0', 0, 1),
  ('recoil .8', 0, .8),
  ('recoil .55', 0, .55),
  ('recoil .3', 0, .3),
  ('recoil .1', 0, .1),
  ('settled', 0, 0),
];

void _attackSheet(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(c, 'DUSK MOTH · CHARGE > FIRE > RECOIL', const Offset(24, 18), 22);
  for (var i = 0; i < _attackPoses.length; i++) {
    final (label, charge, recoil) = _attackPoses[i];
    final col = i % 6, row = i ~/ 6;
    final center = Offset(140 + col * 260.0, 170 + row * 240.0);
    _artBox(c, center, 56);
    _moth(c, center, 56, seconds: 2.1, charge: charge, recoil: recoil);
    _text(
      c,
      label,
      center + const Offset(-110, -100),
      13,
      color: SkyColors.purple,
    );
  }
}

void _gameplaySheet(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'GAMEPLAY SIZE · r = 16.2px (360px viewport) · on every sky band',
    const Offset(24, 16),
    20,
  );
  final palettes = [
    ('EGYPT NOON', WorldRegion.egypt.palette),
    ('CHINA DUSK', WorldRegion.china.palette),
    ('NEW YORK NIGHT', WorldRegion.newYork.palette),
  ];
  const r = 360 * SkyEnemy.radius;
  for (var p = 0; p < palettes.length; p++) {
    final (name, palette) = palettes[p];
    final top = 60.0 + p * 212;
    _text(c, name, Offset(24, top), 13, color: SkyColors.purple);
    final bands = [
      palette.top,
      Color.lerp(palette.top, palette.horizon, .5)!,
      palette.horizon,
      palette.haze,
      palette.land,
      const Color(0xfffffbf2),
    ];
    for (var b = 0; b < bands.length; b++) {
      final rect = Rect.fromLTWH(24 + b * 192.0, top + 22, 184, 180);
      c.drawRect(rect, Paint()..color = bands[b]);
      final poses = [(0.0, 0.0, 2.0), (.55, 0.0, 2.2), (1.0, 0.0, 2.3)];
      for (var k = 0; k < poses.length; k++) {
        final (charge, recoil, t) = poses[k];
        _moth(
          c,
          rect.topLeft + Offset(50 + (k % 2) * 90, 40 + k * 52.0),
          r,
          seconds: t + b * .13,
          charge: charge,
          recoil: recoil,
        );
      }
      _moth(
        c,
        rect.topLeft + const Offset(142, 144),
        r,
        seconds: 2.4,
        recoil: .8,
      );
    }
  }
}

/// A real-renderer timeline: cruise → .75 s charge → volley → recoil → settle.
void _strip(Canvas c, int sky) {
  final palette = sky == 0
      ? WorldRegion.egypt.palette
      : WorldRegion.china.palette;
  c.drawRect(
    const Rect.fromLTWH(0, 0, 1200, 640),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.top, palette.horizon, palette.haze, palette.land],
        stops: const [0, .45, .75, 1],
      ).createShader(const Rect.fromLTWH(0, 0, 1200, 640)),
  );
  _text(
    c,
    'ATTACK TIMELINE · gameplay size · 1/15 s per frame',
    const Offset(20, 12),
    18,
  );
  const cols = 8, cellW = 150.0, cellH = 100.0;
  const frames = 48;
  const fireAt = 1.15;
  for (var i = 0; i < frames; i++) {
    final t = i / 15;
    final col = i % cols, row = i ~/ cols;
    final center = Offset(cellW * col + 100, 88 + row * cellH);
    final enemy = _timelineEnemy(t, fireAt);
    c.save();
    c.clipRect(
      Rect.fromCenter(center: center, width: cellW - 6, height: cellH - 6),
    );
    c.translate(center.dx - enemy.x * 360, center.dy - enemy.y * 360);
    EnemyArt.paint(c, 360, enemy, birdY: enemy.y + .05, reducedMotion: false);
    if (t >= fireAt) {
      final dt = t - fireAt;
      for (final angle in [-.3, 0.0, .3]) {
        EnemyArt.ammo(
          c,
          360,
          EnemyAmmo(
            x: enemy.muzzleX - math.cos(angle) * .34 * dt,
            y: enemy.y + math.sin(angle) * .34 * dt,
            vx: -math.cos(angle) * .34,
            vy: math.sin(angle) * .34,
            attack: EnemyAttack.fan,
          ),
          seconds: t,
          reducedMotion: false,
        );
      }
    }
    c.restore();
    final label = t < fireAt - .75
        ? 'cruise'
        : t < fireAt
        ? 'charge ${enemy.charge.toStringAsFixed(2)}'
        : 'recoil ${enemy.recoil.toStringAsFixed(2)}';
    _text(
      c,
      label,
      center + const Offset(-70, 26),
      10,
      color: SkyColors.ink.withValues(alpha: .7),
    );
  }
}

SkyEnemy _timelineEnemy(double t, double fireAt) {
  final enemy = SkyEnemy(x: 1.5, y: .5, appearance: 2, flightPhase: 1.3)
    ..age = 4 + t;
  if (t < fireAt) {
    enemy
      ..preparing = true
      ..fireIn = fireAt - t;
  } else {
    enemy
      ..preparing = true
      ..fireIn = 3.2 - (t - fireAt)
      ..lastShotAt = 4 + fireAt;
  }
  return enemy;
}

void _closeStrip(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xffd9d2ea));
  _text(
    c,
    'ATTACK TIMELINE · close-up (r = 40) · 1/15 s per frame',
    const Offset(20, 12),
    18,
  );
  const fireAt = 1.15;
  for (var i = 0; i < 32; i++) {
    final t = .45 + i / 15;
    final col = i % 8, row = i ~/ 8;
    final center = Offset(100 + col * 196.0, 130 + row * 200.0);
    final enemy = _timelineEnemy(t, fireAt);
    c.save();
    c.clipRect(Rect.fromCenter(center: center, width: 190, height: 170));
    const height = 40 / SkyEnemy.radius;
    c.translate(center.dx - enemy.x * height, center.dy - enemy.y * height);
    EnemyArt.paint(
      c,
      height,
      enemy,
      birdY: enemy.y + .05,
      reducedMotion: false,
    );
    if (t >= fireAt) {
      final dt = t - fireAt;
      for (final angle in [-.3, 0.0, .3]) {
        EnemyArt.ammo(
          c,
          height,
          EnemyAmmo(
            x: enemy.muzzleX - math.cos(angle) * .34 * dt,
            y: enemy.y + math.sin(angle) * .34 * dt,
            vx: -math.cos(angle) * .34,
            vy: math.sin(angle) * .34,
            attack: EnemyAttack.fan,
          ),
          seconds: t,
          reducedMotion: false,
        );
      }
    }
    c.restore();
    final label = t < fireAt - .75
        ? 'cruise'
        : t < fireAt
        ? 'charge ${enemy.charge.toStringAsFixed(2)}'
        : 'recoil ${enemy.recoil.toStringAsFixed(2)}';
    _text(
      c,
      label,
      center + const Offset(-80, -92),
      12,
      color: SkyColors.purple,
    );
  }
}

void _reducedSheet(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xffd2a9af));
  _text(
    c,
    'REDUCED MOTION · charge & recoil stay readable',
    const Offset(20, 12),
    18,
  );
  const poses = [
    (0.0, 0.0),
    (.3, 0.0),
    (.6, 0.0),
    (.95, 0.0),
    (0.0, 1.0),
    (0.0, .4),
  ];
  for (var i = 0; i < poses.length; i++) {
    final (charge, recoil) = poses[i];
    _moth(
      c,
      Offset(110 + i * 196.0, 170),
      42,
      seconds: 9,
      charge: charge,
      recoil: recoil,
      reduced: true,
    );
  }
}

void _heroSheet(Canvas c) {
  const rect = Rect.fromLTWH(0, 0, 1500, 520);
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          WorldRegion.china.palette.top,
          WorldRegion.china.palette.horizon,
          WorldRegion.china.palette.haze,
        ],
      ).createShader(rect),
  );
  _text(c, 'DUSK MOTH · hero close-up (r = 118)', const Offset(24, 16), 20);
  _moth(c, const Offset(360, 280), 118, seconds: 2.3, look: .4);
  _moth(c, const Offset(1110, 280), 118, seconds: 2.3, charge: .82, look: .4);
  _text(c, 'cruise', const Offset(40, 470), 16, color: SkyColors.purple);
  _text(c, 'charge .82', const Offset(790, 470), 16, color: SkyColors.purple);
}

void _movieFrame(Canvas c, double t) {
  c.drawPaint(Paint()..color = const Color(0xffd9d2ea));
  const fireAt = 1.15;
  final enemy = _timelineEnemy(t, fireAt);
  const height = 60 / SkyEnemy.radius;
  c.translate(210 - enemy.x * height, 130 - enemy.y * height);
  EnemyArt.paint(c, height, enemy, birdY: enemy.y + .05, reducedMotion: false);
}
