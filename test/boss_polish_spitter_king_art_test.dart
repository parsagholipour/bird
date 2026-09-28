import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/enemy_designs/aimed_enemy.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/game/spitter_boss_rig.dart';

const _folder = 'build/visual-review/boss-polish/spitter-king';

SkyBoss _boss({double age = 5}) =>
    SkyBoss(number: 2, x: 1.5, kind: BossKind.spitterBeetle, cinematic: true)
      ..age = age;

typedef _Pose = (String, void Function(SkyBoss), double);

final _poses = <_Pose>[
  ('IDLE A', (b) {}, 0),
  ('IDLE B', (b) => b.age = 5.07, 0),
  ('IDLE C', (b) => b.age = 5.14, 0),
  ('IDLE D', (b) => b.age = 5.62, 0),
  ('LOOK UP', (b) {}, -1),
  ('LOOK DOWN', (b) {}, 1),
  ('PUMP .35', (b) => b.fireIn = .42, 0),
  ('PUMP .95', (b) => b.fireIn = .03, 0),
  ('SPIT', (b) => b.lastVolleyAt = 4.95, 0),
  ('RECOIL', (b) => b.lastVolleyAt = 4.83, 0),
  ('SUMMON', (b) => b.lastSummonAt = 4.65, 0),
  ('HIT', (b) => b.lastHitAt = 4.88, 0),
  (
    'FURY IDLE',
    (b) {
      b.hp = 80;
      b.enragedAt = 1;
    },
    0,
  ),
  (
    'FURY PUMP',
    (b) {
      b.hp = 80;
      b.enragedAt = 1;
      b.fireIn = .05;
    },
    0,
  ),
  (
    'ENRAGE MOMENT',
    (b) {
      b.hp = 80;
      b.enragedAt = 4.6;
    },
    0,
  ),
  ('ARRIVE 1.5s', (b) => b.age = 1.5, 0),
  ('ARRIVE 2.2s', (b) => b.age = 2.2, 0),
  ('HAT TIP 2.9s', (b) => b.age = 2.9, 0),
  ('DEFEAT .15s', (b) => b.defeatedAt = 4.85, 0),
  ('DEFEAT .5s', (b) => b.defeatedAt = 4.5, 0),
];

/// Paints the rig with the same body transform the encounter applies.
void _paintBoss(
  Canvas c,
  SkyBoss boss,
  Offset at,
  double radius, {
  bool reduced = false,
  double look = 0,
}) {
  final m = BossMotion(boss, reducedMotion: reduced);
  c.save();
  c.translate(at.dx, at.dy);
  final scale = radius * m.bodyScale;
  c.rotate(m.rotation);
  c.scale(scale * (1 + m.stretch), scale * (1 - m.stretch));
  final layer = Paint()
    ..color = const Color(0xffffffff).withValues(alpha: m.opacity);
  if (m.silhouette > .01) {
    layer.colorFilter = ColorFilter.mode(
      const Color(0xff1d2340).withValues(alpha: m.silhouette * .97),
      BlendMode.srcATop,
    );
  }
  c.saveLayer(const Rect.fromLTWH(-3, -2.3, 6, 4), layer);
  SpitterBossRig.paint(c, boss, m, lookY: look);
  c.restore();
  c.restore();
}

Future<ui.Image> _image(void Function(Canvas) draw, int w, int h) {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  return picture.toImage(w, h).whenComplete(picture.dispose);
}

Future<Uint8List> _pixels(
  SkyBoss boss, {
  bool reduced = false,
  double look = 0,
}) async {
  final img = await _image(
    (c) => _paintBoss(
      c,
      boss,
      const Offset(200, 190),
      80,
      reduced: reduced,
      look: look,
    ),
    400,
    340,
  );
  final bytes = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  return bytes;
}

Future<void> _save(
  String name,
  void Function(Canvas) draw,
  int w,
  int h,
) async {
  final folder = Directory(_folder)..createSync(recursive: true);
  final img = await _image(draw, w, h);
  File('${folder.path}/$name.png').writeAsBytesSync(
    (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
  img.dispose();
}

void _label(Canvas c, String text, Offset at, {double size = 13}) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: size,
        color: const Color(0xff203b45),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

void _sky(Canvas c, Rect rect, double seconds) {
  c.save();
  c.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
  c.translate(rect.left, rect.top);
  SkyScenery.paint(
    c,
    Size(
      rect.width < 800 ? 800 : rect.width,
      rect.height < 360 ? 360 : rect.height,
    ),
    seconds: seconds,
    distance: 3,
  );
  c.restore();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('spitter king animation is deterministic and seekable', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final pose in _poses) {
        final a = _boss();
        pose.$2(a);
        final first = await _pixels(a, look: pose.$3);
        final t = a.age;
        a.age = t + .9;
        await _pixels(a, look: pose.$3);
        a.age = t;
        expect(
          await _pixels(a, look: pose.$3),
          first,
          reason: '${pose.$1} replays identically after a seek',
        );
      }
      final boss = _boss();
      final a = await _pixels(boss);
      boss.age = 5.11;
      expect(await _pixels(boss), isNot(equals(a)), reason: 'idle is alive');
    });
  });

  testWidgets('Reduced Motion holds still but keeps every state readable', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final boss = _boss();
      final quiet = await _pixels(boss, reduced: true);
      for (final age in [5.13, 5.77, 7.3]) {
        boss.age = age;
        expect(await _pixels(boss, reduced: true), quiet, reason: 'idle $age');
      }
      boss.age = 5;
      boss.fireIn = .05;
      expect(await _pixels(boss, reduced: true), isNot(equals(quiet)));
      boss.fireIn = 1;
      boss.lastHitAt = 4.88;
      expect(
        await _pixels(boss, reduced: true),
        isNot(equals(quiet)),
        reason: 'hits still flash without moving',
      );
      boss.lastHitAt = double.negativeInfinity;
      boss.hp = 80;
      final fury = await _pixels(boss, reduced: true);
      expect(fury, isNot(equals(quiet)));
      boss.age = 6.4;
      expect(await _pixels(boss, reduced: true), fury);
    });
  });

  testWidgets('renders spitter king pose sheets', (tester) async {
    await tester.runAsync(() async {
      for (final family in ['Fredoka', 'Nunito']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
      }
      const cols = 5, cw = 300.0, ch = 270.0;
      final rows = (_poses.length / cols).ceil();
      await _save(
        'pose-sheet',
        (c) {
          c.drawColor(const Color(0xfff3eee0), BlendMode.src);
          _label(
            c,
            'SPITTER KING · POSES (radius 62px)',
            const Offset(20, 12),
            size: 20,
          );
          for (var i = 0; i < _poses.length; i++) {
            final r = Rect.fromLTWH(
              14 + (i % cols) * cw,
              46 + (i ~/ cols) * ch,
              cw - 10,
              ch - 10,
            );
            _sky(c, r, i >= 12 && i < 15 ? 38 : 4);
            _label(c, _poses[i].$1, r.topLeft + const Offset(10, 8));
            final boss = _boss();
            _poses[i].$2(boss);
            _paintBoss(
              c,
              boss,
              r.center + const Offset(-8, 22),
              62,
              look: _poses[i].$3,
            );
          }
        },
        (14 + cols * cw).toInt(),
        (56 + rows * ch).toInt(),
      );

      // Realistic phone: 360 logical px tall landscape, radius = 41 px.
      for (final (name, dpr) in [('phone-1x', 1.0), ('phone-3x', 3.0)]) {
        const w = 820.0, h = 360.0;
        await _save(
          name,
          (c) {
            c.scale(dpr);
            for (final (row, seconds) in [(0, 4.0), (1, 38.0)]) {
              final r = Rect.fromLTWH(0, row * h, w, h);
              _sky(c, r, seconds);
              final picks = row == 0 ? [0, 7, 9, 11] : [12, 13, 10, 19];
              for (var k = 0; k < picks.length; k++) {
                final pose = _poses[picks[k]];
                final boss = _boss();
                pose.$2(boss);
                final at = Offset(115 + k * 195.0, r.top + 150);
                _paintBoss(c, boss, at, h * SkyBoss.radius, look: pose.$3);
                _label(c, pose.$1, Offset(at.dx - 40, r.top + 250), size: 12);
              }
              c.save();
              c.translate(60, r.top + 310);
              AimedEnemyArt.paint(c, 16, seconds: 5, reducedMotion: false);
              c.restore();
              _label(c, 'minion (16px)', Offset(90, r.top + 302), size: 11);
            }
          },
          (w * dpr).toInt(),
          (h * 2 * dpr).toInt(),
        );
      }

      await _save(
        'reduced-motion',
        (c) {
          _sky(c, const Rect.fromLTWH(0, 0, 820, 300), 4);
          final picks = [0, 7, 11, 12, 19];
          for (var k = 0; k < picks.length; k++) {
            final boss = _boss();
            _poses[picks[k]].$2(boss);
            final at = Offset(90 + k * 160.0, 140);
            _paintBoss(c, boss, at, 52, reduced: true);
            _label(c, 'RM ${_poses[picks[k]].$1}', Offset(at.dx - 40, 250));
          }
        },
        820,
        300,
      );
    });
  });
}
