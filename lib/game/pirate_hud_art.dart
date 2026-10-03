import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// The Pirate Captain's health plate dressing: a weathered plank plate laced
/// with rope, a brass porthole holding a skull and crossbones, a gauge of
/// rolling sea-water with a foam tip, a gold doubloon on the fury mark and a
/// gold-and-blood damage drain.
///
/// [BossHealthBarArt] keeps the layout, timeline and numbers; these are only
/// the pirate's brushstrokes. Everything is drawn from the values it is given
/// (the boss clock included) so paused, replayed and captured frames repeat.
abstract final class PirateHudArt {
  static const ink = Color(0xff241510), cream = Color(0xfffff2c9);
  static const gold = Color(0xffffcf5c), goldDeep = Color(0xffc9862b);
  static const goldLight = Color(0xfffff0b4), crimson = Color(0xffd4404f);
  static const rope = Color(0xffdcb87a), ropeDeep = Color(0xff7d522b);
  static const foam = Color(0xfff2fffb), bone = Color(0xfffff4dd);
  static const _woodLit = Color(0xff644029), _wood = Color(0xff3e2619);
  static const _woodDeep = Color(0xff2a1a12);
  static const _bed = Color(0xff153b47), _bedDeep = Color(0xff0c2530);
  static const _ember = Color(0xffff775c), _mint = Color(0xffa8e8bc);

  // The plank pill and its rope lacing only depend on the strip, so the
  // twist marks and grain are built once per layout.
  static Rect? _builtFor;
  static Path _twist = Path(), _grain = Path(), _grainLit = Path();

  static void _build(Rect strip, double u) {
    if (_builtFor == strip) return;
    _builtFor = strip;
    final line = strip.deflate(1.9 * u);
    final r = line.height / 2;
    final twist = Path();
    void tick(Offset p, double along) {
      final tx = math.cos(along), ty = math.sin(along);
      final nx = -ty, ny = tx;
      twist
        ..moveTo(
          p.dx - nx * .8 * u - tx * .55 * u,
          p.dy - ny * .8 * u - ty * .55 * u,
        )
        ..lineTo(
          p.dx + nx * .8 * u + tx * .55 * u,
          p.dy + ny * .8 * u + ty * .55 * u,
        );
    }

    final step = 2.7 * u;
    for (var x = line.left + r; x <= line.right - r; x += step) {
      tick(Offset(x, line.top), 0);
      tick(Offset(x, line.bottom), math.pi);
    }
    final arc = math.pi * r;
    final n = (arc / step).round();
    for (var i = 1; i < n; i++) {
      final a = i * math.pi / n;
      tick(
        Offset(line.right - r, line.center.dy) +
            Offset(math.sin(a), -math.cos(a)) * r,
        a,
      );
      tick(
        Offset(line.left + r, line.center.dy) +
            Offset(-math.sin(a), math.cos(a)) * r,
        a + math.pi,
      );
    }
    _twist = twist;
    final grain = Path(), lit = Path();
    for (final (f, phase) in const [(.3, 0.0), (.56, 1.9), (.8, 4.1)]) {
      final y = strip.top + strip.height * f;
      for (var x = strip.left + r; x <= strip.right - r; x += 2 * u) {
        final wave = .35 * u * math.sin(x / (9 * u) + phase);
        if (x == strip.left + r) {
          grain.moveTo(x, y + wave);
          lit.moveTo(x, y + wave + .7 * u);
        } else {
          grain.lineTo(x, y + wave);
          lit.lineTo(x, y + wave + .7 * u);
        }
      }
    }
    _grain = grain;
    _grainLit = lit;
  }

  /// The plate: drop shadow, dark edge, plank body, grain, a lit top edge and
  /// the rope lacing. [flash] blends the rope toward cream on hits and at the
  /// onset of fury.
  static void frame(
    Canvas c,
    Rect strip,
    double u, {
    required bool fury,
    required bool defeated,
    required double wave,
    required double flash,
  }) {
    _build(strip, u);
    final pill = RRect.fromRectAndRadius(
      strip,
      Radius.circular(strip.height / 2),
    );
    c.drawRRect(
      pill.shift(Offset(0, 1.5 * u)),
      Paint()..color = ink.withValues(alpha: .3),
    );
    c.drawRRect(pill, Paint()..color = ink);
    final body = pill.deflate(1 * u);
    c.save();
    c.clipRRect(body);
    c.drawRect(strip, Paint()..color = _wood);
    c.drawRect(
      Rect.fromLTRB(
        strip.left,
        strip.top,
        strip.right,
        strip.top + strip.height * .4,
      ),
      Paint()..color = _woodLit.withValues(alpha: .85),
    );
    c.drawRect(
      Rect.fromLTRB(
        strip.left,
        strip.bottom - strip.height * .3,
        strip.right,
        strip.bottom,
      ),
      Paint()..color = _woodDeep.withValues(alpha: .8),
    );
    c.drawPath(
      _grain,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6 * u
        ..color = ink.withValues(alpha: .28),
    );
    c.drawPath(
      _grainLit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .5 * u
        ..color = ropeDeep.withValues(alpha: .28),
    );
    c.restore();

    var color = rope;
    if (fury) color = Color.lerp(rope, _ember, .5 + .35 * wave)!;
    if (defeated) color = Color.lerp(rope, _mint, .5)!;
    color = Color.lerp(color, cream, flash.clamp(0.0, 1.0))!;
    final line = RRect.fromRectAndRadius(
      strip.deflate(1.9 * u),
      Radius.circular(strip.height / 2 - 1.9 * u),
    );
    c.drawRRect(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * u
        ..color = ink,
    );
    c.drawRRect(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7 * u
        ..color = color,
    );
    c.drawPath(
      _twist,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .55 * u
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(ropeDeep, color, .2)!.withValues(alpha: .85),
    );
  }

  /// A brass porthole with a skull and crossbones behind sea-glass.
  static void crest(
    Canvas c,
    Offset center,
    double r,
    double u, {
    required List<Color> glass,
    required bool fury,
  }) {
    c.drawCircle(center, r + .7 * u, Paint()..color = ink);
    c.drawCircle(center, r, Paint()..color = goldDeep);
    c.drawCircle(
      center + Offset(-.06 * r, -.08 * r),
      r * .92,
      Paint()..color = gold,
    );
    c.drawArc(
      Rect.fromCircle(center: center, radius: r * .84),
      math.pi * 1.05,
      math.pi * .5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * u
        ..strokeCap = StrokeCap.round
        ..color = goldLight,
    );
    final pane = r * .74;
    c.drawCircle(center, pane + .55 * u, Paint()..color = ink);
    c.drawCircle(center, pane, Paint()..color = glass[2]);
    c.drawCircle(
      center + Offset(0, -pane * .1),
      pane * .86,
      Paint()..color = glass[1],
    );
    c.drawCircle(
      center + Offset(-pane * .18, -pane * .34),
      pane * .5,
      Paint()..color = glass[0].withValues(alpha: .4),
    );
    // Rivets on the brass.
    for (var i = 0; i < 4; i++) {
      final a = math.pi / 4 + i * math.pi / 2;
      c.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * r * .87,
        .45 * u,
        Paint()..color = ink.withValues(alpha: .55),
      );
    }

    mark(c, center, pane * .98, fill: bone, edge: ink);
    if (fury) {
      c.drawCircle(
        center,
        r + .3 * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3 * u
          ..color = _ember,
      );
    }
  }

  /// The pirate's mark: crossbones behind a grinning skull, [s] being the
  /// half-width of the whole emblem.
  static void mark(
    Canvas c,
    Offset center,
    double s, {
    required Color fill,
    required Color edge,
    double alpha = 1,
  }) {
    final o = center + Offset(0, s * .06);
    final bones = Path()
      ..moveTo(o.dx - s * .62, o.dy - s * .5)
      ..lineTo(o.dx + s * .62, o.dy + s * .62)
      ..moveTo(o.dx + s * .62, o.dy - s * .5)
      ..lineTo(o.dx - s * .62, o.dy + s * .62);
    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..color = color.withValues(alpha: color.a * alpha);
    c.drawPath(bones, stroke(edge, s * .34));
    c.drawPath(bones, stroke(fill, s * .17));
    final skull = center + Offset(0, -s * .1);
    final jaw = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: skull + Offset(0, s * .38),
        width: s * .5,
        height: s * .3,
      ),
      Radius.circular(s * .1),
    );
    Paint flat(Color color) =>
        Paint()..color = color.withValues(alpha: color.a * alpha);
    c.drawCircle(skull, s * .5, flat(edge));
    c.drawRRect(jaw.inflate(s * .08), flat(edge));
    c.drawCircle(skull, s * .4, flat(fill));
    c.drawRRect(jaw, flat(fill));
    for (final side in [-1.0, 1.0]) {
      c.drawCircle(skull + Offset(side * s * .17, 0), s * .125, flat(edge));
    }
    c.drawLine(
      skull + Offset(0, s * .28),
      skull + Offset(0, s * .46),
      Paint()
        ..color = edge.withValues(alpha: edge.a * alpha * .55)
        ..strokeWidth = s * .05,
    );
  }

  /// The gauge's empty bed: a brass-lined channel of deep water.
  static void track(Canvas c, Rect bar, double u) {
    final radius = Radius.circular(bar.height / 2);
    final track = RRect.fromRectAndRadius(bar, radius);
    c.drawRRect(track.inflate(1.4 * u), Paint()..color = ink);
    c.drawRRect(
      track.inflate(.9 * u),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7 * u
        ..color = goldDeep.withValues(alpha: .75),
    );
    c.drawRRect(track, Paint()..color = _bedDeep);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bar.left, bar.top + 1.6 * u, bar.right, bar.bottom),
        radius,
      ),
      Paint()..color = _bed,
    );
  }

  static double _lap(double x, Rect bar, double length, double phase) =>
      (x - bar.left) / length * 2 * math.pi + phase;

  static Path _swell(
    Rect bar,
    double from,
    double to,
    double y,
    double amp,
    double length,
    double phase,
    double u,
  ) {
    final p = Path();
    var x = from;
    p.moveTo(x, y + amp * math.sin(_lap(x, bar, length, phase)));
    while (x < to) {
      x = math.min(x + 1.4 * u, to);
      p.lineTo(x, y + amp * math.sin(_lap(x, bar, length, phase)));
    }
    return p;
  }

  /// The health as sea-water: a deep base, a lit body under a rolling
  /// surface, a wave-shaped shine and a foam tip on the leading edge.
  static void fill(
    Canvas c,
    Rect bar,
    double right,
    double u,
    List<Color> ramp, {
    required double glow,
    required double phase,
    required bool foamTip,
  }) {
    final left = bar.left, top = bar.top, bottom = bar.bottom;
    c.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      Paint()..color = ramp[2],
    );
    double surface(double x) =>
        bottom - 3.3 * u + .6 * u * math.sin(_lap(x, bar, 8.5 * u, phase));
    final lit = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(right, surface(right));
    for (var x = right; x > left; x -= 1.4 * u) {
      lit.lineTo(x, surface(x));
    }
    lit.lineTo(left, surface(left));
    lit.close();
    c.drawPath(lit, Paint()..color = Color.lerp(ramp[1], ramp[0], glow)!);
    final shine = _swell(
      bar,
      left + 2.4 * u,
      math.max(left + 2.4 * u, right - 2.2 * u),
      top + 2.3 * u,
      .45 * u,
      13 * u,
      phase * 1.3 + 1,
      u,
    );
    c.drawPath(
      shine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.5 * u
        ..color = ramp[0].withValues(alpha: .9),
    );
    if (foamTip) {
      // Foam gathers where the water stops.
      final bob = math.sin(phase * 1.7) * .35 * u;
      final x = right - .2 * u;
      for (final (dy, radius, shift) in const [
        (.2, 1.5, .0),
        (.5, 1.95, .5),
        (.8, 1.5, -.1),
      ]) {
        c.drawCircle(
          Offset(x + shift * u, top + bar.height * dy + bob * (dy - .5) * 2),
          radius * u,
          Paint()..color = foam,
        );
      }
      c.drawRect(
        Rect.fromLTRB(right - 1.2 * u, top, right, bottom),
        Paint()..color = foam,
      );
    }
  }

  /// The damage drain: molten gold over blood, white-hot for a beat after a
  /// hit ([heat] 1) and cooling to its own colors.
  static void chip(
    Canvas c,
    Rect area, {
    required double heat,
    required double alpha,
  }) {
    const white = Color(0xffffffff);
    final gilt = Color.lerp(gold, white, heat * .9)!.withValues(alpha: alpha);
    final blood = Color.lerp(
      crimson,
      white,
      heat * .9,
    )!.withValues(alpha: alpha);
    c.drawRect(area, Paint()..color = gilt);
    c.drawRect(
      Rect.fromLTRB(
        area.left,
        area.top + area.height * .6,
        area.right,
        area.bottom,
      ),
      Paint()..color = blood,
    );
  }

  /// The fury mark: a gold doubloon set in the plate's rim until the boss
  /// crosses into fury (half health, or [share] of it: a third for a staged
  /// campaign boss), then a hollow, ember-rimmed slot.
  static void halfMark(
    Canvas c,
    Rect bar,
    double u, {
    required bool above,
    required bool fury,
    required double wave,
    double share = .5,
  }) {
    final x = bar.left + bar.width * share;
    final slot = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, bar.center.dy),
        width: 1.9 * u,
        height: bar.height + 1.4 * u,
      ),
      Radius.circular(.95 * u),
    );
    c.drawRRect(slot, Paint()..color = ink);
    if (above) {
      c.drawLine(
        Offset(x, bar.top + 2 * u),
        Offset(x, bar.bottom - .4 * u),
        Paint()
          ..color = goldDeep
          ..strokeWidth = .7 * u
          ..strokeCap = StrokeCap.round,
      );
    }
    final at = Offset(x, bar.top - .1 * u);
    final r = 3.1 * u;
    if (above) {
      c.drawCircle(at, r + .8 * u, Paint()..color = ink);
      c.drawCircle(at, r, Paint()..color = goldDeep);
      c.drawCircle(
        at + Offset(-.2 * u, -.25 * u),
        r * .88,
        Paint()..color = gold,
      );
      c.drawCircle(
        at,
        r * .58,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7 * u
          ..color = goldDeep,
      );
      c.drawCircle(
        at + Offset(-r * .35, -r * .38),
        r * .2,
        Paint()..color = goldLight,
      );
    } else if (fury) {
      c.drawCircle(at, r + .6 * u, Paint()..color = ink);
      c.drawCircle(at, r * .82, Paint()..color = _woodDeep);
      c.drawCircle(
        at,
        r * .82,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9 * u
          ..color = Color.lerp(_ember, cream, (1 - wave) * .5)!,
      );
    }
  }
}
