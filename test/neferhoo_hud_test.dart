import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_stage_hud_art.dart';
import 'package:push_up_bird/game/neferhoo_hud_art.dart';
import 'package:push_up_bird/game/neferhoo_kit.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'neferhoo_stage_support.dart';
import 'proof/counting_canvas.dart';

/// Neferhoo's health strip (A2, design §5.7, in family with the shipped
/// guardians' plates and the staged system's `BossStageHudArt`): his lapis
/// cartouche in a gold rim, the mask medallion, a gold-leaf gauge that turns
/// turquoise in fury, cut in thirds: the stage gem at two thirds in his gold,
/// the fury mark at a third his carnelian wax seal that cracks; the shared
/// STRONGER! card; a frame inside the strip's budget.

const _size640 = ui.Size(640, 360);

/// A real 2-6 flight [combat] seconds into the fight (the bird parked and
/// kept safe), on a screen [width] px wide.
FlightSimulation _fight(double combat, {double width = 640}) {
  final sim = neferhooArrival(width: width / 360);
  while (sim.boss!.age < sim.boss!.arrivalDuration + combat) {
    sim
      ..birdY = .5
      ..invulnerableUntil = sim.elapsed + 1;
    frame(sim, width: width / 360);
  }
  return sim;
}

/// Lands one rock on him at [hp] health and steps [seconds].
void _strike(FlightSimulation sim, int hp, {double seconds = .5, double width = 640}) {
  final boss = sim.boss!;
  boss.hp = hp;
  sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    sim
      ..birdY = .5
      ..invulnerableUntil = sim.elapsed + 1;
    frame(sim, width: width / 360);
  }
}

Future<Uint8List> _strip(SkyBoss boss, {bool reduced = false, ui.Size size = _size640}) =>
    raster((c) => BossHealthBarArt.paint(c, size, boss, reducedMotion: reduced), size.width, 80);

/// The colour at [p] of an RGBA raster [w] wide.
ui.Color _at(Uint8List a, int w, ui.Offset p) {
  final i = (p.dy.round() * w + p.dx.round()) * 4;
  return ui.Color.fromARGB(a[i + 3], a[i], a[i + 1], a[i + 2]);
}

bool _blue(ui.Color c) => c.b > c.r + .15 && c.b > c.g + .05;
bool _gold(ui.Color c) => c.r > .7 && c.g > .45 && c.b < .5 && c.r > c.b + .3;
bool _turquoise(ui.Color c) => c.g > .55 && c.b > .5 && c.r < .55;
bool _carnelian(ui.Color c) => c.r > .6 && c.g < .5 && c.b < .45;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  test('his plate is a lapis cartouche, not the shared night strip', () async {
    final boss = _fight(1).boss!;
    final strip = BossHealthBarArt.bounds(_size640, boss);
    final bytes = await _strip(boss);
    // Most of the plate is lapis.
    var blue = 0, all = 0;
    for (var y = strip.top.ceil(); y < strip.bottom.floor(); y++) {
      for (var x = strip.left.ceil(); x < strip.right.floor(); x++) {
        all++;
        if (_blue(_at(bytes, 640, ui.Offset(x.toDouble(), y.toDouble())))) blue++;
      }
    }
    expect(blue / all, greaterThan(.35), reason: 'lapis share ${blue / all}');
    // The rim is gold.
    var rim = 0;
    for (var x = strip.left + 20; x < strip.right - 20; x += 4) {
      // (thin at 1x: a warm line over the lapis)
      final c = _at(bytes, 640, ui.Offset(x, strip.top + 1.2));
      if (c.r > c.b + .15) rim++;
    }
    expect(rim, greaterThan(((strip.width - 40) / 4) * .6), reason: 'the gold rim');
  });

  test('the gauge is gold leaf; in fury it turns turquoise and the seal cracks', () async {
    final sim = _fight(1);
    final boss = sim.boss!;
    final bar = BossHealthBarArt.track(_size640, boss);
    final calm = await _strip(boss);
    final fillAt = ui.Offset(bar.left + 6, bar.center.dy);
    expect(_gold(_at(calm, 640, fillAt)), isTrue, reason: '${_at(calm, 640, fillAt)}');
    // The fury mark at a third is the carnelian wax seal.
    final seal = ui.Offset(bar.left + bar.width * boss.stageMarks.last, bar.center.dy - .6);
    final wax = seal + const ui.Offset(-2.6, 0);
    expect(_carnelian(_at(calm, 640, wax)), isTrue, reason: '${_at(calm, 640, wax)}');
    _strike(sim, boss.maxHp ~/ 3 + 1, seconds: 1.0);
    expect(boss.enraged, isTrue);
    final fury = await _strip(boss);
    expect(_turquoise(_at(fury, 640, fillAt)), isTrue, reason: '${_at(fury, 640, fillAt)}');
    // Split: turquoise light where the seal's middle was.
    expect(_turquoise(_at(fury, 640, seal - const ui.Offset(0, 3))) || _at(fury, 640, seal - const ui.Offset(0, 3)).g > .7, isTrue,
        reason: '${_at(fury, 640, seal - const ui.Offset(0, 3))}');
    expect(changed(calm, fury), greaterThan(400));
  });

  test('cut in thirds: his gold stage gem at two thirds snaps; STRONGER! drops with the stage hint', () async {
    final sim = _fight(1);
    final boss = sim.boss!;
    expect(boss.staged, isTrue);
    expect(boss.stageMarks, [2 / 3, 1 / 3]);
    expect(BossStageHudArt.metal(BossKind.neferhoo), NeferhooHudArt.stageMetal);
    final before = await _strip(boss);
    _strike(sim, boss.maxHp * 2 ~/ 3 + 1, seconds: .6);
    expect(boss.stage, 1);
    expect(boss.stageHint, isNotNull);
    final after = await raster((c) => BossHealthBarArt.paint(c, _size640, boss), 640, 80);
    // The STRONGER! card hangs below the strip.
    final strip = BossHealthBarArt.bounds(_size640, boss);
    var below = 0;
    for (var y = strip.bottom.ceil() + 2; y < 70; y++) {
      for (var x = 0; x < 640; x++) {
        if (after[(y * 640 + x) * 4 + 3] > 0 && before[(y * 640 + x) * 4 + 3] == 0) below++;
      }
    }
    expect(below, greaterThan(800), reason: 'the STRONGER! card');
  });

  test('a frame stays inside the strip\'s budget in every state: <= 60 draws, 0 layers, 0 clips, no blur', () {
    final sim = _fight(1);
    final boss = sim.boss!;
    void check(String state, {bool reduced = false}) {
      for (var pass = 0; pass < 2; pass++) {
        final c = Counting(ui.Canvas(ui.PictureRecorder()));
        BossHealthBarArt.paint(c, _size640, boss, reducedMotion: reduced);
        if (pass == 0) continue; // the first frame records the plate
        expect(c.draws, lessThanOrEqualTo(60), reason: '$state: ${c.counts}');
        expect(c.layers, 0, reason: state);
        // (the shared STRONGER! card clips its drop; his own pieces never clip)
        expect(c.clips, lessThanOrEqualTo(state == 'stronger' ? 1 : 0), reason: state);
        expect(c.blurs, 0, reason: state);
      }
    }

    check('calm');
    check('calm, reduced', reduced: true);
    // (a chip in the warm-up: five sixths of his health, clear of the stage
    // line at two thirds whatever his campaign health)
    _strike(sim, boss.maxHp * 5 ~/ 6, seconds: .1);
    expect(boss.stage, 0);
    check('hit (chip)');
    _strike(sim, boss.maxHp * 2 ~/ 3 + 1, seconds: .4);
    check('stronger');
    _strike(sim, boss.maxHp ~/ 3 + 1, seconds: .3);
    check('fury onset');
    _strike(sim, 30, seconds: .5);
    check('critical');
  });

  test('his name fits the name field, and his pieces are his own', () {
    final p = TextPainter(
      text: TextSpan(text: 'NEFERHOO', style: heading(10).copyWith(letterSpacing: .5)),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(p.width, lessThanOrEqualTo(84));
    final boss = _fight(.5).boss!;
    expect(BossHealthBarArt.accent(boss), NeferhooHudArt.ramp[1]);
    expect(NeferhooHudArt.ramp[1], NeferhooPalette.gold);
    expect(NeferhooHudArt.furyRamp[1], NeferhooPalette.turq);
  });

  test('pure: the same state paints the same strip, at 640, 800 and 864', () async {
    for (final w in const [640.0, 800.0, 864.0]) {
      final boss = _fight(1.3, width: w).boss!;
      final size = ui.Size(w, 360);
      final a = await _strip(boss, size: size);
      final b = await _strip(boss, size: size);
      expect(changed(a, b, tolerance: 0), 0, reason: '$w');
    }
  });

  test('the medallion is his mask: different in fury (the eye lit), never a crown', () async {
    final calm = await raster((c) => NeferhooHudArt.crest(c, const ui.Offset(30, 30), 20, 1, fury: false), 60, 60);
    final fury = await raster((c) => NeferhooHudArt.crest(c, const ui.Offset(30, 30), 20, 1, fury: true), 60, 60);
    expect(changed(calm, fury), greaterThan(20));
    final shared = await raster((c) => BossHealthBarArt.emblem(c, const ui.Offset(30, 30), 20, 1, BossKind.neferhoo), 60, 60);
    expect(changed(calm, shared), 0, reason: 'the vanguard plate\'s emblem is the same medallion');
  });
}
