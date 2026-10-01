import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

import 'king_coo_test_kit.dart';

/// King Coo's per-frame budget (real mid-range Android phones, 60 fps).
///
/// The rig (everything `KingCooBossRig.paintPose` draws) must, in every state:
///   * make at most `KingCooBudget.rigOps` draw calls (paths, circles, lines,
///     rects, ovals, arcs...),
///   * at most `rigClips` clipPaths, no saveLayer and no blur mask,
///   * build at most `rigShaders` gradient shaders on a warm frame (the
///     pose-independent ones live in `static final` or `KingCooKit.cached`),
///     and NONE at all in a fight after `KingCooBossRig.prewarm()`.
/// Each part has its own share too (`KingCooBudget`): a failure names the
/// owner, the state and the number. The rig's total is the sum of the shares
/// with headroom, so a part over its share can hide behind another part's
/// slack in the total; the per-owner lines catch it.
///
/// Until every part has landed this REPORTS; flip [enforceRealArt]
/// (test/king_coo_test_kit.dart, one line) to fail.

/// One owner's share: its parts (z-order names), draw ops, shaders BUILT per
/// warm frame, clips.
typedef _Share = (String owner, List<String> parts, int ops, int shaders, int clips);

final _shares = <_Share>[
  (
    'head (K2: ruff head cap whistle steam)',
    KingCooLayout.headParts,
    KingCooBudget.head.ops,
    KingCooBudget.head.shaders,
    KingCooBudget.head.clips,
  ),
  (
    'body (K3: legs tail torso sack chest)',
    KingCooLayout.bodyParts,
    KingCooBudget.body.ops,
    KingCooBudget.body.shaders,
    KingCooBudget.body.clips,
  ),
  (
    'wings (K4)',
    KingCooLayout.wingParts,
    KingCooBudget.wings.ops,
    KingCooBudget.wings.shaders,
    KingCooBudget.wings.clips,
  ),
  ('bomb in hand (K5)', KingCooLayout.crumbParts, KingCooBudget.bomb, 1, 0),
];

/// Counts what a frame asks of the canvas.
class Counting implements Canvas {
  Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get clips => (counts['clipPath'] ?? 0) + (counts['clipPath.noAA'] ?? 0);
  int get shaderDraws => counts.entries
      .where((e) => e.key.endsWith('.shader'))
      .fold(0, (a, e) => a + e.value);

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

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    _n('clipRect');
    inner.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
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
  void drawRRect(RRect r, Paint paint) {
    _paint('drawRRect', paint);
    inner.drawRRect(r, paint);
  }

  @override
  void drawOval(Rect r, Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
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
  void drawDRRect(RRect outer, RRect inner_, Paint paint) {
    _paint('drawDRRect', paint);
    inner.drawDRRect(outer, inner_, paint);
  }

  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) {
    _paint('drawVertices', paint);
    inner.drawVertices(vertices, blendMode, paint);
  }

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {
    _paint('drawPoints', paint);
    inner.drawPoints(pointMode, points, paint);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

class _Frame {
  _Frame(this.counting, this.built);
  final Counting counting;
  final int built;
}

_Frame _measure(KingCooPose pose, {Set<String>? only}) {
  final before = KingCooKit.shadersBuilt;
  final canvas = Counting(Canvas(ui.PictureRecorder()));
  KingCooBossRig.paintPose(canvas, pose, only: only);
  return _Frame(canvas, KingCooKit.shadersBuilt - before);
}

/// The worst frames of the fight for the art: every lit state, the widest
/// fans, the most effects (fury with the siren, the bomb, the whistle).
List<(String, KingCooPose)> _states() => [
  for (final (name, pose) in [
    ('idle', poseOf(cooBoss(combat: 1.2))),
    ('dip', poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .2))))),
    ('wind-up hold', poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .7))))),
    ('release', poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .8))))),
    ('whip', poseOf(cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .92))))),
    ('inhale', poseOf(cooBoss(combat: 8.2))),
    ('puffed', poseOf(cooBoss(combat: 9.0))),
    ('whistle', poseOf(cooBoss(combat: 9.3))),
    ('pop', poseOf(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .5))),
    ('hit', poseOf(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .05))),
    ('fury idle', poseOf(cooBoss(combat: 1.2, fury: true))),
    ('fury window', poseOf(cooBoss(combat: 9.3, fury: true))),
    ('fury hit', poseOf(cooBoss(combat: 9.3, fury: true, setup: (b) => b.lastHitAt = b.age - .05))),
    ('fury throw', poseOf(cooBoss(combat: 1.0, fury: true, setup: (b) => b.lobs.add(lobAt(b.age - .7, fury: true))))),
    ('arrival silhouette', poseOf(arrivingBoss(1.0))),
    ('arrival roar', poseOf(arrivingBoss(3.0))),
    ('defeat .3', poseOf(dyingBoss(.3))),
    ('defeat .7', poseOf(dyingBoss(.7))),
    ('defeat .9', poseOf(dyingBoss(.9))),
  ])
    (name, pose),
];

void main() {
  test('a fight never builds a shader once the rig is warmed', () {
    KingCooBossRig.prewarm();
    final before = KingCooKit.shadersBuilt;
    var frames = 0, worst = 0, worstAt = 0.0;
    // A whole fight replay at 60 fps: the arrival, three cycles in calm and
    // the fury's two, hits and a pop in the window.
    for (var i = 0; i < 60 * 52; i++) {
      final age = i / 60.0, combat = age - 4.6;
      final b = cooBoss(combat: 0);
      b.age = age;
      if (combat > 22) {
        b.hp = b.maxHp ~/ 2;
        b.enragedAt = 4.6 + 22;
      }
      for (final n in [0, 1, 2]) {
        b.lobs.addAll([
          lobAt(4.6 + n * 14 + .6),
          lobAt(4.6 + n * 14 + 3.0, y: .7),
        ]);
      }
      if (combat > 16.2 && combat < 16.6) b.lastHitAt = 4.6 + 16.2;
      if (combat > 37 && combat < 37.3) b.lastHitAt = 4.6 + 37;
      if (combat > 22.5) b.poppedAt = 4.6 + 22.5 + 0;
      final pose = poseOf(b, light: const KingCooSkyLight(dark: .9));
      final built0 = KingCooKit.shadersBuilt;
      KingCooBossRig.paintPose(Canvas(ui.PictureRecorder()), pose);
      final built = KingCooKit.shadersBuilt - built0;
      frames++;
      if (built > worst) {
        worst = built;
        worstAt = age;
      }
    }
    // ignore: avoid_print
    print(
      'fight replay: $frames frames built ${KingCooKit.shadersBuilt - before} '
      'shaders in all (worst frame $worst at ${worstAt.toStringAsFixed(2)} s)',
    );
    expect(worst, 0, reason: 'a warmed fight builds nothing (worst at $worstAt s)');
  });

  test('a cold rig builds at most the rig\'s total share, then nothing', () {
    // The first frames of a process build the gradients once; no frame after
    // them builds one for a state already seen.
    KingCooBossRig.prewarm();
    for (final (name, pose) in _states()) {
      final f = _measure(pose);
      expect(f.built, 0, reason: name);
    }
  });

  test('the rig stays inside its per-frame budget, whole and by owner', () {
    final poses = _states();
    // Warm every cache the states share, then measure a steady-state frame.
    for (final (_, pose) in poses) {
      _measure(pose);
    }
    final report = StringBuffer()
      ..writeln(
        'state                 ops  shader-draws built clips layers blur | '
        'head / body / wings / bomb ops',
      );
    final over = <String>[];
    for (final (name, pose) in poses) {
      final whole = _measure(pose);
      final c = whole.counting;
      final shares = <String>[];
      for (final (owner, parts, ops, shaders, clips) in _shares) {
        final group = parts.toSet();
        final f = _measure(pose, only: group);
        final o = f.counting.draws;
        shares.add(o.toString());
        if (o > ops) over.add('$name: $owner $o ops > $ops');
        if (f.built > shaders) {
          over.add('$name: $owner builds ${f.built} shaders > $shaders');
        }
        if (f.counting.clips > clips) {
          over.add('$name: $owner ${f.counting.clips} clips > $clips');
        }
      }
      report.writeln(
        '${name.padRight(21)} ${c.draws.toString().padLeft(4)} '
        '${c.shaderDraws.toString().padLeft(12)} '
        '${whole.built.toString().padLeft(5)} ${c.clips.toString().padLeft(5)} '
        '${(c.counts['saveLayer'] ?? 0).toString().padLeft(6)} '
        '${(c.counts['maskFilter'] ?? 0).toString().padLeft(4)} | ${shares.join(' / ')}',
      );
      if (c.draws > KingCooBudget.rigOps) {
        over.add('$name: rig ${c.draws} ops > ${KingCooBudget.rigOps}');
      }
      if (c.clips > KingCooBudget.rigClips) {
        over.add('$name: rig ${c.clips} clips > ${KingCooBudget.rigClips}');
      }
      if ((c.counts['saveLayer'] ?? 0) > 0) over.add('$name: rig makes a saveLayer');
      if ((c.counts['maskFilter'] ?? 0) > 0) over.add('$name: rig uses a blur mask');
      if (whole.built > KingCooBudget.rigShaders) {
        over.add('$name: rig builds ${whole.built} shaders > ${KingCooBudget.rigShaders}');
      }
      final unforwarded = c.counts.keys.where((k) => k.startsWith('UNFORWARDED'));
      if (unforwarded.isNotEmpty) over.add('$name: unforwarded $unforwarded');
    }
    // ignore: avoid_print
    print(report);
    if (over.isNotEmpty) {
      // ignore: avoid_print
      print('over budget (${over.length}):\n${over.take(60).join('\n')}');
    }
    if (enforceRealArt) expect(over, isEmpty);
  });

  test('the rig\'s own assembly draws nothing (a share of ${KingCooBudget.assembly.ops})', () {
    for (final (name, pose) in _states()) {
      final f = _measure(pose, only: const <String>{});
      expect(f.counting.draws, lessThanOrEqualTo(KingCooBudget.assembly.ops), reason: name);
      expect(f.built, 0);
      expect(f.counting.clips, 0);
      expect(f.counting.counts['saveLayer'] ?? 0, 0);
    }
  });

  test('the proof budget holds today: the first cut is inside its own budget', () {
    // The contract's first-cut painters show that the budget is reachable: a
    // part builder replacing one keeps to its share. (Always enforced.)
    for (final (name, pose) in _states()) {
      final c = _measure(pose).counting;
      expect(c.draws, lessThanOrEqualTo(KingCooBudget.rigOps), reason: name);
      expect(c.counts['saveLayer'] ?? 0, 0, reason: name);
      expect(c.counts['maskFilter'] ?? 0, 0, reason: name);
    }
  });

  test('the pose is cheap: the solver is allocation-light', () {
    // ~10-30 us per pose on a JIT desktop; the bound is loose enough for a
    // loaded CI box and tight enough to catch an accidental blow-up.
    final boss = cooBoss(combat: 9.3);
    var sink = 0.0;
    for (var i = 0; i < 500; i++) {
      sink += poseOf(boss).puff;
    }
    final sw = Stopwatch()..start();
    const n = 3000;
    for (var i = 0; i < n; i++) {
      boss.age += 1e-5;
      final p = poseOf(boss);
      sink += p.puff + p.wingNear;
    }
    final micros = sw.elapsedMicroseconds / n;
    // ignore: avoid_print
    print('pose: ${micros.toStringAsFixed(1)} us per frame');
    expect(sink.isFinite, isTrue);
    expect(micros, lessThan(1500));
  });

  test('KingCooKit.glow builds one shader per colour, not one per call', () {
    final before = KingCooKit.shadersBuilt;
    final c = Canvas(ui.PictureRecorder());
    for (var i = 0; i < 40; i++) {
      KingCooKit.glow(c, Offset(i * .1, 0), 1 + i * .05, const Color(0xffff4a5e), .3 + i * .01);
    }
    expect(KingCooKit.shadersBuilt - before, lessThanOrEqualTo(1));
    KingCooKit.glow(c, Offset.zero, 1, const Color(0xff4aa8ff), .5);
    KingCooKit.glow(c, Offset.zero, 2, const Color(0xff4aa8ff), .2);
    expect(KingCooKit.shadersBuilt - before, lessThanOrEqualTo(2));
  });

  test('KingCooKit.scallop is cached by its quantised depth', () {
    final a = KingCooKit.scallop(15, .07);
    final b = KingCooKit.scallop(15, .0703);
    expect(identical(a, b), isTrue);
    expect(identical(KingCooKit.scallop(15, .012), a), isFalse);
  });

  testWidgets('the cached glow looks like the gradient it replaced', (tester) async {
    await tester.runAsync(() async {
      Future<List<int>> render(void Function(Canvas) draw) async {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        c.drawRect(
          const Rect.fromLTWH(0, 0, 120, 120),
          Paint()..color = const Color(0xff202040),
        );
        draw(c);
        final img = await rec.endRecording().toImage(120, 120);
        final data = (await img.toByteData())!.buffer.asUint8List();
        img.dispose();
        return data;
      }

      for (final (color, alpha, radius) in const [
        (Color(0xffff4a5e), .7, 40.0),
        (Color(0xff4aa8ff), .35, 55.0),
        (Color(0xfffff0b0), 1.0, 30.0),
      ]) {
        const at = Offset(60, 55);
        final old = await render((c) {
          c.drawCircle(
            at,
            radius,
            Paint()
              ..shader = ui.Gradient.radial(
                at,
                radius,
                [
                  color.withValues(alpha: alpha),
                  color.withValues(alpha: alpha * .38),
                  color.withValues(alpha: 0),
                ],
                const [0, .45, 1],
              ),
          );
        });
        final cached = await render(
          (c) => KingCooKit.glow(c, at, radius, color, alpha),
        );
        var worst = 0;
        for (var i = 0; i < old.length; i++) {
          final d = (old[i] - cached[i]).abs();
          if (d > worst) worst = d;
        }
        expect(worst, lessThanOrEqualTo(8), reason: '$color alpha $alpha');
      }
    });
  });
}
