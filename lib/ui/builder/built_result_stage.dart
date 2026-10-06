import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/built_level.dart';
import '../../domain/built_reach.dart';
import '../../domain/game_rules.dart';
import '../../domain/tracking.dart';
import '../../game/play_controller.dart';
import '../../game/star_art.dart';
import '../campaign_text_scale.dart';
import '../components.dart';
import '../control_glyphs.dart';
import '../game_over_stage.dart' show StageBirdPainter;
import '../match_hud.dart' show MatchIcon, MatchSymbol;
import '../stage_key.dart';
import '../theme.dart';
import 'builder_chrome.dart' show builtControl, builtModeColor, builtModeName;

/// The end of a built level's flight, staged over the frozen sky as the
/// campaign's result is: the word dropping in over the bird on its cloud
/// (beaming at the finish, dizzy after a bump), the level's three stars
/// crowning a scoreboard with the finish and the two marks under them, the
/// stars collected against the level's best, and the way on.
///
/// A creator's test flight wears a TEST tab and plate, keeps nothing and
/// leads back to the editor; one that flies the whole level to the finish
/// is stamped "Cleared by you". No story is told here.
class BuiltResultStage extends StatefulWidget {
  const BuiltResultStage({
    super.key,
    required this.controller,
    required this.flight,
    required this.before,
    required this.onLeave,
    this.handoff = false,
  });
  final PlayController controller;
  final BuiltFlight flight;

  /// The level's bests before this flight, or null before its first.
  final BuiltBest? before;
  final Future<void> Function([String destination]) onLeave;

  /// Whether the finish's celebrating bird flew all the way into the
  /// courier's seat, so the courier is already there and only its cloud
  /// puffs in.
  final bool handoff;

  static const entrance = Duration(milliseconds: 1900);
  static const calmEntrance = Duration(milliseconds: 500);

  /// When the keys may be pressed, and when each earned star lands, as
  /// shares of the entrance.
  static const armAt = .55;
  static const starsAt = [.34, .46, .58];

  /// The word over the bird.
  static String wordFor({required bool finished, required bool bumped}) =>
      finished
      ? 'Cleared!'
      : bumped
      ? 'Bonk!'
      : 'Landed';

  /// Where on the level's whole route (thousandths) [controller]'s flight
  /// got to: a test from a place started at [BuiltFlight.from], which the
  /// flight moved up to the start of its own route (after the lead-in every
  /// flight begins with).
  static int reached(PlayController controller, BuiltFlight flight) {
    final sim = controller.simulation;
    if (sim == null) return flight.from ?? 0;
    final x = ((sim.distance + FlightSimulation.birdX) * BuiltPlan.unit)
        .round();
    final from = flight.from;
    // A test from a place flies a lead-in first: it got at least there.
    return from == null
        ? math.max(0, x)
        : math.max(from, from + x - BuiltPlan.firstX);
  }

  @override
  State<BuiltResultStage> createState() => _BuiltResultStageState();
}

class _BuiltResultStageState extends State<BuiltResultStage>
    with SingleTickerProviderStateMixin {
  bool get _calm => widget.controller.reducedMotion;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _calm ? BuiltResultStage.calmEntrance : BuiltResultStage.entrance,
  )..addListener(_chime);
  int _landed = 0;

  @override
  void initState() {
    super.initState();
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Each earned star chimes as it lands; a calm stage places them quietly.
  void _chime() {
    if (_calm) return;
    final stars = _rating;
    while (_landed < stars &&
        _intro.value >= BuiltResultStage.starsAt[_landed] + .06) {
      _landed++;
      widget.controller.audio.effect(_landed == 3 ? 'wing' : 'star');
    }
  }

  double _span(double from, double to, [Curve curve = Curves.linear]) {
    if (_calm) return 1;
    final t = ((_intro.value - from) / (to - from)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  RunResult get _run => widget.controller.result!;
  BuiltPlan get _plan => widget.flight.plan;
  bool get _test => widget.flight.test;
  bool get _finished => _run.reason == EndReason.completed;
  int get _rating => _plan.rate(finished: _finished, stars: _run.stars);

  /// A test that flew the whole level to the finish: the creator has
  /// cleared it (a starter level is never the creator's own).
  bool get _clearedByYou =>
      _test &&
      _finished &&
      widget.flight.whole &&
      !widget.flight.level.template;

  /// A real flight's best to beat, when there was one.
  BuiltBest? get _beat {
    final before = widget.before;
    return !_test && _finished && before != null && before.cleared
        ? before
        : null;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _intro,
    builder: (context, _) => _stage(context),
  );

  Widget _stage(BuildContext context) {
    final bumped = _run.reason == EndReason.collision;
    final armed = _intro.value >= BuiltResultStage.armAt || _intro.isCompleted;
    final word = BuiltResultStage.wordFor(finished: _finished, bumped: bumped);
    // A finish's courier sits where the celebrating bird lands, as on the
    // campaign's result.
    final aside = _finished ? _seatShift : 0.0;
    return CampaignTextScale.wrap(
      Opacity(
        opacity: _calm ? _intro.value.clamp(0.0, 1.0) : 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: Opacity(
                opacity: _span(0, .25),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-.35, -.1),
                      radius: 1.25,
                      colors: [Color(0x1a203b45), Color(0x94203b45)],
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
                      left: -aside,
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
                      left: 20 - aside,
                      top: 104,
                      width: 380,
                      height: 346,
                      child: _courier(bumped: bumped),
                    ),
                    Positioned(
                      left: 0,
                      width: 410,
                      top: 4,
                      child: _title(word),
                    ),
                    Positioned(
                      left: 20 - aside,
                      width: 380,
                      top: 394,
                      child: _plateTag(),
                    ),
                    Positioned(
                      left: 418,
                      right: 20,
                      top: 6,
                      bottom: 14,
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _card(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(height: 88, child: _actions()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// How far a finish's courier moves over: to the seat the celebrating
  /// bird flies into ([LevelResultStage.courierSeat]).
  static const _seatShift = 40.0;

  Widget _courier({required bool bumped}) {
    final handoff = widget.handoff;
    final rise = handoff ? 1.0 : _span(.02, .4, Curves.easeOutBack);
    final land = BuiltResultStage.starsAt.last;
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * 380),
        child: CustomPaint(
          painter: StageBirdPainter(
            bird: widget.controller.bird,
            seconds: bumped && !_calm ? _intro.value * 4.8 : null,
            wet: false,
            happy: !bumped,
            puff: handoff ? _span(0, .15, Curves.easeOutBack) : 1,
            beaming: handoff,
            hop: _finished ? _span(land, land + .16, Curves.easeOut) : 0,
            cheer: _finished ? _span(land, 1) : 0,
          ),
        ),
      ),
    );
  }

  /// The word, each letter dropping in and landing with a squash at its
  /// own jaunty angle, as on the campaign's result.
  Widget _title(String word) {
    final letters = word.split('');
    return Semantics(
      key: const ValueKey('built-result-word'),
      header: true,
      label: word,
      child: ExcludeSemantics(
        child: MediaQuery.withNoTextScaling(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, letter) in letters.indexed) _letter(letter, i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _letter(String letter, int i) {
    final start = .02 + i * .025;
    final t = _span(start, start + .22);
    final fall = Curves.bounceOut.transform(t);
    final squash = t <= 0 || t >= 1 ? 0.0 : math.sin(t * math.pi) * .12;
    final tilt = [-.06, .05, -.03, .06, -.05, .04, -.02][i % 7];
    final style = heading(78, weight: FontWeight.w700);
    final fill = i.isEven ? SkyColors.yellow : SkyColors.cream;
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
                          ..strokeWidth = 11
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
                        ..strokeWidth = 9
                        ..strokeJoin = StrokeJoin.round
                        ..color = SkyColors.ink,
                    ),
                  ),
                  Text(letter, style: style.copyWith(color: fill)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The level's name on a cream plate under the cloud, tagged with its
  /// mode, or TEST FLIGHT for a creator's test.
  Widget _plateTag() {
    final plate = _span(.22, .42, Curves.easeOutBack);
    return Center(
      child: Opacity(
        opacity: plate.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: .7 + .3 * plate,
          child: Container(
            key: const ValueKey('built-result-plate'),
            padding: const EdgeInsets.fromLTRB(6, 5, 16, 5),
            decoration: BoxDecoration(
              color: SkyColors.cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SkyColors.ink, width: 2.6),
              boxShadow: [
                BoxShadow(
                  color: SkyColors.ink.withValues(alpha: .25),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Chip(
                  _test ? 'TEST FLIGHT' : builtModeName(_plan.mode),
                  icon: _test
                      ? Icons.construction_rounded
                      : Icons.dashboard_customize_rounded,
                  color: _test
                      ? SkyColors.lavender
                      : Color.lerp(
                          builtModeColor(_plan.mode),
                          SkyColors.cream,
                          _plan.mode == PlayMode.touch ? .35 : 0,
                        )!,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    widget.flight.level.plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(18, weight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // The scoreboard.

  static final _label = bodyText(
    13,
    color: SkyColors.muted,
    weight: FontWeight.w900,
  ).copyWith(letterSpacing: .8);

  static const _inset = Color(0xfff6ecda);
  static const _teal = Color(0xff2e7d6f);
  static const _mintFill = Color(0xffe0f0e2);
  static const _lilacFill = Color(0xffece7ff);

  /// The height of the stars over the card; half of it overlaps the card.
  static const _crown = 134.0;

  /// The distance between the stars' centres, and so between the goals
  /// under them, and the width of one goal.
  static const _pitch = 138.0, _goalWidth = 128.0;

  Widget _card() {
    final t = _span(.1, .34, Curves.easeOutCubic);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset((1 - t) * 70, 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: _crown / 2),
              child: _board(),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: _crown,
              child: Center(
                child: SizedBox(
                  width: 400,
                  height: _crown,
                  child: Semantics(
                    label: '$_rating of 3 level stars',
                    excludeSemantics: true,
                    child: CustomPaint(
                      painter: _CrownPainter(
                        earned: _rating,
                        spacing: _pitch,
                        pops: [
                          for (final at in BuiltResultStage.starsAt)
                            _span(at - .1, at + .06),
                        ],
                        slots: _span(.18, .32, Curves.easeOutCubic),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // A test wears its tab on the card's shoulder, clear of the
            // stars.
            if (_test)
              const Positioned(
                left: 16,
                top: _crown / 2 - 13,
                child: _Chip(
                  'TEST',
                  key: ValueKey('built-result-test-tab'),
                  icon: Icons.construction_rounded,
                  color: SkyColors.lavender,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _board() => DecoratedBox(
    key: const ValueKey('built-result-card'),
    decoration: BoxDecoration(
      color: SkyColors.cream,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: SkyColors.ink, width: 3),
      boxShadow: [
        // Three stars, or a creator's clear, light the whole scoreboard.
        if (_rating == 3 || _clearedByYou)
          BoxShadow(
            color: (_clearedByYou ? SkyColors.mint : SkyColors.yellow)
                .withValues(alpha: .6 * _span(.62, .82)),
            blurRadius: 34,
            spreadRadius: 5,
          ),
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .3),
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      // The goals begin just under the stars' lower points.
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _goals(),
          const SizedBox(height: 6),
          SizedBox(height: 92, child: _scores()),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Opacity(
                opacity: _span(.4, .6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _status(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// The finish (or the boss) and the two marks as tags under their stars,
  /// each ticked as its star lands, or saying how many stars are left.
  Widget _goals() {
    final marks = [null, _plan.marks.two, _plan.marks.three];
    final first = _plan.boss == null ? 'Finish' : 'Boss';
    return Opacity(
      opacity: _span(.24, .44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: _pitch - _goalWidth),
            Semantics(
              label: i == 0
                  ? '$first.${_rating > 0 ? ' Done.' : ''}'
                  : 'Collect ${marks[i]} stars.${_rating > i ? ' Done.' : ''}',
              excludeSemantics: true,
              child: _goal(
                i,
                title: marks[i] == null ? first : '${marks[i]}',
                star: marks[i] != null,
                earned: _rating > i,
                left: marks[i] == null ? null : marks[i]! - _run.stars,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _goal(
    int i, {
    required String title,
    required bool star,
    required bool earned,
    required int? left,
  }) {
    final at = BuiltResultStage.starsAt[i] + .06;
    final met = earned && (_calm || _intro.value >= at);
    final hint = met
        ? 'Done'
        : earned
        ? ''
        : left == null
        ? 'Not yet'
        : left > 0
        ? '$left to go'
        : 'Finish first';
    final tone = met ? _teal : SkyColors.muted;
    final pop = _calm ? 0.0 : math.sin(_span(at, at + .08) * math.pi);
    final scale = CampaignTextScale.of(context);
    return Transform.scale(
      scale: 1 + .08 * pop,
      child: Container(
        width: _goalWidth,
        height: 54 * scale,
        decoration: BoxDecoration(
          color: met ? _mintFill : _inset,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: met ? SkyColors.teal : SkyColors.sand.withValues(alpha: .6),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  star
                      ? MatchIcon(MatchSymbol.star, size: 20, muted: !met)
                      : Icon(
                          _plan.boss == null
                              ? Icons.flag_rounded
                              : Icons.shield_rounded,
                          size: 21,
                          color: tone,
                        ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: heading(
                      22,
                      color: met ? SkyColors.ink : SkyColors.muted,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 18 * scale,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (met) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: _teal,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      hint,
                      style: bodyText(14, color: tone, weight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The stars collected, with the best beside them (or a creator's clear
  /// stamped there), and a panel with the flight's other number: the score,
  /// the workout, or how far a short flight got.
  Widget _scores() {
    final r = _run;
    final beat = _beat;
    final before = widget.before;
    final newStars = beat != null && r.stars > beat.collected;
    final count = _span(.28, .68, Curves.easeOutCubic);
    final land = math.sin(_span(.68, .78) * math.pi);
    final stamp = _span(.72, .9, Curves.elasticOut);
    final swap = 1 - _span(.72, .78);
    final total = _plan.totalStars;
    // Beside the count: a creator's clear, a first clear, the best, or a
    // test's reminder that nothing is kept.
    final String? ribbon = _clearedByYou
        ? 'CLEARED BY YOU'
        : newStars
        ? 'NEW BEST!'
        : null;
    final Widget side = _test
        ? (_clearedByYou
              ? const SizedBox.shrink()
              : _tag(Icons.construction_rounded, 'Practice'))
        : !_finished
        ? (before != null && before.cleared
              ? _tag(Icons.emoji_events_rounded, 'Best ${before.collected}')
              : const SizedBox.shrink())
        : beat == null
        ? _tag(Icons.auto_awesome_rounded, 'First clear!')
        : _tag(Icons.emoji_events_rounded, 'Best ${beat.collected}');
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('STARS COLLECTED', style: _label),
                    Transform.scale(
                      scale: 1 + .08 * land,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const MatchIcon(MatchSymbol.star, size: 42),
                          const SizedBox(width: 8),
                          Text(
                            '${(r.stars * count).round()}',
                            style: heading(62, weight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/$total',
                            style: heading(
                              22,
                              color: SkyColors.muted,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: _clearedByYou ? 184 : 156,
                  height: 40,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: ribbon != null ? swap : 1,
                          child: side,
                        ),
                        if (ribbon != null && stamp > 0)
                          OverflowBox(
                            maxWidth: 260,
                            maxHeight: 40,
                            child: Transform.scale(
                              scale: stamp,
                              child: Transform.rotate(
                                angle: -.04,
                                child: StageRibbon(ribbon),
                              ),
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
        SizedBox(
          width: 176,
          child: Center(
            child: _panel(count, stamp: stamp, swap: swap),
          ),
        ),
      ],
    );
  }

  Widget _tag(IconData icon, String text) => Container(
    padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
    decoration: BoxDecoration(
      color: _test ? _lilacFill : _inset,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: _test
            ? SkyColors.purple.withValues(alpha: .45)
            : SkyColors.sand.withValues(alpha: .6),
        width: 2,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: _test ? SkyColors.purple : SkyColors.gold),
        const SizedBox(width: 4),
        Text(
          text,
          style: bodyText(14, color: SkyColors.muted, weight: FontWeight.w900),
        ),
      ],
    ),
  );

  /// The panel beside the stars: a camera level's workout, a Tap & Fly
  /// finish's score, or how far a Tap & Fly flight got.
  Widget _panel(double count, {required double stamp, required double swap}) {
    final r = _run;
    final level = widget.flight.level;
    final reached = BuiltReach.secondsTo(
      level.plan,
      BuiltResultStage.reached(widget.controller, widget.flight),
    );
    final length = BuiltReach.seconds(level.plan);
    final beat = _beat;
    final newScore = beat != null && r.score > beat.score;
    final String label, value;
    final String? note;
    IconData? icon;
    double? meter;
    switch (_plan.mode) {
      case PlayMode.pushUp || PlayMode.squat:
        final word = _plan.mode == PlayMode.squat ? 'squats' : 'push-ups';
        // A test's finger does no push-ups: it shows what the level asks.
        if (_test) {
          label = 'ASKS FOR';
          value = '${BuiltReach.reps(level.plan) ?? 0}';
          note = '$word on camera';
        } else {
          label = 'WORKOUT';
          value = '${(r.repetitions * count).round()}';
          note = word;
        }
      case PlayMode.jump:
        label = 'WORKOUT';
        value = '${(r.flaps * count).round()}';
        note = 'jumps';
      case PlayMode.touch when !_finished:
        label = 'GOT TO';
        value = '${reached.round()} s';
        note = 'of ${length.round()} s';
        icon = Icons.flag_rounded;
        meter = length <= 0 ? 0 : (reached / length).clamp(0.0, 1.0) * count;
      case PlayMode.touch:
        label = 'SCORE';
        value = '${(r.score * count).round()}';
        final best = widget.before?.score ?? 0;
        note = _test
            ? 'Not kept'
            : best > 0
            ? 'Best ${math.max(best, r.score)}'
            : 'No best yet';
    }
    return Container(
      key: const ValueKey('built-result-panel'),
      width: 168,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: _inset,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SkyColors.sand.withValues(alpha: .6),
          width: 2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: newScore ? swap : 1,
                      child: Text(label, style: _label),
                    ),
                    if (newScore && stamp > 0)
                      OverflowBox(
                        maxWidth: 240,
                        maxHeight: 40,
                        child: Transform.scale(
                          scale: stamp,
                          child: Transform.rotate(
                            angle: -.04,
                            child: const StageRibbon('NEW BEST!'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 26, color: SkyColors.teal),
                    const SizedBox(width: 5),
                  ] else if (_plan.mode != PlayMode.touch) ...[
                    ControlGlyph(builtControl(_plan.mode), size: 30),
                    const SizedBox(width: 6),
                  ],
                  Text(value, style: heading(38, weight: FontWeight.w700)),
                ],
              ),
              if (meter != null) ...[
                const SizedBox(height: 2),
                _meter(meter),
                const SizedBox(height: 2),
              ],
              Text(
                note,
                maxLines: 1,
                style: bodyText(
                  13.5,
                  color: SkyColors.muted,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meter(double value) => Container(
    width: 128,
    height: 11,
    decoration: BoxDecoration(
      color: SkyColors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: SkyColors.ink, width: 1.6),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: const ColoredBox(color: SkyColors.teal),
        ),
      ),
    ),
  );

  /// What the flight means: a creator's clear and what a test keeps, how
  /// far a short flight got, or the save's news.
  List<Widget> _status() {
    final c = widget.controller;
    final level = widget.flight.level;
    final reached = BuiltReach.secondsTo(
      level.plan,
      BuiltResultStage.reached(c, widget.flight),
    ).round();
    final length = BuiltReach.seconds(level.plan).round();
    final from = widget.flight.from;
    final camera = _plan.mode != PlayMode.touch;
    if (_test) {
      return [
        if (_clearedByYou)
          _strip(
            Icons.verified_rounded,
            SkyColors.mint,
            'Cleared by you · ready to share!',
            key: const ValueKey('built-result-cleared-by-you'),
          )
        else if (_finished && from != null)
          _strip(
            Icons.construction_rounded,
            SkyColors.lavender,
            'Flown from ${BuiltReach.secondsTo(level.plan, from).round()} s. '
            'Fly it all to clear it.',
            fill: _lilacFill,
          )
        else if (_finished)
          _strip(
            Icons.construction_rounded,
            SkyColors.lavender,
            'Test flight · nothing is saved',
            fill: _lilacFill,
          )
        else
          _strip(
            Icons.construction_rounded,
            SkyColors.lavender,
            camera
                ? 'Test flight · got to $reached s of $length s'
                : 'Test flight · nothing is saved',
            fill: _lilacFill,
          ),
      ];
    }
    return [
      if (!_finished)
        _strip(
          Icons.flag_rounded,
          SkyColors.sky,
          camera
              ? 'Got to $reached s of $length s. Reach the finish for stars.'
              : 'Reach the finish to earn stars.',
          fill: _inset,
        ),
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
      else if (_finished)
        _quiet(
          c.saved
              ? Icons.check_circle_outline_rounded
              : Icons.hourglass_top_rounded,
          c.saved ? 'Saved on this phone' : 'Saving your flight…',
        ),
    ];
  }

  Widget _strip(
    IconData icon,
    Color badge,
    String text, {
    Color fill = _mintFill,
    Key? key,
  }) => Padding(
    key: key,
    padding: const EdgeInsets.only(top: 4),
    child: Container(
      height: 30,
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: fill == _mintFill
              ? SkyColors.teal.withValues(alpha: .6)
              : fill == _lilacFill
              ? SkyColors.purple.withValues(alpha: .45)
              : SkyColors.sand.withValues(alpha: .7),
          width: 1.6,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: badge,
              shape: BoxShape.circle,
              border: Border.all(color: SkyColors.ink, width: 1.6),
            ),
            child: Icon(icon, size: 14, color: SkyColors.ink),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, style: bodyText(15, weight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _quiet(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: SkyColors.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: bodyText(
              13.5,
              color: SkyColors.muted,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------
  // The way on.

  /// The small keys stand a little taller than the stage keys elsewhere, so
  /// they stay 48 dp on the smallest phone.
  static const _keyHeight = 76.0;

  Widget _actions() {
    final c = widget.controller;
    final r = _run;
    final flight = widget.flight;
    final level = flight.level;
    Widget pop(double at, Widget child) {
      final k = _span(at, at + .2, Curves.easeOutBack);
      return Opacity(
        opacity: k.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - k) * 30),
          child: Transform.scale(scale: .8 + .2 * k, child: child),
        ),
      );
    }

    // The lead key gives a little hop and a glint once the stage has
    // settled; Reduced Motion leaves it be.
    final ready = _calm ? 0.0 : _span(.86, 1);
    // A test goes back to where it stopped in the editor.
    final at = flight.test ? BuiltResultStage.reached(c, flight) : null;
    // A finished test leads back to the editor (to share it, or build on);
    // anything else leads to another go.
    final editLeads = flight.test && _finished;
    final builder = StageKey(
      key: const ValueKey('built-result-builder'),
      label: 'Builder',
      icon: Icons.dashboard_customize_rounded,
      height: _keyHeight,
      onPressed: () => widget.onLeave('/builder'),
    );
    final edit = StageKey(
      key: const ValueKey('built-result-edit'),
      label: editLeads ? 'Edit level' : 'Edit',
      icon: Icons.edit_rounded,
      hero: editLeads,
      autofocus: editLeads,
      shine: editLeads ? ready : 0,
      height: editLeads ? null : _keyHeight,
      onPressed: () => widget.onLeave(
        '/builder/edit/${level.id}${at == null ? '' : '?at=$at'}',
      ),
    );
    final retry = StageKey(
      key: const ValueKey('built-result-retry'),
      label: _finished ? 'Fly again' : 'Retry',
      icon: Icons.replay_rounded,
      hero: !editLeads,
      autofocus: !editLeads,
      shine: editLeads ? 0 : ready,
      height: editLeads ? _keyHeight : null,
      onPressed: () => c.retry(),
    );
    final session = StageKey(
      key: const ValueKey('save-or-watch-session'),
      height: _keyHeight,
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
    );
    // A starter level cannot be edited. Any real flight can be kept as a
    // session to replay; a test flight is kept nowhere.
    final template = !flight.test && level.template;
    final keep = c.canSaveSession || c.sessionSaved;
    final (Widget lead, List<(double, Widget)> small) = editLeads
        ? (edit, [(96.0, builder), (112.0, retry)])
        : template
        ? (retry, [(96.0, builder), if (keep) (136.0, session)])
        : (retry, [(96.0, builder), (96.0, edit), if (keep) (128.0, session)]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, (width, key)) in small.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          SizedBox(width: width, child: pop(.34 + i * .03, key)),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: pop(
            .44,
            Transform.scale(
              scale: 1 + .06 * math.sin(ready * math.pi),
              child: lead,
            ),
          ),
        ),
      ],
    );
  }
}

/// A small inked chip: the plate's mode or TEST FLIGHT, the card's tab.
class _Chip extends StatelessWidget {
  const _Chip(
    this.text, {
    super.key,
    required this.icon,
    required this.color,
    this.size = 15,
  });
  final String text;
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 2, 10, 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .25),
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size + 2, color: SkyColors.ink),
        const SizedBox(width: 4),
        Text(
          text,
          style: heading(size, weight: FontWeight.w700).copyWith(height: 1.1),
        ),
      ],
    ),
  );
}

/// The three big level stars. Empty sockets fade in first, dark and carved
/// so they read as places waiting to be filled; then each earned star pops
/// in over its socket, spinning a little as it lands, with a flash ring and
/// a ring of little sparks, and stays lit in a warm halo. (The campaign's
/// result draws its stars the same way.)
class _CrownPainter extends CustomPainter {
  const _CrownPainter({
    required this.earned,
    required this.pops,
    required this.slots,
    required this.spacing,
  });
  final int earned;
  final List<double> pops;
  final double slots, spacing;

  static const _deep = Color(0xff3f5d68), _well = Color(0xff648390);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = h * .36;
    for (var i = 0; i < 3; i++) {
      final big = i == 1;
      final radius = big ? r * 1.2 : r;
      final at = Offset(w / 2 + (i - 1) * spacing, h * (big ? .42 : .53));
      final tilt = (i - 1) * .2;
      if (slots > 0) _socket(canvas, at, radius, tilt);
      final run = i < earned ? pops[i] : 0.0;
      if (run <= 0) continue;
      final k = Curves.easeOutBack.transform(run);
      canvas.drawCircle(
        at,
        radius * 1.75,
        Paint()
          ..shader = ui.Gradient.radial(at, radius * 1.75, [
            SkyColors.yellow.withValues(alpha: .5 * run),
            SkyColors.yellow.withValues(alpha: 0),
          ]),
      );
      if (run < 1) {
        final spark = Curves.easeOut.transform(run);
        canvas.drawCircle(
          at,
          radius * (.9 + .9 * spark),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * (1 - spark)
            ..color = SkyColors.cream.withValues(alpha: .9 * (1 - spark)),
        );
        for (var s = 0; s < 8; s++) {
          final a = s * math.pi / 4 + i;
          final d = radius * (1.1 + .55 * spark);
          StarArt.mini(
            canvas,
            at + Offset(math.cos(a) * d, math.sin(a) * d),
            radius * (s.isEven ? .17 : .11) * (1 - spark),
            outline: 1.2,
          );
        }
      }
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(k);
      StarArt.mini(
        canvas,
        Offset.zero,
        radius,
        rotation: tilt + (1 - run) * -.5,
        outline: 4.5,
      );
      canvas.restore();
    }
  }

  void _socket(Canvas canvas, Offset at, double radius, double tilt) {
    final path = StarArt.path(at, radius * .94, rotation: -math.pi / 2 + tilt);
    canvas.drawPath(
      path.shift(const Offset(0, 5)),
      Paint()..color = SkyColors.ink.withValues(alpha: .3 * slots),
    );
    final fading = slots < 1;
    if (fading) {
      canvas.saveLayer(
        Rect.fromCircle(center: at, radius: radius * 1.2),
        Paint()..color = Color.fromRGBO(0, 0, 0, slots),
      );
    }
    canvas.drawPath(path, Paint()..color = _deep);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path.shift(const Offset(0, 6)), Paint()..color = _well);
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeJoin = StrokeJoin.round,
    );
    if (fading) canvas.restore();
  }

  @override
  bool shouldRepaint(_CrownPainter old) =>
      old.earned != earned ||
      old.slots != slots ||
      old.pops != pops ||
      old.spacing != spacing;
}
