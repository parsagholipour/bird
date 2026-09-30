import 'package:flutter/painting.dart';

import 'dusk_moth_boss_rig.dart' show DuskMothBossRig;
import 'dusk_moth_kit.dart';

/// The lunar diadem, drawn around its seat on the head's crest.
///
/// The moth faces left, so the ring is seen from the side and a little above:
/// a narrow forehead plate at the left end carries a moon gem and a crescent
/// finial, a long curved band runs along the near side with a ruby and a
/// row of pearls, and the dark opening of the ring shows the far rim with
/// its prongs partly hidden behind the near ones.
///
/// It is pure paint with no clock, so it can be seated on the head and later
/// tumble away in the defeat looking exactly the same.
abstract final class DuskMothCrownArt {
  static const _ink = DuskMothBossRig.ink;
  static const _pearl = DuskMothBossRig.pearl;
  static const _silk = DuskMothBossRig.silk;
  static const _rose = DuskMothBossRig.rose;
  static const _plum = DuskMothBossRig.plum;
  static const _pollen = DuskMothBossRig.pollen;
  static const _veil = DuskMothBossRig.veil;
  static const _ember = DuskMothBossRig.ember;
  static const _goldShadow = Color(0xffbe7f64), _goldDeep = Color(0xff9a5c4c);
  static const _flame = DuskMothBossRig.flame;

  // The diadem is authored at .9 of the size it is drawn.
  static const _size = 1.16;

  /// Everything the diadem reaches, around its origin.
  static const bounds = Rect.fromLTRB(-.72, -1.22, .6, .3);

  // The far rim with its three prongs, and the opening of the ring.
  static final _farRim = Path()
    ..moveTo(-.33, -.15)
    ..lineTo(-.28, -.29)
    ..lineTo(-.21, -.58)
    ..lineTo(-.14, -.31)
    ..lineTo(.02, -.74)
    ..lineTo(.1, -.32)
    ..lineTo(.25, -.6)
    ..lineTo(.3, -.25)
    ..lineTo(.39, -.17)
    ..quadraticBezierTo(.03, -.03, -.33, -.15)
    ..close();
  static final _opening = DuskMothKit.spline(
    const [
      Offset(-.33, -.15),
      Offset(-.2, -.27),
      Offset(.03, -.31),
      Offset(.26, -.27),
      Offset(.39, -.17),
      Offset(.2, -.06),
      Offset(.0, -.04),
      Offset(-.18, -.07),
    ],
    sharp: const {0, 4},
  );

  // The near band, and the prongs standing on its rim.
  static final _band = DuskMothKit.spline(
    const [
      Offset(-.33, -.15),
      Offset(-.17, -.075),
      Offset(.03, -.045),
      Offset(.22, -.08),
      Offset(.39, -.17),
      Offset(.38, .02),
      Offset(.22, .12),
      Offset(.0, .18),
      Offset(-.2, .15),
      Offset(-.31, .09),
    ],
    sharp: const {0, 4},
  );
  static final _rimLine = DuskMothKit.spline(const [
    Offset(-.32, -.14),
    Offset(-.17, -.075),
    Offset(.03, -.045),
    Offset(.22, -.08),
    Offset(.38, -.16),
  ], closed: false);
  static final _engraving = DuskMothKit.spline(const [
    Offset(-.25, .02),
    Offset(-.1, .08),
    Offset(.05, .1),
    Offset(.2, .05),
    Offset(.3, -.03),
  ], closed: false);
  static final _nearPronged = Path()
    ..moveTo(-.27, -.1)
    ..lineTo(-.24, -.27)
    ..lineTo(-.15, -.09)
    ..close()
    ..moveTo(-.1, -.06)
    ..lineTo(-.02, -.45)
    ..lineTo(.07, -.045)
    ..close()
    ..moveTo(.15, -.07)
    ..lineTo(.24, -.35)
    ..lineTo(.31, -.1)
    ..close();
  static const _beads = [
    Offset(-.24, -.27),
    Offset(-.02, -.45),
    Offset(.24, -.35),
  ];

  // The narrow forehead plate, seen nearly edge-on at the left of the band.
  static final _plate = DuskMothKit.spline(
    const [
      Offset(-.31, .1),
      Offset(-.42, .03),
      Offset(-.45, -.2),
      Offset(-.42, -.38),
      Offset(-.35, -.46),
      Offset(-.3, -.3),
      Offset(-.29, -.1),
    ],
    sharp: const {4},
  );
  static final _gem = Path()
    ..moveTo(-.375, -.3)
    ..lineTo(-.335, -.16)
    ..lineTo(-.365, -.03)
    ..lineTo(-.415, -.16)
    ..close();

  static void paint(Canvas c, {double moonlight = 0, double fury = 0}) {
    c.save();
    c.scale(_size);
    _paint(c, moonlight, fury);
    c.restore();
  }

  static void _paint(Canvas c, double moonlight, double fury) {
    final hot = fury.clamp(0.0, 1.0);
    final gold = [
      Color.lerp(_pearl, const Color(0xffffe6b8), hot)!,
      Color.lerp(_pollen, const Color(0xffffb45a), hot)!,
      Color.lerp(_goldShadow, _flame, hot * .7)!,
    ];
    final ring = Rect.fromLTRB(-.45, -.75, .4, .2);
    // The far rim sits behind the opening.
    c.drawPath(
      _farRim,
      DuskMothKit.linear(ring.topLeft, ring.bottomRight, [
        Color.lerp(_pollen, const Color(0xffffe6b8), hot)!,
        Color.lerp(_goldShadow, _flame, hot * .6)!,
      ]),
    );
    c.drawPath(_farRim, DuskMothKit.line(_ink, .04));
    c.drawPath(
      _opening,
      DuskMothKit.linear(const Offset(-.3, -.3), const Offset(.35, -.05), [
        _ink,
        Color.lerp(_plum, _flame, hot * .6)!,
      ]),
    );
    c.drawPath(_opening, DuskMothKit.line(_goldShadow, .035));
    // Far prong beads catch a little light through the opening.
    for (final bead in const [
      Offset(-.21, -.58),
      Offset(.02, -.74),
      Offset(.25, -.6),
    ]) {
      c.drawCircle(bead, .034, DuskMothKit.fill(_ink));
      c.drawCircle(bead, .022, DuskMothKit.fill(_pollen));
    }
    // The near side.
    c.drawPath(_nearPronged, DuskMothKit.line(_ink, .085));
    c.drawPath(_band, DuskMothKit.line(_ink, .085));
    c.drawPath(
      _nearPronged,
      DuskMothKit.linear(const Offset(-.3, -.45), const Offset(.3, -.05), gold),
    );
    c.drawPath(
      _band,
      DuskMothKit.linear(const Offset(-.3, -.1), const Offset(.35, .2), gold),
    );
    c.drawPath(_band, DuskMothKit.line(_ink, .04));
    c.drawPath(_nearPronged, DuskMothKit.line(_ink, .03));
    DuskMothKit.rim(c, _band, light: _pearl, shade: _goldDeep, width: .08);
    c.drawPath(
      _engraving,
      DuskMothKit.line(_goldShadow.withValues(alpha: .8), .022),
    );
    c.drawPath(_rimLine, DuskMothKit.line(_pearl.withValues(alpha: .9), .022));
    for (final bead in _beads) {
      c.drawCircle(bead, .04, DuskMothKit.fill(_ink));
      c.drawCircle(bead, .028, DuskMothKit.fill(_pearl));
    }
    // Pearls along the rim, and the ruby set in the band.
    for (var i = 0; i < 5; i++) {
      final x = -.16 + i * .1;
      c.drawCircle(
        Offset(x, .1 - (i - 2) * (i - 2) * .006 - .0),
        .018,
        DuskMothKit.fill(_pearl),
      );
    }
    const ruby = Offset(.03, .06);
    c.drawCircle(ruby, .07, DuskMothKit.fill(_ink));
    c.drawCircle(ruby, .054, DuskMothKit.fill(_pollen));
    c.drawCircle(
      ruby,
      .04,
      DuskMothKit.radial(ruby + const Offset(-.01, -.01), .05, [
        Color.lerp(const Color(0xffff8fa0), const Color(0xffffd27a), hot)!,
        Color.lerp(_rose, _flame, hot)!,
      ]),
    );
    c.drawCircle(
      ruby + const Offset(-.015, -.018),
      .012,
      DuskMothKit.fill(_pearl),
    );
    // The crescent finial cradles a moon-gem on top of the forehead plate.
    c.save();
    c.translate(-.4, -.6);
    c.rotate(-1.0);
    DuskMothKit.glow(
      c,
      Offset.zero,
      .36,
      Color.lerp(_veil, _ember, hot)!,
      .25 + hot * .35,
    );
    final moon = DuskMothKit.crescent(Offset.zero, .2);
    c.drawPath(moon, DuskMothKit.line(_ink, .06));
    c.drawPath(
      moon,
      DuskMothKit.linear(const Offset(-.2, -.2), const Offset(.2, .2), [
        _pearl,
        Color.lerp(_silk, _pollen, hot)!,
      ]),
    );
    c.drawPath(
      DuskMothKit.crescent(const Offset(-.02, .014), .15),
      DuskMothKit.fill(
        Color.lerp(Color.lerp(_silk, _veil, moonlight)!, _pollen, hot)!,
      ),
    );
    c.restore();
    final orb = Offset(-.385, -.74);
    c.drawCircle(orb, .072, DuskMothKit.fill(_ink));
    c.drawCircle(
      orb,
      .058,
      DuskMothKit.radial(orb + const Offset(-.01, -.012), .05, [
        Color.lerp(_pearl, const Color(0xffffe6a0), hot)!,
        Color.lerp(Color.lerp(_veil, _pearl, moonlight * .6)!, _ember, hot)!,
      ]),
    );
    // The forehead plate and its moon gem.
    c.drawPath(_plate, DuskMothKit.line(_ink, .075));
    c.drawPath(
      _plate,
      DuskMothKit.linear(const Offset(-.46, -.4), const Offset(-.29, .05), [
        _silk,
        _pollen,
        _goldShadow,
      ]),
    );
    c.drawPath(_plate, DuskMothKit.line(_ink, .033));
    c.drawLine(
      const Offset(-.44, -.2),
      const Offset(-.4, .02),
      DuskMothKit.line(_pearl, .02),
    );
    c.drawPath(
      _gem,
      DuskMothKit.fill(Color.lerp(_veil, _pearl, moonlight * .6)!),
    );
    c.drawPath(_gem, DuskMothKit.line(_goldShadow, .02));
    c.drawLine(
      const Offset(-.372, -.24),
      const Offset(-.368, -.18),
      DuskMothKit.line(_pearl, .018),
    );
  }
}
