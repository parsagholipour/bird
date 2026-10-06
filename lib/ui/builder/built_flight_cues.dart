import 'package:flutter/material.dart';

import '../theme.dart';

/// The cues a creator's test flight wears in flight, so it never passes
/// for a real one: a TEST FLIGHT tag on the HUD and the countdown, and on a
/// push-up or squat level the rail the finger's height steers along.

/// A lavender sticker: TEST FLIGHT.
class TestFlightTag extends StatelessWidget {
  const TestFlightTag({super.key, this.note});

  /// A few words after the tag, such as "nothing is saved".
  final String? note;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('test-flight-tag'),
    height: 30,
    padding: const EdgeInsets.fromLTRB(7, 0, 12, 0),
    decoration: BoxDecoration(
      color: SkyColors.lavender,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: SkyColors.ink, width: 2.2),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .3),
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.construction_rounded, size: 17, color: SkyColors.ink),
        const SizedBox(width: 5),
        Text(
          'TEST FLIGHT',
          style: heading(
            15,
            weight: FontWeight.w700,
          ).copyWith(height: 1.1, letterSpacing: .4),
        ),
        if (note != null) ...[
          const SizedBox(width: 6),
          Text(
            note!,
            style: bodyText(13, weight: FontWeight.w800).copyWith(height: 1.1),
          ),
        ],
      ],
    ),
  );
}

/// The finger's rail on a test of a push-up or squat level: a slim track
/// down the right edge (under the pause key) for the movement's range, the
/// sky from [top] to [bottom], with a thumb where the bird is ([height],
/// from 0 at the top of the sky to 1 at the bottom), so the creator sees
/// that the finger's height is the bird's.
class TestFingerRail extends StatelessWidget {
  const TestFingerRail({
    super.key,
    required this.height,
    this.top = .15,
    this.bottom = .85,
  });
  final double height, top, bottom;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return IgnorePointer(
      child: CustomPaint(
        key: const ValueKey('test-finger-rail'),
        size: Size.infinite,
        painter: _RailPainter(
          height: height,
          top: top,
          bottom: bottom,
          right: padding.right,
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.height,
    required this.top,
    required this.bottom,
    required this.right,
  });
  final double height, top, bottom, right;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final x = size.width - right - h * .055;
    // The track starts under the pause key; its ends are the movement's.
    final y0 = h * .19, y1 = h * bottom;
    final width = h * .028;
    final track = RRect.fromLTRBR(
      x - width / 2,
      y0,
      x + width / 2,
      y1,
      Radius.circular(width / 2),
    );
    canvas.drawRRect(
      track,
      Paint()..color = SkyColors.cream.withValues(alpha: .55),
    );
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .006
        ..color = SkyColors.ink.withValues(alpha: .45),
    );
    // The movement's two ends: the top and the bottom lanes' marks.
    for (final y in [y0 + width / 2, y1 - width / 2]) {
      canvas.drawCircle(
        Offset(x, y),
        width * .22,
        Paint()..color = SkyColors.ink.withValues(alpha: .5),
      );
    }
    // The thumb: where the bird is, with a little up-and-down glyph.
    final share = ((height - top) / (bottom - top)).clamp(0.0, 1.0);
    final at = Offset(x, y0 + width / 2 + share * (y1 - y0 - width));
    final r = h * .034;
    canvas.drawCircle(
      at + Offset(0, h * .006),
      r,
      Paint()..color = SkyColors.ink.withValues(alpha: .35),
    );
    canvas.drawCircle(at, r, Paint()..color = SkyColors.lavender);
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .007
        ..color = SkyColors.ink,
    );
    final glyph = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .006
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = SkyColors.ink;
    final a = r * .42, b = r * .2;
    for (final s in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - a, at.dy + s * b)
          ..lineTo(at.dx, at.dy + s * (b + a * .8))
          ..lineTo(at.dx + a, at.dy + s * b),
        glyph,
      );
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.height != height ||
      old.top != top ||
      old.bottom != bottom ||
      old.right != right;
}
