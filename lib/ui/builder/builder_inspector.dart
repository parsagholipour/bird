import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/built_reach.dart';
import '../../domain/game_rules.dart';
import '../../domain/tracking.dart';
import '../campaign_chrome.dart' show MapKey;
import '../control_glyphs.dart';
import '../../game/star_art.dart';
import '../theme.dart';
import '../ui_sounds.dart';
import 'builder_art.dart';
import 'builder_chrome.dart';
import 'builder_controller.dart';
import 'builder_pickers.dart' show PressCard;
import '../../l10n/l10n.dart';
import '../../l10n/text/builder_text.dart';
import '../fit_text.dart';

/// The panel on the right: with nothing selected, the level at a glance;
/// with a gate or anything else selected, everything about it that can be
/// changed, in big keys.
class BuilderInspector extends StatelessWidget {
  const BuilderInspector({super.key, required this.controller});
  final BuilderController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final item = controller.selection;
      final Widget body = switch (item) {
        null => _LevelSummary(controller: controller),
        _ when controller.readOnly => _LevelSummary(controller: controller),
        final BuiltGate gate => _GateInspector(
          key: ValueKey('gate-${controller.selected}'),
          controller: controller,
          gate: gate,
        ),
        _ => _ItemInspector(
          key: ValueKey('item-${controller.selected}'),
          controller: controller,
          item: item,
        ),
      };
      return DecoratedBox(
        decoration: BoxDecoration(
          color: SkyColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SkyColors.ink, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(SkyColors.teal, SkyColors.ink, .4)!,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17.5),
          child: body,
        ),
      );
    },
  );
}

/// The panel's header: what is selected.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.art});
  final String title, subtitle;
  final Widget? art;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
    decoration: const BoxDecoration(
      color: Color(0xfffff1d6),
      border: Border(bottom: BorderSide(color: SkyColors.ink, width: 2)),
    ),
    child: Row(
      children: [
        if (art != null) ...[art!, const SizedBox(width: 8)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitText(title, style: heading(19, weight: FontWeight.w700)),
              FitText(subtitle, style: bodyText(11.5, color: SkyColors.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The panel's foot: keys to copy the selected thing and to remove it.
class _Footer extends StatelessWidget {
  const _Footer({required this.controller});
  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xfffff1d6),
        border: Border(top: BorderSide(color: SkyColors.ink, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: BuilderKey(
              key: const ValueKey('inspector-duplicate'),
              tooltip: l.builderDuplicateSemantics,
              label: l.builderCopy,
              icon: Icons.copy_all_rounded,
              labelSize: 14,
              onPressed: controller.duplicateSelected,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: BuilderKey(
              key: const ValueKey('inspector-delete'),
              tooltip: l.builderDeleteSemantics,
              label: l.builderDelete,
              icon: Icons.delete_rounded,
              labelSize: 14,
              color: SkyColors.coral,
              sound: 'ui_back',
              onPressed: controller.deleteSelected,
            ),
          ),
        ],
      ),
    );
  }
}

/// A scrolling column of groups that shows plainly when there is more: a
/// scrollbar that stays in view, a fade at either end with more beyond it,
/// and a "More below" tag at the foot until the last group is in view.
class _Body extends StatefulWidget {
  const _Body({required this.children});
  final List<Widget> children;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _scroll = ScrollController();
  bool _above = false, _below = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_scrolled);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  /// A scroll corrected while laying out (the panel's content changed)
  /// is measured once the frame is done.
  void _scrolled() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    } else {
      _measure();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    final above = p.pixels > 2;
    final below = p.maxScrollExtent - p.pixels > 2;
    if (above != _above || below != _below) {
      setState(() {
        _above = above;
        _below = below;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    const fade = 22.0;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
        return false;
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) {
                final h = math.max(rect.height, fade * 2 + 1);
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(_above ? 0x00000000 : 0xff000000),
                    const Color(0xff000000),
                    const Color(0xff000000),
                    Color(_below ? 0x00000000 : 0xff000000),
                  ],
                  stops: [0, fade / h, 1 - fade / h, 1],
                ).createShader(rect);
              },
              child: RawScrollbar(
                controller: _scroll,
                thumbVisibility: true,
                thickness: 5,
                radius: const Radius.circular(3),
                crossAxisMargin: 3,
                mainAxisMargin: 8,
                thumbColor: SkyColors.ink.withValues(alpha: .38),
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(10, 10, 15, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, child) in widget.children.indexed) ...[
                        if (i > 0) const SizedBox(height: 12),
                        child,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _below ? 1 : 0,
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                child: const Center(child: _MoreBelow()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The tag at the foot of a panel with more to scroll to.
class _MoreBelow extends StatelessWidget {
  const _MoreBelow();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('inspector-more'),
    height: 24,
    padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
    decoration: BoxDecoration(
      color: SkyColors.yellow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SkyColors.ink, width: 1.8),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .3),
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.builderMoreBelow,
          style: bodyText(11.5, weight: FontWeight.w900).copyWith(height: 1),
        ),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: SkyColors.ink,
        ),
      ],
    ),
  );
}

/// One value in a single row: a key either side, and between them what it
/// is, its value (or a [picture] of it) and a [hint] with its unit.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.name,
    required this.caption,
    required this.value,
    required this.onLess,
    required this.onMore,
    this.hint,
    this.picture,
    this.lessIcon = Icons.remove_rounded,
    this.moreIcon = Icons.add_rounded,
    this.lessTip,
    this.moreTip,
    this.alongRoute = false,
  });

  /// What is stepped, for the keys' names: "height" makes `height-less`.
  final String name;

  /// The keys step along the route, which runs left to right in every
  /// language as the sky does: earlier on the left, later on the right.
  final bool alongRoute;
  final String caption, value;
  final String? hint, lessTip, moreTip;
  final Widget? picture;
  final VoidCallback? onLess, onMore;
  final IconData lessIcon, moreIcon;

  @override
  Widget build(BuildContext context) {
    final small = bodyText(
      10.5,
      color: SkyColors.muted,
      weight: FontWeight.w900,
    ).copyWith(height: 1.05);
    final l = context.l10n;
    final less = BuilderKey(
      key: ValueKey('$name-less'),
      tooltip: lessTip ?? l.builderLessSemantics(caption),
      icon: lessIcon,
      sound: 'ui_toggle',
      onPressed: onLess,
    );
    final more = BuilderKey(
      key: ValueKey('$name-more'),
      tooltip: moreTip ?? l.builderMoreSemantics(caption),
      icon: moreIcon,
      sound: 'ui_toggle',
      onPressed: onMore,
    );
    final Widget middle = Semantics(
      label: hint == null
          ? l.builderStepSemantics(caption, value)
          : l.builderStepHintSemantics(caption, value, hint!),
      excludeSemantics: true,
      child: SizedBox(
        height: MapKey.size,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  L10n.upper(caption),
                  style: small.copyWith(letterSpacing: .9),
                ),
                picture ??
                    Text(
                      value,
                      style: heading(
                        20,
                        weight: FontWeight.w700,
                      ).copyWith(height: 1.12),
                    ),
                if (hint != null)
                  Text(
                    hint!,
                    style: small.copyWith(fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!alongRoute) {
      return Row(
        children: [
          less,
          Expanded(child: middle),
          more,
        ],
      );
    }
    // The keys keep the route's order (earlier on the left, as in the
    // sky); the words between them keep the language's own direction.
    return FlightDirection(
      child: Row(
        children: [
          less,
          Expanded(child: LanguageDirection(child: middle)),
          more,
        ],
      ),
    );
  }
}

/// A caption over a row of keys.
class _Group extends StatelessWidget {
  const _Group(this.caption, {this.trailing, required this.child});
  final String caption;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = bodyText(
      11,
      color: SkyColors.muted,
      weight: FontWeight.w900,
    ).copyWith(height: 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 4),
          child: Row(
            children: [
              Text(
                L10n.upper(caption),
                style: style.copyWith(letterSpacing: 1.1),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                // A long note shrinks to the room left rather than past it,
                // or takes a second line when that would make it too small.
                Expanded(
                  child: _Trailing(
                    trailing!,
                    style: style.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// A group's note beside its caption, at the line's end: one line,
/// shrunk a little if need be, or two lines when one would have to shrink
/// past [_shrink] (a long translation).
class _Trailing extends StatelessWidget {
  const _Trailing(this.text, {required this.style});
  final String text;
  final TextStyle style;

  static const _shrink = .8;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      if (width * _shrink <= box.maxWidth) {
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FitText(text, style: style),
        );
      }
      return Text(
        text,
        maxLines: 2,
        textAlign: TextAlign.end,
        style: style.copyWith(height: 1.1),
      );
    },
  );
}

/// Height as a share of the sky from the bottom: "55 %".
String _height(AppLocalizations l, int y) =>
    l.builderPercent(((BuiltPlan.unit - y) / 10).round());

/// The route position as seconds from the start: "12.4 s".
String _along(AppLocalizations l, BuiltPlan plan, int x) =>
    l.builtSeconds(BuiltReach.secondsTo(plan, x), digits: 1);

/// A length of route as seconds of flight: "2.2 s".
String _seconds(AppLocalizations l, BuiltPlan plan, int length) {
  final s = length / BuiltPlan.unit / BuiltReach.cruise(plan);
  return l.builtSeconds(s, digits: s < 10 ? 1 : 0);
}

/// Moves [item] along the route by [dx], never into the start zone.
BuiltItem _nudged(BuiltItem item, int dx) {
  final x = math.max(BuiltPlan.firstX + (item.x - item.left), item.x + dx);
  return item.movedTo(x: x);
}

class _GateInspector extends StatelessWidget {
  const _GateInspector({
    super.key,
    required this.controller,
    required this.gate,
  });
  final BuilderController controller;
  final BuiltGate gate;

  static const _gapStep = 20, _heightStep = 25, _alongStep = 100;
  static const _cycles = [1500, BuiltGate.defaultCycle, 4000];

  void _set(BuiltGate next) {
    // An opening never shrinks below what the bird needs.
    final mode = controller.mode;
    final safe = BuiltPlan.safeGap(mode, next.y, next.amp);
    if (next.gap < safe) {
      next = next.copyWith(gap: math.min(safe, BuiltPlan.maxGap(mode)));
    }
    controller.updateSelected(next);
  }

  Future<void> _pickFamily(BuildContext context) async {
    final plan = controller.plan;
    final gentle = (BuiltPlan.maxAmp(controller.mode) / 2).round();
    final kind = await showFamilySheet(
      context,
      region: plan.region,
      selected: gate.kind,
    );
    if (kind == null || kind == gate.kind) return;
    _set(
      gate.copyWith(
        kind: kind,
        // A garden gate stands still; a moving family starts gently.
        amp: kind == ObstacleKind.garden
            ? 0
            : gate.amp == 0
            ? gentle
            : gate.amp,
        door: kind == ObstacleKind.garden && gate.door,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mode = controller.mode;
    final plan = controller.plan;
    final safe = BuiltPlan.safeGap(mode, gate.y, gate.amp);
    final maxGap = BuiltPlan.maxGap(mode);
    final maxAmp = BuiltPlan.maxAmp(mode);
    final gentle = (maxAmp / 2).round();
    final garden = gate.kind == ObstacleKind.garden;
    final motion = gate.amp == 0
        ? 0
        : gate.amp <= gentle
        ? 1
        : 2;
    final cycle = _cycles.reduce(
      (a, b) => (a - gate.cycle).abs() <= (b - gate.cycle).abs() ? a : b,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FamilyButton(
          key: const ValueKey('gate-family'),
          kind: gate.kind,
          region: plan.region,
          onPressed: () => _pickFamily(context),
        ),
        Expanded(
          child: _Body(
            children: [
              if (mode.controlsHeight)
                _Group(
                  l.builderLane,
                  trailing: l.builderLaneHint(l.builtMovement(mode)),
                  child: BuilderChoice<int>(
                    values: const [BuiltPlan.highLane, BuiltPlan.lowLane],
                    selected: gate.y,
                    label: (y) => y == BuiltPlan.highLane
                        ? l.builderLaneTop
                        : l.builderLaneBottom,
                    onSelected: (y) => _set(gate.copyWith(y: y)),
                  ),
                )
              else
                _StepRow(
                  name: 'height',
                  caption: l.builderHeight,
                  value: _height(l, gate.y),
                  hint: l.builderHeightHint,
                  lessIcon: Icons.arrow_downward_rounded,
                  moreIcon: Icons.arrow_upward_rounded,
                  lessTip: l.builderLowerSemantics,
                  moreTip: l.builderHigherSemantics,
                  onLess: gate.y >= BuiltPlan.maxGateY
                      ? null
                      : () => _set(
                          gate.copyWith(
                            y: math.min(
                              BuiltPlan.maxGateY,
                              gate.y + _heightStep,
                            ),
                          ),
                        ),
                  onMore: gate.y <= BuiltPlan.minGateY
                      ? null
                      : () => _set(
                          gate.copyWith(
                            y: math.max(
                              BuiltPlan.minGateY,
                              gate.y - _heightStep,
                            ),
                          ),
                        ),
                ),
              _StepRow(
                name: 'opening',
                caption: l.builderOpening,
                value: l.builderPercent((gate.gap / 10).round()),
                hint: l.builderOpeningHint((safe / 10).round()),
                lessTip: l.builderNarrowerSemantics,
                moreTip: l.builderWiderSemantics,
                onLess: gate.gap <= safe
                    ? null
                    : () => _set(
                        gate.copyWith(gap: math.max(safe, gate.gap - _gapStep)),
                      ),
                onMore: gate.gap >= maxGap
                    ? null
                    : () => _set(
                        gate.copyWith(
                          gap: math.min(maxGap, gate.gap + _gapStep),
                        ),
                      ),
              ),
              _Group(
                l.builderMotion,
                trailing: garden ? l.builderMotionGardenHint : null,
                child: BuilderChoice<int>(
                  values: const [0, 1, 2],
                  selected: motion,
                  labelSize: 12.5,
                  spacing: 4,
                  label: (m) => [
                    l.builderMotionStill,
                    l.builderMotionGentle,
                    l.builderMotionLively,
                  ][m],
                  enabled: (m) => m == 0 || !garden,
                  onDisabled: (_) =>
                      BuilderToast.warn(context, l.builderMotionGardenToast),
                  onSelected: (m) => _set(
                    gate.copyWith(
                      amp: m == 0
                          ? 0
                          : m == 1
                          ? gentle
                          : maxAmp,
                    ),
                  ),
                ),
              ),
              if (gate.moving) ...[
                _Group(
                  l.builderSway,
                  trailing: l.builderSwayHint(_seconds(l, plan, gate.cycle)),
                  child: BuilderChoice<int>(
                    values: _cycles,
                    selected: cycle,
                    label: (c) => switch (_cycles.indexOf(c)) {
                      0 => l.builderSwayFast,
                      1 => l.builderSwayMedium,
                      _ => l.builderSwaySlow,
                    },
                    labelSize: 12.5,
                    spacing: 4,
                    onSelected: (c) => _set(gate.copyWith(cycle: c)),
                  ),
                ),
                _StepRow(
                  name: 'phase',
                  caption: l.builderPhase,
                  value: l.builderPhaseValue((gate.phase / 45).round() + 1, 8),
                  hint: l.builderPhaseHint,
                  picture: CustomPaint(
                    size: const Size(64, 22),
                    painter: _SwayPainter(gate.phase),
                  ),
                  lessIcon: Icons.rotate_left_rounded,
                  moreIcon: Icons.rotate_right_rounded,
                  lessTip: l.builderPhaseEarlierSemantics,
                  moreTip: l.builderPhaseLaterSemantics,
                  onLess: () =>
                      _set(gate.copyWith(phase: (gate.phase + 315) % 360)),
                  onMore: () =>
                      _set(gate.copyWith(phase: (gate.phase + 45) % 360)),
                ),
              ],
              _Group(
                l.builderLook,
                child: Row(
                  children: [
                    for (var look = 0; look < BuiltGate.looks; look++) ...[
                      if (look > 0) const SizedBox(width: 6),
                      Expanded(
                        child: BuilderKey(
                          key: ValueKey('gate-look-$look'),
                          tooltip: l.builderLookSemantics(look + 1),
                          selected: gate.look == look,
                          sound: 'ui_toggle',
                          art: SizedBox(
                            width: 40,
                            height: 40,
                            child: CustomPaint(
                              painter: _LookPainter(
                                gate.kind,
                                plan.region,
                                look,
                              ),
                            ),
                          ),
                          onPressed: () => _set(gate.copyWith(look: look)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (mode == PlayMode.touch && garden)
                _Group(
                  l.builderDoor,
                  trailing: l.builderDoorHint,
                  child: BuilderChoice<bool>(
                    values: const [false, true],
                    selected: gate.door,
                    label: (on) => on ? l.builderDoor : l.builderDoorNone,
                    labelSize: 13,
                    enabled: (on) => !on || plan.shoot,
                    onDisabled: (_) => BuilderToast.warn(
                      context,
                      l.builderDoorNeedsShootToast,
                    ),
                    onSelected: (on) => _set(gate.copyWith(door: on)),
                  ),
                ),
              _StepRow(
                name: 'place',
                caption: l.builderPlace,
                value: _along(l, plan, gate.x),
                hint: l.builderPlaceHint,
                lessIcon: Icons.arrow_back_rounded,
                moreIcon: Icons.arrow_forward_rounded,
                lessTip: l.builderEarlierSemantics,
                moreTip: l.builderLaterSemantics,
                alongRoute: true,
                onLess: gate.x <= BuiltPlan.firstX
                    ? null
                    : () =>
                          controller.updateSelected(_nudged(gate, -_alongStep)),
                onMore: () =>
                    controller.updateSelected(_nudged(gate, _alongStep)),
              ),
            ],
          ),
        ),
        _Footer(controller: controller),
      ],
    );
  }
}

/// The selected gate's family at the top of the panel, as a key: a little
/// picture of the gate in its sky, its name, and Change, which opens the
/// families.
class _FamilyButton extends StatefulWidget {
  const _FamilyButton({
    super.key,
    required this.kind,
    required this.region,
    required this.onPressed,
  });
  final ObstacleKind kind;
  final WorldRegion region;
  final VoidCallback onPressed;

  @override
  State<_FamilyButton> createState() => _FamilyButtonState();
}

class _FamilyButtonState extends State<_FamilyButton> {
  bool pressed = false;

  void _press() {
    UiSounds.effect(context);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final still = MediaQuery.disableAnimationsOf(context);
    final sink = pressed && !still ? 2.0 : 0.0;
    final family = l.gateFamilyName(widget.kind);
    return Semantics(
      button: true,
      label: l.builderFamilySemantics(family),
      excludeSemantics: true,
      onTap: _press,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: _press,
          onHighlightChanged: (value) => setState(() => pressed = value),
          child: Container(
            padding: const EdgeInsets.fromLTRB(9, 7, 10, 8),
            decoration: BoxDecoration(
              color: pressed
                  ? const Color(0xfff6e2bd)
                  : const Color(0xfffff1d6),
              border: const Border(
                bottom: BorderSide(color: SkyColors.ink, width: 2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SkyColors.ink, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RegionThumb(
                          region: widget.region,
                          radius: 0,
                          outline: 0,
                        ),
                        CustomPaint(
                          painter: _FamilyScenePainter(
                            widget.kind,
                            widget.region,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FitText(
                        family,
                        style: heading(17.5, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      // The family changes from here: a small key-like tag.
                      Transform.translate(
                        offset: Offset(0, sink),
                        child: Container(
                          height: 24,
                          padding: const EdgeInsets.fromLTRB(5, 0, 9, 0),
                          decoration: BoxDecoration(
                            color: SkyColors.cream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: SkyColors.ink,
                              width: 1.8,
                            ),
                            boxShadow: [
                              if (sink == 0)
                                BoxShadow(
                                  color: SkyColors.ink.withValues(alpha: .35),
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.swap_horiz_rounded,
                                size: 15,
                                color: SkyColors.ink,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: FitText(
                                  l.builderChangeFamily,
                                  style: bodyText(
                                    11.5,
                                    weight: FontWeight.w900,
                                  ).copyWith(height: 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: SkyColors.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One sway as a wave, with a dot where the gate is as the bird arrives.
class _SwayPainter extends CustomPainter {
  const _SwayPainter(this.phase);
  final int phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final dot = h * .24;
    final amp = h / 2 - dot - 1;
    double y(double t) => h / 2 + math.sin(t * math.pi * 2) * amp;
    final wave = Path()..moveTo(dot, y(0));
    for (var i = 1; i <= 32; i++) {
      final t = i / 32;
      wave.lineTo(dot + t * (w - dot * 2), y(t));
    }
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = SkyColors.ink.withValues(alpha: .45),
    );
    final t = phase / 360;
    final at = Offset(dot + t * (w - dot * 2), y(t));
    canvas.drawCircle(at, dot, Paint()..color = SkyColors.gold);
    canvas.drawCircle(
      at,
      dot,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = SkyColors.ink,
    );
  }

  @override
  bool shouldRepaint(_SwayPainter old) => old.phase != phase;
}

/// A gate family's [look] as a close-up icon.
class _LookPainter extends CustomPainter {
  const _LookPainter(this.kind, this.region, this.look);
  final ObstacleKind kind;
  final WorldRegion region;
  final int look;

  @override
  void paint(Canvas canvas, Size size) {
    // Floating families show their orbs, whose colour is the look.
    if (kind.floating) {
      BuilderArt.gateIcon(canvas, size, kind, region: region, look: look);
      return;
    }
    // A wall's make is its look: close in on the upper wall over the
    // opening, its foot low in the box.
    final h = size.width * .6 / kind.width;
    final wall = kind.width * h;
    const y = 500, gap = 300;
    final foot = (y - gap / 2) / BuiltPlan.unit * h;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - wall) / 2, size.height * .8 - foot);
    BuilderArt.gate(
      canvas,
      h,
      BuiltGate(x: 0, y: y, gap: gap, kind: kind, look: look),
      mode: PlayMode.touch,
      x: 0,
      region: region,
      aim: false,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LookPainter old) =>
      old.kind != kind || old.region != region || old.look != look;
}

class _ItemInspector extends StatelessWidget {
  const _ItemInspector({
    super.key,
    required this.controller,
    required this.item,
  });
  final BuilderController controller;
  final BuiltItem item;

  static const _heightStep = 25, _alongStep = 100;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = controller.plan;
    final (title, line) = switch (item) {
      BuiltStar() => (l.builderItemStar, l.builderItemStarDetail),
      BuiltTrio() => (l.builderItemTrio, l.builderItemTrioDetail),
      BuiltHeart() => (l.builderItemHeart, l.builderItemHeartDetail),
      BuiltEnemy enemy => (l.builderItemEnemy, l.builtEnemyName(enemy.kind)),
      BuiltGate() => (l.builderItemGate, ''),
    };
    final y = item.y;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: title,
          subtitle: line,
          art: SizedBox.square(
            dimension: 36,
            child: CustomPaint(painter: _ItemPainter(item)),
          ),
        ),
        Expanded(
          child: _Body(
            children: [
              if (item case final BuiltEnemy enemy)
                _Group(
                  l.builderEnemyKind,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final kind in enemyKinds)
                        BuilderKey(
                          key: ValueKey('enemy-${kind.name}'),
                          tooltip: l.builtEnemyName(kind),
                          width: 48,
                          height: 48,
                          selected: kind == enemy.kind,
                          sound: 'ui_toggle',
                          art: SizedBox.square(
                            dimension: 36,
                            child: CustomPaint(painter: _EnemyPainter(kind)),
                          ),
                          onPressed: () => controller.updateSelected(
                            BuiltEnemy(x: enemy.x, y: enemy.y, kind: kind),
                          ),
                        ),
                    ],
                  ),
                ),
              _StepRow(
                name: 'height',
                caption: l.builderHeight,
                value: _height(l, y),
                hint: l.builderHeightHint,
                lessIcon: Icons.arrow_downward_rounded,
                moreIcon: Icons.arrow_upward_rounded,
                lessTip: l.builderLowerSemantics,
                moreTip: l.builderHigherSemantics,
                onLess: y >= BuiltPlan.maxItemY
                    ? null
                    : () => controller.updateSelected(
                        item.movedTo(
                          y: math.min(BuiltPlan.maxItemY, y + _heightStep),
                        ),
                      ),
                onMore: y <= BuiltPlan.minItemY
                    ? null
                    : () => controller.updateSelected(
                        item.movedTo(
                          y: math.max(BuiltPlan.minItemY, y - _heightStep),
                        ),
                      ),
              ),
              _StepRow(
                name: 'place',
                caption: l.builderPlace,
                value: _along(l, plan, item.x),
                hint: l.builderPlaceHint,
                lessIcon: Icons.arrow_back_rounded,
                moreIcon: Icons.arrow_forward_rounded,
                lessTip: l.builderEarlierSemantics,
                moreTip: l.builderLaterSemantics,
                alongRoute: true,
                onLess: item.left <= BuiltPlan.firstX
                    ? null
                    : () =>
                          controller.updateSelected(_nudged(item, -_alongStep)),
                onMore: () =>
                    controller.updateSelected(_nudged(item, _alongStep)),
              ),
              if (controller.mode.controlsHeight && item is! BuiltEnemy)
                _Note(
                  icon: Icons.lightbulb_rounded,
                  text: l.builderPickupLanesNote(
                    l.builtMovement(controller.mode),
                  ),
                ),
            ],
          ),
        ),
        _Footer(controller: controller),
      ],
    );
  }
}

/// The enemies a built level may hold.
const enemyKinds = [
  EnemyKind.simpleBat,
  EnemyKind.caveBat,
  EnemyKind.spitterBeetle,
  EnemyKind.duskMoth,
];

/// The level at a glance, when nothing is selected.
class _LevelSummary extends StatelessWidget {
  const _LevelSummary({required this.controller});
  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = controller.plan;
    final level = controller.level;
    final reps = builtReps(plan, l);
    final marks = plan.marks;
    final factLabel = bodyText(
      13,
      color: SkyColors.muted,
      weight: FontWeight.w800,
    );
    final factValue = heading(15, weight: FontWeight.w700);
    Widget factRow(IconData icon, String label, Widget? value) => Row(
      children: [
        Icon(icon, size: 18, color: SkyColors.muted),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: factLabel)),
        ?value,
      ],
    );
    Widget fact(IconData icon, String label, Object value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: value is Widget
          ? factRow(icon, label, value)
          : LayoutBuilder(
              builder: (context, box) {
                final words = '$value';
                double width(String text, TextStyle style) {
                  final painter = TextPainter(
                    text: TextSpan(text: text, style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: 1,
                  )..layout();
                  final w = painter.width;
                  painter.dispose();
                  return w;
                }

                if (26 +
                        width(label, factLabel) +
                        8 +
                        width(words, factValue) <=
                    box.maxWidth) {
                  return factRow(icon, label, Text(words, style: factValue));
                }
                // A long value (a boss's whole name in some languages)
                // takes its own lines under the label rather than overflow.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    factRow(icon, label, null),
                    Text(words, style: factValue, textAlign: TextAlign.end),
                  ],
                );
              },
            ),
    );
    final mark = heading(15, weight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: Color(0xfffff1d6),
            border: Border(bottom: BorderSide(color: SkyColors.ink, width: 2)),
          ),
          child: Row(
            children: [
              ControlGlyph(builtControl(plan.mode), size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FitText(
                      l.builderSummaryTitle,
                      style: heading(19, weight: FontWeight.w700),
                    ),
                    FitText(
                      l.builderModeRegion(
                        builtModeName(plan.mode, l),
                        l.regionName(plan.region),
                      ),
                      style: bodyText(11.5, color: SkyColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _Body(
            children: [
              Column(
                children: [
                  fact(
                    Icons.timer_rounded,
                    l.builderFactLength,
                    builtLength(plan, l),
                  ),
                  fact(
                    Icons.star_rounded,
                    l.builderFactStars,
                    '${plan.totalStars}',
                  ),
                  fact(
                    Icons.military_tech_rounded,
                    l.builderFactMarks,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BuilderStars(earned: 2, of: 2, size: 12),
                        Text(' ${marks.two}   ', style: mark),
                        const BuilderStars(earned: 3, of: 3, size: 12),
                        Text(' ${marks.three}', style: mark),
                      ],
                    ),
                  ),
                  if (reps != null)
                    fact(
                      Icons.fitness_center_rounded,
                      l.builderFactWorkout,
                      reps,
                    ),
                  fact(
                    Icons.speed_rounded,
                    l.builderFactPace,
                    l.builtPaceName(plan.pace),
                  ),
                  if (plan.boss != null)
                    fact(
                      Icons.shield_rounded,
                      l.builderFactBoss,
                      l.bossName(plan.boss!),
                    ),
                ],
              ),
              if (controller.readOnly)
                _Note(
                  icon: Icons.auto_fix_high_rounded,
                  text: l.builderSummaryStarterNote,
                )
              else if (level.cleared)
                _Note(
                  icon: Icons.verified_rounded,
                  color: SkyColors.mint,
                  text: l.builderSummaryClearedNote,
                )
              else
                _Note(
                  icon: Icons.flag_rounded,
                  text: plan.boss == null
                      ? l.builderSummaryClearNote
                      : l.builderSummaryClearBossNote(
                          l.bossName(plan.boss!),
                          plan.boss!.name,
                        ),
                ),
              if (!controller.readOnly)
                _Note(
                  icon: Icons.touch_app_rounded,
                  color: SkyColors.cream,
                  text: l.builderSummaryHowTo,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.text,
    this.color = SkyColors.yellow,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
    decoration: BoxDecoration(
      color: Color.lerp(color, SkyColors.cream, .55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: SkyColors.ink.withValues(alpha: .5),
        width: 1.5,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SkyColors.ink),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: bodyText(12.5))),
      ],
    ),
  );
}

/// What each gate family does, for its card, in [l]'s language
/// ([L10n.strings] by default).
String familyLine(ObstacleKind kind, [AppLocalizations? l]) =>
    (l ?? L10n.strings).gateFamilyDetail(kind);

/// The seven gate families as cards, drawn in [region] as the flight draws
/// them, a moving family with a faint second pose. Returns the one picked.
Future<ObstacleKind?> showFamilySheet(
  BuildContext context, {
  required WorldRegion region,
  required ObstacleKind selected,
}) => showBuilderSheet<ObstacleKind>(
  context,
  label: context.l10n.builderFamiliesCloseSemantics,
  builder: (context) => Padding(
    padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
    child: Column(
      children: [
        BuilderSheetTitle(
          title: context.l10n.builderFamiliesTitle,
          subtitle: context.l10n.builderFamiliesSubtitle,
          closeLabel: context.l10n.builderFamiliesCloseSemantics,
        ),
        const SizedBox(height: 12),
        for (final row in const [
          [
            ObstacleKind.garden,
            ObstacleKind.windLift,
            ObstacleKind.petalGate,
            ObstacleKind.switchback,
          ],
          [
            ObstacleKind.lanternDrift,
            ObstacleKind.sunWheels,
            ObstacleKind.crystalSteps,
            null,
          ],
        ]) ...[
          if (row.first != ObstacleKind.garden) const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, kind) in row.indexed) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(
                    child: kind == null
                        ? const SizedBox()
                        : PressCard(
                            key: ValueKey('family-${kind.name}'),
                            label: context.l10n.builderFamilyCardSemantics(
                              context.l10n.gateFamilyName(kind),
                              context.l10n.gateFamilyDetail(kind),
                            ),
                            selected: kind == selected,
                            radius: 18,
                            accent: kind == selected
                                ? SkyColors.gold
                                : SkyColors.teal,
                            onPressed: () => Navigator.of(context).pop(kind),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 86,
                                  child: DecoratedBox(
                                    position: DecorationPosition.foreground,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: SkyColors.ink,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        RegionThumb(
                                          region: region,
                                          radius: 0,
                                          outline: 0,
                                        ),
                                        CustomPaint(
                                          painter: _FamilyScenePainter(
                                            kind,
                                            region,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      8,
                                      8,
                                      8,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.l10n.gateFamilyName(kind),
                                          style: heading(
                                            17,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          context.l10n.gateFamilyDetail(kind),
                                          style: bodyText(
                                            12.5,
                                            color: SkyColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    ),
  ),
);

/// A gate of [kind] standing in its sky, as tall as the box: a moving
/// family shows a faint second pose half a swing on.
class _FamilyScenePainter extends CustomPainter {
  const _FamilyScenePainter(this.kind, this.region);
  final ObstacleKind kind;
  final WorldRegion region;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final moving = kind != ObstacleKind.garden;
    BuiltGate pose(int phase) => BuiltGate(
      x: 0,
      y: 500,
      gap: 400,
      kind: kind,
      amp: moving ? 80 : 0,
      phase: phase,
    );
    final x = (size.width / h - kind.width) / 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (moving) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = SkyColors.white.withValues(alpha: .38),
      );
      BuilderArt.gate(
        canvas,
        h,
        pose(270),
        mode: PlayMode.touch,
        x: x,
        region: region,
        aim: false,
      );
      canvas.restore();
    }
    BuilderArt.gate(
      canvas,
      h,
      pose(90),
      mode: PlayMode.touch,
      x: x,
      region: region,
      aim: false,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FamilyScenePainter old) =>
      old.kind != kind || old.region != region;
}

class _ItemPainter extends CustomPainter {
  const _ItemPainter(this.item);
  final BuiltItem item;

  @override
  void paint(Canvas canvas, Size size) => switch (item) {
    BuiltEnemy(:final kind) => BuilderArt.enemyIcon(canvas, size, kind),
    BuiltHeart() => BuilderArt.heartIcon(canvas, size),
    BuiltTrio() => () {
      final sky = size.width * .17 / StarArt.radius;
      for (var i = -1; i <= 1; i++) {
        BuilderArt.star(
          canvas,
          sky,
          size.center(Offset(i * size.width * .32, i == 0 ? -4 : 3)),
        );
      }
    }(),
    _ => BuilderArt.starIcon(canvas, size),
  };

  @override
  bool shouldRepaint(_ItemPainter old) => old.item != item;
}

class _EnemyPainter extends CustomPainter {
  const _EnemyPainter(this.kind);
  final EnemyKind kind;

  @override
  void paint(Canvas canvas, Size size) =>
      BuilderArt.enemyIcon(canvas, size, kind);

  @override
  bool shouldRepaint(_EnemyPainter old) => old.kind != kind;
}
