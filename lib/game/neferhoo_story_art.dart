import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/campaign_story.dart' show CampaignStory, StoryMood;
import 'neferhoo_hud_art.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_pose.dart';
import 'neferhoo_rig.dart';
import 'neferhoo_staging_art.dart';

/// What a story line asks of his body besides its mood (design §5.8): the
/// near wing thrust up like a traffic warden's hand ([halt]), the RETURN TO
/// SENDER stamp on his chest and a fan of letters in his wing ([stamp]), the
/// lost letter held to his chest ([letter]), the spectacles pushed up onto
/// his forehead ([specsUp]).
enum NeferhooGesture { none, halt, stamp, letter, specsUp }

/// Neferhoo on the story stage and as a keepsake.
///
/// The story poses (design §5.8, `mummy_present_story.dart`): one acting
/// pose per mood, built from the rig's own channels and painted by the rig
/// itself ([NeferhooPainter], so the portrait never drifts from the fight):
///  * masked: plain (at attention, chin up, looking down his beak), happy (a
///    courier's flourish), surprised (thrown back, crest fanned, beak open),
///    angry (leaning in, brows slammed, the wing up: HALT!), sad (slumped,
///    crest folded, holding the one letter left in his bag);
///  * beaten (the mask gone: a kindly old hoopoe, cinnamon face, grey brows,
///    round spectacles, the wraps loose as a scarf): plain, happy and sad
///    hold the lost letter (`last-2-6`'s lines 2, 4 and 7), surprised pushes
///    his spectacles up ("I can see!"), angry is an indignant Hmph.
/// The gesture follows the mood (the stage gives a boss only its line's
/// mood): the design's pose sheet, `present-story-poses.png`.
///
/// The golden mask he loses ([mask]): the keepsake stamp's, the map shield's
/// and the route lair's emblem.
abstract final class NeferhooStoryArt {
  /// How the stage fits him (see `StoryBossArt.portrait`): pixels per rig
  /// unit on a 360-high stage, the rig's origin from his place on the floor
  /// line, and everything the art can reach in any story pose, in rig units
  /// (measured from the renders by `neferhoo_story_test`). M1's fix round
  /// made him 40 px a unit (the design's 43), 24 px lower (his feet meet the
  /// floor line, a boss rising from behind the panel) and tucked his
  /// streamers to [storyRibbons]: at 640 and 800 px his raised wing and
  /// streamers ran under the scene's Skip key (745 px² at 640); now a
  /// feather tip at 640 (88 px²), nothing at 800 or 864.
  static const unit = 40.0;
  static const origin = Offset(-30, -90);
  static const reach = Rect.fromLTRB(-3.2, -3.5, 4.4, 2.3);

  /// The most his streamers flow on the stage (the fight's reach 1.35).
  static const storyRibbons = .45;

  /// The rig's level of detail on the stage (40 px per unit: play). The
  /// stage records the portrait at unit scale, so the painter cannot read it
  /// from the canvas.
  static const lod = 2;

  /// His card line, "Return to sender! This route has a courier."
  /// (`before-2-6` line 7, the guardian card's): acted with the stamp and a
  /// fan of letters (design `mummy_story_test`'s `gestureFor`), not the
  /// HALT! of his other angry line.
  static String? get cardLine => CampaignStory.guardianLines['2-6'];

  /// Whether [line] (the line he is acting) asks for a gesture of its own
  /// beyond its mood: his card line, while he still wears the mask.
  static bool actsLine(String? line, {bool beaten = false}) => !beaten && line != null && line == cardLine;

  /// The gesture each mood carries, masked or [beaten] (design); [line], the
  /// line he is acting, overrides it for his card line ([actsLine]).
  static NeferhooGesture gestureOf(StoryMood mood, {required bool beaten, String? line}) => actsLine(line, beaten: beaten)
      ? NeferhooGesture.stamp
      : beaten
      ? switch (mood) {
          StoryMood.surprised => NeferhooGesture.specsUp,
          StoryMood.angry => NeferhooGesture.none,
          _ => NeferhooGesture.letter,
        }
      : switch (mood) {
          StoryMood.angry => NeferhooGesture.halt,
          StoryMood.sad => NeferhooGesture.letter,
          _ => NeferhooGesture.none,
        };

  /// His pose for [mood] ([beaten] after his fall), with the mood's gesture
  /// (or [gesture]); [talk] opens the beak, [blink] shuts the eye. [phase]
  /// only drives the idle sway (a still portrait passes a constant).
  static NeferhooPose poseOf(
    StoryMood mood, {
    bool beaten = false,
    double talk = 0,
    double blink = 0,
    NeferhooGesture? gesture,
    String? line,
    double phase = .4,
  }) {
    final breathe = math.sin(phase * 1.6) * .012;
    final p = beaten ? _beaten(mood, phase) : _masked(mood, phase);
    p.lean += breathe;
    p.beak = math.max(p.beak, talk.clamp(0.0, 1.0) * .34);
    switch (gesture ?? gestureOf(mood, beaten: beaten, line: line)) {
      case NeferhooGesture.none:
        break;
      case NeferhooGesture.stamp:
        // Letters fanned in the wing and the stamp on his chest: RETURN TO
        // SENDER (the design's `StoryGesture.stamp`).
        p.cards = 3;
        p.cardSpread = 1.1;
        p.satchelOpen = 1;
        p.reach = .75;
        p.stamp = 1;
      case NeferhooGesture.halt:
        // The near wing thrust straight up, the head pushed forward: HALT!
        p.wing = -1;
        p.sweep = .78;
        p.lean = -.12;
        p.headTilt = -.09;
        p.satchelOpen = 0;
      case NeferhooGesture.letter:
        p.prop = 'letter';
        p.reach = 1;
        p.satchelOpen = beaten ? 0 : .5;
      case NeferhooGesture.specsUp:
        p.specsUp = 1;
    }
    p.lid = math.max(p.lid, blink.clamp(0.0, 1.0));
    p.ribbons = math.min(p.ribbons, storyRibbons);
    return p;
  }

  /// Paints him in rig units at the origin (the hit circle), facing left.
  static void paint(
    Canvas c,
    StoryMood mood, {
    bool beaten = false,
    double talk = 0,
    double blink = 0,
    String? line,
  }) => NeferhooPainter(c, poseOf(mood, beaten: beaten, talk: talk, blink: blink, line: line), lod: lod).paint();

  static NeferhooPose _masked(StoryMood mood, double phase) => switch (mood) {
    // A courier's flourish: chin up, chest out, one wing waving, the eyes
    // squeezed in pride, a little hop in the feet.
    StoryMood.happy => NeferhooPose(
      crest: .62 + .03 * math.sin(phase * 3),
      wing: -.62 + .1 * math.sin(phase * 3.2),
      lean: .1,
      lid: .38,
      brow: .25,
      headTilt: .1,
      legs: .55 + .12 * math.sin(phase * 2.2),
      ribbons: 1.25,
      phase: phase,
      look: const Offset(-1, -.3),
    ),
    // Thrown back: the crest at full fan, the wings flung wide, the beak
    // open, a jolt.
    StoryMood.surprised => NeferhooPose(
      crest: 1,
      wing: -.35,
      reach: .55,
      lean: .2,
      brow: 1,
      beak: .85,
      hit: .65,
      legs: .9,
      ribbons: 1.35,
      headTilt: -.02,
      phase: phase,
      glow: .15,
      look: const Offset(-.2, -.1),
    ),
    // Leaning in, head down, brows slammed, the crest bristling.
    StoryMood.angry => NeferhooPose(
      crest: .78,
      wing: -.5,
      lean: -.1,
      brow: -1,
      beak: .3,
      glow: .65,
      fury: .4,
      headTilt: -.07,
      legs: .15,
      ribbons: 1.25,
      phase: phase * 1.4,
      look: const Offset(-1, .1),
    ),
    // Slumped and bowed, wings in, the crest folded, heavy lids.
    StoryMood.sad => NeferhooPose(
      crest: .05,
      wing: .95,
      lean: -.1,
      headTilt: -.2,
      sleepy: .6,
      sad: 1,
      brow: .5,
      legs: -.35,
      ribbons: .3,
      phase: phase * .6,
      satchelOpen: .35,
      look: const Offset(-.4, .9),
    ),
    // At attention: chin up, chest out, the satchel shut, looking down his
    // beak at whoever is there.
    StoryMood.plain => NeferhooPose(
      crest: .4 + .02 * math.sin(phase * 2),
      wing: .22 + .08 * math.sin(phase * 1.9),
      lean: .05,
      lid: .16,
      headTilt: .06,
      legs: -.12,
      phase: phase,
      look: const Offset(-1, .15),
    ),
  };

  static NeferhooPose _beaten(StoryMood mood, double phase) {
    final base = NeferhooPose(mask: false, specs: true, unwrap: .6, phase: phase, ribbons: .5, legs: -.2);
    return switch (mood) {
      StoryMood.happy => base.copy(
        crest: .5 + .03 * math.sin(phase * 3),
        wing: -.45 + .1 * math.sin(phase * 3),
        lean: .06,
        smile: 1,
        headTilt: .12,
        brow: .25,
        legs: .55,
        ribbons: 1.0,
        look: const Offset(-.9, -.2),
      ),
      StoryMood.surprised => base.copy(
        crest: 1,
        wing: -.85,
        lean: .13,
        brow: 1,
        beak: .35,
        hit: .35,
        lid: 0,
        sleepy: 0,
        smile: 0,
        headTilt: -.04,
        legs: .7,
        ribbons: 1.1,
        look: const Offset(-.2, -.3),
      ),
      // An indignant old courier: Hmph!
      StoryMood.angry => base.copy(
        crest: .75,
        wing: -.5,
        lean: -.07,
        brow: -1,
        beak: .25,
        smile: 0,
        sleepy: 0,
        headTilt: -.06,
        ribbons: .9,
        look: const Offset(-1, .1),
      ),
      StoryMood.sad => base.copy(
        crest: .05,
        wing: .95,
        lean: -.1,
        headTilt: -.2,
        sleepy: .55,
        sad: 1,
        brow: .5,
        smile: 0,
        ribbons: .3,
        look: const Offset(-.3, .9),
      ),
      StoryMood.plain => base.copy(
        crest: .25 + .02 * math.sin(phase * 2),
        wing: .5 + .05 * math.sin(phase * 1.7),
        lean: .07,
        sleepy: .25,
        smile: .35,
        headTilt: .09,
        look: const Offset(-.9, .2),
      ),
    };
  }

  // ------------------------------------------------------------ the mask --

  /// How far [mask] reaches about its origin (the head's centre), in rig
  /// units, measured from the render (`neferhoo_keepsake_test`): for fitting
  /// it into a box.
  static const maskReach = Rect.fromLTRB(-2.15, -.95, 1.02, 1.02);

  /// Below this many logical pixels on its short side the mask is drawn as
  /// the emblem ([NeferhooHudArt.emblem]: the gold face, the kohl eye and
  /// the long beak in bold shapes) so it still reads at a map shield's
  /// 28 x 21 and a route mark's size; larger, it is the rig's own mask.
  static const emblemBelow = 40.0;

  /// The golden mask he loses, about the head's centre in rig units, filling
  /// [maskReach]: the rig's own (face plate, nemes, brow band, beak, eye),
  /// or with [small] the bold emblem fitted to the same box.
  static void mask(Canvas c, {bool small = false}) {
    if (small) {
      // The emblem without its disc and crest, fitted to the mask's box.
      const e = Rect.fromLTRB(-1.62, -.72, .76, .78);
      final s = math.min(maskReach.width / e.width, maskReach.height / e.height);
      c.save();
      c.translate(maskReach.center.dx, maskReach.center.dy);
      c.scale(s);
      c.translate(-e.center.dx, -e.center.dy);
      NeferhooHudArt.emblem(c, Offset.zero, 1, disc: false, crest: false, detail: false, pixels: _scaleOf(c));
      c.restore();
      return;
    }
    // The painter's own mask is centred on the head's centre already.
    NeferhooPainter(c, NeferhooPose(crest: 0), lod: 2).paintMaskOnly();
  }

  /// The canvas's scale (px per unit), or 1 when it cannot say.
  static double _scaleOf(Canvas c) {
    try {
      final m = c.getTransform();
      final s = math.sqrt(m[0] * m[0] + m[1] * m[1]);
      return s.isFinite && s > 0 ? s : 1;
    } catch (_) {
      return 1;
    }
  }

  /// The keepsake stamp's field and the map shield: lapis (design §5.7), on
  /// which the gold mask reads at 72 and at 24 px.
  static const field = NeferhooStaging.stamp;

  /// The rig's head anchor (the mask's origin), for callers that place it.
  static const head = NeferhooLayout.head;
}
