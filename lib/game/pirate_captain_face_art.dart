import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import 'pirate_boss_rig.dart' show PirateBossRig;

/// What the Pirate Captain's face is doing, straight from the boss clock.
///
/// Every channel is a pure function of `SkyBoss` and `BossMotion`, so the face
/// seeks exactly. Channels that are motion (rather than expression) arrive as
/// zero under Reduced Motion, which is how the caller keeps it still.
final class PirateFaceState {
  const PirateFaceState({
    this.time = 0,
    this.aim = 0,
    this.charge = 0,
    this.recoil = 0,
    this.roar = 0,
    this.wince = 0,
    this.blink = 0,
    this.fury = 0,
    this.tide = 0,
    this.dizzy = false,
    this.jiggle = 0,
    this.braid = 0,
    this.talk = 0,
    this.mood,
  });

  /// Seconds on the boss clock (0 when the face must sit still).
  final double time;

  /// Where he looks: -1 up, 1 down.
  final double aim;
  final double charge, recoil, roar, wince, blink, fury, tide;
  final bool dizzy;

  /// Swing of the earring and of the braids.
  final double jiggle, braid;

  /// How far the words of a line he is saying open his mouth, 0 to 1, and
  /// that line's mood (null in silence).
  final double talk;
  final StoryMood? mood;

  /// How far the mouth is thrown open by a bellow, the shot, the tide call
  /// or his words.
  double get shout =>
      math.max(math.max(roar, talk), math.max(recoil * .9, tide * .55));

  /// How hard he glares: the enraged scowl, the aim before a shot, or an
  /// angry line.
  double get glare => dizzy
      ? 0
      : math.max(
          math.max(fury, charge * .85),
          mood == StoryMood.angry ? .9 : 0,
        );

  /// His eye thrown open: the roar, or a startled line.
  double get wide => math.max(roar, mood == StoryMood.surprised ? .7 : 0);

  /// Where he looks (-1 up, 1 down): toward the bird, or at his boots in a
  /// sorry line.
  double get look {
    final down = switch (mood) {
      StoryMood.sad => .9,
      StoryMood.surprised => -.3,
      _ => 0.0,
    };
    return (aim + down).clamp(-1.0, 1.0);
  }

  /// Teeth bared and clenched.
  double get snarl => dizzy ? 0 : math.max(charge, fury * .6) * (1 - shout);

  /// The flinch after a hit.
  double get ouch => dizzy ? 0 : wince * (1 - roar);
}

/// The Pirate Captain's head, drawn around the origin of his head frame in a
/// three-quarter view turned toward the bird on the left: a weathered face
/// under the hat, the far eye following the bird and the near one patched, a
/// scarred near cheek, a sunburnt nose jutting past the far cheek, a waxed
/// handlebar mustache, a grin with one long gold tooth, and a braided beard
/// hung with gold that wraps the jaw back to the ear.
///
/// He stands with a torch at his left (the bird's side), a parrot at his
/// right shoulder and a big hat over the brow, so the face is built to read
/// in the window between the brim and the beard.
abstract final class PirateCaptainFaceArt {
  static const _ink = PirateBossRig.ink;
  static const _gold = PirateBossRig.gold;
  static const _bone = PirateBossRig.bone;
  static const _goldDeep = Color(0xffc9862b), _goldLight = Color(0xfffff0b4);
  static const _skin = Color(0xfff6bd97), _skinLit = Color(0xffffdcbc);
  static const _skinShade = Color(0xffd68c6c), _skinDeep = Color(0xffa85c4c);
  static const _blush = Color(0xffea7468), _ember = Color(0xffff5a3a);
  static const _hair = Color(0xff3e3b5a), _hairLit = Color(0xff7a77a0);
  static const _hairDeep = Color(0xff24223a), _hairSheen = Color(0xffb1aed8);
  static const _crimson = Color(0xffc53b4d), _crimsonDeep = Color(0xff7c2238);
  static const _leather = Color(0xff262034), _leatherLit = Color(0xff5a4a66);
  static const _mouthDark = Color(0xff3a1520), _tongue = Color(0xffd0566c);
  static const _torch = Color(0xffffb347);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Shapes and shaders that never change are built once.

  /// The head turned toward the bird: the brow ridge, cheekbone and cheek
  /// make the far contour on the left, the round back of the skull and the
  /// jaw the near one on the right.
  static final Path _head = Path()
    ..moveTo(-.62, -.84)
    ..cubicTo(-.64, -1.14, .34, -1.16, .36, -.8)
    ..cubicTo(.42, -.6, .4, -.36, .3, -.22)
    ..cubicTo(.22, -.06, .02, .08, -.24, .1)
    ..quadraticBezierTo(-.46, .12, -.58, .02)
    ..cubicTo(-.66, -.1, -.64, -.22, -.67, -.32)
    ..quadraticBezierTo(-.72, -.4, -.74, -.5)
    ..quadraticBezierTo(-.76, -.6, -.7, -.7)
    ..quadraticBezierTo(-.64, -.8, -.62, -.84)
    ..close();

  /// The bandana under the hat: a crimson scarf across the crown.
  static final Path _band = Path()
    ..moveTo(-.8, -1.3)
    ..lineTo(.5, -1.3)
    ..lineTo(.5, -.72)
    ..quadraticBezierTo(-.1, -.92, -.8, -.7)
    ..close();
  static final Path _bandEdge = Path()
    ..moveTo(.5, -.72)
    ..quadraticBezierTo(-.1, -.92, -.8, -.7);

  /// The side of the head, from the cheekbone back to the ear, turned away
  /// from the torch.
  static final Path _sidePlane = Path()
    ..moveTo(-.02, -.9)
    ..cubicTo(-.07, -.62, -.05, -.4, .03, -.22)
    ..lineTo(.5, -.22)
    ..lineTo(.5, -.9)
    ..close();

  static final ui.Shader _skinShader = ui.Gradient.linear(
    const Offset(-.7, -.86),
    const Offset(.4, .0),
    const [_skinLit, _skin, _skinShade],
    const [0, .46, 1],
  );
  static final ui.Shader _hatShadow = ui.Gradient.linear(
    const Offset(0, -.72),
    const Offset(0, -.56),
    [_ink.withValues(alpha: .3), _ink.withValues(alpha: 0)],
  );
  static final ui.Shader _bandShader = ui.Gradient.linear(
    const Offset(-.6, -1.1),
    const Offset(.3, -.7),
    const [Color(0xffe8636b), _crimson, _crimsonDeep],
    const [0, .5, 1],
  );
  static final ui.Shader _beardShader = ui.Gradient.linear(
    const Offset(-.84, -.1),
    const Offset(.3, .7),
    const [_hairLit, _hair, _hairDeep],
    const [0, .45, 1],
  );
  static final ui.Shader _beardGlow = ui.Gradient.radial(
    const Offset(-.56, .22),
    .3,
    [_hairLit.withValues(alpha: .4), _hairLit.withValues(alpha: 0)],
  );
  static final ui.Shader _stacheShader = ui.Gradient.linear(
    const Offset(-.8, -.3),
    const Offset(-.1, -.05),
    const [_hairSheen, _hairLit, _hair],
    const [0, .35, 1],
  );
  static final ui.Shader _patchShader = ui.Gradient.linear(
    const Offset(-.34, -.6),
    const Offset(.02, -.3),
    const [_leatherLit, _leather, Color(0xff181322)],
    const [0, .45, 1],
  );

  /// The face, back to front. [PirateFaceState] carries every expression
  /// channel; the caller has already moved and tilted the head.
  static void paint(Canvas c, PirateFaceState s) {
    _skull(c, s);
    _ear(c);
    _beardBack(c, s);
    _earring(c, s);
    _braids(c, s);
    _cheeks(c, s);
    _scar(c);
    _eye(c, s);
    _patch(c, s);
    _mouth(c, s);
    _mustache(c, s);
    _nose(c, s);
    _brows(c, s);
    // An angry line pops the vein too; a sorry one breaks a sweat.
    if (s.fury > 0 || (s.mood == StoryMood.angry && !s.dizzy)) _vein(c, s);
    if (s.mood == StoryMood.sad && !s.dizzy) _sweat(c);
  }

  // --------------------------------------------------------- head & skin --

  static void _skull(Canvas c, PirateFaceState s) {
    c.drawPath(_head, _line(_ink, .12));
    c.drawPath(_head, Paint()..shader = _skinShader);
    c.save();
    c.clipPath(_head);
    // The crimson bandana shows when the hat lifts or is knocked off.
    c.drawPath(_band, Paint()..shader = _bandShader);
    for (final (x, y) in const [
      (-.44, -.92),
      (-.2, -.95),
      (.04, -.95),
      (.26, -.92),
      (-.32, -.84),
      (-.08, -.86),
      (.16, -.84),
    ]) {
      c.drawCircle(Offset(x, y), .022, _fill(_bone.withValues(alpha: .8)));
    }
    c.drawPath(_bandEdge, _line(_ink, .06));
    c.drawPath(
      _bandEdge.shift(const Offset(0, -.03)),
      _line(_crimsonDeep.withValues(alpha: .6), .02),
    );
    // The hat throws a shadow across the brow.
    c.drawRect(
      const Rect.fromLTRB(-1, -.76, .5, -.5),
      Paint()..shader = _hatShadow,
    );
    // A weathered flush across the near cheek, under the patch.
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.16, -.24), width: .3, height: .16),
      _fill(_blush.withValues(alpha: .3 + s.fury * .35)),
    );
    // Cel shading: a crisp form shadow over the side of the head, and the
    // torch-lit near cheekbone.
    c.drawPath(_sidePlane, _fill(_skinShade.withValues(alpha: .34)));
    c.drawArc(
      Rect.fromCenter(center: const Offset(-.25, -.26), width: .18, height: .1),
      3.4,
      2.0,
      false,
      _line(_skinLit.withValues(alpha: .75), .03),
    );
    if (s.fury > 0) {
      c.drawPath(
        _head,
        _fill(const Color(0xffe8384f).withValues(alpha: .3 * s.fury)),
      );
    }
    // The torch lights the far contour warm.
    c.drawPath(
      Path()
        ..moveTo(-.66, -.76)
        ..quadraticBezierTo(-.78, -.6, -.72, -.44)
        ..quadraticBezierTo(-.68, -.34, -.66, -.2),
      _line(_torch.withValues(alpha: .38), .05),
    );
    c.restore();
  }

  static const _earRect = Rect.fromLTRB(.18, -.53, .33, -.27);

  /// The near ear, set well back on the side of the head.
  static void _ear(Canvas c) {
    c.drawOval(_earRect.inflate(.03), _fill(_ink));
    c.drawOval(_earRect, _fill(_skinShade));
    // The rim runs round the back; the bowl opens toward the face.
    c.drawArc(_earRect.deflate(.04), -1.9, 3.5, false, _line(_blush, .026));
    c.drawCircle(const Offset(.23, -.4), .022, _fill(_skinDeep));
  }

  /// A gold hoop in the lobe, swaying with his head.
  static void _earring(Canvas c, PirateFaceState s) {
    final hoop = Offset(.26, -.2 + s.jiggle * .3);
    c.drawCircle(hoop, .075, _line(_ink, .065));
    c.drawCircle(hoop, .075, _line(_gold, .036));
    c.drawArc(
      Rect.fromCircle(center: hoop, radius: .075),
      3.5,
      1.3,
      false,
      _line(_goldLight, .014),
    );
  }

  static void _cheeks(Canvas c, PirateFaceState s) {
    final crease = _skinDeep.withValues(alpha: .38);
    // The bag under his good eye.
    c.drawArc(
      Rect.fromCenter(center: const Offset(-.59, -.38), width: .2, height: .07),
      .35,
      2.4,
      false,
      _line(crease, .022),
    );
    // A laugh line round the nostril and down past the mustache.
    c.drawPath(
      Path()
        ..moveTo(-.36, -.26)
        ..quadraticBezierTo(-.29, -.2, -.28, -.1),
      _line(crease, .025),
    );
    // Stubble.
    c.drawPoints(
      ui.PointMode.points,
      _stubble,
      _line(_hairDeep.withValues(alpha: .5), .014),
    );
  }

  static const _stubble = [
    Offset(-.1, -.14),
    Offset(-.06, -.19),
    Offset(-.02, -.12),
    Offset(.05, -.18),
    Offset(-.07, -.08),
    Offset(.02, -.24),
  ];

  /// An old cutlass scar from under the patch down the near cheek,
  /// stitched with three ticks.
  static void _scar(Canvas c) {
    final scar = Path()
      ..moveTo(-.02, -.36)
      ..quadraticBezierTo(.0, -.26, -.01, -.18)
      ..quadraticBezierTo(-.02, -.14, .0, -.1);
    c.drawPath(scar, _line(_skinDeep, .042));
    c.drawPath(scar, _line(const Color(0xffefa898), .022));
    for (final (x, y) in const [(-.008, -.3), (-.004, -.23), (-.012, -.16)]) {
      c.drawLine(
        Offset(x - .035, y - .01),
        Offset(x + .035, y + .01),
        _line(_skinDeep, .016),
      );
    }
  }

  // --------------------------------------------------------------- beard --

  /// Glossy lights on the locks of the beard, following the hair.
  static final List<Path> _lockLights = [
    for (final (pts, width) in const [
      (
        [
          Offset(-.68, .06),
          Offset(-.74, .2),
          Offset(-.72, .36),
          Offset(-.66, .5),
        ],
        .08,
      ),
      (
        [
          Offset(-.46, .12),
          Offset(-.5, .3),
          Offset(-.46, .48),
          Offset(-.44, .64),
        ],
        .09,
      ),
      (
        [
          Offset(-.16, .06),
          Offset(-.2, .24),
          Offset(-.18, .42),
          Offset(-.16, .56),
        ],
        .08,
      ),
    ])
      _ribbon(_spline(pts, 5), (t) => width * (1 - t * .9)),
  ];

  static double _jaw(PirateFaceState s) => s.shout * .05 + (s.dizzy ? .02 : 0);

  /// The beard: from under the ear it wraps the jaw to the chin, hangs in
  /// four locks, and frames the grin with a mouth-side edge. The jaw drops
  /// [jaw] and pulls the beard with it; its roots under the ear stay put.
  static Path _beard(double jaw) {
    Offset p(double x, double y) =>
        Offset(x, y + jaw * ((y + .3) / .3).clamp(0.0, 1.0));
    final path = Path();
    void quad(double cx, double cy, double x, double y) {
      final a = p(cx, cy), b = p(x, y);
      path.quadraticBezierTo(a.dx, a.dy, b.dx, b.dy);
    }

    void cubic(double ax, double ay, double bx, double by, double x, double y) {
      final a = p(ax, ay), b = p(bx, by), q = p(x, y);
      path.cubicTo(a.dx, a.dy, b.dx, b.dy, q.dx, q.dy);
    }

    path.moveTo(.12, -.24);
    quad(.2, -.31, .26, -.22);
    quad(.3, -.14, .28, -.04);
    cubic(.29, .14, .28, .3, .2, .42);
    quad(.2, .54, .1, .54);
    quad(.02, .52, -.02, .46);
    quad(-.04, .66, -.16, .68);
    quad(-.26, .66, -.3, .58);
    quad(-.34, .76, -.46, .76);
    quad(-.56, .74, -.6, .6);
    quad(-.64, .66, -.72, .6);
    quad(-.8, .5, -.76, .36);
    quad(-.84, .3, -.8, .18);
    quad(-.84, .1, -.78, .04);
    quad(-.73, .0, -.64, .0);
    quad(-.48, .16, -.26, .03);
    cubic(-.14, -.04, .0, -.1, .08, -.18);
    quad(.1, -.22, .12, -.24);
    return path..close();
  }

  static void _beardBack(Canvas c, PirateFaceState s) {
    final jaw = _jaw(s);
    final beard = _beard(jaw);
    c.drawPath(beard, _line(_ink, .12));
    c.drawPath(beard, Paint()..shader = _beardShader);
    c.save();
    c.clipPath(beard);
    // The side of the jaw, away from the torch, sinks into shade.
    c.drawPath(
      Path()
        ..moveTo(.06, -.9)
        ..cubicTo(.08, -.2, .02, .3, -.06, .8)
        ..lineTo(.5, .8)
        ..lineTo(.5, -.9)
        ..close(),
      _fill(_hairDeep.withValues(alpha: .4)),
    );
    c.translate(0, jaw);
    // Dark grooves between the locks, and glossy lights that follow the
    // fall of the hair.
    for (final (a, b, e) in const [
      (Offset(-.6, .1), Offset(-.66, .34), Offset(-.6, .56)),
      (Offset(-.3, .06), Offset(-.34, .34), Offset(-.3, .56)),
      (Offset(.04, -.08), Offset(.0, .24), Offset(-.02, .44)),
    ]) {
      final groove = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(b.dx, b.dy, e.dx, e.dy);
      c.drawPath(groove, _line(_hairDeep, .055));
    }
    for (final lit in _lockLights) {
      c.drawPath(lit, _fill(const Color(0xff67648f).withValues(alpha: .8)));
    }
    // A silver streak from the corner of the mouth.
    c.drawPath(
      Path()
        ..moveTo(-.7, .06)
        ..quadraticBezierTo(-.77, .19, -.71, .32),
      _line(const Color(0xffd5d4ea).withValues(alpha: .8), .024),
    );
    // A soft light on the torch side of the beard.
    c.drawCircle(const Offset(-.56, .22), .3, Paint()..shader = _beardGlow);
    c.restore();
  }

  /// Two braids tied off with gold: a doubloon and a red bead.
  static void _braids(Canvas c, PirateFaceState s) {
    final jaw = _jaw(s);
    for (final (x, len, second) in const [
      (-.46, .22, false),
      (-.18, .19, true),
    ]) {
      final top = Offset(x, .5 + jaw);
      final tip = Offset(x + s.braid * (second ? 1.2 : 1), .5 + len + jaw);
      final mid = Offset(x - .02, top.dy + len * .5);
      Offset at(double t) =>
          top * ((1 - t) * (1 - t)) + mid * (2 * (1 - t) * t) + tip * (t * t);
      final braid = Path()..moveTo(top.dx, top.dy);
      for (var i = 1; i <= 8; i++) {
        final p = at(i / 8 * .9);
        braid.lineTo(p.dx, p.dy);
      }
      c.drawPath(braid, _line(_ink, .17));
      c.drawPath(braid, _line(_hair, .11));
      // Plaits: a chevron for every twist.
      final plaits = Path();
      for (var i = 0; i < 3; i++) {
        final p = at(.14 + i * .24);
        plaits
          ..moveTo(p.dx - .045, p.dy - .03)
          ..lineTo(p.dx, p.dy + .02)
          ..lineTo(p.dx + .045, p.dy - .03);
      }
      c.drawPath(plaits, _line(_hairLit, .024));
      final ring = at(.82);
      c.drawOval(
        Rect.fromCenter(center: ring, width: .17, height: .09),
        _fill(_ink),
      );
      c.drawOval(
        Rect.fromCenter(center: ring, width: .13, height: .06),
        _fill(_gold),
      );
      // The loose tail of hair ends in a doubloon or a bead.
      final end = at(.9);
      final tail = Path();
      for (final k in const [-1.0, 0.0, 1.0]) {
        tail
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx + k * .04, end.dy + .075);
      }
      c.drawPath(tail, _line(_ink, .06));
      c.drawPath(tail, _line(_hair, .03));
      final bead = end + const Offset(0, .1);
      c.drawCircle(bead, .062, _fill(_ink));
      c.drawCircle(bead, .045, _fill(second ? _crimson : _gold));
      c.drawCircle(bead + const Offset(-.014, -.014), .014, _fill(_goldLight));
    }
  }

  // ----------------------------------------------------------------- eye --

  /// His good eye, the far one, set beside the bridge of the nose. It looks
  /// along his turn toward the bird, so the iris rides in the front corner
  /// and slides up and down with the aim.
  static void _eye(Canvas c, PirateFaceState s) {
    const e = PirateBossRig.eyeCenter;
    // A wide almond, a touch narrower for the turn, that the roar throws
    // open.
    final kx = .98 + s.wide * .06, ky = 1.08 + s.wide * .4;
    Offset q(double dx, double dy) => e + Offset(dx * kx, dy * ky);
    final almond = Path()
      ..moveTo(q(-.135, .02).dx, q(-.135, .02).dy)
      ..cubicTo(
        q(-.09, -.15).dx,
        q(-.09, -.15).dy,
        q(.07, -.16).dx,
        q(.07, -.16).dy,
        q(.135, -.01).dx,
        q(.135, -.01).dy,
      )
      ..cubicTo(
        q(.07, .12).dx,
        q(.07, .12).dy,
        q(-.09, .13).dx,
        q(-.09, .13).dy,
        q(-.135, .02).dx,
        q(-.135, .02).dy,
      )
      ..close();
    final top = q(0, -.115).dy, bottom = q(0, .095).dy;
    if (s.dizzy) {
      // Knocked silly: a spiral where the eye was.
      final spiral = Path()..moveTo(e.dx, e.dy);
      for (var i = 1; i <= 24; i++) {
        final t = i / 24;
        final a = t * math.pi * 4.4;
        spiral.lineTo(e.dx + math.cos(a) * .1 * t, e.dy + math.sin(a) * .1 * t);
      }
      c.drawPath(almond, _line(_ink, .1));
      c.drawPath(almond, _fill(_bone));
      c.drawPath(spiral, _line(_ink, .03));
      return;
    }
    final ouch = s.ouch;
    if (ouch > .45) {
      // Squeezed shut: > pointing at the nose, with creases around it.
      final chevron = Path()
        ..moveTo(e.dx - .1, e.dy - .1)
        ..lineTo(e.dx + .07, e.dy + .01)
        ..lineTo(e.dx - .1, e.dy + .12);
      c.drawPath(chevron, _line(_ink, .07));
      c.drawLine(
        e + const Offset(.1, -.1),
        e + const Offset(.05, -.07),
        _line(_skinDeep, .025),
      );
      c.drawLine(
        e + const Offset(.1, .12),
        e + const Offset(.05, .08),
        _line(_skinDeep, .025),
      );
      return;
    }
    final fury = s.fury > 0;
    final glare = s.glare;
    // The lid: half-lowered and smug at rest, a slit in a glare, shut in a
    // blink, wide open in the roar.
    final lookLid = s.look > 0 ? s.look * .1 : s.look * .05;
    final lid = (math.max(.13 + glare * .3 + lookLid, s.blink) * (1 - s.wide))
        .clamp(0.0, 1.0);
    if (lid > .9) {
      // A blink: the closed lid curves like a smile.
      c.drawPath(
        Path()
          ..moveTo(e.dx - .13, e.dy + .01)
          ..quadraticBezierTo(e.dx, e.dy + .1, e.dx + .13, e.dy - .01),
        _line(_ink, .055),
      );
      return;
    }
    c.drawPath(almond, _line(_ink, .058));
    c.drawPath(almond, _fill(fury ? const Color(0xffffe1c4) : _bone));
    c.save();
    c.clipPath(almond);
    final drift = s.time == 0 ? 0.0 : math.sin(s.time * .9) * .006;
    final pupil =
        e + Offset(-.058 + s.look.abs() * .006 + drift, s.look * .045);
    final irisR = .078 - s.wide * .012;
    // Turned toward the corner, the iris narrows a little.
    Rect round(double r) =>
        Rect.fromCenter(center: pupil, width: r * 1.8, height: r * 2);
    c.drawOval(
      round(irisR),
      _fill(fury ? const Color(0xff8c2320) : const Color(0xff6b3a1c)),
    );
    c.drawOval(
      round(irisR - .014),
      _fill(fury ? _ember : const Color(0xffd08a35)),
    );
    if (glare > .5) {
      c.drawOval(
        Rect.fromCenter(center: pupil, width: .045, height: .12),
        _fill(_ink),
      );
    } else {
      c.drawOval(round(.04 - s.wide * .012), _fill(_ink));
    }
    c.drawCircle(pupil + const Offset(-.022, -.03), .026, _fill(_bone));
    c.drawCircle(
      pupil + const Offset(.022, .028),
      .011,
      _fill(_bone.withValues(alpha: .85)),
    );
    if (fury) {
      for (final (a, b) in const [
        (Offset(.11, -.05), Offset(.06, -.03)),
        (Offset(.12, .03), Offset(.07, .02)),
        (Offset(.08, .07), Offset(.04, .04)),
      ]) {
        c.drawLine(e + a, e + b, _line(const Color(0xffe0524a), .014));
      }
    }
    // The socket shades the top of the eye.
    c.drawOval(
      Rect.fromCenter(center: Offset(e.dx, top - .045), width: .4, height: .17),
      _fill(_skinShade.withValues(alpha: .35)),
    );
    if (lid > .01) {
      final edge = top + (bottom - top) * lid;
      final slope = glare * .05;
      final l = Offset(e.dx - .17, edge + slope);
      final r = Offset(e.dx + .17, edge - slope * .6);
      final lidEdge = Path()
        ..moveTo(l.dx, l.dy)
        ..quadraticBezierTo(e.dx, edge + .02 + slope * .3, r.dx, r.dy);
      c.drawPath(
        Path.from(lidEdge)
          ..lineTo(r.dx, top - .1)
          ..lineTo(l.dx, top - .1)
          ..close(),
        _fill(Color.lerp(_skin, _skinShade, .55)!),
      );
      c.drawPath(lidEdge, _line(_ink, .05));
    }
    c.restore();
    // The lid line is a bold stroke, the lower rim a light one.
    c.drawPath(almond, _line(_ink, .034));
  }

  // --------------------------------------------------------------- patch --

  /// The patch over the near eye, broad on the cheek that faces us. Its
  /// strap climbs the brow under the hat and runs back over the ear.
  static void _patch(Canvas c, PirateFaceState s) {
    final strap = Path()
      ..moveTo(-.33, -.56)
      ..quadraticBezierTo(-.38, -.66, -.46, -.8)
      ..moveTo(-.03, -.5)
      ..quadraticBezierTo(.16, -.6, .41, -.6);
    c.drawPath(strap, _line(_ink, .058));
    c.drawPath(strap, _line(_leather, .03));
    c.drawPath(strap, _line(_leatherLit.withValues(alpha: .8), .012));
    c.drawPath(_patchShape, _line(_ink, .045));
    c.drawPath(_patchShape, Paint()..shader = _patchShader);
    // Stitched hem, a brass rivet and a lit crease across the leather.
    c.drawPath(_hem, _line(_leatherLit, .012));
    c.drawCircle(const Offset(-.3, -.5), .02, _fill(_goldDeep));
    c.drawCircle(const Offset(-.306, -.506), .008, _fill(_goldLight));
    c.drawPath(
      Path()
        ..moveTo(-.25, -.53)
        ..quadraticBezierTo(-.16, -.57, -.07, -.53),
      _line(_leatherLit, .026),
    );
  }

  static final Path _patchShape = Path()
    ..moveTo(-.35, -.55)
    ..quadraticBezierTo(-.19, -.63, -.02, -.54)
    ..quadraticBezierTo(.02, -.34, -.17, -.28)
    ..quadraticBezierTo(-.36, -.31, -.35, -.55)
    ..close();

  static final Path _hem = _dashed(
    Path()
      ..moveTo(-.3, -.51)
      ..quadraticBezierTo(-.19, -.58, -.06, -.51)
      ..quadraticBezierTo(-.03, -.37, -.17, -.32)
      ..quadraticBezierTo(-.31, -.35, -.3, -.51),
    .03,
    .02,
  );

  /// [path] broken into dashes [dash] long with [gap] between them.
  static Path _dashed(Path path, double dash, double gap) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        out.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
      }
    }
    return out;
  }

  // --------------------------------------------------------------- brows --

  static void _brows(Canvas c, PirateFaceState s) {
    // Thick brows that knit down at the nose in a glare and after a hit,
    // jump up in the roar, and slump when he is dazed. The far one arches
    // over his good eye, shorter for the turn; the near one is cocked over
    // the patch.
    // A sorry line tips them up at the nose instead.
    final knit =
        s.glare * .07 + s.ouch * .06 - (s.mood == StoryMood.sad ? .07 : 0);
    final lift = s.wide * .08 + s.tide * .03 + (s.aim < 0 ? -s.aim * .02 : 0);
    final daze = s.dizzy ? 1.0 : 0.0;
    final flat = s.glare * .5;
    final brows = <(List<Offset>, double Function(double))>[];
    for (final (l, r, arch, cock, width) in [
      (
        Offset(-.73, -.61 - lift - s.glare * .02 + daze * .03),
        Offset(-.44, -.645 + knit - lift * .8 - daze * .02),
        .045 * (1 - flat),
        0.0,
        (double t) => .09 * (.45 + t * .55),
      ),
      (
        Offset(-.33, -.61 + knit * .9 - lift * .8 - daze * .02),
        Offset(-.01, -.655 - lift - s.glare * .02 + daze * .03),
        .04 * (1 - flat),
        .022 * (1 - s.glare),
        (double t) => .09 * (1 - t * .6),
      ),
    ]) {
      final pts = <Offset>[];
      for (var i = 0; i <= 8; i++) {
        final t = i / 8;
        pts.add(
          Offset.lerp(l, r, t)! + Offset(0, -arch * 4 * t * (1 - t) - cock * t),
        );
      }
      brows.add((pts, width));
    }
    final shapes = [
      for (final (pts, width) in brows) _ribbon(pts, width, fuzz: .006),
    ];
    for (final b in shapes) {
      c.drawPath(b, _line(_ink, .05));
    }
    for (final b in shapes) {
      c.drawPath(b, _fill(_hair));
    }
    for (final (pts, _) in brows) {
      final sheen = Path()..moveTo(pts[1].dx, pts[1].dy - .02);
      for (var i = 2; i <= 5; i++) {
        sheen.lineTo(pts[i].dx, pts[i].dy - .025);
      }
      c.drawPath(sheen, _line(_hairLit.withValues(alpha: .7), .014));
    }
  }

  static Path _ribbon(
    List<Offset> pts,
    double Function(double t) width, {
    double fuzz = 0,
  }) {
    final top = <Offset>[], bottom = <Offset>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[math.max(i - 1, 0)];
      final b = pts[math.min(i + 1, pts.length - 1)];
      final d = b - a;
      final n = d.distance == 0
          ? Offset.zero
          : Offset(d.dy, -d.dx) / d.distance;
      final w = width(i / (pts.length - 1)) / 2;
      top.add(pts[i] + n * (w + (i.isOdd ? fuzz : 0)));
      bottom.add(pts[i] - n * w);
    }
    return Path()..addPolygon([...top, ...bottom.reversed], true);
  }

  static List<Offset> _spline(List<Offset> p, int perSegment) {
    final out = <Offset>[];
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = p[math.max(i - 1, 0)], p1 = p[i], p2 = p[i + 1];
      final p3 = p[math.min(i + 2, p.length - 1)];
      for (var j = 0; j < perSegment; j++) {
        final t = j / perSegment, t2 = t * t, t3 = t2 * t;
        out.add(
          (p1 * 2 +
                  (p2 - p0) * t +
                  (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2 +
                  (p1 * 3 - p0 - p2 * 3 + p3) * t3) *
              .5,
        );
      }
    }
    out.add(p.last);
    return out;
  }

  // ---------------------------------------------------------------- nose --

  /// A big sunburnt nose: the bridge drops from the brow between the good
  /// eye and the patch, and the bulb juts out past the far cheek toward the
  /// bird.
  static final Path _noseFill = Path()
    ..moveTo(-.4, -.58)
    ..cubicTo(-.41, -.5, -.42, -.42, -.47, -.36)
    ..cubicTo(-.54, -.33, -.66, -.36, -.74, -.3)
    ..cubicTo(-.81, -.24, -.8, -.1, -.72, -.09)
    ..cubicTo(-.66, -.08, -.62, -.12, -.57, -.1)
    ..cubicTo(-.51, -.06, -.42, -.08, -.41, -.15)
    ..cubicTo(-.4, -.22, -.38, -.26, -.37, -.34)
    ..quadraticBezierTo(-.36, -.48, -.4, -.58)
    ..close();

  /// The ink runs down the bridge, round the tip and the near nostril wing;
  /// the near side of the bridge is left to the shading.
  static final Path _noseEdge = Path()
    ..moveTo(-.4, -.56)
    ..cubicTo(-.41, -.5, -.42, -.42, -.47, -.36)
    ..cubicTo(-.54, -.33, -.66, -.36, -.74, -.3)
    ..cubicTo(-.81, -.24, -.8, -.1, -.72, -.09)
    ..cubicTo(-.66, -.08, -.62, -.12, -.57, -.1)
    ..cubicTo(-.51, -.06, -.43, -.08, -.415, -.13);

  /// The shaded near side of the nose, away from the torch.
  static final Path _noseShade = Path()
    ..moveTo(-.38, -.62)
    ..cubicTo(-.41, -.44, -.45, -.3, -.5, -.02)
    ..lineTo(-.3, -.02)
    ..lineTo(-.3, -.62)
    ..close();

  static final ui.Shader _noseShader = ui.Gradient.radial(
    const Offset(-.68, -.24),
    .24,
    [
      _skinLit,
      Color.lerp(_skin, _blush, .5)!,
      Color.lerp(_skinShade, _blush, .6)!,
    ],
    const [0, .55, 1],
  );

  static void _nose(Canvas c, PirateFaceState s) {
    // It casts a soft shadow on the near cheek.
    c.drawOval(
      Rect.fromCenter(center: const Offset(-.34, -.16), width: .12, height: .16),
      _fill(_skinDeep.withValues(alpha: .18)),
    );
    c.drawPath(_noseFill, Paint()..shader = _noseShader);
    c.save();
    c.clipPath(_noseFill);
    c.drawPath(_noseShade, _fill(_skinShade.withValues(alpha: .45)));
    if (s.fury > 0) {
      c.drawPath(_noseFill, _fill(_blush.withValues(alpha: .35 * s.fury)));
    }
    c.restore();
    c.drawPath(_noseEdge, _line(_ink, .05));
    // The nostril wing and the nostril, which flares a little in a glare.
    c.drawArc(
      Rect.fromCircle(center: const Offset(-.46, -.14), radius: .05),
      -1.2,
      -2.4,
      false,
      _line(_skinDeep.withValues(alpha: .7), .02),
    );
    c.save();
    c.translate(-.56, -.115);
    c.rotate(-.25);
    c.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: .07 + s.glare * .02,
        height: .036 + s.glare * .01,
      ),
      _fill(_skinDeep.withValues(alpha: .75)),
    );
    c.restore();
    // The sunburnt tip catches the torch.
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-.7, -.25),
        width: .055,
        height: .038,
      ),
      _fill(_bone.withValues(alpha: .9)),
    );
    if (s.dizzy) {
      // A plaster across the nose for the knock-out.
      c.save();
      c.translate(-.62, -.21);
      for (final a in const [.6, -.6]) {
        c.save();
        c.rotate(a);
        final strip = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: .21, height: .06),
          const Radius.circular(.02),
        );
        c.drawRRect(strip.inflate(.014), _fill(_ink));
        c.drawRRect(strip, _fill(const Color(0xffffe6c4)));
        c.drawCircle(const Offset(-.05, 0), .008, _fill(_skinShade));
        c.drawCircle(const Offset(.05, 0), .008, _fill(_skinShade));
        c.restore();
      }
      c.restore();
    }
    if (s.glare > .3) {
      // A snarl wrinkles the bridge of the nose.
      final wrinkle = _skinDeep.withValues(alpha: s.glare.clamp(0.0, 1.0));
      for (final y in const [-.52, -.47]) {
        c.drawLine(
          Offset(-.43, y),
          Offset(-.38, y + .025),
          _line(wrinkle, .018),
        );
      }
    }
  }

  // ------------------------------------------------------------ mustache --

  static void _mustache(Canvas c, PirateFaceState s) {
    // One waxed handlebar in a single stroke, from the short far wing
    // tucked behind the nose to the long near wing across the cheek: it
    // twitches up with the grin, flares in the roar and wilts when he is
    // knocked out.
    // It bobs with his words too, and perks up or droops with their mood.
    final lift =
        s.roar * .06 +
        s.recoil * .04 +
        s.talk * .03 +
        switch (s.mood) {
          StoryMood.happy => .03,
          StoryMood.sad => -.04,
          _ => 0,
        } +
        (s.dizzy ? -.07 : .01 + math.sin(s.time * 2.4) * .006);
    final pts = _spline([
      Offset(-.73, -.12 - lift),
      Offset(-.75, -.16 - lift),
      Offset(-.79, -.15 - lift),
      Offset(-.81, -.1 - lift * .8),
      Offset(-.78, -.04 - lift * .4),
      const Offset(-.71, -.01),
      const Offset(-.62, -.02),
      const Offset(-.53, -.07),
      const Offset(-.44, -.03),
      const Offset(-.34, .0),
      const Offset(-.24, -.02),
      Offset(-.17, -.07 - lift * .5),
      Offset(-.14, -.14 - lift),
      Offset(-.17, -.19 - lift),
      Offset(-.21, -.18 - lift),
    ], 4);
    final shape = _ribbon(
      pts,
      (t) => .014 + .092 * math.pow(math.sin(math.pi * t), 1.8),
    );
    c.drawPath(shape, _line(_ink, .046));
    c.drawPath(shape, Paint()..shader = _stacheShader);
    // Wax sheen along the top of each wing.
    for (final (from, to) in const [(18, 26), (31, 44)]) {
      final sheen = Path()..moveTo(pts[from].dx, pts[from].dy - .034);
      for (var i = from + 1; i <= to; i++) {
        sheen.lineTo(pts[i].dx, pts[i].dy - .034);
      }
      c.drawPath(sheen, _line(_hairSheen.withValues(alpha: .75), .018));
    }
  }

  // --------------------------------------------------------------- mouth --

  static void _mouth(Canvas c, PirateFaceState s) {
    final open = s.shout;
    final snarl = math.max(s.snarl, s.ouch * .8);
    // Idle grin -> gritted snarl -> bellow, blended by the state weights.
    // A glad line keeps the grin's corners up as he talks; a sorry one
    // turns them down.
    final happy = s.mood == StoryMood.happy ? 1.0 : 0.0;
    var hw = .21 + happy * .02,
        corner = -.03 - happy * .03 + (s.mood == StoryMood.sad ? .07 : 0),
        depth = .12,
        slant = .04;
    hw += (.22 - hw) * snarl;
    corner += (.03 - corner) * snarl;
    depth += (.16 - depth) * snarl;
    slant *= 1 - snarl;
    hw += (.18 - hw) * open;
    corner += (.0 - corner) * open * (1 - happy * .7);
    depth += (.3 - depth) * open;
    slant *= 1 - open * (1 - happy * .7);
    if (s.dizzy) {
      hw = .13;
      corner = .03;
      depth = .2;
      slant = 0;
    }
    // Turned away, the far half of the mouth is foreshortened.
    final far = hw * .62, near = hw * 1.1;
    const cx = -.48;
    const top = .02;
    // A cheeky lopsided grin: the near corner rides higher.
    final l = Offset(cx - far, top + corner + slant * .3);
    final r = Offset(cx + near, top + corner - slant);
    final bottom = top + depth;
    final shape = Path()
      ..moveTo(l.dx, l.dy)
      ..quadraticBezierTo(cx, top - .015, r.dx, r.dy)
      ..cubicTo(r.dx + .01, bottom - .03, cx + near * .5, bottom, cx, bottom)
      ..cubicTo(cx - far * .5, bottom, l.dx - .01, bottom - .03, l.dx, l.dy)
      ..close();
    c.drawPath(shape, _line(_ink, .052));
    c.drawPath(shape, _fill(_mouthDark));
    c.save();
    c.clipPath(shape);
    // The tongue.
    final tongue = math.max(open, s.dizzy ? .7 : 0.0);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx + .04, bottom + .01 - tongue * .02),
        width: (far + near) * .5 * (1.0 + tongue * .5),
        height: .07 + tongue * .13,
      ),
      _fill(_tongue),
    );
    // Top teeth, one of them a long gold fang.
    const teeth = .075;
    c.drawRect(
      Rect.fromLTRB(l.dx - .02, top - .08, r.dx + .02, top + teeth),
      _fill(_bone),
    );
    c.drawRect(
      Rect.fromLTRB(cx - .015, top - .08, cx + .065, top + teeth + .03),
      _fill(_gold),
    );
    c.drawRect(
      Rect.fromLTRB(cx, top + teeth - .05, cx + .02, top + teeth + .01),
      _fill(_goldLight),
    );
    // The teeth crowd closer together round the far side.
    for (final x in const [-.1, -.055, .13, .2]) {
      c.drawLine(
        Offset(cx + x, top - .01),
        Offset(cx + x, top + teeth),
        _line(_skinDeep.withValues(alpha: .6), .014),
      );
    }
    if (snarl > .4 || open > .5) {
      // Bottom teeth, only when he bares them.
      c.drawRect(
        Rect.fromLTRB(
          cx - far * .8,
          bottom - (open > .5 ? .05 : .06),
          cx + near * .8,
          bottom + .02,
        ),
        _fill(_bone),
      );
    }
    c.restore();
    final grin = (1 - snarl) * (1 - open) * (s.dizzy ? 0 : 1);
    if (grin > .3) {
      // A crease at the near corner of a wide grin.
      c.drawArc(
        Rect.fromCenter(
          center: r + const Offset(.01, -.01),
          width: .05,
          height: .1,
        ),
        -1.3,
        2.6,
        false,
        _line(_skinDeep.withValues(alpha: .7), .022),
      );
    }
    if (s.dizzy) {
      // Tongue lolling out over the beard.
      final lolling = Path()
        ..moveTo(cx + .04, bottom - .02)
        ..quadraticBezierTo(cx + .12, bottom + .12, cx + .04, bottom + .14)
        ..quadraticBezierTo(cx - .04, bottom + .12, cx - .02, bottom - .02);
      c.drawPath(lolling, _line(_ink, .05));
      c.drawPath(lolling, _fill(_tongue));
    }
  }

  // ---------------------------------------------------------------- vein --

  /// A popping cross-vein on the side of his head, throbbing with his rage.
  static void _vein(Canvas c, PirateFaceState s) {
    const at = Offset(.095, -.37);
    final size =
        .72 + s.fury * .1 + (s.time == 0 ? 0 : math.sin(s.time * 9) * .06);
    final mark = Path();
    for (var turn = 0; turn < 4; turn++) {
      final a = turn * math.pi / 2 + .3;
      final cos = math.cos(a), sin = math.sin(a);
      Offset p(double x, double y) =>
          at + Offset(x * cos - y * sin, x * sin + y * cos) * size;
      final from = p(.035, .12), bend = p(.05, .05), to = p(.12, .035);
      mark
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(bend.dx, bend.dy, to.dx, to.dy);
    }
    c.drawPath(mark, _line(_ink, .075));
    c.drawPath(mark, _line(_ember, .034));
  }

  /// A bead of sweat at the temple, as in the story's sorry captain.
  static void _sweat(Canvas c) {
    c.save();
    c.translate(.12, -.4);
    c.scale(.13);
    final drop = Path()
      ..moveTo(0, -1)
      ..cubicTo(.75, 0, .6, .8, 0, .8)
      ..cubicTo(-.6, .8, -.75, 0, 0, -1)
      ..close();
    c.drawPath(drop, _fill(const Color(0xff9fe0f2)));
    c.drawPath(drop, _line(_ink, .3));
    c.drawLine(
      const Offset(-.2, .1),
      const Offset(-.2, .36),
      _line(const Color(0xffffffff), .2),
    );
    c.restore();
  }
}
