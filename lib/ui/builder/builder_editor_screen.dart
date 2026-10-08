import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/builder_providers.dart';
import '../../data/providers.dart';
import '../../domain/built_level.dart';
import '../../domain/built_reach.dart';
import '../../domain/built_templates.dart';
import '../../domain/game_rules.dart';
import '../../l10n/l10n.dart';
import '../../l10n/text/builder_shelf_text.dart';
import '../../l10n/text/builder_text.dart';
import '../campaign_chrome.dart' show MapGlyph, MapKey;
import '../components.dart' show SceneLayout, SkyBackdrop;
import '../control_glyphs.dart';
import '../fit_text.dart';
import '../home_keys.dart';
import '../match_hud.dart' show MatchPlate;
import '../theme.dart';
import '../ui_sounds.dart';
import 'builder_canvas.dart';
import 'builder_chrome.dart';
import 'builder_controller.dart';
import 'builder_inspector.dart';
import 'builder_name_dialog.dart';
import 'builder_palette.dart';
import 'builder_settings_sheet.dart';
import 'builder_timeline.dart';

/// Where the editor's parts sit on the 1000 × 450 canvas: the tools down
/// the left, the sky in the middle with the whole route under it, and the
/// selected thing's settings on the right. The sky shows about one phone
/// screen of the route (2.2 sky heights).
abstract final class EditorLayout {
  static const palette = Rect.fromLTRB(12, 68, 92, 440);
  static const canvas = Rect.fromLTRB(100, 68, 740, 362);
  static const timeline = Rect.fromLTRB(100, 372, 740, 440);
  static const inspector = Rect.fromLTRB(750, 68, 988, 440);

  /// How much of the route the sky shows, in sky heights.
  static double get view => canvas.width / canvas.height;
}

/// The level editor (`/builder/edit/<id>`): one of the player's levels to
/// build, or a starter level to look at, fly and remix. [at] is a place on
/// the route (thousandths) to show first, such as where a test flight got.
class BuilderEditorScreen extends ConsumerStatefulWidget {
  const BuilderEditorScreen({super.key, required this.id, this.at});
  final String id;
  final int? at;

  @override
  ConsumerState<BuilderEditorScreen> createState() =>
      _BuilderEditorScreenState();
}

class _BuilderEditorScreenState extends ConsumerState<BuilderEditorScreen> {
  BuilderController? _controller;
  bool _leaving = false;
  final _toastKey = GlobalKey();
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(builtStoreProvider);
    BuiltLevel? level;
    try {
      level =
          BuiltTemplates.byId(widget.id) ??
          (BuiltPlan.isBuiltId(widget.id)
              ? await store.level(widget.id)
              : null);
    } catch (error) {
      debugPrint('PushUpBird builder load: $error');
    }
    if (!mounted) return;
    if (level == null) {
      context.go('/builder');
      return;
    }
    final controller = BuilderController(level: level, store: store);
    final at = widget.at;
    controller.scrollTo(
      at != null
          ? at / BuiltPlan.unit - EditorLayout.view * .45
          : BuiltPlan.firstX / BuiltPlan.unit - .75,
    );
    // An empty level opens with the gate in hand, so the first tap on the
    // sky places something.
    if (!controller.readOnly && controller.plan.items.isEmpty) {
      controller.pick(BuilderTool.gate);
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  BuildContext get _toastContext => _toastKey.currentContext ?? context;

  void _refresh() {
    ref.invalidate(builtShelfProvider);
    ref.invalidate(builtLevelProvider(widget.id));
  }

  /// Saves what is left to save, then goes to [to].
  Future<void> _leave(String to) async {
    if (_leaving) return;
    _leaving = true;
    await _controller?.flush();
    _refresh();
    if (mounted) context.go(to);
  }

  /// Saves, then flies the level: its creator's test flight (from the
  /// view's left edge with [fromHere]), or a starter level for real.
  Future<void> _fly({bool fromHere = false}) async {
    final c = _controller;
    if (c == null || _leaving) return;
    await c.flush();
    if (!mounted) return;
    if (c.saveError) {
      BuilderToast.warn(_toastContext, context.l10n.builderSaveFailedFlyToast);
      return;
    }
    _leaving = true;
    _refresh();
    flyBuilt(
      context,
      c.plan,
      test: !c.readOnly,
      from: fromHere ? testFromHere(c.scroll) : null,
    );
  }

  Future<void> _remix() async {
    final c = _controller;
    if (c == null || _leaving) return;
    final level = c.level;
    try {
      final copy = await ref
          .read(builtStoreProvider)
          .create(
            level.plan.copyWith(
              id: BuiltPlan.newId(_random),
              // Named as the shelf names a remix: a starter's in the
              // player's language.
              name: suffixedName(
                context.l10n.builtLevelName(level.plan),
                ' ${context.l10n.builderShelfRemixSuffix}',
                context.l10n,
              ),
            ),
            origin: BuiltOrigin.remixed,
            remixOf: level.template ? level.id : level.from,
          );
      _leaving = true;
      ref.invalidate(builtShelfProvider);
      // The remix opens where the starter level was being looked at.
      final at = ((c.scroll + EditorLayout.view * .45) * BuiltPlan.unit)
          .round();
      if (mounted) context.go('/builder/edit/${copy.id}?at=$at');
    } catch (error) {
      debugPrint('PushUpBird builder remix: $error');
      if (mounted) {
        BuilderToast.warn(_toastContext, context.l10n.builderShelfSaveFailed);
      }
    }
  }

  Future<void> _share() async {
    final c = _controller;
    if (c == null) return;
    final l = context.l10n;
    if (!c.flyable) {
      BuilderToast.warn(_toastContext, l.builderShareBlockedToast);
      return;
    }
    await c.flush();
    await copyShareCode(c.plan, cleared: c.level.cleared, l: l);
    if (!mounted) return;
    // A friend's preview says whether its maker flew it to the end, as the
    // shelf's share does.
    BuilderToast.show(
      _toastContext,
      c.level.cleared
          ? l.builderShelfCodeCopied
          : l.builderShelfCodeCopiedUncleared,
      icon: Icons.content_paste_go_rounded,
    );
  }

  Future<void> _rename() async {
    final c = _controller;
    if (c == null || c.readOnly) return;
    final name = await showBuilderNameDialog(context, c.plan.name);
    if (name != null) c.settings(name: name);
  }

  Future<void> _issues() async {
    final c = _controller;
    if (c == null) return;
    final issue = await showIssuesSheet(context, c);
    if (issue == null || !mounted) return;
    final x = issue.x;
    if (x == null) return;
    c.scrollTo(x / BuiltPlan.unit - EditorLayout.view * .4);
    for (final entry in c.draft.items) {
      if (entry.item.x == x) {
        c.pick(BuilderTool.select);
        c.select(entry.key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final bird = ref.watch(
      progressProvider.select((p) => p.asData?.value.settings.bird ?? 0),
    );
    // The system back key leaves as the back key does: saved, to the
    // builder.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave('/builder'));
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SkyBackdrop(
          child: builderTextScale(
            SceneLayout(
              // Toasts sit over the sky's lower edge, clear of the route
              // strip.
              child: BuilderToastHost(
                bottom: 450 - EditorLayout.canvas.bottom + 26,
                child: c == null
                    ? const Center(
                        child: CircularProgressIndicator(color: SkyColors.ink),
                      )
                    : Stack(
                        key: _toastKey,
                        children: [
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 8,
                            height: 52,
                            child: _TopBar(
                              controller: c,
                              onBack: () => _leave('/builder'),
                              onRename: _rename,
                              onSettings: () => showBuilderSettings(context, c),
                              onIssues: _issues,
                              onShare: _share,
                              onFly: () => _fly(),
                              onFlyFromHere: () => _fly(fromHere: true),
                              onRemix: _remix,
                            ),
                          ),
                          Positioned.fromRect(
                            rect: EditorLayout.palette,
                            child: BuilderPalette(controller: c),
                          ),
                          // The sky and the route strip are the flight's
                          // world: they run left to right in every language.
                          Positioned.fromRect(
                            rect: EditorLayout.canvas,
                            child: FlightDirection(
                              child: BuilderCanvas(controller: c, bird: bird),
                            ),
                          ),
                          Positioned.fromRect(
                            rect: EditorLayout.timeline,
                            child: FlightDirection(
                              child: BuilderTimeline(
                                controller: c,
                                view: EditorLayout.view,
                              ),
                            ),
                          ),
                          Positioned.fromRect(
                            rect: EditorLayout.inspector,
                            child: BuilderInspector(controller: c),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.onBack,
    required this.onRename,
    required this.onSettings,
    required this.onIssues,
    required this.onShare,
    required this.onFly,
    required this.onFlyFromHere,
    required this.onRemix,
  });
  final BuilderController controller;
  final VoidCallback onBack,
      onRename,
      onSettings,
      onIssues,
      onShare,
      onFly,
      onFlyFromHere,
      onRemix;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final l = context.l10n;
      final c = controller;
      final readOnly = c.readOnly;
      final issues = c.issues;
      final blocking = issues.where((i) => i.blocking).length;
      final advice = issues.length - blocking;
      // Three groups: the level itself (its name and settings) on the
      // left; then editing (undo, redo), its state (problems, share); then
      // flying, the one primary key, with "From here" as its quieter twin.
      return Row(
        children: [
          MapKey(
            glyph: MapGlyph.back,
            label: l.builderEditorBackSemantics,
            onPressed: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: _NamePlate(controller: c, onRename: onRename),
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 8),
                  MapKey(
                    glyph: MapGlyph.settings,
                    label: l.builderSettingsSemantics,
                    onPressed: onSettings,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (readOnly) ...[
            // A starter level says so up here, clear of its sky.
            // A long translation shrinks its words rather than the name.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _StarterBanner(onRemix: onRemix),
            ),
            const SizedBox(width: 10),
            _FlyKey(test: false, onPressed: onFly),
          ] else ...[
            BuilderKey(
              key: const ValueKey('editor-undo'),
              tooltip: l.builderUndoSemantics,
              icon: Icons.undo_rounded,
              onPressed: c.canUndo ? c.undo : null,
            ),
            const SizedBox(width: 4),
            BuilderKey(
              key: const ValueKey('editor-redo'),
              tooltip: l.builderRedoSemantics,
              icon: Icons.redo_rounded,
              onPressed: c.canRedo ? c.redo : null,
            ),
            const SizedBox(width: 16),
            BuilderKey(
              key: const ValueKey('editor-issues'),
              tooltip: blocking > 0
                  ? l.builderIssuesSemantics(blocking, advice)
                  : advice > 0
                  ? l.builderTipsSemantics(advice)
                  : l.builderReadySemantics,
              // Ready is a quiet tick: the fly key is the loud one.
              label: blocking > 0
                  ? '$blocking'
                  : advice > 0
                  ? '$advice'
                  : null,
              gap: 2,
              icon: blocking > 0
                  ? Icons.priority_high_rounded
                  : advice > 0
                  ? Icons.lightbulb_rounded
                  : Icons.check_rounded,
              color: blocking > 0
                  ? SkyColors.coral
                  : advice > 0
                  ? SkyColors.yellow
                  : SkyColors.mint,
              onPressed: onIssues,
            ),
            const SizedBox(width: 6),
            BuilderKey(
              key: const ValueKey('editor-share'),
              tooltip: l.builderShareSemantics,
              icon: Icons.ios_share_rounded,
              muted: !c.flyable,
              onMuted: onShare,
              onPressed: onShare,
            ),
            const SizedBox(width: 16),
            BuilderKey(
              key: const ValueKey('editor-from-here'),
              tooltip: l.builderFromHereSemantics,
              label: l.builderFromHere,
              icon: Icons.play_arrow_rounded,
              color: const Color(0xffe4f4e8),
              labelSize: 14,
              gap: 3,
              onPressed: onFlyFromHere,
            ),
            const SizedBox(width: 8),
            _FlyKey(test: true, onPressed: onFly),
          ],
        ],
      );
    },
  );
}

/// The way into the sky: a mint key like the title screen's, FLY for a
/// starter level and TEST FLY for the player's own.
class _FlyKey extends StatelessWidget {
  const _FlyKey({required this.test, required this.onPressed});
  final bool test;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = test ? l.builderTestFly : l.builderFly;
    return SizedBox(
      key: const ValueKey('editor-fly'),
      width: test ? 148 : 112,
      height: 54,
      child: HomeKey(
        label: test ? l.builderTestFlySemantics : l.builderFlySemantics,
        colors: HomeKeyColors.mint,
        lip: 6,
        radius: 20,
        onPressed: onPressed,
        builder: (context, _) => Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: heading(18, weight: FontWeight.w700).copyWith(
                    letterSpacing: 1,
                    height: 1,
                    shadows: const [
                      Shadow(color: SkyColors.cream, offset: Offset(0, 1.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 26,
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

/// The level's name and mode, and whether its changes are saved. A tap
/// renames it, or retries a save that failed.
class _NamePlate extends StatelessWidget {
  const _NamePlate({required this.controller, required this.onRename});
  final BuilderController controller;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = controller;
    final plan = c.plan;
    final (status, color) = c.readOnly
        ? (l.builderStatusStarter, SkyColors.muted)
        : c.saveError
        ? (l.builderStatusSaveFailed, SkyColors.coralDeep)
        : c.unsaved
        ? (l.builderStatusSaving, SkyColors.muted)
        : (l.builderStatusSaved, SkyColors.muted);
    final name = l.builtLevelName(plan);
    final mode = builtModeName(plan.mode, l);
    return Semantics(
      button: !c.readOnly,
      label: c.readOnly
          ? l.builderNamePlateSemantics(l.playerText(name), mode, status)
          : l.builderNamePlateRenameSemantics(l.playerText(name), mode, status),
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('editor-name'),
        behavior: HitTestBehavior.opaque,
        onTap: c.readOnly
            ? null
            : () {
                UiSounds.effect(context);
                if (c.saveError) {
                  c.flush();
                } else {
                  onRename();
                }
              },
        child: MatchPlate(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
          radius: 18,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: mode,
                  child: ControlGlyph(builtControl(plan.mode), size: 32),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The player's own words: never translated, set in
                      // the game's font with the system's for any other
                      // script.
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: heading(18, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 1),
                      FitText(
                        status,
                        style: bodyText(
                          11,
                          color: color,
                          weight: FontWeight.w800,
                        ).copyWith(height: 1.1),
                      ),
                    ],
                  ),
                ),
                if (!c.readOnly) ...[
                  const SizedBox(width: 8),
                  Icon(
                    c.saveError ? Icons.refresh_rounded : Icons.edit_rounded,
                    size: 18,
                    color: c.saveError ? SkyColors.coralDeep : SkyColors.muted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Beside a starter level's fly key: it is read-only, and can be remixed.
class _StarterBanner extends StatelessWidget {
  const _StarterBanner({required this.onRemix});
  final VoidCallback onRemix;

  @override
  Widget build(BuildContext context) => MatchPlate(
    key: const ValueKey('starter-banner'),
    color: SkyColors.yellow,
    radius: 18,
    padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_rounded, size: 18, color: SkyColors.ink),
        const SizedBox(width: 6),
        Flexible(
          child: FitText(
            context.l10n.builderStarterBanner,
            style: bodyText(14, weight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        BuilderKey(
          key: const ValueKey('banner-remix'),
          tooltip: context.l10n.builderRemixSemantics,
          label: context.l10n.builderRemix,
          icon: Icons.auto_fix_high_rounded,
          color: SkyColors.cream,
          labelSize: 14,
          onPressed: onRemix,
        ),
      ],
    ),
  );
}

/// The level's problems (which stop it flying and sharing) and advice, in
/// route order. Returns the one tapped, to go and look at.
Future<BuiltIssue?> showIssuesSheet(
  BuildContext context,
  BuilderController controller,
) => showBuilderSheet<BuiltIssue>(
  context,
  label: context.l10n.builderIssuesCloseSemantics,
  builder: (context) {
    final l = context.l10n;
    final issues = controller.issues;
    final plan = controller.plan;
    final blocking = issues.where((i) => i.blocking).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
      child: Column(
        children: [
          BuilderSheetTitle(
            title: issues.isEmpty
                ? l.builderIssuesReadyTitle
                : blocking > 0
                ? l.builderIssuesFixTitle
                : l.builderIssuesTipsTitle,
            subtitle: issues.isEmpty
                ? l.builderIssuesReadyDetail
                : l.builderIssuesDetail,
            closeLabel: l.builderIssuesCloseSemantics,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 680,
                child: issues.isEmpty
                    ? Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: SkyColors.mint,
                            shape: BoxShape.circle,
                            border: Border.all(color: SkyColors.ink, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: SkyColors.ink,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 72,
                            color: SkyColors.ink,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 10),
                        itemCount: issues.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final issue = issues[i];
                          final where = issue.x == null
                              ? null
                              : l.builtSeconds(
                                  BuiltReach.secondsTo(plan, issue.x!),
                                  digits: 1,
                                );
                          return _IssueRow(
                            key: ValueKey('issue-$i'),
                            issue: issue,
                            where: where,
                            onPressed: issue.x == null
                                ? null
                                : () => Navigator.of(context).pop(issue),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  },
);

class _IssueRow extends StatelessWidget {
  const _IssueRow({
    super.key,
    required this.issue,
    required this.where,
    required this.onPressed,
  });
  final BuiltIssue issue;
  final String? where;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = issue.blocking ? SkyColors.coral : SkyColors.yellow;
    final row = MatchPlate(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: SkyColors.ink, width: 2),
              ),
              child: Icon(
                issue.blocking
                    ? Icons.priority_high_rounded
                    : Icons.lightbulb_rounded,
                size: 20,
                color: SkyColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.builtIssueMessage(issue),
                maxLines: 2,
                style: bodyText(15, weight: FontWeight.w800),
              ),
            ),
            if (where != null) ...[
              const SizedBox(width: 10),
              Text(where!, style: heading(15, color: SkyColors.muted)),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: SkyColors.ink,
              ),
            ],
          ],
        ),
      ),
    );
    if (onPressed == null) return row;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          UiSounds.effect(context);
          onPressed!();
        },
        child: row,
      ),
    );
  }
}
