import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'dusk_moth_boss_rig.dart' show DuskMothBossRig;
import 'dusk_moth_kit.dart';
import 'dusk_moth_pose.dart';

/// The Dusk Empress's four wings: a falcate forewing with a hooked apex and a
/// luna-tailed hindwing on each side, spread behind her body like a royal
/// cape. Velvet rose at the shoulder deepens through wine to midnight violet,
/// edged in pearl lace and lit by moon eyespots. Fury ignites the veins,
/// hems and eyespots to ember.
///
/// Everything is authored in the rig's hit-radius units, in the body frame.
/// A wing beats about its own root, so the forewing lifts and the hindwing
/// and tails ripple a beat behind it.
abstract final class DuskMothWingArt {
  static const _ink = DuskMothBossRig.ink;
  static const _pearl = DuskMothBossRig.pearl;
  static const _silk = DuskMothBossRig.silk;
  static const _coral = DuskMothBossRig.coral;
  static const _rose = DuskMothBossRig.rose;
  static const _pollen = DuskMothBossRig.pollen;
  static const _veil = DuskMothBossRig.veil;
  static const _ember = DuskMothBossRig.ember;

  // The velvet ramp, shoulder to hem.
  static const _hot = Color(0xffe0708a), _velvet = Color(0xffb6466e);
  static const _wine = Color(0xff7c3263), _violet = DuskMothBossRig.violet;
  static const _night = DuskMothBossRig.night;
  static const _hotFury = Color(0xfff28a62), _velvetFury = Color(0xffd44a5c);
  static const _wineFury = Color(0xff8e2c54), _violetFury = Color(0xff5c2a6c);
  static const _flame = DuskMothBossRig.flame;

  // The wings are a touch smaller than their authored size, so the body
  // stays the heart of the silhouette.
  static const _size = .9;
  static const _foreRoot = Offset(.02, -.2), _hindRoot = Offset(.0, .05);

  // Wing shapes, clockwise on screen.
  static const _foreOutline = <Offset>[
    Offset(.02, -.18),
    Offset(-.2, -.7),
    Offset(-.04, -1.3),
    Offset(.4, -1.86),
    Offset(1.0, -2.22),
    Offset(1.66, -2.34),
    Offset(2.52, -2.0),
    Offset(2.04, -1.86),
    Offset(1.76, -1.55),
    Offset(1.9, -1.2),
    Offset(1.84, -.8),
    Offset(1.56, -.52),
    Offset(1.1, -.32),
    Offset(.6, -.14),
    Offset(.24, -.06),
  ];
  static const _foreSharp = {0, 6};
  static const _hindOutline = <Offset>[
    Offset(.0, .02),
    Offset(.5, -.02),
    Offset(1.05, .0),
    Offset(1.6, .14),
    Offset(1.95, .5),
    Offset(2.02, .92),
    Offset(1.9, 1.3),
    Offset(1.55, 1.22),
    Offset(1.1, 1.06),
    Offset(.62, .84),
    Offset(.24, .5),
  ];
  static const _hindSharp = {0, 6, 7};

  static final _fore = DuskMothKit.spline(_foreOutline, sharp: _foreSharp);
  static final _hind = DuskMothKit.spline(_hindOutline, sharp: _hindSharp);
  // The pearl costa, and the scalloped hems along the outer margins.
  static final _foreCosta = DuskMothKit.spline(
    _foreOutline,
    sharp: _foreSharp,
    from: 0,
    to: 6,
  );
  static final _foreMargin = DuskMothKit.spline(
    _foreOutline,
    sharp: _foreSharp,
    from: 6,
    to: 11,
  );
  static final _hindMargin = DuskMothKit.spline(
    _hindOutline,
    sharp: _hindSharp,
    from: 2,
    to: 6,
  );
  static final _foreLace = DuskMothKit.lace(
    _foreMargin,
    size: .24,
    depth: .085,
  );
  static final _hindLace = DuskMothKit.lace(
    _hindMargin,
    size: .24,
    depth: .085,
  );
  static final _foreBand = _zigzag(_foreMargin, inset: .5, amp: .035);
  static final _hindBand = _zigzag(_hindMargin, inset: .36, amp: .03);

  // Translucent windows, like the panes in an atlas moth's wings.
  static final _foreWindow = DuskMothKit.spline(
    const [
      Offset(1.24, -1.6),
      Offset(1.46, -1.9),
      Offset(1.86, -2.1),
      Offset(1.74, -1.82),
      Offset(1.6, -1.56),
      Offset(1.4, -1.46),
    ],
    sharp: const {2},
  );
  static final _hindWindow = DuskMothKit.spline(const [
    Offset(1.5, .3),
    Offset(1.76, .42),
    Offset(1.86, .72),
    Offset(1.7, .98),
    Offset(1.56, .78),
    Offset(1.48, .52),
  ]);

  static final _foreWindowBounds = _foreWindow.getBounds();
  static final _hindWindowBounds = _hindWindow.getBounds();

  // Veins fan from each shoulder to the margin.
  static const _foreVeins = <Offset>[
    Offset(1.0, -2.3),
    Offset(1.7, -2.2),
    Offset(2.15, -1.6),
    Offset(2.1, -1.05),
    Offset(2.05, -.6),
    Offset(1.8, -.15),
    Offset(1.2, -.05),
  ];
  static const _hindVeins = <Offset>[
    Offset(1.5, -.05),
    Offset(2.1, .45),
    Offset(2.2, .95),
    Offset(1.9, 1.5),
    Offset(1.3, 1.55),
    Offset(.7, 1.2),
  ];
  static final _foreVeinPath = _veinPath(_foreRoot, _foreVeins);
  static final _hindVeinPath = _veinPath(_hindRoot, _hindVeins);

  // Dust and a few twilight stars, fixed by hash so every frame matches.
  static final _foreDust = _dust(
    1,
    90,
    const Rect.fromLTRB(.1, -2.2, 2.1, -.05),
  );
  static final _hindDust = _dust(
    2,
    60,
    const Rect.fromLTRB(.1, -.05, 2.1, 1.45),
  );
  static final _foreStars = _stars(
    3,
    9,
    const Rect.fromLTRB(.7, -2.05, 2.0, -.4),
  );
  static final _hindStars = _stars(4, 6, const Rect.fromLTRB(.9, .1, 2.0, 1.3));

  // A soft diagonal sheen, as light slides over velvet.
  static final _foreSheen = Path()
    ..moveTo(.02, -.6)
    ..quadraticBezierTo(.5, -1.6, 1.3, -2.04);
  static final _hindSheen = Path()
    ..moveTo(.4, .12)
    ..quadraticBezierTo(1.3, .2, 1.85, .84);

  static Path _veinPath(Offset root, List<Offset> ends) {
    final path = Path();
    for (final end in ends) {
      final d = end - root;
      final bow = Offset(-d.dy, d.dx) * .07;
      final mid = root + d * .5 + bow;
      path
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
      // A short fork before the margin.
      final fork = root + d * .66 + bow * .7;
      final off = Offset(-d.dy, d.dx) * .13;
      path
        ..moveTo(fork.dx, fork.dy)
        ..quadraticBezierTo(
          fork.dx + d.dx * .18 + off.dx,
          fork.dy + d.dy * .18 + off.dy,
          end.dx + off.dx * .8,
          end.dy + off.dy * .8,
        );
    }
    return path;
  }

  static Path _dust(int seed, int count, Rect area) {
    final path = Path();
    for (var i = 0; i < count; i++) {
      final at = Offset(
        area.left + area.width * DuskMothKit.hash(seed * 1000 + i * 3),
        area.top + area.height * DuskMothKit.hash(seed * 1000 + i * 3 + 1),
      );
      final r = .009 + .02 * DuskMothKit.hash(seed * 1000 + i * 3 + 2);
      path.addOval(Rect.fromCircle(center: at, radius: r));
    }
    return path;
  }

  static Path _stars(int seed, int count, Rect area) {
    final path = Path();
    for (var i = 0; i < count; i++) {
      final at = Offset(
        area.left + area.width * DuskMothKit.hash(seed * 77 + i * 3),
        area.top + area.height * DuskMothKit.hash(seed * 77 + i * 3 + 1),
      );
      path.addPath(
        DuskMothKit.star(
          at,
          .035 + .04 * DuskMothKit.hash(seed * 77 + i * 3 + 2),
        ),
        Offset.zero,
      );
    }
    return path;
  }

  /// A wavy pearl band that follows [edge], [inset] inside it.
  static Path _zigzag(Path edge, {required double inset, required double amp}) {
    final points = <Offset>[];
    for (final metric in edge.computeMetrics()) {
      final steps = (metric.length / .2).round();
      for (var i = 0; i <= steps; i++) {
        final t = metric.getTangentForOffset(metric.length * i / steps)!;
        final inward = Offset(-t.vector.dy, t.vector.dx);
        points.add(t.position + inward * (inset + (i.isOdd ? amp : -amp)));
      }
    }
    return DuskMothKit.spline(points, closed: false);
  }

  /// One side's forewing and hindwing. The far pair sits behind the near
  /// one, darker and turned up and back, so four wing tips fan out behind the
  /// queen.
  static void paint(Canvas c, DuskMothPose p, {required bool far}) {
    _hindWing(c, p, far: far);
    _foreWing(c, p, far: far);
  }

  // ----------------------------------------------------------------- motes --

  // Where the wing dust and embers leave the wings, in the body frame.
  static const _sources = <Offset>[
    Offset(1.75, -1.7),
    Offset(1.85, -1.15),
    Offset(1.7, -.62),
    Offset(1.5, -.3),
    Offset(1.9, .55),
    Offset(1.85, 1.1),
    Offset(1.3, .95),
    Offset(2.3, 1.6),
    Offset(1.2, -1.9),
    Offset(2.0, -1.5),
  ];

  /// Twilight dust that sifts from her wings and sinks away on the air; in
  /// fury it turns to embers that rise. Under Reduced Motion the same motes
  /// hang still, so the fury is still readable.
  static void motes(Canvas c, DuskMothPose p) {
    final fury = p.fury;
    final count = fury > 0 ? _sources.length : 6;
    final speed = fury > 0 ? .5 : .16;
    for (var i = 0; i < count; i++) {
      final seed = DuskMothKit.hash(300 + i);
      final phase = (p.time * speed + seed + i * .137) % 1.0;
      final at = _sources[i];
      final drift = fury > 0
          ? Offset(.18 * phase + .05 * math.sin(phase * 9 + i), -.85 * phase)
          : Offset(.3 * phase + .06 * math.sin(phase * 5 + i), .7 * phase);
      final fade = math.sin(phase * math.pi);
      final r =
          (.02 + .022 * DuskMothKit.hash(320 + i)) *
          (fury > 0 ? 1 - phase * .5 : 1);
      final pos = at + drift;
      if (fury > 0) {
        DuskMothKit.glow(c, pos, r * 4, _flame, .35 * fade);
        c.drawCircle(
          pos,
          r,
          DuskMothKit.fill(
            Color.lerp(_pollen, _ember, phase)!.withValues(alpha: .95 * fade),
          ),
        );
      } else {
        c.drawPath(
          DuskMothKit.star(pos, r * 1.6, waist: .3),
          DuskMothKit.fill(_pearl.withValues(alpha: .7 * fade)),
        );
      }
    }
  }

  // ------------------------------------------------------------ transforms --

  static void _place(
    Canvas c,
    DuskMothPose p, {
    required Offset root,
    required double angle,
    required double stretch,
    required bool far,
    Offset shift = Offset.zero,
  }) {
    final flare = 1 + p.roar * .07;
    final fold = p.fold;
    final size = _size * (1 - p.shelter) * flare * (far ? .93 : 1);
    c.translate(
      root.dx + shift.dx + (far ? .1 : 0),
      root.dy + shift.dy + (far ? -.1 : 0),
    );
    c.rotate(angle);
    c.scale((1 - fold * .14) * size, stretch * (1 - fold * .3) * size);
    c.translate(-root.dx, -root.dy);
  }

  static void _foreWing(Canvas c, DuskMothPose p, {required bool far}) {
    final raise = p.raise(far ? .55 : 0);
    c.save();
    _place(
      c,
      p,
      root: _foreRoot,
      angle:
          -raise * .3 +
          .02 +
          p.fold * .95 -
          p.recoil * .07 -
          p.summon * .08 -
          p.jolt * .05 +
          (far ? .32 - p.roar * .05 : 0),
      stretch: .7 + .3 * (raise + 1) / 2,
      far: far,
    );
    final tone = p.tone;
    final hem = tone.burn(_pearl, const Color(0xffffb98a));
    // Fury's ember light spills outside the ink like heat off the margin.
    if (!far && p.fury > 0) {
      for (var i = 0; i < 3; i++) {
        c.drawPath(
          _fore,
          DuskMothKit.line(
            _flame.withValues(alpha: p.fury * (.12 + i * .07)),
            .5 - i * .14,
          ),
        );
      }
    }
    c.drawPath(_fore, DuskMothKit.line(_ink, far ? .13 : .16));
    c.drawPath(_fore, _velvetPaint(tone, far, _foreRoot, 3.1));
    c.save();
    c.clipPath(_fore);
    _velvetFinish(c, _fore, _foreRoot, tone, far: far);
    // Wing scales.
    c.drawPath(
      _foreDust,
      DuskMothKit.fill(_pearl.withValues(alpha: far ? .12 : .3)),
    );
    if (!far) {
      // The sheen slides over the velvet with each stroke.
      c.save();
      c.translate(raise * .14, -raise * .06);
      c.drawPath(
        _foreSheen,
        DuskMothKit.line(_pearl.withValues(alpha: .09), .5),
      );
      c.drawPath(
        _foreSheen,
        DuskMothKit.line(_pearl.withValues(alpha: .1), .14),
      );
      c.restore();
      _halo(c, const Offset(1.06, -1.16), .46, p);
      _window(c, _foreWindow, _foreWindowBounds, tone);
      c.drawPath(_foreStars, DuskMothKit.fill(_pearl.withValues(alpha: .8)));
      _veins(c, _foreVeinPath, tone, far: false);
      _band(c, _foreBand, tone);
      // The pearl costa, with a coral thread inside it.
      c.drawPath(_foreCosta, DuskMothKit.line(hem, .21));
      c.save();
      c.translate(.06, .07);
      c.drawPath(
        _foreCosta,
        DuskMothKit.line(tone.burn(_rose, _flame).withValues(alpha: .75), .03),
      );
      c.restore();
      _lace(c, _foreLace, tone);
    } else {
      _veins(c, _foreVeinPath, tone, far: true);
      c.drawPath(_foreCosta, DuskMothKit.line(_rose.withValues(alpha: .8), .1));
      c.drawPath(
        _foreMargin,
        DuskMothKit.line(_rose.withValues(alpha: .8), .1),
      );
    }
    c.restore();
    if (!far) {
      _moon(c, const Offset(1.06, -1.16), .46, -.5, p);
    }
    c.restore();
  }

  static void _hindWing(Canvas c, DuskMothPose p, {required bool far}) {
    final raise = p.raise((far ? .55 : 0) + .7);
    c.save();
    _place(
      c,
      p,
      root: _hindRoot,
      angle: .2 - raise * .2 - p.fold * .5 + p.recoil * .04 - (far ? .3 : 0),
      stretch: .8 + .2 * (raise + 1) / 2,
      far: far,
      shift: const Offset(0, .16),
    );
    final tone = p.tone;
    _tail(c, p, far: far, tone: tone);
    if (!far && p.fury > 0) {
      for (var i = 0; i < 3; i++) {
        c.drawPath(
          _hind,
          DuskMothKit.line(
            _flame.withValues(alpha: p.fury * (.12 + i * .07)),
            .5 - i * .14,
          ),
        );
      }
    }
    c.drawPath(_hind, DuskMothKit.line(_ink, far ? .13 : .16));
    c.drawPath(_hind, _velvetPaint(tone, far, _hindRoot, 2.5));
    c.save();
    c.clipPath(_hind);
    _velvetFinish(c, _hind, _hindRoot, tone, far: far);
    c.drawPath(
      _hindDust,
      DuskMothKit.fill(_pearl.withValues(alpha: far ? .12 : .3)),
    );
    if (!far) {
      c.save();
      c.translate(raise * .12, raise * .05);
      c.drawPath(
        _hindSheen,
        DuskMothKit.line(_pearl.withValues(alpha: .08), .4),
      );
      c.restore();
      _halo(c, const Offset(1.1, .68), .34, p);
      _window(c, _hindWindow, _hindWindowBounds, tone);
      c.drawPath(_hindStars, DuskMothKit.fill(_pearl.withValues(alpha: .8)));
      _veins(c, _hindVeinPath, tone, far: false);
      _band(c, _hindBand, tone);
      _lace(c, _hindLace, tone);
    } else {
      _veins(c, _hindVeinPath, tone, far: true);
      c.drawPath(
        _hindMargin,
        DuskMothKit.line(_rose.withValues(alpha: .8), .1),
      );
    }
    c.restore();
    if (!far) {
      _moon(c, const Offset(1.1, .68), .34, .5, p);
    }
    c.restore();
  }

  // ---------------------------------------------------------------- velvet --

  static Paint _velvetPaint(
    DuskTone tone,
    bool far,
    Offset root,
    double radius,
  ) {
    final colors = far
        ? [
            tone.lit(const Color(0xff7a3560)),
            tone.lit(const Color(0xff55305f)),
            tone.lit(const Color(0xff3a2a66)),
            tone.lit(const Color(0xff2a2052)),
          ]
        : [
            tone.burn(_hot, _hotFury),
            tone.burn(_velvet, _velvetFury),
            tone.burn(_wine, _wineFury),
            tone.burn(_violet, _violetFury),
            tone.lit(_night),
          ];
    return DuskMothKit.radial(
      root,
      radius,
      colors,
      far ? const [0, .4, .75, 1] : const [0, .26, .54, .82, 1],
    );
  }

  // Shading inside the wing: a contact shadow under the body, a lit upper
  // edge and a shaded lower one.
  static void _velvetFinish(
    Canvas c,
    Path outline,
    Offset root,
    DuskTone tone, {
    required bool far,
  }) {
    // The mantle shades the wing where it lies over the shoulder.
    c.drawCircle(
      root,
      .85,
      DuskMothKit.radial(root, .85, [
        _ink.withValues(alpha: far ? .25 : .3),
        _ink.withValues(alpha: 0),
      ]),
    );
    c.save();
    c.translate(.055, .06);
    c.drawPath(
      outline,
      DuskMothKit.line(_pearl.withValues(alpha: far ? .1 : .3), .11),
    );
    c.translate(-.11, -.12);
    c.drawPath(outline, DuskMothKit.line(_ink.withValues(alpha: .3), .16));
    c.restore();
  }

  static void _veins(Canvas c, Path veins, DuskTone tone, {required bool far}) {
    c.drawPath(
      veins,
      DuskMothKit.line(_ink.withValues(alpha: far ? .3 : .34), .07),
    );
    c.save();
    c.translate(-.012, -.014);
    c.drawPath(
      veins,
      DuskMothKit.line(_rose.withValues(alpha: far ? .3 : .55), .035),
    );
    c.restore();
    if (tone.fury > 0 && !far) {
      c.drawPath(
        veins,
        DuskMothKit.line(_flame.withValues(alpha: .55 * tone.fury), .085),
      );
      c.drawPath(
        veins,
        DuskMothKit.line(_ember.withValues(alpha: .95 * tone.fury), .05),
      );
      c.drawPath(
        veins,
        DuskMothKit.line(_pollen.withValues(alpha: .9 * tone.fury), .02),
      );
    }
  }

  static void _band(Canvas c, Path band, DuskTone tone) {
    c.drawPath(band, DuskMothKit.line(_ink.withValues(alpha: .4), .085));
    c.drawPath(
      band,
      DuskMothKit.line(
        tone.burn(_silk, const Color(0xffffb27a)).withValues(alpha: .85),
        .04,
      ),
    );
  }

  static void _lace(Canvas c, Path lace, DuskTone tone) {
    c.drawPath(
      lace,
      DuskMothKit.fill(tone.burn(_pearl, const Color(0xffffb98a))),
    );
    c.drawPath(lace, DuskMothKit.line(_ink.withValues(alpha: .5), .032));
    if (tone.fury > 0) {
      c.drawPath(
        lace,
        DuskMothKit.line(_ember.withValues(alpha: .7 * tone.fury), .05),
      );
    }
  }

  static void _window(Canvas c, Path window, Rect bounds, DuskTone tone) {
    c.drawPath(
      window,
      DuskMothKit.linear(bounds.topLeft, bounds.bottomRight, [
        Color.lerp(
          _pearl,
          _veil,
          .35 + tone.moon * .65,
        )!.withValues(alpha: .55),
        _veil.withValues(alpha: .14),
      ]),
    );
    // A glassy edge lights the upper left of the pane.
    c.save();
    c.clipPath(window);
    c.translate(.035, .035);
    c.drawPath(window, DuskMothKit.line(_pearl.withValues(alpha: .55), .05));
    c.restore();
    c.drawPath(window, DuskMothKit.line(_ink.withValues(alpha: .45), .03));
  }

  // -------------------------------------------------------------- eyespots --

  /// A glowing moon eyespot: ink ring, pearl ring, gold ring, a midnight
  /// disc holding a bright crescent and a gem, with a halo behind it.
  // The eyespot's halo, painted inside the wing's clip so it never spills
  // out onto the sky.
  static void _halo(Canvas c, Offset at, double r, DuskMothPose p) =>
      DuskMothKit.glow(
        c,
        at,
        r * 2.1,
        Color.lerp(Color.lerp(_pollen, _veil, p.moonlight)!, _flame, p.fury)!,
        (.34 + p.fury * .3) * (1 + p.sway(p.fury > 0 ? 9 : 2.6, .18)),
      );

  static void _moon(
    Canvas c,
    Offset at,
    double r,
    double tilt,
    DuskMothPose p,
  ) {
    final tone = p.tone;
    final fury = p.fury, moon = p.moonlight;
    final ring = Color.lerp(
      Color.lerp(_pearl, _veil, moon)!,
      const Color(0xffffb98a),
      fury,
    )!;
    final gold = Color.lerp(_pollen, _ember, fury)!;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(tilt);
    c.scale(1.12, 1);
    final disc = Rect.fromCircle(center: Offset.zero, radius: r);
    c.drawOval(disc.inflate(r * .08), DuskMothKit.fill(_ink));
    c.drawOval(
      disc,
      DuskMothKit.linear(disc.topLeft, disc.bottomRight, [
        tone.lit(ring),
        tone.lit(Color.lerp(ring, gold, .5)!),
      ]),
    );
    final inner = disc.deflate(r * .13);
    c.drawOval(
      inner,
      DuskMothKit.linear(inner.topLeft, inner.bottomRight, [
        tone.lit(Color.lerp(gold, _pearl, .3)!),
        tone.lit(Color.lerp(gold, _rose, .35 + fury * .2)!),
      ]),
    );
    final core = disc.deflate(r * .3);
    c.drawOval(
      core,
      DuskMothKit.radial(core.center, core.width * .6, [
        tone.lit(Color.lerp(const Color(0xff6b3f95), _flame, fury * .55)!),
        tone.lit(
          Color.lerp(
            const Color(0xff2f2360),
            const Color(0xff7a2a3f),
            fury * .7,
          )!,
        ),
      ]),
    );
    c.drawOval(core, DuskMothKit.line(_ink.withValues(alpha: .7), r * .06));
    // The moon: a bright crescent lit from the upper left.
    final moonColor = Color.lerp(
      Color.lerp(_pearl, _veil, moon)!,
      _pollen,
      fury * (1 - moon),
    )!;
    c.drawPath(
      DuskMothKit.crescent(const Offset(-.005, 0) * r, r * .34),
      DuskMothKit.fill(tone.lit(moonColor)),
    );
    final gem = Offset(r * .06, r * .05);
    c.drawCircle(
      gem,
      r * (.13 + p.charge * .04),
      DuskMothKit.fill(
        tone.lit(
          Color.lerp(Color.lerp(_coral, _ember, fury)!, _pollen, p.charge)!,
        ),
      ),
    );
    c.drawCircle(
      gem + Offset(-r * .04, -r * .04),
      r * .045,
      DuskMothKit.fill(_pearl),
    );
    c.restore();
  }

  // ------------------------------------------------------------------ tail --

  // The long luna tail: a ribbon that ends in a curled spatula and a pearl
  // drop, streaming a beat behind the wing.
  static void _tail(
    Canvas c,
    DuskMothPose p, {
    required bool far,
    required DuskTone tone,
  }) {
    final lag = p.raise((far ? .55 : 0) + 1.5);
    final flutter = p.sway(3.4, .05, far ? 1.3 : 0);
    Offset bend(int i) {
      final t = i / 4;
      final swing = (lag * .22 + flutter + p.recoil * .05) * t * t * 1.9;
      return Offset(swing - p.fold * .15 * t, -math.sin(t * math.pi) * 0);
    }

    const base = [
      Offset(1.72, 1.12),
      Offset(1.9, 1.42),
      Offset(2.2, 1.68),
      Offset(2.52, 1.84),
      Offset(2.76, 1.82),
    ];
    final center = [for (var i = 0; i < 5; i++) base[i] + bend(i)];
    final tail = DuskMothKit.ribbon(center, const [.34, .19, .13, .22, .19]);
    c.drawPath(tail, DuskMothKit.line(_ink, far ? .13 : .16));
    c.drawPath(
      tail,
      DuskMothKit.linear(
        center.first,
        center.last,
        far
            ? [
                tone.lit(const Color(0xff8e4270)),
                tone.lit(const Color(0xff4a2f78)),
              ]
            : [
                tone.burn(_velvet, _velvetFury),
                tone.burn(_wine, _wineFury),
                tone.burn(_violet, _violetFury),
              ],
      ),
    );
    if (far) {
      c.save();
      c.clipPath(tail);
      c.drawPath(tail, DuskMothKit.line(_rose.withValues(alpha: .85), .07));
      c.restore();
    }
    if (!far) {
      c.save();
      c.clipPath(tail);
      DuskMothKit.rim(
        c,
        tail,
        light: _pearl,
        shade: _ink,
        width: .1,
        alpha: .35,
      );
      // A pearl hem runs down both edges and a vein down the middle.
      c.drawPath(
        tail,
        DuskMothKit.line(tone.burn(_pearl, const Color(0xffffb98a)), .085),
      );
      final rib = DuskMothKit.spline(center, closed: false);
      c.drawPath(rib, DuskMothKit.line(_ink.withValues(alpha: .35), .05));
      c.drawPath(rib, DuskMothKit.line(_rose.withValues(alpha: .8), .022));
      c.restore();
    }
    final tip = center.last;
    c.drawCircle(tip, far ? .06 : .085, DuskMothKit.fill(_ink));
    c.drawCircle(
      tip,
      far ? .045 : .066,
      DuskMothKit.fill(
        far ? _rose : Color.lerp(_pearl, _veil, p.moonlight * .7)!,
      ),
    );
  }
}
