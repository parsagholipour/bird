import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign_story.dart' show StoryMood;
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/king_coo_story_art.dart';
import 'package:push_up_bird/ui/story_boss_art.dart';

import 'king_coo_test_kit.dart';

/// King Coo in the story scenes (K8): the six portraits (the five moods and
/// the beaten king), fitted to the stage by `StoryBossArt.portrait`, painted by
/// the real rig through `KingCooStoryArt`.

const _w = 480, _h = 380;

/// A portrait of [mood] on a 360-high stage: the floor at y 330.
Future<Uint8List> portrait(
  StoryMood mood, {
  bool beaten = false,
  double talk = 0,
  double blink = 0,
  Color backdrop = const Color(0xff2a2f55),
}) => rawPixels(_w, _h, (c) {
  c.drawRect(
    const Rect.fromLTWH(0, 0, 480, 380),
    Paint()..color = backdrop,
  );
  final (:unit, :origin, reach: _) = StoryBossArt.portrait(
    BossKind.kingCoo,
    beaten: beaten,
  );
  c.translate(_w / 2 + origin.dx, 330 + origin.dy);
  c.scale(unit);
  StoryBossArt.paint(
    c,
    BossKind.kingCoo,
    mood,
    beaten: beaten,
    talk: talk,
    blink: blink,
  );
});

/// The solid pixels' bounds in stage pixels (alpha against the backdrop is
/// not available: a transparent render is used).
Future<Rect> bounds(
  StoryMood mood, {
  bool beaten = false,
  double talk = 0,
  double blink = 0,
}) async {
  final data = await rawPixels(_w, _h, (c) {
    final (:unit, :origin, reach: _) = StoryBossArt.portrait(
      BossKind.kingCoo,
      beaten: beaten,
    );
    c.translate(_w / 2 + origin.dx, 330 + origin.dy);
    c.scale(unit);
    StoryBossArt.paint(
      c,
      BossKind.kingCoo,
      mood,
      beaten: beaten,
      talk: talk,
      blink: blink,
    );
  });
  var l = _w, t = _h, r = -1, b = -1;
  for (var y = 0; y < _h; y++) {
    for (var x = 0; x < _w; x++) {
      if (data[(y * _w + x) * 4 + 3] > 40) {
        if (x < l) l = x;
        if (x > r) r = x;
        if (y < t) t = y;
        if (y > b) b = y;
      }
    }
  }
  return Rect.fromLTRB(l.toDouble(), t.toDouble(), r + 1.0, b + 1.0);
}

int differing(Uint8List a, Uint8List b) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if ((a[i] - b[i]).abs() + (a[i + 1] - b[i + 1]).abs() + (a[i + 2] - b[i + 2]).abs() > 40) n++;
  }
  return n;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final scenes = <(String, StoryMood, bool)>[
    ('plain', StoryMood.plain, false),
    ('happy', StoryMood.happy, false),
    ('surprised', StoryMood.surprised, false),
    ('angry', StoryMood.angry, false),
    ('sad', StoryMood.sad, false),
    ('beaten', StoryMood.plain, true),
  ];

  testWidgets('the six portraits render and are all different', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final shots = <String, Uint8List>{};
      for (final (name, mood, beaten) in scenes) {
        shots[name] = await portrait(mood, beaten: beaten);
      }
      for (final a in shots.keys) {
        for (final b in shots.keys) {
          if (a.compareTo(b) >= 0) continue;
          expect(
            differing(shots[a]!, shots[b]!),
            greaterThan(1500),
            reason: '$a and $b must read differently',
          );
        }
      }
      // The review sheet: three across, two rows, on the stage's dusk and on
      // a bright wall.
      for (final (suffix, backdrop) in [
        ('dusk', const Color(0xff2a2f55)),
        ('bright', const Color(0xfff2e6c9)),
      ]) {
        final img = await render(_w * 3, (_h + 18) * 2, (c) {
          for (var i = 0; i < scenes.length; i++) {
            final (name, mood, beaten) = scenes[i];
            c.save();
            c.translate((i % 3) * _w * 1.0, (i ~/ 3) * (_h + 18.0));
            c.clipRect(const Rect.fromLTWH(0, 0, 480, 398));
            c.drawRect(
              const Rect.fromLTWH(0, 0, 480, 398),
              Paint()..color = backdrop,
            );
            label(c, name, const Offset(8, 2), size: 13);
            c.translate(0, 18);
            final (:unit, :origin, reach: _) = StoryBossArt.portrait(
              BossKind.kingCoo,
              beaten: beaten,
            );
            c.translate(_w / 2 + origin.dx, 330 + origin.dy);
            c.scale(unit);
            StoryBossArt.paint(c, BossKind.kingCoo, mood, beaten: beaten, talk: mood == StoryMood.happy ? .3 : 0);
            c.restore();
          }
        });
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$reviewDir/story-portraits-$suffix.png')
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
        img.dispose();
      }
    });
  });

  testWidgets('every portrait stays inside the reach box the stage fits', (tester) async {
    await tester.runAsync(() async {
      for (final (name, mood, beaten) in scenes) {
        for (final (talk, blink) in [(0.0, 0.0), (1.0, 1.0)]) {
          final (:unit, :origin, :reach) = StoryBossArt.portrait(
            BossKind.kingCoo,
            beaten: beaten,
          );
          final box = Rect.fromLTRB(
            _w / 2 + origin.dx + reach.left * unit,
            330 + origin.dy + reach.top * unit,
            _w / 2 + origin.dx + reach.right * unit,
            330 + origin.dy + reach.bottom * unit,
          );
          final r = await bounds(mood, beaten: beaten, talk: talk, blink: blink);
          expect(box.inflate(1).contains(r.topLeft) && box.inflate(1).contains(r.bottomRight), isTrue,
              reason: '$name talk $talk: $r is outside the reach $box');
          // On the stage: feet near the floor line, nothing above the top of a
          // 360-high stage's panel.
          expect(r.top, greaterThan(20), reason: '$name: the cap clears the top');
          expect(r.bottom, lessThan(350), reason: '$name: the feet sink only a little below the floor');
        }
      }
    });
  });

  testWidgets('the props: a bagel in the happy pose, a pretzel when beaten', (tester) async {
    await tester.runAsync(() async {
      // With and without the prop the happy pose differs only at the hand.
      final withBagel = await portrait(StoryMood.happy);
      final pose = KingCooPose.story(KingCooMood.happy);
      expect(pose.wingNear, greaterThan(2.0), reason: 'the wing is out for the bagel');
      final plain = await rawPixels(_w, _h, (c) {
        c.drawRect(const Rect.fromLTWH(0, 0, 480, 380), Paint()..color = const Color(0xff2a2f55));
        final (:unit, :origin, reach: _) = StoryBossArt.portrait(BossKind.kingCoo);
        c.translate(_w / 2 + origin.dx, 330 + origin.dy);
        c.scale(unit);
        // The rig alone, no props.
        KingCooStoryArt.paint(c, KingCooMood.plain);
      });
      expect(differing(withBagel, plain), greaterThan(1000));
      // The beaten pose and the beaten-and-happy (the bagel job) differ.
      expect(
        differing(await portrait(StoryMood.happy, beaten: true), await portrait(StoryMood.plain, beaten: true)),
        greaterThan(800),
        reason: 'the beaten king who is offered a bagel reaches for it',
      );
    });
  });

  testWidgets('talking opens the beak, a blink lowers the lids, the beaten wear no cap', (tester) async {
    await tester.runAsync(() async {
      for (final mood in StoryMood.values) {
        final closed = await portrait(mood);
        final talking = await portrait(mood, talk: 1);
        expect(differing(closed, talking), greaterThan(60), reason: '$mood: talking moves the beak');
        final blinking = await portrait(mood, blink: 1);
        expect(differing(closed, blinking), greaterThan(20), reason: '$mood: a blink shows');
      }
      expect(KingCooPose.story(KingCooMood.sad, beaten: true).capOff, isTrue);
      expect(KingCooPose.story(KingCooMood.sad).capOff, isFalse);
    });
  });

  testWidgets('a portrait is deterministic and a pure function of its arguments', (tester) async {
    await tester.runAsync(() async {
      for (final (_, mood, beaten) in scenes) {
        final a = await portrait(mood, beaten: beaten, talk: .5, blink: .5);
        final b = await portrait(mood, beaten: beaten, talk: .5, blink: .5);
        expect(a, equals(b));
      }
    });
  });
}
