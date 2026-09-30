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
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_fireball_art.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

import 'boss_fight_test.dart' show arena;

/// Visual review for the Ember Dragon: a labelled pose sheet at close-up and
/// real phone scale, in-game frames through the real renderer at 640×360
/// and 800×360 (the breath in every lane with its safe band, fury and the
/// ember split included), fireball and health bar close-ups, plus
/// determinism and Reduced Motion checks.
final _folder = Directory('build/visual-review/boss-polish/ember-dragon');

/// A dragon [t] seconds into the fight (negative: into the arrival).
SkyBoss _boss({double t = 1.2, BreathLane lane = BreathLane.middle}) {
  final boss = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = lane;
  boss.age = boss.arrivalDuration + t;
  return boss;
}

typedef _Pose = (String, void Function(SkyBoss), double);

void _at(SkyBoss b, double t) => b.age = b.arrivalDuration + t;

/// The pose sheet, in the order of a fight: idle, the fireball, the breath
/// beat by beat (alert 3.4, warning/rear 4.6, hold 4.95..5.20, snap 5.20..5.28,
/// lunge and thump after it, the three lanes, the gutter), the swarm call
/// (wind 7.3, roar 7.6), fury, the arrival and the defeat. Times are combat
/// seconds into the 11 s breath cycle (see DragonTimeline).
final _poses = <_Pose>[
  ('IDLE · A', (b) {}, 0),
  ('IDLE · B', (b) => b.age += .37, 0),
  ('IDLE · C', (b) => b.age += .81, 0),
  ('CHARGING', (b) => b.fireIn = .12, 0),
  ('RECOIL', (b) => b.lastVolleyAt = b.age - .12, 0),
  ('ALERT', (b) => _at(b, 3.7), 0),
  // REAR: 4.6 s, the head drawn back and up, the jaws parting.
  ('BREATH WARNING', (b) => _at(b, DragonBreath.warnAt + .6), 0),
  ('REAR · LATE', (b) => _at(b, 4.9), 0),
  // HOLD: 4.95..5.20, frozen at full tension.
  ('HOLD', (b) => _at(b, 5.05), 0),
  // SNAP: 5.20..5.28, the head driven at the band.
  ('SNAP', (b) => _at(b, 5.24), 0),
  ('SNAP · OVERSHOOT', (b) => _at(b, 5.33), 0),
  // The lunge and thump after the snap (this pose was 'INHALE · LATE' when the
  // inhale ran to 5.4: it now shows the body recoiling from the strike).
  ('BREATH · LUNGE', (b) => _at(b, DragonBreath.blastAt - .1), 0),
  (
    'BREATH · HIGH',
    (b) {
      b.breathLane = BreathLane.high;
      _at(b, DragonBreath.blastAt + .6);
    },
    0,
  ),
  ('BREATH · MIDDLE', (b) => _at(b, DragonBreath.blastAt + .6), 0),
  (
    'BREATH · LOW',
    (b) {
      b.breathLane = BreathLane.low;
      _at(b, DragonBreath.blastAt + .6);
    },
    0,
  ),
  ('GUTTER', (b) => _at(b, 7.3), 0),
  // CALL WIND: 7.3..7.6 the intake; SWARM CALL: the roar from 7.6.
  ('CALL WIND', (b) => _at(b, 7.45), 0),
  ('SWARM CALL', (b) => _at(b, 7.95), 0),
  ('HIT FLASH', (b) => b.lastHitAt = b.age - .1, 0),
  (
    'HEART HIT',
    (b) {
      _at(b, DragonBreath.warnAt + .8);
      b.lastHitAt = b.lastCoreHitAt = b.age - .1;
    },
    0,
  ),
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
  // FURY CALL: the second, smaller call a fury dragon adds at 9.0 s.
  (
    'FURY · CALL',
    (b) {
      b.hp = b.maxHp ~/ 3;
      _at(b, 9.25);
    },
    0,
  ),
  (
    'FURY · HOLD',
    (b) {
      b.hp = b.maxHp ~/ 3;
      _at(b, 5.05);
    },
    0,
  ),
  (
    'FURY · BLAST',
    (b) {
      b.hp = b.maxHp ~/ 3;
      _at(b, DragonBreath.blastAt + .6);
    },
    0,
  ),
  ('ARRIVAL · SILHOUETTE', (b) => b.age = 1.5, 0),
  ('ARRIVAL · WINGS', (b) => b.age = 2.2, 0),
  // (the intake at 2.35..2.65 is motion, so it has no Reduced Motion frame)
  ('ARRIVAL · REVEAL', (b) => b.age = 1.9, 0),
  ('ARRIVAL · ROAR', (b) => b.age = SkyBoss.roarAt + .3, 0),
  ('LOOK UP', (b) {}, -1),
  ('LOOK DOWN', (b) {}, 1),
  ('DEFEAT · HIT', (b) => b.defeatedAt = b.age - .15, 0),
  ('DEFEAT · OVERLOAD', (b) => b.defeatedAt = b.age - .7, 0),
  ('DEFEAT · BURST', (b) => b.defeatedAt = b.age - 1.0, 0),
  ('DEFEAT · SCATTER', (b) => b.defeatedAt = b.age - 1.4, 0),
];

/// Draws the whole encounter layer for [boss] with its heart at [center]
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
  boss.y = .5;
  final s = sim ?? arena();
  s.boss = boss;
  s.birdY = boss.y - .22 + aim * .3;
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

/// The bare rig for [boss] (no breath, bats or effects) with its heart at
/// [center] and a hit radius of [radius] pixels.
void _rig(
  Canvas c,
  SkyBoss boss,
  Offset center,
  double radius, {
  double aim = 0,
  bool reduced = false,
}) {
  c.save();
  c.translate(center.dx, center.dy);
  c.scale(radius);
  DragonBossRig.paintPose(
    c,
    DragonPose(boss, BossMotion(boss, reducedMotion: reduced), lookY: aim),
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
  const cell = Rect.fromLTWH(0, 0, 420, 360);
  _paintBoss(
    Canvas(recorder),
    cell,
    boss,
    const Offset(250, 210),
    30,
    reduced: reduced,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(420, 360);
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
      Offset(cell.left + cellW * .5, cell.top + cellH * .66),
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

  /// Hovers to combat time [t] of the current breath cycle [cycle].
  void fightTo(int cycle, double t) =>
      hoverTo(sim.boss!.arrivalDuration + cycle * DragonBreath.period + t);

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

/// The second dragon of a flight (encounter 10), which brings the whole
/// fight; its debut only ever burns one half of the sky.
Future<_Stage> _stage(
  WidgetTester tester,
  double width, {
  bool reduced = false,
  int defeated = 9,
}) async {
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..elapsed = FlightSimulation.bossInterval - .001
    ..bossesDefeated = defeated;
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
  expect(sim.boss!.kind, BossKind.dragon);
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
    ('silhouette', 1.5),
    ('wings', 2.2),
    ('roar', 2.95),
    ('title', 3.7),
  ]) {
    s.hoverTo(age);
    await _shot(s, '$tag-arrival-$beat', frames);
  }
  final boss = s.sim.boss!;
  s.birdY = .5;
  s.fightTo(0, 1.05);
  await _shot(s, '$tag-fight-charging', frames);
  s.fightTo(0, 1.6);
  await _shot(s, '$tag-fight-fireball', frames);
  s.fightTo(0, 3.6);
  await _shot(s, '$tag-fight-pair', frames);
  // Breath 1 aims at the middle (the bird sits mid-sky as it inhales).
  s.fightTo(0, DragonBreath.warnAt + .5);
  await _shot(s, '$tag-breath-middle-warning', frames);
  s.birdY = .8;
  // The held breath and the strike, before the jet leaves the jaws.
  s.fightTo(0, 5.05);
  await _shot(s, '$tag-breath-middle-hold', frames);
  s.fightTo(0, 5.24);
  await _shot(s, '$tag-breath-middle-snap', frames);
  s.fightTo(0, DragonBreath.blastAt - .1);
  await _shot(s, '$tag-breath-middle-late', frames);
  s.fightTo(0, DragonBreath.blastAt + .02);
  await _shot(s, '$tag-breath-middle-ignite', frames);
  s.fightTo(0, DragonBreath.blastAt + .7);
  await _shot(s, '$tag-breath-middle-blast', frames);
  s.fightTo(0, DragonBreath.endAt + .15);
  await _shot(s, '$tag-breath-middle-end', frames);
  // The dragon calls the swarm as the flame gutters out (rules 39).
  s.fightTo(0, 7.45);
  await _shot(s, '$tag-call-wind', frames);
  s.fightTo(0, 7.95);
  await _shot(s, '$tag-swarm-call', frames);
  // Breath 2: the bird is high, so the top burns.
  s.birdY = .2;
  s.fightTo(1, DragonBreath.warnAt + .6);
  await _shot(s, '$tag-breath-high-warning', frames);
  s.birdY = .72;
  s.fightTo(1, DragonBreath.blastAt + .7);
  await _shot(s, '$tag-breath-high-blast', frames);
  // Breath 3: the bird is low; a hit on the open heart doubles.
  s.birdY = .8;
  s.fightTo(2, DragonBreath.warnAt + .6);
  await _shot(s, '$tag-breath-low-warning', frames);
  s.birdY = .38;
  s.fightTo(2, DragonBreath.blastAt + .5);
  s.sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));
  s.hover(.06);
  await _shot(s, '$tag-breath-low-heart-hit', frames);
  // Fury: drop to a third and wait for a splitting fireball, then its
  // embers.
  s.birdY = .5;
  s.fightTo(3, .2);
  boss.hp = boss.maxHp ~/ 2 + 5;
  s.sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));
  s.hover(.3);
  expect(boss.enraged, isTrue);
  await _shot(s, '$tag-fury', frames);
  for (var i = 0; i < 300; i++) {
    s.hover(.02);
    if (s.sim.bossAmmo.any((a) => a.splitAfter != null && a.age > .3)) break;
  }
  await _shot(s, '$tag-fury-splitting', frames);
  for (var i = 0; i < 100; i++) {
    s.hover(.02);
    if (s.sim.bossAmmo.any((a) => a.ember)) break;
  }
  s.hover(.12);
  await _shot(s, '$tag-fury-embers', frames);
  s.birdY = .25;
  s.fightTo(4, DragonBreath.warnAt + .7);
  await _shot(s, '$tag-fury-breath-warning', frames);
  s.birdY = .8;
  s.fightTo(4, DragonBreath.blastAt + .8);
  await _shot(s, '$tag-fury-breath', frames);
  // Defeat.
  s.sim.bossAmmo.clear();
  s.sim.rocks.addAll(
    List.generate(boss.hp, (_) => BirdRock(x: boss.x - .12, y: boss.y)),
  );
  s.hover(.02);
  expect(boss.phase, BossPhase.defeated);
  for (final (beat, death) in const [
    ('hit', .12),
    ('overload', .6),
    ('burst', .95),
    ('scatter', 1.25),
    ('victory', 2.4),
  ]) {
    s.hover(death - (boss.age - boss.defeatedAt!));
    await _shot(s, '$tag-defeat-$beat', frames);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ember Dragon renders deterministically', (tester) async {
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

  test('the jaws open where the rules launch fireballs', () {
    for (final reduced in [false, true]) {
      final boss = _boss()..fireIn = .01;
      final pose = DragonPose(boss, BossMotion(boss, reducedMotion: reduced));
      final mouth = DragonBossRig.mouthAt(pose) * SkyBoss.radius;
      expect(mouth.dx, closeTo(SkyBoss.dragonMouth.$1, .012));
      expect(mouth.dy, closeTo(SkyBoss.dragonMouth.$2, .012));
    }
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
        // The shot's recoil is motion; its flash ring is what remains.
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

  testWidgets('renders the Ember Dragon review sheets', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      const columns = 6;
      final rows = (_poses.length / columns).ceil();
      await _save(
        'pose-sheet-large',
        380 * columns,
        380 * rows,
        (c) => _sheet(c, cellW: 380, cellH: 380, radius: 40, font: 15),
      );
      // A 360-pt-tall landscape phone: the hit radius is .115 of the height.
      const phoneRadius = 360 * SkyBoss.radius;
      await _save(
        'pose-sheet-phone',
        300 * columns,
        300 * rows,
        (c) => _sheet(
          c,
          cellW: 300,
          cellH: 300,
          radius: phoneRadius * .7,
          font: 11,
        ),
      );
      await _save(
        'pose-sheet-reduced',
        300 * columns,
        300 * rows,
        (c) => _sheet(
          c,
          cellW: 300,
          cellH: 300,
          radius: phoneRadius * .7,
          font: 11,
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
          const Offset(860, 520),
          100,
          reduced: true,
        );
      });
      await _save('hero-fury', 1600, 900, (c) {
        const rect = Rect.fromLTWH(0, 0, 1600, 900);
        _sky(c, rect);
        final boss = _boss()
          ..hp = 100
          ..fireIn = .15;
        _paintBoss(c, rect, boss, const Offset(860, 520), 100, reduced: true);
      });
      await _save('head-closeup', 1000, 800, (c) {
        const rect = Rect.fromLTWH(0, 0, 1000, 800);
        _sky(c, rect);
        _paintBoss(
          c,
          rect,
          _boss(),
          const Offset(878, 757),
          210,
          reduced: true,
        );
      });
      await _save('fireballs', 1400, 700, _fireballs);
      await _save('health-bars', 820, 520, _healthBars);
    });
  });

  testWidgets('renders the Ember Dragon joint close-ups', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      // Each joint of the rest pose at 3× hero size, where a seam, a gap or
      // a stray outline between two parts would show.
      for (final (name, focus) in const [
        ('joints-head-neck', Offset(-.85, -2.0)),
        ('joints-neck-chest', Offset(-.35, -.75)),
        ('joints-hips-tail', Offset(1.75, .55)),
        ('joints-wing-root', Offset(1.0, -.75)),
        ('joints-foreleg', Offset(-.55, .55)),
      ]) {
        await _save(name, 900, 900, (c) {
          const rect = Rect.fromLTWH(0, 0, 900, 900);
          _sky(c, rect);
          _rig(c, _boss(), const Offset(450, 450) - focus * 300, 300);
        });
      }
      // The head and neck through every pose that moves them: the neck
      // must follow the head at any angle and gape with no seam or gap.
      const cols = 5, cw = 420.0, ch = 400.0;
      final rows = (_poses.length / cols).ceil();
      await _save(
        'joints-neck-poses',
        (cols * cw).toInt(),
        (rows * ch).toInt(),
        (c) {
          _sky(c, Rect.fromLTWH(0, 0, cols * cw, rows * ch));
          for (var i = 0; i < _poses.length; i++) {
            final (name, setup, aim) = _poses[i];
            final cell = Rect.fromLTWH(i % cols * cw, i ~/ cols * ch, cw, ch);
            final boss = _boss();
            setup(boss);
            c.save();
            c.clipRect(cell);
            _rig(c, boss, cell.topLeft + const Offset(300, 330), 115, aim: aim);
            c.restore();
            c.drawRect(
              cell,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0x55000000),
            );
            _label(
              c,
              name,
              cell.topLeft + const Offset(6, 4),
              14,
              const Color(0xfffff3da),
            );
          }
        },
      );
    });
  });

  for (final width in [640.0, 800.0]) {
    testWidgets('in-game dragon frames at ${width.toInt()}', (tester) async {
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

  testWidgets('in-game dragon frames with Reduced Motion', (tester) async {
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

void _fireballs(Canvas c) {
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
    final fury = row == 1;
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
      // Close-up: plain, splitting (fury row), then gameplay-size shots:
      // fireballs, a splitting one, and embers.
      DragonFireballArt.paint(
        c,
        center: cell.topLeft + const Offset(220, 95),
        radius: 40,
        direction: math.pi + .15,
        seconds: 1.3,
        reducedMotion: false,
        fury: fury,
        split: fury ? .75 : null,
      );
      for (var i = 0; i < 4; i++) {
        DragonFireballArt.paint(
          c,
          center: cell.topLeft + Offset(290 - i * 70.0, 215 + i * 8.0),
          radius: 360 * BossAmmo.fireballRadius,
          direction: math.pi + .1,
          seconds: 1.3 + i * .2,
          reducedMotion: false,
          fury: fury,
          split: fury && i == 3 ? .9 : null,
        );
      }
      for (var i = 0; i < 3; i++) {
        DragonFireballArt.paint(
          c,
          center: cell.topLeft + Offset(250 - i * 80.0, 290 + (i - 1) * 16.0),
          radius: 360 * BossAmmo.emberRadius,
          direction: math.pi + (i - 1) * .5,
          seconds: 1.3 + i * .3,
          reducedMotion: false,
          fury: fury,
          ember: true,
        );
      }
      c.restore();
    }
  }
}

void _healthBars(Canvas c) {
  c.drawRect(
    const Rect.fromLTWH(0, 0, 820, 520),
    Paint()..color = const Color(0xff8fd0e6),
  );
  final states = <(String, SkyBoss)>[
    ('full', _boss()),
    (
      'hit',
      _boss()
        ..hp = 330
        ..lastDamage = 30
        ..lastHitAt = _boss().age - .15,
    ),
    ('breath · heart open', _boss(t: DragonBreath.warnAt + .5)..hp = 250),
    (
      'fury onset',
      _boss()
        ..hp = 170
        ..enragedAt = _boss().age - .4,
    ),
    ('fury', _boss()..hp = 120),
    ('critical', _boss()..hp = 40),
    (
      'defeated',
      _boss()
        ..hp = 0
        ..defeatedAt = _boss().age - .4,
    ),
  ];
  for (var i = 0; i < states.length; i++) {
    final (label, boss) = states[i];
    c.save();
    c.translate(0, i * 72.0);
    c.clipRect(const Rect.fromLTWH(0, 0, 820, 70));
    BossHealthBarArt.paint(c, const Size(800, 360), boss);
    c.restore();
    _label(c, label, Offset(6, i * 72.0 + 44), 12, const Color(0xff1c1224));
  }
}
