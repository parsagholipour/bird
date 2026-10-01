import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/duel_art.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/game/tether_art.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'duel_flight_test.dart'
    show RiggedRandom, clearCourse, duel, hold, hover, openFor;

/// Review renders are written with --dart-define=CAPTURE_VISUALS=true.
const _capture = bool.fromEnvironment('CAPTURE_VISUALS');

/// Only the moments whose names contain this are captured, when set.
const _only = String.fromEnvironment('DUEL_ONLY');
final _folder = Directory('build/visual-review/duel');

/// Where the birds hover in most moments: player 1 above, player 2 below.
const _apart = [.3, .7];

/// A duel flying over [region]'s stretch of the world tour.
FlightSimulation _over(WorldRegion region) {
  final sim = duel(random: RiggedRandom(9));
  final time = region.index * WorldTour.leg + 5;
  sim
    ..elapsed = time
    ..distance = time * .36;
  for (final bird in sim.flock) {
    bird.invulnerableUntil = 0;
  }
  // Settle the trails at the new clock.
  hover(sim, .6, _apart);
  return sim;
}

/// An opened box, [age] seconds into its burst.
MysteryBox _opened(
  FlightSimulation sim,
  double x,
  double y,
  BoxPrize prize, {
  required int opener,
  required double age,
}) => MysteryBox(x: x, y: y, phase: x * 3)
  ..openedAt = sim.elapsed - age
  ..opener = opener
  ..prize = prize;

/// A moment to draw, and where to look closely: a close-up [zoom] times
/// around [focus] (viewport heights).
typedef _Moment = ({FlightSimulation sim, Offset? focus, double zoom});

_Moment _shot(FlightSimulation sim, [Offset? focus, double zoom = 2.2]) =>
    (sim: sim, focus: focus, zoom: zoom);

/// Moments of a duel over [region], each a simulation ready to draw.
Map<String, _Moment Function()> _moments(WorldRegion region) => {
  // Boxes floating ahead of both birds, one above and one below.
  'closed': () {
    final sim = _over(region);
    hold(sim, [.38, .62]);
    sim.boxes.addAll([
      MysteryBox(x: .95, y: .22, phase: .4),
      MysteryBox(x: 1.45, y: .8, phase: 2.1),
      MysteryBox(x: 1.9, y: .5, phase: 4.2),
    ]);
    return _shot(sim, const Offset(1.0, .3), 3);
  },
  // A box mid-hop, its lid pushed up from inside, and one mid-glint.
  'hop': () {
    final sim = _over(region);
    hold(sim, [.38, .62]);
    double phaseAt(double clock) => ((clock - sim.elapsed) % 2.6) / 1.37;
    sim.boxes.addAll([
      MysteryBox(x: .95, y: .35, phase: phaseAt(.25)),
      MysteryBox(x: 1.25, y: .35, phase: phaseAt(1.445)),
    ]);
    return _shot(sim, const Offset(1.1, .33), 3.2);
  },
  // Every prize bursting out of its box: attacks on the top row, helps on
  // the bottom, player 1's on the left and player 2's on the right.
  for (final age in [.06, .2, .45, .8])
    'bursts-${(age * 100).round()}': () {
      final sim = _over(region);
      hold(sim, [.08, .94]);
      for (final prize in BoxPrize.values) {
        final column = prize.index % 3;
        final row = prize.attack ? .3 : .7;
        for (final opener in [0, 1]) {
          sim.boxes.add(
            _opened(
              sim,
              .3 + column * .3 + opener * 1.0,
              row,
              prize,
              opener: opener,
              age: age,
            ),
          );
        }
      }
      return _shot(sim, const Offset(.8, .48), 1.5);
    },
  // Player 1 flies into a box: the prize bursts out around the bird.
  'open-heart': () {
    final sim = _over(region);
    hold(sim, _apart);
    sim.lead.hearts = 3;
    openFor(sim, 0, BoxPrize.heart);
    hover(sim, .2, _apart);
    return _shot(sim, const Offset(.6, .3));
  },
  'open-spitter': () {
    final sim = _over(region);
    hold(sim, _apart);
    openFor(sim, 1, BoxPrize.spitter);
    hover(sim, .3, _apart);
    return _shot(sim, const Offset(.6, .6));
  },
  // Player 1's bats stream in at player 2's height.
  'swarm': () {
    final sim = _over(region);
    hold(sim, _apart);
    openFor(sim, 0, BoxPrize.batSwarm);
    hover(sim, 1.1, _apart);
    final bats = sim.swarm.map((b) => Offset(b.x, b.y)).toList();
    return _shot(sim, bats[bats.length ~/ 2] - const Offset(.15, 0));
  },
  // Player 2's spitter beetle spits at player 1.
  'spitter': () {
    final sim = _over(region);
    hold(sim, _apart);
    openFor(sim, 1, BoxPrize.spitter);
    final spitter = sim.enemies.single;
    for (var i = 0; i < 200 && sim.enemyAmmo.isEmpty; i++) {
      hover(sim, .02, _apart);
    }
    hover(sim, .25, _apart);
    expect(spitter.sender, 1);
    return _shot(sim, Offset(spitter.x - .2, spitter.y));
  },
  // Player 1's meteors fall on player 2: one in the sky, one on its way.
  'meteors': () {
    final sim = _over(region);
    hold(sim, _apart);
    openFor(sim, 0, BoxPrize.meteorShower);
    hover(sim, 1.15, _apart);
    final rock = sim.meteors.firstWhere((m) => m.y > 0);
    return _shot(sim, Offset(rock.x, rock.y));
  },
  // Player 1 has star power; player 2 keeps its shield.
  'star': () {
    final sim = _over(region);
    hold(sim, [.42, .62]);
    openFor(sim, 0, BoxPrize.starPower);
    hover(sim, 1.2, [.42, .62]);
    return _shot(sim, const Offset(.55, .48), 2.2);
  },
  // Its last second.
  'star-ending': () {
    final sim = _over(region);
    hold(sim, [.42, .62]);
    sim.lead.shield = false;
    openFor(sim, 0, BoxPrize.starPower);
    hover(sim, Duel.starPowerSeconds - .55, [.42, .62]);
    return _shot(sim, const Offset(.55, .48), 2.2);
  },
  // A hectic sky: both players' attacks at once and a box still to take.
  'brawl': () {
    final sim = _over(region);
    hold(sim, _apart);
    openFor(sim, 1, BoxPrize.spitter);
    hover(sim, .8, _apart);
    openFor(sim, 0, BoxPrize.batSwarm);
    hover(sim, .3, _apart);
    openFor(sim, 1, BoxPrize.meteorShower);
    hover(sim, .9, _apart);
    sim.boxes.add(MysteryBox(x: 1.7, y: .5, phase: 1.3));
    return _shot(sim);
  },
};

/// The regions the review flies over: bright day, deep night, desert noon
/// and neon night.
const _regions = [
  WorldRegion.jungle,
  WorldRegion.paris,
  WorldRegion.egypt,
  WorldRegion.cyberpunk,
];

Future<ui.Image> _render(
  BirdGame game,
  int width,
  int height, {
  Offset? focus,
  double zoom = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (focus != null) {
    canvas
      ..translate(width / 2, height / 2)
      ..scale(zoom)
      ..translate(-focus.dx * height, -focus.dy * height);
  }
  game.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

Future<void> _save(ui.Image image, String name) async {
  if (!_capture) return;
  _folder.createSync(recursive: true);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${_folder.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

/// Draws the flight at the review size: 800 × 360.
void _sized(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

BirdGame _game(FlightSimulation sim, {required bool reducedMotion}) => BirdGame(
  simulation: sim,
  nowMs: () => 0,
  bird: 0,
  partnerBird: 2,
  reducedMotion: reducedMotion,
  playback: true,
  onChanged: () {},
);

/// Draws [paint] alone on a transparent [size] canvas and returns its RGBA.
Future<ByteData> _pixels(Size size, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  final bytes = (await image.toByteData())!;
  image.dispose();
  picture.dispose();
  return bytes;
}

int _alphaAt(ByteData pixels, int width, Offset at) =>
    pixels.getUint8((at.dy.round() * width + at.dx.round()) * 4 + 3);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Fredoka',
    )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
  });

  for (final reducedMotion in [false, true]) {
    testWidgets('every duel moment draws over every region'
        '${reducedMotion ? ' with Reduced Motion' : ''}', (tester) async {
      _sized(tester);
      for (final region in _regions) {
        // Without captures one region is enough to prove nothing throws.
        if (!_capture && region != _regions.first) continue;
        for (final MapEntry(key: name, value: build) in _moments(
          region,
        ).entries) {
          final tag = '$name-${region.name}${reducedMotion ? '-calm' : ''}';
          if (_capture && _only.isNotEmpty && !tag.contains(_only)) continue;
          final (:sim, :focus, :zoom) = build();
          final game = _game(sim, reducedMotion: reducedMotion);
          await tester.pumpWidget(GameWidget(game: game));
          await tester.runAsync(() async {
            await game.loaded;
            game.pauseEngine();
            final image = await _render(game, 800, 360);
            await _save(image, tag);
            image.dispose();
            if (focus != null && _capture) {
              final close = await _render(
                game,
                800,
                360,
                focus: focus,
                zoom: zoom,
              );
              await _save(close, '$tag-zoom');
              close.dispose();
            }
            if (name.startsWith('bursts') && _capture) {
              // One box and its sticker, up close: player 1's heart.
              final detail = await _render(
                game,
                800,
                360,
                focus: const Offset(.34, .6),
                zoom: 3.5,
              );
              await _save(detail, '$tag-detail');
              detail.dispose();
            }
          });
          expect(tester.takeException(), isNull, reason: tag);
        }
      }
    });
  }

  test('the prize stickers, big and at HUD size, on light and dark', () async {
    if (!_capture) return;
    const size = Size(800, 360);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        const Rect.fromLTWH(0, 0, 800, 180),
        Paint()..color = SkyColors.sky,
      )
      ..drawRect(
        const Rect.fromLTWH(0, 180, 800, 180),
        Paint()..color = const Color(0xff2b2350),
      );
    for (final (row, top) in [(0, 0.0), (1, 180.0)]) {
      for (final prize in BoxPrize.values) {
        final x = 66.0 + prize.index * 128;
        DuelArt.prizeIcon(
          canvas,
          Offset(x, top + 62),
          48,
          prize,
          color: TetherArt.players[row],
        );
        DuelArt.prizeIcon(
          canvas,
          Offset(x - 22, top + 146),
          11,
          prize,
          color: TetherArt.players[row],
        );
        DuelArt.prizeIcon(
          canvas,
          Offset(x + 22, top + 146),
          16,
          prize,
          color: TetherArt.players[1 - row],
        );
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.round(),
      size.height.round(),
    );
    await _save(image, 'stickers');
    image.dispose();
    picture.dispose();
  });

  test('a closed box is solid at its centre and clear far from it', () async {
    const size = Size(400, 400);
    final sim = duel();
    clearCourse(sim);
    sim.boxes.add(MysteryBox(x: .5, y: .5, phase: 0));
    final pixels = await _pixels(
      size,
      (canvas) => DuelArt.boxes(canvas, size, sim, reducedMotion: true),
    );
    expect(_alphaAt(pixels, 400, const Offset(200, 200)), 255);
    expect(_alphaAt(pixels, 400, const Offset(200, 330)), 0);
    expect(_alphaAt(pixels, 400, const Offset(60, 200)), 0);
  });

  test('every prize has its own sticker', () async {
    const size = Size(100, 100);
    final looks = <String>{};
    for (final prize in BoxPrize.values) {
      final pixels = await _pixels(
        size,
        (canvas) => DuelArt.prizeIcon(
          canvas,
          const Offset(50, 50),
          30,
          prize,
          color: SkyColors.coral,
        ),
      );
      expect(_alphaAt(pixels, 100, const Offset(50, 50)), 255);
      looks.add(String.fromCharCodes(pixels.buffer.asUint8List()));
    }
    expect(looks, hasLength(BoxPrize.values.length));
  });

  test(
    'Reduced Motion draws the same box, marks and aura at any time',
    () async {
      const size = Size(720, 360);
      final sim = duel();
      hold(sim, _apart);
      openFor(sim, 0, BoxPrize.starPower);
      openFor(sim, 1, BoxPrize.batSwarm);
      hover(sim, 1, _apart);
      sim.boxes.add(MysteryBox(x: 1.2, y: .5, phase: 2));
      Future<List<int>> frame() async {
        final pixels = await _pixels(size, (canvas) {
          DuelArt.boxes(canvas, size, sim, reducedMotion: true);
          DuelArt.bursts(canvas, size, sim, reducedMotion: true);
          DuelArt.marks(canvas, size, sim, reducedMotion: true);
          sim.viewing(
            sim.lead,
            () => DuelArt.starPower(canvas, 360, sim, reducedMotion: true),
          );
        });
        return pixels.buffer.asUint8List();
      }

      final before = await frame();
      // Only the clock moves: the swarm stays where it is.
      sim.elapsed += .37;
      final after = await frame();
      expect(after, before);
    },
  );

  test('marks and the aura draw nothing without a sender or star', () async {
    const size = Size(720, 360);
    final sim = duel();
    hold(sim, _apart);
    final pixels = await _pixels(size, (canvas) {
      DuelArt.marks(canvas, size, sim, reducedMotion: false);
      sim.viewing(
        sim.lead,
        () => DuelArt.starPower(canvas, 360, sim, reducedMotion: false),
      );
    });
    expect(pixels.buffer.asUint8List().every((b) => b == 0), isTrue);
  });
}
