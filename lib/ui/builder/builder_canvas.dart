import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../domain/built_draft.dart';
import '../../domain/built_reach.dart';
import '../../domain/game_rules.dart';
import '../../game/regions/region_scene.dart' show SceneFrame;
import '../../game/regions/world_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../l10n/text/builder_text.dart';
import '../campaign_region_still.dart';
import '../match_hud.dart' show MatchPlate;
import '../theme.dart';
import '../ui_sounds.dart';
import 'builder_art.dart';
import 'builder_chrome.dart' show BuilderToast;
import 'builder_controller.dart';
import 'builder_palette.dart' show ToolIconPainter;

/// The editor's sky: the level's route in its region, a phone screen of it
/// at a time, with everything placed on it painted by the flight's own art.
///
/// A tap places what the tool in hand places (or, with Select, picks what is
/// under the finger); a drag moves the selected item, or with Select picks
/// up a star, heart or enemy and moves it; any other drag pans along the
/// route. Positions read in the canvas's own pixels: the sky is the canvas
/// height tall, so a world position is `scroll + x / height` along.
///
/// Every action answers: a press with a placing tool shows a ghost of what
/// will land and where it snaps; a placement pops (with Reduced Motion off)
/// and clicks; a tap in the start zone is refused with a word why; a drag
/// lifts the item, leaves a ghost where it came from and draws the lines it
/// snaps to.
class BuilderCanvas extends StatefulWidget {
  const BuilderCanvas({super.key, required this.controller, this.bird = 0});
  final BuilderController controller;

  /// The player's bird, drawn faint where the flight starts.
  final int bird;

  @override
  State<BuilderCanvas> createState() => _BuilderCanvasState();
}

/// How far (canvas pixels) a finger may land from an item and still take it.
const _slop = 26.0;

/// What a placing tool would put down: the item itself, or for the finish
/// tool the line's place, and whether it may go there.
typedef PlacePreview = ({BuiltItem? item, double? finishX, bool blocked});

class _BuilderCanvasState extends State<BuilderCanvas>
    with TickerProviderStateMixin {
  BuilderController get c => widget.controller;

  /// The item being dragged, where the finger holds it from its place, and
  /// the item as it was when the drag began.
  int? _dragging;
  Offset _grab = Offset.zero;
  BuiltItem? _dragOrigin;

  /// A pan: the scroll and the finger where it began.
  double? _panScroll;
  double _panFrom = 0;

  /// Where a placing tool is pressed, before the finger lifts.
  Offset? _press;

  /// The pop of the item just placed, and the start zone's refusal flash.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final AnimationController _deny = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  int? _popKey;

  @override
  void dispose() {
    _pop.dispose();
    _deny.dispose();
    super.dispose();
  }

  bool get _still => MediaQuery.disableAnimationsOf(context);

  bool get _placing => !c.readOnly && c.tool != BuilderTool.select;

  Offset _world(Offset local, double h) =>
      Offset(c.scroll + local.dx / h, local.dy / h);

  static Offset _place(BuiltItem item) =>
      Offset(item.worldX, item.y / BuiltPlan.unit);

  static const _start = BuiltPlan.firstX / BuiltPlan.unit;

  /// The item the tool in hand would place at [at], snapped as it will be.
  BuiltItem? _wouldPlace(BuilderTool tool, Offset at) {
    final x = BuiltDraft.snapX(at.dx), y = BuiltDraft.snapY(at.dy);
    return switch (tool) {
      BuilderTool.gate => BuiltDraft.gateAt(c.mode, at.dx, at.dy),
      BuilderTool.star => BuiltStar(x: x, y: y),
      BuilderTool.trio => BuiltTrio(x: x, y: y),
      BuilderTool.heart => BuiltHeart(x: x, y: y),
      BuilderTool.enemy => BuiltEnemy(x: x, y: y, kind: EnemyKind.simpleBat),
      BuilderTool.select || BuilderTool.finish => null,
    };
  }

  /// [at] moved just far enough along that what [tool] places there clears
  /// the start zone, or null when the finger is inside the zone itself.
  Offset? _clearOfStart(BuilderTool tool, Offset at) {
    final item = _wouldPlace(tool, at);
    if (item == null || item.left >= BuiltPlan.firstX) return at;
    // A finger on the line itself is taken as meaning just past it.
    if (at.dx < _start - .02) return null;
    final x = ((item.x + BuiltPlan.firstX - item.left) / 50).ceil() * 50;
    return Offset(x / BuiltPlan.unit, at.dy);
  }

  /// What a press at [local] would place, for the ghost under the finger.
  PlacePreview? _preview(double h) {
    final press = _press;
    if (press == null || !_placing) return null;
    final at = _world(press, h);
    if (c.tool == BuilderTool.finish) {
      final x = math.max(
        BuiltPlan.firstX + BuiltPlan.unit,
        BuiltDraft.snapX(at.dx),
      );
      return (item: null, finishX: x / BuiltPlan.unit, blocked: false);
    }
    final clear = _clearOfStart(c.tool, at);
    return (
      item: _wouldPlace(c.tool, clear ?? at),
      finishX: null,
      blocked: clear == null,
    );
  }

  void _pressDown(Offset local) {
    if (_placing) setState(() => _press = local);
  }

  void _pressEnd() {
    if (_press != null) setState(() => _press = null);
  }

  void _refuse() {
    UiSounds.effect(context, ShopCues.denied);
    BuilderToast.warn(context, context.l10n.builderStartZoneToast);
    if (!_still) _deny.forward(from: 0);
  }

  void _tap(Offset local, double h) {
    _pressEnd();
    var at = _world(local, h);
    final reach = _slop / h;
    final tool = c.tool;
    if (_placing && tool != BuilderTool.finish) {
      // Tapping a gate with the gate tool, or right on a pickup, picks it
      // rather than piling another on top of it.
      final hit = c.draft.hit(at.dx, at.dy, reach: reach);
      final item = hit == null ? null : c.draft[hit];
      final onIt = switch (item) {
        null => false,
        BuiltGate() => tool == BuilderTool.gate,
        _ => (_place(item) - at).distance <= reach * .7,
      };
      if (onIt) {
        UiSounds.effect(context, 'ui_tap');
        c.select(hit);
        return;
      }
      // Nothing is placed in the start zone; a thing that would just
      // overhang it is set down clear of it.
      final clear = _clearOfStart(tool, at);
      if (clear == null) {
        _refuse();
        return;
      }
      at = clear;
    }
    final before = c.draft;
    final key = c.tapAt(at.dx, at.dy, reach: reach);
    if (c.readOnly || tool == BuilderTool.select) {
      if (key != null) UiSounds.effect(context, 'ui_tap');
      return;
    }
    if (identical(before, c.draft)) return;
    UiSounds.effect(context, switch (tool) {
      BuilderTool.star || BuilderTool.trio => 'star',
      BuilderTool.heart => 'heart',
      _ => 'ui_toggle',
    });
    HapticFeedback.selectionClick();
    _popKey = key;
    if (!_still && key != null) _pop.forward(from: 0);
  }

  void _panStart(Offset local, double h) {
    _pressEnd();
    final at = _world(local, h);
    final reach = _slop / h;
    if (!c.readOnly) {
      final hit = c.draft.hit(at.dx, at.dy, reach: reach);
      final item = hit == null ? null : c.draft[hit];
      // The selected item moves under the finger; with Select, so does a
      // star, heart or enemy picked up anywhere. Gates fill the sky's
      // height, so an unselected one never steals a pan.
      final grab =
          hit != null &&
          item != null &&
          (hit == c.selected ||
              (c.tool == BuilderTool.select && item is! BuiltGate));
      if (grab) {
        _dragging = hit;
        _dragOrigin = item;
        _grab = _place(item) - at;
        c.beginDrag(hit);
        UiSounds.effect(context, 'ui_tap');
        HapticFeedback.selectionClick();
        return;
      }
    }
    _panScroll = c.scroll;
    _panFrom = local.dx;
  }

  void _panUpdate(Offset local, Size size) {
    final h = size.height;
    if (_dragging != null) {
      // Near an edge the view follows the dragged item along the route.
      const edge = 40.0;
      if (local.dx > size.width - edge) {
        c.scrollTo(c.scroll + .03);
      } else if (local.dx < edge && c.scroll > 0) {
        c.scrollTo(c.scroll - .03);
      }
      final at = _world(local, h) + _grab;
      c.dragTo(at.dx, at.dy);
      return;
    }
    final from = _panScroll;
    if (from != null) c.scrollTo(from - (local.dx - _panFrom) / h);
  }

  void _panEnd() {
    final key = _dragging;
    if (key != null) {
      final moved = c.draft[key];
      c.endDrag();
      // A drop that moved it lands with a click.
      if (moved != null && !identical(moved, _dragOrigin)) {
        UiSounds.effect(context, 'ui_toggle');
        HapticFeedback.selectionClick();
      }
    }
    setState(() {
      _dragging = null;
      _dragOrigin = null;
    });
    _panScroll = null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final l = context.l10n;
      final plan = c.plan;
      final still = _still;
      return Semantics(
        label: c.readOnly
            ? l.builderSkyReadOnlySemantics
            : l.builderSkySemantics,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SkyColors.ink, width: 2.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, box) {
                final size = box.biggest;
                final dragging = _dragging != null && _dragging == c.selected;
                return GestureDetector(
                  key: const ValueKey('builder-canvas'),
                  behavior: HitTestBehavior.opaque,
                  // A drag picks up what is under the finger where it
                  // touched down, not where it had moved to by then.
                  dragStartBehavior: DragStartBehavior.down,
                  onTapDown: (d) => _pressDown(d.localPosition),
                  onTapCancel: _pressEnd,
                  onTapUp: (d) => _tap(d.localPosition, size.height),
                  onPanStart: (d) => _panStart(d.localPosition, size.height),
                  onPanUpdate: (d) => _panUpdate(d.localPosition, size),
                  onPanEnd: (_) => _panEnd(),
                  onPanCancel: _panEnd,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // The region's scenery slides by as the route does,
                      // at the flight's own parallax; with Reduced Motion
                      // it stays the still a level opens on.
                      if (still)
                        CampaignRegionView(region: plan.region)
                      else
                        RepaintBoundary(
                          child: CustomPaint(
                            key: const ValueKey('builder-scenery'),
                            painter: BuilderSceneryPainter(
                              region: plan.region,
                              scroll: c.scroll,
                            ),
                          ),
                        ),
                      CustomPaint(
                        painter: BuilderCanvasPainter(
                          words: l,
                          draft: c.draft,
                          plan: plan,
                          scroll: c.scroll,
                          selected: c.selected,
                          issues: c.issues,
                          bird: widget.bird,
                          dragFrom: dragging ? _dragOrigin : null,
                          preview: _preview(size.height),
                          pop: _pop,
                          popKey: _popKey,
                          deny: _deny,
                        ),
                      ),
                      // First steps, out of the way while a finger is down.
                      // They are words over the sky, read the language's
                      // way.
                      if (!c.readOnly)
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _press != null || dragging ? 0 : 1,
                            duration: still
                                ? Duration.zero
                                : const Duration(milliseconds: 140),
                            child: LanguageDirection(
                              child: _Coach(controller: c),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

/// First steps over the sky, read from the level itself: an empty level
/// shows how to begin (pick a tool, tap the sky, test fly); with its first
/// thing or two placed, a line on moving and scrolling. It never takes a
/// tap: the sky under it answers.
class _Coach extends StatelessWidget {
  const _Coach({required this.controller});
  final BuilderController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final l = context.l10n;
      final count = controller.plan.items.length;
      if (count == 0) {
        return Align(
          alignment: const Alignment(.42, -.38),
          child: MatchPlate(
            key: const ValueKey('editor-coach'),
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.builderCoachTitle,
                  style: heading(19, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CoachStep(
                      number: 1,
                      text: l.builderCoachPickTool,
                      picture: SizedBox(
                        width: 26,
                        height: 32,
                        child: CustomPaint(
                          painter: ToolIconPainter(
                            BuilderTool.gate,
                            region: controller.plan.region,
                          ),
                        ),
                      ),
                    ),
                    const _CoachArrow(),
                    _CoachStep(
                      number: 2,
                      text: l.builderCoachTapSky,
                      picture: const Icon(
                        Icons.touch_app_rounded,
                        size: 26,
                        color: SkyColors.ink,
                      ),
                    ),
                    const _CoachArrow(),
                    _CoachStep(
                      number: 3,
                      text: l.builderCoachTestFly,
                      color: SkyColors.mint,
                      picture: const Icon(
                        Icons.play_arrow_rounded,
                        size: 30,
                        color: SkyColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.builderCoachDrag,
                  style: bodyText(
                    12,
                    color: SkyColors.muted,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (count > 2) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 12, 0),
          child: MatchPlate(
            key: const ValueKey('editor-tip'),
            padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.open_with_rounded,
                  size: 18,
                  color: SkyColors.ink,
                ),
                const SizedBox(width: 6),
                Text(
                  l.builderTipDrag,
                  style: bodyText(12.5, weight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CoachStep extends StatelessWidget {
  const _CoachStep({
    required this.number,
    required this.text,
    required this.picture,
    this.color = SkyColors.yellow,
  });
  final int number;
  final String text;
  final Widget picture;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    child: Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: SkyColors.ink, width: 2.2),
                boxShadow: const [
                  BoxShadow(color: SkyColors.ink, offset: Offset(0, 2.5)),
                ],
              ),
              child: Center(child: picture),
            ),
            PositionedDirectional(
              start: -6,
              top: -4,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SkyColors.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: SkyColors.cream, width: 1.5),
                ),
                child: Text(
                  '$number',
                  style: heading(
                    12,
                    color: SkyColors.cream,
                    weight: FontWeight.w700,
                  ).copyWith(height: 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 3,
          style: bodyText(12.5, weight: FontWeight.w900).copyWith(height: 1.1),
        ),
      ],
    ),
  );
}

class _CoachArrow extends StatelessWidget {
  const _CoachArrow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 12),
    child: Icon(Icons.chevron_right_rounded, size: 22, color: SkyColors.muted),
  );
}

/// The region's flight scenery at a place on the route: its bands slide at
/// their parallax as the editor scrolls, so the world feels continuous. It
/// repaints only when the view moves.
class BuilderSceneryPainter extends CustomPainter {
  const BuilderSceneryPainter({required this.region, required this.scroll});
  final WorldRegion region;
  final double scroll;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    WorldBackdrop.paint(
      canvas,
      SceneFrame(
        size,
        seconds: scroll / WorldBackdrop.cruise,
        distance: scroll,
        reducedMotion: false,
        region: region,
      ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BuilderSceneryPainter old) =>
      old.region != region || old.scroll != scroll;
}

/// Paints the route over the region's scenery: the start zone, lanes, the
/// items in reach, the finish line or a boss's mark, the selection, a drag's
/// ghost and snap lines, a press's preview, issue flags and a ruler of
/// seconds.
class BuilderCanvasPainter extends CustomPainter {
  BuilderCanvasPainter({
    required this.words,
    required this.draft,
    required this.plan,
    required this.scroll,
    required this.selected,
    required this.issues,
    required this.bird,
    this.dragFrom,
    this.preview,
    this.pop,
    this.popKey,
    this.deny,
  }) : super(repaint: Listenable.merge([pop, deny]));

  /// The language its tags are written in.
  final AppLocalizations words;
  final BuiltDraft draft;
  final BuiltPlan plan;
  final double scroll;
  final int? selected;
  final List<BuiltIssue> issues;
  final int bird;

  /// While the selected item is dragged: where it was when the drag began.
  final BuiltItem? dragFrom;

  /// What a placing tool's press would put down.
  final PlacePreview? preview;

  /// The pop of the item [popKey] just placed, and the start zone's
  /// refusal flash: 0 to 1 while they play.
  final Animation<double>? pop, deny;
  final int? popKey;

  static double _playing(Animation<double>? a) {
    final t = a?.value ?? 0;
    return t > 0 && t < 1 ? t : 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height, w = size.width;
    final view = w / h;
    double sx(double worldX) => (worldX - scroll) * h;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Past the finish line the sky is out of the level.
    final finishX = sx(plan.finishX);
    if (finishX < w) {
      canvas.drawRect(
        Rect.fromLTRB(math.max(0, finishX), 0, w, h),
        Paint()..color = SkyColors.night.withValues(alpha: .32),
      );
    }

    final chosen = selected == null ? null : draft[selected!];
    _lanes(canvas, size, chosen);
    _startZone(canvas, size, sx);

    // Where a dragged item came from, faint.
    final from = dragFrom;
    if (from != null) _ghost(canvas, h, from, sx, opacity: .38);

    // Everything in view, in the flight's order: gates, then pickups.
    final entries = [...draft.items]
      ..sort((a, b) => BuiltItem.compare(a.item, b.item));
    final popping = _playing(pop);
    for (final entry in entries) {
      final item = entry.item;
      final left = item.left / BuiltPlan.unit - .35;
      final right = item.right / BuiltPlan.unit + .35;
      if (right < scroll || left > scroll + view) continue;
      final lifted = from != null && entry.key == selected;
      if (lifted && item is! BuiltGate) {
        // Lifted off the sky: a soft shadow under it.
        canvas.drawOval(
          Rect.fromCenter(
            center:
                Offset(sx(item.worldX), item.y / BuiltPlan.unit * h) +
                Offset(0, h * .07),
            width: item is BuiltTrio ? h * .5 : h * .12,
            height: h * .03,
          ),
          Paint()
            ..color = SkyColors.ink.withValues(alpha: .28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      final grow = entry.key == popKey && popping > 0
          ? 1 + .28 * math.sin(popping * math.pi) * (1 - popping * .4)
          : lifted
          ? 1.08
          : 1.0;
      if (grow != 1) {
        final focus = _focus(item, sx, h);
        canvas.save();
        canvas.translate(focus.dx, focus.dy);
        // A gate only swells across: it already fills the sky's height.
        canvas.scale(grow, item is BuiltGate ? 1 : grow);
        canvas.translate(-focus.dx, -focus.dy);
      }
      _item(canvas, h, item, sx);
      if (grow != 1) canvas.restore();
    }

    // The finish gate, or the boss waiting on its mark.
    if (finishX > -h * .7 && finishX < w + h * .7) {
      if (plan.boss != null) {
        BuilderArt.bossMark(canvas, h, finishX, plan.boss!);
      } else {
        BuilderArt.finish(canvas, h, finishX);
      }
    }

    _laneLabels(canvas, size, sx);
    if (chosen != null) {
      if (from != null) _guides(canvas, size, chosen, sx);
      _halo(canvas, size, chosen, sx, dragging: from != null);
    }
    _preview(canvas, size, sx);
    if (popping > 0) {
      final placed = popKey == null ? null : draft[popKey!];
      if (placed != null) _burst(canvas, _focus(placed, sx, h), h, popping);
    }
    _flags(canvas, size, sx);
    _ruler(canvas, size, sx);
    canvas.restore();
  }

  void _item(
    Canvas canvas,
    double h,
    BuiltItem item,
    double Function(double) sx,
  ) {
    final at = Offset(sx(item.worldX), item.y / BuiltPlan.unit * h);
    switch (item) {
      case BuiltGate gate:
        BuilderArt.gate(
          canvas,
          h,
          gate,
          mode: plan.mode,
          x: at.dx / h,
          region: plan.region,
        );
      case BuiltStar():
        BuilderArt.star(canvas, h, at);
      case BuiltTrio():
        BuilderArt.trio(canvas, h, at);
      case BuiltHeart():
        BuilderArt.heart(canvas, h, at);
      case BuiltEnemy enemy:
        BuilderArt.enemy(canvas, h, enemy.kind, at);
    }
  }

  /// Where the eye goes on [item]: a gate's opening, a pickup's centre.
  Offset _focus(BuiltItem item, double Function(double) sx, double h) {
    final y = item.y / BuiltPlan.unit * h;
    if (item is BuiltGate) {
      return Offset((sx(item.worldX) + sx(item.right / BuiltPlan.unit)) / 2, y);
    }
    return Offset(sx(item.worldX), y);
  }

  /// [item] drawn see-through, as a ghost.
  void _ghost(
    Canvas canvas,
    double h,
    BuiltItem item,
    double Function(double) sx, {
    double opacity = .5,
    Color? tint,
  }) {
    canvas.saveLayer(
      null,
      Paint()
        ..color = SkyColors.white.withValues(alpha: opacity)
        ..colorFilter = tint == null
            ? null
            : ColorFilter.mode(tint.withValues(alpha: .55), BlendMode.srcATop),
    );
    _item(canvas, h, item, sx);
    canvas.restore();
  }

  /// A push-up or squat bird's two lanes: where its gates sit (dotted) and
  /// the calibrated top and bottom it aims at, with the sky beyond its reach
  /// shaded. The lane a selected gate sits on glows.
  void _lanes(Canvas canvas, Size size, BuiltItem? chosen) {
    if (!plan.mode.controlsHeight) return;
    final h = size.height, w = size.width;
    final shade = Paint()..color = SkyColors.night.withValues(alpha: .22);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * .09), shade);
    canvas.drawRect(Rect.fromLTWH(0, h * .91, w, h * .09), shade);
    final dots = Paint()..color = SkyColors.white.withValues(alpha: .55);
    final lit = Paint()..color = SkyColors.yellow;
    final lane = chosen is BuiltGate ? chosen.y / BuiltPlan.unit : null;
    for (final y in const [.25, .75]) {
      final on = lane != null && (lane - y).abs() < .01;
      for (var x = 6.0; x < w; x += 14) {
        canvas.drawCircle(Offset(x, y * h), on ? 2.4 : 1.6, on ? lit : dots);
      }
    }
    final aim = Paint()
      ..color = SkyColors.yellow.withValues(alpha: .85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final y in const [.15, .85]) {
      for (var x = 0.0; x < w; x += 22) {
        canvas.drawLine(Offset(x, y * h), Offset(x + 12, y * h), aim);
      }
    }
  }

  /// The names of the two aiming lines at the left edge: in full while the
  /// start zone is in view, then just "TOP" and "BOTTOM", so they cover
  /// little of what is placed there.
  void _laneLabels(Canvas canvas, Size size, double Function(double) sx) {
    if (!plan.mode.controlsHeight) return;
    final h = size.height;
    final movement = words.builtMovement(plan.mode);
    final full = sx(BuiltPlan.firstX / BuiltPlan.unit) > 170;
    _tag(
      canvas,
      full ? words.builderCanvasTopOf(movement) : words.builderCanvasTop,
      Offset(8, h * .15 + 6),
      color: SkyColors.yellow,
      size: 10,
    );
    _tag(
      canvas,
      full ? words.builderCanvasBottomOf(movement) : words.builderCanvasBottom,
      Offset(8, h * .85 - 24),
      color: SkyColors.yellow,
      size: 10,
    );
  }

  /// The start zone: nothing may stand before [BuiltPlan.firstX], so the
  /// bird is never met by anything as it takes off. It flashes coral when a
  /// placement there is refused.
  void _startZone(Canvas canvas, Size size, double Function(double) sx) {
    final h = size.height;
    final end = sx(BuiltPlan.firstX / BuiltPlan.unit);
    if (end <= 0) return;
    final zone = Rect.fromLTRB(0, 0, math.min(end, size.width), h);
    canvas.drawRect(
      zone,
      Paint()..color = SkyColors.night.withValues(alpha: .28),
    );
    final flash = _playing(deny);
    if (flash > 0) {
      canvas.drawRect(
        zone,
        Paint()
          ..color = SkyColors.coral.withValues(
            alpha: .5 * math.sin(flash * math.pi),
          ),
      );
    }
    canvas.save();
    canvas.clipRect(zone);
    final stripe = Paint()
      ..color = SkyColors.cream.withValues(alpha: .16)
      ..strokeWidth = 9;
    final from = (sx(0) / 26).floor() * 26.0;
    for (var x = from - h; x < zone.right + h; x += 26) {
      canvas.drawLine(Offset(x, h), Offset(x + h, 0), stripe);
    }
    canvas.restore();
    // The start zone's edge, dashed.
    final edge = Paint()
      ..color = SkyColors.cream.withValues(alpha: .9)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var y = 6.0; y < h; y += 16) {
      canvas.drawLine(Offset(end, y), Offset(end, y + 8), edge);
    }
    final bird = sx(FlightSimulation.birdX);
    if (bird > -h * .2) {
      BuilderArt.ghostBird(canvas, h, Offset(bird, h * .5), this.bird);
    }
    // The full tag where the zone has room for it, the short one where it
    // does not, none on a sliver.
    final room = math.min(end, size.width) - 24;
    final tag = [
      if (end > 200) words.builderCanvasStartZoneFull,
      if (end > 110) words.builderCanvasStartZone,
    ].where((text) => _tagWidth(text) <= room).firstOrNull;
    if (tag != null) {
      _tag(
        canvas,
        tag,
        Offset(math.min(end, size.width) - 12, 12),
        color: SkyColors.cream,
        alignRight: true,
      );
    }
  }

  /// Rings the selected item, gives it a move handle, and says when the
  /// bird meets it.
  void _halo(
    Canvas canvas,
    Size size,
    BuiltItem item,
    double Function(double) sx, {
    required bool dragging,
  }) {
    final h = size.height;
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final light = Paint()
      ..color = SkyColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    final Rect bounds;
    final Offset handle;
    if (item is BuiltGate) {
      final left = sx(item.worldX), right = sx(item.right / BuiltPlan.unit);
      bounds = Rect.fromLTRB(left - 6, 4, right + 6, h - 4);
      final r = RRect.fromRectAndRadius(bounds, const Radius.circular(12));
      canvas.drawRRect(
        r,
        Paint()
          ..color = SkyColors.yellow.withValues(alpha: dragging ? .24 : .14),
      );
      canvas.drawRRect(r, ink);
      canvas.drawRRect(r, light);
      // One handle, in the opening: the whole gate moves.
      handle = Offset(bounds.center.dx, item.y / BuiltPlan.unit * h);
    } else {
      final center = Offset(sx(item.worldX), item.y / BuiltPlan.unit * h);
      final half = item is BuiltTrio
          ? Size(BuiltTrio.spacing / BuiltPlan.unit * h + h * .07, h * .07)
          : Size(h * .075, h * .075);
      bounds = Rect.fromCenter(
        center: center,
        width: half.width * 2,
        height: half.height * 2,
      );
      final r = RRect.fromRectAndRadius(bounds, Radius.circular(half.height));
      canvas.drawRRect(r, ink);
      canvas.drawRRect(r, light);
      // The handle sits on the ring's shoulder, clear of the art.
      handle = Offset(bounds.right - half.height * .3, bounds.top + 2);
    }
    if (!dragging) _moveHandle(canvas, handle);
    final seconds = BuiltReach.secondsTo(plan, item.x);
    _tag(
      canvas,
      words.builtSeconds(seconds, digits: 1),
      Offset(bounds.center.dx, item is BuiltGate ? h - 52 : bounds.bottom + 6),
      color: SkyColors.yellow,
      centred: true,
    );
  }

  /// A round yellow handle with four arrows: drag me.
  static void _moveHandle(Canvas canvas, Offset at) {
    canvas.drawCircle(
      at + const Offset(0, 2),
      11,
      Paint()..color = SkyColors.ink,
    );
    canvas.drawCircle(at, 11, Paint()..color = SkyColors.yellow);
    canvas.drawCircle(
      at,
      11,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _glyph(canvas, Icons.open_with_rounded, at, 15, SkyColors.ink);
  }

  /// While dragging: the lines the item snaps to, across the sky.
  void _guides(
    Canvas canvas,
    Size size,
    BuiltItem item,
    double Function(double) sx,
  ) {
    final h = size.height, w = size.width;
    final focus = _focus(item, sx, h);
    final line = Paint()
      ..color = SkyColors.cream.withValues(alpha: .85)
      ..strokeWidth = 1.6;
    final x = item is BuiltGate ? sx(item.worldX) : focus.dx;
    _dashed(canvas, Offset(x, 0), Offset(x, h), line);
    if (item is! BuiltGate || !plan.mode.controlsHeight) {
      _dashed(canvas, Offset(0, focus.dy), Offset(w, focus.dy), line);
    }
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final length = (b - a).distance;
    if (length <= 0) return;
    final step = (b - a) / length;
    for (var d = 0.0; d < length; d += 10) {
      canvas.drawLine(a + step * d, a + step * math.min(d + 5, length), paint);
    }
  }

  /// A placing tool's press: a ghost of what will land, snapped, or a coral
  /// cross where nothing may go.
  void _preview(Canvas canvas, Size size, double Function(double) sx) {
    final p = preview;
    if (p == null) return;
    final h = size.height;
    final finish = p.finishX;
    if (finish != null) {
      final x = sx(finish);
      _dashed(
        canvas,
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = SkyColors.cream
          ..strokeWidth = 3,
      );
      _tag(canvas, words.builderCanvasFinishHere, Offset(x, 30), centred: true);
      return;
    }
    final item = p.item;
    if (item == null) return;
    final focus = _focus(item, sx, h);
    if (p.blocked) {
      _ghost(canvas, h, item, sx, opacity: .45, tint: SkyColors.coral);
      canvas.drawCircle(focus, 16, Paint()..color = SkyColors.coral);
      canvas.drawCircle(
        focus,
        16,
        Paint()
          ..color = SkyColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      _glyph(canvas, Icons.close_rounded, focus, 20, SkyColors.ink);
      return;
    }
    _guides(canvas, size, item, sx);
    _ghost(canvas, h, item, sx, opacity: .62);
  }

  /// The ring that bursts from a thing just placed.
  static void _burst(Canvas canvas, Offset at, double h, double t) {
    final eased = Curves.easeOutCubic.transform(t);
    final r = h * (.05 + .13 * eased);
    final fade = 1 - t;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .5 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * fade + 1,
    );
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..color = SkyColors.yellow.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade + .5,
    );
    final spark = Paint()..color = SkyColors.cream.withValues(alpha: fade);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      canvas.drawCircle(
        at + Offset(math.cos(a), math.sin(a)) * (r + h * .03),
        2.6 * fade + .6,
        spark,
      );
    }
  }

  /// A coral flag over each problem and a yellow one over each piece of
  /// advice, at its place on the route.
  void _flags(Canvas canvas, Size size, double Function(double) sx) {
    final h = size.height;
    for (final issue in issues) {
      final x = issue.x;
      if (x == null) continue;
      final at = sx(x / BuiltPlan.unit);
      if (at < -20 || at > size.width + 20) continue;
      final color = issue.blocking ? SkyColors.coral : SkyColors.yellow;
      // A thin line down to the place itself.
      canvas.drawLine(
        Offset(at + 10, 30),
        Offset(at + 10, h * .12),
        Paint()
          ..color = color.withValues(alpha: .85)
          ..strokeWidth = 2,
      );
      final center = Offset(at + 10, 18);
      canvas.drawCircle(
        center + const Offset(0, 2),
        11,
        Paint()..color = SkyColors.ink,
      );
      canvas.drawCircle(center, 11, Paint()..color = color);
      canvas.drawCircle(
        center,
        11,
        Paint()
          ..color = SkyColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      _glyph(
        canvas,
        issue.blocking ? Icons.priority_high_rounded : Icons.lightbulb_rounded,
        center,
        14,
        SkyColors.ink,
      );
    }
  }

  /// Seconds from the start in a band along the bottom edge, as the route
  /// strip counts them.
  void _ruler(Canvas canvas, Size size, double Function(double) sx) {
    final h = size.height, w = size.width;
    const band = 20.0;
    canvas.drawRect(
      Rect.fromLTWH(0, h - band, w, band),
      Paint()..color = SkyColors.night.withValues(alpha: .42),
    );
    final cruise = BuiltReach.cruise(plan);
    double xAt(double seconds) => sx(FlightSimulation.birdX + seconds * cruise);
    final tick = Paint()
      ..color = SkyColors.cream.withValues(alpha: .75)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final first = math.max(
      0,
      ((scroll - FlightSimulation.birdX) / cruise).floor(),
    );
    for (var s = first; ; s++) {
      final x = xAt(s.toDouble());
      if (x > w + 30) break;
      if (x < -30) continue;
      final major = s % 5 == 0;
      if (major) {
        canvas.drawLine(Offset(x, h - band), Offset(x, h), tick);
        _label(canvas, words.builtSeconds(s), Offset(x + 4, h - band + 4));
      } else {
        canvas.drawLine(Offset(x, h - band), Offset(x, h - band + 5), tick);
      }
    }
  }

  /// Cream lettering on the ruler band.
  static void _label(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: bodyText(
          11,
          color: SkyColors.cream,
          weight: FontWeight.w900,
        ).copyWith(height: 1),
      ),
      textDirection: L10n.textDirection,
    )..layout();
    painter.paint(canvas, at);
    painter.dispose();
  }

  /// [icon] centred on [at].
  static void _glyph(
    Canvas canvas,
    IconData icon,
    Offset at,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
    painter.dispose();
  }

  /// How wide [_tag] draws [text] at [size].
  static double _tagWidth(String text, {double size = 11}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: bodyText(size, weight: FontWeight.w900).copyWith(height: 1),
      ),
      textDirection: L10n.textDirection,
    )..layout();
    final width = painter.width + 12;
    painter.dispose();
    return width;
  }

  /// A small cream (or [color]) plate with ink lettering.
  static void _tag(
    Canvas canvas,
    String text,
    Offset at, {
    Color color = SkyColors.cream,
    double size = 11,
    bool centred = false,
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: bodyText(size, weight: FontWeight.w900).copyWith(height: 1),
      ),
      textDirection: L10n.textDirection,
    )..layout();
    final width = painter.width + 12, height = painter.height + 8;
    final left = centred
        ? at.dx - width / 2
        : alignRight
        ? at.dx - width
        : at.dx;
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, at.dy, width, height),
      Radius.circular(height / 2),
    );
    canvas.drawRRect(
      plate.shift(const Offset(0, 2)),
      Paint()..color = SkyColors.ink,
    );
    canvas.drawRRect(plate, Paint()..color = color);
    canvas.drawRRect(
      plate,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    painter.paint(canvas, Offset(left + 6, at.dy + 4));
    painter.dispose();
  }

  @override
  bool shouldRepaint(BuilderCanvasPainter old) =>
      !identical(old.words, words) ||
      !identical(old.draft, draft) ||
      old.scroll != scroll ||
      old.selected != selected ||
      old.bird != bird ||
      !identical(old.issues, issues) ||
      !identical(old.dragFrom, dragFrom) ||
      old.preview != preview ||
      old.popKey != popKey;
}

/// The world x (sky heights) for a test flight to start from the view's
/// left edge, or null when that is still the start zone.
int? testFromHere(double scroll) {
  final from = BuiltDraft.snapX(scroll);
  return from <= BuiltPlan.firstX ? null : from;
}
