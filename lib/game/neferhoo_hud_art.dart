import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';
import 'neferhoo_kit.dart';
import 'neferhoo_staging_art.dart';

/// Neferhoo's skin of the shared health strip and of the staged-boss HUD
/// (design §5.7, in family with the shipped guardians' plates): a long
/// cartouche, the lapis plate in a burnished gold rim with a wave line and
/// a reed frieze, his name in its own cartouche with the tie bar, the mask
/// medallion at the left end, a recessed lapis track and a gold-leaf gauge
/// whose end is a torn papyrus edge (turquoise in fury), and at the fury
/// mark (a third along the staged bar) a carnelian wax seal that cracks,
/// turquoise light leaking, once he is furious. The stage gem at two thirds
/// is the shared one in his gold ([stageMetal]); the STRONGER! card, the
/// numbers, the chip and the tags are the shared plate's.
///
/// `BossHealthBarArt` keeps the layout, timeline and numbers; these are only
/// his brushstrokes (the A2 hunk of `boss_health_bar_art.dart` calls them
/// from his branches). Pure functions of the values given, so paused,
/// replayed and captured frames repeat. The plate and the medallion are
/// recorded once per layout as pictures and replayed; nothing here blurs,
/// opens a layer or a clip, or lays out text. Budget (`neferhoo_hud_test`):
/// the strip <= 60 draw calls in every state (a replayed picture counts
/// once).
///
/// The [emblem] (the golden mask in profile, crest and long beak) is also
/// the name card's badge and the keepsake at small sizes.
abstract final class NeferhooHudArt {
  static const _ink = NeferhooPalette.ink;

  /// The gauge's ramp as [light, main, deep]: gold leaf on papyrus.
  static const ramp = [
    NeferhooPalette.goldHi,
    NeferhooPalette.gold,
    NeferhooPalette.goldShade,
  ];

  /// The gauge's ramp in fury: his turquoise magic.
  static const furyRamp = [
    NeferhooPalette.turqLit,
    NeferhooPalette.turq,
    NeferhooPalette.turqShade,
  ];

  /// The stage gem's metal and the face of its tags (see
  /// `BossStageHudArt.metal`): his mask's gold, on lapis.
  static const stageMetal = (
    ink: NeferhooPalette.ink,
    deep: NeferhooPalette.goldDeep,
    main: NeferhooPalette.gold,
    lit: NeferhooPalette.goldLit,
    face: NeferhooPalette.lapisDeep,
  );

  /// The power-up's colour and its light (`BossPowerUpArt.colors`): his
  /// turquoise magic.
  static const powerUp = (NeferhooPalette.turq, NeferhooPalette.turqLit);

  /// Where the power-up centres and how far it reaches (px) on a screen [h]
  /// high (`BossPowerUpArt.frame`): about his chest and mask, where the
  /// encounter draws him (the rules' place, no shared offset).
  static ({Offset at, double reach}) powerUpFrame(BossMotion m, double h) {
    final boss = m.boss, unit = h * SkyBoss.radius;
    final x = boss.x.isFinite ? boss.x : 0.0;
    // (where the encounter draws him: held at the bob's centre under Reduced
    // Motion, `NeferhooFightArt.drawnY`)
    final drawn = m.reducedMotion ? Neferhoo.hoverY(0) : boss.y;
    final y = drawn.isFinite ? drawn : .5;
    return (
      at: Offset(x * h, y * h) + Offset(-.4 * unit, -.6 * unit),
      reach: unit * 2.4,
    );
  }

  // -------------------------------------------------------------- emblem --

  static Paint _fill(Color c, [double a = 1]) => NeferhooStaging.fill(c, a);
  static Paint _line(Color c, double w, [double a = 1]) => NeferhooStaging.line(c, w, a);
  static Shader _lin(Offset a, Offset b, List<Color> c, [List<double>? s]) =>
      NeferhooStaging.lin(a, b, c, s);
  static Shader _rad(Offset o, double r, List<Color> c, [List<double>? s]) =>
      NeferhooStaging.rad(o, r, c, s);

  /// A smooth closed path through [pts] (Catmull-Rom as cubics).
  static Path _smooth(List<Offset> pts) {
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n], p1 = pts[i];
      final p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return p..close();
  }

  /// The crest fan: five cinnamon feathers swept back from the crown (the
  /// rig's lean), with their bands and black tips, and one outline round
  /// them all.
  static ({List<(Offset, Offset, Offset, double, Path)> feathers, Path union}) _fan() =>
      NeferhooStaging.once('emblem-fan', () {
        const root = Offset(-.12, -.52);
        final out = <(Offset, Offset, Offset, double, Path)>[];
        Path? union;
        for (var i = 0; i < 5; i++) {
          final t = i / 4;
          final ang = -1.85 + t * 1.05;
          final len = .78 + t * .2;
          final d = Offset(math.cos(ang), math.sin(ang)), n = Offset(-d.dy, d.dx);
          final tip = root + d * len;
          const fw = .27;
          final a = root + d * len * .6 + n * fw, b = root + d * len * .6 - n * fw;
          final f = Path()
            ..moveTo(root.dx, root.dy)
            ..quadraticBezierTo(a.dx, a.dy, tip.dx, tip.dy)
            ..quadraticBezierTo(b.dx, b.dy, root.dx, root.dy)
            ..close();
          out.add((root, d, n, len, f));
          union = union == null ? f : Path.combine(PathOperation.union, union, f);
        }
        return (feathers: out, union: union!);
      });

  static final Path _nemes = _smooth(const [
    Offset(-.02, -.5),
    Offset(.5, -.34),
    Offset(.66, .12),
    Offset(.52, .66),
    Offset(.18, .6),
    Offset(.1, .12),
  ]);

  static final Path _face = _smooth(const [
    Offset(-.04, -.62),
    Offset(-.4, -.54),
    Offset(-.58, -.16),
    Offset(-.5, .3),
    Offset(-.2, .56),
    Offset(.12, .44),
    Offset(.2, -.02),
    Offset(.16, -.42),
  ]);

  static final Path _beak = Path()
    ..moveTo(-.44, -.18)
    ..cubicTo(-.82, -.38, -1.28, .02, -1.5, .66)
    ..cubicTo(-1.22, .3, -.86, .26, -.4, .2)
    ..close();

  static final Path _kohl = Path()
    ..moveTo(-.34, -.13)
    ..quadraticBezierTo(0, -.34, .3, -.2)
    ..lineTo(.28, -.14)
    ..quadraticBezierTo(0, -.18, -.2, -.02)
    ..close();

  static final Path _almond = Path()
    ..moveTo(-.44, -.12)
    ..quadraticBezierTo(-.22, -.34, .0, -.14)
    ..quadraticBezierTo(-.22, .04, -.44, -.12)
    ..close();

  /// How far the [emblem] reaches about its centre in disc radii, without
  /// the disc (the beak leaves the circle at the lower left): for fitting it
  /// into a box.
  static const emblemReach = Rect.fromLTRB(-1.55, -1.36, .72, .7);

  /// The golden courier mask in profile (the hoopoe crest, the nemes, the
  /// kohl eye, the long decurved beak), centred at [o], [r] the disc's
  /// radius in pixels. [disc] false draws the mask alone (the keepsake's
  /// stamp is the ground); [glow] 0..1 lights the eye turquoise (fury);
  /// [detail] (default: [r] at least 11 px) adds the collar and the inlay
  /// where they read. [pixels] is the disc radius on screen when [r] is not
  /// in pixels (a canvas already scaled): the lines stay at least ~.9 px.
  static void emblem(
    Canvas c,
    Offset o,
    double r, {
    bool disc = true,
    bool crest = true,
    double glow = 0,
    double alpha = 1,
    bool? detail,
    double? pixels,
  }) {
    if (alpha <= 0 || !(r > 0) || !o.isFinite) return;
    final px = pixels ?? r;
    final fine = detail ?? px >= 11;
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(r);
    // Lines stay at least ~.9 px at tiny sizes.
    final w = math.max(.085, .95 / math.max(px, 1e-3));
    final a = alpha;
    if (disc) {
      c.drawCircle(const Offset(0, .06), 1.1, _fill(_ink, .28 * a));
      c.drawCircle(
        Offset.zero,
        1,
        NeferhooStaging.grad(
          NeferhooStaging.once(
            'emblem-disc',
            () => _rad(const Offset(-.32, -.4), 1.25, const [
              Color(0xff5b80f2),
              NeferhooPalette.lapis,
              NeferhooPalette.lapisShade,
              NeferhooPalette.lapisDeep,
            ], const [0, .35, .72, 1]),
          ),
          a,
        ),
      );
      if (fine) {
        // An inner gold hairline and a faint sunburst behind the head.
        c.drawCircle(Offset.zero, .84, _line(NeferhooPalette.goldLit, .035, .55 * a));
        c.drawPath(
          NeferhooStaging.once('emblem-rays', () {
            final rays = Path();
            for (var k = 0; k < 12; k++) {
              final an = k * math.pi / 6 + .2;
              rays
                ..moveTo(math.cos(an) * .5, math.sin(an) * .5)
                ..lineTo(math.cos(an) * .8, math.sin(an) * .8);
            }
            return rays;
          }),
          _line(NeferhooPalette.lapisLit, .05, .22 * a),
        );
      }
      c.drawCircle(Offset.zero, 1, _line(NeferhooPalette.goldLit, .17, a));
      c.drawCircle(Offset.zero, 1.085, _line(_ink, w, a));
      c.drawCircle(Offset.zero, .915, _line(NeferhooPalette.goldDeep, .05, .8 * a));
    }
    if (crest) {
      final fan = _fan();
      for (final (root, d, _, len, path) in fan.feathers) {
        c.drawPath(
          path,
          NeferhooStaging.grad(
            NeferhooStaging.once(
              ('emblem-feather', len),
              () => _lin(root, root + d * len, const [
                NeferhooPalette.cinnShade,
                NeferhooPalette.cinn,
                NeferhooPalette.cinnLit,
              ]),
            ),
            a,
          ),
        );
      }
      final bands = Path(), tips = Path();
      for (final (root, d, n, len, _) in fan.feathers) {
        final b0 = root + d * len * .72 - n * .17, b1 = root + d * len * .72 + n * .17;
        bands
          ..moveTo(b0.dx, b0.dy)
          ..lineTo(b1.dx, b1.dy);
        final t0 = root + d * len * .82, t1 = root + d * len;
        tips
          ..moveTo(t0.dx, t0.dy)
          ..lineTo(t1.dx, t1.dy);
      }
      c.drawPath(bands, _line(NeferhooPalette.barWhite, .055, .95 * a)..strokeCap = StrokeCap.butt);
      c.drawPath(tips, _line(NeferhooPalette.barBlack, .12, a)..strokeCap = StrokeCap.butt);
      c.drawPath(fan.union, _line(_ink, w * .62, a));
    }
    // The nemes lappet behind the face: gold with lapis stripes.
    c.drawPath(
      _nemes,
      NeferhooStaging.grad(
        NeferhooStaging.once(
          'emblem-nemes',
          () => _lin(const Offset(0, -.5), const Offset(.6, .6), const [
            NeferhooPalette.goldLit,
            NeferhooPalette.gold,
            NeferhooPalette.goldShade,
          ]),
        ),
        a,
      ),
    );
    c.save();
    c.clipPath(_nemes);
    c.drawPath(
      NeferhooStaging.once('emblem-stripes', () {
        final p = Path();
        for (var k = 0; k < 4; k++) {
          p
            ..moveTo(-.1, -.38 + k * .26)
            ..lineTo(.8, -.16 + k * .26);
        }
        return p;
      }),
      _line(NeferhooPalette.lapis, .1, a)..strokeCap = StrokeCap.butt,
    );
    c.restore();
    c.drawPath(_nemes, _line(_ink, w * .85, a));
    // The face plate, with the lapis brow band.
    c.drawPath(
      _face,
      NeferhooStaging.grad(
        NeferhooStaging.once(
          'emblem-face',
          () => _lin(const Offset(-.55, -.6), const Offset(.2, .55), const [
            NeferhooPalette.goldHi,
            NeferhooPalette.goldLit,
            NeferhooPalette.gold,
            NeferhooPalette.goldShade,
          ], const [0, .25, .65, 1]),
        ),
        a,
      ),
    );
    c.save();
    c.clipPath(_face);
    c.drawLine(const Offset(-.7, -.44), const Offset(.3, -.52), _line(NeferhooPalette.lapis, .1, a));
    c.restore();
    c.drawPath(_face, _line(_ink, w, a));
    // The beak: long, slim, decurved, leaving the circle at the lower left.
    c.drawPath(
      _beak,
      NeferhooStaging.grad(
        NeferhooStaging.once(
          'emblem-beak',
          () => _lin(const Offset(-.45, -.3), const Offset(-1.5, .66), const [
            NeferhooPalette.goldLit,
            NeferhooPalette.gold,
            NeferhooPalette.goldShade,
          ]),
        ),
        a,
      ),
    );
    c.drawLine(const Offset(-1.5, .66), const Offset(-1.28, .34), _line(NeferhooPalette.barBlack, .13, a));
    c.drawPath(_beak, _line(_ink, w * .9, a));
    c.drawLine(const Offset(-.66, -.2), const Offset(-.98, -.12), _line(const Color(0xffffffff), .05, .55 * a));
    // The eye with its kohl wing.
    c.drawPath(_kohl, _fill(_ink, a));
    c.drawPath(_almond, _fill(const Color(0xfffffdf6), a));
    c.drawCircle(
      const Offset(-.22, -.14),
      .105,
      _fill(Color.lerp(_ink, NeferhooPalette.magic, glow.clamp(0.0, 1.0))!, a),
    );
    c.drawCircle(const Offset(-.25, -.17), .04, _fill(const Color(0xffffffff), a));
    c.drawPath(_almond, _line(_ink, w * .7, a));
    if (glow > 0) {
      c.drawCircle(const Offset(-.22, -.14), .42, _fill(NeferhooPalette.magic, .22 * glow * a));
    }
    if (fine) {
      // The broad collar's top rows peeking under the chin.
      for (var k = 0; k < 3; k++) {
        final col = const [NeferhooPalette.turq, NeferhooPalette.gold, NeferhooPalette.carn][k];
        c.drawArc(
          Rect.fromCircle(center: const Offset(-.05, .02), radius: .6 + k * .1),
          .5,
          1.9,
          false,
          _line(col, .075, a)..strokeCap = StrokeCap.butt,
        );
      }
    }
    c.restore();
  }

  /// The round medallion (the strip's crest, the card's badge, the map's
  /// shield): the [emblem] on its lapis disc in a gold bezel, with a ring of
  /// beads at sizes where they read.
  static void medallion(Canvas c, Offset o, double r, {double alpha = 1, double glow = 0}) {
    if (alpha <= 0 || !(r > 0) || !o.isFinite) return;
    emblem(c, o, r, glow: glow, alpha: alpha);
    if (r >= 11) {
      c.save();
      c.translate(o.dx, o.dy);
      c.scale(r);
      c.drawPath(
        NeferhooStaging.once('medallion-beads', () {
          final beads = Path();
          for (var k = 0; k < 20; k++) {
            final a = k * math.pi / 10;
            beads.addOval(Rect.fromCircle(center: Offset(math.cos(a), math.sin(a)), radius: .045));
          }
          return beads;
        }),
        _fill(NeferhooPalette.goldHi, .8 * alpha),
      );
      c.restore();
    }
  }

  /// The strip's medallion at [center], [r] its radius, [u] the strip's
  /// unit: his mask on lapis, the eye lit turquoise in [fury]; dimmed a
  /// little once [defeated]. Replayed from a picture recorded once per size.
  static void crest(
    Canvas c,
    Offset center,
    double r,
    double u, {
    required bool fury,
    bool defeated = false,
    double time = 0,
    bool reduced = false,
  }) {
    if (!center.isFinite || !(r > 0)) return;
    final glow = fury && !defeated ? 1.0 : 0.0;
    c.save();
    c.translate(center.dx, center.dy);
    c.drawPicture(
      NeferhooStaging.picture(
        ('hud-crest', (r * 4).round(), glow),
        (p) => medallion(p, Offset.zero, r, glow: glow),
      ),
    );
    c.restore();
    if (fury && !defeated) {
      // His magic's ring round the bezel.
      c.drawCircle(center, r + 1.3 * u, _line(NeferhooPalette.magic, 1.2 * u, .55));
    }
  }

  // ---------------------------------------------------------- the plate --

  /// The plate's geometry from the shared strip (the shared layout's own
  /// sums: crest, name field, numbers).
  static ({Offset crest, double crestR, double nameLeft, double nameW}) _geo(Rect s, double u) {
    final crestR = 7.5 * u;
    final crest = Offset(s.left + 3.5 * u + crestR, s.center.dy);
    return (crest: crest, crestR: crestR, nameLeft: crest.dx + crestR + 5 * u, nameW: 84 * u);
  }

  /// The plate under everything on the strip: the drop shadow, the lapis,
  /// the wave line and the reed frieze, the burnished gold rim, the name's
  /// cartouche with its tie bar and the studs at the right end; in [fury] a
  /// turquoise glow round it. One recorded picture per layout and state.
  /// [flash] lights the rim (a hit, the fury's onset, growing stronger).
  static void frame(
    Canvas c,
    Rect strip,
    Rect bar,
    double u, {
    required bool fury,
    bool defeated = false,
    double wave = .5,
    double flash = 0,
    double time = 0,
    bool reduced = false,
  }) {
    if (!strip.isFinite || !bar.isFinite || !(u > 0)) return;
    c.drawPicture(
      NeferhooStaging.picture(
        ('hud-plate', strip, bar, (u * 100).round(), fury),
        (p) => _plate(p, strip, bar, u, fury),
      ),
    );
    final plate = RRect.fromRectAndRadius(strip, Radius.circular(11 * u));
    if (fury && !defeated) {
      // The glow breathes with the shared wave.
      c.drawRRect(plate.inflate(1.6 * u), _line(NeferhooPalette.magic, 1.6 * u, .2 + .25 * wave));
    }
    if (flash > 0) {
      c.drawRRect(plate.deflate(1 * u), _line(NeferhooPalette.goldHi, 1.7 * u, flash));
    }
    if (defeated) {
      c.drawRRect(plate, _fill(NeferhooStaging.night, .28));
    }
  }

  static void _plate(Canvas c, Rect s, Rect bar, double u, bool fury) {
    final g = _geo(s, u);
    final plate = RRect.fromRectAndRadius(s, Radius.circular(11 * u));
    c.drawRRect(plate.shift(Offset(0, 1.6 * u)), _fill(const Color(0xff0f1330), .32));
    if (fury) c.drawRRect(plate.inflate(1.6 * u), _line(NeferhooPalette.magic, 2.2 * u, .35));
    c.drawRRect(
      plate,
      Paint()
        ..shader = _lin(s.topCenter, s.bottomCenter, const [
          Color(0xff4b73ef),
          NeferhooPalette.lapis,
          NeferhooPalette.lapisShade,
          NeferhooPalette.lapisDeep,
        ], const [0, .3, .68, 1]),
    );
    // A lit upper edge, the wave line along the top and the reed frieze.
    c.drawRRect(plate.deflate(2.2 * u), _line(const Color(0xffffffff), .8 * u, .12));
    final waves = Path();
    final wy = s.top + 3.4 * u;
    var x = g.nameLeft + 4 * u;
    waves.moveTo(x, wy);
    while (x < s.right - 14 * u) {
      waves
        ..relativeLineTo(1.5 * u, -1.1 * u)
        ..relativeLineTo(1.5 * u, 1.1 * u);
      x += 3 * u;
    }
    c.drawPath(waves, _line(NeferhooPalette.lapisLit, .7 * u, .5));
    final frieze = Path();
    for (var fx = g.nameLeft + 2 * u; fx < s.right - 12 * u; fx += 4.6 * u) {
      frieze
        ..moveTo(fx - .7 * u, s.bottom - 2.4 * u)
        ..lineTo(fx, s.bottom - 4.1 * u)
        ..lineTo(fx + .7 * u, s.bottom - 2.4 * u)
        ..close();
    }
    c.drawPath(frieze, _fill(NeferhooPalette.goldLit, .62));
    // The burnished gold rim with a lapis-deep groove inside it.
    c.drawRRect(
      plate.deflate(1 * u),
      Paint()
        ..shader = _lin(s.topLeft, s.bottomRight, const [
          NeferhooPalette.goldHi,
          NeferhooPalette.gold,
          NeferhooPalette.goldShade,
          NeferhooPalette.gold,
          NeferhooPalette.goldLit,
        ], const [0, .22, .55, .8, 1])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7 * u,
    );
    c.drawRRect(plate.deflate(2.15 * u), _line(NeferhooPalette.lapisDeep, .6 * u, .85));
    c.drawRRect(plate, _line(_ink, 1 * u, .9));
    // The name's cartouche: a pill with the tie bar at its end.
    final cart = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        g.crest.dx + g.crestR + 3.4 * u,
        s.center.dy - 7.2 * u,
        g.nameLeft + g.nameW + 1 * u,
        s.center.dy + 7.2 * u,
      ),
      Radius.circular(7.2 * u),
    );
    c.drawRRect(cart, _fill(NeferhooPalette.lapisDeep, .55));
    c.drawRRect(cart, _line(NeferhooPalette.goldLit, .95 * u, .9));
    c.drawRRect(cart.deflate(1.2 * u), _line(_ink, .5 * u, .35));
    final tie = RRect.fromRectAndRadius(
      Rect.fromLTRB(cart.right + 1.2 * u, s.center.dy - 8.6 * u, cart.right + 2.9 * u, s.center.dy + 8.6 * u),
      Radius.circular(.8 * u),
    );
    c.drawRRect(
      tie,
      Paint()
        ..shader = _lin(tie.outerRect.topLeft, tie.outerRect.bottomRight, const [
          NeferhooPalette.goldHi,
          NeferhooPalette.gold,
          NeferhooPalette.goldShade,
        ]),
    );
    c.drawRRect(tie, _line(_ink, .55 * u, .9));
    // Two gold studs on the rim at the right end.
    for (final dy in const [-1.0, 1.0]) {
      c.drawCircle(Offset(s.right - 5 * u, s.center.dy + dy * 4.2 * u), .9 * u, _fill(NeferhooPalette.goldLit, .9));
    }
  }

  // ---------------------------------------------------------- the gauge --

  /// The gauge's recessed lapis track in [bar]. Always drawn (true): the
  /// shared track never shows under his plate.
  static bool track(
    Canvas c,
    Rect bar,
    double u, {
    required bool fury,
    required bool defeated,
    double time = 0,
    bool reduced = false,
  }) {
    if (!bar.isFinite || !(u > 0)) return true;
    final br = RRect.fromRectAndRadius(bar.inflate(.4 * u), Radius.circular(5 * u));
    c.drawRRect(br.inflate(1 * u), _fill(_ink, .55));
    c.drawRRect(
      br,
      NeferhooStaging.grad(
        NeferhooStaging.once(
          ('hud-track', bar),
          () => _lin(bar.topCenter, bar.bottomCenter, const [Color(0xff0c1030), Color(0xff1a2150)]),
        ),
      ),
    );
    return true;
  }

  /// The gauge's fill in [bar] up to [right]: gold leaf (turquoise in
  /// [fury]) with a gloss on its upper third and a darker lower lip, ending
  /// in a torn papyrus edge while he is hurt ([edge]). [glow] (critical
  /// health) brightens it.
  static void fill(
    Canvas c,
    Rect bar,
    double right,
    double u, {
    required bool fury,
    double glow = 0,
    bool edge = true,
  }) {
    if (!bar.isFinite || !right.isFinite || !(u > 0) || right <= bar.left) return;
    final r = Rect.fromLTRB(bar.left, bar.top, math.min(right, bar.right), bar.bottom);
    c.drawRect(
      r,
      NeferhooStaging.grad(
        NeferhooStaging.once(
          ('hud-fill', bar, fury),
          () => _lin(bar.topCenter, bar.bottomCenter, fury ? furyRamp : ramp, const [0, .45, 1]),
        ),
      ),
    );
    if (glow > 0) c.drawRect(r, _fill(fury ? NeferhooPalette.turqLit : NeferhooPalette.goldHi, glow));
    c.drawRect(Rect.fromLTRB(r.left, bar.top + .9 * u, r.right, bar.top + 2.4 * u), _fill(const Color(0xffffffff), .32));
    c.drawRect(
      Rect.fromLTRB(r.left, bar.bottom - 1.6 * u, r.right, bar.bottom),
      _fill(fury ? NeferhooPalette.turqShade : NeferhooPalette.goldDeep, .35),
    );
    if (edge) {
      // A torn papyrus edge at the fill's end.
      final te = Path()..moveTo(r.right - 3.2 * u, bar.top);
      for (var k = 0; k < 5; k++) {
        te.lineTo(r.right + (k.isEven ? 1.6 : -1.4) * u, bar.top + (k + 1) * bar.height / 5);
      }
      te
        ..lineTo(r.right - 3.2 * u, bar.bottom)
        ..close();
      c.drawPath(te, _fill(NeferhooPalette.papyrusHi, .95));
    }
  }

  /// The fury mark at [share] of [bar]: a carnelian wax seal in a gold ring,
  /// stamped with a winged envelope, standing a little proud of the track
  /// while he is [above] it; once he is in [fury] it splits down the middle,
  /// the halves pushed apart, turquoise light leaking from the gap (the split
  /// opens over 0.3 s after the onset, [furyAge]; at once under Reduced
  /// Motion). Beaten, the halves stay apart and the light is out.
  static void seal(
    Canvas c,
    Rect bar,
    double u, {
    required bool above,
    required bool fury,
    double furyAge = double.infinity,
    bool defeated = false,
    bool reduced = false,
    double share = 1 / 3,
  }) {
    if (!bar.isFinite || !(u > 0)) return;
    final o = Offset(bar.left + bar.width * share, bar.center.dy - (above ? .6 * u : 0));
    final r = 3.9 * u;
    c.drawCircle(o + Offset(0, .5 * u), r + .9 * u, _fill(_ink, .5));
    if (!fury && !defeated) {
      c.drawCircle(
        o,
        r + .8 * u,
        Paint()..shader = _lin(o - Offset(r, r), o + Offset(r, r), const [NeferhooPalette.goldHi, NeferhooPalette.gold, NeferhooPalette.goldShade]),
      );
      c.drawCircle(
        o,
        r,
        Paint()..shader = _rad(o - Offset(r * .3, r * .35), r * 1.3, const [NeferhooPalette.carnLit, NeferhooPalette.carn, NeferhooPalette.carnShade]),
      );
      c.drawCircle(o, r + .8 * u, _line(_ink, .6 * u, .9));
      // The winged envelope stamped in the wax.
      final e = Rect.fromCenter(center: o, width: r, height: r * .68);
      c.drawRect(e, _fill(NeferhooPalette.carnDeep, .85));
      c.drawPath(
        Path()
          ..moveTo(e.left, e.top)
          ..lineTo(e.center.dx, e.center.dy)
          ..lineTo(e.right, e.top),
        _line(NeferhooPalette.carnLit, .4 * u, .9),
      );
      return;
    }
    final open = defeated || reduced || !furyAge.isFinite ? 1.0 : NeferhooStaging.outBack(furyAge / .3, 2.2);
    final lit = defeated ? 0.0 : 1.0;
    if (lit > 0) {
      // Turquoise light leaks from the split: a glow, a wedge, a spark.
      c.drawCircle(o, r + 3.2 * u, _fill(NeferhooPalette.magic, .26 * open));
      c.drawCircle(o, r + 1.8 * u, _fill(NeferhooPalette.magic, .3 * open));
      final pivot = Offset(o.dx, o.dy + r * .9);
      c.drawPath(
        Path()
          ..moveTo(pivot.dx, pivot.dy)
          ..lineTo(o.dx - 2.4 * u * open, o.dy - r - 1.6 * u)
          ..lineTo(o.dx + 2.4 * u * open, o.dy - r - 1.6 * u)
          ..close(),
        _fill(NeferhooPalette.turqLit, open),
      );
    }
    final pivot = Offset(o.dx, o.dy + r * .9);
    final rect = Rect.fromCircle(center: o, radius: r);
    for (final s in const [-1.0, 1.0]) {
      c.save();
      c.translate(pivot.dx, pivot.dy);
      c.rotate(s * .2 * open);
      c.translate(-pivot.dx, -pivot.dy);
      final start = s < 0 ? math.pi / 2 : -math.pi / 2;
      final half = Path()
        ..addArc(rect, start, math.pi)
        ..close();
      final ring = Path()
        ..addArc(rect.inflate(.8 * u), start, math.pi)
        ..close();
      c.drawPath(ring, Paint()..shader = _lin(o - Offset(r, r), o + Offset(r, r), const [NeferhooPalette.goldHi, NeferhooPalette.gold, NeferhooPalette.goldShade]));
      c.drawPath(half, Paint()..shader = _rad(o + Offset(-r * .3, -r * .35), r * 1.3, const [NeferhooPalette.carnLit, NeferhooPalette.carn, NeferhooPalette.carnShade]));
      c.drawPath(ring, _line(_ink, .6 * u, .9));
      c.restore();
    }
    if (lit > 0) {
      c.drawLine(
        Offset(o.dx, o.dy - r - 2.6 * u),
        Offset(o.dx, o.dy - r - 4 * u),
        _line(NeferhooPalette.turqLit, .8 * u, open),
      );
    }
  }

  /// The colours the shared numbers take on his plate (light on lapis): the
  /// hit points in gold (turquoise in fury) and the maximum in pale lapis.
  static const numbers = (gold: NeferhooPalette.goldHi, fury: NeferhooPalette.turqLit, max: Color(0xffb7c8ff));

  /// The name's carved edge on the lapis cartouche.
  static const nameShadow = NeferhooPalette.lapisDeep;
}
