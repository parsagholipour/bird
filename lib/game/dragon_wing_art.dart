import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'dragon_kit.dart';
import 'dragon_layout.dart';
import 'dragon_pose.dart';

/// One finger bone of a wing: a cubic from the wrist [a] to the bone tip [b]
/// through [c1] and [c2]. Every rib arches toward the leading edge (the lead
/// finger most) and comes down at its tip, so the claw that continues it
/// hooks back.
final class DragonFinger {
  const DragonFinger(this.a, this.c1, this.c2, this.b);
  final Offset a, c1, c2, b;

  /// The direction the bone is heading as it leaves its tip.
  Offset get heading => DragonKit.unit(b - c2);

  Offset at(double t) => DragonKit.bezier(a, c1, c2, b, t);
  Offset tangentAt(double t) =>
      DragonKit.unit(DragonKit.bezierTangent(a, c1, c2, b, t));
}

/// The side of a heading that faces the lead finger (up-left for a bone
/// pointing right).
Offset _lead(Offset d) => Offset(d.dy, -d.dx);

/// One of the Ember Dragon's wings as it stands this frame.
///
/// The joints come from [DragonLayout.wingAt] (the key poses, interpolated
/// joint by joint so the wrist lags the elbow and every finger lags the
/// wrist), then each tip is turned up about the wrist by its flex and the
/// trailing fingers are fanned open by the spread. The far wing is the near
/// wing's key transformed about its own shoulder ([DragonLayout.farOf]).
///
/// Nothing here leaves [DragonLayout.envelope]: the keys are BONE tips, the
/// claws stay inside [DragonLayout.clawAllowance] beyond them, and hem
/// flames are clamped to the box.
final class DragonWing {
  DragonWing._({
    required this.far,
    required this.shoulder,
    required this.root,
    required this.elbow,
    required this.wrist,
    required this.tips,
    required this.flex,
    required this.fold,
    required this.sag,
    required this.spread,
    required this.lead,
    required this.bob,
    required this.pitch,
  });

  /// The wing for one joint motion; [far] selects the far wing's transform.
  ///
  /// [bob] and [pitch] are the figure's own shift and turn (the rig applies
  /// them to everything it paints): the wing needs them to keep its tips and
  /// flames inside the envelope AS THE FRAME SEES THEM, since a nose-down
  /// pitch lifts the wings and the bob may lift them further. Without them
  /// the wing is laid out in the rig's own frame.
  factory DragonWing.of(
    DragonWingMotion m, {
    bool far = false,
    Offset bob = Offset.zero,
    double pitch = 0,
  }) {
    var k = DragonLayout.wingAt(
      elbow: m.elbow,
      wrist: m.wrist,
      tips: m.tips,
      fold: m.fold,
    );
    // Flex turns each tip up about the wrist; the spread fans the trailing
    // fingers down and back (the lead finger stays put).
    final tips = <Offset>[
      for (var i = 0; i < 4; i++)
        k.wrist +
            DragonKit.turn(
              k.tips[i] - k.wrist,
              -m.flex[i] + m.spread * .12 * i / 3,
            ),
    ];
    k = DragonWingKey(k.elbow, k.wrist, tips);
    if (far) {
      k = DragonLayout.farOf(k);
      // The far wing is not the near one's echo: its fan is a touch shorter
      // and opens wider, so its bones never run parallel to the near ones.
      final wr0 = k.wrist;
      k = DragonWingKey(k.elbow, wr0, [
        for (var i = 0; i < 4; i++)
          wr0 +
              DragonKit.turn(
                (k.tips[i] - wr0) * (1 - .05 * i / 3),
                _farOpen * i / 3,
              ),
      ]);
    }
    // Tips that the pose's pitch and bob would carry past the envelope's top
    // or right edge are drawn shorter along their own line (a whip trimmed
    // at the frame, not a wing squashed flat).
    final cp = math.cos(pitch), sp = math.sin(pitch);
    double poseX(Offset q) => bob.dx + q.dx * cp - q.dy * sp;
    double poseY(Offset q) => bob.dy + q.dx * sp + q.dy * cp;
    final wr = k.wrist;
    final top = DragonLayout.envelope.top + _tipTopInset;
    final right = DragonLayout.envelope.right - _tipRightInset;
    final tamed = <Offset>[
      for (final t in k.tips)
        () {
          var f = 1.0;
          final wy = poseY(wr), ty = poseY(t);
          if (ty < top && wy > ty) f = math.min(f, (wy - top) / (wy - ty));
          final wx = poseX(wr), tx = poseX(t);
          if (tx > right && tx > wx) f = math.min(f, (right - wx) / (tx - wx));
          return f >= 1 ? t : wr + (t - wr) * math.max(f, .5);
        }(),
    ];
    k = DragonWingKey(k.elbow, k.wrist, tamed);
    return DragonWing._(
      far: far,
      shoulder: far
          ? DragonLayout.farShoulder + _farShoulderShift
          : DragonLayout.nearShoulder,
      root: far ? DragonLayout.farRoot : DragonLayout.nearRoot,
      elbow: k.elbow,
      wrist: k.wrist,
      tips: k.tips,
      flex: m.flex,
      fold: m.fold,
      sag: m.sag,
      spread: m.spread,
      lead: m.elbow - m.wrist,
      bob: bob,
      pitch: pitch,
    );
  }

  // A bone tip stays this far inside the envelope's top and right edge (in
  // the frame's own space): its claw and ink reach the rest of the way.
  static const _tipTopInset = .10, _tipRightInset = .23;

  /// The figure's shift and turn this frame (see [DragonWing.of]).
  final Offset bob;
  final double pitch;

  /// [q] (a point in the rig's frame) as the frame sees it: turned by the
  /// pitch, then shifted by the bob.
  Offset inFrame(Offset q) {
    final c = math.cos(pitch), s = math.sin(pitch);
    return bob + Offset(q.dx * c - q.dy * s, q.dx * s + q.dy * c);
  }

  /// The near wing for [pose]. EVERY wing implementation keeps these two
  /// factories: the rig builds nothing but `DragonWing.nearOf(pose)` and
  /// `DragonWing.farOf(pose)`.
  factory DragonWing.nearOf(DragonPose pose) =>
      DragonWing.of(pose.nearWing, bob: pose.bob, pitch: pose.pitch);

  /// The far wing for [pose]: a phase behind the near one, smaller, tilted.
  factory DragonWing.farOf(DragonPose pose) =>
      DragonWing.of(pose.farWing, far: true, bob: pose.bob, pitch: pose.pitch);

  /// The far wing sits behind the body and is drawn in shade.
  final bool far;

  /// Shoulder and the flank anchor of the membrane, in rig units.
  final Offset shoulder, root;

  /// The joints after flex and spread: elbow, wrist, four BONE tips.
  final Offset elbow, wrist;
  final List<Offset> tips;

  /// Radians each tip trails up, defeat fold, hem sag, fan spread.
  final List<double> flex;
  final double fold, sag, spread;

  /// How far the elbow's stroke runs ahead of the wrist's (it drives the
  /// beat), -2..2: the elbow bulges back a little more while it leads.
  final double lead;

  // How much wider the far wing's fan opens than the near one's (radians at
  // the last finger).
  static const _farOpen = .1;

  /// The far shoulder, behind the neck's back, stands .15 farther from the
  /// head than the layout's pivot (round 3 moved both shoulders toward the
  /// neck): the skull's cheek spike and the great horn then keep .44 (calm,
  /// limit .30) and .25 (head-up, limit .19) from the far arm, and .74 u2 of
  /// far wing still shows past the near one at the worst phase.
  static const _farShoulderShift = Offset(.15, 0);

  /// Where the arm bends when it is drawn: the middle of the shoulder to
  /// wrist line pushed back toward the tail, so the upper arm and the forearm
  /// are about as long as each other and the elbow points back and out (the
  /// validated bend of the design review, which puts the layout's mid elbow
  /// at (1.80, -1.44)). Derived from the shoulder and the wrist alone, so the
  /// drawn arm follows the wrist and never stretches, whatever the layout's
  /// own elbow key.
  late final Offset joint = () {
    final chord = wrist - shoulder;
    final d = DragonKit.unit(chord);
    final back = Offset(-d.dy, d.dx);
    final bend =
        chord.distance * (far ? .1 : .17) * (1 + lead.clamp(-1.0, 1.0) * .5);
    return Offset.lerp(shoulder, wrist, far ? .54 : .5)! + back * bend;
  }();

  // How much each rib arches toward the leading edge, as a share of its
  // length: the lead finger reads as the wing's bold arch.
  static const _arch = [.115, .06, .035, .02];

  /// The four finger bones.
  late final List<DragonFinger> fingers = _buildFingers();

  List<DragonFinger> _buildFingers() {
    final out = <DragonFinger>[];
    for (var i = 0; i < 4; i++) {
      final chord = tips[i] - wrist;
      final len = chord.distance;
      final n = _lead(DragonKit.unit(chord));
      // A tip that trails up (flex) leaves the middle of the bone bowed the
      // other way, like a whip under load.
      final bow = (_arch[i] * (1 - fold) - flex[i] * .3) * len;
      out.add(
        DragonFinger(
          wrist,
          wrist + chord * .3 + n * bow,
          wrist + chord * .72 + n * (bow * .85),
          tips[i],
        ),
      );
    }
    return out;
  }

  /// How deep the scallop between tips [i] and [i]+1 dips (the last one runs
  /// from the fourth tip to the flank): a third of the span, plus the sag.
  double hemDepth(int i) {
    final span = ((i < 3 ? tips[i + 1] : root) - tips[i]).distance;
    final g = DragonWingArt.grown;
    return (span * .34).clamp(.16 * g, .55 * g) + .1 * sag + (far ? .05 : 0);
  }

  /// The two control points of the hem cubic that leaves tip [i]: it sets
  /// off back down its own finger (so every membrane tip is a needle along
  /// its bone) and comes into the next tip the same way.
  (Offset, Offset) hemControls(int i) {
    final k = hemDepth(i) * 1.4;
    final a = tips[i] - fingers[i].heading * k;
    if (i < 3) {
      return (a, tips[i + 1] - fingers[i + 1].heading * k);
    }
    // The last scallop ends on the flank: it comes in from the wrist's side.
    return (a, root + DragonKit.unit(wrist - root) * (hemDepth(i) * 1.2));
  }

  /// Point [t] of hem [i], from tip [i] toward the next tip (or the root).
  Offset hemAt(int i, double t) {
    final (p1, p2) = hemControls(i);
    return DragonKit.bezier(tips[i], p1, p2, i < 3 ? tips[i + 1] : root, t);
  }
}

/// Paints the Ember Dragon's wings.
abstract final class DragonWingArt {
  static const _ink = DragonPalette.ink;

  /// The longest finger (wrist to bone tip) over the three key poses. Every
  /// size in the wing that should grow with it (the membrane's radial, the
  /// scallops, the bones' gradient) is derived from this, so a layout that
  /// gives the wings more reach makes a proportionally bigger, not a
  /// stretched, wing. 3.05 was the reach the sizes were first drawn for.
  static final double reach = () {
    var r = 0.0;
    for (final k in [
      DragonLayout.wingUp,
      DragonLayout.wingMid,
      DragonLayout.wingDown,
    ]) {
      for (final t in k.tips) {
        r = math.max(r, (t - k.wrist).distance);
      }
    }
    return r;
  }();

  /// [reach] against the reach the wing was first drawn for.
  static final double grown = reach / 3.05;

  /// Flames stop this far inside the envelope's right edge and top: a tongue
  /// on the frame's edge reads as a crop.
  static final double flameRight = DragonLayout.envelope.right - .48;
  static final double flameTop = DragonLayout.envelope.top + .32;

  // Scratch paths, reset and refilled every wing: nothing here allocates
  // per frame. Membrane paths are built in "wing space" (the wrist at the
  // origin) so its radial shader is cached and drawn under a translate.
  static final Path _mem = Path(),
      _hem = Path(),
      _sleeveA = Path(),
      _sleeveB = Path(),
      _veins = Path(),
      _bones = Path(),
      _ridge = Path(),
      _claws = Path(),
      _limb = Path(),
      _scales = Path(),
      _flames = Path(),
      _glints = Path(),
      _dots = Path();

  // --------------------------------------------------------------- paint --

  /// Draws [wing] lit by [tone]. [time] animates the fury flames along the
  /// hems (0 holds them still).
  static void paint(Canvas c, DragonWing wing, DragonTone tone, double time) {
    final heat = math.max(tone.fury, tone.heat * .7);
    _membrane(c, wing, tone, heat);
    if (tone.fury > 0) _hemFlames(c, wing, tone, time);
    _fingerBones(c, wing, tone);
    _clawsAndSpurs(c, wing, tone);
    _limbArt(c, wing, tone);
  }

  // ------------------------------------------------------------ membrane --

  static void _membrane(Canvas c, DragonWing w, DragonTone tone, double heat) {
    final far = w.far;
    final o = w.wrist;
    Offset q(Offset v) => v - o;

    // The whole membrane: down finger 0, along the four hems, back along the
    // flank to the shoulder, elbow and wrist. The arm covers its inner edge.
    final f0 = w.fingers[0];
    _mem
      ..reset()
      ..moveTo(0, 0)
      ..cubicTo(
        q(f0.c1).dx,
        q(f0.c1).dy,
        q(f0.c2).dx,
        q(f0.c2).dy,
        q(f0.b).dx,
        q(f0.b).dy,
      );
    _hem.reset();
    _hem.moveTo(q(w.tips[0]).dx, q(w.tips[0]).dy);
    for (var i = 0; i < 4; i++) {
      final (p1, p2) = w.hemControls(i);
      final end = q(i < 3 ? w.tips[i + 1] : w.root);
      _hem.cubicTo(q(p1).dx, q(p1).dy, q(p2).dx, q(p2).dy, end.dx, end.dy);
      _mem.cubicTo(q(p1).dx, q(p1).dy, q(p2).dx, q(p2).dy, end.dx, end.dy);
    }
    _mem
      ..lineTo(q(w.shoulder).dx, q(w.shoulder).dy)
      ..lineTo(q(w.joint).dx, q(w.joint).dy)
      ..close();

    c.save();
    c.translate(o.dx, o.dy);
    c.drawPath(_mem, _membranePaint(tone, far));

    // Inside the membrane: light through skin beside every bone, veins,
    // heat, and the darker hem band that gives the edge its curl.
    c.save();
    c.clipPath(_mem, doAntiAlias: false);
    _sleeves(w);
    final k = far ? .7 : 1.0;
    // Between the bones the skin billows away from the light and shades.
    _valleys(c, w, tone);
    // Light comes through the skin beside every bone.
    final glow = tone.burn(
      DragonPalette.membraneGlow,
      DragonPalette.flameYellow,
    );
    c.drawPath(_sleeveA, DragonKit.fill(glow, (.2 + .3 * heat) * k));
    c.drawPath(_sleeveB, DragonKit.fill(glow, (.24 + .24 * heat) * k));
    _veinPath(w);
    // The veins carry the fire when it rises: dark skin lines that glow.
    c.drawPath(
      _veins,
      DragonKit.fill(
        tone.lit(
          Color.lerp(
            DragonPalette.membraneDeep,
            DragonPalette.seamHot,
            (heat * .9).clamp(0.0, 1.0),
          )!,
        ),
        (far ? .4 : .55) + heat * .35,
      ),
    );
    if (heat > .05) {
      // The fire rising inside blooms in the skin: gold, with a white-hot
      // heart between the fingers.
      final centre = q(Offset.lerp(w.wrist, w.tips[2], .5)!);
      final reach = (w.tips[2] - w.wrist).distance;
      _bloom(
        c,
        centre,
        reach * .9,
        DragonPalette.flameGold,
        heat * (far ? .4 : .82),
      );
      if (!far) {
        _bloom(c, centre, reach * .42, DragonPalette.flameCore, heat * .65);
      }
    }
    final band = tone.burn(DragonPalette.membraneDark, DragonPalette.flameDark);
    c.drawPath(_hem, DragonKit.line(band, .5, far ? .16 : .22));
    c.drawPath(_hem, DragonKit.line(band, .27, far ? .8 : .9));
    // The skin's thickness: a bright lip just inside the dark band.
    c.save();
    c.translate(-.085, -.07);
    c.drawPath(
      _hem,
      DragonKit.line(
        tone.burn(DragonPalette.membraneLit, DragonPalette.flameGold),
        .045,
        far ? .3 : .6,
      ),
    );
    c.restore();
    c.restore();
    DragonKit.inkHero(
      c,
      _hem,
      far ? DragonLayout.inkMajor : DragonLayout.inkHero,
    );
    c.restore();
  }

  static Paint _membranePaint(DragonTone tone, bool far) => DragonKit.cached(
    ('wing.membrane', far, (tone.flash * 8).round(), (tone.fury * 8).round()),
    () => DragonKit.membrane(
      Offset.zero,
      (far ? .875 : 1.05) * reach,
      DragonTone(
        flash: (tone.flash * 8).round() / 8,
        fury: (tone.fury * 8).round() / 8,
      ),
      far: far,
    ),
  );

  /// A soft round glow of [color] at [at], like `DragonKit.glow` but from a
  /// cached unit gradient (alpha in sixteenths, so a pure function of it).
  static void _bloom(Canvas c, Offset at, double r, Color color, double alpha) {
    final q = (alpha.clamp(0.0, 1.0) * 16).round();
    if (q == 0) return;
    final paint = DragonKit.cached(('wing.bloom', color, q), () {
      final a = q / 16;
      return DragonKit.radial(
        Offset.zero,
        1,
        [
          color.withValues(alpha: a),
          color.withValues(alpha: a * .38),
          color.withValues(alpha: 0),
        ],
        const [0, .45, 1],
      );
    });
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    c.drawCircle(Offset.zero, 1, paint);
    c.restore();
  }

  /// A soft dark hollow down the middle of every panel, drawn with one cached
  /// unit radial gradient under a transform (no shader is built per frame).
  ///
  /// KIT-REQUEST: a `DragonKit.softBlob(c, at, angle, rx, ry, paintKey)` that
  /// draws a cached unit radial under a transform would let every part shade
  /// without building a shader per frame; until then it lives here.
  static void _valleys(Canvas c, DragonWing w, DragonTone tone) {
    final paint = _softPaint(tone, w.far);
    final o = w.wrist;
    for (var i = 0; i < 4; i++) {
      final apex = w.hemAt(i, .5) - o;
      final reach = apex.distance;
      final chord = ((i < 3 ? w.tips[i + 1] : w.root) - w.tips[i]).distance;
      final centre = apex * .52;
      c.save();
      c.translate(centre.dx, centre.dy);
      c.rotate(math.atan2(apex.dy, apex.dx));
      c.scale(reach * .36, (chord * .2).clamp(.12, .42));
      c.drawCircle(Offset.zero, 1, paint);
      c.restore();
    }
    // Where the skin drapes onto the flank it turns into the body's shadow.
    final to = w.root - w.shoulder;
    final centre = Offset.lerp(w.shoulder, w.root, .5)! - o;
    c.save();
    c.translate(centre.dx, centre.dy);
    c.rotate(math.atan2(to.dy, to.dx));
    c.scale(to.distance * .5, .3);
    c.drawCircle(Offset.zero, 1, paint);
    c.restore();
  }

  static Paint _softPaint(DragonTone tone, bool far) => DragonKit.cached(
    ('wing.soft', far, (tone.flash * 8).round(), (tone.fury * 8).round()),
    () {
      final t = DragonTone(
        flash: (tone.flash * 8).round() / 8,
        fury: (tone.fury * 8).round() / 8,
      );
      var col = t.burn(DragonPalette.membraneDeep, DragonPalette.flameDark);
      if (far) col = DragonKit.shade(col, .74);
      return DragonKit.radial(
        Offset.zero,
        1,
        [
          col.withValues(alpha: .58),
          col.withValues(alpha: .28),
          col.withValues(alpha: 0),
        ],
        const [0, .55, 1],
      );
    },
  );

  /// Nested light wedges under every finger, wide at the wrist and narrowing
  /// to the tip: fire seen through skin beside the bone.
  static void _sleeves(DragonWing w) {
    _sleeveA.reset();
    _sleeveB.reset();
    final o = w.wrist;
    for (var i = 0; i < 4; i++) {
      final f = w.fingers[i];
      final s = 1 - i * .08;
      _taper(_sleeveA, f, .3 * s, .02, o);
      _taper(_sleeveB, f, .17 * s, .015, o);
    }
  }

  /// Veins and creases: thin brush-stroke lenses fanning from every finger
  /// toward its hem, and one crease down the middle of each panel.
  static void _veinPath(DragonWing w) {
    _veins.reset();
    final o = w.wrist;
    for (var i = 0; i < 4; i++) {
      final f = w.fingers[i];
      for (final (s, u) in const [(.3, .3), (.52, .68)]) {
        final from = f.at(s) - o;
        final hem = w.hemAt(i, u);
        final to = Offset.lerp(hem, w.wrist, .3)! - o;
        _lens(_veins, from, to, .05, .017);
      }
      // The crease where the panel folds away from the light.
      final apex = w.hemAt(i, .5) - o;
      _lens(
        _veins,
        apex * .12,
        Offset.lerp(Offset.zero, apex, .82)!,
        -.05,
        .03,
      );
    }
  }

  /// A brush-stroke lens from [a] to [b], bowed by [bow] and [w] thick at the
  /// middle, tapering to points at both ends.
  static void _lens(Path p, Offset a, Offset b, double bow, double w) {
    final n = _lead(DragonKit.unit(b - a));
    final mid = Offset.lerp(a, b, .5)! + n * bow;
    final up = mid + n * w, down = mid - n * w;
    p
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(up.dx, up.dy, b.dx, b.dy)
      ..quadraticBezierTo(down.dx, down.dy, a.dx, a.dy)
      ..close();
  }

  // --------------------------------------------------------------- bones --

  static void _fingerBones(Canvas c, DragonWing w, DragonTone tone) {
    _bones.reset();
    _ridge.reset();
    _dots.reset();
    for (var i = 0; i < 4; i++) {
      final f = w.fingers[i];
      final h0 = (w.far ? .066 : .078) - i * .006, h1 = w.far ? .024 : .028;
      _taper(_bones, f, h0, h1);
      // A knuckle where the bone bends, and the lit ridge on its leading side.
      final j = f.at(.5);
      final jr = (h0 * .85).clamp(.05, .12);
      _bones.addOval(Rect.fromCircle(center: j, radius: jr));
      _dots.addOval(
        Rect.fromCircle(
          center: j + const Offset(-.02, -.025),
          radius: jr * .42,
        ),
      );
      final from = f.at(.1) + _lead(f.tangentAt(.1)) * h0 * .45;
      final mid = f.at(.42) + _lead(f.tangentAt(.42)) * h0 * .38;
      final to = f.at(.8) + _lead(f.tangentAt(.8)) * h0 * .2;
      _ridge
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(
          mid.dx * 2 - (from.dx + to.dx) / 2,
          mid.dy * 2 - (from.dy + to.dy) / 2,
          to.dx,
          to.dy,
        );
    }
    c.drawPath(_bones, DragonKit.line(_ink, w.far ? .06 : .07));
    c.drawPath(_bones, _fingerPaint(tone, w.far));
    c.drawPath(
      _ridge,
      DragonKit.line(
        tone.lit(DragonPalette.scaleSheen),
        DragonLayout.hair * 1.15,
        w.far ? .3 : .7,
      ),
    );
    c.drawPath(
      _dots,
      DragonKit.fill(tone.lit(DragonPalette.scaleSheen), w.far ? .25 : .65),
    );
    if (!w.far) {
      // The sky's bounce along the wing's leading edge.
      _ridge.reset();
      final f = w.fingers[0];
      _taper(_ridge, f, .018, .01, Offset.zero, .062, .022);
      c.drawPath(_ridge, DragonKit.fill(tone.lit(tone.sky), tone.skyRim));
    }
  }

  static Paint _fingerPaint(DragonTone tone, bool far) => DragonKit.cached(
    (
      'wing.finger',
      far,
      (tone.flash * 8).round(),
      (tone.fury * 8).round(),
      (tone.dark * 4).round(),
    ),
    () {
      final t = _quantised(tone);
      Color f(Color v) =>
          far ? DragonKit.shade(t.plate(v), _farShade) : t.plate(v);
      // The bones' light runs from the upper left of the wing's box to its
      // lower right, so every finger shades the same way.
      final up = DragonLayout.wingUp, mid = DragonLayout.wingMid;
      final top = math.min(up.tips[0].dy, mid.tips[0].dy);
      final right = math.max(mid.tips[1].dx, mid.tips[0].dx);
      return DragonKit.linear(
        Offset(mid.wrist.dx - .75, top - .1),
        Offset(right - .55, mid.tips[3].dy + .15),
        [
          f(DragonPalette.scale),
          f(DragonPalette.scaleDeep),
          f(DragonPalette.scaleDark),
        ],
        const [0, .55, 1],
      );
    },
  );

  // ------------------------------------------------------ claws & spurs --

  static void _clawsAndSpurs(Canvas c, DragonWing w, DragonTone tone) {
    _claws.reset();
    for (var i = 0; i < 4; i++) {
      final f = w.fingers[i];
      final d = f.heading;
      _claw(_claws, f.b - d * .02, d, -_lead(d), i == 0 ? .2 : .17, .045);
    }
    // The thumb: a hook on the wrist's leading side (the far wing's is
    // hidden behind the near wrist and stays off the head).
    if (!w.far) {
      final thumb = DragonKit.unit(DragonLayout.thumbOffset);
      _claw(
        _claws,
        w.wrist + thumb * .1,
        thumb,
        Offset(thumb.dy, -thumb.dx),
        .32,
        .06,
      );
    }
    // The elbow spur juts back into the membrane.
    final arm = DragonKit.unit(w.joint - w.shoulder);
    final back = Offset(-arm.dy, arm.dx);
    final spur = DragonKit.unit(back * .8 + arm * .45);
    final k = w.far ? .8 : 1.0;
    _claw(
      _claws,
      w.joint + back * (_elbowR * k * .6),
      spur,
      DragonKit.unit(w.wrist - w.joint),
      .3 * k,
      .07 * k,
    );
    c.drawPath(
      _claws,
      DragonKit.fill(
        w.far
            ? DragonKit.shade(tone.lit(DragonPalette.boneDeep), .74)
            : tone.lit(DragonPalette.bone),
      ),
    );
    c.drawPath(_claws, DragonKit.line(_ink, DragonLayout.inkPart * .85));
  }

  /// A curved thorn from [base] growing along [dir], hooking toward [side]:
  /// [len] long and [w] wide at the root.
  static void _claw(
    Path p,
    Offset base,
    Offset dir,
    Offset side,
    double len,
    double w,
  ) {
    Offset at(double x, double y) => base + dir * x + side * y;
    final tip = at(len * .82, len * .5);
    final a = at(0, -w), b = at(0, w);
    final outer = at(len * .92, -w * .35);
    final inner = at(len * .36, len * .18);
    p
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(outer.dx, outer.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(inner.dx, inner.dy, b.dx, b.dy)
      ..close();
  }

  // ----------------------------------------------------------------- arm --

  // The arm is bone under skin, not a pipe: a deltoid that swells out of the
  // shoulder and pinches to a sinew by the middle of the upper arm, a knot at
  // the elbow, a slim forearm and a small wrist knuckle. Half-widths at
  // (fraction along the segment, half-width).
  static const _upperProfile = [
    (0.0, .2),
    (.14, .205),
    (.34, .142),
    (.55, .102),
    (.78, .088),
    (1.0, .098),
  ];
  static const _foreProfile = [
    (0.0, .098),
    (.35, .078),
    (.75, .066),
    (1.0, .07),
  ];
  static const _elbowR = .105, _wristR = .078;
  static const _samples = 9;

  // The outline samples of the arm, kept for the strips laid along it.
  static final List<Offset> _uc = List.filled(_samples + 1, Offset.zero),
      _un = List.filled(_samples + 1, Offset.zero),
      _fc = List.filled(_samples + 1, Offset.zero),
      _fn = List.filled(_samples + 1, Offset.zero);
  static final List<double> _uh = List.filled(_samples + 1, 0),
      _fh = List.filled(_samples + 1, 0);

  static double _along(List<(double, double)> profile, double t) {
    for (var i = 1; i < profile.length; i++) {
      if (t <= profile[i].$1) {
        final (t0, h0) = profile[i - 1];
        final (t1, h1) = profile[i];
        final u = (t - t0) / (t1 - t0);
        return h0 + (h1 - h0) * u * u * (3 - 2 * u);
      }
    }
    return profile.last.$2;
  }

  /// Samples [f] into [c] (centre), [n] (leading normal) and [h] (half-width
  /// from [profile] times [k]).
  static void _sample(
    DragonFinger f,
    List<(double, double)> profile,
    double k,
    List<Offset> c,
    List<Offset> n,
    List<double> h,
  ) {
    for (var i = 0; i <= _samples; i++) {
      final t = i / _samples;
      c[i] = f.at(t);
      n[i] = _lead(f.tangentAt(t));
      h[i] = _along(profile, t) * k;
    }
  }

  /// The outline of one arm segment into [p]: down the leading side, back up
  /// the trailing side, closed with a round cap at the start if [cap].
  static void _outline(
    Path p,
    List<Offset> c,
    List<Offset> n,
    List<double> h, {
    required bool cap,
  }) {
    final pts = <Offset>[
      for (var i = 0; i <= _samples; i++) c[i] + n[i] * h[i],
      for (var i = _samples; i >= 0; i--) c[i] - n[i] * h[i],
    ];
    if (cap) {
      // Round the shoulder end: swing round the back of the start point.
      final back = Offset(n[0].dy, -n[0].dx);
      for (final a in const [.5, 1.05, 1.57, 2.09, 2.64]) {
        pts.add(
          c[0] - n[0] * (h[0] * math.cos(a)) + back * (h[0] * math.sin(a)),
        );
      }
    }
    DragonKit.spline(pts, sharp: {_samples, _samples + 1}, into: p);
  }

  /// A strip along the arm between [a] and [b] of its half-width (1 is the
  /// leading edge, -1 the trailing), pinched to nothing at both ends, so it
  /// never ends in a hard cut.
  static void _sliver(
    Path p,
    List<Offset> c,
    List<Offset> n,
    List<double> h,
    double a,
    double b,
  ) {
    final pts = <Offset>[];
    final inner = <Offset>[];
    for (var i = 1; i < _samples; i++) {
      final pinch = math.sin(math.pi * i / _samples);
      final mid = (a + b) / 2, half = (b - a) / 2 * pinch;
      pts.add(c[i] + n[i] * (h[i] * (mid + half)));
      inner.add(c[i] + n[i] * (h[i] * (mid - half)));
    }
    DragonKit.spline([...pts, ...inner.reversed], into: p);
  }

  static void _limbArt(Canvas c, DragonWing w, DragonTone tone) {
    final far = w.far;
    final s = w.shoulder, e = w.joint, r = w.wrist;
    final k = far ? .8 : 1.0;
    final nUp = _lead(DragonKit.unit(e - s));
    final nLow = _lead(DragonKit.unit(r - e));
    // Upper arm and forearm as gently bowed bones: the upper arm's muscle
    // swells on its leading side, the forearm hollows a little.
    final upper = DragonFinger(
      s,
      s + (e - s) * .3 + nUp * .05,
      s + (e - s) * .72 + nUp * .03,
      e,
    );
    final fore = DragonFinger(
      e,
      e + (r - e) * .33 - nLow * .015,
      e + (r - e) * .7 - nLow * .012,
      r,
    );
    _sample(upper, _upperProfile, k, _uc, _un, _uh);
    _sample(fore, _foreProfile, k, _fc, _fn, _fh);
    _limb.reset();
    _outline(_limb, _uc, _un, _uh, cap: true);
    _outline(_limb, _fc, _fn, _fh, cap: false);
    // The elbow's knot sits on its outer (back) side; the wrist knuckle is
    // barely wider than the bone.
    _limb.addOval(
      Rect.fromCircle(
        center: e - nUp * (_elbowR * k * .35),
        radius: _elbowR * k,
      ),
    );
    _limb.addOval(Rect.fromCircle(center: r, radius: _wristR * k));
    c.drawPath(_limb, DragonKit.line(_ink, far ? .1 : .12));
    c.drawPath(_limb, _limbPaint(tone, far));

    // Form: light down the leading side, shade down the trailing side; both
    // are slivers pinched to nothing at their ends.
    Color plate(Color v) {
      final t = tone.plate(v);
      return far ? DragonKit.shade(t, _farShade) : t;
    }

    _scales.reset();
    _sliver(_scales, _uc, _un, _uh, .18, .78);
    _sliver(_scales, _fc, _fn, _fh, .1, .7);
    c.drawPath(
      _scales,
      DragonKit.fill(plate(DragonPalette.scaleLit), far ? .0 : .7),
    );
    _scales.reset();
    _sliver(_scales, _uc, _un, _uh, -.95, -.2);
    _sliver(_scales, _fc, _fn, _fh, -.9, -.2);
    c.drawPath(
      _scales,
      DragonKit.fill(plate(DragonPalette.scaleDark), far ? .6 : .65),
    );

    // Plate rings across the muscle, in the mid-tone only.
    _scales.reset();
    for (final i in const [3, 5, 7]) {
      final ctr = _uc[i], nn = _un[i], hh = _uh[i] * .9;
      final d = Offset(nn.dy, -nn.dx);
      final tip = ctr + d * (hh * 1.1);
      _scales
        ..moveTo(ctr.dx + nn.dx * hh, ctr.dy + nn.dy * hh)
        ..quadraticBezierTo(
          tip.dx,
          tip.dy,
          ctr.dx - nn.dx * hh,
          ctr.dy - nn.dy * hh,
        );
    }
    c.drawPath(
      _scales,
      DragonKit.line(
        DragonPalette.inkCool,
        DragonLayout.inkDetail,
        far ? .4 : .7,
      ),
    );
    // Fury runs molten through the plate rings.
    if (tone.fury > .05) {
      DragonKit.moltenSeam(c, _scales, tone, width: .05, alpha: tone.fury);
    }

    if (!far) {
      // The sky's bounce along the leading edge and the fire's along the
      // underside, as pinched slivers inside the ink.
      _scales.reset();
      _sliver(_scales, _uc, _un, _uh, .8, .96);
      _sliver(_scales, _fc, _fn, _fh, .76, .95);
      c.drawPath(_scales, DragonKit.fill(tone.lit(tone.sky), tone.skyRim));
      _scales.reset();
      _sliver(_scales, _uc, _un, _uh, -.96, -.8);
      _sliver(_scales, _fc, _fn, _fh, -.95, -.76);
      c.drawPath(
        _scales,
        DragonKit.fill(tone.lit(DragonPalette.rimFire), tone.fireRim * .8),
      );
      // Hard pill glints, like the roster's other domes: on the deltoid, on
      // the elbow's knot and along the lead finger's first span.
      _glints.reset();
      final g = _uc[1] + _un[1] * (_uh[1] * .45);
      final gd = DragonKit.unit(
        _un[1] * .8 + Offset(_un[1].dy, -_un[1].dx) * -.6,
      );
      _glints
        ..moveTo(g.dx - gd.dx * .06, g.dy - gd.dy * .06)
        ..lineTo(g.dx + gd.dx * .06, g.dy + gd.dy * .06);
      final ek =
          e + Offset(-nUp.dx, -nUp.dy) * 0 + _un[_samples] * (_elbowR * .35);
      _glints
        ..moveTo(ek.dx - .015, ek.dy - .035)
        ..lineTo(ek.dx + .005, ek.dy - .01);
      final lf = w.fingers[0];
      final l0 = lf.at(.16) + _lead(lf.tangentAt(.16)) * .012;
      final l1 = lf.at(.27) + _lead(lf.tangentAt(.27)) * .012;
      _glints
        ..moveTo(l0.dx, l0.dy)
        ..lineTo(l1.dx, l1.dy);
      c.drawPath(
        _glints,
        DragonKit.line(DragonPalette.white, .05, tone.flash > 0 ? .35 : .7),
      );
      // The wrist knuckle's highlight.
      c.drawCircle(
        r + const Offset(-.025, -.03),
        .022,
        DragonKit.fill(tone.lit(DragonPalette.scaleSheen), .8),
      );
    }
  }

  static const _farShade = .6;

  static Paint _limbPaint(DragonTone tone, bool far) => DragonKit.cached(
    (
      'wing.limb',
      far,
      (tone.flash * 8).round(),
      (tone.fury * 8).round(),
      (tone.dark * 4).round(),
    ),
    () {
      final t = _quantised(tone);
      Color f(Color v) =>
          far ? DragonKit.shade(t.plate(v), _farShade) : t.plate(v);
      // The dome of the shoulder catches the sky at its upper left.
      final s = DragonLayout.nearShoulder;
      return DragonKit.linear(
        s + const Offset(-.5, -.8),
        s + const Offset(1.1, .5),
        [
          f(DragonPalette.scaleLit),
          f(DragonPalette.scale),
          f(DragonPalette.scale),
        ],
        const [0, .42, 1],
      );
    },
  );

  // -------------------------------------------------------------- flames --

  /// Fury sets the hems alight: licks of flame rooted on every scallop, four
  /// layers deep (ember red, orange, gold, white-hot), all leaning back and
  /// up as if in one wind, pressed down near the ceiling and clamped so they
  /// never leave the envelope. Each lobe carries a tall lick and a short one.
  // Flames stop well short of the frame's right edge (the envelope ends at
  // 4.30, the screen at 4.35): a tongue on the edge reads as a crop.

  static void _hemFlames(Canvas c, DragonWing w, DragonTone tone, double time) {
    final k = tone.fury * (w.far ? .75 : 1);
    for (var pass = 0; pass < 4; pass++) {
      final color = switch (pass) {
        0 => DragonPalette.flameDark,
        1 => DragonPalette.flame,
        2 => DragonPalette.flameGold,
        _ => DragonPalette.flameCore,
      };
      // (width, height) of this layer against the outermost one.
      final (wide, tall) = switch (pass) {
        0 => (1.0, 1.0),
        1 => (.76, .84),
        2 => (.52, .64),
        _ => (.3, .4),
      };
      _flames.reset();
      var n = 0;
      for (var i = 0; i < 4; i++) {
        final lobes = i < 3 ? 4 : 3;
        for (var l = 0; l < lobes; l++) {
          final t0 = l / lobes, t1 = (l + 1) / lobes, dt = t1 - t0;
          final mid = w.hemAt(i, (t0 + t1) / 2);
          var out = _lead(DragonKit.unit(w.hemAt(i, t1) - w.hemAt(i, t0)));
          final away = mid - (i < 3 ? w.wrist : w.joint);
          if (away.dx * out.dx + away.dy * out.dy < 0) out = -out;
          // All the fire leans one way, back and up, like a wind on it.
          // Toward the frame's edge there is no room to stream outward, so
          // the fire climbs instead.
          final room = ((flameRight - .15 - mid.dx) / .5).clamp(.2, .8);
          var up = DragonKit.unit(
            out * room + const Offset(.15, -1) * (1 - room * .35),
          );
          // Near the ceiling the tongues are pressed down and back.
          final press = ((mid.dy + 3.2) / 1.0).clamp(0.0, 1.0);
          up = DragonKit.unit(up + Offset(.1, DragonKit.mix(.9, 0, press)));
          final side = Offset(-up.dy, up.dx);
          for (final (from, to, share, lean) in const [
            (0.0, .76, 1.0, 1.0),
            (.68, 1.0, .5, -.7),
          ]) {
            final ta = t0 + dt * from, tb = t0 + dt * to;
            final lick = time == 0
                ? .68
                : .62 +
                      .38 *
                          math.sin(time * 9 + n * 1.9 + DragonKit.hash(n) * 6);
            final height =
                (.62 + DragonKit.hash(n, 3) * .6) * lick * share * tall;
            final sway =
                (time == 0 ? .16 : .16 + math.sin(time * 6.3 + n * 2.1) * .12) *
                lean;
            final base = w.hemAt(i, (ta + tb) / 2);
            var tip = base + up * height + side * (sway * height);
            // Never past the envelope's ceiling or right edge, as the frame
            // sees the tongue (the figure's pitch and bob included).
            var shrink = 1.0;
            final fb = w.inFrame(base), ft = w.inFrame(tip);
            if (ft.dy < flameTop && fb.dy > ft.dy) {
              shrink = math.min(
                shrink,
                math.max(0.0, (fb.dy - flameTop) / (fb.dy - ft.dy)),
              );
            }
            if (ft.dx > flameRight && ft.dx > fb.dx) {
              shrink = math.min(
                shrink,
                math.max(0.0, (flameRight - fb.dx) / (ft.dx - fb.dx)),
              );
            }
            tip = base + (tip - base) * shrink;
            final rise = tip - base;
            if (rise.distance < .14 * tall) {
              n++;
              continue;
            }
            final a = w.hemAt(i, ta + (tb - ta) * (1 - wide) / 2) - out * .07;
            final b = w.hemAt(i, tb - (tb - ta) * (1 - wide) / 2) - out * .07;
            final curl = side * (height * shrink * sway);
            final c1 = a + rise * .5 + curl * .55;
            final c2 = tip - rise * .36 - curl * 1.1;
            final c3 = tip - rise * .3 - curl * .3;
            final c4 = b + rise * .4 + curl * .25;
            // Every lick winds the same way, so overlapping ones merge under
            // the non-zero fill instead of cancelling into holes.
            final turnsRight =
                (b.dx - a.dx) * (tip.dy - a.dy) -
                    (b.dy - a.dy) * (tip.dx - a.dx) >
                0;
            if (turnsRight) {
              _flames
                ..moveTo(a.dx, a.dy)
                ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tip.dx, tip.dy)
                ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, b.dx, b.dy)
                ..close();
            } else {
              _flames
                ..moveTo(b.dx, b.dy)
                ..cubicTo(c4.dx, c4.dy, c3.dx, c3.dy, tip.dx, tip.dy)
                ..cubicTo(c2.dx, c2.dy, c1.dx, c1.dy, a.dx, a.dy)
                ..close();
            }
            n++;
          }
        }
      }
      c.drawPath(_flames, DragonKit.fill(tone.lit(color), k));
    }
  }

  // ------------------------------------------------------------- helpers --

  /// A closed strip along [f] from half-width [h0] at the wrist to [h1] at
  /// the tip, in coordinates relative to [o]. [s0] and [s1] slide the strip
  /// sideways (toward the lead finger when positive) at each end.
  static void _taper(
    Path p,
    DragonFinger f,
    double h0,
    double h1, [
    Offset o = Offset.zero,
    double s0 = 0,
    double s1 = 0,
  ]) {
    Offset nrm(Offset v) => _lead(DragonKit.unit(v));
    final n0 = nrm(f.c1 - f.a), n1 = nrm(f.c2 - f.a);
    final n2 = nrm(f.b - f.c1), n3 = nrm(f.b - f.c2);
    final hc1 = h0 + (h1 - h0) * .33, hc2 = h0 + (h1 - h0) * .7;
    final sc1 = s0 + (s1 - s0) * .33, sc2 = s0 + (s1 - s0) * .7;
    final l0 = f.a + n0 * (s0 + h0) - o, l1 = f.c1 + n1 * (sc1 + hc1) - o;
    final l2 = f.c2 + n2 * (sc2 + hc2) - o, l3 = f.b + n3 * (s1 + h1) - o;
    final r0 = f.a + n0 * (s0 - h0) - o, r1 = f.c1 + n1 * (sc1 - hc1) - o;
    final r2 = f.c2 + n2 * (sc2 - hc2) - o, r3 = f.b + n3 * (s1 - h1) - o;
    p
      ..moveTo(l0.dx, l0.dy)
      ..cubicTo(l1.dx, l1.dy, l2.dx, l2.dy, l3.dx, l3.dy)
      ..lineTo(r3.dx, r3.dy)
      ..cubicTo(r2.dx, r2.dy, r1.dx, r1.dy, r0.dx, r0.dy)
      ..close();
  }

  /// The tone snapped to the steps of [DragonTone.key], so a cached paint is
  /// the same whichever frame built it (animation stays a pure function).
  static DragonTone _quantised(DragonTone t) => DragonTone(
    flash: (t.flash * 8).round() / 8,
    fury: (t.fury * 8).round() / 8,
    heat: (t.heat * 8).round() / 8,
    dark: (t.dark * 4).round() / 4,
    sky: t.sky,
  );
}
