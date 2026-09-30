import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/enemy_designs/aimed_enemy.dart';
import 'package:push_up_bird/game/spitter_boss_rig.dart';

SkyBoss _boss() =>
    SkyBoss(number: 2, x: 1.5, kind: BossKind.spitterBeetle, cinematic: true)
      ..age = 5;

Future<Uint8List> _pixels(
  SkyBoss boss, {
  bool reduced = false,
  double aim = 0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..translate(180, 200)
    ..scale(90.0);
  SpitterBossRig.paint(
    canvas,
    boss,
    BossMotion(boss, reducedMotion: reduced),
    lookY: aim,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 360);
  final result = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return result;
}

int _changedIn(Uint8List a, Uint8List b, Rect region) {
  var changed = 0;
  for (
    var y = (200 + region.top * 90).floor();
    y < 200 + region.bottom * 90;
    y++
  ) {
    for (
      var x = (180 + region.left * 90).floor();
      x < 180 + region.right * 90;
      x++
    ) {
      final i = (y * 400 + x) * 4;
      if (a[i] != b[i] ||
          a[i + 1] != b[i + 1] ||
          a[i + 2] != b[i + 2] ||
          a[i + 3] != b[i + 3]) {
        changed++;
      }
    }
  }
  return changed;
}

void main() {
  testWidgets(
    'brewer animation seeks exactly and Reduced Motion holds its pose',
    (tester) async {
      await tester.runAsync(() async {
        final boss = _boss();
        final first = await _pixels(boss);
        boss.age = 5.2;
        expect(await _pixels(boss), isNot(equals(first)));
        boss.age = 5;
        expect(
          await _pixels(boss),
          first,
          reason: 'Backward seeks reproduce wings, liquid and secondary motion',
        );
        final quiet = await _pixels(boss, reduced: true);
        boss.age = 8.1;
        expect(await _pixels(boss, reduced: true), quiet);
        boss.fireIn = .12;
        expect(
          await _pixels(boss, reduced: true),
          isNot(equals(quiet)),
          reason: 'Pressure and the swollen jowl still telegraph the volley',
        );
        boss.fireIn = 1;
        boss.hp = 9;
        final fury = await _pixels(boss, reduced: true);
        expect(
          fury,
          isNot(equals(quiet)),
          reason: 'Amber acid and glowing cracks retain fury readability',
        );
        boss.age = 8.5;
        expect(
          await _pixels(boss, reduced: true),
          fury,
          reason:
              'Fury has no idle bubbling or wing animation in Reduced Motion',
        );
      });
    },
  );

  testWidgets(
    'charge, recoil, summon and defeat articulate the relevant anatomy',
    (tester) async {
      await tester.runAsync(() async {
        final boss = _boss();
        final idle = await _pixels(boss);
        boss.fireIn = .05;
        final charged = await _pixels(boss);
        expect(
          _changedIn(idle, charged, const Rect.fromLTRB(-.9, .05, -.02, .65)),
          greaterThan(500),
          reason: 'The jowl sac inflates before the spit',
        );
        expect(
          _changedIn(idle, charged, const Rect.fromLTRB(.3, -.95, 1.8, 1.25)),
          greaterThan(500),
          reason: 'Vat pressure, valve and liquid show the windup',
        );
        boss.fireIn = 1;
        boss.lastVolleyAt = 4.83;
        final recoil = await _pixels(boss);
        expect(
          _changedIn(idle, recoil, const Rect.fromLTRB(-1.2, -1.75, .25, -.55)),
          greaterThan(500),
          reason: 'The crown follows through after each spit',
        );
        expect(
          _changedIn(idle, recoil, const Rect.fromLTRB(.3, -.95, 1.8, 1.25)),
          greaterThan(500),
          reason: 'Recoil rocks the vat and sloshes acid',
        );
        boss.lastVolleyAt = double.negativeInfinity;
        boss.lastSummonAt = 4.65;
        expect(
          _changedIn(
            idle,
            await _pixels(boss),
            const Rect.fromLTRB(-1.7, -.95, -1.1, .3),
          ),
          greaterThan(300),
          reason: 'A raised beckoning claw calls the swarm',
        );
        boss.lastSummonAt = double.negativeInfinity;
        boss.defeatedAt = 4.4;
        final defeated = await _pixels(boss);
        expect(
          _changedIn(
            idle,
            defeated,
            const Rect.fromLTRB(-1.2, -1.75, .25, -.55),
          ),
          greaterThan(500),
          reason: 'The crown leaves the rig for the encounter debris animation',
        );
        expect(
          _changedIn(idle, defeated, const Rect.fromLTRB(-.6, .5, .9, 1.3)),
          greaterThan(500),
          reason: 'Legs curl up on defeat',
        );
      });
    },
  );

  testWidgets('tracking and recoil preserve the fixed spit port', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final boss = _boss();
      final idle = await _pixels(boss);
      boss.lastVolleyAt = 4.83;
      final recoiling = await _pixels(boss, aim: 1);
      const muzzle = Rect.fromLTRB(-1.065, -.018, -1.025, .018);
      expect(
        _changedIn(idle, recoiling, muzzle),
        0,
        reason:
            'The projectile origin remains inside the same dark mouth opening',
      );
      expect(
        _changedIn(idle, recoiling, const Rect.fromLTRB(-1, -.6, -.35, -.1)),
        greaterThan(100),
        reason: 'Eye tracking remains visible independently of the muzzle',
      );
    });
  });

  testWidgets('renders the brewer pose sheet and gameplay-scale comparison', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('CAPTURE_SPITTER_ART')) return;
    await tester.runAsync(() async {
      await (FontLoader(
        'Fredoka',
      )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
      final states = <(String, void Function(SkyBoss))>[
        ('ARRIVAL · WINGS FOLDED', (b) => b.age = 1.5),
        ('ENTRANCE · CROWN LIFT', (b) => b.age = 2.9),
        ('HOVER · WINGS BEATING', (b) {}),
        ('WINDUP · PRESSURE RISES', (b) => b.fireIn = .05),
        ('SPIT · RECOIL & SLOSH', (b) => b.lastVolleyAt = 4.83),
        ('SUMMON · BECKONING CLAW', (b) => b.lastSummonAt = 4.65),
        (
          'FURY · AMBER BREW',
          (b) {
            b.hp = 9;
            b.fireIn = .13;
          },
        ),
        ('DEFEAT · CROWN BREAKS FREE', (b) => b.defeatedAt = 4.4),
      ];
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawColor(const Color(0xff182e35), BlendMode.src);
      void label(
        String value,
        Offset at, {
        double size = 15,
        Color color = const Color(0xffd8e8ce),
      }) {
        (TextPainter(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: size,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout()).paint(canvas, at);
      }

      label(
        'SPITTER KING',
        const Offset(35, 22),
        size: 30,
        color: SpitterBossRig.gold,
      );
      label(
        'The airborne acid alchemist-monarch',
        const Offset(35, 58),
        size: 18,
      );
      for (var i = 0; i < states.length; i++) {
        final left = (i % 4) * 300.0, top = 100 + (i ~/ 4) * 310.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left + 10, top, 280, 298),
            const Radius.circular(18),
          ),
          Paint()..color = const Color(0xff29434a),
        );
        label(states[i].$1, Offset(left + 24, top + 20), size: 13);
        final boss = _boss();
        states[i].$2(boss);
        canvas.save();
        canvas.translate(left + 138, top + 187);
        canvas.scale(65.0);
        SpitterBossRig.paint(
          canvas,
          boss,
          BossMotion(boss, reducedMotion: false),
        );
        canvas.restore();
      }
      label(
        'GAMEPLAY SCALE · 360px scene height',
        const Offset(35, 755),
        size: 17,
      );
      canvas.save();
      canvas.translate(235, 858);
      AimedEnemyArt.paint(canvas, 16, seconds: 5, reducedMotion: false);
      canvas.restore();
      label('Ordinary spitter', const Offset(185, 912), size: 14);
      canvas.save();
      canvas.translate(490, 858);
      canvas.scale(360 * SkyBoss.radius);
      final boss = _boss();
      SpitterBossRig.paint(
        canvas,
        boss,
        BossMotion(boss, reducedMotion: false),
      );
      canvas.restore();
      label('Spitter King', const Offset(456, 912), size: 14);
      canvas.save();
      canvas.translate(815, 858);
      canvas.scale(360 * SkyBoss.radius);
      SpitterBossRig.paint(canvas, boss, BossMotion(boss, reducedMotion: true));
      canvas.restore();
      label('Reduced Motion', const Offset(773, 912), size: 14);
      final picture = recorder.endRecording();
      final image = await picture.toImage(1200, 950);
      final folder = Directory('build/visual-review')
        ..createSync(recursive: true);
      File('${folder.path}/spitter-brewer-pose-sheet.png').writeAsBytesSync(
        (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List(),
      );
      image.dispose();
      picture.dispose();
    });
  });
}
