import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/king_coo_crumb_art.dart';

import 'king_coo_helpers.dart' as rules;
import 'king_coo_test_kit.dart';

/// The two hooks `ny-ws/patches/k5-crumbs.patch` adds to
/// `BossEncounterArt` (`backdrop`: `KingCooCrumbArt.under`; `paint`:
/// `KingCooCrumbArt.flight`), exercised through the game's own entry points
/// (`BossArt.backdrop` and `BossArt.paint`) in a REAL flight: the effects
/// that appear are the rules' lobs, where the rules put them, and nothing
/// else in the frame changes.
///
/// Needs the patch; K8 (staging) keeps the two lines wherever it moves them.
const _h = 360.0;
const _w = 640.0;

Future<Uint8List> frame(void Function(Canvas c) draw) =>
    rawPixels(_w.round(), _h.round(), draw);

/// The pixels that differ between [a] and [b], as a mask.
List<bool> changed(Uint8List a, Uint8List b) => [
  for (var i = 0; i < a.length; i += 4)
    (a[i] - b[i]).abs() +
            (a[i + 1] - b[i + 1]).abs() +
            (a[i + 2] - b[i + 2]).abs() +
            (a[i + 3] - b[i + 3]).abs() >
        40,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const rPx = KingCoo.cloudRadius * _h;

  test('the backdrop slot draws the ring where the rules locked it', () async {
    final sim = rules.cooFight(width: _w / _h);
    final boss = sim.boss!;
    rules.runTo(sim, 1.4, hold: .4, protect: true);
    final lob = boss.lobs.single;
    expect(boss.liveLobs, [lob]);
    const size = Size(_w, _h);
    final withLob = await frame((c) => BossArt.backdrop(c, size, boss, false));
    final saved = [...boss.lobs];
    boss.lobs.clear();
    final without = await frame((c) => BossArt.backdrop(c, size, boss, false));
    boss.lobs.addAll(saved);
    final mask = changed(withLob, without);
    final centre = Offset(lob.lockX * _h, lob.lockY * _h);
    var far = 0.0, n = 0;
    for (var i = 0; i < mask.length; i++) {
      if (!mask[i]) continue;
      n++;
      final d =
          (Offset(i % _w.round() + .5, i ~/ _w.round() + .5) - centre).distance;
      if (d > far) far = d;
    }
    expect(n, greaterThan(500), reason: 'a ring was drawn');
    expect(
      far,
      lessThanOrEqualTo(rPx + 1.0),
      reason: 'never past the radius that hurts',
    );
    expect(far, greaterThanOrEqualTo(rPx - 1.5), reason: 'and reaching it');
  });

  test('the boss pass draws the roll leaving his wing, over him', () async {
    final sim = rules.cooFight(width: _w / _h);
    final boss = sim.boss!;
    rules.runTo(sim, 1.43, hold: .4, protect: true);
    final lob = boss.lobs.single;
    expect(boss.age - lob.launchAt, inInclusiveRange(0, .05));
    const size = Size(_w, _h);
    final m = BossMotion(boss, reducedMotion: true);
    // K8: the stage paints the figure itself now (and he winds up with the
    // lob), so the roll is judged on its own pass and then in the boss's.
    final only = await frame((c) => KingCooCrumbArt.flight(c, size, boss, m));
    final full = await frame(
      (c) => BossArt.paint(c, size, sim, reducedMotion: true),
    );
    final from = KingCooCrumbArt.release(boss, m, lob);
    // What the roll's own pass draws lies along its arc (its dotted path and
    // its crumbs), and the roll itself is at the wing tip.
    final to = Offset(lob.lockX, lob.lockY);
    final path = [
      for (var i = 0; i <= 200; i++)
        KingCooCrumbArt.arc(from, to, i / 200) * _h,
    ];
    var n = 0, near = 0, off = 0, hidden = 0, solid = 0;
    for (var i = 0; i < only.length; i += 4) {
      if (only[i + 3] == 0) continue;
      n++;
      final px = i ~/ 4;
      final p = Offset(px % _w.round() + .5, px ~/ _w.round() + .5);
      var d = double.infinity;
      for (final q in path) {
        final e = (p - q).distance;
        if (e < d) d = e;
      }
      if (d > 18) off++;
      if ((p - from * _h).distance < .06 * _h) near++;
      // Over him: wherever the roll is opaque, the boss pass shows it.
      if (only[i + 3] >= 250) {
        solid++;
        if ((full[i] - only[i]).abs() +
                (full[i + 1] - only[i + 1]).abs() +
                (full[i + 2] - only[i + 2]).abs() >
            12) {
          hidden++;
        }
      }
    }
    expect(n, greaterThan(150), reason: 'the roll was drawn');
    expect(near, greaterThan(100), reason: 'at the wing tip');
    expect(off, 0, reason: 'nothing but the roll, its arc and its crumbs');
    expect(solid, greaterThan(80));
    expect(hidden, 0, reason: 'the boss pass draws the roll over the figure');
  });

  test(
    'fury in a real flight: two rings and the corridor between them',
    () async {
      final sim = rules.cooFight(width: _w / _h);
      final boss = sim.boss!;
      boss.hp = KingCoo.furyHp;
      rules.runTo(sim, 1.4, hold: .5, protect: true);
      final lob = boss.lobs.single;
      expect(lob.fury, isTrue);
      expect(lob.cloudHeights, hasLength(2));
      const size = Size(_w, _h);
      final withLob = await frame(
        (c) => BossArt.backdrop(c, size, boss, false),
      );
      final saved = [...boss.lobs];
      boss.lobs.clear();
      final without = await frame(
        (c) => BossArt.backdrop(c, size, boss, false),
      );
      boss.lobs.addAll(saved);
      final mask = changed(withLob, without);
      for (final y in lob.cloudHeights) {
        final centre = Offset(lob.lockX * _h, y * _h);
        var far = 0.0;
        for (var i = 0; i < mask.length; i++) {
          if (!mask[i]) continue;
          final p = Offset(i % _w.round() + .5, i ~/ _w.round() + .5);
          final d = (p - centre).distance;
          if (d < rPx + 9 && d > far) far = d;
        }
        expect(far, closeTo(rPx, 1.3), reason: 'a ring at $y');
      }
      // The corridor: changed pixels between the rings, on the bird's column.
      final lane = KingCooCrumbArt.corridor(lob)!;
      var between = 0;
      for (var y = (lane.$1 * _h).round(); y < (lane.$2 * _h).round(); y++) {
        for (var x = 100; x < 240; x++) {
          if (mask[y * _w.round() + x]) between++;
        }
      }
      expect(between, greaterThan(200), reason: 'the corridor is drawn');
    },
  );
}
