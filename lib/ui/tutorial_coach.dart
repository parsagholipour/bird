import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/campaign_story.dart' show StoryMood;
import '../domain/tutorial.dart';
import '../domain/tutorial_story.dart';
import '../l10n/l10n.dart';
import 'match_hud.dart';
import 'story_postmaster_art.dart';
import 'theme.dart';

/// Where flight school's coach points, in the flight HUD's [SceneLayout]
/// units (1000 × 450): the Shoot and Sprint faces as `_flightHud` lays
/// them out (play_screen.dart).
abstract final class CoachTargets {
  static const _edge = MatchLayout.edge, _bottom = MatchLayout.edge + 6;
  static const shotSize = 96.0, sprintSize = 80.0;

  static const shoot = Offset(
    1000 - _edge - shotSize / 2,
    450 - _bottom - shotSize / 2,
  );
  static const sprint = Offset(
    1000 - _edge - shotSize - MatchLayout.gap - 4 - sprintSize / 2,
    450 - _bottom - (shotSize - sprintSize) / 2 - sprintSize / 2,
  );
}

/// Flight school over the flight (inside the HUD's [SceneLayout]): Bill in a
/// round frame with his line in a speech bubble at the bottom of the
/// screen, the lesson's goal on a chip over it, a burst of praise when a
/// goal is met and, while a lesson holds the moment still, a shade with a
/// spotlight on what to press and a pulsing shout.
///
/// It never takes a touch: taps fall through to the sky and the HUD's
/// keys, which pass them on to the coach (`PlayController`).
class TutorialCoachLayer extends StatefulWidget {
  const TutorialCoachLayer({
    super.key,
    required this.coach,
    required this.bird,
    this.reducedMotion = false,
  });
  final TutorialCoach coach;
  final int bird;
  final bool reducedMotion;

  @override
  State<TutorialCoachLayer> createState() => _TutorialCoachLayerState();
}

class _TutorialCoachLayerState extends State<TutorialCoachLayer>
    with SingleTickerProviderStateMixin {
  /// Seconds of idle life for pulses, the bob and Bill's talking bill.
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  bool get _still =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _life.stop();
    } else if (!_life.isAnimating) {
      _life.repeat();
    }
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _life,
      builder: (context, _) => _layer(context, _life.value * 60),
    ),
  );

  Widget _layer(BuildContext context, double t) {
    final coach = widget.coach;
    final l = context.l10n;
    final line = coach.line;
    final hold = coach.waitingFor;
    final still = _still;
    // The shade deepens as time slows to a stop.
    final shade = coach.holding ? 1 - coach.timeScale : 0.0;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (shade > 0)
          CustomPaint(
            painter: _ShadePainter(
              amount: shade,
              hole: switch (hold) {
                CoachGesture.shoot ||
                CoachGesture.holdShoot => CoachTargets.shoot,
                CoachGesture.sprint => CoachTargets.sprint,
                _ => null,
              },
              radius: hold == CoachGesture.sprint
                  ? CoachTargets.sprintSize * .78
                  : CoachTargets.shotSize * .74,
              pulse: still ? .5 : .5 + .5 * math.sin(t * 6),
            ),
          ),
        if (coach.holding) _prompt(context, hold, t, still),
        if (coach.goal case final goal? when !coach.holding)
          Positioned(
            left: 300,
            right: 300,
            bottom: 122,
            child: Center(
              child: _GoalChip(goal: goal, label: _goalLabel(l, goal.kind)),
            ),
          ),
        if (coach.praising)
          Positioned(
            left: 0,
            right: 0,
            top: 96,
            child: Center(
              child: _Praise(
                key: ValueKey('praise-${coach.praises}'),
                text: switch (coach.praises % 3) {
                  0 => l.tutorialPraiseSuper,
                  1 => l.tutorialPraiseNice,
                  _ => l.tutorialPraiseGreat,
                },
                age: coach.praiseAge,
                still: still,
              ),
            ),
          ),
        if (line != null)
          Positioned(
            left: 250,
            right: 220,
            bottom: 14,
            child: AnimatedOpacity(
              opacity: coach.speaking ? 1 : 0,
              duration: Duration(milliseconds: still ? 0 : 260),
              child: _Bubble(
                key: const ValueKey('coach-bubble'),
                text: L10n.captions.line(
                  TutorialStory.coach(line),
                  0,
                  bird: widget.bird,
                ),
                // His bill works while the line is fresh.
                talking: !still && coach.lineAge < 1.8,
                t: t,
                mood: line == CoachLine.victory || line == CoachLine.powerDone
                    ? StoryMood.happy
                    : line == CoachLine.pirate || line == CoachLine.tide
                    ? StoryMood.surprised
                    : StoryMood.plain,
              ),
            ),
          ),
      ],
    );
  }

  /// The shout while a lesson holds: by the sky for a tap, beside the key
  /// for Shoot or Sprint.
  Widget _prompt(
    BuildContext context,
    CoachGesture hold,
    double t,
    bool still,
  ) {
    final l = context.l10n;
    final text = switch (hold) {
      CoachGesture.tap => l.tutorialPromptTap,
      CoachGesture.shoot => l.tutorialPromptShoot,
      CoachGesture.holdShoot => l.tutorialPromptHoldShoot,
      CoachGesture.sprint => l.tutorialPromptSprint,
      CoachGesture.none => '',
    };
    final bob = still ? 0.0 : math.sin(t * 5) * 6;
    final scale = still ? 1.0 : 1 + .06 * math.sin(t * 6);
    final shout = Semantics(
      liveRegion: true,
      label: l.tutorialWaitingSemantics(text),
      excludeSemantics: true,
      child: Transform.scale(
        scale: scale,
        child: MatchPlate(
          key: const ValueKey('coach-prompt'),
          color: SkyColors.yellow,
          radius: 22,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hold == CoachGesture.tap
                    ? Icons.touch_app_rounded
                    : hold == CoachGesture.holdShoot
                    ? Icons.pan_tool_alt_rounded
                    : Icons.ads_click_rounded,
                size: 30,
                color: SkyColors.ink,
              ),
              const SizedBox(width: 8),
              Text(
                L10n.upper(text),
                style: heading(28, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
    if (hold == CoachGesture.tap) {
      // Over the open sky ahead of the bird, with a finger tapping.
      return Positioned(
        left: 420,
        top: 150 + bob,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            shout,
            const SizedBox(height: 10),
            _TapFinger(t: t, still: still),
          ],
        ),
      );
    }
    final target = hold == CoachGesture.sprint
        ? CoachTargets.sprint
        : CoachTargets.shoot;
    // Above and to the left of the key, with an arrow down to it.
    return Positioned(
      right: 1000 - target.dx - 40,
      bottom: 450 - target.dy + 62 + bob,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          shout,
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 2),
            child: Transform.rotate(
              angle: .35,
              child: const Icon(
                Icons.arrow_downward_rounded,
                size: 40,
                color: SkyColors.yellow,
                shadows: [Shadow(color: SkyColors.ink, blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _goalLabel(AppLocalizations l, CoachGoalKind kind) =>
      switch (kind) {
        CoachGoalKind.flaps => l.tutorialGoalFlaps,
        CoachGoalKind.stars => l.tutorialGoalStars,
        CoachGoalKind.gates => l.tutorialGoalGates,
        CoachGoalKind.bats => l.tutorialGoalBats,
        CoachGoalKind.door => l.tutorialGoalDoor,
        CoachGoalKind.sprint => l.tutorialGoalSprint,
        CoachGoalKind.boss => l.tutorialGoalBoss,
      };
}

/// The shade over a held moment: dark at the edges, with a lit hole over
/// the key to press, ringed in gold.
class _ShadePainter extends CustomPainter {
  const _ShadePainter({
    required this.amount,
    required this.hole,
    required this.radius,
    required this.pulse,
  });
  final double amount, radius, pulse;
  final Offset? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // A vignette: the sky in the middle stays readable.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          SkyColors.night.withValues(alpha: .18 * amount),
          SkyColors.night.withValues(alpha: .55 * amount),
        ],
        stops: const [.3, 1],
        radius: .75,
      ).createShader(rect);
    final shade = Path()..addRect(rect.inflate(400));
    if (hole case final at?) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          shade,
          Path()..addOval(Rect.fromCircle(center: at, radius: radius)),
        ),
        vignette,
      );
      canvas.drawCircle(
        at,
        radius + 4 + 4 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = SkyColors.yellow.withValues(alpha: amount),
      );
      canvas.drawCircle(
        at,
        radius + 14 + 10 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = SkyColors.yellow.withValues(alpha: amount * (1 - pulse)),
      );
    } else {
      canvas.drawPath(shade, vignette);
    }
  }

  @override
  bool shouldRepaint(_ShadePainter old) =>
      old.amount != amount ||
      old.hole != hole ||
      old.pulse != pulse ||
      old.radius != radius;
}

/// A finger tapping the sky: it presses, a ring spreads, and it lifts.
class _TapFinger extends StatelessWidget {
  const _TapFinger({required this.t, required this.still});
  final double t;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final phase = still ? .3 : (t * 1.4) % 1;
    final press = phase < .3 ? phase / .3 : 1.0;
    final ring = phase < .3 ? 0.0 : (phase - .3) / .7;
    return SizedBox(
      width: 96,
      height: 86,
      child: CustomPaint(
        painter: _RingPainter(ring),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(10, -14 + 10 * press),
            child: const Icon(
              Icons.touch_app_rounded,
              size: 58,
              color: SkyColors.white,
              shadows: [
                Shadow(
                  color: SkyColors.ink,
                  blurRadius: 1,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.ring);
  final double ring;
  @override
  void paint(Canvas canvas, Size size) {
    if (ring <= 0) return;
    canvas.drawCircle(
      Offset(size.width / 2 - 8, size.height * .32),
      10 + 30 * ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = SkyColors.white.withValues(alpha: 1 - ring),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ring != ring;
}

/// The lesson's goal: what to do and how far along, as pips for a short
/// count, a bar for the captain's health.
class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.goal, required this.label});
  final CoachGoal goal;
  final String label;

  @override
  Widget build(BuildContext context) {
    final done = goal.done >= goal.total;
    final boss = goal.kind == CoachGoalKind.boss;
    return LanguageDirection(
      child: MatchPlate(
        key: const ValueKey('coach-goal'),
        color: done ? SkyColors.mint : SkyColors.cream,
        radius: 18,
        padding: const EdgeInsets.fromLTRB(10, 4, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.flag_rounded,
              size: 22,
              color: done ? SkyColors.teal : SkyColors.coral,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: heading(17, weight: FontWeight.w700),
              ),
            ),
            if (!boss) ...[
              const SizedBox(width: 8),
              for (var i = 0; i < goal.total; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Icon(
                    i < goal.done
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: goal.total > 4 ? 15 : 19,
                    color: i < goal.done ? SkyColors.gold : SkyColors.muted,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A burst of praise: it pops in large, settles and fades.
class _Praise extends StatelessWidget {
  const _Praise({
    super.key,
    required this.text,
    required this.age,
    required this.still,
  });
  final String text;
  final double age;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final life = (age / TutorialCoach.praiseSeconds).clamp(0.0, 1.0);
    final pop = still
        ? 1.0
        : life < .15
        ? Curves.easeOutBack.transform(life / .15)
        : 1.0;
    final fade = life > .7 ? 1 - (life - .7) / .3 : 1.0;
    return Opacity(
      opacity: fade.clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: -.06,
        child: Transform.scale(
          scale: .4 + .6 * pop,
          child: MatchTag(text, color: SkyColors.coral, size: 40),
        ),
      ),
    );
  }
}

/// Bill in a round frame beside his speech bubble.
class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.text,
    required this.talking,
    required this.t,
    required this.mood,
  });
  final String text;
  final bool talking;
  final double t;
  final StoryMood mood;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '${context.l10n.postmasterName}: $text',
    excludeSemantics: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox.square(
          dimension: 84,
          child: CustomPaint(
            painter: _BillPortraitPainter(
              open: talking ? (.5 + .5 * math.sin(t * 16)).clamp(0, 1) : 0,
              blink: (t % 3.7) < .12 ? 1 : 0,
              mood: mood,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: LanguageDirection(
            child: MatchPlate(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    text,
                    key: const ValueKey('coach-line'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(
                      17,
                      weight: FontWeight.w800,
                    ).copyWith(height: 1.2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Postmaster Bill's head and shoulders in a round frame: his story art,
/// cropped to his cap, eyes and bill.
class _BillPortraitPainter extends CustomPainter {
  const _BillPortraitPainter({
    required this.open,
    required this.blink,
    required this.mood,
  });
  final double open, blink;
  final StoryMood mood;

  /// The part of his art the frame shows.
  static const _crop = Rect.fromLTWH(56, 14, 210, 210);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      center + const Offset(0, 3),
      r,
      Paint()..color = const Color(0xff2a5c93),
    );
    canvas.drawCircle(center, r, Paint()..color = SkyColors.sky);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: r - 2)),
    );
    final scale = size.width / _crop.width;
    canvas.scale(scale);
    canvas.translate(-_crop.left, -_crop.top);
    StoryPostmasterArt.paint(canvas, mood: mood, open: open, blink: blink);
    canvas.restore();
    canvas.drawCircle(
      center,
      r - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = SkyColors.ink,
    );
  }

  @override
  bool shouldRepaint(_BillPortraitPainter old) =>
      old.open != open || old.blink != blink || old.mood != mood;
}
