import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game/star_art.dart';
import 'components.dart';
import 'theme.dart';

/// The title screen is drawn on a 1000 × 450 canvas that phones letterbox.
/// The sky reaches past that canvas so it stays full-bleed.
const homeWidth = 1000.0, homeHeight = 450.0;

/// The warm light behind each bird, matched to its plumage.
const birdAccents = [
  SkyColors.yellow,
  Color(0xffffa3b5),
  SkyColors.mint,
  SkyColors.lavender,
];

/// Ambient time and the opening choreography for every layer of the title
/// screen. With Reduced Motion nothing ticks: the clock rests at zero, which
/// is the composed still pose, and the opening is already finished.
class HomeStage extends StatefulWidget {
  const HomeStage({
    super.key,
    required this.reducedMotion,
    required this.child,
  });
  final bool reducedMotion;
  final Widget child;

  @override
  State<HomeStage> createState() => _HomeStageState();
}

class _HomeStageState extends State<HomeStage> with TickerProviderStateMixin {
  final clock = ValueNotifier<double>(0);
  late final Ticker ticker = createTicker(
    (elapsed) =>
        clock.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond,
  );
  late final AnimationController enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  bool entered = false;

  bool get still =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(HomeStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (still) {
      ticker.stop();
      enter.value = 1;
      entered = true;
      // Come to rest in the composed pose, once this frame has been built.
      if (clock.value != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && still) clock.value = 0;
        });
      }
      return;
    }
    if (!ticker.isActive) ticker.start();
    if (!entered) {
      entered = true;
      enter.forward();
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    enter.dispose();
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      HomeMotion(clock: clock, enter: enter, still: still, child: widget.child);
}

class HomeMotion extends InheritedWidget {
  const HomeMotion({
    super.key,
    required this.clock,
    required this.enter,
    required this.still,
    required super.child,
  });

  /// Seconds of ambient motion since the screen opened.
  final ValueListenable<double> clock;

  /// 0 → 1 while the screen assembles itself.
  final Animation<double> enter;
  final bool still;

  static HomeMotion of(BuildContext context) => maybeOf(context)!;

  static HomeMotion? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeMotion>();

  @override
  bool updateShouldNotify(HomeMotion oldWidget) => still != oldWidget.still;
}

/// One piece of the opening: fades, slides and pops in over [begin]…[end] of
/// the choreography, then costs nothing.
class HomeEntrance extends StatelessWidget {
  const HomeEntrance({
    super.key,
    required this.begin,
    required this.end,
    required this.child,
    this.slide = Offset.zero,
    this.pop = 1,
    this.curve = Curves.easeOutBack,
  });
  final double begin, end;
  final Offset slide;

  /// Starting scale; 1 leaves the size alone.
  final double pop;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enter = HomeMotion.of(context).enter;
    return AnimatedBuilder(
      animation: enter,
      child: child,
      builder: (context, child) {
        final u = ((enter.value - begin) / (end - begin)).clamp(0.0, 1.0);
        final e = curve.transform(u);
        return Opacity(
          opacity: Curves.easeOut.transform(math.min(1, u * 2.2)),
          child: Transform.translate(
            offset: slide * (1 - e),
            child: Transform.scale(scale: pop + (1 - pop) * e, child: child),
          ),
        );
      },
    );
  }
}

/// Everything that lives behind the menu: sky, sun, clouds, far islands, the
/// star trail, the island and the bird.
class HomeWorld extends StatelessWidget {
  const HomeWorld({super.key, required this.bird});
  final int bird;

  @override
  Widget build(BuildContext context) {
    final motion = HomeMotion.of(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -400,
              top: -220,
              width: 1800,
              height: 900,
              child: CustomPaint(
                painter: _SunPainter(
                  clock: motion.clock,
                  accent: birdAccents[bird],
                ),
              ),
            ),
            for (final c in _clouds) _DriftingCloud(c),
            Positioned.fill(
              child: CustomPaint(
                painter: _TrailPainter(
                  clock: motion.clock,
                  enter: motion.enter,
                  still: motion.still,
                ),
              ),
            ),
            HomeEntrance(
              begin: .04,
              end: .5,
              slide: const Offset(0, 40),
              curve: Curves.easeOutCubic,
              child: _IslandAndBird(bird: bird),
            ),
            const Positioned(
              left: -400,
              top: _seaTop,
              width: 1800,
              height: 700 - _seaTop,
              child: _CloudSea(),
            ),
            // On tall screens the sea carries on down to the bottom edge.
            Positioned(
              left: -400,
              top: 699,
              width: 1800,
              height: 2000,
              child: ColoredBox(color: SkyColors.white.withValues(alpha: .76)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriftCloud {
  const _DriftCloud(this.width, this.x, this.y, this.speed, this.fade);
  final double width, x, y, speed, fade;
}

// Far clouds are small, pale and slow; near ones are larger and quicker, so
// the sky slides in parallax. Speeds are canvas units per second.
const _clouds = [
  _DriftCloud(150, 300, 96, 3.2, .55),
  _DriftCloud(120, 840, 30, 2.4, .5),
  _DriftCloud(205, -60, 150, 5.5, .9),
  _DriftCloud(235, 700, 250, 6.4, .9),
  _DriftCloud(170, 470, 20, 4.4, .7),
];

const _driftFrom = -420.0, _driftTo = 1420.0;

class _DriftingCloud extends StatelessWidget {
  const _DriftingCloud(this.cloud);
  final _DriftCloud cloud;

  @override
  Widget build(BuildContext context) {
    final clock = HomeMotion.of(context).clock;
    final span = _driftTo - _driftFrom;
    return Positioned(
      left: 0,
      top: 0,
      child: AnimatedBuilder(
        animation: clock,
        child: RepaintBoundary(
          child: Opacity(
            opacity: cloud.fade,
            child: Cloud(width: cloud.width),
          ),
        ),
        builder: (context, child) => Transform.translate(
          offset: Offset(
            _driftFrom +
                (cloud.x - _driftFrom + cloud.speed * clock.value) % span,
            cloud.y,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The island, its shadow and the bird, which hops now and then: a squat, a
/// spring and a landing, the same three beats as the exercises.
class _IslandAndBird extends StatelessWidget {
  const _IslandAndBird({required this.bird});
  final int bird;

  static const birdLeft = 618.0, birdTop = 84.0, birdSize = 262.0;

  @override
  Widget build(BuildContext context) {
    final clock = HomeMotion.of(context).clock;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 587,
          top: 236,
          child: Image.asset(
            'assets/images/island.png',
            width: 330,
            height: 206,
            excludeFromSemantics: true,
          ),
        ),
        Positioned(
          left: birdLeft + 30,
          top: 288,
          child: AnimatedBuilder(
            animation: clock,
            builder: (context, _) {
              final pose = HomeBirdPose.at(clock.value);
              final lift = math.max(0.0, pose.lift) / HomeBirdPose.apex;
              // The shadow shrinks and fades as the bird leaves the ground.
              return Transform.scale(
                scale: 1 - lift * .3 + pose.squash * .05,
                child: Container(
                  width: 176,
                  height: 24,
                  decoration: BoxDecoration(
                    color: SkyColors.ink.withValues(
                      alpha: .13 * (1 - lift * .5),
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          left: birdLeft,
          top: birdTop,
          child: AnimatedBuilder(
            animation: clock,
            child: BirdArt(bird: bird, size: birdSize, bob: false),
            builder: (context, child) {
              final pose = HomeBirdPose.at(clock.value);
              return Transform(
                alignment: const Alignment(0, .86),
                transform: Matrix4.identity()
                  ..translateByDouble(0, -pose.lift, 0, 1)
                  ..rotateZ(pose.tilt)
                  ..scaleByDouble(pose.sx, pose.sy, 1, 1),
                child: child,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// How the bird sits on its island at [t] seconds: a slow bob, and every
/// [period] seconds a crouch, a spring and a landing.
class HomeBirdPose {
  const HomeBirdPose(this.lift, this.squash, this.tilt);

  /// Height above rest in canvas units.
  final double lift;

  /// Positive squashes the bird down and out, negative stretches it up.
  final double squash;

  /// Radians. The resting bird leans a little, beak up.
  final double tilt;

  static const period = 6.8, apex = 34.0, _start = 2.6;

  double get sx => 1 + .06 * squash;
  double get sy => 1 - .08 * squash;

  /// 0 → 1 over the half second after the hop reaches its top, when the bird
  /// touches a star; -1 the rest of the time.
  static double catchProgress(double t) {
    final u = t % period - _start - .9;
    return u >= 0 && u < .6 ? u / .6 : -1;
  }

  static HomeBirdPose at(double t) {
    final wave = math.sin(t * 2 * math.pi / 2.8);
    final u = t % period - _start;
    if (u < 0) return HomeBirdPose(wave * 4, 0, -.09 + wave * .012);
    double lift, squash;
    if (u < .42) {
      final e = Curves.easeInOut.transform(u / .42);
      squash = e;
      lift = -7 * e;
    } else if (u < .62) {
      final e = Curves.easeOut.transform((u - .42) / .2);
      squash = 1 - 1.7 * e;
      lift = -7 + 17 * e;
    } else if (u < .95) {
      final e = Curves.easeOut.transform((u - .62) / .33);
      squash = -.7 + .5 * e;
      lift = 10 + (apex - 10) * e;
    } else if (u < 1.35) {
      final e = Curves.easeIn.transform((u - .95) / .4);
      squash = -.2 + .2 * e;
      lift = apex * (1 - e);
    } else if (u < 1.65) {
      squash = math.sin((u - 1.35) / .3 * math.pi) * .55;
      lift = 0;
    } else {
      squash = 0;
      lift = 0;
    }
    // The bob fades out for the hop and back in after it.
    final weight = u < .42
        ? 1 - u / .42
        : u < 1.7
        ? 0.0
        : u < 2.1
        ? (u - 1.7) / .4
        : 1.0;
    final nose = -.07 * (lift.clamp(0, apex) / apex);
    return HomeBirdPose(
      lift + wave * 4 * weight,
      squash,
      -.09 + wave * .012 * weight + nose,
    );
  }
}

/// A warm sun disc and slowly turning rays behind the bird.
class _SunPainter extends CustomPainter {
  _SunPainter({required this.clock, required this.accent})
    : super(repaint: clock);
  final ValueListenable<double> clock;
  final Color accent;

  static const center = Offset(748, 186);

  late final Paint _disc = Paint()
    ..shader = RadialGradient(
      colors: [
        Color.lerp(SkyColors.cream, accent, .3)!.withValues(alpha: .8),
        Color.lerp(SkyColors.cream, accent, .3)!.withValues(alpha: .5),
        Color.lerp(SkyColors.cream, accent, .3)!.withValues(alpha: .18),
        Color.lerp(SkyColors.cream, accent, .3)!.withValues(alpha: 0),
      ],
      stops: const [0, .45, .78, 1],
    ).createShader(Rect.fromCircle(center: center, radius: 205));

  static final Path _rays = () {
    final path = Path();
    const count = 14;
    for (var i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count;
      const half = .085;
      path
        ..moveTo(0, 0)
        ..lineTo(math.cos(a - half) * 1.1, math.sin(a - half) * 1.1)
        ..lineTo(math.cos(a + half) * 1.1, math.sin(a + half) * 1.1)
        ..close();
    }
    return path;
  }();

  static final Paint _rayPaint = Paint()
    ..shader = RadialGradient(
      colors: [
        SkyColors.white.withValues(alpha: .34),
        SkyColors.white.withValues(alpha: 0),
      ],
      stops: const [.2, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));

  static const _horizonBox = Rect.fromLTWH(-200, 330, 1400, 300);
  static final Paint _horizon = Paint()
    ..shader = RadialGradient(
      colors: [
        const Color(0xfffff0c2).withValues(alpha: .75),
        const Color(0xfffff0c2).withValues(alpha: 0),
      ],
    ).createShader(_horizonBox);

  @override
  void paint(Canvas canvas, Size size) {
    // The painter's box starts at (-400, -220) of the title canvas.
    canvas.translate(400, 220);
    // Low warm light along the horizon.
    canvas.drawOval(_horizonBox, _horizon);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(clock.value * .04);
    canvas.scale(520);
    canvas.drawPath(_rays, _rayPaint);
    canvas.restore();
    // The disc: the accent glows through cream so each bird has its own dawn.
    canvas.drawCircle(center, 205, _disc);
  }

  @override
  bool shouldRepaint(_SunPainter oldDelegate) => oldDelegate.accent != accent;
}

/// Small far-off islands, the dotted star trail from the Endless key and the
/// stars along it. A pulse of light travels the trail from the key, and the
/// bird's hop ends in a star that pops.
class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.clock, required this.enter, required this.still})
    : super(repaint: Listenable.merge([clock, enter]));
  final ValueListenable<double> clock;
  final Animation<double> enter;
  final bool still;

  static final Path _path = Path()
    ..moveTo(496, 268)
    ..cubicTo(500, 214, 538, 198, 584, 156)
    ..cubicTo(640, 104, 690, 62, 760, 56)
    ..cubicTo(832, 50, 884, 92, 896, 152);

  static final List<Offset> _dots = () {
    final points = <Offset>[];
    for (final metric in _path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 13) {
        points.add(metric.getTangentForOffset(d)!.position);
      }
    }
    return points;
  }();

  /// The first dot clear of the Endless key; the ones before it would sit
  /// under the key, so the trail starts at its edge.
  static final int _first = _dots.indexWhere((p) => p.dx > 566);

  // Stars sit on the trail at these dot indices and grow toward the bird.
  // The third hangs where the bird's hop reaches.
  static const _stars = [
    (11, 13.0, -.15),
    (17, 17.0, -.2),
    (23, 21.0, .12),
    (-1, 30.0, .15),
  ];
  static const _catchStar = 2;
  static const _last = Offset(896, 152);

  static final Paint _dot = Paint()
    ..color = SkyColors.cream.withValues(alpha: .82);
  static final Paint _pulse = Paint();
  static const _sparkles = [
    (Offset(529, 122), 0.0),
    (Offset(958, 214), 1.7),
    (Offset(812, 30), 3.1),
    (Offset(588, 214), 4.4),
    (Offset(640, 44), 2.3),
  ];
  static final Paint _sparkle = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _burst = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / homeWidth, size.height / homeHeight);
    final t = clock.value;
    final open = enter.value;
    _flagIsland(canvas, const Offset(556, 386), .5, t, 0);
    _flagIsland(canvas, const Offset(944, 268), .85, t, 2.1);
    final n = _dots.length;
    final shown = n - _first;
    // The pulse leaves the Endless key and runs to the bird, then rests.
    final head = still ? -100.0 : _first + (t * 15) % (shown + 30);
    for (var i = _first; i < n; i++) {
      // The trail draws itself outward from the key as the screen opens.
      final reveal = ((open - .3 - .3 * (i - _first) / shown) / .06).clamp(
        0.0,
        1.0,
      );
      if (reveal == 0) continue;
      final near = (1 - (head - i).abs() / 5).clamp(0.0, 1.0);
      if (near == 0) {
        canvas.drawCircle(_dots[i], 2 * reveal, _dot);
        continue;
      }
      canvas.drawCircle(
        _dots[i],
        (2 + near * 1.6) * reveal,
        _pulse..color = SkyColors.cream.withValues(alpha: .82 + near * .18),
      );
    }
    final hop = HomeBirdPose.catchProgress(t);
    for (final (i, (index, radius, rotation)) in _stars.indexed) {
      final grow = Curves.easeOutBack.transform(
        ((open - .34 - i * .08) / .2).clamp(0.0, 1.0),
      );
      if (grow == 0) continue;
      final at = index < 0 ? _last : _dots[index] + const Offset(0, -2);
      var pulse = 0.0;
      if (index < 0) {
        pulse = still
            ? 0
            : (1 - (head - (n - 1)).abs() / 5).clamp(0.0, 1.0) * .1;
      } else if (!still) {
        pulse = (1 - (head - index).abs() / 4).clamp(0.0, 1.0) * .16;
      }
      if (i == _catchStar && hop >= 0) {
        pulse += .38 * math.sin(hop * math.pi);
      }
      StarArt.paint(
        canvas,
        at,
        radius * grow * (1 + pulse),
        seconds: t,
        reducedMotion: still,
        phase: i * .7,
        rotation: rotation,
      );
      if (i == _catchStar && hop >= 0) _pop(canvas, at, hop);
    }
    for (final (i, (p, phase)) in _sparkles.indexed) {
      final glow = still ? .8 : .5 + .5 * math.sin(t * 2.2 + phase + i);
      final r = 3 + 4.5 * glow;
      final fade = ((open - .5) / .2).clamp(0.0, 1.0);
      _sparkle
        ..color = SkyColors.cream.withValues(alpha: (.35 + .65 * glow) * fade)
        ..strokeWidth = 2.5;
      for (var k = 0; k < 4; k++) {
        final a = k * math.pi / 2;
        canvas.drawLine(
          p + Offset(math.cos(a), math.sin(a)) * 2.5,
          p + Offset(math.cos(a), math.sin(a)) * r,
          _sparkle,
        );
      }
    }
    canvas.restore();
  }

  /// A ring of tiny stars flies out of a star the bird has just touched.
  static void _pop(Canvas canvas, Offset at, double u) {
    final e = Curves.easeOut.transform(u);
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4 + .3;
      StarArt.mini(
        canvas,
        at + Offset(math.cos(a), math.sin(a)) * (30 + 34 * e),
        (k.isEven ? 6.5 : 4.5) * (1 - .6 * u),
        opacity: 1 - u * u,
        rotation: a + u,
        outline: 1.4,
      );
    }
    canvas.drawCircle(
      at,
      22 + 34 * e,
      _burst
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1 - u)
        ..color = SkyColors.gold.withValues(alpha: .8 * (1 - u)),
    );
  }

  static final Path _islandRock = Path()
    ..moveTo(-67, 8)
    ..lineTo(65, 8)
    ..lineTo(18, 81)
    ..lineTo(-16, 59)
    ..close();
  static final Path _pennant = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(21, 2, 41, 10)
    ..quadraticBezierTo(21, 16, 0, 23)
    ..close();
  static final Paint _rockPaint = Paint()
    ..color = const Color(0xff7ebdb5).withValues(alpha: .5);
  static final Paint _grassPaint = Paint()..color = const Color(0xff92cdb9);
  static final Paint _polePaint = Paint()
    ..color = SkyColors.teal.withValues(alpha: .65)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  static final Paint _flagPaint = Paint()
    ..color = SkyColors.cream.withValues(alpha: .85);

  static void _flagIsland(
    Canvas canvas,
    Offset at,
    double scale,
    double t,
    double phase,
  ) {
    canvas.save();
    canvas.translate(at.dx, at.dy + math.sin(t * .9 + phase) * 3);
    canvas.scale(scale);
    canvas.drawPath(_islandRock, _rockPaint);
    canvas.drawOval(const Rect.fromLTWH(-70, -7, 140, 33), _grassPaint);
    canvas.drawLine(const Offset(10, 0), const Offset(10, -63), _polePaint);
    // The pennant flutters in a light breeze.
    canvas.translate(12, -62);
    canvas.rotate(math.sin(t * 3 + phase) * .07);
    canvas.drawPath(_pennant, _flagPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) => oldDelegate.still != still;
}

/// A soft sea of cloud the menu rests on.
const _seaTop = 340.0;

class _CloudSea extends StatelessWidget {
  const _CloudSea();

  @override
  Widget build(BuildContext context) {
    final clock = HomeMotion.of(context).clock;
    return AnimatedBuilder(
      animation: clock,
      child: const RepaintBoundary(
        child: CustomPaint(
          size: Size(1800, 700 - _seaTop),
          painter: _SeaPainter(),
        ),
      ),
      builder: (context, child) => Transform.translate(
        offset: Offset(math.sin(clock.value * .12) * 14, 0),
        child: child,
      ),
    );
  }
}

class _SeaPainter extends CustomPainter {
  const _SeaPainter();

  static Path _bank(int seed, double base, double spread, double lift) {
    final random = math.Random(seed);
    final path = Path();
    for (var x = -40.0; x < 1840; x += spread) {
      final r = 46 + random.nextDouble() * 52;
      path.addOval(
        Rect.fromCircle(
          center: Offset(
            x + random.nextDouble() * 30,
            base - lift + random.nextDouble() * 26,
          ),
          radius: r,
        ),
      );
    }
    path.addRect(Rect.fromLTRB(-40, base + 40, 1840, 700));
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Local x = canvas x + 400; the far bank sits behind the near one.
    canvas.translate(0, -_seaTop);
    canvas.drawPath(
      _bank(3, 470, 118, 0),
      Paint()..color = SkyColors.white.withValues(alpha: .38),
    );
    canvas.drawPath(
      _bank(11, 520, 150, 0),
      Paint()..color = SkyColors.white.withValues(alpha: .62),
    );
  }

  @override
  bool shouldRepaint(_SeaPainter oldDelegate) => false;
}
