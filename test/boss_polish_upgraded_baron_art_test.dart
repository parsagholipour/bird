import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/baron_screech_art.dart';
import 'package:push_up_bird/game/baron_storm_pose.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/boss_rig.dart';

import 'boss_fight_test.dart' show arena;

/// Visual review for the upgraded Baron Bat (encounter 6 onward, rules 40):
/// a pose sheet beside his debut, in-game frames through the real renderer
/// at 640×360 and 800×360 (every gap, the wall approaching and crossing the
/// bird, fury, a bat pair, the arrival and the defeat), the same under
/// Reduced Motion, plus the checks that keep the art honest to the rules:
/// the drawn wall's front and gap, determinism, exact seeks, the debut's
/// unchanged pixels and Reduced Motion.
final _folder = Directory('build/visual-review/boss-polish/upgraded-baron');
final _baselineFile = File('test/fixtures/debut_baron_baseline.json');

/// Set with --dart-define=RECORD_BARON_BASELINE=true to re-record the debut
/// Baron's pixels (only ever from a tree where his art is known good).
const _record = bool.fromEnvironment('RECORD_BARON_BASELINE');

const _birdX = FlightSimulation.birdX, _birdR = FlightSimulation.birdRadius;

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

/// FNV-1a over raw RGBA pixels.
String _hash(Uint8List bytes) {
  var h = 0xcbf29ce484222325;
  for (final b in bytes) {
    h ^= b;
    h = (h * 0x100000001b3) & 0xffffffffffffffff;
  }
  return h.toRadixString(16);
}

Future<Uint8List> _raster(
  int w,
  int h,
  void Function(Canvas) draw, {
  String? save,
}) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  if (save != null) {
    final file = File('${_folder.path}/$save.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(
      (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List(),
    );
  }
  image.dispose();
  picture.dispose();
  return bytes;
}

void _label(Canvas c, String text, Offset at, double size, Color color) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

void _sky(Canvas c, Rect rect, [List<Color>? colors]) {
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors:
            colors ??
            const [Color(0xff5b6c9e), Color(0xff8e93c0), Color(0xffd2b3c4)],
      ).createShader(rect),
  );
}

// ------------------------------------------------------------- bosses --

/// A Baron [t] seconds into the fight: the upgraded one by default.
SkyBoss _baron({
  double t = 1.2,
  bool upgraded = true,
  ScreechGap gap = ScreechGap.middle,
  double width = 800 / 360,
}) {
  final boss =
      SkyBoss(
          number: upgraded ? 6 : 1,
          x: math.max(_birdX + .55, width - .72),
          cinematic: true,
          upgraded: upgraded,
          debut: !upgraded,
        )
        ..fireIn = 1.5
        ..screechGap = gap;
  boss.age = boss.arrivalDuration + t;
  return boss;
}

void _fury(SkyBoss b) => b.hp = b.maxHp ~/ 3;
void _at(SkyBoss b, double t) => b.age = b.arrivalDuration + t;

typedef _Pose = (String, void Function(SkyBoss));

final _poses = <_Pose>[
  ('IDLE', (b) {}),
  ('CHARGING', (b) => b.fireIn = .1),
  ('WARNING · 0', (b) => _at(b, BaronScreech.warnAt + .03)),
  ('WARNING · .5', (b) => _at(b, BaronScreech.warnAt + .75)),
  ('WARNING · 1', (b) => _at(b, BaronScreech.screechAt - .02)),
  ('RELEASE', (b) => _at(b, BaronScreech.screechAt + .07)),
  ('SCREECH', (b) => _at(b, BaronScreech.screechAt + .6)),
  ('SETTLE', (b) => _at(b, BaronScreech.endAt + .15)),
  ('HIT', (b) => b.lastHitAt = b.age - .1),
  ('BECKON', (b) => b.lastSummonAt = b.age - .3),
  ('FURY', _fury),
  (
    'FURY · WARNING',
    (b) {
      _fury(b);
      _at(b, BaronScreech.warnAt + 1.1);
    },
  ),
  (
    'FURY · SCREECH',
    (b) {
      _fury(b);
      _at(b, BaronScreech.screechAt + .12);
    },
  ),
  ('ARRIVAL · SILHOUETTE', (b) => b.age = 1.5),
  ('ARRIVAL · ROAR', (b) => b.age = SkyBoss.roarAt + .25),
  ('DEFEAT · HIT', (b) => b.defeatedAt = b.age - .15),
  ('DEFEAT · OVERLOAD', (b) => b.defeatedAt = b.age - .7),
  ('DEFEAT · BURST', (b) => b.defeatedAt = b.age - 1.0),
];

SkyBoss _posed(_Pose pose, {bool upgraded = true}) {
  final boss = _baron(upgraded: upgraded);
  pose.$2(boss);
  return boss;
}

/// The whole encounter layer for [boss], its heart at [center] with a hit
/// radius of [radius] pixels, clipped to [cell].
void _paintBoss(
  Canvas c,
  Rect cell,
  SkyBoss boss,
  Offset center,
  double radius, {
  bool reduced = false,
}) {
  final h = radius / SkyBoss.radius;
  boss.y = .5;
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..boss = boss
    ..birdY = .42;
  c.save();
  c.clipRect(cell);
  c.translate(center.dx - boss.x * h, center.dy - boss.y * h);
  BossEncounterArt.paint(
    c,
    Size(boss.x * h * 2, h),
    sim,
    BossMotion(boss, reducedMotion: reduced),
  );
  c.restore();
}

Future<Uint8List> _pixels(SkyBoss boss, {bool reduced = false}) => _raster(
  420,
  360,
  (c) => _paintBoss(
    c,
    const Rect.fromLTWH(0, 0, 420, 360),
    boss,
    const Offset(250, 190),
    36,
    reduced: reduced,
  ),
);

void _sheet(
  Canvas c, {
  required double cell,
  required double radius,
  required double font,
  bool reduced = false,
}) {
  const columns = 5;
  // The debut Baron first, for comparison, then the upgraded poses.
  final entries = <(String, SkyBoss)>[
    ('DEBUT · IDLE', _baron(upgraded: false)),
    for (final pose in _poses) (pose.$1, _posed(pose)),
  ];
  final rows = (entries.length / columns).ceil();
  _sky(c, Rect.fromLTWH(0, 0, cell * columns, cell * rows));
  for (var i = 0; i < entries.length; i++) {
    final (name, boss) = entries[i];
    final rect = Rect.fromLTWH(
      i % columns * cell,
      i ~/ columns * cell,
      cell,
      cell,
    );
    _paintBoss(
      c,
      rect,
      boss,
      Offset(rect.left + cell * .58, rect.top + cell * .56),
      radius,
      reduced: reduced,
    );
    c.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x55000000),
    );
    _label(
      c,
      name,
      Offset(rect.left + 6, rect.top + 4),
      font,
      const Color(0xfffff3da),
    );
  }
}

// ------------------------------------------------------ debut baseline --

/// The debut Baron (and an older replay's encounter-6 Baron) through every
/// boss layer at 800×360: backdrop, stage, foreground and plate.
List<(String, SkyBoss, bool)> _debutFrames() {
  SkyBoss baron({double t = 1.2, int number = 1, bool debut = true}) {
    final boss = SkyBoss(number: number, x: 1.5, cinematic: true, debut: debut)
      ..fireIn = 1.5;
    boss.age = boss.arrivalDuration + t;
    return boss;
  }

  SkyBoss arriving(double age) => baron()
    ..age = age
    ..x = 2.2 - .7 * BossMotion.ease(BossMotion.ramp(age, .95, 2.65));
  SkyBoss fury([double t = 1.2]) => baron(t: t)..hp = 50;
  return [
    ('idle', baron(), false),
    ('idle-late', baron(t: 3.37), false),
    ('charge', baron()..fireIn = .1, false),
    ('volley', baron()..lastVolleyAt = baron().age - .12, false),
    ('hit', baron()..lastHitAt = baron().age - .1, false),
    ('summon', baron()..lastSummonAt = baron().age - .3, false),
    ('fury', fury(), false),
    ('fury-onset', fury()..enragedAt = fury().age - .4, false),
    ('fury-charge', fury()..fireIn = .1, false),
    ('arrival-omen', arriving(.9), false),
    ('arrival-silhouette', arriving(1.5), false),
    ('arrival-unfold', arriving(2.2), false),
    ('arrival-roar', arriving(2.95), false),
    ('arrival-title', arriving(3.7), false),
    for (final d in [.12, .6, .95, 1.25, 2.4])
      ('defeat-$d', fury(4)..defeatedAt = fury(4).age - d, false),
    ('reduced-idle', baron(), true),
    ('reduced-hit', baron()..lastHitAt = baron().age - .1, true),
    ('reduced-fury', fury(), true),
    ('reduced-arrival-title', arriving(3.7), true),
    ('reduced-defeat-.6', fury(4)..defeatedAt = fury(4).age - .6, true),
    ('replay-encounter-6', baron(number: 6, debut: false), false),
    (
      'replay-encounter-6-summon',
      baron(number: 6, debut: false)..lastSummonAt = baron().age - .3,
      false,
    ),
  ];
}

Future<Uint8List> _bossLayers(
  SkyBoss boss, {
  bool reduced = false,
  double birdY = .45,
  String? save,
}) {
  const size = Size(800, 360);
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..boss = boss
    ..birdY = birdY;
  final m = BossMotion(boss, reducedMotion: reduced);
  return _raster(800, 360, (c) {
    c.drawRect(Offset.zero & size, Paint()..color = const Color(0xff8fa3cf));
    BossEncounterArt.backdrop(c, size, boss, m);
    BossEncounterArt.paint(c, size, sim, m);
    BossEncounterArt.foreground(c, size, sim, m);
    BossEncounterArt.healthBar(c, size, boss, reducedMotion: reduced);
  }, save: save);
}

// ------------------------------------------------------------ in-game --

class _Stage {
  _Stage(this.game, this.sim, this.width);
  final BirdGame game;
  final FlightSimulation sim;
  final double width;
  double birdY = .5;

  void hover(double seconds) {
    for (var i = 0; i < (seconds / .02).round(); i++) {
      final now = (sim.elapsed + .02) * 1000;
      sim.birdY = birdY;
      sim.velocity = 0;
      sim.hearts = 3;
      sim.apply(
        const MovementInput(valid: true),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      sim.tick(.02, now, viewportWidth: width / 360);
    }
  }

  void hoverTo(double age) => hover(age - sim.boss!.age);

  /// Hovers to combat time [t] of screech cycle [cycle].
  void fightTo(int cycle, double t) =>
      hoverTo(sim.boss!.arrivalDuration + cycle * BaronScreech.period + t);

  /// Hovers until the wall's front reaches [x] (screen heights).
  void frontTo(double x) {
    final boss = sim.boss!;
    final t =
        BaronScreech.screechAt + (boss.screechOriginX - x) / BaronScreech.speed;
    final cycle = ((boss.age - boss.arrivalDuration) / BaronScreech.period)
        .floor();
    fightTo(cycle, t);
  }

  Future<ui.Image> frame() async {
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }
}

/// The second Baron of a flight (encounter 6), which comes back upgraded.
Future<_Stage> _stage(
  WidgetTester tester,
  double width, {
  bool reduced = false,
}) async {
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..elapsed = FlightSimulation.bossInterval - .001
    ..bossesDefeated = 5;
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await game.loaded;
  game.pauseEngine();
  final stage = _Stage(game, sim, width)..hover(.02);
  expect(sim.boss!.screeches, isTrue);
  return stage;
}

Future<void> _shot(
  _Stage s,
  String name,
  List<(String, ui.Image)> frames,
) async {
  final image = await s.frame();
  final png = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(png);
  frames.add((name, image));
}

Future<void> _contact(String name, List<(String, ui.Image)> frames) async {
  const cols = 4, scale = .5;
  final fw = frames.first.$2.width * scale, fh = 360 * scale;
  final rows = (frames.length / cols).ceil();
  await _raster((fw * cols).toInt(), ((fh + 18) * rows).toInt(), (c) {
    c.drawRect(
      Rect.fromLTWH(0, 0, fw * cols, (fh + 18) * rows),
      Paint()..color = const Color(0xff101223),
    );
    for (var i = 0; i < frames.length; i++) {
      final (label, image) = frames[i];
      final at = Offset(i % cols * fw, (i ~/ cols) * (fh + 18));
      c.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(at.dx, at.dy + 18, fw - 2, fh - 2),
        Paint()..filterQuality = FilterQuality.medium,
      );
      _label(c, label, at + const Offset(4, 2), 12, const Color(0xffffffff));
    }
  }, save: name);
}

/// Walks the whole encounter through the real game, shooting each beat.
Future<void> _encounter(
  _Stage s,
  String tag,
  List<(String, ui.Image)> frames,
) async {
  for (final (beat, age) in const [
    ('omen', .9),
    ('silhouette', 1.5),
    ('roar', 2.95),
    ('title', 3.7),
  ]) {
    s.hoverTo(age);
    await _shot(s, '$tag-arrival-$beat', frames);
  }
  final boss = s.sim.boss!;
  s.birdY = .5;
  s.fightTo(0, 1.2);
  await _shot(s, '$tag-calm', frames);
  // Screech 1: the bird is mid-sky as the warning begins, so the gap opens
  // high.
  s.fightTo(0, BaronScreech.warnAt + .75);
  expect(boss.screechGap, ScreechGap.high);
  await _shot(s, '$tag-warning-high', frames);
  s.birdY = .3;
  s.fightTo(0, BaronScreech.screechAt - .05);
  await _shot(s, '$tag-warning-high-late', frames);
  s.fightTo(0, BaronScreech.screechAt + .06);
  await _shot(s, '$tag-release', frames);
  s.frontTo(_birdX + .3);
  await _shot(s, '$tag-wall-approaching', frames);
  s.frontTo(_birdX - .02);
  await _shot(s, '$tag-wall-crossing-in-gap', frames);
  s.frontTo(_birdX - .35);
  await _shot(s, '$tag-wall-passed', frames);
  s.fightTo(0, BaronScreech.pairAt + 1.1);
  await _shot(s, '$tag-bat-pair', frames);
  // Screech 2: the bird is high, so the gap opens in the middle.
  s.birdY = .2;
  s.fightTo(1, BaronScreech.warnAt + .75);
  expect(boss.screechGap, ScreechGap.middle);
  await _shot(s, '$tag-warning-middle', frames);
  // The bird stays high: the wall catches it.
  s.frontTo(_birdX + .01);
  await _shot(s, '$tag-wall-hits-bird', frames);
  // Screech 3: the bird is high again, so the gap opens low.
  s.birdY = .2;
  s.fightTo(2, BaronScreech.warnAt + .75);
  expect(boss.screechGap, ScreechGap.low);
  await _shot(s, '$tag-warning-low', frames);
  s.birdY = .72;
  s.frontTo(_birdX - .02);
  await _shot(s, '$tag-wall-crossing-low', frames);
  // Fury: the gap narrows.
  s.birdY = .5;
  s.fightTo(3, .4);
  boss.hp = boss.maxHp ~/ 2 - 5;
  s.hover(.5);
  expect(boss.enraged, isTrue);
  await _shot(s, '$tag-fury', frames);
  s.fightTo(3, BaronScreech.warnAt + 1.0);
  await _shot(s, '$tag-fury-warning', frames);
  final (top, bottom) = boss.screechOpening;
  s.birdY = (top + bottom) / 2;
  s.frontTo(_birdX - .02);
  await _shot(s, '$tag-fury-wall-crossing', frames);
  s.fightTo(3, BaronScreech.furyPairAt + .9);
  await _shot(s, '$tag-fury-bat-pairs', frames);
  // Defeat.
  s.sim.bossAmmo.clear();
  s.sim.rocks.addAll(
    List.generate(boss.hp, (_) => BirdRock(x: boss.x - .12, y: boss.y)),
  );
  s.hover(.02);
  expect(boss.phase, BossPhase.defeated);
  for (final (beat, death) in const [
    ('hit', .12),
    ('overload', .6),
    ('burst', .95),
    ('crown', 1.3),
    ('victory', 2.4),
  ]) {
    s.hover(death - (boss.age - boss.defeatedAt!));
    await _shot(s, '$tag-defeat-$beat', frames);
  }
}

// ------------------------------------------------------------- checks --

/// The wall alone on a transparent canvas.
Future<Uint8List> _wallPixels(SkyBoss boss, double h, double width) {
  final m = BossMotion(boss, reducedMotion: false);
  return _raster(
    width.toInt(),
    h.toInt(),
    (c) => BaronScreechArt.wall(
      c,
      Size(width, h),
      boss,
      reduced: false,
      mouthY: BaronScreechArt.mouth(boss, m, h).dy / h,
    ),
  );
}

int _alpha(Uint8List px, int width, int x, int y) =>
    px[(y * width + x) * 4 + 3];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the debut Baron renders exactly as before the upgrade', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await _fonts();
      final hashes = <String, String>{};
      for (final (name, boss, reduced) in _debutFrames()) {
        hashes[name] = _hash(
          await _bossLayers(boss, reduced: reduced, save: 'debut/$name'),
        );
      }
      if (_record) {
        _baselineFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(hashes),
        );
        return;
      }
      final baseline = (jsonDecode(_baselineFile.readAsStringSync()) as Map)
          .cast<String, String>();
      expect(hashes.keys.toSet(), baseline.keys.toSet());
      for (final name in baseline.keys) {
        expect(hashes[name], baseline[name], reason: '$name changed');
      }
    });
  });

  test('the drawn wall leads exactly where the rules sweep', () {
    for (final width in [4 / 3, 640 / 360, 800 / 360, 2.4]) {
      for (final fury in [false, true]) {
        for (final gap in ScreechGap.values) {
          var crossings = 0;
          for (
            var t = BaronScreech.screechAt;
            t < BaronScreech.endAt;
            t += 1 / 240
          ) {
            final boss = _baron(t: t, gap: gap, width: width);
            if (fury) _fury(boss);
            final front = boss.screechFront!;
            if (!BaronScreech.reaches(front, _birdX, _birdR)) continue;
            crossings++;
            for (final reduced in [false, true]) {
              final m = BossMotion(boss, reducedMotion: reduced);
              final mouthY = BaronScreechArt.mouth(boss, m, 360).dy / 360;
              for (var y = 0.0; y <= 1; y += .01) {
                expect(
                  BaronScreechArt.leadingEdge(
                        boss,
                        y,
                        mouthY: mouthY,
                        reduced: reduced,
                      )! -
                      front,
                  closeTo(0, .01),
                  reason: '$width $gap fury $fury at $t, height $y',
                );
              }
            }
            expect(BaronScreechArt.opening(boss), boss.screechOpening);
          }
          expect(crossings, greaterThan(10));
        }
      }
    }
  });

  testWidgets('the wall is painted on the rules front with the rules gap', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const h = 360.0, width = 800.0;
      for (final fury in [false, true]) {
        for (final gap in ScreechGap.values) {
          final probe = _baron(gap: gap);
          // The front just past the bird's center.
          final t =
              BaronScreech.screechAt +
              (probe.screechOriginX - _birdX + .01) / BaronScreech.speed;
          final boss = _baron(t: t, gap: gap);
          if (fury) _fury(boss);
          final front = boss.screechFront!;
          final (top, bottom) = boss.screechOpening;
          final px = await _wallPixels(boss, h, width);
          // The leading edge, row by row outside the gap.
          for (final y in [.03, top - .03, bottom + .03, .97]) {
            if (y > top && y < bottom) continue;
            if (y < 0 || y > 1) continue;
            final row = (y * h).round();
            var x = 0;
            while (x < width && _alpha(px, width.toInt(), x, row) < 128) {
              x++;
            }
            expect(
              x / h - front,
              closeTo(0, .01),
              reason: '$gap fury $fury: edge at row $row',
            );
          }
          // Inside the band: solid outside the gap, clear inside it.
          final col = ((front + BaronScreech.thickness / 2) * h).round();
          for (var row = 0; row < h; row++) {
            final y = (row + .5) / h;
            final a = _alpha(px, width.toInt(), col, row);
            if (y > top + 1 / h && y < bottom - 1 / h) {
              expect(a, 0, reason: '$gap fury $fury: gap row $row is clear');
            } else if (y < top - 1 / h || y > bottom + 1 / h) {
              expect(a, greaterThan(200), reason: '$gap: wall row $row');
            }
          }
        }
      }
    });
  });

  testWidgets('the upgraded Baron renders deterministically and seeks '
      'exactly', (tester) async {
    await tester.runAsync(() async {
      for (final pose in _poses) {
        expect(
          await _pixels(_posed(pose)),
          await _pixels(_posed(pose)),
          reason: pose.$1,
        );
      }
      // A seek away and back lands on the same frame, through the warning,
      // the sweep and the calm.
      for (final t in [
        1.2,
        BaronScreech.warnAt + .6,
        BaronScreech.screechAt + .4,
        BaronScreech.endAt + .2,
      ]) {
        final boss = _baron(t: t);
        final first = await _pixels(boss);
        _at(boss, t + 2.7);
        expect(await _pixels(boss), isNot(equals(first)));
        _at(boss, t);
        expect(await _pixels(boss), first, reason: 'seek back to $t');
      }
    });
  });

  testWidgets('Reduced Motion is still but keeps every screech beat', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final idle = await _pixels(_baron(), reduced: true);
      expect(
        await _pixels(_baron(t: 3.1), reduced: true),
        idle,
        reason: 'Idle holds still with Reduced Motion',
      );
      final seen = <String, Uint8List>{};
      for (final pose in _poses) {
        if (pose.$1 == 'IDLE' || pose.$1.startsWith('DEFEAT')) continue;
        final pixels = await _pixels(_posed(pose), reduced: true);
        expect(
          pixels,
          isNot(equals(idle)),
          reason: '${pose.$1} must read under Reduced Motion',
        );
        for (final MapEntry(key: other, value: seenPixels) in seen.entries) {
          expect(
            pixels,
            isNot(equals(seenPixels)),
            reason: '${pose.$1} and $other must differ',
          );
        }
        seen[pose.$1] = pixels;
      }
    });
  });

  testWidgets('the storm Baron stays inside the encounter layer', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const r = 50.0, w = 420, h = 330;
      var union = Rect.zero;
      final boxes = <String>[];
      for (final (name, setup) in [
        ..._poses.where((p) => !p.$1.startsWith('ARRIVAL')),
        for (var i = 0; i < 24; i++)
          ('cycle $i', (SkyBoss b) => _at(b, BaronScreech.warnAt + i * .15)),
      ]) {
        final boss = _baron();
        setup(boss);
        final m = BossMotion(boss, reducedMotion: false);
        final px = await _raster(w, h, (c) {
          c.translate(w / 2, 180);
          c.scale(r);
          BaronStormRig.paint(c, boss, m);
        });
        var left = w, top = h, right = -1, bottom = -1;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (px[(y * w + x) * 4 + 3] > 8) {
              left = math.min(left, x);
              right = math.max(right, x + 1);
              top = math.min(top, y);
              bottom = math.max(bottom, y + 1);
            }
          }
        }
        final box = Rect.fromLTRB(
          (left - w / 2) / r,
          (top - 180) / r,
          (right - w / 2) / r,
          (bottom - 180) / r,
        );
        boxes.add('$name: $box');
        union = union == Rect.zero ? box : union.expandToInclude(box);
      }
      final report = boxes.join('\n');
      expect(union.left, greaterThan(-3), reason: report);
      expect(union.right, lessThan(3), reason: report);
      expect(union.top, greaterThan(-2.3), reason: report);
      expect(union.bottom, lessThan(1.7), reason: report);
    });
  });

  testWidgets('screech paint stays light', (tester) async {
    await tester.runAsync(() async {
      const size = Size(800, 360);
      // Recording time per frame, the best of three runs of 240 frames.
      double cost(SkyBoss Function(int) at) {
        final sim = arena(version: FlightSimulation.currentRulesVersion)
          ..birdY = .5;
        var best = double.infinity;
        for (var run = 0; run < 3; run++) {
          final watch = Stopwatch();
          const frames = 240;
          for (var i = 0; i < frames + 20; i++) {
            final boss = at(i);
            sim.boss = boss;
            final recorder = ui.PictureRecorder();
            if (i >= 20) watch.start();
            BossEncounterArt.paint(
              Canvas(recorder),
              size,
              sim,
              BossMotion(boss, reducedMotion: false),
            );
            watch.stop();
            recorder.endRecording().dispose();
          }
          best = math.min(best, watch.elapsedMicroseconds / frames / 1000);
        }
        return best;
      }

      final debut = cost((i) => _baron(t: 1 + i / 60, upgraded: false));
      final calm = cost((i) => _baron(t: 1 + i / 60));
      final warning = cost(
        (i) => _baron(t: BaronScreech.warnAt + (i % 90) / 60),
      );
      final sweep = cost(
        (i) => _baron(t: BaronScreech.screechAt + (i % 90) / 60),
      );
      final report =
          'paint ms/frame (recording) · debut ${debut.toStringAsFixed(3)} · '
          'upgraded calm ${calm.toStringAsFixed(3)} · warning '
          '${warning.toStringAsFixed(3)} · sweep ${sweep.toStringAsFixed(3)}';
      _folder.createSync(recursive: true);
      File('${_folder.path}/paint-cost.txt').writeAsStringSync(report);
      // ignore: avoid_print
      print(report);
      expect(sweep, lessThan(3));
      expect(warning, lessThan(3));
    });
  });

  testWidgets('renders the upgraded Baron review sheets', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      const columns = 5;
      final rows = ((_poses.length + 1) / columns).ceil();
      await _raster(
        (380 * columns).toInt(),
        (380 * rows).toInt(),
        (c) => _sheet(c, cell: 380, radius: 52, font: 15),
        save: 'pose-sheet-large',
      );
      // A 360-pt-tall landscape phone: the hit radius is .115 of the height.
      const phone = 360 * SkyBoss.radius;
      await _raster(
        260 * columns,
        260 * rows,
        (c) => _sheet(c, cell: 260, radius: phone, font: 11),
        save: 'pose-sheet-phone',
      );
      await _raster(
        260 * columns,
        260 * rows,
        (c) => _sheet(c, cell: 260, radius: phone, font: 11, reduced: true),
        save: 'pose-sheet-reduced',
      );
      // Hero: the debut and the upgraded Baron side by side, then his
      // warning and his screech.
      await _raster(1600, 560, (c) {
        c.drawPaint(Paint()..color = const Color(0xfff2eedf));
        final entries = [
          _baron(upgraded: false),
          _baron(),
          _posed(_poses[4]),
          _posed(_poses[6]),
        ];
        for (var i = 0; i < entries.length; i++) {
          final boss = entries[i];
          c.save();
          c.translate(200 + i * 400.0, 310);
          c.scale(78);
          final m = BossMotion(boss, reducedMotion: true);
          c.saveLayer(const Rect.fromLTWH(-3, -2.3, 6, 4), Paint());
          if (boss.screeches) {
            BaronStormRig.paint(c, boss, m);
          } else {
            BossRig.paint(c, boss, m);
          }
          c.restore();
          c.restore();
        }
      }, save: 'hero');
    });
  });

  for (final width in [640.0, 800.0]) {
    testWidgets('in-game upgraded Baron frames at ${width.toInt()}', (
      tester,
    ) async {
      tester.view.physicalSize = ui.Size(width, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await _fonts();
        final s = await _stage(tester, width);
        final frames = <(String, ui.Image)>[];
        await _encounter(s, '${width.toInt()}', frames);
        await _contact('sheet-${width.toInt()}', frames);
        for (final (_, image) in frames) {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('in-game upgraded Baron frames with Reduced Motion', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await _fonts();
      final s = await _stage(tester, 640, reduced: true);
      final frames = <(String, ui.Image)>[];
      await _encounter(s, '640-reduced', frames);
      await _contact('sheet-640-reduced', frames);
      for (final (_, image) in frames) {
        image.dispose();
      }
    });
    await tester.pumpWidget(const SizedBox());
  });
}
