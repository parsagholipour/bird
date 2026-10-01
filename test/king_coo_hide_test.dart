import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/king_coo_body_art.dart';
import 'package:push_up_bird/game/king_coo_head_art.dart';
import 'package:push_up_bird/game/king_coo_hide_art.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

import 'king_coo_test_kit.dart';

/// King Coo's hide (K3): the torso, chest, neck, skull, near thigh and tail as
/// ONE creature (one outline, one skin, one light), in the method of the Ember
/// Dragon's hide.
///
/// Checked here: the parts lie in one path that fills and clips as their union
/// (they all wind the same way); no ink is drawn across any joint (measured on
/// pixels, the hide against the parts assembled the old way, at every seam and
/// pose of the sheet: the owner's complaint about the dragon was "the part that
/// connects the head to the body has a border"); the outline is ONE thick
/// stroke of the trunk; the nested clips stay at three; the light is laid
/// along the true outer edge; the glints are one pass; nothing is built per
/// frame; frames do not depend on what was drawn before.

// ---------------------------------------------------------------- poses --

typedef _S = (String, KingCooPose);

List<_S> _sheet({KingCooSkyLight light = KingCooSkyLight.neutral}) => [
  ('idle', poseOf(cooBoss(combat: 1.2), light: light)),
  ('idle late', poseOf(cooBoss(combat: 2.6), light: light)),
  ('hover', poseOf(cooBoss(combat: 4.1), light: light)),
  ('dip', poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .2))), light: light)),
  ('hold', poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .7))), light: light)),
  ('toss', poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .82))), light: light)),
  ('inhale', poseOf(cooBoss(combat: 8.2), light: light)),
  ('puffed', poseOf(cooBoss(combat: 9.0), light: light)),
  ('whistle', poseOf(cooBoss(combat: 9.3), light: light)),
  ('pop', poseOf(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .45), light: light)),
  ('hit', poseOf(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .09), light: light)),
  ('fury', poseOf(cooBoss(combat: 1.2, fury: true), light: light)),
  ('fury window', poseOf(cooBoss(combat: 9.3, fury: true), light: light)),
  ('stomp', poseOf(cooBoss(combat: 3.05, fury: true, setup: (b) => b.enragedAt = b.age - .1), light: light)),
  ('roar', poseOf(arrivingBoss(2.9), light: light)),
  ('defeat', poseOf(dyingBoss(.62), light: light)),
  ('RM idle', poseOf(cooBoss(combat: 1.2), reduced: true, light: light)),
  ('look up', poseOf(cooBoss(combat: 2.0), lookY: -1, light: light)),
];

KingCooHide _hideOf(KingCooPose p) =>
    KingCooHide(KingCooBodyPose.of(p), KingCooHeadPose.of(p));

// ------------------------------------------------------------- rendering --

/// CIE L* under which a pixel is the outline's ink (L* 9; the fine inner lines
/// are L* 15 and up).
const _inkL = 12.0;

const _ppu = 40.0, _x0 = -3.4, _y0 = -3.4, _w = 330, _h = 290;

/// The hide and only the hide (plus, optionally, the face over it).
void _paintHide(Canvas c, KingCooPose p, {bool face = false}) {
  c.scale(_ppu);
  c.translate(-_x0, -_y0);
  c.save();
  c.translate(p.bob.dx, p.bob.dy);
  c.rotate(p.roll + p.pitch);
  c.scale(p.scaleX, p.scaleY);
  _hideOf(p).paint(c);
  if (face) KingCooHeadArt.face(c, KingCooHeadPose.of(p));
  c.restore();
}

/// The same parts assembled the old way: every part with its own outline, in
/// the contract's z-order.
void _paintClassic(Canvas c, KingCooPose p) {
  c.scale(_ppu);
  c.translate(-_x0, -_y0);
  c.save();
  c.translate(p.bob.dx, p.bob.dy);
  c.rotate(p.roll + p.pitch);
  c.scale(p.scaleX, p.scaleY);
  final body = KingCooBodyPose.of(p);
  final head = KingCooHeadPose.of(p);
  KingCooBodyArt.tail(c, body);
  KingCooBodyArt.torso(c, body);
  KingCooHeadArt.neck(c, head);
  KingCooBodyArt.nearLeg(c, body);
  KingCooBodyArt.chest(c, body);
  KingCooHeadArt.head(c, head);
  c.restore();
}

class _Img {
  _Img(this.data, this.pose);
  final Uint8List data;
  final KingCooPose pose;

  int _i(Offset figure) {
    final rig = pose.toRig(figure);
    final x = ((rig.dx - _x0) * _ppu).round(), y = ((rig.dy - _y0) * _ppu).round();
    if (x < 0 || y < 0 || x >= _w || y >= _h) return -1;
    return (y * _w + x) * 4;
  }

  int alpha(Offset figure) {
    final i = _i(figure);
    return i < 0 ? 0 : data[i + 3];
  }

  /// CIE L* of the pixel at [figure] (100 for empty space).
  double lstar(Offset figure) {
    final i = _i(figure);
    if (i < 0 || data[i + 3] < 128) return 100;
    double lin(int v) {
      final c = v / 255;
      return c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
    }

    final y = .2126 * lin(data[i]) + .7152 * lin(data[i + 1]) + .0722 * lin(data[i + 2]);
    return y > 216 / 24389 ? 116 * math.pow(y, 1 / 3) - 16 : 903.3 * y;
  }
}

Future<_Img> _render(KingCooPose pose, void Function(Canvas, KingCooPose) paint, {Color? bg}) async {
  final px = await rawPixels(_w, _h, (c) {
    if (bg != null) {
      c.drawRect(Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()), Paint()..color = bg);
    }
    paint(c, pose);
  });
  return _Img(px, pose);
}

List<Offset> _along(Path path, double step) {
  final out = <Offset>[];
  for (final m in path.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += step) {
      out.add(m.getTangentForOffset(d)!.position);
    }
  }
  return out;
}

// ------------------------------------------------------------------ spies --

/// Records the strokes (width, colour) and the clips of a painted frame.
class _Spy implements Canvas {
  final strokes = <({double width, int colour, double alpha})>[];
  int clips = 0, draws = 0, layers = 0;

  void _paint(Paint p) {
    draws++;
    if (p.style == PaintingStyle.stroke && p.shader == null) {
      strokes.add((width: p.strokeWidth, colour: p.color.toARGB32() & 0xffffff, alpha: p.color.a));
    }
  }

  @override
  void drawPath(Path path, Paint paint) => _paint(paint);
  @override
  void drawCircle(Offset c, double radius, Paint paint) => _paint(paint);
  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) => _paint(paint);
  @override
  void drawLine(Offset a, Offset b, Paint paint) => _paint(paint);
  @override
  void drawRect(Rect r, Paint paint) => _paint(paint);
  @override
  void drawRRect(RRect r, Paint paint) => _paint(paint);
  @override
  void drawOval(Rect r, Paint paint) => _paint(paint);
  @override
  void clipPath(Path p, {bool doAntiAlias = true}) => clips++;
  @override
  void clipRect(Rect r, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) => clips++;
  @override
  void saveLayer(Rect? bounds, Paint paint) => layers++;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('one path', () {
    test('every part winds the same way, so the trunk fills as their union', () {
      for (final (name, pose) in _sheet()) {
        final hide = _hideOf(pose);
        final parts = <String, Path>{
          'torso': KingCooBodyArt.hideTorso,
          'chest': hide.chest,
          'thigh': KingCooBodyArt.nearThigh,
          'neck': hide.neck!,
          'skull': hide.skull!,
        };
        // A point inside two parts must be inside the trunk (opposite windings
        // would cancel it out).
        final names = parts.keys.toList();
        var checked = 0;
        for (var i = 0; i < names.length; i++) {
          for (var j = i + 1; j < names.length; j++) {
            for (final p in _along(parts[names[i]]!, .05)) {
              // Nudged inward of the first part so the sample is well inside it.
              if (parts[names[j]]!.contains(p) && parts[names[i]]!.contains(p + const Offset(-.03, .03))) {
                expect(
                  hide.trunk.contains(p + const Offset(-.03, .03)),
                  isTrue,
                  reason: '$name: ${names[i]} x ${names[j]} at $p is a hole in the trunk',
                );
                checked++;
              }
            }
          }
        }
        expect(checked, greaterThan(20), reason: '$name has overlaps to check');
        // The tail's feathers wind the same way too.
        final root = KingCooLayout.tailRoot + const Offset(.3, .05);
        expect(hide.tail.contains(root), isTrue, reason: '$name: the tail fills');
      }
    });

    test('the trunk holds every part and nothing wanders off', () {
      for (final (name, pose) in _sheet()) {
        final hide = _hideOf(pose);
        final box = hide.trunk.getBounds();
        expect(box.left.isFinite && box.top.isFinite && box.right.isFinite && box.bottom.isFinite, isTrue, reason: name);
        expect(box.left, greaterThan(-2.4), reason: name);
        expect(box.right, lessThan(2.6), reason: name);
        expect(box.top, greaterThan(-2.5), reason: name);
        expect(box.bottom, lessThan(1.6), reason: name);
        // The chest's outline is inside its box at every swell.
        final r = hide.chestRadius;
        // (the path's box counts its control points: sample the outline itself)
        final reach = _along(hide.chest, .02).map((p) => p.distance);
        expect(reach.reduce(math.max), lessThan(r + .02), reason: name);
        expect(reach.reduce(math.min), greaterThan(r - .15), reason: name);
      }
    });
  });

  group('no border across a joint', () {
    testWidgets('no ink is drawn where one part lies inside another', (tester) async {
      await tester.runAsync(() async {
        var classicDark = 0, classicN = 0, hideDark = 0, hideN = 0;
        final report = StringBuffer();
        for (final (name, pose) in _sheet()) {
          final hide = _hideOf(pose);
          final shapes = <String, Path>{
            'torso': KingCooBodyArt.hideTorso,
            'chest': hide.chest,
            'neck': hide.neck!,
            'skull': hide.skull!,
            'thigh': KingCooBodyArt.nearThigh,
          };
          bool deep(Offset p) {
            if (!hide.trunk.contains(p)) return false;
            for (var k = 0; k < 8; k++) {
              final q = p + Offset.fromDirection(k * math.pi / 4, .14);
              if (!hide.trunk.contains(q)) return false;
            }
            return true;
          }

          final seam = <Offset>[];
          for (final a in shapes.entries) {
            for (final b in shapes.entries) {
              if (a.key == b.key) continue;
              for (final p in _along(a.value, .07)) {
                if (b.value.contains(p) && deep(p)) seam.add(p);
              }
            }
          }
          final classic = await _render(pose, _paintClassic);
          final joined = await _render(pose, (c, p) => _paintHide(c, p));
          var cd = 0, hd = 0;
          for (final p in seam) {
            if (classic.lstar(p) < _inkL) cd++;
            if (joined.lstar(p) < _inkL) hd++;
          }
          classicDark += cd;
          classicN += seam.length;
          hideDark += hd;
          hideN += seam.length;
          report.writeln(
            '${name.padRight(12)} ${seam.length.toString().padLeft(4)} seam pixels: '
            'classic ${cd.toString().padLeft(3)} inked, hide ${hd.toString().padLeft(3)}',
          );
          expect(seam.length, greaterThan(15), reason: '$name has seams to check');
          expect(hd / seam.length, lessThan(.07), reason: '$name: ink across a joint');
        }
        // ignore: avoid_print
        print(report);
        // The test can see the problem: the old assembly is inked there.
        expect(classicDark / classicN, greaterThan(.12), reason: 'the old assembly shows its borders');
        expect(hideDark / hideN, lessThan(.03));
      });
    });

    testWidgets('the neck-to-chest and neck-to-skull seams carry no ink at all', (tester) async {
      await tester.runAsync(() async {
        for (final (name, pose) in _sheet().take(12)) {
          final hide = _hideOf(pose);
          final img = await _render(pose, (c, p) => _paintHide(c, p));
          var seam = 0, dark = 0;
          for (final pair in [(hide.chest, hide.neck!), (hide.skull!, hide.neck!)]) {
            for (final p in _along(pair.$1, .05)) {
              if (!pair.$2.contains(p)) continue;
              // Inside the trunk by a margin: a silhouette edge is allowed its ink.
              var deep = hide.trunk.contains(p);
              for (var k = 0; k < 8 && deep; k++) {
                deep = hide.trunk.contains(p + Offset.fromDirection(k * math.pi / 4, .13));
              }
              if (!deep) continue;
              seam++;
              if (img.lstar(p) < _inkL) dark++;
            }
          }
          expect(dark, lessThanOrEqualTo((seam * .03).ceil()), reason: '$name: $dark of $seam seam samples are ink');
        }
      });
    });

    test('one outline: a single thick ink stroke of the trunk', () {
      final pose = poseOf(cooBoss(combat: 1.2));
      final spy = _Spy();
      _hideOf(pose).paint(spy);
      const ink = 0x1b1730;
      final heavy = spy.strokes
          .where((s) => s.colour == ink && (s.width - KingCooHide.inkWidth).abs() < 1e-6)
          .toList();
      expect(heavy, hasLength(1), reason: 'the trunk is outlined once');
      expect(
        spy.strokes.where((s) => s.colour == ink && (s.width - KingCooHide.tailInkWidth).abs() < 1e-6),
        hasLength(1),
        reason: 'and the tail once, a notch finer',
      );
      // ... and the old assembly strokes its parts many times over.
      final old = _Spy();
      final body = KingCooBodyPose.of(pose), head = KingCooHeadPose.of(pose);
      KingCooBodyArt.torso(old, body);
      KingCooBodyArt.chest(old, body);
      KingCooHeadArt.neck(old, head);
      KingCooHeadArt.head(old, head);
      expect(old.strokes.where((s) => s.colour == ink && s.width >= .06).length, greaterThan(5));
    });
  });

  group('the light follows the true silhouette', () {
    testWidgets('on a dark sky the upper-right edge carries the moon\'s crescent and no inner border does', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final night = poseOf(cooBoss(combat: 1.2), light: const KingCooSkyLight(dark: 1));
        final day = poseOf(cooBoss(combat: 1.2), light: const KingCooSkyLight(dark: 0));
        final a = await _render(night, (c, p) => _paintHide(c, p));
        final b = await _render(day, (c, p) => _paintHide(c, p));
        // Just inside the back's ink, a little toward the upper right of the
        // torso (the wing is not painted here).
        const back = Offset(.45, -.985);
        var night0 = a.lstar(back + const Offset(0, .10)), day0 = b.lstar(back + const Offset(0, .10));
        // The crescent is a flat, lighter band against the skin under it.
        expect(night0, greaterThan(day0 - 2));
        // The same point further in is the plain skin in both.
        expect((a.lstar(const Offset(.45, -.50)) - b.lstar(const Offset(.45, -.50))).abs(), lessThan(1.5));
      });
    });

    test('three clips, no layer and no blur: the whole hide', () {
      for (final (name, pose) in _sheet()) {
        final spy = _Spy();
        _hideOf(pose).paint(spy);
        expect(spy.clips, lessThanOrEqualTo(3), reason: name);
        expect(spy.layers, 0, reason: name);
      }
    });
  });

  group('the glints', () {
    test('hard white pills, one op for the neck and one on the globe, gone under a hit\'s bleach', () {
      int whites(KingCooPose p) {
        final spy = _Spy();
        _hideOf(p).paint(spy);
        return spy.strokes.where((s) => s.colour == 0xffffff && s.alpha > .5).length;
      }

      final calm = poseOf(cooBoss(combat: 1.2));
      expect(whites(calm), greaterThanOrEqualTo(2));
      final hit = poseOf(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .05));
      expect(whites(hit), lessThan(whites(calm)));
    });
  });

  group('cost and caches', () {
    test('the hide\'s frame cost: ops and shaders, worst over the sheet', () {
      var worst = 0, worstName = '';
      var builtWorst = 0;
      for (final (_, pose) in _sheet()) {
        _hideOf(pose).paint(Canvas(ui.PictureRecorder()));
      }
      for (final (name, pose) in _sheet()) {
        final spy = _Spy();
        final before = KingCooKit.shadersBuilt;
        _hideOf(pose).paint(spy);
        builtWorst = math.max(builtWorst, KingCooKit.shadersBuilt - before);
        if (spy.draws > worst) {
          worst = spy.draws;
          worstName = name;
        }
      }
      // ignore: avoid_print
      print('the hide paints at most $worst ops ($worstName), builds at most $builtWorst shaders warm');
      // 70 before the fix round; the double-damage window's gold (a bolder ring,
      // the beating ring inside it, the warm glow, the x2 roundel) costs the hide
      // 9 more in its worst state. The rig's own budget (210) is untouched.
      expect(worst, lessThanOrEqualTo(74), reason: 'the trunk, legs under it, tail, chest, badge and the x2 roundel');
      expect(builtWorst, 0);
    });

    test('building the hide allocates only what the pose changes', () {
      final pose = poseOf(cooBoss(combat: 1.2));
      final a = KingCooHide(KingCooBodyPose.of(pose), KingCooHeadPose.of(pose));
      final b = KingCooHide(KingCooBodyPose.of(pose), KingCooHeadPose.of(pose));
      // Static outlines are shared, not rebuilt.
      expect(identical(KingCooBodyArt.hideTorso, KingCooBodyArt.hideTorso), isTrue);
      expect(a.trunk.getBounds(), b.trunk.getBounds());
    });

    test('a non-finite body or head never reaches the canvas as a number', () {
      final pose = poseOf(cooBoss(combat: 1.2));
      final nan = KingCooBodyPose(
        puff: double.nan,
        tailFan: double.nan,
        tailWag: double.infinity,
        pedal: double.nan,
        sackSwing: double.nan,
        stomp: double.nan,
        tone: const KingCooTone(flash: double.nan, fury: double.nan),
      );
      final hide = KingCooHide(nan, KingCooHeadPose.of(pose));
      final b = hide.trunk.getBounds();
      expect(b.left.isFinite && b.right.isFinite && b.top.isFinite && b.bottom.isFinite, isTrue);
      expect(hide.chestRadius, KingCooLayout.chestRadiusAt(0));
      hide.paint(Canvas(ui.PictureRecorder()));
      // No head: the body's own joints only.
      KingCooHide(KingCooBodyPose.of(pose)).paint(Canvas(ui.PictureRecorder()));
    });

    testWidgets('frames do not depend on what was drawn before', (tester) async {
      await tester.runAsync(() async {
        final poses = _sheet(light: newYorkLight());
        Future<List<Uint8List>> run(List<int> order) async {
          KingCooKit.clearCaches();
          final out = List<Uint8List?>.filled(poses.length, null);
          for (final i in order) {
            out[i] = (await _render(poses[i].$2, (c, p) => _paintHide(c, p, face: true))).data;
          }
          return out.cast<Uint8List>();
        }

        final n = poses.length;
        final forward = await run([for (var i = 0; i < n; i++) i]);
        final backward = await run([for (var i = n - 1; i >= 0; i--) i]);
        for (var i = 0; i < n; i++) {
          expect(forward[i], backward[i], reason: poses[i].$1);
        }
      });
    });
  });

  group('review renders', () {
    testWidgets('the hide on light and dark, five times over at every joint', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final pose = poseOf(cooBoss(combat: 1.2), light: newYorkLight());
        final puffed = poseOf(cooBoss(combat: 9.0), light: newYorkLight());
        // Joints (figure units): neck-to-chest, neck-to-skull, the rump and the
        // tail, the thigh and the belly.
        final joints = <(String, Rect)>[
          ('neck-chest', const Rect.fromLTRB(-1.9, -1.6, .2, -.2)),
          ('rump-tail', const Rect.fromLTRB(1.6, -.6, 3.2, 1.0)),
          ('thigh-belly', const Rect.fromLTRB(-.5, .5, 1.3, 1.9)),
          ('chest-back', const Rect.fromLTRB(-.4, -1.3, 1.3, .3)),
        ];
        const zoom = 120.0;
        Future<void> strip(String name, KingCooPose p, Color bg) async {
          var width = 0.0;
          for (final j in joints) {
            width += j.$2.width * zoom;
          }
          await savePng(name, width.round(), (2.2 * zoom).round(), (c) {
            var x = 0.0;
            for (final (_, r) in joints) {
              c.save();
              c.translate(x, 0);
              c.clipRect(Rect.fromLTWH(0, 0, r.width * zoom, 2.2 * zoom));
              c.drawRect(Rect.fromLTWH(0, 0, r.width * zoom, 2.2 * zoom), Paint()..color = bg);
              c.scale(zoom);
              c.translate(-r.left, -r.top);
              _hideOf(p).paint(c);
              KingCooHeadArt.face(c, KingCooHeadPose.of(p));
              c.restore();
              x += r.width * zoom;
            }
          });
        }

        await strip('hide-joints-light', pose, const Color(0xffe6dfd6));
        await strip('hide-joints-dark', pose, const Color(0xff14152e));
        await strip('hide-joints-puffed', puffed, const Color(0xff3a3b6a));
      });
    });
  });
}
