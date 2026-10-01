import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart' show FlightSimulation;
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_encounter_ui.dart';
import 'package:push_up_bird/game/king_coo_hud_art.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'king_coo_test_kit.dart';

/// Review renders: `--dart-define=KING_COO_HUD_REVIEW=true` writes the sheets
/// to `build/king-coo-hud/` (never source).
const _review = bool.fromEnvironment('KING_COO_HUD_REVIEW');
const _out = 'build/king-coo-hud';

SkyBoss _fight(
  double combat, {
  int? hp,
  bool fury = false,
  double? hitAgo,
  int damage = 10,
  int puffDamage = 0,
  double? furyAgo,
  int cycles = 0,
  Setup? setup,
}) {
  final b = cooBoss(
    combat: combat,
    cycles: cycles,
    fury: fury || (hp != null && hp <= 70),
  );
  if (hp != null) b.hp = hp;
  if (furyAgo != null) b.enragedAt = b.age - furyAgo;
  if (hitAgo != null) {
    b.lastHitAt = b.age - hitAgo;
    b.lastDamage = damage;
  }
  b.puffDamage = puffDamage;
  setup?.call(b);
  return b;
}

Future<ui.Image> _shot(int w, int h, void Function(Canvas) draw) =>
    render(w, h, draw);

Future<void> _save(String name, ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$_out/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  expect(file.existsSync(), isTrue);
}

/// One real flight frame over New York's night: the figure as the rules place
/// him at [boss]'s age, the bird, and the strip as the game paints it.
void _frame(
  Canvas c,
  double w,
  SkyBoss boss, {
  bool reduced = false,
  void Function(Canvas c, Offset at, double h)? above,
  bool bird = true,
}) {
  final pose = poseOf(boss, reduced: reduced, light: newYorkLight());
  nyFrame(
    c,
    w,
    pose: pose,
    combat: boss.age - boss.arrivalDuration,
    bird: bird,
    above: (c, at, h) {
      BossHealthBarArt.paint(c, Size(w, h), boss, reducedMotion: reduced);
      above?.call(c, at, h);
    },
  );
}

const _night = Color(0xff171c39);

/// Counts what a frame asks of the canvas (draw calls, clips, layers, blurs).
class Counting implements Canvas {
  Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get paragraphs => counts['drawParagraph'] ?? 0;
  int get layers => counts['saveLayer'] ?? 0;
  int get blurs => counts['maskFilter'] ?? 0;
  int get clips => counts.entries
      .where((e) => e.key.startsWith('clip'))
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
    Rect r, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    _n('clipRect');
    inner.clipRect(r, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect r, {bool doAntiAlias = true}) {
    _n('clipRRect');
    inner.clipRRect(r, doAntiAlias: doAntiAlias);
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

/// Paints with [draw] on a counting canvas, after a warm-up frame, and returns
/// the counts and the number of gradient shaders the frame built.
(Counting, int) measure(void Function(Canvas) draw) {
  draw(Canvas(ui.PictureRecorder()));
  final before = KingCooKit.shadersBuilt;
  final canvas = Counting(Canvas(ui.PictureRecorder()));
  draw(canvas);
  return (canvas, KingCooKit.shadersBuilt - before);
}

/// The anchor the rules give him on a [w] x 360 screen.
double _anchorX(double w) => math.max(birdX + .70, w / 360 - .55);

/// A frame of the arrival, [age] seconds in: the backdrop, the figure as the
/// pose has him, the letterbox, the shout and the card, as the staging will
/// layer them.
void _arrival(
  Canvas c,
  double w,
  double age, {
  bool reduced = false,
  String? line = '“Nobody flies till the bread cart is found!”',
  double birdY = .72,
}) {
  final boss = arrivingBoss(age)..x = _anchorX(w);
  final pose = poseOf(boss, reduced: reduced, light: newYorkLight());
  final m = BossMotion(boss, reducedMotion: reduced);
  nyFrame(
    c,
    w,
    pose: pose,
    bird: true,
    birdY: birdY,
    silhouette: pose.silhouette > .5,
    above: (c, at, h) {
      final mouth = at + KingCooBossRig.mouthAt(pose) * (h * SkyBoss.radius);
      KingCooEncounterUi.shout(
        c,
        mouth,
        h,
        shock: pose.shock,
        roar: pose.roar,
        reduced: reduced,
        chest: at,
      );
      final bar = h * .082 * m.focus;
      if (bar > 0) {
        c.drawRect(
          Rect.fromLTWH(0, 0, w, bar),
          Paint()..color = _night.withValues(alpha: .95),
        );
        c.drawRect(
          Rect.fromLTWH(0, h - bar, w, bar),
          Paint()..color = _night.withValues(alpha: .95),
        );
      }
      KingCooEncounterUi.nameCard(
        c,
        Size(w, h),
        boss,
        m,
        birdY: birdY,
        line: line,
      );
    },
  );
}

/// A frame of the defeat, [death] seconds after the killing blow: the figure
/// fading as the staging fades it, then the burst, the snow and the badge.
void _defeat(Canvas c, double w, double death, {bool reduced = false}) {
  final boss = dyingBoss(death)..x = _anchorX(w);
  final pose = poseOf(boss, reduced: reduced, light: newYorkLight());
  const h = 360.0;
  final k = death - SkyBoss.burstAt;
  final at = bossAnchor(w);
  c.save();
  c.clipRect(Offset.zero & Size(w, h));
  SkyScenery.paint(
    c,
    Size(w, h),
    seconds: 12,
    distance: 12 * .36,
    held: WorldRegion.newYork,
  );
  final opacity = reduced
      ? math.min(pose.opacity, 1 - BossMotion.ramp(death, .3, SkyBoss.burstAt))
      : math.min(pose.opacity, 1 - BossMotion.ramp(death, .7, .86));
  if (opacity > 0) {
    c.saveLayer(
      null,
      Paint()..color = const Color(0xffffffff).withValues(alpha: opacity),
    );
    paintFigure(c, pose, at, h);
    c.restore();
  }
  c.save();
  c.translate(birdX * h, .6 * h);
  final bw = h * .145;
  BirdPuppet.paint(
    c,
    Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
    bird: 0,
    wing: .3,
  );
  c.restore();
  if (k >= 0) {
    if (!reduced) KingCooEncounterUi.shockwave(c, at, h, k);
    KingCooEncounterUi.burst(c, at, h, BossMotion.ramp(k, 0, 1.3), reduced);
    KingCooEncounterUi.featherSnow(c, at, h, k, reduced: reduced);
    KingCooEncounterUi.victoryBadge(c, at, h, k, reduced: reduced);
  }
  c.restore();
}

Future<void> _sheet(
  String name,
  int cols,
  Size cell,
  List<(String, void Function(Canvas c))> frames, {
  Rect? crop,
  double zoom = 1,
}) async {
  final rows = (frames.length / cols).ceil();
  final src = crop ?? Offset.zero & cell;
  final dst = Size(src.width * zoom, src.height * zoom);
  final images = <ui.Image>[];
  for (final (_, draw) in frames) {
    images.add(await _shot(cell.width.toInt(), cell.height.toInt(), draw));
  }
  final sheet = await _shot(
    (dst.width * cols).toInt(),
    (dst.height * rows).toInt(),
    (c) {
      c.drawRect(
        Offset.zero & Size(dst.width * cols, dst.height * rows),
        Paint()..color = const Color(0xff101020),
      );
      for (var i = 0; i < images.length; i++) {
        final to = Rect.fromLTWH(
          (i % cols) * dst.width,
          (i ~/ cols) * dst.height,
          dst.width,
          dst.height,
        );
        c.drawImageRect(
          images[i],
          src,
          to,
          Paint()
            ..filterQuality = zoom == zoom.roundToDouble() && zoom > 1
                ? FilterQuality.none
                : FilterQuality.medium,
        );
        label(
          c,
          frames[i].$1,
          to.topLeft + const Offset(4, 3),
          size: 11,
          color: const Color(0xffffffff),
        );
      }
    },
  );
  await _save(name, sheet);
  for (final i in images) {
    i.dispose();
  }
  sheet.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'review renders',
    skip: _review ? false : 'set KING_COO_HUD_REVIEW=true',
    () {
      final states = <(String, SkyBoss Function())>[
        ('full', () => _fight(2.0)),
        ('60pct', () => _fight(2.0, hp: 84)),
        ('puffed-0', () => _fight(8.4)),
        (
          'puffed-1-hit',
          () => _fight(
            8.6,
            hitAgo: .06,
            puffDamage: 20,
            setup: (b) => b.lastPuffHitAt = b.age - .06,
          ),
        ),
        ('puffed-2', () => _fight(9.3, puffDamage: 40)),
        ('fury-onset', () => _fight(2.0, hp: 70, furyAgo: .15)),
        ('fury', () => _fight(2.0, hp: 60, furyAgo: 5)),
        ('5pct', () => _fight(2.0, hp: 7, furyAgo: 20)),
        ('entrance-.3', () => _fight(.3)),
        ('hit', () => _fight(2.0, hp: 120, hitAgo: .04)),
        ('chip', () => _fight(2.0, hp: 110, hitAgo: .35, damage: 12)),
        ('defeated', () => dyingBoss(.5)),
      ];

      for (final w in [640.0, 800.0]) {
        testWidgets('bar sheet $w', (tester) async {
          await tester.runAsync(() async {
            await loadFonts();
            const rowH = 66.0;
            for (final reduced in [false, true]) {
              final images = <ui.Image>[];
              for (final (_, make) in states) {
                images.add(
                  await _shot(
                    w.toInt(),
                    360,
                    (c) => _frame(c, w, make(), reduced: reduced),
                  ),
                );
              }
              // The strip's area, 1:1 and at 2x with nearest sampling.
              final sheet = await _shot(
                (w * 2).toInt(),
                (rowH * 2 * states.length).toInt(),
                (c) {
                  c.drawRect(
                    Offset.zero & Size(w * 2, rowH * 2 * states.length),
                    Paint()..color = const Color(0xff101020),
                  );
                  for (var i = 0; i < images.length; i++) {
                    c.drawImageRect(
                      images[i],
                      Rect.fromLTWH(0, 0, w, rowH),
                      Rect.fromLTWH(0, i * rowH * 2, w * 2, rowH * 2),
                      Paint()..filterQuality = FilterQuality.none,
                    );
                    label(
                      c,
                      states[i].$1,
                      Offset(4, i * rowH * 2 + 4),
                      size: 11,
                      color: const Color(0xffffffff),
                    );
                  }
                },
              );
              await _save(
                'bars-${w.toInt()}${reduced ? '-reduced' : ''}',
                sheet,
              );
              for (final i in images) {
                i.dispose();
              }
              sheet.dispose();
            }
          });
        });
      }

      testWidgets('close-ups', (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          const w = 640.0;
          const zoom = 8.0;
          final picks = <(String, SkyBoss Function(), Rect)>[
            (
              'crest-calm',
              () => _fight(2.0),
              const Rect.fromLTWH(172, 4, 60, 30),
            ),
            (
              'crest-blue',
              () => _fight(8.4),
              const Rect.fromLTWH(172, 4, 60, 30),
            ),
            (
              'crest-red',
              () => _fight(8.55),
              const Rect.fromLTWH(172, 4, 60, 30),
            ),
            (
              'crest-fury',
              () => _fight(2.0, hp: 60, furyAgo: 5),
              const Rect.fromLTWH(172, 4, 60, 30),
            ),
            (
              'mid-calm',
              () => _fight(2.0, hp: 100),
              const Rect.fromLTWH(290, 0, 80, 34),
            ),
            (
              'mid-fury-onset',
              () => _fight(2.0, hp: 70, furyAgo: .15),
              const Rect.fromLTWH(290, 0, 80, 34),
            ),
            (
              'mid-fury',
              () => _fight(2.0, hp: 66, furyAgo: 5),
              const Rect.fromLTWH(290, 0, 80, 34),
            ),
            (
              'edge-60',
              () => _fight(2.0, hp: 84),
              const Rect.fromLTWH(290, 0, 80, 34),
            ),
            (
              'edge-20',
              () => _fight(2.0, hp: 30),
              const Rect.fromLTWH(270, 0, 80, 34),
            ),
          ];
          final images = <ui.Image>[];
          for (final (_, make, _) in picks) {
            images.add(await _shot(640, 360, (c) => _frame(c, w, make())));
          }
          const cols = 3;
          final cell = const Size(80 * zoom / 2, 34 * zoom / 2);
          final rows = (picks.length / cols).ceil();
          final sheet = await _shot(
            (cell.width * cols).toInt(),
            (cell.height * rows).toInt(),
            (c) {
              for (var i = 0; i < picks.length; i++) {
                final dst = Rect.fromLTWH(
                  (i % cols) * cell.width,
                  (i ~/ cols) * cell.height,
                  cell.width,
                  cell.height,
                );
                c.save();
                c.clipRect(dst);
                c.drawImageRect(
                  images[i],
                  picks[i].$3,
                  dst,
                  Paint()..filterQuality = FilterQuality.none,
                );
                c.restore();
                label(
                  c,
                  picks[i].$1,
                  dst.topLeft + const Offset(3, 2),
                  size: 10,
                  color: const Color(0xffffffff),
                );
              }
            },
          );
          await _save('closeups', sheet);
        });
      });

      for (final w in [640.0, 800.0]) {
        for (final reduced in [false, true]) {
          final tag = '${w.toInt()}${reduced ? '-reduced' : ''}';
          testWidgets('arrival $tag', (tester) async {
            await tester.runAsync(() async {
              await loadFonts();
              final ages = [2.7, 2.85, 2.95, 3.1, 3.3, 3.6, 4.0, 4.3, 4.5];
              await _sheet('arrival-$tag', 3, Size(w, 360), [
                for (final a in ages)
                  ('age $a', (c) => _arrival(c, w, a, reduced: reduced)),
              ]);
            });
          });
          testWidgets('defeat $tag', (tester) async {
            await tester.runAsync(() async {
              await loadFonts();
              final deaths = [.1, .5, .85, .95, 1.05, 1.25, 1.5, 1.9, 2.4];
              await _sheet('defeat-$tag', 3, Size(w, 360), [
                for (final d in deaths)
                  ('death $d', (c) => _defeat(c, w, d, reduced: reduced)),
              ]);
            });
          });
        }
      }

      for (final reduced in [false, true]) {
        testWidgets('effects ${reduced ? 'reduced' : 'motion'}', (
          tester,
        ) async {
          await tester.runAsync(() async {
            await loadFonts();
            const w = 640.0;
            Future<void> strip(
              String name,
              List<double> ts,
              void Function(Canvas c, Offset at, double h, double t) draw, {
              SkyBoss Function()? make,
            }) async {
              await _sheet(
                '$name${reduced ? '-reduced' : ''}',
                4,
                const Size(w, 360),
                [
                  for (final t in ts)
                    (
                      't $t',
                      (c) {
                        final boss = (make ?? () => _fight(2.0))();
                        nyFrame(
                          c,
                          w,
                          pose: poseOf(
                            boss,
                            reduced: reduced,
                            light: newYorkLight(),
                          ),
                          above: (c, at, h) => draw(c, at, h, t),
                        );
                      },
                    ),
                ],
                crop: const Rect.fromLTWH(220, 40, 340, 260),
                zoom: 1.4,
              );
            }

            await strip('fx-hit', [.0, .08, .2, .4, .6, .85, .95, .99], (
              c,
              at,
              h,
              t,
            ) {
              KingCooEncounterUi.hit(
                c,
                at,
                h,
                t,
                reduced: reduced,
                puffed: false,
              );
            });
            await strip('fx-hit-puffed', [.0, .08, .2, .4, .6, .85, .95, .99], (
              c,
              at,
              h,
              t,
            ) {
              KingCooEncounterUi.hit(
                c,
                at,
                h,
                t,
                reduced: reduced,
                puffed: true,
              );
            });
            await strip('fx-fury', [.0, .08, .2, .35, .5, .7, .85, .98], (
              c,
              at,
              h,
              t,
            ) {
              KingCooEncounterUi.furyBurst(c, at, h, t, reduced: reduced);
            });
            await strip('fx-pop', [.0, .08, .2, .35, .5, .7, .85, .98], (
              c,
              at,
              h,
              t,
            ) {
              KingCooEncounterUi.pop(c, at, h, t, reduced: reduced);
            });
          });
        });
      }

      testWidgets('compare with the other bosses', (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          for (final w in [640.0, 800.0]) {
            SkyBoss other(BossKind kind, int number, {bool fury = false}) {
              final b = SkyBoss(
                number: number,
                x: 1.5,
                kind: kind,
                cinematic: true,
              );
              b.age = b.arrivalDuration + 2;
              if (fury) {
                b.hp = b.maxHp ~/ 2 - 3;
                b.enragedAt = b.age - 5;
              }
              return b;
            }

            final rows = <(String, SkyBoss)>[
              ('Baron', other(BossKind.baronBat, 1)),
              ('Spitter King', other(BossKind.spitterBeetle, 2)),
              ('Dusk Empress', other(BossKind.duskMoth, 3)),
              ('Pirate Captain', other(BossKind.pirate, 4)),
              ('Ember Dragon', other(BossKind.dragon, 5)),
              ('King Coo', _fight(2.0)),
              ('Baron fury', other(BossKind.baronBat, 1, fury: true)),
              ('Dragon fury', other(BossKind.dragon, 5, fury: true)),
              ('King Coo fury', _fight(2.0, hp: 66, furyAgo: 5)),
            ];
            await _sheet('compare-${w.toInt()}', 1, Size(w, 50), [
              for (final (name, b) in rows)
                (
                  name,
                  (c) {
                    SkyScenery.paint(
                      c,
                      Size(w, 360),
                      seconds: 12,
                      distance: 4,
                      held: WorldRegion.newYork,
                    );
                    BossHealthBarArt.paint(c, Size(w, 360), b);
                  },
                ),
            ], zoom: 2);
          }
        });
      });

      testWidgets('strip at 4x', (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          const w = 640.0;
          await _sheet(
            'strip-4x',
            1,
            const Size(w, 360),
            [
              ('calm', (c) => _frame(c, w, _fight(2.0, hp: 100))),
              ('puffed', (c) => _frame(c, w, _fight(8.55, puffDamage: 20))),
              ('fury', (c) => _frame(c, w, _fight(2.0, hp: 50, furyAgo: 5))),
            ],
            crop: const Rect.fromLTWH(165, 0, 310, 48),
            zoom: 4,
          );
        });
      });

      testWidgets('full frames', (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          for (final w in [640.0, 800.0]) {
            for (final (name, make) in states) {
              if (!['full', 'puffed-1-hit', 'fury'].contains(name)) continue;
              final image = await _shot(
                w.toInt(),
                360,
                (c) => _frame(c, w, make()),
              );
              await _save('frame-${w.toInt()}-$name', image);
              image.dispose();
            }
          }
        });
      });
    },
  );

  // ---------------------------------------------------------- the tests --

  const phones = [
    Size(568, 320),
    Size(640, 360),
    Size(800, 360),
    Size(844, 390),
    Size(932, 430),
  ];

  Future<Uint8List> px(void Function(Canvas) draw, {Size size = const Size(640, 360)}) =>
      rawPixels(size.width.round(), size.height.round(), draw);

  bool blank(Uint8List rgba) {
    for (var i = 3; i < rgba.length; i += 4) {
      if (rgba[i] != 0) return false;
    }
    return true;
  }

  int differing(Uint8List a, Uint8List b, {int w = 640, Rect? within, int tolerance = 12}) {
    var n = 0;
    final rows = a.length ~/ 4 ~/ w;
    final r = within ?? Rect.fromLTWH(0, 0, w.toDouble(), rows.toDouble());
    for (var y = r.top.floor(); y < r.bottom.ceil() && y < rows; y++) {
      for (var x = r.left.floor(); x < r.right.ceil() && x < w; x++) {
        final i = (y * w + x) * 4;
        if ((a[i] - b[i]).abs() +
                (a[i + 1] - b[i + 1]).abs() +
                (a[i + 2] - b[i + 2]).abs() +
                (a[i + 3] - b[i + 3]).abs() >
            tolerance) {
          n++;
        }
      }
    }
    return n;
  }

  /// Pixels inside [within] (all, when null) that satisfy [test].
  int count(
    Uint8List rgba,
    bool Function(int r, int g, int b, int a) test, {
    int w = 640,
    Rect? within,
  }) {
    var n = 0;
    final rows = rgba.length ~/ 4 ~/ w;
    final r = within ?? Rect.fromLTWH(0, 0, w.toDouble(), rows.toDouble());
    for (var y = r.top.floor(); y < r.bottom.ceil() && y < rows; y++) {
      for (var x = r.left.floor(); x < r.right.ceil() && x < w; x++) {
        final i = (y * w + x) * 4;
        if (test(rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3])) n++;
      }
    }
    return n;
  }

  /// The centre of mass of the non-transparent pixels, weighted by alpha.
  Offset centroid(Uint8List rgba, {int w = 640}) {
    var sx = 0.0, sy = 0.0, sum = 0.0;
    for (var i = 3, p = 0; i < rgba.length; i += 4, p++) {
      final a = rgba[i];
      if (a == 0) continue;
      sx += (p % w) * a;
      sy += (p ~/ w) * a;
      sum += a;
    }
    return sum == 0 ? Offset.zero : Offset(sx / sum, sy / sum);
  }

  SkyBoss kingBoss(double age, {double width = 640}) =>
      arrivingBoss(age)..x = _anchorX(width);

  // Every look the plate has, with whether it runs under Reduced Motion.
  final barStates = <(String, SkyBoss Function(), bool)>[
    ('full', () => _fight(2.0), false),
    ('60%', () => _fight(2.0, hp: 84), false),
    ('hit', () => _fight(2.0, hp: 120, hitAgo: .04), false),
    ('chip', () => _fight(2.0, hp: 110, hitAgo: .35), false),
    ('puffed 0', () => _fight(8.4), false),
    ('puffed 1', () => _fight(8.6, puffDamage: 20, hitAgo: .06, setup: (b) => b.lastPuffHitAt = b.age - .06), false),
    ('puffed 2', () => _fight(9.3, puffDamage: 40), false),
    ('popped', () => _fight(9.0, puffDamage: 60, setup: (b) => b.poppedAt = b.age - .1), false),
    ('window closing', () => _fight(10.1), false),
    ('fury .05', () => _fight(2.0, hp: 70, furyAgo: .05), false),
    ('fury .2', () => _fight(2.0, hp: 70, furyAgo: .2), false),
    ('fury', () => _fight(2.0, hp: 60, furyAgo: 5), false),
    ('fury puffed', () => _fight(9.0, hp: 60, furyAgo: 30, puffDamage: 20), false),
    ('5%', () => _fight(2.0, hp: 7, furyAgo: 20), false),
    ('fill .1', () => _fight(.1), false),
    ('fill .3', () => _fight(.3), false),
    ('fill .5', () => _fight(.5), false),
    ('R full', () => _fight(2.0), true),
    ('R hit', () => _fight(2.0, hp: 120, hitAgo: .04), true),
    ('R puffed', () => _fight(8.4), true),
    ('R puffed 2', () => _fight(9.3, puffDamage: 40), true),
    ('R fury', () => _fight(2.0, hp: 60, furyAgo: 5), true),
    ('R 5%', () => _fight(2.0, hp: 7, furyAgo: 20), true),
  ];

  group('health plate', () {
    test('the strip and the track are where every other boss has them', () {
      for (final size in phones) {
        final u = math.min(size.height / 360, size.width / 640).clamp(.8, 1.3);
        final hud = math.min(size.width / 1000, size.height / 450);
        final w = math.min(460 * hud, size.width - 24);
        final expected = Rect.fromLTWH((size.width - w) / 2, 7 * u, w, 22 * u);
        final king = BossHealthBarArt.bounds(size, _fight(2));
        expect(king.left, closeTo(expected.left, .01), reason: '$size');
        expect(king.top, closeTo(expected.top, .01), reason: '$size');
        expect(king.width, closeTo(expected.width, .01), reason: '$size');
        expect(king.height, closeTo(expected.height, .01), reason: '$size');
        final baron = SkyBoss(number: 1, x: 1.5);
        expect(BossHealthBarArt.bounds(size, baron), king);
        expect(BossHealthBarArt.track(size, baron), BossHealthBarArt.track(size, _fight(2)));
      }
    });

    testWidgets('what the plate draws stays inside the screen and near its strip', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final size in phones) {
          final strip = BossHealthBarArt.bounds(size, _fight(2));
          final u = strip.height / 22;
          for (final (name, make, reduced) in barStates) {
            final bytes = await px(
              (c) => BossHealthBarArt.paint(c, size, make(), reducedMotion: reduced),
              size: size,
            );
            // The wings poke past the strip's ends by at most 15 u; nothing
            // reaches the screen's edge, and the tag hangs at most 17 u down.
            final box = Rect.fromLTRB(strip.left - 16 * u, 0, strip.right + 16 * u, strip.bottom + 17 * u);
            final outside = count(
              bytes,
              (r, g, b, a) => a > 200,
              w: size.width.round(),
              within: Rect.fromLTWH(0, 0, size.width, size.height),
            );
            final inside = count(
              bytes,
              (r, g, b, a) => a > 200,
              w: size.width.round(),
              within: box,
            );
            expect(inside, outside, reason: '$name at $size draws outside $box');
            expect(inside, greaterThan(500), reason: name);
          }
        }
      });
    });

    testWidgets('every state repeats exactly, in any order, with the caches emptied', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const size = Size(800, 360);
        Future<int> shot((String, SkyBoss Function(), bool) s) async => Object.hashAll(
          await px((c) => BossHealthBarArt.paint(c, size, s.$2(), reducedMotion: s.$3), size: size),
        );
        final forward = <String, int>{};
        for (final s in barStates) {
          forward[s.$1] = await shot(s);
          expect(await shot(s), forward[s.$1], reason: '${s.$1} repeats');
        }
        KingCooKit.clearCaches();
        for (final s in barStates.reversed) {
          expect(await shot(s), forward[s.$1], reason: '${s.$1} in another order');
          KingCooKit.clearCaches();
        }
      });
    });

    testWidgets('Reduced Motion holds still but every state still reads', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const size = Size(800, 360);
        Future<Uint8List> bar(SkyBoss b) =>
            px((c) => BossHealthBarArt.paint(c, size, b, reducedMotion: true), size: size);
        final calm = await bar(_fight(2.0));
        expect(await bar(_fight(2.9)), calm, reason: 'the calm plate is still');
        final fury = await bar(_fight(2.0, hp: 60, furyAgo: 5));
        expect(await bar(_fight(2.6, hp: 60, furyAgo: 5.6)), fury, reason: 'steady fury is still');
        final tagged = await bar(_fight(8.4));
        expect(await bar(_fight(8.9)), tagged, reason: 'the blue lamp holds until the whistle');
        expect(await bar(_fight(9.5)), isNot(equals(tagged)), reason: 'red from the whistle');
        expect(await bar(_fight(8.9, puffDamage: 20)), await bar(_fight(8.9, puffDamage: 20)));
        for (final (name, make, reduced) in barStates) {
          if (!reduced || name == 'R full') continue;
          expect(await bar(make()), isNot(equals(calm)), reason: '$name must stay distinguishable');
        }
        // The hit shudder and the flare of the onset are motion: gone.
        expect(KingCooHudArt.jolt(.05, 1, reduced: true), Offset.zero);
      });
    });

    test('the entrance fills the gauge from empty in .6 s after the cutscene', () {
      double share(SkyBoss b, {bool reduced = false}) => KingCooHudArt.gaugeHp(b, reduced: reduced) / b.maxHp;
      expect(share(_fight(0)), 0);
      expect(share(_fight(.3)), inExclusiveRange(.2, .8));
      expect(share(_fight(.6)), 1);
      expect(share(_fight(2)), 1);
      expect(share(_fight(0), reduced: true), 1);
      expect(share(_fight(.3, hp: 70)), lessThanOrEqualTo(.5 + 1e-9), reason: 'never past the real health');
      final dead = dyingBoss(.5);
      expect(share(dead), 0);
      // The sweep rides the same clock and is gone when the gauge is full.
      expect(KingCooHudArt.entrance(_fight(.3), reduced: false), inExclusiveRange(0, 1));
      expect(KingCooHudArt.entrance(_fight(.7), reduced: false), -1);
      expect(KingCooHudArt.entrance(_fight(.3), reduced: true), -1);
      expect(KingCooHudArt.surge(_fight(.3), reduced: false), greaterThan(.5));
      expect(KingCooHudArt.surge(_fight(2), reduced: false), 0);
    });

    testWidgets('the cutscenes hide the plate and the fight shows it', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final boss in [arrivingBoss(1.0), arrivingBoss(4.0), dyingBoss(.5)]) {
          expect(blank(await px((c) => BossHealthBarArt.paint(c, const Size(640, 360), boss))), isTrue);
        }
        expect(blank(await px((c) => BossHealthBarArt.paint(c, const Size(640, 360), _fight(2)))), isFalse);
      });
    });

    testWidgets('the gauge shows the health: more loaf, more pixels, a torn edge', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const size = Size(800, 360);
        final track = BossHealthBarArt.track(size, _fight(2));
        Future<int> loaf(int hp) async {
          final bytes = await px((c) => BossHealthBarArt.paint(c, size, _fight(2, hp: hp)), size: size);
          // Crust (golden, or siren-red toast in the fury): warm and bright
          // against the dark trough.
          return count(
            bytes,
            (r, g, b, a) => a > 200 && r > 190 && b < 150,
            w: 800,
            within: track,
          );
        }

        final full = await loaf(140), mostly = await loaf(100), half = await loaf(72), low = await loaf(30);
        expect(full, greaterThan(mostly));
        expect(mostly, greaterThan(half));
        expect(half, greaterThan(low));
        expect(low, greaterThan(40));
        expect(full, greaterThan(track.width * track.height * .45), reason: 'a full gauge is mostly loaf');
      });
    });

    testWidgets('the fury notch sits on the half mark, with the whistle over it', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const size = Size(800, 360);
        final track = BossHealthBarArt.track(size, _fight(2));
        final strip = BossHealthBarArt.bounds(size, _fight(2));
        final mid = track.left + track.width / 2;
        final bytes = await px((c) => BossHealthBarArt.paint(c, size, _fight(2)), size: size);
        // A brass column through the track at the middle.
        final column = count(
          bytes,
          (r, g, b, a) => a > 200 && r > 200 && g > 150 && b < 120,
          w: 800,
          within: Rect.fromLTRB(mid - .7, track.top, mid + .7, track.bottom),
        );
        expect(column, greaterThanOrEqualTo(8));
        // Silver over it, on the plate's top rim.
        final silver = count(
          bytes,
          (r, g, b, a) => a > 200 && r > 150 && g > 160 && b > 190 && (r - b).abs() < 70,
          w: 800,
          within: Rect.fromLTRB(mid - 6, strip.top - 4, mid + 6, track.top),
        );
        expect(silver, greaterThanOrEqualTo(6));
        // The onset: red and blue rays out of the notch, then a steady red light.
        final onset = await px((c) => BossHealthBarArt.paint(c, size, _fight(2, hp: 70, furyAgo: .15)), size: size);
        final steady = await px((c) => BossHealthBarArt.paint(c, size, _fight(2, hp: 70, furyAgo: 3)), size: size);
        final around = Rect.fromLTRB(mid - 18, strip.top - 6, mid + 18, strip.bottom + 6);
        expect(differing(onset, steady, w: 800, within: around), greaterThan(120));
        final blue = count(
          onset,
          (r, g, b, a) => a > 200 && b > 200 && r < 120 && g > 120,
          w: 800,
          within: around,
        );
        final white = count(
          onset,
          (r, g, b, a) => a > 200 && r > 245 && g > 235 && b > 190,
          w: 800,
          within: around,
        );
        expect(blue, greaterThan(20));
        expect(white, greaterThan(30));
      });
    });

    testWidgets('the medallion lamp follows his own siren, blue then red, steady in Reduced Motion', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const size = Size(640, 360);
        final strip = BossHealthBarArt.bounds(size, _fight(2));
        final crest = Rect.fromLTWH(strip.left, strip.top, 24, strip.height);
        Future<Uint8List> lamp(SkyBoss b, {bool reduced = false}) =>
            px((c) => BossHealthBarArt.paint(c, size, b, reducedMotion: reduced));
        final calm = await lamp(_fight(2.0));
        // Motion: the siren blinks at 3 Hz through the window.
        final a = await lamp(_fight(8.0)), b = await lamp(_fight(8.0 + 1 / 6));
        expect(differing(a, b, within: crest), greaterThan(8));
        expect(differing(a, calm, within: crest), greaterThan(8));
        // Reduced Motion: blue until the whistle, red from it.
        final blue = await lamp(_fight(8.4), reduced: true);
        final blueLater = await lamp(_fight(8.9), reduced: true);
        final red = await lamp(_fight(9.5), reduced: true);
        expect(differing(blue, blueLater, within: crest), lessThan(40), reason: 'steady until the whistle');
        expect(differing(blueLater, red, within: crest), greaterThan(8));
        expect(KingCooHudArt.siren(_fight(2.0), reduced: false), (0, 0.0));
        expect(KingCooHudArt.siren(_fight(8.4), reduced: true).$1, 2);
        expect(KingCooHudArt.siren(_fight(9.5), reduced: true).$1, 1);
        expect(KingCooHudArt.siren(dyingBoss(.5), reduced: false), (0, 0.0));
      });
    });

    testWidgets('the plate fits the budget: at most 60 ops in every state, no layer, no blur', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final report = StringBuffer();
        for (final size in [const Size(640, 360), const Size(800, 360)]) {
          for (final (name, make, reduced) in barStates) {
            final (canvas, built) = measure((c) => BossHealthBarArt.paint(c, size, make(), reducedMotion: reduced));
            report.writeln(
              '${name.padRight(15)} ${size.width.toInt()} ops ${canvas.draws.toString().padLeft(3)} '
              '(text ${canvas.paragraphs}) clips ${canvas.clips} built $built',
            );
            expect(canvas.draws, lessThanOrEqualTo(KingCooBudget.hud), reason: '$name at ${size.width}');
            expect(canvas.layers, 0, reason: '$name opens a layer');
            expect(canvas.blurs, 0, reason: '$name blurs');
            expect(built, 0, reason: '$name builds a shader on a warm frame');
            expect(canvas.counts.keys.where((k) => k.startsWith('UNFORWARDED')), isEmpty);
          }
        }
        // ignore: avoid_print
        print(report);
      });
    });

    testWidgets('a bad clock or a bad rectangle draws nothing and never throws', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final nan = _fight(2.0)..age = double.nan;
        expect(blank(await px((c) => BossHealthBarArt.paint(c, const Size(640, 360), nan))), isTrue);
        final inf = _fight(2.0)..age = double.infinity;
        expect(blank(await px((c) => BossHealthBarArt.paint(c, const Size(640, 360), inf))), isTrue);
        const bad = Rect.fromLTWH(double.nan, 0, 100, 22);
        const worse = Rect.fromLTWH(0, 0, double.infinity, 22);
        expect(
          blank(
            await px((c) {
              KingCooHudArt.frame(c, bad, 1, fury: false, defeated: false, wave: .5, flash: 0);
              KingCooHudArt.frame(c, worse, 1, fury: false, defeated: false, wave: .5, flash: 0);
              KingCooHudArt.crest(c, const Offset(double.nan, 5), 7, 1, fury: false);
              KingCooHudArt.crest(c, const Offset(5, 5), double.infinity, 1, fury: false);
              KingCooHudArt.track(c, bad, 1);
              KingCooHudArt.fill(c, bad, 50, 1, KingCooHudArt.crust, glow: 0, phase: 0, hotTip: true);
              KingCooHudArt.fill(c, const Rect.fromLTWH(0, 0, 100, 10), double.nan, 1, KingCooHudArt.crust, glow: 0, phase: 0, hotTip: true);
              KingCooHudArt.crumbs(c, bad, 50, 1, time: 1, fury: false, reduced: false);
              KingCooHudArt.crumbs(c, const Rect.fromLTWH(0, 0, 100, 10), 50, 1, time: double.nan, fury: false, reduced: false);
              KingCooHudArt.halfMark(c, bad, 1, above: true, fury: true, wave: .5, furyAge: .1);
              KingCooHudArt.chip(c, bad, heat: 1, alpha: 1);
              KingCooHudArt.puffedTag(c, bad, bad, 1, _fight(8.4), reduced: false);
              KingCooHudArt.badge(c, const Offset(double.nan, 0), 5);
              KingCooHudArt.lamp(c, const Offset(0, double.nan), 5);
            }),
          ),
          isTrue,
        );
        expect(KingCooHudArt.jolt(double.nan, 1, reduced: false), Offset.zero);
        expect(KingCooHudArt.jolt(.05, double.infinity, reduced: false), Offset.zero);
        expect(KingCooHudArt.gaugeHp(nan, reduced: false).isFinite, isTrue);
        expect(KingCooHudArt.siren(nan, reduced: false), (0, 0.0));
        expect(KingCooHudArt.tagState(nan, reduced: false).show, 0);
      });
    });
  });

  group('PUFFED x2 tag', () {
    test('it shows exactly while rocks count double, with a pip for every 20 health', () {
      ({double show, double pop, int pips}) state(SkyBoss b, {bool reduced = false}) =>
          KingCooHudArt.tagState(b, reduced: reduced);
      // Fluffed: no tag, in calm, in the lobs, in the fury.
      for (final c in [.5, 2.0, 5.0, 7.5, 12.0]) {
        expect(state(_fight(c)).show, 0, reason: 'combat $c');
      }
      expect(state(_fight(2, hp: 60, furyAgo: 5)).show, 0);
      // The window: 7.6 to 10.0, in every cycle.
      expect(state(_fight(7.59)).show, 0);
      expect(state(_fight(7.69)).show, inExclusiveRange(0, 1));
      for (final c in [7.9, 8.5, 9.2, 9.99]) {
        expect(state(_fight(c)).show, 1, reason: 'combat $c');
        expect(state(_fight(c, cycles: 1)).show, 1, reason: 'cycle 1 at $c');
        expect(state(_fight(c, fury: true)).show, 1, reason: 'fury at $c');
      }
      // Closing: it folds away over a quarter second.
      expect(state(_fight(10.1)).show, inExclusiveRange(0, 1));
      expect(state(_fight(10.3)).show, 0);
      // The pips: one for every 20 health the window has taken.
      for (final (damage, pips) in [(0, 0), (10, 0), (19, 0), (20, 1), (39, 1), (40, 2), (59, 2)]) {
        expect(state(_fight(9.0, puffDamage: damage)).pips, pips, reason: '$damage taken');
      }
      // The pop: all three, bursting away in .3 s; then nothing.
      final popped = _fight(9.0, puffDamage: 60, setup: (b) => b.poppedAt = b.age - .1);
      expect(state(popped).pips, 3);
      expect(state(popped).pop, closeTo(1 / 3, 1e-6));
      expect(state(popped).show, closeTo(2 / 3, 1e-6));
      expect(state(_fight(9.0, puffDamage: 60, setup: (b) => b.poppedAt = b.age - .4)).show, 0);
      // Not in a cutscene, not for anyone else.
      expect(state(arrivingBoss(3.0)).show, 0);
      expect(state(dyingBoss(.5)).show, 0);
      expect(state(SkyBoss(number: 5, x: 1.5, kind: BossKind.dragon, cinematic: true)..age = 8).show, 0);
      // Reduced Motion: there while the window is open, gone the moment it is not.
      expect(state(_fight(7.65), reduced: true).show, 1);
      expect(state(_fight(10.05), reduced: true).show, 0);
      expect(state(popped, reduced: true).show, 0);
      expect(state(_fight(9.0, puffDamage: 40), reduced: true).pips, 2);
    });

    testWidgets('its type is at least ten pixels and it is no wider than 130 at 640', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        expect(KingCooHudArt.tagType, greaterThanOrEqualTo(10));
        for (final size in phones) {
          final strip = BossHealthBarArt.bounds(size, _fight(2));
          final bar = BossHealthBarArt.track(size, _fight(2));
          final u = strip.height / 22;
          final box = KingCooHudArt.tagBox(strip, bar, u);
          expect(box.width, lessThanOrEqualTo(130 * u), reason: '$size');
          expect(box.width, lessThanOrEqualTo(KingCooHudArt.tagWidthMax * u), reason: '$size');
          expect(box.top, closeTo(strip.bottom - 1.2 * u, .01));
          expect(box.left, greaterThanOrEqualTo(strip.left));
          expect(box.right, lessThan(bar.center.dx + 8 * u), reason: 'left of the gauge\'s middle');
        }
        // The cream letters of PUFFED are at least 7 px tall (a 10.5 px type's
        // capitals) at 640 x 360, where one logical pixel is one pixel.
        const size = Size(640, 360);
        final strip = BossHealthBarArt.bounds(size, _fight(2));
        final bar = BossHealthBarArt.track(size, _fight(2));
        final box = KingCooHudArt.tagBox(strip, bar, 1);
        final bytes = await px((c) => BossHealthBarArt.paint(c, size, _fight(8.9), reducedMotion: true));
        final rows = <int>[];
        for (var y = box.top.floor(); y < box.bottom.ceil(); y++) {
          final n = count(
            bytes,
            (r, g, b, a) => a > 220 && r > 235 && g > 220 && b > 150 && b < 235,
            within: Rect.fromLTWH(box.left + 16, y.toDouble(), 46, 1),
          );
          if (n >= 2) rows.add(y);
        }
        expect(rows, isNotEmpty);
        expect(rows.last - rows.first + 1, greaterThanOrEqualTo(7), reason: 'capital height of the type');
      });
    });

    testWidgets('it never sits on him: no part of the figure is under it', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final size in phones) {
          final width = size.width, height = size.height;
          final strip = BossHealthBarArt.bounds(size, _fight(2));
          final bar = BossHealthBarArt.track(size, _fight(2));
          final box = KingCooHudArt.tagBox(strip, bar, strip.height / 22);
          // The whole figure at the moments of the window (it hovers lowest
          // there, but the cap hops at the whistle's blast), every cycle, hit
          // and not.
          for (final cycle in [0, 1, 2, 3]) {
            for (final combat in [7.7, 8.4, 9.0, 9.2, 9.3, 9.45, 9.9]) {
              for (final hit in [false, true]) {
                final b = cooBoss(combat: combat, cycles: cycle, setup: (b) {
                  if (hit) b.lastHitAt = b.age - .05;
                });
                final pose = poseOf(b, light: newYorkLight());
                final bytes = await px((c) {
                  // As the rules place him: x = max(birdX + .70, w/h - .55)
                  // heights, hovering .06 about the middle.
                  final at = Offset(
                    math.max(birdX + .70, width / height - .55) * height,
                    (.5 + .06 * math.sin(.9 * (b.age - b.arrivalDuration))) * height,
                  );
                  paintFigure(c, pose, at, height);
                }, size: size);
                final under = count(
                  bytes,
                  (r, g, b, a) => a > 200,
                  w: width.toInt(),
                  within: box.inflate(1),
                );
                expect(under, 0, reason: 'cycle $cycle combat $combat hit $hit at $width: ${under}px under the tag');
              }
            }
          }
        }
      });
    });

    testWidgets('the pips light one by one, and a landed rock makes the tag jump', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const size = Size(640, 360);
        final strip = BossHealthBarArt.bounds(size, _fight(2));
        final bar = BossHealthBarArt.track(size, _fight(2));
        final box = KingCooHudArt.tagBox(strip, bar, 1);
        final pips = Rect.fromLTRB(box.right - 24, box.top + 2, box.right - 2, box.bottom - 2);
        Future<Uint8List> shot(SkyBoss b) =>
            px((c) => BossHealthBarArt.paint(c, size, b, reducedMotion: true));
        int gold(Uint8List p) => count(p, (r, g, b, a) => a > 200 && r > 230 && g > 190 && b < 140, within: pips);
        final none = gold(await shot(_fight(9.0)));
        final one = gold(await shot(_fight(9.0, puffDamage: 20)));
        final two = gold(await shot(_fight(9.0, puffDamage: 40)));
        expect(one, greaterThan(none + 4));
        expect(two, greaterThan(one + 4));
        // Motion: a rock landing on the taut chest flashes the label's rim.
        final hit = await px(
          (c) => BossHealthBarArt.paint(
            c,
            size,
            _fight(9.0, hitAgo: .03, setup: (b) => b.lastPuffHitAt = b.age - .03),
          ),
        );
        final later = await px(
          (c) => BossHealthBarArt.paint(
            c,
            size,
            _fight(9.0, hitAgo: .5, setup: (b) => b.lastPuffHitAt = b.age - .5),
          ),
        );
        expect(differing(hit, later, within: box.inflate(3)), greaterThan(30));
      });
    });
  });

  group('name card', () {
    const size = Size(800, 360);
    Future<Uint8List> card(
      double age, {
      bool reduced = false,
      Size s = size,
      String? line = '“Nobody flies till the bread cart is found!”',
      double birdY = .5,
      bool useDefault = false,
    }) {
      final boss = kingBoss(age, width: s.width);
      return px((c) {
        final drew = KingCooEncounterUi.nameCard(
          c,
          s,
          boss,
          BossMotion(boss, reducedMotion: reduced),
          birdY: birdY,
          line: useDefault ? null : line,
        );
        expect(drew, isTrue, reason: 'the card is his own at $age');
      }, size: s);
    }

    test('the words are the guardian\'s, one word everywhere', () {
      final king = SkyBoss(number: 6, x: 1.5, kind: BossKind.kingCoo, cinematic: true);
      expect(KingCooEncounterUi.ribbonWord, 'GUARDIAN');
      expect(BossEncounterArt.nameCardEyebrow(king), KingCooEncounterUi.ribbonWord);
      expect(KingCooEncounterUi.ribbonWord, isNot(contains('ENCOUNTER')));
      expect(KingCooEncounterUi.ribbonWord, isNot(contains('MINI')));
      expect(king.name.toUpperCase(), 'KING COO');
      expect(king.title, 'COMMISSIONER OF THE CURB');
      expect(KingCooEncounterUi.entranceLine, '“Nobody flies till the bread cart is found!”');
      expect(Campaign.bossLine(Campaign.level('3-2')!), 'Nobody flies till the bread cart is found!');
      expect(KingCooEncounterUi.entranceLine, '“${Campaign.bossLine(Campaign.level('3-2')!)}”');
    });

    testWidgets('it waits for the COO!, holds, and folds shut', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        expect(KingCooEncounterUi.slamAt, KingCooTimeline.cardAt);
        expect(KingCooEncounterUi.slamAt, greaterThan(SkyBoss.roarAt), reason: 'after the shout');
        for (final reduced in [false, true]) {
          for (final age in [0.0, 1.0, 1.6, 2.2, 2.7, 2.84]) {
            expect(blank(await card(age, reduced: reduced)), isTrue, reason: '$age reduced $reduced');
          }
          for (final age in [2.95, 3.2, 3.6, 4.0, 4.15]) {
            expect(blank(await card(age, reduced: reduced)), isFalse, reason: '$age reduced $reduced');
          }
          expect(blank(await card(4.6, reduced: reduced)), isTrue);
          expect(blank(await card(5.0, reduced: reduced)), isTrue);
        }
      });
    });

    testWidgets('it repeats exactly, holds through the hold, and holds still in Reduced Motion', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final age in [2.9, 3.0, 3.2, 3.6, 4.1, 4.4]) {
          expect(await card(age), await card(age), reason: '$age');
          expect(await card(age, reduced: true), await card(age, reduced: true), reason: '$age reduced');
        }
        // (The lamp's glow is clipped under the film bars as they are drawn, and
        // they start to leave at 3.8 s: so the hold is judged while they are full.)
        expect(await card(3.5, reduced: true), await card(3.7, reduced: true));
        // The hold: only the lamp's flashing moves (red at 3.7, blue at 4.05).
        final a = await card(3.7), b = await card(4.05);
        final moved = differing(a, b, w: 800, tolerance: 90);
        expect(moved, lessThan(2600), reason: 'the hold is a hold: $moved');
        expect(differing(a, b, w: 800), greaterThan(0), reason: 'the siren is flashing');
      });
    });

    testWidgets('the name stamps in letter by letter, left to right', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        // Cream letter pixels over the plate, as the stamps land.
        int letters(Uint8List p) => count(p, (r, g, b, a) => a > 220 && r > 240 && g > 225 && b > 170 && b < 225, w: 800);
        final seen = <int>[];
        for (final t in [.12, .22, .32, .42, .52]) {
          seen.add(letters(await card(KingCooEncounterUi.slamAt + t, reduced: false, line: null, useDefault: true)));
        }
        for (var i = 1; i < seen.length; i++) {
          expect(seen[i], greaterThanOrEqualTo(seen[i - 1] - 10), reason: 'monotone: $seen');
        }
        expect(seen.last, greaterThan(seen.first + 120), reason: 'later stamps add letters: $seen');
        // Reduced Motion: every letter is there at once.
        final rm = letters(await card(KingCooEncounterUi.slamAt + .5, reduced: true, useDefault: true));
        expect(rm, greaterThan(seen.last * .8));
      });
    });

    testWidgets('it carries the campaign line; without one he says his own; the plate never changes', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        const age = 4.0;
        // (The bird flies low, out from behind the quote.)
        final mine = await card(age, useDefault: true, birdY: .92);
        final given = await card(age, birdY: .92);
        expect(mine, given, reason: 'his own line is the campaign\'s line');
        final other = await card(age, line: '“Bread! Bread! Bread!”', birdY: .92);
        final boss = kingBoss(age, width: 800);
        // The plate's rows are equal; the quote's rows are not.
        final plateBottom = 360 * .142 + 360 * .272;
        expect(differing(other, given, w: 800, within: Rect.fromLTWH(0, 0, 800, plateBottom)), 0);
        expect(differing(other, given, w: 800, within: Rect.fromLTWH(0, plateBottom, 800, 80)), greaterThan(150));
        expect(boss.age, age);
        // Under the plate, at most two lines, as wide as the plate.
        final quoteRows = count(given, (r, g, b, a) => a > 200 && r > 240 && g > 230 && b > 180, w: 800,
            within: Rect.fromLTWH(0, plateBottom, 800, 80));
        expect(quoteRows, greaterThan(200));
        final long = await card(age, line: '“${'Nobody flies till the bread cart is found! ' * 4}”', birdY: .92);
        var lowest = 0;
        for (var y = 359; y > 0; y--) {
          if (count(long, (r, g, b, a) => a > 120, w: 800, within: Rect.fromLTWH(0, y.toDouble(), 800, 1)) > 0) {
            lowest = y;
            break;
          }
        }
        expect(lowest, lessThan(360 * .142 + 360 * .272 + 52), reason: 'two lines at most');
      });
    });

    testWidgets('it keeps clear of his beak at every phone size, in every beat of the hold', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final s in phones) {
          final anchor = _anchorX(s.width) * s.height;
          // The beak tip juts 2.24 radii left of the chest, 2.5 with the head
          // thrown back for the COO!.
          final beak = anchor - 2.5 * s.height * SkyBoss.radius;
          for (final age in [2.95, 3.3, 3.8, 4.1]) {
            final bytes = await card(age, s: s);
            var right = 0;
            final w = s.width.round();
            for (var i = 3; i < bytes.length; i += 4) {
              if (bytes[i] > 100) right = math.max(right, (i ~/ 4) % w);
            }
            expect(right.toDouble(), lessThan(beak), reason: '$s at $age');
          }
        }
      });
    });

    testWidgets('the plate turns see-through where the bird flies behind it', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        Future<int> alphaAt(double birdY) async {
          final bytes = await card(4.0, birdY: birdY);
          // Plate between the stud and the ribbon, low on the card.
          var peak = 0;
          for (var y = 108; y < 112; y++) {
            for (var x = 74; x < 90; x++) {
              peak = math.max(peak, bytes[(y * 800 + x) * 4 + 3]);
            }
          }
          return peak;
        }

        final behind = await alphaAt(.3), away = await alphaAt(.85);
        expect(behind, lessThan(away), reason: '$behind vs $away');
        expect(behind, greaterThan(60), reason: 'still readable');
      });
    });

    testWidgets('a frame fits the budget: at most 60 ops, no layer, no blur', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final reduced in [false, true]) {
          for (final width in [640.0, 800.0]) {
            for (final age in [2.86, 2.9, 3.0, 3.1, 3.2, 3.4, 3.9, 4.3, 4.5]) {
              final boss = kingBoss(age, width: width);
              final (canvas, built) = measure(
                (c) => KingCooEncounterUi.nameCard(
                  c,
                  Size(width, 360),
                  boss,
                  BossMotion(boss, reducedMotion: reduced),
                  birdY: .5,
                  line: KingCooEncounterUi.entranceLine,
                ),
              );
              expect(canvas.draws, lessThanOrEqualTo(60), reason: '$age at $width reduced $reduced: ${canvas.draws}');
              expect(canvas.layers, 0);
              expect(canvas.blurs, 0);
              expect(built, 0, reason: '$age builds shaders');
            }
          }
        }
      });
    });

    testWidgets('a bad clock, size or bird height draws nothing and the card is still his', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final good = kingBoss(4.0);
        final bad = kingBoss(4.0)..age = double.nan;
        for (final (boss, s, y) in [
          (bad, const Size(640, 360), .5),
          (good, const Size(double.nan, 360), .5),
          (good, const Size(640, 360), double.nan),
        ]) {
          var drew = false;
          final bytes = await px((c) {
            drew = KingCooEncounterUi.nameCard(c, s, boss, BossMotion(boss, reducedMotion: false), birdY: y);
          });
          expect(drew, isTrue);
          expect(blank(bytes), isTrue);
        }
      });
    });
  });

  group('bursts', () {
    const at = Offset(442, 180);
    const h = 360.0;

    // Everything the staging paints for the defeat at [t] (0 to 1 over the
    // 1.3 s after the burst), in the order it paints it.
    void defeat(Canvas c, double t, {bool reduced = false}) {
      final k = t * 1.3;
      if (!reduced) KingCooEncounterUi.shockwave(c, at, h, k);
      KingCooEncounterUi.burst(c, at, h, t, reduced);
      KingCooEncounterUi.featherSnow(c, at, h, k, reduced: reduced);
      KingCooEncounterUi.victoryBadge(c, at, h, k, reduced: reduced);
    }

    final pieces = <(String, void Function(Canvas c, double t, bool reduced))>[
      ('hit', (c, t, r) => KingCooEncounterUi.hit(c, at, h, t, reduced: r)),
      ('hit x2', (c, t, r) => KingCooEncounterUi.hit(c, at, h, t, reduced: r, puffed: true)),
      ('fury', (c, t, r) => KingCooEncounterUi.furyBurst(c, at, h, t, reduced: r)),
      ('pop', (c, t, r) => KingCooEncounterUi.pop(c, at, h, t, reduced: r)),
      (
        'shout',
        (c, t, r) => KingCooEncounterUi.shout(c, const Offset(360, 100), h, shock: t, roar: math.sin(t * math.pi), reduced: r, chest: at),
      ),
      ('burst', (c, t, r) => KingCooEncounterUi.burst(c, at, h, t, r)),
      ('defeat', (c, t, r) => defeat(c, t, reduced: r)),
      ('snow', (c, t, r) => KingCooEncounterUi.featherSnow(c, at, h, 1.3 + t * 1.4, reduced: r)),
      ('badge', (c, t, r) => KingCooEncounterUi.victoryBadge(c, at, h, t * 2.2, reduced: r)),
    ];

    testWidgets('every piece repeats exactly, in any order', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final first = <String, int>{};
        for (final (name, draw) in pieces) {
          for (final reduced in [false, true]) {
            for (final t in [.05, .2, .45, .7, .95]) {
              final key = '$name $t $reduced';
              final a = Object.hashAll(await px((c) => draw(c, t, reduced)));
              expect(Object.hashAll(await px((c) => draw(c, t, reduced))), a, reason: key);
              first[key] = a;
            }
          }
        }
        KingCooKit.clearCaches();
        for (final (name, draw) in pieces.reversed) {
          for (final reduced in [true, false]) {
            for (final t in [.95, .7, .45, .2, .05]) {
              expect(Object.hashAll(await px((c) => draw(c, t, reduced))), first['$name $t $reduced'], reason: '$name $t $reduced in another order');
            }
          }
        }
      });
    });

    testWidgets('each piece fits the budget in every frame: a burst at most 80 ops, no layer, no blur', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final report = StringBuffer();
        for (final (name, draw) in pieces) {
          var worst = 0;
          for (final reduced in [false, true]) {
            for (var i = 0; i <= 50; i++) {
              final t = i / 51;
              final (canvas, built) = measure((c) => draw(c, t, reduced));
              worst = math.max(worst, canvas.draws);
              expect(canvas.draws, lessThanOrEqualTo(KingCooBudget.burst), reason: '$name at $t reduced $reduced');
              expect(canvas.layers, 0, reason: '$name opens a layer');
              expect(canvas.blurs, 0, reason: '$name blurs');
              expect(built, 0, reason: '$name builds a shader at $t');
              expect(canvas.counts.keys.where((k) => k.startsWith('UNFORWARDED')), isEmpty);
            }
          }
          report.writeln('${name.padRight(8)} worst frame $worst ops');
        }
        // ignore: avoid_print
        print(report);
      });
    });

    testWidgets('they begin and end on time and never before their cue', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        Future<bool> empty(void Function(Canvas c) draw) async => blank(await px(draw));
        // Hit, fury, pop and the burst end at t = 1; nothing before 0.
        for (final (name, draw) in pieces.take(4)) {
          expect(await empty((c) => draw(c, 1.0, false)), isTrue, reason: '$name ends');
          expect(await empty((c) => draw(c, 1.4, false)), isTrue, reason: '$name stays ended');
          expect(await empty((c) => draw(c, -.1, false)), isTrue, reason: '$name does not start early');
          expect(await empty((c) => draw(c, .3, false)), isFalse, reason: '$name draws');
        }
        expect(await empty((c) => KingCooEncounterUi.burst(c, at, h, -.2, false)), isTrue);
        expect(await empty((c) => KingCooEncounterUi.burst(c, at, h, 1.0, false)), isTrue);
        expect(await empty((c) => KingCooEncounterUi.burst(c, at, h, .3, false)), isFalse);
        // The snow is the burst's tail: nothing before it, nothing after 2.7 s.
        for (final k in [0.0, 1.0, 1.3, 2.7, 3.0]) {
          expect(await empty((c) => KingCooEncounterUi.featherSnow(c, at, h, k, reduced: false)), isTrue, reason: 'snow at $k');
        }
        expect(await empty((c) => KingCooEncounterUi.featherSnow(c, at, h, 2.0, reduced: false)), isFalse);
        expect(await empty((c) => KingCooEncounterUi.featherSnow(c, at, h, 2.0, reduced: true)), isTrue, reason: 'no snow in Reduced Motion');
        // The badge: shows from .10 s, is gone by 2.15 s.
        for (final k in [0.0, .1, 2.15, 2.5]) {
          expect(await empty((c) => KingCooEncounterUi.victoryBadge(c, at, h, k, reduced: false)), isTrue, reason: 'badge at $k');
        }
        for (final k in [.3, .8, 1.2, 1.6, 2.0]) {
          expect(await empty((c) => KingCooEncounterUi.victoryBadge(c, at, h, k, reduced: false)), isFalse, reason: 'badge at $k');
        }
        // A caller can fade the glow away early.
        expect(await empty((c) => KingCooEncounterUi.victoryBadge(c, at, h, 1.6, reduced: false, fade: 0)), isTrue);
        // The shout needs a shock or a roar.
        expect(
          await empty((c) => KingCooEncounterUi.shout(c, const Offset(360, 100), h, shock: 0, roar: 0, reduced: false)),
          isTrue,
        );
      });
    });

    testWidgets('Reduced Motion holds one frame in place and only fades', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        for (final (name, draw) in pieces.where((p) => ['hit', 'hit x2', 'fury', 'pop', 'burst'].contains(p.$1))) {
          final early = await px((c) => draw(c, .25, true));
          final late = await px((c) => draw(c, .6, true));
          final a = centroid(early), b = centroid(late);
          expect((a - b).distance, lessThan(1.5), reason: '$name does not move: $a vs $b');
          // What is left is what was there: nothing new appears.
          final fresh = count(late, (r, g, bl, al) => al > 40) - count(early, (r, g, bl, al) => al > 40);
          expect(fresh, lessThan(30), reason: '$name only fades');
        }
        // The badge hangs still where the glow will be, then the glow fades in and out.
        final hang = await px((c) => KingCooEncounterUi.victoryBadge(c, at, h, .6, reduced: true));
        final hang2 = await px((c) => KingCooEncounterUi.victoryBadge(c, at, h, .85, reduced: true));
        expect((centroid(hang) - centroid(hang2)).distance, lessThan(1.5));
        // No shock wave, no snow: only the held frame.
        expect(blank(await px((c) => KingCooEncounterUi.featherSnow(c, at, h, 2.0, reduced: true))), isTrue);
      });
    });

    testWidgets('a hit lands on the chest with a flash, and a hit on the taut chest is louder', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final plain = await px((c) => KingCooEncounterUi.hit(c, at, h, .12, reduced: false));
        final loud = await px((c) => KingCooEncounterUi.hit(c, at, h, .12, reduced: false, puffed: true));
        // White at the point of impact.
        int whiteAt(Uint8List p) => count(p, (r, g, b, a) => a > 220 && r > 240 && g > 240 && b > 220,
            within: Rect.fromCenter(center: at, width: 10, height: 10));
        expect(whiteAt(plain), greaterThan(20));
        expect(whiteAt(loud), greaterThan(20));
        // Gold, a bigger star and the x2: far more ink on the taut chest.
        int gold(Uint8List p) => count(p, (r, g, b, a) => a > 200 && r > 230 && g > 170 && b < 120);
        expect(gold(loud), greaterThan(gold(plain) + 250));
        // The x2 pops above the chest.
        final above = Rect.fromLTWH(at.dx - 40, at.dy - 60, 80, 40);
        expect(count(loud, (r, g, b, a) => a > 200 && r > 230 && g > 170 && b < 120, within: above), greaterThan(50));
        expect(count(plain, (r, g, b, a) => a > 200 && r > 230 && g > 170 && b < 120, within: above), lessThan(20));
      });
    });

    testWidgets('the fury goes off in red and blue; the shout is cream and brass and leftward', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final fury = await px((c) => KingCooEncounterUi.furyBurst(c, at, h, .2, reduced: false));
        expect(count(fury, (r, g, b, a) => a > 150 && r > 200 && g < 120 && b < 140), greaterThan(300));
        expect(count(fury, (r, g, b, a) => a > 150 && b > 200 && r < 130 && g > 110), greaterThan(150));
        const mouth = Offset(360, 100);
        final shout = await px((c) => KingCooEncounterUi.shout(c, mouth, h, shock: .4, roar: 1, reduced: false));
        // The word and the arcs are left of the beak; the sound is not aimed at the chest.
        final left = count(shout, (r, g, b, a) => a > 150, within: Rect.fromLTRB(0, 0, mouth.dx, 360));
        final right = count(shout, (r, g, b, a) => a > 150, within: Rect.fromLTRB(mouth.dx + 40, 0, 640, 360));
        expect(left, greaterThan(right));
        // The rings expand: the sound reaches further left as the shock grows
        // (with no word or arcs: roar 0).
        int leftmost(Uint8List p) {
          for (var x = 0; x < 640; x++) {
            if (count(p, (r, g, b, a) => a > 6, within: Rect.fromLTWH(x.toDouble(), 0, 1, 360)) > 0) return x;
          }
          return 640;
        }

        final small = await px((c) => KingCooEncounterUi.shout(c, mouth, h, shock: .15, roar: 0, reduced: false));
        final big = await px((c) => KingCooEncounterUi.shout(c, mouth, h, shock: .45, roar: 0, reduced: false));
        expect(leftmost(big), lessThan(leftmost(small) - 30));
      });
    });

    testWidgets('the defeat reads as a funny pillow: cream down, lilac and rosy feathers, crumbs, stars, sparkles', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final frame = await px((c) => defeat(c, .45));
        bool cloud(int r, int g, int b, int a) => a > 200 && r > 235 && g > 230 && b > 240;
        bool lilac(int r, int g, int b, int a) => a > 200 && (r - 157).abs() < 14 && (g - 154).abs() < 14 && (b - 198).abs() < 14;
        bool crumb(int r, int g, int b, int a) => a > 200 && r > 235 && g > 235 && b > 160 && b < 215;
        bool star(int r, int g, int b, int a) => a > 200 && r > 250 && g > 205 && g < 225 && b > 100 && b < 140;
        bool red(int r, int g, int b, int a) => a > 150 && r > 240 && g < 100 && b < 120;
        bool blue(int r, int g, int b, int a) => a > 150 && r < 100 && b > 240 && g > 150;
        expect(count(frame, cloud), greaterThan(1500), reason: 'the cloud of down');
        expect(count(frame, lilac), greaterThan(80), reason: 'plumage');
        expect(count(frame, crumb), greaterThan(25), reason: 'crumbs from the sack');
        expect(count(frame, star), greaterThan(25), reason: 'dizzy stars');
        expect(count(frame, red) + count(frame, blue), greaterThan(12), reason: 'siren sparkle');
        // A comic starburst first: white spikes beyond the cloud's own radius.
        final first = await px((c) => defeat(c, .1));
        expect(count(first, (r, g, b, a) => a > 200 && r > 245 && g > 245 && b > 235), greaterThan(300));
        // The badge rises from the burst and ends high, away from the title's middle.
        final early = await px((c) => KingCooEncounterUi.victoryBadge(c, at, h, .3, reduced: false));
        final late = await px((c) => KingCooEncounterUi.victoryBadge(c, at, h, 1.6, reduced: false));
        expect(centroid(late).dy, lessThan(centroid(early).dy - 40));
        expect(centroid(late).dy, lessThan(h * .3));
        // The glow keeps off the bird's column.
        expect(centroid(late).dx, greaterThan(FlightSimulation.birdX * h + 60));
      });
    });

    testWidgets('a bad input draws nothing and never throws', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final nan = double.nan, inf = double.infinity;
        const badAt = Offset(double.nan, 100);
        expect(
          blank(
            await px((c) {
              KingCooEncounterUi.hit(c, badAt, h, .3, reduced: false);
              KingCooEncounterUi.hit(c, at, nan, .3, reduced: false);
              KingCooEncounterUi.hit(c, at, h, nan, reduced: true, puffed: true);
              KingCooEncounterUi.furyBurst(c, badAt, h, .3, reduced: false);
              KingCooEncounterUi.furyBurst(c, at, h, inf, reduced: false);
              KingCooEncounterUi.pop(c, at, nan, .3, reduced: false);
              KingCooEncounterUi.pop(c, at, h, nan, reduced: false);
              KingCooEncounterUi.burst(c, badAt, h, .3, false);
              KingCooEncounterUi.burst(c, at, h, nan, true);
              KingCooEncounterUi.featherSnow(c, at, h, nan, reduced: false);
              KingCooEncounterUi.featherSnow(c, at, inf, 2, reduced: false);
              KingCooEncounterUi.shockwave(c, at, h, nan);
              KingCooEncounterUi.shockwave(c, badAt, h, .3);
              KingCooEncounterUi.victoryBadge(c, at, h, nan, reduced: false);
              KingCooEncounterUi.victoryBadge(c, badAt, h, 1, reduced: false);
              KingCooEncounterUi.victoryBadge(c, at, h, 1, reduced: false, fade: nan);
              KingCooEncounterUi.shout(c, badAt, h, shock: .3, roar: .5, reduced: false);
              KingCooEncounterUi.shout(c, at, h, shock: nan, roar: .5, reduced: false);
              KingCooEncounterUi.shout(c, at, h, shock: .3, roar: inf, reduced: false);
            }),
          ),
          isTrue,
        );
      });
    });
  });
}
