import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/sky_enemy.dart';
import '../ui/theme.dart';

/// The small capsule above a damaged enemy. Everything is derived from the
/// enemy's hp, maxHp, hpBeforeLastHit and hit clock, so paused and replayed
/// frames repeat exactly.
abstract final class EnemyHealthBarArt {
  // Geometry in hit-radius units (r = height * SkyEnemy.radius).
  static const _width = 2.1, _thickness = .30, _frame = .095;

  /// Clearance between the enemy center and the frame's bottom edge; the
  /// character art stays within ±1.2 r, so this leaves a small gap.
  static const _clearance = 1.40;

  /// Bar center above the enemy center, in viewport-height units.
  static const lift = (_clearance + _frame + _thickness / 2) * SkyEnemy.radius;

  // Post-hit timeline (seconds since the hit).
  static const _white = .07, _cool = .08, _hold = .30, _drain = .34;
  static const _pop = .26, _fade = .16;
  static const settleSeconds = _hold + _drain;

  static const _frameInk = SkyColors.ink;
  static const _track = Color(0xff3c3a5e), _trackShade = Color(0xff27283f);
  static const _ghost = Color(0xffffe2c8);
  static const _healthy = [
    Color(0xff5fb886),
    Color(0xff86d69a),
    Color(0xffd2f5d2),
  ];
  static const _wounded = [
    Color(0xffe39b32),
    Color(0xffffc94d),
    Color(0xfffff0b0),
  ];
  static const _critical = [
    Color(0xffd75e4f),
    Color(0xfff47d64),
    Color(0xffffc2b0),
  ];

  static void paint(
    Canvas canvas,
    double height,
    SkyEnemy enemy, {
    bool reducedMotion = false,
  }) {
    final hp = enemy.hp, maxHp = enemy.maxHp;
    if (hp <= 0 || hp >= maxHp) return;
    final r = height * SkyEnemy.radius;
    final since = enemy.age - enemy.lastHitAt;
    final hit = since.isFinite && since >= 0;
    final before = hit ? math.max(enemy.hpBeforeLastHit, hp) : hp;

    // Lost health: white on impact, warm cream while it holds, then drains.
    var ghostHp = hp.toDouble();
    var ghostColor = _ghost;
    if (hit && since < settleSeconds) {
      if (reducedMotion) {
        // No sliding: the lost chunk holds, then quickly fades away.
        ghostHp = before.toDouble();
        final fade = (settleSeconds - since) / _fade;
        ghostColor = _ghost.withValues(alpha: fade.clamp(0.0, 1.0));
      } else {
        final drain = _easeInOut(((since - _hold) / _drain).clamp(0.0, 1.0));
        ghostHp = before + (hp - before) * drain;
        ghostColor = Color.lerp(
          SkyColors.white,
          _ghost,
          ((since - _white) / _cool).clamp(0.0, 1.0),
        )!;
      }
    }

    canvas.save();
    canvas.translate(enemy.x * height, (enemy.y - lift) * height);
    canvas.scale(r);
    if (hit && !reducedMotion) {
      if (before >= maxHp) {
        // First damage: the bar pops out of the enemy with a small overshoot.
        final p = (since / _pop).clamp(0.0, 1.0);
        if (p < 1) {
          final grow = _easeOutBack(p);
          canvas.translate(0, .3 * (1 - _easeOut(p)));
          canvas.scale(.5 + .5 * grow, .3 + .7 * grow);
        }
      } else if (since < .2) {
        // Later hits: a short squash-and-stretch punch.
        final k = math.pow(1 - since / .2, 3).toDouble();
        canvas.scale(1 + .08 * k, 1 + .28 * k);
      }
    }

    const half = _width / 2, t2 = _thickness / 2;
    const inner = Rect.fromLTRB(-half, -t2, half, t2);
    const round = Radius.circular(t2);
    final outer = inner.inflate(_frame);
    final outerRound = Radius.circular(t2 + _frame);

    // Contact shadow keeps the bar off bright skies without a blur.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.shift(const Offset(0, .09)), outerRound),
      Paint()..color = _frameInk.withValues(alpha: .28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, outerRound),
      Paint()..color = _frameInk,
    );
    // Track with a one-step inner shadow along its top edge.
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, round),
      Paint()..color = _trackShade,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(-half, -t2 + .09, half, t2), round),
      Paint()..color = _track,
    );

    double edge(double value) => -half + _width * value / maxHp;
    if (ghostHp > hp + .01 && ghostColor.a > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(-half, -t2, edge(ghostHp), t2),
          round,
        ),
        Paint()..color = ghostColor,
      );
    }

    final fraction = hp / maxHp;
    final tone = fraction > .6
        ? _healthy
        : fraction > .34
        ? _wounded
        : _critical;
    final right = edge(hp.toDouble());
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(-half, -t2, right, t2), round),
      Paint()..color = tone[0],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-half, -t2, right, t2 - .085),
        round,
      ),
      Paint()..color = tone[1],
    );
    // Glossy highlight band, inset from the ends.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-half + .09, -t2 + .05, right - .09, -t2 + .13),
        const Radius.circular(.04),
      ),
      Paint()..color = tone[2].withValues(alpha: .9),
    );

    // Notches every 10 HP make each shot's worth readable.
    final segments = maxHp / 10;
    if (segments > 1 && segments <= 8) {
      final notch = Paint()
        ..color = _frameInk.withValues(alpha: .5)
        ..strokeWidth = .075;
      for (var i = 10; i < maxHp; i += 10) {
        final x = edge(i.toDouble());
        canvas.drawLine(Offset(x, -t2), Offset(x, t2), notch);
      }
    }
    canvas.restore();
  }

  static double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

  static double _easeInOut(double t) =>
      t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;

  static double _easeOutBack(double t) {
    const c1 = 1.5, c3 = c1 + 1;
    final u = t - 1;
    return 1 + c3 * u * u * u + c1 * u * u;
  }
}
