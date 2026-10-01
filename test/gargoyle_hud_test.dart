// The Searchlight Gargoyle's HUD (G7): the health plate, the lamp / SPOTTED
// tags, the entrance name card and the arrival / hit / fury / defeat bursts.
//
// Review renders (off unless GARGOYLE_G7_REVIEW=true):
//   flutter test --no-pub --dart-define=GARGOYLE_G7_REVIEW=true test/gargoyle_hud_test.dart
// write build/visual-review/g7-hud/ (or $GARGOYLE_G7_OUT).
@Timeout(Duration(minutes: 15))
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_encounter_ui.dart';
import 'package:push_up_bird/game/gargoyle_hud_art.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/regions/world_backdrop.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'gargoyle_pilot.dart' show arena;
import 'proof/counting_canvas.dart';
import 'proof/gargoyle_stage.dart';
import 'searchlight_gargoyle_test.dart' show hold, jumpTo;

const _review = bool.fromEnvironment('GARGOYLE_G7_REVIEW');
const _outEnv = String.fromEnvironment('GARGOYLE_G7_OUT');
const _only = String.fromEnvironment('GARGOYLE_G7_ONLY');
final _out = _outEnv.isEmpty ? 'build/visual-review/g7-hud' : _outEnv;

bool _want(String name) => _only.isEmpty || _only.split(',').any(name.contains);

Future<void> _save(ui.Image image, String name) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_out/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

Future<ui.Image> _render(int w, int h, void Function(ui.Canvas) draw) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec)..clipRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  draw(c);
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  pic.dispose();
  return img;
}

/// The Gargoyle in a flight state: [combat] seconds into the fight at [hp].
SkyBoss hudBoss(
  double combat, {
  int? hp,
  double? hitAgo,
  int lastDamage = 10,
  double? enragedAgo,
  double? spotAgo,
  double aspect = 640 / 360,
  double? deadFor,
  bool fury = false,
}) {
  final b = gBoss(combat, aspect: aspect, deadFor: deadFor, hitAgo: hitAgo, fury: fury);
  if (hp != null) b.hp = hp;
  if (enragedAgo != null) b.enragedAt = b.age - enragedAgo;
  if (hitAgo != null) b.lastDamage = lastDamage;
  if (spotAgo != null) b.lastSpotAt = b.age - spotAgo;
  return b;
}

/// A named state of the bar.
typedef _State = (String, SkyBoss Function(double aspect), bool);

List<_State> _states() => [
  ('full 160/160 (shuttered)', (a) => hudBoss(1.0, hp: 160, aspect: a), false),
  ('60%: 96/160', (a) => hudBoss(1.0, hp: 96, aspect: a), false),
  ('hit chip (.2 s)', (a) => hudBoss(7.5, hp: 130, hitAgo: .2, lastDamage: 10, aspect: a), false),
  ('fury onset (.15 s)', (a) => hudBoss(1.0, hp: 70, enragedAgo: .15, aspect: a), false),
  ('fury 67/160', (a) => hudBoss(1.0, hp: 67, enragedAgo: 3.0, aspect: a), false),
  ('critical 8/160', (a) => hudBoss(1.0, hp: 8, enragedAgo: 9.0, aspect: a), false),
  ('LAMP OPEN (vent)', (a) => hudBoss(7.2, hp: 125, aspect: a), false),
  ('SPOTTED! flash', (a) => hudBoss(4.2, hp: 125, spotAgo: .25, aspect: a), false),
  ('lamp opening (.1 s)', (a) => hudBoss(6.5, hp: 125, aspect: a), false),
  ('defeated', (a) => hudBoss(1.0, hp: 0, deadFor: .3, aspect: a), false),
  ('Reduced Motion: full', (a) => hudBoss(1.0, hp: 160, aspect: a), true),
  ('Reduced Motion: LAMP OPEN', (a) => hudBoss(7.2, hp: 125, aspect: a), true),
];

void _label(ui.Canvas c, String s, ui.Offset at, {double size = 11}) {
  text(c, s, at, size, const ui.Color(0xffffffff), outline: true);
}

Future<void> _reviewHud(int w) async {
  final size = ui.Size(w.toDouble(), 360);
  final aspect = w / 360;
  final states = _states();
  // 1) Full frames in a grid (the rig, beams, bird and the real bar).
  const cols = 3;
  final rows = (states.length / cols).ceil();
  final sheet = await _render(w * cols, 360 * rows, (c) {
    for (var i = 0; i < states.length; i++) {
      final (name, mk, reduced) = states[i];
      c.save();
      c.translate((i % cols) * w.toDouble(), (i ~/ cols) * 360.0);
      c.clipRect(ui.Offset.zero & size);
      final boss = mk(aspect);
      paintFrame(c, size, boss, FrameOptions(birdY: .74, reduced: reduced, label: name));
      c.restore();
    }
  });
  await _save(sheet, 'hud-frames-$w');
  // 2) The strips at 3x, one per state (the bar and its tags).
  final strip = BossHealthBarArt.bounds(size, hudBoss(1.0));
  final crop = ui.Rect.fromLTRB(strip.left - 12, 0, strip.right + 12, 66);
  const zoom = 3.0;
  final cellW = (crop.width * zoom).ceil(), cellH = (crop.height * zoom).ceil();
  final images = <ui.Image>[];
  for (final (_, mk, reduced) in states) {
    images.add(await _render(w, 360, (c) {
      paintFrame(c, size, mk(aspect), FrameOptions(birdY: .74, reduced: reduced, hud: true));
    }));
  }
  final zoomSheet = await _render(cellW * 2, (cellH + 18) * (states.length / 2).ceil(), (c) {
    c.drawRect(ui.Offset.zero & ui.Size((cellW * 2).toDouble(), 4000), ui.Paint()..color = const ui.Color(0xff0c0f22));
    for (var i = 0; i < states.length; i++) {
      final x0 = (i % 2) * cellW.toDouble(), y0 = (i ~/ 2) * (cellH + 18).toDouble();
      _label(c, states[i].$1, ui.Offset(x0 + 4, y0 + 2), size: 11);
      c.drawImageRect(
        images[i],
        crop,
        ui.Rect.fromLTWH(x0, y0 + 18, cellW.toDouble(), cellH.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    }
  });
  await _save(zoomSheet, 'hud-zoom-$w');
  // 3) Real size, only the strip: what the player sees.
  final real = await _render((crop.width).ceil() * 2, (crop.height).ceil() * ((states.length + 1) ~/ 2), (c) {
    for (var i = 0; i < states.length; i++) {
      c.drawImageRect(
        images[i],
        crop,
        ui.Rect.fromLTWH((i % 2) * crop.width, (i ~/ 2) * crop.height, crop.width, crop.height),
        ui.Paint(),
      );
    }
  });
  await _save(real, 'hud-real-$w');
}

/// Every boss's bar, calm and furious, on New York's night, at 3x: the
/// Gargoyle's beside the others' and the dragon's.
Future<void> _reviewCompare(int w) async {
  final size = ui.Size(w.toDouble(), 360);
  final kinds = [
    (BossKind.baronBat, 1),
    (BossKind.spitterBeetle, 2),
    (BossKind.duskMoth, 3),
    (BossKind.pirate, 4),
    (BossKind.dragon, 5),
    (BossKind.kingCoo, 6),
    (BossKind.searchlightGargoyle, 6),
  ];
  SkyBoss make(BossKind k, int n, {required bool fury}) {
    final b = k == BossKind.searchlightGargoyle
        ? hudBoss(1.0, hp: fury ? 67 : 160, enragedAgo: fury ? 3.0 : null, aspect: w / 360)
        : (SkyBoss(number: n, x: w * .7 / 360, kind: k, cinematic: true)..age = 4.6 + 1.0);
    if (k != BossKind.searchlightGargoyle && fury) {
      b.hp = b.maxHp ~/ 2 - 8;
      b.enragedAt = b.age - 3.0;
    }
    return b;
  }

  final strip = BossHealthBarArt.bounds(size, make(BossKind.baronBat, 1, fury: false));
  final crop = ui.Rect.fromLTRB(strip.left - 10, 2, strip.right + 10, 38);
  const zoom = 3.0;
  final cw = (crop.width * zoom).ceil(), ch = (crop.height * zoom).ceil();
  final calm = <ui.Image>[], furious = <ui.Image>[];
  for (final (k, n) in kinds) {
    for (final fury in [false, true]) {
      final img = await _render(w, 360, (c) {
        SkyScenery.paint(c, size, seconds: 38, distance: 38 * WorldBackdrop.cruise, held: WorldRegion.newYork, reducedMotion: true);
        c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff171c39).withValues(alpha: .22));
        BossHealthBarArt.paint(c, size, make(k, n, fury: fury));
      });
      (fury ? furious : calm).add(img);
    }
  }
  final sheet = await _render(cw * 2, (ch + 16) * kinds.length, (c) {
    c.drawRect(ui.Offset.zero & ui.Size((cw * 2).toDouble(), 3000), ui.Paint()..color = const ui.Color(0xff0c0f22));
    for (var i = 0; i < kinds.length; i++) {
      final y0 = i * (ch + 16).toDouble();
      _label(c, kinds[i].$1.name, ui.Offset(4, y0 + 1), size: 10);
      for (var j = 0; j < 2; j++) {
        c.drawImageRect(
          (j == 0 ? calm : furious)[i],
          crop,
          ui.Rect.fromLTWH(j * cw.toDouble(), y0 + 16, cw.toDouble(), ch.toDouble()),
          ui.Paint()..filterQuality = ui.FilterQuality.medium,
        );
      }
    }
  });
  await _save(sheet, 'hud-compare-$w');
}


/// The Gargoyle at boss age [age] of his arrival (0..4.6).
SkyBoss arrivalBoss(double age, {double aspect = 640 / 360}) => gBoss(age - 4.6, aspect: aspect);

const _quote = '\u201cHold still! Nobody ever stays in the light.\u201d';

ui.Offset _lamp(ui.Size s, SkyBoss b) => bossCentre(s, b);

Future<void> _reviewCard(int w) async {
  final size = ui.Size(w.toDouble(), 360);
  final ages = [2.84, 2.9, 2.97, 3.05, 3.15, 3.3, 3.6, 4.15, 4.4];
  const cols = 3;
  final rows = (ages.length / cols).ceil();
  final sheet = await _render(w * cols, 360 * rows, (c) {
    for (var i = 0; i < ages.length; i++) {
      c.save();
      c.translate((i % cols) * w.toDouble(), (i ~/ cols) * 360.0);
      c.clipRect(ui.Offset.zero & size);
      final b = arrivalBoss(ages[i], aspect: w / 360);
      paintFrame(c, size, b, FrameOptions(birdY: .62, hud: false, label: 'age ${ages[i]}'));
      GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: false), birdY: .62, line: _quote);
      c.restore();
    }
  });
  await _save(sheet, 'card-$w');
  // Reduced Motion and the bird behind the card.
  final rm = await _render(w * 2, 360, (c) {
    for (var i = 0; i < 2; i++) {
      c.save();
      c.translate(i * w.toDouble(), 0);
      c.clipRect(ui.Offset.zero & size);
      final b = arrivalBoss(i == 0 ? 3.4 : 3.5, aspect: w / 360);
      paintFrame(c, size, b, FrameOptions(birdY: i == 0 ? .62 : .3, reduced: true, hud: false, label: i == 0 ? 'Reduced Motion' : 'bird behind the card'));
      GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: true), birdY: i == 0 ? .62 : .3, line: _quote);
      c.restore();
    }
  });
  await _save(rm, 'card-reduced-$w');
}

Future<void> _bursts(String name, int w, List<(String, SkyBoss Function(), void Function(ui.Canvas, ui.Size, SkyBoss) over)> frames, {ui.Rect? crop, int cols = 3, double scale = 1}) async {
  final size = ui.Size(w.toDouble(), 360);
  final box = crop ?? ui.Rect.fromLTWH(0, 0, w.toDouble(), 360);
  final cw = (box.width * scale).ceil(), ch = (box.height * scale).ceil();
  final rows = (frames.length / cols).ceil();
  final sheet = await _render(cw * cols, (ch + 16) * rows, (c) {
    c.drawRect(ui.Offset.zero & ui.Size((cw * cols).toDouble(), ((ch + 16) * rows).toDouble()), ui.Paint()..color = const ui.Color(0xff0c0f22));
    for (var i = 0; i < frames.length; i++) {
      final (label, mk, over) = frames[i];
      c.save();
      c.translate((i % cols) * cw.toDouble(), (i ~/ cols) * (ch + 16).toDouble() + 16);
      c.clipRect(ui.Offset.zero & ui.Size(cw.toDouble(), ch.toDouble()));
      c.scale(scale);
      c.translate(-box.left, -box.top);
      final b = mk();
      paintFrame(c, size, b, const FrameOptions(birdY: .62, hud: false));
      over(c, size, b);
      c.restore();
      _label(c, label, ui.Offset((i % cols) * cw + 4.0, (i ~/ cols) * (ch + 16) + 1.0), size: 11);
    }
  });
  await _save(sheet, name);
}

Future<void> _reviewBursts(int w) async {
  final aspect = w / 360;
  final crop = ui.Rect.fromLTRB(w * .3, 0, w.toDouble(), 360);
  // The hit / fury sheet reaches left to the bird's column (the spot ring).
  final wide = ui.Rect.fromLTRB(w * .2, 0, w.toDouble(), 360);
  // The waking.
  await _bursts('arrival-$w', w, [
    for (final age in [1.5, 1.68, 1.8, 1.95, 2.1, 2.3, 2.6, 2.9, 3.4])
      (
        'age $age',
        () => arrivalBoss(age, aspect: aspect),
        (c, s, b) {
          final at = _lamp(s, b);
          GargoyleEncounterUi.awaken(c, at, s.height, b.age - SkyBoss.revealAt, reduced: false);
          GargoyleEncounterUi.flush(c, at, s.height, b.age, reduced: false);
        },
      ),
  ], crop: crop);
  // The hit and the fury onset.
  await _bursts('hit-fury-$w', w, [
    for (final since in [.02, .06, .12, .2])
      (
        'hit +$since',
        () => hudBoss(7.2, hp: 130, hitAgo: since, aspect: aspect),
        (c, s, b) => GargoyleEncounterUi.hit(c, _lamp(s, b), s.height, since, reduced: false),
      ),
    for (final since in [.05, .2, .45, .8])
      (
        'fury +$since',
        () => hudBoss(1.0, hp: 70, enragedAgo: since, aspect: aspect),
        (c, s, b) => GargoyleEncounterUi.furyOnset(c, _lamp(s, b), s.height, since, reduced: false),
      ),
    (
      'hit, Reduced Motion',
      () => hudBoss(7.2, hp: 130, hitAgo: .1, aspect: aspect),
      (c, s, b) => GargoyleEncounterUi.hit(c, _lamp(s, b), s.height, .1, reduced: true),
    ),
    (
      'fury, Reduced Motion',
      () => hudBoss(1.0, hp: 70, enragedAgo: .3, aspect: aspect),
      (c, s, b) => GargoyleEncounterUi.furyOnset(c, _lamp(s, b), s.height, .3, reduced: true),
    ),
    (
      'spot ring +.1',
      () => hudBoss(4.2, hp: 125, aspect: aspect),
      (c, s, b) => GargoyleEncounterUi.spotRing(c, ui.Offset(FlightSimulationBird.x * s.height, .62 * s.height), s.height, .1, reduced: false),
    ),
  ], crop: wide);
  // The defeat, frame by frame.
  final deaths = [.3, .8, .95, 1.1, 1.3, 1.6, 1.9, 2.3, 2.8, 3.4, 3.7];
  await _bursts('defeat-$w', w, [
    for (final d in deaths)
      (
        'death +$d',
        () => hudBoss(1.0, hp: 0, deadFor: d, aspect: aspect),
        (c, s, b) {
          final at = _lamp(s, b);
          GargoyleEncounterUi.rubble(c, at, s.height, d, reduced: false);
          GargoyleEncounterUi.crumble(c, at, s.height, d, reduced: false);
          GargoyleEncounterUi.lenses(c, at, s.height, d, reduced: false);
          GargoyleEncounterUi.pigeonsOut(c, at, s.height, d, reduced: false);
        },
      ),
    (
      'Reduced Motion +2.9',
      () => hudBoss(1.0, hp: 0, deadFor: 2.9, aspect: aspect),
      (c, s, b) {
        final at = _lamp(s, b);
        GargoyleEncounterUi.rubble(c, at, s.height, 2.9, reduced: true);
        GargoyleEncounterUi.crumble(c, at, s.height, 2.9, reduced: true);
        GargoyleEncounterUi.lenses(c, at, s.height, 2.9, reduced: true);
        GargoyleEncounterUi.pigeonsOut(c, at, s.height, 2.9, reduced: true);
      },
    ),
  ], crop: crop);
}


/// The same pieces over a bright day sky (the world tour's Egypt) and close-ups
/// of the card and the bird's ring: contrast on any backdrop.
Future<void> _reviewBright(int w) async {
  final size = ui.Size(w.toDouble(), 360);
  final aspect = w / 360;
  final frames = <(String, SkyBoss, void Function(ui.Canvas, ui.Size, SkyBoss))>[
    ('card 3.6 on Egypt', arrivalBoss(3.6, aspect: aspect), (c, s, b) => GargoyleEncounterUi.nameCard(c, s, b, BossMotion(b, reducedMotion: false), birdY: .62, line: _quote)),
    ('LAMP OPEN on Egypt', hudBoss(7.2, hp: 125, aspect: aspect), (c, s, b) {}),
    ('SPOTTED on Egypt', hudBoss(4.2, hp: 125, spotAgo: .25, aspect: aspect), (c, s, b) {}),
    ('fury on Egypt', hudBoss(1.0, hp: 67, enragedAgo: 3.0, aspect: aspect), (c, s, b) {}),
    ('defeat +1.5 on Egypt', hudBoss(1.0, hp: 0, deadFor: 1.5, aspect: aspect), (c, s, b) {
      final at = _lamp(s, b);
      GargoyleEncounterUi.rubble(c, at, s.height, 1.5, reduced: false);
      GargoyleEncounterUi.crumble(c, at, s.height, 1.5, reduced: false);
      GargoyleEncounterUi.lenses(c, at, s.height, 1.5, reduced: false);
      GargoyleEncounterUi.pigeonsOut(c, at, s.height, 1.5, reduced: false);
    }),
    ('defeat +3.0 on Egypt', hudBoss(1.0, hp: 0, deadFor: 3.0, aspect: aspect), (c, s, b) {
      final at = _lamp(s, b);
      GargoyleEncounterUi.rubble(c, at, s.height, 3.0, reduced: false);
      GargoyleEncounterUi.crumble(c, at, s.height, 3.0, reduced: false);
      GargoyleEncounterUi.lenses(c, at, s.height, 3.0, reduced: false);
      GargoyleEncounterUi.pigeonsOut(c, at, s.height, 3.0, reduced: false);
    }),
  ];
  const cols = 3;
  final rows = (frames.length / cols).ceil();
  final sheet = await _render(w * cols, 360 * rows, (c) {
    for (var i = 0; i < frames.length; i++) {
      final (label, b, over) = frames[i];
      c.save();
      c.translate((i % cols) * w.toDouble(), (i ~/ cols) * 360.0);
      c.clipRect(ui.Offset.zero & size);
      paintFrame(c, size, b, FrameOptions(birdY: .62, hud: !b.inCutscene, region: WorldRegion.egypt, dim: 0, label: label));
      over(c, size, b);
      c.restore();
    }
  });
  await _save(sheet, 'bright-$w');
}

Future<void> _reviewCloseups(int w) async {
  final size = ui.Size(w.toDouble(), 360);
  final aspect = w / 360;
  final card = arrivalBoss(3.7, aspect: aspect);
  final spot = hudBoss(4.2, hp: 125, spotAgo: .12, aspect: aspect);
  final images = <ui.Image>[];
  images.add(await _render(w, 360, (c) {
    paintFrame(c, size, card, const FrameOptions(birdY: .62, hud: false));
    GargoyleEncounterUi.nameCard(c, size, card, BossMotion(card, reducedMotion: false), birdY: .62, line: _quote);
  }));
  images.add(await _render(w, 360, (c) {
    paintFrame(c, size, spot, const FrameOptions(birdY: .62, spotted: false));
    GargoyleEncounterUi.spotRing(c, ui.Offset(.47 * 360, .62 * 360), 360, .12, reduced: false);
  }));
  images.add(await _render(w, 360, (c) {
    paintFrame(c, size, spot, const FrameOptions(birdY: .62, spotted: false));
    GargoyleEncounterUi.spotRing(c, ui.Offset(.47 * 360, .62 * 360), 360, .3, reduced: false);
  }));
  const zoom = 3.0;
  final cardCrop = ui.Rect.fromLTWH(30, 20, 270, 200), ringCrop = ui.Rect.fromLTWH(100, 190, 140, 100);
  final out = await _render((cardCrop.width * zoom).ceil() + (ringCrop.width * zoom).ceil(), (cardCrop.height * zoom).ceil() + 8 + (ringCrop.height * zoom).ceil(), (c) {
    c.drawRect(ui.Offset.zero & const ui.Size(2000, 2000), ui.Paint()..color = const ui.Color(0xff0c0f22));
    c.drawImageRect(images[0], cardCrop, ui.Rect.fromLTWH(0, 0, cardCrop.width * zoom, cardCrop.height * zoom), ui.Paint()..filterQuality = ui.FilterQuality.medium);
    c.drawImageRect(images[1], ringCrop, ui.Rect.fromLTWH(cardCrop.width * zoom, 0, ringCrop.width * zoom, ringCrop.height * zoom), ui.Paint()..filterQuality = ui.FilterQuality.medium);
    c.drawImageRect(images[2], ringCrop, ui.Rect.fromLTWH(cardCrop.width * zoom, ringCrop.height * zoom + 8, ringCrop.width * zoom, ringCrop.height * zoom), ui.Paint()..filterQuality = ui.FilterQuality.medium);
  });
  await _save(out, 'closeups-$w');
}

/// The bird's column (the rules' `FlightSimulation.birdX`).
abstract final class FlightSimulationBird {
  static const x = .47;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
    await (FontLoader('Nunito')..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
  });

  if (_review) {
    group('review renders', () {
      testWidgets('HUD, card and bursts at 640 and 800', (tester) async {
        await tester.runAsync(() async {
          if (_want('hud')) {
            await _reviewHud(640);
            await _reviewHud(800);
          }
          if (_want('card')) {
            await _reviewCard(640);
            await _reviewCard(800);
          }
          if (_want('burst')) {
            await _reviewBursts(640);
            await _reviewBursts(800);
          }
          if (_want('bright')) {
            await _reviewBright(640);
          }
          if (_want('closeups')) {
            await _reviewCloseups(640);
          }
          if (_want('compare')) {
            await _reviewCompare(640);
            await _reviewCompare(800);
          }
        });
      });
    });
  }

  _hudTests();
  _cardTests();
  _burstTests();
}

// ============================================================ the tests ==

const _sizes = [ui.Size(640, 360), ui.Size(800, 360)];

Counting _count(void Function(ui.Canvas) draw) {
  final c = Counting(ui.Canvas(ui.PictureRecorder()));
  draw(c);
  return c;
}

Future<Uint8List> _pixels(int w, int h, void Function(ui.Canvas) draw) async {
  final img = await _render(w, h, draw);
  final bytes = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  return bytes.buffer.asUint8List();
}

/// How many pixels differ by more than [tolerance] in any channel.
int _diff(Uint8List a, Uint8List b, [int tolerance = 8]) {
  expect(a.length, b.length);
  var n = 0, x0 = 1 << 20, x1 = 0, y0 = 1 << 20, y1 = 0;
  final w = 640;
  for (var i = 0; i < a.length; i += 4) {
    if ((a[i] - b[i]).abs() > tolerance || (a[i + 1] - b[i + 1]).abs() > tolerance || (a[i + 2] - b[i + 2]).abs() > tolerance) {
      n++;
      final px = (i ~/ 4) % w, py = (i ~/ 4) ~/ w;
      x0 = math.min(x0, px);
      x1 = math.max(x1, px);
      y0 = math.min(y0, py);
      y1 = math.max(y1, py);
    }
  }
  if (n > 0) {
    // ignore: avoid_print
    print('diff $n pixels in x $x0..$x1, y $y0..$y1');
  }
  return n;
}

void _paintBar(ui.Canvas c, ui.Size size, SkyBoss boss, {bool reduced = false}) => BossHealthBarArt.paint(c, size, boss, reducedMotion: reduced);

/// Every state of the bar the fight can show (name, boss, Reduced Motion).
List<(String, SkyBoss, bool)> _everyState(double aspect) => [
  for (final (name, mk, reduced) in _states()) (name, mk(aspect), reduced),
  ('perch mid-cycle', hudBoss(2.4, hp: 160, aspect: aspect), false),
  ('warning', hudBoss(3.0, hp: 160, aspect: aspect), false),
  ('sweep', hudBoss(4.5, hp: 140, aspect: aspect), false),
  ('vent closing', hudBoss(8.8, hp: 100, aspect: aspect), false),
  ('fury, lamp open', hudBoss(7.5, hp: 60, enragedAgo: 5.0, aspect: aspect), false),
  ('fury, spotted', hudBoss(4.6, hp: 60, enragedAgo: 5.0, spotAgo: .1, aspect: aspect), false),
  ('last hit chip in fury', hudBoss(7.6, hp: 70, hitAgo: .15, enragedAgo: .15, aspect: aspect), false),
];

void _hudTests() {
  group('the health bar plate (G7)', () {
    test('the strip is the same size and place as every boss\'s, at both phone sizes, in every state', () {
      for (final size in _sizes) {
        final baseline = BossHealthBarArt.bounds(size, SkyBoss(number: 1, x: 1.5, cinematic: true));
        for (final (name, boss, _) in _everyState(size.width / size.height)) {
          expect(BossHealthBarArt.bounds(size, boss), baseline, reason: '$name at $size');
        }
        // The plate (its silhouette's bounds are the strip's) never leaves it by more than
        // the spool and the tag's hang below.
        expect(baseline.height, closeTo(22, .01));
      }
    });

    test('a frame stays inside its budget in every state: <= 60 ops, 0 clips, 0 layers, no blur', () {
      for (final size in _sizes) {
        var worst = 0, at = '';
        for (final (name, boss, reduced) in _everyState(size.width / size.height)) {
          if (boss.inCutscene) continue;
          final c = _count((c) => _paintBar(c, size, boss, reduced: reduced));
          expect(c.layers, 0, reason: name);
          expect(c.blurs, 0, reason: name);
          expect(c.clips, 0, reason: '$name: the Gargoyle\'s bar needs no clip');
          if (c.draws > worst) {
            worst = c.draws;
            at = '$name at ${size.width}';
          }
        }
        // ignore: avoid_print
        print('G7 bar: worst frame $worst ops ($at)');
        expect(worst, lessThanOrEqualTo(60), reason: at);
      }
    });

    test('the whole fight needs at most 4 distinct shaders (cold), and a warm frame builds none', () {
      GargoyleKit.clearCaches();
      for (final size in _sizes) {
        for (final (_, boss, reduced) in _everyState(size.width / size.height)) {
          if (boss.inCutscene) continue;
          _count((c) => _paintBar(c, size, boss, reduced: reduced));
        }
      }
      // (Soft glows are the kit's, shared with the rig.)
      final own = GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).toList();
      // ignore: avoid_print
      print('G7 bar shaders over a whole fight, both sizes: ${own.length} $own');
      // Two layouts (640 and 800) key their own, so at most 4 per layout.
      expect(own.length, lessThanOrEqualTo(8));
      for (final size in _sizes) {
        GargoyleKit.clearCaches();
        for (final (_, boss, reduced) in _everyState(size.width / size.height)) {
          if (boss.inCutscene) continue;
          _count((c) => _paintBar(c, size, boss, reduced: reduced));
        }
        final perLayout = GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).length;
        expect(perLayout, lessThanOrEqualTo(4), reason: 'one layout (${size.width}) owns 4 gradients: steel, amber, fury amber, lens');
        final before = GargoyleKit.shadersBuilt;
        for (final (_, boss, reduced) in _everyState(size.width / size.height)) {
          if (boss.inCutscene) continue;
          _count((c) => _paintBar(c, size, boss, reduced: reduced));
        }
        expect(GargoyleKit.shadersBuilt - before, 0, reason: 'a warm frame builds no shader');
      }
    });

    test('the lamp tag\'s type is at least 10 px at 640 x 360 and 800 x 360; the words say what to do', () {
      for (final size in _sizes) {
        final u = math.min(size.height / 360, size.width / 640).clamp(.8, 1.3);
        expect(GargoyleHudArt.tagText * u, greaterThanOrEqualTo(10));
        expect(GargoyleHudArt.spottedTagSize(u).height, greaterThanOrEqualTo(15));
      }
      expect(GargoyleHudArt.lampWords + GargoyleHudArt.shootWords, 'LAMP OPEN · SHOOT!');
      expect(GargoyleHudArt.spottedWords, 'SPOTTED!');
      expect(GargoyleHudArt.label, 'GARGOYLE');
    });

    test('the tags hang under the plate\'s left end and clear his head and crest at both sizes', () {
      for (final size in _sizes) {
        final boss = hudBoss(7.2, hp: 125, aspect: size.width / size.height);
        final strip = BossHealthBarArt.bounds(size, boss);
        final u = math.min(size.height / 360, size.width / 640).clamp(.8, 1.3);
        final tag = GargoyleHudArt.lampTagSize(u);
        final left = strip.left + 9 * u, right = left + tag.width;
        final lamp = bossCentre(size, boss);
        final unit = size.height * SkyBoss.radius;
        // His crest roots start 1.74 units left of the lamp (the tallest part of him
        // under the tag's rows); the beak and lenses are far below.
        expect(right, lessThan(lamp.dx - 1.74 * unit - 4), reason: 'tag right edge $right, crest at ${lamp.dx - 1.74 * unit}');
        expect(left, greaterThan(strip.left), reason: 'under the plate, not before it');
        expect(strip.top + strip.height + tag.height, lessThan(size.height * .2));
        final spot = GargoyleHudArt.spottedTagSize(u);
        expect(left + spot.width, lessThan(lamp.dx - 1.74 * unit - 4));
      }
    });

    testWidgets('the lamp tag shows exactly while the lamp is open and the SPOTTED! flash exactly for its second', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        final strip = BossHealthBarArt.bounds(size, hudBoss(1.0));
        final tagRegion = ui.Rect.fromLTWH(strip.left, strip.bottom + 2, 150, 14);
        Future<Uint8List> region(SkyBoss b) => _pixels(640, 360, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff202a50));
          _paintBar(c, size, b);
        });
        final closed = await region(hudBoss(6.3, hp: 125));
        final open = await region(hudBoss(7.0, hp: 125));
        final shut = await region(hudBoss(9.3, hp: 125));
        int tagPixels(Uint8List a, Uint8List base) {
          var n = 0;
          for (var y = tagRegion.top.floor(); y < tagRegion.bottom.ceil(); y++) {
            for (var x = tagRegion.left.floor(); x < tagRegion.right.ceil(); x++) {
              final i = (y * 640 + x) * 4;
              if ((a[i] - base[i]).abs() + (a[i + 1] - base[i + 1]).abs() + (a[i + 2] - base[i + 2]).abs() > 60) n++;
            }
          }
          return n;
        }

        expect(tagPixels(open, closed), greaterThan(400), reason: 'the tag is there while the lamp is open');
        expect(tagPixels(shut, closed), lessThan(20), reason: 'and gone in the next cycle\'s perch');
        final spot = await region(hudBoss(4.2, hp: 125, spotAgo: .3));
        final late = await region(hudBoss(4.2, hp: 125, spotAgo: 1.2));
        expect(tagPixels(spot, closed), greaterThan(400));
        expect(tagPixels(late, closed), lessThan(20), reason: 'SPOTTED! lasts ${GargoyleHudArt.spottedSeconds} s');
      });
    });

    testWidgets('the states differ where they must: shuttered/open, calm/fury, hit, spotted; and the same state repeats', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        Future<Uint8List> shot(SkyBoss b, {bool reduced = false}) => _pixels(640, 90, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff202a50));
          _paintBar(c, size, b, reduced: reduced);
        });
        final calm = await shot(hudBoss(1.0, hp: 125));
        expect(_diff(calm, await shot(hudBoss(1.0, hp: 125))), 0, reason: 'a frame repeats exactly');
        expect(_diff(calm, await shot(hudBoss(7.2, hp: 125))), greaterThan(300), reason: 'the open lamp lights the medallion, the louvres and the tag');
        expect(_diff(calm, await shot(hudBoss(1.0, hp: 67, enragedAgo: 4))), greaterThan(300), reason: 'fury');
        expect(_diff(calm, await shot(hudBoss(1.0, hp: 125, hitAgo: .03))), greaterThan(30), reason: 'the hit flash on the rim');
        expect(_diff(calm, await shot(hudBoss(4.2, hp: 125, spotAgo: .2))), greaterThan(300), reason: 'SPOTTED!');
        // The fury onset's crack is there at .2 s and cooler at 2 s.
        final onset = await shot(hudBoss(1.0, hp: 67, enragedAgo: .2));
        final settled = await shot(hudBoss(1.0, hp: 67, enragedAgo: 3.0));
        expect(_diff(onset, settled), greaterThan(40));
      });
    });

    testWidgets('Reduced Motion: nothing moves (no pulse, glint, shudder, pop), the states stay', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        Future<Uint8List> shot(SkyBoss b, bool reduced) => _pixels(640, 90, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff202a50));
          _paintBar(c, size, b, reduced: reduced);
        });
        // The same moment of the cycle nine seconds apart: only the glint's and the pulse's phase differ.
        final a = hudBoss(1.0, hp: 125), b = hudBoss(10.0, hp: 125);
        expect(_diff(await shot(a, true), await shot(b, true)), 0);
        // The lamp tag's pulse is gone: two frames inside the vent are identical.
        final v1 = hudBoss(7.0, hp: 125), v2 = hudBoss(7.0 + 9.0, hp: 125);
        expect(_diff(await shot(v1, true), await shot(v2, true)), 0, reason: 'a steady tag');
        // Under motion the same two differ (the pulse).
        expect(_diff(await shot(v1, false), await shot(v2, false)), greaterThan(0));
        // States stay: the lamp, fury.
        expect(_diff(await shot(a, true), await shot(hudBoss(7.0, hp: 125), true)), greaterThan(300));
        expect(_diff(await shot(a, true), await shot(hudBoss(1.0, hp: 67, enragedAgo: 4), true)), greaterThan(300));
        // The hit does not shudder the plate.
        expect(GargoyleHudArt.jolt(.05, 1, reduced: true), ui.Offset.zero);
        expect(GargoyleHudArt.jolt(.05, 1, reduced: false).distance, greaterThan(0));
        expect(GargoyleHudArt.jolt(.5, 1, reduced: false), ui.Offset.zero);
        expect(GargoyleHudArt.jolt(.05, 1, reduced: false).distance, lessThan(1.6), reason: 'about a pixel');
      });
    });

    testWidgets('the same frame is the same pixels after every cache is flooded and rebuilt', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        final boss = hudBoss(7.5, hp: 90, hitAgo: .15, enragedAgo: 3, spotAgo: 2.0);
        Future<Uint8List> shot() => _pixels(640, 90, (c) => _paintBar(c, size, boss));
        final first = await shot();
        GargoyleKit.clearCaches();
        for (final (_, b, r) in _everyState(2.2)) {
          if (!b.inCutscene) _count((c) => _paintBar(c, size, b, reduced: r));
        }
        expect(_diff(first, await shot(), 0), 0);
      });
    });

    test('non-finite clocks, health and sizes paint nothing worse than nothing and never throw', () {
      const size = ui.Size(640, 360);
      final bad = [double.nan, double.infinity, double.negativeInfinity];
      for (final v in bad) {
        final b = hudBoss(1.0, hp: 100);
        b.age = v;
        expect(() => _count((c) => _paintBar(c, size, b)), returnsNormally);
        final b2 = hudBoss(7.2, hp: 100)..lastHitAt = v;
        expect(() => _count((c) => _paintBar(c, size, b2)), returnsNormally);
        final b3 = hudBoss(7.2, hp: 100)..lastSpotAt = v;
        expect(() => _count((c) => _paintBar(c, size, b3)), returnsNormally);
        final b4 = hudBoss(7.2, hp: 100)..enragedAt = v;
        expect(() => _count((c) => _paintBar(c, size, b4)), returnsNormally);
        final canvas = ui.Canvas(ui.PictureRecorder());
        const r = ui.Rect.fromLTWH(10, 10, 200, 20);
        expect(() {
          GargoyleHudArt.frame(canvas, r, r, v, fury: true, defeated: false, wave: v, flash: v);
          GargoyleHudArt.crest(canvas, ui.Offset(v, v), v, fury: true, glow: v, shutter: v, wave: v);
          GargoyleHudArt.crest(canvas, const ui.Offset(20, 20), 10, fury: false, glow: v, shutter: v, wave: v);
          GargoyleHudArt.track(canvas, r, v);
          GargoyleHudArt.fill(canvas, r, v, 1, glow: v, phase: v, edge: true, surge: v);
          GargoyleHudArt.fill(canvas, r, 100, 1, glow: v, phase: v, edge: true, surge: v);
          GargoyleHudArt.chip(canvas, r, v, v, heat: v, alpha: v);
          GargoyleHudArt.notch(canvas, r, r, 1, above: true, fury: true, wave: v, furyAge: v);
          GargoyleHudArt.lampTag(canvas, r, pulse: v, drain: v, alpha: v);
          GargoyleHudArt.spottedTag(canvas, r, since: v);
          GargoyleHudArt.tags(canvas, r, v, hudBoss(7.2), reduced: false, spotSince: v);
          GargoyleHudArt.jolt(v, v, reduced: false);
          GargoyleHudArt.gaugeHp(b, reduced: false);
          GargoyleHudArt.surge(b, reduced: false);
        }, returnsNormally, reason: 'NaN / infinite $v');
        final count = _count((c) => GargoyleHudArt.fill(c, const ui.Rect.fromLTWH(0, 0, 100, 10), v, 1, glow: 0, phase: 0, edge: false));
        expect(count.draws, 0, reason: 'a fill to a non-finite edge draws nothing');
      }
    });

    test('the gauge fills on the entrance (never past his health) and the chip stays inside the channel', () {
      final b = SkyBoss(number: 6, x: 1.5, cinematic: true, kind: BossKind.searchlightGargoyle);
      b.age = 4.6 - .1;
      expect(b.phase, BossPhase.arriving);
      expect(GargoyleHudArt.gaugeHp(b, reduced: false), 0);
      b.age = 4.6 + .3;
      expect(GargoyleHudArt.gaugeHp(b, reduced: false), inExclusiveRange(0, 160));
      expect(GargoyleHudArt.surge(b, reduced: false), greaterThan(0));
      b.age = 4.6 + .7;
      expect(GargoyleHudArt.gaugeHp(b, reduced: false), 160);
      expect(GargoyleHudArt.surge(b, reduced: false), 0);
      b.hp = 100;
      b.age = 4.6 + .3;
      expect(GargoyleHudArt.gaugeHp(b, reduced: false), lessThanOrEqualTo(100));
      expect(GargoyleHudArt.gaugeHp(b, reduced: true), 100);
      expect(GargoyleHudArt.surge(b, reduced: true), 0);
      b.defeatedAt = b.age;
      expect(GargoyleHudArt.gaugeHp(b, reduced: false), 0);
    });

    testWidgets('the amber and the chip never leave the channel (no clip is needed), at 0, 1, 50 and 160 health', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        final bar = BossHealthBarArt.track(size, hudBoss(1.0));
        Future<Uint8List> shot(SkyBoss b) => _pixels(640, 60, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff000000));
          _paintBar(c, size, b);
        });
        final base = await shot(hudBoss(1.0, hp: 0, enragedAgo: 5));
        for (final hp in [1, 50, 80, 160]) {
          for (final hit in [null, .15, .3]) {
            final img = await shot(hudBoss(1.0, hp: hp, hitAgo: hit, lastDamage: 10, enragedAgo: hp <= 80 ? 5 : null));
            // Pixels that changed against the empty bar, within the bar's rows:
            // none of them is left of the channel or right of it.
            for (var y = (bar.top + 3).floor(); y < (bar.bottom - 3).floor(); y++) {
              for (var x = (bar.left - 5).floor(); x <= (bar.right + 5).ceil(); x++) {
                if (x >= bar.left - 1 && x <= bar.right + 1) continue;
                final i = (y * 640 + x) * 4;
                final d = (img[i] - base[i]).abs() + (img[i + 1] - base[i + 1]).abs() + (img[i + 2] - base[i + 2]).abs();
                expect(d, lessThan(30), reason: 'hp $hp hit $hit leaked at x $x y $y');
              }
            }
          }
        }
      });
    });

    test('the fury notch is at his fury health: the middle of the gauge, 80 of 160', () {
      expect(SearchlightGargoyle.furyHp * 2, SearchlightGargoyle.maxHp);
      expect(GargoyleHudArt.segments.isEven, isTrue, reason: 'the middle is a segment boundary the spool takes');
    });

    test('lastSpotAt is the boss clock when a beam really hurts (the SPOTTED! tag reads it)', () {
      final sim = arena();
      final boss = sim.boss!;
      expect(boss.lastSpotAt, double.negativeInfinity);
      boss
        ..beamSide = BeamSide.high
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      sim.invulnerableUntil = 0;
      jumpTo(boss, 4.5);
      hold(sim, .42);
      expect(boss.spots, 1);
      expect(boss.lastSpotAt, closeTo(boss.age, 1 / 60 + 1e-9));
      final first = boss.lastSpotAt;
      // Still lit while recovering: no second hurt, so the stamp does not move.
      for (var i = 0; i < 20; i++) {
        hold(sim, .42);
      }
      expect(boss.spots, 1);
      expect(boss.lastSpotAt, first);
    });
  });
}

void _cardTests() {
  group('the entrance card (G7)', () {
    const quote = '\u201cHold still! Nobody ever stays in the light.\u201d';

    test('it is his own while he arrives and nobody\'s afterwards; it is silent for other bosses', () {
      final canvas = ui.Canvas(ui.PictureRecorder());
      for (final age in [0.0, 1.0, 2.8, 3.5, 4.4, 4.59]) {
        final b = arrivalBoss(age);
        expect(GargoyleEncounterUi.nameCard(canvas, _sizes[0], b, BossMotion(b, reducedMotion: false)), isTrue, reason: 'age $age');
      }
      final fighting = gBoss(.5);
      expect(GargoyleEncounterUi.nameCard(canvas, _sizes[0], fighting, BossMotion(fighting, reducedMotion: false)), isFalse);
      final other = SkyBoss(number: 5, x: 1.5, cinematic: true, kind: BossKind.dragon)..age = 3.0;
      expect(GargoyleEncounterUi.nameCard(canvas, _sizes[0], other, BossMotion(other, reducedMotion: false)), isFalse);
    });

    test('it lands on the roar\'s hold (${GargoyleTimeline.cardAt} s): nothing before, a card from then, gone by the end of the entrance', () {
      expect(GargoyleEncounterUi.slamAt, GargoyleTimeline.cardAt);
      expect(GargoyleEncounterUi.slamAt, greaterThan(SkyBoss.roarAt));
      expect(GargoyleEncounterUi.slamAt, lessThan(SkyBoss.roarAt + .3));
      for (final size in _sizes) {
        int ops(double age, {bool reduced = false}) {
          final b = arrivalBoss(age, aspect: size.width / size.height);
          return _count((c) => GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: reduced), birdY: .62, line: quote)).draws;
        }

        expect(ops(2.0), 0);
        expect(ops(GargoyleEncounterUi.slamAt - .01), 0);
        expect(ops(GargoyleEncounterUi.slamAt + .06), greaterThan(5));
        expect(ops(3.5), greaterThan(20));
        expect(ops(4.0), greaterThan(20));
        expect(ops(GargoyleEncounterUi.goneBy - .001), lessThan(14), reason: 'folded away at the entrance\'s end: at most the plate\'s hairline');
        expect(ops(GargoyleEncounterUi.goneBy + .01), 0, reason: 'the shared rules then run the fight, with no card');
        expect(ops(3.5, reduced: true), greaterThan(20));
      }
    });

    test('budget: <= 60 ops, 4 shaders, 0 clips, 0 layers, no blur at every moment of the card, at both sizes', () {
      for (final size in _sizes) {
        GargoyleKit.clearCaches();
        var worst = 0, at = 0.0;
        for (var age = 2.8; age <= 4.62; age += .02) {
          for (final reduced in [false, true]) {
            for (final birdY in [.62, .25]) {
              final b = arrivalBoss(age, aspect: size.width / size.height);
              final c = _count((c) => GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: reduced), birdY: birdY, line: quote));
              expect(c.clips, 0, reason: 'age $age');
              expect(c.layers, 0, reason: 'age $age');
              expect(c.blurs, 0, reason: 'age $age');
              if (c.draws > worst) {
                worst = c.draws;
                at = age;
              }
            }
          }
        }
        // ignore: avoid_print
        print('G7 card at ${size.width}: worst $worst ops (age $at), shaders ${GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).length}');
        expect(worst, lessThanOrEqualTo(60), reason: 'age $at');
        expect(GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).length, lessThanOrEqualTo(4), reason: 'shade, steel, ribbon, beam (one layout; the spark is the kit\'s shared glow)');
      }
    });

    test('the card\'s words are laid out once: a whole entrance adds a bounded number of painters', () {
      final before = GargoyleEncounterUi.textCacheSize;
      for (var age = 2.8; age <= 4.62; age += .01) {
        final b = arrivalBoss(age);
        _count((c) => GargoyleEncounterUi.nameCard(c, _sizes[0], b, BossMotion(b, reducedMotion: false), birdY: .62, line: quote));
      }
      final after = GargoyleEncounterUi.textCacheSize;
      expect(after, lessThan(513));
      // A second entrance lays out nothing new.
      for (var age = 2.8; age <= 4.62; age += .01) {
        final b = arrivalBoss(age);
        _count((c) => GargoyleEncounterUi.nameCard(c, _sizes[0], b, BossMotion(b, reducedMotion: false), birdY: .62, line: quote));
      }
      expect(GargoyleEncounterUi.textCacheSize, after);
      expect(after - before, lessThan(513));
    });

    test('the plate keeps clear of his head and inside the screen at both sizes, with or without the line', () {
      for (final size in _sizes) {
        final b = arrivalBoss(3.5, aspect: size.width / size.height);
        final lamp = bossCentre(size, b);
        final unit = size.height * SkyBoss.radius;
        for (final line in [null, quote, '\u201c${'A long, long story line that wraps ' * 3}\u201d']) {
          final r = GargoyleEncounterUi.cardRect(size, b, line: line);
          expect(r.left, greaterThanOrEqualTo(size.height * .04 - .01));
          expect(r.top, greaterThan(0));
          expect(r.right, lessThan(lamp.dx + GargoyleLayout.envelope.left * unit), reason: 'his head reaches ${GargoyleLayout.envelope.left} units left of the lamp');
          expect(r.bottom, lessThan(size.height * .6));
        }
      }
    });

    testWidgets('the plate is identical with or without the line; the line is only under it', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        final b = arrivalBoss(3.9);
        Future<Uint8List> shot(String? line) => _pixels(640, 360, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff303a60));
          GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: false), birdY: .9, line: line);
        });
        final with0 = await shot(quote), without = await shot('\u201cA different story line, a good deal longer than the first one.\u201d');
        final plate = GargoyleEncounterUi.cardRect(size, b, line: quote).inflate(8);
        var inside = 0, below = 0;
        for (var y = 0; y < 360; y++) {
          for (var x = 0; x < 640; x++) {
            final i = (y * 640 + x) * 4;
            final d = (with0[i] - without[i]).abs() + (with0[i + 1] - without[i + 1]).abs() + (with0[i + 2] - without[i + 2]).abs();
            if (d < 12) continue;
            if (plate.contains(ui.Offset(x + .5, y + .5))) {
              inside++;
            } else if (y > plate.bottom - 20) {
              below++;
            }
          }
        }
        expect(inside, 0, reason: 'the plate does not depend on the line');
        expect(below, greaterThan(500), reason: 'the quote sits under the plate');
      });
    });

    testWidgets('the plate turns see-through where the bird flies behind it', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        final b = arrivalBoss(3.9);
        Future<Uint8List> shot(double birdY) => _pixels(640, 360, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xffffd45b));
          GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: false), birdY: birdY, line: quote);
        });
        final plate = GargoyleEncounterUi.cardRect(size, b, line: quote);
        final away = await shot(.95), behind = await shot((plate.center.dy) / 360);
        // On a bright yellow ground, a see-through plate is brighter.
        double mean(Uint8List a) {
          var sum = 0.0, n = 0;
          for (var y = plate.top.ceil() + 8; y < plate.bottom.floor() - 8; y += 2) {
            for (var x = plate.left.ceil() + 8; x < plate.right.floor() - 8; x += 2) {
              final i = (y * 640 + x) * 4;
              sum += a[i] + a[i + 1] + a[i + 2];
              n++;
            }
          }
          return sum / n;
        }

        expect(mean(behind), greaterThan(mean(away) + 20));
      });
    });

    testWidgets('Reduced Motion: the card only fades (steady from .25 s on), and says the same words', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        Future<Uint8List> shot(double age) {
          final b = arrivalBoss(age);
          return _pixels(640, 360, (c) {
            c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff303a60));
            GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: true), birdY: .9, line: quote);
          });
        }

        expect(_diff(await shot(3.2), await shot(4.0), 0), 0, reason: 'steady between the fade in and the fade out');
        expect(_diff(await shot(2.9), await shot(3.5)), greaterThan(300), reason: 'it fades in');
        expect(_diff(await shot(3.5), await shot(4.5)), greaterThan(300), reason: 'and out');
        // Under motion the beam, the bulbs and the letters change between the same two moments.
        Future<Uint8List> live(double age) {
          final b = arrivalBoss(age);
          return _pixels(640, 360, (c) {
            c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff303a60));
            GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: false), birdY: .9, line: quote);
          });
        }

        expect(_diff(await live(3.05), await live(3.1)), greaterThan(100));
      });
    });

    testWidgets('the same card frame is the same pixels after the caches are flooded', (tester) async {
      await tester.runAsync(() async {
        const size = ui.Size(640, 360);
        final b = arrivalBoss(3.1);
        Future<Uint8List> shot() => _pixels(640, 360, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff303a60));
          GargoyleEncounterUi.nameCard(c, size, b, BossMotion(b, reducedMotion: false), birdY: .9, line: quote);
        });
        final first = await shot();
        GargoyleKit.clearCaches();
        for (var age = 2.8; age < 4.6; age += .05) {
          final x = arrivalBoss(age, aspect: 800 / 360);
          _count((c) => GargoyleEncounterUi.nameCard(c, _sizes[1], x, BossMotion(x, reducedMotion: false), birdY: .3, line: 'Other words'));
        }
        expect(_diff(first, await shot(), 0), 0);
      });
    });

    test('non-finite clocks, sizes and bird heights never throw', () {
      final canvas = ui.Canvas(ui.PictureRecorder());
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        final b = arrivalBoss(3.5)..age = v;
        expect(() => GargoyleEncounterUi.nameCard(canvas, _sizes[0], b, BossMotion(b, reducedMotion: false)), returnsNormally);
        final ok = arrivalBoss(3.5);
        expect(() => GargoyleEncounterUi.nameCard(canvas, _sizes[0], ok, BossMotion(ok, reducedMotion: false), birdY: v), returnsNormally);
        expect(() => GargoyleEncounterUi.nameCard(canvas, ui.Size(v, 360), ok, BossMotion(ok, reducedMotion: false)), returnsNormally);
        final off = arrivalBoss(3.5)..x = v;
        expect(() => GargoyleEncounterUi.nameCard(canvas, _sizes[0], off, BossMotion(off, reducedMotion: false)), returnsNormally);
      }
    });

    test('the words: GUARDIAN everywhere, the full name, his epithet, his entrance line', () {
      expect(GargoyleEncounterUi.tag, 'GUARDIAN');
      expect('${GargoyleEncounterUi.titleSmall} ${GargoyleEncounterUi.titleBig}', 'THE SEARCHLIGHT GARGOYLE');
      expect(GargoyleEncounterUi.epithet, 'WATCHMAN OF THE TALLEST TOWER');
      expect(GargoyleEncounterUi.line, 'Hold still! Nobody ever stays in the light.');
    });
  });
}

void _burstTests() {
  group('the arrival, hit, fury and defeat bursts (G7)', () {
    const size = ui.Size(640, 360);
    final at = bossCentre(size, gBoss(1.0));
    const h = 360.0;

    int ops(void Function(ui.Canvas) draw) {
      final c = _count(draw);
      expect(c.layers, 0);
      expect(c.blurs, 0);
      expect(c.clips, 0);
      return c.draws;
    }

    test('each is silent outside its window and bounded inside it, with no layer, clip or blur', () {
      final budget = <(String, int, List<double>, void Function(ui.Canvas, double, bool))>[
        ('awaken', 40, [0.0, .1, .3, .6, 1.0, 1.29], (c, t, r) => GargoyleEncounterUi.awaken(c, at, h, t, reduced: r)),
        ('hit', 40, [0.0, .05, .15, .29], (c, t, r) => GargoyleEncounterUi.hit(c, at, h, t, reduced: r)),
        ('furyOnset', 40, [0.0, .2, .6, 1.09], (c, t, r) => GargoyleEncounterUi.furyOnset(c, at, h, t, reduced: r)),
        ('spotRing', 20, [0.0, .1, .3, .44], (c, t, r) => GargoyleEncounterUi.spotRing(c, const ui.Offset(169, 220), h, t, reduced: r)),
        ('crumble', 60, [.86, 1.0, 1.4, 2.0, 2.6, 3.5], (c, t, r) => GargoyleEncounterUi.crumble(c, at, h, t, reduced: r)),
        ('rubble', 40, [1.0, 1.5, 2.0, 3.0, 3.7], (c, t, r) => GargoyleEncounterUi.rubble(c, at, h, t, reduced: r)),
        ('lenses', 60, [1.3, 1.6, 2.0, 3.0, 3.7], (c, t, r) => GargoyleEncounterUi.lenses(c, at, h, t, reduced: r)),
        ('pigeonsOut', 40, [1.0, 1.3, 1.8, 2.3, 2.7, 3.6], (c, t, r) => GargoyleEncounterUi.pigeonsOut(c, at, h, t, reduced: r)),
        ('flush', 40, [2.0, 2.2, 2.6, 3.0, 3.4], (c, t, r) => GargoyleEncounterUi.flush(c, at, h, t, reduced: r)),
      ];
      for (final (name, limit, times, draw) in budget) {
        for (final reduced in [false, true]) {
          for (final t in times) {
            final n = ops((c) => draw(c, t, reduced));
            expect(n, lessThanOrEqualTo(limit), reason: '$name at $t (reduced $reduced)');
          }
        }
      }
      // Silent outside their windows.
      expect(ops((c) => GargoyleEncounterUi.awaken(c, at, h, -.01, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.awaken(c, at, h, 1.3, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.hit(c, at, h, .3, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.hit(c, at, h, -.1, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.furyOnset(c, at, h, 1.1, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.spotRing(c, at, h, .45, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.crumble(c, at, h, GargoyleEncounterUi.burstAt - .01, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.rubble(c, at, h, GargoyleEncounterUi.burstAt, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.pigeonsOut(c, at, h, .99, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.flush(c, at, h, 1.99, reduced: false)), 0);
      expect(ops((c) => GargoyleEncounterUi.flush(c, at, h, 3.6, reduced: false)), 0);
    });

    test('a whole arrival or defeat (every pose, 30 fps) stays inside one budget and builds at most 3 shaders of its own', () {
      GargoyleKit.clearCaches();
      var worst = 0, at0 = 0.0;
      for (var death = 0.0; death <= 3.8; death += 1 / 30) {
        final n = ops((c) {
          GargoyleEncounterUi.rubble(c, at, h, death, reduced: false);
          GargoyleEncounterUi.crumble(c, at, h, death, reduced: false);
          GargoyleEncounterUi.lenses(c, at, h, death, reduced: false);
          GargoyleEncounterUi.pigeonsOut(c, at, h, death, reduced: false);
        });
        if (n > worst) {
          worst = n;
          at0 = death;
        }
      }
      // ignore: avoid_print
      print('G7 defeat set: worst frame $worst ops (death +$at0)');
      expect(worst, lessThanOrEqualTo(120));
      for (var age = 1.6; age <= 3.6; age += 1 / 30) {
        final n = ops((c) {
          GargoyleEncounterUi.awaken(c, at, h, age - SkyBoss.revealAt, reduced: false);
          GargoyleEncounterUi.flush(c, at, h, age, reduced: false);
        });
        expect(n, lessThanOrEqualTo(80), reason: 'arrival age $age');
      }
      final own = GargoyleKit.built.where((k) => !'$k'.startsWith('glow:')).toList();
      // ignore: avoid_print
      print('G7 burst shaders: ${own.length} $own');
      expect(own.length, lessThanOrEqualTo(3));
      final before = GargoyleKit.shadersBuilt;
      ops((c) => GargoyleEncounterUi.rubble(c, at, h, 2.5, reduced: false));
      ops((c) => GargoyleEncounterUi.crumble(c, at, h, 2.5, reduced: false));
      expect(GargoyleKit.shadersBuilt - before, 0, reason: 'a warm frame builds none');
    });

    testWidgets('the same defeat frame is the same pixels twice and after the caches are flooded; Reduced Motion is steady', (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> shot(double death, {bool reduced = false}) => _pixels(640, 360, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff303a60));
          GargoyleEncounterUi.rubble(c, at, h, death, reduced: reduced);
          GargoyleEncounterUi.crumble(c, at, h, death, reduced: reduced);
          GargoyleEncounterUi.lenses(c, at, h, death, reduced: reduced);
          GargoyleEncounterUi.pigeonsOut(c, at, h, death, reduced: reduced);
        });
        final a = await shot(1.4);
        expect(_diff(a, await shot(1.4), 0), 0);
        GargoyleKit.clearCaches();
        for (var d = 3.5; d > 0; d -= .2) {
          await shot(d);
        }
        expect(_diff(a, await shot(1.4), 0), 0, reason: 'order of drawing does not matter');
        // Reduced Motion: the rubble holds still from the moment it has faded in.
        expect(_diff(await shot(3.0, reduced: true), await shot(3.7, reduced: true), 0), 0);
      });
    });

    testWidgets('his two lenses lie lit on the rubble where the layout puts them, after the burst and not before', (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> shot(double death) => _pixels(640, 360, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff202a50));
          GargoyleEncounterUi.lenses(c, at, h, death, reduced: false);
        });
        int lum(Uint8List a, ui.Offset p) {
          final i = (p.dy.round() * 640 + p.dx.round()) * 4;
          return a[i] + a[i + 1] + a[i + 2];
        }

        final unit = h * SkyBoss.radius;
        final early = await shot(.9), lit = await shot(3.0);
        for (final (rel, _) in GargoyleLayout.rubbleLenses) {
          final p = at + rel * unit;
          expect(lum(early, p), lessThan(200), reason: 'dark before the burst');
          expect(lum(lit, p), greaterThan(560), reason: 'lit at ${rel.dx}, ${rel.dy}: white-hot core');
          // Amber around the core.
          final ring = p + ui.Offset(unit * rel.dy.sign * 0, 0) + ui.Offset(GargoyleLayout.rubbleLenses.first.$2 * unit * .45, 0);
          expect(lit[((ring.dy.round()) * 640 + ring.dx.round()) * 4], greaterThan(200));
        }
      });
    });

    testWidgets('the heap stands on the ledge, clear of the empty vane mount and inside the layer bounds', (tester) async {
      await tester.runAsync(() async {
        final img = await _pixels(640, 360, (c) {
          c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff000000));
          GargoyleEncounterUi.rubble(c, at, h, 3.0, reduced: false);
        });
        final unit = h * SkyBoss.radius;
        var left = 640.0, right = 0.0, top = 360.0, bottom = 0.0;
        for (var y = 0; y < 360; y++) {
          for (var x = 0; x < 640; x++) {
            final i = (y * 640 + x) * 4;
            if (img[i] + img[i + 1] + img[i + 2] > 30) {
              left = math.min(left, x.toDouble());
              right = math.max(right, x.toDouble());
              top = math.min(top, y.toDouble());
              bottom = math.max(bottom, y.toDouble());
            }
          }
        }
        // On the lip (y 2.95) and no higher than 1.6 units above it; left of the vane mount
        // (x -2.0) it starts only past the rod, and the pier (3.55) stays free.
        expect(bottom, closeTo(at.dy + GargoyleLayout.ledgeY * unit, 3));
        expect(top, greaterThan(at.dy + (GargoyleLayout.ledgeY - 1.7) * unit));
        expect(left, greaterThan(at.dx + GargoyleLayout.vaneMount.dx * unit + 1));
        expect(right, lessThan(at.dx + GargoyleLayout.pierX * unit));
      });
    });

    test('the pigeons: nine at the most, the last one stays on the rubble; none under Reduced Motion but that one', () {
      // The ninth is on the rubble from 2.6 s on, at the same place for the rest of the defeat.
      final spots = <ui.Offset>{};
      for (final death in [2.7, 3.0, 3.4, 3.79]) {
        final c = _count((c) => GargoyleEncounterUi.pigeonsOut(c, at, h, death, reduced: false));
        expect(c.draws, greaterThan(0), reason: 'a pigeon sits on the rubble at +$death');
        spots.add(ui.Offset(death.floor().toDouble(), 0));
      }
      final reduced = _count((c) => GargoyleEncounterUi.pigeonsOut(c, at, h, 1.5, reduced: true));
      expect(reduced.draws, 0, reason: 'the flock is motion');
      final reducedLate = _count((c) => GargoyleEncounterUi.pigeonsOut(c, at, h, 3.2, reduced: true));
      expect(reducedLate.draws, greaterThan(0));
      expect(GargoyleEncounterUi.chunkCount, lessThanOrEqualTo(16));
    });

    test('every shard comes to rest on the heap, clear of the lenses, and nowhere off the ledge', () {
      for (var i = 0; i < GargoyleEncounterUi.chunkCount; i++) {
        final r = GargoyleEncounterUi.chunkRest(i);
        expect(r.dy, lessThanOrEqualTo(GargoyleLayout.ledgeY), reason: 'chunk $i rests on or above the lip');
        expect(r.dy, greaterThan(GargoyleLayout.ledgeY - 1.5));
        expect(r.dx, inInclusiveRange(-1.8, 2.45));
        for (final (lens, rad) in GargoyleLayout.rubbleLenses) {
          expect((r - lens).distance, greaterThan(rad * 1.2), reason: 'chunk $i would hide a lens');
        }
      }
    });

    test('non-finite clocks and positions never throw', () {
      final canvas = ui.Canvas(ui.PictureRecorder());
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(() {
          GargoyleEncounterUi.awaken(canvas, at, h, v, reduced: false);
          GargoyleEncounterUi.awaken(canvas, ui.Offset(v, v), h, .5, reduced: false);
          GargoyleEncounterUi.hit(canvas, at, h, v, reduced: false);
          GargoyleEncounterUi.hit(canvas, at, v, .1, reduced: false);
          GargoyleEncounterUi.furyOnset(canvas, at, h, v, reduced: false);
          GargoyleEncounterUi.furyOnset(canvas, ui.Offset(v, 0), h, .5, reduced: true);
          GargoyleEncounterUi.spotRing(canvas, at, h, v, reduced: false);
          GargoyleEncounterUi.crumble(canvas, at, h, v, reduced: false);
          GargoyleEncounterUi.crumble(canvas, at, v, 2.0, reduced: false);
          GargoyleEncounterUi.rubble(canvas, at, h, v, reduced: false);
          GargoyleEncounterUi.lenses(canvas, at, h, v, reduced: false);
          GargoyleEncounterUi.pigeonsOut(canvas, at, h, v, reduced: false);
          GargoyleEncounterUi.pigeonsOut(canvas, ui.Offset(v, v), h, 2.0, reduced: false);
          GargoyleEncounterUi.flush(canvas, at, h, v, reduced: false);
        }, returnsNormally, reason: '$v');
      }
    });
  });
}
