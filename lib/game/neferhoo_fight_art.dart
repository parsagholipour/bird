import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_health_bar_art.dart';
import 'boss_motion.dart';
import 'boss_stage_hud_art.dart';
import 'neferhoo_fx.dart';
import 'neferhoo_kit.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_pose.dart';
import 'neferhoo_props_art.dart';
import 'neferhoo_timeline.dart';

/// Neferhoo's attacks on screen, exactly where the rules put them
/// ([NeferhooBoss], [NeferhooLetter], [NeferhooAnkh]): ported from the
/// approved design (`egypt-ws/iter5/test/egypt/mummy_fx.dart`,
/// `mummy_props_art.dart`, the in-game frame of `mummy_frames_test.dart`).
///
/// Two passes keep the design's draw order around his rig:
///
///  * [under] (the encounter's backdrop, under everything that flies): the
///    MAIL CALL lane (its corridor IS the band in which a letter hurts the
///    bird: the letter's half height plus the bird's radius) with its tag,
///    and the ANKH's loop (the rules' path, out, the turn behind the bird,
///    back) with the two crossing bands numbered 1 and 2 (the ankh's radius
///    plus the bird's), fury's mirrored loop in turquoise;
///  * [over] (right after the rig, still under the rocks and the bird): his
///    magic's glyph motes, the letters in flight (each body the rules'
///    rectangle; near the bird their rocking is calmed so every edge stays
///    within a pixel of it), the flying ankhs (their first
///    [NeferhooTimeline.ankhEase] seconds leave the hover point over his
///    shoulder, then the rules' centre exactly), the returned letters homing
///    in with the RETURN TO SENDER label, the landing bursts (postmark slam,
///    paper confetti, the damage) and the cloth puff of a rock on his wraps.
///
/// Nothing is drawn unless he is fighting. Under Reduced Motion the lane and
/// the loop stay (their march stops), the letters and the ankhs keep still
/// (no rocking, no spin), the motes go. No `saveLayer`, no blur.
abstract final class NeferhooFightArt {
  // ------------------------------------------------------- the geometry --

  /// Half the mail lane's height (screen heights): the band about the lane in
  /// which a letter can touch the bird's circle.
  static const laneHalfBand = Neferhoo.letterHalfHeight + FlightSimulation.birdRadius;

  /// Half the ankh band's height at the bird's column (screen heights).
  static const ankhReach = Neferhoo.ankhRadius + FlightSimulation.birdRadius;

  /// The rules' rectangle of [letter] at boss age [age] (before it is
  /// returned), in px on a screen [h] px high: what the art draws as its body.
  static Rect letterRect(NeferhooLetter letter, SkyBoss boss, double h, {double? age}) {
    final x = letter.xAt(age ?? boss.age, boss.handX);
    return Rect.fromCenter(
      center: Offset(x * h, letter.yAt(age ?? boss.age) * h),
      width: Neferhoo.letterHalfWidth * 2 * h,
      height: Neferhoo.letterHalfHeight * 2 * h,
    );
  }

  /// How much a flying letter at screen x [x] may rock (1 = the design's
  /// .13 rad at most): calmed to [nearRock] within .1 of the bird's column,
  /// so the drawn corners stay within a pixel of the rules' rectangle where
  /// the letter can touch the bird.
  static double rockAt(double x) {
    final near = 1 - NeferhooKit.smooth01(((x - FlightSimulation.birdX).abs() - .1) / .15);
    return 1 - (1 - nearRock) * near;
  }

  static const nearRock = .3;

  /// The drawn centre of [ankh] (screen fractions) at boss age [age]: the
  /// rules' centre ([NeferhooAnkh.at]), its first [NeferhooTimeline.ankhEase]
  /// seconds blended from the hover point over his shoulder; null when it is
  /// not in flight.
  static Offset? ankhCentre(NeferhooAnkh ankh, SkyBoss boss, {double? age, bool reduced = false}) {
    final t = age ?? boss.age;
    final turn = Neferhoo.turnX(FlightSimulation.birdX);
    final at = ankh.at(t, handX: boss.handX, turnX: turn);
    if (at == null) return null;
    final k = NeferhooKit.smooth01((t - ankh.thrownAt) / NeferhooTimeline.ankhEase);
    final p = Offset.lerp(neferhooAnkhHover(boss.x, drawnY(boss, reduced: reduced)), Offset(at.$1, at.$2), k)!;
    // the catch: its last [catchEase] seconds glide from the rules' lane B into
    // his hand, wherever the lane is (it is then at least .5 screen heights
    // right of the bird's column, where nothing can be hit)
    final home = ankh.caughtAt ?? ankh.homeAt(handX: boss.handX, turnX: turn);
    final c = NeferhooKit.smooth01((t - (home - catchEase)) / catchEase);
    return c <= 0 ? p : Offset.lerp(p, handPoint(boss, reduced: reduced), c);
  }

  /// How long the drawn ankh takes to glide from its lane into his hand.
  static const catchEase = .3;

  /// His catching hand (screen fractions): the rules' hand x
  /// ([NeferhooBoss.handX]) at the height he holds his fan
  /// ([NeferhooLayout.dealPoint]), on the drawn chest.
  static Offset handPoint(SkyBoss boss, {bool reduced = false}) =>
      Offset(boss.handX, drawnY(boss, reduced: reduced) + NeferhooLayout.dealPoint.dy * SkyBoss.radius);

  static bool _fighting(SkyBoss boss) => boss.isNeferhoo && boss.phase == BossPhase.attacking;

  /// Where his chest is drawn (screen height fraction): the rules' place
  /// ([SkyBoss.y], which bobs .04 at every setting: the hit circle is the
  /// rules', Reduced Motion is presentation only), held at the bob's centre
  /// under [reduced] Motion. The rules' circle is within .04 of it (a third
  /// of the circle's radius), so a rock aimed at the drawn body still meets
  /// him; what flies to his chest (a returned letter, its burst) goes to the
  /// drawn chest.
  static double drawnY(SkyBoss boss, {required bool reduced}) => reduced ? restY : boss.y;

  /// The centre of his hover (`Neferhoo.hoverY`'s bob centre).
  static final restY = Neferhoo.hoverY(0);

  // ---------------------------------------------------------- the passes --

  /// The telegraphs, under everything that flies ([size] is the screen; its
  /// height is the unit).
  static void under(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (!_fighting(boss)) return;
    final reduced = m.reducedMotion;
    final clock = reduced ? 0.0 : boss.combatTime;
    // ---- the hint under his health strip (a letter sent back; the adaptive
    // line after eight rocks on his wraps), under everything that flies
    final pill = hintPill(size, boss);
    if (pill != null) NeferhooPropsArt.hintPill(c, pill.rect.center, pill.text, size.height, alpha: pill.alpha);
    // (the tags keep clear of his health strip, the hint, and the hearts plate)
    final clear = [hudStrip(size, boss), ?pill?.rect];
    // ---- the MAIL CALL lane, from the lock until the last letter is past the bird
    // (the faster fight: every call's lane still live, a wave's too)
    if (boss.fasterNeferhoo) {
      for (final lane in mailLanes(boss)) {
        NeferhooPropsArt.mailLane(c, size, lane.y, boss.handX, t: lane.reveal, fury: lane.express, alpha: lane.alpha, clock: clock, clear: clear);
      }
    } else {
      final lane = mailLane(boss);
      if (lane != null) {
        NeferhooPropsArt.mailLane(c, size, boss.laneY, boss.handX, t: lane.reveal, fury: lane.express, alpha: lane.alpha, clock: clock, clear: clear);
      }
    }
    // ---- the ANKH's loop, from the lock until the last ankh is home
    final loop = ankhLoop(boss);
    if (loop != null) {
      NeferhooPropsArt.ankhTelegraph(c, size, boss.handX, loop.laneA, yB: loop.laneB, t: loop.reveal, fury: loop.two, alpha: loop.alpha, clear: clear);
    }
  }

  /// His magic, the letters and the ankhs in flight, the returns and the
  /// bursts: right after the rig ([size] is the screen).
  static void over(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (!_fighting(boss)) return;
    final h = size.height, age = boss.age;
    final reduced = m.reducedMotion;
    final y = drawnY(boss, reduced: reduced);
    final chest = Offset(boss.x * h, y * h);
    // ---- the glyph motes (a few at rest, more while he deals or raises the
    // ankh, the full orbit in fury; none under Reduced Motion)
    if (!reduced) {
      final pose = NeferhooPose.fight(boss, m);
      final busy = NeferhooKit.smooth01((math.max(pose.glow, pose.satchelOpen) - .15) / .3);
      final strength = .3 + .3 * busy + (1 - .3 - .3 * busy) * pose.fury.clamp(0.0, 1.0);
      motes(c, chest, h, boss.combatTime, strength);
    }
    // ---- the letters in flight
    for (final letter in boss.liveLetters) {
      if (letter.returned) continue;
      final x = letter.xAt(age, boss.handX);
      if (x < -.12) continue;
      final la = age - letter.releaseAt;
      final tilt = reduced ? 0.0 : math.sin(la * 7 + letter.index) * .06;
      final flutter = reduced ? .5 : (math.sin(la * 18 + letter.index) + 1) / 2;
      NeferhooPropsArt.letter(c, Offset(x * h, letter.yAt(age) * h), h, tilt: tilt, fury: letter.express, flutter: math.max(.001, flutter), rock: rockAt(x));
    }
    // ---- the ankhs in flight (a ribbon trail along the path they flew)
    for (final ankh in boss.liveAnkhs) {
      final p = ankhCentre(ankh, boss, reduced: reduced);
      if (p == null) continue;
      final since = age - ankh.thrownAt;
      final trail = <Offset>[
        for (var i = 20; i >= 1; i--)
          if (since - i * _trailStep(ankh, boss) > 0) ankhCentre(ankh, boss, age: age - i * _trailStep(ankh, boss), reduced: reduced)!,
      ];
      final spin = reduced ? 0.0 : since * 14;
      NeferhooPropsArt.flyingAnkh(c, p, h, spin, trail: reduced ? const [] : trail, second: ankh.second);
    }
    // ---- the returned letters, homing in on his chest
    for (final letter in boss.liveLetters) {
      if (!letter.returned) continue;
      NeferhooPropsArt.returnedLetter(c, Offset(letter.struckX, letter.struckY), Offset(boss.x, y), h, returnProgress(letter, boss));
    }
    // ---- the landings: a burst on his chest for each of the latest two
    var bursts = 0;
    for (final letter in boss.neferhoo.letters.reversed) {
      final landed = letter.landedAt;
      if (landed == null) continue;
      final t = (age - landed) / burstSeconds;
      if (t < 0 || t >= 1) continue;
      NeferhooPropsArt.returnBurst(c, Offset(boss.x - .02, y - .02), h, t, damage: Neferhoo.returnDamageOf(faster: boss.fasterNeferhoo), reduced: reduced);
      if (++bursts == 2) break;
    }
    // ---- a rock on his wraps: a small cloth puff
    final scuff = (age - boss.lastScuffAt) / puffSeconds;
    if (scuff >= 0 && scuff < 1) _puff(c, chest, h, scuff, reduced);
  }

  /// The hint the play screen shows under his health strip now, where, and
  /// how strongly; null when none. It is the rules' own line
  /// ([NeferhooBoss.neferhooHint], the screen reader's too) when it is one a
  /// player must see: RETURN TO SENDER! for [Neferhoo.returnHintSeconds]
  /// after a letter is sent back (in .15 s, out over the last .3 s), and the
  /// adaptive line ([Neferhoo.neferhooScuffHint]) once
  /// [Neferhoo.scuffsBeforeHint] rocks have scuffed his wraps without a
  /// return (in over .25 s; it gives way to the ankh's telegraph and comes
  /// back once the ankh is home, as the rules' line does, and goes with the
  /// next return). It yields to the shared STRONGER! card, which hangs from
  /// the same strip. Hung like the shipped guardians' tags (the Gargoyle's
  /// LAMP OPEN, King Coo's PUFFED): centred under the strip, so clear of the
  /// hearts plate, the pause key and the Shoot and Sprint keys at every
  /// width and inset; drawn under the letters, the ankhs and the bird, so it
  /// never hides a hazard.
  static ({String text, double alpha, Rect rect})? hintPill(Size size, SkyBoss boss) {
    if (!_fighting(boss) || !boss.age.isFinite) return null;
    final f = boss.neferhoo, age = boss.age;
    final now = boss.neferhooHint;
    String? text;
    var alpha = 0.0;
    if (now == Neferhoo.returnHint || now == Neferhoo.fasterReturnHint) {
      final t = age - f.lastReturnAt;
      text = now;
      alpha = NeferhooKit.ramp(t, 0, .15) * (1 - NeferhooKit.ramp(t, Neferhoo.returnHintSeconds - .3, Neferhoo.returnHintSeconds));
    } else if (f.scuffsSinceReturn >= Neferhoo.scuffsBeforeHint) {
      text = Neferhoo.neferhooScuffHint;
      if (now == Neferhoo.neferhooScuffHint) {
        // in from the eighth scuff, or from the moment the ankh came home
        var from = f.scuffsSinceReturn == Neferhoo.scuffsBeforeHint ? f.lastScuffAt : double.negativeInfinity;
        for (final a in f.ankhs) {
          final home = a.caughtAt;
          if (home != null && home <= age && home > from) from = home;
        }
        alpha = from.isFinite ? NeferhooKit.ramp(age - from, 0, .25) : 1;
      } else {
        // the ankh's telegraph takes over: out over .25 s from its lock
        alpha = 1 - NeferhooKit.ramp(age - f.ankhLockedAt, 0, .25);
      }
    }
    if (text == null || !(alpha > 0)) return null;
    // the STRONGER! card has the place while it hangs
    final card = BossStageHudArt.strongerAge(boss);
    if (card.isFinite) alpha *= NeferhooKit.ramp(card, BossStageHudArt.tagSeconds, BossStageHudArt.tagSeconds + .25);
    if (!(alpha > 0)) return null;
    final strip = BossHealthBarArt.bounds(size, boss);
    final s = NeferhooPropsArt.hintPillSize(text, size.height);
    final u = size.height / 360;
    var rect = Rect.fromCenter(center: Offset(strip.center.dx, strip.bottom + 6 * u + s.height / 2), width: s.width, height: s.height);
    // (kept between the hearts plate and the pause key, whatever the width)
    final from = neferhooHudPlate(size).right + 6 * u, to = neferhooHudPause(size).left - 6 * u;
    if (rect.right > to) rect = rect.shift(Offset(to - rect.right, 0));
    if (rect.left < from) rect = rect.shift(Offset(from - rect.left, 0));
    return (text: text, alpha: alpha.clamp(0.0, 1.0), rect: rect);
  }

  /// How strongly the play screen's hearts plate (`MatchHealth`) is drawn
  /// now on a screen of [size] (1 normally). While the ankh's loop passes
  /// under the plate (a high lane: the turn and the start of the return
  /// pass are behind the bird, at the screen's top left) the plate fades to
  /// [plateFaded] from the lock (over .25 s) until the last ankh of that lock
  /// is home (back over .3 s), so the loop and the ankh show through it all
  /// the way and the return pass never pops out from under the HUD just
  /// before it reaches the bird. [insets] are the screen's safe-area insets
  /// (the plate moves with them). A pure function of the fight: a replay
  /// fades the same.
  static double hudPlateAlpha(Size size, SkyBoss boss, {EdgeInsets? insets}) {
    if (!_fighting(boss) || !boss.age.isFinite) return 1;
    final f = boss.neferhoo, lock = f.ankhLockedAt, age = boss.age;
    if (!lock.isFinite || age < lock) return 1;
    final group = [for (final a in f.ankhs) if ((a.lockedAt - lock).abs() < 1e-9) a];
    if (group.isEmpty) return 1;
    final turn = Neferhoo.turnX(FlightSimulation.birdX);
    var end = double.negativeInfinity;
    for (final a in group) {
      end = math.max(end, a.caughtAt ?? a.homeAt(handX: boss.handX, turnX: turn));
    }
    final low = NeferhooKit.ramp(age - lock, 0, .25) * (1 - NeferhooKit.ramp(age - end, 0, .3));
    if (low <= 0 || !loopUnderPlate(size, boss, group, insets: insets)) return 1;
    return 1 - (1 - plateFaded) * low;
  }

  /// The hearts plate's strength while an ankh's loop passes under it.
  static const plateFaded = .25;

  /// Whether any of [ankhs] (on its whole loop, with its radius) passes under
  /// the hearts plate on a screen of [size].
  static bool loopUnderPlate(Size size, SkyBoss boss, List<NeferhooAnkh> ankhs, {EdgeInsets? insets}) {
    final h = size.height;
    final plate = neferhooHudPlate(size, insets);
    final turn = Neferhoo.turnX(FlightSimulation.birdX);
    for (final a in ankhs) {
      final length = a.length(boss.handX, turn);
      for (var k = 0; k <= 80; k++) {
        final at = a.at(a.thrownAt + length * k / 80 / a.speed - 1e-9, handX: boss.handX, turnX: turn);
        if (at == null) continue;
        final r = Rect.fromCircle(center: Offset(at.$1 * h, at.$2 * h), radius: Neferhoo.ankhRadius * h);
        if (r.overlaps(plate)) return true;
      }
    }
    return false;
  }

  /// His health strip on a screen of [size] (with the STRONGER! card's
  /// drop under it), which the hint tags keep clear of.
  static Rect hudStrip(Size size, SkyBoss boss) {
    final strip = BossHealthBarArt.bounds(size, boss);
    return Rect.fromLTRB(strip.left, strip.top, strip.right, strip.bottom + size.height * .03);
  }

  /// A burst's life, and a scuff puff's.
  static const burstSeconds = .6, puffSeconds = .32;


  // ------------------------------------------------- what the passes read --

  /// The mail lane now: its reveal (0..1 over the first .5 s), its alpha
  /// (it fades out over its last .25 s) and whether it is the express post;
  /// null when no mail call is on screen. It runs from the rules' lock
  /// ([NeferhooFight.mailLockedAt]) until the call's last letter is .15
  /// screen heights past the bird (the design's `mailEnd`), at the speed the
  /// rules dealt them ([NeferhooLetter.speed]: rules 52's are faster). In the
  /// tougher fight (rules 52) the call's mummy bats follow its letters down
  /// the lane, and it stays until the last of them is .15 past the bird too,
  /// or gone ([NeferhooBat]).
  static ({double reveal, double alpha, bool express})? mailLane(SkyBoss boss) {
    final fight = boss.neferhoo;
    final lock = fight.mailLockedAt;
    final since = boss.age - lock;
    if (!since.isFinite || since < 0) return null;
    final express = fight.express;
    final gap = express ? Neferhoo.furyStreamGap : Neferhoo.streamGap;
    var speed = express ? Neferhoo.furyLetterSpeed : Neferhoo.letterSpeed;
    for (final letter in fight.letters.reversed) {
      if (letter.releaseAt >= lock) speed = letter.speed;
      break;
    }
    final last = Neferhoo.mailReleaseAt - Neferhoo.mailLockAt + (Neferhoo.streamCount(fury: express) - 1) * gap;
    var end = last + (boss.handX - FlightSimulation.birdX + .15) / speed;
    for (final bat in fight.bats.reversed) {
      if (bat.launchAt < lock) break;
      if (bat.goneAt != null) continue;
      // Yet to fly in at the right edge (about .75 right of his hand), or on
      // its way (from where it is now), at its pace: re-judged every frame,
      // so the fade follows the bat itself.
      final enemy = bat.enemy;
      final from = enemy == null ? bat.launchAt - lock : since;
      final x = enemy?.x ?? boss.handX + .75;
      end = math.max(end, from + (x - FlightSimulation.birdX + .15) / bat.pace);
    }
    if (since >= end) return null;
    return (
      reveal: NeferhooKit.ramp(since, 0, .5),
      alpha: 1 - NeferhooKit.smooth01((since - (end - .25)) / .25),
      express: express,
    );
  }

  /// The faster fight's lanes now (rules 55, [NeferhooFight.calls]): every
  /// call's lane from its lock until its last letter is .15 past the bird
  /// and its mummy bats too (or gone), as [mailLane] judges the classic
  /// call's; a warm-up wave's lane until its bats have passed. Two can be on
  /// screen at once (a call's last letters as the next one locks), oldest
  /// first.
  static List<({double y, double reveal, double alpha, bool express})> mailLanes(SkyBoss boss) {
    final fight = boss.neferhoo;
    final age = boss.age;
    final lanes = <({double y, double reveal, double alpha, bool express})>[];
    for (final call in fight.calls.reversed) {
      final since = age - call.lockedAt;
      // (no call older than two cycles is still on screen)
      if (since > 2 * boss.neferhooBeats.period) break;
      if (!since.isFinite || since < 0) continue;
      var end = double.negativeInfinity;
      if (call.letters > 0) {
        final gap = call.express ? Neferhoo.furyStreamGap : Neferhoo.streamGap;
        final speed = Neferhoo.letterSpeedOf(fury: call.express, tougher: true);
        final last = Neferhoo.windupSeconds + (call.letters - 1) * gap;
        end = last + (boss.handX - FlightSimulation.birdX + .15) / speed;
      }
      for (final bat in fight.bats.reversed) {
        if (bat.launchAt < call.lockedAt) break;
        if (bat.call != call.number || bat.goneAt != null) continue;
        final enemy = bat.enemy;
        final from = enemy == null ? bat.launchAt - call.lockedAt : since;
        final x = enemy?.x ?? boss.handX + .75;
        end = math.max(end, from + (x - FlightSimulation.birdX + .15) / bat.pace);
      }
      if (since >= end) continue;
      lanes.add((
        y: call.lane,
        reveal: NeferhooKit.ramp(since, 0, .5),
        alpha: 1 - NeferhooKit.smooth01((since - (end - .25)) / .25),
        express: call.express,
      ));
    }
    return lanes.reversed.toList();
  }

  /// The ankh's loop now: the latest lock's lanes (the first ankh's), its
  /// reveal (0..1 over .6 s), alpha (1 until the throw, then .65, fading out
  /// over the last .25 s before the last ankh is home) and whether two fly;
  /// null when no loop is on screen.
  static ({double laneA, double laneB, double reveal, double alpha, bool two})? ankhLoop(SkyBoss boss) {
    final fight = boss.neferhoo;
    final lock = fight.ankhLockedAt;
    if (!lock.isFinite || boss.age < lock) return null;
    final group = [for (final a in fight.ankhs) if ((a.lockedAt - lock).abs() < 1e-9) a];
    if (group.isEmpty) return null;
    final turn = Neferhoo.turnX(FlightSimulation.birdX);
    var end = double.negativeInfinity;
    for (final a in group) {
      end = math.max(end, a.caughtAt ?? a.thrownAt + a.length(boss.handX, turn) / a.speed);
    }
    if (boss.age >= end) return null;
    final first = group.firstWhere((a) => !a.second, orElse: () => group.first);
    final thrown = group.map((a) => a.thrownAt).reduce(math.min);
    final after = NeferhooKit.smooth01((boss.age - thrown) / .2);
    return (
      laneA: first.laneA,
      laneB: first.laneB,
      reveal: NeferhooKit.ramp(boss.age - lock, 0, .6),
      alpha: (1 - .35 * after) * (1 - NeferhooKit.smooth01((boss.age - (end - .25)) / .25)),
      two: group.length > 1 || fight.twoAnkhs,
    );
  }

  /// How far (0..1) a returned [letter] is on its way home: the rules' own
  /// clock ([NeferhooLetter.homeward], from the catch to the landing time the
  /// rules latched at the catch, [NeferhooLetter.homeAt]: a letter sent back
  /// together with others may land up to [Neferhoo.landingGap] later per
  /// earlier one). The painter flies it on the rules' curve
  /// ([NeferhooLetter.returnAt]: from where it was struck to his chest now,
  /// control [Neferhoo.returnControl]); [returnedAt] is that point.
  static double returnProgress(NeferhooLetter letter, SkyBoss boss) => letter.homeward(boss.age);

  /// Where the rules have a returned [letter] now (screen fractions): the
  /// point the painter draws it at.
  static Offset returnedAt(NeferhooLetter letter, SkyBoss boss) {
    final (x, y) = letter.returnAt(boss.age, chestX: boss.x, chestY: boss.y);
    return Offset(x, y);
  }

  static double _trailStep(NeferhooAnkh ankh, SkyBoss boss) =>
      ankh.length(boss.handX, Neferhoo.turnX(FlightSimulation.birdX)) / ankh.speed / 200;

  /// The glyph motes at [strength] (0..1), the last one fading in, so more
  /// motes never pop in.
  static void motes(Canvas c, Offset chest, double h, double age, double strength) {
    final s = strength.clamp(0.0, 1.0);
    final whole = (7 * s).floor() / 7;
    NeferhooFx.glyphMotes(c, chest, h, age, strength: whole, fade: 7 * s - (7 * s).floor());
  }

  // a scuff: a small puff of loose linen and a few fibres knocked off the wraps where the rocks
  // arrive (the hit circle's left edge), shaded under a lit cap with a soft keyline so it reads on
  // his pale linen as well as on the sky; the fibres fly back toward the bird
  static void _puff(Canvas c, Offset chest, double h, double t, bool reduced) {
    final at = chest + Offset(-h * SkyBoss.radius * 1.02, h * .008);
    final a = 1 - NeferhooKit.smooth01((t - .35) / .65);
    final grow = reduced ? .7 : .45 + .55 * NeferhooKit.smooth01(t * 1.8);
    final r = h * .017 * grow;
    final puff = Path();
    for (var i = 0; i < 3; i++) {
      final ang = math.pi * (.82 + i * .2);
      puff.addOval(Rect.fromCircle(center: at + Offset(math.cos(ang), math.sin(ang)) * h * .016 * grow, radius: r * (1 - i * .15)));
    }
    c.drawPath(
      puff,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .004
        ..color = NeferhooPalette.inkSoft.withValues(alpha: .45 * a),
    );
    c.drawPath(puff, Paint()..color = NeferhooPalette.linenShade.withValues(alpha: .95 * a));
    c.drawPath(puff.shift(Offset(h * .003, -h * .004)), Paint()..color = NeferhooPalette.linenHi.withValues(alpha: .9 * a));
    final threads = Path();
    for (var i = 0; i < 4; i++) {
      final ang = math.pi * (.78 + i * .15);
      final d = Offset(math.cos(ang), math.sin(ang));
      final from = h * (.022 + .01 * grow), to = h * (.03 + .035 * grow);
      threads
        ..moveTo(at.dx + d.dx * from, at.dy + d.dy * from)
        ..quadraticBezierTo(at.dx + d.dx * (from + to) / 2 + h * .004, at.dy + d.dy * (from + to) / 2 - h * .004, at.dx + d.dx * to, at.dy + d.dy * to);
    }
    c.drawPath(
      threads,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0035
        ..strokeCap = StrokeCap.round
        ..color = NeferhooPalette.linenDeep.withValues(alpha: .85 * a),
    );
  }

  /// Records every cached piece of the fight art (letters at both sizes,
  /// calm and express, returned; the ankh; the lane and the loop with their
  /// tags; a burst) into [c], so no fight frame records one.
  static void prewarm(Canvas c) {
    const size = Size(800, 360);
    for (final h in [360.0, 432.0]) {
      for (final fury in [false, true]) {
        NeferhooPropsArt.letter(c, const Offset(300, 180), h, fury: fury, flutter: .5);
        NeferhooPropsArt.letter(c, const Offset(300, 180), h, fury: fury);
      }
      NeferhooPropsArt.letter(c, const Offset(300, 180), h, returned: 1);
      NeferhooPropsArt.flyingAnkh(c, const Offset(1, .3), h, 1, trail: const [Offset(1.05, .3), Offset(1.1, .3)]);
      // (fury's second, turquoise-inlaid ankh has its own picture)
      NeferhooPropsArt.flyingAnkh(c, const Offset(1, .3), h, 1, trail: const [Offset(1.05, .3), Offset(1.1, .3)], second: true);
      NeferhooPropsArt.returnBurst(c, const Offset(1.2, .5), h, .3);
    }
    for (final fury in [false, true]) {
      NeferhooPropsArt.mailLane(c, size, .5, 1.6, fury: fury, clock: 1);
      NeferhooPropsArt.ankhTelegraph(c, size, 1.6, .3, fury: fury);
    }
    NeferhooFx.glyphMotes(c, const Offset(600, 190), 360, 1);
  }
}
