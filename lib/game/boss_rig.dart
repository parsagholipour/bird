import 'package:flutter/painting.dart';
import '../domain/sky_boss.dart';
import 'baron_bat_art.dart';
import 'baron_storm_art.dart';
import 'baron_storm_pose.dart';
import 'boss_motion.dart';

/// Baron Bat: the crowned, caped elder of the purple bat family.
///
/// Authored layers pivot independently; coordinates use the combat hit radius
/// (the body oval spans x ±.91, y -.81..89). The rig is symmetric and looks
/// left toward the bird. Every pose stays inside the encounter layer
/// (x ±3, y -2.3..1.7).
abstract final class BossRig {
  static const ink = Color(0xff18182f), plum = Color(0xff514278);
  static const violet = Color(0xffaa89d3), gold = Color(0xffffd878);
  static const cream = Color(0xfffff2c9), ember = Color(0xffff775c);
  static Paint fill(Color color) => Paint()..color = color;
  static Paint line(Color color, [double width = .045]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint gradient(Rect rect, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);

  // Right-wing rig in body coordinates (the shoulder and hip roots are
  // BaronBatArt.root and .hip): the wrist, the tip and three trailing finger
  // tips of each key pose.
  static const _spread = [
    Offset(1.42, -1.0),
    Offset(2.42, -.8),
    Offset(2.3, -.08),
    Offset(1.74, .4),
    Offset(1.14, .62),
  ];
  static const _raised = [
    Offset(1.26, -1.28),
    Offset(1.98, -1.74),
    Offset(2.34, -1.18),
    Offset(2.1, -.52),
    Offset(1.46, .02),
  ];
  static const _down = [
    Offset(1.5, -.64),
    Offset(2.34, -.08),
    Offset(2.0, .6),
    Offset(1.48, .88),
    Offset(.98, .8),
  ];
  // Folded into a tall cloak: the wrist tucks by the ear, fingers run down.
  static const _folded = [
    Offset(1.02, -.98),
    Offset(.96, -1.5),
    Offset(1.16, -.62),
    Offset(1.14, .08),
    Offset(.92, .6),
  ];

  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion motion, {
    double lookY = 0,
    bool adorned = true,
    BaronStormPose? storm,
  }) {
    final look = lookY.isFinite ? lookY.clamp(-1.0, 1.0) : 0.0;
    final fury = boss.enraged && !motion.defeated;
    final flash = motion.hit * (motion.reducedMotion ? .42 : .56);
    if (flash > .01) {
      // One bounded layer blows the fills out toward white for a crisp hit
      // flash while ink outlines stay dark, so the silhouette never ghosts.
      c.saveLayer(
        const Rect.fromLTWH(-3, -2.3, 6, 4),
        Paint()..colorFilter = _flash(flash),
      );
    }
    final wing = _wingPose(motion);
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.scale(side, 1);
      BaronBatArt.wing(c, wing, fury, adorned: adorned, storm: storm);
      c.restore();
    }
    if (storm != null) {
      // The upgraded Baron: a storm-torn cape and great sonar ears.
      if (adorned) BaronStormArt.cape(c);
      BaronStormArt.ears(c, storm, fury: fury);
    } else {
      if (adorned) BaronBatArt.cape(c);
      BaronBatArt.ears(c, motion, fury);
    }
    BaronBatArt.feet(c);
    BaronBatArt.torso(c, adorned);
    if (adorned) BaronBatArt.breastplate(c, boss, motion, fury, storm);
    BaronBatArt.face(c, boss, motion, look, fury, storm);
    if (adorned && motion.death < .3) {
      c.save();
      c.translate(0, -motion.crownLift);
      c.rotate(-motion.rotation * .55);
      if (storm != null) {
        BaronStormArt.crown(c, glow: storm.glow, fury: fury);
      } else {
        crown(c);
      }
      c.restore();
    }
    if (flash > .01) c.restore();
  }

  static ColorFilter _flash(double w) {
    const k = 2.6, b = -60.0;
    final keep = 1 - w;
    return ColorFilter.matrix([
      keep + w * .3 * k, w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, keep + w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, w * .59 * k, keep + w * .11 * k, 0, w * b, //
      0, 0, 0, 1, 0,
    ]);
  }

  static List<Offset> _wingPose(BossMotion motion) {
    final s = motion.wingStroke;
    // A parabola through raised (-1), spread (0) and down (1) keeps every
    // point's path smooth through the spread pose.
    return [
      for (var i = 0; i < 5; i++)
        Offset.lerp(
          _spread[i] +
              (_down[i] - _raised[i]) * (s / 2) +
              ((_down[i] + _raised[i]) / 2 - _spread[i]) * (s * s),
          _folded[i],
          motion.folded.clamp(0.0, 1.0),
        )!,
    ];
  }

  /// The crown in body coordinates, seated on the head with a jaunty tilt.
  /// It is also drawn on its own when it is knocked off in the defeat and
  /// as the campaign keepsake.
  static void crown(Canvas c) => BaronBatArt.crown(c);
}
