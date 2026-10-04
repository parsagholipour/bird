import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/tracking.dart';
import 'campaign_chrome.dart' show MapGlyph, MapKey;
import 'components.dart' show Pill;
import 'home_keys.dart';
import 'match_hud.dart' show MatchPlate, matchInkEdge;
import 'theme.dart';
import 'ui_sounds.dart';

/// The screens behind the Mini games picker (each workout's camera setup and
/// calibration, and Fly Together) dressed in the title screen's material:
/// ink-outlined cards on a colored lip, sticker plates for tags and round
/// keys, and a [HomeKey] for the way on. Each workout keeps the color its
/// card has in the picker. The title screen's shelf (Adventure, Birds,
/// Passport, Records) and Settings wear the same material.

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
  Widget build(BuildContext context) =>
      Pill(label, icon: icon, color: color, foreground: foreground);
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

/// A sticker plate that is a key: an icon and a few words on a pill, as tall
/// as the round keys, for a side trip such as Saved sessions.
class MiniPillKey extends StatefulWidget {
  const MiniPillKey({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = SkyColors.cream,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  State<MiniPillKey> createState() => _MiniPillKeyState();
}

class _MiniPillKeyState extends State<MiniPillKey> {
  bool pressed = false, focused = false;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final ring =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: _press,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          onTap: _press,
          onFocusChange: (value) => setState(() => focused = value),
          onHighlightChanged: (value) => setState(() => pressed = value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MapKey.size),
              boxShadow: [
                if (ring)
                  const BoxShadow(color: SkyColors.gold, spreadRadius: 7),
              ],
            ),
            child: Transform.translate(
              offset: Offset(0, pressed && !still ? 3 : 0),
              child: MatchPlate(
                color: pressed && still
                    ? Color.lerp(widget.color, SkyColors.ink, .1)!
                    : widget.color,
                padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
                child: SizedBox(
                  height: MapKey.size,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 22, color: SkyColors.ink),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: bodyText(15, weight: FontWeight.w900),
                      ),
                    ],
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
    widget.onPressed();
  }
}

/// A round coin with an ink outline and an icon, the way a row in a list
/// names what it is about. [muted] greys it for something not yet earned.
class MiniCoin extends StatelessWidget {
  const MiniCoin({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.muted = false,
  });
  final IconData icon;
  final Color color;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: muted ? Color.lerp(SkyColors.cream, SkyColors.sky, .5) : color,
      shape: BoxShape.circle,
      border: Border.all(
        color: muted ? SkyColors.ink.withValues(alpha: .45) : SkyColors.ink,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: muted ? SkyColors.ink.withValues(alpha: .2) : SkyColors.ink,
          offset: const Offset(0, 2.5),
        ),
      ],
    ),
    child: Icon(
      icon,
      size: size * .55,
      color: muted ? SkyColors.muted : SkyColors.ink,
    ),
  );
}

/// A chunky progress bar: a cream groove with an ink outline, filled with
/// [color] up to [value] and lit along its top.
class MiniMeter extends StatelessWidget {
  const MiniMeter({
    super.key,
    required this.value,
    required this.color,
    this.height = 12,
  });

  /// From 0 to 1.
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: CustomPaint(
      painter: _MeterPainter(value.clamp(0, 1).toDouble(), color),
    ),
  );
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final groove = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(
      groove,
      Paint()..color = Color.lerp(SkyColors.cream, SkyColors.sky, .55)!,
    );
    if (value > 0) {
      // Never narrower than its own height, so a first step still reads.
      final width = size.height + (size.width - size.height) * value;
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, size.height),
        radius,
      );
      canvas.save();
      canvas.clipRRect(groove);
      canvas.drawRRect(fill, Paint()..color = color);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.height * .45,
            size.height * .22,
            math.max(0, width - size.height * .9),
            size.height * .2,
          ),
          Radius.circular(size.height * .1),
        ),
        Paint()..color = SkyColors.white.withValues(alpha: .6),
      );
      canvas.restore();
    }
    canvas.drawRRect(
      groove.deflate(1),
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_MeterPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
