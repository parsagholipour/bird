import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_ammo_art.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_defeat_art.dart';
import 'package:push_up_bird/game/ny_placeholder_art.dart';
import 'package:push_up_bird/domain/campaign_story.dart' show StoryMood;
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/story_boss_art.dart';

/// The scaffold's guard against the top risk in the systems report: a new
/// kind drawn by another kind's art. Every `EnemyKind` and `BossKind` is
/// rendered through every shared dispatch point (encounter, name card, health
/// bar, ammo, story pose, headwear, defeat) and must produce a picture no
/// other kind produces, so a kind that falls through to Baron Bat's rig,
/// crown or palette, or to a bat painter, fails here. The placeholders are
/// replaced by the real painters; the test stays and keeps every future kind
/// distinct.

/// An FNV-1a hash of the picture [paint] draws, at [size].
Future<String> shot(
  void Function(Canvas canvas) paint, {
  Size size = const Size(640, 360),
}) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  picture.dispose();
  final bytes = data.buffer.asUint8List();
  var hash = 0xcbf29ce484222325;
  for (final b in bytes) {
    hash ^= b;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  // Something was drawn.
  expect(bytes.any((b) => b != 0), isTrue, reason: 'an empty picture');
  return hash.toRadixString(16);
}

/// Expects the pictures of the campaign-only kinds (`BossKind.kingCoo`, ...
/// or `EnemyKind.alleyPigeon`) to differ from every other kind's. [pictures]
/// maps a kind's name to its picture's hash. Two new kinds may share a
/// picture where [newMayMatch] (a shared placeholder); the older kinds may
/// always share one (a generic victory card).
void expectNovel(
  String what,
  Map<String, String> pictures, {
  required Set<String> novel,
  bool newMayMatch = false,
}) {
  final clashes = <String>[];
  for (final a in novel) {
    for (final MapEntry(:key, :value) in pictures.entries) {
      if (key == a || pictures[a] != value) continue;
      if (newMayMatch && novel.contains(key)) continue;
      clashes.add('$a = $key');
    }
  }
  expect(clashes, isEmpty, reason: '$what: drawn alike: $clashes');
}

Set<String> get newBosses => {
  for (final kind in BossKind.values)
    if (kind.campaignOnly) kind.name,
};

Future<void> fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

FlightSimulation arenaWith(SkyBoss? boss) =>
    FlightSimulation(
        rules: TapFlyMode(),
        practice: true,
        course: FlightCourse.starTrail,
      )
      ..phase = RunPhase.playing
      ..started = true
      ..boss = boss;

SkyBoss bossOf(BossKind kind, {double? age, bool fury = false}) {
  final boss = SkyBoss(
    number: kind.index + 1,
    x: 1.4,
    kind: kind,
    cinematic: true,
  )..fireIn = 5;
  boss.age = age ?? boss.arrivalDuration + 3;
  if (fury) {
    boss
      ..hp = boss.maxHp ~/ 2
      ..enragedAt = boss.age - 2;
  }
  return boss;
}

void main() {
  testWidgets('no enemy kind is drawn like another (the pigeon is no bat)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final reduced in [true, false]) {
        final live = <String, String>{};
        final dead = <String, String>{};
        for (final kind in EnemyKind.values) {
          final enemy = SkyEnemy(
            x: 1.0,
            y: .5,
            appearance: kind.index,
            flightPhase: 1,
          )..age = 1.2;
          live[kind.name] = await shot(
            (c) => EnemyArt.paint(
              c,
              360,
              enemy,
              birdY: .5,
              reducedMotion: reduced,
            ),
          );
          dead[kind.name] = await shot(
            (c) => EnemyDefeatArt.paint(
              c,
              const Offset(320, 180),
              16,
              age: .1,
              reducedMotion: reduced,
              kind: kind,
            ),
          );
        }
        expectNovel(
          'enemies, reduced $reduced',
          live,
          novel: {EnemyKind.alleyPigeon.name, EnemyKind.mummyBat.name},
        );
        expectNovel(
          'enemy defeats, reduced $reduced',
          dead,
          novel: {EnemyKind.alleyPigeon.name, EnemyKind.mummyBat.name},
        );
      }
      // The stub pigeon is the placeholder, not a bat: it is in the shared
      // painter signature and draws inside the designer's envelope.
      final pigeon = await shot((c) {
        c.translate(320, 180);
        NyPlaceholderArt.pigeon(c, 16, seconds: 1, reducedMotion: true);
      });
      final bat = SkyEnemy(
        x: 1.0,
        y: .5,
        appearance: EnemyKind.simpleBat.index,
      );
      expect(
        pigeon,
        isNot(
          await shot(
            (c) => EnemyArt.paint(c, 360, bat, birdY: .5, reducedMotion: true),
          ),
        ),
      );
    });
  });

  testWidgets(
    'no boss kind is staged like another (Coo and the Gargoyle are no Baron)',
    (tester) async {
      await tester.runAsync(() async {
        await fonts();
        final stages =
            <
              (
                String,
                SkyBoss Function(BossKind),
                void Function(Canvas, Size, FlightSimulation, BossMotion),
              )
            >[
              ('fighting', (kind) => bossOf(kind), BossEncounterArt.paint),
              (
                'fury',
                (kind) => bossOf(kind, fury: true),
                BossEncounterArt.paint,
              ),
              (
                'arriving',
                (kind) => bossOf(kind, age: 2.4),
                BossEncounterArt.paint,
              ),
              (
                'defeated',
                (kind) => bossOf(kind, age: 10)
                  ..x = 1
                  ..defeatedAt = 10 - 1.0,
                BossEncounterArt.paint,
              ),
              (
                'name card',
                (kind) => bossOf(kind, age: 3.0),
                BossEncounterArt.foreground,
              ),
              (
                'omen',
                (kind) => bossOf(kind, age: 1.0),
                BossEncounterArt.foreground,
              ),
              // (The victory card is generic text, shared by every kind, so
              // it cannot tell one boss's art from another's.)
              (
                'backdrop',
                (kind) => bossOf(kind, age: 6),
                (c, s, sim, m) => BossEncounterArt.backdrop(c, s, m.boss, m),
              ),
            ];
        for (final (name, make, layer) in stages) {
          for (final reduced in [true, false]) {
            final pictures = <String, String>{};
            for (final kind in BossKind.values) {
              final boss = make(kind);
              final sim = arenaWith(boss);
              pictures[kind.name] = await shot(
                (c) => layer(
                  c,
                  const Size(640, 360),
                  sim,
                  BossMotion(boss, reducedMotion: reduced),
                ),
              );
            }
            expectNovel('$name, reduced $reduced', pictures, novel: newBosses);
          }
        }
      });
    },
  );

  testWidgets('no boss kind has another\'s health bar, ammo or accent', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await fonts();
      final bars = <String, String>{};
      final furyBars = <String, String>{};
      final ammo = <String, String>{};
      for (final kind in BossKind.values) {
        final boss = bossOf(kind);
        bars[kind.name] = await shot(
          (c) => BossHealthBarArt.paint(c, const Size(640, 360), boss),
        );
        final furious = bossOf(kind, fury: true);
        furyBars[kind.name] = await shot(
          (c) => BossHealthBarArt.paint(c, const Size(640, 360), furious),
        );
        ammo[kind.name] = await shot(
          (c) => BossAmmoArt.paint(
            c,
            center: const Offset(320, 180),
            radius: 24,
            direction: 3.1,
            attack: EnemyAttack.none,
            kind: kind,
            seconds: 1,
            reducedMotion: true,
          ),
        );
      }
      expectNovel('health bars', bars, novel: newBosses);
      expectNovel('fury health bars', furyBars, novel: newBosses);
      expectNovel('boss ammo', ammo, novel: newBosses, newMayMatch: true);
      expectNovel('accents', {
        for (final kind in BossKind.values)
          kind.name: BossHealthBarArt.accent(
            bossOf(kind),
          ).toARGB32().toString(),
      }, novel: newBosses);
    });
    // The new kinds never use another boss's shot style.
    final styles = {
      for (final kind in BossKind.values) kind: BossAmmoArt.styleFor(kind),
    };
    expect(styles[BossKind.kingCoo], BossAmmoStyle.placeholder);
    // The Gargoyle's feather has its own style (G6): never the pellet.
    expect(styles[BossKind.searchlightGargoyle], BossAmmoStyle.stoneFeather);
    expect(
      styles.entries
          .where((e) => e.value == BossAmmoStyle.placeholder)
          .map((e) => e.key),
      // Neferhoo (rules 50) fires no boss ammo at all: his letters and ankhs
      // are his own art, so the style is never drawn for him.
      [BossKind.kingCoo, BossKind.neferhoo],
    );
  });

  testWidgets('no boss kind has another\'s story pose, headwear or stamp', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final mood in StoryMood.values) {
        for (final beaten in [false, true]) {
          final poses = <String, String>{};
          for (final kind in BossKind.values) {
            poses[kind.name] = await shot((c) {
              final (:unit, :origin, :reach) = StoryBossArt.portrait(
                kind,
                beaten: beaten,
              );
              c.translate(320 + origin.dx, 300 + origin.dy);
              c.scale(unit);
              StoryBossArt.paint(c, kind, mood, beaten: beaten);
              expect(reach.isEmpty, isFalse);
              expect(unit, greaterThan(0));
            });
          }
          expectNovel(
            'story poses, $mood beaten $beaten',
            poses,
            novel: newBosses,
          );
        }
      }
      final headwear = <String, String>{};
      final stamps = <String, String>{};
      for (final kind in BossKind.values) {
        headwear[kind.name] = await shot(
          (c) => CampaignHeadwear.paint(
            c,
            const Rect.fromLTWH(200, 100, 240, 160),
            kind,
          ),
        );
        stamps[kind.name] = await shot(
          (c) => CampaignStampPainter(
            kind,
            chapter: 3,
          ).paint(c, const Size(240, 160)),
          size: const Size(240, 160),
        );
      }
      expectNovel('headwear', headwear, novel: newBosses);
      expectNovel('stamps', stamps, novel: newBosses);
    });
    expect({
      for (final kind in BossKind.values) CampaignHeadwear.name(kind),
    }, hasLength(BossKind.values.length));
    expect({
      for (final kind in BossKind.values) CampaignHeadwear.field(kind),
    }, hasLength(BossKind.values.length));
    expect(CampaignHeadwear.name(BossKind.kingCoo), 'King Coo');
    expect(
      CampaignHeadwear.name(BossKind.searchlightGargoyle),
      'Searchlight Gargoyle',
    );
  });

  test(
    'the placeholder palettes and stubs are defined for both mini-bosses',
    () {
      // New York's two; Neferhoo has his own (neferhoo_placeholder_art.dart).
      for (final kind in [BossKind.kingCoo, BossKind.searchlightGargoyle]) {
        expect(NyPlaceholderArt.ramp(kind), hasLength(3), reason: kind.name);
        expect(
          NyPlaceholderArt.tint(kind),
          isNot(NyPlaceholderArt.light(kind)),
        );
        expect(NyPlaceholderArt.smoke(kind).$2, isNot(NyPlaceholderArt.ink));
        expect(NyPlaceholderArt.headwearReach(kind).isEmpty, isFalse);
      }
      // The placeholders refuse the chapter bosses: they are never a fallback.
      expect(
        () => NyPlaceholderArt.tint(BossKind.baronBat),
        throwsArgumentError,
      );
      expect(() => NyPlaceholderArt.ramp(BossKind.dragon), throwsArgumentError);
    },
  );

  test('the mini-bosses have no chapter boss\'s encounter label', () {
    // The name card reads GUARDIAN (the one word the level card, the result
    // and the card all use; R0's stub said MINI-BOSS), not ENCOUNTER 06 or 07.
    for (final kind in BossKind.values.where((kind) => kind.campaignOnly)) {
      expect(bossOf(kind).isMiniBoss, isTrue);
      expect(bossOf(kind).number, kind.index + 1);
      expect(BossEncounterArt.nameCardEyebrow(bossOf(kind)), 'GUARDIAN');
    }
    // Chapter bosses are not mini-bosses.
    for (final kind in BossKind.values.where((kind) => !kind.campaignOnly)) {
      expect(bossOf(kind).isMiniBoss, isFalse);
      expect(
        BossEncounterArt.nameCardEyebrow(bossOf(kind)),
        'ENCOUNTER ${bossOf(kind).number.toString().padLeft(2, '0')}',
      );
    }
  });
}
