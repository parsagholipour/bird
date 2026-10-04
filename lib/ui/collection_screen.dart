import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../game/bird_trail.dart';
import 'components.dart';
import 'home_keys.dart' show HomeKey, HomeKeyColors;
import 'match_hud.dart' show MatchIcon, MatchSymbol, matchInkEdge;
import 'mini_chrome.dart';
import 'star_wallet.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// Each bird's tile color, from its feathers: Pip, Peaches, Minty, Orbit.
const _birdColors = [
  SkyColors.yellow,
  SkyColors.coral,
  SkyColors.mint,
  SkyColors.lavender,
];

/// The showcase panel's deeper take on the same colors.
const _panelColors = [
  Color(0xffffc93f),
  Color(0xfff2856d),
  Color(0xff66c197),
  Color(0xff9a88e4),
];

/// Greyed ink for what the wallet cannot pay for yet.
const _locked = Color(0xff6d8086), _lockedFace = Color(0xffefe7d6);
const _lockedLip = Color(0xff9fb0b4);

/// The flight crew, arcade style: a big showcase of the bird being looked
/// at beside a 2×2 roster. Tapping a tile only looks; the showcase's one key
/// flies with that bird, or unlocks it with collected stars first.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  int? _viewing;
  bool _busy = false;

  /// Runs [action] and, once it has gone through, plays [cue].
  Future<void> _run(
    Future<void> Function(ProgressController) action,
    String cue,
  ) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(progressProvider.notifier));
      if (mounted) UiSounds.effect(context, cue);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider).asData?.value;
    final viewing = p == null ? null : _viewing ?? p.settings.bird;
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
            child: p == null || viewing == null
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
                            color: SkyColors.cream,
                          ),
                          StarWallet(stars: p.starWallet),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 11,
                              child: _Showcase(
                                bird: viewing,
                                progress: p,
                                busy: _busy,
                                onFly: () => _run(
                                  (n) => n.equip(viewing),
                                  ShopCues.birdEquip,
                                ),
                                onUnlock: () => _run(
                                  (n) => n.unlockBird(viewing),
                                  ShopCues.birdUnlock,
                                ),
                                onDenied: () =>
                                    UiSounds.effect(context, ShopCues.denied),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 9,
                              child: _Roster(
                                progress: p,
                                viewing: viewing,
                                onView: (bird) {
                                  if (bird != viewing) {
                                    UiSounds.effect(context, ShopCues.select);
                                  }
                                  setState(() => _viewing = bird);
                                },
                              ),
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

/// The bird being looked at, bursting out of a panel of its color with its
/// trail streaming behind it: name, personality, trail and flights, and the
/// one key that flies with it or unlocks it.
class _Showcase extends StatelessWidget {
  const _Showcase({
    required this.bird,
    required this.progress,
    required this.busy,
    required this.onFly,
    required this.onUnlock,
    required this.onDenied,
  });
  final int bird;
  final ProgressSnapshot progress;
  final bool busy;
  final VoidCallback onFly, onUnlock, onDenied;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final equipped = p.settings.bird == bird;
    final unlocked = p.birdUnlocked(bird);
    final flights = p.birdFlights[bird] ?? 0;
    final price = birdPrices[bird];
    return LayoutBuilder(
      builder: (context, box) {
        final art = math.min(box.maxHeight * .56, box.maxWidth * .4);
        // The bird hovers low on the right, beside the key, so its trail
        // streams left through the open band between the chips and the key.
        final birdTop = box.maxHeight * .66 - art / 2;
        return Stack(
          key: const ValueKey('bird-showcase'),
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: _panelColors[bird],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: SkyColors.ink, width: 3),
                  boxShadow: const [
                    BoxShadow(color: SkyColors.ink, offset: Offset(0, 6)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: CustomPaint(
                    painter: _Burst(
                      center: Offset(
                        box.maxWidth - art * .55,
                        box.maxHeight * .4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The trail streams from the bird's tail across the panel.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _Trail(
                    bird: bird,
                    anchor: Offset(
                      box.maxWidth - 8 - art * .8,
                      birdTop + art * .52,
                    ),
                    unit: art / 12,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: birdTop,
              child: Opacity(
                opacity: unlocked ? 1 : .92,
                child: BirdArt(
                  key: ValueKey('showcase-bird-$bird'),
                  bird: bird,
                  size: art,
                  reducedMotion: p.settings.reducedMotion,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusPill(equipped: equipped, unlocked: unlocked),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: box.maxWidth * .6,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        birdNames[bird],
                        style: heading(
                          68,
                          color: SkyColors.white,
                          weight: FontWeight.w700,
                        ).copyWith(height: 1.05, shadows: matchInkEdge(3.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.auto_awesome_rounded,
                        text: BirdTrail.names[bird],
                      ),
                      if (!unlocked && !p.canUnlock(bird))
                        _InfoChip(
                          icon: Icons.lock_rounded,
                          text: '${price - p.starWallet} more to go',
                        )
                      else
                        _InfoChip(
                          icon: flights > 0
                              ? Icons.flight_takeoff_rounded
                              : Icons.fiber_new_rounded,
                          text: flights == 0
                              ? 'Not flown yet'
                              : flights == 1
                              ? '1 flight'
                              : '$flights flights',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: BoxConstraints(maxWidth: box.maxWidth * .56),
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
                    decoration: BoxDecoration(
                      color: SkyColors.cream.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SkyColors.ink, width: 2.5),
                    ),
                    child: Text(
                      birdDescriptions[bird],
                      style: bodyText(
                        16,
                        weight: FontWeight.w900,
                      ).copyWith(height: 1.2),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 60,
                    width: box.maxWidth * .58,
                    child: equipped
                        ? const _FlyingNow()
                        : unlocked
                        ? _ActionKey(
                            key: ValueKey('fly-with-$bird'),
                            label: 'Fly with ${birdNames[bird]}',
                            semantics:
                                'Fly with ${birdNames[bird]} instead of '
                                '${birdNames[p.settings.bird]}',
                            enabled: !busy,
                            busy: busy,
                            onPressed: onFly,
                          )
                        : _ActionKey(
                            key: ValueKey('unlock-$bird'),
                            label: 'Unlock ${birdNames[bird]}',
                            semantics: p.canUnlock(bird)
                                ? 'Unlock ${birdNames[bird]} for $price stars'
                                : 'Unlock ${birdNames[bird]} for $price '
                                      'stars, not enough stars yet',
                            price: price,
                            enabled: p.canUnlock(bird) && !busy,
                            busy: busy,
                            onPressed: onUnlock,
                            onDenied: onDenied,
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Soft rays fanning out from behind the bird.
class _Burst extends CustomPainter {
  const _Burst({required this.center});
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final reach = size.longestSide * 1.4;
    final paint = Paint()..color = SkyColors.white.withValues(alpha: .16);
    const rays = 14;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final half = math.pi / rays / 2;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + math.cos(a - half) * reach,
            center.dy + math.sin(a - half) * reach,
          )
          ..lineTo(
            center.dx + math.cos(a + half) * reach,
            center.dy + math.sin(a + half) * reach,
          )
          ..close(),
        paint,
      );
    }
    canvas.drawCircle(
      center,
      size.height * .42,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                SkyColors.white.withValues(alpha: .35),
                SkyColors.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.height * .42),
            ),
    );
  }

  @override
  bool shouldRepaint(_Burst oldDelegate) => center != oldDelegate.center;
}

class _Trail extends CustomPainter {
  const _Trail({required this.bird, required this.anchor, required this.unit});
  final int bird;
  final Offset anchor;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    // A dotted flight line under the marks keeps them readable on any
    // panel color. It follows the trail's resting wave.
    final dot = Paint()..color = SkyColors.white.withValues(alpha: .75);
    for (var x = 2.0; x < 26; x += .9) {
      final wave = math.sin(x * .36) * unit * .6 * math.min(1, x / 7);
      canvas.drawCircle(
        anchor + Offset(-x * unit, wave),
        unit * .13 * (1 - x / 34),
        dot,
      );
    }
    BirdTrail.paint(
      canvas,
      bird: bird,
      anchor: anchor,
      unit: unit,
      animate: false,
    );
  }

  @override
  bool shouldRepaint(_Trail oldDelegate) =>
      bird != oldDelegate.bird ||
      anchor != oldDelegate.anchor ||
      unit != oldDelegate.unit;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.equipped, required this.unlocked});
  final bool equipped, unlocked;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = equipped
        ? (Icons.check_rounded, 'YOUR CO-PILOT')
        : unlocked
        ? (Icons.favorite_rounded, 'READY TO FLY')
        : (Icons.lock_rounded, 'LOCKED');
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 14, 5),
      decoration: BoxDecoration(
        color: SkyColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: SkyColors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: bodyText(
              14,
              color: SkyColors.white,
              weight: FontWeight.w900,
            ).copyWith(letterSpacing: 1, height: 1),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 5, 14, 6),
    decoration: BoxDecoration(
      color: SkyColors.cream,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: SkyColors.ink, width: 2.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: SkyColors.ink),
        const SizedBox(width: 6),
        Text(
          text,
          style: bodyText(15, weight: FontWeight.w900).copyWith(height: 1),
        ),
      ],
    ),
  );
}

/// The showcase's one action: fly with this bird or unlock it for its price, greyed with a lock until
/// the wallet can pay.
class _ActionKey extends StatelessWidget {
  const _ActionKey({
    super.key,
    required this.label,
    required this.semantics,
    required this.enabled,
    required this.busy,
    required this.onPressed,
    this.onDenied,
    this.price,
  });
  final String label, semantics;
  final int? price;
  final bool enabled, busy;
  final VoidCallback onPressed;

  /// Answers a press on the greyed key, when it is not just busy.
  final VoidCallback? onDenied;

  @override
  Widget build(BuildContext context) {
    final live = enabled || busy;
    final ink = live ? SkyColors.ink : _locked;
    final face = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: heading(
                  26,
                  color: ink,
                  weight: FontWeight.w700,
                ).copyWith(height: 1),
              ),
            ),
          ),
          if (price != null)
            Container(
              padding: const EdgeInsets.fromLTRB(6, 3, 12, 3),
              decoration: BoxDecoration(
                color: SkyColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: live ? SkyColors.ink : _lockedLip,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (live)
                    const MatchIcon(MatchSymbol.star, size: 26)
                  else
                    const Icon(Icons.lock_rounded, size: 22, color: _locked),
                  const SizedBox(width: 4),
                  Text(
                    '$price',
                    style: heading(
                      22,
                      color: ink,
                      weight: FontWeight.w700,
                    ).copyWith(height: 1),
                  ),
                ],
              ),
            ),
          // A price chip carries the unlock key's star; a fly key gets
          // the round arrow.
          if (price == null) ...[
            const SizedBox(width: 10),
            SizedBox.square(
              dimension: 30,
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        value: MediaQuery.disableAnimationsOf(context)
                            ? .75
                            : null,
                        strokeWidth: 2.5,
                        color: SkyColors.ink,
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: live ? SkyColors.ink : _lockedLip,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 19,
                        color: SkyColors.white,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: semantics,
      excludeSemantics: true,
      child: enabled
          ? HomeKey(
              label: label,
              colors: HomeKeyColors.sun,
              lip: 6,
              radius: 22,
              onPressed: onPressed,
              builder: (context, _) => face,
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: busy ? null : onDenied,
              child: Container(
                decoration: BoxDecoration(
                  color: live ? SkyColors.yellow : _lockedFace,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: live ? SkyColors.ink : _locked,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: live ? SkyColors.gold : _lockedLip,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: face,
              ),
            ),
    );
  }
}

/// Where the co-pilot's showcase would offer its key: a plate saying it is
/// already flying.
class _FlyingNow extends StatelessWidget {
  const _FlyingNow();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('bird-flying'),
    decoration: BoxDecoration(
      color: SkyColors.mint,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: SkyColors.ink, width: 3),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, size: 26, color: SkyColors.ink),
        const SizedBox(width: 8),
        Text('Flying with you', style: heading(24, weight: FontWeight.w700)),
      ],
    ),
  );
}

/// The four birds as square portrait tiles, two by two.
class _Roster extends StatelessWidget {
  const _Roster({
    required this.progress,
    required this.viewing,
    required this.onView,
  });
  final ProgressSnapshot progress;
  final int viewing;
  final ValueChanged<int> onView;

  @override
  Widget build(BuildContext context) {
    Widget tile(int bird) => Expanded(
      child: _Tile(
        bird: bird,
        progress: progress,
        selected: bird == viewing,
        onTap: () => onView(bird),
      ),
    );
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(birdOrder[0]),
              const SizedBox(width: 14),
              tile(birdOrder[1]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(birdOrder[2]),
              const SizedBox(width: 14),
              tile(birdOrder[3]),
            ],
          ),
        ),
      ],
    );
  }
}

/// One bird's portrait tile: a head-and-shoulders crop on its color and its
/// name. Badges say which bird flies now, which have flown, which are new,
/// and what a locked one costs.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.bird,
    required this.progress,
    required this.selected,
    required this.onTap,
  });
  final int bird;
  final ProgressSnapshot progress;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final equipped = p.settings.bird == bird;
    final unlocked = p.birdUnlocked(bird);
    final flown = p.birdsFlown.contains(bird);
    final price = birdPrices[bird];
    final affordable = p.canUnlock(bird);
    return Semantics(
      button: true,
      selected: selected,
      label: [
        birdNames[bird],
        if (equipped) 'flying with you',
        if (!unlocked) 'locked, $price stars',
        if (unlocked && !flown) 'new',
      ].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('bird-card-$bird'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: SkyColors.ink,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? SkyColors.yellow : SkyColors.ink,
              width: selected ? 5 : 3,
            ),
            boxShadow: [
              if (selected)
                const BoxShadow(
                  color: Color(0x99ffd45b),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              const BoxShadow(color: SkyColors.ink, offset: Offset(0, 5)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(selected ? 19 : 21),
            child: LayoutBuilder(
              builder: (context, box) {
                final strip = math.min(40.0, box.maxHeight * .3);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                _birdColors[bird],
                                SkyColors.white,
                                .35,
                              )!,
                              _birdColors[bird],
                            ],
                          ),
                        ),
                      ),
                    ),
                    // A head-and-shoulders crop: the art runs off the
                    // bottom, under the name strip.
                    Positioned(
                      left: box.maxWidth * .1,
                      top: 6,
                      child: ColorFiltered(
                        colorFilter: unlocked
                            ? const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.dst,
                              )
                            : const ColorFilter.matrix([
                                .5, .3, .1, 0, 20, //
                                .2, .5, .1, 0, 20,
                                .2, .3, .4, 0, 30,
                                0, 0, 0, 1, 0,
                              ]),
                        child: BirdArt(
                          bird: bird,
                          size: box.maxWidth * 1.05,
                          bob: false,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: strip,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: SkyColors.cream,
                          border: Border(
                            top: BorderSide(color: SkyColors.ink, width: 3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            birdNames[bird],
                            style: heading(
                              22,
                              weight: FontWeight.w700,
                            ).copyWith(height: 1),
                          ),
                        ),
                      ),
                    ),
                    if (equipped)
                      const Positioned(
                        left: 8,
                        top: 8,
                        child: _Badge(
                          icon: Icons.check_rounded,
                          text: 'FLYING',
                          color: SkyColors.teal,
                          ink: SkyColors.white,
                        ),
                      )
                    else if (unlocked && !flown)
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: _Badge(
                          text: 'NEW',
                          color: SkyColors.coral,
                          ink: SkyColors.white,
                        ),
                      )
                    else if (flown)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: SkyColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SkyColors.ink,
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: SkyColors.teal,
                          ),
                        ),
                      ),
                    if (!unlocked)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: strip + 10,
                        child: Center(
                          child: _PriceTag(
                            price: price,
                            affordable: affordable,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    required this.ink,
    this.icon,
  });
  final String text;
  final Color color, ink;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 3, 10, 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SkyColors.ink, width: 2.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: ink),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: bodyText(
            13,
            color: ink,
            weight: FontWeight.w900,
          ).copyWith(letterSpacing: .8, height: 1),
        ),
      ],
    ),
  );
}

/// A locked tile's lock and price: yellow when the wallet can pay, grey
/// when not yet.
class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.price, required this.affordable});
  final int price;
  final bool affordable;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
    decoration: BoxDecoration(
      color: affordable ? SkyColors.yellow : _lockedFace,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: affordable ? SkyColors.ink : _locked,
        width: 2.5,
      ),
      boxShadow: [
        BoxShadow(
          color: affordable ? SkyColors.ink : _lockedLip,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_rounded,
          size: 18,
          color: affordable ? SkyColors.ink : _locked,
        ),
        const SizedBox(width: 4),
        const MatchIcon(MatchSymbol.star, size: 22),
        const SizedBox(width: 3),
        Text(
          '$price',
          style: heading(
            19,
            color: affordable ? SkyColors.ink : _locked,
            weight: FontWeight.w700,
          ).copyWith(height: 1),
        ),
      ],
    ),
  );
}
