import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/passport_progress.dart';
import '../data/progress_repository.dart';
import '../domain/campaign.dart';
import '../domain/flight_goals.dart';
import '../domain/game_rules.dart';
import '../domain/sky_passport.dart';
import '../domain/tracking.dart';
import '../game/bird_puppet.dart';
import '../game/play_controller.dart';
import 'campaign_map_art.dart' show MapStarsPainter;
import 'components.dart';
import 'flight_goals.dart';
import 'stage_key.dart';
import 'theme.dart';

/// The arcade game-over stage after a fatal bump, staged over the frozen,
/// dimmed flight. The left of the stage tells what happened: a friendly
/// title drops in over the dazed bird riding a cloud up from where it fell.
/// The right is the scoreboard: the score counts up beside the personal
/// best, and a big Fly again key leads the actions below it. Everything the
/// plain results panel offers stays on this stage: flight wings, personal
/// best, mode stats, passport and postcard links, save status (tap to retry)
/// and Save session / Watch replay.
///
/// A failed campaign level plays the same stage without the endless best
/// or flight wings: the scoreboard counts the stars collected against the
/// level's marks beside how far along the route the bird got, and the keys
/// are Map, Save session and a big Retry.
///
/// Its buttons stay inert until the entrance has settled, so taps that were
/// meant for the bird cannot start another flight by accident. Reduced Motion
/// fades the stage in with the bird still dazed under three still stars.
class GameOverStage extends StatefulWidget {
  const GameOverStage({
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
    this.splash = false,
  });
  final PlayController controller;
  final ProgressSnapshot progress;
  final PlayMode mode;
  final FlightCourse course;
  final int initialBest;
  final Set<SkyStamp> initialStamps;
  final String? initialDailyKey;
  final bool initialDailyComplete;
  final Future<void> Function([String destination]) onLeave;

  /// The bird went into the Pirate Captain's sea rather than off the sky.
  final bool splash;

  /// The entrance's length; the buttons arm once it has settled.
  static const entrance = Duration(milliseconds: 1500);
  static const calmEntrance = Duration(milliseconds: 500);

  /// Fraction of the entrance after which the actions accept taps.
  static const armAt = .62;

  @override
  State<GameOverStage> createState() => _GameOverStageState();
}

class _GameOverStageState extends State<GameOverStage>
    with TickerProviderStateMixin {
  bool get _calm => widget.controller.reducedMotion;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _calm ? GameOverStage.calmEntrance : GameOverStage.entrance,
  );

  /// The dizzy spell: stars circle, the bird shakes it off and looks ready.
  late final AnimationController _dizzy = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  );

  @override
  void initState() {
    super.initState();
    _intro.forward();
    if (!_calm) _dizzy.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _dizzy.dispose();
    super.dispose();
  }

  double _span(double from, double to, [Curve curve = Curves.linear]) {
    if (_calm) return 1;
    final t = ((_intro.value - from) / (to - from)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  /// Seconds into the dizzy spell; null with Reduced Motion.
  double? get _dizzySeconds =>
      _calm ? null : _dizzy.value * _dizzy.duration!.inMilliseconds / 1000;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_intro, _dizzy]),
    builder: (context, _) => _stage(context),
  );

  Widget _stage(BuildContext context) {
    final c = widget.controller;
    final r = c.result!;
    final p = widget.progress;
    // A level's stars take the place of flight wings and the endless best.
    final level = c.level;
    final goals = level == null
        ? FlightGoals.forRun(r)
        : const <FlightGoalProgress>[];
    final newStamps = p.passport
        .where((s) => s.earned && !widget.initialStamps.contains(s.stamp))
        .toList();
    final nextStamp = p.nextStamp;
    final newDailyCard =
        c.saved &&
        p.today?.complete == true &&
        (widget.initialDailyKey != p.today?.dayKey ||
            !widget.initialDailyComplete);
    final isBest = level == null && r.score > widget.initialBest;
    final best = p.record(widget.mode, widget.course).best;
    final armed = _intro.value >= GameOverStage.armAt || _intro.isCompleted;
    final fade = _calm ? _intro.value.clamp(0.0, 1.0) : 1.0;
    final caption = isBest
        ? 'Bumped out on a brand-new best!'
        : widget.splash
        ? 'A little splash in the sea.'
        : 'A little bump in the clouds.';

    return Opacity(
      opacity: fade,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A deep vignette quiets the dimmed world behind the stage.
          IgnorePointer(
            child: Opacity(
              opacity: _span(0, .25),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-.35, -.1),
                    radius: 1.25,
                    colors: [Color(0x26203b45), Color(0x9e203b45)],
                  ),
                ),
              ),
            ),
          ),
          SceneLayout(
            child: IgnorePointer(
              ignoring: !armed,
              child: Stack(
                children: [
                  // A soft spotlight that lifts the bird off the world.
                  Positioned(
                    left: 0,
                    top: 120,
                    width: 410,
                    height: 330,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: _span(.05, .4),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0, .05),
                              radius: .62,
                              colors: [
                                Color(0x8cfff9ed),
                                Color(0x33fff9ed),
                                Color(0x00fff9ed),
                              ],
                              stops: [0, .55, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 104,
                    width: 380,
                    height: 346,
                    child: _vignette(isBest),
                  ),
                  Positioned(
                    left: 0,
                    width: 410,
                    top: 4,
                    child: _title(caption),
                  ),
                  // The keys keep one place from flight to flight; the
                  // scoreboard hugs its content just above them.
                  Positioned(
                    left: 418,
                    right: 20,
                    top: 12,
                    bottom: 14,
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _card(
                              context,
                              r,
                              goals,
                              best: isBest ? math.max(best, r.score) : best,
                              isBest: isBest,
                              link: _link(
                                r,
                                newDailyCard: newDailyCard,
                                newStamps: newStamps,
                                nextStamp: nextStamp,
                              ),
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
          ),
        ],
      ),
    );
  }

  Widget _vignette(bool isBest) {
    final rise = _span(.02, .42, Curves.easeOutBack);
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * 380),
        child: CustomPaint(
          painter: StageBirdPainter(
            bird: widget.controller.bird,
            seconds: _dizzySeconds,
            wet: widget.splash,
            cheer: isBest ? _span(.78, 1) : 0,
          ),
        ),
      ),
    );
  }

  Widget _title(String caption) {
    final level = widget.controller.level;
    final word = widget.splash ? 'Splash!' : 'Bonk!';
    final letters = word.split('');
    final plate = _span(.26, .46, Curves.easeOutBack);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          label: word,
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (i, letter) in letters.indexed)
                  _letter(letter, i, letters.length),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // The caption rides on a cream plate so it reads over any world.
        Opacity(
          opacity: plate.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: .7 + .3 * plate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              child: level == null
                  ? Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: bodyText(16, weight: FontWeight.w900),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // A level's number leads its caption, as on the
                        // result's plate.
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 1),
                          decoration: BoxDecoration(
                            // The result's chip colours: a chapter's boss coral, a
                            // guardian lavender.
                            color: level.isChapterBoss
                                ? SkyColors.coral
                                : level.isGuardian
                                ? SkyColors.lavender
                                : SkyColors.yellow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: SkyColors.ink,
                              width: 1.8,
                            ),
                          ),
                          child: Text(
                            level.id,
                            style: heading(15, weight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          caption,
                          style: bodyText(16, weight: FontWeight.w900),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Each letter drops from above, lands with a squash and settles at its
  /// own jaunty angle, like a sign bouncing into place.
  Widget _letter(String letter, int i, int count) {
    final start = .03 + i * .04;
    final t = _span(start, start + .26);
    final fall = Curves.bounceOut.transform(t);
    final squash = t <= 0 || t >= 1 ? 0.0 : math.sin(t * math.pi) * .12;
    final tilt = [-.07, .05, -.03, .06, -.05, .04, -.02][i % 7];
    final style = heading(96, weight: FontWeight.w700);
    return Opacity(
      opacity: t > 0 ? 1 : 0,
      child: Transform.translate(
        offset: Offset(0, (1 - fall) * -150),
        child: Transform.rotate(
          angle: tilt * (_calm ? 1 : fall),
          child: Transform.scale(
            scaleX: 1 + squash,
            scaleY: 1 - squash,
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Stack(
                children: [
                  Transform.translate(
                    offset: const Offset(0, 6),
                    child: Text(
                      letter,
                      style: style.copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 12
                          ..strokeJoin = StrokeJoin.round
                          ..color = SkyColors.ink.withValues(alpha: .35),
                      ),
                    ),
                  ),
                  Text(
                    letter,
                    style: style.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 10
                        ..strokeJoin = StrokeJoin.round
                        ..color = SkyColors.ink,
                    ),
                  ),
                  Text(
                    letter,
                    style: style.copyWith(
                      color: i.isEven ? SkyColors.cream : SkyColors.yellow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static final _label = bodyText(
    12.5,
    color: SkyColors.muted,
    weight: FontWeight.w900,
  ).copyWith(letterSpacing: .8);

  /// A sand inset for the quieter parts of the scoreboard.
  static const _inset = Color(0xfff6ecda);

  /// The scoreboard: an ink-framed card with the score and best on top,
  /// this flight's stats beneath, then progress and save status.
  Widget _card(
    BuildContext context,
    RunResult r,
    List<FlightGoalProgress> goals, {
    required int best,
    required bool isBest,
    required Widget? link,
  }) {
    final t = _span(.1, .36, Curves.easeOutCubic);
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
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 116,
                  child: widget.controller.level == null
                      ? _scores(r, best: best, isBest: isBest)
                      : _levelScores(r, widget.controller.level!),
                ),
                const SizedBox(height: 6),
                _stats(r),
                const SizedBox(height: 10),
                // Long messages scroll rather than push the keys away.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (goals.isNotEmpty || link != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _progress(context, r, goals, link),
                          ),
                        Opacity(
                          opacity: _span(.36, .56),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _status(r),
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
      ),
    );
  }

  Widget _scores(RunResult r, {required int best, required bool isBest}) {
    final count = _span(.3, .7, Curves.easeOutCubic);
    final land = math.sin(_span(.7, .8) * math.pi);
    final ribbon = _span(.72, .92, Curves.elasticOut);
    final shown = (r.score * count).round();
    // A new best keeps the old record on the plaque until the score lands,
    // then the plaque turns gold under its ribbon.
    final gild = isBest ? _span(.72, .78) : 0.0;
    final record = isBest && gild <= 0 ? widget.initialBest : best;
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.course.scoreLabel, style: _label),
              Flexible(
                child: Transform.scale(
                  scale: 1 + .08 * land,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$shown',
                      style: heading(
                        82,
                        weight: FontWeight.w700,
                        color: isBest && count >= 1
                            ? SkyColors.coralDeep
                            : SkyColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 208,
          child: Center(
            child: Container(
              width: 176,
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
                          child: Text('PERSONAL BEST', style: _label),
                        ),
                        if (isBest && ribbon > 0)
                          OverflowBox(
                            maxWidth: 260,
                            maxHeight: 40,
                            child: Transform.scale(
                              scale: ribbon,
                              child: Transform.rotate(
                                angle: -.04,
                                child: const StageRibbon('NEW PERSONAL BEST!'),
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
                          child: Text(
                            '$record',
                            style: heading(44, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A level's scoreboard: the stars collected against the level's next
  /// mark, and how far along the route the bird got, or how much fight the
  /// boss had left.
  Widget _levelScores(RunResult r, CampaignLevel level) {
    final count = _span(.3, .7, Curves.easeOutCubic);
    final land = math.sin(_span(.7, .8) * math.pi);
    final sim = widget.controller.simulation!;
    final boss = sim.boss?.defeatedAt == null ? sim.boss : null;
    final flown = (sim.routeProgress * 100).floor();
    final marks = level.marks;
    // The next collection mark, as the level card shows it.
    final (mark, at) = r.stars < marks.two
        ? (2, marks.two)
        : r.stars < marks.three
        ? (3, marks.three)
        : (3, null);
    final label = _label.copyWith(fontSize: 13);
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('STARS COLLECTED', style: label),
              Flexible(
                child: Transform.scale(
                  scale: 1 + .08 * land,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${(r.stars * count).round()}',
                      style: heading(68, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Semantics(
                label: at == null
                    ? 'Every mark reached'
                    : '${at - r.stars} more stars for $mark stars',
                excludeSemantics: true,
                child: at == null
                    ? _marksReached(
                        beat: boss != null && boss.isMiniBoss
                            ? boss.name
                            : null,
                      )
                    : _nextMark(mark, at, r.stars, count),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 208,
          child: Center(
            child: Semantics(
              label: boss != null
                  ? '${boss.name}: ${boss.hp} of ${boss.maxHp} health left'
                  : '$flown percent of the route flown',
              excludeSemantics: true,
              child: Container(
                width: 184,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  color: _inset,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: SkyColors.sand.withValues(alpha: .6),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A long boss name shrinks rather than wrapping.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        boss != null
                            // "KING COO LEFT" reads as "went away": a guardian
                            // says what is left of him.
                            ? boss.isMiniBoss
                                  ? '${boss.name.toUpperCase()}: ${boss.hp} HP LEFT'
                                  : '${boss.name.toUpperCase()} LEFT'
                            : 'ROUTE FLOWN',
                        maxLines: 1,
                        style: label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          boss != null
                              ? Icons.favorite_rounded
                              : Icons.flag_rounded,
                          size: 30,
                          color: boss != null
                              ? SkyColors.coral
                              : SkyColors.teal,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              boss != null
                                  ? '${boss.hp} HP'
                                  : '${(flown * count).round()}%',
                              style: heading(42, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // The route so far, or the boss's remaining health.
                    _meter(
                      boss != null
                          ? boss.hp / boss.maxHp
                          : sim.routeProgress * count,
                      boss != null ? SkyColors.coral : SkyColors.teal,
                      height: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A slim inked meter, filled [value] of the way.
  Widget _meter(
    double value,
    Color color, {
    required double height,
    double? width,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: SkyColors.sand.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(height / 2),
      border: Border.all(
        color: SkyColors.ink.withValues(alpha: .6),
        width: 1.6,
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

  /// How far the stars collected are from the next mark: a meter that
  /// fills toward the rating it earns, and how many more it takes.
  Widget _nextMark(int mark, int at, int stars, double count) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _meter(stars / at * count, SkyColors.gold, height: 13, width: 96),
      const SizedBox(width: 8),
      Text(
        '${at - stars} more for',
        style: bodyText(14, color: SkyColors.muted, weight: FontWeight.w900),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 46,
        height: 15,
        child: CustomPaint(painter: MapStarsPainter(mark)),
      ),
    ],
  );

  /// Both star marks were reached, so the finish is all that is missing; a
  /// guardian's level says what is left to do ([beat] is his name).
  Widget _marksReached({String? beat}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 46,
        height: 15,
        child: CustomPaint(painter: MapStarsPainter(3)),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            beat == null
                ? 'Both marks reached'
                : 'Both marks reached. Beat $beat!',
            style: bodyText(
              14,
              color: const Color(0xff2e7d6f),
              weight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ],
  );

  /// This flight's numbers, as quiet tiles on a sand inset.
  Widget _stats(RunResult r) {
    final repsLabel = switch (widget.mode) {
      PlayMode.pushUp => 'push-ups',
      PlayMode.squat => 'squats',
      PlayMode.jump => 'jumps',
      PlayMode.touch => 'flaps',
    };
    final stats = <(IconData, Color, String, String)>[
      (
        widget.mode == PlayMode.touch
            ? Icons.touch_app_outlined
            : Icons.fitness_center_rounded,
        SkyColors.sky,
        '${widget.mode.controlsHeight ? r.repetitions : r.flaps}',
        repsLabel,
      ),
      (
        Icons.timer_outlined,
        SkyColors.sky,
        '${r.durationSeconds.round()}s',
        'flight time',
      ),
      (
        Icons.center_focus_strong_rounded,
        SkyColors.mint,
        '${r.perfectPasses}',
        'perfect',
      ),
      if (r.course.collectsStars)
        (Icons.auto_awesome, SkyColors.yellow, '${r.bestCombo}', 'best streak')
      else if (r.score >= 5)
        (
          Icons.workspace_premium_outlined,
          SkyColors.yellow,
          r.score >= 25
              ? 'Sky captain'
              : r.score >= 10
              ? 'Cloud explorer'
              : 'First wings',
          'rank',
        ),
    ];
    final k = _span(.2, .42, Curves.easeOutCubic);
    return Opacity(
      opacity: k,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _inset,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            for (final (i, (icon, color, value, label)) in stats.indexed) ...[
              if (i > 0)
                Container(
                  width: 1.5,
                  height: 32,
                  color: SkyColors.sand.withValues(alpha: .55),
                ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 17, color: SkyColors.ink),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A rank is a word, so it wraps rather than
                          // shrinking below its label.
                          if (value.length > 5)
                            Text(
                              value,
                              maxLines: 2,
                              style: heading(16, weight: FontWeight.w700),
                            )
                          else
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                style: heading(24, weight: FontWeight.w700),
                              ),
                            ),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyText(
                              13,
                              color: SkyColors.muted,
                              weight: FontWeight.w800,
                            ).copyWith(height: 1.1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Flight wings and the passport or postcard link, side by side.
  Widget _progress(
    BuildContext context,
    RunResult r,
    List<FlightGoalProgress> goals,
    Widget? link,
  ) => Opacity(
    opacity: _span(.3, .52),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (goals.isNotEmpty)
          _chip(
            key: const ValueKey('result-flight-goals'),
            fill: false,
            onTap: () => showFlightGoals(context, r.course, progress: goals),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlightWings(goals: goals, size: 24),
                const SizedBox(height: 2),
                Text(
                  '${FlightGoals.earned(goals)}/3 flight wings',
                  style: bodyText(12, weight: FontWeight.w900),
                ),
              ],
            ),
          ),
        if (goals.isNotEmpty && link != null) const SizedBox(width: 8),
        if (link != null) Expanded(child: link),
      ],
    ),
  );

  /// A tappable progress chip: something leading, a body and a chevron.
  /// A [fill] chip stretches its body so the chevron sits at the far edge.
  Widget _chip({
    Key? key,
    required VoidCallback onTap,
    Widget? leading,
    required Widget body,
    bool fill = true,
  }) => Material(
    key: key,
    color: SkyColors.white.withValues(alpha: .75),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: SkyColors.ink.withValues(alpha: .2), width: 1.5),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Flexible(fit: fill ? FlexFit.tight : FlexFit.loose, child: body),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: SkyColors.muted,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _badge(IconData icon, Color color) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: SkyColors.ink, width: 1.8),
    ),
    child: Icon(icon, size: 19, color: SkyColors.ink),
  );

  /// The same passport and postcard links as the results panel.
  Widget? _link(
    RunResult r, {
    required bool newDailyCard,
    required List<StampProgress> newStamps,
    required StampProgress? nextStamp,
  }) {
    final title = bodyText(14, weight: FontWeight.w900);
    final detail = bodyText(
      12,
      color: SkyColors.muted,
      weight: FontWeight.w700,
    );
    if (newDailyCard) {
      return _chip(
        onTap: () => widget.onLeave('/daily'),
        leading: _badge(Icons.local_post_office_outlined, SkyColors.mint),
        body: Text('Today’s postcard stamped!', style: title),
      );
    }
    if (newStamps.isNotEmpty) {
      final stamp = newStamps.first.stamp;
      return _chip(
        onTap: () => widget.onLeave('/passport'),
        leading: _badge(Icons.workspace_premium_rounded, SkyColors.yellow),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stamp earned: ${stamp.title}', style: title),
            Text(
              stamp.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: detail,
            ),
          ],
        ),
      );
    }
    if (widget.controller.saved && nextStamp != null) {
      final stamp = nextStamp.stamp;
      return _chip(
        onTap: () => widget.onLeave('/passport'),
        leading: _badge(Icons.explore_outlined, SkyColors.sky),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Next stamp: ${stamp.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: title,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${nextStamp.current}/${stamp.target}',
                  style: bodyText(13, weight: FontWeight.w900),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: nextStamp.fraction,
                  minHeight: 6,
                  color: SkyColors.teal,
                  backgroundColor: SkyColors.sand.withValues(alpha: .35),
                ),
              ),
            ),
            Text(
              stamp.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: detail,
            ),
          ],
        ),
      );
    }
    return null;
  }

  /// Save status (tap to retry), then session and camera messages.
  List<Widget> _status(RunResult r) {
    final c = widget.controller;
    Widget note(IconData icon, String text, Color color) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: bodyText(12.5, color: color, weight: FontWeight.w700),
          ),
        ),
      ],
    );
    return [
      if (c.saveError.isNotEmpty)
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
              c.saveError,
              style: bodyText(
                13.5,
                weight: FontWeight.w900,
                color: SkyColors.coralDeep,
              ),
            ),
          ),
        )
      else
        note(
          c.saved
              ? Icons.check_circle_outline_rounded
              : Icons.hourglass_top_rounded,
          c.saved
              // Gates count endless flights only, so a level just saves.
              ? c.campaign
                    ? 'Saved on this phone'
                    : 'Saved on this phone · ${widget.progress.totalObstacles} total gates'
              : 'Saving your flight…',
          SkyColors.muted,
        ),
      if (c.sessionSaved)
        note(
          Icons.video_library_outlined,
          'Session saved · Watch in Records',
          // Teal deepened so small text keeps its contrast on cream.
          const Color(0xff2e7d6f),
        ),
      if (c.sessionError.isNotEmpty || c.cameraRecordingError.isNotEmpty)
        note(
          Icons.error_outline_rounded,
          c.sessionError.isNotEmpty ? c.sessionError : c.cameraRecordingError,
          SkyColors.coralDeep,
        ),
    ];
  }

  Widget _actions(RunResult r) {
    final c = widget.controller;
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

    // Fly again gives a little hop and a glint once the bird looks ready.
    final s = _dizzySeconds;
    final ready = s == null
        ? 0.0
        : ((s - StageBirdPainter._recovered) / .6).clamp(0.0, 1.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // A level goes back to the map rather than Home.
        SizedBox(
          width: 100,
          child: pop(
            .34,
            c.campaign
                ? StageKey(
                    key: const ValueKey('game-over-map'),
                    label: 'Map',
                    icon: Icons.map_rounded,
                    // Tall enough to stay 48 dp on the smallest phone.
                    height: 76,
                    onPressed: () => widget.onLeave('/campaign'),
                  )
                : StageKey(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    onPressed: widget.onLeave,
                  ),
          ),
        ),
        if (c.simulation?.started == true) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 136,
            child: pop(
              .37,
              StageKey(
                key: const ValueKey('save-or-watch-session'),
                height: c.campaign ? 76 : null,
                label: c.sessionSaved
                    ? 'Watch replay'
                    : c.preparingReplay
                    ? 'Preparing…'
                    : c.sessionSaving
                    ? 'Saving…'
                    : 'Save session',
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
            .4,
            Transform.scale(
              scale: 1 + .06 * math.sin(ready * math.pi),
              child: StageKey(
                key: const ValueKey('game-over-fly-again'),
                label: c.campaign ? 'Retry' : 'Fly again',
                icon: Icons.replay_rounded,
                hero: true,
                shine: ready,
                onPressed: () => c.retry(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The dazed bird slumped on a fluffy cloud with stars circling its head.
/// [seconds] runs the dizzy spell (null: Reduced Motion's still pose): the
/// stars circle, the bird shakes it off and looks ready to fly again.
///
/// A [happy] bird (a campaign level's result) sits up on the same cloud,
/// beaming, wings raised, with [hop] (0–1) lifting it once as it lands;
/// [cheer] still scatters its sparkles.
class StageBirdPainter extends CustomPainter {
  const StageBirdPainter({
    required this.bird,
    required this.seconds,
    required this.wet,
    required this.cheer,
    this.happy = false,
    this.hop = 0,
    this.puff = 1,
    this.beaming = false,
  });
  final int bird;
  final double? seconds;
  final bool wet, happy;
  final double cheer, hop;

  /// How far the cloud has puffed in under the bird, from 0 (not yet) to 1,
  /// overshooting a little on the way: a level's celebrating bird lands in
  /// its seat just before its cloud arrives.
  final double puff;

  /// Whether the happy courier beams from the start, having flown in from
  /// the finish line already celebrating.
  final bool beaming;

  static const design = Size(380, 346);

  /// The happy courier's pose in [design]: its centre, width, tilt and
  /// wings. A level's celebrating bird lands in exactly this pose.
  static const happyCenter = Offset(182, 162), happyWidth = 196.0;
  static const happyTilt = .04, happyWing = -.5;
  static const _shakeAt = 3.7, _recovered = 4.2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / design.width, size.height / design.height);
    final t = seconds;
    const center = Offset(186, 262);
    _puffed(canvas, center, front: false);
    if (happy) {
      _happy(canvas, center);
      canvas.restore();
      return;
    }
    // The bird sits low in the cloud, leaning back, until it shakes it off.
    final shake = t == null
        ? 0.0
        : t < _shakeAt
        ? 0.0
        : t < _recovered
        ? math.sin((t - _shakeAt) * 38) * (1 - (t - _shakeAt) / .5) * .16
        : 0.0;
    final recovered = t != null && t >= _recovered;
    final hop = t == null || t < _recovered
        ? 0.0
        : math.sin(((t - _recovered) / .35).clamp(0.0, 1.0) * math.pi) * 14;
    final lean = recovered ? 0.0 : -.12;
    const width = 196.0;
    final birdCenter = center + Offset(-4, -92 - hop);
    final expression = t == null
        ? BirdExpression.dazed
        : t < _shakeAt + .2
        ? BirdExpression.dazed
        : t < _recovered
        ? BirdExpression.blink
        : cheer > 0
        ? BirdExpression.pleased
        : BirdExpression.neutral;
    final stars = t == null
        ? 1.0
        : t < _shakeAt
        ? (t / .3).clamp(0.0, 1.0)
        : (1 - (t - _shakeAt) / .3).clamp(0.0, 1.0);
    final head = birdCenter + const Offset(10, -86);
    _orbit(canvas, head, t, stars, behind: true);
    canvas.save();
    canvas.translate(birdCenter.dx, birdCenter.dy);
    canvas.rotate(lean + shake);
    BirdPuppet.paint(
      canvas,
      const Rect.fromLTWH(-width * .48, -width * .43, width, width * 224 / 256),
      bird: bird,
      wing: recovered ? .1 : .38,
      expression: expression,
    );
    canvas.restore();
    if (wet && !recovered) _drips(canvas, birdCenter, t ?? 0);
    _orbit(canvas, head, t, stars, behind: false);
    _cloud(canvas, center, front: true);
    if (cheer > 0) _sparkles(canvas, birdCenter, cheer);
    canvas.restore();
  }

  void _happy(Canvas canvas, Offset center) {
    const width = happyWidth;
    final birdCenter = happyCenter + Offset(0, -22 * math.sin(hop * math.pi));
    canvas.save();
    canvas.translate(birdCenter.dx, birdCenter.dy);
    canvas.rotate(happyTilt);
    BirdPuppet.paint(
      canvas,
      const Rect.fromLTWH(-width * .48, -width * .43, width, width * 224 / 256),
      bird: bird,
      wing: happyWing,
      // It beams once its cheer begins.
      expression: beaming || cheer > 0 || hop > 0
          ? BirdExpression.pleased
          : BirdExpression.neutral,
    );
    canvas.restore();
    _puffed(canvas, center, front: true);
    if (cheer > 0) _sparkles(canvas, birdCenter, cheer);
  }

  void _orbit(
    Canvas c,
    Offset head,
    double? t,
    double grow, {
    required bool behind,
  }) {
    if (grow <= 0) return;
    const rx = 66.0, ry = 17.0;
    if (t != null) {
      // A faint ring shows the stars are circling, not scattered.
      final ring = Rect.fromCenter(
        center: head,
        width: rx * 2 * grow,
        height: ry * 2 * grow,
      );
      c.drawArc(
        ring,
        behind ? math.pi : 0,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = SkyColors.cream.withValues(alpha: behind ? .35 : .6),
      );
    }
    for (var i = 0; i < 3; i++) {
      final a = t == null
          ? -math.pi / 2 - .9 + i * .9
          : t * 5.2 + i * 2 * math.pi / 3;
      final depth = t == null ? 0.0 : math.sin(a);
      if (t != null && (depth < 0) != behind) continue;
      if (t == null && behind) continue;
      final p = t == null
          ? head + Offset((i - 1) * 46.0, i == 1 ? -18 : -6)
          : head + Offset(math.cos(a) * rx, depth * ry) * grow;
      final scale = (t == null ? 1 : .78 + .22 * (depth + 1) / 2) * grow;
      _star(c, p, 15 * scale, a * .5);
    }
  }

  void _star(Canvas c, Offset at, double radius, double turn) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final b = a + math.pi / 5;
      final tip = Offset(math.cos(a), math.sin(a));
      final next = Offset(
        math.cos(a + 2 * math.pi / 5),
        math.sin(a + 2 * math.pi / 5),
      );
      final valley = Offset(math.cos(b), math.sin(b)) * .48 * .78;
      if (i == 0) path.moveTo(tip.dx, tip.dy);
      path.quadraticBezierTo(valley.dx, valley.dy, next.dx, next.dy);
    }
    path.close();
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    c.scale(radius);
    c.drawPath(path, Paint()..color = SkyColors.yellow);
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xffb86a2a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 / radius
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawCircle(
      const Offset(-.12, -.14),
      .2,
      Paint()..color = SkyColors.white.withValues(alpha: .9),
    );
    c.restore();
  }

  /// A few sea drops still dripping off a soaked bird.
  void _drips(Canvas c, Offset bird, double t) {
    for (var i = 0; i < 3; i++) {
      final k = ((t * .9 + i * .37) % 1);
      final start = bird + Offset(-58.0 + i * 52, 30 + (i == 1 ? 18 : 0));
      final p = start + Offset(0, k * k * 60);
      final alpha = (1 - k).clamp(0.0, 1.0);
      final drop = Path()
        ..moveTo(p.dx, p.dy - 9)
        ..quadraticBezierTo(p.dx + 6, p.dy, p.dx, p.dy + 4)
        ..quadraticBezierTo(p.dx - 6, p.dy, p.dx, p.dy - 9)
        ..close();
      c.drawPath(
        drop,
        Paint()..color = const Color(0xff8fe3dc).withValues(alpha: alpha),
      );
      c.drawPath(
        drop,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = SkyColors.ink.withValues(alpha: alpha * .8),
      );
    }
  }

  void _sparkles(Canvas c, Offset bird, double k) {
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + .3;
      final d = 110 + 40 * k;
      final p = bird + Offset(math.cos(a) * d, math.sin(a) * d * .75 - 20);
      final r = 9 * math.sin(k.clamp(0.0, 1.0) * math.pi);
      if (r <= .5) continue;
      _star(c, p, r, a);
    }
  }

  /// Lobes over a flat base (dx, dy, radius), in design units from the
  /// cloud's centre; the front lip is drawn over the bird's lap.
  static const _back = <(double, double, double)>[
    (-112, 2, 38),
    (-62, -22, 52),
    (4, -36, 60),
    (70, -20, 50),
    (118, 4, 36),
  ];
  static const _front = <(double, double, double)>[
    (-80, 6, 34),
    (-16, 4, 36),
    (50, 6, 34),
    (104, 12, 28),
  ];

  static Path _union(Iterable<Path> parts) =>
      parts.reduce((a, b) => Path.combine(PathOperation.union, a, b));

  static Path _lobes(Offset center, List<(double, double, double)> puffs) =>
      _union([
        for (final (dx, dy, r) in puffs)
          Path()..addOval(
            Rect.fromCircle(center: center + Offset(dx, dy), radius: r),
          ),
      ]);

  static Path _silhouette(Offset center) => _union([
    Path()..addRRect(
      RRect.fromLTRBR(
        center.dx - 150,
        center.dy - 6,
        center.dx + 150,
        center.dy + 40,
        const Radius.circular(23),
      ),
    ),
    _lobes(center, _back),
  ]);

  static Path _lip(Offset center) => _union([
    Path()..addRect(
      Rect.fromLTRB(center.dx - 80, center.dy, center.dx + 104, center.dy + 40),
    ),
    _lobes(center, _front),
  ]);

  /// White with a lavender underside that follows the bottom contour.
  static void _fill(Canvas c, Path shape) {
    c.drawPath(shape, Paint()..color = const Color(0xffdcd6fb));
    c.save();
    c.translate(0, -11);
    c.drawPath(shape, Paint()..color = SkyColors.white);
    c.restore();
  }

  static void _shine(
    Canvas c,
    Offset center,
    List<(double, double, double)> puffs,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = SkyColors.cream;
    for (final (dx, dy, r) in puffs) {
      if (r < 34) continue;
      c.drawArc(
        Rect.fromCircle(center: center + Offset(dx, dy), radius: r * .66),
        math.pi * 1.12,
        .62,
        false,
        paint,
      );
    }
  }

  /// The cloud scaled up from its base by [puff].
  void _puffed(Canvas c, Offset center, {required bool front}) {
    if (puff == 1) return _cloud(c, center, front: front);
    if (puff <= 0) return;
    final base = center + const Offset(0, 40);
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(puff);
    c.translate(-base.dx, -base.dy);
    _cloud(c, center, front: front);
    c.restore();
  }

  void _cloud(Canvas c, Offset center, {required bool front}) {
    final whole = _silhouette(center);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..color = SkyColors.ink;
    if (!front) {
      // A soft shadow the cloud floats over.
      c.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 60),
          width: 280,
          height: 20,
        ),
        Paint()..color = SkyColors.ink.withValues(alpha: .2),
      );
      c.drawPath(whole, ink);
      c.save();
      c.clipPath(whole);
      _fill(c, whole);
      _shine(c, center, _back);
      c.restore();
      return;
    }
    // The lip hugs the bird's lap: only its upper edge is outlined.
    final lip = _lip(center);
    c.save();
    c.clipPath(whole);
    _fill(c, lip);
    c.clipRect(
      Rect.fromLTRB(
        center.dx - 200,
        center.dy - 120,
        center.dx + 200,
        center.dy + 4,
      ),
    );
    c.drawPath(lip, ink..strokeWidth = 5.5);
    c.restore();
    _shine(c, center, _front);
  }

  @override
  bool shouldRepaint(StageBirdPainter old) =>
      old.bird != bird ||
      old.seconds != seconds ||
      old.wet != wet ||
      old.cheer != cheer ||
      old.happy != happy ||
      old.hop != hop ||
      old.puff != puff ||
      old.beaming != beaming;
}
