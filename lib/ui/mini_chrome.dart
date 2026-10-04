import 'package:flutter/material.dart';
import '../domain/tracking.dart';
import 'campaign_chrome.dart' show MapGlyph, MapKey;
import 'home_keys.dart';
import 'match_hud.dart' show MatchPlate, matchInkEdge;
import 'theme.dart';
import 'ui_sounds.dart';

/// The screens behind the Mini games picker (each workout's camera setup and
/// calibration, and Fly Together) dressed in the title screen's material:
/// ink-outlined cards on a colored lip, sticker plates for tags and round
/// keys, and a [HomeKey] for the way on. Each workout keeps the color its
/// card has in the picker.

/// A workout's color, as its card in the Mini games picker shows it.
Color miniColor(PlayMode mode) => switch (mode) {
  PlayMode.pushUp => SkyColors.yellow,
  PlayMode.squat => SkyColors.coral,
  PlayMode.jump => SkyColors.lavender,
  PlayMode.touch => SkyColors.skyDeep,
};

/// The key that starts a workout, in its color.
HomeKeyColors miniKeyColors(PlayMode mode) => switch (mode) {
  PlayMode.pushUp => HomeKeyColors.sun,
  PlayMode.squat => HomeKeyColors.coral,
  PlayMode.jump => HomeKeyColors.lavender,
  PlayMode.touch => HomeKeyColors.sun,
};

/// A screen title on the sky: cream lettering with an ink edge, like the
/// Mini games picker's, after the map's round back key.
class MiniHeader extends StatelessWidget {
  const MiniHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.leading = const [],
    this.trailing = const [],
    this.size = 28,
  });
  final String title;
  final VoidCallback onBack;

  /// Tags right after the title.
  final List<Widget> leading;

  /// Tags and keys at the far end of the row.
  final List<Widget> trailing;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      MapKey(glyph: MapGlyph.back, label: 'Back home', onPressed: onBack),
      const SizedBox(width: 16),
      // The title shrinks to fit rather than lose its end, and the tags
      // after it follow; the trailing tags keep to the far edge.
      Expanded(
        child: Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: heading(
                      size,
                      color: SkyColors.cream,
                      weight: FontWeight.w700,
                    ).copyWith(letterSpacing: .4, shadows: matchInkEdge(1.6)),
                  ),
                ),
              ),
            ),
            for (final tag in leading) ...[const SizedBox(width: 12), tag],
          ],
        ),
      ),
      if (trailing.isNotEmpty) const SizedBox(width: 12),
      for (final (i, tag) in trailing.indexed) ...[
        if (i > 0) const SizedBox(width: 10),
        tag,
      ],
    ],
  );
}

/// A small sticker plate: an icon and a few capital words.
class MiniTag extends StatelessWidget {
  const MiniTag(
    this.label, {
    super.key,
    this.icon,
    this.color = SkyColors.cream,
    this.foreground = SkyColors.ink,
  });
  final String label;
  final IconData? icon;
  final Color color, foreground;

  @override
  Widget build(BuildContext context) {
    final light = foreground == SkyColors.white;
    return MatchPlate(
      color: color,
      padding: const EdgeInsets.fromLTRB(11, 5, 13, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: bodyText(12, color: foreground, weight: FontWeight.w900)
                .copyWith(
                  letterSpacing: .6,
                  shadows: light ? matchInkEdge(1) : null,
                ),
          ),
        ],
      ),
    );
  }
}

/// A paper card with an ink outline on a lip of [accent], like the cards in
/// the Mini games picker.
class MiniCard extends StatelessWidget {
  const MiniCard({
    super.key,
    required this.child,
    this.accent = SkyColors.teal,
    this.color = SkyColors.cream,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });
  final Widget child;
  final Color accent, color;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Color.lerp(accent, SkyColors.ink, .4),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: SkyColors.ink, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .2),
          offset: const Offset(0, 6),
          blurRadius: 10,
        ),
      ],
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius - 2.5),
        border: const Border(
          bottom: BorderSide(color: SkyColors.ink, width: 2.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

/// The top of a [MiniCard] in its accent: a soft wash with a few sparks that
/// flows into the paper in a wave, as the picker's cards do. Lay it edge to
/// edge (the card's own padding zero) and paint the illustration over it.
class MiniArtBand extends StatelessWidget {
  const MiniArtBand({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BandPainter(color),
    child: Padding(padding: const EdgeInsets.only(bottom: 10), child: child),
  );
}

class _BandPainter extends CustomPainter {
  const _BandPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, SkyColors.cream, .72)!,
            Color.lerp(color, SkyColors.cream, .38)!,
          ],
        ).createShader(rect),
    );
    final glow = Paint()..color = SkyColors.cream.withValues(alpha: .35);
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .55),
      size.height * .46,
      glow,
    );
    final spark = Paint()..color = SkyColors.cream;
    for (final (x, y, r) in [
      (.08, .22, 4.0),
      (.9, .18, 5.0),
      (.94, .62, 3.0),
      (.14, .7, 3.0),
    ]) {
      final c = Offset(size.width * x, size.height * y);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r * 1.6)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 1.6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 1.6)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 1.6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 1.6),
        spark,
      );
    }
    final h = size.height, w = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(0, h - 6)
        ..quadraticBezierTo(w * .25, h - 16, w * .52, h - 6)
        ..quadraticBezierTo(w * .8, h + 3, w, h - 9)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = SkyColors.cream,
    );
  }

  @override
  bool shouldRepaint(_BandPainter oldDelegate) => oldDelegate.color != color;
}

/// A numbered coin for a list of steps.
class MiniStepCoin extends StatelessWidget {
  const MiniStepCoin(this.number, {super.key, this.color = SkyColors.yellow});
  final String number;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: const [
        BoxShadow(color: SkyColors.ink, offset: Offset(0, 2.5)),
      ],
    ),
    child: Text(
      number,
      style: heading(16, weight: FontWeight.w700).copyWith(height: 1),
    ),
  );
}

/// The way on from a mini game's screen: a [HomeKey] with a title and an
/// icon. Laid out [height] tall; null [onPressed] greys it out, and [busy]
/// swaps the icon for a spinner.
class MiniKey extends StatelessWidget {
  const MiniKey({
    super.key,
    required this.label,
    required this.colors,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 64,
    this.size = 21,
    this.busy = false,
  });
  final String label;
  final HomeKeyColors colors;
  final VoidCallback? onPressed;
  final IconData icon;
  final double height, size;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return SizedBox(
      height: height,
      child: Semantics(
        button: true,
        enabled: enabled,
        value: busy ? 'Busy' : null,
        liveRegion: busy,
        child: Opacity(
          opacity: enabled || busy ? 1 : .55,
          child: IgnorePointer(
            ignoring: !enabled,
            child: ExcludeFocus(
              excluding: !enabled,
              child: HomeKey(
                label: label,
                colors: colors,
                lip: 6,
                radius: 20,
                onPressed: () {
                  if (enabled) onPressed!();
                },
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: heading(size, weight: FontWeight.w700)
                                .copyWith(
                                  letterSpacing: .6,
                                  height: 1,
                                  shadows: const [
                                    Shadow(
                                      color: SkyColors.cream,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox.square(
                            dimension: 22,
                            child: busy
                                ? CircularProgressIndicator(
                                    value:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? .75
                                        : null,
                                    strokeWidth: 2.5,
                                    color: SkyColors.ink,
                                  )
                                : Icon(icon, size: 22, color: SkyColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round sticker key with an icon, beside the map's back key: switch
/// camera, camera settings.
class MiniRoundKey extends StatefulWidget {
  const MiniRoundKey({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<MiniRoundKey> createState() => _MiniRoundKeyState();
}

class _MiniRoundKeyState extends State<MiniRoundKey> {
  bool pressed = false, focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final still = MediaQuery.disableAnimationsOf(context);
    final ring =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: enabled ? _press : null,
      child: Tooltip(
        message: widget.label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: enabled ? _press : null,
            onFocusChange: (value) => setState(() => focused = value),
            onHighlightChanged: (value) => setState(() => pressed = value),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  if (ring)
                    const BoxShadow(color: SkyColors.gold, spreadRadius: 7),
                ],
              ),
              child: Opacity(
                opacity: enabled ? 1 : .5,
                child: Transform.translate(
                  offset: Offset(0, pressed && !still ? 3 : 0),
                  child: MatchPlate(
                    padding: EdgeInsets.zero,
                    child: SizedBox.square(
                      dimension: MapKey.size,
                      child: Icon(widget.icon, color: SkyColors.ink, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _press() {
    UiSounds.effect(context);
    widget.onPressed!();
  }
}
