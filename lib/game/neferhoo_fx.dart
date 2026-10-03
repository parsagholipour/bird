import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'neferhoo_kit.dart';

/// Neferhoo's screen-space effects that are not props: his magic's glyph
/// motes, the arrival's glowing eyes, and the ankh's loop as the rules fly it.
/// Ported 1:1 from the approved design (`egypt-ws/iter5/test/egypt/
/// mummy_fx.dart`). Pure functions of their arguments; no layers, no blur.
abstract final class NeferhooFx {
  /// The ankh's flight path, as the rules fly it ([NeferhooAnkh.at]),
  /// sampled in [n] + 1 points: out along [yA] from the hand at [fromX], a
  /// half turn [turnX] (the rules' [Neferhoo.turnX] of the bird's column),
  /// back along [yB]. Screen fractions (screen heights).
  static List<Offset> ankhLoop(double fromX, double yA, double yB, {int n = 120, double? turnX}) {
    final turn = turnX ?? Neferhoo.turnX(FlightSimulation.birdX);
    final r = (yB - yA).abs() / 2;
    final legOut = fromX - turn, arc = math.pi * r;
    final total = legOut * 2 + arc;
    final out = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final s = total * k / n;
      if (s <= legOut) {
        out.add(Offset(fromX - s, yA));
      } else if (s <= legOut + arc) {
        final a = (s - legOut) / r;
        final cy = (yA + yB) / 2, sign = yB > yA ? 1 : -1;
        out.add(Offset(turn - r * math.sin(a), cy - sign * r * math.cos(a)));
      } else {
        out.add(Offset(turn + (s - legOut - arc), yB));
      }
    }
    return out;
  }

  // unit glyphs, 1 = the glyph's height, centred
  static final List<Path> _glyphs = () {
    final eye = Path()
      ..moveTo(-.5, 0)
      ..quadraticBezierTo(0, -.55, .5, 0)
      ..quadraticBezierTo(0, .42, -.5, 0)
      ..addOval(Rect.fromCircle(center: const Offset(0, -.03), radius: .12))
      ..moveTo(.1, .2)
      ..quadraticBezierTo(.22, .5, .5, .46);
    // an ankh: an open LOOP on a T (a loop at every size: never a bare cross), a
    // little taller than its neighbours (see `gs` below)
    final ankh = Path()
      ..addOval(Rect.fromCenter(center: const Offset(0, -.27), width: .42, height: .46))
      ..moveTo(0, -.04)
      ..lineTo(0, .5)
      ..moveTo(-.3, .02)
      ..lineTo(.3, .02);
    final feather = Path()
      ..moveTo(0, .5)
      ..quadraticBezierTo(-.3, 0, 0, -.5)
      ..quadraticBezierTo(.3, 0, 0, .5)
      ..moveTo(0, .5)
      ..lineTo(0, -.5);
    final water = Path()
      ..moveTo(-.5, -.12)
      ..lineTo(-.25, -.32)
      ..lineTo(0, -.12)
      ..lineTo(.25, -.32)
      ..lineTo(.5, -.12)
      ..moveTo(-.5, .26)
      ..lineTo(-.25, .06)
      ..lineTo(0, .26)
      ..lineTo(.25, .06)
      ..lineTo(.5, .26);
    return [eye, ankh, feather, water];
  }();

  static Paint _fill(Color c, double a) => Paint()..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));
  static Paint _stroke(Color c, double w, double a) => Paint()
    ..color = c.withValues(alpha: (c.a * a).clamp(0.0, 1.0))
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Floating glyph motes of his magic around [boss] (px, the chest) on a
  /// screen [h] px high at [age] seconds: a wedjat eye, an ankh, a feather
  /// and a water ripple in turquoise, orbiting him on slow ellipses, each
  /// with a faint glow and a twinkle. Sparing by design: [strength] 0..1
  /// sets how many are lit (about 7 at 1, 3-4 at .6); [fade] 0..1 lights
  /// one more at that share of its strength (so a mote never pops in).
  static void glyphMotes(Canvas c, Offset boss, double h, double age, {double strength = 1, double fade = 0}) {
    if (strength <= 0) return;
    final u = h * .115;
    final n = (7 * strength.clamp(0.0, 1.0)).round();
    final lit = fade > 0 && n < 7 ? n + 1 : n;
    for (var k = 0; k < lit; k++) {
      final a = age * (.6 + k * .05) + k * .9;
      final r = u * (2.1 + .4 * math.sin(age * .8 + k));
      final o = boss + Offset(math.cos(a) * r * 1.2, math.sin(a) * r * .8 - u * .4);
      final tw = .5 + .5 * math.sin(age * 2 + k * 1.7);
      final al = (.4 + .45 * tw) * strength.clamp(0.0, 1.0) * (k < n ? 1 : fade.clamp(0.0, 1.0));
      // (the ankh is drawn larger so its loop stays open)
      final gs = h * (k % 4 == 0 ? .028 : .024) * (k % 4 == 1 ? 1.3 : 1.0);
      c.drawCircle(o, gs * .85, _fill(NeferhooPalette.magic, .16 * al));
      c.save();
      c.translate(o.dx, o.dy + math.sin(age * 1.7 + k) * h * .004);
      c.scale(gs);
      c.drawPath(_glyphs[k % 4], _stroke(NeferhooPalette.ink, .26, .35 * al));
      c.drawPath(_glyphs[k % 4], _stroke(NeferhooPalette.magic, .15, al));
      c.restore();
    }
  }

  /// A sky-tinted silhouette's two glowing eyes (the arrival), [boss] the
  /// chest in px on a screen [h] px high, [a] their strength.
  static void silhouetteGlow(Canvas c, Offset boss, double h, double a) {
    final eye = boss + Offset(-h * .115 * 1.27, -h * .115 * 1.4);
    c.drawCircle(eye, h * .02, _fill(NeferhooPalette.magic, a));
    c.drawCircle(eye, h * .045, _fill(NeferhooPalette.magic, .25 * a));
  }
}
