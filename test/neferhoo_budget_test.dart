import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/neferhoo_boss_rig.dart';
import 'package:push_up_bird/game/neferhoo_fight_art.dart';
import 'package:push_up_bird/game/neferhoo_fx.dart';
import 'package:push_up_bird/game/neferhoo_kit.dart';
import 'package:push_up_bird/game/neferhoo_pose.dart';
import 'package:push_up_bird/game/neferhoo_props_art.dart';

import 'neferhoo_art_support.dart';

/// Neferhoo's per-frame cost at 640x360 (the rig at 41.4 px per unit),
/// measured with the design's counting proxy: every cached picture counts
/// what it replays on the raster thread, so "effective" = draw calls - picture
/// calls + replayed ops (`NeferhooKit.debugWrap`, set before any cache is
/// built). Budgets (design §5.9 and iteration 5): the rig calm <= 240
/// (the design measured 230; the open-sky gag 237), the busiest <= 330
/// (fury express 324); combat draws no saveLayer and no blur; each attack
/// effect inside its share.

/// The rig of [boss] now, as the encounter places it at 640x360.
void _rig(Canvas c, SkyBoss boss, {bool reduced = false}) {
  c.save();
  c.translate(boss.x * 360, boss.y * 360);
  c.scale(360 * SkyBoss.radius);
  NeferhooBossRig.paint(c, boss, BossMotion(boss, reducedMotion: reduced));
  c.restore();
}

void _pose(Canvas c, NeferhooPose p) {
  c.save();
  c.translate(300, 200);
  c.scale(41.4);
  NeferhooBossRig.paintPose(c, p);
  c.restore();
}

String _row(String name, OpCounter k) =>
    '${name.padRight(46)} ${k.draws.toString().padLeft(5)} ${k.pictures.toString().padLeft(4)} ${k.replayDraws.toString().padLeft(6)} ${k.effective.toString().padLeft(6)} ${(k.clips + k.replayClips).toString().padLeft(4)} ${(k.shaderDraws + k.replayShaders).toString().padLeft(5)} ${(k.layers + k.replayLayers).toString().padLeft(4)} ${k.blurs.toString().padLeft(4)}';

final _log = StringBuffer('frame                                          draws  pic replay  effec clip  shdr  lay  blr\n');

OpCounter _measure(String name, void Function(Canvas) draw) {
  final k = measure(draw);
  _log.writeln(_row(name, k));
  expect(k.layers + k.replayLayers, 0, reason: '$name: no saveLayer in combat');
  expect(k.blurs, 0, reason: '$name: no blur in combat');
  expect(k.counts.keys.where((key) => key.startsWith('UNFORWARDED')), isEmpty, reason: name);
  return k;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    NeferhooKit.debugWrap = OpCounter.new;
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });
  tearDownAll(() {
    NeferhooKit.debugWrap = null;
    // ignore: avoid_print
    print(_log);
  });

  test('the rig: calm <= 240, the busiest <= 330 effective ops (the design\'s key poses)', () {
    final calm = _measure('rig: calm', (c) => _pose(c, NeferhooPose(crest: .4, wing: .2, phase: .3)));
    expect(calm.effective, lessThanOrEqualTo(240));
    final poses = <(String, NeferhooPose)>[
      ('rig: mail call (open, fan held)', NeferhooPose(crest: .42, wing: .45, cards: 3, satchelOpen: 1, reach: 1, wingRate: 0, brow: -.4, lean: .05, phase: .5, glint: .5)),
      ('rig: ankh raised', NeferhooPose(crest: 1, wing: -.9, wingRate: 0, ankh: 1, glow: .9, brow: -.7, phase: .7)),
      ('rig: returned (stamp, hit)', NeferhooPose(crest: .6, wing: -.8, hit: 1, stamp: 1, lid: .6, beak: .55, brow: .6, lean: .2, headTilt: .15, legs: 1, phase: .9)),
      ('rig: fury (unwrap, crack, glow)', NeferhooPose(crest: 1, wing: -.6, fury: 1, unwrap: .8, cracked: 1, glow: 1, brow: -1, beak: .35, ribbons: 1.2, phase: 1.0)),
      ('rig: FURY EXPRESS = busiest', NeferhooPose(crest: .6, wing: .45, fury: 1, unwrap: .8, cracked: 1, glow: 1, brow: -1, cards: 3, satchelOpen: 1, reach: 1, wingRate: 0, sweep: .6, lean: -.1, phase: 1.1)),
      ('rig: the gag (buff 1, ring glint)', NeferhooPose(crest: .4, wing: .1, buff: 1, phase: 10.4, ringGlint: .5, lid: .34)),
    ];
    for (final (name, p) in poses) {
      expect(_measure(name, (c) => _pose(c, p)).effective, lessThanOrEqualTo(330), reason: name);
    }
    expect(_measure('rig: the gag (buff 1, ring glint)', (c) => _pose(c, poses.last.$2)).effective, lessThanOrEqualTo(240));
  });

  test('the fight, sampled every 1/12 s over whole cycles at 640, 800 and 864 px: calm idle and the gag <= 240, every frame <= 330', () {
    for (final px in [640.0, 800.0, 864.0]) {
      for (final stage in [1, 2]) {
        final boss = courier(px: px, stage: stage);
        var worst = 0, worstIdle = 0, worstGag = 0;
        for (var i = 0; i < 12 * 12 * 2; i++) {
          final t = 12 + i / 12;
          fightTo(boss, t);
          final pose = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false));
          final k = measure((c) => _rig(c, boss));
          expect(k.layers + k.replayLayers + k.blurs, 0);
          worst = math.max(worst, k.effective);
          final ct = boss.mailCycle;
          final idle = pose.cards == 0 && pose.satchelOpen < .01 && pose.ankh <= 0 && pose.reach <= 0 && pose.glow < .01 && pose.sweep <= 0 && pose.buff <= 0 && ct > 3.8;
          if (idle) worstIdle = math.max(worstIdle, k.effective);
          if (pose.buff > 0) worstGag = math.max(worstGag, k.effective);
        }
        _log.writeln('timeline ${px.round()} px ${stage == 2 ? 'fury' : 'calm'}: whole cycle $worst, idle $worstIdle, the gag $worstGag');
        expect(worst, lessThanOrEqualTo(330), reason: '$px px stage $stage');
        if (stage == 1) {
          expect(worstIdle, lessThanOrEqualTo(240), reason: '$px px calm idle');
          expect(worstGag, lessThanOrEqualTo(240), reason: '$px px calm gag');
        }
      }
    }
  });

  test('each attack effect inside its share (screen px at 640x360)', () {
    const size = Size(640, 360);
    final shares = <(String, int, void Function(Canvas))>[
      ('letter at rest', 24, (c) => NeferhooPropsArt.letter(c, const Offset(300, 180), 360)),
      ('letter in flight', 30, (c) => NeferhooPropsArt.letter(c, const Offset(300, 180), 360, flutter: .6, tilt: .05)),
      ('letter, express', 32, (c) => NeferhooPropsArt.letter(c, const Offset(300, 180), 360, flutter: .6, fury: true)),
      ('letter, returned', 30, (c) => NeferhooPropsArt.letter(c, const Offset(300, 180), 360, returned: 1)),
      ('mail lane + tag', 40, (c) => NeferhooPropsArt.mailLane(c, size, .46, 1.13, clock: 1.7)),
      ('mail lane + tag (express)', 40, (c) => NeferhooPropsArt.mailLane(c, size, .46, 1.13, fury: true, clock: 1.7)),
      ('ankh loop + tag', 64, (c) => NeferhooPropsArt.ankhTelegraph(c, size, 1.1, .3)),
      ('ankh loop + tag (two ankhs)', 80, (c) => NeferhooPropsArt.ankhTelegraph(c, size, 1.1, .3, fury: true)),
      ('flying ankh (20-point trail)', 40, (c) => NeferhooPropsArt.flyingAnkh(c, const Offset(1.0, .3), 360, 1.2, trail: [for (var i = 0; i < 20; i++) Offset(1.0 + i * .008, .3)])),
      ('returned letter in flight', 38, (c) => NeferhooPropsArt.returnedLetter(c, const Offset(.8, .45), const Offset(1.2, .5), 360, .5)),
      ('return burst t=.3', 34, (c) => NeferhooPropsArt.returnBurst(c, const Offset(1.2, .5), 360, .3)),
      ('glyph motes (strength 1)', 24, (c) => NeferhooFx.glyphMotes(c, const Offset(440, 190), 360, 3)),
    ];
    for (final (name, cap, draw) in shares) {
      expect(_measure(name, draw).effective, lessThanOrEqualTo(cap), reason: name);
    }
  });

  test('the whole fight art of the busiest moments (fury express in flight, two ankhs, a return)', () {
    for (final px in [640.0, 800.0]) {
      final size = Size(px, 360);
      final boss = courier(px: px, stage: 2);
      var worst = 0;
      for (final t in [12 + 2.6, 12 + 3.1, 12 + 7.0, 12 + 7.6, 12 + 8.4]) {
        fightTo(boss, t);
        final live = boss.liveLetters.where((l) => !l.returned).toList();
        if (live.length > 1 && t < 12 + 3.2) returnLetter(boss, live.first);
        final m = BossMotion(boss, reducedMotion: false);
        final k = _measure('fight art ${px.round()} t=${(t - 12).toStringAsFixed(1)} (under + over)', (c) {
          NeferhooFightArt.under(c, size, boss, m);
          NeferhooFightArt.over(c, size, boss, m);
        });
        worst = math.max(worst, k.effective);
      }
      expect(worst, lessThanOrEqualTo(260), reason: '$px px');
    }
  });

  test('Reduced Motion costs no more', () {
    final boss = courier(stage: 2);
    fightTo(boss, 12 + 1.9);
    final moving = measure((c) => _rig(c, boss)).effective;
    final still = measure((c) => _rig(c, boss, reduced: true)).effective;
    expect(still, lessThanOrEqualTo(moving + 4));
  });
}
