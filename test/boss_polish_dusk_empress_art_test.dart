import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dusk_moth_boss_rig.dart';

import 'boss_fight_test.dart' show arena;

/// Visual review for the Dusk Empress rig: a labelled pose sheet at close-up
/// and real phone scale, a hero close-up, plus determinism and Reduced Motion.
final _folder = Directory('build/visual-review/boss-polish/dusk-empress');

SkyBoss _boss() =>
    SkyBoss(number: 3, x: 1.5, kind: BossKind.duskMoth, cinematic: true)
      ..age = 5;

typedef _Pose = (String, void Function(SkyBoss), double);

final _poses = <_Pose>[
  ('IDLE · A', (b) {}, 0),
  ('IDLE · B', (b) => b.age = 5.11, 0),
  ('IDLE · C', (b) => b.age = 5.23, 0),
  ('CHARGING', (b) => b.fireIn = .05, 0),
  ('RECOIL', (b) => b.lastVolleyAt = b.age - .17, 0),
  ('HIT FLASH', (b) => b.lastHitAt = b.age - .12, 0),
  ('FURY', (b) => b.hp = b.maxHp ~/ 3, 0),
  (
    'FURY · CHARGING',
    (b) {
      b.hp = b.maxHp ~/ 3;
      b.fireIn = .08;
    },
    0,
  ),
  (
    'FURY · RAGE BURST',
    (b) {
      b.hp = b.maxHp ~/ 3;
      b.enragedAt = b.age - .45;
    },
    0,
  ),
  ('ARRIVAL · UNFOLD', (b) => b.age = 2.2, 0),
  ('ARRIVAL · ROAR', (b) => b.age = SkyBoss.roarAt + .35, 0),
  ('SUMMON', (b) => b.lastSummonAt = b.age - .35, 0),
  ('SHIELD WARNING', (b) => b.age = b.arrivalDuration + 4.55, 0),
  ('SHIELDED', (b) => b.age = b.arrivalDuration + 5.2, 0),
  (
    'SHIELD HIT',
    (b) {
      b.age = b.arrivalDuration + 5.2;
      b.lastShieldHitAt = b.age - .12;
    },
    0,
  ),
  ('LOOK UP', (b) {}, -1),
  ('LOOK DOWN', (b) {}, 1),
  ('DEFEAT', (b) => b.defeatedAt = b.age - .2, 0),
];

/// Mirrors BossEncounterArt's body transform so the sheet matches gameplay.
void _paintBoss(
  Canvas c,
  SkyBoss boss,
  Offset center,
  double radius, {
  bool reduced = false,
  double aim = 0,
}) {
  final m = BossMotion(boss, reducedMotion: reduced);
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(m.rotation);
  final scale = radius * m.bodyScale;
  c.scale(scale * (1 + m.stretch), scale * (1 - m.stretch));
  final layer = Paint()..color = const Color(0xffffffff);
  if (m.silhouette > .01) {
    layer.colorFilter = ColorFilter.mode(
      const Color(0xff241f3a).withValues(alpha: m.silhouette * .97),
      BlendMode.srcATop,
    );
  }
  c.saveLayer(DuskMothBossRig.layerBounds, layer);
  DuskMothBossRig.paint(c, boss, m, lookY: aim);
  c.restore();
  c.restore();
  DuskMothBossRig.paintShield(c, center, radius * 1.85, boss, m);
}

void _sceneBackground(Canvas c, Rect rect) {
  c.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff4f5982), Color(0xff7b80a4)],
      ).createShader(rect),
  );
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
  _paintBoss(
    Canvas(recorder),
    boss,
    const Offset(200, 180),
    70,
    reduced: reduced,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 360);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
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

void _sheet(
  Canvas c, {
  required double cellW,
  required double cellH,
  required double radius,
  required bool scene,
  required double font,
}) {
  const columns = 6;
  final rows = (_poses.length / columns).ceil();
  final full = Rect.fromLTWH(0, 0, cellW * columns, cellH * rows);
  if (scene) {
    _sceneBackground(c, full);
  } else {
    c.drawRect(full, Paint()..color = const Color(0xff27243d));
  }
  for (var i = 0; i < _poses.length; i++) {
    final (name, setup, aim) = _poses[i];
    final left = i % columns * cellW, top = i ~/ columns * cellH;
    _label(
      c,
      name,
      Offset(left + 8, top + 6),
      font,
      scene ? const Color(0xfffff3da) : DuskMothBossRig.silk,
    );
    final boss = _boss();
    setup(boss);
    _paintBoss(
      c,
      boss,
      Offset(left + cellW * .4, top + cellH * .55),
      radius,
      aim: aim,
    );
  }
}

void main() {
  testWidgets('Dusk Empress renders deterministically', (tester) async {
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
      boss.age = 5.37;
      expect(await _pixels(boss), isNot(equals(first)));
      boss.age = 5;
      expect(await _pixels(boss), first, reason: 'Poses seek exactly');
    });
  });

  testWidgets('Reduced Motion is still but keeps every state readable', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final idle = await _pixels(_boss(), reduced: true);
      expect(
        await _pixels(_boss()..age = 7.3, reduced: true),
        idle,
        reason: 'Idle does not animate with Reduced Motion',
      );
      for (final (name, setup, aim) in _poses) {
        if (name.startsWith('IDLE') || aim != 0) continue;
        // Arrival is carried by the encounter's silhouette; the shot ring
        // drawn by the encounter marks recoil.
        if (name.startsWith('ARRIVAL') || name == 'RECOIL') continue;
        final boss = _boss();
        setup(boss);
        expect(
          await _pixels(boss, reduced: true),
          isNot(equals(idle)),
          reason: '$name must stay distinguishable in Reduced Motion',
        );
      }
      final shielded = _boss()..age = _boss().arrivalDuration + 5.2;
      final still = await _pixels(shielded, reduced: true);
      shielded.age += SkyBoss.shieldPeriod;
      expect(
        await _pixels(shielded, reduced: true),
        still,
        reason: 'The veil does not rotate with Reduced Motion',
      );
    });
  });

  testWidgets('renders the Dusk Empress review sheets', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'Fredoka',
      )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
      const columns = 6, rows = 3;
      await _save(
        'pose-sheet-large',
        330 * columns,
        330 * rows,
        (c) => _sheet(
          c,
          cellW: 330,
          cellH: 330,
          radius: 52,
          scene: false,
          font: 15,
        ),
      );
      // A 360-pt-tall landscape phone: the hit radius is .115 of the height.
      const phoneRadius = 360 * SkyBoss.radius;
      await _save(
        'pose-sheet-phone',
        220 * columns,
        220 * rows,
        (c) => _sheet(
          c,
          cellW: 220,
          cellH: 220,
          radius: phoneRadius,
          scene: true,
          font: 10,
        ),
      );
      await _save('hero', 1500, 620, (c) {
        _sceneBackground(c, const Rect.fromLTWH(0, 0, 1500, 620));
        final calm = _boss();
        final fury = _boss()
          ..hp = _boss().maxHp ~/ 3
          ..fireIn = .08;
        final shielded = _boss()..age = _boss().arrivalDuration + 5.2;
        _paintBoss(c, calm, const Offset(230, 330), 105, reduced: true);
        _paintBoss(c, fury, const Offset(780, 330), 105, reduced: true);
        _paintBoss(c, shielded, const Offset(1290, 330), 105, reduced: true);
      });
      // The rig inside the real encounter layer at landscape phone size.
      for (final (name, setup) in <(String, void Function(SkyBoss))>[
        ('encounter-fighting', (b) {}),
        ('encounter-fury', (b) => b.hp = b.maxHp ~/ 3),
        ('encounter-shielded', (b) => b.age = b.arrivalDuration + 5.2),
        ('encounter-arrival', (b) => b.age = 2.3),
      ]) {
        final boss = _boss()..x = .62 * 800 / 360;
        setup(boss);
        await _save(name, 800, 360, (c) {
          _sceneBackground(c, const Rect.fromLTWH(0, 0, 800, 360));
          BossEncounterArt.paint(
            c,
            const Size(800, 360),
            arena()..boss = boss,
            BossMotion(boss, reducedMotion: false),
          );
        });
      }
      await _save('crown-closeup', 900, 520, (c) {
        c.drawColor(const Color(0xff27243d), BlendMode.src);
        _paintBoss(c, _boss(), const Offset(395, 400), 200, reduced: true);
        final fury = _boss()..hp = _boss().maxHp ~/ 3;
        c.save();
        c.clipRect(const Rect.fromLTWH(450, 0, 450, 520));
        _paintBoss(c, fury, const Offset(845, 400), 200, reduced: true);
        c.restore();
      });
      await _save('reduced-motion', 220 * columns, 220 * rows, (c) {
        _sceneBackground(c, const Rect.fromLTWH(0, 0, 1320, 660));
        for (var i = 0; i < _poses.length; i++) {
          final (name, setup, aim) = _poses[i];
          final left = i % columns * 220.0, top = i ~/ columns * 220.0;
          _label(
            c,
            name,
            Offset(left + 8, top + 6),
            10,
            const Color(0xfffff3da),
          );
          final boss = _boss();
          setup(boss);
          _paintBoss(
            c,
            boss,
            Offset(left + 88, top + 119),
            phoneRadius,
            reduced: true,
            aim: aim,
          );
        }
      });
    });
  });
}
