import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import 'theme.dart';

/// Postmaster Bill: the old pelican who runs the Sky Club post.
///
/// A tall white pear of a bird under a blue postal cap, with bushy brows,
/// heavy kind eyelids and a great orange bill whose pouch is the club's
/// first mailbag: it is patched and stitched, and letters peek out of it.
///
/// Authored in the player birds' own units (their art is 256 wide), with
/// their ink weight and their finish (flat fills, a gloss stroke, a shade
/// crescent, a blush), facing right. [perch] is where his feet meet the
/// ground.
abstract final class StoryPostmasterArt {
  /// The box the art is authored in.
  static const size = Size(340, 316);

  /// Where his feet stand, in the box.
  static const perch = Offset(144, 308);

  static const _ink = SkyColors.ink;
  static const _white = Color(0xffffffff), _shade = Color(0xffd5e2ee);
  static const _wing = Color(0xffc3d3e3), _wingTip = Color(0xff8ea6bf);
  static const _bill = Color(0xfffaa63d), _billLit = Color(0xffffcd73);
  static const _billTip = Color(0xffe9713f), _foot = Color(0xfff29136);
  static const _pouch = Color(0xffffdc93), _pouchShade = Color(0xfff3b55f);
  static const _mouth = Color(0xff8a3f3c);
  static const _blue = Color(0xff4583c4), _capLit = Color(0xff79aee2);
  static const _capDeep = Color(0xff2a5c93), _visor = Color(0xff1f3f63);
  static const _brass = SkyColors.yellow;
  static const _paper = SkyColors.cream, _pen = Color(0xff2e5f93);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, [double width = 4]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final _body = Path()
    ..moveTo(140, 50)
    ..cubicTo(186, 50, 212, 84, 210, 124)
    ..cubicTo(209, 150, 240, 180, 240, 228)
    ..cubicTo(240, 276, 198, 301, 146, 301)
    ..cubicTo(92, 301, 50, 272, 50, 222)
    ..cubicTo(50, 180, 82, 158, 84, 122)
    ..cubicTo(85, 84, 102, 50, 140, 50)
    ..close();

  static final _tail = Path()
    ..moveTo(60, 228)
    ..cubicTo(40, 222, 26, 226, 20, 236)
    ..cubicTo(30, 238, 34, 242, 32, 250)
    ..cubicTo(24, 252, 22, 260, 28, 268)
    ..cubicTo(44, 270, 58, 264, 66, 254)
    ..close();

  static final _crest = Path()
    ..moveTo(90, 106)
    ..cubicTo(78, 98, 68, 98, 62, 104)
    ..cubicTo(70, 106, 74, 110, 74, 116)
    ..cubicTo(66, 116, 60, 122, 60, 130)
    ..cubicTo(72, 134, 84, 130, 90, 124)
    ..close();

  static final _wingPath = Path()
    ..moveTo(150, 184)
    ..cubicTo(168, 200, 160, 234, 132, 248)
    ..cubicTo(108, 260, 80, 262, 64, 254)
    ..cubicTo(76, 240, 80, 218, 92, 200)
    ..cubicTo(104, 182, 132, 170, 150, 184)
    ..close();
  static const _wingPivot = Offset(144, 192);

  static const _nearEye = Offset(148, 118), _farEye = Offset(187, 115);
  static const _nearR = 22.0, _farR = 15.5;

  /// Where the bill hinges on the face.
  static const _hinge = Offset(202, 150);

  /// Paints Bill in the box [size]. [open] (0 to 1) works the bill as he
  /// talks, [blink] (0 to 1) shuts his eyes, and [wing] lifts his wing out
  /// behind him in a gesture (radians).
  static void paint(
    Canvas c, {
    StoryMood mood = StoryMood.plain,
    double open = 0,
    double blink = 0,
    double wing = 0,
  }) {
    final look = _Look.of(mood);
    final gape = math.max(open, look.gape).clamp(0.0, 1.0);

    // Tail, feet and the tuft behind the cap go under the body.
    c.drawPath(_tail, _fill(_white));
    c.drawPath(_tail, _line(_ink));
    c.drawPath(
      Path()
        ..moveTo(44, 244)
        ..lineTo(56, 246),
      _line(_shade, 3),
    );
    for (final x in const [118.0, 170.0]) {
      _footAt(c, Offset(x, 300));
    }
    c.drawPath(_crest, _fill(_white));
    c.drawPath(_crest, _line(_ink));

    // The body: a white pear with a cool shade along its underside.
    c.drawPath(_body, _fill(_white));
    c.save();
    c.clipPath(_body);
    c.drawPath(
      Path()
        ..moveTo(40, 214)
        ..cubicTo(66, 278, 150, 300, 244, 236)
        ..lineTo(244, 310)
        ..lineTo(40, 310)
        ..close(),
      _fill(_shade),
    );
    c.restore();
    c.drawPath(_body, _line(_ink, 4.5));

    // The folded wing, which lifts when he gestures.
    c.save();
    c.translate(_wingPivot.dx, _wingPivot.dy);
    c.rotate(wing);
    c.translate(-_wingPivot.dx, -_wingPivot.dy);
    c.drawPath(_wingPath, _fill(_wing));
    c.save();
    c.clipPath(_wingPath);
    // The flight feathers at the tip are a shade darker.
    c.drawPath(
      Path()
        ..moveTo(56, 262)
        ..lineTo(60, 236)
        ..cubicTo(86, 250, 118, 250, 150, 226)
        ..lineTo(150, 270)
        ..close(),
      _fill(_wingTip),
    );
    c.restore();
    c.drawPath(
      Path()
        ..moveTo(104, 202)
        ..cubicTo(112, 192, 126, 188, 138, 192),
      _line(_white.withValues(alpha: .85), 5),
    );
    c.drawPath(
      Path()
        ..moveTo(92, 240)
        ..cubicTo(102, 238, 110, 232, 114, 224)
        ..moveTo(114, 244)
        ..cubicTo(124, 240, 132, 232, 136, 222),
      _line(_ink.withValues(alpha: .55), 3),
    );
    c.drawPath(_wingPath, _line(_ink));
    c.restore();

    _hat(c, look);
    _face(c, look, blink);
    _beak(c, look, gape);
    if (look.startle) _startle(c);
  }

  static void _footAt(Canvas c, Offset at) {
    final foot = Path()
      ..moveTo(at.dx - 8, at.dy - 6)
      ..lineTo(at.dx - 17, at.dy + 8)
      ..lineTo(at.dx - 5, at.dy + 5)
      ..lineTo(at.dx + 2, at.dy + 9)
      ..lineTo(at.dx + 9, at.dy + 5)
      ..lineTo(at.dx + 21, at.dy + 8)
      ..lineTo(at.dx + 10, at.dy - 6)
      ..close();
    c.drawPath(foot, _fill(_foot));
    c.drawPath(foot, _line(_ink, 3.5));
  }

  // ---------------------------------------------------------------- cap --

  /// The postal cap: a blue crown with a coral band, a brass badge and a
  /// short dark peak. A start lifts it off his head.
  static void _hat(Canvas c, _Look look) {
    c.save();
    c.translate(142, 74);
    c.translate(0, -look.capLift);
    c.rotate(-.12 + look.capTilt);
    final crown = Path()
      ..moveTo(-50, 2)
      ..cubicTo(-52, -18, -50, -34, -44, -40)
      ..cubicTo(-16, -52, 22, -52, 48, -40)
      ..cubicTo(52, -30, 52, -14, 50, 4)
      ..cubicTo(20, 14, -22, 14, -50, 2)
      ..close();
    c.drawPath(crown, _fill(_blue));
    c.save();
    c.clipPath(crown);
    // The flat top catches the light.
    c.drawOval(
      Rect.fromCenter(center: const Offset(2, -41), width: 96, height: 20),
      _fill(_capLit),
    );
    // The band.
    c.drawPath(
      Path()
        ..moveTo(-54, -10)
        ..cubicTo(-22, 0, 22, 0, 54, -8)
        ..lineTo(54, 12)
        ..lineTo(-54, 12)
        ..close(),
      _fill(SkyColors.coral),
    );
    c.drawPath(
      Path()
        ..moveTo(-54, -10)
        ..cubicTo(-22, 0, 22, 0, 54, -8),
      _line(_brass, 3),
    );
    c.drawPath(
      Path()
        ..moveTo(36, -36)
        ..cubicTo(42, -28, 42, -20, 41, -12),
      _line(_capDeep, 4),
    );
    c.restore();
    c.drawPath(crown, _line(_ink));
    // The badge: a brass disc stamped with an envelope.
    const badge = Offset(16, -13);
    c.drawCircle(badge, 11.5, _fill(_brass));
    c.drawCircle(badge, 11.5, _line(_ink, 3));
    final letter = Rect.fromCenter(center: badge, width: 13, height: 9);
    c.drawRect(letter, _fill(_paper));
    c.drawPath(
      Path()
        ..addRect(letter)
        ..moveTo(letter.left, letter.top)
        ..lineTo(badge.dx, badge.dy + 1.5)
        ..lineTo(letter.right, letter.top),
      _line(_ink, 1.6),
    );
    // The peak juts forward over his brow.
    final peak = Path()
      ..moveTo(26, 8)
      ..cubicTo(42, 1, 60, 2, 74, 12)
      ..cubicTo(60, 17, 42, 19, 28, 17)
      ..close();
    c.drawPath(peak, _fill(_visor));
    c.drawPath(
      Path()
        ..moveTo(38, 8)
        ..cubicTo(46, 6, 54, 6, 62, 9),
      _line(_capLit.withValues(alpha: .7), 2.5),
    );
    c.drawPath(peak, _line(_ink));
    c.restore();
  }

  // --------------------------------------------------------------- face --

  static void _face(Canvas c, _Look look, double blink) {
    // A blush under the near eye, like every bird in the club.
    c.drawOval(
      Rect.fromCenter(center: const Offset(126, 154), width: 25, height: 13),
      _fill(SkyColors.coral.withValues(alpha: look.blush)),
    );
    _eye(c, _nearEye, _nearR, look, blink, near: true);
    _eye(c, _farEye, _farR, look, blink, near: false);
    _brow(c, _nearEye + Offset(-2, -_nearR - 9 - look.browLift), 40, look, 1);
    _brow(c, _farEye + Offset(2, -_farR - 8 - look.browLift), 27, look, -1);
  }

  static void _eye(
    Canvas c,
    Offset at,
    double r,
    _Look look,
    double blink, {
    required bool near,
  }) {
    final shut = blink > .5;
    if (look.smile || shut) {
      // Eyes shut: a happy arch, or the dip of a blink.
      c.drawCircle(at, r, _fill(_white));
      final w = r * .8;
      final arc = Path();
      if (look.smile && !shut) {
        arc
          ..moveTo(at.dx - w, at.dy + r * .22)
          ..quadraticBezierTo(
            at.dx,
            at.dy - r * .7,
            at.dx + w,
            at.dy + r * .22,
          );
      } else {
        arc
          ..moveTo(at.dx - w, at.dy - r * .05)
          ..quadraticBezierTo(
            at.dx,
            at.dy + r * .6,
            at.dx + w,
            at.dy - r * .05,
          );
      }
      c.drawPath(arc, _line(_ink, near ? 4.5 : 4));
      return;
    }
    final size = r * look.eyeScale;
    final eye = Rect.fromCircle(center: at, radius: size);
    c.drawOval(eye, _fill(_white));
    final pupil = at + Offset(size * .22, size * .08 + look.gaze * size * .3);
    c.save();
    c.clipPath(Path()..addOval(eye));
    c.drawCircle(pupil, size * .52 * look.pupil, _fill(_ink));
    c.drawCircle(
      pupil + Offset(-size * .18, -size * .2),
      size * .17 * look.pupil,
      _fill(_white),
    );
    // A heavy old eyelid, which slants with the mood.
    final lid = look.lid;
    if (lid > 0) {
      final side = near ? 1.0 : -1.0;
      final top = eye.top - 4;
      final level = eye.top + eye.height * lid;
      final slant = look.lidSlant * size * side;
      final shape = Path()
        ..moveTo(eye.left - 4, top)
        ..lineTo(eye.right + 4, top)
        ..lineTo(eye.right + 4, level + slant)
        ..lineTo(eye.left - 4, level - slant)
        ..close();
      c.drawPath(shape, _fill(_white));
      c.drawLine(
        Offset(eye.left - 4, level - slant),
        Offset(eye.right + 4, level + slant),
        _line(_ink, 3.5),
      );
    }
    c.restore();
    c.drawOval(eye, _line(_ink));
  }

  /// A bushy white brow: three soft tufts along a line that tips with the
  /// mood. [side] is 1 for the near brow, whose inner end is on the right.
  static void _brow(
    Canvas c,
    Offset at,
    double width,
    _Look look,
    double side,
  ) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(look.browTilt * side);
    final w = width / 2, h = width * .2;
    final brow = Path()
      ..moveTo(-w, h * .2)
      ..cubicTo(-w * .9, -h * 1.4, -w * .3, -h * 1.5, -w * .2, -h * .6)
      ..cubicTo(w * .0, -h * 1.7, w * .7, -h * 1.5, w * .62, -h * .5)
      ..cubicTo(w * 1.0, -h * .9, w * 1.2, -h * .1, w, h * .6)
      ..cubicTo(w * .4, h * 1.1, -w * .5, h * 1.1, -w, h * .2)
      ..close();
    c.drawPath(brow, _fill(_white));
    c.drawPath(brow, _line(_ink, 3.5));
    c.restore();
  }

  // --------------------------------------------------------------- bill --

  static void _beak(Canvas c, _Look look, double gape) {
    c.save();
    c.translate(_hinge.dx, _hinge.dy);
    c.rotate(look.droop);
    final lift = -(.03 + gape * .3);
    final sag = gape * .09;
    // The inside of the mouth shows in the wedge as the bill opens.
    c.drawPath(
      Path()
        ..moveTo(-4, 6)
        ..lineTo(112 * math.cos(lift), 112 * math.sin(lift) + 12)
        ..lineTo(100, 26)
        ..close(),
      _fill(_mouth),
    );

    // The upper bill: long, with a hooked nail at the tip.
    c.save();
    c.rotate(lift);
    final upper = Path()
      ..moveTo(-8, -17)
      ..cubicTo(30, -21, 80, -13, 118, 5)
      ..cubicTo(125, 11, 124, 24, 116, 31)
      ..cubicTo(112, 23, 106, 19, 98, 17)
      ..cubicTo(64, 12, 28, 12, -8, 14)
      ..close();
    c.drawPath(upper, _fill(_bill));
    c.save();
    c.clipPath(upper);
    c.drawPath(
      Path()
        ..moveTo(-10, -22)
        ..cubicTo(30, -26, 82, -18, 124, 2)
        ..lineTo(124, -6)
        ..cubicTo(82, -16, 30, -12, -10, -7)
        ..close(),
      _fill(_billLit),
    );
    c.drawPath(
      Path()
        ..moveTo(94, -10)
        ..lineTo(130, 4)
        ..lineTo(124, 38)
        ..lineTo(98, 24)
        ..close(),
      _fill(_billTip),
    );
    c.restore();
    c.drawLine(const Offset(18, -6), const Offset(30, -4), _line(_ink, 3));
    c.drawPath(upper, _line(_ink));
    c.restore();

    // Letters ride in the pouch and stand up out of it.
    c.save();
    c.rotate(sag);
    _letter(c, const Offset(34, 30), -.3, SkyColors.coral);
    _letter(c, const Offset(62, 33), .16, _pen);

    // The pouch: the lower bill, deep and soft, patched like the old
    // mailbag it is.
    final pouch = Path()
      ..moveTo(-8, 12)
      ..cubicTo(28, 17, 70, 20, 104, 24)
      ..cubicTo(100, 58, 72, 92, 40, 94)
      ..cubicTo(12, 96, -12, 72, -14, 40)
      ..close();
    c.drawPath(pouch, _fill(_pouch));
    c.save();
    c.clipPath(pouch);
    c.drawPath(
      Path()
        ..moveTo(-16, 60)
        ..cubicTo(14, 88, 60, 86, 106, 38)
        ..lineTo(106, 100)
        ..lineTo(-16, 100)
        ..close(),
      _fill(_pouchShade),
    );
    c.restore();
    // A row of stitches along the rim, and a sewn patch.
    _dashes(
      c,
      Path()
        ..moveTo(2, 24)
        ..cubicTo(30, 29, 62, 32, 92, 35),
      _line(_billTip, 2.4),
    );
    final patch = Path()
      ..moveTo(22, 50)
      ..lineTo(44, 48)
      ..lineTo(47, 68)
      ..lineTo(25, 71)
      ..close();
    c.drawPath(patch, _fill(SkyColors.coral));
    c.drawPath(patch, _line(_ink, 2.6));
    for (final (a, b) in const [
      (Offset(17, 54), Offset(25, 53)),
      (Offset(19, 65), Offset(27, 64)),
      (Offset(42, 51), Offset(50, 50)),
      (Offset(44, 63), Offset(52, 62)),
    ]) {
      c.drawLine(a, b, _line(_ink, 2.2));
    }
    c.drawPath(pouch, _line(_ink));
    c.restore();

    // The corner of his mouth says as much as his brows do.
    final corner = Path()
      ..moveTo(-8, 13)
      ..quadraticBezierTo(-17, 15 - look.corner * 3, -19, 11 - look.corner * 9);
    c.drawPath(corner, _line(_ink, 3.5));
    c.restore();
  }

  /// An envelope standing in the pouch: cream, with a wax seal in [seal].
  static void _letter(Canvas c, Offset at, double turn, Color seal) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    final paper = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-13, -30, 26, 36),
      const Radius.circular(3),
    );
    c.drawRRect(paper, _fill(_paper));
    c.drawRRect(paper, _line(_ink, 3));
    c.drawPath(
      Path()
        ..moveTo(-13, -29)
        ..lineTo(0, -17)
        ..lineTo(13, -29),
      _line(_ink, 2.4),
    );
    c.drawCircle(const Offset(0, -16), 3.6, _fill(seal));
    c.restore();
  }

  static void _dashes(Canvas c, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 11) {
        c.drawPath(
          metric.extractPath(d, math.min(d + 5.5, metric.length)),
          paint,
        );
      }
    }
  }

  /// Three short strokes over his cap: he has had a start.
  static void _startle(Canvas c) {
    for (final (from, to) in const [
      (Offset(96, 22), Offset(88, 8)),
      (Offset(142, 8), Offset(142, -8)),
      (Offset(190, 20), Offset(200, 6)),
    ]) {
      c.drawLine(from, to, _line(_ink, 4.5));
    }
  }
}

/// How Bill's face sits for a mood.
class _Look {
  const _Look({
    this.browTilt = 0,
    this.browLift = 0,
    this.lid = .13,
    this.lidSlant = 0,
    this.pupil = 1,
    this.eyeScale = 1,
    this.gaze = 0,
    this.droop = 0,
    this.corner = .4,
    this.blush = .85,
    this.gape = 0,
    this.capLift = 0,
    this.capTilt = 0,
    this.smile = false,
    this.startle = false,
  });

  /// The brows tip inward (positive, a frown) or outward (a worry), and
  /// lift off the eyes.
  final double browTilt, browLift;

  /// How much of each eye its lid covers, and how the lid slants.
  final double lid, lidSlant;
  final double pupil, eyeScale;

  /// Where he looks: positive is down.
  final double gaze;

  /// The bill hangs lower when he is glum.
  final double droop;

  /// The corner of the mouth: up (positive) or down.
  final double corner;
  final double blush;

  /// The least the bill is open in this mood.
  final double gape;
  final double capLift, capTilt;
  final bool smile, startle;

  static _Look of(StoryMood mood) => switch (mood) {
    StoryMood.plain => const _Look(),
    StoryMood.happy => const _Look(
      browLift: 5,
      browTilt: -.08,
      corner: 1,
      blush: 1,
      gape: .22,
      smile: true,
    ),
    StoryMood.surprised => const _Look(
      browLift: 11,
      browTilt: -.12,
      lid: 0,
      pupil: .6,
      eyeScale: 1.1,
      corner: 0,
      gape: .55,
      capLift: 15,
      capTilt: -.14,
      startle: true,
    ),
    StoryMood.angry => const _Look(
      browTilt: .42,
      browLift: -6,
      lid: .3,
      lidSlant: .3,
      pupil: .86,
      corner: -.8,
      blush: .5,
    ),
    StoryMood.sad => const _Look(
      browTilt: -.4,
      browLift: 1,
      lid: .4,
      lidSlant: -.26,
      gaze: 1,
      droop: .12,
      corner: -1,
      blush: .45,
      capTilt: .08,
    ),
  };
}
