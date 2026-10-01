import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/passport_progress.dart';
import '../data/progress_repository.dart';
import '../domain/campaign.dart';
import '../domain/campaign_progress.dart';
import '../domain/game_rules.dart';
import '../domain/sky_passport.dart';
import '../game/campaign_voices.dart';
import '../game/play_controller.dart';
import '../game/star_art.dart';
import 'components.dart';
import 'campaign_map_art.dart' show MapGuardianPainter, MapNodeLook;
import 'campaign_text_scale.dart';
import 'delivery_art.dart';
import 'game_over_stage.dart' show StageBirdPainter;
import 'level_intro.dart' show LevelIntroCard;
import 'match_hud.dart' show MatchIcon, MatchSymbol;
import 'stage_key.dart';
import 'theme.dart';

/// The campaign's level result, staged over the frozen finish like the
/// game-over stage it sits beside. The left tells the story: a title drops
/// in above the courier, who rises in on its cloud, beaming, with the level's
/// plate hung below; once the title has landed, a thank-you note from
/// whoever the delivery was for flutters down beside it. The right is the
/// scoreboard, crowned with the level's three stars, which pop in one by
/// one, gold for each one earned and an empty socket for each one not. Under
/// each star sits its goal, ticked or with how far is left to go; the stars
/// collected count up beside the score and the bests, then come the news of
/// the save, and the keys lead on: Next (the next level's card on the map),
/// Retry, Map and Save session / Watch replay.
///
/// A level that ended short of the finish without a knockout (an
/// interrupted flight) shows the same stage with no stars, no note and Retry
/// leading. A knockout never comes here; it plays the game-over stage.
///
/// The keys stay inert until the entrance has settled, so taps meant for
/// the bird cannot leave by accident. Reduced Motion fades the finished
/// stage in, with every star and the note already in place.
class LevelResultStage extends StatefulWidget {
  const LevelResultStage({
    super.key,
    required this.controller,
    required this.level,
    required this.progress,
    required this.before,
    required this.initialStamps,
    required this.initialDailyKey,
    required this.initialDailyComplete,
    required this.onLeave,
  });
  final PlayController controller;
  final CampaignLevel level;
  final ProgressSnapshot progress;

  /// The level's bests before this flight, for "New best".
  final LevelRecord before;
  final Set<SkyStamp> initialStamps;
  final String? initialDailyKey;
  final bool initialDailyComplete;
  final Future<void> Function([String destination]) onLeave;

  static const entrance = Duration(milliseconds: 1900);
  static const calmEntrance = Duration(milliseconds: 500);

  /// Fraction of the entrance after which the keys accept taps.
  static const armAt = .55;

  /// When each of the three stars lands, as fractions of the entrance.
  static const starsAt = [.34, .46, .58];

  /// When the thank-you note sets off and when it has landed, as fractions
  /// of the entrance: it comes down as the last star lands.
  static const noteFrom = .5, noteTo = .76;

  /// The word that drops in over the courier: "Victory!" for a chapter's
  /// boss, "Guardian down!" for a mini-boss that guarded a level before it,
  /// "Delivered!" for any other finish, "Try again!" when the flight ended
  /// short of the finish.
  static String wordFor(CampaignLevel level, {required bool complete}) =>
      !complete
      ? 'Try again!'
      : level.isChapterBoss
      ? 'Victory!'
      : level.isGuardian
      ? 'Guardian down!'
      : 'Delivered!';

  /// The news strip for a finish whose next level is in this chapter but not in
  /// this build: "Paris is coming soon!" after 3-4, where Next is hidden.
  /// Null when there is nothing to say: a next level that can be flown (its
  /// own strip says it is open), another chapter, or no next level.
  static String? comingSoonNews(CampaignLevel level) {
    final next = Campaign.after(level);
    if (!Campaign.playable(level) ||
        next == null ||
        next.chapter != level.chapter) {
      return null;
    }
    return Campaign.playable(next)
        ? null
        : '${next.region.title} is coming soon!';
  }

  @override
  State<LevelResultStage> createState() => _LevelResultStageState();
}

class _LevelResultStageState extends State<LevelResultStage>
    with SingleTickerProviderStateMixin {
  bool get _calm => widget.controller.reducedMotion;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _calm ? LevelResultStage.calmEntrance : LevelResultStage.entrance,
  )..addListener(_chime);
  int _landed = 0;

  /// Whether the thank-you has been read out.
  bool _thanked = false;

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
    _thank();
    if (_calm) return;
    final stars = widget.controller.levelStars;
    while (_landed < stars &&
        _intro.value >= LevelResultStage.starsAt[_landed] + .06) {
      _landed++;
      widget.controller.audio.effect(_landed == 3 ? 'wing' : 'star');
    }
  }

  /// A finished level's thank-you is read out in its sender's voice as the
  /// note lands.
  void _thank() {
    if (_thanked ||
        !widget.controller.levelComplete ||
        _intro.value < LevelResultStage.noteTo) {
      return;
    }
    _thanked = true;
    final voice = CampaignVoices.thanks(level);
    if (voice != null) widget.controller.audio.speak(voice);
  }

  double _span(double from, double to, [Curve curve = Curves.linear]) {
    if (_calm) return 1;
    final t = ((_intro.value - from) / (to - from)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  CampaignLevel get level => widget.level;

  /// The next level after a finish, when this build has it: finishing
  /// this one has just opened it.
  CampaignLevel? get _next {
    final next = widget.controller.nextLevel;
    if (!widget.controller.levelComplete || next == null) return null;
    return Campaign.playable(next) ? next : null;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _intro,
    builder: (context, _) => _stage(context),
  );

  Widget _stage(BuildContext context) {
    final c = widget.controller;
    final r = c.result!;
    final stars = c.levelStars;
    final before = widget.before;
    // A best counts once there was one to beat, and only a finished flight
    // sets one.
    final beat = c.levelComplete && before.cleared;
    final newStars = beat && r.stars > before.bestCollected;
    final newScore = beat && r.score > before.bestScore;
    final armed = _intro.value >= LevelResultStage.armAt || _intro.isCompleted;
    final fade = _calm ? _intro.value.clamp(0.0, 1.0) : 1.0;
    final word = LevelResultStage.wordFor(level, complete: c.levelComplete);
    // A finished flight's courier sits over on its cloud, to leave room for
    // the thank-you note beside it.
    final aside = c.levelComplete ? _noteRoom : 0.0;
    // The stage is drawn on a fixed canvas that already scales with the
    // screen. Its text follows the system text size up to 1.3x
    // ([CampaignTextScale]); the display lettering (the word over the courier)
    // and the thank-you note on its paper stay at their size.
    return CampaignTextScale.wrap(
      Opacity(
        opacity: fade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A warm vignette settles the frozen finish behind the stage.
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
            // A beaten guardian's shield hangs on the finish gate in place of
            // its FINISH sign: the frozen frame behind the stage is the gate
            // of a level that ended at a boss.
            if (c.levelComplete && level.isGuardian)
              Positioned.fill(child: IgnorePointer(child: _trophy())),
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
                      child: _courier(),
                    ),
                    Positioned(
                      left: 0,
                      width: 410,
                      top: 4,
                      child: _title(word),
                    ),
                    // The level's plate hangs under the cloud, so the frozen
                    // finish's sign stays clear behind the title.
                    Positioned(
                      left: 20 - aside,
                      width: 380,
                      top: 394,
                      child: _plate(),
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
                              child: _card(
                                r,
                                stars,
                                newStars: newStars,
                                newScore: newScore,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(height: 88, child: _actions(r)),
                        ],
                      ),
                    ),
                    // The note lands between the courier and the scoreboard,
                    // over the scoreboard's glow.
                    if (c.levelComplete)
                      Positioned(
                        left: 406 - DeliveryNote.width,
                        width: DeliveryNote.width,
                        top: _noteFoot - DeliveryNote.maxHeight,
                        height: DeliveryNote.maxHeight,
                        child: _thanks(),
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

  /// The courier on its cloud, rising in from below and beaming, with a
  /// hop as its stars land.
  Widget _courier() {
    final rise = _span(.02, .4, Curves.easeOutBack);
    final land = LevelResultStage.starsAt.last;
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * 380),
        child: CustomPaint(
          painter: StageBirdPainter(
            bird: widget.controller.bird,
            seconds: null,
            wet: false,
            happy: true,
            hop: widget.controller.levelComplete
                ? _span(land, land + .16, Curves.easeOut)
                : 0,
            cheer: widget.controller.levelComplete ? _span(land, 1) : 0,
          ),
        ),
      ),
    );
  }

  /// How far the courier moves over for the thank-you note, and where the
  /// note's foot rests: just above the cloud's shoulder, at the courier's
  /// eye level.
  static const _noteRoom = 40.0, _noteFoot = 292.0;

  /// The thank-you for the delivery: a note from whoever it was for, which
  /// flutters down beside the courier as the last star lands, swaying like a
  /// dropped letter, and is sealed once it has settled.
  Widget _thanks() {
    final t = _span(LevelResultStage.noteFrom, LevelResultStage.noteTo);
    final drop = Curves.easeOutCubic.transform(t);
    final sway = math.sin(t * math.pi * 2.5) * (1 - t);
    final to = LevelResultStage.noteTo;
    return IgnorePointer(
      child: Opacity(
        opacity: (t * 5).clamp(0.0, 1.0),
        child: Transform.translate(
          // It keeps to its own column on the way down, off the scoreboard.
          offset: Offset(sway * 10 - (1 - drop) * 10, (1 - drop) * -96),
          child: Transform.rotate(
            angle: -.04 + sway * .26,
            child: Transform.scale(
              scale: .78 + .22 * drop,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MediaQuery.withNoTextScaling(
                  child: DeliveryNote(
                    delivery: level.delivery,
                    // A guardian's thank-you is an ordinary friend's, not a boss
                    // grumbling in its own ink; only a chapter's boss seals its
                    // note with its headwear.
                    boss: level.isChapterBoss ? level.boss : null,
                    seal: _span(to - .02, to + .12, Curves.easeOutBack),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String word) {
    final letters = word.split('');
    return Semantics(
      header: true,
      label: word,
      child: ExcludeSemantics(
        child: MediaQuery.withNoTextScaling(
          child: Padding(
            // "Guardian down!" is the one word wide enough to reach the stage's
            // edge once it is scaled to fit: it keeps a margin.
            padding: EdgeInsets.symmetric(
              horizontal: level.isGuardian ? 16 : 0,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, letter) in letters.indexed)
                    _letter(letter, i, letters.length),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The beaten guardian's shield, hung on the finish gate where the FINISH
  /// sign is: it pops in with the title and sways to rest. The gate stands at
  /// the line's x, in screen heights, wherever the stage is scaled to.
  Widget _trophy() {
    final boss = level.boss;
    if (boss == null) return const SizedBox.shrink();
    final x =
        widget.controller.simulation?.finishLine?.x ?? FlightSimulation.birdX;
    final t = _span(.1, .42);
    return LayoutBuilder(
      builder: (context, box) => CustomPaint(
        size: box.biggest,
        painter: _TrophyPainter(
          boss: boss,
          x: x,
          pop: _calm ? 1 : Curves.easeOutBack.transform(t),
          sway: _calm ? 0 : math.sin(t * math.pi * 3) * (1 - t) * .16,
          glow: _span(.1, .5),
        ),
      ),
    );
  }

  /// The level's number and name on a cream plate, so it reads over any
  /// world.
  Widget _plate() {
    final plate = _span(.22, .42, Curves.easeOutBack);
    return Center(
      child: Opacity(
        opacity: plate.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: .7 + .3 * plate,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 18, 5),
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
                Container(
                  padding: const EdgeInsets.fromLTRB(9, 1, 9, 2),
                  decoration: BoxDecoration(
                    color: level.isChapterBoss
                        ? SkyColors.coral
                        : level.isGuardian
                        ? SkyColors.lavender
                        : SkyColors.yellow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SkyColors.ink, width: 2),
                  ),
                  child: Text(
                    level.id,
                    style: heading(18, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 9),
                Text(level.name, style: bodyText(18, weight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Each letter drops from above and lands with a squash at its own jaunty
  /// angle, like the game-over title.
  Widget _letter(String letter, int i, int count) {
    final start = .02 + i * .025;
    final t = _span(start, start + .22);
    final fall = Curves.bounceOut.transform(t);
    final squash = t <= 0 || t >= 1 ? 0.0 : math.sin(t * math.pi) * .12;
    final tilt = [-.06, .05, -.03, .06, -.05, .04, -.02][i % 7];
    final style = heading(78, weight: FontWeight.w700);
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
                  Text(
                    letter,
                    style: style.copyWith(
                      color: i.isEven ? SkyColors.yellow : SkyColors.cream,
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

  /// The level's three stars, the middle one raised, each popping in with
  /// a burst when earned; stars not earned wait as empty sockets.
  Widget _stars(int earned) => Semantics(
    label: '$earned of 3 stars',
    excludeSemantics: true,
    child: CustomPaint(
      painter: _BigStarsPainter(
        earned: earned,
        spacing: _pitch,
        pops: [
          for (final at in LevelResultStage.starsAt) _span(at - .1, at + .06),
        ],
        slots: _span(.18, .32, Curves.easeOutCubic),
      ),
    ),
  );

  static final _label = bodyText(
    13,
    color: SkyColors.muted,
    weight: FontWeight.w900,
  ).copyWith(letterSpacing: .8);

  static const _inset = Color(0xfff6ecda);
  static const _teal = Color(0xff2e7d6f);
  static const _mintFill = Color(0xffe0f0e2);

  /// The height of the stars over the card; half of it overlaps the card.
  static const _crown = 134.0;

  /// The distance between the stars' centres, and so between the goals
  /// under them, and the width of one goal.
  static const _pitch = 138.0, _goalWidth = 128.0;

  /// The scoreboard, crowned with the level's three stars: the goals under
  /// them, the stars collected and score, then the news of the save.
  Widget _card(
    RunResult r,
    int stars, {
    required bool newStars,
    required bool newScore,
  }) {
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
              child: _board(r, stars, newStars: newStars, newScore: newScore),
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
                  child: _stars(stars),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _board(
    RunResult r,
    int stars, {
    required bool newStars,
    required bool newScore,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: SkyColors.cream,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: SkyColors.ink, width: 3),
      boxShadow: [
        // Three stars light the whole scoreboard.
        if (stars == 3)
          BoxShadow(
            color: SkyColors.yellow.withValues(alpha: .6 * _span(.62, .82)),
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
          _goals(r, stars),
          const SizedBox(height: 6),
          SizedBox(
            height: 92,
            child: _scores(r, newStars: newStars, newScore: newScore),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Opacity(
                opacity: _span(.4, .6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _status(r),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// The stars collected beside the score, each with its best. A new best
  /// stamps its ribbon over the old one once the count lands.
  Widget _scores(
    RunResult r, {
    required bool newStars,
    required bool newScore,
  }) {
    final done = widget.controller.levelComplete;
    final before = widget.before;
    // Only a finished flight can set a best.
    final bestStars = done
        ? math.max(before.bestCollected, r.stars)
        : before.bestCollected;
    final bestScore = done
        ? math.max(before.bestScore, r.score)
        : before.bestScore;
    final count = _span(.28, .68, Curves.easeOutCubic);
    final land = math.sin(_span(.68, .78) * math.pi);
    final stamp = _span(.72, .9, Curves.elasticOut);
    final swap = 1 - _span(.72, .78);
    Widget bestNote(int best) => Text(
      best > 0 ? 'Best $best' : 'No best yet',
      style: bodyText(13.5, color: SkyColors.muted, weight: FontWeight.w800),
    );
    // The best beside the count: a tag, or the ribbon of a new one. A first
    // clear has no old best to beat, so it says so.
    Widget tag(IconData? icon, String text) => Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
      decoration: BoxDecoration(
        color: _inset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SkyColors.sand.withValues(alpha: .6),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: SkyColors.gold),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: bodyText(
              14,
              color: SkyColors.muted,
              weight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
    final first = done && !before.cleared;
    // An unfinished first flight has no best to name: the score says so.
    final bestTag = !done && bestStars == 0
        ? const SizedBox.shrink()
        : first
        ? tag(Icons.auto_awesome_rounded, 'First clear!')
        : tag(
            bestStars > 0 ? Icons.emoji_events_rounded : null,
            newStars
                ? 'Best ${before.bestCollected}'
                : bestStars > 0
                ? 'Best $bestStars'
                : 'No best yet',
          );
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The label sits over the count it names.
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('STARS COLLECTED', style: _label),
                    Transform.scale(
                      scale: 1 + .08 * land,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const MatchIcon(MatchSymbol.star, size: 46),
                          const SizedBox(width: 8),
                          Text(
                            '${(r.stars * count).round()}',
                            style: heading(66, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 150,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Opacity(opacity: newStars ? swap : 1, child: bestTag),
                        if (newStars && stamp > 0)
                          Transform.scale(
                            scale: stamp,
                            child: Transform.rotate(
                              angle: -.04,
                              child: const StageRibbon('NEW BEST!'),
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
          width: 184,
          child: Center(
            child: Container(
              width: 172,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                color: _inset,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SkyColors.sand.withValues(alpha: .6),
                  width: 2,
                ),
              ),
              // The panel is 80 high inside; a larger text size shrinks the
              // three lines together to it.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 152),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A new best stamps its ribbon over the label, its tails
                      // hanging past the panel.
                      SizedBox(
                        height: 20,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: newScore ? swap : 1,
                              child: Text('SCORE', style: _label),
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${(r.score * count).round()}',
                          style: heading(38, weight: FontWeight.w700),
                        ),
                      ),
                      bestNote(bestScore),
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

  /// The level's three goals as tags under their stars, each ticked as its
  /// star lands, or saying how many stars are left to go.
  Widget _goals(RunResult r, int stars) {
    final goals = LevelIntroCard.goals(level);
    final marks = [null, level.marks.two, level.marks.three];
    return Opacity(
      opacity: _span(.24, .44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: _pitch - _goalWidth),
            Semantics(
              label: '${goals[i]}.${stars > i ? ' Done.' : ''}',
              excludeSemantics: true,
              child: _goal(
                i,
                mark: marks[i],
                earned: stars > i,
                left: marks[i] == null ? null : marks[i]! - r.stars,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// One goal: a flag for the finish, a star for a collection mark. It waits
  /// until its star has landed to be ticked; a goal not met says how many
  /// stars are left, or that the finish comes first.
  Widget _goal(
    int i, {
    required int? mark,
    required bool earned,
    required int? left,
  }) {
    final at = LevelResultStage.starsAt[i] + .06;
    final met = earned && (_calm || _intro.value >= at);
    final title = mark == null
        ? (level.isChapterBoss
              ? 'Boss'
              : level.isGuardian
              ? 'Guardian'
              : 'Finish')
        : '$mark';
    final hint = met
        ? 'Done'
        : earned
        ? ''
        : mark == null
        ? 'Not yet'
        : left! > 0
        ? '$left to go'
        : 'Finish first';
    final tone = met ? _teal : SkyColors.muted;
    // The tick lands with a little pop.
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
            // Each line shrinks to the box rather than past it when the text
            // size is up.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  mark == null
                      ? Icon(Icons.flag_rounded, size: 21, color: tone)
                      : MatchIcon(MatchSymbol.star, size: 20, muted: !met),
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

  /// What the save did, as news strips (what it unlocked or earned), or a
  /// quiet line when it did nothing new; a failed save can be tapped to try
  /// again.
  List<Widget> _status(RunResult r) {
    final c = widget.controller;
    final p = widget.progress;
    Widget strip(
      IconData icon,
      Color badge,
      String text, {
      Color? fill,
      Color? edge,
    }) => Container(
      height: 30,
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
      decoration: BoxDecoration(
        color: fill ?? _mintFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              edge ??
              (fill == null
                  ? SkyColors.teal.withValues(alpha: .6)
                  : SkyColors.sand.withValues(alpha: .7)),
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
    );
    // Two strips share a line, so the news never crowds the scoreboard.
    List<Widget> lines(List<Widget> strips) => [
      for (var i = 0; i < strips.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(child: strips[i]),
              if (i + 1 < strips.length) ...[
                const SizedBox(width: 6),
                Expanded(child: strips[i + 1]),
              ],
            ],
          ),
        ),
    ];
    Widget quiet(IconData icon, String text, Color color) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: bodyText(13.5, color: color, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    final newStamps = p.passport
        .where((s) => s.earned && !widget.initialStamps.contains(s.stamp))
        .toList();
    final newDailyCard =
        c.saved &&
        p.today?.complete == true &&
        (widget.initialDailyKey != p.today?.dayKey ||
            !widget.initialDailyComplete);
    final next = _next;
    final soon = LevelResultStage.comingSoonNews(level);
    final news = <Widget>[
      if (c.saved && c.levelComplete)
        if (level == Campaign.chapterOf(level).bossLevel &&
            !widget.before.cleared)
          strip(
            Icons.local_post_office_outlined,
            SkyColors.lavender,
            'A postcard is waiting on the map!',
          )
        else if (next != null && !widget.before.cleared)
          strip(
            Icons.lock_open_rounded,
            SkyColors.mint,
            '${next.id} ${next.name} is open!',
          )
        else if (next == null && soon != null)
          // Next is hidden: the rest of the chapter is not in this build.
          strip(
            Icons.flight_takeoff_rounded,
            SkyColors.lavender,
            soon,
            fill: const Color(0xffece7ff),
            edge: SkyColors.purple.withValues(alpha: .55),
          ),
      if (newDailyCard)
        strip(
          Icons.local_post_office_outlined,
          SkyColors.mint,
          'Today’s postcard stamped!',
        )
      else if (newStamps.isNotEmpty)
        strip(
          Icons.workspace_premium_rounded,
          SkyColors.yellow,
          'Stamp earned: ${newStamps.first.stamp.title}',
        ),
    ];
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
      else if (!c.saved)
        quiet(
          Icons.hourglass_top_rounded,
          'Saving your flight…',
          SkyColors.muted,
        )
      else ...[
        ...lines(
          [
            // A session that would not save is the news that matters most.
            if (c.sessionError.isNotEmpty)
              strip(
                Icons.error_outline_rounded,
                SkyColors.coral,
                c.sessionError,
                fill: const Color(0xffffe6df),
                edge: SkyColors.coralDeep.withValues(alpha: .6),
              ),
            if (!c.levelComplete)
              strip(
                Icons.flag_rounded,
                SkyColors.sky,
                'Reach the finish to earn stars.',
                fill: _inset,
              ),
            ...news,
          ].take(2).toList(),
        ),
        // A saved session already turns its key into Watch replay, so it
        // only gets a line here when the news leaves the room.
        if (c.levelComplete && news.isEmpty && c.sessionError.isEmpty)
          quiet(
            c.sessionSaved
                ? Icons.video_library_outlined
                : Icons.check_circle_outline_rounded,
            c.sessionSaved
                ? 'Session saved · Watch in Records'
                : 'Saved on this phone',
            c.sessionSaved ? _teal : SkyColors.muted,
          ),
      ],
    ];
  }

  /// The small keys stand a little taller than the stage keys elsewhere, so
  /// they stay 48 dp on the smallest phone, where the stage is drawn at
  /// .64 of its size.
  static const _keyHeight = 76.0;

  Widget _actions(RunResult r) {
    final c = widget.controller;
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

    final next = _next;
    // The lead key gives a little hop and a glint once the stage has
    // settled; Reduced Motion leaves it be.
    final ready = _calm ? 0.0 : _span(.86, 1);
    final map = StageKey(
      key: const ValueKey('level-result-map'),
      label: 'Map',
      icon: Icons.map_rounded,
      hero: next == null && c.levelComplete,
      shine: next == null && c.levelComplete ? ready : 0,
      height: next == null && c.levelComplete ? null : _keyHeight,
      onPressed: () => widget.onLeave('/campaign'),
    );
    final retry = StageKey(
      key: const ValueKey('level-result-retry'),
      label: 'Retry',
      icon: Icons.replay_rounded,
      hero: !c.levelComplete,
      shine: c.levelComplete ? 0 : ready,
      height: c.levelComplete ? _keyHeight : null,
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
    // The lead key is Next while there is a next level, then Map once the
    // build's last level is done, or Retry when the finish was missed.
    final (lead, small) = next != null
        ? (
            StageKey(
              key: const ValueKey('level-result-next'),
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              hero: true,
              shine: ready,
              // Leaving waits for the save, so the next level is open.
              busy: !c.saved && c.saveError.isEmpty,
              onPressed: c.saved
                  ? () => widget.onLeave('/campaign?level=${next.id}')
                  : null,
            ),
            [map, retry],
          )
        : c.levelComplete
        ? (map, [retry])
        : (retry, [map]);
    final started = c.simulation?.started == true;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, key) in small.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          SizedBox(width: 96, child: pop(.34 + i * .03, key)),
        ],
        if (started) ...[
          const SizedBox(width: 10),
          SizedBox(width: 136, child: pop(.4, session)),
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

/// The three big level stars. Empty sockets fade in first, dark and carved
/// so they read as places waiting to be filled; then each earned star pops
/// in over its socket (a [pops] value runs 0–1; the size overshoots), spinning
/// a little as it lands, with a flash ring and a ring of little sparks, and
/// stays lit in a warm halo.
class _BigStarsPainter extends CustomPainter {
  const _BigStarsPainter({
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
      // How far the pop has run, and its size, which overshoots.
      final run = i < earned ? pops[i] : 0.0;
      if (run <= 0) continue;
      final k = Curves.easeOutBack.transform(run);
      final settled = run;
      // The halo stays: a lit star against the dark sockets.
      canvas.drawCircle(
        at,
        radius * 1.75,
        Paint()
          ..shader = ui.Gradient.radial(at, radius * 1.75, [
            SkyColors.yellow.withValues(alpha: .5 * settled),
            SkyColors.yellow.withValues(alpha: 0),
          ]),
      );
      // A ring flashes out and little stars fly as the star lands.
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
        rotation: tilt + (1 - settled) * -.5,
        outline: 4.5,
      );
      canvas.restore();
    }
  }

  /// An empty socket: a dark star with a carved inner shadow along its top,
  /// so it reads as waiting, not switched off.
  void _socket(Canvas canvas, Offset at, double radius, double tilt) {
    final path = StarArt.path(at, radius * .94, rotation: -math.pi / 2 + tilt);
    canvas.drawPath(
      path.shift(const Offset(0, 5)),
      Paint()..color = SkyColors.ink.withValues(alpha: .3 * slots),
    );
    // It fades in as one piece, not layer by layer.
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
  bool shouldRepaint(_BigStarsPainter old) =>
      old.earned != earned ||
      old.slots != slots ||
      old.pops != pops ||
      old.spacing != spacing;
}

/// A beaten guardian's shield on the finish gate: the shield of its map node
/// (beaten: mint rim and a tick) with its headwear on it, hung from the gate's
/// checkered beam over the FINISH sign, in a soft pool of light. The gate is
/// drawn in screen heights, so this is too: the shield is as wide as the sign
/// (.27 of the height), hanging from the beam's foot.
class _TrophyPainter extends CustomPainter {
  const _TrophyPainter({
    required this.boss,
    required this.x,
    required this.pop,
    required this.sway,
    required this.glow,
  });
  final BossKind boss;

  /// The gate's centre, in screen heights.
  final double x;

  /// 0 to 1 and a little past: how far the shield has popped in.
  final double pop;

  /// How far the shield swings on its hook, in radians.
  final double sway;

  /// The pool of light's strength, 0 to 1.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final r = .135 * h / .94;
    final w = MapGuardianPainter.halfWidth(r) * 2 + 4;
    final tall =
        MapGuardianPainter.halfHeight(r) * 2 + MapGuardianPainter.depth + 4;
    final hook = Offset(x * h, .226 * h);
    // The light the shield gives off, under it.
    final centre = hook.translate(0, tall * .5);
    canvas.drawCircle(
      centre,
      h * .3,
      Paint()
        ..shader = ui.Gradient.radial(
          centre,
          h * .3,
          [
            SkyColors.cream.withValues(alpha: .55 * glow),
            SkyColors.cream.withValues(alpha: .18 * glow),
            SkyColors.cream.withValues(alpha: 0),
          ],
          const [0, .5, 1],
        ),
    );
    canvas.save();
    canvas.translate(hook.dx, hook.dy);
    canvas.rotate(sway);
    canvas.scale(math.max(pop, 0));
    canvas.translate(-w / 2, 0);
    MapGuardianPainter(
      look: MapNodeLook.cleared,
      radius: r,
      boss: boss,
    ).paint(canvas, Size(w, tall));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrophyPainter old) =>
      old.boss != boss ||
      old.x != x ||
      old.pop != pop ||
      old.sway != sway ||
      old.glow != glow;
}
