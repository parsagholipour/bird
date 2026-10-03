import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../neferhoo_kit.dart' show NeferhooPalette;
import 'simple_bat.dart' show SimpleBatArt;

/// Neferhoo's mummy bats: the helpers that fly out of the pyramid with his
/// mail calls (EnemyKind.mummyBat).
///
/// A tiny bat in the family of [SimpleBatArt]: the same proportions at the
/// 16 px gameplay radius, the same wing rig, flap and glide rhythm, blink,
/// look and charge/recoil, and the same Reduced Motion glide. It is wound in
/// his cool moon-linen (bands over the brow and belly, bound ears), with two glowing turquoise eyes (his magic)
/// in gaps of the wraps, a little lapis postage stamp with a red postmark
/// slapped on the belly, wings of dusty plum with linen-wrapped wrists, and
/// one loose bandage end that trails behind, its tip aglow like his own
/// ribbons. The rig looks left by default; the caller owns facing. Every
/// pose stays within x ±1.9r, y ±1.2r.
///
/// Cost: about as many draw calls as the simple bat (both wings, both ears,
/// both eyes are batched into one path each), no layer, no blur, no clip;
/// everything static is built once (call [prewarm] before the fight).
abstract final class MummyBatArt {
  /// One wingbeat: the very same as the simple bat's, so a mixed flock flaps
  /// in one rhythm.
  static const cycleSeconds = SimpleBatArt.cycleSeconds;

  static const _arcRate = 2.8;
  static const _blinkEvery = 3.7, _blinkAt = 2.1, _blinkSeconds = .15;

  // ---- palette: his linen, his magic, his postal ink ----
  static const _ink = NeferhooPalette.ink;
  static const _linenHi = NeferhooPalette.linenHi;
  static const _linenLit = NeferhooPalette.linenLit;
  static const _linen = NeferhooPalette.linen;
  static const _linenWarm = Color(0xfffff8ea);
  static const _linenShade = Color(0xffcdc4de);
  static const _seam = Color(0xff5f5680);
  static const _magic = NeferhooPalette.magic;
  static const _turq = NeferhooPalette.turq;

  // Dusty plum: the membrane. Pinker and greyer than the simple bat's violet.
  static const _plumLit = Color(0xffc9a0c4);
  static const _plumMid = Color(0xff8a5f8e);
  static const _plumDark = Color(0xff4a3157);
  static const _plumEar = Color(0xff7a5382);
  static const _earInner = Color(0xffe6a9c4);

  static const _body = Rect.fromLTRB(-.68, -.62, .68, .68);
  static const _shoulder = Offset(.36, -.18), _hip = Offset(.38, .32);

  // Right-wing key poses, the simple bat's own: wrist, tip, three fingers.
  static const _raised = 0, _spread = 1;
  static const _keyTimes = [0.0, .22, .45, .72];
  static const _keys = [
    [
      Offset(.72, -.92),
      Offset(1.36, -1.1),
      Offset(1.5, -.66),
      Offset(1.26, -.3),
      Offset(.86, -.04),
    ],
    [
      Offset(.98, -.74),
      Offset(1.74, -.5),
      Offset(1.62, .1),
      Offset(1.2, .4),
      Offset(.76, .48),
    ],
    [
      Offset(1.06, -.3),
      Offset(1.56, .32),
      Offset(1.24, .72),
      Offset(.9, .74),
      Offset(.62, .6),
    ],
    [
      Offset(.9, -.72),
      Offset(1.42, -.28),
      Offset(1.26, .1),
      Offset(.98, .3),
      Offset(.7, .4),
    ],
  ];

  // ---- paints (built once) ----
  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final _bodyPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_linenWarm, Color(0xfff1ebf0), _linenShade],
    ).createShader(_body);
  // Mirror-symmetric (both wings are one fill): lit on top, dark below.
  static final _wingPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_plumLit, _plumMid, _plumDark],
    ).createShader(const Rect.fromLTRB(-1.8, -1.1, 1.8, .8));
  static final _tailPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_linenHi, _linen, _linenShade],
    ).createShader(const Rect.fromLTRB(.2, .4, 1.1, 1.2));

  static final _inkFill = _fill(_ink);
  static final _outline = _line(_ink, .07);
  static final _outlineFine = _line(_ink, .05);
  static final _outlineHair = _line(_ink, .03);
  static final _bones = _line(_plumLit.withValues(alpha: .75), .035);
  static final _armInk = _line(_ink, .2);
  static final _armLinen = _line(_linenLit, .11);
  static final _cuffInk = _line(_ink, .25);
  static final _cuffLinen = _line(_linenHi, .17);
  static final _seamLine = _line(_seam.withValues(alpha: .8), .05);
  static final _earFill = _fill(_plumEar);
  static final _earLine = _line(_earInner, .07);
  static final _linenHiFill = _fill(_linenHi);
  static final _bandLit = _fill(_linenHi.withValues(alpha: .9));
  static final _haloFill = _fill(_magic.withValues(alpha: .5));
  static final _irisFill = _fill(_turq);
  static final _coreFill = _fill(_magic);
  static final _glint = _fill(const Color(0xffffffff));
  static final _sparkHalo = _fill(_magic.withValues(alpha: .35));
  static final _sparkCore = _fill(NeferhooPalette.turqLit);
  static final _stampField = _fill(NeferhooPalette.lapis);
  static final _stampGlyph = _fill(const Color(0xfffff6dc));
  static final _stampSun = _fill(NeferhooPalette.goldLit);
  static final _postmark = _line(
    NeferhooPalette.stampInk.withValues(alpha: .85),
    .04,
  );

  // ---- cached geometry (unit space, built once) ----

  /// A tiny affine map as a column-major matrix: x' = ax + cy + e, y' = bx + dy + f.
  static Float64List _affine(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) => Float64List.fromList([a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1]);

  static final Float64List _mirror = _affine(-1, 0, 0, 1, 0, 0);

  /// [right] and its mirror image: one path for a pair.
  static Path _pair(Path right) => Path()
    ..addPath(right, Offset.zero)
    ..addPath(right.transform(_mirror), Offset.zero);

  /// A wind of linen across the body: its middle height, slope and bow.
  static Offset _windAt(double y0, double slope, double bow, double x) {
    final u = x / .75;
    return Offset(x, y0 + slope * x + bow * (1 - u * u));
  }

  /// The wind's line from one side of the body to the other, ending exactly
  /// on the outline (so nothing needs a clip).
  static List<Offset> _wind(double y0, double slope, double bow) {
    double edge(double dir) {
      var lo = 0.0, hi = .9;
      for (var k = 0; k < 24; k++) {
        final mid = (lo + hi) / 2;
        final p = _windAt(y0, slope, bow, dir * mid);
        final inside =
            math.pow(p.dx / (_body.width / 2), 2) +
                math.pow((p.dy - _body.center.dy) / (_body.height / 2), 2) <
            1;
        if (inside) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      return dir * lo;
    }

    final l = edge(-1), r = edge(1);
    return [
      for (var k = 0; k <= 10; k++)
        _windAt(y0, slope, bow, l + (r - l) * k / 10),
    ];
  }

  static void _poly(Path path, List<Offset> pts, {bool move = true}) {
    if (move) path.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(move ? 1 : 0)) {
      path.lineTo(p.dx, p.dy);
    }
  }

  /// Strips of linen: (middle height, slope, bow, half width).
  static const _strips = [
    // Across the brow, over the ears' feet.
    (-.5, .1, -.05, .09),
    // Under the mouth and round the belly, rising to the right.
    (.22, -.24, .06, .07),
    (.52, -.24, .07, .07),
  ];

  /// The strips' bright faces (one fill) and the seam under each (one line).
  static final Path _bandFaces = () {
    final path = Path();
    for (final (y0, slope, bow, half) in _strips) {
      final top = _wind(y0 - half, slope, bow);
      final bottom = _wind(y0 + half, slope, bow).reversed.toList();
      _poly(path, [...top, ...bottom]);
      path.close();
    }
    return path;
  }();
  static final Path _seams = () {
    final path = Path();
    for (final (y0, slope, bow, half) in _strips) {
      _poly(path, _wind(y0 + half, slope, bow));
    }
    return path;
  }();

  // The ears (one pair), the linen bound round each, and the inner highlight.
  static final Path _ear = Path()
    ..moveTo(.52, -.4)
    ..lineTo(.79, -1.06)
    ..quadraticBezierTo(.34, -.88, .14, -.5)
    ..close();
  static final Path _ears = _pair(_ear);
  static final Path _earBands = () {
    final band = Path()
      ..moveTo(.0, -.62)
      ..lineTo(1.0, -.74)
      ..lineTo(1.0, -.84)
      ..lineTo(.0, -.72)
      ..close();
    return _pair(Path.combine(PathOperation.intersect, _ear, band));
  }();
  static final Path _earLines = _pair(
    Path()
      ..moveTo(.52, -.62)
      ..lineTo(.67, -.92),
  );

  // The eyes: two gaps in the winds (sockets), each turned a little (the
  // inner end low: a sly look), the glowing eye in each under a lid of linen
  // lowered over its inner half. Authored for the right eye, in a frame whose
  // +x points outward and whose origin is the eye's centre.
  static const _eyeAt = Offset(.285, -.21), _socketTilt = .2;
  static const _lidInner = Offset(-.2, .04), _lidOuter = Offset(.2, -.11);
  static const _lidPivot = -.04;
  static final Path _socket = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-.235, -.18, .235, .18),
        const Radius.circular(.18),
      ),
    );
  static Path _lidded(double w, double h, double dy) {
    final eye = Path()
      ..addOval(Rect.fromCenter(center: Offset(0, dy), width: w, height: h));
    final rise = (_lidInner.dy - _lidOuter.dy) * .5;
    final lid = Path()
      ..moveTo(_lidInner.dx - .1, _lidInner.dy + rise)
      ..lineTo(_lidOuter.dx + .1, _lidOuter.dy - rise)
      ..lineTo(_lidOuter.dx + .1, -.4)
      ..lineTo(_lidInner.dx - .1, -.4)
      ..close();
    return Path.combine(PathOperation.difference, eye, lid);
  }

  static final Path _iris = _lidded(.33, .36, .02);
  static final Path _core = _lidded(.21, .25, .035);
  static Path _haloOf(double r) =>
      Path()..addOval(Rect.fromCircle(center: const Offset(0, .02), radius: r));

  /// Where an eye's local frame sits on the face: [side] is -1 (left) or 1;
  /// [squash] flattens the eye onto its lid (a blink).
  static Float64List _eye(double side, {double squash = 1}) {
    final cos = math.cos(_socketTilt), sin = math.sin(_socketTilt);
    final a = side * cos, b = sin, c = -side * sin, d = cos;
    final e = side * _eyeAt.dx, f = _eyeAt.dy;
    final k = squash, p = _lidPivot * (1 - squash);
    return _affine(a, b, c * k, d * k, e + c * p, f + d * p);
  }

  static Path _eyes(Path local, {double squash = 1}) => Path()
    ..addPath(local.transform(_eye(-1, squash: squash)), Offset.zero)
    ..addPath(local.transform(_eye(1, squash: squash)), Offset.zero);

  static final Path _sockets = _eyes(_socket);
  static final Path _irises = _eyes(_iris);
  static final Path _cores = _eyes(_core);
  static final Path _halos = _eyes(_haloOf(.2));

  static final Path _mouth = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-.17, .03, .17, .13),
        const Radius.circular(.05),
      ),
    );
  static final Path _fangs = Path()
    ..moveTo(-.13, .04)
    ..lineTo(-.08, .15)
    ..lineTo(-.03, .04)
    ..moveTo(.03, .04)
    ..lineTo(.08, .15)
    ..lineTo(.13, .04);

  // The stamp (centred, tilted when drawn): a perforated cream edge, a lapis
  // field, a cream pyramid under a gold sun, and the red postmark.
  static const _stampRect = Rect.fromLTRB(-.2, -.23, .2, .23);
  static final Path _stampShape = () {
    // A rectangle with a round bite out of the middle of each perforation
    // span, built from arcs so one fill and one line draw it.
    const nx = 3, ny = 4, bite = .03;
    final r = _stampRect;
    final dx = r.width / nx, dy = r.height / ny;
    final path = Path()..moveTo(r.left, r.top);
    void bit(Offset to, Offset along) {
      path
        ..lineTo(to.dx - along.dx * bite, to.dy - along.dy * bite)
        ..arcToPoint(
          Offset(to.dx + along.dx * bite, to.dy + along.dy * bite),
          radius: const Radius.circular(bite),
          clockwise: false,
        );
    }

    for (var k = 0; k < nx; k++) {
      bit(Offset(r.left + (k + .5) * dx, r.top), const Offset(1, 0));
    }
    path.lineTo(r.right, r.top);
    for (var k = 0; k < ny; k++) {
      bit(Offset(r.right, r.top + (k + .5) * dy), const Offset(0, 1));
    }
    path.lineTo(r.right, r.bottom);
    for (var k = nx - 1; k >= 0; k--) {
      bit(Offset(r.left + (k + .5) * dx, r.bottom), const Offset(-1, 0));
    }
    path.lineTo(r.left, r.bottom);
    for (var k = ny - 1; k >= 0; k--) {
      bit(Offset(r.left, r.top + (k + .5) * dy), const Offset(0, -1));
    }
    return path..close();
  }();
  static final Path _stampInner = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        _stampRect.deflate(.05),
        const Radius.circular(.012),
      ),
    );
  static final Path _pyramid = Path()
    ..moveTo(-.115, .13)
    ..lineTo(.01, -.04)
    ..lineTo(.115, .13)
    ..close();
  static final Rect _postmarkRing = Rect.fromCircle(
    center: const Offset(.12, .17),
    radius: .1,
  );

  /// Builds every cached path, gradient and paint the bat will ask for, by
  /// painting a few poses into a picture nobody sees, so that no frame of a
  /// fight builds one. Pure and idempotent: safe to call as often as you like
  /// (Neferhoo's own prewarm does, during the countdown).
  static void prewarm() {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    for (final (seconds, reduced, charge, recoil) in const [
      (.1, false, 0.0, 0.0),
      (2.15, false, 1.0, 0.0),
      (1.7, false, 0.0, 1.0),
      (0.0, true, 0.0, 0.0),
    ]) {
      paint(
        c,
        16,
        seconds: seconds,
        reducedMotion: reduced,
        lookY: .5,
        charge: charge,
        recoil: recoil,
      );
    }
    recorder.endRecording().dispose();
  }

  static void paint(
    Canvas c,
    double radius, {
    required double seconds,
    required bool reducedMotion,
    double lookY = 0,
    double charge = 0,
    double recoil = 0,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    final time = seconds.isFinite && seconds > 0 ? seconds : 0.0;
    final look = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    final tense = charge.isFinite ? charge.clamp(0.0, 1.0) : 0.0;
    final kick = recoil.isFinite ? recoil.clamp(0.0, 1.0) : 0.0;
    final phase = (time / cycleSeconds) % 1;
    // Reduced Motion holds the glide: the clearest, most bat-like silhouette.
    final glide = reducedMotion ? 1.0 : _glide(time);
    // The downstroke lifts the body; it sinks through the recovery.
    final bob = .05 * (1 - glide) * math.cos((phase - .08) * math.pi * 2);
    final blinkAge = (time % _blinkEvery) - _blinkAt;
    final blink = reducedMotion || blinkAge < 0 || blinkAge > _blinkSeconds
        ? 0.0
        : math.sin(blinkAge / _blinkSeconds * math.pi);

    final wing = [
      for (var point = 0; point < 5; point++)
        Offset.lerp(
          Offset.lerp(_pose(point, phase), _keys[_spread][point], glide),
          _keys[_raised][point],
          tense * .5,
        )!,
    ];

    c.save();
    c.scale(radius);
    c.translate(0, bob);
    // Wind-up and recoil only squash, so no pose can leave the art box.
    if (!reducedMotion) {
      c.scale(1 + tense * .04 - kick * .06, 1 - tense * .04 - kick * .03);
    }
    _wings(c, wing);
    _trail(c, phase, reducedMotion);
    _head(c);
    _torso(c);
    _face(c, look, blink, math.max(tense * .6, kick));
    _stampOnBelly(c);
    c.restore();
  }

  static double _glide(double time) {
    final t = ((math.cos(time * _arcRate) - .35) / .5).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// Cubic Hermite through the key poses; Catmull-Rom tangents over the uneven
  /// key timing keep each point's path and speed continuous (no pops).
  static Offset _pose(int point, double phase) {
    var i = _keyTimes.length - 1;
    while (phase < _keyTimes[i]) {
      i--;
    }
    final j = (i + 1) % _keyTimes.length;
    final t0 = _keyTimes[i], t1 = j == 0 ? 1.0 : _keyTimes[j];
    final dt = t1 - t0;
    final s = (phase - t0) / dt, s2 = s * s, s3 = s * s * s;
    return _keys[i][point] * (2 * s3 - 3 * s2 + 1) +
        _tangent(point, i) * (dt * (s3 - 2 * s2 + s)) +
        _keys[j][point] * (3 * s2 - 2 * s3) +
        _tangent(point, j) * (dt * (s3 - s2));
  }

  static Offset _tangent(int point, int k) {
    const n = 4;
    final prev = (k + n - 1) % n, next = (k + 1) % n;
    final tPrev = _keyTimes[prev] - (prev > k ? 1 : 0);
    final tNext = _keyTimes[next] + (next < k ? 1 : 0);
    return (_keys[next][point] - _keys[prev][point]) / (tNext - tPrev);
  }

  // Scallops dip toward the wrist, so fingers stay pointed in every pose.
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

  /// Both wings at once (the right one authored, the left its mirror image):
  /// the membrane with its ink shadow and outline, the finger bones, the arm
  /// bound in linen along the leading edge, and a cuff of winds at the wrist.
  static void _wings(Canvas c, List<Offset> wing) {
    final [wrist, tip, f1, f2, f3] = wing;
    final membrane = Path()..moveTo(_shoulder.dx, _shoulder.dy);
    _quad(membrane, _bulge(_shoulder, wrist, .14), wrist);
    _quad(membrane, _bulge(wrist, tip, .05), tip);
    _quad(membrane, _toward(tip, f1, wrist, .34), f1);
    _quad(membrane, _toward(f1, f2, wrist, .36), f2);
    _quad(membrane, _toward(f2, f3, wrist, .36), f3);
    _quad(membrane, _toward(f3, _hip, _shoulder, .3), _hip);
    membrane.close();

    final bones = Path();
    for (final finger in [f1, f2]) {
      bones.moveTo(wrist.dx, wrist.dy);
      _quad(bones, _bulge(wrist, finger, -.04), finger);
    }
    final elbow = Offset.lerp(_shoulder, wrist, .55)!;
    bones
      ..moveTo(elbow.dx, elbow.dy)
      ..lineTo(f3.dx, f3.dy);

    final arm = Path()..moveTo(_shoulder.dx, _shoulder.dy);
    _quad(arm, _bulge(_shoulder, wrist, .14), wrist);
    final along = (wrist - _shoulder) / (wrist - _shoulder).distance;
    final cuffFrom = wrist - along * .32;
    final cuffTo = wrist - along * .09;
    final cuff = Path()
      ..moveTo(cuffFrom.dx, cuffFrom.dy)
      ..lineTo(cuffTo.dx, cuffTo.dy);
    final ticks = Path();
    final across = Offset(-along.dy, along.dx) * .09;
    for (final t in const [.28, .55, .82]) {
      final at = Offset.lerp(cuffFrom, cuffTo, t)!;
      ticks
        ..moveTo(
          at.dx - across.dx - along.dx * .03,
          at.dy - across.dy - along.dy * .03,
        )
        ..lineTo(
          at.dx + across.dx + along.dx * .03,
          at.dy + across.dy + along.dy * .03,
        );
    }

    final pairMembrane = _pair(membrane);
    c.drawPath(_pair(membrane.shift(const Offset(.02, .05))), _inkFill);
    c.drawPath(pairMembrane, _wingPaint);
    c.drawPath(_pair(bones), _bones);
    c.drawPath(pairMembrane, _outline);
    final pairArm = _pair(arm), pairCuff = _pair(cuff);
    c.drawPath(pairArm, _armInk);
    c.drawPath(pairArm, _armLinen);
    c.drawPath(pairCuff, _cuffInk);
    c.drawPath(pairCuff, _cuffLinen);
    c.drawPath(_pair(ticks), _seamLine);
  }

  /// The ears with the linen bound round them, behind the body.
  static void _head(Canvas c) {
    c.drawPath(_ears, _earFill);
    c.drawPath(_earBands, _linenHiFill);
    c.drawPath(_earLines, _earLine);
    c.drawPath(_ears, _outline);
  }

  /// The loose bandage end: it leaves from under the belly's last wind and
  /// streams behind the bat in a slow S, waving with the wingbeat, its tip
  /// aglow with his magic.
  static void _trail(Canvas c, double phase, bool reduced) {
    final wave = reduced ? .3 : phase * math.pi * 2;
    const n = 8;
    final pts = <Offset>[];
    final half = <double>[];
    for (var i = 0; i <= n; i++) {
      final s = i / n;
      final sway = math.sin(wave - s * 3.6) * (reduced ? .035 : .08) * s;
      final droop = .07 * math.sin(s * math.pi);
      pts.add(Offset(.3 + .92 * s - sway * .3, .5 + .4 * s + droop + sway));
      half.add(.1 - .06 * s);
    }
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final a = pts[math.max(0, i - 1)], b = pts[math.min(n, i + 1)];
      final d = b - a;
      final len = d.distance;
      final nr = len == 0 ? const Offset(0, 1) : Offset(-d.dy, d.dx) / len;
      left.add(pts[i] + nr * half[i]);
      right.add(pts[i] - nr * half[i]);
    }
    final end = pts.last;
    final dir = (end - pts[n - 1]) / (end - pts[n - 1]).distance;
    final nr = Offset(-dir.dy, dir.dx);
    final path = Path();
    _poly(path, left);
    // The end tapers to a point, where the magic sits.
    path
      ..lineTo(
        end.dx + dir.dx * .1 + nr.dx * .03,
        end.dy + dir.dy * .1 + nr.dy * .03,
      )
      ..lineTo(end.dx + dir.dx * .15, end.dy + dir.dy * .15)
      ..lineTo(
        end.dx + dir.dx * .1 - nr.dx * .03,
        end.dy + dir.dy * .1 - nr.dy * .03,
      );
    _poly(path, right.reversed.toList(), move: false);
    path.close();
    c.drawPath(path, _tailPaint);
    c.drawPath(path, _outlineFine);
    final ticks = Path();
    for (final i in const [2, 4]) {
      ticks
        ..moveTo(left[i].dx, left[i].dy)
        ..lineTo(right[i].dx, right[i].dy);
    }
    c.drawPath(ticks, _seamLine);
    final spark = end + dir * .15;
    final pulse = reduced ? 1.0 : 1 + .18 * math.sin(phase * math.pi * 4);
    c.drawCircle(spark, .1 * pulse, _sparkHalo);
    c.drawCircle(spark, .045, _sparkCore);
  }

  static void _torso(Canvas c) {
    c.drawOval(_body.shift(const Offset(.03, .06)), _inkFill);
    c.drawOval(_body, _bodyPaint);
    c.drawPath(_bandFaces, _bandLit);
    c.drawPath(_seams, _seamLine);
    c.drawOval(_body, _outline);
  }

  static void _face(Canvas c, double look, double blink, double open) {
    final flare = 1 + open * .35;
    c.drawPath(_sockets, _inkFill);
    c.drawPath(flare == 1 ? _halos : _eyes(_haloOf(.2 * flare)), _haloFill);
    final squash = 1 - blink * .9;
    c.drawPath(blink == 0 ? _irises : _eyes(_iris, squash: squash), _irisFill);
    c.drawPath(blink == 0 ? _cores : _eyes(_core, squash: squash), _coreFill);
    if (blink < .5) {
      // The pupils turn toward the bird (screen-left) and follow its height.
      final pupils = Path(), glints = Path();
      for (final side in const [-1.0, 1.0]) {
        final at = Offset(-.045 * side, .045 + look * .05);
        final m = _eye(side);
        Offset place(Offset p) => Offset(
          m[0] * p.dx + m[4] * p.dy + m[12],
          m[1] * p.dx + m[5] * p.dy + m[13],
        );
        pupils.addOval(
          Rect.fromCenter(center: place(at), width: .1, height: .15),
        );
        glints.addOval(
          Rect.fromCircle(
            center: place(at + Offset(.025 * side, -.03)),
            radius: .028,
          ),
        );
      }
      c.drawPath(pupils, _inkFill);
      c.drawPath(glints, _glint);
    }
    c.drawPath(_mouth, _inkFill);
    c.drawPath(_fangs, _linenHiFill);
  }

  static void _stampOnBelly(Canvas c) {
    c.save();
    c.translate(.04, .45);
    c.rotate(-.22);
    c.scale(.96);
    c.drawPath(_stampShape, _linenHiFill);
    c.drawPath(_stampInner, _stampField);
    c.drawPath(_pyramid, _stampGlyph);
    c.drawCircle(const Offset(.08, -.1), .035, _stampSun);
    c.drawPath(_stampShape, _outlineHair);
    c.drawOval(_postmarkRing, _postmark);
    c.restore();
  }
}
