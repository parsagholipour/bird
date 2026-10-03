import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';

import '../../domain/sky_enemy.dart';
import '../crust_art.dart';
import '../star_art.dart';
import 'alley_pigeon_pose.dart';

export 'alley_pigeon_pose.dart';

/// A crust-throwing squadron pigeon's arm (King Coo's vanguard, rules
/// version 45): [windup] 0 to 1 through the wind-up (the enemy's charge),
/// [follow] 0 to 1 through the follow-through after the release (negative
/// when it has not just thrown).
typedef PigeonThrow = ({double windup, double follow});

/// The Alley Pigeon: New York's star thief, in side profile among the frontal
/// bats and moths. Drawn looking left in hit-radius units (r is the enemy's
/// hit radius; the bird spans x -1.6..1.9 and y -1.4..1.0, and x -2.4 with a
/// star in its beak); the caller owns facing, bank and knock-back. Every state
/// is a pure function of the enemy's own clock and raid state
/// ([PigeonPose.of]), so a replay, a pause or a seek draws the same bird.
///
/// The body, tail, collar, head and eye are cached paths placed with the
/// canvas matrix; the two wings are rebuilt each frame from a keyed rig (the
/// way the bats' wings are) as two small paths, because a wing has to swing
/// round its shoulder. Every gradient is built once, per plumage.
///
/// Three plumages (chosen by the pigeon's slot in its flock) keep a V of three
/// from being three copies: blue-bar, dark checker, pale white-wing.
abstract final class AlleyPigeonArt {
  /// One wingbeat while cruising. The downstroke is the quick clap.
  static const cycleSeconds = .50;

  /// Wingbeats while gloating, climbing away and fleeing (faster, flustered).
  static const hurryCycleSeconds = .32;

  /// The number of plumages ([PigeonPose.coat] is taken modulo this).
  static const coatCount = 3;

  // Palette: a cool blue-grey rock pigeon with an iridescent neck, a coral
  // beak and feet and an amber eye. The ink is a blue-black, not the skies'
  // teal ink, so the outline stays dark against every region.
  static const ink = Color(0xff18182f);
  static const _slate = Color(0xff2e3358);
  static const _grey = Color(0xffaab3d2), _greyLit = Color(0xffe8edfb);
  static const _greyShade = Color(0xff6d7599), _greyDeep = Color(0xff474e78);
  static const _belly = Color(0xfff2f3ff), _rump = Color(0xfffafaff);
  static const _cream = Color(0xfffff2c9);
  static const _coral = Color(0xffff8f63), _coralDeep = Color(0xffc9553f);
  static const _amber = Color(0xffffb23a);
  static const _rim = Color(0xffdbe6ff);

  // Line weights, in r.
  static const _outline = .085, _inner = .05, _bar = .17;

  // ------------------------------------------------------------ geometry --

  static const _head = Offset(-.80, -.48);
  static const _headR = .44;
  static const _tailRoot = Offset(.78, .02);

  static final Path _bodyPath = Path()
    ..moveTo(-.72, -.30)
    ..cubicTo(-.30, -.68, .40, -.72, .80, -.32)
    ..cubicTo(.98, -.12, .94, .30, .60, .52)
    ..cubicTo(.26, .76, -.42, .80, -.78, .42)
    ..cubicTo(-1.00, .16, -.94, -.14, -.72, -.30)
    ..close();
  static final Path _bodyShade = Path.combine(
    PathOperation.difference,
    _bodyPath,
    _bodyPath.shift(const Offset(-.08, -.13)),
  );
  static final Path _bellyPath = Path()
    ..addOval(const Rect.fromLTRB(-.72, .02, .46, .68));
  static final Path _rumpPath = Path()
    ..addOval(const Rect.fromLTRB(.50, -.34, .90, .14));
  static final Path _rimPath = Path()
    ..moveTo(-.02, -.63)
    ..cubicTo(.36, -.68, .74, -.46, .90, -.16);

  static final Path _collarPath = Path()
    ..moveTo(-.34, -.46)
    ..quadraticBezierTo(-.02, -.22, -.20, .14)
    ..quadraticBezierTo(-.58, .30, -.98, .04)
    ..quadraticBezierTo(-.86, -.26, -.34, -.46)
    ..close();
  static final Path _collarSheen = Path()
    ..moveTo(-.62, -.20)
    ..quadraticBezierTo(-.40, -.22, -.26, -.10);

  static final Path _feet = () {
    final p = Path();
    for (final x in const [-.16, .14]) {
      p
        ..moveTo(x, .58)
        ..lineTo(x - .04, .80)
        ..moveTo(x - .04, .80)
        ..lineTo(x - .17, .88)
        ..moveTo(x - .04, .80)
        ..lineTo(x - .02, .92)
        ..moveTo(x - .04, .80)
        ..lineTo(x + .10, .88);
    }
    return p;
  }();

  // The wing is a keyed rig in the body's frame: the wrist, the tip of the
  // outermost primary and three trailing feather tips, at four poses (raised,
  // spread, down, swept back for a dive). A key is five (radius, angle) pairs
  // about the shoulder (angles clockwise from +x, y down): blending those, not
  // the points, swings the wing round the shoulder instead of squashing it
  // flat between two poses, and keeping the feathers in order (leading to
  // trailing) keeps the fan open at every stroke.
  static const _wingShoulder = Offset(-.08, -.30);
  static const _wingRoot = Offset(.60, .10);
  static const _wingScale = 1.12;
  static const _wingPolar = <List<(double, double)>>[
    // Raised, at the top of the stroke.
    [(.60, -1.36), (1.0, -1.12), (1.22, -.84), (1.34, -.52), (1.22, -.14)],
    // Spread: the glide, and the middle of the power stroke.
    [(.54, -.92), (1.22, -.76), (1.50, -.50), (1.60, -.24), (1.32, .02)],
    // Down, at the bottom of the stroke: the feathers hang over the flank.
    [(.56, .10), (1.25, .30), (1.20, .52), (1.00, .76), (.74, 1.0)],
    // Swept back along the body for a dive.
    [(.58, -.07), (1.36, -.07), (1.66, .08), (1.66, .26), (1.28, .36)],
  ];

  /// The wing's five points (wrist, outer tip, three trailing tips) for a
  /// stroke (+1 raised .. -1 down), blended toward the swept pose by [tuck].
  static List<Offset> _wingPoints(double stroke, double tuck) {
    final a = _wingPolar[stroke >= 0 ? 0 : 2];
    final mid = _wingPolar[1], swept = _wingPolar[3];
    final t = stroke.abs().clamp(0.0, 1.0);
    return [
      for (var i = 0; i < 5; i++)
        () {
          final r = (mid[i].$1 + (a[i].$1 - mid[i].$1) * t) * _wingScale;
          final ang = mid[i].$2 + (a[i].$2 - mid[i].$2) * t;
          final rs = r + (swept[i].$1 - r) * tuck;
          // The swept wing trembles in the wind of the stoop.
          final as = ang + (swept[i].$2 - ang) * tuck + stroke * .08 * tuck;
          return _wingShoulder + Offset(math.cos(as), math.sin(as)) * rs;
        }(),
    ];
  }

  /// The wing's points, for the tests that keep every pose in its envelope.
  @visibleForTesting
  static List<Offset> wingPointsForTest(double stroke, double tuck) =>
      _wingPoints(stroke, tuck);

  /// The outline of a wing with rounded feather tips, from [pts]. The seams
  /// between the feathers are added to [seams] when given.
  static Path _wingOutline(List<Offset> pts, [Path? seams]) {
    final [wrist, tip, f1, f2, f3] = pts;
    final tips = [tip, f1, f2, f3];
    // The valleys between feathers lie a little toward the wrist.
    Offset notch(Offset a, Offset b) {
      final m = (a + b) / 2;
      return m + (wrist - m) * .16;
    }

    final p = Path()..moveTo(_wingShoulder.dx, _wingShoulder.dy);
    final lead = _bulge(_wingShoulder, wrist, -.16);
    p.quadraticBezierTo(lead.dx, lead.dy, wrist.dx, wrist.dy);
    // From the wrist along the leading edge to the outer feather's base.
    var from = Offset.lerp(wrist, tip, .42)!;
    final edge = _bulge(wrist, from, -.05);
    p.quadraticBezierTo(edge.dx, edge.dy, from.dx, from.dy);
    for (var i = 0; i < tips.length; i++) {
      final to = i == tips.length - 1 ? _wingRoot : notch(tips[i], tips[i + 1]);
      if (seams != null && i < tips.length - 1) {
        final back = Offset.lerp(to, wrist, .6)!;
        seams
          ..moveTo(to.dx, to.dy)
          ..lineTo(back.dx, back.dy);
      }
      final d = tips[i] - wrist;
      final dir = d / d.distance;
      final reach = (tips[i] - (from + to) / 2).distance / .75;
      p.cubicTo(
        from.dx + dir.dx * reach,
        from.dy + dir.dy * reach,
        to.dx + dir.dx * reach,
        to.dy + dir.dy * reach,
        to.dx,
        to.dy,
      );
      from = to;
    }
    return p..close();
  }

  static Offset _bulge(Offset a, Offset b, double amount) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return a;
    return (a + b) / 2 + Offset(d.dy, -d.dx) / len * amount;
  }

  static final Path _tail = () {
    final tips = [-.36, -.18, 0.0, .18, .36];
    const reach = 1.06, valley = .80;
    Offset at(double r, double a) => Offset(math.cos(a) * r, math.sin(a) * r);
    final p = Path()..moveTo(-.02, -.22);
    final first = at(reach, tips.first);
    p.lineTo(first.dx, first.dy);
    for (var i = 0; i < 4; i++) {
      final c = at(valley, (tips[i] + tips[i + 1]) / 2);
      final to = at(reach, tips[i + 1]);
      p.quadraticBezierTo(c.dx, c.dy, to.dx, to.dy);
    }
    p.lineTo(-.02, .22);
    return p..close();
  }();
  static final Path _tailBand = Path()
    ..arcTo(Rect.fromCircle(center: Offset.zero, radius: 1.04), -.38, .76, true)
    ..arcTo(Rect.fromCircle(center: Offset.zero, radius: .72), .38, -.76, false)
    ..close();
  static final Path _tailSeams = () {
    final p = Path();
    for (final a in const [-.27, -.09, .09, .27]) {
      p
        ..moveTo(math.cos(a) * .30, math.sin(a) * .30)
        ..lineTo(math.cos(a) * .80, math.sin(a) * .80);
    }
    return p;
  }();

  static final Path _headShadePath = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: _head, radius: _headR)),
    Path()..addOval(
      Rect.fromCircle(center: _head + const Offset(-.07, -.11), radius: _headR),
    ),
  );
  static final Path _upperBeak = Path()
    ..moveTo(-1.14, -.62)
    ..quadraticBezierTo(-1.36, -.64, -1.60, -.48)
    ..quadraticBezierTo(-1.38, -.42, -1.14, -.43)
    ..close();
  static final Path _lowerBeak = Path()
    ..moveTo(-1.14, -.44)
    ..quadraticBezierTo(-1.34, -.43, -1.48, -.42)
    ..quadraticBezierTo(-1.34, -.30, -1.14, -.32)
    ..close();
  static final Path _mouth = Path()
    ..moveTo(-1.14, -.43)
    ..lineTo(-1.50, -.45)
    ..lineTo(-1.14, -.30)
    ..close();
  static final Rect _cere = Rect.fromCenter(
    center: const Offset(-1.17, -.60),
    width: .17,
    height: .12,
  );
  static final Rect _cheek = Rect.fromCenter(
    center: _head + const Offset(.14, .13),
    width: .14,
    height: .08,
  );
  static final List<Rect> _arcs = [
    for (final (dx, size) in const [(-.16, .16), (-.36, .26)])
      Rect.fromCenter(
        center: Offset(-1.60 + dx, -.47),
        width: size,
        height: size * 1.5,
      ),
  ];

  /// The eyelid: the part of the eye above a chord, for eleven chord heights
  /// (eye radius units, -.20 open to .225 shut). A segment of the eye's own
  /// circle, so turning it about the eye's centre never leaves the eye.
  static const _lidReach = .225, _lidLow = -.20, _lidStep = .0425;
  static final List<Path> _lids = [
    for (var i = 0; i < 11; i++)
      () {
        final h = (_lidLow + i * _lidStep).clamp(-_lidReach, _lidReach);
        final a = math.asin(h / _lidReach);
        return Path()
          ..moveTo(-math.cos(a) * _lidReach, h)
          ..arcTo(
            Rect.fromCircle(center: Offset.zero, radius: _lidReach),
            math.pi - a,
            math.pi + 2 * a,
            false,
          )
          ..close();
      }(),
  ];
  static final Path _archEye = Path()
    ..moveTo(-.19, .07)
    ..quadraticBezierTo(0, -.28, .19, .07);
  static final Path _browUp = Path()
    ..moveTo(-.22, -.34)
    ..quadraticBezierTo(0, -.47, .22, -.32);
  static final Path _xEye = Path()
    ..moveTo(-.14, -.14)
    ..lineTo(.14, .14)
    ..moveTo(.14, -.14)
    ..lineTo(-.14, .14);
  static final Path _sweat = Path()
    ..moveTo(0, -.16)
    ..quadraticBezierTo(.12, .02, 0, .08)
    ..quadraticBezierTo(-.12, .02, 0, -.16)
    ..close();
  static final Path _glint = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(.08, -.08, 1, 0)
    ..quadraticBezierTo(.08, .08, 0, 1)
    ..quadraticBezierTo(-.08, .08, -1, 0)
    ..quadraticBezierTo(-.08, -.08, 0, -1)
    ..close();
  static final Path _star = StarArt.path(Offset.zero, 1);

  // A straggler's scuffs: a rumpled tuft off the back of the head (three
  // ragged feathers), and a plaster.
  static final Path _tuft = Path()
    ..moveTo(-.86, -.84)
    ..lineTo(-.92, -1.16)
    ..lineTo(-.74, -.94)
    ..lineTo(-.64, -1.22)
    ..lineTo(-.56, -.92)
    ..lineTo(-.36, -1.06)
    ..lineTo(-.44, -.78)
    ..close();
  static final RRect _plaster = RRect.fromRectAndRadius(
    const Rect.fromLTRB(-.17, -.08, .17, .08),
    const Radius.circular(.05),
  );
  static final Path _starLit = Path.combine(
    PathOperation.intersect,
    _star,
    _star.shift(const Offset(-.07, -.22)),
  );

  // -------------------------------------------------------------- paints --

  static Paint _fill(Color c) => Paint()..color = c;
  static Paint _line(Color c, double w, {StrokeCap cap = StrokeCap.round}) =>
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = cap
        ..strokeJoin = StrokeJoin.round;

  static final _inkOutline = _line(ink, _outline);
  static final _inkFill = _fill(ink);
  static final _greyFill = _fill(_grey);
  static final _bellyFill = _fill(_belly);
  static final _rumpFill = _fill(_rump);
  static final _slateFill = _fill(_slate);
  static final _shadeFill = _fill(_greyDeep.withValues(alpha: .34));
  static final _headShade = _fill(_greyShade.withValues(alpha: .42));
  static final _headLit = _fill(_greyLit.withValues(alpha: .65));
  static final _coralFill = _fill(_coral);
  static final _coralDeepFill = _fill(_coralDeep);
  static final _creamFill = _fill(_cream);
  static final _amberFill = _fill(_amber);
  static final _whiteFill = _fill(const Color(0xffffffff));
  static final _blushFill = _fill(const Color(0x88f492b4));
  static final _sweatFill = _fill(const Color(0xff9fe7ff));
  static final _starFill = _fill(const Color(0xffe8a73c));
  static final _starLitFill = _fill(const Color(0xffffd45b));
  static final _seamLine = _line(_slate.withValues(alpha: .55), .05);
  static final _rimLine = _line(_rim.withValues(alpha: .85), .05);
  static final _collarLine = _line(ink, _inner);
  static final _sheenLine = _line(const Color(0xaaffffff), .045);
  static final _legInk = _line(ink, .13);
  static final _legCoral = _line(_coral, .06);
  static final _beakLine = _line(ink, .065);
  static final _lowerLine = _line(ink, .06);
  static final _eyeRing = _line(ink, .05);
  static final _lidLine = _line(ink, .065);
  static final _archLine = _line(ink, .10);
  static final _browLine = _line(ink, .07);
  static final _xLine = _line(ink, .085);
  static final _sweatLine = _line(ink, .04);
  static final _plasterLine = _line(const Color(0xffc9906a), .035);
  static final _starLine = _line(ink, .11 / .58);

  // Added light, as the collectible's own glow: it warms a dark sky without
  // greying it. One radial shader, built once.
  static final _starGlow = Paint()
    ..blendMode = BlendMode.plus
    ..shader = ui.Gradient.radial(
      Offset.zero,
      1,
      [
        const Color(0xffffe68a).withValues(alpha: .55),
        const Color(0xffe8a73c).withValues(alpha: .28),
        const Color(0xffe8a73c).withValues(alpha: 0),
      ],
      const [.3, .62, 1],
    );

  // Reused for alpha fades: a canvas copies the paint's state per call.
  static final _scratchFill = Paint();
  static final _scratchLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint _fade(Color c, double alpha) =>
      _scratchFill..color = c.withValues(alpha: alpha.clamp(0.0, 1.0));
  static Paint _fadeLine(Color c, double alpha, double w) => _scratchLine
    ..color = c.withValues(alpha: alpha.clamp(0.0, 1.0))
    ..strokeWidth = w;

  /// One plumage: the gradients (built once) and the flat colours that
  /// change with it.
  static final List<_Coat> _coats = [
    // Blue-bar: the classic, light wing with two dark bars.
    _Coat(
      body: const [_greyLit, _grey, _greyShade],
      wing: const [
        Color(0xffe6eaf9),
        Color(0xffb6bedd),
        Color(0xff7e88b2),
        Color(0xff4f577f),
      ],
      collar: const [Color(0xff2fd9b4), Color(0xff6f8cf0), Color(0xffc05ae0)],
      bars: _slate,
      tail: const Color(0xff8a93bb),
      farWing: const Color(0xff5a6290),
    ),
    // Checker: a darker bird, pale bars on a slate wing, a green-gold neck.
    _Coat(
      body: const [Color(0xffd6dcf0), Color(0xff919cc4), Color(0xff58618c)],
      wing: const [
        Color(0xffb9c1e0),
        Color(0xff8792b8),
        Color(0xff59628e),
        Color(0xff363d66),
      ],
      collar: const [Color(0xff7be889), Color(0xff2fc6c0), Color(0xff6f8cf0)],
      bars: const Color(0xffe6ebfa),
      tail: const Color(0xff6f79a4),
      farWing: const Color(0xff454d78),
    ),
    // White-wing: a pale bird with a pink-violet neck and grey bars.
    _Coat(
      body: const [Color(0xfffbfbff), Color(0xffdde2f3), Color(0xffa9b2d2)],
      wing: const [
        Color(0xffffffff),
        Color(0xffe6eaf7),
        Color(0xffbcc4e2),
        Color(0xff8b95bd),
      ],
      collar: const [Color(0xffff9fd0), Color(0xffc05ae0), Color(0xff6f8cf0)],
      bars: const Color(0xff6d7599),
      tail: const Color(0xffc3c9e4),
      farWing: const Color(0xff8c95bd),
    ),
  ];

  // ---------------------------------------------------------------- pose --

  /// +1 at the top of the stroke, -1 at the bottom: a quick clap down
  /// (38% of the beat) and a slower recovery.
  static double beat(double phase) {
    final u = phase - phase.floorToDouble();
    const down = .38;
    return u < down
        ? math.cos(math.pi * u / down)
        : -math.cos(math.pi * (u - down) / (1 - down));
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double _blink(double time) {
    final t = (time + 1.9) % 4.3;
    return t < .15 ? math.sin(math.pi * t / .15) : 0;
  }

  /// Where the wing stroke holds in a stage when nothing moves (Reduced
  /// Motion, and the defeat ghost): each stage keeps a pose of its own.
  static double _restStroke(PigeonStage stage) => switch (stage) {
    PigeonStage.glide => .10,
    PigeonStage.warn => .95,
    PigeonStage.dive => .0,
    PigeonStage.gloat => -.25,
    PigeonStage.climb => -.40,
    PigeonStage.flee => .55,
  };

  // --------------------------------------------------------------- paint --

  /// Paints the pigeon at the canvas origin, [radius] px per hit radius,
  /// looking left. The painter signature is `EnemyArt`'s; [pose] carries the
  /// raid state ([PigeonPose.of]). [glider] is King Coo's squadron variant:
  /// the same bird with the detail nobody can see at 16 px left out (under 30
  /// draw calls), and no star to snatch. [dazed] is the defeat ghost's face.
  ///
  /// [throwing] is a vanguard glider's throw (rules version 45), the
  /// player's warning: through the wind-up it pulls a stale crust out of
  /// its breast feathers and cocks its near wing back over its shoulder
  /// like an arm, the crust gripped in the wingtip and glowing warning
  /// orange, the body coiled back and the collar puffed (with a coo as it
  /// starts); at the release the wing whips down through a swoosh and the
  /// body lunges after the throw, then it settles back into its glide.
  /// Under Reduced Motion the cocked pose holds still for the wind-up and
  /// there is no follow-through.
  ///
  /// [ragged] is a vanguard pigeon come back for more (King Coo's
  /// stragglers): a rumpled tuft sticks up off its head and a sticking
  /// plaster sits behind its eye.
  static void paint(
    Canvas c,
    double radius, {
    required double seconds,
    required bool reducedMotion,
    double lookY = 0,
    double charge = 0,
    double recoil = 0,
    PigeonPose pose = const PigeonPose(),
    bool glider = false,
    bool dazed = false,
    PigeonThrow? throwing,
    bool ragged = false,
  }) {
    if (!radius.isFinite || radius <= 0) return;
    // Every number of the pose is made safe to paint first.
    final p = pose.cleaned();
    final time = seconds.isFinite && seconds > 0 ? seconds : 0.0;
    final motion = reducedMotion ? 0.0 : 1.0;
    final look = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    final stage = p.stage;
    final kick = math
        .max(p.kick, recoil.isFinite ? recoil : 0.0)
        .clamp(0.0, 1.0);
    final coat = _coats[p.coat.abs() % coatCount];

    // The telegraph: a fast wind-up into a held crouch that quivers. (Called
    // through the shared painter signature, [charge] is the same tell.) A
    // thrower's tell is its throw, below.
    final tell = stage == PigeonStage.warn
        ? p.warn
        : stage == PigeonStage.glide && charge.isFinite && throwing == null
        ? charge.clamp(0.0, 1.0)
        : 0.0;
    final arm = _arm(throwing, reducedMotion);
    final warn = _smooth(tell / .22);
    final quiver = math.sin(time * 54) * motion * warn;
    // The wings tuck for the stoop and flare open to brake at the snatch;
    // [settling] carries the dive's tuck, tremble and tempo into the climb's
    // over the snatch's first 0.14 s so nothing jumps.
    final hurried =
        stage == PigeonStage.gloat ||
        stage == PigeonStage.climb ||
        stage == PigeonStage.flee;
    final settling = hurried ? 1 - _smooth(p.settle) : 0.0;
    final tucked = stage == PigeonStage.dive ? _smooth(p.dive / .22) : settling;
    final tuck = tucked * (1 - p.flare);
    final cycle = cycleSeconds * p.beat, hurry = hurryCycleSeconds * p.beat;
    final period = hurried ? hurry : cycle;

    // Wing stroke and its far-wing echo (+1 raised, -1 down).
    var stroke = reducedMotion ? _restStroke(stage) : beat(time / period);
    stroke += (.95 - stroke) * warn;
    stroke += quiver * .05;
    // Tucked for the stoop, the wings tremble rather than beat.
    if (motion > 0 && tucked > 0) {
      stroke += (math.sin(time * 38) * .6 - stroke) * tucked;
    }
    stroke += (.9 - stroke) * p.flare;
    var farStroke = reducedMotion
        ? _restStroke(stage) * .8
        : beat(time / period - .10) * .8 + .10;
    if (motion > 0 && settling > 0) {
      // The far wing keeps the dive's slow beat until the snatch has settled.
      farStroke += (beat(time / cycle - .10) * .8 + .10 - farStroke) * settling;
    }
    farStroke += (.85 - farStroke) * warn;
    farStroke += (.85 - farStroke) * p.flare;

    // Body: the flap lifts it, a crouch drops it, a gloat shivers it.
    final chuckle = stage == PigeonStage.gloat
        ? math.sin(time * 40) *
              motion *
              _smooth(p.settle) *
              (1 - p.stageTime / AlleyPigeon.gloatSeconds).clamp(0.0, 1.0)
        : 0.0;
    final bob =
        -.04 * stroke * motion * (1 - warn - tuck) +
        .12 * warn +
        .012 * chuckle;
    // A throw coils the body back and lunges it after the crust.
    final pitch = p.tilt + .08 * quiver + .17 * arm.cock - .16 * arm.lunge;
    // The stoop stretches along its path and eases back at the snatch.
    final stretch = stage == PigeonStage.dive
        ? .10 * math.sin(math.pi * p.dive.clamp(0.0, 1.0)) * motion
        : 0.0;
    final squashX =
        1 +
        .05 * warn -
        .07 * kick * motion +
        .02 * chuckle +
        stretch -
        .05 * arm.cock +
        .06 * arm.lunge;
    final squashY =
        1 -
        .10 * warn +
        .06 * kick * motion -
        .02 * chuckle -
        stretch * .5 +
        .04 * arm.cock -
        .04 * arm.lunge;
    // A pigeon's head stays put while the body bobs; it lags the flap. The
    // neck stretches toward the star as the dive closes in.
    final headBob =
        motion * (1 - warn - tuck) * .05 * stroke -
        .16 * p.reach +
        .10 * arm.cock -
        .14 * arm.lunge;
    final headDip = .14 * warn + .10 * tuck + .05 * p.startle + .03 * p.reach;

    c.save();
    c.scale(radius * p.scale);
    // The wings rise above the hit circle; centre the whole bird on it. The
    // drift is the dive's momentum carried through the snatch.
    c.translate(-.02 - p.drift / p.scale - .10 * arm.lunge, .12 + bob);
    c.rotate(pitch);
    c.scale(squashX, squashY);

    _wing(c, coat, farStroke, glider ? 0 : tuck, far: true, glider: glider);
    _tailPart(c, coat, warn, tuck, hurried ? 1 - settling : 0, glider);
    _torso(c, coat, glider);
    if (!glider && stage != PigeonStage.dive) {
      // The feet come out of the belly feathers as the snatch settles.
      _feetPart(c, warn, hurried ? _smooth((p.settle - .2) / .6) : 1.0);
    }
    _collar(c, coat, math.max(warn, .7 * arm.cock), glider);
    if (throwing == null) {
      _wing(c, coat, stroke, tuck, far: false, glider: glider);
    } else {
      _throwingWing(c, coat, stroke, arm, glider: glider, time: time);
    }
    _headPart(
      c,
      pose: pose,
      look: look,
      headBob: headBob,
      headDip: headDip,
      warn: warn,
      kick: math.max(kick, .8 * arm.lunge),
      time: time,
      motion: motion,
      glider: glider,
      dazed: dazed,
      coo: arm.coo,
      ragged: ragged,
    );
    if (stage == PigeonStage.dive && motion > 0) _streaks(c, p.dive);
    // Only for a thief that has its star: a hit pigeon already has the
    // sweat drop and the open beak to draw within the budget.
    if (p.loot && p.kick > 0 && motion > 0) _featherPuff(c, p.kick);
    c.restore();
  }

  /// How far a thrower's arm is through its throw: [cock] (0 to 1, the
  /// wind-up's wing raised back), [grip] (0 to 1, the crust out of the
  /// feathers and in the wingtip), [whip] (0 to 1, the wing coming down
  /// through the release), [lunge] (the body after the crust) and [coo] (the
  /// wind-up's progress while the coo shows, else 0). All zero when it is
  /// not throwing.
  static ({double cock, double grip, double whip, double lunge, double coo})
  _arm(PigeonThrow? t, bool reduced) {
    const rest = (cock: 0.0, grip: 0.0, whip: 0.0, lunge: 0.0, coo: 0.0);
    if (t == null) return rest;
    final w = t.windup.isFinite ? t.windup.clamp(0.0, 1.0) : 0.0;
    final f = t.follow.isFinite ? t.follow : -1.0;
    if (reduced) {
      // A still state: cocked with the crust for the whole wind-up.
      return w > 0
          ? (cock: 1.0, grip: 1.0, whip: 0.0, lunge: 0.0, coo: 0.0)
          : rest;
    }
    if (f >= 0 && f < 1) {
      // The release: down fast, then back into the glide.
      final out = 1 - _smooth((f - .35) / .65);
      final down = 1 - math.pow(1 - (f / .3).clamp(0.0, 1.0), 3).toDouble();
      return (
        cock: (1 - down) * out,
        grip: 0.0,
        whip: down * out,
        lunge: math.sin(math.pi * (f / .55).clamp(0.0, 1.0)),
        coo: 0.0,
      );
    }
    if (w <= 0) return rest;
    return (
      cock: _smooth((w - .12) / .6),
      grip: _smooth(w / .3),
      whip: 0.0,
      lunge: 0.0,
      coo: w < .55 ? w : 0.0,
    );
  }

  /// How far the cocked wing turns back about its shoulder, past its raised
  /// key (radians): up behind the head, the crust held high.
  static const _armTurn = .12;

  /// The near wing of a thrower: raised and turned back over its shoulder
  /// as it cocks ([arm]'s `cock`), the crust in its tip glowing warning
  /// orange as the wind-up builds; swept down as it whips through the
  /// release, a swoosh arc over its head showing the throw.
  static void _throwingWing(
    Canvas c,
    _Coat coat,
    double stroke,
    ({double cock, double grip, double whip, double lunge, double coo}) arm, {
    required bool glider,
    required double time,
  }) {
    var s = stroke + (1 - stroke) * arm.cock;
    s += (-1 - s) * arm.whip;
    final turn = _armTurn * arm.cock - .35 * arm.whip;
    c.save();
    c.translate(_wingShoulder.dx, _wingShoulder.dy);
    c.rotate(turn);
    c.translate(-_wingShoulder.dx, -_wingShoulder.dy);
    _wing(c, coat, s, 0, far: false, glider: glider);
    if (arm.grip > 0) {
      // The crust: out of the breast feathers into the wingtip.
      final tip = _wingPoints(s, 0)[1];
      final at = Offset.lerp(const Offset(-.30, .05), tip, arm.cock)!;
      final size = .6 * arm.grip;
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(size);
      if (arm.cock > .1) {
        c.drawCircle(
          Offset.zero,
          2.1,
          Paint()
            ..shader = _heldGlow
            ..color = Color.fromRGBO(255, 255, 255, arm.cock),
        );
      }
      c.rotate(-turn + .5);
      CrustArt.slab(c, edge: _outline / size, fine: false);
      c.restore();
    }
    c.restore();
    if (arm.whip > 0 && arm.whip < 1) {
      // The swoosh: from over the shoulder, over the head, to the front.
      final fade = 1 - arm.whip;
      final sweep = Path()
        ..addArc(
          Rect.fromCircle(center: const Offset(-.30, -.30), radius: 1.35),
          -math.pi * .15,
          -math.pi * (.35 + .55 * arm.whip),
        );
      c.drawPath(sweep, _fadeLine(_rim, .9 * fade, .16 * fade + .04));
    }
  }

  static final Shader _heldGlow = ui.Gradient.radial(
    Offset.zero,
    2.1,
    [
      CrustArt.threat.withValues(alpha: .72),
      CrustArt.threat.withValues(alpha: .3),
      CrustArt.threat.withValues(alpha: 0),
    ],
    const [.35, .62, 1],
  );

  /// A wing for [stroke] (+1 raised .. -1 down), [tuck]ed for a dive. The
  /// far wing is a flat dark silhouette behind the body; the near one has
  /// its bars and feather seams (a glider's has one bar and no seams).
  static void _wing(
    Canvas c,
    _Coat coat,
    double stroke,
    double tuck, {
    required bool far,
    required bool glider,
  }) {
    final pts = _wingPoints(stroke, tuck);
    final seams = far || glider ? null : Path();
    final outline = _wingOutline(pts, seams);
    if (far) {
      c.save();
      c.translate(.12, -.12);
      c.drawPath(outline, coat.farFill);
      c.drawPath(outline, _inkOutline);
      c.restore();
      return;
    }
    final [wrist, _, _, f2, _] = pts;
    c.drawPath(outline, coat.wingPaint);
    if (glider) {
      c.drawLine(
        Offset.lerp(_wingShoulder, wrist, .55)!,
        Offset.lerp(_wingRoot, f2, .55)!,
        coat.barLine,
      );
    } else {
      // The two dark bars across the coverts, then the feathers' seams.
      final bars = Path();
      for (final k in const [.30, .62]) {
        final a = Offset.lerp(_wingShoulder, wrist, .35 + k * .9)!;
        final b = Offset.lerp(_wingRoot, f2, k + .15)!;
        final m = (a + b) / 2;
        bars
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(m.dx + .03, m.dy - .10, b.dx, b.dy);
      }
      c.drawPath(bars, coat.barLine);
      c.drawPath(seams!, _seamLine);
    }
    c.drawPath(outline, _inkOutline);
  }

  static void _tailPart(
    Canvas c,
    _Coat coat,
    double warn,
    double tuck,
    double hurried,
    bool glider,
  ) {
    final splay = 1 + .55 * warn + .18 * hurried - .30 * tuck;
    c.save();
    c.translate(_tailRoot.dx, _tailRoot.dy);
    c.rotate(.20 - .14 * warn);
    c.scale(1, splay);
    c.drawPath(_tail, coat.tailFill);
    c.drawPath(_tailBand, _slateFill);
    if (!glider) c.drawPath(_tailSeams, _seamLine);
    c.drawPath(_tail, _inkOutline);
    c.restore();
  }

  static void _torso(Canvas c, _Coat coat, bool glider) {
    c.drawPath(_bodyPath, coat.bodyPaint);
    c.drawPath(_bellyPath, _bellyFill);
    if (!glider) c.drawPath(_rumpPath, _rumpFill);
    c.drawPath(_bodyShade, _shadeFill);
    c.drawPath(_bodyPath, _inkOutline);
    if (!glider) c.drawPath(_rimPath, _rimLine);
  }

  static void _feetPart(Canvas c, double warn, double out) {
    if (out <= .04) return;
    c.save();
    // Out of the belly: grown down from the hips.
    c.translate(0, .58);
    c.scale(1, out);
    c.translate(0, -.58);
    // A crouch puts the feet forward, like a cat about to pounce.
    c.translate(-.10 * warn, -.02 * warn);
    c.rotate(.22 * warn);
    c.drawPath(_feet, _legInk);
    c.drawPath(_feet, _legCoral);
    c.restore();
  }

  static void _collar(Canvas c, _Coat coat, double warn, bool glider) {
    c.save();
    // A coo puffs the iridescent collar out around the throat.
    c.translate(-.60, -.06);
    c.scale(1 + .22 * warn, 1 + .30 * warn);
    c.translate(.60, .06);
    c.drawPath(_collarPath, coat.collarPaint);
    if (!glider) c.drawPath(_collarSheen, _sheenLine);
    c.drawPath(_collarPath, _collarLine);
    c.restore();
  }

  static void _headPart(
    Canvas c, {
    required PigeonPose pose,
    required double look,
    required double headBob,
    required double headDip,
    required double warn,
    required double kick,
    required double time,
    required double motion,
    required bool glider,
    required bool dazed,
    double coo = 0,
    bool ragged = false,
  }) {
    final stage = pose.stage;
    c.save();
    c.translate(headBob, headDip);
    if (ragged) {
      // Behind the head: a rumpled tuft of three feathers.
      c.drawPath(_tuft, _greyFill);
      c.drawPath(_tuft, _inkOutline);
    }
    if (pose.loot) _stolenStar(c, time, motion, pose.kick);
    c.drawCircle(_head, _headR, _greyFill);
    c.drawCircle(_head + const Offset(-.08, -.12), _headR * .62, _headLit);
    if (!glider) c.drawPath(_headShadePath, _headShade);
    c.drawCircle(_head, _headR, _inkOutline);

    // Beak: opens on the snatch, on a fright and when dazed.
    final open = math
        .max(
          math.max(kick * .55, pose.startle * .75),
          math.max(dazed ? .7 : 0.0, pose.reach * .45),
        )
        .clamp(0.0, 1.0);
    c.save();
    c.translate(-1.14, -.43);
    c.rotate(open * .14);
    c.translate(1.14, .43);
    c.drawPath(_upperBeak, _coralFill);
    c.drawPath(_upperBeak, _beakLine);
    c.restore();
    if (open > .05) {
      c.save();
      c.translate(-1.14, -.42);
      c.rotate(-open * .5);
      c.translate(1.14, .42);
      c.drawPath(_mouth, _inkFill);
      c.drawPath(_lowerBeak, _coralDeepFill);
      c.drawPath(_lowerBeak, _lowerLine);
      c.restore();
    }
    // Cere: the pale bump every pigeon wears above the beak.
    c.drawOval(_cere, _creamFill);
    if (ragged) {
      // A sticking plaster over the back of its head.
      c.save();
      c.translate(-.56, -.70);
      c.rotate(.62);
      c.drawRRect(_plaster, _creamFill);
      c.drawRRect(_plaster, _plasterLine);
      c.drawLine(const Offset(0, -.07), const Offset(0, .07), _plasterLine);
      c.restore();
    }

    // The coo made visible: two sound arcs while the warning (or a
    // thrower's wind-up) begins.
    final cooing = stage == PigeonStage.warn ? pose.warn : coo;
    if ((stage == PigeonStage.warn || coo > 0) && motion > 0 && cooing < .55) {
      final fade = 1 - cooing / .55;
      for (final arc in _arcs) {
        c.drawArc(
          arc,
          math.pi * .68,
          math.pi * .64,
          false,
          _fadeLine(_cream, .9 * fade, .07),
        );
      }
    }

    _eye(
      c,
      pose: pose,
      look: look,
      time: time,
      motion: motion,
      warn: warn,
      glider: glider,
      dazed: dazed,
    );
    if (!glider && !dazed && pose.startle < .05 && stage != PigeonStage.flee) {
      c.drawOval(_cheek, _blushFill);
    }
    if (stage == PigeonStage.flee || pose.startle > .3) {
      // A cartoon sweat drop flicks off the brow.
      c.save();
      c.translate(-.46, -.96 - (motion > 0 ? (time * 2 % 1) * .1 : 0));
      c.drawPath(_sweat, _sweatFill);
      c.drawPath(_sweat, _sweatLine);
      c.restore();
    }
    c.restore();
  }

  static void _eye(
    Canvas c, {
    required PigeonPose pose,
    required double look,
    required double time,
    required double motion,
    required double warn,
    required bool glider,
    required bool dazed,
  }) {
    final eye = _head + Offset(-.14, -.08 + look * .02);
    c.save();
    c.translate(eye.dx, eye.dy);
    if (dazed) {
      c.drawPath(_xEye, _xLine);
    } else if (pose.loot && pose.startle < .3) {
      // A gleeful arch: the thief is pleased with itself.
      c.drawPath(_archEye, _archLine);
    } else {
      _openEye(c, pose, look, time, motion, warn, glider);
    }
    c.restore();
  }

  static void _openEye(
    Canvas c,
    PigeonPose pose,
    double look,
    double time,
    double motion,
    double warn,
    bool glider,
  ) {
    final stage = pose.stage;
    final wide = pose.startle > .05 || stage == PigeonStage.flee;
    final white = wide ? .25 : .22;
    c.drawCircle(Offset.zero, white, _creamFill);
    c.drawCircle(Offset.zero, white * .80, _amberFill);
    final pupil = Offset(-.035, .01 + look * .03);
    c.drawCircle(pupil, wide ? .05 : .085 - .015 * warn, _inkFill);
    c.drawCircle(pupil + const Offset(-.03, -.04), .03, _whiteFill);
    c.drawCircle(Offset.zero, white, _eyeRing);
    if (wide) {
      // Wide-eyed, brows up.
      c.drawPath(_browUp, _browLine);
      return;
    }
    // The lid: open and cocky while cruising, pressed down when it means it
    // (the telegraph and the dive), so the face tells the change of mood.
    final squint = math.max(warn, stage == PigeonStage.dive ? 1.0 : 0.0);
    final blink = motion > 0 ? _blink(time) : 0.0;
    final mean = glider ? 1.0 : 0.0;
    final chord = (-.15 + .20 * squint + .06 * mean + .31 * blink).clamp(
      _lidLow,
      _lidReach,
    );
    final i = ((chord - _lidLow) / _lidStep).round().clamp(0, _lids.length - 1);
    final h = _lidLow + i * _lidStep;
    final reach = math.sqrt(math.max(0.0, _lidReach * _lidReach - h * h));
    c.save();
    // Angry brows slope down toward the beak (the left end is lower).
    c.rotate(-(.12 + .40 * squint + .30 * mean));
    c.drawPath(_lids[i], _greyFill);
    c.drawLine(Offset(-reach, h), Offset(reach, h), _lidLine);
    c.restore();
  }

  /// The stolen star in the beak, with its glow and a twinkle. It zips from
  /// where it was (the body) into the beak over the snatch's kick, then rides
  /// at the beak tip.
  static void _stolenStar(Canvas c, double time, double motion, double kick) {
    final arrive = _smooth((1 - kick) / .5);
    final at = Offset.lerp(
      const Offset(.2, -.3),
      const Offset(-1.80, -.62),
      arrive,
    )!;
    const r = .58;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r * 1.9);
    c.drawCircle(Offset.zero, 1, _starGlow);
    c.restore();
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(-.30 + (1 - arrive) * 1.2);
    c.scale(r);
    c.drawPath(_star, _starFill);
    c.drawPath(_starLit, _starLitFill);
    c.drawPath(_star, _starLine);
    c.restore();
    final g = .16 + .10 * (motion > 0 ? (math.sin(time * 9) * .5 + .5) : .5);
    c.save();
    c.translate(at.dx + .42, at.dy - .48);
    c.scale(g);
    c.drawPath(_glint, _whiteFill);
    c.restore();
  }

  /// A loose feather: a leaf with pointed ends and a quill, unit length.
  static final Path _looseFeather = Path()
    ..moveTo(-.5, 0)
    ..quadraticBezierTo(-.05, -.34, .5, 0)
    ..quadraticBezierTo(-.05, .34, -.5, 0)
    ..close();

  /// Three feathers knocked loose by the snatch, drifting up and back over
  /// the kick's 0.24 s: they appear after its first frame, so the snatch's
  /// own pose (the star flying into the beak) is never crowded.
  static void _featherPuff(Canvas c, double kick) {
    final p = 1 - kick;
    final visible = math.sin(math.pi * p.clamp(0.0, 1.0));
    if (visible <= .02) return;
    const dirs = [(-2.25, .62), (-1.55, .74), (-.85, .58)];
    for (var i = 0; i < dirs.length; i++) {
      final (angle, size) = dirs[i];
      final at =
          const Offset(.35, -.10) +
          Offset(math.cos(angle), math.sin(angle)) * (.25 + 1.0 * p);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(angle + 1.0 + p * 2.4 * (i.isEven ? 1 : -1));
      c.scale(size);
      c.drawPath(_looseFeather, _fade(_greyLit, visible * 1.6));
      c.drawPath(_looseFeather, _fadeLine(ink, visible * 1.6, .09));
      c.restore();
    }
  }

  /// Two speed streaks trailing the dive.
  static void _streaks(Canvas c, double dive) {
    final a = .55 * math.sin(math.pi * dive.clamp(0.0, 1.0)) + .25;
    final paint = _fadeLine(_rim, a, .07);
    c.drawLine(const Offset(1.0, -.30), const Offset(1.8, -.30), paint);
    c.drawLine(const Offset(1.0, .26), const Offset(1.6, .26), paint);
  }

  /// The pigeon as `SkyEnemy` has it: its pose from the raid state and its
  /// own clock. [hitAge] is `enemy.age - enemy.lastHitAt`. A squadron pigeon
  /// (King Coo's) is the glider variant.
  static void paintEnemy(
    Canvas c,
    double radius,
    SkyEnemy enemy, {
    required double lookY,
    required double hitAge,
    required bool reducedMotion,
    bool ragged = false,
  }) {
    final pose = PigeonPose.of(
      enemy,
      hitAge: reducedMotion ? double.infinity : hitAge,
    );
    paint(
      c,
      radius,
      seconds: enemy.wingTime,
      reducedMotion: reducedMotion,
      lookY: lookY,
      charge: enemy.charge,
      recoil: enemy.throwsCrumbs ? 0 : enemy.recoil,
      pose: pose,
      glider: enemy.squad,
      throwing: enemy.throwsCrumbs ? throwOf(enemy) : null,
      ragged: ragged,
    );
  }

  /// The follow-through after a throw lasts this long.
  static const followSeconds = .45;

  /// Where a crust-throwing pigeon ([SkyEnemy.throwsCrumbs]) is in its
  /// throw: the wind-up is its charge while it prepares; the
  /// follow-through runs [followSeconds] from its last shot, on its own
  /// clock.
  static PigeonThrow throwOf(SkyEnemy enemy) {
    final since = enemy.age - enemy.lastShotAt;
    return (
      windup: enemy.preparing ? enemy.charge : 0.0,
      follow: since.isFinite && since >= 0 && since < followSeconds
          ? since / followSeconds
          : -1.0,
    );
  }
}

/// One plumage's paints: the gradients are built once, here.
final class _Coat {
  _Coat({
    required List<Color> body,
    required List<Color> wing,
    required List<Color> collar,
    required Color bars,
    required Color tail,
    required Color farWing,
  }) : bodyPaint = Paint()
         ..shader = ui.Gradient.linear(
           const Offset(-.7, -.6),
           const Offset(.7, .7),
           body,
           const [0, .5, 1],
         ),
       wingPaint = Paint()
         ..shader = ui.Gradient.radial(
           const Offset(.10, -.50),
           1.55,
           wing,
           const [0, .34, .66, .92],
         ),
       collarPaint = Paint()
         ..shader = ui.Gradient.linear(
           const Offset(-.3, -.4),
           const Offset(-.9, .2),
           collar,
           const [.05, .5, .95],
         ),
       barLine = Paint()
         ..color = bars
         ..style = PaintingStyle.stroke
         ..strokeWidth = AlleyPigeonArt._bar
         ..strokeCap = StrokeCap.butt
         ..strokeJoin = StrokeJoin.round,
       tailFill = Paint()..color = tail,
       farFill = Paint()..color = farWing;

  final Paint bodyPaint, wingPaint, collarPaint, barLine, tailFill, farFill;
}
