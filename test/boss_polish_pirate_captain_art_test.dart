import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_ammo_art.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/pirate_sea_art.dart';

import 'boss_fight_test.dart' show arena;

/// Visual review for the Pirate Captain: a labelled pose sheet of the
/// captain, his ship and cannon at close-up and real phone scale, in-game
/// frames through the real renderer at 640×360 and 800×360, and a
/// cannonball close-up, plus determinism and Reduced Motion checks.
final _folder = Directory('build/visual-review/boss-polish/pirate-captain');

/// A boss [t] seconds into the fight (negative: into the arrival).
SkyBoss _boss({double t = 1.2}) {
  final boss = SkyBoss(number: 4, x: 2, kind: BossKind.pirate, cinematic: true)
    ..fireIn = 1.8;
  boss.age = boss.arrivalDuration + t;
  return boss;
}

typedef _Pose = (String, void Function(SkyBoss), double);

final _poses = <_Pose>[
  ('IDLE · A', (b) {}, 0),
  ('IDLE · B', (b) => b.age += .37, 0),
  ('IDLE · C', (b) => b.age += .81, 0),
  ('CHARGING', (b) => b.fireIn = .12, 0),
  ('FUSE LIT', (b) => b.fireIn = .4, 0),
  ('RECOIL', (b) => b.lastVolleyAt = b.age - .12, 0),
  ('SMOKE', (b) => b.lastVolleyAt = b.age - .45, 0),
  ('HIT FLASH', (b) => b.lastHitAt = b.age - .12, 0),
  ('HULL HIT', (b) => b.lastHullHitAt = b.age - .05, 0),
  ('FURY', (b) => b.hp = b.maxHp ~/ 3, 0),
  (
    'FURY · CHARGING',
    (b) {
      b.hp = b.maxHp ~/ 3;
      b.fireIn = .1;
    },
    0,
  ),
  (
    'FURY · RAGE',
    (b) {
      b.hp = b.maxHp ~/ 3;
      b.enragedAt = b.age - .45;
    },
    0,
  ),
  ('TIDE CALL', (b) => b.age = b.arrivalDuration + 3.9, 0),
  ('HIGH TIDE', (b) => b.age = b.arrivalDuration + 6, 0),
  ('ARRIVAL · SILHOUETTE', (b) => b.age = 1.5, 0),
  ('ARRIVAL · REVEAL', (b) => b.age = 2.1, 0),
  ('ARRIVAL · ROAR', (b) => b.age = SkyBoss.roarAt + .3, 0),
  ('LOOK UP', (b) {}, -1),
  ('LOOK DOWN', (b) {}, 1),
  ('DEFEAT · HIT', (b) => b.defeatedAt = b.age - .15, 0),
  ('DEFEAT · OVERLOAD', (b) => b.defeatedAt = b.age - .7, 0),
  ('DEFEAT · BURST', (b) => b.defeatedAt = b.age - 1.05, 0),
  ('DEFEAT · BREAK', (b) => b.defeatedAt = b.age - 1.1, 0),
  ('DEFEAT · SINK', (b) => b.defeatedAt = b.age - 1.35, 0),
];

/// Draws the whole encounter layer for [boss] with its captain at [center]
/// and a hit radius of [radius] pixels, clipped to [cell].
void _paintBoss(
  Canvas c,
  Rect cell,
  SkyBoss boss,
  Offset center,
  double radius, {
  bool reduced = false,
  double aim = 0,
  FlightSimulation? sim,
}) {
  final h = radius / SkyBoss.radius;
  final sea = boss.waterLevel ?? SkyBoss.seaLevel;
  boss.y = sea - SkyBoss.shipRide;
  final s = sim ?? arena();
  s.boss = boss;
  s.birdY = boss.y + aim * .3;
  c.save();
  c.clipRect(cell);
  c.translate(center.dx - boss.x * h, center.dy - boss.y * h);
  BossEncounterArt.paint(
    c,
    Size(boss.x * h * 2, h),
    s,
    BossMotion(boss, reducedMotion: reduced),
  );
  c.restore();
}

void _sky(Canvas c, Rect rect) {
  c.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff4f5982), Color(0xff8a86ad), Color(0xffc9a9b8)],
      ).createShader(rect),
  );
}

void _label(Canvas c, String text, Offset at, double size, Color color) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

Future<void> _save(
  String name,
  int w,
  int h,
  void Function(Canvas) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(
    (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
  image.dispose();
  picture.dispose();
}

Future<Uint8List> _pixels(SkyBoss boss, {bool reduced = false}) async {
  final recorder = ui.PictureRecorder();
  const cell = Rect.fromLTWH(0, 0, 400, 360);
  _paintBoss(
    Canvas(recorder),
    cell,
    boss,
    const Offset(220, 170),
    36,
    reduced: reduced,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 360);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

void _sheet(
  Canvas c, {
  required double cellW,
  required double cellH,
  required double radius,
  required double font,
  bool reduced = false,
  Offset anchor = const Offset(.55, .52),
}) {
  const columns = 6;
  final rows = (_poses.length / columns).ceil();
  _sky(c, Rect.fromLTWH(0, 0, cellW * columns, cellH * rows));
  for (var i = 0; i < _poses.length; i++) {
    final (name, setup, aim) = _poses[i];
    final cell = Rect.fromLTWH(
      i % columns * cellW,
      i ~/ columns * cellH,
      cellW,
      cellH,
    );
    final boss = _boss();
    setup(boss);
    _paintBoss(
      c,
      cell,
      boss,
      Offset(cell.left + cellW * anchor.dx, cell.top + cellH * anchor.dy),
      radius,
      aim: aim,
      reduced: reduced,
    );
    c.drawRect(
      cell,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x55000000),
    );
    _label(
      c,
      name,
      Offset(cell.left + 6, cell.top + 4),
      font,
      const Color(0xfffff3da),
    );
  }
}

// ------------------------------------------------------------ in-game --

class _Stage {
  _Stage(this.game, this.sim, this.width);
  final BirdGame game;
  final FlightSimulation sim;
  final double width;
  double birdY = .5;

  void hover(double seconds) {
    for (var i = 0; i < (seconds / .02).round(); i++) {
      final now = (sim.elapsed + .02) * 1000;
      sim.birdY = birdY;
      sim.velocity = 0;
      sim.hearts = 3;
      sim.apply(
        const MovementInput(valid: true),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      sim.tick(.02, now, viewportWidth: width / 360);
    }
  }

  void hoverTo(double age) => hover(age - sim.boss!.age);

  Future<ui.Image> frame() async {
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }
}

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

Future<_Stage> _stage(
  WidgetTester tester,
  double width, {
  bool reduced = false,
}) async {
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..elapsed = FlightSimulation.bossInterval - .001
    ..bossesDefeated = 3;
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await game.loaded;
  game.pauseEngine();
  final stage = _Stage(game, sim, width)..hover(.02);
  expect(sim.boss!.kind, BossKind.pirate);
  return stage;
}

Future<void> _shot(
  _Stage s,
  String name,
  List<(String, ui.Image)> frames,
) async {
  final image = await s.frame();
  final png = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(png);
  frames.add((name, image));
}

Future<void> _contact(String name, List<(String, ui.Image)> frames) async {
  const cols = 4, scale = .5;
  final fw = frames.first.$2.width * scale, fh = 360 * scale;
  final rows = (frames.length / cols).ceil();
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder);
  c.drawRect(
    Rect.fromLTWH(0, 0, fw * cols, (fh + 18) * rows),
    Paint()..color = const Color(0xff101223),
  );
  for (var i = 0; i < frames.length; i++) {
    final (label, image) = frames[i];
    final at = Offset(i % cols * fw, (i ~/ cols) * (fh + 18));
    c.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(at.dx, at.dy + 18, fw - 2, fh - 2),
      Paint()..filterQuality = FilterQuality.medium,
    );
    _label(c, label, at + const Offset(4, 2), 12, const Color(0xffffffff));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (fw * cols).toInt(),
    ((fh + 18) * rows).toInt(),
  );
  File('${_folder.path}/$name.png').writeAsBytesSync(
    (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
  image.dispose();
  picture.dispose();
}

/// Walks the whole encounter through the real game, shooting each beat.
Future<void> _encounter(
  _Stage s,
  String tag,
  List<(String, ui.Image)> frames,
) async {
  for (final (beat, age) in const [
    ('warning', .9),
    ('rolling-in', 1.42),
    ('reveal', 2.05),
    ('roar', 2.95),
    ('title', 3.7),
  ]) {
    s.hoverTo(age);
    await _shot(s, '$tag-arrival-$beat', frames);
  }
  final boss = s.sim.boss!;
  final a = boss.arrivalDuration;
  s.birdY = .42;
  s.hoverTo(a + 1.2);
  await _shot(s, '$tag-fight-calm', frames);
  s.hoverTo(a + 2.35);
  await _shot(s, '$tag-fight-balls', frames);
  // A high lob that has climbed out of view, as when the bird flies high.
  s.sim.bossAmmo.add(
    BossAmmo(
      x: s.sim.boss!.x - .45,
      y: -.12,
      vx: -.5,
      vy: -.1,
      gravity: SkyBoss.cannonGravity,
      radius: BossAmmo.cannonballRadius,
    ),
  );
  s.hover(.02);
  await _shot(s, '$tag-fight-overhead', frames);
  s.hoverTo(a + 3.35);
  await _shot(s, '$tag-tide-warning', frames);
  s.hoverTo(a + 4.1);
  await _shot(s, '$tag-tide-warning-late', frames);
  s.birdY = .38;
  s.hoverTo(a + 4.75);
  await _shot(s, '$tag-tide-rising', frames);
  s.hoverTo(a + 6.1);
  await _shot(s, '$tag-high-tide', frames);
  // A ball about to splash: find the frame where one hits the sea.
  for (var i = 0; i < 200; i++) {
    final before = s.sim.seaSplashes.where((e) => !e.bird).length;
    s.hover(.02);
    if (s.sim.seaSplashes.where((e) => !e.bird).length > before) break;
  }
  s.hover(.12);
  await _shot(s, '$tag-ball-splash', frames);
  // The bird dips into the calm sea.
  s.hoverTo(a + 9.2);
  s.sim.invulnerableUntil = 0;
  s.birdY = .89;
  s.hover(.02);
  s.birdY = .8;
  s.hover(.16);
  await _shot(s, '$tag-bird-splash', frames);
  // Fury: drop to a third and wait for a broadside.
  s.birdY = .45;
  boss.hp = boss.maxHp ~/ 3;
  s.sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y));
  s.hover(.02);
  s.hover(.5);
  await _shot(s, '$tag-fury', frames);
  for (var i = 0; i < 400; i++) {
    s.hover(.02);
    if (s.sim.bossAmmo.length >= 3 && boss.age - boss.lastVolleyAt > .3) break;
  }
  await _shot(s, '$tag-fury-broadside', frames);
  // Hull hit: a shot below the rail glances off.
  s.sim.rocks.add(
    BirdRock(x: boss.x + SkyBoss.hullLeft - .03, y: boss.y + .15),
  );
  s.hover(.06);
  await _shot(s, '$tag-hull-hit', frames);
  // Defeat.
  s.sim.bossAmmo.clear();
  s.sim.rocks.addAll(
    List.generate(boss.hp, (_) => BirdRock(x: boss.x - .07, y: boss.y)),
  );
  s.hover(.02);
  expect(boss.phase, BossPhase.defeated);
  for (final (beat, death) in const [
    ('hit', .12),
    ('overload', .6),
    ('burst', .95),
    ('break', 1.15),
    ('plunge', 1.35),
    ('swallowed', 1.7),
    ('victory', 2.4),
    ('drained', 3.4),
  ]) {
    s.hover(death - (boss.age - boss.defeatedAt!));
    await _shot(s, '$tag-defeat-$beat', frames);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pirate Captain renders deterministically', (tester) async {
    await tester.runAsync(() async {
      for (final (_, setup, _) in _poses) {
        final a = _boss();
        setup(a);
        final b = _boss();
        setup(b);
        expect(await _pixels(a), await _pixels(b));
      }
      final boss = _boss();
      final first = await _pixels(boss);
      boss.age += .37;
      expect(await _pixels(boss), isNot(equals(first)));
      boss.age -= .37;
      expect(await _pixels(boss), first, reason: 'Poses seek exactly');
    });
  });

  testWidgets('the drawn sea surface sits on the rules\' water line', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const size = Size(800, 360);
      for (final (label, t) in [
        ('calm', 1.2),
        ('warning', 3.9),
        ('rising', 4.8),
        ('high tide', 6.0),
        ('falling', 7.9),
      ]) {
        for (final reduced in [false, true]) {
          final boss = _boss(t: t)..x = 1.72;
          final level = boss.waterLevel!;
          boss.y = level - SkyBoss.shipRide;
          final sim = arena()
            ..boss = boss
            ..distance = 37.3
            ..elapsed = 400 + t;
          final m = BossMotion(boss, reducedMotion: reduced);
          final recorder = ui.PictureRecorder();
          final c = Canvas(recorder);
          PirateSeaArt.back(c, size, sim, boss, m);
          PirateSeaArt.front(
            c,
            size,
            sim,
            boss,
            m,
            bowX: boss.x + SkyBoss.hullLeft,
            sternX: boss.x + SkyBoss.hullRight,
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(800, 360);
          final pixels = (await image.toByteData())!.buffer.asUint8List();
          image.dispose();
          picture.dispose();
          // Everywhere the bird can fly (clear of the hull and its wash),
          // the first solid water from the top is within a hundredth of the
          // rules' surface.
          final shipLeft = (boss.x + SkyBoss.hullLeft - .03) * 360;
          for (var x = 0; x < shipLeft; x += 3) {
            var top = 360;
            for (var y = 0; y < 360; y++) {
              if (pixels[(y * 800 + x) * 4 + 3] > 128) {
                top = y;
                break;
              }
            }
            expect(
              (top / 360 - level).abs(),
              lessThan(.0105),
              reason: '$label${reduced ? ' reduced' : ''} at x=$x',
            );
          }
        }
      }
    });
  });

  testWidgets('Reduced Motion is still but keeps every state readable', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final idle = await _pixels(_boss(), reduced: true);
      expect(
        await _pixels(_boss()..age += 1.3, reduced: true),
        idle,
        reason: 'Idle does not animate with Reduced Motion',
      );
      for (final (name, setup, aim) in _poses) {
        if (name.startsWith('IDLE') || aim != 0) continue;
        // The splinters knocked out where a shot struck mark a hull hit;
        // they follow the rebounding shot, which a lone pose has none of.
        if (name == 'HULL HIT') continue;
        final boss = _boss();
        setup(boss);
        expect(
          await _pixels(boss, reduced: true),
          isNot(equals(idle)),
          reason: '$name must stay distinguishable in Reduced Motion',
        );
      }
    });
  });

  testWidgets('renders the Pirate Captain review sheets', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      const columns = 6;
      final rows = (_poses.length / columns).ceil();
      await _save(
        'pose-sheet-large',
        300 * columns,
        300 * rows,
        (c) => _sheet(c, cellW: 300, cellH: 300, radius: 40, font: 15),
      );
      // The captain himself up close, pose by pose.
      await _save(
        'captain-poses',
        260 * columns,
        260 * rows,
        (c) => _sheet(c, cellW: 260, cellH: 260, radius: 82, font: 14),
      );
      // His face alone, expression by expression.
      await _save(
        'captain-faces',
        300 * columns,
        300 * rows,
        (c) => _sheet(
          c,
          cellW: 300,
          cellH: 300,
          radius: 150,
          font: 14,
          anchor: const Offset(.6, .68),
        ),
      );
      // A 360-pt-tall landscape phone: the hit radius is .115 of the height.
      const phoneRadius = 360 * SkyBoss.radius;
      await _save(
        'pose-sheet-phone',
        220 * columns,
        200 * rows,
        (c) => _sheet(
          c,
          cellW: 220,
          cellH: 200,
          radius: phoneRadius * .62,
          font: 10,
        ),
      );
      await _save(
        'pose-sheet-reduced',
        220 * columns,
        200 * rows,
        (c) => _sheet(
          c,
          cellW: 220,
          cellH: 200,
          radius: phoneRadius * .62,
          font: 10,
          reduced: true,
        ),
      );
      await _save('hero', 1600, 900, (c) {
        const rect = Rect.fromLTWH(0, 0, 1600, 900);
        _sky(c, rect);
        _paintBoss(
          c,
          rect,
          _boss(),
          const Offset(900, 430),
          120,
          reduced: true,
        );
      });
      await _save('hero-fury', 1600, 900, (c) {
        const rect = Rect.fromLTWH(0, 0, 1600, 900);
        _sky(c, rect);
        final boss = _boss()
          ..hp = 100
          ..fireIn = .15;
        _paintBoss(c, rect, boss, const Offset(900, 430), 120, reduced: true);
      });
      await _save('captain-closeup', 1000, 800, (c) {
        const rect = Rect.fromLTWH(0, 0, 1000, 800);
        _sky(c, rect);
        _paintBoss(
          c,
          rect,
          _boss(),
          const Offset(560, 420),
          260,
          reduced: true,
        );
      });
      await _save('cannonballs', 1400, 700, _cannonballs);
    });
  });

  for (final width in [640.0, 800.0]) {
    testWidgets('in-game pirate frames at ${width.toInt()}', (tester) async {
      tester.view.physicalSize = ui.Size(width, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await _fonts();
        final s = await _stage(tester, width);
        final frames = <(String, ui.Image)>[];
        await _encounter(s, '${width.toInt()}', frames);
        await _contact('sheet-${width.toInt()}', frames);
        for (final (_, image) in frames) {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('in-game pirate frames with Reduced Motion', (tester) async {
    tester.view.physicalSize = const ui.Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await _fonts();
      final s = await _stage(tester, 640, reduced: true);
      final frames = <(String, ui.Image)>[];
      await _encounter(s, '640-reduced', frames);
      await _contact('sheet-640-reduced', frames);
      for (final (_, image) in frames) {
        image.dispose();
      }
    });
    await tester.pumpWidget(const SizedBox());
  });
}

void _cannonballs(Canvas c) {
  c.drawRect(
    const Rect.fromLTWH(0, 0, 1400, 700),
    Paint()..color = const Color(0xfff2eedf),
  );
  const skies = [
    (Color(0xff8dd8eb), Color(0xffe9f5df)),
    (Color(0xffaaa9e0), Color(0xffffdfc3)),
    (Color(0xff485584), Color(0xffadb6da)),
    (Color(0xff1f2446), Color(0xff4a4f7a)),
  ];
  for (var row = 0; row < 2; row++) {
    final enraged = row == 1;
    for (var col = 0; col < 4; col++) {
      final cell = Rect.fromLTWH(20 + col * 345.0, 20 + row * 340.0, 335, 330);
      final (top, bottom) = skies[col];
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(cell, const Radius.circular(14)));
      c.drawRect(
        cell,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(cell),
      );
      // Close-up on a falling arc, then gameplay-size balls along an arc.
      BossAmmoArt.paint(
        c,
        center: cell.topLeft + const Offset(110, 110),
        radius: 42,
        direction: math.pi - .9,
        attack: EnemyAttack.none,
        kind: BossKind.pirate,
        enraged: enraged,
        speed: .8,
        seconds: 1.3,
        reducedMotion: false,
      );
      for (var i = 0; i < 5; i++) {
        final t = i / 4;
        final at =
            cell.topLeft +
            Offset(300 - t * 250, 300 - math.sin(t * math.pi) * 120);
        final heading = math.atan2(-math.cos(t * math.pi) * 1.4, -1);
        BossAmmoArt.paint(
          c,
          center: at,
          radius: 360 * BossAmmo.cannonballRadius,
          direction: heading,
          attack: EnemyAttack.none,
          kind: BossKind.pirate,
          enraged: enraged,
          speed: .9,
          seconds: 1.3 + i * .2,
          reducedMotion: false,
        );
      }
      c.restore();
    }
  }
}
