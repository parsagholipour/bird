import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'dragon_hud_art.dart';
import 'pirate_hud_art.dart';

/// The slim boss strip at the top center of the flight: one row with a
/// crest, the boss name, a health bar with a damage chip, and hit points.
///
/// Encounter states live inside the row instead of below it: fury tints the
/// bar and flashes a short tag in the emptied track, and the Dusk Empress
/// veil creeps over the bar and locks it with a shield badge.
///
/// Everything is derived from the boss clock and hit history, so paused,
/// replayed and captured frames repeat exactly.
abstract final class BossHealthBarArt {
  static const _night = Color(0xff171c39), _nightDeep = Color(0xff0f1330);
  static const _track = Color(0xff2e2b4b), _trackShade = Color(0xff1f1d38);
  static const _cream = Color(0xfffff2c9), _gold = Color(0xffffd878);
  static const _ember = Color(0xffff775c), _emberText = Color(0xffffb89e);
  static const _veil = Color(0xffbdefff), _chip = Color(0xffffe6c4);
  static const _mint = Color(0xffa8e8bc), _dim = Color(0xff9a96b8);

  /// Fill ramps as [light, main, deep].
  static const _baron = [
    Color(0xffffedb0),
    Color(0xffffcf5c),
    Color(0xffd99a2e),
  ];
  static const _spitter = [
    Color(0xffdcffc9),
    Color(0xff6fe3a4),
    Color(0xff34a771),
  ];
  static const _moth = [
    Color(0xffffdcee),
    Color(0xfff29cc6),
    Color(0xffb95c92),
  ];
  static const _pirate = [
    Color(0xffcaf7ef),
    Color(0xff4fd1c5),
    Color(0xff22919b),
  ];
  static const _fury = [
    Color(0xffffd0a8),
    Color(0xffff775c),
    Color(0xffd23f3a),
  ];
  static const _shield = [
    Color(0xffffffff),
    Color(0xffbdefff),
    Color(0xff79b9dc),
  ];

  // Post-hit timeline (seconds since the hit), matching the small enemy bars.
  static const _white = .07, _cool = .10, _hold = .32, _drain = .42;
  static const _fade = .18;
  static const chipSeconds = _hold + _drain;

  /// The FURY tag shows for this long after the boss crosses half health.
  static const furyTagSeconds = 2.2, _tagFade = .5;

  /// Accent color that identifies each boss on the strip.
  static Color accent(SkyBoss boss) => _ramp(boss.kind)[1];

  static List<Color> _ramp(BossKind kind) => switch (kind) {
    BossKind.baronBat => _baron,
    BossKind.spitterBeetle => _spitter,
    BossKind.duskMoth => _moth,
    BossKind.pirate => _pirate,
    BossKind.dragon => DragonHudArt.lava,
  };

  /// The strip, for layout checks.
  static Rect bounds(Size size, SkyBoss boss) => _Layout(size).strip;

  /// The health track inside the strip.
  static Rect track(Size size, SkyBoss boss) => _Layout(size).bar;

  static void paint(
    Canvas c,
    Size size,
    SkyBoss boss, {
    bool reducedMotion = false,
  }) {
    if (boss.inCutscene) return;
    // A dragon whose clock has gone bad is not drawn (nothing to trust).
    if (boss.isDragon && !boss.age.isFinite) return;
    final l = _Layout(size);
    final u = l.u;
    final defeated = boss.phase == BossPhase.defeated;
    final arriving = boss.phase == BossPhase.arriving;
    final shielded = boss.shielded;
    final warning = shielded ? 0.0 : boss.shieldWarning;
    final fury = boss.enraged && !defeated && !arriving;
    final critical = !defeated && !arriving && boss.hp / boss.maxHp <= .15;
    final since = boss.age - boss.lastHitAt;
    final wave = reducedMotion ? .5 : .5 + .5 * math.sin(boss.age * 6.5);
    final blink = reducedMotion
        ? 1.0
        : .55 + .45 * math.cos(boss.age * math.pi * 5);
    final base = _ramp(boss.kind)[1];

    // Strip: a thin pill with a hairline accent border.
    final strip = RRect.fromRectAndRadius(
      l.strip,
      Radius.circular(l.strip.height / 2),
    );
    // The pirate's plate is a rope-laced plank, drawn by PirateHudArt.
    final pirate = boss.isPirate;
    // The dragon's is an obsidian plate rimmed in gold (DragonHudArt).
    final dragon = boss.isDragon;
    if (dragon) {
      // Each hit shudders the dragon's plate by a pixel.
      final jolt = DragonHudArt.jolt(since, u, reduced: reducedMotion);
      c.save();
      c.translate(jolt.dx, jolt.dy);
    }
    if (!pirate && !dragon) {
      c.drawRRect(
        strip.shift(Offset(0, 1.5 * u)),
        Paint()..color = _nightDeep.withValues(alpha: .2),
      );
      c.drawRRect(strip, Paint()..color = _night.withValues(alpha: .88));
    }
    final fresh = since.isFinite && since >= 0 && since < .1 && !reducedMotion
        ? 1 - since / .1
        : 0.0;
    final furyAge = boss.age - boss.enragedAt;
    final onset = !reducedMotion && furyAge >= 0 && furyAge < .6
        ? 1 - furyAge / .6
        : 0.0;
    final border = shielded
        ? _veil.withValues(alpha: .8)
        : warning > 0
        ? Color.lerp(base, _veil, warning)!.withValues(alpha: .4 + .5 * blink)
        : fury
        ? _ember.withValues(alpha: .5 + .3 * wave)
        : defeated
        ? _mint.withValues(alpha: .6)
        : base.withValues(alpha: .45);
    if (dragon) {
      DragonHudArt.frame(
        c,
        l.strip,
        u,
        fury: fury,
        defeated: defeated,
        wave: wave,
        flash: math.max(fresh * .6, onset),
        time: boss.age,
        reduced: reducedMotion,
      );
    } else if (pirate) {
      PirateHudArt.frame(
        c,
        l.strip,
        u,
        fury: fury,
        defeated: defeated,
        wave: wave,
        flash: math.max(fresh * .6, onset),
      );
    } else {
      c.drawRRect(
        strip,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * u
          ..color = Color.lerp(border, _cream, math.max(fresh * .6, onset))!,
      );
    }
    if (onset > 0) {
      // A short flare the moment the boss crosses into fury.
      c.drawRRect(
        strip.inflate(2.5 * u * (1 - onset)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * u
          ..color = _ember.withValues(alpha: .5 * onset),
      );
    }

    _crest(c, l, boss, fury: fury, shielded: shielded);

    final name = l.name(
      boss.name.toUpperCase(),
      defeated ? _mint : _cream,
      // Carved lettering on the pirate's plank.
      shadows: pirate || dragon
          ? [Shadow(color: PirateHudArt.ink, offset: Offset(0, .9 * u))]
          : null,
    );
    name.paint(c, Offset(l.nameLeft, l.strip.center.dy - name.height / 2));

    if (!arriving) {
      final hp = _painter(
        defeated ? '0' : '${boss.hp}',
        10.5 * u,
        shielded
            ? _veil
            : critical
            ? Color.lerp(_ember, _cream, 1 - wave)!
            : fury
            ? _emberText
            : _gold,
      );
      final max = _painter('/${boss.maxHp}', 7.5 * u, _dim);
      final baseline =
          l.strip.center.dy +
          hp.computeDistanceToActualBaseline(TextBaseline.alphabetic) -
          hp.height / 2;
      void at(TextPainter p, double x) => p.paint(
        c,
        Offset(
          x,
          baseline - p.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        ),
      );
      at(max, l.hpRight - max.width);
      at(hp, l.hpRight - max.width - hp.width - .5 * u);
    }

    _bar(
      c,
      l,
      boss,
      shielded
          ? _shield
          : fury || critical
          ? _fury
          : _ramp(boss.kind),
      reducedMotion: reducedMotion,
      arriving: arriving,
      defeated: defeated,
      fury: fury,
      critical: critical,
      shielded: shielded,
      warning: warning,
      blink: blink,
      wave: wave,
    );
    if (dragon) {
      DragonHudArt.heartBanner(
        c,
        l.strip,
        l.bar,
        u,
        boss,
        reduced: reducedMotion,
      );
      c.restore();
    }
  }

  static void _crest(
    Canvas c,
    _Layout l,
    SkyBoss boss, {
    required bool fury,
    required bool shielded,
  }) {
    final u = l.u, center = l.crest, r = l.crestRadius;
    if (boss.isDragon) {
      DragonHudArt.crest(c, center, r, u, fury: fury);
      return;
    }
    if (boss.isPirate) {
      PirateHudArt.crest(c, center, r, u, glass: fury ? _fury : _pirate, fury: fury);
      return;
    }
    final ramp = shielded ? _shield : _ramp(boss.kind);
    final disc = Rect.fromCircle(center: center, radius: r);
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ramp[0], ramp[1], ramp[2]],
          stops: const [0, .45, 1],
        ).createShader(disc),
    );
    if (fury) {
      c.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * u
          ..color = _ember,
      );
    }
    if (boss.isSpitter) {
      _flaskCrown(c, center, r);
      return;
    }
    // Every boss is royalty: a crown sits on the medallion.
    final cw = r * 1.2, ch = r * .84;
    final o = center + Offset(-cw / 2, -ch / 2 + r * .04);
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy + ch)
        ..lineTo(o.dx, o.dy + ch * .2)
        ..lineTo(o.dx + cw * .27, o.dy + ch * .55)
        ..lineTo(o.dx + cw * .5, o.dy)
        ..lineTo(o.dx + cw * .73, o.dy + ch * .55)
        ..lineTo(o.dx + cw, o.dy + ch * .2)
        ..lineTo(o.dx + cw, o.dy + ch)
        ..close(),
      Paint()..color = _night,
    );
  }

  /// The Spitter King's crown for the medallion: a band of three flasks.
  static void _flaskCrown(Canvas c, Offset center, double r) {
    final w = r * 1.3, h = r * .96;
    final o = center + Offset(-w / 2, -h / 2 + r * .06);
    final bandTop = o.dy + h * .8;
    final flasks = Path();
    for (final (x, height, base, neck) in const [
      (.16, .56, .13, .05),
      (.84, .56, .13, .05),
      (.5, .8, .17, .06),
    ]) {
      final cx = o.dx + w * x, top = bandTop - h * height;
      flasks
        ..moveTo(cx - w * base, bandTop)
        ..lineTo(cx - w * neck, top + h * height * .42)
        ..lineTo(cx - w * neck, top)
        ..lineTo(cx + w * neck, top)
        ..lineTo(cx + w * neck, top + h * height * .42)
        ..lineTo(cx + w * base, bandTop)
        ..close();
    }
    flasks.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, bandTop - h * .04, w, h * .24),
        Radius.circular(h * .1),
      ),
    );
    c.drawPath(flasks, Paint()..color = _night);
  }

  static void _bar(
    Canvas c,
    _Layout l,
    SkyBoss boss,
    List<Color> ramp, {
    required bool reducedMotion,
    required bool arriving,
    required bool defeated,
    required bool fury,
    required bool critical,
    required bool shielded,
    required double warning,
    required double blink,
    required double wave,
  }) {
    final u = l.u, bar = l.bar;
    final radius = Radius.circular(bar.height / 2);
    final track = RRect.fromRectAndRadius(bar, radius);
    final pirate = boss.isPirate, dragon = boss.isDragon;
    if (dragon) {
      DragonHudArt.track(
        c,
        bar,
        u,
        fury: fury,
        reduced: reducedMotion,
        time: boss.age,
        furyAge: boss.age - boss.enragedAt,
      );
    } else if (pirate) {
      PirateHudArt.track(c, bar, u);
    } else {
      c.drawRRect(track.inflate(1.2 * u), Paint()..color = _nightDeep);
      c.drawRRect(track, Paint()..color = _trackShade);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(bar.left, bar.top + 1.6 * u, bar.right, bar.bottom),
          radius,
        ),
        Paint()..color = _track,
      );
    }

    final maxHp = boss.maxHp;
    double edge(double value) =>
        bar.left + bar.width * (value / maxHp).clamp(0.0, 1.0);
    final hp = dragon
        ? DragonHudArt.gaugeHp(boss, reduced: reducedMotion)
        : arriving
        ? maxHp *
              (reducedMotion
                  ? 1.0
                  : _easeInOut((boss.age / boss.arrivalDuration).clamp(0, 1)))
        : defeated
        ? 0.0
        : boss.hp.toDouble();

    c.save();
    c.clipRRect(track);

    // Damage chip: white on impact, warm cream while it holds, then drains.
    final since = boss.age - boss.lastHitAt;
    var chipHp = hp;
    if (!arriving &&
        since.isFinite &&
        since >= 0 &&
        since < chipSeconds &&
        boss.lastDamage > 0) {
      final before = math.min(hp + boss.lastDamage, maxHp.toDouble());
      chipHp = before;
      var color = Color.lerp(
        const Color(0xffffffff),
        _chip,
        ((since - _white) / _cool).clamp(0.0, 1.0),
      )!;
      if (reducedMotion) {
        color = _chip.withValues(
          alpha: ((chipSeconds - since) / _fade).clamp(0.0, 1.0),
        );
      } else {
        chipHp =
            before +
            (hp - before) * _easeInOut(((since - _hold) / _drain).clamp(0, 1));
      }
      if (chipHp > hp + .01) {
        final drained = Rect.fromLTRB(
          edge(hp) - bar.height,
          bar.top,
          edge(chipHp),
          bar.bottom,
        );
        if (dragon) {
          DragonHudArt.chip(
            c,
            drained,
            heat: reducedMotion
                ? 0
                : 1 - ((since - _white) / _cool).clamp(0.0, 1.0),
            alpha: reducedMotion
                ? ((chipSeconds - since) / _fade).clamp(0.0, 1.0)
                : 1,
          );
        } else if (pirate) {
          PirateHudArt.chip(
            c,
            drained,
            heat: reducedMotion
                ? 0
                : 1 - ((since - _white) / _cool).clamp(0.0, 1.0),
            alpha: reducedMotion
                ? ((chipSeconds - since) / _fade).clamp(0.0, 1.0)
                : 1,
          );
        } else {
          c.drawRect(drained, Paint()..color = color);
        }
      }
    }

    final right = edge(hp);
    if (right > bar.left && dragon) {
      DragonHudArt.fill(
        c,
        bar,
        right,
        u,
        ramp,
        glow: critical && !reducedMotion ? .3 * wave : 0.0,
        phase: reducedMotion ? 0 : boss.age * 1.7,
        hotTip: right < bar.right - .5,
        fury: fury,
        surge: DragonHudArt.surge(boss, reduced: reducedMotion),
      );
    } else if (right > bar.left && pirate) {
      PirateHudArt.fill(
        c,
        bar,
        right,
        u,
        ramp,
        glow: critical && !reducedMotion ? .3 * wave : 0.0,
        phase: reducedMotion ? 0 : boss.age * 1.7,
        foamTip: right < bar.right - .5,
      );
    } else if (right > bar.left) {
      final fill = Rect.fromLTRB(bar.left, bar.top, right, bar.bottom);
      final glow = critical && !reducedMotion ? .3 * wave : 0.0;
      c.drawRect(fill, Paint()..color = ramp[2]);
      c.drawRect(
        Rect.fromLTRB(fill.left, fill.top, fill.right, fill.bottom - 2 * u),
        Paint()..color = Color.lerp(ramp[1], ramp[0], glow)!,
      );
      // Glossy highlight line.
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            fill.left + 2.5 * u,
            fill.top + 1.4 * u,
            math.max(fill.left + 2.5 * u, fill.right - 1.5 * u),
            fill.top + 3 * u,
          ),
          Radius.circular(.8 * u),
        ),
        Paint()..color = ramp[0].withValues(alpha: .85),
      );
      if (shielded) _sheen(c, bar, fill.right, u, .45);
      // A bright leading edge keeps the current health crisp.
      if (right < bar.right - .5) {
        c.drawRect(
          Rect.fromLTRB(right - 1.3 * u, bar.top, right, bar.bottom),
          Paint()..color = ramp[0],
        );
      }
    }

    if (warning > 0) {
      // The veil creeps over the bar while the shield forms.
      final front = bar.left + bar.width * warning;
      c.drawRect(
        Rect.fromLTRB(bar.left, bar.top, front, bar.bottom),
        Paint()..color = _veil.withValues(alpha: .38),
      );
      _sheen(c, bar, front, u, .35);
      c.drawRect(
        Rect.fromLTRB(front - 1.6 * u, bar.top, front, bar.bottom),
        Paint()..color = _veil.withValues(alpha: .6 + .4 * blink),
      );
    }

    // Light quarter ticks.
    final tick = Paint()
      ..strokeWidth = 1 * u
      ..color = _nightDeep.withValues(alpha: .35);
    for (final i in const [1, 3]) {
      final x = bar.left + bar.width * i / 4;
      c.drawLine(
        Offset(x, bar.top + 2 * u),
        Offset(x, bar.bottom - 2 * u),
        tick,
      );
    }

    // Short state tags sit in the emptied part of the track.
    final furyAge = boss.age - boss.enragedAt;
    final tag = defeated
        ? ('DEFEATED', _mint, 1.0)
        : arriving
        ? ('INCOMING', _cream, 1.0)
        : fury && furyAge >= 0 && furyAge < furyTagSeconds
        ? (
            'FURY',
            _emberText,
            ((furyTagSeconds - furyAge) / _tagFade).clamp(0.0, 1.0),
          )
        // The Ember Dragon's heart lies open while it breathes.
        : boss.coreExposed && !dragon
        ? ('HEART ×2', _cream, 1.0)
        : null;
    if (tag != null) {
      final (text, color, alpha) = tag;
      final p = _painter(
        text,
        7.4 * u,
        color.withValues(alpha: alpha),
        spacing: .9 * u,
      );
      final room = Rect.fromLTRB(
        math.max(right, chipHp > hp ? edge(chipHp) : right) + 3 * u,
        bar.top,
        bar.right - 4 * u,
        bar.bottom,
      );
      if (room.width >= p.width) {
        p.paint(
          c,
          Offset(
            defeated || arriving
                ? bar.center.dx - p.width / 2
                : room.right - p.width,
            bar.center.dy - p.height / 2 + .3 * u,
          ),
        );
      }
    }
    c.restore();

    // The half mark is where the fury begins: an ember notch that pokes
    // past the track until the boss crosses it.
    final half = bar.left + bar.width / 2;
    final above = !fury && !defeated && !arriving;
    if (dragon) {
      DragonHudArt.motes(
        c,
        bar,
        right,
        u,
        time: boss.age,
        fury: fury,
        reduced: reducedMotion,
        surge: DragonHudArt.surge(boss, reduced: reducedMotion),
      );
      DragonHudArt.halfMark(
        c,
        bar,
        u,
        above: above,
        fury: fury,
        wave: wave,
        furyAge: boss.age - boss.enragedAt,
        reduced: reducedMotion,
      );
    } else if (pirate) {
      // The pirate's mark is a gold doubloon set in the plate's rim.
      PirateHudArt.halfMark(c, bar, u, above: above, fury: fury, wave: wave);
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(half, bar.center.dy),
            width: 2.8 * u,
            height: bar.height + (above ? 4.4 : 2) * u,
          ),
          Radius.circular(1.4 * u),
        ),
        Paint()..color = _nightDeep,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(half, bar.center.dy),
            width: 1.3 * u,
            height: bar.height + (above ? 2.8 : 0) * u,
          ),
          Radius.circular(.65 * u),
        ),
        Paint()..color = above ? _ember : _nightDeep,
      );
    }

    // The frame lights up on hits and while the shield forms.
    final fresh = since.isFinite && since >= 0 && since < .1 && !reducedMotion
        ? 1 - since / .1
        : 0.0;
    final ring = shielded
        ? .95
        : warning > 0
        ? warning * blink
        : fresh;
    if (ring > 0) {
      c.drawRRect(
        track.inflate(1.2 * u),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * u
          ..color = (shielded || warning > 0 ? _veil : const Color(0xffffffff))
              .withValues(alpha: ring),
      );
    }
    if (shielded || warning > 0) {
      // Shield badge on the bar's end: outlined while the veil forms,
      // solid while health is locked.
      final blocked = boss.age - boss.lastShieldHitAt;
      final pop = shielded && !reducedMotion && blocked >= 0 && blocked < .25
          ? math.sin(blocked / .25 * math.pi) * .3
          : 0.0;
      final size = 12 * u * (1 + pop);
      final center = Offset(bar.right, bar.center.dy);
      c.drawCircle(center, size * .7, Paint()..color = _nightDeep);
      _shieldGlyph(
        c,
        center,
        size,
        _veil.withValues(alpha: shielded ? 1 : .5 + .5 * blink),
        filled: shielded,
      );
    }
  }

  static void _sheen(Canvas c, Rect bar, double front, double u, double a) {
    final sheen = Paint()
      ..color = const Color(0xffffffff).withValues(alpha: a)
      ..strokeWidth = 1.8 * u;
    for (var x = bar.left - bar.height; x < front; x += 7 * u) {
      final end = math.min(x + bar.height, front);
      c.drawLine(
        Offset(x, bar.bottom),
        Offset(end, bar.bottom - (end - x)),
        sheen,
      );
    }
  }

  static void _shieldGlyph(
    Canvas c,
    Offset center,
    double size,
    Color color, {
    required bool filled,
  }) {
    final w = size * .82, h = size;
    final top = center.dy - h / 2;
    final shield = Path()
      ..moveTo(center.dx, top)
      ..quadraticBezierTo(
        center.dx + w * .3,
        top + h * .12,
        center.dx + w / 2,
        top + h * .1,
      )
      ..quadraticBezierTo(center.dx + w * .52, top + h * .7, center.dx, top + h)
      ..quadraticBezierTo(
        center.dx - w * .52,
        top + h * .7,
        center.dx - w / 2,
        top + h * .1,
      )
      ..quadraticBezierTo(center.dx - w * .3, top + h * .12, center.dx, top)
      ..close();
    c.drawPath(
      shield,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = size * .13
        ..strokeJoin = StrokeJoin.round,
    );
    if (filled) {
      c.drawLine(
        Offset(center.dx, top + h * .2),
        Offset(center.dx, top + h * .82),
        Paint()
          ..color = _night.withValues(alpha: .45)
          ..strokeWidth = size * .11
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  static TextPainter _painter(
    String value,
    double size,
    Color color, {
    double spacing = 0,
    double maxWidth = double.infinity,
    List<Shadow>? shadows,
  }) => TextPainter(
    text: TextSpan(
      text: value,
      style: heading(
        size,
        color: color,
      ).copyWith(letterSpacing: spacing, shadows: shadows),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);

  static double _easeInOut(double t) =>
      t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
}

/// Fixed geometry: the strip never resizes with the boss or its state, so
/// the bar does not jump when the name or numbers change.
class _Layout {
  _Layout(Size size)
    : u = math.min(size.height / 360, size.width / 640).clamp(.8, 1.3) {
    // Width stays inside the band the flight HUD leaves free between the
    // hearts readout (left) and the clock and pause buttons (right).
    final hud = math.min(size.width / 1000, size.height / 450);
    final w = math.min(460 * hud, size.width - 24);
    strip = Rect.fromLTWH((size.width - w) / 2, 7 * u, w, 22 * u);
    crestRadius = 7.5 * u;
    crest = Offset(strip.left + 3.5 * u + crestRadius, strip.center.dy);
    nameLeft = crest.dx + crestRadius + 5 * u;
    nameWidth = 84 * u;
    hpRight = strip.right - 10 * u;
    bar = Rect.fromLTRB(
      nameLeft + nameWidth + 6 * u,
      strip.center.dy - 5 * u,
      hpRight - 42 * u,
      strip.center.dy + 5 * u,
    );
  }

  final double u;
  late final Rect strip, bar;
  late final Offset crest;
  late final double crestRadius, nameLeft, nameWidth, hpRight;

  TextPainter name(String value, Color color, {List<Shadow>? shadows}) =>
      BossHealthBarArt._painter(
        value,
        10 * u,
        color,
        spacing: .5 * u,
        maxWidth: nameWidth,
        shadows: shadows,
      );
}
