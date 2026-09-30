import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_body_art.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_head_art.dart';
import 'package:push_up_bird/game/dragon_hide_art.dart';
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

/// The hide (B9): torso, neck, head, tail and near legs painted as ONE
/// creature - one outline, one skin, one light - instead of parts laid over
/// each other.
///
/// Checked here: the parts lie in one path that fills and clips as their
/// union (they all wind the same way); no ink is drawn across any joint
/// (measured on pixels, hide against the classic assembly, at every seam and
/// pose of the sheet); the outline is ONE stroke of the trunk; the belly-leg-
/// tail gap (>= .5) and the throat notch (>= .7) stay open; every feature the
/// parts had survives (eye, jaw opening, mouth interior, circlet); frames are
/// deterministic. The timing probe is `dragon_hide_perf_test.dart`.

// ---------------------------------------------------------------- poses --

SkyBoss _boss([double combat = 1.2]) {
  final boss = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = BreathLane.middle;
  boss.age = boss.arrivalDuration + combat;
  return boss;
}

void _at(SkyBoss b, double t) => b.age = b.arrivalDuration + t;

typedef _S = ({String name, void Function(SkyBoss) setup, double aim});
_S _s(String name, void Function(SkyBoss) setup, [double aim = 0]) =>
    (name: name, setup: setup, aim: aim);

/// The pose sheet's beats that move the joints most.
final _sheet = <_S>[
  _s('idle', (b) {}),
  _s('idle late', (b) => _at(b, 2.6)),
  _s('charge', (b) => b.fireIn = .12),
  _s('alert', (b) => _at(b, 3.8)),
  _s('rear', (b) => _at(b, 4.7)),
  _s('hold', (b) => _at(b, 5.05)),
  _s('snap', (b) => _at(b, 5.26)),
  _s('blast', (b) => _at(b, 5.7)),
  _s('blast low', (b) {
    b.breathLane = BreathLane.low;
    _at(b, 5.7);
  }),
  _s('blast high', (b) {
    b.breathLane = BreathLane.high;
    _at(b, 5.7);
  }),
  _s('snap low', (b) {
    b.breathLane = BreathLane.low;
    _at(b, 5.3);
  }),
  _s('roar', (b) => b.age = SkyBoss.roarAt + .3),
  _s('call', (b) {
    _at(b, 7.95);
    b.lastSummonAt = b.age - .35;
  }),
  _s('hit', (b) => b.lastHitAt = b.age - .1),
  _s('fury', (b) => b.hp = b.maxHp ~/ 3),
  _s('rage', (b) {
    b.hp = b.maxHp ~/ 3;
    b.enragedAt = b.age - .45;
  }),
  _s('defeat', (b) => b.defeatedAt = b.age - .15),
  _s('look up', (b) {}, -1),
  _s('look down', (b) {}, 1),
];

DragonPose _pose(_S s, {double dark = 0, bool reduced = false}) {
  final boss = _boss();
  s.setup(boss);
  return DragonPose(
    boss,
    BossMotion(boss, reducedMotion: reduced),
    lookY: s.aim,
    light: DragonSkyLight(dark: dark),
  );
}

// ------------------------------------------------------------- rendering --

/// Everything the hide paints, and nothing else (no wings, heart or smoke).
const _hideOnly = {
  'farLegs+tail',
  'torso',
  'hindLeg',
  'neck',
  'head',
  'foreleg',
};

const _ppu = 40.0, _x0 = -4.5, _y0 = -4.6, _w = 388, _h = 376;

class _Img {
  _Img(this.data);
  final List<int> data;

  int _i(Offset rig) {
    final x = ((rig.dx - _x0) * _ppu).round(),
        y = ((rig.dy - _y0) * _ppu).round();
    if (x < 0 || y < 0 || x >= _w || y >= _h) return -1;
    return (y * _w + x) * 4;
  }

  int alpha(Offset rig) {
    final i = _i(rig);
    return i < 0 ? 0 : data[i + 3];
  }

  /// CIE L* of the pixel at [rig] (rig units), 100 for empty space.
  double lstar(Offset rig) {
    final i = _i(rig);
    if (i < 0 || data[i + 3] < 128) return 100;
    double lin(int v) {
      final c = v / 255;
      return c <= .04045
          ? c / 12.92
          : math.pow((c + .055) / 1.055, 2.4).toDouble();
    }

    final y =
        .2126 * lin(data[i]) +
        .7152 * lin(data[i + 1]) +
        .0722 * lin(data[i + 2]);
    return y > 216 / 24389 ? 116 * math.pow(y, 1 / 3) - 16 : 903.3 * y;
  }
}

Future<_Img> _render(
  DragonPose pose, {
  bool hide = true,
  Set<String>? only,
  bool crown = true,
  Color? bg,
}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  if (bg != null) {
    c.drawRect(
      Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
      Paint()..color = bg,
    );
  }
  c.scale(_ppu);
  c.translate(-_x0, -_y0);
  DragonBossRig.paintPose(
    c,
    pose,
    hide: hide,
    only: only ?? _hideOnly,
    crown: crown,
  );
  final pic = rec.endRecording();
  final img = await pic.toImage(_w, _h);
  final data = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  pic.dispose();
  return _Img(data);
}

// ----------------------------------------------------------- geometry --

/// Points along [path]'s outline every [step] rig units.
List<Offset> _along(Path path, double step) {
  final out = <Offset>[];
  for (final m in path.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += step) {
      out.add(m.getTangentForOffset(d)!.position);
    }
  }
  return out;
}

void main() {
  DragonHide hideOf(DragonPose pose) =>
      DragonHide(DragonBodyPose.of(pose), DragonHeadPose.of(pose));

  group('one path', () {
    test(
      'every part winds the same way, so the trunk fills as their union',
      () {
        for (final s in _sheet) {
          final hide = hideOf(_pose(s));
          // A point inside two parts must be inside the trunk (opposite
          // windings would cancel it out).
          final parts = <String, Path>{
            'torso': hide.torso,
            'neck': hide.neck.path,
            'tail': hide.tail.shape,
            'skull': hide.skull,
            'jaw': hide.jaw,
          };
          var overlaps = 0;
          for (final a in parts.entries) {
            for (final b in parts.entries) {
              if (a.key.compareTo(b.key) >= 0) continue;
              for (final p in _along(a.value, .05)) {
                if (b.value.contains(p) && !hide.trunk.contains(p)) {
                  fail(
                    '${s.name}: ${a.key} edge inside ${b.key} but outside the '
                    'trunk at $p (opposite windings?)',
                  );
                }
                if (b.value.contains(p)) overlaps++;
              }
            }
          }
          expect(
            overlaps,
            greaterThan(20),
            reason: '${s.name}: the parts overlap',
          );
        }
      },
    );

    test('the kit reads a polygon\'s winding and turns a path exactly', () {
      final cw = [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ];
      expect(DragonKit.winding(cw), isPositive); // clockwise on screen
      expect(DragonKit.winding(cw.reversed.toList()), isNegative);
      final square = Path()..addRect(const Rect.fromLTWH(0, 0, 1, 1));
      final moved = DragonKit.turned(
        square,
        math.pi / 2,
        by: const Offset(3, 0),
      );
      final b = moved.getBounds();
      expect(b.left, closeTo(2, 1e-9));
      expect(b.right, closeTo(3, 1e-9));
      expect(b.top, closeTo(0, 1e-9));
      expect(b.bottom, closeTo(1, 1e-9));
      // Skull and jaw follow the head and open with the gape, as the art does.
      final head = DragonHeadPose.of(_pose(_sheet[0]));
      expect(
        DragonHeadArt.skullAt(head).getBounds().center,
        isNot(DragonHeadArt.jawAt(head).getBounds().center),
      );
    });
  });

  group('the kit\'s hide helpers', () {
    test('a ribbon tapers to a point and keeps its width between', () {
      final pts = [for (var i = 0; i <= 8; i++) Offset(i * .5, 0)];
      final widths = DragonKit.taper(pts.length, .2, head: .25, tail: .25);
      expect(widths.first, 0);
      expect(widths.last, 0);
      expect(widths[4], closeTo(.2, 1e-9));
      expect(widths, everyElement(inInclusiveRange(0, .2)));
      final b = DragonKit.ribbon(pts, widths).getBounds();
      expect(b.left, closeTo(0, 1e-9));
      expect(b.right, closeTo(4, 1e-9));
      expect(b.height, closeTo(.2, .02));
    });

    test('catmull is the curve spline draws', () {
      const pts = [Offset(0, 0), Offset(1, .5), Offset(2, 0), Offset(3, -.5)];
      expect(DragonKit.catmull(pts, 1, 0), pts[1]);
      expect(DragonKit.catmull(pts, 1, 1), pts[2]);
      final spline = DragonKit.spline(pts, closed: false);
      final m = DragonKit.catmull(pts, 1, .5);
      // (the curve passes through its samples: the path contains them in
      // its bounds, and the mid-point lies between the vertices)
      expect(spline.getBounds().contains(m), isTrue);
      expect(m.dx, inExclusiveRange(1, 2));
    });

    test('rows of scale arcs stay inside their tube', () {
      // A straight tube along +x, 1 wide.
      final out = Path();
      DragonKit.tubeRows(
        out,
        (u) => (
          centre: Offset(u, 0),
          normal: const Offset(0, 1),
          plus: .5,
          minus: .5,
        ),
        from: 1,
        to: 6,
        pitchFrom: .25,
        pitchTo: .15,
        bulge: 1,
        reach: .8,
      );
      final b = out.getBounds();
      expect(b.top, greaterThanOrEqualTo(-.5));
      expect(b.bottom, lessThanOrEqualTo(.5 + .4)); // (arcs bow forward)
      expect(b.left, greaterThanOrEqualTo(.95));
      expect(b.right, lessThanOrEqualTo(6.6));
      // Rows, and columns in each: a real pattern, and the pitch shrinks.
      expect(out.computeMetrics().length, greaterThan(25));
    });
  });

  group('every pose of the cycle', () {
    test('the hide builds, fills as a union and paints, calm and in fury', () {
      for (final fury in [false, true]) {
        final boss =
            SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
              ..fireIn = 1.8
              ..breathLane = BreathLane.middle;
        if (fury) boss.hp = boss.maxHp ~/ 3;
        boss.age = boss.arrivalDuration + .1;
        final m = BossMotion(boss, reducedMotion: false);
        for (var i = 0; i < 660; i += 3) {
          boss.age += 3 / 60;
          if (i % 90 == 0) boss.lastVolleyAt = boss.age;
          final pose = DragonPose(boss, m);
          final hide = hideOf(pose);
          final b = hide.trunk.getBounds();
          expect(b.isFinite, isTrue, reason: 'i $i');
          expect(DragonLayout.layerBounds.inflate(.5).overlaps(b), isTrue);
          // Deep inside two parts: inside the union (windings agree).
          expect(
            hide.trunk.contains(hide.neck.spine[1]),
            isTrue,
            reason: 'neck base, i $i',
          );
          expect(
            hide.trunk.contains(hide.tail.spine[2]),
            isTrue,
            reason: 'tail root, i $i',
          );
          expect(hide.trunk.contains(hide.torso.getBounds().center), isTrue);
          final rec = ui.PictureRecorder();
          final canvas = Canvas(rec);
          hide.paint(canvas);
          hide.paintForeleg(canvas);
          rec.endRecording().dispose();
        }
      }
    });
  });

  group('no border across a joint', () {
    testWidgets('no ink is drawn where one part lies inside another', (
      tester,
    ) async {
      await tester.runAsync(() async {
        var classicDark = 0, classicN = 0, hideDark = 0, hideN = 0;
        final report = StringBuffer();
        for (final s in _sheet) {
          final pose = _pose(s);
          final hide = hideOf(pose);
          final shapes = <String, Path>{
            'torso': hide.torso,
            'neck': hide.neck.path,
            'tail': hide.tail.shape,
            'skull': hide.skull,
            'jaw': hide.jaw,
          };
          // (skull/jaw is the mouth: its seam is a deliberate line.)
          bool skip(String a, String b) =>
              (a == 'skull' && b == 'jaw') || (a == 'jaw' && b == 'skull');
          bool deep(Offset p) {
            if (!hide.trunk.contains(p)) return false;
            for (var k = 0; k < 8; k++) {
              final q = p + Offset.fromDirection(k * math.pi / 4, .16);
              if (!hide.trunk.contains(q)) return false;
            }
            return !hide.hind.shape.contains(p) && !hide.fore.shape.contains(p);
          }

          final seam = <Offset>[];
          for (final a in shapes.entries) {
            for (final b in shapes.entries) {
              if (a.key == b.key || skip(a.key, b.key)) continue;
              for (final p in _along(a.value, .07)) {
                if (b.value.contains(p) && deep(p)) seam.add(pose.toRig(p));
              }
            }
          }
          final classic = await _render(pose, hide: false);
          final joined = await _render(pose);
          var cd = 0, hd = 0;
          for (final p in seam) {
            if (classic.lstar(p) < 8) cd++;
            if (joined.lstar(p) < 8) hd++;
          }
          classicDark += cd;
          classicN += seam.length;
          hideDark += hd;
          hideN += seam.length;
          report.writeln(
            '${s.name.padRight(11)} ${seam.length.toString().padLeft(4)} seam pixels: '
            'classic ${cd.toString().padLeft(3)} inked, hide ${hd.toString().padLeft(3)}',
          );
          expect(
            seam.length,
            greaterThan(15),
            reason: '${s.name} has seams to check',
          );
          expect(
            hd / seam.length,
            lessThan(.07),
            reason: '${s.name}: ink across a joint',
          );
        }
        // ignore: avoid_print
        print(report);
        // The test can see the problem: the classic assembly is inked there.
        expect(classicDark / classicN, greaterThan(.25));
        expect(hideDark / hideN, lessThan(.03));
      });
    });

    testWidgets('one outline: a single thick ink stroke of the trunk', (
      tester,
    ) async {
      final pose = _pose(_sheet[0]);
      final spy = _Strokes();
      DragonBossRig.paintPose(spy, pose, only: _hideOnly);
      final heavy = spy.strokes.where((s) => s.ink && s.width >= .14).toList();
      expect(heavy, hasLength(1), reason: 'the trunk is outlined once');
      // ... and the classic assembly strokes its parts many times over.
      final old = _Strokes();
      DragonBossRig.paintPose(old, pose, only: _hideOnly, hide: false);
      expect(
        old.strokes.where((s) => s.ink && s.width >= .06).length,
        greaterThan(6),
      );
    });
  });

  group('the negative spaces stay open', () {
    testWidgets('the belly-leg-tail gap is at least .5 wide', (tester) async {
      await tester.runAsync(() async {
        for (final s in [
          _sheet[0], // idle
          _sheet[3], // alert
          _sheet[4], // rear
          _sheet[5], // hold
          _sheet[6], // snap
          _sheet[7], // blast
          _sheet[8], // blast low
          _sheet[9], // blast high
          _sheet[14], // fury
        ]) {
          final pose = _pose(s);
          final img = await _render(pose);
          bool solid(double x, double y) =>
              img.alpha(pose.toRig(Offset(x, y))) > 128;
          // On each row under the hips: the empty run between the leg and
          // the tail; the widest is the gap.
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
          expect(widest, greaterThanOrEqualTo(.5), reason: '${s.name} gap');
        }
      });
    });

    testWidgets('the throat notch under the jaw is at least .7 deep', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // As the head's own test measures it: the head's lowest point per
        // column against the torso's highest outline point. The geometry is
        // B1's and B2's (what the merge must not fill in); the pixels add the
        // outline, which the head's own measure counted for the head only.
        for (final s in [_sheet[0], _sheet[3]]) {
          final pose = _pose(s, reduced: true);
          final hide = hideOf(pose);
          Map<int, double> extreme(Iterable<Path> paths, bool lowest) {
            final out = <int, double>{};
            for (final path in paths) {
              for (final p in _along(path, .01)) {
                final r = pose.toRig(p);
                final col = (r.dx * 40).round();
                final old = out[col];
                if (old == null || (lowest ? r.dy > old : r.dy < old)) {
                  out[col] = r.dy;
                }
              }
            }
            return out;
          }

          final top = extreme([hide.torso], false);
          final bottom = extreme([hide.skull, hide.jaw], true);
          var geometry = double.infinity;
          for (var x = -1.45; x < -.95; x += .025) {
            final col = (x * 40).round();
            if (top[col] == null || bottom[col] == null) continue;
            geometry = math.min(geometry, top[col]! - bottom[col]!);
          }
          expect(geometry, greaterThanOrEqualTo(.7), reason: '${s.name} notch');

          // In pixels, ink included, against the classic assembly's.
          Future<double> pixels(bool joined) async {
            final img = await _render(pose, hide: joined);
            var notch = double.infinity;
            for (var x = -1.45; x < -.95; x += .025) {
              final col = (x * 40).round();
              if (top[col] == null) continue;
              var y = -4.5;
              while (y < top[col]! && img.alpha(Offset(x, y)) < 128) {
                y += .025;
              }
              if (y >= top[col]!) continue;
              while (y < top[col]! && img.alpha(Offset(x, y)) >= 128) {
                y += .025;
              }
              notch = math.min(notch, top[col]! - y);
            }
            return notch;
          }

          final classic = await pixels(false), merged = await pixels(true);
          // ignore: avoid_print
          print(
            '${s.name}: notch geometry ${geometry.toStringAsFixed(2)}, '
            'pixels classic ${classic.toStringAsFixed(2)} hide ${merged.toStringAsFixed(2)}',
          );
          // (The merged outline lies wholly outside the fill's edge - the
          // classic ink was centred on it - so the visible silhouette grows by
          // the other half of the line, ~.05, and the notch measured in pixels
          // shrinks by that much; the geometry, B1's, is unchanged.)
          expect(merged, greaterThanOrEqualTo(classic - .08), reason: s.name);
          expect(
            merged,
            greaterThanOrEqualTo(.6),
            reason: '${s.name}: still open',
          );
        }
      });
    });
  });

  group('round 3: haze, tail tip, dark-sky rim, cost', () {
    /// The outer contour pixels (opaque, with a clear 4-neighbour) inside
    /// [box] (rig units) and their CIE L*.
    List<double> contour(_Img img, Rect box) {
      final out = <double>[];
      for (
        var y = ((box.top - _y0) * _ppu).round();
        y < ((box.bottom - _y0) * _ppu).round();
        y++
      ) {
        for (
          var x = ((box.left - _x0) * _ppu).round();
          x < ((box.right - _x0) * _ppu).round();
          x++
        ) {
          Offset at(int px, int py) =>
              Offset(px / _ppu + _x0 + .5 / _ppu, py / _ppu + _y0 + .5 / _ppu);
          if (img.alpha(at(x, y)) < 220) continue;
          if (img.alpha(at(x - 1, y)) > 40 &&
              img.alpha(at(x + 1, y)) > 40 &&
              img.alpha(at(x, y - 1)) > 40 &&
              img.alpha(at(x, y + 1)) > 40) {
            continue;
          }
          out.add(img.lstar(at(x, y)));
        }
      }
      return out;
    }

    testWidgets(
      'the tail and its blade share one ink contour (no mauve hairline, no patch)',
      (tester) async {
        await tester.runAsync(() async {
          for (final s in [_sheet[0], _sheet[14], _sheet[13]]) {
            final img = await _render(_pose(s));
            // The blade's tip and the tail's cuff.
            final l = contour(img, const Rect.fromLTRB(2.4, 1.4, 4.5, 3.6));
            expect(l.length, greaterThan(40), reason: s.name);
            final ink = l.where((v) => v < 14).length / l.length;
            // ignore: avoid_print
            print(
              '${s.name.padRight(6)} tail-tip contour ${(ink * 100).toStringAsFixed(0)}% ink of ${l.length} px',
            );
            expect(
              ink,
              greaterThan(.8),
              reason: '${s.name}: the contour is ink',
            );
          }
        });
      },
    );

    test('the far claws are one solid dark shape, not a grey fringe', () {
      final fills = _SolidFills();
      DragonBodyArt.farLegs(fills, const DragonBodyPose());
      expect(fills.count, greaterThan(0));
      for (final c in fills.colors) {
        expect(c.a, 1, reason: 'opaque');
        expect(c.computeLuminance(), lessThan(.06), reason: 'dark: $c');
      }
    });

    testWidgets('on a dark sky the lit upper edge holds without the ink', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const city = Color(0xff2b2450); // a violet dusk city, L* ~ 17
        // First pixel that is no longer backdrop, per column along the torso's
        // back (x .3 .. 1.5, hide only): the lit upper edge; or, from below,
        // the shade edge.
        Future<double> edge(double dark, {required bool top}) async {
          final img = await _render(_pose(_sheet[0], dark: dark), bg: city);
          final ls = <double>[];
          final base = img.lstar(const Offset(-4.4, -4.5));
          for (var x = .3; x <= 1.5; x += .04) {
            final ys = top
                ? [for (var y = -1.3; y < .2; y += 1 / _ppu) y]
                : [for (var y = 3.2; y > 1.0; y -= 1 / _ppu) y];
            for (final y in ys) {
              final l = img.lstar(Offset(x, y));
              if ((l - base).abs() > 2) {
                ls.add(l);
                break;
              }
            }
          }
          ls.sort();
          return ls[ls.length ~/ 2];
        }

        final plain = await edge(0, top: true);
        final rim = await edge(.93, top: true);
        final shade = await edge(.93, top: false);
        // ignore: avoid_print
        print(
          'lit edge L* over a L*17 city: ink only ${plain.toStringAsFixed(1)}, '
          'rim ${rim.toStringAsFixed(1)}; shade edge ${shade.toStringAsFixed(1)}',
        );
        expect(
          rim - plain,
          greaterThan(14),
          reason: 'the rim lifts the lit edge',
        );
        expect(
          rim,
          greaterThan(34),
          reason: 'dL >= 17 over the backdrop at the edge',
        );
        expect(
          shade,
          lessThan(16),
          reason: 'the shade side keeps its plain ink',
        );
      });
    });

    test(
      'the tone snaps to the steps of its cache key (order independence)',
      () {
        const a = DragonTone(flash: .50, fury: .53, heat: .28, dark: .60);
        const b = DragonTone(flash: .56, fury: .56, heat: .31, dark: .62);
        expect(a.key, b.key, reason: 'same cache key');
        final sa = DragonBodyArt.snap(a), sb = DragonBodyArt.snap(b);
        expect(
          (sa.flash, sa.fury, sa.heat, sa.dark),
          (sb.flash, sb.fury, sb.heat, sb.dark),
        );
        final again = DragonBodyArt.snap(sa);
        expect(again.key, sa.key);
        expect(again.flash, sa.flash);
      },
    );

    test('the body keeps a hierarchy of bold spikes, not a rash', () {
      // Counted as fills of the two bone shades the thorns use.
      final counter = _BoneCount();
      const p = DragonBodyPose();
      DragonBodyArt.tail(counter, p);
      DragonBodyArt.heart(counter, p);
      DragonBodyArt.front(counter, p);
      DragonBodyArt.foreleg(counter, p);
      // ignore: avoid_print
      print('bone-shaded thorn fills: ${counter.thorns}');
      expect(counter.thorns, inInclusiveRange(3, 5));
    });

    test(
      'the heart\'s glow stays inside its ring: it cannot tint the outline',
      () {
        // Painted after the hide, a glow past r 1.3 dyes the ink at the neck's
        // base and the back spine muddy brown.
        const open = DragonBodyPose(heart: 1, open: 1);
        final counter = _Glows();
        DragonBodyArt.heart(counter, open);
        // ignore: avoid_print
        print(
          'largest heart glow radius: ${counter.largest.toStringAsFixed(2)}',
        );
        expect(counter.largest, lessThanOrEqualTo(1.3));
      },
    );
  });

  group('everything the parts had survives', () {
    testWidgets('the eye burns, the jaws open, the circlet is worn', (
      tester,
    ) async {
      await tester.runAsync(() async {
        int count(_Img img, Rect rig, bool Function(int r, int g, int b) test) {
          var n = 0;
          for (var y = rig.top; y < rig.bottom; y += 1 / _ppu) {
            for (var x = rig.left; x < rig.right; x += 1 / _ppu) {
              final i = img._i(Offset(x, y));
              if (i >= 0 &&
                  img.data[i + 3] > 200 &&
                  test(img.data[i], img.data[i + 1], img.data[i + 2])) {
                n++;
              }
            }
          }
          return n;
        }

        double meanL(_Img img, Rect rig) {
          var sum = 0.0, n = 0;
          for (var y = rig.top; y < rig.bottom; y += 1 / _ppu) {
            for (var x = rig.left; x < rig.right; x += 1 / _ppu) {
              sum += img.lstar(Offset(x, y));
              n++;
            }
          }
          return sum / n;
        }

        final report = StringBuffer();
        for (final s in _sheet) {
          if (s.name == 'defeat') continue;
          final pose = _pose(s);
          final classic = await _render(pose, hide: false);
          final joined = await _render(pose);
          final eye = DragonBossRig.eyeAt(pose);
          final box = Rect.fromCenter(center: eye, width: .9, height: .7);
          bool bright(int r, int g, int b) => r > 200 && g > 150;
          final a = count(classic, box, bright), b = count(joined, box, bright);
          final la = meanL(classic, box), lb = meanL(joined, box);
          report.writeln(
            '${s.name.padRight(11)} eye box: bright ${a.toString().padLeft(3)} -> '
            '${b.toString().padLeft(3)}, mean L* ${la.toStringAsFixed(1)} -> ${lb.toStringAsFixed(1)}',
          );
          // The eye keeps its brightness (or, under a wince, its darkness).
          expect(
            (lb - la).abs(),
            lessThan(14),
            reason: '${s.name}: the eye box',
          );
          // (A winced eye leaves a 36-41 px sliver in the classic render, not an
          // eye: only the states with an open eye, 73+ px, are counted.)
          if (a > 60) {
            expect(b, greaterThan(a * .7), reason: '${s.name}: the eye burns');
          }
          // The circlet: gold above the brow.
          final seat = DragonBossRig.crownAt(pose).at;
          final crown = Rect.fromCenter(center: seat, width: 1.2, height: .8);
          bool gold(int r, int g, int b) => r > 200 && g > 140;
          expect(
            count(joined, crown, gold),
            greaterThan(count(classic, crown, gold) * .8),
            reason: '${s.name}: the circlet',
          );
        }
        // ignore: avoid_print
        print(report);
        // The jaws open: the mouth's dark red inside appears with the gape.
        final shut = _pose(_sheet[0]), wide = _pose(_sheet[11]);
        final mouthShut = DragonBossRig.mouthAt(shut);
        final mouthWide = DragonBossRig.mouthAt(wide);
        bool inside(int r, int g, int b) =>
            r > 55 && r < 200 && r > 2.2 * g && b < 90;
        final imgShut = await _render(shut), imgWide = await _render(wide);
        expect(
          count(
            imgWide,
            Rect.fromCenter(
              center: mouthWide + const Offset(.5, .2),
              width: 1.6,
              height: 1.2,
            ),
            inside,
          ),
          greaterThan(
            count(
                  imgShut,
                  Rect.fromCenter(
                    center: mouthShut + const Offset(.5, .2),
                    width: 1.6,
                    height: 1.2,
                  ),
                  inside,
                ) +
                30,
          ),
        );
      });
    });

    testWidgets('the belly is a warm ribbon, not the biggest bright shape', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // Sample the plates under the keel and along the chest: the median
        // L* holds near 66 (R2), well under the face's iris (>= 90) and the
        // gem, and nowhere near the old cream (L* 77-80).
        final img = await _render(_pose(_sheet[0]));
        final ls = <double>[];
        for (final p in const [
          Offset(-.75, 1.30),
          Offset(-.55, 1.42),
          Offset(-.40, 1.36),
          Offset(-.20, 1.34),
          Offset(0, 1.30),
          Offset(.15, 1.22),
        ]) {
          final l = img.lstar(p);
          if (l < 100) ls.add(l);
        }
        expect(ls.length, greaterThanOrEqualTo(4));
        ls.sort();
        final median = ls[ls.length ~/ 2];
        // ignore: avoid_print
        print('belly median L* ${median.toStringAsFixed(1)} from $ls');
        // The band sits at the palette's belly tone (L* 68 in the R2 palette,
        // whose lit stop is only mixed in), a step under bellyLit: never the
        // old cream, which was the largest bright shape on the figure.
        double lstarOf(Color c) {
          final y = c.computeLuminance();
          return y > 216 / 24389 ? 116 * math.pow(y, 1 / 3) - 16 : 903.3 * y;
        }

        expect(median, lessThan(lstarOf(DragonPalette.belly) + 6));
        expect(median, lessThan(lstarOf(DragonPalette.bellyLit)));
        expect(median, greaterThan(50));
      });
    });

    test(
      'every cache the hide and the body own stays bounded (x100 cycles)',
      () {
        // A long fight walks the tone through every heat, fury, flash and
        // darkness step. LRU caches evict one entry at a time: they never grow
        // past their bound and never clear in one frame.
        var frames = 0;
        final rec0 = DragonHide.cacheSize + DragonBodyArt.cacheSize;
        for (var n = 0; n < 100; n++) {
          final dark = (n % 5) / 4;
          for (var t = 0.0; t < DragonBreath.period; t += .25) {
            final boss = _boss(t);
            if (n.isOdd) boss.hp = boss.maxHp ~/ 3;
            if ((n + t * 4).round() % 7 == 0) boss.lastHitAt = boss.age - .1;
            final pose = DragonPose(
              boss,
              BossMotion(boss, reducedMotion: false),
              light: DragonSkyLight(dark: dark),
            );
            final r = ui.PictureRecorder();
            DragonBossRig.paintPose(Canvas(r), pose);
            r.endRecording().dispose();
            frames++;
          }
          expect(
            DragonHide.cacheSize,
            lessThanOrEqualTo(96),
            reason: 'cycle $n',
          );
          expect(
            DragonBodyArt.cacheSize,
            lessThanOrEqualTo(24),
            reason: 'cycle $n',
          );
        }
        expect(frames, greaterThan(4000));
        // ignore: avoid_print
        print(
          'caches after 100 cycles: hide ${DragonHide.cacheSize} '
          '(was $rec0 in total), body ${DragonBodyArt.cacheSize}',
        );
      },
    );

    test('a NaN or infinite input never reaches the canvas', () {
      const nan = double.nan, inf = double.infinity;
      final head = DragonHeadPose.of(_pose(_sheet[0]));
      final bad = DragonBodyPose(
        time: nan,
        breath: inf,
        heart: nan,
        open: -inf,
        crit: nan,
        crack: inf,
        slump: nan,
        clutch: inf,
        kick: nan,
        hindSwing: inf,
        foreSwing: nan,
        bend: (u) => nan,
        tailSway: inf,
        tone: const DragonTone(flash: nan, fury: inf, heat: nan, dark: inf),
      );
      final r = ui.PictureRecorder();
      final c = Canvas(r);
      DragonBodyArt.back(c, bad);
      DragonBodyArt.torsoPaint(c, bad);
      DragonBodyArt.front(c, bad);
      DragonBodyArt.heart(c, bad);
      DragonBodyArt.foreleg(c, bad);
      final hide = DragonHide(bad, head);
      hide.paint(c);
      hide.paintForeleg(c);
      r.endRecording().dispose();
      // ...and the hide's own shapes are finite.
      final b = hide.trunk.getBounds();
      expect(b.isFinite, isTrue, reason: '$b');
    });

    test('the mouth anchor is still the rules\' fireball point', () {
      // (dragon_boss_test holds the rules; the hide must not move the rig's.)
      final pose = _pose(_sheet[2]);
      final m = DragonBossRig.mouthAt(pose);
      expect((m - DragonLayout.rulesMouth).distance, lessThan(.1));
    });

    testWidgets(
      'frames are deterministic and Reduced Motion is one still frame',
      (tester) async {
        await tester.runAsync(() async {
          final a = await _render(_pose(_sheet[6]));
          await _render(_pose(_sheet[14]));
          final b = await _render(_pose(_sheet[6]));
          expect(b.data, a.data);
          final r1 = await _render(_pose(_sheet[0], reduced: true));
          final r2 = await _render(_pose(_sheet[1], reduced: true));
          expect(r2.data, r1.data);
        });
      },
    );
  });
}

/// Records the strokes a frame makes (their width and whether they are ink).
class _Strokes implements Canvas {
  final strokes = <({double width, bool ink})>[];

  void _paint(Paint p) {
    if (p.style == PaintingStyle.stroke && p.shader == null) {
      strokes.add((
        width: p.strokeWidth,
        ink: p.color.toARGB32() == DragonPalette.ink.toARGB32(),
      ));
    }
  }

  @override
  void drawPath(Path path, Paint paint) => _paint(paint);
  @override
  void drawCircle(Offset c, double radius, Paint paint) => _paint(paint);
  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) =>
      _paint(paint);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Counts the fills of the two bone shades the body's thorns wear.
class _BoneCount implements Canvas {
  int thorns = 0;
  @override
  void drawPath(Path path, Paint paint) {
    if (paint.style != PaintingStyle.fill || paint.shader != null) return;
    final c = paint.color.toARGB32();
    final deep = DragonPalette.boneDeep.toARGB32();
    final mix = Color.lerp(
      DragonPalette.boneDeep,
      DragonPalette.bone,
      .4,
    )!.toARGB32();
    if (c == deep || c == mix) thorns++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Records the radius of every circle drawn with a radial shader (the glows).
class _Glows implements Canvas {
  double largest = 0, _scale = 1;
  final _stack = <double>[];
  @override
  void save() => _stack.add(_scale);
  @override
  void restore() => _scale = _stack.removeLast();
  @override
  void scale(double sx, [double? sy]) => _scale *= sx;
  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    if (paint.shader != null && radius * _scale > largest) {
      largest = radius * _scale;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The solid (shader-less) fills a painter makes.
class _SolidFills implements Canvas {
  final colors = <Color>[];
  int get count => colors.length;
  @override
  void drawPath(Path path, Paint paint) {
    if (paint.style == PaintingStyle.fill && paint.shader == null) {
      colors.add(paint.color);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
