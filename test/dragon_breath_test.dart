import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_breath_art.dart';
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';
import 'package:push_up_bird/game/regions/world_region.dart';

import 'boss_fight_test.dart' show arena;

/// The Ember Dragon's breath VFX: the warning, the inhale funnel and the
/// fire jet (`DragonBreathArt`).
///
/// Contract tests: the solid fire is exactly the rules' band, the front
/// reaches the bird's column at 5.50 and not before, the flame stays inside
/// its budget (<= 250 path vertices, no saveLayer, no blur, no new shaders
/// on a warm frame), the scene light really lights dark, mid and bright
/// scenery, every state has a Reduced Motion frame, and the frames are pure
/// functions of the boss clock. It also writes review sheets to
/// `build/visual-review/dragon-breath/`: the nine key moments of the breath
/// in all three lanes over a dark, a mid and a bright backdrop at 640 and
/// 800, plus the fury and Reduced Motion variants.
final _folder = Directory('build/visual-review/dragon-breath');

const _h = 360.0;
const _times = [4.02, 4.6, 5.05, 5.25, 5.3, 5.5, 6.3, 7.1, 7.3];

/// A dragon [t] seconds into the fight, breathing at [lane].
SkyBoss _boss(
  double t, {
  BreathLane lane = BreathLane.middle,
  bool fury = false,
}) {
  final b = SkyBoss(number: 5, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = lane;
  if (fury) b.hp = b.maxHp ~/ 3;
  b.age = b.arrivalDuration + t;
  return b;
}

/// Where the jaws are, in pixels, for a dragon at [width] x 360.
Offset _mouth(SkyBoss boss, BossMotion m, double width) {
  boss
    ..x = (width - 180) / _h
    ..y = .5;
  final unit = _h * SkyBoss.radius;
  final pose = DragonPose(boss, m);
  return Offset(boss.x * _h, boss.y * _h) + DragonBossRig.mouthAt(pose) * unit;
}

/// Counts what the breath asks of the canvas.
class _Counting implements Canvas {
  _Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);

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
  void clipRect(
    Rect r, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    _n('clipRect');
    inner.clipRect(r, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void clipPath(Path p, {bool doAntiAlias = true}) {
    _n('clipPath');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  void _paint(String k, Paint p) {
    _n(k);
    if (p.shader != null) _n('$k.shader');
    if (p.maskFilter != null) _n('maskFilter');
    if (p.imageFilter != null) _n('imageFilter');
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
  void drawRRect(RRect r, Paint paint) {
    _paint('drawRRect', paint);
    inner.drawRRect(r, paint);
  }

  @override
  void drawOval(Rect r, Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
  }

  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) {
    _paint('drawArc', paint);
    inner.drawArc(r, a, b, c, paint);
  }

  @override
  void drawLine(Offset a, Offset b, Paint paint) {
    _paint('drawLine', paint);
    inner.drawLine(a, b, paint);
  }

  @override
  void drawPoints(ui.PointMode mode, List<Offset> points, Paint paint) {
    _paint('drawPoints', paint);
    inner.drawPoints(mode, points, paint);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    _n('drawParagraph');
    inner.drawParagraph(paragraph, offset);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

/// Everything the breath draws for one moment, in the encounter's order.
void _paintBreath(
  Canvas c,
  SkyBoss boss,
  BossMotion m,
  Offset mouth, {
  double width = 800,
  double seconds = 40,
  bool warning = true,
  bool flame = true,
  bool inhale = true,
  bool marks = true,
}) {
  final size = Size(width, _h);
  if (warning) {
    DragonBreathArt.warning(c, size, boss, m, mouth: mouth, seconds: seconds);
  }
  if (flame) {
    DragonBreathArt.flame(c, size, boss, m, mouth: mouth, seconds: seconds);
  }
  if (inhale) DragonBreathArt.inhale(c, _h, boss, m, mouth: mouth);
  if (marks) {
    DragonBreathArt.marks(c, size, boss, m, mouth: mouth, seconds: seconds);
  }
}

class _Px {
  _Px(this.bytes, this.w, this.h);
  final Uint8List bytes;
  final int w, h;
  (int, int, int, int) at(int x, int y) {
    final i = (y.clamp(0, h - 1) * w + x.clamp(0, w - 1)) * 4;
    return (bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
  }

  int alpha(int x, int y) => at(x, y).$4;
  double luma(int x, int y) {
    final (r, g, b, _) = at(x, y);
    return .2126 * r + .7152 * g + .0722 * b;
  }
}

/// Whether two frames are the same picture. Frames a whole breath apart
/// reach the same cycle time through different float rounding, so allow a
/// step of rounding in near-transparent pixels.
bool _samePicture(_Px a, _Px b) {
  for (var i = 0; i < a.bytes.length; i += 4) {
    if ((a.bytes[i + 3] - b.bytes[i + 3]).abs() > 1) {
      return false;
    }
    final alpha = a.bytes[i + 3];
    if (alpha < 4) continue;
    // Straight colour of a faint pixel moves by up to 255 / alpha when its
    // premultiplied value rounds the other way.
    final tolerance = 2 + 260 ~/ alpha;
    for (var k = 0; k < 3; k++) {
      if ((a.bytes[i + k] - b.bytes[i + k]).abs() > tolerance) {
        return false;
      }
    }
  }
  return true;
}

Future<_Px> _raster(
  void Function(Canvas) draw, {
  int width = 800,
  Color? backdrop,
}) async {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  if (backdrop != null) {
    c.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), _h),
      Paint()..color = backdrop,
    );
  }
  draw(c);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, _h.toInt());
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final px = _Px(data!.buffer.asUint8List(), width, _h.toInt());
  image.dispose();
  picture.dispose();
  return px;
}

/// One frame of just the breath (flame only unless asked) on [backdrop].
Future<_Px> _breathFrame(
  double t, {
  BreathLane lane = BreathLane.middle,
  bool fury = false,
  bool reduced = false,
  double width = 800,
  Color? backdrop,
  double seconds = 40,
  bool warning = false,
  bool flame = true,
  bool inhale = false,
  bool marks = false,
  Offset? mouthAt,
}) {
  final boss = _boss(t, lane: lane, fury: fury);
  final m = BossMotion(boss, reducedMotion: reduced);
  final mouth = mouthAt ?? _mouth(boss, m, width);
  return _raster(
    (c) => _paintBreath(
      c,
      boss,
      m,
      mouth,
      width: width,
      seconds: seconds,
      warning: warning,
      flame: flame,
      inhale: inhale,
      marks: marks,
    ),
    width: width.toInt(),
    backdrop: backdrop,
  );
}

Future<void> _save(
  String name,
  int w,
  int h,
  void Function(Canvas) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(
    (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
  image.dispose();
  picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => DragonBreathArt.sceneLight = true);

  test('the marks keep the rules timings', () {
    double at(double t) => DragonBreathArt.markings(_boss(t));
    expect(at(3.9), 0);
    expect(at(4.0), 0);
    expect(at(4.2), 1, reason: 'in over the first .18 s of the inhale');
    expect(at(5.0), 1);
    expect(
      at(6.0),
      closeTo(.55, 1e-9),
      reason: 'held faintly through the flame',
    );
    expect(at(7.1 + .3), 0, reason: 'out a quarter second after the flame');
    // A dragon that is not fighting shows nothing.
    final arriving = SkyBoss(
      number: 5,
      x: 2,
      kind: BossKind.dragon,
      cinematic: true,
    );
    expect(DragonBreathArt.markings(arriving), 0);
  });

  test('the flame draws in budget: <= 250 vertices, no layer, no blur', () {
    var worst = 0, worstInhale = 0, draws = 0;
    for (final lane in BreathLane.values) {
      for (final fury in [false, true]) {
        for (final reduced in [false, true]) {
          for (var t = 3.9; t < 7.6; t += .02) {
            final boss = _boss(t, lane: lane, fury: fury);
            final m = BossMotion(boss, reducedMotion: reduced);
            final mouth = _mouth(boss, m, 800);
            final counting = _Counting(Canvas(ui.PictureRecorder()));
            _paintBreath(counting, boss, m, mouth, seconds: 40 + t);
            expect(counting.counts['saveLayer'], isNull, reason: '$lane $t');
            expect(counting.counts['maskFilter'], isNull, reason: '$lane $t');
            expect(counting.counts['imageFilter'], isNull, reason: '$lane $t');
            expect(
              counting.counts.keys.where((k) => k.startsWith('UNFORWARDED')),
              isEmpty,
              reason: 'the counting canvas must see every call',
            );
            worst = math.max(worst, DragonBreathArt.flameVertices);
            worstInhale = math.max(worstInhale, DragonBreathArt.inhaleVertices);
            draws = math.max(draws, counting.draws);
          }
        }
      }
    }
    // ignore: avoid_print
    print(
      'breath budget: flame vertices <= $worst, inhale <= $worstInhale, draw ops <= $draws',
    );
    expect(worst, lessThanOrEqualTo(250));
    expect(worst, greaterThan(120), reason: 'a real flame, not a stub');
    expect(worstInhale, lessThanOrEqualTo(200));
    // Warning + jet + inhale + marks together stay a modest number of ops.
    expect(draws, lessThanOrEqualTo(90));
  });

  test(
    'a warm frame builds no new gradient shaders for the jet or the inhale',
    () {
      for (final t in [4.5, 5.05, 5.3, 5.6, 6.5, 7.2]) {
        for (final lane in BreathLane.values) {
          final boss = _boss(t, lane: lane);
          final m = BossMotion(boss, reducedMotion: false);
          final mouth = _mouth(boss, m, 800);
          const size = Size(800, _h);
          final c = Canvas(ui.PictureRecorder());
          // Warm the caches, then measure.
          DragonBreathArt.flame(c, size, boss, m, mouth: mouth, seconds: 40);
          DragonBreathArt.inhale(c, _h, boss, m, mouth: mouth);
          final before = DragonKit.shadersBuilt;
          DragonBreathArt.flame(c, size, boss, m, mouth: mouth, seconds: 41);
          DragonBreathArt.inhale(c, _h, boss, m, mouth: mouth);
          expect(DragonKit.shadersBuilt - before, 0, reason: '$lane at $t');
        }
      }
      // The warning builds only a handful (the band wash, stripes, safe wash
      // and one bank per edge).
      final boss = _boss(4.8);
      final m = BossMotion(boss, reducedMotion: false);
      final before = DragonKit.shadersBuilt;
      DragonBreathArt.warning(
        Canvas(ui.PictureRecorder()),
        const Size(800, _h),
        boss,
        m,
        mouth: _mouth(boss, m, 800),
        seconds: 40,
      );
      expect(DragonKit.shadersBuilt - before, lessThanOrEqualTo(8));
    },
  );

  testWidgets('the front reaches the bird\'s column at 5.50, never after', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final birdX = (FlightSimulation.birdX * _h).round();
      for (final width in [640.0, 800.0]) {
        for (final lane in BreathLane.values) {
          final (top, bottom) = DragonBreath.band(lane);
          final yMid = (((top + bottom) / 2) * _h).round();
          bool covered(_Px px) => px.alpha(birdX, yMid) > 200;
          // The fire's tip first touches the bird's column no earlier than
          // .1 s before the rules burn (never late), and it is there at 5.50.
          double? first;
          for (var t = 5.28; t <= 5.5 && first == null; t += .01) {
            if (covered(await _breathFrame(t, lane: lane, width: width))) {
              first = t;
            }
          }
          expect(first, isNotNull, reason: 'there by 5.50 ($lane, $width)');
          expect(
            first,
            greaterThanOrEqualTo(5.4),
            reason: 'not before 5.40: $first ($lane, $width)',
          );
          expect(
            covered(await _breathFrame(5.5, lane: lane, width: width)),
            isTrue,
            reason: 'there by 5.50 ($lane, $width)',
          );
          expect(
            covered(await _breathFrame(6.5, lane: lane, width: width)),
            isTrue,
          );
        }
      }
    });
  });

  testWidgets(
    'the visible fire IS the burn band: within 4 px of its edge, never beyond it',
    (tester) async {
      // Fairness, both ways. Whoever sees fire beside the bird is hurt (the
      // fire reaches to within [_shortTolerance] px of the rules' band edge
      // at every column where the jet has settled, in every frame of the
      // flicker) and whoever sees clear air is safe (no solid fire more than
      // [_beyondTolerance] px past the edge). Calm, fury and Reduced Motion,
      // every lane, at 640 and 800, drawn WITH the scene light on.
      const shortTolerance = 4.0, beyondTolerance = 1.0;
      var overallShort = 0.0, overallBeyond = 0.0;
      await tester.runAsync(() async {
        final birdX = (FlightSimulation.birdX * _h).round();
        final rr = (FlightSimulation.birdRadius * _h).round();
        for (final mode in ['calm', 'fury', 'reduced']) {
          for (final width in [640.0, 800.0]) {
            for (final lane in BreathLane.values) {
              final (top, bottom) = DragonBreath.band(lane);
              final y0 = top * _h, y1 = bottom * _h;
              var worstShort = 0.0, worstBeyond = 0.0, checked = 0;
              for (
                var t = DragonBreath.blastAt;
                t < DragonBreath.endAt - .01;
                t += 1 / 15
              ) {
                final boss = _boss(t, lane: lane, fury: mode == 'fury');
                final m = BossMotion(boss, reducedMotion: mode == 'reduced');
                final mouth = _mouth(boss, m, width);
                final px = await _breathFrame(
                  t,
                  lane: lane,
                  fury: mode == 'fury',
                  reduced: mode == 'reduced',
                  width: width,
                );
                // Where solid fire (alpha >= .6) starts and stops in a column.
                (int, int)? extent(int x) {
                  int? first, last;
                  for (var y = 0; y < _h; y++) {
                    if (px.alpha(x, y) >= 153) {
                      first ??= y;
                      last = y;
                    }
                  }
                  return first == null ? null : (first, last!);
                }

                // The bird is hurt if any part of its sprite overlaps the band,
                // so the fire's reach over the whole window at the bird's
                // column is what must match the band; everywhere the jet has
                // settled (left of the trumpet, and clear of its nose once the
                // front has run on) each column must match it too.
                final settledFrom = t >= 5.7 ? 8 : birdX + rr;
                final columns = <int>{
                  for (
                    var x = settledFrom;
                    x < mouth.dx - _h * .46 - 10;
                    x += 3
                  )
                    x,
                };
                int? windowFirst, windowLast;
                for (var x = birdX - rr; x <= birdX + rr; x++) {
                  final e = extent(x);
                  expect(
                    e,
                    isNotNull,
                    reason: 'fire at the bird: $mode $lane $width t=$t',
                  );
                  windowFirst = math.min(windowFirst ?? e!.$1, e!.$1);
                  windowLast = math.max(windowLast ?? e.$2, e.$2);
                }
                if (top > 0) {
                  worstShort = math.max(worstShort, windowFirst! - y0);
                  worstBeyond = math.max(worstBeyond, y0 - windowFirst);
                }
                if (bottom < 1) {
                  worstShort = math.max(worstShort, y1 - windowLast!);
                  worstBeyond = math.max(worstBeyond, windowLast - y1);
                }
                for (final x in columns) {
                  final e = extent(x);
                  expect(
                    e,
                    isNotNull,
                    reason: 'fire at column $x: $mode $lane $width t=$t',
                  );
                  final (first, last) = e!;
                  if (top > 0) {
                    worstShort = math.max(worstShort, first - y0);
                    worstBeyond = math.max(worstBeyond, y0 - first);
                  }
                  if (bottom < 1) {
                    worstShort = math.max(worstShort, y1 - last);
                    worstBeyond = math.max(worstBeyond, last - y1);
                  }
                  checked++;
                }
              }
              final why = '$mode $lane at $width';
              overallShort = math.max(overallShort, worstShort);
              overallBeyond = math.max(overallBeyond, worstBeyond);
              expect(checked, greaterThan(500), reason: why);
              expect(
                worstShort,
                lessThanOrEqualTo(shortTolerance),
                reason:
                    'fire stops short of the burn band by up to '
                    '${worstShort.toStringAsFixed(1)} px, $why',
              );
              expect(
                worstBeyond,
                lessThanOrEqualTo(beyondTolerance),
                reason:
                    'fire passes the burn band by up to '
                    '${worstBeyond.toStringAsFixed(1)} px, $why',
              );
            }
          }
        }
      });
      // ignore: avoid_print
      print(
        'burn-band fit: fire stops at most ${overallShort.toStringAsFixed(1)} px short and at most ${overallBeyond.toStringAsFixed(1)} px beyond the band (calm, fury, Reduced Motion; 640 and 800; all lanes)',
      );
    },
  );

  testWidgets('the haze runs no more than ~18 px past the fire\'s hard edge', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The soft glow (>= 12% opaque) around the jet is light, not fire: it
      // may fade out past the rules' edge but must not look like more flame.
      var worstReach = 0;
      for (final region in [WorldRegion.cyberpunk, WorldRegion.egypt]) {
        final seconds = region.index * WorldTour.leg + 9.0;
        for (final lane in BreathLane.values) {
          final (top, bottom) = DragonBreath.band(lane);
          final y0 = top * _h, y1 = bottom * _h;
          for (final t in [6.0, 6.6]) {
            DragonBreathArt.sceneLight = false;
            final off = await _breathFrame(t, lane: lane, seconds: seconds);
            DragonBreathArt.sceneLight = true;
            final on = await _breathFrame(t, lane: lane, seconds: seconds);
            for (var x = 20; x < 330; x += 10) {
              // Past the hard edge: how far does a pixel with no fire of its
              // own still carry >= 12% alpha?
              if (top > 0) {
                var reach = 0;
                for (var y = y0.round() - 1; y > 0; y--) {
                  if (off.alpha(x, y) >= 8) continue;
                  if (on.alpha(x, y) < 31) break;
                  reach = (y0 - y).round();
                }
                worstReach = math.max(worstReach, reach);
              }
              if (bottom < 1) {
                var reach = 0;
                for (var y = y1.round() + 1; y < _h; y++) {
                  if (off.alpha(x, y) >= 8) continue;
                  if (on.alpha(x, y) < 31) break;
                  reach = (y - y1).round();
                }
                worstReach = math.max(worstReach, reach);
              }
            }
          }
        }
      }
      // ignore: avoid_print
      print(
        'haze reach: >= 12% opaque up to $worstReach px past the band edge',
      );
      expect(worstReach, lessThanOrEqualTo(18));
    });
  });

  test(
    'a NaN or infinite clock, size or mouth draws nothing and never throws',
    () {
      final bad = [double.nan, double.infinity, double.negativeInfinity];
      void tryAll(
        SkyBoss boss,
        Size size,
        Offset mouth,
        double seconds, {
        bool reduced = false,
        bool withInhale = true,
      }) {
        final m = BossMotion(boss, reducedMotion: reduced);
        final counting = _Counting(Canvas(ui.PictureRecorder()));
        DragonBreathArt.warning(
          counting,
          size,
          boss,
          m,
          mouth: mouth,
          seconds: seconds,
        );
        DragonBreathArt.flame(
          counting,
          size,
          boss,
          m,
          mouth: mouth,
          seconds: seconds,
        );
        if (withInhale) {
          DragonBreathArt.inhale(counting, size.height, boss, m, mouth: mouth);
        }
        DragonBreathArt.marks(
          counting,
          size,
          boss,
          m,
          mouth: mouth,
          seconds: seconds,
        );
        expect(
          counting.draws,
          0,
          reason: 'nothing drawn: ${boss.age} $size $mouth $seconds',
        );
        expect(DragonBreathArt.flameVertices, 0);
        expect(DragonBreathArt.inhaleVertices, 0);
      }

      const size = Size(800, _h), mouth = Offset(500, 140);
      // A non-finite boss clock, in every phase of the breath's cycle.
      for (final age in bad) {
        for (final reduced in [false, true]) {
          final boss = _boss(5.9)..age = age;
          expect(DragonBreathArt.markings(boss), 0, reason: 'markings at $age');
          tryAll(boss, size, mouth, 40, reduced: reduced);
        }
      }
      // Non-finite drawing inputs on a boss that is mid-breath (each function
      // must return quietly, not only the one that reads the input).
      for (final t in [4.6, 5.05, 5.3, 6.3, 7.25]) {
        for (final v in bad) {
          final boss = _boss(t);
          tryAll(boss, size, Offset(v, 140), 40);
          tryAll(boss, size, Offset(500, v), 40);
          // (the inhale takes no clock of its own, so a bad one cannot reach it)
          tryAll(boss, size, mouth, v, withInhale: false);
          tryAll(boss, Size(800, v), mouth, 40);
          tryAll(boss, Size(v, _h), mouth, 40, withInhale: false);
        }
      }
      // Hostile but finite (huge or negative) clocks still draw or skip cleanly.
      for (final age in [1e15, -1e15, -3.0]) {
        final boss = _boss(5.9)..age = age;
        final m = BossMotion(boss, reducedMotion: false);
        final c = Canvas(ui.PictureRecorder());
        DragonBreathArt.warning(c, size, boss, m, mouth: mouth, seconds: 40);
        DragonBreathArt.flame(c, size, boss, m, mouth: mouth, seconds: 40);
        DragonBreathArt.inhale(c, _h, boss, m, mouth: mouth);
        DragonBreathArt.marks(c, size, boss, m, mouth: mouth, seconds: 40);
      }
      // And the healthy call right after a bad one still draws (no stuck state).
      final ok = _boss(6.3);
      final counting = _Counting(Canvas(ui.PictureRecorder()));
      DragonBreathArt.flame(
        counting,
        size,
        ok,
        BossMotion(ok, reducedMotion: false),
        mouth: mouth,
        seconds: 40,
      );
      expect(counting.draws, greaterThan(5));
    },
  );

  testWidgets(
    'the scene light is light, not fire: never more than .55 opaque',
    (tester) async {
      await tester.runAsync(() async {
        // A capture of the breath alone must not read the wash as solid fire
        // (a reviewer's harness counts alpha >= .6 as fire).
        for (final region in [
          WorldRegion.cyberpunk,
          WorldRegion.antarctica,
          WorldRegion.egypt,
          WorldRegion.paris,
        ]) {
          final seconds = region.index * WorldTour.leg + 9.0;
          for (final lane in BreathLane.values) {
            DragonBreathArt.sceneLight = false;
            final off = await _breathFrame(6.3, lane: lane, seconds: seconds);
            DragonBreathArt.sceneLight = true;
            final on = await _breathFrame(6.3, lane: lane, seconds: seconds);
            var worst = 0;
            for (var y = 0; y < _h; y++) {
              for (var x = 0; x < 800; x++) {
                if (off.alpha(x, y) == 0) {
                  worst = math.max(worst, on.alpha(x, y));
                }
              }
            }
            expect(
              worst,
              lessThanOrEqualTo(141),
              reason: '${region.name} $lane',
            );
          }
        }
      });
    },
  );

  testWidgets('nothing of the jet lies outside the band but a faint light', (
    tester,
  ) async {
    await tester.runAsync(() async {
      DragonBreathArt.sceneLight = false;
      for (final lane in [BreathLane.middle, BreathLane.low]) {
        final (top, bottom) = DragonBreath.band(lane);
        final y0 = top * _h, y1 = bottom * _h;
        for (final t in [5.4, 5.5, 6.0, 6.8, 7.15]) {
          final boss = _boss(t, lane: lane);
          final m = BossMotion(boss, reducedMotion: false);
          final mouth = _mouth(boss, m, 800);
          final px = await _breathFrame(t, lane: lane);
          var stray = 0;
          // The trumpet (the first .4 h off the jaws) is where the flame
          // leaves the mouth, which the rules put outside the band.
          for (var x = 0; x < mouth.dx - _h * .4; x++) {
            for (var y = 0; y < _h; y++) {
              if (y >= y0 - 3 && y <= y1 + 3) continue;
              if (px.alpha(x, y) > 31) stray++; // .12 of 255
            }
          }
          expect(stray, 0, reason: '$lane at $t');
        }
      }
    });
  });

  testWidgets('the ignition is a white-hot wedge tapering to orange', (
    tester,
  ) async {
    await tester.runAsync(() async {
      DragonBreathArt.sceneLight = false;
      final boss = _boss(5.34);
      final m = BossMotion(boss, reducedMotion: false);
      final mouth = _mouth(boss, m, 800);
      final px = await _breathFrame(5.34);
      // Walk the jet's axis (the middle of its solid extent, column by
      // column) from the jaws to the front.
      int? front;
      for (var x = mouth.dx.round() - 6; x > 0; x--) {
        for (var y = 0; y < _h; y++) {
          if (px.alpha(x, y) > 200) {
            front = x;
            break;
          }
        }
      }
      expect(front, isNotNull);
      final length = mouth.dx - front!;
      expect(length, greaterThan(60), reason: 'already a real plume by 5.34');
      (int, int, int, int) axis(double x) {
        int? first, last;
        for (var y = 0; y < _h; y++) {
          if (px.alpha(x.round(), y) > 200) {
            first ??= y;
            last = y;
          }
        }
        return px.at(x.round(), ((first! + last!) / 2).round());
      }

      final near = axis(mouth.dx - length * .12);
      final tip = axis(front + length * .3);
      // ignore: avoid_print
      print("ignition: length $length near $near tip $tip");
      // White-hot at the jaws: every channel high.
      expect(near.$1, greaterThan(235));
      expect(near.$2, greaterThan(225));
      expect(near.$3, greaterThan(190));
      // Orange (not white) at the tip: red high, blue low.
      expect(tip.$1, greaterThan(200));
      expect(tip.$3, lessThan(130), reason: 'the tip has cooled to orange');
      // The very first frames are a white-hot wedge: at 5.285 the axis just
      // ahead of the jaws is pure white.
      final first = await _breathFrame(5.285);
      final b0 = _boss(5.285);
      final mouth0 = _mouth(b0, BossMotion(b0, reducedMotion: false), 800);
      final flash = first.at((mouth0.dx - 14).round(), mouth0.dy.round());
      expect(
        [flash.$1, flash.$2, flash.$3].every((v) => v >= 205),
        isTrue,
        reason: 'white-hot frame at 5.285, got $flash (mouth $mouth0)',
      );
      // Not a flat wedge: the outline is torn into tongues, so its top edge
      // is not a straight line. Fit a line and measure the residual.
      final xs = <double>[], ys = <double>[];
      for (var x = front + 6; x < mouth.dx - 30; x++) {
        for (var y = 0; y < _h; y++) {
          if (px.alpha(x, y) > 140) {
            xs.add(x.toDouble());
            ys.add(y.toDouble());
            break;
          }
        }
      }
      expect(xs.length, greaterThan(30));
      double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;
      final mx = mean(xs), my = mean(ys);
      var sxy = 0.0, sxx = 0.0;
      for (var i = 0; i < xs.length; i++) {
        sxy += (xs[i] - mx) * (ys[i] - my);
        sxx += (xs[i] - mx) * (xs[i] - mx);
      }
      final slope = sxy / sxx;
      var residual = 0.0;
      for (var i = 0; i < xs.length; i++) {
        residual = math.max(
          residual,
          (ys[i] - (my + slope * (xs[i] - mx))).abs(),
        );
      }
      expect(residual, greaterThan(1.5), reason: 'not a flat wedge');
    });
  });

  testWidgets('the scene light visibly lights dark, mid and bright scenery', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The three regions the review uses; the backdrop is that region's own
      // sky at the clock the game would be showing it.
      for (final (region, minLift) in [
        (WorldRegion.cyberpunk, 10.0),
        (WorldRegion.antarctica, 10.0),
        (WorldRegion.egypt, 5.0),
      ]) {
        final seconds = region.index * WorldTour.leg + 9.0;
        final sky = region.palette;
        final backdrop = Color.lerp(sky.top, sky.horizon, .5)!;
        const t = 6.3;
        final lane = BreathLane.middle;
        final (top, bottom) = DragonBreath.band(lane);
        final y0 = top * _h, y1 = bottom * _h;
        DragonBreathArt.sceneLight = false;
        final off = await _breathFrame(t, backdrop: backdrop, seconds: seconds);
        DragonBreathArt.sceneLight = true;
        final on = await _breathFrame(t, backdrop: backdrop, seconds: seconds);
        // The scenery just outside the band, where the flame does not cover:
        // it must change visibly (brighter on dark and mid scenery, warmer on
        // a bright sky, where nothing can be brightened).
        var shift = 0.0, count = 0;
        for (var x = 40; x < 380; x += 2) {
          for (final y in [
            (y0 - _h * .035).round(),
            (y1 + _h * .035).round(),
          ]) {
            final a = on.at(x, y), b = off.at(x, y);
            shift +=
                ((a.$1 - b.$1).abs() +
                    (a.$2 - b.$2).abs() +
                    (a.$3 - b.$3).abs()) /
                3;
            count++;
          }
        }
        final lift = shift;
        // ignore: avoid_print
        print(
          '${region.name}: scene light shifts scenery next to the jet by ${(shift / count).toStringAsFixed(1)} of 255',
        );
        expect(shift / count, greaterThan(minLift), reason: region.name);
        // And it stays a light, not a second flame.
        expect(lift / count, lessThan(90), reason: region.name);
      }
    });
  });

  testWidgets(
    'the warning fades out before the jaws and keeps the safe band clear',
    (tester) async {
      await tester.runAsync(() async {
        for (final width in [640.0, 800.0]) {
          for (final lane in BreathLane.values) {
            for (final t in [4.3, 4.9, 5.4, 6.0]) {
              final boss = _boss(t, lane: lane);
              final m = BossMotion(boss, reducedMotion: false);
              final mouth = _mouth(boss, m, width);
              final px = await _breathFrame(
                t,
                lane: lane,
                width: width,
                warning: true,
                flame: false,
                marks: true,
              );
              final clear = (mouth.dx - _h * .06).round();
              var veil = 0;
              for (var x = clear + 2; x < width; x++) {
                for (var y = 0; y < _h; y++) {
                  if (px.alpha(x, y) > 0) veil++;
                }
              }
              expect(
                veil,
                0,
                reason: 'nothing over the dragon: $lane $t $width',
              );
              // The safe band carries a wash and a bank, never a veil: its
              // mean opacity stays low, so the scenery and the bird read.
              for (final (sTop, sBottom) in DragonBreath.safeBands(lane)) {
                var sum = 0.0, n = 0;
                for (var x = 10; x < mouth.dx - _h * .3; x += 3) {
                  for (
                    var y = (sTop * _h + _h * .1).round();
                    y < sBottom * _h - _h * .02;
                    y += 3
                  ) {
                    sum += px.alpha(x, y) / 255;
                    n++;
                  }
                }
                expect(
                  sum / n,
                  lessThan(.32),
                  reason: 'safe band stays clear: $lane $t',
                );
                if (t < 5.5) {
                  expect(
                    sum / n,
                    greaterThan(.05),
                    reason: 'but visibly washed: $lane $t',
                  );
                }
              }
            }
          }
        }
      });
    },
  );

  testWidgets('the inhale builds, holds at full and pulses twice as fast', (
    tester,
  ) async {
    await tester.runAsync(() async {
      Future<double> glow(double t, {bool reduced = false}) async {
        final px = await _breathFrame(
          t,
          warning: false,
          flame: false,
          inhale: true,
          reduced: reduced,
        );
        var sum = 0.0;
        for (var i = 3; i < px.bytes.length; i += 4) {
          sum += px.bytes[i] / 255;
        }
        return sum;
      }

      final a = await glow(4.15), b = await glow(4.6), c = await glow(4.9);
      expect(a, greaterThan(0), reason: 'the first sign of the inhale');
      expect(b, greaterThan(a));
      expect(c, greaterThan(b));
      // The hold is at full and pulses; the ramp before it pulses too but slower.
      final hold = [for (var t = 5.0; t < 5.2; t += .0167) await glow(t)];
      final ramp = [for (var t = 4.5; t < 4.7; t += .0167) await glow(t)];
      int flips(List<double> v) {
        var n = 0;
        for (var i = 2; i < v.length; i++) {
          if ((v[i] - v[i - 1]).sign != (v[i - 1] - v[i - 2]).sign) n++;
        }
        return n;
      }

      expect(
        flips(hold),
        greaterThan(flips(ramp)),
        reason: 'the hold pulses faster',
      );
      // Reduced Motion: steady (no pulse), still a full glow.
      final r1 = await glow(5.05, reduced: true),
          r2 = await glow(5.05, reduced: true);
      expect(r1, r2);
      expect(r1, greaterThan(b));
    });
  });

  testWidgets('the tag\'s three pips fill gold, orange, red and burn down', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Read the pip row of the high breath's tag (its layout is fixed:
      // plate 0.092 h tall, pips 0.014 h tall .7 pads above its bottom).
      const tall = _h * .092, pad = _h * .016, pipH = _h * .014;
      final (_, bottom) = DragonBreath.band(BreathLane.high);
      final cy = bottom * _h - tall * .95;
      final rowY = (cy + tall / 2 - pad * .7 - pipH / 2).round();

      /// The lit width of each pip colour, in pixels.
      Future<(int, int, int)> pips(double t) async {
        final px = await _breathFrame(
          t,
          lane: BreathLane.high,
          reduced: true,
          warning: false,
          flame: false,
          marks: true,
        );
        var gold = 0, orange = 0, red = 0;
        for (var x = 11; x < 260; x++) {
          final (r, g, b, a) = px.at(x, rowY);
          if (a < 100) continue;
          if (r > 240 && g > 160 && g < 200 && b < 90) gold++;
          if (r > 240 && g > 90 && g < 125 && b < 70) orange++;
          if (r > 240 && g > 45 && g < 75 && b > 55 && b < 95) red++;
        }
        return (gold, orange, red);
      }

      final early = await pips(4.2);
      expect(early.$1, greaterThan(4), reason: 'the first pip begins to fill');
      expect(early.$2 + early.$3, 0, reason: 'the others are still dark');
      final full = await pips(5.45);
      expect(full.$1, greaterThan(early.$1));
      expect(full.$2, greaterThan(10), reason: 'the second pip is lit');
      expect(full.$3, greaterThan(10), reason: 'and the third, red');
      // Burning down through the flame (drawn at .55 over a dark plate, so
      // read the lit width by brightness): they empty from the last.
      Future<int> lit(double t) async {
        final px = await _breathFrame(
          t,
          lane: BreathLane.high,
          reduced: true,
          warning: false,
          flame: false,
          marks: true,
        );
        var n = 0;
        for (var x = 11; x < 260; x++) {
          if (px.alpha(x, rowY) > 100 && px.luma(x, rowY) > 95) n++;
        }
        return n;
      }

      final l545 = await lit(5.45), l6 = await lit(6.0), l69 = await lit(6.9);
      expect(l6, lessThan(l545));
      expect(l69, lessThan(l6));
      expect(l69, greaterThan(0), reason: 'still burning down');
    });
  });

  testWidgets('every state has a Reduced Motion frame that keeps its meaning', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final frames = <double, Uint8List>{};
      for (final t in [4.1, 4.6, 5.05, 5.25, 5.3, 5.5, 6.3, 7.12, 7.3]) {
        // Whatever the world clock or how many breaths ago, the frame for
        // this moment of the cycle is the same still.
        final a = await _breathFrame(
          t,
          reduced: true,
          seconds: 12.3,
          warning: true,
          inhale: true,
          marks: true,
          mouthAt: const Offset(480, 150),
        );
        final b = await _breathFrame(
          t + DragonBreath.period,
          reduced: true,
          seconds: 12.3,
          warning: true,
          inhale: true,
          marks: true,
          mouthAt: const Offset(480, 150),
        );
        expect(
          _samePicture(a, b),
          isTrue,
          reason: 'reduced frame at $t is a still',
        );
        var painted = 0;
        for (var i = 3; i < a.bytes.length; i += 4) {
          if (a.bytes[i] > 0) painted++;
        }
        if (t < 7.3) {
          expect(
            painted,
            greaterThan(500),
            reason: 'state at $t must be readable',
          );
        }
        frames[t] = a.bytes;
      }
      final keys = frames.keys.toList();
      for (var i = 1; i < keys.length; i++) {
        expect(
          frames[keys[i]],
          isNot(equals(frames[keys[i - 1]])),
          reason: '${keys[i - 1]} and ${keys[i]} must differ',
        );
      }
    });
  });

  testWidgets('the breath is a pure function of the boss clock', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final t in _times) {
        for (final lane in BreathLane.values) {
          final a = await _breathFrame(
            t,
            lane: lane,
            warning: true,
            inhale: true,
            marks: true,
          );
          final b = await _breathFrame(
            t,
            lane: lane,
            warning: true,
            inhale: true,
            marks: true,
          );
          expect(a.bytes, equals(b.bytes), reason: '$lane at $t');
        }
      }
      // And it moves: the jet's tongues are not frozen in normal motion.
      final a = await _breathFrame(6.3);
      final b = await _breathFrame(6.35);
      expect(a.bytes, isNot(equals(b.bytes)));
    });
  });

  testWidgets('review sheets: nine moments x three lanes x dark, mid, bright', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final backdrops = <(String, WorldRegion, List<Color>)>[
        (
          'dark',
          WorldRegion.cyberpunk,
          const [Color(0xff1a1233), Color(0xff5b2a63)],
        ),
        (
          'mid',
          WorldRegion.antarctica,
          const [Color(0xff4d6a98), Color(0xffd6aeb9)],
        ),
        (
          'bright',
          WorldRegion.egypt,
          const [Color(0xff8fd0ee), Color(0xfff3e2b8)],
        ),
      ];
      // One sheet per backdrop, variant, lane and width: the nine moments in
      // a 3 x 3 grid at half size, each labelled with its time in the cycle.
      for (final width in [640.0, 800.0]) {
        for (final (name, region, colors) in backdrops) {
          for (final variant in ['normal', 'fury', 'reduced']) {
            for (final lane in BreathLane.values) {
              final cw = width / 2, ch = _h / 2;
              await _save(
                '$name-$variant-${lane.name}-${width.toInt()}',
                (cw * 3).round(),
                ((ch + 14) * 3).round(),
                (c) {
                  c.drawRect(
                    Rect.fromLTWH(0, 0, cw * 3, (ch + 14) * 3),
                    Paint()..color = const Color(0xff101223),
                  );
                  for (var i = 0; i < _times.length; i++) {
                    final t = _times[i];
                    final boss = _boss(t, lane: lane, fury: variant == 'fury');
                    boss
                      ..x = (width - 180) / _h
                      ..y = .5;
                    final m = BossMotion(
                      boss,
                      reducedMotion: variant == 'reduced',
                    );
                    final sim =
                        arena(version: FlightSimulation.currentRulesVersion)
                          ..elapsed = region.index * WorldTour.leg + 9.0
                          ..boss = boss
                          ..birdY = lane == BreathLane.low ? .25 : .8;
                    c.save();
                    c.translate(i % 3 * cw, i ~/ 3 * (ch + 14) + 14);
                    c.scale(.5);
                    c.clipRect(Rect.fromLTWH(0, 0, width, _h));
                    c.drawRect(
                      Rect.fromLTWH(0, 0, width, _h),
                      Paint()
                        ..shader = ui.Gradient.linear(
                          Offset.zero,
                          const Offset(0, _h),
                          colors,
                        ),
                    );
                    final ink = Paint()
                      ..color = colors[0].withValues(alpha: .85);
                    for (var k = 0; k < 14; k++) {
                      final w = 30.0 + (k * 37) % 40;
                      final hh = 40.0 + (k * 53) % 90;
                      c.drawRect(
                        Rect.fromLTWH(k * 62.0, 300 - hh, w, hh + 60),
                        ink,
                      );
                    }
                    BossEncounterArt.paint(c, Size(width, _h), sim, m);
                    c.restore();
                    (TextPainter(
                      text: TextSpan(
                        text: '${lane.name} ${t.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xffffffff),
                        ),
                      ),
                      textDirection: TextDirection.ltr,
                    )..layout()).paint(
                      c,
                      Offset(i % 3 * cw + 4, i ~/ 3 * (ch + 14)),
                    );
                  }
                },
              );
            }
          }
        }
      }
      expect(_folder.existsSync(), isTrue);
    });
  });

  test('the layout timeline the jet hangs on is the one the dragon uses', () {
    expect(DragonTimeline.igniteAt, DragonBreath.blastAt - .22);
    expect(DragonTimeline.holdAt, lessThan(DragonTimeline.snapAt));
    expect(
      DragonTimeline.snapAt + DragonTimeline.snapSeconds,
      closeTo(DragonTimeline.igniteAt, 1e-9),
    );
  });
}
