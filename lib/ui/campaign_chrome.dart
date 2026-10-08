import 'dart:math' show pi;
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'campaign_map_art.dart' show MapPadlockPainter, MapRibbonPainter;
import 'campaign_text_scale.dart';
import 'keyboard.dart' show BackKeyTarget;
import 'match_hud.dart' show MatchIcon, MatchPlate, MatchSymbol, matchDigits;
import 'theme.dart';
import 'ui_sounds.dart';

/// What a [MapKey] shows on its face.
enum MapGlyph { back, close, previous, next, settings }

/// A round key in the flight HUD's sticker material (an ink-outlined face on
/// a lip, like Pause), for the back key and the stop arrows around the map.
/// Every piece of chrome on the map shares that material, so none of it
/// vanishes into the cloud banks or the scenery behind. The menus' back keys
/// and the close keys on their dialogs are the same key, so the way out
/// looks the same everywhere.
///
/// Pressing sinks the key into its lip; with Reduced Motion it stays put and
/// a held press shades the face instead.
class MapKey extends StatefulWidget {
  const MapKey({
    super.key,
    required this.glyph,
    required this.label,
    required this.onPressed,
    this.reducedMotion = false,
  });
  final MapGlyph glyph;

  /// The tooltip and the spoken name, such as "Back home".
  final String label;
  final VoidCallback onPressed;
  final bool reducedMotion;

  /// The face's width and height: the smallest touch target.
  static const size = 48.0;

  @override
  State<MapKey> createState() => _MapKeyState();
}

class _MapKeyState extends State<MapKey> {
  bool pressed = false, focused = false;

  void _press() {
    UiSounds.effect(context, switch (widget.glyph) {
      MapGlyph.back || MapGlyph.close => 'ui_back',
      MapGlyph.previous || MapGlyph.next || MapGlyph.settings => 'ui_tap',
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final still =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    // The same gold keyboard ring as the HUD's keys; a pointer stays quiet.
    final ring =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final key = Semantics(
      button: true,
      label: widget.label,
      onTap: _press,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: _press,
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
              child: Transform.translate(
                offset: Offset(0, pressed && !still ? 3 : 0),
                child: MatchPlate(
                  padding: EdgeInsets.zero,
                  child: SizedBox.square(
                    dimension: MapKey.size,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pressed && still
                            ? SkyColors.ink.withValues(alpha: .1)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size.square(24),
                          painter: _GlyphPainter(
                            widget.glyph,
                            rtl:
                                Directionality.of(context) == TextDirection.rtl,
                          ),
                        ),
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
    // Esc presses the screen's back or close key.
    return switch (widget.glyph) {
      MapGlyph.back ||
      MapGlyph.close => BackKeyTarget(onBack: _press, child: key),
      MapGlyph.previous || MapGlyph.next || MapGlyph.settings => key,
    };
  }
}

/// A chunky arrow, cross, chevron or cog: round caps and a stroke as heavy as
/// the HUD's pause bars, so the face reads at a glance.
///
/// The back arrow points the way back in the reading direction: right in a
/// right-to-left language ([rtl]). The map's step chevrons point along the
/// route, which runs left to right in every language, so they never turn.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, {this.rtl = false});
  final MapGlyph glyph;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (rtl && glyph == MapGlyph.back) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final s = size.width / 24;
    canvas.scale(s);
    final path = Path();
    switch (glyph) {
      case MapGlyph.back:
        path
          ..moveTo(21, 12)
          ..lineTo(3.5, 12)
          ..moveTo(11.5, 4)
          ..lineTo(3.5, 12)
          ..lineTo(11.5, 20);
      case MapGlyph.close:
        path
          ..moveTo(5.5, 5.5)
          ..lineTo(18.5, 18.5)
          ..moveTo(18.5, 5.5)
          ..lineTo(5.5, 18.5);
      case MapGlyph.previous:
        path
          ..moveTo(15, 3.5)
          ..lineTo(6.5, 12)
          ..lineTo(15, 20.5);
      case MapGlyph.next:
        path
          ..moveTo(9, 3.5)
          ..lineTo(17.5, 12)
          ..lineTo(9, 20.5);
      case MapGlyph.settings:
        return _cog(canvas);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Eight round teeth on a solid wheel with a cream hub.
  static void _cog(Canvas canvas) {
    const c = Offset(12, 12);
    var cog = Path()..addOval(Rect.fromCircle(center: c, radius: 7.6));
    for (var i = 0; i < 8; i++) {
      final tooth = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(0, -8.6), width: 5, height: 5),
            const Radius.circular(1.6),
          ),
        );
      cog = Path.combine(
        PathOperation.union,
        cog,
        tooth.transform(
          (Matrix4.translationValues(
            c.dx,
            c.dy,
            0,
          )..rotateZ(i * pi / 4)).storage,
        ),
      );
    }
    canvas.drawPath(cog, Paint()..color = SkyColors.ink);
    canvas.drawCircle(c, 3.6, Paint()..color = SkyColors.cream);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.rtl != rtl;
}

/// The campaign's star total, "12 / 48", on a plate in the same material as
/// the keys and the same height as the back key, so the two corners pair up.
class CampaignStarTotal extends StatelessWidget {
  const CampaignStarTotal({super.key, required this.stars, required this.of});
  final int stars, of;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.campaignStarTotalSemantics(stars, of),
    excludeSemantics: true,
    child: CampaignTextScale.wrap(
      MatchPlate(
        key: const ValueKey('campaign-star-total'),
        padding: const EdgeInsets.fromLTRB(9, 0, 18, 0),
        child: SizedBox(
          height: MapKey.size,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MatchIcon(MatchSymbol.star, size: 32),
              const SizedBox(width: 6),
              Text('$stars', style: matchDigits(23).copyWith(height: 1)),
              Text(
                ' / $of',
                style: heading(
                  17,
                  color: SkyColors.muted,
                  weight: FontWeight.w600,
                ).copyWith(height: 1),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A cream coin with the yellow padlock, for a locked stop's name and for
/// the notices about what is locked.
class MapPadlockCoin extends StatelessWidget {
  const MapPadlockCoin({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: SkyColors.cream,
      shape: BoxShape.circle,
      border: Border.all(color: SkyColors.ink, width: size * .06),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .2),
          offset: Offset(0, size * .075),
        ),
      ],
    ),
    padding: EdgeInsets.all(size * .2),
    child: const CustomPaint(
      painter: MapPadlockPainter(color: SkyColors.ink, fill: SkyColors.yellow),
    ),
  );
}

/// The map's notice: a yellow ribbon with ink lettering. "Coming soon"
/// across a stop's clouds and the answer to a tap on a locked level are the
/// same ribbon, at two sizes; [locked] adds the padlock coin.
class MapNotice extends StatelessWidget {
  const MapNotice(this.text, {super.key, this.size = 22, this.locked = false});
  final String text;

  /// The lettering's size; the ribbon and its tails follow.
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) => CampaignTextScale.wrap(
    CustomPaint(
      painter: const MapRibbonPainter(
        color: SkyColors.yellow,
        shade: SkyColors.gold,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          locked ? size : size * 1.4,
          size * .3,
          size * 1.4,
          size * .62,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) ...[
              MapPadlockCoin(size: size * 1.5),
              SizedBox(width: size * .45),
            ],
            Text(
              text,
              style: heading(size, weight: FontWeight.w700).copyWith(height: 1),
            ),
          ],
        ),
      ),
    ),
  );
}
