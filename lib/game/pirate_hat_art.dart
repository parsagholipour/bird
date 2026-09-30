import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'pirate_boss_rig.dart';

/// The Pirate Captain's plumed tricorn: a dark felt crown pinched into a
/// crease, a wide brim turned up into three corners (a raised point at each
/// side and a low one over the brow), gold braid wrapping its whole edge, a
/// cockade pinning a two-feather plume, and a skull and crossbones on the
/// front fold.
///
/// Authored around the hat's own seat in hit-radius units, facing left. It is
/// drawn on the captain's head and, on its own, tumbling free in the defeat.
/// Every path, gradient and paint is built once; a frame only replays them.
abstract final class PirateHatArt {
  static const _ink = PirateBossRig.ink;
  static const _felt = Color(0xff2d2942), _feltLit = Color(0xff5a5584);
  static const _feltDeep = Color(0xff171422), _feltMid = Color(0xff3b3656);
  static const _feltFury = Color(0xff8a4a70);
  static const _lining = Color(0xff7a2b4d), _liningFury = Color(0xffb02a3a);
  static const _gold = PirateBossRig.gold;
  static const _goldDeep = Color(0xffc9862b), _goldLight = Color(0xfffff0b4);
  static const _emberGold = Color(0xffff8a3a), _emberDeep = Color(0xffc23a26);
  static const _emberLight = Color(0xffffc48a), _ember = Color(0xffff5a3a);
  static const _bone = Color(0xfffff4dd), _boneShade = Color(0xffe6cfa6);
  static const _boneDeep = Color(0xffbf9c72);
  static const _plumeDeep = Color(0xff8a2440), _plumeRed = Color(0xffe44a5c);
  static const _plumeLit = Color(0xffffa59a), _plumeTip = Color(0xffffd3bd);
  static const _fluffTeal = Color(0xff2e9fa0), _fluffLit = Color(0xff8ff0dc);
  static const _fluffDeep = Color(0xff1d6577);

  /// Everything the hat can reach, plume and tumble included.
  static const bounds = Rect.fromLTRB(-1.25, -1.75, 1.95, .35);

  /// Where the plume and cockade are pinned to the crown.
  static const _pin = Offset(.5, -.4);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// A gradient from point [a] to point [b], across [rect].
  static Paint _along(
    Rect rect,
    Offset a,
    Offset b,
    List<Color> colors, {
    List<double>? stops,
  }) {
    Alignment at(Offset p) => Alignment(
      (p.dx - rect.center.dx) / (rect.width / 2),
      (p.dy - rect.center.dy) / (rect.height / 2),
    );
    return Paint()
      ..shader = LinearGradient(
        begin: at(a),
        end: at(b),
        colors: colors,
        stops: stops,
      ).createShader(rect);
  }

  /// The tricorn. [fury] reddens the trim and ruffles the plume, [sway]
  /// (radians) swings the feathers about their pin, and [glint] (0 to 1)
  /// flashes the braid. A hat that is [worn] casts its shadow on the brow.
  static void paint(
    Canvas c, {
    bool fury = false,
    double sway = 0,
    double glint = 0,
    bool worn = true,
  }) {
    final look = fury ? 1 : 0;
    _plumes(c, look, sway);
    _crown(c, look);
    _brim(c, look, worn);
    _cockade(c, look);
    _skull(c, const Offset(-.09, -.17), .225, fury);
    if (glint > .01) {
      _sparkle(c, const Offset(-1.0, -.7), .14 * glint);
      if (fury) _sparkle(c, const Offset(1.1, -.68), .09 * glint);
    }
  }

  // ----------------------------------------------------------- feathers --

  // Calm and ruffled plumes, and the smaller feather that lags behind them.
  static final _plume = [
    _feather(
      root: _pin,
      c1: const Offset(.72, -1.02),
      c2: const Offset(1.32, -1.18),
      tip: const Offset(1.66, -.62),
      width: .28,
      barbs: 10,
      ruffle: 0,
      colors: const [_plumeDeep, _plumeRed, _plumeLit, _plumeTip],
    ),
    _feather(
      root: _pin,
      c1: const Offset(.72, -1.02),
      c2: const Offset(1.32, -1.18),
      tip: const Offset(1.66, -.62),
      width: .28,
      barbs: 10,
      ruffle: 1,
      colors: const [_plumeDeep, _ember, _emberGold, _plumeTip],
    ),
  ];
  static final _fluff = [
    _feather(
      root: _pin,
      c1: const Offset(.36, -1.0),
      c2: const Offset(.86, -1.34),
      tip: const Offset(1.3, -1.1),
      width: .17,
      barbs: 8,
      ruffle: 0,
      colors: const [_fluffDeep, _fluffTeal, _fluffLit],
    ),
    _feather(
      root: _pin,
      c1: const Offset(.36, -1.0),
      c2: const Offset(.86, -1.34),
      tip: const Offset(1.3, -1.1),
      width: .17,
      barbs: 8,
      ruffle: 1,
      colors: const [_emberDeep, _emberGold, _goldLight],
    ),
  ];

  static final _featherInk = _line(_ink, .07);
  static final _fluffInk = _line(_ink, .06);
  static final _featherShade = _line(_plumeDeep.withValues(alpha: .5), .02);
  static final _featherQuillInk = _line(_ink.withValues(alpha: .55), .038);
  static final _featherQuill = _line(_bone.withValues(alpha: .95), .02);

  /// A curled ostrich feather: a bowed quill with a vane of soft lobes that
  /// all sweep toward the tip. [ruffle] splits and roughens it for the fury.
  static _Feather _feather({
    required Offset root,
    required Offset c1,
    required Offset c2,
    required Offset tip,
    required double width,
    required int barbs,
    required double ruffle,
    required List<Color> colors,
  }) {
    Offset at(double t) {
      final u = 1 - t;
      return root * (u * u * u) +
          c1 * (3 * u * u * t) +
          c2 * (3 * u * t * t) +
          tip * (t * t * t);
    }

    Offset tangent(double t) {
      final u = 1 - t;
      final d =
          (c1 - root) * (3 * u * u) +
          (c2 - c1) * (6 * u * t) +
          (tip - c2) * (3 * t * t);
      return d / d.distance;
    }

    Offset normal(double t) {
      final d = tangent(t);
      return Offset(-d.dy, d.dx);
    }

    double vane(double t) =>
        width * math.pow(math.sin(math.pi * math.min(t * 1.04, 1)), .7);

    // One lobe per barb group: a notch, then a curve swelling out to a
    // swept tip.
    final n = barbs + .4;
    Offset notch(int i, int side) {
      final t = (i + .1) / n;
      return at(t) + normal(t) * (side * vane(t) * (.55 - ruffle * .22));
    }

    Offset lobeTip(int i, int side) {
      final t = (i + 1.0) / n;
      final len =
          1 +
          ruffle * .3 * (i.isEven ? 1 : -.4) +
          .06 * math.sin(i * 2.7 + side);
      return at(t) +
          normal(t) * (side * vane(t) * len) +
          tangent(t) * (vane(t) * (.3 + ruffle * .35));
    }

    Offset lobeBulge(int i, int side) {
      final t = (i + .5) / n;
      return at(t) + normal(t) * (side * vane(t) * (1.18 + ruffle * .1));
    }

    final body = Path()..moveTo(root.dx, root.dy);
    for (var i = 0; i < barbs; i++) {
      final k = notch(i, 1), b = lobeBulge(i, 1), e = lobeTip(i, 1);
      body
        ..lineTo(k.dx, k.dy)
        ..quadraticBezierTo(b.dx, b.dy, e.dx, e.dy);
    }
    final end = at(1) + tangent(1) * .06;
    body.lineTo(end.dx, end.dy);
    for (var i = barbs - 1; i >= 0; i--) {
      final k = notch(i, -1), b = lobeBulge(i, -1), e = lobeTip(i, -1);
      body
        ..lineTo(e.dx, e.dy)
        ..quadraticBezierTo(b.dx, b.dy, k.dx, k.dy);
    }
    body.close();
    final lit = Path(),
        shade = Path(),
        quill = Path()..moveTo(root.dx, root.dy);
    for (var i = 0; i < barbs; i++) {
      final spine = at((i + .3) / n);
      for (final side in [1, -1]) {
        final e = lobeTip(i, side), k = notch(i, side);
        final bow = tangent((i + .5) / n) * .03;
        final to = Offset.lerp(spine, e, .88)!;
        lit
          ..moveTo(spine.dx, spine.dy)
          ..quadraticBezierTo(
            (spine.dx + e.dx) / 2 + bow.dx,
            (spine.dy + e.dy) / 2 + bow.dy,
            to.dx,
            to.dy,
          );
        final inner = Offset.lerp(k, spine, .5)!;
        shade
          ..moveTo(k.dx, k.dy)
          ..lineTo(inner.dx, inner.dy);
      }
    }
    for (var i = 1; i <= 16; i++) {
      final p = at(i / 16 * .97);
      quill.lineTo(p.dx, p.dy);
    }
    final rect = body.getBounds();
    return _Feather(
      body,
      lit,
      shade,
      quill,
      _along(rect, root, at(1), colors),
      _line(colors.last.withValues(alpha: .7), .016),
    );
  }

  static void _drawFeather(Canvas c, _Feather f, Paint ink) {
    c.drawPath(f.body, ink);
    c.drawPath(f.body, f.fill);
    c.drawPath(f.shade, _featherShade);
    c.drawPath(f.lit, f.litLine);
    c.drawPath(f.quill, _featherQuillInk);
    c.drawPath(f.quill, _featherQuill);
  }

  static void _plumes(Canvas c, int look, double sway) {
    // The small feather lags behind the big one, so the plume ripples.
    c.save();
    c.translate(_pin.dx, _pin.dy);
    c.rotate(sway * 1.5 - .04);
    c.translate(-_pin.dx, -_pin.dy);
    _drawFeather(c, _fluff[look], _fluffInk);
    c.restore();
    c.save();
    c.translate(_pin.dx, _pin.dy);
    c.rotate(sway);
    c.translate(-_pin.dx, -_pin.dy);
    _drawFeather(c, _plume[look], _featherInk);
    c.restore();
  }

  // -------------------------------------------------------------- crown --

  static final _crownPath = Path()
    ..moveTo(-.54, -.1)
    ..cubicTo(-.62, -.5, -.38, -.72, .02, -.73)
    ..cubicTo(.4, -.74, .7, -.56, .64, -.1)
    ..close();
  static final _crownInk = _line(_ink, .1);
  static final _crownFill = [
    _along(
      _crownPath.getBounds(),
      _crownPath.getBounds().topLeft,
      _crownPath.getBounds().bottomRight,
      const [_feltLit, _felt, _feltDeep],
      stops: const [0, .5, 1],
    ),
    _along(
      _crownPath.getBounds(),
      _crownPath.getBounds().topLeft,
      _crownPath.getBounds().bottomRight,
      [Color.lerp(_feltLit, _feltFury, .55)!, _felt, _feltDeep],
      stops: const [0, .5, 1],
    ),
  ];
  // A soft pinch down the front of the crown, and the sheen on the dome.
  static final _crease = Path()
    ..moveTo(.02, -.7)
    ..quadraticBezierTo(-.04, -.58, -.06, -.4);
  static final _creaseShade = _line(_feltDeep.withValues(alpha: .38), .06);
  static final _creaseLit = _line(_feltLit.withValues(alpha: .5), .026);
  static final _sheen = Path()
    ..moveTo(-.47, -.4)
    ..quadraticBezierTo(-.42, -.6, -.2, -.67);
  static final _sheenLit = _line(_feltLit.withValues(alpha: .9), .05);
  // A stitched patch: he has seen some weather.
  static final _patch = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: .19, height: .14),
    const Radius.circular(.018),
  );
  static final _patchStitches = _dashes(
    Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: .15, height: .1),
        const Radius.circular(.01),
      ),
    ),
    .028,
    .022,
  );
  static final _patchInk = _line(_ink, .05);
  static final _patchFill = _fill(const Color(0xff8d7a5c));
  static final _patchThread = _line(const Color(0xffefdcb0), .014);

  static void _crown(Canvas c, int look) {
    c.drawPath(_crownPath, _crownInk);
    c.drawPath(_crownPath, _crownFill[look]);
    c.drawPath(_crease, _creaseShade);
    c.drawPath(_crease.shift(const Offset(-.045, 0)), _creaseLit);
    c.drawPath(_sheen, _sheenLit);
    c.save();
    c.translate(.27, -.55);
    c.rotate(.25);
    c.drawRRect(_patch, _patchInk);
    c.drawRRect(_patch, _patchFill);
    c.drawPath(_patchStitches, _patchThread);
    c.restore();
  }

  // --------------------------------------------------------------- brim --

  static const _tipL = Offset(-1.04, -.74), _tipR = Offset(1.16, -.72);

  // The near corner: a wing folded up beside the crown.
  static final _leftFlap = Path()
    ..moveTo(-1.04, -.74)
    ..cubicTo(-1.14, -.32, -.98, .0, -.58, .06)
    ..lineTo(-.2, .0)
    ..lineTo(-.3, -.36)
    ..lineTo(-.64, -.34)
    ..cubicTo(-.8, -.44, -.92, -.56, -1.04, -.74)
    ..close();
  // The far corner, turned away from the light.
  static final _rightFlap = Path()
    ..moveTo(1.16, -.72)
    ..cubicTo(1.26, -.3, 1.0, -.02, .4, .08)
    ..lineTo(.1, .02)
    ..lineTo(.1, -.32)
    ..lineTo(.5, -.32)
    ..cubicTo(.84, -.42, 1.02, -.55, 1.16, -.72)
    ..close();
  // The braided raised edge of each corner.
  static final _rims = Path()
    ..moveTo(-1.04, -.74)
    ..cubicTo(-.92, -.56, -.8, -.44, -.64, -.34)
    ..moveTo(1.16, -.72)
    ..cubicTo(1.02, -.55, .84, -.42, .5, -.32);
  // The brim's lower edge, corner to corner.
  static final _lowerEdge = Path()
    ..moveTo(-1.04, -.74)
    ..cubicTo(-1.14, -.32, -.98, .0, -.58, .06)
    ..cubicTo(-.2, .14, .2, .14, .4, .08)
    ..cubicTo(1.0, -.02, 1.26, -.3, 1.16, -.72);
  static final _panelBottom = Path()
    ..moveTo(-.58, .06)
    ..cubicTo(-.2, .14, .2, .14, .4, .08);

  // The front panel: the brim folded up flat against the crown.
  static final _panel = Path()
    ..moveTo(-.66, -.36)
    ..cubicTo(-.4, -.52, .16, -.52, .5, -.32)
    ..cubicTo(.6, -.2, .56, -.02, .4, .08)
    ..cubicTo(.2, .14, -.2, .14, -.58, .06)
    ..cubicTo(-.68, -.06, -.7, -.22, -.66, -.36)
    ..close();
  static final _topEdge = Path()
    ..moveTo(-.66, -.36)
    ..cubicTo(-.4, -.52, .16, -.52, .5, -.32);

  /// The lining under a turned-up edge: a band [from] to [to] below the rim
  /// that runs a to b.
  static Path _band(
    Offset a,
    Offset c1,
    Offset c2,
    Offset b,
    double from,
    double to,
  ) {
    Offset d(Offset p, double y) => p + Offset(0, y);
    return Path()
      ..moveTo(a.dx, a.dy + from)
      ..cubicTo(c1.dx, c1.dy + from, c2.dx, c2.dy + from, b.dx, b.dy + from)
      ..lineTo(b.dx, b.dy + to)
      ..cubicTo(c2.dx, c2.dy + to, c1.dx, c1.dy + to, d(a, to).dx, d(a, to).dy)
      ..close();
  }

  static final _leftRim = [
    const Offset(-1.04, -.74),
    const Offset(-.92, -.56),
    const Offset(-.8, -.44),
    const Offset(-.64, -.34),
  ];
  static final _rightRim = [
    const Offset(1.16, -.72),
    const Offset(1.02, -.55),
    const Offset(.84, -.42),
    const Offset(.5, -.32),
  ];
  static final _liningBand = [
    for (final r in [_leftRim, _rightRim])
      Path()..addPath(_band(r[0], r[1], r[2], r[3], 0, .075), Offset.zero),
  ];
  static final _liningShadeBand = [
    for (final r in [_leftRim, _rightRim])
      Path()..addPath(_band(r[0], r[1], r[2], r[3], .075, .15), Offset.zero),
  ];

  static final _flapInk = _line(_ink, .1);
  static final _leftFlapFill = _along(
    _leftFlap.getBounds(),
    _leftFlap.getBounds().topCenter,
    _leftFlap.getBounds().bottomCenter,
    const [_feltMid, _felt],
  );
  static final _rightFlapFill = _along(
    _rightFlap.getBounds(),
    _rightFlap.getBounds().topCenter,
    _rightFlap.getBounds().bottomCenter,
    const [_felt, _feltDeep],
  );
  static final _liningFill = [_fill(_lining), _fill(_liningFury)];
  static final _liningShadeFill = _fill(_feltDeep.withValues(alpha: .5));
  static final _panelFill = [
    _along(
      _panel.getBounds(),
      _panel.getBounds().topLeft,
      _panel.getBounds().bottomRight,
      const [_feltLit, _felt, _feltDeep],
      stops: const [0, .55, 1],
    ),
    _along(
      _panel.getBounds(),
      _panel.getBounds().topLeft,
      _panel.getBounds().bottomRight,
      [Color.lerp(_feltLit, _feltFury, .55)!, _felt, _feltDeep],
      stops: const [0, .55, 1],
    ),
  ];
  static final _panelLip = _line(_feltLit.withValues(alpha: .75), .03);
  static final _stitchLine = _line(_goldLight.withValues(alpha: .6), .016);
  static final _stitches = _dashes(
    _topEdge.shift(const Offset(0, .045)),
    .045,
    .04,
  );
  static final _browShadow = _line(_ink.withValues(alpha: .24), .1);

  // Felt nap: worn, lighter fibres and dark scuffs scattered over the crown
  // and front panel, placed by a fixed hash.
  static final _napLit = Path(), _napDark = Path();
  static final _napPaints = () {
    for (var i = 0; i < 26; i++) {
      final crown = i < 10;
      final h1 = _hash(i * 3 + 1), h2 = _hash(i * 3 + 2), h3 = _hash(i * 3 + 3);
      final x = crown ? -.42 + h1 * .56 : -.56 + h1 * .5;
      final y = crown ? -.68 + h2 * .16 : -.27 + h2 * .27;
      final len = .04 + h3 * .05, tilt = -.5 + h1 * .4;
      final to = Offset(x + math.cos(tilt) * len, y + math.sin(tilt) * len);
      final path = i.isEven ? _napLit : _napDark;
      path
        ..moveTo(x, y)
        ..lineTo(to.dx, to.dy);
    }
    return (
      _line(_feltLit.withValues(alpha: .38), .014),
      _line(_feltDeep.withValues(alpha: .4), .016),
    );
  }();

  // A ragged bullet hole through the near corner, with frayed felt.
  static final _hole = () {
    const at = Offset(-.86, -.22);
    const radii = [.05, .027, .042, .03, .056, .025, .04, .033];
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * math.pi * 2 + .3 + (i % 3) * .08;
      final q = at + Offset(math.cos(a), math.sin(a)) * radii[i];
      if (i == 0) {
        p.moveTo(q.dx, q.dy);
      } else {
        p.lineTo(q.dx, q.dy);
      }
    }
    return p..close();
  }();
  static final _holeFray = Path()
    ..moveTo(-.9, -.29)
    ..lineTo(-.92, -.33)
    ..moveTo(-.8, -.25)
    ..lineTo(-.76, -.27)
    ..moveTo(-.84, -.15)
    ..lineTo(-.85, -.11);
  static final _holeFrayLine = _line(_feltLit.withValues(alpha: .55), .014);
  static final _holeFill = _fill(_ink);

  // Braid: the diagonal twist ticks are laid out once along the edge.
  static final _braidTicks = _ticks(
    Path()
      ..addPath(_lowerEdge, Offset.zero)
      ..addPath(_rims, Offset.zero),
    .07,
    .036,
  );
  static final _braid = [
    _Braid(_line(_ink, .115), _line(_goldDeep, .078), _line(_gold, .062)),
    _Braid(_line(_ink, .115), _line(_emberDeep, .078), _line(_emberGold, .062)),
  ];
  static final _braidTick = [
    _line(_goldDeep.withValues(alpha: .85), .014),
    _line(_emberDeep.withValues(alpha: .85), .014),
  ];
  static final _braidGleam = [
    _line(_goldLight.withValues(alpha: .6), .014),
    _line(_emberLight.withValues(alpha: .6), .014),
  ];
  static final _lowerGleam = _lowerEdge.shift(const Offset(0, -.014));

  static Path _dashes(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        out.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
      }
    }
    return out;
  }

  static Path _ticks(Path source, double step, double half) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      for (var d = step / 2; d < metric.length; d += step) {
        final t = metric.getTangentForOffset(d);
        if (t == null) continue;
        final v = t.vector, n = Offset(-v.dy, v.dx);
        final a = t.position - n * half + v * (half * .8);
        final b = t.position + n * half - v * (half * .8);
        out
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy);
      }
    }
    return out;
  }

  /// A fixed pseudo-random number in [0, 1) for [i].
  static double _hash(int i) {
    final v = math.sin(i * 12.9898 + 4.1414) * 43758.5453;
    return v - v.floorToDouble();
  }

  // A soft fold running down each turned-up corner: lit on the near one.
  static final _foldLeft = Path()
    ..moveTo(-.99, -.6)
    ..cubicTo(-1.03, -.34, -.92, -.1, -.66, -.03);
  static final _foldRight = Path()
    ..moveTo(1.1, -.58)
    ..cubicTo(1.14, -.3, .96, -.06, .6, .02);
  static final _foldLit = _line(_feltLit.withValues(alpha: .4), .03);
  static final _foldDark = _line(_feltDeep.withValues(alpha: .5), .04);

  static void _flap(Canvas c, Path flap, Paint fill, int side, int look) {
    c.drawPath(flap, _flapInk);
    c.drawPath(flap, fill);
    c.drawPath(
      side == 0 ? _foldLeft : _foldRight,
      side == 0 ? _foldLit : _foldDark,
    );
    // The underside of the turned-up edge shows a lining.
    c.drawPath(_liningBand[side], _liningFill[look]);
    c.drawPath(_liningShadeBand[side], _liningShadeFill);
  }

  static void _brim(Canvas c, int look, bool worn) {
    _flap(c, _leftFlap, _leftFlapFill, 0, look);
    _flap(c, _rightFlap, _rightFlapFill, 1, look);
    c.drawPath(_hole, _holeFill);
    c.drawPath(_holeFray, _holeFrayLine);
    final braid = _braid[look];
    // Braid wraps the raised edge of each corner...
    c.drawPath(_rims, braid.ink);
    c.drawPath(_rims, braid.deep);
    c.drawPath(_rims, braid.gold);
    // ...then the front panel folds over it.
    c.drawPath(_panel, _flapInk);
    c.drawPath(_panel, _panelFill[look]);
    c.drawPath(_topEdge.shift(const Offset(0, .03)), _panelLip);
    c.drawPath(_stitches, _stitchLine);
    c.drawPath(_napLit, _napPaints.$1);
    c.drawPath(_napDark, _napPaints.$2);
    if (worn) {
      // The brim casts a soft shadow across the brow.
      c.drawPath(_panelBottom.shift(const Offset(0, .07)), _browShadow);
    }
    c.drawPath(_lowerEdge, braid.ink);
    c.drawPath(_lowerEdge, braid.deep);
    c.drawPath(_lowerEdge, braid.gold);
    c.drawPath(_braidTicks, _braidTick[look]);
    c.drawPath(_lowerGleam, _braidGleam[look]);
    final deep = look == 1 ? _emberDeep : _goldDeep;
    final gold = look == 1 ? _emberGold : _gold;
    final light = look == 1 ? _emberLight : _goldLight;
    for (final at in const [_tipL, _tipR]) {
      c.drawCircle(at, .075, _fill(_ink));
      c.drawCircle(at, .052, _fill(deep));
      c.drawCircle(at + const Offset(-.008, -.008), .036, _fill(gold));
      c.drawCircle(at + const Offset(-.016, -.016), .012, _fill(light));
    }
  }

  // ------------------------------------------------------------ cockade --

  static final _tails = () {
    final p = Path();
    for (final (dx, dy, bend) in const [(.06, .3, .05), (.2, .26, -.06)]) {
      p
        ..moveTo(_pin.dx - .02, _pin.dy + .04)
        ..quadraticBezierTo(
          _pin.dx + bend,
          _pin.dy + dy * .5,
          _pin.dx + dx,
          _pin.dy + dy,
        )
        ..lineTo(_pin.dx + dx + .07, _pin.dy + dy + .05)
        ..lineTo(_pin.dx + dx + .11, _pin.dy + dy - .02)
        ..quadraticBezierTo(
          _pin.dx + bend + .1,
          _pin.dy + dy * .4,
          _pin.dx + .07,
          _pin.dy,
        )
        ..close();
    }
    return p;
  }();

  // A rosette of eight rounded petals around a gold button.
  static Offset _petal(int i) {
    final a = i * math.pi / 4 + .2;
    return _pin + Offset(math.cos(a), math.sin(a)) * .105;
  }

  static final _rosetteInk = () {
    final p = Path()..addOval(Rect.fromCircle(center: _pin, radius: .13));
    for (var i = 0; i < 8; i++) {
      p.addOval(Rect.fromCircle(center: _petal(i), radius: .076));
    }
    return p;
  }();
  static final _petalsA = () {
    final p = Path();
    for (var i = 0; i < 8; i += 2) {
      p.addOval(Rect.fromCircle(center: _petal(i), radius: .053));
    }
    return p;
  }();
  static final _petalsB = () {
    final p = Path();
    for (var i = 1; i < 8; i += 2) {
      p.addOval(Rect.fromCircle(center: _petal(i), radius: .053));
    }
    return p;
  }();
  static final _petalGleams = () {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + .2;
      p.addOval(
        Rect.fromCircle(
          center:
              _petal(i) + Offset(math.cos(a - 1.2), math.sin(a - 1.2)) * .02,
          radius: .02,
        ),
      );
    }
    return p;
  }();
  static final _rosetteFills = [
    (
      _fill(PirateBossRig.crimson),
      _fill(Color.lerp(PirateBossRig.crimson, _lining, .25)!),
      _fill(const Color(0xffff8a86).withValues(alpha: .8)),
      _fill(_lining),
    ),
    (
      _fill(_ember),
      _fill(Color.lerp(_ember, _liningFury, .25)!),
      _fill(_emberGold.withValues(alpha: .8)),
      _fill(_emberDeep),
    ),
  ];
  static final _tailInk = _line(_ink, .045);
  static final _tailFill = [_fill(_lining), _fill(_emberDeep)];
  static final _inkFill = _fill(_ink);
  static final _goldFill = _fill(_gold);
  static final _goldLightFill = _fill(_goldLight);

  static void _cockade(Canvas c, int look) {
    // Two ribbon tails trail from the pin.
    c.drawPath(_tails, _tailInk);
    c.drawPath(_tails, _tailFill[look]);
    final (a, b, gleam, centre) = _rosetteFills[look];
    c.drawPath(_rosetteInk, _inkFill);
    c.drawPath(_petalsA, a);
    c.drawPath(_petalsB, b);
    c.drawPath(_petalGleams, gleam);
    c.drawCircle(_pin, .078, centre);
    c.drawCircle(_pin, .06, _inkFill);
    c.drawCircle(_pin, .045, _goldFill);
    c.drawCircle(_pin + const Offset(-.014, -.014), .016, _goldLightFill);
  }

  // -------------------------------------------------------------- skull --

  // Everything below is authored around the skull's own centre, [1 = the
  // skull's half-width], and scaled onto the front panel.
  static final _boneCross = Path()
    ..moveTo(-.95, -.4)
    ..lineTo(.95, .82)
    ..moveTo(.95, -.4)
    ..lineTo(-.95, .82);
  static final _boneGleam = _boneCross.shift(const Offset(-.02, -.05));
  // Two knuckles cap each bone.
  static Path _knuckles(double radius) {
    final p = Path();
    for (final (end, dir) in const [
      (Offset(-.95, -.4), Offset(-.14, -.11)),
      (Offset(.95, .82), Offset(.14, .11)),
      (Offset(.95, -.4), Offset(.14, -.11)),
      (Offset(-.95, .82), Offset(-.14, .11)),
    ]) {
      for (final side in [-1.0, 1.0]) {
        p.addOval(
          Rect.fromCircle(
            center: end + Offset(dir.dy * side * -1.9, dir.dx * side * 1.9),
            radius: radius,
          ),
        );
      }
    }
    return p;
  }

  static final _knuckleInk = _knuckles(.22);
  static final _knuckleBone = _knuckles(.155);
  static final _skullPath = Path()
    ..addOval(const Rect.fromLTRB(-.7, -.9, .7, .3))
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-.42, .0, .42, .58),
        const Radius.circular(.16),
      ),
    );
  static final _sockets = () {
    final p = Path();
    for (final x in const [-.27, .27]) {
      p
        ..moveTo(x - .19 * x.sign, -.32)
        ..quadraticBezierTo(x, -.42, x + .17 * x.sign, -.26)
        ..quadraticBezierTo(x + .21 * x.sign, -.02, x, .01)
        ..quadraticBezierTo(x - .2 * x.sign, -.02, x - .19 * x.sign, -.32)
        ..close();
    }
    return p;
  }();
  static final _nose = Path()
    ..moveTo(0, .05)
    ..lineTo(-.1, .24)
    ..quadraticBezierTo(0, .2, .1, .24)
    ..close();
  static final _teeth = Path()
    ..moveTo(-.36, .36)
    ..lineTo(.36, .36)
    ..moveTo(-.24, .36)
    ..lineTo(-.24, .56)
    ..moveTo(-.08, .36)
    ..lineTo(-.08, .56)
    ..moveTo(.08, .36)
    ..lineTo(.08, .56)
    ..moveTo(.24, .36)
    ..lineTo(.24, .56);
  static final _crack = Path()
    ..moveTo(.16, -.86)
    ..lineTo(.06, -.62)
    ..lineTo(.2, -.5)
    ..lineTo(.1, -.36);
  // A thin crescent of shade down the skull's far side.
  static final _cheeks = Path()
    ..moveTo(.3, -.66)
    ..cubicTo(.5, -.5, .56, -.2, .44, .2)
    ..cubicTo(.47, -.1, .43, -.4, .3, -.66)
    ..close();

  static final _skullShadow = _fill(_feltDeep.withValues(alpha: .35));
  static final _boneInk = _line(_ink, .5);
  static final _boneBase = _line(_boneShade, .3);
  static final _boneLit = _line(_bone, .14);
  static final _skullInk = _line(_ink, .24);
  static final _skullFill = _along(
    const Rect.fromLTRB(-.7, -.9, .7, .58),
    const Offset(-.7, -.9),
    const Offset(.7, .58),
    const [Color(0xfffffbee), _bone, _boneShade],
    stops: const [0, .45, 1],
  );
  static final _crackLine = _line(_boneDeep, .06);
  static final _cheekShade = _fill(_boneDeep.withValues(alpha: .35));
  static final _teethLine = _line(_ink, .06);

  static void _skull(Canvas c, Offset at, double s, bool fury) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(s);
    // A soft shadow settles the emblem into the felt.
    c.drawOval(const Rect.fromLTRB(-1.3, -.7, 1.3, 1.25), _skullShadow);
    c.drawPath(_boneCross, _boneInk);
    c.drawPath(_boneCross, _boneBase);
    c.drawPath(_boneGleam, _boneLit);
    c.drawPath(_knuckleInk, _inkFill);
    c.drawPath(_knuckleBone, _boneFill);
    c.drawPath(_skullPath, _skullInk);
    c.drawPath(_skullPath, _skullFill);
    c.drawPath(_cheeks, _cheekShade);
    c.drawPath(_crack, _crackLine);
    c.drawPath(_sockets, _inkFill);
    if (fury) {
      for (final x in const [-.27, .27]) {
        c.drawCircle(Offset(x, -.12), .1, _fill(_ember));
        c.drawCircle(Offset(x - .02, -.14), .035, _goldLightFill);
      }
    }
    c.drawPath(_nose, _inkFill);
    c.drawPath(_teeth, _teethLine);
    c.restore();
  }

  static final _boneFill = _fill(_bone);
  static final _sparkleFill = _fill(const Color(0xffffffff));

  static void _sparkle(Canvas c, Offset at, double r) {
    final star = Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx + r * .12, at.dy - r * .12, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx + r * .12, at.dy + r * .12, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx - r * .12, at.dy + r * .12, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx - r * .12, at.dy - r * .12, at.dx, at.dy - r)
      ..close();
    c.drawPath(star, _sparkleFill);
  }
}

/// A feather's cached geometry: vane, barbs, notch shading and quill.
class _Feather {
  const _Feather(
    this.body,
    this.lit,
    this.shade,
    this.quill,
    this.fill,
    this.litLine,
  );
  final Path body, lit, shade, quill;
  final Paint fill, litLine;
}

/// The three strokes that make up a length of braid.
class _Braid {
  const _Braid(this.ink, this.deep, this.gold);
  final Paint ink, deep, gold;
}
