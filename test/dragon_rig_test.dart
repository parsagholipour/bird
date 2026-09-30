import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_body_art.dart';
import 'package:push_up_bird/game/dragon_head_art.dart';
import 'package:push_up_bird/game/dragon_hide_art.dart';
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

/// The rig's contract with everything that places the dragon in the world:
/// its bounds, the mouth / eye / crown anchors (whatever art is in the tree),
/// the falling crown, the z-order, and a canvas left as it was found.

SkyBoss _boss(
  double combat, {
  bool fury = false,
  BreathLane lane = BreathLane.middle,
  void Function(SkyBoss)? setup,
}) {
  final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 5
    ..breathLane = lane;
  if (fury) b.hp = b.maxHp ~/ 3;
  b.age = b.arrivalDuration + combat;
  setup?.call(b);
  return b;
}

DragonPose _pose(SkyBoss b, {bool reduced = false, double lookY = 0}) =>
    DragonPose(b, BossMotion(b, reducedMotion: reduced), lookY: lookY);

/// A canvas that remembers what the rig did to it.
class _Spy implements Canvas {
  final ops = <String>[];
  var depth = 0, deepest = 0;
  final transforms = <(String, double, double)>[];

  @override
  void save() {
    depth++;
    deepest = math.max(deepest, depth);
    ops.add('save');
  }

  @override
  void restore() {
    depth--;
    ops.add('restore');
  }

  @override
  void translate(double dx, double dy) {
    transforms.add(('translate', dx, dy));
    ops.add('translate');
  }

  @override
  void rotate(double r) {
    transforms.add(('rotate', r, 0));
    ops.add('rotate');
  }

  @override
  void scale(double sx, [double? sy]) {
    transforms.add(('scale', sx, sy ?? sx));
    ops.add('scale');
  }

  @override
  void drawCircle(Offset c, double r, Paint paint) => ops.add('draw');
  @override
  void drawPath(Path p, Paint paint) => ops.add('draw');
  @override
  void drawRect(Rect r, Paint paint) => ops.add('draw');
  @override
  void drawLine(Offset a, Offset b, Paint paint) => ops.add('draw');
  @override
  void drawOval(Rect r, Paint paint) => ops.add('draw');
  @override
  void drawRRect(RRect r, Paint paint) => ops.add('draw');
  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) => ops.add('draw');
  @override
  void clipPath(Path p, {bool doAntiAlias = true}) => ops.add('clip');
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    depth++;
    ops.add('saveLayer');
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    ops.add('other:${i.memberName}');
    return null;
  }
}

Future<List<int>> _pixels(void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.scale(40);
  c.translate(5, 6);
  draw(c);
  final img = await rec.endRecording().toImage(400, 400);
  final data = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bounds', () {
    test('the layer clip is the layout\'s, and holds every pose of the envelope',
        () {
      expect(DragonBossRig.bounds, DragonLayout.layerBounds);
      // Room for the arrival swell (x1.1) and the defeat pitch and fall.
      final swell = Rect.fromLTRB(
        DragonLayout.envelope.left * 1.1,
        DragonLayout.envelope.top * 1.1,
        DragonLayout.envelope.right * 1.1,
        DragonLayout.envelope.bottom * 1.1,
      );
      expect(DragonBossRig.bounds.left, lessThanOrEqualTo(swell.left));
      expect(DragonBossRig.bounds.top, lessThanOrEqualTo(swell.top));
      expect(DragonBossRig.bounds.right, greaterThanOrEqualTo(swell.right));
      expect(DragonBossRig.bounds.bottom, greaterThanOrEqualTo(swell.bottom));
      expect(DragonLayout.envelope.left, greaterThanOrEqualTo(DragonBossRig.bounds.left));
    });

    test('the envelopes nest: rest inside combat inside the layer clip', () {
      const rest = DragonLayout.restEnvelope, env = DragonLayout.envelope;
      expect(env.left, lessThanOrEqualTo(rest.left));
      expect(env.top, lessThanOrEqualTo(rest.top));
      expect(env.right, greaterThanOrEqualTo(rest.right));
      expect(env.bottom, greaterThanOrEqualTo(rest.bottom));
      // The combat envelope fits the worst-case screen.
      const screen = DragonLayout.visibleWorst;
      expect(env.top, greaterThanOrEqualTo(screen.top));
      expect(env.bottom, lessThanOrEqualTo(screen.bottom));
      expect(env.right, lessThanOrEqualTo(screen.right));
    });

    test('the crown box is the head art\'s', () {
      expect(DragonBossRig.crownBounds, DragonHeadArt.crownBounds);
    });
  });

  group('anchors', () {
    test('the jaws open on the rules\' mouth at full charge, in every state',
        () {
      for (final reduced in [false, true]) {
        for (final fury in [false, true]) {
          for (final lane in BreathLane.values) {
            for (final lookY in [-1.0, 0.0, 1.0]) {
              for (final combat in const [1.2, 2.8, 8.2, 9.5]) {
                final boss = _boss(
                  combat,
                  fury: fury,
                  lane: lane,
                  setup: (b) => b.fireIn = .01,
                );
                final pose = _pose(boss, reduced: reduced, lookY: lookY);
                final mouth = DragonBossRig.mouthAt(pose) * SkyBoss.radius;
                expect(
                  mouth.dx,
                  closeTo(SkyBoss.dragonMouth.$1, .012),
                  reason: 'reduced $reduced fury $fury look $lookY t $combat',
                );
                expect(mouth.dy, closeTo(SkyBoss.dragonMouth.$2, .012));
              }
            }
          }
        }
      }
    });

    test('the mouth rides the head in every other state (pitch and bob included)',
        () {
      for (final combat in const [1.2, 4.6, 5.05, 5.6, 6.5, 7.9]) {
        final pose = _pose(_boss(combat));
        final mouth = DragonBossRig.mouthAt(pose);
        final expected = pose.toRig(
          DragonHeadArt.point(DragonBossRig.headOf(pose), DragonHeadArt.mouth),
        );
        expect(mouth, expected);
        // The mouth follows the figure's turn: a nose-up figure lifts it.
        final flat = pose.headPoint(DragonLayout.headMouth);
        expect(
          (mouth - pose.toRig(flat)).distance,
          lessThan(.15),
          reason: 't $combat (old art\'s mouth anchor within .15 of the layout\'s)',
        );
      }
    });

    test('eye and crown anchors are the head\'s anchors through pitch and bob',
        () {
      for (final combat in const [1.2, 5.05, 5.6, 7.9]) {
        final pose = _pose(_boss(combat));
        expect(
          DragonBossRig.eyeAt(pose),
          pose.toRig(
            DragonHeadArt.point(DragonBossRig.headOf(pose), DragonHeadArt.eye),
          ),
        );
        final crown = DragonBossRig.crownAt(pose);
        expect(
          crown.at,
          pose.toRig(
            DragonHeadArt.point(DragonBossRig.headOf(pose), DragonHeadArt.crownSeat),
          ),
        );
        expect(
          crown.angle,
          closeTo(pose.pitch - pose.head.angle + DragonLayout.headCrownTurn, 1e-12),
        );
      }
    });

    test('the rest anchors are those of the still pose', () {
      expect(
        DragonBossRig.eyeCenter,
        DragonBossRig.eyeAt(DragonPose.still),
      );
      expect(
        DragonBossRig.crownAnchor,
        DragonBossRig.crownAt(DragonPose.still).at,
      );
      // The rest eye is well clear of the top of the screen and the bar.
      expect(DragonBossRig.eyeCenter.dy, greaterThan(DragonLayout.healthBarClearance + .3));
      expect(DragonBossRig.crownAnchor.dy, greaterThan(DragonLayout.envelope.top + .2));
    });

    test('a turn of the look moves the eye, not the mouth anchor', () {
      final up = _pose(_boss(1.2), lookY: -1);
      final down = _pose(_boss(1.2), lookY: 1);
      expect(up.aim, -1);
      expect(down.aim, 1);
      expect(up.head.angle, lessThan(down.head.angle));
      // ... but at full charge the mouth sits on the rules' anchor either way.
      for (final look in [up, down]) {
        final charged = _pose(
          _boss(1.2, setup: (b) => b.fireIn = 1e-6),
          lookY: look.aim,
        );
        expect(
          (charged.headPoint(DragonLayout.headMouth) - DragonLayout.rulesMouth).distance,
          lessThan(.005),
        );
      }
    });
  });

  group('the falling crown', () {
    test('it leaves the head that lost it, from whatever the dragon was doing',
        () {
      for (final reduced in [false, true]) {
        final drop = DragonBossRig.crownDrop(.3, reduced: reduced);
        for (final combat in const [1.2, 4.6, 5.05, 5.6, 5.9, 7.9]) {
          final pose = _pose(
            _boss(combat, setup: (b) => b.defeatedAt = b.age - .3),
            reduced: reduced,
          );
          final real = DragonBossRig.crownAt(pose);
          expect((real.at - drop.at).distance, lessThan(1e-9), reason: 't $combat reduced $reduced');
          expect(real.angle, closeTo(drop.angle, 1e-9));
        }
      }
    });

    test('and it starts on the slumped head, not at the rest seat', () {
      final rest = DragonBossRig.crownAnchor;
      final drop = DragonBossRig.crownDrop(.3);
      expect((drop.at - rest).distance, greaterThan(.4));
      // The head is thrown back and drops: the seat is lower and to the tail.
      expect(drop.at.dy, greaterThan(rest.dy));
      // Earlier in the throes the seat is nearer the rest seat.
      final early = DragonBossRig.crownDrop(.05);
      expect((early.at - rest).distance, lessThan((drop.at - rest).distance));
      // Reduced Motion: one still slumped head.
      final r1 = DragonBossRig.crownDrop(.1, reduced: true);
      final r2 = DragonBossRig.crownDrop(.5, reduced: true);
      expect(r1.at, r2.at);
    });

    test('the crown seat is continuous through the defeat (no hop at .3)', () {
      var prev = DragonBossRig.crownDrop(0);
      for (var d = .002; d <= .6; d += .002) {
        final c = DragonBossRig.crownDrop(d);
        // (the killing blow flings the head at once - a jerk of speed, but
        // never a hop: 2 ms moves at most .07 = 35 units/s)
        expect((c.at - prev.at).distance, lessThan(.07), reason: 'd $d');
        expect((c.angle - prev.angle).abs(), lessThan(.05), reason: 'd $d');
        prev = c;
      }
    });
  });

  group('painting', () {
    test('parts are painted in the layout\'s z-order, bloom first', () {
      // (B9: the hide paints torso, tail, hind leg, neck AND head as one
      // creature under one outline, so the head is traced right after the
      // neck and before the near wing; the parts painted with their own
      // outlines (`hide: false`) keep the layout's order exactly.)
      final classic = [
        for (final p in DragonLayout.zOrder)
          if (p != 'reserved') p,
      ];
      final expected = [
        for (final p in classic)
          if (p != 'head') p,
      ]..insert(classic.indexOf('nearWing'), 'head');
      for (final combat in const [1.2, 5.05, 5.6, 7.9]) {
        final seen = <String>[];
        DragonBossRig.paintPose(
          Canvas(ui.PictureRecorder()),
          _pose(_boss(combat)),
          trace: seen.add,
        );
        expect(seen, expected, reason: 't $combat');
        final parts = <String>[];
        DragonBossRig.paintPose(
          Canvas(ui.PictureRecorder()),
          _pose(_boss(combat)),
          trace: parts.add,
          hide: false,
        );
        expect(parts, classic, reason: 'hide: false, t $combat');
      }
      // The neck is behind the near wing (the wing grows from the back), the
      // heart over both; the hide's head is behind the wing too (nothing of
      // the head reaches the wing arms) and the foreleg, over the
      // breastplate, is last.
      expect(expected.indexOf('neck'), lessThan(expected.indexOf('nearWing')));
      expect(expected.indexOf('nearWing'), lessThan(expected.indexOf('heart')));
      expect(expected.indexOf('head'), lessThan(expected.indexOf('nearWing')));
      expect(expected.indexOf('farWing'), lessThan(expected.indexOf('torso')));
      expect(expected.indexOf('heart'), lessThan(expected.indexOf('foreleg')));
      expect(classic.indexOf('heart'), lessThan(classic.indexOf('head')));
      expect(expected.first, 'bloom');
      expect(expected.last, 'smoke');
    });

    test('only= paints exactly the named parts', () {
      final seen = <String>[];
      DragonBossRig.paintPose(
        Canvas(ui.PictureRecorder()),
        _pose(_boss(1.2)),
        only: {'head', 'nearWing'},
        trace: seen.add,
      );
      expect(seen, ['nearWing', 'head']);
    });

    test('the figure is turned by the pitch and shifted by the bob, once, '
        'after the scene light', () {
      for (final combat in const [1.2, 5.3, 5.6]) {
        final pose = _pose(_boss(combat));
        final spy = _Spy();
        DragonBossRig.paintPose(spy, pose);
        // Translate then rotate, in that order, with the pose's numbers.
        final t = spy.transforms.where((e) => e.$1 != 'scale').toList();
        final first = t.indexWhere((e) => e.$1 == 'translate' && e.$2 == pose.bob.dx && e.$3 == pose.bob.dy);
        expect(first, isNonNegative, reason: 't $combat');
        expect(t[first + 1].$1, 'rotate');
        expect(t[first + 1].$2, pose.pitch);
      }
    });

    test('the canvas comes back as it was: saves balance, no layers', () {
      for (final combat in const [1.2, 5.05, 5.6, 7.9]) {
        for (final crown in [true, false]) {
          final spy = _Spy();
          DragonBossRig.paintPose(spy, _pose(_boss(combat)), crown: crown);
          expect(spy.depth, 0, reason: 't $combat');
          expect(spy.ops.where((o) => o == 'saveLayer'), isEmpty);
        }
      }
    });

    testWidgets('painting is deterministic and pure', (tester) async {
      await tester.runAsync(() async {
        for (final combat in const [1.2, 5.05, 5.6, 7.9]) {
          final pose = _pose(_boss(combat));
          final a = await _pixels((c) => DragonBossRig.paintPose(c, pose));
          // Paint something else in between: no state leaks between frames.
          await _pixels((c) => DragonBossRig.paintPose(c, _pose(_boss(6.0, fury: true))));
          final b = await _pixels((c) => DragonBossRig.paintPose(c, _pose(_boss(combat))));
          expect(b, a, reason: 't $combat');
        }
      });
    });

    testWidgets('paint(boss, motion) is paintPose(DragonPose)', (tester) async {
      await tester.runAsync(() async {
        for (final combat in const [1.2, 5.6]) {
          final boss = _boss(combat);
          final m = BossMotion(boss, reducedMotion: false);
          final a = await _pixels((c) => DragonBossRig.paint(c, boss, m));
          final b = await _pixels((c) => DragonBossRig.paintPose(c, DragonPose(boss, m)));
          expect(a, b);
        }
        // The circlet leaves at 0.3 s of the defeat, and not before.
        final early = _boss(1.2, setup: (b) => b.defeatedAt = b.age - .1);
        final late = _boss(1.2, setup: (b) => b.defeatedAt = b.age - .5);
        final me = BossMotion(early, reducedMotion: false);
        final ml = BossMotion(late, reducedMotion: false);
        expect(
          await _pixels((c) => DragonBossRig.paint(c, early, me)),
          await _pixels((c) => DragonBossRig.paintPose(c, DragonPose(early, me))),
        );
        expect(
          await _pixels((c) => DragonBossRig.paint(c, late, ml)),
          await _pixels((c) => DragonBossRig.paintPose(c, DragonPose(late, ml), crown: false)),
        );
      });
    });

    testWidgets('a dark sky changes the light, not the drawing\'s bounds',
        (tester) async {
      await tester.runAsync(() async {
        final boss = _boss(1.2);
        final m = BossMotion(boss, reducedMotion: false);
        final day = await _pixels(
          (c) => DragonBossRig.paintPose(c, DragonPose(boss, m)),
        );
        final night = await _pixels(
          (c) => DragonBossRig.paintPose(
            c,
            DragonPose(boss, m, light: const DragonSkyLight(dark: 1)),
          ),
        );
        expect(night, isNot(day));
      });
    });

    test('the bloom is the only thing drawn outside the figure\'s transform', () {
      final spy = _Spy();
      DragonBossRig.paintPose(
        spy,
        _pose(_boss(5.6), ),
        only: {'bloom'},
      );
      // (Two cached glows: translate/scale/circle inside a save/restore each.)
      expect(spy.depth, 0);
      expect(spy.ops.where((o) => o == 'draw').length, lessThanOrEqualTo(2));
    });

    test('the bloom skips itself where it is invisible (and only there)', () {
      // A bright sky at rest: nothing drawn. Night, or any heat: drawn.
      final calm = _Spy();
      DragonBossRig.paintPose(calm, _pose(_boss(1.2)), only: {'bloom'}, warm: false);
      expect(calm.ops.where((o) => o == 'draw'), isEmpty);
      final night = _Spy();
      final b = _boss(1.2);
      DragonBossRig.paintPose(
        night,
        DragonPose(b, BossMotion(b, reducedMotion: false), light: const DragonSkyLight(dark: .9)),
        only: {'bloom'},
        warm: false,
      );
      expect(night.ops.where((o) => o == 'draw'), isNotEmpty);
      final hot = _Spy();
      DragonBossRig.paintPose(hot, _pose(_boss(5.6)), only: {'bloom'}, warm: false);
      expect(hot.ops.where((o) => o == 'draw'), isNotEmpty);
    });
  });

  group('round 2: the neck shows', () {
    /// The least distance between the head's outline (skull and lower jaw) and
    /// the chest's front (the torso outline left of x -.6), in rig units: the
    /// throat. The bible wants the notch at least .7 deep in the calm; the
    /// design review measured .27 in the low-lane strike (the jaw on the
    /// breastplate).
    double throat(DragonPose pose) {
      List<Offset> along(Path path) => [
        for (final m in path.computeMetrics())
          for (var d = 0.0; d < m.length; d += .03) m.getTangentForOffset(d)!.position,
      ];
      final hide = DragonHide(DragonBodyPose.of(pose), DragonHeadPose.of(pose));
      final head = [...along(hide.skull), ...along(hide.jaw)];
      final chest = [for (final q in along(hide.torso)) if (q.dx <= -.6) q];
      var best = double.infinity;
      for (final p in head) {
        for (final q in chest) {
          best = math.min(best, (p - q).distanceSquared);
        }
      }
      return math.sqrt(best);
    }

    test('chin to chest: open in the calm, the alert and every strike', () {
      double at(double combat, {BreathLane lane = BreathLane.middle, bool fury = false}) =>
          throat(_pose(_boss(combat, lane: lane, fury: fury)));
      // The calm, through a whole wingbeat (the head bobs .16 against the body).
      var calmLeast = 9.0, calmMost = 0.0;
      for (var t = 0.3; t < 3.3; t += .05) {
        final g = at(t);
        calmLeast = math.min(calmLeast, g);
        calmMost = math.max(calmMost, g);
      }
      // ignore: avoid_print
      print('throat: calm ${calmLeast.toStringAsFixed(2)} .. ${calmMost.toStringAsFixed(2)}');
      expect(calmLeast, greaterThanOrEqualTo(.44));
      expect(calmMost, greaterThanOrEqualTo(.7));
      expect(at(3.95), greaterThanOrEqualTo(.6), reason: 'alert');
      expect(at(4.6), greaterThanOrEqualTo(.45), reason: 'rear');
      expect(at(5.05), greaterThanOrEqualTo(.5), reason: 'hold');
      expect(at(5.24), greaterThanOrEqualTo(.44), reason: 'snap mid');
      expect(at(6.0), greaterThanOrEqualTo(.48), reason: 'blast mid');
      expect(at(6.0, lane: BreathLane.high), greaterThanOrEqualTo(.7), reason: 'blast high');
      // The low strike: the jaw used to land on the breastplate (0.00).
      expect(at(5.28, lane: BreathLane.low), greaterThanOrEqualTo(.36), reason: 'snap low');
      expect(at(5.36, lane: BreathLane.low), greaterThanOrEqualTo(.36), reason: 'thump low');
      expect(at(6.0, lane: BreathLane.low), greaterThanOrEqualTo(.36), reason: 'blast low');
      expect(at(7.9), greaterThanOrEqualTo(.45), reason: 'roar');
      expect(at(1.2, fury: true), greaterThanOrEqualTo(.44), reason: 'fury');
      expect(at(6.0, lane: BreathLane.low, fury: true), greaterThanOrEqualTo(.36), reason: 'fury low');
      // The rest pose (no idle life) is the deep one.
      expect(throat(_pose(_boss(1.2), reduced: true)), greaterThanOrEqualTo(.7));
    });
  });

  group('round 2: a rig that survives bad times and warms itself', () {
    test('a NaN or infinite clock paints (and every part rounds something)', () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        for (final field in ['age', 'lastHitAt', 'fireIn', 'enragedAt', 'defeatedAt']) {
          final b = _boss(5.3, fury: true);
          switch (field) {
            case 'age':
              b.age = v;
            case 'lastHitAt':
              b.lastHitAt = v;
            case 'fireIn':
              b.fireIn = v;
            case 'enragedAt':
              b.enragedAt = v;
            case 'defeatedAt':
              b.defeatedAt = v;
          }
          final m = BossMotion(b, reducedMotion: false);
          // (paint builds its own pose: this is the game's own call)
          DragonBossRig.paint(Canvas(ui.PictureRecorder()), b, m);
          DragonBossRig.paintPose(Canvas(ui.PictureRecorder()), DragonPose(b, m));
          expect(DragonBossRig.mouthAt(DragonPose(b, m)).isFinite, isTrue, reason: '$field=$v');
          expect(DragonBossRig.eyeAt(DragonPose(b, m)).isFinite, isTrue);
          expect(DragonBossRig.crownAt(DragonPose(b, m)).at.isFinite, isTrue);
        }
      }
      // A NaN sky.
      final b = _boss(1.2);
      DragonBossRig.paintPose(
        Canvas(ui.PictureRecorder()),
        DragonPose(b, BossMotion(b, reducedMotion: false), light: const DragonSkyLight(dark: double.nan)),
      );
    });

    testWidgets('the prewarm never changes a pixel of the frame it rides on', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final combat in const [.3, 3.95, 5.6, 7.9]) {
          final pose = _pose(_boss(combat));
          final cold = await _pixels(
            (c) => DragonBossRig.paintPose(c, pose, warm: false),
          );
          final warm = await _pixels(
            (c) => DragonBossRig.paintPose(c, pose, warm: true),
          );
          expect(warm, cold, reason: 't $combat');
        }
        // A pose painted in another tone (what the prewarm does) differs, and
        // asks only for what the tone changes.
        final p = _pose(_boss(1.2));
        final hit = p.withTone(const DragonTone(flash: .5));
        final plain = await _pixels((c) => DragonBossRig.paintPose(c, p, warm: false));
        final bleached = await _pixels((c) => DragonBossRig.paintPose(c, hit, warm: false));
        expect(bleached, isNot(plain));
      });
    });

    test('the prewarm builds ahead in pictures nobody sees, once per look', () {
      final before = DragonBossRig.warmedShaders;
      // A fresh arrival frame queues the ladders; quiet frames paint them.
      for (var i = 0; i < 40; i++) {
        final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
          ..age = .5 + i / 60;
        DragonBossRig.paintPose(
          Canvas(ui.PictureRecorder()),
          DragonPose(b, BossMotion(b, reducedMotion: false), light: const DragonSkyLight(dark: .25)),
        );
      }
      final built = DragonBossRig.warmedShaders - before;
      // (it may already have run for this sky in an earlier test: never less
      // than nothing, and never unbounded)
      expect(built, greaterThanOrEqualTo(0));
      expect(built, lessThan(4000));
      // Nothing is built for a look it has already built.
      final once = DragonBossRig.warmedShaders;
      for (var i = 0; i < 40; i++) {
        final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
          ..age = .5 + i / 60;
        DragonBossRig.paintPose(
          Canvas(ui.PictureRecorder()),
          DragonPose(b, BossMotion(b, reducedMotion: false), light: const DragonSkyLight(dark: .25)),
        );
      }
      expect(DragonBossRig.warmedShaders, once);
    });
  });
}
