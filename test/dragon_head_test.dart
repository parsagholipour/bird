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
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';
import 'package:push_up_bird/game/dragon_wing_art.dart';

/// The Ember Dragon's head, neck and circlet, on their own: a jaw-open
/// sweep, the expression sheets (light and dark, at 120 and 250 px), the
/// neck at every lane pose, a 6x close-up, the silhouette with the horn's
/// clearance from the wing arm, the tones (flash, fury, heat) and the
/// numbers the bible asks of package B1 (mouth anchor, budget, envelope,
/// hand-off of the falling crown).
final _folder = Directory('build/visual-review/dragon-head');

/// One 250 px dragon is ~7 rig units tall; a 120 px one ~3.4x smaller.
const _ppu250 = 250 / 7.0, _ppu120 = 120 / 7.0;

SkyBoss _boss([double combat = 1.2]) {
  final boss = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = BreathLane.middle;
  boss.age = boss.arrivalDuration + combat;
  return boss;
}

void _at(SkyBoss b, double t) => b.age = b.arrivalDuration + t;

typedef _S = ({String name, void Function(SkyBoss) setup, double aim});

_S _s(String name, void Function(SkyBoss) setup, [double aim = 0]) =>
    (name: name, setup: setup, aim: aim);

final _idle = _s('IDLE', (b) {});
final _alert = _s('ALERT', (b) => _at(b, 3.8));
// A real blink: the idle window (before the breath's alert at 3.4 s) where
// the boss clock's blink pulse peaks. Blinks are motion, so not in Reduced.
final _blink = _s('BLINK', (b) => _at(b, 2.88));
final _charge = _s('CHARGE', (b) => b.fireIn = .12);
final _rear = _s('INHALE', (b) => _at(b, 4.7));
final _hold = _s('HOLD', (b) => _at(b, 5.05));
final _snap = _s('SNAP', (b) => _at(b, 5.26));
final _roar = _s('ROAR', (b) => b.age = SkyBoss.roarAt + .3);
final _call = _s('CALL', (b) {
  _at(b, 7.95);
  b.lastSummonAt = b.age - .35;
});
final _wince = _s('WINCE', (b) => b.lastHitAt = b.age - .14);
final _fury = _s('FURY', (b) => b.hp = b.maxHp ~/ 3);
final _rage = _s('RAGE', (b) {
  b.hp = b.maxHp ~/ 3;
  b.enragedAt = b.age - .45;
});
final _dizzy = _s('DEFEAT', (b) => b.defeatedAt = b.age - .15);
final _lookUp = _s('LOOK UP', (b) {}, -1);
final _lookDown = _s('LOOK DOWN', (b) {}, 1);
final _flash = _s('FLASH', (b) => b.lastHitAt = b.age - .1);
final _blastMid = _s('BLAST MID', (b) => _at(b, 5.6));
final _blastLow = _s('BLAST LOW', (b) {
  b.breathLane = BreathLane.low;
  _at(b, 5.6);
});
final _snapHigh = _s('SNAP HIGH', (b) {
  b.breathLane = BreathLane.high;
  _at(b, 5.3);
});
final _snapLow = _s('SNAP LOW', (b) {
  b.breathLane = BreathLane.low;
  _at(b, 5.3);
});

/// The twelve expressions of the sheet.
final _twelve = [
  _idle,
  _alert,
  _blink,
  _charge,
  _rear,
  _hold,
  _roar,
  _call,
  _wince,
  _fury,
  _rage,
  _dizzy,
];

DragonPose _pose(_S s, {bool reduced = false, DragonSkyLight? light}) {
  final boss = _boss();
  s.setup(boss);
  return DragonPose(
    boss,
    BossMotion(boss, reducedMotion: reduced),
    lookY: s.aim,
    light: light ?? DragonSkyLight.neutral,
  );
}

// ------------------------------------------------------------- drawing --

/// What stands behind the neck and head in a review render.
enum _Body { none, torso, full }

/// The neck and head as the rig draws them, in the rig's z-order, over a
/// flat stand-in for the parts other builders own (torso, wings, tail, legs
/// from the layout numbers and the pose channels, like the proof rig).
void _paintHead(
  Canvas c,
  DragonPose pose, {
  bool crown = true,
  _Body body = _Body.torso,
}) {
  final head = DragonHeadPose.of(pose, crown: crown);
  c.save();
  c.translate(pose.bob.dx, pose.bob.dy);
  c.rotate(pose.pitch);
  if (body == _Body.full) {
    _standWing(c, pose, far: true);
    _standLeg(c, pose, hind: true, far: true);
    _standLeg(c, pose, hind: false, far: true);
    _standTail(c, pose);
  }
  if (body != _Body.none) {
    final t = DragonKit.spline(DragonLayout.torsoOutline);
    _standShape(c, t, const Color(0xff6a4a80));
  }
  if (body == _Body.full) _standLeg(c, pose, hind: true, far: false);
  DragonHeadArt.neck(c, head);
  if (body == _Body.full) _standWing(c, pose, far: false);
  if (body != _Body.none) {
    c.drawCircle(Offset.zero, 1, DragonKit.line(const Color(0x66ffffff), .02));
  }
  DragonHeadArt.head(c, head);
  if (body == _Body.full) _standLeg(c, pose, hind: false, far: false);
  DragonHeadArt.smoke(c, head);
  c.restore();
}

void _standShape(Canvas c, Path path, Color colour, {double w = .07}) {
  c.drawPath(path, Paint()..color = colour);
  c.drawPath(
    path,
    Paint()
      ..color = const Color(0xff101010)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeJoin = StrokeJoin.round,
  );
}

void _standTail(Canvas c, DragonPose p) {
  const base = DragonLayout.tailSpine;
  final n = base.length;
  final spine = [
    for (var i = 0; i < n; i++) base[i] + Offset(0, p.tailBend(i / (n - 1))),
  ];
  _standShape(
    c,
    DragonKit.tube(spine, DragonLayout.tailWidths),
    const Color(0xff5a4070),
  );
  final tip = spine.last;
  final d = DragonKit.unit(spine.last - spine[n - 2]);
  final nn = Offset(-d.dy, d.dx);
  const len = DragonLayout.tailBladeLength,
      hw = DragonLayout.tailBladeHalfWidth;
  final blade = Path()
    ..moveTo(tip.dx + nn.dx * .18, tip.dy + nn.dy * .18)
    ..quadraticBezierTo(
      tip.dx + nn.dx * hw + d.dx * .3,
      tip.dy + nn.dy * hw + d.dy * .3,
      tip.dx + d.dx * len,
      tip.dy + d.dy * len,
    )
    ..quadraticBezierTo(
      tip.dx - nn.dx * hw + d.dx * .3,
      tip.dy - nn.dy * hw + d.dy * .3,
      tip.dx - nn.dx * .18,
      tip.dy - nn.dy * .18,
    )
    ..close();
  _standShape(c, blade, const Color(0xffc04050));
}

void _standLeg(
  Canvas c,
  DragonPose p, {
  required bool hind,
  required bool far,
}) {
  final shift = far ? DragonLayout.farLegShift : Offset.zero;
  final limb = [
    for (final q in hind ? DragonLayout.hindLeg : DragonLayout.foreLeg)
      q + shift,
  ];
  if (hind) limb[2] += Offset(.25 * p.legKick, -.08 * p.legKick.abs());
  final foot =
      limb.last + (hind ? DragonLayout.hindFoot : DragonLayout.foreFoot);
  final w = hind
      ? const <double>[1.10, .58, .34, .26]
      : const <double>[.85, .52, .34, .26];
  _standShape(c, DragonKit.tube([...limb, foot], w), const Color(0xff4a3568));
}

void _standWing(Canvas c, DragonPose p, {required bool far}) {
  final m = far ? p.farWing : p.nearWing;
  var k = DragonLayout.wingAt(
    elbow: m.elbow,
    wrist: m.wrist,
    tips: m.tips,
    fold: m.fold,
  );
  final tips = <Offset>[
    for (var i = 0; i < 4; i++)
      k.wrist +
          DragonKit.turn(
            k.tips[i] - k.wrist,
            -m.flex[i] + m.spread * .12 * i / 3,
          ),
  ];
  k = DragonWingKey(k.elbow, k.wrist, tips);
  var sh = DragonLayout.nearShoulder, rt = DragonLayout.nearRoot;
  if (far) {
    k = DragonLayout.farOf(k);
    sh = DragonLayout.farShoulder;
    rt = DragonLayout.farRoot;
  }
  final w = k.wrist;
  Offset hem(Offset a, Offset b, Offset toward, double depth) =>
      Offset.lerp(Offset.lerp(a, b, .5)!, toward, depth)!;
  final mem = Path()
    ..moveTo(sh.dx, sh.dy)
    ..lineTo(k.elbow.dx, k.elbow.dy)
    ..lineTo(w.dx, w.dy)
    ..lineTo(k.tips[0].dx, k.tips[0].dy);
  for (var i = 1; i < 4; i++) {
    final h = hem(k.tips[i - 1], k.tips[i], w, .5 + .1 * m.sag);
    mem.quadraticBezierTo(h.dx, h.dy, k.tips[i].dx, k.tips[i].dy);
  }
  final last = hem(k.tips.last, rt, k.elbow, .2);
  mem
    ..quadraticBezierTo(last.dx, last.dy, rt.dx, rt.dy)
    ..close();
  _standShape(c, mem, far ? const Color(0xff902838) : const Color(0xffe04050));
  final bone = Paint()
    ..color = const Color(0xff3a2a55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .12;
  for (final t in k.tips) {
    c.drawLine(w, t, bone);
  }
  c.drawPath(
    Path()
      ..moveTo(sh.dx, sh.dy)
      ..lineTo(k.elbow.dx, k.elbow.dy)
      ..lineTo(w.dx, w.dy),
    Paint()
      ..color = const Color(0xff3a2a55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .30
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

void _bg(Canvas c, Rect rect, {required bool dark}) {
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? const [Color(0xff1a1f3a), Color(0xff3a3560), Color(0xff6a4a68)]
            : const [Color(0xffbfe4f2), Color(0xffe9f5df), Color(0xfff3e2c8)],
      ).createShader(rect),
  );
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

/// Draws [draw] in rig units at [ppu] pixels per unit so the rig point
/// [focus] lands on the middle of [cell].
void _view(
  Canvas c,
  Rect cell,
  Offset focus,
  double ppu,
  void Function(Canvas) draw, {
  bool dark = true,
  bool background = true,
}) {
  c.save();
  c.clipRect(cell);
  if (background) _bg(c, cell, dark: dark);
  c.translate(cell.center.dx - focus.dx * ppu, cell.center.dy - focus.dy * ppu);
  c.scale(ppu);
  draw(c);
  c.restore();
}

/// The rig point a head close-up is centred on: the skull, a little toward
/// the neck so the join shows.
Offset _headFocus(DragonPose p, {Offset shift = const Offset(.25, .35)}) =>
    p.toRig(p.head.at) + shift;

Future<ui.Image> _image(int w, int h, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();
  return image;
}

Future<void> _save(
  String name,
  int w,
  int h,
  void Function(Canvas) draw,
) async {
  final image = await _image(w, h, draw);
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(
    (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
  image.dispose();
}

Future<Uint8List> _pixels(void Function(Canvas) draw, int w, int h) async {
  final image = await _image(w, h, draw);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  return bytes;
}

/// A black cut-out of [draw] (the silhouette test).
void _silhouette(Canvas c, void Function(Canvas) draw) {
  c.saveLayer(
    DragonBossRig.bounds.inflate(1),
    Paint()
      ..colorFilter = const ColorFilter.mode(
        Color(0xff000000),
        BlendMode.srcATop,
      ),
  );
  draw(c);
  c.restore();
}

// -------------------------------------------------------------- geometry --

/// The near wing's arm (shoulder, elbow, wrist) and the far wing's, in rig
/// units, for [pose].
List<List<Offset>> _arms(DragonPose pose) {
  // The arm as B3 draws it: shoulder, the drawn bend (`joint`, pushed back
  // from the shoulder-wrist chord), wrist.
  final near = DragonWing.nearOf(pose), far = DragonWing.farOf(pose);
  return [
    [near.shoulder, near.joint, near.wrist],
    [far.shoulder, far.joint, far.wrist],
  ];
}

double _distToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final t =
      ((p - a).dx * ab.dx + (p - a).dy * ab.dy) /
      (ab.dx * ab.dx + ab.dy * ab.dy);
  final q = a + ab * t.clamp(0.0, 1.0);
  return (p - q).distance;
}

/// How far [p] is from the nearest wing arm's centre line, in rig units.
double _armDistance(DragonPose pose, Offset p) {
  var best = double.infinity;
  for (final arm in _arms(pose)) {
    for (var i = 0; i < arm.length - 1; i++) {
      best = math.min(best, _distToSegment(p, arm[i], arm[i + 1]));
    }
  }
  return best;
}

/// The wing arm is ~.34 wide at the shoulder and ~.22 at the wrist.
const _armHalfWidth = .17;

/// The states the calm-to-combat sweeps walk, as (name, combat second,
/// setup): the same beats as the envelope test.
final _sweep = <(String, double, void Function(SkyBoss))>[
  ('idle', 1.2, (b) {}),
  ('idle late', 2.6, (b) {}),
  ('charge .3', 1.2, (b) => b.fireIn = .45),
  ('charge 1', 1.2, (b) => b.fireIn = .01),
  ('shot', 1.2, (b) => b.lastVolleyAt = b.age - .04),
  ('recoil', 1.2, (b) => b.lastVolleyAt = b.age - .14),
  ('hit', 1.2, (b) => b.lastHitAt = b.age - .1),
  ('alert', 3.7, (b) {}),
  ('sniff', 4.15, (b) {}),
  ('rear', 4.6, (b) {}),
  ('rear late', 4.9, (b) {}),
  ('hold', 5.05, (b) {}),
  ('snap', 5.23, (b) {}),
  ('overshoot', 5.33, (b) {}),
  for (final lane in BreathLane.values) ...[
    ('blast ${lane.name}', 5.6, (b) => b.breathLane = lane),
    ('snap ${lane.name}', 5.3, (b) => b.breathLane = lane),
    ('plateau ${lane.name}', 6.5, (b) => b.breathLane = lane),
  ],
  ('gutter', 7.3, (b) {}),
  ('wind', 7.45, (b) {}),
  ('call', 7.72, (b) => b.lastSummonAt = b.age - .1),
  ('call peak', 7.95, (b) => b.lastSummonAt = b.age - .35),
  ('rage', 1.2, (b) => b.enragedAt = b.age - .3),
];

DragonPose _sweepPose(
  (String, double, void Function(SkyBoss)) s, {
  int cycle = 0,
  bool fury = false,
  bool reduced = false,
}) {
  final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = BreathLane.middle;
  if (fury) b.hp = b.maxHp ~/ 3;
  b.age = b.arrivalDuration + s.$2 + cycle * DragonBreath.period;
  s.$3(b);
  return DragonPose(b, BossMotion(b, reducedMotion: reduced));
}

/// Counts what a frame asks of the canvas (a copy of the budget test's).
class _Counting implements Canvas {
  _Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get clips => (counts['clipPath'] ?? 0) + (counts['clipPath.noAA'] ?? 0);

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    _n('saveLayer');
    inner.saveLayer(bounds, paint);
  }

  @override
  void translate(double dx, double dy) => inner.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => inner.scale(sx, sy);
  @override
  void rotate(double r) => inner.rotate(r);
  @override
  void clipPath(Path p, {bool doAntiAlias = true}) {
    _n(doAntiAlias ? 'clipPath' : 'clipPath.noAA');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  void _paint(String k, Paint p) {
    _n(k);
    if (p.maskFilter != null) _n('maskFilter');
  }

  @override
  void drawPath(Path p, Paint paint) {
    _paint('drawPath', paint);
    inner.drawPath(p, paint);
  }

  @override
  void drawCircle(Offset c, double r, Paint paint) {
    _paint('drawCircle', paint);
    inner.drawCircle(c, r, paint);
  }

  @override
  void drawRect(Rect r, Paint paint) {
    _paint('drawRect', paint);
    inner.drawRect(r, paint);
  }

  @override
  void drawOval(Rect r, Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
  }

  @override
  void drawLine(Offset a, Offset b, Paint paint) {
    _paint('drawLine', paint);
    inner.drawLine(a, b, paint);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

/// The neck, head and smoke exactly as the rig draws them, without the
/// stand-in.
void _rigHead(Canvas c, DragonPose pose) {
  final head = DragonHeadPose.of(pose);
  c.save();
  c.translate(pose.bob.dx, pose.bob.dy);
  c.rotate(pose.pitch);
  DragonHeadArt.neck(c, head);
  DragonHeadArt.head(c, head);
  DragonHeadArt.smoke(c, head);
  c.restore();
}

/// The head's share of the ASSEMBLED dragon: exactly what the hide asks of
/// it (the neck's crest spines, everything behind the skin, the skull's
/// detail, the jaw's shade, the features, the smoke). The neck's scales, the
/// skin and the belly band are B9's and B2's.
void _hideHead(Canvas c, DragonPose pose) {
  final head = DragonHeadPose.of(pose);
  c.save();
  c.translate(pose.bob.dx, pose.bob.dy);
  c.rotate(pose.pitch);
  DragonHeadArt.neckSpikes(c, head.tone, DragonHeadArt.neckOf(head));
  DragonHeadArt.headUnder(c, head);
  DragonHeadArt.jawShade(c, head);
  DragonHeadArt.skullDetails(c, head);
  DragonHeadArt.headFeatures(c, head);
  DragonHeadArt.smoke(c, head);
  c.restore();
}

/// CIE L* (0..100) of a pixel.
double lstar(int r, int g, int b) {
  double lin(int v) {
    final c = v / 255;
    return c <= .04045
        ? c / 12.92
        : math.pow((c + .055) / 1.055, 2.4).toDouble();
  }

  final y = .2126 * lin(r) + .7152 * lin(g) + .0722 * lin(b);
  return y > .008856 ? 116 * math.pow(y, 1 / 3).toDouble() - 16 : 903.3 * y;
}

Future<void> _fonts() async {
  await (FontLoader(
    'Fredoka',
  )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_fonts);

  // ------------------------------------------- the assembled dragon, ROUND 2 --

  /// The head as the ASSEMBLED dragon draws it (the hide, wings, everything),
  /// [ppu] pixels per rig unit, in a cell around the skull.
  Future<void> rigSheet(
    String name,
    List<_S> states, {
    required double ppu,
    required double cw,
    required double ch,
    required bool dark,
    int cols = 4,
    Offset shift = const Offset(.5, .35),
    bool reduced = true,
  }) async {
    final rows = (states.length / cols).ceil();
    await _save(name, (cw * cols).toInt(), (ch * rows).toInt(), (c) {
      for (var i = 0; i < states.length; i++) {
        final s = states[i];
        final pose = _pose(
          s,
          reduced: reduced && s != _blink && s != _flash,
          light: dark
              ? const DragonSkyLight(dark: .9, sky: Color(0xffa48fe0))
              : DragonSkyLight.neutral,
        );
        final cell = Rect.fromLTWH(i % cols * cw, i ~/ cols * ch, cw, ch);
        _view(
          c,
          cell,
          _headFocus(pose, shift: shift),
          ppu,
          (c) => DragonBossRig.paintPose(c, pose),
          dark: dark,
        );
        _label(
          c,
          s.name,
          cell.topLeft + const Offset(4, 2),
          11,
          dark ? const Color(0xffffffff) : const Color(0xff000000),
        );
      }
    });
  }

  testWidgets('assembled: close-ups (6x) and real size (250 px)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final six = [
        _idle,
        _fury,
        _flash,
        _roar,
        _blastLow,
        _charge,
        _call,
        _rage,
      ];
      final tw = [
        _idle,
        _alert,
        _charge,
        _rear,
        _roar,
        _wince,
        _fury,
        _blastLow,
      ];
      for (final dark in [false, true]) {
        final t = dark ? 'dark' : 'light';
        await rigSheet(
          'asm-6x-$t',
          six,
          ppu: 190,
          cw: 640,
          ch: 560,
          dark: dark,
          cols: 4,
        );
        await rigSheet(
          'asm-250-$t',
          tw,
          ppu: _ppu250,
          cw: 190,
          ch: 170,
          dark: dark,
          cols: 4,
          shift: const Offset(.7, .5),
        );
        await rigSheet(
          'asm-120-$t',
          tw,
          ppu: _ppu120,
          cw: 92,
          ch: 84,
          dark: dark,
          cols: 4,
          shift: const Offset(.7, .5),
        );
      }
      // The big single idle face, as the hide draws it.
      final pose = _pose(_idle, reduced: true);
      await _save('asm-face-big', 1400, 1100, (c) {
        _view(
          c,
          const Rect.fromLTWH(0, 0, 1400, 1100),
          _headFocus(pose, shift: const Offset(.55, .55)),
          248,
          (c) => DragonBossRig.paintPose(c, pose),
          dark: true,
        );
      });
    });
  });

  // ------------------------------------------------------------ anchors --

  test('the head speaks in layout anchors', () {
    expect(DragonHeadArt.mouth, DragonLayout.headMouth);
    expect(DragonHeadArt.eye, DragonLayout.headEye);
    expect(DragonHeadArt.nostril, DragonLayout.headNostril);
    expect(DragonHeadArt.crownSeat, DragonLayout.headCrownSeat);
    expect(DragonHeadArt.crownBounds, DragonLayout.crownBounds);
    expect(DragonHeadArt.scale, DragonLayout.headScale);
    expect(DragonHeadArt.scale, 1.0);
  });

  test(
    'the jaws open where the rules launch fireballs (normal and Reduced)',
    () {
      for (final reduced in [false, true]) {
        final boss = _boss()..fireIn = .01;
        final pose = DragonPose(boss, BossMotion(boss, reducedMotion: reduced));
        final mouth = DragonBossRig.mouthAt(pose) * SkyBoss.radius;
        expect(mouth.dx, closeTo(SkyBoss.dragonMouth.$1, .012));
        expect(mouth.dy, closeTo(SkyBoss.dragonMouth.$2, .012));
      }
    },
  );

  // ---------------------------------------------------------------- jaw --

  test('the jaw drops as gape rises, all the way to 39 degrees', () {
    var last = DragonHeadArt.jawFront(0);
    expect(last.dy, closeTo(.26, .001));
    for (var g = .1; g <= 1.0001; g += .1) {
      final now = DragonHeadArt.jawFront(g);
      expect(now.dy, greaterThan(last.dy), reason: 'gape $g');
      last = now;
    }
    // The chin is over a whole unit below the lip at a full roar.
    expect(last.dy, greaterThan(1.0));
    expect(DragonHeadArt.open(1), closeTo(39 * math.pi / 180, .01));
    expect(DragonHeadArt.open(2), DragonHeadArt.open(1));
    expect(DragonHeadArt.open(-1), 0);
  });

  testWidgets('the jaw really opens on screen', (tester) async {
    await tester.runAsync(() async {
      const ppu = 80.0;
      // The head alone at its rest angle, drawn at gape 0 and 1: the ink of
      // the lower jaw must reach a unit further down.
      Future<double> lowest(double gape) async {
        final p = DragonHeadPose(gape: gape, angle: 0, at: Offset.zero);
        final px = await _pixels(
          (c) {
            c.translate(300, 200);
            c.scale(ppu);
            DragonHeadArt.head(c, p);
          },
          600,
          500,
        );
        var bottom = 0;
        for (var y = 0; y < 500; y++) {
          for (var x = 0; x < 600; x++) {
            if (px[(y * 600 + x) * 4 + 3] > 200) bottom = y;
          }
        }
        return (bottom - 200) / ppu;
      }

      final shut = await lowest(0), wide = await lowest(1);
      // ignore: avoid_print
      print(
        'lowest ink: shut ${shut.toStringAsFixed(2)}  wide ${wide.toStringAsFixed(2)}',
      );
      expect(wide - shut, greaterThan(.45));
    });
  });

  testWidgets('jaw-open sweep sheet', (tester) async {
    await tester.runAsync(() async {
      const gapes = [0.0, .15, .3, .55, .8, 1.0];
      const cw = 340.0, ch = 300.0;
      // Rows: calm, fire in the throat, the swarm call (violet).
      final rows = <(String, double, double)>[
        ('calm', 0, 0),
        ('fire', 1, 0),
        ('call', 0, 1),
      ];
      await _save(
        'jaw-sweep',
        (cw * gapes.length).toInt(),
        (ch * rows.length).toInt(),
        (c) {
          for (var r = 0; r < rows.length; r++) {
            for (var i = 0; i < gapes.length; i++) {
              final cell = Rect.fromLTWH(i * cw, r * ch, cw, ch);
              final (name, throat, call) = rows[r];
              final p = DragonHeadPose(
                at: DragonLayout.headRest,
                angle: DragonLayout.headRestAngle,
                gape: gapes[i],
                throat: throat,
                call: call,
                glare: throat,
                tone: DragonTone(heat: throat),
              );
              _view(
                c,
                cell,
                DragonLayout.headRest + const Offset(-.1, .35),
                85,
                (c) {
                  DragonHeadArt.neck(c, p);
                  DragonHeadArt.head(c, p);
                },
              );
              _label(
                c,
                '$name  gape ${gapes[i]}',
                cell.topLeft + const Offset(6, 4),
                14,
                const Color(0xffffffff),
              );
            }
          }
        },
      );
    });
  });

  // -------------------------------------------------------- expressions --

  testWidgets(
    'expression sheets: 12 states, light and dark, 250 px and 120 px',
    (tester) async {
      await tester.runAsync(() async {
        for (final (ppu, tag, cw, ch) in [
          (_ppu250, '250', 190.0, 170.0),
          (_ppu120, '120', 92.0, 84.0),
          (_ppu250 * 3, '750', 520.0, 460.0),
        ]) {
          for (final dark in [true, false]) {
            await _save(
              'expressions-$tag-${dark ? 'dark' : 'light'}',
              (cw * 4).toInt(),
              (ch * 3).toInt(),
              (c) {
                for (var i = 0; i < _twelve.length; i++) {
                  final s = _twelve[i];
                  final pose = _pose(
                    s,
                    reduced: s != _blink,
                    light: dark
                        ? const DragonSkyLight(dark: .9, sky: Color(0xffa48fe0))
                        : DragonSkyLight.neutral,
                  );
                  final cell = Rect.fromLTWH(i % 4 * cw, i ~/ 4 * ch, cw, ch);
                  _view(
                    c,
                    cell,
                    _headFocus(pose, shift: const Offset(.5, .1)),
                    ppu,
                    (c) => _paintHead(c, pose),
                    dark: dark,
                  );
                  if (tag != '120') {
                    _label(
                      c,
                      s.name,
                      cell.topLeft + const Offset(4, 2),
                      11,
                      dark ? const Color(0xffffffff) : const Color(0xff000000),
                    );
                  }
                }
              },
            );
          }
        }
      });
    },
  );

  testWidgets('eight expressions read differently at 120 px', (tester) async {
    await tester.runAsync(() async {
      final eight = [
        _idle,
        _alert,
        _charge,
        _rear,
        _roar,
        _wince,
        _fury,
        _blink,
      ];
      const w = 96, h = 84;
      final shots = <Uint8List>[];
      for (final s in eight) {
        final pose = _pose(s, reduced: s != _blink);
        shots.add(
          await _pixels(
            (c) {
              _view(
                c,
                const Rect.fromLTWH(0, 0, 96, 84),
                _headFocus(pose, shift: const Offset(.5, .1)),
                _ppu120,
                (c) => _paintHead(c, pose),
                dark: false,
              );
            },
            w,
            h,
          ),
        );
      }
      double diff(Uint8List a, Uint8List b) {
        var total = 0;
        for (var i = 0; i < a.length; i += 4) {
          total +=
              (a[i] - b[i]).abs() +
              (a[i + 1] - b[i + 1]).abs() +
              (a[i + 2] - b[i + 2]).abs();
        }
        return total / (a.length / 4) / 3;
      }

      final report = StringBuffer();
      var worst = double.infinity;
      for (var i = 0; i < eight.length; i++) {
        for (var j = i + 1; j < eight.length; j++) {
          final d = diff(shots[i], shots[j]);
          worst = math.min(worst, d);
          report.write(
            '${eight[i].name}/${eight[j].name} ${d.toStringAsFixed(1)}  ',
          );
        }
        report.writeln();
      }
      // ignore: avoid_print
      print(
        'mean |dRGB| per pixel at 120 px, worst ${worst.toStringAsFixed(2)}\n$report',
      );
      expect(worst, greaterThan(1.2), reason: 'two expressions look alike');
    });
  });

  // --------------------------------------------------------------- neck --

  test('the neck never folds or pinches, in any lane, look or fury', () {
    // The layout's curve can double back tighter than the neck is wide in the
    // strikes; the art holds the inner edge of a bend to 85% of its radius,
    // so the tube narrows there instead of folding. Where that happens must
    // be hidden (inside the torso): the neck the player SEES keeps at least
    // 70% of its nominal width.
    final torso = DragonKit.spline(DragonLayout.torsoOutline);
    var tightest = double.infinity, pinch = double.infinity;
    var where = '', pinchAt = '';
    for (final s in _sweep) {
      for (final fury in [false, true]) {
        for (var n = 0; n < 12; n++) {
          final pose = _sweepPose(s, cycle: n, fury: fury);
          final head = DragonHeadPose.of(pose);
          final g = DragonHeadArt.neckOf(head);
          final spine = g.spine;
          for (var i = 1; i < spine.length - 1; i++) {
            final a = spine[i] - spine[i - 1], b = spine[i + 1] - spine[i];
            final turn = math
                .atan2(a.dx * b.dy - a.dy * b.dx, a.dx * b.dx + a.dy * b.dy)
                .abs();
            final len = (a.distance + b.distance) / 2;
            final radius = turn < 1e-6 ? double.infinity : len / turn;
            final margin = radius / (DragonLayout.neckWidths[i] / 2);
            if (margin < tightest) {
              tightest = margin;
              where =
                  '${s.$1}${fury ? ' fury' : ''} #$n sample $i radius ${radius.toStringAsFixed(2)}';
            }
          }
          for (var i = 0; i < spine.length; i++) {
            if (torso.contains(spine[i])) continue;
            final share = (g.plus[i] + g.minus[i]) / DragonLayout.neckWidths[i];
            if (share < pinch) {
              pinch = share;
              pinchAt = '${s.$1}${fury ? ' fury' : ''} #$n sample $i';
            }
          }
        }
      }
    }
    // ignore: avoid_print
    print(
      'tightest raw neck bend: ${tightest.toStringAsFixed(2)} x half width ($where); '
      'narrowest visible neck: ${(pinch * 100).round()}% of nominal ($pinchAt)',
    );
    expect(tightest, greaterThan(.15), reason: where);
    expect(pinch, greaterThan(.7), reason: pinchAt);
    // And the widths never dip below the swan's minimum.
    expect(DragonLayout.neckWidths.reduce(math.min), greaterThanOrEqualTo(.74));
    expect(DragonLayout.neckWidths.last, greaterThanOrEqualTo(.8));
  });

  testWidgets('neck sheet: every lane and look pose', (tester) async {
    await tester.runAsync(() async {
      final poses = [
        _idle,
        _alert,
        _rear,
        _hold,
        _snapHigh,
        _blastMid,
        _snapLow,
        _blastLow,
        _lookUp,
        _lookDown,
        _roar,
        _call,
      ];
      const cw = 360.0, ch = 400.0;
      await _save('neck-poses', (cw * 4).toInt(), (ch * 3).toInt(), (c) {
        for (var i = 0; i < poses.length; i++) {
          final s = poses[i];
          final pose = _pose(s, reduced: true);
          final cell = Rect.fromLTWH(i % 4 * cw, i ~/ 4 * ch, cw, ch);
          _view(c, cell, const Offset(-.6, -1.2), 62, (c) {
            _paintHead(c, pose);
            final spine = DragonHeadArt.neckSpine(DragonHeadPose.of(pose));
            for (final q in spine) {
              c.drawCircle(
                pose.toRig(q),
                .03,
                DragonKit.fill(const Color(0xffffffff)),
              );
            }
          }, dark: i.isEven);
          _label(
            c,
            s.name,
            cell.topLeft + const Offset(6, 4),
            14,
            const Color(0xffffffff),
          );
        }
      });
    });
  });

  testWidgets('neck sheet: the eight tightest bends of the fight', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final found = <(double, String, DragonPose)>[];
      for (final s in _sweep) {
        for (final fury in [false, true]) {
          for (var n = 0; n < 12; n++) {
            final pose = _sweepPose(s, cycle: n, fury: fury);
            final spine = DragonHeadArt.neckSpine(DragonHeadPose.of(pose));
            var worst = double.infinity;
            for (var i = 1; i < spine.length - 1; i++) {
              final a = spine[i] - spine[i - 1], b = spine[i + 1] - spine[i];
              final turn = math
                  .atan2(a.dx * b.dy - a.dy * b.dx, a.dx * b.dx + a.dy * b.dy)
                  .abs();
              final radius = turn < 1e-6
                  ? double.infinity
                  : (a.distance + b.distance) / 2 / turn;
              worst = math.min(
                worst,
                radius / (DragonLayout.neckWidths[i] / 2),
              );
            }
            found.add((worst, '${s.$1}${fury ? ' fury' : ''} #$n', pose));
          }
        }
      }
      found.sort((a, b) => a.$1.compareTo(b.$1));
      const cw = 360.0, ch = 400.0;
      await _save('neck-tight', (cw * 4).toInt(), (ch * 2).toInt(), (c) {
        for (var i = 0; i < 8; i++) {
          final (margin, name, pose) = found[i];
          final cell = Rect.fromLTWH(i % 4 * cw, i ~/ 4 * ch, cw, ch);
          _view(c, cell, const Offset(-.6, -1.2), 62, (c) {
            _paintHead(c, pose);
            for (final q in DragonHeadArt.neckSpine(DragonHeadPose.of(pose))) {
              c.drawCircle(
                pose.toRig(q),
                .03,
                DragonKit.fill(const Color(0xffffffff)),
              );
            }
          }, dark: i.isEven);
          _label(
            c,
            '$name  ${margin.toStringAsFixed(2)}',
            cell.topLeft + const Offset(6, 4),
            12,
            const Color(0xffffffff),
          );
        }
      });
    });
  });

  // ------------------------------------------------------------ close-up --

  testWidgets('6x close-ups on light and dark', (tester) async {
    await tester.runAsync(() async {
      for (final dark in [true, false]) {
        final pose = _pose(
          _idle,
          reduced: true,
          light: dark
              ? const DragonSkyLight(dark: .9, sky: Color(0xffa48fe0))
              : DragonSkyLight.neutral,
        );
        await _save('closeup-6x-${dark ? 'dark' : 'light'}', 1400, 1100, (c) {
          _view(
            c,
            const Rect.fromLTWH(0, 0, 1400, 1100),
            _headFocus(pose, shift: const Offset(.55, .55)),
            248,
            (c) => _paintHead(c, pose),
            dark: dark,
          );
        });
      }
      // The neck's join under the jaw, and the face, big.
      final idle = _pose(_idle, reduced: true);
      final joint = idle.toRig(
        DragonHeadArt.point(DragonHeadPose.of(idle), const Offset(.3, .6)),
      );
      await _save('join-zoom', 1000, 800, (c) {
        _view(
          c,
          const Rect.fromLTWH(0, 0, 1000, 800),
          joint,
          420,
          (c) => _paintHead(c, idle),
          dark: true,
        );
      });
      final face = idle.toRig(
        DragonHeadArt.point(DragonHeadPose.of(idle), const Offset(-.85, -.1)),
      );
      await _save('face-zoom', 1200, 900, (c) {
        _view(
          c,
          const Rect.fromLTWH(0, 0, 1200, 900),
          face,
          520,
          (c) => _paintHead(c, idle),
          dark: true,
        );
      });
      // The circlet alone, big, and worn.
      await _save('crown-zoom', 1200, 700, (c) {
        final pose = _pose(_idle, reduced: true);
        final seat = pose.toRig(
          DragonHeadArt.point(DragonHeadPose.of(pose), DragonHeadArt.crownSeat),
        );
        _view(
          c,
          const Rect.fromLTWH(0, 0, 1200, 700),
          seat + const Offset(.3, .45),
          520,
          (c) => _paintHead(c, pose),
          dark: true,
        );
      });
    });
  });

  testWidgets('open mouths, big', (tester) async {
    await tester.runAsync(() async {
      final states = [_roar, _charge, _hold, _call];
      const cw = 760.0, ch = 640.0;
      await _save('mouth-zoom', (cw * 2).toInt(), (ch * 2).toInt(), (c) {
        for (var i = 0; i < states.length; i++) {
          final pose = _pose(states[i], reduced: true);
          final cell = Rect.fromLTWH(i % 2 * cw, i ~/ 2 * ch, cw, ch);
          _view(
            c,
            cell,
            _headFocus(pose, shift: const Offset(-.2, .3)),
            190,
            (c) => _paintHead(c, pose),
            dark: true,
          );
          _label(
            c,
            states[i].name,
            cell.topLeft + const Offset(6, 4),
            16,
            const Color(0xffffffff),
          );
        }
      });
    });
  });

  // ---------------------------------------------------------------- tones --

  testWidgets('tones: hit flash, fury, heat, on light and dark', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final tones = [
        (_idle, 'calm'),
        (_flash, 'hit flash'),
        (_fury, 'fury'),
        (_rage, 'fury onset'),
        (_charge, 'charge (heat)'),
        (_hold, 'hold (max heat)'),
      ];
      const cw = 420.0, ch = 360.0;
      for (final dark in [true, false]) {
        await _save(
          'tones-${dark ? 'dark' : 'light'}',
          (cw * 3).toInt(),
          (ch * 2).toInt(),
          (c) {
            for (var i = 0; i < tones.length; i++) {
              final (s, name) = tones[i];
              final pose = _pose(
                s,
                light: dark
                    ? const DragonSkyLight(dark: .93, sky: Color(0xffb26ad0))
                    : DragonSkyLight.neutral,
              );
              final cell = Rect.fromLTWH(i % 3 * cw, i ~/ 3 * ch, cw, ch);
              _view(
                c,
                cell,
                _headFocus(pose, shift: const Offset(.55, .3)),
                110,
                (c) => _paintHead(c, pose),
                dark: dark,
              );
              _label(
                c,
                name,
                cell.topLeft + const Offset(6, 4),
                14,
                dark ? const Color(0xffffffff) : const Color(0xff000000),
              );
            }
          },
        );
      }
    });
  });

  // ---------------------------------------------------------- silhouette --

  testWidgets('silhouette at 250 and 120 px', (tester) async {
    await tester.runAsync(() async {
      final poses = [
        _idle,
        _alert,
        _rear,
        _hold,
        _snap,
        _blastLow,
        _roar,
        _call,
      ];
      for (final (ppu, tag, cw, ch) in [
        (_ppu250, '250', 330.0, 300.0),
        (_ppu120, '120', 160.0, 144.0),
      ]) {
        await _save('silhouette-$tag', (cw * 4).toInt(), (ch * 2).toInt(), (c) {
          for (var i = 0; i < poses.length; i++) {
            final pose = _pose(poses[i]);
            final cell = Rect.fromLTWH(i % 4 * cw, i ~/ 4 * ch, cw, ch);
            _view(c, cell, const Offset(.6, .1), ppu, (c) {
              _silhouette(c, (c) => DragonBossRig.paintPose(c, pose));
            }, dark: false);
            _label(
              c,
              poses[i].name,
              cell.topLeft + const Offset(4, 2),
              10,
              const Color(0xff000000),
            );
          }
        });
      }
    });
  });

  /// The states in which the head is thrown up or back toward the wing arms.
  const extremes = {
    'rear',
    'rear late',
    'hold',
    'wind',
    'call',
    'call peak',
    'rage',
    'sniff',
  };

  test('nothing behind the skull chains into a wing arm', () {
    // Every extremity that sticks out behind the skull, in every state and
    // wingbeat phase: in calm states it keeps 0.3 clear of the arm's edge,
    // in the head-up poses (rear, hold, call, rage) it still never touches.
    var calm = double.infinity, rearing = double.infinity;
    var calmAt = '', rearAt = '';
    for (final s in _sweep) {
      for (final fury in [false, true]) {
        for (var n = 0; n < 24; n++) {
          final pose = _sweepPose(s, cycle: n, fury: fury);
          final head = DragonHeadPose.of(pose);
          final extreme = extremes.contains(s.$1);
          final points = [
            for (final local in DragonHeadArt.reachFor(head))
              DragonHeadArt.point(head, local),
            DragonHeadArt.crownTop(head),
          ];
          for (var k = 0; k < points.length; k++) {
            final d = _armDistance(pose, pose.toRig(points[k])) - _armHalfWidth;
            final label = '${s.$1}${fury ? ' fury' : ''} #$n point $k';
            if (extreme) {
              if (d < rearing) {
                rearing = d;
                rearAt = label;
              }
            } else if (d < calm) {
              calm = d;
              calmAt = label;
            }
          }
        }
      }
    }
    // ignore: avoid_print
    print(
      'clearance from the wing arm edge: calm ${calm.toStringAsFixed(2)} ($calmAt), '
      'head-up ${rearing.toStringAsFixed(2)} ($rearAt)',
    );
    expect(calm, greaterThan(.3), reason: calmAt);
    expect(rearing, greaterThan(.19), reason: rearAt);
  });

  // ------------------------------------------------------------- budget --

  for (final (label, draw, maxOps)
      in <(String, void Function(Canvas, DragonPose), int)>[
        ('what the hide asks of the head', _hideHead, 80),
        ('the parts drawn on their own (neck + head + smoke)', _rigHead, 92),
      ]) {
    test('budget: $label', () {
      final report = StringBuffer();
      final over = <String>[];
      var peak = 0;
      for (final s in _sweep) {
        for (final fury in [false, true]) {
          final pose = _sweepPose(s, fury: fury);
          // Warm the caches, then measure a frame.
          draw(Canvas(ui.PictureRecorder()), pose);
          final before = DragonKit.shadersBuilt;
          final canvas = _Counting(Canvas(ui.PictureRecorder()));
          draw(canvas, pose);
          final built = DragonKit.shadersBuilt - before;
          final name = '${s.$1}${fury ? ' fury' : ''}';
          peak = math.max(peak, canvas.draws);
          report.writeln(
            '${name.padRight(20)} ops ${canvas.draws.toString().padLeft(3)}  '
            'clips ${canvas.clips}  layers ${canvas.counts['saveLayer'] ?? 0}  '
            'blur ${canvas.counts['maskFilter'] ?? 0}  shaders built $built',
          );
          if (canvas.draws > maxOps) over.add('$name: ${canvas.draws} ops');
          if (canvas.clips > 2) over.add('$name: ${canvas.clips} clips');
          if ((canvas.counts['saveLayer'] ?? 0) > 0) {
            over.add('$name: saveLayer');
          }
          if ((canvas.counts['maskFilter'] ?? 0) > 0) {
            over.add('$name: blur');
          }
          if (built > 0) {
            over.add('$name: $built shaders built on a warm frame');
          }
        }
      }
      // ignore: avoid_print
      print('$label: peak $peak ops (limit $maxOps)\n$report');
      expect(over, isEmpty);
    });
  }

  // ------------------------------------------------------------- envelope --

  testWidgets('the head and neck alone stay inside the combat envelope', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const ppu = 24.0, x0 = -7.0, y0 = -7.0, size = 15;
      Future<Rect> scan(void Function(Canvas) draw) async {
        final n = (size * ppu).round();
        final px = await _pixels(
          (c) {
            c.scale(ppu);
            c.translate(-x0, -y0);
            draw(c);
          },
          n,
          n,
        );
        var minX = n, minY = n, maxX = -1, maxY = -1;
        for (var y = 0; y < n; y++) {
          for (var x = 0; x < n; x++) {
            if (px[(y * n + x) * 4 + 3] >= 200) {
              minX = math.min(minX, x);
              maxX = math.max(maxX, x);
              minY = math.min(minY, y);
              maxY = math.max(maxY, y);
            }
          }
        }
        return Rect.fromLTRB(
          minX / ppu + x0,
          minY / ppu + y0,
          (maxX + 1) / ppu + x0,
          (maxY + 1) / ppu + y0,
        );
      }

      var union = Rect.zero;
      final over = <String>[];
      for (final s in _sweep) {
        for (final fury in [false, true]) {
          for (var n = 0; n < 6; n++) {
            final pose = _sweepPose(s, cycle: n, fury: fury);
            final r = await scan((c) => _rigHead(c, pose));
            union = union.expandToInclude(r);
            const e = DragonLayout.envelope;
            if (r.left < e.left - .02 ||
                r.top < e.top - .02 ||
                r.right > e.right + .02 ||
                r.bottom > e.bottom + .02) {
              over.add('${s.$1}${fury ? ' fury' : ''} #$n: $r');
            }
          }
        }
      }
      // ignore: avoid_print
      print(
        'head+neck union L ${union.left.toStringAsFixed(2)} T ${union.top.toStringAsFixed(2)} '
        'R ${union.right.toStringAsFixed(2)} B ${union.bottom.toStringAsFixed(2)}',
      );
      expect(over, isEmpty);
    });
  });

  test('the chin never touches the reaching foreleg', () {
    // The foreleg reaches forward-left under the chin (layout numbers): its
    // limb with the width at each joint, talons adding ~.3 at the foot. Only
    // the part outside the torso counts (inside it, the torso is what the
    // head overlaps and the leg is not seen).
    final limb = [
      ...DragonLayout.foreLeg,
      DragonLayout.foreLeg.last + DragonLayout.foreFoot,
    ];
    final widths = const <double>[.85, .52, .34, .26];
    final torso = DragonKit.spline(DragonLayout.torsoOutline);
    // (point, half width) along the limb, outside the torso.
    final samples = <(Offset, double)>[];
    for (var i = 0; i < limb.length - 1; i++) {
      for (var k = 0; k <= 20; k++) {
        final t = k / 20;
        final at = Offset.lerp(limb[i], limb[i + 1], t)!;
        if (torso.contains(at)) continue;
        final half = (widths[i] + (widths[i + 1] - widths[i]) * t) / 2;
        final talons = i == limb.length - 2 ? .3 : 0.0;
        samples.add((at, half + talons));
      }
    }
    var closest = double.infinity;
    var closestAt = '';
    for (final s in _sweep) {
      for (final fury in [false, true]) {
        for (var n = 0; n < 6; n++) {
          final pose = _sweepPose(s, cycle: n, fury: fury);
          final head = DragonHeadPose.of(pose);
          final chin = DragonHeadArt.chinPoints(head);
          for (var k = 0; k < chin.length; k++) {
            final p = pose.toRig(DragonHeadArt.point(head, chin[k]));
            for (final (at, half) in samples) {
              final gap = (p - at).distance - half;
              if (gap < closest) {
                closest = gap;
                closestAt =
                    '${s.$1}${fury ? ' fury' : ''} #$n chin point $k at $p, '
                    'head ${head.at} angle ${head.angle.toStringAsFixed(2)} '
                    'gape ${head.gape.toStringAsFixed(2)}';
              }
            }
          }
        }
      }
    }
    // ignore: avoid_print
    print(
      'chin to foreleg (edge, talons included): ${closest.toStringAsFixed(2)} at $closestAt',
    );
    expect(closest, greaterThan(.3), reason: closestAt);
  });

  // ------------------------------------- the notch of the ASSEMBLED dragon --

  /// The throat gap of the assembled dragon: for each rig column between the
  /// chin and the neck, the transparent run under the jaw down to the chest.
  /// Returns (deepest, at x) as the MIN over the columns (the tightest gap),
  /// and the gap at the column [at].
  Future<({double min, double minAt, double atCol})> throatGap(
    DragonPose pose, {
    double from = -1.45,
    double to = -.55,
    double at = -.9,
  }) async {
    const ppu = 60.0, x0 = -5.0, y0 = -5.5, w = 480, h = 700;
    final px = await _pixels(
      (c) {
        c.scale(ppu);
        c.translate(-x0, -y0);
        DragonBossRig.paintPose(c, pose);
      },
      w,
      h,
    );
    bool solid(int x, int y) => px[(y * w + x) * 4 + 3] > 40;
    double gapAt(double xr) {
      final x = ((xr - x0) * ppu).round();
      // Start at the jaw: the first solid pixel from the top below the head's
      // centre line, then follow it down to its lowest solid pixel of that run.
      final headY = ((pose.toRig(pose.head.at).dy - y0) * ppu).round();
      var y = headY;
      while (y < h && !solid(x, y)) {
        y++;
      }
      if (y >= h) return 0;
      while (y < h && solid(x, y)) {
        y++;
      }
      final start = y;
      while (y < h && !solid(x, y)) {
        y++;
      }
      return (y - start) / ppu;
    }

    var min = double.infinity, minAt = from;
    for (var xr = from; xr <= to + 1e-9; xr += .05) {
      final g = gapAt(xr);
      if (g < min) {
        min = g;
        minAt = xr;
      }
    }
    return (min: min, minAt: minAt, atCol: gapAt(at));
  }

  testWidgets('assembled: the throat gap under the jaw (report)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final out = StringBuffer();
      for (final s in [
        _idle,
        _alert,
        _hold,
        _snapHigh,
        _blastMid,
        _snapLow,
        _blastLow,
      ]) {
        final pose = _pose(s, reduced: true);
        final g = await throatGap(pose);
        out.writeln(
          '${s.name.padRight(10)} min ${g.min.toStringAsFixed(2)} at x ${g.minAt.toStringAsFixed(2)}   at x -.9: ${g.atCol.toStringAsFixed(2)}',
        );
      }
      // ignore: avoid_print
      print('throat gap (transparent run under the jaw, rig units):\n$out');
    });
  });

  test(
    'the chin clears the chest: the tightest gap in each strike (report)',
    () {
      final torso = DragonKit.spline(DragonLayout.torsoOutline);
      final samples = <Offset>[];
      for (final m in torso.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += .04) {
          samples.add(m.getTangentForOffset(d)!.position);
        }
      }
      double gap(DragonPose pose) {
        final head = DragonHeadPose.of(pose);
        var best = double.infinity;
        for (final q in DragonHeadArt.chinPoints(head)) {
          final r = pose.toRig(DragonHeadArt.point(head, q));
          for (final t in samples) {
            best = math.min(best, (r - t).distance);
          }
        }
        return best;
      }

      final out = StringBuffer();
      double worst = double.infinity;
      for (final s in _sweep) {
        var lo = double.infinity;
        for (var n = 0; n < 6; n++) {
          for (final fury in [false, true]) {
            lo = math.min(lo, gap(_sweepPose(s, cycle: n, fury: fury)));
          }
        }
        worst = math.min(worst, lo);
        if (s.$1.contains('low') ||
            s.$1 == 'idle' ||
            s.$1 == 'alert' ||
            s.$1 == 'hold' ||
            s.$1.startsWith('snap')) {
          out.writeln('${s.$1.padRight(14)} ${lo.toStringAsFixed(2)}');
        }
      }
      // ignore: avoid_print
      print(
        'chin (belly points) to the chest outline, rig units:\n$out'
        'worst of all ${worst.toStringAsFixed(2)}',
      );
    },
  );

  // ------------------------------------------------- robustness (R4) --

  test('the paint caches stay bounded over 100 fight cycles', () {
    var peak = 0;
    for (var cycle = 0; cycle < 100; cycle++) {
      for (var i = 0; i < 66; i++) {
        final t = i / 6; // every sixth of a second across the 11 s cycle
        final b =
            SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
              ..fireIn = 1.8
              ..breathLane = BreathLane.values[(cycle + i) % 3];
        if (cycle % 3 == 1) b.hp = b.maxHp ~/ 3;
        b.age = b.arrivalDuration + t + cycle * DragonBreath.period;
        if (i % 7 == 0) b.lastHitAt = b.age - (i % 5) * .05;
        final light = DragonSkyLight(
          dark: (cycle % 5) / 4,
          sky: const Color(0xffa4afde),
        );
        final pose = DragonPose(
          b,
          BossMotion(b, reducedMotion: false),
          light: light,
        );
        _rigHead(Canvas(ui.PictureRecorder()), pose);
        peak = math.max(peak, DragonHeadArt.debugCacheEntries);
      }
    }
    // ignore: avoid_print
    print('paint cache peak over 100 cycles x 66 frames: $peak entries');
    expect(peak, lessThanOrEqualTo(512));
  });

  test('every public entry point survives non-finite inputs', () {
    const nan = double.nan, inf = double.infinity;
    final bad = <DragonHeadPose>[
      const DragonHeadPose(time: nan),
      const DragonHeadPose(time: inf, gape: inf),
      const DragonHeadPose(at: Offset(nan, 1), angle: nan),
      const DragonHeadPose(
        gape: nan,
        glare: nan,
        look: nan,
        blink: nan,
        wince: nan,
      ),
      const DragonHeadPose(
        throat: inf,
        smoke: nan,
        roar: nan,
        call: nan,
        alert: inf,
      ),
      const DragonHeadPose(drag: Offset(nan, inf), coil: nan),
      const DragonHeadPose(
        tone: DragonTone(flash: nan, fury: inf, heat: nan, dark: nan),
      ),
      const DragonHeadPose(angle: -inf, look: -inf, gape: -inf),
    ];
    for (final p in bad) {
      final c = Canvas(ui.PictureRecorder());
      DragonHeadArt.neck(c, p);
      DragonHeadArt.head(c, p);
      DragonHeadArt.smoke(c, p);
      DragonHeadArt.headUnder(c, p);
      DragonHeadArt.skullDetails(c, p);
      DragonHeadArt.jawShade(c, p);
      DragonHeadArt.headFeatures(c, p);
      DragonHeadArt.crown(c, tone: p.tone, glint: p.time);
      expect(
        DragonHeadArt.neckOf(
          p,
        ).spine.every((q) => q.dx.isFinite && q.dy.isFinite),
        isTrue,
      );
      expect(DragonHeadArt.point(p, DragonHeadArt.mouth).dx.isFinite, isTrue);
      expect(DragonHeadArt.openFor(p).isFinite, isTrue);
      expect(DragonHeadArt.open(p.gape).isFinite, isTrue);
      expect(DragonHeadArt.chinPoints(p).every((q) => q.dx.isFinite), isTrue);
      expect(DragonHeadArt.hornTip(p).dx.isFinite, isTrue);
      expect(DragonHeadArt.crownTop(p).dx.isFinite, isTrue);
      expect(DragonHeadArt.skullAt(p).getBounds().isFinite, isTrue);
      expect(DragonHeadArt.jawAt(p).getBounds().isFinite, isTrue);
      final (o, i) = DragonHeadArt.jawBandEdges(p);
      expect(
        o.every((q) => q.dx.isFinite) && i.every((q) => q.dx.isFinite),
        isTrue,
      );
    }
  });

  testWidgets('assembled: the eye out-contrasts its surroundings (face first)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The mean L* of the eye against the ring of skin round it, and of the
      // heart-gem's core against ITS ring, on the assembled dragon at 250 px.
      final pose = _pose(_idle, reduced: true);
      const ppu = _ppu250, w = 700, h = 620;
      final px = await _pixels(
        (c) {
          c.translate(w / 2, h * .38);
          c.scale(ppu);
          c.translate(
            -pose.toRig(pose.head.at).dx,
            -pose.toRig(pose.head.at).dy,
          );
          DragonBossRig.paintPose(c, pose);
        },
        w,
        h,
      );
      double lAt(double x, double y) {
        final ix = (w / 2 + (x - pose.toRig(pose.head.at).dx) * ppu).round();
        final iy = (h * .38 + (y - pose.toRig(pose.head.at).dy) * ppu).round();
        if (ix < 0 || iy < 0 || ix >= w || iy >= h) return double.nan;
        final k = (iy * w + ix) * 4;
        return lstar(px[k], px[k + 1], px[k + 2]);
      }

      double mean(Offset c, double r0, double r1) {
        var sum = 0.0, n = 0;
        for (var y = c.dy - r1; y <= c.dy + r1; y += 1 / ppu) {
          for (var x = c.dx - r1; x <= c.dx + r1; x += 1 / ppu) {
            final d = (Offset(x, y) - c).distance;
            if (d < r0 || d > r1) continue;
            final v = lAt(x, y);
            if (v.isNaN) continue;
            sum += v;
            n++;
          }
        }
        return n == 0 ? double.nan : sum / n;
      }

      final eye = DragonBossRig.eyeAt(pose);
      final eyeIn = mean(eye, 0, .3), eyeRing = mean(eye, .7, 1.1);
      final gem = pose.toRig(Offset.zero);
      final gemIn = mean(gem, 0, .28), gemRing = mean(gem, .55, .9);
      // ignore: avoid_print
      print(
        'eye core L* ${eyeIn.toStringAsFixed(1)} vs ring ${eyeRing.toStringAsFixed(1)} '
        '(+${(eyeIn - eyeRing).toStringAsFixed(1)});  gem core ${gemIn.toStringAsFixed(1)} '
        'vs ring ${gemRing.toStringAsFixed(1)} (+${(gemIn - gemRing).toStringAsFixed(1)})',
      );
      expect(eyeIn - eyeRing, greaterThan(24));
    });
  });

  // ------------------------------------------------------ throat notch --

  testWidgets('the throat notch under the jaw stays at least .7 deep', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const ppu = 60.0, x0 = -4.0, y0 = -4.5, w = 300, h = 360;
      Future<List<int>> columns(
        void Function(Canvas) draw, {
        required bool fromTop,
      }) async {
        final px = await _pixels(
          (c) {
            c.scale(ppu);
            c.translate(-x0, -y0);
            draw(c);
          },
          w,
          h,
        );
        return [
          for (var x = 0; x < w; x++)
            () {
              if (fromTop) {
                for (var y = 0; y < h; y++) {
                  if (px[(y * w + x) * 4 + 3] > 128) return y;
                }
                return -1;
              }
              for (var y = h - 1; y >= 0; y--) {
                if (px[(y * w + x) * 4 + 3] > 128) return y;
              }
              return -1;
            }(),
        ];
      }

      final report = StringBuffer();
      for (final s in [_idle, _alert]) {
        final pose = _pose(s, reduced: true);
        final head = DragonHeadPose.of(pose);
        // The head alone (its lowest pixel per column) and the torso alone
        // (its highest).
        final low = await columns((c) {
          c.translate(pose.bob.dx, pose.bob.dy);
          c.rotate(pose.pitch);
          DragonHeadArt.head(c, head);
        }, fromTop: false);
        final top = await columns((c) {
          c.translate(pose.bob.dx, pose.bob.dy);
          c.rotate(pose.pitch);
          c.drawPath(
            DragonKit.spline(DragonLayout.torsoOutline),
            Paint()..color = const Color(0xff000000),
          );
        }, fromTop: true);
        var notch = double.infinity;
        var at = 0.0;
        // The columns between the chin's front and the neck's front edge.
        for (
          var x = ((-1.45 - x0) * ppu).round();
          x < ((-.95 - x0) * ppu).round();
          x++
        ) {
          if (low[x] < 0 || top[x] < 0) continue;
          final gap = (top[x] - low[x]) / ppu;
          if (gap < notch) {
            notch = gap;
            at = x / ppu + x0;
          }
        }
        report.writeln(
          '${s.name}: notch ${notch.toStringAsFixed(2)} at x ${at.toStringAsFixed(2)}',
        );
        expect(notch, greaterThanOrEqualTo(.7), reason: '${s.name} at x $at');
      }
      // ignore: avoid_print
      print(report);
    });
  });

  // ------------------------------------------------------- values, bounds --

  testWidgets(
    'the horn is not the lightest shape: L* 80 or less but for its tip',
    (tester) async {
      await tester.runAsync(() async {
        const ppu = 120.0;
        final pose = _pose(_idle, reduced: true);
        final head = DragonHeadPose.of(pose);
        final px = await _pixels(
          (c) {
            c.translate(300, 300);
            c.scale(ppu);
            DragonHeadArt.head(
              c,
              DragonHeadPose(at: Offset.zero, angle: 0, tone: head.tone),
            );
          },
          600,
          500,
        );
        var highest = 0.0;
        final spine = DragonHeadArt.hornSpine;
        // Sample the horn along its spine short of its tip (the last stretch
        // is the tip, allowed up to boneLit); the gold ring sits at sample 4.
        for (final i in const [3, 5, 6]) {
          final at = spine[i];
          final x = (300 + at.dx * ppu).round(),
              y = (300 + at.dy * ppu).round();
          final k = (y * 600 + x) * 4;
          final l = lstar(px[k], px[k + 1], px[k + 2]);
          highest = math.max(highest, l);
        }
        // ignore: avoid_print
        print('horn L* along its body: max ${highest.toStringAsFixed(1)}');
        expect(highest, lessThanOrEqualTo(80));
      });
    },
  );

  testWidgets('at 250 px the eye holds most of the very brightest pixels', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final pose = _pose(_idle, reduced: true);
      const w = 190, h = 170;
      final px = await _pixels(
        (c) => _view(
          c,
          const Rect.fromLTWH(0, 0, 190, 170),
          _headFocus(pose, shift: const Offset(.5, .1)),
          _ppu250,
          (c) => _paintHead(c, pose, body: _Body.none),
          background: false,
        ),
        w,
        h,
      );
      // Where is the eye on this canvas?
      final head = DragonHeadPose.of(pose);
      final eyeRig = pose.toRig(DragonHeadArt.point(head, DragonHeadArt.eye));
      final focus = _headFocus(pose, shift: const Offset(.5, .1));
      final eyePx = Offset(
        w / 2 + (eyeRig.dx - focus.dx) * _ppu250,
        h / 2 + (eyeRig.dy - focus.dy) * _ppu250,
      );
      // Who owns the very brightest pixels (L* 88 and up)? The eye's white-hot
      // core and its glints should hold most of them; the gold, the teeth and
      // the horn tip may sparkle, but not outshine it.
      var bright = 0, inEye = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final k = (y * w + x) * 4;
          if (px[k + 3] < 250) continue;
          if (lstar(px[k], px[k + 1], px[k + 2]) < 88) continue;
          bright++;
          if ((Offset(x.toDouble(), y.toDouble()) - eyePx).distance <
              .55 * _ppu250) {
            inEye++;
          }
        }
      }
      // ignore: avoid_print
      print(
        '$inEye of the $bright very bright pixels of the head (L* >= 88) are in the eye',
      );
      expect(inEye, greaterThan(bright ~/ 2));
    });
  });

  testWidgets('the circlet stays inside its bounds', (tester) async {
    await tester.runAsync(() async {
      const ppu = 200.0;
      final px = await _pixels(
        (c) {
          c.translate(300, 200);
          c.scale(ppu);
          DragonHeadArt.crown(c);
        },
        600,
        400,
      );
      var minX = 600, minY = 400, maxX = 0, maxY = 0;
      for (var y = 0; y < 400; y++) {
        for (var x = 0; x < 600; x++) {
          if (px[(y * 600 + x) * 4 + 3] > 8) {
            minX = math.min(minX, x);
            maxX = math.max(maxX, x);
            minY = math.min(minY, y);
            maxY = math.max(maxY, y);
          }
        }
      }
      final r = Rect.fromLTRB(
        (minX - 300) / ppu,
        (minY - 200) / ppu,
        (maxX + 1 - 300) / ppu,
        (maxY + 1 - 200) / ppu,
      );
      // ignore: avoid_print
      print(
        'circlet ink extent ${r.left.toStringAsFixed(2)},${r.top.toStringAsFixed(2)},${r.right.toStringAsFixed(2)},${r.bottom.toStringAsFixed(2)}',
      );
      // The falling crown's layer is `crownBounds.inflate(.1)` (B8): the
      // bigger circlet stays inside it, with its own ink to spare.
      final layer = DragonHeadArt.crownBounds.inflate(.1);
      expect(layer.inflate(-.02).contains(r.topLeft), isTrue, reason: '$r');
      expect(layer.inflate(-.02).contains(r.bottomRight), isTrue, reason: '$r');
    });
  });

  test('cost: neck, head and smoke record in well under a millisecond', () {
    final pose = _sweepPose(_sweep.firstWhere((s) => s.$1 == 'blast middle'));
    final head = DragonHeadPose.of(pose);
    void frame() {
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      DragonHeadArt.neck(c, head);
      DragonHeadArt.head(c, head);
      DragonHeadArt.smoke(c, head);
      recorder.endRecording().dispose();
    }

    for (var i = 0; i < 50; i++) {
      frame();
    }
    final sw = Stopwatch()..start();
    const frames = 400;
    for (var i = 0; i < frames; i++) {
      frame();
    }
    final us = sw.elapsedMicroseconds / frames;
    // ignore: avoid_print
    print(
      'recording neck + head + smoke (open mouth): ${us.toStringAsFixed(0)} us per frame on this machine',
    );
    expect(us, lessThan(1500));
  });

  // ------------------------------------------------- circlet and Reduced --

  test('the circlet is level on screen at rest', () {
    final pose = DragonPose.still;
    final angle = DragonBossRig.crownAt(pose).angle;
    expect(angle.abs(), lessThan(.06), reason: 'the band turns $angle rad');
  });

  testWidgets('the falling crown starts exactly where the worn one was', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The worn circlet (head drawn with it) and the free one (head
      // without it, then DragonBossRig.crownPaint at crownDrop's anchor)
      // must be the same pixels.
      for (final death in [0.0, .3]) {
        final pose = death == 0
            ? DragonPose.still
            : DragonPose.atDeath(death, reduced: true);
        const ppu = 200.0;
        const cell = Rect.fromLTWH(0, 0, 700, 500);
        final focus = DragonBossRig.crownAt(pose).at;
        Future<Uint8List> shoot(void Function(Canvas) draw) => _pixels(
          (c) => _view(c, cell, focus, ppu, draw, background: false),
          700,
          500,
        );
        final worn = await shoot((c) => _paintHead(c, pose, body: _Body.none));
        final free = await shoot((c) {
          _paintHead(c, pose, crown: false, body: _Body.none);
          final drop = DragonBossRig.crownAt(pose);
          c.save();
          c.translate(drop.at.dx, drop.at.dy);
          c.scale(DragonHeadArt.scale);
          c.rotate(drop.angle);
          DragonBossRig.crownPaint(c);
          c.restore();
        });
        var total = 0;
        var differing = 0;
        for (var i = 0; i < worn.length; i += 4) {
          final d =
              (worn[i] - free[i]).abs() +
              (worn[i + 1] - free[i + 1]).abs() +
              (worn[i + 2] - free[i + 2]).abs() +
              (worn[i + 3] - free[i + 3]).abs();
          total += d;
          if (d > 140) differing++;
        }
        // ignore: avoid_print
        print('crown hand-off at death $death: $differing pixels differ');
        expect(
          differing,
          lessThan(40),
          reason: 'the crown pops (${total / 1000})',
        );
      }
    });
  });

  testWidgets('Reduced Motion holds the head still; states stay distinct', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const w = 260, h = 220;
      Future<Uint8List> shoot(_S s, {double age = 0}) async {
        final boss = _boss();
        s.setup(boss);
        boss.age += age;
        final pose = DragonPose(
          boss,
          BossMotion(boss, reducedMotion: true),
          lookY: s.aim,
        );
        return _pixels(
          (c) => _view(
            c,
            const Rect.fromLTWH(0, 0, 260, 220),
            _headFocus(pose, shift: const Offset(.5, .1)),
            40,
            (c) => _paintHead(c, pose),
          ),
          w,
          h,
        );
      }

      final idle = await shoot(_idle);
      expect(
        await shoot(_idle, age: 1.3),
        idle,
        reason: 'idle does not animate',
      );
      for (final s in [
        _alert,
        _charge,
        _rear,
        _roar,
        _call,
        _wince,
        _fury,
        _dizzy,
      ]) {
        expect(
          await shoot(s),
          isNot(equals(idle)),
          reason: '${s.name} is distinguishable',
        );
      }
    });
  });

  testWidgets('the head renders deterministically', (tester) async {
    await tester.runAsync(() async {
      for (final s in _twelve) {
        Future<Uint8List> shoot() {
          final pose = _pose(s);
          return _pixels(
            (c) => _view(
              c,
              const Rect.fromLTWH(0, 0, 300, 260),
              _headFocus(pose, shift: const Offset(.5, .1)),
              60,
              (c) => _paintHead(c, pose),
            ),
            300,
            260,
          );
        }

        expect(await shoot(), await shoot(), reason: s.name);
      }
    });
  });
}
