import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../domain/tether.dart';
import '../game/bird_puppet.dart';
import '../game/play_controller.dart';
import '../game/tether_art.dart';
import 'components.dart';
import 'match_hud.dart';
import 'pause_card.dart';
import 'theme.dart';

/// Fly Together's end screens, staged like the solo game-over stage over
/// the frozen flight: the pair's moment on the left under a big lettered
/// title, the scoreboard on the right, and the keys beneath it.
///
/// [CoopTeamStage] shows a roped or rope-free team: the two birds side by
/// side on one cloud, the team score beside the team best and each
/// player's share of the flaps. [CoopDuelStage] crowns a duel's winner on
/// a podium beside the series scoreboard and a head-to-head of the fight.
///
/// Both settle in about a second and a half, then the keys arm, so taps
/// meant for a bird cannot start another flight by accident. Reduced
/// Motion fades the stage in with everything still.

/// How long each stage's entrance runs, and the calm fade instead.
const _entrance = Duration(milliseconds: 1500);
const _calmEntrance = Duration(milliseconds: 450);

/// The part of the entrance after which the keys accept taps.
const _armAt = .62;

/// A sand inset for the quieter parts of a scoreboard, as on the solo
/// stage.
const _inset = Color(0xfff6ecda);

final _label = bodyText(
  12.5,
  color: SkyColors.muted,
  weight: FontWeight.w900,
).copyWith(letterSpacing: .8);

/// Minutes and seconds, as a flight's clock reads.
String _clock(double seconds) {
  final s = seconds.floor();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// The save line under a scoreboard: an error first, then the session,
/// then the flight itself. Null while there is nothing worth saying.
(IconData, String, Color)? coopStatus(PlayController flight) {
  if (flight.saveError.isNotEmpty) {
    return (Icons.error_outline_rounded, flight.saveError, SkyColors.coralDeep);
  }
  if (flight.sessionError.isNotEmpty) {
    return (
      Icons.error_outline_rounded,
      flight.sessionError,
      SkyColors.coralDeep,
    );
  }
  if (flight.sessionSaved) {
    // Teal deepened so small text keeps its contrast on cream.
    return (
      Icons.video_library_outlined,
      'Session saved · Watch in Records',
      const Color(0xff2e7d6f),
    );
  }
  return null;
}

// ------------------------------------------------------------------ stage --

/// The entrance and idle clocks the two stages share.
mixin _StageClock<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  bool get reducedMotion;

  late bool calm = reducedMotion;
  late final AnimationController intro = AnimationController(
    vsync: this,
    duration: calm ? _calmEntrance : _entrance,
  );

  /// A slow loop for the birds' bob and the sparkles; still under Reduced
  /// Motion.
  late final AnimationController idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (intro.status == AnimationStatus.dismissed) {
      calm = reducedMotion || MediaQuery.disableAnimationsOf(context);
      intro.duration = calm ? _calmEntrance : _entrance;
      intro.forward();
      if (!calm) idle.repeat();
    }
  }

  @override
  void dispose() {
    intro.dispose();
    idle.dispose();
    super.dispose();
  }

  /// Progress through the part of the entrance from [from] to [to].
  double span(double from, double to, [Curve curve = Curves.linear]) {
    if (calm) return 1;
    final t = ((intro.value - from) / (to - from)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  /// Seconds into the idle loop; null under Reduced Motion.
  double? get seconds => calm ? null : idle.value * 12;

  bool get armed => intro.value >= _armAt || intro.isCompleted;

  /// The whole stage: a vignette that quiets the flight, then [left] (title
  /// and illustration) beside [card] over the [keys].
  Widget stage({
    required Widget title,
    required Widget scene,
    required Widget card,
    required List<Widget> keys,
  }) => Opacity(
    opacity: calm ? intro.value : 1,
    child: Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: Opacity(
            opacity: span(0, .25),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-.35, -.1),
                  radius: 1.25,
                  colors: [Color(0x4d203b45), Color(0xc4203b45)],
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
                // A soft wash of sky that lifts the pair off the frozen
                // flight, whose own birds would otherwise peek through.
                Positioned(
                  left: 0,
                  top: 110,
                  width: 440,
                  height: 340,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: span(.05, .4),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, .05),
                            radius: .7,
                            colors: [
                              Color(0xf0d2effa),
                              Color(0xb3c4e9f6),
                              Color(0x00bde9f6),
                            ],
                            stops: [0, .55, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 112,
                  width: 410,
                  height: 320,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (1 - span(.02, .42, Curves.easeOutBack)) * 360,
                    ),
                    child: scene,
                  ),
                ),
                Positioned(left: 0, width: 436, top: 8, child: title),
                Positioned(
                  left: 444,
                  right: 20,
                  top: 12,
                  bottom: 14,
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _slideIn(card),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(height: 88, child: _keys(keys)),
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

  Widget _slideIn(Widget card) {
    final t = span(.1, .36, Curves.easeOutCubic);
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset((1 - t) * 70, 0), child: card),
    );
  }

  /// Home, Change birds and the session keep one width each; the last,
  /// the way back into the sky, takes the rest. Each pops in turn.
  Widget _keys(List<Widget> keys) {
    Widget pop(int i, Widget child) {
      final at = .34 + i * .03;
      final k = span(at, at + .22, Curves.easeOutBack);
      return Opacity(
        opacity: k.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - k) * 30),
          child: Transform.scale(scale: .8 + .2 * k, child: child),
        ),
      );
    }

    const widths = [96.0, 124.0, 132.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, key) in keys.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          if (i < widths.length && i < keys.length - 1)
            SizedBox(width: widths[i], child: pop(i, key))
          else
            Expanded(child: pop(i, key)),
        ],
      ],
    );
  }

  /// The scoreboard's frame: cream, ink-outlined, on a drop.
  Widget board(Widget child) => DecoratedBox(
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: child,
    ),
  );

  /// The title drops in and settles at a jaunty angle; its caption plate
  /// follows.
  Widget title(Widget lettering, Widget caption) {
    final drop = span(.04, .34, Curves.elasticOut);
    final plate = span(.26, .46, Curves.easeOutBack);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: span(.04, .12),
          child: Transform.translate(
            offset: Offset(0, (1 - drop) * -60),
            child: Transform.rotate(
              angle: -.035,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  height: 80,
                  child: FittedBox(fit: BoxFit.scaleDown, child: lettering),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Opacity(
          opacity: plate.clamp(0.0, 1.0),
          child: Transform.scale(scale: .7 + .3 * plate, child: caption),
        ),
      ],
    );
  }

  /// A small line of status, under the scoreboard.
  Widget note((IconData, String, Color) status) {
    final (icon, text, color) = status;
    return Opacity(
      opacity: span(.36, .56),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyText(12.5, color: color, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- team --

/// A roped or rope-free team's result: the pair on one cloud under "New
/// team best!" or "What a team.", the team score counting up beside the
/// team best, the flight's numbers, and how the flaps split between the
/// players.
class CoopTeamStage extends StatefulWidget {
  const CoopTeamStage({
    super.key,
    required this.birds,
    required this.mode,
    required this.score,
    required this.previousBest,
    required this.best,
    required this.durationSeconds,
    required this.stars,
    required this.gates,
    required this.flaps,
    required this.keys,
    required this.reducedMotion,
    this.status,
  });
  final (int, int) birds;
  final CoopMode mode;
  final int score, stars, gates;

  /// The team best before this flight, and the best saved now.
  final int previousBest, best;
  final double durationSeconds;

  /// Each player's flaps.
  final (int, int) flaps;

  /// Home, Change birds, the session and Fly again, in that order.
  final List<Widget> keys;
  final bool reducedMotion;
  final (IconData, String, Color)? status;

  bool get isBest => score > previousBest && score > 0;

  @override
  State<CoopTeamStage> createState() => _CoopTeamStageState();
}

class _CoopTeamStageState extends State<CoopTeamStage>
    with TickerProviderStateMixin, _StageClock {
  @override
  bool get reducedMotion => widget.reducedMotion;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([intro, idle]),
    builder: (context, _) {
      final w = widget;
      final (first, second) = w.birds;
      return stage(
        title: title(
          _Lettering(
            w.isBest ? 'New team best!' : 'What a team.',
            size: 62,
            fill: w.isBest ? SkyColors.yellow : SkyColors.cream,
          ),
          _CaptionPlate(
            children: [
              _ModeChip(w.mode),
              const SizedBox(width: 8),
              Text(
                '${birdNames[first]} & ${birdNames[second]}',
                style: bodyText(16, weight: FontWeight.w900),
              ),
            ],
          ),
        ),
        scene: _TeamScene(
          birds: w.birds,
          roped: w.mode == CoopMode.roped,
          seconds: seconds,
          cheer: w.isBest ? span(.72, 1) : 0,
        ),
        card: board(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 108, child: _scores()),
              const SizedBox(height: 6),
              Opacity(opacity: span(.2, .42), child: _stats()),
              const SizedBox(height: 8),
              Opacity(opacity: span(.26, .48), child: _split()),
              if (w.status case final status?) ...[
                const SizedBox(height: 6),
                note(status),
              ],
            ],
          ),
        ),
        keys: w.keys,
      );
    },
  );

  /// The team score counting up beside the team best's plaque, which a new
  /// best gilds under its ribbon once the score lands.
  Widget _scores() {
    final w = widget;
    final count = span(.3, .7, Curves.easeOutCubic);
    final land = math.sin(span(.7, .8) * math.pi);
    final ribbon = span(.72, .92, Curves.elasticOut);
    final gild = w.isBest ? span(.72, .78) : 0.0;
    final record = w.isBest && gild <= 0
        ? w.previousBest
        : math.max(w.best, w.score * (w.isBest ? 1 : 0));
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('TEAM SCORE', style: _label),
              Flexible(
                child: Transform.scale(
                  scale: 1 + .08 * land,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${(w.score * count).round()}',
                      style: matchDigits(
                        80,
                        color: w.isBest && count >= 1
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
          width: 204,
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
                  SizedBox(
                    height: 26,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 1 - gild,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('TEAM BEST', style: _label),
                          ),
                        ),
                        if (w.isBest && ribbon > 0)
                          OverflowBox(
                            maxWidth: 260,
                            maxHeight: 40,
                            child: Transform.scale(
                              scale: ribbon,
                              child: Transform.rotate(
                                angle: -.04,
                                child: const _Ribbon('NEW TEAM BEST!'),
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
                            record > 0 ? '$record' : '–',
                            style: matchDigits(44),
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

  Widget _stats() {
    final w = widget;
    return _Inset(
      tiles: [
        (
          Icons.timer_outlined,
          SkyColors.sky,
          _clock(w.durationSeconds),
          'flight time',
        ),
        (Icons.auto_awesome, SkyColors.yellow, '${w.stars}', 'stars'),
        (Icons.flag_rounded, SkyColors.mint, '${w.gates}', 'gates'),
      ],
    );
  }

  /// Each player's flaps in their own colour, with the share each put in
  /// as one bar between them.
  Widget _split() {
    final (one, two) = widget.flaps;
    final total = one + two;
    final share = total == 0 ? .5 : one / total;
    final grow = span(.4, .75, Curves.easeOutCubic);
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          _PlayerFlaps(player: 0, flaps: one),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('FLAP SHARE', style: _label),
                ),
                const SizedBox(height: 4),
                _ShareBar(share: .5 + (share - .5) * grow),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${(share * 100).round()}%',
                      style: bodyText(
                        12,
                        color: SkyColors.coralDeep,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${100 - (share * 100).round()}%',
                      style: bodyText(
                        12,
                        color: const Color(0xff2e7d6f),
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PlayerFlaps(player: 1, flaps: two),
        ],
      ),
    );
  }
}

/// A player's flaps on a plate of their colour, their tag on its corner.
class _PlayerFlaps extends StatelessWidget {
  const _PlayerFlaps({required this.player, required this.flaps});
  final int player, flaps;

  @override
  Widget build(BuildContext context) {
    final color = TetherArt.players[player];
    final left = player == 0;
    final tag = _PlayerCoin(player);
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$flaps',
            style: matchDigits(
              26,
              color: SkyColors.white,
            ).copyWith(shadows: matchInkEdge(1.2), height: 1.05),
          ),
        ),
        Text(
          'P${player + 1} flaps',
          maxLines: 1,
          style: bodyText(
            12,
            color: SkyColors.ink,
            weight: FontWeight.w900,
          ).copyWith(height: 1.1),
        ),
      ],
    );
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SkyColors.ink, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, SkyColors.ink, .45)!,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: left
            ? [tag, const SizedBox(width: 8), Expanded(child: body)]
            : [Expanded(child: body), const SizedBox(width: 8), tag],
      ),
    );
  }
}

/// A round "P1" or "P2" sticker in the player's colour, cream-rimmed.
class _PlayerCoin extends StatelessWidget {
  const _PlayerCoin(this.player, {this.size = 34});
  final int player;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: SkyColors.cream,
      shape: BoxShape.circle,
      border: Border.all(color: SkyColors.ink, width: 2),
    ),
    child: Text(
      'P${player + 1}',
      style: matchDigits(size * .42, color: TetherArt.players[player]),
    ),
  );
}

/// One bar split between the players' colours at [share] (player 1's
/// part), with a notch where the halves meet.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share});
  final double share;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 14,
    width: double.infinity,
    child: CustomPaint(painter: _SharePainter(share.clamp(.04, .96))),
  );
}

class _SharePainter extends CustomPainter {
  const _SharePainter(this.share);
  final double share;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final split = size.width * share;
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, split, size.height),
      Paint()..color = TetherArt.players[0],
    );
    canvas.drawRect(
      Rect.fromLTWH(split, 0, size.width - split, size.height),
      Paint()..color = TetherArt.players[1],
    );
    // A gloss along the top, as on the HUD's meters.
    canvas.drawRRect(
      RRect.fromLTRBR(
        5,
        2.5,
        size.width - 5,
        size.height * .42,
        const Radius.circular(3),
      ),
      Paint()..color = SkyColors.white.withValues(alpha: .35),
    );
    canvas.restore();
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = SkyColors.ink,
    );
    // The seam: a little cream diamond where the halves meet.
    final c = Offset(split, size.height / 2);
    final d = Path()
      ..moveTo(c.dx, c.dy - 9)
      ..lineTo(c.dx + 6, c.dy)
      ..lineTo(c.dx, c.dy + 9)
      ..lineTo(c.dx - 6, c.dy)
      ..close();
    canvas.drawPath(d, Paint()..color = SkyColors.cream);
    canvas.drawPath(
      d,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..color = SkyColors.ink,
    );
  }

  @override
  bool shouldRepaint(_SharePainter old) => old.share != share;
}

/// The pair on one cloud, facing each other: roped birds hold the flight's
/// own rope between them, rope-free birds share a heart.
class _TeamScene extends StatelessWidget {
  const _TeamScene({
    required this.birds,
    required this.roped,
    required this.seconds,
    required this.cheer,
  });
  final (int, int) birds;
  final bool roped;
  final double? seconds;
  final double cheer;

  static const _width = 150.0;
  static const _centers = [Offset(124, 180), Offset(286, 180)];

  /// Each bird's bob, out of step with its partner's.
  double _bob(int player) {
    final t = seconds;
    if (t == null) return 0;
    return math.sin(t * 2 * math.pi / 1.6 + player * 1.9) * 3.5;
  }

  @override
  Widget build(BuildContext context) {
    final (first, second) = birds;
    final centers = [
      for (final (i, c) in _centers.indexed) c + Offset(0, _bob(i)),
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _CloudPainter(front: false)),
        ),
        for (final (player, bird) in [first, second].indexed)
          Positioned(
            left: centers[player].dx - _width / 2,
            top: centers[player].dy - _width * .4375,
            child: _PuppetBird(
              bird: bird,
              width: _width,
              flip: player == 1,
              wing: -.45,
              expression: BirdExpression.pleased,
              tilt: player == 0 ? .05 : .05,
            ),
          ),
        Positioned.fill(
          child: CustomPaint(
            painter: _CloudPainter(
              front: true,
              rope: roped ? (centers[0], centers[1]) : null,
              heart: roped ? null : (centers[0] + centers[1]) / 2,
              seconds: seconds,
              cheer: cheer,
            ),
          ),
        ),
        // Each bird's tag rides on the cloud in front of it.
        for (final player in [0, 1])
          Positioned(
            left: _centers[player].dx + (player == 0 ? -46 : 46) - 24,
            top: _CloudPainter._center.dy + 4,
            width: 48,
            child: Center(child: _HudTag(player)),
          ),
      ],
    );
  }
}

/// The little "P1" or "P2" flag the flight hangs over each bird.
class _HudTag extends StatelessWidget {
  const _HudTag(this.player);
  final int player;

  @override
  Widget build(BuildContext context) => MatchPlate(
    color: TetherArt.players[player],
    padding: const EdgeInsets.fromLTRB(9, 1, 9, 2),
    child: Text(
      'P${player + 1}',
      style: matchDigits(
        16,
        color: SkyColors.white,
      ).copyWith(shadows: matchInkEdge(1)),
    ),
  );
}

/// A cloud wide enough for two, in the solo stage's style: white lobes
/// with a lavender underside on an ink outline. The [front] pass draws the
/// lip over the birds' laps, then the rope or the shared heart, then any
/// [cheer] sparkles.
class _CloudPainter extends CustomPainter {
  const _CloudPainter({
    required this.front,
    this.rope,
    this.heart,
    this.seconds,
    this.cheer = 0,
  });
  final bool front;
  final (Offset, Offset)? rope;
  final Offset? heart;
  final double? seconds;
  final double cheer;

  static const _center = Offset(205, 252);
  static const _back = <(double, double, double)>[
    (-156, 4, 38),
    (-104, -20, 52),
    (-36, -34, 58),
    (36, -34, 58),
    (104, -20, 52),
    (156, 4, 38),
  ];
  static const _front = <(double, double, double)>[
    (-128, 8, 32),
    (-70, 4, 36),
    (-8, 8, 32),
    (54, 4, 36),
    (116, 8, 32),
  ];

  static Path _union(Iterable<Path> parts) =>
      parts.reduce((a, b) => Path.combine(PathOperation.union, a, b));

  static Path _lobes(List<(double, double, double)> puffs) => _union([
    for (final (dx, dy, r) in puffs)
      Path()
        ..addOval(Rect.fromCircle(center: _center + Offset(dx, dy), radius: r)),
  ]);

  static final _whole = _union([
    Path()..addRRect(
      RRect.fromLTRBR(
        _center.dx - 190,
        _center.dy - 6,
        _center.dx + 190,
        _center.dy + 40,
        const Radius.circular(23),
      ),
    ),
    _lobes(_back),
  ]);

  static final _lip = _union([
    Path()..addRect(
      Rect.fromLTRB(
        _center.dx - 128,
        _center.dy,
        _center.dx + 116,
        _center.dy + 40,
      ),
    ),
    _lobes(_front),
  ]);

  static void _fill(Canvas c, Path shape) {
    c.drawPath(shape, Paint()..color = const Color(0xffdcd6fb));
    c.save();
    c.translate(0, -11);
    c.drawPath(shape, Paint()..color = SkyColors.white);
    c.restore();
  }

  static void _shine(Canvas c, List<(double, double, double)> puffs) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = SkyColors.cream;
    for (final (dx, dy, r) in puffs) {
      if (r < 34) continue;
      c.drawArc(
        Rect.fromCircle(center: _center + Offset(dx, dy), radius: r * .66),
        math.pi * 1.12,
        .62,
        false,
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..color = SkyColors.ink;
    if (!front) {
      canvas.drawOval(
        Rect.fromCenter(
          center: _center + const Offset(0, 58),
          width: 360,
          height: 20,
        ),
        Paint()..color = SkyColors.ink.withValues(alpha: .2),
      );
      canvas.drawPath(_whole, ink);
      canvas.save();
      canvas.clipPath(_whole);
      _fill(canvas, _whole);
      _shine(canvas, _back);
      canvas.restore();
      return;
    }
    canvas.save();
    canvas.clipPath(_whole);
    _fill(canvas, _lip);
    canvas.clipRect(
      Rect.fromLTRB(
        _center.dx - 220,
        _center.dy - 120,
        _center.dx + 220,
        _center.dy + 4,
      ),
    );
    canvas.drawPath(_lip, ink..strokeWidth = 5.5);
    canvas.restore();
    _shine(canvas, _front);

    if (rope case (final a, final b)) {
      // The flight's own rope, tied round each bird's middle. Its scale
      // leaves the pair close enough for the rope to hang slack.
      const h = 600.0;
      TetherArt.between(
        canvas,
        h,
        (a + const Offset(18, 26)) / h,
        (b + const Offset(-18, 26)) / h,
        seconds: seconds ?? 0,
        reducedMotion: seconds == null,
      );
    }
    if (heart case final at?) {
      final t = seconds;
      final beat = t == null ? 0.0 : math.pow(math.sin(t * math.pi), 8) * .12;
      _heart(canvas, at + const Offset(0, -6), 21 * (1 + beat));
    }
    if (cheer > 0) _sparkles(canvas, cheer);
  }

  @override
  bool shouldRepaint(_CloudPainter old) =>
      old.front != front ||
      old.rope != rope ||
      old.heart != heart ||
      old.seconds != seconds ||
      old.cheer != cheer;

  /// The shared heart: coral, ink-outlined, with a gloss.
  static void _heart(Canvas c, Offset at, double r) {
    Path shape(double r) => Path()
      ..moveTo(at.dx, at.dy + r * .95)
      ..cubicTo(
        at.dx - r * 1.5,
        at.dy - r * .05,
        at.dx - r * .95,
        at.dy - r * 1.25,
        at.dx,
        at.dy - r * .45,
      )
      ..cubicTo(
        at.dx + r * .95,
        at.dy - r * 1.25,
        at.dx + r * 1.5,
        at.dy - r * .05,
        at.dx,
        at.dy + r * .95,
      )
      ..close();
    final p = shape(r);
    c.drawPath(
      p.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    );
    c.drawPath(p, Paint()..color = SkyColors.coral);
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..color = SkyColors.ink,
    );
    c.drawArc(
      Rect.fromCircle(center: at + Offset(-r * .5, -r * .38), radius: r * .32),
      math.pi * 1.05,
      1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = SkyColors.white.withValues(alpha: .8),
    );
  }

  /// A burst of stars around the pair for a new team best.
  void _sparkles(Canvas c, double k) {
    const spots = [
      (40.0, 120.0, 0.0),
      (88.0, 60.0, .1),
      (205.0, 92.0, .2),
      (322.0, 60.0, .05),
      (372.0, 124.0, .15),
      (150.0, 40.0, .25),
      (262.0, 38.0, .3),
    ];
    for (final (x, y, delay) in spots) {
      final t = ((k - delay) / (1 - delay)).clamp(0.0, 1.0);
      final twinkle = seconds == null
          ? 1.0
          : .75 + .25 * math.sin(seconds! * 3 + x);
      final r = 9 * math.sin(t * math.pi * .5) * twinkle;
      if (r > .5) _star(c, Offset(x, y), r);
    }
  }
}

/// A small four-point twinkle, yellow on ink.
void _star(Canvas c, Offset at, double r) {
  final p = Path();
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4 - math.pi / 2;
    final d = i.isEven ? r : r * .38;
    final q = at + Offset(math.cos(a) * d, math.sin(a) * d);
    i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
  }
  p.close();
  c.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..color = SkyColors.ink,
  );
  c.drawPath(p, Paint()..color = SkyColors.yellow);
}

// ------------------------------------------------------------------- duel --

/// A duel player's numbers for the head-to-head.
typedef DuelLine = ({int hearts, int boxes, int hits});

/// A duel's result: the winner crowned on the taller step of a podium in
/// its colour under its title, the series as a scoreboard, and a
/// head-to-head of hearts left, boxes opened and hits landed. A draw puts
/// both birds on level steps, dazed, with no crown; a duel stopped from
/// the pause card leaves them level and unruffled.
class CoopDuelStage extends StatefulWidget {
  const CoopDuelStage({
    super.key,
    required this.birds,
    required this.winner,
    required this.title,
    required this.caption,
    required this.wins,
    required this.durationSeconds,
    required this.lines,
    required this.keys,
    required this.reducedMotion,
    this.stopped = false,
    this.status,
  });
  final (int, int) birds;
  final int? winner;
  final String title, caption;

  /// Whether the players stopped the duel before either was knocked out.
  final bool stopped;

  /// Duels each player has won since the screen opened.
  final (int, int) wins;
  final double durationSeconds;
  final List<DuelLine> lines;
  final List<Widget> keys;
  final bool reducedMotion;
  final (IconData, String, Color)? status;

  @override
  State<CoopDuelStage> createState() => _CoopDuelStageState();
}

class _CoopDuelStageState extends State<CoopDuelStage>
    with TickerProviderStateMixin, _StageClock {
  @override
  bool get reducedMotion => widget.reducedMotion;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([intro, idle]),
    builder: (context, _) {
      final w = widget;
      final winner = w.winner;
      return stage(
        title: title(
          _Lettering(
            w.title,
            key: const ValueKey('duel-title'),
            size: 64,
            fill: winner == null ? SkyColors.cream : TetherArt.players[winner],
          ),
          _CaptionPlate(
            children: [
              if (winner != null) ...[
                _PlayerCoin(winner, size: 26),
                const SizedBox(width: 8),
              ],
              Text(w.caption, style: bodyText(16, weight: FontWeight.w900)),
            ],
          ),
        ),
        scene: _Podium(
          birds: w.birds,
          winner: winner,
          stopped: w.stopped,
          seconds: seconds,
          rise: span(.3, .62, Curves.easeOutBack),
          crown: span(.55, .8, Curves.elasticOut),
        ),
        card: board(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _series(),
              const SizedBox(height: 10),
              Opacity(opacity: span(.24, .46), child: _headToHead()),
              const SizedBox(height: 6),
              Opacity(
                opacity: span(.3, .5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: SkyColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Duel time ${_clock(w.durationSeconds)}',
                      style: bodyText(
                        12.5,
                        color: SkyColors.muted,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (w.status case final status?) ...[
                const SizedBox(height: 4),
                note(status),
              ],
            ],
          ),
        ),
        keys: w.keys,
      );
    },
  );

  /// The series on a dark scoreboard, each player's wins in their colour
  /// beside their bird's name; the winner's new point pops as it lands.
  Widget _series() {
    final w = widget;
    final (one, two) = w.wins;
    final (first, second) = w.birds;
    final pop = math.sin(span(.5, .62) * math.pi);
    TextStyle digits(int player) =>
        matchDigits(54, color: TetherArt.players[player]).copyWith(
          height: 1,
          shadows: [
            Shadow(
              color: TetherArt.players[player].withValues(alpha: .7),
              blurRadius: 14,
            ),
          ],
        );
    Widget side(int player, int bird) {
      final won = w.winner == player;
      final left = player == 0;
      final name = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: left
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            'PLAYER ${player + 1}',
            style: bodyText(
              11,
              color: TetherArt.players[player],
              weight: FontWeight.w900,
            ).copyWith(letterSpacing: 1),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              birdNames[bird],
              style: heading(
                20,
                color: SkyColors.cream,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
      final crown = Opacity(
        opacity: won ? 1 : 0,
        child: const SizedBox(
          width: 26,
          height: 22,
          child: CustomPaint(painter: _CrownPainter()),
        ),
      );
      return Expanded(
        child: Row(
          mainAxisAlignment: left
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: left
              ? [crown, const SizedBox(width: 6), Flexible(child: name)]
              : [Flexible(child: name), const SizedBox(width: 6), crown],
        ),
      );
    }

    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SkyColors.ink, width: 3),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff2c4c58), Color(0xff1d3640)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xff142a32), offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          side(0, first),
          Transform.scale(
            scale: 1 + .1 * pop,
            child: Text.rich(
              key: const ValueKey('duel-series'),
              TextSpan(
                children: [
                  TextSpan(
                    text: 'SERIES ',
                    style: bodyText(
                      13,
                      color: SkyColors.cream.withValues(alpha: .75),
                      weight: FontWeight.w900,
                    ).copyWith(letterSpacing: 1.4),
                  ),
                  TextSpan(
                    text: '$one',
                    style: digits(0).copyWith(letterSpacing: 6),
                  ),
                  TextSpan(
                    text: '–',
                    style: matchDigits(
                      36,
                      color: SkyColors.cream.withValues(alpha: .6),
                    ).copyWith(letterSpacing: 6),
                  ),
                  TextSpan(text: '$two', style: digits(1)),
                ],
              ),
            ),
          ),
          side(1, second),
        ],
      ),
    );
  }

  /// Hearts left, boxes opened and hits landed, each player's number on
  /// their side; whoever did better gets their colour.
  Widget _headToHead() {
    final [a, b] = widget.lines;
    final rows = [
      (Icons.favorite_rounded, 'hearts left', a.hearts, b.hearts),
      (Icons.card_giftcard_rounded, 'boxes opened', a.boxes, b.boxes),
      (Icons.bolt_rounded, 'hits landed', a.hits, b.hits),
    ];
    Widget value(int player, int n, bool ahead) {
      final color = TetherArt.players[player];
      return Container(
        width: 76,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ahead ? color : _inset,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ahead ? SkyColors.ink : SkyColors.sand.withValues(alpha: .6),
            width: ahead ? 2 : 1.5,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$n',
            style: ahead
                ? matchDigits(
                    22,
                    color: SkyColors.white,
                  ).copyWith(shadows: matchInkEdge(1.1))
                : matchDigits(22, color: SkyColors.ink),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final (i, (icon, label, one, two)) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              value(0, one, one > two),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 17, color: SkyColors.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(
                          14,
                          color: SkyColors.ink,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              value(1, two, two > one),
            ],
          ),
        ],
      ],
    );
  }
}

/// The podium: a step in each player's colour, the winner's taller, with
/// sunrays and confetti behind the crowned winner. Player 1 stands on the
/// left and player 2 on the right, facing each other, as they flew.
class _Podium extends StatelessWidget {
  const _Podium({
    required this.birds,
    required this.winner,
    required this.stopped,
    required this.seconds,
    required this.rise,
    required this.crown,
  });
  final (int, int) birds;
  final int? winner;
  final bool stopped;
  final double? seconds;
  final double rise, crown;

  static const _base = 292.0;
  static const _steps = [(52.0, 196.0), (214.0, 358.0)];

  double height(int player) => winner == null
      ? 84
      : winner == player
      ? 112
      : 60;

  @override
  Widget build(BuildContext context) {
    final (first, second) = birds;
    final t = seconds;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _PodiumPainter(
              winner: winner,
              stopped: stopped,
              heights: [height(0) * rise, height(1) * rise],
              seconds: t,
            ),
          ),
        ),
        for (final (player, bird) in [first, second].indexed)
          _bird(player, bird, t),
      ],
    );
  }

  Widget _bird(int player, int bird, double? t) {
    final won = winner == player;
    final lost = winner != null && !won;
    // A draw knocks both out; a stopped duel leaves both unruffled.
    final dazed = lost || (winner == null && !stopped);
    final width = won ? 150.0 : 128.0;
    final (l, r) = _steps[player];
    final top = _base - height(player) * rise;
    final hop = t == null || !won
        ? 0.0
        : math.max(0.0, math.sin(t * 2 * math.pi / 1.4)) * 7;
    final birdHeight = width * 224 / 256;
    return Positioned(
      left: (l + r) / 2 - width / 2,
      top: top - birdHeight + 10 - hop,
      width: width,
      height: birdHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _PuppetBird(
              key: ValueKey('duel-result-bird-$player'),
              bird: bird,
              width: width,
              flip: player == 1,
              wing: won ? -.55 : .38,
              tilt: dazed ? -.1 : .04,
              expression: won
                  ? BirdExpression.pleased
                  : dazed
                  ? BirdExpression.dazed
                  : BirdExpression.neutral,
            ),
          ),
          // The loser sees stars; the winner wears the crown.
          if (dazed)
            Positioned(
              left: 0,
              right: 0,
              top: -14,
              height: 30,
              child: CustomPaint(painter: _DizzyPainter(seconds: t)),
            ),
          if (won && crown > 0)
            Positioned(
              left: width / 2 - 30 + (player == 0 ? -4 : 4),
              top: -40,
              width: 60,
              height: 50,
              child: Transform.rotate(
                angle:
                    (player == 0 ? -.16 : .16) +
                    (t == null ? 0 : math.sin(t * 2.4) * .04),
                child: Transform.scale(
                  scale: crown,
                  child: const CustomPaint(painter: _CrownPainter()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PodiumPainter extends CustomPainter {
  const _PodiumPainter({
    required this.winner,
    required this.stopped,
    required this.heights,
    required this.seconds,
  });
  final int? winner;
  final bool stopped;
  final List<double> heights;
  final double? seconds;

  @override
  void paint(Canvas canvas, Size size) {
    const base = _Podium._base;
    final win = winner;
    if (win != null) {
      final (l, r) = _Podium._steps[win];
      final at = Offset((l + r) / 2, base - heights[win] - 70);
      _rays(canvas, at, TetherArt.players[win]);
      _confetti(canvas, at);
    }
    // A soft shadow the podium stands in.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(205, base + 6),
        width: 360,
        height: 18,
      ),
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    );
    for (final (player, (l, r)) in _Podium._steps.indexed) {
      _step(canvas, player, Rect.fromLTRB(l, base - heights[player], r, base));
    }
  }

  /// Soft sunrays fanning out behind the winner, turning slowly.
  void _rays(Canvas c, Offset at, Color color) {
    final turn = (seconds ?? 0) * .12;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          SkyColors.yellow.withValues(alpha: .8),
          color.withValues(alpha: .32),
          color.withValues(alpha: 0),
        ],
        stops: const [0, .5, 1],
      ).createShader(Rect.fromCircle(center: at, radius: 190));
    const count = 12;
    for (var i = 0; i < count; i++) {
      final a = turn + i * 2 * math.pi / count;
      final p = Path()
        ..moveTo(at.dx, at.dy)
        ..lineTo(
          at.dx + math.cos(a - .12) * 200,
          at.dy + math.sin(a - .12) * 200,
        )
        ..lineTo(
          at.dx + math.cos(a + .12) * 200,
          at.dy + math.sin(a + .12) * 200,
        )
        ..close();
      c.drawPath(p, paint);
    }
  }

  /// Confetti drifting down around the winner, in both players' colours
  /// and gold.
  void _confetti(Canvas c, Offset at) {
    const colors = [
      SkyColors.yellow,
      SkyColors.coral,
      SkyColors.teal,
      SkyColors.lavender,
    ];
    final t = seconds;
    for (var i = 0; i < 16; i++) {
      final seed = i * 37.0;
      final dx = math.sin(seed) * 170;
      final fall = t == null ? 0.0 : (t * (18 + i % 5 * 4) + seed) % 220;
      final y = at.dy - 90 + ((seed * 3.1) % 220 + fall) % 220;
      final x = at.dx + dx + (t == null ? 0 : math.sin(t * 1.3 + seed) * 6);
      final spin = (t ?? 0) * 2 + seed;
      c.save();
      c.translate(x, y);
      c.rotate(spin);
      final r = Rect.fromCenter(
        center: Offset.zero,
        width: 9,
        height: i.isEven ? 5 : 9,
      );
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(1.5));
      c.drawRRect(rr, Paint()..color = colors[i % colors.length]);
      c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = SkyColors.ink,
      );
      c.restore();
    }
  }

  /// One step: a block in the player's colour with a lighter top, its
  /// place on a cream medal.
  void _step(Canvas c, int player, Rect r) {
    if (r.height < 4) return;
    final color = TetherArt.players[player];
    final shape = RRect.fromRectAndCorners(
      r,
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );
    c.drawRRect(
      shape.shift(const Offset(0, 5)),
      Paint()..color = Color.lerp(color, SkyColors.ink, .5)!,
    );
    c.drawRRect(shape, Paint()..color = color);
    c.save();
    c.clipRRect(shape);
    // A lighter cap and a darker foot give the block its depth.
    c.drawRect(
      Rect.fromLTWH(r.left, r.top, r.width, 16),
      Paint()..color = Color.lerp(color, SkyColors.white, .38)!,
    );
    c.drawRect(
      Rect.fromLTWH(r.left, r.top + 16, r.width, 2.5),
      Paint()..color = SkyColors.ink.withValues(alpha: .35),
    );
    c.drawRect(
      Rect.fromLTWH(r.left, r.bottom - 12, r.width, 12),
      Paint()..color = Color.lerp(color, SkyColors.ink, .18)!,
    );
    c.restore();
    c.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..color = SkyColors.ink,
    );
    final win = winner;
    if (r.height < 52 || (win == null && stopped)) return;
    final place = win == null
        ? '='
        : win == player
        ? '1'
        : '2';
    final medal = Offset(r.center.dx, r.top + 16 + (r.height - 28) / 2);
    final radius = win == player ? 22.0 : 18.0;
    c.drawCircle(
      medal + const Offset(0, 2.5),
      radius,
      Paint()..color = SkyColors.ink.withValues(alpha: .3),
    );
    c.drawCircle(
      medal,
      radius,
      Paint()..color = win == player ? SkyColors.yellow : SkyColors.cream,
    );
    c.drawCircle(
      medal,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = SkyColors.ink,
    );
    final text = TextPainter(
      text: TextSpan(text: place, style: matchDigits(radius * 1.35)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(c, medal - Offset(text.width / 2, text.height / 2 + 1));
    text.dispose();
  }

  @override
  bool shouldRepaint(_PodiumPainter old) =>
      old.winner != winner ||
      old.stopped != stopped ||
      old.heights[0] != heights[0] ||
      old.heights[1] != heights[1] ||
      old.seconds != seconds;
}

/// Three little stars circling a beaten bird's head; still under Reduced
/// Motion.
class _DizzyPainter extends CustomPainter {
  const _DizzyPainter({required this.seconds});
  final double? seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final turn = (seconds ?? 0) * 2.2;
    for (var i = 0; i < 3; i++) {
      final a = turn + i * 2 * math.pi / 3;
      _star(
        canvas,
        c + Offset(math.cos(a) * size.width * .26, math.sin(a) * 6),
        7 + math.sin(a) * 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_DizzyPainter old) => old.seconds != seconds;
}

/// A gold crown with three points, a gem on each, outlined in ink.
class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final s = math.min(w / 60, h / 50);
    canvas.save();
    canvas.translate((w - 60 * s) / 2, (h - 50 * s) / 2);
    canvas.scale(s);
    final body = Path()
      ..moveTo(8, 40)
      ..lineTo(4, 14)
      ..lineTo(19, 26)
      ..lineTo(30, 8)
      ..lineTo(41, 26)
      ..lineTo(56, 14)
      ..lineTo(52, 40)
      ..close();
    final band = RRect.fromLTRBR(7, 36, 53, 46, const Radius.circular(4));
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeJoin = StrokeJoin.round
      ..color = SkyColors.ink;
    canvas.drawPath(
      body.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    );
    canvas.drawPath(body, Paint()..color = SkyColors.yellow);
    // A shade down the right of the crown.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      const Rect.fromLTWH(34, 0, 30, 50),
      Paint()..color = SkyColors.gold.withValues(alpha: .55),
    );
    canvas.restore();
    canvas.drawPath(body, ink);
    canvas.drawRRect(band, Paint()..color = SkyColors.gold);
    canvas.drawRRect(band, ink);
    for (final (x, y, r) in [
      (4.0, 13.0, 4.2),
      (30.0, 7.0, 4.8),
      (56.0, 13.0, 4.2),
    ]) {
      canvas.drawCircle(Offset(x, y), r, Paint()..color = SkyColors.cream);
      canvas.drawCircle(Offset(x, y), r, ink..strokeWidth = 2.6);
    }
    // A coral gem on the band, with a glint.
    canvas.drawCircle(
      const Offset(30, 41),
      4,
      Paint()..color = SkyColors.coral,
    );
    canvas.drawCircle(const Offset(30, 41), 4, ink..strokeWidth = 2.2);
    canvas.drawLine(
      const Offset(12, 32),
      const Offset(15, 22),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = SkyColors.white.withValues(alpha: .75),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CrownPainter old) => false;
}

// ------------------------------------------------------------------ parts --

/// A bird drawn by [BirdPuppet] in a box [width] wide, so it can raise its
/// wings and pull a face; [flip] turns it to face left.
class _PuppetBird extends StatelessWidget {
  const _PuppetBird({
    super.key,
    required this.bird,
    required this.width,
    this.flip = false,
    this.wing = 0,
    this.tilt = 0,
    this.expression = BirdExpression.neutral,
  });
  final int bird;
  final double width, wing, tilt;
  final bool flip;
  final BirdExpression expression;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 224 / 256,
    child: CustomPaint(
      painter: _PuppetPainter(bird, flip, wing, tilt, expression),
    ),
  );
}

class _PuppetPainter extends CustomPainter {
  const _PuppetPainter(
    this.bird,
    this.flip,
    this.wing,
    this.tilt,
    this.expression,
  );
  final int bird;
  final bool flip;
  final double wing, tilt;
  final BirdExpression expression;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (flip) canvas.scale(-1, 1);
    canvas.rotate(tilt);
    BirdPuppet.paint(
      canvas,
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width,
        height: size.height,
      ),
      bird: bird,
      wing: wing,
      expression: expression,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PuppetPainter old) =>
      old.bird != bird ||
      old.flip != flip ||
      old.wing != wing ||
      old.tilt != tilt ||
      old.expression != expression;
}

/// Big lettering in the solo stage's style: a fill with a thick ink edge
/// and a soft drop. The edge is painted behind a single [Text], so the
/// title reads (and is found) as one piece of text.
class _Lettering extends StatelessWidget {
  const _Lettering(
    this.text, {
    super.key,
    required this.size,
    required this.fill,
  });
  final String text;
  final double size;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final style = heading(size, weight: FontWeight.w700).copyWith(height: 1.1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: CustomPaint(
        painter: _EdgePainter(text, style, MediaQuery.textScalerOf(context)),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: style.copyWith(color: fill),
        ),
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter(this.text, this.style, this.scaler);
  final String text;
  final TextStyle style;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    TextPainter edge(double width, Color color) => TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final k = style.fontSize! / 96;
    final drop = edge(12 * k + 2, SkyColors.ink.withValues(alpha: .35));
    drop.paint(canvas, Offset(0, 6 * k + 1));
    drop.dispose();
    final ink = edge(10 * k + 2, SkyColors.ink);
    ink.paint(canvas, Offset.zero);
    ink.dispose();
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.text != text || old.style != style || old.scaler != scaler;
}

/// The cream plate a title's caption rides on, so it reads over any world.
class _CaptionPlate extends StatelessWidget {
  const _CaptionPlate({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 420),
    padding: const EdgeInsets.fromLTRB(10, 5, 16, 5),
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
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );
}

/// The co-op mode as a small chip: a rope for Roped, a heart for No rope.
class _ModeChip extends StatelessWidget {
  const _ModeChip(this.mode);
  final CoopMode mode;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(7, 1, 9, 2),
    decoration: BoxDecoration(
      color: mode == CoopMode.roped ? SkyColors.yellow : SkyColors.mint,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SkyColors.ink, width: 1.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          mode == CoopMode.roped ? Icons.link_rounded : Icons.favorite_rounded,
          size: 15,
          color: SkyColors.ink,
        ),
        const SizedBox(width: 4),
        Text(mode.title, style: heading(15, weight: FontWeight.w700)),
      ],
    ),
  );
}

/// A yellow banner with notched tails, outlined in ink, for a new best.
class _Ribbon extends StatelessWidget {
  const _Ribbon(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _RibbonPainter(),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 5, 22, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 16,
            color: SkyColors.ink,
          ),
          const SizedBox(width: 5),
          Text(label, style: bodyText(13, weight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const notch = 10.0;
    final shape = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - notch, h / 2)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(notch, h / 2)
      ..close();
    canvas.drawPath(
      shape.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    );
    canvas.drawPath(shape, Paint()..color = SkyColors.yellow);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = SkyColors.ink,
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => false;
}

/// Quiet stat tiles on a sand inset, as on the solo scoreboard.
typedef _Tile = (IconData, Color, String, String);

class _Inset extends StatelessWidget {
  const _Inset({required this.tiles});
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: _inset,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        for (final (i, (icon, color, value, label)) in tiles.indexed) ...[
          if (i > 0)
            Container(
              width: 1.5,
              height: 30,
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(value, style: matchDigits(22)),
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
  );
}

// ------------------------------------------------------------------ pause --

/// Fly Together's pause card: PlayScreen's [PauseCard], with the pair
/// perched on its top edge for their breather.
class CoopPauseCard extends StatelessWidget {
  const CoopPauseCard({
    super.key,
    required this.birds,
    required this.onFinish,
    required this.onResume,
    this.tipSeed = 0,
    this.reducedMotion = false,
  });
  final (int, int) birds;
  final VoidCallback onFinish, onResume;

  /// Picks the breather tip; keep it fixed for the length of a pause.
  final int tipSeed;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final (first, second) = birds;
    return PauseCard(
      reducedMotion: reducedMotion,
      subtitle: 'You’re both perched and waiting. We’ll count you both in.',
      tip: pauseTip(pauseTipsCoop, tipSeed),
      secondary: [
        SkyButton(
          label: 'Finish flight',
          onPressed: onFinish,
          color: SkyColors.cream,
          icon: Icons.flag_outlined,
          compact: true,
        ),
      ],
      onResume: onResume,
      perched: [
        // The pair rests on the card's edge, either side of the badge.
        for (final (player, bird) in [first, second].indexed)
          Positioned(
            top: -45,
            left: player == 0 ? 34 : null,
            right: player == 1 ? 34 : null,
            child: ExcludeSemantics(
              child: _PuppetBird(
                bird: bird,
                width: 66,
                flip: player == 1,
                wing: .25,
                expression: BirdExpression.blink,
              ),
            ),
          ),
      ],
    );
  }
}
