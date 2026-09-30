import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dusk_moth_boss_rig.dart';

import 'boss_fight_test.dart' show arena;

SkyBoss _boss() =>
    SkyBoss(number: 3, x: 1.5, kind: BossKind.duskMoth, cinematic: true)
      ..age = 5;

void _paint(
  Canvas c,
  SkyBoss boss,
  Offset center,
  double radius, {
  bool reduced = false,
  bool shieldOnly = false,
  double aim = 0,
}) {
  final motion = BossMotion(boss, reducedMotion: reduced);
  if (!shieldOnly) {
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(radius);
    DuskMothBossRig.paint(c, boss, motion, lookY: aim);
    c.restore();
  }
  DuskMothBossRig.paintShield(c, center, radius * 1.85, boss, motion);
}

Future<Uint8List> _pixels(
  SkyBoss boss, {
  bool reduced = false,
  bool shieldOnly = false,
  bool crownOnly = false,
  double aim = 0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (crownOnly) {
    canvas.translate(180, 180);
    canvas.scale(75);
    canvas.translate(
      DuskMothBossRig.crownAnchor.dx,
      DuskMothBossRig.crownAnchor.dy,
    );
    DuskMothBossRig.crown(canvas);
  } else {
    _paint(
      canvas,
      boss,
      const Offset(180, 180),
      75,
      reduced: reduced,
      shieldOnly: shieldOnly,
      aim: aim,
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(360, 360);
  final result = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return result;
}

int _changedIn(Uint8List a, Uint8List b, Rect region) {
  var changed = 0;
  for (
    var y = (180 + region.top * 75).floor();
    y < 180 + region.bottom * 75;
    y++
  ) {
    for (
      var x = (180 + region.left * 75).floor();
      x < 180 + region.right * 75;
      x++
    ) {
      final i = (y * 360 + x) * 4;
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
  testWidgets('diadem stays seated on the skull through attached poses', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final crown = await _pixels(_boss(), crownOnly: true);
      for (final contact in const [
        Offset(-1.04, -.85),
        Offset(-.76, -.9),
        Offset(-.52, -.79),
      ]) {
        final x = (180 + contact.dx * 75).floor();
        final y = (180 + contact.dy * 75).floor();
        expect(
          crown[(y * 360 + x) * 4 + 3],
          greaterThan(240),
          reason: 'The fitted rim must contact both sides and the head crest',
        );
      }
      for (final reduced in [false, true]) {
        for (final boss in [
          _boss(),
          _boss()..age = 5.2,
          _boss()..fireIn = .05,
          _boss()..lastVolleyAt = 4.83,
          _boss()..lastHitAt = 4.86,
          _boss()..age = SkyBoss.roarAt + .4,
          _boss()..defeatedAt = 4.71,
        ]) {
          final actual = await _pixels(boss, reduced: reduced);
          var changed = 0;
          for (var i = 0; i < crown.length; i += 4) {
            if (crown[i + 3] != 255) continue;
            if (actual[i] != crown[i] ||
                actual[i + 1] != crown[i + 1] ||
                actual[i + 2] != crown[i + 2]) {
              changed++;
            }
          }
          expect(
            changed,
            0,
            reason: 'The diadem must share its head attachment in every pose',
          );
        }
      }
    });
  });

  testWidgets('defeat releases the crown without a position or angle jump', (
    tester,
  ) async {
    await tester.runAsync(() async {
      Future<Uint8List> frame(double death) async {
        final boss = _boss()
          ..x = .5
          ..age = 5 + death
          ..defeatedAt = 5;
        final recorder = ui.PictureRecorder();
        BossEncounterArt.paint(
          Canvas(recorder),
          const Size(360, 360),
          arena()..boss = boss,
          BossMotion(boss, reducedMotion: false),
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(360, 360);
        final pixels = (await image.toByteData())!.buffer.asUint8List();
        if (const bool.fromEnvironment('CAPTURE_MOTH_ART')) {
          Directory('build/visual-review').createSync(recursive: true);
          File(
            'build/visual-review/dusk-moth-crown-${death < .3 ? 'attached' : 'released'}.png',
          ).writeAsBytesSync(
            (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List(),
          );
        }
        image.dispose();
        picture.dispose();
        return pixels;
      }

      final before = await frame(.299999), after = await frame(.300001);
      var shifted = 0;
      for (var i = 0; i < before.length; i += 4) {
        // Separate compositing layers can slightly alter edge antialiasing.
        if ((before[i] - after[i]).abs() > 24 ||
            (before[i + 1] - after[i + 1]).abs() > 24 ||
            (before[i + 2] - after[i + 2]).abs() > 24 ||
            (before[i + 3] - after[i + 3]).abs() > 24) {
          shifted++;
        }
      }
      expect(
        shifted,
        lessThan(25),
        reason: 'The free crown begins at the final fitted transform',
      );
    });
  });

  testWidgets('moth poses seek exactly and Reduced Motion keeps useful cues', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final boss = _boss();
      final first = await _pixels(boss);
      boss.age = 5.2;
      expect(await _pixels(boss), isNot(equals(first)));
      boss.age = 5;
      expect(await _pixels(boss), first);
      final quiet = await _pixels(boss, reduced: true);
      boss.age = 8;
      expect(await _pixels(boss, reduced: true), quiet);
      boss.fireIn = .05;
      expect(
        await _pixels(boss, reduced: true),
        isNot(equals(quiet)),
        reason: 'Three glowing glands telegraph pollen fans',
      );
      boss.fireIn = 1;
      boss.age = boss.arrivalDuration + 4.5;
      final warning = await _pixels(boss, reduced: true);
      expect(warning, isNot(equals(quiet)));
      boss.age = boss.arrivalDuration + 5.2;
      final shield = await _pixels(boss, reduced: true);
      expect(shield, isNot(equals(warning)));
      boss.age += 8;
      expect(
        await _pixels(boss, reduced: true),
        shield,
        reason: 'The active veil does not rotate in Reduced Motion',
      );
      boss.hp = 12;
      expect(await _pixels(boss, reduced: true), isNot(equals(shield)));
      boss.defeatedAt = boss.age;
      expect(boss.shielded, isFalse);
      expect(await _pixels(boss, reduced: true), isNot(equals(shield)));
    });
  });

  testWidgets('aim and recoil preserve the fixed pollen port', (tester) async {
    await tester.runAsync(() async {
      final boss = _boss();
      final idle = await _pixels(boss);
      boss.lastVolleyAt = boss.age - .17;
      final recoil = await _pixels(boss, aim: 1);
      expect(
        _changedIn(
          idle,
          recoil,
          const Rect.fromLTRB(-1.07, -.025, -1.03, .025),
        ),
        0,
        reason: 'The shared projectile origin stays inside the dark mouth',
      );
      expect(
        _changedIn(idle, recoil, const Rect.fromLTRB(-1.12, -.44, -.56, -.05)),
        greaterThan(40),
        reason: 'The pupil tracks the player independently of the pollen port',
      );
      boss.lastVolleyAt = double.negativeInfinity;
      boss.fireIn = .05;
      expect(
        _changedIn(
          idle,
          await _pixels(boss),
          const Rect.fromLTRB(-.86, .12, -.34, .58),
        ),
        greaterThan(250),
        reason: 'The glands visibly swell and glow before the fan',
      );
    });
  });

  testWidgets('woven veil keeps a complete collision rim and clear center', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final boss = _boss()..age = 9.8;
      expect(boss.shielded, isTrue);
      final shield = await _pixels(boss, reduced: true, shieldOnly: true);
      for (var i = 0; i < 36; i++) {
        final angle = i * math.pi / 18;
        final x = (180 + math.cos(angle) * 75 * 1.85).floor();
        final y = (180 + math.sin(angle) * 75 * 1.85).floor();
        expect(
          shield[(y * 360 + x) * 4 + 3],
          greaterThan(180),
          reason: 'The blocking rim must remain continuous at angle $angle',
        );
      }
      expect(
        shield[(180 * 360 + 180) * 4 + 3],
        0,
        reason:
            'Silk decoration stays at the perimeter and leaves the face clear',
      );
      boss.lastShieldHitAt = boss.age - .15;
      final hit = await _pixels(boss, reduced: true, shieldOnly: true);
      expect(
        _changedIn(shield, hit, const Rect.fromLTRB(-2, -.4, -1.4, .4)),
        greaterThan(250),
        reason:
            'Caught shots show a bright rosette and short ripples even with Reduced Motion',
      );
      boss.age += 8;
      boss.lastShieldHitAt += 8;
      expect(
        await _pixels(boss, reduced: true, shieldOnly: true),
        hit,
        reason: 'Reduced Motion holds the impact geometry and silk weave',
      );
      boss.lastShieldHitAt = double.negativeInfinity;
      boss.age = boss.arrivalDuration + 4.3;
      final earlyWarning = await _pixels(boss, reduced: true, shieldOnly: true);
      boss.age = boss.arrivalDuration + 4.85;
      expect(
        await _pixels(boss, reduced: true, shieldOnly: true),
        isNot(equals(earlyWarning)),
        reason: 'The warning visibly weaves toward the complete veil',
      );
      boss.defeatedAt = boss.age;
      expect(
        (await _pixels(boss, shieldOnly: true)).every((value) => value == 0),
        isTrue,
      );
    });
  });

  testWidgets('renders moth poses at gameplay scale', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_MOTH_ART')) return;
    await tester.runAsync(() async {
      await (FontLoader(
        'Fredoka',
      )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
      final states = <(String, void Function(SkyBoss))>[
        ('DUSK EMPRESS · HOVER', (b) {}),
        ('POLLEN FAN · WINDUP', (b) => b.fireIn = .05),
        ('POLLEN FAN · RECOIL', (b) => b.lastVolleyAt = b.age - .17),
        ('VEIL · WARNING', (b) => b.age = b.arrivalDuration + 4.6),
        ('VEIL · SHIELDED', (b) => b.age = b.arrivalDuration + 5.2),
        (
          'VEIL · SHOT CAUGHT',
          (b) {
            b.age = b.arrivalDuration + 5.2;
            b.lastShieldHitAt = b.age - .15;
          },
        ),
        ('SWARM · SUMMON', (b) => b.lastSummonAt = b.age - .35),
        (
          'FURY · SEVEN SHOTS',
          (b) {
            b.hp = 12;
            b.fireIn = .1;
          },
        ),
        ('DEFEAT · CROWN RELEASED', (b) => b.defeatedAt = 4.5),
      ];
      Future<void> sheet({required bool phone}) async {
        final width = phone ? 250.0 : 360.0;
        final height = phone ? 240.0 : 340.0;
        final radius = phone ? 360 * SkyBoss.radius : 55.0;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)
          ..drawColor(const Color(0xff27243d), BlendMode.src);
        for (var i = 0; i < states.length; i++) {
          final left = i % 3 * width, top = i ~/ 3 * height;
          (TextPainter(
            text: TextSpan(
              text: states[i].$1,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: phone ? 12 : 16,
                color: DuskMothBossRig.silk,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout()).paint(canvas, Offset(left + 15, top + 18));
          final boss = _boss();
          states[i].$2(boss);
          _paint(
            canvas,
            boss,
            Offset(left + width * .38, top + height * .55),
            radius,
          );
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          (width * 3).round(),
          (height * 3).round(),
        );
        Directory('build/visual-review').createSync(recursive: true);
        File(
          'build/visual-review/dusk-moth-${phone ? 'phone' : 'pose'}-sheet.png',
        ).writeAsBytesSync(
          (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List(),
        );
        image.dispose();
        picture.dispose();
      }

      await sheet(phone: false);
      await sheet(phone: true);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawColor(const Color(0xff27243d), BlendMode.src);
      _paint(canvas, _boss(), const Offset(300, 330), 150, reduced: true);
      final picture = recorder.endRecording();
      final closeup = await picture.toImage(500, 400);
      File('build/visual-review/dusk-moth-crown-profile.png').writeAsBytesSync(
        (await closeup.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List(),
      );
      closeup.dispose();
      picture.dispose();
    });
  });
}
