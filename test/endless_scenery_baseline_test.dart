// Hundreds of scenery frames are rasterised and hashed.
@Timeout(Duration(minutes: 6))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/gale_art.dart';
import 'package:push_up_bird/game/gate_art.dart';
import 'package:push_up_bird/game/obstacle_art.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

/// Endless scenery is locked to pixel digests recorded before campaign
/// flights could hold one region: the world tour's backdrop in every region,
/// crossing and lap, with regional obstacles, the older gate looks, a gale's
/// flecks and real game frames, in normal and Reduced Motion.
///
/// A digest changes only when a pixel does. The fixture is written when it
/// is missing, or with `--dart-define=RECORD_SCENERY_BASELINE=true` after a
/// deliberate art change. A mismatching frame is written to
/// build/scenery-baseline/ so it can be looked at.
const _record = bool.fromEnvironment('RECORD_SCENERY_BASELINE');
final _fixture = File('test/fixtures/endless_scenery_baseline.json');

const _size = Size(800, 360);
const _leg = WorldTour.leg, _hold = WorldTour.hold;

/// 64-bit FNV-1a over the frame's RGBA words, as 16 hex digits.
String _digest(Uint32List words) {
  var hash = 0xcbf29ce484222325;
  for (final word in words) {
    hash ^= word;
    hash *= 0x100000001b3;
  }
  String half(int v) => v.toRadixString(16).padLeft(8, '0');
  return half(hash >>> 32) + half(hash & 0xffffffff);
}

Future<(String, Uint8List)> _rasterise(
  ui.Picture picture, [
  Size size = _size,
]) async {
  final image = await picture.toImage(
    size.width.round(),
    size.height.round(),
  );
  picture.dispose();
  final raw = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  image.dispose();
  return (
    _digest(raw.buffer.asUint32List()),
    png.buffer.asUint8List(),
  );
}

/// Compares [frames] with the fixture, or records them.
void _check(Map<String, (String, Uint8List)> frames) {
  final stored = _fixture.existsSync()
      ? (jsonDecode(_fixture.readAsStringSync()) as Map).cast<String, String>()
      : <String, String>{};
  final missing = frames.keys.where((k) => !stored.containsKey(k));
  if (_record || missing.isNotEmpty) {
    for (final MapEntry(:key, :value) in frames.entries) {
      stored[key] = value.$1;
    }
    final sorted = Map.fromEntries(
      stored.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    _fixture.parent.createSync(recursive: true);
    _fixture.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
    );
    if (_record) return;
  }
  final changed = <String>[];
  for (final MapEntry(:key, :value) in frames.entries) {
    if (stored[key] == value.$1) continue;
    changed.add(key);
    File('build/scenery-baseline/$key.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(value.$2);
  }
  expect(changed, isEmpty, reason: 'frames differ from the endless baseline');
}

/// One of each obstacle kind across the screen, born at [seconds], so each
/// takes the tour region of that moment.
List<(Obstacle, bool, bool)> _lineup(double seconds, int variant) {
  Obstacle make(ObstacleKind kind, double x, double center, int i) => Obstacle(
    x: x,
    center: center,
    gap: .4,
    width: kind.width,
    kind: kind,
    amplitude: kind == ObstacleKind.garden ? 0 : .05,
    appearance: variant + i,
    bornAt: seconds,
  )..advance(seconds);
  return [
    (make(ObstacleKind.garden, .3, .56, 0), false, false),
    (make(ObstacleKind.windLift, .62, .44, 1), true, false),
    (make(ObstacleKind.petalGate, .9, .52, 2), true, true),
    (make(ObstacleKind.switchback, 1.16, .5, 0), false, false),
    (make(ObstacleKind.lanternDrift, 1.4, .46, 1), false, false),
    (make(ObstacleKind.sunWheels, 1.66, .56, 2), true, false),
    (make(ObstacleKind.crystalSteps, 1.94, .48, 0), false, false),
  ];
}

/// The backdrop at [seconds] with a lineup of obstacles in front, dressed
/// by the rules generation [refined]/[garden] selects.
ui.Picture _scene(
  double seconds, {
  bool reducedMotion = false,
  int variant = 0,
  bool obstacles = true,
  bool refined = true,
  bool garden = true,
}) {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder)..clipRect(Offset.zero & _size);
  SkyScenery.paint(
    c,
    _size,
    seconds: seconds,
    distance: seconds * .36,
    reducedMotion: reducedMotion,
  );
  final h = _size.height;
  if (obstacles) {
    for (final (o, cleared, perfect) in _lineup(seconds, variant)) {
      ObstacleArt.paint(
        c,
        o,
        h,
        seconds: seconds,
        reducedMotion: reducedMotion,
        cleared: cleared,
        perfect: perfect,
        refined: refined,
        gardenStructures: garden,
      );
      if (cleared) {
        ObstacleArt.seal(
          c,
          Offset((o.x + o.width / 2) * h, o.target * h),
          h,
          WorldTour.of(o),
          perfect: perfect,
        );
      }
    }
  }
  return recorder.endRecording();
}

/// The oldest replays' gate towers, one of each kind, at [seconds].
ui.Picture _gates(double seconds, {bool reducedMotion = false}) {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder)..clipRect(Offset.zero & _size);
  c.drawColor(const Color(0xff8fb7d9), BlendMode.src);
  for (final (i, kind) in ObstacleKind.values.indexed) {
    final x = 12.0 + i * 64;
    for (final top in [true, false]) {
      GateArt.paint(
        c,
        Rect.fromLTRB(x, top ? -10 : 230, x + 44, top ? 130 : 370),
        top: top,
        kind: kind,
        seconds: seconds,
        reducedMotion: reducedMotion,
        cleared: i.isEven,
        perfect: i % 3 == 0,
      );
    }
  }
  return recorder.endRecording();
}

/// A gale blowing at [seconds] over a plain sky, so its flecks show.
ui.Picture _gale(double seconds, {bool reducedMotion = false}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(),
    practice: true,
    course: FlightCourse.starTrail,
  )
    ..elapsed = seconds
    ..distance = seconds * .36
    ..gale = (Gale(number: 0, startDistance: 0)
      ..phase = GalePhase.blowing
      ..startedAt = 0);
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder)..clipRect(Offset.zero & _size);
  c.drawColor(const Color(0xff5d7fa6), BlendMode.src);
  GaleArt.backdrop(c, _size, sim, reducedMotion: reducedMotion);
  return recorder.endRecording();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the world tour paints every region, crossing and lap as before', () async {
    final frames = <String, (String, Uint8List)>{};
    Future<void> add(String name, ui.Picture picture) async =>
        frames[name] = await _rasterise(picture);
    for (final r in WorldRegion.values) {
      final start = r.index * _leg;
      for (final local in const [1.0, 8.0, 15.5]) {
        await add(
          '${r.name}-hold-$local',
          _scene(start + local, variant: r.index),
        );
      }
      for (final t in const [.2, .5, .8]) {
        await add(
          '${r.name}-cross-$t',
          _scene(start + _hold + WorldTour.crossing * t, variant: r.index + 1),
        );
      }
      await add(
        '${r.name}-still-hold',
        _scene(start + 8, reducedMotion: true, variant: r.index),
      );
      await add(
        '${r.name}-still-cross',
        _scene(start + _hold + 3, reducedMotion: true, variant: r.index + 2),
      );
      // Later laps: painters that time a landmark once per leg.
      await add(
        '${r.name}-lap2',
        _scene(WorldTour.loop + start + 12, variant: r.index),
      );
      await add(
        '${r.name}-lap3-bare',
        _scene(WorldTour.loop * 2 + start + 4.5, obstacles: false),
      );
    }
    // Once-per-leg landmarks: the sea's whale and dawn, the Arabian and
    // Roman traffic, the cyberpunk maglev, the Chinese sky.
    for (final r in [
      WorldRegion.sea,
      WorldRegion.arabia,
      WorldRegion.rome,
      WorldRegion.cyberpunk,
      WorldRegion.china,
      WorldRegion.paris,
      WorldRegion.egypt,
    ]) {
      for (final local in const [0.0, 3.0, 5.5, 10.5, 13.0, 17.0, 21.5]) {
        await add(
          '${r.name}-sweep-$local',
          _scene(r.index * _leg + local, obstacles: false),
        );
      }
    }
    // The tour wraps from the sea back to the jungle.
    for (final back in const [4.0, 2.0, .5]) {
      await add('loop-wrap-$back', _scene(WorldTour.loop - back));
    }
    // The first gate generations borrow the tour's looks and palette.
    for (final r in [
      WorldRegion.jungle,
      WorldRegion.antarctica,
      WorldRegion.egypt,
      WorldRegion.cyberpunk,
      WorldRegion.sea,
    ]) {
      final at = r.index * _leg + _hold + 2.5;
      await add('${r.name}-legacy', _scene(at, refined: false));
      await add('${r.name}-garden', _scene(at, garden: false));
      await add('${r.name}-gates', _gates(at));
      await add('${r.name}-gates-hold', _gates(r.index * _leg + 5));
    }
    await add('gates-still', _gates(_leg * 4 + 3, reducedMotion: true));
    for (final r in WorldRegion.values) {
      await add('${r.name}-gale', _gale(r.index * _leg + 8));
      await add('${r.name}-gale-cross', _gale(r.index * _leg + _hold + 3));
    }
    await add('gale-still', _gale(_leg * 2 + 18, reducedMotion: true));
    _check(frames);
  });

  testWidgets('a real endless flight renders as before', (tester) async {
    for (final family in ['Fredoka', 'Nunito']) {
      await tester.runAsync(
        () => (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load(),
      );
    }
    var now = 0.0;
    final recorder = FlightRecorder(
      ReplayTape(
        mode: PlayMode.touch,
        course: FlightCourse.starTrail,
        practice: true,
        seed: 11,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: false,
        originMs: 0,
      ),
      () => now,
    );
    final sim = recorder.simulation;
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: false,
      onChanged: () {},
      playback: true,
    );
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() => game.loaded);
    game.pauseEngine();
    final shots = [10.0, 17.5, 19.0, 20.5, 23.0];
    final frames = <String, (String, Uint8List)>{};
    for (
      var frame = 0;
      frame < 6000 && sim.phase != RunPhase.ended && shots.isNotEmpty;
      frame++
    ) {
      now += 20;
      final upcoming = sim.obstacles.where(
        (o) =>
            o.x + o.width >
            FlightSimulation.birdX - FlightSimulation.birdRadius,
      );
      final aim = upcoming.isEmpty ? .5 : upcoming.first.target;
      recorder.apply(
        MovementInput(
          valid: true,
          height: .5,
          flap: sim.birdY > aim + .04 && sim.velocity > -.1,
        ),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      recorder.tick(.02, now, _size.width / _size.height);
      if (sim.elapsed < shots.first) continue;
      final name = 'game-${shots.removeAt(0)}';
      await tester.runAsync(() async {
        final pictures = ui.PictureRecorder();
        game.render(Canvas(pictures));
        frames[name] = await _rasterise(pictures.endRecording());
      });
    }
    expect(shots, isEmpty);
    _check(frames);
    await tester.pumpWidget(const SizedBox());
  });
}
