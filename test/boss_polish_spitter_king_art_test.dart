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

void _fury(SkyBoss b) {
  b.hp = 80;
  b.enragedAt = 1;
}

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
  ('FURY IDLE', _fury, 0),
  (
    'FURY PUMP',
    (b) {
      _fury(b);
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
  ('CROWN LIFT 2.9s', (b) => b.age = 2.9, 0),
  ('DEFEAT .15s', (b) => b.defeatedAt = 4.85, 0),
  ('DEFEAT .5s', (b) => b.defeatedAt = 4.5, 0),
  ('BLINK', (b) => b.age = 7.48, 0),
];

/// Paints the rig with the same body transform the encounter applies.
void _paintBoss(
  Canvas c,
  SkyBoss boss,
  Offset at,
  double radius, {
  bool reduced = false,
  double look = 0,
  Color? tint,
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
  } else if (tint != null) {
    layer.colorFilter = ColorFilter.mode(tint, BlendMode.srcATop);
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

/// The rig at (200, 190) with a radius of 80 px: 400 x 340 pixels.
const _origin = Offset(200, 190), _unit = 80.0;

Future<Uint8List> _pixels(
  SkyBoss boss, {
  bool reduced = false,
  double look = 0,
}) async {
  final img = await _image(
    (c) => _paintBoss(c, boss, _origin, _unit, reduced: reduced, look: look),
    400,
    340,
  );
  final bytes = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  return bytes;
}

/// The rig alone, with no body transform, so the spit port is exactly at
/// (-1.05, 0) in rig units.
Future<Uint8List> _rawPixels(SkyBoss boss, {double look = 0}) async {
  final img = await _image(
    (c) {
      c.translate(_origin.dx, _origin.dy);
      c.scale(_unit);
      SpitterBossRig.paint(
        c,
        boss,
        BossMotion(boss, reducedMotion: false),
        lookY: look,
      );
    },
    400,
    340,
  );
  final bytes = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  return bytes;
}

/// Pixels of [region] (rig units) that satisfy [test] on a 400-wide frame.
int _count(
  Uint8List px,
  Rect region,
  bool Function(int r, int g, int b, int a) test,
) {
  var n = 0;
  for (
    var y = (_origin.dy + region.top * _unit).floor();
    y < _origin.dy + region.bottom * _unit;
    y++
  ) {
    for (
      var x = (_origin.dx + region.left * _unit).floor();
      x < _origin.dx + region.right * _unit;
      x++
    ) {
      final i = (y * 400 + x) * 4;
      if (test(px[i], px[i + 1], px[i + 2], px[i + 3])) n++;
    }
  }
  return n;
}

bool _amber(int r, int g, int b, int a) =>
    a > 200 && r > 190 && g > 80 && g < 220 && b < 150 && r - b > 90;
bool _acidGreen(int r, int g, int b, int a) =>
    a > 200 && g > 140 && g - r > 50 && g - b > 20 && b < 220;
bool _dark(int r, int g, int b, int a) => a > 200 && r < 60 && g < 70 && b < 80;

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

/// A plain ground for judging the art itself, day or night.
void _plain(Canvas c, Rect rect, {bool night = false}) => c.drawRRect(
  RRect.fromRectAndRadius(rect, const Radius.circular(12)),
  Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: night
          ? const [Color(0xff1a2a5c), Color(0xff6a5aa5)]
          : const [Color(0xffbfe3d8), Color(0xff7fb59f)],
    ).createShader(rect),
);

typedef _Frame = (String, void Function(SkyBoss));

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
      // Includes a blink (7.48) and the crown's glint (7.1).
      for (final age in [5.13, 5.77, 7.1, 7.3, 7.48, 9.9]) {
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

  testWidgets('fury turns the whole brew amber, and the eyes red', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const vat = Rect.fromLTRB(.3, -.35, 1.7, 1.25);
      const crown = Rect.fromLTRB(-1.1, -1.7, .2, -.7);
      const eye = Rect.fromLTRB(-.85, -.6, -.3, -.15);
      final calm = await _pixels(_boss());
      final furious = await _pixels(_boss()..hp = 80);
      expect(
        _count(furious, vat, _amber),
        greaterThan(_count(calm, vat, _amber) + 1500),
        reason: 'the vat glows amber',
      );
      expect(
        _count(furious, crown, _amber),
        greaterThan(_count(calm, crown, _amber) + 200),
        reason: 'the crown flasks glow amber',
      );
      expect(
        _count(calm, vat, _acidGreen),
        greaterThan(_count(furious, vat, _acidGreen) + 1500),
        reason: 'calm acid is green',
      );
      bool red(int r, int g, int b, int a) =>
          a > 200 && r - g > 105 && b > 35 && b < 130;
      expect(
        _count(furious, eye, red),
        greaterThan(_count(calm, eye, red) + 60),
        reason: 'the iris burns red',
      );
    });
  });

  testWidgets('charge raises the acid, swells the jowl and lights the mouth', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const vat = Rect.fromLTRB(.3, -.35, 1.7, 1.25);
      const mouth = Rect.fromLTRB(-1.1, -.08, -1.0, .08);
      var last = 0;
      var lastJowl = 0;
      const jowl = Rect.fromLTRB(-.85, .1, -.05, .75);
      bool jowlGreen(int r, int g, int b, int a) =>
          a > 200 && g > 190 && g - r > 40 && b < 210;
      for (final fireIn in [.65, .4, .2, .03]) {
        final px = await _pixels(_boss()..fireIn = fireIn);
        final liquid = _count(px, vat, _acidGreen);
        final sac = _count(px, jowl, jowlGreen);
        expect(liquid, greaterThan(last), reason: 'liquid at $fireIn');
        expect(sac, greaterThan(lastJowl), reason: 'jowl at $fireIn');
        last = liquid;
        lastJowl = sac;
      }
      final idle = await _pixels(_boss());
      final windup = await _pixels(_boss()..fireIn = .03);
      expect(_count(idle, mouth, _dark), greaterThan(30));
      expect(
        _count(windup, mouth, _dark),
        lessThan(_count(idle, mouth, _dark) * .6),
        reason: 'the throat glows before it spits',
      );
    });
  });

  testWidgets('the spit port stays dark and fixed at rest in every pose', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const port = Rect.fromLTRB(-1.07, -.03, -1.03, .03);
      for (final pose in _poses) {
        final name = pose.$1;
        // Windups light the throat and the flash lifts every tone.
        if (name.contains('PUMP') || name.contains('HIT')) continue;
        final boss = _boss();
        pose.$2(boss);
        final px = await _rawPixels(boss, look: pose.$3);
        final total =
            (port.width * _unit).ceil() * (port.height * _unit).ceil();
        expect(
          _count(px, port, _dark),
          greaterThanOrEqualTo(total - 3),
          reason: '$name: the projectile leaves the dark throat',
        );
      }
    });
  });

  testWidgets('the entrance eye anchor sits on the eye', (tester) async {
    await tester.runAsync(() async {
      final px = await _pixels(_boss());
      final at = SpitterBossRig.eyeCenter;
      final i =
          ((_origin.dy + at.dy * _unit).round() * 400 +
              (_origin.dx + at.dx * _unit).round()) *
          4;
      final r = px[i], g = px[i + 1], b = px[i + 2];
      // The amber iris, or the slit's ink, never the jade around the eye.
      expect(
        r > 200 && g > 90 && b < 110 || r < 60 && g < 70,
        isTrue,
        reason: 'pixel at eyeCenter is $r,$g,$b',
      );
    });
  });

  testWidgets('the crown is worn until the defeat throws it clear', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Above the head: only the crown's flasks reach this high.
      const region = Rect.fromLTRB(-1.05, -1.75, -.15, -.95);
      final worn = await _pixels(_boss());
      final gone = await _pixels(_boss()..defeatedAt = 4.6);
      bool solid(int r, int g, int b, int a) => a > 100;
      expect(_count(worn, region, solid), greaterThan(1200));
      expect(
        _count(gone, region, solid),
        lessThan(150),
        reason: 'the debris animation takes over',
      );
    });
  });

  testWidgets('the detached crown fits the box the debris layer allots', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const unit = 100.0;
      const origin = Offset(350, 300);
      for (final glow in [SpitterBossRig.acid, const Color(0xffffb65f)]) {
        final img = await _image(
          (c) {
            c.translate(origin.dx, origin.dy);
            c.scale(unit);
            SpitterBossRig.crown(c, glow: glow);
          },
          700,
          500,
        );
        final px = (await img.toByteData())!.buffer.asUint8List();
        img.dispose();
        var l = 700, t = 500, r = 0, b = 0;
        for (var y = 0; y < 500; y++) {
          for (var x = 0; x < 700; x++) {
            if (px[(y * 700 + x) * 4 + 3] > 8) {
              if (x < l) l = x;
              if (x > r) r = x;
              if (y < t) t = y;
              if (y > b) b = y;
            }
          }
        }
        final box = SpitterBossRig.crownBounds.inflate(.1);
        expect(l, greaterThanOrEqualTo(origin.dx + box.left * unit - 1));
        expect(r, lessThanOrEqualTo(origin.dx + box.right * unit + 1));
        expect(t, greaterThanOrEqualTo(origin.dy + box.top * unit - 1));
        expect(b, lessThanOrEqualTo(origin.dy + box.bottom * unit + 1));
        expect(r - l, greaterThan(70), reason: 'the crown is drawn at all');
      }
    });
  });

  testWidgets('a hit flashes the whole King without ghosting it', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const body = Rect.fromLTRB(-1.2, -1.7, 2.0, 1.2);
      final calm = await _pixels(_boss());
      final hit = await _pixels(_boss()..lastHitAt = 4.88);
      bool bright(int r, int g, int b, int a) => a > 200 && r + g + b > 700;
      expect(
        _count(hit, body, bright),
        greaterThan(_count(calm, body, bright) + 800),
        reason: 'the flash lifts every part',
      );
      // The flash lifts the ink itself, but it stays the darkest tone.
      bool inked(int r, int g, int b, int a) =>
          a > 200 && r < 150 && g < 160 && b < 150;
      expect(
        _count(hit, body, inked),
        greaterThan(_count(calm, body, _dark) * .6),
        reason: 'outlines survive the flash',
      );
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

      // Large close-ups on a plain ground, for judging craft and materials.
      const closeups = [0, 7, 13, 17];
      await _save(
        'closeups',
        (c) {
          c.drawColor(const Color(0xffe4efe6), BlendMode.src);
          for (var k = 0; k < closeups.length; k++) {
            final pose = _poses[closeups[k]];
            final boss = _boss();
            pose.$2(boss);
            final at = Offset(230 + (k % 2) * 700.0, 330 + (k ~/ 2) * 560.0);
            _paintBoss(c, boss, at, 150, look: pose.$3);
            _label(c, pose.$1, at + const Offset(-200, -270), size: 20);
          }
        },
        1400,
        1120,
      );
      await _save(
        'hero',
        (c) {
          c.drawColor(const Color(0xffe4efe6), BlendMode.src);
          _paintBoss(c, _boss(), const Offset(480, 520), 330);
        },
        1500,
        1100,
      );

      // One-glance silhouettes at the real gameplay size (x3), beside the
      // ordinary spitter, to judge the hero shape without any color.
      await _save(
        'silhouette',
        (c) {
          c.drawColor(const Color(0xffdfe9f0), BlendMode.src);
          c.scale(3);
          for (var k = 0; k < 4; k++) {
            final boss = _boss();
            _poses[[0, 7, 12, 10][k]].$2(boss);
            _paintBoss(
              c,
              boss,
              Offset(70 + k * 120.0, 90),
              360 * SkyBoss.radius,
              tint: const Color(0xff223437),
            );
          }
          c.save();
          c.translate(560, 90);
          c.saveLayer(
            const Rect.fromLTWH(-30, -30, 60, 60),
            Paint()
              ..colorFilter = const ColorFilter.mode(
                Color(0xff223437),
                BlendMode.srcATop,
              ),
          );
          AimedEnemyArt.paint(c, 16, seconds: 5, reducedMotion: false);
          c.restore();
          c.restore();
        },
        1800,
        480,
      );

      // Motion strips: one frame per label, on a plain ground.
      Future<void> strip(
        String name,
        List<_Frame> frames, {
        bool reduced = false,
        bool night = false,
      }) async {
        const cw = 190.0, ch = 190.0;
        await _save(
          name,
          (c) {
            c.drawColor(const Color(0xfff3eee0), BlendMode.src);
            for (var i = 0; i < frames.length; i++) {
              final r = Rect.fromLTWH(
                6 + (i % 8) * cw,
                6 + (i ~/ 8) * ch,
                cw - 8,
                ch - 8,
              );
              _plain(c, r, night: night);
              _label(c, frames[i].$1, r.topLeft + const Offset(8, 6), size: 12);
              final boss = _boss();
              frames[i].$2(boss);
              _paintBoss(
                c,
                boss,
                r.center + const Offset(-6, 14),
                56,
                reduced: reduced,
              );
            }
          },
          (12 + 8 * cw).toInt(),
          (12 + ((frames.length + 7) ~/ 8) * ch).toInt(),
        );
      }

      await strip('seq-charge-recoil', [
        for (final f in [.65, .55, .45, .35, .25, .15, .06, 0.0])
          ('fireIn $f', (b) => b.fireIn = f),
        for (final f in [0.0, .04, .08, .13, .19, .25, .3, .34])
          ('recoil ${(f * 100).round()}', (b) => b.lastVolleyAt = 5 - f),
      ]);
      await strip('seq-arrival', [
        for (final a in [.5, 1.0, 1.4, 1.8, 2.2, 2.6, 2.9, 3.2, 3.5, 3.8, 4.2])
          ('age $a', (b) => b.age = a),
      ]);
      await strip('seq-defeat', [
        for (final d in [0.0, .1, .25, .4, .6, .8, 1.0, 1.4])
          ('death $d', (b) => b.defeatedAt = 5 - d),
      ]);
      await strip('seq-summon-fury', [
        for (final d in [0.0, .1, .2, .3, .4, .5, .6, .7])
          ('summon $d', (b) => b.lastSummonAt = 5 - d),
        for (final d in [0.0, .2, .4, .6, .8, 1.0, 1.1, 1.3])
          (
            'rage $d',
            (b) {
              b.hp = 80;
              b.enragedAt = 5 - d;
            },
          ),
      ], night: true);
      await strip('seq-idle', [
        for (var i = 0; i < 16; i++)
          ('t ${(i * .05).toStringAsFixed(2)}', (b) => b.age = 5 + i * .05),
      ]);

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
