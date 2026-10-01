import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_crumb_art.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/game/star_art.dart';

import 'king_coo_helpers.dart' as rules;
import 'king_coo_test_kit.dart';

/// King Coo's crumb bombs (K5): the roll in flight, the telegraph ring, the
/// fury bracket, the crumb cloud and its sprinkle.
///
/// The art is the rules' geometry made visible, so most of this file measures
/// PIXELS against the rules, in both directions:
///  * the ring's outer edge is the cloud's full radius (never past it) and
///    its centre is where the rules locked it;
///  * the cloud's outermost pixel is `lob.cloudRadius(age)` at every instant
///    of its second (never past it, and reaching it), at 640 and 800, calm
///    and fury; and in a REAL flight the bird is hurt exactly where the
///    drawn cloud overlaps it;
///  * the corridor's brackets sit on the bird-centre-safe limits;
///  * the roll leaves the wing tip at the toss and lands on the ring's
///    middle on the frame the cloud begins, on a ballistic arc.
/// The rest is the contract every part of the rig keeps: budget, caches,
/// determinism in any order, Reduced Motion, finite inputs, draw order.
///
/// The review renders are written to `build/king-coo-crumbs/` (evidence).

const _h = 360.0;
const _arrival = 4.6;
const _widths = [640.0, 800.0];

/// A King Coo [combat] seconds into the fight on a [w]x360 screen, anchored
/// where the rules put him.
SkyBoss stageBoss(
  double w,
  double combat, {
  List<CrumbLob> lobs = const [],
  bool fury = false,
}) {
  final b = SkyBoss(
    number: 6,
    x: KingCooLayout.anchorX(birdX, w / _h),
    kind: BossKind.kingCoo,
    cinematic: true,
  );
  if (fury) {
    b.hp = b.maxHp ~/ 2;
    b.enragedAt = _arrival - 30;
  }
  b.lobs.addAll(lobs);
  b.age = _arrival + combat;
  b.y = KingCooLayout.hoverY(combat);
  return b;
}

/// A lob locked [lockCombat] seconds into the fight on the bird at [y].
CrumbLob lob(double lockCombat, {double y = .5, bool fury = false}) => CrumbLob(
  lockedAt: _arrival + lockCombat,
  lockX: birdX,
  lockY: y,
  fury: fury,
);

/// The staging K8 will give the effects: scenery, the backdrop slot, stars,
/// the boss's pass (figure, then the bombs in the air), the bird.
void stage(
  Canvas c,
  double w,
  SkyBoss boss, {
  double birdY = .5,
  bool reduced = false,
  WorldRegion region = WorldRegion.newYork,
  double seconds = 12,
  bool bird = true,
  bool figure = true,
  bool effects = true,
  bool bombs = true,
  bool scenery = true,
  List<Offset> stars = const [],
}) {
  final size = Size(w, _h);
  c.save();
  c.clipRect(Offset.zero & size);
  if (scenery) {
    SkyScenery.paint(
      c,
      size,
      seconds: seconds,
      distance: seconds * .36,
      held: region,
    );
  }
  final m = BossMotion(boss, reducedMotion: reduced);
  if (effects) KingCooCrumbArt.under(c, size, boss, m);
  for (final s in stars) {
    StarArt.paint(
      c,
      Offset(s.dx * _h, s.dy * _h),
      _h * StarArt.radius,
      seconds: 1,
      reducedMotion: reduced,
      phase: 0,
    );
  }
  if (figure) {
    final pose = KingCooPose(boss, m, light: regionLight(region, seconds));
    paintFigure(c, pose, Offset(boss.x * _h, boss.y * _h), _h);
  }
  if (effects && bombs) KingCooCrumbArt.flight(c, size, boss, m);
  if (bird) {
    final bw = _h * .145;
    c.save();
    c.translate(birdX * _h, birdY * _h);
    BirdPuppet.paint(
      c,
      Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
      bird: 0,
      wing: .3,
    );
    c.restore();
  }
  c.restore();
}

// ---------------------------------------------------------------- pixels --

/// A picture's pixels (straight RGBA) and what to ask of them.
class Pix {
  Pix(this.w, this.h, this.data);
  final int w, h;
  final Uint8List data;

  int alpha(int x, int y) => data[(y * w + x) * 4 + 3];
  int red(int x, int y) => data[(y * w + x) * 4];
  int green(int x, int y) => data[(y * w + x) * 4 + 1];
  int blue(int x, int y) => data[(y * w + x) * 4 + 2];

  /// The farthest pixel CENTRE from [c] with alpha at least [min], or 0.
  double reach(Offset c, int min, {bool Function(int x, int y)? where}) {
    var far = 0.0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (alpha(x, y) < min) continue;
        if (where != null && !where(x, y)) continue;
        final d = (Offset(x + .5, y + .5) - c).distance;
        if (d > far) far = d;
      }
    }
    return far;
  }

  /// The alpha-weighted centroid.
  Offset centroid() {
    var sx = 0.0, sy = 0.0, sum = 0.0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final a = alpha(x, y).toDouble();
        sx += a * (x + .5);
        sy += a * (y + .5);
        sum += a;
      }
    }
    return sum == 0 ? Offset.zero : Offset(sx / sum, sy / sum);
  }

  int count(int min) {
    var n = 0;
    for (var i = 3; i < data.length; i += 4) {
      if (data[i] >= min) n++;
    }
    return n;
  }

  bool get empty => count(1) == 0;
}

Future<Pix> pix(int w, void Function(Canvas c) draw, {int h = 360}) async =>
    Pix(w, h, await rawPixels(w, h, draw));

// ------------------------------------------------------------- op counting --

/// Counts what a frame asks of the canvas (draw calls, clips, layers, blurs).
class Count implements Canvas {
  Count([Canvas? inner]) : inner = inner ?? Canvas(ui.PictureRecorder());
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get clips => (counts['clipPath'] ?? 0) + (counts['clipRect'] ?? 0);
  int get layers => counts['saveLayer'] ?? 0;
  int get blurs => counts['maskFilter'] ?? 0;
  int get unforwarded => counts.entries
      .where((e) => e.key.startsWith('UNFORWARDED'))
      .fold(0, (a, e) => a + e.value);

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  int getSaveCount() => inner.getSaveCount();
  @override
  Float64List getTransform() => inner.getTransform();
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
    _n('clipPath');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    _n('clipRect');
    inner.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
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
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

Count ops(void Function(Canvas c) draw) {
  final c = Count();
  draw(c);
  return c;
}

// -------------------------------------------------------------------- main --

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const R = KingCoo.cloudRadius; // screen heights
  const rPx = R * _h;

  group('the ring marks the cloud\'s radius and the lock', () {
    test('the ring\'s outer edge is the cloud\'s full radius from the first '
        'frame to the burst, never past it', () async {
      for (final t in [.14, .4, .8, 1.3, 1.8, 1.89, 1.95, 2.1, 2.19, 2.2]) {
        final p = await pix(400, (c) {
          KingCooCrumbArt.ring(
            c,
            _h,
            const Offset(200, 180),
            t,
            reduced: false,
          );
        });
        const centre = Offset(200, 180);
        expect(
          p.reach(centre, 6),
          lessThanOrEqualTo(rPx + 1.0),
          reason: 'visible edge at t=$t never exceeds the radius that hurts',
        );
        expect(
          p.reach(centre, 100),
          greaterThanOrEqualTo(rPx - 1.0),
          reason: 'solid edge at t=$t reaches it',
        );
      }
    });

    test(
      'the ring is centred on the lock, in both rim styles, to 1 px',
      () async {
        for (final t in [.2, .9, 1.5, 2.0, 2.15]) {
          for (final reduced in [false, true]) {
            final p = await pix(400, (c) {
              KingCooCrumbArt.ring(
                c,
                _h,
                const Offset(200.3, 180.4),
                t,
                reduced: reduced,
              );
            });
            final c = p.centroid();
            expect(
              (c - const Offset(200.3, 180.4)).distance,
              lessThan(1.0),
              reason: 't=$t RM=$reduced centroid $c',
            );
          }
        }
      },
    );

    test('the target fills toward impact: the pips light one by one and the '
        'last 0.3 s are red', () async {
      Future<int> litPips(double t) async {
        // Count lit (gold or red, not cream) pips by sampling the eight spokes.
        final p = await pix(400, (c) {
          KingCooCrumbArt.ring(c, _h, const Offset(200, 180), t, reduced: true);
        });
        var lit = 0;
        for (var i = 0; i < 8; i++) {
          final a = -math.pi / 2 + (i + .5) * 2 * math.pi / 8;
          final d = rPx - _h * .0165 * .95 - _h * .014;
          final x = (200 + math.cos(a) * d).round();
          final y = (180 + math.sin(a) * d).round();
          final r = p.red(x, y), g = p.green(x, y), b = p.blue(x, y);
          final warm = r > 200 && b < 170 && g > 150; // gold, not cream
          final hot = r > 220 && g < 140; // red
          if (warm || hot) lit++;
        }
        return lit;
      }

      final seen = <int>[];
      for (final t in [.1, .5, .9, 1.3, 1.6, 1.85]) {
        seen.add(await litPips(t));
      }
      for (var i = 1; i < seen.length; i++) {
        expect(
          seen[i],
          greaterThanOrEqualTo(seen[i - 1]),
          reason: 'pips never go out: $seen',
        );
      }
      expect(seen.last, greaterThan(seen.first));
      // Red: the rim's colour in the urgent window is the stop red, and before
      // it it is gold.
      Future<Color> rimAt(double t) async {
        final p = await pix(400, (c) {
          KingCooCrumbArt.ring(c, _h, const Offset(200, 180), t, reduced: true);
        });
        // Just outside the rim's centre line (which is the cream core).
        final y = (180 - (rPx - _h * .0165 / 2 + 1.25)).round();
        return Color.fromARGB(
          255,
          p.red(200, y),
          p.green(200, y),
          p.blue(200, y),
        );
      }

      final early = await rimAt(1.0),
          late = await rimAt(KingCoo.telegraph - .1);
      expect(early.r, greaterThan(.8));
      expect(early.b, lessThan(.7), reason: 'gold: $early');
      expect(late.r, greaterThan(.85));
      expect(late.g, lessThan(.55), reason: 'red: $late');
    });

    test('the rim is at full strength 0.12 s after the lock: readable in under '
        'half a second', () async {
      Future<int> rim(double t) async {
        final p = await pix(400, (c) {
          KingCooCrumbArt.ring(
            c,
            _h,
            const Offset(200, 180),
            t,
            reduced: false,
          );
        });
        var n = 0;
        for (var y = 0; y < p.h; y++) {
          for (var x = 0; x < p.w; x++) {
            final d =
                (Offset(x + .5, y + .5) - const Offset(200, 180)).distance;
            if (d > rPx - 6 && p.alpha(x, y) >= 150) n++;
          }
        }
        return n;
      }

      final early = await rim(.12),
          later = await rim(.5),
          first = await rim(.04);
      expect(early / later, closeTo(1, .05));
      expect(
        first,
        lessThan(later * .6),
        reason: 'it fades in, it does not pop',
      );
      expect(early, greaterThan(400));
    });

    test(
      'no ring before the lock or after its hand-over to the cloud',
      () async {
        for (final t in [-.5, -1e-9]) {
          final p = await pix(400, (c) {
            KingCooCrumbArt.ring(
              c,
              _h,
              const Offset(200, 180),
              t,
              reduced: false,
            );
          });
          expect(p.empty, isTrue, reason: 't=$t');
        }
        final gone = await pix(400, (c) {
          KingCooCrumbArt.ring(
            c,
            _h,
            const Offset(200, 180),
            KingCoo.telegraph + KingCooCrumbArt.ringOut + .01,
            reduced: false,
          );
        });
        expect(gone.empty, isTrue);
      },
    );
  });

  group('the cloud is the rules\' cloud', () {
    Future<Pix> cloudAt(double s, {int seed = 3, bool reduced = false}) =>
        pix(400, (c) {
          KingCooCrumbArt.cloud(
            c,
            _h,
            const Offset(200, 180),
            s,
            seed: seed,
            reduced: reduced,
          );
        });

    test('at every instant of its second the outermost pixel is the hurt '
        'radius: never past it, and reaching it', () async {
      const centre = Offset(200, 180);
      for (var seed = 0; seed < 4; seed++) {
        for (var s = .01; s < 1.0; s += .0125) {
          final radius = KingCoo.cloudRadiusAt(s) * _h;
          final p = await cloudAt(s, seed: seed);
          final visible = p.reach(centre, 4);
          expect(
            visible,
            lessThanOrEqualTo(radius + 1.0),
            reason:
                's=$s seed=$seed: drawn ${visible.toStringAsFixed(2)} px vs rules ${radius.toStringAsFixed(2)}',
          );
          if (radius >= 8) {
            expect(
              p.reach(centre, 90),
              greaterThanOrEqualTo(radius - 1.2),
              reason: 's=$s seed=$seed: solid edge reaches the radius',
            );
            // The disc it fills is the disc that hurts, within 3 px on average.
            final area = p.count(90);
            final mean = math.sqrt(area / math.pi);
            expect(
              radius - mean,
              lessThan(3.2),
              reason: 's=$s mean radius $mean vs $radius',
            );
            expect(mean, lessThanOrEqualTo(radius + .6));
          }
        }
      }
    });

    test(
      'nothing of the cloud before the burst or from the end of its second',
      () async {
        for (final s in [-1.0, -1e-6, 1.0, 1.0001, 1.2]) {
          expect((await cloudAt(s)).empty, isTrue, reason: 's=$s');
        }
      },
    );

    test('through `under`, at 640 and 800, calm and fury: each cloud stands at '
        'the rules\' centre with the rules\' radius', () async {
      for (final w in _widths) {
        for (final fury in [false, true]) {
          final l = lob(.6, y: .5, fury: fury);
          for (final s in [.06, .11, .3, .6, .86, .93, .97]) {
            final boss = stageBoss(
              w,
              l.burstAt - _arrival + s,
              lobs: [l],
              fury: fury,
            );
            final m = BossMotion(boss, reducedMotion: false);
            final p = await pix(
              w.round(),
              (c) => KingCooCrumbArt.under(c, Size(w, _h), boss, m),
            );
            final r = l.cloudRadius(boss.age) * _h;
            for (final y in l.cloudHeights) {
              final centre = Offset(l.lockX * _h, y * _h);
              // Keep the other cloud (and the ring's hand-over) out of the measure.
              final near = p.reach(
                centre,
                4,
                // (The corridor's brackets lie further out than this.)
                where: (x, py) =>
                    (Offset(x + .5, py + .5) - centre).distance < rPx + 9,
              );
              final ring = s < KingCooCrumbArt.ringOut ? rPx : 0;
              expect(
                near,
                lessThanOrEqualTo(math.max(r, ring) + 1.0),
                reason: 'w=$w fury=$fury s=$s y=$y',
              );
              if (r >= 6) {
                expect(
                  near,
                  greaterThanOrEqualTo(r - 1.5),
                  reason: 'w=$w fury=$fury s=$s y=$y reaches',
                );
              }
            }
          }
        }
      }
    });

    test('a real flight: the bird is hurt exactly where the drawn cloud '
        'overlaps its body, both ways, at 640 and 800', () async {
      for (final w in _widths) {
        final sim = rules.cooFight(width: w / _h);
        final boss = sim.boss!;
        rules.runTo(sim, .7, hold: .4, protect: true);
        final l = boss.lobs.single;
        expect(l.lockY, closeTo(.4, 1e-9));
        // Into the cloud's hold (burst + .25 s), the bird out of the way.
        rules.runTo(
          sim,
          l.burstAt - boss.arrivalDuration + .25,
          hold: .8,
          protect: true,
        );
        expect(l.cloudRadius(boss.age), closeTo(R, 1e-9));
        // What is drawn now.
        final m = BossMotion(boss, reducedMotion: false);
        final p = await pix(
          w.round(),
          (c) => KingCooCrumbArt.under(c, Size(w, _h), boss, m),
        );
        final cx = (l.lockX * _h).round();
        final cy = l.lockY * _h;
        // The lowest drawn cloud pixel on the bird's column.
        var edge = 0.0;
        // (Only the cloud's own range: the next bomb's ring locks at 3.0 s on
        // the bird, lower down.)
        for (var y = cy.round(); y < (cy + rPx + 14).round(); y++) {
          if (p.alpha(cx, y) >= 90) edge = y + 1 - cy;
        }
        expect(
          (edge - rPx).abs(),
          lessThan(3.3),
          reason: 'w=$w drawn edge $edge vs $rPx',
        );
        const birdR = FlightSimulation.birdRadius * _h;
        var checked = 0;
        for (var d = rPx + birdR - 12; d <= rPx + birdR + 12; d += 1.0) {
          sim
            ..shield = true
            ..hearts = 3
            ..invulnerableUntil = 0
            ..birdY = (cy + d) / _h
            ..velocity = 0;
          rules.tick(sim, width: w / _h);
          final hurt = !sim.shield;
          final overlap = d - birdR < edge; // the bird's body touches the cloud
          if (d <= edge + birdR - 3.5) {
            expect(
              hurt,
              isTrue,
              reason: 'w=$w d=$d: the drawn cloud overlaps the bird: hurt',
            );
            expect(overlap, isTrue);
            checked++;
          } else if (d >= edge + birdR + 3.5) {
            expect(
              hurt,
              isFalse,
              reason: 'w=$w d=$d: clear of the drawn cloud: not hurt',
            );
            expect(overlap, isFalse);
            checked++;
          }
        }
        expect(checked, greaterThan(10));
      }
    });

    test('the cloud dims in its last 0.3 s but stays a clear hazard; it is '
        'chalky when it settles', () async {
      expect(KingCooCrumbArt.dim(.5), 1);
      expect(KingCooCrumbArt.dim(.7), 1);
      expect(KingCooCrumbArt.dim(1.0), closeTo(KingCooCrumbArt.dimFloor, 1e-9));
      var last = 1.0;
      for (var s = .7; s <= 1.0; s += .02) {
        final d = KingCooCrumbArt.dim(s);
        expect(d, lessThanOrEqualTo(last + 1e-12));
        last = d;
      }
      expect(KingCooCrumbArt.dimFloor, greaterThanOrEqualTo(.55));
      final full = await cloudAt(.5), faint = await cloudAt(.93);
      int meanAlpha(Pix p) {
        var sum = 0, n = 0;
        for (var y = 0; y < p.h; y++) {
          for (var x = 0; x < p.w; x++) {
            final a = p.alpha(x, y);
            if (a >= 30) {
              sum += a;
              n++;
            }
          }
        }
        return n == 0 ? 0 : sum ~/ n;
      }

      expect(meanAlpha(faint), lessThan(meanAlpha(full)));
      expect(
        meanAlpha(faint),
        greaterThan(110),
        reason: 'still solid enough to read as a hazard',
      );
    });

    test(
      'the sprinkle after it is sparse and harmless-looking: never a disc',
      () async {
        const centre = Offset(200, 180);
        for (final s in [.02, .1, .2, .3]) {
          final p = await pix(400, (c) {
            KingCooCrumbArt.sprinkle(c, _h, centre, s, seed: 5, reduced: false);
          });
          final within = p.count(s > .3 ? 8 : 30);
          // Far less than the cloud's own disc area.
          expect(
            within,
            lessThan(math.pi * rPx * rPx * .22),
            reason: 's=$s covers $within px',
          );
          expect(within, greaterThan(0));
        }
        final last = await pix(400, (c) {
          KingCooCrumbArt.sprinkle(c, _h, centre, .39, seed: 5, reduced: false);
        });
        expect(last.count(1), greaterThan(0), reason: 'faint, not gone');
        for (final s in [-.1, .4, .6]) {
          final p = await pix(400, (c) {
            KingCooCrumbArt.sprinkle(c, _h, centre, s, seed: 5, reduced: false);
          });
          expect(p.empty, isTrue, reason: 's=$s');
        }
      },
    );
  });

  group('the fury bracket', () {
    test('the corridor is exactly where the bird\'s centre is safe from both '
        'clouds, and exists only when both clouds stand', () {
      for (var y = KingCoo.lockMin; y <= KingCoo.lockMax; y += .02) {
        final l = CrumbLob(lockedAt: 5, lockX: birdX, lockY: y, fury: true);
        final lane = KingCooCrumbArt.corridor(l);
        final both = l.cloudHeights.length == 2;
        expect(lane != null, both, reason: 'lockY=$y');
        if (lane == null) continue;
        final (top, bottom) = lane;
        const reach = R + FlightSimulation.birdRadius;
        // At the limits the bird's body just touches a cloud.
        expect((top - l.cloudHeights.first).abs(), closeTo(reach, 1e-9));
        expect((bottom - l.cloudHeights.last).abs(), closeTo(reach, 1e-9));
        expect(top, lessThan(bottom));
        // The corridor is centred on the bird's old height.
        expect((top + bottom) / 2, closeTo(y, 1e-9));
        // Its middle is clear of both clouds, with room to spare.
        for (final c in l.cloudHeights) {
          expect(((top + bottom) / 2 - c).abs(), greaterThan(reach));
        }
      }
      expect(
        KingCooCrumbArt.corridor(lob(1, y: .3)),
        isNull,
        reason: 'calm: none',
      );
    });

    test('the brackets are drawn on the limits (pixels, to 1 px)', () async {
      final l = lob(.6, y: .5, fury: true);
      final lane = KingCooCrumbArt.corridor(l)!;
      for (final t in [.5, 1.2, 2.0, 2.6]) {
        final p = await pix(400, (c) {
          KingCooCrumbArt.bracket(
            c,
            _h,
            200,
            lane.$1 * _h,
            lane.$2 * _h,
            t,
            reduced: false,
          );
        });
        var top = 1e9, bottom = -1.0;
        for (var y = 0; y < p.h; y++) {
          for (var x = 0; x < p.w; x++) {
            // The go colour (62e6a0), solid.
            if (p.alpha(x, y) > 200 &&
                p.green(x, y) > 200 &&
                p.red(x, y) < 140 &&
                p.blue(x, y) < 200) {
              if (y < top) top = y.toDouble();
              if (y + 1 > bottom) bottom = y + 1.0;
            }
          }
        }
        const stroke = _h * .0075;
        expect(
          top,
          closeTo(lane.$1 * _h - stroke / 2, 1.2),
          reason: 't=$t top cap',
        );
        expect(
          bottom,
          closeTo(lane.$2 * _h + stroke / 2, 1.2),
          reason: 't=$t bottom cap',
        );
      }
    });

    test(
      'through `under` a fury lob draws two rings and the corridor',
      () async {
        final l = lob(.6, y: .5, fury: true);
        final boss = stageBoss(
          640,
          l.lockedAt - _arrival + 1.0,
          lobs: [l],
          fury: true,
        );
        final m = BossMotion(boss, reducedMotion: false);
        final p = await pix(
          640,
          (c) => KingCooCrumbArt.under(c, const Size(640, _h), boss, m),
        );
        for (final y in l.cloudHeights) {
          final centre = Offset(l.lockX * _h, y * _h);
          final near = p.reach(
            centre,
            6,
            where: (x, py) =>
                (Offset(x + .5, py + .5) - centre).distance < rPx + 9,
          );
          expect(near, closeTo(rPx, 1.1), reason: 'ring at $y');
        }
        // The corridor between them has green in it.
        var green = 0;
        final lane = KingCooCrumbArt.corridor(l)!;
        for (var y = (lane.$1 * _h).round(); y < (lane.$2 * _h).round(); y++) {
          for (var x = 100; x < 240; x++) {
            if (p.alpha(x, y) > 200 &&
                p.green(x, y) > 200 &&
                p.red(x, y) < 140) {
              green++;
            }
          }
        }
        expect(green, greaterThan(40));
      },
    );
  });

  group('the roll in flight', () {
    test('a ballistic arc: gravity .8, exactly from the hand to the ring', () {
      for (final to in const [
        Offset(.47, .14),
        Offset(.47, .5),
        Offset(.47, .86),
      ]) {
        for (final from in const [Offset(1.1, .45), Offset(1.45, .56)]) {
          expect(KingCooCrumbArt.arc(from, to, 0), from);
          expect(KingCooCrumbArt.arc(from, to, 1), to);
          const dt = 1 / 100;
          for (var u = .1; u <= .9; u += .05) {
            final y0 = KingCooCrumbArt.arc(
              from,
              to,
              u - dt / KingCoo.lobFlight,
            ).dy;
            final y1 = KingCooCrumbArt.arc(from, to, u).dy;
            final y2 = KingCooCrumbArt.arc(
              from,
              to,
              u + dt / KingCoo.lobFlight,
            ).dy;
            expect(
              (y0 - 2 * y1 + y2) / (dt * dt),
              closeTo(KingCoo.bombGravity, 1e-6),
            );
            // Constant horizontal speed.
            final x = KingCooCrumbArt.arc(from, to, u).dx;
            expect(x, closeTo(from.dx + (to.dx - from.dx) * u, 1e-12));
          }
          // On the screen all the way (the report's arc never leaves the sky).
          for (var u = 0.0; u <= 1; u += .02) {
            final p = KingCooCrumbArt.arc(from, to, u);
            expect(p.dy, inInclusiveRange(0, 1), reason: '$from -> $to at $u');
          }
        }
      }
    });

    test('it leaves the wing tip: the screen release is the pose\'s hand at the '
        'toss, within .15 of the layout\'s release point', () {
      for (final w in _widths) {
        for (final reduced in [false, true]) {
          for (final y in [.2, .5, .8]) {
            final l = lob(.6, y: y);
            final boss = stageBoss(w, l.launchAt - _arrival, lobs: [l]);
            final m = BossMotion(boss, reducedMotion: reduced);
            final from = KingCooCrumbArt.release(boss, m, l);
            final pose = KingCooPose(boss, m, at: l.launchAt);
            final anchor = Offset(
              boss.x,
              KingCooLayout.hoverY(l.launchAt - _arrival),
            );
            expect(
              from,
              offsetCloseTo(
                anchor + KingCooBossRig.bombOrigin(pose) * SkyBoss.radius,
                1e-12,
              ),
            );
            final nominal =
                anchor + KingCooBossRig.lobReleaseAt(pose) * SkyBoss.radius;
            expect(
              (from - nominal).distance / SkyBoss.radius,
              lessThan(KingCooLayout.lobReleaseTolerance + .03),
              reason:
                  'w=$w RM=$reduced: ${(from - nominal).distance / SkyBoss.radius} units off',
            );
          }
        }
      }
    });

    test('the held roll and the flying roll are one sprite: same place, same '
        'size, same turn at the toss (normal and Reduced Motion)', () async {
      for (final reduced in [false, true]) {
        const w = 640.0;
        final l = lob(.6, y: .5);
        // Just before the toss the rig paints the roll in his hand.
        final before = stageBoss(w, l.launchAt - _arrival - 1e-6, lobs: [l]);
        final pose = poseOf(before, reduced: reduced);
        expect(pose.bombHeld, 1);
        expect(
          pose.bombSpin,
          closeTo(
            reduced ? KingCooCrumbArt.stillTilt : KingCooCrumbArt.handSpin,
            2e-4,
          ),
        );
        final held = await pix(640, (c) {
          paintFigure(
            c,
            pose,
            Offset(before.x * _h, before.y * _h),
            _h,
            only: {'bomb'},
          );
        });
        // At the toss the flight draws it from the hand.
        final at = stageBoss(w, l.launchAt - _arrival, lobs: [l]);
        final m = BossMotion(at, reducedMotion: reduced);
        expect(
          poseOf(at, reduced: reduced).bombHeld,
          0,
          reason: 'the hand lets go',
        );
        final from = KingCooCrumbArt.release(at, m, l);
        final flying = await pix(640, (c) {
          KingCooCrumbArt.roll(
            c,
            _h,
            from,
            Offset(l.lockX, l.lockY),
            0,
            reduced: reduced,
            trail: false,
          );
        });
        expect(held.count(200), greaterThan(300));
        expect((held.centroid() - flying.centroid()).distance, lessThan(.5));
        expect(
          (held.count(200) - flying.count(200)).abs() / flying.count(200),
          lessThan(.02),
        );
        // The same turn: the two sprites overlap almost completely.
        var both = 0, either = 0;
        for (var y = 0; y < held.h; y++) {
          for (var x = 0; x < held.w; x++) {
            final a = held.alpha(x, y) > 200, b = flying.alpha(x, y) > 200;
            if (a && b) both++;
            if (a || b) either++;
          }
        }
        expect(both / either, greaterThan(.93), reason: 'RM=$reduced');
      }
    });

    test(
      'it lands on the ring\'s middle on the frame the cloud begins',
      () async {
        for (final w in _widths) {
          final l = lob(.6, y: .62);
          final boss = stageBoss(w, l.burstAt - _arrival - 1e-4, lobs: [l]);
          final m = BossMotion(boss, reducedMotion: false);
          final from = KingCooCrumbArt.release(boss, m, l);
          final to = Offset(l.lockX, l.lockY);
          final p = await pix(w.round(), (c) {
            KingCooCrumbArt.roll(
              c,
              _h,
              from,
              to,
              l.burstAt - l.launchAt - 1e-4,
              reduced: false,
              trail: false,
            );
          });
          expect(
            (p.centroid() - to * _h).distance,
            lessThan(1.0),
            reason: 'w=$w',
          );
          // And from the burst on there is no roll: the cloud has it.
          final burst = stageBoss(w, l.burstAt - _arrival, lobs: [l]);
          final after = await pix(w.round(), (c) {
            final m = BossMotion(burst, reducedMotion: false);
            KingCooCrumbArt.rolls(c, Size(w, _h), burst, m, near: true);
            KingCooCrumbArt.rolls(c, Size(w, _h), burst, m, near: false);
          });
          expect(after.empty, isTrue);
        }
      },
    );

    test('a roll leaves his wing over the figure and flies on under the stars '
        'once it is clear of him, in exactly one of the two layers', () async {
      for (final w in _widths) {
        final l = lob(.6, y: .5);
        var overFigure = 0, underStars = 0;
        for (var s = 0.0; s < KingCoo.lobFlight - .01; s += .035) {
          final boss = stageBoss(w, l.launchAt - _arrival + s, lobs: [l]);
          final m = BossMotion(boss, reducedMotion: true);
          final near = await pix(
            w.round(),
            (c) => KingCooCrumbArt.rolls(c, Size(w, _h), boss, m, near: true),
          );
          final far = await pix(
            w.round(),
            (c) => KingCooCrumbArt.rolls(c, Size(w, _h), boss, m, near: false),
          );
          // One layer or the other, never both and never neither.
          expect(near.empty != far.empty, isTrue, reason: 'w=$w s=$s');
          // `flight` is the near half.
          final viaFlight = await pix(
            w.round(),
            (c) => KingCooCrumbArt.flight(c, Size(w, _h), boss, m),
          );
          expect(viaFlight.empty, near.empty);
          if (!near.empty) {
            overFigure++;
          } else {
            underStars++;
          }
        }
        expect(
          overFigure,
          greaterThan(2),
          reason: 'it leaves his wing over him',
        );
        expect(
          underStars,
          greaterThan(15),
          reason: 'then flies under the stars',
        );
        // The hand-over is where the sprite is clear of his envelope: at the
        // switch the roll is farther from his chest than his beak reaches.
        expect(
          KingCooCrumbArt.nearKing,
          greaterThan(
            -KingCooLayout.envelope.left + KingCooCrumbArt.flightRadius,
          ),
        );
      }
    });

    test('the roll grows from the hand\'s size as it comes down, and never '
        'past ${KingCooCrumbArt.flightRadius} units', () {
      expect(KingCooCrumbArt.flightSize(0), KingCooLayout.bombRadius);
      expect(KingCooCrumbArt.flightSize(1), KingCooCrumbArt.flightRadius);
      var last = 0.0;
      for (var f = 0.0; f <= 1; f += .05) {
        final r = KingCooCrumbArt.flightSize(f);
        expect(r, greaterThanOrEqualTo(last));
        last = r;
      }
    });

    test('a fury toss throws a pair: one roll to each ring', () async {
      final l = lob(.6, y: .5, fury: true);
      final boss = stageBoss(
        640,
        l.launchAt - _arrival + .7,
        lobs: [l],
        fury: true,
      );
      final m = BossMotion(boss, reducedMotion: true);
      final p = await pix(640, (c) {
        KingCooCrumbArt.rolls(c, const Size(640, _h), boss, m, near: true);
        KingCooCrumbArt.rolls(c, const Size(640, _h), boss, m, near: false);
      });
      // Reduced Motion draws no sparkle: two rolls and their dotted arcs.
      final from = KingCooCrumbArt.release(boss, m, l);
      for (final y in l.cloudHeights) {
        final f = l.flight(boss.age);
        final at = KingCooCrumbArt.arc(from, Offset(l.lockX, y), f) * _h;
        var solid = 0;
        for (var py = (at.dy - 14).round(); py < (at.dy + 14).round(); py++) {
          for (var px = (at.dx - 14).round(); px < (at.dx + 14).round(); px++) {
            if (p.alpha(px, py) > 200) solid++;
          }
        }
        expect(solid, greaterThan(250), reason: 'a roll near $at');
      }
    });
  });

  group('where it is drawn: under the bird and the stars', () {
    test(
      'the effects leave the canvas as they found it, so what is drawn after '
      '(the stars, the bird) is untouched',
      () async {
        const w = 640.0;
        final l = lob(.6, y: .5);
        final lobs = [l, lob(2.4, y: .3, fury: true)];
        for (final s in [
          .05,
          .4,
          .9,
          1.4,
          2.0,
          2.19,
          2.3,
          2.6,
          3.4,
          3.9,
          4.3,
        ]) {
          for (final reduced in [false, true]) {
            final boss = stageBoss(w, l.lockedAt - _arrival + s, lobs: lobs);
            final m = BossMotion(boss, reducedMotion: reduced);
            final c = Count();
            c.translate(12, 7);
            final before = c.getTransform();
            final saves = c.getSaveCount();
            KingCooCrumbArt.under(c, const Size(w, _h), boss, m);
            expect(
              c.getSaveCount(),
              saves,
              reason: 's=$s: saves balance (under)',
            );
            expect(
              c.getTransform(),
              orderedEquals(before),
              reason: 's=$s: transform restored (under)',
            );
            KingCooCrumbArt.flight(c, const Size(w, _h), boss, m);
            expect(
              c.getSaveCount(),
              saves,
              reason: 's=$s: saves balance (flight)',
            );
            expect(
              c.getTransform(),
              orderedEquals(before),
              reason: 's=$s: transform restored (flight)',
            );
          }
        }
        // And what comes after is pixel-identical with or without them: an
        // opaque probe star and an opaque probe bird, drawn after the
        // backdrop slot and after the boss's pass, as K8 stages them.
        Future<Pix> probes(SkyBoss boss, bool on) => pix(640, (c) {
          final m = BossMotion(boss, reducedMotion: false);
          if (on) KingCooCrumbArt.under(c, const Size(w, _h), boss, m);
          for (final st in const [
            Offset(birdX + .02, .45),
            Offset(birdX - .03, .56),
            Offset(birdX, .5),
          ]) {
            c.drawCircle(st * _h, 9, Paint()..color = const Color(0xffffd23f));
          }
          if (on) KingCooCrumbArt.flight(c, const Size(w, _h), boss, m);
          c.drawCircle(
            const Offset(birdX, .5) * _h,
            19,
            Paint()..color = const Color(0xffff8f63),
          );
        });
        for (final s in [.4, .9, 2.0, 2.3, 2.6, 3.2]) {
          final boss = stageBoss(w, l.lockedAt - _arrival + s, lobs: [l]);
          expect(boss.liveLobs, isNotEmpty);
          final off = await probes(boss, false), on = await probes(boss, true);
          var covered = 0;
          for (var y = 0; y < off.h; y++) {
            for (var x = 0; x < off.w; x++) {
              if (off.alpha(x, y) < 255) continue;
              covered++;
              expect(
                [on.red(x, y), on.green(x, y), on.blue(x, y), on.alpha(x, y)],
                [off.red(x, y), off.green(x, y), off.blue(x, y), 255],
                reason: 's=$s: probe pixel ($x,$y) was covered',
              );
            }
          }
          expect(covered, greaterThan(1000));
        }
      },
    );

    test('with no bomb in the air the effects draw nothing at all', () async {
      final calm = stageBoss(640, 1.0);
      final fighting = await pix(
        640,
        (c) => KingCooCrumbArt.under(
          c,
          const Size(640, _h),
          calm,
          BossMotion(calm, reducedMotion: false),
        ),
      );
      expect(fighting.empty, isTrue);
      // Gone: a lob whose second and sprinkle are over.
      final l = lob(.6);
      final late = stageBoss(640, l.crumbsEndAt - _arrival + .01, lobs: [l]);
      final p = await pix(640, (c) {
        final m = BossMotion(late, reducedMotion: false);
        KingCooCrumbArt.under(c, const Size(640, _h), late, m);
        KingCooCrumbArt.flight(c, const Size(640, _h), late, m);
      });
      expect(p.empty, isTrue);
      // An arriving boss has no bombs.
      final arriving = SkyBoss(
        number: 6,
        x: 2,
        kind: BossKind.kingCoo,
        cinematic: true,
      )..age = 2;
      final q = await pix(
        640,
        (c) => KingCooCrumbArt.under(
          c,
          const Size(640, _h),
          arriving,
          BossMotion(arriving, reducedMotion: false),
        ),
      );
      expect(q.empty, isTrue);
    });
  });

  group('determinism and Reduced Motion', () {
    /// Every effect state worth checking, as (name, boss, reduced).
    List<(String, SkyBoss, bool)> states() {
      final out = <(String, SkyBoss, bool)>[];
      for (final fury in [false, true]) {
        final l = lob(.6, y: fury ? .5 : .35, fury: fury);
        for (final t in [
          .05,
          .9,
          1.9,
          2.1,
          2.19,
          2.24,
          2.8,
          3.4,
          3.9,
          4.01,
          4.3,
        ]) {
          for (final reduced in [false, true]) {
            out.add((
              'fury=$fury t=$t RM=$reduced',
              stageBoss(640, l.lockedAt - _arrival + t, lobs: [l], fury: fury),
              reduced,
            ));
          }
        }
      }
      return out;
    }

    Future<Uint8List> shot(SkyBoss b, bool reduced) => rawPixels(320, 360, (c) {
      final m = BossMotion(b, reducedMotion: reduced);
      KingCooCrumbArt.under(c, const Size(640, _h), b, m);
      KingCooCrumbArt.flight(c, const Size(640, _h), b, m);
    });

    test(
      'the same pixels in any order with the caches emptied',
      timeout: const Timeout(Duration(seconds: 150)),
      () async {
        final all = states();
        final reference = <String, Uint8List>{};
        for (final (name, b, reduced) in all) {
          reference[name] = await shot(b, reduced);
        }
        for (final order in [
          all.reversed.toList(),
          [...all]..shuffle(math.Random(7)),
        ]) {
          KingCooKit.clearCaches();
          for (final (name, b, reduced) in order) {
            expect(
              await shot(b, reduced),
              orderedEquals(reference[name]!),
              reason: name,
            );
          }
        }
      },
    );

    test(
      'Reduced Motion holds every motion still and keeps every state',
      () async {
        final l = lob(.6, y: .5);
        // A cloud that is holding: Reduced Motion frames are identical, the
        // full-motion ones drift.
        Future<Uint8List> cloud(double s, bool reduced) {
          final b = stageBoss(640, l.burstAt - _arrival + s, lobs: [l]);
          return shot(b, reduced);
        }

        expect(await cloud(.3, true), orderedEquals(await cloud(.5, true)));
        expect(
          await cloud(.3, false),
          isNot(orderedEquals(await cloud(.5, false))),
        );
        // Its fade and its sprinkle are states: they stay.
        expect(
          await cloud(.5, true),
          isNot(orderedEquals(await cloud(.95, true))),
        );
        expect(
          await cloud(1.02, true),
          isNot(orderedEquals(await cloud(1.3, true))),
        );
        // The channels themselves.
        for (final t in [0.0, .3, 1.0, 2.0]) {
          expect(KingCooCrumbArt.march(t, true), 0);
          expect(KingCooCrumbArt.slide(t, true), 1);
          expect(KingCooCrumbArt.pulse(t, true), 1);
          expect(KingCooCrumbArt.drift(t, true), 0);
          expect(KingCooCrumbArt.spinAt(t, true), KingCooCrumbArt.stillTilt);
        }
        expect(KingCooCrumbArt.march(1, false), isNot(0));
        expect(KingCooCrumbArt.slide(0, false), 0);
        expect(KingCooCrumbArt.slide(.3, false), 1);
        expect(
          KingCooCrumbArt.spinAt(0, false),
          KingCooCrumbArt.handSpin,
          reason: 'out of the hand\'s spin',
        );
        expect(
          KingCooCrumbArt.spinAt(.5, false),
          greaterThan(KingCooCrumbArt.spinAt(.1, false)),
        );
        // The ring's fill and pips are states: in Reduced Motion they still grow.
        final early = lob(.6);
        final a = stageBoss(640, early.lockedAt - _arrival + .5, lobs: [early]);
        final b = stageBoss(
          640,
          early.lockedAt - _arrival + 1.6,
          lobs: [early],
        );
        expect(await shot(a, true), isNot(orderedEquals(await shot(b, true))));
      },
    );

    test(
      'the spin hands over from the rig\'s: the hand turns 6 rad at the toss',
      () {
        final l = lob(.6, y: .5);
        final b = stageBoss(640, l.launchAt - _arrival - 1e-6, lobs: [l]);
        expect(poseOf(b).bombSpin, closeTo(KingCooCrumbArt.handSpin, 2e-4));
      },
    );
  });

  group('the budget', () {
    const size = Size(640, _h);

    test(
      'a roll is at most ${KingCooBudget.bomb} ops at every point of its flight',
      () {
        var worst = 0;
        for (var f = 0.0; f <= 1; f += .02) {
          for (final spin in [0.0, 1.0, 2.5]) {
            final n = ops(
              (c) => KingCooCrumbArt.bomb(
                c,
                Offset.zero,
                KingCooCrumbArt.flightSize(f),
                spin: spin,
              ),
            ).draws;
            worst = math.max(worst, n);
          }
        }
        expect(worst, lessThanOrEqualTo(KingCooBudget.bomb));
        // ... and the flying roll with its dotted arc, its crumbs and its
        // grains adds a handful, never a layer.
        var flight = 0;
        for (var s = 0.0; s < KingCoo.lobFlight; s += .02) {
          final n = ops(
            (c) => KingCooCrumbArt.roll(
              c,
              _h,
              const Offset(1.1, .5),
              const Offset(.47, .5),
              s,
              reduced: false,
            ),
          ).draws;
          flight = math.max(flight, n);
        }
        expect(flight, lessThanOrEqualTo(KingCooBudget.bomb + 12));
      },
    );

    test(
      'a ring is at most ${KingCooBudget.ring} ops, a cloud ${KingCooBudget.cloud}, a '
      'corridor ${KingCooBudget.ring ~/ 2}; no layer, no blur, no clip',
      () {
        var ring = 0, cloud = 0, lane = 0, sprinkle = 0;
        for (var t = 0.0; t <= KingCoo.telegraph + .13; t += .01) {
          for (final reduced in [false, true]) {
            final r = ops(
              (c) => KingCooCrumbArt.ring(
                c,
                _h,
                const Offset(200, 180),
                t,
                reduced: reduced,
              ),
            );
            ring = math.max(ring, r.draws);
            expect(
              [r.layers, r.blurs, r.clips, r.unforwarded],
              [0, 0, 0, 0],
              reason: 'ring t=$t',
            );
          }
        }
        for (var s = 0.0; s <= 1.0; s += .01) {
          for (final reduced in [false, true]) {
            final k = ops(
              (c) => KingCooCrumbArt.cloud(
                c,
                _h,
                const Offset(200, 180),
                s,
                seed: 2,
                reduced: reduced,
              ),
            );
            cloud = math.max(cloud, k.draws);
            expect(
              [k.layers, k.blurs, k.clips, k.unforwarded],
              [0, 0, 0, 0],
              reason: 'cloud s=$s',
            );
          }
        }
        for (var t = 0.0; t <= 3.4; t += .02) {
          final k = ops(
            (c) => KingCooCrumbArt.bracket(
              c,
              _h,
              200,
              120,
              240,
              t,
              reduced: false,
            ),
          );
          lane = math.max(lane, k.draws);
          expect([k.layers, k.blurs, k.clips], [0, 0, 0]);
        }
        for (var s = 0.0; s <= .4; s += .01) {
          final k = ops(
            (c) => KingCooCrumbArt.sprinkle(
              c,
              _h,
              const Offset(200, 180),
              s,
              seed: 1,
              reduced: false,
            ),
          );
          sprinkle = math.max(sprinkle, k.draws);
        }
        // ignore: avoid_print
        print(
          'crumb budget (worst per element): ring $ring/${KingCooBudget.ring}, '
          'cloud $cloud/${KingCooBudget.cloud}, bracket $lane, sprinkle $sprinkle',
        );
        expect(ring, lessThanOrEqualTo(KingCooBudget.ring));
        expect(cloud, lessThanOrEqualTo(KingCooBudget.cloud));
        expect(lane, lessThanOrEqualTo(KingCooBudget.ring ~/ 2));
        expect(sprinkle, lessThanOrEqualTo(8));
      },
    );

    test('the worst frames of a whole fight, calm and fury, stay in the sum of '
        'the shares; every frame builds no shader after the prewarm', () {
      KingCooBossRig.prewarm();
      final built = KingCooKit.shadersBuilt;
      var worstUnder = 0, worstFlight = 0;
      for (final fury in [false, true]) {
        // A real fight's lobs: calm 0.6/3.0, fury 0.6/2.4/4.2, two cycles.
        final lobs = <CrumbLob>[
          for (var cycle = 0; cycle < 2; cycle++)
            for (final lock in KingCoo.locks(fury: fury))
              CrumbLob(
                lockedAt: _arrival + cycle * KingCoo.period + lock,
                lockX: birdX,
                lockY:
                    .3 +
                    .4 *
                        math.Random(
                          cycle * 7 + (lock * 10).round(),
                        ).nextDouble(),
                fury: fury,
              ),
        ];
        for (var t = _arrival; t < _arrival + 30; t += 1 / 30) {
          final b = stageBoss(640, t - _arrival, lobs: lobs, fury: fury);
          final m = BossMotion(b, reducedMotion: false);
          final u = ops((c) => KingCooCrumbArt.under(c, size, b, m));
          final f = ops((c) => KingCooCrumbArt.flight(c, size, b, m));
          worstUnder = math.max(worstUnder, u.draws);
          worstFlight = math.max(worstFlight, f.draws);
          expect(
            [
              u.layers + f.layers,
              u.blurs + f.blurs,
              u.clips + f.clips,
              u.unforwarded + f.unforwarded,
            ],
            [0, 0, 0, 0],
          );
        }
      }
      // ignore: avoid_print
      print(
        'crumb budget (worst frame): under $worstUnder, flight $worstFlight',
      );
      // At most two clouds + two rings + a corridor, and two rolls with
      // their trails (fury's pair).
      expect(
        worstUnder,
        lessThanOrEqualTo(
          2 * KingCooBudget.cloud +
              2 * KingCooBudget.ring +
              KingCooBudget.ring ~/ 2 +
              2 * (KingCooBudget.bomb + 12),
        ),
      );
      expect(worstFlight, lessThanOrEqualTo(2 * (KingCooBudget.bomb + 12)));
      expect(
        KingCooKit.shadersBuilt,
        built,
        reason: 'no shader built after the prewarm',
      );
    });

    test(
      '`bomb` alone builds every shader the effects need (the rig\'s prewarm '
      'calls it), so no frame of the fight does',
      () {
        KingCooKit.clearCaches();
        KingCooBossRig.prewarm();
        final after = KingCooKit.shadersBuilt;
        final l = lob(.6);
        for (final t in [.1, 1.0, 2.0, 2.3, 2.6, 3.4, 3.7]) {
          final b = stageBoss(640, l.lockedAt - _arrival + t, lobs: [l]);
          final m = BossMotion(b, reducedMotion: false);
          ops((c) {
            KingCooCrumbArt.under(c, size, b, m);
            KingCooCrumbArt.flight(c, size, b, m);
          });
        }
        expect(KingCooKit.shadersBuilt, after);
      },
    );

    test(
      'a frame of effects is cheap to build (mean under 1.5 ms on this machine)',
      () {
        final l = lob(.6, y: .5, fury: true);
        final sw = Stopwatch()..start();
        var n = 0;
        for (var t = 0.0; t < 6; t += .02) {
          final b = stageBoss(
            640,
            l.lockedAt - _arrival + t,
            lobs: [l],
            fury: true,
          );
          final m = BossMotion(b, reducedMotion: false);
          ops((c) {
            KingCooCrumbArt.under(c, size, b, m);
            KingCooCrumbArt.flight(c, size, b, m);
          });
          n++;
        }
        expect(sw.elapsedMicroseconds / n / 1000, lessThan(1.5));
      },
    );
  });

  group('safe on any input', () {
    test('NaN and infinity draw nothing and throw nothing', () {
      const nan = double.nan, inf = double.infinity;
      final c = Canvas(ui.PictureRecorder());
      for (final bad in [nan, inf, -inf]) {
        KingCooCrumbArt.bomb(c, Offset(bad, 0), .3);
        KingCooCrumbArt.bomb(c, Offset.zero, bad);
        KingCooCrumbArt.bomb(c, Offset.zero, .3, spin: bad, alpha: bad);
        KingCooCrumbArt.ring(c, _h, Offset(bad, 3), 1, reduced: false);
        KingCooCrumbArt.ring(c, bad, const Offset(3, 3), 1, reduced: false);
        KingCooCrumbArt.ring(c, _h, const Offset(3, 3), bad, reduced: true);
        KingCooCrumbArt.cloud(
          c,
          _h,
          Offset(bad, 3),
          .5,
          seed: 1,
          reduced: false,
        );
        KingCooCrumbArt.cloud(
          c,
          _h,
          const Offset(3, 3),
          bad,
          seed: 1,
          reduced: false,
        );
        KingCooCrumbArt.cloud(
          c,
          bad,
          const Offset(3, 3),
          .5,
          seed: 1,
          reduced: false,
        );
        KingCooCrumbArt.sprinkle(
          c,
          _h,
          Offset(3, bad),
          .1,
          seed: 1,
          reduced: false,
        );
        KingCooCrumbArt.sprinkle(
          c,
          _h,
          const Offset(3, 3),
          bad,
          seed: 1,
          reduced: false,
        );
        KingCooCrumbArt.bracket(c, _h, bad, 10, 100, 1, reduced: false);
        KingCooCrumbArt.bracket(c, _h, 10, bad, 100, 1, reduced: false);
        KingCooCrumbArt.roll(
          c,
          _h,
          Offset(bad, 0),
          const Offset(.5, .5),
          .5,
          reduced: false,
        );
        KingCooCrumbArt.roll(
          c,
          _h,
          const Offset(1, .5),
          Offset(.5, bad),
          .5,
          reduced: false,
        );
        KingCooCrumbArt.roll(
          c,
          _h,
          const Offset(1, .5),
          const Offset(.5, .5),
          bad,
          reduced: false,
        );
      }
      // A boss or a lob with a bad time or place.
      for (final bad in [nan, inf, -inf]) {
        final good = lob(.6, y: .5);
        final lobs = [
          CrumbLob(lockedAt: bad, lockX: birdX, lockY: .5),
          CrumbLob(lockedAt: _arrival + .6, lockX: bad, lockY: .5),
          CrumbLob(lockedAt: _arrival + .6, lockX: birdX, lockY: bad),
          good,
        ];
        for (final age in [bad, _arrival + 2.0, _arrival + 3.3]) {
          for (final size in [
            const Size(640, _h),
            Size(640, bad),
            Size(bad, _h),
            Size.zero,
          ]) {
            final boss = stageBoss(640, 1, lobs: lobs)..age = age;
            final m = BossMotion(boss, reducedMotion: false);
            KingCooCrumbArt.under(c, size, boss, m);
            KingCooCrumbArt.flight(c, size, boss, m);
          }
        }
      }
    });
  });

  group('evidence', () {
    /// A contact sheet of [frames] (name, combat second, bird height) of a
    /// boss built by [boss], [cols] columns.
    Future<void> sheet(
      String name,
      double w,
      List<(String, double, double)> frames,
      SkyBoss Function(double t) boss, {
      int cols = 2,
      bool reduced = false,
      WorldRegion region = WorldRegion.newYork,
      double seconds = 12,
      List<Offset> stars = const [],
    }) async {
      final rows = (frames.length / cols).ceil();
      await savePng(name, (w * cols).round(), (_h * rows).round(), (c) {
        for (var i = 0; i < frames.length; i++) {
          final (name_, t, by) = frames[i];
          c.save();
          c.translate((i % cols) * w, (i ~/ cols) * _h);
          stage(
            c,
            w,
            boss(t),
            birdY: by,
            reduced: reduced,
            region: region,
            seconds: seconds,
            stars: stars,
          );
          label(
            c,
            name_,
            const Offset(8, 336),
            color: const Color(0xffffffff),
            size: 13,
          );
          c.restore();
        }
      }, dir: 'build/king-coo-crumbs');
    }

    List<(String, double, double)> calmFrames(CrumbLob l, double by0) => [
      ('lock +.05', l.lockedAt - _arrival + .05, by0),
      ('wind-up hold', l.lockedAt - _arrival + .6, by0),
      ('toss', l.launchAt - _arrival + .02, by0),
      ('flight +.4', l.launchAt - _arrival + .4, by0 + .1),
      ('flight +.9', l.launchAt - _arrival + .9, by0 + .2),
      ('urgent', l.burstAt - _arrival - .15, by0 + .24),
      ('burst +.04', l.burstAt - _arrival + .04, by0 + .24),
      ('cloud +.5', l.burstAt - _arrival + .5, by0 + .24),
      ('cloud +.88', l.burstAt - _arrival + .88, by0 + .24),
      ('sprinkle', l.cloudEndsAt - _arrival + .15, by0 + .24),
    ];

    testWidgets('lob chains over New York, 640 and 800, calm', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final w in _widths) {
          final l = lob(.6, y: .55);
          await sheet(
            'chain-${w.round()}',
            w,
            calmFrames(l, .55),
            (t) => stageBoss(w, t, lobs: [l]),
          );
        }
      });
    });

    testWidgets('fury bracket over New York, 640 and 800', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final w in _widths) {
          final l = lob(.6, y: .5, fury: true);
          final frames = <(String, double, double)>[
            ('lock +.05', l.lockedAt - _arrival + .05, .5),
            ('wind-up hold', l.lockedAt - _arrival + .6, .5),
            ('toss', l.launchAt - _arrival + .02, .5),
            ('flight +.7', l.launchAt - _arrival + .7, .5),
            ('urgent', l.burstAt - _arrival - .15, .5),
            ('burst +.05', l.burstAt - _arrival + .05, .5),
            ('cloud +.5', l.burstAt - _arrival + .5, .5),
            ('cloud +.88', l.burstAt - _arrival + .88, .5),
          ];
          await sheet(
            'fury-${w.round()}',
            w,
            frames,
            (t) => stageBoss(w, t, lobs: [l], fury: true),
          );
        }
      });
    });

    testWidgets('the lowest and highest heights: lit windows and moon haze', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await loadFonts();
        const w = 640.0;
        for (final (name, y) in [('low', .84), ('high', .17)]) {
          final l = lob(.6, y: y);
          final frames = <(String, double, double)>[
            ('$name: lock hold', l.lockedAt - _arrival + .7, y),
            ('$name: flight', l.launchAt - _arrival + .6, y - .2),
            ('$name: urgent', l.burstAt - _arrival - .15, y - .3),
            ('$name: cloud', l.burstAt - _arrival + .5, y - .3),
          ];
          await sheet(
            'extremes-$name',
            w,
            frames,
            (t) => stageBoss(w, t, lobs: [l]),
          );
        }
      });
    });

    testWidgets('the toss strip: hand to flight, 3x', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const w = 640.0;
        final l = lob(.6, y: .55);
        final times = [-.12, -.05, -.01, 0.0, .03, .07, .12, .22];
        const zoom = 3.0, cw = 190.0, ch = 150.0;
        final boss0 = stageBoss(w, l.launchAt - _arrival, lobs: [l]);
        final hand = KingCooCrumbArt.release(
          boss0,
          BossMotion(boss0, reducedMotion: false),
          l,
        );
        await savePng(
          'toss-strip',
          (cw * zoom * 4).round(),
          (ch * zoom * 2).round(),
          (c) {
            for (var i = 0; i < times.length; i++) {
              c.save();
              c.translate((i % 4) * cw * zoom, (i ~/ 4) * ch * zoom);
              c.clipRect(const Rect.fromLTWH(0, 0, cw * zoom, ch * zoom));
              c.scale(zoom);
              c.translate(-(hand.dx * _h - 120), -(hand.dy * _h - 85));
              stage(
                c,
                w,
                stageBoss(w, l.launchAt - _arrival + times[i], lobs: [l]),
                birdY: .55,
              );
              c.restore();
              label(
                c,
                'toss ${times[i] >= 0 ? '+' : ''}${times[i]}',
                Offset((i % 4) * cw * zoom + 6, (i ~/ 4) * ch * zoom + 4),
                color: const Color(0xffffffff),
                size: 14,
              );
            }
          },
          dir: 'build/king-coo-crumbs',
        );
      });
    });

    testWidgets('close-ups', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const w = 640.0;
        final l = lob(.6, y: .55);
        final cases = <(String, double, double)>[
          ('a-lock', l.lockedAt - _arrival + .3, .55),
          ('b-mid', l.lockedAt - _arrival + 1.3, .62),
          ('c-urgent', l.burstAt - _arrival - .15, .8),
          ('d-burst', l.burstAt - _arrival + .06, .8),
          ('e-cloud', l.burstAt - _arrival + .5, .8),
          ('f-fade', l.burstAt - _arrival + .9, .8),
          ('g-sprinkle', l.cloudEndsAt - _arrival + .12, .8),
        ];
        const cols = 4, zoom = 3.0;
        const cw = 150.0, ch = 150.0;
        final rows = (cases.length / cols).ceil();
        await savePng(
          'closeups',
          (cw * zoom * cols).round(),
          (ch * zoom * rows).round(),
          (c) {
            for (var i = 0; i < cases.length; i++) {
              final (name, t, by) = cases[i];
              c.save();
              c.translate((i % cols) * cw * zoom, (i ~/ cols) * ch * zoom);
              c.clipRect(const Rect.fromLTWH(0, 0, cw * zoom, ch * zoom));
              c.scale(zoom);
              c.translate(-(birdX * _h - 75), -(.55 * _h - 75));
              stage(c, w, stageBoss(w, t, lobs: [l]), birdY: by);
              c.restore();
              label(
                c,
                name,
                Offset((i % cols) * cw * zoom + 6, (i ~/ cols) * ch * zoom + 4),
                color: const Color(0xffffffff),
                size: 14,
              );
            }
          },
          dir: 'build/king-coo-crumbs',
        );
      });
    });

    testWidgets('Reduced Motion and a bright backdrop', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const w = 640.0;
        final l = lob(.6, y: .55);
        final frames = <(String, double, double)>[
          ('RM lock', l.lockedAt - _arrival + .6, .55),
          ('RM toss', l.launchAt - _arrival + .02, .55),
          ('RM flight', l.launchAt - _arrival + .7, .7),
          ('RM urgent', l.burstAt - _arrival - .15, .78),
          ('RM cloud', l.burstAt - _arrival + .5, .78),
          ('RM fade', l.burstAt - _arrival + .9, .78),
        ];
        await sheet(
          'rm-640',
          w,
          frames,
          (t) => stageBoss(w, t, lobs: [l]),
          reduced: true,
        );
        await sheet(
          'bright-640',
          w,
          calmFrames(l, .55).sublist(1, 9),
          (t) => stageBoss(w, t, lobs: [l]),
          region: WorldRegion.egypt,
          seconds: 40,
        );
      });
    });

    testWidgets('the bomb: spin strip', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const n = 8;
        await savePng('bomb-strip', 160 * n, 320, (c) {
          c.drawRect(
            const Rect.fromLTWH(0, 0, 160.0 * n, 160),
            Paint()..color = const Color(0xff3a3560),
          );
          c.drawRect(
            const Rect.fromLTWH(0, 160, 160.0 * n, 160),
            Paint()..color = const Color(0xffe9e0cf),
          );
          for (var i = 0; i < n; i++) {
            for (var row = 0; row < 2; row++) {
              c.save();
              c.translate(i * 160 + 80, row * 160 + 80.0);
              c.scale(100);
              KingCooCrumbArt.bomb(
                c,
                Offset.zero,
                KingCooCrumbArt.flightSize(i / (n - 1)) * 1.6,
                spin: i * 2 * math.pi / n,
              );
              c.restore();
            }
          }
        }, dir: 'build/king-coo-crumbs');
      });
    });
  });
}

Matcher offsetCloseTo(Offset o, double tolerance) =>
    _OffsetCloseTo(o, tolerance);

class _OffsetCloseTo extends Matcher {
  const _OffsetCloseTo(this.o, this.tolerance);
  final Offset o;
  final double tolerance;
  @override
  bool matches(dynamic item, Map matchState) =>
      item is Offset && (item - o).distance <= tolerance;
  @override
  Description describe(Description d) => d.add('within $tolerance of $o');
}
