import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_head_art.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'king_coo_budget_test.dart' show Counting;
import 'king_coo_test_kit.dart';

/// K2: King Coo's face. REVIEW RENDERS (written to `build/king-coo-head-review/`,
/// or `--dart-define=KING_COO_HEAD_OUT=`) and the head's own contract checks.
const _out = String.fromEnvironment(
  'KING_COO_HEAD_OUT',
  defaultValue: 'build/king-coo-head-review',
);

/// The head's region in rig units at rest (cap, face, ruff, neck, whistle).
const _headBox = Rect.fromLTRB(-2.50, -2.78, -.10, -.55);

// A tone for the head-only renders (night light, nothing else).
const nightTone = KingCooTone(dark: .8, sky: Color(0xff8a70a8));

/// Every head part in the rig's order, without the body (for sweeps of the
/// art's own channels).
void _paintHead(Canvas c, KingCooHeadPose h) {
  KingCooHeadArt.neck(c, h);
  KingCooHeadArt.ruff(c, h);
  KingCooHeadArt.head(c, h);
  KingCooHeadArt.cap(c, h);
  KingCooHeadArt.whistle(c, h);
  KingCooHeadArt.steam(c, h);
}

/// The states whose faces the matrix must tell apart.
List<(String, KingCooPose)> _expressions({
  bool reduced = false,
  KingCooSkyLight light = KingCooSkyLight.neutral,
}) {
  KingCooPose at(SkyBoss b, {double lookY = 0}) =>
      poseOf(b, reduced: reduced, light: light, lookY: lookY);
  final blinkAt = () {
    var best = 1.2, bestBlink = 0.0;
    for (var t = 1.0; t < 7.0; t += .01) {
      final p = poseOf(cooBoss(combat: t));
      if (p.blink > bestBlink) {
        bestBlink = p.blink;
        best = t;
      }
    }
    return best;
  }();
  SkyBoss lob(double ago, {bool fury = false}) => cooBoss(
    combat: 1.0,
    fury: fury,
    setup: (b) => b.lobs.add(lobAt(b.age - ago, fury: fury)),
  );
  return [
    ('idle grump', at(cooBoss(combat: 1.2))),
    ('looks at the bird (up)', at(cooBoss(combat: 1.2), lookY: -.9)),
    ('looks at the bird (down)', at(cooBoss(combat: 1.2), lookY: .9)),
    ('wind-up: hold (squint)', at(lob(.7))),
    ('puff: inhale', at(cooBoss(combat: 8.2))),
    ('whistle raised', at(cooBoss(combat: 8.9))),
    ('whistle blown', at(cooBoss(combat: 9.3))),
    (
      'hit: wince',
      at(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .09)),
    ),
    ('fury glare', at(cooBoss(combat: 1.2, fury: true))),
    (
      'fury + hit',
      at(
        cooBoss(
          combat: 1.2,
          fury: true,
          setup: (b) => b.lastHitAt = b.age - .09,
        ),
      ),
    ),
    (
      'POP: dizzy',
      at(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .45)),
    ),
    ('blink', at(cooBoss(combat: blinkAt))),
    ('COO! (beak wide)', at(arrivingBoss(3.0))),
    ('defeat: inflating', at(dyingBoss(.62))),
    (
      'story: happy',
      KingCooPose.story(KingCooMood.happy, talk: .6, light: light),
    ),
    (
      'story: beaten',
      KingCooPose.story(KingCooMood.sad, beaten: true, light: light),
    ),
  ];
}

/// [pose] over a backdrop, cropped to [box] (rig units, chest at the origin)
/// and painted at [ppu] pixels per unit, as the game frames him at 640x360.
void _crop(
  Canvas c,
  KingCooPose pose,
  Rect box,
  double ppu, {
  WorldRegion region = WorldRegion.newYork,
  bool silhouette = false,
  double seconds = 12,
}) {
  final boss = bossAnchor(640);
  final zoom = ppu / 41.4;
  c.save();
  c.clipRect(Rect.fromLTWH(0, 0, box.width * ppu, box.height * ppu));
  c.scale(zoom);
  c.translate(-(boss.dx + box.left * 41.4), -(boss.dy + box.top * 41.4));
  nyFrame(
    c,
    640,
    pose: pose,
    bird: false,
    region: region,
    silhouette: silhouette,
    seconds: seconds,
  );
  c.restore();
}

// ------------------------------------------------------------------ helpers --

const _ink = KingCooPalette.ink;

const _headParts = {'neck', 'ruff', 'head', 'cap', 'whistle', 'steam'};

/// The head parts of [pose] as RGBA, [ppu] pixels per rig unit, rig origin at
/// pixel ([ox], [oy]).
Future<Uint8List> _headPixels(
  KingCooPose pose, {
  double ppu = 60,
  int w = 360,
  int h = 300,
  double ox = 210,
  double oy = 250,
  Set<String>? only,
}) => rawPixels(w, h, (c) {
  c.translate(ox, oy);
  c.scale(ppu);
  KingCooBossRig.paintPose(c, pose, only: only ?? _headParts);
});

/// The pixel at rig point [p] for a [_headPixels] render.
({int r, int g, int b, int a}) _at(
  Uint8List px,
  Offset p, {
  double ppu = 60,
  int w = 360,
  double ox = 210,
  double oy = 250,
}) {
  final x = (ox + p.dx * ppu).floor(), y = (oy + p.dy * ppu).floor();
  final i = (y * w + x) * 4;
  return (r: px[i], g: px[i + 1], b: px[i + 2], a: px[i + 3]);
}

/// Whether a solid pixel with [test] lies within [radius] rig units of [p].
bool _near(
  Uint8List px,
  Offset p,
  double radius,
  bool Function(int r, int g, int b, int a) test, {
  double ppu = 60,
  int w = 360,
  double ox = 210,
  double oy = 250,
}) {
  final n = (radius * ppu).ceil();
  for (var dy = -n; dy <= n; dy++) {
    for (var dx = -n; dx <= n; dx++) {
      if (dx * dx + dy * dy > n * n) continue;
      final x = (ox + p.dx * ppu).floor() + dx,
          y = (oy + p.dy * ppu).floor() + dy;
      if (x < 0 || y < 0 || x >= w || y >= 300) continue;
      final i = (y * w + x) * 4;
      if (test(px[i], px[i + 1], px[i + 2], px[i + 3])) return true;
    }
  }
  return false;
}

bool _orange(int r, int g, int b, int a) =>
    a > 200 && r > 190 && g > 50 && g < 210 && b < 120;
bool _solid(int r, int g, int b, int a) => a > 200;

/// How many pixels of a crop differ visibly between two renders.
int _differ(
  Uint8List a,
  Uint8List b, {
  Rect? region,
  double ppu = 60,
  int w = 360,
  int h = 300,
  double ox = 210,
  double oy = 250,
}) {
  var n = 0;
  final x0 = region == null ? 0 : (ox + region.left * ppu).floor();
  final x1 = region == null ? w : (ox + region.right * ppu).ceil();
  final y0 = region == null ? 0 : (oy + region.top * ppu).floor();
  final y1 = region == null ? h : (oy + region.bottom * ppu).ceil();
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = (y * w + x) * 4;
      var d = 0;
      for (var k = 0; k < 4; k++) {
        d = math.max(d, (a[i + k] - b[i + k]).abs());
      }
      if (d > 48) n++;
    }
  }
  return n;
}

/// The head's own channels, to draw without the solver (head frame at rest).
KingCooHeadPose _face({
  double beak = 0,
  double cheek = 0,
  double squint = 0,
  double anger = 0,
  double worry = 0,
  double dizzy = 0,
  double blink = 0,
  double wince = 0,
  double fury = 0,
  double lookX = 0,
  double lookY = 0,
}) => KingCooHeadPose(
  beak: beak,
  cheek: cheek,
  squint: squint,
  anger: anger,
  worry: worry,
  dizzy: dizzy,
  blink: blink,
  wince: wince,
  fury: fury,
  lookX: lookX,
  lookY: lookY,
  tone: KingCooTone(fury: fury, dark: .8, sky: const Color(0xff8a70a8)),
);

Future<Uint8List> _faceRender(KingCooHeadPose h, {double ppu = 60}) =>
    rawPixels(360, 300, (c) {
      c.translate(210, 250);
      c.scale(ppu);
      c.translate(1.1, 1.3); // the head to the middle of the picture
      _paintHead(c, h);
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('review renders', () {
    testWidgets(
      'close-ups at 6x on night and day, the expression sheets, strips',
      (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          final night = newYorkLight();
          final day = regionLight(WorldRegion.egypt);

          // -------- 6x close-ups of the idle head, night and day --------
          const zoom = 6 * 41.4;
          final w = (_headBox.width * zoom).round(),
              h = (_headBox.height * zoom).round();
          await savePng('closeup-night', w, h, (c) {
            _crop(
              c,
              poseOf(cooBoss(combat: 1.2), light: night),
              _headBox,
              zoom,
            );
          }, dir: _out);
          await savePng('closeup-day', w, h, (c) {
            _crop(
              c,
              poseOf(cooBoss(combat: 1.2), light: day),
              _headBox,
              zoom,
              region: WorldRegion.egypt,
            );
          }, dir: _out);

          // -------- the expression sheets --------
          Future<void> sheet(
            String name,
            double ppu,
            int scale,
            KingCooSkyLight light, {
            bool reduced = false,
            WorldRegion region = WorldRegion.newYork,
          }) async {
            final poses = _expressions(reduced: reduced, light: light);
            const cols = 4;
            final box = Rect.fromLTRB(-2.55, -2.80, .15, -.40);
            final cw = (box.width * ppu).round(),
                ch = (box.height * ppu).round();
            final rows = (poses.length / cols).ceil();
            final images = <ui.Image>[];
            for (final (_, pose) in poses) {
              images.add(
                await render(
                  cw,
                  ch,
                  (c) => _crop(c, pose, box, ppu, region: region),
                ),
              );
            }
            await savePng(
              name,
              cw * cols * scale,
              (ch + 0) * rows * scale + 0,
              (c) {
                for (var i = 0; i < poses.length; i++) {
                  final x = (i % cols) * cw.toDouble() * scale;
                  final y = (i ~/ cols) * ch.toDouble() * scale;
                  c.save();
                  c.translate(x, y);
                  c.scale(scale.toDouble());
                  c.drawImage(
                    images[i],
                    Offset.zero,
                    Paint()..filterQuality = FilterQuality.none,
                  );
                  c.restore();
                  c.drawRect(
                    Rect.fromLTWH(x, y, cw * scale.toDouble(), 18),
                    Paint()..color = const Color(0xaa0c0a24),
                  );
                  label(
                    c,
                    poses[i].$1,
                    Offset(x + 4, y + 1),
                    color: const Color(0xffffffff),
                    size: 12,
                  );
                }
              },
              dir: _out,
            );
            for (final i in images) {
              i.dispose();
            }
          }

          await sheet('expressions-250', 41.4 * 1.5, 1, night);
          await sheet('expressions-120', 19.0, 3, night);
          await sheet(
            'expressions-120-day',
            19.0,
            3,
            day,
            region: WorldRegion.egypt,
          );
          await sheet('expressions-rm', 41.4, 1, night, reduced: true);
        });
      },
    );

    testWidgets('the gape sweep, cap and siren, whistle, neck', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final night = newYorkLight();
        // -------- the gape: 0 .. 1 in five steps (the lower mandible drops) --------
        {
          const ppu = 41.4 * 4;
          const box = Rect.fromLTRB(-2.60, -2.85, -.35, -.75);
          final cw = (box.width * ppu).round(), ch = (box.height * ppu).round();
          const steps = [0.0, .25, .5, .75, 1.0];
          await savePng('gape-sweep', cw * steps.length ~/ 2, ch, (c) {
            c.drawRect(
              Rect.fromLTWH(0, 0, cw * steps.length / 2, ch.toDouble()),
              Paint()..color = const Color(0xffd8cfe6),
            );
            for (var i = 0; i < steps.length; i++) {
              c.save();
              c.translate(cw / 2 * i, 0);
              c.scale(.5);
              c.translate(-box.left * ppu, -box.top * ppu);
              c.scale(ppu);
              _paintHead(c, KingCooHeadPose(beak: steps[i], tone: nightTone));
              c.restore();
            }
          }, dir: _out);
        }

        // -------- cap and siren states, and the whistle, at 6x --------
        Future<void> strip(
          String name,
          List<(String, KingCooPose)> poses,
          Rect box,
          double zoom,
        ) async {
          final cw = (box.width * zoom).round(),
              ch = (box.height * zoom).round();
          await savePng(name, cw * poses.length, ch, (c) {
            for (var i = 0; i < poses.length; i++) {
              c.save();
              c.translate(cw * i.toDouble(), 0);
              _crop(c, poses[i].$2, box, zoom);
              c.restore();
              label(
                c,
                poses[i].$1,
                Offset(cw * i + 4.0, 2),
                color: const Color(0xffffffff),
                size: 12,
              );
            }
          }, dir: _out);
        }

        KingCooPose p(SkyBoss b, {bool rm = false}) =>
            poseOf(b, reduced: rm, light: night);
        await strip(
          'cap-strip',
          [
            ('idle', p(cooBoss(combat: 1.2))),
            ('siren red', p(cooBoss(combat: 9.1))),
            ('siren blue', p(cooBoss(combat: 8.1))),
            (
              'hit',
              p(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .09)),
            ),
            ('fury cocked', p(cooBoss(combat: 1.2, fury: true))),
            (
              'pop: cap flies',
              p(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .4)),
            ),
          ],
          const Rect.fromLTRB(-2.05, -2.95, -.25, -1.45),
          41.4 * 5,
        );
        await strip(
          'whistle-strip',
          [
            ('hanging', p(cooBoss(combat: 1.2))),
            ('rising', p(cooBoss(combat: 8.7))),
            ('in the beak', p(cooBoss(combat: 9.0))),
            ('blast', p(cooBoss(combat: 9.3))),
          ],
          const Rect.fromLTRB(-2.55, -2.15, -.2, .05),
          41.4 * 3.3,
        );
        await strip(
          'faces-5x',
          [
            ('COO!', p(arrivingBoss(3.05))),
            ('fury', p(cooBoss(combat: 1.2, fury: true))),
            (
              'fury + hit',
              p(
                cooBoss(
                  combat: 1.2,
                  fury: true,
                  setup: (b) => b.lastHitAt = b.age - .09,
                ),
              ),
            ),
            (
              'POP',
              p(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .45)),
            ),
            (
              'wind-up hold',
              p(
                cooBoss(
                  combat: 1.0,
                  setup: (b) => b.lobs.add(lobAt(b.age - .7)),
                ),
              ),
            ),
          ],
          const Rect.fromLTRB(-2.85, -3.25, -.05, -.75),
          41.4 * 2.8,
        );
        await strip(
          'story-strip',
          [
            for (final (name, m, beaten) in const [
              ('plain', KingCooMood.plain, false),
              ('happy', KingCooMood.happy, false),
              ('surprised', KingCooMood.surprised, false),
              ('angry', KingCooMood.angry, false),
              ('sad', KingCooMood.sad, false),
              ('beaten', KingCooMood.sad, true),
            ])
              (
                name,
                KingCooPose.story(
                  m,
                  beaten: beaten,
                  talk: name == 'happy' ? .4 : 0,
                  light: night,
                ),
              ),
          ],
          const Rect.fromLTRB(-2.55, -2.95, -.05, -.55),
          41.4 * 2.6,
        );
        await strip(
          'neck-strip',
          [
            ('idle', p(cooBoss(combat: 1.2))),
            ('inhale: head rears', p(cooBoss(combat: 8.4))),
            ('thrust', p(cooBoss(combat: 1.2 + .30))),
            (
              'hit: head snaps back',
              p(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .06)),
            ),
            ('defeat', p(dyingBoss(.62))),
          ],
          const Rect.fromLTRB(-2.45, -2.3, .35, -.35),
          41.4 * 3.2,
        );
      });
    });

    testWidgets('head silhouettes at 250 px and 120 px', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final poses = <(String, KingCooPose)>[
          ('rest', KingCooPose.still),
          (
            'wind-up hold',
            poseOf(
              cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .7))),
            ),
          ),
          ('inhale', poseOf(cooBoss(combat: 8.2))),
          ('whistle', poseOf(cooBoss(combat: 9.3))),
          ('fury', poseOf(cooBoss(combat: 1.2, fury: true))),
          (
            'hit',
            poseOf(
              cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .09),
            ),
          ),
          ('COO!', poseOf(arrivingBoss(3.0))),
          (
            'pop',
            poseOf(
              cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .45),
            ),
          ),
        ];
        for (final (name, ppu) in const [
          ('silhouette-head-250', 41.4),
          ('silhouette-head-120', 19.0),
        ]) {
          const box = Rect.fromLTRB(-3.0, -3.3, .3, -.3);
          final cw = (box.width * ppu).round(), ch = (box.height * ppu).round();
          final images = <ui.Image>[];
          for (final (_, pose) in poses) {
            images.add(
              await silhouetteImage(
                pose,
                ppu: ppu,
                w: cw,
                h: ch,
                origin: Offset(-box.left * ppu, -box.top * ppu),
                only: {..._headParts, 'chest', 'torso'},
              ),
            );
          }
          await savePng(name, cw * poses.length, ch, (c) {
            c.drawRect(
              Rect.fromLTWH(0, 0, cw * poses.length.toDouble(), ch.toDouble()),
              Paint()..color = const Color(0xffd9d2ea),
            );
            for (var i = 0; i < poses.length; i++) {
              c.drawImage(images[i], Offset(cw * i.toDouble(), 0), Paint());
              label(
                c,
                poses[i].$1,
                Offset(cw * i + 4.0, 2),
                size: ppu > 30 ? 13 : 9,
              );
            }
          }, dir: _out);
          for (final i in images) {
            i.dispose();
          }
        }
      });
    });

    testWidgets(
      'skin mode: the pieces laid as one creature beside the standalone head',
      (tester) async {
        await tester.runAsync(() async {
          await loadFonts();
          final night = newYorkLight();
          final pose = poseOf(cooBoss(combat: 1.2), light: night);
          final hp = KingCooHeadPose.of(pose);
          const ppu = 41.4 * 4;
          const box = Rect.fromLTRB(-2.55, -2.85, -.15, -.45);
          final cw = (box.width * ppu).round(), ch = (box.height * ppu).round();
          await savePng('skin-mode', cw * 2 ~/ 1, ch, (c) {
            c.drawRect(
              Rect.fromLTWH(0, 0, cw * 2.0, ch.toDouble()),
              Paint()..color = const Color(0xff5a4f7c),
            );
            for (final skin in [false, true]) {
              c.save();
              c.translate(skin ? cw.toDouble() : 0, 0);
              c.translate(-box.left * ppu, -box.top * ppu);
              c.scale(ppu);
              // A chest globe behind so the joints have something to meet.
              c.drawCircle(
                Offset.zero,
                .84,
                Paint()..color = const Color(0xffd8bdd0),
              );
              c.drawCircle(
                Offset.zero,
                .84,
                Paint()
                  ..color = _ink
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = .1,
              );
              if (!skin) {
                KingCooHeadArt.neck(c, hp);
                KingCooHeadArt.ruff(c, hp);
                KingCooHeadArt.head(c, hp);
                KingCooHeadArt.cap(c, hp);
                KingCooHeadArt.whistle(c, hp);
              } else {
                final neck = KingCooHeadArt.neckOf(hp);
                final trunk = Path()
                  ..addPath(neck.path, Offset.zero)
                  ..addPath(KingCooHeadArt.skullAt(hp), Offset.zero);
                // One outline under one skin: the ink is stroked first, the fills bury
                // every stroke that lies inside the union.
                KingCooKit.inkHero(c, trunk, .18);
                KingCooHeadArt.under(c, hp);
                c.drawPath(trunk, Paint()..color = const Color(0xff9d9ac6));
                KingCooHeadArt.neckFill(c, hp, geometry: neck);
                KingCooHeadArt.neckDetails(c, hp, geometry: neck);
                KingCooHeadArt.ruff(c, hp);
                KingCooHeadArt.skullFill(c, hp);
                KingCooHeadArt.skullDetails(c, hp);
                KingCooHeadArt.face(c, hp);
              }
              c.restore();
            }
          }, dir: _out);
        });
      },
    );

    testWidgets('frames at 640 and 800 over New York at night', (tester) async {
      await tester.runAsync(() async {
        await loadFonts();
        final night = newYorkLight();
        final states = <(String, KingCooPose, int)>[
          ('idle', poseOf(cooBoss(combat: 1.2), light: night), 0),
          (
            'puff: whistle in the beak',
            poseOf(cooBoss(combat: 9.0), light: night),
            0,
          ),
          (
            'fury + hit',
            poseOf(
              cooBoss(
                combat: 1.2,
                fury: true,
                setup: (b) => b.lastHitAt = b.age - .09,
              ),
              light: night,
            ),
            0,
          ),
          ('COO!', poseOf(arrivingBoss(3.0), light: night), 0),
        ];
        for (final width in [640, 800]) {
          await savePng('frames-$width', width * 2, 360 * 2, (c) {
            for (var i = 0; i < states.length; i++) {
              c.save();
              c.translate((i % 2) * width.toDouble(), (i ~/ 2) * 360.0);
              nyFrame(c, width.toDouble(), pose: states[i].$2);
              c.restore();
              label(
                c,
                '${states[i].$1} @ $width',
                Offset((i % 2) * width + 6.0, (i ~/ 2) * 360 + 4.0),
                color: const Color(0xffffffff),
              );
            }
          }, dir: _out);
        }
      });
    });
  });

  // ======================================================== the contract ==

  group('anchors land on the pixels', () {
    testWidgets('eye, beak tip, mouth, cap, siren, whistle in every head state', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final states = <(String, KingCooPose)>[
          ('rest', KingCooPose.still),
          ('hover', poseOf(cooBoss(combat: 2.0))),
          (
            'wind-up hold',
            poseOf(
              cooBoss(combat: 1.0, setup: (b) => b.lobs.add(lobAt(b.age - .7))),
            ),
          ),
          ('inhale', poseOf(cooBoss(combat: 8.2))),
          ('whistle in the beak', poseOf(cooBoss(combat: 9.0))),
          ('blast', poseOf(cooBoss(combat: 9.3))),
          ('fury', poseOf(cooBoss(combat: 1.2, fury: true))),
          ('COO!', poseOf(arrivingBoss(3.0))),
          (
            'hit',
            poseOf(
              cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .09),
            ),
          ),
          (
            'pop',
            poseOf(
              cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .45),
            ),
          ),
        ];
        final bad = <String>[];
        for (final (name, pose) in states) {
          final px = await _headPixels(pose);
          void want(
            String what,
            Offset p,
            double radius,
            bool Function(int, int, int, int) test,
          ) {
            if (!_near(px, p, radius, test)) {
              bad.add(
                '$name: $what at (${p.dx.toStringAsFixed(2)},${p.dy.toStringAsFixed(2)}) has no matching pixel within $radius',
              );
            }
          }

          // The eye: amber iris when the lids leave it open, else any solid.
          final shut = pose.dizzy > .5 || pose.blink > .5 || pose.squint > .5;
          want('eye', KingCooBossRig.eyeAt(pose), .14, shut ? _solid : _orange);
          // The beak tip is on the coral beak (or its ink).
          want('beak tip', KingCooBossRig.beakAt(pose), .10, _solid);
          want('mouth', KingCooBossRig.mouthAt(pose), .06, _solid);
          if (!pose.capOff) {
            want(
              'cap seat',
              KingCooBossRig.capAt(pose).at,
              .08,
              (r, g, b, a) => a > 200 && b > r + 15,
            );
            final s = KingCooBossRig.sirenAt(pose);
            want('siren', s, .08, (r, g, b, a) => a > 200);
          }
          want('whistle', KingCooBossRig.whistleAt(pose), .10, _solid);
        }
        expect(bad, isEmpty);
      });
    });

    testWidgets(
      'the siren anchor is on the lit dome: red, blue or a dim lamp within 0.07 of it',
      (tester) async {
        await tester.runAsync(() async {
          for (final (t, colour) in const [
            (9.3, 'red'),
            (8.1, 'blue'),
            (1.2, 'off'),
          ]) {
            final pose = poseOf(cooBoss(combat: t), reduced: true);
            final px = await _headPixels(pose);
            final anchor = KingCooBossRig.sirenAt(pose);
            final ok = switch (colour) {
              'red' => _near(
                px,
                anchor,
                .07,
                (r, g, b, a) => a > 200 && r > b + 60 && r > 180,
              ),
              'blue' => _near(
                px,
                anchor,
                .07,
                (r, g, b, a) => a > 200 && b > r + 60 && b > 180,
              ),
              _ => _near(
                px,
                anchor,
                .07,
                (r, g, b, a) => a > 200 && r > b + 25 && r > 60 && r < 200,
              ),
            };
            expect(
              ok,
              isTrue,
              reason: 'the $colour dome is at the siren anchor',
            );
          }
        });
      },
    );
  });

  group('the beak opens the right way', () {
    test('the lower mandible drops and the upper lifts as the gape grows', () {
      var lastLow = -99.0, lastUp = 99.0;
      for (var i = 0; i <= 10; i++) {
        final h = KingCooHeadPose(beak: i / 10);
        final low = KingCooHeadArt.jawAt(h).getBounds().bottom;
        final up = KingCooHeadArt.beakAt(h).getBounds().top;
        expect(
          low,
          greaterThanOrEqualTo(lastLow - 1e-9),
          reason: 'the chin only goes down (gape ${i / 10})',
        );
        expect(
          up,
          lessThanOrEqualTo(lastUp + 1e-9),
          reason: 'the upper mandible only lifts',
        );
        lastLow = low;
        lastUp = up;
      }
      final shut = KingCooHeadArt.jawAt(const KingCooHeadPose()).getBounds();
      final wide = KingCooHeadArt.jawAt(
        const KingCooHeadPose(beak: 1),
      ).getBounds();
      expect(
        wide.bottom - shut.bottom,
        greaterThan(.15),
        reason:
            'a full gape drops the chin by at least .15 unit (6 px at 41 px per unit)',
      );
      // The lower tip ends below the upper one at full gape: a real opening.
      final lowTip = KingCooHeadArt.point(
        const KingCooHeadPose(beak: 1),
        const Offset(-.96, .10),
      );
      expect(wide.bottom, greaterThan(lowTip.dy - .5));
    });

    testWidgets(
      'pixels: a full gape puts the lower beak below where it was shut',
      (tester) async {
        await tester.runAsync(() async {
          final shut = await _faceRender(_face());
          final wide = await _faceRender(_face(beak: 1));
          // Below the beak, at the lower mandible's reach: solid pixels appear
          // only when it drops.
          const probe = Rect.fromLTRB(
            -2.1,
            -1.35,
            -1.75,
            -1.05,
          ); // rig units at rest
          int solidIn(Uint8List px) {
            var n = 0;
            for (
              var y = (250 + (probe.top + 1.3) * 60).floor();
              y < (250 + (probe.bottom + 1.3) * 60).ceil();
              y++
            ) {
              for (
                var x = (210 + (probe.left + 1.1) * 60).floor();
                x < (210 + (probe.right + 1.1) * 60).ceil();
                x++
              ) {
                if (px[(y * 360 + x) * 4 + 3] > 200) n++;
              }
            }
            return n;
          }

          expect(solidIn(wide), greaterThan(solidIn(shut) + 40));
        });
      },
    );
  });

  group('the expression matrix reads', () {
    testWidgets(
      'idle grump, squint, wince, fury, worry, X eyes, blink, COO!, grin: every pair differs',
      (tester) async {
        await tester.runAsync(() async {
          final faces = <(String, KingCooHeadPose)>[
            ('idle grump', _face()),
            ('squint (wind-up hold)', _face(squint: .25, cheek: .35, beak: .1)),
            ('wince (hit)', _face(squint: 1, worry: .3, beak: .35, wince: 1)),
            ('fury', _face(anger: 1, squint: .3, fury: 1, beak: .12)),
            ('worry (pop, beaten)', _face(worry: 1)),
            ('X eyes (dizzy)', _face(dizzy: 1, worry: .6, beak: .5)),
            ('blink', _face(blink: 1)),
            ('COO!', _face(beak: 1, anger: .55)),
            ('grin', _face(squint: .45, cheek: .35, beak: .22)),
            ('puffed cheeks (whistle)', _face(cheek: 1, beak: .14)),
          ];
          // The face box (head frame at 19 px per unit: what a player sees at 120 px).
          final px = <Uint8List>[];
          for (final (_, h) in faces) {
            px.add(await _faceRender(h, ppu: 19));
          }
          const box = Rect.fromLTRB(-1.3, -.75, .7, .75);
          // In the picture the head sits at rig (0,0)+(-.04,-.28): shift the box.
          final region = box.shift(const Offset(-1.14 + 1.1, -1.58 + 1.3));
          final report = StringBuffer(
            'expression difference (pixels at 120 px, of ${(box.width * 19 * box.height * 19).round()}):\n',
          );
          var worst = 99999;
          String worstPair = '';
          for (var i = 0; i < faces.length; i++) {
            for (var j = i + 1; j < faces.length; j++) {
              final d = _differ(px[i], px[j], region: region, ppu: 19);
              report.writeln('${faces[i].$1} / ${faces[j].$1}: $d');
              if (d < worst) {
                worst = d;
                worstPair = '${faces[i].$1} / ${faces[j].$1}';
              }
            }
          }
          // ignore: avoid_print
          print('$report\nworst pair: $worstPair = $worst');
          expect(
            worst,
            greaterThan(25),
            reason:
                'every pair of expressions differs by 25+ pixels at 120 px ($worstPair)',
          );
        });
      },
    );

    testWidgets(
      'the real states differ: idle, wind-up, hit, fury, pop, COO!, whistle (rig frames)',
      (tester) async {
        await tester.runAsync(() async {
          final states = <(String, KingCooPose)>[
            for (final e in _expressions().where(
              (e) => !e.$1.startsWith('looks') && !e.$1.startsWith('story'),
            ))
              e,
          ];
          final px = <Uint8List>[];
          for (final (_, p) in states) {
            px.add(
              await _headPixels(p, ppu: 19, w: 150, h: 100, ox: 100, oy: 82),
            );
          }
          var worst = 99999;
          var worstPair = '';
          for (var i = 0; i < states.length; i++) {
            for (var j = i + 1; j < states.length; j++) {
              var n = 0;
              for (var k = 0; k < px[i].length; k += 4) {
                var d = 0;
                for (var q = 0; q < 4; q++) {
                  d = math.max(d, (px[i][k + q] - px[j][k + q]).abs());
                }
                if (d > 48) n++;
              }
              if (n < worst) {
                worst = n;
                worstPair = '${states[i].$1} / ${states[j].$1}';
              }
            }
          }
          // ignore: avoid_print
          print(
            'real states: worst pair "$worstPair" differs by $worst px at 120 px',
          );
          expect(worst, greaterThan(20), reason: worstPair);
        });
      },
    );

    testWidgets(
      'Reduced Motion: every state keeps its face, none depends on the clock',
      (tester) async {
        await tester.runAsync(() async {
          // The same state at two ages renders the same head (the waddle is 0).
          Future<Uint8List> idle(double t) => _headPixels(
            poseOf(cooBoss(combat: t), reduced: true),
            ppu: 40,
            w: 240,
            h: 200,
            ox: 150,
            oy: 160,
          );
          final a = await idle(1.2), b = await idle(2.9), c = await idle(5.3);
          expect(
            _differ(a, b, ppu: 40, w: 240, h: 200),
            0,
            reason: 'an idle head is a still frame in Reduced Motion',
          );
          expect(_differ(a, c, ppu: 40, w: 240, h: 200), 0);
          // Every state differs from the RM idle (the face survives).
          final base = await _headPixels(
            KingCooPose.still,
            ppu: 40,
            w: 240,
            h: 200,
            ox: 150,
            oy: 160,
          );
          for (final (name, pose) in _expressions(reduced: true).where(
            (e) =>
                !e.$1.startsWith('looks') &&
                e.$1 != 'idle grump' &&
                e.$1 != 'blink',
          )) {
            final px = await _headPixels(
              pose,
              ppu: 40,
              w: 240,
              h: 200,
              ox: 150,
              oy: 160,
            );
            expect(
              _differ(base, px, ppu: 40, w: 240, h: 200),
              greaterThan(40),
              reason: name,
            );
          }
          // No steam, no raindrops: the head draws no motion.
          final fury = poseOf(cooBoss(combat: 1.2, fury: true), reduced: true);
          expect(fury.steam, 0);
          expect(KingCooHeadPose.of(fury).time, 0);
        });
      },
    );
  });

  group('the hit flash goes near white', () {
    testWidgets('skull, beak and cap bleach; the ink holds', (tester) async {
      await tester.runAsync(() async {
        double luma(Uint8List px, Offset p) {
          final c = _at(px, p);
          return (.2126 * c.r + .7152 * c.g + .0722 * c.b) / 255;
        }

        final calm = poseOf(cooBoss(combat: 1.2), reduced: true);
        final flash = poseOf(
          cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .03),
        );
        expect(flash.flash, greaterThan(.5));
        final a = await _headPixels(calm), b = await _headPixels(flash);
        final head =
            KingCooBossRig.eyeAt(flash) + const Offset(.30, .30); // cheek
        final beak = KingCooBossRig.beakAt(flash) + const Offset(.22, .0);
        final cap = KingCooBossRig.capAt(flash).at + const Offset(0, -.22);
        for (final (name, p, min) in [
          ('skull', head, .62),
          ('beak', beak, .72),
          ('cap', cap, .55),
        ]) {
          final before = luma(a, p), after = luma(b, p);
          expect(
            after,
            greaterThan(before + .10),
            reason: '$name bleaches ($before -> $after)',
          );
          expect(
            after,
            greaterThan(min),
            reason: '$name is near white at the flash ($after)',
          );
        }
        // A full-strength flash (.55) is near white on the lilac: L* above 80.
        final px = await _faceRender(
          const KingCooHeadPose(tone: KingCooTone(flash: .55)),
        );
        final calmPx = await _faceRender(const KingCooHeadPose());
        final cheek =
            KingCooLayout.headRest +
            const Offset(.22, .25) +
            const Offset(1.1, 1.3);
        final c = _at(px, cheek), k = _at(calmPx, cheek);
        final lum = (.2126 * c.r + .7152 * c.g + .0722 * c.b) / 255;
        final lumCalm = (.2126 * k.r + .7152 * k.g + .0722 * k.b) / 255;
        expect(
          lum,
          greaterThan(.78),
          reason:
              'a full flash bleaches the lilac to near white ($lumCalm -> $lum)',
        );
      });
    });
  });

  group('the skin API', () {
    bool clockwise(Path path) {
      final m = path.computeMetrics().first;
      var sum = 0.0;
      Offset? first, prev;
      for (var i = 0; i <= 80; i++) {
        final p = m.getTangentForOffset(m.length * i / 80)!.position;
        first ??= p;
        if (prev != null) sum += prev.dx * p.dy - p.dx * prev.dy;
        prev = p;
      }
      sum += prev!.dx * first!.dy - first.dx * prev.dy;
      return sum > 0;
    }

    test(
      'skull, beak, jaw and neck are finite, placed on the head and wound like the torso',
      () {
        final rest = KingCooHeadPose.of(KingCooPose.still);
        final torso = KingCooKit.spline(KingCooLayout.bodyOutline);
        expect(
          clockwise(torso),
          isTrue,
          reason: 'the torso winds clockwise on screen',
        );
        final skull = KingCooHeadArt.skullAt(rest);
        final jaw = KingCooHeadArt.jawAt(rest);
        final beak = KingCooHeadArt.beakAt(rest);
        final neck = KingCooHeadArt.neckOf(rest);
        for (final (name, path) in [
          ('skull', skull),
          ('jaw', jaw),
          ('beak', beak),
          ('neck', neck.path),
        ]) {
          expect(path.getBounds().isFinite, isTrue, reason: name);
          expect(
            clockwise(path),
            isTrue,
            reason:
                '$name winds like the torso, so a skin can fill their union',
          );
        }
        expect(skull.contains(rest.at), isTrue);
        expect(
          skull.contains(KingCooHeadArt.point(rest, KingCooLayout.headEye)),
          isTrue,
        );
        expect(
          beak.contains(KingCooHeadArt.point(rest, const Offset(-.80, -.05))),
          isTrue,
        );
        expect(
          jaw.contains(KingCooHeadArt.point(rest, const Offset(-.70, .22))),
          isTrue,
        );
        // The neck starts inside the chest globe and ends under the skull.
        expect(
          neck.spine.first.distance,
          lessThan(KingCooLayout.chestFluffRadius),
        );
        expect(skull.contains(neck.spine.last), isTrue);
        expect(neck.path.contains(neck.spine[2]), isTrue);
        expect(
          neck.at(2, -1).dx,
          lessThan(neck.at(2, 1).dx),
          reason: 'the throat edge is on the beak side',
        );
        // They follow the head: a thrust and a tilt move the skull with it.
        final moved = KingCooHeadPose(
          at: rest.at + const Offset(.3, .14),
          tilt: -.3,
        );
        expect(
          (KingCooHeadArt.skullAt(moved).getBounds().center -
                  skull.getBounds().center)
              .distance,
          greaterThan(.25),
        );
        expect(KingCooHeadArt.neckOf(moved).spine.last, isNot(neck.spine.last));
      },
    );

    testWidgets('a skin built from the pieces paints the same face as head()', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final pose = poseOf(cooBoss(combat: 1.2), reduced: true);
        final hp = KingCooHeadPose.of(pose);
        final standalone = await rawPixels(360, 300, (c) {
          c.translate(210, 250);
          c.scale(60);
          KingCooHeadArt.neck(c, hp);
          KingCooHeadArt.ruff(c, hp);
          KingCooHeadArt.head(c, hp);
        });
        final skin = await rawPixels(360, 300, (c) {
          c.translate(210, 250);
          c.scale(60);
          // A skin: neck and skull filled as one, then the pieces.
          final trunk = Path()
            ..addPath(KingCooHeadArt.neckOf(hp).path, Offset.zero)
            ..addPath(KingCooHeadArt.skullAt(hp), Offset.zero);
          c.drawPath(trunk, Paint()..color = const Color(0xff9d9ac6));
          KingCooHeadArt.neckFill(c, hp);
          KingCooHeadArt.neckDetails(c, hp);
          KingCooHeadArt.ruff(c, hp);
          KingCooHeadArt.under(c, hp);
          KingCooHeadArt.skullFill(c, hp);
          KingCooHeadArt.skullDetails(c, hp);
          KingCooHeadArt.face(c, hp, withCap: false, withWhistle: false);
        });
        // The eye, the beak and the brow (what the face layer owns) are the same.
        final eye = KingCooBossRig.eyeAt(pose);
        final region = Rect.fromCenter(center: eye, width: .6, height: .5);
        expect(
          _differ(standalone, skin, region: region),
          lessThan(40),
          reason: 'the same eye and brow',
        );
        final beak = KingCooBossRig.beakAt(pose);
        expect(
          _differ(
            standalone,
            skin,
            region: Rect.fromCenter(
              center: beak + const Offset(.25, 0),
              width: .6,
              height: .35,
            ),
          ),
          lessThan(400),
        );
      });
    });
  });

  group('budget', () {
    final worst = <(String, KingCooPose)>[
      ('idle', poseOf(cooBoss(combat: 1.2))),
      ('whistle', poseOf(cooBoss(combat: 9.3))),
      (
        'hit',
        poseOf(cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .05)),
      ),
      ('fury', poseOf(cooBoss(combat: 1.2, fury: true))),
      ('fury window', poseOf(cooBoss(combat: 9.3, fury: true))),
      (
        'fury hit',
        poseOf(
          cooBoss(
            combat: 9.3,
            fury: true,
            setup: (b) => b.lastHitAt = b.age - .05,
          ),
        ),
      ),
      (
        'fury hit + wind-up',
        poseOf(
          cooBoss(
            combat: 1.0,
            fury: true,
            setup: (b) => b
              ..lobs.add(lobAt(b.age - .7, fury: true))
              ..lastHitAt = b.age - .05,
          ),
        ),
      ),
      ('roar', poseOf(arrivingBoss(3.0))),
      ('roar + siren', poseOf(arrivingBoss(2.5))),
      (
        'pop',
        poseOf(cooBoss(combat: 9.0, setup: (b) => b.poppedAt = b.age - .5)),
      ),
      (
        'pop in fury',
        poseOf(
          cooBoss(
            combat: 9.0,
            fury: true,
            setup: (b) => b.poppedAt = b.age - .5,
          ),
        ),
      ),
      ('defeat', poseOf(dyingBoss(.5))),
    ];

    test(
      'the head stays inside 70 ops, 3 shaders, 2 clips in every state, and never builds a shader warm',
      () {
        KingCooBossRig.prewarm();
        final report = StringBuffer();
        for (final (name, pose) in worst) {
          final before = KingCooKit.shadersBuilt;
          final cc = Counting(Canvas(ui.PictureRecorder()));
          KingCooBossRig.paintPose(
            cc,
            pose,
            only: KingCooLayout.headParts.toSet(),
          );
          report.writeln(
            '${name.padRight(20)} ${cc.draws} ops, ${cc.clips} clips, ${cc.counts['saveLayer'] ?? 0} layers, ${cc.counts['maskFilter'] ?? 0} blur',
          );
          expect(
            cc.draws,
            lessThanOrEqualTo(KingCooBudget.head.ops),
            reason: name,
          );
          expect(
            cc.clips,
            lessThanOrEqualTo(KingCooBudget.head.clips),
            reason: name,
          );
          expect(cc.counts['saveLayer'] ?? 0, 0, reason: name);
          expect(cc.counts['maskFilter'] ?? 0, 0, reason: name);
          expect(
            KingCooKit.shadersBuilt - before,
            0,
            reason: '$name builds a shader after prewarm',
          );
          expect(
            cc.counts.keys.where((k) => k.startsWith('UNFORWARDED')),
            isEmpty,
            reason: name,
          );
        }
        // ignore: avoid_print
        print(report);
      },
    );

    test(
      'every expression and every story pose builds no shader once warmed, and the cache stays small',
      () {
        KingCooKit.clearCaches();
        KingCooBossRig.prewarm();
        final size = KingCooKit.cacheSize;
        final before = KingCooKit.shadersBuilt;
        final c = Canvas(ui.PictureRecorder());
        for (final (_, pose) in _expressions(
          light: const KingCooSkyLight(dark: .9),
        )) {
          KingCooBossRig.paintPose(c, pose);
        }
        for (final mood in KingCooMood.values) {
          for (final beaten in [false, true]) {
            KingCooBossRig.paintPose(
              c,
              KingCooPose.story(mood, beaten: beaten, talk: .7, blink: .4),
            );
          }
        }
        for (final t in [0.0, .2, .6, 1.0]) {
          KingCooKit.glow(c, Offset.zero, 1, KingCooPalette.sirenRed, t);
        }
        expect(
          KingCooKit.shadersBuilt - before,
          0,
          reason: 'a warmed rig draws every face without a shader',
        );
        expect(
          KingCooKit.cacheSize,
          lessThanOrEqualTo(size + 2),
          reason: 'no state adds a cache entry',
        );
        expect(KingCooKit.cacheSize, lessThan(KingCooKit.cacheCapacity ~/ 2));
      },
    );
  });

  group('determinism', () {
    testWidgets(
      'the same head pixels in any visiting order with every cache emptied',
      (tester) async {
        await tester.runAsync(() async {
          final states = <(String, KingCooHeadPose)>[
            for (final (name, h) in [
              ('idle', _face()),
              ('fury', _face(anger: 1, squint: .3, fury: 1, beak: .12)),
              ('wince', _face(squint: 1, worry: .3, beak: .35, wince: 1)),
              ('coo', _face(beak: 1, anger: .55)),
              ('dizzy', _face(dizzy: 1, beak: .5)),
              ('cheeks', _face(cheek: 1, beak: .14)),
            ])
              (name, h),
            for (final (name, tone) in const [
              ('flash', KingCooTone(flash: .55, dark: .8)),
              ('flash + fury', KingCooTone(flash: .3, fury: 1, dark: .4)),
              ('siren red', KingCooTone(siren: 1, sirenGlow: 1, dark: 1)),
              ('siren blue', KingCooTone(siren: 2, sirenGlow: .6)),
            ])
              (
                name,
                KingCooHeadPose(
                  tone: tone,
                  siren: tone.siren,
                  sirenGlow: tone.sirenGlow,
                  fury: tone.fury,
                  steam: tone.fury,
                  time: 1.3,
                  whistle: .7,
                  whistleAt: const Offset(-1.4, -1.2),
                  blast: .5,
                ),
              ),
          ];
          KingCooKit.clearCaches();
          final fwd = <Uint8List>[];
          for (final (_, h) in states) {
            fwd.add(await _faceRender(h));
          }
          KingCooKit.clearCaches();
          final back = List<Uint8List?>.filled(states.length, null);
          for (var i = states.length - 1; i >= 0; i--) {
            back[i] = await _faceRender(states[i].$2);
          }
          for (var i = 0; i < states.length; i++) {
            expect(_differ(fwd[i], back[i]!), 0, reason: states[i].$1);
          }
        });
      },
    );
  });

  group('safety', () {
    test('non-finite channels never throw and never reach a path', () {
      const nan = double.nan, inf = double.infinity;
      final bad = <KingCooHeadPose>[
        const KingCooHeadPose(at: Offset(nan, 0)),
        const KingCooHeadPose(
          tilt: inf,
          beak: nan,
          cheek: inf,
          squint: nan,
          anger: -inf,
        ),
        const KingCooHeadPose(
          worry: nan,
          dizzy: inf,
          blink: nan,
          wince: nan,
          lookX: inf,
          lookY: nan,
        ),
        const KingCooHeadPose(
          capTilt: nan,
          capLift: Offset(0, inf),
          capSpin: nan,
        ),
        const KingCooHeadPose(
          whistle: nan,
          whistleAt: Offset(nan, nan),
          blast: inf,
        ),
        const KingCooHeadPose(
          sirenGlow: nan,
          steam: inf,
          time: nan,
          fury: nan,
          siren: 2,
        ),
        KingCooHeadPose(
          tone: const KingCooTone(flash: nan, fury: inf, heat: nan, dark: inf),
        ),
        const KingCooHeadPose(
          beak: 99,
          cheek: -9,
          squint: 7,
          anger: 50,
          worry: -3,
        ),
      ];
      for (final h in bad) {
        final c = Canvas(ui.PictureRecorder());
        _paintHead(c, h);
        KingCooHeadArt.face(c, h);
        KingCooHeadArt.under(c, h);
        KingCooHeadArt.skullDetails(c, h);
        KingCooHeadArt.neckDetails(c, h);
        expect(KingCooHeadArt.skullAt(h).getBounds().isFinite, isTrue);
        expect(KingCooHeadArt.jawAt(h).getBounds().isFinite, isTrue);
        expect(KingCooHeadArt.beakAt(h).getBounds().isFinite, isTrue);
        expect(KingCooHeadArt.neckOf(h).path.getBounds().isFinite, isTrue);
        KingCooHeadArt.capOnly(c, siren: 2, sirenGlow: nan);
        KingCooHeadArt.capOnly(
          c,
          tone: KingCooTone(flash: nan),
          siren: 1,
          sirenGlow: 1,
        );
      }
    });

    testWidgets('a figure with a NaN in its boss clock still paints', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final boss = cooBoss(combat: 1.2);
        boss.lastHitAt = double.nan;
        final pose = poseOf(boss);
        final px = await _headPixels(
          pose,
          ppu: 30,
          w: 180,
          h: 150,
          ox: 105,
          oy: 125,
        );
        expect(px.any((v) => v != 0), isTrue);
      });
    });
  });

  group('the cap comes back alone', () {
    testWidgets(
      'capOnly paints the cap about its band centre, every siren state, no pop',
      (tester) async {
        await tester.runAsync(() async {
          for (final siren in [0, 1, 2]) {
            final px = await rawPixels(200, 160, (c) {
              c.translate(100, 110);
              c.scale(80);
              KingCooHeadArt.capOnly(
                c,
                siren: siren,
                sirenGlow: siren == 0 ? 0 : 1,
              );
            });
            final origin = _at(
              px,
              Offset.zero,
              ppu: 80,
              w: 200,
              ox: 100,
              oy: 110,
            );
            expect(origin.a, greaterThan(200));
            expect(origin.b, greaterThan(origin.r), reason: 'the band is navy');
            final dome = _at(
              px,
              KingCooHeadArt.siren - KingCooHeadArt.capSeat,
              ppu: 80,
              w: 200,
              ox: 100,
              oy: 110,
            );
            expect(
              dome.a,
              greaterThan(200),
              reason: 'the dome sits on the cap',
            );
          }
          // The cap in the rig and the cap alone are the same pixels (a cap with
          // no pose turn, at the origin): the tumble starts from the head.
          final pose = KingCooPose.still;
          final hp = KingCooHeadPose.of(pose);
          final atHead = await rawPixels(200, 160, (c) {
            c.translate(100, 110);
            c.scale(80);
            c.translate(
              -hp.at.dx - KingCooHeadArt.capSeat.dx,
              -hp.at.dy - KingCooHeadArt.capSeat.dy,
            );
            KingCooHeadArt.cap(
              c,
              KingCooHeadPose(at: hp.at, capTilt: 0, tone: hp.tone),
            );
          });
          final alone = await rawPixels(200, 160, (c) {
            c.translate(100, 110);
            c.scale(80);
            c.translate(-KingCooHeadArt.capSeat.dx * 0, 0);
            KingCooHeadArt.capOnly(c);
          });
          // (Different origins by design: compare the cap's bounding box size.)
          int rows(Uint8List px) {
            var top = 160, bottom = 0;
            for (var y = 0; y < 160; y++) {
              for (var x = 0; x < 200; x++) {
                if (px[(y * 200 + x) * 4 + 3] > 200) {
                  top = math.min(top, y);
                  bottom = math.max(bottom, y);
                }
              }
            }
            return bottom - top;
          }

          expect((rows(atHead) - rows(alone)).abs(), lessThan(3));
        });
      },
    );
  });

  group('the beak leads', () {
    testWidgets(
      'the beak leads the face by at least .28 at 250 px in every head pose (printed)',
      (tester) async {
        await tester.runAsync(() async {
          const ppu = 41.4;
          final report = StringBuffer();
          var worst = 99.0;
          for (final (name, pose) in [
            ('rest', KingCooPose.still),
            ('hover', poseOf(cooBoss(combat: 2.0))),
            ('fury', poseOf(cooBoss(combat: 1.2, fury: true))),
            ('inhale', poseOf(cooBoss(combat: 8.2))),
            ('whistle', poseOf(cooBoss(combat: 9.3))),
            (
              'hit',
              poseOf(
                cooBoss(combat: 1.2, setup: (b) => b.lastHitAt = b.age - .09),
              ),
            ),
            (
              'wind-up hold',
              poseOf(
                cooBoss(
                  combat: 1.0,
                  setup: (b) => b.lobs.add(lobAt(b.age - .7)),
                ),
              ),
            ),
          ]) {
            final raw = await rawPixels(420, 360, (c) {
              c.translate(170, 180);
              c.scale(ppu);
              KingCooBossRig.paintPose(c, pose);
            });
            double left(double y) {
              final row = (180 + y * ppu).round();
              for (var x = 0; x < 420; x++) {
                if (raw[(row * 420 + x) * 4 + 3] >= 128) return (x - 170) / ppu;
              }
              return 99;
            }

            final tip = KingCooBossRig.beakAt(pose);
            var beakLeft = 99.0, other = 99.0;
            for (var y = tip.dy - .12; y <= tip.dy + .12; y += .02) {
              beakLeft = math.min(beakLeft, left(y));
            }
            for (var y = tip.dy - 1.4; y <= tip.dy + 1.4; y += .02) {
              if ((y - tip.dy).abs() < .35) continue;
              other = math.min(other, left(y));
            }
            final lead = other - beakLeft;
            report.writeln(
              '$name: the beak leads by ${lead.toStringAsFixed(2)}',
            );
            // The inhale tips the head beak-down by .22 rad (K8: it was .30,
            // and the visor then reached as far forward as the beak's tilted
            // tip, a lead of .27): the contract's .28 holds in every pose.
            const limit = .28;
            expect(
              lead,
              greaterThan(limit),
              reason: '$name: the beak leads by $limit or more',
            );
            worst = math.min(worst, lead);
          }
          // ignore: avoid_print
          print('$report beak-lead worst: ${worst.toStringAsFixed(2)}');
        });
      },
    );
  });

  group('cost', () {
    test(
      'a head frame records in well under a millisecond (no per-frame shader, allocation-light)',
      () {
        KingCooBossRig.prewarm();
        final poses = [
          for (var i = 0; i < 40; i++)
            poseOf(
              cooBoss(
                combat: 1.0 + i * .37,
                fury: i % 3 == 0,
                setup: (b) {
                  if (i % 4 == 0) b.lastHitAt = b.age - .05;
                },
              ),
              light: const KingCooSkyLight(dark: .8),
            ),
        ];
        // Warm the JIT.
        for (var i = 0; i < 300; i++) {
          final rec = ui.PictureRecorder();
          KingCooBossRig.paintPose(
            Canvas(rec),
            poses[i % poses.length],
            only: _headParts,
          );
          rec.endRecording().dispose();
        }
        final sw = Stopwatch()..start();
        const n = 2000;
        for (var i = 0; i < n; i++) {
          final rec = ui.PictureRecorder();
          KingCooBossRig.paintPose(
            Canvas(rec),
            poses[i % poses.length],
            only: _headParts,
          );
          rec.endRecording().dispose();
        }
        final micros = sw.elapsedMicroseconds / n;
        // ignore: avoid_print
        print('head record: ${micros.toStringAsFixed(0)} us per frame');
        expect(micros, lessThan(1000));
      },
    );
  });
}
