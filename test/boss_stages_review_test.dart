// Visual review of the staged campaign bosses and their vanguards (rules
// version 44). Writes PNGs to build/visual-review/boss-stages/ for a person
// to look at; the assertions live in boss_stages_art_test.dart.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';

import 'boss_stages_support.dart';

const _folder = 'build/visual-review/boss-stages';

/// Landscape phone viewports: 16:9 at two sizes, 2.2:1 and the narrowest.
const _sizes = [Size(640, 360), Size(800, 360), Size(792, 360)];

const _kinds = [
  BossKind.baronBat,
  BossKind.spitterBeetle,
  BossKind.duskMoth,
  BossKind.pirate,
  BossKind.dragon,
  BossKind.kingCoo,
  BossKind.searchlightGargoyle,
];

/// A staged campaign boss [fight] seconds into its attack at [share] of its
/// health, having grown stronger [since] seconds ago (to [stage]).
SkyBoss staged(
  BossKind kind, {
  double fight = 6,
  double share = 1,
  int stage = 0,
  double since = 30,
  bool staged = true,
}) {
  final boss = SkyBoss(
    number: 1,
    x: 1.6,
    cinematic: true,
    kind: kind,
    debut: true,
    staged: staged,
    maxHp: staged ? SkyBoss.campaignHealthFor(kind) : null,
  )..age = 0;
  boss.age = boss.arrivalDuration + fight - 40;
  final target = (boss.maxHp * share).round();
  if (target < boss.maxHp) {
    // The blow that took it there landed long ago (no chip).
    boss.takeDamage(boss.maxHp - target);
  }
  boss.age = boss.arrivalDuration + fight;
  if (stage > 0) {
    boss
      ..stageReached = stage
      ..stageUpAt = boss.age - since;
    if (stage == 2) boss.enragedAt = boss.age - since;
  }
  return boss;
}

void _sky(Canvas c, Size size, {bool dusk = false}) {
  c.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dusk
            ? const [Color(0xff485584), Color(0xffadb6da)]
            : const [Color(0xff90d5ee), Color(0xffbde9f6)],
      ).createShader(Offset.zero & size),
  );
}

typedef _Row = (String, SkyBoss Function(BossKind), {bool reduced});

final List<_Row> _rows = [
  ('unstaged (endless)', (k) => staged(k, staged: false), reduced: false),
  ('warm-up full', (k) => staged(k), reduced: false),
  (
    'warm-up glint',
    // Boss age 7.05: halfway through a glint (every 3.4 s).
    (k) => staged(k, fight: 2.45),
    reduced: false,
  ),
  ('warm-up 80%', (k) => staged(k, share: .8), reduced: false),
  (
    'stage-up +0.05s',
    (k) => staged(k, share: .65, stage: 1, since: .05),
    reduced: false,
  ),
  (
    'stage-up +0.2s',
    (k) => staged(k, share: .65, stage: 1, since: .2),
    reduced: false,
  ),
  (
    'stage-up +0.5s',
    (k) => staged(k, share: .65, stage: 1, since: .5),
    reduced: false,
  ),
  (
    'stage-up +1.4s',
    (k) => staged(k, share: .62, stage: 1, since: 1.4),
    reduced: false,
  ),
  (
    'stage-up +2.0s',
    (k) => staged(k, share: .6, stage: 1, since: 2.0),
    reduced: false,
  ),
  ('full fight 50%', (k) => staged(k, share: .5, stage: 1), reduced: false),
  (
    'fury onset +0.2s',
    (k) => staged(k, share: .32, stage: 2, since: .2),
    reduced: false,
  ),
  ('fury 20%', (k) => staged(k, share: .2, stage: 2), reduced: false),
  (
    'reduced stage-up +0.2s',
    (k) => staged(k, share: .65, stage: 1, since: .2),
    reduced: true,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  Future<ui.Image> draw(void Function(Canvas) paint, Size size) {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder));
    return recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
  }

  testWidgets('health bar stage sheets', (tester) async {
    await tester.runAsync(() async {
      final out = Directory('$_folder/health-bar');
      for (final size in _sizes) {
        for (final kind in _kinds) {
          // Strips of the top of the viewport, one per state, labelled
          // (deep enough for the STRONGER! card and its hint).
          const strip = 76.0;
          final frames = <(String, ui.Image)>[];
          for (final (label, make, :reduced) in _rows) {
            frames.add((
              label,
              await draw((c) {
                c.clipRect(Offset.zero & Size(size.width, strip));
                _sky(
                  c,
                  size,
                  dusk:
                      kind == BossKind.duskMoth ||
                      kind == BossKind.kingCoo ||
                      kind == BossKind.searchlightGargoyle,
                );
                BossHealthBarArt.paint(
                  c,
                  size,
                  make(kind),
                  reducedMotion: reduced,
                );
              }, Size(size.width, strip)),
            ));
          }
          await sheet(
            out,
            '${kindName(kind)}-${size.width.toInt()}',
            frames,
            cols: 1,
            height: strip,
          );
          for (final (_, image) in frames) {
            image.dispose();
          }
          if (size.width != 640) continue;
          // The plate alone at 3x, two columns.
          final plate = BossHealthBarArt.bounds(size, staged(kind));
          final crop = Rect.fromLTRB(
            plate.left - 14,
            0,
            plate.right + 14,
            strip,
          );
          const zoom = 3.0;
          final zoomed = <(String, ui.Image)>[];
          for (final (label, make, :reduced) in _rows) {
            zoomed.add((
              label,
              await draw((c) {
                c.scale(zoom);
                c.translate(-crop.left, 0);
                c.clipRect(crop);
                _sky(
                  c,
                  size,
                  dusk:
                      kind == BossKind.duskMoth ||
                      kind == BossKind.kingCoo ||
                      kind == BossKind.searchlightGargoyle,
                );
                BossHealthBarArt.paint(
                  c,
                  size,
                  make(kind),
                  reducedMotion: reduced,
                );
              }, Size(crop.width * zoom, strip * zoom)),
            ));
          }
          await sheet(
            out,
            'zoom-${kindName(kind)}',
            zoomed,
            cols: 2,
            height: strip * zoom,
          );
          for (final (_, image) in zoomed) {
            image.dispose();
          }
        }
      }
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  /// A real flight of [kind]'s level at [width], flown to its fight ([fight]
  /// seconds into it), the vanguard shot down on the way.
  Future<StagesGame> toFight(
    WidgetTester tester,
    BossKind kind,
    double width, {
    bool reduced = false,
    double fight = 2.5,
  }) async {
    final g = await stagesGame(tester, kind, width, reduced: reduced);
    g.shooting = true;
    g.runUntil((s) => s.boss != null, seconds: 60);
    g.shooting = false;
    g.bossTo(g.boss!.arrivalDuration + fight);
    return g;
  }

  const vanguards = [
    BossKind.baronBat,
    BossKind.spitterBeetle,
    BossKind.duskMoth,
    BossKind.kingCoo,
  ];
  for (final width in [640.0, 800.0, 792.0]) {
    testWidgets('vanguard at $width', (tester) async {
      await tester.runAsync(() async {
        final out = Directory('$_folder/vanguard');
        for (final kind in vanguards) {
          for (final reduced in [false, true]) {
            if (reduced && (width != 640 || kind != BossKind.kingCoo)) {
              continue;
            }
            final g = await stagesGame(tester, kind, width, reduced: reduced);
            final start = g.sim.vanguard!.startedAt;
            final frames = <(String, ui.Image)>[];
            Future<void> at(double t, String label, {String? file}) async {
              g.run(start + t - g.sim.elapsed);
              frames.add((label, await g.render()));
              if (file != null) {
                await save(
                  out,
                  'frames/${kindName(kind)}-${width.toInt()}'
                  '${reduced ? '-reduced' : ''}-$file',
                  frames.last.$2,
                );
              }
            }

            await at(.1, 'banner +0.1s');
            await at(.35, 'banner +0.35s', file: 'banner');
            await at(1.4, 'banner +1.4s');
            await at(2.45, 'banner +2.45s');
            g.shooting = true;
            // The second wave's pips spring up as it is sent.
            final guard = g.sim.vanguard!;
            await at(
              guard.waves[1].at + .1,
              'wave 2 sent +0.1s',
              file: 'pop-sent',
            );
            // A member going down (or past): its pip pops.
            bool popping(FlightSimulation s) => [
              ...s.vanguard!.downedAt.values,
              ...s.vanguard!.goneAt.values,
            ].any((t) => s.elapsed - t >= .08 && s.elapsed - t < .1);
            try {
              g.runUntil(popping, seconds: 8);
              frames.add(('a pip pops', await g.render()));
              await save(
                out,
                'frames/${kindName(kind)}-${width.toInt()}'
                '${reduced ? '-reduced' : ''}-pop',
                frames.last.$2,
              );
            } on StateError {
              // (No member went in time; the sheet goes without.)
            }
            await at(
              math.max(5.5, g.sim.elapsed - start + .4),
              'wave 2',
              file: 'plate-mid',
            );
            await at(9.5, 'wave 3', file: 'plate-late');
            g.runUntil((s) => s.vanguard!.cleared, seconds: 40);
            final cleared = g.sim.vanguard!.clearedAt! - start;
            await at(cleared + .2, 'cleared +0.2s', file: 'plate-clear');
            await at(cleared + .7, 'cleared +0.7s');
            g.shooting = false;
            g.runUntil((s) => s.boss != null);
            g.bossTo(.25);
            frames.add(('boss age 0.25', await g.render()));
            await sheet(
              out,
              '${kindName(kind)}-${width.toInt()}${reduced ? '-reduced' : ''}',
              frames,
              cols: 3,
              scale: .75,
            );
            // The plate in every frame, at 3x.
            final crop = Rect.fromCenter(
              center: Offset(width / 2, 22),
              width: 300,
              height: 44,
            );
            final plates = <(String, ui.Image)>[
              for (final (label, image) in frames)
                (label, await zoom(image, crop, 3)),
            ];
            await sheet(
              out,
              'zoom-${kindName(kind)}-${width.toInt()}'
              '${reduced ? '-reduced' : ''}',
              plates,
              cols: 2,
              height: 132,
            );
            for (final (_, image) in [...frames, ...plates]) {
              image.dispose();
            }
          }
        }
      });
    }, timeout: const Timeout(Duration(minutes: 10)));
  }

  for (final width in [640.0, 792.0]) {
    testWidgets('power-up timelines at $width', (tester) async {
      await tester.runAsync(() async {
        final out = Directory('$_folder/power-up');
        for (final kind in _kinds) {
          for (final reduced in [false, true]) {
            if (reduced &&
                (width != 640 ||
                    (kind != BossKind.baronBat && kind != BossKind.kingCoo))) {
              continue;
            }
            final g = await toFight(tester, kind, width, reduced: reduced);
            final frames = <(String, ui.Image)>[];
            frames.add(('warm-up', await g.render()));
            g.hurtTo(.66);
            final up = g.boss!.stageUpAt;
            for (final t in const [.05, .15, .3, .5, .8, 1.15, 1.5]) {
              g.bossTo(up + t);
              frames.add(('stage 1 +${t}s', await g.render()));
              if (t == .3 || t == .8) {
                await save(
                  out,
                  'frames/${kindName(kind)}-${width.toInt()}'
                  '${reduced ? '-reduced' : ''}-stage1-$t',
                  frames.last.$2,
                );
              }
            }
            g.bossTo(up + 3);
            g.hurtTo(.32);
            final fury = g.boss!.stageUpAt;
            for (final t in const [.15, .5]) {
              g.bossTo(fury + t);
              frames.add(('fury +${t}s', await g.render()));
            }
            await sheet(
              out,
              '${kindName(kind)}-${width.toInt()}${reduced ? '-reduced' : ''}',
              frames,
              cols: 3,
              scale: .75,
            );
            for (final (_, image) in frames) {
              image.dispose();
            }
          }
        }
      });
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
