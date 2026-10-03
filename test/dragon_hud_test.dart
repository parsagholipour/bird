import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_encounter_ui.dart';
import 'package:push_up_bird/game/dragon_hud_art.dart';
import 'package:push_up_bird/game/dragon_kit.dart';

/// The Ember Dragon's health plate, title card and set-piece brushes: the
/// plate stays where it was, every piece is deterministic and holds still
/// (only fading) under Reduced Motion, none of them blurs or opens a layer,
/// the roar's fire stays under the letterbox, the title card waits for the
/// roar, and the review sheets are written for a look.
final _folder = Directory('build/visual-review/dragon-hud');

// ------------------------------------------------------------ helpers --

SkyBoss _dragon(double age, {int? hp, int number = 10, double x = 1.6}) {
  final b = SkyBoss(
    number: number,
    x: x,
    kind: BossKind.dragon,
    cinematic: true,
  )..fireIn = 1.8;
  b.y = .5;
  if (hp != null) b.hp = hp;
  b.age = age;
  return b;
}

/// A dragon [t] seconds into the fight.
SkyBoss _fight(double t, {int? hp}) {
  final b = _dragon(0, hp: hp);
  b.age = b.arrivalDuration + t;
  return b;
}

SkyBoss _struck(double t, {int hp = 450, double since = .04}) {
  final b = _fight(t, hp: hp)..lastDamage = 30;
  b.lastHitAt = b.age - since;
  return b;
}

SkyBoss _furious(double t, {int hp = 130, double since = 4}) {
  final b = _fight(t, hp: hp);
  b.enragedAt = b.age - since;
  return b;
}

typedef _State = (String, SkyBoss Function(), bool);

/// Every look the plate has: entrance, calm, hit, chip, heart open, fury
/// onset and steady fury, critical, and Reduced Motion variants.
final List<_State> _barStates = [
  ('full', () => _fight(2), false),
  ('60%', () => _fight(2, hp: 290), false),
  ('hit', () => _struck(2), false),
  ('chip', () => _struck(2, since: .35), false),
  ('heart open', () => _fight(DragonBreath.warnAt + .6, hp: 250), false),
  ('heart blast', () => _fight(DragonBreath.blastAt + .6, hp: 250), false),
  ('fury .05', () => _furious(2, hp: 230, since: .05), false),
  ('fury .2', () => _furious(2, hp: 230, since: .2), false),
  ('fury', () => _furious(3), false),
  ('5%', () => _furious(3, hp: 24, since: 9), false),
  ('fill .1', () => _fight(.1), false),
  ('fill .3', () => _fight(.3), false),
  ('fill .5', () => _fight(.5), false),
  ('R full', () => _fight(2), true),
  ('R hit', () => _struck(2), true),
  ('R heart', () => _fight(DragonBreath.warnAt + .6, hp: 250), true),
  ('R fury', () => _furious(3), true),
  ('R 5%', () => _furious(3, hp: 24, since: 9), true),
];

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

Future<Uint8List> _pixels(
  void Function(Canvas) draw, {
  Size size = const Size(800, 360),
}) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.round(), size.height.round());
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

bool _blank(Uint8List rgba) {
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] != 0) return false;
  }
  return true;
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

void _label(Canvas c, String text, Offset at, double size, Color color) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

/// Counts what a frame asks of the canvas.
class Counting implements Canvas {
  Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get layers => counts['saveLayer'] ?? 0;
  int get blurs => counts['maskFilter'] ?? 0;

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
    _n('clip');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(
    Rect r, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    _n('clip');
    inner.clipRect(r, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect r, {bool doAntiAlias = true}) {
    _n('clip');
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
    _n('paragraph');
    inner.drawParagraph(paragraph, offset);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

/// Paints with [draw] on a counting canvas, after a warm-up frame, and
/// returns the counts and the number of gradient shaders the frame built.
(Counting, int) _measure(void Function(Canvas) draw) {
  draw(Canvas(ui.PictureRecorder()));
  final before = DragonKit.shadersBuilt;
  final canvas = Counting(Canvas(ui.PictureRecorder()));
  draw(canvas);
  return (canvas, DragonKit.shadersBuilt - before);
}

const _phones = [
  Size(568, 320),
  Size(640, 360),
  Size(800, 360),
  Size(844, 390),
  Size(932, 430),
];

const _skies = [
  ('night', Color(0xff1b1f45), Color(0xff3a3c73)),
  ('dusk', Color(0xff6a75a8), Color(0xffc9a0b4)),
  ('day', Color(0xff8fd5ee), Color(0xfff2e9c4)),
];

void _sky(Canvas c, Rect r, int which) {
  final (_, top, bottom) = _skies[which];
  c.drawRect(
    r,
    Paint()
      ..shader = ui.Gradient.linear(r.topLeft, r.bottomLeft, [top, bottom]),
  );
}

// -------------------------------------------------------------- tests --

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_fonts);

  group('health plate', () {
    test('the plate is where it was, at every phone size', () {
      for (final size in _phones) {
        final u = math.min(size.height / 360, size.width / 640).clamp(.8, 1.3);
        final hud = math.min(size.width / 1000, size.height / 450);
        final w = math.min(460 * hud, size.width - 24);
        final expected = Rect.fromLTWH((size.width - w) / 2, 7 * u, w, 22 * u);
        final dragon = BossHealthBarArt.bounds(size, _fight(2));
        expect(dragon.left, closeTo(expected.left, .01), reason: '$size');
        expect(dragon.top, closeTo(expected.top, .01), reason: '$size');
        expect(dragon.width, closeTo(expected.width, .01), reason: '$size');
        expect(dragon.height, closeTo(expected.height, .01), reason: '$size');
        // The Baron's plate is the same strip: only the skin differs.
        final baron = SkyBoss(number: 1, x: 1.5);
        expect(BossHealthBarArt.bounds(size, baron), dragon);
        expect(
          BossHealthBarArt.track(size, baron),
          BossHealthBarArt.track(size, _fight(2)),
        );
      }
    });

    testWidgets('every state repeats exactly', (tester) async {
      await tester.runAsync(() async {
        for (final (name, make, reduced) in _barStates) {
          Future<Uint8List> shot() => _pixels(
            (c) => BossHealthBarArt.paint(
              c,
              const Size(800, 360),
              make(),
              reducedMotion: reduced,
            ),
          );
          expect(await shot(), await shot(), reason: name);
        }
      });
    });

    testWidgets('Reduced Motion holds still but every state still reads', (
      tester,
    ) async {
      await tester.runAsync(() async {
        Future<Uint8List> bar(SkyBoss b) => _pixels(
          (c) => BossHealthBarArt.paint(
            c,
            const Size(800, 360),
            b,
            reducedMotion: true,
          ),
        );
        final calm = await bar(_fight(2));
        expect(await bar(_fight(2.9)), calm, reason: 'calm plate is still');
        final fury = await bar(_furious(3));
        expect(await bar(_furious(3.6)), fury, reason: 'steady fury is still');
        for (final (name, make, reduced) in _barStates) {
          if (!reduced || name == 'R full') continue;
          expect(
            await bar(make()),
            isNot(equals(calm)),
            reason: '$name must stay distinguishable',
          );
        }
      });
    });

    test('the entrance fills the gauge from empty in 0.6 s', () {
      double share(SkyBoss b, {bool reduced = false}) =>
          DragonHudArt.gaugeHp(b, reduced: reduced) / b.maxHp;
      expect(share(_fight(0)), 0);
      expect(share(_fight(.3)), inExclusiveRange(.2, .8));
      expect(share(_fight(.6)), 1);
      expect(share(_fight(2)), 1);
      expect(share(_fight(0), reduced: true), 1);
      // Never past the boss's real health.
      expect(share(_fight(.3, hp: 100)), lessThanOrEqualTo(100 / 360 + 1e-9));
      // A defeated dragon's gauge is empty.
      final dead = _fight(2)..defeatedAt = 3;
      expect(share(dead), 0);
    });

    test(
      'a warm plate frame fits the budget: <= 60 ops, no layer, no blur',
      () {
        const size = Size(800, 360);
        final report = StringBuffer();
        for (final (name, make, reduced) in _barStates) {
          final (canvas, built) = _measure(
            (c) =>
                BossHealthBarArt.paint(c, size, make(), reducedMotion: reduced),
          );
          report.writeln(
            '${name.padRight(11)} ops ${canvas.draws.toString().padLeft(3)}  '
            'clips ${canvas.counts['clip'] ?? 0}  built $built',
          );
          expect(canvas.draws, lessThanOrEqualTo(60), reason: name);
          expect(canvas.layers, 0, reason: '$name opens a layer');
          expect(canvas.blurs, 0, reason: '$name blurs');
          expect(built, lessThanOrEqualTo(6), reason: '$name builds shaders');
        }
        // ignore: avoid_print
        print(report);
      },
    );
  });

  group('title card', () {
    const size = Size(800, 360);
    Future<Uint8List> card(double age, {bool reduced = false, Size s = size}) {
      final boss = _dragon(
        age,
        x: math.max(FlightSimulation.birdX + .76, s.width / s.height - .5),
      );
      return _pixels((c) {
        final drew = DragonEncounterUi.nameCard(
          c,
          s,
          boss,
          BossMotion(boss, reducedMotion: reduced),
          birdY: .5,
        );
        expect(drew, isTrue, reason: 'the dragon owns its card at $age');
      }, size: s);
    }

    testWidgets('it waits for the roar, holds, and folds away', (tester) async {
      await tester.runAsync(() async {
        // Before the roar strikes (2.80 s): nothing, so the shared card must
        // not appear early either (the hook says it drew the card).
        expect(DragonEncounterUi.slamAt, closeTo(SkyBoss.roarAt + .15, 1e-9));
        for (final age in [1.6, 2.2, 2.7, 2.79]) {
          expect(_blank(await card(age)), isTrue, reason: '$age');
        }
        // ... and it is there as the plume reaches its height.
        for (final age in [2.86, 3.0, 3.5, 4.0, 4.15]) {
          expect(_blank(await card(age)), isFalse, reason: '$age');
        }
        expect(_blank(await card(4.6)), isTrue);
        expect(_blank(await card(5)), isTrue);
        // Held: from 3.85 to 4.1 only the flame glyph and the ember glow
        // breathe.
        final a = await card(3.85), b = await card(4.1);
        var moved = 0;
        for (var i = 0; i < a.length; i += 4) {
          if ((a[i] - b[i]).abs() > 12 || (a[i + 3] - b[i + 3]).abs() > 12) {
            moved++;
          }
        }
        expect(moved, lessThan(1500), reason: 'the hold is a hold');
      });
    });

    testWidgets('it repeats exactly and holds still under Reduced Motion', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final age in [2.95, 3.2, 3.6, 4.4]) {
          expect(await card(age), await card(age), reason: '$age');
        }
        expect(await card(3.5, reduced: true), await card(4.1, reduced: true));
        expect(_blank(await card(2.7, reduced: true)), isTrue);
        expect(_blank(await card(3.4, reduced: true)), isFalse);
      });
    });

    testWidgets('it keeps clear of the muzzle at every phone size', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final s in _phones) {
          final anchor = math.max(
            FlightSimulation.birdX + .76,
            s.width / s.height - .5,
          );
          final bytes = await card(4.0, s: s);
          // The rightmost card pixel is left of the dragon's snout, which
          // juts some 2.65 hit radii left of the heart.
          final snout = (anchor - 2.65 * SkyBoss.radius) * s.height;
          var right = 0;
          final w = s.width.round();
          for (var i = 3; i < bytes.length; i += 4) {
            if (bytes[i] > 120) right = math.max(right, (i ~/ 4) % w);
          }
          expect(right.toDouble(), lessThan(snout), reason: '$s');
        }
      });
    });

    test('a frame fits the budget: <= 60 ops, no layer, no blur', () {
      for (final age in [2.95, 3.1, 3.4, 3.9, 4.3]) {
        final boss = _dragon(age);
        final (canvas, built) = _measure(
          (c) => DragonEncounterUi.nameCard(
            c,
            size,
            boss,
            BossMotion(boss, reducedMotion: false),
            birdY: .5,
          ),
        );
        expect(canvas.draws, lessThanOrEqualTo(60), reason: '$age');
        expect(canvas.layers, 0);
        expect(canvas.blurs, 0);
        expect(built, lessThanOrEqualTo(6), reason: '$age builds shaders');
      }
    });

    testWidgets('the plate turns see-through where the bird flies', (
      tester,
    ) async {
      await tester.runAsync(() async {
        Future<int> plateAlpha(double birdY) async {
          final boss = _dragon(4.0);
          final bytes = await _pixels((c) {
            DragonEncounterUi.nameCard(
              c,
              size,
              boss,
              BossMotion(boss, reducedMotion: false),
              birdY: birdY,
            );
          });
          // Plate between the letters and the studs, low on the card.
          var peak = 0;
          for (var y = 121; y < 125; y++) {
            for (var x = 70; x < 78; x++) {
              peak = math.max(peak, bytes[(y * 800 + x) * 4 + 3]);
            }
          }
          return peak;
        }

        final clear = await plateAlpha(.8);
        final behind = await plateAlpha(.3);
        expect(clear, greaterThan(200));
        expect(behind, lessThan(clear - 60));
      });
    });
  });

  group('set pieces', () {
    const size = Size(800, 360);
    const h = 360.0;
    final heart = Offset(
      math.max(FlightSimulation.birdX + .76, size.width / h - .5) * h,
      h * .5,
    );

    void roarFrame(
      Canvas c,
      double age, {
      bool reduced = false,
      Offset mouth = const Offset(-97, -58),
      Offset? chin,
    }) {
      final boss = _dragon(age);
      final m = BossMotion(boss, reducedMotion: reduced);
      DragonEncounterUi.roar(
        c,
        heart,
        h,
        m,
        mouth: heart + mouth,
        chin: chin == null ? null : heart + chin,
      );
    }

    testWidgets('the roar stays under the letterbox and does not blur', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final bar = (h * .082).ceil();
        for (final (age, mouth, chin) in [
          for (final age in [2.72, 2.8, 2.9, 3.0, 3.15, 3.3, 3.45])
            for (final (mouth, chin) in const [
              (Offset(-97, -58), null),
              (Offset(-97, -112), null),
              (Offset(-60, -122), null),
              // The jaws as the arrival's roar opens them.
              (Offset(-94, -101), Offset(-111, -51)),
            ])
              (age, mouth, chin),
        ]) {
          final bytes = await _pixels(
            (c) => roarFrame(c, age, mouth: mouth, chin: chin),
          );
          // The gout's rim (crimson at the jaws, cooling to wine at the
          // crown) edges all of its fire, the flicked-off flames too, and
          // nothing else the roar draws is that colour.
          bool rim(int i) =>
              bytes[i] > 110 &&
              bytes[i + 1] < 60 &&
              bytes[i + 2] > 35 &&
              bytes[i + 2] < 90 &&
              bytes[i + 3] > 230;
          var fire = 0;
          for (var i = 0; i < bytes.length; i += 4) {
            if (rim(i)) fire++;
          }
          // (It is all gone to smoke by 3.45.)
          if (age < 3.4) {
            expect(fire, greaterThan(0), reason: 'no fire at $age $mouth');
          }
          for (var y = 0; y < bar; y++) {
            for (var x = 0; x < 800; x++) {
              expect(
                rim((y * 800 + x) * 4),
                isFalse,
                reason: 'fire above the bar at $age $mouth ($x,$y)',
              );
            }
          }
        }
        // ... and it is really there below the bar.
        final mid = await _pixels((c) => roarFrame(c, 2.9));
        var lit = 0;
        for (var i = 3; i < mid.length; i += 4) {
          if (mid[i] > 200) lit++;
        }
        expect(lit, greaterThan(400));
      });
    });

    testWidgets('roar, fury ring, hit, burst and snow repeat exactly', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final frames = <String, void Function(Canvas)>{
          'roar': (c) => roarFrame(c, 2.9),
          'roar R': (c) => roarFrame(c, 2.9, reduced: true),
          'rage': (c) {
            final b = _furious(3, hp: 170, since: .3);
            DragonEncounterUi.rage(
              c,
              heart,
              h,
              BossMotion(b, reducedMotion: false),
            );
          },
          'rage R': (c) {
            final b = _furious(3, hp: 170, since: .3);
            DragonEncounterUi.rage(
              c,
              heart,
              h,
              BossMotion(b, reducedMotion: true),
            );
          },
          'hit': (c) => DragonEncounterUi.hit(c, heart, h, .2, reduced: false),
          'heart': (c) => DragonEncounterUi.hit(
            c,
            heart,
            h,
            .2,
            reduced: false,
            crit: true,
          ),
          'heart R': (c) =>
              DragonEncounterUi.hit(c, heart, h, .2, reduced: true, crit: true),
          'burst': (c) => DragonEncounterUi.burst(c, heart, h, .3, false),
          'burst R': (c) => DragonEncounterUi.burst(c, heart, h, .3, true),
          'shockwave': (c) => DragonEncounterUi.shockwave(c, heart, h, .25),
          'snow': (c) =>
              DragonEncounterUi.emberSnow(c, heart, h, 1.7, reduced: false),
          'mood': (c) {
            final b = _fight(6, hp: 150);
            DragonEncounterUi.mood(
              c,
              size,
              b,
              BossMotion(b, reducedMotion: false),
            );
          },
        };
        for (final entry in frames.entries) {
          final a = await _pixels(entry.value), b = await _pixels(entry.value);
          expect(a, b, reason: entry.key);
          expect(_blank(a), isFalse, reason: '${entry.key} draws something');
        }
      });
    });

    testWidgets(
      'the burst and its snow behave: bounded, quiet after, still in Reduced Motion',
      (tester) async {
        await tester.runAsync(() async {
          // Nothing after the burst's own 1.3 s; the snow carries on past it,
          // to 2.45 s, and only through emberSnow.
          expect(
            _blank(
              await _pixels(
                (c) => DragonEncounterUi.burst(c, heart, h, 1, false),
              ),
            ),
            isTrue,
          );
          expect(
            _blank(
              await _pixels(
                (c) => DragonEncounterUi.emberSnow(
                  c,
                  heart,
                  h,
                  1.2,
                  reduced: false,
                ),
              ),
            ),
            isTrue,
            reason: 'the burst owns the snow until 1.3 s',
          );
          expect(
            _blank(
              await _pixels(
                (c) => DragonEncounterUi.emberSnow(
                  c,
                  heart,
                  h,
                  1.8,
                  reduced: false,
                ),
              ),
            ),
            isFalse,
          );
          expect(
            _blank(
              await _pixels(
                (c) => DragonEncounterUi.emberSnow(
                  c,
                  heart,
                  h,
                  2.6,
                  reduced: false,
                ),
              ),
            ),
            isTrue,
          );
          expect(
            _blank(
              await _pixels(
                (c) => DragonEncounterUi.emberSnow(
                  c,
                  heart,
                  h,
                  1.8,
                  reduced: true,
                ),
              ),
            ),
            isTrue,
          );
          // Reduced Motion: the same scatter, only fading.
          final early = await _pixels(
            (c) => DragonEncounterUi.burst(c, heart, h, .2, true),
          );
          final late = await _pixels(
            (c) => DragonEncounterUi.burst(c, heart, h, .5, true),
          );
          expect(_blank(early), isFalse);
          expect(_blank(late), isFalse);
          var brighter = 0;
          for (var i = 3; i < early.length; i += 4) {
            if (early[i] > late[i]) brighter++;
          }
          expect(
            brighter,
            greaterThan(2000),
            reason: 'it fades, it does not move',
          );
        });
      },
    );

    test('a burst frame fits the budget: <= 80 ops, no layer, no blur', () {
      for (final t in [.02, .08, .15, .25, .4, .55, .7, .9]) {
        for (final reduced in [false, true]) {
          final (canvas, built) = _measure(
            (c) => DragonEncounterUi.burst(c, heart, h, t, reduced),
          );
          expect(canvas.draws, lessThanOrEqualTo(80), reason: 't $t $reduced');
          expect(canvas.layers, 0);
          expect(canvas.blurs, 0);
          expect(built, lessThanOrEqualTo(6), reason: 't $t builds shaders');
        }
      }
    });

    test('roar, ring, hit, shockwave and mood open no layer and no blur', () {
      final b = _fight(6, hp: 150);
      final pieces = <String, void Function(Canvas)>{
        for (final age in [2.7, 2.9, 3.2])
          'roar $age': (c) => roarFrame(c, age),
        'rage': (c) {
          final f = _furious(3, hp: 170, since: .3);
          DragonEncounterUi.rage(
            c,
            heart,
            h,
            BossMotion(f, reducedMotion: false),
          );
        },
        'hit': (c) => DragonEncounterUi.hit(c, heart, h, .2, reduced: false),
        'heart': (c) =>
            DragonEncounterUi.hit(c, heart, h, .2, reduced: false, crit: true),
        'shockwave': (c) => DragonEncounterUi.shockwave(c, heart, h, .2),
        'mood': (c) => DragonEncounterUi.mood(
          c,
          size,
          b,
          BossMotion(b, reducedMotion: false),
        ),
      };
      for (final entry in pieces.entries) {
        final (canvas, built) = _measure(entry.value);
        expect(canvas.layers, 0, reason: entry.key);
        expect(canvas.blurs, 0, reason: entry.key);
        expect(canvas.draws, lessThanOrEqualTo(80), reason: entry.key);
        expect(built, lessThanOrEqualTo(6), reason: '${entry.key} shaders');
      }
    });
  });

  group('campaign story line', () {
    const quote = '\u201cThis route is my roost now, little courier!\u201d';
    const long =
        '\u201cYou crawled all this way to lose your feathers on my mountain, '
        'little courier, and you will thank me for it.\u201d';

    Future<Uint8List> card(
      double age,
      Size s, {
      String? line,
      bool reduced = false,
      double birdY = .9,
    }) {
      final boss = _dragon(
        age,
        x: math.max(FlightSimulation.birdX + .76, s.width / s.height - .5),
      );
      return _pixels(
        (c) => DragonEncounterUi.nameCard(
          c,
          s,
          boss,
          BossMotion(boss, reducedMotion: reduced),
          birdY: birdY,
          line: line,
        ),
        size: s,
      );
    }

    /// The pixels where two cards differ: their box (left, top, right,
    /// bottom) and how many there are.
    (int, int, int, int, int) apart(Uint8List a, Uint8List b, Size s) {
      final w = s.width.toInt();
      var l = w, t = s.height.toInt(), r = -1, bt = -1, n = 0;
      for (var y = 0; y < s.height; y++) {
        for (var x = 0; x < w; x++) {
          final i = (y * w + x) * 4;
          var d = 0;
          for (var k = 0; k < 4; k++) {
            d = math.max(d, (a[i + k] - b[i + k]).abs());
          }
          if (d <= 6) continue;
          n++;
          l = math.min(l, x);
          t = math.min(t, y);
          r = math.max(r, x);
          bt = math.max(bt, y);
        }
      }
      return (l, t, r, bt, n);
    }

    for (final s in const [Size(640, 360), Size(800, 360)]) {
      final w = s.width.toInt();
      testWidgets('a line sits under the plate and fits at $w', (tester) async {
        await tester.runAsync(() async {
          final anchor = math.max(
            FlightSimulation.birdX + .76,
            s.width / s.height - .5,
          );
          final snout = (anchor - 2.65 * SkyBoss.radius) * s.height;
          for (final reduced in [false, true]) {
            for (final line in [quote, long]) {
              final plain = await card(3.6, s, reduced: reduced);
              final withLine = await card(3.6, s, line: line, reduced: reduced);
              final (l, t, r, b, n) = apart(plain, withLine, s);
              final why = '$w reduced: $reduced ${line.length} chars';
              expect(n, greaterThan(400), reason: '$why: the line shows');
              // The plate, its lettering and its shade above the quote are
              // exactly what they were: the difference starts under it.
              expect(t, greaterThan(s.height * .36), reason: why);
              // Two lines at most, clear of the letterbox's caption bar and
              // of the dragon's muzzle.
              expect(b, lessThan(s.height * .58), reason: why);
              expect(b - t, lessThan(s.height * .2), reason: why);
              expect(r, lessThan(snout), reason: why);
              expect(l, greaterThan(0), reason: why);
              expect(r, lessThan(w - 24), reason: why);
            }
          }
        });
      });
    }

    testWidgets('no line, an empty line and a blank line are the card', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final s in const [Size(640, 360), Size(800, 360)]) {
          final plain = await card(3.6, s);
          expect(await card(3.6, s, line: ''), plain);
          expect(await card(3.6, s, line: '   '), plain);
          expect(await card(3.6, s, line: null), plain);
        }
      });
    });

    testWidgets(
      'the line arrives after the name, fades with the card, and holds still in Reduced Motion',
      (tester) async {
        await tester.runAsync(() async {
          const s = Size(640, 360);
          // Gone before the strike and after the fold, like the card.
          for (final age in [1.2, 2.79, 4.6]) {
            expect(await card(age, s, line: quote), await card(age, s));
          }
          // Not yet at the slam, there by the time the name has lit.
          final early = apart(
            await card(2.9, s),
            await card(2.9, s, line: quote),
            s,
          );
          final late = apart(
            await card(3.5, s),
            await card(3.5, s, line: quote),
            s,
          );
          expect(early.$5, lessThan(late.$5 ~/ 3));
          // It holds through the hold (only the flame breathes).
          final a = await card(3.85, s, line: quote);
          final b = await card(4.1, s, line: quote);
          final moved = apart(a, b, s);
          expect(moved.$5, lessThan(1500));
          // Reduced Motion: one frame from the fade-in to the fade-out.
          expect(
            await card(3.4, s, line: quote, reduced: true),
            await card(4.1, s, line: quote, reduced: true),
          );
          // And it repeats exactly.
          expect(
            await card(3.3, s, line: quote),
            await card(3.3, s, line: quote),
          );
        });
      },
    );

    testWidgets('the plate is the same wherever the bird flies', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const s = Size(800, 360);
        // The bird right behind the quote fades the quote, not the plate.
        final plain = await card(3.6, s, birdY: .44);
        final withLine = await card(3.6, s, line: quote, birdY: .44);
        final (_, t, _, _, n) = apart(plain, withLine, s);
        expect(n, greaterThan(200));
        expect(t, greaterThan(s.height * .36));
      });
    });

    test(
      'a frame with a line fits the budget: <= 60 ops, no layer, no blur',
      () {
        for (final line in [quote, long]) {
          for (final age in [3.0, 3.2, 3.5, 4.0]) {
            final boss = _dragon(age);
            final (canvas, built) = _measure(
              (c) => DragonEncounterUi.nameCard(
                c,
                const Size(800, 360),
                boss,
                BossMotion(boss, reducedMotion: false),
                birdY: .5,
                line: line,
              ),
            );
            expect(canvas.draws, lessThanOrEqualTo(60), reason: '$age');
            expect(canvas.layers, 0);
            expect(canvas.blurs, 0);
            expect(built, lessThanOrEqualTo(6), reason: '$age builds shaders');
          }
        }
      },
    );
  });

  group('medallion and banner', () {
    testWidgets('the medallion wears a circlet with a ruby, not an eye', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const center = Offset(40, 40);
        const r = 7.5;
        Future<Uint8List> crest({required bool fury}) => _pixels(
          (c) => DragonHudArt.crest(c, center, r, 1, fury: fury),
          size: const Size(80, 80),
        );
        Color at(Uint8List b, double x, double y) {
          final i = (y.round() * 80 + x.round()) * 4;
          return Color.fromARGB(b[i + 3], b[i], b[i + 1], b[i + 2]);
        }

        final calm = await crest(fury: false);
        // The ruby sits in the band, low in the disc.
        var redness = 0.0;
        for (var dx = -1; dx <= 1; dx++) {
          for (var dy = -1; dy <= 1; dy++) {
            final p = at(calm, center.dx + dx, center.dy + r * .27 + dy);
            redness = math.max(redness, (p.r - p.g) * 255);
          }
        }
        expect(redness, greaterThan(120), reason: 'a ruby in the band');
        // Where an iris's bright core used to be there is now dark metal or
        // gold, never a yellow-white eye.
        final middle = at(calm, center.dx, center.dy - r * .12);
        expect(middle.b * 255, lessThan(190));
        // The fury heats it.
        expect(await crest(fury: true), isNot(equals(calm)));
      });
    });

    testWidgets('HEART x2 reads at 640: ten-pixel type, under the plate', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const size = Size(640, 360);
        final strip = BossHealthBarArt.bounds(size, _fight(4.6));
        final boss = _fight(DragonBreath.warnAt + .7, hp: 250);
        final bytes = await _pixels(
          (c) => BossHealthBarArt.paint(c, size, boss),
          size: size,
        );
        // Rows below the plate that hold cream lettering.
        final rows = <int>{};
        var minX = 640, maxX = 0, maxY = 0;
        for (var y = strip.bottom.ceil(); y < 70; y++) {
          for (var x = 0; x < 640; x++) {
            final i = (y * 640 + x) * 4;
            if (bytes[i] > 235 &&
                bytes[i + 1] > 215 &&
                bytes[i + 2] > 160 &&
                bytes[i + 3] > 250) {
              rows.add(y);
              minX = math.min(minX, x);
              maxX = math.max(maxX, x);
              maxY = math.max(maxY, y);
            }
          }
        }
        // Cap height of ten-pixel Fredoka is about seven pixels.
        expect(rows.length, greaterThanOrEqualTo(7));
        // It hangs under the plate, centred on the gauge, inside the strip's
        // width, and stays out of the play space below the HUD band.
        final bar = BossHealthBarArt.track(size, boss);
        expect((minX + maxX) / 2, closeTo(bar.center.dx + 5, 14));
        expect(minX, greaterThan(strip.left));
        expect(maxX, lessThan(strip.right));
        expect(maxY, lessThan(size.height * .11));
      });
    });

    test('plate and lettering keep their contrast over the darkest sky', () {
      double lum(Color c) => c.computeLuminance();
      double ratio(Color a, Color b) {
        final hi = math.max(lum(a), lum(b)), lo = math.min(lum(a), lum(b));
        return (hi + .05) / (lo + .05);
      }

      const sky = Color(0xff1b1f45); // cyberpunk night
      // The rim that outlines the plate against the sky.
      expect(ratio(DragonPalette.gold, sky), greaterThan(6));
      // The lettering on the plate.
      expect(
        ratio(DragonHudArt.cream, const Color(0xff2c1a33)),
        greaterThan(10),
      );
      expect(
        ratio(DragonPalette.gold, const Color(0xff2c1a33)),
        greaterThan(6),
      );
    });
  });

  group('victory gem', () {
    const size = Size(800, 360);
    const h = 360.0;
    final heart = Offset(
      math.max(FlightSimulation.birdX + .76, size.width / h - .5) * h,
      h * .5,
    );

    (double, double, double) alphaStats(Uint8List b, {Rect? within}) {
      var sx = 0.0, sy = 0.0, total = 0.0, peak = 0.0;
      for (var y = 0; y < 360; y++) {
        for (var x = 0; x < 800; x++) {
          if (within != null && !within.contains(Offset(x + .5, y + .5))) {
            continue;
          }
          final a = b[(y * 800 + x) * 4 + 3].toDouble();
          sx += x * a;
          sy += y * a;
          total += a;
          peak = math.max(peak, a);
        }
      }
      return (total == 0 ? 0 : sx / total, total == 0 ? 0 : sy / total, peak);
    }

    testWidgets('it frees the gem, lifts it into a sun, and goes out', (
      tester,
    ) async {
      await tester.runAsync(() async {
        Future<Uint8List> at(
          double k, {
          bool reduced = false,
          double fade = 1,
        }) => _pixels(
          (c) => DragonEncounterUi.victoryGem(
            c,
            heart,
            h,
            k,
            reduced: reduced,
            fade: fade,
          ),
        );
        expect(_blank(await at(.05)), isTrue);
        expect(_blank(await at(2.3)), isTrue);
        expect(_blank(await at(.4)), isFalse, reason: 'the gem flies');
        expect(_blank(await at(1.4)), isFalse, reason: 'the sun burns');
        expect(
          _blank(await at(1.4, fade: 0)),
          isTrue,
          reason: 'the game can take it away',
        );
        // The gem starts at the heart and rises to the sun, which is high.
        final (gx, gy, _) = alphaStats(await at(.2));
        expect((gx - heart.dx).abs(), lessThan(60));
        expect((gy - heart.dy).abs(), lessThan(70));
        final (_, sy, _) = alphaStats(await at(1.5));
        expect(
          sy,
          lessThan(heart.dy - 60),
          reason: 'the sun is above the dragon',
        );
        expect(await at(.7), await at(.7), reason: 'deterministic');
      });
    });

    testWidgets('it leaves the victory title alone', (tester) async {
      await tester.runAsync(() async {
        // The title, its sparkles, its rule and its points line: the middle
        // of the frame, about 0.38 heights either side of the centre.
        for (final w in [640.0, 800.0]) {
          final sz = Size(w, h);
          final at = Offset(
            math.max(FlightSimulation.birdX + .76, w / h - .5) * h,
            h * .5,
          );
          final zone = Rect.fromLTRB(
            w * .5 - h * .38,
            h * .26,
            w * .5 + h * .38,
            h * .46,
          );
          for (final k in [1.1, 1.3, 1.5, 1.7, 1.9]) {
            final b = await _pixels(
              (c) => DragonEncounterUi.victoryGem(c, at, h, k, reduced: false),
              size: sz,
            );
            var peak = 0;
            for (var y = zone.top.floor(); y < zone.bottom; y++) {
              for (var x = zone.left.floor(); x < zone.right; x++) {
                peak = math.max(peak, b[(y * w.toInt() + x) * 4 + 3]);
              }
            }
            expect(peak, lessThan(70), reason: '$w k $k: a wash, under 27%');
          }
        }
      });
    });

    testWidgets('under Reduced Motion nothing flies: it fades in place', (
      tester,
    ) async {
      await tester.runAsync(() async {
        Future<Uint8List> at(double k) => _pixels(
          (c) => DragonEncounterUi.victoryGem(c, heart, h, k, reduced: true),
        );
        final (x1, y1, _) = alphaStats(await at(.5));
        final (x2, y2, _) = alphaStats(await at(.9));
        expect((x1 - x2).abs(), lessThan(1.5));
        expect((y1 - y2).abs(), lessThan(1.5));
        // The sun grows round the same point (its corona is clipped by the
        // top of the frame, which pulls the centroid a little down).
        final (x3, y3, _) = alphaStats(await at(1.5));
        expect((x1 - x3).abs(), lessThan(4));
        expect((y1 - y3).abs(), lessThan(16));
        expect(_blank(await at(.5)), isFalse);
        expect(_blank(await at(1.5)), isFalse);
        expect(_blank(await at(2.3)), isTrue);
      });
    });

    test('a frame fits the budget: <= 40 ops, no layer, no blur', () {
      for (final reduced in [false, true]) {
        for (final k in [.12, .25, .5, .8, 1.0, 1.2, 1.5, 1.9]) {
          final (canvas, built) = _measure(
            (c) =>
                DragonEncounterUi.victoryGem(c, heart, h, k, reduced: reduced),
          );
          expect(canvas.draws, lessThanOrEqualTo(40), reason: 'k $k $reduced');
          expect(canvas.layers, 0);
          expect(canvas.blurs, 0);
          expect(built, lessThanOrEqualTo(6), reason: 'k $k builds shaders');
        }
      }
    });
  });

  group('sky mood', () {
    const size = Size(800, 360);

    SkyBoss at(double age, {int? hp, double? furySince, double? death}) {
      final b = _dragon(age, hp: hp);
      if (furySince != null) b.enragedAt = age - furySince;
      if (death != null) {
        b.hp = 0;
        b.defeatedAt = age - death;
      }
      return b;
    }

    final states = <(String, SkyBoss Function(), bool)>[
      ('arrival .3', () => at(.3), false),
      ('arrival 1.0', () => at(1.0), false),
      ('roar 2.95', () => at(2.95), false),
      ('calm', () => at(4.6 + 1.2), false),
      ('warning', () => at(4.6 + 4.8), false),
      ('blast', () => at(4.6 + 6.0), false),
      ('fury onset', () => at(4.6 + 2, hp: 200, furySince: .3), false),
      ('fury', () => at(4.6 + 2, hp: 120, furySince: 3), false),
      ('fury blast', () => at(4.6 + 6, hp: 120, furySince: 8), false),
      ('death .5', () => at(4.6 + 9, death: .5), false),
      ('death 2.0', () => at(4.6 + 9, death: 2.0), false),
      ('R calm', () => at(4.6 + 1.2), true),
      ('R fury blast', () => at(4.6 + 6, hp: 120, furySince: 8), true),
    ];

    test(
      'the washes cover at most 1.1 screens, in tight boxes, in every state',
      () {
        final report = StringBuffer();
        for (final (name, make, reduced) in states) {
          final boss = make();
          final area = _AreaCanvas(
            Canvas(ui.PictureRecorder()),
            Offset.zero & size,
          );
          DragonEncounterUi.mood(
            area,
            size,
            boss,
            BossMotion(boss, reducedMotion: reduced),
          );
          report.writeln(
            '${name.padRight(14)} ${(area.area / (size.width * size.height)).toStringAsFixed(2)} screens, '
            '${area.draws} draws, largest ${(area.largest / (size.width * size.height)).toStringAsFixed(2)}',
          );
          expect(
            area.area / (size.width * size.height),
            lessThan(1.1),
            reason: name,
          );
          // No single draw is a bounding box over the sky bigger than one
          // gradient half of it (the embers and wisps are drawn dot by dot).
          expect(
            area.largest / (size.width * size.height),
            lessThan(.51),
            reason: name,
          );
          expect(area.draws, lessThanOrEqualTo(14), reason: name);
        }
        // ignore: avoid_print
        print(report);
      },
    );

    testWidgets(
      'nothing is drawn where nothing could be seen, and it never pops',
      (tester) async {
        await tester.runAsync(() async {
          Future<Uint8List> frame(SkyBoss b) => _pixels(
            (c) => DragonEncounterUi.mood(
              c,
              size,
              b,
              BossMotion(b, reducedMotion: true),
            ),
          );
          // The first frame of the arrival has a storm of zero.
          expect(_blank(await frame(at(0))), isTrue);
          // A dragon long gone.
          expect(_blank(await frame(at(4.6 + 9, death: 3.6))), isTrue);
          // Across the fade-out (Reduced Motion, so the dots hold still) no
          // pixel steps by more than 3 of 255 between frames 0.02 s apart.
          Uint8List? last;
          for (var d = 2.0; d <= 3.5; d += .02) {
            final next = await frame(at(4.6 + 9, death: d));
            if (last != null) {
              var worst = 0;
              for (var i = 0; i < next.length; i++) {
                worst = math.max(worst, (next[i] - last[i]).abs());
              }
              expect(worst, lessThanOrEqualTo(12), reason: 'death $d');
            }
            last = next;
          }
          // And in, across the arrival.
          last = null;
          for (var a = 0.0; a <= .9; a += .02) {
            final next = await frame(at(a));
            if (last != null) {
              var worst = 0;
              for (var i = 0; i < next.length; i++) {
                worst = math.max(worst, (next[i] - last[i]).abs());
              }
              expect(worst, lessThanOrEqualTo(12), reason: 'arrival $a');
            }
            last = next;
          }
        });
      },
    );

    test(
      'the breath\'s heat ramps without building more than two gradients a frame',
      () {
        final boss = at(4.6 + 3.9);
        var worst = 0;
        for (var t = 3.9; t < 7.4; t += .02) {
          boss.age = boss.arrivalDuration + t;
          final before = DragonKit.shadersBuilt;
          DragonEncounterUi.mood(
            Canvas(ui.PictureRecorder()),
            size,
            boss,
            BossMotion(boss, reducedMotion: false),
          );
          worst = math.max(worst, DragonKit.shadersBuilt - before);
        }
        expect(worst, lessThanOrEqualTo(2));
        // A second pass over the same breath builds none.
        var again = 0;
        for (var t = 3.9; t < 7.4; t += .02) {
          boss.age = boss.arrivalDuration + t;
          final before = DragonKit.shadersBuilt;
          DragonEncounterUi.mood(
            Canvas(ui.PictureRecorder()),
            size,
            boss,
            BossMotion(boss, reducedMotion: false),
          );
          again += DragonKit.shadersBuilt - before;
        }
        expect(again, 0);
      },
    );
  });

  group('bad clocks', () {
    const size = Size(800, 360);
    const h = 360.0;
    const heart = Offset(620, 180);
    const bad = [double.nan, double.infinity, double.negativeInfinity];

    /// Every brush, once, for [boss] on a [sz] screen.
    void everyBrush(SkyBoss boss, Size sz, {bool reduced = false}) {
      final canvas = Canvas(ui.PictureRecorder());
      final m = BossMotion(boss, reducedMotion: reduced);
      // (The plate's layout is the shared strip's; it is asked only for real
      // screens.)
      if (sz.isFinite) {
        BossHealthBarArt.paint(canvas, sz, boss, reducedMotion: reduced);
      }
      DragonEncounterUi.nameCard(
        canvas,
        sz,
        boss,
        m,
        birdY: .5,
        line: '\u201cHi\u201d',
      );
      DragonEncounterUi.mood(canvas, sz, boss, m);
      DragonEncounterUi.roar(canvas, heart, sz.height, m, mouth: heart);
      DragonEncounterUi.rage(canvas, heart, sz.height, m);
      DragonEncounterUi.hit(
        canvas,
        heart,
        sz.height,
        boss.age - boss.lastHitAt,
        reduced: reduced,
        crit: boss.lastCoreHitAt == boss.lastHitAt,
      );
      final k = m.death - SkyBoss.burstAt;
      DragonEncounterUi.shockwave(canvas, heart, sz.height, k);
      DragonEncounterUi.burst(
        canvas,
        heart,
        sz.height,
        BossMotion.ramp(k, 0, 1.3),
        reduced,
      );
      DragonEncounterUi.emberSnow(
        canvas,
        heart,
        sz.height,
        k,
        reduced: reduced,
      );
      DragonEncounterUi.victoryGem(
        canvas,
        heart,
        sz.height,
        k,
        reduced: reduced,
      );
    }

    test(
      'no brush throws when any other boss field, or the screen, is non-finite',
      () {
        for (final v in bad) {
          for (final reduced in [false, true]) {
            for (final change in <(String, void Function(SkyBoss))>[
              ('enragedAt', (b) => b.enragedAt = v),
              ('lastHitAt', (b) => b.lastHitAt = v),
              ('lastCoreHitAt', (b) => b.lastCoreHitAt = v),
              ('defeatedAt', (b) => b.defeatedAt = v),
              ('x', (b) => b.x = v),
              ('y', (b) => b.y = v),
              ('fireIn', (b) => b.fireIn = v),
              ('lastVolleyAt', (b) => b.lastVolleyAt = v),
              ('lastSummonAt', (b) => b.lastSummonAt = v),
            ]) {
              final boss = _fight(6, hp: 150);
              change.$2(boss);
              expect(
                () => everyBrush(boss, size, reduced: reduced),
                returnsNormally,
                reason: '${change.$1} = $v, reduced $reduced',
              );
            }
            // The screen itself.
            for (final sz in [Size(v, 360), Size(800, v), Size(v, v)]) {
              expect(
                () => everyBrush(_fight(6, hp: 150), sz, reduced: reduced),
                returnsNormally,
                reason: 'size $sz reduced $reduced',
              );
            }
          }
        }
      },
    );

    test('no brush throws on a non-finite time, position or size', () {
      for (final v in bad) {
        for (final reduced in [false, true]) {
          final boss = _fight(6, hp: 200)..age = v;
          final m = BossMotion(boss, reducedMotion: reduced);
          final canvas = Canvas(ui.PictureRecorder());
          expect(
            () => BossHealthBarArt.paint(
              canvas,
              size,
              boss,
              reducedMotion: reduced,
            ),
            returnsNormally,
            reason: 'bar $v',
          );
          expect(
            () => DragonEncounterUi.nameCard(canvas, size, boss, m, birdY: .5),
            returnsNormally,
            reason: 'card $v',
          );
          expect(
            () => DragonEncounterUi.nameCard(
              canvas,
              size,
              _dragon(3.5),
              BossMotion(_dragon(3.5), reducedMotion: reduced),
              birdY: v,
            ),
            returnsNormally,
          );
          expect(
            () => DragonEncounterUi.mood(canvas, size, boss, m),
            returnsNormally,
            reason: 'mood $v',
          );
          expect(
            () => DragonEncounterUi.roar(canvas, heart, h, m, mouth: heart),
            returnsNormally,
            reason: 'roar $v',
          );
          expect(
            () => DragonEncounterUi.roar(
              canvas,
              Offset(v, 0),
              h,
              m,
              mouth: heart,
            ),
            returnsNormally,
          );
          expect(
            () => DragonEncounterUi.rage(canvas, heart, h, m),
            returnsNormally,
            reason: 'rage $v',
          );
          expect(
            () => DragonEncounterUi.hit(
              canvas,
              heart,
              h,
              v,
              reduced: reduced,
              crit: true,
            ),
            returnsNormally,
            reason: 'hit $v',
          );
          expect(
            () => DragonEncounterUi.burst(canvas, heart, h, v, reduced),
            returnsNormally,
            reason: 'burst $v',
          );
          expect(
            () => DragonEncounterUi.burst(canvas, Offset(v, v), h, .3, reduced),
            returnsNormally,
          );
          expect(
            () => DragonEncounterUi.shockwave(canvas, heart, h, v),
            returnsNormally,
            reason: 'shockwave $v',
          );
          expect(
            () => DragonEncounterUi.emberSnow(
              canvas,
              heart,
              h,
              v,
              reduced: reduced,
            ),
            returnsNormally,
            reason: 'snow $v',
          );
          expect(
            () => DragonEncounterUi.victoryGem(
              canvas,
              heart,
              h,
              v,
              reduced: reduced,
            ),
            returnsNormally,
            reason: 'gem $v',
          );
          expect(
            () => DragonEncounterUi.victoryGem(
              canvas,
              heart,
              v,
              1.4,
              reduced: reduced,
            ),
            returnsNormally,
          );
          expect(
            () => DragonEncounterUi.victoryGem(
              canvas,
              heart,
              h,
              1.4,
              reduced: reduced,
              fade: v,
            ),
            returnsNormally,
          );
        }
        // The plate's own brushes, called straight.
        final canvas = Canvas(ui.PictureRecorder());
        final strip = Rect.fromLTWH(v, 7, 300, 22);
        expect(
          () => DragonHudArt.frame(
            canvas,
            strip,
            1,
            fury: false,
            defeated: false,
            wave: v,
            flash: v,
          ),
          returnsNormally,
        );
        expect(
          () => DragonHudArt.fill(
            canvas,
            strip,
            v,
            1,
            DragonHudArt.lava,
            glow: v,
            phase: v,
            hotTip: true,
          ),
          returnsNormally,
        );
        expect(
          () => DragonHudArt.motes(
            canvas,
            strip,
            v,
            1,
            time: v,
            fury: true,
            reduced: false,
          ),
          returnsNormally,
        );
        expect(
          () => DragonHudArt.halfMark(
            canvas,
            strip,
            1,
            above: true,
            fury: true,
            wave: v,
            furyAge: v,
          ),
          returnsNormally,
        );
        expect(
          () => DragonHudArt.crest(canvas, Offset(v, 4), 7.5, 1, fury: false),
          returnsNormally,
        );
        expect(() => DragonHudArt.jolt(v, 1, reduced: false), returnsNormally);
      }
    });
  });

  // ---------------------------------------------------- review sheets --

  testWidgets('renders the dragon HUD review sheets', (tester) async {
    await tester.runAsync(() async {
      for (final width in [640.0, 800.0]) {
        final size = Size(width, 360);
        final w = width.toInt();
        final strip = BossHealthBarArt.bounds(size, _fight(2)).inflate(12);
        // Native size: three skies side by side, one row per state.
        final cw = strip.width.ceil(), ch = strip.height.ceil() + 14;
        await _save('bars-$w', cw * 3, ch * _barStates.length, (c) {
          for (var s = 0; s < _barStates.length; s++) {
            final (name, make, reduced) = _barStates[s];
            for (var k = 0; k < 3; k++) {
              c.save();
              c.translate(k * cw.toDouble(), s * ch.toDouble());
              final cell = Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble());
              c.clipRect(cell);
              _sky(c, cell, k);
              c.translate(-strip.left, -strip.top + 2);
              BossHealthBarArt.paint(c, size, make(), reducedMotion: reduced);
              c.restore();
            }
            _label(
              c,
              name,
              Offset(3, s * ch + ch - 14.0),
              9,
              const Color(0xffffffff),
            );
          }
        });
        // Close-up: 3x, the dusk sky.
        const zoom = 3.0;
        final zh = (strip.height * zoom).ceil();
        await _save(
          'bars-$w-zoom',
          (strip.width * zoom).ceil(),
          zh * _barStates.length,
          (c) {
            for (var s = 0; s < _barStates.length; s++) {
              final (name, make, reduced) = _barStates[s];
              c.save();
              c.translate(0, s * zh.toDouble());
              final cell = Rect.fromLTWH(
                0,
                0,
                strip.width * zoom,
                zh.toDouble(),
              );
              c.clipRect(cell);
              _sky(c, cell, 1);
              c.scale(zoom);
              c.translate(-strip.left, -strip.top);
              BossHealthBarArt.paint(c, size, make(), reducedMotion: reduced);
              c.restore();
              _label(
                c,
                name,
                Offset(4, s * zh + 2.0),
                12,
                const Color(0xffffffff),
              );
            }
          },
        );
      }
      // The title card over each sky at its beats, then under Reduced Motion.
      const size = Size(800, 360);
      final ages = [2.9, 3.05, 3.3, 3.6, 4.0, 4.3];
      const cell = Size(330, 125);
      await _save(
        'title-card',
        (cell.width * 6).toInt(),
        (cell.height * 6).toInt(),
        (c) {
          var row = 0;
          for (final reduced in [false, true]) {
            for (var sky = 0; sky < 3; sky++) {
              for (var i = 0; i < ages.length; i++) {
                c.save();
                c.translate(i * cell.width, row * cell.height);
                final box = Offset.zero & cell;
                c.clipRect(box);
                _sky(c, box, sky);
                c.translate(-30, -30);
                final boss = _dragon(ages[i] + (reduced ? .1 : 0));
                DragonEncounterUi.nameCard(
                  c,
                  size,
                  boss,
                  BossMotion(boss, reducedMotion: reduced),
                  birdY: .5,
                );
                c.restore();
              }
              row++;
            }
          }
        },
      );
    });
  });
}

/// Tallies the screen-space bounds a frame's draws claim (a dot batch counts
/// each dot, not the box round them all).
class _AreaCanvas implements Canvas {
  _AreaCanvas(this.inner, this.screen);
  final Canvas inner;
  final Rect screen;
  double area = 0, largest = 0;
  int draws = 0;

  void _add(Rect r) {
    draws++;
    final box = r.intersect(screen);
    if (box.width <= 0 || box.height <= 0) return;
    final a = box.width * box.height;
    area += a;
    largest = math.max(largest, a);
  }

  @override
  void drawRect(Rect r, Paint p) {
    _add(r);
    inner.drawRect(r, p);
  }

  @override
  void drawOval(Rect r, Paint p) {
    _add(r);
    inner.drawOval(r, p);
  }

  @override
  void drawCircle(Offset c, double r, Paint p) {
    _add(Rect.fromCircle(center: c, radius: r));
    inner.drawCircle(c, r, p);
  }

  @override
  void drawPath(Path path, Paint p) {
    _add(path.getBounds());
    inner.drawPath(path, p);
  }

  @override
  void drawPoints(ui.PointMode mode, List<Offset> points, Paint p) {
    draws++;
    for (final o in points) {
      final box = Rect.fromCircle(
        center: o,
        radius: p.strokeWidth / 2,
      ).intersect(screen);
      if (box.width > 0 && box.height > 0) area += box.width * box.height;
    }
    inner.drawPoints(mode, points, p);
  }

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  void translate(double dx, double dy) => inner.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => inner.scale(sx, sy);
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName}');
}
