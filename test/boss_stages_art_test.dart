// The staged campaign bosses and their vanguards (rules version 44), as the
// art draws them: the bar cut in thirds, the STRONGER! tag, the power-up
// effect around every boss, the vanguard's card and plate. Review PNGs come
// from boss_stages_review_test.dart.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_power_up_art.dart';
import 'package:push_up_bird/game/boss_stage_hud_art.dart';
import 'package:push_up_bird/game/boss_vanguard_art.dart';
import 'package:push_up_bird/game/ammo_shatter_art.dart';
import 'package:push_up_bird/game/enemy_ammo_art.dart';
import 'package:push_up_bird/game/enemy_ammo_impact_art.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_designs/alley_pigeon.dart';
import 'package:push_up_bird/game/king_coo_hud_art.dart';
import 'package:push_up_bird/game/straggler_art.dart';

import 'boss_stages_support.dart';
import 'campaign_flight.dart';

/// Landscape phone viewports (the app is locked to landscape).
const _sizes = [
  Size(568, 320),
  Size(640, 360),
  Size(800, 360),
  Size(792, 360),
  Size(932, 430),
];

/// A campaign boss in its fight at [share] of its health; grown stronger
/// to [stage] [since] seconds ago.
SkyBoss _boss(
  BossKind kind, {
  double share = 1,
  int stage = 0,
  double since = 30,
  bool staged = true,
  double fight = 6,
}) {
  final boss = SkyBoss(
    number: 1,
    x: 1.6,
    cinematic: true,
    kind: kind,
    debut: true,
    staged: staged,
    maxHp: staged ? SkyBoss.campaignHealthFor(kind) : null,
  )..age = -40;
  final target = (boss.maxHp * share).round();
  if (target < boss.maxHp) boss.takeDamage(boss.maxHp - target);
  boss.age = boss.arrivalDuration + fight;
  if (stage > 0) {
    boss
      ..stageReached = stage
      ..stageUpAt = boss.age - since;
  }
  return boss;
}

/// Areas the Flutter flight HUD (SceneLayout 1000×450, contain-fit) keeps
/// for the hearts readout, the flight clock and the pause button.
List<Rect> _hudZones(Size size) {
  final scale = math.min(size.width / 1000, size.height / 450);
  final dx = (size.width - 1000 * scale) / 2;
  final dy = (size.height - 450 * scale) / 2;
  Rect at(double l, double t, double r, double b) => Rect.fromLTRB(
    dx + l * scale,
    dy + t * scale,
    dx + r * scale,
    dy + b * scale,
  );
  return [
    at(24, 18, 250, 90),
    at(1000 - 112 - 110, 24, 1000 - 112, 86),
    at(1000 - 24 - 76, 18, 1000 - 24, 94),
  ];
}

double _lin(int v) {
  final c = v / 255;
  return c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
}

Float64List _luminance(Uint8List px) {
  final o = Float64List(px.length ~/ 4);
  for (var i = 0; i < o.length; i++) {
    o[i] =
        .2126 * _lin(px[i * 4]) +
        .7152 * _lin(px[i * 4 + 1]) +
        .0722 * _lin(px[i * 4 + 2]);
  }
  return o;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  Future<Uint8List> pixels(void Function(Canvas) draw, Size size) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final image = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();
    return bytes;
  }

  void sky(Canvas c, Size size) =>
      c.drawRect(Offset.zero & size, Paint()..color = const Color(0xff7aa6d6));

  Future<Uint8List> bar(SkyBoss boss, Size size, {bool reduced = false}) =>
      pixels((c) {
        sky(c, size);
        BossHealthBarArt.paint(c, size, boss, reducedMotion: reduced);
      }, size);

  int changed(Uint8List a, Uint8List b, Size size, [Rect? region]) {
    final r = region ?? Offset.zero & size;
    var count = 0;
    for (var y = math.max(0, r.top.floor()); y < r.bottom.ceil(); y++) {
      for (var x = math.max(0, r.left.floor()); x < r.right.ceil(); x++) {
        final i = (y * size.width.toInt() + x) * 4;
        if ((a[i] - b[i]).abs() +
                (a[i + 1] - b[i + 1]).abs() +
                (a[i + 2] - b[i + 2]).abs() >
            24) {
          count++;
        }
      }
    }
    return count;
  }

  group('the bar in thirds', () {
    const size = Size(640, 360);

    testWidgets('a boss that fights in one stage never shows any of it', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final kind in BossKind.values) {
          for (final share in const [1.0, .6, .3]) {
            final plain = _boss(kind, share: share, staged: false);
            // Stage fields the rules never set on such a boss change nothing.
            final marked = _boss(kind, share: share, staged: false)
              ..stageReached = 1
              ..stageUpAt = plain.age - .2;
            expect(
              changed(await bar(plain, size), await bar(marked, size), size),
              0,
              reason: '$kind at $share',
            );
            expect(plain.stageMarks, [.5]);
          }
        }
      });
    });

    testWidgets('a staged bar has its marks at the thirds, not the half', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final kind in BossKind.values) {
          final staged = _boss(kind);
          final plain = _boss(kind, staged: false);
          final track = BossHealthBarArt.track(size, staged);
          final a = await bar(staged, size), b = await bar(plain, size);
          Rect around(double share) => Rect.fromCenter(
            center: Offset(track.left + track.width * share, track.top - 2),
            width: 8,
            height: 10,
          );
          // The gem stands over the two-thirds mark, the fury mark moves to
          // a third, and the half is left to the fill.
          expect(changed(a, b, size, around(2 / 3)), greaterThan(6));
          expect(changed(a, b, size, around(1 / 3)), greaterThan(4));
          expect(changed(a, b, size, around(.5)), greaterThan(4));
        }
      });
    });

    testWidgets('the gem snaps when the boss loses its first third', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final kind in BossKind.values) {
          final whole = _boss(kind, share: .7);
          final broken = _boss(kind, share: .6, stage: 1);
          final track = BossHealthBarArt.track(size, whole);
          final gem = Rect.fromCenter(
            center: Offset(track.left + track.width * 2 / 3, track.top - 1),
            width: 9,
            height: 10,
          );
          expect(
            changed(await bar(whole, size), await bar(broken, size), size, gem),
            greaterThan(8),
            reason: '$kind',
          );
        }
      });
    });

    testWidgets('STRONGER! hangs from the plate through the roar, then goes', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final kind in BossKind.values) {
          final strip = BossHealthBarArt.bounds(size, _boss(kind));
          final below = Rect.fromLTRB(
            strip.left,
            strip.bottom + 2,
            strip.right,
            strip.bottom + 14,
          );
          final settled = await bar(
            _boss(kind, share: .6, stage: 1, since: 30),
            size,
          );
          final tagged = await bar(
            _boss(kind, share: .6, stage: 1, since: .6),
            size,
          );
          final gone = await bar(
            _boss(
              kind,
              share: .6,
              stage: 1,
              since: BossStageHudArt.tagSeconds + .05,
            ),
            size,
          );
          expect(
            changed(settled, tagged, size, below),
            greaterThan(200),
            reason: '$kind: the tag shows',
          );
          expect(
            changed(settled, gone, size, below),
            0,
            reason: '$kind: it is gone before the new attacks can begin',
          );
          // Fury keeps its own tag: no STRONGER! after a step into fury.
          final fury = await bar(
            _boss(kind, share: .3, stage: 2, since: .6),
            size,
          );
          final furySettled = await bar(
            _boss(kind, share: .3, stage: 2, since: 30),
            size,
          );
          expect(changed(fury, furySettled, size, below), 0, reason: '$kind');
        }
      });
    });

    testWidgets('a staged dragon\'s warm-up never lays its heart open', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // Six seconds into the fight a breath is under way (HEART x2 hangs
        // from the plate), unless the dragon is still warming up.
        final endless = _boss(BossKind.dragon, staged: false);
        final warmUp = _boss(BossKind.dragon);
        final fullFight = _boss(BossKind.dragon, share: .6, stage: 1)
          ..signatureCycle = 0;
        expect(endless.breathBusy, isTrue);
        final strip = BossHealthBarArt.bounds(size, warmUp);
        final below = Rect.fromLTRB(
          strip.left,
          strip.bottom + 2,
          strip.right,
          strip.bottom + 14,
        );
        final empty = await pixels((c) => sky(c, size), size);
        expect(
          changed(empty, await bar(endless, size), size, below),
          greaterThan(200),
        );
        expect(changed(empty, await bar(warmUp, size), size, below), 0);
        expect(
          changed(empty, await bar(fullFight, size), size, below),
          greaterThan(200),
        );
      });
    });

    testWidgets(
      'the card and its hint keep under the plate, clear of the flight HUD',
      (tester) async {
        await tester.runAsync(() async {
          for (final s in _sizes) {
            final u = BossHealthBarArt.unit(s);
            for (final kind in BossKind.values) {
              final strip = BossHealthBarArt.bounds(s, _boss(kind));
              final tagged = await bar(
                _boss(kind, share: .6, stage: 1, since: .8),
                s,
              );
              final clean = await bar(_boss(kind, share: .6, stage: 1), s);
              final w = s.width.toInt();
              var drawn = 0;
              for (var y = 0; y < s.height; y++) {
                for (var x = 0; x < w; x++) {
                  final i = (y * w + x) * 4;
                  if ((tagged[i] - clean[i]).abs() +
                          (tagged[i + 1] - clean[i + 1]).abs() +
                          (tagged[i + 2] - clean[i + 2]).abs() <=
                      24) {
                    continue;
                  }
                  final at = Offset(x + .5, y + .5);
                  // Below the plate and inside its span, short of the clock.
                  if (y >= strip.bottom - 2 * u) {
                    drawn++;
                    expect(at.dx, greaterThanOrEqualTo(strip.left));
                    expect(
                      at.dx,
                      lessThanOrEqualTo(
                        math.min(strip.right, BossStageHudArt.hudRight(s)),
                      ),
                      reason: '$kind at $s',
                    );
                    expect(at.dy, lessThan(strip.bottom + 48 * u));
                  }
                  for (final zone in _hudZones(s)) {
                    expect(
                      zone.contains(at),
                      isFalse,
                      reason: '$kind at $s: $at is in $zone',
                    );
                  }
                }
              }
              expect(drawn, greaterThan(400), reason: '$kind at $s');
            }
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test('the hint is what the full fight brings, at stage 1 only', () {
      expect(
        BossStageHudArt.hintOf(_boss(BossKind.baronBat, stage: 1, since: .5)),
        'Triple shots, and his bats join in!',
      );
      for (final kind in BossKind.values) {
        expect(
          BossStageHudArt.hintOf(_boss(kind, stage: 1, since: .5)),
          allOf(isNotNull, isNot(contains('STRONGER'))),
        );
        expect(
          BossStageHudArt.hintOf(
            _boss(kind, stage: 1, since: SkyBoss.stageHintSeconds),
          ),
          isNull,
        );
        expect(
          BossStageHudArt.hintOf(_boss(kind, stage: 2, since: .5)),
          isNull,
        );
        expect(
          BossStageHudArt.hintOf(
            _boss(kind, staged: false)
              ..stageReached = 1
              ..stageUpAt = 5,
          ),
          isNull,
        );
      }
    });

    testWidgets('the card gives way to the boss\'s own tags', (tester) async {
      await tester.runAsync(() async {
        // King Coo puffed (8 s into a cycle: PUFFED x2 hangs from the plate)
        // and the dragon breathing (HEART x2), a second after each grew
        // stronger: the card is not there, right of the gauge's middle where
        // their tags never reach.
        for (final (kind, busy, calm) in const [
          (BossKind.kingCoo, 8.0, 5.0),
          (BossKind.dragon, 4.3, 2.0),
        ]) {
          SkyBoss at(double fight, {bool card = true}) => _boss(
            kind,
            share: .6,
            stage: 1,
            since: card ? 1 : 30,
            fight: fight,
          )..signatureCycle = 0;
          final track = BossHealthBarArt.track(size, at(busy));
          final strip = BossHealthBarArt.bounds(size, at(busy));
          final right = Rect.fromLTRB(
            track.center.dx + 40,
            strip.bottom + 2,
            strip.right,
            strip.bottom + 30,
          );
          expect(
            changed(
              await bar(at(busy), size),
              await bar(at(busy, card: false), size),
              size,
              right,
            ),
            0,
            reason: '$kind: it gave way',
          );
          expect(
            changed(
              await bar(at(calm), size),
              await bar(at(calm, card: false), size),
              size,
              right,
            ),
            greaterThan(100),
            reason: '$kind: it hangs when nothing else needs the place',
          );
        }
      });
    });
  });

  group('the power-up', () {
    FlightSimulation simWith(SkyBoss boss) =>
        levelFlight(Campaign.level('1-8')!)..boss = boss;

    Future<Uint8List> effect(SkyBoss boss, Size size, {required bool reduced}) {
      final sim = simWith(boss);
      return pixels((c) {
        c.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xff141a33),
        );
        BossPowerUpArt.under(c, size, sim, reducedMotion: reduced);
        BossPowerUpArt.over(c, size, sim, reducedMotion: reduced);
      }, size);
    }

    test('it lasts the roar, for a staged boss alone', () {
      for (final kind in BossKind.values) {
        expect(BossPowerUpArt.age(_boss(kind, stage: 1, since: .5)), .5);
        expect(BossPowerUpArt.age(_boss(kind, stage: 1, since: 1.41)), isNull);
        expect(
          BossPowerUpArt.age(_boss(kind, staged: false)..stageUpAt = 0),
          isNull,
        );
      }
    });

    testWidgets(
      'it never flashes: under a tenth of the screen brightens in 0.1 s',
      (tester) async {
        await tester.runAsync(() async {
          const size = Size(640, 360), fps = 30.0;
          for (final kind in BossKind.values) {
            for (final reduced in const [false, true]) {
              for (final stage in const [1, 2]) {
                final frames = <Float64List>[];
                for (var t = -.1; t < SkyBoss.stageRoar + .1; t += 1 / fps) {
                  final boss = _boss(
                    kind,
                    share: stage == 1 ? .6 : .3,
                    stage: stage,
                    since: t,
                  );
                  frames.add(
                    _luminance(await effect(boss, size, reduced: reduced)),
                  );
                }
                var worst = 0.0;
                for (var i = 3; i < frames.length; i++) {
                  var count = 0;
                  for (var p = 0; p < frames[i].length; p++) {
                    if (frames[i][p] - frames[i - 3][p] >= .10) count++;
                  }
                  worst = math.max(worst, count / frames[i].length);
                }
                // ignore: avoid_print
                print(
                  'power-up $kind stage $stage reduced $reduced: worst '
                  '${(worst * 100).toStringAsFixed(2)}% of the screen',
                );
                expect(
                  worst,
                  lessThan(.05),
                  reason: '$kind stage $stage reduced $reduced',
                );
              }
            }
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    testWidgets('Reduced Motion holds it still while it glows', (tester) async {
      await tester.runAsync(() async {
        const size = Size(640, 360);
        for (final kind in BossKind.values) {
          Future<Uint8List> at(double t, bool reduced) => effect(
            _boss(kind, share: .6, stage: 1, since: t),
            size,
            reduced: reduced,
          );
          expect(
            changed(await at(.35, true), await at(.65, true), size),
            0,
            reason: '$kind: still',
          );
          expect(
            changed(await at(.35, false), await at(.65, false), size),
            greaterThan(100),
            reason: '$kind: it moves without Reduced Motion',
          );
        }
      });
    });

    testWidgets('it is a function of the boss clock', (tester) async {
      await tester.runAsync(() async {
        const size = Size(800, 360);
        for (final kind in BossKind.values) {
          final first = await effect(
            _boss(kind, share: .6, stage: 1, since: .4),
            size,
            reduced: false,
          );
          for (final t in const [1.1, .05, .9]) {
            await effect(
              _boss(kind, share: .6, stage: 1, since: t),
              size,
              reduced: false,
            );
          }
          final again = await effect(
            _boss(kind, share: .6, stage: 1, since: .4),
            size,
            reduced: false,
          );
          expect(changed(first, again, size), 0, reason: '$kind');
        }
      });
    });
  });

  group('the vanguard', () {
    FlightSimulation flying(BossKind kind) {
      final sim = levelFlight(Campaign.level(bossLevels[kind]!)!);
      sim.vanguard = BossVanguard(boss: kind, startedAt: 0);
      return sim;
    }

    SkyEnemy send(FlightSimulation sim, {double x = 1.5}) {
      final guard = sim.vanguard!;
      final enemy = SkyEnemy(x: x, y: .5);
      guard.members.add(enemy);
      sim.enemies.add(enemy);
      return enemy;
    }

    test('each pip is flying, down or gone past, wave by wave', () {
      final sim = flying(BossKind.baronBat);
      final guard = sim.vanguard!..wavesSent = 2;
      final members = [for (var i = 0; i < 5; i++) send(sim)];
      // The rules' records: shot down at 2 s, flown past at 3 s, rammed at
      // 4 s (down), into the bird at 4.5 s (past).
      void gone(SkyEnemy m, double at, {bool down = false}) {
        sim.enemies.remove(m);
        guard.goneAt[m] = at;
        if (down) guard.downedAt[m] = at;
      }

      gone(members[0], 2, down: true);
      gone(members[1], 3);
      gone(members[2], 4, down: true);
      gone(members[3], 4.5);
      expect(BossVanguardArt.pips(sim), [
        [VanguardPip.downed, VanguardPip.escaped],
        [VanguardPip.downed, VanguardPip.escaped, VanguardPip.flying],
        List.filled(4, VanguardPip.coming),
      ]);
      final states = BossVanguardArt.pipStates(sim);
      expect([for (final p in states[0]) p.at], [2, 3]);
      expect(
        [for (final p in states[1]) p.at],
        [4, 4.5, guard.startedAt + guard.waves[1].at],
      );
    });

    testWidgets('a pip pops as it changes, never under Reduced Motion', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const size = Size(640, 360);
        final sim = flying(BossKind.baronBat);
        final guard = sim.vanguard!..wavesSent = 1;
        final a = send(sim), b = send(sim);
        sim.enemies.remove(a);
        guard.goneAt[a] = guard.downedAt[a] = 6;
        sim.enemies.remove(b);
        guard.goneAt[b] = 3;
        final plate = BossVanguardArt.bounds(size, guard).inflate(4);
        Future<Uint8List> at(double t, {bool reduced = false}) {
          sim.elapsed = t;
          return pixels((c) {
            sky(c, size);
            BossVanguardArt.plate(c, size, sim, reducedMotion: reduced);
          }, size);
        }

        final popping = await at(6.1), settled = await at(6.5);
        expect(changed(popping, settled, size, plate), greaterThan(30));
        // After its pop the plate holds still (nothing else changed).
        expect(changed(settled, await at(7.5), size, plate), 0);
        expect(
          changed(
            await at(6.1, reduced: true),
            await at(6.5, reduced: true),
            size,
            plate,
          ),
          0,
        );
      });
    });

    test(
      'the plate comes in with the vanguard and leaves as the boss comes',
      () {
        final sim = flying(BossKind.kingCoo);
        final guard = sim.vanguard!;
        sim.elapsed = 5;
        expect(BossVanguardArt.plateShow(sim, reduced: false), 1);
        guard.clearedAt = 10;
        sim.elapsed = 10 + BossVanguardArt.plateHold;
        expect(BossVanguardArt.plateShow(sim, reduced: false), 1);
        sim.elapsed = 10 + BossVanguard.bossDelay;
        expect(
          BossVanguardArt.plateShow(sim, reduced: true),
          inExclusiveRange(0, .6),
        );
        sim.elapsed = 10 + BossVanguard.bossDelay + .3;
        expect(BossVanguardArt.plateShow(sim, reduced: false), 0);
      },
    );

    test('the plate stays clear of the flight HUD at every phone size', () {
      for (final size in _sizes) {
        for (final kind in const [
          BossKind.baronBat,
          BossKind.spitterBeetle,
          BossKind.duskMoth,
          BossKind.kingCoo,
        ]) {
          final plate = BossVanguardArt.bounds(
            size,
            BossVanguard(boss: kind, startedAt: 0),
          );
          expect(plate.left, greaterThanOrEqualTo(0));
          expect(plate.right, lessThanOrEqualTo(size.width));
          expect(plate.height, lessThanOrEqualTo(size.height * .08));
          expect(plate.bottom, lessThanOrEqualTo(size.height * .11));
          for (final zone in _hudZones(size)) {
            expect(
              plate.inflate(4).overlaps(zone),
              isFalse,
              reason: '$kind at $size overlaps $zone',
            );
          }
        }
      }
    });

    testWidgets('the card and the plate are a function of the flight', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const size = Size(640, 360);
        final sim = flying(BossKind.duskMoth);
        sim.vanguard!.wavesSent = 1;
        send(sim);
        Future<Uint8List> at(double t, {bool reduced = false}) {
          sim.elapsed = t;
          return pixels((c) {
            sky(c, size);
            BossVanguardArt.paint(c, size, sim, reducedMotion: reduced);
          }, size);
        }

        final first = await at(1.2);
        await at(.1);
        await at(2.3);
        expect(changed(first, await at(1.2), size), 0);
        // The card is gone after its time; the plate stays.
        final late = await at(BossVanguard.bannerSeconds + .1);
        final plate = BossVanguardArt.bounds(size, sim.vanguard!);
        expect(
          changed(late, await at(6), size, plate.inflate(-4)),
          // (A pip is about 11 px square.)
          lessThan(120),
          reason: 'only the flying pip bobs',
        );
        expect(
          changed(
            late,
            await at(1.2),
            size,
            Rect.fromLTRB(0, plate.bottom + 6, size.width, size.height),
          ),
          greaterThan(2000),
        );
        // Under Reduced Motion nothing on the plate moves.
        expect(
          changed(await at(4, reduced: true), await at(6, reduced: true), size),
          0,
        );
      });
    });
  });

  group('King Coo\'s crusts (rules version 45)', () {
    const size = Size(160, 120), h = 360.0;
    Future<Uint8List> shot(void Function(Canvas) draw) => pixels((c) {
      c.drawRect(Offset.zero & size, Paint()..color = const Color(0xff3a3f6a));
      draw(c);
    }, size);
    EnemyAmmo pellet(EnemyAttack attack) =>
        EnemyAmmo(x: 80 / h, y: 60 / h, vx: -.40, vy: .05, attack: attack);

    testWidgets('the crust has its own look in flight, splash and shatter', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final reduced in const [false, true]) {
          Future<Uint8List> flying(EnemyAttack a) => shot(
            (c) => EnemyAmmoArt.paint(
              c,
              h,
              pellet(a),
              seconds: 1,
              reducedMotion: reduced,
            ),
          );
          Future<Uint8List> splash(EnemyAttack a, AmmoStop stop) => shot(
            (c) => EnemyAmmoImpactArt.splash(
              c,
              const Offset(80, 60),
              h * EnemyAmmo.radius,
              direction: 3,
              attack: a,
              stop: stop,
              age: .1,
              reducedMotion: reduced,
            ),
          );
          Future<Uint8List> shatter(EnemyAttack a) => shot(
            (c) => AmmoShatterArt.blast(
              c,
              const Offset(80, 60),
              h * EnemyAmmo.radius,
              reach: 45,
              charge: .8,
              direction: 3,
              attack: a,
              age: .1,
              reducedMotion: reduced,
            ),
          );
          final crust = await flying(EnemyAttack.crumb);
          for (final other in const [
            EnemyAttack.none,
            EnemyAttack.fan,
            EnemyAttack.aimed,
          ]) {
            expect(
              changed(crust, await flying(other), size),
              greaterThan(60),
              reason: 'in flight, unlike $other (reduced $reduced)',
            );
            expect(
              changed(
                await shatter(EnemyAttack.crumb),
                await shatter(other),
                size,
              ),
              greaterThan(60),
              reason: 'shattered, unlike $other',
            );
            for (final stop in AmmoStop.values) {
              expect(
                changed(
                  await splash(EnemyAttack.crumb, stop),
                  await splash(other, stop),
                  size,
                ),
                greaterThan(30),
                reason: '$stop, unlike $other (reduced $reduced)',
              );
            }
          }
        }
      });
    });

    testWidgets('it tumbles, but holds still under Reduced Motion', (
      tester,
    ) async {
      await tester.runAsync(() async {
        Future<Uint8List> at(double t, bool reduced) => shot(
          (c) => EnemyAmmoArt.paint(
            c,
            h,
            pellet(EnemyAttack.crumb),
            seconds: t,
            reducedMotion: reduced,
          ),
        );
        expect(
          changed(await at(1, false), await at(1.1, false), size),
          greaterThan(20),
        );
        expect(changed(await at(1, true), await at(1.1, true), size), 0);
      });
    });

    SkyEnemy thrower({
      double age = 3,
      bool preparing = false,
      double fireIn = 2,
      double shotAgo = 9,
    }) {
      final e = SkyEnemy(
        x: 80 / h,
        y: 60 / h,
        appearance: EnemyKind.alleyPigeon.index,
        flightPhase: 2.399963,
        squad: true,
        throwsCrumbs: true,
      )..age = age;
      e
        ..preparing = preparing
        ..fireIn = fireIn
        ..lastShotAt = age - shotAgo;
      return e;
    }

    test(
      'the throw follows the rules: wind-up on the charge, then the follow-through',
      () {
        expect(thrower().attack, EnemyAttack.crumb);
        final idle = AlleyPigeonArt.throwOf(thrower());
        expect(idle.windup, 0);
        expect(idle.follow, lessThan(0));
        final cocked = AlleyPigeonArt.throwOf(
          thrower(preparing: true, fireIn: SkyEnemy.warningSeconds * .25),
        );
        expect(cocked.windup, closeTo(.75, 1e-9));
        final thrown = AlleyPigeonArt.throwOf(thrower(shotAgo: .09));
        expect(
          thrown.follow,
          closeTo(.09 / AlleyPigeonArt.followSeconds, 1e-9),
        );
        expect(
          AlleyPigeonArt.throwOf(
            thrower(shotAgo: AlleyPigeonArt.followSeconds),
          ).follow,
          lessThan(0),
        );
      },
    );

    testWidgets('the wind-up reads at game size, and Reduced Motion holds it', (
      tester,
    ) async {
      await tester.runAsync(() async {
        Future<Uint8List> draw(SkyEnemy e, {bool reduced = false}) => shot(
          (c) => EnemyArt.paint(c, h, e, birdY: .5, reducedMotion: reduced),
        );
        final idle = await draw(thrower());
        final cocked = await draw(
          thrower(preparing: true, fireIn: SkyEnemy.warningSeconds * .1),
        );
        final thrown = await draw(thrower(shotAgo: .06));
        // At a 360 px high screen the pigeon is ~16 px: the raised crust and
        // its glow change a good part of it.
        expect(changed(idle, cocked, size), greaterThan(120));
        expect(changed(idle, thrown, size), greaterThan(60));
        // Under Reduced Motion the cocked pose is one still state (the
        // painter alone: the rules steady the bird's height as it winds up).
        Future<Uint8List> pose(PigeonThrow t) => shot((c) {
          c.translate(80, 60);
          AlleyPigeonArt.paint(
            c,
            h * SkyEnemy.radius,
            seconds: 1.3,
            reducedMotion: true,
            glider: true,
            throwing: t,
          );
        });
        expect(
          changed(
            await pose((windup: .3, follow: -1)),
            await pose((windup: .9, follow: -1)),
            size,
          ),
          0,
        );
        // And no follow-through: the glide is back at once.
        expect(
          changed(
            await pose((windup: 0, follow: .2)),
            await pose((windup: 0, follow: -1)),
            size,
          ),
          0,
        );
      });
    });

    test('the card tells the player to duck the crusts', () {
      expect(
        BossVanguardArt.call(BossKind.kingCoo, crusts: true),
        contains('crusts'),
      );
      expect(BossVanguardArt.call(BossKind.kingCoo), isNot(contains('crusts')));
    });
  });

  group('King Coo\'s stragglers (rules version 45)', () {
    /// A flight of 3-2 in King Coo's fight (at [share] of his health, grown
    /// stronger [since] seconds ago to [stage]) after a vanguard of which
    /// [escaped] got away; [caught] of them since shot down, the last at
    /// [caughtAt].
    FlightSimulation fight({
      int escaped = 5,
      int caught = 0,
      double caughtAt = 20,
      double elapsed = 21,
      double share = .9,
      int stage = 0,
      double since = 30,
    }) {
      final sim = levelFlight(Campaign.level('3-2')!);
      final guard = sim.vanguard = BossVanguard(
        boss: BossKind.kingCoo,
        startedAt: 0,
      )..wavesSent = 3;
      for (var i = 0; i < guard.total; i++) {
        final member = SkyEnemy(x: -.2, y: .5);
        guard.members.add(member);
        guard.goneAt[member] = 1 + i * .3;
        if (i >= escaped) guard.downedAt[member] = 1 + i * .3;
      }
      for (var i = 0; i < caught; i++) {
        final straggler = SkyEnemy(x: .8, y: .3);
        guard.stragglers.add(straggler);
        guard.stragglerGoneAt[straggler] = caughtAt - (caught - 1 - i);
        guard.stragglerDownedAt[straggler] = caughtAt - (caught - 1 - i);
      }
      sim
        ..elapsed = elapsed
        ..boss = _boss(
          BossKind.kingCoo,
          share: share,
          stage: stage,
          since: since,
        );
      return sim;
    }

    Future<Uint8List> tag(
      FlightSimulation sim,
      Size size, {
      bool reduced = false,
    }) => pixels((c) {
      sky(c, size);
      BossHealthBarArt.paint(c, size, sim.boss!, reducedMotion: reduced);
      StragglerArt.owedTag(c, size, sim, reducedMotion: reduced);
    }, size);

    testWidgets('the tag shows while any are owed, then ALL CAUGHT!', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const size = Size(640, 360);
        final region = StragglerArt.tagBounds(size, fight().boss!).inflate(6);
        final none = await tag(fight(escaped: 0), size);
        final owed = await tag(fight(), size);
        expect(changed(none, owed, size, region), greaterThan(300));
        // All five caught: ALL CAUGHT! (a different picture), then nothing.
        final allCaught = fight(caught: 5, caughtAt: 20, elapsed: 21);
        expect(StragglerArt.caughtAt(allCaught.vanguard!), 20);
        final done = await tag(allCaught, size);
        expect(changed(owed, done, size, region), greaterThan(150));
        expect(changed(none, done, size, region), greaterThan(300));
        final gone = await tag(
          fight(
            caught: 5,
            caughtAt: 20,
            elapsed: 20 + StragglerArt.caughtSeconds + .01,
          ),
          size,
        );
        expect(changed(none, gone, size), 0);
        // Nothing escaped, nothing owed: no tag, and no ALL CAUGHT!.
        expect(StragglerArt.caughtAt(fight(escaped: 0).vanguard!), isNull);
        expect(
          changed(none, await tag(fight(escaped: 0, elapsed: 2), size), size),
          0,
        );
      });
    });

    testWidgets('a catch pops the tag, but not under Reduced Motion', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const size = Size(640, 360);
        FlightSimulation after(double t) =>
            fight(caught: 1, caughtAt: 20, elapsed: 20 + t);
        final region = StragglerArt.tagBounds(size, after(0).boss!).inflate(10);
        expect(
          changed(
            await tag(after(.15), size),
            await tag(after(1), size),
            size,
            region,
          ),
          greaterThan(40),
        );
        expect(
          changed(
            await tag(after(.15), size, reduced: true),
            await tag(after(1), size, reduced: true),
            size,
            region,
          ),
          0,
        );
      });
    });

    testWidgets(
      'the tag keeps clear of the flight HUD, PUFFED x2 and the STRONGER! card',
      (tester) async {
        await tester.runAsync(() async {
          for (final s in _sizes) {
            final sim = fight();
            final box = StragglerArt.tagBounds(s, sim.boss!);
            expect(box.left, greaterThanOrEqualTo(0));
            expect(box.bottom, lessThan(s.height * .2));
            for (final zone in _hudZones(s)) {
              expect(box.overlaps(zone), isFalse, reason: '$s: $zone');
            }
            final u = BossHealthBarArt.unit(s);
            final puffed = KingCooHudArt.tagBox(
              BossHealthBarArt.bounds(s, sim.boss!),
              BossHealthBarArt.track(s, sim.boss!),
              u,
            );
            expect(box.overlaps(puffed), isFalse, reason: '$s: PUFFED x2');
            // The STRONGER! card, as the plate hangs it, never reaches it.
            final card = await pixels((c) {
              sky(c, s);
              BossHealthBarArt.paint(
                c,
                s,
                _boss(BossKind.kingCoo, share: .6, stage: 1, since: .8),
                reducedMotion: false,
              );
            }, s);
            final settled = await pixels((c) {
              sky(c, s);
              BossHealthBarArt.paint(
                c,
                s,
                _boss(BossKind.kingCoo, share: .6, stage: 1),
                reducedMotion: false,
              );
            }, s);
            expect(
              changed(card, settled, s, box.deflate(1)),
              0,
              reason: '$s: STRONGER!',
            );
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets('a straggler wears its scuffs and the comes-back badge', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const size = Size(160, 120), h = 360.0;
        SkyEnemy pigeon() => SkyEnemy(
          x: 80 / h,
          y: 70 / h,
          appearance: EnemyKind.alleyPigeon.index,
          flightPhase: 2.399963,
          squad: true,
          throwsCrumbs: true,
        )..age = 2;
        Future<Uint8List> draw({required bool straggler}) => pixels((c) {
          sky(c, size);
          EnemyArt.paint(
            c,
            h,
            pigeon(),
            birdY: .5,
            reducedMotion: false,
            straggler: straggler,
          );
        }, size);
        expect(
          changed(
            await draw(straggler: false),
            await draw(straggler: true),
            size,
          ),
          greaterThan(80),
        );
      });
    });

    test('the card says a missed one comes back', () {
      expect(
        BossVanguardArt.call(BossKind.kingCoo, crusts: true, returns: true),
        contains('comes back'),
      );
    });
  });
}
