import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/boss_rig.dart';
import 'package:push_up_bird/game/enemy_designs/simple_bat.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

/// Visual review for the Baron Bat boss rig (BossKind.baronBat).
///
/// Writes PNGs to build/visual-review/boss-polish/baron-bat/ and checks the
/// layer budget, determinism and Reduced Motion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final folder = Directory('build/visual-review/boss-polish/baron-bat');
  const night = Color(0xff171c39);

  Future<Uint8List> raster(
    void Function(Canvas) draw, {
    required int width,
    required int height,
    String? name,
  }) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final pixels = (await image.toByteData())!.buffer.asUint8List();
    if (name != null) {
      folder.createSync(recursive: true);
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      File('${folder.path}/$name.png').writeAsBytesSync(png);
    }
    image.dispose();
    picture.dispose();
    return pixels;
  }

  // Poses built from real encounter state, not faked motion values.
  SkyBoss attacking(double age, {bool enraged = false}) {
    final boss = SkyBoss(number: 1, x: 1.6, cinematic: true)
      ..age = age
      ..fireIn = 2;
    if (enraged) {
      boss.hp = boss.maxHp ~/ 2 - 1;
      boss.enragedAt = age - 3;
    }
    return boss;
  }

  final poses = <(String, SkyBoss, double)>[
    for (final t in [5.0, 5.12, 5.24, 5.36]) ('idle $t', attacking(t), 0.0),
    ('charging', attacking(5.0)..fireIn = .08, 0.0),
    ('volley', attacking(5.0)..lastVolleyAt = 5.0 - .16, 0.0),
    ('hit', attacking(5.0)..lastHitAt = 5.0 - .12, 0.0),
    ('enraged', attacking(5.0, enraged: true), 0.0),
    ('fury charge', attacking(5.1, enraged: true)..fireIn = .1, 0.0),
    ('fury onset', attacking(5.0, enraged: true)..enragedAt = 4.6, 0.0),
    ('blink', attacking(7.48), 0.0),
    ('look up', attacking(5.0), -1.0),
    ('look down', attacking(5.0), 1.0),
    ('folded 1.2', SkyBoss(number: 1, x: 1.6, cinematic: true)..age = 1.2, 0.0),
    ('unfold 2.0', SkyBoss(number: 1, x: 1.6, cinematic: true)..age = 2.0, 0.0),
    ('roar 3.0', SkyBoss(number: 1, x: 1.6, cinematic: true)..age = 3.0, 0.0),
    ('defeat .15', attacking(8.15, enraged: true)..defeatedAt = 8.0, 0.0),
    ('defeat .5', attacking(8.5, enraged: true)..defeatedAt = 8.0, 0.0),
    ('defeat .85', attacking(8.85, enraged: true)..defeatedAt = 8.0, 0.0),
  ];

  // Mirrors BossEncounterArt.paint's body transform and silhouette layer.
  void drawBoss(
    Canvas c,
    SkyBoss boss,
    double scale, {
    bool reduced = false,
    double lookY = 0,
    bool transform = true,
  }) {
    final m = BossMotion(boss, reducedMotion: reduced);
    if (m.opacity <= 0) return;
    c.save();
    if (transform) {
      c.translate(m.offset.dx * scale / .115, m.offset.dy * scale / .115);
      c.rotate(m.rotation);
      final s = scale * m.bodyScale;
      c.scale(s * (1 + m.stretch), s * (1 - m.stretch));
    } else {
      c.scale(scale);
    }
    final layer = Paint()
      ..color = const Color(0xffffffff).withValues(alpha: m.opacity);
    if (transform && m.silhouette > .01) {
      layer.colorFilter = ColorFilter.mode(
        night.withValues(alpha: m.silhouette * .97),
        BlendMode.srcATop,
      );
    }
    c.saveLayer(const Rect.fromLTWH(-3, -2.3, 6, 4), layer);
    BossRig.paint(c, boss, m, lookY: lookY);
    c.restore();
    c.restore();
  }

  // Painted bounds in rig units (hit radius), without the body transform.
  const r = 60.0, boxW = 480, boxH = 330;
  Future<Rect> bounds(SkyBoss boss, {bool reduced = false}) async {
    final pixels = await raster(
      (c) {
        c.translate(boxW / 2, 150);
        drawBoss(c, boss, r, reduced: reduced, transform: false);
      },
      width: boxW,
      height: boxH,
    );
    var left = boxW, top = boxH, right = -1, bottom = -1;
    for (var y = 0; y < boxH; y++) {
      for (var x = 0; x < boxW; x++) {
        if (pixels[(y * boxW + x) * 4 + 3] > 8) {
          left = math.min(left, x);
          right = math.max(right, x + 1);
          top = math.min(top, y);
          bottom = math.max(bottom, y + 1);
        }
      }
    }
    return Rect.fromLTRB(
      (left - boxW / 2) / r,
      (top - 150) / r,
      (right - boxW / 2) / r,
      (bottom - 150) / r,
    );
  }

  test('baron bat stays inside the encounter layer in every pose', () async {
    final report = StringBuffer();
    var union = Rect.zero;
    String fmt(Rect b) =>
        'L ${b.left.toStringAsFixed(2)} T ${b.top.toStringAsFixed(2)} '
        'R ${b.right.toStringAsFixed(2)} B ${b.bottom.toStringAsFixed(2)}';
    for (final (label, boss, _) in poses) {
      final box = await bounds(boss);
      report.writeln('$label: ${fmt(box)}');
      union = union == Rect.zero ? box : union.expandToInclude(box);
    }
    for (var f = 0; f < 60; f++) {
      final box = await bounds(attacking(5 + f / 40, enraged: f.isOdd));
      union = union.expandToInclude(box);
    }
    report.writeln('union: ${fmt(union)}');
    folder.createSync(recursive: true);
    File('${folder.path}/bounds.txt').writeAsStringSync(report.toString());
    // The encounter saveLayer is Rect.fromLTWH(-3, -2.3, 6, 4).
    expect(union.left, greaterThan(-3), reason: '$report');
    expect(union.right, lessThan(3), reason: '$report');
    expect(union.top, greaterThan(-2.3), reason: '$report');
    expect(union.bottom, lessThan(1.7), reason: '$report');
  });

  test('baron bat is deterministic and honours Reduced Motion', () async {
    Future<Uint8List> pose(
      SkyBoss boss, {
      bool reduced = false,
      double lookY = 0,
    }) => raster(
      (c) {
        c.translate(150, 120);
        drawBoss(c, boss, 40, reduced: reduced, lookY: lookY);
      },
      width: 300,
      height: 220,
    );
    expect(
      await pose(attacking(5.37)),
      await pose(attacking(5.37)),
      reason: 'a paused frame repaints exactly',
    );
    expect(
      await pose(attacking(5.1)),
      isNot(equals(await pose(attacking(5.3)))),
      reason: 'wings beat',
    );
    expect(
      await pose(attacking(5.1), reduced: true),
      await pose(attacking(7.9), reduced: true),
      reason: 'Reduced Motion holds one idle pose',
    );
    expect(
      await pose(attacking(5.0)..lastHitAt = 4.9, reduced: true),
      isNot(equals(await pose(attacking(5.0), reduced: true))),
      reason: 'a hit still reads under Reduced Motion, without motion',
    );
    expect(
      await pose(attacking(5.0), reduced: true, lookY: -1),
      isNot(equals(await pose(attacking(5.0), reduced: true, lookY: 1))),
      reason: 'eyes follow the bird',
    );
    expect(
      await pose(attacking(5.0, enraged: true), reduced: true),
      isNot(equals(await pose(attacking(5.0), reduced: true))),
      reason: 'fury reads without motion',
    );
  });

  test('baron bat review sheets', () async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
    // Large pose sheet on a neutral card, then on a night sky.
    for (final (label, dark) in [
      ('pose-sheet', false),
      ('pose-sheet-night', true),
    ]) {
      const cols = 6, cellW = 330.0, cellH = 330.0;
      final rows = (poses.length / cols).ceil();
      await raster(
        (c) {
          c.drawPaint(Paint()..color = dark ? night : const Color(0xfff2eedf));
          for (var i = 0; i < poses.length; i++) {
            final (name, boss, look) = poses[i];
            final cx = cellW * (i % cols) + cellW / 2;
            final cy = cellH * (i ~/ cols) + 185;
            final tp = TextPainter(
              text: TextSpan(
                text: name,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: dark ? Colors.white70 : Colors.black54,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(c, Offset(cx - cellW / 2 + 8, cy - 180));
            c.save();
            c.translate(cx, cy);
            drawBoss(c, boss, 62, lookY: look);
            c.restore();
          }
        },
        width: (cols * cellW).toInt(),
        height: (rows * cellH).toInt(),
        name: label,
      );
    }

    // Hero close-up: idle and fury side by side.
    await raster(
      (c) {
        c.drawPaint(Paint()..color = const Color(0xfff2eedf));
        c.translate(300, 300);
        drawBoss(c, attacking(5.0), 120, transform: false);
        c.translate(600, 0);
        drawBoss(c, attacking(5.0, enraged: true), 120, transform: false);
      },
      width: 1200,
      height: 560,
      name: 'hero',
    );

    // Phone size (radius .115 x 360 px) across all skies, next to the small
    // bat it should read as the grander relative of.
    for (final (sky, elapsed) in [
      ('daylight', 5.0),
      ('dusk', 21.0),
      ('night', 45.0),
    ]) {
      await raster(
        (c) {
          SkyScenery.paint(c, const Size(1500, 180), seconds: elapsed);
          final phone = .115 * 360;
          const picks = [0, 4, 6, 7, 12, 14, 16];
          for (var i = 0; i < picks.length; i++) {
            final (_, boss, look) = poses[picks[i]];
            c.save();
            c.translate(110 + i * 195.0, 95);
            drawBoss(c, boss, phone, lookY: look);
            c.restore();
          }
          c.save();
          c.translate(1440, 60);
          SimpleBatArt.paint(c, 16, seconds: 1.6, reducedMotion: false);
          c.restore();
        },
        width: 1500,
        height: 180,
        name: 'phone-$sky',
      );
    }

    // A wingbeat strip at phone size, 12 frames across one enraged beat too.
    await raster(
      (c) {
        c.drawPaint(Paint()..color = const Color(0xff8fa3cf));
        for (var i = 0; i < 12; i++) {
          c.save();
          c.translate(110 + i * 200.0, 70);
          drawBoss(c, attacking(5 + i * (2 * math.pi / 7) / 12), 41.4);
          c.restore();
          c.save();
          c.translate(110 + i * 200.0, 190);
          drawBoss(
            c,
            attacking(5 + i * (2 * math.pi / 10) / 12, enraged: true),
            41.4,
          );
          c.restore();
        }
      },
      width: 2400,
      height: 260,
      name: 'wingbeat-strip',
    );
  });

  for (final (label, elapsed, enraged, fireIn) in [
    ('dusk', 21.0, false, 2.0),
    ('day-charging', 5.0, false, .1),
    ('night-fury', 45.0, true, 2.0),
  ]) {
    testWidgets('baron bat in the actual game: $label', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..phase = RunPhase.playing
        ..elapsed = elapsed
        ..birdY = .4;
      sim.boss = attacking(6.2, enraged: enraged)
        ..fireIn = fireIn
        ..x = 1.72
        ..y = .47;
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
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(800, 360);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        folder.createSync(recursive: true);
        File('${folder.path}/in-game-$label.png').writeAsBytesSync(bytes);
        expect(bytes.length, greaterThan(2000));
        image.dispose();
        picture.dispose();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
