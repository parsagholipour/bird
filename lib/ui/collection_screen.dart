import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import 'components.dart';
import 'theme.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider).asData?.value;
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: p == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RoundButton(
                            icon: Icons.arrow_back_rounded,
                            label: 'Back home',
                            onPressed: () => context.go('/'),
                          ),
                          const SizedBox(width: 18),
                          Text('Meet your flight crew.', style: heading(36)),
                          const Spacer(),
                          Pill(
                            '${p.totalObstacles} obstacles cleared',
                            icon: Icons.auto_awesome,
                            color: SkyColors.yellow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 66),
                        child: Text(
                          'Little personalities. Same big adventure. Unlock birds in either scored mode.',
                          style: bodyText(16, color: SkyColors.muted),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < 4; i++) ...[
                              if (i > 0) const SizedBox(width: 16),
                              Expanded(
                                child: _BirdCard(index: i, progress: p),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _BirdCard extends ConsumerStatefulWidget {
  const _BirdCard({required this.index, required this.progress});
  final int index;
  final ProgressSnapshot progress;
  @override
  ConsumerState<_BirdCard> createState() => _BirdCardState();
}

class _BirdCardState extends ConsumerState<_BirdCard> {
  bool busy = false;
  Future<void> equip() async {
    setState(() => busy = true);
    try {
      await ref.read(progressProvider.notifier).equip(widget.index);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.index,
        p = widget.progress,
        unlocked = p.unlocked.contains(i),
        selected = p.settings.bird == i;
    return Panel(
      padding: const EdgeInsets.all(16),
      color: selected ? const Color(0xfffff2c9) : SkyColors.cream,
      child: Column(
        children: [
          Pill(
            selected
                ? 'YOUR CO-PILOT'
                : unlocked
                ? 'READY TO FLY'
                : '${unlockThresholds[i]} OBSTACLES',
            icon: selected
                ? Icons.check_rounded
                : unlocked
                ? Icons.favorite_outline
                : Icons.lock_outline,
            color: selected ? SkyColors.yellow : SkyColors.white,
          ),
          Expanded(
            child: Center(
              child: Opacity(
                opacity: unlocked ? 1 : .42,
                child: BirdArt(
                  bird: i,
                  size: 158,
                  bob: unlocked,
                  reducedMotion: p.settings.reducedMotion,
                ),
              ),
            ),
          ),
          Text(birdNames[i], style: heading(26)),
          const SizedBox(height: 6),
          Text(
            birdDescriptions[i],
            style: bodyText(13, color: SkyColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SkyButton(
              label: selected
                  ? 'Equipped'
                  : unlocked
                  ? 'Fly with me'
                  : '${unlockThresholds[i] - p.totalObstacles} to unlock',
              icon: selected
                  ? Icons.check_rounded
                  : unlocked
                  ? Icons.arrow_forward_rounded
                  : Icons.lock_outline,
              onPressed: unlocked && !selected && !busy ? equip : null,
              color: SkyColors.yellow,
              compact: true,
              busy: busy,
            ),
          ),
        ],
      ),
    );
  }
}
