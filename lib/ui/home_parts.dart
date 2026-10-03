import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../app_brand.dart';
import '../game/star_art.dart';
import 'control_glyphs.dart';
import 'home_world.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// The pieces of the title screen's menu, each laid out on the 1000 × 450
/// canvas by `HomeScreen`.

class HomeTitle extends StatelessWidget {
  const HomeTitle({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${AppBrand.name}. Every letter lands.',
    header: true,
    child: ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: SizedBox(
          height: 130,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HomeEntrance(
                begin: .07,
                end: .4,
                slide: const Offset(0, -20),
                child: Transform.rotate(
                  angle: -.025,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _TitleWord(
                        'BEAKBOUND',
                        size: 64,
                        color: SkyColors.yellow,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              HomeEntrance(
                begin: .3,
                end: .52,
                slide: const Offset(0, 10),
                curve: Curves.easeOutCubic,
                child: Text(
                  'Every letter lands.',
                  style: bodyText(16, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TitleWord extends StatelessWidget {
  const _TitleWord(this.text, {required this.size, required this.color});
  final String text;
  final double size;
  final Color color;

  Text _layer(TextStyle style) => Text(text, style: style);

  @override
  Widget build(BuildContext context) {
    final style = heading(
      size,
      weight: FontWeight.w700,
    ).copyWith(height: .94, letterSpacing: 3);
    Paint stroke(double width, Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..color = color;
    return Stack(
      children: [
        // A cream sticker edge lifts the lettering off the sky, then the ink
        // outline and a hard drop shadow give it weight.
        _layer(
          style.copyWith(
            foreground: stroke(
              size * .2,
              SkyColors.cream.withValues(alpha: .7),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, 5),
          child: _layer(style.copyWith(foreground: stroke(7, SkyColors.ink))),
        ),
        _layer(style.copyWith(foreground: stroke(6, SkyColors.ink))),
        _layer(style.copyWith(color: color)),
      ],
    );
  }
}

/// Twinkles at the corners of the title lockup.
class HomeTitleSparkles extends StatelessWidget {
  const HomeTitleSparkles({super.key});

  @override
  Widget build(BuildContext context) {
    final motion = HomeMotion.of(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: HomeEntrance(
          begin: .3,
          end: .6,
          pop: .3,
          child: CustomPaint(
            painter: _TwinklePainter(motion.clock, motion.still),
          ),
        ),
      ),
    );
  }
}

class _TwinklePainter extends CustomPainter {
  _TwinklePainter(this.clock, this.still) : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool still;

  static final Path _twinkle = () {
    final p = Path()..moveTo(0, -1);
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      p.quadraticBezierTo(
        math.cos(a + math.pi / 4) * .2,
        math.sin(a + math.pi / 4) * .2,
        math.cos(a + math.pi / 2),
        math.sin(a + math.pi / 2),
      );
    }
    return p..close();
  }();
  static final Paint _fill = Paint()..color = SkyColors.white;
  static final Paint _edge = Paint()
    ..color = SkyColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = .12
    ..strokeJoin = StrokeJoin.round;

  static const _spots = [
    (Offset(488, 79), 12.0, 0.0),
    (Offset(74, 105), 9.0, 2.1),
    (Offset(476, 174), 7.0, 4.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (p, r, phase) in _spots) {
      final glow = still
          ? 1.0
          : math.max(0.0, math.sin(clock.value * 1.6 + phase)) * .5 + .5;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(still ? 0 : math.sin(clock.value + phase) * .12);
      canvas.scale(r * (.6 + .4 * glow));
      canvas.drawPath(_twinkle, _fill);
      canvas.drawPath(_twinkle, _edge);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TwinklePainter oldDelegate) => oldDelegate.still != still;
}

/// The best flight so far, or an invitation while there is no Star Trail
/// score to show.
class HomeBestPill extends StatelessWidget {
  const HomeBestPill({
    super.key,
    required this.best,
    this.control,
    this.firstFlight = false,
  });

  /// Star points of the best Star Trail flight, with the control that earned
  /// them; zero before the first one.
  final int best;
  final FlyControl? control;

  /// Nobody has flown yet, so the invitation is a welcome.
  final bool firstFlight;

  @override
  Widget build(BuildContext context) {
    final invite = best <= 0 || control == null;
    final invitation = firstFlight
        ? 'Your first flight awaits'
        : 'Your next flight awaits';
    return Semantics(
      label: invite
          ? '$invitation.'
          : 'Best flight: $best star points, ${control!.label.toLowerCase()}.',
      excludeSemantics: true,
      child: Container(
        height: 46,
        padding: const EdgeInsets.fromLTRB(9, 0, 16, 0),
        decoration: BoxDecoration(
          color: SkyColors.cream.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: Colors.white.withValues(alpha: .85),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: SkyColors.ink.withValues(alpha: .1),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomPaint(size: Size(30, 30), painter: _MedalPainter()),
            const SizedBox(width: 9),
            if (invite)
              Text(invitation, style: heading(15))
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BEST · ${control!.label.toUpperCase()}',
                    style: bodyText(
                      10.5,
                      color: SkyColors.muted,
                      weight: FontWeight.w900,
                    ).copyWith(letterSpacing: .8, height: 1),
                  ),
                  Text('$best stars', style: heading(20).copyWith(height: 1)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  const _MedalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, 14.6, Paint()..color = SkyColors.gold);
    canvas.drawCircle(center, 13, Paint()..color = SkyColors.yellow);
    canvas.drawCircle(
      center,
      14.6,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    StarArt.mini(canvas, center + const Offset(0, .5), 9.2, outline: 1.5);
  }

  @override
  bool shouldRepaint(_MedalPainter oldDelegate) => false;
}

/// A single line that tells a new player their body is the controller.
class HomeHooks extends StatelessWidget {
  const HomeHooks({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Fly with push-ups, squats, jumps or taps.',
    excludeSemantics: true,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: SkyColors.cream.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white.withValues(alpha: .7),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, control) in FlyControl.values.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            ControlGlyph(control, size: 28),
            const SizedBox(width: 5),
            Text(control.label, style: bodyText(12.5, weight: FontWeight.w900)),
          ],
        ],
      ),
    ),
  );
}

/// A shortcut in the dock: a little illustrated object and its name.
class HomeDockItem extends StatefulWidget {
  const HomeDockItem({
    super.key,
    required this.label,
    required this.art,
    required this.onTap,
    this.badge,
    this.semanticLabel,
    this.glow,
  });
  final String label;
  final Widget art;
  final VoidCallback onTap;
  final Widget? badge, glow;
  final String? semanticLabel;

  @override
  State<HomeDockItem> createState() => _HomeDockItemState();
}

class _HomeDockItemState extends State<HomeDockItem> {
  bool pressed = false;

  void _tap() {
    UiSounds.effect(context);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      onTap: _tap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _tap,
          onHighlightChanged: (v) => setState(() => pressed = v),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedScale(
            scale: pressed && !still ? .93 : 1,
            duration: const Duration(milliseconds: 90),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 68,
                  height: 54,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (widget.glow != null)
                        Positioned.fill(child: widget.glow!),
                      Positioned.fill(child: widget.art),
                      if (widget.badge != null)
                        Positioned(right: -6, bottom: -2, child: widget.badge!),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(widget.label, style: heading(14.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small tag on a dock item: a count, or a check when everything is done.
class HomeBadge extends StatelessWidget {
  const HomeBadge(this.text, {super.key, this.done = false});
  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: done ? SkyColors.yellow : SkyColors.coral,
      border: Border.all(color: SkyColors.ink, width: 1.8),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (done) ...[
          const Icon(Icons.check_rounded, size: 13, color: SkyColors.ink),
          const SizedBox(width: 2),
        ],
        Text(
          text,
          style: bodyText(
            11.5,
            color: done ? SkyColors.ink : SkyColors.cream,
            weight: FontWeight.w900,
          ).copyWith(height: 1.1),
        ),
      ],
    ),
  );
}

/// A pulsing glow that makes today's adventure hard to miss while it is open,
/// and a ring of stars once it is done.
class HomeAdventureGlow extends StatelessWidget {
  const HomeAdventureGlow({super.key, required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    final motion = HomeMotion.of(context);
    return IgnorePointer(
      child: CustomPaint(
        painter: _GlowPainter(motion.clock, motion.still, done),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.clock, this.still, this.done) : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool still, done;

  // Unit-radius glows, placed with the canvas transform so a frame allocates
  // nothing.
  static Paint _glow(Color color, double alpha) =>
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
          stops: const [.35, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
  static final Paint _open = _glow(SkyColors.yellow, .75);
  static final Paint _done = _glow(SkyColors.gold, .7);

  @override
  void paint(Canvas canvas, Size size) {
    final t = still ? 0.0 : clock.value;
    final center = size.center(const Offset(0, -1));
    final pulse = still ? .5 : .5 + .5 * math.sin(t * 2.6);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(33 + pulse * 5);
    canvas.drawCircle(Offset.zero, 1, done ? _done : _open);
    canvas.restore();
    if (done) {
      for (var i = 0; i < 3; i++) {
        final a = t * .9 + i * 2 * math.pi / 3 - math.pi / 2;
        StarArt.mini(
          canvas,
          center + Offset(math.cos(a) * 36, math.sin(a) * 27),
          5.5,
          outline: 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) =>
      oldDelegate.still != still || oldDelegate.done != done;
}
