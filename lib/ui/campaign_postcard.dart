import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/campaign.dart';
import '../domain/sky_boss.dart' show BossKind;
import '../game/bird_puppet.dart';
import '../game/regions/world_region.dart';
import '../game/star_art.dart';
import 'campaign_keepsake_art.dart';
import 'campaign_map_art.dart' show MapRibbonPainter;
import 'campaign_region_still.dart';
import 'fit_text.dart';
import 'theme.dart';
import '../l10n/l10n.dart';

/// What one chapter's postcard says and shows. The words come from the
/// chapter in the campaign catalog, so the card and docs/campaign.md have
/// one source; the card only adds where its picture looks.
///
/// [route], [postmarkName], [body] and [postscript] are the English words
/// (the twins of the ARB keys `chapter_*`, which test/l10n_campaign_test.dart
/// keeps equal); the card shows the current language's through
/// [CampaignText] (`routeIn`, `bodyIn`, ...).
class CampaignLetter {
  const CampaignLetter(this.chapter, {this.crop = 0});
  final CampaignChapter chapter;

  /// The chapter's route, which signs the card.
  String get route => chapter.route;

  /// The route as a postmark prints it: capitals, without the leading "The".
  String get postmarkName => route.replaceFirst('The ', '').toUpperCase();

  /// The boss's home region, on the picture side: the chapter's last stop.
  WorldRegion get region => chapter.regions.last;

  /// The boss whose lost headwear is on the stamp.
  BossKind get boss => chapter.boss;

  /// The message after "Dear courier," which the card writes as its own
  /// greeting line.
  String get body {
    // Reads the English twin. l10n-ignore
    final text = _typeset(_after(chapter.postcard, 'Dear courier, '));
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  /// The P.S. without its label, which the card sets in its own colour.
  // Reads the English twin. l10n-ignore
  String get postscript => _typeset(_after(chapter.postscript, 'P.S. '));

  /// [route], [postmarkName], [body] and [postscript] in [l]'s language.
  String routeIn(AppLocalizations l) => l.chapterRoute(chapter);
  String postmarkIn(AppLocalizations l) => l.chapterPostmark(chapter);
  String bodyIn(AppLocalizations l) => l.chapterPostcard(chapter);
  String postscriptIn(AppLocalizations l) => l.chapterPostscript(chapter);

  /// How far the picture slides along the region's skyline, as a fraction
  /// of the frame, to keep its landmark beside the bird.
  final double crop;

  static String _after(String text, String prefix) =>
      text.startsWith(prefix) ? text.substring(prefix.length) : text;

  /// The catalog keeps plain apostrophes; the card prints curly ones, like
  /// the rest of the menus.
  static String _typeset(String text) => text.replaceAll("'", '’');
}

/// The postcard that arrives after a chapter's boss is beaten: the picture
/// side (the boss's home region, the equipped bird and a letter) and the
/// message side (a note from the route, a stamp of the boss's lost headwear
/// and a postmark), laid out like two cards on a table.
///
/// It keeps its composition at any size, scaling as one piece. [action]
/// sits over the corner of the message side, for the screen's Continue key.
class CampaignPostcard extends StatelessWidget {
  const CampaignPostcard({
    super.key,
    required this.chapter,
    required this.bird,
    this.action,
  }) : assert(chapter >= 1 && chapter <= 5);

  /// The chapter, 1 to 5.
  final int chapter;

  /// The equipped bird, on the picture side.
  final int bird;
  final Widget? action;

  /// The five letters, in chapter order.
  static final letters = [
    for (final (i, crop) in const [.12, .12, .2, .02, .1].indexed)
      CampaignLetter(Campaign.chapters[i], crop: crop),
  ];

  /// The composed size; the card scales as one piece to fit its box.
  static const size = Size(780, 340);

  CampaignLetter get letter => letters[chapter - 1];

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.l10n.campaignPostcardSemantics(
      letter.routeIn(context.l10n),
      letter.bodyIn(context.l10n),
      letter.postscriptIn(context.l10n),
    ),
    child: AspectRatio(
      aspectRatio: size.width / size.height,
      child: FittedBox(
        child: MediaQuery.withNoTextScaling(
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 6,
                  top: 16,
                  width: 424,
                  height: 292,
                  child: Transform.rotate(
                    angle: -.045,
                    child: ExcludeSemantics(
                      child: RepaintBoundary(
                        child: _PictureSide(letter: letter, bird: bird),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 374,
                  top: 26,
                  width: 400,
                  height: 288,
                  child: Transform.rotate(
                    angle: .025,
                    child: ExcludeSemantics(
                      child: RepaintBoundary(
                        child: _MessageSide(letter: letter, chapter: chapter),
                      ),
                    ),
                  ),
                ),
                if (action != null)
                  Positioned(right: 0, bottom: 0, child: action!),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Card stock: cream, rounded, inked, with a soft drop shadow.
BoxDecoration _card(Color color) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: SkyColors.ink, width: 2.6),
  boxShadow: [
    BoxShadow(
      color: SkyColors.ink.withValues(alpha: .22),
      offset: const Offset(0, 7),
    ),
  ],
);

class _PictureSide extends StatelessWidget {
  const _PictureSide({required this.letter, required this.bird});
  final CampaignLetter letter;
  final int bird;

  @override
  Widget build(BuildContext context) => Container(
    decoration: _card(const Color(0xfffffcf4)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        // The white border of the print, toned and grainy like card stock.
        Positioned.fill(
          child: CustomPaint(
            painter: CampaignPaperPainter(
              seed: letter.chapter.number + 40,
              radius: 11.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(9),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CampaignRegionView(
                  region: letter.region,
                  frameSize: const Size(760, 330),
                  crop: letter.crop,
                ),
                CustomPaint(painter: _FlightPainter(bird)),
                Positioned(
                  left: 14,
                  top: 12,
                  // A long name in another language shrinks to the picture.
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomPaint(
                        painter: const MapRibbonPainter(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 3, 18, 8),
                          child: Text(
                            context.l10n.campaignPostcardGreetingsFrom,
                            style: bodyText(
                              12,
                              color: SkyColors.cream,
                              weight: FontWeight.w900,
                            ).copyWith(height: 1.1, letterSpacing: .4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Transform.rotate(
                        angle: -.04,
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: CampaignLettering(
                            context.l10n.regionName(letter.region),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // The gloss of a printed photograph: one soft diagonal glare.
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-1, -.6),
                        end: const Alignment(1, .6),
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: .24),
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: .14),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [.26, .32, .38, .42, .445, .47],
                      ),
                    ),
                  ),
                ),
                // A soft inner edge, like a print's.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: SkyColors.ink.withValues(alpha: .35),
                      width: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// The courier flying home with a letter in its beak, on a dotted trail
/// of stars.
class _FlightPainter extends CustomPainter {
  const _FlightPainter(this.bird);
  final int bird;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final at = Offset(w * .6, h * .5);
    // The trail the bird has flown, from the lower left.
    final trail = Path()
      ..moveTo(-10, h * .92)
      ..cubicTo(
        w * .18,
        h * .9,
        w * .3,
        h * .56,
        at.dx - w * .12,
        at.dy + h * .1,
      );
    final dot = Paint()..color = SkyColors.cream;
    final edge = Paint()..color = SkyColors.ink.withValues(alpha: .45);
    for (final m in trail.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 15) {
        final p = m.getTangentForOffset(d)!.position;
        final r = 2.2 + 1.6 * d / m.length;
        canvas.drawCircle(p.translate(0, 1), r + .9, edge);
        canvas.drawCircle(p, r, dot);
      }
    }
    for (final (p, r) in [
      (Offset(w * .3, h * .66), 9.0),
      (Offset(w * .87, h * .3), 11.0),
      (Offset(w * .82, h * .66), 7.0),
    ]) {
      StarArt.mini(canvas, p, r, outline: 1.6, rotation: r / 30);
    }
    final bw = h * .46;
    final bounds = Rect.fromCenter(
      center: at,
      width: bw,
      height: bw * 224 / 256,
    );
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(-.1);
    canvas.translate(-at.dx, -at.dy);
    _letter(canvas, bounds.topLeft + Offset(bw * .98, bw * .5), bw * .34);
    BirdPuppet.paint(
      canvas,
      bounds,
      bird: bird,
      wing: -.5,
      expression: BirdExpression.pleased,
    );
    canvas.restore();
  }

  /// An envelope with a heart seal, held by one corner.
  static void _letter(Canvas canvas, Offset at, double w) {
    final h = w * .66;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(.32);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w * .1, -h * .2, w, h),
      Radius.circular(w * .06),
    );
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .045
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(body, Paint()..color = const Color(0xfffffcf4));
    final flap = Path()
      ..moveTo(body.left, body.top)
      ..lineTo(body.left + w / 2, body.top + h * .55)
      ..lineTo(body.right, body.top);
    canvas.drawPath(flap, ink);
    canvas.drawRRect(body, ink);
    final seal = Offset(body.left + w / 2, body.top + h * .55);
    canvas.drawCircle(seal, w * .11, Paint()..color = SkyColors.coral);
    canvas.drawCircle(seal, w * .11, ink..strokeWidth = w * .035);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlightPainter old) => old.bird != bird;
}

class _MessageSide extends StatelessWidget {
  const _MessageSide({required this.letter, required this.chapter});
  final CampaignLetter letter;
  final int chapter;

  /// Blue ballpoint, for what the courier's friends wrote by hand.
  static const pen = Color(0xff2e5f93);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: _card(const Color(0xfffffaef)),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: CampaignPaperPainter(seed: chapter, radius: 11.4),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: CampaignAirmailPainter(radius: 11.4)),
          ),
          // A faint club seal on the paper, behind the message.
          const Positioned(
            left: 132,
            top: 163,
            width: 90,
            height: 90,
            child: CustomPaint(painter: _SealPainter()),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 13,
            child: Center(
              child: FitText(
                l.campaignPostcardHeader,
                style: bodyText(
                  10,
                  color: SkyColors.muted.withValues(alpha: .7),
                  weight: FontWeight.w900,
                ).copyWith(letterSpacing: 2.4),
              ),
            ),
          ),
          // The message on the left, the stamp and address on the right.
          Positioned(
            left: 24,
            top: 36,
            width: 222,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The message keeps to its half of the card: a longer
                // translation sets a little smaller rather than run into the
                // signature.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(
                      width: _messageWidth,
                      child: Column(
                        key: const ValueKey('campaign-postcard-message'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Pen(
                            angle: -.03,
                            child: Text(
                              l.campaignPostcardGreeting,
                              style: heading(24, color: pen),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            letter.bodyIn(l),
                            style: bodyText(
                              14,
                              weight: FontWeight.w700,
                            ).copyWith(height: 1.34),
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${l.campaignPostcardPs} ',
                                  style: heading(
                                    14,
                                    color: SkyColors.coralDeep,
                                  ),
                                ),
                                TextSpan(text: letter.postscriptIn(l)),
                              ],
                            ),
                            style: bodyText(
                              13,
                              color: SkyColors.muted,
                              weight: FontWeight.w700,
                            ).copyWith(height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // The flourish is as wide as the name it underlines.
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Pen(
                        angle: -.03,
                        child: Text(
                          l.campaignPostcardSignature(letter.routeIn(l)),
                          style: heading(18, color: pen),
                        ),
                      ),
                      const SizedBox(height: 1),
                      const CustomPaint(
                        size: Size.fromHeight(9),
                        painter: _FlourishPainter(pen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 258,
            top: 40,
            bottom: 26,
            child: CustomPaint(
              size: const Size(2, double.infinity),
              painter: _DashPainter(),
            ),
          ),
          Positioned(
            right: 22,
            top: 22,
            width: 86,
            height: 102,
            child: Transform.rotate(
              angle: .03 + chapter % 3 * .02,
              child: CustomPaint(
                painter: CampaignStampPainter(
                  letter.boss,
                  chapter: chapter,
                  label: l.campaignStampSkyClub,
                ),
              ),
            ),
          ),
          // The postmark's ring bites the stamp's lower corner; its cancel
          // lines run across the stamp and off the card.
          Positioned(
            left: 251,
            top: 103,
            width: 136,
            height: 62,
            child: Transform.rotate(
              angle: -.1,
              child: CustomPaint(
                painter: CampaignPostmarkPainter(
                  top: letter.postmarkIn(l),
                  middle: l.campaignPostmarkDelivered,
                  bottom: l.campaignPostmarkClub,
                ),
              ),
            ),
          ),
          Positioned(
            left: 272,
            right: 18,
            top: 167,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddressLine(l.campaignPostcardAddressName, angle: -.012),
                const SizedBox(height: 6),
                _AddressLine(l.campaignPostcardAddressStreet, angle: .01),
                const SizedBox(height: 6),
                _AddressLine(l.campaignPostcardAddressCity, angle: -.008),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The width of the message column, beside the stamp.
  static const _messageWidth = 222.0;
}

/// Handwriting in Fredoka: leaned over and set a little off the baseline,
/// which is all it takes to stop it looking typeset.
class _Pen extends StatelessWidget {
  const _Pen({required this.child, this.angle = 0});
  final Widget child;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform(
    alignment: Alignment.bottomLeft,
    transform: Matrix4.rotationZ(angle)..multiply(Matrix4.skewX(-.15)),
    child: child,
  );
}

/// One handwritten address line on a faint rule.
class _AddressLine extends StatelessWidget {
  const _AddressLine(this.text, {required this.angle});
  final String text;
  final double angle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: SkyColors.muted.withValues(alpha: .4),
          width: 1.4,
        ),
      ),
    ),
    child: _Pen(
      angle: angle,
      child: FitText(
        text,
        style: heading(14.5, color: _MessageSide.pen, weight: FontWeight.w500),
      ),
    ),
  );
}

/// The Sky Club's round seal, printed pale on the page.
class _SealPainter extends CustomPainter {
  const _SealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.width / 2;
    final ink = Paint()
      ..color = SkyColors.coral.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .07;
    canvas.drawCircle(c, r * .96, ink);
    canvas.drawCircle(c, r * .8, ink..strokeWidth = r * .035);
    // Beads around the inner ring.
    final bead = Paint()..color = ink.color;
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * .88,
        r * .03,
        bead,
      );
    }
    StarArt.sparkle(canvas, c, r * .5, ink.color, rotation: .2);
  }

  @override
  bool shouldRepaint(_SealPainter old) => false;
}

/// A pen flourish under the signature.
class _FlourishPainter extends CustomPainter {
  const _FlourishPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * .7)
        ..cubicTo(w * .2, h * 1.1, w * .42, h * .1, w * .6, h * .55)
        ..cubicTo(w * .7, h * .85, w * .82, h * .45, w * .98, h * .3),
      Paint()
        ..color = color.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FlourishPainter old) => old.color != color;
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SkyColors.muted.withValues(alpha: .3)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var y = 0.0; y < size.height; y += 9) {
      canvas.drawLine(
        Offset(1, y),
        Offset(1, math.min(size.height, y + 4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}
