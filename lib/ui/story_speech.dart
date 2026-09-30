import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'campaign_keepsake_art.dart'
    show CampaignAirmailPainter, CampaignPaperPainter;
import 'delivery_art.dart' show DeliveryArt;
import 'match_hud.dart' show MatchPlate;
import 'theme.dart';
import 'ui_sounds.dart';

/// How a line is set in the speech panel.
enum StoryVoice {
  /// Somebody says it: the cream panel.
  spoken,

  /// Where the scene is: a dark title plate.
  place,

  /// The words of a letter read aloud: a sheet of airmail paper.
  letter;

  /// A caption in curly quotes is a letter; any other sets the place.
  static StoryVoice of(String? name, String text) => name != null
      ? spoken
      : text.startsWith('“')
      ? letter
      : place;
}

/// The speech panel: the line as far as it has been written out, how far
/// through the scene it is, and the cue to move on once the line is whole.
///
/// The line is one text (key `story-line`) that always holds every word,
/// with the part not yet written left clear, so the words never jump
/// between rows as they arrive. It is set in the largest size that keeps it
/// to two rows, so the panel never changes height and never cuts a line
/// short. The cue (key `story-cue`) shows once the line is whole.
class StorySpeech extends StatelessWidget {
  const StorySpeech({
    super.key,
    required this.text,
    required this.voice,
    required this.label,
    required this.write,
    required this.step,
    required this.of,
    this.bob,
  });
  final String text;
  final StoryVoice voice;

  /// What a screen reader says for the line.
  final String label;

  /// Writes the line out, 0 to 1.
  final Animation<double> write;

  /// The line's place in the scene, from 1.
  final int step, of;

  /// Seconds that bob the cue; null holds it still.
  final Animation<double>? bob;

  /// The panel's height on a 360-high stage.
  static const height = 92.0;

  /// The sizes a line is tried in, largest first.
  static const sizes = [18.0, 17.0, 16.0, 15.0];
  static const _rows = 2;
  static const _padding = EdgeInsets.fromLTRB(24, 19, 24, 27);

  /// Blue ballpoint, as on the postcards.
  static const _pen = Color(0xff2e5f93);

  /// The style a line is written in at [size].
  static TextStyle style(StoryVoice voice, double size) => switch (voice) {
    StoryVoice.spoken => bodyText(size, weight: FontWeight.w800),
    StoryVoice.place => bodyText(
      size,
      color: SkyColors.cream,
      weight: FontWeight.w800,
    ).copyWith(fontStyle: FontStyle.italic, letterSpacing: .2),
    StoryVoice.letter => bodyText(
      size,
      color: _pen,
      weight: FontWeight.w800,
    ).copyWith(fontStyle: FontStyle.italic),
  };

  /// A letter's sheet is narrower than the panel by this much each side.
  static const _sheetInset = 26.0;

  static EdgeInsets _paddingOf(StoryVoice voice) => voice == StoryVoice.letter
      ? _padding + const EdgeInsets.symmetric(horizontal: _sheetInset)
      : _padding;

  /// The width a line in [voice] has to itself in a panel [width] wide.
  static double room(StoryVoice voice, double width) =>
      width - _paddingOf(voice).horizontal;

  /// The largest of [sizes] at which [text] keeps to two rows across
  /// [width], or null if even the smallest runs over.
  static double? fit(String text, StoryVoice voice, double width) {
    for (final size in sizes) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style(voice, size)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      final rows = painter.computeLineMetrics().length;
      painter.dispose();
      if (rows <= _rows) return size;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: label,
    excludeSemantics: true,
    child: MediaQuery.withNoTextScaling(
      child: SizedBox(
        key: const ValueKey('story-speech'),
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _surface()),
            Positioned.fill(
              child: Padding(
                padding: _paddingOf(voice),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = fit(text, voice, box.maxWidth) ?? sizes.last;
                    final look = style(voice, size);
                    return Align(
                      alignment: voice == StoryVoice.spoken
                          ? Alignment.topLeft
                          : Alignment.center,
                      // A line that wraps splits evenly, so no word is left
                      // alone on its second row.
                      child: SizedBox(
                        width: DeliveryArt.balancedWidth(
                          context,
                          text,
                          look,
                          box.maxWidth,
                        ),
                        child: AnimatedBuilder(
                          animation: write,
                          builder: (context, _) {
                            final written = (text.length * write.value).round();
                            return Text.rich(
                              key: const ValueKey('story-line'),
                              TextSpan(
                                children: [
                                  TextSpan(text: text.substring(0, written)),
                                  TextSpan(
                                    text: text.substring(written),
                                    style: const TextStyle(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                              style: look,
                              textAlign: voice == StoryVoice.spoken
                                  ? TextAlign.start
                                  : TextAlign.center,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: _paddingOf(voice).left,
              bottom: voice == StoryVoice.letter ? 13 : 11,
              child: CustomPaint(
                size: Size(of * _PipsPainter.pitch, 8),
                painter: _PipsPainter(
                  step: step,
                  of: of,
                  light: voice == StoryVoice.place,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 5,
              child: AnimatedBuilder(
                animation: write,
                builder: (context, _) => write.value < 1
                    ? const SizedBox.square(dimension: _Cue.size)
                    : _Cue(
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

  Widget _surface() => switch (voice) {
    StoryVoice.spoken => const CustomPaint(painter: _PanelPainter()),
    StoryVoice.place => const CustomPaint(painter: _PlatePainter()),
    StoryVoice.letter => const Padding(
      padding: EdgeInsets.symmetric(horizontal: _sheetInset),
      child: _LetterSheet(),
    ),
  };
}

/// The cream panel a voice speaks in: an ink outline, a hard drop shadow
/// and a lit top rim, with a slip of airmail stripes along its foot.
class _PanelPainter extends CustomPainter {
  const _PanelPainter();

  static final _blue = Color.lerp(SkyColors.skyDeep, SkyColors.ink, .16)!;

  @override
  void paint(Canvas canvas, Size size) {
    final face = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(
      face.inflate(3).shift(const Offset(0, 6)),
      Paint()..color = SkyColors.ink.withValues(alpha: .34),
    );
    canvas.drawRRect(face.inflate(3), Paint()..color = SkyColors.ink);
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xfffffdf6), SkyColors.cream, Color(0xfffbf0d9)],
          stops: [0, .5, 1],
        ).createShader(face.outerRect),
    );
    // Airmail stripes along the foot, like the edge of an envelope.
    canvas.save();
    canvas.clipRRect(face);
    const band = 6.0, period = 22.0, stripe = 7.5;
    final top = size.height - band;
    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width, band),
      Paint()..color = const Color(0xfffffdf6),
    );
    void slant(double x, Color color) => canvas.drawPath(
      Path()
        ..moveTo(x, top)
        ..lineTo(x + stripe, top)
        ..lineTo(x + stripe + band, size.height)
        ..lineTo(x + band, size.height)
        ..close(),
      Paint()..color = color,
    );
    for (var x = -band; x < size.width; x += period) {
      slant(x, SkyColors.coral);
      slant(x + period / 2, _blue);
    }
    canvas.drawLine(
      Offset(0, top),
      Offset(size.width, top),
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .2)
        ..strokeWidth = 1,
    );
    canvas.restore();
    canvas.drawRRect(
      face.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SkyColors.white, SkyColors.white.withValues(alpha: 0)],
          stops: const [0, .4],
        ).createShader(face.outerRect),
    );
  }

  @override
  bool shouldRepaint(_PanelPainter old) => false;
}

/// The dark plate that names the place, like a title over the scene.
class _PlatePainter extends CustomPainter {
  const _PlatePainter();

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
      Paint()..color = const Color(0xff12262e),
    );
    canvas.drawRRect(plate, Paint()..color = SkyColors.ink);
    canvas.drawRRect(
      plate.deflate(5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = SkyColors.cream.withValues(alpha: .28),
    );
    // A small star at each end of the rule, as on a postmark.
    for (final x in [26.0, size.width - 26]) {
      final at = Offset(x, size.height / 2 + 4 - 9);
      final star = Path();
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 - math.pi / 2;
        final r = i.isEven ? 5.5 : 2.0;
        final p = at + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        star..close(),
        Paint()..color = SkyColors.yellow.withValues(alpha: .9),
      );
    }
  }

  @override
  bool shouldRepaint(_PlatePainter old) => false;
}

/// A sheet of airmail paper held up to be read: the postcards' card stock
/// and striped border, a little askew, sealed with wax.
class _LetterSheet extends StatelessWidget {
  const _LetterSheet();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.008,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffffaef),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SkyColors.ink,
          width: 3,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: SkyColors.ink.withValues(alpha: .34),
            offset: const Offset(0, 6),
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: CampaignPaperPainter(seed: 5, radius: 14)),
          CustomPaint(painter: CampaignAirmailPainter(band: 5.5, radius: 14)),
          Positioned(
            left: 18,
            top: -13,
            width: 26,
            height: 26,
            child: CustomPaint(painter: _WaxSealPainter()),
          ),
        ],
      ),
    ),
  );
}

/// A coral wax seal pressed with a star.
class _WaxSealPainter extends CustomPainter {
  const _WaxSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), r = size.width / 2;
    final blob = Path();
    for (var i = 0; i <= 40; i++) {
      final a = i * math.pi / 20;
      final reach = r * (1 + .07 * math.sin(a * 5 + 1));
      final p = center + Offset(math.cos(a), math.sin(a)) * reach;
      i == 0 ? blob.moveTo(p.dx, p.dy) : blob.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(blob, Paint()..color = SkyColors.coralDeep);
    canvas.drawPath(
      blob,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = SkyColors.ink,
    );
    canvas.drawCircle(center, r * .66, Paint()..color = SkyColors.coral);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5 - math.pi / 2;
      final p =
          center + Offset(math.cos(a), math.sin(a)) * r * (i.isEven ? .46 : .2);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = SkyColors.cream);
  }

  @override
  bool shouldRepaint(_WaxSealPainter old) => false;
}

/// One pip for each line of the scene: those said, the one being said,
/// and those to come.
class _PipsPainter extends CustomPainter {
  const _PipsPainter({
    required this.step,
    required this.of,
    required this.light,
  });
  final int step, of;

  /// On the dark plate the pips are cream.
  final bool light;

  static const pitch = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final tone = light ? SkyColors.cream : SkyColors.ink;
    for (var i = 1; i <= of; i++) {
      final at = Offset((i - .5) * pitch, size.height / 2);
      if (i == step) {
        canvas.drawCircle(at, 4, Paint()..color = tone);
        canvas.drawCircle(at, 2.4, Paint()..color = SkyColors.coral);
      } else {
        canvas.drawCircle(
          at,
          2.4,
          Paint()..color = tone.withValues(alpha: i < step ? .6 : .2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PipsPainter old) =>
      old.step != step || old.of != of || old.light != light;
}

/// The cue to tap: a coral coin with a chevron, or a tick on the last
/// line, that bobs gently while it waits.
class _Cue extends StatelessWidget {
  const _Cue({super.key, required this.last, required this.bob});
  final bool last;
  final Animation<double>? bob;

  static const size = 24.0;

  @override
  Widget build(BuildContext context) {
    final coin = CustomPaint(
      size: const Size.square(size),
      painter: _CuePainter(last),
    );
    final bob = this.bob;
    if (bob == null) return coin;
    // Its own layer: the bob repaints the coin and nothing else.
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

/// The speaker's name on a sticker plate in the speaker's own colour. It
/// sits on the panel's top edge under whoever is talking, who stands on it.
class StoryNameTag extends StatelessWidget {
  const StoryNameTag(this.name, {super.key, required this.color});
  final String name;
  final Color color;

  /// The plate's height, without its lip.
  static const height = 24.0;

  /// How wide the plate is for [name].
  static double widthOf(String name) {
    final painter = TextPainter(
      text: TextSpan(text: name, style: _style(SkyColors.ink)),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width + 26;
    painter.dispose();
    return width;
  }

  static TextStyle _style(Color color) =>
      heading(16, color: color, weight: FontWeight.w700).copyWith(height: 1);

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() < .42;
    return MediaQuery.withNoTextScaling(
      child: MatchPlate(
        color: color,
        radius: 11,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: height,
          width: widthOf(name),
          child: Center(
            child: Text(
              name,
              key: const ValueKey('story-speaker'),
              maxLines: 1,
              softWrap: false,
              style: _style(dark ? SkyColors.cream : SkyColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Skip key, in the map's sticker material: a cream pill on a lip with
/// a fast-forward mark. Pressing sinks it; with Reduced Motion it stays put
/// and a held press shades the face instead.
class StorySkipKey extends StatefulWidget {
  const StorySkipKey({
    super.key,
    required this.onPressed,
    this.reducedMotion = false,
  });
  final VoidCallback onPressed;
  final bool reducedMotion;

  /// The key's height: a full touch target.
  static const height = 48.0;

  @override
  State<StorySkipKey> createState() => _StorySkipKeyState();
}

class _StorySkipKeyState extends State<StorySkipKey> {
  bool pressed = false, focused = false;

  void _press() {
    UiSounds.effect(context, 'ui_back');
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final still =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final ring =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    const pill = BorderRadius.all(Radius.circular(StorySkipKey.height / 2));
    return Semantics(
      button: true,
      label: 'Skip',
      onTap: _press,
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: pill,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: _press,
            onFocusChange: (value) => setState(() => focused = value),
            onHighlightChanged: (value) => setState(() => pressed = value),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: pill,
                boxShadow: [
                  if (ring)
                    const BoxShadow(color: SkyColors.gold, spreadRadius: 7),
                ],
              ),
              child: Transform.translate(
                offset: Offset(0, pressed && !still ? 3 : 0),
                child: MatchPlate(
                  padding: EdgeInsets.zero,
                  child: Container(
                    height: StorySkipKey.height,
                    padding: const EdgeInsets.fromLTRB(18, 0, 15, 0),
                    decoration: BoxDecoration(
                      borderRadius: pill,
                      color: pressed && still
                          ? SkyColors.ink.withValues(alpha: .1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Skip',
                          style: heading(
                            19,
                            weight: FontWeight.w700,
                          ).copyWith(height: 1),
                        ),
                        const SizedBox(width: 7),
                        const CustomPaint(
                          size: Size(22, 18),
                          painter: _SkipGlyphPainter(),
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
    );
  }
}

/// Two chunky chevrons: fast forward, in the map keys' stroke.
class _SkipGlyphPainter extends CustomPainter {
  const _SkipGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final path = Path();
    for (final x in [3.0, 12.0]) {
      path
        ..moveTo(x, 2.5)
        ..lineTo(x + 6.5, h / 2)
        ..lineTo(x, h - 2.5);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SkipGlyphPainter old) => false;
}
