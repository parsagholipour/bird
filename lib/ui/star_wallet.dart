import 'package:flutter/material.dart';
import 'match_hud.dart' show MatchIcon, MatchSymbol;
import 'theme.dart';

/// The stars to spend, in the gold pill the shop screens show them in.
/// Found in tests by its `star-wallet` key.
class StarWallet extends StatelessWidget {
  const StarWallet({super.key, required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('star-wallet'),
    label: '$stars stars to spend',
    excludeSemantics: true,
    child: Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
      decoration: BoxDecoration(
        color: SkyColors.yellow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SkyColors.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: SkyColors.gold, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MatchIcon(MatchSymbol.star, size: 38),
          const SizedBox(width: 6),
          Text(
            '$stars',
            style: heading(32, weight: FontWeight.w700).copyWith(height: 1),
          ),
          const SizedBox(width: 8),
          Text(
            'YOUR\nSTARS',
            style: bodyText(
              13,
              color: SkyColors.muted,
              weight: FontWeight.w900,
            ).copyWith(height: 1.05, letterSpacing: .5),
          ),
        ],
      ),
    ),
  );
}
