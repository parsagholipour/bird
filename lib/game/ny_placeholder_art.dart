import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';

/// Placeholder painters for New York's specials: the Alley Pigeon, King Coo
/// and the Searchlight Gargoyle (rules version 43).
///
/// This is the SCAFFOLD's answer to every exhaustive `EnemyKind` and
/// `BossKind` switch: each new kind dispatches here, explicitly, so that it
/// can never fall through to Baron Bat's rig, palette or crown. The shapes are
/// deliberately plain (ink-outlined flat fills, no gradients, no layers) and
/// unmistakably not a bat: the art builders replace each call site with the
/// real painter, in the order the SCAFFOLD.md lists. `ny_placeholder_art_test`
/// fails if a new kind ever renders like Baron.
///
/// Everything is a pure function of its arguments and the simulation clock.
abstract final class NyPlaceholderArt {
  static const ink = Color(0xff18182f);

  // Alley Pigeon: cool grey with a coral beak, like the designer's palette.
  static const pigeonBody = Color(0xffa9abc8), pigeonWing = Color(0xff6c7199);
  static const pigeonBeak = Color(0xffff8f63), pigeonEye = Color(0xffffb23a);

  // King Coo: lavender plumage, a navy police cap, a brass badge.
  static const cooBody = Color(0xff9d9ac6), cooBreast = Color(0xfff2dce6);
  static const cooCap = Color(0xff283672), cooBrass = Color(0xfff3c350);

  // Searchlight Gargoyle: limestone and steel around an amber lamp.
  static const stone = Color(0xffc9b894), steel = Color(0xff7f9dbd);
  static const lamp = Color(0xffffb84a), lampHot = Color(0xfffffbe8);

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()..color = color.withValues(alpha: (color.a * alpha).clamp(0, 1));
  static Paint _line(double width, [double alpha = 1]) => Paint()
    ..color = ink.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// The accent colours the encounter, health bar and keepsakes use, so a
  /// mini-boss is never given Baron's.
  static Color tint(BossKind kind) => switch (kind) {
    BossKind.kingCoo => cooBody,
    BossKind.searchlightGargoyle => steel,
    _ => throw ArgumentError.value(kind, 'kind', 'not a mini-boss'),
  };
  static Color light(BossKind kind) => switch (kind) {
    BossKind.kingCoo => cooBrass,
    BossKind.searchlightGargoyle => lamp,
    _ => throw ArgumentError.value(kind, 'kind', 'not a mini-boss'),
  };

  /// A health-bar ramp as [light, main, deep].
  static List<Color> ramp(BossKind kind) => switch (kind) {
    BossKind.kingCoo => const [
      Color(0xffdcd6ee),
      Color(0xff7f9bff),
      Color(0xff3f4f9a),
    ],
    BossKind.searchlightGargoyle => const [
      Color(0xffffe9a8),
      Color(0xffe3b454),
      Color(0xffa8742f),
    ],
    _ => throw ArgumentError.value(kind, 'kind', 'not a mini-boss'),
  };

  /// The stamp field behind a mini-boss's headwear.
  static Color stampField(BossKind kind) => switch (kind) {
    BossKind.kingCoo => const Color(0xffe0a93a),
    BossKind.searchlightGargoyle => const Color(0xff6f86a8),
    _ => throw ArgumentError.value(kind, 'kind', 'not a mini-boss'),
  };

  // ------------------------------------------------------------- enemy --

  /// A plain pigeon, in `EnemyArt`'s painter signature: a grey egg with a
  /// round head, a coral beak and two flapping wing strokes, facing left,
  /// inside x -2.0 to 1.8 and y -1.3 to 1.3 (the designer's envelope).
  static void pigeon(
    Canvas canvas,
    double radius, {
    required double seconds,
    required bool reducedMotion,
    double lookY = 0,
    double charge = 0,
    double recoil = 0,
  }) {
    final flap = reducedMotion ? 0.0 : math.sin(seconds * 12) * .45;
    canvas.save();
    canvas.scale(radius);
    final line = _line(.08);
    // Wings behind the body.
    for (final side in [-1.0, 1.0]) {
      final wing = Path()
        ..moveTo(.1, -.2)
        ..quadraticBezierTo(.5 + side * .3, -1.2 - flap * side, 1.2, -.7 + flap)
        ..quadraticBezierTo(.9, -.2, .5, .1)
        ..close();
      if (side > 0) {
        canvas.drawPath(wing, _fill(pigeonWing));
        canvas.drawPath(wing, line);
      }
    }
    final body = Rect.fromLTRB(-.7, -.6, 1.4, .8);
    canvas.drawOval(body, _fill(pigeonBody));
    canvas.drawOval(body, line);
    canvas.drawCircle(const Offset(-.85, -.35), .5, _fill(pigeonBody));
    canvas.drawCircle(const Offset(-.85, -.35), .5, line);
    canvas.drawPath(
      Path()
        ..moveTo(-1.3, -.42)
        ..lineTo(-1.9, -.3)
        ..lineTo(-1.3, -.22)
        ..close(),
      _fill(pigeonBeak),
    );
    canvas.drawCircle(const Offset(-.95, -.45), .1, _fill(pigeonEye));
    canvas.restore();
  }

  // -------------------------------------------------------------- boss --

  /// A mini-boss's placeholder body in rig units: the origin is the hit
  /// circle's centre (radius 1), it faces left and reaches about x -3 to
  /// 4, y -3 to 3. [puff] (King Coo's chest) and [lampOpen] (the Gargoyle's
  /// lamp) are the pure 0-to-1 channels the rules expose; [alpha] fades it.
  static void rig(
    Canvas canvas,
    BossKind kind, {
    double alpha = 1,
    double puff = 0,
    double lampOpen = 0,
    bool beaten = false,
  }) {
    final line = _line(.08, alpha);
    switch (kind) {
      case BossKind.kingCoo:
        final chest = 1 + puff * .1;
        canvas.drawOval(
          Rect.fromLTRB(-.6, -.7, 3.3, .9),
          _fill(cooBody, alpha),
        );
        canvas.drawOval(Rect.fromLTRB(-.6, -.7, 3.3, .9), line);
        canvas.drawCircle(Offset.zero, chest, _fill(cooBreast, alpha));
        canvas.drawCircle(Offset.zero, chest, line);
        canvas.drawCircle(const Offset(-1.1, -1.3), .55, _fill(cooBody, alpha));
        canvas.drawCircle(const Offset(-1.1, -1.3), .55, line);
        if (!beaten) {
          final cap = RRect.fromRectAndRadius(
            Rect.fromLTRB(-1.75, -2.05, -.45, -1.6),
            const Radius.circular(.12),
          );
          canvas.drawRRect(cap, _fill(cooCap, alpha));
          canvas.drawRRect(cap, line);
        }
        canvas.drawCircle(const Offset(.02, .1), .14, _fill(cooBrass, alpha));
      case BossKind.searchlightGargoyle:
        final torso = RRect.fromRectAndRadius(
          Rect.fromLTRB(-1.6, -1.7, 2.0, 2.9),
          const Radius.circular(.3),
        );
        canvas.drawRRect(torso, _fill(stone, alpha));
        canvas.drawRRect(torso, line);
        canvas.drawRect(
          Rect.fromLTRB(-2.4, 2.9, 4.3, 3.3),
          _fill(steel, alpha),
        );
        canvas.drawRect(Rect.fromLTRB(-2.4, 2.9, 4.3, 3.3), line);
        canvas.drawCircle(
          Offset.zero,
          1,
          _fill(Color.lerp(steel, lampHot, lampOpen)!, alpha),
        );
        canvas.drawCircle(Offset.zero, 1, line);
        if (!beaten) {
          canvas.drawCircle(const Offset(-.9, -1.3), .3, _fill(lamp, alpha));
          canvas.drawCircle(const Offset(.5, -1.3), .3, _fill(lamp, alpha));
        }
      default:
        throw ArgumentError.value(kind, 'kind', 'not a mini-boss');
    }
  }

  // --------------------------------------------------- ammo and keepsakes --

  /// A plain grey pellet in unit space (hit radius 1) for any mini-boss shot.
  static void ammo(Canvas canvas, double edge) {
    canvas.drawCircle(Offset.zero, 1, _fill(stone));
    canvas.drawCircle(Offset.zero, 1, _line(edge));
  }

  /// The box [headwear] fits, in its own units.
  static Rect headwearReach(BossKind kind) => switch (kind) {
    BossKind.kingCoo => const Rect.fromLTRB(-.8, -.6, .8, .4),
    BossKind.searchlightGargoyle => const Rect.fromLTRB(-.8, -.5, .8, .5),
    _ => throw ArgumentError.value(kind, 'kind', 'not a mini-boss'),
  };

  /// What a mini-boss loses: Coo's police cap, the Gargoyle's lamp hood.
  static void headwear(Canvas canvas, BossKind kind, {double alpha = 1}) {
    final line = _line(.07, alpha);
    switch (kind) {
      case BossKind.kingCoo:
        final cap = RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.7, -.4, .7, .15),
          const Radius.circular(.15),
        );
        canvas.drawRRect(cap, _fill(cooCap, alpha));
        canvas.drawRRect(cap, line);
        canvas.drawCircle(const Offset(0, -.12), .1, _fill(cooBrass, alpha));
      case BossKind.searchlightGargoyle:
        final hood = RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.7, -.3, .7, .3),
          const Radius.circular(.2),
        );
        canvas.drawRRect(hood, _fill(steel, alpha));
        canvas.drawRRect(hood, line);
        canvas.drawCircle(Offset.zero, .18, _fill(lamp, alpha));
      default:
        throw ArgumentError.value(kind, 'kind', 'not a mini-boss');
    }
  }

  /// The lost headwear tumbling away after the killing blow, from 0.3 s to
  /// 2.7 s into the defeat: the stub of `BossEncounterArt._headwear`, without
  /// a compositing layer.
  static void headwearTumble(Canvas c, Offset at, double h, BossMotion m) {
    final t = m.death;
    if (t < .3 || t >= 2.7) return;
    final flight = t - .3;
    final travel = m.reducedMotion ? .45 : flight;
    final fade = m.reducedMotion
        ? 1 - BossMotion.ramp(t, 1.2, 1.6)
        : 1 - BossMotion.ramp(t, 2.2, 2.7);
    if (fade <= 0) return;
    final place =
        at +
        Offset(0, -h * .13) +
        Offset(h * .11 * travel, h * (-.31 * travel + .28 * travel * travel));
    c.save();
    c.translate(place.dx, place.dy);
    c.scale(h * SkyBoss.radius * .9);
    c.rotate(m.reducedMotion ? .25 : flight * 5.4);
    headwear(c, m.boss.kind, alpha: fade);
    c.restore();
  }

  /// The defeat's smoke colours as (shade, body, light).
  static (Color, Color, Color) smoke(BossKind kind) => switch (kind) {
    BossKind.kingCoo => (
      const Color(0xff3c3a5e),
      const Color(0xffc9c6e6),
      const Color(0xfff6f2fb),
    ),
    BossKind.searchlightGargoyle => (
      const Color(0xff3a3552),
      const Color(0xffc9b894),
      const Color(0xfffbf3e0),
    ),
    _ => throw ArgumentError.value(kind, 'kind', 'not a mini-boss'),
  };

  /// The health bar's medallion: a plain ramp disc, no crown.
  static void crest(
    Canvas c,
    Offset center,
    double radius,
    BossKind kind, {
    required bool fury,
  }) {
    final colors = ramp(kind);
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (fury) {
      c.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .14
          ..color = const Color(0xffff775c),
      );
    }
    c.drawCircle(center, radius * .28, _fill(ink));
  }
}
