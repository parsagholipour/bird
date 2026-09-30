import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../game/star_art.dart';
import 'home_world.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// The way into the campaign, beside Play. It is built like Play's key (a
/// face on a lip, a cream ring and a streak of light) in mint, so the two read
/// as a pair, with a little map on the face and the level stars earned so far
/// on a tag that hangs below it.
///
/// Lay it out in a box [width] wide and [height] tall: the key fills the top
/// 76 of it, as tall as Play's, and the tag hangs into the rest.
class HomeCampaignButton extends StatefulWidget {
  const HomeCampaignButton({
    super.key,
    required this.stars,
    required this.of,
    required this.onPressed,
  });

  static const width = 100.0, height = 88.0;

  /// Level stars earned, out of those this build offers.
  final int stars, of;
  final VoidCallback onPressed;

  @override
  State<HomeCampaignButton> createState() => _HomeCampaignButtonState();
}

class _HomeCampaignButtonState extends State<HomeCampaignButton> {
  bool pressed = false, focused = false;

  void _tap() {
    UiSounds.effect(context);
    widget.onPressed();
  }

  // The face sits this far above the lip, and sinks most of the way when
  // pressed, as Play's does.
  static const _lift = 8.0, _sink = 5.0, _face = 68.0;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final motion = HomeMotion.of(context);
    final done = widget.of > 0 && widget.stars >= widget.of;
    final radius = BorderRadius.circular(24);
    final ink = Border.all(color: SkyColors.ink, width: 2.5);
    return Semantics(
      button: true,
      label: 'Campaign. ${widget.stars} of ${widget.of} stars.',
      onTap: _tap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          // The key shows its own pressed state, so no ink over the tag.
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: _tap,
          onHighlightChanged: (v) => setState(() => pressed = v),
          onFocusChange: (v) => setState(() => focused = v),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (focused)
                Positioned(
                  top: 0,
                  height: _face,
                  left: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: const [
                        BoxShadow(color: SkyColors.ink, spreadRadius: 7),
                        BoxShadow(color: SkyColors.cream, spreadRadius: 5),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: _lift,
                height: _face,
                left: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xff2f8c69),
                    borderRadius: radius,
                    border: ink,
                    boxShadow: [
                      // A soft glow keeps the mint off the pale sky, as
                      // Play's warm one lifts it.
                      BoxShadow(
                        color: const Color(0xff7fe0a8).withValues(alpha: .5),
                        offset: const Offset(0, 6),
                        blurRadius: 22,
                      ),
                      BoxShadow(
                        color: SkyColors.ink.withValues(alpha: .16),
                        offset: const Offset(0, 4),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                height: _face,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: still
                      ? Duration.zero
                      : const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(
                    0,
                    pressed && !still ? _sink : 0,
                    0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: ink,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: pressed
                          ? const [Color(0xffa9e6bf), Color(0xff55b984)]
                          : const [Color(0xffc4f0d3), Color(0xff69c893)],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: SkyColors.cream.withValues(alpha: .55),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Large system text shrinks to fit rather than spill.
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 11),
                          child: Column(
                            children: [
                              Expanded(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    size: const Size(60, 36),
                                    painter: _MapPainter(
                                      motion.clock,
                                      motion.still || still,
                                    ),
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Campaign',
                                  style: heading(17.5, weight: FontWeight.w700)
                                      .copyWith(
                                        height: 1.05,
                                        shadows: const [
                                          Shadow(
                                            color: SkyColors.cream,
                                            offset: Offset(0, 1.2),
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // The star total hangs below, over the lip.
                      Positioned(
                        bottom: _face - HomeCampaignButton.height,
                        left: 0,
                        right: 0,
                        height: 22,
                        child: Center(
                          child: _StarTag(
                            stars: widget.stars,
                            of: widget.of,
                            done: done,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The stars earned in the campaign so far, as a small tag: the map screen's
/// pill in miniature, gold once every star is in.
class _StarTag extends StatelessWidget {
  const _StarTag({required this.stars, required this.of, required this.done});
  final int stars, of;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.fromLTRB(5, 0, 8, 0),
    decoration: BoxDecoration(
      color: done ? SkyColors.yellow : SkyColors.cream,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .18),
          offset: const Offset(0, 2),
        ),
      ],
    ),
    // A longer total shrinks to fit the key's width rather than spill.
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomPaint(size: Size(15, 15), painter: _StarPainter()),
          const SizedBox(width: 3),
          Text.rich(
            TextSpan(
              text: '$stars',
              style: heading(14.5, weight: FontWeight.w700),
              children: [
                TextSpan(
                  text: ' / $of',
                  style: bodyText(
                    12,
                    color: SkyColors.muted,
                    weight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            style: const TextStyle(height: 1),
          ),
        ],
      ),
    ),
  );
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) => StarArt.mini(
    canvas,
    size.center(Offset.zero),
    size.shortestSide * .5,
    outline: 1.2,
  );

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}

/// A little folded map with a dotted mail route to a pin. The pin hops now
/// and then, and stays put when [still].
class _MapPainter extends CustomPainter {
  _MapPainter(this.clock, this.still) : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool still;

  // Drawn on a 60 × 36 grid and scaled to the box.
  static const _grid = Size(60, 36);
  static const _top = [3.0, 0.0, 3.0, 0.0], _bottom = [36.0, 33.0, 36.0, 33.0];
  static const _paper = [
    Color(0xfffff3d6),
    Color(0xffeedcb4),
    Color(0xfffff3d6),
  ];
  static const _tip = Offset(47, 20);
  static const _hopEvery = 3.6, _hopFor = .7;

  static final Path _route = Path()
    ..moveTo(8, 28)
    ..cubicTo(14, 17, 21, 34, 29, 25)
    ..cubicTo(35, 18, 39, 24, _tip.dx - 1, _tip.dy - 1);

  static final List<Path> _panels = [
    for (var i = 0; i < 3; i++)
      Path()
        ..moveTo(20.0 * i, _top[i])
        ..lineTo(20.0 * (i + 1), _top[i + 1])
        ..lineTo(20.0 * (i + 1), _bottom[i + 1])
        ..lineTo(20.0 * i, _bottom[i])
        ..close(),
  ];

  static final Path _silhouette = _panels.reduce(
    (a, b) => Path.combine(PathOperation.union, a, b),
  );

  static final List<Offset> _dots = () {
    final dots = <Offset>[];
    for (final metric in _route.computeMetrics()) {
      for (var d = 0.0; d < metric.length - 2; d += 4.8) {
        dots.add(metric.getTangentForOffset(d)!.position);
      }
    }
    return dots;
  }();

  static Paint _line(double width) => Paint()
    ..color = SkyColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(
      math.min(size.width / _grid.width, size.height / _grid.height),
    );
    canvas.rotate(-.06);
    canvas.translate(-_grid.width / 2, -_grid.height / 2);

    canvas.drawPath(
      _silhouette.shift(const Offset(0, 2)),
      Paint()..color = SkyColors.ink.withValues(alpha: .16),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawPath(_panels[i], Paint()..color = _paper[i]);
    }
    // Land and water on the paper, cut off at the map's edge.
    canvas.save();
    canvas.clipPath(_silhouette);
    canvas.drawOval(
      const Rect.fromLTRB(-3, 12, 13, 26),
      Paint()..color = SkyColors.mint,
    );
    canvas.drawOval(
      const Rect.fromLTRB(22, 3, 36, 12),
      Paint()..color = SkyColors.sky,
    );
    canvas.drawOval(
      const Rect.fromLTRB(41, 22, 63, 38),
      Paint()..color = SkyColors.mint,
    );
    canvas.restore();
    for (final panel in _panels) {
      canvas.drawPath(panel, _line(1.8));
    }

    final route = Paint()..color = SkyColors.coralDeep;
    for (final dot in _dots) {
      canvas.drawCircle(dot, 1.45, route);
    }
    // Where the courier starts.
    canvas.drawCircle(_dots.first, 3, Paint()..color = SkyColors.cream);
    canvas.drawCircle(_dots.first, 3, _line(1.5));

    final t = still ? 0.0 : clock.value % _hopEvery;
    final hop = t < _hopFor ? math.sin(t / _hopFor * math.pi) * 3.2 : 0.0;
    _pin(canvas, _tip, hop);
    canvas.restore();
  }

  void _pin(Canvas canvas, Offset tip, double lift) {
    canvas.drawOval(
      Rect.fromCenter(center: tip, width: 8 - lift, height: 2.4),
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    );
    final at = tip.translate(0, -lift);
    final head = at.translate(0, -9.4);
    const r = 5.6;
    final drop = Path()
      ..moveTo(at.dx, at.dy)
      ..cubicTo(
        at.dx - 2.6,
        at.dy - 3.6,
        at.dx - r,
        head.dy + 3.2,
        at.dx - r,
        head.dy,
      )
      ..arcToPoint(Offset(at.dx + r, head.dy), radius: const Radius.circular(r))
      ..cubicTo(
        at.dx + r,
        head.dy + 3.2,
        at.dx + 2.6,
        at.dy - 3.6,
        at.dx,
        at.dy,
      )
      ..close();
    canvas.drawPath(drop, Paint()..color = SkyColors.coral);
    canvas.drawPath(drop, _line(1.7));
    canvas.drawCircle(head, 2.3, Paint()..color = SkyColors.cream);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => oldDelegate.still != still;
}
