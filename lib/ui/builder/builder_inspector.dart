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
              Text(
                title,
                maxLines: 1,
                style: heading(19, weight: FontWeight.w700),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyText(11.5, color: SkyColors.muted),
              ),
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
  Widget build(BuildContext context) => Container(
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
            tooltip: 'Duplicate',
            label: 'Copy',
            icon: Icons.copy_all_rounded,
            labelSize: 14,
            onPressed: controller.duplicateSelected,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BuilderKey(
            key: const ValueKey('inspector-delete'),
            tooltip: 'Delete',
            label: 'Delete',
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
          'More below',
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
  });

  /// What is stepped, for the keys' names: "height" makes `height-less`.
  final String name;
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
    return Row(
      children: [
        BuilderKey(
          key: ValueKey('$name-less'),
          tooltip: lessTip ?? 'Less $name',
          icon: lessIcon,
          sound: 'ui_toggle',
          onPressed: onLess,
        ),
        Expanded(
          child: Semantics(
            label: '$caption $value${hint == null ? '' : ', $hint'}',
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
                        caption.toUpperCase(),
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
          ),
        ),
        BuilderKey(
          key: ValueKey('$name-more'),
          tooltip: moreTip ?? 'More $name',
          icon: moreIcon,
          sound: 'ui_toggle',
          onPressed: onMore,
        ),
      ],
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
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Row(
            children: [
              Text(
                caption.toUpperCase(),
                style: style.copyWith(letterSpacing: 1.1),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                // A long note shrinks to the room left rather than past it.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        trailing!,
                        style: style.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
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

/// Height as a share of the sky from the bottom: "55 %".
String _height(int y) => '${((BuiltPlan.unit - y) / 10).round()} %';

/// The route position as seconds from the start: "12.4 s".
String _along(BuiltPlan plan, int x) =>
    '${BuiltReach.secondsTo(plan, x).toStringAsFixed(1)} s';

/// A length of route as seconds of flight: "2.2 s".
String _seconds(BuiltPlan plan, int length) {
  final s = length / BuiltPlan.unit / BuiltReach.cruise(plan);
  return '${s.toStringAsFixed(s < 10 ? 1 : 0)} s';
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
                  'Lane',
                  trailing: mode == PlayMode.squat
                      ? 'top or bottom of the squat'
                      : 'top or bottom of the push-up',
                  child: BuilderChoice<int>(
                    values: const [BuiltPlan.highLane, BuiltPlan.lowLane],
                    selected: gate.y,
                    label: (y) => y == BuiltPlan.highLane ? 'Top' : 'Bottom',
                    onSelected: (y) => _set(gate.copyWith(y: y)),
                  ),
                )
              else
                _StepRow(
                  name: 'height',
                  caption: 'Height',
                  value: _height(gate.y),
                  hint: 'of the sky',
                  lessIcon: Icons.arrow_downward_rounded,
                  moreIcon: Icons.arrow_upward_rounded,
                  lessTip: 'Lower',
                  moreTip: 'Higher',
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
                caption: 'Opening',
                value: '${(gate.gap / 10).round()} %',
                hint: 'at least ${(safe / 10).round()} %',
                lessTip: 'Narrower',
                moreTip: 'Wider',
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
                'Motion',
                trailing: garden ? 'garden gates stand still' : null,
                child: BuilderChoice<int>(
                  values: const [0, 1, 2],
                  selected: motion,
                  labelSize: 12.5,
                  spacing: 4,
                  label: (m) => const ['Still', 'Gentle', 'Lively'][m],
                  enabled: (m) => m == 0 || !garden,
                  onDisabled: (_) => BuilderToast.warn(
                    context,
                    'Garden gates stand still: pick another family to '
                    'make it move.',
                  ),
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
                  'Sway',
                  trailing: 'one sway: ${_seconds(plan, gate.cycle)}',
                  child: BuilderChoice<int>(
                    values: _cycles,
                    selected: cycle,
                    label: (c) => switch (_cycles.indexOf(c)) {
                      0 => 'Fast',
                      1 => 'Medium',
                      _ => 'Slow',
                    },
                    labelSize: 12.5,
                    spacing: 4,
                    onSelected: (c) => _set(gate.copyWith(cycle: c)),
                  ),
                ),
                _StepRow(
                  name: 'phase',
                  caption: 'As you arrive',
                  value: '${(gate.phase / 45).round() + 1} of 8',
                  hint: 'where it is in its sway',
                  picture: CustomPaint(
                    size: const Size(64, 22),
                    painter: _SwayPainter(gate.phase),
                  ),
                  lessIcon: Icons.rotate_left_rounded,
                  moreIcon: Icons.rotate_right_rounded,
                  lessTip: 'Earlier in its sway',
                  moreTip: 'Later in its sway',
                  onLess: () =>
                      _set(gate.copyWith(phase: (gate.phase + 315) % 360)),
                  onMore: () =>
                      _set(gate.copyWith(phase: (gate.phase + 45) % 360)),
                ),
              ],
              _Group(
                'Look',
                child: Row(
                  children: [
                    for (var look = 0; look < BuiltGate.looks; look++) ...[
                      if (look > 0) const SizedBox(width: 6),
                      Expanded(
                        child: BuilderKey(
                          key: ValueKey('gate-look-$look'),
                          tooltip: 'Look ${look + 1}',
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
                  'Stone door',
                  trailing: 'shoot it open',
                  child: BuilderChoice<bool>(
                    values: const [false, true],
                    selected: gate.door,
                    label: (on) => on ? 'Stone door' : 'No door',
                    labelSize: 13,
                    enabled: (on) => !on || plan.shoot,
                    onDisabled: (_) => BuilderToast.warn(
                      context,
                      'Turn Shoot on in the level’s settings to use doors.',
                    ),
                    onSelected: (on) => _set(gate.copyWith(door: on)),
                  ),
                ),
              _StepRow(
                name: 'place',
                caption: 'Place',
                value: _along(plan, gate.x),
                hint: 'from the start',
                lessIcon: Icons.arrow_back_rounded,
                moreIcon: Icons.arrow_forward_rounded,
                lessTip: 'Earlier',
                moreTip: 'Later',
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
    final still = MediaQuery.disableAnimationsOf(context);
    final sink = pressed && !still ? 2.0 : 0.0;
    return Semantics(
      button: true,
      label: 'Gate family: ${widget.kind.title}. Change',
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
                      Text(
                        widget.kind.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                              Text(
                                'Change family',
                                style: bodyText(
                                  11.5,
                                  weight: FontWeight.w900,
                                ).copyWith(height: 1),
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
    final plan = controller.plan;
    final (title, line) = switch (item) {
      BuiltStar() => ('Star', 'One star to collect'),
      BuiltTrio() => ('Star trio', 'All three pay a bonus'),
      BuiltHeart() => ('Heart', 'One heart back'),
      BuiltEnemy enemy => ('Enemy', _enemyName(enemy.kind)),
      BuiltGate() => ('Gate', ''),
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
                  'Kind',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final kind in enemyKinds)
                        BuilderKey(
                          key: ValueKey('enemy-${kind.name}'),
                          tooltip: _enemyName(kind),
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
                caption: 'Height',
                value: _height(y),
                hint: 'of the sky',
                lessIcon: Icons.arrow_downward_rounded,
                moreIcon: Icons.arrow_upward_rounded,
                lessTip: 'Lower',
                moreTip: 'Higher',
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
                caption: 'Place',
                value: _along(plan, item.x),
                hint: 'from the start',
                lessIcon: Icons.arrow_back_rounded,
                moreIcon: Icons.arrow_forward_rounded,
                lessTip: 'Earlier',
                moreTip: 'Later',
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
                  text:
                      'The bird flies the top and bottom of each '
                      '${controller.mode == PlayMode.squat ? 'squat' : 'push-up'}: '
                      'put pickups on or between the yellow lines.',
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

String _enemyName(EnemyKind kind) => switch (kind) {
  EnemyKind.simpleBat => 'Purple bat',
  EnemyKind.caveBat => 'Cave bat',
  EnemyKind.spitterBeetle => 'Spitter beetle',
  EnemyKind.duskMoth => 'Dusk moth',
  EnemyKind.alleyPigeon => 'Alley pigeon',
  EnemyKind.mummyBat => 'Mummy bat',
};

/// The level at a glance, when nothing is selected.
class _LevelSummary extends StatelessWidget {
  const _LevelSummary({required this.controller});
  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final plan = controller.plan;
    final level = controller.level;
    final reps = builtReps(plan);
    final marks = plan.marks;
    Widget fact(IconData icon, String label, Object value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SkyColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: bodyText(
                13,
                color: SkyColors.muted,
                weight: FontWeight.w800,
              ),
            ),
          ),
          if (value is Widget)
            value
          else
            Text('$value', style: heading(15, weight: FontWeight.w700)),
        ],
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
                    Text(
                      'This level',
                      style: heading(19, weight: FontWeight.w700),
                    ),
                    Text(
                      '${builtModeName(plan.mode)} · ${plan.region.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  fact(Icons.timer_rounded, 'Length', builtLength(plan)),
                  fact(Icons.star_rounded, 'Stars', '${plan.totalStars}'),
                  fact(
                    Icons.military_tech_rounded,
                    'Marks',
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
                    fact(Icons.fitness_center_rounded, 'Workout', reps),
                  fact(Icons.speed_rounded, 'Pace', switch (plan.pace) {
                    BuiltPace.relaxed => 'Relaxed',
                    BuiltPace.steady => 'Steady',
                    BuiltPace.brisk => 'Brisk',
                  }),
                  if (plan.boss != null)
                    fact(Icons.shield_rounded, 'Boss', bossName(plan.boss!)),
                ],
              ),
              if (controller.readOnly)
                const _Note(
                  icon: Icons.auto_fix_high_rounded,
                  text:
                      'A starter level to fly as it is, or remix into a '
                      'level of your own.',
                )
              else if (level.cleared)
                const _Note(
                  icon: Icons.verified_rounded,
                  color: SkyColors.mint,
                  text: 'Cleared by you: you flew it to the end.',
                )
              else
                _Note(
                  icon: Icons.flag_rounded,
                  text: plan.boss == null
                      ? 'Test fly it all the way to the finish to mark it '
                            'cleared.'
                      : 'Test fly it, beat ${bossName(plan.boss!)} and cross '
                            'the line to mark it cleared.',
                ),
              if (!controller.readOnly)
                const _Note(
                  icon: Icons.touch_app_rounded,
                  color: SkyColors.cream,
                  text:
                      'Pick a tool on the left, then tap the sky. Tap a '
                      'thing to change it; drag it to move it.',
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

/// What each gate family does, for its card.
String familyLine(ObstacleKind kind) => switch (kind) {
  ObstacleKind.garden => 'Stands still. Can hold a stone door.',
  ObstacleKind.windLift => 'The opening rises and falls.',
  ObstacleKind.petalGate => 'The opening narrows and widens.',
  ObstacleKind.switchback => 'Two openings that slide apart.',
  ObstacleKind.lanternDrift => 'Hanging lanterns that bob.',
  ObstacleKind.sunWheels => 'Wheels that close in and back.',
  ObstacleKind.crystalSteps => 'Three steps in a ripple.',
};

/// The seven gate families as cards, drawn in [region] as the flight draws
/// them, a moving family with a faint second pose. Returns the one picked.
Future<ObstacleKind?> showFamilySheet(
  BuildContext context, {
  required WorldRegion region,
  required ObstacleKind selected,
}) => showBuilderSheet<ObstacleKind>(
  context,
  label: 'Close gate families',
  builder: (context) => Padding(
    padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
    child: Column(
      children: [
        const BuilderSheetTitle(
          title: 'Gate family',
          subtitle: 'How the gate looks and moves.',
          closeLabel: 'Close gate families',
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
                            label: '${kind.title}. ${familyLine(kind)}',
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
                                          kind.title,
                                          style: heading(
                                            17,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          familyLine(kind),
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
