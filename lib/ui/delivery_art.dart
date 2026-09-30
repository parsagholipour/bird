import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/campaign.dart' show Delivery;
import '../domain/sky_boss.dart' show BossKind;
import 'campaign_keepsake_art.dart';
import 'theme.dart';

/// The postal pieces a level's delivery is shown with: the parcel tag tied to
/// its card and the thank-you note on its result. Both are written by hand,
/// like the chapter postcards.
abstract final class DeliveryArt {
  /// Blue ballpoint, the pen of the postcards.
  static const pen = Color(0xff2e5f93);

  /// Tag and note stock, a shade warmer than the cards they lie on.
  static const paper = Color(0xfffffcf2);

  /// The ink a boss writes in: its stamp colour, darkened to read on paper.
  static Color bossInk(BossKind boss) =>
      Color.lerp(CampaignHeadwear.field(boss), SkyColors.ink, .38)!;

  /// Handwriting at [size].
  static TextStyle hand(double size, {Color color = pen}) =>
      heading(size, color: color, weight: FontWeight.w500);

  /// The narrowest width that keeps [text] on as many lines as it takes in
  /// [max], so a line that wraps splits evenly instead of leaving one word
  /// alone on the last line. It is never narrower than the longest word, so
  /// no word is broken to even the lines out.
  static double balancedWidth(
    BuildContext context,
    String text,
    TextStyle style,
    double max,
  ) {
    // Measured in the style the Text will really wear, with the theme's
    // defaults folded in.
    final worn = DefaultTextStyle.of(context).style.merge(style);
    var word = 0.0;
    int lines(double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: worn),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);
      final count = painter.computeLineMetrics().length;
      word = painter.minIntrinsicWidth;
      painter.dispose();
      return count;
    }

    final wanted = lines(max);
    if (wanted < 2) return max;
    var low = math.min(max, math.max(max / 2, word)), high = max;
    for (var i = 0; i < 8; i++) {
      final mid = (low + high) / 2;
      if (lines(mid) > wanted) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return math.min(max, high + 1);
  }
}

/// A few words written by hand: Fredoka leaned over, its lines split evenly
/// unless [balance] is off, when each line takes all it can. The text widget
/// carries [textKey].
class DeliveryScript extends StatelessWidget {
  const DeliveryScript(
    this.text, {
    super.key,
    required this.style,
    required this.maxLines,
    this.textKey,
    this.align = TextAlign.left,
    this.balance = true,
  });
  final String text;
  final TextStyle style;
  final int maxLines;
  final Key? textKey;
  final TextAlign align;
  final bool balance;

  /// How far the pen leans.
  static const lean = -.15;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Align(
      alignment: switch (align) {
        TextAlign.center => Alignment.center,
        TextAlign.right || TextAlign.end => Alignment.centerRight,
        _ => Alignment.centerLeft,
      },
      child: SizedBox(
        width: balance
            ? DeliveryArt.balancedWidth(context, text, style, box.maxWidth)
            : box.maxWidth,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.skewX(lean),
          child: Text(
            text,
            key: textKey,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: style,
          ),
        ),
      ),
    ),
  );
}

/// A parcel tag: stock with its string end cut to a point, an eyelet punched
/// through it, inked like the card it is tied to.
class DeliveryTagPainter extends CustomPainter {
  const DeliveryTagPainter({this.eyelet = SkyColors.coral});

  /// The colour of the eyelet's reinforcing ring.
  final Color eyelet;

  /// How much of each corner the cut takes at the string end, and how far in
  /// the eyelet sits.
  static const cut = 12.0, inset = 14.0;

  /// The middle of the eyelet on a tag of [size].
  static Offset hole(Size size) => Offset(inset, size.height / 2);

  static Path _shape(Size size) {
    final w = size.width, h = size.height;
    const r = Radius.circular(7);
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(w - r.x, 0)
      ..arcToPoint(Offset(w, r.y), radius: r)
      ..lineTo(w, h - r.y)
      ..arcToPoint(Offset(w - r.x, h), radius: r)
      ..lineTo(cut, h)
      ..lineTo(0, h - cut)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);
    canvas.drawPath(
      shape.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink.withValues(alpha: .3),
    );
    canvas.drawPath(shape, Paint()..color = DeliveryArt.paper);
    // Handling tones the stock toward its edges.
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = const Color(0xffc99e5c).withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();
    canvas.drawPath(
      shape,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    final at = hole(size);
    canvas.drawCircle(at, 6.4, Paint()..color = eyelet);
    canvas.drawCircle(
      at,
      6.4,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(at, 2.6, Paint()..color = SkyColors.ink);
  }

  @override
  bool shouldRepaint(DeliveryTagPainter old) => old.eyelet != eyelet;
}

/// The string a tag hangs by: a doubled cord of twine from its eyelet at
/// [from], knotted there, up to [to], where it passes over the edge of what
/// the tag is tied to and out of sight.
class DeliveryTwinePainter extends CustomPainter {
  const DeliveryTwinePainter({required this.from, required this.to});
  final Offset from, to;

  static const _twine = Color(0xffecd3a8);

  @override
  void paint(Canvas canvas, Size size) {
    // The cord runs on past the edge and is cut off flush with it.
    final run = to - from;
    final past = to + run / run.distance * 6;
    final side = Offset(-run.dy, run.dx) / run.distance;
    // A little slack: it bows one way, then the other.
    Path strand(double shift) => Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        from.dx + run.dx * .3 + side.dx * (5 + shift),
        from.dy + run.dy * .3 + side.dy * (5 + shift),
        from.dx + run.dx * .7 - side.dx * (3 - shift),
        from.dy + run.dy * .7 - side.dy * (3 - shift),
        past.dx + side.dx * shift,
        past.dy + side.dy * shift,
      );
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        math.min(from.dx, to.dx) - 20,
        to.dy,
        math.max(from.dx, to.dx) + 20,
        from.dy + 20,
      ),
    );
    final strands = [strand(-1.5), strand(1.5)];
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8;
    final cord = Paint()
      ..color = _twine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    for (final path in strands) {
      canvas.drawPath(path, ink);
    }
    for (final path in strands) {
      canvas.drawPath(path, cord);
    }
    canvas.restore();
    canvas.drawCircle(from, 3.6, Paint()..color = SkyColors.ink);
    canvas.drawCircle(from, 2.2, Paint()..color = _twine);
  }

  @override
  bool shouldRepaint(DeliveryTwinePainter old) =>
      old.from != from || old.to != to;
}

/// The seal on a thank-you note: a heart sticker, or a boss's own seal with
/// its headwear pressed into wax of its stamp colour.
class DeliverySealPainter extends CustomPainter {
  const DeliverySealPainter({this.boss});
  final BossKind? boss;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.shortestSide / 2;
    final boss = this.boss;
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .16
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(
      c.translate(0, r * .14),
      r * .92,
      Paint()..color = SkyColors.ink.withValues(alpha: .28),
    );
    final field = boss == null ? SkyColors.coral : CampaignHeadwear.field(boss);
    canvas.drawCircle(c, r * .92, Paint()..color = field);
    // A lighter ring just inside the rim, like pressed wax.
    canvas.drawCircle(
      c,
      r * .7,
      Paint()
        ..color = SkyColors.cream.withValues(alpha: .32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .08,
    );
    canvas.drawCircle(c, r * .92, ink);
    if (boss != null) {
      CampaignHeadwear.paint(
        canvas,
        Rect.fromCenter(center: c, width: r * 1.2, height: r * 1.0),
        boss,
      );
      return;
    }
    final heart = Path()
      ..moveTo(0, .62)
      ..cubicTo(-.95, .02, -.62, -.72, 0, -.22)
      ..cubicTo(.62, -.72, .95, .02, 0, .62)
      ..close();
    canvas.save();
    canvas.translate(c.dx, c.dy + r * .04);
    canvas.scale(r * .62);
    canvas.drawPath(heart, Paint()..color = SkyColors.cream);
    canvas.restore();
  }

  @override
  bool shouldRepaint(DeliverySealPainter old) => old.boss != boss;
}

/// The thank-you note for a delivery: what they said, in curly quotes and
/// their own hand, and who signs it, on air-mail paper with a heart seal. A
/// boss grumbles its thanks in its own ink, on paper framed in its stamp
/// colour and sealed with its headwear.
class DeliveryNote extends StatelessWidget {
  const DeliveryNote({
    super.key,
    required this.delivery,
    required this.boss,
    required this.seal,
  });
  final Delivery delivery;
  final BossKind? boss;

  /// How far the seal has been pressed on, 0 to 1 and a little past.
  final double seal;

  /// Its width; it is as tall as its words need, up to [maxHeight] for the
  /// longest thanks and a signer of two lines.
  static const width = 150.0, maxHeight = 148.0;
  static const _radius = 12.0, _edge = 2.6, _seal = 30.0;

  @override
  Widget build(BuildContext context) {
    final boss = this.boss;
    final pen = boss == null ? DeliveryArt.pen : DeliveryArt.bossInk(boss);
    return Semantics(
      label: 'Thank-you note from ${delivery.from}: ${delivery.thanks}',
      excludeSemantics: true,
      child: SizedBox(
        key: const ValueKey('level-result-note'),
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: DeliveryArt.paper,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: SkyColors.ink, width: _edge),
                boxShadow: [
                  BoxShadow(
                    color: SkyColors.ink.withValues(alpha: .28),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(_edge),
                child: CustomPaint(
                  painter: CampaignPaperPainter(
                    seed: delivery.from.length + 20,
                    radius: _radius - _edge,
                  ),
                  foregroundPainter: boss == null
                      ? const CampaignAirmailPainter(
                          band: 5,
                          radius: _radius - _edge,
                        )
                      : _BossFramePainter(
                          CampaignHeadwear.field(boss),
                          radius: _radius - _edge,
                        ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 17, 10, 9),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DeliveryScript(
                          '“${delivery.thanks}”',
                          textKey: const ValueKey('level-result-thanks'),
                          maxLines: 4,
                          align: TextAlign.center,
                          style: DeliveryArt.hand(
                            17,
                            color: pen,
                          ).copyWith(height: 1.12),
                        ),
                        const SizedBox(height: 7),
                        // The signature keeps off the paper's edge.
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: DeliveryScript(
                            '— ${delivery.from}',
                            maxLines: 2,
                            align: TextAlign.right,
                            balance: false,
                            style: DeliveryArt.hand(
                              13.5,
                              color: SkyColors.muted,
                            ).copyWith(height: 1.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The seal holds the note by the middle of its top edge.
            Positioned(
              left: (width - _seal) / 2,
              top: -_seal * .46,
              width: _seal,
              height: _seal,
              child: Transform.rotate(
                angle: .12,
                child: Transform.scale(
                  scale: seal,
                  child: CustomPaint(
                    key: const ValueKey('level-result-seal'),
                    painter: DeliverySealPainter(boss: boss),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A boss's writing paper: a band of its stamp colour just inside the edge,
/// ruled off in ink, where a friend's note has its air-mail stripes.
class _BossFramePainter extends CustomPainter {
  const _BossFramePainter(this.color, {required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final inner = outer.deflate(5);
    canvas.drawDRRect(outer, inner, Paint()..color = color);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BossFramePainter old) =>
      old.color != color || old.radius != radius;
}
