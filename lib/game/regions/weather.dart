import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'world_region.dart';

/// Particle kinds a region can blow across its backdrop. [drizzle] is fine
/// rain tinted by neon light and [data] the glowing pixels that drift up
/// through a cyberpunk city.
enum Mote { sand, snow, leaf, firefly, petal, rain, spray, drizzle, data }

/// A region's weather: a fixed list of slots, each holding one mote kind.
///
/// Every slot has seeded constants, so positions are pure functions of the
/// replay clock and flown distance. During a crossing each slot hands over at
/// its own seeded moment: the old mote shrinks away while the new one grows
/// in, so sand thins into snow instead of switching all at once.
class Weather {
  const Weather(this.motes);

  /// Slot kinds in order; slots past the end stay empty.
  final List<Mote> motes;

  static const slots = 40;

  static List<Mote> of(List<(Mote, int)> spec) => [
    for (final (kind, count) in spec) ...List.filled(count, kind),
  ];

  static final _leaf = Path()
    ..moveTo(-1, 0)
    ..quadraticBezierTo(-.2, -.62, 1, 0)
    ..quadraticBezierTo(-.2, .62, -1, 0)
    ..close();

  static final _petal = Path()
    ..moveTo(-1, 0)
    ..cubicTo(-.6, -.75, .55, -.7, 1, -.08)
    ..cubicTo(.55, .5, -.5, .62, -1, 0)
    ..close();

  static void paint(Canvas c, SceneFrame f, Weather a, Weather b, double t) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < slots; i++) {
      final from = i < a.motes.length ? a.motes[i] : null;
      final to = i < b.motes.length ? b.motes[i] : null;
      if (t <= 0 || from == to) {
        if (from != null) _mote(c, f, paint, from, i, 1);
        continue;
      }
      final turn = .2 + .6 * Sketch.hash(i * 7 + 3);
      final grow = RegionBlend.smooth((t - turn) / .14 + .5);
      if (from != null && grow < 1) _mote(c, f, paint, from, i, 1 - grow);
      if (to != null && grow > 0) _mote(c, f, paint, to, i, grow);
    }
  }

  static double _wrap(double v, double span) => ((v % span) + span) % span;

  static void _mote(
    Canvas c,
    SceneFrame f,
    Paint paint,
    Mote kind,
    int i,
    double scale,
  ) {
    final w = f.w, h = f.h;
    final time = f.clock;
    final travel = f.reducedMotion ? 0.0 : f.distance * h;
    final r1 = Sketch.hash(i * 3 + 11);
    final r2 = Sketch.hash(i * 3 + 12);
    final z = Sketch.hash(i * 3 + 13);
    final margin = h * .12;
    final spanX = w + margin * 2;
    switch (kind) {
      case Mote.sand:
        // Wind-blown grains: short streaks hurrying low across the dunes.
        final speed = h * (.5 + .45 * z);
        final x =
            _wrap(r1 * spanX - time * speed - travel * .25, spanX) - margin;
        // Grains keep low over the dunes; the nearest ride a little higher.
        final y =
            h * (.62 + .34 * r2 - .18 * z * z) +
            math.sin(time * 1.7 + i) * h * .012;
        final len = h * (.01 + .02 * z) * scale;
        paint
          ..color = Sketch.fade(const Color(0xfff9e2b4), (.3 + .35 * z) * scale)
          ..strokeWidth = .8 + z * 1.2;
        c.drawLine(Offset(x, y), Offset(x + len, y - len * .1), paint);
      case Mote.snow:
        final fall = h * (.03 + .05 * z);
        final spanY = h + margin * 2;
        final y = _wrap(r2 * spanY + time * fall, spanY) - margin;
        final x =
            _wrap(
              r1 * spanX -
                  time * h * (.02 + .03 * z) -
                  travel * (.06 + .12 * z) +
                  math.sin(time * .8 + i * 1.9) * h * .016,
              spanX,
            ) -
            margin;
        paint.color = Sketch.fade(const Color(0xffffffff), (.62 + .3 * z));
        c.drawCircle(Offset(x, y), h * (.0028 + .0048 * z) * scale, paint);
      case Mote.leaf || Mote.petal:
        final petal = kind == Mote.petal;
        final fall = h * (petal ? .05 + .04 * z : .04 + .03 * z);
        final spanY = h + margin * 2;
        final y = _wrap(r2 * spanY + time * fall, spanY) - margin;
        final sway = math.sin(time * (petal ? 1.3 : .9) + i * 2.3);
        final x =
            _wrap(
              r1 * spanX -
                  time * h * (petal ? .06 : .035) -
                  travel * (.1 + .12 * z) +
                  sway * h * (petal ? .03 : .045),
              spanX,
            ) -
            margin;
        final size = h * (petal ? .007 + .005 * z : .011 + .007 * z) * scale;
        final color = petal
            ? (i.isEven ? const Color(0xfff7c6d3) : const Color(0xffffe6ea))
            : switch (i % 3) {
                0 => const Color(0xff7fbf6a),
                1 => const Color(0xffc9c35a),
                _ => const Color(0xff4f9a64),
              };
        paint.color = Sketch.fade(color, .9);
        c.save();
        c.translate(x, y);
        c.rotate(time * (petal ? 1.6 : 1.1) * (i.isEven ? 1 : -1) + i);
        c.scale(size, size * (.55 + .45 * sway.abs()));
        c.drawPath(petal ? _petal : _leaf, paint);
        c.restore();
      case Mote.firefly:
        // Fireflies wander in the shaded understory and pulse softly.
        final ax = _wrap(r1 * spanX - travel * .14, spanX) - margin;
        final x = ax + math.sin(time * .7 + i * 1.3) * h * .05;
        final y = h * (.5 + .42 * r2) + math.sin(time * .9 + i * 2.1) * h * .03;
        final pulse = .55 + .45 * math.sin(time * 2.2 + i * 1.7);
        paint.color = Sketch.fade(const Color(0xfff4ff9a), .2 * pulse * scale);
        c.drawCircle(Offset(x, y), h * .016 * scale, paint);
        paint.color = Sketch.fade(const Color(0xfffcffd0), .9 * pulse);
        c.drawCircle(Offset(x, y), h * .0042 * scale, paint);
      case Mote.rain:
        final fall = h * (1.3 + .5 * z);
        final spanY = h + margin * 2;
        final y = _wrap(r2 * spanY + time * fall, spanY) - margin;
        final x =
            _wrap(r1 * spanX - time * h * .22 - travel * .2, spanX) - margin;
        final len = h * (.035 + .03 * z) * scale;
        paint
          ..color = Sketch.fade(const Color(0xffc9d6f2), .22 + .18 * z)
          ..strokeWidth = .9 + z * .6;
        c.drawLine(Offset(x, y), Offset(x - len * .2, y + len), paint);
      case Mote.drizzle:
        // Fine, fast rain: most drops catch the city's pale light, some the
        // cyan and magenta of the signs they fall past.
        final fall = h * (1.1 + .45 * z);
        final spanY = h + margin * 2;
        final y = _wrap(r2 * spanY + time * fall, spanY) - margin;
        final x =
            _wrap(r1 * spanX - time * h * .15 - travel * .22, spanX) - margin;
        final len = h * (.018 + .02 * z) * scale;
        final tint = switch (i % 5) {
          0 => const Color(0xff8ff4ff),
          1 => const Color(0xffff9fdc),
          _ => const Color(0xffd6d8f8),
        };
        paint
          ..color = Sketch.fade(tint, .2 + .24 * z)
          ..strokeWidth = .7 + z * .5;
        c.drawLine(Offset(x, y), Offset(x - len * .14, y + len), paint);
      case Mote.data:
        // Data motes: square pixels rising slowly on the warm air of the
        // streets, blinking in steps like a signal refreshing.
        final rise = h * (.022 + .03 * z);
        final spanY = h + margin * 2;
        final y = spanY - _wrap(r2 * spanY + time * rise, spanY) - margin;
        final x =
            _wrap(
              r1 * spanX -
                  time * h * .018 -
                  travel * (.08 + .1 * z) +
                  math.sin(time * .7 + i * 2.1) * h * .012,
              spanX,
            ) -
            margin;
        final on = Sketch.hash(i * 31 + (time * 2.5 + i * .37).floor()) > .3;
        final tint = switch (i % 3) {
          0 => const Color(0xff6ff6ff),
          1 => const Color(0xffd4ff5a),
          _ => const Color(0xffff6fd0),
        };
        final side = h * (.0034 + .003 * z) * scale;
        paint.color = Sketch.fade(tint, (on ? .16 : .05) * scale);
        c.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: side * 3.4,
            height: side * 3.4,
          ),
          paint,
        );
        paint.color = Sketch.fade(tint, on ? .9 : .3);
        c.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: side, height: side),
          paint,
        );
      case Mote.spray:
        // Droplets flung from the swells arc up and fall back.
        final period = 1.4 + z * 1.2;
        final age = _wrap(time + r1 * period, period) / period;
        final anchor = _wrap(r1 * 977 * h - travel * .5, spanX) - margin;
        final x = anchor - age * h * .06;
        final y =
            h * (.93 - .08 * r2) -
            math.sin(age * math.pi) * h * (.06 + .06 * z);
        paint.color = Sketch.fade(
          const Color(0xfff4fbff),
          (.75 * (1 - age * age)) * scale,
        );
        c.drawCircle(Offset(x, y), h * (.003 + .003 * z) * scale, paint);
    }
  }
}
