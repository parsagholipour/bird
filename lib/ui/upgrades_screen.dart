import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../domain/power_ups.dart';
import 'components.dart';
import 'home_keys.dart' show HomeKey, HomeKeyColors;
import 'match_hud.dart' show MatchIcon, MatchSymbol;
import 'mini_chrome.dart';
import 'theme.dart';

/// The hangar: the equipped bird on its perch with the four upgrades
/// ([PowerUp]) as gear sockets around it. Tapping a socket opens its
/// callout, which explains it and buys its next level with collected stars.
class UpgradesScreen extends ConsumerStatefulWidget {
  const UpgradesScreen({super.key});

  @override
  ConsumerState<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends ConsumerState<UpgradesScreen> {
  PowerUp? _selected;
  bool _busy = false;

  /// The socket open on arrival: the first upgrade the wallet can pay for,
  /// else the first that is not maxed.
  static PowerUp _firstPick(ProgressSnapshot p) =>
      PowerUp.values.where(p.canBuy).firstOrNull ??
      PowerUp.values
          .where((u) => PowerUp.costFrom(p.upgrades[u]) != null)
          .firstOrNull ??
      PowerUp.shot;

  Future<void> _buy(PowerUp up) async {
    setState(() => _busy = true);
    try {
      await ref.read(progressProvider.notifier).buyUpgrade(up);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider).asData?.value;
    final selected = p == null ? null : _selected ??= _firstPick(p);
    return Scaffold(
      body: SkyBackdrop(
        child: SceneLayout(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
            child: p == null || selected == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MiniHeader(
                        title: 'Power up your bird.',
                        size: 34,
                        onBack: () => context.go('/'),
                        trailing: [_Wallet(stars: p.starWallet)],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 64),
                        child: Text(
                          'Tap a gear to see what it does. Every star you pick up in flight is one to spend.',
                          style: bodyText(15, weight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _Hangar(
                                progress: p,
                                selected: selected,
                                onSelect: (up) =>
                                    setState(() => _selected = up),
                              ),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: 400,
                              child: _Callout(
                                power: selected,
                                progress: p,
                                busy: _busy,
                                onBuy: () => _buy(selected),
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

Color _colorOf(PowerUp p) => switch (p) {
  PowerUp.shot => SkyColors.coral,
  PowerUp.sprint => SkyColors.yellow,
  PowerUp.shield => SkyColors.teal,
  PowerUp.magnet => SkyColors.purple,
};

MatchSymbol _symbolOf(PowerUp p) => switch (p) {
  PowerUp.shot => MatchSymbol.shot,
  PowerUp.sprint => MatchSymbol.sprint,
  PowerUp.shield => MatchSymbol.shield,
  PowerUp.magnet => MatchSymbol.magnet,
};

/// Greyed ink for what the wallet cannot pay for yet.
const _locked = Color(0xff6d8086), _lockedFace = Color(0xffefe7d6);
const _lockedLip = Color(0xff9fb0b4);

/// The stars to spend, in the gold pill every screen shows them in.
class _Wallet extends StatelessWidget {
  const _Wallet({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars stars to spend',
    excludeSemantics: true,
    child: Container(
      key: const ValueKey('star-wallet'),
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

/// The bird on its perch between two columns of sockets, each tied to it by
/// a dotted line.
class _Hangar extends StatelessWidget {
  const _Hangar({
    required this.progress,
    required this.selected,
    required this.onSelect,
  });
  final ProgressSnapshot progress;
  final PowerUp selected;
  final ValueChanged<PowerUp> onSelect;

  Widget _socket(PowerUp up) => _Socket(
    power: up,
    level: progress.upgrades[up],
    affordable: progress.canBuy(up),
    selected: up == selected,
    onTap: () => onSelect(up),
  );

  @override
  Widget build(BuildContext context) {
    final bird = progress.settings.bird;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: SkyColors.white.withValues(alpha: .22),
        border: Border.all(
          color: SkyColors.ink.withValues(alpha: .16),
          width: 2.5,
        ),
      ),
      child: CustomPaint(
        painter: const _Links(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [_socket(PowerUp.shot), _socket(PowerUp.sprint)],
              ),
              Expanded(
                child: _Perch(
                  bird: bird,
                  reducedMotion: progress.settings.reducedMotion,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [_socket(PowerUp.shield), _socket(PowerUp.magnet)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faint dotted lines from each socket to the bird.
class _Links extends CustomPainter {
  const _Links();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SkyColors.ink.withValues(alpha: .22)
      ..style = PaintingStyle.fill;
    Offset at(double x, double y) => Offset(size.width * x, size.height * y);
    for (final (from, bend, to) in [
      (at(.22, .27), at(.36, .30), at(.40, .52)),
      (at(.22, .75), at(.36, .73), at(.41, .64)),
      (at(.78, .27), at(.64, .30), at(.60, .52)),
      (at(.78, .75), at(.64, .73), at(.59, .64)),
    ]) {
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(bend.dx, bend.dy, to.dx, to.dy);
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 9) {
          final dot = metric.getTangentForOffset(d)!.position;
          canvas.drawCircle(dot, 1.6, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Links oldDelegate) => false;
}

/// The equipped bird standing on a cream perch, its name on a plate.
class _Perch extends StatelessWidget {
  const _Perch({required this.bird, required this.reducedMotion});
  final int bird;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = math.min(box.maxWidth * .92, 250.0);
      final art = math.min(width * .95, box.maxHeight - 70);
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The perch: a cream disc on a darker rim.
          Positioned(
            bottom: 24,
            child: Container(
              width: width,
              height: 52,
              decoration: BoxDecoration(
                color: SkyColors.cream,
                borderRadius: BorderRadius.all(Radius.elliptical(width, 52)),
                border: Border.all(color: SkyColors.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0xffe8d9b8), offset: Offset(0, 8)),
                  BoxShadow(
                    color: SkyColors.ink,
                    offset: Offset(0, 8),
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 44,
            child: BirdArt(bird: bird, size: art, reducedMotion: reducedMotion),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
              decoration: BoxDecoration(
                color: SkyColors.ink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                birdNames[bird],
                style: heading(
                  17,
                  color: SkyColors.white,
                  weight: FontWeight.w700,
                ).copyWith(height: 1),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// One upgrade's gear socket: its symbol on a core of its color inside a
/// four-segment level ring, its name, and a price tag that says at a glance
/// whether the wallet can pay (yellow), cannot yet (grey, locked) or it is
/// maxed (mint).
class _Socket extends StatelessWidget {
  const _Socket({
    required this.power,
    required this.level,
    required this.affordable,
    required this.selected,
    required this.onTap,
  });
  final PowerUp power;
  final int level;
  final bool affordable, selected;
  final VoidCallback onTap;

  static const _size = 82.0;

  @override
  Widget build(BuildContext context) {
    final cost = PowerUp.costFrom(level);
    final color = _colorOf(power);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${power.title}, level $level of ${PowerUp.maxLevel}. '
          '${cost == null
              ? 'Maxed'
              : affordable
              ? 'Next level $cost stars'
              : 'Next level $cost stars, not enough yet'}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('upgrade-card-${power.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 130,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: _size + 12,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (selected)
                      Container(
                        width: _size + 14,
                        height: _size + 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SkyColors.yellow.withValues(alpha: .6),
                          border: Border.all(color: SkyColors.ink, width: 3),
                        ),
                      ),
                    CustomPaint(
                      size: const Size.square(_size),
                      painter: _LevelRing(level: level, color: color),
                    ),
                    Container(
                      width: _size - 26,
                      height: _size - 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(color: SkyColors.ink, width: 3),
                        boxShadow: const [
                          BoxShadow(color: SkyColors.ink, offset: Offset(0, 3)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: MatchIcon(_symbolOf(power), size: 34),
                    ),
                    Positioned(
                      right: 0,
                      top: 2,
                      child: _Chip(
                        '$level/${PowerUp.maxLevel}',
                        color: SkyColors.white,
                      ),
                    ),
                    // A coral dot calls out what the wallet can buy now.
                    if (affordable && !selected)
                      Positioned(
                        left: 8,
                        top: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SkyColors.coral,
                            border: Border.all(
                              color: SkyColors.ink,
                              width: 2.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '!',
                            style: heading(
                              14,
                              color: SkyColors.white,
                              weight: FontWeight.w700,
                            ).copyWith(height: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 1, 10, 3),
                decoration: BoxDecoration(
                  color: selected ? SkyColors.ink : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  power.title,
                  maxLines: 1,
                  style: heading(
                    18,
                    color: selected ? SkyColors.white : SkyColors.ink,
                    weight: FontWeight.w600,
                  ).copyWith(height: 1.1),
                ),
              ),
              const SizedBox(height: 4),
              _PriceTag(cost: cost, affordable: affordable),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four ring segments, one per level, filled in the upgrade's color as
/// they are bought.
class _LevelRing extends CustomPainter {
  const _LevelRing({required this.level, required this.color});
  final int level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6.5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = SkyColors.ink,
    );
    const n = PowerUp.maxLevel, gap = .14;
    final segment = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    for (var i = 0; i < n; i++) {
      final start = -math.pi / 2 + gap / 2 + i * 2 * math.pi / n;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        2 * math.pi / n - gap,
        false,
        segment..color = i < level ? color : SkyColors.cream,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelRing oldDelegate) =>
      level != oldDelegate.level || color != oldDelegate.color;
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: SkyColors.ink, width: 2.5),
    ),
    child: Text(
      text,
      style: bodyText(15, weight: FontWeight.w900).copyWith(height: 1),
    ),
  );
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.cost, required this.affordable});
  final int? cost;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final maxed = cost == null;
    final ink = maxed || affordable ? SkyColors.ink : _locked;
    return Container(
      height: 32,
      padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
      decoration: BoxDecoration(
        color: maxed
            ? SkyColors.mint
            : affordable
            ? SkyColors.yellow
            : _lockedFace,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: maxed || affordable ? SkyColors.ink : _lockedLip,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (maxed)
            const Icon(Icons.check_rounded, size: 20, color: SkyColors.ink)
          else if (affordable)
            const MatchIcon(MatchSymbol.star, size: 22)
          else
            const Icon(Icons.lock_rounded, size: 17, color: _locked),
          const SizedBox(width: 4),
          Text(
            maxed ? 'MAX' : '$cost',
            style: heading(
              18,
              color: ink,
              weight: FontWeight.w700,
            ).copyWith(height: 1),
          ),
        ],
      ),
    );
  }
}

/// The open socket's speech bubble: what the upgrade does, what the next
/// level changes, how far the wallet is from it, and the key that buys it.
class _Callout extends StatelessWidget {
  const _Callout({
    required this.power,
    required this.progress,
    required this.busy,
    required this.onBuy,
  });
  final PowerUp power;
  final ProgressSnapshot progress;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final up = power, p = progress;
    final level = p.upgrades[up];
    final cost = PowerUp.costFrom(level);
    final stats = up.stats(level);
    final next = cost == null ? null : up.stats(level + 1);
    final affordable = p.canBuy(up);
    // The tail points at the open socket: top or bottom row.
    final top = up == PowerUp.shot || up == PowerUp.shield;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              key: const ValueKey('upgrade-callout'),
              decoration: BoxDecoration(
                color: SkyColors.cream,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: SkyColors.ink, width: 3),
                boxShadow: [
                  const BoxShadow(color: SkyColors.ink, offset: Offset(0, 6)),
                  BoxShadow(
                    color: SkyColors.ink.withValues(alpha: .18),
                    offset: const Offset(0, 14),
                    blurRadius: 20,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CalloutHead(power: up, level: level),
                  const SizedBox(height: 8),
                  Text(
                    up.blurb,
                    style: bodyText(
                      16,
                      weight: FontWeight.w800,
                    ).copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  // On a short screen the rows shrink a little instead of
                  // hiding behind a scroll.
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: box.maxWidth - 42,
                          child: Column(
                            children: [
                              for (final (i, (label, value)) in stats.indexed)
                                _StatRow(
                                  label: label,
                                  now: value,
                                  next: next?[i].$2,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (cost == null)
                    const _Maxed()
                  else ...[
                    _Progress(cost: cost, wallet: p.starWallet),
                    const SizedBox(height: 8),
                    _UpgradeKey(
                      key: ValueKey('buy-${up.name}'),
                      cost: cost,
                      enabled: affordable && !busy,
                      busy: busy,
                      onPressed: onBuy,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: -22,
            top: top ? 46 : box.maxHeight - 150,
            child: const CustomPaint(size: Size(26, 36), painter: _Tail()),
          ),
        ],
      ),
    );
  }
}

/// The bubble's tail, pointing left at the open socket.
class _Tail extends CustomPainter {
  const _Tail();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Path()
      ..moveTo(w + 4, 0)
      ..lineTo(0, h / 2)
      ..lineTo(w + 4, h)
      ..close();
    canvas.drawPath(fill, Paint()..color = SkyColors.cream);
    canvas.drawPath(
      Path()
        ..moveTo(w + 1, 0)
        ..lineTo(0, h / 2)
        ..lineTo(w + 1, h),
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Tail oldDelegate) => false;
}

class _CalloutHead extends StatelessWidget {
  const _CalloutHead({required this.power, required this.level});
  final PowerUp power;
  final int level;

  @override
  Widget build(BuildContext context) {
    final maxed = level >= PowerUp.maxLevel;
    final color = _colorOf(power);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: SkyColors.ink, width: 3),
          ),
          alignment: Alignment.center,
          child: MatchIcon(_symbolOf(power), size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                power.title,
                style: heading(27, weight: FontWeight.w700).copyWith(height: 1),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    maxed ? 'Level $level, the top' : 'Level $level',
                    style: bodyText(
                      15,
                      color: SkyColors.muted,
                      weight: FontWeight.w800,
                    ),
                  ),
                  if (!maxed) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: SkyColors.muted,
                      ),
                    ),
                    Text(
                      '${level + 1}',
                      style: bodyText(
                        15,
                        color: SkyColors.muted,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              for (var i = 0; i < PowerUp.maxLevel; i++)
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(left: 5),
                  decoration: BoxDecoration(
                    color: i < level
                        ? color
                        : i == level
                        ? color.withValues(alpha: .3)
                        : SkyColors.white,
                    border: Border.all(color: SkyColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One stat in a white row: its label, today's value and, in teal, the next
/// level's.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.now, this.next});
  final String label, now;
  final String? next;

  @override
  Widget build(BuildContext context) {
    final upgrade = next != null && next != now;
    return Semantics(
      label: upgrade ? '$label $now, next level $next' : '$label $now',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
        decoration: BoxDecoration(
          color: SkyColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe6dcc6), width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: bodyText(
                  16,
                  color: SkyColors.muted,
                  weight: FontWeight.w800,
                ).copyWith(height: 1.1),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              now,
              style: bodyText(
                upgrade ? 17 : 21,
                color: upgrade ? _locked : SkyColors.ink,
                weight: FontWeight.w900,
              ),
            ),
            if (upgrade) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: SkyColors.teal,
                ),
              ),
              Text(
                next!,
                style: heading(
                  20,
                  color: const Color(0xff2f8f7d),
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// How the wallet stands against the price: a bar and what is still
/// missing, or what will be left after buying.
class _Progress extends StatelessWidget {
  const _Progress({required this.cost, required this.wallet});
  final int cost;
  final int wallet;

  @override
  Widget build(BuildContext context) {
    final style = bodyText(15, color: SkyColors.muted, weight: FontWeight.w800);
    if (wallet >= cost) {
      return Text(
        'You will have ${wallet - cost} stars left.',
        style: style,
        textAlign: TextAlign.center,
      );
    }
    return Row(
      children: [
        Text('$wallet / $cost', style: style),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: SkyColors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: SkyColors.ink, width: 2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (wallet / cost).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: SkyColors.yellow,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${cost - wallet} more to go', style: style),
      ],
    );
  }
}

/// "Upgrade" with the price on a chip; greyed with a lock until the wallet
/// can pay.
class _UpgradeKey extends StatelessWidget {
  const _UpgradeKey({
    super.key,
    required this.cost,
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });
  final int cost;
  final bool enabled, busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = enabled || busy ? SkyColors.ink : _locked;
    final face = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!enabled && !busy) ...[
          const Icon(Icons.lock_rounded, size: 22, color: _locked),
          const SizedBox(width: 8),
        ],
        Text(
          'Upgrade',
          style: heading(
            24,
            color: ink,
            weight: FontWeight.w700,
          ).copyWith(height: 1),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(6, 3, 12, 3),
          decoration: BoxDecoration(
            color: SkyColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: enabled || busy ? SkyColors.ink : _lockedLip,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: SkyColors.ink,
                  ),
                )
              else
                const MatchIcon(MatchSymbol.star, size: 24),
              const SizedBox(width: 4),
              Text(
                '$cost',
                style: heading(
                  21,
                  color: ink,
                  weight: FontWeight.w700,
                ).copyWith(height: 1),
              ),
            ],
          ),
        ),
      ],
    );
    return SizedBox(
      height: 56,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: enabled
            ? 'Upgrade for $cost stars'
            : 'Upgrade for $cost stars, not enough stars yet',
        excludeSemantics: true,
        child: enabled
            ? HomeKey(
                label: 'Upgrade',
                colors: HomeKeyColors.sun,
                lip: 6,
                radius: 22,
                onPressed: onPressed,
                builder: (context, _) => face,
              )
            : Container(
                decoration: BoxDecoration(
                  color: _lockedFace,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _locked, width: 3),
                  boxShadow: const [
                    BoxShadow(color: _lockedLip, offset: Offset(0, 6)),
                  ],
                ),
                child: face,
              ),
      ),
    );
  }
}

/// Where a maxed upgrade's key would be.
class _Maxed extends StatelessWidget {
  const _Maxed();

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    decoration: BoxDecoration(
      color: SkyColors.mint,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: SkyColors.ink, width: 3),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, size: 24, color: SkyColors.ink),
        const SizedBox(width: 8),
        Text('Maxed out', style: heading(22, weight: FontWeight.w700)),
      ],
    ),
  );
}
