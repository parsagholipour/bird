import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/progress_repository.dart';
import '../data/providers.dart';
import '../domain/campaign.dart';
import '../domain/campaign_progress.dart';
import '../domain/campaign_story.dart';
import '../domain/world_region.dart';
import '../l10n/l10n.dart';
import '../l10n/language_providers.dart' show storyCaptionsProvider;
import 'campaign_chrome.dart';
import 'campaign_map.dart';
import 'campaign_postcard.dart';
import 'campaign_text_scale.dart';
import 'components.dart';
import 'level_intro.dart';
import 'match_hud.dart' show MatchPlate;
import 'story_scene.dart';
import 'theme.dart';

/// The campaign's world map, from the saved progress: one stop per region,
/// levels as nodes with their stars, the courier perched on the current
/// level. Tapping an open level opens its card; a locked one nudges toward
/// the level that unlocks it.
///
/// The story is told here, in scenes that each play by themselves once: the
/// prologue on the first visit, a scene ahead of some levels' cards, and
/// one after each boss falls. A card's story key plays its level's scenes
/// again.
///
/// A chapter's postcard arrives here: after its boss first falls, the map
/// shows the boss's last scene and then the postcard before anything else,
/// and marks the postcard seen on Continue. [level] opens that level's card
/// straight away (the result's Next), on its own stop.
class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key, this.level});
  final String? level;

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  CampaignLevel? _intro;
  int? _focus;

  /// A postcard opened from the map, to see it again.
  int? _revisit;

  /// Postcards continued on this visit, hidden while the save lands.
  final _continued = <int>{};

  /// Scenes watched on this visit, hidden while the save lands.
  final _watched = <String>{};

  /// Scenes a card's story key asked to see again, in order. They play
  /// without being saved.
  List<StoryScene> _replay = const [];

  String? _nudge;
  Timer? _nudgeTimer;

  /// Which tap raised the nudge, so a second tap on the same locked level
  /// shows it afresh.
  int _nudgeId = 0;

  CampaignProgress? _stopsFrom;
  String? _stopsIn;
  List<CampaignMapStop> _stops = const [];

  @override
  void initState() {
    super.initState();
    final level = widget.level == null ? null : Campaign.level(widget.level!);
    if (level != null) {
      _intro = level;
      _focus = Campaign.journey.indexOf(level.region);
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  /// The stops, rebuilt only when the progress or the language changes, so
  /// the map keeps its layout between frames.
  List<CampaignMapStop> _stopsOf(
    CampaignProgress progress,
    AppLocalizations l,
  ) {
    if (identical(progress, _stopsFrom) && l.localeName == _stopsIn) {
      return _stops;
    }
    _stopsFrom = progress;
    _stopsIn = l.localeName;
    return _stops = campaignStops(progress, l);
  }

  /// The first chapter whose postcard has not been seen yet.
  int? _due(CampaignProgress progress) {
    for (final chapter in Campaign.chapters) {
      if (progress.postcardDue(chapter) &&
          !_continued.contains(chapter.number)) {
        return chapter.number;
      }
    }
    return null;
  }

  void _open(String id) {
    final level = Campaign.level(id);
    if (level == null) return;
    setState(() {
      _intro = level;
      _nudge = null;
    });
  }

  void _locked(String id) {
    final level = Campaign.level(id);
    if (level == null) return;
    _nudgeTimer?.cancel();
    // A stop that is not in this build has its Coming soon ribbon on the map
    // already, which answers the tap; a second notice would cover it.
    if (!Campaign.playable(level)) {
      setState(() => _nudge = null);
      return;
    }
    setState(() {
      _nudge = lockedNudge(level, context.l10n);
      _nudgeId++;
    });
    _nudgeTimer = Timer(_Nudge.life, () {
      if (mounted) setState(() => _nudge = null);
    });
  }

  void _fly(CampaignLevel level) => context.go('/play/touch?level=${level.id}');

  /// The scene over the map now, if any: one asked for again, or else the
  /// first one due. The prologue leads, a fallen boss's scene comes ahead of
  /// its postcard, and a level's scene ahead of its card.
  StoryScene? _scene(CampaignProgress progress) {
    if (_replay.isNotEmpty) return _replay.first;
    StoryScene? fresh(StoryScene? scene) =>
        scene == null || _watched.contains(scene.id) ? null : scene;
    final prologue = fresh(progress.prologueDue);
    if (prologue != null) return prologue;
    final due = _due(progress);
    if (due != null) {
      return _revisit == null
          ? fresh(progress.sceneAfter(Campaign.chapters[due - 1]))
          : null;
    }
    // A guardian's last word plays once its level is first beaten, on the map
    // the result returns to (New York).
    if (_revisit == null) {
      for (final level in Campaign.levels) {
        if (!level.isGuardian) continue;
        final last = fresh(progress.sceneLast(level));
        if (last != null) return last;
      }
    }
    final intro = _intro;
    return _revisit == null && intro != null && progress.unlocked(intro)
        ? fresh(progress.sceneBefore(intro))
        : null;
  }

  /// A scene ended or was skipped. One that played by itself is saved as
  /// watched; one asked for again gives way to the next in line.
  void _sceneDone(StoryScene scene) {
    if (_replay.isNotEmpty) {
      // A second tap as a scene ends must not skip the one after it.
      if (identical(_replay.first, scene)) {
        setState(() => _replay = _replay.sublist(1));
      }
      return;
    }
    if (_watched.contains(scene.id)) return;
    setState(() => _watched.add(scene.id));
    unawaited(ref.read(progressProvider.notifier).storyWatched(scene));
  }

  /// The scenes [level]'s card can play again: the one before it and, at a
  /// beaten boss's lair, the one after its fall.
  List<StoryScene> _scenesOf(CampaignLevel level, CampaignProgress progress) {
    final chapter = Campaign.chapterOf(level);
    return [
      ?CampaignStory.before(level),
      // A beaten guardian's last word, which ends on the "To be continued…"
      // card at 3-4.
      ?(level.isGuardian && progress.cleared(level)
          ? CampaignStory.lastWord(level)
          : null),
      if (level == chapter.bossLevel && progress.cleared(level))
        CampaignStory.after(chapter),
    ];
  }

  void _continue(int chapter, {required bool due}) {
    setState(() {
      _revisit = null;
      if (due) _continued.add(chapter);
    });
    if (due) {
      unawaited(
        ref
            .read(progressProvider.notifier)
            .postcardSeen(Campaign.chapters[chapter - 1]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(progressProvider);
    final progress = async.asData?.value;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Still loading, or the save could not be read: back goes Home.
        if (progress == null) {
          context.go('/');
          return;
        }
        final scene = _scene(progress.campaign);
        final due = _due(progress.campaign);
        if (scene != null) {
          _sceneDone(scene);
        } else if (_revisit != null || due != null) {
          _continue(_revisit ?? due!, due: _revisit == null);
        } else if (_intro != null) {
          setState(() => _intro = null);
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: SkyColors.sky,
        body: progress == null
            ? _Unavailable(
                failed: async.hasError,
                onRetry: () => ref.invalidate(progressProvider),
                onHome: () => context.go('/'),
              )
            : _map(context, progress),
      ),
    );
  }

  Widget _map(BuildContext context, ProgressSnapshot progress) {
    final campaign = progress.campaign;
    final l = context.l10n;
    // The story's words: the current language's captions once they have
    // loaded (L10n.captions follows them), English until then.
    ref.watch(storyCaptionsProvider);
    final still =
        progress.settings.reducedMotion ||
        MediaQuery.disableAnimationsOf(context);
    final scene = _scene(campaign);
    final due = _due(campaign);
    final postcard = scene == null ? _revisit ?? due : null;
    final intro = scene == null && _intro != null && campaign.unlocked(_intro!)
        ? _intro
        : null;
    final covered = scene != null || intro != null || postcard != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Under a scene, card or postcard the map holds its frame: its bird,
        // glows and pulses cost no frames until the overlay closes.
        // Under a scene, card or postcard the map is out of the semantics tree
        // too, so a screen reader meets the card first and not the map's
        // forty-odd buttons.
        // Its keys step out of the keyboard's way too.
        ExcludeSemantics(
          excluding: covered,
          child: TickerMode(
            enabled: !covered,
            child: ExcludeFocus(
              excluding: covered,
              child: CampaignMap(
                stops: _stopsOf(campaign, l),
                bird: progress.settings.bird,
                reducedMotion: still,
                chromeHidden: covered,
                focusStop: _focus,
                onLevel: _open,
                onLockedLevel: _locked,
                onPostcard: (chapter) => setState(() => _revisit = chapter),
                leading: MapKey(
                  glyph: MapGlyph.back,
                  label: l.commonBackHome,
                  reducedMotion: still,
                  onPressed: () => context.go('/'),
                ),
                trailing: CampaignStarTotal(
                  stars: campaign.totalStars,
                  of: campaignStarsInBuild,
                ),
              ),
            ),
          ),
        ),
        if (_nudge != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: IgnorePointer(
              child: Center(
                child: _Nudge(_nudge!, key: ValueKey(_nudgeId), still: still),
              ),
            ),
          ),
        if (intro != null && postcard == null)
          Positioned.fill(
            child: _Entrance(
              key: ValueKey('intro-${intro.id}'),
              still: still,
              child: _IntroLayer(
                level: intro,
                record: campaign.record(intro),
                onFly: () => _fly(intro),
                onClose: () => setState(() => _intro = null),
                onStory: CampaignStory.before(intro) == null
                    ? null
                    : () =>
                          setState(() => _replay = _scenesOf(intro, campaign)),
              ),
            ),
          ),
        if (postcard != null)
          Positioned.fill(
            child: _Entrance(
              key: ValueKey('postcard-$postcard'),
              still: still,
              child: _PostcardLayer(
                chapter: postcard,
                bird: progress.settings.bird,
                onContinue: () => _continue(postcard, due: _revisit == null),
              ),
            ),
          ),
        if (scene != null)
          Positioned.fill(
            child: _Entrance(
              key: ValueKey('story-${scene.id}'),
              still: still,
              // A scene covers the whole screen, so it only fades in.
              lift: 0,
              child: StoryScenePlayer(
                key: ValueKey('story-scene-${scene.id}'),
                scene: scene,
                bird: progress.settings.bird,
                reducedMotion: still,
                voices: progress.settings.voices,
                onDone: () => _sceneDone(scene),
              ),
            ),
          ),
      ],
    );
  }
}

/// The map before the save has loaded, or when it cannot be read: the same
/// sky as Home, with the back key in the map's place. The way back Home
/// stays open either way, and a failed load can be tried again.
class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.failed,
    required this.onRetry,
    required this.onHome,
  });
  final bool failed;
  final VoidCallback onRetry, onHome;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SkyBackdrop(
      child: SafeArea(
        child: Stack(
          children: [
            PositionedDirectional(
              start: 16,
              top: 12,
              child: MapKey(
                glyph: MapGlyph.back,
                label: l.commonBackHome,
                onPressed: onHome,
              ),
            ),
            Center(
              child: failed
                  ? Panel(
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 120,
                            height: 68,
                            child: CustomPaint(painter: _LostMapPainter()),
                          ),
                          const SizedBox(height: 10),
                          Text(l.campaignMapUnavailable, style: heading(26)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SkyButton(
                                key: const ValueKey('campaign-home'),
                                label: l.commonHome,
                                icon: Icons.home_rounded,
                                color: SkyColors.skyDeep,
                                onPressed: onHome,
                              ),
                              const SizedBox(width: 12),
                              SkyButton(
                                label: l.commonTryAgain,
                                onPressed: onRetry,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const _Opening(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wait for the save: a round plate with a spinner, which holds still
/// as a part-filled ring when animations are off.
class _Opening extends StatelessWidget {
  const _Opening();

  @override
  Widget build(BuildContext context) => MatchPlate(
    padding: EdgeInsets.zero,
    child: SizedBox.square(
      dimension: 68,
      child: Center(
        child: SizedBox.square(
          dimension: 34,
          child: CircularProgressIndicator(
            value: MediaQuery.disableAnimationsOf(context) ? .75 : null,
            strokeWidth: 5,
            strokeCap: StrokeCap.round,
            color: SkyColors.coral,
            backgroundColor: SkyColors.ink.withValues(alpha: .1),
          ),
        ),
      ),
    ),
  );
}

/// A folded map with its mail route running out before the end, for the
/// error panel.
class _LostMapPainter extends CustomPainter {
  const _LostMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 96, size.height / 54);
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    // Three folds sharing their creases, like a map opened out on a table.
    const tops = [8.0, 2.0, 8.0, 2.0];
    for (var i = 0; i < 3; i++) {
      final x = 3.0 + i * 30;
      final fold = Path()
        ..moveTo(x, tops[i])
        ..lineTo(x + 30, tops[i + 1])
        ..lineTo(x + 30, tops[i + 1] + 44)
        ..lineTo(x, tops[i] + 44)
        ..close();
      canvas.drawPath(
        fold,
        Paint()..color = i.isOdd ? const Color(0xffd6efe1) : SkyColors.mint,
      );
      canvas.drawPath(fold, ink);
    }
    // The route: dots that stop short of the mark.
    for (final (x, y) in [
      (13.0, 42.0),
      (22.0, 33.0),
      (34.0, 35.0),
      (44.0, 28.0),
      (54.0, 21.0),
    ]) {
      canvas.drawCircle(Offset(x, y), 2.3, Paint()..color = SkyColors.gold);
    }
    // A cross where it should end, dashed to show it is not reached yet.
    final cross = Paint()
      ..color = SkyColors.coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(69, 13), const Offset(81, 25), cross);
    canvas.drawLine(const Offset(81, 13), const Offset(69, 25), cross);
  }

  @override
  bool shouldRepaint(_LostMapPainter old) => false;
}

/// Level stars there are to earn in this build: three for each playable
/// level. A getter, not a constant, so a build that opens New York counts it.
int get campaignStarsInBuild => Campaign.playableLevels.length * 3;

/// The map's stops from the saved progress, one per region in trip order,
/// worded in [l]'s language (the current one when null).
List<CampaignMapStop> campaignStops(
  CampaignProgress progress, [
  AppLocalizations? l,
]) {
  final words = l ?? L10n.strings;
  final current = progress.current;
  return [
    for (final chapter in Campaign.chapters)
      for (final region in chapter.regions)
        () {
          final nodes = [
            for (final level in chapter.levels)
              if (level.region == region)
                CampaignMapNode(
                  id: level.id,
                  name: words.levelName(level),
                  state: progress.cleared(level)
                      ? CampaignNodeState.cleared
                      : progress.unlocked(level)
                      ? CampaignNodeState.open
                      : CampaignNodeState.locked,
                  stars: progress.stars(level),
                  isCurrent:
                      identical(level, current) && progress.unlocked(level),
                  // A guardian's node is a shield only in a stop the build has
                  // opened; a closed stop keeps its plain locked coins (and
                  // must not draw the guardian as a chapter lair).
                  boss: level.isGuardian && !Campaign.playable(level)
                      ? null
                      : level.boss,
                  guardian: level.isGuardian && Campaign.playable(level),
                  lockNote: _lockNote(progress, level, words),
                ),
          ];
          return CampaignMapStop(
            region: region,
            chapter: chapter.number,
            route: words.chapterRoute(chapter),
            nodes: nodes,
            locked: nodes.every((node) => node.locked),
            comingSoon: Campaign.comingSoon(region),
            soonNote: _soonNote(chapter, region, words),
            postcard:
                region == chapter.regions.last &&
                progress.chapterComplete(chapter),
          );
        }(),
  ];
}

/// What unlocks [level] when it is locked in this build, for the screen reader
/// ("Beat King Coo to unlock"); null when it is open, beaten, or not in this
/// build (its stop's Coming soon ribbon says that).
String? _lockNote(
  CampaignProgress progress,
  CampaignLevel level,
  AppLocalizations l,
) =>
    Campaign.playable(level) &&
        !progress.cleared(level) &&
        !progress.unlocked(level)
    ? lockedNudge(level, l)
    : null;

/// What the Coming soon ribbon across [region]'s clouds says: "Coming soon",
/// or, in a chapter the build has partly opened, the stop's own name, as in
/// "Paris — coming soon".
String _soonNote(
  CampaignChapter chapter,
  WorldRegion region,
  AppLocalizations l,
) =>
    Campaign.comingSoon(region) &&
        Campaign.playableLevels.any((level) => level.chapter == chapter.number)
    ? l.campaignStopComingSoon(l.regionName(region))
    : l.campaignComingSoon;

/// A short message over the map's foot when a locked level is tapped: the
/// map's yellow notice ribbon, which pops in and fades before the screen
/// drops it. Reduced Motion shows it still.
class _Nudge extends StatefulWidget {
  const _Nudge(this.text, {super.key, required this.still});
  final String text;
  final bool still;

  /// How long it stays, popping in at the start and fading at the end.
  static const life = Duration(milliseconds: 2400);

  @override
  State<_Nudge> createState() => _NudgeState();
}

class _NudgeState extends State<_Nudge> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: _Nudge.life);
    if (!widget.still) controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = Semantics(
      liveRegion: true,
      label: widget.text,
      excludeSemantics: true,
      child: MapNotice(
        widget.text,
        key: const ValueKey('campaign-nudge'),
        size: 19,
        locked: true,
      ),
    );
    if (widget.still) return notice;
    return AnimatedBuilder(
      animation: controller,
      child: notice,
      builder: (context, child) {
        final ms = controller.value * _Nudge.life.inMilliseconds;
        final pop = Curves.easeOutBack.transform((ms / 200).clamp(0.0, 1.0));
        final fade = ((_Nudge.life.inMilliseconds - ms) / 260).clamp(0.0, 1.0);
        return Opacity(
          opacity: math.min(pop.clamp(0.0, 1.0), fade),
          child: Transform.translate(
            offset: Offset(0, (1 - pop) * 12),
            child: Transform.scale(scale: .9 + .1 * pop, child: child),
          ),
        );
      },
    );
  }
}

/// The level card over a dimmed map; a tap beside the card closes it.
class _IntroLayer extends StatelessWidget {
  const _IntroLayer({
    required this.level,
    required this.record,
    required this.onFly,
    required this.onClose,
    this.onStory,
  });
  final CampaignLevel level;
  final LevelRecord record;
  final VoidCallback onFly, onClose;
  final VoidCallback? onStory;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    // Composed for a 360-high phone; a taller screen grows it a little.
    final grow = (height / 360).clamp(1.0, 1.2);
    // A larger system text size composes the card on a taller box, which the
    // card then scales down to the screen.
    final design = LevelIntroCard.sizeFor(CampaignTextScale.of(context));
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          button: true,
          label: context.l10n.campaignCloseLevelSemantics(
            context.l10n.levelName(level),
          ),
          onTap: onClose,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('level-intro-barrier'),
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: ColoredBox(color: SkyColors.ink.withValues(alpha: .4)),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(10),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: design.width * grow,
                maxHeight: design.height * grow,
              ),
              child: LevelIntroCard(
                key: ValueKey('level-intro-${level.id}'),
                level: level,
                record: record,
                onFly: onFly,
                onClose: onClose,
                onStory: onStory,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A chapter's postcard on the sky, with Continue back to the map.
class _PostcardLayer extends StatelessWidget {
  const _PostcardLayer({
    required this.chapter,
    required this.bird,
    required this.onContinue,
  });
  final int chapter, bird;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => SkyBackdrop(
    child: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Center(
        child: CampaignPostcard(
          key: ValueKey('campaign-postcard-card-$chapter'),
          chapter: chapter,
          bird: bird,
          action: SkyButton(
            key: const ValueKey('campaign-postcard-continue'),
            label: context.l10n.commonContinue,
            autofocus: true,
            onPressed: onContinue,
          ),
        ),
      ),
    ),
  );
}

/// Fades and lifts a layer in; Reduced Motion shows it at once.
class _Entrance extends StatelessWidget {
  const _Entrance({
    super.key,
    required this.still,
    required this.child,
    this.lift = 18,
  });
  final bool still;
  final Widget child;

  /// How far below its place the layer starts.
  final double lift;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: still ? 1 : 0, end: 1),
    duration: still ? Duration.zero : const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * lift),
        child: child,
      ),
    ),
  );
}
