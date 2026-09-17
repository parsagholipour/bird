import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';

abstract final class CourierArt {
  static const handoffDuration = .65;

  static FlightEvent? latestHandoff(FlightSimulation simulation) {
    for (final event in simulation.events.reversed) {
      if (event.kind == FlightEventKind.letterLost) return null;
      if (event.kind == FlightEventKind.letter ||
          event.kind == FlightEventKind.delivery) {
        return event;
      }
    }
    return null;
  }

  static bool collecting(
    FlightSimulation simulation, {
    required bool reducedMotion,
  }) {
    if (reducedMotion) return false;
    final event = latestHandoff(simulation);
    return event?.kind == FlightEventKind.letter &&
        event!.gateWorldX != null &&
        simulation.elapsed - event.at >= 0 &&
        simulation.elapsed - event.at < handoffDuration;
  }

  static void letter(
    Canvas c,
    Offset center,
    double width, {
    bool gold = false,
  }) {
    final r = Rect.fromCenter(center: center, width: width, height: width * .7);
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(const Offset(0, 2)),
        Radius.circular(width * .09),
      ),
      Paint()..color = SkyColors.ink.withValues(alpha: .18),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(width * .09)),
      Paint()..color = gold ? SkyColors.yellow : SkyColors.cream,
    );
    c.drawPath(
      Path()
        ..moveTo(r.left + width * .05, r.top + width * .08)
        ..lineTo(center.dx, center.dy + width * .06)
        ..lineTo(r.right - width * .05, r.top + width * .08),
      Paint()
        ..color = SkyColors.coralDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * .045
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawCircle(
      center + Offset(0, width * .06),
      width * .065,
      Paint()..color = SkyColors.coralDeep,
    );
  }

  static void station(
    Canvas c,
    Offset center,
    double h,
    CourierStop stop, {
    required bool carrying,
    bool handled = false,
    bool showLabel = true,
  }) {
    final pickup = stop == CourierStop.pickup;
    c.drawCircle(
      center,
      h * .048,
      Paint()
        ..color = (pickup && !handled ? SkyColors.yellow : SkyColors.mint)
            .withValues(alpha: .85),
    );
    c.drawCircle(
      center,
      h * .048,
      Paint()
        ..color = SkyColors.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (pickup && handled) {
      c.drawPath(
        Path()
          ..moveTo(center.dx - h * .018, center.dy)
          ..lineTo(center.dx - h * .004, center.dy + h * .012)
          ..lineTo(center.dx + h * .022, center.dy - h * .016),
        Paint()
          ..color = SkyColors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .006
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else if (pickup) {
      letter(c, center, h * .06);
    } else {
      final r = Rect.fromCenter(
        center: center,
        width: h * .051,
        height: h * .065,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(h * .008)),
        Paint()..color = carrying || handled ? SkyColors.teal : SkyColors.muted,
      );
      c.drawLine(
        Offset(r.left + h * .009, r.top + h * .018),
        Offset(r.right - h * .009, r.top + h * .018),
        Paint()
          ..color = SkyColors.cream
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(
        Offset(center.dx, r.bottom - h * .014),
        h * .004,
        Paint()..color = SkyColors.yellow,
      );
      if (handled) {
        final flag = Offset(r.right - h * .004, r.top + h * .008);
        c.drawLine(
          flag,
          flag - Offset(0, h * .035),
          Paint()
            ..color = SkyColors.coralDeep
            ..strokeWidth = h * .004
            ..strokeCap = StrokeCap.round,
        );
        c.drawPath(
          Path()
            ..moveTo(flag.dx, flag.dy - h * .035)
            ..lineTo(flag.dx + h * .024, flag.dy - h * .028)
            ..lineTo(flag.dx, flag.dy - h * .020)
            ..close(),
          Paint()..color = SkyColors.coral,
        );
      }
    }
    if (!showLabel) return;
    final painter = TextPainter(
      text: TextSpan(
        text: pickup ? 'PICK UP' : 'POSTBOX',
        style: bodyText(h * .025),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelCenter =
        center + Offset(0, center.dy < h * .3 ? h * .078 : -h * .078);
    final background = Rect.fromCenter(
      center: labelCenter,
      width: painter.width + 14,
      height: painter.height + 8,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(background, const Radius.circular(8)),
      Paint()..color = SkyColors.cream.withValues(alpha: .94),
    );
    painter.paint(
      c,
      labelCenter - Offset(painter.width / 2, painter.height / 2),
    );
  }

  static void handoff(
    Canvas canvas,
    double height,
    FlightSimulation simulation, {
    required bool reducedMotion,
  }) {
    if (reducedMotion) return;
    final event = latestHandoff(simulation);
    if (event == null || event.gateWorldX == null || event.gateY == null) {
      return;
    }
    final age = simulation.elapsed - event.at;
    if (age < 0 || age >= 1.4) return;
    final gate = Offset(
      (event.gateWorldX! - simulation.distance) * height,
      event.gateY! * height,
    );
    final delivery = event.kind == FlightEventKind.delivery;
    if (age < handoffDuration) {
      final t = age / handoffDuration;
      final eased = t * t * (3 - 2 * t);
      final parcel = Offset(
        (FlightSimulation.birdX + .045) * height,
        ((delivery ? event.y : simulation.birdY) + .065) * height,
      );
      final from = delivery ? parcel : gate;
      final to = delivery ? gate : parcel;
      final control = Offset(
        (from.dx + to.dx) / 2,
        math.max(height * .06, math.min(from.dy, to.dy) - height * .11),
      );
      final position =
          from * ((1 - eased) * (1 - eased)) +
          control * (2 * (1 - eased) * eased) +
          to * (eased * eased);
      // Small approach beads make the transfer direction clear without a line
      // across the bird's next aiming mark.
      for (var i = 1; i <= 3; i++) {
        final beadT = (eased - i * .09).clamp(0.0, 1.0);
        final bead =
            from * ((1 - beadT) * (1 - beadT)) +
            control * (2 * (1 - beadT) * beadT) +
            to * (beadT * beadT);
        canvas.drawCircle(
          bead,
          height * .003 * (4 - i) / 3,
          Paint()..color = SkyColors.cream.withValues(alpha: .6 - i * .12),
        );
      }
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(math.sin(t * math.pi) * (delivery ? -.22 : .22));
      letter(
        canvas,
        Offset.zero,
        height * (.057 - (delivery ? .020 * eased : 0)),
        gold: true,
      );
      canvas.restore();
    } else if (delivery) {
      final t = (age - handoffDuration) / (1.4 - handoffDuration);
      for (var i = 0; i < 3; i++) {
        final center =
            gate +
            Offset(
              (i - 1) * height * (.025 + t * .025),
              -height * (.052 + t * .07) + (i == 1 ? -height * .018 : 0),
            );
        final radius = height * .012 * (1 - t * .3);
        final heart = Path()
          ..moveTo(center.dx, center.dy + radius)
          ..cubicTo(
            center.dx - radius * 2,
            center.dy - radius * .2,
            center.dx - radius,
            center.dy - radius * 1.7,
            center.dx,
            center.dy - radius * .6,
          )
          ..cubicTo(
            center.dx + radius,
            center.dy - radius * 1.7,
            center.dx + radius * 2,
            center.dy - radius * .2,
            center.dx,
            center.dy + radius,
          )
          ..close();
        canvas.drawPath(
          heart,
          Paint()..color = SkyColors.coral.withValues(alpha: 1 - t),
        );
      }
    }
  }
}
