import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/tutorial.dart';
import '../domain/tutorial_story.dart';
import '../game/sound_bank.dart';
import '../l10n/l10n.dart';
import 'components.dart';
import 'match_hud.dart' show MatchPlate;
import 'story_scene.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// The end of flight school, over the settled finish: the rookie Pirate
/// Captain's retreat and Bill's verdict ([TutorialStory.outro]), then the
/// new courier's licence. Its skills tick in one by one, Bill's
/// "Certified" stamp comes down on it, and confetti falls. [onStart] opens
/// the campaign map, [onAgain] flies the lesson again.
class TutorialFinale extends StatefulWidget {
  const TutorialFinale({
    super.key,
    required this.coach,
    required this.stars,
    required this.bird,
    required this.onStart,
    required this.onAgain,
    this.voices = true,
    this.reducedMotion = false,
  });
  final TutorialCoach coach;
  final int stars, bird;
  final bool voices, reducedMotion;
  final VoidCallback onStart, onAgain;

  @override
  State<TutorialFinale> createState() => _TutorialFinaleState();
}

class _TutorialFinaleState extends State<TutorialFinale> {
  bool _scene = true;

  @override
  Widget build(BuildContext context) {
    final still =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: Duration(milliseconds: still ? 0 : 420),
      child: _scene
          ? StoryScenePlayer(
              key: const ValueKey('tutorial-outro'),
              scene: TutorialStory.outro,
              bird: widget.bird,
              voices: widget.voices,
              reducedMotion: still,
              onDone: () => setState(() => _scene = false),
            )
          : CourierLicence(
              key: const ValueKey('courier-licence'),
              bird: widget.bird,
              stars: widget.stars,
              reducedMotion: still,
              onStart: widget.onStart,
              onAgain: widget.onAgain,
            ),
    );
  }
}

/// The courier licence Bill hands over: the bird's picture and name, its
/// rank, the skills of flight school ticked, his signature and his stamp.
class CourierLicence extends StatefulWidget {
  const CourierLicence({
    super.key,
    required this.bird,
    required this.stars,
    required this.onStart,
    required this.onAgain,
    this.reducedMotion = false,
  });
  final int bird, stars;
  final bool reducedMotion;
  final VoidCallback onStart, onAgain;

  /// When (seconds) the card has landed, each skill is ticked, the stamp
  /// comes down and the keys appear.
  static const landed = .55, firstTick = .7, tickEvery = .16;
  static const stampAt = firstTick + 7 * tickEvery + .25;
  static const keysAt = stampAt + .45;
  static const length = keysAt + .4;

  @override
  State<CourierLicence> createState() => _CourierLicenceState();
}

class _CourierLicenceState extends State<CourierLicence>
    with TickerProviderStateMixin {
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (CourierLicence.length * 1000).round()),
  );

  /// Confetti, falling for as long as the licence is up.
  late final AnimationController _fall = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _stamped = false;

  @override
  void initState() {
    super.initState();
    if (widget.reducedMotion) {
      _show.value = 1;
    } else {
      _show.addListener(_beat);
      _show.forward();
      _fall.repeat();
    }
  }

  void _beat() {
    final t = _show.value * CourierLicence.length;
    if (!_stamped && t >= CourierLicence.stampAt) {
      _stamped = true;
      UiSounds.effect(
        context,
        soundBank.containsKey('tutorial_stamp') ? 'tutorial_stamp' : 'unlock',
      );
    }
  }

  @override
  void dispose() {
    _show.dispose();
    _fall.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: SkyColors.night.withValues(alpha: .55),
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (!widget.reducedMotion)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _fall,
              builder: (context, _) =>
                  CustomPaint(painter: _ConfettiPainter(_fall.value)),
            ),
          ),
        SceneLayout(
          child: AnimatedBuilder(
            animation: _show,
            builder: (context, _) =>
                _card(context, _show.value * CourierLicence.length),
          ),
        ),
      ],
    ),
  );

  static double _ease(double t) =>
      Curves.easeOutBack.transform(t.clamp(0.0, 1.0));

  Widget _card(BuildContext context, double t) {
    final l = context.l10n;
    final land = _ease(t / CourierLicence.landed);
    final keys = ((t - CourierLicence.keysAt) / .35).clamp(0.0, 1.0);
    final skills = [
      l.tutorialGoalFlaps,
      l.tutorialGoalStars,
      l.tutorialGoalGates,
      l.tutorialGoalBats,
      l.tutorialGoalDoor,
      l.tutorialGoalSprint,
      l.tutorialGoalBoss,
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 170,
          top: 18,
          width: 660,
          height: 330,
          child: Opacity(
            opacity: (t / .2).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 60 * (1 - land)),
              child: Transform.rotate(
                angle: -.025 * land,
                child: Transform.scale(
                  scale: .8 + .2 * land,
                  child: _Licence(
                    bird: widget.bird,
                    stars: widget.stars,
                    skills: skills,
                    ticked: [
                      for (var i = 0; i < skills.length; i++)
                        t >=
                            CourierLicence.firstTick +
                                i * CourierLicence.tickEvery,
                    ],
                    stamp: ((t - CourierLicence.stampAt) / .22).clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 14,
          child: Opacity(
            opacity: keys,
            child: IgnorePointer(
              ignoring: keys < 1,
              child: LanguageDirection(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      key: const ValueKey('licence-again'),
                      onPressed: () {
                        UiSounds.effect(context);
                        widget.onAgain();
                      },
                      icon: const Icon(
                        Icons.replay_rounded,
                        color: SkyColors.cream,
                      ),
                      label: Text(
                        l.licenceAgain,
                        style: bodyText(
                          16,
                          color: SkyColors.cream,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    SkyButton(
                      key: const ValueKey('licence-start'),
                      label: l.licenceStart,
                      icon: Icons.map_rounded,
                      color: SkyColors.mint,
                      autofocus: true,
                      onPressed: widget.onStart,
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
}

/// The card itself, laid out the language's way.
class _Licence extends StatelessWidget {
  const _Licence({
    required this.bird,
    required this.stars,
    required this.skills,
    required this.ticked,
    required this.stamp,
  });
  final int bird, stars;
  final List<String> skills;
  final List<bool> ticked;

  /// The stamp's fall, 0 (not yet) to 1 (on the card).
  final double stamp;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LanguageDirection(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SkyColors.cream,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SkyColors.ink, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              offset: Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: _AirmailEdge())),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The header band: the post and the card's name.
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xff4583c4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mail_rounded,
                          color: SkyColors.yellow,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                L10n.upper(l.licenceIssuer),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyText(
                                  12,
                                  color: SkyColors.cream,
                                  weight: FontWeight.w900,
                                ).copyWith(letterSpacing: 1.6),
                              ),
                              Text(
                                l.licenceTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: heading(
                                  28,
                                  color: SkyColors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        MatchPlate(
                          color: SkyColors.yellow,
                          radius: 14,
                          padding: const EdgeInsets.fromLTRB(8, 2, 10, 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: SkyColors.ink,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l.licenceStars(stars),
                                style: heading(16, weight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The picture, in a scalloped photo frame.
                          Container(
                            width: 150,
                            height: 172,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [SkyColors.skyDeep, SkyColors.sky],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: SkyColors.ink,
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: BirdArt(bird: bird, size: 120, bob: false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Field(
                                        label: l.licenceHolder,
                                        value: l.birdName(bird),
                                      ),
                                    ),
                                    Expanded(
                                      child: _Field(
                                        label: l.licenceRank,
                                        value: l.licenceRankRookie,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  L10n.upper(l.licenceSkills),
                                  style: bodyText(
                                    11,
                                    color: SkyColors.muted,
                                    weight: FontWeight.w900,
                                  ).copyWith(letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 2),
                                Expanded(
                                  child: _Skills(
                                    skills: skills,
                                    ticked: ticked,
                                  ),
                                ),
                                Text(
                                  l.licenceSignedBy(l.postmasterName),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bodyText(
                                    14,
                                    color: const Color(0xff2e5f93),
                                    weight: FontWeight.w700,
                                  ).copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (stamp > 0)
                // In the free corner under the skills.
                PositionedDirectional(
                  end: 34,
                  bottom: 10,
                  child: Opacity(
                    opacity: math.min(1, stamp * 2),
                    child: Transform.rotate(
                      angle: -.32,
                      child: Transform.scale(
                        scale: 2.6 - 1.6 * Curves.easeIn.transform(stamp),
                        child: _Stamp(text: L10n.upper(l.licenceStamp)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        L10n.upper(label),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: bodyText(
          11,
          color: SkyColors.muted,
          weight: FontWeight.w900,
        ).copyWith(letterSpacing: 1.2),
      ),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: heading(22, weight: FontWeight.w700),
      ),
    ],
  );
}

/// The ticked skills in two columns.
class _Skills extends StatelessWidget {
  const _Skills({required this.skills, required this.ticked});
  final List<String> skills;
  final List<bool> ticked;

  @override
  Widget build(BuildContext context) {
    final half = (skills.length / 2).ceil();
    Widget column(int from, int to) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = from; i < to; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                AnimatedScale(
                  scale: ticked[i] ? 1 : .4,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    ticked[i]
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: ticked[i] ? SkyColors.teal : SkyColors.muted,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    skills[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(14, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(0, half)),
        Expanded(child: column(half, skills.length)),
      ],
    );
  }
}

/// Bill's rubber stamp: a double ring in post-office red with the word
/// across it.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.text});
  final String text;

  static const _red = Color(0xffd2453b);

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('licence-stamp'),
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: _red.withValues(alpha: .85), width: 4),
    ),
    padding: const EdgeInsets.all(5),
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _red.withValues(alpha: .85), width: 1.5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: _red, size: 18),
                Text(
                  text,
                  style: heading(
                    20,
                    color: _red.withValues(alpha: .9),
                    weight: FontWeight.w700,
                  ).copyWith(letterSpacing: 1),
                ),
                const Icon(Icons.star_rounded, color: _red, size: 18),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The card's airmail edge: red and blue stripes round its border.
class _AirmailEdge extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const band = 7.0, stripe = 16.0;
    final inner = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(band),
      const Radius.circular(14),
    );
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(inner),
      ),
    );
    final paints = [
      Paint()..color = const Color(0xffd2453b),
      Paint()..color = SkyColors.cream,
      Paint()..color = const Color(0xff4583c4),
      Paint()..color = SkyColors.cream,
    ];
    var i = 0;
    for (var x = -size.height; x < size.width + size.height; x += stripe) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + stripe, 0)
          ..lineTo(x + stripe + size.height, size.height)
          ..lineTo(x + size.height, size.height)
          ..close(),
        paints[i++ % paints.length],
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AirmailEdge old) => false;
}

/// Paper confetti in the game's colours, drifting down and turning.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.t);
  final double t;

  static const _colors = [
    SkyColors.coral,
    SkyColors.yellow,
    SkyColors.mint,
    SkyColors.lavender,
    SkyColors.sky,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    for (var i = 0; i < 70; i++) {
      final x0 = random.nextDouble();
      final speed = .6 + random.nextDouble() * .8;
      final phase = random.nextDouble();
      final y = ((t * speed + phase) % 1.0) * (size.height + 40) - 20;
      final sway = math.sin((t * 6 + phase * 10) * math.pi) * 14;
      final paint = Paint()..color = _colors[i % _colors.length];
      canvas.save();
      canvas.translate(x0 * size.width + sway, y);
      canvas.rotate((t * 8 + phase * 6) * math.pi);
      canvas.drawRect(const Rect.fromLTWH(-4, -2.5, 8, 5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
