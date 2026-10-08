import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/passport_progress.dart';
import '../domain/sky_passport.dart';
import '../l10n/l10n.dart';
import '../l10n/text/passport_text.dart';
import 'components.dart';
import 'fit_text.dart';
import 'mini_chrome.dart';
import 'theme.dart';

// teal is too light for small text on paper.
const _tealInk = Color(0xff1f6a5b);

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).asData?.value;
    final l = context.l10n;
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MiniHeader(
                  title: l.passportTitle,
                  size: 34,
                  onBack: () => context.go('/'),
                  trailing: [
                    MiniPillKey(
                      icon: Icons.wb_sunny_rounded,
                      label: l.passportDailyCard,
                      onPressed: () => context.go('/daily'),
                    ),
                    MiniTag(
                      l.passportMedalsTag(
                        progress?.earnedMedals ?? 0,
                        passportMedals,
                      ),
                      icon: Icons.workspace_premium_rounded,
                      color: SkyColors.yellow,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 64),
                  child: FitText(
                    l.passportIntro,
                    style: bodyText(15, weight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: progress == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            for (
                              var row = 0;
                              row < (progress.passport.length / 4).ceil();
                              row++
                            ) ...[
                              if (row > 0) const SizedBox(height: 8),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (var col = 0; col < 4; col++) ...[
                                      if (col > 0) const SizedBox(width: 8),
                                      Expanded(
                                        child:
                                            row * 4 + col <
                                                progress.passport.length
                                            ? _StampCard(
                                                progress: progress
                                                    .passport[row * 4 + col],
                                              )
                                            : const SizedBox(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
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

/// One stamp of the passport, printed as a postage stamp with perforated
/// edges. Its three medals sit along the bottom, and the stamp tints deeper
/// in its color with each one. Until gold it shows the next medal's goal and
/// how far along it is; a gold stamp is franked with a postmark.
class _StampCard extends StatelessWidget {
  const _StampCard({required this.progress});
  final StampProgress progress;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stamp = progress.stamp;
    final medal = progress.medal;
    final name = l.stampName(stamp);
    final goal = l.stampProgressGoal(progress);
    final icon = switch (stamp) {
      SkyStamp.frequentFlyer => Icons.flight_takeoff_rounded,
      SkyStamp.onTheDot => Icons.center_focus_strong_rounded,
      SkyStamp.starChaser => Icons.star_rounded,
      SkyStamp.constellation => Icons.auto_awesome_rounded,
      SkyStamp.skyCaptain => Icons.explore_rounded,
      SkyStamp.trailblazer => Icons.route_rounded,
      SkyStamp.flockTogether => Icons.flutter_dash_rounded,
      SkyStamp.allRounder => Icons.fitness_center_rounded,
    };
    final accent = [
      SkyColors.yellow,
      SkyColors.mint,
      SkyColors.coral,
      SkyColors.lavender,
    ][stamp.index % 4];
    final held = medal == null
        ? l.passportNoMedal
        : l.passportMedalHeld(medal.name);
    return Semantics(
      label: progress.complete
          ? l.passportStampDoneSemantics(name, goal)
          : l.passportStampSemantics(
              name,
              held,
              l.medalName(progress.aim),
              goal,
              progress.current,
              progress.target,
            ),
      excludeSemantics: true,
      child: CustomPaint(
        painter: _StampPainter(
          tint: medal == null
              ? SkyColors.cream
              : Color.lerp(
                  SkyColors.cream,
                  accent,
                  const [.2, .32, .46][medal.index],
                )!,
          earned: medal != null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MiniCoin(
                    icon: icon,
                    color: accent,
                    size: 30,
                    muted: medal == null,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: FitText(
                      name,
                      style: heading(16.5, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              FitParagraph(goal, style: bodyText(11.5, color: SkyColors.muted)),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in StampMedal.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 3),
                      child: _Medal(
                        m,
                        won: medal != null && m.index <= medal.index,
                        next: m == progress.nextMedal,
                      ),
                    ),
                  const Spacer(),
                  if (progress.complete)
                    const _Postmark()
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        l.passportToMedal(progress.aim.name),
                        style: bodyText(
                          10.5,
                          color: SkyColors.muted,
                          weight: FontWeight.w900,
                        ).copyWith(letterSpacing: 1.1),
                      ),
                    ),
                ],
              ),
              if (!progress.complete) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: MiniMeter(
                        value: progress.fraction,
                        color: accent,
                        height: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.stampTally(progress),
                      style: bodyText(11, weight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A medal's metal: a face, a darker rim and a ribbon.
const _metals = {
  StampMedal.bronze: (Color(0xffd9955a), Color(0xff9c5d2c), SkyColors.coral),
  StampMedal.silver: (Color(0xffdfe6ee), Color(0xff8e9cae), SkyColors.sky),
  StampMedal.gold: (SkyColors.yellow, SkyColors.gold, SkyColors.coral),
};

/// One small medal on its ribbon. A medal won is struck in its metal; one
/// still to win is a pale blank, outlined darker when it is the next one.
class _Medal extends StatelessWidget {
  const _Medal(this.medal, {required this.won, required this.next});
  final StampMedal medal;
  final bool won, next;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 21,
    height: 27,
    child: CustomPaint(
      painter: _MedalPainter(medal, won: won, next: next),
    ),
  );
}

class _MedalPainter extends CustomPainter {
  const _MedalPainter(this.medal, {required this.won, required this.next});
  final StampMedal medal;
  final bool won, next;

  @override
  void paint(Canvas canvas, Size size) {
    final (face, rim, ribbon) = _metals[medal]!;
    final ink = SkyColors.ink.withValues(alpha: won ? 1 : (next ? .6 : .28));
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = won || next ? 1.6 : 1.3
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final r = w / 2 - 1;
    final center = Offset(w / 2, size.height - r - 1);
    // The ribbon: a V of two tails from the top edge to the medal.
    if (won) {
      for (final side in [-1.0, 1.0]) {
        final tail = Path()
          ..moveTo(w / 2 + side * 7, 1)
          ..lineTo(w / 2 + side * 2, 1)
          ..lineTo(w / 2 - side * 3, center.dy - r + 2.5)
          ..lineTo(w / 2 + side * 2, center.dy - r + 2.5)
          ..close();
        canvas.drawPath(
          tail,
          Paint()..color = side < 0 ? ribbon : Color.lerp(ribbon, rim, .35)!,
        );
        canvas.drawPath(tail, outline);
      }
    }
    if (won) {
      canvas.drawCircle(center + const Offset(0, 1.4), r, Paint()..color = ink);
    }
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = won
            ? rim
            : next
            ? Color.lerp(SkyColors.cream, face, .55)!
            : Color.lerp(SkyColors.cream, SkyColors.sky, .3)!,
    );
    if (next) {
      // The next medal waits in a dashed ring of its metal's rim.
      final ring = Path()
        ..addOval(Rect.fromCircle(center: center, radius: r - 2.6));
      for (final metric in ring.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 4.4) {
          canvas.drawPath(
            metric.extractPath(d, d + 2.2),
            Paint()
              ..color = rim
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
        }
      }
    }
    if (won) {
      canvas.drawCircle(center, r - 2.2, Paint()..color = face);
      // A struck star and a glint.
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final d = i.isEven ? r * .52 : r * .23;
        final p = center + Offset(math.cos(a) * d, math.sin(a) * d);
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      star.close();
      canvas.drawPath(star, Paint()..color = rim);
      canvas.drawCircle(
        center + Offset(-r * .42, -r * .42),
        1.1,
        Paint()..color = SkyColors.white.withValues(alpha: .85),
      );
    }
    canvas.drawCircle(center, r, outline);
  }

  @override
  bool shouldRepaint(_MedalPainter oldDelegate) =>
      oldDelegate.medal != medal ||
      oldDelegate.won != won ||
      oldDelegate.next != next;
}

/// The frank on a gold stamp: a tilted oval of teal ink.
class _Postmark extends StatelessWidget {
  const _Postmark();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.12,
    child: Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tealInk, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 0, 7, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _tealInk.withValues(alpha: .6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 13, color: _tealInk),
            const SizedBox(width: 2),
            Text(
              context.l10n.passportStamped,
              style: bodyText(
                10.5,
                color: _tealInk,
                weight: FontWeight.w900,
              ).copyWith(letterSpacing: 1.2, height: 1.2),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A postage stamp: white paper with a perforated edge and an ink outline,
/// and an inner frame in [tint]. The frame of an unearned stamp is dashed,
/// waiting for its picture.
class _StampPainter extends CustomPainter {
  const _StampPainter({required this.tint, required this.earned});
  final Color tint;
  final bool earned;

  static const _hole = 3.6, _pitch = 12.0, _frame = 8.0;

  Path _paper(Size size) {
    var paper = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
      );
    final holes = Path();
    void edge(Offset from, Offset to) {
      final length = (to - from).distance;
      final count = math.max(1, (length / _pitch).round());
      for (var i = 0; i <= count; i++) {
        holes.addOval(
          Rect.fromCircle(
            center: Offset.lerp(from, to, i / count)!,
            radius: _hole,
          ),
        );
      }
    }

    edge(Offset.zero, Offset(size.width, 0));
    edge(Offset(0, size.height), Offset(size.width, size.height));
    edge(Offset(0, _pitch), Offset(0, size.height - _pitch));
    edge(Offset(size.width, _pitch), Offset(size.width, size.height - _pitch));
    paper = Path.combine(PathOperation.difference, paper, holes);
    return paper;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paper = _paper(size);
    canvas.drawPath(
      paper.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink.withValues(alpha: .28),
    );
    canvas.drawPath(paper, Paint()..color = SkyColors.white);
    canvas.drawPath(
      paper,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    final frame = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(_frame),
      const Radius.circular(8),
    );
    canvas.drawRRect(frame, Paint()..color = tint);
    final line = Paint()
      ..color = earned ? SkyColors.ink : SkyColors.ink.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = earned ? 1.6 : 1.4;
    if (earned) {
      canvas.drawRRect(frame, line);
    } else {
      for (final metric in (Path()..addRRect(frame)).computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 9) {
          canvas.drawPath(metric.extractPath(d, d + 5), line);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StampPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.earned != earned;
}
