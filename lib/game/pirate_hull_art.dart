import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'pirate_sea_art.dart';
import 'pirate_ship_art.dart';

/// The Pirate Captain's hull: a weathered galleon's timber, wale and gun
/// ports, a gilded stern castle with lantern-lit windows, the sea-dragon
/// figurehead, bowsprit, anchor and hanging lanterns, the damage it takes
/// in fury, and the way it breaks apart and sinks.
///
/// Authored in the ship's rig units (see [PirateShipArt]). Every animated
/// value follows the simulation clock, so it seeks exactly, and Reduced
/// Motion keeps the hull still.
abstract final class PirateHullArt {
  static const _bow = PirateShipArt.bow, _stern = PirateShipArt.stern;
  static const _rail = PirateShipArt.rail, _water = PirateShipArt.waterline;
  static const _keel = PirateShipArt.keel, _ink = PirateShipArt.ink;

  static const _wood = Color(0xff7a4630), _woodLit = Color(0xffa8683f);
  static const _woodDeep = Color(0xff3f2119), _woodDark = Color(0xff55301f);
  static const _plank = Color(0xff2e1914), _ochre = Color(0xffd9a441);
  static const _ochreDeep = Color(0xff9d6a24), _gold = Color(0xffffcf5c);
  static const _goldLight = Color(0xfffff0b4), _goldDeep = Color(0xffc9862b);
  static const _red = Color(0xffb8404a), _redDeep = Color(0xff762431);
  static const _copper = Color(0xffc0703f), _patina = Color(0xff5fae95);
  static const _mast = Color(0xff8c5a38), _mastLit = Color(0xffc58a58);
  static const _rope = Color(0xff4f3527), _ropeLit = Color(0xffb08c5c);
  static const _bone = Color(0xfffff4dd), _fury = Color(0xffc8313f);
  static const _bronzeDeep = Color(0xff6d4420), _bronze = Color(0xffbd843c);
  static const _bronzeLit = Color(0xfff4cf85), _iron = Color(0xff454a58);
  static const _ironLit = Color(0xff8d95a8), _glow = Color(0xffffd36b);
  static const _pane = Color(0xffffe39a), _windowHot = Color(0xffff8a4a);
  static const _deck = Color(0xff24161a), _fin = Color(0xff3fb5a8);
  static const _finDeep = Color(0xff23786f), _pale = Color(0xffe8be82);
  static const _weed = Color(0xff3f7a54), _soot = Color(0xff1a1114);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint _vertical(
    Rect rect,
    List<Color> colors, [
    List<double>? stops,
  ]) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    ).createShader(rect);

  static double _hash(int a, [int b = 0]) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  // Gradients that never change are built once and reused every frame.
  static final _hullFill = _vertical(
    const Rect.fromLTRB(_bow, .2, _stern + .2, _keel),
    const [_woodLit, _wood, _woodDark, _woodDeep],
    const [0, .35, .7, 1],
  );
  static final _shadeFill = Paint()
    ..shader = LinearGradient(
      colors: [
        _woodLit.withValues(alpha: .26),
        _woodLit.withValues(alpha: 0),
        _woodDeep.withValues(alpha: .38),
      ],
      stops: const [0, .42, 1],
    ).createShader(const Rect.fromLTRB(_bow, 0, _stern + .2, 1));
  static final _castleFill = _vertical(
    const Rect.fromLTRB(1.6, .2, 3.4, 1),
    const [_woodDark, _wood],
  );
  static final _waleFill = _vertical(
    const Rect.fromLTRB(-3, 1, 3, 1.34),
    const [_ochre, _ochreDeep],
  );
  static final _wetFill = _vertical(
    const Rect.fromLTRB(-3, _water - .34, 3.5, _water + .1),
    [
      const Color(0xff1c2b30).withValues(alpha: 0),
      const Color(0xff1c2b30).withValues(alpha: .42),
    ],
  );
  static final _copperFill = _vertical(
    const Rect.fromLTRB(-3, 1.6, 3, 2.4),
    const [_copper, Color(0xff8a4a2c)],
  );
  static final _bayFill = _vertical(
    const Rect.fromLTRB(2.6, .44, 3.4, 1.2),
    const [_woodLit, _wood, _woodDark],
  );
  static final _glass = <(Rect, bool), Paint>{};

  // -------------------------------------------------------------- states --

  /// 0 to 1 for a moment after a shot thumps the hull: a flash of light
  /// along the timbers. Color only, so it also reads with Reduced Motion.
  static double _thud(SkyBoss boss) {
    final age = boss.age - boss.lastHullHitAt;
    if (age < 0 || age > .3) return 0;
    final k = 1 - age / .3;
    return k * k;
  }

  /// 0 before fury, .55 to 1 as the hull is shot to pieces in fury.
  static double _wear(SkyBoss boss) => boss.enraged
      ? .55 + .45 * (1 - boss.hp / (boss.maxHp / 2)).clamp(0.0, 1.0)
      : 0;

  /// How far the stern lantern swings on its hook: a slow pendulum that
  /// hangs plumb against the ship's roll and jolts with the guns.
  static double swing(SkyBoss boss, BossMotion m) {
    if (m.reducedMotion) return 0;
    final t = boss.age;
    var a = math.sin(t * 1.9 + .6) * .07 + math.sin(t * 4.3) * .015;
    a -= PirateShipArt.roll(boss, m) * 1.4;
    a -= m.recoil * .12;
    final hit = boss.age - boss.lastHullHitAt;
    if (hit >= 0 && hit < .8) {
      a += math.sin(hit * 24) * .1 * (1 - hit / .8);
    }
    return a;
  }

  /// The lantern's hook, and how far the lamp hangs below it.
  static const hook = Offset(3.2, -.86), drop = .56;

  /// Where the stern lamp's flame hangs at the moment, in rig units.
  static Offset lamp(SkyBoss boss, BossMotion m) {
    final a = swing(boss, m);
    return hook + Offset(-math.sin(a), math.cos(a)) * drop;
  }

  // ---------------------------------------------------------------- seam --

  /// Where the hull parts when it breaks, in rig units.
  static const seamX = 1.76;

  /// The break: a ragged line down through the timbers, dense where the
  /// hull is so the planks end in teeth.
  static final seam = <Offset>[
    const Offset(1.7, -6),
    const Offset(1.78, -1.9),
    for (var i = 0; i < 27; i++)
      Offset(
        seamX + (i.isEven ? -1 : 1) * (.05 + _hash(i, 4) * .1),
        -.4 + i * .118,
      ),
    const Offset(1.76, 3),
  ];

  static Path half({required bool left}) {
    final edge = left ? -8.0 : 8.0;
    return Path()
      ..addPolygon([Offset(edge, -6), ...seam, Offset(edge, 3)], true);
  }

  // ---------------------------------------------------------------- hull --

  /// The sheer sags a touch amidships; every strake and band follows it.
  static double _sag(double x) {
    final u = (x - .15) / 3.1;
    return .05 * (1 - u * u);
  }

  static Path _curve(double y, {double k = 1, double x0 = -2.9, double x1 = 3.4}) {
    final ya = y + _sag(x0) * k, yb = y + _sag(x1) * k;
    final xm = (x0 + x1) / 2, ym = y + _sag(xm) * k;
    return Path()
      ..moveTo(x0, ya)
      ..quadraticBezierTo(xm, 2 * ym - (ya + yb) / 2, x1, yb);
  }

  static Path _band(
    double top,
    double bottom, {
    double k = 1,
    double x0 = -2.9,
    double x1 = 3.4,
  }) {
    final ta = top + _sag(x0) * k, tb = top + _sag(x1) * k;
    final ba = bottom + _sag(x0) * k, bb = bottom + _sag(x1) * k;
    final xm = (x0 + x1) / 2;
    return Path()
      ..moveTo(x0, ta)
      ..quadraticBezierTo(
        xm,
        2 * (top + _sag(xm) * k) - (ta + tb) / 2,
        x1,
        tb,
      )
      ..lineTo(x1, bb)
      ..quadraticBezierTo(
        xm,
        2 * (bottom + _sag(xm) * k) - (ba + bb) / 2,
        x0,
        ba,
      )
      ..close();
  }

  static final path = Path()
    ..moveTo(_bow, _rail - .16)
    ..cubicTo(-2.3, _rail - .05, -1.7, _rail + .04, -1.1, _rail)
    ..lineTo(1.56, _rail)
    ..lineTo(1.66, .34)
    ..quadraticBezierTo(2.4, .3, _stern + .1, .2)
    ..lineTo(_stern + .16, .3)
    ..cubicTo(_stern + .22, .7, _stern + .08, 1.3, _stern - .22, _water)
    ..cubicTo(
      _stern - .42,
      _keel - .05,
      _stern - .8,
      _keel,
      _stern - 1.3,
      _keel,
    )
    ..lineTo(-1.7, _keel)
    ..cubicTo(-2.2, _keel, -2.42, _water + .25, -2.5, _water - .12)
    ..cubicTo(-2.56, 1.3, -2.61, 1.04, _bow, _rail - .16)
    ..close();

  /// Timber: staggered strakes with a tone of their own, grain, knots,
  /// butt joints and treenails, built once.
  static final _timber = _Timber._build();

  /// Gun ports along the wale, bow to stern.
  static const _portX = [-1.96, -.38, .56, 1.5, 2.44];
  static const _portY = 1.17;

  /// Records [draw] once into a picture. Everything about the hull that
  /// does not change from frame to frame is baked this way, so a frame
  /// only replays it and draws the few things that move or change color.
  static ui.Picture _bake(void Function(Canvas c) draw) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording();
  }

  static final _bowspritPic = _bake(_bowsprit);
  static final _figurePics = [
    _bake((c) => _figurehead(c, fury: false)),
    _bake((c) => _figurehead(c, fury: true)),
  ];
  static final _bodyPic = _bake(_body);
  static final _portsPics = [
    _bake((c) => _ports(c, false, 0, 0)),
    _bake((c) => _ports(c, true, 0, 0)),
  ];
  static final _windowsPics = [
    _bake((c) => _windows(c, fury: false)),
    _bake((c) => _windows(c, fury: true)),
  ];

  /// Fury's scorch and damage are baked per wear level (four of them, so
  /// the hull is a little more shot up each time the captain's hull points
  /// drop by an eighth), the first time each is seen.
  static final _scorchPics = <int, ui.Picture>{};
  static final _damagePics = <(int, bool), ui.Picture>{};

  static int _wearLevel(double wear) =>
      wear <= 0 ? 0 : 1 + ((wear - .55) / .45 * 3).round().clamp(0, 3);

  static double _levelWear(int level) => .55 + (level - 1) / 3 * .45;
  static final _railPics = [
    _bake((c) {
      _embrasure(c);
      _caps(c, 0);
    }),
    _bake((c) {
      _embrasure(c);
      _caps(c, 1);
    }),
  ];
  static final _topPics = [
    _bake((c) => _topsides(c, fury: false)),
    _bake((c) => _topsides(c, fury: true)),
  ];

  /// The hull's fixed body: its shadow, outline, gradient and every
  /// timber, panel, patch and waterline detail.
  static void _body(Canvas c) {
    final hull = path;
    c.drawPath(
      hull.shift(const Offset(.05, .06)),
      _fill(_ink.withValues(alpha: .35)),
    );
    c.drawPath(hull, _line(_ink, .16));
    c.drawPath(hull, _hullFill);
    c.save();
    c.clipPath(hull);
    _shading(c, hull);
    _planking(c);
    _castleWall(c);
    _waleBase(c);
    _patches(c);
    _waterline(c);
    c.restore();
  }

  /// Above the sheer and down the stern: the balustrade, the gilt trim,
  /// the gallery and the anchor.
  static void _topsides(Canvas c, {required bool fury}) {
    _balustrade(c);
    // Gilt trim down the stern post, under the gallery.
    c.drawPath(
      Path()
        ..moveTo(_stern + .16, .3)
        ..cubicTo(_stern + .22, .7, _stern + .08, 1.3, _stern - .22, _water),
      _line(_gold, .05),
    );
    _gallery(c, fury: fury);
    _anchor(c);
  }

  /// Hull hit, fury, and the broken halves all pass through here.
  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion m, {
    required bool bowHalf,
    required bool broken,
  }) {
    final t = m.reducedMotion ? 0.0 : boss.age;
    final fury = boss.enraged && !m.defeated;
    final wear = _wear(boss);
    final thud = _thud(boss);
    c.save();
    if (thud > 0 && !m.reducedMotion) {
      // A thump squashes the hull for a beat about its waterline.
      c.translate(.15, _water);
      c.scale(1 + .012 * thud, 1 - .035 * thud);
      c.translate(-.15, -_water);
    }
    c.drawPicture(_bowspritPic);
    c.drawPicture(_figurePics[fury ? 1 : 0]);
    c.drawPicture(_bodyPic);
    final hull = path;
    // What changes with the fight: scorch, the guns, the glass, damage.
    c.save();
    c.clipPath(hull);
    final level = _wearLevel(wear);
    if (level > 0) {
      c.drawPicture(
        _scorchPics.putIfAbsent(
          level,
          () => _bake((c) => _scorch(c, _levelWear(level))),
        ),
      );
    }
    // The lids only rattle while a hit lands; otherwise the guns are baked.
    if (thud > 0) {
      _ports(c, fury, thud, t);
    } else {
      c.drawPicture(_portsPics[fury ? 1 : 0]);
    }
    c.drawPicture(_windowsPics[fury ? 1 : 0]);
    if (level > 0) {
      c.drawPicture(
        _damagePics.putIfAbsent(
          (level, fury),
          () => _bake((c) => _damage(c, _levelWear(level), fury: fury)),
        ),
      );
    }
    if (m.defeated && !broken) _deathCracks(c, hull, m);
    if (broken) _seamEdge(c, bowHalf: bowHalf);
    if (thud > 0) {
      // An additive flash lights the timbers without flattening them.
      c.drawPath(
        hull,
        Paint()
          ..color = const Color(0xffffe1a0).withValues(alpha: .34 * thud)
          ..blendMode = BlendMode.plus,
      );
    }
    c.restore();
    if (thud > 0) {
      c.drawPath(hull, _line(_goldLight.withValues(alpha: .9 * thud), .08));
    }
    c.drawPicture(_railPics[wear > 0 ? 1 : 0]);
    c.drawPicture(_topPics[fury ? 1 : 0]);
    _lantern(c, boss, m, fury: fury);
    c.restore();
  }

  static void _shading(Canvas c, Path hull) {
    // Light comes from the bow's upper side; the stern falls into shade.
    c.drawPath(hull, _shadeFill);
    // Warm highlight along the upper strake.
    c.drawPath(
      Path()
        ..moveTo(_bow + .1, _rail + .05)
        ..cubicTo(-2.3, _rail + .08, -1.7, _rail + .1, -1.1, _rail + .08)
        ..lineTo(1.5, _rail + .08),
      _line(_woodLit.withValues(alpha: .8), .03),
    );
  }

  static void _planking(Canvas c) {
    final t = _timber;
    // The bulwark: a lighter strake under the gold-capped rail.
    c.drawPath(
      _band(_rail - .2, _rail + .17),
      _fill(_woodLit.withValues(alpha: .4)),
    );
    c.drawPath(t.dark, _fill(_woodDeep.withValues(alpha: .38)));
    c.drawPath(t.light, _fill(_woodLit.withValues(alpha: .3)));
    c.drawPath(t.grain, _line(_plank.withValues(alpha: .5), .014));
    c.drawPath(t.grainLight, _line(_woodLit.withValues(alpha: .4), .012));
    c.drawPath(t.seams, _line(_plank.withValues(alpha: .72), .03));
    // A lit edge under each seam gives the strakes their relief.
    c.drawPath(
      t.seams.shift(const Offset(0, .026)),
      _line(_woodLit.withValues(alpha: .38), .016),
    );
    c.drawPath(t.joints, _line(_plank.withValues(alpha: .55), .022));
    c.drawPath(t.nails, _fill(_ink.withValues(alpha: .6)));
    for (final (at, r) in t.knots) {
      final knot = Rect.fromCenter(center: at, width: r * 2.4, height: r * 1.5);
      c.drawOval(knot, _fill(_plank.withValues(alpha: .55)));
      c.drawOval(knot.deflate(r * .45), _fill(_woodDeep.withValues(alpha: .8)));
      c.drawArc(
        knot.inflate(r * .3),
        2.6,
        1.9,
        false,
        _line(_woodLit.withValues(alpha: .5), .012),
      );
    }
  }

  /// The stern castle's paneled side: wall, frieze, pilasters, scrollwork.
  static void _castleWall(Canvas c) {
    const wall = Rect.fromLTRB(1.62, .2, 3.4, _rail + .05);
    c.drawRect(wall, _castleFill);
    // Upright planks with butt joints, and a shaded lower panel.
    for (var i = 0; i < 6; i++) {
      final x = 1.64 + i * .3;
      c.drawLine(
        Offset(x, .3),
        Offset(x, _rail + .05),
        _line(_plank.withValues(alpha: .55), .028),
      );
      if (_hash(i, 9) > .35) {
        final y = .44 + _hash(i, 3) * .3;
        c.drawLine(
          Offset(x - .015, y),
          Offset(x + .28, y),
          _line(_plank.withValues(alpha: .3), .014),
        );
      }
    }
    c.drawRect(
      const Rect.fromLTRB(1.62, .76, 3.4, _rail + .05),
      _fill(_woodDeep.withValues(alpha: .34)),
    );
    // A carved frieze under the deck edge: gilded dentils on a dark band.
    c.drawRect(
      const Rect.fromLTRB(1.62, .29, 3.4, .4),
      _fill(_woodDeep.withValues(alpha: .55)),
    );
    for (var x = 1.72; x < 3.2; x += .12) {
      final y = .36 - (x - 1.66) * .0714;
      c.drawRect(
        Rect.fromLTWH(x, y, .06, .06),
        _fill(_gold.withValues(alpha: .9)),
      );
    }
    c.drawLine(
      const Offset(1.62, .42),
      const Offset(3.4, .34),
      _line(_ochreDeep, .03),
    );
    // Two gilt bands with a row of studs run along the foot of the castle.
    for (final y in const [.8, .9]) {
      c.drawLine(Offset(1.62, y), Offset(3.4, y), _line(_ink, .06));
      c.drawLine(Offset(1.62, y), Offset(3.4, y), _line(_ochre, .03));
    }
    for (var x = 1.7; x < 3.3; x += .1) {
      c.drawCircle(Offset(x, .85), .02, _fill(_gold.withValues(alpha: .9)));
    }
    // A coil of rope hangs from a peg by the break of the deck.
    const coil = Offset(1.8, .6);
    c.drawOval(
      Rect.fromCenter(center: coil, width: .34, height: .3),
      _fill(_ink),
    );
    c.drawOval(
      Rect.fromCenter(center: coil, width: .29, height: .25),
      _fill(_ropeLit),
    );
    for (var i = 1; i < 4; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: coil,
          width: .29 - i * .07,
          height: .25 - i * .06,
        ),
        _line(_rope.withValues(alpha: .85), .022),
      );
    }
    c.drawOval(
      Rect.fromCenter(center: coil, width: .07, height: .06),
      _fill(_ink),
    );
    c.drawCircle(coil + const Offset(0, -.17), .028, _fill(_iron));
  }

  static void _waleBase(Canvas c) {
    final wale = _band(1.02, 1.34);
    c.drawPath(wale, _waleFill);
    // Shadow under the wale, then its edges: a lit top, an inked foot.
    c.drawPath(_band(1.34, 1.42), _fill(_ink.withValues(alpha: .3)));
    c.drawPath(_curve(1.055), _line(_goldLight.withValues(alpha: .75), .02));
    c.drawPath(_curve(1.02), _line(_ink, .04));
    c.drawPath(_curve(1.335), _line(_ink, .045));
    // Carved panels with a gilt rosette in the runs between the ports.
    const runs = [(.09, .62), (1.03, .62), (1.97, .62), (2.8, .34)];
    for (final (mid, w) in runs) {
      final y = 1.18 + _sag(mid);
      final panel = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(mid, y), width: w, height: .16),
        const Radius.circular(.05),
      );
      c.drawRRect(panel, _fill(_ochreDeep.withValues(alpha: .35)));
      c.drawRRect(panel, _line(_ochreDeep, .03));
      c.drawRRect(
        panel.deflate(.028),
        _line(_goldLight.withValues(alpha: .45), .014),
      );
      c.drawCircle(Offset(mid, y), .045, _fill(_ink.withValues(alpha: .75)));
      c.drawCircle(Offset(mid, y), .034, _fill(_gold));
      c.drawCircle(Offset(mid - .01, y - .01), .014, _fill(_goldLight));
      for (final dx in [-w / 2 - .09, w / 2 + .09]) {
        if (mid == 2.8 && dx > 0) continue;
        final at = Offset(mid + dx, y);
        c.drawCircle(at, .03, _fill(_ink.withValues(alpha: .7)));
        c.drawCircle(at + const Offset(-.007, -.008), .016, _fill(_ironLit));
      }
    }
    // Rust and weather stain run down from the bolts.
    for (final x in const [-.42, .6, .69, 1.56, 1.65, 2.58]) {
      final y = 1.34 + _sag(x);
      c.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + .02, y + .1, x - .01, y + .22 + (x * 13 % 1) * .1),
        _line(_plank.withValues(alpha: .28), .022),
      );
    }
  }

  static void _ports(Canvas c, bool fury, double thud, double t) {
    for (var i = 0; i < _portX.length; i++) {
      _gunPort(c, Offset(_portX[i], _portY + _sag(_portX[i])), i, fury, thud, t);
    }
  }

  static void _gunPort(
    Canvas c,
    Offset at,
    int index,
    bool fury,
    double thud,
    double t,
  ) {
    final port = Rect.fromCenter(center: at, width: .24, height: .2);
    c.drawRect(port.inflate(.035), _fill(_ink));
    c.drawRect(port, _fill(fury ? const Color(0xff4a1414) : const Color(0xff1a0f10)));
    // The gun run out: a bronze muzzle with its bore, hot in fury.
    final muzzle = at + const Offset(-.01, .015);
    c.drawCircle(muzzle, .075, _fill(_ink));
    c.drawCircle(muzzle, .062, _fill(fury ? _bronze : _bronzeDeep));
    c.drawArc(
      Rect.fromCircle(center: muzzle, radius: .05),
      -2.7,
      1.5,
      false,
      _line(_bronzeLit.withValues(alpha: .9), .016),
    );
    c.drawCircle(muzzle, .033, _fill(fury ? _windowHot : const Color(0xff120c0e)));
    if (fury) {
      c.drawCircle(muzzle, .02, _fill(const Color(0xfffff0b4)));
      c.drawCircle(
        muzzle,
        .19,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _windowHot.withValues(alpha: .42),
              _windowHot.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: muzzle, radius: .19)),
      );
    }
    // The red lid, hinged open above the port and rattled by a hit.
    final rattle = t == 0 ? 0.0 : thud * math.sin(t * 60 + index) * .05;
    c.save();
    c.translate(port.left, port.top - .02);
    c.rotate(rattle);
    final lid = Path()
      ..moveTo(-.02, 0)
      ..lineTo(port.width + .02, 0)
      ..lineTo(port.width - .02, -.14)
      ..lineTo(.02, -.14)
      ..close();
    c.drawPath(lid, _fill(_red));
    c.drawPath(lid, _line(_ink, .028));
    c.drawLine(
      const Offset(.04, -.11),
      Offset(port.width - .04, -.11),
      _line(const Color(0xffe9707a).withValues(alpha: .8), .02),
    );
    c.restore();
  }

  /// Copper sheathing and the wet, weedy waterline.
  static void _waterline(Canvas c) {
    // Boot-topping: a dark red stripe just above the water.
    c.drawPath(_band(_water - .15, _water - .02, k: .3), _fill(_redDeep.withValues(alpha: .85)));
    c.drawPath(_curve(_water - .15, k: .3), _line(_ink.withValues(alpha: .5), .025));
    // Wet timber darkens toward the sea.
    c.drawRect(const Rect.fromLTRB(-3, _water - .34, 3.5, _water + .1), _wetFill);
    // Copper sheathing below, green with age.
    c.drawPath(_band(_water - .04, _keel + .3, k: .3), _copperFill);
    for (var x = _bow; x < _stern; x += .32) {
      c.drawLine(
        Offset(x, _water),
        Offset(x + .02, _keel),
        _line(_ink.withValues(alpha: .25), .02),
      );
    }
    for (final (x, y, r) in const [
      (-1.6, 1.95, .16),
      (.3, 2.05, .2),
      (2.1, 1.92, .14),
    ]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r * 3, height: r),
        _fill(_patina.withValues(alpha: .55)),
      );
    }
    // Weed streaks and barnacle clusters at the waterline.
    for (var i = 0; i < 14; i++) {
      final x = -2.5 + i * .4 + _hash(i, 21) * .25;
      final len = .1 + _hash(i, 22) * .14;
      final lean = (_hash(i, 23) - .5) * .12;
      c.drawPath(
        Path()
          ..moveTo(x, _water - .02)
          ..quadraticBezierTo(x + lean, _water - len * .6, x + lean * 1.6, _water - len),
        _line(_weed.withValues(alpha: .85), .028),
      );
    }
    for (var i = 0; i < 9; i++) {
      final x = -2.2 + i * .62 + _hash(i, 31) * .3;
      for (var j = 0; j < 3; j++) {
        final at = Offset(x + j * .045, _water - .1 - (j % 2) * .03 + _hash(i, j) * .03);
        c.drawCircle(at, .026, _fill(_ink.withValues(alpha: .5)));
        c.drawCircle(at + const Offset(-.004, -.004), .019, _fill(_bone.withValues(alpha: .85)));
      }
    }
    c.drawPath(
      _curve(_water - .06, k: .3, x0: -2.9, x1: 3.4),
      _line(_bone.withValues(alpha: .7), .035),
    );
  }

  /// Plank patches and rope mends: the ship has seen a few fights already.
  static void _patches(Canvas c) {
    for (final (rect, turn, tone) in [
      (Rect.fromLTWH(-1.38, 1.4, .5, .19), -.02, _woodLit),
      (Rect.fromLTWH(1.86, 1.52, .42, .16), .03, _pale),
    ]) {
      c.save();
      c.translate(rect.center.dx, rect.center.dy);
      c.rotate(turn);
      final r = Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height);
      c.drawRect(r.inflate(.02), _fill(_ink.withValues(alpha: .8)));
      c.drawRect(r, _fill(tone.withValues(alpha: .85)));
      c.drawLine(
        Offset(r.left + .02, r.center.dy),
        Offset(r.right - .02, r.center.dy),
        _line(_plank.withValues(alpha: .3), .014),
      );
      for (final x in [r.left + .05, r.right - .05]) {
        for (final y in [r.top + .04, r.bottom - .04]) {
          c.drawCircle(Offset(x, y), .018, _fill(_ink));
        }
      }
      c.restore();
    }
  }

  static void _windows(Canvas c, {required bool fury}) {
    for (final x in const [2.02, 2.34]) {
      _window(c, Rect.fromLTWH(x, .46, .22, .29), fury, shutters: true);
    }
  }

  static void _window(Canvas c, Rect r, bool fury, {bool shutters = false}) {
    if (shutters) {
      for (final left in [true, false]) {
        final x = left ? r.left - .1 : r.right + .03;
        final shutter = Rect.fromLTWH(x, r.top + .02, .07, r.height - .02);
        c.drawRect(shutter.inflate(.02), _fill(_ink));
        c.drawRect(shutter, _fill(_red));
        c.drawLine(
          Offset(shutter.center.dx, shutter.top + .02),
          Offset(shutter.center.dx, shutter.bottom - .02),
          _line(_redDeep, .012),
        );
      }
    }
    final arch = RRect.fromRectAndCorners(
      r,
      topLeft: Radius.circular(r.width / 2),
      topRight: Radius.circular(r.width / 2),
    );
    c.drawRRect(arch.inflate(.045), _fill(_ink));
    c.drawRRect(arch.inflate(.024), _fill(_goldDeep));
    c.drawRRect(
      arch,
      _glass[(r, fury)] ??= _vertical(r, [
        fury ? _windowHot : _pane,
        fury ? const Color(0xffd6452f) : _glow,
      ]),
    );
    // A glint across the glass, then the mullions and a gilded sill.
    c.drawLine(
      Offset(r.left + r.width * .22, r.top + r.height * .34),
      Offset(r.left + r.width * .42, r.top + r.height * .12),
      _line(const Color(0xffffffff).withValues(alpha: .55), .022),
    );
    c.drawLine(
      Offset(r.center.dx, r.top),
      Offset(r.center.dx, r.bottom),
      _line(_ink, .025),
    );
    c.drawLine(
      Offset(r.left, r.center.dy),
      Offset(r.right, r.center.dy),
      _line(_ink, .025),
    );
    c.drawLine(
      Offset(r.left - .04, r.bottom + .04),
      Offset(r.right + .04, r.bottom + .04),
      _line(_ink, .06),
    );
    c.drawLine(
      Offset(r.left - .04, r.bottom + .04),
      Offset(r.right + .04, r.bottom + .04),
      _line(_gold, .028),
    );
  }

  // -------------------------------------------------------------- damage --

  /// Soot blooms out of the ports that have fired hardest, a burnt ring
  /// around each muzzle; drawn under the ports so their glow stays hot.
  static void _scorch(Canvas c, double wear) {
    for (final (x, r) in const [(.56, .5), (1.5, .44), (-.38, .38)]) {
      final at = Offset(x, 1.17 + _sag(x));
      c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _soot.withValues(alpha: .85 * wear),
              _soot.withValues(alpha: .4 * wear),
              _soot.withValues(alpha: 0),
            ],
            stops: const [0, .5, 1],
          ).createShader(Rect.fromCircle(center: at, radius: r)),
      );
      c.drawPath(
        _sootLick(x, r * .8, r * 1.1),
        _fill(_soot.withValues(alpha: .34 * wear)),
      );
    }
  }

  /// Fury: scorch, splintered holes, cracks and broken rail. It builds as
  /// the captain's hull points run out.
  static void _damage(Canvas c, double wear, {required bool fury}) {
    // Shot-through holes below the wale, splinters bristling from the lip.
    _hole(c, const Offset(.06, 1.52), 1.15, fury);
    if (wear > .8) _hole(c, const Offset(-1.02, 1.55), .8, fury);
    // Cracks running out of the hole and up the bulwark.
    c.drawPath(
      Path()
        ..moveTo(.34, 1.5)
        ..lineTo(.5, 1.42)
        ..lineTo(.62, 1.5)
        ..lineTo(.86, 1.44)
        ..moveTo(-.2, 1.56)
        ..lineTo(-.36, 1.64)
        ..lineTo(-.52, 1.58)
        ..moveTo(.98, _rail + .01)
        ..lineTo(1.02, _rail + .1)
        ..lineTo(1.1, _rail + .06)
        ..lineTo(1.14, _rail + .15),
      _line(_ink.withValues(alpha: .85), .03),
    );
  }

  /// A tongue of soot licking up from a gun port's top edge.
  static Path _sootLick(double x, double w, double h) => Path()
    ..moveTo(x - w * .5, 1.08)
    ..quadraticBezierTo(x - w * .7, 1.08 - h * .6, x - w * .15, 1.08 - h)
    ..quadraticBezierTo(x + w * .05, 1.08 - h * .55, x + w * .1, 1.08 - h * .82)
    ..quadraticBezierTo(x + w * .75, 1.08 - h * .5, x + w * .5, 1.08)
    ..close();

  static void _hole(Canvas c, Offset at, double scale, bool fury) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(scale);
    // A plank shot out: a ragged, wide gap in the course.
    final hole = Path()
      ..addPolygon(const [
        Offset(-.32, .05),
        Offset(-.27, -.06),
        Offset(-.16, -.09),
        Offset(-.08, -.05),
        Offset(.04, -.1),
        Offset(.16, -.07),
        Offset(.27, -.1),
        Offset(.33, .0),
        Offset(.26, .08),
        Offset(.13, .06),
        Offset(.02, .11),
        Offset(-.1, .07),
        Offset(-.2, .11),
      ], true);
    c.drawPath(hole, _line(_soot.withValues(alpha: .7), .13));
    c.drawPath(hole, _line(_ink, .05));
    c.drawPath(hole, _fill(const Color(0xff0e0809)));
    // The hold behind: a glimmer of deck beams, embers in fury.
    c.drawLine(const Offset(-.24, .0), const Offset(.26, .0), _line(_deck, .06));
    if (fury) {
      c.drawOval(
        Rect.fromCenter(center: const Offset(.05, .03), width: .22, height: .05),
        _fill(_windowHot.withValues(alpha: .65)),
      );
    }
    // Slender splinters angle in from the left rim.
    for (final (a, tip) in const [
      (Offset(-.3, -.03), Offset(-.09, .0)),
      (Offset(-.22, .09), Offset(-.05, .045)),
    ]) {
      final n = Offset(tip.dy - a.dy, a.dx - tip.dx);
      final k = .035 / n.distance;
      final sliver = Path()
        ..moveTo(a.dx + n.dx * k, a.dy + n.dy * k)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(a.dx - n.dx * k, a.dy - n.dy * k)
        ..close();
      c.drawPath(sliver, _line(_ink, .04));
      c.drawPath(sliver, _fill(_pale));
    }
    // A broken plank hangs from the right lip by a few fibres.
    c.save();
    c.translate(.2, -.07);
    c.rotate(1.05);
    final plank = Path()
      ..moveTo(0, -.035)
      ..lineTo(.24, -.03)
      ..lineTo(.3, -.005)
      ..lineTo(.25, .015)
      ..lineTo(.28, .04)
      ..lineTo(0, .035)
      ..close();
    c.drawPath(plank, _line(_ink, .05));
    c.drawPath(plank, _fill(_pale));
    c.drawLine(const Offset(.02, .0), const Offset(.22, .0), _line(_wood.withValues(alpha: .7), .014));
    c.restore();
    c.restore();
  }

  /// Death: the timbers glow along the line where the keel is about to
  /// snap, a crack running down from the deck as the overload builds.
  static void _deathCracks(Canvas c, Path hull, BossMotion m) {
    if (m.reducedMotion) return;
    final k = BossMotion.ramp(m.death, .3, SkyBoss.burstAt);
    if (k <= 0) return;
    final pulse = .75 + .25 * math.sin(m.death * 46);
    c.drawPath(hull, _fill(_windowHot.withValues(alpha: .2 * k * pulse)));
    final crack = Path();
    var started = false;
    for (final p in seam.sublist(2, seam.length - 1)) {
      if (p.dy < .25 || p.dy > .25 + 2.2 * k) continue;
      started ? crack.lineTo(p.dx, p.dy) : crack.moveTo(p.dx, p.dy);
      started = true;
    }
    if (!started) return;
    c.drawPath(crack, _line(_windowHot.withValues(alpha: .35 * k), .34));
    c.drawPath(crack, _line(_ink, .2));
    c.drawPath(crack, _line(_windowHot.withValues(alpha: pulse), .12));
    c.drawPath(crack, _line(_goldLight, .05));
  }

  // ----------------------------------------------------------- broken --

  /// The fresh timber where the hull parted: pale end grain in a ragged
  /// band and the dark frames behind it.
  static void _seamEdge(Canvas c, {required bool bowHalf}) {
    final edge = Path()..addPolygon(seam.sublist(1, seam.length - 1), false);
    final into = bowHalf ? -1.0 : 1.0;
    c.drawPath(edge, _line(_ink, .26));
    c.drawPath(edge, _line(_pale, .2));
    for (var i = 3; i < seam.length - 3; i += 2) {
      final p = seam[i];
      c.drawLine(p, p + Offset(into * .26, 0), _line(_woodDeep.withValues(alpha: .85), .05));
    }
    c.drawPath(edge, _line(_goldLight.withValues(alpha: .6), .05));
  }

  // --------------------------------------------------- above the sheer --

  /// The cannon's embrasure: a gap in the bulwark over the bow deck.
  static void _embrasure(Canvas c) {
    final notch = RRect.fromRectAndCorners(
      const Rect.fromLTRB(-1.7, _rail - .06, -.78, 1.16),
      bottomLeft: const Radius.circular(.12),
      bottomRight: const Radius.circular(.12),
    );
    c.drawRRect(notch, _fill(_deck));
    c.drawLine(
      const Offset(-1.66, 1.1),
      const Offset(-.82, 1.1),
      _line(_woodLit.withValues(alpha: .35), .03),
    );
  }

  /// Gold rail caps, broken by the embrasure (and by shot, in fury).
  static void _caps(Canvas c, double wear) {
    final caps = <Path>[
      Path()
        ..moveTo(_bow, _rail - .16)
        ..cubicTo(-2.3, _rail - .06, -1.95, _rail - .02, -1.7, _rail - .01),
      if (wear > 0) ...[
        Path()
          ..moveTo(-.78, _rail)
          ..lineTo(1.24, _rail),
        Path()
          ..moveTo(1.4, _rail)
          ..lineTo(1.56, _rail),
      ] else
        Path()
          ..moveTo(-.78, _rail)
          ..lineTo(1.56, _rail),
      Path()
        ..moveTo(1.66, .34)
        ..quadraticBezierTo(2.4, .3, _stern + .1, .2),
    ];
    for (final cap in caps) {
      c.drawPath(cap, _line(_ink, .12));
      c.drawPath(cap, _line(_ochre, .06));
      c.drawPath(cap, _line(_goldLight.withValues(alpha: .7), .018));
    }
    if (wear > 0) {
      // Splintered ends where the cap was shot away.
      for (final (x, dir) in const [(1.24, 1.0), (1.4, -1.0)]) {
        final a = Offset(x - dir * .02, _rail - .07);
        final b = Offset(x + dir * .03, _rail + .05);
        c.drawLine(a, b, _line(_ink, .075));
        c.drawLine(a, b, _line(_pale, .036));
      }
    }
    // A gilded knee curls up the stem.
    final scroll = Path()
      ..moveTo(_bow + .3, _rail - .1)
      ..quadraticBezierTo(_bow - .04, _rail - .2, _bow - .08, _rail + .06)
      ..quadraticBezierTo(_bow - .06, _rail + .22, _bow + .1, _rail + .16)
      ..quadraticBezierTo(_bow + .14, _rail + .02, _bow + .02, _rail + .04);
    c.drawPath(scroll, _line(_ink, .1));
    c.drawPath(scroll, _line(_gold, .05));
  }

  static void _balustrade(Canvas c) {
    // Turned posts along the quarterdeck.
    final post = _line(_ink, .07);
    final wood = _line(_woodLit, .035);
    for (var x = 1.76; x < _stern; x += .2) {
      final y = .33 - (x - 1.66) * .1 / 1.4;
      c.drawLine(Offset(x, y), Offset(x, y - .22), post);
      c.drawLine(Offset(x, y), Offset(x, y - .22), wood);
      c.drawCircle(Offset(x, y - .11), .034, _fill(_ink));
      c.drawCircle(Offset(x, y - .11), .02, _fill(_woodLit));
    }
    final top = Path()
      ..moveTo(1.66, .1)
      ..quadraticBezierTo(2.4, .06, _stern + .1, -.04);
    c.drawPath(top, _line(_ink, .1));
    c.drawPath(top, _line(_ochre, .05));
    // Gilded finials cap the end posts.
    for (final at in const [Offset(1.68, .06), Offset(_stern + .1, -.06)]) {
      c.drawCircle(at, .07, _fill(_ink));
      c.drawCircle(at, .048, _fill(_gold));
      c.drawCircle(at + const Offset(-.014, -.016), .017, _fill(_goldLight));
    }
  }

  /// The quarter gallery hangs off the stern: a bell-shaped bay with its
  /// own lit window, gilt pilasters and a carved pendant.
  static void _gallery(Canvas c, {required bool fury}) {
    final bay = Path()
      ..moveTo(2.68, .46)
      ..lineTo(3.32, .46)
      ..cubicTo(3.44, .66, 3.42, .92, 3.26, 1.06)
      ..quadraticBezierTo(3.02, 1.22, 2.8, 1.1)
      ..lineTo(2.68, .98)
      ..close();
    c.drawPath(bay, _line(_ink, .08));
    c.drawPath(bay, _bayFill);
    c.drawPath(
      Path()
        ..moveTo(3.3, .5)
        ..cubicTo(3.4, .68, 3.38, .9, 3.24, 1.03),
      _line(_woodDeep.withValues(alpha: .5), .05),
    );
    _window(c, const Rect.fromLTWH(2.85, .54, .22, .3), fury);
    // Gilt pilasters flank the window.
    for (final x in const [2.76, 3.16]) {
      c.drawLine(Offset(x, .5), Offset(x, 1.0), _line(_ink, .06));
      c.drawLine(Offset(x, .5), Offset(x, 1.0), _line(_gold, .028));
    }
    // A gilded cornice with its lit top, and a carved pendant below.
    c.drawLine(const Offset(2.63, .45), const Offset(3.37, .45), _line(_ink, .12));
    c.drawLine(const Offset(2.63, .45), const Offset(3.37, .45), _line(_ochre, .065));
    c.drawLine(
      const Offset(2.66, .43),
      const Offset(3.34, .43),
      _line(_goldLight.withValues(alpha: .8), .02),
    );
    final pendant = Path()
      ..moveTo(3.0, 1.12)
      ..quadraticBezierTo(2.94, 1.24, 3.02, 1.3)
      ..quadraticBezierTo(3.1, 1.24, 3.04, 1.12);
    c.drawPath(pendant, _line(_ink, .06));
    c.drawPath(pendant, _fill(_gold));
    c.drawLine(const Offset(2.74, 1.02), const Offset(3.3, 1.02), _line(_gold, .035));
  }

  static void _anchor(Canvas c) {
    // A cathead beam pokes out of the bow; the anchor hangs from it.
    const ring = Offset(-2.3, 1.04);
    c.drawCircle(const Offset(-2.3, .94), .1, _fill(_ink));
    c.drawCircle(const Offset(-2.3, .94), .07, _fill(_mast));
    c.drawCircle(const Offset(-2.3, .94), .028, _fill(_ironLit));
    c.drawLine(const Offset(-2.3, .96), ring, _line(_ink, .07));
    c.drawLine(const Offset(-2.3, .96), ring, _line(_rope, .035));
    final anchor = Path()
      ..moveTo(ring.dx, ring.dy)
      ..lineTo(ring.dx, ring.dy + .52)
      ..moveTo(ring.dx - .15, ring.dy + .12)
      ..lineTo(ring.dx + .15, ring.dy + .12)
      ..moveTo(ring.dx - .22, ring.dy + .38)
      ..quadraticBezierTo(ring.dx - .2, ring.dy + .52, ring.dx, ring.dy + .52)
      ..quadraticBezierTo(ring.dx + .2, ring.dy + .52, ring.dx + .22, ring.dy + .38);
    c.drawPath(anchor, _line(_ink, .11));
    c.drawPath(anchor, _line(_iron, .06));
    c.drawPath(anchor, _line(_ironLit.withValues(alpha: .6), .016));
    for (final s in const [-1.0, 1.0]) {
      final fluke = Path()
        ..moveTo(ring.dx + s * .22, ring.dy + .38)
        ..lineTo(ring.dx + s * .32, ring.dy + .3)
        ..lineTo(ring.dx + s * .24, ring.dy + .46)
        ..close();
      c.drawPath(fluke, _line(_ink, .04));
      c.drawPath(fluke, _fill(_iron));
      c.drawCircle(Offset(ring.dx + s * .15, ring.dy + .12), .035, _fill(_ink));
    }
    c.drawCircle(ring, .055, _line(_ink, .05));
    c.drawCircle(ring, .055, _line(_ironLit, .02));
  }

  // -------------------------------------------------------------- lamp --

  /// The stern lantern on a gooseneck arm: it hangs from its hook and
  /// swings.
  static void _lantern(Canvas c, SkyBoss boss, BossMotion m, {required bool fury}) {
    final arm = Path()
      ..moveTo(_stern + .04, .24)
      ..cubicTo(_stern + .1, -.3, _stern + .02, -.86, hook.dx - .02, hook.dy);
    c.drawPath(arm, _line(_ink, .1));
    c.drawPath(arm, _line(_iron, .05));
    c.drawPath(arm, _line(_ironLit.withValues(alpha: .6), .014));
    c.drawCircle(hook, .05, _fill(_ink));
    c.drawCircle(hook, .03, _fill(_ironLit));
    final t = m.reducedMotion ? 0.0 : boss.age;
    c.save();
    c.translate(hook.dx, hook.dy);
    c.rotate(swing(boss, m));
    c.translate(0, drop);
    _lampBody(c, fury, t);
    c.restore();
  }

  static void _lampBody(Canvas c, bool fury, double t) {
    // Two links of chain up to the ring.
    for (var i = 0; i < 2; i++) {
      final at = Offset(0, -drop + .1 + i * .07);
      c.drawOval(Rect.fromCenter(center: at, width: .05, height: .075), _line(_ink, .03));
    }
    final body = Path()
      ..moveTo(-.1, -.14)
      ..lineTo(.1, -.14)
      ..lineTo(.13, .12)
      ..lineTo(.06, .2)
      ..lineTo(-.06, .2)
      ..lineTo(-.13, .12)
      ..close();
    final flicker = t == 0 ? 0.0 : math.sin(t * 9) * .04 + math.sin(t * 23) * .03;
    c.drawPath(body, _line(_ink, .06));
    c.drawPath(
      body,
      _vertical(body.getBounds(), [
        _bone,
        Color.lerp(fury ? _windowHot : _pane, _bone, .2 + flicker)!,
        fury ? const Color(0xffd6452f) : _glow,
      ]),
    );
    c.drawLine(const Offset(0, -.14), const Offset(0, .2), _line(_goldDeep, .03));
    for (final x in const [-.06, .06]) {
      c.drawLine(Offset(x, -.13), Offset(x * 1.6, .13), _line(_goldDeep.withValues(alpha: .7), .02));
    }
    final cap = Path()
      ..moveTo(-.15, -.13)
      ..lineTo(0, -.3)
      ..lineTo(.15, -.13)
      ..close();
    c.drawPath(cap, _line(_ink, .05));
    c.drawPath(cap, _fill(_gold));
    c.drawCircle(const Offset(0, -.34), .05, _line(_ink, .03));
    c.drawLine(const Offset(-.08, .22), const Offset(.08, .22), _line(_goldDeep, .05));
  }

  // -------------------------------------------------------------- bow --

  static void _bowsprit(Canvas c) {
    final spar = Path()
      ..moveTo(-2.1, .98)
      ..lineTo(-2.3, .76)
      ..lineTo(-3.8, .27)
      ..lineTo(-3.76, .36)
      ..close();
    c.drawPath(spar, _line(_ink, .1));
    c.drawPath(spar, _fill(_mast));
    c.drawLine(
      const Offset(-2.3, .8),
      const Offset(-3.74, .31),
      _line(_mastLit.withValues(alpha: .7), .025),
    );
    // Rope lashing and iron bands along the spar.
    for (final x in const [-2.52, -2.58, -2.64, -2.7]) {
      final y = .76 + (x + 2.3) * .325;
      c.drawLine(Offset(x - .01, y - .1), Offset(x + .035, y + .09), _line(_ink, .045));
      c.drawLine(Offset(x - .01, y - .1), Offset(x + .035, y + .09), _line(_ropeLit, .025));
    }
    for (final x in const [-3.0, -3.42]) {
      final y = .76 + (x + 2.3) * .325;
      c.drawLine(Offset(x, y - .09), Offset(x + .04, y + .08), _line(_iron, .04));
    }
    c.drawCircle(const Offset(-3.79, .3), .06, _fill(_ink));
    c.drawCircle(const Offset(-3.79, .3), .04, _fill(_gold));
    // A bobstay chain runs from the spar's tip down to the cutwater.
    const tip = Offset(-3.74, .33), foot = Offset(-2.6, 1.6);
    c.drawLine(tip, foot, _line(_ink, .06));
    c.drawLine(tip, foot, _line(_iron, .03));
    for (var i = 1; i < 9; i++) {
      final at = Offset.lerp(tip, foot, i / 9.5)!;
      c.drawOval(Rect.fromCenter(center: at, width: .05, height: .07), _line(_ironLit, .016));
    }
  }

  static Offset _bez(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t);
  }

  /// A swept fin: a curved blade with ribs, [len] long, growing from [at]
  /// along [angle].
  static void _finBlade(Canvas c, Offset at, double angle, double len, Color color, Color deep) {
    final d = Offset(math.cos(angle), math.sin(angle));
    final n = Offset(-d.dy, d.dx);
    final w = len * .3;
    final tip = at + d * len + n * len * .12;
    final blade = Path()
      ..moveTo((at + n * w).dx, (at + n * w).dy)
      ..quadraticBezierTo(
        (at + d * len * .6 + n * w * .9).dx,
        (at + d * len * .6 + n * w * .9).dy,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        (at + d * len * .5 - n * w * .6).dx,
        (at + d * len * .5 - n * w * .6).dy,
        (at - n * w).dx,
        (at - n * w).dy,
      )
      ..close();
    c.drawPath(blade, _line(_ink, .055));
    c.drawPath(blade, _fill(color));
    for (final k in const [-.5, .2]) {
      c.drawLine(
        at + n * w * k,
        at + d * len * .8 + n * (w * k * .3 + len * .1),
        _line(deep, .022),
      );
    }
  }

  /// The sea-dragon figurehead: gilded scales, teal fins and a red maw,
  /// snarling forward off the cutwater.
  static void _figurehead(Canvas c, {required bool fury}) {
    c.save();
    c.translate(-3.2, .98);
    c.scale(-1.35, 1.35);
    final fin = fury ? _fury : _fin;
    final finDeep = fury ? const Color(0xff7a1626) : _finDeep;
    const n0 = Offset(-.5, .5), n1 = Offset(-.6, .16);
    const n2 = Offset(-.36, .2), n3 = Offset(-.14, .04);
    // A fan of fins sweeps back from behind the jaw, over the spar.
    for (var i = 0; i < 3; i++) {
      _finBlade(
        c,
        const Offset(-.16, -.02) + Offset(-i * .04, i * .05),
        -2.0 - i * .38,
        .56 - i * .07,
        i.isEven ? fin : finDeep,
        i.isEven ? finDeep : fin,
      );
    }
    // The neck swoops up out of the stem.
    final neck = Path()
      ..moveTo(n0.dx, n0.dy)
      ..cubicTo(n1.dx, n1.dy, n2.dx, n2.dy, n3.dx, n3.dy);
    c.drawPath(neck, _line(_ink, .44));
    c.drawPath(neck, _line(_goldDeep, .34));
    c.drawPath(neck.shift(const Offset(0, -.035)), _line(_gold, .2));
    c.drawPath(neck.shift(const Offset(-.01, -.07)), _line(_goldLight.withValues(alpha: .7), .05));
    // Scale arcs on the neck.
    for (var i = 0; i < 5; i++) {
      final at = _bez(n0, n1, n2, n3, .38 + i * .13) + const Offset(0, .06);
      c.drawArc(
        Rect.fromCenter(center: at, width: .1, height: .09),
        .4,
        2.3,
        false,
        _line(_ink.withValues(alpha: .55), .02),
      );
    }
    // Mouth, jaws, teeth.
    final maw = Path()
      ..moveTo(-.12, .0)
      ..lineTo(.46, .02)
      ..lineTo(.4, .2)
      ..lineTo(-.04, .18)
      ..close();
    c.drawPath(maw, _fill(fury ? const Color(0xffe8552f) : _red));
    final lower = Path()
      ..moveTo(-.12, .08)
      ..lineTo(.4, .17)
      ..quadraticBezierTo(.44, .26, .32, .27)
      ..lineTo(-.02, .24)
      ..quadraticBezierTo(-.16, .2, -.12, .08)
      ..close();
    c.drawPath(lower, _line(_ink, .07));
    c.drawPath(lower, _fill(_goldDeep));
    for (final x in const [.14, .27]) {
      c.drawPath(
        Path()
          ..moveTo(x - .04, .17)
          ..lineTo(x, .08)
          ..lineTo(x + .04, .17)
          ..close(),
        _fill(_bone),
      );
    }
    final upper = Path()
      ..moveTo(-.18, -.1)
      ..cubicTo(-.06, -.26, .2, -.22, .46, -.08)
      ..quadraticBezierTo(.54, -.02, .46, .05)
      ..lineTo(.08, .06)
      ..lineTo(-.14, .02)
      ..close();
    c.drawPath(upper, _line(_ink, .07));
    c.drawPath(upper, _fill(_gold));
    c.drawPath(
      Path()
        ..moveTo(-.1, -.12)
        ..cubicTo(.02, -.2, .2, -.17, .38, -.08),
      _line(_goldLight, .03),
    );
    // Cheek plate with a scale, teeth on the upper lip.
    c.drawArc(
      Rect.fromCenter(center: const Offset(-.02, .06), width: .2, height: .2),
      -1.2,
      2.6,
      false,
      _line(_goldDeep, .03),
    );
    for (final x in const [.18, .32, .42]) {
      c.drawPath(
        Path()
          ..moveTo(x - .045, .05)
          ..lineTo(x, x > .3 ? .17 : .14)
          ..lineTo(x + .045, .05)
          ..close(),
        _fill(_bone),
      );
    }
    // Nostril, angry eye, a brow horn.
    c.drawOval(
      Rect.fromCenter(center: const Offset(.4, -.05), width: .065, height: .04),
      _fill(_ink),
    );
    if (fury) {
      c.drawPath(
        Path()
          ..moveTo(.42, -.06)
          ..quadraticBezierTo(.5, -.16, .44, -.26)
          ..quadraticBezierTo(.56, -.18, .5, -.06)
          ..close(),
        _fill(const Color(0xffffb23e)),
      );
    }
    final eye = Rect.fromCenter(center: const Offset(.1, -.07), width: .14, height: .11);
    c.drawOval(eye.inflate(.025), _fill(_ink));
    c.drawOval(eye, _fill(fury ? const Color(0xffffe08a) : _bone));
    c.drawCircle(const Offset(.125, -.06), .034, _fill(fury ? _fury : _ink));
    c.drawLine(const Offset(-.03, -.18), const Offset(.19, -.1), _line(_ink, .05));
    final horn = Path()
      ..moveTo(.0, -.18)
      ..quadraticBezierTo(.06, -.4, -.2, -.46)
      ..quadraticBezierTo(-.06, -.32, -.1, -.14)
      ..close();
    c.drawPath(horn, _line(_ink, .06));
    c.drawPath(horn, _fill(_bone));
    c.drawLine(const Offset(-.02, -.2), const Offset(-.06, -.36), _line(_pale, .022));
    // A curling whisker under the chin.
    final whisker = Path()
      ..moveTo(.22, .26)
      ..cubicTo(.26, .48, .52, .48, .46, .34);
    c.drawPath(whisker, _line(_ink, .075));
    c.drawPath(whisker, _line(_gold, .04));
    c.restore();
  }

  // -------------------------------------------------------------- lights --

  /// Where the warm light of the stern windows falls.
  static const windows = [Offset(2.13, .6), Offset(2.45, .6), Offset(2.96, .69)];

  // ------------------------------------------------------------- wreck --

  /// After the burst the hull splits and the wreck goes down with the sea:
  /// spray leaps and timbers fly from the break, foam rings spread, and
  /// bubbles and a little flotsam mark where it sank. [ship] is the ship's
  /// origin on screen; [h] the screen height.
  static void wreck(Canvas c, Offset ship, double h, BossMotion m) {
    final k = m.death - SkyBoss.burstAt;
    if (k < 0) return;
    final unit = h * SkyBoss.radius;
    if (m.reducedMotion) {
      // Still: the hull fades where it floated, leaving a single foam ring.
      final a = 1 - BossMotion.ramp(k, 0, .9);
      final rect = Rect.fromCenter(
        center: ship + Offset(seamX * unit, (_water - .04) * unit),
        width: unit * 5.2,
        height: unit * .6,
      );
      c.drawOval(rect, _line(_foamRim.withValues(alpha: .6 * a), unit * .13));
      c.drawOval(rect, _line(_foam.withValues(alpha: .95 * a), unit * .06));
      return;
    }
    final seamAt = ship + Offset(seamX * unit, _rail * unit);
    final level = PirateSeaArt.drawnLevel(m.boss, m);
    final t = BossMotion.ramp(k, 0, 1.1);
    if (level != null) {
      _column(c, ship, unit, k);
      _spray(c, ship, unit, k);
      _rings(c, ship, unit, k);
    }
    if (t < 1) _timbers(c, seamAt, h, unit, t);
    if (level != null) {
      _bubbles(c, ship, unit, k, level * h);
      _flotsam(c, ship, unit, k, level * h);
    }
  }

  static const _foam = Color(0xfff2fffb), _foamRim = Color(0xff8fe3dc);

  /// A crown of white water bursts up where the keel snapped: tapering
  /// jets fanned up and out.
  static void _column(Canvas c, Offset ship, double unit, double k) {
    final rise = BossMotion.ease(BossMotion.ramp(k, 0, .2));
    final fade = 1 - BossMotion.ramp(k, .3, .7);
    if (rise <= 0 || fade <= 0) return;
    final base = ship + Offset(seamX * unit, (_water - .02) * unit);
    final jets = <Path>[];
    for (var i = 0; i < 9; i++) {
      final f = (i - 4) / 4;
      final lean = f * .9;
      final hgt = unit * (1.5 + (1 - f.abs()) * 1.1 + _hash(i, 41) * .4) * rise;
      final foot = base + Offset(f * unit * .9, 0);
      final tip = foot + Offset(math.sin(lean) * hgt * .6, -math.cos(lean * .6) * hgt);
      final w = unit * (.2 + (1 - f.abs()) * .08);
      jets.add(
        Path()
          ..moveTo(foot.dx - w, foot.dy)
          ..quadraticBezierTo(foot.dx - w * .5, foot.dy - hgt * .55, tip.dx, tip.dy)
          ..quadraticBezierTo(foot.dx + w * .5, foot.dy - hgt * .5, foot.dx + w, foot.dy)
          ..close(),
      );
    }
    for (final jet in jets) {
      c.drawPath(jet, _line(_foamRim.withValues(alpha: .85 * fade), unit * .07));
    }
    for (final jet in jets) {
      c.drawPath(jet, _fill(_foam.withValues(alpha: .92 * fade)));
    }
  }

  /// The sea leaps where the keel snapped: droplets thrown up and out.
  static void _spray(Canvas c, Offset ship, double unit, double k) {
    final fade = 1 - BossMotion.ramp(k, .4, 1);
    if (fade <= 0) return;
    final origin = ship + Offset(seamX * unit, (_water - .05) * unit);
    for (var i = 0; i < 22; i++) {
      final a = -math.pi / 2 + (_hash(i, 51) - .5) * 1.8;
      final v = unit * (3 + _hash(i, 52) * 3.4);
      final at =
          origin +
          Offset(
            math.cos(a) * v * k * 1.4,
            math.sin(a) * v * k * 1.4 + unit * 7 * k * k,
          );
      final r = unit * (.06 + _hash(i, 53) * .09) * (1 - k * .4);
      c.drawCircle(at, r + unit * .03, _fill(_foamRim.withValues(alpha: .75 * fade)));
      c.drawCircle(at, r, _fill(_foam.withValues(alpha: fade)));
    }
  }

  /// Two foam rings roll out over the sea from the wreck.
  static void _rings(Canvas c, Offset ship, double unit, double k) {
    final centre = ship + Offset(seamX * unit, (_water - .04) * unit);
    for (var j = 0; j < 2; j++) {
      final r = BossMotion.ramp(k, .04 + j * .22, 1.1 + j * .3);
      if (r <= 0 || r >= 1) continue;
      final rect = Rect.fromCenter(
        center: centre,
        width: unit * (1.6 + BossMotion.ease(r) * 7),
        height: unit * (.22 + BossMotion.ease(r) * .7),
      );
      c.drawOval(rect, _line(_foamRim.withValues(alpha: .6 * (1 - r)), unit * .13));
      c.drawOval(rect, _line(_foam.withValues(alpha: .95 * (1 - r)), unit * .06));
    }
  }

  /// Timbers, gilt and a cask hurled out of the break.
  static void _timbers(
    Canvas c,
    Offset seamAt,
    double h,
    double unit,
    double t,
  ) {
    final fade = 1 - t;
    for (var i = 0; i < 16; i++) {
      final a = -math.pi / 2 + (i - 7.5) * .28;
      final v = h * (.3 + (i % 4) * .08);
      final life = t * 1.1;
      final p =
          seamAt +
          Offset(
            math.cos(a) * v * life,
            math.sin(a) * v * life + h * .9 * life * life,
          );
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(a + life * (6 + i));
      switch (i % 4) {
        case 3:
          // A scrap of gilt trim.
          final gilt = Rect.fromCenter(
            center: Offset.zero,
            width: unit * .3,
            height: unit * .07,
          );
          c.drawRect(gilt.inflate(unit * .02), _fill(_ink.withValues(alpha: fade)));
          c.drawRect(gilt, _fill(_gold.withValues(alpha: fade)));
        default:
          _timberPiece(c, unit * (.28 + (i % 3) * .14), unit * (.07 + (i % 2) * .02), fade, i);
      }
      c.restore();
    }
  }

  /// A broken plank: dark edge, lit face and a pale, splintered end.
  static void _timberPiece(Canvas c, double len, double th, double alpha, int seed) {
    final body = Path()
      ..moveTo(-len / 2, -th / 2)
      ..lineTo(len / 2 - th * .4, -th / 2)
      ..lineTo(len / 2, -th * .1)
      ..lineTo(len / 2 - th * .5, th * .1)
      ..lineTo(len / 2 + th * .1, th / 2)
      ..lineTo(-len / 2, th / 2)
      ..close();
    c.drawPath(body, _line(_ink.withValues(alpha: alpha), th * .34));
    c.drawPath(body, _fill((seed.isEven ? _wood : _woodLit).withValues(alpha: alpha)));
    c.drawLine(
      Offset(-len / 2 + th * .2, -th * .2),
      Offset(len / 2 - th, -th * .2),
      _line(_woodLit.withValues(alpha: alpha * .9), th * .16),
    );
    c.drawLine(
      Offset(len / 2 - th * .2, -th * .3),
      Offset(len / 2 - th * .05, th * .3),
      _line(_pale.withValues(alpha: alpha), th * .22),
    );
  }

  /// Bubbles well up from the sunk hull and pop at the surface.
  static void _bubbles(Canvas c, Offset ship, double unit, double k, double surface) {
    final fade = BossMotion.ramp(k, .25, .6) * (1 - BossMotion.ramp(k, 1.9, 2.7));
    if (fade <= 0) return;
    for (var i = 0; i < 16; i++) {
      final phase = ((k - .25) * (.6 + _hash(i, 61) * .4) + _hash(i, 62)) % 1;
      final x = ship.dx + (-1.2 + _hash(i, 63) * 4.6) * unit + math.sin(phase * 9 + i) * unit * .1;
      final depth = unit * (1.2 + _hash(i, 64) * 1.6);
      final y = surface - unit * .04 + depth * (1 - phase) * (1 - phase);
      final r = unit * (.045 + _hash(i, 65) * .06) * (phase > .9 ? 1.6 : 1);
      final a = fade * (phase > .9 ? (1 - phase) * 10 : 1);
      final at = Offset(x, y);
      c.drawCircle(at, r, _line(_foam.withValues(alpha: .9 * a), unit * .028));
      c.drawCircle(at, r, _fill(_foamRim.withValues(alpha: .22 * a)));
      c.drawCircle(at + Offset(-r * .35, -r * .35), r * .22, _fill(_foam.withValues(alpha: a)));
    }
  }

  /// Flotsam bobbing where the ship went down: planks and a cask.
  static void _flotsam(Canvas c, Offset ship, double unit, double k, double surface) {
    final fade = BossMotion.ramp(k, 1.3, 1.7) * (1 - BossMotion.ramp(k, 2.3, 3));
    if (fade <= 0) return;
    for (var i = 0; i < 5; i++) {
      final x = ship.dx + (-.8 + i * 1.0 + _hash(i, 71) * .5) * unit * 1.15 + k * unit * .12;
      final bob = math.sin(k * 3.2 + i * 1.7) * unit * .05;
      c.save();
      c.translate(x, surface - unit * .02 + bob);
      c.rotate(math.sin(k * 2.1 + i) * .2 + (i - 2) * .12);
      if (i == 2) {
        // A cask, bobbing low.
        final cask = Rect.fromCenter(center: Offset.zero, width: unit * .34, height: unit * .26);
        c.drawOval(cask.inflate(unit * .03), _fill(_ink.withValues(alpha: fade)));
        c.drawOval(cask, _fill(_wood.withValues(alpha: fade)));
        for (final dx in const [-.08, .08]) {
          c.drawLine(
            Offset(unit * dx, -unit * .12),
            Offset(unit * dx, unit * .12),
            _line(_iron.withValues(alpha: fade), unit * .035),
          );
        }
      } else {
        _timberPiece(c, unit * (.42 + (i % 2) * .16), unit * .08, fade, i);
      }
      c.restore();
      // A ring of foam around each piece.
      c.drawOval(
        Rect.fromCenter(center: Offset(x, surface + bob * .4 + unit * .04), width: unit * .9, height: unit * .14),
        _line(_foam.withValues(alpha: .55 * fade), unit * .04),
      );
    }
  }
}

/// The hull's timber, built once: tone patches, grain, seams, joints,
/// nails and knots, all in rig units.
class _Timber {
  _Timber._(
    this.dark,
    this.light,
    this.grain,
    this.grainLight,
    this.seams,
    this.joints,
    this.nails,
    this.knots,
  );

  final Path dark, light, grain, grainLight, seams, joints, nails;
  final List<(Offset, double)> knots;

  static _Timber _build() {
    final dark = Path(), light = Path(), grain = Path(), grainLight = Path();
    final seams = Path(), joints = Path(), nails = Path();
    final knots = <(Offset, double)>[];
    double sag(double x) => PirateHullArt._sag(x);
    const rows = [
      (PirateShipArt.rail + .0, 1.02),
      (1.34, 1.51),
      (1.51, 1.68),
      (1.68, PirateShipArt.waterline),
    ];
    for (var r = 0; r < rows.length; r++) {
      final (y0, y1) = rows[r];
      final hgt = y1 - y0;
      var x = -2.75 - PirateHullArt._hash(r, 1) * 1.1;
      var i = 0;
      while (x < 3.4) {
        final len = .9 + PirateHullArt._hash(r * 10 + i, 2) * .7;
        final a = math.max(x, -2.7), b = math.min(x + len, 3.4);
        if (b > a) {
          final tone = PirateHullArt._hash(r * 10 + i, 3);
          final seg = Path()
            ..moveTo(a, y0 + sag(a))
            ..lineTo(b, y0 + sag(b))
            ..lineTo(b, y1 + sag(b))
            ..lineTo(a, y1 + sag(a))
            ..close();
          if (tone > .6) {
            dark.addPath(seg, Offset.zero);
          } else if (tone < .3) {
            light.addPath(seg, Offset.zero);
          }
          // Grain: long, slightly wavy strokes with a highlight beneath.
          for (var g = 0; g < 2; g++) {
            final gy = y0 + hgt * (.3 + g * .4 + PirateHullArt._hash(r * 10 + i, 5 + g) * .12);
            final wob = (PirateHullArt._hash(r * 10 + i, 7 + g) - .5) * .03;
            final ga = a + .08 + PirateHullArt._hash(i, g + 11) * .2;
            final gb = b - .08 - PirateHullArt._hash(i, g + 13) * .2;
            if (gb > ga) {
              grain
                ..moveTo(ga, gy + sag(ga))
                ..quadraticBezierTo((ga + gb) / 2, gy + wob + sag((ga + gb) / 2), gb, gy + sag(gb));
              grainLight
                ..moveTo(ga + .04, gy + .022 + sag(ga))
                ..quadraticBezierTo(
                  (ga + gb) / 2,
                  gy + wob + .022 + sag((ga + gb) / 2),
                  gb - .06,
                  gy + .022 + sag(gb),
                );
            }
          }
          // Butt joint and treenails at the strake's start.
          if (a == x && a > -2.6) {
            joints
              ..moveTo(a, y0 + sag(a))
              ..lineTo(a + .015, y1 + sag(a));
            for (final ny in [y0 + hgt * .28, y0 + hgt * .72]) {
              nails.addOval(Rect.fromCircle(center: Offset(a + .07, ny + sag(a)), radius: .014));
            }
          }
          if (PirateHullArt._hash(r * 10 + i, 17) > .72 && b - a > .5) {
            knots.add((
              Offset((a + b) / 2 + (PirateHullArt._hash(i, r) - .5) * .3, y0 + hgt * .5 + sag((a + b) / 2)),
              .04 + PirateHullArt._hash(r, i) * .02,
            ));
          }
        }
        x += len;
        i++;
      }
      if (r > 0) {
        seams
          ..moveTo(-2.9, y0 + sag(-2.9))
          ..quadraticBezierTo(.25, y0 + 2 * sag(.25) - (sag(-2.9) + sag(3.4)) / 2, 3.4, y0 + sag(3.4));
      }
    }
    return _Timber._(dark, light, grain, grainLight, seams, joints, nails, knots);
  }
}
