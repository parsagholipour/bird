import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/game_rules.dart';
import '../game/tether_art.dart';
import '../l10n/l10n.dart';
import 'home_keys.dart';
import 'match_hud.dart' show matchInkEdge;
import 'theme.dart';

/// The pieces of Fly Together's setup screen: two facing player cards in the
/// players' colours, like a pair of trading cards on the table, the rope or
/// the VS burst between them, the mode switch and the way into the sky.
///
/// Everything is drawn in the title screen's material: ink outlines, a
/// darker lip under every face and a streak of light along its top.

/// A player's card: a frame in [color] on a darker lip, holding the [art]
/// window above the [tray] of birds to pick from.
class CoopCard extends StatelessWidget {
  const CoopCard({
    super.key,
    required this.color,
    required this.art,
    required this.tray,
  });
  final Color color;
  final Widget art, tray;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Color.lerp(color, SkyColors.ink, .38),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: SkyColors.ink, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .22),
          offset: const Offset(0, 7),
          blurRadius: 12,
        ),
      ],
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21.5),
        border: const Border(
          bottom: BorderSide(color: SkyColors.ink, width: 2.5),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, SkyColors.white, .28)!, color],
          stops: const [0, .6],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The streak of light every key and card in the app carries.
          Positioned(
            left: 26,
            top: 3,
            width: 60,
            height: 2.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SkyColors.cream.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 8, 7, 7),
            child: Column(
              children: [
                Expanded(child: art),
                const SizedBox(height: 6),
                tray,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The window a player's bird stands in: a wash of their colour with a
/// sunburst behind the bird, a few sparks and a soft cloud floor. [focus] is
/// where the bird stands, so the burst and its shadow sit under it.
class CoopArtWindow extends StatelessWidget {
  const CoopArtWindow({
    super.key,
    required this.color,
    required this.focus,
    required this.child,
  });
  final Color color;
  final Alignment focus;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SkyColors.ink, width: 2),
    ),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(
      painter: _ArtWindowPainter(color: color, focus: focus),
      child: child,
    ),
  );
}

class _ArtWindowPainter extends CustomPainter {
  const _ArtWindowPainter({required this.color, required this.focus});
  final Color color;
  final Alignment focus;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width, h = size.height;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, SkyColors.cream, .8)!,
            Color.lerp(color, SkyColors.cream, .46)!,
          ],
        ).createShader(rect),
    );
    final center = focus.alongSize(size);
    // A slow sunburst of cream rays from behind the bird, fading out toward
    // the window's edge so the name stays easy to read.
    final reach = size.longestSide;
    final rays = Path();
    const count = 16;
    for (var i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count;
      const half = math.pi / count * .5;
      rays
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(a - half) * reach,
          center.dy + math.sin(a - half) * reach,
        )
        ..lineTo(
          center.dx + math.cos(a + half) * reach,
          center.dy + math.sin(a + half) * reach,
        )
        ..close();
    }
    canvas.drawPath(
      rays,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.cream.withValues(alpha: .55),
            SkyColors.cream.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: h * .9)),
    );
    canvas.drawCircle(
      center,
      h * .36,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.cream.withValues(alpha: .75),
            SkyColors.cream.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: h * .36)),
    );
    // A cloud floor along the bottom, and the bird's shadow on it.
    final floor = Path()..moveTo(0, h);
    const bumps = 7;
    for (var i = 0; i <= bumps; i++) {
      final x = w * i / bumps;
      final y = h - 14 - (i.isEven ? 4 : 0);
      if (i == 0) {
        floor.lineTo(x, y);
      } else {
        floor.quadraticBezierTo(x - w / bumps / 2, y - 12, x, y);
      }
    }
    floor
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      floor,
      Paint()..color = SkyColors.cream.withValues(alpha: .7),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, h - 16),
        width: h * .62,
        height: 11,
      ),
      Paint()..color = SkyColors.ink.withValues(alpha: .12),
    );
    // Sparks, mirrored with the bird so they frame it rather than the name.
    final flip = focus.x < 0;
    for (final (x, y, r) in [
      (.06, .62, 3.0),
      (.52, .2, 4.0),
      (.96, .58, 3.5),
      (.9, .86, 2.5),
    ]) {
      _spark(canvas, Offset(w * (flip ? 1 - x : x), h * y), r, SkyColors.cream);
    }
  }

  @override
  bool shouldRepaint(_ArtWindowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.focus != focus;
}

/// A four-pointed spark, the app's sparkle.
void _spark(Canvas canvas, Offset c, double r, Color color) {
  final l = r * 1.7;
  canvas.drawPath(
    Path()
      ..moveTo(c.dx, c.dy - l)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + l, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + l)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - l, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - l),
    Paint()..color = color,
  );
}

/// A banner across the top corner of a player's window, "PLAYER 1" in white
/// on their colour, with a swallowtail that points into the card. Mirrored,
/// it hangs from the right corner.
class CoopRibbon extends StatelessWidget {
  const CoopRibbon({
    super.key,
    required this.label,
    required this.color,
    this.mirrored = false,
  });
  final String label;
  final Color color;
  final bool mirrored;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _RibbonPainter(color: color, mirrored: mirrored),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        mirrored ? 22 : 14,
        4,
        mirrored ? 14 : 22,
        7,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: heading(
          15,
          color: SkyColors.white,
          weight: FontWeight.w700,
        ).copyWith(letterSpacing: 1.2, height: 1.1, shadows: matchInkEdge(1.1)),
      ),
    ),
  );
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.color, required this.mirrored});
  final Color color;
  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    if (mirrored) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    const lip = 3.0;
    final w = size.width, h = size.height - lip;
    Path band(double dy) => Path()
      ..moveTo(-4, dy)
      ..lineTo(w, dy)
      ..lineTo(w - 9, dy + h / 2)
      ..lineTo(w, dy + h)
      ..lineTo(-4, dy + h)
      ..close();
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final under = band(lip);
    canvas
      ..drawPath(under, Paint()..color = Color.lerp(color, SkyColors.ink, .4)!)
      ..drawPath(under, ink);
    final face = band(0);
    canvas
      ..drawPath(
        face,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, SkyColors.white, .3)!, color],
          ).createShader(Offset.zero & Size(w, h)),
      )
      ..drawPath(face, ink)
      ..drawLine(
        const Offset(6, 3.5),
        Offset(math.min(46, w - 18), 3.5),
        Paint()
          ..color = SkyColors.cream.withValues(alpha: .7)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mirrored != mirrored;
}

/// A small frosted note on a player's window: which half of the sky is
/// theirs.
class CoopHint extends StatelessWidget {
  const CoopHint({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(7, 3, 10, 3),
    decoration: BoxDecoration(
      color: SkyColors.cream.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: SkyColors.ink.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.touch_app_rounded,
          size: 14,
          color: SkyColors.ink.withValues(alpha: .8),
        ),
        const SizedBox(width: 3),
        Text(text, style: bodyText(11.5, weight: FontWeight.w800)),
      ],
    ),
  );
}

/// The paper strip along the bottom of a player's card that holds their
/// four bird choices.
class CoopTray extends StatelessWidget {
  const CoopTray({super.key, required this.color, required this.children});
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    height: 70,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: SkyColors.cream,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: [
        BoxShadow(
          color: Color.lerp(color, SkyColors.ink, .45)!,
          offset: const Offset(0, 2.5),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children,
    ),
  );
}

/// A bird choice's face: a white coin, or for the chosen bird a raised coin
/// in the player's [color] with a check badge on its shoulder.
class CoopPickCoin extends StatelessWidget {
  const CoopPickCoin({
    super.key,
    required this.selected,
    required this.color,
    required this.reducedMotion,
    required this.child,
  });
  final bool selected, reducedMotion;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return SizedBox.square(
      dimension: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: duration,
            curve: Curves.easeOutBack,
            left: 3,
            right: 3,
            top: selected ? 0 : 4,
            height: 54,
            child: AnimatedContainer(
              duration: duration,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Both faces are gradients, so the change between them
                // blends cleanly.
                gradient: RadialGradient(
                  center: const Alignment(-.3, -.4),
                  colors: selected
                      ? [
                          Color.lerp(color, SkyColors.white, .75)!,
                          Color.lerp(color, SkyColors.white, .3)!,
                        ]
                      : const [SkyColors.white, Color(0xfffcf6ea)],
                ),
                border: Border.all(
                  color: selected
                      ? SkyColors.ink
                      : SkyColors.ink.withValues(alpha: .18),
                  width: selected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? Color.lerp(color, SkyColors.ink, .5)!
                        : SkyColors.ink.withValues(alpha: .08),
                    offset: Offset(0, selected ? 4 : 2),
                  ),
                ],
              ),
              child: child,
            ),
          ),
          Positioned(
            top: -3,
            right: -1,
            child: AnimatedScale(
              duration: duration,
              curve: Curves.easeOutBack,
              scale: selected ? 1 : 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(color, SkyColors.ink, .12),
                  border: Border.all(color: SkyColors.ink, width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: SkyColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What sits between the two cards: the co-op [rope] tied to a brass ring on
/// each card with the pair's shared heart hanging from it, two cut ends with
/// no rope, or a clash of sparks behind the VS badge in a duel. [gap] is the
/// space between the cards, centred in the box; [ropeAt] is how far down the
/// rings sit.
///
/// [rope] paints a slack rope from just inside one end of its box to just
/// inside the other, at the box's middle: it is laid out so those ends land
/// on the rings. The heart swings gently unless motion is reduced.
class CoopTether extends StatefulWidget {
  const CoopTether({
    super.key,
    required this.mode,
    required this.gap,
    required this.rope,
    required this.reducedMotion,
    this.ropeAt = .38,
  });
  final CoopMode mode;
  final double gap, ropeAt;
  final Widget rope;
  final bool reducedMotion;

  /// The share of the rope's length its span takes, and how far inside its
  /// box each knot sits, in rope heights: the co-op rope painter's own
  /// proportions.
  static const span = .78, inset = .017, lift = .03;

  @override
  State<CoopTether> createState() => _CoopTetherState();
}

class _CoopTetherState extends State<CoopTether>
    with SingleTickerProviderStateMixin {
  late final clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  bool get still =>
      widget.reducedMotion ||
      MediaQuery.disableAnimationsOf(context) ||
      widget.mode != CoopMode.roped;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CoopTether oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (still) {
      clock
        ..stop()
        ..value = 0;
    } else if (!clock.isAnimating) {
      clock.repeat();
    }
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final y = size.height * widget.ropeAt;
      final mid = size.width / 2;
      // Each ring sits on its card's inner frame.
      final a = Offset(mid - widget.gap / 2 - 4, y);
      final b = Offset(mid + widget.gap / 2 + 4, y);
      final unit = (b.dx - a.dx) / (Tether.length * CoopTether.span);
      const box = 80.0;
      final roped = widget.mode == CoopMode.roped;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TetherPainter(mode: widget.mode, a: a, b: b),
            ),
          ),
          if (roped) ...[
            Positioned(
              left: a.dx - CoopTether.inset * unit,
              width: b.dx - a.dx + 2 * CoopTether.inset * unit,
              top: y - box / 2 + CoopTether.lift * unit,
              height: box,
              child: widget.rope,
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CharmPainter(a: a, b: b, unit: unit, swing: clock),
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// The rings, the cut ends and the clash behind the VS badge.
class _TetherPainter extends CustomPainter {
  const _TetherPainter({required this.mode, required this.a, required this.b});
  final CoopMode mode;
  final Offset a, b;

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case CoopMode.roped:
        _ring(canvas, a);
        _ring(canvas, b);
      case CoopMode.free:
        // Where the rope would hang, a dotted ghost of it.
        final span = b.dx - a.dx;
        final dot = Paint()..color = SkyColors.cream.withValues(alpha: .9);
        for (var i = 3; i <= 13; i++) {
          final t = i / 16;
          canvas.drawCircle(
            Offset(a.dx + span * t, a.dy + span * .8 * t * (1 - t) + 6),
            2.2,
            dot,
          );
        }
        _stub(canvas, a, 1);
        _stub(canvas, b, -1);
      case CoopMode.duel:
        _clash(canvas, Offset((a.dx + b.dx) / 2, a.dy));
    }
  }

  /// A cut end of rope hanging from a ring, frayed at the tip. [side] is
  /// 1 for the left card's end, curling right, and -1 for the right card's.
  void _stub(Canvas canvas, Offset ring, double side) {
    final tip = ring + Offset(10 * side, 30);
    final path = Path()
      ..moveTo(ring.dx, ring.dy)
      ..quadraticBezierTo(ring.dx + 2 * side, ring.dy + 22, tip.dx, tip.dy);
    final round = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(
        path,
        Paint.from(round)
          ..color = SkyColors.ink
          ..strokeWidth = 8,
      )
      ..drawPath(
        path,
        Paint.from(round)
          ..color = _straw
          ..strokeWidth = 4.5,
      );
    // The frayed strands at its tip.
    for (final spread in [-1.0, 0.0, 1.0]) {
      final end = tip + Offset((3 + 4 * spread) * side, 7 - spread.abs());
      canvas
        ..drawLine(
          tip,
          end,
          Paint.from(round)
            ..color = SkyColors.ink
            ..strokeWidth = 3.6,
        )
        ..drawLine(
          tip,
          end,
          Paint.from(round)
            ..color = const Color(0xffe2b16a)
            ..strokeWidth = 1.6,
        );
    }
    _ring(canvas, ring);
  }

  /// Speed lines in each player's colour rushing at the middle, where the
  /// VS badge sits.
  void _clash(Canvas canvas, Offset c) {
    final round = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (player, side) in [(0, -1.0), (1, 1.0)]) {
      for (final (dy, length, from) in [
        (-22.0, 22.0, 50.0),
        (0.0, 30.0, 54.0),
        (22.0, 22.0, 50.0),
      ]) {
        final start = c + Offset(side * (from + length), dy * 1.25);
        final end = c + Offset(side * from, dy);
        canvas
          ..drawLine(
            start,
            end,
            Paint.from(round)
              ..color = SkyColors.ink
              ..strokeWidth = 7.5,
          )
          ..drawLine(
            start,
            end,
            Paint.from(round)
              ..color = TetherArt.players[player]
              ..strokeWidth = 4,
          );
      }
    }
    for (final (dx, dy, r) in [
      (-34.0, -44.0, 4.5),
      (36.0, 42.0, 4.0),
      (40.0, -38.0, 3.0),
      (-38.0, 40.0, 3.0),
    ]) {
      _spark(canvas, c + Offset(dx, dy), r + 1.4, SkyColors.ink);
      _spark(canvas, c + Offset(dx, dy), r, SkyColors.yellow);
    }
  }

  @override
  bool shouldRepaint(_TetherPainter oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.a != a || oldDelegate.b != b;
}

/// The rope's slack straw, as the flight draws it.
const _straw = Color(0xfff9dea0);

/// A brass ring the rope is tied to.
void _ring(Canvas canvas, Offset c) {
  canvas
    ..drawCircle(
      c + const Offset(0, 2),
      11.5,
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    )
    ..drawCircle(c, 11.5, Paint()..color = SkyColors.ink)
    ..drawCircle(
      c,
      9.3,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffffe9a3), SkyColors.gold],
        ).createShader(Rect.fromCircle(center: c, radius: 9.3)),
    )
    ..drawCircle(c, 4.4, Paint()..color = SkyColors.ink)
    ..drawCircle(
      c + const Offset(-3.6, -4.2),
      1.6,
      Paint()..color = SkyColors.white.withValues(alpha: .85),
    );
}

/// A little heart hanging from the middle of the rope: the hearts the pair
/// share. It swings on its string while [swing] runs.
class _CharmPainter extends CustomPainter {
  _CharmPainter({
    required this.a,
    required this.b,
    required this.unit,
    required this.swing,
  }) : super(repaint: swing);
  final Offset a, b;
  final double unit;
  final Animation<double> swing;

  @override
  void paint(Canvas canvas, Size size) {
    // The rope's own sag for this span, so the heart hangs from it.
    final span = (b.dx - a.dx) / unit;
    final slack = math.max(0.0, Tether.length - span);
    final sag = math.sqrt(3 * span * slack / 8);
    final top = Offset((a.dx + b.dx) / 2, a.dy + sag * unit);
    canvas
      ..save()
      ..translate(top.dx, top.dy)
      ..rotate(.12 * math.sin(swing.value * 2 * math.pi));
    const c = Offset(0, 16);
    canvas.drawLine(
      Offset.zero,
      c - const Offset(0, 6),
      Paint()
        ..color = SkyColors.ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final heart = _heartPath(c, 9);
    canvas
      ..drawPath(
        heart.shift(const Offset(0, 2)),
        Paint()..color = SkyColors.ink.withValues(alpha: .25),
      )
      ..drawPath(
        heart,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffff8f9c), Color(0xffe8455a)],
          ).createShader(Rect.fromCircle(center: c, radius: 9)),
      )
      ..drawPath(
        heart,
        Paint()
          ..color = SkyColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(
        c + const Offset(-3.6, -2.6),
        1.8,
        Paint()..color = SkyColors.white.withValues(alpha: .9),
      )
      ..drawCircle(Offset.zero, 2.6, Paint()..color = SkyColors.ink)
      ..restore();
  }

  @override
  bool shouldRepaint(_CharmPainter oldDelegate) =>
      oldDelegate.a != a || oldDelegate.b != b || oldDelegate.unit != unit;
}

Path _heartPath(Offset c, double r) => Path()
  ..moveTo(c.dx, c.dy + r)
  ..cubicTo(
    c.dx - r * 1.6,
    c.dy - r * .05,
    c.dx - r * .95,
    c.dy - r * 1.15,
    c.dx,
    c.dy - r * .4,
  )
  ..cubicTo(
    c.dx + r * .95,
    c.dy - r * 1.15,
    c.dx + r * 1.6,
    c.dy - r * .05,
    c.dx,
    c.dy + r,
  )
  ..close();

/// The VS badge: a jagged burst split between the two players' colours,
/// tilted like a sticker slapped on between them. It fills its box, so it
/// shrinks to fit wherever it is placed.
class CoopVersusBurst extends StatelessWidget {
  const CoopVersusBurst({super.key});

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.1,
    child: CustomPaint(
      painter: const _BurstPainter(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FittedBox(
          child: Text(
            context.l10n.duelVersus,
            style: heading(
              34,
              color: SkyColors.white,
              weight: FontWeight.w700,
            ).copyWith(height: 1, letterSpacing: 1, shadows: matchInkEdge(1.8)),
          ),
        ),
      ),
    ),
  );
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 3;
    Path burst(double r, double depth) {
      final path = Path();
      const points = 12;
      for (var i = 0; i < points * 2; i++) {
        final a = -math.pi / 2 + i * math.pi / points;
        final radius = i.isEven ? r : r * depth;
        final p = c + Offset(math.cos(a), math.sin(a)) * radius;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      return path..close();
    }

    final shape = burst(outer, .78);
    final bounds = Rect.fromCircle(center: c, radius: outer);
    canvas
      ..drawPath(
        shape.shift(const Offset(0, 4)),
        Paint()..color = SkyColors.ink.withValues(alpha: .28),
      )
      ..drawPath(
        shape,
        Paint()
          ..color = SkyColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, .5, .5, 1],
            colors: [
              Color.lerp(TetherArt.players[0], SkyColors.white, .25)!,
              TetherArt.players[0],
              TetherArt.players[1],
              Color.lerp(TetherArt.players[1], SkyColors.ink, .12)!,
            ],
          ).createShader(bounds),
      );
    // A yellow core under the letters, and a cream ring around it.
    final core = burst(outer * .7, .86);
    canvas
      ..drawPath(
        core,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xffffe58a), SkyColors.yellow],
          ).createShader(bounds),
      )
      ..drawPath(
        core,
        Paint()
          ..color = SkyColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawArc(
        Rect.fromCircle(center: c, radius: outer * .52),
        math.pi * 1.05,
        math.pi * .55,
        false,
        Paint()
          ..color = SkyColors.white.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => false;
}

/// A mode's little picture for the mode switch: the two players' birds as
/// round heads, roped together, apart with a cut rope, or clashing with a
/// bolt between them. [muted] greys it out for the modes not chosen.
class CoopModeGlyph extends StatelessWidget {
  const CoopModeGlyph(this.mode, {super.key, this.muted = false});
  final CoopMode mode;
  final bool muted;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 22,
    child: CustomPaint(painter: _ModeGlyphPainter(mode, muted)),
  );
}

class _ModeGlyphPainter extends CustomPainter {
  const _ModeGlyphPainter(this.mode, this.muted);
  final CoopMode mode;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final straw = Paint.from(ink)..color = _straw;
    final h = size.height, w = size.width;
    final left = Offset(7.5, h / 2), right = Offset(w - 7.5, h / 2);
    switch (mode) {
      case CoopMode.roped:
        final rope = Path()
          ..moveTo(left.dx + 4, left.dy + 2)
          ..quadraticBezierTo(w / 2, h + 3, right.dx - 4, right.dy + 2);
        canvas
          ..drawPath(rope, Paint.from(ink)..strokeWidth = 5)
          ..drawPath(rope, Paint.from(straw)..strokeWidth = 2.4);
      case CoopMode.free:
        for (final (from, dir) in [(left, 1.0), (right, -1.0)]) {
          final stub = Path()
            ..moveTo(from.dx + 4 * dir, from.dy + 2)
            ..quadraticBezierTo(
              from.dx + 8 * dir,
              from.dy + 7,
              from.dx + 9 * dir,
              from.dy + 9,
            );
          canvas
            ..drawPath(stub, Paint.from(ink)..strokeWidth = 5)
            ..drawPath(stub, Paint.from(straw)..strokeWidth = 2.4);
        }
      case CoopMode.duel:
        final bolt = Path()
          ..moveTo(w / 2 + 2.5, 1.5)
          ..lineTo(w / 2 - 3.5, h / 2 + 1)
          ..lineTo(w / 2 + .5, h / 2 + 1)
          ..lineTo(w / 2 - 2.5, h - 1.5)
          ..lineTo(w / 2 + 4, h / 2 - 1.5)
          ..lineTo(w / 2, h / 2 - 1.5)
          ..close();
        canvas
          ..drawPath(bolt, Paint()..color = SkyColors.yellow)
          ..drawPath(bolt, Paint.from(ink)..strokeWidth = 1.6);
    }
    for (final (i, c) in [left, right].indexed) {
      final color = TetherArt.players[i];
      canvas
        ..drawCircle(
          c,
          6.5,
          Paint()
            ..color = muted ? Color.lerp(color, SkyColors.cream, .45)! : color,
        )
        ..drawCircle(c, 6.5, Paint.from(ink)..strokeWidth = 2)
        ..drawCircle(
          c + Offset(i == 0 ? 1.8 : -1.8, -1),
          1.3,
          Paint()..color = SkyColors.ink,
        );
    }
  }

  @override
  bool shouldRepaint(_ModeGlyphPainter oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.muted != muted;
}

/// A raised sticker face on a darker lip, for the chosen segment of the
/// mode switch.
class CoopStickerPainter extends CustomPainter {
  const CoopStickerPainter({required this.color, this.radius = 16});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const lip = 3.5, outline = 2.2;
    final base = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final face = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - lip),
      Radius.circular(radius),
    );
    final ink = Paint()..color = SkyColors.ink;
    canvas
      ..drawRRect(base.inflate(outline), ink)
      ..drawRRect(base, Paint()..color = Color.lerp(color, SkyColors.ink, .34)!)
      ..drawRRect(face.inflate(outline), ink)
      ..drawRRect(
        face,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, SkyColors.white, .55)!, color],
            stops: const [0, .6],
          ).createShader(face.outerRect),
      )
      ..drawLine(
        Offset(radius * .8, 3.5),
        Offset(radius * .8 + 22, 3.5),
        Paint()
          ..color = SkyColors.white.withValues(alpha: .85)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(CoopStickerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// A speech bubble whose tail points left at the mode switch, telling the
/// players what the chosen mode means: a bold [lead] and the rest after it.
/// The words shrink rather than overflow under large text.
class CoopBubble extends StatelessWidget {
  const CoopBubble({
    super.key,
    required this.lead,
    required this.body,
    required this.accent,
  });
  final String lead, body;
  final Color accent;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BubblePainter(accent),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 14, 11),
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$lead ',
                    style: bodyText(13.5, weight: FontWeight.w900),
                  ),
                  TextSpan(text: body),
                ],
              ),
              style: bodyText(
                12.5,
                color: SkyColors.ink.withValues(alpha: .78),
              ).copyWith(height: 1.25),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter(this.accent);
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0, lip = 3.0, r = 16.0;
    final body = Rect.fromLTWH(tail, 0, size.width - tail, size.height - lip);
    final mid = body.center.dy;
    final card = RRect.fromRectAndRadius(body, const Radius.circular(r));
    final shape = Path.combine(
      PathOperation.union,
      Path()..addRRect(card),
      Path()
        ..moveTo(tail + 4, mid - 8)
        ..lineTo(0, mid + 2)
        ..lineTo(tail + 4, mid + 8)
        ..close(),
    );
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final under = shape.shift(const Offset(0, lip));
    canvas
      ..drawPath(under, Paint()..color = Color.lerp(accent, SkyColors.ink, .3)!)
      ..drawPath(under, ink)
      ..drawPath(shape, Paint()..color = SkyColors.cream)
      // A band of the mode's colour down the bubble's leading edge.
      ..save()
      ..clipPath(shape)
      ..drawRect(
        Rect.fromLTWH(0, 0, tail + 6, body.height),
        Paint()..color = accent,
      )
      ..restore()
      ..drawPath(shape, ink);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

/// The way into the sky: a big [HomeKey] that breathes and glints to invite
/// the pair in, with the [label] beside an icon coin. Null [onPressed] greys
/// it out while the birds load.
class CoopStartKey extends StatelessWidget {
  const CoopStartKey({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
    required this.reducedMotion,
  });
  final String label;
  final IconData icon;
  final HomeKeyColors colors;
  final VoidCallback? onPressed;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : .55,
        child: IgnorePointer(
          ignoring: !enabled,
          child: ExcludeFocus(
            excluding: !enabled,
            child: HomeKey(
              label: label,
              colors: colors,
              lip: 7,
              radius: 22,
              animated: enabled,
              reducedMotion: reducedMotion,
              onPressed: () {
                if (enabled) onPressed!();
              },
              builder: (context, _) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: heading(24, weight: FontWeight.w700).copyWith(
                            letterSpacing: 1,
                            height: 1,
                            shadows: const [
                              Shadow(
                                color: SkyColors.cream,
                                offset: Offset(0, 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SkyColors.cream,
                        border: Border.all(color: SkyColors.ink, width: 2.2),
                        boxShadow: [
                          BoxShadow(
                            color: colors.lip,
                            offset: const Offset(0, 2.5),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 22, color: SkyColors.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
