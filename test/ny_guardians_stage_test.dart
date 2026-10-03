import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_art.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/gargoyle_encounter_art.dart';
import 'package:push_up_bird/game/gargoyle_encounter_ui.dart';
import 'package:push_up_bird/game/gargoyle_story_art.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_encounter_ui.dart';
import 'package:push_up_bird/game/king_coo_pose.dart' show KingCooMood;
import 'package:push_up_bird/game/king_coo_staging_art.dart';
import 'package:push_up_bird/game/king_coo_story_art.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/level_result.dart';
import 'package:push_up_bird/ui/story_boss_art.dart';

import 'campaign_flight.dart' show flyLevel;
import 'king_coo_helpers.dart' as rules;
import 'king_coo_test_kit.dart' show loadFonts, rawPixels;
import 'ny_plans.dart';

/// King Coo and the Searchlight Gargoyle in ONE tree (the integration of K8
/// and G8): each one's staging was built and tested alone on the same base, so
/// this file holds what only the merge can break.
///
///  * a frame sequence per guardian (the catalog's 3-2 and 3-4, flown with the
///    real rules, rendered by the real `BirdGame`) whose boss pass is the
///    guardian's OWN entry point byte for byte and never the Baron's
///    fall-through, whatever came before it in the process;
///  * one wording for every guardian (the card's word, the victory title, the
///    result screen's) and one letterbox;
///  * both name cards carry the campaign's line;
///  * both story adapters and both keepsakes in the shared `StoryBossArt` /
///    `CampaignHeadwear`;
///  * the squadron pigeons (King Coo) against the Gargoyle's feathers and
///    beams: each boss's layering is keyed on its own kind and the two never
///    reach the other's frame.

// ------------------------------------------------------------ the stage --

/// A real flight of a catalog level with its guardian on stage, stepped at
/// 120 Hz with the bird hovering at the middle, never hurt.
class _Stage {
  _Stage._(this.sim, this.game, this.width, this.reduced);

  final FlightSimulation sim;
  final BirdGame game;
  final double width;
  final bool reduced;

  SkyBoss get boss => sim.boss!;
  double get aspect => width / 360;
  Size get size => Size(width, 360);

  /// The catalog's [levelId] flown to the first instant of its guardian.
  factory _Stage.open(String levelId, double width, {bool reduced = false}) {
    final sim = nyFlight(Campaign.level(levelId)!.plan, weaponDamage: 10);
    flyLevel(sim, viewportWidth: width / 360, until: (s) => s.boss != null);
    sim.rocks.clear();
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: reduced,
      playback: true,
      onChanged: () {},
    )..onGameResize(Vector2(width, 360));
    return _Stage._(sim, game, width, reduced);
  }

  void toAge(double age) => rules.run(
    sim,
    1000,
    width: aspect,
    hold: .5,
    protect: true,
    until: (s) => s.boss == null || s.boss!.age >= age - 1e-9,
  );

  /// Runs to [t] seconds into the fight (the arrival is 4.6 s).
  void toCombat(double t) => toAge(boss.arrivalDuration + t);

  /// A rock of [damage] on his heart, stepped in.
  void hit(int damage) {
    sim.rocks.add(
      BirdRock(
        x: boss.x - (boss.isGargoyle ? .12 : .07),
        y: boss.y,
        damage: damage,
      ),
    );
    rules.run(sim, 1 / 120, width: aspect, hold: .5, protect: true);
  }

  /// Runs until [done] (never past [limit] seconds).
  void until(bool Function(FlightSimulation s) done, {double limit = 30}) =>
      rules.run(
        sim,
        limit,
        width: aspect,
        hold: .5,
        protect: true,
        until: (s) => s.boss == null || done(s),
      );

  /// One frame of the whole game.
  Future<Uint8List> frame() async {
    final recorder = ui.PictureRecorder();
    game.render(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    final data = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
    return Uint8List.fromList(data);
  }

  /// One of the encounter's three passes ('backdrop', 'paint', 'foreground')
  /// as [boss] draws it on a transparent canvas, in the real game's order of
  /// calls (through `BossArt` the way `BirdGame` makes them), the simulation
  /// holding [boss] while it does.
  Future<Uint8List> pass(String which, {SkyBoss? boss}) {
    final b = boss ?? this.boss;
    final saved = sim.boss;
    sim.boss = b;
    return rawPixels(width.toInt(), 360, (c) {
      switch (which) {
        case 'backdrop':
          BossArt.backdrop(c, size, b, reduced);
        case 'paint':
          BossArt.paint(c, size, sim, reducedMotion: reduced);
        case 'foreground':
          BossArt.foreground(c, size, sim, reduced);
      }
    }).whenComplete(() => sim.boss = saved);
  }
}

/// The same instant as [b] with another kind on stage: where the Baron's
/// fall-through would draw.
SkyBoss _as(SkyBoss b, BossKind kind) =>
    SkyBoss(number: 1, x: b.x, kind: kind, cinematic: true)
      ..y = b.y
      ..age = b.age
      ..defeatedAt = b.defeatedAt
      ..fireIn = 5;

int _differ(Uint8List a, Uint8List b) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (a[i] != b[i] ||
        a[i + 1] != b[i + 1] ||
        a[i + 2] != b[i + 2] ||
        a[i + 3] != b[i + 3]) {
      n++;
    }
  }
  return n;
}

int _opaque(Uint8List p) {
  var n = 0;
  for (var i = 3; i < p.length; i += 4) {
    if (p[i] > 8) n++;
  }
  return n;
}

bool _same(Uint8List a, Uint8List b) => _differ(a, b) == 0;

/// One beat of a guardian's encounter: the label, the boss's age and the
/// frames (the whole game and the boss pass alone).
class _Beat {
  _Beat(this.label, this.age, this.game, this.paint, this.defeat);
  final String label;
  final double age;
  final Uint8List game, paint;
  final bool defeat;
}

/// King Coo's whole encounter at [width]: arrival, a calm lob, a hit that
/// carries him into fury, the puff, the whistle with the squadron still at
/// his back and out in the open, and the killing blow, the defeat, the
/// victory card.
Future<List<_Beat>> _kingSequence(
  double width, {
  bool reduced = false,
  _Stage? into,
}) async {
  final s = into ?? _Stage.open('3-2', width, reduced: reduced);
  final beats = <_Beat>[];
  Future<void> snap(String label) async => beats.add(
    _Beat(
      label,
      s.boss.age,
      await s.frame(),
      await s.pass('paint'),
      s.boss.defeatedAt != null,
    ),
  );
  for (final age in const [.3, 1.2, 1.75, 2.05, 2.5, 2.8, 3.4, 4.2]) {
    s.toAge(age);
    await snap('arrival $age');
  }
  for (final t in const [1.0, 2.6]) {
    s.toCombat(t);
    await snap('fight $t');
  }
  s.toCombat(3.0);
  s.hit(150);
  await snap('hit');
  expect(s.boss.enraged, isTrue, reason: 'the hit carries him into fury');
  s.toCombat(3.6);
  await snap('fury');
  s.toCombat(7.9);
  await snap('puffed');
  // The whistle: the first instant a squadron pigeon is still at his back...
  s.until(
    (x) => x.enemies.any((e) => KingCooStaging.squadBehind(x.boss, e, 360)),
  );
  expect(
    s.sim.enemies.any((e) => KingCooStaging.squadBehind(s.boss, e, 360)),
    isTrue,
    reason: 'a squadron pigeon came out from behind him',
  );
  await snap('whistle, the squadron at his back');
  // ...and the first when none is and the squadron is in the open.
  s.until(
    (x) =>
        x.enemies.any((e) => e.squad) &&
        !x.enemies.any((e) => KingCooStaging.squadBehind(x.boss, e, 360)),
  );
  await snap('whistle, the squadron in the open');
  s.hit(1000);
  final dead = s.boss.defeatedAt;
  expect(dead, isNotNull, reason: 'the blow ends him');
  for (final d in const [.05, .5, 1.0, 1.6, 2.3, 3.0, 3.6]) {
    s.toAge(dead! + d);
    await snap('defeat $d');
  }
  return beats;
}

/// The Gargoyle's: arrival, perch, warning, sweep, a hit in the vent that
/// carries him into fury, a fury cycle with its feathers in the air, the
/// killing blow, the defeat, the victory card.
Future<List<_Beat>> _gargoyleSequence(
  double width, {
  bool reduced = false,
  _Stage? into,
}) async {
  final s = into ?? _Stage.open('3-4', width, reduced: reduced);
  final beats = <_Beat>[];
  Future<void> snap(String label) async => beats.add(
    _Beat(
      label,
      s.boss.age,
      await s.frame(),
      await s.pass('paint'),
      s.boss.defeatedAt != null,
    ),
  );
  for (final age in const [.3, 1.2, 1.75, 2.2, 2.7, 3.4, 4.2]) {
    s.toAge(age);
    await snap('arrival $age');
  }
  for (final x in const [1.0, 2.8, 4.5]) {
    s.toCombat(x);
    await snap('cycle 0 at $x');
  }
  s.toCombat(6.8);
  await snap('vent');
  s.hit(90);
  await snap('hit');
  expect(s.boss.enraged, isTrue, reason: 'the hit carries him into fury');
  for (final x in const [10.0, 11.8]) {
    s.toCombat(x);
    await snap('cycle 1 at ${x - 9}');
  }
  s.toCombat(14.6);
  expect(
    s.sim.bossAmmo.any((a) => a.feather),
    isTrue,
    reason: 'stone feathers are in the air',
  );
  await snap('fury feathers');
  s.toCombat(15.8);
  expect(s.boss.lampOpen, isTrue);
  s.hit(1000);
  final dead = s.boss.defeatedAt;
  expect(dead, isNotNull, reason: 'the blow ends him');
  for (final d in const [.05, .5, 1.0, 1.6, 2.3, 3.0, 3.6]) {
    s.toAge(dead! + d);
    await snap('defeat $d');
  }
  return beats;
}


/// A squadron pigeon's track, for the pigeons these tests park by hand.
const _squadTrack = SquadTrack(x0: 0, fromY: .5, lane: .5, bornAt: 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const guardians = [
    ('King Coo', '3-2', BossKind.kingCoo),
    ('the Searchlight Gargoyle', '3-4', BossKind.searchlightGargoyle),
  ];

  // --------------------------------- one frame sequence per guardian --

  group('a whole encounter through the real renderer', () {
    for (final width in const [640.0, 800.0]) {
      for (final (name, levelId, kind) in guardians) {
        testWidgets(
          '$name at ${width.toInt()} px: every beat is his own picture',
          (tester) async {
            await tester.runAsync(() async {
              await loadFonts();
              final s = _Stage.open(levelId, width);
              expect(s.boss.kind, kind, reason: '$levelId guards $name');
              final beats = kind == BossKind.kingCoo
                  ? await _kingSequence(width, into: s)
                  : await _gargoyleSequence(width, into: s);
              // The real game drew every beat, at the screen's size.
              for (final b in beats) {
                expect(b.game.length, width.toInt() * 360 * 4, reason: b.label);
                expect(_opaque(b.game), width.toInt() * 360, reason: b.label);
              }
              // One picture per beat: no beat is a stand-in for another.
              for (var i = 0; i < beats.length; i++) {
                for (var j = i + 1; j < beats.length; j++) {
                  expect(
                    _same(beats[i].game, beats[j].game),
                    isFalse,
                    reason:
                        '"${beats[i].label}" and "${beats[j].label}" differ',
                  );
                }
              }
              // The boss pass alone is the same two ways round for the two
              // bosses: shown from the first instant of the storm.
              final seen = beats.where((b) => _opaque(b.paint) > 0).length;
              expect(seen, greaterThan(beats.length - 3), reason: '$name drew');
            });
          },
          timeout: const Timeout(Duration(minutes: 8)),
        );
      }
    }

    testWidgets(
      'under Reduced Motion each guardian still shows every state, distinctly',
      (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          final king = await _kingSequence(640, reduced: true);
          final gargoyle = await _gargoyleSequence(640, reduced: true);
          for (final (name, beats) in [
            ('King Coo', king),
            ('the Gargoyle', gargoyle),
          ]) {
            // The states a player has to read still differ from one another.
            final states = <String>{
              for (final b in beats)
                if (b.label.startsWith('arrival 2.8') ||
                    b.label.startsWith('arrival 2.7') ||
                    b.label.startsWith('fight 1.0') ||
                    b.label.startsWith('cycle 0 at 1.0') ||
                    b.label == 'hit' ||
                    b.label.startsWith('fury') ||
                    b.label == 'defeat 0.5' ||
                    b.label == 'defeat 2.3')
                b.label,
            };
            final shots = [for (final b in beats) if (states.contains(b.label)) b];
            expect(shots.length, greaterThanOrEqualTo(6), reason: name);
            for (var i = 0; i < shots.length; i++) {
              for (var j = i + 1; j < shots.length; j++) {
                expect(
                  _same(shots[i].paint, shots[j].paint),
                  isFalse,
                  reason:
                      '$name: "${shots[i].label}" and "${shots[j].label}" '
                      '(Reduced Motion)',
                );
              }
            }
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 8)),
    );
  });

  // -------------------------------------------- the two dispatches --

  group('each guardian is drawn by his own entry point', () {
    testWidgets(
      'the boss pass equals his stage byte for byte and is never the Baron\'s '
      'or the other guardian\'s, at every beat of the encounter',
      (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          for (final width in const [640.0, 800.0]) {
            final king = _Stage.open('3-2', width);
            final gar = _Stage.open('3-4', width);
            // Interleaved on purpose: the same process draws one, then the
            // other, then the first again.
            final kingAges = <double>[.5, 1.8, 2.8, 3.4, 4.3];
            // (He is not drawn until the tower slides in at .95 s.)
            final garAges = <double>[1.2, 1.8, 2.8, 3.4, 4.3];
            Future<void> check(_Stage s, void Function(Canvas, Size) own, String at) async {
              final b = s.boss;
              final real = await s.pass('paint');
              final entry = await rawPixels(
                s.width.toInt(),
                360,
                (c) => own(c, s.size),
              );
              expect(_differ(real, entry), 0, reason: '$at: his own stage');
              final baron = await s.pass('paint', boss: _as(b, BossKind.baronBat));
              expect(
                _differ(real, baron),
                greaterThan(200),
                reason: '$at: not the Baron\'s fall-through',
              );
              final other = await s.pass(
                'paint',
                boss: _as(
                  b,
                  b.isKingCoo
                      ? BossKind.searchlightGargoyle
                      : BossKind.kingCoo,
                ),
              );
              expect(
                _differ(real, other),
                greaterThan(200),
                reason: '$at: not the other guardian\'s',
              );
              final backdrop = await s.pass('backdrop');
              final baronBackdrop = await s.pass(
                'backdrop',
                boss: _as(b, BossKind.baronBat),
              );
              expect(
                _differ(backdrop, baronBackdrop),
                greaterThan(0),
                reason: '$at: his own backdrop',
              );
            }

            for (var i = 0; i < kingAges.length; i++) {
              king.toAge(kingAges[i]);
              await check(
                king,
                (c, size) => KingCooStaging.paint(
                  c,
                  size,
                  king.sim,
                  BossMotion(king.boss, reducedMotion: false),
                ),
                'King Coo at ${kingAges[i]} s, $width px',
              );
              gar.toAge(garAges[i]);
              await check(
                gar,
                (c, size) => GargoyleEncounterArt.paint(
                  c,
                  size,
                  gar.sim,
                  BossMotion(gar.boss, reducedMotion: false),
                ),
                'the Gargoyle at ${garAges[i]} s, $width px',
              );
            }
            // The fight itself, and the defeat.
            king.toCombat(8.0);
            await check(
              king,
              (c, size) => KingCooStaging.paint(
                c,
                size,
                king.sim,
                BossMotion(king.boss, reducedMotion: false),
              ),
              'King Coo puffed, $width px',
            );
            gar.toCombat(6.8);
            await check(
              gar,
              (c, size) => GargoyleEncounterArt.paint(
                c,
                size,
                gar.sim,
                BossMotion(gar.boss, reducedMotion: false),
              ),
              'the Gargoyle at the vent, $width px',
            );
            king.hit(1000);
            gar.hit(1000);
            for (final d in const [.4, 1.2]) {
              king.toAge(king.boss.defeatedAt! + d);
              await check(
                king,
                (c, size) => KingCooStaging.paint(
                  c,
                  size,
                  king.sim,
                  BossMotion(king.boss, reducedMotion: false),
                ),
                'King Coo ${d}s into his defeat, $width px',
              );
              gar.toAge(gar.boss.defeatedAt! + d);
              await check(
                gar,
                (c, size) => GargoyleEncounterArt.paint(
                  c,
                  size,
                  gar.sim,
                  BossMotion(gar.boss, reducedMotion: false),
                ),
                'the Gargoyle ${d}s into his defeat, $width px',
              );
            }
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 8)),
    );

    testWidgets(
      'what one has drawn never changes what the other draws (shared caches)',
      (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          final king = _Stage.open('3-2', 640);
          final gar = _Stage.open('3-4', 640);
          king.toAge(2.8);
          gar.toAge(2.8);
          final k1 = await king.frame();
          final g1 = await gar.frame();
          final k2 = await king.frame();
          final g2 = await gar.frame();
          expect(_differ(k1, k2), 0, reason: 'King Coo, a second time');
          expect(_differ(g1, g2), 0, reason: 'the Gargoyle, a second time');
          // And in the fight, with fury and every cache warm.
          king.toCombat(3.0);
          king.hit(150);
          gar.toCombat(6.8);
          gar.hit(90);
          final k3 = await king.frame();
          final g3 = await gar.frame();
          final g4 = await gar.frame();
          final k4 = await king.frame();
          expect(_differ(k3, k4), 0);
          expect(_differ(g3, g4), 0);
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  // ------------------------------------------------ one letterbox --

  group('one letterbox for every cinematic boss', () {
    test('the arrival: both guardians close, open for their roar and lift the bars exactly as the dragon\'s (King Coo\'s joined them in the K8 fix round)', () {
      for (var i = 0; i <= 120; i++) {
        final age = i * .05;
        double focusOf(BossKind kind) {
          final boss = SkyBoss(number: 6, x: 1.4, kind: kind, cinematic: true)
            ..age = age;
          final m = BossMotion(boss, reducedMotion: false);
          return switch (kind) {
            BossKind.kingCoo => KingCooStaging.focus(m),
            BossKind.searchlightGargoyle => GargoyleEncounterArt.focus(m),
            _ => BossEncounterArt.dragonFocus(m),
          };
        }

        final dragon = focusOf(BossKind.dragon);
        expect(
          focusOf(BossKind.searchlightGargoyle),
          closeTo(dragon, 1e-9),
          reason: 'the Gargoyle at $age s',
        );
        expect(
          focusOf(BossKind.kingCoo),
          closeTo(dragon, 1e-9),
          reason: 'King Coo at $age s (open to 30% for his COO!, as theirs)',
        );
      }
    });

    test('and close behind the dying figure on the same ramp: the Gargoyle\'s and King Coo\'s are the dragon\'s (0.4 to 1.1 s)', () {
      SkyBoss dead(BossKind kind, double death) =>
          SkyBoss(number: 6, x: 1.4, kind: kind, cinematic: true)
            ..age = 20
            ..defeatedAt = 20 - death;
      double dragon(double death) => BossEncounterArt.dragonFocus(
        BossMotion(dead(BossKind.dragon, death), reducedMotion: false),
      );
      for (var i = 4; i <= 76; i++) {
        final death = i * .05;
        final garg = GargoyleEncounterArt.focus(
          BossMotion(dead(BossKind.searchlightGargoyle, death), reducedMotion: false),
        );
        final king = KingCooStaging.focus(
          BossMotion(dead(BossKind.kingCoo, death), reducedMotion: false),
        );
        expect(garg, closeTo(dragon(death), 1e-9), reason: 'the Gargoyle $death s into his defeat');
        expect(king, closeTo(dragon(death), 1e-9), reason: 'King Coo $death s into his defeat');
        expect(king, inInclusiveRange(0, 1));
      }
      // Both are fully in from 1.1 s and fully out by the end of the defeat.
      for (final kind in [BossKind.kingCoo, BossKind.searchlightGargoyle]) {
        final m = BossMotion(dead(kind, 1.5), reducedMotion: false);
        expect(kind == BossKind.kingCoo ? KingCooStaging.focus(m) : GargoyleEncounterArt.focus(m), 1.0, reason: '$kind');
        final end = BossMotion(dead(kind, 3.8), reducedMotion: false);
        expect(kind == BossKind.kingCoo ? KingCooStaging.focus(end) : GargoyleEncounterArt.focus(end), 0.0, reason: '$kind');
      }
    });
  });

  // ----------------------------------------------- one wording --

  group('one wording for every guardian', () {
    test('the card says GUARDIAN: the shared eyebrow, King Coo\'s ribbon and the Gargoyle\'s', () {
      for (final kind in [BossKind.kingCoo, BossKind.searchlightGargoyle]) {
        final boss = SkyBoss(number: 6, x: 1, kind: kind, cinematic: true);
        expect(BossEncounterArt.nameCardEyebrow(boss), 'GUARDIAN', reason: '$kind');
      }
      expect(KingCooEncounterUi.ribbonWord, 'GUARDIAN');
      expect(GargoyleEncounterUi.tag, 'GUARDIAN');
      // A chapter's boss keeps its numbered encounter.
      for (final kind in [
        BossKind.baronBat,
        BossKind.spitterBeetle,
        BossKind.duskMoth,
        BossKind.pirate,
        BossKind.dragon,
      ]) {
        final boss = SkyBoss(number: 3, x: 1, kind: kind, cinematic: true);
        expect(BossEncounterArt.nameCardEyebrow(boss), 'ENCOUNTER 03');
      }
    });

    test('the victory card says GUARDIAN DOWN! for both, the result screen\'s word', () {
      for (final (_, levelId, kind) in guardians) {
        final boss = SkyBoss(number: 6, x: 1, kind: kind, cinematic: true);
        final level = Campaign.level(levelId)!;
        expect(level.isGuardian, isTrue);
        expect(BossEncounterArt.victoryTitle(boss), 'GUARDIAN DOWN!');
        expect(
          BossEncounterArt.victoryTitle(boss),
          LevelResultStage.wordFor(level, complete: true).toUpperCase(),
          reason: 'the in-flight card and the result screen say the same',
        );
      }
      for (final kind in [
        BossKind.baronBat,
        BossKind.spitterBeetle,
        BossKind.duskMoth,
        BossKind.pirate,
        BossKind.dragon,
      ]) {
        final boss = SkyBoss(number: 3, x: 1, kind: kind, cinematic: true);
        expect(BossEncounterArt.victoryTitle(boss), 'SKY RECLAIMED');
      }
    });

    testWidgets('the real victory card draws that title for King Coo and the Gargoyle alike, and not the chapter bosses\'', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final sim = nyFlight(Campaign.level('3-2')!.plan);
        Future<Uint8List> band(BossKind kind) async {
          final boss = SkyBoss(number: 6, x: 1.4, kind: kind, cinematic: true)
            ..age = 10
            ..defeatedAt = 7.7;
          final saved = sim.boss;
          sim.boss = boss;
          final p = await rawPixels(
            640,
            360,
            (c) => BossEncounterArt.foreground(
              c,
              const Size(640, 360),
              sim,
              BossMotion(boss, reducedMotion: false),
            ),
          );
          sim.boss = saved;
          // The title's band, between the letterbox and the rule under it.
          return Uint8List.sublistView(p, 640 * 4 * 88, 640 * 4 * 131);
        }

        final king = await band(BossKind.kingCoo);
        final gargoyle = await band(BossKind.searchlightGargoyle);
        final dragon = await band(BossKind.dragon);
        expect(_opaque(king), greaterThan(2000), reason: 'a title is drawn');
        expect(
          _differ(king, gargoyle),
          0,
          reason: 'the same title in the same place',
        );
        expect(
          _differ(king, dragon),
          greaterThan(500),
          reason: 'a chapter\'s boss says SKY RECLAIMED',
        );
      });
    });

    test('no player-facing string in lib says MINI-BOSS', () {
      final bad = <String>[];
      final quoted = RegExp(r'''(["'])[^"'\n]*mini[- ]?boss[^"'\n]*\1''', caseSensitive: false);
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        for (final (i, line) in file.readAsLinesSync().indexed) {
          final code = line.trimLeft();
          if (code.startsWith('//')) continue;
          // Developer messages (errors, assertions) are not player-facing.
          if (code.contains('ArgumentError') || code.contains('assert(') || code.contains('StateError')) continue;
          // Drop a trailing comment before looking for a string.
          final cut = line.indexOf(' // ');
          final text = cut < 0 ? line : line.substring(0, cut);
          if (quoted.hasMatch(text)) bad.add('${file.path}:${i + 1}');
        }
      }
      expect(bad, isEmpty);
    });
  });

  // --------------------------------------- both cards carry the line --

  group('both name cards carry the campaign\'s line', () {
    test('the dispatch hands each card the level\'s quote', () {
      final source = File('lib/game/boss_encounter_art.dart').readAsStringSync();
      for (final card in ['KingCooEncounterUi.nameCard(', 'GargoyleEncounterUi.nameCard(']) {
        final at = source.indexOf(card);
        expect(at, greaterThan(0), reason: card);
        expect(source.indexOf(card, at + 1), -1, reason: '$card is dispatched once');
        // The call's own arguments: to the parenthesis that closes it.
        final open = source.indexOf('(', at);
        var depth = 0, end = open;
        for (; end < source.length; end++) {
          if (source[end] == '(') depth++;
          if (source[end] == ')' && --depth == 0) break;
        }
        final call = source.substring(at, end + 1);
        expect(call, contains('line: bossLine(sim)'), reason: card);
        expect(call, contains('birdY: sim.birdY'), reason: card);
      }
      // The campaign's own words, as both cards receive them.
      for (final (_, levelId, kind) in guardians) {
        final sim = nyFlight(Campaign.level(levelId)!.plan);
        sim.boss = SkyBoss(number: 6, x: 1, kind: kind, cinematic: true);
        expect(
          BossEncounterArt.bossLine(sim),
          '“${CampaignStory.guardianLines[levelId]}”',
          reason: levelId,
        );
      }
    });

    testWidgets('each card draws the line it is given, under its own epithet', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        Future<Uint8List> card(BossKind kind, String? line, double age) {
          final boss = SkyBoss(number: 6, x: 1.4, kind: kind, cinematic: true)
            ..age = age
            ..fireIn = 5;
          final m = BossMotion(boss, reducedMotion: false);
          return rawPixels(640, 360, (c) {
            if (kind == BossKind.kingCoo) {
              KingCooEncounterUi.nameCard(c, const Size(640, 360), boss, m, birdY: .8, line: line);
            } else {
              GargoyleEncounterUi.nameCard(c, const Size(640, 360), boss, m, birdY: .8, line: line);
            }
          });
        }

        for (final (_, levelId, kind) in guardians) {
          final own = '“${CampaignStory.guardianLines[levelId]}”';
          final a = await card(kind, own, 3.4);
          final b = await card(kind, '“Something else entirely.”', 3.4);
          final none = await card(kind, null, 3.4);
          expect(_opaque(a), greaterThan(4000), reason: '$kind: a card is drawn');
          expect(_differ(a, b), greaterThan(300), reason: '$kind: the line is on the card');
          // His own words stand in when the caller has none (the same ones).
          expect(_differ(a, none), 0, reason: '$kind: the campaign line is his own');
        }
      });
    });
  });

  // -------------------------------------- the story and the keepsake --

  group('both story portraits and keepsakes in the shared adapters', () {
    testWidgets('StoryBossArt paints each from his own rig in every mood', (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> story(BossKind kind, StoryMood mood, bool beaten) =>
            rawPixels(260, 260, (c) {
              c.translate(130, 150);
              c.scale(30);
              StoryBossArt.paint(c, kind, mood, beaten: beaten);
            });
        Future<Uint8List> direct(BossKind kind, StoryMood mood, bool beaten) =>
            rawPixels(260, 260, (c) {
              c.translate(130, 150);
              c.scale(30);
              if (kind == BossKind.kingCoo) {
                final m = beaten && mood == StoryMood.plain ? StoryMood.sad : mood;
                KingCooStoryArt.paint(c, KingCooMood.values.byName(m.name), beaten: beaten);
              } else {
                GargoyleStoryArt.paint(c, mood, beaten: beaten);
              }
            });
        final pictures = <BossKind, List<Uint8List>>{};
        for (final kind in [BossKind.kingCoo, BossKind.searchlightGargoyle]) {
          pictures[kind] = [];
          for (final beaten in [false, true]) {
            for (final mood in StoryMood.values) {
              final shared = await story(kind, mood, beaten);
              final own = await direct(kind, mood, beaten);
              expect(_differ(shared, own), 0, reason: '$kind $mood beaten=$beaten is his own adapter');
              expect(_opaque(shared), greaterThan(500), reason: '$kind $mood beaten=$beaten draws');
              if (!beaten) pictures[kind]!.add(shared);
            }
          }
          // The five plain moods are five different pictures.
          for (var i = 0; i < 5; i++) {
            for (var j = i + 1; j < 5; j++) {
              expect(_differ(pictures[kind]![i], pictures[kind]![j]), greaterThan(0), reason: '$kind moods $i and $j');
            }
          }
        }
        for (var i = 0; i < 5; i++) {
          expect(
            _differ(pictures[BossKind.kingCoo]![i], pictures[BossKind.searchlightGargoyle]![i]),
            greaterThan(2000),
            reason: 'mood $i: two guardians, two portraits',
          );
        }
        // Each has his own fit on the stage.
        final king = StoryBossArt.portrait(BossKind.kingCoo);
        final gargoyle = StoryBossArt.portrait(BossKind.searchlightGargoyle);
        expect(king.unit, isNot(gargoyle.unit));
        expect(king.reach, isNot(gargoyle.reach));
      });
    });

    testWidgets('the keepsakes are the cap and the visor, on their own stamp fields', (tester) async {
      await tester.runAsync(() async {
        const box = Rect.fromLTWH(10, 10, 120, 100);
        Future<Uint8List> shared(BossKind kind) => rawPixels(140, 120, (c) => CampaignHeadwear.paint(c, box, kind));
        Future<Uint8List> own(BossKind kind) => rawPixels(140, 120, (c) {
          final reach = kind == BossKind.kingCoo ? KingCooStaging.capReach : GargoyleStoryArt.visorReach;
          final scale = [box.width / reach.width, box.height / reach.height].reduce((a, b) => a < b ? a : b);
          c.save();
          c.translate(box.center.dx, box.center.dy);
          c.scale(scale);
          c.translate(-reach.center.dx, -reach.center.dy);
          if (kind == BossKind.kingCoo) {
            KingCooBossRig.capPaint(c);
          } else {
            GargoyleStoryArt.visor(c);
          }
          c.restore();
        });
        final kingKeep = await shared(BossKind.kingCoo);
        final gargoyleKeep = await shared(BossKind.searchlightGargoyle);
        expect(_differ(kingKeep, await own(BossKind.kingCoo)), 0);
        expect(_differ(gargoyleKeep, await own(BossKind.searchlightGargoyle)), 0);
        expect(_opaque(kingKeep), greaterThan(800));
        expect(_opaque(gargoyleKeep), greaterThan(800));
        expect(_differ(kingKeep, gargoyleKeep), greaterThan(800));
        expect(CampaignHeadwear.name(BossKind.kingCoo), 'King Coo');
        expect(CampaignHeadwear.name(BossKind.searchlightGargoyle), 'Searchlight Gargoyle');
        expect(CampaignHeadwear.field(BossKind.kingCoo), isNot(CampaignHeadwear.field(BossKind.searchlightGargoyle)));
      });
    });
  });

  // ------------------------------------------- squadron against feathers --

  group('King Coo\'s squadron and the Gargoyle\'s feathers and beams', () {
    test('his squadron is held back from the shared pass for him alone', () {
      // One of his squadron: it flies on a track (a squad pigeon without one
      // is a rules 45 straggler, drawn in front of him).
      final pigeon = SkyEnemy(x: 1.0, y: .5, appearance: 4, squad: true)
        ..track = _squadTrack;
      for (final kind in BossKind.values) {
        final boss = SkyBoss(number: 6, x: 1.4, kind: kind, cinematic: true);
        // A pigeon right at his back (inside the reach) is held back for King
        // Coo and for nobody else.
        pigeon.x = boss.x - .1;
        expect(
          KingCooStaging.squadBehind(boss, pigeon, 360),
          kind == BossKind.kingCoo,
          reason: '$kind',
        );
      }
      final gargoyle = SkyBoss(number: 6, x: 1.4, kind: BossKind.searchlightGargoyle, cinematic: true);
      for (var x = .2; x < 1.6; x += .1) {
        pigeon.x = x;
        expect(KingCooStaging.squadBehind(gargoyle, pigeon, 360), isFalse, reason: 'x $x');
        expect(KingCooStaging.squadBehind(null, pigeon, 360), isFalse);
      }
    });

    testWidgets('CombatArt draws a squadron pigeon for the Gargoyle and for King Coo in the open, never one at King Coo\'s back', (tester) async {
      await tester.runAsync(() async {
        final king = _Stage.open('3-2', 640)..toCombat(1.0);
        final gar = _Stage.open('3-4', 640)..toCombat(1.0);
        Future<Uint8List> combat(_Stage s, {SkyEnemy? with_}) => rawPixels(640, 360, (c) {
          s.sim.enemies
            ..clear()
            ..addAll([?with_]);
          CombatArt.paint(c, 360, s.sim, reducedMotion: false);
        });
        SkyEnemy pigeonAt(double x) => SkyEnemy(x: x, y: .5, appearance: 4, squad: true)..track = _squadTrack;
        for (final (s, back, open) in [
          (king, king.boss.x - .2, king.boss.x - .6),
          (gar, gar.boss.x - .2, gar.boss.x - .6),
        ]) {
          final empty = await combat(s);
          final atBack = await combat(s, with_: pigeonAt(back));
          final inOpen = await combat(s, with_: pigeonAt(open));
          expect(_differ(empty, inOpen), greaterThan(100), reason: '${s.boss.kind}: a pigeon in the open is drawn');
          if (s.boss.isKingCoo) {
            expect(_differ(empty, atBack), 0, reason: 'his stage draws the pigeon at his back, under him');
          } else {
            expect(_differ(empty, atBack), greaterThan(100), reason: 'the Gargoyle\'s frame has nobody else to draw it');
          }
        }
      });
    }, timeout: const Timeout(Duration(minutes: 4)));

    testWidgets('in the Gargoyle\'s frames a pigeon is on top of his feathers, beams and plate; his feathers are drawn by his stage', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final s = _Stage.open('3-4', 640);
        // The first sweep (3.5 to 6.4 s) with the second feather (launched at
        // 4.6 s, 1.72 s in the air) in flight.
        s.toCombat(5.4);
        s.until((x) => x.bossAmmo.any((a) => a.feather) && x.boss!.beamCentres.isNotEmpty);
        final feathers = s.sim.bossAmmo.where((a) => a.feather).toList();
        expect(feathers, isNotEmpty);
        final base = await s.frame();
        // A squadron pigeon parked on a feather is drawn over it.
        final f = feathers.first;
        s.sim.enemies.add(SkyEnemy(x: f.x, y: f.y.clamp(.1, .9), appearance: 4, squad: true));
        final withPigeon = await s.frame();
        s.sim.enemies.clear();
        expect(_differ(base, withPigeon), greaterThan(150), reason: 'the pigeon is on the picture');
        final frame = await s.frame();
        expect(_differ(base, frame), 0, reason: 'and takes nothing with it when it goes');
        // The feathers are the Gargoyle's: take them away and the frame loses
        // them (his pass, not CombatArt's).
        final kept = List.of(s.sim.bossAmmo);
        s.sim.bossAmmo.clear();
        final without = await s.frame();
        s.sim.bossAmmo.addAll(kept);
        expect(_differ(base, without), greaterThan(150), reason: 'the feathers are drawn');
        final fromCombat = await rawPixels(640, 360, (c) => CombatArt.paint(c, 360, s.sim, reducedMotion: false));
        final fromCombatNone = await (() async {
          s.sim.bossAmmo.clear();
          final p = await rawPixels(640, 360, (c) => CombatArt.paint(c, 360, s.sim, reducedMotion: false));
          s.sim.bossAmmo.addAll(kept);
          return p;
        })();
        expect(_differ(fromCombat, fromCombatNone), 0, reason: 'CombatArt draws no feather');
      });
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('the real game paints the boss pass before the combat pass, and the plate\'s feather pass after the plate', () {
      final source = File('lib/game/bird_game.dart').readAsStringSync();
      // (The call may be written on one line or wrapped.)
      final boss = source.indexOf('BossArt.paint(');
      final combat = source.indexOf('CombatArt.paint(');
      final bar = source.indexOf('BossArt.healthBar(');
      final overBar = source.indexOf('GargoyleFeatherArt.overBar(');
      expect(boss, greaterThan(0));
      expect(combat, greaterThan(boss), reason: 'squadron pigeons paint over the boss pass');
      expect(overBar, greaterThan(bar), reason: 'the Gargoyle\'s feathers redraw over his plate');
      expect(overBar, greaterThan(combat));
      // The beam sits in the backdrop, under the stars, enemies and the bird.
      final backdrop = source.indexOf('BossArt.backdrop(');
      expect(backdrop, greaterThan(0));
      expect(backdrop, lessThan(boss));
    });
  });
}
