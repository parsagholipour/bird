import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';

const _folder = 'build/visual-review/boss-polish/health-bar';

/// Landscape phone viewports (the app is locked to landscape).
const _sizes = [
  Size(568, 320),
  Size(640, 360),
  Size(800, 360),
  Size(844, 390),
  Size(932, 430),
];

const _kinds = [
  (BossKind.baronBat, 1),
  (BossKind.spitterBeetle, 2),
  (BossKind.duskMoth, 3),
  (BossKind.pirate, 4),
];

/// A boss [fight] seconds into its attack, with [hits] landing 1.5 s apart
/// and the last one [since] seconds before the frame.
SkyBoss bossAfter(
  BossKind kind,
  int number, {
  double fight = 1,
  List<double> hits = const [],
  double since = 3,
  bool cinematic = true,
}) {
  final boss = SkyBoss(number: number, x: 1.5, kind: kind, cinematic: cinematic)
    ..age = 0;
  final start = boss.arrivalDuration + fight;
  var at = start - since - (hits.length - 1) * 1.5;
  for (final share in hits) {
    boss.age = at;
    boss.takeDamage((boss.maxHp * share).round());
    at += 1.5;
  }
  boss.age = start;
  return boss;
}

typedef _State = (String, SkyBoss Function(BossKind, int), {bool reduced});

final List<_State> _states = [
  ('full', (k, n) => bossAfter(k, n), reduced: false),
  (
    'chip-flash',
    (k, n) => bossAfter(k, n, hits: [.2], since: .03),
    reduced: false,
  ),
  (
    'chip-hold',
    (k, n) => bossAfter(k, n, hits: [.2], since: .22),
    reduced: false,
  ),
  (
    'chip-drain',
    (k, n) => bossAfter(k, n, hits: [.2], since: .55),
    reduced: false,
  ),
  ('damaged', (k, n) => bossAfter(k, n, hits: [.15, .15]), reduced: false),
  (
    'fury-onset',
    (k, n) => bossAfter(k, n, hits: [.3, .25], since: .2),
    reduced: false,
  ),
  (
    'fury',
    (k, n) => bossAfter(k, n, fight: 2, hits: [.3, .32]),
    reduced: false,
  ),
  (
    'near-death',
    (k, n) => bossAfter(k, n, fight: 2, hits: [.5, .42], since: .3),
    reduced: false,
  ),
  (
    'reduced-chip',
    (k, n) => bossAfter(k, n, hits: [.2], since: .22),
    reduced: true,
  ),
];

final List<_State> _shieldStates = [
  (
    'shield-warning-early',
    (k, n) => bossAfter(k, n, fight: 4.3, hits: [.1]),
    reduced: false,
  ),
  (
    'shield-warning',
    (k, n) => bossAfter(k, n, fight: 4.7, hits: [.1]),
    reduced: false,
  ),
  (
    'shielded',
    (k, n) => bossAfter(k, n, fight: 5.6, hits: [.1]),
    reduced: false,
  ),
  (
    'shield-block',
    (k, n) {
      final boss = bossAfter(k, n, fight: 5.6, hits: [.1]);
      boss.lastShieldHitAt = boss.age - .1;
      return boss;
    },
    reduced: false,
  ),
  (
    'shielded-fury',
    (k, n) => bossAfter(k, n, fight: 5.8, hits: [.3, .3]),
    reduced: false,
  ),
];

/// The classic (pre-cinematic) encounter keeps a visible plate on arrival
/// and defeat.
final List<(String, SkyBoss Function())> _classic = [
  ('classic-arriving', () => SkyBoss(number: 1, x: 1.5)..age = 1.1),
  ('classic-fighting', () => bossAfter(BossKind.baronBat, 1, cinematic: false)),
  (
    'classic-defeated',
    () {
      final boss = bossAfter(BossKind.baronBat, 1, cinematic: false);
      boss.takeDamage(boss.maxHp);
      boss.defeatedAt = boss.age;
      boss.age += .4;
      return boss;
    },
  ),
];

String _kindName(BossKind kind) => switch (kind) {
  BossKind.baronBat => 'baron-bat',
  BossKind.spitterBeetle => 'spitter-king',
  BossKind.duskMoth => 'dusk-empress',
  BossKind.pirate => 'pirate-captain',
  BossKind.dragon => 'ember-dragon',
  BossKind.kingCoo => 'king-coo',
  BossKind.searchlightGargoyle => 'searchlight-gargoyle',
  BossKind.neferhoo => 'neferhoo',
};

/// Areas the Flutter flight HUD (SceneLayout 1000×450, contain-fit) keeps
/// for the hearts readout, the flight clock and the pause button.
List<Rect> _hudZones(Size size) {
  final scale = (size.width / 1000) < (size.height / 450)
      ? size.width / 1000
      : size.height / 450;
  final dx = (size.width - 1000 * scale) / 2;
  final dy = (size.height - 450 * scale) / 2;
  Rect at(double l, double t, double r, double b) => Rect.fromLTRB(
    dx + l * scale,
    dy + t * scale,
    dx + r * scale,
    dy + b * scale,
  );
  return [
    at(24, 18, 250, 90), // hearts + shield, up to five hearts
    at(1000 - 112 - 110, 24, 1000 - 112, 86), // clock (timed flights)
    at(1000 - 24 - 76, 18, 1000 - 24, 94), // pause
  ];
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

void drawHudZones(Canvas c, Size size) {
  for (final zone in _hudZones(size)) {
    c.drawRRect(
      RRect.fromRectAndRadius(zone, const Radius.circular(12)),
      Paint()..color = const Color(0x33fff9ed),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(zone, const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x88203b45),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  Future<ui.Image> image(void Function(Canvas) draw, Size size) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
  }

  Future<Uint8List> rgba(void Function(Canvas) draw, Size size) async {
    final shot = await image(draw, size);
    final bytes = (await shot.toByteData())!.buffer.asUint8List();
    shot.dispose();
    return bytes;
  }

  Future<void> save(void Function(Canvas) draw, String name, Size size) async {
    final shot = await image(draw, size);
    final png = (await shot.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
    file.writeAsBytesSync(png);
    shot.dispose();
  }

  void bar(Canvas c, Size size, SkyBoss boss, {bool reduced = false}) =>
      BossHealthBarArt.paint(c, size, boss, reducedMotion: reduced);

  /// Strips of the top of the viewport, one per state, stacked for review.
  Future<void> sheet(
    String name,
    Size size,
    List<(SkyBoss, bool)> rows, {
    bool dusk = false,
  }) async {
    const strip = 46.0;
    await save(
      (c) {
        for (final (boss, reduced) in rows) {
          c.save();
          c.clipRect(Offset.zero & Size(size.width, strip));
          _sky(c, size, dusk: dusk);
          drawHudZones(c, size);
          bar(c, size, boss, reduced: reduced);
          c.restore();
          c.translate(0, strip + 2);
        }
      },
      name,
      Size(size.width, rows.length * (strip + 2)),
    );
  }

  testWidgets('boss health bar review sheets', (tester) async {
    await tester.runAsync(() async {
      for (final size in [const Size(640, 360), const Size(800, 360)]) {
        final width = size.width.toInt();
        for (final (kind, number) in _kinds) {
          final states = [
            ..._states,
            if (kind == BossKind.duskMoth) ..._shieldStates,
          ];
          await sheet('${_kindName(kind)}-$width', size, [
            for (final (_, make, :reduced) in states)
              (make(kind, number), reduced),
          ], dusk: kind == BossKind.duskMoth);
          for (final (state, make, :reduced) in states) {
            await save(
              (c) {
                _sky(c, size, dusk: kind == BossKind.duskMoth);
                bar(c, size, make(kind, number), reduced: reduced);
              },
              'states/${_kindName(kind)}-$state-$width',
              size,
            );
          }
        }
        await sheet('classic-$width', size, [
          for (final (_, make) in _classic) (make(), false),
        ]);
      }
      // One sheet per viewport: every boss at full, fury and (moth) shield.
      for (final size in _sizes) {
        await sheet(
          'sizes-${size.width.toInt()}x${size.height.toInt()}',
          size,
          [
            for (final (kind, number) in _kinds) ...[
              (bossAfter(kind, number, hits: [.2], since: .22), false),
              (bossAfter(kind, number, fight: 2, hits: [.3, .32]), false),
            ],
            (bossAfter(BossKind.duskMoth, 3, fight: 5.6, hits: [.1]), false),
          ],
        );
      }
    });
  });

  testWidgets('plate stays clear of the flight HUD at every phone size', (
    tester,
  ) async {
    for (final size in _sizes) {
      for (final (kind, number) in _kinds) {
        for (final (state, make, reduced: _) in [
          ..._states,
          ..._shieldStates,
        ]) {
          final boss = make(kind, number);
          final plate = BossHealthBarArt.bounds(size, boss);
          expect(plate.left, greaterThanOrEqualTo(0));
          expect(plate.right, lessThanOrEqualTo(size.width));
          // A slim strip: at most ~8% of the height tall, ~11% of it
          // down from the top, and under 4% of the screen's area.
          expect(plate.height, lessThanOrEqualTo(size.height * .08));
          expect(plate.bottom, lessThanOrEqualTo(size.height * .11));
          expect(
            plate.width * plate.height,
            lessThan(size.width * size.height * .04),
            reason: '$kind $state at $size',
          );
          for (final zone in _hudZones(size)) {
            expect(
              plate.overlaps(zone),
              isFalse,
              reason: '$kind $state at $size overlaps $zone',
            );
          }
        }
      }
    }
  });

  testWidgets('the Spitter King wears his flask crown on the crest', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const size = Size(800, 360);
      Future<Uint8List> frame(BossKind kind, int number) =>
          rgba((c) => bar(c, size, bossAfter(kind, number)), size);
      // The crest sits at the strip's left end; the crown glyph is drawn in
      // the strip's own night color, so a dark mask isolates its shape.
      Future<List<int>> glyph(BossKind kind, int number) async {
        final strip = BossHealthBarArt.bounds(size, bossAfter(kind, number));
        final pixels = await frame(kind, number);
        final mask = <int>[];
        for (var y = strip.top.floor(); y < strip.bottom.ceil(); y++) {
          for (
            var x = strip.left.floor() + 2;
            x < strip.left.floor() + strip.height * 1.1;
            x++
          ) {
            final i = (y * size.width.toInt() + x) * 4;
            mask.add(
              pixels[i] < 70 && pixels[i + 1] < 80 && pixels[i + 2] < 120
                  ? 1
                  : 0,
            );
          }
        }
        return mask;
      }

      final baron = await glyph(BossKind.baronBat, 1);
      final spitter = await glyph(BossKind.spitterBeetle, 2);
      var differing = 0, spitterInk = 0, baronInk = 0;
      for (var i = 0; i < baron.length; i++) {
        if (baron[i] != spitter[i]) differing++;
        spitterInk += spitter[i];
        baronInk += baron[i];
      }
      expect(
        spitterInk,
        greaterThan(baronInk ~/ 2),
        reason: 'a crown is drawn',
      );
      expect(
        differing,
        greaterThan(15),
        reason: 'the flasks are not the generic crown',
      );
    });
  });

  testWidgets('bar is deterministic and shows the damage chip', (tester) async {
    await tester.runAsync(() async {
      const size = Size(800, 360);
      Future<Uint8List> frame(SkyBoss boss, {bool reduced = false}) =>
          rgba((c) => bar(c, size, boss, reduced: reduced), size);
      int changed(Uint8List a, Uint8List b, Rect region) {
        var count = 0;
        for (var y = region.top.floor(); y < region.bottom.ceil(); y++) {
          for (var x = region.left.floor(); x < region.right.ceil(); x++) {
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

      for (final (kind, number) in _kinds) {
        for (final (state, make, :reduced) in [..._states, ..._shieldStates]) {
          if (kind != BossKind.duskMoth && state.startsWith('shield')) continue;
          expect(
            await frame(make(kind, number), reduced: reduced),
            await frame(make(kind, number), reduced: reduced),
            reason: '$kind $state',
          );
        }
        final track = BossHealthBarArt.track(size, bossAfter(kind, number));
        final hold = await frame(
          bossAfter(kind, number, hits: [.2], since: .22),
        );
        final settled = await frame(
          bossAfter(kind, number, hits: [.2], since: 2),
        );
        // The lost fifth of the bar stays visible as a chip while it holds.
        final lost = Rect.fromLTRB(
          track.left + track.width * .82,
          track.top + 2,
          track.left + track.width * .98,
          track.bottom - 2,
        );
        expect(
          changed(hold, settled, lost),
          greaterThan(lost.width * lost.height * .6),
        );
        final after = await frame(
          bossAfter(
            kind,
            number,
            hits: [.2],
            since: BossHealthBarArt.chipSeconds + .01,
          ),
        );
        expect(changed(after, settled, lost), 0);
      }

      // Reduced motion: no pulsing, so frames seconds apart match.
      final early = bossAfter(
        BossKind.spitterBeetle,
        2,
        fight: 2,
        hits: [.3, .32],
      );
      final late = bossAfter(
        BossKind.spitterBeetle,
        2,
        fight: 2.37,
        hits: [.3, .32],
      )..lastHitAt = early.lastHitAt;
      expect(
        await frame(early, reduced: true),
        await frame(late, reduced: true),
      );

      // Each boss owns a fill color while healthy.
      final centers = <int>{};
      for (final (kind, number) in _kinds) {
        final boss = bossAfter(kind, number);
        final track = BossHealthBarArt.track(size, boss);
        final pixels = await frame(boss);
        final p = Offset(track.left + track.width * .23, track.center.dy + 1);
        final i = (p.dy.toInt() * size.width.toInt() + p.dx.toInt()) * 4;
        centers.add(pixels[i] << 16 | pixels[i + 1] << 8 | pixels[i + 2]);
      }
      expect(centers, hasLength(_kinds.length));

      // Cinematic cutscenes hide the plate; the classic encounter shows it.
      final blank = await rgba((_) {}, size);
      final arriving = SkyBoss(number: 1, x: 1.5, cinematic: true)..age = 1;
      expect(await frame(arriving), blank);
      expect(await frame(SkyBoss(number: 1, x: 1.5)..age = 1), isNot(blank));
    });
  });
}
