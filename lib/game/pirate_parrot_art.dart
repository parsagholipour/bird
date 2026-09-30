import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'boss_motion.dart';
import 'pirate_boss_rig.dart';

/// The Pirate Captain's scarlet macaw: a big-beaked, wide-eyed bird with a
/// white face patch, layered red/yellow/blue wings and a long streaming
/// tail. It rides the captain's far shoulder, ruffles and squawks with the
/// fight, and flaps away when the captain is beaten.
///
/// Everything is authored in rig units (1 = the boss's hit radius) with the
/// bird's feet at the origin, facing left toward the player's bird. All
/// motion derives from the seconds handed in, so any frame can be redrawn.
abstract final class PirateParrotArt {
  static const _ink = PirateBossRig.ink;
  static const _scarlet = Color(0xffe8402f), _scarletLit = Color(0xffff8f60);
  static const _scarletDeep = Color(0xffa61f30);
  static const _yellow = Color(0xffffc93a), _yellowLit = Color(0xfffff08c);
  static const _yellowDeep = Color(0xffe39a22);
  static const _blue = Color(0xff2f86e6), _blueLit = Color(0xff74c4ff);
  static const _blueDeep = Color(0xff1e4fb5);
  static const _face = Color(0xfffff6ea), _faceShade = Color(0xffe8cbb8);
  static const _faceLine = Color(0xffb8443f), _iris = Color(0xfffff0a0);
  static const _beak = Color(0xfff7e9cf), _beakShade = Color(0xffd6b58a);
  static const _beakTip = Color(0xff8f7a68), _beakDark = Color(0xff3b3444);
  static const _beakDarkLit = Color(0xff6c6280);
  static const _mouth = Color(0xff8a1f3a), _tongue = Color(0xffff7f95);
  static const _foot = Color(0xffa39cb3), _footDeep = Color(0xff625a74);
  static const _white = Color(0xffffffff);

  /// Where the feet stand and where the tail leaves the body, for callers.
  static const _shoulder = Offset(.05, -.42);
  static const _rump = Offset(.22, -.13);
  static const _headCenter = Offset(-.13, -.6);
  static const _neck = Offset(-.02, -.5);
  static const _wingRate = 22.0;

  /// The whole bird is drawn a little over life size so it reads on a phone.
  static const _size = 1.14;

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint _grad(Offset a, Offset b, List<Color> colors) =>
      Paint()..shader = _shader(a, b, colors);
  static ui.Shader _shader(Offset a, Offset b, List<Color> colors) =>
      ui.Gradient.linear(a, b, colors, [
        for (var i = 0; i < colors.length; i++) i / (colors.length - 1),
      ]);

  // ----------------------------------------------------------- shapes --

  static Path _leaf(double length, double width) => Path()
    ..moveTo(0, -width * .55)
    ..cubicTo(length * .3, -width * 1.15, length * .8, -width, length, 0)
    ..cubicTo(length * .8, width, length * .3, width * 1.15, 0, width * .55)
    ..close();

  /// A row of feather tips bulging toward +x along a vertical edge.
  static Path _scallops(double x, double from, double to, int count) {
    final path = Path()..moveTo(x, from);
    final step = (to - from) / count;
    for (var i = 0; i < count; i++) {
      final y = from + i * step;
      path.quadraticBezierTo(x + .07, y + step * .5, x, y + step);
    }
    return path;
  }

  static final Path _body = Path()
    ..moveTo(0, -.05)
    ..cubicTo(-.25, -.05, -.32, -.29, -.23, -.43)
    ..cubicTo(-.17, -.52, -.05, -.56, .07, -.55)
    ..cubicTo(.21, -.54, .31, -.42, .31, -.28)
    ..cubicTo(.31, -.14, .2, -.04, 0, -.05)
    ..close();
  static final Path _headShape = Path()
    ..addOval(Rect.fromCircle(center: _headCenter, radius: .17));
  static final Path _facePatch = Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(-.06, -.004),
        width: .23,
        height: .2,
      ),
    );

  /// Scalloped breast feathers, in rows.
  static final Path _breast = () {
    final path = Path();
    for (var row = 0; row < 3; row++) {
      for (var k = 0; k < 3; k++) {
        final x = -.27 + (row.isOdd ? .05 : 0) + k * .1;
        final y = -.4 + row * .1;
        path
          ..moveTo(x, y)
          ..quadraticBezierTo(x + .045, y + .06, x + .09, y);
      }
    }
    return path;
  }();

  // The wing, in its own frame: x runs from the shoulder out along the wing.
  static final Path _cap = Path()
    ..moveTo(-.05, .01)
    ..cubicTo(-.02, .13, .14, .17, .27, .09)
    ..cubicTo(.32, .06, .34, -.03, .29, -.09)
    ..cubicTo(.2, -.16, .04, -.16, -.05, -.08)
    ..close();
  static final Path _redRow = _scallops(.09, -.2, .2, 4);
  static final Path _yellowRow = _scallops(.2, -.2, .2, 4);
  static final Path _redBand = Path.from(_redRow)
    ..lineTo(-.1, .2)
    ..lineTo(-.1, -.2)
    ..close();
  static final Path _yellowBand = Path.from(_yellowRow)
    ..lineTo(-.1, .2)
    ..lineTo(-.1, -.2)
    ..close();
  static final List<Path> _primaries = [
    for (final length in _primaryLengths) _leaf(length, .05),
  ];
  static const _primaryLengths = [.44, .5, .47, .41, .35];
  static const _primaryBase = Offset(.05, 0);

  // The tail: three streamers with blue tips.
  static const _tailLengths = [.56, .66, .58];
  static final List<Path> _tail = [
    for (final length in _tailLengths) _leaf(length, .072),
  ];
  static final List<Path> _tailTips = [
    for (final length in _tailLengths)
      Path()
        ..moveTo(length * .66, -.14)
        ..lineTo(length * .76, 0)
        ..lineTo(length * .66, .14)
        ..lineTo(length + .1, .14)
        ..lineTo(length + .1, -.14)
        ..close(),
  ];

  // The beak, in a frame at the hinge of the jaw.
  static final Path _upper = Path()
    ..moveTo(.06, -.12)
    ..cubicTo(-.04, -.17, -.19, -.15, -.25, -.05)
    ..cubicTo(-.28, 0, -.28, .07, -.23, .11)
    ..cubicTo(-.22, .05, -.16, .015, -.08, .02)
    ..lineTo(.06, .02)
    ..close();
  static final Path _lower = Path()
    ..moveTo(.05, .015)
    ..cubicTo(-.03, .005, -.11, .01, -.155, .045)
    ..cubicTo(-.15, .11, -.07, .14, .03, .115)
    ..close();
  static const _hinge = Offset(-.14, .03);
  static const _jaw = Offset(.02, .02);

  static final Path _featherShape = _leaf(.2, .06);

  static final Path _bellyShade = Path()
    ..moveTo(-.2, -.02)
    ..quadraticBezierTo(.1, .02, .32, -.24);
  static final Path _wingLight = Path()
    ..moveTo(-.02, .085)
    ..quadraticBezierTo(.05, .12, .11, .1);
  static final Path _headLight = Path()
    ..moveTo(-.11, -.1)
    ..quadraticBezierTo(-.06, -.15, .01, -.145);
  static final Path _crownLines = () {
    final path = Path();
    for (final (x, y) in const [(.03, -.11), (.07, -.07), (.09, -.02)]) {
      path
        ..moveTo(x, y)
        ..quadraticBezierTo(x + .02, y + .015, x + .035, y + .05);
    }
    return path;
  }();
  static final Path _faceLines = () {
    final path = Path();
    for (final (x, y, dx, dy) in const [
      (-.03, .04, .045, .02),
      (-.065, .062, .05, .015),
      (.0, .0, .04, .035),
    ]) {
      path
        ..moveTo(x, y)
        ..quadraticBezierTo(x + dx * .5, y + dy * 1.6, x + dx, y + dy);
    }
    return path;
  }();
  static const _eyeAt = Offset(-.05, -.025);
  static final Path _blinkLine = Path()
    ..moveTo(_eyeAt.dx - .045, _eyeAt.dy)
    ..quadraticBezierTo(
      _eyeAt.dx,
      _eyeAt.dy + .04,
      _eyeAt.dx + .045,
      _eyeAt.dy,
    );
  static final Path _lowerRim = Path()
    ..moveTo(-.13, .075)
    ..quadraticBezierTo(-.07, .118, .0, .1);
  static final Path _jawShade = Path()
    ..moveTo(-.22, .07)
    ..quadraticBezierTo(-.14, .02, .04, .03);
  static final Path _ridgeGlint = Path()
    ..moveTo(.0, -.125)
    ..quadraticBezierTo(-.12, -.135, -.19, -.08);
  static final Path _leg = Path()
    ..moveTo(0, -.07)
    ..lineTo(0, -.005);
  // Toes curl over the epaulette: two forward, one back.
  static final Path _toes = () {
    final path = Path();
    for (final (dx, dy) in const [(-.1, .035), (-.065, .048), (.07, .04)]) {
      path
        ..moveTo(0, -.008)
        ..quadraticBezierTo(dx * .55, -.03, dx, dy);
    }
    return path;
  }();
  static final RRect _ring = RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(0, -.04), width: .07, height: .03),
    const Radius.circular(.012),
  );

  static final Paint _legInk = _line(_ink, .08);
  static final Paint _toeInk = _line(_ink, .07);
  static final Paint _legNear = _line(_foot, .042);
  static final Paint _legFar = _line(_footDeep, .042);
  static final Paint _toeNear = _line(_foot, .034);
  static final Paint _toeFar = _line(_footDeep, .034);
  static final Paint _goldFill = _fill(PirateBossRig.gold);
  static final Paint _thin = _line(_ink, .014);
  static final Paint _chestLight = _fill(_scarletLit.withValues(alpha: .35));
  static final Paint _breastLine = _line(
    _scarletDeep.withValues(alpha: .55),
    .018,
  );
  static final Paint _bellyLine = _line(_scarletDeep.withValues(alpha: .5), .1);
  static final Paint _rowEdge = _line(_ink.withValues(alpha: .5), .015);
  static final Paint _wingInk = _line(_ink, .05);
  static final Paint _capInk = _line(_ink, .055);
  static final Paint _headGlow = _line(
    _scarletLit.withValues(alpha: .75),
    .024,
  );
  static final Paint _crownInk = _line(
    _scarletDeep.withValues(alpha: .7),
    .016,
  );
  static final Paint _facePaint = _fill(_face);
  static final Paint _faceEdge = _line(_faceShade, .022);
  static final Paint _faceStroke = _line(_faceLine, .011);
  static final Paint _mouthInk = _line(_ink, .04);
  static final Paint _mouthFill = _fill(_mouth);
  static final Paint _lowerInk = _line(_ink, .045);
  static final Paint _lowerFill = _fill(_beakDark);
  static final Paint _lowerLit = _line(_beakDarkLit, .018);
  static final Paint _tonguePaint = _fill(_tongue);
  static final Paint _tipPaint = _fill(_beakTip);
  static final Paint _shadePaint = _line(_beakShade, .05);
  static final Paint _glintPaint = _line(_white.withValues(alpha: .85), .02);
  static final Paint _darkFill = _fill(_beakDark);
  static final Paint _shaftLine = _line(_white.withValues(alpha: .35), .012);
  static final Paint _tailInk = _line(_ink, .06);
  static final Paint _inkFill = _fill(_ink);
  static final Paint _irisFill = _fill(_iris);
  static final Paint _whiteFill = _fill(_white);
  static final Paint _blinkInk = _line(_ink, .022);
  static final Paint _browInk = _line(_ink, .028);
  static final Paint _deepFill = _fill(_scarletDeep);
  static final Paint _scarletFill = _fill(_scarlet);
  static final Paint _yellowSolid = _fill(_yellow);
  static final Paint _hackleInk = _line(_ink, .05);

  static final Paint _outline = _line(_ink, .075);
  static final Paint _bodyFill = _grad(
    const Offset(-.3, -.78),
    const Offset(.3, -.05),
    const [_scarletLit, _scarlet, _scarletDeep],
  );
  static final Paint _upperFill = _grad(
    const Offset(-.1, -.15),
    const Offset(-.1, .1),
    const [_white, _beak, _beakShade],
  );
  static final Paint _tailRed = _grad(Offset.zero, const Offset(.6, 0), const [
    _scarletLit,
    _scarlet,
    _scarletDeep,
  ]);
  static final Paint _tailDeep = _grad(Offset.zero, const Offset(.6, 0), const [
    _scarlet,
    _scarletDeep,
    Color(0xff7d1730),
  ]);
  static final Paint _tailBlue = _grad(Offset.zero, const Offset(.6, 0), const [
    _blueLit,
    _blue,
    _blueDeep,
  ]);
  static final Paint _tailTip = _grad(
    const Offset(.3, 0),
    const Offset(.7, 0),
    const [_blue, _blueDeep],
  );
  static final _Plumage _near = _Plumage(null);
  static final _Plumage _far = _Plumage(const Color(0xff2a1f5a));

  // --------------------------------------------------------- the bird --

  /// The bird. [squawk] opens the beak and throws the head back; [flap] is
  /// the perched wing ruffle (wings flare out); [ruffle] is fury alertness;
  /// [dizzy] is a startled, wide-eyed shock; [look] turns the eye toward the
  /// player's bird (-1 up, 1 down). [air] blends from perched (0) to flying
  /// (1), where [stroke] is the wingbeat (0 raised, 1 swept down).
  ///
  /// [time] drives the idle bob, blink and tail sway; 0 holds it perfectly
  /// still (Reduced Motion, and the frozen defeat).
  static void paint(
    Canvas c, {
    double time = 0,
    double squawk = 0,
    double flap = 0,
    double ruffle = 0,
    bool dizzy = false,
    double look = 0,
    double air = 0,
    double stroke = 0,
  }) {
    c.save();
    c.scale(_size);
    final live = time != 0;
    final shock = dizzy ? 1.0 : 0.0;
    final open = math.max(squawk.clamp(0.0, 1.0), shock * .55);
    final alert = ruffle.clamp(0.0, 1.0);
    final flare = flap.clamp(0.0, 1.0) * (1 - air);
    final bob = live ? math.sin(time * (3.4 + alert * 3.2)) * .022 : 0.0;
    // Now and then the head cocks curiously to one side.
    final cock = live && air < .5
        ? BossMotion.pulse(time % 5.3 - 3.9, .8) * (1 - open)
        : 0.0;
    final blink = live && air < .5
        ? BossMotion.pulse((time + 1.3) % 3.1 - 2.75, .2)
        : 0.0;
    final headRot =
        open * .3 - look.clamp(-1.0, 1.0) * .08 - cock * .22 - air * .1;
    final headAt = Offset(
      open * .015 - alert * .02 - air * .04 + cock * .01,
      bob + alert * .012 + cock * .014,
    );
    final puff = 1 + flare * .05 + alert * .045 + open * .03;

    _feet(c, air);
    if (air > 0) tail(c, time: time, squawk: squawk, ruffle: alert, air: air);
    // The far wing, behind the body.
    final wingAngle = _lerp(1.0 - flare * 1.35, -1.0 + stroke * 2.25, air);
    final wingSize = 1 + air * .2;
    final wingAt = _shoulder + Offset(.08, .02) * air;
    final wingSpread = _lerp(.06 + flare * .3, .12 + stroke * .1, air);
    final wingReach = _lerp(
      1 + flare * .12,
      1.75 * (.8 + .2 * (stroke * 2 - 1).abs()),
      air,
    );
    final farReach = math.min(1.0, flare * 3 + air);
    if (farReach > .05) {
      _wing(
        c,
        angle: wingAngle - (.55 + flare * .4),
        spread: wingSpread,
        reach: wingReach * .95 * farReach,
        size: wingSize,
        at: wingAt,
        plumage: _far,
      );
    }
    final raised = math.max(alert, shock * .7);
    if (raised > 0) _hackles(c, headAt, headRot, raised);
    // Body and head share one silhouette: inks first, then fills.
    void bodyFrame() {
      c.translate(0, -.05);
      c.scale(puff);
      c.translate(0, .05);
    }

    c.save();
    bodyFrame();
    c.drawPath(_body, _outline);
    c.restore();
    _headFrame(c, headAt, headRot);
    c.drawPath(_headShape, _outline);
    c.restore();
    c.save();
    bodyFrame();
    c.drawPath(_body, _bodyFill);
    c.save();
    c.clipPath(_body);
    // Light on the chest, shade under the belly, breast feathers.
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.15, -.33), width: .13, height: .2),
      _chestLight,
    );
    c.drawPath(_breast, _breastLine);
    c.drawPath(_bellyShade, _bellyLine);
    c.restore();
    c.restore();
    _headFrame(c, headAt, headRot);
    c.drawPath(_headShape, _bodyFill);
    c.restore();
    _wing(
      c,
      angle: wingAngle,
      spread: wingSpread,
      reach: wingReach,
      size: wingSize,
      at: wingAt,
      plumage: _near,
    );
    _head(
      c,
      headAt,
      headRot,
      open: open,
      alert: alert,
      shock: shock,
      blink: blink,
      look: look,
    );
    c.restore();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static void _headFrame(Canvas c, Offset at, double rot) {
    c.save();
    c.translate(at.dx, at.dy);
    c.translate(_neck.dx, _neck.dy);
    c.rotate(rot);
    c.translate(-_neck.dx, -_neck.dy);
  }

  // ------------------------------------------------------------ feet --

  static void _feet(Canvas c, double air) {
    for (final (x, far) in const [(.11, true), (-.06, false)]) {
      c.save();
      c.translate(x, -.07);
      c.rotate(-air * 1.3);
      c.translate(0, .07);
      c.drawPath(_leg, _legInk);
      c.drawPath(_leg, far ? _legFar : _legNear);
      c.drawPath(_toes, _toeInk);
      c.drawPath(_toes, far ? _toeFar : _toeNear);
      if (!far) {
        // A little gold ring: this bird has been somewhere.
        c.drawRRect(_ring, _goldFill);
        c.drawRRect(_ring, _thin);
      }
      c.restore();
    }
  }

  // ------------------------------------------------------------ wing --

  static void _wing(
    Canvas c, {
    required double angle,
    required double spread,
    required double reach,
    required double size,
    required Offset at,
    required _Plumage plumage,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    c.scale(reach * size, size);
    for (var i = 0; i < _primaries.length; i++) {
      c.save();
      c.translate(_primaryBase.dx, _primaryBase.dy);
      c.rotate((i - 2) * spread + spread * .3);
      c.drawPath(_primaries[i], _wingInk);
      c.drawPath(_primaries[i], plumage.primary);
      c.drawLine(
        const Offset(.05, 0),
        Offset(_primaryLengths[i] * .86, 0),
        plumage.shaft,
      );
      c.restore();
    }
    c.drawPath(_cap, _capInk);
    c.drawPath(_cap, plumage.blue);
    c.save();
    c.clipPath(_cap);
    c.drawPath(_yellowBand, plumage.yellow);
    c.drawPath(_redBand, plumage.red);
    c.drawPath(_yellowRow, _rowEdge);
    c.drawPath(_redRow, _rowEdge);
    c.drawPath(_wingLight, plumage.light);
    c.restore();
    c.restore();
  }

  /// Feathers raised on the crown and nape when it is angry or startled.
  static void _hackles(Canvas c, Offset at, double rot, double amount) {
    _headFrame(c, at, rot);
    c.translate(_headCenter.dx, _headCenter.dy);
    for (var i = 0; i < 5; i++) {
      c.save();
      c.translate(.0 + i * .035, -.135 + i * .02);
      c.rotate(-1.55 + i * .32);
      c.scale(1.05 + amount * .35 - i * .05);
      c.drawPath(_featherShape, _hackleInk);
      c.drawPath(_featherShape, i.isEven ? _scarletFill : _yellowSolid);
      c.restore();
    }
    c.restore();
  }

  // ------------------------------------------------------------- face --

  static void _head(
    Canvas c,
    Offset at,
    double rot, {
    required double open,
    required double alert,
    required double shock,
    required double blink,
    required double look,
  }) {
    _headFrame(c, at, rot);
    c.translate(_headCenter.dx, _headCenter.dy);
    // Head light and a few tiny crown feathers.
    c.drawPath(_headLight, _headGlow);
    c.drawPath(_crownLines, _crownInk);
    // The pale face patch with fine feather lines.
    c.drawPath(_facePatch, _facePaint);
    c.drawPath(_facePatch, _faceEdge);
    c.drawPath(_faceLines, _faceStroke);
    _eye(c, _eyeAt, alert: alert, shock: shock, blink: blink, look: look);
    _beakAt(c, open);
    c.restore();
  }

  static void _eye(
    Canvas c,
    Offset e, {
    required double alert,
    required double shock,
    required double blink,
    required double look,
  }) {
    if (blink > .55) {
      c.drawPath(_blinkLine, _blinkInk);
      return;
    }
    final ring = .062 + shock * .01;
    c.drawCircle(e, ring, _inkFill);
    c.drawCircle(e, ring - .014, _irisFill);
    final gaze = Offset(-.55, look.clamp(-1.0, 1.0) * .6) * .014;
    final pupil = shock > 0 ? .014 : .036 - alert * .006;
    c.drawCircle(e + gaze, pupil, _inkFill);
    c.drawCircle(e + gaze + const Offset(-.011, -.013), .01, _whiteFill);
    final lid = math.max(blink * 1.6, alert);
    if (lid > .02 || shock == 0 && blink > 0) {
      // Half-shut on the blink; a hard slanted brow when angry.
      c.save();
      c.clipPath(Path()..addOval(Rect.fromCircle(center: e, radius: ring)));
      final drop = blink * .05;
      final brow = Path()
        ..moveTo(e.dx + .09, e.dy - .12 + drop)
        ..lineTo(e.dx + .09, e.dy - .08 + drop + alert * .02)
        ..lineTo(e.dx - .09, e.dy - .01 + drop + alert * .02)
        ..lineTo(e.dx - .09, e.dy - .12 + drop)
        ..close();
      c.drawPath(brow, alert > 0 ? _deepFill : _facePaint);
      c.drawPath(
        Path()
          ..moveTo(e.dx + .09, e.dy - .08 + drop + alert * .02)
          ..lineTo(e.dx - .09, e.dy - .01 + drop + alert * .02),
        _browInk,
      );
      c.restore();
    }
  }

  static Offset _turn(Offset p, Offset pivot, double a) {
    final d = p - pivot;
    final s = math.sin(a), k = math.cos(a);
    return pivot + Offset(d.dx * k - d.dy * s, d.dx * s + d.dy * k);
  }

  static void _beakAt(Canvas c, double open) {
    c.save();
    c.translate(_hinge.dx, _hinge.dy);
    c.scale(.82);
    final up = .3 * open, down = .5 * open;
    if (open > .05) {
      // Dark throat between the jaws, with a tongue.
      final top = _turn(const Offset(-.2, .03), Offset.zero, -up);
      final bottom = _turn(const Offset(-.15, .04), _jaw, down);
      final mouth = Path()
        ..moveTo(.05, 0)
        ..lineTo(top.dx, top.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(.05, .05)
        ..close();
      c.drawPath(mouth, _mouthInk);
      c.drawPath(mouth, _mouthFill);
    }
    c.save();
    c.translate(_jaw.dx, _jaw.dy);
    c.rotate(down);
    c.translate(-_jaw.dx, -_jaw.dy);
    c.drawPath(_lower, _lowerInk);
    c.drawPath(_lower, _lowerFill);
    c.drawPath(_lowerRim, _lowerLit);
    if (open > .3) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(-.075, .025),
          width: .11,
          height: .05,
        ),
        _tonguePaint,
      );
    }
    c.restore();
    c.rotate(-up);
    c.drawPath(_upper, _lowerInk);
    c.drawPath(_upper, _upperFill);
    c.save();
    c.clipPath(_upper);
    // A darker horn tip, a shaded jaw edge and a glint along the ridge.
    c.drawCircle(const Offset(-.26, .1), .075, _tipPaint);
    c.drawPath(_jawShade, _shadePaint);
    c.restore();
    c.drawPath(_ridgeGlint, _glintPaint);
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-.005, -.07),
        width: .045,
        height: .03,
      ),
      _darkFill,
    );
    c.restore();
  }

  // ------------------------------------------------------------- tail --

  /// The long streamers, drawn behind everything else. Perched, they hang
  /// and sway; in the air they trail and ripple.
  static void tail(
    Canvas c, {
    double time = 0,
    double squawk = 0,
    double ruffle = 0,
    double air = 0,
  }) {
    final live = time != 0;
    c.save();
    c.scale(_size);
    c.translate(_rump.dx, _rump.dy);
    final base =
        _lerp(.62, .12, air) - squawk.clamp(0.0, 1.0) * .3 - ruffle * .1;
    final length = 1 + air * .2;
    for (final i in const [0, 2, 1]) {
      final wave = live
          ? math.sin(time * _lerp(2.2, 9, air) - i * (.9 + air)) *
                _lerp(.045, .1, air)
          : 0.0;
      c.save();
      c.rotate(base + (i - 1) * .2 + wave * (1 + i * .4));
      c.scale(length);
      c.drawPath(_tail[i], _tailInk);
      c.drawPath(
        _tail[i],
        i == 0
            ? _tailDeep
            : i == 2
            ? _tailBlue
            : _tailRed,
      );
      c.save();
      c.clipPath(_tail[i]);
      c.drawPath(_tailTips[i], i == 2 ? _tailRed : _tailTip);
      c.restore();
      c.drawLine(
        const Offset(.04, 0),
        Offset(_tailLengths[i] * .9, 0),
        _shaftLine,
      );
      c.restore();
    }
    c.restore();
  }

  // -------------------------------------------------------- feathers --

  /// A loose feather (0 scarlet, 1 blue, 2 yellow), centred on its middle.
  static void feather(Canvas c, int kind, double alpha) {
    final color = const [_scarlet, _blue, _yellow][kind % 3];
    c.save();
    c.translate(-.1, 0);
    c.drawPath(_featherShape, _line(_ink.withValues(alpha: alpha), .05));
    c.drawPath(_featherShape, _fill(color.withValues(alpha: alpha)));
    c.drawLine(
      const Offset(.02, 0),
      const Offset(.17, 0),
      _line(_white.withValues(alpha: .45 * alpha), .01),
    );
    c.restore();
  }

  // ------------------------------------------------------------ flight --

  static const _hop = .16;

  static Offset _track(double t) {
    final s = math.max(0.0, t - _hop);
    final spring = (1 - math.exp(-8 * s)) * .34;
    return Offset(1.3 * s + 1.2 * s * s, -(2.4 * s + .8 * s * s + spring));
  }

  static double _hash(int i) =>
      (math.sin(i * 12.9898 + 4.1414) * 43758.5453).abs() % 1;

  /// The parrot has had enough: it crouches, throws its wings out, spins
  /// about and beats away up and out of the fight, squawking and shedding
  /// feathers. [from] is where its feet stood, [unit] the rig unit in pixels
  /// and [t] the seconds since it left.
  static void flee(
    Canvas c, {
    required Offset from,
    required double unit,
    required double t,
    required bool reduced,
  }) {
    if (t < 0) return;
    final fade =
        1 - BossMotion.ramp(t, reduced ? .3 : 1.75, reduced ? .65 : 2.3);
    if (fade <= 0) return;
    c.save();
    c.translate(from.dx, from.dy);
    c.scale(unit);
    if (reduced) {
      // Held still, wings up, already clear of the captain's shoulder.
      c.translate(1.6, -1.1);
      c.rotate(-.3);
      c.scale(-1, 1);
      _layer(c, fade);
      paint(c, squawk: .6, dizzy: true, air: 1, stroke: .4);
    } else {
      _flight(c, t, fade);
    }
    if (fade < 1) c.restore();
    c.restore();
    if (!reduced) _shed(c, from, unit, t);
  }

  /// Fades the bird out with a bounded layer, only once it is fading.
  static void _layer(Canvas c, double fade) {
    if (fade >= 1) return;
    c.saveLayer(
      PirateBossRig.parrotBounds,
      _fill(const Color(0xffffffff).withValues(alpha: fade)),
    );
  }

  static void _flight(Canvas c, double t, double fade) {
    final s = math.max(0.0, t - _hop);
    final wobble = -math.sin(t * _wingRate) * .05 * BossMotion.ramp(s, 0, .3);
    final at = _track(t) + Offset(0, wobble);
    final ahead = _track(t + .05) - _track(t);
    final climb = math.atan2(-ahead.dy, math.max(.01, ahead.dx));
    // Crouch, then spring; the spin about happens in the first jump.
    final crouch =
        BossMotion.ease(BossMotion.ramp(t, 0, .12)) *
        (1 - BossMotion.ease(BossMotion.ramp(t, .12, .2)));
    final spin = BossMotion.ease(BossMotion.ramp(t, _hop, _hop + .2));
    final air = BossMotion.ease(BossMotion.ramp(t, _hop - .04, _hop + .12));
    c.translate(at.dx, at.dy);
    c.rotate(-climb * .55 * spin);
    final turn = math.cos(spin * math.pi);
    c.scale(turn.abs() < .02 ? .02 : turn, 1);
    c.scale(1 + crouch * .1, 1 - crouch * .16);
    _layer(c, fade);
    final beat = .5 - .5 * math.cos(math.max(0.0, t - _hop) * _wingRate);
    paint(
      c,
      time: t + .001,
      squawk: t < .6 ? 1 : .35 + .65 * math.max(0.0, math.sin(t * 6.4)),
      flap: BossMotion.ease(BossMotion.ramp(t, 0, .12)),
      dizzy: true,
      air: air,
      stroke: beat,
    );
  }

  /// Feathers shaken loose: two at the take-off, then one every so often.
  static void _shed(Canvas c, Offset from, double unit, double t) {
    const dropAt = [.02, .12, .35, .62, .9, 1.2, 1.55];
    for (var i = 0; i < dropAt.length; i++) {
      final dt = t - dropAt[i];
      if (dt <= 0 || dt > 1.5) continue;
      final born = _track(dropAt[i]) + Offset((_hash(i) - .5) * .3, -.25);
      final drift = Offset(
        math.sin(dt * 3.2 + i * 1.7) * .16 + dt * (.18 + _hash(i + 9) * .5),
        dt * .55 + dt * dt * .5 - dt * (i < 3 ? 1.1 : .3),
      );
      final p = from + (born + drift) * unit;
      final fade = 1 - BossMotion.ramp(dt, .8, 1.5);
      c.save();
      c.translate(p.dx, p.dy);
      c.scale(unit * (1.05 + _hash(i + 3) * .5));
      c.rotate(dt * (2 + _hash(i + 5) * 3) * (i.isEven ? 1 : -1) + i);
      feather(c, i, fade);
      c.restore();
    }
  }
}

/// A wing's paints; the far wing is the same plumage seen in shade.
class _Plumage {
  _Plumage(Color? tint)
    : primary = Paint()
        ..shader =
            PirateParrotArt._shader(const Offset(.05, 0), const Offset(.5, 0), [
              _t(PirateParrotArt._blueLit, tint, .3),
              _t(PirateParrotArt._blue, tint, .3),
              _t(PirateParrotArt._blueDeep, tint, .3),
            ]),
      blue = Paint()
        ..shader = PirateParrotArt._shader(
          const Offset(0, -.15),
          const Offset(.3, .1),
          [
            _t(PirateParrotArt._blueLit, tint, .3),
            _t(PirateParrotArt._blue, tint, .3),
          ],
        ),
      yellow = Paint()
        ..shader = PirateParrotArt._shader(
          const Offset(0, -.2),
          const Offset(.2, .2),
          [
            _t(PirateParrotArt._yellowLit, tint, .3),
            _t(PirateParrotArt._yellow, tint, .3),
            _t(PirateParrotArt._yellowDeep, tint, .3),
          ],
        ),
      red = Paint()
        ..shader = PirateParrotArt._shader(
          const Offset(-.05, -.1),
          const Offset(.1, .15),
          [
            _t(PirateParrotArt._scarletLit, tint, .3),
            _t(PirateParrotArt._scarlet, tint, .3),
            _t(PirateParrotArt._scarletDeep, tint, .3),
          ],
        ),
      shaft = PirateParrotArt._line(
        _t(const Color(0xffbfe6ff), tint, .3),
        .012,
      ),
      light = PirateParrotArt._line(
        _t(const Color(0xffbfe6ff), tint, .3).withValues(alpha: .7),
        .022,
      );

  final Paint primary, blue, yellow, red, shaft, light;

  static Color _t(Color color, Color? tint, double amount) =>
      tint == null ? color : Color.lerp(color, tint, amount)!;
}
