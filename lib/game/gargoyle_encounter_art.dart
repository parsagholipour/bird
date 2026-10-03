import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_ammo_art.dart';
import 'boss_health_bar_art.dart';
import 'boss_motion.dart';
import 'gargoyle_beam_art.dart';
import 'gargoyle_body_art.dart';
import 'gargoyle_boss_rig.dart';
import 'gargoyle_encounter_ui.dart';
import 'gargoyle_feather_art.dart';
import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';
import 'gargoyle_pose.dart';
import 'gargoyle_staging_art.dart';
import 'regions/world_region.dart';

/// Where the Searchlight Gargoyle stands in the world, and how he arrives,
/// fights and falls: the Gargoyle branches of `BossEncounterArt` (the shared
/// file only dispatches to this).
///
/// **Layers** (the game paints backdrop, obstacles and stars, [paint], the bird,
/// [foreground], then the health bar):
///  * [backdrop], under everything: the storm's wash and rain, the distant
///    lightning, then the warning and the beams (G5: they must stay under the
///    stars, the feathers, the bird and the HUD);
///  * [paint]: the lightning's flash and bolt (behind him: he is darkest then),
///    his tower and himself, then the feathers, his lens flares, and the
///    arrival's, the fight's and the defeat's effects;
///  * [foreground]: the killing blow's white flash (over everything, under the
///    letterbox).
///
/// **Where he is.** The heart is `(boss.x * h, SearchlightGargoyle.anchorY * h)`
/// always (the rules keep y at .5 through the arrival; this pins it anyway),
/// the scale is `h * SkyBoss.radius`, and none of [BossMotion]'s offset,
/// rotation, stretch or body scale touches him: he is bolted to a tower, and
/// the rig is fitted to the screen. His own jolts (a hit, the tipping into
/// fury, the killing blow, the burst) move the rig only and sit under the
/// shared camera's.
///
/// Pure functions of the simulation and the boss clock: nothing here reads a
/// wall clock or a random number, so a replay, a pause and a seek show exactly
/// what the live flight did. A boss whose clock is broken (NaN or infinite
/// time or place) draws nothing.
abstract final class GargoyleEncounterArt {
  static const _night = Color(0xff171c39);

  /// Layer bounds of the defeat's white-out (the only layer an encounter ever
  /// opens): everything the rig can reach.
  static const layerBounds = GargoyleBossRig.bounds;

  static bool _fine(SkyBoss boss, BossMotion m, Size size) =>
      boss.isGargoyle &&
      boss.age.isFinite &&
      boss.x.isFinite &&
      boss.y.isFinite &&
      size.width.isFinite &&
      size.height.isFinite &&
      size.height > 0 &&
      (!m.defeated || m.death.isFinite);

  static double _ramp(double v, double a, double b) => BossMotion.ramp(v, a, b);
  static double _ease(double t) => BossMotion.ease(t);

  // ------------------------------------------------------------- frame --

  /// Where the rig's origin (the chest lamp, the hit circle) is on a screen
  /// [h] high, and how many pixels one rig unit is. Pinned: the rules' x,
  /// the anchor's y, never any of [BossMotion]'s transforms.
  static ({Offset heart, double unit}) frame(BossMotion m, double h) =>
      (heart: Offset(m.boss.x * h, SearchlightGargoyle.anchorY * h), unit: h * SkyBoss.radius);

  /// How much of its own shake he shows: all of it, but only .4 while the
  /// shared camera shakes too (the camera slides and zooms the whole world with
  /// its shake, `BirdGame.shakeZoom`; a local jolt on top would compound it).
  static double underCamera(BossMotion m) => m.shake == Offset.zero ? 1.0 : .4;

  /// His own jolt (px on a screen [h] high): a hit shivers the rig 1.5 px for
  /// .1 s, the tipping into fury 2 px for .25 s, the killing blow 2.5 px for
  /// .12 s (the hit-stop), the burst 3 px at 3.5 Hz dying away. Never under
  /// Reduced Motion.
  static Offset jolt(BossMotion m, double h) {
    if (m.reducedMotion || !h.isFinite) return Offset.zero;
    final boss = m.boss;
    var amp = 0.0;
    if (m.defeated) {
      final d = m.death;
      if (d >= 0 && d < .12) amp = 2.5 * (1 - d / .12);
      final k = d - SkyBoss.burstAt;
      if (k >= 0 && k < 1.0) amp = math.max(amp, 3 * math.exp(-5 * k));
    } else {
      final hit = boss.age - boss.lastHitAt;
      if (boss.lastDamage > 0 && hit >= 0 && hit < .1) amp = 1.5 * (1 - hit / .1);
      final fury = boss.age - boss.enragedAt;
      if (fury >= 0 && fury < .25) amp = math.max(amp, 2 * (1 - fury / .25));
    }
    if (amp <= 0) return Offset.zero;
    final t = boss.age;
    return Offset(math.sin(t * 2 * math.pi * 27) * .6, math.cos(t * 2 * math.pi * 23)) * (amp * h / 360 * underCamera(m));
  }

  /// The backdrop's light on him: the sky of the region the flight holds
  /// (New York, for a campaign level: the sim's `region`) or of the tour.
  static GargoyleSkyLight light(FlightSimulation sim) {
    if (!sim.elapsed.isFinite) return GargoyleSkyLight.neutral;
    final sky = SkyPalette.at(sim.elapsed, held: sim.region);
    return GargoyleSkyLight.fromSky(top: sky.top, horizon: sky.horizon, haze: sky.haze);
  }

  /// The pose he is drawn with (the rig's, the HUD's and the effects'): his
  /// head watches the bird a hair while he perches, the sky lights him.
  static GargoylePose pose(FlightSimulation sim, BossMotion m) {
    final boss = m.boss;
    final look = sim.birdY.isFinite ? ((sim.birdY - GargoylePose.lensY) * 2).clamp(-1.0, 1.0) : 0.0;
    return GargoylePose(
      boss,
      m,
      lookY: m.defeated ? 0 : look,
      light: light(sim),
      gap: boss.x - .29 - GargoyleLayout.birdColumn,
    );
  }

  // --------------------------------------------------------- letterbox --

  /// The letterbox, 0 to 1, as his encounter draws it: the dragon's timing.
  /// In for the arrival's storm, open to 30% for the roar (his crest and the
  /// roar's rings climb to the top edge), closed again for the title card, out
  /// 0.2 s earlier than the others' so the card's exit is never cut by it; after
  /// the killing blow it slides in behind the crumbling statue (0.4 to 1.1 s)
  /// instead of cutting across it.
  static const reducedBars = .65;

  static double focus(BossMotion m) {
    final age = m.boss.age;
    if (!age.isFinite || (m.defeated && !m.death.isFinite)) return 0;
    if (m.arriving) {
      final base = _ease(_ramp(age, 0, .65)) * (1 - _ease(_ramp(age, 3.8, 4.4)));
      // Under Reduced Motion the bars do not open and close for the roar (a
      // still frame); they stand thinner for the whole arrival instead, thin
      // enough to clear his crest at the static roar pose (it stands 21 px
      // below the top edge; the full bars are 29).
      if (m.reducedMotion) return base * reducedBars;
      final open = _ease(_ramp(age, 2.5, 2.75)) * (1 - _ease(_ramp(age, 3.2, 3.6)));
      return base * (1 - .7 * open);
    }
    if (m.defeated) return _ease(_ramp(m.death, .4, 1.1)) * m.focus;
    return m.focus;
  }

  // ---------------------------------------------------------- backdrop --

  /// Under everything: the storm's wash (the shared one's strength, so the
  /// sky stays as dark as the beams were reviewed on), the arrival's rain, the
  /// distant lightning of the fight and the warning and beams.
  static void backdrop(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (!_fine(boss, m, size)) return;
    final storm = m.storm;
    c.drawRect(Offset.zero & size, GargoyleKit.fill(_night, storm * (.22 + focus(m) * .25)));
    _rain(c, size, boss, m);
    _distant(c, size, boss, m);
    GargoyleBeamArt.underBoss(c, size, boss, m);
  }

  /// The storm that brings him to life: a heavy slanting rain that thickens
  /// as the lightning nears and thins again as control returns. One path, one
  /// op; none under Reduced Motion.
  static void _rain(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (m.reducedMotion || !m.arriving) return;
    final age = boss.age;
    final k = _ease(_ramp(age, .2, 1.4)) * (1 - _ease(_ramp(age, 2.4, 4.4)));
    if (k <= .02) return;
    final h = size.height, w = size.width;
    final rain = Path();
    const n = 44;
    for (var i = 0; i < n; i++) {
      final x0 = GargoyleKit.hash(i, 41) * (w + h * .4) - h * .2;
      final fall = (GargoyleKit.hash(i, 43) * 1.3 + age * (1.35 + GargoyleKit.hash(i, 47) * .5)) % 1.3 - .15;
      final y = fall * h;
      final len = h * (.05 + GargoyleKit.hash(i, 49) * .04);
      rain
        ..moveTo(x0 + y * .25, y)
        ..lineTo(x0 + y * .25 - len * .25, y - len);
    }
    c.drawPath(rain, GargoyleKit.line(const Color(0xffbfd0ff), math.max(1.0, h * .0028), .3 * k));
  }

  /// The storm rolling on in the distance during the fight: every other cycle
  /// (a hash of the cycle number) a flicker lights the sky a hair (9% at its
  /// brightest, under everything but the sky itself: the feathers, the beams
  /// and the bird stay as readable) and a pale fork stands for a heartbeat far
  /// over the skyline at the left, well away from the bird's column and from
  /// his beams. One flicker per 9-second cycle at most, in the perch (the
  /// vent, when the lamp is open, is never lit by it). None under Reduced
  /// Motion.
  static void _distant(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (m.reducedMotion || boss.phase != BossPhase.attacking) return;
    final t = boss.age - boss.arrivalDuration;
    if (t < 0) return;
    final k = (t / GargoyleTimeline.period).floor();
    if (GargoyleKit.hash(k, 11) > .55) return;
    final u = t - k * GargoyleTimeline.period - (.95 + GargoyleKit.hash(k, 13) * .5);
    if (u < 0 || u > .6) return;
    // A double flicker: on, off, on again, then the long fade.
    final f = u < .07
        ? 1.0
        : u < .13
        ? .15
        : u < .26
        ? .85
        : 1 - _ramp(u, .26, .6);
    if (f <= 0) return;
    final h = size.height, w = size.width;
    c.drawRect(Offset.zero & size, GargoyleKit.fill(const Color(0xffcfd8ff), .09 * f));
    final top = Offset(w * (.1 + GargoyleKit.hash(k, 17) * .26), -h * .04);
    final path = Path()..moveTo(top.dx, top.dy);
    var p = top;
    for (var i = 1; i <= 6; i++) {
      p = Offset(top.dx + (GargoyleKit.hash(i, 19 + k) - .5) * h * .1 + i * h * .004, h * (.05 + i * .06));
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, GargoyleKit.line(const Color(0xff9fb4ff), h * .014, .2 * f));
    c.drawPath(path, GargoyleKit.line(const Color(0xffeaf0ff), h * .0045, .7 * f));
  }

  // ------------------------------------------------------------- paint --

  /// The first moment of the arrival is spent on one frame's worth of work:
  /// the rig's gradients, the body's paths and the beam's shaders are built
  /// once, off screen, while the storm's caption is up (a first frame of the
  /// body alone costs 46 ms in the debug JIT).
  static Size? _warmed;

  /// Builds every shader, glow, laid-out text and cached path the encounter
  /// needs, once, for a screen of [size] (the name card's and the plate's
  /// gradients are keyed by their layout, which depends on it). Called from
  /// the arrival's first second; calling it again for the same size does
  /// nothing (and it heals itself if the kit's caches were emptied).
  static void prewarm([Size size = const Size(640, 360)]) {
    if (_warmed == size && GargoyleKit.built.isNotEmpty) return;
    _warmed = size;
    GargoyleBodyArt.prewarm();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final h = size.height;
    final x = SearchlightGargoyle.anchorX(GargoyleLayout.birdColumn, size.width / h);
    final lamp = Offset(x * h, SearchlightGargoyle.anchorY * h);
    final bird = Offset(GargoyleLayout.birdColumn * h, h * .5);
    // The rig in the looks that build its gradients (rest, fury and a hit and
    // the lamp open, the beaten one).
    for (final pose in [
      GargoylePose.still,
      GargoylePose.custom(lamp: 1, flare: 1, fury: 1, crack: .6, steam: .5, hit: .5, glance: .5, shatter: .5, grip: .5, roar: 1, gape: .8),
      GargoylePose.story(GargoyleMood.beaten),
    ]) {
      GargoyleBossRig.paintPose(c, pose);
    }
    // The beams, the warning (its dodge tag lays its text out once), SPOTTED!.
    const band = GargoyleBeam(centre: .4, half: .09, far: false, fury: false, intensity: 1);
    GargoyleBeamArt.beam(c, size, band, lamp + const Offset(-130, -100));
    SkyBoss gargoyle(double age) => SkyBoss(number: 6, x: x, kind: BossKind.searchlightGargoyle, cinematic: true)..age = age;
    for (final combat in const [3.0, 4.5]) {
      final b = gargoyle(4.6 + combat);
      final pose = GargoylePose(b, BossMotion(b, reducedMotion: false));
      GargoyleBeamArt.under(c, size, pose, lamp);
      GargoyleBeamArt.over(c, size, pose, lamp);
    }
    for (final cost in GargoyleSpotCost.values) {
      GargoyleBeamArt.spotted(c, size, bird: bird, since: .2, cost: cost, fury: false, reduced: false);
    }
    // The plate in calm and fury, the name card (its lettering and layout).
    for (final fury in const [false, true]) {
      final plated = gargoyle(4.6 + 1.0);
      if (fury) plated.hp = plated.maxHp ~/ 2 - 1;
      BossHealthBarArt.paint(c, size, plated);
    }
    final arriving = gargoyle(3.3);
    GargoyleEncounterUi.nameCard(c, size, arriving, BossMotion(arriving, reducedMotion: false), birdY: .5, line: '“${GargoyleEncounterUi.line}”');
    // His effects (each builds its glows once), his feather, the lamp's blows.
    GargoyleEncounterUi.awaken(c, lamp, h, .3, reduced: false);
    GargoyleEncounterUi.roost(c, lamp, h, 1.5, reduced: false);
    GargoyleEncounterUi.flush(c, lamp, h, 2.3, reduced: false);
    for (final fury in const [false, true]) {
      GargoyleEncounterUi.hit(c, lamp, h, .1, reduced: false, fury: fury);
    }
    GargoyleEncounterUi.furyOnset(c, lamp, h, .2, reduced: false);
    GargoyleEncounterUi.spotRing(c, bird, h, .1, reduced: false);
    for (final d in const [1.0, 1.5, 2.0]) {
      GargoyleEncounterUi.rubble(c, lamp, h, d, reduced: false);
      GargoyleEncounterUi.crumble(c, lamp, h, d, reduced: false);
      GargoyleEncounterUi.lenses(c, lamp, h, d + .5, reduced: false);
      GargoyleEncounterUi.pigeonsOut(c, lamp, h, d, reduced: false);
    }
    GargoyleFeatherArt.glance(c, lamp, h * SkyBoss.radius, .1);
    GargoyleFeatherArt.impact(c, lamp, h * SkyBoss.radius, .1, fury: true);
    GargoyleFeatherArt.dust(c, size, .8, .9);
    BossAmmoArt.shot(
      c,
      h,
      BossAmmo(x: 1.0, y: .3, vx: -.36, vy: .3, gravity: .3, radius: .028, feather: true),
      gargoyle(4.6 + 2.0),
      seconds: 40,
      reducedMotion: false,
    );
    // The staging's own glows: the strike's pin, the hit-stop, the light that
    // gathers in the cracks.
    GargoyleStagingArt.bolt(c, lamp, h, .5);
    for (final color in const [Color(0xffcfe0ff), GargoylePalette.lampCore, GargoylePalette.lampWarm]) {
      GargoyleKit.glow(c, lamp, 10, color, .5);
    }
    rec.endRecording().dispose();
  }

  /// His layer: the arrival's lightning, the tower and the creature, the
  /// feathers and the lens flares, the arrival's, the fight's and the
  /// defeat's effects. See the class comment for the order.
  static void paint(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss;
    if (!_fine(boss, m, size)) return;
    final h = size.height;
    if (m.arriving && boss.age < 1.2) prewarm(size);
    final f = frame(m, h);
    final p = pose(sim, m);
    final lamp = f.heart;
    final reduced = m.reducedMotion;

    // The lightning's flash: behind him, so the stone is darkest against it.
    _flash(c, size, boss, m);
    // The presentation sweep that finds the bird in the roar (never a real beam).
    _tease(c, size, sim, m, p, f);

    // The tower and the creature, and what they take from the blows.
    final body = f.heart + jolt(m, h);
    c.save();
    c.translate(body.dx, body.dy);
    c.scale(f.unit);
    final white = _white(m);
    final fade = _fadeIn(m);
    final layered = white > .01 || fade < 1;
    if (fade > 0) {
      if (layered) {
        c.saveLayer(
          layerBounds,
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, fade)
            ..colorFilter = white > .01 ? _whiten(white) : null,
        );
      }
      GargoyleBossRig.paintPose(c, p);
      if (layered) c.restore();
    }
    c.restore();

    // The arrival: pigeons roost on the stone and are flushed, the stone's
    // cracks and dust, the roar's rings.
    if (m.arriving) {
      _bolt(c, size, boss, m, f);
      GargoyleEncounterUi.roost(c, lamp, h, boss.age, reduced: reduced);
      GargoyleEncounterUi.awaken(c, lamp, h, boss.age - SkyBoss.revealAt, reduced: reduced);
      GargoyleEncounterUi.flush(c, lamp, h, boss.age, reduced: reduced);
      _roar(c, size, boss, m, p, f);
    }

    // His feathers, AFTER the rig (a low bird's feather would hide behind the
    // head otherwise), the dust that announces the next, his lens flares.
    for (final ammo in sim.bossAmmo) {
      BossAmmoArt.shot(c, h, ammo, boss, seconds: sim.elapsed, reducedMotion: reduced);
    }
    if (p.dust > 0 && !m.defeated && sim.birdY.isFinite) {
      GargoyleFeatherArt.dust(c, size, p.dust, GargoyleFeatherArt.entryX(sim.birdY, fury: boss.furyPace, level: boss.levelFeathers), reducedMotion: reduced);
    }
    GargoyleBeamArt.overBoss(c, size, boss, m);

    // The fight's blows on the lamp.
    if (!m.arriving && !m.defeated) {
      if (p.glance > 0) {
        GargoyleFeatherArt.glance(c, lamp, f.unit, p.glance, open: p.lamp, fury: boss.enraged, reducedMotion: reduced);
      }
      if (boss.lastDamage > 0) {
        final since = boss.age - boss.lastHitAt;
        if (since >= 0 && since < .3) GargoyleEncounterUi.hit(c, lamp, h, since, reduced: reduced, fury: boss.enraged);
      }
      GargoyleEncounterUi.furyOnset(c, lamp, h, boss.age - boss.enragedAt, reduced: reduced);
      final spot = boss.age - boss.lastSpotAt;
      if (spot >= 0 && spot < .45 && sim.birdY.isFinite) {
        GargoyleEncounterUi.spotRing(c, Offset(FlightSimulation.birdX * h, sim.birdY * h), h, spot, reduced: reduced);
      }
    }
    if (m.defeated) _defeat(c, size, m, p, f);
  }

  // ----------------------------------------------------------- arrival --

  /// The strike that wakes him: at [SkyBoss.revealAt] (1.65 s, the instant of
  /// the audio's `gargoyle_strike`) the world blanches (.38, fading over .25
  /// s) behind the stone ([flash], drawn before the rig so he is darkest
  /// against it) and a bolt hits the weather-vane mount's pin ([bolt], drawn
  /// after him: it comes down in front of the skyline, left of his head). The
  /// bolt flickers (struck, dark, struck again by .11 s) and the pin flares.
  /// Under Reduced Motion: no flash and no flicker; the bolt is drawn once,
  /// still, for half a second and fades.
  static void _flash(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (!m.arriving || m.reducedMotion) return;
    final since = boss.age - SkyBoss.revealAt;
    if (since < 0 || since > .3) return;
    final u = 1 - _ramp(since, 0, .25);
    if (u > 0) c.drawRect(Offset.zero & size, GargoyleKit.fill(const Color(0xffe6ecff), .38 * u * u));
  }

  static void _bolt(Canvas c, Size size, SkyBoss boss, BossMotion m, ({Offset heart, double unit}) f) {
    if (!m.arriving) return;
    final since = boss.age - SkyBoss.revealAt;
    if (since < 0 || since > .7) return;
    final h = size.height;
    final tip = f.heart + GargoyleStagingArt.pinTip * f.unit;
    if (m.reducedMotion) {
      GargoyleStagingArt.bolt(c, tip, h, .6 * (1 - _ramp(since, .3, .7)));
      return;
    }
    final flicker = since < .07
        ? 1.0
        : since < .11
        ? .12
        : since < .24
        ? 1.0
        : 1 - _ramp(since, .24, .5);
    GargoyleStagingArt.bolt(c, tip, h, flicker);
    // The pin flares white-hot as the current finds the rod.
    final flare = (1 - _ramp(since, 0, .3)) * flicker;
    GargoyleKit.glow(c, tip, f.unit * 2.0 * (1 + flare), const Color(0xffcfe0ff), .9 * flare);
  }

  /// His roar's three rings, each a ring of light from the beak (the roar
  /// rises at 2.65 s, peaks 2.81 to 3.11 s). Motion: none under Reduced Motion.
  static void _roar(Canvas c, Size size, SkyBoss boss, BossMotion m, GargoylePose p, ({Offset heart, double unit}) f) {
    if (m.reducedMotion) return;
    final h = size.height;
    final beak = f.heart + GargoyleBossRig.beakTipAt(p) * f.unit;
    for (var i = 0; i < 3; i++) {
      final u = _ramp(boss.age, 2.78 + i * .15, 3.32 + i * .15);
      if (u <= 0 || u >= 1) continue;
      final r = h * (.05 + .42 * (1 - math.pow(1 - u, 2.4)));
      final fade = (1 - u) * (1 - u);
      c.drawCircle(beak, r, GargoyleKit.line(GargoylePalette.ink, h * .014 * (1 - u * .5), fade * .35));
      c.drawCircle(beak, r, GargoyleKit.line(GargoylePalette.lampWarm, h * .007 * (1 - u * .5), fade * .85));
    }
  }

  /// The beam that "tests" the sky when he wakes: from the roar's release it
  /// glides down from the top to the bird, holds a beat and goes out, and an
  /// iris closes round the bird (his catch phrase, "SPOTTED!", without its
  /// cost). PRESENTATION only: the rules light no beam in a cutscene, so it
  /// has none of a real beam's hard hairline edges or motes (it is a soft
  /// cone) and the bird is not hurt. None under Reduced Motion.
  static void _tease(Canvas c, Size size, FlightSimulation sim, BossMotion m, GargoylePose p, ({Offset heart, double unit}) f) {
    if (m.reducedMotion || !m.arriving || !sim.birdY.isFinite) return;
    final age = m.boss.age;
    const from = 3.25, lands = 3.95, off = 4.45;
    if (age < from || age > off) return;
    final h = size.height;
    final glide = _ease(_ramp(age, from, lands));
    final k = _ramp(age, from, from + .18) * (1 - _ramp(age, lands + .2, off));
    final centre = .16 + (sim.birdY.clamp(.2, .86) - .16) * glide;
    final eye = f.heart + GargoyleBossRig.eyeAt(p) * f.unit;
    GargoyleBeamArt.beam(
      c,
      size,
      GargoyleBeam(centre: centre, half: .08, far: false, fury: false, intensity: .95 * k),
      eye,
      layers: GargoyleBeamArt.layerBody | GargoyleBeamArt.layerCore,
    );
    final bird = Offset(FlightSimulation.birdX * h, sim.birdY * h);
    final since = age - lands;
    if (since >= 0) GargoyleEncounterUi.spotRing(c, bird, h, since, reduced: false);
  }

  // ------------------------------------------------------------ defeat --

  /// He comes on with the tower sliding in from the right at .95 s (the rules
  /// park him just off the edge, .3 screen heights out, which is less than the
  /// reach of his beak: until the slide begins he is not drawn, and he fades in
  /// over .25 s as it does, so no sliver of grey beak hangs at the edge of the
  /// storm).
  static double _fadeIn(BossMotion m) {
    if (!m.arriving) return 1;
    return _ease(_ramp(m.boss.age, .95, 1.2));
  }

  /// The killing blow's white-out on the creature's layer: white-hot from
  /// the blow to .03 s, clearing by .12 s (the hit-stop). Nothing under Reduced
  /// Motion but the .12 s hold.
  static double _white(BossMotion m) {
    if (!m.defeated) return 0;
    if (m.reducedMotion) return m.death < .12 ? .6 : 0;
    return 1 - _ramp(m.death, .03, .12);
  }

  /// Fills blow out toward white while ink lines stay a readable grey (the
  /// shared pass the other bosses' white-outs use).
  static ColorFilter _whiten(double w) {
    const k = 3.2, b = -90.0;
    final keep = 1 - w;
    return ColorFilter.matrix([
      keep + w * .3 * k, w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, keep + w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, w * .59 * k, keep + w * .11 * k, 0, w * b, //
      0, 0, 0, 1, 0,
    ]);
  }

  /// His fall, [BossMotion.death] seconds after the killing blow: the lamp
  /// breaks (.6 s), light gathers in the cracks and bursts out at .85 s, the
  /// body is a heap of limestone, steel and dust, pigeons burst out of it and
  /// two lenses are left lit on the rubble. The rig draws him to the burst and
  /// then the ledge; the heap, dust, pigeons and lenses are G7's, the hit-stop
  /// glow and the falling visor G8's. The shared generic death (overload, two
  /// rings, a smoke poof) is never drawn for him.
  static void _defeat(Canvas c, Size size, BossMotion m, GargoylePose p, ({Offset heart, double unit}) f) {
    final d = m.death, h = size.height, reduced = m.reducedMotion;
    final lamp = f.heart;
    // The hit-stop: a white-hot core on the lamp, then light gathering in him.
    final stop = reduced ? (d < .12 ? .4 : 0.0) : .55 * (1 - _ramp(d, 0, .12));
    if (stop > 0) GargoyleKit.glow(c, lamp, f.unit * 2.6, GargoylePalette.lampCore, stop);
    final gather = reduced ? 0.0 : _ease(_ramp(d, .35, SkyBoss.burstAt)) * (d < SkyBoss.burstAt + .05 ? 1.0 : 0.0);
    if (gather > 0) GargoyleKit.glow(c, lamp, f.unit * (1.5 + 2.2 * gather), GargoylePalette.lampWarm, .55 * gather);
    GargoyleEncounterUi.rubble(c, lamp, h, d, reduced: reduced);
    GargoyleEncounterUi.crumble(c, lamp, h, d, reduced: reduced);
    _visor(c, m, f);
    GargoyleEncounterUi.lenses(c, lamp, h, d, reduced: reduced);
    GargoyleEncounterUi.pigeonsOut(c, lamp, h, d, reduced: reduced);
  }

  /// The brow visor the blow knocks loose (.3 s in): it starts exactly on the
  /// slumped head (position, turn and size from [GargoyleBossRig.visorDrop]),
  /// is thrown up and back, tumbles and clatters down the tower, off the
  /// left of the ledge into the night. Reduced Motion: it is simply gone after
  /// a .25 s fade (nothing tumbles).
  static void _visor(Canvas c, BossMotion m, ({Offset heart, double unit}) f) {
    final d = m.death;
    if (d < GargoyleTimeline.visorLostAt || d > 2.4) return;
    final tau = d - GargoyleTimeline.visorLostAt;
    final start = GargoyleBossRig.visorDrop(GargoyleTimeline.visorLostAt, reduced: m.reducedMotion);
    if (m.reducedMotion) {
      final a = 1 - _ramp(tau, .1, .35);
      if (a <= 0) return;
      c.save();
      c.translate(f.heart.dx + start.at.dx * f.unit, f.heart.dy + start.at.dy * f.unit);
      c.rotate(start.angle);
      c.scale(f.unit * start.scale);
      c.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, a));
      GargoyleBossRig.visorPaint(c);
      c.restore();
      c.restore();
      return;
    }
    // Ballistic in rig units: up and back, then gravity (22 u/s^2).
    final at = start.at + Offset(-1.3, -2.1) * tau + Offset(0, 11) * tau * tau;
    if (f.heart.dy + at.dy * f.unit > 400 + f.unit * 3) return;
    c.save();
    c.translate(f.heart.dx + at.dx * f.unit, f.heart.dy + at.dy * f.unit);
    c.rotate(start.angle - 5.2 * tau);
    c.scale(f.unit * start.scale);
    GargoyleBossRig.visorPaint(c);
    c.restore();
  }

  // -------------------------------------------------------- foreground --

  /// The killing blow's burst flashes the whole screen, over everything and
  /// under the letterbox: .5 fading over .18 s at the burst (.85 s). Motion:
  /// none under Reduced Motion.
  static void foreground(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss;
    if (!_fine(boss, m, size) || m.reducedMotion || !m.defeated) return;
    final k = m.death - SkyBoss.burstAt;
    if (k < 0) return;
    final u = 1 - _ramp(k, 0, .18);
    if (u > 0) c.drawRect(Offset.zero & size, GargoyleKit.fill(GargoylePalette.lampCore, .5 * u * u));
  }
}
