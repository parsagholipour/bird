import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../game/bird_trail.dart';
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
                            '${p.birdsFlown.length} of ${birdNames.length} flown',
                            icon: Icons.flutter_dash_rounded,
                            color: SkyColors.yellow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 66),
                        child: Text(
                          'Four personalities, four trails. Pick who flies with you next.',
                          style: bodyText(16, color: SkyColors.muted),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < birdNames.length; i++) ...[
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
        selected = p.settings.bird == i;
    return Panel(
      padding: const EdgeInsets.all(16),
      color: selected ? const Color(0xfffff2c9) : SkyColors.cream,
      child: Column(
        children: [
          Pill(
            selected ? 'YOUR CO-PILOT' : 'READY TO FLY',
            icon: selected ? Icons.check_rounded : Icons.favorite_outline,
            color: selected ? SkyColors.yellow : SkyColors.white,
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 188,
                  height: 120,
                  child: CustomPaint(
                    painter: _TrailPreview(bird: i),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: BirdArt(
                        bird: i,
                        size: 132,
                        reducedMotion: p.settings.reducedMotion,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(birdNames[i], style: heading(26)),
          const SizedBox(height: 6),
          Text(
            BirdTrail.names[i],
            style: bodyText(13, color: SkyColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SkyButton(
              label: selected ? 'Equipped' : 'Fly with me',
              icon: selected
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: !selected && !busy ? equip : null,
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

class _TrailPreview extends CustomPainter {
  const _TrailPreview({required this.bird});
  final int bird;

  // Anchored a flight-sized step ahead of the art's tail, so the card shows
  // the trail as it leaves the bird rather than only its faded end.
  @override
  void paint(Canvas canvas, Size size) => BirdTrail.paint(
    canvas,
    bird: bird,
    anchor: Offset(size.width * .46, size.height * .5),
    unit: 4.6,
    animate: false,
  );

  @override
  bool shouldRepaint(_TrailPreview oldDelegate) => oldDelegate.bird != bird;
}
