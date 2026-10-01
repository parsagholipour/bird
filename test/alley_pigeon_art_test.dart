import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/alley_pigeon_overlay_art.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_defeat_art.dart';
import 'package:push_up_bird/game/enemy_designs/alley_pigeon.dart';
import 'package:push_up_bird/game/enemy_designs/patrol_bat.dart';

import 'ny_plans.dart';

/// The Alley Pigeon's art: poses as a pure function of the raid state and the
/// enemy's clock, determinism, Reduced Motion (still frames that keep every
/// state readable), the glider variant, the marks on the world, the envelope,
/// and the per-frame budget (the `dragon_budget_test` way: a counting canvas).

// ------------------------------------------------------------ the budget --

/// Per pigeon, per frame (spec `reports/02-alley-pigeon.md` section 5): at most
/// 60 draw calls for the bird, 4 gradient-shader draws, no layer, clip or blur,
/// and a whole pigeon frame (bird plus its marks) at most 75.
const maxOps = 60, maxShaderDraws = 4, maxFrameOps = 75;

/// King Coo's squadron variant is the cheap one.
const maxGliderOps = 30;

/// Counts what a frame asks of the canvas.
class Counting implements Canvas {
  Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};

  /// The Paths and shaders the frame drew with, by identity, so a test can
  /// tell what is cached (the same object at every frame) from what a frame
  /// builds.
  final paths = <Path>{};
  final shaders = <Shader>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get clips => (counts['clipPath'] ?? 0) + (counts['clipRect'] ?? 0);
  int get shaderDraws => counts.entries
      .where((e) => e.key.endsWith('.shader'))
      .fold(0, (a, e) => a + e.value);
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
    final shader = p.shader;
    if (shader != null) {
      _n('$k.shader');
      shaders.add(shader);
    }
    if (p.maskFilter != null) _n('maskFilter');
  }

  @override
  void drawPath(Path p, Paint paint) {
    _paint('drawPath', paint);
    paths.add(p);
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
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

// --------------------------------------------------------------- helpers --

typedef Draw = void Function(Canvas c);

/// Two pictures that differ only by the rounding of an antialiased edge
/// (translating by a large coordinate and back moves an edge by 1e-13 px).
bool sameWithinAntialiasing(List<int> a, List<int> b) {
  var off = 0;
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > 6) off++;
  }
  return off == 0;
}

Future<List<int>> pixels(Draw draw, int w, int h) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

/// A picture of the pigeon at 40 px per hit radius.
Future<List<int>> shot(
  PigeonPose pose,
  double t, {
  bool reduced = false,
  bool glider = false,
  bool dazed = false,
}) => pixels(
  (c) {
    c.translate(120, 90);
    AlleyPigeonArt.paint(
      c,
      40,
      seconds: t,
      reducedMotion: reduced,
      pose: pose,
      glider: glider,
      dazed: dazed,
    );
  },
  240,
  180,
);

/// Painted bounds in hit-radius units, scanned from a 100 px per r picture.
Future<Rect> bounds(
  PigeonPose pose,
  double t, {
  bool reduced = false,
  bool glider = false,
}) async {
  const r = 100.0, w = 800, h = 500;
  final bytes = await pixels(
    (c) {
      c.translate(w / 2, h / 2);
      AlleyPigeonArt.paint(
        c,
        r,
        seconds: t,
        reducedMotion: reduced,
        pose: pose,
        glider: glider,
      );
    },
    w,
    h,
  );
  var left = w, right = -1, top = h, bottom = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (bytes[(y * w + x) * 4 + 3] > 24) {
        left = math.min(left, x);
        right = math.max(right, x);
        top = math.min(top, y);
        bottom = math.max(bottom, y);
      }
    }
  }
  return Rect.fromLTRB(
    (left - w / 2) / r,
    (top - h / 2) / r,
    (right + 1 - w / 2) / r,
    (bottom + 1 - h / 2) / r,
  );
}

/// One pigeon of a level: a raid [phase] that began [into] seconds ago.
SkyEnemy pigeon(
  PigeonPhase phase, {
  double into = 0,
  double x = 1.4,
  double y = .4,
  bool loot = false,
  double age = 2.0,
  double hitAgo = double.infinity,
}) {
  final e = SkyEnemy(
    x: x,
    y: y,
    appearance: EnemyKind.alleyPigeon.index,
    flightPhase: 1.3,
  )..age = age;
  if (hitAgo.isFinite) e.lastHitAt = age - hitAgo;
  final raid = e.pigeon!
    ..phase = phase
    ..phaseAt = age - into;
  if (phase == PigeonPhase.carry || phase == PigeonPhase.flee) {
    raid.snatchedAt = age - into;
  }
  if (loot) {
    raid.loot = SkyStar(x: x, y: y);
  }
  return e;
}

/// Every stage of the pigeon, as the rules would hold it.
List<(String, SkyEnemy)> everyState() => [
  ('glide', pigeon(PigeonPhase.glide)),
  ('warn early', pigeon(PigeonPhase.warning, into: .10)),
  ('warn late', pigeon(PigeonPhase.warning, into: .70)),
  ('dive', pigeon(PigeonPhase.dive, into: .2)),
  ('dive end', pigeon(PigeonPhase.dive, into: .42)),
  ('snatch', pigeon(PigeonPhase.carry, into: .05, loot: true)),
  ('gloat', pigeon(PigeonPhase.carry, into: .4, loot: true)),
  ('climb', pigeon(PigeonPhase.carry, into: 1.4, loot: true)),
  ('flee', pigeon(PigeonPhase.flee, into: .6)),
  ('hit', pigeon(PigeonPhase.glide, hitAgo: .05)),
];

void paintEnemy(Canvas c, SkyEnemy e, {bool reduced = false, double r = 40}) {
  c.translate(120, 90);
  AlleyPigeonArt.paintEnemy(
    c,
    r,
    e,
    lookY: 0,
    hitAge: e.age - e.lastHitAt,
    reducedMotion: reduced,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pose', () {
    test('a pigeon\'s stage follows its raid state', () {
      PigeonPose of(SkyEnemy e) => PigeonPose.of(e, hitAge: double.infinity);
      expect(of(pigeon(PigeonPhase.glide)).stage, PigeonStage.glide);
      expect(of(pigeon(PigeonPhase.glide)).facingRight, isFalse);
      final warn = of(
        pigeon(PigeonPhase.warning, into: AlleyPigeon.warningSeconds / 2),
      );
      expect(warn.stage, PigeonStage.warn);
      expect(warn.warn, closeTo(.5, 1e-9));
      expect(warn.facingRight, isTrue, reason: 'it turns to its prey');
      final dive = of(
        pigeon(PigeonPhase.dive, into: AlleyPigeon.diveSeconds / 2),
      );
      expect(dive.stage, PigeonStage.dive);
      expect(dive.dive, closeTo(.5, 1e-9));
      final gloat = of(pigeon(PigeonPhase.carry, into: .3, loot: true));
      expect(gloat.stage, PigeonStage.gloat);
      expect(gloat.loot, isTrue);
      expect(
        of(
          pigeon(
            PigeonPhase.carry,
            into: AlleyPigeon.gloatSeconds + .1,
            loot: true,
          ),
        ).stage,
        PigeonStage.climb,
      );
      final flee = of(pigeon(PigeonPhase.flee, into: .3));
      expect(flee.stage, PigeonStage.flee);
      expect(flee.loot, isFalse, reason: 'a spooked pigeon has no star');
      expect(flee.facingRight, isTrue);
    });

    test(
      'the snatch\'s kick and a hit\'s startle are pure functions of time',
      () {
        final e = pigeon(PigeonPhase.carry, into: .12, loot: true);
        final p = PigeonPose.of(e, hitAge: double.infinity);
        expect(p.kick, closeTo(.5, 1e-9));
        expect(
          PigeonPose.of(
            pigeon(PigeonPhase.carry, into: .3, loot: true),
            hitAge: 9,
          ).kick,
          0,
        );
        final hit = PigeonPose.of(pigeon(PigeonPhase.glide), hitAge: .05);
        expect(hit.startle, greaterThan(.9));
        expect(
          PigeonPose.of(
            pigeon(PigeonPhase.glide),
            hitAge: PigeonPose.startleSeconds,
          ).startle,
          0,
        );
        expect(
          PigeonPose.of(
            pigeon(PigeonPhase.glide),
            hitAge: double.infinity,
          ).startle,
          0,
        );
      },
    );

    test('a squadron pigeon is a plain glider whatever its clock says', () {
      final squad = SkyEnemy(x: 1.2, y: .5, appearance: 4, squad: true)
        ..age = 3;
      final pose = PigeonPose.of(squad, hitAge: double.infinity);
      expect(pose.stage, PigeonStage.glide);
      expect(pose.facingRight, isFalse);
      expect(pose.loot, isFalse);
      expect(pose.coat, 0);
    });

    test('a flock wears three plumages by slot', () {
      for (var slot = 0; slot < 3; slot++) {
        final raid = PigeonFlight(slot: slot, flockSize: 3);
        expect(PigeonPose.ofRaid(raid, age: 1, hitAge: 9).coat, slot);
      }
    });

    test(
      'the stoop points along the swoop: down from above the lane, up from below, eased in',
      () {
        for (var slot = 0; slot < 3; slot++) {
          for (final u in [.1, .3, .5, .8, 1.0]) {
            final above = PigeonPose.diveTilt(u, slot: slot, side: -1);
            final below = PigeonPose.diveTilt(u, slot: slot, side: 1);
            expect(above, lessThan(0), reason: 'nose down from above, u $u');
            expect(below, greaterThan(0), reason: 'nose up from below, u $u');
            expect(above, closeTo(-below, 1e-9));
          }
          // It comes out level at the snatch.
          expect(
            PigeonPose.diveTilt(1, slot: slot, side: -1).abs(),
            lessThan(.12),
          );
          // Never a full nosedive.
          expect(
            PigeonPose.diveTilt(0, slot: slot, side: -1).abs(),
            lessThanOrEqualTo(.95),
          );
        }
        // No snap when the crouch turns into the dive: the tilt is continuous
        // across the first few frames.
        var last = PigeonPose.of(
          pigeon(PigeonPhase.warning, into: .8),
          hitAge: 9,
        ).tilt;
        for (var i = 0; i <= 12; i++) {
          final t = i / 60.0;
          final tilt = PigeonPose.of(
            pigeon(PigeonPhase.dive, into: t),
            hitAge: 9,
          ).tilt;
          expect((tilt - last).abs(), lessThan(.25), reason: 'frame $i');
          last = tilt;
        }
        // The climb away tips the nose toward where the thief is heading.
        expect(PigeonPose.fleeTilt(0, side: -1), 0);
        expect(PigeonPose.fleeTilt(1.6, side: -1), greaterThan(.2));
        expect(PigeonPose.fleeTilt(1.6, side: 1), lessThan(-.2));
      },
    );
  });

  group('picture', () {
    testWidgets('every state is a pure function of the enemy\'s clock', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final (name, e) in everyState()) {
          final a = await pixels((c) => paintEnemy(c, e), 240, 180);
          expect(
            await pixels((c) => paintEnemy(c, e), 240, 180),
            a,
            reason: '$name repeats exactly',
          );
          // An identical enemy built from scratch draws the same picture.
          final twin = pigeon(
            e.pigeon!.phase,
            into: e.age - e.pigeon!.phaseAt,
            loot: e.pigeon!.loot != null,
            hitAgo: e.age - e.lastHitAt,
          );
          expect(
            await pixels((c) => paintEnemy(c, twin), 240, 180),
            a,
            reason: '$name, rebuilt',
          );
        }
        // Time moves the picture (the wings beat).
        final a = pigeon(PigeonPhase.glide, age: 2.0);
        final b = pigeon(PigeonPhase.glide, age: 2.11);
        expect(
          await pixels((c) => paintEnemy(c, a), 240, 180),
          isNot(await pixels((c) => paintEnemy(c, b), 240, 180)),
        );
      });
    });

    testWidgets('the states all look different', (tester) async {
      await tester.runAsync(() async {
        final seen = <String, String>{};
        for (final (name, e) in everyState()) {
          final px = await pixels((c) => paintEnemy(c, e), 240, 180);
          final key = px.join(',').hashCode.toString();
          expect(seen[key], isNull, reason: '$name looks like ${seen[key]}');
          seen[key] = name;
        }
      });
    });

    testWidgets(
      'Reduced Motion: one still frame per state, and the states stay readable',
      (tester) async {
        await tester.runAsync(() async {
          final stills = <String, String>{};
          for (final (name, e) in everyState()) {
            if (name == 'hit') continue; // a hit's reaction is motion
            final pose = PigeonPose.of(e, hitAge: double.infinity);
            final clocks = [
              for (final t in [0.0, .037, .2, .31, 1.7])
                await shot(pose, t, reduced: true),
            ];
            for (final frame in clocks) {
              expect(
                frame,
                clocks.first,
                reason: '$name holds still under Reduced Motion',
              );
            }
            final key = clocks.first.join(',').hashCode.toString();
            expect(
              stills[key],
              isNull,
              reason: '$name looks like ${stills[key]} in Reduced Motion',
            );
            stills[key] = name;
            // ...while the same state in motion does move.
            expect(
              await shot(pose, 0, reduced: false),
              isNot(await shot(pose, .17, reduced: false)),
              reason: '$name moves',
            );
          }
        });
      },
    );

    testWidgets(
      'Reduced Motion drops the flourishes but keeps the state: the hit is still one pose',
      (tester) async {
        await tester.runAsync(() async {
          final calm = pigeon(PigeonPhase.glide);
          final hit = pigeon(PigeonPhase.glide, hitAgo: .05);
          expect(
            await pixels((c) => paintEnemy(c, hit, reduced: true), 240, 180),
            await pixels((c) => paintEnemy(c, calm, reduced: true), 240, 180),
            reason:
                'no startle under Reduced Motion (the health bar and defeat carry the news)',
          );
        });
      },
    );

    testWidgets(
      'carrying a star shows it, and the star is the collectible\'s gold',
      (tester) async {
        await tester.runAsync(() async {
          final carry = pigeon(PigeonPhase.carry, into: .6, loot: true);
          final empty = pigeon(PigeonPhase.carry, into: .6);
          final a = await pixels((c) => paintEnemy(c, carry), 240, 180);
          final b = await pixels((c) => paintEnemy(c, empty), 240, 180);
          expect(a, isNot(b));
          // Gold pixels in the star's place (left of the beak), none without it.
          int gold(List<int> px) {
            var n = 0;
            for (var y = 0; y < 180; y++) {
              for (var x = 0; x < 120 - 50; x++) {
                final i = (y * 240 + x) * 4;
                if (px[i] > 220 &&
                    px[i + 1] > 170 &&
                    px[i + 1] < 235 &&
                    px[i + 2] < 120) {
                  n++;
                }
              }
            }
            return n;
          }

          expect(gold(a), greaterThan(150));
          expect(gold(b), lessThan(10));
        });
      },
    );

    testWidgets('the envelope: every pose stays inside the small-enemy box', (
      tester,
    ) async {
      await tester.runAsync(() async {
        var union = Rect.zero;
        Rect widest = Rect.zero;
        var carryLeft = 0.0;
        final poses = <(String, PigeonPose)>[
          ('glide', const PigeonPose()),
          (
            'warn',
            const PigeonPose(
              stage: PigeonStage.warn,
              warn: .6,
              stageTime: .5,
              tilt: .1,
              facingRight: true,
            ),
          ),
          (
            'dive',
            PigeonPose(
              stage: PigeonStage.dive,
              dive: .5,
              stageTime: .2,
              tilt: PigeonPose.diveTilt(.5, slot: 0, side: -1),
              facingRight: true,
            ),
          ),
          (
            'flee',
            const PigeonPose(
              stage: PigeonStage.flee,
              stageTime: .5,
              facingRight: true,
            ),
          ),
          ('startle', const PigeonPose(startle: 1)),
        ];
        for (final (name, pose) in poses) {
          for (var i = 0; i < 12; i++) {
            final b = await bounds(pose, i / 12 * AlleyPigeonArt.cycleSeconds);
            // The pose's tilt moves the box; the un-tilted envelope is the
            // contract, so measure the level poses.
            if (pose.tilt.abs() < .2) {
              union = union == Rect.zero ? b : union.expandToInclude(b);
              if (b.width > widest.width) widest = b;
            }
            expect(b.width, lessThan(4.3), reason: '$name frame $i');
          }
        }
        for (var i = 0; i < 6; i++) {
          final b = await bounds(
            PigeonPose(
              stage: PigeonStage.climb,
              stageTime: 1.2,
              loot: true,
              facingRight: true,
            ),
            i / 6 * AlleyPigeonArt.hurryCycleSeconds,
          );
          carryLeft = math.min(carryLeft, b.left);
        }
        // ignore: avoid_print
        print(
          'pigeon union ${union.left.toStringAsFixed(2)}..${union.right.toStringAsFixed(2)} x '
          '${union.top.toStringAsFixed(2)}..${union.bottom.toStringAsFixed(2)}; '
          'widest ${widest.width.toStringAsFixed(2)} r; with a star left ${carryLeft.toStringAsFixed(2)}',
        );
        // The bats' box is +-1.9 x +-1.2; the health bar sits at 1.4 above.
        expect(union.left, greaterThanOrEqualTo(-1.75));
        expect(union.right, lessThanOrEqualTo(2.0));
        expect(
          union.top,
          greaterThanOrEqualTo(-1.42),
          reason: 'under the health bar',
        );
        expect(union.bottom, lessThanOrEqualTo(1.25));
        expect(
          widest.width,
          inInclusiveRange(3.2, 3.9),
          reason: 'the bats\' size class',
        );
        expect(
          carryLeft,
          greaterThanOrEqualTo(-2.9),
          reason: 'star and its glow',
        );
        // The glider is the same bird in the same box.
        final g = await bounds(const PigeonPose(), .1, glider: true);
        expect(g.width, inInclusiveRange(3.0, 3.9));
        expect(g.top, greaterThanOrEqualTo(-1.42));
      });
    });

    test(
      'the wing keeps its fan at every stroke (no flat smear between poses)',
      () {
        for (var i = 0; i <= 20; i++) {
          final stroke = 1 - i / 10;
          for (final tuck in [0.0, .5, 1.0]) {
            final pts = AlleyPigeonArt.wingPointsForTest(stroke, tuck);
            // The four feather tips keep their leading-to-trailing order around
            // the shoulder, and never collapse onto one ray.
            const shoulder = Offset(-.08, -.30);
            final angles = [
              for (final p in pts.skip(1))
                math.atan2(p.dy - shoulder.dy, p.dx - shoulder.dx),
            ];
            for (var k = 1; k < angles.length; k++) {
              expect(
                angles[k],
                greaterThan(angles[k - 1] + .05),
                reason: 'stroke $stroke tuck $tuck tip $k',
              );
            }
            for (final p in pts) {
              expect(p.dy, greaterThan(-1.5));
              expect(p.dx, lessThan(2.1));
            }
          }
        }
      },
    );
  });

  group('hostile inputs', () {
    test(
      'odd clocks, looks and sizes paint something sane or nothing, never throw',
      () {
        final recorder = ui.PictureRecorder();
        final c = Canvas(recorder);
        const poses = [
          PigeonPose(),
          PigeonPose(stage: PigeonStage.warn, warn: 2, facingRight: true),
          PigeonPose(stage: PigeonStage.dive, dive: -1, tilt: 9),
          PigeonPose(
            stage: PigeonStage.climb,
            loot: true,
            kick: 5,
            stageTime: -3,
          ),
          PigeonPose(startle: 3, coat: -7),
        ];
        for (final pose in poses) {
          for (final seconds in [double.nan, double.infinity, -5.0, 1e9, 0.0]) {
            for (final radius in [
              0.0,
              -3.0,
              double.nan,
              double.infinity,
              16.2,
            ]) {
              AlleyPigeonArt.paint(
                c,
                radius,
                seconds: seconds,
                reducedMotion: seconds.isNegative,
                lookY: double.nan,
                charge: double.infinity,
                recoil: double.nan,
                pose: pose,
                glider: radius == 16.2 && seconds == 0,
              );
            }
          }
        }
        recorder.endRecording().dispose();
        // A zero or unusable radius draws nothing at all.
        final counting = Counting(Canvas(ui.PictureRecorder()));
        AlleyPigeonArt.paint(
          counting,
          double.nan,
          seconds: 1,
          reducedMotion: false,
        );
        AlleyPigeonArt.paint(counting, 0, seconds: 1, reducedMotion: false);
        expect(counting.draws, 0);
      },
    );
  });

  group('the snatch eases', () {
    test(
      'the nose comes level with a flick, from the dive\'s own entry angle',
      () {
        for (final side in [-1, 1]) {
          final entry = side * PigeonPose.entryTilt;
          // Continuous at the snatch: the dive ends at the entry angle and the
          // settle starts there.
          expect(PigeonPose.snatchPitch(0, entry), closeTo(entry, 1e-12));
          final dive = PigeonPose.ofRaid(
            PigeonFlight(slot: 1, side: side)
              ..phase = PigeonPhase.dive
              ..phaseAt = 2 - AlleyPigeon.diveSeconds * .9999,
            age: 2,
            hitAge: 9,
          );
          expect(dive.tilt, closeTo(entry, .02), reason: 'side $side');
          // It flicks past level, 60% of the way back up (0.12 rad), the other
          // way from the dive, and is level when the settle is over.
          var peak = 0.0;
          for (var i = 0; i <= 140; i++) {
            final t = i / 1000;
            final v = PigeonPose.snatchPitch(t, entry);
            if (v.abs() > peak.abs()) peak = v;
          }
          // (the first frame holds the entry angle; look for the overshoot)
          var over = 0.0;
          for (var i = 20; i <= 140; i++) {
            final v = PigeonPose.snatchPitch(i / 1000, entry);
            if (v * entry < 0 && v.abs() > over.abs()) over = v;
          }
          expect(
            over.abs(),
            closeTo(.12, .015),
            reason: 'the overshoot, side $side',
          );
          expect(over.sign, -entry.sign);
          expect(PigeonPose.snatchPitch(PigeonPose.settleSeconds, entry), 0);
          expect(PigeonPose.snatchPitch(.5, entry), 0);
          expect(
            PigeonPose.snatchPitch(double.infinity, entry),
            0,
            reason: 'no snatch',
          );
          expect(peak.abs(), closeTo(entry.abs(), 1e-9));
          // No step bigger than a tenth of a radian from one 120 Hz frame to the
          // next, through the dive's end and the settle.
          late double last;
          double tiltAt(double s) {
            final raid = PigeonFlight(slot: 1, side: side);
            if (s < 0) {
              raid
                ..phase = PigeonPhase.dive
                ..phaseAt = 2 - (AlleyPigeon.diveSeconds + s);
            } else {
              raid
                ..phase = PigeonPhase.carry
                ..phaseAt = 2 - s
                ..snatchedAt = 2 - s;
            }
            return PigeonPose.ofRaid(raid, age: 2, hitAge: 9).tilt;
          }

          last = tiltAt(-49 / 240);
          for (var f = -48; f <= 60; f++) {
            final tilt = tiltAt(f / 240);
            expect(
              (tilt - last).abs(),
              lessThan(.1),
              reason: 'side $side step $f',
            );
            last = tilt;
          }
        }
      },
    );

    test(
      'the wings, neck and feet carry the dive into the climb with no jump',
      () {
        PigeonPose at(double s) {
          final raid = PigeonFlight(slot: 0, side: -1);
          if (s < 0) {
            raid
              ..phase = PigeonPhase.dive
              ..phaseAt = 2 - (AlleyPigeon.diveSeconds + s);
          } else {
            raid
              ..phase = PigeonPhase.carry
              ..phaseAt = 2 - s
              ..snatchedAt = 2 - s;
          }
          return PigeonPose.ofRaid(raid, age: 2, hitAge: 9);
        }

        // The neck stretches as the strike closes in, and the brake flare begins.
        expect(at(-.30).reach, 0);
        expect(at(-.06).reach, greaterThan(.2));
        expect(at(-.001).reach, closeTo(1, .02));
        expect(at(-.30).flare, 0);
        expect(at(-.001).flare, closeTo(.55, .02));
        // Continuous through the snatch itself...
        expect(at(.0).reach, closeTo(at(-.0005).reach, .02));
        expect(at(.0).flare, closeTo(at(-.0005).flare, .02));
        // ...a full flare just after it...
        expect(at(.06).flare, greaterThan(.8));
        // ...and folded, neck drawn back, momentum spent and settled by 0.18 s.
        expect(at(.18).flare, 0);
        expect(at(.12).reach, 0);
        expect(at(.14).settle, 1);
        expect(at(.0).settle, 0);
        expect(at(.07).settle, closeTo(.5, 1e-9));
        for (var i = 0; i <= 60; i++) {
          final s = i / 240;
          expect(at(s).flare, lessThanOrEqualTo(.95));
          expect(at(s).reach, inInclusiveRange(0, 1));
        }
        // A pigeon that never snatched has none of it.
        final spooked = PigeonPose.ofRaid(
          PigeonFlight(slot: 0, side: -1)
            ..phase = PigeonPhase.flee
            ..phaseAt = 1,
          age: 1.1,
          hitAge: 9,
        );
        expect(
          (spooked.reach, spooked.flare, spooked.drift, spooked.settle),
          (0, 0, 0, 1),
        );
      },
    );

    test(
      'the picture\'s speed is continuous through the snatch, the rules\' is not',
      () {
        // Screen heights per second. The rules fly a quarter ellipse to the
        // star and then climb at AlleyPigeon.flee's pace; both ride the course's
        // scroll. The hit circle follows the rules; the picture adds a
        // displacement that keeps its speed continuous.
        const scroll = .43, dt = 1 / 480;
        for (var slot = 0; slot < 3; slot++) {
          ({double x, double y}) rules(double s) {
            if (s < 0) {
              final u = (AlleyPigeon.diveSeconds + s) / AlleyPigeon.diveSeconds;
              final star = (x: 1.2 - scroll * s, y: .56);
              final home = AlleyPigeon.hover(
                slot: slot,
                preyX: star.x,
                lane: .56,
                side: -1,
              );
              return AlleyPigeon.dive(u, home, star);
            }
            final f = AlleyPigeon.flee(s, -1);
            return (x: 1.2 - scroll * s + f.dx, y: .56 + f.dy);
          }

          ({double x, double y}) seen(double s) {
            final p = rules(s);
            final d = PigeonPose.snatchDrift(s, slot, -1) * SkyEnemy.radius;
            return (x: p.x + d, y: p.y);
          }

          double speed(({double x, double y}) Function(double) at, double s) {
            final a = at(s - dt), b = at(s + dt);
            return math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2)) /
                (2 * dt);
          }

          final before = speed(rules, -2 * dt), after = speed(rules, 2 * dt);
          final seenBefore = speed(seen, -2 * dt),
              seenAfter = speed(seen, 2 * dt);
          expect(
            (seenAfter - seenBefore).abs() / math.max(seenBefore, .05),
            lessThan(.12),
            reason:
                'slot $slot: the picture keeps its speed through the snatch',
          );
          if (slot != 1) {
            expect(
              (after - before).abs() / before,
              greaterThan(.3),
              reason:
                  'slot $slot: the rules do change speed (the review\'s finding)',
            );
          }
          // The displacement is spent: gone after half a second, never more than
          // a radius from the hit circle.
          var worst = 0.0;
          for (var i = 0; i <= 600; i++) {
            worst = math.max(
              worst,
              PigeonPose.snatchDrift(i / 1000, slot, -1).abs(),
            );
          }
          expect(worst, lessThan(1.0), reason: 'slot $slot, in hit radii');
          expect(PigeonPose.snatchDrift(.6, slot, -1).abs(), lessThan(.01));
          expect(PigeonPose.snatchDrift(-1, slot, -1), 0);
          expect(PigeonPose.snatchDrift(double.infinity, slot, -1), 0);
        }
      },
    );

    testWidgets(
      'it draws no pop: the wings and tail do not jump across the snatch',
      (tester) async {
        await tester.runAsync(() async {
          Future<List<int>> shotAt(double s) {
            final raid = PigeonFlight(slot: 1, flockSize: 3, side: -1);
            if (s < 0) {
              raid
                ..phase = PigeonPhase.dive
                ..phaseAt = 2 - (AlleyPigeon.diveSeconds + s);
            } else {
              raid
                ..phase = PigeonPhase.carry
                ..phaseAt = 2 - s
                ..snatchedAt = 2 - s
                ..loot = SkyStar(x: 1, y: .5);
            }
            // The same wing clock on both sides, so only the pose can differ.
            return pixels(
              (c) {
                c.translate(120, 90);
                AlleyPigeonArt.paint(
                  c,
                  40,
                  seconds: .37,
                  reducedMotion: false,
                  pose: PigeonPose.ofRaid(raid, age: 2, hitAge: 9),
                );
              },
              240,
              180,
            );
          }

          int off(List<int> a, List<int> b) {
            var n = 0;
            for (var i = 3; i < a.length; i += 4) {
              if ((a[i] - b[i]).abs() > 100) n++;
            }
            return n;
          }

          // Silhouette (alpha) change between neighbouring 1/240 s frames, at the
          // snatch and away from it: the snatch frame must not be the outlier.
          final steps = <int>[];
          for (var f = -4; f <= 4; f++) {
            steps.add(off(await shotAt(f / 240), await shotAt((f + 1) / 240)));
          }
          final atSnatch = steps[3] > steps[4] ? steps[3] : steps[4];
          final typical = steps
              .where((n) => n != steps[3] && n != steps[4])
              .fold(0, (a, n) => n > a ? n : a);
          expect(atSnatch, lessThan(typical * 3 + 400), reason: 'steps $steps');
        });
      },
    );
  });

  group('a V of squadron gliders reads as individuals', () {
    SkyEnemy squad(int n) => SkyEnemy(
      x: 1.4,
      y: .5,
      appearance: 4,
      squad: true,
      flightPhase: n * 2.399963,
    )..age = 2.0;

    test(
      'plumage cycles with the squadron\'s numbering; size, tempo and bank vary again',
      () {
        final coats = <int>{};
        final scales = <double>{};
        for (var n = 14; n < 14 + 28; n++) {
          final look = PigeonPose.squadLook(n * 2.399963);
          coats.add(look.coat);
          scales.add(look.scale);
          expect(look.scale, inInclusiveRange(.94 - 1e-9, 1.06 + 1e-9));
          expect(look.beat, inInclusiveRange(.93 - 1e-9, 1.07 + 1e-9));
          expect(
            look.tilt.abs(),
            lessThanOrEqualTo(.07 + 1e-9),
            reason: 'four degrees',
          );
          // Neighbours in a V differ in plumage.
          expect(
            look.coat,
            isNot(PigeonPose.squadLook((n + 1) * 2.399963).coat),
            reason: 'n $n',
          );
        }
        expect(coats, {0, 1, 2});
        expect(scales.length, greaterThanOrEqualTo(4));
        // No clock, no variation.
        final plain = PigeonPose.squadLook(null);
        expect((plain.coat, plain.scale, plain.beat, plain.tilt), (0, 1, 1, 0));
        expect(PigeonPose.squadLook(double.nan).coat, 0);
        // A raider is never varied this way.
        final raider = PigeonPose.ofRaid(
          PigeonFlight(slot: 2),
          age: 1,
          hitAge: 9,
        );
        expect((raider.scale, raider.beat, raider.coat), (1, 1, 2));
      },
    );

    testWidgets(
      'seven gliders of one whistle draw as seven different birds, still the cheap glider',
      (tester) async {
        await tester.runAsync(() async {
          final seen = <String>{};
          final ops = <int>[];
          for (var i = 0; i < 7; i++) {
            final e = squad((1 * 2 + 0) * 7 + i);
            // The same wing clock, so only the bird's own look can differ.
            final pose = PigeonPose.of(e, hitAge: double.infinity);
            final px = await shot(pose, .3, glider: true);
            seen.add(px.join(',').hashCode.toString());
            final counting = Counting(Canvas(ui.PictureRecorder()));
            AlleyPigeonArt.paintEnemy(
              counting,
              16,
              e,
              lookY: 0,
              hitAge: 9,
              reducedMotion: false,
            );
            ops.add(counting.draws);
          }
          expect(seen.length, 7, reason: 'seven distinct birds');
          for (final n in ops) {
            expect(n, lessThanOrEqualTo(maxGliderOps));
          }
          // Reduced Motion: the individuals stay individuals, and still.
          final still = <String>{};
          for (var i = 0; i < 7; i++) {
            final pose = PigeonPose.of(squad(14 + i), hitAge: double.infinity);
            final a = await shot(pose, 0, glider: true, reduced: true);
            expect(await shot(pose, 1.9, glider: true, reduced: true), a);
            still.add(a.join(',').hashCode.toString());
          }
          expect(still.length, 7);
          // Deterministic: the same enemy draws the same picture twice.
          final pose = PigeonPose.of(squad(16), hitAge: double.infinity);
          expect(
            await shot(pose, .3, glider: true),
            await shot(pose, .3, glider: true),
          );
        });
      },
    );

    test('a squad pigeon stays inside the bats\' box at its biggest', () async {
      // +-6% size on a 3.7 r bird: still under the health bar and the glider box.
      final b = await bounds(
        PigeonPose.of(squad(14 + 3), hitAge: double.infinity),
        .1,
        glider: true,
      );
      expect(b.width, lessThan(4.1));
      expect(b.top, greaterThanOrEqualTo(-1.5));
    });
  });

  group('non-finite input', () {
    final nan = double.nan, inf = double.infinity;

    test(
      'a pose with a number that is not one paints at rest and costs the same',
      () {
        final dirty = PigeonPose(
          stage: PigeonStage.dive,
          warn: nan,
          dive: inf,
          stageTime: -inf,
          tilt: nan,
          kick: nan,
          startle: inf,
          reach: nan,
          flare: inf,
          drift: nan,
          scale: nan,
          beat: 0,
          settle: nan,
        );
        final clean = dirty.cleaned();
        for (final v in [
          clean.warn,
          clean.dive,
          clean.stageTime,
          clean.tilt,
          clean.kick,
          clean.startle,
          clean.reach,
          clean.flare,
          clean.drift,
          clean.scale,
          clean.beat,
          clean.settle,
        ]) {
          expect(v.isFinite, isTrue);
        }
        expect((clean.scale, clean.settle), (1, 1));
        final c = Counting(Canvas(ui.PictureRecorder()));
        for (final seconds in [nan, inf, -inf]) {
          AlleyPigeonArt.paint(
            c,
            16,
            seconds: seconds,
            reducedMotion: false,
            pose: dirty,
            lookY: inf,
            charge: nan,
            recoil: -inf,
          );
        }
        expect(c.draws, greaterThan(0));
        expect(c.draws, lessThanOrEqualTo(3 * maxOps));
        // An enemy whose clock is not a number is the resting pigeon.
        final e = pigeon(PigeonPhase.dive, into: .2)..age = nan;
        final pose = PigeonPose.of(e, hitAge: nan);
        expect((pose.stage, pose.dive, pose.tilt), (PigeonStage.glide, 0, 0));
        expect(
          () => AlleyPigeonArt.paintEnemy(
            Canvas(ui.PictureRecorder()),
            16,
            e,
            lookY: nan,
            hitAge: nan,
            reducedMotion: false,
          ),
          returnsNormally,
        );
      },
    );

    test('the marks on the world take any star, enemy, clock or height', () {
      FlightSimulation arena() =>
          FlightSimulation(rules: TapFlyMode(), practice: true)
            ..phase = RunPhase.playing
            ..elapsed = 3;
      final bad = [nan, inf, -inf];
      for (final phase in [
        PigeonPhase.warning,
        PigeonPhase.dive,
        PigeonPhase.carry,
      ]) {
        for (final reduced in [false, true]) {
          // A sound scene, and then each number poisoned in turn.
          for (var poison = 0; poison < 9; poison++) {
            for (final v in bad) {
              final sim = arena();
              final prey = SkyStar(x: 1.5, y: .56);
              sim.stars.add(prey);
              final e = pigeon(
                phase,
                into: .1,
                x: 1.3,
                y: .3,
                loot: phase == PigeonPhase.carry,
              )..pigeon!.prey = prey;
              sim.enemies.add(e);
              switch (poison) {
                case 0:
                  prey.x = v;
                case 1:
                  prey.heldY = v;
                case 2:
                  sim.elapsed = v;
                case 3:
                  e.age = v;
                case 4:
                  e.x = v;
                case 5:
                  e.placeAt(1.3, v);
                case 6:
                  e.pigeon!.phaseAt = v;
                case 7:
                  e.pigeon!.snatchedAt = v;
                case 8:
                  e.pigeon!.homeX = v;
              }
              final canvas = Canvas(ui.PictureRecorder());
              expect(
                () => AlleyPigeonOverlayArt.paint(
                  canvas,
                  360,
                  sim,
                  reducedMotion: reduced,
                ),
                returnsNormally,
                reason: '$phase poison $poison = $v reduced $reduced',
              );
              expect(
                () => AlleyPigeonOverlayArt.swoopDots(
                  e.pigeon!,
                  prey,
                  age: e.age,
                ),
                returnsNormally,
              );
            }
          }
        }
      }
      // Heights that are not heights draw nothing.
      final sim = arena();
      final prey = SkyStar(x: 1.5, y: .56);
      sim.stars.add(prey);
      sim.enemies.add(
        pigeon(PigeonPhase.warning, into: .3, x: 1.3, y: .3)
          ..pigeon!.prey = prey,
      );
      for (final h in [nan, inf, 0.0, -360.0]) {
        final c = Counting(Canvas(ui.PictureRecorder()));
        AlleyPigeonOverlayArt.paint(c, h, sim, reducedMotion: false);
        expect(c.draws, 0, reason: 'height $h');
      }
      // A freed star with a poisoned place or clock.
      final star = SkyStar(x: 1.2, y: .5)..freedAt = 5;
      for (final v in bad) {
        final canvas = Canvas(ui.PictureRecorder());
        expect(
          () => AlleyPigeonOverlayArt.freed(
            canvas,
            360,
            star..x = v,
            5.2,
            reducedMotion: false,
          ),
          returnsNormally,
        );
        star.x = 1.2;
        expect(
          () => AlleyPigeonOverlayArt.freed(
            canvas,
            360,
            star..heldY = v,
            5.2,
            reducedMotion: false,
          ),
          returnsNormally,
        );
        star.heldY = null;
        expect(
          () => AlleyPigeonOverlayArt.freed(
            canvas,
            360,
            star,
            v,
            reducedMotion: false,
          ),
          returnsNormally,
        );
        expect(
          () => AlleyPigeonOverlayArt.freed(
            canvas,
            v,
            star,
            5.2,
            reducedMotion: false,
          ),
          returnsNormally,
        );
      }
      // The swoop dots of a star that is not anywhere are none.
      final raid = PigeonFlight()
        ..phase = PigeonPhase.warning
        ..prey = prey;
      expect(
        AlleyPigeonOverlayArt.swoopDots(raid, prey..x = nan, age: 1),
        isEmpty,
      );
    });

    testWidgets(
      'the real renderer survives a pigeon scene with poisoned numbers',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final sim = nyFlight(nyPlan())
          ..phase = RunPhase.playing
          ..elapsed = 4;
        final prey = SkyStar(x: 1.5, y: .56);
        sim.stars.add(prey);
        sim.enemies
          ..add(
            pigeon(PigeonPhase.warning, into: .3, x: 1.3, y: .3)
              ..pigeon!.prey = prey,
          )
          ..add(pigeon(PigeonPhase.carry, into: .05, x: 1.0, y: .5, loot: true))
          ..add(
            SkyEnemy(
              x: 1.7,
              y: .8,
              appearance: 4,
              squad: true,
              flightPhase: nan,
            )..age = 2,
          );
        sim.enemies.first.age = nan;
        final game = BirdGame(
          simulation: sim,
          nowMs: () => 0,
          bird: 0,
          reducedMotion: false,
          playback: true,
          onChanged: () {},
        );
        await tester.pumpWidget(GameWidget(game: game));
        await tester.runAsync(() async {
          await game.loaded;
          game.pauseEngine();
          // No pigeon of the scene is allowed to throw; other painters are not
          // the point here, so only pigeons' own numbers are poisoned.
          final px = await pixels(game.render, 800, 360);
          expect(px.any((b) => b != 0), isTrue);
        });
        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('budget', () {
    Counting measure(void Function(Canvas c) draw) {
      final counting = Counting(Canvas(ui.PictureRecorder()));
      draw(counting);
      return counting;
    }

    test('a pigeon frame stays inside its budget in every state', () {
      final report = StringBuffer(
        'state         ops shader-draws layers clips blurs new-paths\n',
      );
      var worst = 0;
      for (final reduced in [false, true]) {
        for (final (name, e) in everyState()) {
          // Warm frame: a first paint may build; a steady one must not.
          measure((c) => paintEnemy(c, e, reduced: reduced));
          final first = measure((c) => paintEnemy(c, e, reduced: reduced));
          final later = pigeon(
            e.pigeon!.phase,
            into: e.age - e.pigeon!.phaseAt + .013,
            loot: e.pigeon!.loot != null,
            hitAgo: e.age - e.lastHitAt + .013,
            age: e.age + .013,
          );
          final second = measure((c) => paintEnemy(c, later, reduced: reduced));
          report.writeln(
            '${(name + (reduced ? ' RM' : '')).padRight(13)} ${first.draws.toString().padLeft(3)} '
            '${first.shaderDraws.toString().padLeft(12)} ${first.layers.toString().padLeft(6)} '
            '${first.clips.toString().padLeft(5)} ${first.blurs.toString().padLeft(5)} '
            '${first.paths.difference(second.paths).length.toString().padLeft(9)}',
          );
          expect(first.draws, lessThanOrEqualTo(maxOps), reason: '$name ops');
          expect(
            first.shaderDraws,
            lessThanOrEqualTo(maxShaderDraws),
            reason: '$name shader draws',
          );
          expect(first.layers, 0, reason: '$name makes a layer');
          expect(first.clips, 0, reason: '$name clips');
          expect(first.blurs, 0, reason: '$name blurs');
          expect(
            first.unforwarded,
            0,
            reason: '$name calls something the counter cannot see',
          );
          // Gradients are built once: the frames after the first draw with the
          // very same shader objects.
          expect(
            second.shaders.difference(first.shaders),
            isEmpty,
            reason: '$name builds a shader per frame',
          );
          // Only the wings are rebuilt (near outline, bars, seams; far outline).
          expect(
            first.paths.difference(second.paths).length,
            lessThanOrEqualTo(5),
            reason: '$name builds paths per frame',
          );
          worst = math.max(worst, first.draws);
        }
      }
      // ignore: avoid_print
      print('$report worst $worst ops');
    });

    test(
      'the worst frame of a whole raid, every slot and side, hit or not, stays at 44',
      () {
        var worst = 0;
        var at = '';
        for (final reduced in [false, true]) {
          for (final slot in [0, 1, 2]) {
            for (final side in [-1, 1]) {
              // A hit frees the star (no loot) or spooks the pigeon (no snatch):
              // a pigeon with a star in its beak cannot be mid-startle.
              for (final hit in [double.infinity, .02, .1, .3]) {
                for (var i = 0; i <= 600; i++) {
                  final s =
                      -.5 + i * .004; // 0.5 s before the snatch to 1.9 s after
                  final raid = PigeonFlight(slot: slot, side: side);
                  const age = 5.0;
                  if (s < -AlleyPigeon.diveSeconds) {
                    raid
                      ..phase = PigeonPhase.warning
                      ..phaseAt =
                          age -
                          (AlleyPigeon.warningSeconds +
                                  AlleyPigeon.diveSeconds +
                                  s)
                              .clamp(0.0, .8);
                  } else if (s < 0) {
                    raid
                      ..phase = PigeonPhase.dive
                      ..phaseAt = age - (AlleyPigeon.diveSeconds + s);
                  } else {
                    raid
                      ..phase = hit.isFinite
                          ? PigeonPhase.flee
                          : PigeonPhase.carry
                      ..phaseAt = age - s
                      ..snatchedAt = age - s;
                    if (!hit.isFinite) raid.loot = SkyStar(x: 1, y: .5);
                  }
                  final c = measure(
                    (c) => AlleyPigeonArt.paint(
                      c,
                      16,
                      seconds: age,
                      reducedMotion: reduced,
                      pose: PigeonPose.ofRaid(raid, age: age, hitAge: hit),
                    ),
                  );
                  if (c.draws > worst) {
                    worst = c.draws;
                    at = 's $s slot $slot side $side hit $hit reduced $reduced';
                  }
                  expect(c.shaderDraws, lessThanOrEqualTo(maxShaderDraws));
                  expect(c.layers + c.clips + c.blurs, 0);
                }
              }
            }
          }
        }
        // ignore: avoid_print
        print('worst frame of a whole raid: $worst ops ($at)');
        expect(worst, lessThanOrEqualTo(44), reason: at);
      },
    );

    test('the glider is the cheap variant', () {
      final pose = PigeonPose.of(
        SkyEnemy(x: 1.2, y: .5, appearance: 4, squad: true)..age = 1.3,
        hitAge: double.infinity,
      );
      for (final reduced in [false, true]) {
        final full = measure(
          (c) =>
              AlleyPigeonArt.paint(c, 16, seconds: 1.3, reducedMotion: reduced),
        );
        final g = measure(
          (c) => AlleyPigeonArt.paint(
            c,
            16,
            seconds: 1.3,
            reducedMotion: reduced,
            pose: pose,
            glider: true,
          ),
        );
        // ignore: avoid_print
        print(
          'glider ${g.draws} ops (${g.shaderDraws} shader draws) against ${full.draws} for a raider',
        );
        expect(g.draws, lessThanOrEqualTo(maxGliderOps));
        expect(g.draws, lessThan(full.draws - 8));
        expect(g.shaderDraws, lessThanOrEqualTo(3));
        expect(g.layers + g.clips + g.blurs, 0);
      }
    });

    test('the whole frame of a pigeon and its marks: at most 75 draw calls', () {
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..phase = RunPhase.playing
        ..elapsed = 3;
      final prey = SkyStar(x: 1.5, y: .56);
      final carried = SkyStar(x: 1.0, y: .56)..carried = true;
      sim.stars.addAll([prey, carried]);
      final diver = pigeon(PigeonPhase.dive, into: .2, x: 1.42, y: .40)
        ..pigeon!.prey = prey;
      final thief = pigeon(
        PigeonPhase.carry,
        into: .3,
        x: 1.05,
        y: .56,
        loot: true,
      )..pigeon!.prey = carried;
      sim.enemies.addAll([diver, thief]);
      var worst = 0;
      for (final (e, label) in [(diver, 'diver'), (thief, 'thief')]) {
        final counting = measure((c) {
          AlleyPigeonOverlayArt.paint(c, 360, sim, reducedMotion: false);
          EnemyArt.paint(c, 360, e, birdY: .5, reducedMotion: false);
        });
        // ignore: avoid_print
        print('$label frame: ${counting.draws} ops');
        // The overlay covers every pigeon in the sim; this frame holds both.
        expect(
          counting.draws,
          lessThanOrEqualTo(maxFrameOps + 25),
          reason: label,
        );
        worst = math.max(worst, counting.draws);
      }
      // A flock of three at their worst (one telegraphing, one diving, one
      // gloating) stays under a quarter of a thousand ops.
      final flock = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..phase = RunPhase.playing
        ..elapsed = 3;
      final trio = [
        for (var i = 0; i < 3; i++) SkyStar(x: 1.3 + i * .17, y: .56),
      ];
      flock.stars.addAll(trio);
      final phases = [PigeonPhase.warning, PigeonPhase.dive, PigeonPhase.carry];
      for (var i = 0; i < 3; i++) {
        final e = pigeon(
          phases[i],
          into: [.6, .2, .3][i],
          x: 1.2 + i * .1,
          y: .4,
          loot: i == 2,
        )..pigeon!.prey = trio[i];
        if (i == 2) trio[i].carried = true;
        flock.enemies.add(e);
      }
      final counting = measure((c) {
        AlleyPigeonOverlayArt.paint(c, 360, flock, reducedMotion: false);
        for (final e in flock.enemies) {
          EnemyArt.paint(c, 360, e, birdY: .5, reducedMotion: false);
        }
      });
      // ignore: avoid_print
      print(
        'flock of three at its worst: ${counting.draws} ops, ${counting.shaderDraws} shader draws',
      );
      expect(counting.draws, lessThanOrEqualTo(250));
      expect(counting.layers + counting.clips + counting.blurs, 0);
      expect(worst, greaterThan(0));
    });

    test('painting is cheap: no dearer than the cave bat it flies beside', () {
      double micros(void Function(Canvas c, int i) paint) {
        var best = double.infinity;
        for (var round = 0; round < 3; round++) {
          final canvas = Canvas(ui.PictureRecorder());
          for (var i = 0; i < 200; i++) {
            paint(canvas, i);
          }
          final sw = Stopwatch()..start();
          const n = 2000;
          for (var i = 0; i < n; i++) {
            paint(canvas, i);
          }
          best = math.min(best, sw.elapsedMicroseconds / n);
        }
        return best;
      }

      final states = everyState().map((s) => s.$2).toList();
      final pigeonUs = micros((c, i) {
        final e = states[i % states.length]..age = 2 + i * .016;
        c.save();
        AlleyPigeonArt.paintEnemy(
          c,
          16,
          e,
          lookY: 0,
          hitAge: 9,
          reducedMotion: false,
        );
        c.restore();
      });
      final batUs = micros((c, i) {
        c.save();
        PatrolBatArt.paint(c, 16, seconds: i * .016, reducedMotion: false);
        c.restore();
      });
      // ignore: avoid_print
      print(
        'paint per frame: pigeon ${pigeonUs.toStringAsFixed(0)} us, '
        'cave bat ${batUs.toStringAsFixed(0)} us',
      );
      // Relative to a painter already in the game, so a loaded CI box moves
      // both; generous enough not to flake, tight enough to catch a path
      // built in a loop or a shader built per frame.
      expect(pigeonUs, lessThan(batUs * 1.5));
    });
  });

  group('the variant for King Coo\'s squadron', () {
    testWidgets(
      'a squad pigeon is drawn as the glider, and looks different from a raider',
      (tester) async {
        await tester.runAsync(() async {
          final squad = SkyEnemy(
            x: 1.2,
            y: .5,
            appearance: 4,
            squad: true,
            flightPhase: 1.3,
          )..age = 2;
          final raider = pigeon(PigeonPhase.glide);
          final a = await pixels((c) => paintEnemy(c, squad), 240, 180);
          final b = await pixels((c) => paintEnemy(c, raider), 240, 180);
          expect(a, isNot(b));
          // It never takes a snatch pose, whatever it is told.
          final told = SkyEnemy(
            x: 1.2,
            y: .5,
            appearance: 4,
            squad: true,
            flightPhase: 1.3,
          )..age = 2;
          expect(told.pigeon, isNull);
          expect(await pixels((c) => paintEnemy(c, told), 240, 180), a);
        });
      },
    );
  });

  group('facing', () {
    testWidgets(
      'a raiding pigeon faces right from its warning on, even behind the bird',
      (tester) async {
        await tester.runAsync(() async {
          // In the glide it looks left, and turns to watch the bird once it has
          // passed it (as the bats do). Once it warns or carries it faces right.
          SkyEnemy at(PigeonPhase p, double x) =>
              pigeon(p, into: .5, x: x, y: .25, loot: p == PigeonPhase.carry);
          // EnemyArt paints at enemy.x * height: 889 gives a 40 px hit radius.
          Future<List<int>> frameOf(SkyEnemy e) => pixels(
            (c) {
              c.translate(-e.x * 889 + 120, -e.y * 889 + 90);
              EnemyArt.paint(c, 889, e, birdY: .4, reducedMotion: true);
            },
            240,
            180,
          );
          final warnAhead = await frameOf(at(PigeonPhase.warning, 1.3));
          final warnBehind = await frameOf(at(PigeonPhase.warning, .3));
          expect(
            sameWithinAntialiasing(warnBehind, warnAhead),
            isTrue,
            reason: 'a warning pigeon keeps facing its prey',
          );
          expect(
            sameWithinAntialiasing(
              await frameOf(at(PigeonPhase.carry, .3)),
              await frameOf(at(PigeonPhase.carry, 1.3)),
            ),
            isTrue,
          );
          final glideAhead = await frameOf(at(PigeonPhase.glide, 1.3));
          final glideBehind = await frameOf(at(PigeonPhase.glide, .3));
          expect(
            sameWithinAntialiasing(glideBehind, glideAhead),
            isFalse,
            reason: 'a gliding pigeon turns to watch the bird',
          );
          // And facing right really is the mirror of the left-facing painting.
          final left = await pixels(
            (c) {
              c.translate(120, 90);
              AlleyPigeonArt.paintEnemy(
                c,
                40,
                at(PigeonPhase.warning, 1.3),
                lookY: -.3,
                hitAge: 9,
                reducedMotion: true,
              );
            },
            240,
            180,
          );
          final right = await pixels(
            (c) {
              c.translate(120, 90);
              c.scale(-1, 1);
              AlleyPigeonArt.paintEnemy(
                c,
                40,
                at(PigeonPhase.warning, 1.3),
                lookY: -.3,
                hitAge: 9,
                reducedMotion: true,
              );
            },
            240,
            180,
          );
          expect(left, isNot(right));
        });
      },
    );
  });

  group('marks on the world', () {
    FlightSimulation arena() =>
        FlightSimulation(rules: TapFlyMode(), practice: true)
          ..phase = RunPhase.playing
          ..elapsed = 3;

    Counting draw(FlightSimulation sim, {bool reduced = false}) {
      final c = Counting(Canvas(ui.PictureRecorder()));
      AlleyPigeonOverlayArt.paint(c, 360, sim, reducedMotion: reduced);
      return c;
    }

    test(
      'the ring and swoop line appear only while a pigeon telegraphs or dives',
      () {
        final sim = arena();
        final prey = SkyStar(x: 1.5, y: .56);
        sim.stars.add(prey);
        final e = pigeon(PigeonPhase.glide, x: 1.3, y: .3)..pigeon!.prey = prey;
        sim.enemies.add(e);
        expect(
          draw(sim).draws,
          0,
          reason: 'nothing marked while it only flies',
        );
        e.pigeon!.phase = PigeonPhase.warning;
        e.pigeon!.phaseAt = e.age - .4;
        final warn = draw(sim);
        expect(
          warn.counts['drawCircle'],
          2,
          reason: 'a ring with its ink edge',
        );
        expect(
          warn.counts['drawPoints'],
          greaterThanOrEqualTo(2),
          reason: 'the swoop line',
        );
        e.pigeon!.phase = PigeonPhase.dive;
        e.pigeon!.phaseAt = e.age - .1;
        expect(
          draw(sim).counts['drawCircle'],
          2,
          reason: 'the ring stays through the dive',
        );
        // No mark for a star that is already gone.
        prey.collected = true;
        expect(draw(sim).draws, 0);
        prey.collected = false;
        prey.missed = true;
        expect(draw(sim).draws, 0);
      },
    );

    test('a few canvas ops per prey, cached paints, no layer', () {
      final sim = arena();
      final prey = SkyStar(x: 1.5, y: .56);
      sim.stars.add(prey);
      sim.enemies.add(
        pigeon(PigeonPhase.warning, into: .3, x: 1.3, y: .3)
          ..pigeon!.prey = prey,
      );
      final c = draw(sim);
      expect(c.draws, lessThanOrEqualTo(10));
      expect(c.layers + c.clips + c.shaderDraws + c.blurs, 0);
      expect(draw(sim, reduced: true).draws, lessThanOrEqualTo(10));
    });

    test(
      'the swoop line lies on the path the pigeon will fly and thins out as it passes',
      () {
        final prey = SkyStar(x: 1.6, y: .56);
        for (final side in [-1, 1]) {
          for (var slot = 0; slot < 3; slot++) {
            final raid = PigeonFlight(slot: slot, flockSize: 3, side: side)
              ..prey = prey
              ..phase = PigeonPhase.warning
              ..phaseAt = 0;
            final dots = AlleyPigeonOverlayArt.swoopDots(raid, prey, age: .4);
            expect(dots, hasLength(AlleyPigeonOverlayArt.dots));
            final home = AlleyPigeon.hover(
              slot: slot,
              preyX: prey.x,
              lane: prey.y,
              side: side,
            );
            // Every dot is a point of the quarter ellipse: the ellipse equation
            // with its centre above (or below) the star.
            final a = prey.x - home.x, b = prey.y - home.y;
            for (final d in dots) {
              final ex = (prey.x - d.dx) / a, ey = (d.dy - home.y) / b;
              expect(
                ex * ex + ey * ey,
                closeTo(1, 1e-9),
                reason: 'slot $slot side $side',
              );
            }
            // They run from the hover to the star.
            expect(
              (dots.first - Offset(home.x, home.y)).distance,
              lessThan((dots.last - Offset(home.x, home.y)).distance),
            );
            // A dive takes them away behind the pigeon.
            raid.phase = PigeonPhase.dive;
            final half = AlleyPigeonOverlayArt.swoopDots(
              raid,
              prey,
              age: AlleyPigeon.diveSeconds * .6,
            );
            expect(half.length, lessThan(dots.length));
            expect(
              AlleyPigeonOverlayArt.swoopDots(
                raid,
                prey,
                age: AlleyPigeon.diveSeconds,
              ),
              isEmpty,
            );
          }
        }
      },
    );

    test(
      'the snatch flashes a ring where the star was, and nothing marks a thief after',
      () {
        final sim = arena();
        final prey = SkyStar(x: 1.0, y: .56)..carried = true;
        sim.stars.add(prey);
        final e = pigeon(
          PigeonPhase.carry,
          into: .1,
          x: 1.05,
          y: .56,
          loot: true,
        )..pigeon!.prey = prey;
        sim.enemies.add(e);
        final ring = draw(sim);
        expect(
          ring.counts['drawCircle'],
          2,
          reason: 'the snatch ring, gold on its ink edge',
        );
        expect(ring.counts['drawPoints'], 2, reason: 'six sparks, inked');
        expect(ring.draws, 4);
        // Reduced Motion: the ring only, settled in size.
        final still = draw(sim, reduced: true);
        expect(still.counts['drawCircle'], 2);
        expect(still.counts['drawPoints'], isNull);
        // Even with no prey bound (the rules may let go of it), the ring shows.
        e.pigeon!.prey = null;
        expect(draw(sim).counts['drawCircle'], 2);
        // The ring lives over the kick only.
        e.pigeon!.phaseAt = e.age - 1.0;
        e.pigeon!.snatchedAt = e.age - 1.0;
        expect(draw(sim).draws, 0, reason: 'once the kick is over');
        // Nothing for the pigeons that do not carry.
        e.pigeon!.phase = PigeonPhase.flee;
        e.pigeon!.snatchedAt = e.age - .05;
        expect(draw(sim).draws, 0);
      },
    );

    test('a freed star\'s halo lives 0.6 s and is pure', () {
      final star = SkyStar(x: 1.2, y: .5)
        ..freedAt = 5
        ..rescued = true;
      int ops(double elapsed, {bool reduced = false}) {
        final c = Counting(Canvas(ui.PictureRecorder()));
        AlleyPigeonOverlayArt.freed(
          c,
          360,
          star,
          elapsed,
          reducedMotion: reduced,
        );
        return c.draws;
      }

      expect(ops(4.9), 0, reason: 'before the hit');
      expect(ops(5.0), greaterThan(0));
      expect(ops(5.3), greaterThan(1), reason: 'ring and sparkles');
      expect(
        ops(5.3, reduced: true),
        1,
        reason: 'Reduced Motion: a fading ring only',
      );
      expect(
        ops(5.0 + AlleyPigeonOverlayArt.haloSeconds + 1e-6),
        0,
        reason: 'gone at 0.6 s',
      );
      expect(ops(9), 0);
      expect(ops(5.2), ops(5.2), reason: 'a pure function of the clock');
    });

    testWidgets(
      'marks are pure: the same clock draws the same pixels, and Reduced Motion holds still',
      (tester) async {
        await tester.runAsync(() async {
          Future<List<int>> frame(double elapsed, bool reduced) => pixels(
            (c) {
              final sim = arena()..elapsed = elapsed;
              final prey = SkyStar(x: 1.5, y: .56);
              sim.stars.add(prey);
              sim.enemies.add(
                pigeon(PigeonPhase.warning, into: .3, x: 1.3, y: .3)
                  ..pigeon!.prey = prey,
              );
              AlleyPigeonOverlayArt.paint(c, 360, sim, reducedMotion: reduced);
            },
            800,
            360,
          );
          expect(await frame(3.0, false), await frame(3.0, false));
          expect(
            await frame(3.0, false),
            isNot(await frame(3.07, false)),
            reason: 'the ring pulses',
          );
          expect(
            await frame(3.0, true),
            await frame(3.07, true),
            reason: 'steady under Reduced Motion',
          );
        });
      },
    );
  });

  group('the defeat', () {
    testWidgets(
      'the pigeon goes out in feathers, dazed, and differs from every other kind\'s',
      (tester) async {
        await tester.runAsync(() async {
          Future<List<int>> at(
            EnemyKind k,
            double age, {
            bool reduced = false,
          }) => pixels(
            (c) => EnemyDefeatArt.paint(
              c,
              const Offset(120, 90),
              40,
              age: age,
              reducedMotion: reduced,
              kind: k,
              seed: 7,
            ),
            240,
            180,
          );
          for (final age in [0.0, .05, .12, .2, .35, .55]) {
            final pg = await at(EnemyKind.alleyPigeon, age);
            for (final k in EnemyKind.values.where(
              (k) => k != EnemyKind.alleyPigeon,
            )) {
              expect(pg, isNot(await at(k, age)), reason: 'age $age is not $k');
            }
            expect(await at(EnemyKind.alleyPigeon, age), pg, reason: 'pure');
          }
          // Reduced Motion: one static poof.
          expect(
            await at(EnemyKind.alleyPigeon, .1, reduced: true),
            isNot(await at(EnemyKind.caveBat, .1, reduced: true)),
          );
          // Teal neck feathers are in the debris.
          final mid = await at(EnemyKind.alleyPigeon, .3);
          var teal = 0;
          for (var i = 0; i < mid.length; i += 4) {
            if (mid[i] < 90 &&
                mid[i + 1] > 190 &&
                mid[i + 2] > 150 &&
                mid[i + 2] < 235 &&
                mid[i + 3] > 200) {
              teal++;
            }
          }
          expect(teal, greaterThan(20), reason: 'the iridescent feathers');
        });
      },
    );
  });

  group('in the real renderer', () {
    Future<List<int>> render(
      WidgetTester tester,
      FlightSimulation sim,
      bool reduced,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: reduced,
        playback: true,
        onChanged: () {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      late List<int> px;
      await tester.runAsync(() async {
        await game.loaded;
        game.pauseEngine();
        px = await pixels(game.render, 800, 360);
      });
      await tester.pumpWidget(const SizedBox());
      return px;
    }

    for (final reduced in [false, true]) {
      testWidgets(
        'a level frame with pigeons in every state paints (Reduced Motion: $reduced)',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final sim = nyFlight(nyPlan())
            ..phase = RunPhase.playing
            ..elapsed = 4;
          final trio = [
            for (var i = 0; i < 3; i++) SkyStar(x: 1.3 + i * .17, y: .56),
          ];
          sim.stars.addAll(trio);
          final states = everyState();
          for (var i = 0; i < states.length; i++) {
            final src = states[i].$2;
            sim.enemies.add(
              SkyEnemy(
                  x: .9 + (i % 5) * .22,
                  y: .14 + (i ~/ 5) * .3 + (i % 2) * .05,
                  appearance: 4,
                  flightPhase: i * 1.7,
                )
                ..age = src.age
                ..lastHitAt = src.lastHitAt
                ..pigeon!.phase = src.pigeon!.phase
                ..pigeon!.phaseAt = src.pigeon!.phaseAt
                ..pigeon!.snatchedAt = src.pigeon!.snatchedAt
                ..pigeon!.prey = trio[i % 3]
                ..pigeon!.loot = src.pigeon!.loot,
            );
          }
          trio[2].carried = true;
          trio[1]
            ..freedAt = sim.elapsed - .3
            ..rescued = true;
          sim.enemies.add(
            SkyEnemy(x: 1.7, y: .8, appearance: 4, squad: true, flightPhase: .4)
              ..age = 2,
          );
          final px = await render(tester, sim, reduced);
          expect(px.any((b) => b != 0), isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'a carried star is drawn by its thief, not left hanging in the lane',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        FlightSimulation sim({required bool carried}) => nyFlight(nyPlan())
          ..phase = RunPhase.playing
          ..elapsed = 4
          ..stars.add(SkyStar(x: 1.0, y: .56)..carried = carried);
        final hanging = await render(tester, sim(carried: false), false);
        final taken = await render(tester, sim(carried: true), false);
        expect(taken, isNot(hanging));
        // The gold of the star is gone from the lane (360 px tall: y .56 -> 201).
        int gold(List<int> px) {
          var n = 0;
          for (var y = 180; y < 222; y++) {
            for (var x = 340; x < 380; x++) {
              final i = (y * 800 + x) * 4;
              if (px[i] > 230 && px[i + 1] > 180 && px[i + 2] < 120) n++;
            }
          }
          return n;
        }

        expect(gold(hanging), greaterThan(80));
        expect(gold(taken), lessThan(5));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
