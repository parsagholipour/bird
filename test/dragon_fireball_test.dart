import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_call_art.dart';
import 'package:push_up_bird/game/dragon_fireball_art.dart';
import 'package:push_up_bird/game/dragon_pose.dart';

import 'boss_fight_test.dart' show arena;

/// The Ember Dragon's fireballs: review renders (close-ups on light and dark
/// skies, the flight strip, the split), and the promises the art makes.
final _folder = Directory('build/visual-review/dragon-fireball');

const _skies = <(String, Color, Color)>[
  ('cyan', Color(0xff8dd8eb), Color(0xffe9f5df)),
  ('lilac', Color(0xffaaa9e0), Color(0xffffdfc3)),
  ('dusk', Color(0xff485584), Color(0xffadb6da)),
  ('night', Color(0xff1f2446), Color(0xff4a4f7a)),
  ('sunset', Color(0xffe8875a), Color(0xffffd18a)),
];

void _sky(Canvas c, Rect r, int i) {
  final (_, top, bottom) = _skies[i % _skies.length];
  c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(r),
  );
}

Future<ui.Image> _render(int w, int h, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();
  return image;
}

Future<void> _write(String name, ui.Image image) async {
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(
    (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
}

Future<void> _save(
  String name,
  int w,
  int h,
  void Function(Canvas) draw,
) async {
  final image = await _render(w, h, draw);
  await _write(name, image);
  image.dispose();
}

/// [source] blown up [k] times with hard pixels, so the player's real size
/// can be judged in a close-up.
void _blow(Canvas c, ui.Image source, Rect from, Rect to) {
  c.drawImageRect(
    source,
    from,
    to,
    Paint()..filterQuality = FilterQuality.none,
  );
}

void _label(
  Canvas c,
  String text,
  Offset at, {
  Color? color,
  double size = 12,
}) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        color: color ?? const Color(0xffffffff),
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

// ------------------------------------------------------------ in-game --
// Real frames through the real renderer (with the hooks wired by the
// encounter art), for the review sheets.

class _Stage {
  _Stage(this.game, this.sim, this.width);
  final BirdGame game;
  final FlightSimulation sim;
  final double width;
  double birdY = .5;

  void hover(double seconds) {
    for (var i = 0; i < (seconds / .02).round(); i++) {
      final now = (sim.elapsed + .02) * 1000;
      sim.birdY = birdY;
      sim.velocity = 0;
      sim.hearts = 3;
      sim.apply(
        const MovementInput(valid: true),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      sim.tick(.02, now, viewportWidth: width / 360);
    }
  }

  /// Hovers to combat time [t] of breath cycle [cycle].
  void fightTo(int cycle, double t) => hover(
    sim.boss!.arrivalDuration + cycle * DragonBreath.period + t - sim.boss!.age,
  );

  Future<ui.Image> frame() async {
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }
}

Future<_Stage> _stage(
  WidgetTester tester,
  double width, {
  bool reduced = false,
}) async {
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..elapsed = FlightSimulation.bossInterval - .001
    ..bossesDefeated = 9;
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await game.loaded;
  game.pauseEngine();
  final stage = _Stage(game, sim, width)..hover(.02);
  expect(sim.boss!.kind, BossKind.dragon);
  return stage;
}

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

/// Counts what a piece of art asks of the canvas.
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
  List<String> get unforwarded =>
      counts.keys.where((k) => k.startsWith('UNFORWARDED')).toList();

  void _paint(String k, Paint p) {
    _n(k);
    if (p.maskFilter != null) _n('maskFilter');
  }

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
  void drawPoints(ui.PointMode mode, List<Offset> points, Paint paint) {
    _paint('drawPoints', paint);
    inner.drawPoints(mode, points, paint);
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

/// [draw] measured: what it asked of a canvas.
Counting _count(void Function(Canvas) draw) {
  final canvas = Counting(Canvas(ui.PictureRecorder()));
  draw(canvas);
  return canvas;
}

/// [draw] on a flat backdrop, as straight RGBA bytes.
Future<Uint8List> _pixels(
  int w,
  int h,
  void Function(Canvas) draw, {
  Color bg = const Color(0xff808080),
}) async {
  final image = await _render(w, h, (c) {
    c.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = bg,
    );
    draw(c);
  });
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  return bytes;
}

double _lum(Uint8List b, int w, int x, int y) {
  final i = (y * w + x) * 4;
  return .2126 * b[i] + .7152 * b[i + 1] + .0722 * b[i + 2];
}

bool _dark(Uint8List b, int w, int x, int y) => _lum(b, w, x, y) < 60;

/// One tick of the real rules with the bird hovering at [birdY].
void _tick(FlightSimulation sim, double birdY, [double width = 640]) {
  final now = (sim.elapsed + .02) * 1000;
  sim.birdY = birdY;
  sim.velocity = 0;
  sim.hearts = 3;
  sim.apply(
    const MovementInput(valid: true),
    TrackingSample(
      mode: PlayMode.touch,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
  sim.tick(.02, now, viewportWidth: width / 360);
}

SkyBoss _dragon({double combat = 1.2, bool fury = false, int number = 10}) {
  final boss = SkyBoss(
    number: number,
    x: 2,
    kind: BossKind.dragon,
    cinematic: true,
  )..fireIn = 1.8;
  if (fury) boss.hp = boss.maxHp ~/ 3;
  boss.age = boss.arrivalDuration + combat;
  return boss;
}

Offset _dir(double a) => Offset(math.cos(a), math.sin(a));

void main() {
  group('the promises', () {
    test('the fireball ends exactly on the hit circle', () async {
      // The ink ring's outer edge must be the ammo's radius, in the game's
      // own scale and at 4x, on every side but the tail.
      for (final height in [360.0, 1440.0]) {
        final boss = _dragon(fury: true);
        final ammo = BossAmmo(
          x: .3,
          y: .3,
          vx: -.62,
          vy: 0,
          radius: BossAmmo.fireballRadius,
          splitAfter: SkyBoss.emberSplitAfter,
        )..age = .3;
        final size = (height * .6).toInt();
        final r = ammo.radius * height;
        final bytes = await _pixels(
          size,
          size,
          (c) => DragonFireballArt.shot(
            c,
            height,
            ammo,
            boss,
            seconds: 1.3,
            reducedMotion: false,
          ),
        );
        final cx = (ammo.x * height).round(), cy = (ammo.y * height).round();
        for (final (dx, dy) in const [(-1, 0), (0, -1), (0, 1)]) {
          // The pixel [k] steps out from the centre, and its centre distance.
          double lumAt(int k) {
            final x = dx < 0 ? cx - 1 - k : cx + dx * k;
            final y = dy < 0 ? cy - 1 - k : cy + dy * k;
            return _lum(bytes, size, x, y);
          }

          // The outermost pixel that is ink, and how much of the next is.
          var last = (r + 3).floor();
          while (last > 0 && lumAt(last) >= 60) {
            last--;
          }
          final bg = lumAt(last + 3), ink = lumAt(last);
          final spill = ((bg - lumAt(last + 1)) / (bg - ink)).clamp(0.0, 1.0);
          expect(
            last + 1 + spill,
            closeTo(r, .4),
            reason: 'ink ring toward ($dx,$dy) at height $height',
          );
        }
      }
    });

    test('no piece asks for more than its budget', () {
      void within(String name, int limit, void Function(Canvas) draw) {
        final c = _count(draw);
        expect(c.unforwarded, isEmpty, reason: '$name: ${c.unforwarded}');
        expect(c.layers, 0, reason: '$name: no saveLayer');
        expect(c.blurs, 0, reason: '$name: no blur mask');
        expect(c.draws, lessThanOrEqualTo(limit), reason: '$name: ${c.counts}');
      }

      final worst = <String, int>{};
      void watch(String name, int limit, void Function(Canvas) draw) {
        within(name, limit, draw);
        final c = _count(draw);
        worst[name] = math.max(worst[name] ?? 0, c.draws);
      }

      for (final fury in [false, true]) {
        for (final fine in [false, true]) {
          for (final split in [null, .2, .9, 1.0]) {
            watch(
              'fireball fury=$fury fine=$fine split=$split',
              30,
              (c) => DragonFireballArt.paint(
                c,
                center: const Offset(100, 100),
                radius: fine ? 40 : 9,
                direction: math.pi + .1,
                seconds: 1.3,
                reducedMotion: false,
                fury: fury,
                split: split,
              ),
            );
          }
          for (final born in [null, 0.0, .03, .1, .25]) {
            watch(
              'ember fury=$fury born=$born',
              30,
              (c) => DragonFireballArt.paint(
                c,
                center: const Offset(100, 100),
                radius: fine ? 30 : 5.76,
                direction: math.pi + .3,
                seconds: 1.3,
                reducedMotion: false,
                fury: fury,
                ember: true,
                sinceSplit: born,
                speed: 223,
              ),
            );
          }
        }
        for (var i = 0; i <= 20; i++) {
          watch(
            'charge fury=$fury k=${i / 20}',
            30,
            (c) => DragonFireballArt.charge(
              c,
              mouth: const Offset(100, 100),
              h: 360,
              charge: i / 20,
              seconds: 1.3,
              reducedMotion: false,
              fury: fury,
            ),
          );
        }
        for (var i = 0; i <= 36; i++) {
          watch(
            'muzzle fury=$fury tau=${i * .01}',
            30,
            (c) => DragonFireballArt.muzzle(
              c,
              mouth: const Offset(100, 100),
              h: 360,
              tau: i * .01,
              reducedMotion: false,
              fury: fury,
            ),
          );
        }
        for (var i = -30; i <= 100; i++) {
          for (final k in [1.0, .8]) {
            watch(
              'call fury=$fury tau=${i * .01}',
              40,
              (c) => DragonCallArt.paint(
                c,
                mouth: const Offset(300, 100),
                center: const Offset(460, 180),
                h: 360,
                call: 1,
                seconds: 1.3,
                reducedMotion: false,
                fury: fury,
                tau: i * .01,
                strength: k,
              ),
            );
          }
        }
      }
      // The most each kind of piece ever asks for.
      final byKind = <String, int>{};
      for (final e in worst.entries) {
        final kind = e.key.split(' ').first;
        byKind[kind] = math.max(byKind[kind] ?? 0, e.value);
      }
      // ignore: avoid_print
      print('draw ops, worst case: $byKind');
    });

    test('every piece is deterministic and Reduced Motion is still', () async {
      Future<void> check(
        String name,
        void Function(Canvas, double seconds, bool reduced) draw,
      ) async {
        Future<Uint8List> at(double seconds, bool reduced) =>
            _pixels(320, 240, (c) => draw(c, seconds, reduced));
        expect(
          await at(1.3, false),
          await at(1.3, false),
          reason: '$name repeats',
        );
        expect(
          await at(0.4, true),
          await at(2.9, true),
          reason: '$name holds still in Reduced Motion',
        );
      }

      await check(
        'fireball',
        (c, s, r) => DragonFireballArt.paint(
          c,
          center: const Offset(120, 120),
          radius: 30,
          direction: math.pi + .1,
          seconds: s,
          reducedMotion: r,
          fury: true,
          split: .8,
        ),
      );
      await check(
        'ember',
        (c, s, r) => DragonFireballArt.paint(
          c,
          center: const Offset(120, 120),
          radius: 24,
          direction: math.pi + .5,
          seconds: s,
          reducedMotion: r,
          fury: true,
          ember: true,
          sinceSplit: .07,
          speed: 400,
        ),
      );
      for (final k in [.15, .5, .9, 1.0]) {
        await check(
          'charge $k',
          (c, s, r) => DragonFireballArt.charge(
            c,
            mouth: const Offset(160, 120),
            h: 360,
            charge: k,
            seconds: s,
            reducedMotion: r,
            fury: false,
          ),
        );
      }
      for (final tau in [0.0, .05, .2]) {
        await check(
          'muzzle $tau',
          (c, s, r) => DragonFireballArt.muzzle(
            c,
            mouth: const Offset(160, 120),
            h: 360,
            tau: tau,
            reducedMotion: r,
            fury: false,
          ),
        );
      }
      for (final tau in [-.15, .05, .3, .6]) {
        await check(
          'call $tau',
          (c, s, r) => DragonCallArt.paint(
            c,
            mouth: const Offset(120, 100),
            center: const Offset(260, 180),
            h: 360,
            call: .8,
            seconds: s,
            reducedMotion: r,
            fury: false,
            tau: tau,
          ),
        );
      }
    });

    test('states stay readable and distinct in Reduced Motion', () async {
      Future<Uint8List> px(void Function(Canvas) draw) =>
          _pixels(320, 240, draw);
      // Charging: more charge, more orb.
      final charges = <Uint8List>[];
      for (final k in [.2, .5, .9, 1.0]) {
        charges.add(
          await px(
            (c) => DragonFireballArt.charge(
              c,
              mouth: const Offset(160, 120),
              h: 360,
              charge: k,
              seconds: 0,
              reducedMotion: true,
              fury: false,
            ),
          ),
        );
      }
      for (var i = 1; i < charges.length; i++) {
        expect(charges[i], isNot(charges[i - 1]), reason: 'charge step $i');
      }
      // The muzzle ring is there at .1 s and gone at .35 s.
      final bare = await px((c) {});
      final ring = await px(
        (c) => DragonFireballArt.muzzle(
          c,
          mouth: const Offset(160, 120),
          h: 360,
          tau: .1,
          reducedMotion: true,
          fury: false,
        ),
      );
      expect(ring, isNot(bare));
      final gone = await px(
        (c) => DragonFireballArt.muzzle(
          c,
          mouth: const Offset(160, 120),
          h: 360,
          tau: .35,
          reducedMotion: true,
          fury: false,
        ),
      );
      expect(gone, bare);
      // A splitting fireball differs from a plain one, and closes in.
      Future<Uint8List> ball(double? split) => px(
        (c) => DragonFireballArt.paint(
          c,
          center: const Offset(160, 120),
          radius: 30,
          direction: math.pi,
          seconds: 0,
          reducedMotion: true,
          fury: true,
          split: split,
        ),
      );
      expect(await ball(.6), isNot(await ball(null)));
      expect(await ball(.9), isNot(await ball(.6)));
      // The swarm call: still frames differ from nothing, and grow with call.
      Future<Uint8List> call(double v) => px(
        (c) => DragonCallArt.paint(
          c,
          mouth: const Offset(120, 120),
          center: const Offset(260, 180),
          h: 360,
          call: v,
          seconds: 0,
          reducedMotion: true,
          fury: false,
        ),
      );
      expect(await call(.6), isNot(bare));
      expect(await call(1), isNot(await call(.6)));
    });

    test('the charge ends as the launched ball, on the mouth', () async {
      const h = 360.0, mouth = Offset(160, 120);
      final r = h * BossAmmo.fireballRadius;
      for (final k in [.05, .2, .4, .6, .8, .9, 1.0]) {
        final bytes = await _pixels(
          320,
          240,
          (c) => DragonFireballArt.charge(
            c,
            mouth: mouth,
            h: h,
            charge: k,
            seconds: 0,
            reducedMotion: true,
            fury: false,
          ),
        );
        // The ink ring's outer edge, downward and to the right (the funnel
        // of streaks opens to the left).
        for (final (dx, dy) in const [(1, 0), (0, 1)]) {
          double lumAt(int i) => _lum(bytes, 320, 160 + dx * i, 120 + dy * i);
          var last = (r * 1.5).ceil() + 2;
          while (last > 0 && lumAt(last) >= 60) {
            last--;
          }
          if (last == 0) continue; // too small for a ring yet
          final bg = lumAt(last + 3), ink = lumAt(last);
          final spill = ((bg - lumAt(last + 1)) / (bg - ink)).clamp(0.0, 1.0);
          final outer = last + 1 + spill;
          expect(outer, lessThanOrEqualTo(r * 1.5), reason: 'charge $k');
          if (k == 1.0) {
            expect(outer, closeTo(r, .5), reason: 'the full orb is the shot');
          }
        }
      }
      // At full charge the orb sits on the mouth: left and right edges are
      // as far from it as up and down.
      final full = await _pixels(
        320,
        240,
        (c) => DragonFireballArt.charge(
          c,
          mouth: mouth,
          h: h,
          charge: 1,
          seconds: 0,
          reducedMotion: true,
          fury: false,
        ),
      );
      var right = 0, down = 0, up = 0;
      while (!_dark(full, 320, 160 + right, 120)) {
        right++;
      }
      while (!_dark(full, 320, 160, 120 + down)) {
        down++;
      }
      while (!_dark(full, 320, 160, 119 - up)) {
        up++;
      }
      expect((down - up).abs(), lessThanOrEqualTo(1));
      expect((right - down).abs(), lessThanOrEqualTo(1));
    });

    test('the three embers are three at a tenth of a second', () async {
      // At the game's scale: 0.62 h/s, fanned 0.5 rad either side.
      const h = 360.0, speed = .62 * h, d0 = math.pi + .12;
      const origin = Offset(320, 180);
      final r = h * BossAmmo.emberRadius;
      final bytes = await _pixels(640, 360, (c) {
        for (final turn in const [-.5, 0.0, .5]) {
          final d = d0 + turn;
          DragonFireballArt.paint(
            c,
            center: origin + _dir(d) * speed * .1,
            radius: r,
            direction: d,
            seconds: 1.3,
            reducedMotion: false,
            fury: true,
            ember: true,
            sinceSplit: .1,
            speed: speed,
          );
        }
      });
      // Each ember's ink ring is whole: no neighbour overlaps it.
      for (final turn in const [-.5, 0.0, .5]) {
        final at = origin + _dir(d0 + turn) * speed * .1;
        var dark = 0;
        for (var i = 0; i < 24; i++) {
          final a = i * math.pi / 12;
          // The ring sits at the drawn body's edge, a little inside the hit
          // circle while the ember is newly born.
          final p = at + _dir(a) * (r * .61);
          if (_dark(bytes, 640, p.dx.floor(), p.dy.floor())) dark++;
        }
        expect(dark, greaterThanOrEqualTo(15), reason: 'ember at turn $turn');
      }
    });

    test('an ember knows how long ago it was born', () {
      final sim = arena(version: FlightSimulation.currentRulesVersion)
        ..elapsed = FlightSimulation.bossInterval - .001
        ..bossesDefeated = 9;
      _tick(sim, .5);
      final boss = sim.boss!;
      while (boss.age < boss.arrivalDuration + 3.2) {
        _tick(sim, .5);
      }
      boss.hp = boss.maxHp ~/ 2 + 5;
      sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));
      for (var i = 0; i < 20; i++) {
        _tick(sim, .5);
      }
      expect(boss.enraged, isTrue);
      double? born;
      var checked = 0;
      for (var i = 0; i < 600 && checked < 20; i++) {
        _tick(sim, .5);
        final embers = sim.bossAmmo.where((a) => a.ember).toList();
        if (embers.isEmpty) continue;
        born ??= boss.age;
        final truth = boss.age - born;
        for (final e in embers) {
          final guess = DragonFireballArt.sinceSplit(e, boss);
          if (truth < DragonFireballArt.burstSeconds - .03) {
            expect(guess, isNotNull, reason: 'ember at +${truth}s');
            expect(guess!, closeTo(truth, .03));
          }
          if (truth > DragonFireballArt.burstSeconds + .03) {
            expect(guess, isNull, reason: 'an old ember has no burst');
          }
        }
        checked++;
      }
      expect(born, isNotNull, reason: 'fury never split a fireball');
      // A fireball is not an ember, and neither is one after a pair.
      final ball = BossAmmo(x: 1, y: .5, vx: -.6, vy: 0);
      expect(DragonFireballArt.sinceSplit(ball, boss), isNull);
      final ember = BossAmmo(x: 1, y: .5, vx: -.6, vy: 0, ember: true);
      final other = _dragon(fury: true)
        ..volleys = 2
        ..lastVolleyAt = 1.0;
      other.age = 1.55;
      expect(DragonFireballArt.sinceSplit(ember, other), isNull);
      other.volleys = 3;
      expect(DragonFireballArt.sinceSplit(ember, other), closeTo(.1, 1e-9));
    });

    test('the call cue follows the pose', () {
      for (final fury in [false, true]) {
        for (var i = 0; i < 1100; i++) {
          final boss = _dragon(combat: i * .01, fury: fury);
          final pose = DragonPose(boss, BossMotion(boss, reducedMotion: false));
          final timing = DragonCallArt.timing(boss);
          if (pose.call > .001) {
            expect(
              timing,
              isNotNull,
              reason: 'call ${pose.call} at ${i * .01}',
            );
          }
          if (timing == null) {
            expect(pose.call, lessThan(.001), reason: 'silent at ${i * .01}');
          } else {
            expect(timing.tau, inInclusiveRange(-DragonCallArt.intake, 1.0));
          }
        }
      }
      // The first call lands at 7.6; the fury follow-up 1.4 s later, weaker.
      expect(DragonCallArt.timing(_dragon(combat: 7.6))!.tau, closeTo(0, 1e-9));
      expect(DragonCallArt.timing(_dragon(combat: 7.6))!.strength, 1);
      expect(
        DragonCallArt.timing(_dragon(combat: 9.0, fury: true))!.tau,
        closeTo(0, 1e-9),
      );
      expect(
        DragonCallArt.timing(_dragon(combat: 9.0, fury: true))!.strength,
        lessThan(1),
      );
      expect(DragonCallArt.timing(_dragon(combat: 9.0)), isNull);
      expect(DragonCallArt.timing(_dragon(combat: 4.0)), isNull);
      // Cycle after cycle.
      expect(
        DragonCallArt.timing(_dragon(combat: 11 * 3 + 7.8))!.tau,
        closeTo(.2, 1e-9),
      );
    });

    test('the call is cool, small and never goes for the bird', () async {
      const h = 360.0, mouth = Offset(360, 100);
      var worstCover = 0.0;
      for (final fury in [false, true]) {
        var leftmost = 9999.0, rightmost = 0.0;
        for (var i = -6; i <= 20; i++) {
          final tau = i * .05;
          final bytes = await _pixels(
            800,
            360,
            (c) => DragonCallArt.paint(
              c,
              mouth: mouth,
              center: const Offset(620, 180),
              h: h,
              call: 1,
              seconds: 1.1,
              reducedMotion: false,
              fury: fury,
              tau: tau,
            ),
            bg: const Color(0xff000000),
          );
          var lit = 0;
          for (var y = 0; y < 360; y++) {
            for (var x = 0; x < 800; x++) {
              final j = (y * 800 + x) * 4;
              final r = bytes[j], g = bytes[j + 1], b = bytes[j + 2];
              final peak = math.max(r, math.max(g, b));
              if (peak < 40) continue;
              // Cool: never fire, whatever the blend.
              expect(
                r > 140 && r > b + 30,
                isFalse,
                reason: 'a fire colour ($r,$g,$b) at $x,$y tau $tau',
              );
              leftmost = math.min(leftmost, x.toDouble());
              rightmost = math.max(rightmost, x.toDouble());
              if (peak > 128) lit++;
            }
          }
          worstCover = math.max(worstCover, lit / (800 * 360));
        }
        expect(
          leftmost,
          greaterThanOrEqualTo(mouth.dx - h * .34),
          reason: 'fury=$fury: nothing sweeps left toward the bird',
        );
        expect(
          rightmost,
          lessThan(mouth.dx + h * .22),
          reason: 'fury=$fury: nothing reaches back over the face',
        );
      }
      // ignore: avoid_print
      print(
        'call cue: worst coverage ${(worstCover * 100).toStringAsFixed(2)}%',
      );
      expect(worstCover, lessThan(.06), reason: 'the cue hides nothing large');
    });

    test('the call never covers the eye or the face', () async {
      // The assembled dragon's own pose at every beat of the call, both
      // calls of a fury cycle: nothing of the cue may sit on the eye.
      const h = 360.0, unit = h * SkyBoss.radius;
      const center = Offset(460, 180);
      var worst = 0.0;
      for (final fury in [false, true]) {
        for (final start in fury ? [7.6, 9.0] : [7.6]) {
          for (var i = -6; i <= 20; i++) {
            final tau = i * .05;
            final boss = _dragon(combat: start + tau, fury: fury);
            final pose = DragonPose(
              boss,
              BossMotion(boss, reducedMotion: false),
            );
            final mouth = center + DragonBossRig.mouthAt(pose) * unit;
            final eye = center + DragonBossRig.eyeAt(pose) * unit;
            final bytes = await _pixels(
              640,
              360,
              (c) => DragonCallArt.paint(
                c,
                mouth: mouth,
                center: center,
                h: h,
                call: math.max(pose.call, .3),
                seconds: 1.1,
                reducedMotion: false,
                fury: fury,
                boss: boss,
              ),
              bg: const Color(0xff000000),
            );
            var painted = 0, total = 0;
            const r = h * .05;
            for (var y = (eye.dy - r).floor(); y <= (eye.dy + r).ceil(); y++) {
              for (
                var x = (eye.dx - r).floor();
                x <= (eye.dx + r).ceil();
                x++
              ) {
                if ((Offset(x + .5, y + .5) - eye).distance > r) continue;
                total++;
                final j = (y * 640 + x) * 4;
                if (math.max(bytes[j], math.max(bytes[j + 1], bytes[j + 2])) >
                    45) {
                  painted++;
                }
              }
            }
            worst = math.max(worst, painted / total);
            expect(
              painted / total,
              lessThan(.06),
              reason: 'fury=$fury call at $start tau $tau on the eye',
            );
          }
        }
      }
      // ignore: avoid_print
      print(
        'call cue: worst share of the eye disc touched '
        '${(worst * 100).toStringAsFixed(1)}%',
      );
    });

    test('the call and the fireball share the jaws', () async {
      // The rules launch a fireball at ~8.0 s in the middle of the call:
      // with the orb in the jaws and the muzzle bursting, the call's violet
      // must still read, and the orb's fire must not turn violet.
      const h = 360.0, mouth = Offset(360, 100), center = Offset(620, 180);
      int violet(Uint8List b) {
        var n = 0;
        for (var i = 0; i < b.length; i += 4) {
          final r = b[i], g = b[i + 1], bl = b[i + 2];
          if (bl > 90 && bl > r + 30 && bl > g + 30) n++;
        }
        return n;
      }

      void cue(Canvas c, double tau, bool fury) => DragonCallArt.paint(
        c,
        mouth: mouth,
        center: center,
        h: h,
        call: 1,
        seconds: 1.1,
        reducedMotion: false,
        fury: fury,
        tau: tau,
      );

      for (final fury in [false, true]) {
        for (final tau in [-.15, .05, .2, .35, .45]) {
          final alone = await _pixels(
            800,
            360,
            (c) => cue(c, tau, fury),
            bg: const Color(0xff000000),
          );
          final both = await _pixels(800, 360, (c) {
            cue(c, tau, fury);
            DragonFireballArt.charge(
              c,
              mouth: mouth,
              h: h,
              charge: tau < .3 ? .95 : 1,
              seconds: 1.1,
              reducedMotion: false,
              fury: fury,
            );
            if (tau > .3) {
              DragonFireballArt.muzzle(
                c,
                mouth: mouth,
                h: h,
                tau: .03,
                reducedMotion: false,
                fury: fury,
              );
            }
          }, bg: const Color(0xff000000));
          final before = violet(alone), after = violet(both);
          expect(before, greaterThan(0));
          // ignore: avoid_print
          print('fury=$fury tau=$tau violet kept $after / $before');
          expect(
            after,
            greaterThan(before * (tau < 0 ? .55 : .8)),
            reason: 'fury=$fury tau $tau: $after of $before violet pixels left',
          );
        }
      }
    });

    test('hooks shrug off nonsense', () {
      const bad = [
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -1.0,
        0.0,
      ];
      for (final v in bad) {
        final c = _count((c) {
          DragonFireballArt.charge(
            c,
            mouth: Offset(v, 0),
            h: 360,
            charge: .5,
            seconds: 1,
            reducedMotion: false,
            fury: false,
          );
          DragonFireballArt.charge(
            c,
            mouth: const Offset(0, 0),
            h: v,
            charge: .5,
            seconds: 1,
            reducedMotion: false,
            fury: false,
          );
          DragonFireballArt.charge(
            c,
            mouth: const Offset(0, 0),
            h: 360,
            charge: v,
            seconds: 1,
            reducedMotion: false,
            fury: false,
          );
          DragonFireballArt.charge(
            c,
            mouth: const Offset(0, 0),
            h: 360,
            charge: .5,
            seconds: v,
            reducedMotion: false,
            fury: false,
          );
          DragonFireballArt.muzzle(
            c,
            mouth: Offset(v, 0),
            h: 360,
            tau: .1,
            reducedMotion: false,
            fury: false,
          );
          DragonFireballArt.muzzle(
            c,
            mouth: const Offset(0, 0),
            h: v,
            tau: .1,
            reducedMotion: false,
            fury: false,
          );
          DragonFireballArt.muzzle(
            c,
            mouth: const Offset(0, 0),
            h: 360,
            tau: v,
            reducedMotion: false,
            fury: false,
          );
          DragonCallArt.paint(
            c,
            mouth: Offset(v, 0),
            center: Offset.zero,
            h: 360,
            call: .5,
            seconds: 1,
            reducedMotion: false,
            fury: false,
          );
          DragonCallArt.paint(
            c,
            mouth: Offset.zero,
            center: Offset.zero,
            h: v,
            call: .5,
            seconds: 1,
            reducedMotion: false,
            fury: false,
          );
          DragonCallArt.paint(
            c,
            mouth: Offset.zero,
            center: Offset.zero,
            h: 360,
            call: v,
            seconds: 1,
            reducedMotion: false,
            fury: false,
          );
          DragonCallArt.paint(
            c,
            mouth: Offset.zero,
            center: Offset.zero,
            h: 360,
            call: .5,
            seconds: v,
            reducedMotion: false,
            fury: false,
          );
          DragonCallArt.paint(
            c,
            mouth: Offset.zero,
            center: Offset.zero,
            h: 360,
            call: .5,
            seconds: 1,
            reducedMotion: false,
            fury: false,
            tau: v,
          );
          DragonFireballArt.paint(
            c,
            center: Offset(v, 0),
            radius: 9,
            direction: math.pi,
            seconds: 1,
            reducedMotion: false,
          );
          DragonFireballArt.paint(
            c,
            center: Offset.zero,
            radius: v,
            direction: math.pi,
            seconds: 1,
            reducedMotion: false,
          );
          DragonFireballArt.paint(
            c,
            center: Offset.zero,
            radius: 9,
            direction: v,
            seconds: 1,
            reducedMotion: false,
          );
          DragonFireballArt.paint(
            c,
            center: Offset.zero,
            radius: 9,
            direction: math.pi,
            seconds: v,
            reducedMotion: false,
            ember: true,
            sinceSplit: v,
            speed: v,
          );
        });
        expect(c.unforwarded, isEmpty);
      }
      // A call at 0 or below draws nothing at all.
      expect(
        _count(
          (c) => DragonCallArt.paint(
            c,
            mouth: Offset.zero,
            center: Offset.zero,
            h: 360,
            call: 0,
            seconds: 1,
            reducedMotion: false,
            fury: false,
          ),
        ).draws,
        0,
      );
    });
  });

  test('Reduced Motion sheet', () async {
    // Every piece as the still frame Reduced Motion shows, dark sky then light.
    const h = 360.0, unit = h * SkyBoss.radius;
    const cell = Size(330, 230);
    final frames = <(String, ui.Image)>[];
    Future<void> add(String label, int sky, void Function(Canvas) draw) async {
      frames.add((
        label,
        await _render(cell.width.toInt(), cell.height.toInt(), (c) {
          _sky(c, Offset.zero & cell, sky);
          draw(c);
        }),
      ));
    }

    Future<void> headScene(
      String label,
      int sky,
      double charge,
      void Function(Canvas, Offset) over, {
      double tau = -1,
      bool fury = false,
    }) => add(label, sky, (c) {
      final boss = SkyBoss(
        number: 5,
        x: 2,
        kind: BossKind.dragon,
        cinematic: true,
      )..fireIn = .65 * (1 - charge);
      if (fury) boss.hp = boss.maxHp ~/ 3;
      boss.age = boss.arrivalDuration + 1.2;
      if (tau >= 0) {
        boss.fireIn = 1.5;
        boss.lastVolleyAt = boss.age - tau;
      }
      final pose = DragonPose(boss, BossMotion(boss, reducedMotion: true));
      const center = Offset(250, 150);
      c.save();
      c.translate(center.dx, center.dy);
      c.scale(unit * .8);
      DragonBossRig.paintPose(c, pose);
      c.restore();
      over(c, center + DragonBossRig.mouthAt(pose) * (unit * .8));
    });

    for (final sky in [3, 0]) {
      for (final k in [.3, .65, 1.0]) {
        await headScene(
          'charge $k',
          sky,
          k,
          (c, mouth) => DragonFireballArt.charge(
            c,
            mouth: mouth,
            h: h * .8,
            charge: k,
            seconds: 0,
            reducedMotion: true,
            fury: sky == 3,
          ),
          fury: sky == 3,
        );
      }
      for (final tau in [.05, .15, .28]) {
        await headScene(
          'muzzle $tau',
          sky,
          1,
          (c, mouth) => DragonFireballArt.muzzle(
            c,
            mouth: mouth,
            h: h * .8,
            tau: tau,
            reducedMotion: true,
            fury: sky == 3,
          ),
          tau: tau,
          fury: sky == 3,
        );
      }
      await add('fireball / splitting', sky, (c) {
        for (final (i, split) in [(0, null), (1, .5), (2, .9)]) {
          DragonFireballArt.paint(
            c,
            center: Offset(70.0 + i * 100, 60),
            radius: 22,
            direction: math.pi,
            seconds: 0,
            reducedMotion: true,
            fury: sky == 3,
            split: split,
          );
        }
        for (final (i, age) in [(0, 0.03), (1, .1), (2, .2)]) {
          for (final turn in const [-.5, 0.0, .5]) {
            final d = math.pi + turn;
            DragonFireballArt.paint(
              c,
              center: Offset(80.0 + i * 100, 165) + _dir(d) * 223 * age,
              radius: 5.76,
              direction: d,
              seconds: 0,
              reducedMotion: true,
              fury: true,
              ember: true,
              sinceSplit: age,
              speed: 223,
            );
          }
        }
      });
      for (final tau in [.2, .5]) {
        await headScene(
          'call $tau',
          sky,
          0,
          (c, mouth) => DragonCallArt.paint(
            c,
            mouth: mouth,
            center: const Offset(250, 150),
            h: h * .8,
            call: tau < .3 ? 1 : .6,
            seconds: 0,
            reducedMotion: true,
            fury: sky == 3,
          ),
          fury: sky == 3,
        );
      }
    }
    await _save(
      'reduced',
      (cell.width * 4).toInt(),
      (cell.height * ((frames.length + 3) ~/ 4)).toInt(),
      (c) {
        for (var i = 0; i < frames.length; i++) {
          final (label, image) = frames[i];
          c.drawImage(
            image,
            Offset((i % 4) * cell.width, (i ~/ 4) * cell.height),
            Paint(),
          );
          _label(
            c,
            label,
            Offset((i % 4) * cell.width + 6, (i ~/ 4) * cell.height + 4),
          );
        }
      },
    );
    for (final (_, image) in frames) {
      image.dispose();
    }
  });

  test('close-ups on every sky', () async {
    const cellW = 330.0, cellH = 300.0;
    await _save(
      'closeups',
      (cellW * _skies.length).toInt(),
      (cellH * 4).toInt(),
      (c) {
        for (var s = 0; s < _skies.length; s++) {
          for (var row = 0; row < 4; row++) {
            final cell = Rect.fromLTWH(s * cellW, row * cellH, cellW, cellH);
            c.save();
            c.clipRect(cell);
            _sky(c, cell, s);
            final fury = row >= 2;
            final split = row.isOdd ? .78 : null;
            DragonFireballArt.paint(
              c,
              center: cell.topLeft + const Offset(110, 110),
              radius: 42,
              direction: math.pi,
              seconds: 1.3,
              reducedMotion: false,
              fury: fury,
              split: split,
            );
            for (var i = 0; i < 3; i++) {
              DragonFireballArt.paint(
                c,
                center: cell.topLeft + Offset(90 + i * 100.0, 245),
                radius: 26,
                direction: math.pi + (i - 1) * .5,
                seconds: 1.3 + i * .2,
                reducedMotion: false,
                fury: fury,
                ember: true,
              );
            }
            c.restore();
          }
        }
      },
    );
  });

  test('real size and blown up', () async {
    // The game's own scale: h = 360, so a fireball is 9 px and an ember
    // 5.8 px. One row of successive positions per sky, 1x on top of 4x.
    const h = 360.0;
    const w = 460, rowH = 70;
    final frames = <ui.Image>[];
    for (var s = 0; s < _skies.length; s++) {
      for (final fury in [false, true]) {
        frames.add(
          await _render(w, rowH, (c) {
            _sky(c, const Rect.fromLTWH(0, 0, 460, 70), s);
            for (var i = 0; i < 4; i++) {
              DragonFireballArt.paint(
                c,
                center: Offset(340 - i * 90.0, 26 + i * 3.0),
                radius: h * BossAmmo.fireballRadius,
                direction: math.pi + .1,
                seconds: 1.3 + i * .09,
                reducedMotion: false,
                fury: fury,
                split: fury && i == 3 ? .9 : null,
              );
            }
            for (var i = 0; i < 3; i++) {
              DragonFireballArt.paint(
                c,
                center: Offset(400 - i * 26.0, 54 + (i - 1) * 3.0),
                radius: h * BossAmmo.emberRadius,
                direction: math.pi + (i - 1) * .5,
                seconds: 1.3 + i * .3,
                reducedMotion: false,
                fury: fury,
                ember: true,
              );
            }
          }),
        );
      }
    }
    await _save('real-size', w * 2, frames.length * rowH * 2, (c) {
      for (var i = 0; i < frames.length; i++) {
        _blow(
          c,
          frames[i],
          Rect.fromLTWH(0, 0, w.toDouble(), rowH.toDouble()),
          Rect.fromLTWH(0, i * rowH * 2.0, w * 2.0, rowH * 2.0),
        );
      }
    });
    for (final f in frames) {
      f.dispose();
    }
  });

  test('the split in five frames', () async {
    const h = 360.0, speed = .62 * h, d0 = math.pi + .12;
    final times = [-.2, -.05, 0.0, .1, .25, .45];
    final cells = <ui.Image>[];
    for (final fury in [true]) {
      for (final t in times) {
        cells.add(
          await _render(210, 90, (c) {
            _sky(c, const Rect.fromLTWH(0, 0, 210, 90), 2);
            // The split point sits at (120, 45) in every cell.
            const o = Offset(120, 45);
            final v = _dir(d0) * speed;
            if (t < 0) {
              DragonFireballArt.paint(
                c,
                center: o + v * t,
                radius: h * BossAmmo.fireballRadius,
                direction: d0,
                seconds: 1.3,
                reducedMotion: false,
                fury: fury,
                split: (.45 + t) / .45,
              );
            } else {
              for (final turn in const [-.5, 0.0, .5]) {
                final d = d0 + turn;
                DragonFireballArt.paint(
                  c,
                  center: o + _dir(d) * speed * t,
                  radius: h * BossAmmo.emberRadius,
                  direction: d,
                  seconds: 1.3,
                  reducedMotion: false,
                  fury: fury,
                  ember: true,
                  sinceSplit: t,
                  speed: speed,
                );
              }
            }
          }),
        );
      }
    }
    await _save('split-seq', 525 * 3, 225 * 2, (c) {
      for (var i = 0; i < cells.length; i++) {
        _blow(
          c,
          cells[i],
          const Rect.fromLTWH(0, 0, 210, 90),
          Rect.fromLTWH((i % 3) * 525.0, (i ~/ 3) * 225.0, 525, 225),
        );
      }
    });
    for (final f in cells) {
      f.dispose();
    }
  });

  test('charge orb in the jaws and the muzzle burst', () async {
    const h = 360.0, unit = h * SkyBoss.radius;
    const center = Offset(300, 200);
    Future<ui.Image> scene(
      double charge,
      int sky, {
      bool fury = false,
      bool reduced = false,
      double tau = -1,
    }) => _render(400, 300, (c) {
      _sky(c, const Rect.fromLTWH(0, 0, 400, 300), sky);
      final boss = SkyBoss(
        number: 5,
        x: 2,
        kind: BossKind.dragon,
        cinematic: true,
      )..fireIn = .65 * (1 - charge);
      if (fury) boss.hp = boss.maxHp ~/ 3;
      boss.age = boss.arrivalDuration + 1.2;
      if (tau >= 0) {
        boss.fireIn = 1.5;
        boss.lastVolleyAt = boss.age - tau;
      }
      final m = BossMotion(boss, reducedMotion: reduced);
      final pose = DragonPose(boss, m);
      c.save();
      c.translate(center.dx, center.dy);
      c.scale(unit);
      DragonBossRig.paintPose(c, pose);
      c.restore();
      final mouth = center + DragonBossRig.mouthAt(pose) * unit;
      if (tau < 0) {
        DragonFireballArt.charge(
          c,
          mouth: mouth,
          h: h,
          charge: boss.charge,
          seconds: 1.2,
          reducedMotion: reduced,
          fury: fury,
        );
      } else {
        DragonFireballArt.paint(
          c,
          center: mouth + Offset(-h * .62 * tau, 0),
          radius: h * BossAmmo.fireballRadius,
          direction: math.pi,
          seconds: 1.2,
          reducedMotion: reduced,
          fury: fury,
        );
        DragonFireballArt.muzzle(
          c,
          mouth: mouth,
          h: h,
          tau: tau,
          reducedMotion: reduced,
          fury: fury,
        );
      }
    });
    final charges = [.1, .3, .5, .7, .88, 1.0];
    final rows = <List<ui.Image>>[];
    for (final (sky, fury, reduced) in const [
      (0, false, false),
      (3, true, false),
      (2, false, true),
    ]) {
      rows.add([
        for (final k in charges)
          await scene(k, sky, fury: fury, reduced: reduced),
      ]);
    }
    await _save('charge', 400 * 3, 100 * 6, (c) {
      for (var r = 0; r < rows.length; r++) {
        for (var i = 0; i < rows[r].length; i++) {
          // Crop 133 x 100 around the jaws, blown up 3x, two rows of three.
          _blow(
            c,
            rows[r][i],
            const Rect.fromLTWH(128, 72, 133, 100),
            Rect.fromLTWH(
              (i % 3) * 400.0,
              (r * 2 + i ~/ 3) * 100.0 * 1,
              399,
              99,
            ),
          );
        }
      }
    });
    final taus = [0.0, .03, .06, .1, .2, .3];
    final muzzles = <ui.Image>[];
    for (final (sky, fury) in const [(0, false), (3, true)]) {
      for (final t in taus) {
        muzzles.add(await scene(1, sky, fury: fury, tau: t));
      }
    }
    await _save('muzzle', 400 * 3, 300 * 4, (c) {
      for (var i = 0; i < muzzles.length; i++) {
        _blow(
          c,
          muzzles[i],
          const Rect.fromLTWH(128, 72, 133, 100),
          Rect.fromLTWH((i % 3) * 400.0, (i ~/ 3) * 300.0, 399, 299),
        );
      }
    });
    for (final f in [...rows.expand((e) => e), ...muzzles]) {
      f.dispose();
    }
  });

  test('the swarm call on three skies', () async {
    const h = 360.0, unit = h * SkyBoss.radius;
    Future<ui.Image> scene(
      double width,
      double tau,
      int sky, {
      bool fury = false,
      bool reduced = false,
      bool bats = true,
    }) => _render(width.toInt(), 360, (c) {
      _sky(c, Rect.fromLTWH(0, 0, width, 360), sky);
      final boss = SkyBoss(
        number: 5,
        x: 2,
        kind: BossKind.dragon,
        cinematic: true,
      )..fireIn = 1.8;
      if (fury) boss.hp = boss.maxHp ~/ 3;
      boss.age = boss.arrivalDuration + SkyBoss.swarmCallAt + tau;
      final m = BossMotion(boss, reducedMotion: reduced);
      final pose = DragonPose(boss, m);
      final center = Offset(width - 180, 180);
      c.save();
      c.translate(center.dx, center.dy);
      c.scale(unit);
      DragonBossRig.paintPose(c, pose);
      c.restore();
      final mouth = center + DragonBossRig.mouthAt(pose) * unit;
      DragonCallArt.paint(
        c,
        mouth: mouth,
        center: center,
        h: h,
        call: pose.call,
        seconds: 1.2,
        reducedMotion: reduced,
        fury: fury,
        boss: boss,
      );
      if (bats && tau >= 0) {
        // Stand-in bats streaming in from the right at the bird's height.
        for (var i = 0; i < 5; i++) {
          final x = width + 36 - tau * 420 + i * 36;
          c.drawOval(
            Rect.fromCenter(center: Offset(x, 250), width: 26, height: 13),
            Paint()..color = const Color(0xff2a1740),
          );
        }
      }
      c.drawCircle(
        const Offset(169, 250),
        20,
        Paint()..color = const Color(0xffffd23c),
      );
    });
    final taus = [-.15, 0.0, .06, .15, .3, .5, .7, .9];
    for (final (name, sky, width, fury) in const [
      ('call-cyan-640', 0, 640.0, false),
      ('call-dusk-640', 2, 640.0, false),
      ('call-night-800', 3, 800.0, false),
      ('call-fury-640', 3, 640.0, true),
    ]) {
      final frames = [
        for (final t in taus) await scene(width, t, sky, fury: fury),
      ];
      final cropW = 400.0;
      await _save(name, (cropW * 4).toInt(), 250 * 2, (c) {
        for (var i = 0; i < frames.length; i++) {
          _blow(
            c,
            frames[i],
            Rect.fromLTWH(width - cropW, 0, cropW, 250),
            Rect.fromLTWH((i % 4) * cropW, (i ~/ 4) * 250.0, cropW, 250),
          );
          _label(
            c,
            'tau ${taus[i]}',
            Offset((i % 4) * cropW + 6, (i ~/ 4) * 250.0 + 232),
            color: const Color(0xffffffff),
          );
        }
      });
      for (final f in frames) {
        f.dispose();
      }
    }
    final still = await scene(640, .3, 2, reduced: true);
    await _write('call-reduced', still);
    still.dispose();
  });

  for (final width in [640.0, 800.0]) {
    testWidgets('in-game frames at ${width.toInt()}', (tester) async {
      tester.view.physicalSize = ui.Size(width, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await _fonts();
        final s = await _stage(tester, width);
        final boss = s.sim.boss!;
        final tag = '${width.toInt()}';
        final shots = <(String, ui.Image, Rect)>[];
        final crops = <Rect>[];
        Future<void> shot(String name, [Rect? crop]) async {
          final image = await s.frame();
          await _write('game-$tag-$name', image);
          shots.add((name, image, crop ?? Rect.fromLTWH(0, 0, width, 360)));
        }

        Rect around(Offset p, double w, double h) =>
            Rect.fromCenter(center: p, width: w, height: h);

        // The same moment over the dark violet skies (cyberpunk, New York,
        // Paris): the sky is a function of the flight clock.
        final darkShots = <(ui.Image, Rect)>[];
        Future<void> dark(Rect? crop) async {
          if (crop == null) return;
          final saved = s.sim.elapsed;
          for (final index in const [5, 8, 3]) {
            s.sim.elapsed = index * 22.0 + 6;
            darkShots.add((await s.frame(), crop));
          }
          s.sim.elapsed = saved;
        }

        // Charging, the launch and the muzzle burst, and the pair.
        Offset rulesMouth() => Offset(boss.mouthX * 360, boss.mouthY * 360);
        s.fightTo(0, 1.05);
        await shot(
          'charging',
          around(rulesMouth() + const Offset(-40, 0), 190, 120),
        );
        s.fightTo(0, 1.2);
        var launched = boss.lastVolleyAt;
        for (var i = 0; i < 40 && boss.lastVolleyAt == launched; i++) {
          s.hover(.02);
        }
        for (final tau in [0.0, .04, .1, .2]) {
          s.hover(math.max(0, tau - (boss.age - boss.lastVolleyAt)));
          await shot(
            'muzzle-$tau',
            around(rulesMouth() + const Offset(-30, 0), 190, 120),
          );
        }
        s.fightTo(0, 1.9);
        {
          final ammo = s.sim.bossAmmo.firstOrNull;
          final crop = ammo == null
              ? null
              : around(Offset(ammo.x * 360 + 20, ammo.y * 360), 190, 120);
          await shot('fireball', crop);
          await dark(crop);
        }
        {
          // One fireball crossing the screen: five frames, a fifth of a second apart.
          final strip = <ui.Image>[];
          final ammo = s.sim.bossAmmo.firstOrNull;
          for (var i = 0; ammo != null && i < 4; i++) {
            final image = await s.frame();
            strip.add(image);
            crops.add(around(Offset(ammo.x * 360 + 26, ammo.y * 360), 150, 96));
            s.hover(.12);
          }
          if (strip.isNotEmpty) {
            await _save(
              'game-$tag-flight-strip',
              150 * 2 * strip.length,
              96 * 2,
              (c) {
                for (var i = 0; i < strip.length; i++) {
                  _blow(
                    c,
                    strip[i],
                    crops[i],
                    Rect.fromLTWH(i * 300.0, 0, 300, 192),
                  );
                }
              },
            );
            for (final f in strip) {
              f.dispose();
            }
          }
        }
        for (var i = 0; i < 400 && boss.volleys < 2; i++) {
          s.hover(.02);
        }
        s.hover(.5);
        {
          final pair = s.sim.bossAmmo.toList();
          final crop = pair.isEmpty
              ? null
              : around(
                  Offset(
                    pair.map((a) => a.x).reduce((a, b) => a + b) /
                            pair.length *
                            360 +
                        20,
                    pair.map((a) => a.y).reduce((a, b) => a + b) /
                        pair.length *
                        360,
                  ),
                  190,
                  130,
                );
          await shot('pair', crop);
          await dark(crop);
        }

        // Fury: a splitting fireball, then its embers.
        s.birdY = .5;
        s.fightTo(3, .2);
        boss.hp = boss.maxHp ~/ 2 + 5;
        s.sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));
        s.hover(.3);
        expect(boss.enraged, isTrue);
        BossAmmo? ball;
        for (var i = 0; i < 400 && ball == null; i++) {
          s.hover(.02);
          for (final a in s.sim.bossAmmo) {
            if (a.splitAfter != null && a.age > .2) ball = a;
          }
        }
        if (ball != null) {
          Offset at() => Offset(ball!.x * 360, ball.y * 360);
          await shot('split-minus-0.2', around(at(), 170, 110));
          while (s.sim.bossAmmo.contains(ball) && ball.age < .43) {
            s.hover(.02);
          }
          final near = at();
          await shot('split-minus-0.01', around(near, 170, 110));
          await dark(around(near, 170, 110));
          for (var i = 0; i < 20 && !s.sim.bossAmmo.any((a) => a.ember); i++) {
            s.hover(.02);
          }
          final origin = near + Offset(-.62 * 360 * .02, 0);
          var born = boss.age;
          for (final t in [0.0, .1, .24, .44]) {
            s.hover(math.max(0, t - (boss.age - born)) + (t == 0 ? 0 : 0));
            born = born; // keep the first ember frame as the clock
            await shot(
              'split-plus-$t',
              around(origin + Offset(-70, 0), 260, 150),
            );
            if (t == .1 || t == .24) {
              await dark(around(origin + Offset(-70, 0), 260, 150));
            }
          }
        }
        s.sim.bossAmmo.clear();
        final split = [
          for (final shot in shots)
            if (shot.$1.startsWith('split-')) shot,
        ];
        if (split.length >= 6) {
          await _save('game-$tag-split-strip', 3 * 390, 2 * 225, (c) {
            for (var i = 0; i < 6; i++) {
              final (_, image, crop) = split[i];
              _blow(
                c,
                image,
                crop,
                Rect.fromLTWH((i % 3) * 390.0, (i ~/ 3) * 225.0, 389, 224),
              );
            }
          });
        }
        if (darkShots.isNotEmpty) {
          const cellW = 430.0;
          final rows = darkShots.length ~/ 3;
          final cellHs = [
            for (var r = 0; r < rows; r++)
              cellW * darkShots[r * 3].$2.height / darkShots[r * 3].$2.width,
          ];
          await _save(
            'game-$tag-dark-skies',
            (cellW * 3).toInt(),
            cellHs.fold<double>(0, (a, b) => a + b).ceil(),
            (c) {
              var y = 0.0;
              for (var r = 0; r < rows; r++) {
                for (var i = 0; i < 3; i++) {
                  final (image, crop) = darkShots[r * 3 + i];
                  _blow(
                    c,
                    image,
                    crop,
                    Rect.fromLTWH(i * cellW, y, cellW - 1, cellHs[r] - 1),
                  );
                }
                y += cellHs[r];
              }
            },
          );
          for (final (image, _) in darkShots) {
            image.dispose();
          }
        }
        for (final (name, image, crop) in shots) {
          if (crop.width < width) {
            await _save(
              'game-$tag-$name-zoom',
              (crop.width * 3).toInt(),
              (crop.height * 3).toInt(),
              (c) {
                _blow(
                  c,
                  image,
                  crop,
                  Rect.fromLTWH(0, 0, crop.width * 3, crop.height * 3),
                );
              },
            );
          }
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox());
    });

    for (final fury in [false, true]) {
      testWidgets(
        'in-game swarm call at ${width.toInt()}${fury ? ' in fury' : ''}',
        (tester) async {
          tester.view.physicalSize = ui.Size(width, 360);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.runAsync(() async {
            await _fonts();
            final s = await _stage(tester, width);
            final boss = s.sim.boss!;
            if (fury) boss.hp = boss.maxHp ~/ 3;
            // Dark violet, mid and bright skies: the sky is a function of the
            // flight clock, so each region is one clock away.
            const regions = [
              ('cyberpunk', 5),
              ('newyork', 8),
              ('paris', 3),
              ('china', 6),
              ('egypt', 4),
            ];
            // Combat seconds: the intake, the roar, the rules' fireball at
            // ~8.0 in the middle of the call, and (fury) the second call.
            final times = [
              7.35,
              7.55,
              7.7,
              7.85,
              7.98,
              8.04,
              8.2,
              8.45,
              if (fury) ...[8.9, 9.1, 9.3, 9.6],
            ];
            final frames = <String, List<ui.Image>>{
              for (final (name, _) in regions) name: [],
            };
            s.birdY = .62;
            for (final t in times) {
              s.fightTo(0, t);
              final saved = s.sim.elapsed;
              for (final (name, index) in regions) {
                s.sim.elapsed = index * 22.0 + 6;
                frames[name]!.add(await s.frame());
              }
              s.sim.elapsed = saved;
            }
            expect(boss.summons, greaterThan(0));
            final tag = '${width.toInt()}${fury ? '-fury' : ''}';
            for (final (name, _) in regions) {
              final rows = (times.length + 3) ~/ 4;
              await _save('game-call-$name-$tag', 4 * 420, rows * 250, (c) {
                for (var i = 0; i < times.length; i++) {
                  _blow(
                    c,
                    frames[name]![i],
                    Rect.fromLTWH(width - 420, 0, 420, 250),
                    Rect.fromLTWH((i % 4) * 420.0, (i ~/ 4) * 250.0, 420, 250),
                  );
                }
              });
              for (final f in frames[name]!) {
                f.dispose();
              }
            }
          });
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
