import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/power_ups.dart';
import 'components.dart';
import 'home_keys.dart' show HomeKeyColors;
import 'match_hud.dart' show MatchIcon, MatchPlate, MatchSymbol;
import 'mini_chrome.dart';
import 'theme.dart';

/// Spends collected stars on the four upgrades ([PowerUp]).
class UpgradesScreen extends ConsumerWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider).asData?.value;
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
            child: p == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MiniHeader(
                        title: 'Power up your bird.',
                        size: 34,
                        onBack: () => context.go('/'),
                        trailing: [
                          MiniTag(
                            '${p.starWallet} STARS',
                            key: const ValueKey('star-wallet'),
                            icon: Icons.star_rounded,
                            color: SkyColors.yellow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 64),
                        child: Text(
                          'Spend the stars you collect in flight. Upgrades work on every new flight.',
                          style: bodyText(15, weight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final up in PowerUp.values) ...[
                              if (up != PowerUp.values.first)
                                const SizedBox(width: 16),
                              Expanded(
                                child: _UpgradeCard(power: up, progress: p),
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

class _UpgradeCard extends ConsumerStatefulWidget {
  const _UpgradeCard({required this.power, required this.progress});
  final PowerUp power;
  final ProgressSnapshot progress;

  @override
  ConsumerState<_UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends ConsumerState<_UpgradeCard> {
  bool busy = false;

  Future<void> buy() async {
    setState(() => busy = true);
    try {
      await ref.read(progressProvider.notifier).buyUpgrade(widget.power);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  static Color colorOf(PowerUp p) => switch (p) {
    PowerUp.shot => SkyColors.coral,
    PowerUp.sprint => SkyColors.yellow,
    PowerUp.shield => SkyColors.teal,
    PowerUp.magnet => SkyColors.lavender,
  };

  static MatchSymbol symbolOf(PowerUp p) => switch (p) {
    PowerUp.shot => MatchSymbol.shot,
    PowerUp.sprint => MatchSymbol.sprint,
    PowerUp.shield => MatchSymbol.shield,
    PowerUp.magnet => MatchSymbol.magnet,
  };

  @override
  Widget build(BuildContext context) {
    final up = widget.power, p = widget.progress;
    final level = p.upgrades[up];
    final cost = PowerUp.costFrom(level);
    final color = colorOf(up);
    final stats = up.stats(level);
    final next = cost == null ? null : up.stats(level + 1);
    return MiniCard(
      key: ValueKey('upgrade-card-${up.name}'),
      accent: color,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 96,
            child: MiniArtBand(
              color: color,
              child: Center(child: MatchIcon(symbolOf(up), size: 56)),
            ),
          ),
          const SizedBox(height: 6),
          Text(up.title, style: heading(24, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          _LevelPips(level: level, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      up.blurb,
                      style: bodyText(
                        13,
                        color: SkyColors.muted,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final (i, line) in stats.indexed)
                      _StatLine(line, next: next?[i]),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: SizedBox(
              height: 56,
              child: cost == null
                  ? const _Maxed()
                  : MiniKey(
                      key: ValueKey('buy-${up.name}'),
                      label: '$cost ★',
                      icon: Icons.arrow_upward_rounded,
                      colors: p.canBuy(up)
                          ? HomeKeyColors.sun
                          : HomeKeyColors.paper,
                      height: 56,
                      size: 19,
                      busy: busy,
                      onPressed: busy || !p.canBuy(up) ? null : buy,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Five pips: the levels bought, out of the top.
class _LevelPips extends StatelessWidget {
  const _LevelPips({required this.level, required this.color});
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Level $level of ${PowerUp.maxLevel}',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= PowerUp.maxLevel; i++)
          Container(
            width: 22,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i <= level ? color : SkyColors.ink.withValues(alpha: .1),
              border: Border.all(color: SkyColors.ink, width: 1.6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ],
    ),
  );
}

/// One stat at the current level, and what the next level makes of it.
class _StatLine extends StatelessWidget {
  const _StatLine(this.now, {this.next});
  final String now;
  final String? next;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: now),
          if (next != null && next != now)
            TextSpan(
              text: '  →  $next',
              style: bodyText(
                13,
                color: SkyColors.teal,
                weight: FontWeight.w900,
              ),
            ),
        ],
      ),
      style: bodyText(13, weight: FontWeight.w800),
    ),
  );
}

/// Where a topped-out card would offer its key.
class _Maxed extends StatelessWidget {
  const _Maxed();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2, bottom: 8),
    child: MatchPlate(
      color: SkyColors.mint,
      radius: 20,
      padding: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 22,
              color: SkyColors.ink,
            ),
            const SizedBox(width: 8),
            Text('Maxed out', style: heading(19, weight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}
