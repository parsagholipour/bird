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
                          'Every star you pick up in flight is one to spend. Upgrades work on every new flight.',
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Badge(symbol: symbolOf(up), color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        up.title,
                        style: heading(23, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 3),
                    _LevelPips(level: level, color: color),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Everything reads at a glance: on a short screen the details
          // shrink a little rather than hide behind a scroll.
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: box.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        up.blurb,
                        style: bodyText(
                          15,
                          color: SkyColors.muted,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final (i, (label, value)) in stats.indexed)
                        _StatLine(label: label, now: value, next: next?[i].$2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 50,
            child: cost == null
                ? const _Maxed()
                : MiniKey(
                    key: ValueKey('buy-${up.name}'),
                    // The game's fonts have no ★, so the key's icon is the
                    // star: "50 ★".
                    label: '$cost',
                    icon: Icons.star_rounded,
                    colors: p.canBuy(up)
                        ? HomeKeyColors.sun
                        : HomeKeyColors.paper,
                    height: 50,
                    size: 18,
                    busy: busy,
                    onPressed: busy || !p.canBuy(up) ? null : buy,
                  ),
          ),
        ],
      ),
    );
  }
}

/// The upgrade's HUD symbol on a round chip of its color.
class _Badge extends StatelessWidget {
  const _Badge({required this.symbol, required this.color});
  final MatchSymbol symbol;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: SkyColors.ink, width: 2),
    ),
    alignment: Alignment.center,
    child: MatchIcon(symbol, size: 32),
  );
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

/// One stat: its label, its value now and, in teal, the next level's.
class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.now, this.next});
  final String label, now;
  final String? next;

  @override
  Widget build(BuildContext context) {
    final upgrade = next != null && next != now;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Semantics(
        label: upgrade ? '$label $now, next level $next' : '$label $now',
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: bodyText(
                  15,
                  color: SkyColors.muted,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            Text(now, style: bodyText(16, weight: FontWeight.w900)),
            // The game's fonts have no arrow glyph; the icon reads the same.
            if (upgrade) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: SkyColors.teal,
                ),
              ),
              Text(
                next!,
                style: bodyText(
                  16,
                  color: SkyColors.teal,
                  weight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
