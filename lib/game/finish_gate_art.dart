import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../ui/theme.dart';
import 'sky_scenery.dart';

/// The finish gate of a campaign level: two candy-striped posts, a checkered
/// beam, a hanging FINISH sign and bunting, standing where the rules put the
/// line. The bird flies in front of it, so it can never hide the bird, a
/// hazard or the HUD, and everything wears the ink outline of the game's
/// other pictures so it reads over bright beaches and dark nights alike.
///
/// The gate is drawn in screen heights, centred on the line's x. A level
/// ends the moment the bird crosses, so the crossing's confetti is one still
/// burst that the frozen result frame keeps; only the flags, bunting and
/// sparkles move, and Reduced Motion stills them.
abstract final class FinishGateArt {
  /// The posts stand this far either side of the line, in screen heights:
  /// wide enough for the bird to pass between them, narrow enough to clear
  /// the hearts panel when the bird meets the line.
  static const postOffset = .135, postWidth = .056;

  /// Everything the gate paints lies within this far of the line's x.
  static const reach = .6;

  static const _outline = .0065;
  static const _ink = SkyColors.ink;

  static void paint(
    Canvas canvas,
    double h, {
    required double x,
    required double seconds,
    required bool arrived,
    required bool reducedMotion,
  }) {
    final view = canvas.getLocalClipBounds();
    if (x + h * reach < view.left || x - h * reach > view.right) return;
    final t = reducedMotion ? 0.0 : seconds;
    canvas.save();
    canvas.translate(x, 0);
    canvas.scale(h);
    _glow(canvas);
    _tape(canvas);
    for (final side in [-1.0, 1.0]) {
      _post(canvas, side * postOffset);
    }
    _beam(canvas);
    _crest(canvas);
    _bunting(canvas, t);
    _sign(canvas);
    for (final side in [-1.0, 1.0]) {
      _flag(canvas, side * postOffset, t, side);
    }
    _sparkles(canvas, t, reducedMotion);
    if (arrived) _confetti(canvas);
    canvas.restore();
    _lettering(canvas, h, x);
  }

  /// A soft column of light behind the gate, so the line stands out of dark
  /// scenery. Added light brightens a night and hardly shows on a bright day,
  /// where the outlines do the work.
  static void _glow(Canvas c) {
    c.drawRect(
      const Rect.fromLTRB(-.55, 0, .55, 1),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          colors: [
            SkyColors.yellow.withValues(alpha: 0),
            SkyColors.yellow.withValues(alpha: .32),
            SkyColors.yellow.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTRB(-.55, 0, .55, 1)),
    );
  }

  /// The line itself: a narrow checkered tape from the beam to the ground,
  /// exactly where the bird crosses.
  static void _tape(Canvas c) {
    const cell = .014, top = .23;
    for (var i = 0; top + i * cell < 1.02; i++) {
      for (var col = 0; col < 2; col++) {
        c.drawRect(
          Rect.fromLTWH((col - 1) * cell, top + i * cell, cell, cell),
          Paint()
            ..color = ((i + col).isEven ? _ink : SkyColors.cream).withValues(
              alpha: .62,
            ),
        );
      }
    }
  }

  static void _post(Canvas c, double cx) {
    const w = postWidth, top = .15;
    final rect = Rect.fromLTRB(cx - w / 2, top, cx + w / 2, 1.05);
    // The plinth sits in a soft pool of shade.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx + .012, .985),
        width: .14,
        height: .026,
      ),
      Paint()..color = _ink.withValues(alpha: .18),
    );
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(w * .3));
    c.drawRRect(
      body.shift(const Offset(.009, .004)),
      Paint()..color = _ink.withValues(alpha: .16),
    );
    c.save();
    c.clipRRect(body);
    c.drawRect(rect, Paint()..color = SkyColors.cream);
    // Diagonal candy stripes, one stripe every .08.
    final stripe = Paint()..color = SkyColors.coral;
    for (var y = top - w; y < 1.1; y += .08) {
      c.drawPath(
        Path()
          ..moveTo(rect.left, y + w)
          ..lineTo(rect.right, y)
          ..lineTo(rect.right, y + .04)
          ..lineTo(rect.left, y + .04 + w)
          ..close(),
        stripe,
      );
    }
    // Round the shaft: light down one side, shade down the other.
    c.drawRect(
      Rect.fromLTWH(cx - w * .34, top, w * .16, 1),
      Paint()..color = SkyColors.white.withValues(alpha: .45),
    );
    c.drawRect(
      Rect.fromLTRB(cx + w * .14, top, rect.right, 1.1),
      Paint()..color = _ink.withValues(alpha: .14),
    );
    c.restore();
    c.drawRRect(body, _line());
    // A cap on top and a plinth at the foot hold the shaft in place.
    for (final cap in [
      Rect.fromCenter(
        center: Offset(cx, top + .006),
        width: w * 1.3,
        height: .026,
      ),
      Rect.fromCenter(center: Offset(cx, .96), width: w * 1.9, height: .034),
    ]) {
      final rr = RRect.fromRectAndRadius(cap, Radius.circular(cap.height * .4));
      c.drawRRect(rr, Paint()..color = SkyColors.yellow);
      c.drawRRect(rr, _line());
    }
    // The finial ball.
    final ball = Offset(cx, top - .026);
    c.drawCircle(ball, .027, Paint()..color = SkyColors.yellow);
    c.drawCircle(
      ball.translate(-.008, -.008),
      .008,
      Paint()..color = SkyColors.white.withValues(alpha: .75),
    );
    c.drawCircle(ball, .027, _line());
  }

  /// The checkered beam across the top of the gate.
  static void _beam(Canvas c) {
    const cols = 14, half = postOffset + postWidth / 2 + .012;
    const cell = half * 2 / cols, top = .176;
    final rect = Rect.fromLTWH(-half, top, half * 2, cell * 2);
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(.01));
    c.drawRRect(
      body.shift(const Offset(.005, .008)),
      Paint()..color = _ink.withValues(alpha: .16),
    );
    c.save();
    c.clipRRect(body);
    c.drawRect(rect, Paint()..color = SkyColors.cream);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < cols; col++) {
        if ((row + col).isEven) continue;
        c.drawRect(
          Rect.fromLTWH(-half + col * cell, top + row * cell, cell, cell),
          Paint()..color = _ink,
        );
      }
    }
    c.drawRect(
      Rect.fromLTRB(-half, rect.bottom - .008, half, rect.bottom),
      Paint()..color = _ink.withValues(alpha: .22),
    );
    c.restore();
    c.drawRRect(body, _line());
  }

  /// A gold star crowning the beam: the level's stars are what the flight
  /// was for.
  static void _crest(Canvas c) {
    const center = Offset(0, .148);
    final star = SkyScenery.star(center, .05);
    c.drawPath(
      star.shift(const Offset(.004, .007)),
      Paint()..color = _ink.withValues(alpha: .16),
    );
    c.drawPath(star, Paint()..color = SkyColors.yellow);
    c.drawPath(
      SkyScenery.star(center.translate(-.004, -.006), .026),
      Paint()..color = SkyColors.white.withValues(alpha: .55),
    );
    c.drawPath(star, _line(.0075));
  }

  /// The FINISH board, hung from the beam on two short ropes. Its lettering
  /// is set by [_lettering] once the canvas is back at pixel scale.
  static void _sign(Canvas c) {
    const width = .27, top = .255, height = .095;
    for (final side in [-1.0, 1.0]) {
      c.drawLine(
        Offset(side * .09, .232),
        Offset(side * .09, top + .006),
        Paint()
          ..color = _ink
          ..strokeWidth = .008
          ..strokeCap = StrokeCap.round,
      );
    }
    final rect = Rect.fromLTWH(-width / 2, top, width, height);
    final board = RRect.fromRectAndRadius(rect, const Radius.circular(.024));
    c.drawRRect(
      board.shift(const Offset(.005, .009)),
      Paint()..color = _ink.withValues(alpha: .18),
    );
    c.drawRRect(board, Paint()..color = SkyColors.coral);
    // A lit upper half, a deeper lower edge and a cream rim make the board
    // a chunky slab.
    c.save();
    c.clipRRect(board);
    c.drawRect(
      Rect.fromLTWH(rect.left, top, width, height * .46),
      Paint()..color = SkyColors.white.withValues(alpha: .2),
    );
    c.drawRect(
      Rect.fromLTRB(rect.left, rect.bottom - .02, rect.right, rect.bottom),
      Paint()..color = SkyColors.coralDeep,
    );
    c.restore();
    c.drawRRect(
      board.deflate(.0095),
      Paint()
        ..color = SkyColors.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = .005,
    );
    c.drawRRect(board, _line());
  }

  /// A swag of pennants strung between the posts, below the sign.
  static void _bunting(Canvas c, double t) {
    const inner = postOffset - postWidth / 2, y = .392, sag = .038;
    c.drawPath(
      Path()
        ..moveTo(-inner, y)
        ..quadraticBezierTo(0, y + sag * 2, inner, y),
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = .005
        ..strokeCap = StrokeCap.round,
    );
    final colors = [
      SkyColors.coral,
      SkyColors.yellow,
      SkyColors.mint,
      SkyColors.lavender,
      SkyColors.white,
    ];
    const count = 7;
    for (var i = 0; i < count; i++) {
      // Along the quadratic string: sag is greatest in the middle.
      final u = (i + .5) / count;
      final px = -inner + inner * 2 * u;
      final py = y + sag * 4 * u * (1 - u);
      final sway = math.sin(t * 2.4 + i * .9) * .005;
      final flap = Path()
        ..moveTo(px - .0165, py)
        ..lineTo(px + .0165, py)
        ..lineTo(px + sway, py + .052)
        ..close();
      c.drawPath(flap, Paint()..color = colors[i % colors.length]);
      c.drawPath(flap, _line(.0035));
    }
  }

  /// A swallowtail pennant on a short pole above a post, streaming away from
  /// the bird.
  static void _flag(Canvas c, double cx, double t, double side) {
    const base = .1, tip = .05;
    final wave = math.sin(t * 3.1 + (side > 0 ? 1.7 : 0));
    c.drawLine(
      Offset(cx, base),
      Offset(cx, tip),
      Paint()
        ..color = _ink
        ..strokeWidth = .007
        ..strokeCap = StrokeCap.round,
    );
    final len = .075 + wave * .006;
    final flag = Path()
      ..moveTo(cx, tip + .002)
      ..quadraticBezierTo(
        cx + len * .5,
        tip + .004 + wave * .006,
        cx + len,
        tip + .012,
      )
      ..lineTo(cx + len * .78, tip + .03)
      ..lineTo(cx + len, tip + .048 + wave * .003)
      ..quadraticBezierTo(
        cx + len * .5,
        tip + .045 + wave * .005,
        cx,
        tip + .05,
      )
      ..close();
    c.drawPath(
      flag,
      Paint()..color = side < 0 ? SkyColors.yellow : SkyColors.coral,
    );
    c.drawPath(flag, _line(.0045));
  }

  /// Four-point twinkles either side of the gate.
  static void _sparkles(Canvas c, double t, bool reducedMotion) {
    const spots = [
      Offset(-.225, .16),
      Offset(.235, .25),
      Offset(-.215, .33),
      Offset(.225, .43),
      Offset(.06, .07),
    ];
    for (var i = 0; i < spots.length; i++) {
      final beat = reducedMotion
          ? 1.0
          : .62 + .38 * math.sin(t * 3.6 + i * 1.9);
      final r = (i == 4 ? .02 : .016) * beat;
      final p = spots[i];
      final path = Path()
        ..moveTo(p.dx, p.dy - r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
        ..close();
      c.drawPath(path, Paint()..color = SkyColors.white);
      c.drawPath(path, _line(.0035));
    }
  }

  /// A still burst above the crossing: the frozen last frame of the flight
  /// keeps it. The pieces are laid by a fixed hash, so every replay of the
  /// same crossing paints the same burst.
  static void _confetti(Canvas c) {
    final colors = [
      SkyColors.coral,
      SkyColors.yellow,
      SkyColors.mint,
      SkyColors.lavender,
      SkyColors.skyDeep,
      SkyColors.white,
    ];
    double hash(int i, int k) {
      final v = math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
      return v - v.floorToDouble();
    }

    for (var i = 0; i < 72; i++) {
      final spread = hash(i, 1), lift = hash(i, 2);
      final x = (spread - .5) * 1.1 * (.5 + lift * .5);
      final y = .05 + math.pow(lift, .85) * .72;
      // Keep the sign, the crest and the beam clear so the word stays easy
      // to read.
      if (x.abs() < .22 && y > .09 && y < .36) continue;
      final color = colors[i % colors.length];
      final fill = Paint()..color = color;
      c.save();
      c.translate(x, y);
      c.rotate(hash(i, 3) * math.pi);
      switch (i % 6) {
        case 0:
        case 1:
        case 2:
          final piece = Rect.fromCenter(
            center: Offset.zero,
            width: .028,
            height: .015,
          );
          c.drawRect(piece, fill);
          c.drawRect(piece, _line(.003));
        case 3:
        case 4:
          c.drawCircle(Offset.zero, .0095, fill);
          c.drawCircle(Offset.zero, .0095, _line(.003));
        default:
          final star = SkyScenery.star(Offset.zero, .024);
          c.drawPath(star, Paint()..color = SkyColors.yellow);
          c.drawPath(star, _line(.0042));
      }
      c.restore();
    }
  }

  /// FINISH on the sign: cream letters with an ink edge, set at pixel scale
  /// so the text stays crisp.
  static void _lettering(Canvas canvas, double h, double x) {
    final size = h * .062;
    final center = Offset(x, h * (.255 + .095 / 2 + .003));
    TextPainter word(Paint? paint, Color? color) => TextPainter(
      text: TextSpan(
        text: 'FINISH',
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: size,
          letterSpacing: size * .06,
          color: color,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final edge = word(
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .012
        ..strokeJoin = StrokeJoin.round,
      null,
    );
    final fill = word(null, SkyColors.cream);
    final at = center - Offset(fill.width / 2, fill.height / 2);
    edge.paint(canvas, at);
    fill.paint(canvas, at);
  }

  static Paint _line([double width = _outline]) => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round;
}
