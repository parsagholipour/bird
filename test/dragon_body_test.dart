import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_body_art.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

/// The Ember Dragon's body (B2): torso, belly, breastplate and heart-gem, the
/// legs and the tail.
///
/// Visual review (PNGs in `build/visual-review/dragon-body/`): close-ups of
/// the torso on a light and a dark sky, the heart in every state, the tail
/// across its bend, the legs across the wingbeat, calm against fury and the
/// silhouette at 250 and 120 px. Checks: the gem is the clearest target and
/// the plates end inside the hit circle; fury changes plates, seams and tail;
/// the body stays inside the layout's envelope for every bend; the belly-leg-
/// tail gap stays open; the per-frame budget; determinism and Reduced Motion.
final _out = Directory('build/visual-review/dragon-body');

SkyBoss _boss(
  void Function(SkyBoss) setup,
  double combat, {
  bool fury = false,
  int cycles = 0,
}) {
  final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = BreathLane.middle;
  if (fury) b.hp = b.maxHp ~/ 3;
  b.age = b.arrivalDuration + combat + cycles * DragonBreath.period;
  setup(b);
  return b;
}

DragonPose _pose(
  void Function(SkyBoss) setup,
  double combat, {
  bool fury = false,
  bool reduced = false,
  int cycles = 0,
  DragonSkyLight light = DragonSkyLight.neutral,
}) {
  final b = _boss(setup, combat, fury: fury, cycles: cycles);
  return DragonPose(b, BossMotion(b, reducedMotion: reduced), light: light);
}

/// The body in the rig's order and frame (pitch and bob included).
void _paintBody(
  Canvas c,
  DragonBodyPose body, {
  DragonPose? pose,
  bool neck = false,
}) {
  c.save();
  if (pose != null) {
    c.translate(pose.bob.dx, pose.bob.dy);
    c.rotate(pose.pitch);
  }
  DragonBodyArt.back(c, body);
  DragonBodyArt.torsoPaint(c, body);
  DragonBodyArt.front(c, body);
  if (neck) {
    // A flat stand-in for the neck so the breastplate has something to
    // overlap (the real one belongs to the head).
    final spine = DragonLayout.neckSpine(const Offset(-.5, -1.75), .16);
    final tube = DragonKit.tube(spine, DragonLayout.neckWidths);
    c.drawPath(tube, Paint()..color = const Color(0xff7a5a90));
    c.drawPath(tube, DragonKit.line(DragonPalette.ink, .1));
  }
  DragonBodyArt.heart(c, body);
  DragonBodyArt.foreleg(c, body);
  c.restore();
}

Future<Uint8List> _pixels(int w, int h, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  final data = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return data;
}

Future<void> _save(
  String name,
  int w,
  int h,
  void Function(Canvas) draw,
) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  _out.createSync(recursive: true);
  File('${_out.path}/$name.png').writeAsBytesSync(
    (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
  img.dispose();
  pic.dispose();
}

Future<void> _fonts() async {
  await (FontLoader(
    'Fredoka',
  )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
}

void _label(Canvas c, String text, Offset at, Color color) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

const _sky = Color(0xff8a86ad);
const _night = Color(0xff141a3a);
const _bright = Color(0xffe9dfd2);

/// A labelled grid of cells, each drawn in rig units by its callback.
Future<void> _grid(
  String name, {
  required List<(String, void Function(Canvas))> cells,
  required int cols,
  required Rect view,
  required double ppu,
  Color bg = _sky,
  Color fg = const Color(0xff222222),
}) async {
  final cw = (view.width * ppu).round(), ch = (view.height * ppu).round();
  final rows = (cells.length / cols).ceil();
  await _save(name, cw * cols, ch * rows, (c) {
    c.drawRect(
      Rect.fromLTWH(0, 0, (cw * cols).toDouble(), (ch * rows).toDouble()),
      Paint()..color = bg,
    );
    for (var i = 0; i < cells.length; i++) {
      final cx = (i % cols) * cw.toDouble(), cy = (i ~/ cols) * ch.toDouble();
      c.save();
      c.clipRect(Rect.fromLTWH(cx, cy, cw.toDouble(), ch.toDouble()));
      c.translate(cx, cy);
      c.scale(ppu);
      c.translate(-view.left, -view.top);
      cells[i].$2(c);
      c.restore();
      _label(c, cells[i].$1, Offset(cx + 6, cy + 4), fg);
    }
  });
}

/// The solid (alpha >= [solid]) bounds of [draw] in rig units.
Future<Rect> _scan(void Function(Canvas) draw, {int solid = 200}) async {
  const ppu = 24.0, half = 7.5, n = 360;
  final data = await _pixels(n, n, (c) {
    c.scale(ppu);
    c.translate(half, half);
    draw(c);
  });
  var minX = n, minY = n, maxX = -1, maxY = -1;
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (data[(y * n + x) * 4 + 3] >= solid) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) return Rect.zero;
  return Rect.fromLTRB(
    minX / ppu - half,
    minY / ppu - half,
    (maxX + 1) / ppu - half,
    (maxY + 1) / ppu - half,
  );
}

/// Counts what a frame asks of the canvas.
class _Counting implements Canvas {
  _Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get clips => (counts['clipPath'] ?? 0) + (counts['clipPath.noAA'] ?? 0);

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    _n('saveLayer');
    inner.saveLayer(bounds, paint);
  }

  @override
  void translate(double dx, double dy) => inner.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => inner.scale(sx, sy);
  @override
  void rotate(double r) => inner.rotate(r);
  @override
  void clipPath(Path p, {bool doAntiAlias = true}) {
    _n(doAntiAlias ? 'clipPath' : 'clipPath.noAA');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  void _paint(String k, Paint p) {
    _n(k);
    if (p.shader != null) _n('$k.shader');
    if (p.maskFilter != null) _n('maskFilter');
  }

  @override
  void drawPath(Path p, Paint paint) {
    _paint('drawPath', paint);
    inner.drawPath(p, paint);
  }

  @override
  void drawCircle(Offset c, double r, Paint paint) {
    _paint('drawCircle', paint);
    inner.drawCircle(c, r, paint);
  }

  @override
  void drawRect(Rect r, Paint paint) {
    _paint('drawRect', paint);
    inner.drawRect(r, paint);
  }

  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) {
    _paint('drawArc', paint);
    inner.drawArc(r, a, b, c, paint);
  }

  @override
  void drawLine(Offset a, Offset b, Paint paint) {
    _paint('drawLine', paint);
    inner.drawLine(a, b, paint);
  }

  @override
  void drawOval(Rect r, Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
  }

  @override
  void drawRRect(RRect r, Paint paint) {
    _paint('drawRRect', paint);
    inner.drawRRect(r, paint);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

double _luma(Uint8List d, int w, int x, int y) {
  final i = (y * w + x) * 4;
  return (d[i] * .2126 + d[i + 1] * .7152 + d[i + 2] * .0722) / 255;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const night = DragonSkyLight(dark: 1, sky: Color(0xff8f8cd8));

  testWidgets('review: torso close-ups on a light and a dark sky', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _fonts();
      const view = Rect.fromLTRB(-2.5, -1.7, 4.6, 3.8);
      for (final (name, light, bg, fg) in [
        (
          'torso-light',
          DragonSkyLight.neutral,
          _bright,
          const Color(0xff222222),
        ),
        ('torso-dark', night, _night, const Color(0xffdddddd)),
      ]) {
        final states = <(String, DragonPose)>[
          ('rest', _pose((b) {}, 1.2, light: light)),
          ('inhale: the chest opens', _pose((b) {}, 4.9, light: light)),
          ('hit', _pose((b) => b.lastHitAt = b.age - .1, 1.2, light: light)),
          ('fury', _pose((b) {}, 1.2, fury: true, light: light)),
        ];
        await _grid(
          name,
          cells: [
            for (final (n, p) in states)
              (
                n,
                (c) => _paintBody(c, DragonBodyPose.of(p), pose: p, neck: true),
              ),
          ],
          cols: 2,
          view: view,
          ppu: 78,
          bg: bg,
          fg: fg,
        );
        // The chest at 5x: the breastplate, the gem, the belly plates.
        final rest = states.first.$2;
        await _grid(
          '$name-5x',
          cells: [
            (
              'chest 5x',
              (c) => _paintBody(
                c,
                DragonBodyPose.of(rest),
                pose: rest,
                neck: true,
              ),
            ),
          ],
          cols: 1,
          view: const Rect.fromLTRB(-1.75, -1.25, 2.45, 1.95),
          ppu: 205,
          bg: bg,
          fg: fg,
        );
      }
    });
  });

  testWidgets(
    'review: the heart in rest, fury, open, wide open, crit and crack',
    (tester) async {
      await tester.runAsync(() async {
        await _fonts();
        final cells = <(String, DragonBodyPose)>[
          ('rest', const DragonBodyPose(heart: .2)),
          ('fury', const DragonBodyPose(heart: .45, tone: DragonTone(fury: 1))),
          (
            'open .5',
            const DragonBodyPose(
              heart: .8,
              open: .5,
              tone: DragonTone(heat: .6),
            ),
          ),
          (
            'open 1',
            const DragonBodyPose(heart: 1, open: 1, tone: DragonTone(heat: 1)),
          ),
          (
            'crit',
            const DragonBodyPose(
              heart: 1,
              open: 1,
              crit: .8,
              tone: DragonTone(heat: 1),
            ),
          ),
          ('crack', const DragonBodyPose(heart: .5, crack: .7)),
        ];
        await _grid(
          'heart-states',
          cells: [
            for (final (n, p) in cells)
              (n, (c) => _paintBody(c, p, neck: true)),
          ],
          cols: 3,
          view: const Rect.fromLTRB(-1.9, -1.7, 1.9, 1.7),
          ppu: 105,
        );
      });
    },
  );

  testWidgets('review: the tail across its bend and the legs across the beat', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _fonts();
      await _grid(
        'tail-wave',
        cells: [
          for (final b in [-.5, -.25, 0.0, .25, .5])
            (
              'bend $b',
              (c) => _paintBody(
                c,
                DragonBodyPose(heart: .3, bend: (u) => b * u * u),
              ),
            ),
        ],
        cols: 3,
        view: const Rect.fromLTRB(.6, -.3, 4.5, 3.8),
        ppu: 110,
      );
      await _grid(
        'leg-strip',
        cells: [
          for (final sw in [-1.0, 0.0, 1.0])
            (
              'beat $sw',
              (c) => _paintBody(
                c,
                DragonBodyPose(
                  heart: .3,
                  hindSwing: sw * .06,
                  foreSwing: sw * .04,
                ),
              ),
            ),
          for (final cl in [0.0, .6, 1.0])
            (
              'clutch $cl',
              (c) => _paintBody(c, DragonBodyPose(heart: .3, clutch: cl)),
            ),
          (
            'kick',
            (c) => _paintBody(c, const DragonBodyPose(heart: .3, kick: 1)),
          ),
          (
            'slump',
            (c) => _paintBody(c, const DragonBodyPose(heart: .3, slump: .7)),
          ),
        ],
        cols: 3,
        view: const Rect.fromLTRB(-2.5, .2, 2.7, 3.0),
        ppu: 100,
      );
    });
  });

  testWidgets(
    'review: calm against fury, and the silhouette at 250 and 120 px',
    (tester) async {
      await tester.runAsync(() async {
        await _fonts();
        final calm = _pose((b) {}, 1.2, light: night);
        final fury = _pose((b) {}, 1.2, fury: true, light: night);
        await _grid(
          'fury-vs-calm',
          cells: [
            (
              'calm',
              (c) => _paintBody(
                c,
                DragonBodyPose.of(calm),
                pose: calm,
                neck: true,
              ),
            ),
            (
              'fury',
              (c) => _paintBody(
                c,
                DragonBodyPose.of(fury),
                pose: fury,
                neck: true,
              ),
            ),
          ],
          cols: 2,
          view: const Rect.fromLTRB(-2.5, -1.7, 4.6, 3.8),
          ppu: 90,
          bg: _night,
          fg: const Color(0xffdddddd),
        );
        final cells = <(String, DragonPose)>[
          ('idle', _pose((b) {}, 1.2)),
          ('charge', _pose((b) => b.fireIn = .01, 1.2)),
          ('alert', _pose((b) {}, 3.7)),
          ('rear back', _pose((b) {}, 4.7)),
          ('hold', _pose((b) {}, 5.05)),
          ('snap', _pose((b) {}, 5.24)),
          ('blast low', _pose((b) => b.breathLane = BreathLane.low, 5.7)),
          ('hit', _pose((b) => b.lastHitAt = b.age - .1, 1.2)),
        ];
        void sil(Canvas c, DragonPose p) {
          c.saveLayer(
            null,
            Paint()
              ..colorFilter = const ColorFilter.mode(
                Color(0xff000000),
                BlendMode.srcIn,
              ),
          );
          DragonBossRig.paintPose(c, p);
          c.restore();
        }

        const view = Rect.fromLTRB(-3.9, -4.6, 5.3, 4.6);
        for (final (name, ppu, cols) in const [
          ('silhouette-250', 41.4, 4),
          ('silhouette-120', 19.0, 4),
        ]) {
          await _grid(
            name,
            cells: [for (final (n, p) in cells) (n, (c) => sil(c, p))],
            cols: cols,
            view: view,
            ppu: ppu,
            bg: _bright,
          );
        }
      });
    },
  );

  testWidgets(
    'the gem is the clearest target and the plates end inside the hit circle',
    (tester) async {
      await tester.runAsync(() async {
        for (final (name, pose) in const [
          ('rest', DragonBodyPose(heart: .2)),
          (
            'open',
            DragonBodyPose(heart: 1, open: 1, tone: DragonTone(heat: 1)),
          ),
          ('crit', DragonBodyPose(heart: 1, open: 1, crit: 1)),
          ('crack', DragonBodyPose(heart: .5, crack: 1)),
          ('fury', DragonBodyPose(heart: .5, tone: DragonTone(fury: 1))),
        ]) {
          // The solid pixels inside 1.15 of the heart (the back spines, painted
          // with the heart in front of the wing, lie farther out): none may be
          // beyond the hit circle, and the ring of plates must reach it.
          const ppu = 100.0, half = 130;
          final d = await _pixels(2 * half, 2 * half, (c) {
            c.scale(ppu);
            c.translate(half / ppu, half / ppu);
            DragonBodyArt.heart(c, pose);
          });
          var outermost = 0.0;
          for (var y = 0; y < 2 * half; y++) {
            for (var x = 0; x < 2 * half; x++) {
              if (d[(y * 2 * half + x) * 4 + 3] < 200) continue;
              final r = Offset(
                (x + .5) / ppu - half / ppu,
                (y + .5) / ppu - half / ppu,
              ).distance;
              if (r < 1.15) outermost = math.max(outermost, r);
            }
          }
          expect(
            outermost,
            lessThanOrEqualTo(1.0 + .03),
            reason: '$name plates end inside the hit circle',
          );
          expect(
            outermost,
            greaterThan(.9),
            reason: '$name: the ring fills the circle',
          );
        }
        // Contrast: the gem's core is bright against the dark socket around it.
        const cp = 100.0;
        final cd = await _pixels(200, 200, (c) {
          c.scale(cp);
          c.translate(1, 1);
          DragonBodyArt.heart(c, const DragonBodyPose(heart: .6));
        });
        int px(double u) => (u * cp + 100).round();
        final core = _luma(cd, 200, px(0), px(0));
        final socket = _luma(cd, 200, px(0), px(-.33));
        expect(core, greaterThan(.6), reason: 'the gem core is white-hot');
        expect(socket, lessThan(.16), reason: 'the socket around it is dark');
        expect(core - socket, greaterThan(.45));
      });
    },
  );

  testWidgets('the breastplate is plum armour, not a black badge', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Sample each plate's body: a step above the crease colour (L* 13) and
      // below the body's lit crest (L* 45), lit along its top edge.
      const ppu = 100.0, half = 130;
      final d = await _pixels(2 * half, 2 * half, (c) {
        c.scale(ppu);
        c.translate(half / ppu, half / ppu);
        DragonBodyArt.heart(c, const DragonBodyPose(heart: .2));
      });
      double lstar(Offset rig) {
        final x = (rig.dx * ppu + half).round(),
            y = (rig.dy * ppu + half).round();
        final i = (y * 2 * half + x) * 4;
        double lin(int v) {
          final c = v / 255;
          return c <= .04045
              ? c / 12.92
              : math.pow((c + .055) / 1.055, 2.4).toDouble();
        }

        final yy =
            .2126 * lin(d[i]) + .7152 * lin(d[i + 1]) + .0722 * lin(d[i + 2]);
        return yy > 216 / 24389 ? 116 * math.pow(yy, 1 / 3) - 16 : 903.3 * yy;
      }

      // Seven petals at -60 + 51.4 k degrees: sample each at r .74, a little
      // to either side of its ridge.
      final samples = <double>[];
      for (var k = 0; k < 7; k++) {
        final a = -math.pi / 3 + k * 2 * math.pi / 7;
        for (final off in const [-.12, .12]) {
          samples.add(
            lstar(Offset(math.cos(a + off), math.sin(a + off)) * .74),
          );
        }
      }
      samples.sort();
      final median = samples[samples.length ~/ 2];
      // ignore: avoid_print
      print(
        'breastplate median L* ${median.toStringAsFixed(1)} '
        '(${samples.first.toStringAsFixed(1)}..${samples.last.toStringAsFixed(1)})',
      );
      expect(median, greaterThan(17), reason: 'plum plates, not #201e3d');
      expect(median, lessThan(45), reason: 'still armour under the gem');
    });
  });

  test('the body keeps bounded caches through 100 breath cycles', () {
    for (var n = 0; n < 100; n++) {
      for (var i = 0; i < 12; i++) {
        final pose = _pose(
          (b) {
            if (i % 3 == 0) b.lastHitAt = b.age - .1;
          },
          i * .9,
          fury: n.isOdd,
          cycles: n,
          light: DragonSkyLight(dark: (n % 5) / 4),
        );
        final rec = ui.PictureRecorder();
        _paintBody(Canvas(rec), DragonBodyPose.of(pose), pose: pose);
        rec.endRecording().dispose();
      }
      expect(
        DragonBodyArt.cacheSize,
        lessThanOrEqualTo(24),
        reason: 'cycle $n',
      );
    }
  });

  test('a NaN or infinite pose never reaches the canvas', () {
    const nan = double.nan, inf = double.infinity;
    final bad = DragonBodyPose(
      time: nan,
      breath: inf,
      heart: nan,
      open: inf,
      crit: nan,
      crack: nan,
      slump: inf,
      clutch: nan,
      kick: inf,
      hindSwing: nan,
      foreSwing: inf,
      bend: (u) => nan,
      tailSway: nan,
      tone: const DragonTone(flash: nan, fury: inf, heat: nan, dark: nan),
    );
    final r = ui.PictureRecorder();
    _paintBody(Canvas(r), bad);
    expect(DragonBodyArt.tailOf(bad).shape.getBounds().isFinite, isTrue);
    expect(DragonBodyArt.torsoOf(bad).getBounds().isFinite, isTrue);
    r.endRecording().dispose();
  });

  test('the LRU cache evicts one entry at a time, oldest first', () {
    final cache = DragonCache<int, int>(3);
    for (var i = 0; i < 3; i++) {
      cache.get(i, () => i * 10);
    }
    expect(cache.get(0, () => -1), 0, reason: 'a hit keeps its value');
    cache.get(3, () => 30); // evicts 1 (the oldest), not 0 (just used)
    expect(cache.length, 3);
    expect(cache.get(0, () => -1), 0);
    expect(cache.get(1, () => 11), 11, reason: '1 was evicted, so rebuilt');
    expect(cache.length, 3);
  });

  testWidgets(
    'fury changes the plates, the seams and the tail, not only the wings',
    (tester) async {
      await tester.runAsync(() async {
        const calm = DragonBodyPose(heart: .3);
        const fury = DragonBodyPose(heart: .5, tone: DragonTone(fury: 1));
        const ppu = 40.0, w = 320, h = 200;
        Future<Uint8List> shot(DragonBodyPose p) => _pixels(w, h, (c) {
          c.scale(ppu);
          c.translate(2.8, 1.4);
          _paintBody(c, p);
        });
        final a = await shot(calm), b = await shot(fury);
        double diff(Rect rig) {
          var sum = 0.0, n = 0;
          for (
            var y = ((rig.top + 1.4) * ppu).round();
            y < ((rig.bottom + 1.4) * ppu).round();
            y++
          ) {
            for (
              var x = ((rig.left + 2.8) * ppu).round();
              x < ((rig.right + 2.8) * ppu).round();
              x++
            ) {
              final i = (y * w + x) * 4;
              if (a[i + 3] < 200 || b[i + 3] < 200) continue;
              sum +=
                  ((a[i] - b[i]).abs() +
                      (a[i + 1] - b[i + 1]).abs() +
                      (a[i + 2] - b[i + 2]).abs()) /
                  3;
              n++;
            }
          }
          return n == 0 ? 0 : sum / n;
        }

        final torso = diff(const Rect.fromLTRB(-1.3, -.7, -.6, .5));
        final plates = diff(const Rect.fromLTRB(-.9, -.9, .9, .9));
        final tail = diff(const Rect.fromLTRB(2.4, 1.0, 3.7, 2.4));
        final thigh = diff(const Rect.fromLTRB(1.2, .5, 1.9, 1.2));
        expect(torso, greaterThan(12), reason: 'torso plates');
        expect(plates, greaterThan(8), reason: 'breastplate');
        expect(tail, greaterThan(12), reason: 'tail');
        expect(thigh, greaterThan(12), reason: 'haunch');
      });
    },
  );

  testWidgets(
    'the body stays inside the envelope in every state, phase and bend',
    (tester) async {
      await tester.runAsync(() async {
        final states = <(String, double, void Function(SkyBoss))>[
          ('idle', 1.2, (b) {}),
          ('charge', 1.2, (b) => b.fireIn = .01),
          ('shot', 1.2, (b) => b.lastVolleyAt = b.age - .04),
          ('recoil', 1.2, (b) => b.lastVolleyAt = b.age - .14),
          ('hit', 1.2, (b) => b.lastHitAt = b.age - .1),
          ('alert', 3.7, (b) {}),
          ('rear', 4.6, (b) {}),
          ('hold', 5.05, (b) {}),
          ('snap', 5.23, (b) {}),
          ('overshoot', 5.33, (b) {}),
          ('thump low', 5.42, (b) => b.breathLane = BreathLane.low),
          ('blast low', 5.6, (b) => b.breathLane = BreathLane.low),
          ('blast high', 5.6, (b) => b.breathLane = BreathLane.high),
          ('plateau', 6.5, (b) {}),
          ('gutter', 7.3, (b) {}),
          ('wind', 7.45, (b) {}),
          ('call', 7.72, (b) => b.lastSummonAt = b.age - .1),
          ('call peak', 7.95, (b) => b.lastSummonAt = b.age - .35),
          ('rage', 1.2, (b) => b.enragedAt = b.age - .3),
        ];
        var union = Rect.zero;
        for (final fury in [false, true]) {
          for (final (name, t, setup) in states) {
            for (var n = 0; n < 12; n++) {
              final pose = _pose(setup, t, fury: fury, cycles: n);
              final r = await _scan(
                (c) => _paintBody(c, DragonBodyPose.of(pose), pose: pose),
              );
              union = union.expandToInclude(r);
              expect(
                r.left,
                greaterThanOrEqualTo(DragonLayout.envelope.left),
                reason: '$name #$n fury $fury',
              );
              expect(
                r.right,
                lessThanOrEqualTo(DragonLayout.envelope.right),
                reason: '$name #$n fury $fury',
              );
              expect(
                r.bottom,
                lessThanOrEqualTo(DragonLayout.envelope.bottom),
                reason: '$name #$n fury $fury',
              );
            }
          }
        }
        // ignore: avoid_print
        print(
          'body union L ${union.left.toStringAsFixed(2)} R ${union.right.toStringAsFixed(2)} B ${union.bottom.toStringAsFixed(2)} vs ${DragonLayout.envelope}',
        );
      });
    },
  );

  testWidgets(
    'the belly-leg-tail gap stays open in rest, alert, hold and blast',
    (tester) async {
      await tester.runAsync(() async {
        const ppu = 40.0, w = 200, h = 160;
        final states = <(String, DragonPose)>[
          ('rest', _pose((b) {}, 1.2)),
          ('alert', _pose((b) {}, 3.7)),
          ('rear', _pose((b) {}, 4.7)),
          ('hold', _pose((b) {}, 5.05)),
          ('snap', _pose((b) {}, 5.24)),
          for (final lane in BreathLane.values)
            ('blast ${lane.name}', _pose((b) => b.breathLane = lane, 5.7)),
          ('fury', _pose((b) {}, 1.2, fury: true)),
        ];
        for (final (name, pose) in states) {
          final d = await _pixels(w, h, (c) {
            c.scale(ppu);
            _paintBody(c, DragonBodyPose.of(pose), pose: pose);
          });
          bool solid(double x, double y) {
            final px = (x * ppu).round(), py = (y * ppu).round();
            if (px < 0 || py < 0 || px >= w || py >= h) return false;
            return d[(py * w + px) * 4 + 3] > 128;
          }

          // On each row under the hips, the empty run between the leg and the
          // tail; the widest of them is the gap (an open row: no tail there).
          var widest = 0.0;
          for (var y = 1.5; y <= 2.3; y += .05) {
            var x = 1.3;
            while (x < 4.4 && !solid(x, y)) {
              x += .025;
            }
            while (x < 4.4 && solid(x, y)) {
              x += .025;
            }
            final start = x;
            while (x < 4.4 && !solid(x, y)) {
              x += .025;
            }
            widest = math.max(widest, x >= 4.4 ? 9.0 : x - start);
          }
          expect(widest, greaterThanOrEqualTo(.5), reason: name);
        }
      });
    },
  );

  test('the body stays inside its per-frame budget', () {
    final states = <(String, DragonPose)>[
      ('rest', _pose((b) {}, 1.2)),
      ('open', _pose((b) {}, 5.0)),
      ('blast', _pose((b) => b.breathLane = BreathLane.low, 5.8)),
      (
        'crit',
        _pose((b) {
          b.lastHitAt = b.lastCoreHitAt = b.age - .1;
        }, 4.8),
      ),
      ('hit', _pose((b) => b.lastHitAt = b.age - .1, 1.2)),
      ('fury', _pose((b) {}, 5.0, fury: true)),
      ('defeat', _pose((b) => b.defeatedAt = b.age - .5, 1.2)),
    ];
    for (final (name, pose) in states) {
      final body = DragonBodyPose.of(pose);
      _paintBody(Canvas(ui.PictureRecorder()), body);
      final before = DragonKit.shadersBuilt;
      final c = _Counting(Canvas(ui.PictureRecorder()));
      _paintBody(c, body, pose: pose);
      final built = DragonKit.shadersBuilt - before;
      // ignore: avoid_print
      print(
        '${name.padRight(7)} ops ${c.draws} clips ${c.clips} shaders built $built',
      );
      expect(c.draws, lessThanOrEqualTo(110), reason: '$name ops');
      expect(c.clips, lessThanOrEqualTo(3), reason: '$name clips');
      expect(
        built,
        lessThanOrEqualTo(4),
        reason: '$name shaders built on a warm frame',
      );
      expect(c.counts['saveLayer'] ?? 0, 0, reason: '$name layers');
      expect(c.counts['maskFilter'] ?? 0, 0, reason: '$name blur');
    }
  });

  testWidgets(
    'identical inputs paint identical pixels; Reduced Motion holds still',
    (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> shot(DragonPose p) => _pixels(360, 360, (c) {
          c.scale(40);
          c.translate(2.5, 2);
          _paintBody(c, DragonBodyPose.of(p), pose: p);
        });
        final a = await shot(_pose((b) {}, 2.3));
        final b = await shot(_pose((b) {}, 2.3));
        expect(a, b, reason: 'deterministic');
        final r1 = await shot(_pose((b) {}, 1.2, reduced: true));
        final r2 = await shot(_pose((b) {}, 2.9, reduced: true));
        expect(r1, r2, reason: 'a Reduced Motion idle is one still frame');
        final inhale = await shot(_pose((b) {}, 5.0, reduced: true));
        expect(
          inhale,
          isNot(r1),
          reason: 'the open chest is a state and still shows',
        );
        final crit = await shot(
          _pose(
            (b) {
              b.lastHitAt = b.lastCoreHitAt = b.age - .1;
            },
            4.8,
            reduced: true,
          ),
        );
        expect(crit, isNot(await shot(_pose((b) {}, 4.8, reduced: true))));
      });
    },
  );

  test('the body reads the channels it should', () {
    final open = DragonBodyPose.of(_pose((b) {}, 5.0));
    expect(open.open, greaterThan(.9));
    final rest = DragonBodyPose.of(_pose((b) {}, 1.2));
    expect(rest.open, 0);
    expect(rest.bend(1), isNot(0.0), reason: 'the tail is alive');
    final still = DragonBodyPose.of(_pose((b) {}, 1.2, reduced: true));
    expect(still.bend(1), 0, reason: 'and still under Reduced Motion');
    expect(still.hindSwing, 0);
    final dead = DragonBodyPose.of(
      _pose((b) => b.defeatedAt = b.age - .5, 1.2),
    );
    expect(dead.crack, greaterThan(0));
    expect(dead.slump, greaterThan(0));
  });

  testWidgets('the neck crest still gets its bone spines', (tester) async {
    await tester.runAsync(() async {
      final r = await _scan((c) {
        DragonBodyArt.spine(c, Offset.zero, .4, -1.5, const DragonTone());
        DragonBodyArt.spine(
          c,
          const Offset(2, 0),
          .3,
          -1.4,
          const DragonTone(),
          shade: .6,
        );
      }, solid: 128);
      expect(r.width, greaterThan(2), reason: '$r');
      expect(r.height, greaterThan(.3), reason: '$r');
    });
  });

  test('every pose across the whole cycle paints without a bad number', () {
    var frames = 0;
    for (final fury in [false, true]) {
      for (final reduced in [false, true]) {
        for (var i = 0; i < 160; i++) {
          final pose = _pose((b) {}, i * .07, fury: fury, reduced: reduced);
          final body = DragonBodyPose.of(pose);
          for (final v in [
            body.time,
            body.breath,
            body.heart,
            body.open,
            body.crit,
            body.crack,
            body.slump,
            body.clutch,
            body.kick,
            body.hindSwing,
            body.foreSwing,
            body.bend(0),
            body.bend(.5),
            body.bend(1),
          ]) {
            expect(v.isFinite, isTrue, reason: 't=${i * .07} fury=$fury');
          }
          final rec = ui.PictureRecorder();
          _paintBody(Canvas(rec), body, pose: pose);
          rec.endRecording().dispose();
          frames++;
        }
      }
    }
    for (var d = 0.0; d < 1.6; d += .1) {
      final pose = _pose((b) => b.defeatedAt = b.age - d, 1.2);
      final rec = ui.PictureRecorder();
      _paintBody(Canvas(rec), DragonBodyPose.of(pose), pose: pose);
      rec.endRecording().dispose();
      frames++;
    }
    expect(frames, greaterThan(600));
  });

  test('a frame of the body records quickly', () {
    final pose = _pose((b) {}, 5.0);
    final body = DragonBodyPose.of(pose);
    for (var i = 0; i < 20; i++) {
      final rec = ui.PictureRecorder();
      _paintBody(Canvas(rec), body, pose: pose);
      rec.endRecording().dispose();
    }
    final watch = Stopwatch()..start();
    const n = 300;
    for (var i = 0; i < n; i++) {
      final rec = ui.PictureRecorder();
      _paintBody(Canvas(rec), body, pose: pose);
      rec.endRecording().dispose();
    }
    final perFrame = watch.elapsedMicroseconds / n;
    // ignore: avoid_print
    print('body records in ${perFrame.toStringAsFixed(0)} us a frame');
    // Generous: CI machines are slow and this is debug-mode Dart.
    expect(perFrame, lessThan(6000));
  });
}
