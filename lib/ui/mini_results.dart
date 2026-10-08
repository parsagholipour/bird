import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/passport_progress.dart';
import '../data/progress_repository.dart';
import '../domain/game_rules.dart';
import '../domain/sky_passport.dart';
import '../domain/tracking.dart';
import '../game/play_controller.dart';
import '../l10n/l10n.dart';
import '../l10n/text/flight_text.dart';
import '../l10n/text/passport_text.dart';
import 'fit_text.dart';
import 'flight_portrait.dart';
import 'match_hud.dart';
import 'mini_chrome.dart';
import 'stage_key.dart';
import 'theme.dart';

/// The result of a flight that ended without a bump: a workout finished from
/// the pause menu, or a whole trail flown. It is a sibling of the knockout
/// stage and the level result: the left tells the story (the bird in a soft
/// spotlight, a cheer, why the flight ended and a sticker for any passport
/// or postcard news), and the right is the scoreboard (the score counts up
/// beside the personal best, which turns gold under a ribbon when beaten),
/// with Home, Save session and a big Fly again below it.
///
/// The keys work from the first frame, since nothing about a finished
/// flight invites stray taps. Reduced Motion fades the screen in, settled.
class MiniResults extends StatefulWidget {
  const MiniResults({
    super.key,
    required this.controller,
    required this.progress,
    required this.mode,
    required this.course,
    required this.initialBest,
    required this.initialStamps,
    required this.initialDailyKey,
    required this.initialDailyComplete,
    required this.onLeave,
  });
  final PlayController controller;
  final ProgressSnapshot progress;
  final PlayMode mode;
  final FlightCourse course;
  final int initialBest;
  final Map<SkyStamp, StampMedal> initialStamps;
  final String? initialDailyKey;
  final bool initialDailyComplete;
  final Future<void> Function([String destination]) onLeave;

  static const entrance = Duration(milliseconds: 1700);
  static const calmEntrance = Duration(milliseconds: 400);

  @override
  State<MiniResults> createState() => _MiniResultsState();
}

class _MiniResultsState extends State<MiniResults>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this);
  bool _calm = false, _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _calm =
        widget.controller.reducedMotion ||
        MediaQuery.disableAnimationsOf(context);
    _intro
      ..duration = _calm ? MiniResults.calmEntrance : MiniResults.entrance
      ..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// How far along [from]–[to] of the entrance is; always 1 when calm.
  double _span(double from, double to, [Curve curve = Curves.linear]) {
    if (_calm) return 1;
    final t = ((_intro.value - from) / (to - from)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _intro,
    builder: (context, _) => _stage(context),
  );

  Widget _stage(BuildContext context) {
    final c = widget.controller;
    final r = c.result!;
    final l = context.l10n;
    final p = widget.progress;
    final newStamps = p.medalsWonSince(widget.initialStamps);
    final newDailyCard =
        c.saved &&
        p.today?.complete == true &&
        (widget.initialDailyKey != p.today?.dayKey ||
            !widget.initialDailyComplete);
    final isBest = r.score > widget.initialBest;
    final best = p.record(widget.mode, widget.course).best;
    final completed = r.reason == EndReason.completed;
    final reason = l.flightEndReason(r.reason);
    final celebrate =
        isBest || newDailyCard || newStamps.isNotEmpty || completed;
    return Opacity(
      opacity: _calm ? _intro.value : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
        child: Column(
          children: [
            MiniHeader(
              title: l.miniResultTitle,
              onBack: widget.onLeave,
              leading: [
                MiniTag(
                  L10n.upper(l.courseTitle(widget.course)),
                  icon: widget.course.collectsStars
                      ? Icons.auto_awesome
                      : Icons.flag_rounded,
                  color: miniColor(widget.mode),
                  foreground: widget.mode == PlayMode.touch
                      ? SkyColors.white
                      : SkyColors.ink,
                ),
              ],
              trailing: [
                MiniTag(
                  l.miniResultComplete,
                  icon: Icons.emoji_events_rounded,
                  color: SkyColors.yellow,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 372,
                    child: _story(
                      r,
                      isBest: isBest,
                      celebrate: celebrate,
                      reason: reason,
                      sticker: _sticker(
                        newDailyCard: newDailyCard,
                        newStamps: newStamps,
                        nextStamp: p.nextStamp,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  // The keys keep one place from flight to flight; the
                  // scoreboard hugs its content just above them.
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _card(
                              r,
                              best: isBest ? math.max(best, r.score) : best,
                              isBest: isBest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(height: 88, child: _actions(r)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The bird in its spotlight, the cheer and the reason on a cream plate,
  /// then the passport or postcard sticker.
  Widget _story(
    RunResult r, {
    required bool isBest,
    required bool celebrate,
    required String reason,
    required Widget? sticker,
  }) {
    final p = widget.progress;
    final l = context.l10n;
    final glow = _span(0, .35, Curves.easeOut);
    final cheer = _span(.08, .38, Curves.easeOutBack);
    final plate = _span(.22, .44, Curves.easeOutBack);
    final drop = _span(.62, .9, Curves.easeOutBack);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 372,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 372,
                height: 176,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _SpotlightPainter(
                            color: miniColor(widget.mode),
                            glow: glow,
                            sparkle: celebrate ? _span(.3, .8) : 0,
                          ),
                        ),
                      ),
                    ),
                    FlightPortrait(
                      key: ValueKey(r.id),
                      bird: p.settings.bird,
                      reducedMotion: p.settings.reducedMotion,
                      arrivedCourse:
                          r.reason == EndReason.completed &&
                              r.course.legacyTimed
                          ? r.course
                          : null,
                      celebrate: celebrate,
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: cheer.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: .7 + .3 * cheer,
                  child: Semantics(
                    header: true,
                    child: Text(
                      isBest
                          ? l.miniResultCheerBest
                          : r.reason == EndReason.completed
                          ? l.miniResultCheerComplete
                          : l.miniResultCheerNice,
                      textAlign: TextAlign.center,
                      style: heading(
                        44,
                        color: SkyColors.cream,
                        weight: FontWeight.w700,
                      ).copyWith(letterSpacing: .4, shadows: matchInkEdge(2.2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // The reason rides on a cream plate so it reads over any sky.
              Opacity(
                opacity: plate.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: .8 + .2 * plate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SkyColors.cream,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SkyColors.ink, width: 2.4),
                      boxShadow: [
                        BoxShadow(
                          color: SkyColors.ink.withValues(alpha: .25),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      reason,
                      textAlign: TextAlign.center,
                      style: bodyText(16, weight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              if (sticker != null) ...[
                const SizedBox(height: 18),
                // The sticker is slapped on, landing at a jaunty angle.
                Opacity(
                  opacity: drop.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - drop) * -36),
                    child: Transform.rotate(
                      angle: -.03 + (1 - drop) * .14,
                      child: sticker,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The same passport and postcard news as the other results, as a
  /// tappable sticker: a postage stamp beside what it says.
  Widget? _sticker({
    required bool newDailyCard,
    required List<StampProgress> newStamps,
    required StampProgress? nextStamp,
  }) {
    final l = context.l10n;
    final title = bodyText(14.5, weight: FontWeight.w900);
    final detail = bodyText(
      12,
      color: SkyColors.muted,
      weight: FontWeight.w700,
    );
    if (newDailyCard) {
      return _StickerCallout(
        stamp: const _PostageStamp(
          icon: Icons.local_post_office_rounded,
          color: SkyColors.mint,
        ),
        fresh: true,
        onTap: () => widget.onLeave('/daily'),
        body: Text(l.flightResultDailyStamped, style: title),
      );
    }
    if (newStamps.isNotEmpty) {
      final won = newStamps.first;
      return _StickerCallout(
        stamp: const _PostageStamp(
          icon: Icons.workspace_premium_rounded,
          color: SkyColors.yellow,
        ),
        fresh: true,
        onTap: () => widget.onLeave('/passport'),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.stampMedalTitle(won), style: title),
            // A long goal shrinks rather than lose its end.
            FitText(l.stampGoal(won.stamp, won.medal!), style: detail),
          ],
        ),
      );
    }
    if (widget.controller.saved && nextStamp != null) {
      return _StickerCallout(
        stamp: const _PostageStamp(
          icon: Icons.explore_rounded,
          color: SkyColors.sky,
        ),
        onTap: () => widget.onLeave('/passport'),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // A long title shrinks rather than lose its end.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l.flightResultNextStamp(l.stampNextTitle(nextStamp)),
                      maxLines: 1,
                      style: title,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(l.stampTally(nextStamp), style: title),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _meter(nextStamp.fraction, SkyColors.teal, height: 9),
            ),
            // A long goal shrinks rather than lose its end.
            FitText(l.stampProgressGoal(nextStamp), style: detail),
          ],
        ),
      );
    }
    return null;
  }

  static final _label = bodyText(
    12.5,
    color: SkyColors.muted,
    weight: FontWeight.w900,
  ).copyWith(letterSpacing: .8);

  /// A sand inset for the quieter parts of the scoreboard.
  static const _inset = Color(0xfff6ecda);

  /// Teal deepened so small text keeps its contrast on cream.
  static const _teal = Color(0xff2e7d6f);

  /// The scoreboard: an ink-framed card with the score and best on top,
  /// this flight's stats beneath, then the save status.
  Widget _card(RunResult r, {required int best, required bool isBest}) {
    final t = _span(.06, .34, Curves.easeOutCubic);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset((1 - t) * 70, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SkyColors.cream,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: SkyColors.ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: SkyColors.ink.withValues(alpha: .3),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 108,
                  child: _scores(r, best: best, isBest: isBest),
                ),
                const SizedBox(height: 8),
                _stats(r),
                const SizedBox(height: 10),
                // Long messages scroll rather than push the keys away.
                Flexible(
                  child: SingleChildScrollView(
                    child: Opacity(
                      opacity: _span(.34, .56),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _status(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scores(RunResult r, {required int best, required bool isBest}) {
    final l = context.l10n;
    final count = _span(.26, .66, Curves.easeOutCubic);
    final land = math.sin(_span(.66, .76) * math.pi);
    final ribbon = _span(.7, .9, Curves.elasticOut);
    final shown = (r.score * count).round();
    // A new best keeps the old record on the plaque until the score lands,
    // then the plaque turns gold under its ribbon.
    final gild = isBest ? _span(.68, .74) : 0.0;
    final record = isBest && gild <= 0 ? widget.initialBest : best;
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l.courseScoreLabel(widget.course), style: _label),
              Flexible(
                child: Transform.scale(
                  scale: 1 + .08 * land,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.course.collectsStars)
                          const MatchIcon(MatchSymbol.star, size: 50)
                        else
                          const Icon(
                            Icons.flag_rounded,
                            size: 48,
                            color: SkyColors.teal,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '$shown',
                          style: matchDigits(
                            80,
                            color: isBest && count >= 1
                                ? SkyColors.coralDeep
                                : SkyColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 200,
          child: Center(
            child: Container(
              width: 180,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              decoration: BoxDecoration(
                color: Color.lerp(_inset, const Color(0xfffff0bf), gild),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color.lerp(
                    SkyColors.sand.withValues(alpha: .6),
                    SkyColors.gold,
                    gild,
                  )!,
                  width: 2,
                ),
              ),
              // The plaque keeps its height; a larger text size shrinks its
              // lines together to fit.
              height: 92,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A new best stamps its ribbon over the label, its tails
                      // hanging past the plaque.
                      SizedBox(
                        height: 26,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: 1 - gild,
                              child: Text(
                                l.flightResultPersonalBest,
                                style: _label,
                              ),
                            ),
                            if (isBest && ribbon > 0)
                              OverflowBox(
                                maxWidth: 260,
                                maxHeight: 40,
                                child: Transform.scale(
                                  scale: ribbon,
                                  child: Transform.rotate(
                                    angle: -.04,
                                    child: StageRibbon(
                                      l.flightResultNewPersonalBest,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 30,
                            color: SkyColors.gold,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('$record', style: matchDigits(44)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// This flight's numbers on a sand inset, each a coin beside a bold
  /// number and its word.
  Widget _stats(RunResult r) {
    final l = context.l10n;
    final moves = widget.mode.controlsHeight ? r.repetitions : r.flaps;
    final reps = l.flightMoves(widget.mode, moves);
    final stats = <(IconData, Color, String, String)>[
      (
        widget.mode == PlayMode.touch
            ? Icons.touch_app_rounded
            : Icons.fitness_center_rounded,
        miniColor(widget.mode),
        '$moves',
        reps,
      ),
      (
        Icons.timer_rounded,
        SkyColors.sky,
        l.flightSeconds('${r.durationSeconds.round()}'),
        l.flightStatFlightTime,
      ),
      (
        Icons.center_focus_strong_rounded,
        SkyColors.mint,
        '${r.perfectPasses}',
        l.flightStatPerfect,
      ),
      if (r.course.collectsStars)
        (
          Icons.auto_awesome,
          SkyColors.yellow,
          '${r.bestCombo}',
          l.flightStatBestStreak,
        )
      else if (r.score >= 5)
        (
          Icons.workspace_premium_rounded,
          SkyColors.yellow,
          l.flightRank(r.score),
          '',
        ),
    ];
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _inset,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final (i, (icon, color, value, word)) in stats.indexed) ...[
            if (i > 0)
              Container(
                width: 1.5,
                height: 30,
                color: SkyColors.sand.withValues(alpha: .55),
              ),
            // Longer phrases get the wider cells.
            Expanded(
              flex: 12 + value.length + word.length,
              child: _tile(
                i,
                icon,
                color,
                value,
                word,
                light: widget.mode == PlayMode.touch && i == 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// One stat: its coin pops in, then the number and word beside it.
  Widget _tile(
    int i,
    IconData icon,
    Color color,
    String value,
    String word, {
    bool light = false,
  }) {
    final k = _span(.2 + i * .05, .42 + i * .05, Curves.easeOutBack);
    return Opacity(
      opacity: k.clamp(0.0, 1.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: .6 + .4 * k,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: SkyColors.ink, width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: SkyColors.ink, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: light ? SkyColors.white : SkyColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                // One line, so the number and its word read as a phrase.
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: word.isEmpty
                            ? heading(18, weight: FontWeight.w700)
                            : matchDigits(22),
                      ),
                      if (word.isNotEmpty)
                        TextSpan(
                          text: ' $word',
                          style: bodyText(
                            12.5,
                            color: SkyColors.muted,
                            weight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Save status (tap to retry), then session and camera messages.
  List<Widget> _status() {
    final c = widget.controller;
    final l = context.l10n;
    Widget note(IconData icon, String text, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: bodyText(12.5, color: color, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return [
      if (c.saveError.isNotEmpty)
        TextButton.icon(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: SkyColors.coralDeep, width: 1.5),
            ),
          ),
          onPressed: c.persist,
          icon: const Icon(
            Icons.refresh_rounded,
            size: 20,
            color: SkyColors.coralDeep,
          ),
          label: Text(
            l.flightNote(c.saveError),
            style: bodyText(
              13,
              weight: FontWeight.w900,
              color: SkyColors.coralDeep,
            ),
          ),
        )
      else
        note(
          c.saved
              ? Icons.check_circle_outline_rounded
              : Icons.hourglass_top_rounded,
          c.saved
              ? l.flightResultSavedGates(widget.progress.totalObstacles)
              : l.flightResultSaving,
          SkyColors.muted,
        ),
      if (c.sessionSaved)
        note(Icons.video_library_outlined, l.flightResultSessionSaved, _teal),
      if (c.sessionError.isNotEmpty || c.cameraRecordingError.isNotEmpty)
        note(
          Icons.error_outline_rounded,
          l.flightNote(
            c.sessionError.isNotEmpty ? c.sessionError : c.cameraRecordingError,
          ),
          SkyColors.coralDeep,
        ),
    ];
  }

  /// A slim inked meter, filled [value] of the way.
  Widget _meter(double value, Color color, {required double height}) =>
      Container(
        height: height,
        decoration: BoxDecoration(
          color: SkyColors.sand.withValues(alpha: .35),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: SkyColors.ink.withValues(alpha: .6),
            width: 1.4,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: color),
            ),
          ),
        ),
      );

  Widget _actions(RunResult r) {
    final c = widget.controller;
    final l = context.l10n;
    Widget pop(double at, Widget child) {
      final k = _span(at, at + .22, Curves.easeOutBack);
      return Opacity(
        opacity: k.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - k) * 30),
          child: Transform.scale(scale: .8 + .2 * k, child: child),
        ),
      );
    }

    // Fly again catches a glint once everything has landed.
    final shine = _calm ? 0.0 : _span(.84, 1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 104,
          child: pop(
            .3,
            StageKey(
              label: l.commonHome,
              icon: Icons.home_rounded,
              onPressed: widget.onLeave,
            ),
          ),
        ),
        if (c.simulation?.started == true) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: pop(
              .34,
              StageKey(
                key: const ValueKey('save-or-watch-session'),
                label: c.sessionSaved
                    ? l.flightResultWatchReplay
                    : c.preparingReplay
                    ? l.flightResultPreparing
                    : c.sessionSaving
                    ? l.flightResultSavingShort
                    : l.flightResultSaveSession,
                icon: c.sessionSaved
                    ? Icons.play_circle_outline_rounded
                    : Icons.save_alt_rounded,
                busy: c.preparingReplay || c.sessionSaving,
                onPressed: c.sessionSaved
                    ? () => widget.onLeave('/replay/${r.id}')
                    : c.canSaveSession && !c.sessionSaving
                    ? c.persistSession
                    : null,
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: pop(
            .38,
            StageKey(
              label: l.flightResultFlyAgain,
              icon: Icons.replay_rounded,
              hero: true,
              autofocus: true,
              shine: shine,
              onPressed: () => c.retry(),
            ),
          ),
        ),
      ],
    );
  }
}

/// A tappable sticker on the sky: a cream plate in the HUD material with a
/// postage stamp at its head, what it says, and a chevron. A [fresh]
/// sticker (something just earned) wears a little NEW tag on its corner.
class _StickerCallout extends StatelessWidget {
  const _StickerCallout({
    required this.stamp,
    required this.body,
    required this.onTap,
    this.fresh = false,
  });
  final Widget stamp, body;
  final VoidCallback onTap;
  final bool fresh;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        MatchPlate(
          radius: 20,
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      stamp,
                      const SizedBox(width: 12),
                      Flexible(child: body),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 26,
                        color: SkyColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (fresh)
          Positioned(
            top: -20,
            right: -16,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: MatchTag(
                  context.l10n.miniResultNew,
                  color: SkyColors.coral,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// A little postage stamp: a perforated white edge around a colored face
/// with an icon, set at a slight tilt.
class _PostageStamp extends StatelessWidget {
  const _PostageStamp({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: .07,
    child: SizedBox(
      width: 46,
      height: 52,
      child: CustomPaint(
        painter: _StampPainter(color),
        child: Center(child: Icon(icon, size: 24, color: SkyColors.ink)),
      ),
    ),
  );
}

class _StampPainter extends CustomPainter {
  const _StampPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // The perforations: half circles bitten out of every edge.
    const bite = 3.2;
    var paper = Path()..addRect(rect);
    final holes = Path();
    for (final (from, to, horizontal) in [
      (Offset.zero, Offset(size.width, 0), true),
      (Offset(0, size.height), Offset(size.width, size.height), true),
      (Offset.zero, Offset(0, size.height), false),
      (Offset(size.width, 0), Offset(size.width, size.height), false),
    ]) {
      final length = horizontal ? size.width : size.height;
      final n = (length / (bite * 3)).floor();
      for (var i = 0; i <= n; i++) {
        holes.addOval(
          Rect.fromCircle(center: Offset.lerp(from, to, i / n)!, radius: bite),
        );
      }
    }
    paper = Path.combine(PathOperation.difference, paper, holes);
    canvas.drawPath(
      paper.shift(const Offset(0, 2.5)),
      Paint()..color = SkyColors.ink.withValues(alpha: .3),
    );
    canvas.drawPath(paper, Paint()..color = SkyColors.white);
    canvas.drawPath(
      paper,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = SkyColors.ink,
    );
    final face = RRect.fromRectAndRadius(
      rect.deflate(6.5),
      const Radius.circular(4),
    );
    canvas.drawRRect(face, Paint()..color = color);
    // A soft highlight along the top of the face.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(face.left, face.top, face.width, face.height * .4),
        const Radius.circular(4),
      ),
      Paint()..color = SkyColors.white.withValues(alpha: .3),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = SkyColors.ink,
    );
  }

  @override
  bool shouldRepaint(_StampPainter old) => old.color != color;
}

/// A soft glow on the sky behind the bird, with faint rays in the workout's
/// color; a celebrating flight also scatters a few sparkles that twinkle in
/// once ([sparkle] runs 0–1).
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.color,
    required this.glow,
    required this.sparkle,
  });
  final Color color;
  final double glow, sparkle;

  @override
  void paint(Canvas canvas, Size size) {
    if (glow <= 0) return;
    final center = Offset(size.width / 2, size.height * .5);
    final radius = size.height * .62;
    // Rays fan out from behind the bird and fade toward their ends.
    final tint = Color.lerp(color, SkyColors.cream, .7)!;
    final rays = Paint()
      ..shader = RadialGradient(
        colors: [
          tint.withValues(alpha: .95 * glow),
          tint.withValues(alpha: .4 * glow),
          tint.withValues(alpha: 0),
        ],
        stops: const [.15, .55, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.35));
    const count = 14;
    for (var i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count - math.pi / 2;
      const half = math.pi / count * .42;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + math.cos(a - half) * radius * 1.35,
            center.dy + math.sin(a - half) * radius * 1.35,
          )
          ..lineTo(
            center.dx + math.cos(a + half) * radius * 1.35,
            center.dy + math.sin(a + half) * radius * 1.35,
          )
          ..close(),
        rays,
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.cream.withValues(alpha: .75 * glow),
            SkyColors.cream.withValues(alpha: .3 * glow),
            SkyColors.cream.withValues(alpha: 0),
          ],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (sparkle <= 0) return;
    for (final (i, (x, y, r)) in [
      (.12, .2, 7.0),
      (.88, .26, 9.0),
      (.08, .72, 5.0),
      (.92, .78, 6.0),
      (.24, .06, 4.0),
      (.78, .04, 5.0),
    ].indexed) {
      final start = i * .1;
      final k = ((sparkle - start) / .4).clamp(0.0, 1.0);
      if (k <= 0) continue;
      // Each sparkle swells past its size, then settles.
      final s = r * (k < 1 ? Curves.easeOutBack.transform(k) : 1);
      final c = Offset(size.width * x, size.height * y);
      final star = Path()
        ..moveTo(c.dx, c.dy - s * 1.7)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + s * 1.7, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s * 1.7)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - s * 1.7, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s * 1.7);
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round
          ..color = SkyColors.ink,
      );
      canvas.drawPath(
        star,
        Paint()..color = i.isEven ? SkyColors.yellow : SkyColors.cream,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.color != color || old.glow != glow || old.sparkle != sparkle;
}
