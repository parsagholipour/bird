import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import '../domain/sky_boss.dart';
import 'baron_storm_art.dart';
import 'baron_storm_pose.dart';
import 'boss_motion.dart';
import 'boss_rig.dart';
import 'sky_scenery.dart';

/// Baron Bat's parts, in rig units (the body oval is the combat hit radius,
/// x ±.91, y -.81..89; the rig looks left toward the bird). [BossRig.paint]
/// assembles them back to front: wings, cape and collar, ears, feet, the
/// furred body, breastplate, face, crown.
///
/// He is the elder of the purple bat family, dressed up: a real bat's wing
/// (forearm, thumb claw, four fingers, a scalloped membrane that lightens
/// toward its edge), big ears with a pink concha, cheek fur and a fur ruff,
/// small clawed feet, a stiff bat-wing collar over a wine cape, a gilt
/// breastplate with his winged gem, and an heirloom crown over a velvet cap.
/// Value order at play size: the eyes, the crown, the lilac body (the hit
/// zone), then the wings, cape and plate.
abstract final class BaronBatArt {
  static const ink = BossRig.ink, plum = BossRig.plum, violet = BossRig.violet;
  static const gold = BossRig.gold,
      cream = BossRig.cream,
      ember = BossRig.ember;

  static const _lilac = Color(0xffd6b6eb), _wine = Color(0xff6e2a4f);
  static const _lining = Color(0xffc2456a), _bronze = Color(0xffb97a3d);
  static const _steel = Color(0xff6f6d95), _steelDark = Color(0xff262848);
  static const _tongue = Color(0xffcc6884), _mint = Color(0xff98f0dc);
  static const _fur = Color(0xffe9d8f5), _furShade = Color(0xff9a7cc4);
  static const _bone = Color(0xff3a2c5c), _boneLit = Color(0xffab94dc);
  static const _concha = Color(0xffc98bc0), _conchaDeep = Color(0xff6c3f7e);
  static const _velvet = Color(0xffa3325f), _velvetDeep = Color(0xff4a1233);
  static const _amethyst = Color(0xffb27cf0), _amethystDeep = Color(0xff4b2486);
  static const _iris = Color(0xfff6cf6e), _irisDeep = Color(0xffb46a26);
  static const _noseColor = Color(0xff7a4d8f), _noseLit = Color(0xffc29ad6);
  static const _goldDeep = Color(0xffd9952f), _wineDeep = Color(0xff3c1230);
  static const _lid = Color(0xff9d80c6);

  static Paint _fill(Color c) => BossRig.fill(c);
  static Paint _line(Color c, [double w = .045]) => BossRig.line(c, w);
  static Paint _lin(Rect r, List<Color> colors, [List<double>? stops]) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: stops,
        ).createShader(r);
  static Paint _rad(
    Offset center,
    double radius,
    List<Color> colors, [
    List<double>? stops,
  ]) => Paint()
    ..shader = RadialGradient(
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

  static final _mirror = Float64List.fromList([
    -1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1,
  ]);

  /// [right] and its mirror image in one path.
  static Path _both(Path right) => Path()
    ..addPath(right, Offset.zero)
    ..addPath(right.transform(_mirror), Offset.zero);

  static Offset _toward(Offset a, Offset b, Offset target, double pull) {
    final mid = (a + b) / 2;
    return mid + (target - mid) * pull;
  }

  static Offset _bulge(Offset a, Offset b, double amount) {
    final d = b - a;
    final length = d.distance;
    if (length == 0) return a;
    return (a + b) / 2 + Offset(d.dy, -d.dx) / length * amount;
  }

  static void _quad(Path path, Offset control, Offset to) =>
      path.quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);

  /// The shot's release: 1 as a fireball leaves him, easing to 0 over .2 s.
  /// The charge drops to 0 on the launch frame and the recoil only starts
  /// to grow from 0, so the mouth and the gem would blink shut for a frame;
  /// this holds them through the hand-over.
  static double release(BossMotion m) {
    if (m.defeated) return 0;
    final since = m.boss.age - m.boss.lastVolleyAt;
    if (!(since >= 0) || since > .2) return 0;
    final t = 1 - since / .2;
    return t * t;
  }

  // ---------------------------------------------------------------- wings --

  static const root = Offset(.6, -.2), hip = Offset(.64, .34);

  /// Membrane paints: dark at the shoulder, lightening toward the hem so the
  /// span reads against night skies (debut calm, debut fury, storm calm,
  /// storm fury).
  static Paint _membrane(List<Color> c) =>
      _rad(const Offset(.62, -.18), 2.15, c, const [.1, .5, 1]);
  static final _membranes = [
    _membrane(const [Color(0xff3b2e60), Color(0xff6a55a0), Color(0xffb7a0e4)]),
    _membrane(const [Color(0xff3d1c45), Color(0xff7a3a74), Color(0xffe39ac0)]),
    // The storm palettes run light to dark; the membrane is lit at its hem.
    _membrane(BaronStormArt.wingColors(false).reversed.toList()),
    _membrane(BaronStormArt.wingColors(true).reversed.toList()),
  ];
  static final _panelShade = _fill(
    const Color(0xff160f2c).withValues(alpha: .17),
  );
  static final _hemBand = _fill(const Color(0xff1d1534).withValues(alpha: .28));
  static final _sleeve = _line(
    const Color(0xffcdb8f2).withValues(alpha: .3),
    .17,
  );
  static final _sleeveFury = _line(
    const Color(0xffffb3c8).withValues(alpha: .3),
    .17,
  );
  static final _boneFill = _fill(_bone);
  static final _boneRidge = _line(_boneLit.withValues(alpha: .85), .024);
  static final _veins = _line(
    const Color(0xffd9c8f7).withValues(alpha: .2),
    .02,
  );
  static final _inkFill = _fill(ink);
  static final _wingOutline = _line(ink, .065);
  static final _claw = _fill(cream);
  static final _clawLine = _line(ink, .035);

  /// Adds a tapered bone along the quadratic curve a→(ctrl)→b.
  static void _taper(
    Path p,
    Offset a,
    Offset ctrl,
    Offset b,
    double w0,
    double w1,
  ) {
    Offset n(Offset d) {
      final l = d.distance;
      return l == 0 ? Offset.zero : Offset(-d.dy, d.dx) / l;
    }

    final na = n(ctrl - a), nb = n(b - ctrl), nc = n(b - a);
    final wc = (w0 + w1) / 2;
    p
      ..moveTo(a.dx + na.dx * w0, a.dy + na.dy * w0)
      ..quadraticBezierTo(
        ctrl.dx + nc.dx * wc,
        ctrl.dy + nc.dy * wc,
        b.dx + nb.dx * w1,
        b.dy + nb.dy * w1,
      )
      ..lineTo(b.dx - nb.dx * w1, b.dy - nb.dy * w1)
      ..quadraticBezierTo(
        ctrl.dx - nc.dx * wc,
        ctrl.dy - nc.dy * wc,
        a.dx - na.dx * w0,
        a.dy - na.dy * w0,
      )
      ..close();
  }

  /// One wing in right-side coordinates: [wing] is wrist, tip and the three
  /// trailing finger tips of the pose.
  static void wing(
    Canvas c,
    List<Offset> wing,
    bool fury, {
    required bool adorned,
    BaronStormPose? storm,
  }) {
    final [wrist, tip, f1, f2, f3] = wing;
    final arm = _bulge(root, wrist, .16), hand = _bulge(wrist, tip, .07);
    // The trailing edge: deep scallops between the fingers.
    final s1 = _toward(tip, f1, wrist, .36);
    final s2 = _toward(f1, f2, wrist, .42);
    final s3 = _toward(f2, f3, wrist, .42);
    final s4 = _toward(f3, hip, root, .34);
    final path = Path()..moveTo(root.dx, root.dy);
    _quad(path, arm, wrist);
    _quad(path, hand, tip);
    _quad(path, s1, f1);
    _quad(path, s2, f2);
    _quad(path, s3, f3);
    _quad(path, s4, hip);
    path.close();
    c.drawPath(path.shift(const Offset(.03, .07)), _inkFill);
    c.drawPath(path, _membranes[(storm != null ? 2 : 0) + (fury ? 1 : 0)]);
    // Alternate panels fold darker, like the gores of an umbrella.
    final panels = Path()
      ..moveTo(wrist.dx, wrist.dy)
      ..lineTo(f1.dx, f1.dy);
    _quad(panels, s2, f2);
    panels
      ..close()
      ..moveTo(wrist.dx, wrist.dy)
      ..lineTo(f3.dx, f3.dy);
    _quad(panels, s4, hip);
    _quad(panels, Offset.lerp(arm, hip, .5)!, root);
    _quad(panels, arm, wrist);
    panels.close();
    c.drawPath(panels, _panelShade);
    // A darker hem band just inside the trailing edge.
    Offset inset(Offset p) => p + (wrist - p) * .11;
    final band = Path()..moveTo(tip.dx, tip.dy);
    _quad(band, s1, f1);
    _quad(band, s2, f2);
    _quad(band, s3, f3);
    _quad(band, s4, hip);
    final hipIn = hip + (root - hip) * .1;
    band.lineTo(hipIn.dx, hipIn.dy);
    _quad(band, inset(s4), inset(f3));
    _quad(band, inset(s3), inset(f2));
    _quad(band, inset(s2), inset(f1));
    _quad(band, inset(s1), inset(tip));
    band.close();
    c.drawPath(band, _hemBand);
    // The membrane glows beside each finger, then the bones on top.
    final fingers = <(Offset, Offset)>[
      (_bulge(wrist, f1, -.06), f1),
      (_bulge(wrist, f2, -.05), f2),
      (_bulge(wrist, f3, -.04), f3),
    ];
    final sleeves = Path();
    for (final (ctrl, to) in fingers) {
      sleeves.moveTo(wrist.dx, wrist.dy);
      _quad(sleeves, ctrl, Offset.lerp(wrist, to, .94)!);
    }
    c.drawPath(sleeves, fury ? _sleeveFury : _sleeve);
    final bones = Path();
    final down = const Offset(0, .045);
    _taper(bones, root + down, arm + down, wrist + down * .6, .065, .05);
    _taper(bones, wrist, hand + down * .8, tip + down * .5, .045, .016);
    for (final (ctrl, to) in fingers) {
      _taper(bones, wrist, ctrl, Offset.lerp(wrist, to, .97)!, .04, .012);
    }
    c.drawPath(bones, _boneFill);
    final ridge = Path();
    for (final (ctrl, to) in fingers) {
      final a = Offset.lerp(wrist, to, .12)!, b = Offset.lerp(wrist, to, .8)!;
      ridge.moveTo(a.dx, a.dy - .012);
      _quad(ridge, ctrl + const Offset(0, -.015), b + const Offset(0, -.01));
    }
    c.drawPath(ridge, _boneRidge);
    // Fine membrane fibres run across each panel, parallel to the hem.
    final veins = Path();
    for (final (a, ctrl, b) in [(tip, s1, f1), (f1, s2, f2), (f2, s3, f3)]) {
      for (final k in const [.7]) {
        final p0 = Offset.lerp(wrist, a, k)!, p1 = Offset.lerp(wrist, b, k)!;
        final pc = Offset.lerp(wrist, ctrl, k)!;
        veins.moveTo(p0.dx, p0.dy);
        _quad(veins, pc, p1);
      }
    }
    c.drawPath(veins, _veins);
    // A knuckle halfway along each finger.
    final joints = Path();
    for (final (ctrl, to) in fingers) {
      final t = .5, u = 1 - t;
      final at = wrist * (u * u) + ctrl * (2 * t * u) + to * (t * t);
      joints.addOval(Rect.fromCircle(center: at, radius: .03));
    }
    c.drawPath(joints, _boneFill);
    if (storm != null && adorned) {
      final bolts = Path();
      for (final (i, f) in [f1, f2].indexed) {
        final at = Offset.lerp(wrist, Offset.lerp(f, [f2, f3][i], .5)!, .55)!;
        bolts.addPath(BaronStormArt.bolt(at, .085 - i * .012), Offset.zero);
      }
      c.drawPath(bolts, _fill(gold.withValues(alpha: .7)));
    }
    c.drawPath(path, _wingOutline);
    if (storm != null) {
      // The upgraded Baron's leading edge crackles with lightning.
      BaronStormArt.wingEdge(
        c,
        root + const Offset(.04, .05),
        arm + const Offset(0, .05),
        wrist + const Offset(0, .05),
        hand + const Offset(0, .04),
        tip + const Offset(-.08, .04),
        fury: fury,
      );
    } else {
      // The gold-trimmed leading edge holds the span against dark skies.
      final edge = Path()..moveTo(root.dx + .04, root.dy + .05);
      _quad(edge, arm + const Offset(0, .05), wrist + const Offset(0, .05));
      _quad(edge, hand + const Offset(0, .04), tip + const Offset(-.08, .04));
      c.drawPath(edge, _line(fury ? ember : (adorned ? gold : violet), .05));
    }
    // The thumb claw: a cream thorn hooked toward his head.
    final w = wrist;
    final claw = Path()
      ..moveTo(w.dx - .085, w.dy + .03)
      ..quadraticBezierTo(w.dx - .03, w.dy - .12, w.dx - .17, w.dy - .27)
      ..quadraticBezierTo(w.dx + .03, w.dy - .17, w.dx + .07, w.dy + .0)
      ..close();
    c.drawPath(claw, _claw);
    c.drawPath(claw, _clawLine);
  }

  // ------------------------------------------------------- cape and collar --

  static final _hem = () {
    final hem = Path()..moveTo(-.78, .2);
    const scallops = [
      Offset(-1.0, .98),
      Offset(-.5, 1.2),
      Offset(0, 1.32),
      Offset(.5, 1.2),
      Offset(1.0, .98),
    ];
    hem.lineTo(scallops.first.dx, scallops.first.dy);
    for (var i = 1; i < scallops.length; i++) {
      final a = scallops[i - 1], b = scallops[i];
      _quad(hem, _toward(a, b, const Offset(0, .5), .3), b);
    }
    return hem
      ..lineTo(.78, .2)
      ..close();
  }();
  static final _hemPaint = _lin(const Rect.fromLTRB(-1, .2, 1, 1.3), const [
    Color(0xff8e2f5a),
    _wine,
    _wineDeep,
  ]);
  static final _hemFolds = _both(
    Path()
      ..moveTo(.62, .86)
      ..quadraticBezierTo(.66, 1.0, .6, 1.14)
      ..moveTo(.26, 1.04)
      ..quadraticBezierTo(.28, 1.16, .24, 1.25),
  );

  /// The lining shows where the hem's corners turn back.
  static final _hemTurn = _both(
    Path()
      ..moveTo(.86, .44)
      ..lineTo(1.0, .98)
      ..quadraticBezierTo(.9, 1.0, .8, 1.06)
      ..quadraticBezierTo(.86, .76, .78, .5)
      ..close(),
  );

  /// The stiff bat-wing collar (right half): lining toward us, two scallops
  /// up the outer edge, gold piping along the top.
  static final _collar = Path()
    ..moveTo(.42, .32)
    ..lineTo(1.04, .18)
    ..quadraticBezierTo(1.14, .0, 1.2, -.22)
    ..quadraticBezierTo(1.12, -.32, 1.3, -.74)
    ..quadraticBezierTo(1.04, -.58, .84, -.46)
    ..close();
  static final _collarInner = Path()
    ..moveTo(.5, .24)
    ..lineTo(.96, .12)
    ..quadraticBezierTo(1.04, -.02, 1.1, -.21)
    ..quadraticBezierTo(1.04, -.32, 1.17, -.62)
    ..quadraticBezierTo(1.0, -.5, .84, -.4)
    ..close();
  static final _collars = _both(_collar);
  static final _collarInners = _both(_collarInner);
  static final _collarPleats = _both(
    Path()
      ..moveTo(.74, .14)
      ..quadraticBezierTo(.92, .0, 1.1, -.21)
      ..moveTo(.74, .0)
      ..quadraticBezierTo(.92, -.3, 1.16, -.6),
  );
  static final _collarPiping = _both(
    Path()
      ..moveTo(1.0, .14)
      ..quadraticBezierTo(1.09, .0, 1.15, -.2)
      ..quadraticBezierTo(1.08, -.3, 1.23, -.66)
      ..quadraticBezierTo(1.02, -.53, .86, -.43),
  );
  static final _collarOuter = _fill(_wine);
  static final _hemTurnPaint = _fill(_lining);
  static final _hemFoldPaint = _line(_wineDeep.withValues(alpha: .8), .035);
  static final _pipingPaint = _line(gold.withValues(alpha: .9), .03);
  static final _collarLining = _lin(
    const Rect.fromLTRB(-1.3, -.8, 1.3, .3),
    const [Color(0xffe0607f), _lining, Color(0xff8a2650)],
  );
  static final _pleatLine = _line(
    const Color(0xff7a1f45).withValues(alpha: .55),
    .03,
  );
  static final _outline = _line(ink, .055);

  static void cape(Canvas c) {
    c.drawPath(_hem.shift(const Offset(.03, .06)), _inkFill);
    c.drawPath(_hem, _hemPaint);
    c.drawPath(_hemTurn, _hemTurnPaint);
    c.drawPath(_hemFolds, _hemFoldPaint);
    c.drawPath(_hem, _outline);
    collar(c);
  }

  /// The collar's lining paint, shared with the storm collar.
  static Paint get collarLining => _collarLining;

  static void collar(Canvas c) {
    c.drawPath(_collars.shift(const Offset(.03, .06)), _inkFill);
    c.drawPath(_collars, _collarOuter);
    c.drawPath(_collarInners, _collarLining);
    c.drawPath(_collarPleats, _pleatLine);
    c.drawPath(_collarPiping, _pipingPaint);
    c.drawPath(_collars, _outline);
  }

  // ----------------------------------------------------------------- ears --

  static final _ear = Path()
    ..moveTo(.2, -.64)
    ..quadraticBezierTo(.42, -1.24, .98, -1.56)
    ..quadraticBezierTo(1.02, -1.14, .9, -.92)
    ..quadraticBezierTo(.94, -.8, .82, -.72)
    ..quadraticBezierTo(.76, -.6, .6, -.5)
    ..close();
  static final _earInner = Path()
    ..moveTo(.38, -.72)
    ..quadraticBezierTo(.54, -1.16, .88, -1.42)
    ..quadraticBezierTo(.9, -1.1, .8, -.92)
    ..quadraticBezierTo(.74, -.76, .58, -.64)
    ..close();
  static final _earWell = Path()
    ..moveTo(.54, -.76)
    ..quadraticBezierTo(.68, -1.06, .84, -1.26)
    ..quadraticBezierTo(.8, -1.0, .7, -.8)
    ..close();
  static final _earTuft = Path()
    ..moveTo(.48, -.6)
    ..quadraticBezierTo(.58, -.78, .76, -.84)
    ..quadraticBezierTo(.68, -.76, .7, -.7)
    ..quadraticBezierTo(.78, -.78, .9, -.76)
    ..quadraticBezierTo(.82, -.7, .82, -.64)
    ..quadraticBezierTo(.86, -.66, .92, -.62)
    ..quadraticBezierTo(.84, -.56, .8, -.5)
    ..close();

  /// Light along the ear's front edge.
  static final _earRim = Path()
    ..moveTo(.3, -.76)
    ..quadraticBezierTo(.5, -1.16, .9, -1.46);
  static final _earPaint = _lin(
    const Rect.fromLTRB(-1.1, -1.56, 1.1, -.36),
    const [Color(0xff8c76c0), Color(0xff5c4b8a), Color(0xff45366e)],
  );
  static final _conchaPaint = _lin(
    const Rect.fromLTRB(-1.0, -1.3, 1.0, -.58),
    const [_concha, Color(0xffa0629f)],
  );

  static const _earPivot = Offset(.46, -.6);
  static final _earWellPaint = _fill(_conchaDeep);
  static final _earRimPaint = _line(const Color(0xffb9a3e6), .03);
  static final _earLine = _line(ink, .06);
  static final _tuftPaint = _fill(_lilac);

  /// How far each ear turns out (radians, + tips outward and down): pinned
  /// back in fury, pricked forward by a charge, and a quick flick every few
  /// seconds while he idles (each ear on its own beat; none under Reduced
  /// Motion).
  static double earTurn(BossMotion m, double side, bool fury) {
    final charge = m.defeated ? 0.0 : m.boss.charge;
    var turn = (fury ? .17 : 0) - charge * .1 + (m.defeated ? .22 : 0);
    if (!m.reducedMotion && !m.defeated && !m.arriving) {
      final beat = (m.boss.age + (side > 0 ? 0 : 1.7)) % 4.1;
      turn += BossMotion.pulse(beat - 3.5, .26) * .2;
    }
    return turn;
  }

  static void ears(Canvas c, BossMotion m, bool fury) {
    for (final side in const [-1.0, 1.0]) {
      final turn = earTurn(m, side, fury);
      c.save();
      c.scale(side, 1);
      if (turn != 0) {
        c.translate(_earPivot.dx, _earPivot.dy);
        c.rotate(turn);
        c.translate(-_earPivot.dx, -_earPivot.dy);
      }
      c.drawPath(_ear.shift(const Offset(.03, .05)), _inkFill);
      c.drawPath(_ear, _earPaint);
      c.drawPath(_earInner, _conchaPaint);
      c.drawPath(_earWell, _earWellPaint);
      c.drawPath(_earRim, _earRimPaint);
      c.drawPath(_ear, _earLine);
      c.drawPath(_earTuft, _tuftPaint);
      c.restore();
    }
  }

  // ----------------------------------------------------------------- feet --

  static final _feet = _both(
    Path()
      ..moveTo(.15, .84)
      ..quadraticBezierTo(.16, 1.08, .31, 1.13)
      ..quadraticBezierTo(.46, 1.1, .48, .84)
      ..close(),
  );
  static final _toes = _both(
    Path()
      ..moveTo(.21, 1.04)
      ..quadraticBezierTo(.16, 1.12, .2, 1.19)
      ..moveTo(.31, 1.08)
      ..quadraticBezierTo(.3, 1.16, .34, 1.22)
      ..moveTo(.41, 1.03)
      ..quadraticBezierTo(.44, 1.11, .48, 1.15),
  );
  static final _toeTips = _both(
    Path()
      ..moveTo(.17, 1.15)
      ..lineTo(.2, 1.19)
      ..moveTo(.32, 1.19)
      ..lineTo(.34, 1.22)
      ..moveTo(.46, 1.13)
      ..lineTo(.48, 1.15),
  );

  static final _footPaint = _fill(plum), _footLine = _line(ink, .045);
  static final _toeInk = _line(ink, .1), _toePaint = _line(plum, .052);
  static final _toeTipPaint = _line(cream, .045);

  static void feet(Canvas c) {
    c.drawPath(_feet, _footPaint);
    c.drawPath(_feet, _footLine);
    c.drawPath(_toes, _toeInk);
    c.drawPath(_toes, _toePaint);
    c.drawPath(_toeTips, _toeTipPaint);
  }

  // ----------------------------------------------------------------- body --

  static const body = Rect.fromLTWH(-.91, -.81, 1.82, 1.7);

  /// The hit oval with tufts of cheek fur breaking its lower sides.
  static final _bodyPath = () {
    Path tufts(double s) => Path()
      ..moveTo(s * .8, -.14)
      ..quadraticBezierTo(s * .98, -.1, s * 1.03, .0)
      ..quadraticBezierTo(s * .94, .04, s * .9, .1)
      ..quadraticBezierTo(s * 1.02, .14, s * 1.05, .22)
      ..quadraticBezierTo(s * .94, .26, s * .88, .3)
      ..quadraticBezierTo(s * .98, .36, s * .97, .45)
      ..quadraticBezierTo(s * .86, .46, s * .74, .44)
      ..close();
    return Path.combine(
      PathOperation.union,
      Path.combine(PathOperation.union, Path()..addOval(body), tufts(1)),
      tufts(-1),
    );
  }();
  static final _bodyPaint = _lin(body, const [_lilac, violet, plum]);
  static final _muzzle = _rad(
    const Offset(-.03, .1),
    .56,
    [
      _fur.withValues(alpha: .62),
      _fur.withValues(alpha: .4),
      _fur.withValues(alpha: 0),
    ],
    const [0, .62, 1],
  );
  static final _bodyLine = _line(ink, .06);
  static final _furTickPaint = _line(_furShade.withValues(alpha: .7), .03);
  static final _gloss = _line(cream.withValues(alpha: .55), .04);
  static final _furTicks = _both(
    Path()
      ..moveTo(.72, -.02)
      ..quadraticBezierTo(.8, .02, .84, .1)
      ..moveTo(.7, .16)
      ..quadraticBezierTo(.79, .2, .82, .3),
  );

  static void torso(Canvas c, bool adorned) {
    c.drawPath(_bodyPath.shift(const Offset(.035, .08)), _inkFill);
    c.drawPath(_bodyPath, _bodyPaint);
    c.drawOval(const Rect.fromLTRB(-.6, -.2, .54, .46), _muzzle);
    if (!adorned) {
      c.drawOval(
        const Rect.fromLTWH(-.43, .28, .86, .48),
        _fill(const Color(0xffc0a3df)),
      );
    }
    c.drawPath(_furTicks, _furTickPaint);
    c.drawPath(_bodyPath, _bodyLine);
    c.drawArc(body.deflate(.09), -2.8, 1.25, false, _gloss);
  }

  // ---------------------------------------------------------- breastplate --

  static final _armor = Path()
    ..moveTo(-.64, .4)
    ..quadraticBezierTo(0, .26, .64, .4)
    ..quadraticBezierTo(.6, .86, 0, 1.02)
    ..quadraticBezierTo(-.6, .86, -.64, .4)
    ..close();
  static final _armorPaint = _lin(
    const Rect.fromLTRB(-.64, .3, .64, 1),
    const [Color(0xff8583ad), _steel, _steelDark],
    const [0, .35, 1],
  );
  static final _armorSheen = Path()
    ..moveTo(-.54, .46)
    ..quadraticBezierTo(-.3, .4, -.18, .42)
    ..quadraticBezierTo(-.34, .62, -.3, .82)
    ..quadraticBezierTo(-.52, .66, -.54, .46)
    ..close();
  static final _filigree = Path()
    ..moveTo(-.48, .5)
    ..quadraticBezierTo(-.36, .78, -.14, .88)
    ..moveTo(.48, .5)
    ..quadraticBezierTo(.36, .78, .14, .88);
  static final _innerRim = Path()
    ..moveTo(-.55, .46)
    ..quadraticBezierTo(0, .35, .55, .46)
    ..moveTo(-.53, .56)
    ..quadraticBezierTo(-.46, .82, 0, .93)
    ..quadraticBezierTo(.46, .82, .53, .56);
  static final _bezel = Path()
    ..moveTo(0, .37)
    ..lineTo(.2, .63)
    ..lineTo(0, .92)
    ..lineTo(-.2, .63)
    ..close();
  static final _rivets = () {
    final p = Path();
    for (final x in const [-.5, -.27, .27, .5]) {
      final y = .4 - (.14 * (1 - (x / .64) * (x / .64))) + .055;
      p.addOval(Rect.fromCircle(center: Offset(x, y), radius: .028));
    }
    return p;
  }();

  /// Little gold bat wings either side of his gem: his family crest.
  static final _crestWings = _both(
    Path()
      ..moveTo(.13, .6)
      ..quadraticBezierTo(.26, .5, .42, .52)
      ..quadraticBezierTo(.38, .58, .4, .64)
      ..quadraticBezierTo(.33, .63, .3, .7)
      ..quadraticBezierTo(.24, .66, .19, .72)
      ..quadraticBezierTo(.17, .67, .13, .66)
      ..close(),
  );
  static final _clasps = () {
    final p = Path();
    for (final s in const [-1.0, 1.0]) {
      p.addOval(Rect.fromCircle(center: Offset(s * .62, .41), radius: .085));
    }
    return p;
  }();
  static final _claspFaces = () {
    final p = Path();
    for (final s in const [-1.0, 1.0]) {
      p.addOval(
        Rect.fromCircle(center: Offset(s * .62 - .008, .4), radius: .055),
      );
    }
    return p;
  }();
  static final _claspPaint = _rad(
    const Offset(0, .36),
    .75,
    const [cream, gold, _goldDeep],
    const [.0, .75, 1],
  );
  static final _gem = Path()
    ..moveTo(0, .43)
    ..lineTo(.15, .63)
    ..lineTo(0, .86)
    ..lineTo(-.15, .63)
    ..close();
  static final _star = SkyScenery.star(const Offset(0, .64), .25);

  static void breastplate(
    Canvas c,
    SkyBoss boss,
    BossMotion motion,
    bool fury, [
    BaronStormPose? storm,
  ]) {
    c.drawPath(_armor.shift(const Offset(.02, .05)), _inkFill);
    c.drawPath(_armor, _armorPaint);
    c.drawPath(
      _armorSheen,
      _fill(const Color(0xffb6b4d8).withValues(alpha: .35)),
    );
    c.drawPath(_filigree, _line(gold.withValues(alpha: .5), .028));
    c.drawPath(_innerRim, _line(gold.withValues(alpha: .35), .02));
    c.drawPath(_armor, _line(gold, .055));
    c.drawPath(_rivets, _fill(const Color(0xffffe7a8)));
    // The cape's clasps at the plate's corners.
    c.drawPath(_clasps, _inkFill);
    c.drawPath(_claspFaces, _claspPaint);
    final glow = motion.defeated
        ? 0.0
        : math.max(math.max(boss.charge, motion.recoil), release(motion));
    if (storm != null) {
      BaronStormArt.resonator(c, storm, charge: glow, fury: fury);
      return;
    }
    c.drawPath(_crestWings, _fill(gold));
    c.drawPath(_crestWings, _line(const Color(0xff8a5a2a), .02));
    final gemColor = fury ? ember : _mint;
    c.drawPath(_star, _inkFill);
    c.drawPath(_bezel, _line(ink, .07));
    c.drawPath(_bezel, _line(gold, .035));
    c.drawPath(
      _gem,
      _lin(const Rect.fromLTRB(-.15, .43, .15, .86), [
        cream,
        Color.lerp(gemColor, cream, glow * .45)!,
        fury ? const Color(0xff932e63) : plum,
      ]),
    );
    if (glow > .05) {
      // The gem powers up: four sparkle rays grow with the wind-up.
      final rays = Path();
      for (final d in const [
        Offset(0, -1),
        Offset(1, 0),
        Offset(0, 1),
        Offset(-1, 0),
      ]) {
        final from = const Offset(0, .645) + d * (.2 + glow * .05);
        final to = const Offset(0, .645) + d * (.21 + glow * .2);
        rays
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy);
      }
      c.drawPath(rays, _line(Color.lerp(gemColor, cream, .5)!, .045));
    }
    c.drawPath(_gem, _line(gold, .025));
    c.drawLine(
      const Offset(-.04, .5),
      const Offset(-.08, .62),
      _line(cream.withValues(alpha: .8), .025),
    );
  }

  // ----------------------------------------------------------------- face --

  static const eyeY = -.25, eyeX = .36;

  static final _nose = Path()
    ..moveTo(0, -.25)
    ..quadraticBezierTo(.05, -.17, .07, -.12)
    ..quadraticBezierTo(.15, -.11, .15, -.04)
    ..quadraticBezierTo(.14, .03, .05, .03)
    ..quadraticBezierTo(0, .0, -.05, .03)
    ..quadraticBezierTo(-.14, .03, -.15, -.04)
    ..quadraticBezierTo(-.15, -.11, -.07, -.12)
    ..quadraticBezierTo(-.05, -.17, 0, -.25)
    ..close();
  static final _nostrils = Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(-.065, -.03),
        width: .06,
        height: .045,
      ),
    )
    ..addOval(
      Rect.fromCenter(
        center: const Offset(.065, -.03),
        width: .06,
        height: .045,
      ),
    );
  static final _white = _fill(const Color(0xffffffff));
  static final _eyeBags = _both(
    Path()
      ..moveTo(.2, .04)
      ..quadraticBezierTo(.38, .1, .56, .0),
  );
  static final _noseLitPath = Path()
    ..moveTo(-.02, -.19)
    ..quadraticBezierTo(-.04, -.13, -.09, -.09);

  static void face(
    Canvas c,
    SkyBoss boss,
    BossMotion motion,
    double look,
    bool fury, [
    BaronStormPose? storm,
  ]) {
    final charge = motion.defeated ? 0.0 : boss.charge;
    final wince = motion.wince, blink = motion.blink;
    final (lidMood, browMood, gaze) = switch (motion.mood) {
      StoryMood.happy => (.03, -.06, 0.0),
      StoryMood.surprised => (-.12, -.14, -.4),
      StoryMood.angry => (.1, .1, 0.0),
      StoryMood.sad => (.15, -.22, .8),
      _ => (0.0, 0.0, 0.0),
    };
    final surprised = motion.mood == StoryMood.surprised;
    final scowl = fury || motion.mood == StoryMood.angry;
    final eyeShift = (look + gaze).clamp(-1.0, 1.0) * .09;
    for (final side in [-1.0, 1.0]) {
      final center = Offset(side * eyeX, eyeY);
      final eye = Rect.fromCenter(center: center, width: .56, height: .48);
      c.drawOval(eye.inflate(.045), _fill(plum));
      if (motion.defeated) {
        c.drawOval(eye, _fill(cream));
        final x = center.dx;
        final cross = Path()
          ..moveTo(x - .13, -.36)
          ..lineTo(x + .11, -.15)
          ..moveTo(x + .11, -.36)
          ..lineTo(x - .13, -.15);
        c.drawPath(cross, _line(ink, .07));
        continue;
      }
      if (wince > .5) {
        final x = center.dx;
        c.drawPath(
          Path()
            ..moveTo(x - side * .16, -.38)
            ..lineTo(x + side * .12, -.26)
            ..lineTo(x - side * .16, -.14),
          _line(ink, .075),
        );
        continue;
      }
      c.drawOval(eye, _fill(fury ? const Color(0xffffe3b8) : cream));
      final pupil = center + Offset(-.09, .03 + eyeShift);
      final size = surprised ? .72 : 1.0;
      if (fury) {
        c.drawCircle(pupil, .135, _fill(ember));
        c.drawOval(
          Rect.fromCenter(center: pupil, width: .11, height: .19),
          _fill(ink),
        );
      } else {
        // Big dark pupils ringed in pale gold: the old family's eyes, still
        // the brightest thing on him at play size.
        c.drawCircle(pupil, .128 * size, _fill(_irisDeep));
        c.drawCircle(
          pupil + const Offset(-.006, -.01),
          .108 * size,
          _fill(_iris),
        );
        c.drawOval(
          Rect.fromCenter(
            center: pupil,
            width: .17 * size,
            height: .235 * size,
          ),
          _fill(ink),
        );
      }
      c.drawCircle(pupil + const Offset(-.04, -.075), .045, _white);
      c.drawCircle(pupil + const Offset(.045, .06), .018, _white);
      // A heavy lid slants toward the nose; it drops in fury, charge and
      // blinks. The far lid hangs a little lower: a bored, superior look.
      final drop =
          .02 +
          (fury ? .07 : 0) +
          charge * .05 +
          blink * .48 +
          lidMood +
          (side > 0 && !fury ? .03 : 0);
      final outer = Offset(side * .66, -.47 + drop);
      final inner = Offset(side * .07, -.33 + drop);
      final lid = Path()..moveTo(outer.dx, outer.dy);
      _quad(lid, (outer + inner) / 2 + const Offset(0, .03), inner);
      c.save();
      c.clipRRect(RRect.fromRectXY(eye, eye.width / 2, eye.height / 2));
      c.drawPath(
        Path.from(lid)
          ..lineTo(inner.dx, -.6)
          ..lineTo(outer.dx, -.6)
          ..close(),
        _fill(_lid),
      );
      c.restore();
      c.drawPath(lid, _line(ink, .06));
    }
    // Lower lids: a tired, superior old roué.
    c.drawPath(
      _eyeBags,
      _line(const Color(0xff6f58a3).withValues(alpha: .55), .026),
    );
    // Tapered brows with a fur flick at the outer end: steeper in fury,
    // lifted and worried in defeat. At rest the far brow is cocked.
    var tilt = motion.defeated
        ? -.16
        : (fury ? .07 : 0) + charge * .04 - wince * .05 + browMood;
    if (storm != null && !motion.defeated) tilt += storm.glow * .09;
    final brows = Path();
    for (final side in [-1.0, 1.0]) {
      final cock = side > 0 && !fury && !motion.defeated ? .06 : 0.0;
      final outer = Offset(side * .76, -.64 - tilt * .4 - cock);
      final inner = Offset(side * .1, -.47 + tilt - cock * .3);
      brows
        ..moveTo(outer.dx + side * .06, outer.dy - .08)
        ..quadraticBezierTo(
          outer.dx,
          outer.dy - .03,
          outer.dx - side * .02,
          outer.dy - .02,
        )
        ..quadraticBezierTo(
          side * .42,
          (outer.dy + inner.dy) / 2 - .09,
          inner.dx,
          inner.dy - .07,
        )
        ..lineTo(inner.dx, inner.dy + .06)
        ..quadraticBezierTo(
          side * .44,
          (outer.dy + inner.dy) / 2 + .01,
          outer.dx,
          outer.dy + .03,
        )
        ..close();
    }
    c.drawPath(brows, _fill(ink));
    // The pug nose with its little leaf.
    c.drawPath(_nose, _fill(_noseColor));
    c.drawPath(_noseLitPath, _line(_noseLit, .028));
    c.drawPath(_nostrils, _fill(ink));
    c.drawPath(_nose, _line(ink, .032));
    mouth(c, motion, charge, fury, storm);
    if (scowl) {
      final mark = Path();
      for (var turn = 0; turn < 4; turn++) {
        final a = turn * math.pi / 2 + .3;
        final cos = math.cos(a), sin = math.sin(a);
        Offset at(double x, double y) =>
            const Offset(.74, -.46) +
            Offset(x * cos - y * sin, x * sin + y * cos);
        final from = at(.04, .14), bend = at(.055, .055), to = at(.14, .04);
        mark
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(bend.dx, bend.dy, to.dx, to.dy);
      }
      c.drawPath(mark, _line(ink, .1));
      c.drawPath(mark, _line(ember, .05));
    }
  }

  static void mouth(
    Canvas c,
    BossMotion motion,
    double charge,
    bool fury, [
    BaronStormPose? storm,
  ]) {
    final (rest, range) = switch (motion.mood) {
      StoryMood.happy => (.2, .55),
      StoryMood.surprised => (.3, .45),
      StoryMood.angry => (.1, .8),
      StoryMood.sad => (0.0, .45),
      _ => (0.0, .65),
    };
    final fight = math.max(motion.mouth, release(motion) * .6);
    final open = motion.voiced(fight, rest: rest, range: range).clamp(0.0, 1.0);
    final smile = switch (motion.mood) {
      StoryMood.happy => 1.0,
      StoryMood.sad => -1.0,
      _ => 0.0,
    };
    final left = Offset(-.44 - smile.abs() * .03, .04 - smile * .08);
    final right = Offset(.38 + smile.abs() * .03, .06 - smile * .08);
    const top = Offset(-.04, .16);
    Offset along(double t) =>
        left * ((1 - t) * (1 - t)) + top * (2 * t * (1 - t)) + right * (t * t);
    final drop = open * (storm == null ? .3 : .55);
    final mouth = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(top.dx, top.dy, right.dx, right.dy)
      ..cubicTo(.3, .3 + drop, -.32, .36 + drop, left.dx, left.dy)
      ..close();
    c.drawPath(mouth, _fill(ink));
    c.save();
    c.clipPath(mouth);
    if (charge > 0 || (fury && open > .1)) {
      final heat = math.max(charge, fury ? open * .6 : 0);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-.04, .2 + drop * .6),
          width: .5,
          height: .12 + drop,
        ),
        _fill((fury ? ember : gold).withValues(alpha: .75 * heat)),
      );
    }
    if (storm != null) BaronStormArt.throat(c, storm, drop, fury);
    if (storm == null || storm.jaw < .4) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-.06, .3 + drop),
          width: .22,
          height: .08 + open * .05,
        ),
        _fill(_tongue),
      );
    }
    c.restore();
    // A smug crease at the far corner.
    if (smile >= 0 && !motion.defeated) {
      c.drawPath(
        Path()
          ..moveTo(right.dx - .02, right.dy - .01)
          ..quadraticBezierTo(
            right.dx + .07,
            right.dy - .02,
            right.dx + .08,
            right.dy - .1,
          ),
        _line(ink, .035),
      );
    }
    final fang = storm != null ? (fury ? .21 : .19) : (fury ? .19 : .17);
    final fangs = Path();
    for (final t in [.27, .72]) {
      final at = along(t);
      fangs
        ..moveTo(at.dx - .065, at.dy - .02)
        ..quadraticBezierTo(at.dx - .03, at.dy + fang * .6, at.dx, at.dy + fang)
        ..quadraticBezierTo(
          at.dx + .045,
          at.dy + fang * .5,
          at.dx + .065,
          at.dy - .01,
        )
        ..close();
    }
    c.drawPath(fangs, _fill(cream));
    c.drawPath(fangs, _line(ink, .025));
  }

  // ---------------------------------------------------------------- crown --

  static final _cap = Path()
    ..moveTo(-.58, -.86)
    ..quadraticBezierTo(-.56, -1.44, 0, -1.48)
    ..quadraticBezierTo(.56, -1.44, .58, -.86)
    ..close();
  static final _capPaint = _lin(
    const Rect.fromLTRB(-.6, -1.5, .6, -.86),
    const [Color(0xffd0507e), _velvet, _velvetDeep],
    const [0, .45, 1],
  );
  static final _capFold = Path()
    ..moveTo(-.04, -1.44)
    ..quadraticBezierTo(-.2, -1.24, -.22, -1.02)
    ..moveTo(.3, -1.36)
    ..quadraticBezierTo(.36, -1.2, .34, -1.04);
  static final _crown = Path()
    ..moveTo(-.6, -.7)
    ..lineTo(-.74, -1.46)
    ..lineTo(-.33, -1.18)
    ..lineTo(0, -1.74)
    ..lineTo(.33, -1.18)
    ..lineTo(.74, -1.46)
    ..lineTo(.6, -.7)
    ..quadraticBezierTo(0, -.94, -.6, -.7)
    ..close();
  static final _crownPaint = _lin(
    const Rect.fromLTWH(-.75, -1.75, 1.5, 1.05),
    const [cream, gold, _bronze],
  );
  static final _band = Path()
    ..moveTo(-.63, -.86)
    ..quadraticBezierTo(0, -1.1, .63, -.86)
    ..lineTo(.6, -.7)
    ..quadraticBezierTo(0, -.94, -.6, -.7)
    ..close();
  static final _bandPaint = _lin(
    const Rect.fromLTRB(-.63, -1.0, .63, -.7),
    const [Color(0xfff3c766), _goldDeep, Color(0xff9c5f2a)],
  );
  static final _bevel = Path()
    ..moveTo(-.66, -1.32)
    ..lineTo(-.58, -.96)
    ..moveTo(-.06, -1.58)
    ..lineTo(-.24, -1.18)
    ..moveTo(.68, -1.34)
    ..lineTo(.62, -1.02);
  static final _engraving = () {
    final p = Path();
    for (final x in const [-.5, -.18, .18, .5]) {
      final y = -.8 - .1 * (1 - (x / .62) * (x / .62));
      p
        ..moveTo(x - .045, y)
        ..lineTo(x, y - .035)
        ..lineTo(x + .045, y)
        ..lineTo(x, y + .035)
        ..close();
    }
    return p;
  }();
  static final _bandGems = Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(-.34, -.84),
        width: .13,
        height: .11,
      ),
    )
    ..addOval(
      Rect.fromCenter(center: const Offset(.34, -.84), width: .13, height: .11),
    );
  static final _pearls = Path()
    ..addOval(Rect.fromCircle(center: const Offset(-.74, -1.46), radius: .06))
    ..addOval(Rect.fromCircle(center: const Offset(0, -1.74), radius: .06))
    ..addOval(Rect.fromCircle(center: const Offset(.74, -1.46), radius: .06));
  static final _pearlRims = Path()
    ..addOval(Rect.fromCircle(center: const Offset(-.74, -1.46), radius: .088))
    ..addOval(Rect.fromCircle(center: const Offset(0, -1.74), radius: .088))
    ..addOval(Rect.fromCircle(center: const Offset(.74, -1.46), radius: .088));
  static final _jewel = Path()
    ..moveTo(0, -1.42)
    ..lineTo(.14, -1.24)
    ..lineTo(0, -1.05)
    ..lineTo(-.14, -1.24)
    ..close();
  static final _jewelPaint = _lin(
    const Rect.fromLTWH(-.14, -1.42, .28, .37),
    const [cream, ember, Color(0xff932e63)],
  );

  /// Scrolls engraved up each point.
  static final _filigreeCrown = () {
    final p = Path();
    for (final (x, top, s) in const [(-.6, -1.22, 1.0), (.6, -1.22, -1.0)]) {
      p
        ..moveTo(x, -1.0)
        ..quadraticBezierTo(x - s * .06, top + .12, x, top)
        ..quadraticBezierTo(x + s * .07, top + .04, x + s * .03, top + .1);
    }
    return p;
  }();
  static final _filigreeCrownPaint = _line(
    const Color(0xffa8662c).withValues(alpha: .55),
    .022,
  );

  /// A dent in the right point: the heirloom has been dropped before.
  static final _dent = Path()
    ..moveTo(.5, -1.31)
    ..quadraticBezierTo(.52, -1.25, .47, -1.2);

  /// The velvet cap inside the crown (crown coordinates, before the tilt
  /// is undone): shared with the storm crown.
  static void crownCap(Canvas c) {
    c.drawPath(_cap, _capPaint);
    c.drawPath(_capFold, _line(_velvetDeep.withValues(alpha: .7), .03));
    c.drawPath(_cap, _line(ink, .045));
  }

  /// The band's darker gold, after the crown's own fill.
  static void crownBandFill(Canvas c) => c.drawPath(_band, _bandPaint);

  /// The engraved band's diamonds, its lit top edge and two cabochons of
  /// [gem], after the crown's outline. Shared with the storm crown.
  static void crownBand(Canvas c, Color gem, Color gemDeep) {
    c.drawPath(_engraving, _fill(const Color(0xff8a5122)));
    c.drawPath(_bandLight, _line(cream.withValues(alpha: .7), .025));
    c.drawPath(_bandGems, _fill(gemDeep));
    c.drawPath(_bandGems.shift(const Offset(-.012, -.012)), _fill(gem));
  }

  static final _bandLight = Path()
    ..moveTo(-.5, -.95)
    ..quadraticBezierTo(0, -1.13, .5, -.95);

  /// The heirloom crown in body coordinates, seated with a jaunty tilt over
  /// a velvet cap. Also drawn alone when knocked off and as the keepsake.
  static void crown(Canvas c) {
    c.save();
    c.translate(0, -.84);
    c.rotate(.09);
    c.translate(0, .84);
    crownCap(c);
    c.drawPath(_crown.shift(const Offset(.03, .06)), _inkFill);
    c.drawPath(_crown, _crownPaint);
    c.drawPath(_band, _bandPaint);
    c.drawPath(_bevel, _line(cream.withValues(alpha: .75), .03));
    c.drawPath(_dent, _line(_bronze, .03));
    c.drawPath(_filigreeCrown, _filigreeCrownPaint);
    c.drawPath(_crown, _line(ink, .055));
    crownBand(c, _amethyst, _amethystDeep);
    c.drawPath(_pearlRims, _inkFill);
    c.drawPath(_pearls, _fill(cream));
    c.drawPath(_jewel, _jewelPaint);
    c.drawPath(
      Path()
        ..moveTo(-.07, -1.26)
        ..lineTo(0, -1.36)
        ..lineTo(.02, -1.25),
      _line(const Color(0xffffffff).withValues(alpha: .8), .022),
    );
    c.drawPath(_jewel, _line(ink, .03));
    c.restore();
  }
}
