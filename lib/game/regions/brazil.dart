import 'dart:math' as math;
import 'dart:ui';

import 'region_scene.dart';
import 'scenery.dart';
import 'weather.dart';
import 'world_region.dart';

/// Brazil on a bright beach day: Sugarloaf with its cable car and the
/// Corcovado over a bay, hillsides of pastel houses, a
/// jangada and a sailboat on a turquoise sea, then a sandy beach with palms,
/// striped umbrellas, a goal and footballers passing a ball. Gulls wheel, a
/// hang glider drifts, cloud gathers on the peak and bougainvillea petals
/// blow past.
class BrazilScene extends RegionScene {
  const BrazilScene();

  @override
  WorldRegion get region => WorldRegion.brazil;

  @override
  double get horizon => .62;

  @override
  SkyLight get light => const SkyLight(
    at: Offset(.78, .2),
    radius: .058,
    disc: Color(0xfffffae0),
    glow: Color(0xffffea9c),
    halo: .64,
    strength: .55,
  );

  static final _weather = Weather(Weather.of([(Mote.petal, 12)]));
  @override
  Weather get weather => _weather;

  static const _haze = Color(0xffd8f3f0);

  @override
  Ground ground(Depth d) => switch (d) {
    Depth.far => const Ground(
      Color(0xff8cc4cc),
      Color(0xff7ab6c2),
      Color(0x00000000),
      rimWidth: 0,
    ),
    // The far side of the bay: hazier, paler water than the low band's, with
    // the hillsides standing straight out of it (a pale lap line on the shore).
    Depth.mid => const Ground(
      Color(0xff76cfd9),
      Color(0xff46b3ce),
      Color(0xffd6f4f0),
      rimWidth: .0025,
    ),
    Depth.low => const Ground(
      Color(0xff3ac0d8),
      Color(0xff2a9fc4),
      Color(0xffe8fbff),
      rimWidth: .003,
    ),
    Depth.near => const Ground(
      Color(0xfff5dda0),
      Color(0xffe4bd78),
      Color(0x00ffefc0),
      rimWidth: 0,
    ),
  };

  @override
  double ridge(Depth d, double x, double clock) => switch (d) {
    Depth.far => .67,
    Depth.mid => .72 - .05 * Sketch.humps(x / 1.8 + .2),
    Depth.low => .79 + .004 * math.sin(x * math.pi * 4 + clock * 1.4),
    Depth.near => .915 - .012 * Sketch.humps(x / 1.5 + .4),
  };

  @override
  double sink(Depth d) => switch (d) {
    Depth.far => .46,
    Depth.mid => .34,
    Depth.low => .18,
    Depth.near => .5,
  };

  static Color _hazed(Color c, double t) => Scenery.hazed(c, _haze, t);

  static Color _dim(Color c) => Sketch.mix(c, const Color(0xff000000), .16);

  static const _navy = Color(0xff26303a);
  static const _cream = Color(0xfffffcf0);

  /// Seconds one pass of the ball takes.
  static const _pass = 1.3;

  /// Near-band layout, in viewport heights along the 3 h repeat. Beach life
  /// fills 2.25 h .. 3 h and 0 .. 1.15 h; the pitch keeps 1.2 h .. 2.2 h.
  /// Palms are (x, scale, lean, seed), umbrellas (x, variant).
  static const _palms = [(.28, 1.0, .09, 0), (2.86, .86, -.12, 1)];
  static const _umbrellas = [(1.09, 0), (3.05, 1)];
  static const _goalAt = 1.95, _goalWide = .17;
  static const _passers = (1.3, 1.56);

  double _nearY(double x, double h) => ridge(Depth.near, x / h, 0) * h;

  /// Sugarloaf and Corcovado, scaled down on a narrow phone so both fit.
  static (Offset, double, Offset, double) _skyline(double w, double h) {
    final k = math.min(1.0, math.max(.72, w / h / 1.1));
    return (Offset(w * .3, h * .7), h * .3 * k, Offset(w * .76, h * .7), h * .38 * k);
  }

  /// The cable car line, from Sugarloaf's summit to its neighbour's.
  static (Offset, Offset) _cable(Offset base, double s) =>
      (Offset(base.dx + s * .09, base.dy - s * .977), Offset(base.dx + s * .86, base.dy - s * .43));

  @override
  void features(Canvas c, Depth d, Size size) {
    final w = size.width, h = size.height;
    switch (d) {
      case Depth.far:
        _serra(c, w, h);
        final (sugar, sugarSize, corco, corcoSize) = _skyline(w, h);
        _sugarloaf(c, sugar, sugarSize);
        _corcovado(c, corco, corcoSize);
      case Depth.mid:
        _headlands(c, w, h);
      case Depth.low:
        _bayFeatures(c, h);
      case Depth.near:
        break;
    }
  }

  @override
  void live(Canvas c, Depth d, SceneFrame f, int copy) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        // Two cable cars pass on Sugarloaf's line.
        final (sugar, sugarSize, _, _) = _skyline(f.w, h);
        final (from, to) = _cable(sugar, sugarSize);
        final u = .5 + .5 * math.sin(f.clock * .25 + .9);
        _gondola(c, _peakCableAt(from, to, u, sugarSize), sugarSize);
        _gondola(c, _peakCableAt(from, to, 1 - u, sugarSize), sugarSize);
      case Depth.low:
        _bayLive(c, f);
      case Depth.near:
        break;
      case Depth.mid:
        _hillLive(c, f);
    }
  }

  /// Footballers' height in viewport heights, and how much wider than
  /// `_goalWide` the goal is drawn.
  static const _matchSize = .098, _matchGoalScale = 1.22;

  /// Where in the two-pass cycle Reduced Motion freezes the game: the ball
  /// hangs at the top of its arc between the friends.
  static const _matchFreeze = .56;

  /// The beach match, painted in front of the sand each frame: two friends
  /// pass a ball to each other, a keeper paces his line and a kid on a
  /// cooler cheers. It stands on the sand, so a crossing slides it off the
  /// bottom edge instead of sinking it behind the ridge.
  void _match(Canvas c, SceneFrame f, double presence) {
    if (presence <= 0) return;
    final h = f.h;
    final view = c.getLocalClipBounds();
    if (view.right < h * 1.05 || view.left > h * 2.4) return;
    final fade = f.reducedMotion && presence < .999;
    c.save();
    if (fade) {
      c.saveLayer(Rect.fromLTWH(h, h * .7, h * 1.5, h * .35), Paint()..color = Color.fromRGBO(0, 0, 0, presence));
    } else if (!f.reducedMotion && presence < 1) {
      c.translate(0, h * .32 * math.pow(1 - presence, 1.4));
    }
    _matchScene(c, f);
    if (fade) c.restore();
    c.restore();
  }

  /// The two passers stand a little further apart than `_passers` says.
  static (double, double) _matchSpots(double h) {
    final mid = (_passers.$1 + _passers.$2) / 2, half = (_passers.$2 - _passers.$1) / 2 * 1.3;
    return (h * (mid - half), h * (mid + half));
  }

  /// Ball centre while resting at a player's feet and while cushioned on his
  /// raised boot, as (forward, up) in footballer heights.
  static const _matchRest = (.56, .08), _matchTrap = (.43, .31);

  void _matchScene(Canvas c, SceneFrame f) {
    final h = f.h, s = h * _matchSize, clock = f.clock;
    c.drawPicture(_matchBackdrop(h));
    final (ax, bx) = _matchSpots(h);
    double footY(double x, double depth) => _nearY(x, h) + h * depth;
    final ay = footY(ax, .034), by = footY(bx, .034);
    final gx = h * _goalAt, gw = h * _goalWide * _matchGoalScale;
    final gy = footY(gx, .026);

    // The keeper paces his line, hops now and then, and watches the ball.
    final kx = gx + gw * (.5 + .2 * math.sin(clock * 1.3));
    _matchFigure(c, Offset(kx, gy), s * .97, -1, _keeperPose(clock), _keeperKit, .012 * math.sin(clock * 5), keeper: true);
    _matchKid(c, Offset(h * 1.78, footY(h * 1.78, .02)), h * .066, clock);

    // One pass takes _pass seconds; A strikes at u = .25, B at u = 1.25.
    final u = (clock / _pass + _matchFreeze) % 2.0;
    final poseA = _matchPose(u), poseB = _matchPose((u + 1) % 2.0);
    final ownerA = u < 1;
    final r = u - u.floorToDouble();
    final ox = ownerA ? ax : bx, oy = ownerA ? ay : by, oDir = ownerA ? 1.0 : -1.0;
    final tx = ownerA ? bx : ax, ty = ownerA ? by : ay;
    Offset world(double px, double py, double dir, (double, double) spot) => Offset(px + dir * spot.$1 * s, py - spot.$2 * s);
    final ballR = s * .08;
    final rest = world(ox, oy, oDir, _matchRest);
    Offset ball;
    if (r < .25) {
      final k = math.min(1.0, r / .12), e = k * k * (3 - 2 * k);
      ball = Offset.lerp(world(ox, oy, oDir, _matchTrap), rest, e)! - Offset(0, math.sin(k * math.pi) * s * .05);
    } else {
      final e = (r - .25) / .75;
      ball = Offset.lerp(rest, world(tx, ty, -oDir, _matchTrap), e)! - Offset(0, math.sin(e * math.pi) * s * .62);
    }
    final spin = .4 + oDir * math.pi * 2 * (r < .25 ? 0 : (r - .25) / .75);

    // Sand thrown up by the strike and by the ball dropping off the boot.
    final ground = (ay + by) / 2;
    if (r >= .25 && (r - .25) * _pass < .55) _matchPuff(c, Offset(rest.dx, oy), s, (r - .25) * _pass, oDir, 1);
    if (r < .2) _matchPuff(c, Offset(rest.dx - oDir * s * .05, oy), s, r * _pass, -oDir, .55);

    // The ball's shadow shrinks as it climbs.
    final lift = math.max(0.0, (ground - ballR - ball.dy) / s);
    c.drawOval(
      Rect.fromCenter(center: Offset(ball.dx - s * .03, ground + s * .01), width: ballR * 2.2 * (1 - math.min(.5, lift * .5)), height: ballR * .7),
      Paint()..color = Color.fromRGBO(106, 74, 28, .3 * (1 - math.min(.6, lift * .5))),
    );
    _matchFigure(c, Offset(ax, ay), s, 1, poseA, _yellowKit, .009 * math.sin(clock * 6.5), number: true);
    _matchFigure(c, Offset(bx, by), s * .97, -1, poseB, _blueKit, .009 * math.sin(clock * 6.5 + 1.7), number: true);
    _ball(c, ball, ballR, spin);
  }

  /// Sand thrown up at [at], [t] seconds after it left the ground.
  static void _matchPuff(Canvas c, Offset at, double s, double t, double dir, double scale) {
    final life = t / .55;
    if (life >= 1) return;
    final fill = Paint();
    final k = 1 - (1 - life) * (1 - life);
    for (var i = 0; i < 6; i++) {
      final side = i.isEven ? 1.0 : -.35;
      final x = at.dx + dir * side * s * (.05 + .3 * Sketch.hash(i + 901)) * k * scale;
      final y = at.dy - s * (.03 + .2 * Sketch.hash(i + 902)) * k * scale;
      final radius = s * (.02 + .028 * Sketch.hash(i + 903)) * (.6 + .9 * life) * scale;
      fill.color = Color.fromRGBO(252, 236, 200, .62 * math.pow(1 - life, 1.2));
      c.drawCircle(Offset(x, y), radius, fill);
    }
  }

  /// Pose at cycle time [r], counted from the moment the ball reaches this
  /// player: trap, wind-up, strike at .25, follow-through, then he waits and
  /// gets ready for the return.
  static _Pose _matchPose(double r) {
    for (var i = 1; i < _kickCycle.length; i++) {
      final (t1, p1) = _kickCycle[i];
      if (r <= t1) {
        final (t0, p0) = _kickCycle[i - 1];
        final k = ((r - t0) / (t1 - t0)).clamp(0.0, 1.0);
        return _Pose.lerp(p0, p1, k * .55 + k * k * (3 - 2 * k) * .45);
      }
    }
    return _kickCycle.last.$2;
  }

  //  shift crouch lean  near foot   far foot    near arm    far arm    head
  static const _kickCycle = [
    (0.0, _Pose(.03, .03, .10, .36, .17, -.03, 0, .5, .8, -.7, -.5, .12)),
    (.10, _Pose(.05, .05, .18, .40, .03, -.02, 0, .3, .5, -.6, -.4, .30)),
    (.17, _Pose(.10, .05, .12, -.26, .16, .24, 0, .9, 1.1, -.9, -.8, .30)),
    (.25, _Pose(.14, .07, .30, .41, .035, .24, 0, -.7, -.5, .9, 1.2, .38)),
    (.36, _Pose(.16, -.02, .08, .60, .30, .26, 0, -.9, -.7, .8, .9, .10)),
    (.55, _Pose(.08, .07, .05, .30, 0, -.04, 0, .4, .5, -.3, -.2, .10)),
    (.85, _Pose(.02, .03, .02, .10, 0, -.10, 0, .25, .3, -.2, -.1, .05)),
    (1.25, _Pose(.03, .06, .10, .14, .02, -.14, 0, .7, .8, -.7, -.6, .10)),
    (1.65, _Pose(.05, .07, .14, .10, .03, -.08, 0, .9, 1.0, -.9, -.8, .15)),
    (1.90, _Pose(.06, .06, .12, .26, .10, -.04, 0, .8, .9, -.8, -.7, .20)),
    (2.0, _Pose(.03, .03, .10, .36, .17, -.03, 0, .5, .8, -.7, -.5, .12)),
  ];

  /// The keeper: knees bent, gloves up, feet shuffling; every 10 s he jumps
  /// to reach for an imagined shot.
  static _Pose _keeperPose(double clock) {
    final sw = math.sin(clock * 4.5);
    final g = (clock % 10.4) / 10.4;
    final jump = g < .62 || g > .74 ? 0.0 : math.sin((g - .62) / .12 * math.pi);
    final pump = .12 * math.sin(clock * 3);
    return _Pose(
      0,
      .06 - .16 * jump,
      .10,
      .12 + .05 * sw,
      .03 * math.max(0.0, sw) + .1 * jump,
      -.12 - .05 * sw,
      .03 * math.max(0.0, -sw) + .1 * jump,
      1.5 + jump * 1.1 + pump,
      2.3 + jump * .6 - pump,
      1.2 + jump * 1.4 - pump,
      2.1 + jump * .8 + pump,
      .1,
    );
  }

  /// Static things around the pitch, recorded once per viewport height:
  /// footprints, the goal line scratched in the sand and the goal itself.
  static final _matchPictures = <double, Picture>{};

  Picture _matchBackdrop(double h) {
    final cached = _matchPictures[h];
    if (cached != null) return cached;
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    final (ax, bx) = _matchSpots(h);
    // Footprints scuffed around the passers.
    final print = Paint();
    for (var i = 0; i < 16; i++) {
      final x = h * (1.22 + .5 * Sketch.hash(i + 950));
      final y = _nearY(x, h) + h * (.03 + .03 * Sketch.hash(i + 951));
      print.color = const Color.fromRGBO(150, 106, 52, .16);
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: h * .014, height: h * .006), print);
      print.color = const Color.fromRGBO(255, 244, 214, .3);
      c.drawOval(Rect.fromCenter(center: Offset(x + h * .001, y + h * .0022), width: h * .012, height: h * .003), print);
    }
    for (final x in [ax, bx]) {
      print.color = const Color.fromRGBO(150, 106, 52, .2);
      c.drawOval(Rect.fromCenter(center: Offset(x - h * .012, _nearY(x, h) + h * .04), width: h * .05, height: h * .012), print);
    }
    final gx = h * _goalAt, gy = _nearY(gx, h) + h * .026;
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .0028)
      ..color = const Color.fromRGBO(150, 106, 52, .3);
    final lip = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, h * .0016)
      ..color = const Color.fromRGBO(255, 246, 220, .5);
    final gw = h * _goalWide * _matchGoalScale;
    c.drawLine(Offset(gx - h * .06, gy + h * .012), Offset(gx + gw * 1.25, gy + h * .012), groove);
    c.drawLine(Offset(gx - h * .06, gy + h * .0145), Offset(gx + gw * 1.25, gy + h * .0145), lip);
    _goal(c, Offset(gx, gy), gw);
    final picture = recorder.endRecording();
    _matchPictures[h] = picture;
    if (_matchPictures.length > 6) _matchPictures.remove(_matchPictures.keys.first)!.dispose();
    return picture;
  }

  /// A kid on a red cooler cheering the game on, waving both arms.
  static void _matchKid(Canvas c, Offset base, double s, double clock) {
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void seg(Offset a, Offset b, double w, Color col) {
      line
        ..strokeWidth = math.max(.9, w * s)
        ..color = col;
      c.drawLine(a, b, line);
    }

    // A pair of flip-flops left on the sand, the cooler and its shadow.
    for (final (dx, col) in const [(.62, Color(0xff2f8fd8)), (.78, Color(0xfffff6de))]) {
      c.drawOval(Rect.fromCenter(center: base + Offset(dx * s, s * .05), width: s * .13, height: s * .05), Paint()..color = col);
    }
    fill.color = const Color(0x2e6a4a1c);
    c.drawOval(Rect.fromCenter(center: base + Offset(-s * .12, s * .02), width: s * 1.0, height: s * .08), fill);
    final box = Rect.fromLTWH(base.dx - s * .3, base.dy - s * .3, s * .6, s * .3);
    c.drawRRect(RRect.fromRectAndRadius(box, Radius.circular(s * .03)), fill..color = const Color(0xffe2483a));
    c.drawRect(Rect.fromLTRB(box.left, box.top + s * .02, box.left + s * .16, box.bottom), fill..color = const Color(0x22000000));
    c.drawRect(Rect.fromLTRB(box.right - s * .1, box.top + s * .02, box.right, box.bottom), fill..color = const Color(0x2effffff));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(box.left - s * .02, box.top - s * .045, box.right + s * .02, box.top + s * .03), Radius.circular(s * .025)),
      fill..color = const Color(0xfff6f3ea),
    );
    seg(Offset(base.dx - s * .1, box.top + s * .13), Offset(base.dx + s * .1, box.top + s * .13), .02, const Color(0x55ffffff));
    // The kid sits looking left at the players.
    final seat = Offset(base.dx - s * .02, box.top - s * .04);
    const skin = Color(0xffb8804f), shirt = Color(0xff2fb5c8), shorts = Color(0xfff2758a);
    final knee = seat + Offset(-s * .3, s * .012), ankle = knee + Offset(-s * .02, s * .3 - s * .02 - s * .012);
    seg(seat, knee, .1, shorts);
    seg(knee, ankle, .075, skin);
    seg(ankle, ankle + Offset(-s * .08, s * .012), .06, const Color(0xff2f8fd8));
    final sh = seat + Offset(0, -s * .26);
    seg(seat, sh, .22, shirt);
    seg(seat + Offset(s * .06, 0), sh + Offset(s * .06, 0), .07, const Color(0x2effffff));
    final wave = math.sin(clock * 6.5);
    for (final (a, e, far) in [(2.2 + .25 * wave, 2.85 - .3 * wave, true), (2.85 - .25 * wave, 2.5 + .3 * wave, false)]) {
      final root = sh + Offset(s * .01, s * .02);
      final elbow = root + Offset(-math.sin(a), math.cos(a)) * (s * .15);
      final hand = elbow + Offset(-math.sin(e), math.cos(e)) * (s * .14);
      seg(root, hand, .055, far ? _dim(skin) : skin);
      seg(root, Offset.lerp(root, elbow, .5)!, .085, far ? _dim(shirt) : shirt);
      c.drawCircle(hand, s * .035, fill..color = far ? _dim(skin) : skin);
    }
    final head = sh + Offset(-s * .03, -s * .15);
    c.drawCircle(head, s * .105, fill..color = const Color(0xff2a2020));
    c.drawCircle(head + Offset(-s * .02, s * .015), s * .085, fill..color = skin);
    c.drawCircle(head + Offset(-s * .06, 0), math.max(.5, s * .012), fill..color = const Color(0xff2a2020));
    c.drawArc(
      Rect.fromCenter(center: head + Offset(-s * .06, s * .045), width: s * .07, height: s * .05),
      .1,
      math.pi * .8,
      false,
      line
        ..strokeWidth = math.max(.5, s * .012)
        ..color = const Color(0xff8a3030),
    );
  }

  @override
  void overlay(Canvas c, Depth d, SceneFrame f, double presence) {
    final h = f.h;
    switch (d) {
      case Depth.far:
        Sketch.mist(
          c,
          Rect.fromCenter(center: Offset(f.w * .5, h * .68), width: f.w * 1.3, height: h * .08),
          const Color(0xffeafaf8),
          .7 * presence,
        );
        // Cloud gathers on the peaks, as it does over Rio.
        _peakMist(c, f, presence);
      case Depth.low:
        _bayOverlay(c, f, presence);
      case Depth.near:
        _shore(c, f, presence);
        _beachProps(c, f, presence);
        _match(c, f, presence);
      case Depth.mid:
        _bayFar(c, f, presence);
    }
  }

  /// The far reaches of the bay, over the mid band's pale water: the hills'
  /// soft shadow along the shore and a scatter of lazy glints, longer and
  /// brighter the nearer they lie.
  void _bayFar(Canvas c, SceneFrame f, double a) {
    if (a <= .01) return;
    final h = f.h, t = f.clock, reach = f.w + h * .7;
    final view = c.getLocalClipBounds();
    final shore = Path();
    var first = true;
    for (var x = math.max(view.left - h * .1, -h * .1); x < math.min(view.right + h * .2, reach + h * .2); x += h * .08) {
      final y = ridge(Depth.mid, x / h, 0) * h + h * .009;
      if (first) {
        shore.moveTo(x, y);
        first = false;
      } else {
        shore.lineTo(x, y);
      }
    }
    c.drawPath(
      shore,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .016
        ..strokeJoin = StrokeJoin.round
        ..color = Color.fromRGBO(34, 110, 118, .16 * a),
    );
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 30; i++) {
      final x = reach * Sketch.hash(i + 1200);
      if (x < view.left - h * .1 || x > view.right) continue;
      final top = ridge(Depth.mid, x / h, 0) + .018, u = Sketch.hash(i + 1230);
      final y = (top + (.786 - top) * u) * h;
      final on = .55 + .45 * math.sin(t * (.6 + .5 * Sketch.hash(i + 1260)) + i * 2.1);
      final len = h * (.012 + .03 * u) * (.7 + .6 * Sketch.hash(i + 1290));
      c.drawLine(
        Offset(x, y),
        Offset(x + len, y),
        glint
          ..strokeWidth = math.max(.7, h * (.0014 + .0016 * u))
          ..color = Color.fromRGBO(255, 255, 255, (.16 + .3 * u) * on * a),
      );
    }
  }

  /// Surf lapping the sand: each wave runs up the beach at a slant, spreads a
  /// thin sheet of water and leaves a bright lace of foam along its front.
  void _shore(Canvas c, SceneFrame f, double presence) {
    final h = f.h, span = period(Depth.near);
    const samples = 48;
    double reach(double x) {
      final u = .5 + .5 * math.sin(f.clock * 1.05 + x * math.pi * 4 / span + .6 * math.sin(x * math.pi * 10 / span));
      return u * u * (3 - 2 * u);
    }

    final sheet = Path(), front = Path(), lace = Path(), crest = Path();
    final edge = <Offset>[], tip = <Offset>[];
    for (var i = 0; i <= samples; i++) {
      final x = span * i / samples;
      final y = ridge(Depth.near, x, 0) * h;
      edge.add(Offset(x * h, y));
      final r = reach(x);
      tip.add(Offset(x * h, y + h * (.002 + .019 * r)));
      final off = Offset(x * h, y - h * (.008 + .005 * (1 - r)));
      if (i == 0) {
        front.moveTo(tip[i].dx, tip[i].dy);
        crest.moveTo(off.dx, off.dy);
      } else {
        front.lineTo(tip[i].dx, tip[i].dy);
        if (Sketch.hash(i + 460) > .3) {
          crest.lineTo(off.dx, off.dy);
        } else {
          crest.moveTo(off.dx, off.dy);
        }
        if (Sketch.hash(i + 490) > .35) {
          lace.moveTo(tip[i - 1].dx, tip[i - 1].dy - h * .006);
          lace.lineTo(tip[i].dx, tip[i].dy - h * .0065);
        }
      }
    }
    sheet.moveTo(edge.first.dx, edge.first.dy - h * .001);
    for (final p in edge) {
      sheet.lineTo(p.dx, p.dy - h * .001);
    }
    for (final p in tip.reversed) {
      sheet.lineTo(p.dx, p.dy);
    }
    sheet.close();
    c.drawPath(sheet, Paint()..color = Sketch.fade(const Color(0xffd6f4f0), .5 * presence));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    c.drawPath(crest, line..strokeWidth = h * .003..color = Sketch.fade(const Color(0xffffffff), .5 * presence));
    c.drawPath(lace, line..strokeWidth = h * .0028..color = Sketch.fade(const Color(0xffffffff), .7 * presence));
    c.drawPath(front, line..strokeWidth = h * .0055..color = Sketch.fade(const Color(0xffffffff), .92 * presence));
  }

  /// The beach is static, so it is recorded once per viewport height and
  /// replayed; only the surf and a few living touches are drawn each frame.
  static final _beachPictures = <double, Picture>{};

  void _beachProps(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    var picture = _beachPictures.remove(h);
    if (picture == null) {
      final recorder = PictureRecorder();
      _beachPaint(Canvas(recorder), h);
      picture = recorder.endRecording();
      if (_beachPictures.length > 4) _beachPictures.remove(_beachPictures.keys.first)?.dispose();
    }
    _beachPictures[h] = picture;
    if (presence < .995) {
      c.saveLayer(
        Rect.fromLTWH(-h, 0, period(Depth.near) * h + h * 2, h),
        Paint()..color = Color.fromRGBO(0, 0, 0, presence),
      );
      c.drawPicture(picture);
      c.restore();
    } else {
      c.drawPicture(picture);
    }
    _beachLife(c, f, presence);
  }

  static const _beachSandLit = Color(0xfffff0c4);
  static const _beachWood = Color(0xffa8794a);
  static const _beachStraw = Color(0xffd6a650);
  static const _beachKioskAt = .76, _beachKioskW = .2, _beachCastleAt = 2.3;

  /// Where the kiosk stands (base centre) and the castle (base centre).
  Offset _beachKioskBase(double h) => Offset(h * _beachKioskAt, _nearY(h * _beachKioskAt, h) + h * .045);
  Offset _beachCastleBase(double h) => Offset(h * _beachCastleAt, _nearY(h * _beachCastleAt, h) + h * .068);

  /// Everything that stands on the sand, back to front.
  void _beachPaint(Canvas c, double h) {
    _beachSand(c, h);
    for (final (fx, s, lean, seed) in _palms) {
      final x = h * fx;
      _beachPalm(c, Offset(x, _nearY(x, h) + h * .04), h * .34 * s, lean, seed);
    }
    _beachKiosk(c, _beachKioskBase(h), h * _beachKioskW);
    _beachBoards(c, Offset(h * .5, _nearY(h * .5, h) + h * .05), h);
    _beachNet(c, Offset(h * 2.5, _nearY(h * 2.5, h) + h * .05), h * .24);
    _beachVendor(c, Offset(h * .99, _nearY(h * .99, h) + h * .05), h * .085);
    for (final (fx, i) in _umbrellas) {
      final x = h * fx, y = _nearY(x, h) + h * .05;
      _beachShadow(c, Offset(x - h * .03, y + h * .004), h * .17, h * .014, .2);
      _umbrella(c, Offset(x, y), h * .15, i);
      _beachChair(c, Offset(x + h * .09, y + h * .016), h * .075, i.isEven ? const Color(0xff2fb5d8) : const Color(0xffe94f6a));
      _beachTowel(c, Offset(x - h * .07, y + h * .016), h * .1, i);
    }
    _beachCastle(c, _beachCastleBase(h), h * .085);
  }

  static void _beachShadow(Canvas c, Offset at, double w, double hgt, double alpha) {
    c.drawOval(
      Rect.fromCenter(center: at, width: w, height: hgt),
      Paint()..color = Sketch.fade(const Color(0xff7a5426), alpha),
    );
  }

  /// Wet sand with its sheen, lace left by earlier waves, the tide line of
  /// weed and shells, wind ripples, speckle and trails of footprints.
  void _beachSand(Canvas c, double h) {
    final span = period(Depth.near) * h;
    const samples = 120;
    double xAt(int i) => span * i / samples;
    double edge(double x) => ridge(Depth.near, x / h, 0) * h;
    double wob(double x, int k, double ph) => math.sin(x / span * math.pi * 2 * k + ph);
    Path along(double down, {double amp = 0, int k = 9, double ph = 0, int gaps = 0}) {
      final p = Path();
      for (var i = 0; i <= samples; i++) {
        final x = xAt(i);
        final y = edge(x) + h * (down + amp * wob(x, k, ph));
        if (i == 0 || (gaps > 0 && Sketch.hash(i ~/ 3 + gaps) < .3)) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p;
    }

    // Broad dunes of light and shade.
    for (var j = 0; j < 6; j++) {
      final cx = span * (j + .5) / 6, cy = h * (.99 + .005 * (j % 2));
      c.drawOval(Rect.fromCenter(center: Offset(cx - h * .04, cy + h * .012), width: h * .62, height: h * .07), Paint()..color = const Color(0x16b98a4a));
      c.drawOval(Rect.fromCenter(center: Offset(cx + h * .05, cy - h * .006), width: h * .5, height: h * .05), Paint()..color = const Color(0x30fff2c8));
    }
    // Wet sand: dark at the water, drying downward.
    final wet = Path()..moveTo(0, edge(0) - h * .002);
    for (var i = 1; i <= samples; i++) {
      wet.lineTo(xAt(i), edge(xAt(i)) - h * .002);
    }
    for (var i = samples; i >= 0; i--) {
      wet.lineTo(xAt(i), edge(xAt(i)) + h * (.036 + .004 * wob(xAt(i), 6, 1)));
    }
    wet.close();
    c.drawPath(
      wet,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * .9),
          Offset(0, h * .942),
          const [Color(0xf2ad824a), Color(0xc8bd9156), Color(0x66d2b074), Color(0x00e4bd78)],
          const [0, .32, .68, 1],
        ),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Sky mirrored on the wet film, and lace from earlier waves.
    c.drawPath(along(.007, amp: .002, k: 12, ph: .5, gaps: 300), stroke..strokeWidth = h * .0034..color = const Color(0x88f0fbf6));
    for (var i = 0; i < 12; i++) {
      final cx = span * Sketch.hash(i + 510), cy = edge(cx) + h * (.011 + .005 * Sketch.hash(i + 520));
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: h * (.06 + .1 * Sketch.hash(i + 530)), height: h * .0045), Paint()..color = const Color(0x30ffffff));
    }
    c.drawPath(along(.031, amp: .004, k: 9, gaps: 320), stroke..strokeWidth = h * .0022..color = const Color(0x66ffffff));
    c.drawPath(along(.043, amp: .005, k: 14, ph: 1.3, gaps: 340), stroke..strokeWidth = h * .0018..color = const Color(0x44ffffff));
    // Wind ripples in the dry sand: a dark trough and a lit crest.
    final trough = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .0024
      ..color = const Color(0x22986a2e);
    final crestLit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .0016
      ..color = const Color(0x66fff6d8);
    for (var i = 0; i < 46; i++) {
      final x = span * Sketch.hash(i + 540), y = h * (.958 + .034 * Sketch.hash(i + 550));
      final len = h * (.05 + .07 * Sketch.hash(i + 560));
      for (var k = 0; k < 2 + i % 2; k++) {
        final ox = k * h * .012, oy = k * h * .006;
        final ripple = Path()
          ..moveTo(x + ox, y + oy)
          ..quadraticBezierTo(x + ox + len * .5, y + oy - h * .003, x + ox + len, y + oy + h * .001);
        c.drawPath(ripple.shift(Offset(0, h * .0022)), crestLit);
        c.drawPath(ripple, trough);
      }
    }
    // Speckle: grains that read as a tint.
    final dark = <Offset>[], light = <Offset>[];
    for (var i = 0; i < 260; i++) {
      final x = span * Sketch.hash(i + 570);
      final y = edge(x) + h * .04 + (h - edge(x) - h * .04) * Sketch.hash(i + 580);
      (i.isEven ? dark : light).add(Offset(x, y));
    }
    c.drawPoints(PointMode.points, dark, Paint()..strokeCap = StrokeCap.round..strokeWidth = h * .0032..color = const Color(0x2c8a5f2a));
    c.drawPoints(PointMode.points, light, Paint()..strokeCap = StrokeCap.round..strokeWidth = h * .0032..color = const Color(0x66fff8e0));
    // The tide line: weed, shells, pebbles.
    final weed = Paint();
    for (var i = 0; i < 15; i++) {
      final x = span * (i + .2 + .6 * Sketch.hash(i + 600)) / 15;
      final y = edge(x) + h * (.05 + .005 * wob(x, 6, 2) + .008 * Sketch.hash(i + 610));
      // A tangle of flat strands fanning from one knot.
      for (var k = 0; k < 4; k++) {
        final len = h * (.012 + .02 * Sketch.hash(i * 5 + k + 620)), ang = -math.pi * (.08 + .84 * Sketch.hash(i * 5 + k + 630));
        final tip = Offset(x + math.cos(ang) * len, y + math.sin(ang) * len * .35 + len * .1);
        final mid = Offset(x + math.cos(ang) * len * .5, y + math.sin(ang) * len * .35 - len * .2);
        weed.color = [const Color(0xff55652f), const Color(0xff7a6a36), const Color(0xff3e5230), const Color(0xff8a7a40)][(i + k) % 4].withValues(alpha: .85);
        c.drawPath(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(mid.dx, mid.dy - h * .002, tip.dx, tip.dy)
            ..quadraticBezierTo(mid.dx, mid.dy + h * .002, x, y + h * .001),
          weed,
        );
      }
      if (i % 3 == 0) c.drawCircle(Offset(x + h * .004, y - h * .005), h * .0022, weed..color = const Color(0xff9a9a40));
    }
    for (var i = 0; i < 16; i++) {
      final x = span * (i + .3 + .4 * Sketch.hash(i + 640)) / 16;
      final at = Offset(x, edge(x) + h * (.047 + .012 * Sketch.hash(i + 650)));
      _beachShell(c, at, h * (.007 + .005 * Sketch.hash(i + 660)), i % 4, i);
    }
    // Hero finds: starfish, conch, sand dollar.
    _beachShell(c, Offset(h * .62, edge(h * .62) + h * .085), h * .014, 4, 1);
    _beachShell(c, Offset(h * 2.5, edge(h * 2.5) + h * .078), h * .012, 5, 2);
    _beachShell(c, Offset(h * 1.75, edge(h * 1.75) + h * .07), h * .011, 4, 3);
    _beachShell(c, Offset(h * 1.4, edge(h * 1.4) + h * .078), h * .012, 3, 4);
    _beachSteps(c, h, h * 1.3, h * .985, 1, 14);
    _beachSteps(c, h, h * 2.9, h * .987, -1, 8);
  }

  /// A trail of bare footprints along the sand, [dir] the way they walk.
  static void _beachSteps(Canvas c, double h, double x0, double y0, double dir, int n) {
    final pit = Paint()..color = const Color(0x40805a28);
    final rim = Paint()..color = const Color(0x77fff4d0);
    for (var k = 0; k < n; k++) {
      final x = x0 + dir * k * h * .034, y = y0 + (k.isEven ? -1 : 1) * h * .0035 + h * .003 * math.sin(k * .5);
      c.drawOval(Rect.fromCenter(center: Offset(x + h * .0012, y + h * .0016), width: h * .0125, height: h * .0058), rim);
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: h * .0125, height: h * .0058), pit);
      for (var t = 0; t < 3; t++) {
        c.drawCircle(Offset(x + dir * h * (.0075 + t * .0006), y - h * .0022 + t * h * .0022), h * .0011, pit);
      }
    }
  }

  /// Small finds on the sand: 0 scallop, 1 pebble, 2 spiral, 3 sand dollar,
  /// 4 starfish, 5 conch.
  static void _beachShell(Canvas c, Offset at, double r, int kind, int seed) {
    final p = Paint();
    c.drawOval(Rect.fromCenter(center: at + Offset(-r * .2, r * .45), width: r * 2.1, height: r * .7), p..color = const Color(0x2a7a5426));
    switch (kind) {
      case 0:
        p.color = const Color(0xfff2c2b0);
        c.drawPath(
          Path()
            ..moveTo(at.dx - r, at.dy)
            ..quadraticBezierTo(at.dx, at.dy - r * 2, at.dx + r, at.dy)
            ..close(),
          p,
        );
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.5, r * .1)
          ..color = const Color(0x88b96a5a);
        for (var k = -1; k <= 1; k++) {
          c.drawLine(at, at + Offset(k * r * .5, -r * .9), p);
        }
      case 1:
        c.drawOval(Rect.fromCenter(center: at, width: r * 1.4, height: r * .9), p..color = Sketch.mix(const Color(0xff6a5a4a), const Color(0xff9a8a78), Sketch.hash(seed + 700)));
      case 2:
        p.color = const Color(0xfff6e6d0);
        c.drawPath(Sketch.poly([at.dx - r, at.dy, at.dx + r * .3, at.dy - r * .9, at.dx + r, at.dy]), p);
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.5, r * .16)
          ..color = const Color(0xffb8804a);
        c.drawLine(at + Offset(-r * .45, -r * .3), at + Offset(r * .7, -r * .3), p);
      case 3:
        c.drawCircle(at, r, p..color = const Color(0xfff4e8d2));
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.5, r * .1)
          ..color = const Color(0xffc8b090);
        for (var k = 0; k < 5; k++) {
          final a = k * math.pi * .4 - math.pi / 2;
          c.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * r * .75, p);
        }
      case 4:
        p.color = const Color(0xfff2874f);
        final pts = <double>[];
        for (var k = 0; k < 10; k++) {
          final a = k * math.pi * .2 - math.pi / 2 + .3;
          final rr = k.isEven ? r * 1.3 : r * .5;
          pts
            ..add(at.dx + math.cos(a) * rr)
            ..add(at.dy + math.sin(a) * rr * .8);
        }
        c.drawPath(Sketch.poly(pts), p);
        c.drawCircle(at, r * .25, p..color = const Color(0xffffc08a));
      default:
        p.color = const Color(0xfff4dcc0);
        c.drawOval(Rect.fromCenter(center: at, width: r * 2.4, height: r * 1.1), p);
        c.drawCircle(at + Offset(r * .8, 0), r * .5, p);
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.5, r * .14)
          ..color = const Color(0xffd08a5a);
        c.drawLine(at + Offset(-r * .6, -r * .2), at + Offset(r * .5, -r * .2), p);
        c.drawLine(at + Offset(-r * .5, r * .2), at + Offset(r * .4, r * .2), p);
    }
  }

  static Offset _beachQuad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  static Offset _beachTan(Offset a, Offset b, Offset c, double t) {
    final v = (b - a) * (2 * (1 - t)) + (c - b) * (2 * t);
    final d = v.distance;
    return d == 0 ? const Offset(0, -1) : v / d;
  }

  /// A coconut palm standing in the sand: a ringed, three-plane trunk, a
  /// crown of feathered fronds lit from the sun's side, and its coconuts.
  static void _beachPalm(Canvas c, Offset base, double H, double lean, int seed) {
    final crown = base + Offset(lean * H, -H);
    final ctrl = base + Offset(lean * H * .06, -H * .62);
    Offset at(double t) => _beachQuad(base, ctrl, crown, t);
    double half(double t) => H * (.05 - .022 * t + .03 * math.pow(1 - t, 8));
    Offset side(double t, double k) {
      final tg = _beachTan(base, ctrl, crown, t);
      return at(t) + Offset(-tg.dy, tg.dx) * (half(t) * k);
    }

    Path band(double k0, double k1) {
      const n = 20;
      final p = Path();
      for (var i = 0; i <= n; i++) {
        final o = side(i / n, k0);
        if (i == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
      for (var i = n; i >= 0; i--) {
        final o = side(i / n, k1);
        p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    // Shadow on the sand, thrown away from the sun on the right.
    _beachShadow(c, base + Offset(-H * .5, H * .01), H * .95, H * .06, .18);
    _beachShadow(c, base + Offset(-H * .62, H * .012), H * .55, H * .045, .12);
    c.drawPath(band(-1, 1), Paint()..color = const Color(0xff9d7a4e));
    c.drawPath(band(-1, -.2), Paint()..color = const Color(0xff70502f));
    c.drawPath(band(.35, 1), Paint()..color = const Color(0xffc29a66));
    final rings = Path(), lights = Path();
    for (var t = .04; t < .98; t += .046) {
      final a = side(t, -1), b = side(t, 1), tg = _beachTan(base, ctrl, crown, t);
      final bulge = at(t) - tg * (half(t) * .5);
      final up = tg * (H * .012);
      rings
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(bulge.dx, bulge.dy, b.dx, b.dy);
      lights
        ..moveTo(a.dx + up.dx, a.dy + up.dy)
        ..quadraticBezierTo(bulge.dx + up.dx, bulge.dy + up.dy, b.dx + up.dx, b.dy + up.dy);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(lights, line..strokeWidth = math.max(.6, H * .006)..color = const Color(0x55f2d6a0));
    c.drawPath(rings, line..strokeWidth = math.max(.8, H * .01)..color = const Color(0x8a4a3220));
    // Sand heaped around the foot, with a few blades of grass and fallen nuts.
    c.drawOval(Rect.fromCenter(center: base + Offset(0, H * .002), width: H * .26, height: H * .05), Paint()..color = const Color(0xffe8c888));
    c.drawOval(Rect.fromCenter(center: base + Offset(H * .03, -H * .002), width: H * .17, height: H * .028), Paint()..color = _beachSandLit);
    final blade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, H * .008);
    for (var k = 0; k < 7; k++) {
      final x = base.dx - H * .09 + k * H * .03, lift = H * (.035 + .025 * Sketch.hash(seed * 9 + k));
      final swing = (k - 3) * H * .012;
      c.drawPath(
        Path()
          ..moveTo(x, base.dy - H * .005)
          ..quadraticBezierTo(x + swing * .3, base.dy - lift * .6, x + swing, base.dy - lift),
        blade..color = k.isEven ? const Color(0xff4f9a4a) : const Color(0xff7bbf5a),
      );
    }
    for (final (dx, dy) in const [(-.16, .012), (.15, .018)]) {
      final p = base + Offset(dx * H, dy * H);
      c.drawCircle(p, H * .022, Paint()..color = const Color(0xff7a5230));
      c.drawCircle(p + Offset(H * .006, -H * .006), H * .008, Paint()..color = const Color(0xffb88450));
    }
    // Crown: back fronds in shade, coconuts, then the lit front fronds.
    void frond(double deg, double len, double sag, double lit) {
      final th = deg * math.pi / 180 + (Sketch.hash(seed * 31 + deg.round() + 100) - .5) * .12;
      final dir = Offset(math.cos(th), -math.sin(th));
      final l = H * len * (.94 + .12 * Sketch.hash(seed * 17 + deg.round() + 100));
      final tip = crown + dir * l + Offset(0, l * sag * .42);
      final bend = dir.dx >= 0 ? 1.0 : -1.0;
      final ctl = crown + dir * l * .55 + Offset(bend * l * .06, -l * .16);
      final leaf = l * .2;
      final body = Sketch.mix(const Color(0xff236b3c), const Color(0xff4fae5e), lit);
      c.drawPath(_beachBlade(crown, ctl, tip, leaf, 0, 16), Paint()..color = body);
      final tg = _beachTan(crown, ctl, tip, .5);
      if (lit > .35) {
        c.drawPath(_beachBlade(crown, ctl, tip, leaf, tg.dx >= 0 ? -1 : 1, 16), Paint()..color = Sketch.mix(body, const Color(0xff9fe08a), .35));
      }
      c.drawPath(
        Path()
          ..moveTo(crown.dx, crown.dy)
          ..quadraticBezierTo(ctl.dx, ctl.dy, tip.dx, tip.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(.7, H * .008)
          ..color = Sketch.mix(const Color(0xff2a6a3a), const Color(0xffc8e890), lit * .8),
      );
    }

    for (final (deg, len, sag, lit) in const [
      (200.0, .5, 1.3, .0),
      (-22.0, .5, 1.3, .2),
      (165.0, .56, 1.0, .1),
      (18.0, .56, 1.0, .3),
      (134.0, .5, .5, .25),
      (50.0, .5, .5, .45),
    ]) {
      frond(deg, len, sag, lit);
    }
    // Two dry brown fronds hanging under the crown.
    for (final (dx, tilt) in const [(-.03, -.5), (.035, .4)]) {
      final root = crown + Offset(dx * H, H * .02);
      final tip = root + Offset(tilt * H * .2, H * .2);
      c.drawPath(_beachBlade(root, root + Offset(tilt * H * .14, H * .08), tip, H * .04, 0, 9), Paint()..color = const Color(0xffa07a3a));
    }
    for (final (dx, dy, r, ripe) in const [(-.045, .045, .03, false), (.02, .055, .033, true), (.06, .04, .029, false), (-.005, .03, .03, true), (.03, .03, .027, false)]) {
      final p = crown + Offset(dx * H, dy * H);
      c.drawCircle(p, H * r, Paint()..color = ripe ? const Color(0xff7a5230) : const Color(0xff8fa842));
      c.drawCircle(p + Offset(H * r * .35, -H * r * .35), H * r * .38, Paint()..color = ripe ? const Color(0xffb88450) : const Color(0xffc4d878));
    }
    for (final (deg, len, sag, lit) in const [
      (176.0, .46, .9, .55),
      (4.0, .46, .9, .8),
      (147.0, .46, .55, .6),
      (33.0, .46, .55, .95),
      (112.0, .4, .3, .7),
      (72.0, .4, .3, 1.0),
      (92.0, .3, .12, .9),
    ]) {
      frond(deg, len, sag, lit);
    }
    c.drawCircle(crown, H * .03, Paint()..color = const Color(0xff2a6a3a));
  }

  /// A feathered frond outline along the arch [a] .. [c]: leaflets sweep
  /// toward the tip on the [side] (+1 / -1) or on both sides (0).
  static Path _beachBlade(Offset a, Offset b, Offset c, double leaf, int side, int n) {
    List<Offset> edge(double s) {
      final pts = <Offset>[];
      for (var i = 0; i < n; i++) {
        final t = .06 + .92 * i / n, t2 = .06 + .92 * (i + .5) / n;
        final tg = _beachTan(a, b, c, t), nr = Offset(-tg.dy, tg.dx) * s;
        final len = leaf * (.3 + .7 * math.sin(math.pi * math.min(1.0, t * .92 + .06)));
        pts.add(_beachQuad(a, b, c, t) + (tg * .8 + nr * .6 + const Offset(0, .3)) * len);
        final tg2 = _beachTan(a, b, c, t2), nr2 = Offset(-tg2.dy, tg2.dx) * s;
        pts.add(_beachQuad(a, b, c, t2) + nr2 * (len * .22));
      }
      return pts;
    }

    final p = Path()..moveTo(a.dx, a.dy);
    if (side == 0) {
      for (final o in edge(1)) {
        p.lineTo(o.dx, o.dy);
      }
      p.lineTo(c.dx, c.dy);
      for (final o in edge(-1).reversed) {
        p.lineTo(o.dx, o.dy);
      }
    } else {
      for (final o in edge(side.toDouble())) {
        p.lineTo(o.dx, o.dy);
      }
      p.lineTo(c.dx, c.dy);
    }
    return p..close();
  }

  @override
  void reflect(Canvas c, SceneFrame f, double presence) {
    // A broken path of sun glitter that widens toward the viewer.
    final h = f.h, cx = f.w * light.at.dx;
    final glint = Paint()..strokeCap = StrokeCap.round;
    for (var row = 0; row < 9; row++) {
      final u = row / 8;
      final y = h * (.803 + .092 * u);
      for (var k = 0; k < 3; k++) {
        final seed = 950 + row * 3 + k;
        final on = .5 + .5 * math.sin(f.clock * (1.4 + Sketch.hash(seed)) + seed * 1.9);
        final x = cx + (Sketch.hash(seed + 40) * 2 - 1) * h * (.025 + .16 * u) * (1 - .35 * k / 2);
        final len = h * (.008 + .022 * u) * (.5 + .5 * on) * (.7 + .5 * Sketch.hash(seed + 80));
        glint
          ..strokeWidth = math.max(.8, h * (.0025 + .002 * u))
          ..color = Sketch.fade(const Color(0xfffffce0), (.35 + .5 * on) * presence);
        c.drawLine(Offset(x - len, y + h * .003 * Sketch.hash(seed + 120)), Offset(x + len, y), glint);
      }
    }
  }

  @override
  void sky(Canvas c, SceneFrame f, double presence) {
    final sun = Offset(f.w * light.at.dx, f.h * light.at.dy);
    final glow = _sunnyShaders(f.size, sun, light.radius * f.h);
    _sunnyWash(c, f, sun, glow, presence);
    _sunnyRays(c, f, sun, glow[4], presence);
    _sunnyClouds(c, f, presence);
    _sunnyBloom(c, f, sun, light.radius * f.h, glow, presence);
    _sunnyBirds(c, f, presence);
    _sunnyPlane(c, f, presence);
    _sunnyParagliders(c, f, presence);
    _hangGlider(c, f.w, f.h, f.clock, presence);
  }

  static final _sunnyFillPaint = Paint();
  static final _sunnyLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Paint _sunnyFill(Color color, double alpha) => _sunnyFillPaint
    ..shader = null
    ..blendMode = BlendMode.srcOver
    ..color = Sketch.fade(color, alpha);

  static Paint _sunnyLine(Color color, double alpha, double width) => _sunnyLinePaint
    ..color = Sketch.fade(color, alpha)
    ..strokeWidth = width;

  /// A cached shader painted at [alpha]: paint alpha scales a shader, so one
  /// gradient serves every crossing frame.
  static Paint _sunnyTint(Shader shader, double alpha, [BlendMode mode = BlendMode.srcOver]) => _sunnyFillPaint
    ..shader = shader
    ..blendMode = mode
    ..color = Color.fromRGBO(0, 0, 0, alpha);

  static final _sunnyGlow = <(double, double), List<Shader>>{};

  /// The gradients of the sky's light, built once per viewport: cobalt at the
  /// zenith, a dark top corner, a pearly horizon belt, warm daylight round the
  /// sun, its shafts, the glare, the white-hot core and a faint prismatic ring.
  static List<Shader> _sunnyShaders(Size size, Offset sun, double r) {
    final key = (size.width, size.height);
    final cached = _sunnyGlow.remove(key);
    if (cached != null) return _sunnyGlow[key] = cached;
    final h = size.height;
    const deep = Color(0xff1668cc), pearl = Color(0xfffffbe8), warm = Color(0xfffff0b0);
    const ray = Color(0xfffff6cc), glare = Color(0xfffffbe0);
    final shaders = <Shader>[
      Gradient.linear(Offset.zero, Offset(0, h * .55), [Sketch.fade(deep, .3), Sketch.fade(deep, 0)]),
      Gradient.radial(Offset.zero, h * 1.3, [Sketch.fade(deep, .24), Sketch.fade(deep, 0)]),
      Gradient.linear(Offset(0, h * .4), Offset(0, h * .7), [Sketch.fade(pearl, 0), Sketch.fade(pearl, .22), Sketch.fade(pearl, 0)], const [0, .62, 1]),
      Gradient.radial(sun, h * .95, [Sketch.fade(warm, .17), Sketch.fade(warm, 0)]),
      Gradient.radial(sun, h * 1.25, [Sketch.fade(ray, .1), Sketch.fade(ray, .045), Sketch.fade(ray, 0)], const [.06, .5, 1]),
      Gradient.radial(sun, h * .55, [Sketch.fade(glare, .5), Sketch.fade(glare, .16), Sketch.fade(glare, 0)], const [0, .2, 1]),
      Gradient.radial(sun, r * 1.05, [const Color(0xf2ffffff), Sketch.fade(glare, .7), Sketch.fade(glare, 0)], const [0, .6, 1]),
      Gradient.radial(
        sun,
        h * .3,
        [
          const Color(0x00ffffff),
          const Color(0x00ffffff),
          Sketch.fade(const Color(0xffbfe8ff), .07),
          Sketch.fade(const Color(0xfffff2b0), .08),
          Sketch.fade(const Color(0xffffc8d8), .06),
          const Color(0x00ffffff),
        ],
        const [0, .78, .84, .9, .95, 1],
      ),
    ];
    _sunnyGlow[key] = shaders;
    if (_sunnyGlow.length > 6) {
      for (final old in _sunnyGlow.remove(_sunnyGlow.keys.first)!) {
        old.dispose();
      }
    }
    return shaders;
  }

  /// Deeper cobalt toward the top corner, a pearly belt of sea haze along the
  /// horizon and warm daylight pooled round the sun: the tints that lift the
  /// flat gradient into a tropical sky.
  static void _sunnyWash(Canvas c, SceneFrame f, Offset sun, List<Shader> glow, double presence) {
    final w = f.w, h = f.h;
    c.drawRect(Rect.fromLTWH(0, 0, w, h * .55), _sunnyTint(glow[0], presence));
    c.drawRect(Rect.fromLTWH(0, 0, w, h * .9), _sunnyTint(glow[1], presence));
    c.drawRect(Rect.fromLTWH(0, h * .4, w, h * .3), _sunnyTint(glow[2], presence));
    // The sun travels to the next region's light while the sky fades, so its
    // own glow leaves faster than the clouds.
    c.drawCircle(sun, h * .95, _sunnyTint(glow[3], presence * presence));
  }

  /// Wide soft shafts of sunlight fanning down and away from the sun.
  static void _sunnyRays(Canvas c, SceneFrame f, Offset sun, Shader shader, double presence) {
    final h = f.h, t = f.clock;
    final len = h * 1.25;
    const angles = [1.05, 1.5, 1.85, 2.2, 2.55, 2.95, 3.3];
    const spreads = [.03, .022, .035, .026, .04, .024, .03];
    final beams = Path();
    for (var i = 0; i < angles.length; i++) {
      final s = spreads[i] * (1 + .2 * math.sin(t * .33 + i * 1.7));
      beams
        ..moveTo(sun.dx, sun.dy)
        ..lineTo(sun.dx + math.cos(angles[i] - s) * len, sun.dy + math.sin(angles[i] - s) * len)
        ..lineTo(sun.dx + math.cos(angles[i] + s) * len, sun.dy + math.sin(angles[i] + s) * len)
        ..close();
    }
    c.drawPath(beams, _sunnyTint(shader, presence * presence));
  }

  /// Glare over the clouds nearest the sun, a white-hot core in the disc and
  /// a faint prismatic ring round it.
  static void _sunnyBloom(Canvas c, SceneFrame f, Offset sun, double r, List<Shader> glow, double presence) {
    final h = f.h;
    c.drawCircle(sun, h * .55, _sunnyTint(glow[5], presence * presence, BlendMode.screen));
    c.drawCircle(sun, r * 1.05, _sunnyTint(glow[6], presence * presence * presence));
    c.drawCircle(sun, h * .3, _sunnyTint(glow[7], presence * presence * presence));
  }

  static final _sunnyPics = <(double, double), List<Picture>>{};

  static const _sunnyLit = Color(0xfff9fcff);
  static const _sunnyMid = Color(0xffc4daf1);
  static const _sunnyShade = Color(0xff8eb0dc);
  static const _sunnyBelly = Color(0xff86a9d6);

  /// The cloud decks in painting order, each as (span in viewport heights,
  /// seconds per repeat, phase): high cirrus, a bank on the horizon, and two
  /// ranks of cumulus. A repeat time that divides 132 s, half a lap of the
  /// world tour, keeps the sky on every visit to Brazil the same as at clock
  /// 0, so a composed picture is what the player sees.
  static const _sunnyDecks = [(3.4, 264.0, .2), (2.8, 264.0, .55), (3.0, 132.0, .0), (3.6, 132.0, .35)];

  /// Cirrus, a distant bank and two ranks of cumulus, each drifting at its own
  /// pace and drawn from a cached picture.
  static void _sunnyClouds(Canvas c, SceneFrame f, double presence) {
    if (presence <= 0) return;
    final w = f.w, h = f.h;
    final pics = _sunnyPictures(f.size);
    final fading = presence < .995;
    if (fading) {
      c.saveLayer(Rect.fromLTWH(0, 0, w, h * .7), Paint()..color = Color.fromRGBO(0, 0, 0, presence));
    }
    for (final (i, (spanH, period, phase)) in _sunnyDecks.indexed) {
      final span = spanH * h;
      final x0 = -(((f.clock / period + phase) * span) % span);
      for (var k = 0; k < 2; k++) {
        final x = x0 + k * span;
        if (x > w) break;
        c.save();
        c.translate(x, 0);
        c.drawPicture(pics[i]);
        c.restore();
      }
    }
    if (fading) c.restore();
  }

  static List<Picture> _sunnyPictures(Size size) {
    final key = (size.width, size.height);
    final cached = _sunnyPics.remove(key);
    if (cached != null) return _sunnyPics[key] = cached;
    final h = size.height;
    Picture record(void Function(Canvas c) paint) {
      final recorder = PictureRecorder();
      paint(Canvas(recorder));
      return recorder.endRecording();
    }

    void clouds(Canvas c, List<(double, double, double, double, int)> specs, {double haze = 0}) {
      for (final (cx, base, width, height, seed) in specs) {
        _sunnyCumulus(c, cx * h, base * h, width * h, height * h, seed, haze: haze);
      }
    }

    final pics = [
      record((c) => _sunnyCirrus(c, h, _sunnyDecks[0].$1)),
      record((c) => clouds(c, const [(.4, .64, .7, .13, 101), (1.1, .64, .45, .09, 102), (1.8, .64, .8, .14, 103), (2.45, .64, .4, .08, 104)], haze: .42)),
      record((c) => clouds(c, const [(.55, .25, .58, .13, 111), (1.5, .2, .34, .075, 112), (2.4, .255, .72, .16, 113)])),
      record((c) => clouds(c, const [(.8, .105, .4, .085, 121), (2.3, .085, .32, .07, 122)], haze: .12)),
    ];
    _sunnyPics[key] = pics;
    if (_sunnyPics.length > 6) {
      for (final p in _sunnyPics.remove(_sunnyPics.keys.first)!) {
        p.dispose();
      }
    }
    return pics;
  }

  /// A fair-weather cumulus on a flat base: a mound of round puffs painted top
  /// down so the lower ones bulge over the upper, each bright toward the sun
  /// and pale blue away from it, then a flat shaded belly.
  static void _sunnyCumulus(Canvas c, double cx, double base, double width, double height, int seed, {double haze = 0}) {
    Color tone(Color t) => haze > 0 ? _hazed(t, haze) : t;
    final lit = tone(_sunnyLit), mid = tone(_sunnyMid), shade = tone(_sunnyShade), belly = tone(_sunnyBelly);
    final puffs = <(double, double, double)>[];
    final r0 = height * (.25 + .05 * Sketch.hash(seed));
    final n = math.max(3, (width / (r0 * 1.45)).round());
    for (var j = 0; j < n; j++) {
      final t = (j + .5) / n;
      final env = math.pow(math.sin(t * math.pi), .7).toDouble();
      final k = seed * 31 + j * 7;
      final r = r0 * (.62 + .6 * env) * (.75 + .5 * Sketch.hash(k));
      final x = cx - width / 2 + width * t + (Sketch.hash(k + 1) - .5) * r * .3;
      final y = base - r * (.5 + .3 * (1 - env));
      puffs.add((x, y, r));
      var pr = r, py = y, px = x;
      final top = height * (.25 + .75 * math.pow(env, 1.4)) * (.8 + .2 * Sketch.hash(k + 2));
      for (var s = 0; s < 4; s++) {
        if (base - (py - pr) >= top) break;
        final nr = pr * (.7 + .12 * Sketch.hash(k + 3 + s));
        py -= pr * .55 + nr * .45;
        px += (Sketch.hash(k + 9 + s) - .5) * nr * .8;
        pr = nr;
        puffs.add((px, py, pr));
      }
      // A small bud on the crown of the taller columns.
      if (env > .35) puffs.add((px + (Sketch.hash(k + 20) - .5) * pr * .9, py - pr * .8, pr * .5));
    }
    puffs.sort((a, b) => (a.$2 - a.$3 * .3).compareTo(b.$2 - b.$3 * .3));
    // Scattered light glows softly round the whole mass.
    Sketch.mist(c, Rect.fromCenter(center: Offset(cx, base - height * .45), width: width * 1.3, height: height * 1.5), tone(const Color(0xffffffff)), .28);
    c.save();
    c.clipRect(Rect.fromLTRB(cx - width, base - height * 3, cx + width, base));
    for (final (x, y, r) in puffs) {
      c.drawCircle(
        Offset(x, y),
        r,
        Paint()..shader = Gradient.radial(Offset(x + r * .2, y - r * .3), r * 1.55, [lit, lit, mid, shade], const [0, .4, .74, .93]),
      );
    }
    // The flat belly: cool shade pooled under the middle of the base.
    final bh = height * .3;
    c.save();
    c.translate(cx, base);
    c.scale(width * .52, bh);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()..shader = Gradient.radial(Offset.zero, 1, [Sketch.fade(belly, .75), Sketch.fade(belly, .5), Sketch.fade(belly, 0)], const [0, .6, 1]),
    );
    c.restore();
    c.restore();
  }

  /// A lens of thin cloud centred on [cx], [cy], [len] long, tilted by [tilt],
  /// sagging by [bow] and [th] thick at the belly.
  static void _sunnyStreak(Path p, double cx, double cy, double len, double tilt, double bow, double th) {
    final dx = math.cos(tilt) * len / 2, dy = math.sin(tilt) * len / 2;
    final nx = -math.sin(tilt), ny = math.cos(tilt);
    final a = Offset(cx - dx, cy - dy), b = Offset(cx + dx, cy + dy);
    final m = Offset(cx + nx * bow, cy + ny * bow);
    p
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(m.dx + nx * th, m.dy + ny * th, b.dx, b.dy)
      ..quadraticBezierTo(m.dx - nx * th, m.dy - ny * th, a.dx, a.dy);
  }

  /// Faint high cirrus: bundles of thin streaks.
  static void _sunnyCirrus(Canvas c, double h, double span) {
    final haze = Path(), thin = Path();
    for (var i = 0; i < 7; i++) {
      final x = (.4 + (span - .8) * (i + .15 + .7 * Sketch.hash(950 + i)) / 7) * h;
      final y = h * (.035 + .13 * Sketch.hash(960 + i));
      final len = h * (.28 + .5 * Sketch.hash(970 + i));
      final tilt = -.06 + .07 * Sketch.hash(980 + i);
      final bow = len * .1 * (Sketch.hash(990 + i) - .4);
      for (final (dx, dy, k, th) in const [(0.0, 0.0, 1.0, .0055), (.05, .02, .62, .004), (-.04, -.016, .48, .003)]) {
        _sunnyStreak(haze, x + dx * h, y + dy * h, len * k, tilt, bow * k, h * th * 3);
        _sunnyStreak(thin, x + dx * h, y + dy * h, len * k, tilt, bow * k, h * th);
      }
    }
    c.drawPath(haze, Paint()..color = const Color(0x18ffffff));
    c.drawPath(thin, Paint()..color = const Color(0x4cffffff));
  }

  /// Where something crossing the sky is at [t]: it wraps every [period]
  /// seconds over [span] (with [margin] off screen) and is at [at] at clock 0.
  static double _sunnyCross(double t, double at, double span, double margin, double period, double dir) =>
      (at + margin + dir * span * t / period) % span - margin;

  /// Flap of a gliding bird, -1 wings down to 1 wings up: bursts of beats
  /// between long glides.
  static double _sunnyFlap(double t, double seed) {
    final burst = ((math.sin(t * .31 + seed * 2.1) + .25) * 2).clamp(0.0, 1.0);
    return .12 + burst * .8 * math.sin(t * (4.2 + .3 * (seed % 3)) + seed * 1.9);
  }

  /// One wing seen from below, as a smooth leaf running shoulder, elbow,
  /// wrist, tip; [flap] raises it. The chords are those of the elbow and
  /// wrist ([c1], [c2]) and the root ([c0]) in units of [s].
  static (Path, Path) _sunnyWing(Offset root, double side, double s, double flap, {double arm = .42, double hand = .36, double tipLen = .3, double bend = .55, double c0 = .15, double c1 = .14, double c2 = .095}) {
    final up1 = .26 + .5 * flap, up2 = up1 - bend + .5 * flap, up3 = up2 - .12;
    Offset dir(double a) => Offset(side * math.cos(a), -math.sin(a));
    Offset norm(double a) => Offset(side * math.sin(a), math.cos(a));
    final e = root + dir(up1) * s * arm;
    final wr = e + dir(up2) * s * hand;
    final tip = wr + dir(up3) * s * tipLen;
    final t2 = wr + norm(up2) * s * c2;
    final t1 = e + norm((up1 + up2) / 2) * s * c1;
    final t0 = root + norm(up1) * s * c0;
    final wing = Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(e.dx, e.dy, wr.dx, wr.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(t2.dx, t2.dy)
      ..quadraticBezierTo(t1.dx, t1.dy, t0.dx, t0.dy)
      ..close();
    final a = Offset.lerp(wr, tip, .3)!;
    final tipPath = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(Offset.lerp(t2, tip, .3)!.dx, Offset.lerp(t2, tip, .3)!.dy)
      ..close();
    return (wing, tipPath);
  }

  /// A seagull gliding toward [dir] (-1 left, 1 right): white with black
  /// wingtips, a rounded body and a small yellow bill.
  static void _sunnyGull(Canvas c, Offset p, double s, double flap, double dir, double alpha) {
    final wings = Path(), tips = Path();
    for (final side in const [-1.0, 1.0]) {
      final (wing, tip) = _sunnyWing(p + Offset(side * s * .05, 0), side, s, flap, c0: .24, c1: .22, c2: .14);
      wings.addPath(wing, Offset.zero);
      tips.addPath(tip, Offset.zero);
    }
    final body = Path()
      ..addOval(Rect.fromCenter(center: p + Offset(0, s * .03), width: s * .34, height: s * .12))
      ..addOval(Rect.fromCenter(center: p + Offset(dir * s * .18, -s * .005), width: s * .1, height: s * .09))
      ..moveTo(p.dx - dir * s * .14, p.dy)
      ..lineTo(p.dx - dir * s * .3, p.dy + s * .01)
      ..lineTo(p.dx - dir * s * .14, p.dy + s * .08)
      ..close();
    c.drawPath(wings, _sunnyFill(const Color(0xffdfeaf6), alpha));
    c.drawPath(tips, _sunnyFill(const Color(0xff2a3340), alpha * .9));
    c.drawPath(body, _sunnyFill(const Color(0xffffffff), alpha));
  }

  /// A frigatebird soaring: sooty, with long angular wings and a forked tail.
  static void _sunnyFrigate(Canvas c, Offset p, double s, double flap, double dir, double alpha) {
    final wings = Path();
    for (final side in const [-1.0, 1.0]) {
      final (wing, _) = _sunnyWing(p + Offset(side * s * .05, 0), side, s, flap, arm: .46, hand: .5, tipLen: .36, bend: .62, c0: .17, c1: .13, c2: .075);
      wings.addPath(wing, Offset.zero);
    }
    final tail = Path()
      ..moveTo(p.dx - dir * s * .08, p.dy - s * .015)
      ..lineTo(p.dx - dir * s * .62, p.dy - s * .06)
      ..lineTo(p.dx - dir * s * .3, p.dy + s * .01)
      ..lineTo(p.dx - dir * s * .6, p.dy + s * .075)
      ..lineTo(p.dx - dir * s * .08, p.dy + s * .03)
      ..close();
    final body = Path()
      ..addOval(Rect.fromCenter(center: p + Offset(dir * s * .04, s * .01), width: s * .36, height: s * .09))
      ..moveTo(p.dx + dir * s * .2, p.dy)
      ..lineTo(p.dx + dir * s * .34, p.dy + s * .04)
      ..lineTo(p.dx + dir * s * .2, p.dy + s * .03)
      ..close();
    const ink = Color(0xff1e2a38);
    c.drawPath(wings, _sunnyFill(ink, alpha));
    c.drawPath(tail, _sunnyFill(ink, alpha));
    c.drawPath(body, _sunnyFill(ink, alpha));
  }

  /// Gulls in a loose V, frigatebirds soaring high and a small flock of
  /// scarlet ibis crossing the bay far away.
  static void _sunnyBirds(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final span = w + h * 1.6;
    final lead = Offset(_sunnyCross(t, w * .6, span, h * .8, 132, -1), h * .3 + math.sin(t * .22) * h * .012);
    const flock = [(0.0, 0.0, .022), (.06, .026, .019), (.06, -.024, .018), (.125, .055, .016), (.13, -.05, .015)];
    for (final (i, (dx, dy, size)) in flock.indexed) {
      final bob = math.sin(t * .8 + i * 1.7) * h * .004;
      _sunnyGull(c, lead + Offset(dx * h, dy * h + bob), h * size, _sunnyFlap(t, i.toDouble()), -1, presence);
    }
    // A lone gull far off, lower and smaller.
    _sunnyGull(
      c,
      Offset(_sunnyCross(t, w * .4, span, h * .8, 66, -1), h * .44 + math.sin(t * .27 + 2) * h * .01),
      h * .012,
      _sunnyFlap(t, 7),
      -1,
      presence * .85,
    );
    for (final (i, (fx, fy, size)) in const [(.1, .215, .03), (.72, .125, .024)].indexed) {
      final x = _sunnyCross(t, w * fx, span, h * .8, 132, 1);
      _sunnyFrigate(c, Offset(x, h * fy + math.sin(t * .18 + i * 2) * h * .008), h * size, .05 + .06 * math.sin(t * .4 + i), 1, presence * .85);
    }
    _sunnyIbis(c, f, presence);
  }

  /// Scarlet ibis in a V, tiny and hazy with distance.
  static void _sunnyIbis(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final span = w + h * 1.6;
    final lead = Offset(_sunnyCross(t, w * .7, span, h * .8, 66, -1), h * .52 + math.sin(t * .2) * h * .006);
    final wings = Path();
    for (var i = 0; i < 7; i++) {
      final rank = (i + 1) ~/ 2, side = i.isOdd ? 1.0 : -1.0;
      final p = lead + Offset(rank * h * .02, side * rank * h * .012);
      final s = h * .0095;
      final lift = s * (.25 + .5 * math.sin(t * 5.5 + i * .9));
      wings
        ..moveTo(p.dx - s, p.dy - lift)
        ..quadraticBezierTo(p.dx - s * .4, p.dy - lift * .3, p.dx, p.dy)
        ..quadraticBezierTo(p.dx + s * .4, p.dy - lift * .3, p.dx + s, p.dy - lift);
    }
    c.drawPath(wings, _sunnyLine(_hazed(const Color(0xffe8504a), .2), .85 * presence, math.max(.9, h * .0028)));
  }

  /// A little high-wing plane towing an advertising banner, far and hazy.
  static void _sunnyPlane(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    final span = w + h * 1.6;
    final x = _sunnyCross(t, w * .32, span, h * .8, 132, 1);
    final y = h * .135 + math.sin(t * .21) * h * .005;
    final l = h * .046;
    final a = presence;
    Color hz(Color c0) => _hazed(c0, .08);
    c.save();
    c.translate(x, y);
    c.rotate(math.sin(t * .21 + 1) * .02 - .01);
    // Banner: cream cloth streaming from a tow line, lettered in blocks.
    final bx = -l * .62, bl = l * 2.5, bh = l * .34;
    double wave(double u) => math.sin(u * 5.5 - t * 2.6) * l * .06 * (.25 + .75 * u);
    c.drawLine(Offset(-l * .5, -l * .012), Offset(bx, wave(0) - bh * .3), _sunnyLine(const Color(0xff53606c), .7 * a, math.max(.5, l * .012)));
    final cloth = Path()..moveTo(bx, wave(0) - bh * .5);
    const segs = 10;
    for (var i = 1; i <= segs; i++) {
      final u = i / segs;
      cloth.lineTo(bx - bl * u, wave(u) - bh * .5);
    }
    for (var i = segs; i >= 0; i--) {
      final u = i / segs;
      cloth.lineTo(bx - bl * u, wave(u) + bh * .5);
    }
    c.drawPath(cloth..close(), _sunnyFill(const Color(0xfffff8ea), a));
    final letters = Path();
    for (var i = 0; i < 9; i++) {
      final u = (i + .6) / (segs - .4);
      final top = -bh * (.28 - .12 * Sketch.hash(1400 + i));
      letters.addRect(Rect.fromLTWH(bx - bl * u - l * .05, wave(u) + top, l * .1, -top + bh * .22 * Sketch.hash(1410 + i)));
    }
    c.drawPath(letters, _sunnyFill(const Color(0xff2f8f5a), .8 * a));
    final edge = Path()..moveTo(bx, wave(0) - bh * .5);
    for (var i = 1; i <= segs; i++) {
      edge.lineTo(bx - bl * i / segs, wave(i / segs) - bh * .5);
    }
    edge.moveTo(bx, wave(0) + bh * .5);
    for (var i = 1; i <= segs; i++) {
      edge.lineTo(bx - bl * i / segs, wave(i / segs) + bh * .5);
    }
    c.drawPath(edge, _sunnyLine(const Color(0xff5a7a98), .55 * a, math.max(.4, l * .01)));
    // Plane, nose to the right.
    final body = Path()
      ..moveTo(l * .5, -l * .01)
      ..quadraticBezierTo(l * .5, -l * .06, l * .38, -l * .07)
      ..lineTo(l * .12, -l * .095)
      ..lineTo(-l * .12, -l * .085)
      ..lineTo(-l * .5, -l * .035)
      ..lineTo(-l * .5, l * .005)
      ..lineTo(-l * .1, l * .06)
      ..lineTo(l * .34, l * .06)
      ..quadraticBezierTo(l * .5, l * .05, l * .5, -l * .01)
      ..close();
    c.drawPath(body, _sunnyFill(hz(const Color(0xfffdfdfb)), a));
    c.drawPath(
      Sketch.poly([l * .46, -l * .03, l * .4, -l * .015, -l * .5, l * .0, -l * .5, -l * .02]),
      _sunnyFill(const Color(0xffe0455a), a),
    );
    c.drawPath(Sketch.poly([l * .15, -l * .085, l * -.06, -l * .085, l * -.07, -l * .045, l * .17, -l * .045]), _sunnyFill(const Color(0xff4a78a8), .85 * a));
    c.drawPath(Sketch.poly([-l * .34, -l * .075, -l * .5, -l * .165, -l * .5, -l * .035]), _sunnyFill(const Color(0xffe0455a), a));
    c.drawPath(Sketch.poly([l * .24, -l * .112, l * -.08, -l * .112, l * -.14, -l * .142, l * .18, -l * .142]), _sunnyFill(hz(const Color(0xffe8eef4)), a));
    c.drawLine(Offset(l * .04, -l * .112), Offset(l * .1, -l * .075), _sunnyLine(const Color(0xff9fb0c0), .8 * a, math.max(.4, l * .008)));
    c.drawOval(Rect.fromCenter(center: Offset(l * .515, -l * .005), width: l * .022, height: l * .16), _sunnyFill(const Color(0xff5a6a7a), .32 * a));
    c.drawLine(Offset(l * .2, l * .055), Offset(l * .2, l * .09), _sunnyLine(const Color(0xff3a4550), .8 * a, math.max(.4, l * .012)));
    c.drawCircle(Offset(l * .2, l * .095), l * .02, _sunnyFill(const Color(0xff2a3038), a));
    c.restore();
  }

  /// Two paragliders loitering on a thermal, canopies banking with each turn.
  static void _sunnyParagliders(Canvas c, SceneFrame f, double presence) {
    final w = f.w, h = f.h, t = f.clock;
    for (final (i, (fx, fy, ax, ay, rate, u, cell, alt)) in const [
      (.2, .37, .035, .012, 2, .034, Color(0xffe8407a), Color(0xfffff3f6)),
      (.66, .27, .03, .01, 3, .027, Color(0xff2a9fd8), Color(0xffeafaff)),
    ].indexed) {
      // Loops of 66 s and 44 s, so the sky matches at every visit.
      final ph = t * rate * math.pi / 66 + i * 2.2;
      final p = Offset(w * fx + math.sin(ph) * w * ax, h * fy + math.cos(ph * 2) * h * ay);
      _sunnyParaglider(c, p, h * u, math.cos(ph) * .2, cell, alt, presence);
    }
  }

  /// A paraglider: an arched canopy of cells, a fan of lines and a pilot in
  /// a harness, swinging [bank] radians about the pilot.
  static void _sunnyParaglider(Canvas c, Offset pilot, double u, double bank, Color cell, Color alt, double alpha) {
    c.save();
    c.translate(pilot.dx, pilot.dy);
    c.rotate(bank);
    Offset top(double t) {
      final x = -1 + 2 * t, arch = 1 - x * x;
      return Offset(x * u, (-1.05 - .26 * arch + .22 * x * x) * u);
    }

    Offset bottom(double t) {
      final x = -1 + 2 * t, arch = 1 - x * x;
      return Offset(x * u * .98, (-1.05 - .04 * arch + .22 * x * x) * u + u * .03);
    }

    const cells = 9;
    final canopy = Path()..moveTo(top(0).dx, top(0).dy);
    for (var i = 1; i <= cells; i++) {
      canopy.lineTo(top(i / cells).dx, top(i / cells).dy);
    }
    for (var i = cells; i >= 0; i--) {
      canopy.lineTo(bottom(i / cells).dx, bottom(i / cells).dy);
    }
    canopy.close();
    // Suspension lines first, so the canopy overlaps their tops.
    final lines = Path();
    for (var i = 0; i <= 4; i++) {
      final b = bottom(i / 4);
      lines
        ..moveTo(b.dx, b.dy)
        ..lineTo(0, -u * .07);
    }
    c.drawPath(lines, _sunnyLine(const Color(0xff3a4a5a), .55 * alpha, math.max(.4, u * .012)));
    c.drawPath(canopy, _sunnyFill(alt, alpha));
    final shaded = Path();
    for (var i = 0; i < cells; i += 2) {
      final a = i / cells, b = (i + 1) / cells;
      shaded
        ..moveTo(top(a).dx, top(a).dy)
        ..lineTo(top(b).dx, top(b).dy)
        ..lineTo(bottom(b).dx, bottom(b).dy)
        ..lineTo(bottom(a).dx, bottom(a).dy)
        ..close();
    }
    c.drawPath(shaded, _sunnyFill(cell, alpha));
    c.drawPath(
      Path()
        ..moveTo(bottom(0).dx, bottom(0).dy)
        ..quadraticBezierTo(0, -u * 1.09, bottom(1).dx, bottom(1).dy),
      _sunnyLine(const Color(0xff26303a), .3 * alpha, math.max(.4, u * .015)),
    );
    // The pilot sits back in the harness under the lines.
    c.drawOval(Rect.fromCenter(center: Offset(0, u * .02), width: u * .13, height: u * .26), _sunnyFill(const Color(0xff33404e), alpha));
    c.drawCircle(Offset(0, -u * .14), u * .055, _sunnyFill(const Color(0xffe8d9c6), alpha));
    c.restore();
  }

  /// A hang glider drifts down the coast: a delta sail of striped panels on
  /// dark leading-edge tubes and a keel, the pilot slung beneath.
  static void _hangGlider(Canvas c, double w, double h, double clock, double presence) {
    final u = h * .05;
    final span = w + h * 1.4;
    final gx = _sunnyCross(clock, w * .5, span, h * .7, 132, -1);
    final gy = h * .25 + math.sin(clock * .3) * h * .012;
    final turn = math.sin(clock * .27 + .8);
    c.save();
    c.translate(gx, gy);
    c.rotate(turn * .1);
    c.scale(.94 + .06 * math.cos(clock * .27 + .8), 1);
    Offset o(double x, double y) => Offset(x * u, y * u);
    final nose = o(0, -.52), tail = o(0, .1);
    Offset trail(double side, double t) {
      // Point along the trailing edge, tip (0) to centre (1).
      final a = o(side, .2), b = o(side * .55, -.06);
      return a * ((1 - t) * (1 - t)) + b * (2 * t * (1 - t)) + tail * (t * t);
    }

    for (final (side, base, stripe) in const [(-1.0, Color(0xffe8405e), Color(0xfffff4ea)), (1.0, Color(0xfffff4ea), Color(0xffe8405e))]) {
      c.drawPath(
        Path()
          ..moveTo(nose.dx, nose.dy)
          ..lineTo(side * u, .2 * u)
          ..quadraticBezierTo(side * .55 * u, -.06 * u, tail.dx, tail.dy)
          ..close(),
        Paint()..color = Sketch.fade(base, presence),
      );
      final stripes = Path();
      for (final (a, b) in const [(.16, .3), (.5, .64)]) {
        stripes
          ..moveTo(nose.dx, nose.dy)
          ..lineTo(trail(side, a).dx, trail(side, a).dy)
          ..lineTo(trail(side, b).dx, trail(side, b).dy)
          ..close();
      }
      c.drawPath(stripes, Paint()..color = Sketch.fade(stripe, presence));
    }
    final tube = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Sketch.fade(const Color(0xff36424f), presence)
      ..strokeWidth = math.max(.8, u * .05);
    c.drawPath(Path()..moveTo(-u, .2 * u)..lineTo(nose.dx, nose.dy)..lineTo(u, .2 * u), tube);
    c.drawLine(nose, tail, tube..strokeWidth = math.max(.6, u * .028)..color = Sketch.fade(const Color(0xff36424f), .6 * presence));
    // Pilot in a harness hanging from the keel, helmet up.
    c.drawLine(o(0, .1), o(0, .3), tube..strokeWidth = math.max(.5, u * .02));
    c.drawPath(
      Path()
        ..moveTo(-u * .06, u * .34)
        ..lineTo(u * .06, u * .34)
        ..lineTo(u * .05, u * .56)
        ..lineTo(u * .025, u * .74)
        ..lineTo(-u * .01, u * .74)
        ..lineTo(-u * .05, u * .56)
        ..close(),
      Paint()..color = Sketch.fade(_navy, presence),
    );
    c.drawCircle(o(0, .3), u * .055, Paint()..color = Sketch.fade(const Color(0xffe8405e), presence));
    c.restore();
  }

  /// The Serra do Mar: a haze-blue ridge behind the famous peaks. It runs
  /// well past the right edge so the slow drift never uncovers a gap.
  static void _serra(Canvas c, double w, double h) {
    final end = w + h * .9;
    final floor = h * .72;
    // Farthest range: pale rock carrying the Pico da Tijuca, the Dois Irmaos
    // twins and the great block of the Pedra da Gavea.
    double range(double x) {
      final roll = .014 * math.sin(x / h * 1.9 + .4) + .009 * math.sin(x / h * 5.3 + 1.1);
      return h * (.56 - roll) -
          _peakBump(x, w * .085, h * .22, h * .26, h * .06, 1.1) -
          _peakBump(x, w * .44, h * .2, h * .24, h * .035, .7) -
          _peakBump(x, w * .585, h * .085, h * .07, h * .075, .9) -
          _peakBump(x, w * .585 + h * .17, h * .07, h * .09, h * .05, .8) -
          _peakBump(x, w * .93, h * .08, h * .24, h * .125, .4);
    }

    c.drawPath(
      _peakRidgePath(-h * .2, end, h * .012, range, floor),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, h * .42),
          Offset(0, h * .68),
          [_hazed(const Color(0xff86aeb4), .58), _hazed(const Color(0xff86aeb4), .86)],
        ),
    );
    // The sun is to the right: each summit is shaded softly on its left.
    for (final (cx, reach) in [(w * .085, h * .24), (w * .585, h * .12), (w * .585 + h * .17, h * .1), (w * .93, h * .12)]) {
      final path = Path()..moveTo(cx - reach, floor);
      for (var x = cx - reach; x < cx + reach * .6; x += h * .012) {
        path.lineTo(x, range(x));
      }
      c.drawPath(
        path
          ..lineTo(cx + reach * .6, floor)
          ..close(),
        Paint()
          ..shader = Gradient.linear(
            Offset(cx - reach, 0),
            Offset(cx + reach * .6, 0),
            [Sketch.fade(_hazed(_peakGraniteDeep, .5), 0), Sketch.fade(_hazed(_peakGraniteDeep, .5), .3), Sketch.fade(_hazed(_peakGraniteDeep, .5), .15), Sketch.fade(_hazed(_peakGraniteDeep, .5), 0)],
            const [0, .28, .62, 1],
          ),
      );
    }
    // Sheer streaks down the Gavea's great left face.
    final face = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, h * .0025)
      ..color = Sketch.fade(_hazed(_peakGraniteDeep, .5), .26);
    for (var i = 0; i < 6; i++) {
      final x = w * .93 - h * (.072 - .02 * i + .008 * Sketch.hash(880 + i));
      c.drawLine(Offset(x, range(x) + h * .012), Offset(x + h * .004, range(x) + h * (.04 + .03 * Sketch.hash(890 + i))), face);
    }
    // Two ranks of forested ridge, nearer and darker.
    _peakForestRidge(
      c,
      h,
      -h * .2,
      end,
      (x) => h * (.592 - .012 * math.sin(x / h * 2.3 + 2.0) - .008 * math.sin(x / h * 6.1 + .4)) - _peakBump(x, w * .7, h * .35, h * .45, h * .03, .7) - _peakBump(x, w * .2, h * .3, h * .3, h * .025, .7),
      top: _hazed(const Color(0xff5c9a88), .5),
      bottom: _hazed(const Color(0xff5c9a88), .78),
      dark: _hazed(const Color(0xff4a8c74), .46),
      lit: _hazed(const Color(0xff66aa88), .42),
      crown: .0085,
      seed: 900,
    );
    _peakForestRidge(
      c,
      h,
      -h * .2,
      end,
      (x) => h * (.63 - .009 * math.sin(x / h * 3.1 + .7) - .006 * math.sin(x / h * 8 + .2)),
      top: _hazed(const Color(0xff458a6c), .34),
      bottom: _hazed(const Color(0xff458a6c), .6),
      dark: _hazed(const Color(0xff357660), .3),
      lit: _hazed(const Color(0xff58a274), .26),
      crown: .011,
      seed: 1000,
    );
  }

  // ---- peaks: shared helpers ------------------------------------------------

  static const _peakGraniteDeep = Color(0xff5d777d);
  static const _peakLeaf = Color(0xff3f8460);
  static const _peakLeafShade = Color(0xff2a6250);
  static const _peakLeafLit = Color(0xff6cb070);

  /// A smooth curve through [p]: quadratic beziers between midpoints.
  static Path _peakCurve(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 1; i < p.length - 1; i++) {
      final m = Offset.lerp(p[i], p[i + 1], .5)!;
      path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
    }
    return path..lineTo(p.last.dx, p.last.dy);
  }

  /// A smooth closed blob through [p].
  static Path _peakLoop(List<Offset> p) {
    final n = p.length;
    final start = Offset.lerp(p[n - 1], p[0], .5)!;
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final m = Offset.lerp(p[i], p[(i + 1) % n], .5)!;
      path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
    }
    return path..close();
  }

  /// Round dots of diameter [d] at [pts]: any number of crowns in one draw.
  static void _peakDots(Canvas c, List<Offset> pts, double d, Color color) {
    if (pts.isEmpty) return;
    c.drawPoints(
      PointMode.points,
      pts,
      Paint()
        ..color = color
        ..strokeWidth = d
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A rounded bump [ht] high, [left]/[right] wide either side of [cx]; a
  /// small [p] blunts it into a dome, a large one sharpens it to a peak.
  static double _peakBump(double x, double cx, double left, double right, double ht, [double p = .6]) {
    final u = (x - cx).abs() / (x < cx ? left : right);
    return u >= 1 ? 0 : ht * math.pow(1 - u * u, p);
  }

  /// The ground under a skyline given as a function of x.
  static Path _peakRidgePath(double x0, double x1, double step, double Function(double) y, double floor) {
    final path = Path()
      ..moveTo(x0, floor)
      ..lineTo(x0, y(x0));
    for (var x = x0 + step; x < x1; x += step) {
      path.lineTo(x, y(x));
    }
    return path
      ..lineTo(x1, y(x1))
      ..lineTo(x1, floor)
      ..close();
  }

  /// A forested ridge: a hazy fill under a skyline of tiny crowns.
  static void _peakForestRidge(
    Canvas c,
    double h,
    double x0,
    double x1,
    double Function(double) y, {
    required Color top,
    required Color bottom,
    required Color dark,
    required Color lit,
    required double crown,
    required int seed,
  }) {
    c.drawPath(
      _peakRidgePath(x0, x1, h * .015, y, h * .72),
      Paint()..shader = Gradient.linear(Offset(0, h * .5), Offset(0, h * .7), [top, bottom]),
    );
    final r = h * crown;
    final big = <Offset>[], small = <Offset>[], caps = <Offset>[];
    var i = 0;
    for (var x = x0; x < x1; x += r * 1.1) {
      final k = seed + i++;
      final p = Offset(x, y(x) + r * (.15 + .5 * Sketch.hash(k)));
      (Sketch.hash(k + 3000) < .5 ? big : small).add(p);
      if (Sketch.hash(k + 6000) > .3) caps.add(p + Offset(r * .3, -r * .4));
    }
    _peakDots(c, big, r * 2.3, dark);
    _peakDots(c, small, r * 1.7, dark);
    _peakDots(c, caps, r * 1.2, lit);
  }

  /// Scatters tree crowns over [rows] (y, left, right), batched into dots:
  /// shaded ones left of [split], sunlit ones right of it, each with a small
  /// bright cap. [keep] can mask out bare rock.
  static void _peakCanopy(
    Canvas c,
    List<(double, double, double)> rows, {
    required double dot,
    required double grow,
    required double split,
    required Color shade,
    required Color mid,
    required Color lit,
    required int seed,
    bool Function(double x, double y)? keep,
  }) {
    final capShade = Sketch.mix(shade, mid, .55);
    for (final (row, (y, l, r)) in rows.indexed) {
      final d = dot + grow * row, gap = d * .8;
      final dark = <Offset>[], sun = <Offset>[], capsDark = <Offset>[], capsSun = <Offset>[];
      var i = 0;
      for (var x = l + gap * .5; x < r; x += gap) {
        final k = seed + row * 97 + i++;
        final p = Offset(x + gap * .5 * (Sketch.hash(k) - .5), y + d * .3 * (Sketch.hash(k + 5000) - .5));
        if (keep != null && !keep(p.dx, p.dy)) continue;
        final cap = p + Offset(d * .13, -d * .15);
        if (p.dx < split) {
          dark.add(p);
          if (Sketch.hash(k + 9000) > .45) capsDark.add(cap);
        } else {
          sun.add(p);
          if (Sketch.hash(k + 9000) > .25) capsSun.add(cap);
        }
      }
      _peakDots(c, dark, d, shade);
      _peakDots(c, sun, d, mid);
      _peakDots(c, capsDark, d * .55, capShade);
      _peakDots(c, capsSun, d * .55, lit);
    }
  }

  /// Sugarloaf's height, in units of its size.
  static const _peakSugarH = .965;

  /// Half width of Sugarloaf's granite dome at height [t] (0 base to 1
  /// summit) on the left (a < 0) or right, in units of its size. Steeper on
  /// the left, with a rounded shoulder to the right.
  static double _peakSugarHalf(double t, double a) {
    final flare = .03 * math.pow(1 - t, 5);
    return a < 0 ? .375 * math.sqrt(1 - math.pow(t, 3.2)) + flare : .375 * math.sqrt(1 - math.pow(t, 2.4)) + flare;
  }

  /// x of the dome at height [t], across from the left edge (a = -1) to the
  /// right (a = 1). Below [straight] a stain runs plumb instead of following
  /// the dome inward.
  static double _peakSugarX(double t, double a, [double straight = 0]) {
    final e = straight > 0 && t < straight ? straight : t;
    final half = _peakSugarHalf(e, a) * (straight > 0 && t < straight ? .96 : 1);
    return .012 * t + a * half;
  }

  static Path _peakSugarBody(Offset base, double s) {
    Offset at(double t, double a) => Offset(base.dx + s * _peakSugarX(t, a), base.dy - s * _peakSugarH * t);
    const ts = [0.0, .06, .13, .22, .32, .42, .52, .62, .7, .78, .85, .9, .94, .97, .99];
    return _peakCurve([
      Offset(at(0, -1).dx, base.dy + s * .08),
      for (final t in ts) at(t, -1),
      at(1, 0),
      for (final t in ts.reversed) at(t, 1),
      Offset(at(0, 1).dx, base.dy + s * .08),
    ])..close();
  }

  /// A tapered stain running down the dome at across-fraction [a].
  static Path _peakSugarStreak(Offset base, double s, double a, double t0, double t1, double wide) {
    const n = 8;
    final left = <Offset>[], right = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final u = k / n;
      final t = t0 + (t1 - t0) * u;
      final x = base.dx + s * _peakSugarX(t, a, .7), y = base.dy - s * _peakSugarH * t;
      final half = s * wide * .5 * math.sin(math.pi * math.pow(u, .7));
      left.add(Offset(x - half, y));
      right.add(Offset(x + half, y));
    }
    return _peakCurve([...left, ...right.reversed])..close();
  }

  /// A tongue of forest licking up from [from] to [to], tapering as it goes.
  static Path _peakTongue(Offset from, Offset to, double wide, int seed) {
    const n = 7;
    final left = <Offset>[], right = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final u = k / n;
      final p = Offset.lerp(from, to, u)! + Offset(math.sin(u * 5 + seed) * wide * .5, 0);
      final half = wide * (1 - u * .92) * (.7 + .5 * Sketch.hash(seed + k)) * .5;
      left.add(p - Offset(half, 0));
      right.add(p + Offset(half, 0));
    }
    return _peakCurve([...left, ...right.reversed])..close();
  }

  static void _sugarloaf(Canvas c, Offset base, double s) {
    Offset at(double t, double a, [double straight = 0]) => Offset(base.dx + s * _peakSugarX(t, a, straight), base.dy - s * _peakSugarH * t);
    final body = _peakSugarBody(base, s);
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(base.dx - s * .4, 0),
          Offset(base.dx + s * .4, 0),
          [
            for (final k in const [Color(0xffa9c0be), Color(0xff88a3a6), Color(0xff7c989c), Color(0xff8ea8a9), Color(0xffb4c4bb), Color(0xffdde2d0), Color(0xffd9dfcd), Color(0xffc3cdbd)]) _hazed(k, .22),
          ],
          const [0, .06, .2, .42, .58, .74, .9, 1],
        ),
    );
    c.save();
    c.clipPath(body);
    // Dark streaks weep down the granite from the summit, pale ones between.
    final stain = Paint();
    for (var i = 0; i < 13; i++) {
      final a = -.86 + 1.72 * (i + .6 * Sketch.hash(810 + i)) / 13;
      final t0 = .95 - .18 * Sketch.hash(830 + i) - .1 * a.abs();
      final t1 = .24 + .4 * Sketch.hash(850 + i);
      stain.color = Sketch.fade(_hazed(_peakGraniteDeep, .15), a < .05 ? .3 : .38);
      c.drawPath(_peakSugarStreak(base, s, a, t0, t1, .009 + .011 * Sketch.hash(870 + i)), stain);
    }
    stain.color = Sketch.fade(const Color(0xffffffff), .24);
    for (var i = 0; i < 5; i++) {
      final a = -.6 + 1.4 * (i + .4 * Sketch.hash(910 + i)) / 5;
      c.drawPath(_peakSugarStreak(base, s, a, .9 - .1 * Sketch.hash(920 + i), .35 + .3 * Sketch.hash(930 + i), .007), stain);
    }
    // Forest climbs the skirt and licks up the crevices.
    final leafShade = _hazed(_peakLeafShade, .22), leaf = _hazed(_peakLeaf, .22), leafLit = _hazed(_peakLeafLit, .22);
    final forest = Paint()
      ..shader = Gradient.linear(
        Offset(base.dx - s * .4, 0),
        Offset(base.dx + s * .4, 0),
        [leafShade, Sketch.mix(leafShade, leaf, .6), leaf, leafLit],
        const [0, .3, .65, 1],
      );
    final skirt = <Offset>[Offset(base.dx - s * .5, base.dy + s * .05)];
    for (var k = 0; k <= 14; k++) {
      final x = -.5 + 1.0 * k / 14;
      skirt.add(base + Offset(s * x, -s * (.1 + .05 * Sketch.hash(940 + k) + .05 * (x + .4))));
    }
    skirt.add(Offset(base.dx + s * .5, base.dy + s * .05));
    c.drawPath(_peakCurve(skirt)..close(), forest);
    for (final (x, up, wide) in const [(-.27, .3, .07), (-.1, .22, .05), (.1, .38, .07), (.29, .27, .06)]) {
      c.drawPath(_peakTongue(base + Offset(s * x, -s * .12), base + Offset(s * (x + .02), -s * (.12 + up)), s * wide, (x * 100).round()), forest);
    }
    // A dark tree-lined crest down the right shoulder.
    final crest = <Offset>[];
    for (var k = 0; k <= 8; k++) {
      final t = .84 - .04 * k;
      crest.add(at(t, 1.05));
    }
    for (var k = 8; k >= 0; k--) {
      final t = .84 - .04 * k;
      crest.add(at(t, 1 - .12 * math.sin(math.pi * k / 8 * .9 + .2) * (.5 + Sketch.hash(950 + k))));
    }
    c.drawPath(_peakLoop(crest), forest);
    // Crowns dot the forest.
    final dots = <Offset>[], caps = <Offset>[];
    for (var k = 0; k < 46; k++) {
      final x = -.42 + .84 * Sketch.hash(960 + k);
      final y = .09 + .17 * Sketch.hash(1010 + k);
      dots.add(base + Offset(s * x, -s * y));
      caps.add(base + Offset(s * x + s * .006, -s * y - s * .007));
    }
    _peakDots(c, dots, s * .05, Sketch.fade(leafShade, .55));
    _peakDots(c, caps, s * .028, Sketch.fade(leafLit, .5));
    // Haze pools around the foot.
    c.drawRect(
      Rect.fromLTRB(base.dx - s, base.dy - s * .55, base.dx + s, base.dy + s * .1),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, base.dy - s * .55),
          Offset(0, base.dy),
          [Sketch.fade(_haze, 0), Sketch.fade(_haze, .62)],
        ),
    );
    // Rim of sunlight down the right shoulder.
    final rim = Path()..moveTo(at(.99, 1).dx, at(.99, 1).dy);
    for (final t in const [.95, .9, .85, .8, .74, .68, .6, .5]) {
      rim.lineTo(at(t, 1).dx, at(t, 1).dy);
    }
    c.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, s * .009)
        ..color = Sketch.fade(const Color(0xfffff6dc), .5),
    );
    c.restore();
    _peakUrca(c, base, s);
    // Summit station perched on the dome.
    final apex = at(1, 0);
    _peakStation(c, Offset(apex.dx + s * .02, apex.dy + s * .004), s * .11);
    _peakCableLines(c, base, s);
  }

  /// Morro da Urca: the forested shoulder in front, with its station, the
  /// pylon of the first leg and the cable running off into the haze.
  static const _peakUrcaTop = [(.3, .0), (.4, .1), (.5, .19), (.62, .275), (.74, .335), (.86, .365), (.95, .374), (1.05, .365), (1.16, .325), (1.28, .255), (1.4, .165), (1.52, .085), (1.62, .02), (1.7, -.03)];

  static double _peakUrcaY(double x) {
    if (x <= _peakUrcaTop.first.$1) return _peakUrcaTop.first.$2;
    for (var i = 1; i < _peakUrcaTop.length; i++) {
      final (x1, y1) = _peakUrcaTop[i];
      final (x0, y0) = _peakUrcaTop[i - 1];
      if (x <= x1) return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
    }
    return _peakUrcaTop.last.$2;
  }

  static void _peakUrca(Canvas c, Offset base, double s) {
    Offset at(double x, double y) => Offset(base.dx + s * x, base.dy - s * y);
    final leafShade = _hazed(_peakLeafShade, .26), leaf = _hazed(_peakLeaf, .26), leafLit = _hazed(_peakLeafLit, .26);
    // Scalloped crown line along the top, tucked behind the body.
    final edge = <Offset>[], edgeBig = <Offset>[];
    for (var x = .34; x < 1.7; x += .032) {
      (Sketch.hash(1100 + (x * 100).round()) < .5 ? edge : edgeBig).add(at(x, _peakUrcaY(x) - .004));
    }
    _peakDots(c, edge, s * .052, leaf);
    _peakDots(c, edgeBig, s * .07, leaf);
    final body = _peakCurve([
      at(.3, -.08),
      for (final (x, y) in _peakUrcaTop) at(x, y),
      at(1.7, -.08),
    ])..close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          at(.4, 0),
          at(1.6, 0),
          [leafShade, Sketch.mix(leafShade, leaf, .6), leaf, leafLit],
          const [0, .3, .6, 1],
        ),
    );
    // Rows of tree crowns down the slope.
    _peakCanopy(
      c,
      [
        for (var row = 0; row < 5; row++) (base.dy - s * (_peakUrcaY(1.0) - .035 - row * .045), base.dx + s * (.36 + row * .04), base.dx + s * (1.66 - row * .05)),
      ],
      dot: s * .04,
      grow: s * .003,
      split: base.dx + s * .78,
      shade: Sketch.fade(leafShade, .6),
      mid: Sketch.fade(leaf, .7),
      lit: leafLit,
      seed: 1200,
      keep: (x, y) => y > base.dy - s * (_peakUrcaY((x - base.dx) / s) - .01),
    );
    // Haze pooled at the foot.
    c.drawRect(
      Rect.fromLTRB(base.dx + s * .3, base.dy - s * .3, base.dx + s * 1.75, base.dy + s * .1),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, base.dy - s * .3),
          Offset(0, base.dy),
          [Sketch.fade(_haze, 0), Sketch.fade(_haze, .6)],
        ),
    );
    // Station on the summit, and the pylon of the first leg on its shoulder.
    _peakStation(c, at(.94, .372), s * .16);
    final tower = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.6, s * .006)
      ..color = _hazed(const Color(0xff3f5a5a), .3);
    final foot = at(.66, .302), crown = at(.66, .385);
    c.drawLine(foot + Offset(-s * .022, 0), crown + Offset(-s * .004, 0), tower);
    c.drawLine(foot + Offset(s * .022, 0), crown + Offset(s * .004, 0), tower);
    for (final k in const [.3, .6]) {
      final y = foot.dy + (crown.dy - foot.dy) * k, half = s * (.022 - .018 * k);
      c.drawLine(Offset(foot.dx - half, y), Offset(foot.dx + half, y), tower);
    }
    c.drawLine(
      at(.86, .418),
      at(-.06, .1),
      Paint()
        ..strokeWidth = math.max(.6, s * .004)
        ..shader = Gradient.linear(at(.86, .418), at(-.06, .1), [_hazed(const Color(0xff3f5a5a), .3), Sketch.fade(_hazed(const Color(0xff3f5a5a), .5), 0)]),
    );
  }

  /// A small station building: a cream box, glass band and a slab roof.
  static void _peakStation(Canvas c, Offset at, double w) {
    final hgt = w * .34;
    c.drawRect(Rect.fromLTRB(at.dx - w * .5, at.dy - hgt, at.dx + w * .5, at.dy), Paint()..color = _hazed(const Color(0xfff2e9d8), .2));
    c.drawRect(Rect.fromLTRB(at.dx - w * .5, at.dy - hgt * .72, at.dx + w * .5, at.dy - hgt * .38), Paint()..color = _hazed(const Color(0xff4c6f7a), .25));
    c.drawRect(Rect.fromLTRB(at.dx - w * .58, at.dy - hgt * 1.16, at.dx + w * .58, at.dy - hgt), Paint()..color = _hazed(const Color(0xffb8574a), .25));
    c.drawLine(
      at + Offset(w * .3, -hgt * 1.16),
      at + Offset(w * .3, -hgt * 1.9),
      Paint()
        ..strokeWidth = math.max(.6, w * .04)
        ..color = _hazed(const Color(0xff3f5a5a), .3),
    );
  }

  /// Both cables of the span, sagging a little under their own weight.
  static void _peakCableLines(Canvas c, Offset base, double s) {
    final (from, to) = _cable(base, s);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, s * .004)
      ..color = _hazed(const Color(0xff3f5a5a), .3);
    for (final (dy, sag) in const [(0.0, .08), (.014, .075)]) {
      c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy + s * dy)
          ..quadraticBezierTo((from.dx + to.dx) / 2, (from.dy + to.dy) / 2 + s * (sag + dy), to.dx, to.dy + s * dy),
        line,
      );
    }
  }

  /// A point on the span at [u] (0 summit, 1 Urca), following the sag.
  static Offset _peakCableAt(Offset from, Offset to, double u, double s) =>
      Offset.lerp(from, to, u)! + Offset(0, s * .16 * u * (1 - u) + s * .007);

  static void _gondola(Canvas c, Offset at, double s) {
    final w = s * .06, hgt = s * .042;
    final body = Rect.fromLTRB(at.dx - w / 2, at.dy + s * .018, at.dx + w / 2, at.dy + s * .018 + hgt);
    c.drawLine(
      at,
      at + Offset(0, s * .02),
      Paint()
        ..color = _hazed(const Color(0xff3f5a5a), .3)
        ..strokeWidth = math.max(.6, s * .005),
    );
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(s * .008)), Paint()..color = _hazed(const Color(0xfff6f0e4), .16));
    c.drawRect(Rect.fromLTRB(body.left + w * .1, body.top + hgt * .3, body.right - w * .1, body.top + hgt * .68), Paint()..color = _hazed(const Color(0xff5aa5c4), .2));
    c.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTRB(body.left - w * .04, body.top, body.right + w * .04, body.top + hgt * .24), topLeft: Radius.circular(s * .008), topRight: Radius.circular(s * .008)),
      Paint()..color = _hazed(const Color(0xffe94f4a), .16),
    );
  }

  /// The Corcovado's profile as (height, x) pairs in units of its size, and
  /// the ragged line above which the granite is bare, as (x, height) pairs.
  static const _peakCorcoL = [(-.06, -.7), (0.0, -.66), (.04, -.56), (.09, -.45), (.16, -.35), (.25, -.265), (.35, -.2), (.45, -.15), (.54, -.11), (.61, -.088), (.66, -.07), (.69, -.052), (.706, -.035)];
  static const _peakCorcoR = [(-.06, .76), (0.0, .72), (.04, .62), (.09, .53), (.16, .44), (.25, .35), (.35, .265), (.45, .195), (.54, .14), (.61, .108), (.66, .085), (.69, .062), (.706, .045)];
  static const _peakCorcoTrees = [(-.7, .3), (-.3, .5), (-.19, .55), (-.12, .56), (-.07, .5), (-.03, .43), (.02, .4), (.07, .43), (.12, .5), (.17, .54), (.24, .5), (.34, .4), (.46, .28), (.62, .17), (.85, .05)];

  static double _peakEdgeX(List<(double, double)> e, double y) {
    for (var i = 1; i < e.length; i++) {
      final (y1, x1) = e[i];
      final (y0, x0) = e[i - 1];
      if (y <= y1) return x0 + (x1 - x0) * (y - y0) / (y1 - y0);
    }
    return e.last.$2;
  }

  static double _peakTreesY(double x) {
    for (var i = 1; i < _peakCorcoTrees.length; i++) {
      final (x1, y1) = _peakCorcoTrees[i];
      final (x0, y0) = _peakCorcoTrees[i - 1];
      if (x <= x1) return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
    }
    return _peakCorcoTrees.last.$2;
  }

  /// The Corcovado: a steep granite dome in Atlantic forest.
  static void _corcovado(Canvas c, Offset base, double s) {
    Offset at(double y, double x) => Offset(base.dx + s * x, base.dy - s * y);
    final leafShade = _hazed(_peakLeafShade, .3), leaf = _hazed(_peakLeaf, .3), leafLit = _hazed(_peakLeafLit, .3);
    // Crowns scalloping the skyline of the forested flanks, tucked behind.
    final bumpsL = <Offset>[], bumpsR = <Offset>[];
    for (var y = .02; y < .42; y += .022) {
      bumpsL.add(at(y, _peakEdgeX(_peakCorcoL, y) + .004));
      bumpsR.add(at(y, _peakEdgeX(_peakCorcoR, y) - .004));
    }
    _peakDots(c, bumpsL, s * .05, leafShade);
    _peakDots(c, bumpsR, s * .05, leaf);
    final body = _peakCurve([for (final (y, x) in _peakCorcoL) at(y, x), for (final (y, x) in _peakCorcoR.reversed) at(y, x)])..close();
    // Bare granite first: pale and sunlit on the right, blue-grey on the left.
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          at(0, -.3),
          at(0, .3),
          [_hazed(const Color(0xff8fa8a8), .3), _hazed(const Color(0xff9fb5b0), .28), _hazed(const Color(0xffcdd6c8), .26), _hazed(const Color(0xffe2e4d2), .26)],
          const [0, .42, .68, 1],
        ),
    );
    c.save();
    c.clipPath(body);
    final stain = Paint()..color = Sketch.fade(_hazed(_peakGraniteDeep, .15), .3);
    for (var i = 0; i < 9; i++) {
      final x = -.13 + .26 * (i + .3 * Sketch.hash(1800 + i)) / 9;
      final y0 = _peakTreesY(x) + .12 + .12 * Sketch.hash(1810 + i), y1 = _peakTreesY(x) - .01;
      final wide = .006 + .006 * Sketch.hash(1820 + i);
      c.drawPath(Path()..addPolygon([at(y0, x - wide), at(y0 + .02, x + wide), at(y1, x + wide * .5), at(y1, x - wide * .5)], true), stain);
    }
    // Forest below the ragged tree line, in a deeper green on the shaded side.
    final forest = Paint()
      ..shader = Gradient.linear(
        at(0, -.4),
        at(0, .5),
        [leafShade, Sketch.mix(leafShade, leaf, .55), leaf, leafLit],
        const [0, .34, .62, 1],
      );
    final trees = [for (final (x, y) in _peakCorcoTrees) at(y, x)];
    c.drawPath(
      _peakCurve([at(-.1, -.7), ...trees, at(-.1, .85)])..close(),
      forest,
    );
    final ragged = <Offset>[], raggedCaps = <Offset>[];
    for (var x = -.36; x < .56; x += .022) {
      final p = at(_peakTreesY(x) + .004 * math.sin(x * 90), x);
      ragged.add(p);
      if (Sketch.hash(2000 + (x * 100).round()) > .35) raggedCaps.add(p + Offset(s * .004, -s * .006));
    }
    _peakDots(c, ragged, s * .038, Sketch.mix(leafShade, leaf, .45));
    _peakDots(c, raggedCaps, s * .022, leafLit);
    _peakCanopy(
      c,
      [
        for (var row = 0; row < 8; row++) (base.dy - s * (.5 - row * .055), base.dx - s * .8, base.dx + s * .9),
      ],
      dot: s * .036,
      grow: s * .003,
      split: base.dx - s * .02,
      shade: Sketch.fade(leafShade, .7),
      mid: Sketch.fade(leaf, .75),
      lit: leafLit,
      seed: 1600,
      keep: (x, y) {
        final gx = (x - base.dx) / s, gy = (base.dy - y) / s;
        return gy < _peakTreesY(gx) - .02 && gx > _peakEdgeX(_peakCorcoL, gy) + .01 && gx < _peakEdgeX(_peakCorcoR, gy) - .01;
      },
    );
    // Shade plane on the left, soft into the sunlit right.
    c.drawPath(
      _peakCurve([at(.74, -.02), at(.55, -.05), at(.36, -.1), at(.16, -.16), at(-.06, -.24)])
        ..lineTo(at(-.06, -.8).dx, at(-.06, -.8).dy)
        ..lineTo(at(.74, -.8).dx, at(.74, -.8).dy)
        ..close(),
      Paint()
        ..shader = Gradient.linear(
          at(0, -.4),
          at(0, .05),
          [Sketch.fade(_hazed(const Color(0xff1e5652), .2), .5), Sketch.fade(_hazed(const Color(0xff1e5652), .2), .22), Sketch.fade(_hazed(const Color(0xff1e5652), .2), 0)],
          const [0, .6, 1],
        ),
    );
    // Haze pools around the foot.
    c.drawRect(
      Rect.fromLTRB(base.dx - s, base.dy - s * .4, base.dx + s, base.dy + s * .1),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, base.dy - s * .4),
          Offset(0, base.dy),
          [Sketch.fade(_haze, 0), Sketch.fade(_haze, .6)],
        ),
    );
    // Rim of sunlight down the right shoulder.
    final rim = Path()..moveTo(at(.706, .045).dx, at(.706, .045).dy);
    for (final y in const [.66, .61, .54, .45, .35]) {
      rim.lineTo(at(y, _peakEdgeX(_peakCorcoR, y)).dx, at(y, _peakEdgeX(_peakCorcoR, y)).dy);
    }
    c.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.8, s * .008)
        ..color = Sketch.fade(const Color(0xfffff6dc), .5),
    );
    c.restore();
  }

  /// Wisps of cloud snagged on the peaks and haze pooled in the valleys.
  static void _peakMist(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    final (sugar, sugarSize, corco, corcoSize) = _skyline(f.w, h);
    final sway = math.sin(f.clock * .2);
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(sugar.dx + sugarSize * .1 - sway * h * .03, sugar.dy - sugarSize * .78), width: sugarSize * .9, height: sugarSize * .05),
      const Color(0xffffffff),
      .5 * presence,
    );
    Sketch.mist(
      c,
      Rect.fromCenter(center: Offset(corco.dx + sway * h * .04, corco.dy - corcoSize * .3), width: corcoSize * 1.5, height: corcoSize * .06),
      const Color(0xffffffff),
      .45 * presence,
    );
  }

  // ---- The bay: Cagarras islands, a distant ship, far sails, and the water
  // strip in front of the low ridge with its boats, paddlers and swimmers.

  /// Cagarras islands along the 3 h repeat: (x, scale, kind).
  static const _bayIslands = <(double, double, int)>[
    (1.2, .09, 0),
    (1.58, .1, 1),
    (1.9, .065, 2),
    (2.15, .075, 3),
    (2.42, .055, 4),
  ];

  /// Island silhouettes as (x, y) pairs in island units; base is y = .1.
  static const _bayIslandPts = <List<double>>[
    [-1.5, .1, -1.35, -.15, -1.0, -.3, -.6, -.36, -.25, -.28, 0.0, -.36, .45, -.5, .85, -.4, 1.2, -.22, 1.5, .1],
    [-1.15, .1, -1.05, -.2, -.8, -.5, -.5, -.72, -.2, -.82, .1, -.98, .4, -.86, .65, -.6, .95, -.3, 1.15, .1],
    [-.9, .1, -.8, -.3, -.4, -.62, 0.0, -.7, .4, -.6, .8, -.28, .95, .1],
    [-.8, .1, -.6, -.35, -.3, -.8, -.05, -1.02, .2, -.85, .5, -.5, .8, -.2, .95, .1],
    [-1.4, .1, -1.2, -.12, -.7, -.2, 0.0, -.24, .7, -.2, 1.2, -.1, 1.4, .1],
  ];

  /// The water strip's actors: (x, waterline y, kind, size, facing), painted
  /// far to near. Kinds: 0 yacht, 1 trawler, 2 catamaran, 3 jangada,
  /// 4 kite-surfer, 5 surf wave, 6 paddle-boarder, 7 kayak, 8 swimmer.
  static const _bayCast = <(double, double, int, double, double)>[
    (.30, .813, 0, .07, 1.0),
    (1.76, .826, 1, .095, -1.0),
    (2.56, .832, 2, .10, 1.0),
    (.98, .838, 4, .075, 1.0),
    (1.30, .852, 3, .115, -1.0),
    (2.02, .866, 6, .075, 1.0),
    (2.30, .877, 5, .08, 1.0),
    (.66, .886, 7, .06, 1.0),
    (1.66, .885, 8, .05, 1.0),
    (1.92, .879, 8, .05, -1.0),
  ];

  static const _bayNavy = Color(0xff20405f);
  static const _bayGrey = Color(0xffbfd2dd);
  static const _bayWhite = Color(0xfffbfdff);
  static const _baySail = Color(0xfffff9ee);
  static const _baySailShade = Color(0xffe4dac4);
  static const _bayCoral = Color(0xffe8505f);
  static const _baySkin = Color(0xffc98d63);
  static const _bayWood = Color(0xffd3a26b);
  static const _bayWoodDark = Color(0xff8a5a30);
  static const _bayBlue = Color(0xff2f7fa6);

  static final _bayF = Paint();
  static final _bayS = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _bayTint = Paint();
  static final _bayShaders = <double, Shader>{};

  static Color _bayA(Color col, double a) => a >= 1 ? col : Sketch.fade(col, a);

  static void _bayP(Canvas c, double a, List<double> xy, Color col) =>
      c.drawPath(Sketch.poly(xy), _bayF..color = _bayA(col, a));

  static void _bayPath(Canvas c, double a, Path p, Color col) => c.drawPath(p, _bayF..color = _bayA(col, a));

  static void _bayO(Canvas c, double a, double x, double y, double rx, double ry, Color col) =>
      c.drawOval(Rect.fromLTRB(x - rx, y - ry, x + rx, y + ry), _bayF..color = _bayA(col, a));

  static void _bayL(Canvas c, double a, double x0, double y0, double x1, double y1, double w, Color col) =>
      c.drawLine(Offset(x0, y0), Offset(x1, y1), _bayS..strokeWidth = w..color = _bayA(col, a));

  static void _bayC(Canvas c, double a, Path p, double w, Color col) =>
      c.drawPath(p, _bayS..strokeWidth = w..color = _bayA(col, a));

  /// Depth of the bay: hazy far water, deep blue mid-bay, glassy shallows.
  static Shader _bayDepth(double h) => _bayShaders.putIfAbsent(
    h,
    () => Gradient.linear(
      Offset(0, h * .79),
      Offset(0, h * .93),
      const [
        Color(0x00e9fbff),
        Color(0x5ce4f8f4),
        Color(0x30d2f2f0),
        Color(0x0045b8d8),
        Color(0x4a1479a8),
        Color(0x361a8cb8),
        Color(0x627be8d6),
        Color(0x6e8cf0dc),
      ],
      const [0, .07, .14, .29, .5, .68, .82, 1],
    ),
  );

  /// Quadratic trace through the midpoints of the control points [from]..[to];
  /// the current point must already be at [from].
  static void _bayTrace(Path path, List<double> p, int from, int to) {
    for (var i = from + 1; i < to; i++) {
      path.quadraticBezierTo(p[i * 2], p[i * 2 + 1], (p[i * 2] + p[i * 2 + 2]) / 2, (p[i * 2 + 1] + p[i * 2 + 3]) / 2);
    }
    path.lineTo(p[to * 2], p[to * 2 + 1]);
  }

  /// Water closing round a hull spanning [x0]..[x1]: reflection and foam lap.
  static void _bayLap(Canvas c, double a, double x0, double x1, Color tint) {
    final mid = (x0 + x1) / 2, r = (x1 - x0) / 2;
    _bayO(c, a, mid, .07, r * .9, .035, Sketch.fade(tint, .3));
    _bayO(c, a, mid, .004, r * 1.04, .022, const Color(0xb8ffffff));
    _bayO(c, a, mid + r * .1, .1, r * .5, .01, const Color(0x50ffffff));
  }

  /// Distant sailboat riding the far edge of the water, in haze.
  static void _sailboat(Canvas c, double s, Color hull, Color sail) {
    c.drawPath(
      Sketch.poly([-s * .5, -s * .12, s * .5, -s * .14, s * .34, s * .08, -s * .34, s * .08]),
      Paint()..color = _hazed(hull, .2),
    );
    c.drawPath(
      Path()
        ..moveTo(s * .02, -s * 1.0)
        ..quadraticBezierTo(s * .5, -s * .5, s * .44, -s * .16)
        ..lineTo(s * .02, -s * .16)
        ..close(),
      Paint()..color = _hazed(sail, .16),
    );
    c.drawPath(
      Sketch.poly([-s * .04, -s * .86, -s * .38, -s * .17, -s * .04, -s * .17]),
      Paint()..color = _hazed(Sketch.mix(sail, const Color(0xff9fd4ea), .5), .2),
    );
  }

  /// An ocean-going container ship far out on the horizon.
  static void _bayShip(Canvas c, Offset base, double len) {
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(len, len);
    final hull = _hazed(const Color(0xff34475b), .3);
    c.drawPath(Sketch.poly([-.5, -.05, .5, -.062, .46, .02, -.49, .02]), Paint()..color = hull);
    c.drawPath(
      Sketch.poly([-.5, -.05, .5, -.062, .5, -.052, -.5, -.04]),
      Paint()..color = _hazed(const Color(0xffcfd8de), .3),
    );
    const cols = [Color(0xffd84a4a), Color(0xff2f9aa8), Color(0xfff2ead2), Color(0xffc08a3a), Color(0xff3c66b8), Color(0xffa8412f)];
    final box = Paint();
    for (var row = 0; row < 3; row++) {
      for (var i = 0; i < 12; i++) {
        if (row == 2 && (i < 2 || i > 8)) continue;
        final seed = 610 + row * 20 + i;
        box.color = _hazed(cols[(Sketch.hash(seed) * cols.length).floor()], .32);
        final x = -.3 + i * .058;
        c.drawRect(Rect.fromLTWH(x, -.062 - .032 * (row + 1), .052, .03), box);
      }
    }
    // Bridge tower and funnel at the stern.
    c.drawRect(Rect.fromLTRB(-.47, -.17, -.37, -.05), Paint()..color = _hazed(const Color(0xfff2f4f2), .28));
    c.drawRect(Rect.fromLTRB(-.48, -.185, -.36, -.17), Paint()..color = _hazed(const Color(0xff4a5a6a), .3));
    c.drawRect(Rect.fromLTRB(-.46, -.15, -.38, -.14), Paint()..color = _hazed(const Color(0xff2a3a4a), .3));
    c.drawRect(Rect.fromLTRB(-.43, -.215, -.4, -.185), Paint()..color = _hazed(const Color(0xffc84a3a), .3));
    c.restore();
  }

  /// One of the Cagarras: granite under an Atlantic-forest cap, lit from the
  /// sun's side (right).
  static void _island(Canvas c, Offset base, double s, int kind) {
    final p = _bayIslandPts[kind];
    final n = p.length ~/ 2;
    var peak = 1;
    for (var i = 1; i < n - 1; i++) {
      if (p[i * 2 + 1] < p[peak * 2 + 1]) peak = i;
    }
    final px = p[peak * 2], py = p[peak * 2 + 1];
    final fill = Paint();
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(s, s);
    final body = Path()..moveTo(p[0], p[1]);
    _bayTrace(body, p, 0, n - 1);
    c.drawPath(body..close(), fill..color = _hazed(const Color(0xff9a9488), .1));
    final shade = Path()..moveTo(p[0], p[1]);
    _bayTrace(shade, p, 0, peak);
    shade.quadraticBezierTo(px + .2, py + .55 * (.1 - py), px - .1, .1);
    c.drawPath(shade..close(), fill..color = _hazed(const Color(0xff625e58), .1));
    final lx = p[n * 2 - 2];
    final rim = Path()..moveTo(px, py);
    _bayTrace(rim, p, peak, n - 1);
    rim.quadraticBezierTo(px + .55 * (lx - px), py + .8 * (.1 - py), px + .03, py + .1);
    c.drawPath(rim..close(), fill..color = _hazed(const Color(0xffd4cdb8), .1).withValues(alpha: .7));
    if (kind == 1 || kind == 3) {
      // Sheer granite faces streaked by rain.
      final streak = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .022
        ..color = _hazed(const Color(0xff4a4640), .1).withValues(alpha: .5);
      for (var j = 0; j < 4; j++) {
        final x = px - .32 + .24 * j + .05 * Sketch.hash(kind * 9 + j);
        c.drawLine(Offset(x, py + .38 + .05 * j), Offset(x + .03, .06), streak);
      }
    }
    // Forest cap: a band following the crest, scalloped with tree crowns.
    final leaf = _hazed(const Color(0xff25683f), .1), leafLit = _hazed(const Color(0xff58b060), .1);
    final cap = Path()..moveTo(p[2], p[3]);
    _bayTrace(cap, p, 1, n - 2);
    for (var i = n - 2; i >= 1; i--) {
      cap.lineTo(p[i * 2], p[i * 2 + 1] + .16 + .2 * Sketch.hash(kind * 40 + i));
    }
    c.drawPath(cap..close(), fill..color = leaf);
    for (var i = 1; i < n - 1; i++) {
      final qx = .125 * p[i * 2 - 2] + .75 * p[i * 2] + .125 * p[i * 2 + 2];
      final qy = .125 * p[i * 2 - 1] + .75 * p[i * 2 + 1] + .125 * p[i * 2 + 3];
      final mx = (p[i * 2] + p[i * 2 + 2]) / 2, my = (p[i * 2 + 1] + p[i * 2 + 3]) / 2;
      var k = 0;
      for (final (x, y) in [(qx, qy), (mx, my)]) {
        k++;
        if (y > -.06) continue;
        final r = .085 + .06 * Sketch.hash(kind * 70 + i * 2 + k);
        c.drawCircle(Offset(x, y + r * .45), r, fill..color = leaf);
        if (x > px - .3) c.drawCircle(Offset(x + r * .25, y + r * .1), r * .6, fill..color = leafLit);
      }
    }
    if (kind == 4) {
      // Ilha Rasa's lighthouse.
      c.drawRect(Rect.fromLTRB(.1, -.62, .2, -.22), fill..color = _hazed(const Color(0xfff6f6ee), .15));
      c.drawRect(Rect.fromLTRB(.1, -.5, .2, -.42), fill..color = _hazed(const Color(0xffd84a4a), .15));
      c.drawRect(Rect.fromLTRB(.09, -.68, .21, -.62), fill..color = _hazed(const Color(0xff3a4a58), .15));
      c.drawRect(Rect.fromLTRB(.115, -.72, .185, -.68), fill..color = _hazed(const Color(0xfffff2b0), .15));
    }
    c.restore();
  }

  void _bayFeatures(Canvas c, double h) {
    for (final (fx, s, kind) in _bayIslands) {
      _island(c, Offset(h * fx, ridge(Depth.low, fx, 0) * h + h * .012), h * s, kind);
    }
    _bayShip(c, Offset(h * .78, ridge(Depth.low, .78, 0) * h + h * .004), h * .26);
  }

  /// Three far sails tilt on the swell at the water's far edge.
  void _bayLive(Canvas c, SceneFrame f) {
    final h = f.h;
    for (final (fx, s, hull, sail) in const [
      (.55, .04, _bayCoral, _cream),
      (1.02, .05, Color(0xff2f5fd0), _cream),
      (2.78, .035, _cream, Color(0xfff2e6c8)),
    ]) {
      final y = ridge(Depth.low, fx, f.clock) * h + h * .004;
      final slope = (ridge(Depth.low, fx + .02, f.clock) - ridge(Depth.low, fx - .02, f.clock)) / .04;
      c.save();
      c.translate(h * fx, y);
      c.rotate(math.atan(slope));
      _sailboat(c, h * s, hull, sail);
      c.restore();
    }
  }

  /// The strip of bay in front of the low ridge: depth tint, drifting
  /// ripples, foam round the islands and every boat and swimmer.
  void _bayOverlay(Canvas c, SceneFrame f, double a) {
    if (a <= .01) return;
    final h = f.h, t = f.clock, span = period(Depth.low) * h;
    final view = c.getLocalClipBounds().inflate(h * .35);
    _bayTint
      ..shader = _bayDepth(h)
      ..color = Color.fromRGBO(0, 0, 0, a);
    c.drawRect(Rect.fromLTRB(0, h * .79, span, h * .935), _bayTint);
    // Surf collars and shadows where the islands meet the water.
    for (final (fx, s, kind) in _bayIslands) {
      final x = h * fx, half = -_bayIslandPts[kind][0] * s * h;
      if (x + half < view.left || x - half > view.right) continue;
      final y = ridge(Depth.low, fx, t) * h;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y + h * .014), width: half * 1.9, height: h * .016),
        _bayF..color = Color.fromRGBO(20, 110, 150, .2 * a),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y + h * .003), width: half * 2.1, height: h * .009),
        _bayF..color = Color.fromRGBO(255, 255, 255, .7 * a),
      );
    }
    // Ripples drift toward the beach, fading in and out.
    for (var i = 0; i < 38; i++) {
      final seed = 900 + i * 4;
      final x0 = h * .04 + (span - h * .2) * Sketch.hash(seed);
      if (x0 < view.left - h * .1 || x0 > view.right) continue;
      final u = (Sketch.hash(seed + 1) + t * (.012 + .01 * Sketch.hash(seed + 2))) % 1.0;
      final fade = math.sin(u * math.pi);
      final x = x0 + math.sin(t * .5 + i) * h * .006;
      final y = h * (.797 + .108 * u);
      final len = h * (.016 + .05 * u) * (.7 + .6 * Sketch.hash(seed + 3));
      final w = h * (.0012 + .0022 * u);
      _bayS
        ..strokeWidth = w
        ..color = Color.fromRGBO(20, 105, 150, (.1 + .12 * u) * fade * a);
      c.drawLine(Offset(x, y + w * 1.8), Offset(x + len, y + w * 1.8), _bayS);
      _bayS.color = Color.fromRGBO(255, 255, 255, (.14 + .36 * u) * fade * a);
      c.drawLine(Offset(x, y), Offset(x + len, y), _bayS);
    }
    _bayBuoys(c, a, t, h, h * 1.55, h * .868, 5);
    for (final (fx, fy, kind, u, dir) in _bayCast) {
      final x = h * fx, reach = h * u * 2.6;
      if (x + reach < view.left || x - reach > view.right) continue;
      final ph = fx * 5.3;
      final boat = kind <= 3 || kind == 6 || kind == 7;
      c.save();
      c.translate(x, h * fy + math.sin(t * 1.3 + ph) * h * .0022);
      if (boat) c.rotate(math.sin(t * 1.05 + ph * 1.7) * .03 + (kind == 0 ? .05 * dir : 0));
      c.scale(h * u * dir, h * u);
      switch (kind) {
        case 0:
          _bayYacht(c, a, t);
        case 1:
          _bayTrawler(c, a, t);
        case 2:
          _bayCat(c, a, t);
        case 3:
          _jangada(c, a, t);
        case 4:
          _bayKite(c, a, t);
        case 5:
          _bayWave(c, a, t);
        case 6:
          _baySup(c, a, t);
        case 7:
          _bayKayak(c, a, t);
        default:
          _baySwimmer(c, a, t + ph);
      }
      c.restore();
    }
  }

  /// A swim-area line of red-and-white buoys on a sagging rope.
  static void _bayBuoys(Canvas c, double a, double t, double h, double x0, double y, int n) {
    final gap = h * .1;
    final rope = Path();
    for (var i = 0; i < n; i++) {
      final bx = x0 + i * gap, by = y + math.sin(t * 1.3 + i * 1.9) * h * .002;
      if (i == 0) {
        rope.moveTo(bx, by);
      } else {
        final px = bx - gap;
        rope.quadraticBezierTo(px + gap / 2, y + h * .009, bx, by);
      }
    }
    c.drawPath(
      rope,
      _bayS
        ..strokeWidth = math.max(.6, h * .0016)
        ..color = Color.fromRGBO(240, 250, 255, .6 * a),
    );
    for (var i = 0; i < n; i++) {
      final bx = x0 + i * gap, by = y + math.sin(t * 1.3 + i * 1.9) * h * .002;
      c.save();
      c.translate(bx, by);
      c.scale(h * .05, h * .05);
      _bayO(c, a, 0, .07, .16, .04, const Color(0x40ffffff));
      c.drawRRect(RRect.fromLTRBR(-.09, -.26, .09, .03, const Radius.circular(.08)), _bayF..color = _bayA(_bayCoral, a));
      c.drawRect(const Rect.fromLTRB(-.09, -.15, .09, -.1), _bayF..color = _bayA(_bayWhite, a));
      c.restore();
    }
  }

  /// A cruising sloop: white hull, navy sheer stripe, roached main and genoa.
  static void _bayYacht(Canvas c, double a, double t) {
    final sway = math.sin(t * 1.7) * .012;
    _bayL(c, a, .05, -1.19, -.5, -.12, .007, _bayGrey);
    _bayL(c, a, .05, -1.19, .55, -.13, .007, _bayGrey);
    _bayP(c, a, [.075, -1.03, .53, -.15, .085, -.19], const Color(0xffe6f3fb));
    final main = Path()
      ..moveTo(.045, -.2)
      ..lineTo(.045, -1.17)
      ..quadraticBezierTo(-.3, -.72 + sway, -.44 + sway, -.215)
      ..close();
    _bayPath(c, a, main, _baySail);
    _bayP(c, a, [.045, -.2, .045, -1.17, -.05, -.82, -.13, -.21], _baySailShade);
    for (final k in const [.28, .5, .72]) {
      final y = -.2 - .97 * k;
      _bayL(c, a, .045, y, -.41 + .485 * k - .06 * math.sin(k * math.pi), y + .01, .008, const Color(0xffd0c4aa));
    }
    _bayL(c, a, .045, -.19, .045, -1.2, .016, _bayGrey);
    _bayL(c, a, .045, -.2, -.46 + sway, -.215, .018, const Color(0xff9aa7ae));
    _bayP(c, a, [.05, -1.21, .16, -1.185 + sway, .05, -1.165], _bayCoral);
    final hull = Path()
      ..moveTo(-.5, -.115)
      ..quadraticBezierTo(0, -.07, .55, -.14)
      ..quadraticBezierTo(.5, -.05, .4, .02)
      ..quadraticBezierTo(0, .05, -.42, .015)
      ..close();
    _bayPath(c, a, hull, _bayWhite);
    _bayC(c, a, Path()..moveTo(-.49, -.085)..quadraticBezierTo(0, -.04, .5, -.105), .03, _bayNavy);
    _bayC(c, a, Path()..moveTo(-.4, .0)..quadraticBezierTo(0, .03, .38, .0), .035, _bayGrey);
    _bayP(c, a, [-.22, -.1, -.18, -.19, .14, -.185, .24, -.1], const Color(0xffe9f1f5));
    _bayP(c, a, [-.15, -.165, .13, -.162, .14, -.14, -.14, -.14], _bayNavy);
    _bayLap(c, a, -.46, .5, const Color(0xffdff6ff));
    _bayO(c, a, .5, .0, .09, .02, const Color(0xd0ffffff));
  }

  /// A fishing boat with a wheelhouse, boom, net pile and a man at the stern.
  static void _bayTrawler(Canvas c, double a, double t) {
    _bayL(c, a, .3, -.2, .3, -.9, .02, _bayWoodDark);
    _bayL(c, a, .3, -.62, -.34, -.8, .014, _bayWoodDark);
    _bayL(c, a, -.34, -.8, -.34, -.5, .006, _bayGrey);
    _bayP(c, a, [.3, -.9, .42, -.87, .3, -.84], _bayCoral);
    final hull = Path()
      ..moveTo(-.5, -.15)
      ..quadraticBezierTo(0, -.1, .3, -.15)
      ..quadraticBezierTo(.47, -.19, .58, -.3)
      ..quadraticBezierTo(.52, -.08, .38, .02)
      ..quadraticBezierTo(0, .06, -.44, .02)
      ..close();
    _bayPath(c, a, hull, _bayBlue);
    _bayC(c, a, Path()..moveTo(-.46, -.11)..quadraticBezierTo(0, -.065, .29, -.11)..quadraticBezierTo(.46, -.15, .53, -.215), .07, _bayWhite);
    _bayC(c, a, Path()..moveTo(-.46, -.06)..quadraticBezierTo(0, -.02, .3, -.06)..quadraticBezierTo(.44, -.09, .5, -.14), .022, _bayCoral);
    _bayP(c, a, [-.22, -.13, -.2, -.36, .04, -.36, .08, -.13], _bayWhite);
    _bayP(c, a, [-.22, -.13, -.2, -.36, -.16, -.36, -.16, -.13], _bayGrey);
    _bayP(c, a, [-.24, -.36, .07, -.36, .06, -.4, -.23, -.4], _bayBlue);
    _bayP(c, a, [-.15, -.31, -.02, -.31, -.02, -.22, -.14, -.22], _bayNavy);
    _bayL(c, a, -.1, -.4, -.1, -.6, .012, _bayGrey);
    _bayO(c, a, -.1, -.62, .05, .02, _bayWhite);
    _bayO(c, a, .37, -.2, .13, .06, const Color(0xff3aa58a));
    _bayO(c, a, .34, -.23, .07, .03, const Color(0xff5fc7a8));
    _bayO(c, a, .22, -.19, .035, .035, _bayCoral);
    // The fisher hauls a line.
    final haul = math.sin(t * 1.4) * .03;
    _bayL(c, a, -.4, -.15, -.4, -.29, .07, const Color(0xffb7d84a));
    _bayO(c, a, -.4, -.335, .04, .04, _baySkin);
    _bayO(c, a, -.4, -.36, .05, .02, _bayNavy);
    _bayL(c, a, -.38, -.27, -.26 + haul, -.2, .03, _baySkin);
    _bayLap(c, a, -.46, .52, _bayWhite);
    _bayO(c, a, -.8, .005, .3, .014, const Color(0x90ffffff));
    _bayO(c, a, -1.25, .0, .35, .01, const Color(0x55ffffff));
  }

  /// A beach catamaran: twin hulls, a mesh trampoline, a tall white sail with
  /// a magenta head and two sailors.
  static void _bayCat(Canvas c, double a, double t) {
    final sway = math.sin(t * 1.6) * .012;
    const mag = Color(0xffc93a8a);
    _bayL(c, a, .04, -.16, .04, -1.06, .016, _bayGrey);
    final sail = Path()
      ..moveTo(.04, -.17)
      ..lineTo(.04, -1.05)
      ..quadraticBezierTo(-.3, -.68 + sway, -.46 + sway, -.2)
      ..close();
    _bayPath(c, a, sail, _baySail);
    _bayP(c, a, [.04, -1.05, -.058, -.9365, -.145, -.82, .04, -.8], mag);
    _bayP(c, a, [.04, -.17, .04, -.9, -.06, -.6, -.14, -.2], _baySailShade);
    _bayP(c, a, [.07, -.82, .5, -.13, .08, -.18], const Color(0xfff6dcec));
    _bayL(c, a, .04, -.17, -.46 + sway, -.2, .016, const Color(0xff9aa7ae));
    // Far hull, trampoline, then the near hull.
    final hullFar = Path()
      ..moveTo(-.43, -.135)
      ..quadraticBezierTo(.08, -.1, .5, -.2)
      ..quadraticBezierTo(.46, -.09, .34, -.07)
      ..quadraticBezierTo(-.05, -.06, -.4, -.08)
      ..close();
    _bayPath(c, a, hullFar, const Color(0xffb8ccd8));
    _bayP(c, a, [-.4, -.09, .4, -.11, .42, -.17, -.34, -.145], const Color(0xff2a4a6e));
    for (var k = 1; k < 5; k++) {
      final x = -.4 + k * .2;
      _bayL(c, a, x, -.1, x + .02, -.16, .008, const Color(0xff6f8fae));
    }
    for (final (x, lean, shirt) in const [(-.14, .05, Color(0xffe8505f)), (-.02, -.03, Color(0xff3c8fd6))]) {
      _bayL(c, a, x, -.13, x + lean, -.24, .06, shirt);
      _bayO(c, a, x + lean, -.275, .035, .035, _baySkin);
    }
    final hull = Path()
      ..moveTo(-.5, -.07)
      ..quadraticBezierTo(.05, -.03, .52, -.13)
      ..quadraticBezierTo(.5, -.02, .36, .02)
      ..quadraticBezierTo(-.05, .04, -.46, .01)
      ..close();
    _bayPath(c, a, hull, _bayWhite);
    _bayC(c, a, Path()..moveTo(-.44, -.03)..quadraticBezierTo(0, .0, .42, -.05), .022, mag);
    _bayL(c, a, -.25, -.08, -.22, -.15, .014, const Color(0xff3a4a58));
    _bayL(c, a, .25, -.09, .27, -.16, .014, const Color(0xff3a4a58));
    _bayLap(c, a, -.46, .5, _bayWhite);
    _bayO(c, a, .5, .0, .09, .02, const Color(0xd0ffffff));
  }

  /// A jangada, the sailing raft of the north-east coast: lashed logs under
  /// one tall lateen sail bearing a painted sun, a fisher at the steering oar.
  static void _jangada(Canvas c, double a, double t) {
    const head = Offset(.14, -1.36), tack = Offset(.56, -.2), clew = Offset(-.42, -.26);
    final flap = math.sin(t * 1.8) * .012;
    _bayL(c, a, .14, -1.36, -.52, -.14, .007, _bayGrey);
    final sail = Path()
      ..moveTo(head.dx, head.dy)
      ..lineTo(tack.dx, tack.dy)
      ..lineTo(clew.dx, clew.dy)
      ..quadraticBezierTo(-.3 + flap, -.75, head.dx, head.dy);
    _bayPath(c, a, sail, _baySail);
    _bayP(c, a, [head.dx, head.dy, clew.dx, clew.dy, 0.0, -.24, .08, -.6], _baySailShade);
    for (final k in const [.25, .5, .75]) {
      final p1 = Offset.lerp(tack, head, k)!, p2 = Offset.lerp(clew, head, k)!;
      _bayL(c, a, p1.dx, p1.dy, p2.dx, p2.dy, .01, const Color(0xffd6c8a8));
    }
    // The painted emblem: a red sun ringed in cream.
    _bayO(c, a, .09, -.6, .15, .15, _bayCoral);
    _bayO(c, a, .09, -.6, .09, .09, _baySail);
    _bayO(c, a, .09, -.6, .045, .045, _bayNavy);
    _bayL(c, a, head.dx, head.dy, tack.dx, tack.dy, .024, _bayWoodDark);
    _bayL(c, a, clew.dx, clew.dy, tack.dx, tack.dy, .024, _bayWoodDark);
    _bayL(c, a, .05, -.12, .13, -1.37, .03, const Color(0xff7a5a3a));
    // Steering oar, bench and cooler.
    _bayL(c, a, -.52, -.36, -.64, .16, .022, _bayWoodDark);
    _bayO(c, a, -.645, .18, .03, .06, _bayWoodDark);
    _bayL(c, a, -.42, -.19, -.16, -.19, .035, _bayWood);
    _bayP(c, a, [.0, -.29, .18, -.29, .18, -.19, .0, -.19], _bayWhite);
    _bayP(c, a, [-.005, -.29, .185, -.29, .185, -.26, -.005, -.26], _bayCoral);
    // The raft: logs stacked, roped, with the log ends at the bow.
    final top = Path()..moveTo(-.55, -.1)..quadraticBezierTo(0, -.07, .58, -.19);
    final body = Path()
      ..moveTo(-.55, -.1)
      ..quadraticBezierTo(0, -.07, .58, -.19)
      ..lineTo(.5, -.01)
      ..quadraticBezierTo(0, .03, -.5, .02)
      ..close();
    _bayPath(c, a, body, _bayWood);
    for (final dy in const [.05, .1]) {
      _bayC(c, a, Path()..moveTo(-.53, -.1 + dy)..quadraticBezierTo(0, -.07 + dy, .55, -.19 + dy), .012, _bayWoodDark);
    }
    _bayC(c, a, top, .014, const Color(0xffefc98e));
    for (final x in const [-.4, -.15, .1, .35]) {
      final y = -.1 + (x + .55) * -.075 + .02;
      _bayL(c, a, x, y - .02, x, y + .06, .014, const Color(0xff5a3a24));
    }
    for (final (dy, dx) in const [(-.16, .58), (-.11, .575), (-.06, .56)]) {
      _bayO(c, a, dx, dy, .022, .032, const Color(0xffe6bc80));
      _bayO(c, a, dx, dy, .01, .016, _bayWoodDark);
    }
    // The fisher: straw hat, blue shirt, an arm on the oar.
    _bayL(c, a, -.27, -.19, -.13, -.18, .05, const Color(0xff9a8a5a));
    _bayL(c, a, -.27, -.2, -.25, -.38, .09, const Color(0xff4a86c6));
    _bayL(c, a, -.26, -.34, -.46, -.27 + math.sin(t * .8) * .02, .035, _baySkin);
    _bayO(c, a, -.245, -.44, .05, .05, _baySkin);
    _bayO(c, a, -.245, -.475, .11, .022, const Color(0xffe5c27a));
    _bayO(c, a, -.245, -.49, .055, .04, const Color(0xffe5c27a));
    _bayLap(c, a, -.5, .56, _bayWood);
    _bayO(c, a, -.85, .005, .3, .012, const Color(0x70ffffff));
  }

  /// A kite-surfer carving right, the small kite high up on its lines.
  static void _bayKite(Canvas c, double a, double t) {
    final sway = math.sin(t * .7) * .12;
    final kx = .38 + sway * .6, ky = -1.42 + math.sin(t * .9) * .03;
    _bayO(c, a, -.45, -.01, .38, .03, const Color(0x99ffffff));
    _bayO(c, a, -1.0, .0, .32, .02, const Color(0x55ffffff));
    _bayL(c, a, .14, -.52, kx - .16, ky + .06, .008, const Color(0x99ffffff));
    _bayL(c, a, .14, -.52, kx + .16, ky + .06, .008, const Color(0x99ffffff));
    c.save();
    c.translate(kx, ky);
    c.rotate(sway * .9 + .2);
    final canopy = Path()
      ..moveTo(-.34, .08)
      ..quadraticBezierTo(0, -.32, .34, .08)
      ..quadraticBezierTo(0, -.1, -.34, .08)
      ..close();
    _bayPath(c, a, canopy, const Color(0xffc93a8a));
    _bayC(c, a, Path()..moveTo(-.34, .08)..quadraticBezierTo(0, -.32, .34, .08), .04, _bayWhite);
    _bayC(c, a, Path()..moveTo(-.12, -.09)..quadraticBezierTo(0, -.15, .12, -.09), .045, const Color(0xff2fc4d0));
    c.restore();
    _bayPath(c, a, Path()..moveTo(-.34, -.02)..quadraticBezierTo(0, -.09, .34, -.05)..quadraticBezierTo(0, .02, -.34, -.02), const Color(0xfff4f7f6));
    _bayL(c, a, -.1, -.05, .0, -.36, .075, _bayNavy);
    _bayL(c, a, .12, -.06, .0, -.36, .075, const Color(0xff2a5a86));
    _bayL(c, a, .0, -.36, -.08, -.66, .11, const Color(0xffdd4a5a));
    _bayL(c, a, -.06, -.6, .13, -.52, .04, _baySkin);
    _bayO(c, a, -.1, -.74, .055, .055, _baySkin);
    _bayO(c, a, -.11, -.77, .06, .035, _bayNavy);
  }

  /// A breaking wave with a surfer standing on its face and another paddling.
  static void _bayWave(Canvas c, double a, double t) {
    final wob = math.sin(t * 1.5) * .02;
    final face = Path()
      ..moveTo(-1.0, .02)
      ..quadraticBezierTo(-.75, -.22, -.15, -.4)
      ..quadraticBezierTo(.28, -.52, .62, -.38)
      ..quadraticBezierTo(1.05, -.22, 1.32, .02)
      ..close();
    _bayPath(c, a, face, const Color(0xffe0f8f8));
    _bayO(c, a, .2, -.02, 1.1, .12, const Color(0x8a1b8fb2));
    _bayO(c, a, .2, -.14, .85, .12, const Color(0x5a5edcdc));
    for (final (x0, dy) in const [(-.4, -.05), (.05, -.13)]) {
      _bayC(c, a, Path()..moveTo(x0, -.12 + dy)..quadraticBezierTo(x0 + .5, -.26 + dy, x0 + 1.0, -.1 + dy), .02, const Color(0x66177fa2));
    }
    _bayC(c, a, Path()..moveTo(-.15, -.4)..quadraticBezierTo(.28, -.52, .7, -.4), .07, _bayWhite);
    _bayO(c, a, .3, -.5 + wob * .3, .22, .05, _bayWhite);
    for (final (i, (x, y, rx, ry)) in const [(-.75, -.1, .42, .14), (-1.05, -.05, .3, .1), (-.45, -.2, .3, .12), (-.2, -.3, .18, .08)].indexed) {
      _bayO(c, a, x, y + .03, rx, ry, const Color(0xffbfe8f0));
      _bayO(c, a, x, y + math.sin(t * 1.5 + i) * .015, rx * .92, ry * .9, _bayWhite);
    }
    // The surfer, carving along the face.
    final bx = .68 + math.sin(t * .5) * .1, by = -.3 + math.sin(t * 1.4) * .02;
    c.save();
    c.translate(bx, by);
    c.rotate(.3);
    _bayPath(c, a, Path()..moveTo(-.3, .0)..quadraticBezierTo(0, -.06, .3, -.02)..quadraticBezierTo(0, .03, -.3, .0), const Color(0xfff4f7f6));
    _bayL(c, a, -.2, -.01, .2, -.02, .012, const Color(0xff2fc4d0));
    c.restore();
    _bayL(c, a, bx - .07, by - .03, bx - .03, by - .3, .06, _bayNavy);
    _bayL(c, a, bx + .07, by - .04, bx + .05, by - .3, .06, _bayNavy);
    _bayL(c, a, bx + .02, by - .3, bx + .08, by - .62, .1, const Color(0xff3d6fd8));
    _bayL(c, a, bx + .07, by - .56, bx - .16, by - .5, .035, _baySkin);
    _bayL(c, a, bx + .08, by - .55, bx + .3, by - .66, .035, _baySkin);
    _bayO(c, a, bx + .1, by - .7, .055, .055, _baySkin);
    _bayO(c, a, bx + .09, by - .74, .06, .04, _bayNavy);
    // A second surfer lies on his board beyond the shoulder, paddling.
    final arm = math.sin(t * 2.2);
    _bayO(c, a, 1.75, .0, .42, .045, const Color(0xfff4f7f6));
    _bayO(c, a, 1.7, -.075, .26, .06, const Color(0xffe8505f));
    _bayO(c, a, 1.98, -.11, .055, .055, _baySkin);
    _bayL(c, a, 1.86, -.1, 1.98 + arm * .1, -.02 + arm * .06, .035, _baySkin);
    _bayO(c, a, 2.05, .02, .2, .02, const Color(0x80ffffff));
  }

  /// A stand-up paddler working a long board.
  static void _baySup(Canvas c, double a, double t) {
    final swing = math.sin(t * 1.1) * .22;
    _bayO(c, a, .0, .06, .5, .03, const Color(0x40ffffff));
    _bayPath(c, a, Path()..moveTo(-.55, -.02)..quadraticBezierTo(-.1, -.09, .55, -.03)..quadraticBezierTo(-.1, .03, -.55, -.02), const Color(0xfff2fbfb));
    _bayC(c, a, Path()..moveTo(-.45, -.03)..quadraticBezierTo(0, -.06, .48, -.03), .018, const Color(0xff2fc4d0));
    _bayL(c, a, -.09, -.05, -.04, -.34, .055, const Color(0xff2a5a86));
    _bayL(c, a, .02, -.055, -.02, -.34, .055, const Color(0xff2a5a86));
    _bayL(c, a, -.03, -.34, -.03, -.58, .11, const Color(0xffe8505f));
    _bayO(c, a, -.03, -.66, .052, .052, _baySkin);
    _bayO(c, a, -.03, -.69, .056, .034, _bayNavy);
    final g = Offset(.1, -.66);
    final d = Offset(math.sin(.28 + swing), math.cos(.28 + swing));
    final b = g + d * .86, hand = g + d * .38;
    _bayL(c, a, -.03, -.55, g.dx, g.dy, .04, _baySkin);
    _bayL(c, a, -.03, -.52, hand.dx, hand.dy, .04, _baySkin);
    _bayL(c, a, g.dx, g.dy, b.dx, b.dy, .02, const Color(0xffe6eef2));
    _bayL(c, a, b.dx - d.dx * .2, b.dy - d.dy * .2, b.dx, b.dy, .065, const Color(0xff1f8aa5));
    _bayO(c, a, b.dx, .01, .09, .02, const Color(0xa0ffffff));
  }

  /// A sea kayak with a paddler swinging a double blade.
  static void _bayKayak(Canvas c, double a, double t) {
    final ang = math.sin(t * 1.6) * .42;
    _bayO(c, a, .0, .06, .55, .03, const Color(0x40ffffff));
    _bayPath(c, a, Path()..moveTo(-.6, -.06)..quadraticBezierTo(-.1, -.13, .62, -.08)..quadraticBezierTo(-.1, .03, -.6, -.06), _bayCoral);
    _bayC(c, a, Path()..moveTo(-.5, -.075)..quadraticBezierTo(0, -.11, .5, -.085), .02, _bayWhite);
    _bayL(c, a, -.03, -.1, -.03, -.32, .12, const Color(0xff3a9ad0));
    _bayO(c, a, -.03, -.39, .055, .055, _baySkin);
    _bayO(c, a, -.03, -.42, .06, .03, _bayWhite);
    c.save();
    c.translate(-.02, -.24);
    c.rotate(ang);
    _bayL(c, a, -.64, 0.0, .64, 0.0, .02, const Color(0xff3a4a58));
    _bayO(c, a, -.66, .0, .1, .028, _bayWhite);
    _bayO(c, a, .66, .0, .1, .028, _bayCoral);
    c.restore();
    _bayL(c, a, -.03, -.28, .1, -.24, .04, _baySkin);
    _bayLap(c, a, -.56, .58, _bayCoral);
  }

  /// A swimmer doing the crawl, a bright cap and a splash of rings.
  static void _baySwimmer(Canvas c, double a, double t) {
    final s = math.sin(t * 3);
    _bayO(c, a, -.05, .03, .5, .07, const Color(0x80ffffff));
    _bayO(c, a, -.05, .03, .3, .045, const Color(0x40ffffff));
    _bayO(c, a, -.32, -.02, .34, .085, const Color(0xff2a7ab8));
    _bayL(c, a, -.05, -.1, .2 + s * .1, s > 0 ? -.3 * s - .06 : -.06, .07, _baySkin);
    _bayO(c, a, .06, -.08, .12, .12, _baySkin);
    _bayO(c, a, .06, -.13, .13, .09, _bayCoral);
    _bayO(c, a, -.72 - s * .04, .0, .2, .025, const Color(0xa0ffffff));
  }

  // ---------------------------------------------------------------------
  // Hills: forested morros with houses stacked up their slopes, a church on
  // a knoll, cables and a zip line, and a hint of Copacabana's towers behind.
  // The band is timed and drifts left, so it runs past the right edge.
  // ---------------------------------------------------------------------

  /// Morros, back to front: x as a fraction of the width plus an offset in
  /// heights, half width and crest top in heights, seed, haze, and kind (0
  /// a hazy back hill, 1 a hillside town, 2 the church knoll). The tall ones
  /// stand clear of the Sugarloaf and Corcovado so the peaks keep their feet.
  static const _hills = [
    (0.0, -.25, .3, .595, 11, .36, 0),
    (.17, 0.0, .2, .606, 12, .34, 0),
    (.07, 0.0, .3, .56, 13, .2, 1),
    (.6, .12, .21, .612, 14, .32, 0),
    (.62, 0.0, .17, .548, 15, .18, 2),
    (1.0, -.05, .3, .59, 16, .34, 0),
    (1.0, .62, .3, .6, 18, .32, 0),
    (1.0, .1, .35, .52, 17, .16, 1),
  ];

  /// The hill that carries the zip line.
  static const _hillZipOn = 7;

  /// House paints: bare brick and concrete are as common as the pastels.
  static const _hillPaints = [
    Color(0xffffb45e),
    Color(0xfff2758a),
    Color(0xff62cfe0),
    Color(0xfff7e88a),
    Color(0xffa4dc7c),
    Color(0xfff6a3cb),
    Color(0xfffff1dc),
    Color(0xffe8f4f4),
    Color(0xffd98a62),
    Color(0xffc9743f),
    Color(0xffbdb6aa),
    Color(0xff8fb4e8),
    Color(0xffd8c0f0),
  ];

  static const _hillGlass = Color(0xff34495e);
  static const _hillTile = Color(0xffc8583c);
  static const _hillSlab = Color(0xffddd6c8);
  static const _hillLit = Color(0xffb4e58c);
  static const _hillShade = Color(0xff1a5c48);

  /// Forest green from the sunlit crest ([t] 0) to the shaded foot (1).
  static Color _hillTone(double t, double haze) =>
      _hazed(Sketch.mix(const Color(0xff62bb72), const Color(0xff2b8556), t), haze);

  /// Height of a morro's crest above its foot at [u] (-1 to 1 across it):
  /// a steep-sided dome with a lopsided summit and knobbly shoulders.
  static double _hillRise(double u, double b, int seed) {
    final knoll = seed == _hills[4].$5;
    final v = u - (knoll ? 0 : .16) * math.sin(seed * 2.1) * (1 - u * u);
    final k = 1 - v * v;
    if (k <= 0) return 0;
    final wobble = 1 + (knoll ? .02 : .06) * math.sin(u * 6.5 + seed * 1.7) + .03 * math.sin(u * 15 + seed);
    // The church knoll has a broad, flat summit to carry the terrace.
    return b * math.pow(k, knoll ? .4 : .72) * wobble;
  }

  void _headlands(Canvas c, double w, double h) {
    _hillTowers(c, w, h);
    _hillShore(c, w, h);
    for (final (fx, off, half, top, seed, haze, kind) in _hills) {
      final cy = h * .76;
      _hillMass(c, h, w * fx + h * off, h * half, cy, cy - h * top, seed, haze, kind);
    }
    // A breath of bay haze in the valleys, thickest where the hills meet the water.
    final top = h * .58, bottom = h * .74;
    c.drawRect(
      Rect.fromLTRB(-h * .5, top, w + h * 1.3, bottom),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          [Sketch.fade(_haze, 0), Sketch.fade(_haze, .1), Sketch.fade(_haze, .3)],
          const [0, .45, 1],
        ),
    );
  }

  /// One morro: a gradient dome, its shade and lit flanks, knobbly canopy,
  /// forest, and, on the towns, stairs, houses, cables and a church.
  void _hillMass(Canvas c, double h, double cx, double a, double cy, double b, int seed, double haze, int kind) {
    final top = cy - b;
    Offset crest(double u) => Offset(cx + u * a, cy - _hillRise(u, b, seed));
    const n = 56;
    final body = Path()..moveTo(cx - a, cy);
    for (var i = 1; i < n; i++) {
      final p = crest(-1 + 2 * i / n);
      body.lineTo(p.dx, p.dy);
    }
    body
      ..lineTo(cx + a, cy)
      ..close();
    c.drawPath(
      body,
      Paint()..shader = Gradient.linear(Offset(0, top), Offset(0, cy), [_hillTone(0, haze), _hillTone(1, haze)]),
    );
    // The sun stands high on the right: the left flank falls into shade.
    Path plane(double u0, double u1, double foot0, double foot1) {
      final p = crest(u0);
      final path = Path()..moveTo(p.dx, p.dy);
      for (var i = 1; i <= 16; i++) {
        final q = crest(u0 + (u1 - u0) * i / 16);
        path.lineTo(q.dx, q.dy);
      }
      return path
        ..lineTo(cx + foot1 * a, cy)
        ..lineTo(cx + foot0 * a, cy)
        ..close();
    }

    c.drawPath(plane(-1, -.04, -1, -.34), Paint()..color = Sketch.fade(_hazed(_hillShade, haze * .6), .34));
    c.drawPath(plane(.2, 1, .04, 1), Paint()..color = Sketch.fade(_hazed(_hillLit, haze * .6), .3));

    final fill = Paint();
    double ridgeAt(double x) => ridge(Depth.mid, x / h, 0) * h;
    // Canopy: overlapping tree crowns knob the skyline, each with a lit cap.
    final bumps = (a / (h * (kind == 0 ? .0135 : .0105))).round();
    for (var i = 0; i < bumps; i++) {
      final sd = seed * 211 + i;
      final u = -.97 + 1.94 * (i + .5 + .55 * (Sketch.hash(sd) - .5)) / bumps;
      final rise = _hillRise(u, b, seed);
      if (rise < h * .014) continue;
      final r = h * (.0085 + .0075 * Sketch.hash(sd + 900));
      _hillCrown(c, fill, Offset(cx + u * a, cy - rise + r * .3), r, (1 - rise / b) * .9, u, haze);
    }
    // Forest over the summit, and over the whole slope of the hazy back hills.
    final deep = kind == 0 ? b * .95 : b * (kind == 2 ? .16 : .13);
    final trees = (a / h * (kind == 0 ? 28 : 20)).round();
    for (var i = 0; i < trees; i++) {
      final sd = seed * 313 + i;
      final u = (Sketch.hash(sd) * 2 - 1) * .86;
      final p = crest(u);
      final y = p.dy + h * .012 + deep * Sketch.hash(sd + 1);
      if (y > ridgeAt(p.dx) + h * .005) continue;
      final r = h * (.0075 + .0065 * Sketch.hash(sd + 2));
      _hillCrown(c, fill, Offset(p.dx, y), r, (y - top) / b, u, haze);
    }
    if (kind > 0) {
      // A few tall trees and palms break through the crest.
      for (var i = 0; i < (kind == 2 ? 4 : 6); i++) {
        final sd = seed * 419 + i;
        final u = -.7 + 1.4 * (i + .4 + .3 * Sketch.hash(sd)) / (kind == 2 ? 4 : 6);
        final p = crest(u) + Offset(0, h * .008);
        if (Sketch.hash(sd + 1) < .45) {
          _hillPalm(c, fill, p, h * (.036 + .014 * Sketch.hash(sd + 2)), sd, haze);
        } else {
          _hillCanopyTree(c, fill, p, h * (.034 + .014 * Sketch.hash(sd + 2)), haze);
        }
      }
      final s = h * (kind == 2 ? .0185 : .021);
      final cap = h * (kind == 2 ? .072 : .05);
      _hillStairs(c, h, cx, a, cy, b, seed, s, haze, cap);
      _hillTown(c, h, cx, a, cy, b, seed, s, haze, cap);
      if (kind == 2) _hillChurch(c, h, crest(-.02), haze);
      _hillWires(c, h, cx, a, cy, b, seed, haze, cap);
      if (kind == 1 && seed == _hills[_hillZipOn].$5) {
        final (from, to) = _hillZip(cx, a, cy, b, seed, h);
        _hillZipLine(c, h, from, to, haze);
      }
    } else {
      // Tiny huts freckle the back hills.
      _hillTown(c, h, cx, a, cy, b, seed, h * .0105, haze, h * .03, simple: true);
    }
    // Shade over everything on the far flank, light over the near one.
    c.drawPath(plane(-1, -.04, -1, -.34), Paint()..color = Sketch.fade(_hillShade, .1));
    c.drawPath(plane(.28, 1, .12, 1), Paint()..color = Sketch.fade(const Color(0xffffffe0), .07));
  }

  /// A round tree crown with a sunlit cap, toned by how far down the hill it
  /// sits ([t]) and which flank ([u]).
  static void _hillCrown(Canvas c, Paint fill, Offset at, double r, double t, double u, double haze) {
    var tone = _hillTone(t.clamp(0.0, 1.0), haze);
    if (u < -.05) tone = Sketch.mix(tone, _hillShade, .28 * math.min(1.0, -u * 1.5));
    if (u > .2) tone = Sketch.mix(tone, _hillLit, .16 * math.min(1.0, u * 1.2));
    c.drawCircle(at, r, fill..color = tone);
    c.drawCircle(at + Offset(r * .3, -r * .32), r * .58, fill..color = Sketch.mix(tone, _hillLit, .42));
  }

  /// An Atlantic-forest emerging tree: a slim trunk under a flat umbrella.
  static void _hillCanopyTree(Canvas c, Paint fill, Offset base, double s, double haze) {
    c.drawRect(
      Rect.fromLTRB(base.dx - s * .028, base.dy - s * .62, base.dx + s * .028, base.dy),
      fill..color = _hazed(const Color(0xff6a4a34), haze),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(base.dx, base.dy - s * .72), width: s * .82, height: s * .38),
      fill..color = _hazed(const Color(0xff2b7a4c), haze),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(base.dx + s * .07, base.dy - s * .78), width: s * .56, height: s * .2),
      fill..color = _hazed(const Color(0xff7ccb78), haze),
    );
  }

  /// A slender palm: a leaning trunk and a crown of arching fronds.
  static void _hillPalm(Canvas c, Paint fill, Offset base, double s, int sd, double haze) {
    final lean = (Sketch.hash(sd + 7) - .5) * s * .2;
    final crown = base + Offset(lean, -s);
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + lean * .2, base.dy - s * .55, crown.dx, crown.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, s * .05)
        ..color = _hazed(const Color(0xff8a6a48), haze),
    );
    final leaves = Path();
    final lit = Path();
    for (var i = 0; i < 7; i++) {
      final a = -math.pi * (.06 + .88 * i / 6);
      final len = s * (i == 3 ? .3 : .38);
      final tip = crown + Offset(math.cos(a) * len, math.sin(a) * len * .55 + len * .5 * (i == 3 ? 0 : .35 + .35 * (1 - math.sin(a).abs())));
      final mid = crown + Offset(math.cos(a) * len * .5, math.sin(a) * len * .55 - len * .16);
      final side = Offset(-math.sin(a), math.cos(a)) * len * .1;
      (i.isOdd ? lit : leaves)
        ..moveTo(crown.dx, crown.dy)
        ..quadraticBezierTo(mid.dx + side.dx, mid.dy + side.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(mid.dx - side.dx, mid.dy - side.dy, crown.dx, crown.dy);
    }
    c.drawPath(leaves, fill..color = _hazed(const Color(0xff2a7f4a), haze));
    c.drawPath(lit, fill..color = _hazed(const Color(0xff63bd6c), haze));
  }

  /// A banana clump: a few broad leaves fanning from one point.
  static void _hillBanana(Canvas c, Paint fill, Offset base, double s, double haze) {
    final leaves = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi * (.12 + .76 * i / 4);
      final tip = base + Offset(math.cos(a) * s * .55, math.sin(a) * s * .9 + s * .12);
      final side = Offset(-math.sin(a), math.cos(a)) * s * .16;
      final mid = Offset.lerp(base, tip, .55)!;
      leaves
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(mid.dx + side.dx, mid.dy + side.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(mid.dx - side.dx, mid.dy - side.dy, base.dx, base.dy);
    }
    c.drawPath(leaves, fill..color = _hazed(const Color(0xff4fa858), haze));
  }

  /// Stone stairways and lanes climbing the slope, seen between the houses.
  void _hillStairs(Canvas c, double h, double cx, double a, double cy, double b, int seed, double s, double haze, double cap) {
    final path = Path();
    for (var j = 0; j < 3; j++) {
      var u = -.55 + j * .5 + .18 * (Sketch.hash(seed * 5 + j) - .5);
      var first = true;
      for (var k = 0; k < 14; k++) {
        final p = Offset(cx + u * a, cy - _hillRise(u, b, seed) + cap + k * s * .85);
        if (first) {
          path.moveTo(p.dx, p.dy);
          first = false;
        } else {
          path.lineTo(p.dx, p.dy);
        }
        u += (k.isEven ? 1 : -.7) * s * 1.1 / a * (1 + .5 * Sketch.hash(seed * 9 + j * 20 + k));
      }
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(.9, h * .0026)
        ..color = _hazed(const Color(0xfff0e4cc), haze + .05),
    );
  }

  /// Houses in terraced rows that follow the hill's contour, top to bottom,
  /// so each lower row overlaps the one above. [simple] gives bare huts.
  void _hillTown(Canvas c, double h, double cx, double a, double cy, double b, int seed, double s, double haze, double cap, {bool simple = false}) {
    double ridgeAt(double x) => ridge(Depth.mid, x / h, 0) * h;
    final fill = Paint();
    var row = 0;
    Rect? prev;
    for (var d = cap; d < b * .97; d += s * (simple ? 1.5 : .8), row++) {
      var u = -.9 + .14 * Sketch.hash(seed * 7 + row);
      var i = 0;
      prev = null;
      while (u < .9) {
        final sd = seed * 977 + row * 131 + i;
        i++;
        final r0 = Sketch.hash(sd), r1 = Sketch.hash(sd + 500);
        final x = cx + u * a;
        final y = cy - _hillRise(u, b, seed) + d + s * .22 * (r1 - .5);
        u += s * (simple ? 1.6 + 2 * r0 : 1.05 + .8 * r0) / a;
        if (y > ridgeAt(x) + s * .45 || y > cy) continue;
        if (simple) {
          final hut = s * (.8 + .5 * r1);
          c.drawRect(
            Rect.fromLTWH(x - hut * .5, y - hut * .8, hut, hut * .8),
            fill..color = _hazed(_hillPaints[(r0 * _hillPaints.length).floor() % _hillPaints.length], haze + .1),
          );
          c.drawRect(
            Rect.fromLTWH(x - hut * .58, y - hut * 1.0, hut * 1.16, hut * .22),
            fill..color = _hazed(_hillTile, haze + .12),
          );
          continue;
        }
        final patch = math.sin(u * 10 + seed * 2.0 + row * .7) + math.sin(u * 3.7 + row * .45 + seed);
        if (patch > 1.3 || r0 < .09) {
          // A patch of forest or a little square where people gather.
          final p = Offset(x, y);
          if (r1 < .35 && patch <= 1.3) {
            _hillPerson(c, fill, p + Offset(-s * .25, 0), s, sd, haze);
            _hillPerson(c, fill, p + Offset(s * .2, s * .04), s * .92, sd + 3, haze);
          } else if (r1 < .68) {
            _hillCrown(c, fill, p + Offset(0, -s * .5), s * (.55 + .3 * r1), (y - cy + b) / b, u, haze);
          } else if (r1 < .84) {
            _hillPalm(c, fill, p, s * (2.6 + r1), sd, haze);
          } else {
            _hillBanana(c, fill, p, s * (1.1 + r1 * .4), haze);
          }
          prev = null;
          continue;
        }
        final rect = _hillHouse(c, Offset(x, y), s * (.88 + .38 * Sketch.hash(sd + 3)), sd, haze);
        if (r1 > .9 && prev != null && rect.left - prev.right < s * 2.2 && rect.left > prev.right - s * .3) {
          _hillLaundry(c, fill, Offset(prev.right, prev.top + prev.height * .3), Offset(rect.left, rect.top + rect.height * .3), s, sd, haze);
        }
        prev = rect;
      }
    }
  }

  /// One house: stacked floors with slab edges, windows and a door, a shaded
  /// side, and a flat slab, tile or corrugated roof with its clutter.
  Rect _hillHouse(Canvas c, Offset at, double s, int sd, double haze) {
    double r(int k) => Sketch.hash(sd * 31 + k);
    Color paint(int k) => _hazed(_hillPaints[(r(k) * _hillPaints.length).floor() % _hillPaints.length], haze);
    final wide = s * (.95 + .55 * r(1)), floorH = s * .8;
    final p = r(2);
    final floors = p < .5 ? 1 : (p < .86 ? 2 : 3);
    final fill = Paint();
    final shade = Path(), slabs = Path(), glass = Path();
    final base = paint(3);
    final left = at.dx - wide / 2, right = at.dx + wide / 2;
    var topL = left, topW = wide, topY = at.dy;
    for (var f = 0; f < floors; f++) {
      final fw = f == 0 ? wide : wide * (.74 + .24 * r(10 + f));
      final fl = f == 0 ? left : left + (wide - fw) * r(20 + f);
      final bottom = at.dy - f * floorH, tp = bottom - floorH;
      c.drawRect(Rect.fromLTRB(fl, tp, fl + fw, bottom), fill..color = f == 0 || r(30 + f) < .45 ? base : paint(40 + f));
      shade.addRect(Rect.fromLTRB(fl, tp, fl + fw * .24, bottom));
      if (f > 0) slabs.addRect(Rect.fromLTRB(left - s * .05, bottom - s * .04, right + s * .05, bottom + s * .04));
      final ww = s * .16, wh = s * .26, wy = tp + floorH * .28;
      glass.addRect(Rect.fromLTWH(fl + fw * .27 - ww / 2, wy, ww, wh));
      if (fw > s * 1.05) glass.addRect(Rect.fromLTWH(fl + fw * .74 - ww / 2, wy, ww, wh));
      if (f == 0) {
        glass.addRect(Rect.fromLTWH(fl + fw * (.4 + .2 * r(50)) - ww * .5, bottom - s * .42, ww * 1.1, s * .42));
      }
      topL = fl;
      topW = fw;
      topY = tp;
    }
    c.drawPath(shade, fill..color = const Color(0x26102030));
    if (floors > 1) c.drawPath(slabs, fill..color = _hazed(_hillSlab, haze));
    c.drawPath(glass, fill..color = _hazed(_hillGlass, haze + .08));
    final topR = topL + topW;
    final roof = r(4);
    if (roof < .42) {
      c.drawRect(Rect.fromLTRB(topL - s * .06, topY - s * .12, topR + s * .06, topY), fill..color = _hazed(_hillSlab, haze));
      final clutter = r(5);
      if (clutter < .5) {
        final tx = topL + topW * (.2 + .5 * r(6)), tw = s * .34;
        c.drawRect(Rect.fromLTWH(tx, topY - s * .12 - s * .4, tw, s * .4), fill..color = _hazed(r(7) < .65 ? const Color(0xff3a86d4) : const Color(0xffe8eef2), haze));
        c.drawRect(Rect.fromLTWH(tx - s * .02, topY - s * .12 - s * .44, tw + s * .04, s * .06), fill..color = _hazed(const Color(0xff8fc4f0), haze));
      } else if (clutter < .8 && floors > 1) {
        // Rebar waits on the roof for the next floor.
        final bars = Path();
        for (var k = 0; k < 3; k++) {
          final bx = topL + topW * (.18 + .32 * k);
          bars
            ..moveTo(bx, topY - s * .12)
            ..lineTo(bx, topY - s * .12 - s * .34);
        }
        c.drawPath(
          bars,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.6, s * .04)
            ..color = _hazed(const Color(0xff5a4a48), haze),
        );
      } else {
        c.drawCircle(Offset(topR - topW * .22, topY - s * .12 - s * .14), s * .13, fill..color = _hazed(const Color(0xffeef0ea), haze));
      }
    } else if (roof < .74) {
      c.drawPath(
        Sketch.poly([topL - s * .07, topY, topL + topW * .22, topY - s * .42, topR - topW * .22, topY - s * .42, topR + s * .07, topY]),
        fill..color = _hazed(_hillTile, haze),
      );
      c.drawPath(
        Sketch.poly([topL + topW * .5, topY, topL + topW * .5, topY - s * .42, topR - topW * .22, topY - s * .42, topR + s * .07, topY]),
        fill..color = _hazed(const Color(0xffe07a52), haze),
      );
    } else {
      c.drawPath(
        Sketch.poly([topL - s * .06, topY - s * .01, topL - s * .06, topY - s * .3, topR + s * .06, topY - s * .13, topR + s * .06, topY - s * .01]),
        fill..color = _hazed(const Color(0xff8a9eaa), haze),
      );
      final ribs = Path();
      for (var k = 1; k < 4; k++) {
        final rx = topL + topW * k / 4;
        ribs
          ..moveTo(rx, topY - s * .02)
          ..lineTo(rx, topY - s * (.29 - .16 * (k / 4)));
      }
      c.drawPath(
        ribs,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.5, s * .03)
          ..color = _hazed(const Color(0xffc8d6dc), haze),
      );
    }
    return Rect.fromLTRB(left, topY, right, at.dy);
  }

  /// A clothes line slung between two houses, a few garments on it.
  static void _hillLaundry(Canvas c, Paint fill, Offset from, Offset to, double s, int sd, double haze) {
    final sag = Offset((from.dx + to.dx) / 2, math.max(from.dy, to.dy) + s * .22);
    c.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(sag.dx, sag.dy + s * .12, to.dx, to.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .03)
        ..color = _hazed(const Color(0xff4a4a54), haze),
    );
    const cloth = [Color(0xffffffff), Color(0xfff2758a), Color(0xff62cfe0), Color(0xfff7e88a)];
    for (var k = 1; k < 4; k++) {
      final t = k / 4;
      final x = from.dx + (to.dx - from.dx) * t;
      final y = (1 - t) * (1 - t) * from.dy + 2 * t * (1 - t) * (sag.dy + s * .12) + t * t * to.dy;
      c.drawRect(Rect.fromLTWH(x - s * .05, y, s * .1, s * .2), fill..color = _hazed(cloth[(sd + k) % cloth.length], haze));
    }
  }

  /// A person seen from far off: a coloured torso and a head.
  static void _hillPerson(Canvas c, Paint fill, Offset feet, double s, int sd, double haze) {
    const shirts = [Color(0xfff2758a), Color(0xff3a86d4), Color(0xffffffff), Color(0xfff7a24a), Color(0xff4fae6a)];
    c.drawRect(
      Rect.fromLTWH(feet.dx - s * .055, feet.dy - s * .42, s * .11, s * .42),
      fill..color = _hazed(shirts[sd % shirts.length], haze),
    );
    c.drawCircle(Offset(feet.dx, feet.dy - s * .5), s * .06, fill..color = _hazed(const Color(0xffb5764e), haze));
  }

  /// Utility poles and the tangle of wires strung between them.
  void _hillWires(Canvas c, double h, double cx, double a, double cy, double b, int seed, double haze, double cap) {
    final poles = <Offset>[];
    for (var i = 0; i < 4; i++) {
      final u = -.66 + .4 * i + .1 * (Sketch.hash(seed * 3 + i) - .5);
      poles.add(Offset(cx + u * a, cy - _hillRise(u, b, seed) + cap + h * .012 + h * .02 * Sketch.hash(seed * 4 + i)));
    }
    final stick = Path(), wire = Path();
    final tall = h * .026;
    for (final p in poles) {
      stick
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx, p.dy - tall)
        ..moveTo(p.dx - h * .005, p.dy - tall * .92)
        ..lineTo(p.dx + h * .005, p.dy - tall * .92);
    }
    for (var i = 0; i + 1 < poles.length; i++) {
      final p = poles[i], q = poles[i + 1];
      for (final drop in const [.92, .8]) {
        final from = p + Offset(0, -tall * drop), to = q + Offset(0, -tall * drop);
        wire
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo((from.dx + to.dx) / 2, math.max(from.dy, to.dy) + h * .012, to.dx, to.dy);
      }
    }
    c.drawPath(
      stick,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, h * .0018)
        ..color = _hazed(const Color(0xff4a3a34), haze),
    );
    c.drawPath(
      wire,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .0011)
        ..color = _hazed(const Color(0xff3a3a44), haze + .05),
    );
  }

  /// The zip line's two ends on [_hillZipOn]: a tall tower by the crest and a
  /// low landing on the flank.
  static (Offset, Offset) _hillZip(double cx, double a, double cy, double b, int seed, double h) {
    Offset at(double u, double lift) => Offset(cx + u * a, cy - _hillRise(u, b, seed) - lift);
    return (at(-.16, h * .05), at(-.8, h * .02));
  }

  void _hillZipLine(Canvas c, double h, Offset from, Offset to, double haze) {
    final post = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, h * .0022)
      ..color = _hazed(const Color(0xff5a4a44), haze);
    c.drawLine(from, from + Offset(0, h * .052), post);
    c.drawLine(to, to + Offset(0, h * .022), post);
    c.drawLine(
      from,
      to,
      Paint()
        ..strokeWidth = math.max(.5, h * .0012)
        ..color = _hazed(const Color(0xff33333c), haze),
    );
  }

  /// Someone rides the zip line back and forth, slow enough to be calm.
  void _hillLive(Canvas c, SceneFrame f) {
    final h = f.h, w = f.w;
    final (fx, off, half, top, seed, haze, _) = _hills[_hillZipOn];
    final cy = h * .76;
    final (from, to) = _hillZip(w * fx + h * off, h * half, cy, cy - h * top, seed, h);
    // Clock zero parks the rider mid-line.
    final t = .5 + .46 * math.sin(f.clock * .16);
    final p = Offset.lerp(from, to, t)!;
    final rider = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, h * .0026)
      ..color = _hazed(const Color(0xff2f5fd0), haze);
    c.drawLine(p, p + Offset(0, h * .008), Paint()..color = _hazed(const Color(0xff33333c), haze)..strokeWidth = math.max(.5, h * .0012));
    c.drawLine(p + Offset(0, h * .008), p + Offset(0, h * .017), rider);
    c.drawCircle(p + Offset(0, h * .0215), h * .0028, Paint()..color = _hazed(const Color(0xffe9b98a), haze));
  }

  /// A small colonial church on the knoll: cream nave under a tiled gable, a
  /// belfry with a cap and cross, a terrace and stairs.
  void _hillChurch(Canvas c, double h, Offset top, double haze) {
    final q = h * .01;
    final fill = Paint();
    final at = top + Offset(0, q * .5);
    Color cream(double t) => _hazed(Sketch.mix(const Color(0xfffbf1dc), const Color(0xffe6d6b8), t), haze);
    // Terrace wall and steps.
    c.drawPath(
      Sketch.poly([at.dx - q * 7, at.dy - q * .9, at.dx + q * 7.5, at.dy - q * .9, at.dx + q * 7.9, at.dy + q * 2.1, at.dx - q * 7.4, at.dy + q * 2.1]),
      fill..color = _hazed(const Color(0xffc9bda2), haze),
    );
    c.drawRect(Rect.fromLTRB(at.dx - q * 7, at.dy - q * .9, at.dx + q * 7.5, at.dy + q * .3), fill..color = _hazed(const Color(0xffeee6d2), haze));
    c.drawRect(Rect.fromLTRB(at.dx - q * 7.4, at.dy + q * .3, at.dx - q * 3, at.dy + q * 2.1), fill..color = const Color(0x24102030));
    final floor = at.dy - q * .9;
    // Low annex on the left with a tile roof.
    c.drawRect(Rect.fromLTRB(at.dx - q * 6.4, floor - q * 2.2, at.dx - q * 2.6, floor), fill..color = cream(.15));
    c.drawPath(
      Sketch.poly([at.dx - q * 6.8, floor - q * 2.2, at.dx - q * 5.6, floor - q * 3.1, at.dx - q * 3.4, floor - q * 3.1, at.dx - q * 2.2, floor - q * 2.2]),
      fill..color = _hazed(_hillTile, haze),
    );
    // Nave, gable and belfry.
    final nl = at.dx - q * 2.6, nr = at.dx + q * 2.1;
    c.drawRect(Rect.fromLTRB(nl, floor - q * 3.4, nr, floor), fill..color = cream(0));
    c.drawRect(Rect.fromLTRB(nl, floor - q * 3.4, nl + q * 1.0, floor), fill..color = cream(.6));
    c.drawPath(
      Sketch.poly([nl - q * .4, floor - q * 3.4, (nl + nr) / 2, floor - q * 5.6, nr + q * .4, floor - q * 3.4]),
      fill..color = _hazed(_hillTile, haze),
    );
    c.drawPath(
      Sketch.poly([nl + q * .2, floor - q * 3.5, (nl + nr) / 2, floor - q * 5.1, nr - q * .2, floor - q * 3.5]),
      fill..color = cream(0),
    );
    final door = Path()
      ..moveTo((nl + nr) / 2 - q * .55, floor)
      ..lineTo((nl + nr) / 2 - q * .55, floor - q * 1.4)
      ..arcToPoint(Offset((nl + nr) / 2 + q * .55, floor - q * 1.4), radius: Radius.circular(q * .55))
      ..lineTo((nl + nr) / 2 + q * .55, floor)
      ..close();
    c.drawPath(door, fill..color = _hazed(const Color(0xff5a3a2c), haze));
    c.drawCircle(Offset((nl + nr) / 2, floor - q * 2.5), q * .38, fill..color = _hazed(const Color(0xff4a7fc0), haze));
    final tl = nr + q * .1, tr = nr + q * 1.9;
    c.drawRect(Rect.fromLTRB(tl, floor - q * 6.4, tr, floor), fill..color = cream(.1));
    c.drawRect(Rect.fromLTRB(tr - q * .6, floor - q * 6.4, tr, floor), fill..color = cream(0));
    c.drawRect(Rect.fromLTRB(tl, floor - q * 6.4, tl + q * .5, floor), fill..color = cream(.6));
    final belfry = Path()
      ..moveTo((tl + tr) / 2 - q * .42, floor - q * 4.6)
      ..lineTo((tl + tr) / 2 - q * .42, floor - q * 5.4)
      ..arcToPoint(Offset((tl + tr) / 2 + q * .42, floor - q * 5.4), radius: Radius.circular(q * .42))
      ..lineTo((tl + tr) / 2 + q * .42, floor - q * 4.6)
      ..close();
    c.drawPath(belfry, fill..color = _hazed(const Color(0xff4a3a44), haze));
    c.drawPath(
      Sketch.poly([tl - q * .25, floor - q * 6.4, (tl + tr) / 2, floor - q * 8.4, tr + q * .25, floor - q * 6.4]),
      fill..color = _hazed(const Color(0xff4a7fc0), haze),
    );
    c.drawPath(
      Sketch.poly([(tl + tr) / 2, floor - q * 8.4, tr + q * .25, floor - q * 6.4, (tl + tr) / 2, floor - q * 6.4]),
      fill..color = _hazed(const Color(0xff6fa0dc), haze),
    );
    c.drawPath(
      Path()
        ..moveTo((tl + tr) / 2, floor - q * 8.4)
        ..lineTo((tl + tr) / 2, floor - q * 9.5)
        ..moveTo((tl + tr) / 2 - q * .35, floor - q * 9.0)
        ..lineTo((tl + tr) / 2 + q * .35, floor - q * 9.0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, q * .13)
        ..color = _hazed(const Color(0xfff6f1e2), haze),
    );
    // Palms and a cypress frame the square; a few worshippers stand about.
    _hillPalm(c, fill, Offset(at.dx + q * 5.6, floor + q * .3), q * 5.2, 5, haze);
    _hillPalm(c, fill, Offset(at.dx - q * 6.6, floor + q * .3), q * 4.2, 9, haze);
    Scenery.cypress(c, Offset(at.dx + q * 3.9, floor + q * .2), q * 3.6, _hazed(const Color(0xff2a7a4c), haze), _hazed(const Color(0xff5cb26e), haze));
    _hillPerson(c, fill, Offset(at.dx + q * 0.2, floor + q * .55), q * 1.9, 21, haze);
    _hillPerson(c, fill, Offset(at.dx - q * .9, floor + q * .55), q * 1.8, 24, haze);
  }

  /// Copacabana's towers, far behind the left-hand morros: two hazy ranks of
  /// pale slabs with balcony bands, peeking over the hills.
  void _hillTowers(Canvas c, double w, double h) {
    const paints = [Color(0xfff2ece0), Color(0xffe8d8bc), Color(0xffd6e2ea), Color(0xfff0d0c0), Color(0xffe2e0d4)];
    for (var rank = 0; rank < 2; rank++) {
      var x = -h * (.3 - .05 * rank);
      var i = 0;
      while (x < w * .27) {
        final sd = 300 + rank * 70 + i;
        i++;
        final tw = h * (.024 + .02 * Sketch.hash(sd)), th = h * (.15 + .07 * Sketch.hash(sd + 1) - .02 * rank);
        final haze = .5 - .1 * rank;
        final base = h * .72;
        final lean = Sketch.hash(sd + 2);
        final tone = _hazed(paints[(lean * paints.length).floor() % paints.length], haze);
        final box = Rect.fromLTWH(x, base - th, tw, th);
        final fill = Paint()..color = tone;
        c.drawRect(box, fill);
        c.drawRect(Rect.fromLTWH(x, base - th, tw * .32, th), fill..color = _hazed(const Color(0xff7d8fa0), haze + .18).withValues(alpha: .28));
        final bands = Path();
        for (var y = base - th + h * .012; y < base; y += h * .0078) {
          bands
            ..moveTo(x + tw * .06, y)
            ..lineTo(x + tw * .94, y);
        }
        c.drawPath(
          bands,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.6, h * .0021)
            ..color = _hazed(const Color(0xff8a9cae), haze + .05).withValues(alpha: .5),
        );
        c.drawRect(Rect.fromLTWH(x + tw * .3, base - th - h * .006, tw * .4, h * .006), fill..color = _hazed(const Color(0xffcfc6b8), haze));
        x += tw * (.7 + .5 * Sketch.hash(sd + 3)) + h * .004;
      }
    }
  }

  /// A waterfront of little houses and palms hugging the shore in front of
  /// the peaks, where no tall hill may stand.
  void _hillShore(Canvas c, double w, double h) {
    final fill = Paint();
    for (final (from, to) in [(w * .3 - h * .16, w * .3 + h * .84), (w * .76 - h * .28, w * .76 + h * .56)]) {
      var x = from;
      var i = 0;
      while (x < to) {
        final sd = 1200 + (from * .1).round() + i;
        i++;
        final r = Sketch.hash(sd);
        final y = ridge(Depth.mid, x / h, 0) * h + h * .004;
        if (i % 7 == 0) {
          _hillPalm(c, fill, Offset(x, y), h * (.034 + .014 * r), sd, .3);
        } else if (i % 5 == 0) {
          _hillCrown(c, fill, Offset(x, y - h * .01), h * (.009 + .004 * r), .5, 0, .3);
        } else {
          final bw = h * (.012 + .012 * r), bh = h * (.011 + .014 * Sketch.hash(sd + 1));
          c.drawRect(Rect.fromLTWH(x, y - bh, bw, bh), fill..color = _hazed(_hillPaints[(r * _hillPaints.length).floor() % _hillPaints.length], .3));
          c.drawRect(Rect.fromLTWH(x - h * .001, y - bh - h * .0035, bw + h * .002, h * .0045), fill..color = _hazed(_hillTile, .32));
        }
        x += h * (.016 + .014 * Sketch.hash(sd + 2));
      }
    }
  }

  static const _beachCanopies = [
    (Color(0xffe94f6a), Color(0xfffffcf0)),
    (Color(0xff1fa9d8), Color(0xfffffcf0)),
    (Color(0xffffc238), Color(0xffe0483a)),
  ];

  /// A beach umbrella: sixteen gores (eight in view) alternating colour, lit
  /// on the sun's side, with a scalloped valance, ribs and a finial.
  static void _umbrella(Canvas c, Offset base, double s, int i) {
    final (a, b) = _beachCanopies[i % _beachCanopies.length];
    final tilt = (i.isEven ? .05 : -.06) * s;
    final top = base + Offset(tilt, -s);
    c.drawOval(Rect.fromCenter(center: base, width: s * .18, height: s * .03), Paint()..color = const Color(0xffe8c888));
    c.drawLine(
      base,
      top,
      Paint()
        ..color = const Color(0xff8a6a48)
        ..strokeWidth = math.max(1.2, s * .03)
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      base + Offset(s * .008, 0),
      top + Offset(s * .008, 0),
      Paint()
        ..color = const Color(0xffe0c090)
        ..strokeWidth = math.max(.6, s * .012),
    );
    c.save();
    c.translate(top.dx, top.dy);
    c.rotate(math.atan2(tilt, s));
    final r = s * .56, dome = s * .22, drop = s * .035;
    c.drawOval(
      Rect.fromCenter(center: Offset(0, drop * .9), width: r * 1.9, height: s * .07),
      Paint()..color = Sketch.mix(a, const Color(0xff000000), .45),
    );
    Offset onGore(double phi, double theta) => Offset(
      r * math.sin(phi) * math.cos(theta),
      -dome * math.sin(theta) + drop * math.cos(phi) * math.cos(theta),
    );
    final seam = Path();
    for (var k = 0; k < 8; k++) {
      final p0 = -math.pi / 2 + math.pi * k / 8, p1 = -math.pi / 2 + math.pi * (k + 1) / 8;
      final lit = .5 + .5 * math.sin((p0 + p1) / 2 + .5);
      final paint = k.isEven ? a : b;
      final col = Sketch.mix(Sketch.mix(paint, const Color(0xff1a2a4a), .22), Sketch.mix(paint, const Color(0xffffffff), .16), lit);
      final gore = Path();
      final r0 = onGore(p0, 0);
      gore.moveTo(r0.dx, r0.dy);
      for (var j = 1; j <= 6; j++) {
        final o = onGore(p0, j / 6 * math.pi / 2);
        gore.lineTo(o.dx, o.dy);
      }
      for (var j = 5; j >= 0; j--) {
        final o = onGore(p1, j / 6 * math.pi / 2);
        gore.lineTo(o.dx, o.dy);
      }
      c.drawPath(gore..close(), Paint()..color = col);
      final e1 = onGore(p1, 0);
      c.drawPath(
        Path()
          ..moveTo(r0.dx, r0.dy)
          ..quadraticBezierTo((r0.dx + e1.dx) / 2, (r0.dy + e1.dy) / 2 + s * .07, e1.dx, e1.dy)
          ..close(),
        Paint()..color = Sketch.mix(col, const Color(0xff000000), .07),
      );
      if (k > 0) {
        seam
          ..moveTo(r0.dx, r0.dy)
          ..lineTo(onGore(p0, math.pi / 4).dx, onGore(p0, math.pi / 4).dy)
          ..lineTo(0, -dome);
      }
    }
    c.drawPath(
      seam,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .004)
        ..color = const Color(0x30203040),
    );
    c.drawOval(Rect.fromCenter(center: Offset(r * .34, -dome * .62), width: r * .5, height: dome * .18), Paint()..color = const Color(0x2effffff));
    c.drawLine(Offset(0, -dome), Offset(0, -dome - s * .05), Paint()..color = _cream..strokeWidth = math.max(.8, s * .012));
    c.drawCircle(Offset(0, -dome - s * .055), s * .014, Paint()..color = _cream);
    c.restore();
  }

  /// A folding beach chair in side view, striped cloth on a light frame.
  static void _beachChair(Canvas c, Offset base, double s, Color cloth) {
    _beachShadow(c, base + Offset(-s * .25, s * .02), s * 1.1, s * .16, .2);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, s * .05)
      ..color = const Color(0xffb4aca0);
    Offset p(double x, double y) => base + Offset(-x * s, y * s);
    c.drawLine(p(.34, -.34), p(.44, 0), frame);
    c.drawLine(p(-.04, -.2), p(-.3, 0), frame);
    c.drawLine(p(.44, 0), p(-.02, -.24), frame..strokeWidth = math.max(.7, s * .035));
    final seat = [p(-.12, -.26), p(.38, -.4), p(.38, -.3), p(-.12, -.16)];
    c.drawPath(Sketch.poly([for (final q in seat) ...[q.dx, q.dy]]), Paint()..color = cloth);
    // Backrest: three cloth stripes.
    for (var k = 0; k < 3; k++) {
      final t0 = k / 3, t1 = (k + 1) / 3;
      Offset l(double t) => p(-.1 + (-.4 + .1) * t, -.2 + (-.88 + .2) * t);
      Offset r(double t) => p(0 + (-.28 - 0) * t, -.2 + (-.9 + .2) * t);
      c.drawPath(
        Sketch.poly([l(t0).dx, l(t0).dy, r(t0).dx, r(t0).dy, r(t1).dx, r(t1).dy, l(t1).dx, l(t1).dy]),
        Paint()..color = k.isEven ? cloth : _cream,
      );
    }
  }

  /// A sunbather on a striped towel, with sandals and a book beside.
  static void _beachTowel(Canvas c, Offset at, double w, int i) {
    final skin = i.isEven ? const Color(0xffc48a5a) : const Color(0xff8a5a3a);
    final suit = i.isEven ? const Color(0xfff6e26a) : const Color(0xffe94f6a);
    final tone = i.isEven ? const Color(0xffe94f6a) : const Color(0xff2fb5d8);
    final t = w * .15;
    _beachShadow(c, at + Offset(-w * .05, t * .8), w * 1.08, t * .8, .22);
    // Towel with bands and fringe.
    c.drawPath(
      Sketch.poly([at.dx, at.dy, at.dx + w, at.dy - t * .25, at.dx + w * 1.02, at.dy + t * .55, at.dx + w * .02, at.dy + t * .8]),
      Paint()..color = tone,
    );
    for (var k = 0; k < 3; k++) {
      final x0 = at.dx + w * (.22 + k * .25), x1 = x0 + w * .07;
      final u0 = (x0 - at.dx) / w, u1 = (x1 - at.dx) / w;
      c.drawPath(
        Sketch.poly([x0, at.dy - t * .25 * u0, x1, at.dy - t * .25 * u1, x1, at.dy + t * .8 - t * .25 * u1, x0, at.dy + t * .8 - t * .25 * u0]),
        Paint()..color = _cream.withValues(alpha: .85),
      );
    }
    final fringe = Paint()
      ..strokeWidth = math.max(.5, w * .006)
      ..color = tone.withValues(alpha: .8);
    for (var k = 0; k < 6; k++) {
      final y = at.dy + t * (.05 + k * .13);
      c.drawLine(Offset(at.dx - w * .012, y), Offset(at.dx, y + t * .02), fringe);
      c.drawLine(Offset(at.dx + w * 1.02, y - t * .2), Offset(at.dx + w * 1.035, y - t * .2), fringe);
    }
    // The sunbather, head to the left, one knee raised.
    final y = at.dy + t * .1;
    final limb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * .05;
    c.drawLine(Offset(at.dx + w * .44, y - w * .03), Offset(at.dx + w * .86, y - w * .02), limb..color = Sketch.mix(skin, const Color(0xff000000), .15));
    c.drawPath(
      Path()
        ..moveTo(at.dx + w * .44, y - w * .03)
        ..lineTo(at.dx + w * .6, y - w * .13)
        ..lineTo(at.dx + w * .76, y - w * .03),
      limb
        ..color = skin
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawRRect(RRect.fromLTRBR(at.dx + w * .14, y - w * .085, at.dx + w * .46, y + w * .01, Radius.circular(w * .04)), Paint()..color = skin);
    c.drawRRect(RRect.fromLTRBR(at.dx + w * .36, y - w * .085, at.dx + w * .5, y + w * .012, Radius.circular(w * .03)), Paint()..color = suit);
    c.drawCircle(Offset(at.dx + w * .11, y - w * .045), w * .055, Paint()..color = skin);
    c.drawArc(Rect.fromCircle(center: Offset(at.dx + w * .11, y - w * .045), radius: w * .058), math.pi * .9, math.pi * 1.1, true, Paint()..color = i.isEven ? const Color(0xff2a2020) : const Color(0xff5a3a24));
    c.drawRect(Rect.fromLTWH(at.dx + w * .125, y - w * .06, w * .045, w * .014), Paint()..color = const Color(0xff26303a));
    for (final dx in const [1.06, 1.12]) {
      c.drawOval(Rect.fromCenter(center: Offset(at.dx + w * dx, y + w * .03), width: w * .05, height: w * .02), Paint()..color = suit);
    }
    c.drawRect(Rect.fromLTWH(at.dx + w * .68, y + t * .5, w * .07, w * .01), Paint()..color = const Color(0xff3a6a9a));
  }

  /// A quiosque: thatched roof, painted planks, a counter of coconuts and
  /// bottles, a sign, bunting, stools and a cooler.
  static void _beachKiosk(Canvas c, Offset base, double w) {
    final x = base.dx, y = base.dy;
    _beachShadow(c, Offset(x - w * .2, y + w * .02), w * 1.3, w * .09, .2);
    c.drawRect(Rect.fromLTRB(x - w * .53, y - w * .03, x + w * .53, y), Paint()..color = _beachWood);
    c.drawRect(Rect.fromLTRB(x - w * .53, y - w * .03, x + w * .53, y - w * .024), Paint()..color = const Color(0xffd2a06a));
    // Back wall of painted planks, with shelves and bottles.
    final wall = Rect.fromLTRB(x - w * .47, y - w * .36, x + w * .47, y - w * .03);
    c.drawRect(wall, Paint()..color = const Color(0xff69cbc4));
    c.drawRect(Rect.fromLTRB(x - w * .47, wall.top, x - w * .1, wall.bottom), Paint()..color = const Color(0x18103040));
    final plank = Paint()
      ..strokeWidth = math.max(.5, w * .004)
      ..color = const Color(0x2a1a5a5a);
    for (var k = 1; k < 16; k++) {
      c.drawLine(Offset(x - w * .47 + w * .94 * k / 16, wall.top), Offset(x - w * .47 + w * .94 * k / 16, wall.bottom), plank);
    }
    c.drawRect(Rect.fromLTRB(x - w * .4, y - w * .215, x + w * .16, y - w * .2), Paint()..color = const Color(0xff7a5a3a));
    const bottles = [Color(0xffe94f6a), Color(0xffffc238), Color(0xff3cb371), Color(0xffffffff), Color(0xffe0483a), Color(0xff2fb5d8), Color(0xffffc238), Color(0xffe94f6a)];
    for (var k = 0; k < bottles.length; k++) {
      final bx = x - w * .38 + k * w * .07;
      c.drawRRect(RRect.fromLTRBR(bx, y - w * .29, bx + w * .035, y - w * .215, Radius.circular(w * .01)), Paint()..color = bottles[k]);
      c.drawRect(Rect.fromLTRB(bx + w * .01, y - w * .32, bx + w * .025, y - w * .29), Paint()..color = bottles[k]);
    }
    // Menu board.
    c.drawRRect(RRect.fromLTRBR(x + w * .24, y - w * .31, x + w * .43, y - w * .14, Radius.circular(w * .01)), Paint()..color = const Color(0xff2c4a3a));
    for (var k = 0; k < 4; k++) {
      c.drawRect(Rect.fromLTWH(x + w * .27, y - w * .28 + k * w * .035, w * (.09 + .04 * Sketch.hash(k + 800)), w * .012), Paint()..color = const Color(0xdfffffff));
    }
    // Counter.
    c.drawRect(Rect.fromLTRB(x - w * .5, y - w * .14, x + w * .38, y - w * .03), Paint()..color = const Color(0xffc9925a));
    c.drawRect(Rect.fromLTRB(x - w * .5, y - w * .14, x - w * .1, y - w * .03), Paint()..color = const Color(0x20301a08));
    for (var k = 0; k < 6; k++) {
      c.drawRect(Rect.fromLTWH(x - w * .48 + k * w * .146, y - w * .125, w * .07, w * .085), Paint()..color = k.isEven ? const Color(0xff3cb371) : const Color(0xffffd23a));
    }
    c.drawRRect(RRect.fromLTRBR(x - w * .53, y - w * .165, x + w * .41, y - w * .14, Radius.circular(w * .008)), Paint()..color = const Color(0xffe6b878));
    for (var k = 0; k < 4; k++) {
      final cx = x - w * .36 + k * w * .09;
      c.drawCircle(Offset(cx, y - w * .195), w * .03, Paint()..color = const Color(0xff8fa842));
      c.drawCircle(Offset(cx + w * .01, y - w * .205), w * .011, Paint()..color = const Color(0xffc4d878));
    }
    for (final gx in const [.06, .12, .2]) {
      c.drawRect(Rect.fromLTWH(x + w * gx, y - w * .215, w * .03, w * .05), Paint()..color = const Color(0xaaeaf8f8));
      c.drawLine(Offset(x + w * gx + w * .022, y - w * .215), Offset(x + w * gx + w * .03, y - w * .25), Paint()..color = const Color(0xffe0483a)..strokeWidth = math.max(.5, w * .006));
    }
    // Posts.
    for (final px in const [-.5, .43]) {
      c.drawRect(Rect.fromLTRB(x + w * px, y - w * .39, x + w * (px + .04), y - w * .03), Paint()..color = const Color(0xff8a5f38));
    }
    // Sign hung from the eave.
    c.drawRRect(RRect.fromLTRBR(x - w * .17, y - w * .35, x + w * .17, y - w * .26, Radius.circular(w * .012)), Paint()..color = const Color(0xffffd23a));
    c.drawRRect(
      RRect.fromLTRBR(x - w * .17, y - w * .35, x + w * .17, y - w * .26, Radius.circular(w * .012)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, w * .008)
        ..color = const Color(0xff2f8f4a),
    );
    c.drawCircle(Offset(x - w * .1, y - w * .305), w * .028, Paint()..color = const Color(0xff2f8f4a));
    c.drawCircle(Offset(x - w * .09, y - w * .315), w * .01, Paint()..color = const Color(0xff8fd07a));
    for (var k = 0; k < 2; k++) {
      c.drawRect(Rect.fromLTWH(x - w * .05, y - w * .335 + k * w * .035, w * (.16 - k * .04), w * .016), Paint()..color = const Color(0xff2f8f4a));
    }
    // Thatched roof: shaded left, lit right, straw strands along the eave.
    final ridge = Offset(x, y - w * .74);
    final roof = Path()
      ..moveTo(x - w * .68, y - w * .37)
      ..quadraticBezierTo(x - w * .32, y - w * .52, ridge.dx - w * .03, ridge.dy)
      ..lineTo(ridge.dx + w * .03, ridge.dy)
      ..quadraticBezierTo(x + w * .32, y - w * .52, x + w * .68, y - w * .37);
    for (var k = 24; k >= 0; k--) {
      roof.lineTo(x - w * .68 + w * 1.36 * k / 24, y - w * .37 + (k.isEven ? w * .055 : w * .01) + w * .02 * Sketch.hash(k + 820));
    }
    c.drawPath(roof..close(), Paint()..color = _beachStraw);
    c.drawPath(
      Path()
        ..moveTo(x + w * .01, y - w * .74)
        ..lineTo(ridge.dx + w * .03, ridge.dy)
        ..quadraticBezierTo(x + w * .32, y - w * .52, x + w * .68, y - w * .37)
        ..lineTo(x + w * .68, y - w * .32)
        ..lineTo(x + w * .01, y - w * .32)
        ..close(),
      Paint()..color = const Color(0x4ffff0b0),
    );
    c.drawPath(
      Path()
        ..moveTo(x - w * .68, y - w * .37)
        ..quadraticBezierTo(x - w * .32, y - w * .52, ridge.dx - w * .03, ridge.dy)
        ..lineTo(x - w * .01, y - w * .32)
        ..lineTo(x - w * .68, y - w * .32)
        ..close(),
      Paint()..color = const Color(0x40603a10),
    );
    final layers = Path();
    for (var k = 1; k <= 4; k++) {
      final yy = y - w * (.4 + k * .07), half = w * (.66 - k * .13);
      layers
        ..moveTo(x - half, yy + w * .02 * k)
        ..quadraticBezierTo(x, yy - w * .02, x + half, yy + w * .02 * k);
    }
    c.drawPath(
      layers,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, w * .006)
        ..color = const Color(0x55704a14),
    );
    final tuft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.7, w * .012)
      ..color = const Color(0xffb88a3a);
    for (var k = -2; k <= 2; k++) {
      c.drawLine(Offset(ridge.dx + k * w * .012, ridge.dy + w * .01), Offset(ridge.dx + k * w * .03, ridge.dy - w * .05), tuft);
    }
    c.drawLine(Offset(ridge.dx, ridge.dy), Offset(ridge.dx, ridge.dy - w * .16), Paint()..color = const Color(0xff6a4a2a)..strokeWidth = math.max(.8, w * .008));
    // Bunting along the eave.
    final l = Offset(x - w * .66, y - w * .33), r = Offset(x + w * .66, y - w * .33);
    const flags = [Color(0xff3cb371), Color(0xffffd23a), Color(0xff2f5fd0), Color(0xffffffff)];
    Offset string(double t) => Offset.lerp(l, r, t)! + Offset(0, math.sin(t * math.pi) * w * .06);
    for (var k = 0; k < 11; k++) {
      final p0 = string((k + .5) / 12), p1 = string((k + 1.5) / 12);
      c.drawPath(Sketch.poly([p0.dx, p0.dy, p1.dx, p1.dy, (p0.dx + p1.dx) / 2, p0.dy + w * .05]), Paint()..color = flags[k % 4]);
    }
    // Stools, a stack of green coconuts and a cooler.
    for (final sx in const [-.3, -.02]) {
      final st = Offset(x + w * sx, y + w * .06);
      c.drawLine(st + Offset(-w * .025, 0), st + Offset(-w * .035, -w * .09), Paint()..color = const Color(0xff5a4030)..strokeWidth = math.max(.8, w * .01));
      c.drawLine(st + Offset(w * .025, 0), st + Offset(w * .035, -w * .09), Paint()..color = const Color(0xff5a4030)..strokeWidth = math.max(.8, w * .01));
      c.drawOval(Rect.fromCenter(center: st + Offset(0, -w * .095), width: w * .1, height: w * .03), Paint()..color = const Color(0xffe94f6a));
    }
    for (final (dx, dy) in const [(.6, 0.0), (.68, 0.0), (.76, 0.0), (.64, -.07), (.72, -.07), (.68, -.14)]) {
      final p = Offset(x + w * dx, y + w * .03 + w * dy);
      c.drawCircle(p, w * .04, Paint()..color = const Color(0xff7fa03c));
      c.drawCircle(p + Offset(w * .012, -w * .012), w * .015, Paint()..color = const Color(0xffbcd66a));
    }
    c.drawRRect(RRect.fromLTRBR(x - w * .82, y - w * .06, x - w * .62, y + w * .03, Radius.circular(w * .01)), Paint()..color = const Color(0xff2f8fd0));
    c.drawRect(Rect.fromLTRB(x - w * .83, y - w * .08, x - w * .61, y - w * .055), Paint()..color = const Color(0xfff2f6f8));
  }

  /// Surfboards planted upright in the sand, leaning a little.
  static void _beachBoards(Canvas c, Offset base, double h) {
    for (final (k, (dx, len, lean, color, stripe)) in const [
      (0.0, .15, -.1, Color(0xfff2745a), Color(0xfffffcf0)),
      (.03, .135, .03, Color(0xff2fb5d8), Color(0xfffff0a0)),
      (.06, .155, .12, Color(0xffffc238), Color(0xffe0483a)),
    ].indexed) {
      final at = base + Offset(dx * h, k.isEven ? 0 : h * .006);
      final l = len * h, w = h * .034;
      _beachShadow(c, at + Offset(-h * .02, h * .002), h * .06, h * .01, .2);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(lean);
      final body = Path()
        ..moveTo(-w * .42, 0)
        ..lineTo(-w * .5, -l * .7)
        ..quadraticBezierTo(-w * .5, -l * .96, 0, -l)
        ..quadraticBezierTo(w * .5, -l * .96, w * .5, -l * .7)
        ..lineTo(w * .42, 0)
        ..close();
      c.drawPath(body, Paint()..color = color);
      c.save();
      c.clipPath(body);
      c.drawRect(Rect.fromLTRB(w * .1, -l, w * .6, 0), Paint()..color = const Color(0x30ffffff));
      c.drawRect(Rect.fromLTRB(-w * .6, -l, -w * .2, 0), Paint()..color = const Color(0x22000000));
      c.drawRect(Rect.fromLTRB(-w, -l * .52, w, -l * .44), Paint()..color = stripe);
      c.drawRect(Rect.fromLTRB(-w, -l * .40, w, -l * .38), Paint()..color = stripe);
      c.restore();
      c.drawLine(Offset(0, -l * .02), Offset(0, -l * .98), Paint()..color = const Color(0x40000000)..strokeWidth = math.max(.5, w * .05));
      c.restore();
      c.drawOval(Rect.fromCenter(center: at, width: h * .04, height: h * .008), Paint()..color = const Color(0xffe8c888));
    }
  }

  /// A futevôlei net on two poles, guy ropes, court tape and a ball.
  static void _beachNet(Canvas c, Offset base, double w) {
    final x0 = base.dx, x1 = base.dx + w, hgt = w * .44;
    _beachShadow(c, base + Offset(w * .3, w * .02), w * 1.1, w * .04, .12);
    final pole = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, w * .018)
      ..color = const Color(0xffefe6d0);
    final rope = Paint()
      ..strokeWidth = math.max(.5, w * .005)
      ..color = const Color(0xaa6a5a4a);
    c.drawLine(Offset(x0, base.dy - hgt), Offset(x0 - w * .12, base.dy + w * .012), rope);
    c.drawLine(Offset(x1, base.dy - hgt), Offset(x1 + w * .12, base.dy + w * .012), rope);
    final net = Path();
    for (var k = 0; k <= 16; k++) {
      final t = k / 16, sag = math.sin(t * math.pi) * w * .025;
      final top = Offset(x0 + w * t, base.dy - hgt + sag), bottom = Offset(x0 + w * t, base.dy - hgt * .62 + sag * .6);
      net
        ..moveTo(top.dx, top.dy)
        ..lineTo(bottom.dx, bottom.dy);
    }
    for (var k = 1; k <= 4; k++) {
      final f = k / 5;
      net.moveTo(x0, base.dy - hgt + hgt * .38 * f);
      for (var m = 1; m <= 16; m++) {
        final t = m / 16, sag = math.sin(t * math.pi) * w * (.025 - .01 * f);
        net.lineTo(x0 + w * t, base.dy - hgt + hgt * .38 * f + sag);
      }
    }
    c.drawPath(net, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.5, w * .004)..color = const Color(0x88f6faff));
    final tape = Path()..moveTo(x0, base.dy - hgt);
    for (var m = 1; m <= 16; m++) {
      final t = m / 16;
      tape.lineTo(x0 + w * t, base.dy - hgt + math.sin(t * math.pi) * w * .025);
    }
    c.drawPath(tape, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(1.2, w * .014)..color = const Color(0xfffffcf0));
    c.drawLine(Offset(x0 + w * .02, base.dy - hgt * .62), Offset(x1 - w * .02, base.dy - hgt * .62), Paint()..color = const Color(0xffe0483a)..strokeWidth = math.max(.8, w * .008));
    c.drawLine(Offset(x0, base.dy + w * .01), Offset(x0, base.dy - hgt), pole);
    c.drawLine(Offset(x1, base.dy + w * .01), Offset(x1, base.dy - hgt), pole);
    c.drawLine(Offset(x0 + w * .02, base.dy - hgt), Offset(x0 + w * .02, base.dy + w * .01), Paint()..color = const Color(0x33000000)..strokeWidth = math.max(.5, w * .006));
    // Court tape on the sand and a ball resting by the pole.
    final court = Paint()
      ..strokeWidth = math.max(.8, w * .01)
      ..color = const Color(0xccffffff);
    c.drawLine(Offset(x0 - w * .25, base.dy + w * .028), Offset(x1 + w * .25, base.dy + w * .028), court);
    final ball = Offset(x1 + w * .16, base.dy + w * .05);
    c.drawCircle(ball, w * .035, Paint()..color = _cream);
    c.drawCircle(ball, w * .035, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(.5, w * .005)..color = const Color(0xff2f5fd0));
    c.drawCircle(ball + Offset(w * .008, -w * .006), w * .012, Paint()..color = const Color(0xffffd23a));
  }

  /// A beach vendor in a straw hat, cangas draped over one arm.
  static void _beachVendor(Canvas c, Offset feet, double s) {
    const d = -1.0;
    _beachShadow(c, feet + Offset(-s * .1, s * .02), s * .6, s * .07, .22);
    const skin = Color(0xffb47848);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final hip = feet + Offset(0, -s * .46);
    c.drawLine(hip, feet + Offset(d * s * .13, -s * .02), line..strokeWidth = s * .095..color = Sketch.mix(skin, const Color(0xff000000), .2));
    c.drawLine(hip, feet + Offset(-d * s * .1, -s * .02), line..strokeWidth = s * .1..color = skin);
    c.drawLine(feet + Offset(d * s * .13, -s * .02), feet + Offset(d * s * .2, -s * .01), line..strokeWidth = s * .05..color = const Color(0xff26303a));
    c.drawLine(feet + Offset(-d * s * .1, -s * .02), feet + Offset(-d * s * .03, -s * .01), line);
    c.drawRRect(RRect.fromLTRBR(hip.dx - s * .14, hip.dy - s * .08, hip.dx + s * .14, hip.dy + s * .1, Radius.circular(s * .04)), Paint()..color = const Color(0xff2f8fd0));
    c.drawRRect(RRect.fromLTRBR(hip.dx - s * .14, hip.dy - s * .4, hip.dx + s * .14, hip.dy - s * .04, Radius.circular(s * .06)), Paint()..color = const Color(0xffffe04a));
    c.drawRect(Rect.fromLTRB(hip.dx + s * .04, hip.dy - s * .4, hip.dx + s * .14, hip.dy - s * .04), Paint()..color = const Color(0x22ffffff));
    // Arm out front with cangas hanging from it.
    final shoulder = hip + Offset(d * s * .02, -s * .36);
    final hand = shoulder + Offset(d * s * .2, s * .1);
    c.drawLine(shoulder, hand, line..strokeWidth = s * .075..color = skin);
    const cangas = [Color(0xffe94f6a), Color(0xff2fb5d8), Color(0xffffc238), Color(0xff7bbf5a)];
    for (var k = 0; k < 4; k++) {
      final top = hand + Offset(-d * s * .02 + d * k * s * .035, -s * .01);
      c.drawPath(
        Sketch.poly([top.dx, top.dy, top.dx + s * .07, top.dy, top.dx + s * .075, top.dy + s * (.36 - k * .03), top.dx + s * .005, top.dy + s * (.34 - k * .03)]),
        Paint()..color = cangas[k],
      );
      c.drawRect(Rect.fromLTWH(top.dx + s * .005, top.dy + s * .12, s * .068, s * .03), Paint()..color = const Color(0x66ffffff));
    }
    final head = shoulder + Offset(d * s * .03, -s * .1);
    c.drawCircle(head, s * .085, Paint()..color = skin);
    c.drawOval(Rect.fromCenter(center: head + Offset(0, -s * .06), width: s * .34, height: s * .06), Paint()..color = const Color(0xffe8c060));
    c.drawPath(
      Path()
        ..moveTo(head.dx - s * .09, head.dy - s * .06)
        ..quadraticBezierTo(head.dx, head.dy - s * .19, head.dx + s * .09, head.dy - s * .06)
        ..close(),
      Paint()..color = const Color(0xffd6a650),
    );
    c.drawRect(Rect.fromLTRB(head.dx - s * .09, head.dy - s * .075, head.dx + s * .09, head.dy - s * .055), Paint()..color = const Color(0xffe94f6a));
  }

  /// A sandcastle with three towers, crenellations, a moat, a bucket and spade.
  static void _beachCastle(Canvas c, Offset base, double w) {
    final x = base.dx, y = base.dy;
    c.drawOval(Rect.fromCenter(center: Offset(x, y - w * .02), width: w * 1.5, height: w * .2), Paint()..color = const Color(0x3a805a28));
    c.drawOval(Rect.fromCenter(center: Offset(x + w * .02, y - w * .03), width: w * 1.3, height: w * .15), Paint()..color = const Color(0xffe8c888));
    _beachShadow(c, Offset(x - w * .4, y), w * 1.3, w * .1, .2);
    void block(double l, double t, double r, double b) {
      c.drawRect(Rect.fromLTRB(x + w * l, y + w * t, x + w * r, y + w * b), Paint()..color = const Color(0xffe2be7e));
      c.drawRect(Rect.fromLTRB(x + w * (l + (r - l) * .6), y + w * t, x + w * r, y + w * b), Paint()..color = const Color(0xffefd090));
      c.drawRect(Rect.fromLTRB(x + w * l, y + w * t, x + w * (l + (r - l) * .22), y + w * b), Paint()..color = const Color(0xffc9a05a));
    }

    void merlons(double l, double r, double t, int n) {
      final mw = (r - l) / (2 * n - 1);
      for (var k = 0; k < n; k++) {
        block(l + k * 2 * mw, t - w * .06 / w, l + k * 2 * mw + mw, t);
      }
    }

    block(-.5, -.24, .5, 0);
    block(-.17, -.5, .17, -.24);
    merlons(-.17, .17, -.5, 3);
    block(-.5, -.42, -.27, -.24);
    merlons(-.5, -.27, -.42, 2);
    block(.27, -.36, .5, -.24);
    merlons(.27, .5, -.36, 2);
    c.drawPath(
      Path()
        ..moveTo(x - w * .07, y)
        ..lineTo(x - w * .07, y - w * .09)
        ..quadraticBezierTo(x, y - w * .17, x + w * .07, y - w * .09)
        ..lineTo(x + w * .07, y)
        ..close(),
      Paint()..color = const Color(0xff7a5a30),
    );
    for (final (wx, wy) in const [(-.03, -.4), (.05, -.4), (-.42, -.34), (.38, -.3)]) {
      c.drawRect(Rect.fromLTWH(x + w * wx, y + w * wy, w * .03, w * .07), Paint()..color = const Color(0xff7a5a30));
    }
    c.drawLine(Offset(x, y - w * .56), Offset(x, y - w * .95), Paint()..color = const Color(0xff8a6a48)..strokeWidth = math.max(.7, w * .014));
    for (final (sx, sy) in const [(-.44, -.1), (-.3, -.06), (.3, -.08), (.44, -.05)]) {
      c.drawCircle(Offset(x + w * sx, y + w * sy), w * .022, Paint()..color = const Color(0xfff6e6d0));
    }
    // Bucket and spade.
    final bx = x + w * .78, by = y + w * .02;
    c.drawPath(Sketch.poly([bx - w * .12, by - w * .2, bx + w * .12, by - w * .2, bx + w * .09, by, bx - w * .09, by]), Paint()..color = const Color(0xffe94f6a));
    c.drawRect(Rect.fromLTRB(bx - w * .11, by - w * .14, bx + w * .11, by - w * .1), Paint()..color = const Color(0xffffd23a));
    c.drawRect(Rect.fromLTRB(bx + w * .04, by - w * .2, bx + w * .12, by - w * .02), Paint()..color = const Color(0x28ffffff));
    c.drawLine(Offset(bx + w * .22, by), Offset(bx + w * .3, by - w * .22), Paint()..color = const Color(0xff2f8fd0)..strokeWidth = math.max(.8, w * .03)..strokeCap = StrokeCap.round);
  }

  /// A few living touches drawn each frame: waders on the swash line, the
  /// flags on the kiosk and the sandcastle.
  void _beachLife(Canvas c, SceneFrame f, double presence) {
    final h = f.h;
    for (var i = 0; i < 2; i++) {
      final phase = f.clock * .35 + i * 2.6;
      final x = h * (i == 0 ? 1.85 : .42) + h * .12 * math.sin(phase);
      final dir = math.cos(phase) >= 0 ? 1.0 : -1.0;
      final y = _nearY(x, h) + h * (.029 + .004 * i);
      final s = h * .011;
      final leg = Paint()
        ..strokeWidth = math.max(.6, s * .12)
        ..strokeCap = StrokeCap.round
        ..color = Sketch.fade(const Color(0xff4a3a30), presence);
      final flick = math.sin(f.clock * 15 + i) * s * .35;
      c.drawLine(Offset(x, y - s * .5), Offset(x + flick, y + s * .35), leg);
      c.drawLine(Offset(x, y - s * .5), Offset(x - flick, y + s * .35), leg);
      c.drawOval(Rect.fromCenter(center: Offset(x, y - s * .75), width: s * 1.5, height: s * .9), Paint()..color = Sketch.fade(const Color(0xffefeadc), presence));
      c.drawOval(Rect.fromCenter(center: Offset(x - dir * s * .12, y - s * .95), width: s * 1.2, height: s * .55), Paint()..color = Sketch.fade(const Color(0xff8a7a68), presence));
      c.drawCircle(Offset(x + dir * s * .65, y - s * 1.05), s * .28, Paint()..color = Sketch.fade(const Color(0xff8a7a68), presence));
      c.drawLine(Offset(x + dir * s * .85, y - s * 1.05), Offset(x + dir * s * 1.5, y - s * .95), leg);
    }
    // Flags flutter in the sea breeze.
    void flag(Offset pole, double len, Color color, double phase) {
      final wave = math.sin(f.clock * 4 + phase) * len * .12;
      c.drawPath(
        Path()
          ..moveTo(pole.dx, pole.dy)
          ..quadraticBezierTo(pole.dx - len * .5, pole.dy + wave, pole.dx - len, pole.dy + wave * 1.5 + len * .03)
          ..lineTo(pole.dx - len, pole.dy + len * .5 + wave)
          ..quadraticBezierTo(pole.dx - len * .5, pole.dy + len * .5 - wave, pole.dx, pole.dy + len * .5)
          ..close(),
        Paint()..color = Sketch.fade(color, presence),
      );
    }

    final k = _beachKioskBase(h), kw = h * _beachKioskW;
    flag(Offset(k.dx, k.dy - kw * .9), kw * .2, const Color(0xff3cb371), 0);
    final cb = _beachCastleBase(h), cw = h * .085;
    flag(Offset(cb.dx, cb.dy - cw * .95), cw * .3, const Color(0xffe94f6a), 1.7);
  }

  /// A football goal seen from the front, a little from the right: round
  /// posts and crossbar, the ground frame, and netting over the back, right
  /// side and roof. [s] is the mouth width; [base] is the left post's foot.
  static void _goal(Canvas c, Offset base, double s) {
    final hg = s * .5;
    final o = Offset(s * .2, -hg * .32);
    final f0 = base, f1 = base + Offset(s, 0);
    final t0 = f0 - Offset(0, hg), t1 = f1 - Offset(0, hg);
    final b0 = f0 + o, b1 = f1 + o, u0 = t0 + o, u1 = t1 + o;
    Path quad(Offset a, Offset b, Offset d, Offset e) => Sketch.poly([a.dx, a.dy, b.dx, b.dy, d.dx, d.dy, e.dx, e.dy]);
    // Its shadow falls left and toward the viewer, away from the sun.
    c.drawPath(quad(f0, f1, b1, b0), Paint()..color = const Color(0x1f6a4a1c));
    c.drawPath(
      quad(f0, Offset(f0.dx - hg * .7, f0.dy + hg * .16), Offset(f1.dx - hg * .7, f1.dy + hg * .16), f1),
      Paint()..color = const Color(0x186a4a1c),
    );
    // Sheets of net: the back one in shade so it reads through the mouth.
    c.drawPath(quad(b0, b1, u1, u0), Paint()..color = const Color(0x2c5a7a8a));
    final sheet = Paint()..color = const Color(0x26ffffff);
    c.drawPath(quad(f1, b1, u1, t1), sheet);
    c.drawPath(quad(t0, t1, u1, u0), sheet);
    void mesh(Path p, Offset bl, Offset br, Offset tr, Offset tl, int nu, int nv) {
      for (var i = 1; i < nu; i++) {
        final k = i / nu;
        p
          ..moveTo(Offset.lerp(bl, br, k)!.dx, Offset.lerp(bl, br, k)!.dy)
          ..lineTo(Offset.lerp(tl, tr, k)!.dx, Offset.lerp(tl, tr, k)!.dy);
      }
      for (var j = 1; j < nv; j++) {
        final k = j / nv;
        p
          ..moveTo(Offset.lerp(bl, tl, k)!.dx, Offset.lerp(bl, tl, k)!.dy)
          ..lineTo(Offset.lerp(br, tr, k)!.dx, Offset.lerp(br, tr, k)!.dy);
      }
    }

    final net = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, s * .006);
    final back = Path();
    mesh(back, b0, b1, u1, u0, 14, 7);
    c.drawPath(back, net..color = const Color(0x806f8794));
    final lit = Path();
    mesh(lit, f1, b1, u1, t1, 5, 7);
    mesh(lit, t0, t1, u1, u0, 14, 4);
    c.drawPath(lit, net..color = const Color(0xccf2f8fa));
    // Frame: thin rear and ground tubes, then the round front posts.
    final pw = math.max(1.8, s * .03);
    final tube = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = pw * .5
      ..color = const Color(0xffe2eaee);
    for (final (a, b) in [(b0, b1), (u0, u1), (b1, u1), (f1, b1), (t1, u1), (t0, u0)]) {
      c.drawLine(a, b, tube);
    }
    tube.color = const Color(0x99e2eaee);
    c.drawLine(f0, b0, tube);
    c.drawLine(b0, u0, tube);
    final post = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = pw
      ..color = const Color(0xffa9bac4);
    for (final (a, b) in [(f0, t0), (f1, t1), (t0, t1)]) {
      c.drawLine(a, b, post);
    }
    post
      ..strokeWidth = pw * .62
      ..color = const Color(0xfffbfbf3);
    c.drawLine(f0 + Offset(pw * .14, 0), t0 + Offset(pw * .14, 0), post);
    c.drawLine(f1 + Offset(pw * .14, 0), t1 + Offset(pw * .14, 0), post);
    c.drawLine(t0 + Offset(0, -pw * .14), t1 + Offset(0, -pw * .14), post);
  }

  /// The football: shaded cream leather with navy panels that turn as it rolls.
  static void _ball(Canvas c, Offset at, double r, double spin) {
    final fill = Paint()..color = Sketch.mix(_cream, const Color(0xff5a7a9a), .32);
    c.drawCircle(at, r, fill);
    c.drawCircle(at + Offset(r * .14, -r * .14), r * .84, fill..color = _cream);
    fill.color = _navy;
    for (var k = 0; k < 3; k++) {
      c.drawArc(Rect.fromCircle(center: at, radius: r), spin + k * 2.094 - .3, .6, false, fill);
    }
    for (final (dist, phase, size) in const [(.3, .9, .3), (.68, 3.6, .2)]) {
      final a = spin + phase;
      final centre = at + Offset(math.cos(a), math.sin(a)) * (r * dist);
      final pts = <double>[];
      for (var i = 0; i < 5; i++) {
        final t = a + i * math.pi * .4 - math.pi / 2;
        pts
          ..add(centre.dx + math.cos(t) * r * size)
          ..add(centre.dy + math.sin(t) * r * size);
      }
      c.drawPath(Sketch.poly(pts), fill);
    }
    c.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, r * .1)
        ..color = _navy.withValues(alpha: .7),
    );
  }

  static const _yellowKit = _Kit(
    jersey: Color(0xffffd92e),
    trim: Color(0xff1f8f4a),
    shorts: Color(0xff2a56c8),
    stripe: Color(0xfff6f1e2),
    socks: Color(0xfff6f1e2),
    band: Color(0xff1f8f4a),
    skin: Color(0xff8a5a3a),
    hair: Color(0xff2a2020),
    boot: Color(0xff1a2028),
  );
  static const _blueKit = _Kit(
    jersey: Color(0xff4c9ae6),
    trim: Color(0xfff6f1e2),
    shorts: Color(0xfff6f1e2),
    stripe: Color(0xff2f5fd0),
    socks: Color(0xff2f5fd0),
    band: Color(0xfff6f1e2),
    skin: Color(0xffc48a5a),
    hair: Color(0xffd8b24a),
    boot: Color(0xff1a2028),
    hairKind: 2,
  );
  static const _keeperKit = _Kit(
    jersey: Color(0xffff7a3a),
    trim: Color(0xff26303a),
    shorts: Color(0xff26303a),
    stripe: Color(0xffff7a3a),
    socks: Color(0xff26303a),
    band: Color(0xffff7a3a),
    skin: Color(0xff6f4a30),
    hair: Color(0xff1e1818),
    boot: Color(0xff141a20),
    glove: Color(0xffb6f04a),
    hairKind: 1,
  );

  /// Two-bone leg from a hip at ([hx], [hy]) (forward, up, in footballer
  /// heights) to an ankle target above a boot sole at ([tx], [ty]): returns
  /// the knee, which bends forward, and the ankle. Out of reach the leg
  /// straightens and the foot leaves the ground.
  static (Offset, Offset) _matchLeg(double hx, double hy, double tx, double ty) {
    const l1 = .245, l2 = .235, reach = l1 + l2 - .006;
    var dx = tx - hx, dy = ty + .045 - hy;
    final far = math.sqrt(dx * dx + dy * dy);
    if (far > reach) {
      dx *= reach / far;
      dy *= reach / far;
    }
    final d = math.max(.14, math.min(far, reach));
    final alpha = math.acos(((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)).clamp(-1.0, 1.0));
    final phi = math.atan2(dx, -dy);
    return (Offset(hx + l1 * math.sin(phi + alpha), hy - l1 * math.cos(phi + alpha)), Offset(hx + dx, hy + dy));
  }

  /// A footballer seen from the side, [s] tall, standing at [base] and
  /// facing [dir] (1 right, -1 left). The pose sets the joints; a planted boot
  /// stays on the sand because the hip drops to meet it. Light comes from the
  /// right, so the screen-left edge of everything is in shade.
  void _matchFigure(
    Canvas c,
    Offset base,
    double s,
    double dir,
    _Pose p,
    _Kit kit,
    double bob, {
    bool keeper = false,
    bool number = false,
  }) {
    Offset at(double x, double up) => Offset(base.dx + dir * x * s, base.dy - up * s);
    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void seg(Offset a, Offset b, double w, Color col) {
      line
        ..strokeWidth = math.max(.9, w * s)
        ..color = col;
      c.drawLine(a, b, line);
    }

    void quad(Offset a, Offset b, Offset d, Offset e, Color col) {
      c.drawPath(Sketch.poly([a.dx, a.dy, b.dx, b.dy, d.dx, d.dy, e.dx, e.dy]), fill..color = col);
    }

    Color dark(Color col) => Sketch.mix(col, const Color(0xff000000), .3);
    final hipUp = .5 - p.crouch + bob;
    final hip = at(p.shift, hipUp);
    final axis = Offset(dir * math.sin(p.lean), -math.cos(p.lean));
    final perp = Offset(math.cos(p.lean), dir * math.sin(p.lean));
    final sh = hip + axis * (s * .27);

    // Contact shadow and the long shadow the sun behind throws forward.
    fill.color = const Color(0x2e6a4a1c);
    c.drawOval(Rect.fromCenter(center: base + Offset(-s * .05, s * .012), width: s * .6, height: s * .07), fill);
    seg(base + Offset(-s * .04, s * .01), base + Offset(-s * .52, s * .06), .09, const Color(0x1f6a4a1c));

    void arm(double a, double e, bool far) {
      final root = sh - axis * (s * .02);
      final elbow = root + Offset(dir * math.sin(a), math.cos(a)) * (s * .16);
      final hand = elbow + Offset(dir * math.sin(e), math.cos(e)) * (s * .15);
      Color tone(Color col) => far ? dark(col) : col;
      if (keeper) {
        seg(root, elbow, .09, tone(kit.jersey));
        seg(elbow, hand, .08, tone(kit.jersey));
        c.drawCircle(hand, s * .055, fill..color = tone(kit.glove));
      } else {
        seg(root, elbow, .062, tone(kit.skin));
        seg(elbow, hand, .056, tone(kit.skin));
        seg(root, Offset.lerp(root, elbow, .62)!, .09, tone(kit.jersey));
        c.drawCircle(hand, s * .033, fill..color = tone(kit.skin));
      }
    }

    void leg(Offset kneeL, Offset ankleL, double soleUp, bool far) {
      final k = at(kneeL.dx, kneeL.dy), a = at(ankleL.dx, ankleL.dy);
      Color tone(Color col) => far ? dark(col) : col;
      seg(hip, k, .105, tone(kit.skin));
      seg(k, a, .085, tone(kit.skin));
      seg(Offset.lerp(k, a, .4)!, a, .092, tone(kit.socks));
      final m = Offset.lerp(k, a, .42)!, along = (a - k) / math.max(.001, (a - k).distance);
      final across = Offset(-along.dy, along.dx) * (s * .05);
      quad(m - across, m + across, m + across + along * (s * .03), m - across + along * (s * .03), tone(kit.band));
      seg(hip, Offset.lerp(hip, k, .55)!, .15, tone(kit.shorts));
      // The boot follows the shin when lifted and lies flat when planted.
      final sx = ankleL.dx - kneeL.dx, sy = ankleL.dy - kneeL.dy;
      final len = math.max(.001, math.sqrt(sx * sx + sy * sy));
      final planted = (1 - soleUp / .07).clamp(0.0, 1.0);
      var fx = (-sy / len) * (1 - planted) + planted, fy = (sx / len) * (1 - planted);
      final fl = math.max(.001, math.sqrt(fx * fx + fy * fy));
      fx /= fl;
      fy /= fl;
      final heel = at(ankleL.dx - fx * .03, ankleL.dy - .028 - fy * .03);
      final toe = at(ankleL.dx + fx * .085, ankleL.dy - .028 + fy * .085);
      seg(heel, toe, .062, tone(kit.boot));
      seg(Offset.lerp(heel, toe, .2)!, Offset.lerp(heel, toe, .8)!, .014, tone(const Color(0xff9aa4ac)));
    }

    arm(p.fa, p.fe, true);
    final (farKnee, farAnkle) = _matchLeg(p.shift, hipUp, p.fx, p.fy);
    final (nearKnee, nearAnkle) = _matchLeg(p.shift, hipUp, p.nx, p.ny);
    leg(farKnee, farAnkle, p.fy, true);
    leg(nearKnee, nearAnkle, p.ny, false);

    // Shorts, then the jersey over them: a shaded back, a lit front edge.
    final top = hip + axis * (s * .04);
    quad(top - perp * (s * .095), top + perp * (s * .095), Offset(hip.dx + s * .1, hip.dy + s * .105), Offset(hip.dx - s * .1, hip.dy + s * .105), kit.shorts);
    seg(top - perp * (s * .085), Offset(hip.dx - s * .092, hip.dy + s * .1), .02, kit.stripe);
    final hipL = hip - perp * (s * .095), hipR = hip + perp * (s * .095);
    final shL = sh - perp * (s * .112), shR = sh + perp * (s * .112);
    quad(hipL, hipR, shR, shL, kit.jersey);
    c.drawCircle(sh, s * .11, fill..color = kit.jersey);
    quad(hipL, hipL + perp * (s * .06), shL + perp * (s * .07), shL, Sketch.mix(kit.jersey, const Color(0xff000000), .17));
    quad(hipR - perp * (s * .035), hipR, shR, shR - perp * (s * .04), Sketch.mix(kit.jersey, const Color(0xffffffff), .22));
    seg(hipL + axis * (s * .03), hipR + axis * (s * .03), .022, kit.trim);
    seg(sh - perp * (s * .055) + axis * (s * .01), sh + perp * (s * .055) + axis * (s * .01), .04, kit.trim);
    if (number) {
      final nc = Offset.lerp(hip, sh, .5)! - perp * (dir * s * .05);
      seg(nc - perp * (s * .022) + axis * (s * .04), nc - perp * (s * .022) - axis * (s * .04), .016, kit.trim);
      c.drawOval(
        Rect.fromCenter(center: nc + perp * (s * .018), width: s * .034, height: s * .09),
        line
          ..strokeWidth = math.max(.5, s * .014)
          ..color = kit.trim,
      );
    }

    // Head: neck, hair behind, face, hair on top, ear, nose and eye.
    final tilt = p.lean + p.head;
    final hc = sh + Offset(dir * math.sin(tilt), -math.cos(tilt)) * (s * .125);
    seg(sh, hc, .055, dark(kit.skin));
    if (kit.hairKind == 1) c.drawCircle(hc + Offset(-dir * s * .012, -s * .012), s * .118, fill..color = kit.hair);
    c.drawCircle(hc, s * .085, fill..color = kit.skin);
    if (kit.hairKind != 1) {
      c.drawArc(
        Rect.fromCircle(center: hc, radius: s * .093),
        dir > 0 ? math.pi * .72 : math.pi * 1.33,
        math.pi * .95,
        true,
        fill..color = kit.hair,
      );
    }
    c.drawCircle(hc + Offset(-dir * s * .022, s * .016), s * .022, fill..color = dark(kit.skin));
    c.drawCircle(hc + Offset(dir * s * .082, s * .014), s * .02, fill..color = kit.skin);
    c.drawCircle(hc + Offset(dir * s * .045, -s * .004), math.max(.5, s * .012), fill..color = const Color(0xff1e1414));
    arm(p.na, p.ne, false);
  }
}

/// The colours a footballer wears. [hairKind]: 0 short, 1 afro, 2 cropped.
class _Kit {
  const _Kit({
    required this.jersey,
    required this.trim,
    required this.shorts,
    required this.stripe,
    required this.socks,
    required this.band,
    required this.skin,
    required this.hair,
    required this.boot,
    this.glove = const Color(0xffffffff),
    this.hairKind = 0,
  });
  final Color jersey, trim, shorts, stripe, socks, band, skin, hair, boot, glove;
  final int hairKind;
}

/// A footballer's joints: pelvis [shift] and [crouch], torso [lean], the near
/// and far boot targets (forward, sole height), both arms as upper and lower
/// angles from hanging (positive forward) and the [head] tilt. Lengths are in
/// footballer heights, angles in radians.
class _Pose {
  const _Pose(this.shift, this.crouch, this.lean, this.nx, this.ny, this.fx, this.fy, this.na, this.ne, this.fa, this.fe, this.head);
  final double shift, crouch, lean, nx, ny, fx, fy, na, ne, fa, fe, head;

  static _Pose lerp(_Pose a, _Pose b, double t) {
    double m(double x, double y) => x + (y - x) * t;
    return _Pose(
      m(a.shift, b.shift),
      m(a.crouch, b.crouch),
      m(a.lean, b.lean),
      m(a.nx, b.nx),
      m(a.ny, b.ny),
      m(a.fx, b.fx),
      m(a.fy, b.fy),
      m(a.na, b.na),
      m(a.ne, b.ne),
      m(a.fa, b.fa),
      m(a.fe, b.fe),
      m(a.head, b.head),
    );
  }
}
