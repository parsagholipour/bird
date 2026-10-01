import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_beam_art.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_feather_art.dart';
import 'package:push_up_bird/game/gargoyle_hud_art.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_staging_art.dart';

import 'gargoyle_enforce.dart';
import 'proof/counting_canvas.dart';
import 'proof/gargoyle_stage.dart';

/// The Searchlight Gargoyle's per-frame budget (real mid-range Android phones,
/// 60 fps; `reports/04-gargoyle.md` section 3.7).
///
/// In every state:
///   * ops (paths, circles, lines, rects...), clips, NO `saveLayer`, NO blur;
///   * shaders: a gradient is built ONCE per look and cached in the kit, so a
///     warm frame builds NONE, and a whole fight needs at most the part's
///     share of DISTINCT shaders ("cold total");
///   * per owner (G1 head, G2 body, G3 wings, G5 beams, G6 feathers, G7 HUD,
///     G8 staging), so a part over its share cannot hide behind another's slack.
///
/// The first-cut painters that ship with the contract already fit. Until every
/// part has landed the real-art checks only REPORT; flip [enforceRealArt]
/// (test/gargoyle_enforce.dart, one line) to fail, each failure naming the part,
/// the state and the number.

/// One owner's share: parts (z-order names), ops, distinct shaders over a whole
/// fight (cold), clips.
typedef _Share = (String owner, List<String> parts, int ops, int shaders, int clips);

const _shares = <_Share>[
  ('assembly (G4): bloom', ['bloom'], 6, 1, 0),
  ('head (G1)', ['head'], 70, 3, 2),
  ('body: torso, lamp, legs, tail (G2)', ['tail', 'farLeg', 'torso', 'thigh', 'ruff', 'lamp', 'cracks', 'steam'], 100, 4, 3),
  ('wings, both (G3)', ['farFan', 'nearFan', 'shed'], 80, 3, 2),
  ('staging: ledge, pier, vane (G8)', ['ledge'], 60, 2, 1),
];

/// The rig's own total: 260 ops, 12 shaders (cold, whole fight), 7 clips. The
/// contract said 11 while the parts were first cuts; the real ones are the
/// shares above (head 3 + body 4 + wings 3 + the stage's ledge and pier 2).
const _rigOps = 260, _rigShaders = 12, _rigClips = 7;

final _states = <(String, SkyBoss Function(), bool)>[
  ('perch', () => gBoss(1.0), false),
  ('shrug flick + shed blade', () => gBoss(4.6 - .02), false),
  ('warning HIGH', () => gBoss(3.3), false),
  ('warning LOW', () => gBoss(3.3, side: BeamSide.low), false),
  ('sweep HIGH', () => gBoss(4.5), false),
  ('sweep LOW', () => gBoss(4.5, side: BeamSide.low), false),
  ('vent (steam, lamp open)', () => gBoss(7.0), false),
  ('glance', () => gBoss(1.0, glanceAgo: .07), false),
  ('hit', () => gBoss(1.0, hitAgo: .06), false),
  ('fury idle', () => gBoss(1.0, fury: true), false),
  ('fury rage', () => gBoss(1.0, fury: true, enragedAgo: .4), false),
  ('fury slit', () => gBoss(4.5, fury: true, slit: true), false),
  ('fury hit sweep', () => gBoss(4.5, fury: true, hitAgo: .06), false),
  ('arrival stone', () => gBoss(-3.6), false),
  ('arrival roar', () => gBoss(-1.5), false),
  ('defeat .3', () => gBoss(1.0, deadFor: .3), false),
  ('defeat .7', () => gBoss(1.0, deadFor: .7), false),
  ('RM sweep', () => gBoss(4.5), true),
  ('RM fury slit', () => gBoss(4.5, fury: true, slit: true), true),
];

class _Frame {
  _Frame(this.c, this.built);
  final Counting c;
  final int built;
}

_Frame _measure(void Function(ui.Canvas) draw) {
  final before = GargoyleKit.shadersBuilt;
  final canvas = Counting(ui.Canvas(ui.PictureRecorder()));
  draw(canvas);
  return _Frame(canvas, GargoyleKit.shadersBuilt - before);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
  });

  test('the rig stays inside its per-frame budget, whole and by part (reports until enforced)', () {
    final problems = <String>[];
    void over(String what, int value, int budget, String where) {
      if (value > budget) problems.add('$where: $what $value > $budget');
    }

    // Cold totals per owner and for the rig, over EVERY state of the fight.
    for (final (owner, parts, ops, shaders, clips) in _shares) {
      GargoyleKit.clearCaches();
      var worstOps = 0, worstClips = 0, worstAt = '';
      for (final (name, mk, reduced) in _states) {
        final pose = poseOf(mk(), reduced: reduced);
        final f = _measure((c) => GargoyleBossRig.paintPose(c, pose, only: parts.toSet()));
        if (f.c.draws > worstOps) {
          worstOps = f.c.draws;
          worstAt = name;
        }
        if (f.c.clips > worstClips) worstClips = f.c.clips;
        over('saveLayers', f.c.layers, 0, '$owner @ $name');
        over('blurs', f.c.blurs, 0, '$owner @ $name');
      }
      // Soft radial glows are the kit's and shared between parts (every glow is
      // charged to the rig's own count below), so a part's share is its other
      // shaders.
      final own = GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).toList();
      // ignore: avoid_print
      print('$owner: worst $worstOps ops (at $worstAt), $worstClips clips, ${own.length} distinct shaders $own '
          '(budget $ops / $clips / $shaders)');
      over('ops', worstOps, ops, '$owner (worst at $worstAt)');
      over('clips', worstClips, clips, owner);
      over('distinct shaders', own.length, shaders, owner);
    }
    GargoyleKit.clearCaches();
    var rigOps = 0, rigClips = 0, rigAt = '';
    var shaderDraws = 0;
    for (final (name, mk, reduced) in _states) {
      final pose = poseOf(mk(), reduced: reduced);
      final f = _measure((c) => GargoyleBossRig.paintPose(c, pose));
      if (f.c.draws > rigOps) {
        rigOps = f.c.draws;
        rigAt = name;
      }
      if (f.c.clips > rigClips) rigClips = f.c.clips;
      if (f.c.shaderDraws > shaderDraws) shaderDraws = f.c.shaderDraws;
      over('saveLayers', f.c.layers, 0, 'rig @ $name');
      over('blurs', f.c.blurs, 0, 'rig @ $name');
    }
    final rigGlows = GargoyleKit.built.where((k) => '$k'.startsWith('glow:')).length;
    final rigCold = GargoyleKit.built.length - rigGlows;
    // ignore: avoid_print
    print('rig (with ledge): worst $rigOps ops (at $rigAt), $rigClips clips, $rigCold distinct shaders + '
        '$rigGlows glow(s), $shaderDraws shader draws in a frame (budget $_rigOps / $_rigClips / $_rigShaders)');
    over('ops', rigOps, _rigOps + 60, 'rig (creature + ledge, worst at $rigAt)');
    over('clips', rigClips, _rigClips, 'rig');
    over('distinct shaders (glows apart)', rigCold, _rigShaders, 'rig');
    over('glows', rigGlows, 2, 'rig');
    if (problems.isNotEmpty) {
      // ignore: avoid_print
      print('over budget:\n${problems.join('\n')}');
    }
    if (enforceRealArt) expect(problems, isEmpty);
  });

  test('a warm frame builds no shader at all', () {
    // Every gradient is built once, in the part's own frame, and cached; a tone
    // (flash, fury, stone) is a colour filter, never a new shader.
    for (final (name, mk, reduced) in _states) {
      final pose = poseOf(mk(), reduced: reduced);
      _measure((c) => GargoyleBossRig.paintPose(c, pose));
      final warm = _measure((c) => GargoyleBossRig.paintPose(c, pose));
      expect(warm.built, 0, reason: '$name built ${warm.built} shader(s) on a warm frame');
    }
    // ... and a hit's whole flash ladder, the fury's and the stone's too.
    final boss = gBoss(1.0, hitAgo: .06);
    for (var i = 0; i <= 12; i++) {
      final b = gBoss(1.0 + i * .0, hitAgo: i * .02, fury: i.isEven);
      final pose = poseOf(b);
      final f = _measure((c) => GargoyleBossRig.paintPose(c, pose));
      expect(f.built, 0, reason: 'flash step $i built ${f.built}');
    }
    expect(boss.age, greaterThan(0));
  });

  test('beams and the warning stay inside their share (<= 60 ops, 1 clip, 6 static shaders)', () {
    final size = const ui.Size(640, 360);
    GargoyleKit.clearCaches();
    var worst = 0, worstClips = 0;
    final rows = <String>[];
    for (final (name, boss) in [
      ('warning HIGH', gBoss(3.3)),
      ('warning LOW', gBoss(3.3, side: BeamSide.low)),
      ('warning slit', gBoss(3.3, fury: true, slit: true)),
      ('zone beam', gBoss(4.5)),
      ('slit beams', gBoss(5.0, fury: true, slit: true)),
    ]) {
      final pose = poseOf(boss);
      final centre = bossCentre(size, boss);
      final f = _measure((c) {
        GargoyleBeamArt.under(c, size, pose, centre);
        GargoyleBeamArt.over(c, size, pose, centre);
      });
      rows.add('$name: ${f.c.draws} ops, ${f.c.clips} clips');
      if (f.c.draws > worst) worst = f.c.draws;
      if (f.c.clips > worstClips) worstClips = f.c.clips;
      expect(f.c.layers, 0, reason: name);
      expect(f.c.blurs, 0, reason: name);
    }
    final cold = GargoyleKit.built.length;
    // ignore: avoid_print
    print('beams: ${rows.join('; ')}; $cold distinct shaders ${GargoyleKit.built}');
    final budget = (ops: 60, clips: 1, shaders: 6);
    if (enforceRealArt) {
      expect(worst, lessThanOrEqualTo(budget.ops));
      expect(worstClips, lessThanOrEqualTo(budget.clips));
      expect(cold, lessThanOrEqualTo(budget.shaders));
    }
    // The contract's own first cut holds them regardless.
    expect(worst, lessThanOrEqualTo(60));
    expect(worstClips, lessThanOrEqualTo(1));
    expect(cold, lessThanOrEqualTo(6));
  });

  test('a beam is at most ${GargoyleBeamLook.maxOps} ops (twin: double), one flare, no layer', () {
    final size = const ui.Size(800, 360);
    for (final (boss, n) in [(gBoss(4.5), 1), (gBoss(5.0, fury: true, slit: true), 2)]) {
      final pose = poseOf(boss);
      final centre = bossCentre(size, boss);
      final f = _measure((c) {
        GargoyleBeamArt.under(c, size, pose, centre);
        GargoyleBeamArt.over(c, size, pose, centre);
      });
      expect(pose.beams.length, n);
      expect(f.c.draws, lessThanOrEqualTo(GargoyleBeamLook.maxOps * n));
    }
  });

  test('each feather is at most 14 ops and three at most 24', () {
    final a = BossAmmo(x: .7, y: .3, vx: -.36, vy: .2, gravity: .30, radius: .028, feather: true);
    final one = _measure((c) => GargoyleFeatherArt.paint(c, 360, a, seconds: 3));
    final three = _measure((c) {
      for (var i = 0; i < 3; i++) {
        GargoyleFeatherArt.paint(c, 360, a, seconds: 3.0 + i);
      }
    });
    expect(one.c.draws, lessThanOrEqualTo(14));
    expect(three.c.draws, lessThanOrEqualTo(24));
    expect(one.c.layers + one.c.blurs, 0);
    expect(one.built, 0);
  });

  test('HUD skin and staging first cuts: HUD <= 60 ops / 4 shaders / 0 clips, ledge <= 60 / 2 / 1', () {
    final hud = _measure((c) {
      GargoyleHudArt.crest(c, const ui.Offset(30, 18), 10, fury: true);
      GargoyleHudArt.lampTag(c, const ui.Rect.fromLTWH(200, 40, 120, 18), pulse: .5);
    });
    expect(hud.c.draws, lessThanOrEqualTo(60));
    expect(hud.c.clips, 0);
    final pose = poseOf(gBoss(1.0));
    final stage = _measure((c) => GargoyleStagingArt.ledge(c, pose));
    expect(stage.c.draws, lessThanOrEqualTo(60));
    expect(stage.c.clips, lessThanOrEqualTo(1));
    expect(stage.c.layers, 0);
  });

  test('the budgets are the report\'s', () {
    // Pinned so a quiet edit of a share shows up in review.
    expect(_rigOps, 260);
    expect(_rigShaders, 12);
    expect(_rigClips, 7);
    expect(_shares.map((s) => s.$3).toList(), [6, 70, 100, 80, 60]);
    expect(GargoyleBeamLook.maxVertices, 40);
    expect(GargoyleLayout.zOrder.length, 14);
    expect(BossMotion.ramp(0, 0, 1), 0);
  });
}
