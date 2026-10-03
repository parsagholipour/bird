// Visual review frames for Neferhoo's presentation (A2), rendered through the
// game's own painters: the arrival and the defeat in a real BirdGame (level
// 2-6) at 640, 800 and 864 x 360, day and the design's dusk, Reduced Motion;
// the strip and the stage HUD in the fight; the name and victory cards; the
// story poses on the real story stage; the keepsake stamp, the map's guardian
// shield and the route mark. Only runs with --dart-define=A2_REVIEW=<name>
// (images in build/neferhoo-review/<name>/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/neferhoo_encounter_ui.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/campaign_map_art.dart';
import 'package:push_up_bird/ui/story_backdrop.dart';
import 'package:push_up_bird/ui/story_cast_art.dart';
import 'package:push_up_bird/ui/story_speech.dart';
import 'package:push_up_bird/ui/story_stage.dart';

import 'neferhoo_stage_support.dart';

const _iter = String.fromEnvironment('A2_REVIEW');
final _out = Directory('build/neferhoo-review/$_iter');

const _arrivalTimes = [.25, .55, .9, 1.2, 1.5, 1.75, 2.0, 2.3, 2.75, 3.1, 3.6, 4.1];
const _defeatTimes = [.05, .4, .7, .9, 1.1, 1.4, 1.7, 2.1, 2.5, 3.0, 3.4, 3.7];

Future<List<(String, ui.Image)>> _arrival(WidgetTester tester, double w, {bool dusk = false, bool reduced = false, List<double> times = _arrivalTimes}) async {
  final s = await neferhooStage(tester, w, reduced: reduced);
  final frames = <(String, ui.Image)>[];
  for (final t in times) {
    s.runTo(t);
    frames.add(('arrival t=${t.toStringAsFixed(2)}${reduced ? ' RM' : ''}', await s.render(dusk: dusk)));
  }
  return frames;
}

Future<List<(String, ui.Image)>> _defeat(WidgetTester tester, double w, {bool dusk = false, bool reduced = false, List<double> times = _defeatTimes}) async {
  final s = await neferhooStage(tester, w, reduced: reduced);
  s.fightTo(1.0);
  s.strike();
  final frames = <(String, ui.Image)>[];
  for (final d in times) {
    s.deathTo(d);
    frames.add(('defeat d=${d.toStringAsFixed(2)}${reduced ? ' RM' : ''}', await s.render(dusk: dusk)));
  }
  return frames;
}

/// The story stage at a lair (the design's harness, with the real cast:
/// Bill, the courier, and Neferhoo through `StoryBoss`).
Widget _scene(Size size, StoryMood mood, {required bool beaten, required bool speaking, String text = ''}) {
  final layout = StoryLayout(size, EdgeInsets.zero, lair: true);
  StoryFace face(StoryMood m, bool talk) => (mood: m, mouth: talk ? 1 : 0, blink: false);
  final cast = <StoryPlacement>[
    (actor: const StoryPostmaster(), x: layout.postmaster, voice: 0.0, presence: 1.0, face: face(StoryMood.plain, false), lift: 0.0, squash: 1.0),
    (actor: const StoryCourier(0), x: layout.courier, voice: 0.0, presence: 1.0, face: face(StoryMood.plain, false), lift: 0.0, squash: 1.0),
    (
      actor: StoryBoss(BossKind.neferhoo, beaten: beaten),
      x: layout.boss,
      voice: speaking ? 1.0 : 0.0,
      presence: 1.0,
      face: face(mood, speaking),
      lift: 0.0,
      squash: 1.0,
    ),
  ];
  return SizedBox(
    width: size.width,
    height: size.height,
    child: Stack(
      children: [
        Positioned.fill(child: StoryBackdrop(region: WorldRegion.egypt, floor: layout.floor)),
        Positioned.fill(child: CustomPaint(painter: StoryStagePainter(cast: cast, floor: layout.floor))),
        Positioned.fromRect(
          rect: layout.panel,
          child: StorySpeech(
            text: text,
            voice: StoryVoice.of(speaking ? 'Neferhoo' : 'Pip', text),
            label: text,
            write: const AlwaysStoppedAnimation(1),
            step: 1,
            of: 9,
          ),
        ),
      ],
    ),
  );
}

Future<ui.Image> _grab(WidgetTester tester, Widget child, Size size) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(child: Center(child: RepaintBoundary(key: key, child: SizedBox.fromSize(size: size, child: child)))),
      ),
    ),
  );
  await tester.pump();
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() => boundary.toImage()))!;
}

Future<ui.Image> _paint(double w, double h, void Function(Canvas c) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  picture.dispose();
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final skip = _iter.isEmpty ? 'review frames: run with --dart-define=A2_REVIEW=<name>' : null;
  setUpAll(loadFonts);

  for (final w in const [640.0, 800.0, 864.0]) {
    testWidgets('arrival $w', (tester) async => tester.runAsync(() async {
      final frames = await _arrival(tester, w);
      await sheet(_out, 'arrival-${w.toInt()}', frames, cols: 4, scale: 640 / w);
      disposeAll(frames);
    }), skip: skip != null, timeout: const Timeout(Duration(minutes: 10)));
    testWidgets('defeat $w', (tester) async => tester.runAsync(() async {
      final frames = await _defeat(tester, w);
      await sheet(_out, 'defeat-${w.toInt()}', frames, cols: 4, scale: 640 / w);
      disposeAll(frames);
    }), skip: skip != null, timeout: const Timeout(Duration(minutes: 10)));
  }

  testWidgets('the hand-over: the arrival\'s last frames into the fight, the fight into the killing blow', (tester) async => tester.runAsync(() async {
    for (final w in const [640.0, 864.0]) {
      final s = await neferhooStage(tester, w);
      final crops = <(String, ui.Image)>[];
      Future<void> shot(String label) async {
        final full = await s.render();
        final at = ui.Offset(s.boss.x * 360, s.boss.y * 360);
        crops.add((
          label,
          await _paint(440, 340, (c) {
            c.drawImageRect(full, Rect.fromCenter(center: at + const Offset(10, -30), width: 220, height: 170), const Rect.fromLTWH(0, 0, 440, 340), Paint()..filterQuality = FilterQuality.medium);
          }),
        ));
        full.dispose();
      }

      for (final t in const [4.40, 4.50, 4.567, 4.583, 4.60, 4.617, 4.65, 4.75]) {
        s.runTo(t);
        await shot('age ${t.toStringAsFixed(3)}');
      }
      s.fightTo(2.0);
      await shot('fight 2.0');
      s.strike();
      for (final d in const [0.0, .05, .15]) {
        s.deathTo(d);
        await shot('death ${d.toStringAsFixed(2)}');
      }
      await sheet(_out, 'handover-${w.toInt()}', crops, cols: 4, scale: .75);
      disposeAll(crops);
    }
  }), skip: skip != null, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('dusk and reduced motion at 640', (tester) async => tester.runAsync(() async {
    final a = await _arrival(tester, 640, dusk: true, times: const [.9, 1.5, 2.0, 2.75, 3.1, 4.1]);
    await sheet(_out, 'arrival-dusk-640', a, cols: 3);
    disposeAll(a);
    final d = await _defeat(tester, 640, dusk: true, times: const [.4, .9, 1.4, 2.1, 2.5, 3.4]);
    await sheet(_out, 'defeat-dusk-640', d, cols: 3);
    disposeAll(d);
    final ra = await _arrival(tester, 640, reduced: true, times: const [.9, 1.5, 2.0, 2.75, 3.1, 4.1]);
    await sheet(_out, 'arrival-rm-640', ra, cols: 3);
    disposeAll(ra);
    final rd = await _defeat(tester, 640, reduced: true, times: const [.4, .9, 1.4, 2.1, 2.5, 3.4]);
    await sheet(_out, 'defeat-rm-640', rd, cols: 3);
    disposeAll(rd);
  }), skip: skip != null, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('the fight: strip, stage gem, STRONGER!, fury seal', (tester) async => tester.runAsync(() async {
    final frames = <(String, ui.Image)>[];
    for (final w in const [640.0, 800.0, 864.0]) {
      final s = await neferhooStage(tester, w);
      s.fightTo(1.0);
      frames.add(('fight calm $w', await s.render()));
      // Into the full fight: the gem snaps, STRONGER! drops.
      s.boss.hp = s.boss.maxHp * 2 ~/ 3 + 1;
      s.sim.rocks.add(BirdRock(x: s.boss.x - .12, y: s.boss.y));
      for (var i = 0; i < 40; i++) {
        s.tick();
      }
      frames.add(('stronger $w', await s.render()));
      // Fury: the seal cracks.
      s.boss.hp = s.boss.maxHp ~/ 3 + 1;
      s.sim.rocks.add(BirdRock(x: s.boss.x - .12, y: s.boss.y));
      for (var i = 0; i < 90; i++) {
        s.tick();
      }
      frames.add(('fury $w', await s.render()));
      frames.add(('fury dusk $w', await s.render(dusk: true)));
    }
    await sheet(_out, 'fight-hud', frames, cols: 4, scale: .75);
    // The strip close-up, 3x, calm / stronger / fury (640).
    final crops = <(String, ui.Image)>[];
    for (final (label, image) in frames.where((f) => f.$1.contains('640'))) {
      crops.add((
        label,
        await _paint(1380, 120, (c) {
          c.scale(3);
          c.drawImageRect(image, const Rect.fromLTWH(85, 0, 460, 40), const Rect.fromLTWH(0, 0, 460, 40), Paint()..filterQuality = FilterQuality.none);
        }),
      ));
    }
    await sheet(_out, 'hud-3x', crops, cols: 1);
    disposeAll(frames);
    disposeAll(crops);
  }), skip: skip != null, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('the cards, close', (tester) async => tester.runAsync(() async {
    final frames = <(String, ui.Image)>[];
    for (final w in const [640.0, 800.0, 864.0]) {
      for (final campaign in const [true, false]) {
        frames.add((
          'card $w ${campaign ? 'campaign' : 'no level'}',
          await _paint(w, 360, (c) {
            c.drawRect(Rect.fromLTWH(0, 0, w, 360), Paint()..color = const Color(0xff7fa9c8));
            NeferhooEncounterUi.paintCard(
              c,
              Size(w, 360),
              ribbon: NeferhooEncounterUi.ribbon(campaign: campaign),
              line: campaign ? NeferhooEncounterUi.line : null,
            );
            NeferhooEncounterUi.paintVictory(c, Size(w, 360));
          }),
        ));
      }
    }
    await sheet(_out, 'cards', frames, cols: 2, scale: .75);
    disposeAll(frames);
  }), skip: skip != null, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('story poses on the real stage', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    for (final w in const [800.0, 640.0]) {
      final size = Size(w, 360);
      final frames = <(String, ui.Image)>[];
      for (final beaten in const [false, true]) {
        for (final mood in StoryMood.values) {
          frames.add((
            '${mood.name}${beaten ? ' beaten' : ''}',
            await _grab(tester, _scene(size, mood, beaten: beaten, speaking: true, text: 'Neferhoo, ${mood.name}${beaten ? ', beaten' : ''}.'), size),
          ));
        }
      }
      frames.add(('listening plain', await _grab(tester, _scene(size, StoryMood.plain, beaten: false, speaking: false, text: 'Bill speaks.'), size)));
      frames.add(('listening beaten', await _grab(tester, _scene(size, StoryMood.plain, beaten: true, speaking: false, text: 'Bill speaks.'), size)));
      await tester.runAsync(() => sheet(_out, 'story-${w.toInt()}', frames, cols: 4, scale: .6));
      disposeAll(frames);
    }
  }, skip: skip != null);

  testWidgets('keepsake, map shield, route mark', (tester) async => tester.runAsync(() async {
    final image = await _paint(900, 330, (c) {
      c.drawRect(const Rect.fromLTWH(0, 0, 900, 330), Paint()..color = const Color(0xffa8cbe0));
      var x = 20.0;
      for (final s in const [96.0, 72.0, 48.0]) {
        c.save();
        c.translate(x, 20);
        CampaignStampPainter(BossKind.neferhoo, chapter: 2).paint(c, Size(s, s * 1.2));
        c.restore();
        x += s + 20;
      }
      for (final s in const [72.0, 40.0, 30.0, 24.0]) {
        final box = Rect.fromLTWH(x, 40, s, s * .75);
        c.drawRect(box, Paint()..color = CampaignHeadwear.field(BossKind.neferhoo));
        CampaignHeadwear.paint(c, box, BossKind.neferhoo);
        x += s + 16;
      }
      var mx = 30.0;
      for (final look in MapNodeLook.values) {
        for (final r in const [22.0, 30.0]) {
          c.save();
          c.translate(mx, 190);
          MapGuardianPainter(look: look, radius: r, boss: BossKind.neferhoo).paint(c, Size(r * 2.4, r * 2.6));
          c.restore();
          mx += r * 2.4 + 14;
        }
      }
      // The King Coo and Gargoyle shields beside his, for the family.
      for (final kind in const [BossKind.kingCoo, BossKind.searchlightGargoyle, BossKind.neferhoo]) {
        c.save();
        c.translate(mx, 190);
        MapGuardianPainter(look: MapNodeLook.open, radius: 30, boss: kind).paint(c, const Size(72, 78));
        c.restore();
        mx += 86;
      }
    });
    await sheet(_out, 'keepsake-map', [('keepsake / headwear / map shields', image)], cols: 1);
    // The real strip at 640 in calm, for the medallion at its size.
    final boss = SkyBoss(number: 9, x: 1.3, kind: BossKind.neferhoo, cinematic: true, staged: true)..age = 6;
    final strip = await _paint(640, 60, (c) {
      c.drawRect(const Rect.fromLTWH(0, 0, 640, 60), Paint()..color = const Color(0xff7fa9c8));
      BossHealthBarArt.paint(c, const Size(640, 360), boss);
    });
    await sheet(_out, 'strip-640', [('strip 640', strip)], cols: 1, scale: 2);
    expect(BossEncounterArt.nameCardEyebrow(boss), 'GUARDIAN');
  }), skip: skip != null, timeout: const Timeout(Duration(minutes: 10)));
}
