import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/builder_providers.dart';
import '../../data/built_level_repository.dart';
import '../../domain/built_code.dart';
import '../../domain/built_draft.dart';
import '../../domain/built_level.dart';
import '../../domain/built_reach.dart';
import '../../domain/game_rules.dart';
import '../../domain/tracking.dart' show PlayMode;
import '../components.dart';
import '../control_glyphs.dart';
import '../home_keys.dart' show LevelBuilderGlyph;
import '../match_hud.dart' show MatchPlate, matchInkEdge;
import '../mini_chrome.dart';
import '../theme.dart';
import '../ui_sounds.dart';
import 'builder_chrome.dart';
import 'builder_pickers.dart';

/// The Level Builder's shelf (`/builder`): the player's own levels to fly,
/// edit and share, the starter levels to fly or remix, a new level and a
/// pasted share code.
class BuilderHomeScreen extends ConsumerStatefulWidget {
  const BuilderHomeScreen({super.key});

  @override
  ConsumerState<BuilderHomeScreen> createState() => _BuilderHomeScreenState();
}

class _BuilderHomeScreenState extends ConsumerState<BuilderHomeScreen> {
  final _random = math.Random();
  final _shelf = ScrollController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Whatever changed while the shelf was away (an edit, a flight) shows.
    Future.microtask(() {
      if (mounted) ref.invalidate(builtShelfProvider);
    });
  }

  @override
  void dispose() {
    _shelf.dispose();
    super.dispose();
  }

  BuiltLevelStore get _store => ref.read(builtStoreProvider);

  BuildContext get _toastContext => _toastKey.currentContext ?? context;
  final _toastKey = GlobalKey();

  void _toast(String text, {IconData? icon, Color? color}) =>
      BuilderToast.show(_toastContext, text, icon: icon, color: color);

  void _warn(String text) => BuilderToast.warn(_toastContext, text);

  /// Runs [work] once at a time, telling the player if saving fails.
  Future<void> _guard(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
    } catch (error) {
      debugPrint('PushUpBird builder shelf: $error');
      if (mounted) {
        _warn('That didn’t save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh(String? id) {
    ref.invalidate(builtShelfProvider);
    if (id != null) ref.invalidate(builtLevelProvider(id));
  }

  Future<void> _newLevel(List<BuiltLevel> mine) async {
    final choice = await showNewLevelSheet(context);
    if (choice == null || !mounted) return;
    await _guard(() async {
      final (mode, region) = choice;
      final plan = BuiltDraft.blank(
        id: BuiltPlan.newId(_random),
        name: newLevelName(mode, mine.map((l) => l.plan.name)),
        mode: mode,
        region: region,
      ).plan;
      final level = await _store.create(plan);
      _refresh(level.id);
      if (mounted) context.go('/builder/edit/${level.id}');
    });
  }

  /// A copy of [level] under a new id: a remix of a starter level, or a
  /// duplicate of one's own. Opens the copy in the editor.
  Future<void> _copy(BuiltLevel level, {required bool remix}) =>
      _guard(() async {
        final plan = level.plan.copyWith(
          id: BuiltPlan.newId(_random),
          name: suffixedName(level.plan.name, remix ? ' remix' : ' copy'),
        );
        final copy = await _store.create(
          plan,
          origin: remix ? BuiltOrigin.remixed : BuiltOrigin.created,
          remixOf: remix ? (level.template ? level.id : level.from) : null,
        );
        _refresh(copy.id);
        if (mounted) context.go('/builder/edit/${copy.id}');
      });

  Future<void> _delete(BuiltLevel level) async {
    final yes = await confirmBuilder(
      context,
      title: 'Delete “${level.plan.name}”?',
      message:
          'Its bests go with it. Push-ups, squats and jumps you flew on it '
          'still count.',
      yes: 'Delete',
    );
    if (!yes || !mounted) return;
    await _guard(() async {
      await _store.delete(level.id);
      _refresh(level.id);
      _toast('Deleted “${level.plan.name}”.', icon: Icons.delete_rounded);
    });
  }

  Future<void> _share(BuiltLevel level) async {
    if (level.plan.problem != null) {
      _warn('Fix what’s marked in red before sharing: tap Fix it.');
      return;
    }
    await copyShareCode(level.plan, cleared: level.cleared);
    // A friend's preview says whether its maker flew it to the end.
    _toast(
      level.cleared
          ? 'Code copied! Paste it to a friend.'
          : 'Code copied! Fly it to the finish too, so friends know it can '
                'be done.',
      icon: Icons.content_paste_go_rounded,
    );
  }

  void _fly(BuiltLevel level) {
    if (level.plan.problem != null) {
      _warn('This level isn’t ready to fly yet: tap Fix it.');
      return;
    }
    flyBuilt(context, level.plan);
  }

  Future<void> _more(BuiltLevel level) async {
    final action = await showLevelActionsSheet(
      context,
      level,
      shareable: level.plan.problem == null,
    );
    if (!mounted) return;
    switch (action) {
      case LevelAction.share:
        await _share(level);
      case LevelAction.duplicate:
        await _copy(level, remix: false);
      case LevelAction.delete:
        await _delete(level);
      case null:
        break;
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final BuiltImport found;
    try {
      found = BuiltCode.decode(data?.text ?? '', id: BuiltPlan.newId(_random));
    } on BuiltCodeException catch (e) {
      await showBuilderNotice(
        context,
        title: switch (e.fault) {
          BuiltCodeFault.missing => 'No level code to paste',
          BuiltCodeFault.newer => 'A level from a newer Beakbound',
          BuiltCodeFault.damaged => 'That code got scrambled',
        },
        message: switch (e.fault) {
          BuiltCodeFault.missing =>
            'Copy a friend’s level code (it starts with BEAK1.) and tap '
                'Paste code again.',
          BuiltCodeFault.newer =>
            'Update Beakbound to fly it, then paste the code again.',
          BuiltCodeFault.damaged =>
            'Part of it is missing or mistyped. Ask your friend to copy the '
                'whole code again.',
        },
        icon: switch (e.fault) {
          BuiltCodeFault.missing => Icons.content_paste_off_rounded,
          BuiltCodeFault.newer => Icons.system_update_rounded,
          BuiltCodeFault.damaged => Icons.broken_image_rounded,
        },
      );
      return;
    }
    final same = await _store.sameRoute(found.plan);
    if (!mounted) return;
    final answer = await showImportSheet(context, found, yours: same);
    if (!mounted) return;
    switch (answer) {
      case ImportAnswer.openYours:
        context.go('/builder/edit/${same!.id}');
      case ImportAnswer.import:
        await _guard(() async {
          final level = await _store.create(
            found.plan,
            origin: BuiltOrigin.imported,
            importedCleared: found.cleared,
          );
          _refresh(level.id);
          if (_shelf.hasClients) _shelf.jumpTo(0);
          _toast('“${level.plan.name}” is on your shelf!');
        });
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelf = ref.watch(builtShelfProvider);
    final mine = shelf.asData?.value.mine ?? const <BuiltLevel>[];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SkyBackdrop(
          child: builderTextScale(
            SceneLayout(
              child: BuilderToastHost(
                child: Padding(
                  key: _toastKey,
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MiniHeader(
                        title: 'Level Builder',
                        size: 32,
                        onBack: () => context.go('/'),
                        trailing: [
                          MiniPillKey(
                            key: const ValueKey('paste-code'),
                            icon: Icons.content_paste_rounded,
                            label: 'Paste code',
                            onPressed: _paste,
                          ),
                          BuilderKey(
                            key: const ValueKey('new-level'),
                            tooltip: 'New level',
                            label: 'New level',
                            icon: Icons.add_rounded,
                            color: SkyColors.mint,
                            onPressed: () => _newLevel(mine),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: shelf.when(
                          skipLoadingOnRefresh: true,
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: SkyColors.ink,
                            ),
                          ),
                          error: (error, _) => Center(
                            child: MiniCard(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Your levels need a moment.',
                                    style: heading(22),
                                  ),
                                  const SizedBox(height: 12),
                                  BuilderKey(
                                    tooltip: 'Try again',
                                    label: 'Try again',
                                    icon: Icons.refresh_rounded,
                                    onPressed: () =>
                                        ref.invalidate(builtShelfProvider),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          data: (shelf) => _ShelfView(
                            shelf: shelf,
                            controller: _shelf,
                            onNew: () => _newLevel(shelf.mine),
                            onPaste: _paste,
                            onFly: _fly,
                            onEdit: (level) =>
                                context.go('/builder/edit/${level.id}'),
                            onShare: _share,
                            onMore: _more,
                            onRemix: (level) => _copy(level, remix: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelfView extends StatelessWidget {
  const _ShelfView({
    required this.shelf,
    required this.controller,
    required this.onNew,
    required this.onPaste,
    required this.onFly,
    required this.onEdit,
    required this.onShare,
    required this.onMore,
    required this.onRemix,
  });
  final BuiltShelf shelf;
  final ScrollController controller;
  final VoidCallback onNew, onPaste;
  final ValueChanged<BuiltLevel> onFly, onEdit, onShare, onMore, onRemix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionTitle(
        'My levels',
        trailing: shelf.mine.isEmpty ? null : '${shelf.mine.length}',
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 172,
        child: shelf.mine.isEmpty
            ? _EmptyShelf(onNew: onNew, onPaste: onPaste)
            : ListView.separated(
                key: const ValueKey('my-levels'),
                controller: controller,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.only(bottom: 4),
                itemCount: shelf.mine.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final level = shelf.mine[i];
                  return SizedBox(
                    width: 248,
                    child: _LevelCard(
                      level: level,
                      best: shelf.best(level),
                      onFly: () => onFly(level),
                      onEdit: () => onEdit(level),
                      onShare: () => onShare(level),
                      onMore: () => onMore(level),
                    ),
                  );
                },
              ),
      ),
      const SizedBox(height: 10),
      const _SectionTitle(
        'Starter levels',
        hint: 'Fly one, or remix it into a level of your own',
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 122,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, level) in shelf.templates.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _StarterCard(
                  level: level,
                  best: shelf.best(level),
                  onFly: () => onFly(level),
                  onOpen: () => onEdit(level),
                  onRemix: () => onRemix(level),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing, this.hint});
  final String text;
  final String? trailing;

  /// A few words after the title on what the row is for.
  final String? hint;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 20,
    child: Row(
      children: [
        const SizedBox(width: 4),
        Semantics(
          header: true,
          child: Text(
            text,
            style: heading(
              18,
              color: SkyColors.cream,
              weight: FontWeight.w700,
            ).copyWith(shadows: matchInkEdge(1.1), letterSpacing: .3),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SkyColors.cream,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: SkyColors.ink, width: 1.6),
            ),
            child: Text(
              trailing!,
              style: bodyText(11, weight: FontWeight.w900).copyWith(height: 1),
            ),
          ),
        ],
        if (hint != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyText(
                12.5,
                color: _hintInk,
                weight: FontWeight.w800,
              ).copyWith(height: 1),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Ink for a line of small print on the sky, as Home's Level Builder key
/// words its subtitle.
const _hintInk = Color(0xff245a77);

/// What the player's shelf shows before their first level.
class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({required this.onNew, required this.onPaste});
  final VoidCallback onNew, onPaste;

  @override
  Widget build(BuildContext context) => MiniCard(
    key: const ValueKey('empty-shelf'),
    accent: SkyColors.skyDeep,
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
    child: Row(
      children: [
        const SizedBox(
          width: 150,
          child: Center(child: LevelBuilderGlyph(size: 118)),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build your first level',
                style: heading(26, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Place gates, stars and hearts by hand, set the finish line '
                'and test fly it.',
                style: bodyText(14.5, color: SkyColors.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  BuilderKey(
                    key: const ValueKey('empty-new-level'),
                    tooltip: 'New level',
                    label: 'New level',
                    icon: Icons.add_rounded,
                    color: SkyColors.mint,
                    onPressed: onNew,
                  ),
                  const SizedBox(width: 12),
                  BuilderKey(
                    tooltip: 'Paste a friend’s code',
                    label: 'Paste a friend’s code',
                    icon: Icons.content_paste_rounded,
                    onPressed: onPaste,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// What stops [plan] flying, counted: "1 thing to fix", "3 things to fix".
String _toFix(BuiltPlan plan) {
  final count = math.max(
    1,
    BuiltReach.check(plan).where((issue) => issue.blocking).length,
  );
  return '$count thing${count == 1 ? '' : 's'} to fix';
}

/// The second fact of a starter level: its workout, its boss, or its stars.
(IconData?, String) _starterFact(BuiltPlan plan) {
  final reps = builtReps(plan);
  if (plan.boss != null) return (Icons.shield_rounded, bossName(plan.boss!));
  if (reps != null) return (null, reps);
  return (Icons.star_rounded, '${plan.totalStars} stars');
}

/// One of the player's levels: its region, mode and state over its
/// picture, its name and best stars, its facts, and keys to fly, edit and
/// share it (duplicate and delete wait under More). A level that cannot fly
/// yet says how much is left to fix and offers Fix it in Fly's place.
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.best,
    required this.onFly,
    required this.onEdit,
    required this.onShare,
    required this.onMore,
  });
  final BuiltLevel level;
  final BuiltBest? best;
  final VoidCallback onFly, onEdit, onShare, onMore;

  @override
  Widget build(BuildContext context) {
    final plan = level.plan;
    final ready = plan.problem == null;
    final name = plan.name;
    final yours = level.clearedRevision == level.revision;
    final friends = level.origin == BuiltOrigin.imported;
    final stars = best?.stars ?? 0;
    final reps = builtReps(plan);
    // A level its maker has flown to the end is worth sharing.
    final brag = ready && yours && !friends;
    void edit() {
      UiSounds.effect(context);
      onEdit();
    }

    return Semantics(
      container: true,
      label:
          '$name. ${builtModeName(plan.mode)} in ${plan.region.title}. '
          '${builtLength(plan)}. '
          '${ready ? 'Best $stars of 3 stars. ' : 'Needs work: ${_toFix(plan)}. '}'
          '${ready && yours ? 'Cleared by you. ' : ''}'
          '${friends ? 'From a friend. ' : ''}',
      child: MiniCard(
        key: ValueKey('level-${level.id}'),
        accent: builtModeColor(plan.mode),
        padding: EdgeInsets.zero,
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The picture opens the editor, as Edit does.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: edit,
              child: SizedBox(
                // Large text takes some of the picture's height.
                height: MediaQuery.textScalerOf(context).scale(10) > 10.5
                    ? 48
                    : 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RegionPicture(region: plan.region),
                    Positioned(left: 7, bottom: 5, child: _ModeChip(plan.mode)),
                    Positioned(
                      right: 8,
                      top: 7,
                      child: !ready
                          ? const BuilderBadge(
                              'Needs work',
                              icon: Icons.build_rounded,
                              color: SkyColors.coral,
                            )
                          : yours
                          ? const BuilderBadge(
                              'Cleared by you',
                              icon: Icons.verified_rounded,
                              color: SkyColors.mint,
                            )
                          : friends
                          ? const BuilderBadge(
                              'From a friend',
                              icon: Icons.mail_rounded,
                              color: SkyColors.cream,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: edit,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 11, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: heading(
                                18,
                                weight: FontWeight.w700,
                              ).copyWith(height: 1.1),
                            ),
                          ),
                          if (ready) ...[
                            const SizedBox(width: 6),
                            BuilderStars(earned: stars, size: 17),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      // With very large text the facts give way first.
                      Flexible(
                        child: ready
                            ? Row(
                                children: [
                                  _Fact(Icons.timer_rounded, builtLength(plan)),
                                  const SizedBox(width: 10),
                                  _Fact(
                                    Icons.star_rounded,
                                    '${plan.totalStars}',
                                  ),
                                  if (plan.boss != null || reps != null) ...[
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: plan.boss != null
                                          ? _Fact(
                                              Icons.shield_rounded,
                                              bossName(plan.boss!),
                                            )
                                          : _Fact.workout(plan.mode, reps!),
                                    ),
                                  ],
                                ],
                              )
                            : _Fact(
                                Icons.build_rounded,
                                '${_toFix(plan)} in the editor',
                                color: SkyColors.coralDeep,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 0, 9, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ready
                        ? BuilderKey(
                            key: ValueKey('fly-${level.id}'),
                            tooltip: 'Fly $name',
                            label: 'Fly',
                            icon: Icons.play_arrow_rounded,
                            color: SkyColors.mint,
                            onPressed: onFly,
                          )
                        : BuilderKey(
                            key: ValueKey('fix-${level.id}'),
                            tooltip: 'Fix $name',
                            label: 'Fix it',
                            icon: Icons.build_rounded,
                            color: SkyColors.yellow,
                            onPressed: onEdit,
                          ),
                  ),
                  if (ready) ...[
                    const SizedBox(width: 7),
                    BuilderKey(
                      key: ValueKey('edit-${level.id}'),
                      tooltip: 'Edit $name',
                      icon: Icons.edit_rounded,
                      onPressed: onEdit,
                    ),
                  ],
                  const SizedBox(width: 7),
                  BuilderKey(
                    key: ValueKey('share-${level.id}'),
                    tooltip: brag
                        ? 'Share $name: you cleared it'
                        : 'Share $name',
                    icon: Icons.ios_share_rounded,
                    color: brag ? SkyColors.skyDeep : SkyColors.cream,
                    muted: !ready,
                    onMuted: onShare,
                    onPressed: onShare,
                  ),
                  const SizedBox(width: 7),
                  BuilderKey(
                    key: ValueKey('more-${level.id}'),
                    tooltip: 'More for $name',
                    icon: Icons.more_horiz_rounded,
                    onPressed: onMore,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A starter level as a ticket: its region and mode, name, length and
/// workout (or boss), its best, and keys to fly it and to remix it into a
/// level of one's own.
class _StarterCard extends StatelessWidget {
  const _StarterCard({
    required this.level,
    required this.best,
    required this.onFly,
    required this.onOpen,
    required this.onRemix,
  });
  final BuiltLevel level;
  final BuiltBest? best;
  final VoidCallback onFly, onOpen, onRemix;

  @override
  Widget build(BuildContext context) {
    final plan = level.plan;
    final (icon, fact) = _starterFact(plan);
    final stars = best?.stars ?? 0;
    return MiniCard(
      key: ValueKey('starter-${level.id}'),
      accent: builtModeColor(plan.mode),
      padding: EdgeInsets.zero,
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label:
                  'Look at ${plan.name}. ${builtModeName(plan.mode)}, '
                  '${builtLength(plan)}, $fact.'
                  '${stars > 0 ? ' Best $stars of 3 stars.' : ''}',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  UiSounds.effect(context);
                  onOpen();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 50,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RegionPicture(region: plan.region),
                          Positioned(
                            left: 5,
                            bottom: 4,
                            child: _ModeChip(plan.mode, glyph: 24, text: 10.5),
                          ),
                          if (stars > 0)
                            Positioned(
                              right: 5,
                              top: 5,
                              child: _StarsPlate(best: stars),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(9, 3, 2, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                plan.name,
                                maxLines: 1,
                                style: heading(
                                  15.5,
                                  weight: FontWeight.w700,
                                ).copyWith(height: 1.1),
                              ),
                            ),
                            const SizedBox(height: 3),
                            _Fact(
                              Icons.timer_rounded,
                              builtLength(plan),
                              size: 11.5,
                            ),
                            const SizedBox(height: 1),
                            if (icon == null)
                              _Fact.workout(plan.mode, fact, size: 11.5)
                            else
                              _Fact(icon, fact, size: 11.5),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 5, 6, 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BuilderKey(
                  key: ValueKey('fly-${level.id}'),
                  tooltip: 'Fly ${plan.name}',
                  label: 'Fly',
                  vertical: true,
                  labelSize: 10.5,
                  width: 54,
                  icon: Icons.play_arrow_rounded,
                  color: SkyColors.mint,
                  onPressed: onFly,
                ),
                BuilderKey(
                  key: ValueKey('remix-${level.id}'),
                  tooltip: 'Remix ${plan.name}',
                  label: 'Remix',
                  vertical: true,
                  labelSize: 10.5,
                  width: 54,
                  icon: Icons.auto_fix_high_rounded,
                  onPressed: onRemix,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One fact of a level: a small ink icon and a few words ("42 s").
class _Fact extends StatelessWidget {
  const _Fact(IconData this.icon, this.text, {this.size = 12.5, this.color})
    : mode = null;

  /// A workout ("10 push-ups") after its mode's glyph.
  const _Fact.workout(PlayMode this.mode, this.text, {this.size = 12.5})
    : icon = null,
      color = null;
  final IconData? icon;
  final PlayMode? mode;
  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? SkyColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mode != null)
          ControlGlyph(builtControl(mode!), size: size + 3)
        else
          Icon(icon, size: size + 2, color: ink),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bodyText(
              size,
              color: color ?? SkyColors.ink,
              weight: FontWeight.w800,
            ).copyWith(height: 1.15),
          ),
        ),
      ],
    );
  }
}

/// A level's mode as a sticker on its picture: the control's glyph over a
/// cream tag with the mode's name ("Push-ups").
class _ModeChip extends StatelessWidget {
  const _ModeChip(this.mode, {this.glyph = 28, this.text = 11.5});
  final PlayMode mode;
  final double glyph, text;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.centerLeft,
    children: [
      Padding(
        padding: EdgeInsets.only(left: glyph - 8),
        child: Container(
          height: glyph * .74,
          padding: const EdgeInsets.fromLTRB(11, 0, 8, 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SkyColors.cream,
            borderRadius: BorderRadius.circular(glyph),
            border: Border.all(color: SkyColors.ink, width: 1.8),
          ),
          child: Text(
            builtModeName(mode),
            maxLines: 1,
            style: bodyText(text, weight: FontWeight.w900).copyWith(height: 1),
          ),
        ),
      ),
      ControlGlyph(builtControl(mode), size: glyph),
    ],
  );
}

/// A starter level's best stars on a small cream plate over its picture.
class _StarsPlate extends StatelessWidget {
  const _StarsPlate({required this.best});
  final int best;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: BoxDecoration(
      color: SkyColors.cream,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SkyColors.ink, width: 1.8),
    ),
    child: BuilderStars(earned: best, size: 13),
  );
}

/// A region still filling its box, as a card's picture (the card clips it).
class RegionPicture extends StatelessWidget {
  const RegionPicture({super.key, required this.region});
  final WorldRegion region;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: SkyColors.ink, width: 2)),
    ),
    child: RegionThumb(region: region, radius: 0, outline: 0),
  );
}

/// Shows a level's share code was not ready, or a pasted code could not be
/// read: a title, a line and OK.
Future<void> showBuilderNotice(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.info_rounded,
}) => showBuilderSheet<void>(
  context,
  builder: (context) => Center(
    child: SizedBox(
      width: 520,
      child: MatchPlate(
        key: const ValueKey('builder-notice'),
        radius: 26,
        padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: SkyColors.yellow,
                shape: BoxShape.circle,
                border: Border.all(color: SkyColors.ink, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: SkyColors.ink, offset: Offset(0, 3)),
                ],
              ),
              child: Icon(icon, size: 30, color: SkyColors.ink),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: heading(24, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: bodyText(15, color: SkyColors.muted),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 200,
              child: BuilderKey(
                key: const ValueKey('notice-ok'),
                tooltip: 'OK',
                label: 'OK',
                color: SkyColors.mint,
                height: 52,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
