import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/campaign.dart';
import '../domain/campaign_progress.dart';
import '../game/regions/world_region.dart';
import 'campaign_keepsake_art.dart';
import 'campaign_map_art.dart';
import 'campaign_region_still.dart';
import 'delivery_art.dart';
import 'match_hud.dart' show MatchIcon, MatchSymbol;
import 'stage_key.dart';
import 'theme.dart';

/// The card that opens over the map when a level is tapped: the level's
/// number and name, its region, what the courier is delivering there (on a
/// parcel tag tied over the region's picture), how long the flight is, the NEW
/// hint of a level that brings something new (or, with no hint to give, the
/// controls it offers), its three star goals with those already earned
/// ticked, and the most stars collected so far. Fly starts the level; the
/// close key returns to the map, and a level with a story scene has a story
/// key under it. A boss level wears its boss's stamp colour.
///
/// The map's own ribbon already names the chapter above the card, so the card
/// leaves that out.
///
/// It is composed at [size] and scales as one piece to fit its box, like the
/// postcard, so it reads the same on every phone.
class LevelIntroCard extends StatelessWidget {
  const LevelIntroCard({
    super.key,
    required this.level,
    required this.record,
    required this.onFly,
    required this.onClose,
    this.onStory,
  });
  final CampaignLevel level;

  /// The level's saved bests; an empty record before its first flight.
  final LevelRecord record;
  final VoidCallback onFly, onClose;

  /// Replays the level's story scene; the card shows its story key only
  /// when this is set.
  final VoidCallback? onStory;

  static const size = Size(620, 326);

  /// The Fly key hangs this far below the card, on a key this tall.
  static const _hang = 26.0, _keyHeight = 74.0;

  /// The goal for each star, from one to three.
  static List<String> goals(CampaignLevel level) => [
    level.isBoss
        ? 'Beat ${CampaignHeadwear.name(level.boss!)}'
        : 'Reach the finish',
    'Collect ${level.marks.two} stars',
    'Collect ${level.marks.three} stars',
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Level ${level.id}, ${level.name}. ${level.region.title}.',
      child: AspectRatio(
        aspectRatio: size.width / size.height,
        child: FittedBox(
          child: MediaQuery.withNoTextScaling(
            child: SizedBox.fromSize(
              size: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 10,
                    right: 10,
                    bottom: _hang,
                    child: _Card(
                      level: level,
                      record: record,
                      story: onStory != null,
                    ),
                  ),
                  // The Fly key hangs off the card's lower edge, like the
                  // postcard's Continue.
                  Positioned(
                    right: 34,
                    bottom: 0,
                    width: 204,
                    child: StageKey(
                      key: const ValueKey('level-intro-fly'),
                      label: 'Fly!',
                      icon: Icons.play_arrow_rounded,
                      hero: true,
                      height: _keyHeight,
                      onPressed: onFly,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _CloseKey(onPressed: onClose),
                  ),
                  // The story key hangs under the close key, a size smaller.
                  if (onStory != null)
                    Positioned(
                      right: (_CloseKey.size - _StoryKey.target) / 2,
                      top: _CloseKey.size + 1,
                      child: _StoryKey(onPressed: onStory!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.level, required this.record, required this.story});
  final CampaignLevel level;
  final LevelRecord record;

  /// Whether the story key sits over the card's edge.
  final bool story;

  static const _padding = 12.0;

  @override
  Widget build(BuildContext context) {
    final boss = level.boss;
    return DecoratedBox(
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
      child: Stack(
        children: [
          // A boss card is framed twice, like a stamp, in the boss's colour.
          if (boss != null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: CampaignHeadwear.field(boss).withValues(alpha: .5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(_padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 176, child: _Picture(level: level)),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: 6),
                    child: _Details(level: level, record: record, story: story),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The level's region as a framed still, with the region's name across its
/// foot and the level's cargo on a tag tied across its top. A boss level's
/// frame is edged in the boss's colour.
class _Picture extends StatelessWidget {
  const _Picture({required this.level});
  final CampaignLevel level;

  @override
  Widget build(BuildContext context) {
    final boss = level.boss;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SkyColors.ink, width: 2.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: boss == null
                      ? null
                      : Border.all(
                          color: CampaignHeadwear.field(boss),
                          width: 5,
                        ),
                ),
                child: CampaignRegionView(
                  region: level.region,
                  frameSize: const Size(800, 360),
                  crop: _crop(level.region),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 14,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _Lettering(level.region.title, size: 22),
            ),
          ),
        ),
        Positioned(
          left: _CargoTag.at.dx,
          top: _CargoTag.at.dy,
          child: _CargoTag(level),
        ),
        // The tag's string runs up over the card's top edge.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: DeliveryTwinePainter(
                from: _CargoTag.eyelet,
                to: Offset(_CargoTag.eyelet.dx + 15, -_Card._padding),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Slides a narrow window of the region toward its landmark.
  static double _crop(WorldRegion region) => switch (region) {
    WorldRegion.aztec || WorldRegion.egypt || WorldRegion.rome => .1,
    WorldRegion.newYork || WorldRegion.paris => .15,
    _ => 0,
  };
}

/// What the courier carries on this level: a parcel tag with SPECIAL DELIVERY
/// printed on it and the cargo written in by hand. A boss's tag is printed in
/// the boss's colour.
class _CargoTag extends StatelessWidget {
  const _CargoTag(this.level);
  final CampaignLevel level;

  static const size = Size(176, 54);

  /// Where the tag lies on the picture, a little over its corner, and how
  /// far it is turned.
  static const at = Offset(-6, 9), angle = -.04;

  /// The eyelet's place on the picture, once the tag is turned.
  static Offset get eyelet {
    final middle = size.center(at);
    final d = DeliveryTagPainter.hole(size) + at - middle;
    return middle +
        Offset(
          d.dx * math.cos(angle) - d.dy * math.sin(angle),
          d.dx * math.sin(angle) + d.dy * math.cos(angle),
        );
  }

  @override
  Widget build(BuildContext context) {
    final boss = level.boss;
    final print = boss == null
        ? SkyColors.coralDeep
        : DeliveryArt.bossInk(boss);
    return Semantics(
      label: 'Special delivery: ${level.delivery.cargo}.',
      excludeSemantics: true,
      child: Transform.rotate(
        angle: angle,
        child: SizedBox.fromSize(
          key: const ValueKey('level-intro-tag'),
          size: size,
          child: CustomPaint(
            painter: DeliveryTagPainter(
              eyelet: boss == null
                  ? SkyColors.coral
                  : CampaignHeadwear.field(boss),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(27, 0, 8, 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPECIAL DELIVERY',
                    style: bodyText(
                      8.5,
                      color: print,
                      weight: FontWeight.w900,
                    ).copyWith(letterSpacing: 1.3, height: 1.1),
                  ),
                  const SizedBox(height: 1),
                  DeliveryScript(
                    level.delivery.cargo,
                    textKey: const ValueKey('level-intro-cargo'),
                    maxLines: 2,
                    style: DeliveryArt.hand(14).copyWith(height: 1.1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The level's number on its map coin, ticked once finished. A boss level's
/// coin wears the boss's crown instead of a number.
class _Coin extends StatelessWidget {
  const _Coin({required this.level, required this.cleared, this.halo = false});
  final CampaignLevel level;
  final bool cleared;

  /// A cream ring round the coin, to set it off a coloured band.
  final bool halo;

  static const radius = 27.0;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: radius * 2 + 6,
      height: radius * 2 + MapNodePainter.depth + 4,
      child: CustomPaint(
        painter: halo ? const _HaloPainter(radius) : null,
        child: CustomPaint(
          painter: MapNodePainter(
            look: cleared
                ? MapNodeLook.cleared
                : level.isBoss
                ? MapNodeLook.open
                : MapNodeLook.current,
            radius: radius,
            boss: level.boss,
          ),
          child: level.isBoss
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: MapNodePainter.depth),
                  child: Center(
                    child: Text(
                      level.id,
                      style: heading(
                        19,
                        weight: FontWeight.w700,
                      ).copyWith(height: 1),
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
}

/// A cream stadium shape behind a coin and its base, a little bigger than
/// both.
class _HaloPainter extends CustomPainter {
  const _HaloPainter(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero).translate(0, -MapNodePainter.depth / 2);
    final r = radius + 3.5;
    canvas.drawRRect(
      RRect.fromLTRBR(
        c.dx - r,
        c.dy - r,
        c.dx + r,
        c.dy + MapNodePainter.depth + r,
        Radius.circular(r),
      ),
      Paint()..color = SkyColors.cream,
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.radius != radius;
}

/// The level's name, how long it is, its hint, its star goals and its best
/// flight. The Fly key overlaps the card's lower right, so the goals stop
/// above it and the best flight sits to its left.
class _Details extends StatelessWidget {
  const _Details({
    required this.level,
    required this.record,
    required this.story,
  });
  final CampaignLevel level;
  final LevelRecord record;
  final bool story;

  /// The height of the best-flight row, and the clear space kept between the
  /// goals and the top of the Fly key.
  static const _bestRow = 36.0, _keyGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final goals = LevelIntroCard.goals(level);
    final next = record.bestStars < 3 ? record.bestStars : -1;
    final length = level.isBoss
        ? 'A ${level.length.round()} s run-up first'
        : 'About ${level.length.round()} s to the finish';
    // The close key sits over the card's corner, so the header stops short.
    const keyRoom = 34.0;
    return Stack(
      children: [
        Positioned.fill(
          bottom:
              LevelIntroCard._keyHeight -
              LevelIntroCard._hang -
              _Card._padding +
              _keyGap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (level.isBoss)
                Padding(
                  padding: const EdgeInsets.only(right: keyRoom - 4),
                  child: _BossBand(
                    level: level,
                    cleared: record.cleared,
                    length: length,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: keyRoom),
                  child: _Header(
                    level: level,
                    cleared: record.cleared,
                    length: length,
                  ),
                ),
              const Spacer(),
              if (level.hint != null)
                _ClearOfKey(
                  room: story ? _StoryKey.room : 0,
                  child: _Tip(level.hint!, isNew: level.hintIsNew),
                )
              else
                _Controls(level),
              const Spacer(),
              for (final (i, goal) in goals.indexed)
                _Goal(
                  stars: i + 1,
                  text: goal,
                  earned: record.bestStars > i,
                  next: next == i,
                ),
            ],
          ),
        ),
        Positioned(left: 0, bottom: 0, height: _bestRow, child: _Best(record)),
      ],
    );
  }
}

/// The coin, the level's name and how long the flight is.
class _Header extends StatelessWidget {
  const _Header({
    required this.level,
    required this.cleared,
    required this.length,
  });
  final CampaignLevel level;
  final bool cleared;
  final String length;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Coin(level: level, cleared: cleared),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                level.name,
                maxLines: 1,
                style: heading(33, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 3),
            _Pill(icon: Icons.flag_rounded, text: length),
          ],
        ),
      ),
    ],
  );
}

/// A boss level's header: a band in the boss's stamp colour with the crown
/// coin, a BOSS FIGHT tag and the name in cream lettering.
class _BossBand extends StatelessWidget {
  const _BossBand({
    required this.level,
    required this.cleared,
    required this.length,
  });
  final CampaignLevel level;
  final bool cleared;
  final String length;

  @override
  Widget build(BuildContext context) {
    final field = CampaignHeadwear.field(level.boss!);
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: field,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SkyColors.ink, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: SkyColors.ink.withValues(alpha: .28),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _RaysPainter()),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
              child: Row(
                children: [
                  _Coin(level: level, cleared: cleared, halo: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _Tag(
                              'BOSS FIGHT',
                              color: SkyColors.ink,
                              icon: Icons.star_rounded,
                              iconColor: SkyColors.yellow,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                length,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    bodyText(
                                      12.5,
                                      color: SkyColors.cream,
                                      weight: FontWeight.w900,
                                    ).copyWith(
                                      shadows: const [
                                        Shadow(
                                          color: SkyColors.ink,
                                          offset: Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _Lettering(level.name, size: 32, halo: false),
                        ),
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
}

/// Soft rays fanning out behind a boss's coin.
class _RaysPainter extends CustomPainter {
  const _RaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(38, size.height / 2);
    final paint = Paint()..color = SkyColors.white.withValues(alpha: .13);
    const rays = 9;
    for (var i = 0; i < rays; i++) {
      final a = i * math.pi * 2 / rays;
      final half = math.pi / rays / 2;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(
            c.dx + math.cos(a - half) * 400,
            c.dy + math.sin(a - half) * 400,
          )
          ..lineTo(
            c.dx + math.cos(a + half) * 400,
            c.dy + math.sin(a + half) * 400,
          )
          ..close(),
        paint,
      );
    }
    // Lighter along the top edge, darker toward the foot.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          SkyColors.white.withValues(alpha: .16),
          SkyColors.ink.withValues(alpha: .1),
        ]),
    );
  }

  @override
  bool shouldRepaint(_RaysPainter old) => false;
}

/// A small rounded chip with an icon: how long the flight is.
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 2, 11, 2),
    decoration: BoxDecoration(
      color: SkyColors.white.withValues(alpha: .8),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: SkyColors.ink.withValues(alpha: .25),
        width: 1.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: SkyColors.coral),
        const SizedBox(width: 4),
        Text(text, style: bodyText(13.5, weight: FontWeight.w900)),
      ],
    ),
  );
}

/// Keeps a hint clear of the story key, which hangs in over the card's edge
/// above it. A hint of two lines stands tall enough to reach the key, so it
/// is laid out [room] short of the edge, as the header stops short of the
/// close key; a hint of one line passes under the key at full width.
class _ClearOfKey extends SingleChildRenderObjectWidget {
  const _ClearOfKey({required this.room, required Widget super.child});
  final double room;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderClearOfKey(room);

  @override
  void updateRenderObject(BuildContext context, _RenderClearOfKey box) =>
      box.room = room;
}

class _RenderClearOfKey extends RenderProxyBox {
  _RenderClearOfKey(this._room);

  double _room;
  set room(double value) {
    if (value == _room) return;
    _room = value;
    markNeedsLayout();
  }

  /// A hint taller than this has wrapped onto a second line.
  static const _oneLine = 42.0;

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints, parentUsesSize: true);
    if (_room > 0 && child.size.height > _oneLine) {
      child.layout(
        constraints.copyWith(maxWidth: constraints.maxWidth - _room),
        parentUsesSize: true,
      );
    }
    size = constraints.constrain(child.size);
  }
}

/// The hint on a level: a note tinted for NEW (a first look at something) or
/// TIP (a reminder).
class _Tip extends StatelessWidget {
  const _Tip(this.text, {required this.isNew});
  final String text;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final edge = isNew ? SkyColors.gold : SkyColors.teal;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xfffff0c4) : const Color(0xffdcf0ea),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: edge.withValues(alpha: .75), width: 1.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNew)
            const _Tag('NEW', icon: Icons.auto_awesome_rounded)
          else
            const _Tag(
              'TIP',
              color: SkyColors.teal,
              icon: Icons.lightbulb_rounded,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: DeliveryArt.balancedWidth(
                    context,
                    text,
                    _style,
                    box.maxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _style,
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

  static final _style = bodyText(
    14.5,
    weight: FontWeight.w800,
  ).copyWith(height: 1.2);
}

/// The best finished flight's stars, beside the Fly key that hangs below.
/// Failed flights set no best.
class _Best extends StatelessWidget {
  const _Best(this.record);
  final LevelRecord record;

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = record.cleared
        ? (
            Icons.emoji_events_rounded,
            SkyColors.yellow,
            'Best: ${record.bestCollected} stars',
          )
        : record.plays > 0
        ? (Icons.local_post_office_rounded, SkyColors.mint, 'Not delivered yet')
        : (Icons.flight_takeoff_rounded, SkyColors.sky, 'First flight');
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: SkyColors.ink, width: 2),
          ),
          child: Icon(icon, size: 17, color: SkyColors.ink),
        ),
        const SizedBox(width: 8),
        Text(text, style: bodyText(14.5, weight: FontWeight.w900)),
      ],
    );
  }
}

/// The controls the level offers, for a level with no hint to give. Shoot
/// and Sprint arrive a few levels in.
class _Controls extends StatelessWidget {
  const _Controls(this.level);
  final CampaignLevel level;

  @override
  Widget build(BuildContext context) {
    final controls = [
      (MatchSymbol.wing, 'Flap'),
      if (level.plan.shoot) (MatchSymbol.shot, 'Shoot'),
      if (level.plan.sprint) (MatchSymbol.sprint, 'Sprint'),
    ];
    return Semantics(
      label: 'Controls: ${controls.map((c) => c.$2).join(', ')}.',
      excludeSemantics: true,
      child: Row(
        children: [
          for (final (i, (symbol, label)) in controls.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(4, 3, 12, 3),
              decoration: BoxDecoration(
                color: SkyColors.white.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: SkyColors.ink.withValues(alpha: .25),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MatchIcon(symbol, size: 24),
                  const SizedBox(width: 5),
                  Text(label, style: bodyText(13.5, weight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One star goal: its stars, what earns them, and a tick once earned. The
/// [next] goal to reach is edged in gold.
class _Goal extends StatelessWidget {
  const _Goal({
    required this.stars,
    required this.text,
    required this.earned,
    required this.next,
  });
  final int stars;
  final String text;
  final bool earned, next;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${const ['One star', 'Two stars', 'Three stars'][stars - 1]}: '
        '$text.${earned ? ' Earned.' : ''}',
    excludeSemantics: true,
    child: Container(
      height: 27,
      margin: EdgeInsets.only(top: stars == 1 ? 0 : 3),
      padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
      decoration: BoxDecoration(
        color: earned ? const Color(0xffd3ecd9) : const Color(0xfff4e9d3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: earned
              ? SkyColors.teal.withValues(alpha: .7)
              : next
              ? SkyColors.gold
              : Colors.transparent,
          width: 1.8,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 17,
            child: CustomPaint(painter: MapStarsPainter(stars)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: bodyText(15, weight: FontWeight.w900)),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: earned ? SkyColors.teal : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: earned
                    ? SkyColors.ink
                    : SkyColors.ink.withValues(alpha: .25),
                width: 1.8,
              ),
            ),
            child: earned
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: SkyColors.cream,
                  )
                : null,
          ),
        ],
      ),
    ),
  );
}

/// A small inked label: NEW, TIP or BOSS FIGHT, with an optional icon.
class _Tag extends StatelessWidget {
  const _Tag(
    this.text, {
    this.color = SkyColors.coral,
    this.icon,
    this.iconColor = SkyColors.cream,
  });
  final String text;
  final Color color;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(icon == null ? 7 : 5, 1, 7, 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: SkyColors.ink, width: 1.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: bodyText(
            11.5,
            color: SkyColors.cream,
            weight: FontWeight.w900,
          ).copyWith(letterSpacing: .8, height: 1.15),
        ),
      ],
    ),
  );
}

/// Lettering with an ink outline and a hard drop shadow, and with a cream
/// halo unless [halo] is off, like the region names on the map, so it reads
/// over any scenery.
class _Lettering extends StatelessWidget {
  const _Lettering(this.text, {required this.size, this.halo = true});
  final String text;
  final double size;
  final bool halo;

  @override
  Widget build(BuildContext context) {
    final style = heading(
      size,
      weight: FontWeight.w700,
    ).copyWith(height: 1, letterSpacing: .5);
    Paint stroke(double width, Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..color = color;
    Text layer(TextStyle s) =>
        Text(text, style: s, maxLines: 1, textAlign: TextAlign.center);
    return ExcludeSemantics(
      child: Stack(
        children: [
          if (halo)
            layer(
              style.copyWith(
                foreground: stroke(
                  size * .26,
                  SkyColors.cream.withValues(alpha: .6),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, size * .1),
            child: layer(
              style.copyWith(foreground: stroke(size * .18, SkyColors.ink)),
            ),
          ),
          layer(style.copyWith(foreground: stroke(size * .18, SkyColors.ink))),
          layer(style.copyWith(color: SkyColors.cream)),
        ],
      ),
    );
  }
}

/// A round cream close key, pinned over the card's corner.
class _CloseKey extends StatelessWidget {
  const _CloseKey({required this.onPressed});
  final VoidCallback onPressed;

  static const size = 50.0;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: SkyColors.ink.withValues(alpha: .25),
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: SkyColors.cream,
      shape: const CircleBorder(
        side: BorderSide(color: SkyColors.ink, width: 2.5),
      ),
      child: IconButton(
        key: const ValueKey('level-intro-close'),
        tooltip: 'Close',
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded, color: SkyColors.ink, size: 26),
        style: IconButton.styleFrom(minimumSize: const Size(size, size)),
      ),
    ),
  );
}

/// The key that replays the level's story scene: a round cream key hung
/// under the close key and a size smaller, so the pair reads as one rail with
/// Close leading. Its face is a speech bubble in sky blue, the only blue on
/// the card.
class _StoryKey extends StatelessWidget {
  const _StoryKey({required this.onPressed});
  final VoidCallback onPressed;

  /// The key's face, and the touch target around it.
  static const face = 44.0, target = 48.0;

  /// How far the key reaches into the card's details, with a little air.
  static const room = 26.0;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: target,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // The key's hard shadow, under its face.
        Positioned(
          top: (target - face) / 2 + 3,
          width: face,
          height: face,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SkyColors.ink.withValues(alpha: .25),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('level-intro-story'),
          tooltip: 'Story',
          onPressed: onPressed,
          icon: const CustomPaint(
            size: Size(26, 24),
            painter: _SpeechPainter(),
          ),
          style: IconButton.styleFrom(
            backgroundColor: SkyColors.cream,
            minimumSize: const Size(face, face),
            fixedSize: const Size(face, face),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
            shape: const CircleBorder(
              side: BorderSide(color: SkyColors.ink, width: 2.5),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A speech bubble with three dots of talk in it.
class _SpeechPainter extends CustomPainter {
  const _SpeechPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromLTRBR(1, 1, w - 1, h * .74, Radius.circular(h * .3));
    final bubble = Path.combine(
      PathOperation.union,
      Path()..addRRect(body),
      // The tail points down to the left, at whoever is talking.
      Path()
        ..moveTo(w * .2, h * .6)
        ..lineTo(w * .16, h - 1)
        ..lineTo(w * .5, h * .7)
        ..close(),
    );
    canvas.drawPath(bubble, Paint()..color = SkyColors.skyDeep);
    // A lighter upper half, like the other keys' gloss.
    canvas.save();
    canvas.clipPath(bubble);
    canvas.drawRect(
      Rect.fromLTRB(0, 0, w, h * .36),
      Paint()..color = SkyColors.white.withValues(alpha: .35),
    );
    canvas.restore();
    canvas.drawPath(
      bubble,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = SkyColors.ink;
    for (final dx in const [-.22, 0.0, .22]) {
      canvas.drawCircle(Offset(w * (.5 + dx), h * .375), 1.7, dot);
    }
  }

  @override
  bool shouldRepaint(_SpeechPainter old) => false;
}

/// What a locked level says when tapped, instead of opening its card: the
/// level that unlocks it, or that its chapter is not in this build yet.
String lockedNudge(CampaignLevel level) {
  if (!Campaign.chapterOf(level).playable) return 'Coming soon';
  final before = Campaign.before(level);
  if (before == null) return 'Coming soon';
  return before.isBoss
      ? 'Beat ${CampaignHeadwear.name(before.boss!)} to unlock'
      : 'Finish ${before.id} to unlock';
}
