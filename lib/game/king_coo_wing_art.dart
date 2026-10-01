import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'king_coo_kit.dart';
import 'king_coo_layout.dart';
import 'king_coo_pose.dart';

/// One of King Coo's wings as the pose has it this frame: where its root is,
/// how it is turned (radians, 0 at the tail, +pi/2 straight down, pi at the
/// bird, -pi/2 up), how far the toss stretches it, and everything that changes
/// how the FEATHERS sit: how open the wing is, how hard the air drags on it,
/// how spread, how limp, how tightly it grips.
///
/// The wing is a pure function of the pose: it keeps no history. The LAG (the
/// hand trails the forearm, the forearm bows against the stroke) comes from the
/// wing's own angular rate, which is known in closed form from the pose's
/// channels (the beat's phase, the throw's progress, the stomp's pulse): see
/// [KingCooWingArt.dragOf].
///
/// KIT-REQUEST (optional): `KingCooPose.wingNearRate/wingFarRate` (rad/s, 0
/// under Reduced Motion) would replace the estimate in `dragOf` by the real
/// derivative; nothing else changes.
final class KingCooWing {
  const KingCooWing({
    required this.shoulder,
    required this.angle,
    required this.stretch,
    required this.far,
    required this.tone,
    this.throwing = 0,
    this.stomp = 0,
    this.openness,
    this.flare = 0,
    this.drag = 0,
    this.limp = 0,
    this.turn = 0,
  });

  /// The near wing, from the pose (root [KingCooLayout.nearShoulder], the
  /// angle [KingCooPose.wingNear], stretched by the toss).
  factory KingCooWing.nearOf(KingCooPose pose) => _of(pose, far: false);

  /// The far wing: behind the body, darker, a little smaller, its own beat
  /// phase, its own feather count: never a clone of the near one.
  factory KingCooWing.farOf(KingCooPose pose) => _of(pose, far: true);

  static KingCooWing _of(KingCooPose pose, {required bool far}) {
    double fin(double v, double d) => v.isFinite ? v : d;
    final angle = fin(
      far ? pose.wingFar : pose.wingNear,
      far ? KingCooLayout.restWingFar : KingCooLayout.restWingNear,
    ).clamp(-4.0, 6.0);
    final stretch = far ? 1.0 : fin(pose.wingStretch, 1).clamp(1.0, 1.3);
    final throwing = far ? 0.0 : fin(pose.armThrow, 0).clamp(0.0, 1.0);
    final stomp = fin(pose.stomp, 0).clamp(0.0, 1.0);
    // The spread: the whistle's blow, the roar and the inflating defeat fan
    // the feathers; the fury keeps them a little raised.
    final flare = math
        .max(
          math.max(pose.blast, pose.whistle * .6),
          math.max(pose.roar, (pose.puff - 1) / .3),
        )
        .clamp(0.0, 1.0);
    return KingCooWing(
      shoulder: far ? KingCooLayout.farShoulder : KingCooLayout.nearShoulder,
      angle: angle,
      stretch: stretch,
      far: far,
      tone: pose.tone,
      throwing: throwing,
      stomp: stomp,
      flare: fin(flare, 0) + .22 * fin(pose.fury, 0).clamp(0.0, 1.0),
      drag: KingCooWingArt.dragOf(pose, far: far),
      limp: fin(pose.deflate * 1.4, 0).clamp(0.0, 1.0),
      turn: fin(pose.roll + pose.pitch, 0),
    );
  }

  final Offset shoulder;
  final double angle, stretch, throwing, stomp;
  final bool far;
  final KingCooTone tone;

  /// How open (0 folded along the flank .. 1 spread), or null: from [angle].
  final double? openness;

  /// Extra spread of the primaries (0..1.3): the whistle's blow, the roar, the
  /// inflating defeat, the fury.
  final double flare;

  /// How hard the air drags on the wing, -1 (swinging up) .. 1 (swinging
  /// down): the forearm bows against the stroke and the hand trails.
  final double drag;

  /// 0 .. 1: the wing hangs limp (the pop).
  final double limp;

  /// The figure's own turn (roll + pitch): the light stays on the screen.
  final double turn;

  /// How open the wing is: 0 folded flat along the flank, 1 fully spread.
  double get open =>
      (openness ?? KingCooWingArt.openAt(angle, far: far)).clamp(0.0, 1.0);

  /// Where the wing's tip is, in the figure frame (what `handAt` is for the
  /// near wing): the rigid tip. While the arm throws the painted tip is pinned
  /// to it (see [throwing]).
  Offset get tip {
    final (sx, sy) = KingCooWingArt.scaleOf(stretch);
    final local = Offset(
      KingCooLayout.wingTipLocal.dx * sx,
      KingCooLayout.wingTipLocal.dy * sy,
    );
    return shoulder + KingCooLayout.turn(local, angle);
  }
}

/// Paints King Coo's wings: a pigeon's, in batched paths, built per frame
/// from the pose.
///
/// Anatomy (wing frame: root at the origin, pointing +x, leading edge on -y,
/// [KingCooLayout.wingLocalLength] long, drawn under the layout's scale):
///
///   spine    shoulder -> wrist -> tip. The wrist is the bend of the wing: high
///            and forward when folded, at mid-span when spread; the air bows it
///            against the stroke and lags the hand behind the forearm (see
///            [KingCooWingArt.dragOf]); a limp wing lets the hand fall.
///   hand     six pointed primaries fanned about the wrist (five on the far
///            wing), the outer one the longest and its tip the rigid tip
///            ([KingCooLayout.wingTipLocal]: pinned to it while the arm
///            throws, so the bomb rides the tip), stepping down toward the
///            wrist; slate with dark tips and pale shafts.
///   panel    one leaf over the forearm that narrows to a point over the hand:
///            the lesser coverts (a fine garland), the greater coverts and the
///            secondaries. Its trailing edge is six scallops (the secondaries'
///            tips); the two WING BARS are bands that follow it and end in the
///            same scallops; hairlines split the secondaries. Pale where the
///            moon reaches it, mid-lavender away from it.
///   alula    one small feather at the wrist, along the leading edge.
///
/// Light (from [KingCooTone]): the moon's cool rim on the leading edge and the
/// feathers' visible sides when they face the upper right, the windows' warm
/// glow on the trailing scallops when they face the lower left, both chosen from
/// the wing's angle ON SCREEN, so a raised wing catches the moon on its trailing
/// feathers and a folded one on its leading edge; a soft occlusion where the
/// panel tucks under the body, a cast shadow while it lies folded against it,
/// and two hard glints (the wrist and the outer tip) only where the moon
/// reaches. The far wing is the same drawing in shade, with one fewer primary
/// and secondary scallop and a hand swept farther back.
///
/// Value: the near wing is lighter than the torso (median L* 61-74 from rest
/// to raised, against 48-52), the dark bars and tips give it its pattern, and
/// the far wing sits 8-16 lower than the near one.
///
/// Cost: the shapes follow the pose, so the paths are BUILT per frame into
/// static scratch paths that are reset and refilled (nothing allocates per
/// frame); gradients are cached in unit space (three in all: the panel lit from
/// either side, the shoulder's occlusion); the tone goes through flat colours
/// (`tone.plate`/`lit`) or [KingCooKit.wash] on the panel only. Near wing 14-18
/// ops, far wing 12-14 (32 for both in the worst state, of the contract's 40),
/// 0 clips, 0 layers, 0 shaders built on a warm frame.
abstract final class KingCooWingArt {
  /// The wing's scale along and across: the toss lengthens it, and widens it a
  /// third as much.
  static (double, double) scaleOf(double stretch) => (
    KingCooLayout.wingScale * stretch,
    KingCooLayout.wingScale * (stretch > 1 ? 1 + (stretch - 1) * .3 : 1),
  );

  /// How open a wing at [angle] is: folded at the flank (0 and below the
  /// contract's rest +.05), opening from there, fully spread from -.6. The
  /// far wing at its rest (-.5) stands open behind the back.
  static double openAt(double angle, {bool far = false}) {
    final o = KingCooKit.ease(KingCooKit.ramp(-angle, -.05, .60));
    return far ? o * .92 : o;
  }

  // ---------------------------------------------------------------- lag --

  static const _beatSlope = 2 * math.pi * KingCooTimeline.beatHz;
  static const _furySlope = 2 * math.pi * KingCooTimeline.furyBeatHz;

  /// How hard the air drags on the wing: its angular rate (rad/s) over 12,
  /// clamped to -1 (swinging up, counter-clockwise) .. 1 (swinging down).
  ///
  /// The beat's rate is exact (the wave is `sin(x + .45 sin x)` at 1.6 Hz, 2.1
  /// in fury, the far wing .7 rad behind) times how much of the wing's angle
  /// the beat still owns (the throw, the whistle, the puff, the stomp, the
  /// pop and the defeat take it over); the throw and the stomp add their own
  /// closed-form rates. Zero under Reduced Motion.
  static double dragOf(KingCooPose pose, {required bool far}) {
    if (pose.reduced) return 0;
    double fin(double v) => v.isFinite ? v : 0;
    final fury = fin(pose.fury).clamp(0.0, 1.0);
    final arm = far ? 0.0 : fin(pose.armThrow).clamp(0.0, 1.0);
    final owns =
        (1 - arm) *
        (1 - fin(pose.whistle).clamp(0.0, 1.0)) *
        (1 - math.max(0.0, fin(pose.puff) - .3 * fury).clamp(0.0, 1.0)) *
        (1 - fin(pose.stomp).clamp(0.0, 1.0)) *
        (1 - fin(pose.roar).clamp(0.0, 1.0)) *
        (1 - fin(pose.wince).clamp(0.0, 1.0) * .8) *
        (1 - fin(pose.deflate).clamp(0.0, 1.0)) *
        (1 - .5 * fin(pose.blast).clamp(0.0, 1.0)) *
        (pose.death > 0 ? 0.0 : 1.0);
    var rate = 0.0;
    if (owns > 0) {
      final phi = fin(pose.beatPhase) - (far ? .7 : 0);
      final slope = 1 + .45 * math.cos(phi);
      final wave = math.cos(phi + .45 * math.sin(phi)) * slope;
      final amp = .75 * (1 + .35 * fury);
      rate += amp * wave * (fury > 0 ? _furySlope : _beatSlope) * owns;
    }
    rate += _stompRate(pose);
    if (!far) rate += _throwRate(pose);
    return (rate / 12).clamp(-1.0, 1.0);
  }

  /// The stomp's rate: a half sine over .25 s, both wings down then home; its
  /// phase is known from the fury's blend (`fury = t / .45`).
  static double _stompRate(KingCooPose p) {
    if (p.stomp <= 0 || p.fury <= 0 || p.fury >= 1) return 0;
    final tau = p.fury * KingCooTimeline.furyBlendSeconds;
    const span = KingCooTimeline.stompSeconds;
    if (tau >= span) return 0;
    // Eased in and out over 20 ms: the wings' lag never pops.
    final edge = math.min(
      KingCooKit.ramp(tau, 0, .02),
      KingCooKit.ramp(span - tau, 0, .02),
    );
    return 1.6 * math.pi / span * math.cos(math.pi * tau / span) * edge;
  }

  /// The throw's rate, decoded from the pose's own throw channels (windup,
  /// follow, bombHeld, stretch): dip (+), backswing (-), hold (0), swing (++,
  /// 38 rad/s at the end), overshoot (+ then -), home (-).
  static double _throwRate(KingCooPose p) {
    if (p.armThrow <= 0) return 0;
    final u = p.windup, f = p.follow;
    if (p.bombHeld > 0) {
      if (f > 0) return 38 * math.pow(f.clamp(0.0, 1.0), .375).toDouble();
      if (u < KingCooTimeline.backEnd) {
        final x = KingCooKit.ramp(
          u,
          KingCooTimeline.dipEnd,
          KingCooTimeline.backEnd,
        );
        return -38.8 * x * (1 - x);
      }
      return 0;
    }
    if (f > 0) {
      // After the release: `follow` = 1 - ease(after / .65).
      final r = _easeInverse(1 - f.clamp(0.0, 1.0));
      final after =
          r *
          (KingCooTimeline.followSeconds + KingCooTimeline.armReturnSeconds);
      if (after < KingCooTimeline.followSeconds) {
        // The overshoot's own rate, plus the hand's inertia: it is still
        // swinging at 38 rad/s when the arm stops, and the lag eases out.
        final reach = after / KingCooTimeline.followSeconds;
        return 5.97 * math.cos(math.pi * reach) * (1 - math.pow(reach, 4)) +
            32 * math.exp(-after / .03);
      }
      final y = KingCooKit.ramp(
        after,
        KingCooTimeline.followSeconds,
        KingCooTimeline.followSeconds + KingCooTimeline.armReturnSeconds,
      );
      return -44 * y * (1 - y);
    }
    // The dip into the sack.
    final x = KingCooKit.ramp(u, 0, KingCooTimeline.dipEnd);
    return 20 * x * (1 - x);
  }

  /// The inverse of smoothstep on 0..1.
  static double _easeInverse(double y) =>
      .5 - math.sin(math.asin((1 - 2 * y).clamp(-1.0, 1.0)) / 3);

  // -------------------------------------------------------------- paints --

  static const _moon = Offset(.6, -.8); // toward the moon, the light's way

  /// The panel's volume: pale where the moon reaches it, the plumage's own
  /// mid-tone where it does not. Built once per side the light comes from, in
  /// the wing's unit space (the far wing paints the same gradient and is dimmed
  /// by a flat wash); the tone is laid over it as washes.
  static Paint _panelPaint(double dir) => KingCooKit.cached(
    ('wing.panel', dir),
    () => KingCooKit.linear(
      Offset(0, dir * -.40),
      Offset(0, dir * .36),
      [
        Color.lerp(KingCooPalette.featherLit, KingCooPalette.white, .38)!,
        Color.lerp(KingCooPalette.feather, KingCooPalette.featherLit, 1.0)!,
        Color.lerp(KingCooPalette.feather, KingCooPalette.featherLit, .80)!,
      ],
      const [0, .50, 1],
    ),
  );

  /// The shoulder's occlusion: the panel darkens where it tucks under the
  /// body (x from the root to .5 along the wing).
  static Paint _rootPaint() => KingCooKit.cached(
    'wing.root',
    () => KingCooKit.linear(
      const Offset(-.12, 0),
      const Offset(.52, 0),
      [
        KingCooPalette.featherCore.withValues(alpha: .20),
        KingCooPalette.featherCore.withValues(alpha: .06),
        KingCooPalette.featherCore.withValues(alpha: 0),
      ],
      const [0, .55, 1],
    ),
  );

  /// Makes sure the three gradients exist (a cache lookup each): whichever
  /// way the light falls on a wing, no frame of a fight ever builds a shader.
  static void _prime() {
    _panelPaint(-1);
    _panelPaint(1);
    _rootPaint();
  }

  // Scratch paths, reset and refilled every wing (nothing allocates per frame).
  static final Path _fingers = Path(),
      _fingerCaps = Path(),
      _edgeF = Path(),
      _shafts = Path(),
      _panel = Path(),
      _rowA = Path(),
      _bar1 = Path(),
      _bar2 = Path(),
      _alula = Path(),
      _under = Path(),
      _lead = Path(),
      _tips = Path(),
      _teRim = Path(),
      _splits = Path(),
      _glint = Path();

  // The feather outline: half widths as a share of w/2 at `_a` along it.
  static const _a = <double>[0, .20, .44, .68, .86, .96];
  static const _hw = <double>[.50, .86, 1.0, .96, .76, .44];

  /// The pointed profile of the primaries: they end in a narrow point, so the
  /// stepped tips of a folded hand read as steps, not as one smooth leaf.
  static const _hwPoint = <double>[.50, .80, .92, .80, .50, .22];

  static double _hwAt(double a, [List<double> prof = _hw]) {
    if (a <= _a.first) return prof.first;
    for (var i = 1; i < _a.length; i++) {
      if (a <= _a[i]) {
        final t = (a - _a[i - 1]) / (_a[i] - _a[i - 1]);
        return prof[i - 1] + (prof[i] - prof[i - 1]) * t;
      }
    }
    return prof.last * (1 - a) / (1 - _a.last);
  }

  static Offset _mid(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  /// A smooth closed leaf from base [b] to tip [t], [w] wide, from `from` (a
  /// share of its length) on: the whole feather, or just its tip.
  static void _leaf(
    Path p,
    Offset b,
    Offset t,
    double w, [
    double from = 0,
    List<double> prof = _hw,
  ]) {
    final dx = t.dx - b.dx, dy = t.dy - b.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-5) return;
    final ux = dx / len, uy = dy / len;
    final nx = -uy, ny = ux;
    final half = w / 2;
    Offset at(double a, double c) => Offset(
      b.dx + ux * a * len + nx * c * half,
      b.dy + uy * a * len + ny * c * half,
    );
    // Left side out, the tip, the right side back, smoothed through midpoints.
    final pts = <Offset>[];
    if (from > 0) pts.add(at(from, _hwAt(from, prof)));
    for (var i = 0; i < _a.length; i++) {
      if (_a[i] > from + 1e-6) pts.add(at(_a[i], prof[i]));
    }
    pts.add(at(1, 0));
    for (var i = _a.length - 1; i >= 0; i--) {
      if (_a[i] > from + 1e-6) pts.add(at(_a[i], -prof[i]));
    }
    if (from > 0) pts.add(at(from, -_hwAt(from, prof)));
    if (from <= 0) pts.add(at(0, 0)); // the base, pointed under the next row
    final n = pts.length;
    final start = _mid(pts[n - 1], pts[0]);
    p.moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final m = _mid(pts[i], pts[(i + 1) % n]);
      p.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
    }
    p.close();
  }

  /// The visible edge of a shingled feather: its inner (+n) side from 30% of
  /// its length to the tip and a little way back along the outer side. The
  /// other side lies under the neighbour.
  static void _edge(Path p, Offset b, Offset t, double w) {
    final dx = t.dx - b.dx, dy = t.dy - b.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-5) return;
    final ux = dx / len, uy = dy / len;
    final nx = -uy, ny = ux;
    final half = w / 2;
    Offset at(double a, double c) => Offset(
      b.dx + ux * a * len + nx * c * half,
      b.dy + uy * a * len + ny * c * half,
    );
    final pts = <Offset>[
      at(.30, _hwAt(.30)),
      for (var i = 3; i < _a.length; i++) at(_a[i], _hw[i]),
      at(1, 0),
    ];
    p.moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final m = _mid(pts[i], pts[i + 1]);
      p.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
    }
    p.lineTo(pts.last.dx, pts.last.dy);
  }

  /// The visible side of a shingled feather, inset: from 50% of its length to
  /// the tip (the light catches it).
  static void _rimSide(Path p, Offset b, Offset t, double w) {
    final dx = t.dx - b.dx, dy = t.dy - b.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-5) return;
    final ux = dx / len, uy = dy / len;
    final nx = -uy, ny = ux;
    final half = w / 2 * .80;
    Offset at(double a, double c) => Offset(
      b.dx + ux * a * len + nx * c * half,
      b.dy + uy * a * len + ny * c * half,
    );
    final p0 = at(.52, _hwAt(.52));
    p.moveTo(p0.dx, p0.dy);
    final q1 = at(.80, _hwAt(.80)),
        q2 = at(.94, _hwAt(.94) * .7),
        q3 = at(.985, 0);
    p.quadraticBezierTo(q1.dx, q1.dy, _mid(q1, q2).dx, _mid(q1, q2).dy);
    p.quadraticBezierTo(q2.dx, q2.dy, q3.dx, q3.dy);
  }

  static Offset _turn(Offset v, double a) {
    final c = math.cos(a), s = math.sin(a);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  // ------------------------------------------------------------ geometry --

  static const _tipLocal = KingCooLayout.wingTipLocal;

  /// A garland: [n] arcs along `at(t0)..at(t1)`, each bowing by [amp] toward
  /// [bow] (a unit vector), cusps between them. The current point is moved to
  /// the first cusp.
  static void _garland(
    Path p,
    Offset Function(double) at,
    int n,
    double t0,
    double t1,
    Offset bow,
    double amp, {
    bool move = true,
  }) {
    var prev = at(t0);
    if (move) p.moveTo(prev.dx, prev.dy);
    for (var i = 1; i <= n; i++) {
      final next = at(t0 + (t1 - t0) * i / n);
      final ctl = _mid(prev, next) + bow * (2 * amp);
      p.quadraticBezierTo(ctl.dx, ctl.dy, next.dx, next.dy);
      prev = next;
    }
  }

  /// A bar: the region between the straight row at `phiA` and a garland at
  /// `phiB` (bowing [amp] toward [bow]) from `t0` to `t1`: a stripe whose
  /// trailing edge is scalloped like feather tips.
  static void _band(
    Path p,
    Offset Function(double, double) row,
    double phiA,
    double phiB,
    double t0,
    double t1,
    int n,
    double amp,
    Offset bow,
  ) {
    final a = row(t0, phiA);
    p.moveTo(a.dx, a.dy);
    for (var i = 1; i <= 3; i++) {
      final q = row(t0 + (t1 - t0) * i / 3, phiA);
      p.lineTo(q.dx, q.dy);
    }
    final b = row(t1, phiB);
    p.lineTo(b.dx, b.dy);
    _garland(p, (t) => row(t, phiB), n, t1, t0, bow, amp, move: false);
    p.close();
  }

  /// The wing's shape this frame, in the wing's own frame (see the class doc),
  /// into the scratch paths.
  static void _build(KingCooWing w) {
    final far = w.far;
    final grip = w.throwing;
    // The throwing arm closes its feathers around the bomb.
    final open = (w.open - .30 * grip).clamp(0.0, 1.0);
    final drag = w.drag;
    final limp = w.limp;
    final sx = w.stretch, sy = sx > 1 ? 1 + (sx - 1) * .3 : 1.0;
    final tipRigid = Offset(_tipLocal.dx * sx, _tipLocal.dy * sy);
    final chordLen = tipRigid.distance;
    final u = tipRigid / chordLen; // along the chord
    final lead = Offset(u.dy, -u.dx); // the leading-edge side (-y)
    final trail = -lead;

    // The spine: the wrist sits high and forward when the wing is folded, at
    // mid-span when it is spread; the air bows it against the stroke.
    final s = .34 + .16 * open;
    final h = (.21 - .09 * open) + .07 * drag - .30 * limp;
    final wrist = u * (chordLen * s) + lead * h;
    var hand = tipRigid - wrist;
    // The far wing's hand sweeps a little farther back, so two wings raised
    // together (the whistle, the roar) fan apart instead of stacking.
    if (far) hand = _turn(hand, .10 + .12 * open);
    // A limp wing (the pop) lets its hand fall toward the ground.
    if (limp > 0) {
      final g = _turn(const Offset(0, 1), -(w.angle + w.turn));
      final hd = hand / hand.distance;
      final cross = hd.dx * g.dy - hd.dy * g.dx;
      hand = _turn(hand, .5 * limp * cross.clamp(-1.0, 1.0));
    }
    // The hand trails the forearm by the drag (counter-clockwise when the wing
    // swings down), pinned to the rigid tip while the arm throws.
    // (Fully pinned from 40% of the grip on: the whole throw, home included,
    // keeps the bomb on the tip; the lag fades back in as the arm lets go.)
    final pin = KingCooKit.ease(KingCooKit.ramp(grip, 0, .4));
    final lagged = _turn(hand, -.30 * drag * (1 - pin));
    final tip = Offset.lerp(wrist + lagged, tipRigid, pin)!;
    hand = tip - wrist;
    final handLen = hand.distance;
    final hdir = hand / handLen;
    final spread =
        (far ? .46 : .42) +
        .40 * open +
        .34 * math.min(w.flare, 1.3) -
        .26 * w.stomp -
        .24 * grip;

    // ---- the hand: primaries fanned about the wrist, the outer one longest --
    final np = far ? 5 : 6;
    _fingers.reset();
    _fingerCaps.reset();
    _edgeF.reset();
    _shafts.reset();
    _tips.reset();
    final lenStep = far ? .135 : .115;
    for (var j = 0; j < np; j++) {
      final jf = j / (np - 1);
      final b = wrist + hdir * (handLen * .10 * (1 - jf)) + trail * .02;
      final t = wrist + _turn(hand, jf * spread) * (1 - lenStep * j);
      final wd =
          ((far ? .21 : .20) + .05 * open) *
          (j == 0
              ? .80
              : j == 1
              ? .92
              : 1.0);
      _leaf(_fingers, b, t, wd, 0, _hwPoint);
      _leaf(
        _fingerCaps,
        b,
        t,
        wd,
        math.max(.74, 1 - .12 / math.max((t - b).distance, .2)),
        _hwPoint,
      );
      _edge(_edgeF, b, t, wd);
      _rimSide(_tips, b, t, wd);
      final sb = Offset.lerp(b, t, .50)!, se = Offset.lerp(b, t, .88)!;
      _shafts.moveTo(sb.dx, sb.dy);
      _shafts.lineTo(se.dx, se.dy);
    }

    // ---- the panel: shield, greater coverts and secondaries in one piece --
    final tipPoint = wrist + hdir * (handLen * .46) + lead * .005;
    final top = <Offset>[
      const Offset(-.02, -.07),
      wrist * .22 + lead * (.105 + h * .2),
      wrist * .62 + lead * (.15 + h * .3),
      wrist + lead * .12 - hdir * .04,
      wrist + hdir * (handLen * .26) + lead * .075,
      tipPoint,
    ];
    final rootBottom = u * -.01 + trail * (.14 + .17 * open);
    Offset leAt(double t) {
      final x = t.clamp(0.0, 1.0) * (top.length - 1);
      final i = x.floor().clamp(0, top.length - 2);
      return Offset.lerp(top[i], top[i + 1], x - i)!;
    }

    Offset teAt(double t) =>
        Offset.lerp(rootBottom, tipPoint, t)! +
        trail * (.04 * math.sin(math.pi * t));
    Offset rowAt(double t, double phi) => Offset.lerp(leAt(t), teAt(t), phi)!;

    // The panel: a leaf that narrows to a point over the hand, its trailing
    // edge six scallops (the secondaries' tips), rounded at the shoulder.
    _panel.reset();
    KingCooKit.spline(top, closed: false, into: _panel);
    final nTe = far ? 5 : 6;
    final scallop = .055 + .04 * open;
    _garland(
      _panel,
      (t) => teAt(1 - t),
      nTe,
      0,
      1,
      trail,
      scallop,
      move: false,
    );
    _panel.quadraticBezierTo(-.17, .035, top.first.dx, top.first.dy);
    _panel.close();

    // Rows: the lesser coverts (a fine garland) and the two wing bars, bands
    // that follow the panel and end in the feathers' own scalloped tips.
    _rowA.reset();
    _garland(_rowA, (t) => rowAt(t, .19), 6, .10, .88, trail, .04);
    _bar1.reset();
    _band(_bar1, rowAt, .39, .48, 1 / nTe, 5 / nTe, 4, .046, trail);
    _bar2.reset();
    _teRim.reset();
    _splits.reset();
    for (var k = 1; k < nTe; k++) {
      final t = k / nTe;
      final a0 = rowAt(t, .96), a1 = rowAt(t, .56);
      _splits.moveTo(a0.dx, a0.dy);
      _splits.lineTo(a1.dx, a1.dy);
    }
    _garland(
      _teRim,
      (t) => rowAt(t, .985),
      nTe,
      1 / nTe,
      1,
      trail,
      scallop * .8,
    );
    _band(_bar2, rowAt, .74, .83, 1 / nTe, 1, 5, scallop * .85, trail);

    // The alula: two small feathers at the wrist, lying along the leading edge.
    _alula.reset();
    final ab = wrist + lead * .075;
    _leaf(_alula, ab, ab + _turn(hdir, -.18) * .36, .10, 0, _hwPoint);

    // The leading edge's rim, inset.
    _lead.reset();
    KingCooKit.spline(
      <Offset>[
        for (var i = 1; i < top.length - 1; i++) top[i] + trail * .035,
        // ... and on along the outer primary's leading side to its tip.
        wrist + hdir * (handLen * .62) + lead * .02,
        tip - hdir * .07 + trail * .012,
      ],
      closed: false,
      into: _lead,
    );

    // The silhouette: the ink, the cast shadow.
    _under.reset();
    _under.addPath(_fingers, Offset.zero);
    _under.addPath(_panel, Offset.zero);

    // A glint at the wrist.
    _glint.reset();
    final gw = wrist + lead * .085 - hdir * .09;
    _glint.moveTo(gw.dx, gw.dy);
    final ge = gw + hdir * .20 + trail * .012;
    _glint.quadraticBezierTo(
      (gw.dx + ge.dx) / 2 + lead.dx * .03,
      (gw.dy + ge.dy) / 2 + lead.dy * .03,
      ge.dx,
      ge.dy,
    );
    // ... and a point of light on the outer primary's tip.
    final gt = tip - hdir * .16 + lead * .012;
    _glint.moveTo(gt.dx, gt.dy);
    _glint.lineTo(gt.dx + hdir.dx * .06, gt.dy + hdir.dy * .06);
  }

  // --------------------------------------------------------------- paint --

  /// [w] with every number made finite and bounded (a replay with a bad pose
  /// must never throw or draw across the screen), or null when it has no root.
  static KingCooWing? _sane(KingCooWing w) {
    bool ok(double v) => v.isFinite;
    if (!ok(w.shoulder.dx) || !ok(w.shoulder.dy)) return null;
    final open = w.openness;
    if (ok(w.angle) &&
        ok(w.stretch) &&
        ok(w.throwing) &&
        ok(w.stomp) &&
        ok(w.flare) &&
        ok(w.drag) &&
        ok(w.limp) &&
        ok(w.turn) &&
        (open == null || ok(open)) &&
        w.stretch >= 1 &&
        w.stretch <= 1.3) {
      return w;
    }
    double f(double v, double d, double lo, double hi) =>
        ok(v) ? v.clamp(lo, hi) : d;
    return KingCooWing(
      shoulder: w.shoulder,
      angle: f(
        w.angle,
        w.far ? KingCooLayout.restWingFar : KingCooLayout.restWingNear,
        -6.0,
        6.0,
      ),
      stretch: f(w.stretch, 1, 1.0, 1.3),
      far: w.far,
      tone: w.tone,
      throwing: f(w.throwing, 0, 0.0, 1.0),
      stomp: f(w.stomp, 0, 0.0, 1.0),
      openness: open == null ? null : f(open, 0, 0.0, 1.0),
      flare: f(w.flare, 0, 0.0, 1.3),
      drag: f(w.drag, 0, -1.0, 1.0),
      limp: f(w.limp, 0, 0.0, 1.0),
      turn: f(w.turn, 0, -1.0, 1.0),
    );
  }

  static void paint(Canvas c, KingCooWing wing) {
    final w = _sane(wing);
    if (w == null) return;
    _prime();
    final tone = w.tone;
    final far = w.far;
    _build(w);
    final s = KingCooLayout.wingScale * (far ? .94 : 1.0);
    final px = 1 / s; // one rig unit in the wing's own frame
    final turnBack = -(w.angle + w.turn);

    // The light, in the wing's own frame: which side faces the moon.
    final toMoon = _turn(_moon, turnBack);
    final facing = toMoon.dy; // > 0: the trailing side faces the moon

    Color plate(Color col) =>
        tone.plate(far ? KingCooKit.shade(col, .72) : col);
    final fingerColor = plate(
      Color.lerp(KingCooPalette.feather, KingCooPalette.featherLit, .50)!,
    );
    final barColor = tone.lit(
      far ? KingCooKit.shade(KingCooPalette.bar, .8) : KingCooPalette.bar,
    );
    final edge = tone.lit(KingCooPalette.inkCool);
    final edgeA = far ? .7 : .9;
    final hair = KingCooLayout.inkDetail * px;
    // A world-space shift as the wing's own frame sees it.
    Offset local(Offset world) => _turn(world, turnBack) * px;

    c.save();
    c.translate(w.shoulder.dx, w.shoulder.dy);
    c.rotate(w.angle);
    // The stomp's fist: the wing fattens across for the slam (the ink and the
    // light shift by at most 22% of their size at the peak, for a few frames).
    c.scale(s, s * (1 + .22 * w.stomp));

    // The wing's shadow on the body while it lies folded against it.
    if (!far) {
      final lie = (1 - w.open) * (1 - tone.washAlpha);
      if (lie > .02) {
        final drop = local(const Offset(-.05, .078));
        c.save();
        c.translate(drop.dx, drop.dy);
        c.drawPath(
          _under,
          KingCooKit.fill(KingCooPalette.featherCore, .34 * lie),
        );
        c.restore();
      }
    }

    // Ink outline: the outer contour of the panel and the fingers.
    c.drawPath(
      _under,
      KingCooKit.line(KingCooPalette.ink, (far ? .12 : .14) * px),
    );

    // The hand: dark primaries, their shingled edges and pale shafts.
    c.drawPath(_fingers, KingCooKit.fill(fingerColor));
    c.drawPath(_fingerCaps, KingCooKit.fill(barColor, far ? .6 : .78));
    c.drawPath(_edgeF, KingCooKit.line(edge, hair * 1.15, far ? .5 : .68));
    c.drawPath(
      _shafts,
      KingCooKit.line(
        tone.lit(KingCooPalette.featherLit),
        hair * .85,
        far ? .2 : .32,
      ),
    );

    // The panel over the fingers' bases.
    final dir = facing >= 0 ? -1.0 : 1.0;
    c.drawPath(_panel, Paint()..shader = _panelPaint(dir).shader);
    if (far) {
      // Behind the body, in its shade: a flat wash of the core colour.
      c.drawPath(
        _panel,
        KingCooKit.fill(
          Color.lerp(KingCooPalette.featherCore, KingCooPalette.ink, .4)!,
          .34,
        ),
      );
    }
    KingCooKit.wash(c, _panel, tone);
    c.drawPath(_panel, KingCooKit.line(edge, hair, edgeA));
    c.drawPath(_splits, KingCooKit.line(edge, hair * .8, far ? .26 : .34));
    c.drawPath(_rowA, KingCooKit.line(edge, hair * .85, far ? .26 : .36));
    c.drawPath(_bar1, KingCooKit.fill(barColor, far ? .8 : .95));
    c.drawPath(_bar2, KingCooKit.fill(barColor, far ? .8 : .95));

    // The alula.
    if (!far) {
      c.drawPath(
        _alula,
        KingCooKit.fill(
          tone.lit(
            Color.lerp(KingCooPalette.bar, KingCooPalette.featherDeep, .3)!,
          ),
        ),
      );
      c.drawPath(_alula, KingCooKit.line(edge, hair, .8));
    }

    // The moon's bounce on the edges that face it, the windows' glow on the
    // ones that face away (the house light, in screen space): the leading
    // edge and the feather tips, each lit by where it points ON SCREEN.
    final sky = tone.skyRim * (far ? .7 : 1), warm = (far ? 0.0 : tone.warmRim);
    final skyColor = tone.lit(tone.sky), wide = 1 + tone.dark * .5;
    final edgeSky = (-facing).clamp(0.0, 1.0),
        edgeWarm = facing.clamp(0.0, 1.0);
    if (sky * edgeSky > .02) {
      c.drawPath(
        _lead,
        KingCooKit.line(skyColor, .07 * px * wide, sky * edgeSky),
      );
    } else if (warm * edgeWarm > .02) {
      c.drawPath(
        _lead,
        KingCooKit.line(KingCooPalette.rimWarm, .06 * px, warm * edgeWarm * .8),
      );
    }
    // The fingers' visible sides face the trailing side: the moon when that
    // side faces it, the windows' glow when it faces away.
    final side = facing;
    if (side > 0 && sky * side > .02) {
      c.drawPath(
        _tips,
        KingCooKit.line(skyColor, .055 * px * wide, sky * side),
      );
    } else if (side < 0 && warm * -side > .02) {
      c.drawPath(
        _teRim,
        KingCooKit.line(KingCooPalette.rimWarm, .045 * px, warm * -side * .7),
      );
    }
    // One hard glint on the wrist, only where the moon reaches it.
    if (!far) {
      final a = (.85 * edgeSky * (1 - tone.washAlpha)).clamp(0.0, 1.0);
      if (a > .05) {
        c.drawPath(_glint, KingCooKit.line(KingCooPalette.white, .045 * px, a));
      }
    }
    c.restore();
  }
}
