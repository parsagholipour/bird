import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../domain/sky_boss.dart' show BossKind;
import '../game/regions/world_region.dart';
import 'campaign_chrome.dart';
import 'campaign_keepsake_art.dart' show CampaignHeadwear;
import 'campaign_map_art.dart';
import 'campaign_text_scale.dart';
import 'components.dart';
import 'keyboard.dart' show KeyTap;
import 'theme.dart';
import 'ui_sounds.dart';

/// Where a level stands on the map.
enum CampaignNodeState { locked, open, cleared }

/// One level on the map, as the screen hands it over: the map only draws it.
class CampaignMapNode {
  const CampaignMapNode({
    required this.id,
    required this.name,
    this.state = CampaignNodeState.locked,
    this.stars = 0,
    this.isCurrent = false,
    this.boss,
    this.guardian = false,
    this.lockNote,
  });

  /// The label on the node, such as "1-3".
  final String id;
  final String name;
  final CampaignNodeState state;

  /// Best star rating, 0 to 3.
  final int stars;

  /// The level the courier is on: the bird perches here.
  final bool isCurrent;

  /// The boss this level ends in: the lair of a chapter's last level, or,
  /// with [guardian], the mini-boss that guards an earlier one.
  final BossKind? boss;

  /// Whether [boss] is a guardian: a campaign-only mini-boss that guards its
  /// level, not the boss of its chapter. A guardian's node is a shield, not a
  /// lair, and carries its name on a plaque.
  final bool guardian;

  /// What unlocks a locked level, such as "Beat King Coo to unlock", which a
  /// screen reader says after "Locked." (the node's picture shows a padlock
  /// and nothing else). Null when the level is not in this build.
  final String? lockNote;

  /// A chapter's lair: the big node with the boss's crown on it.
  bool get isBoss => boss != null && !guardian;

  /// A guardian's shield node.
  bool get isGuardian => boss != null && guardian;
  bool get locked => state == CampaignNodeState.locked;
}

/// One region on the trip, with its levels in flying order.
class CampaignMapStop {
  const CampaignMapStop({
    required this.region,
    required this.chapter,
    required this.route,
    required this.nodes,
    this.locked = false,
    this.comingSoon = false,
    this.postcard = false,
    this.soonNote = 'Coming soon',
  });
  final WorldRegion region;

  /// The chapter this region belongs to, 1 to 5, and its route's name.
  final int chapter;
  final String route;
  final List<CampaignMapNode> nodes;

  /// No level here is open yet: the scenery waits under cloud.
  final bool locked;

  /// The region is not in this build yet.
  final bool comingSoon;

  /// What the ribbon across a [comingSoon] stop says. A stop in a chapter the
  /// build has partly opened names itself ("Paris — coming soon") so the
  /// ribbon reads as the answer to the stop before it.
  final String soonNote;

  /// This stop ends a beaten chapter, so its postcard waits on the route.
  final bool postcard;

  String get title => region.title;
}

/// A stop narrower than this (in layout units) sets a guardian's long name
/// short on its plaque.
const _compactBelow = 560.0;

/// The campaign world map: one stop per region, painted with that region's
/// own scenery, joined by a dotted mail route that runs from stop to stop.
/// It swipes a stop at a time and opens on [focusStop].
///
/// Purely presentational: the screen supplies the stops and reacts to taps.
/// With [reducedMotion] nothing bobs, glows, pulses or glides; changing
/// [focusStop] jumps there instead of scrolling.
class CampaignMap extends StatefulWidget {
  const CampaignMap({
    super.key,
    required this.stops,
    required this.bird,
    required this.onLevel,
    this.onLockedLevel,
    this.onPostcard,
    this.reducedMotion = false,
    this.focusStop,
    this.leading,
    this.trailing,
    this.chromeHidden = false,
  });
  final List<CampaignMapStop> stops;

  /// The equipped bird, which perches on the current level.
  final int bird;
  final bool reducedMotion;

  /// The stop to show; the stop of the current level when null.
  final int? focusStop;

  /// An open level was tapped, with its id.
  final ValueChanged<String> onLevel;

  /// A locked level was tapped: the node wiggles and the screen may nudge.
  final ValueChanged<String>? onLockedLevel;

  /// A chapter's postcard was tapped, with the chapter number.
  final ValueChanged<int>? onPostcard;

  /// Fixed chrome over the map's top corners, such as a back key and the
  /// star total. They stay put while the stops slide by.
  final Widget? leading, trailing;

  /// Hides the chrome (the leading and trailing widgets, the step keys and
  /// each stop's ribbon and name), for a card laid over the map: cream keys
  /// would glow brighter than the dimmed scenery under the scrim and crowd
  /// the card's corners, and a ribbon half behind the card looks cut off.
  final bool chromeHidden;

  /// The stop holding the current level, or the first stop.
  static int currentStopOf(List<CampaignMapStop> stops) {
    final i = stops.indexWhere((s) => s.nodes.any((n) => n.isCurrent));
    return math.max(0, i);
  }

  @override
  State<CampaignMap> createState() => _CampaignMapState();
}

class _CampaignMapState extends State<CampaignMap>
    with SingleTickerProviderStateMixin {
  final clock = ValueNotifier<double>(0);

  /// Counts taps on locked levels of a coming-soon stop, which its ribbon
  /// answers.
  final soonPoke = ValueNotifier<int>(0);
  late final Ticker ticker = createTicker(
    (elapsed) =>
        clock.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond,
  );
  ScrollController? controller;
  late int page = _focus;

  /// The size of one stop (the whole view) and the screen's pixel ratio.
  Size _page = Size.zero;
  double _pixelRatio = 1;
  _MapLayout? _layout;

  int get _focus =>
      (widget.focusStop ?? CampaignMap.currentStopOf(widget.stops)).clamp(
        0,
        math.max(0, widget.stops.length - 1),
      );

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.reducedMotion) {
      ticker.stop();
      clock.value = 0;
    } else if (!ticker.isActive) {
      ticker.start();
    }
  }

  @override
  void didUpdateWidget(CampaignMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
    if (!identical(oldWidget.stops, widget.stops)) _layout = null;
    final oldFocus =
        oldWidget.focusStop ?? CampaignMap.currentStopOf(oldWidget.stops);
    if (_focus != oldFocus) _goTo(_focus);
  }

  @override
  void dispose() {
    ticker.dispose();
    controller?.dispose();
    clock.dispose();
    soonPoke.dispose();
    super.dispose();
  }

  void _goTo(int stop) {
    if (widget.stops.isEmpty) return;
    page = stop.clamp(0, widget.stops.length - 1);
    final c = controller;
    if (c != null && c.hasClients && _page.width > 0) {
      final target = page * _page.width;
      if (widget.reducedMotion) {
        c.jumpTo(target);
      } else {
        c.animateTo(
          target,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubic,
        );
      }
    }
    setState(() {});
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollEndNotification && _page.width > 0) {
      final settled = (n.metrics.pixels / _page.width).round();
      if (settled != page) setState(() => page = settled);
      _prewarm();
    }
    return false;
  }

  /// Paints the neighbours' stills one per frame once the map has settled,
  /// so the next swipe finds them ready instead of painting a region
  /// mid-gesture.
  void _prewarm() {
    final queue = [page + 1, page - 1];
    void next(Duration _) {
      if (!mounted || queue.isEmpty || _page.isEmpty) return;
      final i = queue.removeAt(0);
      if (i >= 0 && i < widget.stops.length) {
        MapSceneryPainter.still(
          widget.stops[i].region,
          _page,
          _pixelRatio,
          first: i == 0,
        );
      }
      if (queue.isNotEmpty) {
        WidgetsBinding.instance
          ..addPostFrameCallback(next)
          ..scheduleFrame();
      }
    }

    WidgetsBinding.instance
      ..addPostFrameCallback(next)
      ..scheduleFrame();
  }

  /// Follows a new view size (a rotation, a resize) or pixel ratio, keeping
  /// the same stop in view.
  void _resize(Size size, double ratio) {
    final first = controller == null;
    _page = size;
    _pixelRatio = ratio;
    _layout = null;
    controller ??= ScrollController(initialScrollOffset: page * size.width);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!first && controller!.hasClients) {
        controller!.jumpTo(page * _page.width);
      }
      _prewarm();
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (widget.stops.isEmpty) return const SizedBox.expand();
      final size = box.biggest;
      final safe = MediaQuery.paddingOf(context);
      final ratio = MediaQuery.devicePixelRatioOf(context);
      if (size != _page || ratio != _pixelRatio) _resize(size, ratio);
      // Levels, banners and the bird are composed for a 360-high phone and
      // grow a little on taller screens, so they keep their weight against
      // the scenery.
      final k = (size.height / 360).clamp(1.0, 1.25);
      var layout = _layout;
      if (layout == null || layout.safe != safe / k) {
        layout = _layout = _MapLayout(widget.stops, size / k, safe / k);
      }
      final still = widget.reducedMotion;
      final n = widget.stops.length;
      return Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const PageScrollPhysics(),
              child: SizedBox(
                width: n * size.width,
                height: size.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: MapSceneryPainter(
                            regions: [for (final s in widget.stops) s.region],
                            dims: [
                              for (final s in widget.stops)
                                s.locked ? 1.0 : 0.0,
                            ],
                            page: size,
                            pixelRatio: ratio,
                            scroll: controller!,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: MapCloudPainter(
                            page: size,
                            stops: n,
                            veils: [
                              for (final s in widget.stops)
                                s.locked ? 1.0 : 0.0,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: MapRoutePainter(layout.dots, scale: k),
                        ),
                      ),
                    ),
                    for (var i = 0; i < n; i++)
                      Positioned(
                        key: ValueKey('campaign-stop-$i'),
                        left: i * size.width,
                        top: 0,
                        width: size.width,
                        height: size.height,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          alignment: Alignment.topLeft,
                          child: SizedBox.fromSize(
                            size: size / k,
                            child: _StopLayer(
                              stop: widget.stops[i],
                              spots: layout.spots[i],
                              safe: safe / k,
                              bird: widget.bird,
                              clock: clock,
                              still: still,
                              bannerHidden: widget.chromeHidden,
                              compactNames: size.width / k < _compactBelow,
                              soonPoke: soonPoke,
                              onLevel: widget.onLevel,
                              onLockedLevel: widget.onLockedLevel,
                              onPostcard: widget.onPostcard,
                              // Enter flies on from the level in view; the
                              // map turns to wherever the keys go.
                              focusNext: i == page && !widget.chromeHidden,
                              onFocused: () {
                                if (i != page) _goTo(i);
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: !widget.chromeHidden,
            maintainState: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.leading != null)
                  Positioned(
                    left: safe.left + 16,
                    top: safe.top + 12,
                    child: widget.leading!,
                  ),
                if (widget.trailing != null)
                  Positioned(
                    right: safe.right + 16,
                    top: safe.top + 12,
                    child: widget.trailing!,
                  ),
                // The step keys sit on the cloud banks in the bottom corners,
                // clear of the levels, in the same sticker material as the
                // back key.
                if (page > 0)
                  Positioned(
                    left: safe.left + 16,
                    bottom: safe.bottom + 14,
                    child: MapKey(
                      glyph: MapGlyph.previous,
                      label: 'Previous stop',
                      reducedMotion: still,
                      onPressed: () => _goTo(page - 1),
                    ),
                  ),
                if (page < n - 1)
                  Positioned(
                    right: safe.right + 16,
                    bottom: safe.bottom + 14,
                    child: MapKey(
                      glyph: MapGlyph.next,
                      label: 'Next stop',
                      reducedMotion: still,
                      onPressed: () => _goTo(page + 1),
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

/// Node spots, route dots and everything else that depends on the stop size.
class _MapLayout {
  _MapLayout(this.stops, this.page, this.safe) {
    final w = page.width, h = page.height;
    final left = safe.left + 84.0, right = w - safe.right - 84.0;
    for (final (i, stop) in stops.indexed) {
      // Up to five levels a stop; any more would crowd a phone screen.
      final pattern = _patterns[stop.nodes.length.clamp(1, 5)]!;
      spots.add([
        for (final (j, (fx, fy)) in pattern.take(stop.nodes.length).indexed)
          if (stop.nodes[j].isGuardian)
            // A guardian's plaque, which is wider than its shield, keeps
            // inside the stop.
            Offset(
              (left + (right - left) * fx).clamp(
                safe.left + _guardianRoom,
                w - safe.right - _guardianRoom,
              ),
              h * (i.isOdd ? _flip(fy) : fy),
            )
          else if (stop.nodes[j].isBoss)
            // A lair keeps room for its name ribbon inside the stop.
            Offset(
              math.min(left + (right - left) * fx, w - safe.right - 116),
              h * (i.isOdd ? _flip(fy) : fy) - h * .03,
            )
          else
            Offset(left + (right - left) * fx, h * (i.isOdd ? _flip(fy) : fy)),
      ]);
    }
    _route();
  }

  final List<CampaignMapStop> stops;
  final Size page;
  final EdgeInsets safe;
  final spots = <List<Offset>>[];
  final dots = <RouteDot>[];

  /// How far a guardian's node keeps from the stop's sides: room for its
  /// plaque, at the longest name.
  static const _guardianRoom = 108.0;

  /// Height of the route where it crosses from one stop into the next.
  static const _seamY = .6;

  static double _flip(double y) => 2 * _seamY - y;

  /// Where a stop's levels sit, by count: x across the stop's safe width,
  /// y down its height. Odd stops mirror the zigzag so the trip weaves.
  static const _patterns = {
    1: [(.5, .6)],
    2: [(.26, .67), (.74, .52)],
    3: [(.1, .67), (.5, .51), (.9, .64)],
    4: [(.02, .65), (.34, .5), (.66, .69), (.98, .53)],
    5: [(0, .63), (.25, .49), (.5, .69), (.75, .5), (1, .65)],
  };

  void _route() {
    final points = <Offset>[];
    final nodeAt = <int>[]; // index into points, per node, flattened
    final current = <int>[];
    final lockedStop = <bool>[];
    for (final (i, stop) in stops.indexed) {
      if (i > 0) {
        points.add(Offset(i * page.width, page.height * _seamY));
        lockedStop.add(stop.locked || stops[i - 1].locked);
      }
      for (final (j, spot) in spots[i].indexed) {
        nodeAt.add(points.length);
        if (stop.nodes[j].isCurrent) current.add(points.length);
        points.add(spot + Offset(i * page.width, 0));
        lockedStop.add(stop.locked);
      }
    }
    if (points.length < 2) return;
    // The flown stretch runs to the current level, or to the last cleared
    // one when nothing is marked current.
    var reached = current.isNotEmpty ? current.first : -1;
    if (reached < 0) {
      var k = 0;
      for (final stop in stops) {
        for (final node in stop.nodes) {
          if (node.state == CampaignNodeState.cleared) reached = nodeAt[k];
          k++;
        }
      }
    }
    final centers = [for (final i in nodeAt) points[i]];
    const spacing = 14.0;
    var carry = 0.0;
    for (var s = 0; s + 1 < points.length; s++) {
      final p0 = points[math.max(0, s - 1)], p1 = points[s];
      final p2 = points[s + 1], p3 = points[math.min(points.length - 1, s + 2)];
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(
          p1.dx + (p2.dx - p0.dx) / 6,
          p1.dy + (p2.dy - p0.dy) / 6,
          p2.dx - (p3.dx - p1.dx) / 6,
          p2.dy - (p3.dy - p1.dy) / 6,
          p2.dx,
          p2.dy,
        );
      final faint = lockedStop[s + 1];
      final done = s < reached;
      for (final metric in path.computeMetrics()) {
        var d = carry;
        for (; d < metric.length; d += spacing) {
          final at = metric.getTangentForOffset(d)!.position;
          if (centers.any((c) => (c - at).distance < 40)) continue;
          dots.add((at: at, done: done, faint: faint && !done));
        }
        carry = d - metric.length;
      }
    }
  }
}

/// Everything that sits on one stop: its banner, its levels, the bird on the
/// current level, a waiting postcard and, when locked, the padlock.
class _StopLayer extends StatelessWidget {
  const _StopLayer({
    required this.stop,
    required this.spots,
    required this.safe,
    required this.bird,
    required this.clock,
    required this.still,
    required this.bannerHidden,
    required this.compactNames,
    required this.soonPoke,
    required this.onLevel,
    required this.onLockedLevel,
    required this.onPostcard,
    this.focusNext = false,
    this.onFocused,
  });
  final CampaignMapStop stop;
  final List<Offset> spots;
  final EdgeInsets safe;
  final int bird;
  final ValueListenable<double> clock;
  final bool still, bannerHidden;

  /// A narrow stop sets a guardian's long name short on its plaque.
  final bool compactNames;
  final ValueNotifier<int> soonPoke;
  final ValueChanged<String> onLevel;
  final ValueChanged<String>? onLockedLevel;
  final ValueChanged<int>? onPostcard;

  /// Gives the keyboard focus to the stop's next level up, if it has one.
  final bool focusNext;

  /// Called when the keyboard brings the focus to one of the stop's levels
  /// or its postcard, so the map turns to it.
  final VoidCallback? onFocused;

  @override
  Widget build(BuildContext context) {
    final boss = stop.nodes.where((n) => n.isBoss).firstOrNull;
    final bossIndex = boss == null ? -1 : stop.nodes.indexOf(boss);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: safe.left,
          right: safe.right,
          top: safe.top + 8,
          child: Center(
            // A card over the map carries the region's name itself; the
            // ribbon peeking out above it would only be cut off.
            child: Visibility(
              visible: !bannerHidden,
              maintainState: true,
              child: _StopBanner(stop: stop),
            ),
          ),
        ),
        if (stop.comingSoon)
          Positioned(
            left: safe.left,
            right: safe.right,
            bottom: safe.bottom + 16,
            child: Center(
              child: _SoonRibbon(
                poke: soonPoke,
                still: still,
                text: stop.soonNote,
              ),
            ),
          ),
        for (final (j, node) in stop.nodes.indexed)
          if (j < spots.length)
            _NodeSlot(
              node: node,
              center: spots[j],
              bird: bird,
              clock: clock,
              still: still,
              dimmed: stop.locked,
              compactNames: compactNames,
              onLevel: onLevel,
              onLockedLevel: (id) {
                // A coming-soon stop has no message to show but its ribbon,
                // which answers the tap.
                if (stop.comingSoon) soonPoke.value++;
                onLockedLevel?.call(id);
              },
              autofocus: focusNext && node.isCurrent,
              onFocused: onFocused,
            ),
        if (stop.postcard && boss != null && bossIndex < spots.length)
          Positioned(
            left: spots[bossIndex].dx - _NodeSlot.bossRadius - 88,
            top: spots[bossIndex].dy - 86,
            child: _PostcardMarker(
              chapter: stop.chapter,
              boss: boss.boss!,
              clock: clock,
              still: still,
              onTap: onPostcard,
            ),
          ),
      ],
    );
  }
}

/// The stop's chapter ribbon and its region name in sticker lettering.
class _StopBanner extends StatelessWidget {
  const _StopBanner({required this.stop});
  final CampaignMapStop stop;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label:
        '${stop.title}. Chapter ${stop.chapter}, ${stop.route}.'
        '${stop.comingSoon
            ? ' Coming soon.'
            : stop.locked
            ? ' Locked.'
            : ''}',
    excludeSemantics: true,
    child: CampaignTextScale.wrap(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            painter: MapRibbonPainter(
              color: stop.locked ? const Color(0xffb4c4cb) : SkyColors.coral,
              shade: stop.locked
                  ? const Color(0xff8fa3ac)
                  : SkyColors.coralDeep,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 5, 22, 10),
              child: Text(
                'CHAPTER ${stop.chapter} · ${stop.route.toUpperCase()}',
                style: bodyText(
                  12,
                  weight: FontWeight.w900,
                ).copyWith(letterSpacing: .8, height: 1.1),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stop.locked) ...[
                const MapPadlockCoin(),
                const SizedBox(width: 8),
              ],
              _Sticker(stop.title, size: 34),
              if (stop.locked) const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Lettering with a cream halo, an ink outline and a hard drop shadow, like
/// the title on Home, so it reads over any scenery.
class _Sticker extends StatelessWidget {
  const _Sticker(this.text, {required this.size});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = heading(
      size,
      weight: FontWeight.w700,
    ).copyWith(height: 1, letterSpacing: .6);
    Paint stroke(double width, Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..color = color;
    Text layer(TextStyle s) => Text(text, style: s, maxLines: 1);
    return Stack(
      children: [
        layer(
          style.copyWith(
            foreground: stroke(
              size * .24,
              SkyColors.cream.withValues(alpha: .6),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, size * .1),
          child: layer(
            style.copyWith(foreground: stroke(size * .17, SkyColors.ink)),
          ),
        ),
        layer(style.copyWith(foreground: stroke(size * .17, SkyColors.ink))),
        layer(style.copyWith(color: SkyColors.cream)),
      ],
    );
  }
}

/// The ribbon across the clouds of a region that is not in this build yet.
/// Tapping one of its locked levels makes it flutter, since it is the only
/// message that stop has; Reduced Motion leaves it still.
class _SoonRibbon extends StatefulWidget {
  const _SoonRibbon({
    required this.poke,
    required this.still,
    required this.text,
  });
  final ValueListenable<int> poke;
  final bool still;
  final String text;

  @override
  State<_SoonRibbon> createState() => _SoonRibbonState();
}

class _SoonRibbonState extends State<_SoonRibbon>
    with SingleTickerProviderStateMixin {
  late final flutter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void initState() {
    super.initState();
    widget.poke.addListener(_poked);
  }

  @override
  void didUpdateWidget(_SoonRibbon old) {
    super.didUpdateWidget(old);
    if (old.poke != widget.poke) {
      old.poke.removeListener(_poked);
      widget.poke.addListener(_poked);
    }
  }

  @override
  void dispose() {
    widget.poke.removeListener(_poked);
    flutter.dispose();
    super.dispose();
  }

  void _poked() {
    if (!widget.still) flutter.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: flutter,
      child: MapNotice(widget.text),
      builder: (context, child) {
        final t = flutter.value;
        return Transform.rotate(
          angle: -.035 + math.sin(t * math.pi * 4) * (1 - t) * .07,
          child: Transform.scale(
            scale: 1 + math.sin(t * math.pi) * .06,
            child: child,
          ),
        );
      },
    ),
  );
}

/// A level node with its stars, and on the current level the glow and the
/// perched bird. Locked nodes wiggle when tapped.
class _NodeSlot extends StatefulWidget {
  const _NodeSlot({
    required this.node,
    required this.center,
    required this.bird,
    required this.clock,
    required this.still,
    required this.dimmed,
    required this.compactNames,
    required this.onLevel,
    required this.onLockedLevel,
    this.autofocus = false,
    this.onFocused,
  });
  final CampaignMapNode node;
  final Offset center;
  final int bird;
  final ValueListenable<double> clock;
  final bool still, dimmed, compactNames;
  final ValueChanged<String> onLevel;
  final ValueChanged<String>? onLockedLevel;

  /// Takes the keyboard focus, as the next level up on the stop in view
  /// does.
  final bool autofocus;

  /// Called when the keyboard brings the focus to it.
  final VoidCallback? onFocused;

  static const radius = 29.0, bossRadius = 38.0;

  /// A guardian's shield is sized from this coin radius: smaller than the
  /// lair's, about the size of a level coin.
  static const guardianRadius = 29.0;

  @override
  State<_NodeSlot> createState() => _NodeSlotState();
}

class _NodeSlotState extends State<_NodeSlot>
    with SingleTickerProviderStateMixin {
  late final wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool pressed = false;

  @override
  void dispose() {
    wiggle.dispose();
    super.dispose();
  }

  CampaignMapNode get node => widget.node;

  MapNodeLook get look => node.locked
      ? MapNodeLook.locked
      : node.isCurrent
      ? MapNodeLook.current
      : node.state == CampaignNodeState.cleared
      ? MapNodeLook.cleared
      : MapNodeLook.open;

  void _tap() {
    if (node.locked) {
      UiSounds.effect(context, 'ui_back');
      if (!widget.still) wiggle.forward(from: 0);
      widget.onLockedLevel?.call(node.id);
      return;
    }
    UiSounds.effect(context);
    widget.onLevel(node.id);
  }

  String get _semantics {
    final kind = node.isBoss
        ? '${node.id}, ${node.name}, boss'
        : node.isGuardian
        ? 'Level ${node.id}, ${node.name}, guardian '
              '${CampaignHeadwear.name(node.boss!)}'
        : 'Level ${node.id}, ${node.name}';
    if (node.locked) {
      return '$kind. Locked.${node.lockNote == null ? '' : ' ${node.lockNote}.'}';
    }
    final stars = '${node.stars} of 3 stars';
    return node.isCurrent ? '$kind. Next up. $stars.' : '$kind. $stars.';
  }

  @override
  Widget build(BuildContext context) {
    // Levels on a locked stop step back under the clouds.
    final r =
        (node.isBoss
            ? _NodeSlot.bossRadius
            : node.isGuardian
            ? _NodeSlot.guardianRadius
            : _NodeSlot.radius) *
        (widget.dimmed ? .8 : 1);
    // A shield stands taller than a coin of its radius; [reach] is how far
    // the node reaches below its centre.
    final reach = node.isGuardian ? MapGuardianPainter.halfHeight(r) : r;
    final box = reach * 2 + 12;
    // The plaque grows with the text size; the stars hang below it.
    final plaque = _GuardianPlaque.heightFor(CampaignTextScale.of(context));
    final c = widget.center;
    final showStars = !node.locked;
    return Positioned(
      left: c.dx - box / 2,
      top: c.dy - box / 2,
      width: box,
      height: box,
      child: Opacity(
        opacity: widget.dimmed ? .66 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (node.isCurrent)
              Positioned(
                left: -r * .9,
                top: -r * .9,
                right: -r * .9,
                bottom: -r * .9,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: MapGlowPainter(widget.clock, still: widget.still),
                  ),
                ),
              ),
            Semantics(
              button: true,
              enabled: !node.locked,
              label: _semantics,
              onTap: _tap,
              excludeSemantics: true,
              // A keyboard walks the open levels; a locked one only answers
              // a tap.
              child: KeyTap(
                onPressed: node.locked ? null : _tap,
                spread: 2,
                autofocus: widget.autofocus,
                onFocused: widget.onFocused,
                child: GestureDetector(
                  key: ValueKey('campaign-node-${node.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _tap,
                  onTapDown: (_) => setState(() => pressed = true),
                  onTapUp: (_) => setState(() => pressed = false),
                  onTapCancel: () => setState(() => pressed = false),
                  child: AnimatedBuilder(
                    animation: wiggle,
                    builder: (context, child) => Transform.rotate(
                      angle:
                          math.sin(wiggle.value * math.pi * 5) *
                          (1 - wiggle.value) *
                          .22,
                      child: child,
                    ),
                    child: SizedBox.square(
                      dimension: box,
                      child: Center(
                        child: SizedBox(
                          width:
                              (node.isGuardian
                                      ? MapGuardianPainter.halfWidth(r)
                                      : r) *
                                  2 +
                              4,
                          height: reach * 2 + MapNodePainter.depth + 4,
                          child: CustomPaint(
                            painter: node.isGuardian
                                ? MapGuardianPainter(
                                    look: look,
                                    radius: r,
                                    boss: node.boss!,
                                    pressed: pressed && !node.locked,
                                  )
                                : MapNodePainter(
                                    look: look,
                                    radius: r,
                                    boss: node.boss,
                                    pressed: pressed && !node.locked,
                                  ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MapNodePainter.depth +
                                    (pressed && !node.locked ? -4 : 0),
                              ),
                              child: Center(child: _face(r)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (showStars)
              Positioned(
                top:
                    box / 2 +
                    reach +
                    (node.isBoss
                        ? 30
                        : node.isGuardian
                        ? _GuardianPlaque.drop + plaque + 3
                        : 6),
                child: IgnorePointer(child: _StarsTag(stars: node.stars)),
              ),
            if (node.isCurrent && !node.isBoss && !node.isGuardian)
              Positioned(
                top: box / 2 + r + 30,
                child: IgnorePointer(child: _NameTag(node.name)),
              ),
            if (node.isBoss)
              Positioned(
                top: box / 2 + r - 12,
                child: IgnorePointer(
                  child: _BossName(name: node.name, locked: node.locked),
                ),
              ),
            if (node.isGuardian)
              Positioned(
                top: box / 2 + reach + _GuardianPlaque.drop,
                child: IgnorePointer(
                  child: _GuardianPlaque(
                    name: CampaignHeadwear.name(node.boss!),
                    short: widget.compactNames,
                    boss: node.boss!,
                    locked: node.locked,
                  ),
                ),
              ),
            if (node.isCurrent)
              Positioned(
                bottom: box / 2 + reach - 6,
                child: IgnorePointer(
                  child: _PerchedBird(
                    bird: widget.bird,
                    clock: widget.clock,
                    still: widget.still,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _face(double r) {
    if (node.isBoss || node.isGuardian) return null;
    if (node.locked) {
      return SizedBox(
        width: r * .8,
        height: r * .9,
        child: CustomPaint(
          painter: MapPadlockPainter(
            color: SkyColors.muted.withValues(alpha: .85),
          ),
        ),
      );
    }
    return CampaignTextScale.wrap(
      Text(
        node.id,
        style: heading(r * .62, weight: FontWeight.w700).copyWith(height: 1),
      ),
    );
  }
}

/// The three star slots under an open node, on a cream tag.
class _StarsTag extends StatelessWidget {
  const _StarsTag({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
    decoration: BoxDecoration(
      color: SkyColors.cream.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: SkyColors.ink.withValues(alpha: .25),
        width: 1.2,
      ),
    ),
    child: SizedBox(
      width: 50,
      height: 15,
      child: CustomPaint(painter: MapStarsPainter(stars.clamp(0, 3))),
    ),
  );
}

/// The current level's name, under its stars.
class _NameTag extends StatelessWidget {
  const _NameTag(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => CampaignTextScale.wrap(
    Container(
      padding: const EdgeInsets.fromLTRB(10, 3, 12, 4),
      decoration: BoxDecoration(
        color: SkyColors.ink,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: SkyColors.ink.withValues(alpha: .18),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_arrow_rounded,
            size: 16,
            color: SkyColors.yellow,
          ),
          const SizedBox(width: 3),
          Text(
            name,
            style: heading(14, color: SkyColors.cream).copyWith(height: 1.15),
          ),
        ],
      ),
    ),
  );
}

/// A guardian's name card, hung at the foot of its shield: GUARDIAN in small
/// capitals over the boss's name, on an ink plaque edged in the guardian's
/// own colour, so it is not mistaken for a chapter lair's ribbon.
///
/// Both lines are 4.5:1 or better against the plaque, locked or not (a locked
/// guardian's plaque is slate with cream lettering), and both follow the
/// system text size: the plaque grows with it ([heightFor]) and the name
/// shrinks to the plaque's widest ([maxWidth]) rather than reaching a
/// neighbouring level.
class _GuardianPlaque extends StatelessWidget {
  const _GuardianPlaque({
    required this.name,
    required this.short,
    required this.boss,
    required this.locked,
  });
  final String name;

  /// Whether a narrow stop sets a long name short ("Gargoyle").
  final bool short;
  final BossKind boss;
  final bool locked;

  /// How far the plaque hangs below the shield's point, and the widest it
  /// gets.
  static const drop = 1.0, maxWidth = 176.0;

  /// The plaque's height at a text [scale] (1 to 1.3): its two lines, 11 and
  /// 13 px at 1x, plus their padding.
  static double heightFor(double scale) => (24 * scale + 14).ceilToDouble();

  /// The name as set: whole, or its last word on a narrow stop.
  String get shown => short && name.length > 12 && name.contains(' ')
      ? name.split(' ').last
      : name;

  @override
  Widget build(BuildContext context) {
    final tone = locked ? SkyColors.cream : GuardianPlaqueLook.accent(boss);
    return CampaignTextScale.wrap(
      Builder(
        builder: (context) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Container(
            key: ValueKey('campaign-guardian-$name'),
            height: heightFor(CampaignTextScale.of(context)),
            padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
            decoration: BoxDecoration(
              color: locked ? GuardianPlaqueLook.lockedFill : SkyColors.ink,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: locked ? const Color(0xffb4c4cb) : tone,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: SkyColors.ink.withValues(alpha: .28),
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GUARDIAN',
                    style: bodyText(
                      11,
                      color: tone,
                      weight: FontWeight.w900,
                    ).copyWith(letterSpacing: 1.6, height: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shown,
                    maxLines: 1,
                    style: heading(
                      13,
                      color: SkyColors.cream,
                      weight: FontWeight.w600,
                    ).copyWith(height: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The boss's name on a ribbon across the foot of its lair.
class _BossName extends StatelessWidget {
  const _BossName({required this.name, required this.locked});
  final String name;
  final bool locked;

  @override
  Widget build(BuildContext context) => CampaignTextScale.wrap(
    CustomPaint(
      painter: MapRibbonPainter(
        color: locked ? const Color(0xff8a9ea8) : SkyColors.ink,
        shade: locked ? const Color(0xff6c7f89) : const Color(0xff15282f),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 3, 18, 8),
        child: Text(
          name,
          style: heading(
            14,
            color: SkyColors.cream,
            weight: FontWeight.w600,
          ).copyWith(height: 1.1),
        ),
      ),
    ),
  );
}

/// The equipped bird standing on the current level, bobbing gently.
class _PerchedBird extends StatelessWidget {
  const _PerchedBird({
    required this.bird,
    required this.clock,
    required this.still,
  });
  final int bird;
  final ValueListenable<double> clock;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final art = BirdArt(bird: bird, size: 66, bob: false);
    if (still) return art;
    return AnimatedBuilder(
      animation: clock,
      child: art,
      builder: (context, child) {
        // A little hop in place: up, then a soft landing squash.
        final t = clock.value * 1.4;
        final lift = math.max(0.0, math.sin(t * math.pi)) * 5;
        return Transform.translate(offset: Offset(0, -lift), child: child);
      },
    );
  }
}

/// A beaten chapter's postcard waiting on the route beside the boss's lair.
class _PostcardMarker extends StatelessWidget {
  const _PostcardMarker({
    required this.chapter,
    required this.boss,
    required this.clock,
    required this.still,
    required this.onTap,
  });
  final int chapter;
  final BossKind boss;
  final ValueListenable<double> clock;
  final bool still;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: 64,
      height: 48,
      child: CustomPaint(painter: MapPostcardPainter(boss)),
    );
    final press = onTap == null
        ? null
        : () {
            UiSounds.effect(context);
            onTap!(chapter);
          };
    return Semantics(
      button: true,
      label: 'Chapter $chapter postcard',
      excludeSemantics: true,
      onTap: onTap == null ? null : () => onTap!(chapter),
      child: KeyTap(
        onPressed: press,
        shape: BoxShape.rectangle,
        radius: BorderRadius.circular(20),
        spread: 2,
        child: GestureDetector(
          key: ValueKey('campaign-postcard-$chapter'),
          behavior: HitTestBehavior.opaque,
          onTap: press,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  SkyColors.cream.withValues(alpha: .75),
                  SkyColors.cream.withValues(alpha: 0),
                ],
              ),
            ),
            child: still
                ? Transform.rotate(angle: -.12, child: card)
                : AnimatedBuilder(
                    animation: clock,
                    child: card,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, math.sin(clock.value * 2) * 3),
                      child: Transform.rotate(
                        angle: -.12 + math.sin(clock.value * 1.3) * .05,
                        child: child,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
