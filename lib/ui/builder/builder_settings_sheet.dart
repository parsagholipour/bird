import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/game_rules.dart';
import '../../domain/tracking.dart';
import '../mini_chrome.dart' show MiniCard;
import '../theme.dart';
import 'builder_chrome.dart';
import 'builder_controller.dart';
import 'builder_name_dialog.dart';
import 'builder_pickers.dart' show PressCard;

/// The level's settings over the editor: its name, region and pace, the
/// star marks, and for Tap & Fly the Shoot and Sprint controls and a boss
/// finale. Every change is made at once, and undoes like any edit.
Future<void> showBuilderSettings(
  BuildContext context,
  BuilderController controller,
) => showBuilderSheet<void>(
  context,
  label: 'Close settings',
  builder: (context) => _SettingsSheet(controller: controller),
);

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.controller});
  final BuilderController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final plan = controller.plan;
      return Padding(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
        child: Column(
          children: [
            BuilderSheetTitle(
              title: 'Level settings',
              subtitle: '${plan.mode.title} · changes save as you make them',
              closeLabel: 'Close settings',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: MiniCard(
                key: const ValueKey('settings-sheet'),
                accent: builtModeColor(plan.mode),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 52, child: _Left(controller: controller)),
                    Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      color: SkyColors.ink.withValues(alpha: .12),
                    ),
                    Expanded(flex: 48, child: _Right(controller: controller)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Left extends StatelessWidget {
  const _Left({required this.controller});
  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final plan = controller.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BuilderCaption('Name'),
        Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: heading(22, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            BuilderKey(
              key: const ValueKey('settings-rename'),
              tooltip: 'Rename',
              label: 'Rename',
              icon: Icons.edit_rounded,
              onPressed: () async {
                final name = await showBuilderNameDialog(context, plan.name);
                if (name != null) controller.settings(name: name);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        BuilderCaption(
          'Region',
          trailing: '${WorldRegion.values.length} places · swipe for more',
        ),
        _RegionStrip(controller: controller),
        const SizedBox(height: 6),
        const BuilderCaption('Pace', trailing: 'how fast the sky scrolls'),
        BuilderChoice<BuiltPace>(
          values: BuiltPace.values,
          selected: plan.pace,
          label: (pace) => switch (pace) {
            BuiltPace.relaxed => 'Relaxed',
            BuiltPace.steady => 'Steady',
            BuiltPace.brisk => 'Brisk',
          },
          onSelected: (pace) => controller.settings(pace: pace),
        ),
      ],
    );
  }
}

class _Right extends StatelessWidget {
  const _Right({required this.controller});
  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final plan = controller.plan;
    final marks = plan.marks;
    final stars = plan.totalStars;
    final auto = controller.draft.autoMarks;
    void setMarks(int two, int three) {
      final top = math.max(1, stars);
      final t = two.clamp(1, top);
      controller.settings(marks: StarMarks(t, three.clamp(t, top)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BuilderCaption(
          'Star marks',
          trailing: '$stars star${stars == 1 ? '' : 's'} placed',
        ),
        Row(
          children: [
            Expanded(
              child: BuilderStepper(
                name: 'two-star mark',
                value: '${marks.two}',
                lead: const BuilderStars(earned: 2, of: 2, size: 15),
                onLess: marks.two <= 1
                    ? null
                    : () => setMarks(marks.two - 1, marks.three),
                onMore: marks.two >= stars
                    ? null
                    : () => setMarks(
                        marks.two + 1,
                        math.max(marks.three, marks.two + 1),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BuilderStepper(
                name: 'three-star mark',
                value: '${marks.three}',
                lead: const BuilderStars(earned: 3, of: 3, size: 13),
                onLess: marks.three <= 1
                    ? null
                    : () => setMarks(
                        math.min(marks.two, marks.three - 1),
                        marks.three - 1,
                      ),
                onMore: marks.three >= stars
                    ? null
                    : () => setMarks(marks.two, marks.three + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BuilderChoice<bool>(
          values: const [true, false],
          selected: auto,
          label: (on) => on ? 'Auto: follow the stars' : 'Set by hand',
          labelSize: 13,
          onSelected: (on) => on
              ? controller.settings(autoMarks: true)
              : controller.settings(marks: marks),
        ),
        const SizedBox(height: 12),
        if (plan.touch) ...[
          const BuilderCaption('Controls'),
          Row(
            children: [
              Expanded(
                child: BuilderKey(
                  key: const ValueKey('settings-shoot'),
                  tooltip: 'Shoot ${plan.shoot ? 'on' : 'off'}',
                  label: 'Shoot ${plan.shoot ? 'on' : 'off'}',
                  icon: plan.shoot
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  selected: plan.shoot,
                  sound: 'ui_toggle',
                  onPressed: () => controller.settings(shoot: !plan.shoot),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BuilderKey(
                  key: const ValueKey('settings-sprint'),
                  tooltip: 'Sprint ${plan.sprint ? 'on' : 'off'}',
                  label: 'Sprint ${plan.sprint ? 'on' : 'off'}',
                  icon: plan.sprint
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  selected: plan.sprint,
                  sound: 'ui_toggle',
                  onPressed: () => controller.settings(sprint: !plan.sprint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const BuilderCaption('Boss finale', trailing: 'waits at the end'),
          SizedBox(
            height: 66,
            child: Row(
              children: [
                for (final (i, boss) in <BossKind?>[
                  null,
                  ...finaleBosses,
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(
                    child: BuilderKey(
                      key: ValueKey('settings-boss-${boss?.name ?? 'none'}'),
                      tooltip: boss == null
                          ? 'No boss: a finish line'
                          : bossName(boss),
                      label: boss == null ? 'None' : _short(boss),
                      vertical: true,
                      labelSize: 10.5,
                      height: 62,
                      selected: plan.boss == boss,
                      sound: 'ui_toggle',
                      art: boss == null
                          ? const Icon(
                              Icons.flag_rounded,
                              size: 30,
                              color: SkyColors.ink,
                            )
                          : BossPortrait(boss, size: const Size(40, 36)),
                      onPressed: () => controller.settings(boss: () => boss),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.lerp(builtModeColor(plan.mode), SkyColors.cream, .6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SkyColors.ink.withValues(alpha: .5),
                width: 1.5,
              ),
            ),
            child: Text(
              plan.mode.controlsHeight
                  ? 'The bird flies two lanes: the top and the bottom of each '
                        '${plan.mode == PlayMode.squat ? 'squat' : 'push-up'}. '
                        'A slower player meets the same level at a gentler '
                        'speed. No shooting, sprinting or bosses here.'
                  : 'Each jump lifts the bird; it glides in between. No '
                        'shooting, sprinting or bosses here.',
              style: bodyText(13.5),
            ),
          ),
      ],
    );
  }

  static String _short(BossKind boss) => switch (boss) {
    BossKind.baronBat => 'Baron',
    BossKind.spitterBeetle => 'Spitter',
    BossKind.duskMoth => 'Empress',
    BossKind.pirate => 'Pirate',
    BossKind.dragon => 'Dragon',
    _ => bossName(boss),
  };
}

/// The regions as a strip of postcards that scrolls sideways, opening with
/// the level's own in view. A scrollbar under it and a fade at either end
/// with more beyond show that there are more places than fit.
class _RegionStrip extends StatefulWidget {
  const _RegionStrip({required this.controller});
  final BuilderController controller;

  @override
  State<_RegionStrip> createState() => _RegionStripState();
}

class _RegionStripState extends State<_RegionStrip> {
  static const _card = 92.0, _gap = 10.0, _pad = 6.0;
  ScrollController? _scroll;
  bool _before = false, _after = true;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// A scroll corrected while laying out is measured once the frame is
  /// done.
  void _scrolled() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    } else {
      _measure();
    }
  }

  void _measure() {
    final scroll = _scroll;
    if (!mounted || scroll == null || !scroll.hasClients) return;
    final p = scroll.position;
    final before = p.pixels > 2, after = p.maxScrollExtent - p.pixels > 2;
    if (before != _before || after != _after) {
      setState(() {
        _before = before;
        _after = after;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.controller.plan;
    return SizedBox(
      height: 122,
      child: LayoutBuilder(
        builder: (context, box) {
          // The level's region starts in the middle of the strip.
          _scroll ??= () {
            final index = WorldRegion.values.indexOf(plan.region);
            final total =
                _pad * 2 + WorldRegion.values.length * (_card + _gap) - _gap;
            final centre = _pad + index * (_card + _gap) + _card / 2;
            final offset = (centre - box.maxWidth / 2)
                .clamp(0.0, math.max(0.0, total - box.maxWidth))
                .toDouble();
            WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
            return ScrollController(initialScrollOffset: offset)
              ..addListener(_scrolled);
          }();
          const fade = 26.0;
          return NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
              return false;
            },
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) {
                final w = math.max(rect.width, fade * 2 + 1);
                return LinearGradient(
                  colors: [
                    Color(_before ? 0x00000000 : 0xff000000),
                    const Color(0xff000000),
                    const Color(0xff000000),
                    Color(_after ? 0x00000000 : 0xff000000),
                  ],
                  stops: [0, fade / w, 1 - fade / w, 1],
                ).createShader(rect);
              },
              child: RawScrollbar(
                controller: _scroll,
                thumbVisibility: true,
                thickness: 5,
                radius: const Radius.circular(3),
                mainAxisMargin: 4,
                crossAxisMargin: 0,
                thumbColor: SkyColors.ink.withValues(alpha: .38),
                child: ListView.separated(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  // Room for the picked region's ring inside the clipped
                  // strip, and for the scrollbar under the cards.
                  padding: const EdgeInsets.fromLTRB(_pad, 6, _pad, 14),
                  itemCount: WorldRegion.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) {
                    final region = WorldRegion.values[i];
                    final picked = region == plan.region;
                    return SizedBox(
                      width: _card,
                      child: PressCard(
                        key: ValueKey('settings-region-${region.name}'),
                        label: region.title,
                        selected: picked,
                        radius: 14,
                        accent: picked ? SkyColors.gold : SkyColors.teal,
                        onPressed: () =>
                            widget.controller.settings(region: region),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: RegionThumb(
                                region: region,
                                radius: 0,
                                outline: 0,
                              ),
                            ),
                            Container(
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: SkyColors.ink,
                                    width: 2,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  region.title,
                                  style: heading(13, weight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
