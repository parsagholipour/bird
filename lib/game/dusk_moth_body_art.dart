import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'dusk_moth_boss_rig.dart' show DuskMothBossRig;
import 'dusk_moth_kit.dart';
import 'dusk_moth_pose.dart';

/// The Dusk Empress below the chin: a tapered abdomen banded in pearl, a
/// fuzzy thorax, slim gold-tipped legs, a layered ermine ruff, and the
/// jewelled throat sacs that load her pollen.
///
/// Authored in hit-radius units in the body frame. The ruff is two rings of
/// tufts (a tall back ring and a bright front ring) that ruffle, puff on the
/// windup and the roar, and bristle in fury.
abstract final class DuskMothBodyArt {
  static const _ink = DuskMothBossRig.ink;
  static const _pearl = DuskMothBossRig.pearl;
  static const _silk = DuskMothBossRig.silk;
  static const _coral = DuskMothBossRig.coral;
  static const _rose = DuskMothBossRig.rose;
  static const _wine = DuskMothBossRig.wine;
  static const _plum = DuskMothBossRig.plum;
  static const _pollen = DuskMothBossRig.pollen;
  static const _ember = DuskMothBossRig.ember;
  static const _peach = Color(0xffffc6a4), _shade = Color(0xffbe7f64);
  static const _ermine = Color(0xff4b3560);
  static const _amber = Color(0xffd98a3c), _amberDeep = Color(0xff9a4f3a);

  /// Where the ruff rings are centred, at the base of the neck.
  static const neck = Offset(-.5, -.02);

  /// The throat setting, and its three sacs.
  static const gland = Offset(-.6, .32);
  static const _sacs = [
    Offset(-.705, .285),
    Offset(-.505, .285),
    Offset(-.605, .425),
  ];

  // ---------------------------------------------------------------- thorax --

  // The thorax and its fur strands never change, so they are built once and
  // only shifted with the breath.
  static const _thoraxCentre = Offset(-.06, .1);
  static final _thorax = () {
    final body = Path()
      ..addOval(
        Rect.fromCenter(center: _thoraxCentre, width: 1.02, height: 1.0),
      );
    for (var i = 0; i < 13; i++) {
      final a = -1.05 + i * .36;
      final base = _thoraxCentre + Offset(math.cos(a) * .47, math.sin(a) * .46);
      final len = .17 + .07 * DuskMothKit.hash(20 + i);
      DuskMothKit.tuft(body, base, a + .12, len, .24, curl: .1);
    }
    return body;
  }();
  static final (Path, Path) _strands = () {
    final light = Path(), dark = Path();
    for (var i = 0; i < 26; i++) {
      final a = DuskMothKit.hash(50 + i) * math.pi * 2;
      final r = .12 + .36 * DuskMothKit.hash(80 + i);
      final at = _thoraxCentre + Offset(math.cos(a) * r, math.sin(a) * r * .95);
      final d = Offset(math.cos(a + .5), math.sin(a + .5)) * .09;
      (i.isEven ? light : dark)
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo(
          at.dx + d.dx * .6 - d.dy * .3,
          at.dy + d.dy * .6 + d.dx * .3,
          at.dx + d.dx,
          at.dy + d.dy,
        );
    }
    return (light, dark);
  }();

  static void thorax(Canvas c, DuskMothPose p) {
    final tone = p.tone;
    c.save();
    c.translate(0, p.breath * .5);
    c.drawPath(_thorax, DuskMothKit.line(_ink, .15));
    c.drawPath(
      _thorax,
      DuskMothKit.linear(
        const Offset(-.5, -.4),
        const Offset(.4, .65),
        [
          tone.burn(_coral, const Color(0xffffb08e)),
          tone.lit(const Color(0xffd57a86)),
          tone.lit(_rose),
          tone.lit(_wine),
        ],
        const [0, .25, .6, 1],
      ),
    );
    c.save();
    c.clipPath(_thorax);
    // Fur strands in light and shade.
    c.drawPath(
      _strands.$1,
      DuskMothKit.line(_pearl.withValues(alpha: .55), .03),
    );
    c.drawPath(
      _strands.$2,
      DuskMothKit.line(_shade.withValues(alpha: .5), .03),
    );
    c.restore();
    c.restore();
  }

  /// Fur epaulettes where the wings join the shoulders: pale locks that hide
  /// the roots of the wings and lift the eye off the velvet.
  static void shoulders(Canvas c, DuskMothPose p) {
    final tone = p.tone;
    final puff = 1 + p.shout * .15 + p.fury * .2;
    final locks = Path();
    const bases = [
      Offset(-.16, -.36),
      Offset(.02, -.4),
      Offset(.2, -.38),
      Offset(.36, -.3),
      Offset(.46, -.16),
    ];
    for (var i = 0; i < bases.length; i++) {
      DuskMothKit.fur(
        locks,
        bases[i] + Offset(0, p.breath * .5),
        -1.15 + i * .42 + p.sway(2.8, .05, i * 1.3),
        (.3 - i * .012) * puff,
        .22,
        curl: .12,
      );
    }
    c.drawPath(locks, DuskMothKit.line(_ink, .1));
    c.drawPath(
      locks,
      DuskMothKit.linear(const Offset(-.2, -.7), const Offset(.5, -.2), [
        tone.lit(_pearl),
        tone.lit(_peach),
      ]),
    );
  }

  // -------------------------------------------------------------- abdomen --

  static void abdomen(Canvas c, DuskMothPose p) {
    final tone = p.tone;
    // The tail end lags the beat: it dips as the wings rise.
    final dip = p.raise(.9) * -.06 + p.breath * 1.4 + p.sway(2.1, .03, .6);
    final centre = <Offset>[
      const Offset(.12, .14),
      const Offset(.6, .17),
      Offset(1.05, .27 + dip * .3),
      Offset(1.42, .43 + dip * .7),
      Offset(1.7, .62 + dip),
    ];
    const widths = [.86, .76, .54, .3, .05];
    final body = DuskMothKit.ribbon(centre, widths);
    c.drawPath(body, DuskMothKit.line(_ink, .15));
    c.drawPath(
      body,
      DuskMothKit.linear(
        const Offset(.2, -.3),
        const Offset(1.9, .8),
        [
          tone.burn(_coral, const Color(0xffffb08e)),
          tone.lit(const Color(0xffd57a86)),
          tone.lit(_rose),
          tone.lit(_wine),
        ],
        const [0, .3, .68, 1],
      ),
    );
    c.save();
    c.clipPath(body);
    final bands = Path(), spots = Path();
    for (var k = 0; k < 6; k++) {
      final t = .16 + k * .155;
      final (at, dir) = _along(centre, t);
      final n = Offset(-dir.dy, dir.dx);
      final w = _widthAt(widths, t) * .5;
      bands
        ..moveTo(at.dx + n.dx * w, at.dy + n.dy * w)
        ..quadraticBezierTo(
          at.dx + dir.dx * .2,
          at.dy + dir.dy * .2,
          at.dx - n.dx * w,
          at.dy - n.dy * w,
        );
      // A dorsal stud on each segment.
      final top = at + n * (w * .78);
      spots.addOval(Rect.fromCircle(center: top + dir * .05, radius: .03));
    }
    c.drawPath(bands, DuskMothKit.line(_ink.withValues(alpha: .35), .1));
    c.drawPath(
      bands,
      DuskMothKit.line(tone.burn(_pearl, const Color(0xffffb98a)), .062),
    );
    c.drawPath(bands, DuskMothKit.line(_rose.withValues(alpha: .6), .02));
    c.drawPath(spots, DuskMothKit.fill(_ermine));
    DuskMothKit.rim(c, body, light: _pearl, shade: _plum, width: .16);
    c.restore();
    // A pearl bead weights the tip.
    final tip = centre.last;
    c.drawCircle(tip, .07, DuskMothKit.fill(_ink));
    c.drawCircle(tip, .05, DuskMothKit.fill(tone.lit(_pearl)));
  }

  static (Offset, Offset) _along(List<Offset> pts, double t) {
    final f = t * (pts.length - 1);
    final i = f.floor().clamp(0, pts.length - 2);
    final a = pts[i], b = pts[i + 1];
    final d = b - a;
    return (a + d * (f - i), d / math.max(d.distance, 1e-6));
  }

  static double _widthAt(List<double> w, double t) {
    final f = t * (w.length - 1);
    final i = f.floor().clamp(0, w.length - 2);
    return w[i] + (w[i + 1] - w[i]) * (f - i);
  }

  // ------------------------------------------------------------------ legs --

  static void legs(Canvas c, DuskMothPose p, {required bool far}) {
    for (var i = far ? 1 : 0; i < 3; i++) {
      final x = -.42 + i * .24 + (far ? .1 : 0);
      // The front leg beckons with the summon; all curl up in defeat.
      final gesture = i == 0 ? p.summon : 0.0;
      final curl = p.curl;
      final sway = p.sway(2.4, .03, i * 1.4) + p.breath;
      final root = Offset(x, .4 + (far ? -.05 : 0));
      final knee =
          root +
          Offset(
            -.1 - gesture * .18 + sway - curl * .06,
            .32 - gesture * .3 - curl * .3,
          );
      final ankle =
          knee +
          Offset(
            -.1 - gesture * .16 - curl * .16,
            .3 - gesture * .16 - curl * .34,
          );
      final toe = ankle + Offset(-.09 - curl * .1, .1 - curl * .13);
      final leg = Path()
        ..moveTo(root.dx, root.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(ankle.dx, ankle.dy);
      if (far) {
        c.drawPath(leg, DuskMothKit.line(_ink, .1));
        c.drawPath(leg, DuskMothKit.line(_plum, .055));
        continue;
      }
      c.drawPath(leg, DuskMothKit.line(_ink, .115));
      c.drawPath(leg, DuskMothKit.line(_rose, .062));
      c.drawPath(leg, DuskMothKit.line(_coral.withValues(alpha: .8), .03));
      c.drawCircle(knee, .052, DuskMothKit.fill(_ink));
      c.drawCircle(knee, .034, DuskMothKit.fill(_pearl));
      // A gold-tipped foot that hooks like a courtier's slipper.
      final foot = Path()
        ..moveTo(ankle.dx, ankle.dy)
        ..quadraticBezierTo(
          ankle.dx + (toe.dx - ankle.dx) * .5,
          toe.dy + .04,
          toe.dx,
          toe.dy,
        );
      c.drawPath(foot, DuskMothKit.line(_ink, .12));
      c.drawPath(foot, DuskMothKit.line(_pollen, .062));
    }
  }

  // ------------------------------------------------------------------ ruff --

  // One ring of tufts about the neck, angles in radians clockwise from east.
  static void _ring(
    Canvas c,
    DuskMothPose p, {
    required int count,
    required double from,
    required double to,
    required Offset radii,
    required double length,
    required double width,
    required double phase,
    required List<Color> colors,
    bool spots = false,
  }) {
    final tone = p.tone;
    final puff =
        1 + p.charge * .1 + p.shout * .16 + p.recoil * .08 + p.jolt * .1;
    final bristle = 1 + p.fury * .26;
    final fills = DuskMothKit.linear(
      neck + const Offset(-.4, -.6),
      neck + const Offset(.5, .6),
      [for (final color in colors) tone.lit(color)],
    );
    for (var i = 0; i < count; i++) {
      final f = count == 1 ? 0.0 : i / (count - 1);
      final a = from + (to - from) * f;
      // Tufts are longest at the nape and shortest under the chin.
      final size =
          (.62 + .38 * math.sin((1 - f) * math.pi * .5 + .3)) *
          (.88 + .24 * DuskMothKit.hash(i * 7 + (phase * 10).round()));
      final len = length * size * puff * bristle;
      final wag =
          p.sway(3.1, .045 + p.fury * .05, i * 1.3 + phase) +
          p.sway(7.3, p.fury * .04, i * 2.1);
      // Fury flares each tuft outward from the neck.
      final angle = a + wag + (a > math.pi ? 0 : 0);
      final base =
          neck + Offset(math.cos(a) * radii.dx, math.sin(a) * radii.dy);
      final tuft = Path();
      DuskMothKit.fur(tuft, base, angle, len, width, curl: .08);
      c.drawPath(tuft, DuskMothKit.line(_ink, .1));
      c.drawPath(tuft, fills);
      // A crest line on each tuft's lit side.
      final dir = Offset(math.cos(angle), math.sin(angle));
      final side = Offset(-dir.dy, dir.dx);
      final lit = base + dir * (len * .16) - side * (width * .16);
      c.drawPath(
        Path()
          ..moveTo(lit.dx, lit.dy)
          ..quadraticBezierTo(
            lit.dx + dir.dx * len * .4 - side.dx * width * .12,
            lit.dy + dir.dy * len * .4 - side.dy * width * .12,
            lit.dx + dir.dx * len * .7,
            lit.dy + dir.dy * len * .7,
          ),
        DuskMothKit.line(_pearl.withValues(alpha: .8), .03),
      );
      if (spots && i % 3 == 1) {
        final mark = Path();
        DuskMothKit.tuft(
          mark,
          base + dir * (len * .58),
          angle,
          len * .3,
          width * .26,
          curl: .07,
        );
        c.drawPath(mark, DuskMothKit.fill(_ermine));
      }
    }
  }

  /// The tall back ring: it frames the head like a court collar.
  static void ruffBack(Canvas c, DuskMothPose p) => _ring(
    c,
    p,
    count: 15,
    from: -1.95,
    to: 3.3,
    radii: const Offset(.3, .36),
    length: .47,
    width: .3,
    phase: 0,
    colors: const [_silk, _peach, Color(0xffffb59c)],
  );

  /// The bright front ring, ermine-spotted, that overlaps the back ring.
  static void ruffFront(Canvas c, DuskMothPose p) => _ring(
    c,
    p,
    count: 12,
    from: -1.7,
    to: 2.15,
    radii: const Offset(.2, .26),
    length: .38,
    width: .27,
    phase: 1.7,
    colors: const [_pearl, _silk, _peach],
    spots: true,
  );

  /// A few small locks of fur that tuck over the edges of the throat setting.
  static void bib(Canvas c, DuskMothPose p) {
    final tone = p.tone;
    final puff = 1 + p.charge * .12 + p.shout * .14 + p.fury * .2;
    final locks = Path();
    for (var i = 0; i < 3; i++) {
      final a = 1.0 + i * .45;
      final base = gland + Offset(math.cos(a) * .3, math.sin(a) * .24 + .1);
      DuskMothKit.fur(
        locks,
        base,
        a + .1 + p.sway(3.3, .05, i * 1.1),
        .2 * puff,
        .2,
        curl: .06,
      );
    }
    c.drawPath(locks, DuskMothKit.line(_ink, .09));
    c.drawPath(locks, DuskMothKit.fill(tone.lit(_silk)));
  }

  // ---------------------------------------------------------------- glands --

  /// The throat setting: three amber sacs in one gold trefoil bezel, tucked
  /// under the chin in the ruff. On the windup they fill from the bottom,
  /// glowing molten pollen.
  static void glands(Canvas c, DuskMothPose p) {
    final tone = p.tone;
    final glow = Color.lerp(_pollen, _ember, p.fury)!;
    c.save();
    c.translate(p.recoil * .02, 0);
    c.drawPath(_setting, DuskMothKit.line(_ink, .1));
    c.drawPath(
      _setting,
      DuskMothKit.linear(
        const Offset(-.85, .1),
        const Offset(-.4, .58),
        [tone.lit(_pearl), tone.lit(_pollen), tone.lit(_shade)],
        const [0, .4, 1],
      ),
    );
    DuskMothKit.rim(c, _setting, light: _pearl, shade: _plum, width: .07);
    for (var i = 0; i < _sacs.length; i++) {
      final at = _sacs[i];
      final swell = ((p.charge - i * .12) / .76).clamp(0.0, 1.0);
      final lit = math.max(swell, p.fury * .3);
      final r = .088 + swell * .022;
      c.drawCircle(at, .108, DuskMothKit.fill(_ink));
      c.drawCircle(
        at,
        r,
        DuskMothKit.radial(
          at - Offset(r * .3, r * .3),
          r * 1.5,
          [
            tone.lit(Color.lerp(_amber, _pearl, lit * .75)!),
            tone.lit(Color.lerp(_amber, glow, lit)!),
            tone.lit(Color.lerp(_amberDeep, glow, lit * .6)!),
          ],
          const [0, .5, 1],
        ),
      );
      c.drawCircle(
        at + Offset(-r * .34, -r * .4),
        r * .26,
        DuskMothKit.fill(_pearl),
      );
    }
    // Pearls stud the setting.
    for (final bead in const [
      Offset(-.83, .29),
      Offset(-.375, .29),
      Offset(-.605, .55),
    ]) {
      c.drawCircle(bead, .03, DuskMothKit.fill(_ink));
      c.drawCircle(bead, .02, DuskMothKit.fill(_pearl));
    }
    c.restore();
  }

  static final _setting = Path()
    ..addOval(Rect.fromCircle(center: _sacs[0], radius: .135))
    ..addOval(Rect.fromCircle(center: _sacs[1], radius: .135))
    ..addOval(Rect.fromCircle(center: _sacs[2], radius: .135))
    ..addPolygon(_sacs, true);

  /// The light of the windup: a halo around the sacs and a bright vein that
  /// runs up the throat to the pollen port.
  static void pollenLight(Canvas c, DuskMothPose p) {
    final glow = Color.lerp(_pollen, _ember, p.fury)!;
    final power = math.max(p.charge, p.fury * .25);
    if (power <= 0) return;
    DuskMothKit.glow(c, gland, .5, glow, power * .55);
    if (p.charge > 0) {
      final vein = Path()
        ..moveTo(gland.dx - .18, gland.dy - .1)
        ..quadraticBezierTo(-.86, .17, -1.0, .07);
      c.drawPath(
        vein,
        DuskMothKit.line(_ink.withValues(alpha: .5 * p.charge), .085),
      );
      c.drawPath(vein, DuskMothKit.line(glow.withValues(alpha: p.charge), .05));
      c.drawPath(
        vein,
        DuskMothKit.line(_pearl.withValues(alpha: p.charge * .9), .02),
      );
    }
  }
}
