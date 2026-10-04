import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/passport_progress.dart';
import '../domain/sky_passport.dart';
import 'components.dart';
import 'mini_chrome.dart';
import 'theme.dart';

// teal is too light for small text on paper.
const _tealInk = Color(0xff1f6a5b);

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).asData?.value;
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MiniHeader(
                  title: 'Your sky passport.',
                  size: 34,
                  onBack: () => context.go('/'),
                  trailing: [
                    MiniPillKey(
                      icon: Icons.wb_sunny_rounded,
                      label: 'Daily card',
                      onPressed: () => context.go('/daily'),
                    ),
                    MiniTag(
                      '${progress?.earnedStamps ?? 0} / ${SkyStamp.values.length} STAMPS',
                      icon: Icons.workspace_premium_rounded,
                      color: SkyColors.yellow,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Text(
                    'Small adventures. Lasting souvenirs. Earn stamps in scored flights.',
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
/// edges. An earned stamp is tinted in its color and franked with a
/// postmark; one still to earn shows how far along it is.
class _StampCard extends StatelessWidget {
  const _StampCard({required this.progress});
  final StampProgress progress;
  @override
  Widget build(BuildContext context) {
    final stamp = progress.stamp;
    final earned = progress.earned;
    final icon = switch (stamp) {
      SkyStamp.firstWings => Icons.flight_takeoff_rounded,
      SkyStamp.onTheDot => Icons.center_focus_strong_rounded,
      SkyStamp.starChaser => Icons.star_rounded,
      SkyStamp.constellation => Icons.auto_awesome_rounded,
      SkyStamp.skyCaptain => Icons.explore_rounded,
      SkyStamp.trailblazer => Icons.route_rounded,
      SkyStamp.flockTogether => Icons.flutter_dash_rounded,
      SkyStamp.bothWings => Icons.favorite_rounded,
    };
    final accent = [
      SkyColors.yellow,
      SkyColors.mint,
      SkyColors.coral,
      SkyColors.lavender,
    ][stamp.index % 4];
    return Semantics(
      label:
          '${stamp.title}. ${stamp.description} ${earned ? 'Earned' : '${progress.current} of ${stamp.target}'}',
      excludeSemantics: true,
      child: CustomPaint(
        painter: _StampPainter(
          tint: earned
              ? Color.lerp(SkyColors.cream, accent, .42)!
              : SkyColors.cream,
          earned: earned,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MiniCoin(icon: icon, color: accent, size: 32, muted: !earned),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stamp.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: heading(17, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stamp.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: bodyText(11.5, color: SkyColors.muted),
              ),
              const Spacer(),
              if (earned)
                const Align(
                  alignment: Alignment.centerRight,
                  child: _Postmark(),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: MiniMeter(
                        value: progress.fraction,
                        color: accent,
                        height: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${progress.current}/${stamp.target}',
                      style: bodyText(11, weight: FontWeight.w900),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The frank on an earned stamp: a tilted oval of teal ink.
class _Postmark extends StatelessWidget {
  const _Postmark();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.14,
    child: Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tealInk, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 1, 9, 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _tealInk.withValues(alpha: .6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 14, color: _tealInk),
            const SizedBox(width: 3),
            Text(
              'STAMPED',
              style: bodyText(
                11,
                color: _tealInk,
                weight: FontWeight.w900,
              ).copyWith(letterSpacing: 1.4, height: 1.2),
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
