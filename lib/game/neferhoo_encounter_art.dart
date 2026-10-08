import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../l10n/l10n.dart';
import 'boss_motion.dart';
import 'enemy_designs/mummy_bat.dart';
import 'neferhoo_boss_rig.dart';
import 'neferhoo_encounter_ui.dart';
import 'neferhoo_fight_art.dart';
import 'neferhoo_fx.dart';
import 'neferhoo_kit.dart';
import 'neferhoo_layout.dart';
import 'neferhoo_pose.dart';
import 'neferhoo_props_art.dart';
import 'neferhoo_rig.dart';
import 'neferhoo_staging_art.dart';
import 'regions/region_scene.dart';
import 'regions/world_backdrop.dart';

/// Where Neferhoo stands in the world, and how he arrives, fights and falls:
/// his branches of `BossEncounterArt` (the shared file only dispatches here).
///
/// **Layers** (the game paints backdrop, obstacles and stars, [paint], the
/// bird, [foreground], then the health strip):
///  * [backdrop], under everything: the fight's night wash and his turquoise
///    halo, then (while he fights) the mail lane and the ankh's loop
///    ([NeferhooFightArt.under]);
///  * [paint]: the arrival (the pyramid's courier door, the dust, the sand
///    devil carrying him and its letters, his silhouette and eyes in the
///    whirl, the reveal, HOO-POO-POO), him in the fight with his letters,
///    ankhs and returns over him ([NeferhooFightArt.over]), and the defeat
///    (the wraps unravel, the mask pops off and tumbles onto the dunes, his
///    dead letters burst out, the lost letter floats free and glows, he
///    blinks, looks up and drifts off);
///  * [foreground]: nothing of his own (the shared letterbox, his name card
///    [NeferhooEncounterUi.nameCard] and his victory card are drawn by
///    `BossEncounterArt.foreground` around it).
///
/// **Where he is.** In the fight the rules' place `(boss.x, boss.y)` (x his
/// anchor, y the rules' hover), the rig's unit `h * SkyBoss.radius`, and none
/// of [BossMotion]'s offset, rotation or body scale: his pose's lean and hit
/// carry the recoil (design). In the arrival he is staged at the anchor the
/// rules slide him to and on the hover's own curve, so the arrival's last
/// frame is the fight's first; in the defeat, from where the killing blow
/// found him.
///
/// **Timings** (the shared clocks, so the shared cues land on them): the
/// reveal at [SkyBoss.revealAt] (1.65 s, `boss_reveal`), HOO-POO-POO at
/// [SkyBoss.roarAt] (2.65 s, three syllables .15 s apart), the name card at
/// 2.85 s, control at 4.6 s; the killing blow's hit-stop to .12 s, the mask
/// pops at [SkyBoss.burstAt] (.85 s, the burst cue), the lost letter rises at
/// .95 s, GUARDIAN DOWN! at 1.55 s, all gone by 3.8 s.
///
/// **Reduced Motion**: the clocks that only animate freeze (the devil's spin,
/// the letters' whirl, flutter and tumble, the wind, the motes, the glints,
/// the strips' wave, the rig's own clocks); the flashes, the shockwaves and
/// the ring of flung letters are not drawn; he does not drift off; what
/// happens still happens, in place, and fades (the devil comes and goes, he
/// appears through it; from the pop the mask lies on the dune, the dead
/// letters lie where they come to rest, the lost letter glows where he was).
///
/// Pure functions of the simulation and the boss clock. A boss whose clock
/// or place is broken (NaN, infinite) draws nothing. At most one layer in
/// either cinematic (his colours fading in over the silhouette, bounded to
/// his figure; everything of his fading out together at the end of the
/// defeat; the lost letter fading in under Reduced Motion), none in the
/// fight; the cards add at most one of their own while they fade.
abstract final class NeferhooEncounterArt {
  /// The halo's and the defeat flash's accent, and the light of his magic.
  static const tint = NeferhooPalette.turq;
  static const light = NeferhooPalette.turqLit;

  /// The defeat's dust as (shade, body, light): moonlit linen.
  static const smoke = (
    NeferhooPalette.inkSoft,
    NeferhooPalette.linenShade,
    NeferhooPalette.linenHi,
  );

  /// The arrival's omen (the shared warning band): its title and its line
  /// (design §7: the arrival banner).
  static String get omenTitle => L10n.strings.encounterOmenTitle_neferhoo;
  static String get omenLine => L10n.strings.encounterOmenLine_neferhoo;

  /// The letterbox caption once he has arrived.
  static String get caption => L10n.strings.encounterCaption_neferhoo;

  /// A cinematic boss's arrival (`SkyBoss.arrivalDuration` of a cinematic
  /// boss): control returns, the fight's clock starts.
  static const arrivalSeconds = 4.6;

  static double _ramp(double v, double a, double b) => NeferhooStaging.ramp(v, a, b);
  static double _smooth(double t) => NeferhooStaging.smooth(t);

  static bool _fine(SkyBoss boss, BossMotion m, Size size) =>
      boss.isNeferhoo &&
      boss.age.isFinite &&
      boss.x.isFinite &&
      boss.y.isFinite &&
      size.width.isFinite &&
      size.height.isFinite &&
      size.height > 0 &&
      (!m.defeated || m.death.isFinite);

  // --------------------------------------------------------- letterbox --

  /// The letterbox's height share (0 to 1): the shared bars through the
  /// arrival; after the killing blow they slide in behind him (.4 to 1.1 s,
  /// the dragon's and the Gargoyle's timing) instead of cutting across the
  /// hit-stop.
  static double focus(BossMotion m) {
    if (!m.boss.age.isFinite || (m.defeated && !m.death.isFinite)) return 0;
    if (m.defeated) return _smooth(_ramp(m.death, .4, 1.1)) * m.focus;
    return m.focus;
  }

  // ------------------------------------------------------------- place --

  /// The rig's unit (px per rig unit) on a screen [h] high.
  static double unit(double h) => h * SkyBoss.radius;

  /// Where he stands in the arrival at age [t] (screen px): the anchor the
  /// rules slide him to, on the fight's hover curve (so at 4.6 s it is the
  /// fight's first place).
  static Offset arrivalAt(Size size, double t, {bool reduced = false}) {
    final h = size.height;
    return Offset(
      Neferhoo.anchorX(FlightSimulation.birdX, size.width / h) * h,
      // (under Reduced Motion he does not bob: the fight draws him at the
      // bob's centre, `NeferhooFightArt.drawnY`)
      (reduced ? NeferhooFightArt.restY : Neferhoo.hoverY(t - arrivalSeconds)) * h,
    );
  }

  /// Khufu's courier door on a screen of [size] while [sim] flies (screen
  /// px), following the far band's drift and its repeats; null when no
  /// Egypt pyramid is on screen (a flight outside Egypt, a test harness).
  /// The pyramid's own constant is `regions/egypt.dart`'s `w * .535`; the
  /// door is on its lit face, .147 h left of its axis, .575 h down.
  static Offset? doorAt(Size size, FlightSimulation sim, {required bool reduced}) {
    if (sim.region != WorldRegion.egypt || !sim.elapsed.isFinite) return null;
    final w = size.width, h = size.height;
    final f = SceneFrame(
      size,
      seconds: sim.elapsed,
      distance: sim.distance.isFinite ? sim.distance : 0,
      reducedMotion: reduced,
      region: sim.region,
    );
    final drift = WorldBackdrop.drift(f, Depth.far, WorldRegion.egypt);
    for (final copy in WorldBackdrop.copies(f, Depth.far)) {
      final x = w * khufuShare + copy.shift - drift - h * .147;
      if (x >= copy.from && x <= copy.to && x > -h * .05 && x < w + h * .05) {
        return Offset(x, h * .575);
      }
    }
    return null;
  }

  /// Khufu's place as a share of the screen width (`regions/egypt.dart`'s
  /// `_pyramids(c, w * .535, h, w)`: `neferhoo_staging_test` reads that
  /// file, so the door cannot drift off the pyramid).
  static const khufuShare = .535;

  // ----------------------------------------------------------- prewarm --

  static bool _warmed = false;
  static Locale? _warmLocale;

  /// Warm for the language the cards' words were laid out in: a switch
  /// empties their caches ([NeferhooStaging]), so the next countdown
  /// prewarms again.
  static bool get _warm => _warmed && _warmLocale == L10n.locale;
  static set _warm(bool warm) {
    _warmed = warm;
    _warmLocale = L10n.locale;
  }

  /// Whether [prewarm] has run in this app session (in this language).
  static bool get warm => _warm;

  /// Forgets that the caches are warm (a test that expects the next flight
  /// to prewarm again).
  @visibleForTesting
  static void forgetWarmth() => _warm = false;

  /// Prewarms once, ahead of the fight: [BirdGame] calls it during a 2-6
  /// flight's countdown, when a long frame cannot end the flight. Building
  /// every cache on the arrival's first frame instead took over half a
  /// second on a phone running a debug build, and a frame that long ends a
  /// playing flight as stalled ([FlightSimulation.tick]).
  static void prewarmAhead() {
    if (!_warm) prewarm();
  }

  /// Builds the rig's caches and the stage's gradients into a picture nobody
  /// sees, so no frame of the fight builds one: called on the arrival's
  /// first frame (or a replay's that seeks into the fight). Pure, safe to
  /// call again.
  static void prewarm() {
    _warm = true;
    NeferhooBossRig.prewarm();
    // His mummy bats (rules 52) fly in his fight: their art's caches too.
    MummyBatArt.prewarm();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    NeferhooStaging.dustPuff(c, Offset.zero, 10, 1);
    NeferhooStaging.star(c, Offset.zero, 10);
    final size = const Size(640, 360);
    NeferhooEncounterUi.paintCard(c, size);
    NeferhooEncounterUi.paintVictory(c, size);
    rec.endRecording().dispose();
  }

  // ---------------------------------------------------------- backdrop --

  /// Under everything: the night wash (the shared strength, so the sky is as
  /// dark as his letters were reviewed on) and his turquoise halo; while he
  /// fights, the telegraphs.
  static void backdrop(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    if (!_fine(boss, m, size)) return;
    final h = size.height;
    final storm = m.storm;
    c.drawRect(Offset.zero & size, NeferhooStaging.fill(NeferhooStaging.night, storm * (.22 + focus(m) * .25)));
    final cx = (m.arriving ? arrivalAt(size, boss.age).dx : boss.x * h);
    final halo = Offset(cx, h * .48);
    if (storm > 0) {
      c.drawCircle(
        halo,
        h * .65,
        Paint()
          ..shader = RadialGradient(
            colors: [tint.withValues(alpha: .19 * storm), const Color(0x00171c39)],
          ).createShader(Rect.fromCircle(center: halo, radius: h * .65)),
      );
    }
    if (boss.phase == BossPhase.attacking) NeferhooFightArt.under(c, size, boss, m);
  }

  // ------------------------------------------------------------- paint --

  /// Neferhoo himself: his arrival, the fight and his defeat.
  static void paint(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss;
    if (!_fine(boss, m, size)) return;
    if (!_warm) prewarm();
    if (m.arriving) {
      _arrival(c, size, sim, m);
    } else if (m.defeated) {
      _defeat(c, size, m);
    } else {
      final h = size.height;
      c.save();
      final y = NeferhooFightArt.drawnY(boss, reduced: m.reducedMotion);
      c.translate(boss.x * h, y * h);
      c.scale(unit(h));
      NeferhooBossRig.paint(
        c,
        boss,
        m,
        lookY: sim.birdY.isFinite ? (sim.birdY - y) * 3 : 0,
      );
      c.restore();
      NeferhooFightArt.over(c, size, boss, m);
    }
  }

  /// Over the bird: nothing of his own (see the class notes).
  static void foreground(Canvas c, Size size, FlightSimulation sim, BossMotion m) {}

  // ----------------------------------------------------------- figure --

  /// A rig point [p] (rig units) on screen for a figure at [at] with unit
  /// [u], squashed by [sx]/[sy], posed with [pose]'s lean and hit (the
  /// painter's own transform).
  static Offset rigPoint(Offset p, Offset at, double u, NeferhooPose pose, {double sx = 1, double sy = 1}) {
    final r = NeferhooKit.rot(p, pose.lean + pose.hit * .08) + Offset(pose.hit * .22, -pose.hit * .05);
    return at + Offset(r.dx * u * sx, r.dy * u * sy);
  }

  static void _figure(Canvas c, Offset at, double u, NeferhooPose pose, {double sx = 1, double sy = 1, bool sil = false}) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(u * sx, u * sy);
    NeferhooPainter(c, pose, silhouette: sil, sil: const Color(0xff2a2145)).paint();
    c.restore();
  }

  static Rect _layerRect(Offset at, double u, {double sx = 1, double sy = 1}) {
    final b = NeferhooBossRig.layerBounds;
    return Rect.fromLTRB(at.dx + b.left * u * sx, at.dy + b.top * u * sy, at.dx + b.right * u * sx, at.dy + b.bottom * u * sy);
  }

  /// The scalar channels of [a] eased toward [b] by [w].
  static NeferhooPose _mix(NeferhooPose a, NeferhooPose b, double w) {
    if (w <= 0) return a;
    if (w >= 1) return b;
    double l(double x, double y) => x + (y - x) * w;
    return a.copy(
      crest: l(a.crest, b.crest),
      wing: l(a.wing, b.wing),
      lean: l(a.lean, b.lean),
      beak: l(a.beak, b.beak),
      lid: l(a.lid, b.lid),
      brow: l(a.brow, b.brow),
      look: Offset.lerp(a.look, b.look, w),
      glow: l(a.glow, b.glow),
      legs: l(a.legs, b.legs),
      ribbons: l(a.ribbons, b.ribbons),
      sleepy: l(a.sleepy, b.sleepy),
      smile: l(a.smile, b.smile),
      headTilt: l(a.headTilt, b.headTilt),
      sweep: l(a.sweep, b.sweep),
      reach: l(a.reach, b.reach),
      satchelOpen: l(a.satchelOpen, b.satchelOpen),
      wingRate: l(a.wingRate ?? 0, b.wingRate ?? 0),
    );
  }

  // ------------------------------------------------------------ arrival --

  /// The roar's three syllables (HOO, POO, POO).
  static const syllables = [SkyBoss.roarAt, SkyBoss.roarAt + .15, SkyBoss.roarAt + .30];

  static double beakPulse(double t) {
    var b = 0.0;
    for (final s in syllables) {
      final k = (t - s) / .15;
      if (k > 0 && k < 1) b = math.max(b, math.sin(k * math.pi));
    }
    return b;
  }

  /// His pose through the arrival at age [t] (design `ArrivalFx`): folded
  /// and glowing in the whirl, the crest fanning and the streamers
  /// unfurling after the reveal, the mask catching the sun, a beak pulse on
  /// each syllable, a settle; from 3.8 s it eases into the fight's first
  /// pose ([fight]), so control returns on a still figure.
  static NeferhooPose arrivalPose(double t, {NeferhooPose? fight, bool reduced = false}) {
    final unfurl = _smooth(_ramp(t, 1.9, 2.65));
    final beak = beakPulse(t);
    final settle = t >= SkyBoss.roarAt ? math.sin(((t - SkyBoss.roarAt) / .8).clamp(0.0, 1.0) * math.pi) : 0.0;
    final gk = _ramp(t, 2.16, 2.62);
    final pose = NeferhooPose(
      crest: .2 + .8 * unfurl,
      wing: t < SkyBoss.roarAt
          ? .85 - 1.75 * unfurl
          : -.9 +
                .8 * _smooth(_ramp(t, SkyBoss.roarAt, 3.3)) +
                .12 * math.sin(NeferhooPose.wingBeat * t) * _smooth(_ramp(t, 3.0, 3.6)),
      beak: beak,
      brow: -.5 + .4 * unfurl,
      glow: 1 - .55 * _smooth(_ramp(t, 2.6, 3.4)),
      ribbons: .3 + unfurl,
      lean: settle * .16 + beak * .05,
      legs: settle,
      phase: t - arrivalSeconds,
      look: const Offset(-1, 0),
      glint: gk > 0 && gk < 1 ? gk : -1,
      reduced: reduced,
    );
    if (fight == null) return pose;
    return _mix(pose, fight, _smooth(_ramp(t, 3.8, arrivalSeconds)));
  }

  /// Where the sand devil's base is at [t]: from below the [door] (or the
  /// dunes under it) to under his place [bx] (px).
  static Offset devilBase(double t, Offset start, Offset end) {
    final u = _smooth(_ramp(t, .5, 1.65));
    return Offset.lerp(start, end, u)!;
  }

  static void _arrival(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss, t = boss.age, reduced = m.reducedMotion;
    final h = size.height, w = size.width, k = h / 360, u = unit(h);
    final home = arrivalAt(size, t, reduced: reduced);
    final bx = home.dx;
    // The clock of everything that only animates (frozen under Reduced
    // Motion at a calm phase).
    final spin = reduced ? 1.3 : t;
    final door = doorAt(size, sim, reduced: reduced);
    final start = door != null ? door + Offset(0, 27 * k) : Offset(w * khufuShare - h * .147, 234 * k);
    final end = Offset(bx, 266 * k);

    _haze(c, size, t, reduced);
    if (door != null) NeferhooStaging.door(c, door, h, t, still: reduced);
    _pour(c, t, start - Offset(0, 27 * k), start, end, k);

    // The devil: its far half and far letters, the figure, the near half.
    final base = devilBase(t, start, end);
    final dsc = .24 + .76 * _smooth(_ramp(t, .35, 1.55));
    final drise = _smooth(_ramp(t, .38, 1.2));
    final dstr = _smooth(_ramp(t, .38, .85)) * (1 - _smooth(_ramp(t, 1.7, 2.45)));
    final lean = 1 - _smooth(_ramp(t, 1.4, 1.8));
    final letters = (4 + 9 * _smooth(_ramp(t, .5, 1.5))).round();
    final lAlpha = _smooth(_ramp(t, .5, .8)) * (1 - _smooth(_ramp(t, 1.75, 2.35)));
    if (dstr > 0) {
      for (var i = 0; i < 3; i++) {
        NeferhooStaging.dustPuff(
          c,
          base + Offset((i - 1) * 26 * dsc * k + math.sin(spin * 5 + i) * 4 * k, (-3 - i % 2 * 4) * k),
          (20 + 6 * i) * dsc * k,
          .7 * dstr,
        );
      }
      NeferhooStaging.devilBody(c, base, h, spin, scale: dsc, rise: drise, alpha: .1 * dstr, lean: lean);
      NeferhooStaging.devil(c, base, h, spin, near: false, scale: dsc, rise: drise, strength: dstr, lean: lean);
      NeferhooStaging.devilLetters(c, base, h, spin, near: false, n: letters, scale: dsc, rise: drise, alpha: lAlpha, lean: lean);
    }

    // The figure: a silhouette in the whirl, his colours fading in at the
    // reveal (one bounded layer while they do).
    final reveal = _smooth(_ramp(t, SkyBoss.revealAt, 2.45));
    final pose = arrivalPose(t, fight: NeferhooPose.fight(boss, m), reduced: reduced);
    final crouch = reduced ? 0.0 : _smooth(_ramp(t, 1.38, 1.62));
    final spring = !reduced && t >= SkyBoss.revealAt
        ? math.exp(-7 * (t - SkyBoss.revealAt)) * math.cos(20 * (t - SkyBoss.revealAt))
        : 0.0;
    final sy = 1 - .08 * crouch + .11 * spring;
    final sx = 1 + .06 * crouch - .06 * spring;
    final rise = reduced ? 0.0 : (1 - _smooth(_ramp(t, .9, 1.8))) * h * .15;
    final at = home + Offset(0, rise);
    if (t > .92) {
      if (reveal < 1) _figure(c, at, u, pose, sx: sx, sy: sy, sil: true);
      if (reveal > 0) {
        final fading = reveal < 1;
        if (fading) {
          c.saveLayer(_layerRect(at, u, sx: sx, sy: sy), Paint()..color = Color.fromRGBO(255, 255, 255, reveal));
        }
        _figure(c, at, u, pose, sx: sx, sy: sy);
        if (fading) c.restore();
      }
      if (!reduced) {
        // His magic's glyphs orbit him from the reveal, thinning to the
        // fight's calm few by control, on the fight's own orbit clock (so the
        // hand-over does not jump); the last one lit fades, never pops.
        final strength = reveal * (1 - .7 * _smooth(_ramp(t, 3.6, arrivalSeconds)));
        final s7 = 7 * strength;
        NeferhooFx.glyphMotes(c, at, h, t - arrivalSeconds, strength: s7.floor() / 7, fade: s7 - s7.floor());
      }
    }
    if (dstr > 0) {
      // The veil: dust over the figure, blown open at the reveal.
      final dense = _smooth(_ramp(t, .74, .92)) * (1 - _smooth(_ramp(t, 1.1, 1.62)));
      final blown = _smooth(_ramp(t, SkyBoss.revealAt, 2.5));
      NeferhooStaging.devilBody(c, base, h, spin, scale: dsc, rise: drise, alpha: (.06 + .06 * (1 - reveal)) * dstr, lean: lean);
      NeferhooStaging.dustVeil(
        c,
        at,
        h,
        spin,
        (.66 * dense + .22 * (1 - blown) * (1 - dense)) * dstr * (1 - blown),
        spread: 1 + 1.8 * blown,
      );
      NeferhooStaging.devilLetters(c, base, h, spin, near: true, n: letters, scale: dsc, rise: drise, alpha: lAlpha, lean: lean);
      NeferhooStaging.devil(c, base, h, spin, near: true, scale: dsc, rise: drise, strength: dstr, lean: lean);
    }
    // His eyes burn through the dust.
    if (t > .92 && reveal < 1) {
      final eye = rigPoint(NeferhooLayout.eye, at, u, pose, sx: sx, sy: sy);
      final a = (1 - reveal) * _smooth(_ramp(t, 1.0, 1.3));
      c.drawCircle(eye, 16 * k, NeferhooStaging.fill(NeferhooPalette.magic, .2 * a));
      c.drawCircle(eye, 6.5 * k, NeferhooStaging.fill(NeferhooPalette.magic, a));
      c.drawCircle(eye, 2.6 * k, NeferhooStaging.fill(const Color(0xffffffff), a));
      c.drawCircle(eye + Offset(12 * k, -2 * k), 3.6 * k, NeferhooStaging.fill(NeferhooPalette.magic, .75 * a));
    }
    if (!reduced) {
      _reveal(c, size, t, at, bx);
      _maskGlint(c, t, at, u, pose);
    }
    _roar(c, t, at, u, pose, k, reduced);
    if (!reduced) {
      // Wind-blown dust and three big out-of-focus letters tumbling past.
      final wind = _smooth(_ramp(t, .25, 1.4)) * (1 - _smooth(_ramp(t, 2.4, 3.6)));
      NeferhooStaging.windStreaks(c, size, t, wind);
      for (var i = 0; i < 3; i++) {
        final f = _ramp(t, 1.0 + i * .22, 2.2 + i * .22);
        if (f <= 0 || f >= 1) continue;
        NeferhooStaging.miniLetter(
          c,
          Offset(w + 40 * k - f * (w + 120 * k), (262 + i * 34 + math.sin(f * 9 + i) * 8) * k),
          (52 - i * 6) * k,
          tilt: f * 9 + i * 2,
          alpha: .55 * math.sin(f * math.pi),
        );
      }
    }
  }

  /// A low bank of dust along the plateau, the sun veiled, rolling banks.
  static void _haze(Canvas c, Size size, double t, bool reduced) {
    final storm = _smooth(_ramp(t, .2, 1.4)) * (1 - _smooth(_ramp(t, 2.3, 3.6)));
    if (storm <= 0) return;
    final w = size.width, k = size.height / 360;
    final band = Rect.fromLTWH(0, 196 * k, w, 90 * k);
    c.drawRect(
      band,
      NeferhooStaging.grad(
        NeferhooStaging.lin(band.topLeft, band.bottomLeft, const [Color(0x00eac58b), Color(0xffeac58b), Color(0x00eac58b)], const [0, .55, 1]),
        .33 * storm,
      ),
    );
    final sun = Offset(.8 * w, 68 * k);
    c.drawCircle(sun, 70 * k, NeferhooStaging.grad(NeferhooStaging.rad(sun, 70 * k, const [Color(0xfff6dca6), Color(0x00f6dca6)]), .35 * storm));
    final roll = reduced ? 0.0 : t;
    for (var i = 0; i < 5; i++) {
      final x = w + 60 * k - ((roll * 38 * k + NeferhooStaging.hash(i + 30) * (w + 200 * k)) % (w + 200 * k));
      NeferhooStaging.dustPuff(
        c,
        Offset(x, (232 + NeferhooStaging.hash(i + 31) * 36) * k),
        (34 + 22 * NeferhooStaging.hash(i + 32)) * k,
        .42 * storm,
        col: NeferhooStaging.sand,
        stretch: 1.8,
      );
    }
  }

  /// Dust pouring from the [door] (down the face, along the ground), then
  /// trailing the devil from [start] toward [end].
  static void _pour(Canvas c, double t, Offset door, Offset start, Offset end, double k) {
    if (t < .45 || t > 3.4) return;
    for (var i = 0; i < 20; i++) {
      final age = t - (.46 + i * .05);
      if (age < 0 || age > 1.9) continue;
      final f = age / 1.9;
      final pull = _smooth(_ramp(t, .7, 1.6));
      final dev = devilBase(t, start, end);
      final x = door.dx +
          (14 + 22 * NeferhooStaging.hash(i + 50)) * age * (1 - pull) * k +
          (dev.dx - door.dx) * pull * .8 +
          (NeferhooStaging.hash(i) - .5) * 30 * f * k;
      final y = door.dy + 14 * k - 30 * f * (.5 + .5 * NeferhooStaging.hash(i + 3)) * k + (dev.dy - 26 * k - door.dy) * pull * .35;
      NeferhooStaging.dustPuff(
        c,
        Offset(x, y),
        (12 + 24 * f) * (.7 + .5 * NeferhooStaging.hash(i + 9)) * k,
        (1 - f) * _smooth(_ramp(age, 0, .1)),
        stretch: 1 + .9 * f,
      );
    }
  }

  /// The reveal: a flash, a shockwave along the ground with dust thrown
  /// out, the ring of ten letters flung off, a ring of glyph light.
  static void _reveal(Canvas c, Size size, double t, Offset boss, double bx) {
    const at = SkyBoss.revealAt;
    if (t < at || t > 3.2) return;
    final k = size.height / 360;
    final f = _ramp(t, at, at + .45);
    if (f < 1) c.drawRect(Offset.zero & size, NeferhooStaging.fill(const Color(0xfffffbe8), .4 * (1 - f)));
    final g = _ramp(t, at, at + .95);
    if (g < 1) {
      final ground = Offset(bx, 272 * k);
      c.drawOval(
        Rect.fromCenter(center: ground, width: (40 + 520 * _smooth(g)) * k, height: (8 + 58 * _smooth(g)) * k),
        NeferhooStaging.line(NeferhooStaging.sandHi, (3.4 * (1 - g) + .5) * k, .75 * (1 - g)),
      );
      c.drawOval(
        Rect.fromCenter(center: ground, width: (30 + 380 * _smooth(g)) * k, height: (6 + 40 * _smooth(g)) * k),
        NeferhooStaging.line(NeferhooStaging.sandShade, 6 * (1 - g) * k, .35 * (1 - g)),
      );
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3 + .4;
        NeferhooStaging.dustPuff(
          c,
          Offset(
            bx + (math.cos(a) * 20 + math.cos(a) * 190 * _smooth(g)) * k,
            (272 + math.sin(a) * 6 + math.sin(a) * 26 * _smooth(g) - 14 * g) * k,
          ),
          (12 + 26 * g) * k,
          .8 * (1 - g),
        );
      }
    }
    if (f < 1) {
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi / 5 + .15;
        final r = (24 + 150 * NeferhooStaging.outCubic(f)) * k;
        NeferhooStaging.miniLetter(c, boss + Offset(math.cos(a) * r * 1.15, math.sin(a) * r * .8), 26 * k, tilt: a + f * 4, alpha: 1 - f * f);
      }
    }
    final s = _ramp(t, at, at + .7);
    if (s < 1) {
      final r = (20 + 190 * NeferhooStaging.outCubic(s)) * k;
      c.drawCircle(boss, r, NeferhooStaging.line(NeferhooPalette.magic, (2.6 * (1 - s) + .4) * k, .6 * (1 - s)));
      final gold = Path(), turq = Path();
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6 + s * 1.2;
        (i.isEven ? gold : turq).addOval(
          Rect.fromCircle(center: boss + Offset(math.cos(a), math.sin(a)) * r, radius: (2.2 * (1 - s) + .4) * k),
        );
      }
      c.drawPath(gold, NeferhooStaging.fill(NeferhooPalette.goldHi, 1 - s));
      c.drawPath(turq, NeferhooStaging.fill(NeferhooPalette.turqLit, 1 - s));
    }
  }

  /// The mask catches the sun: a glint star on the face plate's brow.
  static void _maskGlint(Canvas c, double t, Offset at, double u, NeferhooPose pose) {
    final g = _ramp(t, 2.16, 2.62);
    if (g <= 0 || g >= 1) return;
    final k = u / (360 * SkyBoss.radius);
    final p = rigPoint(const Offset(-1.5, -1.62), at, u, pose);
    final f = math.sin(g * math.pi);
    NeferhooStaging.star(c, p, (6 + 22 * f) * k, alpha: f, rot: .15);
    c.drawLine(p + Offset(-34 * f * k, 0), p + Offset(34 * f * k, 0), NeferhooStaging.line(NeferhooStaging.glint, 1.2 * k, .6 * f));
  }

  /// HOO-POO-POO: three comic words, one per syllable, popping from the
  /// beak, each with a gold-and-turquoise ring of glyph dots (the rings and
  /// the pop not under Reduced Motion: the words only fade).
  static void _roar(Canvas c, double t, Offset at, double u, NeferhooPose pose, double k, bool reduced) {
    if (t < SkyBoss.roarAt || t > SkyBoss.roarAt + .95) return;
    final beak = rigPoint(NeferhooLayout.beakTip, at, u, pose) + Offset(-2 * k, -6 * k);
    final l = L10n.strings;
    final words = [l.bossNeferhooHoo, l.bossNeferhooPoo, l.bossNeferhooPoo];
    const spots = [Offset(-10, 16), Offset(-36, 40), Offset(-62, 22)];
    for (var i = 0; i < 3; i++) {
      final s = syllables[i];
      if (t < s) continue;
      final f = ((t - s) / .72).clamp(0.0, 1.0);
      final rk = ((t - s) / .62).clamp(0.0, 1.0);
      if (!reduced && rk < 1) {
        final r = (12 + 54 * NeferhooStaging.outCubic(rk)) * k;
        c.drawCircle(beak, r, NeferhooStaging.line(NeferhooPalette.goldLit, (2.4 * (1 - rk) + .4) * k, .75 * (1 - rk)));
        final magic = Path(), gold = Path();
        for (var j = 0; j < 9; j++) {
          final a = j * 2 * math.pi / 9 + i * .7 + rk;
          (j % 3 == 0 ? magic : gold).addOval(
            Rect.fromCircle(center: beak + Offset(math.cos(a), math.sin(a)) * r, radius: (1.8 * (1 - rk) + .3) * k),
          );
        }
        c.drawPath(magic, NeferhooStaging.fill(NeferhooPalette.magic, 1 - rk));
        c.drawPath(gold, NeferhooStaging.fill(NeferhooPalette.goldHi, 1 - rk));
      }
      final pop = reduced ? 1.0 : NeferhooStaging.outBack(((t - s) / .14).clamp(0.0, 1.0), 2.4);
      final a = (1 - _smooth(_ramp(f, .55, 1))) * _smooth(_ramp(t - s, 0, .05));
      if (a <= 0) continue;
      final o = beak + spots[i] * k + Offset(0, reduced ? 0 : -10 * f * k);
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate((i - 1) * .16 - .06);
      c.scale(pop * (i == 0 ? 1.15 : 1.0));
      NeferhooStaging.text(
        c,
        words[i],
        Offset(0, -11 * k),
        22 * k,
        NeferhooPalette.goldHi.withValues(alpha: a),
        center: true,
        spacing: k,
        outline: NeferhooPalette.ink,
        outlineWidth: 4 * k,
      );
      c.restore();
    }
  }

  // ------------------------------------------------------------- defeat --

  /// When the mask pops off: the shared burst.
  static const pop = SkyBoss.burstAt;

  /// Everything of his fades out over this window after the killing blow
  /// (the victory card has gone by 3.8 s, the letterbox by 3.8 s).
  static const outFrom = 3.0, outBy = 3.85;

  /// The linen strips peel from these points (rig units), heading out.
  static const _roots = [
    (Offset(-.9, -.35), -2.7, 1.0),
    (Offset(-.15, -.98), -1.75, -1.0),
    (Offset(.85, -.8), -.65, 1.0),
    (Offset(1.28, .12), .15, -1.0),
    (Offset(.5, .88), 1.0, 1.0),
    (Offset(-.65, .75), 2.45, -1.0),
  ];

  static double _blink(double d) {
    var b = 0.0;
    for (final s in const [1.3, 1.95, 2.7]) {
      final k = (d - s) / .2;
      if (k > 0 && k < 1) b = math.max(b, math.sin(k * math.pi));
    }
    return b;
  }

  /// His pose [d] seconds after the killing blow (design `DefeatFx.pose`):
  /// the hit-stop, the shudder as the wraps loosen, then (from [pop]) the
  /// kindly old hoopoe with his spectacles, blinking, looking up at the lost
  /// letter, smiling, drifting off.
  static NeferhooPose defeatPose(double d, {bool reduced = false}) {
    if (d < pop) {
      final shake = math.sin(d * 28) * .08 * (1 - _ramp(d, .6, .85));
      return NeferhooPose(
        crest: 1 - _ramp(d, .1, .8) * .6,
        wing: -.8 + .45 * math.sin(d * 24),
        hit: d < .12 ? 1 : .55 + .45 * math.sin(d * 21).abs() * (1 - _ramp(d, .5, .85)),
        lid: .7,
        beak: .6,
        unwrap: .8 + .12 * _ramp(d, .2, .85),
        cracked: 1,
        glow: .9 * (1 - _ramp(d, .15, .85)),
        lean: shake + .2,
        ribbons: 1.3,
        phase: d * 3,
        satchelOpen: _ramp(d, .3, .85),
        legs: 1 - .9 * _ramp(d, .15, .85),
        headTilt: math.sin(d * 17) * .1,
        wingRate: 0,
        reduced: reduced,
      );
    }
    final t = d - pop;
    final drift = _smooth(_ramp(d, 1.0, 3.6));
    final up = _smooth(_ramp(d, 1.2, 1.9));
    return NeferhooPose(
      crest: .15 + .22 * _smooth(_ramp(d, 1.8, 2.4)) + .03 * math.sin(d * 5),
      wing: .9 - math.sin(d * 5) * .25 * (1 - up),
      mask: false,
      specs: true,
      sleepy: .5 - .3 * _smooth(_ramp(d, 1.5, 2.2)),
      lid: _blink(d),
      smile: .75 * _smooth(_ramp(d, 1.7, 2.3)),
      unwrap: .95,
      beak: t < .35 ? .45 * math.sin(t / .35 * math.pi) : 0,
      lean: .18 - drift * .1,
      headTilt: .1 + .08 * math.sin(d * 2.2) * up,
      legs: -.25 + .12 * math.sin(d * 2.3),
      ribbons: .4,
      phase: d,
      look: Offset(-.5 * up, -up),
      reach: .5 * math.sin(_ramp(d, 1.5, 2.9) * math.pi),
      satchelOpen: .9 * (1 - _smooth(_ramp(d, 1.2, 1.9))),
      satchelFull: 1 - _smooth(_ramp(d, pop, pop + .45)),
      sad: 0,
      brow: .3 * up,
      hit: d < 1.1 ? .4 * (1 - _ramp(d, .85, 1.1)) : 0,
      reduced: reduced,
    );
  }

  /// His place and size [d] s after the killing blow, from [at] where it
  /// found him: he drifts off right and up, a little smaller.
  static ({Offset at, double scale}) defeatBody(double d, Offset at, double h, {bool reduced = false}) {
    final drift = reduced ? 0.0 : _smooth(_ramp(d, 1.0, 3.6));
    final popped = d >= pop;
    return (
      at: at + Offset(drift * h * .25, drift * h * .05 - (popped ? drift * h * .1 : 0)),
      scale: popped ? 1 - drift * .25 : 1.0,
    );
  }

  static void _defeat(Canvas c, Size size, BossMotion m) {
    final boss = m.boss, d = m.death, reduced = m.reducedMotion;
    final h = size.height, k = h / 360, u = unit(h);
    final at0 = Offset(boss.x * h, NeferhooFightArt.drawnY(boss, reduced: reduced) * h);
    final p = defeatPose(d, reduced: reduced);
    final b = defeatBody(d, at0, h, reduced: reduced);
    final popPose = defeatPose(pop);
    final headPop = rigPoint(NeferhooLayout.head, at0, u, popPose);
    final satchelPop = rigPoint(NeferhooLayout.satchel, at0, u, popPose);
    // Everything of his fades out together, 3.0 to 3.85 s, through the one
    // bounded layer of the defeat (the figure, the strips, the dead letters,
    // the lost letter, the mask on the dune).
    final out = 1 - _smooth(_ramp(d, outFrom, outBy));
    if (out <= 0) return;
    final fading = out < .995;
    if (fading) {
      c.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, out));
    }
    _figure(c, b.at, u * b.scale, p);
    _strips(c, d, at0, b, p, u, k, reduced);
    _hatLetter(c, d, b, p, u, k, reduced);
    if (d >= pop) {
      _letters(c, d, satchelPop, k, reduced);
      _lostLetter(c, d, satchelPop, at0, k, reduced);
    }
    _mask(c, d, headPop, u, k, reduced);
    if (fading) c.restore();
    if (!reduced) _popFx(c, size, d, headPop, k);
    if (!reduced && d < .12) {
      c.drawRect(Offset.zero & size, NeferhooStaging.fill(const Color(0xffffffff), .85 * (1 - d / .12)));
    }
  }

  /// The strips of linen: attached and peeling before the pop, thrown out,
  /// curling and sinking after (their wave frozen under Reduced Motion).
  static void _strips(Canvas c, double d, Offset at0, ({Offset at, double scale}) b, NeferhooPose p, double u, double k, bool reduced) {
    final popPose = defeatPose(pop);
    for (var i = 0; i < _roots.length; i++) {
      final (root, theta, sgn) = _roots[i];
      final start = .14 + i * .1;
      if (d < start) continue;
      final fade = 1 - _smooth(_ramp(d, 2.7, 3.5));
      if (fade <= 0) continue;
      final peel = _smooth(_ramp(d, start, pop));
      final out = reduced ? (d >= pop ? 1.0 : 0.0) : _smooth(_ramp(d, pop, pop + .5));
      // Reduced Motion: let go, they hang where the pop threw them, still.
      final tau = reduced ? .3 : math.max(0.0, d - pop);
      var r0 = rigPoint(root, b.at, u * b.scale, p);
      var heading = theta;
      if (d >= pop) {
        // Let go at the pop: thrown outward from where they were, then sinking.
        final r1 = rigPoint(root, at0, u, popPose);
        final v = Offset(math.cos(theta), math.sin(theta));
        r0 = r1 + v * 70 * (1 - math.exp(-tau / .35)) * 1.05 * k + Offset(0, (26 * tau * tau + 12 * tau) * k);
        heading = theta + sgn * .35 * tau;
      }
      final len = ((30 + 46 * peel) + out * (70 + 40 * NeferhooStaging.hash(i + 2))) * k;
      final wave = reduced ? 1.2 : d;
      final curl = sgn * (.7 + .9 * out + .3 * math.sin(wave * 2 + i));
      NeferhooStaging.linenStrip(c, r0, heading, len, curl, wave + i, k, width: 13 + 3 * out, alpha: fade, seg: 18);
    }
  }

  /// A blizzard of dead letters from the satchel at [origin], fluttering
  /// down like leaves; some land and lie on the dunes. (Reduced Motion: from
  /// the pop they are simply there, where they come to rest.)
  static void _letters(Canvas c, double d, Offset origin, double k, bool reduced) {
    const a = 1.0;
    final tau = reduced ? 3.0 : d - pop;
    const show = 1.0;
    for (var i = 0; i < 13; i++) {
      final t = tau - .02 * i;
      if (t < 0) continue;
      final aim = -math.pi + .3 + (math.pi - .6) * ((i * .618) % 1.0);
      final speed = 250 + 190 * NeferhooStaging.hash(i + 5);
      final v = Offset(math.cos(aim) * speed * 1.15, math.sin(aim) * speed * .9) * k;
      const T = .5;
      final drag = T * (1 - math.exp(-t / T));
      final freq = 2.3 + 1.2 * NeferhooStaging.hash(i + 9);
      final sway = (14 + 16 * NeferhooStaging.hash(i + 7)) * math.sin(freq * t + i * 1.9) * (1 - math.exp(-t / .5)) * k;
      final fall = (52 + 34 * NeferhooStaging.hash(i + 11)) * (t - .45 * (1 - math.exp(-t / .45))) * k;
      final x = origin.dx + v.dx * drag + sway;
      var y = origin.dy + v.dy * drag + fall;
      final ground = (288 + 36 * NeferhooStaging.hash(i + 13)) * k;
      var tilt = math.sin(freq * t + i * 1.9 + 1.3) * .9 + 5.5 * NeferhooStaging.hash(i + 1) * math.exp(-t / .6);
      var squash = 1.0;
      if (y >= ground) {
        y = ground;
        tilt = 1.2 * NeferhooStaging.hash(i + 21) - .6;
        squash = .45;
      }
      NeferhooStaging.miniLetter(c, Offset(x, y), (24 + 9 * NeferhooStaging.hash(i + 17)) * k, tilt: tilt, alpha: a * show, squash: squash);
    }
  }

  /// The golden mask: it pops from [head], tumbles in a high arc with a glint
  /// whenever it turns to the sun, lands on the dune, bounces twice and rocks
  /// to rest (it fades with the rest of him). Under Reduced Motion it lies at
  /// rest where it lands from the pop on.
  static void _mask(Canvas c, double d, Offset head, double u, double k, bool reduced) {
    if (d < pop) return;
    final tau = reduced ? 3.0 : d - pop;
    const g = 520.0, landT = 1.34, vx = -96.0, vy = -215.0;
    // (the dune above the letterbox's bottom bar, which the design did not
    // have: the mask rests clear of it)
    final groundY = 302 * k;
    double x, y;
    var squash = 1.0;
    if (tau < landT) {
      x = head.dx + vx * tau * k;
      y = head.dy + (vy * tau + .5 * g * tau * tau) * k;
    } else {
      final f = tau - landT;
      x = head.dx + vx * landT * k + vx * .22 * (1 - math.exp(-f / .5)) * k;
      const h1 = .62, h2 = .3;
      if (f < h1) {
        final s = f / h1;
        y = groundY - 4 * 30 * s * (1 - s) * k;
      } else if (f < h1 + h2) {
        final s = (f - h1) / h2;
        y = groundY - 4 * 7 * s * (1 - s) * k;
      } else {
        y = groundY;
      }
      if (f < .09) squash = 1 - .16 * math.sin(f / .09 * math.pi);
    }
    y = math.min(y, groundY);
    final spin = .5 - 6 * math.pi * (1 - NeferhooStaging.outCubic(tau / 1.55));
    final rock = tau > landT ? .1 * math.exp(-(tau - landT) * 3) * math.sin(18 * (tau - landT)) : 0.0;
    final ang = spin + rock;
    const fade = 1.0;
    if (y > groundY - 60 * k) {
      final s = (1 - (groundY - y) / (60 * k)).clamp(0.0, 1.0);
      c.drawOval(
        Rect.fromCenter(center: Offset(x + 6 * k, groundY + 20 * k), width: (70 + 20 * s) * k, height: (9 + 4 * s) * k),
        NeferhooStaging.fill(NeferhooPalette.ink, .22 * s * fade),
      );
    }
    c.save();
    c.translate(x, y);
    c.scale(1, squash);
    c.rotate(ang);
    c.scale(u * .7);
    NeferhooPainter(c, NeferhooPose(crest: 0)).paintMaskOnly();
    c.restore();
    if (reduced) return;
    final gl = math.pow(math.max(0.0, math.cos(ang - 1.1)), 9).toDouble() * (tau < landT + .3 ? 1.0 : .55 + .45 * math.sin(d * 7));
    if (gl > .05) {
      final p = Offset(x, y) + Offset(math.cos(ang - .6), math.sin(ang - .6)) * 26 * k;
      NeferhooStaging.star(c, p, (8 + 24 * gl) * k, alpha: gl * fade, rot: ang * .2);
    }
    // Landing: sand thrown up, three times smaller each hop.
    for (final (lt, big) in const [(landT, 1.0), (landT + .62, .5), (landT + .92, .25)]) {
      final f = _ramp(tau, lt, lt + .55);
      if (f > 0 && f < 1) {
        final lx = head.dx + vx * landT * k;
        for (var i = 0; i < 5; i++) {
          final s = i.isEven ? -1.0 : 1.0;
          NeferhooStaging.dustPuff(
            c,
            Offset(lx + s * (14 + 22 * f * (1 + i * .25)) * big * k, groundY + (12 - 12 * f * big - i % 2 * 5) * k),
            (7 + 14 * f) * big * k,
            (1 - f) * .85,
          );
        }
      }
    }
  }

  /// A comic beat: one of his dead letters drops onto his head and sits
  /// there like a tiny hat while he looks up at the lost one, then slides
  /// off. (Reduced Motion: it is simply there, and fades.)
  static void _hatLetter(Canvas c, double d, ({Offset at, double scale}) b, NeferhooPose p, double u, double k, bool reduced) {
    if (d < 1.72 || d > 3.5) return;
    final f = _ramp(d, 1.72, 2.0);
    final bounce = reduced
        ? 1.0
        : f < .7
        ? 1 - math.pow(1 - f / .7, 2).toDouble()
        : 1 - .1 * math.sin((f - .7) / .3 * math.pi);
    final off = reduced ? 0.0 : _ramp(d, 3.0, 3.5);
    final top = rigPoint(const Offset(-1.15, -2.25), b.at, u * b.scale, p);
    final o = top + Offset(off * 34 * k, (-70 * (1 - bounce) + off * off * 90) * k);
    final a = (reduced ? _smooth(_ramp(d, 1.72, 2.0)) : 1.0) * (1 - _smooth(_ramp(d, 3.2, 3.6)));
    NeferhooStaging.miniLetter(c, o, 30 * k, tilt: -.32 + off * 1.6 + (f < 1 && !reduced ? .5 * (1 - f) : 0), alpha: a);
  }

  /// The pop: a gold ring, linen and gold streaks and a flare at the head,
  /// and a soft white flash.
  static void _popFx(Canvas c, Size size, double d, Offset head, double k) {
    if (d < pop) return;
    final f = _ramp(d, pop, pop + .5);
    if (f >= 1) return;
    c.drawCircle(head, (10 + 96 * NeferhooStaging.outCubic(f)) * k, NeferhooStaging.line(NeferhooPalette.goldLit, (5 * (1 - f) + .5) * k, 1 - f));
    c.drawCircle(head, (6 + 60 * NeferhooStaging.outCubic(f)) * k, NeferhooStaging.line(NeferhooStaging.glint, 2 * (1 - f) * k, .8 * (1 - f)));
    final gold = Path(), linen = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + .3;
      final d0 = Offset(math.cos(a), math.sin(a));
      final r0 = (20 + 30 * f) * k, r1 = (30 + 80 * NeferhooStaging.outCubic(f)) * k;
      (i.isEven ? gold : linen)
        ..moveTo(head.dx + d0.dx * r0, head.dy + d0.dy * r0)
        ..lineTo(head.dx + d0.dx * r1, head.dy + d0.dy * r1);
    }
    c.drawPath(gold, NeferhooStaging.line(NeferhooPalette.goldHi, (2.4 * (1 - f) + .5) * k, 1 - f));
    c.drawPath(linen, NeferhooStaging.line(NeferhooPalette.linenHi, (2.4 * (1 - f) + .5) * k, 1 - f));
    NeferhooStaging.star(c, head, 36 * k * math.sin(math.min(1.0, f * 1.6) * math.pi));
    final flash = 1 - _ramp(d, pop, pop + .35);
    if (flash > 0) c.drawRect(Offset.zero & size, NeferhooStaging.fill(NeferhooStaging.glint, .45 * flash * flash));
  }

  /// The lost letter's flare, 0..1..0 over 3.12-3.62 s after the blow: it
  /// swells once as its chime rings (`NeferhooAudioCues.lostLetterAt`, 3.2 s,
  /// after the victory stinger).
  static double lostLetterFlare(double d) {
    if (d <= 3.12 || d >= 3.62) return 0;
    final s = math.sin((d - 3.12) / .5 * math.pi);
    return s * s;
  }

  /// The lost letter rises out of the [satchel] along a lazy S, floats free
  /// above where he was and glows, bobbing (it fades with the rest of him,
  /// after one last flare as its chime rings).
  static void _lostLetter(Canvas c, double d, Offset satchel, Offset at0, double k, bool reduced) {
    if (d < .95) return;
    final float = at0 + Offset(-70 * k, -17 * k);
    final f = reduced ? 1.0 : _smooth(_ramp(d, .95, 1.95));
    final from = satchel + Offset(0, -10 * k);
    final mid = Offset((from.dx + float.dx) / 2 + 26 * k, from.dy - 70 * k);
    final p = Offset(
      (1 - f) * (1 - f) * from.dx + 2 * (1 - f) * f * mid.dx + f * f * float.dx,
      (1 - f) * (1 - f) * from.dy + 2 * (1 - f) * f * mid.dy + f * f * float.dy,
    );
    final bob = reduced ? Offset.zero : Offset(math.sin(d * 1.7) * 3, math.sin(d * 2.6) * 4) * f * k;
    final w = (22 + 40 * (reduced ? 1.0 : _smooth(_ramp(d, 1.0, 2.0)))) * k * (1 + (reduced ? 0 : .3 * lostLetterFlare(d)));
    const fade = 1.0;
    final o = p + bob;
    // A local dusk round it, so its light reads on the bright sky.
    final spot = (reduced ? 1.0 : _smooth(_ramp(d, 1.2, 2.0))) * fade;
    if (spot > 0) {
      c.drawCircle(
        o,
        150 * k,
        NeferhooStaging.grad(
          NeferhooStaging.rad(o, 150 * k, [
            NeferhooStaging.night.withValues(alpha: .38),
            NeferhooStaging.night.withValues(alpha: .16),
            const Color(0x00171c39),
          ], const [0, .6, 1]),
          spot,
        ),
      );
    }
    final clock = reduced ? 1.6 : d;
    NeferhooStaging.lostLetterGlow(
      c,
      o,
      w,
      (c, o, w, tilt, alpha, phase) => NeferhooPropsArt.lostLetter(c, o, w, tilt: tilt, glow: 0, alpha: alpha, phase: phase),
      tilt: -.5 + .35 * f + (reduced ? 0 : .06 * math.sin(d * 1.9)),
      glow: reduced ? 1.0 : _smooth(_ramp(d, 1.1, 2.0)),
      t: clock,
      alpha: fade,
    );
  }

  /// The victory card (called from the shared victory's slot): his own.
  static void victory(Canvas c, Size size, BossMotion m) => NeferhooEncounterUi.victory(c, size, m);
}
