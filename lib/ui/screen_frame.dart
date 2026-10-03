import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'theme.dart';

/// Lays the whole app out on the reference phone, [design] (792 × 360 dp,
/// 2.2:1), and scales it to fit the display, with navy bars on whatever is
/// left. Every device so shows the same picture: a flight always sees a
/// 2.2-wide sky (the rules' `viewportWidth`), and the menus, map and story
/// compose as they do on that phone. A tap on a bar lands on the nearest edge
/// of the picture, so the whole display still flaps. A display of exactly
/// [design] is passed through untouched.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.child});
  static const design = Size(792, 360);
  final Widget child;

  /// How much [design] is scaled to fit [screen].
  static double scaleFor(Size screen) =>
      math.min(screen.width / design.width, screen.height / design.height);

  /// Where the picture sits on [screen]; the rest is bars.
  static Rect shownIn(Size screen) => Alignment.center.inscribe(
    design * scaleFor(screen),
    Offset.zero & screen,
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    if (screen.isEmpty ||
        (screen.width - design.width).abs() < .01 &&
            (screen.height - design.height).abs() < .01) {
      return child;
    }
    final s = scaleFor(screen);
    final shown = shownIn(screen);
    final barX = shown.left, barY = shown.top;
    // A notch or gesture strip the bars already cover adds no inset inside.
    EdgeInsets inside(EdgeInsets e) => EdgeInsets.fromLTRB(
      math.max(0, e.left - barX) / s,
      math.max(0, e.top - barY) / s,
      math.max(0, e.right - barX) / s,
      math.max(0, e.bottom - barY) / s,
    );
    return _BarTaps(
      child: ColoredBox(
        color: SkyColors.night,
        child: Center(
          child: SizedBox.fromSize(
            size: shown.size,
            child: FittedBox(
              child: SizedBox.fromSize(
                size: design,
                child: ClipRect(
                  child: MediaQuery(
                    data: media.copyWith(
                      size: design,
                      devicePixelRatio: media.devicePixelRatio * s,
                      padding: inside(media.padding),
                      viewPadding: inside(media.viewPadding),
                      viewInsets: inside(media.viewInsets),
                      systemGestureInsets: inside(media.systemGestureInsets),
                      displayFeatures: [
                        for (final f in media.displayFeatures)
                          DisplayFeature(
                            bounds: Rect.fromLTRB(
                              (f.bounds.left - barX) / s,
                              (f.bounds.top - barY) / s,
                              (f.bounds.right - barX) / s,
                              (f.bounds.bottom - barY) / s,
                            ),
                            type: f.type,
                            state: f.state,
                          ),
                      ],
                    ),
                    child: child,
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

class _BarTaps extends SingleChildRenderObjectWidget {
  const _BarTaps({required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBarTaps();
}

class _RenderBarTaps extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final shown = ScreenFrame.shownIn(size);
    return super.hitTest(
      result,
      position: Offset(
        position.dx.clamp(shown.left + .01, shown.right - .01),
        position.dy.clamp(shown.top + .01, shown.bottom - .01),
      ),
    );
  }
}
