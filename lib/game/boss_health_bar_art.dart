import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'boss_stage_hud_art.dart';
import 'dragon_hud_art.dart';
import 'gargoyle_hud_art.dart';
import 'king_coo_hud_art.dart';
import 'neferhoo_hud_art.dart';
import 'ny_placeholder_art.dart';
import 'pirate_hud_art.dart';

/// The slim boss strip at the top center of the flight: one row with a
/// crest, the boss name, a health bar with a damage chip, and hit points.
///
/// Encounter states live inside the row instead of below it: fury tints the
/// bar and flashes a short tag in the emptied track, and the Dusk Empress
/// veil creeps over the bar and locks it with a shield badge.
///
/// A staged campaign boss's bar (rules version 44) is cut in three: its fury
/// mark stands at a third, a stage gem at two thirds snaps as the boss grows
/// stronger, the frame flares in gold and a STRONGER! card, with what the
/// full fight brings, drops from the gem (BossStageHudArt).
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

  /// The strip's unit on a screen of [size]: one pixel at 640 x 360. Plates
  /// that take the strip's place (a vanguard's) use the same.
  static double unit(Size size) =>
      math.min(size.height / 360, size.width / 640).clamp(.8, 1.3);

  static List<Color> _ramp(BossKind kind) => switch (kind) {
    BossKind.baronBat => _baron,
    BossKind.spitterBeetle => _spitter,
    BossKind.duskMoth => _moth,
    BossKind.pirate => _pirate,
    BossKind.dragon => DragonHudArt.lava,
    BossKind.kingCoo => KingCooHudArt.crust,
    BossKind.searchlightGargoyle => GargoyleHudArt.ramp(),
    BossKind.neferhoo => NeferhooHudArt.ramp,
  };

  /// The strip, for layout checks.
  static Rect bounds(Size size, SkyBoss boss) => _Layout(size, boss).strip;

  /// The health track inside the strip.
  static Rect track(Size size, SkyBoss boss) => _Layout(size, boss).bar;

  static void paint(
    Canvas c,
    Size size,
    SkyBoss boss, {
    bool reducedMotion = false,
  }) {
    if (boss.inCutscene) return;
    // A dragon or King Coo whose clock has gone bad is not drawn (nothing to
    // trust).
    if ((boss.isDragon || boss.isKingCoo) && !boss.age.isFinite) return;
    final l = _Layout(size, boss);
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
    // King Coo's is a navy police plate with a brass rim (KingCooHudArt).
    final king = boss.isKingCoo;
    final (siren, sirenGlow) = king
        ? KingCooHudArt.siren(boss, reduced: reducedMotion)
        : (0, 0.0);
    // The Searchlight Gargoyle's is a stepped steel plate in a brass rim
    // (GargoyleHudArt).
    final gargoyle = boss.isGargoyle;
    // Neferhoo's is a lapis cartouche in a gold rim (NeferhooHudArt).
    final neferhoo = boss.isNeferhoo;
    if (dragon || gargoyle) {
      // Each hit shudders the plate by a pixel.
      final jolt = dragon
          ? DragonHudArt.jolt(since, u, reduced: reducedMotion)
          : GargoyleHudArt.jolt(since, u, reduced: reducedMotion);
      c.save();
      c.translate(jolt.dx, jolt.dy);
    }
    if (king) {
      final jolt = KingCooHudArt.jolt(since, u, reduced: reducedMotion);
      c.save();
      c.translate(jolt.dx, jolt.dy);
    }
    if (!pirate && !dragon && !king && !gargoyle && !neferhoo) {
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
    // A staged boss growing stronger flares the frame the same way, in gold.
    final rise = BossStageHudArt.flare(boss, reduced: reducedMotion);
    final flash = math.max(fresh * .6, math.max(onset, rise));
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
        flash: flash,
        time: boss.age,
        reduced: reducedMotion,
      );
    } else if (king) {
      KingCooHudArt.frame(
        c,
        l.strip,
        u,
        fury: fury,
        defeated: defeated,
        wave: wave,
        flash: flash,
        siren: siren,
        sirenGlow: sirenGlow,
        time: boss.age,
        reduced: reducedMotion,
      );
    } else if (gargoyle) {
      GargoyleHudArt.frame(
        c,
        l.strip,
        l.bar,
        u,
        fury: fury,
        defeated: defeated,
        wave: wave,
        flash: flash,
        lamp: boss.lampOpenness,
        time: boss.age,
        reduced: reducedMotion,
      );
    } else if (neferhoo) {
      NeferhooHudArt.frame(
        c,
        l.strip,
        l.bar,
        u,
        fury: fury,
        defeated: defeated,
        wave: wave,
        flash: flash,
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
        flash: flash,
      );
    } else {
      c.drawRRect(
        strip,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * u
          ..color = Color.lerp(border, _cream, flash)!,
      );
    }
    for (final (amount, color) in [(onset, _ember), (rise, _gold)]) {
      if (amount <= 0) continue;
      // A short flare the moment the boss crosses into fury, or grows
      // stronger.
      c.drawRRect(
        strip.inflate(2.5 * u * (1 - amount)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * u
          ..color = color.withValues(alpha: .5 * amount),
      );
    }

    _crest(
      c,
      l,
      boss,
      fury: fury,
      shielded: shielded,
      defeated: defeated,
      flash: flash,
      siren: siren,
      sirenGlow: sirenGlow,
      wave: wave,
      reducedMotion: reducedMotion,
    );

    final name = l.name(
      // The full name overflows the name field.
      gargoyle ? GargoyleHudArt.label : boss.name.toUpperCase(),
      defeated ? _mint : _cream,
      // Carved lettering on the pirate's plank.
      shadows: pirate || dragon || king || gargoyle
          ? [Shadow(color: PirateHudArt.ink, offset: Offset(0, .9 * u))]
          : neferhoo
          ? [Shadow(color: NeferhooHudArt.nameShadow, offset: Offset(0, .9 * u))]
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
            ? (neferhoo ? NeferhooHudArt.numbers.fury : _emberText)
            : neferhoo
            ? NeferhooHudArt.numbers.gold
            : _gold,
      );
      final max = _painter(
        '/${boss.maxHp}',
        7.5 * u,
        neferhoo ? NeferhooHudArt.numbers.max : _dim,
      );
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
    if (boss.staged) {
      // The STRONGER! card drops from the stage gem that just snapped, with
      // what the full fight brings under it, and keeps inside the plate's
      // span, short of the flight's clock. The boss's own tags take the
      // place the moment they come: the Gargoyle's (his card hangs where
      // they do, at the plate's left end, clear of his head), King Coo's
      // PUFFED x2 and the dragon's HEART x2. King Coo's hangs below the
      // crumbs his loaf sheds.
      final others = gargoyle
          ? (boss.lampOpen ||
                    boss.age - boss.lastSpotAt < GargoyleHudArt.spottedSeconds
                ? 1.0
                : 0.0)
          : king
          ? KingCooHudArt.tagState(boss, reduced: reducedMotion).show
          : dragon
          ? DragonHudArt.heartBannerShow(boss, reduced: reducedMotion).show
          : 0.0;
      BossStageHudArt.strongerTag(
        c,
        l.strip,
        l.bar.left + l.bar.width * boss.stageMarks.first,
        u,
        boss,
        reduced: reducedMotion,
        room: (
          left: l.strip.left + 6 * u,
          right: gargoyle
              ? l.bar.center.dx - 12 * u
              : math.min(
                  l.strip.right - 4 * u,
                  BossStageHudArt.hudRight(size) - 4 * u,
                ),
        ),
        left: gargoyle,
        hang: king ? 6 * u : 0,
        alpha: 1 - math.min(1.0, others * 4),
      );
    }
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
    } else if (gargoyle) {
      GargoyleHudArt.tags(
        c,
        l.strip,
        u,
        boss,
        reduced: reducedMotion,
        spotSince: boss.age - boss.lastSpotAt,
      );
      c.restore();
    }
    if (king) {
      KingCooHudArt.puffedTag(
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
    bool defeated = false,
    double flash = 0,
    int siren = 0,
    double sirenGlow = 0,
    double wave = .5,
    bool reducedMotion = false,
  }) {
    final u = l.u, center = l.crest, r = l.crestRadius;
    if (boss.isKingCoo) {
      KingCooHudArt.crest(
        c,
        center,
        r,
        u,
        fury: fury,
        siren: siren,
        sirenGlow: sirenGlow,
        flash: flash,
        defeated: defeated,
        time: boss.age,
        reduced: reducedMotion,
      );
      return;
    }
    if (boss.isGargoyle) {
      // His searchlight lens in a brass octagon: shuttered until the lamp
      // opens, white-hot in fury (his second lens lights too).
      final open = boss.lampOpenness.clamp(0.0, 1.0);
      GargoyleHudArt.crest(
        c,
        center,
        r,
        fury: fury,
        glow: boss.phase == BossPhase.attacking ? .3 + .7 * open : .3,
        shutter: boss.phase == BossPhase.attacking ? 1 - open : 0,
        defeated: boss.phase == BossPhase.defeated,
        wave: wave,
      );
      return;
    }
    if (boss.isNeferhoo) {
      // His golden mask on lapis (NeferhooHudArt), never the crown below.
      NeferhooHudArt.crest(
        c,
        center,
        r,
        u,
        fury: fury,
        defeated: defeated,
        time: boss.age,
        reduced: reducedMotion,
      );
      return;
    }
    if (boss.isMiniBoss) {
      // A plain medallion: never the royal crown below (stub until the
      // mini-boss's own HUD art lands).
      NyPlaceholderArt.crest(c, center, r, boss.kind, fury: fury);
      return;
    }
    if (boss.isDragon) {
      DragonHudArt.crest(c, center, r, u, fury: fury);
      return;
    }
    if (boss.isPirate) {
      PirateHudArt.crest(
        c,
        center,
        r,
        u,
        glass: fury ? _fury : _pirate,
        fury: fury,
      );
      return;
    }
    _medallion(c, center, r, u, boss.kind, fury: fury, shielded: shielded);
  }

  /// The crest of a [kind] whose boss has not arrived (its vanguard's plate,
  /// rules version 44): the medallion the strip would show, calm. Baron
  /// Bat, the Spitter King, the Dusk Empress and King Coo have one.
  static void emblem(
    Canvas c,
    Offset center,
    double r,
    double u,
    BossKind kind, {
    double time = 0,
    bool reduced = false,
  }) {
    if (kind == BossKind.kingCoo) {
      KingCooHudArt.crest(
        c,
        center,
        r,
        u,
        fury: false,
        time: time,
        reduced: reduced,
      );
      return;
    }
    if (kind == BossKind.neferhoo) {
      NeferhooHudArt.crest(c, center, r, u, fury: false, reduced: reduced);
      return;
    }
    _medallion(c, center, r, u, kind, fury: false, shielded: false);
  }

  /// A royal medallion in [kind]'s ramp under its crown (the Spitter King's
  /// is a band of flasks), ember-rimmed in [fury].
  static void _medallion(
    Canvas c,
    Offset center,
    double r,
    double u,
    BossKind kind, {
    required bool fury,
    required bool shielded,
  }) {
    final ramp = shielded ? _shield : _ramp(kind);
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
    if (kind == BossKind.spitterBeetle) {
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
    final king = boss.isKingCoo;
    final gargoyle = boss.isGargoyle;
    // A staged boss's marks cut its bar in thirds: the fury mark is the
    // last of them (half, for a boss that fights in one stage).
    final staged = boss.staged, marks = boss.stageMarks;
    final furyMark = bar.left + bar.width * marks.last;
    if (king) {
      KingCooHudArt.track(
        c,
        bar,
        u,
        fury: fury,
        reduced: reducedMotion,
        time: boss.age,
        furyAge: boss.age - boss.enragedAt,
        staged: staged,
      );
    } else if (gargoyle) {
      GargoyleHudArt.track(c, bar, u, fury: fury, defeated: defeated);
    } else if (dragon) {
      DragonHudArt.track(
        c,
        bar,
        u,
        fury: fury,
        reduced: reducedMotion,
        time: boss.age,
        furyAge: boss.age - boss.enragedAt,
        staged: staged,
      );
    } else if (pirate) {
      PirateHudArt.track(c, bar, u);
    } else if (!boss.isNeferhoo ||
        !NeferhooHudArt.track(
          c,
          bar,
          u,
          fury: fury,
          defeated: defeated,
          time: boss.age,
          reduced: reducedMotion,
        )) {
      // The shared track (Neferhoo's too, until his own draws).
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
    final hp = gargoyle
        ? GargoyleHudArt.gaugeHp(boss, reduced: reducedMotion)
        : dragon
        ? DragonHudArt.gaugeHp(boss, reduced: reducedMotion)
        : king
        ? KingCooHudArt.gaugeHp(boss, reduced: reducedMotion)
        : arriving
        ? maxHp *
              (reducedMotion
                  ? 1.0
                  : _easeInOut((boss.age / boss.arrivalDuration).clamp(0, 1)))
        : defeated
        ? 0.0
        : boss.hp.toDouble();

    c.save();
    // (The Searchlight Gargoyle's pieces keep to the channel themselves.)
    if (!gargoyle) c.clipRRect(track);

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
        if (gargoyle) {
          GargoyleHudArt.chip(
            c,
            bar,
            edge(hp),
            edge(chipHp),
            heat: reducedMotion
                ? 0
                : 1 - ((since - _white) / _cool).clamp(0.0, 1.0),
            alpha: reducedMotion
                ? ((chipSeconds - since) / _fade).clamp(0.0, 1.0)
                : 1,
          );
        } else if (dragon || king) {
          (dragon ? DragonHudArt.chip : KingCooHudArt.chip)(
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
    if (right > bar.left && king) {
      KingCooHudArt.fill(
        c,
        bar,
        right,
        u,
        ramp,
        glow: critical && !reducedMotion ? .3 * wave : 0.0,
        phase: reducedMotion ? 0 : boss.age * 1.7,
        hotTip: right < bar.right - .5,
        fury: fury,
        surge: KingCooHudArt.surge(boss, reduced: reducedMotion),
        share: boss.hp / boss.maxHp,
        entrance: KingCooHudArt.entrance(boss, reduced: reducedMotion),
      );
    } else if (right > bar.left && gargoyle) {
      GargoyleHudArt.fill(
        c,
        bar,
        right,
        u,
        glow: critical && !reducedMotion ? .3 * wave : 0.0,
        phase: boss.age,
        edge: right < bar.right - .5,
        fury: fury,
        surge: GargoyleHudArt.surge(boss, reduced: reducedMotion),
        reduced: reducedMotion,
      );
    } else if (right > bar.left && dragon) {
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
        staged: staged,
      );
    } else if (right > bar.left && boss.isNeferhoo) {
      NeferhooHudArt.fill(
        c,
        bar,
        right,
        u,
        fury: fury,
        glow: critical && !reducedMotion ? .3 * wave : 0.0,
        edge: right < bar.right - .5,
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

    // The health left takes a sweep of light as the boss grows stronger.
    if (staged) {
      BossStageHudArt.sweep(c, bar, right, u, boss, reduced: reducedMotion);
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

    // Light quarter ticks, or sixths on a staged bar (King Coo's gauge and
    // the Gargoyle's brass segments are their own).
    if (gargoyle) {
      GargoyleHudArt.seams(c, bar, u, defeated: defeated, staged: staged);
    } else {
      final tick = Paint()
        ..strokeWidth = 1 * u
        ..color = _nightDeep.withValues(alpha: .35);
      for (final share
          in king
              ? const <double>[]
              : staged
              ? const [1 / 6, 1 / 2, 5 / 6]
              : const [.25, .75]) {
        final x = bar.left + bar.width * share;
        c.drawLine(
          Offset(x, bar.top + 2 * u),
          Offset(x, bar.bottom - 2 * u),
          tick,
        );
      }
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
            boss.isNeferhoo ? NeferhooHudArt.numbers.fury : _emberText,
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

    // A staged boss's stage gems: whole until the boss has lost that much,
    // then snapped. (Beaten, the plate's "DEFEATED" sits there.)
    for (var i = 0; i < marks.length - 1 && !defeated; i++) {
      BossStageHudArt.gem(
        c,
        bar,
        bar.left + bar.width * marks[i],
        u,
        boss.kind,
        passed: !arriving && boss.stage > i,
        since: BossStageHudArt.strongerAge(boss),
        time: boss.age,
        reduced: reducedMotion,
      );
    }

    // The half mark is where the fury begins: an ember notch that pokes
    // past the track until the boss crosses it (a third of the way along a
    // staged bar).
    final half = furyMark;
    final above = !fury && !defeated && !arriving;
    if (gargoyle) {
      // His fury mark is a brass spool; the second beam lights it.
      GargoyleHudArt.notch(
        c,
        l.strip,
        bar,
        u,
        above: above,
        fury: fury,
        wave: wave,
        furyAge: boss.age - boss.enragedAt,
        defeated: defeated,
        reduced: reducedMotion,
        share: marks.last,
      );
    } else if (king) {
      KingCooHudArt.crumbs(
        c,
        bar,
        right,
        u,
        time: boss.age,
        fury: fury,
        reduced: reducedMotion,
        surge: KingCooHudArt.surge(boss, reduced: reducedMotion),
      );
      KingCooHudArt.halfMark(
        c,
        bar,
        u,
        above: above,
        fury: fury,
        wave: wave,
        furyAge: boss.age - boss.enragedAt,
        reduced: reducedMotion,
        share: marks.last,
      );
    } else if (dragon) {
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
        share: marks.last,
        staged: staged,
      );
    } else if (boss.isNeferhoo) {
      // His mark is a carnelian wax seal that cracks, turquoise light
      // leaking, when he turns furious.
      NeferhooHudArt.seal(
        c,
        bar,
        u,
        above: above,
        fury: fury,
        furyAge: boss.age - boss.enragedAt,
        defeated: defeated,
        reduced: reducedMotion,
        share: marks.last,
      );
    } else if (pirate) {
      // The pirate's mark is a gold doubloon set in the plate's rim.
      PirateHudArt.halfMark(
        c,
        bar,
        u,
        above: above,
        fury: fury,
        wave: wave,
        share: marks.last,
      );
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
/// the bar does not jump when the name or numbers change. Only a boss with
/// four-digit health (the campaign's Ember Dragon, rules version 44) keeps
/// its gauge a little shorter, for the longer numbers.
class _Layout {
  _Layout(Size size, SkyBoss boss) : u = BossHealthBarArt.unit(size) {
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
      hpRight - (boss.maxHp >= 1000 ? 51 : 42) * u,
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
