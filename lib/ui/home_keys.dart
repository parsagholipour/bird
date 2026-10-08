import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../game/star_art.dart';
import '../l10n/l10n.dart';
import 'control_glyphs.dart';
import 'home_world.dart';
import 'theme.dart';
import 'ui_sounds.dart';

/// The title screen's keys: the two ways into the main game, Campaign and
/// Endless, side by side, and the smaller Mini games key under them.
///
/// Every key is built the same way: a face on a darker lip, an ink outline, a
/// cream inner ring and a streak of light. Pressing sinks the face toward the
/// lip without moving the touch target.

/// The colors of a [HomeKey]: its face's gradient at rest, hovered and
/// pressed, the lip it sits on and the glow that lifts it off the sky.
class HomeKeyColors {
  const HomeKeyColors({
    required this.face,
    required this.hovered,
    required this.pressed,
    required this.lip,
    required this.glow,
  });
  final List<Color> face, hovered, pressed;
  final Color lip, glow;

  /// Endless: the warm yellow of the old Play key.
  static const sun = HomeKeyColors(
    face: [Color(0xffffe991), Color(0xffffcc4d)],
    hovered: [Color(0xffffeead), Color(0xffffd969)],
    pressed: [Color(0xffffd05a), Color(0xfff2b839)],
    lip: Color(0xffce9239),
    glow: Color(0x99ffd45b),
  );

  /// Campaign: mint, like the map's meadows.
  static const mint = HomeKeyColors(
    face: [Color(0xffc4f0d3), Color(0xff69c893)],
    hovered: [Color(0xffd3f5df), Color(0xff7cd3a2)],
    pressed: [Color(0xffa9e6bf), Color(0xff55b984)],
    lip: Color(0xff2f8c69),
    glow: Color(0x807fe0a8),
  );

  /// Squat & Fly and the duel: the picker's coral.
  static const coral = HomeKeyColors(
    face: [Color(0xffffc2b3), Color(0xfff47d64)],
    hovered: [Color(0xffffcfc3), Color(0xfff68d77)],
    pressed: [Color(0xffffab97), Color(0xffe56b53)],
    lip: Color(0xffad4636),
    glow: Color(0x80f47d64),
  );

  /// A quiet paper key, for a way on that is not the main one.
  static const paper = HomeKeyColors(
    face: [Color(0xffffffff), Color(0xfffff1d9)],
    hovered: [Color(0xffffffff), Color(0xfffff6e6)],
    pressed: [Color(0xfffff5e3), Color(0xfff6e4c4)],
    lip: Color(0xffc2ab84),
    glow: Color(0x40ffffff),
  );

  /// Mini games: a quieter lavender, so the two main keys lead.
  static const lavender = HomeKeyColors(
    face: [Color(0xffeee8ff), Color(0xffcbbdf7)],
    hovered: [Color(0xfff4f0ff), Color(0xffd6cbf9)],
    pressed: [Color(0xffddd3fb), Color(0xffb6a5f0)],
    lip: Color(0xff7462b8),
    glow: Color(0x55b9aaf2),
  );

  /// The Level Builder: blueprint blue, as quiet as the mini games beside it.
  static const blueprint = HomeKeyColors(
    face: [Color(0xffe2f5ff), Color(0xffa3daf3)],
    hovered: [Color(0xffeaf8ff), Color(0xffb2e1f6)],
    pressed: [Color(0xffcfeefc), Color(0xff8dcdec)],
    lip: Color(0xff3b82a8),
    glow: Color(0x5590d5ee),
  );

  /// A key that is not open yet: the shop's greyed paper, with no glow.
  static const locked = HomeKeyColors(
    face: [Color(0xfff7f2e7), Color(0xffdcd8cd)],
    hovered: [Color(0xfffaf6ee), Color(0xffe4e0d6)],
    pressed: [Color(0xffefe9dc), Color(0xffd0ccc0)],
    lip: Color(0xff9fb0b4),
    glow: Color(0x00000000),
  );
}

/// A physical-looking key with a native button underneath, so it takes taps,
/// keyboard activation and focus. Lay it out in a box: the face fills all but
/// the bottom [lip].
///
/// With [animated], it breathes at rest and a glint crosses it every few
/// seconds. [reducedMotion] joins the platform's animation setting in keeping
/// the key still.
class HomeKey extends StatefulWidget {
  const HomeKey({
    super.key,
    required this.label,
    required this.colors,
    required this.onPressed,
    required this.builder,
    this.lip = 8,
    this.radius = 26,
    this.animated = false,
    this.reducedMotion = false,
    this.cue = 'ui_tap',
  });

  /// What a screen reader announces.
  final String label;
  final HomeKeyColors colors;
  final VoidCallback onPressed;

  /// The face's content. [breath] rests at 0 and, while the key breathes,
  /// rises to 1 twice a cycle.
  final Widget Function(BuildContext context, Animation<double> breath) builder;
  final double lip, radius;
  final bool animated, reducedMotion;

  /// The sound a press plays.
  final String cue;

  @override
  State<HomeKey> createState() => _HomeKeyState();
}

class _HomeKeyState extends State<HomeKey> with SingleTickerProviderStateMixin {
  final states = WidgetStatesController();
  late final loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  late final Animation<double> breath = loop.drive(const _Breath());
  // True while the key should hold its resting pose.
  bool still = true;

  bool get reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(HomeKey oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    still = !widget.animated || reduced;
    if (still) {
      loop.stop();
      loop.value = 0;
    } else if (!loop.isAnimating) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = reduced;
    final colors = widget.colors;
    final lip = widget.lip;
    final radius = BorderRadius.circular(widget.radius);
    final ink = Border.all(color: SkyColors.ink, width: 2.5);
    return SizedBox.expand(
      child: TextButton(
        statesController: states,
        onPressed: () {
          UiSounds.effect(context, widget.cue);
          widget.onPressed();
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: radius),
          enableFeedback: true,
        ),
        child: Semantics(
          label: widget.label,
          excludeSemantics: true,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // A glow that stays put while the key breathes over it.
              Positioned(
                top: lip,
                left: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: colors.glow,
                          blurRadius: 26,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: breath,
                builder: (context, child) => Transform.scale(
                  scale: 1 + .016 * breath.value,
                  child: child,
                ),
                child: ValueListenableBuilder<Set<WidgetState>>(
                  valueListenable: states,
                  builder: (context, value, _) {
                    final pressed = value.contains(WidgetState.pressed);
                    final focused = value.contains(WidgetState.focused);
                    final hovered = value.contains(WidgetState.hovered);
                    return Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        if (focused)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: radius,
                                boxShadow: const [
                                  BoxShadow(
                                    color: SkyColors.ink,
                                    spreadRadius: 7,
                                  ),
                                  BoxShadow(
                                    color: SkyColors.cream,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: lip,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.lip,
                              borderRadius: radius,
                              border: ink,
                              boxShadow: [
                                BoxShadow(
                                  color: SkyColors.ink.withValues(alpha: .16),
                                  offset: const Offset(0, 4),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: lip,
                          left: 0,
                          right: 0,
                          child: AnimatedContainer(
                            duration: reducedMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 90),
                            curve: Curves.easeOut,
                            transform: Matrix4.translationValues(
                              0,
                              pressed && !reducedMotion ? lip * .75 : 0,
                              0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              border: ink,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: pressed
                                    ? colors.pressed
                                    : hovered
                                    ? colors.hovered
                                    : colors.face,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          math.max(0, widget.radius - 7),
                                        ),
                                        border: Border.all(
                                          color: SkyColors.cream.withValues(
                                            alpha: .55,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: widget.radius,
                                  top: 7,
                                  width: 56,
                                  height: 3,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: SkyColors.cream.withValues(
                                        alpha: .85,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                if (!still)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        math.max(0, widget.radius - 3),
                                      ),
                                      child: CustomPaint(
                                        painter: _GlintPainter(loop),
                                      ),
                                    ),
                                  ),
                                widget.builder(context, breath),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two slow breaths per cycle: 0 at rest, 1 at the top of each.
class _Breath extends Animatable<double> {
  const _Breath();

  @override
  double transform(double t) => .5 - .5 * math.cos(t * 4 * math.pi);
}

/// A heading with a cream drop line, the lettering every key shares.
TextStyle _keyTitle(double size) =>
    heading(size, weight: FontWeight.w700).copyWith(
      letterSpacing: 1.5,
      height: 1,
      shadows: const [Shadow(color: SkyColors.cream, offset: Offset(0, 1.5))],
    );

/// Endless: Tap & Fly, straight into the sky with no mode to
/// choose. It breathes and glints to invite a quick flight, and shows the best
/// endless flight on a tag.
class HomeEndlessKey extends StatelessWidget {
  const HomeEndlessKey({
    super.key,
    required this.best,
    required this.onPressed,
    this.animated = false,
    this.reducedMotion = false,
  });

  /// Star points of the best endless flight; zero before the first.
  final int best;
  final VoidCallback onPressed;
  final bool animated, reducedMotion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // The play arrow points the way the language reads.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return HomeKey(
      label: best > 0
          ? l.homeEndlessBestSemantics(best)
          : l.homeEndlessSemantics,
      colors: HomeKeyColors.sun,
      animated: animated,
      reducedMotion: reducedMotion,
      onPressed: onPressed,
      builder: (context, breath) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 18, 12),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeEndlessTitle, style: _keyTitle(30)),
                    const SizedBox(height: 3),
                    Text(
                      l.homeEndlessDetail,
                      style: bodyText(
                        12.5,
                        color: const Color(0xff6e4b12),
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _BestTag(best: best),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: breath,
              builder: (context, child) => Transform.translate(
                offset: Offset((rtl ? -4 : 4) * breath.value, 0),
                child: child,
              ),
              child: Transform.flip(
                flipX: rtl,
                child: const CustomPaint(
                  size: Size(30, 34),
                  painter: _PlayArrowPainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The campaign: a little map, the level it continues with and the level
/// stars earned so far.
class HomeCampaignKey extends StatelessWidget {
  const HomeCampaignKey({
    super.key,
    required this.stars,
    required this.of,
    required this.next,
    required this.onPressed,
  });

  /// Level stars earned, out of those this build offers.
  final int stars, of;

  /// The level the campaign continues with, such as "1-3 · Canopy Run", or
  /// null once every level this build offers is cleared.
  final String? next;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final motion = HomeMotion.maybeOf(context);
    final still = motion?.still ?? true;
    final done = of > 0 && stars >= of;
    return HomeKey(
      label: next == null
          ? l.homeCampaignDoneSemantics(stars, of)
          : l.homeCampaignNextSemantics(stars, of, next!),
      colors: HomeKeyColors.mint,
      onPressed: onPressed,
      builder: (context, _) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 12),
        child: Row(
          children: [
            RepaintBoundary(
              child: CustomPaint(
                size: const Size(70, 46),
                painter: _MapPainter(
                  motion?.clock ?? const _Rest(),
                  still || MediaQuery.disableAnimationsOf(context),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeCampaignTitle, style: _keyTitle(27)),
                    const SizedBox(height: 3),
                    Text(
                      next ?? l.homeCampaignDone,
                      style: bodyText(
                        12.5,
                        color: const Color(0xff1d5a43),
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _StarTag(stars: stars, of: of, done: done),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A clock that never moves, for a key shown outside the title screen.
class _Rest implements ValueListenable<double> {
  const _Rest();
  @override
  double get value => 0;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

/// One of the two quieter keys under the main game: a sticker cluster, a
/// title and a few words, and an arrow. Mini games and the Level Builder
/// share the row at half width each.
class _HalfKey extends StatelessWidget {
  const _HalfKey({
    required this.label,
    required this.colors,
    required this.onPressed,
    required this.art,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    this.trailing = Icons.arrow_forward_rounded,
    this.trailingColor = SkyColors.ink,
    this.cue = 'ui_tap',
  });
  final String label, title, subtitle, cue;
  final HomeKeyColors colors;
  final VoidCallback onPressed;
  final Widget art;
  final Color subtitleColor, trailingColor;
  final IconData trailing;

  @override
  Widget build(BuildContext context) => HomeKey(
    label: label,
    colors: colors,
    lip: 6,
    radius: 22,
    cue: cue,
    onPressed: onPressed,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          art,
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _keyTitle(20)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: bodyText(
                      11.5,
                      color: subtitleColor,
                      weight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(trailing, size: 22, color: trailingColor),
        ],
      ),
    ),
  );
}

/// The way to the mini games: push-ups, squats and jumps in front of the
/// camera, and two players on one phone. Quieter than the main keys, and
/// half the row: the Level Builder has the other half.
class HomeMiniGamesKey extends StatelessWidget {
  const HomeMiniGamesKey({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _HalfKey(
    label: context.l10n.homeMiniGamesSemantics,
    colors: HomeKeyColors.lavender,
    onPressed: onPressed,
    title: context.l10n.homeMiniGamesTitle,
    subtitle: context.l10n.homeMiniGamesDetail,
    subtitleColor: const Color(0xff4f4386),
    // Three workouts overlapping like a hand of stickers.
    art: SizedBox(
      width: 66,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, control) in const [
            FlyControl.pushUp,
            FlyControl.squat,
            FlyControl.jump,
          ].indexed)
            Positioned(
              left: i * 18.0,
              top: i.isOdd ? 0 : 12,
              child: ControlGlyph(control, size: 30),
            ),
        ],
      ),
    ),
  );
}

/// The way to the Level Builder: make levels of your own for Tap & Fly and
/// the camera workouts, fly them and share them as codes.
///
/// It stays locked for a new player's first flights: while [flightsLeft] is
/// above 0 the key is greyed and padlocked, says how many flights are left,
/// and a press plays the shop's "not yet" cue without calling [onPressed].
class HomeLevelBuilderKey extends StatelessWidget {
  const HomeLevelBuilderKey({
    super.key,
    required this.onPressed,
    this.flightsLeft = 0,
  });
  final VoidCallback onPressed;
  final int flightsLeft;

  static const _lockedInk = Color(0xff52666c);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (flightsLeft <= 0) {
      return _HalfKey(
        label: l.homeBuilderSemantics,
        colors: HomeKeyColors.blueprint,
        onPressed: onPressed,
        title: l.homeBuilderTitle,
        subtitle: l.homeBuilderDetail,
        subtitleColor: const Color(0xff245a77),
        art: const LevelBuilderGlyph(size: 46),
      );
    }
    return _HalfKey(
      label: l.homeBuilderLockedSemantics(flightsLeft),
      colors: HomeKeyColors.locked,
      cue: ShopCues.denied,
      onPressed: () {},
      title: l.homeBuilderTitle,
      subtitle: l.homeBuilderLocked(flightsLeft),
      subtitleColor: _lockedInk,
      art: const Opacity(opacity: .5, child: LevelBuilderGlyph(size: 46)),
      trailing: Icons.lock_rounded,
      trailingColor: _lockedInk,
    );
  }
}

/// The Level Builder's sticker: a gate and a chequered finish flag drawn on
/// a scrap of blueprint, with a pencil laid across the corner.
class LevelBuilderGlyph extends StatelessWidget {
  const LevelBuilderGlyph({super.key, this.size = 46});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _BlueprintPainter());
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  static final _ink = Paint()
    ..color = SkyColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32);
    // A blueprint card, tilted like a sticker on the key.
    canvas.save();
    canvas.translate(16, 16);
    canvas.rotate(-.08);
    canvas.translate(-16, -16);
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2, 3, 27, 25),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      card.shift(const Offset(0, 1.6)),
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    );
    canvas.drawRRect(card, Paint()..color = const Color(0xff3e8fc2));
    canvas.save();
    canvas.clipRRect(card);
    final grid = Paint()
      ..color = SkyColors.white.withValues(alpha: .28)
      ..strokeWidth = .6;
    for (var x = 5.0; x < 30; x += 4) {
      canvas.drawLine(Offset(x, 3), Offset(x, 28), grid);
    }
    for (var y = 6.0; y < 28; y += 4) {
      canvas.drawLine(Offset(2, y), Offset(29, y), grid);
    }
    canvas.restore();
    // The gate: two cream pillars with an opening between them.
    final pillar = Paint()..color = SkyColors.mint;
    for (final r in const [
      Rect.fromLTWH(7, 3, 5, 8.5),
      Rect.fromLTWH(7, 19.5, 5, 8.5),
    ]) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(1.4));
      canvas.drawRRect(rr, pillar);
      canvas.drawRRect(rr, _ink);
    }
    // A star in the opening.
    StarArt.mini(canvas, const Offset(9.5, 15.5), 2.9, outline: .8);
    // The finish flag on its pole.
    canvas.drawLine(const Offset(21, 25), const Offset(21, 7.5), _ink);
    final flag = Rect.fromLTWH(21, 7.5, 7, 5.6);
    canvas.drawRect(flag, Paint()..color = SkyColors.cream);
    final check = Paint()..color = SkyColors.ink;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 2; j++) {
        if ((i + j).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(21 + i * 7 / 3, 7.5 + j * 2.8, 7 / 3, 2.8),
            check,
          );
        }
      }
    }
    canvas.drawRect(flag, _ink);
    canvas.drawRRect(card, _ink..strokeWidth = 1.8);
    _ink.strokeWidth = 1.6;
    canvas.restore();
    // A yellow pencil across the bottom corner.
    canvas.save();
    canvas.translate(22.5, 25.5);
    canvas.rotate(-.75);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-7, -2.2, 11, 4.4),
      const Radius.circular(1),
    );
    canvas.drawRRect(body, Paint()..color = SkyColors.yellow);
    final tip = Path()
      ..moveTo(4, -2.2)
      ..lineTo(8, 0)
      ..lineTo(4, 2.2)
      ..close();
    canvas.drawPath(tip, Paint()..color = SkyColors.sand);
    canvas.drawCircle(const Offset(7.2, 0), .9, Paint()..color = SkyColors.ink);
    canvas.drawRect(
      const Rect.fromLTWH(-8.6, -2.2, 2, 4.4),
      Paint()..color = SkyColors.coral,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8.6, -2.2, 12.6, 4.4),
        const Radius.circular(1),
      ),
      _ink,
    );
    canvas.drawPath(tip, _ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BlueprintPainter oldDelegate) => false;
}

/// The best endless flight as a small tag, or an invitation before the
/// first.
class _BestTag extends StatelessWidget {
  const _BestTag({required this.best});
  final int best;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.fromLTRB(5, 0, 8, 0),
    decoration: BoxDecoration(
      color: SkyColors.cream,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .18),
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CustomPaint(size: Size(15, 15), painter: _StarPainter()),
        const SizedBox(width: 3),
        if (best > 0)
          Text.rich(
            TextSpan(
              text: '${context.l10n.homeBest} ',
              style: bodyText(
                12,
                color: SkyColors.muted,
                weight: FontWeight.w900,
              ),
              children: [
                TextSpan(
                  text: '$best',
                  style: heading(14.5, weight: FontWeight.w700),
                ),
              ],
            ),
            style: const TextStyle(height: 1),
          )
        else
          Text(
            context.l10n.homeBestNone,
            style: bodyText(
              12,
              color: SkyColors.muted,
              weight: FontWeight.w900,
            ).copyWith(height: 1),
          ),
      ],
    ),
  );
}

/// The stars earned in the campaign so far, as a small tag: the map screen's
/// pill in miniature, gold once every star is in.
class _StarTag extends StatelessWidget {
  const _StarTag({required this.stars, required this.of, required this.done});
  final int stars, of;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.fromLTRB(5, 0, 8, 0),
    decoration: BoxDecoration(
      color: done ? SkyColors.yellow : SkyColors.cream,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: SkyColors.ink, width: 2),
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .18),
          offset: const Offset(0, 2),
        ),
      ],
    ),
    // A longer total shrinks to fit the key's width rather than spill.
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomPaint(size: Size(15, 15), painter: _StarPainter()),
          const SizedBox(width: 3),
          Text.rich(
            TextSpan(
              text: '$stars',
              style: heading(14.5, weight: FontWeight.w700),
              children: [
                TextSpan(
                  text: ' / $of',
                  style: bodyText(
                    12,
                    color: SkyColors.muted,
                    weight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            style: const TextStyle(height: 1),
          ),
        ],
      ),
    ),
  );
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) => StarArt.mini(
    canvas,
    size.center(Offset.zero),
    size.shortestSide * .5,
    outline: 1.2,
  );

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}

/// A little folded map with a dotted mail route to a pin. The pin hops now
/// and then, and stays put when [still].
class _MapPainter extends CustomPainter {
  _MapPainter(this.clock, this.still) : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool still;

  // Drawn on a 60 × 36 grid and scaled to the box.
  static const _grid = Size(60, 36);
  static const _top = [3.0, 0.0, 3.0, 0.0], _bottom = [36.0, 33.0, 36.0, 33.0];
  static const _paper = [
    Color(0xfffff3d6),
    Color(0xffeedcb4),
    Color(0xfffff3d6),
  ];
  static const _tip = Offset(47, 20);
  static const _hopEvery = 3.6, _hopFor = .7;

  static final Path _route = Path()
    ..moveTo(8, 28)
    ..cubicTo(14, 17, 21, 34, 29, 25)
    ..cubicTo(35, 18, 39, 24, _tip.dx - 1, _tip.dy - 1);

  static final List<Path> _panels = [
    for (var i = 0; i < 3; i++)
      Path()
        ..moveTo(20.0 * i, _top[i])
        ..lineTo(20.0 * (i + 1), _top[i + 1])
        ..lineTo(20.0 * (i + 1), _bottom[i + 1])
        ..lineTo(20.0 * i, _bottom[i])
        ..close(),
  ];

  static final Path _silhouette = _panels.reduce(
    (a, b) => Path.combine(PathOperation.union, a, b),
  );

  static final List<Offset> _dots = () {
    final dots = <Offset>[];
    for (final metric in _route.computeMetrics()) {
      for (var d = 0.0; d < metric.length - 2; d += 4.8) {
        dots.add(metric.getTangentForOffset(d)!.position);
      }
    }
    return dots;
  }();

  static Paint _line(double width) => Paint()
    ..color = SkyColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(
      math.min(size.width / _grid.width, size.height / _grid.height),
    );
    canvas.rotate(-.06);
    canvas.translate(-_grid.width / 2, -_grid.height / 2);

    canvas.drawPath(
      _silhouette.shift(const Offset(0, 2)),
      Paint()..color = SkyColors.ink.withValues(alpha: .16),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawPath(_panels[i], Paint()..color = _paper[i]);
    }
    // Land and water on the paper, cut off at the map's edge.
    canvas.save();
    canvas.clipPath(_silhouette);
    canvas.drawOval(
      const Rect.fromLTRB(-3, 12, 13, 26),
      Paint()..color = SkyColors.mint,
    );
    canvas.drawOval(
      const Rect.fromLTRB(22, 3, 36, 12),
      Paint()..color = SkyColors.sky,
    );
    canvas.drawOval(
      const Rect.fromLTRB(41, 22, 63, 38),
      Paint()..color = SkyColors.mint,
    );
    canvas.restore();
    for (final panel in _panels) {
      canvas.drawPath(panel, _line(1.8));
    }

    final route = Paint()..color = SkyColors.coralDeep;
    for (final dot in _dots) {
      canvas.drawCircle(dot, 1.45, route);
    }
    // Where the courier starts.
    canvas.drawCircle(_dots.first, 3, Paint()..color = SkyColors.cream);
    canvas.drawCircle(_dots.first, 3, _line(1.5));

    final t = still ? 0.0 : clock.value % _hopEvery;
    final hop = t < _hopFor ? math.sin(t / _hopFor * math.pi) * 3.2 : 0.0;
    _pin(canvas, _tip, hop);
    canvas.restore();
  }

  void _pin(Canvas canvas, Offset tip, double lift) {
    canvas.drawOval(
      Rect.fromCenter(center: tip, width: 8 - lift, height: 2.4),
      Paint()..color = SkyColors.ink.withValues(alpha: .25),
    );
    final at = tip.translate(0, -lift);
    final head = at.translate(0, -9.4);
    const r = 5.6;
    final drop = Path()
      ..moveTo(at.dx, at.dy)
      ..cubicTo(
        at.dx - 2.6,
        at.dy - 3.6,
        at.dx - r,
        head.dy + 3.2,
        at.dx - r,
        head.dy,
      )
      ..arcToPoint(Offset(at.dx + r, head.dy), radius: const Radius.circular(r))
      ..cubicTo(
        at.dx + r,
        head.dy + 3.2,
        at.dx + 2.6,
        at.dy - 3.6,
        at.dx,
        at.dy,
      )
      ..close();
    canvas.drawPath(drop, Paint()..color = SkyColors.coral);
    canvas.drawPath(drop, _line(1.7));
    canvas.drawCircle(head, 2.3, Paint()..color = SkyColors.cream);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => oldDelegate.still != still;
}

/// A soft diagonal band of light that crosses the key once per cycle.
class _GlintPainter extends CustomPainter {
  _GlintPainter(this.loop) : super(repaint: loop);
  final Animation<double> loop;

  static final Paint _band = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final u = (loop.value - .45) / .18;
    if (u <= 0 || u >= 1) return;
    final x = -70 + (size.width + 140) * Curves.easeInOut.transform(u);
    final fade = math.sin(u * math.pi);
    canvas.save();
    canvas.translate(x, 0);
    canvas.transform(Matrix4.skewX(-.5).storage);
    canvas.drawRect(
      Rect.fromLTWH(-12, 0, 24, size.height),
      _band..color = SkyColors.white.withValues(alpha: .55 * fade),
    );
    canvas.drawRect(
      Rect.fromLTWH(18, 0, 8, size.height),
      _band..color = SkyColors.white.withValues(alpha: .4 * fade),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlintPainter oldDelegate) => false;
}

class _PlayArrowPainter extends CustomPainter {
  const _PlayArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final triangle = Path()
      ..moveTo(5, 3)
      ..quadraticBezierTo(2, 1, 2, 5)
      ..lineTo(2, size.height - 5)
      ..quadraticBezierTo(2, size.height - 1, 5, size.height - 3)
      ..lineTo(size.width - 3, size.height / 2 + 2)
      ..quadraticBezierTo(
        size.width,
        size.height / 2,
        size.width - 3,
        size.height / 2 - 2,
      )
      ..close();
    canvas.drawPath(
      triangle.shift(const Offset(0, 2)),
      Paint()..color = SkyColors.gold,
    );
    canvas.drawPath(triangle, Paint()..color = SkyColors.cream);
    canvas.drawPath(
      triangle,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PlayArrowPainter oldDelegate) => false;
}
