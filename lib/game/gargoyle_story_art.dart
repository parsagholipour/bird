import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show StoryMood;
import 'gargoyle_boss_rig.dart';
import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';
import 'gargoyle_pose.dart';
import 'gargoyle_staging_art.dart';

/// The Searchlight Gargoyle as a still portrait for the story screens: the
/// rig's own pose for the mood of the line ([GargoylePose.story]), painted by
/// the rig itself ([GargoyleBossRig.paintPose]: the parts in its z-order, so
/// the portrait can never drift from the fight), plus the two things the
/// story adds to the stage:
///
///  * a pigeon on his crest when he is low (sad, and beaten), the one that
///    nested in him;
///  * after his fall, the weather vane the courier delivered, turning on the
///    mount at the cornice's left end (the fight's mount is empty).
///
/// Kept beside the rig, like the dragon's, so nothing in the story art has to
/// know the parts. The portrait faces left toward the courier; the ledge is
/// the floor line ([GargoyleLayout.ledgeY] below the lamp).
abstract final class GargoyleStoryArt {
  /// The mood's rig pose for [mood], [beaten] after the fall. A beaten boss
  /// who is cheerful (the end of 3-4: he accepts the lamp-keeper's job) keeps
  /// the damage (cracks, no visor, broken glass) and a warm glow.
  static GargoylePose poseOf(
    StoryMood mood, {
    bool beaten = false,
    double talk = 0,
    double blink = 0,
  }) {
    if (beaten && mood == StoryMood.happy) {
      final base = GargoylePose.custom(
        flare: .6,
        brow: .1,
        iris: 1 - blink.clamp(0.0, 1.0),
        gape: talk.clamp(0.0, 1.0) * .55,
        pitch: -.1,
        head: const Offset(0, -.05),
        wing: .5,
        spread: .1,
        lean: .1,
        crack: 1,
        damage: 1,
        shatter: 1,
        lamp: .25,
        visor: 0,
      );
      return base;
    }
    return GargoylePose.story(
      beaten
          ? GargoyleMood.beaten
          : switch (mood) {
              StoryMood.plain => GargoyleMood.plain,
              StoryMood.happy => GargoyleMood.happy,
              StoryMood.surprised => GargoyleMood.surprised,
              StoryMood.angry => GargoyleMood.angry,
              StoryMood.sad => GargoyleMood.sad,
            },
      talk: talk,
      blink: blink,
    );
  }

  /// Paints him at the origin (the chest lamp) in rig units, facing left.
  /// [talk] (0 to 1) opens the beak as the line is written out, [blink] (0 to
  /// 1) irises the lenses.
  static void paint(
    Canvas c,
    StoryMood mood, {
    bool beaten = false,
    double talk = 0,
    double blink = 0,
  }) {
    final pose = poseOf(mood, beaten: beaten, talk: talk, blink: blink);
    GargoyleBossRig.paintPose(c, pose);
    final low = beaten || mood == StoryMood.sad;
    if (low) {
      // The pigeon on the crest (seated, a little puffed against the rain).
      final crest = pose.headPoint(const Offset(-1.2, -3.2));
      GargoyleStagingArt.sitting(c, crest + const Offset(0, -.2), .6, tone: pose.tone, tilt: .1);
    }
    if (beaten) {
      // The delivered weather vane, on the mount's pin.
      c.save();
      c.translate(GargoyleLayout.vaneMount.dx, GargoyleLayout.vaneTop - .2);
      GargoyleStagingArt.vane(c, tone: pose.tone, turn: -.18);
      c.restore();
    }
  }

  /// The stamp's field behind his emblem: an indigo (L about 24, never amber:
  /// King Coo owns the brass `#e0a93a`) so the brass lens and the cream visor
  /// stand out at 22 to 29 px. `CampaignHeadwear.field` should return this
  /// for him (the UI's one-line hunk); it was the placeholder steel-blue
  /// `#6f86a8`, on which a steel visor was a grey wedge.
  static const stampField = Color(0xff2f3a6b);

  /// Below this many logical pixels on its short side the emblem should be
  /// [visor]'s `lensOnly` look (a map shield's 29 x 22 and a route mark's
  /// 22 x 17): `CampaignHeadwear.paint` passes
  /// `lensOnly: box.shortestSide < GargoyleStoryArt.lensOnlyBelow`.
  static const lensOnlyBelow = 34.0;

  /// The brow visor on its own (the headwear he loses), at its seat's origin:
  /// the keepsake's, the map shield's and the route mark's emblem. It is the
  /// searchlight lens he lost the shade of: a big brass octagon with a lit
  /// amber glass, hooded by the visor in pale steel (the lens carries it at
  /// 22 to 29 px). With [lensOnly] (the UI passes it for boxes under
  /// [lensOnlyBelow]) it is the lens alone, filling the whole reach.
  static void visor(Canvas c, [GargoyleTone tone = const GargoyleTone(), bool lensOnly = false]) {
    if (lensOnly) {
      _lens(c, visorReach.center, visorReach.shortestSide * .5, tone, ink: .1);
      return;
    }
    _lens(c, const Offset(.2, .52), .58, tone, ink: .1);
    // The hood in pale steel (the hit flash's bleach, so no new colours),
    // lifted and a little smaller so the lens leads.
    c.save();
    c.translate(-.02, -.12);
    c.scale(.9);
    GargoyleBossRig.visorPaint(c, const GargoyleTone(flash: .8));
    c.restore();
  }

  /// A searchlight lens: a brass octagon of circumradius [r] about [at], ink
  /// ([ink] units wide) around it, a lit amber glass and a white-hot core.
  static void _lens(Canvas c, Offset at, double r, GargoyleTone tone, {required double ink}) {
    final ring = GargoyleKit.octagon(1);
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    c.drawPath(ring, GargoyleKit.fill(tone.lit(GargoylePalette.brass)));
    c.drawPath(ring, GargoyleKit.line(GargoylePalette.ink, ink / r));
    c.drawCircle(Offset.zero, .66, GargoyleKit.fill(tone.lit(GargoylePalette.lampAmber)));
    c.drawCircle(Offset.zero, .66, GargoyleKit.line(GargoylePalette.ink, ink * .7 / r));
    c.drawCircle(const Offset(-.1, -.1), .3, GargoyleKit.fill(tone.lit(GargoylePalette.lampCore)));
    c.restore();
  }

  /// How far the visor reaches around its seat (rig units), measured from the
  /// render: for fitting it into a box.
  static const visorReach = Rect.fromLTRB(-.78, -.34, .88, 1.14);
}
