import 'dart:math' as math;

import 'sky_boss.dart';
import 'sky_enemy.dart';

/// Neferhoo, the Mummy Courier: Egypt's guardian, who ends level 2-6 "Return
/// to Sender" (rules version 50, campaign only). A hoopoe courier sealed in
/// the Great Pyramid with the one lost letter; he deals letters down a lane
/// locked on the bird, and a rock that meets one sends it home into him
/// (return to sender). From the full fight on, a golden ankh flies out and
/// back on two marked lanes. Spec: `egypt-ws/reports/01-egypt-guardian.md`
/// §3; staged (rules 44's three stages) by `egypt-int/MASTER-PLAN.md` §2.
///
/// The fight, by stage ([SkyBoss.stage]):
///
///  * warm-up (above two thirds): the MAIL CALL only, three letters at
///    [letterSpeed]; nothing else, so the return rule is learned first;
///  * full (from two thirds): the mail call and THE ANKH, his signature
///    ([SkyBoss.signatureArmed] on the [period] clock, onset [ankhLockAt]);
///  * fury (at a third): the EXPRESS POST (five letters at
///    [furyLetterSpeed]) and TWO ANKHS on mirrored loops.
///
/// From rules version 52 his fight is tougher ([SkyBoss.tougherNeferhoo]):
/// [tougherHp] health, letters [tougherPace] times faster there and back,
/// and from the full fight on his mummy bats ([EnemyKind.mummyBat]) fly in
/// from the pyramid's side behind each mail call's letters, down its lane:
/// a pair, fury's trio a bit faster ([batsFor], [NeferhooBat]). A rules 50 fight is exactly as it was.
///
/// From rules version 55 his fight is faster too ([SkyBoss.fasterNeferhoo]):
/// [fasterHp] health and a tighter clock ([NeferhooBeats.faster]): a 10.5 s
/// cycle, a second mail call from the full fight on, his bats from the
/// warm-up on (a pair, a trio, fury's four) and, in the warm-up's open sky, a
/// wave of two more; a returned letter deals [fasterReturnDamage]. A rules 52
/// to 54 fight is exactly as it was ([NeferhooBeats.classic]).
///
/// Everything here is a pure function of its arguments: the rules
/// (`neferhoo_rules.dart`) latch the lanes and the letters' fates on
/// [NeferhooFight], and the art draws exactly what these functions say. The
/// rules' hurt and catch tests are [letterTouches], [ankhTouches] and
/// [catches]; the fairness proof and the pilots use the same functions.
abstract final class Neferhoo {
  static const name = 'Neferhoo';
  static const title = 'KEEPER OF THE LOST LETTER';

  /// Health outside the staged campaign ([SkyBoss.healthFor]): the design's
  /// one-stage fight. No flight meets him unstaged (only a rules 50 level
  /// plan names him, and every campaign boss is staged from 44); tests that
  /// build a [SkyBoss] by hand use it.
  static const maxHp = 150;

  /// Health in the staged campaign ([SkyBoss.campaignHealthFor]), pinned
  /// by the pilots on the real rules (`test/neferhoo_pilot_test.dart`;
  /// tables in `egypt-int/deliveries/r1/HANDOFF.md`): the design's family
  /// bot wins in about a minute at 640 px (59 s; 41 at 800, 39 at 864), a
  /// first-timer in about two (119 s), a practised player in 27 s, like the
  /// staged Searchlight Gargoyle's pilots (63 s average, 26.5 sharp). The
  /// master plan's estimate was 270 (51 s family on the real rules). Each 30
  /// HP moves the family about 5 s.
  static const campaignHp = 300;

  // ----------------------------------------------- tougher (rules 52) --

  /// Health in the tougher staged fight (rules version 52,
  /// [SkyBoss.tougherNeferhoo]): the owner's "double the health" after
  /// playtesting 2-6 at [campaignHp]. Not a tuning knob: the bats and the
  /// letters' pace are tuned around it.
  static const tougherHp = 600;

  /// How much faster his letters fly in the tougher fight: out of his hand
  /// ([letterSpeedOf]) and home again ([returnSecondsOf]). 1.4 gives the
  /// owner's "the letter particles move faster" (.45 → .63, the express
  /// post's .52 → .73) and keeps every lane fair at 640 to 864 px wide
  /// (`test/neferhoo_tougher_fairness_test.dart`).
  static const tougherPace = 1.4;

  /// A letter's speed: [letterSpeed], the express post's [furyLetterSpeed],
  /// [tougherPace] times either in the tougher fight.
  static double letterSpeedOf({required bool fury, bool tougher = false}) {
    final speed = fury ? furyLetterSpeed : letterSpeed;
    return tougher ? speed * tougherPace : speed;
  }

  /// How long a returned letter takes home from [distance] away
  /// ([returnSeconds]; [tougherPace] times faster in the tougher fight).
  static double returnSecondsOf(double distance, {bool tougher = false}) =>
      tougher
      ? returnSeconds(distance) / tougherPace
      : returnSeconds(distance);

  /// The mummy bats a mail call sends in the tougher fight, by his stage at
  /// its lock: none in the warm-up (the return rule is learned on a calm
  /// sky), a pair in the full fight, a trio in fury. In the [faster] fight
  /// (rules 55) the first call of each cycle sends a pair from the warm-up
  /// on, a trio in the full fight and four in fury (its second call sends
  /// none: [NeferhooBeats.secondMailAt]).
  static int batsFor(int stage, {bool faster = false}) => faster
      ? switch (stage) {
          0 => 2,
          1 => 3,
          _ => 4,
        }
      : switch (stage) {
          0 => 0,
          1 => 2,
          _ => 3,
        };

  // ------------------------------------------------ faster (rules 55) --

  /// Health in the faster fight (rules version 55,
  /// [SkyBoss.fasterNeferhoo]): the owner's "100 more HP" over
  /// [tougherHp] (rules 53's boss growth is endless only and left 2-6 at
  /// 600).
  static const fasterHp = 700;

  /// The warm-up's extra wave in the faster fight
  /// ([NeferhooBeats.waveAt]): [waveBats] mummy bats down a lane locked on
  /// the bird, in from the right edge like a call's, the first [waveDelay]
  /// after the lock, the next [waveGap] behind (staggered), at [batPace].
  static const waveBats = 2;
  static const waveDelay = .3, waveGap = .5;

  /// When (seconds after the wave's lock) its bat [index] flies in.
  static double waveLaunch(int index) => waveDelay + index * waveGap;

  /// The bats fly in from the pyramid's side, the right edge of the sky
  /// ([batEntry] past it), down the call's lane, behind its letters: the
  /// first flies in so that it trails the call's last letter by [batTrail]
  /// as that letter leaves his hand, the others [batGap] behind it (fury's
  /// [furyBatGap]). Slower than the letters ([batPace], [furyBatPace]), they
  /// never fly among them: the call's lane stays one hazard, its letters
  /// then its bats, and the bats are past the bird's column before an ankh
  /// can reach it (`test/neferhoo_tougher_fairness_test.dart`).
  static const batEntry = .10, batTrail = .15;
  static const batGap = streamGap, furyBatGap = furyStreamGap;

  /// How fast they close in (screen heights a second): the pair at
  /// [batPace], fury's trio a bit faster at [furyBatPace], both a little
  /// slower than the letters they follow (.63, .73). As small enemies they
  /// close in at a share of the flight's scroll speed ([SkyEnemy.drift]);
  /// the rules set each bat's share as it flies in, so it keeps its pace at
  /// every screen width and however long the fight (the scroll speeds up
  /// with the route clock: about .43 as he arrives, .5 after three minutes).
  /// A sprint speeds them up like everything else on the course, and rams
  /// them.
  static const batPace = .60, furyBatPace = .68;

  /// A mummy bat's health: one rock of any weapon downs it (a simple bat of
  /// 2-6's lineup takes 15).
  static const batHp = 10;

  /// When (seconds after the call's lock) bat [index] of a call flies in on
  /// a sky [width] screen heights wide: about .8 s (fury 1.4) after the
  /// lock on a 16:9 screen or wider, a little later on a narrower one.
  static double batLaunch(
    int index, {
    required bool fury,
    required double width,
  }) {
    final hand = anchorX(birdColumn, width) - handOffset;
    final lastLetter =
        windupSeconds + (streamCount(fury: fury) - 1) * gap(fury: fury);
    final pace = fury ? furyBatPace : batPace;
    final first = lastLetter - (batStartX(width) - hand - batTrail) / pace;
    return math.max(0, first) + index * (fury ? furyBatGap : batGap);
  }

  /// Where (screen x) a bat flies in on a sky [width] screen heights wide.
  static double batStartX(double width) => width + batEntry;

  // ------------------------------------------------------------- clock --

  /// One cycle of his fight, in combat seconds ([SkyBoss.combatTime]). Fury
  /// never retimes it.
  static const period = 12.0;

  /// The mail call: its lane locks on the bird at [mailLockAt]; the letters
  /// leave his hand from [mailReleaseAt], [streamGap] apart
  /// ([furyStreamGap] in the express post).
  static const mailLockAt = .6, mailReleaseAt = 1.6;
  static const streamGap = .40, furyStreamGap = .32;

  /// The ankh: both lanes lock at [ankhLockAt] (the whole loop is drawn from
  /// then: the signature's onset), it is thrown at [ankhThrowAt]; fury's
  /// second ankh follows [furyAnkhDelay] later.
  static const ankhLockAt = 5.4, ankhThrowAt = 6.8, furyAnkhDelay = .5;

  /// Letters in one mail call.
  static int streamCount({required bool fury}) => fury ? 5 : 3;

  /// Seconds between two letters of one mail call.
  static double gap({required bool fury}) => fury ? furyStreamGap : streamGap;

  /// The art's beats, as the fight timeline (`iter5/test/egypt/
  /// mummy_timeline.dart`) plays them: the wind-up from the lock to the
  /// first letter; the letters rise into his fan [fanDelay] after the lock;
  /// the flick goes on [flickTail] after the last letter leaves; the ankh
  /// spins up for the last [spinUpSeconds] before the throw; the catch is
  /// acted for [catchSeconds] once the (last) ankh is home.
  static const windupSeconds = mailReleaseAt - mailLockAt;
  static const fanDelay = .3, flickTail = .35;
  static const spinUpSeconds = .6, catchSeconds = .9;

  /// The time within the cycle, and the cycle's number from 0, at combat
  /// time [combat] (0 or more).
  static double cycleTime(double combat) => combat % period;
  static int cycleNumber(double combat) => (combat / period).floor();

  /// How many times the cycle moment [at] has come by combat time
  /// [combat]: the rules latch an event when this rises.
  static int count(double combat, double at) =>
      combat < at ? 0 : ((combat - at) / period).floor() + 1;

  // ---------------------------------------------------------- geometry --

  /// Where he hovers (screen heights): this far right of the bird, or as far
  /// right as the screen allows (442 px at 640, 602 at 800).
  static double anchorX(double birdX, double width) =>
      math.max(birdX + .70, width - .55);

  /// His height in the fight at combat time [combat]. The rules' hit circle
  /// bobs with it at every setting (Reduced Motion is presentation only).
  static double hoverY(double combat) => .52 + .04 * math.sin(.85 * combat);

  /// Letters leave, and the ankh comes home to, his hand: this far left of
  /// his chest (the hit circle's centre).
  static const handOffset = .10;

  /// The bird's screen column (`FlightSimulation.birdX`): where the hints
  /// judge a stream to have passed, and the ankh's turn is measured from.
  static const birdColumn = .47;

  /// A letter's half size: an envelope .090 × .064 of the screen's height.
  static const letterHalfWidth = .045, letterHalfHeight = .032;
  static const letterSpeed = .45, furyLetterSpeed = .52;

  /// A mail lane locks on the bird's height, kept this far from the edges.
  static const laneTop = .16, laneBottom = .84;
  static double laneFor(double birdY) => birdY.clamp(laneTop, laneBottom);

  /// The addressee rule: a rock catches a letter within the letter's half
  /// height plus this (the bird's radius) of its lane, the band in which the
  /// letter would hit the bird. Every letter that can hit you can be sent
  /// back by a shot fired from where you are.
  static const catchReach = .038;

  /// A rock leaves the beak, up to [beakAbove] above and [beakBelow] below
  /// the bird's centre (`BirdFlightMotion.mouth` over every tilt and flap
  /// stretch: −.0078 to +.0276). The catch band is judged on the rock's
  /// height, so it reaches that much further each way: a shot fired from
  /// any bird whose centre is in the hurt band catches the letter.
  static const beakAbove = .008, beakBelow = .028;

  /// Whether a rock at height [rockY] is in the catch band of a letter
  /// flying the lane [lane] (vertically; [catchesAcross] is the other half).
  static bool catches(double rockY, double lane) {
    final dy = rockY - lane;
    const band = letterHalfHeight + catchReach;
    return dy >= -(band + beakAbove) && dy <= band + beakBelow;
  }

  /// Whether a rock of radius [rockR] that moved from [fromX] to [toX] this
  /// step met a letter that moved from [letterFrom] to [letterTo]: swept,
  /// the rock's span against the letter's (a rock crosses a letter's width
  /// in a few hundredths of a second).
  static bool catchesAcross(
    double fromX,
    double toX,
    double rockR,
    double letterFrom,
    double letterTo,
  ) =>
      toX + rockR >= math.min(letterFrom, letterTo) - letterHalfWidth &&
      fromX - rockR <= math.max(letterFrom, letterTo) + letterHalfWidth;

  /// Whether a bird of radius [r] at ([x], [y]) touches a letter whose
  /// centre is at ([letterX], [lane]): the circle meets the envelope's
  /// rectangle. The rules' hurt test, and the fairness proof's.
  static bool letterTouches(
    double letterX,
    double lane,
    double x,
    double y,
    double r,
  ) {
    final dx = math.max(0.0, (letterX - x).abs() - letterHalfWidth);
    final dy = math.max(0.0, (y - lane).abs() - letterHalfHeight);
    return dx * dx + dy * dy < r * r;
  }

  /// The ankh: its radius, the split between its two lanes, how far behind
  /// the bird's column it turns, and its speed.
  static const ankhRadius = .045, ankhSplit = .32, ankhBehind = .22;
  static const ankhSpeed = .85, furyAnkhSpeed = .95;

  /// Whether a bird of radius [r] at ([x], [y]) touches an ankh centred at
  /// [at]. Rocks pass it by: nothing but a bird meets it.
  static bool ankhTouches((double, double) at, double x, double y, double r) {
    final dx = at.$1 - x, dy = at.$2 - y;
    final reach = ankhRadius + r;
    return dx * dx + dy * dy < reach * reach;
  }

  /// The ankh's first lane locks on the bird's height, kept in this band.
  static const ankhTop = .25, ankhBottom = .75;
  static double ankhLaneFor(double birdY) => birdY.clamp(ankhTop, ankhBottom);

  /// Its second lane, [ankhSplit] from the first, always toward the middle.
  static double backLane(double yA) =>
      yA <= .5 ? yA + ankhSplit : yA - ankhSplit;

  /// Screen x where the ankh turns back, from the bird's column.
  static double turnX(double birdX) => birdX - ankhBehind;

  // ------------------------------------------------------------ damage --

  /// What a returned letter deals as it lands (the wraps do not soften it).
  static const returnDamage = 25;

  /// What it deals in the faster fight (rules 55): his second call sends
  /// twice the letters a cycle, so each is worth less, and a practised
  /// player's fight grows longer with his [fasterHp] instead of shorter
  /// (the pilots: `test/neferhoo_faster_pilot_test.dart`).
  static const fasterReturnDamage = 18;

  /// What a returned letter deals in a fight [faster] or not.
  static int returnDamageOf({bool faster = false}) =>
      faster ? fasterReturnDamage : returnDamage;

  /// A rock (or a blast) on his padded wraps deals a third of its damage,
  /// at least 1: a tapped rock 3, a full charge 13.
  static const wrapsDivisor = 3;
  static int wrapsDamage(int damage) => math.max(1, damage ~/ wrapsDivisor);

  /// A returned letter flies home on a quadratic curve whose control point
  /// is this far from where it was struck, for [returnSeconds] of its
  /// distance to his chest.
  static const returnControl = (.25, -.14);
  static double returnSeconds(double distance) =>
      (distance / 1.4).clamp(.35, .8);

  /// Letters sent back together land at least this far apart (a later one
  /// waits), so every landing is its own step, thud and cue.
  static const landingGap = .1;

  /// A rock charged at least this much (the shatter threshold of 2-2) is not
  /// spent on a letter: it returns every letter it meets (the "bulk return",
  /// the owner's call; see the master plan).
  static const bulkCharge = .35;
  static bool bulkReturns(double charge) => charge >= bulkCharge - 1e-9;

  /// After this many rocks on his wraps without a returned letter, the hint
  /// says so ([neferhooScuffHint]).
  static const scuffsBeforeHint = 8;

  // ------------------------------------------------------------- hints --

  /// How long [returnHint] shows after a letter is sent back.
  static const returnHintSeconds = 1.5;

  static const mailHint = 'MAIL CALL · Shoot them back!';
  static const returnHint = 'RETURN TO SENDER! · −25';
  static const fasterReturnHint = 'RETURN TO SENDER! · −18';
  static const ankhHint = 'THE ANKH · It comes back!';
  static const expressHint = 'EXPRESS POST · Five letters, faster';
  static const twoAnkhsHint = 'TWO ANKHS · Keep off both lanes';

  /// The tougher fight: the mail call's bats still coming down the lane
  /// after its letters, and the card as he grows stronger
  /// ([SkyBoss.stageHint]).
  static const batsHint = 'MUMMY BATS · Shoot them down!';
  static const tougherStageHint = 'STRONGER · The ankh, and his mummy bats!';
  static const neferhooScuffHint =
      'Rocks only scuff his wraps. Shoot his LETTERS back!';

  /// The open sky's line in the warm-up (no ankh yet), the full fight and
  /// fury.
  static const warmUpHint = 'Shoot his letters back · Return to sender';
  static const calmHint = 'Shoot his letters back · Dodge the golden ankh';
  static const furyHint = 'FURY · Express post and two ankhs';
}

/// His fight's clock: the cycle and the moments in it (cycle seconds, from
/// the cycle's start), and how many letters a mail call deals.
/// [classic] is rules 50 to 54's 12 s cycle; [faster] is rules 55's
/// ([SkyBoss.fasterNeferhoo]). The rules latch, and the art, the hints and
/// the audio read, every beat off the boss's own beats
/// ([NeferhooBoss.neferhooBeats]).
class NeferhooBeats {
  const NeferhooBeats._({
    required this.period,
    required this.ankhLockAt,
    required this.ankhThrowAt,
    this.secondMailAt,
    this.waveAt,
  });

  /// Rules 50 to 54: one mail call at [Neferhoo.mailLockAt] and, from the
  /// full fight on, the ankh at [Neferhoo.ankhLockAt], every 12 s.
  static const classic = NeferhooBeats._(
    period: Neferhoo.period,
    ankhLockAt: Neferhoo.ankhLockAt,
    ankhThrowAt: Neferhoo.ankhThrowAt,
  );

  /// Rules 55: a 10.5 s cycle. The first call locks at .6 (letters from
  /// 1.6, its bats behind them: a pair from the warm-up on, a trio, fury's
  /// four); from the full fight on the ankh locks at 5.4 as before (thrown at
  /// 6.8, once the call's bats are past the bird), and once its return pass
  /// is over a second call locks at 9.6: its letters (no bats) reach the bird
  /// early in the next cycle, a call ahead of that cycle's first. In a
  /// warm-up cycle a wave of two bats locks at 5.9 instead, once the call's
  /// bats are past. The open sky between the ankh's return pass and the next
  /// letters drops from about 6 s to 1; the warm-up's from 11 s to about 4
  /// (`test/neferhoo_faster_rules_test.dart`, fairness:
  /// `test/neferhoo_faster_fairness_test.dart`).
  static const faster = NeferhooBeats._(
    period: 10.5,
    ankhLockAt: Neferhoo.ankhLockAt,
    ankhThrowAt: Neferhoo.ankhThrowAt,
    secondMailAt: 9.6,
    waveAt: 5.9,
  );




  /// One cycle, in combat seconds ([SkyBoss.combatTime]). Fury never retimes
  /// it.
  final double period;

  /// The first mail call: it locks at [mailLockAt], its letters leave his
  /// hand from [mailReleaseAt] (the same in both clocks).
  double get mailLockAt => Neferhoo.mailLockAt;
  double get mailReleaseAt => Neferhoo.mailReleaseAt;

  /// The ankh: both lanes lock at [ankhLockAt], it is thrown at
  /// [ankhThrowAt] (1.4 s later in both clocks).
  final double ankhLockAt, ankhThrowAt;

  /// The second mail call of a cycle the ankh runs in (the full fight and
  /// fury), or null (the classic clock has none). It sends no bats.
  final double? secondMailAt;

  /// The extra wave of [Neferhoo.waveBats] mummy bats in a cycle the ankh
  /// does not run in (the warm-up's open sky), or null.
  final double? waveAt;

  bool get isFaster => this != classic;

  /// The time within the cycle, and the cycle's number from 0, at combat
  /// time [combat] (0 or more).
  double cycleTime(double combat) => combat % period;
  int cycleNumber(double combat) => (combat / period).floor();

  /// How many times the cycle moment [at] has come by combat time
  /// [combat]: the rules latch an event when this rises.
  int count(double combat, double at) =>
      combat < at ? 0 : ((combat - at) / period).floor() + 1;

  /// The call moments of a cycle in time order (cycle seconds): the first
  /// call, the warm-up's wave, the second call. Which run in a cycle the
  /// rules decide at each moment ([NeferhooCallKind]).
  List<(double, NeferhooCallKind)> get callMoments => [
    (mailLockAt, NeferhooCallKind.first),
    if (waveAt case final at?) (at, NeferhooCallKind.wave),
    if (secondMailAt case final at?) (at, NeferhooCallKind.second),
  ];
}

/// What a call moment of the faster fight sends ([NeferhooBeats.callMoments]).
enum NeferhooCallKind {
  /// The cycle's first mail call: letters, then its mummy bats
  /// ([Neferhoo.batsFor]).
  first,

  /// The warm-up's wave of mummy bats (a cycle without the ankh only).
  wave,

  /// The second mail call (a cycle with the ankh only, after its return
  /// pass): letters alone.
  second,
}

/// One call of the faster fight (rules 55), latched at its lock: a mail
/// call's lane, its letters and bats, or the warm-up's wave of bats. The
/// art draws each call's lane from [lockedAt] until what it sent has passed
/// the bird (two can be on screen at once). The classic fight latches none.
class NeferhooCall {
  NeferhooCall({
    required this.number,
    required this.cycle,
    required this.kind,
    required this.lane,
    required this.lockedAt,
    required this.express,
    required this.letters,
  });

  /// Its place among the fight's calls (from 0), and its cycle.
  final int number, cycle;
  final NeferhooCallKind kind;

  /// Its lane (screen y) and when it locked (boss age).
  final double lane, lockedAt;

  /// The express post (fury, latched at the lock).
  final bool express;

  /// Letters it deals (none for a wave).
  final int letters;

  bool get wave => kind == NeferhooCallKind.wave;
}

/// One of Neferhoo's letters: dealt down the [lane] locked by its mail call,
/// it leaves his hand at boss age [releaseAt] and flies left at [speed]
/// (screen-fixed: a sprint cannot shorten it). The rules latch its fate.
class NeferhooLetter {
  NeferhooLetter({
    required this.cycle,
    required this.index,
    required this.lane,
    required this.releaseAt,
    required this.speed,
    required this.express,
    this.call = -1,
  });

  /// The mail call's cycle, and its place in the stream (from 0).
  final int cycle, index;

  /// The faster fight's call it was dealt by ([NeferhooCall.number]), or -1.
  final int call;
  final double lane, releaseAt, speed;

  /// Dealt by the express post (fury).
  final bool express;

  /// When (boss age) a rock (or a ram) caught it and where it was struck,
  /// or null.
  double? returnedAt;
  double struckX = 0, struckY = 0;

  /// When (boss age) a returned letter lands on his chest: latched at the
  /// catch, [Neferhoo.returnSeconds] of its distance to the chest then.
  double? homeAt;

  /// When (boss age) it landed home for [Neferhoo.returnDamage] (the step at
  /// or just after [homeAt] that dealt it: [SkyBoss.lastHitAt] then), or hit
  /// the bird, or flew off the left edge; null while it flies.
  double? landedAt, spentAt;

  /// It was spent on a bird (rather than the left edge): it hurt the bird,
  /// or met it while it was still recovering from a hurt.
  bool delivered = false;

  bool get returned => returnedAt != null;
  bool get gone => landedAt != null || spentAt != null;

  /// Its screen x at boss age [age], flying from a hand at [handX] (before
  /// it is returned).
  double xAt(double age, double handX) => handX - speed * (age - releaseAt);

  /// Whether it has left his hand by boss age [age].
  bool dealtBy(double age) => age >= releaseAt;

  /// 0 to 1 along its way home at boss age [age] (0 until it is returned).
  double homeward(double age) {
    final from = returnedAt, to = homeAt;
    if (from == null || to == null) return 0;
    return to > from ? ((age - from) / (to - from)).clamp(0.0, 1.0) : 1;
  }

  /// Where a returned letter is at boss age [age], on its curve from where
  /// it was struck to his chest at ([chestX], [chestY]) (the boss's x and y
  /// now: it homes on him as he bobs).
  (double, double) returnAt(
    double age, {
    required double chestX,
    required double chestY,
  }) {
    final u = homeward(age);
    final (cx, cy) = (
      struckX + Neferhoo.returnControl.$1,
      struckY + Neferhoo.returnControl.$2,
    );
    final a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u;
    return (
      a * struckX + b * cx + c * chestX,
      a * struckY + b * cy + c * chestY,
    );
  }
}

/// One of Neferhoo's ankhs: out along [laneA] from his hand to the turn
/// behind the bird, a half loop, back along [laneB] (fury's second one flies
/// the mirror). Both lanes are latched at its lock, the loop is drawn from
/// [lockedAt]; it is thrown at [thrownAt] (boss ages).
class NeferhooAnkh {
  NeferhooAnkh({
    required this.cycle,
    required this.laneA,
    required this.laneB,
    required this.lockedAt,
    required this.thrownAt,
    required this.speed,
    this.second = false,
  });
  final int cycle;
  final double laneA, laneB, lockedAt, thrownAt, speed;

  /// Fury's mirrored second ankh.
  final bool second;

  /// When (boss age) it came home to his hand, latched by the rules.
  double? caughtAt;

  /// The length of its whole flight from a hand at [handX] turning at
  /// [turnX].
  double length(double handX, double turnX) =>
      (handX - turnX) * 2 + math.pi * (laneB - laneA).abs() / 2;

  /// When (boss age) it is home again (the throw plus its loop at its
  /// speed): about 2.7 s after the throw at 640 px wide, 4.1 s at 864.
  double homeAt({required double handX, required double turnX}) =>
      thrownAt + length(handX, turnX) / speed;

  /// When (boss age) its first and second pass cross screen column
  /// [column] (out along [laneA], back along [laneB]).
  (double, double) passes({
    required double handX,
    required double turnX,
    required double column,
  }) {
    final out = handX - turnX;
    final arc = math.pi * (laneB - laneA).abs() / 2;
    return (
      thrownAt + (handX - column) / speed,
      thrownAt + (out + arc + column - turnX) / speed,
    );
  }

  /// Its centre at boss age [age], or null when it is not in flight.
  (double, double)? at(
    double age, {
    required double handX,
    required double turnX,
  }) {
    final s = (age - thrownAt) * speed;
    final out = handX - turnX, r = (laneB - laneA).abs() / 2;
    final arc = math.pi * r;
    if (s < 0 || s > out * 2 + arc) return null;
    if (s <= out) return (handX - s, laneA);
    if (s <= out + arc) {
      final a = (s - out) / r;
      final mid = (laneA + laneB) / 2;
      final sign = laneB > laneA ? 1 : -1;
      return (turnX - r * math.sin(a), mid - sign * r * math.cos(a));
    }
    return (turnX + (s - out - arc), laneB);
  }
}

/// One of the mummy bats a mail call sends in the tougher fight (rules
/// version 52), latched at the call's lock: it flies in from the right edge
/// of the sky ([Neferhoo.batStartX]) at boss age [launchAt] down the call's
/// [lane] and closes in at [pace] screen heights a second. The rules then fly it as a small enemy ([SkyEnemy] of
/// [EnemyKind.mummyBat], in `FlightSimulation.enemies`): the simple bat's
/// arc, settling into the lane on its final approach, touch hurts, a rock or
/// a sprint's ram downs it.
class NeferhooBat {
  NeferhooBat({
    required this.cycle,
    required this.index,
    required this.lane,
    required this.launchAt,
    required this.pace,
    required this.fury,
    this.call = -1,
  });

  /// The mail call's cycle and its place among the call's bats (from 0).
  final int cycle, index;

  /// The faster fight's call that sent it ([NeferhooCall.number]: a first
  /// mail call or the warm-up's wave), or -1.
  final int call;
  final double lane, launchAt, pace;

  /// Sent by the express post (fury's trio).
  final bool fury;

  /// The enemy it became at its launch (null before). It stays here after
  /// it is downed or gone.
  SkyEnemy? enemy;
  bool get launched => enemy != null;

  /// When (boss age) the rules found it gone from the sky (downed, rammed,
  /// spent on the bird or flown off the left edge), or null.
  double? goneAt;
}

/// What the rules latch and count through one fight with Neferhoo (held by
/// the boss as [SkyBoss.neferhoo]). Counters only ever rise, so cues can
/// edge-detect them and a seek that re-simulates restores them exactly.
class NeferhooFight {
  /// Every letter dealt and every ankh thrown, oldest first. Never pruned
  /// while he fights; the art reads [NeferhooBoss.liveLetters] and
  /// [NeferhooBoss.liveAnkhs].
  final List<NeferhooLetter> letters = [];
  final List<NeferhooAnkh> ankhs = [];

  /// Every mummy bat latched by a mail call of the tougher fight, oldest
  /// first (empty at rules 50). [batsLaunched] of them have left his hand.
  final List<NeferhooBat> bats = [];

  /// The faster fight's calls (rules 55), oldest first (empty before 55),
  /// and the rules' cursor over the clock's call moments
  /// ([NeferhooBeats.callMoments]: a moment that sends nothing is passed).
  final List<NeferhooCall> calls = [];
  int callMoments = 0;

  /// The faster fight's warm-up waves so far, and when (boss age) the latest
  /// locked (render and cue edges; the mail call's [mailLockedAt] is not
  /// moved by a wave).
  int waves = 0;
  double waveLockedAt = double.negativeInfinity;

  /// The latest mail call: its lane, when it locked (boss age) and whether
  /// it is the express post (fury, latched at the lock).
  double laneY = .5;
  double mailLockedAt = double.negativeInfinity;
  bool express = false;

  /// The latest ankh lock (boss age) and whether it threw two.
  double ankhLockedAt = double.negativeInfinity;
  bool twoAnkhs = false;

  /// Mail calls and ankh locks so far: the cues' edges. [mailLocks] is also
  /// the rules' cursor (every cycle locks one); [ankhLocks] counts the locks
  /// that threw (a cycle before the signature is armed throws none), and
  /// [ankhMoments] is the rules' cursor over every cycle's ankh moment.
  int mailLocks = 0, ankhLocks = 0, ankhMoments = 0;

  /// Letters that have left his hand (one rise per flick), caught and sent
  /// back (by a rock or a ram), and landed home for 25.
  int lettersDealt = 0, lettersReturned = 0, returnsLanded = 0;

  /// Ankhs thrown (two per lock in fury) and home again, and rocks (or
  /// blasts) that scuffed his wraps.
  int ankhThrows = 0, ankhCatches = 0, wrapScuffs = 0;

  /// Times a letter, or an ankh, hurt a bird (a bird still recovering from
  /// a hurt is not counted again).
  int letterHits = 0, ankhHits = 0;

  /// Mummy bats that have flown in (the rules' cursor over [bats]; one rise
  /// per bat).
  int batsLaunched = 0;

  /// Rocks on the wraps since the last returned letter (the adaptive hint).
  int scuffsSinceReturn = 0;

  /// Render-only: when (boss age) a letter was last caught, last landed
  /// home, and a rock last scuffed his wraps.
  double lastReturnAt = double.negativeInfinity;
  double lastLandAt = double.negativeInfinity;
  double lastScuffAt = double.negativeInfinity;

  /// Render-only: when (boss age) the latest mummy bat flew in.
  double lastBatAt = double.negativeInfinity;
}

/// The mail call's beat, for the art: [windup] from the lock to the first
/// letter (the satchel opens, the letters rise into his fan), [flicking]
/// from the first letter until [Neferhoo.flickTail] after the last.
enum NeferhooMailPhase { idle, windup, flicking }

/// The ankh's beat, for the art: [rise] from the lock, [spinUp] for the last
/// [Neferhoo.spinUpSeconds] before the throw, [thrown] until the last ankh
/// of the lock is home, [caught] for [Neferhoo.catchSeconds] after.
enum NeferhooAnkhPhase { idle, rise, spinUp, thrown, caught }

/// What the art, the audio and the UI read off a Neferhoo boss. Pure
/// functions of the boss's age and of what the rules latched on
/// [SkyBoss.neferhoo]; empty, idle or zero for any other boss and outside
/// his fight (the arrival, the defeat).
extension NeferhooBoss on SkyBoss {
  bool get _mailFighting => isNeferhoo && phase == BossPhase.attacking;

  /// His fight's clock: rules 55's faster one, or the classic 12 s cycle.
  NeferhooBeats get neferhooBeats =>
      fasterNeferhoo ? NeferhooBeats.faster : NeferhooBeats.classic;

  /// The time within his cycle (12 s; 9 s in the faster fight), or 0 when
  /// he is not fighting.
  double get mailCycle =>
      _mailFighting ? neferhooBeats.cycleTime(combatTime) : 0;

  /// The cycle number from 0, or -1 when he is not fighting.
  int get mailCycleNumber =>
      _mailFighting ? neferhooBeats.cycleNumber(combatTime) : -1;

  /// His hand's screen x.
  double get handX => x - Neferhoo.handOffset;

  /// The latest mail call's lane (screen y).
  double get laneY => neferhoo.laneY;

  /// Seconds since the latest mail call locked (negative infinity before
  /// the first), while he fights.
  double get _sinceMail =>
      _mailFighting ? age - neferhoo.mailLockedAt : double.negativeInfinity;

  /// The mail call's beat now.
  NeferhooMailPhase get mailPhase {
    final t = _sinceMail;
    if (!(t >= 0)) return NeferhooMailPhase.idle;
    if (t < Neferhoo.windupSeconds) return NeferhooMailPhase.windup;
    final express = neferhoo.express;
    final last =
        (Neferhoo.streamCount(fury: express) - 1) * Neferhoo.gap(fury: express);
    return t < Neferhoo.windupSeconds + last + Neferhoo.flickTail
        ? NeferhooMailPhase.flicking
        : NeferhooMailPhase.idle;
  }

  /// 0 to 1 through the wind-up from the lock to the first letter; 1 while
  /// the letters are flicked; 0 otherwise.
  double get mailWindup => switch (mailPhase) {
    NeferhooMailPhase.idle => 0,
    NeferhooMailPhase.windup => (_sinceMail / Neferhoo.windupSeconds).clamp(
      0.0,
      1.0,
    ),
    NeferhooMailPhase.flicking => 1,
  };

  /// Letters still fanned in his hand (0 to 3): the latest call's letters
  /// not yet flicked, from [Neferhoo.fanDelay] after its lock (the express
  /// post's five show as three).
  int get lettersInHand {
    if (!(_sinceMail >= Neferhoo.fanDelay)) return 0;
    final lock = neferhoo.mailLockedAt;
    var n = 0;
    for (final letter in neferhoo.letters.reversed) {
      if (letter.releaseAt < lock) break;
      if (!letter.dealtBy(age)) n++;
    }
    return math.min(n, 3);
  }

  /// The tougher fight's mummy bats of the latest mail call still to come
  /// (0 to 3): latched at its lock and not yet flown in, while he fights. A launched one is a small enemy ([EnemyKind.mummyBat]) in
  /// `FlightSimulation.enemies`, drawn and judged as one.
  int get batsWaiting {
    if (!(_sinceMail >= 0)) return 0;
    final lock = neferhoo.mailLockedAt;
    var n = 0;
    for (final bat in neferhoo.bats.reversed) {
      if (bat.launchAt < lock) break;
      if (!bat.launched) n++;
    }
    return n;
  }

  /// The letters to draw: dealt and not gone, while he fights (a defeat
  /// leaves none). A returned one flies home ([NeferhooLetter.returnAt]).
  List<NeferhooLetter> get liveLetters => !_mailFighting
      ? const []
      : [
          for (final letter in neferhoo.letters)
            if (letter.dealtBy(age) && !letter.gone) letter,
        ];

  /// The ankhs to draw: locked and not yet home, while he fights.
  List<NeferhooAnkh> get liveAnkhs => !_mailFighting
      ? const []
      : [
          for (final ankh in neferhoo.ankhs)
            if (age >= ankh.lockedAt && ankh.caughtAt == null) ankh,
        ];

  /// When (boss age) the latest ankh locked.
  double get ankhLockedAt => neferhoo.ankhLockedAt;

  /// The ankh's beat now (idle through a cycle that throws none: the
  /// warm-up's).
  NeferhooAnkhPhase get ankhPhase {
    if (!_mailFighting) return NeferhooAnkhPhase.idle;
    final lock = neferhoo.ankhLockedAt;
    if (!(age >= lock)) return NeferhooAnkhPhase.idle;
    final throwAt = lock + Neferhoo.ankhThrowAt - Neferhoo.ankhLockAt;
    if (age < throwAt - Neferhoo.spinUpSeconds) return NeferhooAnkhPhase.rise;
    if (age < throwAt) return NeferhooAnkhPhase.spinUp;
    var home = double.negativeInfinity;
    for (final ankh in neferhoo.ankhs.reversed) {
      if (ankh.lockedAt != lock) break;
      final caught = ankh.caughtAt;
      if (caught == null) return NeferhooAnkhPhase.thrown;
      home = math.max(home, caught);
    }
    return age < home + Neferhoo.catchSeconds
        ? NeferhooAnkhPhase.caught
        : NeferhooAnkhPhase.idle;
  }

  /// Render-only times (boss age) of the latest return, landing, scuff and
  /// mummy bat launch.
  double get lastReturnAt => neferhoo.lastReturnAt;
  double get lastLandAt => neferhoo.lastLandAt;
  double get lastScuffAt => neferhoo.lastScuffAt;
  double get lastBatAt => neferhoo.lastBatAt;

  /// The fight's one-line hint (HUD tag and the semantics label), first
  /// match: a letter just sent back; the ankh from its lock until it is home
  /// (two in fury); the adaptive line after [Neferhoo.scuffsBeforeHint]
  /// rocks on the wraps without a return; the mail call from its lock until
  /// its stream has passed the bird (the express post's in fury); in the
  /// tougher fight, its mummy bats until they have too; the open sky's line
  /// for the stage.
  String get neferhooHint {
    if (!_mailFighting) return _openSkyHint;
    final fight = neferhoo;
    if (age - fight.lastReturnAt < Neferhoo.returnHintSeconds) {
      return fasterNeferhoo ? Neferhoo.fasterReturnHint : Neferhoo.returnHint;
    }
    final ankh = ankhPhase;
    if (ankh != NeferhooAnkhPhase.idle && ankh != NeferhooAnkhPhase.caught) {
      return fight.twoAnkhs ? Neferhoo.twoAnkhsHint : Neferhoo.ankhHint;
    }
    final mail = _mailComing;
    if (fight.scuffsSinceReturn >= Neferhoo.scuffsBeforeHint) {
      return Neferhoo.neferhooScuffHint;
    }
    if (mail) return fight.express ? Neferhoo.expressHint : Neferhoo.mailHint;
    if (_batsComing) return Neferhoo.batsHint;
    return _openSkyHint;
  }

  /// The stage's line when nothing is coming (and outside the fight).
  String get _openSkyHint => stage == 0
      ? Neferhoo.warmUpHint
      : enraged
      ? Neferhoo.furyHint
      : Neferhoo.calmHint;

  /// Whether the latest mail call is still coming: locked, and a letter of
  /// it not yet past the bird's column (nor sent back nor spent).
  bool get _mailComing {
    if (!(_sinceMail >= 0)) return false;
    final lock = neferhoo.mailLockedAt;
    for (final letter in neferhoo.letters.reversed) {
      if (letter.releaseAt < lock) break;
      if (letter.gone || letter.returned) continue;
      if (letter.xAt(age, handX) > Neferhoo.birdColumn - .1) return true;
    }
    return false;
  }

  /// Whether a mummy bat of the latest mail call is still coming: yet to fly
  /// in, or flying and not yet past the bird's column (nor gone).
  bool get _batsComing {
    if (!(_sinceMail >= 0)) return false;
    final lock = neferhoo.mailLockedAt;
    for (final bat in neferhoo.bats.reversed) {
      if (bat.launchAt < lock) break;
      if (bat.goneAt != null) continue;
      final enemy = bat.enemy;
      if (enemy == null || enemy.x > Neferhoo.birdColumn - .1) return true;
    }
    return false;
  }
}
