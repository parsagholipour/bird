import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import 'dusk_moth_boss_rig.dart' show DuskMothBossRig;
import 'dusk_moth_kit.dart';
import 'dusk_moth_pose.dart';

/// The Dusk Empress's face and headdress: an imperious, predatory-elegant
/// profile with a kohl-dark eye mask that flicks up and back, a luminous
/// slit-pupilled eye that follows the bird under a heavy lid and a sharp
/// brow, a small mouth that is the pollen port, and a pair of tall plumed
/// feather antennae swept back like a headdress.
///
/// The head itself never moves: the pollen port stays at (-1.05, 0) and the
/// crown shares this frame, so the expression does all the acting.
abstract final class DuskMothHeadArt {
  static const _ink = DuskMothBossRig.ink;
  static const _pearl = DuskMothBossRig.pearl;
  static const _silk = DuskMothBossRig.silk;
  static const _coral = DuskMothBossRig.coral;
  static const _rose = DuskMothBossRig.rose;
  static const _plum = DuskMothBossRig.plum;
  static const _pollen = DuskMothBossRig.pollen;
  static const _veil = DuskMothBossRig.veil;
  static const _ember = DuskMothBossRig.ember;
  static const _peach = Color(0xffffc6a4);
  static const _flame = DuskMothBossRig.flame;

  /// The eye's centre; the arrival silhouette lights it alone.
  static const eye = DuskMothBossRig.eyeCenter;

  /// The far eye, seen at the front edge of the turned face.
  static const farEye = Offset(-1.17, -.3);

  /// The pollen port: the projectiles leave the dark mouth from here.
  static const mouth = Offset(-1.05, 0);

  static const _skullPoints = <Offset>[
    Offset(-.76, -.9),
    Offset(-1.05, -.85),
    Offset(-1.27, -.68),
    Offset(-1.37, -.45),
    Offset(-1.24, -.24),
    Offset(-1.28, -.06),
    Offset(-1.24, .08),
    Offset(-1.04, .15),
    Offset(-.84, .18),
    Offset(-.62, .11),
    Offset(-.45, -.1),
    Offset(-.4, -.45),
    Offset(-.5, -.78),
  ];

  /// The skull outline; the diadem's rim is fitted to its crest.
  static final skull = DuskMothKit.spline(_skullPoints, sharp: const {6});

  static const _eyeHalf = Offset(.27, .2);
  static const _eyeTilt = -.16;

  // ------------------------------------------------------------------ head --

  static void head(Canvas c, DuskMothPose p) {
    final tone = p.tone;
    c.drawPath(skull, DuskMothKit.line(_ink, .15));
    c.drawPath(
      skull,
      DuskMothKit.linear(
        const Offset(-1.15, -.9),
        const Offset(-.42, .24),
        [
          tone.lit(const Color(0xffffe6d4)),
          tone.burn(const Color(0xfff6bca4), const Color(0xfff4a486)),
          tone.lit(const Color(0xffe58f8e)),
        ],
        const [0, .5, 1],
      ),
    );
    c.save();
    c.clipPath(skull);
    DuskMothKit.rim(c, skull, light: _pearl, shade: _plum, alpha: .55);
    // The eye sits in a soft socket of shadow above a rose cheek.
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.95, -.3), width: .9, height: .6),
      DuskMothKit.radial(const Offset(-.95, -.3), .48, [
        _plum.withValues(alpha: .34),
        _plum.withValues(alpha: 0),
      ]),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.98, .0), width: .5, height: .26),
      DuskMothKit.radial(const Offset(-.98, .0), .3, [
        _rose.withValues(alpha: .35),
        _rose.withValues(alpha: 0),
      ]),
    );
    // Fine fur on the face, in light and shade.
    c.drawPath(
      _strands.$1,
      DuskMothKit.line(_pearl.withValues(alpha: .6), .028),
    );
    c.drawPath(
      _strands.$2,
      DuskMothKit.line(_plum.withValues(alpha: .32), .028),
    );
    c.restore();
    _eye(c, p);
    _mouth(c, p);
  }

  // Fixed fur strands over the skull: short flicks that sweep back from the
  // muzzle toward the ruff.
  static final (Path, Path) _strands = () {
    final light = Path(), dark = Path();
    for (var i = 0; i < 30; i++) {
      final at = Offset(
        -1.32 + .86 * DuskMothKit.hash(400 + i * 2),
        -.85 + 1.0 * DuskMothKit.hash(401 + i * 2),
      );
      final len = .07 + .07 * DuskMothKit.hash(500 + i);
      final a = .35 + .5 * DuskMothKit.hash(530 + i);
      final d = Offset(math.cos(a), -math.sin(a)) * len;
      (i.isEven ? light : dark)
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo(
          at.dx + d.dx * .5,
          at.dy + d.dy * .5 - .015,
          at.dx + d.dx,
          at.dy + d.dy,
        );
    }
    return (light, dark);
  }();

  static void _eye(Canvas c, DuskMothPose p) {
    // The head is turned three-quarters toward the bird: the far eye peeks
    // round the bridge of the face, squeezed by perspective.
    c.save();
    c.clipPath(skull);
    _eyeAt(c, p, at: farEye, tilt: _eyeTilt * .5, squeeze: .46);
    c.restore();
    _eyeAt(c, p, at: eye, tilt: _eyeTilt, squeeze: 1);
    // A small gold crescent under the eye, like a queen's beauty mark.
    c.drawPath(
      DuskMothKit.crescent(const Offset(-.9, .04), .05),
      DuskMothKit.fill(p.tone.lit(_pollen)),
    );
  }

  static void _eyeAt(
    Canvas c,
    DuskMothPose p, {
    required Offset at,
    required double tilt,
    required double squeeze,
  }) {
    final tone = p.tone;
    final fury = p.fury;
    final near = squeeze == 1;
    final (w, h) = (_eyeHalf.dx, _eyeHalf.dy);
    // A line's mood over the fight's own look: a contented half-lid, the
    // lids thrown up, a scowl, or a droop at the far corner, looking down.
    final (scowl, lidMood, wide, tip, gaze) = switch (p.mood) {
      StoryMood.happy => (0.0, -.04, 0.0, -.06, 0.0),
      StoryMood.surprised => (0.0, 0.0, .9, 0.0, -.4),
      StoryMood.angry => (.9, 0.0, 0.0, .04, 0.0),
      StoryMood.sad => (0.0, .2, 0.0, -.1, .9),
      _ => (0.0, 0.0, 0.0, 0.0, 0.0),
    };
    final glare = math.max(p.glare, scowl);
    // The upper lid is a straight cut, lowest at the bird's side, so she
    // always glares: a stern set in contempt, a scowl in fury, squeezed
    // when struck, thrown up in the roar, shut on a blink.
    final lid =
        (.14 + glare * .3 + p.wince * .4 + p.blink * .8 + lidMood).clamp(
          0.0,
          1.0,
        ) *
        (1 - math.max(p.shout, wide) * .85);
    final shut = p.defeated ? 1.0 : lid;
    final edge = -h + h * 2 * shut;
    final slant = .13 + glare * .06 + tip;
    // A gloat pushes the lower lid up into a smile.
    final happy = p.mood == StoryMood.happy && !p.defeated;
    final below = Path()
      ..moveTo(-w - .1, edge + slant)
      ..lineTo(w + .12, edge - slant);
    if (happy) {
      below
        ..lineTo(w + .12, h * .7)
        ..quadraticBezierTo(0, -h * .1, -w - .1, h * .7);
    } else {
      below
        ..lineTo(w + .12, h + .3)
        ..lineTo(-w - .1, h + .3);
    }
    below.close();
    DuskMothKit.glow(
      c,
      at,
      near ? .62 : .36,
      Color.lerp(_pollen, _flame, fury)!,
      .2 + fury * .36 + p.charge * .22,
    );
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(tilt);
    c.scale(squeeze, 1);
    final shape = _eyeShape(w, h);
    c.save();
    c.clipPath(below);
    c.drawPath(shape, DuskMothKit.line(_ink, .1));
    final shade = near ? 1.0 : .96;
    c.drawPath(
      shape,
      DuskMothKit.radial(
        const Offset(-.04, -.03),
        .36,
        [
          tone.lit(
            DuskMothKit.shade(
              Color.lerp(
                const Color(0xffffefb8),
                const Color(0xffffe6a0),
                fury,
              )!,
              shade,
            ),
          ),
          tone.lit(
            DuskMothKit.shade(Color.lerp(_pollen, _ember, fury)!, shade),
          ),
          tone.lit(
            DuskMothKit.shade(
              Color.lerp(const Color(0xffe0883a), _flame, fury)!,
              shade,
            ),
          ),
        ],
        const [0, .5, 1],
      ),
    );
    c.save();
    c.clipPath(shape);
    c.drawPath(
      _facets,
      DuskMothKit.fill(const Color(0xffb8622e).withValues(alpha: .28)),
    );
    // The pupil follows the bird, and thins to a slit as she glares.
    final look = Offset(
      near ? -.05 : -.09,
      (p.aim + gaze).clamp(-1.0, 1.0) * .075 + .02,
    );
    final pupil = Rect.fromCenter(
      center: look,
      width:
          (.16 - glare * .08 - p.charge * .02) *
          (near ? 1 : 1.5) *
          (1 - wide * .3),
      height: .3 * (1 - wide * .3),
    );
    c.drawOval(pupil, DuskMothKit.fill(const Color(0xff2a1a3e)));
    c.drawOval(
      pupil.deflate(.02),
      DuskMothKit.radial(look, .13, [
        const Color(0xff4a2b58),
        const Color(0xff1d1430),
      ]),
    );
    c.drawCircle(
      look + const Offset(-.05, -.06),
      .045,
      DuskMothKit.fill(_pearl),
    );
    c.drawCircle(
      look + const Offset(.035, .06),
      .02,
      DuskMothKit.fill(_pearl.withValues(alpha: .85)),
    );
    c.restore();
    c.drawPath(shape, DuskMothKit.line(_ink, .045));
    c.restore();
    if (happy) {
      c.save();
      c.clipPath(shape);
      c.drawPath(
        Path()
          ..moveTo(w + .12, h * .7)
          ..quadraticBezierTo(0, -h * .1, -w - .1, h * .7),
        DuskMothKit.line(_ink, .07),
      );
      c.restore();
    }
    // The kohl line that cuts the lid runs on into a wing-flick.
    final cut = Path()
      ..moveTo(-w * .96, edge + slant * .96)
      ..lineTo(w * 1.02, edge - slant * 1.02)
      ..quadraticBezierTo(w * 1.7, edge - slant - .04, w * 2.3, edge - .3);
    c.save();
    c.clipPath(Path()..addRect(Rect.fromLTRB(-w - .05, -h * 3, w * 3, h * 3)));
    c.drawPath(cut, DuskMothKit.line(_ink, near ? .085 : .07));
    c.restore();
    if (p.defeated && near) {
      final x = Path()
        ..moveTo(-.1, -.02)
        ..lineTo(.1, .16)
        ..moveTo(.1, -.02)
        ..lineTo(-.1, .16);
      c.drawPath(x, DuskMothKit.line(_ink, .065));
    }
    c.restore();
  }

  // Faint compound-eye facets in the iris, in the eye's own frame.
  static final _facets = () {
    final path = Path();
    for (var row = -2; row <= 2; row++) {
      for (var col = -4; col <= 4; col++) {
        final at = Offset(col * .074 + (row.isOdd ? .037 : 0), row * .068);
        path.addOval(Rect.fromCircle(center: at, radius: .014));
      }
    }
    return path;
  }();

  // A leaf-shaped eye: round toward the bird, pointed at the rear corner.
  static Path _eyeShape(double w, double h) => Path()
    ..moveTo(w * 1.08, -h * .2)
    ..cubicTo(w * .6, h * 1.4, -w * .95, h * 1.3, -w, 0)
    ..cubicTo(-w * .95, -h * 1.4, w * .5, -h * 1.45, w * 1.08, -h * .2)
    ..close();

  static void _mouth(Canvas c, DuskMothPose p) {
    final g = p.gape;
    // The proboscis coils under the chin and unwinds into the port on the
    // windup or the roar.
    final curl = 1 - math.max(math.max(p.charge, p.shout), p.voice * .6);
    if (curl > .02) {
      final coil = Path()..moveTo(-1.05, .06);
      for (var i = 1; i <= 26; i++) {
        final t = i / 26;
        final turn = t * math.pi * 2.7 * curl;
        final r = .1 * curl * (1 - t * .7);
        final centre = Offset(-1.05, .06 + .12 * curl);
        coil.lineTo(
          centre.dx - math.sin(turn) * r,
          centre.dy - math.cos(turn) * r,
        );
      }
      c.drawPath(coil, DuskMothKit.line(_ink, .07));
      c.drawPath(coil, DuskMothKit.line(_rose, .03));
    }
    // Words open it wider than the fight does, so they read at her size.
    final rect = Rect.fromCenter(
      center: mouth,
      width: .17 + g * .05 + p.voice * .06,
      height: .12 + g * .17 + p.recoil * .03 + p.voice * .1,
    );
    // A rose lip under the dark port, and two small fangs that grow as it
    // opens. Both keep clear of the exact centre of the port.
    c.drawArc(
      rect.inflate(.025),
      .35,
      2.45,
      false,
      DuskMothKit.line(p.tone.lit(_rose), .035),
    );
    c.drawOval(rect, DuskMothKit.fill(_ink));
    final length = .03 + .045 * g.clamp(0.0, 1.0);
    for (final dx in const [-.072, .058]) {
      final fang = Path()
        ..moveTo(mouth.dx + dx - .022, rect.top + .012)
        ..lineTo(mouth.dx + dx + .022, rect.top + .012)
        ..lineTo(mouth.dx + dx, rect.top + .012 + length)
        ..close();
      c.drawPath(fang, DuskMothKit.fill(_pearl));
    }
  }

  // --------------------------------------------------------------- plumes --

  /// The feather antennae: a far plume and a near plume that sweep up and
  /// back from behind the diadem, lit at the tips.
  static void plumes(Canvas c, DuskMothPose p) {
    _plume(c, p, far: true);
    _plume(c, p, far: false);
  }

  static void _plume(Canvas c, DuskMothPose p, {required bool far}) {
    final tone = p.tone;
    // The plume trails the wingbeat and swings on the windup and the roar.
    final sway =
        p.sway(2.3, .07, far ? 1.4 : 0) +
        p.raise(far ? 1.2 : .8) * .05 +
        p.recoil * .09 +
        p.jolt * .08 +
        p.summon * -.05 +
        p.shout * -.06;
    // A beaten queen's plumes wilt.
    final lift =
        p.shout * .12 +
        p.summon * .1 +
        p.charge * .03 +
        p.fury * .05 -
        p.curl * .5;
    final wilt = p.curl;
    final root = far ? const Offset(-.46, -.82) : const Offset(-.62, -.9);
    final c1 =
        (far ? const Offset(-.38, -1.4) : const Offset(-.62, -1.44)) +
        Offset(sway * .3 + wilt * .12, -lift * .3);
    final c2 =
        (far ? const Offset(-.1, -1.8) : const Offset(-.5, -1.94)) +
        Offset(sway * .7 + wilt * .42, -lift * .6);
    final tip =
        (far ? const Offset(.34, -2.0) : const Offset(-.28, -2.26)) +
        Offset(sway * 1.1 + wilt * .78, -lift);
    const n = 9;
    Offset at(double t) {
      final u = 1 - t;
      return root * (u * u * u) +
          c1 * (3 * u * u * t) +
          c2 * (3 * u * t * t) +
          tip * (t * t * t);
    }

    final centre = [for (var i = 0; i <= n * 2; i++) at(i / (n * 2))];
    double halfWidth(double t) =>
        (far ? .15 : .19) *
        math.sin(math.pi * math.pow(t, .72)) *
        (1 + p.fury * .12);
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= n * 2; i++) {
      final t = i / (n * 2);
      final a = centre[math.max(i - 1, 0)];
      final b = centre[math.min(i + 1, n * 2)];
      final d = b - a;
      final dir = d / math.max(d.distance, 1e-6);
      final normal = Offset(-dir.dy, dir.dx);
      // Barbs on even samples reach out and lean toward the tip; the odd
      // samples are the valleys between them.
      final barb = i.isEven;
      final w = halfWidth(t) * (barb ? 1 : .5);
      final lean = barb ? dir * (halfWidth(t) * .7) : Offset.zero;
      left.add(centre[i] + normal * w + lean);
      right.add(centre[i] - normal * w + lean);
    }
    final outline = Path()..moveTo(left.first.dx, left.first.dy);
    for (final pt in left.skip(1)) {
      outline.lineTo(pt.dx, pt.dy);
    }
    for (final pt in right.reversed) {
      outline.lineTo(pt.dx, pt.dy);
    }
    outline.close();
    final base = far
        ? const [_peach, _coral, _rose]
        : const [_silk, _peach, _coral];
    c.drawPath(outline, DuskMothKit.line(_ink, far ? .1 : .12));
    c.drawPath(
      outline,
      DuskMothKit.linear(root, tip, [
        for (final color in base) tone.lit(color),
      ]),
    );
    // Barb lines, and a glowing quill.
    final barbs = Path();
    for (var i = 2; i < n * 2; i += 2) {
      barbs
        ..moveTo(centre[i].dx, centre[i].dy)
        ..lineTo(left[i].dx, left[i].dy)
        ..moveTo(centre[i].dx, centre[i].dy)
        ..lineTo(right[i].dx, right[i].dy);
    }
    c.drawPath(barbs, DuskMothKit.line(_rose.withValues(alpha: .7), .022));
    final quill = DuskMothKit.spline(centre, closed: false);
    c.drawPath(quill, DuskMothKit.line(_ink.withValues(alpha: .6), .05));
    c.drawPath(
      quill,
      DuskMothKit.line(Color.lerp(_pearl, _ember, p.fury * .7)!, .022),
    );
    // Lit tips.
    final light = Color.lerp(
      Color.lerp(_pollen, _veil, p.moonlight)!,
      _ember,
      p.fury,
    )!;
    DuskMothKit.glow(c, tip, .3, light, .55 + p.charge * .2);
    c.drawCircle(tip, .07, DuskMothKit.fill(_ink));
    c.drawCircle(tip, .052, DuskMothKit.fill(tone.lit(light)));
    c.drawCircle(
      tip + const Offset(-.016, -.016),
      .018,
      DuskMothKit.fill(_pearl),
    );
  }
}
