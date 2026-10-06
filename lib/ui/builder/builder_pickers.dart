import 'package:flutter/material.dart';

import '../../domain/built_code.dart';
import '../../domain/built_level.dart';
import '../../domain/built_templates.dart';
import '../../domain/game_rules.dart';
import '../../domain/tracking.dart';
import '../control_glyphs.dart';
import '../mini_chrome.dart' show MiniCard;
import '../mode_picker_art.dart';
import '../theme.dart';
import '../ui_sounds.dart';
import 'builder_chrome.dart';
import 'builder_timeline.dart' show BuilderRouteStrip;

/// The modes a level can be built for, in the order the picker shows them.
const builtModes = [
  PlayMode.touch,
  PlayMode.pushUp,
  PlayMode.squat,
  PlayMode.jump,
];

/// Picks a new level's mode, then its region. Null when closed.
Future<(PlayMode, WorldRegion)?> showNewLevelSheet(BuildContext context) =>
    showBuilderSheet<(PlayMode, WorldRegion)>(
      context,
      label: 'Close new level',
      builder: (context) => const _NewLevelSheet(),
    );

class _NewLevelSheet extends StatefulWidget {
  const _NewLevelSheet();

  @override
  State<_NewLevelSheet> createState() => _NewLevelSheetState();
}

class _NewLevelSheetState extends State<_NewLevelSheet> {
  PlayMode? mode;

  @override
  Widget build(BuildContext context) {
    final mode = this.mode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 16),
      child: Column(
        children: [
          BuilderSheetTitle(
            title: mode == null ? 'What will it be?' : 'Where does it fly?',
            subtitle: mode == null
                ? 'Pick how it’s flown (you can’t change it later). You test '
                      'fly every level by touch.'
                : '${builtModeName(mode)} · pick where it flies. You can '
                      'change this later.',
            closeLabel: 'Close new level',
            onBack: mode == null
                ? null
                : () => setState(() => this.mode = null),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: mode == null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, m) in builtModes.indexed) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(
                          child: _ModeCard(
                            mode: m,
                            onPressed: () => setState(() => this.mode = m),
                          ),
                        ),
                      ],
                    ],
                  )
                : RegionGrid(
                    suggested: suggestedRegion(mode),
                    onPicked: (region) =>
                        Navigator.of(context).pop((mode, region)),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A card that is a key: it sinks into its lip when pressed (with Reduced
/// Motion it shades instead) and plays the tap cue.
class PressCard extends StatefulWidget {
  const PressCard({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
    this.accent = SkyColors.teal,
    this.selected = false,
    this.radius = 22,
  });
  final String label;
  final VoidCallback onPressed;
  final Widget child;
  final Color accent;
  final bool selected;
  final double radius;

  @override
  State<PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<PressCard> {
  bool pressed = false, focused = false;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final ring =
        widget.selected ||
        (focused &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      excludeSemantics: true,
      onTap: _press,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: _press,
          onFocusChange: (value) => setState(() => focused = value),
          onHighlightChanged: (value) => setState(() => pressed = value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius + 2),
              boxShadow: [
                if (ring)
                  const BoxShadow(color: SkyColors.yellow, spreadRadius: 5),
              ],
            ),
            child: Transform.translate(
              offset: Offset(0, pressed && !still ? 4 : 0),
              child: MiniCard(
                accent: widget.accent,
                color: pressed && still
                    ? Color.lerp(SkyColors.cream, SkyColors.ink, .08)!
                    : SkyColors.cream,
                padding: EdgeInsets.zero,
                radius: widget.radius,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _press() {
    UiSounds.effect(context);
    widget.onPressed();
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onPressed});
  final PlayMode mode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = builtModeColor(mode);
    final line = switch (mode) {
      PlayMode.touch => 'Tap to flap. Gates, stars, enemies and a boss.',
      PlayMode.pushUp => 'A high lane and a low one: every dip is a push-up.',
      PlayMode.squat => 'A high lane and a low one: every dip is a squat.',
      PlayMode.jump => 'Jump for lift. Gates anywhere in the sky.',
    };
    return PressCard(
      key: ValueKey('new-mode-${mode.name}'),
      label: '${mode.title}. $line',
      accent: color,
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: ModePickerArt(mode: mode, color: color),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: ControlGlyph(builtControl(mode), size: 34),
                ),
                if (mode.controlsHeight || mode == PlayMode.jump)
                  Positioned(
                    right: 10,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SkyColors.cream.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_outlined, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Camera',
                            style: bodyText(11, weight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
            child: Column(
              children: [
                Text(
                  mode.title,
                  textAlign: TextAlign.center,
                  style: heading(22, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: bodyText(12.5, color: SkyColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where a new level of [mode] flies if its maker has no other idea: its
/// starter level's region.
WorldRegion suggestedRegion(PlayMode mode) => BuiltTemplates.all
    .firstWhere(
      (template) => template.plan.mode == mode,
      orElse: () => BuiltTemplates.all.first,
    )
    .plan
    .region;

/// The thirteen regions as postcards to pick from: seven over six. A
/// [suggested] region wears a tag until another is [selected].
class RegionGrid extends StatelessWidget {
  const RegionGrid({
    super.key,
    required this.onPicked,
    this.selected,
    this.suggested,
  });
  final ValueChanged<WorldRegion> onPicked;
  final WorldRegion? selected, suggested;

  @override
  Widget build(BuildContext context) {
    const regions = WorldRegion.values;
    const perRow = 7;
    return Column(
      children: [
        for (var start = 0; start < regions.length; start += perRow) ...[
          if (start > 0) const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + perRow; i++) ...[
                  if (i > start) const SizedBox(width: 12),
                  Expanded(
                    child: i < regions.length
                        ? _RegionCard(
                            region: regions[i],
                            selected: regions[i] == selected,
                            suggested:
                                selected == null && regions[i] == suggested,
                            onPressed: () => onPicked(regions[i]),
                          )
                        : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.region,
    required this.onPressed,
    this.selected = false,
    this.suggested = false,
  });
  final WorldRegion region;
  final VoidCallback onPressed;
  final bool selected, suggested;

  @override
  Widget build(BuildContext context) => PressCard(
    key: ValueKey('region-${region.name}'),
    label: suggested ? '${region.title}, suggested' : region.title,
    selected: selected,
    radius: 16,
    accent: selected || suggested ? SkyColors.gold : SkyColors.teal,
    onPressed: onPressed,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: SkyColors.ink, width: 2),
                  ),
                ),
                child: RegionThumb(region: region, radius: 0, outline: 0),
              ),
              if (suggested)
                const Positioned(
                  left: 6,
                  top: 6,
                  child: BuilderBadge(
                    'Suggested',
                    key: ValueKey('region-suggested'),
                    icon: Icons.thumb_up_alt_rounded,
                    color: SkyColors.yellow,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  region.title,
                  maxLines: 1,
                  style: heading(14, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// A level's other actions.

enum LevelAction { share, duplicate, delete }

/// Share, duplicate or delete [level]: the shelf card's More.
Future<LevelAction?> showLevelActionsSheet(
  BuildContext context,
  BuiltLevel level, {
  required bool shareable,
}) => showBuilderSheet<LevelAction>(
  context,
  label: 'Close',
  builder: (context) {
    Widget action(
      LevelAction value,
      String label,
      String line,
      IconData icon,
      Color color, {
      bool muted = false,
    }) => Expanded(
      child: PressCard(
        key: ValueKey('action-${value.name}'),
        label: label,
        accent: color,
        onPressed: () {
          if (muted) {
            BuilderToast.warn(
              context,
              'Fix what’s marked in red before sharing: tap Fix it.',
            );
            return;
          }
          Navigator.of(context).pop(value);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
          child: Column(
            children: [
              // A key that cannot work yet greys its face, but still says
              // why at full strength.
              Opacity(
                opacity: muted ? .45 : 1,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: SkyColors.ink, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: SkyColors.ink, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Icon(icon, size: 30, color: SkyColors.ink),
                    ),
                    const SizedBox(height: 10),
                    Text(label, style: heading(20, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                muted ? 'Not yet: fix what’s marked in red first.' : line,
                textAlign: TextAlign.center,
                style: bodyText(
                  12.5,
                  color: muted ? SkyColors.coralDeep : SkyColors.muted,
                  weight: muted ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 16),
      child: Column(
        children: [
          BuilderSheetTitle(
            title: level.plan.name,
            subtitle:
                '${builtModeName(level.plan.mode)} · ${level.plan.region.title}',
          ),
          const Spacer(),
          SizedBox(
            height: 186,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: 60),
                action(
                  LevelAction.share,
                  'Share code',
                  'Copy a code a friend can paste into their Beakbound.',
                  Icons.ios_share_rounded,
                  SkyColors.skyDeep,
                  muted: !shareable,
                ),
                const SizedBox(width: 16),
                action(
                  LevelAction.duplicate,
                  'Duplicate',
                  'Make a copy to try another idea.',
                  Icons.copy_all_rounded,
                  SkyColors.yellow,
                ),
                const SizedBox(width: 16),
                action(
                  LevelAction.delete,
                  'Delete',
                  'Throw the level away. You’ll be asked first.',
                  Icons.delete_rounded,
                  SkyColors.coral,
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  },
);

// ---------------------------------------------------------------------------
// A pasted level.

enum ImportAnswer { import, openYours }

/// Shows the level a pasted code holds and asks whether to keep it. With
/// [yours] (a kept level with the same route) it offers that level instead.
Future<ImportAnswer?> showImportSheet(
  BuildContext context,
  BuiltImport found, {
  BuiltLevel? yours,
}) => showBuilderSheet<ImportAnswer>(
  context,
  label: 'Cancel import',
  builder: (context) {
    final plan = found.plan;
    final reps = builtReps(plan);
    Widget fact(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SkyColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: bodyText(15, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 16),
      child: Column(
        children: [
          const BuilderSheetTitle(
            title: 'A level to fly!',
            subtitle: 'Someone shared this level with you.',
            closeLabel: 'Cancel import',
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 720,
                child: MiniCard(
                  key: const ValueKey('import-preview'),
                  accent: builtModeColor(plan.mode),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 290,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RegionThumb(region: plan.region),
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: ControlGlyph(
                                builtControl(plan.mode),
                                size: 44,
                              ),
                            ),
                            if (found.cleared)
                              const Positioned(
                                right: 10,
                                top: 10,
                                child: BuilderBadge(
                                  'Cleared by its maker',
                                  icon: Icons.verified_rounded,
                                  color: SkyColors.mint,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: heading(26, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${plan.mode.title} · ${plan.region.title}',
                              style: bodyText(14, color: SkyColors.muted),
                            ),
                            const SizedBox(height: 10),
                            fact(Icons.timer_rounded, builtLength(plan)),
                            fact(
                              Icons.star_rounded,
                              '${plan.totalStars} stars to collect',
                            ),
                            if (reps != null)
                              fact(Icons.fitness_center_rounded, reps),
                            if (plan.boss != null)
                              fact(
                                Icons.shield_rounded,
                                'Ends with ${bossName(plan.boss!)}',
                              ),
                            if (!found.cleared)
                              fact(
                                Icons.help_outline_rounded,
                                'Its maker hasn’t flown it to the end yet.',
                              ),
                            const Spacer(),
                            const BuilderCaption('The route'),
                            BuilderRouteStrip(plan: plan),
                            const SizedBox(height: 10),
                            if (yours != null) ...[
                              Text(
                                'You already have this level: '
                                '“${yours.plan.name}”.',
                                style: bodyText(
                                  13.5,
                                  color: SkyColors.coralDeep,
                                  weight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: yours != null
                                      ? BuilderKey(
                                          key: const ValueKey('import-copy'),
                                          tooltip: 'Import a copy',
                                          label: 'Import a copy',
                                          icon: Icons.copy_all_rounded,
                                          onPressed: () => Navigator.of(
                                            context,
                                          ).pop(ImportAnswer.import),
                                        )
                                      : BuilderKey(
                                          key: const ValueKey('import-cancel'),
                                          tooltip: 'Cancel',
                                          label: 'Cancel',
                                          sound: 'ui_back',
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: yours != null
                                      ? BuilderKey(
                                          key: const ValueKey('import-open'),
                                          tooltip: 'Open yours',
                                          label: 'Open yours',
                                          icon: Icons.edit_rounded,
                                          color: SkyColors.mint,
                                          onPressed: () => Navigator.of(
                                            context,
                                          ).pop(ImportAnswer.openYours),
                                        )
                                      : BuilderKey(
                                          key: const ValueKey('import-keep'),
                                          tooltip: 'Import',
                                          label: 'Import',
                                          icon: Icons.download_rounded,
                                          color: SkyColors.mint,
                                          onPressed: () => Navigator.of(
                                            context,
                                          ).pop(ImportAnswer.import),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
);
