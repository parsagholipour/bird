import 'package:flutter/material.dart';
import 'theme.dart';

/// A flight's target stays fixed even while the saved record is being updated.
class RecordChase extends StatelessWidget {
  const RecordChase({
    super.key,
    required this.best,
    required this.score,
    required this.reducedMotion,
  });

  final int best, score;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final beaten = score > best;
    final matched = score == best;
    final remaining = best + 1 - score;
    final title = beaten
        ? 'New best!'
        : matched
        ? 'Best matched!'
        : 'Best $best';
    final detail = beaten
        ? '+${score - best} beyond your best'
        : remaining == 1
        ? 'One more for a record'
        : '$remaining to a new record';
    return Semantics(
      label: '$title. $detail.',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(beaten),
          tween: Tween(begin: beaten && !reducedMotion ? 1.1 : 1, end: 1),
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: beaten || matched ? SkyColors.yellow : SkyColors.cream,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  beaten ? Icons.emoji_events_rounded : Icons.flag_outlined,
                  size: 25,
                  color: SkyColors.ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(title, style: heading(18)),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(detail, style: bodyText(11)),
                      ),
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
