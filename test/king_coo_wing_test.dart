import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/king_coo_wing_art.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'king_coo_test_kit.dart';

/// K4: King Coo's wings (`lib/game/king_coo_wing_art.dart`).
///
/// What this pins, beyond the contract's envelope / budget / determinism /
/// silhouette tests (which run against the same art):
///  * the wing's TIP is the pose's `handAt` (the bomb is held on it),
///  * the lag is real and has the right sign (the hand trails the stroke),
///  * the wing is open when raised and folded along the flank at rest,
///  * value: the wings separate from the body, the far wing is dimmer than the
///    near one and never a clone of it,
///  * the hit flash is near-white, the fury flushes, Reduced Motion is still,
///  * non-finite input never throws and never draws outside the box,
///  * caches never change a pixel, the budget holds for the wings alone,
///  * the wings stay inside the envelope in every pose, stomp and fury
///    included.
///
/// Review renders: `--dart-define=KING_COO_WING_CAPTURE=true` (written to
/// `build/king-coo-wings/`, or `KING_COO_WING_OUT`).
const capture = bool.fromEnvironment('KING_COO_WING_CAPTURE');
const _out = String.fromEnvironment(
  'KING_COO_WING_OUT',
  defaultValue: 'build/king-coo-wings',
);

const _near = <String>{'nearWing'};
const _far = <String>{'farWing'};
const _wings = <String>{'farWing', 'nearWing'};

/// A named pose for the sheets.
typedef Named = (String, KingCooPose);

KingCooPose _throwAt(
  double ago, {
  bool fury = false,
  bool reduced = false,
  KingCooSkyLight? light,
}) => poseOf(
  cooBoss(
    combat: 1.0,
    fury: fury,
    setup: (b) => b.lobs.add(lobAt(b.age - ago, fury: fury)),
  ),
  reduced: reduced,
  light: light ?? KingCooSkyLight.neutral,
);

/// The wings' own poses, the way a player meets them.
List<Named> keyPoses({KingCooSkyLight light = KingCooSkyLight.neutral}) {
  KingCooPose at(SkyBoss b, {bool reduced = false}) =>
      poseOf(b, light: light, reduced: reduced);
  return [
    ('rest (RM still)', KingCooPose.still),
    ('idle: wing up', idleWithWing(-.7, light: light)),
    ('idle: wing mid', idleWithWing(-.1, light: light)),
    ('idle: wing down', idleWithWing(.6, light: light)),
    ('dip into the sack', _throwAt(.22, light: light)),
    ('backswing + bomb', _throwAt(.45, light: light)),
    ('hold', _throwAt(.6, light: light)),
    ('swing', _throwAt(.78, light: light)),
    ('release', _throwAt(.80, light: light)),
    ('whip', _throwAt(.92, light: light)),
    ('whistle raised', at(cooBoss(combat: 8.9))),
    ('whistle blown', at(cooBoss(combat: 9.3))),
    (
      'stomp (fury onset)',
      at(
        cooBoss(
          combat: 1.2,
          fury: true,
          setup: (b) => b.enragedAt = b.age - .13,
        ),
      ),
    ),
    ('fury', at(cooBoss(combat: 1.2, fury: true))),
    (
      'hit flash',
      at(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .05)),
    ),
    ('pop', at(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .45))),
    ('arrival roar', at(arrivingBoss(3.0))),
    ('defeat: inflating', at(dyingBoss(.62))),
    ('story: happy', KingCooPose.story(KingCooMood.happy, light: light)),
    (
      'story: beaten',
      KingCooPose.story(KingCooMood.sad, beaten: true, light: light),
    ),
  ];
}

// ------------------------------------------------------------------ pixels

double _lstar(int r, int g, int b) {
  double lin(int v) {
    final s = v / 255;
    return s <= .04045
        ? s / 12.92
        : math.pow((s + .055) / 1.055, 2.4).toDouble();
  }

  final y = .2126 * lin(r) + .7152 * lin(g) + .0722 * lin(b);
  return y > .008856 ? 116 * math.pow(y, 1 / 3) - 16 : 903.3 * y;
}

/// Median CIE L* of the solid pixels [pose]'s [only] parts cover (the ink,
/// below L* [ink], does not count: it is the same on every shape), and how many.
Future<(double, int)> _median(
  KingCooPose pose,
  Set<String> only, {
  double ppu = 80,
  double ink = 28,
}) async {
  // 80 px per unit: at phone size a wing is mostly outline and its anti-aliased
  // edge; at 80 the surfaces are what is measured.
  const n = 1200;
  final data = await rawPixels(n, n, (c) {
    c.scale(ppu);
    c.translate(-scanX0, -scanY0);
    KingCooBossRig.paintPose(c, pose, only: only);
  });
  final ls = <double>[];
  for (var i = 0; i < data.length; i += 4) {
    if (data[i + 3] < 240) continue;
    final l = _lstar(data[i], data[i + 1], data[i + 2]);
    if (l >= ink) ls.add(l);
  }
  if (ls.isEmpty) return (0.0, 0);
  ls.sort();
  return (ls[ls.length ~/ 2], ls.length);
}

/// The solid pixels of [only] as booleans on the scan canvas at [ppu].
Future<List<bool>> _mask(KingCooPose pose, Set<String> only, double ppu) async {
  final n = (scanSize * ppu).round();
  final data = await rawPixels(n, n, (c) {
    c.scale(ppu);
    c.translate(-scanX0, -scanY0);
    KingCooBossRig.paintPose(c, pose, only: only);
  });
  return [for (var i = 3; i < data.length; i += 4) data[i] >= 128];
}

// ------------------------------------------------------------------ budget

/// Counts what a frame asks of the canvas (the budget test's own counter).
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
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

/// The wings' hardest frames: every key pose in the night's tone, and the
/// fury's under a hit and its throw (every wash on at once).
List<Named> _worstStates() => [
  ...keyPoses(light: const KingCooSkyLight(dark: .9)),
  (
    'fury + hit',
    poseOf(
      cooBoss(combat: 9.3, fury: true, setup: (b) => b.lastHitAt = b.age - .05),
    ),
  ),
  (
    'fury throw',
    poseOf(
      cooBoss(
        combat: 1.0,
        fury: true,
        setup: (b) => b.lobs.add(lobAt(b.age - .7, fury: true)),
      ),
    ),
  ),
];

// ------------------------------------------------------------------ sheets

Future<void> _sheet(
  String name,
  List<Named> poses, {
  int cols = 4,
  double ppu = 56,
  Rect view = const Rect.fromLTRB(-2.6, -3.0, 3.8, 1.5),
  Set<String>? only = _wings,
  bool dark = false,
  bool ny = false,
}) async {
  await loadFonts();
  final cw = (view.width * ppu).round(), ch = (view.height * ppu).round();
  final rows = (poses.length / cols).ceil();
  await savePng(name, cw * cols, ch * rows, (c) {
    for (var i = 0; i < poses.length; i++) {
      final x = (i % cols) * cw.toDouble(), y = (i ~/ cols) * ch.toDouble();
      c.save();
      c.clipRect(Rect.fromLTWH(x, y, cw.toDouble(), ch.toDouble()));
      c.translate(x, y);
      if (ny) {
        c.save();
        c.translate(-300 + 200, -150 + 110);
        SkyScenery.paint(
          c,
          const Size(640, 360),
          seconds: 6.0 + i * 1.7,
          distance: (6.0 + i * 1.7) * .36,
          held: WorldRegion.newYork,
        );
        c.restore();
      } else {
        c.drawRect(
          Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()),
          Paint()
            ..color = dark ? const Color(0xff1b1d3c) : const Color(0xffe6dfd6),
        );
      }
      c.translate(-view.left * ppu, -view.top * ppu);
      c.scale(ppu);
      KingCooBossRig.paintPose(c, poses[i].$2, only: only);
      c.restore();
      label(
        c,
        poses[i].$1,
        Offset(x + 6, y + 3),
        size: 13,
        color: dark || ny ? const Color(0xffffffff) : const Color(0xff222222),
      );
    }
  }, dir: _out);
}

/// One in-game frame over New York at night ([w]x360 logical px), King Coo
/// in [pose], cropped around him and shown at [scale] x.
Future<void> _frame(
  String name,
  KingCooPose pose,
  double w, {
  double scale = 2,
  double combat = 2.2,
  double birdY = .5,
}) async {
  final boss = bossAnchor(w, combat: combat);
  final crop = Rect.fromLTWH(
    boss.dx - 4.0 * 41.4,
    boss.dy - 3.9 * 41.4,
    7.6 * 41.4,
    7.0 * 41.4,
  );
  await savePng(
    name,
    (crop.width * scale).round(),
    (crop.height * scale).round(),
    (c) {
      c.scale(scale);
      c.translate(-crop.left, -crop.top);
      nyFrame(c, w, pose: pose, combat: combat, birdY: birdY);
    },
    dir: _out,
  );
}

/// [poses] at real size (1 logical px = 1 px) over New York at night, [w]x360,
/// the figure cropped to his own box.
Future<void> _realSize(String name, List<Named> poses, double w) async {
  await loadFonts();
  const unit = 41.4;
  final boss = bossAnchor(w, combat: 2.2);
  final crop = Rect.fromLTWH(
    boss.dx - 3.3 * unit,
    boss.dy - 3.6 * unit,
    7.9 * unit,
    6.6 * unit,
  );
  const cols = 4;
  final rows = (poses.length / cols).ceil();
  final cw = crop.width.round(), ch = crop.height.round();
  await savePng(name, cw * cols, ch * rows, (c) {
    for (var i = 0; i < poses.length; i++) {
      final x = (i % cols) * cw.toDouble(), y = (i ~/ cols) * ch.toDouble();
      c.save();
      c.clipRect(Rect.fromLTWH(x, y, cw.toDouble(), ch.toDouble()));
      c.translate(x - crop.left, y - crop.top);
      nyFrame(c, w, pose: poses[i].$2, combat: 2.2);
      c.restore();
      label(
        c,
        poses[i].$1,
        Offset(x + 6, y + 3),
        size: 12,
        color: const Color(0xffffffff),
      );
    }
  }, dir: _out);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------ anatomy --

  group('anatomy', () {
    test('openAt: folded at the flank, open when raised, continuous', () {
      expect(KingCooWingArt.openAt(KingCooLayout.restWingNear), 0);
      expect(KingCooWingArt.openAt(1.15), 0);
      expect(KingCooWingArt.openAt(-.7), 1);
      expect(KingCooWingArt.openAt(-1.25), 1);
      // The far wing at its rest (-.5) stands open behind the back.
      expect(
        KingCooWingArt.openAt(KingCooLayout.restWingFar, far: true),
        inInclusiveRange(.6, .95),
      );
      var prev = KingCooWingArt.openAt(1.0);
      for (var a = 1.0; a >= -1.3; a -= .01) {
        final o = KingCooWingArt.openAt(a);
        expect(o, greaterThanOrEqualTo(prev - 1e-9), reason: 'monotone at $a');
        expect((o - prev).abs(), lessThan(.06), reason: 'no jump at $a');
        prev = o;
      }
    });

    test('the near wing\'s tip is the pose\'s hand, in every combat pose', () {
      var worst = 0.0;
      for (final (name, pose) in combatPoses(dt: 1 / 10)) {
        final wing = KingCooWing.nearOf(pose);
        final tip = pose.toRig(wing.tip);
        final hand = KingCooBossRig.bombOrigin(pose);
        worst = math.max(worst, (tip - hand).distance);
        expect(tip.dx, closeTo(hand.dx, 1e-9), reason: name);
        expect(tip.dy, closeTo(hand.dy, 1e-9), reason: name);
      }
      // ignore: avoid_print
      print('rigid tip vs handAt: worst $worst');
    });

    test('the wing reads the pose it is given: open, grip, stretch, stomp', () {
      final rest = KingCooPose.still;
      expect(KingCooWing.nearOf(rest).open, 0);
      expect(KingCooWing.nearOf(rest).drag, 0);
      expect(KingCooWing.nearOf(rest).throwing, 0);
      final up = idleWithWing(-.7);
      expect(KingCooWing.nearOf(up).open, greaterThan(.95));
      final hold = _throwAt(.6);
      expect(KingCooWing.nearOf(hold).throwing, 1);
      expect(
        KingCooWing.nearOf(hold).angle,
        closeTo(KingCooLayout.windupBack, .05),
      );
      final whip = _throwAt(.92);
      expect(KingCooWing.nearOf(whip).stretch, greaterThan(1.1));
      final stomp = poseOf(
        cooBoss(
          combat: 1.2,
          fury: true,
          setup: (b) => b.enragedAt = b.age - .125,
        ),
      );
      expect(KingCooWing.nearOf(stomp).stomp, greaterThan(.95));
      expect(KingCooWing.farOf(stomp).stomp, greaterThan(.95));
      final pop = poseOf(
        cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .6),
      );
      expect(KingCooWing.nearOf(pop).limp, greaterThan(.3));
      final whistle = poseOf(cooBoss(combat: 9.3));
      expect(KingCooWing.nearOf(whistle).flare, greaterThan(.3));
      final fury = poseOf(cooBoss(combat: 1.2, fury: true));
      expect(KingCooWing.nearOf(fury).flare, greaterThan(.15));
    });
  });

  // ---------------------------------------------------------------- lag --

  group('lag', () {
    test('Reduced Motion: no lag, every frame', () {
      for (final (name, pose) in combatPoses(dt: 1 / 6, reduced: true)) {
        expect(KingCooWingArt.dragOf(pose, far: false), 0, reason: name);
        expect(KingCooWingArt.dragOf(pose, far: true), 0, reason: name);
      }
    });

    test('the drag has the sign and size of the stroke in the idle beat', () {
      // In the idle waddle the beat owns both wings: the drag must be the wing's
      // own angular rate (a finite difference of the pose) over 12 rad/s.
      const dt = 1 / 480;
      var checked = 0;
      for (var i = 0; i < 400; i++) {
        final t = 1.0 + i * .005;
        final a = poseOf(cooBoss(combat: t - dt));
        final b = poseOf(cooBoss(combat: t + dt));
        final m = poseOf(cooBoss(combat: t));
        for (final far in [false, true]) {
          final rate =
              ((far ? b.wingFar : b.wingNear) -
                  (far ? a.wingFar : a.wingNear)) /
              (2 * dt);
          if (rate.abs() < 3) continue;
          final drag = KingCooWingArt.dragOf(m, far: far);
          checked++;
          expect(drag.sign, rate.sign, reason: 't $t far $far: rate $rate');
          expect(
            drag,
            closeTo((rate / 12).clamp(-1.0, 1.0), .12),
            reason: 't $t far $far: rate $rate',
          );
        }
      }
      expect(checked, greaterThan(200));
    });

    test('the drag never pops: every scenario at 1/480 s', () {
      const dt = 1 / 480;
      var worst = 0.0;
      var where = '';
      for (final (name, at, from, to) in combatScenarios(cycles: 1)) {
        for (var t = from; t < to; t += dt) {
          final p0 = poseOf(at(t)), p1 = poseOf(at(t + dt));
          for (final far in [false, true]) {
            final d =
                (KingCooWingArt.dragOf(p1, far: far) -
                        KingCooWingArt.dragOf(p0, far: far))
                    .abs();
            if (d > worst) {
              worst = d;
              where = '$name t=${(t - 4.6).toStringAsFixed(3)} far=$far';
            }
          }
        }
      }
      // ignore: avoid_print
      print('drag: worst step per 1/480 s $worst at $where');
      expect(worst, lessThan(.35), reason: where);
    });

    test('the drag is bounded; the quick downstroke drags hardest', () {
      // The beat is a quick downstroke and a slow upstroke: the drag peaks high
      // going down and stays gentle going up.
      var up = 0, down = 0;
      for (var i = 0; i < 125; i++) {
        final pose = poseOf(cooBoss(combat: 1.2 + i * .01));
        final drag = KingCooWing.nearOf(pose).drag;
        expect(drag.abs(), lessThanOrEqualTo(1.0));
        if (drag > .5) down++;
        if (drag < -.25) up++;
      }
      expect(down, greaterThan(5));
      expect(up, greaterThan(20));
    });
  });

  // ------------------------------------------------------------- pixels --

  group('pixels', () {
    testWidgets('the painted tip is on the pose\'s hand at every throw frame', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const ppu = 50.0;
        var worst = 0.0, frames = 0;
        var where = '';
        for (var t = 0.0; t <= .8 + .65; t += 1 / 40) {
          final b = cooBoss(
            combat: 0,
            setup: (b) => b.lobs.add(lobAt(4.6 + .6)),
          );
          b.age = 4.6 + .6 + t;
          final pose = poseOf(b);
          if (pose.armThrow < .4) continue;
          final shoulder = pose.toRig(KingCooLayout.nearShoulder);
          final hand = KingCooBossRig.bombOrigin(pose);
          final dir = (hand - shoulder) / (hand - shoulder).distance;
          final n = (scanSize * ppu).round();
          final data = await rawPixels(n, n, (c) {
            c.scale(ppu);
            c.translate(-scanX0, -scanY0);
            KingCooBossRig.paintPose(c, pose, only: _near);
          });
          var best = -1e9;
          var tip = Offset.zero;
          for (var y = 0; y < n; y++) {
            for (var x = 0; x < n; x++) {
              if (data[(y * n + x) * 4 + 3] < 200) continue;
              final p = Offset(
                (x + .5) / ppu + scanX0,
                (y + .5) / ppu + scanY0,
              );
              final q = p - shoulder;
              final along = q.dx * dir.dx + q.dy * dir.dy;
              if (along > best) {
                best = along;
                tip = p;
              }
            }
          }
          frames++;
          final err = (tip - hand).distance;
          if (err > worst) {
            worst = err;
            where =
                'throw +${t.toStringAsFixed(3)} s (arm ${pose.armThrow.toStringAsFixed(2)})';
          }
        }
        // ignore: avoid_print
        print(
          'painted tip vs handAt: worst ${worst.toStringAsFixed(3)} over $frames frames at $where',
        );
        expect(frames, greaterThan(30));
        expect(worst, lessThanOrEqualTo(.10), reason: where);
      });
    });

    testWidgets('value: the wings separate from the body, the far one is dimmer', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final light = newYorkLight();
        final report = StringBuffer();
        for (final (name, pose) in [
          ('rest', poseOf(cooBoss(combat: 1.2), light: light)),
          ('wing up', idleWithWing(-.7, light: light)),
          ('hover', poseOf(cooBoss(combat: 2.0), light: light)),
        ]) {
          final (nearL, nn) = await _median(pose, _near);
          final (farL, nf) = await _median(pose, _far);
          final (bodyL, _) = await _median(pose, {'torso', 'tail'});
          final (chestL, _) = await _median(pose, {'chest'});
          report.writeln(
            '$name: near wing L* ${nearL.toStringAsFixed(1)} ($nn px), far ${farL.toStringAsFixed(1)} ($nf px), '
            'torso+tail ${bodyL.toStringAsFixed(1)}, chest ${chestL.toStringAsFixed(1)}',
          );
          expect(
            (nearL - bodyL).abs(),
            greaterThanOrEqualTo(8),
            reason: '$name: the near wing and the body share a lightness',
          );
          expect(
            nearL,
            greaterThan(farL + 3),
            reason: '$name: the far wing is dimmer than the near one',
          );
        }
        // ignore: avoid_print
        print(report);
      });
    });

    testWidgets('the far wing is never a clone of the near one', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // The same root, angle and light: the feather counts, the fan and the
        // tone keep them apart.
        const ppu = 40.0;
        Future<List<bool>> maskOf(bool far) async {
          final n = (scanSize * ppu).round();
          final data = await rawPixels(n, n, (c) {
            c.scale(ppu);
            c.translate(-scanX0, -scanY0);
            KingCooWingArt.paint(
              c,
              KingCooWing(
                shoulder: const Offset(1, 1),
                angle: -.6,
                stretch: 1,
                far: far,
                tone: KingCooTone.calm,
              ),
            );
          });
          return [for (var i = 3; i < data.length; i += 4) data[i] >= 128];
        }

        final a = await maskOf(false), b = await maskOf(true);
        var both = 0, either = 0;
        for (var i = 0; i < a.length; i++) {
          if (a[i] && b[i]) both++;
          if (a[i] || b[i]) either++;
        }
        final iou = both / either;
        // ignore: avoid_print
        print('near vs far at the same angle: IoU ${iou.toStringAsFixed(3)}');
        expect(iou, lessThan(.93));
      });
    });

    testWidgets('the hit flash takes the wings near white; the ink holds', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final calm = poseOf(cooBoss(combat: 1.2));
        final flash = poseOf(
          cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .03),
        );
        expect(flash.flash, greaterThan(.5));
        final (calmL, _) = await _median(calm, _near);
        final (flashL, _) = await _median(flash, _near);
        // ignore: avoid_print
        print(
          'near wing median L*: calm ${calmL.toStringAsFixed(1)} flash ${flashL.toStringAsFixed(1)}',
        );
        expect(flashL, greaterThan(calmL + 6));
        expect(flashL, greaterThan(74));
        // The ink outline holds: the darkest solid pixel stays dark.
        const n = 300;
        final data = await rawPixels(n, n, (c) {
          c.scale(30);
          c.translate(-scanX0, -scanY0);
          KingCooBossRig.paintPose(c, flash, only: _near);
        });
        var darkest = 100.0;
        for (var i = 0; i < data.length; i += 4) {
          if (data[i + 3] >= 240) {
            darkest = math.min(
              darkest,
              _lstar(data[i], data[i + 1], data[i + 2]),
            );
          }
        }
        expect(darkest, lessThan(30));
      });
    });

    testWidgets('the fury flushes the plumage, and Reduced Motion keeps it', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final calm = poseOf(cooBoss(combat: 1.2));
        final fury = poseOf(cooBoss(combat: 1.2, fury: true));
        final furyRm = poseOf(cooBoss(combat: 1.2, fury: true), reduced: true);
        double red(Uint8List d) {
          var r = 0.0, b = 0.0, k = 0;
          for (var i = 0; i < d.length; i += 4) {
            if (d[i + 3] >= 240) {
              r += d[i];
              b += d[i + 2];
              k++;
            }
          }
          return (r - b) / math.max(k, 1);
        }

        Future<Uint8List> px(KingCooPose p) => rawPixels(300, 300, (c) {
          c.scale(30);
          c.translate(-scanX0, -scanY0);
          KingCooBossRig.paintPose(c, p, only: _wings);
        });
        final a = red(await px(calm)),
            b = red(await px(fury)),
            c = red(await px(furyRm));
        // ignore: avoid_print
        print(
          'red minus blue per pixel: calm ${a.toStringAsFixed(1)} fury ${b.toStringAsFixed(1)} fury RM ${c.toStringAsFixed(1)}',
        );
        expect(b, greaterThan(a + 2));
        expect(c, greaterThan(a + 2));
      });
    });

    testWidgets('Reduced Motion: still frames, every state stays distinct', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // Idle: any two ages look the same.
        final a = poseOf(cooBoss(combat: 1.2), reduced: true);
        final b = poseOf(cooBoss(combat: 2.9), reduced: true);
        expect(await _mask(a, _wings, 20), await _mask(b, _wings, 20));
        // The states keep their poses: the wind-up's hold, the whistle's flare
        // and the pop differ from the idle and from each other.
        final states = <String, KingCooPose>{
          'idle': a,
          'hold': _throwAt(.6, reduced: true),
          'whistle': poseOf(cooBoss(combat: 9.3), reduced: true),
          'pop': poseOf(
            cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .6),
            reduced: true,
          ),
        };
        final masks = <String, List<bool>>{
          for (final e in states.entries)
            e.key: await _mask(e.value, _wings, 20),
        };
        final keys = masks.keys.toList();
        for (var i = 0; i < keys.length; i++) {
          for (var j = i + 1; j < keys.length; j++) {
            expect(
              masks[keys[i]],
              isNot(masks[keys[j]]),
              reason: '${keys[i]} vs ${keys[j]}',
            );
          }
        }
      });
    });

    testWidgets(
      'a wing is a pure function of its pose: the same pixels, any order, any cache',
      (tester) async {
        await tester.runAsync(() async {
          final poses = [for (final (_, p) in _worstStates()) p];
          Future<List<Uint8List>> all(List<KingCooPose> order) async => [
            for (final p in order)
              await rawPixels(260, 260, (c) {
                c.scale(26);
                c.translate(-scanX0, -scanY0);
                KingCooBossRig.paintPose(c, p, only: _wings);
              }),
          ];
          KingCooKit.clearCaches();
          final forward = await all(poses);
          KingCooKit.clearCaches();
          final backward = (await all(
            poses.reversed.toList(),
          )).reversed.toList();
          KingCooKit.clearCaches();
          final again = await all(poses);
          for (var i = 0; i < poses.length; i++) {
            expect(backward[i], forward[i], reason: 'state $i, reversed');
            expect(again[i], forward[i], reason: 'state $i, emptied');
          }
        });
      },
    );

    testWidgets('non-finite input never throws and never draws off the box', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const nan = double.nan, inf = double.infinity;
        final wings = <KingCooWing>[
          for (final far in [false, true])
            for (final v in [nan, inf, -inf, 1e9, -1e9])
              KingCooWing(
                shoulder: far
                    ? KingCooLayout.farShoulder
                    : KingCooLayout.nearShoulder,
                angle: v,
                stretch: v,
                far: far,
                tone: KingCooTone.calm,
                throwing: v,
                stomp: v,
                openness: v,
                flare: v,
                drag: v,
                limp: v,
                turn: v,
              ),
        ];
        for (final w in wings) {
          final r = await scan((c) => KingCooWingArt.paint(c, w), ppu: 20);
          expect(r.rect.isFinite, isTrue);
          expect(
            over(r, KingCooLayout.layerBounds, slack: .05),
            isEmpty,
            reason: 'angle ${w.angle} far ${w.far}: $r',
          );
        }
        // A rootless wing draws nothing.
        final none = await scan(
          (c) => KingCooWingArt.paint(
            c,
            const KingCooWing(
              shoulder: Offset(nan, nan),
              angle: 0,
              stretch: 1,
              far: false,
              tone: KingCooTone.calm,
            ),
          ),
          ppu: 10,
        );
        expect(none.rect, Rect.zero);
      });
    });

    testWidgets('the folded wing adds almost no mass above the back line', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const ppu = 60.0;
        final pose = KingCooPose.still;
        final wing = await _mask(pose, _near, ppu);
        final body = await _mask(pose, {
          'torso',
          'chest',
          'neck',
          'ruff',
          'head',
          'tail',
        }, ppu);
        var above = 0;
        for (var i = 0; i < wing.length; i++) {
          if (wing[i] && !body[i]) above++;
        }
        final area = above / (ppu * ppu);
        // ignore: avoid_print
        print(
          'folded near wing outside the body silhouette: ${area.toStringAsFixed(3)} u2',
        );
        // A sliver at the tip and the root, nothing more.
        expect(area, lessThan(.45));
      });
    });
  });

  // ------------------------------------------------------------- budget --

  group('budget', () {
    (int, int, int, int, int) measure(KingCooPose pose) {
      final before = KingCooKit.shadersBuilt;
      final c = _Counting(Canvas(ui.PictureRecorder()));
      KingCooBossRig.paintPose(c, pose, only: _wings);
      return (
        c.draws,
        c.clips,
        c.counts['saveLayer'] ?? 0,
        c.counts['maskFilter'] ?? 0,
        KingCooKit.shadersBuilt - before,
      );
    }

    test(
      'both wings stay inside their share in every state, none built warm',
      () {
        KingCooBossRig.prewarm();
        var worst = 0;
        var worstName = '';
        for (final (name, pose) in _worstStates()) {
          final (draws, clips, layers, blur, built) = measure(pose);
          if (draws > worst) {
            worst = draws;
            worstName = name;
          }
          expect(
            draws,
            lessThanOrEqualTo(KingCooBudget.wings.ops),
            reason: name,
          );
          expect(
            clips,
            lessThanOrEqualTo(KingCooBudget.wings.clips),
            reason: name,
          );
          expect(layers, 0, reason: name);
          expect(blur, 0, reason: name);
          expect(built, 0, reason: '$name builds a shader on a warm frame');
        }
        // ignore: avoid_print
        print(
          'wings: worst $worst ops ($worstName) of ${KingCooBudget.wings.ops}',
        );
      },
    );

    test('the table: ops per wing, per state', () {
      KingCooBossRig.prewarm();
      final report = StringBuffer('state                 near  far  both\n');
      var nearWorst = 0, farWorst = 0;
      for (final (name, pose) in _worstStates()) {
        int ops(Set<String> only) {
          final c = _Counting(Canvas(ui.PictureRecorder()));
          KingCooBossRig.paintPose(c, pose, only: only);
          return c.draws;
        }

        final n = ops(_near), f = ops(_far);
        nearWorst = math.max(nearWorst, n);
        farWorst = math.max(farWorst, f);
        report.writeln(
          '${name.padRight(21)} ${n.toString().padLeft(4)} ${f.toString().padLeft(4)} ${(n + f).toString().padLeft(5)}',
        );
      }
      // ignore: avoid_print
      print('$report\nworst: near $nearWorst, far $farWorst');
      expect(nearWorst + farWorst, lessThanOrEqualTo(KingCooBudget.wings.ops));
    });

    test('a cold wing builds its three gradients once, then nothing', () {
      KingCooKit.clearCaches();
      final cold = measure(poseOf(cooBoss(combat: 1.2))).$5;
      expect(cold, lessThanOrEqualTo(3));
      // Both lights, both wings, every tone: nothing more.
      for (final (name, p) in _worstStates()) {
        expect(measure(p).$5, 0, reason: name);
      }
    });

    test('painting both wings is cheap', () {
      KingCooBossRig.prewarm();
      final pose = poseOf(cooBoss(combat: 9.3));
      for (var i = 0; i < 200; i++) {
        KingCooWingArt.paint(
          Canvas(ui.PictureRecorder()),
          KingCooWing.nearOf(pose),
        );
      }
      final sw = Stopwatch()..start();
      const n = 1000;
      for (var i = 0; i < n; i++) {
        final c = Canvas(ui.PictureRecorder());
        KingCooWingArt.paint(c, KingCooWing.farOf(pose));
        KingCooWingArt.paint(c, KingCooWing.nearOf(pose));
      }
      final micros = sw.elapsedMicroseconds / n;
      // ignore: avoid_print
      print('both wings: ${micros.toStringAsFixed(0)} us per frame');
      expect(micros, lessThan(6000));
    });
  });

  // ----------------------------------------------------------- envelope --

  group('envelope', () {
    testWidgets('the wings alone stay inside the combat envelope in every pose', (
      tester,
    ) async {
      await tester.runAsync(() async {
        var union = Rect.zero;
        final failures = <String>[];
        for (final reduced in [false, true]) {
          for (final (name, pose) in combatPoses(
            cycles: envelopeCycles,
            dt: 1 / 12,
            reduced: reduced,
          )) {
            final r = await scan(
              (c) => KingCooBossRig.paintPose(c, pose, only: _wings),
              ppu: 20,
            );
            union = union.expandToInclude(r.rect);
            final o = over(r, KingCooLayout.envelope, slack: .05);
            if (o.isNotEmpty) failures.add('$name: $o');
          }
        }
        // ignore: avoid_print
        print(
          'wings alone, combat union: L ${union.left.toStringAsFixed(2)} T ${union.top.toStringAsFixed(2)} '
          'R ${union.right.toStringAsFixed(2)} B ${union.bottom.toStringAsFixed(2)}  '
          '(envelope ${KingCooLayout.envelope})',
        );
        expect(failures.take(8), isEmpty);
      });
    });

    testWidgets(
      'the wings alone stay inside the layer bounds, arrival and defeat',
      (tester) async {
        await tester.runAsync(() async {
          var union = Rect.zero;
          final failures = <String>[];
          for (final (name, pose) in stagedPoses()) {
            final r = await scan(
              (c) => KingCooBossRig.paintPose(c, pose, only: _wings),
              ppu: 20,
            );
            union = union.expandToInclude(r.rect);
            final o = over(r, KingCooLayout.layerBounds, slack: .05);
            if (o.isNotEmpty) failures.add('$name: $o');
          }
          // ignore: avoid_print
          print(
            'wings alone, staged union: L ${union.left.toStringAsFixed(2)} T ${union.top.toStringAsFixed(2)} '
            'R ${union.right.toStringAsFixed(2)} B ${union.bottom.toStringAsFixed(2)}',
          );
          expect(failures.take(8), isEmpty);
        });
      },
    );

    testWidgets('the stomp and the fury spread fit, every .02 s', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (var tau = 0.0; tau <= .5; tau += .02) {
          final pose = poseOf(
            cooBoss(
              combat: 1.2,
              fury: true,
              setup: (b) => b.enragedAt = b.age - tau,
            ),
          );
          final r = await scan(
            (c) => KingCooBossRig.paintPose(c, pose, only: _wings),
            ppu: 20,
          );
          expect(
            over(r, KingCooLayout.envelope, slack: .05),
            isEmpty,
            reason: 'stomp $tau: $r',
          );
        }
      });
    });
  });

  // ----------------------------------------------------------- captures --

  group('captures', skip: !capture, () {
    testWidgets('key poses: wings alone on light, dark and over New York', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final light = newYorkLight();
        await _sheet('01-poses-light', keyPoses(), ppu: 52);
        await _sheet(
          '02-poses-dark',
          keyPoses(light: light),
          ppu: 52,
          dark: true,
        );
        await _sheet(
          '03-poses-ny-full',
          keyPoses(light: light),
          ppu: 52,
          only: null,
          ny: true,
          view: const Rect.fromLTRB(-3.0, -3.2, 4.6, 2.6),
        );
      });
    });

    testWidgets('frames over New York: 2.4x and real size at 640 and 800', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final light = newYorkLight();
        final k = keyPoses(light: light);
        await _frame('30-frame-rest-640', k[0].$2, 640, scale: 2.4);
        await _frame('31-frame-up-640', k[1].$2, 640, scale: 2.4);
        final names = {
          'idle up': 1,
          'idle down': 3,
          'hold': 6,
          'swing': 7,
          'whistle': 11,
          'stomp': 12,
          'fury': 13,
          'hit': 14,
        };
        for (final w in [640.0, 800.0]) {
          final poses = <Named>[
            for (final e in names.entries) (e.key, k[e.value].$2),
          ];
          await _realSize('32-real-size-${w.round()}', poses, w);
        }
      });
    });

    testWidgets('strips: the beat, the throw, the stomp', (tester) async {
      await tester.runAsync(() async {
        final light = newYorkLight();
        const view = Rect.fromLTRB(-2.4, -3.0, 3.0, 1.0);
        final beat = <Named>[
          for (var i = 0; i < 12; i++)
            (
              'beat ${i + 1}/12',
              poseOf(cooBoss(combat: 1.2 + i * (.625 / 12)), light: light),
            ),
        ];
        await _sheet(
          '40-beat-strip',
          beat,
          ppu: 70,
          view: view,
          only: null,
          ny: true,
        );
        final throwAgo = [
          .05,
          .22,
          .35,
          .5,
          .62,
          .74,
          .78,
          .80,
          .83,
          .86,
          .92,
          1.0,
          1.1,
          1.25,
          1.45, //
        ];
        final toss = <Named>[
          for (final a in throwAgo)
            ('throw +${a.toStringAsFixed(2)} s', _throwAt(a, light: light)),
        ];
        await _sheet(
          '41-throw-strip',
          toss,
          cols: 5,
          ppu: 70,
          view: view,
          only: null,
          ny: true,
        );
        final stomp = <Named>[
          for (final tau in [
            0.0, .03, .06, .09, .125, .16, .19, .22, .25, .30, .45, .7, //
          ])
            (
              'stomp ${tau.toStringAsFixed(3)} s',
              poseOf(
                cooBoss(
                  combat: 1.2,
                  fury: true,
                  setup: (b) => b.enragedAt = b.age - tau,
                ),
                light: light,
              ),
            ),
        ];
        await _sheet(
          '42-stomp-strip',
          stomp,
          ppu: 70,
          view: view,
          only: null,
          ny: true,
        );
      });
    });

    testWidgets('close-ups on light and dark', (tester) async {
      await tester.runAsync(() async {
        final k = keyPoses();
        final kn = keyPoses(light: newYorkLight());
        await _sheet(
          '10-close-rest',
          [k[0], k[2]],
          cols: 2,
          ppu: 230,
          view: const Rect.fromLTRB(-.4, -2.0, 2.6, .8),
        );
        await _sheet(
          '11-close-up',
          [k[1], k[3]],
          cols: 2,
          ppu: 200,
          view: const Rect.fromLTRB(-.6, -3.0, 2.6, .9),
        );
        await _sheet(
          '12-close-dark',
          [kn[1], kn[7], kn[12], kn[14]],
          cols: 2,
          ppu: 130,
          view: const Rect.fromLTRB(-2.4, -3.0, 2.7, 1.0),
          dark: true,
        );
      });
    });

    testWidgets('close-ups of the states', (tester) async {
      await tester.runAsync(() async {
        final kn = keyPoses(light: newYorkLight());
        // whistle blown, stomp, pop, fury, hit, defeat, beaten, happy
        await _sheet(
          '13-close-states',
          [kn[11], kn[12], kn[15], kn[13], kn[14], kn[17], kn[19], kn[18]],
          cols: 4,
          ppu: 100,
          view: const Rect.fromLTRB(-2.2, -2.8, 2.6, 1.2),
          dark: true,
        );
      });
    });

    testWidgets('Reduced Motion: the still frames', (tester) async {
      await tester.runAsync(() async {
        final light = newYorkLight();
        final poses = <Named>[
          ('idle', poseOf(cooBoss(combat: 2.0), reduced: true, light: light)),
          ('wind-up hold', _throwAt(.6, reduced: true, light: light)),
          ('release', _throwAt(.8, reduced: true, light: light)),
          (
            'whistle blown',
            poseOf(cooBoss(combat: 9.3), reduced: true, light: light),
          ),
          (
            'fury',
            poseOf(
              cooBoss(combat: 1.2, fury: true),
              reduced: true,
              light: light,
            ),
          ),
          (
            'hit flash (.3)',
            poseOf(
              cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .1),
              reduced: true,
              light: light,
            ),
          ),
          (
            'pop',
            poseOf(
              cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .6),
              reduced: true,
              light: light,
            ),
          ),
          ('defeat', poseOf(dyingBoss(.62), reduced: true, light: light)),
        ];
        await _sheet(
          '14-reduced-motion',
          poses,
          ppu: 80,
          view: const Rect.fromLTRB(-2.4, -2.8, 2.7, 1.2),
          dark: true,
        );
      });
    });

    testWidgets('the onion skin of the flap and the envelope', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const ppu = 110.0;
        const view = Rect.fromLTRB(-2.8, -3.0, 4.4, 2.6);
        final light = newYorkLight();
        final beat = [
          for (var i = 0; i < 16; i++)
            poseOf(cooBoss(combat: 1.2 + i * (.625 / 16)), light: light),
        ];
        await savePng(
          '50-onion-flap',
          (view.width * ppu).round(),
          (view.height * ppu).round(),
          (c) {
            c.drawRect(
              Rect.fromLTWH(0, 0, view.width * ppu, view.height * ppu),
              Paint()..color = const Color(0xff2a2c52),
            );
            c.save();
            c.scale(ppu);
            c.translate(-view.left, -view.top);
            // The body once, dimmed, then each phase of the wings.
            c.saveLayer(null, Paint()..color = const Color(0x55ffffff));
            KingCooBossRig.paintPose(
              c,
              KingCooPose.still,
              only: {
                'torso', 'chest', 'neck', 'ruff', 'head', 'tail', 'sack', //
              },
            );
            c.restore();
            for (final p in beat) {
              c.saveLayer(null, Paint()..color = const Color(0x44ffffff));
              KingCooBossRig.paintPose(c, p, only: _wings);
              c.restore();
            }
            c.drawRect(
              KingCooLayout.envelope,
              Paint()
                ..color = const Color(0xff30d070)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2 / ppu,
            );
            c.restore();
            label(
              c,
              '16 phases of one beat (38 ms apart), wings only; the green box is the envelope',
              const Offset(10, 8),
              size: 14,
              color: const Color(0xffffffff),
            );
          },
          dir: _out,
        );
      });
    });

    testWidgets('silhouettes at 250 and 120 px', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final poses = [
          for (final i in [1, 3, 6, 7, 9, 11, 12, 15]) keyPoses()[i],
        ];
        for (final (name, ppu, cols) in const [
          ('60-sil-250', 41.4, 4),
          ('61-sil-120', 19.0, 8),
        ]) {
          const x0 = -3.0, y0 = -3.6, wU = 8.0, hU = 6.6;
          final cw = (wU * ppu).round(), ch = (hU * ppu).round();
          final rows = (poses.length / cols).ceil();
          final images = <ui.Image>[];
          for (final (_, pose) in poses) {
            images.add(
              await silhouetteImage(
                pose,
                ppu: ppu,
                w: cw,
                h: ch,
                origin: Offset(-x0 * ppu, -y0 * ppu),
              ),
            );
          }
          await savePng(name, cw * cols, ch * rows, (c) {
            c.drawRect(
              Rect.fromLTWH(
                0,
                0,
                (cw * cols).toDouble(),
                (ch * rows).toDouble(),
              ),
              Paint()..color = const Color(0xffd8d0e6),
            );
            for (var i = 0; i < poses.length; i++) {
              final cx = (i % cols) * cw.toDouble(),
                  cy = (i ~/ cols) * ch.toDouble();
              c.drawImage(images[i], Offset(cx, cy), Paint());
              label(
                c,
                poses[i].$1,
                Offset(cx + 4, cy + 2),
                size: ppu > 30 ? 13 : 9,
              );
            }
          }, dir: _out);
          for (final i in images) {
            i.dispose();
          }
        }
      });
    });
  });
}
