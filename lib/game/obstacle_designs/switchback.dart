import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../ui/theme.dart';
import '../sky_scenery.dart';

/// Opaque wayfinding post for one switchback column.
///
/// Appearance picks a festival structure: offset enamel steps, a woven sash,
/// or hitch-ring pennants. Every marker points at the flight opening.
abstract final class SwitchbackDesign {
  static void paint(
    Canvas c,
    Rect r, {
    required bool top,
    required double seconds,
    required bool reducedMotion,
    required bool cleared,
    required bool perfect,
    required int appearance,
    required Color accent,
  }) {
    if (!r.isFinite || r.isEmpty) return;
    final variant = (appearance % 3 + 3) % 3;
    final clock = seconds.isFinite ? seconds : 0.0;
    final sky = SkyPalette.at(clock);
    final sway = reducedMotion
        ? 0.0
        : math.sin(clock * 1.35 + appearance) * 1.8;
    final enamel = Color.lerp(
      Color.lerp(accent, sky.land, .14)!,
      SkyColors.mint,
      cleared ? .3 : 0,
    )!;
    final light = Color.lerp(enamel, SkyColors.cream, .58)!;
    final deep = Color.lerp(enamel, SkyColors.ink, .24)!;
    final bone = Color.lerp(SkyColors.cream, sky.haze, .12)!;
    final metal = Color.lerp(SkyColors.gold, sky.accent, .2)!;
    final shade = Color.lerp(SkyColors.ink, sky.land, .46)!;
    final cloth = Color.lerp(light, SkyColors.sand, .3)!;
    final banner = Color.lerp(light, accent, .18)!;
    final lip = r.height >= 8 ? 4.0 : math.min(3.0, r.height);
    final bevelH = r.height - lip >= 3 ? 3.0 : 0.0;
    final reserve = lip + bevelH;
    final cap = r.height >= reserve + 28 ? 6.0 : 0.0;
    final innerTop = top ? r.top + cap : r.top + reserve;
    final innerBottom = top ? r.bottom - reserve : r.bottom - cap;
    final body = innerBottom - innerTop >= 4
        ? Rect.fromLTRB(r.left, innerTop, r.right, innerBottom)
        : Rect.zero;
    final rail = !body.isEmpty && body.width >= 18
        ? math.min(3.5, body.width * .09)
        : 0.0;
    final signH = !body.isEmpty && body.height >= 12 && body.width >= 14
        ? math.min(12.0, math.max(8.0, body.height * .2))
        : 0.0;
    final field = _field(body, top, signH, rail);
    final sign = _signZone(body, top, signH, rail);

    c.save();
    c.clipRect(r);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [light, enamel, shade],
          stops: const [0, .58, 1],
        ).createShader(r),
    );
    if (!body.isEmpty && rail >= 2) {
      c.drawRect(
        Rect.fromLTWH(body.right - rail, body.top, rail, body.height),
        Paint()..color = shade,
      );
    }
    if (!body.isEmpty && body.width >= 20 && body.height >= 8) {
      c.drawRect(
        Rect.fromLTWH(body.left, body.top, 2, body.height),
        Paint()..color = bone,
      );
    }
    if (!field.isEmpty && field.width >= 10 && field.height >= 8) {
      switch (variant) {
        case 0:
          _steps(c, field, top, sway, light, deep, metal);
        case 1:
          _weave(c, field, top, sway, cloth, deep, metal, bone);
        default:
          _pennants(c, field, top, sway, banner, deep, metal, bone);
      }
    }
    _sign(c, sign, top, sway, deep, metal);
    if (cap >= 4) {
      final y = top ? r.top : r.bottom - cap;
      c.drawRect(
        Rect.fromLTWH(r.left, y, r.width, cap),
        Paint()..color = shade,
      );
      final peg = math.min(2.2, cap * .34);
      if (peg >= 1.3 && r.width >= 16) {
        final cy = y + cap / 2;
        _rivet(c, Offset(r.left + r.width * .3, cy), peg, metal, bone);
        _rivet(c, Offset(r.left + r.width * .7, cy), peg, metal, bone);
      }
    }
    if (bevelH > 0) {
      final y = top ? r.bottom - reserve : r.top + lip;
      c.drawRect(
        Rect.fromLTWH(r.left, y, r.width, bevelH),
        Paint()..color = Color.lerp(deep, SkyColors.rock, .35)!,
      );
    }
    final lipY = top ? r.bottom - lip : r.top;
    c.drawRect(
      Rect.fromLTWH(r.left, lipY, r.width, lip),
      Paint()..color = SkyColors.cream,
    );
    if (lip >= 3) {
      c.drawRect(
        Rect.fromLTWH(
          r.left,
          top ? lipY + lip - 1.15 : lipY,
          r.width,
          1.15,
        ),
        Paint()..color = SkyColors.white,
      );
    }
    if ((cleared || perfect) && r.width >= 14 && r.height >= reserve + 12) {
      _marks(c, r, top, reserve, perfect);
    }
    c.restore();
  }

  static Rect _field(Rect body, bool top, double signH, double rail) {
    if (body.isEmpty) return Rect.zero;
    final right = body.right - 2 - rail;
    final left = body.left + 2;
    final topY = top ? body.top : body.top + signH;
    final bottomY = top ? body.bottom - signH : body.bottom;
    if (right - left < 8 || bottomY - topY < 8) return Rect.zero;
    return Rect.fromLTRB(left, topY, right, bottomY);
  }

  static Rect _signZone(Rect body, bool top, double signH, double rail) {
    if (body.isEmpty || signH < 8) return Rect.zero;
    final right = body.right - 2 - rail;
    final left = body.left + 2;
    if (right - left < 12) return Rect.zero;
    return Rect.fromLTRB(
      left,
      top ? body.bottom - signH : body.top,
      right,
      top ? body.bottom : body.top + signH,
    );
  }

  static void _steps(
    Canvas c,
    Rect field,
    bool top,
    double sway,
    Color light,
    Color deep,
    Color metal,
  ) {
    final n = _count(field.height, 34, 14);
    if (n == 0) return;
    final pitch = field.height / n;
    final gap = math.min(14.0, math.max(4.0, pitch * .36));
    final depth = math.min(22.0, pitch - gap);
    if (depth < 8) return;
    final plateW = math.min(field.width * .7, field.width - 3);
    if (plateW < 8) return;
    c.save();
    c.clipRect(field);
    c.drawRect(
      Rect.fromCenter(
        center: field.center,
        width: 2.6,
        height: field.height,
      ),
      Paint()..color = metal,
    );
    for (var i = 0; i < n; i++) {
      final slot = _span(field, top, i * pitch, depth);
      if (slot.height < 8) continue;
      final onLeft = i.isEven;
      final plate = Rect.fromLTWH(
        onLeft ? field.left : field.right - plateW,
        slot.top,
        plateW,
        slot.height,
      );
      if (plate.right > field.right + .1 || plate.left < field.left - .1) {
        continue;
      }
      c.drawRRect(
        RRect.fromRectAndRadius(plate, const Radius.circular(4)),
        Paint()..color = onLeft ? light : deep,
      );
      final treadH = math.min(2.6, plate.height * .2);
      c.drawRect(
        Rect.fromLTWH(
          plate.left,
          top ? plate.bottom - treadH : plate.top,
          plate.width,
          treadH,
        ),
        Paint()..color = metal,
      );
      _plateArrow(c, plate, top, i == 0 ? sway : 0, onLeft ? deep : light);
      _rivet(c, Offset(field.center.dx, slot.center.dy), 2, metal, light);
      if (i < n - 1 && pitch - depth >= 10) {
        _rivet(
          c,
          Offset(field.center.dx, _yAt(field, top, (i + .5) * pitch)),
          1.7,
          metal,
          light,
        );
      }
    }
    c.restore();
  }

  static void _weave(
    Canvas c,
    Rect field,
    bool top,
    double sway,
    Color cloth,
    Color deep,
    Color metal,
    Color bone,
  ) {
    final n = _count(field.height, 22, 12);
    if (n == 0) return;
    final pitch = field.height / n;
    final gap = math.min(8.0, math.max(3.0, pitch * .28));
    final depth = math.min(16.0, pitch - gap);
    if (depth < 8) return;
    c.save();
    c.clipRect(field);
    for (var i = 0; i < n; i++) {
      final slot = _span(field, top, i * pitch, depth);
      if (slot.height < 8 || slot.width < 8) continue;
      final fromLeft = i.isEven;
      c.drawRRect(
        RRect.fromRectAndRadius(slot, const Radius.circular(3)),
        Paint()..color = fromLeft ? deep : cloth,
      );
      final warpW = math.max(6.0, slot.width * .38);
      if (warpW < slot.width - 2) {
        final slack = math.min(2.2, (slot.width - warpW) / 2);
        final base = fromLeft ? slot.left + slack : slot.right - warpW - slack;
        final travel = i == 0 ? sway : 0.0;
        final left = math.max(
          slot.left,
          math.min(slot.right - warpW, base + travel),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, slot.top, warpW, slot.height),
            const Radius.circular(2),
          ),
          Paint()..color = fromLeft ? bone : deep,
        );
      }
      if (slot.height >= 10 && slot.width >= 12) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              slot.left + 2,
              slot.center.dy - 1.6,
              slot.width - 4,
              3.2,
            ),
            const Radius.circular(1.5),
          ),
          Paint()..color = metal,
        );
      }
      final gapH = pitch - depth;
      final tabW = math.min(5.0, field.width * .16);
      if (i < n - 1 && gapH >= 2.5 && tabW >= 3) {
        final gapRect = _span(field, top, i * pitch + depth, gapH);
        if (gapRect.height >= 2) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                fromLeft ? field.left : field.right - tabW,
                gapRect.top,
                tabW,
                gapRect.height,
              ),
              const Radius.circular(1.5),
            ),
            Paint()..color = metal,
          );
        }
      }
    }
    c.restore();
  }

  static void _pennants(
    Canvas c,
    Rect field,
    bool top,
    double sway,
    Color banner,
    Color deep,
    Color metal,
    Color bone,
  ) {
    final n = _count(field.height, 30, 16);
    if (n == 0) return;
    final pitch = field.height / n;
    final gap = math.min(8.0, math.max(3.0, pitch * .24));
    final depth = math.min(26.0, pitch - gap);
    if (depth < 12) return;
    final step = math.min(6.0, field.width * .16);
    c.save();
    c.clipRect(field);
    for (var i = 0; i < n; i++) {
      final slot = _span(field, top, i * pitch, depth);
      if (slot.height < 12 || slot.width < 10) continue;
      final hitchLeft = i.isEven;
      final board = Rect.fromLTRB(
        field.left + (hitchLeft ? 0 : step),
        slot.top,
        field.right - (hitchLeft ? step : 0),
        slot.bottom,
      );
      if (board.width < 10) continue;
      final point = math.min(8.0, board.height * .32);
      c.drawPath(
        _pennant(board, top, point),
        Paint()..color = hitchLeft ? deep : banner,
      );
      c.drawPath(
        _pennant(board, top, point),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.35
          ..color = bone,
      );
      final backY = top ? board.top + 2 : board.bottom - 2;
      final tipY = top ? board.bottom - 1 : board.top + 1;
      if ((tipY - backY).abs() >= 4) {
        c.drawLine(
          Offset(board.center.dx, backY),
          Offset(board.center.dx, tipY),
          Paint()
            ..color = bone
            ..strokeWidth = 1.7
            ..strokeCap = StrokeCap.round,
        );
      }
      final ringR = math.min(3.1, board.height * .18);
      if (ringR >= 1.6 && board.width >= 16) {
        final gx = hitchLeft ? board.left + ringR + 1.5 : board.right - ringR - 1.5;
        final gy = math.max(
          board.top + ringR + 1,
          math.min(
            board.bottom - ringR - 1,
            board.center.dy + (i == 0 ? sway : 0),
          ),
        );
        final hole = hitchLeft ? deep : banner;
        c.drawCircle(Offset(gx, gy), ringR, Paint()..color = metal);
        c.drawCircle(Offset(gx, gy), ringR * .42, Paint()..color = hole);
      }
      final gapH = pitch - depth;
      if (i < n - 1 && gapH >= 2.5) {
        final gapRect = _span(field, top, i * pitch + depth, gapH);
        if (gapRect.height >= 2) {
          c.drawRect(
            Rect.fromLTWH(
              hitchLeft ? field.left : field.right - 3,
              gapRect.top,
              3,
              gapRect.height,
            ),
            Paint()..color = metal,
          );
        }
      }
    }
    c.restore();
  }

  static void _sign(
    Canvas c,
    Rect zone,
    bool top,
    double sway,
    Color fill,
    Color metal,
  ) {
    if (zone.isEmpty || zone.width < 12 || zone.height < 8) return;
    final h = math.min(zone.height - 1, 10.0);
    final w = math.min(zone.width * .74, 30.0);
    if (w < 12 || h < 7) return;
    final badge = Rect.fromCenter(center: zone.center, width: w, height: h);
    c.drawRRect(
      RRect.fromRectAndRadius(badge, Radius.circular(h / 2)),
      Paint()..color = fill,
    );
    final rim = badge.deflate(1.1);
    if (rim.width > 2 && rim.height > 2) {
      c.drawRRect(
        RRect.fromRectAndRadius(rim, Radius.circular(math.max(1, rim.height / 2))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15
          ..color = SkyColors.cream,
      );
    }
    final toward = top ? 1.0 : -1.0;
    final length = math.min(h * .5, h - 3);
    final half = math.min(w * .18, 5.2);
    if (length >= 2 && half >= 1.4) {
      final nudged = badge.center.dy + toward * (h * .14 + sway * .18);
      final base = nudged - toward * length;
      final lo = math.min(nudged, base);
      final hi = math.max(nudged, base);
      final tipY = lo >= badge.top + .8 && hi <= badge.bottom - .8
          ? nudged
          : badge.center.dy + toward * h * .14;
      _arrow(c, Offset(badge.center.dx, tipY), toward, half, length, bone());
    }
    if (w >= 18) {
      _rivet(
        c,
        Offset(badge.left + 3.5, badge.center.dy),
        math.min(1.6, h * .16),
        metal,
        SkyColors.cream,
      );
    }
  }

  static Color bone() => SkyColors.cream;

  static void _plateArrow(
    Canvas c,
    Rect plate,
    bool top,
    double sway,
    Color color,
  ) {
    final toward = top ? 1.0 : -1.0;
    final length = math.min(6.5, plate.height * .42);
    final half = math.min(4.2, plate.width * .16);
    if (length < 2.5 || half < 1.6) return;
    final edge = top ? plate.bottom - 4.2 : plate.top + 4.2;
    final nudged = edge + toward * sway * .35;
    final base = nudged - toward * length;
    final lo = math.min(nudged, base);
    final hi = math.max(nudged, base);
    final tipY = lo >= plate.top + 1 && hi <= plate.bottom - 1 ? nudged : edge;
    final x = plate.center.dx;
    _arrow(c, Offset(x, tipY), toward, half, length, color);
  }

  static void _marks(
    Canvas c,
    Rect r,
    bool top,
    double reserve,
    bool perfect,
  ) {
    final inward = top ? -1.0 : 1.0;
    final rim = top ? r.bottom : r.top;
    final room = r.height - reserve - 6;
    final n = perfect ? math.min(3, math.max(1, (room / 11).floor())) : 1;
    final radius = perfect ? 2.8 : 2.4;
    final x = r.right - radius - 1.6;
    for (var i = 0; i < n; i++) {
      final y = rim + inward * (reserve + radius + 2 + i * 11);
      if (x - radius < r.left || x + radius > r.right) return;
      if (y - radius < r.top || y + radius > r.bottom) return;
      _bead(
        c,
        Offset(x, y),
        perfect ? (i == 0 ? SkyColors.yellow : SkyColors.gold) : SkyColors.mint,
        radius,
      );
    }
  }

  static Path _pennant(Rect board, bool top, double point) {
    final left = board.left;
    final right = board.right;
    final mid = board.center.dx;
    if (top) {
      final hem = board.bottom - point;
      return Path()
        ..moveTo(left, board.top)
        ..lineTo(right, board.top)
        ..lineTo(right, hem)
        ..lineTo(mid, board.bottom)
        ..lineTo(left, hem)
        ..close();
    }
    final hem = board.top + point;
    return Path()
      ..moveTo(left, board.bottom)
      ..lineTo(right, board.bottom)
      ..lineTo(right, hem)
      ..lineTo(mid, board.top)
      ..lineTo(left, hem)
      ..close();
  }

  static Rect _span(Rect field, bool top, double from, double depth) {
    if (depth <= 0 || from < -0.1 || from + depth > field.height + 0.2) {
      return Rect.zero;
    }
    final opening = top ? field.bottom : field.top;
    final inward = top ? -1.0 : 1.0;
    final a = opening + inward * from;
    final b = a + inward * depth;
    return Rect.fromLTRB(field.left, math.min(a, b), field.right, math.max(a, b));
  }

  static double _yAt(Rect field, bool top, double from) {
    final opening = top ? field.bottom : field.top;
    return opening + (top ? -from : from);
  }

  static int _count(double room, double preferred, double minRoom) {
    if (room < minRoom || preferred <= 0) return 0;
    return math.min(12, math.max(1, (room / preferred).floor()));
  }

  static void _arrow(
    Canvas c,
    Offset tip,
    double toward,
    double halfW,
    double length,
    Color color,
  ) {
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - halfW, tip.dy - toward * length)
        ..lineTo(tip.dx + halfW, tip.dy - toward * length)
        ..close(),
      Paint()..color = color,
    );
  }

  static void _rivet(Canvas c, Offset p, double radius, Color metal, Color shine) {
    if (radius < 1.2) return;
    c.drawCircle(p, radius, Paint()..color = metal);
    c.drawCircle(
      p + Offset(-radius * .28, -radius * .28),
      math.max(.6, radius * .36),
      Paint()..color = shine,
    );
  }

  static void _bead(Canvas c, Offset p, Color color, double radius) {
    c.drawCircle(p, radius, Paint()..color = color);
    c.drawCircle(
      p + Offset(-radius * .28, -radius * .28),
      math.max(.6, radius * .34),
      Paint()..color = SkyColors.cream,
    );
  }
}
