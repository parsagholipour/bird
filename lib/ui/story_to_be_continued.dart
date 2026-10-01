import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/campaign_story.dart';
import '../game/star_art.dart';
import 'delivery_art.dart' show DeliveryArt;
import 'campaign_text_scale.dart';
import 'story_speech.dart' show StorySpeech, StoryVoice;
import 'theme.dart';

/// The end card of a chapter that is not finished yet: the caption that
/// closes the Searchlight Gargoyle's last scene, "To be continued… Next stop:
/// Paris, the City of Light."
///
/// It takes the speech panel's place for that one caption, in the same
/// frame: the panel's size, its `story-speech`, `story-line` and `story-cue`
/// keys, its pips and its way of writing the line out, so a scene that ends
/// on it plays like any other. The plate is Paris at night instead of the
/// place plate's ink: a gold rule round the edge, the tower on a medallion
/// with a searchlight behind it, and the words "To be continued…" lit in
/// gold. With [bob] null (Reduced Motion) nothing twinkles.
///
/// Paris deletes the caption from the scene when it opens, and with it the
/// card.
class ToBeContinued extends StatelessWidget {
  const ToBeContinued({
    super.key,
    required this.text,
    required this.write,
    required this.step,
    required this.of,
    this.bob,
  });

  /// The caption, whole: "To be continued…" and then where the trip goes.
  final String text;

  /// Writes the line out, 0 to 1.
  final Animation<double> write;

  /// The line's place in the scene, from 1.
  final int step, of;

  /// Seconds that twinkle the lights and bob the cue; null holds them still.
  final Animation<double>? bob;

  /// Whether [line] is this card's: a caption that begins "To be continued".
  static bool matches(StoryLine line) =>
      line.speaker == StorySpeaker.caption &&
      RegExp(r'^\s*to be continued', caseSensitive: false).hasMatch(line.text);

  /// Where the words "To be continued…" end in [text]: after their ellipsis
  /// (or full stop), else after the third word.
  static int headEnd(String text) {
    final ellipsis = RegExp(r'^[^.…]*(…|\.{2,}|\.)').firstMatch(text);
    if (ellipsis != null) return ellipsis.end;
    final words = RegExp(r'\S+').allMatches(text).toList();
    return words.length < 3 ? text.length : words[2].end;
  }

  /// The medallion's size and the room it takes from the words.
  static const medallion = 54.0, _lead = 86.0;
  static const _padding = EdgeInsets.fromLTRB(_lead, 19, 24, 27);

  @override
  Widget build(BuildContext context) {
    // The card sets its own sizes (a scaled text size is one more candidate in
    // the fit, below), so the text inside is not scaled again.
    final scale = CampaignTextScale.of(context);
    return _card(scale);
  }

  Widget _card(double scale) => Semantics(
    container: true,
    liveRegion: true,
    label: text,
    excludeSemantics: true,
    child: MediaQuery.withNoTextScaling(
      child: SizedBox(
        key: const ValueKey('story-speech'),
        height: StorySpeech.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: CustomPaint(
                key: ValueKey('story-to-be-continued'),
                painter: _NightPlatePainter(),
              ),
            ),
            Positioned(
              left: 18,
              top: 8 + (StorySpeech.height - 8 - medallion) / 2 - 3,
              width: medallion,
              height: medallion,
              child: RepaintBoundary(
                child: bob == null
                    ? const CustomPaint(painter: _ParisPainter(0))
                    : AnimatedBuilder(
                        animation: bob!,
                        builder: (context, _) =>
                            CustomPaint(painter: _ParisPainter(bob!.value)),
                      ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: _padding,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = _fit(text, box.maxWidth, scale);
                    final look = StorySpeech.style(StoryVoice.place, size);
                    return Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: DeliveryArt.balancedWidth(
                          context,
                          text,
                          look,
                          box.maxWidth,
                        ),
                        child: AnimatedBuilder(
                          animation: write,
                          builder: (context, _) => Text.rich(
                            key: const ValueKey('story-line'),
                            _spans(
                              text,
                              look,
                              (text.length * write.value).round(),
                            ),
                            style: look,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: _padding.left,
              bottom: 11,
              child: CustomPaint(
                size: Size(of * _pitch, 8),
                painter: _PipsPainter(step: step, of: of),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 5,
              child: AnimatedBuilder(
                animation: write,
                builder: (context, _) => write.value < 1
                    ? const SizedBox.square(dimension: _cue)
                    : _CueCoin(
                        key: const ValueKey('story-cue'),
                        last: step >= of,
                        bob: bob,
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  static const _pitch = 11.0, _cue = 24.0;

  /// "To be continued…" is set this much bigger than the panel's size, and
  /// where the trip goes a little smaller.
  static const _headScale = 1.3, _tailScale = .92;

  /// The panel's size for [text] in [width]: the largest of the speech
  /// panel's sizes at which the line, with its lit head and its small tail,
  /// keeps to two rows.
  static double _fit(String text, double width, [double scale = 1]) {
    double heightAt(double size) {
      final painter = TextPainter(
        text: _spans(
          text,
          StorySpeech.style(StoryVoice.place, size),
          text.length,
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      final rows = painter.computeLineMetrics().length;
      final height = painter.height;
      painter.dispose();
      return rows <= 2 ? height : double.infinity;
    }

    // A larger system text size tries the panel's sizes scaled up first, and
    // keeps one that sets in two rows within the plate's height; none that
    // does leaves the panel's own sizes (it is a plate of one fixed height).
    if (scale > 1) {
      for (final size in StorySpeech.sizes) {
        if (heightAt(size * scale) <= _roomHeight) return size * scale;
      }
    }
    for (final size in StorySpeech.sizes) {
      if (heightAt(size) < double.infinity) return size;
    }
    return StorySpeech.sizes.last;
  }

  /// The tallest the words may be at a larger text size: the plate's inside
  /// and a little of its padding.
  static const _roomHeight = 52.0;

  /// The line as written so far, the part not yet written left clear so the
  /// words never move. "To be continued…" is lit in gold and set big; the
  /// rest is the panel's own italic, a little smaller.
  static TextSpan _spans(String text, TextStyle look, int written) {
    final head = headEnd(text);
    final size = look.fontSize!;
    final gold = look.copyWith(
      color: SkyColors.yellow,
      fontSize: size * _headScale,
      fontWeight: FontWeight.w900,
      letterSpacing: .6,
    );
    final tail = look.copyWith(fontSize: size * _tailScale);
    const clear = TextStyle(color: Colors.transparent);
    final headShown = math.min(written, head);
    final tailShown = math.max(0, written - head);
    return TextSpan(
      style: look,
      children: [
        TextSpan(text: text.substring(0, headShown), style: gold),
        TextSpan(
          text: text.substring(headShown, head),
          style: gold.merge(clear),
        ),
        TextSpan(text: text.substring(head, head + tailShown), style: tail),
        TextSpan(
          text: text.substring(head + tailShown),
          style: tail.merge(clear),
        ),
      ],
    );
  }
}

/// Paris at night: the place plate's shape in deep blue with a gold rule
/// inside its edge and a small gold star at the far end.
class _NightPlatePainter extends CustomPainter {
  const _NightPlatePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8, size.width, size.height - 8),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      plate.inflate(3).shift(const Offset(0, 5)),
      Paint()..color = SkyColors.ink.withValues(alpha: .3),
    );
    canvas.drawRRect(
      plate.inflate(3),
      Paint()..color = const Color(0xff101c33),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff2b4274), Color(0xff1b2b52), Color(0xff14203d)],
          stops: [0, .55, 1],
        ).createShader(plate.outerRect),
    );
    canvas.drawRRect(
      plate.deflate(5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = SkyColors.yellow.withValues(alpha: .5),
    );
    final at = Offset(size.width - 26, plate.top + 13);
    StarArt.sparkle(canvas, at, 6, SkyColors.yellow.withValues(alpha: .9));
  }

  @override
  bool shouldRepaint(_NightPlatePainter old) => false;
}

/// The Eiffel Tower on a night-blue medallion with a gold rim, two beams of
/// searchlight sweeping up behind it and a few twinkling lights ([seconds]
/// twinkles them; 0 holds them lit).
class _ParisPainter extends CustomPainter {
  const _ParisPainter(this.seconds);
  final double seconds;

  static const _gold = SkyColors.yellow;

  /// The tower in a 40 × 46 box: spire, two platforms and four splayed legs
  /// with an arch between.
  static Path _tower() {
    final top = Path()
      ..moveTo(20, 0)
      ..lineTo(21.5, 9)
      ..lineTo(23.2, 21)
      ..lineTo(16.8, 21)
      ..lineTo(18.5, 9)
      ..close();
    final upper = Path()
      ..moveTo(15.4, 21)
      ..lineTo(24.6, 21)
      ..lineTo(24.6, 23.4)
      ..lineTo(15.4, 23.4)
      ..close();
    final mid = Path()
      ..moveTo(16.2, 23.4)
      ..lineTo(23.8, 23.4)
      ..lineTo(28, 35)
      ..lineTo(12, 35)
      ..close();
    final deck = Path()
      ..moveTo(10.4, 35)
      ..lineTo(29.6, 35)
      ..lineTo(29.6, 37.6)
      ..lineTo(10.4, 37.6)
      ..close();
    final legs = Path()
      ..moveTo(12, 37.6)
      ..lineTo(28, 37.6)
      ..cubicTo(28, 41, 33, 43, 35, 46)
      ..lineTo(29, 46)
      ..quadraticBezierTo(20, 33.5, 11, 46)
      ..lineTo(5, 46)
      ..cubicTo(7, 43, 12, 41, 12, 37.6)
      ..close();
    return Path()
      ..addPath(top, Offset.zero)
      ..addPath(upper, Offset.zero)
      ..addPath(mid, Offset.zero)
      ..addPath(deck, Offset.zero)
      ..addPath(legs, Offset.zero);
  }

  static final _path = _tower();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.width / 2 - 2;
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c.translate(0, 2.5),
      r + 1.5,
      Paint()..color = SkyColors.ink.withValues(alpha: .4),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, .4),
          radius: 1,
          colors: [Color(0xff4a6aa8), Color(0xff263a6c), Color(0xff172647)],
          stops: [0, .6, 1],
        ).createShader(disc),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(disc));
    // Two searchlight beams crossing behind the tower.
    final sway = math.sin(seconds * 1.4) * .08;
    for (final (side, tilt) in [(-1.0, .36), (1.0, .34)]) {
      final from = Offset(c.dx + side * r * .42, c.dy + r);
      final reach = r * 2.2;
      final a = -math.pi / 2 + side * (tilt + sway * -side);
      canvas.drawPath(
        Path()
          ..moveTo(from.dx - side * 2, from.dy)
          ..lineTo(
            from.dx + math.cos(a - .13) * reach,
            from.dy + math.sin(a - .13) * reach,
          )
          ..lineTo(
            from.dx + math.cos(a + .13) * reach,
            from.dy + math.sin(a + .13) * reach,
          )
          ..lineTo(from.dx + side * 2, from.dy)
          ..close(),
        Paint()..color = SkyColors.cream.withValues(alpha: .2),
      );
    }
    // The tower, gold with an ink edge.
    final k = r * 1.72 / 46;
    canvas.save();
    canvas.translate(c.dx - 20 * k, c.dy - r * .9);
    canvas.scale(k);
    canvas.drawPath(_path, Paint()..color = _gold);
    canvas.drawPath(
      _path,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / k
        ..strokeJoin = StrokeJoin.round,
    );
    // A glint down the tower's lit side.
    canvas.drawLine(
      const Offset(20, 3),
      const Offset(19.6, 20),
      Paint()
        ..color = SkyColors.white.withValues(alpha: .7)
        ..strokeWidth = 1.2 / k
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    // The lights of the city.
    for (final (i, (dx, dy, s)) in const [
      (-.62, -.52, 2.6),
      (.6, -.3, 2.2),
      (.4, -.72, 1.8),
    ].indexed) {
      final twinkle = seconds == 0
          ? 1.0
          : .55 + .45 * math.sin(seconds * 2.6 + i * 2.1);
      StarArt.sparkle(
        canvas,
        c + Offset(dx * r, dy * r),
        s * (.7 + .3 * twinkle),
        SkyColors.cream.withValues(alpha: .55 + .45 * twinkle),
      );
    }
    canvas.restore();
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = SkyColors.ink,
    );
    canvas.drawCircle(
      c,
      r - 2.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = _gold,
    );
  }

  @override
  bool shouldRepaint(_ParisPainter old) => old.seconds != seconds;
}

/// One pip for each line of the scene, cream on the plate: those said, the
/// one being said and those to come, as on the place plate.
class _PipsPainter extends CustomPainter {
  const _PipsPainter({required this.step, required this.of});
  final int step, of;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 1; i <= of; i++) {
      final at = Offset((i - .5) * ToBeContinued._pitch, size.height / 2);
      if (i == step) {
        canvas.drawCircle(at, 4, Paint()..color = SkyColors.cream);
        canvas.drawCircle(at, 2.4, Paint()..color = SkyColors.coral);
      } else {
        canvas.drawCircle(
          at,
          2.4,
          Paint()
            ..color = SkyColors.cream.withValues(alpha: i < step ? .6 : .2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PipsPainter old) => old.step != step || old.of != of;
}

/// The cue to tap, as the speech panel's: a coral coin with a tick on the
/// last line, bobbing while it waits.
class _CueCoin extends StatelessWidget {
  const _CueCoin({super.key, required this.last, required this.bob});
  final bool last;
  final Animation<double>? bob;

  @override
  Widget build(BuildContext context) {
    final coin = CustomPaint(
      size: const Size.square(ToBeContinued._cue),
      painter: _CuePainter(last),
    );
    final bob = this.bob;
    if (bob == null) return coin;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: bob,
        child: coin,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, math.sin(bob.value * 4).abs() * -3.5),
          child: child,
        ),
      ),
    );
  }
}

class _CuePainter extends CustomPainter {
  const _CuePainter(this.last);
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), r = size.width / 2 - 2;
    canvas.drawCircle(
      center + const Offset(0, 2.5),
      r + 2,
      Paint()..color = SkyColors.ink,
    );
    canvas.drawCircle(center, r + 2, Paint()..color = SkyColors.ink);
    canvas.drawCircle(center, r, Paint()..color = SkyColors.coral);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - 1.5),
      math.pi * 1.1,
      math.pi * .5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = SkyColors.white.withValues(alpha: .75),
    );
    final glyph = Path();
    if (last) {
      glyph
        ..moveTo(center.dx - 4.6, center.dy + .4)
        ..lineTo(center.dx - 1.2, center.dy + 3.6)
        ..lineTo(center.dx + 4.8, center.dy - 3.2);
    } else {
      glyph
        ..moveTo(center.dx - 4.4, center.dy - 1.6)
        ..lineTo(center.dx, center.dy + 3)
        ..lineTo(center.dx + 4.4, center.dy - 1.6);
    }
    canvas.drawPath(
      glyph,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = SkyColors.cream,
    );
  }

  @override
  bool shouldRepaint(_CuePainter old) => old.last != last;
}
