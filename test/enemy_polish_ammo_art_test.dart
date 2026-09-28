import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_ammo_art.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/enemy_ammo_impact_art.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/heart_pickup_art.dart';
import 'package:push_up_bird/game/stone_art.dart';
import 'package:push_up_bird/ui/theme.dart';

const _folder = 'build/visual-review/enemy-polish-ammo';

/// Real sky palettes sampled from `SkyPalette` (top, horizon, hills).
const _skies = [
  ('DAYLIGHT', Color(0xff8dd8eb), Color(0xffe9f5df), Color(0xff68b1a8)),
  ('DUSK', Color(0xffaaa9e0), Color(0xffffdfc3), Color(0xff9e82b4)),
  ('TWILIGHT', Color(0xff485584), Color(0xffadb6da), Color(0xff626c9f)),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pellets record launch time and where they stopped, render-only', () {
    final sim = _arena();
    final enemy = SkyEnemy(x: 1.7, y: .5, appearance: 1)..fireIn = 0;
    sim.enemies.add(enemy);
    _step(sim, .01);
    final launched = sim.enemyAmmo.single;
    expect(launched.bornAt, closeTo(sim.elapsed, .011));
    sim.enemies.clear();
    sim.enemyAmmo.clear();
    // A wall, the player's rock and the bird each stop one pellet; a pellet
    // leaving the screen stops silently.
    sim.obstacles.add(Obstacle(x: 1.0, center: .5, gap: .3));
    sim.enemyAmmo
      ..add(_pellet(1.15, .2))
      ..add(_pellet(.9, .8))
      ..add(_pellet(FlightSimulation.birdX + .05, .5))
      ..add(_pellet(-.099, .9));
    sim.rocks.add(BirdRock(x: .88, y: .8));
    sim.birdY = .5;
    _step(sim, .01);
    expect(sim.enemyAmmo, isEmpty);
    expect(sim.enemyAmmoImpacts.map((i) => i.stop).toSet(), {
      AmmoStop.blocked,
      AmmoStop.deflected,
      AmmoStop.struck,
    });
    expect(sim.enemyAmmoImpacts, hasLength(3));
    expect(sim.projectilesDeflected, 1);
    for (final impact in sim.enemyAmmoImpacts) {
      expect(impact.at, closeTo(sim.elapsed, .011));
      expect(impact.direction, closeTo(math.pi, 1e-9));
    }
    _hover(sim, 1.2);
    expect(sim.enemyAmmoImpacts, isEmpty, reason: 'old splashes are pruned');
  });

  testWidgets('enemy ammo review sheets and transitions', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      Directory(_folder).createSync(recursive: true);
      await _raster((c) => _sheet(c, 1.1), 'ammo-sheet', 1400, 900);
      await _raster(
        (c) => _flightStrip(c, 1.0),
        'ammo-flight-strip',
        1400,
        520,
      );
      await _raster(_launchStrip, 'ammo-launch-strip', 1400, 470);
      for (final reduced in [false, true]) {
        await _raster(
          (c) => _impactStrip(c, reducedMotion: reduced),
          reduced ? 'ammo-impact-strip-reduced' : 'ammo-impact-strip',
          1400,
          900,
        );
      }

      Future<List<int>> tile(void Function(Canvas) draw) =>
          _raster(draw, null, 200, 200);
      for (final attack in [EnemyAttack.aimed, EnemyAttack.fan]) {
        // Launch: a fresh pellet pops and stretches, then settles into
        // exactly the ordinary in-flight look.
        EnemyAmmo pellet(double bornAt) => EnemyAmmo(
          x: .3,
          y: .28,
          vx: -.4,
          vy: 0,
          attack: attack,
          bornAt: bornAt,
        );
        Future<List<int>> flying(double bornAt, {bool reduced = false}) => tile(
          (c) => EnemyArt.ammo(
            c,
            360,
            pellet(bornAt),
            seconds: 2,
            reducedMotion: reduced,
          ),
        );
        final settled = await flying(double.negativeInfinity);
        expect(await flying(1.97), isNot(equals(settled)), reason: '$attack');
        expect(await flying(1.8), settled, reason: '$attack launch settles');
        expect(
          await flying(1.8, reduced: true),
          await flying(double.negativeInfinity, reduced: true),
        );

        // Impacts: visible where the pellet stopped, exact when paused or
        // sought, gone once finished; Reduced Motion holds a still mark.
        for (final stop in AmmoStop.values) {
          for (final reduced in [false, true]) {
            final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
              ..elapsed = 2
              ..birdY = .3;
            Future<List<int>> frame() => tile(
              (c) => CombatArt.paint(c, 360, sim, reducedMotion: reduced),
            );
            final blank = await frame();
            sim.enemyAmmoImpacts.add(
              EnemyAmmoImpact(
                x: .28,
                y: .28,
                worldX: .28,
                birdY: .3,
                direction: math.pi,
                attack: attack,
                stop: stop,
                at: 2,
              ),
            );
            final label = '$attack $stop reduced: $reduced';
            sim.elapsed = 2.02;
            final early = await frame();
            expect(early, isNot(equals(blank)), reason: label);
            expect(await frame(), early, reason: 'paused $label');
            sim.elapsed = 2.1;
            final later = await frame();
            if (reduced) {
              expect(later, early, reason: 'nothing flies: $label');
            } else {
              expect(later, isNot(equals(early)), reason: label);
            }
            sim.elapsed = 2.02;
            expect(await frame(), early, reason: 'seek $label');
            sim.elapsed = 2 + EnemyAmmoImpactArt.seconds;
            expect(await frame(), blank, reason: 'expires $label');
          }
        }
      }
    });
  });

  for (final (name, elapsed) in [
    ('day', 6.0),
    ('dusk', 26.0),
    ('twilight', 46.0),
  ]) {
    testWidgets('enemy ammo in the actual game at $name', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim = _scene(elapsed);
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
        await _raster(game.render, 'in-game-$name', 800, 360);
        _impacts(sim);
        for (final ms in [30, 90, 180]) {
          sim.elapsed = elapsed + ms / 1000;
          await _raster(game.render, 'in-game-impacts-$name-${ms}ms', 800, 360);
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

FlightSimulation _arena() {
  final sim = FlightSimulation(
    rules: TapFlyMode(),
    practice: true,
    course: FlightCourse.starTrail,
    random: math.Random(7),
  );
  _step(sim, 3);
  sim.obstacles.clear();
  sim.enemies.clear();
  sim.stars.clear();
  sim.starTrios.clear();
  return sim;
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
  sim.tick(dt, now, viewportWidth: 2.2);
}

void _hover(FlightSimulation sim, double seconds) {
  for (var i = 0; i < (seconds * 100).round(); i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    _step(sim, .01);
  }
}

EnemyAmmo _pellet(double x, double y) =>
    EnemyAmmo(x: x, y: y, vx: -.44, vy: 0, attack: EnemyAttack.aimed);

/// Stops pellets at one instant: spit and an ember on a garden wall, an
/// ember against the player's rock, and spit on the bird.
void _impacts(FlightSimulation sim) {
  sim.obstacles.add(Obstacle(x: .95, center: .52, gap: .3));
  EnemyAmmoImpact impact(
    double x,
    double y,
    EnemyAttack attack,
    AmmoStop stop, {
    double direction = math.pi,
  }) => EnemyAmmoImpact(
    x: x,
    y: y,
    worldX: sim.distance + x,
    birdY: sim.birdY,
    direction: direction,
    attack: attack,
    stop: stop,
    at: sim.elapsed,
  );
  sim.enemyAmmoImpacts
    ..add(
      impact(
        1.105,
        .22,
        EnemyAttack.aimed,
        AmmoStop.blocked,
        direction: math.pi - .12,
      ),
    )
    ..add(
      impact(
        1.105,
        .80,
        EnemyAttack.fan,
        AmmoStop.blocked,
        direction: math.pi + .2,
      ),
    )
    ..add(impact(.80, .42, EnemyAttack.fan, AmmoStop.deflected))
    ..add(
      impact(
        FlightSimulation.birdX + .05,
        .47,
        EnemyAttack.aimed,
        AmmoStop.struck,
        direction: math.pi - .3,
      ),
    );
  sim.rocks.clear();
  sim.enemyAmmo.removeAt(0);
}

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

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

/// A mid-flight moment: both shooters, an aimed spit and a three-ember fan
/// crossing the sky toward the bird, next to a player rock and a heart.
FlightSimulation _scene(double elapsed) {
  final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
    ..phase = RunPhase.playing
    ..elapsed = elapsed
    ..birdY = .5;
  sim.enemies
    ..add(
      SkyEnemy(x: 1.72, y: .30, appearance: 1, flightPhase: 2.4)
        ..age = 1.8
        ..preparing = true
        ..fireIn = .3,
    )
    ..add(
      SkyEnemy(x: 1.9, y: .66, appearance: 2, flightPhase: 4.8)
        ..age = 1.8
        ..preparing = true
        ..fireIn = 1.2,
    );
  final aim = math.atan2(.5 - .30, FlightSimulation.birdX - 1.72);
  sim.enemyAmmo.add(
    EnemyAmmo(
      x: 1.18,
      y: .30 + (1.72 - 1.18) * math.tan(aim).abs(),
      vx: math.cos(aim) * .44,
      vy: math.sin(aim) * .44,
      attack: EnemyAttack.aimed,
    ),
  );
  final fanAim = math.atan2(.5 - .66, FlightSimulation.birdX - 1.9);
  for (final offset in [-.30, 0.0, .30]) {
    final a = fanAim + offset;
    sim.enemyAmmo.add(
      EnemyAmmo(
        x: 1.9 - .047 + math.cos(a) * .30,
        y: .66 + math.sin(a) * .30,
        vx: math.cos(a) * .34,
        vy: math.sin(a) * .34,
        attack: EnemyAttack.fan,
      ),
    );
  }
  sim.rocks.add(BirdRock(x: .78, y: .44));
  sim.heartPickups.add(SkyHeart(x: 1.02, y: .80));
  return sim;
}

void _background(Canvas c, Rect r, int sky, {bool hills = true}) {
  final (_, top, horizon, land) = _skies[sky];
  c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, horizon],
      ).createShader(r),
  );
  if (!hills) return;
  final base = r.bottom;
  c.drawPath(
    Path()
      ..moveTo(r.left, base - r.height * .18)
      ..quadraticBezierTo(
        r.left + r.width * .3,
        base - r.height * .42,
        r.left + r.width * .62,
        base - r.height * .2,
      )
      ..quadraticBezierTo(
        r.left + r.width * .82,
        base - r.height * .06,
        r.right,
        base - r.height * .25,
      )
      ..lineTo(r.right, base)
      ..lineTo(r.left, base)
      ..close(),
    Paint()..color = land,
  );
}

EnemyAmmo _ammo(
  EnemyAttack attack,
  Offset px,
  double height, {
  double angle = 0,
}) => EnemyAmmo(
  x: px.dx / height,
  y: px.dy / height,
  vx: -math.cos(angle) * (attack == EnemyAttack.aimed ? .44 : .34),
  vy: math.sin(angle) * (attack == EnemyAttack.aimed ? .44 : .34),
  attack: attack,
);

void _hitCircle(Canvas c, Offset center, double radius) {
  c.drawCircle(
    center,
    radius,
    Paint()
      ..color = const Color(0xffe0187a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
}

void _sheet(Canvas c, double seconds) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(c, 'SMALL-ENEMY AMMO', const Offset(28, 18), 28);
  _text(
    c,
    'Close-up (hit circle in magenta) · boss relative · gameplay size on '
    'real sky palettes next to the player rock and a heart',
    const Offset(28, 56),
    15,
  );
  for (var kind = 0; kind < 2; kind++) {
    final attack = kind == 0 ? EnemyAttack.aimed : EnemyAttack.fan;
    final left = 24.0 + kind * 690;
    final panel = Rect.fromLTWH(left, 92, 666, 300);
    c.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(20)),
      Paint()..color = SkyColors.cream,
    );
    _text(
      c,
      kind == 0 ? 'Spitter beetle · mint spit' : 'Dusk moth · amber ember',
      Offset(left + 20, 104),
      20,
    );
    const detail = 3000.0; // hit radius 48 px
    final r = detail * EnemyAmmo.radius;
    final center = Offset(left + 190, 250);
    EnemyArt.ammo(
      c,
      detail,
      _ammo(attack, center, detail),
      seconds: seconds,
      reducedMotion: false,
    );
    final checked = Offset(left + 420, 250);
    EnemyArt.ammo(
      c,
      detail,
      _ammo(attack, checked, detail),
      seconds: seconds,
      reducedMotion: false,
    );
    _hitCircle(c, checked, r);
    BossAmmoArt.paint(
      c,
      center: Offset(left + 590, 250),
      radius: 30,
      direction: math.pi,
      attack: attack,
      seconds: seconds,
      reducedMotion: false,
    );
    _text(c, 'IN FLIGHT', Offset(left + 150, 350), 11, color: SkyColors.purple);
    _text(
      c,
      'HIT CIRCLE',
      Offset(left + 385, 350),
      11,
      color: SkyColors.purple,
    );
    _text(c, 'BOSS', Offset(left + 575, 350), 11, color: SkyColors.purple);
  }
  _text(
    c,
    'GAMEPLAY SIZE · 360 px HIGH VIEWPORT',
    const Offset(28, 410),
    13,
    color: SkyColors.purple,
  );
  for (var sky = 0; sky < 3; sky++) {
    final tile = Rect.fromLTWH(24 + sky * 460, 436, 444, 440);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(tile, const Radius.circular(14)));
    _background(c, tile, sky);
    _text(
      c,
      _skies[sky].$1,
      tile.topLeft + const Offset(12, 10),
      11,
      color: sky == 2 ? SkyColors.cream : SkyColors.ink,
    );
    const h = 360.0;
    final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
      ..elapsed = seconds;
    sim.enemies
      ..add(
        SkyEnemy(
          x: (tile.left + 390) / h,
          y: (tile.top + 90) / h,
          appearance: 1,
        )..age = 1.8,
      )
      ..add(
        SkyEnemy(
          x: (tile.left + 390) / h,
          y: (tile.top + 250) / h,
          appearance: 2,
        )..age = 1.8,
      );
    sim.enemyAmmo.add(
      _ammo(
        EnemyAttack.aimed,
        tile.topLeft + const Offset(250, 100),
        h,
        angle: -.08,
      ),
    );
    for (final a in [-.3, 0.0, .3]) {
      sim.enemyAmmo.add(
        _ammo(
          EnemyAttack.fan,
          tile.topLeft + Offset(270 - math.cos(a) * 40, 250 + math.sin(a) * 90),
          h,
          angle: a,
        ),
      );
    }
    CombatArt.paint(c, h, sim, reducedMotion: false);
    StoneArt.paint(
      c,
      h,
      BirdRock(x: (tile.left + 90) / h, y: (tile.top + 170) / h),
      seconds: seconds,
      reducedMotion: false,
    );
    HeartPickupArt.paint(
      c,
      h,
      SkyHeart(x: (tile.left + 80) / h, y: (tile.top + 330) / h),
      seconds: seconds,
      reducedMotion: false,
    );
    // The in-game star pickup, as drawn by BirdGame.
    final star = tile.topLeft + const Offset(80, 70);
    c.drawCircle(
      star,
      h * .038,
      Paint()..color = SkyColors.cream.withValues(alpha: .6),
    );
    c.drawPath(
      _star(star + const Offset(0, 1.4), h * SkyStar.radius),
      Paint()..color = SkyColors.gold,
    );
    c.drawPath(
      _star(star, h * SkyStar.radius),
      Paint()..color = SkyColors.yellow,
    );
    c.restore();
  }
}

Path _star(Offset center, double r) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final d = i.isEven ? r : r * .45;
    final p = center + Offset(math.cos(a), math.sin(a)) * d;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

void _flightStrip(Canvas c, double start) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(c, 'FLIGHT · 1/30 s PER FRAME', const Offset(24, 14), 20);
  for (var kind = 0; kind < 2; kind++) {
    final attack = kind == 0 ? EnemyAttack.aimed : EnemyAttack.fan;
    for (var f = 0; f < 8; f++) {
      final cell = Rect.fromLTWH(20 + f * 172.0, 52 + kind * 232.0, 164, 220);
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(cell, const Radius.circular(10)));
      _background(c, cell, kind == 0 ? 0 : 1, hills: false);
      const detail = 1500.0;
      EnemyArt.ammo(
        c,
        detail,
        _ammo(attack, cell.topLeft + const Offset(52, 70), detail),
        seconds: start + f / 30,
        reducedMotion: false,
      );
      EnemyArt.ammo(
        c,
        360,
        _ammo(attack, cell.topLeft + const Offset(52, 170), 360),
        seconds: start + f / 30,
        reducedMotion: false,
      );
      c.restore();
    }
  }
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

const _launchAges = [0.0, .016, .033, .05, .066, .083, .1, .15];

/// Launch frames at 60 fps: detail scale above, gameplay size (with the
/// real shooter) below. The magenta tick marks the muzzle.
void _launchStrip(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'LAUNCH · pop + stretch, wake unrolls from the muzzle',
    const Offset(24, 14),
    20,
  );
  for (var kind = 0; kind < 2; kind++) {
    final attack = kind == 0 ? EnemyAttack.aimed : EnemyAttack.fan;
    final speed = kind == 0 ? .44 : .34;
    for (var f = 0; f < _launchAges.length; f++) {
      final age = _launchAges[f];
      final cell = Rect.fromLTWH(20 + f * 172.0, 52 + kind * 206.0, 164, 196);
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(cell, const Radius.circular(10)));
      _background(c, cell, kind == 0 ? 0 : 1, hills: false);
      _text(
        c,
        '${(age * 1000).round()} ms',
        cell.topLeft + const Offset(8, 6),
        11,
      );
      const detail = 1500.0;
      final muzzle = cell.topLeft + const Offset(140, 70);
      c.drawLine(
        muzzle + const Offset(0, -30),
        muzzle + const Offset(0, 30),
        Paint()
          ..color = const Color(0xffe0187a)
          ..strokeWidth = 1,
      );
      EnemyArt.ammo(
        c,
        detail,
        EnemyAmmo(
          x: (muzzle.dx - speed * age * detail) / detail,
          y: muzzle.dy / detail,
          vx: -speed,
          vy: 0,
          attack: attack,
          bornAt: 3 - age,
        ),
        seconds: 3,
        reducedMotion: false,
      );
      const h = 360.0;
      final enemy =
          SkyEnemy(
              x: (cell.left + 128) / h,
              y: (cell.top + 160) / h,
              appearance: kind + 1,
            )
            ..age = 2
            ..lastShotAt = 2 - age;
      EnemyArt.paint(c, h, enemy, birdY: enemy.y, reducedMotion: false);
      EnemyArt.ammo(
        c,
        h,
        EnemyAmmo(
          x: enemy.muzzleX - speed * age,
          y: enemy.y,
          vx: -speed,
          vy: 0,
          attack: attack,
          bornAt: 3 - age,
        ),
        seconds: 3,
        reducedMotion: false,
      );
      c.restore();
    }
  }
}

const _impactAges = [0.0, .016, .04, .07, .1, .14, .19, .25, .31];

/// Every way a pellet stops, frame by frame at detail scale.
void _impactStrip(Canvas c, {required bool reducedMotion}) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'IMPACTS${reducedMotion ? ' · REDUCED MOTION' : ''} · '
    'wall · player rock · bird',
    const Offset(24, 14),
    20,
  );
  const rows = [
    (EnemyAttack.aimed, AmmoStop.blocked),
    (EnemyAttack.aimed, AmmoStop.deflected),
    (EnemyAttack.aimed, AmmoStop.struck),
    (EnemyAttack.fan, AmmoStop.blocked),
    (EnemyAttack.fan, AmmoStop.deflected),
    (EnemyAttack.fan, AmmoStop.struck),
  ];
  for (var row = 0; row < rows.length; row++) {
    final (attack, stop) = rows[row];
    for (var f = 0; f < _impactAges.length; f++) {
      final age = _impactAges[f];
      final cell = Rect.fromLTWH(20 + f * 152.0, 50 + row * 140.0, 146, 134);
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(cell, const Radius.circular(10)));
      _background(c, cell, row < 3 ? 0 : 1, hills: false);
      _text(
        c,
        '${(age * 1000).round()} ms',
        cell.topLeft + const Offset(6, 4),
        10,
      );
      final at = cell.center + const Offset(-6, 4);
      const radius = 16.0; // a 1000 px high viewport
      if (stop == AmmoStop.blocked) {
        c.drawRect(
          Rect.fromLTRB(cell.left, cell.top, at.dx - radius, cell.bottom),
          Paint()..color = const Color(0xffe7d3b4),
        );
        c.drawLine(
          Offset(at.dx - radius, cell.top),
          Offset(at.dx - radius, cell.bottom),
          Paint()
            ..color = SkyColors.ink
            ..strokeWidth = 3,
        );
      } else if (stop == AmmoStop.struck) {
        c.drawCircle(
          at + const Offset(-radius - 38, 0),
          40,
          Paint()..color = SkyColors.yellow,
        );
      }
      EnemyAmmoImpactArt.splash(
        c,
        at,
        radius,
        direction: math.pi,
        attack: attack,
        stop: stop,
        age: age,
        reducedMotion: reducedMotion,
      );
      c.restore();
    }
  }
}
