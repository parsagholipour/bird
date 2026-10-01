// Shared helpers for King Coo's contract tests and review renders: building a
// boss in any state, rendering a picture, scanning what it covers, and a
// reference frame over New York's night backdrop.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

/// THE ONE SWITCH for King Coo's real-art contract tests.
///
/// `king_coo_envelope_test.dart` (every pose stays inside
/// `KingCooLayout.envelope`) and `king_coo_budget_test.dart` (ops, shaders,
/// clips, layers per frame, whole rig and per part) run against the real art in
/// `KingCooBossRig`. Every part has landed, so the default is `true` (K8): a
/// failure names the part, the pose and the coordinate that broke the rule.
/// To only REPORT what is over (while working on a part), pass `false`:
///
///   flutter test --no-pub --dart-define=KING_COO_ENFORCE=false \
///       test/king_coo_envelope_test.dart test/king_coo_budget_test.dart
const enforceRealArt = bool.fromEnvironment(
  'KING_COO_ENFORCE',
  defaultValue: true,
);

/// How many whole 14 s cycles of each scenario the envelope sweep samples
/// (every 1/12 s). 1 is quick; the final check before a merge runs 6:
///   flutter test --no-pub --dart-define=KING_COO_CYCLES=6 test/king_coo_envelope_test.dart
const envelopeCycles = int.fromEnvironment('KING_COO_CYCLES', defaultValue: 1);

/// Where review renders go (under `build/`, never source).
const reviewDir = String.fromEnvironment(
  'KING_COO_OUT',
  defaultValue: 'build/king-coo-review',
);

const birdX = .47;

typedef Setup = void Function(SkyBoss b);

/// A King Coo [combat] seconds into the fight (plus [cycles] whole 14 s cycles:
/// the same moment of the cycle, the waddle at another phase).
SkyBoss cooBoss({
  double combat = 1.2,
  int cycles = 0,
  bool fury = false,
  Setup? setup,
}) {
  final b = SkyBoss(number: 6, x: 2, kind: BossKind.kingCoo, cinematic: true);
  if (fury) b.hp = b.maxHp ~/ 2;
  b.age = b.arrivalDuration + combat + cycles * KingCoo.period;
  if (fury) b.enragedAt = b.arrivalDuration - 30;
  setup?.call(b);
  return b;
}

/// A King Coo in the arrival, [age] seconds in.
SkyBoss arrivingBoss(double age) =>
    SkyBoss(number: 6, x: 2, kind: BossKind.kingCoo, cinematic: true)..age = age;

/// A King Coo [death] seconds after the killing hit (he died [at] combat
/// seconds into the fight).
SkyBoss dyingBoss(double death, {double at = 1.2, bool fury = false}) {
  final b = cooBoss(combat: at, fury: fury);
  b.defeatedAt = b.age;
  b.age += death;
  return b;
}

/// A lob locked at [lockedAt] boss age, bird at height [y].
CrumbLob lobAt(double lockedAt, {double y = .5, bool fury = false}) =>
    CrumbLob(lockedAt: lockedAt, lockX: birdX, lockY: y, fury: fury);

KingCooPose poseOf(
  SkyBoss b, {
  bool reduced = false,
  double lookY = 0,
  KingCooSkyLight light = KingCooSkyLight.neutral,
  double? at,
}) => KingCooPose(
  b,
  BossMotion(b, reducedMotion: reduced),
  lookY: lookY,
  light: light,
  at: at,
);

/// A region's backdrop at [seconds], as its own palette lights him.
KingCooSkyLight regionLight(WorldRegion region, [double seconds = 12]) {
  final sky = SkyPalette.at(seconds, held: region);
  return KingCooSkyLight.fromSky(
    top: sky.top,
    horizon: sky.horizon,
    haze: sky.haze,
  );
}

/// New York at night, as the backdrop's own palette lights him.
KingCooSkyLight newYorkLight([double seconds = 12]) =>
    regionLight(WorldRegion.newYork, seconds);

// ---------------------------------------------------------------- rendering

Future<ui.Image> render(int w, int h, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  pic.dispose();
  return img;
}

Future<Uint8List> rawPixels(int w, int h, void Function(Canvas) draw) async {
  final img = await render(w, h, draw);
  final data = (await img.toByteData())!.buffer.asUint8List();
  img.dispose();
  return Uint8List.fromList(data);
}

Future<void> savePng(
  String name,
  int w,
  int h,
  void Function(Canvas) draw, {
  String? dir,
}) async {
  final img = await render(w, h, draw);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${dir ?? reviewDir}/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  expect(file.existsSync(), isTrue);
  img.dispose();
}

Future<void> loadFonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

void label(Canvas c, String text, Offset at, {double size = 12, Color? color}) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: size,
        color: color ?? const Color(0xff222222),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

// ----------------------------------------------------------------- scanning

/// The bounds of the solid pixels of a drawing in rig units, with the pixel
/// that reaches furthest on each side.
class Scan {
  const Scan(this.rect, this.atLeft, this.atTop, this.atRight, this.atBottom);
  final Rect rect;
  final Offset atLeft, atTop, atRight, atBottom;
  double get left => rect.left;
  double get top => rect.top;
  double get right => rect.right;
  double get bottom => rect.bottom;
  static const empty = Scan(Rect.zero, Offset.zero, Offset.zero, Offset.zero, Offset.zero);
  @override
  String toString() =>
      'L ${left.toStringAsFixed(2)} T ${top.toStringAsFixed(2)} '
      'R ${right.toStringAsFixed(2)} B ${bottom.toStringAsFixed(2)}';
}

/// Pixels per rig unit for the scans, the canvas (rig units) and the alpha
/// above which a pixel counts as solid figure (glows stay below).
const scanPpu = 24.0;
const scanX0 = -7.0, scanY0 = -7.0, scanSize = 15.0;
const scanSolid = 200;

Future<Scan> scan(
  void Function(Canvas) draw, {
  int solid = scanSolid,
  double ppu = scanPpu,
}) async {
  final n = (scanSize * ppu).round();
  final data = await rawPixels(n, n, (c) {
    c.scale(ppu);
    c.translate(-scanX0, -scanY0);
    draw(c);
  });
  var minX = n, minY = n, maxX = -1, maxY = -1;
  var left = 0, top = 0, right = 0, bottom = 0;
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
  if (maxX < 0) return Scan.empty;
  Offset at(int x, int y) =>
      Offset((x + .5) / ppu + scanX0, (y + .5) / ppu + scanY0);
  return Scan(
    Rect.fromLTRB(
      minX / ppu + scanX0,
      minY / ppu + scanY0,
      (maxX + 1) / ppu + scanX0,
      (maxY + 1) / ppu + scanY0,
    ),
    at(minX, left),
    at(top, minY),
    at(maxX, right),
    at(bottom, maxY),
  );
}

/// How far [s] pokes out of [box], per side, with the offending coordinate.
String over(Scan s, Rect box, {double slack = .02}) {
  final r = s.rect;
  String at(Offset o) =>
      '(${o.dx.toStringAsFixed(2)},${o.dy.toStringAsFixed(2)})';
  return [
    if (r.left < box.left - slack)
      'L+${(box.left - r.left).toStringAsFixed(2)} at ${at(s.atLeft)}',
    if (r.top < box.top - slack)
      'T+${(box.top - r.top).toStringAsFixed(2)} at ${at(s.atTop)}',
    if (r.right > box.right + slack)
      'R+${(r.right - box.right).toStringAsFixed(2)} at ${at(s.atRight)}',
    if (r.bottom > box.bottom + slack)
      'B+${(r.bottom - box.bottom).toStringAsFixed(2)} at ${at(s.atBottom)}',
  ].join(', ');
}

// ------------------------------------------------------------ reference frame

/// The figure painted as the encounter would: at the screen point [at] (the
/// chest), one rig unit = `h * SkyBoss.radius` pixels, [pose] as given.
void paintFigure(
  Canvas c,
  KingCooPose pose,
  Offset at,
  double h, {
  bool cap = true,
  Set<String>? only,
}) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(h * SkyBoss.radius);
  KingCooBossRig.paintPose(c, pose, cap: cap, only: only);
  c.restore();
}

/// Where the rules anchor him on a [w]x360 screen at hover time [combat].
Offset bossAnchor(double w, {double combat = 0, double h = 360}) => Offset(
  math.max(birdX + .70, w / h - .55) * h,
  (.5 + .06 * math.sin(.9 * combat)) * h,
);

/// A reference frame: New York at night, the bird, and King Coo in [pose].
/// [under] and [over] paint in screen pixels (h = 360) before / after him.
void nyFrame(
  Canvas c,
  double w, {
  required KingCooPose pose,
  double combat = 0,
  double birdY = .5,
  double seconds = 12,
  Offset? bossAt,
  void Function(Canvas c, Offset boss, double h)? under,
  void Function(Canvas c, Offset boss, double h)? above,
  bool bird = true,
  bool silhouette = false,
  WorldRegion region = WorldRegion.newYork,
}) {
  const h = 360.0;
  final size = Size(w, h);
  c.save();
  c.clipRect(Offset.zero & size);
  SkyScenery.paint(
    c,
    size,
    seconds: seconds,
    distance: seconds * .36,
    held: region,
  );
  final boss = bossAt ?? bossAnchor(w, combat: combat);
  under?.call(c, boss, h);
  if (silhouette) {
    c.saveLayer(
      null,
      Paint()
        ..colorFilter = const ColorFilter.mode(Color(0xff07091e), BlendMode.srcATop),
    );
    paintFigure(c, pose, boss, h);
    c.restore();
  } else {
    paintFigure(c, pose, boss, h);
  }
  if (bird) {
    final bw = h * .145;
    c.save();
    c.translate(birdX * h, birdY * h);
    BirdPuppet.paint(
      c,
      Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
      bird: 0,
      wing: .3,
    );
    c.restore();
  }
  above?.call(c, boss, h);
  c.restore();
}

// -------------------------------------------------------------- silhouettes

/// The figure as a hard-edged silhouette (alpha thresholded at half, so soft
/// glows never count), [ppu] pixels per rig unit, in a [w]x[h] picture whose
/// origin (the chest) is at [origin]; [ink] on transparent.
Future<ui.Image> silhouetteImage(
  KingCooPose pose, {
  required double ppu,
  required int w,
  required int h,
  required Offset origin,
  Color ink = const Color(0xff1b1730),
  bool cap = true,
  Set<String>? only,
}) async {
  final raw = await rawPixels(w, h, (c) {
    c.translate(origin.dx, origin.dy);
    c.scale(ppu);
    KingCooBossRig.paintPose(c, pose, cap: cap, only: only);
  });
  final out = Uint8List(raw.length);
  final a = (ink.a * 255).round();
  for (var i = 0; i < raw.length; i += 4) {
    if (raw[i + 3] >= 128) {
      out[i] = (ink.r * 255).round();
      out[i + 1] = (ink.g * 255).round();
      out[i + 2] = (ink.b * 255).round();
      out[i + 3] = a;
    }
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(out, w, h, ui.PixelFormat.rgba8888, done.complete);
  return done.future;
}

// -------------------------------------------------------- scenario sweeps

/// One boss history: a named scenario whose boss at age `t` is `at(t)`.
typedef Scenario = (String name, SkyBoss Function(double t) at, double from, double to);

SkyBoss _scenarioBoss(
  double age, {
  bool fury = false,
  Setup? setup,
}) {
  final b = SkyBoss(number: 6, x: 2, kind: BossKind.kingCoo, cinematic: true);
  if (fury) {
    b.hp = b.maxHp ~/ 2;
    b.enragedAt = 4.6 + 3.0;
  }
  setup?.call(b);
  b.age = age;
  return b;
}

/// The combat scenarios every art test sweeps (boss ages; the arrival is 4.6):
/// a calm fight with its lobs, the fury's fight with its bracketed lobs, the
/// fury's onset (stomp), a hit every half second, a pop before and after the
/// whistle, and a fury pop. [cycles] whole 14 s cycles of each.
List<Scenario> combatScenarios({int cycles = 1}) {
  const a = 4.6;
  final span = cycles * KingCoo.period;
  return [
    (
      'calm',
      (t) => _scenarioBoss(
        t,
        setup: (b) {
          for (var n = 0; n < cycles + 1; n++) {
            b.lobs.addAll([
              lobAt(a + n * 14 + .6, y: .3 + .2 * n),
              lobAt(a + n * 14 + 3.0, y: .7),
            ]);
          }
        },
      ),
      a,
      a + span,
    ),
    (
      'fury',
      (t) => _scenarioBoss(
        t,
        fury: true,
        setup: (b) {
          for (var n = 0; n < cycles + 1; n++) {
            b.lobs.addAll([
              lobAt(a + n * 14 + .6, fury: true),
              lobAt(a + n * 14 + 2.4, y: .25, fury: true),
              lobAt(a + n * 14 + 4.2, y: .75, fury: true),
            ]);
          }
        },
      ),
      a + 3.0,
      a + 3.0 + span,
    ),
    (
      'hits',
      (t) => _scenarioBoss(
        t,
        setup: (b) => b.lastHitAt = a + ((t - a) * 2).floorToDouble() / 2,
      ),
      a,
      a + span,
    ),
    (
      'pop before the whistle',
      (t) => _scenarioBoss(t, setup: (b) => b.poppedAt = a + 8.3),
      a + 7,
      a + 14.5,
    ),
    (
      'pop after the whistle',
      (t) => _scenarioBoss(t, setup: (b) => b.poppedAt = a + 9.6),
      a + 7,
      a + 14.5,
    ),
    (
      'fury pop',
      (t) => _scenarioBoss(t, fury: true, setup: (b) => b.poppedAt = a + 8.9),
      a + 7,
      a + 14.5,
    ),
  ];
}

/// Every pose of [combatScenarios], at [dt] seconds, calm and Reduced Motion.
Iterable<(String, KingCooPose)> combatPoses({
  int cycles = 1,
  double dt = 1 / 12,
  bool reduced = false,
  KingCooSkyLight light = KingCooSkyLight.neutral,
}) sync* {
  for (final (name, at, from, to) in combatScenarios(cycles: cycles)) {
    for (var t = from; t <= to; t += dt) {
      yield (
        '$name t=${(t - 4.6).toStringAsFixed(2)}${reduced ? ' RM' : ''}',
        poseOf(at(t), reduced: reduced, light: light),
      );
    }
  }
}

/// The arrival (boss ages 0..4.6) and the defeat (.0..3.8 after the killing
/// hit, from a calm, a window and a fury fight).
Iterable<(String, KingCooPose)> stagedPoses({
  double dt = 1 / 12,
  bool reduced = false,
  KingCooSkyLight light = KingCooSkyLight.neutral,
}) sync* {
  for (var t = 0.0; t <= 4.6; t += dt) {
    yield (
      'arrival ${t.toStringAsFixed(2)}${reduced ? ' RM' : ''}',
      poseOf(arrivingBoss(t), reduced: reduced, light: light),
    );
  }
  for (final (name, at, fury) in const [
    ('calm', 1.2, false),
    ('window', 9.0, false),
    ('fury', 5.0, true),
  ]) {
    for (var d = 0.0; d <= 3.8; d += dt) {
      yield (
        'defeat from $name ${d.toStringAsFixed(2)}${reduced ? ' RM' : ''}',
        poseOf(dyingBoss(d, at: at, fury: fury), reduced: reduced, light: light),
      );
    }
  }
}

// ---------------------------------------------------------------- the sheet

/// A calm idle pose whose near wing is closest to [angle] (the beat swept at
/// 1/100 s over one waddle).
KingCooPose idleWithWing(double angle, {KingCooSkyLight light = KingCooSkyLight.neutral}) {
  KingCooPose? best;
  for (var i = 0; i < 125; i++) {
    final p = poseOf(cooBoss(combat: 1.2 + i * .01), light: light);
    if (best == null || (p.wingNear - angle).abs() < (best.wingNear - angle).abs()) {
      best = p;
    }
  }
  return best!;
}

/// The 16 poses of the silhouette study and the pose sheet: what the player
/// sees in a fight, in the order of a round.
List<(String, KingCooPose)> sheetPoses({KingCooSkyLight light = KingCooSkyLight.neutral}) {
  KingCooPose at(SkyBoss b, {bool reduced = false}) => poseOf(b, light: light, reduced: reduced);
  SkyBoss withLob(double ago, {bool fury = false}) => cooBoss(
    combat: 1.0,
    fury: fury,
    setup: (b) => b.lobs.add(lobAt(b.age - ago, fury: fury)),
  );
  return [
    ('idle (wing up)', idleWithWing(-.7, light: light)),
    ('idle (wing down)', idleWithWing(.7, light: light)),
    ('wind-up: into the sack', at(withLob(.22))),
    ('wind-up: bomb in hand', at(withLob(.45))),
    ('wind-up: hold', at(withLob(.7))),
    ('release: underhand toss', at(withLob(.8))),
    ('follow-through', at(withLob(.92))),
    ('puff: inhale', at(cooBoss(combat: 8.2))),
    ('puff: chest taut', at(cooBoss(combat: 8.95))),
    ('whistle raised', at(cooBoss(combat: 8.9))),
    ('whistle blown', at(cooBoss(combat: 9.3))),
    ('POP', at(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .45))),
    ('fury', at(cooBoss(combat: 1.2, fury: true))),
    ('hit', at(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .09))),
    ('arrival roar', at(arrivingBoss(3.0))),
    ('defeat: inflating', at(dyingBoss(.62))),
  ];
}
