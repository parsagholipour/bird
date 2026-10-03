// M1 (Egypt integration): Neferhoo's fight art inside the REAL game frame.
// A1 drew the letters, the lane and the ankh on the rules' geometry (tested
// on their own canvas); A2 put his rig in the encounter and calls A1's
// `NeferhooFightArt.over` right after it and `NeferhooBossRig.prewarm` on the
// arrival's first frame; R1's rules latch what is drawn. Here a real 2-6
// flight is rendered by `BirdGame` itself (backdrop, encounter, bird, HUD
// strip): each letter in flight is on screen exactly over the rules'
// rectangle, a fight frame records no picture once the arrival has warmed
// the caches, and the hint tags never sit under the HUD's hearts plate.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/neferhoo_fight_art.dart';
import 'package:push_up_bird/game/neferhoo_kit.dart';

import 'neferhoo_stage_support.dart';

/// Pixels that differ between two frames, as a mask.
List<bool> _diff(Uint8List a, Uint8List b) => [
  for (var i = 0; i < a.length; i += 4)
    (a[i] - b[i]).abs() + (a[i + 1] - b[i + 1]).abs() + (a[i + 2] - b[i + 2]).abs() > 24,
];

/// The share of [r] (px) whose pixels changed.
double _cover(List<bool> mask, int w, ui.Rect r) {
  var n = 0, all = 0;
  for (var y = r.top.ceil(); y < r.bottom.floor(); y++) {
    for (var x = r.left.ceil(); x < r.right.floor(); x++) {
      all++;
      if (mask[y * w + x]) n++;
    }
  }
  return all == 0 ? 0 : n / all;
}

/// The classic clock's beats are scripted here (12 s cycles, the gag's room,
/// the hint and lane moments): rules 54, the last rules on that clock. The
/// faster clock (rules 55) has its own checks (`neferhoo_faster_art_test`).
const _classic = FlightSimulation.cooRestartRulesVersion;

void main() {
  setUpAll(loadFonts);

  for (final px in [640.0, 800.0]) {
    testWidgets('${px.round()} px: the game draws every letter in flight on the rules\' rectangle', (tester) async {
      final stage = await neferhooStage(tester, px, version: _classic);
      final boss = stage.boss;
      // the mail call locks on the bird; it then leaves the lane so the
      // letters fly past it
      stage.birdY = .46;
      stage.fightTo(12.7);
      stage.birdY = .8;
      var checked = 0;
      for (final t in [13.9, 14.5, 15.1]) {
        stage.fightTo(t);
        final letters = boss.liveLetters.where((l) => !l.returned).toList();
        expect(letters, isNotEmpty, reason: 'letters in flight at $t');
        final full = await tester.runAsync(() async => rgba(await stage.render()));
        final keep = boss.neferhoo.letters.toList();
        boss.neferhoo.letters.removeWhere(letters.contains);
        final bare = await tester.runAsync(() async => rgba(await stage.render()));
        boss.neferhoo.letters
          ..clear()
          ..addAll(keep);
        final mask = _diff(full!, bare!);
        for (final letter in letters) {
          final r = NeferhooFightArt.letterRect(letter, boss, 360);
          if (r.left < 2 || r.right > px - 2) continue;
          // its body covers the rules' rectangle (a pixel in from each edge)...
          expect(_cover(mask, px.round(), r.deflate(2)), greaterThan(.9), reason: '${px.round()} px t $t: the letter at $r');
          // ...and nothing of it lies above or below the rules' band
          // (the speed whiskers trail behind it, to the right)
          final above = ui.Rect.fromLTRB(r.left, math.max(0, r.top - 14), r.right, r.top - 2);
          final below = ui.Rect.fromLTRB(r.left, r.bottom + 2, r.right, math.min(360, r.bottom + 14));
          expect(_cover(mask, px.round(), above), lessThan(.04), reason: '${px.round()} px t $t: ink above $r');
          expect(_cover(mask, px.round(), below), lessThan(.04), reason: '${px.round()} px t $t: ink below $r');
          checked++;
        }
      }
      expect(checked, greaterThanOrEqualTo(4));
    });
  }

  testWidgets('the arrival warms his caches: no fight frame records a picture', (tester) async {
    final stage = await neferhooStage(tester, 800, version: _classic);
    // the arrival's first frame (A2 calls the rig's and the stage's prewarm)
    await tester.runAsync(() async => (await stage.render()).dispose());
    stage.runTo(1.0);
    await tester.runAsync(() async => (await stage.render()).dispose());
    var recorded = 0;
    final where = <String>[];
    NeferhooKit.debugWrap = (c) {
      recorded++;
      where.add('${stage.boss.combatTime.toStringAsFixed(2)} s: ${StackTrace.current.toString().split('\n').skip(1).take(8).map((l) => l.replaceAll(RegExp(r'\s+'), ' ')).join(' <- ')}');
      return c;
    };
    addTearDown(() => NeferhooKit.debugWrap = null);
    final boss = stage.boss;
    Future<void> at(List<double> ts) async {
      for (final t in ts) {
        stage.fightTo(t);
        await tester.runAsync(() async => (await stage.render()).dispose());
      }
    }

    // the warm-up's mail call; the full fight (the stage-up roar, the ankh);
    // fury (the express post, two ankhs); a letter sent home and landing
    await at([.5, 2.0, 6.0, 7.5, 13.9]);
    boss.takeDamage(boss.hp - boss.maxHp * 2 ~/ 3);
    await at([14.5, 17.6, 19.0, 20.5, 25.9]);
    final letter = boss.liveLetters.firstWhere((l) => !l.returned);
    stage.sim.rocks.add(BirdRock(x: letter.xAt(boss.age, boss.handX) - .08, y: letter.lane));
    await at([26.1, 26.4, 26.9, 27.4]);
    expect(boss.neferhoo.returnsLanded, greaterThan(0));
    boss.takeDamage(boss.hp - boss.maxHp ~/ 3);
    await at([28, 37.9, 42.3, 43.5]);
    expect(boss.enraged, isTrue);
    expect(boss.neferhoo.ankhs.where((a) => a.second), isNotEmpty);
    expect(recorded, 0, reason: 'a fight frame built a cached picture: ${where.join('\n')}');
  });
}
