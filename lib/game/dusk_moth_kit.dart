import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'dusk_moth_boss_rig.dart' show DuskMothBossRig;

/// How the Dusk Empress is lit right now, shared by every part of her.
///
/// [flash] brightens fills toward pearl after a hit (the ink outline never
/// changes, so a struck queen does not fade); [fury] is the held ember state;
/// [moon] is the pale blue the silk veil lends her moon-marks.
final class DuskTone {
  const DuskTone({this.flash = 0, this.fury = 0, this.moon = 0});
  final double flash, fury, moon;

  /// A fill colour under the hit flash.
  Color lit(Color color) =>
      flash <= 0 ? color : Color.lerp(color, const Color(0xffffece4), flash)!;

  /// A fill colour that burns from [calm] to [burning] with fury.
  Color burn(Color calm, Color burning) =>
      lit(fury <= 0 ? calm : Color.lerp(calm, burning, fury)!);
}

/// Paints, gradients and path builders shared by the Dusk Empress parts.
abstract final class DuskMothKit {
  static Paint fill(Color color) => Paint()..color = color;
  static Paint line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint linear(
    Offset from,
    Offset to,
    List<Color> colors, [
    List<double>? stops,
  ]) =>
      Paint()
        ..shader = ui.Gradient.linear(from, to, colors, stops ?? _even(colors));
  static Paint radial(
    Offset center,
    double radius,
    List<Color> colors, [
    List<double>? stops,
  ]) => Paint()
    ..shader = ui.Gradient.radial(
      center,
      radius,
      colors,
      stops ?? _even(colors),
    );

  // Gradients need explicit stops beyond two colours; space them evenly.
  static List<double>? _even(List<Color> colors) => colors.length == 2
      ? null
      : [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];

  /// A soft round glow of [color]: a radial fade from [alpha] to nothing.
  static void glow(
    Canvas c,
    Offset at,
    double radius,
    Color color,
    double alpha,
  ) {
    if (alpha <= 0) return;
    c.drawCircle(
      at,
      radius,
      radial(
        at,
        radius,
        [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * .35),
          color.withValues(alpha: 0),
        ],
        const [0, .5, 1],
      ),
    );
  }

  /// A smooth curve through [pts] (Catmull-Rom turned into cubic Béziers).
  ///
  /// Vertices listed in [sharp] stay corners. With [from] and [to] only the
  /// segments between those vertices are built, as an open path that follows
  /// exactly the same curve as the whole outline, so a hem or a leading edge
  /// can be stroked along a piece of a closed shape.
  static Path spline(
    List<Offset> pts, {
    bool closed = true,
    Set<int> sharp = const {},
    int? from,
    int? to,
    double tension = 1,
  }) {
    final n = pts.length;
    Offset at(int i) => closed ? pts[(i % n + n) % n] : pts[i.clamp(0, n - 1)];
    final first = from ?? 0;
    final last = to ?? (closed ? n : n - 1);
    final path = Path()..moveTo(at(first).dx, at(first).dy);
    for (var i = first; i < last; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final c1 = sharp.contains((i % n + n) % n)
          ? p1
          : p1 + (p2 - p0) * (tension / 6);
      final c2 = sharp.contains(((i + 1) % n + n) % n)
          ? p2
          : p2 - (p3 - p1) * (tension / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (closed && from == null && to == null) path.close();
    return path;
  }

  /// [color] shaded toward ink: 1 leaves it as it is, less darkens it.
  static Color shade(Color color, double amount) =>
      amount >= 1 ? color : Color.lerp(DuskMothBossRig.ink, color, amount)!;

  /// Shading inside [path]: a lit rim on its upper-left edges and a shaded
  /// one on its lower-right, both clipped to the shape.
  static void rim(
    Canvas c,
    Path path, {
    required Color light,
    required Color shade,
    double width = .11,
    double shift = .05,
    double alpha = .5,
  }) {
    c.save();
    c.clipPath(path);
    c.translate(shift, shift);
    c.drawPath(path, line(light.withValues(alpha: alpha), width));
    c.translate(-shift * 2, -shift * 2);
    c.drawPath(path, line(shade.withValues(alpha: alpha * .7), width * 1.3));
    c.restore();
  }

  /// A pointed tuft of fur rooted at [base], leaning [curl] to one side. Like
  /// `Path.addOval` it runs clockwise, so tufts can be unioned with ovals in
  /// one nonzero fill without cancelling each other out.
  static void tuft(
    Path path,
    Offset base,
    double angle,
    double length,
    double width, {
    double curl = 0,
  }) {
    final dir = Offset(math.cos(angle), math.sin(angle));
    final side = Offset(-dir.dy, dir.dx);
    final left = base + side * (width / 2), right = base - side * (width / 2);
    final tip = base + dir * length + side * (curl * length);
    path
      ..moveTo(right.dx, right.dy)
      ..quadraticBezierTo(
        base.dx + dir.dx * length * .5 - side.dx * width * .66,
        base.dy + dir.dy * length * .5 - side.dy * width * .66,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        base.dx + dir.dx * length * .62 + side.dx * width * .78,
        base.dy + dir.dy * length * .62 + side.dy * width * .78,
        left.dx,
        left.dy,
      )
      ..close();
  }

  /// A clump of fur: a broad root and a jagged three-lock tip, [curl] leaning
  /// the tip to one side. Layered rings of these make the ermine ruff.
  static void fur(
    Path path,
    Offset base,
    double angle,
    double length,
    double width, {
    double curl = 0,
  }) {
    final dir = Offset(math.cos(angle), math.sin(angle));
    final left = Offset(-dir.dy, dir.dx);
    Offset p(double along, double across) =>
        base +
        dir * (along * length) +
        left * (across * width + curl * length * along * along);
    void to(Offset o) => path.lineTo(o.dx, o.dy);
    final start = p(0, .5);
    path.moveTo(start.dx, start.dy);
    // The outer flank swells to a small side lock, then the main lock curls
    // to the tip and the inner flank sweeps back to the root.
    final swell = p(.4, .9), side = p(.8, .52);
    path.quadraticBezierTo(swell.dx, swell.dy, side.dx, side.dy);
    to(p(.6, .26));
    final lift = p(.9, .3), tip = p(1.02, .02);
    path.quadraticBezierTo(lift.dx, lift.dy, tip.dx, tip.dy);
    final back = p(.5, -.7), end = p(0, -.5);
    path.quadraticBezierTo(back.dx, back.dy, end.dx, end.dy);
    path.close();
  }

  /// A crescent moon: a disc of radius [r] with a bite taken from its
  /// upper-right, so the lit horn opens toward the right of the frame. Built
  /// once per shape: the sizes are fixed, so the cache stays tiny.
  static Path crescent(Offset at, double r, {double bite = .84}) =>
      _moons.putIfAbsent((at.dx, at.dy, r, bite), () {
        final disc = Rect.fromCircle(center: at, radius: r);
        final cut = Rect.fromCircle(
          center: at + Offset(r * .48, -r * .24),
          radius: r * bite,
        );
        return Path.combine(
          PathOperation.difference,
          Path()..addOval(disc),
          Path()..addOval(cut),
        );
      });
  static final _moons = <(double, double, double, double), Path>{};

  /// A four-pointed twinkle.
  static Path star(Offset at, double r, {double waist = .2}) {
    final w = r * waist;
    return Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx + w, at.dy - w, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx + w, at.dy + w, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx - w, at.dy + w, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx - w, at.dy - w, at.dx, at.dy - r)
      ..close();
  }

  /// A repeatable 0..1 value for [n]; the wing dust and star fields use it so
  /// they are the same on every frame and every platform.
  static double hash(int n) {
    var x = (n * 0x9E3779B1) & 0xffffffff;
    x = ((x ^ (x >> 15)) * 0x85EBCA6B) & 0xffffffff;
    x = ((x ^ (x >> 13)) * 0xC2B2AE35) & 0xffffffff;
    x ^= x >> 16;
    return (x & 0xffff) / 0xffff;
  }

  /// A ribbon along [center], [width] wide at each sample, as a closed path.
  static Path ribbon(List<Offset> center, List<double> width) {
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < center.length; i++) {
      final a = center[math.max(i - 1, 0)];
      final b = center[math.min(i + 1, center.length - 1)];
      final d = b - a;
      final len = math.max(d.distance, 1e-6);
      final side = Offset(-d.dy / len, d.dx / len) * (width[i] / 2);
      left.add(center[i] + side);
      right.add(center[i] - side);
    }
    return spline([...left, ...right.reversed], sharp: {0, left.length - 1});
  }

  /// A lace of pearl scallops along the edge of [edge], bulging [depth] into
  /// the shape. [edge] must run clockwise on screen (y down), so the inward
  /// side is on the right of the direction of travel.
  static Path lace(Path edge, {required double size, required double depth}) {
    final out = Path();
    for (final metric in edge.computeMetrics()) {
      final count = math.max((metric.length / size).round(), 1);
      final edgePts = <Offset>[];
      final first = metric.getTangentForOffset(0)!;
      out.moveTo(first.position.dx, first.position.dy);
      edgePts.add(first.position);
      for (var i = 0; i < count; i++) {
        final a = metric.length * i / count;
        final b = metric.length * (i + 1) / count;
        final mid = metric.getTangentForOffset((a + b) / 2)!;
        final end = metric.getTangentForOffset(b)!;
        // The tangent's left normal points inward on a clockwise outline.
        final inward = Offset(-mid.vector.dy, mid.vector.dx);
        final control = mid.position + inward * (depth * 2);
        out.quadraticBezierTo(
          control.dx,
          control.dy,
          end.position.dx,
          end.position.dy,
        );
        edgePts.add(end.position);
      }
      for (final p in edgePts.reversed) {
        out.lineTo(p.dx, p.dy);
      }
      out.close();
    }
    return out;
  }
}
