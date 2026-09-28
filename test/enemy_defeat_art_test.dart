import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_defeat_art.dart';
import 'package:push_up_bird/game/rush_art.dart';
import 'package:push_up_bird/ui/theme.dart';

const _daylight = [Color(0xffbde9f6), Color(0xfff9efd8)];
const _dusk = [Color(0xff8f86bf), Color(0xffd2a9af)];
const _kinds = <EnemyKind?>[
  EnemyKind.simpleBat,
  EnemyKind.caveBat,
  EnemyKind.spitterBeetle,
  EnemyKind.duskMoth,
  null,
];
final _folder = Directory('build/visual-review/enemy-defeat');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<int>> raster(
    void Function(Canvas) draw,
    String? name, {
    int width = 240,
    int height = 200,
  }) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final pixels = (await image.toByteData())!.buffer.asUint8List();
    if (name != null) {
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      File('${_folder.path}/$name.png').writeAsBytesSync(png);
    }
    image.dispose();
    picture.dispose();
    return pixels;
  }

  testWidgets('a defeat pops, tumbles into a poof and clears exactly', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final family in ['Fredoka', 'Nunito']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
      }
      _folder.createSync(recursive: true);

      for (final kind in _kinds) {
        for (final rammed in [false, true]) {
          for (final reduced in [false, true]) {
            final label = '$kind rammed: $rammed reduced: $reduced';
            final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
              ..elapsed = 2;
            Future<List<int>> frame() => raster(
              (c) => CombatArt.paint(c, 200, sim, reducedMotion: reduced),
              null,
            );
            final blank = await frame();
            sim.events.add(
              FlightEvent(
                rammed ? FlightEventKind.enemyRammed : FlightEventKind.enemyHit,
                2,
                .5,
                gateWorldX: .6,
                enemyKind: kind,
              ),
            );
            final impact = await frame();
            expect(impact, isNot(equals(blank)), reason: 'visible $label');
            expect(await frame(), impact, reason: 'paused frame $label');
            sim.elapsed += .15;
            final later = await frame();
            expect(later, isNot(equals(impact)), reason: 'animates $label');
            if (reduced) {
              // A stationary acknowledgement: it fades inside its first
              // footprint instead of growing or flinging anything outward.
              expect(
                _bounds(later, 240).expandToInclude(_bounds(impact, 240)),
                _bounds(impact, 240),
                reason: 'no expansion under Reduced Motion $label',
              );
            }
            sim.elapsed = 2;
            expect(await frame(), impact, reason: 'seek restores $label');
            sim.elapsed = 2 + EnemyDefeatArt.seconds;
            expect(await frame(), blank, reason: 'expires $label');
          }
        }
      }

      final seconds = [
        for (var f = 0; f * 30 < EnemyDefeatArt.seconds * 1000; f++) f / 30,
      ];
      for (final rammed in [false, true]) {
        final mode = rammed ? 'ram' : 'shot';
        await raster(
          (c) => _strip(c, seconds, 26, rammed: rammed, sky: _daylight),
          'strip-closeup-$mode',
          width: 60 + (seconds.length + 1) * 220,
          height: 70 + _kinds.length * 190,
        );
        for (final (name, sky) in [('day', _daylight), ('dusk', _dusk)]) {
          await raster(
            (c) => _strip(
              c,
              seconds,
              360 * SkyEnemy.radius,
              rammed: rammed,
              sky: sky,
              scroll: true,
            ),
            'strip-gameplay-$mode-$name',
            width: 60 + (seconds.length + 1) * 120,
            height: 70 + _kinds.length * 100,
          );
        }
        await raster(
          (c) => _strip(
            c,
            seconds,
            360 * SkyEnemy.radius,
            rammed: rammed,
            sky: _daylight,
            reduced: true,
          ),
          'strip-reduced-$mode',
          width: 60 + (seconds.length + 1) * 120,
          height: 70 + _kinds.length * 100,
        );
      }
      for (final rammed in [true, false]) {
        await raster(
          (c) => _swarmChain(c, rammed: rammed),
          'swarm-${rammed ? 'ram' : 'shot'}',
          width: 2 * 420,
          height: 4 * 190,
        );
      }
      await raster(
        (c) => _beforeAfter(c, seconds),
        'before-after',
        width: 60 + (seconds.length + 1) * 120,
        height: 70 + 4 * 100,
      );
    });
  });

  for (final (name, elapsed) in [
    ('day', 6.0),
    ('dusk', 27.0),
    ('twilight', 47.0),
  ]) {
    testWidgets('defeats read in the actual game at $name', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..phase = RunPhase.playing
        ..elapsed = elapsed
        ..birdY = .5;
      sim.enemies.add(
        SkyEnemy(x: 1.72, y: .3, appearance: 3, flightPhase: 1.3)..age = 2,
      );
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: false,
        playback: true,
        onChanged: () {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      await tester.runAsync(() async {
        await game.loaded;
        game.pauseEngine();
        _folder.createSync(recursive: true);
        Future<void> capture(String file) async {
          final recorder = ui.PictureRecorder();
          game.render(Canvas(recorder));
          final picture = recorder.endRecording();
          final image = await picture.toImage(800, 360);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          File('${_folder.path}/$file.png').writeAsBytesSync(bytes);
          expect(bytes.length, greaterThan(2000));
          image.dispose();
          picture.dispose();
        }

        // Four defeats at different moments of the same transition.
        for (final (kind, x, y, ago) in [
          (EnemyKind.caveBat, .78, .26, .05),
          (EnemyKind.spitterBeetle, 1.02, .62, .12),
          (EnemyKind.duskMoth, 1.3, .44, .22),
          (EnemyKind.simpleBat, 1.52, .74, .36),
        ]) {
          sim.events.add(
            FlightEvent(
              FlightEventKind.enemyHit,
              elapsed - ago,
              y,
              gateWorldX: sim.distance + x - ago * sim.speed,
              enemyKind: kind,
            ),
          );
        }
        sim.events.add(
          FlightEvent(
            FlightEventKind.enemyRammed,
            elapsed - .07,
            .5,
            gateWorldX: sim.distance + FlightSimulation.birdX + .04,
            enemyKind: EnemyKind.simpleBat,
          ),
        );
        await capture('in-game-$name');

        // One shot defeat through time, with the world scrolling under it.
        sim.events.clear();
        final start = sim.distance;
        sim.events.add(
          FlightEvent(
            FlightEventKind.enemyHit,
            elapsed,
            .42,
            gateWorldX: start + 1.05,
            value: 3,
            enemyKind: EnemyKind.spitterBeetle,
          ),
        );
        for (final ms in [0, 33, 67, 100, 133, 200, 300, 400, 500]) {
          sim.elapsed = elapsed + ms / 1000;
          sim.distance = start + ms / 1000 * sim.speed;
          await capture('in-game-$name-${ms.toString().padLeft(3, '0')}ms');
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

/// Rows per enemy kind, columns from the live enemy through the whole
/// transition. [scroll] slides the anchor with the world as the game does.
void _strip(
  Canvas c,
  List<double> seconds,
  double radius, {
  required bool rammed,
  required List<Color> sky,
  bool reduced = false,
  bool scroll = false,
}) {
  final cell = radius > 20 ? const Size(220, 190) : const Size(120, 100);
  final width = 60 + (seconds.length + 1) * cell.width;
  final height = 70 + _kinds.length * cell.height;
  c.drawRect(
    Rect.fromLTWH(0, 0, width, height),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: sky,
      ).createShader(Rect.fromLTWH(0, 0, width, height)),
  );
  _text(
    c,
    '${rammed ? 'RAM' : 'SHOT'} DEFEAT · r = ${radius.toStringAsFixed(1)} px'
    '${reduced ? ' · REDUCED MOTION' : ''}${scroll ? ' · world scrolls' : ''}',
    const Offset(16, 10),
    18,
  );
  for (var col = 0; col <= seconds.length; col++) {
    _text(
      c,
      col == 0 ? 'live' : '${(seconds[col - 1] * 1000).round()}ms',
      Offset(60 + col * cell.width + 8, 40),
      12,
    );
  }
  final h = radius / SkyEnemy.radius;
  for (var row = 0; row < _kinds.length; row++) {
    final kind = _kinds[row];
    _text(
      c,
      kind?.name ?? 'no kind',
      Offset(6, 70 + row * cell.height + 6),
      11,
    );
    for (var col = 0; col <= seconds.length; col++) {
      final center = Offset(
        60 + col * cell.width + cell.width * (scroll ? .62 : .42),
        70 + row * cell.height + cell.height * .55,
      );
      c.save();
      c.clipRect(
        Rect.fromLTWH(
          60 + col * cell.width,
          70 + row * cell.height,
          cell.width,
          cell.height,
        ),
      );
      c.translate(center.dx - h, center.dy - .5 * h);
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..elapsed = 2;
      if (col == 0) {
        if (kind != null) {
          EnemyArt.paint(
            c,
            h,
            SkyEnemy(x: 1, y: .5, appearance: kind.index)..age = 1.3,
            birdY: .5,
            reducedMotion: reduced,
          );
        }
      } else {
        final age = seconds[col - 1];
        sim.elapsed = 2 + age;
        if (scroll) sim.distance = age * sim.speed;
        sim.events.add(
          FlightEvent(
            rammed ? FlightEventKind.enemyRammed : FlightEventKind.enemyHit,
            2,
            .5,
            gateWorldX: 1,
            enemyKind: kind,
          ),
        );
        CombatArt.paint(c, h, sim, reducedMotion: reduced);
      }
      c.restore();
    }
  }
}

/// A flock of three swarm bats smashed in a sprint chain (or shot one by
/// one), through the real rush renderer, at eight moments.
void _swarmChain(Canvas c, {required bool rammed}) {
  const cell = Size(420, 190);
  final route = RushPath(
    kind: RushPathKind.swarm,
    number: 1,
    startDistance: 0,
    endDistance: 99,
    resumeDistance: 99,
    heights: const [.5, .5],
  );
  for (var frame = 0; frame < 8; frame++) {
    final time = frame * .08;
    final col = frame % 2, row = frame ~/ 2;
    final origin = Offset(col * cell.width, row * cell.height);
    final sky = row.isEven ? _daylight : _dusk;
    c.save();
    c.clipRect(origin & cell);
    c.drawRect(
      origin & cell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(origin & cell),
    );
    _text(c, '${(time * 1000).round()}ms', origin + const Offset(8, 6), 12);
    c.translate(origin.dx + 110, origin.dy - 85);
    final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
      ..elapsed = 3 + time
      ..birdY = .5;
    final scroll = sim.speed * (rammed ? 2.8 : 1);
    sim.distance = time * scroll;
    for (var k = 0; k < 3; k++) {
      final lane = k * .045 - .045;
      // Bats close on the bird at their own speed plus the scroll.
      final meet = rammed ? .06 + k * .09 : .02 + k * .16;
      final closing = scroll + Rush.swarmSpeed;
      if (time < meet) {
        sim.swarm.add(
          SwarmBat(
            x: FlightSimulation.birdX + .05 + (meet - time) * closing,
            y: .5 + lane,
            route: route,
            lane: 0,
            phase: k * 1.3,
          )..age = 2 + time,
        );
      } else {
        final x = rammed ? FlightSimulation.birdX + .05 : .78 + k * .06;
        sim.events.add(
          FlightEvent(
            FlightEventKind.swarmSmashed,
            3 + meet,
            .5 + lane,
            value: rammed ? k + 1 : 0,
            gateWorldX: meet * scroll + x,
          ),
        );
      }
    }
    RushArt.swarm(c, const Size(800, 360), sim, reducedMotion: false);
    RushArt.effects(c, 360, sim, reducedMotion: false);
    c.drawCircle(
      const Offset(FlightSimulation.birdX * 360, 180),
      FlightSimulation.birdRadius * 360,
      Paint()..color = SkyColors.yellow,
    );
    c.restore();
  }
}

/// The old accent against the new transition at gameplay size.
void _beforeAfter(Canvas c, List<double> seconds) {
  const cell = Size(120, 100);
  final width = 60 + (seconds.length + 1) * cell.width;
  c.drawRect(
    Rect.fromLTWH(0, 0, width, 70 + 2 * cell.height),
    Paint()..color = const Color(0xffc6e5e5),
  );
  _text(c, 'DEFEAT (gameplay size)', const Offset(16, 10), 18);
  final h = 360.0;
  for (var row = 0; row < 2; row++) {
    final sky = row.isEven ? _daylight : _dusk;
    final top = 70 + row * cell.height;
    c.drawRect(
      Rect.fromLTWH(0, top, width, cell.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(Rect.fromLTWH(0, top, width, cell.height)),
    );
    for (var col = 0; col <= seconds.length; col++) {
      final center = Offset(
        60 + col * cell.width + cell.width * .42,
        top + cell.height * .55,
      );
      c.save();
      c.clipRect(
        Rect.fromLTWH(60 + col * cell.width, top, cell.width, cell.height),
      );
      if (col == 0) {
        c.translate(center.dx - h, center.dy - .5 * h);
        EnemyArt.paint(
          c,
          h,
          SkyEnemy(x: 1, y: .5, appearance: 0)..age = 1.3,
          birdY: .5,
          reducedMotion: false,
        );
      } else {
        EnemyDefeatArt.paint(
          c,
          center,
          h * SkyEnemy.radius,
          age: seconds[col - 1],
          reducedMotion: false,
          kind: EnemyKind.caveBat,
          seed: 2000,
        );
      }
      c.restore();
    }
  }
}

/// The bounding box of pixels that differ from transparent.
Rect _bounds(List<int> rgba, int width) {
  var left = width, top = 1 << 30, right = -1, bottom = -1;
  for (var i = 0; i < rgba.length; i += 4) {
    if (rgba[i + 3] == 0) continue;
    final p = i ~/ 4, x = p % width, y = p ~/ width;
    if (x < left) left = x;
    if (x > right) right = x;
    if (y < top) top = y;
    if (y > bottom) bottom = y;
  }
  if (right < 0) return Rect.zero;
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right + 1.0,
    bottom + 1.0,
  );
}

void _text(
  Canvas c,
  String text,
  Offset at,
  double size, {
  Color color = SkyColors.ink,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
}
