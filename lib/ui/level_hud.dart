import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/game_rules.dart' show BossKind, FinishLine;
import '../game/bird_puppet.dart';
import 'campaign_keepsake_art.dart';
import 'match_hud.dart';
import 'theme.dart';

/// A campaign level's hero readout in place of the score: the stars
/// collected so far, the count of the next collection mark beside it, then
/// a short track with the level's two marks as notches. The track fills as
/// stars come in. The next mark's notch is drawn ready, the one after it
/// faint, and each lights up once the count reaches it (★★, then ★★★) with
/// a single pop. Collecting a star pops the plate once.
class MatchLevelStars extends StatefulWidget {
  const MatchLevelStars({
    super.key,
    required this.stars,
    required this.two,
    required this.three,
    required this.reducedMotion,
  });

  /// Stars collected, and the counts that earn ★★ and ★★★.
  final int stars, two, three;
  final bool reducedMotion;

  @override
  State<MatchLevelStars> createState() => _MatchLevelStarsState();
}

class _MatchLevelStarsState extends State<MatchLevelStars>
    with TickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.06,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.06,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 60,
    ),
  ]).animate(_pulse);

  /// The pop of a notch as its mark is reached, and which notches it plays
  /// on. It only runs when a mark is reached in motion; a still HUD just
  /// shows the lit notch.
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  bool _popSecond = false, _popThird = false;

  bool get _still =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _pulse.reset();
      _pop.reset();
    }
  }

  @override
  void didUpdateWidget(MatchLevelStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_still || widget.stars < oldWidget.stars) {
      _pulse.reset();
      _pop.reset();
    } else if (widget.stars > oldWidget.stars) {
      _pulse.forward(from: 0);
      final second = widget.stars >= widget.two && oldWidget.stars < widget.two;
      final third =
          widget.stars >= widget.three && oldWidget.stars < widget.three;
      if (second || third) {
        _popSecond = second;
        _popThird = third;
        _pop.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stars = widget.stars, two = widget.two, three = widget.three;
    String mark(int count, int at) =>
        stars >= at ? '$count stars reached' : '$count stars at $at';
    // The next mark to reach: 2 (★★), 3 (★★★), or 0 once both are in.
    final next = stars < two ? 2 : (stars < three ? 3 : 0);
    final target = switch (next) {
      2 => '/$two',
      3 => '/$three',
      _ => 'MAX',
    };
    // The count and its target keep their width as digits come in and marks
    // pass, so nothing shifts along the plate.
    final digits = '0' * math.max('$three'.length, '$stars'.length);
    final room = '$three'.length > 2 ? '/$three' : '/00';
    return Center(
      child: Semantics(
        label: '$stars stars collected. ${mark(2, two)}. ${mark(3, three)}.',
        excludeSemantics: true,
        child: ScaleTransition(
          scale: _scale,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: MatchPlate(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MatchIcon(MatchSymbol.star, size: 36),
                  const SizedBox(width: 3),
                  // The count and its target share a baseline.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Opacity(
                            opacity: 0,
                            child: Text(digits, style: matchDigits(56)),
                          ),
                          Text('$stars', style: matchDigits(56)),
                        ],
                      ),
                      const SizedBox(width: 1),
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Opacity(
                            opacity: 0,
                            child: Text(room, style: _targetStyle),
                          ),
                          Opacity(
                            opacity: 0,
                            child: Text('MAX', style: _doneStyle),
                          ),
                          Text(
                            target,
                            style: next == 0 ? _doneStyle : _targetStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  _Marks(
                    stars: stars,
                    two: two,
                    three: three,
                    next: next,
                    pop: _pop,
                    popSecond: _popSecond,
                    popThird: _popThird,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The next mark's count: quiet next to the hero number, still readable.
  static final _targetStyle = matchDigits(
    22,
    color: SkyColors.ink.withValues(alpha: .58),
  );

  /// The same slot once every mark is in.
  static final _doneStyle = matchDigits(
    18,
    color: SkyColors.ink.withValues(alpha: .58),
  ).copyWith(letterSpacing: .6);
}

/// The track and its two notches: a star at the ★★ mark and a bigger one at
/// the end for ★★★. A notch is faint until it is the next mark, ready when
/// it is, and lit once reached.
class _Marks extends StatelessWidget {
  const _Marks({
    required this.stars,
    required this.two,
    required this.three,
    required this.next,
    required this.pop,
    required this.popSecond,
    required this.popThird,
  });
  final int stars, two, three, next;
  final Animation<double> pop;
  final bool popSecond, popThird;

  static const width = 118.0, height = 48.0;

  /// Where the ★★ notch sits along the track. Each mark is a stretch of the
  /// track, so the track's fill shows how close the next mark is, and the
  /// notches keep clear of each other whatever a level's marks are.
  static const first = .56;

  double get _fill {
    if (stars >= three) return 1;
    if (stars < two) return first * stars / two;
    return first + (1 - first) * (stars - two) / math.max(1, three - two);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      painter: _MarksPainter(
        fill: _fill,
        second: stars >= two,
        third: stars >= three,
        next: next,
        pop: pop,
        popSecond: popSecond,
        popThird: popThird,
      ),
    ),
  );
}

class _MarksPainter extends CustomPainter {
  const _MarksPainter({
    required this.fill,
    required this.second,
    required this.third,
    required this.next,
    required this.pop,
    required this.popSecond,
    required this.popThird,
  }) : super(repaint: pop);

  /// How much of the track is filled.
  final double fill;

  /// Whether each mark is reached, and which is next (2, 3 or 0 for none).
  final bool second, third;
  final int next;

  /// The pop's progress, and the notches it plays on.
  final Animation<double> pop;
  final bool popSecond, popThird;

  static const _thickness = 13.0, _start = 4.0, _last = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2 + 1;
    final end = size.width - _last;
    final track = RRect.fromLTRBR(
      _start,
      y - _thickness / 2,
      end,
      y + _thickness / 2,
      const Radius.circular(_thickness / 2),
    );
    canvas.drawRRect(track.inflate(2.5), Paint()..color = SkyColors.ink);
    canvas.drawRRect(
      track,
      Paint()..color = Color.lerp(SkyColors.cream, SkyColors.ink, .18)!,
    );
    if (fill > 0) {
      final filled = RRect.fromLTRBR(
        track.left,
        track.top,
        math.max(track.left + _thickness, _start + (end - _start) * fill),
        track.bottom,
        const Radius.circular(_thickness / 2),
      );
      canvas.drawRRect(filled, Paint()..color = SkyColors.yellow);
      // A lit top edge, as on the plates.
      canvas.drawLine(
        Offset(filled.left + 5, track.top + 3),
        Offset(math.max(filled.left + 5, filled.right - 5), track.top + 3),
        Paint()
          ..color = SkyColors.white.withValues(alpha: .85)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
    final t = pop.value;
    final popping = t > 0 && t < 1;
    final notches = [
      (Offset(_start + (end - _start) * _Marks.first, y - 1), 11.5, second, 2),
      (Offset(end, y - 1), 14.5, third, 3),
    ];
    // Bursts under every star, so a swelling one covers the flash.
    for (final (center, radius, _, mark) in notches) {
      if (popping && (mark == 2 ? popSecond : popThird)) {
        _burst(canvas, center, radius, t);
      }
    }
    for (final (center, radius, lit, mark) in notches) {
      final popped = popping && (mark == 2 ? popSecond : popThird);
      _star(
        canvas,
        center,
        radius,
        lit: lit,
        ready: next == mark,
        scale: popped ? _bump(t) : 1,
      );
    }
  }

  /// The notch's swell: up fast, then back home with a little give.
  static double _bump(double t) => t < .28
      ? 1 + .62 * Curves.easeOutCubic.transform(t / .28)
      : 1 + .62 * (1 - Curves.easeOutBack.transform((t - .28) / .72));

  /// A flash, a ring and eight short rays leaving a notch as it lights.
  void _burst(Canvas canvas, Offset center, double radius, double t) {
    final out = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      radius * (1.2 + .9 * out),
      Paint()..color = SkyColors.yellow.withValues(alpha: .7 * fade),
    );
    canvas.drawCircle(
      center,
      radius * (1.2 + 1.5 * out),
      Paint()
        ..color = SkyColors.gold.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + 3.5 * fade,
    );
    final ray = Paint()
      ..color = SkyColors.gold.withValues(alpha: fade)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = math.pi / 8 + i * math.pi / 4;
      final along = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + along * radius * (1.7 + .8 * out),
        center + along * radius * (2.1 + 1.1 * out),
        ray,
      );
    }
  }

  void _star(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool lit,
    required bool ready,
    double scale = 1,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * .49;
      final point = Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    path.close();
    // Reached: yellow with a glint. Next: a warm socket in full ink. Later:
    // a faint socket, like the hearts and shield not yet earned.
    final edge = Paint()
      ..color = lit || ready
          ? SkyColors.ink
          : SkyColors.ink.withValues(alpha: .4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, edge);
    canvas.drawPath(
      path,
      Paint()
        ..color = lit
            ? SkyColors.yellow
            : ready
            ? Color.lerp(SkyColors.cream, SkyColors.yellow, .45)!
            : Color.lerp(SkyColors.cream, SkyColors.ink, .1)!,
    );
    if (lit) {
      canvas.drawLine(
        Offset(-radius * .3, -radius * .18),
        Offset(-radius * .08, -radius * .55),
        Paint()
          ..color = SkyColors.white
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarksPainter oldDelegate) =>
      fill != oldDelegate.fill ||
      second != oldDelegate.second ||
      third != oldDelegate.third ||
      next != oldDelegate.next ||
      popSecond != oldDelegate.popSecond ||
      popThird != oldDelegate.popThird;
}

/// A campaign level's route at a glance, in the slot a timed flight gave its
/// clock: the mail route from its start post to a checkered finish flag, a
/// solid teal line flown behind the bird and an empty dotted groove ahead.
/// Only the bird moves along it, with the flight. A boss level marks its
/// boss's lair with the boss's headwear, at [FinishLine.bossMark]; the
/// victory glide flies the rest.
class MatchRoute extends StatelessWidget {
  const MatchRoute({
    super.key,
    required this.progress,
    required this.bird,
    this.boss,
    this.width = 212,
  });

  /// 0 at the start, 1 at the finish line. See
  /// [FlightSimulation.routeProgress].
  final double progress;
  final int bird;

  /// The boss a boss level meets on the way, or null.
  final BossKind? boss;
  final double width;

  static const height = 44.0;

  /// The plate's face height around the route: the same as Pause, so the
  /// two sit on one line.
  static const plateHeight = height + 12;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Route ${(progress.clamp(0.0, 1.0) * 100).round()}% flown',
    excludeSemantics: true,
    child: MatchPlate(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _RoutePainter(progress.clamp(0.0, 1.0), bird, boss),
        ),
      ),
    ),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.progress, this.bird, this.boss);
  final double progress;
  final int bird;
  final BossKind? boss;

  static const _thickness = 9.0, _start = 9.0, _flagRoom = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 9;
    final finish = size.width - _flagRoom;
    final at = _start + (finish - _start) * progress;
    final groove = RRect.fromLTRBR(
      _start - 3,
      y - _thickness / 2,
      finish + 3,
      y + _thickness / 2,
      const Radius.circular(_thickness / 2),
    );
    canvas.drawRRect(groove.inflate(2.5), Paint()..color = SkyColors.ink);
    canvas.drawRRect(
      groove,
      Paint()..color = Color.lerp(SkyColors.cream, SkyColors.ink, .18)!,
    );
    // Dotted ahead, like the mail routes on the map.
    final dot = Paint()..color = SkyColors.ink.withValues(alpha: .34);
    for (var x = finish - 4; x > at + 8; x -= 8) {
      canvas.drawCircle(Offset(x, y), 1.5, dot);
    }
    // Solid behind: the flown route, filled and lit like the star track.
    if (progress > 0) {
      final flown = RRect.fromLTRBR(
        groove.left,
        groove.top,
        math.max(groove.left + _thickness, at + 2),
        groove.bottom,
        const Radius.circular(_thickness / 2),
      );
      canvas.drawRRect(flown, Paint()..color = SkyColors.teal);
      canvas.drawLine(
        Offset(flown.left + 4, groove.top + 2.4),
        Offset(math.max(flown.left + 4, flown.right - 4), groove.top + 2.4),
        Paint()
          ..color = SkyColors.white.withValues(alpha: .7)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
    // The start post.
    canvas.drawCircle(Offset(_start, y), 7, Paint()..color = SkyColors.ink);
    canvas.drawCircle(Offset(_start, y), 4.4, Paint()..color = SkyColors.teal);
    canvas.drawCircle(
      Offset(_start - 1, y - 1.2),
      1.5,
      Paint()..color = SkyColors.white.withValues(alpha: .8),
    );
    _flag(canvas, Offset(finish + 3, y + 1));
    if (boss case final boss?) {
      _lair(
        canvas,
        Offset(_start + (finish - _start) * FinishLine.bossMark, y),
        boss,
      );
    }
    // The bird rides the line, facing the flag, with a pin where it is.
    const bw = 38.0;
    BirdPuppet.paint(
      canvas,
      Rect.fromLTWH(at - bw * .5, y - 3 - bw * 224 / 256, bw, bw * 224 / 256),
      bird: bird,
      wing: .3,
    );
  }

  /// The boss's lair: a post in the boss's color on the line, crowned with
  /// the headwear it loses, as on the map.
  void _lair(Canvas canvas, Offset at, BossKind boss) {
    canvas.drawCircle(at, 7, Paint()..color = SkyColors.ink);
    canvas.drawCircle(at, 4.5, Paint()..color = CampaignHeadwear.field(boss));
    CampaignHeadwear.paint(
      canvas,
      Rect.fromCenter(center: at.translate(0, -18), width: 26, height: 20),
      boss,
    );
  }

  /// A checkered finish flag on a pole, in ink and cream so it holds on the
  /// plate at a glance.
  void _flag(Canvas canvas, Offset foot) {
    final ink = Paint()..color = SkyColors.ink;
    final pole = Rect.fromLTWH(foot.dx - 1.7, foot.dy - 34, 3.4, 36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pole.inflate(1.5), const Radius.circular(3)),
      ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pole, const Radius.circular(2)),
      Paint()..color = SkyColors.cream,
    );
    final cloth = Path()
      ..moveTo(foot.dx + 1.5, foot.dy - 33)
      ..lineTo(foot.dx + 24, foot.dy - 28)
      ..lineTo(foot.dx + 24, foot.dy - 13)
      ..lineTo(foot.dx + 1.5, foot.dy - 17)
      ..close();
    canvas.drawPath(
      cloth,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(cloth, Paint()..color = SkyColors.white);
    canvas.save();
    canvas.clipPath(cloth);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        if ((row + col).isOdd) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            foot.dx + 1.5 + col * 5.6,
            foot.dy - 34 + row * 5.6 + col * 1.2,
            5.6,
            5.8,
          ),
          ink,
        );
      }
    }
    canvas.restore();
    canvas.drawCircle(Offset(foot.dx, foot.dy - 34.5), 3, ink);
    canvas.drawCircle(
      Offset(foot.dx, foot.dy - 34.5),
      1.7,
      Paint()..color = SkyColors.gold,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      bird != oldDelegate.bird ||
      boss != oldDelegate.boss;
}
