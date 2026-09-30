import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/ammo_shatter_art.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/ui/theme.dart';

/// Review renders are written with --dart-define=CAPTURE_VISUALS=true.
const _capture = bool.fromEnvironment('CAPTURE_VISUALS');
const _folder = 'build/visual-review/ammo-shatter';

/// Daylight and dusk sky gradients sampled from `SkyPalette` (top, horizon).
const _skies = [
  (Color(0xff8dd8eb), Color(0xffe9f5df)),
  (Color(0xffaaa9e0), Color(0xffffdfc3)),
];

const _tile = 400, _h = 360.0;
const _at = Offset(.55, .55);
const _attacks = [EnemyAttack.aimed, EnemyAttack.fan];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the blast', () {
    for (final attack in _attacks) {
      for (final charge in [PowerShot.shatterCharge, 1.0]) {
        for (final reduced in [false, true]) {
          final label = '$attack charge $charge reduced: $reduced';
          test(
            'is exact when paused or sought and ends on time: $label',
            () async {
              final sim = _sim();
              Future<List<int>> frame() => _pixels(
                (c) => CombatArt.paint(c, _h, sim, reducedMotion: reduced),
              );
              final blank = await frame();
              sim.ammoShatters.add(_shatter(attack, charge));
              sim.elapsed = 1.99;
              expect(await frame(), blank, reason: 'not yet');
              sim.elapsed = 2.02;
              final early = await frame();
              expect(early, isNot(equals(blank)));
              expect(await frame(), early, reason: 'paused');
              sim.elapsed = 2.12;
              final later = await frame();
              if (reduced) {
                expect(_coverage(later), lessThanOrEqualTo(_coverage(early)));
              } else {
                expect(later, isNot(equals(early)));
              }
              sim.elapsed = 2.02;
              expect(await frame(), early, reason: 'sought back');
              sim.elapsed = 2 + AmmoShatterArt.seconds;
              expect(await frame(), blank, reason: 'finished');
              sim.elapsed = 2.99;
              expect(await frame(), blank, reason: 'still finished');
            },
          );
        }
      }
    }

    test('under Reduced Motion never grows', () async {
      for (final attack in _attacks) {
        var coverage = _tile * _tile, extent = double.infinity;
        for (final age in [0.0, .03, .08, .15, .25, .4, .55, .59]) {
          final pixels = await _pixels(
            (c) => _blast(c, attack, 1, age, reducedMotion: true),
          );
          expect(_coverage(pixels), lessThanOrEqualTo(coverage));
          expect(_extent(pixels), lessThanOrEqualTo(extent + 1e-9));
          coverage = _coverage(pixels);
          extent = _extent(pixels);
        }
        expect(coverage, greaterThan(0));
      }
    });

    test('stops on the reach the rules use, which grows with charge', () async {
      const hint = .4 * SkyEnemy.radius * _h;
      for (final attack in _attacks) {
        for (final reduced in [false, true]) {
          final extents = <double>[];
          for (final charge in [PowerShot.shatterCharge, .7, 1.0]) {
            final reach = PowerShot.shatterReach(charge) * _h;
            final extent = _extent(
              await _pixels(
                (c) => _blast(c, attack, charge, .2, reducedMotion: reduced),
              ),
            );
            final label = '$attack $charge reduced: $reduced';
            expect(extent, greaterThanOrEqualTo(reach), reason: label);
            expect(extent, lessThanOrEqualTo(reach + hint), reason: label);
            extents.add(extent);
          }
          expect(extents[1], greaterThan(extents[0] + 15));
          expect(extents[2], greaterThan(extents[1] + 15));
        }
      }
    });

    test('keeps the pellet material: mint spit and amber ember', () async {
      int green(List<int> p) => _count(p, (r, g, b) => g > r + 40 && g > b);
      int orange(List<int> p) => _count(p, (r, g, b) => r > g + 50 && g > b);
      for (final reduced in [false, true]) {
        final spit = await _pixels(
          (c) => _blast(c, EnemyAttack.aimed, 1, .08, reducedMotion: reduced),
        );
        final ember = await _pixels(
          (c) => _blast(c, EnemyAttack.fan, 1, .08, reducedMotion: reduced),
        );
        expect(spit, isNot(equals(ember)));
        expect(green(spit), greaterThan(green(ember) * 3 + 50));
        expect(orange(ember), greaterThan(orange(spit) * 2 + 50));
      }
    });

    test('scrolls with the scenery', () async {
      final sim = _sim()..ammoShatters.add(_shatter(EnemyAttack.fan, 1));
      sim.elapsed = 2.2;
      Future<Offset> centroid() async => _centroid(
        await _pixels((c) => CombatArt.paint(c, _h, sim, reducedMotion: false)),
      );
      final still = await centroid();
      sim.distance = .1;
      final moved = await centroid();
      expect(moved.dx, closeTo(still.dx - .1 * _h, .5));
      expect(moved.dy, closeTo(still.dy, .5));
    });

    test('guards against degenerate sizes', () async {
      final blank = await _pixels((_) {});
      for (final (radius, reach) in [
        (0.0, 40.0),
        (6.0, 0.0),
        (double.nan, 40.0),
        (6.0, double.infinity),
      ]) {
        expect(
          await _pixels(
            (c) => AmmoShatterArt.blast(
              c,
              const Offset(200, 200),
              radius,
              reach: reach,
              charge: 1,
              direction: math.pi,
              attack: EnemyAttack.aimed,
              age: .1,
              reducedMotion: false,
            ),
          ),
          blank,
        );
      }
    });
  });

  group('visual review', skip: !_capture, () {
    test('filmstrips and the Reduced Motion still', () async {
      await _fonts();
      Directory(_folder).createSync(recursive: true);
      for (final reduced in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          await _raster(
            (c) => _strip(c, scale, reducedMotion: reduced),
            'strip${scale > 1 ? '-detail' : ''}${reduced ? '-reduced' : ''}',
            (40 + _ages.length * 200 * scale).round(),
            (60 + 4 * 210 * scale).round(),
          );
        }
      }
    });
  });

  for (final (name, attack, charge, reduced) in [
    ('ember-full', EnemyAttack.fan, 1.0, false),
    ('spit-weakest', EnemyAttack.aimed, PowerShot.shatterCharge, false),
    ('ember-full-reduced', EnemyAttack.fan, 1.0, true),
  ]) {
    testWidgets('in the actual game: $name', skip: !_capture, (tester) async {
      await _fonts();
      await _inGame(tester, name, attack, charge, reduced: reduced);
    });
  }
}

FlightSimulation _sim() => FlightSimulation(rules: TapFlyMode(), practice: true)
  ..elapsed = 2
  ..birdY = .3;

AmmoShatter _shatter(EnemyAttack attack, double charge) => AmmoShatter(
  x: _at.dx,
  y: _at.dy,
  worldX: _at.dx,
  reach: PowerShot.shatterReach(charge),
  charge: charge,
  direction: math.pi,
  attack: attack,
  at: 2,
);

void _blast(
  Canvas c,
  EnemyAttack attack,
  double charge,
  double age, {
  required bool reducedMotion,
}) => AmmoShatterArt.blast(
  c,
  _at * _h,
  EnemyAmmo.radius * _h,
  reach: PowerShot.shatterReach(charge) * _h,
  charge: charge,
  direction: math.pi,
  attack: attack,
  age: age,
  reducedMotion: reducedMotion,
);

Future<List<int>> _pixels(void Function(Canvas) draw) =>
    _raster(draw, null, _tile, _tile);

Future<List<int>> _raster(
  void Function(Canvas) draw,
  String? name,
  int width,
  int height,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final pixels = (await image.toByteData())!.buffer.asUint8List();
  if (name != null) {
    final png = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    File('$_folder/$name.png').writeAsBytesSync(png);
  }
  image.dispose();
  picture.dispose();
  return pixels;
}

int _coverage(List<int> rgba) {
  var n = 0;
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] > 0) n++;
  }
  return n;
}

int _count(List<int> rgba, bool Function(int r, int g, int b) test) {
  var n = 0;
  for (var i = 0; i < rgba.length; i += 4) {
    // Straight colour from premultiplied pixels that are clearly painted.
    final a = rgba[i + 3];
    if (a < 128) continue;
    final r = rgba[i] * 255 ~/ a, g = rgba[i + 1] * 255 ~/ a;
    final b = rgba[i + 2] * 255 ~/ a;
    if (test(r, g, b)) n++;
  }
  return n;
}

/// The farthest painted pixel from the blast's centre, in pixels.
double _extent(List<int> rgba) {
  final center = _at * _h;
  var far = 0.0;
  for (var i = 0; i < rgba.length ~/ 4; i++) {
    if (rgba[i * 4 + 3] < 24) continue;
    final d = (Offset((i % _tile) + .5, (i ~/ _tile) + .5) - center).distance;
    far = math.max(far, d);
  }
  return far;
}

Offset _centroid(List<int> rgba) {
  var x = 0.0, y = 0.0, w = 0.0;
  for (var i = 0; i < rgba.length ~/ 4; i++) {
    final a = rgba[i * 4 + 3].toDouble();
    x += (i % _tile) * a;
    y += (i ~/ _tile) * a;
    w += a;
  }
  return Offset(x / w, y / w);
}

// ------------------------------------------------------------- review --

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

void _background(Canvas c, Rect r, int sky) {
  final (top, horizon) = _skies[sky];
  c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, horizon],
      ).createShader(r),
  );
}

void _text(
  Canvas c,
  String text,
  Offset at,
  double size, {
  Color color = SkyColors.ink,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
}

const _ages = [0.0, .03, .07, .13, .22, .34, .48];

/// Four rows (spit and ember at the weakest and the fullest shattering
/// charge) across the blast's life. A 360 px high viewport at [scale] 1;
/// the magenta circle is the rules' reach, the dashed one the reach plus an
/// enemy's hit radius (where an enemy's centre must be to be caught).
void _strip(Canvas c, double scale, {required bool reducedMotion}) {
  final width = 40 + _ages.length * 200 * scale;
  c.drawRect(
    Rect.fromLTWH(0, 0, width, 60 + 4 * 210 * scale),
    Paint()..color = const Color(0xfff2eedf),
  );
  _text(
    c,
    'AMMO SHATTER${reducedMotion ? ' · REDUCED MOTION' : ''} · '
    '${scale > 1 ? '2x detail' : 'gameplay size (360 px high)'}',
    const Offset(20, 14),
    20,
  );
  const rows = [
    (EnemyAttack.aimed, PowerShot.shatterCharge),
    (EnemyAttack.aimed, 1.0),
    (EnemyAttack.fan, PowerShot.shatterCharge),
    (EnemyAttack.fan, 1.0),
  ];
  final h = _h * scale;
  for (var row = 0; row < rows.length; row++) {
    final (attack, charge) = rows[row];
    for (var f = 0; f < _ages.length; f++) {
      final age = _ages[f];
      final cell = Rect.fromLTWH(
        20 + f * 200 * scale,
        50 + row * 210 * scale,
        196 * scale,
        204 * scale,
      );
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(cell, const Radius.circular(10)));
      _background(c, cell, row < 2 ? 0 : 1);
      final center = cell.center;
      final reach = PowerShot.shatterReach(charge) * h;
      if (f == _ages.length - 1) {
        final guide = Paint()
          ..color = const Color(0xffe0187a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        c.drawCircle(center, reach, guide);
        final outer = reach + SkyEnemy.radius * h;
        for (var i = 0; i < 48; i += 2) {
          c.drawArc(
            Rect.fromCircle(center: center, radius: outer),
            i * math.pi / 24,
            math.pi / 24,
            false,
            guide,
          );
        }
      }
      AmmoShatterArt.blast(
        c,
        center,
        EnemyAmmo.radius * h,
        reach: reach,
        charge: charge,
        direction: math.pi,
        attack: attack,
        age: age,
        reducedMotion: reducedMotion,
        seed: row * .23 + .1,
      );
      _text(
        c,
        '${(age * 1000).round()} ms'
        '${f == 0 ? ' · ${attack.name} ${charge.toStringAsFixed(2)}' : ''}',
        cell.topLeft + const Offset(6, 4),
        11,
      );
      c.restore();
    }
  }
}

/// A live touch flight: a charged rock meets a pellet among three enemies.
/// The dusk moth and the cave bat in front are inside the reach; the cave
/// bat below sits just outside it.
Future<void> _inGame(
  WidgetTester tester,
  String name,
  EnemyAttack attack,
  double charge, {
  required bool reduced,
}) async {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final sim = FlightSimulation(
    rules: TapFlyMode(),
    practice: true,
    course: FlightCourse.starTrail,
    random: math.Random(7),
  );
  _step(sim, 6);
  sim.obstacles.clear();
  sim.enemies.clear();
  sim.stars.clear();
  sim.starTrios.clear();
  sim.heartPickups.clear();
  sim.enemyAmmo.clear();
  sim.rocks.clear();
  const pellet = Offset(1.3, .44);
  final reach = PowerShot.shatterReach(charge);
  SkyEnemy around(double angle, double distance, int appearance) =>
      SkyEnemy(
          x: pellet.dx + math.cos(angle) * distance,
          y: pellet.dy + math.sin(angle) * distance,
          appearance: appearance,
        )
        ..fireIn = 99
        ..age = 2;
  final inside = around(-.8, reach + SkyEnemy.radius * .3, 2);
  final defeated = around(.4, reach + SkyEnemy.radius * .5, 0);
  // Its hit circle clears the reach by about a third of its radius.
  final outside = around(1.92, reach + SkyEnemy.radius * 1.35, 0);
  sim.enemies.addAll([inside, defeated, outside]);
  sim.enemyAmmo.add(
    EnemyAmmo(x: pellet.dx, y: pellet.dy, vx: -.44, vy: .05, attack: attack),
  );
  sim.rocks.add(
    BirdRock(
      x: pellet.dx - .16,
      y: pellet.dy,
      damage: PowerShot.damage(BirdRock.baseDamage, charge),
      charge: charge,
    ),
  );
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget(game: game));
  await tester.runAsync(() async {
    await game.loaded;
    game.pauseEngine();
    Directory(_folder).createSync(recursive: true);
    final frames = <(String, ui.Image)>[];
    Future<void> grab(String label) async {
      final recorder = ui.PictureRecorder();
      game.render(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(800, 360);
      picture.dispose();
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      File('$_folder/in-game-$name-$label.png').writeAsBytesSync(png);
      frames.add((label, image));
    }

    await grab('before');
    while (sim.ammoShatters.isEmpty) {
      _hold(sim, .01);
    }
    expect(sim.enemies, contains(outside));
    expect(outside.hp, outside.maxHp, reason: 'just outside the reach');
    expect(inside.hp, lessThan(inside.maxHp));
    final at = sim.ammoShatters.single.at;
    for (final ms in [0, 40, 90, 160, 260, 400, 560]) {
      while (sim.elapsed - at < ms / 1000 - 1e-9) {
        _hold(sim, .01);
      }
      await grab('${ms.toString().padLeft(3, '0')}ms');
    }
    // A half-size contact sheet of the whole sequence.
    const cols = 4, scale = .5;
    final rows = (frames.length / cols).ceil();
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(
      Rect.fromLTWH(0, 0, 400.0 * cols, 200.0 * rows),
      Paint()..color = const Color(0xfff2eedf),
    );
    for (final (i, (label, image)) in frames.indexed) {
      final at = Offset((i % cols) * 400.0, (i ~/ cols) * 200.0 + 20);
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(scale);
      c.drawImage(image, Offset.zero, Paint());
      c.restore();
      _text(c, label, at - const Offset(-6, 18), 12);
    }
    final sheet = await recorder.endRecording().toImage(400 * cols, 200 * rows);
    File('$_folder/sheet-$name.png').writeAsBytesSync(
      (await sheet.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List(),
    );
    sheet.dispose();
    for (final (_, image) in frames) {
      image.dispose();
    }
  });
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
}

void _step(FlightSimulation sim, double dt) {
  final now = (sim.elapsed + dt) * 1000;
  sim.apply(
    const MovementInput(valid: true),
    TrackingSample(
      mode: sim.rules.mode,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
  sim.tick(dt, now, viewportWidth: 800 / 360);
}

void _hold(FlightSimulation sim, double dt) {
  sim.birdY = .5;
  sim.velocity = 0;
  _step(sim, dt);
}
