import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../ui/theme.dart';

/// The same cosmetic marks are used in flight and in the crew preview.
abstract final class BirdTrail {
  static const names = [
    'Sunshine bubbles',
    'Peach hearts',
    'Mint leaves',
    'Stardust sparkles',
  ];

  /// Trail length along the flown line, in units.
  static const _reach = 20.0;

  /// Marks are born this far back, still hidden under the bird's body.
  static const _born = 1.5;

  /// Given a [path] of the bird's recent positions, newest first, marks are
  /// dropped along the line it flew and continue level beyond it. [flown] is
  /// how far the bird has flown along that line, in pixels: marks stay where
  /// they were dropped while the bird flies on, instead of riding with it.
  static void paint(
    Canvas canvas, {
    required int bird,
    required Offset anchor,
    required double unit,
    double seconds = 0,
    bool animate = true,
    bool empowered = false,
    List<Offset>? path,
    double? flown,
  }) {
    if (!(unit > 0)) return;
    final time = animate ? seconds : 0.0;
    final track = _Track(
      path == null ? _row(anchor, unit, time) : [anchor, ...path],
    );
    final travelled = !animate
        ? 0.0
        : flown != null && path != null && path.isNotEmpty
        ? flown + (anchor - path.first).distance
        : seconds * unit * 30;
    final trail = _Trail(
      canvas,
      track,
      unit,
      time,
      travelled,
      empowered ? _golden : _tones[bird],
      glow: empowered,
    );
    switch (bird) {
      case 0:
        trail.bubbles();
      case 1:
        trail.hearts();
      case 2:
        trail.leaves();
      default:
        trail.stardust();
    }
  }

  /// A gently waving row for previews and Reduced Motion, settling into the
  /// bird's tail.
  static List<Offset> _row(Offset anchor, double unit, double time) => [
    for (var x = 0.0; x <= _reach + 2; x += .75)
      anchor +
          Offset(
            -x * unit,
            math.sin(x * .36 - time * 3) * unit * .6 * math.min(1, x / 7),
          ),
  ];

  static const _tones = [
    // Sunshine: butter yellow with a marigold rim.
    _Tone(Color(0xfffff6d8), SkyColors.yellow, SkyColors.gold),
    // Peach: Peaches' rosy pink over a deep rose shadow.
    _Tone(Color(0xffffe8ec), Color(0xffff8fa6), Color(0xffdd5a7a)),
    // Mint: Minty's fresh leaf face over its deeper leaf-green underside.
    _Tone(Color(0xffe6f8e6), Color(0xff8fdda3), Color(0xff45b88a)),
    // Stardust: white-hot core, Orbit's periwinkle light, deep indigo rim.
    _Tone(SkyColors.white, Color(0xffb4b2f7), Color(0xff6e73d6)),
  ];
  static const _golden = _Tone(
    SkyColors.cream,
    SkyColors.yellow,
    SkyColors.gold,
  );
}

class _Tone {
  const _Tone(this.light, this.body, this.deep);
  final Color light, body, deep;
}

/// A polyline measured by length from its first point.
class _Track {
  _Track(this.points) : lengths = List.filled(points.length, 0) {
    for (var i = 1; i < points.length; i++) {
      lengths[i] = lengths[i - 1] + (points[i] - points[i - 1]).distance;
    }
  }
  final List<Offset> points;
  final List<double> lengths;

  /// The point [length] along the line and the unit direction pointing
  /// further back. Past the end the line continues level.
  (Offset, Offset) at(double length) {
    final last = points.length - 1;
    if (length >= lengths[last]) {
      return (
        points[last] - Offset(length - lengths[last], 0),
        const Offset(-1, 0),
      );
    }
    var i = 0;
    while (lengths[i + 1] < length) {
      i++;
    }
    final a = points[i], b = points[i + 1];
    final gap = lengths[i + 1] - lengths[i];
    if (gap == 0) return (a, const Offset(-1, 0));
    return (Offset.lerp(a, b, (length - lengths[i]) / gap)!, (b - a) / gap);
  }
}

/// One frame of a trail: marks are dropped every few units of flight and
/// age as the bird leaves them behind.
class _Trail {
  _Trail(
    this.canvas,
    this.track,
    this.unit,
    this.time,
    this.travelled,
    this.tone, {
    required this.glow,
  });
  final Canvas canvas;
  final _Track track;
  final double unit, time, travelled;
  final _Tone tone;
  final bool glow;
  final fill = Paint(), glowing = Paint(), layer = Paint();
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  /// Calls [mark] for every mark dropped each [spacing] units, oldest first,
  /// with a stable id, its position, the backward direction and its age from
  /// 0 at birth to 1 when it has faded away.
  void drop(
    double spacing,
    void Function(int id, Offset at, Offset back, double age) mark, {
    double jitter = .25,
  }) {
    const born = BirdTrail._born, reach = BirdTrail._reach;
    final gone = travelled / unit;
    if (!gone.isFinite) return;
    final newest = ((gone - born) / spacing).floor() + 1;
    for (var id = ((gone - reach) / spacing).floor() - 1; id <= newest; id++) {
      final behind =
          gone - id * spacing + (noise(id, 7) - .5) * jitter * spacing;
      if (behind < born || behind > reach) continue;
      final (at, back) = track.at(behind * unit);
      mark(id, at, back, (behind - born) / (reach - born));
    }
  }

  /// A stable pseudo-random value in [0, 1) for a mark.
  static double noise(int id, int salt) {
    var x = (id * 0x27d4eb2d + salt * 0x165667b1) & 0xffffffff;
    x = ((x ^ (x >> 15)) * 0x2c1b3c6d) & 0xffffffff;
    x = ((x ^ (x >> 12)) * 0x297a2d39) & 0xffffffff;
    return (x ^ (x >> 15)) / 0x100000000;
  }

  /// Size over a mark's life: it swells out from under the bird, holds, then
  /// tapers to nothing so the oldest never pops out of sight.
  static double taper(double age) =>
      _ease(age / .16) * (1 - math.pow(age, 2.4));

  static double fade(double age) => 1 - _ease((age - .65) / .35);

  static double _ease(double t) {
    final u = t.clamp(0.0, 1.0);
    return u * u * (3 - 2 * u);
  }

  /// Sideways from the flown line, to the bird's left.
  static Offset side(Offset back) => Offset(back.dy, -back.dx);

  void halo(Offset at, double radius, Color color, double alpha) {
    canvas.drawCircle(
      at,
      radius,
      glowing
        ..shader = ui.Gradient.radial(at, radius, [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ]),
    );
  }

  /// Draws what [mark] paints as one piece at [alpha], so its layers do not
  /// show through each other. [reach] is the mark's extent in its own units.
  void translucent(double reach, double alpha, void Function() mark) {
    canvas.saveLayer(
      Rect.fromCircle(center: Offset.zero, radius: reach),
      layer..color = SkyColors.white.withValues(alpha: alpha),
    );
    mark();
    canvas.restore();
  }

  // Sunshine bubbles: soap bubbles with a sunny rim, clear in the middle so
  // they stay light over any sky, rising and wobbling as they drift away.
  void bubbles() {
    const rhythm = [1.0, .66, .88, .58];
    drop(2.4, (id, at, back, age) {
      final r =
          unit * 1.3 * rhythm[id % 4] * (.92 + noise(id, 1) * .16) * taper(age);
      if (r < .5) return;
      final a = .85 * fade(age);
      final sway =
          math.sin(age * 7 + noise(id, 2) * 6.3) * age * .35 +
          math.sin(time * 1.8 + id * 1.7) * .12;
      final c =
          at +
          side(back) * (noise(id, 3) - .5) * age * unit * 1.2 +
          Offset(sway * unit, -math.pow(age, 1.4) * unit * 1.8);
      if (glow) halo(c, r * 1.9, tone.body, .3 * fade(age));
      final wobble = math.sin(time * 5 + id * 2.1) * .025;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(1 + wobble, 1 - wobble);
      canvas.drawCircle(
        Offset.zero,
        r,
        fill
          ..shader = ui.Gradient.radial(
            Offset.zero,
            r,
            [
              tone.light.withValues(alpha: .3 * a),
              tone.light.withValues(alpha: .48 * a),
              tone.body.withValues(alpha: .95 * a),
              tone.deep.withValues(alpha: a),
            ],
            const [0, .5, .76, .96],
          ),
      );
      fill.shader = null;
      final sheen = Rect.fromCircle(center: Offset.zero, radius: r * .64);
      canvas.drawArc(
        sheen,
        3.5,
        1.0,
        false,
        line
          ..color = SkyColors.white.withValues(alpha: a)
          ..strokeWidth = r * .2,
      );
      canvas.drawCircle(
        Offset(r * .22, -r * .6),
        r * .1,
        fill..color = SkyColors.white.withValues(alpha: a),
      );
      canvas.drawArc(
        sheen,
        .3,
        .9,
        false,
        line
          ..color = SkyColors.white.withValues(alpha: .6 * a)
          ..strokeWidth = r * .1,
      );
      canvas.restore();
    });
  }

  static final _heart = Path()
    ..moveTo(0, .92)
    ..cubicTo(-.3, .66, -1, .22, -1, -.3)
    ..cubicTo(-1, -.9, -.32, -1.08, 0, -.56)
    ..cubicTo(.32, -1.08, 1, -.9, 1, -.3)
    ..cubicTo(1, .22, .3, .66, 0, .92)
    ..close();

  // Peach hearts: plump, glossy hearts that float up like released balloons,
  // rocking gently and beating in a ripple down the trail.
  void hearts() {
    const rhythm = [1.0, .7, .88, .62];
    drop(2.5, (id, at, back, age) {
      final f = ((time * .8 - id * .09) % 1 + 1) % 1;
      final beat =
          math.exp(-math.pow((f - .1) / .05, 2)) +
          .6 * math.exp(-math.pow((f - .28) / .05, 2));
      final r =
          unit *
          1.3 *
          rhythm[id % 4] *
          (.92 + noise(id, 1) * .16) *
          taper(age) *
          (1 + beat * .05);
      if (r < .5) return;
      final a = fade(age);
      final c =
          at +
          side(back) * (noise(id, 3) - .5) * age * unit +
          Offset(
            math.sin(age * 5 + noise(id, 2) * 6.3) * age * unit * .3,
            -math.pow(age, 1.3) * unit * 1.5,
          );
      if (glow) halo(c, r * 1.9, tone.body, .3 * a);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(
        (noise(id, 4) - .5) * .5 + math.sin(time * 1.6 + id * 1.3) * .08,
      );
      canvas.scale(r);
      translucent(1.3, .82 * a, () {
        canvas.drawPath(_heart, fill..color = tone.deep);
        canvas.save();
        canvas.translate(-.05, -.08);
        canvas.scale(.8);
        canvas.drawPath(_heart, fill..color = tone.body);
        canvas.restore();
        canvas.save();
        canvas.translate(-.46, -.36);
        canvas.rotate(-.75);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: .4, height: .2),
          fill..color = tone.light,
        );
        canvas.restore();
      });
      canvas.restore();
    });
  }

  static final _leaf = Path()
    ..moveTo(-1, 0)
    ..cubicTo(-.5, -.92, .5, -.84, 1, 0)
    ..cubicTo(.5, .78, -.5, .82, -1, 0)
    ..close();
  static final _leafFace = Path()
    ..moveTo(-1, 0)
    ..cubicTo(-.5, -.92, .5, -.84, 1, 0)
    ..quadraticBezierTo(0, .08, -1, 0)
    ..close();
  static final _vein = Path()
    ..moveTo(-.86, .02)
    ..quadraticBezierTo(0, .08, .8, 0);

  // Mint leaves: two-tone leaves that tumble and flutter down as they fall
  // behind, turning over to show their darker underside.
  void leaves() {
    const rhythm = [1.0, .74, .9, .66];
    drop(2.8, (id, at, back, age) {
      final r =
          unit *
          1.55 *
          rhythm[id % 4] *
          (.92 + noise(id, 1) * .16) *
          taper(age);
      if (r < .5) return;
      final a = fade(age);
      final c =
          at +
          side(back) * (noise(id, 3) - .5) * (.5 + age) * unit +
          Offset(
            math.sin(age * 5 + noise(id, 2) * 6.3) * age * unit * .45,
            math.pow(age, 1.3) * unit * 1.3,
          );
      final spin = noise(id, 5) - .5;
      final turn = math.cos(
        age * (3 + spin * 3) + noise(id, 6) * 6.3 + time * 1.2,
      );
      final under = turn < 0;
      if (glow) halo(c, r * 1.7, tone.body, .3 * a);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(
        math.atan2(back.dy, back.dx) +
            (noise(id, 4) - .5) * 1.8 +
            age * spin * 3 +
            math.sin(time * 1.8 + id * 1.9) * .12,
      );
      canvas.scale(r, r * (.7 + .3 * turn.abs()) * (under ? -1 : 1));
      translucent(1.4, .9 * a, () {
        canvas.drawLine(
          const Offset(-.9, 0),
          const Offset(-1.3, .16),
          line
            ..color = tone.deep
            ..strokeWidth = .14,
        );
        canvas.drawPath(_leaf, fill..color = tone.deep);
        // The face darkens over the turn instead of switching colour.
        canvas.drawPath(
          _leafFace,
          fill
            ..color = Color.lerp(
              tone.body,
              tone.deep,
              .45 * _ease(.5 - turn * 2.5),
            )!,
        );
        canvas.drawPath(
          _vein,
          line
            ..color = tone.light.withValues(alpha: .9)
            ..strokeWidth = .1,
        );
      });
      canvas.restore();
    });
  }

  static final _glint = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(.16, -.16, 1, 0)
    ..quadraticBezierTo(.16, .16, 0, 1)
    ..quadraticBezierTo(-.16, .16, -1, 0)
    ..quadraticBezierTo(-.16, -.16, 0, -1)
    ..close();
  static final _flare = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(.03, -.03, 1, 0)
    ..quadraticBezierTo(.03, .03, 0, 1)
    ..quadraticBezierTo(-.03, .03, -1, 0)
    ..quadraticBezierTo(-.03, -.03, 0, -1)
    ..close();

  static const _dust = [
    SkyColors.white,
    Color(0xffffd6ec),
    SkyColors.lavender,
    Color(0xffc9f1ff),
  ];

  // Stardust: a faint comet tail along the flown line, iridescent dust and
  // softly twinkling four-point glints. Four points and violet light keep it
  // apart from the gold five-point stars the player collects.
  void stardust() {
    final tail = [
      for (var s = BirdTrail._born; s <= 14; s += .8) track.at(s * unit).$1,
    ];
    for (final (share, width) in const [(1.0, .5), (.7, .9), (.42, 1.3)]) {
      final comet = Path()..moveTo(tail.first.dx, tail.first.dy);
      for (final p in tail.take((tail.length * share).ceil()).skip(1)) {
        comet.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        comet,
        line
          ..color = tone.body.withValues(alpha: .08)
          ..strokeWidth = width * unit
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drop(1.2, (id, at, back, age) {
      final r =
          unit * (.16 + noise(id, 11) * .2) * math.min(1, (1 - age) * 2.5);
      final twinkle = .75 + .25 * math.sin(time * 2.4 + noise(id, 12) * 6.3);
      final c =
          at + side(back) * (noise(id, 13) - .5) * unit * (1.4 + age * 2.8);
      fill.color = (glow ? tone.light : _dust[id % 4]).withValues(
        alpha: .7 * twinkle * fade(age),
      );
      if (id % 3 != 0 || r < 1) {
        canvas.drawCircle(c, r, fill);
        return;
      }
      // Every third mote is a tiny glint of its own.
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(r * 1.9);
      canvas.drawPath(_glint, fill);
      canvas.restore();
    }, jitter: .6);

    const rhythm = [1.0, .62, .86, .56];
    drop(2.7, (id, at, back, age) {
      final twinkle = .5 + .5 * math.sin(time * 2.6 + noise(id, 1) * 6.3);
      final r =
          unit * 1.55 * rhythm[id % 4] * taper(age) * (.94 + twinkle * .12);
      if (r < .5) return;
      final a = fade(age);
      final c = at + side(back) * (noise(id, 3) - .5) * age * unit * 1.5;
      halo(c, r * 1.9, tone.body, .22 * a);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate((noise(id, 4) - .5) * .5 + time * (noise(id, 5) - .5) * .4);
      canvas.scale(r);
      if (r < unit * .75) {
        // Rim and core would blur into a little square this small.
        canvas.drawPath(
          _glint,
          fill
            ..color = Color.lerp(
              tone.body,
              tone.light,
              .35,
            )!.withValues(alpha: .8 * a),
        );
      } else {
        translucent(1.3, .8 * a, () {
          canvas.save();
          canvas.scale(1.12);
          canvas.drawPath(
            _glint,
            fill..color = tone.deep.withValues(alpha: .9),
          );
          canvas.restore();
          canvas.drawPath(_glint, fill..color = tone.body);
          canvas.save();
          canvas.scale(.5);
          canvas.drawPath(_glint, fill..color = tone.light);
          canvas.restore();
        });
      }
      canvas.restore();
      // Now and then a glint slowly swells a fine cross of light, each on its
      // own beat and only some of them, so one at most catches the eye.
      final beat = (time * .35 + noise(id, 8)) % 1;
      if (beat < .3 && noise(id, 9) < .5) {
        final flare = math.sin(beat / .3 * math.pi) * a;
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.scale(r * (1 + .3 * flare));
        canvas.drawPath(
          _flare,
          fill..color = tone.light.withValues(alpha: .45 * flare),
        );
        canvas.restore();
      }
    });
  }
}
