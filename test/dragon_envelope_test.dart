import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_head_art.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

import 'dragon_enforce.dart';
import 'proof/dragon_proof_rig.dart';

/// The Ember Dragon must fit the screen.
///
/// At 640x360 and 800x360 the heart sits 180 px (4.35 rig units) from the
/// right edge and the rules bob it 25 px, so the visible window is
/// x <= 4.35, -3.74 <= y <= 3.74 in the worst case (DragonLayout.visibleWorst).
/// Every combat pose of every part, at every point of the wingbeat, must stay
/// inside DragonLayout.envelope.
///
/// Two checks share one list of states:
///  1. the layout numbers + the real DragonPose channels, drawn as the
///     placeholder dragon in test/proof (must always pass: it guards the
///     numbers and the pose maths);
///  2. the real art through DragonBossRig.paintPose. Until every part has
///     landed it only REPORTS; flip [enforceRealArt] (test/dragon_enforce.dart,
///     one line) to make it fail. A failure names the part, the pose, the side
///     and the coordinate of the offending pixel:
///       hold #12 fury: nearWing T+0.31 at (2.10,-4.03)

/// Pixels per rig unit for the scans, the canvas (rig units), and the alpha
/// above which a pixel counts as solid dragon (glows and smoke stay below).
const _ppu = 24.0;
const _x0 = -7.0, _y0 = -7.0, _size = 15.0;
const _solid = 200;

typedef _Setup = void Function(SkyBoss);

SkyBoss _boss(_Setup setup, double combat, {int cycles = 0, bool fury = false}) {
  final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = BreathLane.middle;
  if (fury) b.hp = b.maxHp ~/ 3;
  b.age = b.arrivalDuration + combat + cycles * DragonBreath.period;
  setup(b);
  return b;
}

DragonPose _pose(SkyBoss b, {bool reduced = false}) =>
    DragonPose(b, BossMotion(b, reducedMotion: reduced));

/// The combat states to sweep: name, combat second, setup.
final _combat = <(String, double, _Setup)>[
  ('idle', 1.2, (b) {}),
  ('idle late', 2.6, (b) {}),
  ('charge .3', 1.2, (b) => b.fireIn = .45),
  ('charge .7', 1.2, (b) => b.fireIn = .2),
  ('charge 1', 1.2, (b) => b.fireIn = .01),
  ('shot', 1.2, (b) => b.lastVolleyAt = b.age - .04),
  ('recoil', 1.2, (b) => b.lastVolleyAt = b.age - .14),
  ('spring dip', 1.2, (b) => b.lastVolleyAt = b.age - .22),
  ('recoil late', 1.2, (b) => b.lastVolleyAt = b.age - .3),
  ('hit', 1.2, (b) => b.lastHitAt = b.age - .1),
  ('hit kick', 1.2, (b) => b.lastHitAt = b.age - .05),
  ('hit tail', 1.2, (b) => b.lastHitAt = b.age - .16),
  ('alert', 3.7, (b) {}),
  ('sniff', 4.15, (b) {}),
  ('sniff nudge', 4.22, (b) {}),
  ('rear', 4.6, (b) {}),
  ('rear late', 4.9, (b) {}),
  ('hold', 5.05, (b) {}),
  ('snap', 5.23, (b) {}),
  ('overshoot', 5.33, (b) {}),
  for (final lane in BreathLane.values) ...[
    ('blast ${lane.name}', 5.6, (b) => b.breathLane = lane),
    ('thump ${lane.name}', 5.42, (b) => b.breathLane = lane),
    ('thump 2 ${lane.name}', 5.5, (b) => b.breathLane = lane),
    ('scan up ${lane.name}', 5.9, (b) => b.breathLane = lane),
    ('scan down ${lane.name}', 6.7, (b) => b.breathLane = lane),
    ('plateau ${lane.name}', 6.5, (b) => b.breathLane = lane),
  ],
  ('gutter', 7.3, (b) {}),
  ('exhale', 7.35, (b) {}),
  ('wind', 7.45, (b) {}),
  ('call', 7.72, (b) => b.lastSummonAt = b.age - .1),
  ('call peak', 7.95, (b) => b.lastSummonAt = b.age - .35),
  ('call fade', 8.3, (b) {}),
  ('call + fireball', 7.9, (b) => b.fireIn = .05),
  ('rage', 1.2, (b) => b.enragedAt = b.age - .3),
  ('rage 2', 1.2, (b) => b.enragedAt = b.age - .6),
];

/// The same moments in fury.
final _furyStates = <(String, double, _Setup)>[
  ('fury idle', 1.2, (b) {}),
  ('fury hold', 5.05, (b) {}),
  ('fury blast', 5.6, (b) {}),
  ('fury call', 7.72, (b) {}),
  ('fury call 2', 9.2, (b) {}),
  ('fury wind 2', 8.9, (b) {}),
  ('fury charge', 1.2, (b) => b.fireIn = .01),
  ('fury rage', 1.2, (b) => b.enragedAt = b.age - .4),
];

/// Arrival and defeat are staged cinematics: they must fit the layer clip,
/// not the combat envelope.
final _staged = <(String, _Setup)>[
  for (final age in const [.3, 1.0, 1.5, 2.2, 2.55, 2.8, 3.1, 3.6, 4.4])
    ('arrival $age', (b) => b.age = age),
  for (final death in const [.03, .1, .2, .3, .5, .8, 1.0])
    ('defeat $death', (b) => b.defeatedAt = b.age - death),
  for (final death in const [.1, .3, .6])
    (
      'defeat from hold $death',
      (b) {
        b.age = b.arrivalDuration + 5.05;
        b.defeatedAt = b.age - death;
      },
    ),
];

/// Where the solid pixels of a drawing reach, with the pixel that reaches
/// furthest on each side (rig units).
class _Scan {
  const _Scan(this.rect, this.atLeft, this.atTop, this.atRight, this.atBottom);
  final Rect rect;
  final Offset atLeft, atTop, atRight, atBottom;
  double get left => rect.left;
  double get top => rect.top;
  double get right => rect.right;
  double get bottom => rect.bottom;
  static const empty = _Scan(Rect.zero, Offset.zero, Offset.zero, Offset.zero, Offset.zero);
}

/// The bounds of the solid pixels of [draw] in rig units.
Future<_Scan> _scan(void Function(Canvas) draw, {int solid = _solid}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.scale(_ppu);
  c.translate(-_x0, -_y0);
  draw(c);
  final pic = rec.endRecording();
  final n = (_size * _ppu).round();
  final img = await pic.toImage(n, n);
  final data = (await img.toByteData())!.buffer.asUint8List();
  var minX = n, minY = n, maxX = -1, maxY = -1;
  var left = 0, top = 0, right = 0, bottom = 0; // the other coordinate
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (data[(y * n + x) * 4 + 3] >= solid) {
        if (x < minX) {
          minX = x;
          left = y;
        }
        if (x > maxX) {
          maxX = x;
          right = y;
        }
        if (y < minY) {
          minY = y;
          top = x;
        }
        if (y > maxY) {
          maxY = y;
          bottom = x;
        }
      }
    }
  }
  img.dispose();
  pic.dispose();
  if (maxX < 0) return _Scan.empty;
  Offset at(int x, int y) => Offset((x + .5) / _ppu + _x0, (y + .5) / _ppu + _y0);
  return _Scan(
    Rect.fromLTRB(
      minX / _ppu + _x0,
      minY / _ppu + _y0,
      (maxX + 1) / _ppu + _x0,
      (maxY + 1) / _ppu + _y0,
    ),
    at(minX, left),
    at(top, minY),
    at(maxX, right),
    at(bottom, maxY),
  );
}

/// How far [s] pokes out of [box], per side, with the offending coordinate.
String _over(_Scan s, Rect box) {
  final r = s.rect;
  String at(Offset o) => '(${o.dx.toStringAsFixed(2)},${o.dy.toStringAsFixed(2)})';
  final o = [
    if (r.left < box.left - .02)
      'L+${(box.left - r.left).toStringAsFixed(2)} at ${at(s.atLeft)}',
    if (r.top < box.top - .02)
      'T+${(box.top - r.top).toStringAsFixed(2)} at ${at(s.atTop)}',
    if (r.right > box.right + .02)
      'R+${(r.right - box.right).toStringAsFixed(2)} at ${at(s.atRight)}',
    if (r.bottom > box.bottom + .02)
      'B+${(r.bottom - box.bottom).toStringAsFixed(2)} at ${at(s.atBottom)}',
  ];
  return o.join(', ');
}

Future<void> _fonts() async {
  await (FontLoader(
    'Fredoka',
  )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
}

/// The parts the real rig paints, in z-order, for naming an offender.
final _parts = [
  for (final p in DragonLayout.zOrder)
    if (p != 'reserved') p,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Sweeps every state x [envelopeCycles] wingbeat phases x calm/fury and
  /// then the staged cinematics. With [drawPart] the failures are attributed
  /// to the parts that cause them (the first [_named] only, to stay quick).
  Future<void> sweep(
    WidgetTester tester, {
    required String label,
    required void Function(Canvas, DragonPose) draw,
    void Function(Canvas, DragonPose, Set<String>)? drawPart,
    required bool enforce,
    int solid = _solid,
  }) async {
    const named = 30;
    await tester.runAsync(() async {
      final failures = <String>[];
      var worst = Rect.zero;
      var attributed = 0;
      // Which state pushes each side furthest (for the report).
      final reach = <String, (double, String)>{
        'L': (99, ''), 'T': (99, ''), 'R': (-99, ''), 'B': (-99, ''),
      };
      Future<void> fail(String name, DragonPose pose, _Scan r, Rect box) async {
        final o = _over(r, box);
        if (o.isEmpty) return;
        if (drawPart == null || attributed >= named) {
          failures.add('$name: $o');
          return;
        }
        attributed++;
        final culprits = <String>[];
        for (final part in _parts) {
          final pr = await _scan(
            (c) => drawPart(c, pose, {part}),
            solid: solid,
          );
          final po = _over(pr, box);
          if (po.isNotEmpty) culprits.add('$part $po');
        }
        failures.add(
          '$name: ${culprits.isEmpty ? o : culprits.join('; ')}',
        );
      }

      for (final fury in [false, true]) {
        for (final (name, t, setup) in fury ? _furyStates : _combat) {
          // Each whole cycle offsets the wingbeat phase by 2.85 rad, so the
          // beat is sampled all round without moving the breath's clock.
          for (var n = 0; n < envelopeCycles; n++) {
            final pose = _pose(_boss(setup, t, cycles: n, fury: fury));
            final r = await _scan((c) => draw(c, pose), solid: solid);
            worst = worst.expandToInclude(r.rect);
            final tag = '$name #$n${fury ? ' fury' : ''}';
            if (r.rect.left < reach['L']!.$1) reach['L'] = (r.rect.left, tag);
            if (r.rect.top < reach['T']!.$1) reach['T'] = (r.rect.top, tag);
            if (r.rect.right > reach['R']!.$1) reach['R'] = (r.rect.right, tag);
            if (r.rect.bottom > reach['B']!.$1) reach['B'] = (r.rect.bottom, tag);
            await fail('$name #$n${fury ? ' fury' : ''}', pose, r, DragonLayout.envelope);
          }
        }
      }
      // ignore: avoid_print
      print(
        '$label combat union: L ${worst.left.toStringAsFixed(2)} '
        'T ${worst.top.toStringAsFixed(2)} R ${worst.right.toStringAsFixed(2)} '
        'B ${worst.bottom.toStringAsFixed(2)}   envelope ${DragonLayout.envelope}\n'
        '  furthest: ${reach.entries.map((e) => '${e.key} ${e.value.$1.toStringAsFixed(2)} (${e.value.$2})').join(', ')}',
      );
      for (final (name, setup) in _staged) {
        final pose = _pose(_boss(setup, 1.2));
        final r = await _scan((c) => draw(c, pose), solid: solid);
        await fail('$name (layer)', pose, r, DragonLayout.layerBounds);
      }
      if (failures.isNotEmpty) {
        // ignore: avoid_print
        print(
          '$label: ${failures.length} over (first ${math.min(failures.length, 40)}):\n'
          '${failures.take(40).join('\n')}',
        );
      }
      if (enforce) expect(failures, isEmpty, reason: '$label leaves the envelope');
    });
  }

  testWidgets('layout + pose channels: the proof dragon fits the envelope', (
    tester,
  ) async {
    await sweep(
      tester,
      label: 'proof',
      draw: (c, pose) => paintProofDragon(c, pose),
      enforce: true,
      solid: 40,
    );
  });

  testWidgets('the real art fits the envelope (reports until enforced)', (
    tester,
  ) async {
    await sweep(
      tester,
      label: 'art',
      draw: DragonBossRig.paintPose,
      drawPart: (c, pose, only) => DragonBossRig.paintPose(c, pose, only: only),
      enforce: enforceRealArt,
    );
  });

  test('the head art speaks in layout anchors (reports until enforced)', () {
    final same = DragonHeadArt.mouth == DragonLayout.headMouth &&
        DragonHeadArt.eye == DragonLayout.headEye &&
        DragonHeadArt.nostril == DragonLayout.headNostril &&
        DragonHeadArt.crownSeat == DragonLayout.headCrownSeat &&
        DragonHeadArt.scale == DragonLayout.headScale &&
        DragonHeadArt.crownBounds == DragonLayout.crownBounds;
    if (!same) {
      // ignore: avoid_print
      print(
        'head art anchors differ from DragonLayout '
        '(mouth ${DragonHeadArt.mouth} vs ${DragonLayout.headMouth}, scale '
        '${DragonHeadArt.scale} vs ${DragonLayout.headScale}) - B1 aligns them',
      );
    }
    if (enforceRealArt) expect(same, isTrue);
  });

  test('the eye and the mouth never go under the health bar', () {
    // The bar covers x < -0.9 above y = -3.07 at the worst bob (see
    // DragonLayout.healthBarClearance); crown and horns may pass under it.
    // Checked on the layout anchors, so it holds whatever art is in place;
    // the eye's half height (.14) and the jaws' (.12) are kept clear too.
    var lowestEye = -99.0, highestEye = 99.0, highestMouth = 99.0;
    final offenders = <String>[];
    for (final fury in [false, true]) {
      for (final (name, t, setup) in fury ? _furyStates : _combat) {
        for (var n = 0; n < 12; n++) {
          final p = _pose(_boss(setup, t, cycles: n, fury: fury));
          final eye = p.toRig(p.headPoint(DragonLayout.headEye));
          final mouth = p.toRig(p.headPoint(DragonLayout.headMouth));
          highestEye = math.min(highestEye, eye.dy);
          lowestEye = math.max(lowestEye, eye.dy);
          highestMouth = math.min(highestMouth, mouth.dy);
          if (eye.dx < -.9 && eye.dy - .14 < DragonLayout.healthBarClearance) {
            offenders.add('$name #$n${fury ? ' fury' : ''}: eye at y ${eye.dy.toStringAsFixed(2)}');
          }
          if (mouth.dx < -.9 &&
              mouth.dy - .12 < DragonLayout.healthBarClearance) {
            offenders.add('$name #$n${fury ? ' fury' : ''}: mouth at y ${mouth.dy.toStringAsFixed(2)}');
          }
        }
      }
    }
    // ignore: avoid_print
    print(
      'eye y ${highestEye.toStringAsFixed(2)} .. ${lowestEye.toStringAsFixed(2)}, '
      'mouth top ${highestMouth.toStringAsFixed(2)}, '
      'bar clearance ${DragonLayout.healthBarClearance}',
    );
    expect(offenders.take(10), isEmpty);
  });

  test('the real art eye and mouth anchors agree with the pose (reports until enforced)', () {
    var worst = 0.0;
    String where = '';
    for (final (name, t, setup) in _combat) {
      final p = _pose(_boss(setup, t));
      final eye = DragonBossRig.eyeAt(p);
      final layoutEye = p.toRig(p.headPoint(DragonLayout.headEye));
      final d = (eye - layoutEye).distance;
      if (d > worst) {
        worst = d;
        where = name;
      }
    }
    if (worst > .05) {
      // ignore: avoid_print
      print('art eye differs from DragonLayout.headEye by up to ${worst.toStringAsFixed(2)} ($where)');
    }
    if (enforceRealArt) expect(worst, lessThan(.05), reason: where);
  });

  test('Reduced Motion holds the wings and the figure still', () {
    final a = _pose(_boss((b) {}, 1.2), reduced: true);
    final b = _pose(_boss((b) {}, 1.9), reduced: true);
    expect(a.stroke, -.25);
    expect(a.nearWing.tips, b.nearWing.tips);
    expect(a.bob, Offset.zero);
    expect(a.pitch, b.pitch);
    expect(a.head.at, b.head.at);
    expect(a.tailBend(1), b.tailBend(1));
  });

  testWidgets('the calm Reduced Motion pose keeps the rest envelope', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final pose = _pose(_boss((b) {}, 1.2), reduced: true);
      final r = await _scan((c) => paintProofDragon(c, pose), solid: 40);
      expect(_over(r, DragonLayout.restEnvelope), isEmpty, reason: '$r');
    });
  });

  test('the head is continuous through the fireball launch', () {
    // Charge 1 the instant before launch, then the spring: same head.
    final before = _pose(_boss((b) => b.fireIn = .001, 1.2));
    final after = _pose(_boss((b) => b.lastVolleyAt = b.age - .001, 1.2));
    expect((before.head.at - after.head.at).distance, lessThan(.02));
    expect((before.head.angle - after.head.angle).abs(), lessThan(.02));
  });

  test('every channel is finite and bounded across the whole cycle', () {
    for (var i = 0; i < 1100; i++) {
      for (final fury in [false, true]) {
        final p = _pose(_boss((b) {}, i * .01, fury: fury));
        for (final v in [
          p.inhale, p.blast, p.alert, p.hold, p.wind, p.roar, p.call,
          p.lunge.clamp(-1.0, 1.0), p.gape, p.glare, p.heart, p.chest,
          p.pitch, p.bob.dx, p.bob.dy, p.neckDrag.dx, p.neckDrag.dy,
          p.stroke, p.tailBend(1), p.nearWing.elbow, p.farWing.wrist,
        ]) {
          expect(v.isFinite, isTrue, reason: 't=${i * .01} fury=$fury');
        }
        expect(p.stroke, inInclusiveRange(-1, 1));
        expect(p.bob.distance, lessThanOrEqualTo(.3001));
        expect(p.neckDrag.distance, lessThanOrEqualTo(.5001));
        expect(p.tailBend(1).abs(), lessThanOrEqualTo(.5001));
        expect(p.pitch.abs(), lessThan(.2));
      }
    }
  });

  testWidgets('silhouette sheets and bounds for the bible', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      final out = Directory('build/visual-review/dragon-proof')
        ..createSync(recursive: true);
      // (label, combat second, setup, wanted wing stroke or null)
      final cells = <(String, double, _Setup, double?)>[
        ('idle', 1.2, (b) {}, -.25),
        ('wing up', 1.2, (b) {}, -1),
        ('wing down', 1.2, (b) {}, .7),
        ('charge', 1.2, (b) => b.fireIn = .01, null),
        ('alert', 3.7, (b) {}, null),
        ('rear back', 4.7, (b) {}, null),
        ('hold', 5.05, (b) {}, null),
        ('snap', 5.24, (b) {}, null),
        ('blast high', 5.7, (b) => b.breathLane = BreathLane.high, null),
        ('blast mid', 5.7, (b) => b.breathLane = BreathLane.middle, null),
        ('blast low', 5.7, (b) => b.breathLane = BreathLane.low, null),
        ('call wind', 7.5, (b) {}, null),
        ('swarm call', 7.95, (b) => b.lastSummonAt = b.age - .35, null),
        ('hit', 1.2, (b) => b.lastHitAt = b.age - .1, null),
        ('fury rage', 1.2, (b) => b.enragedAt = b.age - .5, null),
        ('defeat', 1.2, (b) => b.defeatedAt = b.age - .5, null),
      ];
      DragonPose pick((String, double, _Setup, double?) cell) {
        DragonPose best = _pose(_boss(cell.$3, cell.$2));
        if (cell.$4 == null) return best;
        // Whole cycles later the breath is at the same moment but the wing
        // is at another point of its beat.
        for (var n = 1; n < 48; n++) {
          final p = _pose(_boss(cell.$3, cell.$2, cycles: n));
          if ((p.stroke - cell.$4!).abs() < (best.stroke - cell.$4!).abs()) {
            best = p;
          }
        }
        return best;
      }

      final poses = [for (final cell in cells) (cell.$1, pick(cell))];
      final report = StringBuffer();
      for (final (label, pose) in poses) {
        final r = await _scan((c) => paintProofDragon(c, pose), solid: 40);
        report.writeln(
          '${label.padRight(12)} L ${r.left.toStringAsFixed(2)}  T ${r.top.toStringAsFixed(2)}  R ${r.right.toStringAsFixed(2)}  B ${r.bottom.toStringAsFixed(2)}   stroke ${pose.stroke.toStringAsFixed(2)}',
        );
      }
      File('${out.path}/bounds.txt').writeAsStringSync(report.toString());
      for (final (name, ppu, cols, flat) in const [
        ('sil-250', 41.4, 4, false),
        ('flat-250', 41.4, 4, true),
        ('sil-120', 19.0, 8, false),
      ]) {
        const x0 = -3.9, y0 = -4.6, wU = 9.2, hU = 9.2;
        final cw = (wU * ppu).round(), ch = (hU * ppu).round();
        final rows = (poses.length / cols).ceil();
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        c.drawRect(
          Rect.fromLTWH(0, 0, (cw * cols).toDouble(), (ch * rows).toDouble()),
          Paint()..color = const Color(0xffe9dfd2),
        );
        for (var i = 0; i < poses.length; i++) {
          final cx = (i % cols) * cw, cy = (i ~/ cols) * ch;
          c.save();
          c.clipRect(Rect.fromLTWH(cx.toDouble(), cy.toDouble(), cw.toDouble(), ch.toDouble()));
          c.translate(cx.toDouble(), cy.toDouble());
          c.scale(ppu);
          c.translate(-x0, -y0);
          final g = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3 / ppu
            ..color = const Color(0xffd03030);
          // Worst-case screen edges: right edge, top and bottom at the bob.
          c.drawLine(const Offset(4.35, -9), const Offset(4.35, 9), g);
          c.drawLine(const Offset(-9, -3.74), const Offset(9, -3.74), g);
          c.drawLine(const Offset(-9, 3.74), const Offset(9, 3.74), g);
          g.color = const Color(0xff2060d0);
          c.drawCircle(Offset.zero, 1, g);
          g.color = const Color(0xff30a030);
          c.drawRect(DragonLayout.envelope, g);
          paintProofDragon(c, poses[i].$2, flat: flat);
          c.restore();
          (TextPainter(
            text: TextSpan(
              text: poses[i].$1,
              style: TextStyle(fontFamily: 'Fredoka', fontSize: ppu > 30 ? 13 : 9, color: const Color(0xff222222)),
            ),
            textDirection: TextDirection.ltr,
          )..layout()).paint(c, Offset(cx + 4.0, cy + 2.0));
        }
        final img = await rec.endRecording().toImage(cw * cols, ch * rows);
        File('${out.path}/$name.png').writeAsBytesSync(
          (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List(),
        );
        img.dispose();
      }
    });
  });

  testWidgets('anchor map for the bible', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      final out = Directory('build/visual-review/dragon-proof')
        ..createSync(recursive: true);
      const ppu = 110.0, x0 = -3.7, y0 = -4.1, wU = 8.4, hU = 8.1;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(
        Rect.fromLTWH(0, 0, wU * ppu, hU * ppu),
        Paint()..color = const Color(0xffe9dfd2),
      );
      c.save();
      c.scale(ppu);
      c.translate(-x0, -y0);
      final pose = _pose(_boss((b) {}, 1.2, cycles: 3), reduced: true);
      c.saveLayer(
        null,
        Paint()..color = const Color(0x66ffffff),
      );
      paintProofDragon(c, pose, flat: true);
      c.restore();
      Paint line(Color col, [double w = 1.6]) => Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = w / ppu;
      c.drawRect(DragonLayout.envelope, line(const Color(0xff30a030), 2));
      c.drawRect(DragonLayout.restEnvelope, line(const Color(0x8830a030)));
      c.drawLine(const Offset(4.35, -9), const Offset(4.35, 9), line(const Color(0xffd03030)));
      c.drawLine(const Offset(-9, -3.74), const Offset(9, -3.74), line(const Color(0xffd03030)));
      c.drawLine(const Offset(-9, 3.74), const Offset(9, 3.74), line(const Color(0xffd03030)));
      c.drawCircle(Offset.zero, 1, line(const Color(0xff2060d0), 2.4));
      final labels = <(Offset, String, Color)>[];
      void dot(Offset p, String name, Color col) {
        c.drawCircle(p, 4 / ppu, Paint()..color = col);
        labels.add((p, name, col));
      }

      const torso = Color(0xff1050b0), wing = Color(0xffc02020);
      const head = Color(0xff107030), tail = Color(0xff8040a0);
      dot(Offset.zero, 'HEART', const Color(0xff2060d0));
      for (final (i, q) in DragonLayout.torsoOutline.indexed) {
        c.drawCircle(q, 2.5 / ppu, Paint()..color = torso);
        if (i == 0 || i == 4 || i == 9 || i == 11) labels.add((q, 'torso[$i]', torso));
      }
      dot(DragonLayout.neckBase, 'neckBase', head);
      dot(DragonLayout.neckControl, 'neckCtl', head);
      dot(DragonLayout.headRest, 'headRest', head);
      dot(DragonLayout.headCharge, 'headCharge', head);
      dot(DragonLayout.rulesMouth, 'RULES MOUTH', const Color(0xffff6a00));
      dot(pose.headPoint(DragonLayout.headEye), 'eye', head);
      dot(pose.headPoint(DragonLayout.headCrownSeat), 'crownSeat', head);
      dot(pose.headPoint(DragonLayout.headNeckJoint), 'neckJoint', head);
      dot(DragonLayout.nearShoulder, 'nearShoulder', wing);
      dot(DragonLayout.nearRoot, 'nearRoot', wing);
      dot(DragonLayout.farShoulder, 'farShoulder', wing);
      for (final (name, k) in [
        ('up', DragonLayout.wingUp),
        ('mid', DragonLayout.wingMid),
        ('down', DragonLayout.wingDown),
      ]) {
        c.drawCircle(k.wrist, 3.5 / ppu, Paint()..color = wing);
        for (final t in k.tips) {
          c.drawCircle(t, 3 / ppu, Paint()..color = wing);
          c.drawLine(k.wrist, t, line(const Color(0x55c02020), 1));
        }
        labels.add((k.tips[0], 'F0 $name', wing));
        labels.add((k.wrist, 'W $name', wing));
      }
      for (final (i, q) in DragonLayout.tailSpine.indexed) {
        dot(q, 'T$i', tail);
      }
      for (final (i, q) in DragonLayout.hindLeg.indexed) {
        dot(q, 'hind$i', torso);
      }
      for (final (i, q) in DragonLayout.foreLeg.indexed) {
        dot(q, 'fore$i', torso);
      }
      c.restore();
      for (final (p, name, col) in labels) {
        (TextPainter(
          text: TextSpan(text: name, style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: col)),
          textDirection: TextDirection.ltr,
        )..layout()).paint(c, (p - const Offset(x0, y0)) * ppu + const Offset(5, -14));
      }
      final img = await rec.endRecording().toImage((wU * ppu).round(), (hU * ppu).round());
      File('${out.path}/anchors.png').writeAsBytesSync(
        (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List(),
      );
      img.dispose();
    });
  });

  testWidgets('wingbeat onion skin for the bible', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      const ppu = 60.0, x0 = -3.7, y0 = -4.2, wU = 8.6, hU = 8.2;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(
        Rect.fromLTWH(0, 0, wU * ppu, hU * ppu),
        Paint()..color = const Color(0xffe9dfd2),
      );
      c.scale(ppu);
      c.translate(-x0, -y0);
      // Twelve samples of one beat (0.1 s apart) in translucent ink.
      for (var i = 0; i < 12; i++) {
        final pose = _pose(_boss((b) {}, 1.2 + i * .096));
        c.saveLayer(null, Paint()..color = const Color(0x2a000000));
        paintProofDragon(c, pose);
        c.restore();
      }
      final g = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / ppu
        ..color = const Color(0xffd03030);
      c.drawLine(const Offset(4.35, -9), const Offset(4.35, 9), g);
      c.drawLine(const Offset(-9, -3.74), const Offset(9, -3.74), g);
      c.drawLine(const Offset(-9, 3.74), const Offset(9, 3.74), g);
      c.drawRect(DragonLayout.envelope, g..color = const Color(0xff30a030));
      final img = await rec.endRecording().toImage((wU * ppu).round(), (hU * ppu).round());
      final out = Directory('build/visual-review/dragon-proof')..createSync(recursive: true);
      File('${out.path}/wingbeat-onion.png').writeAsBytesSync(
        (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List(),
      );
      img.dispose();
    });
  });

  testWidgets('ascii sketch for the bible', (tester) async {
    await tester.runAsync(() async {
      const cu = .16, ru = .32; // rig units per column / row
      const x0 = -3.3, y0 = -3.8, cols = 49, rows = 24;
      final pose = _pose(_boss((b) {}, 1.2, cycles: 3), reduced: true);
      const ppu = 25.0;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec)
        ..scale(ppu)
        ..translate(-x0, -y0);
      paintProofDragon(c, pose);
      final img = await rec.endRecording().toImage(
        (cols * cu * ppu).round(),
        (rows * ru * ppu).round(),
      );
      final data = (await img.toByteData())!.buffer.asUint8List();
      final w = img.width;
      final grid = [
        for (var r = 0; r < rows; r++)
          [
            for (var k = 0; k < cols; k++)
              () {
                var n = 0, tot = 0;
                for (var y = (r * ru * ppu).floor(); y < ((r + 1) * ru * ppu).floor(); y++) {
                  for (var x = (k * cu * ppu).floor(); x < ((k + 1) * cu * ppu).floor(); x++) {
                    tot++;
                    if (data[(y * w + x) * 4 + 3] > 128) n++;
                  }
                }
                return n * 2 > tot ? '#' : ' ';
              }(),
          ],
      ];
      void mark(Offset p, String ch) {
        final k = ((p.dx - x0) / cu).floor(), r = ((p.dy - y0) / ru).floor();
        if (r >= 0 && r < rows && k >= 0 && k < cols) grid[r][k] = ch;
      }
      mark(Offset.zero, 'O');
      mark(DragonLayout.rulesMouth, '*');
      mark(pose.headPoint(DragonLayout.headNeckJoint), 'J');
      mark(DragonLayout.neckBase, 'N');
      mark(DragonLayout.nearShoulder, 'S');
      mark(DragonLayout.nearRoot, 'R');
      mark(pose.headPoint(DragonLayout.headEye), 'e');
      mark(pose.headPoint(DragonLayout.headCrownSeat), 'c');
      mark(DragonLayout.tailSpine.first, 'T');
      mark(DragonLayout.hindLeg.first, 'h');
      mark(DragonLayout.foreLeg.first, 'f');
      final wm = DragonLayout.wingMid;
      mark(wm.elbow, 'E');
      mark(wm.wrist, 'W');
      final buf = StringBuffer();
      for (var r = 0; r < rows; r++) {
        buf.writeln(
          '${(y0 + r * ru).toStringAsFixed(1).padLeft(5)} ${grid[r].join()}',
        );
      }
      final out = Directory('build/visual-review/dragon-proof')..createSync(recursive: true);
      File('${out.path}/ascii.txt').writeAsStringSync(buf.toString());
    });
  });

  // Silences the unused-import lint for math when trimmed.
  test('sanity: layout mouth equals the rules mouth', () {
    expect(
      (DragonLayout.rulesMouth - const Offset(-2.548, -1.870)).distance,
      lessThan(.01),
    );
    final headMouth = DragonLayout.headCharge +
        Offset(
          DragonLayout.headMouth.dx * math.cos(DragonLayout.headChargeAngle) +
              DragonLayout.headMouth.dy * math.sin(DragonLayout.headChargeAngle),
          -DragonLayout.headMouth.dx * math.sin(DragonLayout.headChargeAngle) +
              DragonLayout.headMouth.dy * math.cos(DragonLayout.headChargeAngle),
        );
    expect((headMouth - DragonLayout.rulesMouth).distance, lessThan(.01));
  });
}
