import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

import 'dragon_enforce.dart';

/// The Ember Dragon's per-frame budget (real mid-range Android phones, 60 fps).
///
/// The rig (everything `DragonBossRig.paintPose` draws) must, in every state:
///   * make at most [maxOps] draw calls (paths, circles, lines, rects...),
///   * at most [maxClips] clipPaths, no saveLayer and no blur mask,
///   * build at most [maxShaders] gradient shaders on a warm frame (the
///     pose-independent ones live in `static final` or `DragonKit.cached`).
/// Each part has its own share too (bible section 7): a failure names the
/// part, the state and the number. The rig's total is the sum of the parts'
/// shares with headroom, so a part over its share can hide behind another
/// part's slack in the total; the per-part lines catch it.
///
/// Until every part has landed this REPORTS; flip [enforceRealArt]
/// (test/dragon_enforce.dart, one line) to fail.
const maxOps = 350, maxClips = 10, maxShaders = 15;

/// One owner's share: parts (z-order names), draw ops, shaders BUILT per warm
/// frame, clips.
typedef _Share = (String owner, List<String> parts, int ops, int shaders, int clips);

const _shares = <_Share>[
  ('rig (B4)', ['bloom'], 6, 1, 0),
  // B9: the torso, tail, legs, neck and head are painted as ONE hide (one
  // outline, one skin, see dragon_hide_art.dart), so their old shares - head+
  // neck (B1) 80 ops / 3 shaders / 2 clips and body (B2) 110 / 4 / 3 - are
  // one joint share, measured together (the parts no longer paint alone in a
  // real frame; alone, each still wears its own outline). Measured: 4 clips
  // (the trunk's three - the union, and the two nested ones that carve the sky
  // and fire crescents - plus the skull's), 5 while an open jaw hangs over
  // the throat (one more keeps the throat's belly plates behind it), against
  // the old 5; and 144-173 ops against the old 190 (the shared outline
  // replaces five double strokes). So the share is the old ones' sum,
  // tightened to what the hide needs plus a little headroom.
  (
    'hide: neck+head+body (B1+B2+B9)',
    [
      'farLegs+tail',
      'torso',
      'hindLeg',
      'neck',
      'head',
      'heart',
      'foreleg',
      'smoke',
    ],
    180,
    4,
    5,
  ),
  ('wings (B3)', ['farWing', 'nearWing'], 90, 4, 3),
];

/// The rig's own total (bible section 7): 300 ops, 12 shaders, 8 clips.
const _rigOps = 300, _rigShaders = 12, _rigClips = 8;

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

SkyBoss _boss(double combat, void Function(SkyBoss) setup, {bool fury = false}) {
  final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8;
  if (fury) b.hp = b.maxHp ~/ 3;
  b.age = b.arrivalDuration + combat;
  setup(b);
  return b;
}

/// The states measured: name, combat second, setup, fury. The worst frames of
/// the cycle for the art (most parts lit, widest fans, most effects).
final _states = <(String, double, void Function(SkyBoss), bool)>[
  ('idle', 1.2, (b) {}, false),
  ('idle 2', 2.6, (b) {}, false),
  ('charge', 1.2, (b) => b.fireIn = .05, false),
  ('launch', 1.2, (b) => b.lastVolleyAt = b.age - .1, false),
  ('alert', 3.7, (b) {}, false),
  ('rear', 4.7, (b) {}, false),
  ('hold', 5.05, (b) {}, false),
  ('snap', 5.24, (b) {}, false),
  ('blast high', 5.8, (b) => b.breathLane = BreathLane.high, false),
  ('blast mid', 5.8, (b) {}, false),
  ('blast low', 5.8, (b) => b.breathLane = BreathLane.low, false),
  ('gutter', 7.3, (b) {}, false),
  ('call wind', 7.45, (b) {}, false),
  ('call', 7.9, (b) => b.lastSummonAt = b.age - .3, false),
  ('hit', 1.2, (b) => b.lastHitAt = b.age - .1, false),
  ('heart hit', 5.0, (b) => b.lastHitAt = b.lastCoreHitAt = b.age - .1, false),
  ('fury idle', 1.2, (b) {}, true),
  ('fury rage', 1.2, (b) => b.enragedAt = b.age - .4, true),
  ('fury charge', 1.2, (b) => b.fireIn = .05, true),
  ('fury hold', 5.05, (b) {}, true),
  ('fury blast', 5.8, (b) {}, true),
  ('fury call', 7.9, (b) {}, true),
  ('fury call 2', 9.3, (b) {}, true),
  ('defeat .3', 1.2, (b) => b.defeatedAt = b.age - .3, false),
  ('defeat .7', 1.2, (b) => b.defeatedAt = b.age - .7, false),
];

/// What one paint asked of the canvas, and how many shaders it built.
class _Frame {
  _Frame(this.counting, this.built);
  final Counting counting;
  final int built;
}

_Frame _measure(DragonPose pose, {Set<String>? only}) {
  final before = DragonKit.shadersBuilt;
  final canvas = Counting(Canvas(ui.PictureRecorder()));
  // (warm: false: the prewarm belongs to a game frame; a budget counts the
  // frame's own paints)
  DragonBossRig.paintPose(canvas, pose, only: only, warm: false);
  return _Frame(canvas, DragonKit.shadersBuilt - before);
}

void main() {
  test('a whole fight never hitches: a frame builds at most 8 shaders (was 32)', () {
    // Tone-keyed gradients used to be built, all of them, in the frame the
    // tone first reached a key: 5 to 6 per heat step of the inhale, 25 to 30 at
    // each step of the fury's blend and of a hit's flash. The prewarm (the
    // arrival queues the ladders, each new tone queues its neighbours, a quiet
    // frame paints one queued tone into a picture nobody sees) spreads them.
    // A fresh process: this must run before anything else paints a dragon.
    final hist = <int, int>{};
    var worst = 0, worstAt = 0.0, real = 0;
    final warmedBefore = DragonBossRig.warmedShaders;
    for (var i = 0; i < 60 * 44; i++) {
      final age = i / 60.0, combat = age - 4.6;
      final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
        ..fireIn = 1.8
        ..age = age;
      if (combat > 22.3) {
        b.hp = b.maxHp ~/ 3;
        b.enragedAt = 4.6 + 22.3;
      }
      // Hits mid-inhale (the worst mix of flash and heat) and mid-fury.
      if (combat > 15 && combat < 15.3) b.lastHitAt = 4.6 + 15.0;
      if (combat > 26 && combat < 26.3) b.lastHitAt = 4.6 + 26.0;
      final pose = DragonPose(
        b,
        BossMotion(b, reducedMotion: false),
        light: const DragonSkyLight(dark: .93),
      );
      final before = DragonKit.shadersBuilt;
      final warmBefore = DragonBossRig.warmedShaders;
      DragonBossRig.paintPose(Canvas(ui.PictureRecorder()), pose);
      final built =
          DragonKit.shadersBuilt -
          before -
          (DragonBossRig.warmedShaders - warmBefore);
      if (combat > 0) {
        real++;
        hist[built] = (hist[built] ?? 0) + 1;
        if (built > worst) {
          worst = built;
          worstAt = combat;
        }
      }
    }
    final keys = hist.keys.toList()..sort();
    // ignore: avoid_print
    print(
      'fight replay: worst $worst shaders in a frame (at ${worstAt.toStringAsFixed(2)} s) '
      'over $real frames; histogram ${{for (final k in keys) k: hist[k]}}; '
      'the prewarm built ${DragonBossRig.warmedShaders - warmedBefore} ahead of time',
    );
    expect(DragonBossRig.warmedShaders, greaterThan(warmedBefore));
    expect(worst, lessThanOrEqualTo(8), reason: 'worst frame at $worstAt s');
    final heavy = hist.entries.where((e) => e.key > 4).fold(0, (a, e) => a + e.value);
    expect(heavy / real, lessThan(.03), reason: 'frames over 4 shaders');
  });

  test('the rig stays inside its per-frame budget, whole and by part', () {
    final poses = [
      for (final (name, t, setup, fury) in _states)
        (
          name,
          () {
            final boss = _boss(t, setup, fury: fury);
            return DragonPose(boss, BossMotion(boss, reducedMotion: false));
          }(),
        ),
    ];
    // Warm every cache the states share, then measure a steady-state frame.
    for (final (_, pose) in poses) {
      DragonBossRig.paintPose(Canvas(ui.PictureRecorder()), pose, warm: false);
    }
    final report = StringBuffer();
    final over = <String>[];
    report.writeln(
      'state         ops  shader-draws built clips layers blur | '
      'rig / hide (neck+head+body) / wings ops',
    );
    for (final (name, pose) in poses) {
      final whole = _measure(pose);
      final c = whole.counting;
      final shares = <String>[];
      for (final (owner, parts, ops, shaders, clips) in _shares) {
        // (A share is painted as a group: the hide's parts are one thing.)
        final group = parts.toSet();
        _measure(pose, only: group); // warm this group's caches
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
        '${name.padRight(12)} ${c.draws.toString().padLeft(4)} '
        '${c.shaderDraws.toString().padLeft(12)} '
        '${whole.built.toString().padLeft(5)} ${c.clips.toString().padLeft(5)} '
        '${(c.counts['saveLayer'] ?? 0).toString().padLeft(6)} '
        '${(c.counts['maskFilter'] ?? 0).toString().padLeft(4)} | ${shares.join(' / ')}',
      );
      if (c.draws > maxOps || c.draws > _rigOps) {
        over.add('$name: rig ${c.draws} ops > $_rigOps');
      }
      if (c.clips > maxClips || c.clips > _rigClips) {
        over.add('$name: rig ${c.clips} clips > $_rigClips');
      }
      if ((c.counts['saveLayer'] ?? 0) > 0) over.add('$name: rig makes a saveLayer');
      if ((c.counts['maskFilter'] ?? 0) > 0) over.add('$name: rig uses a blur mask');
      if (whole.built > maxShaders || whole.built > _rigShaders) {
        over.add('$name: rig builds ${whole.built} shaders > $_rigShaders');
      }
    }
    // ignore: avoid_print
    print(report);
    if (over.isNotEmpty) {
      // ignore: avoid_print
      print('over budget (${over.length}):\n${over.take(60).join('\n')}');
    }
    if (enforceRealArt) expect(over, isEmpty);
  });

  test('the rig itself is inside its own share (always enforced)', () {
    // Bloom: at most 2 glows, no shader built on a warm frame, no clip, no
    // layer, whatever the light and the heat.
    for (final dark in [0.0, .5, 1.0]) {
      for (final (name, t, setup, fury) in _states) {
        final boss = _boss(t, setup, fury: fury);
        final pose = DragonPose(
          boss,
          BossMotion(boss, reducedMotion: false),
          light: DragonSkyLight(dark: dark),
        );
        DragonBossRig.paintPose(Canvas(ui.PictureRecorder()), pose, only: {'bloom'}, warm: false);
        final f = _measure(pose, only: {'bloom'});
        expect(f.counting.draws, lessThanOrEqualTo(2), reason: '$name dark $dark');
        expect(f.built, 0, reason: '$name dark $dark builds a shader per frame');
        expect(f.counting.clips, 0);
        expect(f.counting.counts['saveLayer'] ?? 0, 0);
        expect(f.counting.counts['maskFilter'] ?? 0, 0);
      }
    }
  });

  test('the pose is cheap: wings, neck drag and tail samples included', () {
    // ~12-50 us per pose on a JIT desktop; the bound is loose enough for a
    // loaded CI box and tight enough to catch an accidental blow-up (the
    // wings evaluate the whole state machine for each lagged joint).
    final boss = _boss(5.9, (b) {});
    final m = BossMotion(boss, reducedMotion: false);
    var sink = 0.0;
    for (var i = 0; i < 500; i++) {
      final p = DragonPose(boss, m);
      sink += p.nearWing.elbow + p.tailBend(1);
    }
    final sw = Stopwatch()..start();
    const n = 3000;
    for (var i = 0; i < n; i++) {
      boss.age += 1e-5;
      final p = DragonPose(boss, m);
      sink += p.nearWing.elbow + p.farWing.elbow + p.tailBend(1) + p.tailBend(.5);
    }
    final micros = sw.elapsedMicroseconds / n;
    // ignore: avoid_print
    print('pose: ${micros.toStringAsFixed(1)} us per frame');
    expect(sink.isFinite, isTrue);
    expect(micros, lessThan(1500));
  });

  test('DragonKit.glow builds one shader per colour, not one per call', () {
    final before = DragonKit.shadersBuilt;
    final c = Canvas(ui.PictureRecorder());
    for (var i = 0; i < 40; i++) {
      DragonKit.glow(c, Offset(i * .1, 0), 1 + i * .05, DragonPalette.flame, .3 + i * .01);
    }
    expect(DragonKit.shadersBuilt - before, lessThanOrEqualTo(1));
    DragonKit.glow(c, Offset.zero, 1, DragonPalette.flameGold, .5);
    DragonKit.glow(c, Offset.zero, 2, DragonPalette.flameGold, .2);
    expect(DragonKit.shadersBuilt - before, lessThanOrEqualTo(2));
  });

  testWidgets('the cached glow looks like the gradient it replaced', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The formula the kit used before it cached: a fresh radial, colour
      // stops carrying the alpha.
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
        (DragonPalette.flame, .7, 40.0),
        (DragonPalette.flameGold, .35, 55.0),
        (DragonPalette.rimSky, 1.0, 30.0),
        (DragonPalette.flame, .05, 50.0),
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
          (c) => DragonKit.glow(c, at, radius, color, alpha),
        );
        var worst = 0;
        for (var i = 0; i < old.length; i++) {
          worst = worst < (old[i] - cached[i]).abs() ? (old[i] - cached[i]).abs() : worst;
        }
        expect(worst, lessThanOrEqualTo(3), reason: '$color alpha $alpha');
      }
    });
  });
}
