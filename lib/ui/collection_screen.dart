import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../game/bird_trail.dart';
import 'components.dart';
import 'home_keys.dart' show HomeKeyColors;
import 'match_hud.dart' show MatchPlate;
import 'mini_chrome.dart';
import 'theme.dart';

/// Each bird's color, from its feathers: Pip, Peaches, Minty, Orbit.
const _birdColors = [
  SkyColors.yellow,
  SkyColors.coral,
  SkyColors.mint,
  SkyColors.lavender,
];

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});
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
                        title: 'Meet your flight crew.',
                        size: 34,
                        onBack: () => context.go('/'),
                        trailing: [
                          MiniTag(
                            '${p.birdsFlown.length} OF ${birdNames.length} FLOWN',
                            icon: Icons.flutter_dash_rounded,
                            color: SkyColors.yellow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 64),
                        child: Text(
                          'Four personalities, four trails. Pick who flies with you next.',
                          style: bodyText(15, weight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final i in birdOrder) ...[
                              if (i != birdOrder.first)
                                const SizedBox(width: 16),
                              Expanded(
                                child: _BirdCard(index: i, progress: p),
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
        selected = p.settings.bird == i,
        color = _birdColors[i];
    return DecoratedBox(
      key: ValueKey('bird-card-$i'),
      // The co-pilot's card glows, like the title screen's main keys.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (selected)
            const BoxShadow(
              color: Color(0x99ffd45b),
              blurRadius: 22,
              spreadRadius: 2,
            ),
        ],
      ),
      child: MiniCard(
        accent: selected ? SkyColors.gold : color,
        color: selected ? const Color(0xfffff4d2) : SkyColors.cream,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(
              child: MiniArtBand(
                color: color,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: 30,
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
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Pill(
                          selected ? 'YOUR CO-PILOT' : 'READY TO FLY',
                          icon: selected
                              ? Icons.check_rounded
                              : Icons.favorite_outline,
                          color: selected ? SkyColors.yellow : SkyColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(birdNames[i], style: heading(26, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              BirdTrail.names[i],
              style: bodyText(
                13,
                color: SkyColors.muted,
                weight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: SizedBox(
                height: 56,
                child: selected
                    ? const _Equipped()
                    : MiniKey(
                        label: 'Fly with me',
                        colors: HomeKeyColors.sun,
                        height: 56,
                        size: 19,
                        busy: busy,
                        onPressed: busy ? null : equip,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the co-pilot's card would offer its key: a plate saying it is
/// already on board, sunk to the key's lip so the rows line up.
class _Equipped extends StatelessWidget {
  const _Equipped();

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
            Text('Equipped', style: heading(19, weight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
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
