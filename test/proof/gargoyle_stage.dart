// Staging for the Searchlight Gargoyle studies and reviews: composites the REAL
// rig, beams, warning, feathers and the real (placeholder-skinned) health bar
// over New York's real night backdrop at phone size. Test support only: the
// game's own staging is G8's (boss_encounter_art.dart).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart'
    show FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/gargoyle_beam_art.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_feather_art.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/regions/world_backdrop.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

const birdX = GargoyleLayout.birdColumn;
const _night = ui.Color(0xff171c39);

/// A Gargoyle at [combat] seconds into the fight (negative: the arrival, -4.6
/// its first frame), as the rules would hold him at [width] x 360: anchored,
/// not flying. [fury] puts him below half health; [side] and [slit] are the
/// latched aim; [hitAgo] and [glanceAgo] seconds ago he was hit / a rock
/// clinked off the lamp.
SkyBoss gBoss(
  double combat, {
  bool fury = false,
  BeamSide side = BeamSide.high,
  bool slit = false,
  double? hitAgo,
  double? glanceAgo,
  double? deadFor,
  double aspect = 640 / 360,
  double? enragedAgo,
}) {
  final b = SkyBoss(number: 6, x: 0, kind: BossKind.searchlightGargoyle, cinematic: true);
  b.x = SearchlightGargoyle.anchorX(birdX, aspect);
  b.y = .5;
  b.age = b.arrivalDuration + combat;
  b.beamSide = side;
  b.slitSweep = slit;
  if (fury) {
    b.hp = b.maxHp ~/ 2 - 10;
    if (enragedAgo != null) b.enragedAt = b.age - enragedAgo;
  }
  if (hitAgo != null) b.lastHitAt = b.age - hitAgo;
  if (glanceAgo != null) b.lastGlanceAt = b.age - glanceAgo;
  if (deadFor != null) b.defeatedAt = b.age - deadFor;
  return b;
}

GargoylePose poseOf(SkyBoss b, {bool reduced = false, GargoyleSkyLight? light, double? gap}) => GargoylePose(
  b,
  BossMotion(b, reducedMotion: reduced),
  light: light ?? const GargoyleSkyLight(dark: .8),
  gap: gap ?? gapFor(b),
);

/// The distance from the lenses to the bird's column at this boss's anchor.
double gapFor(SkyBoss b) => b.x - .299 - birdX;

ui.Offset bossCentre(ui.Size s, SkyBoss b) => ui.Offset(b.x * s.height, b.y * s.height);

ui.Size text(
  ui.Canvas c,
  String s,
  ui.Offset at,
  double size,
  ui.Color col, {
  bool bold = true,
  double maxW = 900,
  bool center = false,
  bool outline = false,
}) {
  TextPainter mk(ui.Paint? fg, ui.Color? color) => TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        color: fg == null ? color : null,
        foreground: fg,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxW);
  final p = mk(null, col);
  final at2 = center ? at - ui.Offset(p.width / 2, 0) : at;
  if (outline) {
    mk(
      ui.Paint()
        ..color = _night.withValues(alpha: .9)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = size * .22
        ..strokeJoin = ui.StrokeJoin.round,
      null,
    ).paint(c, at2);
  }
  p.paint(c, at2);
  return ui.Size(p.width, p.height);
}

class FrameOptions {
  const FrameOptions({
    this.birdY = .5,
    this.reduced = false,
    this.ammo = const [],
    this.rules = false,
    this.hud = true,
    this.label,
    this.seconds = 38,
    this.dim = .22,
    this.regionBeams = true,
    this.rock,
    this.spotted = false,
    this.region = WorldRegion.newYork,
    this.ghostPoses = const [],
  });
  final double birdY;
  final bool reduced, rules, hud, regionBeams, spotted;
  final List<BossAmmo> ammo;
  final String? label;
  final double seconds, dim;
  final ui.Offset? rock;
  final WorldRegion region;

  /// Other moments drawn faintly under the boss (the envelope study).
  final List<SkyBoss> ghostPoses;
}

/// One full frame at [s]: backdrop, night wash, warning and beams, the rig and
/// its ledge, lens flares, feathers, the bird and the health bar.
void paintFrame(ui.Canvas c, ui.Size s, SkyBoss boss, [FrameOptions o = const FrameOptions()]) {
  final h = s.height;
  final pose = poseOf(boss, reduced: o.reduced);
  SkyScenery.paint(
    c,
    s,
    seconds: o.seconds,
    distance: o.seconds * WorldBackdrop.cruise,
    held: o.region,
    reducedMotion: o.reduced,
  );
  c.drawRect(ui.Offset.zero & s, ui.Paint()..color = _night.withValues(alpha: o.dim));
  final centre = bossCentre(s, boss);
  GargoyleBeamArt.under(c, s, pose, centre);
  final u = h * SkyBoss.radius;
  for (final g in o.ghostPoses) {
    c.save();
    c.translate(bossCentre(s, g).dx, bossCentre(s, g).dy);
    c.scale(u);
    c.saveLayer(null, ui.Paint()..color = const ui.Color(0x26ffffff));
    GargoyleBossRig.paintPose(c, poseOf(g, reduced: o.reduced), plinth: false);
    c.restore();
    c.restore();
  }
  c.save();
  c.translate(centre.dx, centre.dy);
  c.scale(u);
  GargoyleBossRig.paintPose(c, pose);
  c.restore();
  GargoyleBeamArt.over(c, s, pose, centre);
  for (final a in o.ammo) {
    GargoyleFeatherArt.paint(c, h, a, seconds: boss.age, reducedMotion: o.reduced, fury: boss.enraged);
  }
  if (o.rock != null) {
    final r = o.rock!;
    c.drawCircle(ui.Offset(r.dx * h, r.dy * h), h * .02, ui.Paint()..color = const ui.Color(0xffffd45b));
    c.drawCircle(
      ui.Offset(r.dx * h, r.dy * h),
      h * .02,
      ui.Paint()
        ..color = GargoylePalette.ink
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }
  // The bird.
  final bw = h * .145;
  c.save();
  c.translate(birdX * h, o.birdY * h);
  BirdPuppet.paint(c, ui.Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256), bird: 0, wing: .3);
  c.restore();
  if (o.spotted) {
    final at = ui.Offset(birdX * h, o.birdY * h);
    c.drawCircle(at, h * .09, ui.Paint()..color = const ui.Color(0xffffffff).withValues(alpha: .35));
    c.drawCircle(
      at,
      h * .09,
      ui.Paint()
        ..color = const ui.Color(0xffffffff)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    text(c, 'SPOTTED!', at + ui.Offset(0, -h * .17), h * .045, const ui.Color(0xffffffff), center: true, outline: true);
  }
  if (o.rules) rulesOverlay(c, s, boss, pose, o);
  if (o.hud) BossHealthBarArt.paint(c, s, boss, reducedMotion: o.reduced);
  if (o.label != null) text(c, o.label!, ui.Offset(8, h - 20), 11, const ui.Color(0xffffffff), outline: true);
}

/// The bird column strip: red where the bird's CENTRE is hurt right now (the
/// rules' band grown by the bird's radius), green where it is safe, plus the
/// boss hit circle.
void rulesOverlay(ui.Canvas c, ui.Size s, SkyBoss boss, GargoylePose pose, FrameOptions o) {
  final h = s.height;
  final col = birdX * h;
  c.drawRect(ui.Rect.fromLTWH(col - 5, 0, 10, h), ui.Paint()..color = const ui.Color(0xff35d07f).withValues(alpha: .55));
  for (final b in pose.beams) {
    final a = math.max(0.0, b.centre - b.half - GargoyleLayout.birdRadius) * h;
    final z = math.min(1.0, b.centre + b.half + GargoyleLayout.birdRadius) * h;
    c.drawRect(ui.Rect.fromLTRB(col - 5, a, col + 5, z), ui.Paint()..color = const ui.Color(0xffff3b4a).withValues(alpha: .8));
  }
  c.drawCircle(
    ui.Offset(col, o.birdY * h),
    GargoyleLayout.birdRadius * h,
    ui.Paint()
      ..color = const ui.Color(0xffffffff)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.4,
  );
  final b = bossCentre(s, boss);
  c.drawCircle(
    b,
    SkyBoss.radius * h,
    ui.Paint()
      ..color = const ui.Color(0xffff3b6b)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.4,
  );
}
