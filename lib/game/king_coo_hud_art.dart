import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import '../l10n/l10n.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'king_coo_kit.dart';
import 'king_coo_pose.dart';

/// King Coo's health plate dressing: a police station name plate (navy, with a
/// brass rim and a Sillitoe-checked band, the check every police cap wears)
/// pinned with a brass star badge at its left end, the badge's centre a
/// siren lamp that blinks with his own siren; a gauge that is a crusty loaf
/// (a golden-brown crust under a flour dusting, scored with slashes, torn at
/// the health's edge where crumbs fall off, cracking as it is eaten away);
/// a silver whistle at the half mark that, when the fury blows, sets off a
/// red/blue siren flash and turns the gauge to siren-red toast; and, while
/// his chest is puffed and rocks count double, a hanging **PUFFED x2** tag
/// with three POP pips (one lights for every 20 health the window has taken;
/// the third is the pop).
///
/// `BossHealthBarArt` keeps the layout, timeline and numbers; these are only
/// King Coo's brushstrokes, in the manner of [DragonHudArt]. Everything is a
/// pure function of the values it is given, so paused, replayed and captured
/// frames repeat. Nothing here blurs, opens a layer or lays out text per
/// frame: shapes that only depend on the layout are built once, gradients are
/// cached (and built in the kit, which counts them), and a non-finite input
/// draws nothing instead of throwing.
abstract final class KingCooHudArt {
  static const ink = KingCooPalette.ink, cream = Color(0xfffff2c9);
  static const _trough = Color(0xff0f1330), _troughLit = Color(0xff1d2354);
  static const _plateLit = Color(0xff3a4a9c);

  /// The loaf as [light, main, deep], and the siren-red toast of the fury.
  static const crust = [
    Color(0xfff7d58a),
    Color(0xffd9963f),
    Color(0xff9b5c27),
  ];
  static const furyCrust = [
    Color(0xffffb8a4),
    Color(0xfff2475a),
    Color(0xff9b2440),
  ];

  /// How long the health bar's FURY tag shows after the fury begins.
  static const _furyTagSeconds = 2.2;

  /// Type of the PUFFED tag, in px at 640 x 360 (the brief: at least ten; the
  /// fix round: 11.5, so the "x2" reads at a glance).
  static const tagType = 11.5;

  /// The tag's widest case at u = 1 (px at 640 x 360).
  static const tagWidthMax = 122.0;

  // ------------------------------------------------------------- caches --

  // (laid out again in a new language's words and fonts)
  static final Map<Object, TextPainter> _texts = L10n.cache({});

  static TextPainter _text(
    String value,
    double size,
    double spacing, {
    Color color = cream,
    String? tail,
    Color tailColor = KingCooPalette.gold,
    double tailSize = 0,
  }) {
    final key = (value, size, spacing, color.toARGB32(), tail, tailSize);
    var p = _texts[key];
    if (p == null) {
      if (_texts.length >= 24) _texts.clear();
      final shadow = [Shadow(color: ink, offset: Offset(0, size * .1))];
      p = _texts[key] = TextPainter(
        text: TextSpan(
          text: value,
          style: heading(
            size,
            color: color,
          ).copyWith(letterSpacing: spacing, shadows: shadow),
          children: [
            if (tail != null)
              TextSpan(
                text: tail,
                style: heading(tailSize, color: tailColor).copyWith(
                  letterSpacing: spacing * .6,
                  shadows: shadow,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        // Words run their language's way; the tag stays where it is.
        textDirection: L10n.textDirection,
      )..layout();
    }
    return p;
  }

  // ----------------------------------------------------- static geometry --

  static Rect? _stripFor, _barFor;
  static double _uFor = 0, _barU = 0;
  static Path _checks = Path(), _studs = Path();
  static Path _scores = Path(), _scoreEdge = Path();
  static Path _specks = Path(), _flour = Path();
  static Path _cracks = Path(), _crackLit = Path();
  static Path _teeth = Path(), _tipEdge = Path();
  static Path _ticks = Path(), _sixths = Path();

  static void _buildStrip(Rect strip, double u) {
    if (_stripFor == strip && _uFor == u) return;
    _stripFor = strip;
    _uFor = u;
    // A Sillitoe band along the lower edge: two rows of checks, the light
    // ones cream (the plate's own navy shows through the others).
    final sq = 1.9 * u;
    final top = strip.bottom - 1.1 * u - 2 * sq;
    final checks = Path();
    for (var row = 0; row < 2; row++) {
      for (
        var i = row.isEven ? 0 : 1;
        strip.left + i * sq < strip.right;
        i += 2
      ) {
        checks.addRect(
          Rect.fromLTWH(strip.left + i * sq, top + row * sq, sq, sq),
        );
      }
    }
    _checks = checks;
    // The wings: [out] is -1 at the left end, +1 at the right.
    final wings = Path();
    for (final out in [-1.0, 1.0]) {
      final root = Offset(
        out < 0 ? strip.left + 3.5 * u : strip.right - 3.5 * u,
        strip.center.dy - .8 * u,
      );
      for (final (angle, len, wide) in const [
        (-.82, 11.5, 2.9),
        (-.34, 14.0, 3.2),
        (.18, 12.0, 3.0),
      ]) {
        final dir = Offset(out * math.cos(angle), math.sin(angle));
        final side = Offset(-dir.dy, dir.dx);
        final tip = root + dir * (len * u);
        wings
          ..moveTo(root.dx, root.dy)
          ..quadraticBezierTo(
            root.dx + dir.dx * len * u * .55 + side.dx * wide * u,
            root.dy + dir.dy * len * u * .55 + side.dy * wide * u,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            root.dx + dir.dx * len * u * .5 - side.dx * wide * u * .8,
            root.dy + dir.dy * len * u * .5 - side.dy * wide * u * .8,
            root.dx,
            root.dy,
          )
          ..close();
      }
    }
    _wings = wings;
  }

  static void _buildBar(Rect bar, double u) {
    if (_barFor == bar && _barU == u) return;
    _barFor = bar;
    _barU = u;
    final w = bar.width, h = bar.height;
    // Two studs hold the gauge in the plate, one each end.
    final studs = Path();
    for (final x in [bar.left - 3.8 * u, bar.right + 3.8 * u]) {
      studs.addOval(
        Rect.fromCircle(center: Offset(x, bar.top - 3.1 * u), radius: .9 * u),
      );
    }
    _studs = studs;
    // Slashes cut in the crust before baking: slim leaning lenses, one every
    // 21 u, so a loaf of any length shows the same scoring.
    final scores = Path(), edge = Path();
    for (var x = 12 * u; x < w - 6 * u; x += 21 * u) {
      final cx = bar.left + x, cy = bar.top + h * .46;
      final a = Offset(cx - 5.2 * u, cy + 2.1 * u);
      final b = Offset(cx + 5.2 * u, cy - 2.1 * u);
      final lens = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(cx - .6 * u, cy - 2.4 * u, b.dx, b.dy)
        ..quadraticBezierTo(cx + .6 * u, cy + 2.2 * u, a.dx, a.dy)
        ..close();
      scores.addPath(lens, Offset.zero);
      edge
        ..moveTo(a.dx + .6 * u, a.dy + .5 * u)
        ..quadraticBezierTo(
          cx + .4 * u,
          cy + 2.1 * u,
          b.dx - .6 * u,
          b.dy + .5 * u,
        );
    }
    _scores = scores;
    _scoreEdge = edge;
    // The crust: blisters (dark) and flour (light) scattered over it.
    final specks = Path(), flour = Path();
    for (var i = 0; i < 46; i++) {
      final x = bar.left + KingCooHudFx.hash(i, 11) * w;
      final y = bar.top + (.16 + KingCooHudFx.hash(i, 13) * .7) * h;
      final r = (.34 + KingCooHudFx.hash(i, 17) * .32) * u;
      (i.isEven ? specks : flour).addOval(
        Rect.fromCircle(center: Offset(x, y), radius: r),
      );
    }
    _specks = specks;
    _flour = flour;
    // The loaf's cracks: jagged splits the full height of the bar, a spur off
    // each, spaced so that any stretch of loaf has about two.
    final cracks = Path(), lit = Path();
    var k = 0;
    for (var x = 9 * u; x < w - 3 * u; x += 19 * u, k++) {
      final lean =
          (k.isEven ? -1 : 1) * (2.0 + KingCooHudFx.hash(k, 63) * 1.4) * u;
      final cx = bar.left + x + (KingCooHudFx.hash(k, 61) - .5) * 5 * u;
      final pts = [
        Offset(cx - lean * .5, bar.top + .4 * u),
        Offset(cx + lean * .5, bar.top + h * .34),
        Offset(cx - lean * .45, bar.top + h * .66),
        Offset(cx + lean * .4, bar.bottom - .4 * u),
      ];
      cracks.moveTo(pts[0].dx, pts[0].dy);
      lit.moveTo(pts[0].dx + .5 * u, pts[0].dy);
      for (var i = 1; i < pts.length; i++) {
        cracks.lineTo(pts[i].dx, pts[i].dy);
        lit.lineTo(pts[i].dx + .6 * u, pts[i].dy);
      }
      // A short spur off every other crack, down and away from its lean.
      if (k.isEven) {
        cracks
          ..moveTo(pts[1].dx, pts[1].dy)
          ..lineTo(pts[1].dx - lean.sign * 2.8 * u, pts[1].dy - 1.4 * u);
      }
    }
    _cracks = cracks;
    _crackLit = lit;
    // The torn edge where the health ends: a ragged lip drawn about its own
    // origin (x 0 = where the smooth loaf stops) and moved into place.
    _teeth = Path()
      ..moveTo(0, bar.top)
      ..lineTo(1.2 * u, bar.top)
      ..lineTo(2.9 * u, bar.top + h * .14)
      ..lineTo(1.0 * u, bar.top + h * .3)
      ..lineTo(3.3 * u, bar.top + h * .46)
      ..lineTo(1.3 * u, bar.top + h * .62)
      ..lineTo(2.9 * u, bar.top + h * .8)
      ..lineTo(1.5 * u, bar.bottom)
      ..lineTo(0, bar.bottom)
      ..close();
    _tipEdge = Path()
      ..moveTo(1.2 * u, bar.top)
      ..lineTo(2.9 * u, bar.top + h * .14)
      ..lineTo(1.0 * u, bar.top + h * .3)
      ..lineTo(3.3 * u, bar.top + h * .46)
      ..lineTo(1.3 * u, bar.top + h * .62)
      ..lineTo(2.9 * u, bar.top + h * .8)
      ..lineTo(1.5 * u, bar.bottom);
    // The empty trough: faint ticks at the quarters and a few stray crumbs.
    // A staged gauge, cut in thirds by its marks, has its ticks at the
    // sixths instead (halving each third).
    final ticks = Path(), sixths = Path();
    for (var i = 1; i <= 3; i++) {
      for (final (path, x) in [
        (ticks, bar.left + w * i / 4),
        (sixths, bar.left + w * (2 * i - 1) / 6),
      ]) {
        path
          ..moveTo(x, bar.top + 1.8 * u)
          ..lineTo(x, bar.bottom - 1.6 * u);
      }
    }
    _ticks = ticks;
    _sixths = sixths;
  }

  // The shield badge about the origin, the medallion's radius 1: a gently
  // arched top, straight sides and a rounded point (the guardian shield of the
  // map and the level card), a field inset in it, the siren dome on its base
  // over a gold star.
  static Path _shieldPath(double a, double b, [double dy = 0]) => Path()
    ..moveTo(-a, dy - b * .76)
    ..quadraticBezierTo(0, dy - b, a, dy - b * .76)
    ..lineTo(a, dy + b * .04)
    ..cubicTo(a, dy + b * .5, a * .5, dy + b * .8, 0, dy + b)
    ..cubicTo(-a * .5, dy + b * .8, -a, dy + b * .5, -a, dy + b * .04)
    ..close();
  static final Path _shield = _shieldPath(.98, 1.14);
  static final Path _field = _shieldPath(.72, .86, .1);
  static const _domeY = -.2;
  static final Path _dome = Path()
    ..moveTo(-.42, _domeY)
    ..arcToPoint(
      const Offset(.42, _domeY),
      radius: const Radius.circular(.42),
      clockwise: true,
    )
    ..close();
  static final Path _base = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-.56, _domeY - .01, .56, _domeY + .17),
        const Radius.circular(.06),
      ),
    );
  static final Path _gleam = Path()
    ..moveTo(-.29, _domeY - .06)
    ..quadraticBezierTo(-.25, _domeY - .27, -.08, _domeY - .33);
  static final Path _badgeStar = () {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? .27 : .12;
      final o = Offset(math.cos(a) * r, .6 + math.sin(a) * r);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }();
  // Light rays off the lit dome: three a side.
  static final Path _rays = () {
    final p = Path();
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final a = -math.pi / 2 + side * (.62 + i * .5);
        final from =
            Offset(math.cos(a), math.sin(a)) * .58 + const Offset(0, _domeY);
        final to =
            Offset(math.cos(a), math.sin(a)) * (.78 + (i == 1 ? .08 : 0)) +
            const Offset(0, _domeY);
        p
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy);
      }
    }
    return p;
  }();

  // The silver whistle about the origin, 2 units wide: a round chamber, a
  // mouthpiece to the left and a ring on top.
  static final Path whistleShape = Path()
    ..addOval(Rect.fromCircle(center: const Offset(.42, .1), radius: .52))
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-1.0, -.24, -.05, .42),
        const Radius.circular(.2),
      ),
    );
  static final Path whistleRing = Path()
    ..addOval(Rect.fromCircle(center: const Offset(.66, -.58), radius: .26));

  /// The chamber, mouthpiece and ring in one path (for one ink stroke).
  static final Path whistleInk = Path()
    ..addPath(whistleShape, Offset.zero)
    ..addPath(whistleRing, Offset.zero);

  // A pigeon's feathers at each end of the plate: three fanned from behind the
  // badge, swept out and up, so the plate wears wings as a winged badge does.
  static Path _wings = Path();

  // ------------------------------------------------------------ the lamp --

  /// The siren, as his own: 0 an unlit lamp, 1 red, 2 blue, and how brightly
  /// (0 to 1), from the pose that paints his cap, so the lamp on the plate and
  /// the lamp on his head can never disagree.
  static (int, double) siren(SkyBoss boss, {required bool reduced}) {
    if (!boss.age.isFinite || boss.phase != BossPhase.attacking) return (0, 0);
    final pose = KingCooPose(boss, BossMotion(boss, reducedMotion: reduced));
    return (pose.siren, pose.sirenGlow);
  }

  // -------------------------------------------------------------- plate --

  /// The plate: drop shadow, ink edge, a navy body with its checked band, two
  /// studs, the lamp's light spilling over it, and a brass rim that goes
  /// siren-red in fury and cream on a hit.
  static void frame(
    Canvas c,
    Rect strip,
    double u, {
    required bool fury,
    required bool defeated,
    required double wave,
    required double flash,
    int siren = 0,
    double sirenGlow = 0,
    double time = 0,
    bool reduced = false,
  }) {
    if (!strip.isFinite || !u.isFinite) return;
    _buildStrip(strip, u);
    final pill = RRect.fromRectAndRadius(
      strip,
      Radius.circular(strip.height / 2),
    );
    c.drawRRect(pill.shift(Offset(0, 1.5 * u)), KingCooHudFx.solid(ink, .35));
    // The wings sit behind the plate, so only their swept tips show.
    c.drawPath(_wings, KingCooHudFx.stroke(ink, 1.7 * u));
    c.drawPath(
      _wings,
      defeated
          ? KingCooHudFx.solid(KingCooPalette.brassDeep, .8)
          : KingCooHudFx.shaded(
              ('wings', strip.top, strip.bottom),
              () => KingCooKit.linear(
                Offset(0, strip.top - 4 * u),
                Offset(0, strip.bottom + 4 * u),
                const [
                  KingCooPalette.brassLit,
                  KingCooPalette.brass,
                  KingCooPalette.brassDeep,
                ],
                const [0, .45, 1],
              ),
            ),
    );
    c.drawRRect(pill, KingCooHudFx.solid(ink));
    final body = pill.deflate(1.1 * u);
    c.save();
    c.clipRRect(body, doAntiAlias: false);
    c.drawRect(
      strip,
      KingCooHudFx.shaded(
        ('plate', strip.top, strip.bottom),
        () => KingCooKit.linear(
          Offset(0, strip.top),
          Offset(0, strip.bottom),
          const [_plateLit, KingCooPalette.navy, KingCooPalette.navyDeep],
          const [0, .45, 1],
        ),
      ),
    );
    c.drawPath(
      _checks,
      KingCooHudFx.solid(KingCooPalette.blueLit, defeated ? .25 : .72),
    );
    // The lamp's light, red or blue, spilling over the plate from its badge.
    if (siren != 0 && sirenGlow > 0 && !defeated) {
      KingCooKit.glow(
        c,
        Offset(strip.left + 11 * u, strip.center.dy),
        strip.height * 2.6,
        siren == 1 ? KingCooPalette.sirenRed : KingCooPalette.sirenBlue,
        .5 * sirenGlow,
      );
    }
    c.restore();
    final Color? rim = defeated
        ? const Color(0xffa8e8bc)
        : fury
        ? Color.lerp(
            KingCooPalette.sirenRed,
            KingCooPalette.brassLit,
            wave * .55,
          )
        : null;
    if (rim == null) {
      c.drawRRect(
        body,
        KingCooHudFx.shaded(
            ('rim', strip.top, strip.bottom),
            () => KingCooKit.linear(
              Offset(0, strip.top - 4 * u),
              Offset(0, strip.bottom + 4 * u),
              const [
                KingCooPalette.brassLit,
                KingCooPalette.brass,
                KingCooPalette.brassDeep,
              ],
              const [0, .45, 1],
            ),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1 * u,
      );
    } else {
      c.drawRRect(body, KingCooHudFx.stroke(rim, 1.1 * u));
    }
    if (flash > 0) {
      c.drawRRect(
        body,
        KingCooHudFx.stroke(cream, 1.1 * u, flash.clamp(0.0, 1.0)),
      );
    }
  }

  /// The shudder the plate takes on a hit, [since] seconds after it: about a
  /// pixel, gone in a tenth of a second. Still under Reduced Motion.
  static Offset jolt(double since, double u, {required bool reduced}) {
    if (reduced || !since.isFinite || !u.isFinite || since < 0 || since > .14) {
      return Offset.zero;
    }
    final k = 1 - since / .14;
    return Offset(
      math.sin(since * 150) * u * k,
      math.cos(since * 110) * .45 * u * k,
    );
  }

  // ----------------------------------------------------------- medallion --

  /// The medallion: a brass guardian shield with a siren lamp on a navy field
  /// and a gold star under it. The lamp is dark (a glassy dim red dome) until
  /// the siren sounds, then glows red or blue as his own does, throwing rays;
  /// in fury it burns red.
  static void crest(
    Canvas c,
    Offset center,
    double r,
    double u, {
    required bool fury,
    int siren = 0,
    double sirenGlow = 0,
    double flash = 0,
    bool defeated = false,
    double time = 0,
    bool reduced = false,
  }) {
    if (!center.isFinite || !r.isFinite || !u.isFinite) return;
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(r);
    final line = 1.25 * u / r;
    _shieldUnit(c, line, defeated: defeated);
    _lampUnit(
      c,
      line,
      siren: siren,
      glow: sirenGlow,
      fury: fury,
      defeated: defeated,
    );
    if (flash > 0) {
      c.drawPath(
        _shield,
        KingCooHudFx.stroke(cream, line * 1.1, flash.clamp(0.0, 1.0)),
      );
    }
    c.restore();
  }

  /// The badge on its own, without the lamp: the brass shield, its navy field
  /// and the gold star, [r] its radius about [center] (the chest badge that
  /// floats up when he is beaten). [alpha] fades it; [u] is the line width.
  static void badge(
    Canvas c,
    Offset center,
    double r, {
    double u = 1,
    double alpha = 1,
  }) {
    if (!center.isFinite || !r.isFinite || r <= 0 || alpha <= 0) return;
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(r);
    _shieldUnit(c, 1.25 * u / r, alpha: alpha);
    c.drawPath(_badgeStar, KingCooHudFx.solid(KingCooPalette.gold, alpha));
    c.restore();
  }

  /// Just the siren lamp (dome, brass base, light and rays) about [center],
  /// [r] the dome's size times 2.4: lit red (1) or blue (2) at [glow], else an
  /// unlit glassy dome.
  static void lamp(
    Canvas c,
    Offset center,
    double r, {
    int siren = 0,
    double glow = 0,
    bool fury = false,
    double u = 1,
  }) {
    if (!center.isFinite || !r.isFinite || r <= 0) return;
    c.save();
    c.translate(center.dx, center.dy - _domeY * r);
    c.scale(r);
    _lampUnit(c, 1.1 * u / r, siren: siren, glow: glow, fury: fury);
    c.restore();
  }

  // The shield, its field and its star, in the unit space of the medallion.
  static void _shieldUnit(
    Canvas c,
    double line, {
    bool defeated = false,
    double alpha = 1,
  }) {
    c.drawPath(_shield, KingCooHudFx.stroke(ink, line * 2, alpha));
    c.drawPath(
      _shield,
      defeated
          ? KingCooHudFx.solid(const Color(0xffa8e8bc), alpha)
          : KingCooHudFx.shaded(
              'shield',
              () => KingCooKit.linear(
                const Offset(0, -1.1),
                const Offset(0, 1.1),
                const [
                  KingCooPalette.brassLit,
                  KingCooPalette.brass,
                  KingCooPalette.brassDeep,
                ],
                const [0, .42, 1],
              ),
              alpha,
            ),
    );
    c.drawPath(
      _field,
      KingCooHudFx.shaded(
        'field',
        () => KingCooKit.linear(
          const Offset(0, -.8),
          const Offset(0, .9),
          const [KingCooPalette.navy, KingCooPalette.navyDeep],
        ),
        alpha,
      ),
    );
    c.drawPath(
      _badgeStar,
      KingCooHudFx.solid(KingCooPalette.gold, defeated ? .4 : alpha),
    );
  }

  // The lamp in the unit space of the medallion (dome centre at y = _domeY).
  static void _lampUnit(
    Canvas c,
    double line, {
    int siren = 0,
    double glow = 0,
    bool fury = false,
    bool defeated = false,
  }) {
    final g = glow.isFinite ? glow.clamp(0.0, 1.0) : 0.0;
    final lit = !defeated && siren != 0 && g > 0;
    final hue = siren == 2 ? KingCooPalette.sirenBlue : KingCooPalette.sirenRed;
    final core = siren == 2 ? const Color(0xffd8ecff) : const Color(0xffffc2b8);
    final dim = fury && !defeated
        ? KingCooPalette.sirenRed
        : const Color(0xff8a2b3d);
    if (lit) {
      c.drawPath(_rays, KingCooHudFx.stroke(hue, .09, .9 * g));
    }
    c.drawPath(_base, KingCooHudFx.stroke(ink, line));
    c.drawPath(_base, KingCooHudFx.solid(KingCooPalette.brass));
    c.drawPath(_dome, KingCooHudFx.stroke(ink, line * 1.3));
    c.drawPath(
      _dome,
      KingCooHudFx.solid(
        lit
            ? Color.lerp(dim, hue, g)!
            : (defeated ? KingCooPalette.sirenOffDeep : dim),
      ),
    );
    if (lit) {
      c.drawCircle(
        const Offset(0, _domeY - .12),
        .17,
        KingCooHudFx.solid(core, g),
      );
    }
    c.drawPath(
      _gleam,
      KingCooHudFx.stroke(KingCooPalette.white, .08, lit ? .95 : .6),
    );
  }

  // --------------------------------------------------------------- gauge --

  /// The empty gauge: a dark trough in an ink channel with quarter ticks and
  /// a few crumbs left on the floor of it, the whole channel flushed red in
  /// fury (the siren on it).
  static void track(
    Canvas c,
    Rect bar,
    double u, {
    bool fury = false,
    bool reduced = false,
    double time = 0,
    double furyAge = double.infinity,
    bool staged = false,
  }) {
    if (!bar.isFinite || !u.isFinite) return;
    _buildBar(bar, u);
    final radius = Radius.circular(bar.height / 2);
    final track = RRect.fromRectAndRadius(bar, radius);
    c.drawRRect(track.inflate(1.3 * u), KingCooHudFx.solid(ink));
    c.drawRRect(track, KingCooHudFx.solid(_trough));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bar.left, bar.top + 1.6 * u, bar.right, bar.bottom),
        radius,
      ),
      KingCooHudFx.solid(fury ? const Color(0xff2a1530) : _troughLit),
    );
    // Two studs hold the gauge in the plate.
    c.drawPath(_studs, KingCooHudFx.solid(KingCooPalette.brass, .95));
    // The tag's own stretch of the channel stays clear while FURY shows.
    final tagged = fury && furyAge < _furyTagSeconds;
    if (!tagged) {
      c.drawPath(
        staged ? _sixths : _ticks,
        KingCooHudFx.stroke(ink, .9 * u, .6),
      );
    }
  }

  /// The loaf up to [right]: crust, flour, scoring, cracks that spread through
  /// it as it is eaten, a torn edge with a pale crumb under the crust, and,
  /// while the gauge fills on the entrance ([surge], 0 to 1), a fresh-baked
  /// gold sweep over it. [share] is the health left (0 to 1).
  static void fill(
    Canvas c,
    Rect bar,
    double right,
    double u,
    List<Color> ramp, {
    required double glow,
    required double phase,
    required bool hotTip,
    bool fury = false,
    double surge = 0,
    double share = 1,
    double entrance = -1,
  }) {
    if (!bar.isFinite || !right.isFinite || !u.isFinite) return;
    _buildBar(bar, u);
    final g = (glow * 6).round() / 6;
    final colors = fury ? furyCrust : crust;
    final body = KingCooHudFx.shaded(
      ('loaf', bar.top, bar.bottom, fury, g),
      () => KingCooKit.linear(
        Offset(0, bar.top),
        Offset(0, bar.bottom),
        [Color.lerp(colors[0], KingCooPalette.white, g)!, colors[1], colors[2]],
        const [0, .5, 1],
      ),
    );
    // The smooth loaf stops a lip short of [right]; the lip is the torn edge,
    // so a full gauge (no lip) meets the channel's end cleanly.
    final lip = hotTip ? 3.3 * u : 0.0;
    final flat = math.max(bar.left, right - lip);
    c.drawRect(Rect.fromLTRB(bar.left, bar.top, flat, bar.bottom), body);
    if (hotTip) {
      c.save();
      c.translate(flat, 0);
      c.drawPath(_teeth, body);
      c.restore();
    }
    c.save();
    c.clipRect(
      Rect.fromLTRB(
        bar.left,
        bar.top,
        right - (hotTip ? .4 * u : 0),
        bar.bottom,
      ),
    );
    c.drawPath(
      _scores,
      KingCooHudFx.solid(KingCooPalette.crumbHi, fury ? .55 : .86),
    );
    c.drawPath(_scoreEdge, KingCooHudFx.stroke(colors[2], .8 * u, .85));
    c.drawPath(_specks, KingCooHudFx.solid(colors[2], .55));
    c.drawPath(_flour, KingCooHudFx.solid(KingCooPalette.cream, .5));
    // Cracks open in the stretch of loaf nearest the torn edge first, and
    // reach further back as the health falls: a full loaf has none.
    final eaten = (1 - share).clamp(0.0, 1.0);
    final reach = bar.width * (eaten * 1.4 - .02);
    if (reach > 0) {
      c.save();
      c.clipRect(Rect.fromLTRB(right - reach, bar.top, right, bar.bottom));
      c.drawPath(
        _cracks,
        KingCooHudFx.stroke(const Color(0xff4a2410), 1.5 * u, .95),
      );
      c.drawPath(
        _crackLit,
        KingCooHudFx.stroke(
          fury ? const Color(0xffffd0c0) : KingCooPalette.crumbHi,
          .55 * u,
          fury ? .9 : .55,
        ),
      );
      c.restore();
    }
    c.restore();
    // The underside, baked darker, and the egg-wash gloss along the top.
    c.drawRect(
      Rect.fromLTRB(bar.left, bar.bottom - 2.2 * u, flat, bar.bottom),
      KingCooHudFx.solid(colors[2], .42),
    );
    c.drawRect(
      Rect.fromLTRB(
        bar.left + 2 * u,
        bar.top + 1.0 * u,
        math.max(bar.left + 2 * u, right - 3 * u),
        bar.top + 1.9 * u,
      ),
      KingCooHudFx.solid(KingCooPalette.white, fury ? .5 : .38),
    );
    if (hotTip) {
      c.save();
      c.translate(flat, 0);
      c.drawPath(
        _tipEdge,
        KingCooHudFx.stroke(KingCooPalette.crumbHi, 1.2 * u),
      );
      c.restore();
    }
    // The fresh-baked gold sweep as the gauge fills on the entrance.
    if (surge > 0 && entrance >= 0) {
      final front = bar.left + (right - bar.left) * entrance;
      c.drawRect(
        Rect.fromLTRB(bar.left, bar.top, math.max(bar.left, right), bar.bottom),
        KingCooHudFx.solid(KingCooPalette.gold, .5 * surge),
      );
      c.drawRect(
        Rect.fromLTRB(
          math.max(bar.left, front - 5 * u),
          bar.top,
          math.max(bar.left, front),
          bar.bottom,
        ),
        KingCooHudFx.solid(KingCooPalette.white, .55 * surge),
      );
    }
  }

  /// Crumbs shaken off the torn edge: a handful that drop away from it on
  /// staggered falls, out past the plate. Still under Reduced Motion.
  static void crumbs(
    Canvas c,
    Rect bar,
    double right,
    double u, {
    required double time,
    required bool fury,
    required bool reduced,
    double surge = 0,
  }) {
    if (!(bar.isFinite && right.isFinite && u.isFinite && time.isFinite)) {
      return;
    }
    if (right <= bar.left + 2 * u || right >= bar.right - .5) return;
    final count = fury ? 6 : 4;
    final bits = Path();
    for (var i = 0; i < count; i++) {
      final life = reduced
          ? .15 + .6 * KingCooHudFx.hash(i, 51)
          : (time * (.7 + KingCooHudFx.hash(i, 53) * .5) +
                    KingCooHudFx.hash(i, 55)) %
                1;
      final x =
          right -
          (KingCooHudFx.hash(i, 57) * 4 - 1.5) * u +
          (reduced ? 0 : math.sin(time * 3 + i * 2.1) * 1.1 * u) * life;
      final y =
          bar.center.dy + (1.5 + life * (9 + KingCooHudFx.hash(i, 59) * 4)) * u;
      final s = (1.0 - life * .55) * (i.isEven ? 1.0 : .7) * u;
      bits.addRect(
        Rect.fromCenter(center: Offset(x, y), width: s * 1.5, height: s),
      );
    }
    c.drawPath(bits, KingCooHudFx.solid(KingCooPalette.crumbHi, .95));
  }

  /// The damage drain: pale crumb going stale.
  static void chip(
    Canvas c,
    Rect area, {
    required double heat,
    required double alpha,
  }) {
    if (!area.isFinite) return;
    c.drawRect(
      area,
      Paint()
        ..color = Color.lerp(
          const Color(0xffe3b870),
          KingCooPalette.crumbHi,
          heat,
        )!.withValues(alpha: alpha),
    );
  }

  /// The half mark: a silver whistle perched on the plate's top rim over the
  /// gauge's middle, with a brass notch through the track, until the fury.
  /// When the fury begins, [furyAge] seconds ago, the whistle blows: a flash
  /// of red and blue siren rays bursts out of the notch, the whistle burns
  /// hot and the notch keeps a red light. A staged campaign King Coo's fury
  /// mark stands at [share] (a third) instead of the middle.
  static void halfMark(
    Canvas c,
    Rect bar,
    double u, {
    required bool above,
    required bool fury,
    required double wave,
    double furyAge = double.infinity,
    bool reduced = false,
    double share = .5,
  }) {
    if (!bar.isFinite || !u.isFinite) return;
    _buildBar(bar, u);
    final x = bar.left + bar.width * share;
    final hot = fury
        ? Color.lerp(
            KingCooPalette.sirenRed,
            KingCooPalette.brassLit,
            wave * .45,
          )!
        : KingCooPalette.brass;
    // The notch through the track: ink, then brass (a red light in fury).
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - 1.4 * u,
          bar.top - 4.2 * u,
          x + 1.4 * u,
          bar.bottom + (above ? 1.0 : .6) * u,
        ),
        Radius.circular(1.2 * u),
      ),
      KingCooHudFx.solid(ink),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - .65 * u,
          bar.top - 3.6 * u,
          x + .65 * u,
          bar.bottom + (above ? .4 : .1) * u,
        ),
        Radius.circular(.6 * u),
      ),
      KingCooHudFx.solid(hot),
    );
    final at = Offset(x, bar.center.dy);
    if (fury && furyAge >= 0 && furyAge < .6) {
      // The siren flash: blue and white rays out of the notch, a red ring and
      // a hot core (blue and white, because the gauge is red by now).
      final k = reduced ? .35 : furyAge / .6;
      final fade = reduced ? 1.0 : 1 - k * k;
      final reach = (6 + 22 * math.sqrt(k)) * u;
      final blue = Path(), white = Path();
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6 + .26;
        final len = reach * (i % 2 == 0 ? 1 : .66);
        (i % 4 < 2 ? white : blue)
          ..moveTo(at.dx + math.cos(a) * 3.2 * u, at.dy + math.sin(a) * 3.2 * u)
          ..lineTo(at.dx + math.cos(a) * len, at.dy + math.sin(a) * len);
      }
      c.drawPath(blue, KingCooHudFx.stroke(KingCooPalette.sirenBlue, 2.6 * u, fade));
      c.drawPath(white, KingCooHudFx.stroke(KingCooPalette.cream, 2.6 * u, fade));
      c.drawCircle(
        at,
        (2.6 + 3.4 * (1 - k)) * u,
        KingCooHudFx.stroke(KingCooPalette.sirenRed, 1.5 * u, fade),
      );
      c.drawCircle(at, (1.8 + 2.4 * (1 - k)) * u, KingCooHudFx.solid(KingCooPalette.white, fade));
    }
    // The whistle, its ring up, sitting on the rim over the notch.
    final top = bar.center.dy - 11.9 * u;
    c.save();
    c.translate(x - .2 * u, top);
    c.scale(4.4 * u);
    c.drawPath(whistleInk, KingCooHudFx.stroke(ink, .44));
    c.drawPath(
      whistleShape,
      fury
          ? KingCooHudFx.solid(hot)
          : KingCooHudFx.shaded(
              'whistle',
              () => KingCooKit.linear(
                const Offset(0, -.5),
                const Offset(0, .7),
                const [
                  KingCooPalette.steelLit,
                  KingCooPalette.steel,
                  KingCooPalette.steelDeep,
                ],
                const [0, .5, 1],
              ),
            ),
    );
    c.drawPath(
      whistleRing,
      KingCooHudFx.stroke(KingCooPalette.steelLit, .17),
    );
    c.restore();
  }

  // -------------------------------------------------------------- gauge hp --

  /// The gauge fill as the entrance shows it: it fills from empty in the 0.6 s
  /// that end the arrival (or, when the cutscene hides the plate, the 0.6 s
  /// after it), never past the boss's real health. Paused, replayed and
  /// seeked frames repeat: it is a function of the boss's clock.
  static double gaugeHp(SkyBoss boss, {required bool reduced}) {
    if (boss.phase == BossPhase.defeated) return 0;
    final full = boss.maxHp.toDouble();
    final age = boss.age.isFinite ? boss.age : 0.0;
    final start = boss.cinematic
        ? boss.arrivalDuration
        : boss.arrivalDuration - .6;
    final shown = reduced
        ? 1.0
        : BossMotion.ease(((age - start) / .6).clamp(0.0, 1.0));
    return boss.phase == BossPhase.arriving
        ? full * shown
        : math.min(boss.hp.toDouble(), full * shown);
  }

  /// How far the entrance has filled the gauge, 0 to 1 (1 once it is done);
  /// -1 when it is not filling.
  static double entrance(SkyBoss boss, {required bool reduced}) {
    if (reduced || !boss.age.isFinite) return -1;
    final start = boss.cinematic
        ? boss.arrivalDuration
        : boss.arrivalDuration - .6;
    final t = (boss.age - start) / .6;
    return t <= 0 || t >= 1 ? -1 : BossMotion.ease(t);
  }

  /// 0 to 1 and back while the gauge fills on the entrance, else 0.
  static double surge(SkyBoss boss, {required bool reduced}) {
    if (reduced || !boss.age.isFinite) return 0;
    final start = boss.cinematic
        ? boss.arrivalDuration
        : boss.arrivalDuration - .6;
    final t = (boss.age - start) / .6;
    return t <= 0 || t >= 1 ? 0 : math.sin(t * math.pi);
  }

  // ------------------------------------------------------------ the tag --

  /// What the PUFFED tag shows right now: how much of it ([show], 0 to 1),
  /// the pop's progress ([pop], 0 to 1 over the .3 s after the chest bursts,
  /// else 0) and how many POP pips are lit (one for each 20 health the window
  /// has taken, three at the pop). `show` is 0 whenever rocks do not count
  /// double.
  static ({double show, double pop, int pips}) tagState(
    SkyBoss boss, {
    required bool reduced,
  }) {
    const none = (show: 0.0, pop: 0.0, pips: 0);
    if (!boss.isKingCoo || !boss.age.isFinite) return none;
    if (boss.phase != BossPhase.attacking) return none;
    final pips = (boss.puffDamage ~/ 20).clamp(0, 3);
    // Under Reduced Motion the tag is simply there while rocks count double,
    // and gone the moment they stop (nothing eases or bursts).
    if (reduced) {
      return boss.puffWindow ? (show: 1.0, pop: 0.0, pips: pips) : none;
    }
    final cycle = boss.cooCycle;
    if (boss.popped) {
      final at = boss.poppedAt;
      final since = at == null ? double.infinity : boss.age - at;
      if (since < 0 || since >= .3) return none;
      return (show: 1 - since / .3, pop: since / .3, pips: 3);
    }
    if (boss.puffWindow) {
      final into = BossMotion.ease(
        ((cycle - KingCoo.puffAt) / .18).clamp(0.0, 1.0),
      );
      return (show: into, pop: 0.0, pips: pips);
    }
    final since = cycle - KingCoo.windowEnd;
    if (since >= 0 && since < .25 && boss.puffs > 0) {
      return (show: 1 - since / .25, pop: 0.0, pips: pips);
    }
    return none;
  }

  /// **PUFFED ×2**: the word in cream, the gold ×2; set smaller when a
  /// translation would push the tag past [tagWidthMax] (its other parts take
  /// 42 u).
  static TextPainter _puffed(double u) {
    TextPainter at(double k) => _text(
      L10n.strings.bossKingCooPuffed,
      tagType * u * k,
      .5 * u * k,
      tail: ' ×2',
      tailSize: (tagType + 1.5) * u * k,
    );
    final full = at(1);
    final room = (tagWidthMax - 42) * u;
    return full.width <= room
        ? full
        : at((room / full.width * 100).floorToDouble() / 100);
  }

  /// Where the tag hangs when it is fully shown (px): from the plate's lower
  /// edge, centred a quarter of the way along the gauge, so it keeps left of
  /// his head, and never wider than [tagWidthMax] (u = 1).
  static Rect tagBox(Rect strip, Rect bar, double u) {
    final text = _puffed(u);
    final w = 5.6 * u + 8.4 * u + 3.2 * u + text.width + 4.4 * u + 3 * 5.8 * u + 3.0 * u;
    // A quarter of the way along the gauge, but never so far right that it
    // reaches past the gauge's middle, and never off the plate's left end.
    final cx = math.max(
      strip.left + w / 2 + 5 * u,
      math.min(bar.left + bar.width * .25, bar.center.dx - w / 2 + 4 * u),
    );
    return Rect.fromLTWH(cx - w / 2, strip.bottom - 1.2 * u, w, 14.6 * u);
  }

  /// The tag hangs from the plate's lower edge, left of the gauge's middle
  /// (clear of his head), a navy label with a brass rim: a pink chest-ball on
  /// its left, **PUFFED x2** in cream and gold, and the three POP pips on its
  /// right. It pops in with the inhale, throbs with the siren, flashes when a
  /// puffed rock lands, and bursts away on the pop. Still under Reduced Motion
  /// (steady, no pop animation).
  static void puffedTag(
    Canvas c,
    Rect strip,
    Rect bar,
    double u,
    SkyBoss boss, {
    required bool reduced,
  }) {
    if (!strip.isFinite || !bar.isFinite || !u.isFinite) return;
    final s = tagState(boss, reduced: reduced);
    if (s.show <= 0) return;
    _buildBar(bar, u);
    final text = _puffed(u);
    final ball = 8.4 * u, gap = 3.2 * u, pipGap = 5.8 * u, pipR = 2.1 * u;
    final spot = tagBox(strip, bar, u);
    final w = spot.width, h = spot.height;
    final cx = spot.center.dx, top = spot.top;
    final beat = reduced ? .5 : .5 + .5 * math.sin(boss.age * math.pi * 2 * 3);
    final hitAge = boss.age - boss.lastPuffHitAt;
    final struck = !reduced && hitAge >= 0 && hitAge < .18
        ? 1 - hitAge / .18
        : 0.0;
    // It pops in (from a little narrow), is steady, and bursts away on the pop
    // (wider, flattening); a landed rock makes it jump a hair.
    final sx = s.pop > 0
        ? 1 + .4 * s.pop
        : (.74 + .26 * s.show) * (1 + .05 * struck);
    final sy = s.show * (s.pop > 0 ? 1 : 1 + .05 * struck);
    c.save();
    c.translate(cx, top);
    c.scale(sx, sy);
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w / 2, 0, w, h),
      Radius.circular(3 * u),
    );
    // Two links tie it to the plate.
    c.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(-w / 2 + 5.2 * u, -1.2 * u, 1.6 * u, 2.2 * u))
        ..addRect(Rect.fromLTWH(w / 2 - 6.8 * u, -1.2 * u, 1.6 * u, 2.2 * u)),
      KingCooHudFx.solid(KingCooPalette.brassDeep),
    );
    // Its glow spills onto the sky under the label, red, then blue.
    final siren = beat > .5
        ? KingCooPalette.sirenRed
        : KingCooPalette.sirenBlue;
    KingCooKit.glow(
      c,
      Offset(0, h + .6 * u),
      w * .55,
      siren,
      (.38 + .3 * struck) * s.show,
    );
    c.drawRRect(box.inflate(.9 * u), KingCooHudFx.solid(ink));
    c.drawRRect(
      box,
      KingCooHudFx.shaded(
        ('tag', u, h),
        () => KingCooKit.linear(
          Offset.zero,
          Offset(0, h),
          const [
            KingCooPalette.navyLit,
            KingCooPalette.navy,
            KingCooPalette.navyDeep,
          ],
          const [0, .5, 1],
        ),
      ),
    );
    c.drawRRect(
      box,
      KingCooHudFx.stroke(
        Color.lerp(
          KingCooPalette.brass,
          KingCooPalette.white,
          math.max(struck, beat * .25),
        )!,
        .95 * u,
      ),
    );
    // The chest-ball: pink, taut and glossy, like the chest it points at.
    final bx = -w / 2 + 5.6 * u + ball / 2;
    c.drawCircle(Offset(bx, h / 2), ball / 2 + .8 * u, KingCooHudFx.solid(ink));
    c.drawCircle(
      Offset(bx, h / 2),
      ball / 2,
      KingCooHudFx.solid(
        Color.lerp(
          KingCooPalette.breast,
          KingCooPalette.breastHi,
          struck + beat * .3,
        )!,
      ),
    );
    c.drawCircle(
      Offset(bx - ball * .16, h / 2 - ball * .17),
      ball * .13,
      KingCooHudFx.solid(KingCooPalette.white, .95),
    );
    text.paint(
      c,
      Offset(bx + ball / 2 + gap, h / 2 - text.height / 2 + .3 * u),
    );
    // The POP pips: one for every 20 health the window has taken; the third
    // is the pop. Hollow rings until they light.
    final px = w / 2 - 3.0 * u - 2.5 * pipGap;
    final dark = Path(), lit = Path(), burst = Path(), ring = Path();
    for (var i = 0; i < 3; i++) {
      final at = Offset(px + i * pipGap, h / 2);
      (i < s.pips ? (i == 2 ? burst : lit) : dark).addOval(
        Rect.fromCircle(center: at, radius: pipR),
      );
      ring.addOval(Rect.fromCircle(center: at, radius: pipR + .5 * u));
    }
    c.drawPath(ring, KingCooHudFx.stroke(ink, 1.9 * u));
    c.drawPath(dark, KingCooHudFx.stroke(KingCooPalette.blueLit, .7 * u, .9));
    c.drawPath(lit, KingCooHudFx.solid(KingCooPalette.gold));
    c.drawPath(burst, KingCooHudFx.solid(KingCooPalette.sirenRed));
    c.restore();
  }
}

/// Paints and gradient shaders shared by King Coo's HUD and set-pieces.
abstract final class KingCooHudFx {
  /// A well-mixed 0..1 value for slot [i] and [salt]. (The kit's hash is
  /// linear in [i], so neighbouring slots line up along straight lines.)
  static double hash(int i, [int salt = 0]) {
    var x = (i * 0x9E3779B1 + salt * 0x85EBCA6B + 0x27d4eb2f) & 0xffffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xffffffff;
    x ^= x >> 16;
    return x / 4294967296.0;
  }

  static double _a(double alpha) =>
      alpha.isFinite ? alpha.clamp(0.0, 1.0) : 0.0;

  /// A paint of the gradient kept under [key] (built by [make] through
  /// [KingCooKit.linear] and friends, which count it) at [alpha]: one shader
  /// serves every fade.
  static Paint shaded(Object key, Paint Function() make, [double alpha = 1]) =>
      Paint()
        ..shader = KingCooKit.cached(key, make).shader
        ..color = KingCooPalette.white.withValues(alpha: _a(alpha));

  /// A flat fill of [color] at [alpha] (multiplied into the colour's own).
  static Paint solid(Color color, [double alpha = 1]) => Paint()
    ..color = alpha >= 1 ? color : color.withValues(alpha: _a(color.a * alpha));

  /// A round-capped, round-joined stroke.
  static Paint stroke(Color color, double width, [double alpha = 1]) =>
      solid(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
}
