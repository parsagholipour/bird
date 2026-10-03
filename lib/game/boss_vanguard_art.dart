import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'boss_health_bar_art.dart';
import 'boss_motion.dart';
import 'boss_power_up_art.dart';
import 'crust_art.dart';
import 'straggler_art.dart';
import 'king_coo_hud_art.dart';

/// How one member of a vanguard stands: still to come, flying, shot down
/// (or rammed), or gone past the bird.
enum VanguardPip { coming, flying, downed, escaped }

/// A campaign boss's vanguard (rules version 44): before Baron Bat, the
/// Spitter King, the Dusk Empress and King Coo show up, three waves of their
/// small enemies fly in.
///
/// A title card announces it for [BossVanguard.bannerSeconds], in the house
/// style of the rush cards (a dark plate edged in the boss's colour,
/// ribbons, the title, a call under it, a badge either side). While it
/// flies, a compact plate takes the boss plate's place at the top centre:
/// the boss's crest, a pip for every member (a little silhouette of its
/// kind, grouped by wave) and how many are left; it fades as the boss's
/// arrival begins.
///
/// Everything is read from the flight (the vanguard's clock, its members,
/// the enemies still flying), so paused, replayed and seeked frames repeat.
/// Reduced Motion keeps the cards and pips still.
abstract final class BossVanguardArt {
  static const _ink = Color(0xff14252e), _night = Color(0xff171c39);
  static const _nightDeep = Color(0xff0f1330), _cream = Color(0xfffff2c9);
  static const _gold = Color(0xffffd878), _mint = Color(0xffa8e8bc);
  static const _dim = Color(0xff9a96b8);

  /// The plate leaves this long after the last member is gone (the boss's
  /// arrival starts [BossVanguard.bossDelay] after it), over [_plateFade].
  static const plateHold = .5, _plateFade = .55;

  /// What the card calls under the title. King Coo's squadron throws stale
  /// crusts from rules version 45 ([crusts]), and those that get away come
  /// back in his fight ([returns]); the card says so.
  static String call(
    BossKind kind, {
    bool crusts = false,
    bool returns = false,
  }) => switch (kind) {
    BossKind.baronBat => 'Here they come! The Baron is right behind.',
    BossKind.spitterBeetle =>
      'Here they come! The Spitter King is right behind.',
    BossKind.duskMoth => 'Here they come! The Empress is right behind.',
    BossKind.kingCoo =>
      returns
          ? 'Duck the crusts! Miss one and it comes back!'
          : crusts
          ? 'Here they come! Duck the crusts!'
          : 'Here they come! King Coo is right behind.',
    // Neferhoo sends no vanguard either (see the master plan).
    BossKind.pirate ||
    BossKind.dragon ||
    BossKind.searchlightGargoyle ||
    BossKind.neferhoo => '',
  };

  /// Each member's state, in the order they fly in, wave by wave.
  static List<List<VanguardPip>> pips(FlightSimulation sim) => [
    for (final wave in pipStates(sim)) [for (final pip in wave) pip.state],
  ];

  /// Each member's state and when (flight elapsed seconds) it took it, in
  /// the order they fly in, wave by wave: still to come until its wave is
  /// sent (no time), flying from its wave's time, then down when the rules
  /// record it shot or rammed, or gone past when it left the flight without
  /// that.
  static List<List<({VanguardPip state, double at})>> pipStates(
    FlightSimulation sim,
  ) {
    final guard = sim.vanguard;
    if (guard == null) return const [];
    final out = <List<({VanguardPip state, double at})>>[];
    var next = 0;
    for (final wave in guard.waves) {
      final sentAt = guard.startedAt + wave.at;
      out.add([
        for (var k = 0; k < wave.members.length; k++)
          if (next >= guard.members.length)
            (state: VanguardPip.coming, at: double.negativeInfinity)
          else
            switch (guard.members[next++]) {
              final m when guard.downedAt.containsKey(m) => (
                state: VanguardPip.downed,
                at: guard.downedAt[m]!,
              ),
              final m when guard.goneAt.containsKey(m) => (
                state: VanguardPip.escaped,
                at: guard.goneAt[m]!,
              ),
              _ => (state: VanguardPip.flying, at: sentAt),
            },
      ]);
    }
    return out;
  }

  /// A pip pops as its state changes: this long.
  static const popSeconds = .35;

  /// The card, then the plate.
  static void paint(
    Canvas c,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final guard = sim.vanguard;
    if (guard == null || !size.isFinite || size.height <= 0) return;
    if (!sim.elapsed.isFinite) return;
    plate(c, size, sim, reducedMotion: reducedMotion);
    banner(c, size, sim, reducedMotion: reducedMotion);
  }

  // -------------------------------------------------------------- plate --

  /// How much of the plate shows, 0 to 1: in as the vanguard begins, out as
  /// the boss's arrival begins.
  static double plateShow(FlightSimulation sim, {required bool reduced}) {
    final guard = sim.vanguard;
    if (guard == null) return 0;
    final since = sim.elapsed - guard.startedAt;
    if (since < 0) return 0;
    final into = reduced
        ? 1.0
        : BossMotion.ease(BossMotion.ramp(since, 0, .35));
    final cleared = guard.clearedAt;
    if (cleared == null) return into;
    final out = BossMotion.ramp(
      sim.elapsed - cleared,
      plateHold,
      plateHold + _plateFade,
    );
    return into * (1 - BossMotion.ease(out));
  }

  static double _pipStep(double u) => 12.5 * u;
  static double _waveGap(double u) => 6 * u;

  /// Where the plate sits on a screen of [size] for [guard]: centred at the
  /// top, the boss strip's height, as wide as its pips need.
  static Rect bounds(Size size, BossVanguard guard) {
    final u = BossHealthBarArt.unit(size);
    final pips =
        guard.total * _pipStep(u) + (guard.waves.length - 1) * _waveGap(u);
    final w = math.min(26 * u + pips + 6 * u + 44 * u, size.width - 24);
    return Rect.fromLTWH((size.width - w) / 2, 7 * u, w, 22 * u);
  }

  static void plate(
    Canvas c,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final guard = sim.vanguard!;
    final show = plateShow(sim, reduced: reducedMotion);
    if (show <= .001) return;
    final u = BossHealthBarArt.unit(size);
    final strip = bounds(size, guard);
    final king = guard.boss == BossKind.kingCoo;
    final (main, _) = BossPowerUpArt.colors(guard.boss);
    final time = sim.elapsed - guard.startedAt;
    final lift = reducedMotion ? 0.0 : (1 - show) * -6 * u;
    c.save();
    c.translate(0, lift);
    final faded = show < 1;
    if (faded) {
      c.saveLayer(
        strip.inflate(12 * u),
        Paint()..color = Color.fromRGBO(255, 255, 255, show),
      );
    }
    final pill = RRect.fromRectAndRadius(
      strip,
      Radius.circular(strip.height / 2),
    );
    if (king) {
      KingCooHudArt.frame(
        c,
        strip,
        u,
        fury: false,
        defeated: false,
        wave: .5,
        flash: 0,
        time: time,
        reduced: reducedMotion,
      );
    } else {
      c.drawRRect(
        pill.shift(Offset(0, 1.5 * u)),
        Paint()..color = _nightDeep.withValues(alpha: .2),
      );
      c.drawRRect(pill, Paint()..color = _night.withValues(alpha: .88));
      c.drawRRect(
        pill,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * u
          ..color = main.withValues(alpha: .55),
      );
    }
    final crest = Offset(strip.left + 3.5 * u + 7.5 * u, strip.center.dy);
    BossHealthBarArt.emblem(
      c,
      crest,
      7.5 * u,
      u,
      guard.boss,
      time: time,
      reduced: reducedMotion,
    );

    // The pips, wave by wave.
    final waves = pipStates(sim);
    // King Coo's escapees come back in his fight (rules version 45).
    final returns =
        sim.supportsTougherCoo && BossVanguard.returnsOf(guard.boss);
    var x = crest.dx + 7.5 * u + 6 * u;
    final step = _pipStep(u), cy = strip.center.dy;
    for (final (w, wave) in waves.indexed) {
      if (w > 0) {
        // A dot between waves.
        c.drawCircle(
          Offset(x + _waveGap(u) / 2 - .4 * u, cy),
          .9 * u,
          Paint()..color = _dim.withValues(alpha: .6),
        );
        x += _waveGap(u);
      }
      for (final (k, (:state, :at)) in wave.indexed) {
        final kind = guard.waves[w].members[k].kind;
        final bob = reducedMotion || state != VanguardPip.flying
            ? 0.0
            : math.sin(time * 6 + (w * 7 + k) * 1.3) * .7 * u;
        // The change it just made: none under Reduced Motion.
        final since = sim.elapsed - at;
        final pop = reducedMotion || !(since >= 0 && since < popSeconds)
            ? -1.0
            : since / popSeconds;
        _pip(
          c,
          Offset(x + step / 2, cy + bob),
          5.2 * u,
          u,
          kind,
          state,
          pop: pop,
        );
        if (returns && state == VanguardPip.escaped) {
          // It got away, so it will be back: the "comes back" arrow.
          StragglerArt.badge(
            c,
            Offset(x + step / 2 + 3 * u, cy - 3.6 * u),
            2.7 * u,
          );
        }
        x += step;
      }
    }

    // How many are left: the number in gold, LEFT in dim type (the boss
    // plate's "hp/max" reading), or CLEAR! once they are all gone.
    final left = waves.fold(
      0,
      (n, wave) =>
          n +
          wave
              .where(
                (p) =>
                    p.state == VanguardPip.flying ||
                    p.state == VanguardPip.coming,
              )
              .length,
    );
    final right = strip.right - 10 * u;
    final shadows = king
        ? [Shadow(color: KingCooHudArt.ink, offset: Offset(0, .9 * u))]
        : null;
    if (left == 0) {
      final p = _text(
        'CLEAR!',
        9.5 * u,
        _mint,
        spacing: .6 * u,
        shadows: shadows,
      );
      p.paint(c, Offset(right - p.width, cy - p.height / 2));
    } else {
      final n = _text('$left', 10.5 * u, _gold, shadows: shadows);
      final word = _text('LEFT', 7 * u, _dim, spacing: .5 * u);
      final base =
          cy +
          n.computeDistanceToActualBaseline(TextBaseline.alphabetic) -
          n.height / 2;
      void at(TextPainter p, double px) => p.paint(
        c,
        Offset(
          px,
          base - p.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        ),
      );
      at(word, right - word.width);
      at(n, right - word.width - n.width - 2 * u);
    }
    if (faded) c.restore();
    c.restore();
  }

  /// One member's pip at [at], [r] its half size: its kind's silhouette,
  /// an empty outline while it is still to come, in its colours while it
  /// flies, dark and crossed out once down, and greyed once it has flown
  /// past. [pop] (0 to 1, or negative for none) runs as it takes its state:
  /// a flying pip springs up out of its outline, a downed or passed one
  /// bumps, and a ring (the member's light, gold for a downed one) spreads
  /// off it.
  static void _pip(
    Canvas c,
    Offset at,
    double r,
    double u,
    EnemyKind kind,
    VanguardPip state, {
    double pop = -1,
  }) {
    final (body, light) = _enemyColors(kind);
    c.save();
    c.translate(at.dx, at.dy);
    if (pop >= 0) {
      final ring = switch (state) {
        VanguardPip.downed => _gold,
        VanguardPip.escaped => _dim,
        VanguardPip.flying || VanguardPip.coming => light,
      };
      final e = 1 - (1 - pop) * (1 - pop);
      // (Kept inside its own slot: it never reaches a neighbour's.)
      c.drawCircle(
        Offset.zero,
        r * (.78 + .5 * e),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.7 - 1.0 * pop) * u
          ..color = Color.lerp(
            ring,
            const Color(0xffffffff),
            .35,
          )!.withValues(alpha: math.pow(1 - pop, .7).toDouble()),
      );
      // A flying pip springs out of its outline with a little overshoot;
      // the others bump.
      final grow = state == VanguardPip.flying
          ? .55 + .45 * _outBack(pop)
          : 1 + .38 * math.sin(pop * math.pi) * (1 - pop * .4);
      c.scale(grow);
    }
    c.scale(r);
    final shape = glyph(kind);
    final line = u / r;
    switch (state) {
      case VanguardPip.coming:
        c.drawPath(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = line
            ..strokeJoin = StrokeJoin.round
            ..color = light.withValues(alpha: .5),
        );
      case VanguardPip.flying:
        c.drawPath(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = line * 2
            ..strokeJoin = StrokeJoin.round
            ..color = _nightDeep,
        );
        c.drawPath(shape, Paint()..color = body);
        c.drawPath(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = line * .8
            ..strokeJoin = StrokeJoin.round
            ..color = light.withValues(alpha: .9),
        );
      case VanguardPip.downed:
        c.drawPath(shape, Paint()..color = const Color(0xff2e2b4b));
        final cross = Path()
          ..moveTo(-.62, -.62)
          ..lineTo(.62, .62)
          ..moveTo(.62, -.62)
          ..lineTo(-.62, .62);
        c.drawPath(
          cross,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = line * 3
            ..strokeCap = StrokeCap.round
            ..color = _nightDeep,
        );
        c.drawPath(
          cross,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = line * 1.5
            ..strokeCap = StrokeCap.round
            ..color = _gold,
        );
      case VanguardPip.escaped:
        c.drawPath(shape, Paint()..color = _dim.withValues(alpha: .42));
    }
    c.restore();
  }

  /// Rises past 1 and settles back, for a spring.
  static double _outBack(double t) {
    const k = 1.9;
    final x = t - 1;
    return 1 + (k + 1) * x * x * x + k * x * x;
  }

  /// A small enemy's colours on a pip, as (body, light).
  static (Color, Color) _enemyColors(EnemyKind kind) => switch (kind) {
    EnemyKind.simpleBat => (const Color(0xffbb9fe3), const Color(0xffe9dcf7)),
    EnemyKind.caveBat => (const Color(0xffc98e67), const Color(0xffeac291)),
    EnemyKind.spitterBeetle => (
      const Color(0xff7fd4a0),
      const Color(0xffc3eba2),
    ),
    EnemyKind.duskMoth => (const Color(0xffe58a92), const Color(0xffffc6a4)),
    EnemyKind.alleyPigeon => (const Color(0xffaab3d2), const Color(0xffe8edfb)),
    // Neferhoo's mummy bats never fly in a vanguard: linen, for any pip.
    EnemyKind.mummyBat => (const Color(0xffd9c9a6), const Color(0xfff3ead6)),
  };

  static final Map<EnemyKind, Path> _glyphs = {};

  /// [kind]'s silhouette in a unit box about the origin, facing left (the
  /// way they fly): a bat (the cave bat's ears are taller), a beetle, a
  /// moth, a pigeon. One outline (its parts are merged), so an empty pip
  /// draws only its edge.
  static Path glyph(EnemyKind kind) => _glyphs[kind] ??= _union(switch (kind) {
    EnemyKind.simpleBat ||
    EnemyKind.mummyBat ||
    EnemyKind.caveBat => _bat(kind == EnemyKind.caveBat ? .78 : .62),
    EnemyKind.spitterBeetle => _beetle(),
    EnemyKind.duskMoth => _moth(),
    EnemyKind.alleyPigeon => _pigeon(),
  });

  static Path _union(List<Path> parts) => parts
      .skip(1)
      .fold(
        parts.first,
        (all, part) => Path.combine(PathOperation.union, all, part),
      );

  static List<Path> _bat(double ears) => [
    Path()..addOval(Rect.fromCircle(center: const Offset(0, .1), radius: .36)),
    for (final s in const [-1.0, 1.0]) ...[
      Path()
        ..moveTo(s * .14, -.18)
        ..lineTo(s * .3, -ears)
        ..lineTo(s * .36, -.08)
        ..close(),
      Path()
        ..moveTo(s * .26, -.12)
        ..lineTo(s * 1.0, -.5)
        ..quadraticBezierTo(s * .9, -.2, s * .86, .06)
        ..quadraticBezierTo(s * .7, -.08, s * .6, .2)
        ..quadraticBezierTo(s * .46, .04, s * .3, .3)
        ..close(),
    ],
  ];

  // Seen from above: a round back, a head, feelers and six legs.
  static List<Path> _beetle() {
    Path limb(Offset from, Offset to, double w) {
      final d = to - from;
      final n = Offset(-d.dy, d.dx) / d.distance * (w / 2);
      return Path()
        ..moveTo(from.dx + n.dx, from.dy + n.dy)
        ..lineTo(to.dx + n.dx, to.dy + n.dy)
        ..lineTo(to.dx - n.dx, to.dy - n.dy)
        ..lineTo(from.dx - n.dx, from.dy - n.dy)
        ..close();
    }

    return [
      Path()..addOval(
        Rect.fromCenter(center: const Offset(.14, 0), width: 1.12, height: .9),
      ),
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(-.52, 0), radius: .26)),
      for (final s in const [-1.0, 1.0]) ...[
        limb(Offset(-.66, s * .1), Offset(-.98, s * .5), .11),
        for (final x in const [-.22, .14, .5])
          limb(Offset(x, s * .3), Offset(x - .14, s * .74), .14),
      ],
    ];
  }

  static List<Path> _moth() => [
    for (final s in const [-1.0, 1.0]) ...[
      Path()
        ..moveTo(s * .06, -.12)
        ..cubicTo(s * .45, -.85, s * 1.05, -.72, s * .98, -.2)
        ..quadraticBezierTo(s * .6, .04, s * .06, .04)
        ..close(),
      Path()
        ..moveTo(s * .06, .04)
        ..quadraticBezierTo(s * .78, .1, s * .62, .62)
        ..quadraticBezierTo(s * .28, .66, s * .05, .24)
        ..close(),
      Path()
        ..moveTo(s * .03, -.32)
        ..lineTo(s * .3, -.82)
        ..lineTo(s * .38, -.76)
        ..lineTo(s * .1, -.3)
        ..close(),
    ],
    Path()..addOval(
      Rect.fromCenter(center: const Offset(0, .08), width: .22, height: .86),
    ),
  ];

  static List<Path> _pigeon() => [
    Path()..addOval(
      Rect.fromCenter(center: const Offset(.12, .14), width: 1.12, height: .68),
    ),
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(-.46, -.22), radius: .25)),
    Path()
      ..moveTo(-.66, -.3)
      ..lineTo(-.92, -.18)
      ..lineTo(-.64, -.12)
      ..close(),
    Path()
      ..moveTo(.52, .02)
      ..lineTo(1.0, -.12)
      ..lineTo(1.0, .2)
      ..lineTo(.56, .32)
      ..close(),
    Path()
      ..moveTo(-.1, -.04)
      ..lineTo(.34, -.72)
      ..lineTo(.58, -.04)
      ..close(),
  ];

  // ------------------------------------------------------------- banner --

  static const _bannerLife = BossVanguard.bannerSeconds;

  /// The title card: [BossVanguard.title] in the boss's colour with the
  /// call under it, for [BossVanguard.bannerSeconds] as the vanguard
  /// begins. It lands with a little punch and wobble, a sweep of light
  /// crosses it, and it lifts away. Still (no punch, wobble, sweep or lift)
  /// under Reduced Motion.
  static void banner(
    Canvas c,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final guard = sim.vanguard!;
    final age = sim.elapsed - guard.startedAt;
    if (age < 0 || age >= _bannerLife) return;
    final h = size.height;
    final (accent, light) = BossPowerUpArt.colors(guard.boss);
    final fade = math.min(
      (age / .09).clamp(0.0, 1.0),
      BossMotion.ease(((_bannerLife - age) / .3).clamp(0.0, 1.0)),
    );
    final land = BossMotion.ease((age / .2).clamp(0.0, 1.0));
    final leave = BossMotion.ease(
      ((age - (_bannerLife - .3)) / .3).clamp(0.0, 1.0),
    );
    final reveal = reducedMotion
        ? 1.0
        : BossMotion.ease(((age - .03) / .2).clamp(0.0, 1.0));
    final unfurl = reducedMotion
        ? 1.0
        : BossMotion.ease((age / .18).clamp(0.0, 1.0));
    final solid = math.sqrt(fade);

    TextPainter type(
      String value,
      double points,
      FontWeight weight,
      Paint paint,
    ) => TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: weight,
          fontSize: points,
          letterSpacing: h * .002,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final titleSize = h * .082, callSize = h * .038;
    final shade = type(
      guard.title,
      titleSize,
      FontWeight.w700,
      Paint()..color = Color.lerp(accent, _ink, .62)!.withValues(alpha: fade),
    );
    final crusts = sim.supportsTougherCoo;
    final line = type(
      call(
        guard.boss,
        crusts: crusts,
        returns: crusts && BossVanguard.returnsOf(guard.boss),
      ),
      callSize,
      FontWeight.w600,
      Paint()..color = _cream.withValues(alpha: .94 * fade * reveal),
    );
    final glyphSize = h * .046, gap = h * .03;
    final cardW =
        math.max(shade.width + (glyphSize * 2 + gap) * 2, line.width) + h * .1;
    final cardH = shade.height + line.height + h * .062;
    final tail = h * .055;
    final fit = math.min(1.0, (size.width - h * .09) / (cardW + tail * 2));
    final wobble = reducedMotion || age < .2
        ? 0.0
        : math.sin((age - .2) * 25) * .022 * math.max(0, 1 - (age - .2) / .45);
    final pop = reducedMotion
        ? 1.0
        : (1.12 - .12 * land) * (1 + wobble) * (1 - .08 * leave);
    final top = h * .115;

    c.save();
    c.translate(
      size.width / 2,
      top + cardH * fit / 2 - (reducedMotion ? 0 : h * .055 * leave),
    );
    c.scale(fit * pop);
    final halfW = cardW / 2, halfH = cardH / 2;
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTRB(-halfW, -halfH, halfW, halfH),
      Radius.circular(h * .03),
    );

    // The ribbons either side.
    final ribbon = halfH * .62 * unfurl;
    if (ribbon > 0) {
      for (final side in const [-1.0, 1.0]) {
        final x = side * (halfW - h * .02);
        final reach = side * tail * unfurl;
        c.drawPath(
          Path()
            ..moveTo(x, -ribbon)
            ..lineTo(x + reach, -ribbon - h * .008)
            ..lineTo(x + reach - side * h * .022, 0)
            ..lineTo(x + reach, ribbon + h * .008)
            ..lineTo(x, ribbon)
            ..close(),
          Paint()..color = _deep(accent, .6).withValues(alpha: solid),
        );
        c.drawPath(
          Path()
            ..moveTo(x, -ribbon)
            ..lineTo(x + reach, -ribbon - h * .008)
            ..lineTo(x + reach, -ribbon + h * .006)
            ..lineTo(x, -ribbon + h * .014)
            ..close(),
          Paint()..color = _deep(accent, .88).withValues(alpha: solid),
        );
      }
    }

    c.drawRRect(
      plate.shift(Offset(0, h * .019)),
      Paint()..color = _ink.withValues(alpha: .2 * solid),
    );
    c.drawRRect(
      plate.shift(Offset(0, h * .009)),
      Paint()..color = _deep(accent, .48).withValues(alpha: solid),
    );
    c.drawRRect(
      plate,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(_ink, accent, .1)!.withValues(alpha: .97 * solid),
            _ink.withValues(alpha: .97 * solid),
          ],
        ).createShader(plate.outerRect),
    );
    if (!reducedMotion) {
      // One sweep of light crosses the plate as it settles.
      final s = (age - .26) / .5;
      if (s > 0 && s < 1) {
        c.save();
        c.clipRRect(plate);
        final x = -halfW * 1.6 + s * cardW * 2.1;
        final glare = _cream.withValues(
          alpha: .18 * fade * math.sin(s * math.pi),
        );
        c.drawPath(
          Path()
            ..moveTo(x, halfH)
            ..lineTo(x + h * .06, halfH)
            ..lineTo(x + h * .06 + halfH, -halfH)
            ..lineTo(x + halfH, -halfH)
            ..close(),
          Paint()
            ..shader = LinearGradient(
              colors: [
                glare.withValues(alpha: 0),
                glare,
                glare.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromLTWH(x, -halfH, h * .06 + halfH, cardH)),
        );
        c.restore();
      }
    }
    c.drawRRect(
      plate.deflate(h * .005),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .008
        ..color = accent.withValues(alpha: solid),
    );
    c.drawRRect(
      plate.deflate(h * .017),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0025
        ..color = _cream.withValues(alpha: .18 * solid),
    );

    final titleTop = -halfH + h * .028;
    final punch = reducedMotion
        ? 1.0
        : 1 + .16 * (1 - BossMotion.ease((age / .22).clamp(0.0, 1.0)));
    c.save();
    c.translate(0, titleTop + shade.height / 2);
    c.scale(punch);
    c.translate(0, -titleTop - shade.height / 2);
    shade.paint(c, Offset(-shade.width / 2, titleTop + h * .008));
    type(
      guard.title,
      titleSize,
      FontWeight.w700,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(light, _cream, .4)!.withValues(alpha: fade),
                accent.withValues(alpha: fade),
              ],
              stops: const [0, .82],
            ).createShader(
              Rect.fromLTWH(
                -shade.width / 2,
                titleTop,
                shade.width,
                shade.height,
              ),
            ),
    ).paint(c, Offset(-shade.width / 2, titleTop));
    c.restore();
    line.paint(
      c,
      Offset(
        -line.width / 2,
        titleTop + shade.height + h * .006 + (1 - reveal) * h * .022,
      ),
    );

    // A badge either side of the title: the vanguard's own kind, flying in.
    final kind = guard.waves.last.members.first.kind;
    final grow = reducedMotion
        ? 1.0
        : BossMotion.ease(((age - .02) / .2).clamp(0.0, 1.0));
    final bob = reducedMotion ? 0.0 : math.sin(age * 5.5) * glyphSize * .1;
    final (body, edge) = _enemyColors(kind);
    for (final side in const [-1.0, 1.0]) {
      c.save();
      c.translate(
        side * (shade.width / 2 + gap + glyphSize),
        titleTop + shade.height * .5 + bob,
      );
      c.scale(glyphSize * grow);
      final shape = glyph(kind);
      c.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .22
          ..strokeJoin = StrokeJoin.round
          ..color = _ink.withValues(alpha: fade),
      );
      c.drawPath(shape, Paint()..color = body.withValues(alpha: fade));
      c.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .07
          ..strokeJoin = StrokeJoin.round
          ..color = edge.withValues(alpha: fade),
      );
      if (crusts && kind == EnemyKind.alleyPigeon) {
        // A crust raised over its back, ready to throw.
        c.save();
        c.translate(.38, -.9);
        c.scale(.62);
        CrustArt.slab(c, spin: .4, edge: .09 / .62, alpha: fade);
        c.restore();
      }
      c.restore();
    }
    c.restore();
  }

  /// A darker, still saturated [accent] for the card's ribbon and edge.
  static Color _deep(Color accent, double amount) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withLightness((hsl.lightness * amount).clamp(0.0, 1.0))
        .toColor();
  }

  static final Map<Object, TextPainter> _texts = {};

  static TextPainter _text(
    String value,
    double size,
    Color color, {
    double spacing = 0,
    List<Shadow>? shadows,
  }) => _texts[(value, size, color, spacing, shadows != null)] ??= TextPainter(
    text: TextSpan(
      text: value,
      style: heading(
        size,
        color: color,
      ).copyWith(letterSpacing: spacing, shadows: shadows),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
}
