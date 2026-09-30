import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/door_art.dart';
import 'package:push_up_bird/game/door_fracture.dart';
import 'package:push_up_bird/game/regions/world_region.dart';

Future<Uint8List> pixels(Obstacle o, {bool reduced = true}) async {
  final recorder = ui.PictureRecorder();
  DoorArt.paint(Canvas(recorder), 360, o, reducedMotion: reduced);
  final picture = recorder.endRecording();
  final image = await picture.toImage(800, 360);
  final data = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return data;
}

int alphaAt(Uint8List data, int x, int y) => data[(y * 800 + x) * 4 + 3];

/// Painted pixels outside [allowed] (logical pixels of an 800x360 frame).
int paintedOutside(Uint8List data, Rect allowed) {
  var count = 0;
  for (var y = 0; y < 360; y++) {
    for (var x = 0; x < 800; x++) {
      if (alphaAt(data, x, y) == 0) continue;
      if (x < allowed.left || x >= allowed.right) {
        count++;
      } else if (y < allowed.top || y >= allowed.bottom) {
        count++;
      }
    }
  }
  return count;
}

/// How many pixels differ between two frames.
int changed(Uint8List a, Uint8List b) {
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

/// The furthest painted column to the right of the panel.
int rightmost(Uint8List data) {
  for (var x = 799; x >= 0; x--) {
    for (var y = 0; y < 360; y++) {
      if (alphaAt(data, x, y) != 0) return x;
    }
  }
  return -1;
}

/// A panel with [hits] base rocks in it, on a clock that starts at 5 s.
Obstacle wallWith({
  int hits = 0,
  int appearance = 0,
  double hitY = .5,
  double gap = .34,
}) {
  final o = Obstacle(
    x: 1.2,
    center: .5,
    gap: gap,
    appearance: appearance,
    bornAt: 2,
    door: SkyDoor(),
  );
  for (var i = 0; i < hits; i++) {
    o.advance(5 + i.toDouble());
    o.door!.takeDamage(10, hitY: hitY + [0, -.05, .06][i % 3]);
  }
  o.advance(5 + hits.toDouble());
  return o;
}

/// Panel plus the wall-end collars: a band of [DoorArt.collarReach] above and
/// below the opening, and no wider than the wall itself.
Rect envelope(Obstacle o, {double slack = 1.5}) => Rect.fromLTRB(
  o.x * 360 - slack,
  (o.top - DoorArt.collarReach) * 360 - slack,
  (o.x + o.width) * 360 + slack,
  (o.bottom + DoorArt.collarReach) * 360 + slack,
);

Rect opening(Obstacle o) => Rect.fromLTRB(
  o.x * 360,
  o.top * 360,
  (o.x + o.width) * 360,
  o.bottom * 360,
);

void main() {
  testWidgets(
    'damage changes the panel; art stays in the opening and collars',
    (tester) async {
      await tester.runAsync(() async {
        final o = wallWith();
        var previous = await pixels(o);
        // The intact panel already fills the opening, framed by its collars.
        expect(paintedOutside(previous, envelope(o)), 0);
        final room = opening(o).deflate(3);
        expect(
          alphaAt(previous, room.center.dx.round(), room.center.dy.round()),
          255,
        );
        expect(
          alphaAt(
            previous,
            room.center.dx.round(),
            (opening(o).top - 5).round(),
          ),
          255,
          reason: 'the collar sits in the wall body above the opening',
        );
        for (var hit = 1; hit <= 4; hit++) {
          o.door!.takeDamage(10, hitY: .5 + (hit.isOdd ? .04 : -.05));
          o.advance(5 + hit.toDouble());
          final current = await pixels(o);
          if (hit < 4) {
            expect(
              changed(previous, current),
              greaterThan(150),
              reason: 'stage $hit is distinct from the stage before',
            );
            // Nothing solid escapes the opening except the wall-end collars.
            expect(paintedOutside(current, envelope(o)), 0);
          }
          previous = current;
        }
        expect(
          previous.every((byte) => byte == 0),
          isTrue,
          reason: 'Reduced Motion removes the destroyed insert immediately',
        );
      });
    },
  );

  testWidgets('a moving panel keeps to its opening while idle', (tester) async {
    await tester.runAsync(() async {
      for (final hits in [0, 2]) {
        final o = wallWith(hits: hits);
        for (final age in [0.0, .4, 1.1, 2.7, 9.3]) {
          o.door!.age = age + 6;
          final frame = await pixels(o, reduced: false);
          expect(
            paintedOutside(frame, envelope(o)),
            0,
            reason: 'hits $hits age $age',
          );
        }
      }
      // The sheen and the sun's pulse are motion, so Reduced Motion is still.
      final o = wallWith(hits: 1);
      o.door!.age = 20;
      final still = await pixels(o);
      o.door!.age = 21.1;
      expect(await pixels(o), still);
      expect(await pixels(o, reduced: false), isNot(equals(still)));
    });
  });

  testWidgets('every blow answers with sparks, chips and dust that clear', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final o = wallWith(hits: 1);
      final hitAt = o.door!.lastHitAt;
      final left = o.x * 360 - 2;
      var decorative = 0;
      final frames = <Uint8List>[];
      for (final ms in [10, 40, 90, 200, 400]) {
        o.door!.age = hitAt + ms / 1000;
        final frame = await pixels(o, reduced: false);
        for (var y = 0; y < 360; y++) {
          for (var x = 0; x < left; x++) {
            if (alphaAt(frame, x, y) != 0) decorative++;
          }
        }
        frames.add(frame);
      }
      expect(decorative, greaterThan(400), reason: 'sparks, chips and dust');
      for (var i = 1; i < frames.length; i++) {
        expect(changed(frames[i - 1], frames[i]), greaterThan(60));
      }
      // Once the reaction is over nothing reaches beyond the wall's own width.
      o.door!.age = hitAt + .6;
      expect(paintedOutside(await pixels(o, reduced: false), envelope(o)), 0);
      // Reduced Motion never draws them.
      o.door!.age = hitAt + .04;
      expect(paintedOutside(await pixels(o), envelope(o)), 0);
    });
  });

  testWidgets('the break is deterministic, seekable and clears completely', (
    tester,
  ) async {
    await tester.runAsync(() async {
      Obstacle killed() {
        final o = wallWith(hits: 3);
        o.advance(9);
        o.door!.takeDamage(10, hitY: .52);
        return o;
      }

      final o = killed();
      final start = o.door!.destroyedAt!;
      final times = [0.0, .03, .06, .1, .2, .4, .7, .95];
      final frames = <Uint8List>[];
      for (final t in times) {
        o.door!.age = start + t;
        frames.add(await pixels(o, reduced: false));
      }
      for (var i = 1; i < frames.length; i++) {
        expect(
          changed(frames[i - 1], frames[i]),
          greaterThan(60),
          reason: 'no dead frame between +${times[i - 1]} and +${times[i]}',
        );
      }
      // Same age, same pixels: forwards, backwards, and on a twin panel.
      final twin = killed();
      for (final i in [5, 1, 3, 7, 0, 2]) {
        o.door!.age = start + times[i];
        expect(
          await pixels(o, reduced: false),
          frames[i],
          reason: 'seek to ${times[i]}',
        );
        twin.door!.age = twin.door!.destroyedAt! + times[i];
        expect(
          await pixels(twin, reduced: false),
          frames[i],
          reason: 'twin at ${times[i]}',
        );
      }
      // A different wall of the same kind breaks differently.
      final other = wallWith(hits: 3, appearance: 2)..advance(9);
      other.door!.takeDamage(10, hitY: .52);
      other.door!.age = other.door!.destroyedAt! + .2;
      expect(await pixels(other, reduced: false), isNot(equals(frames[4])));
      // Everything flying is gone by the end; only the chewed sockets stay,
      // inside the wall bodies and never in the opening.
      final settled = <Uint8List>[];
      for (final t in [SkyDoor.crumbleDuration, 1.4, 6.0]) {
        o.door!.age = start + t;
        settled.add(await pixels(o, reduced: false));
      }
      expect(settled[1], settled[0]);
      expect(settled[2], settled[0]);
      final wall = opening(o);
      for (var y = wall.top.ceil() + 1; y < wall.bottom.floor() - 1; y++) {
        for (var x = 0; x < 800; x++) {
          expect(
            alphaAt(settled[0], x, y),
            0,
            reason: 'opening is clear at $x,$y',
          );
        }
      }
      expect(paintedOutside(settled[0], envelope(o)), 0);
      expect(
        settled[0].any((b) => b != 0),
        isTrue,
        reason: 'the wall remembers its broken sockets',
      );
      // Reduced Motion: gone at once, at any moment of the animation.
      for (final t in times) {
        o.door!.age = start + t;
        expect((await pixels(o)).every((b) => b == 0), isTrue);
      }
    });
  });

  testWidgets(
    'a ram throws debris further than a rock; a charge sits between',
    (tester) async {
      await tester.runAsync(() async {
        Future<(Uint8List, int)> frame(String blow, double at) async {
          final o = wallWith(hits: blow == 'shot' ? 3 : 0);
          o.advance(9);
          switch (blow) {
            case 'ram':
              o.door!.takeDamage(40, hitY: .5, rammed: true);
            case 'charged':
              o.door!.takeDamage(40, hitY: .5);
            default:
              o.door!.takeDamage(10, hitY: .5);
          }
          o.door!.age = o.door!.destroyedAt! + at;
          final data = await pixels(o, reduced: false);
          return (data, rightmost(data));
        }

        final shot = await frame('shot', .3),
            charged = await frame('charged', .3),
            ram = await frame('ram', .3);
        expect(changed(shot.$1, charged.$1), greaterThan(200));
        expect(changed(charged.$1, ram.$1), greaterThan(200));
        expect(ram.$2, greaterThan(shot.$2));
        expect(charged.$2, greaterThanOrEqualTo(shot.$2));
      });
    },
  );

  test('the fracture pattern is stable, bounded and cache-independent', () {
    DoorFracture build(int seed) => DoorFracture.of(
      w: .14,
      h: .34,
      seed: seed,
      blows: const [DoorBlow(.12, 0), DoorBlow(.2, .5), DoorBlow(.16, 1)],
      lethal: true,
    );
    final first = build(7);
    // Flush the cache with other seeds, then rebuild the same pattern.
    for (var i = 100; i < 140; i++) {
      build(i);
    }
    final again = build(7);
    expect(identical(first, again), isFalse);
    expect(again.shards.length, first.shards.length);
    for (var i = 0; i < first.shards.length; i++) {
      expect(again.shards[i].points, first.shards[i].points);
    }
    // Enough pieces to look shattered, few enough to paint cheaply.
    expect(first.shards.length, inInclusiveRange(12, 30));
    expect(first.craters.length, 2, reason: 'each earlier blow left a crater');
    // Every piece lies inside the panel.
    for (final shard in first.shards) {
      for (final p in shard.points) {
        expect(p.dx, inInclusiveRange(-1e-6, .14 + 1e-6));
        expect(p.dy, inInclusiveRange(-1e-6, .34 + 1e-6));
      }
    }
    // The pieces and craters tile the panel exactly.
    var area = 0.0;
    for (final shard in first.shards) {
      area += shard.area;
    }
    for (final crater in first.craters) {
      var a = 0.0;
      for (var i = 0; i < crater.length; i++) {
        final p = crater[i], q = crater[(i + 1) % crater.length];
        a += p.dx * q.dy - q.dx * p.dy;
      }
      area += a.abs() / 2;
    }
    expect(area, closeTo(.14 * .34, 1e-4));
  });

  testWidgets('captures the breakable wall for visual review', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_DOOR_ART')) return;
    final rig = await _Rig.start(tester);
    await rig.run();
    await tester.pumpWidget(const SizedBox());
  });
}

// ---------------------------------------------------------------------------
// Visual review harness. Everything below only runs with CAPTURE_DOOR_ART and
// renders the real BirdGame so wall art, backdrop and lighting are included.
// ---------------------------------------------------------------------------

const _out = 'build/visual-review/breakable-walls';

/// Times, in milliseconds after the killing blow, sampled for filmstrips.
const _filmMs = [0, 16, 33, 50, 67, 100, 133, 200, 300, 450, 600, 800];

/// Regions used for the readability sweep: warm, snowy, night, jungle,
/// desert gold, neon, bright, and a dusk.
const _sweep = [
  WorldRegion.jungle,
  WorldRegion.antarctica,
  WorldRegion.paris,
  WorldRegion.egypt,
  WorldRegion.cyberpunk,
  WorldRegion.newYork,
  WorldRegion.brazil,
  WorldRegion.rome,
  WorldRegion.mexico,
];

class _Rig {
  _Rig(this.tester, this.game, this.sim);
  final WidgetTester tester;
  final BirdGame game;
  final FlightSimulation sim;
  late Obstacle wall;
  static const wallX = 1.25;

  static Future<_Rig> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    final sim =
        FlightSimulation(
            rules: TapFlyMode(),
            practice: true,
            course: FlightCourse.starTrail,
          )
          ..phase = RunPhase.playing
          ..elapsed = 130
          ..bossesDefeated = 2;
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: false,
      onChanged: () {},
      playback: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('door-capture'),
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    return _Rig(tester, game, sim);
  }

  /// Puts a fresh panel in [region]'s walls, mid-hold, and returns it.
  Obstacle place(
    WorldRegion? region, {
    int appearance = 0,
    double gap = .34,
    double center = .5,
  }) {
    final leg = region == null ? 0.0 : region.index * WorldTour.leg;
    final o = Obstacle(
      x: wallX,
      center: center,
      gap: gap,
      appearance: appearance,
      bornAt: leg + 2,
      door: SkyDoor(),
    );
    sim.obstacles
      ..clear()
      ..addAll([
        o,
        Obstacle(x: 2.05, center: .3, gap: .34, appearance: 1, bornAt: leg + 2),
      ]);
    sim.elapsed = leg + 8;
    o.advance(sim.elapsed);
    wall = o;
    return o;
  }

  /// Sets the world clock (and with it every age-driven effect).
  void at(double seconds) {
    sim.elapsed = seconds;
    wall.advance(seconds);
  }

  Future<ui.Image> shot({double pixelRatio = 1}) async {
    await tester.pump(const Duration(milliseconds: 16));
    late ui.Image image;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('door-capture')),
      );
      image = await boundary.toImage(pixelRatio: pixelRatio);
    });
    expect(tester.takeException(), isNull);
    return image;
  }

  Future<void> save(ui.Image image, String name) async {
    await tester.runAsync(() async {
      final file = File('$_out/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(
        (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List(),
      );
    });
  }

  /// A labelled grid of crops, `crop` in logical pixels.
  Future<ui.Image> sheet(
    List<ui.Image> frames,
    List<String> labels, {
    required Rect crop,
    required int columns,
    double pixelRatio = 1,
    double? sourceRatio,
    double gap = 4,
  }) async {
    final source = sourceRatio ?? pixelRatio;
    late ui.Image result;
    await tester.runAsync(() async {
      final cw = crop.width * pixelRatio, ch = crop.height * pixelRatio;
      final rows = (frames.length / columns).ceil();
      final width = columns * cw + (columns + 1) * gap;
      final height = rows * ch + (rows + 1) * gap;
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      c.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = const Color(0xff1c1c22),
      );
      for (var i = 0; i < frames.length; i++) {
        final dx = gap + (i % columns) * (cw + gap);
        final dy = gap + (i ~/ columns) * (ch + gap);
        c.drawImageRect(
          frames[i],
          Rect.fromLTWH(
            crop.left * source,
            crop.top * source,
            crop.width * source,
            crop.height * source,
          ),
          Rect.fromLTWH(dx, dy, cw, ch),
          Paint()..filterQuality = FilterQuality.medium,
        );
        final label = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(c, Offset(dx + 4, dy + 3));
      }
      final picture = recorder.endRecording();
      result = await picture.toImage(width.ceil(), height.ceil());
      picture.dispose();
    });
    return result;
  }

  Future<void> run() async {
    Directory(_out).createSync(recursive: true);
    const set = String.fromEnvironment('DOOR_SET', defaultValue: 'all');
    bool wants(String name) => set == 'all' || set.split(',').contains(name);
    if (wants('stages')) await stages();
    if (wants('film')) {
      await film(null, 'default');
      for (final region in _sweep) {
        await film(region, region.name);
      }
    }
    if (wants('regions')) await regions();
    if (wants('hit')) await hitSequence();
    if (wants('blows')) await blows();
    if (wants('zoom')) await zoomBurst();
    if (wants('frames')) await consecutive();
    if (wants('sizes')) await sizes();
    if (wants('reduced')) await reducedMotion();
    if (wants('movie')) await movie();
    if (wants('compare')) await compare();
  }

  /// Crop around the panel and its collars, in logical pixels.
  Rect get panelCrop => Rect.fromLTWH(_Rig.wallX * 360 - 26, 88, 102, 184);

  Future<void> stages() async {
    place(null);
    final zooms = <ui.Image>[];
    final labels = <String>[];
    for (var hit = 0; hit <= 4; hit++) {
      if (hit > 0) {
        wall.door!.takeDamage(10, hitY: [0, .46, .55, .5, .5][hit] + .0);
      }
      at(130 + hit.toDouble() * 1.5);
      final image = await shot();
      await save(image, '${wall.door!.hp}hp');
      image.dispose();
      zooms.add(await shot(pixelRatio: 3));
      labels.add('${wall.door!.hp}hp');
    }
    final s = await sheet(
      zooms,
      labels,
      crop: panelCrop,
      columns: 5,
      pixelRatio: 3,
    );
    await save(s, 'stages-zoom');
  }

  /// How the panel is killed in a film: three base rocks then a fourth, a
  /// single full charge, or a sprint ram against an untouched panel.
  Obstacle stage(WorldRegion? region, String blow, {int appearance = 0}) {
    final o = place(region, appearance: appearance);
    final base = sim.elapsed;
    if (blow == 'shot') {
      for (var hit = 0; hit < 3; hit++) {
        at(base + .3 + hit * .4);
        o.door!.takeDamage(10, hitY: .5 + [0, -.05, .06][hit]);
      }
    }
    return o;
  }

  double strike(Obstacle o, String blow, double base) {
    final kill = base + 1.6;
    at(kill);
    switch (blow) {
      case 'charged':
        o.door!.takeDamage(40, hitY: .5);
      case 'ram':
        o.door!.takeDamage(40, hitY: .52, rammed: true);
      default:
        o.door!.takeDamage(10, hitY: .5);
    }
    return kill;
  }

  Future<List<ui.Image>> playKill(
    WorldRegion? region,
    String blow,
    List<int> times, {
    double pixelRatio = 1,
    int appearance = 0,
  }) async {
    final o = stage(region, blow, appearance: appearance);
    final kill = strike(o, blow, sim.elapsed - (blow == 'shot' ? 0 : 0));
    final frames = <ui.Image>[];
    for (final ms in times) {
      at(kill + ms / 1000);
      frames.add(await shot(pixelRatio: pixelRatio));
    }
    return frames;
  }

  Future<void> film(WorldRegion? region, String name) async {
    final base = (region == null ? 0.0 : region.index * WorldTour.leg) + 8;
    final o = stage(region, 'shot');
    assert(o == wall);
    final kill = strike(o, 'shot', base);
    final frames = <ui.Image>[];
    final labels = <String>[];
    for (final ms in _filmMs) {
      at(kill + ms / 1000);
      final image = await shot();
      frames.add(image);
      labels.add('$name ${ms}ms');
      await save(image, 'frames/$name/${ms}ms');
    }
    final crop = Rect.fromLTWH(_Rig.wallX * 360 - 90, 40, 300, 280);
    final s = await sheet(frames, labels, crop: crop, columns: 6);
    await save(s, 'film-$name');
    for (final f in frames) {
      f.dispose();
    }
  }

  /// The same break in several very different regions: intact (cracked),
  /// at the burst, mid-air and after the dust has settled.
  Future<void> regions() async {
    const moments = [-30, 67, 167, 450];
    final all = <WorldRegion?>[null, ..._sweep];
    final frames = <List<ui.Image>>[];
    final labels = <List<String>>[];
    for (final region in all) {
      final base = (region == null ? 0.0 : region.index * WorldTour.leg) + 8;
      final o = stage(region, 'shot');
      final kill = strike(o, 'shot', base);
      final column = <ui.Image>[];
      final names = <String>[];
      // The still before the blow is drawn from a copy of the state a moment
      // earlier: rebuild it instead of rewinding.
      for (final ms in moments) {
        if (ms < 0) {
          final o2 = stage(region, 'shot');
          at(base + 1.55);
          column.add(await shot());
          names.add('${region?.name ?? 'jungle*'} before');
          assert(o2 == wall);
          stage(region, 'shot');
          strike(wall, 'shot', base);
          continue;
        }
        at(kill + ms / 1000);
        column.add(await shot());
        names.add('${region?.name ?? 'jungle*'} +${ms}ms');
      }
      frames.add(column);
      labels.add(names);
    }
    // Row-major: one row per moment, one column per region.
    final flat = <ui.Image>[];
    final flatLabels = <String>[];
    for (var m = 0; m < moments.length; m++) {
      for (var r = 0; r < all.length; r++) {
        flat.add(frames[r][m]);
        flatLabels.add(labels[r][m]);
      }
    }
    final s = await sheet(
      flat,
      flatLabels,
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 66, 56, 190, 250),
      columns: all.length,
    );
    await save(s, 'regions');
  }

  /// One non-lethal hit, frame by frame.
  Future<void> hitSequence() async {
    const times = [0, 16, 33, 50, 67, 100, 133, 200, 300, 400];
    final o = place(null);
    final base = sim.elapsed;
    // A first hit, then the second, so cracks and craters accumulate.
    at(base + .4);
    o.door!.takeDamage(10, hitY: .46);
    at(base + 1.6);
    final hitAt = sim.elapsed;
    o.door!.takeDamage(10, hitY: .54);
    final frames = <ui.Image>[];
    final labels = <String>[];
    for (final ms in times) {
      at(hitAt + ms / 1000);
      frames.add(await shot(pixelRatio: 2));
      labels.add('hit +${ms}ms');
    }
    final s = await sheet(
      frames,
      labels,
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 100, 96, 190, 168),
      columns: 5,
      pixelRatio: 2,
    );
    await save(s, 'hit-sequence');
  }

  /// A base rock, a full charge and a ram, side by side in time.
  Future<void> blows() async {
    const times = [0, 33, 67, 100, 167, 250, 400, 600];
    final rows = <ui.Image>[];
    final labels = <String>[];
    for (final blow in ['shot', 'charged', 'ram']) {
      final frames = await playKill(WorldRegion.egypt, blow, times);
      for (var i = 0; i < frames.length; i++) {
        rows.add(frames[i]);
        labels.add('$blow ${times[i]}ms');
      }
    }
    final s = await sheet(
      rows,
      labels,
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 60, 40, 240, 280),
      columns: times.length,
    );
    await save(s, 'blows');
  }

  /// The Reduced Motion frames: still damage stages, and nothing at all once
  /// the panel is destroyed. Painted straight onto a sky colour.
  Future<void> reducedMotion() async {
    final frames = <ui.Image>[];
    final labels = <String>[];
    await tester.runAsync(() async {
      Future<ui.Image> draw(Obstacle o) async {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        c.drawRect(
          const Rect.fromLTWH(0, 0, 800, 360),
          Paint()..color = const Color(0xffbde9f6),
        );
        DoorArt.paint(c, 360, o, reducedMotion: true);
        final pic = rec.endRecording();
        final image = await pic.toImage(800, 360);
        pic.dispose();
        return image;
      }

      final o = Obstacle(
        x: _Rig.wallX,
        center: .5,
        gap: .34,
        bornAt: 2,
        door: SkyDoor(),
      );
      for (var hit = 0; hit <= 4; hit++) {
        if (hit > 0) {
          o.advance(5 + hit.toDouble());
          o.door!.takeDamage(10, hitY: .5 + [0, -.05, .06, 0, .02][hit]);
        }
        o.advance(6 + hit.toDouble());
        frames.add(await draw(o));
        labels.add('reduced ${o.door!.hp}hp');
      }
    });
    final s = await sheet(
      frames,
      labels,
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 30, 80, 110, 200),
      columns: 5,
    );
    await save(s, 'reduced-motion');
  }

  /// Openings of every size the game uses, intact and cracked, and the three
  /// looks a seed can give.
  Future<void> sizes() async {
    final frames = <ui.Image>[];
    final labels = <String>[];
    for (final (gap, appearance) in [
      (.28, 0),
      (.34, 1),
      (.40, 2),
      (.46, 0),
      (.52, 1),
    ]) {
      for (final hits in [0, 3]) {
        place(null, gap: gap, appearance: appearance);
        for (var i = 0; i < hits; i++) {
          at(130 + i.toDouble());
          wall.door!.takeDamage(10, hitY: .5 + [-.06, .05, .0][i] * gap / .34);
        }
        at(131 + hits.toDouble());
        frames.add(await shot(pixelRatio: 2));
        labels.add('gap $gap seed $appearance hits $hits');
      }
    }
    final s = await sheet(
      frames,
      labels,
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 26, 50, 102, 260),
      columns: 10,
      pixelRatio: 2,
    );
    await save(s, 'sizes');
  }

  /// Every 60 fps frame of the first 400 ms, to look for pops.
  Future<void> consecutive() async {
    final times = [for (var i = 0; i < 24; i++) (i * 1000 / 60).round()];
    final frames = await playKill(
      WorldRegion.china,
      'shot',
      times,
      pixelRatio: 1.25,
    );
    final s = await sheet(
      frames,
      [for (final t in times) '+${t}ms'],
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 70, 60, 230, 240),
      columns: 8,
      pixelRatio: 1.25,
    );
    await save(s, 'frames-60fps');
  }

  /// The peak of the burst, magnified.
  Future<void> zoomBurst() async {
    const times = [0, 16, 33, 50, 67, 83, 100, 133, 200];
    final frames = await playKill(null, 'shot', times, pixelRatio: 2.5);
    final labels = [for (final t in times) '+${t}ms'];
    final s = await sheet(
      frames,
      labels,
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 100, 70, 250, 220),
      columns: 3,
      pixelRatio: 2.5,
    );
    await save(s, 'zoom-burst');
    const tail = [200, 300, 400, 550, 700, 850, 950, 1100];
    final late = await playKill(null, 'shot', tail, pixelRatio: 2);
    final tailSheet = await sheet(
      late,
      [for (final t in tail) '+${t}ms'],
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 100, 40, 300, 280),
      columns: 4,
      pixelRatio: 2,
    );
    await save(tailSheet, 'zoom-tail');
    // Three moments of the shatter at four times life size.
    const close = [58, 80, 120];
    final big = await playKill(WorldRegion.egypt, 'shot', close, pixelRatio: 4);
    final bigSheet = await sheet(
      big,
      [for (final t in close) '+${t}ms x4'],
      crop: Rect.fromLTWH(_Rig.wallX * 360 - 50, 92, 170, 176),
      columns: 3,
      pixelRatio: 4,
    );
    await save(bigSheet, 'zoom-shards');
    // What the wall keeps once the debris is gone.
    final settled = await playKill(WorldRegion.jungle, 'shot', [
      1200,
    ], pixelRatio: 4);
    final sockets = await sheet(
      settled,
      ['sockets x4'],
      crop: panelCrop,
      columns: 1,
      pixelRatio: 4,
    );
    await save(sockets, 'zoom-sockets');
    // The intact panel and the seat, big.
    place(null);
    at(130);
    final panel = await shot(pixelRatio: 4);
    final one = await sheet(
      [panel],
      ['intact x4'],
      crop: panelCrop,
      columns: 1,
      pixelRatio: 4,
    );
    await save(one, 'zoom-panel');
  }

  /// 60 fps frames of a full break for an mp4 (path in DOOR_FRAMES).
  Future<void> movie() async {
    const dir = String.fromEnvironment('DOOR_FRAMES');
    if (dir.isEmpty) return;
    Directory(dir).createSync(recursive: true);
    final o = place(WorldRegion.egypt);
    final base = sim.elapsed;
    at(base + .2);
    o.door!.takeDamage(10, hitY: .5);
    at(base + .5);
    o.door!.takeDamage(10, hitY: .46);
    at(base + .8);
    o.door!.takeDamage(10, hitY: .55);
    const lead = 1.1;
    at(base + lead);
    o.door!.takeDamage(10, hitY: .5);
    const total = 2.4;
    for (var f = 0; f < total * 60; f++) {
      at(base + .1 + f / 60);
      final image = await shot(pixelRatio: 2);
      await tester.runAsync(() async {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$dir/f${f.toString().padLeft(4, '0')}.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
      });
      image.dispose();
    }
  }

  Future<ui.Image> load(String path) async {
    late ui.Image image;
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File(path).readAsBytesSync(),
      );
      image = (await codec.getNextFrame()).image;
    });
    return image;
  }

  /// Old artwork (kept as before-*.png) above the new.
  Future<void> compare() async {
    final oldFilm = await load('$_out/before-film.png');
    final newFilm = await load('$_out/film-default.png');
    late ui.Image stacked;
    await tester.runAsync(() async {
      final gap = 10.0;
      final w = math.max(oldFilm.width, newFilm.width).toDouble();
      final h = oldFilm.height + newFilm.height + gap * 3 + 60;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xff101014),
      );
      void title(String text, double y) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(12, y));
      }

      title('BEFORE: 8 identical chunks, 0.45 s', 4);
      c.drawImage(oldFilm, Offset(0, 40 + gap), Paint());
      final y2 = 40 + gap + oldFilm.height + gap;
      title('AFTER: shattering slab, medallion, dust, 1.0 s', y2);
      c.drawImage(newFilm, Offset(0, y2 + 36), Paint());
      final pic = rec.endRecording();
      stacked = await pic.toImage(
        w.ceil(),
        (y2 + 36 + newFilm.height + gap).ceil(),
      );
      pic.dispose();
    });
    await save(stacked, 'before-after');
    // Intact panel, before and after, magnified.
    final beforeStage = await load('$_out/before-40hp.png');
    final beforeCrack = await load('$_out/before-10hp.png');
    place(null);
    at(130);
    final afterStage = await shot(pixelRatio: 3);
    wall.door!.takeDamage(10, hitY: .46);
    wall.door!.takeDamage(10, hitY: .55);
    wall.door!.takeDamage(10, hitY: .5);
    at(140);
    final afterCrack = await shot(pixelRatio: 3);
    final crop = Rect.fromLTWH(_Rig.wallX * 360 - 20, 90, 90, 180);
    final olds = await sheet(
      [beforeStage, beforeCrack],
      ['old 40hp', 'old 10hp'],
      crop: crop,
      columns: 2,
      pixelRatio: 3,
      sourceRatio: 1,
    );
    final news = await sheet(
      [afterStage, afterCrack],
      ['new 40hp', 'new 10hp'],
      crop: crop,
      columns: 2,
      pixelRatio: 3,
    );
    late ui.Image s;
    await tester.runAsync(() async {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawImage(olds, Offset.zero, Paint());
      c.drawImage(news, Offset(olds.width.toDouble(), 0), Paint());
      final pic = rec.endRecording();
      s = await pic.toImage(olds.width + news.width, olds.height);
      pic.dispose();
    });
    await save(s, 'before-after-stages');
  }
}
