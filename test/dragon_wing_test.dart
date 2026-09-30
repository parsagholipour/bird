import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';
import 'package:push_up_bird/game/dragon_head_art.dart';
import 'package:push_up_bird/game/dragon_wing_art.dart';

import 'proof/dragon_proof_rig.dart';

/// The Ember Dragon's wings: review sheets (beat strips near + far, onion
/// skin against the envelope, per-joint lag, up/mid/down close-ups on light
/// and dark, fury, fold, flash, heat, silhouettes) and the acceptance
/// numbers (envelope, membrane value, hierarchy, parallax, budget).
final _out = Directory('build/visual-review/dragon-wings');

const _beat = 2 * math.pi / 5.4;

SkyBoss _boss(
  double combat, {
  int cycles = 0,
  bool fury = false,
  void Function(SkyBoss)? setup,
}) {
  final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = BreathLane.middle;
  if (fury) b.hp = b.maxHp ~/ 3;
  b.age = b.arrivalDuration + combat + cycles * DragonBreath.period;
  setup?.call(b);
  return b;
}

DragonPose _pose(
  double combat, {
  int cycles = 0,
  bool fury = false,
  bool reduced = false,
  DragonSkyLight light = DragonSkyLight.neutral,
  void Function(SkyBoss)? setup,
}) {
  final b = _boss(combat, cycles: cycles, fury: fury, setup: setup);
  return DragonPose(b, BossMotion(b, reducedMotion: reduced), light: light);
}

/// Both wings the way the rig paints them (bob and pitch included).
void _wings(Canvas c, DragonPose p, {DragonTone? tone}) {
  c.save();
  c.translate(p.bob.dx, p.bob.dy);
  c.rotate(p.pitch);
  final t = tone ?? p.tone;
  DragonWingArt.paint(c, DragonWing.farOf(p), t, p.time);
  DragonWingArt.paint(c, DragonWing.nearOf(p), t, p.time);
  c.restore();
}

/// A stand-in body built from the layout's numbers only (torso, neck, head,
/// tail), so the wings can be judged where they meet it: far wing, body,
/// neck, near wing, in the rig's own order. The real parts replace it.
void _context(Canvas c, DragonPose p, {DragonTone? tone}) {
  final t = tone ?? p.tone;
  c.save();
  c.translate(p.bob.dx, p.bob.dy);
  c.rotate(p.pitch);
  DragonWingArt.paint(c, DragonWing.farOf(p), t, p.time);
  Paint body([Color col = const Color(0xff53396a)]) => DragonKit.fill(col);
  final ink = DragonKit.line(DragonPalette.ink, .1);
  final torso = DragonKit.spline(DragonLayout.torsoOutline);
  final tail = DragonKit.tube(DragonLayout.tailSpine, DragonLayout.tailWidths);
  for (final path in [tail, torso]) {
    c.drawPath(path, body());
    c.drawPath(path, ink);
  }
  final joint = p.headPoint(DragonLayout.headNeckJoint);
  final neck = DragonKit.tube(
    DragonLayout.neckSpine(
      joint,
      p.head.angle,
      drag: p.neckDrag,
      coil: p.neckCoil,
    ),
    DragonLayout.neckWidths,
  );
  c.drawPath(neck, body(const Color(0xff5d4276)));
  c.drawPath(neck, ink);
  final head = Path()
    ..addOval(Rect.fromCenter(center: p.head.at, width: 2.3, height: 1.5));
  c.drawPath(head, body(const Color(0xff5d4276)));
  c.drawPath(head, ink);
  DragonWingArt.paint(c, DragonWing.nearOf(p), t, p.time);
  c.drawCircle(Offset.zero, 1, DragonKit.line(const Color(0x882060d0), .04));
  c.drawCircle(Offset.zero, .45, DragonKit.fill(const Color(0xffffc060)));
  c.restore();
}

/// A wing motion held at one stroke (the far wing a phase behind).
DragonWingMotion _motion(
  double s, {
  double? wrist,
  List<double>? tips,
  List<double>? flex,
  double spread = 0,
  double sag = 0,
  double fold = 0,
}) => DragonWingMotion(
  elbow: s,
  wrist: wrist ?? s,
  tips: tips ?? [s, s, s, s],
  flex: flex ?? const [0, 0, 0, 0],
  fold: fold,
  spread: spread,
  sag: sag,
);

void _pair(
  Canvas c,
  DragonWingMotion near,
  DragonWingMotion far,
  DragonTone tone,
  double time,
) {
  DragonWingArt.paint(c, DragonWing.of(far, far: true), tone, time);
  DragonWingArt.paint(c, DragonWing.of(near), tone, time);
}

Future<void> _fonts() async {
  await (FontLoader(
    'Fredoka',
  )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
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

Future<void> _png(String name, ui.Picture pic, int w, int h) async {
  _out.createSync(recursive: true);
  final img = await pic.toImage(w, h);
  File('${_out.path}/$name.png').writeAsBytesSync(
    (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
  img.dispose();
  pic.dispose();
}

typedef _Cell = (String, void Function(Canvas));

/// A grid of cells, each drawing in rig units through [view] at [ppu].
Future<void> _sheet(
  String name,
  List<_Cell> cells, {
  required Rect view,
  required double ppu,
  int cols = 6,
  Color bg = const Color(0xffe9dfd2),
  Color? sky,
  bool guides = true,
  double font = 12,
  Color labelColor = const Color(0xff222222),
}) async {
  final cw = (view.width * ppu).round(), ch = (view.height * ppu).round();
  final rows = (cells.length / cols).ceil();
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    Rect.fromLTWH(0, 0, (cw * cols).toDouble(), (ch * rows).toDouble()),
    Paint()..color = bg,
  );
  for (var i = 0; i < cells.length; i++) {
    final cx = (i % cols) * cw, cy = (i ~/ cols) * ch;
    c.save();
    c.clipRect(
      Rect.fromLTWH(cx.toDouble(), cy.toDouble(), cw.toDouble(), ch.toDouble()),
    );
    c.translate(cx.toDouble(), cy.toDouble());
    if (sky != null) {
      c.drawRect(
        Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()),
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(0, ch.toDouble()), [
            sky,
            Color.lerp(sky, const Color(0xffffb080), .35)!,
          ]),
      );
    }
    c.scale(ppu);
    c.translate(-view.left, -view.top);
    if (guides) {
      final g = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 / ppu
        ..color = const Color(0x55d03030);
      c.drawLine(const Offset(4.35, -9), const Offset(4.35, 9), g);
      c.drawLine(const Offset(-9, -3.74), const Offset(9, -3.74), g);
      g.color = const Color(0x8830a030);
      c.drawRect(DragonLayout.envelope, g);
    }
    cells[i].$2(c);
    c.restore();
    _label(c, cells[i].$1, Offset(cx + 4.0, cy + 2.0), font, labelColor);
  }
  await _png(name, rec.endRecording(), cw * cols, ch * rows);
}

/// The bounds of solid pixels of [draw], in rig units.
Future<Rect> _scan(void Function(Canvas) draw, {int solid = 200}) async {
  const ppu = 24.0, x0 = -7.0, y0 = -7.0, size = 15.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.scale(ppu);
  c.translate(-x0, -y0);
  draw(c);
  final pic = rec.endRecording();
  final n = (size * ppu).round();
  final img = await pic.toImage(n, n);
  final data = (await img.toByteData())!.buffer.asUint8List();
  var minX = n, minY = n, maxX = -1, maxY = -1;
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (data[(y * n + x) * 4 + 3] >= solid) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  img.dispose();
  pic.dispose();
  if (maxX < 0) return Rect.zero;
  return Rect.fromLTRB(
    minX / ppu + x0,
    minY / ppu + y0,
    (maxX + 1) / ppu + x0,
    (maxY + 1) / ppu + y0,
  );
}

/// Counts what a frame asks of the canvas (the budget test's counter).
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
    if (p.shader != null) _n('$k.shader');
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

/// CIE L* of [c] (0 black .. 100 white).
double _lstar(Color c) {
  final y = c.computeLuminance();
  final f = y > 216 / 24389
      ? math.pow(y, 1 / 3).toDouble()
      : (24389 / 27 * y + 16) / 116;
  return 116 * f - 16;
}

/// Pixels of [draw] on an opaque white ground, and a lookup by rig point.
class _Shot {
  _Shot(this.data, this.w, this.view, this.ppu);
  final Uint8List data;
  final int w;
  final Rect view;
  final double ppu;

  Color at(Offset p) {
    final x = ((p.dx - view.left) * ppu).floor(),
        y = ((p.dy - view.top) * ppu).floor();
    final i = (y * w + x) * 4;
    return Color.fromARGB(data[i + 3], data[i], data[i + 1], data[i + 2]);
  }
}

Future<_Shot> _shoot(
  void Function(Canvas) draw, {
  Rect view = _wingView,
  double ppu = 60,
  Color bg = const Color(0xffffffff),
}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    Offset.zero & Size(view.width * ppu, view.height * ppu),
    Paint()..color = bg,
  );
  c.scale(ppu);
  c.translate(-view.left, -view.top);
  draw(c);
  final w = (view.width * ppu).round(), h = (view.height * ppu).round();
  final img = await rec.endRecording().toImage(w, h);
  final data = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  return _Shot(data, w, view, ppu);
}

/// Count of solid pixels of [a] that [b] does not cover, and the rig y of
/// the highest of them (null: none), on the [ppu] grid over [view].
Future<(int, double?)> _only(
  void Function(Canvas) a,
  void Function(Canvas) b, {
  double ppu = 24,
  Rect view = const Rect.fromLTRB(-2, -5, 6, 3),
}) async {
  Future<Uint8List> alpha(void Function(Canvas) draw) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(ppu);
    c.translate(-view.left, -view.top);
    draw(c);
    final w = (view.width * ppu).round(), h = (view.height * ppu).round();
    final img = await rec.endRecording().toImage(w, h);
    final data = (await img.toByteData())!.buffer.asUint8List();
    img.dispose();
    return data;
  }

  final da = await alpha(a), db = await alpha(b);
  final w = (view.width * ppu).round(), h = (view.height * ppu).round();
  var n = 0;
  int? top;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4 + 3;
      if (da[i] >= 200 && db[i] < 40) {
        n++;
        top ??= y;
      }
    }
  }
  return (n, top == null ? null : top / ppu + view.top);
}

/// Outer width of a bone at [at] across [dir]: from the first ink line to the
/// far side of the second, measured in [shot] (rig units).
double _boneWidth(_Shot shot, Offset at, Offset dir) {
  final n = Offset(-dir.dy, dir.dx);
  int? start, end;
  var runs = 0;
  var inInk = false;
  for (var k = -45; k <= 45; k++) {
    final ink = _lstar(shot.at(at + n * (k / 100))) < 12;
    if (ink && !inInk) {
      runs++;
      start ??= k;
    }
    if (ink && runs == 2) end = k;
    inInk = ink;
    if (runs == 2 && !ink) break;
  }
  return start == null || end == null ? 9 : (end - start) / 100;
}

/// The combat states the envelope is swept over (the shared envelope test's
/// list, so the wings are held to the same moments as the whole rig).
typedef _Setup = void Function(SkyBoss);
final _combat = <(String, double, _Setup)>[
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
    ('thump ${lane.name}', 5.42, (b) => b.breathLane = lane),
    ('plateau ${lane.name}', 6.5, (b) => b.breathLane = lane),
  ],
  ('gutter', 7.3, (b) {}),
  ('wind', 7.45, (b) {}),
  ('call', 7.72, (b) => b.lastSummonAt = b.age - .1),
  ('call peak', 7.95, (b) => b.lastSummonAt = b.age - .35),
  ('call fade', 8.3, (b) {}),
  ('rage', 1.2, (b) => b.enragedAt = b.age - .3),
  ('rage 2', 1.2, (b) => b.enragedAt = b.age - .6),
];
final _furyStates = <(String, double, _Setup)>[
  ('fury idle', 1.2, (b) {}),
  ('fury hold', 5.05, (b) {}),
  ('fury blast', 5.6, (b) {}),
  ('fury call', 7.72, (b) {}),
  ('fury call 2', 9.2, (b) {}),
  ('fury charge', 1.2, (b) => b.fireIn = .01),
];

const _wingView = Rect.fromLTRB(-.2, -3.9, 4.6, 1.7);

/// Special states: the calm Reduced Motion pose, flash, heat, fury and fold,
/// on light and dark.
Future<void> _states() async {
  final calm = _motion(-.25);
  for (final (name, bg, ink, dk) in [
    ('light', const Color(0xffe9dfd2), const Color(0xff222222), 0.0),
    ('dark', const Color(0xff1c1830), const Color(0xffdddddd), 1.0),
  ]) {
    final cells = <_Cell>[
      (
        'calm (Reduced Motion)',
        (c) => _pair(c, calm, calm, DragonTone(dark: dk), 0),
      ),
      (
        'hit flash .55',
        (c) => _pair(c, calm, calm, DragonTone(flash: .55, dark: dk), 0),
      ),
      (
        'heat 1 (inhale)',
        (c) => _pair(c, calm, calm, DragonTone(heat: 1, dark: dk), 0),
      ),
      (
        'fury (still)',
        (c) => _pair(c, calm, calm, DragonTone(fury: 1, dark: dk), 0),
      ),
      (
        'fury up, spread',
        (c) => _pair(
          c,
          _motion(-1, spread: 1),
          _motion(-.8, spread: 1),
          DragonTone(fury: 1, dark: dk),
          1.3,
        ),
      ),
      (
        'fury mid',
        (c) => _pair(
          c,
          _motion(0),
          _motion(.3),
          DragonTone(fury: 1, dark: dk),
          2.1,
        ),
      ),
      (
        'fury + flash',
        (c) =>
            _pair(c, calm, calm, DragonTone(fury: 1, flash: .5, dark: dk), 0),
      ),
      (
        'fold .3 (defeat)',
        (c) => _pair(
          c,
          _motion(.4, fold: .3),
          _motion(.4, fold: .3),
          DragonTone(dark: dk),
          0,
        ),
      ),
      (
        'fold 1',
        (c) => _pair(
          c,
          _motion(0, fold: 1),
          _motion(0, fold: 1),
          DragonTone(dark: dk),
          0,
        ),
      ),
    ];
    await _sheet(
      'states-$name',
      cells,
      view: _wingView,
      ppu: 62,
      cols: 3,
      bg: bg,
      labelColor: ink,
    );
  }
}

/// Fury close-ups at 100 px per unit: three strokes, two clocks.
Future<void> _furyClose() async {
  for (final (name, bg, ink, dk) in [
    ('dark', const Color(0xff1c1830), const Color(0xffdddddd), 1.0),
    ('light', const Color(0xffe9dfd2), const Color(0xff222222), 0.0),
  ]) {
    final tone = DragonTone(fury: 1, dark: dk);
    await _sheet(
      'fury-$name',
      [
        (
          'up t1.3',
          (c) => _pair(
            c,
            _motion(-1, spread: 1),
            _motion(-.8, spread: 1),
            tone,
            1.3,
          ),
        ),
        (
          'mid t2.1',
          (c) => _pair(
            c,
            _motion(0, spread: .4),
            _motion(.3, spread: .4),
            tone,
            2.1,
          ),
        ),
        ('down t3.4', (c) => _pair(c, _motion(.85), _motion(.95), tone, 3.4)),
      ],
      view: _wingView,
      ppu: 90,
      cols: 3,
      bg: bg,
      labelColor: ink,
    );
  }
}

/// One beat, twelve samples, all drawn translucent against the envelope box.
Future<void> _onion() async {
  const ppu = 70.0;
  const view = Rect.fromLTRB(-.2, -4.3, 5.0, 1.9);
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    Rect.fromLTWH(0, 0, view.width * ppu, view.height * ppu),
    Paint()..color = const Color(0xffe9dfd2),
  );
  c.scale(ppu);
  c.translate(-view.left, -view.top);
  final report = StringBuffer();
  var union = Rect.zero;
  for (var i = 0; i < 12; i++) {
    final pose = _pose(1.2 + i * _beat / 12);
    c.saveLayer(null, Paint()..color = const Color(0x33ffffff));
    _wings(c, pose);
    c.restore();
    final r = await _scan((cv) => _wings(cv, pose));
    union = i == 0 ? r : union.expandToInclude(r);
    report.writeln(
      '#$i stroke ${pose.stroke.toStringAsFixed(2)}  T ${r.top.toStringAsFixed(2)}  R ${r.right.toStringAsFixed(2)}',
    );
  }
  report.writeln(
    'union L ${union.left.toStringAsFixed(2)} T ${union.top.toStringAsFixed(2)} R ${union.right.toStringAsFixed(2)} B ${union.bottom.toStringAsFixed(2)}',
  );
  final g = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6 / ppu
    ..color = const Color(0xff30a030);
  c.drawRect(DragonLayout.envelope, g);
  g.color = const Color(0xffd03030);
  c.drawLine(const Offset(4.35, -9), const Offset(4.35, 9), g);
  c.drawLine(const Offset(-9, -3.74), const Offset(9, -3.74), g);
  await _png(
    'onion',
    rec.endRecording(),
    (view.width * ppu).round(),
    (view.height * ppu).round(),
  );
  _out.createSync(recursive: true);
  File('${_out.path}/onion.txt').writeAsStringSync(report.toString());
  // ignore: avoid_print
  print(report);
}

/// Six frames 50 ms apart with the joints marked, and the joint strokes over
/// one beat as a plot: the wrist trails the elbow, every finger the wrist.
Future<void> _lag() async {
  const frames = 6;
  // Centre the strip on the fastest point of the downstroke.
  var fast = 1.2, speed = 0.0;
  for (var i = 0; i < 200; i++) {
    final at = 1.2 + i * .006;
    final v = _pose(at + .003).stroke - _pose(at).stroke;
    if (v > speed) {
      speed = v;
      fast = at;
    }
  }
  final poses = [for (var i = 0; i < frames; i++) _pose(fast - .12 + i * .048)];
  await _sheet(
    'lag-strip',
    [
      for (var i = 0; i < frames; i++)
        (
          '${(i * 48)} ms  stroke ${poses[i].stroke.toStringAsFixed(2)}',
          (c) {
            _wings(c, poses[i]);
            final p = poses[i];
            final w = DragonWing.nearOf(p);
            c.drawCircle(
              w.elbow,
              .07,
              Paint()..color = const Color(0xff00b0ff),
            );
            c.drawCircle(
              w.wrist,
              .07,
              Paint()..color = const Color(0xff00e050),
            );
            for (final t in w.tips) {
              c.drawCircle(t, .06, Paint()..color = const Color(0xffffffff));
            }
          },
        ),
    ],
    view: _wingView,
    ppu: 50,
    cols: 3,
  );
  // The plot.
  const w = 640.0, h = 300.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    const Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xfff4efe8),
  );
  final colors = [
    const Color(0xff0090e0),
    const Color(0xff00b050),
    const Color(0xffe03030),
    const Color(0xffe08020),
    const Color(0xff9030c0),
    const Color(0xff606060),
  ];
  const t0 = 1.2, span = 1.2;
  final names = ['elbow', 'wrist', 'f0', 'f1', 'f2', 'f3'];
  for (var k = 0; k < 6; k++) {
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final p = _pose(t0 + span * i / 120);
      final m = p.nearWing;
      final v = [m.elbow, m.wrist, ...m.tips][k];
      final x = 30 + i / 120 * (w - 40), y = h / 2 - v * (h / 2 - 20);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    c.drawPath(
      path,
      Paint()
        ..color = colors[k]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _label(c, names[k], Offset(40 + k * 60.0, 4), 12, colors[k]);
  }
  c.drawLine(
    Offset(30, h / 2),
    Offset(w - 10, h / 2),
    Paint()..color = const Color(0x55000000),
  );
  await _png('lag-plot', rec.endRecording(), w.toInt(), h.toInt());
}

/// The assembled dragon (real head, neck, torso) around the wings, at 80 px
/// per unit: up, mid, down and fury. `tag` names the file, so a before and
/// an after can sit side by side.
Future<void> _assembled(String tag) async {
  const view = Rect.fromLTRB(-.6, -3.9, 4.6, 1.9);
  DragonPose at(double t, {bool fury = false}) => _pose(
    t,
    fury: fury,
    light: const DragonSkyLight(dark: .3, sky: Color(0xffa4afde)),
  );
  // Times where the near wing is up, mid and down.
  double when(double stroke) {
    var best = 1.2, err = 9.0;
    for (var i = 0; i < 240; i++) {
      final tt = 1.2 + i * .005;
      final e = (_pose(tt).stroke - stroke).abs();
      if (e < err) {
        err = e;
        best = tt;
      }
    }
    return best;
  }

  final ups = at(when(-.95)), mids = at(when(-.1)), downs = at(when(.6));
  final fury = at(2.4, fury: true);
  await _sheet(
    'assembled-$tag',
    [
      for (final (label, p) in [
        ('up', ups),
        ('mid', mids),
        ('down', downs),
        ('fury', fury),
      ])
        (label, (c) => DragonBossRig.paintPose(c, p)),
    ],
    view: view,
    ppu: 80,
    cols: 2,
    sky: const Color(0xff7d80ab),
    guides: false,
  );
}

/// The shoulder and elbow at 240 px per unit: the joint where shards showed.
Future<void> _shoulderZoom(String tag) async {
  const view = Rect.fromLTRB(.2, -2.2, 2.9, -.2);
  final ps = [
    _pose(1.2, light: const DragonSkyLight(dark: .3, sky: Color(0xffa4afde))),
    _pose(
      1.2 + _beat * .45,
      light: const DragonSkyLight(dark: .3, sky: Color(0xffa4afde)),
    ),
  ];
  await _sheet(
    'shoulder-$tag',
    [for (final p in ps) ('', (c) => DragonBossRig.paintPose(c, p))],
    view: view,
    ppu: 200,
    cols: 2,
    sky: const Color(0xff7d80ab),
    guides: false,
  );
}

/// Debug: the fury hem at 250 px per unit around the lowest scallop.
Future<void> _furyZoom() async {
  final tone = DragonTone(fury: 1);
  await _sheet(
    'fury-zoom',
    [
      ('down', (c) => _pair(c, _motion(.85), _motion(.95), tone, 3.4)),
      ('mid', (c) => _pair(c, _motion(0), _motion(.3), tone, 2.1)),
    ],
    view: const Rect.fromLTRB(2.2, -.8, 4.3, 1.4),
    ppu: 230,
    cols: 2,
    bg: const Color(0xff1c1830),
    guides: false,
    labelColor: const Color(0xffdddddd),
  );
}

/// The wing against the director's proof: both dragons as black silhouettes
/// in the same poses, overlaid (red: the proof only, blue: ours only), and
/// the numbers for the wing's own region, above the torso.
Future<void> _proofCompare() async {
  const ppu = 34.0;
  const view = Rect.fromLTRB(-3.6, -4.2, 4.9, 4.2);
  final poses = [
    ('idle', _pose(1.2)),
    ('wing up', _pose(1.2 + _beat * .15)),
    ('wing down', _pose(1.2 + _beat * .78)),
    ('rear back', _pose(4.6)),
  ];
  final w = (view.width * ppu).round(), h = (view.height * ppu).round();
  Future<List<bool>> mask(void Function(Canvas) draw) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(ppu);
    c.translate(-view.left, -view.top);
    c.saveLayer(null, Paint());
    draw(c);
    c.restore();
    final img = await rec.endRecording().toImage(w, h);
    final data = (await img.toByteData())!.buffer.asUint8List();
    img.dispose();
    return [for (var i = 3; i < data.length; i += 4) data[i] > 128];
  }

  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final report = StringBuffer();
  for (var k = 0; k < poses.length; k++) {
    final (name, pose) = poses[k];
    final ours = await mask((c) => DragonBossRig.paintPose(c, pose));
    final proof = await mask((c) => paintProofDragon(c, pose));
    final cell = ui.PictureRecorder();
    final cc = Canvas(cell);
    cc.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = const Color(0xffffffff),
    );
    final red = Paint()..color = const Color(0xffe04848);
    final blue = Paint()..color = const Color(0xff4870e0);
    final grey = Paint()..color = const Color(0xff282828);
    var wingOurs = 0, wingProof = 0, wingBoth = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final o = ours[y * w + x], p = proof[y * w + x];
        final rx = x / ppu + view.left, ry = y / ppu + view.top;
        if (rx > 1.0 && ry < -.7) {
          if (o) wingOurs++;
          if (p) wingProof++;
          if (o && p) wingBoth++;
        }
        final rect = Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);
        if (o && p) {
          cc.drawRect(rect, grey);
        } else if (p) {
          cc.drawRect(rect, red);
        } else if (o) {
          cc.drawRect(rect, blue);
        }
      }
    }
    final px = ppu * ppu;
    report.writeln(
      '$name: wing region ours ${(wingOurs / px).toStringAsFixed(2)} u2, proof ${(wingProof / px).toStringAsFixed(2)} u2, shared ${(wingBoth / px).toStringAsFixed(2)} u2 (IoU ${(wingBoth / (wingOurs + wingProof - wingBoth)).toStringAsFixed(2)})',
    );
    c.save();
    c.translate((k % 2) * w.toDouble(), (k ~/ 2) * h.toDouble());
    c.drawPicture(cell.endRecording());
    c.restore();
    _label(
      c,
      name,
      Offset((k % 2) * w + 6.0, (k ~/ 2) * h + 4.0),
      13,
      const Color(0xff000000),
    );
  }
  await _png('proof-compare', rec.endRecording(), w * 2, h * 2);
  _out.createSync(recursive: true);
  File('${_out.path}/proof-compare.txt').writeAsStringSync(report.toString());
  // ignore: avoid_print
  print(report);
}

/// The dragon's black silhouette at 250 and 120 px tall, wing V included.
Future<void> _silhouettes() async {
  final poses = [
    ('rest (still)', DragonPose.still),
    ('idle a', _pose(1.2)),
    ('idle b', _pose(1.2 + _beat / 2)),
    ('charge', _pose(1.2, setup: (b) => b.fireIn = .01)),
    ('rear', _pose(4.6)),
    ('roar', _pose(7.95, setup: (b) => b.lastSummonAt = b.age - .35)),
    ('fury', _pose(1.2, fury: true)),
    ('defeat', _pose(1.2, setup: (b) => b.defeatedAt = b.age - .5)),
  ];
  for (final (name, ppu, cols) in const [
    ('sil-250', 27.0, 4),
    ('sil-120', 13.0, 8),
  ]) {
    await _sheet(
      name,
      [
        for (final (label, pose) in poses)
          (
            label,
            (c) {
              c.saveLayer(
                null,
                Paint()
                  ..colorFilter = const ColorFilter.mode(
                    Color(0xff000000),
                    BlendMode.srcATop,
                  ),
              );
              DragonBossRig.paintPose(c, pose);
              c.restore();
            },
          ),
      ],
      view: const Rect.fromLTRB(-3.9, -4.4, 4.9, 4.4),
      ppu: ppu,
      cols: cols,
      font: ppu > 20 ? 12 : 9,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the wings stay inside their per-frame budget', () {
    // Both wings, every state that changes what they draw. The budget is
    // 90 draw ops, 4 new shaders on a warm frame and 3 clips, no layers.
    final states = <(String, DragonPose)>[
      ('idle', _pose(1.2)),
      ('reduced', _pose(1.2, reduced: true)),
      ('charge', _pose(1.2, setup: (b) => b.fireIn = .01)),
      ('hold', _pose(5.05)),
      ('blast', _pose(5.8)),
      ('call', _pose(7.95, setup: (b) => b.lastSummonAt = b.age - .35)),
      ('hit', _pose(1.2, setup: (b) => b.lastHitAt = b.age - .1)),
      ('fury', _pose(1.2, fury: true)),
      ('fury blast', _pose(5.8, fury: true)),
      ('defeat', _pose(1.2, setup: (b) => b.defeatedAt = b.age - .5)),
    ];
    final report = StringBuffer();
    for (final (name, pose) in states) {
      _wings(Canvas(ui.PictureRecorder()), pose); // warm the caches
      final before = DragonKit.shadersBuilt;
      final canvas = _Counting(Canvas(ui.PictureRecorder()));
      _wings(canvas, pose);
      final built = DragonKit.shadersBuilt - before;
      report.writeln(
        '${name.padRight(11)} ops ${canvas.draws.toString().padLeft(3)}  '
        'clips ${canvas.clips}  built $built  layers ${canvas.counts['saveLayer'] ?? 0}  '
        'blur ${canvas.counts['maskFilter'] ?? 0}  '
        'unforwarded ${canvas.counts.keys.where((k) => k.startsWith('UNFORWARDED')).toList()}',
      );
      expect(canvas.draws, lessThanOrEqualTo(90), reason: name);
      expect(canvas.clips, lessThanOrEqualTo(3), reason: name);
      expect(built, lessThanOrEqualTo(4), reason: name);
      expect(canvas.counts['saveLayer'] ?? 0, 0, reason: name);
      expect(canvas.counts['maskFilter'] ?? 0, 0, reason: name);
    }
    // ignore: avoid_print
    print(report);
  });

  testWidgets('the wings stay inside the envelope through the whole beat', (
    tester,
  ) async {
    await tester.runAsync(() async {
      var union = Rect.zero;
      final over = <String>[];
      for (final fury in [false, true]) {
        for (final (name, t, setup) in fury ? _furyStates : _combat) {
          // Each whole breath cycle shifts the beat by 2.85 rad, so the
          // wing is sampled all round the stroke without moving the breath.
          for (var n = 0; n < 16; n++) {
            final pose = _pose(t, cycles: n, fury: fury, setup: setup);
            final r = await _scan((c) => _wings(c, pose));
            union = union == Rect.zero ? r : union.expandToInclude(r);
            const e = DragonLayout.envelope;
            if (r.top < e.top - .02 ||
                r.right > e.right + .02 ||
                r.left < e.left - .02 ||
                r.bottom > e.bottom + .02) {
              over.add('$name #$n: $r');
            }
          }
        }
      }
      // ignore: avoid_print
      print('wings union: $union   envelope ${DragonLayout.envelope}');
      expect(over, isEmpty, reason: over.take(8).join('\n'));
    });
  });

  testWidgets('fold, arrival and defeat stay inside the layer bounds', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final poses = [
        for (final age in const [.3, 1.0, 1.5, 2.2, 2.55, 2.8, 3.1, 3.6, 4.4])
          _pose(1.2, setup: (b) => b.age = age),
        for (final d in const [.03, .1, .2, .3, .5, .8, 1.0])
          _pose(1.2, setup: (b) => b.defeatedAt = b.age - d),
      ];
      for (final pose in poses) {
        final r = await _scan((c) => _wings(c, pose));
        expect(
          DragonLayout.layerBounds.inflate(.02).contains(r.topLeft),
          isTrue,
          reason: '$r',
        );
        expect(
          DragonLayout.layerBounds.inflate(.02).contains(r.bottomRight),
          isTrue,
          reason: '$r',
        );
      }
    });
  });

  testWidgets(
    'the membrane glows: L* 50+ lit half, 15+ above the body, bones darker',
    (tester) async {
      await tester.runAsync(() async {
        final body = _lstar(DragonPalette.scale);
        var worstLit = 100.0;
        final report = StringBuffer();
        for (final s in [-1.0, -.25, 0.0, .6]) {
          final wing = DragonWing.of(_motion(s));
          const ppu = 60.0;
          final shot = await _shoot(
            (c) => DragonWingArt.paint(c, wing, DragonTone(), 0),
            ppu: ppu,
          );
          // Membrane pixels are the saturated warm ones (white ground, plum
          // bones and near-black ink are not); the lit half is the half of
          // them nearest the wrist.
          final skin = <(double, double)>[]; // (distance from the wrist, L*)
          for (var y = 0; y < shot.data.length ~/ (shot.w * 4); y++) {
            for (var x = 0; x < shot.w; x++) {
              final i = (y * shot.w + x) * 4;
              final r = shot.data[i],
                  g = shot.data[i + 1],
                  b = shot.data[i + 2];
              if (r > 150 && r - b > 50 && r - g > 20) {
                final p = Offset(
                  x / ppu + shot.view.left,
                  y / ppu + shot.view.top,
                );
                final c = Color.fromARGB(255, r, g, b);
                skin.add(((p - wing.wrist).distance, _lstar(c)));
              }
            }
          }
          skin.sort((a, b) => a.$1.compareTo(b.$1));
          double mean(Iterable<double> v) =>
              v.reduce((a, b) => a + b) / v.length;
          final lit = mean(skin.take(skin.length ~/ 2).map((e) => e.$2));
          final whole = mean(skin.map((e) => e.$2));
          var boneL = 0.0, skinL = 0.0;
          for (var i = 0; i < 4; i++) {
            final f = wing.fingers[i];
            boneL += _lstar(shot.at(f.at(.35)));
            final side = Offset(-f.tangentAt(.35).dy, f.tangentAt(.35).dx);
            skinL += _lstar(shot.at(f.at(.35) - side * .3));
          }
          boneL /= 4;
          skinL /= 4;
          report.writeln(
            'stroke $s: ${skin.length} membrane px, lit half L* ${lit.toStringAsFixed(1)}, whole ${whole.toStringAsFixed(1)}, body ${body.toStringAsFixed(1)}, bone ${boneL.toStringAsFixed(1)} vs skin ${skinL.toStringAsFixed(1)}',
          );
          worstLit = math.min(worstLit, lit);
          expect(
            boneL,
            lessThan(skinL - 15),
            reason: 'bones are darker than the skin at stroke $s',
          );
          expect(
            boneL,
            lessThan(body + 2),
            reason: 'bones are no lighter than the body',
          );
        }
        // ignore: avoid_print
        print(report);
        expect(worstLit, greaterThanOrEqualTo(50));
        expect(worstLit, greaterThanOrEqualTo(body + 15));
      });
    },
  );

  testWidgets('the far wing always shows its own outline (parallax)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      var least = double.infinity;
      var at = 0;
      for (var i = 0; i < 24; i++) {
        final pose = _pose(1.2 + i * _beat / 24);
        final (area, top) = await _only(
          (c) => DragonWingArt.paint(
            c,
            DragonWing.farOf(pose),
            pose.tone,
            pose.time,
          ),
          (c) => DragonWingArt.paint(
            c,
            DragonWing.nearOf(pose),
            pose.tone,
            pose.time,
          ),
        );
        final units = area / (24 * 24);
        if (units < least) {
          least = units;
          at = i;
        }
        expect(top, isNotNull);
      }
      // ignore: avoid_print
      print(
        'far wing least visible area: ${least.toStringAsFixed(2)} u2 at phase $at/24',
      );
      expect(least, greaterThan(.35));
    });
  });

  test('the wing is articulated: the fingers bend against the arm and lag it', () {
    // Sample the near wing's joints over four beats (10 ms steps).
    final elbow = <double>[],
        wrist = <double>[],
        tips = <List<double>>[[], [], [], []];
    final bend = <double>[];
    for (var i = 0; i < 480; i++) {
      final p = _pose(1.2 + i * .01);
      final m = p.nearWing;
      elbow.add(m.elbow);
      wrist.add(m.wrist);
      for (var k = 0; k < 4; k++) {
        tips[k].add(m.tips[k]);
      }
      final w = DragonWing.of(m);
      final arm = (w.wrist - w.elbow).direction;
      bend.add((w.tips[2] - w.wrist).direction - arm);
    }
    // How many milliseconds a signal trails the elbow (best correlation).
    int lagMs(List<double> a) {
      var best = 0, bestErr = double.infinity;
      for (var lag = 0; lag < 40; lag++) {
        var err = 0.0;
        for (var i = 60; i < 400; i++) {
          err += math.pow(elbow[i - lag] - a[i], 2).toDouble();
        }
        if (err < bestErr) {
          bestErr = err;
          best = lag;
        }
      }
      return best * 10;
    }

    final lags = [lagMs(wrist), for (final t in tips) lagMs(t)];
    // ignore: avoid_print
    print(
      'joint lag behind the elbow (ms): wrist ${lags[0]}  fingers ${lags.skip(1).toList()}',
    );
    for (var i = 1; i < lags.length; i++) {
      expect(
        lags[i],
        greaterThan(lags[i - 1] - 1),
        reason: 'each joint trails the one before',
      );
    }
    expect(lags.last, greaterThanOrEqualTo(120));
    final range = bend.reduce(math.max) - bend.reduce(math.min);
    // ignore: avoid_print
    print(
      'finger-vs-forearm angle swings ${range.toStringAsFixed(2)} rad over the beat',
    );
    expect(range, greaterThan(.3), reason: 'a rigid fan would not bend');
  });

  testWidgets(
    'wings are pure functions of the pose and Reduced Motion is still',
    (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> pixels(DragonPose p) async => (await _shoot(
          (c) => _wings(c, p),
          view: const Rect.fromLTRB(-1, -4.5, 5, 2),
          ppu: 30,
        )).data;
        final a = await pixels(_pose(1.2, fury: true));
        final b = await pixels(_pose(1.2, fury: true));
        expect(a, b, reason: 'same inputs, same pixels');
        final r1 = await pixels(_pose(1.2, reduced: true));
        final r2 = await pixels(_pose(2.3, reduced: true));
        expect(r1, r2, reason: 'Reduced Motion holds one still frame');
        final up = await pixels(_pose(1.2, reduced: true, fury: true));
        expect(
          up,
          isNot(r1),
          reason: 'fury still changes the wings under Reduced Motion',
        );
        final flash = await pixels(
          _pose(1.2, reduced: true, setup: (b) => b.lastHitAt = b.age - .1),
        );
        expect(
          flash,
          isNot(r1),
          reason: 'the hit flash shows under Reduced Motion',
        );
      });
    },
  );

  testWidgets('heat, fury and the hit flash each change the wings visibly', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final calm = _motion(-.25);
      Future<double> membraneL(DragonTone tone) async {
        final wing = DragonWing.of(calm);
        final shot = await _shoot((c) => DragonWingArt.paint(c, wing, tone, 0));
        var sum = 0.0, n = 0;
        for (var i = 0; i < 4; i++) {
          final apex = wing.hemAt(i, .5);
          for (final u in [.55, .65, .75]) {
            sum += _lstar(shot.at(Offset.lerp(wing.wrist, apex, u)!));
            n++;
          }
        }
        return sum / n;
      }

      final base = await membraneL(DragonTone());
      final heat = await membraneL(DragonTone(heat: 1));
      final fury = await membraneL(DragonTone(fury: 1));
      final flash = await membraneL(DragonTone(flash: .55));
      // ignore: avoid_print
      print(
        'mid-panel L*: calm ${base.toStringAsFixed(1)} heat ${heat.toStringAsFixed(1)} fury ${fury.toStringAsFixed(1)} flash ${flash.toStringAsFixed(1)}',
      );
      expect(heat, greaterThan(base + 3));
      expect(fury, greaterThan(base + 8));
      expect(flash, greaterThan(base + 8));
    });
  });

  test(
    'the arm bends like an arm: two bones of a length, the elbow pushed back',
    () {
      var least = 9.0, most = 0.0, sharp = 9.0;
      for (var i = 0; i < 48; i++) {
        final p = _pose(1.2 + i * _beat / 48);
        for (final w in [DragonWing.nearOf(p), DragonWing.farOf(p)]) {
          final up = w.joint - w.shoulder, low = w.wrist - w.joint;
          final ratio = up.distance / low.distance;
          least = math.min(least, ratio);
          most = math.max(most, ratio);
          // Turn from the upper arm to the forearm (positive: toward the wing
          // tip's side), and the elbow on the tail side of the chord.
          final turn = (low.direction - up.direction).abs();
          sharp = math.min(sharp, turn);
          final chord = w.wrist - w.shoulder;
          final side = chord.dx * up.dy - chord.dy * up.dx;
          expect(
            side,
            greaterThan(0),
            reason: 'the elbow points back, toward the tail',
          );
        }
      }
      // ignore: avoid_print
      print(
        'upper arm / forearm length ${least.toStringAsFixed(2)}..${most.toStringAsFixed(2)}, least elbow turn ${(sharp * 57.3).toStringAsFixed(0)} deg',
      );
      expect(least, greaterThan(.8));
      expect(most, lessThan(1.3));
      expect(
        sharp,
        greaterThan(.3),
        reason: 'a straight bar is a pipe, not an arm',
      );
    },
  );

  testWidgets('the far arm is not a clone of the near one', (tester) async {
    await tester.runAsync(() async {
      // Outer width across the upper arm, and the lightness of its fill.
      Future<(double, double)> arm(DragonWing w) async {
        final shot = await _shoot(
          (c) => DragonWingArt.paint(c, w, DragonTone(), 0),
          ppu: 100,
        );
        final mid = Offset.lerp(w.shoulder, w.joint, .55)!;
        final d = DragonKit.unit(w.joint - w.shoulder);
        var lum = 0.0, n = 0;
        for (var k = -4; k <= 4; k++) {
          final l = _lstar(shot.at(mid + Offset(-d.dy, d.dx) * (k / 100)));
          lum += l;
          n++;
        }
        return (_boneWidth(shot, mid, d), lum / n);
      }

      var closest = 9.0;
      for (var i = 0; i < 24; i++) {
        final p = _pose(1.2 + i * _beat / 24);
        closest = math.min(
          closest,
          (DragonWing.nearOf(p).wrist - DragonWing.farOf(p).wrist).distance,
        );
      }
      final p = _pose(1.2, reduced: true);
      final (nearW, nearL) = await arm(DragonWing.nearOf(p));
      final (farW, farL) = await arm(DragonWing.farOf(p));
      // ignore: avoid_print
      print(
        'near arm ${nearW.toStringAsFixed(2)} wide L* ${nearL.toStringAsFixed(1)}; far arm ${farW.toStringAsFixed(2)} wide L* ${farL.toStringAsFixed(1)}; wrists at least ${closest.toStringAsFixed(2)} apart',
      );
      expect(farW, lessThan(nearW * .9), reason: 'thinner');
      expect(farL, lessThan(nearL - 2), reason: 'darker');
      expect(
        closest,
        greaterThan(.2),
        reason: 'wrists never sit on each other',
      );
    });
  });

  testWidgets(
    'the wing arm is a slim bone, not a pipe: knuckles barely wider than the bone',
    (tester) async {
      await tester.runAsync(() async {
        final p = _pose(1.2, reduced: true);
        final w = DragonWing.nearOf(p);
        final shot = await _shoot(
          (c) => DragonWingArt.paint(c, w, DragonTone(), 0),
          ppu: 100,
        );
        double across(Offset at, Offset dir) => _boneWidth(shot, at, dir);

        final up = DragonKit.unit(w.joint - w.shoulder);
        final low = DragonKit.unit(w.wrist - w.joint);
        final mid = across(Offset.lerp(w.shoulder, w.joint, .6)!, up);
        final fore = across(Offset.lerp(w.joint, w.wrist, .55)!, low);
        final delto = across(w.shoulder + up * .12, up);
        // ignore: avoid_print
        print(
          'deltoid ${delto.toStringAsFixed(2)}, upper arm ${mid.toStringAsFixed(2)}, forearm ${fore.toStringAsFixed(2)} wide (with ink)',
        );
        expect(mid, lessThan(.36), reason: 'a tendon-thin middle');
        expect(
          delto,
          lessThan(mid * 2.8),
          reason: 'the shoulder swells, but is no ball',
        );
        expect(fore, lessThan(mid * 1.05));
      });
    },
  );

  test('the horn, frill and crown keep clear of the wing arms', () {
    // Every extremity behind the skull against both arms as drawn (centre
    // line from the shoulder through the bend to the wrist, less the arm's
    // half width), through every state and phase of the beat: calm states
    // keep .30, the head-up poses (rear, hold, call, rage) keep .19.
    const headUp = {
      'rear', 'rear late', 'hold', 'wind', 'call', 'call peak', 'rage', //
      'rage 2', 'sniff',
    };
    double toSegment(Offset p, Offset a, Offset b) {
      final ab = b - a,
          t =
              ((p - a).dx * ab.dx + (p - a).dy * ab.dy) /
              (ab.dx * ab.dx + ab.dy * ab.dy);
      return (p - (a + ab * t.clamp(0.0, 1.0))).distance;
    }

    var calm = double.infinity, up = double.infinity;
    var calmAt = '', upAt = '';
    for (final fury in [false, true]) {
      for (final (name, t, setup) in fury ? _furyStates : _combat) {
        for (var n = 0; n < 24; n++) {
          final pose = _pose(t, cycles: n, fury: fury, setup: setup);
          final head = DragonHeadPose.of(pose);
          final points = [
            for (final local in DragonHeadArt.reachFor(head))
              DragonHeadArt.point(head, local),
            DragonHeadArt.crownTop(head),
          ];
          final arms = [
            for (final w in [DragonWing.nearOf(pose), DragonWing.farOf(pose)])
              [w.shoulder, w.joint, w.wrist],
          ];
          for (var k = 0; k < points.length; k++) {
            var d = double.infinity;
            for (final a in arms) {
              for (var i = 0; i < a.length - 1; i++) {
                d = math.min(
                  d,
                  toSegment(pose.toRig(points[k]), a[i], a[i + 1]),
                );
              }
            }
            d -= .17;
            final label = '$name${fury ? ' fury' : ''} #$n point $k';
            if (headUp.contains(name.replaceAll('fury ', ''))) {
              if (d < up) {
                up = d;
                upAt = label;
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
      'horn-to-arm clearance: calm ${calm.toStringAsFixed(2)} ($calmAt), head-up ${up.toStringAsFixed(2)} ($upAt)',
    );
    expect(calm, greaterThan(.30), reason: calmAt);
    expect(up, greaterThan(.19), reason: upAt);
  });

  test('the wings keep clear of the crown', () {
    for (var i = 0; i < 24; i++) {
      for (final setup in <_Setup>[(b) {}, (b) => b.fireIn = .01]) {
        final p = _pose(1.2 + i * _beat / 24, setup: setup);
        final seat = p.headPoint(DragonLayout.headCrownSeat);
        final crown = DragonLayout.crownBounds.shift(seat).inflate(.25);
        for (final w in [DragonWing.nearOf(p), DragonWing.farOf(p)]) {
          for (final q in [w.wrist, w.elbow, ...w.tips, w.shoulder]) {
            expect(
              crown.contains(q),
              isFalse,
              reason: 'joint $q near the crown $crown',
            );
          }
        }
      }
    }
  });

  testWidgets('review sheets', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      const wingView = Rect.fromLTRB(-.2, -3.9, 4.6, 1.7);
      final phases = [for (var i = 0; i < 12; i++) _pose(1.2 + i * _beat / 12)];
      await _sheet(
        'beat-wings',
        [
          for (var i = 0; i < 12; i++)
            (
              '#$i s${phases[i].stroke.toStringAsFixed(2)}',
              (c) => _wings(c, phases[i]),
            ),
        ],
        view: wingView,
        ppu: 40,
        cols: 4,
      );
      // Close-ups at up / mid / down, light and dark backdrops.
      final keys = <(String, DragonWingMotion, DragonWingMotion)>[
        ('UP', _motion(-1), _motion(-.75)),
        ('MID', _motion(0), _motion(.25)),
        ('DOWN', _motion(.85), _motion(.95)),
      ];
      for (final (name, bg, ink) in [
        ('light', const Color(0xffe9dfd2), const Color(0xff222222)),
        ('dark', const Color(0xff1c1830), const Color(0xffdddddd)),
      ]) {
        final dark = name == 'dark';
        await _sheet(
          'closeup-$name',
          [
            for (final (label, n, f) in keys)
              (label, (c) => _pair(c, n, f, DragonTone(dark: dark ? 1 : 0), 1)),
          ],
          view: wingView,
          ppu: 90,
          cols: 3,
          bg: bg,
          labelColor: ink,
        );
      }
      await _sheet(
        'beat-context',
        [for (var i = 0; i < 12; i++) ('#$i', (c) => _context(c, phases[i]))],
        view: const Rect.fromLTRB(-3.6, -4.3, 4.9, 4.2),
        ppu: 28,
        cols: 4,
        sky: const Color(0xff7d80ab),
      );
      await _sheet(
        'beat-full',
        [
          for (var i = 0; i < 12; i++)
            ('#$i', (c) => DragonBossRig.paintPose(c, phases[i])),
        ],
        view: const Rect.fromLTRB(-3.6, -4.3, 4.9, 4.2),
        ppu: 28,
        cols: 4,
        sky: const Color(0xff7d80ab),
      );
      // The rig at the game's own scale (41.4 px per unit) on three skies.
      final gameView = const Rect.fromLTRB(-5.0, -4.35, 4.35, 4.35);
      for (final (name, sky, dk) in [
        ('dusk', const Color(0xff7d80ab), 0.0),
        ('day', const Color(0xff8fd0f0), 0.0),
        ('night', const Color(0xff1a1638), 1.0),
      ]) {
        final ps = [
          for (final tt in [
            1.2,
            1.2 + _beat * .25,
            1.2 + _beat * .5,
            1.2 + _beat * .75,
          ])
            _pose(
              tt,
              light: DragonSkyLight(
                dark: dk,
                sky: dk > 0 ? const Color(0xff8a94d0) : const Color(0xffb0c0e8),
              ),
            ),
        ];
        await _sheet(
          'game-$name',
          [
            for (var i = 0; i < ps.length; i++)
              ('', (c) => DragonBossRig.paintPose(c, ps[i])),
          ],
          view: gameView,
          ppu: 41.4,
          cols: 4,
          sky: sky,
          guides: false,
        );
      }
      await _states();
      await _assembled(
        const String.fromEnvironment('WING_TAG', defaultValue: 'now'),
      );
      await _shoulderZoom(
        const String.fromEnvironment('WING_TAG', defaultValue: 'now'),
      );
      await _furyZoom();
      await _furyClose();
      await _onion();
      await _lag();
      await _proofCompare();
      await _silhouettes();
    });
  });
}
