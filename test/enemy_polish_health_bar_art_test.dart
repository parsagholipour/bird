import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_health_bar_art.dart';
import 'package:push_up_bird/ui/theme.dart';

const _folder = 'build/visual-review/enemy-polish-health-bar';

const _lift = EnemyHealthBarArt.lift;

void _bar(Canvas c, double height, SkyEnemy enemy, {bool reduced = false}) =>
    EnemyArt.healthBar(c, height, enemy, reducedMotion: reduced);

/// An enemy that has taken [hits] of [damage] each; the last one landed
/// [since] seconds before the rendered frame.
SkyEnemy _hurt({
  required int maxHp,
  required List<int> hits,
  double since = 2,
  double x = .5,
  double y = .5,
  int appearance = 0,
  double? flightPhase,
}) {
  final enemy = SkyEnemy(
    x: x,
    y: y,
    appearance: appearance,
    flightPhase: flightPhase,
    maxHp: maxHp,
  )..age = 1;
  for (final damage in hits) {
    enemy.age += 1.5;
    enemy.takeDamage(damage);
  }
  enemy.age += since;
  return enemy;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loadFonts() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  }

  Future<ui.Image> image(void Function(Canvas) draw, int w, int h) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording().toImage(w, h);
  }

  const box = 240;
  Future<List<int>> pixels(void Function(Canvas) draw) async {
    final shot = await image(draw, box, box);
    final bytes = (await shot.toByteData())!.buffer.asUint8List();
    shot.dispose();
    return bytes;
  }

  /// Bounds of everything painted more opaque than [alpha] as
  /// [left, top, right, bottom].
  List<int>? bounds(List<int> rgba, {int alpha = 0}) {
    int? left, top, right, bottom;
    for (var y = 0; y < box; y++) {
      for (var x = 0; x < box; x++) {
        if (rgba[(y * box + x) * 4 + 3] <= alpha) continue;
        left = left == null || x < left ? x : left;
        right = right == null || x > right ? x : right;
        top ??= y;
        bottom = y;
      }
    }
    return left == null ? null : [left, top!, right!, bottom!];
  }

  Future<void> save(
    void Function(Canvas) draw,
    String name,
    int w,
    int h,
  ) async {
    final shot = await image(draw, w, h);
    final png = (await shot.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    Directory(_folder).createSync(recursive: true);
    File('$_folder/$name.png').writeAsBytesSync(png);
    shot.dispose();
  }

  testWidgets('health bar pops, drains and settles deterministically', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Gameplay scale: a 360 px viewport with the enemy at the box center.
      const height = 360.0, center = box / 2;
      Future<List<int>> frame(SkyEnemy enemy, {bool reduced = false}) =>
          pixels((c) {
            c.translate(center - enemy.x * height, center - enemy.y * height);
            _bar(c, height, enemy, reduced: reduced);
          });
      SkyEnemy first(double since) =>
          _hurt(maxHp: 30, hits: [10], since: since);
      SkyEnemy second(double since) =>
          _hurt(maxHp: 30, hits: [10, 10], since: since);

      final blank = await pixels((_) {});
      expect(
        await frame(_hurt(maxHp: 30, hits: [])),
        blank,
        reason: 'hidden at full health',
      );
      expect(
        await frame(_hurt(maxHp: 30, hits: [10, 10, 10], since: .1)),
        blank,
        reason: 'hidden once defeated',
      );

      for (final reduced in [false, true]) {
        for (final make in [first, second]) {
          final settled = await frame(make(2), reduced: reduced);
          final impact = await frame(make(.03), reduced: reduced);
          expect(
            impact,
            isNot(equals(settled)),
            reason: 'hit acknowledged, reduced: $reduced',
          );
          expect(
            await frame(make(.03), reduced: reduced),
            impact,
            reason: 'paused and replayed frames repeat exactly',
          );
          expect(
            await frame(make(.2), reduced: reduced),
            isNot(equals(settled)),
            reason: 'lost chunk lingers before it drains',
          );
          expect(
            await frame(
              make(EnemyHealthBarArt.settleSeconds + .01),
              reduced: reduced,
            ),
            settled,
            reason: 'nothing animates after the drain',
          );
        }
      }

      final settled = bounds(await frame(first(2)))!;
      final popping = bounds(await frame(first(.02)))!;
      expect(
        popping[2] - popping[0],
        lessThan(settled[2] - settled[0]),
        reason: 'the bar pops in on the first hit',
      );
      expect(
        bounds(await frame(first(.02), reduced: true)),
        settled,
        reason: 'Reduced Motion shows the bar without a pop',
      );
      expect(
        bounds(await frame(second(.02), reduced: true)),
        settled,
        reason: 'Reduced Motion has no punch on later hits',
      );

      // The bar body clears the ±1.2 r character box, even mid-punch; only
      // its faint contact shadow may reach the box edge.
      const artTop = center - 1.2 * height * SkyEnemy.radius;
      for (final enemy in [first(2), first(.12), second(0), second(.05)]) {
        final at = bounds(await frame(enemy), alpha: 127)!;
        expect(at[3], lessThan(artTop - 1), reason: 'clearance');
        expect(at[3], greaterThan(artTop - 12), reason: 'stays close');
        expect((at[0] + at[2]) / 2, closeTo(center, 1.5));
      }
    });
  });

  testWidgets('enemy health bar review sheets', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      await save(_states, 'health-bar-states', 1480, 640);
      await save(_timeline, 'health-bar-timeline', 2140, 1240);
      await save(_overEnemies, 'health-bar-enemies', 1760, 1100);
      await save(_motion, 'health-bar-motion-1x', 1200, 330);
    });
  });

  testWidgets('enemy health bars in the actual game', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
      ..phase = RunPhase.playing
      ..elapsed = 5;
    // Four kinds at different moments after a hit, spread over the viewport.
    final layout = [
      (1.05, .27, 3, [10], .05), // simple bat: bar popping in
      (1.38, .30, 0, [10], .38), // cave bat: ghost draining
      (1.62, .52, 1, [10, 10], 1.6), // beetle: settled wounded
      (1.92, .72, 2, [10, 10], .16), // moth: critical, ghost holding
    ];
    for (final (x, y, kind, hits, since) in layout) {
      sim.enemies.add(
        _hurt(
          maxHp: 30,
          hits: hits,
          since: since,
          x: x,
          y: y,
          appearance: kind,
          flightPhase: kind * 2.399963,
        ),
      );
    }
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
      for (final (name, elapsed) in [
        ('in-game-daylight', 5.0),
        ('in-game-dusk', 21.0),
        ('in-game-twilight', 48.0),
      ]) {
        sim.elapsed = elapsed;
        await save(game.render, name, 800, 360);
      }
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

const _day = [Color(0xffbde9f6), Color(0xfff9efd8)];
const _dusk = [Color(0xffaaa9e0), Color(0xfff3b6aa)];
const _night = [Color(0xff485584), Color(0xffadb6da)];

void _panel(Canvas c, Rect rect, List<Color> colors) {
  c.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(14)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect),
  );
}

/// Draws [enemy]'s bar so that it lands near [at] on a viewport [height] high.
void _barAt(
  Canvas c,
  Offset at,
  double height,
  SkyEnemy enemy, {
  bool reduced = false,
}) {
  c.save();
  c.translate(at.dx - enemy.x * height, at.dy - (enemy.y - _lift) * height);
  _bar(c, height, enemy, reduced: reduced);
  c.restore();
}

void _states(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(c, 'ENEMY HEALTH BAR · SETTLED STATES', const Offset(28, 20), 24);
  _text(
    c,
    'Top: 4× close-up · bottom: actual 360 px viewport size',
    const Offset(28, 54),
    15,
  );
  const states = [
    (50, [10]),
    (50, [10, 10]),
    (50, [10, 10, 10]),
    (50, [10, 10, 10, 10]),
    (30, [10]),
    (30, [10, 10]),
    (20, [10]),
    (15, [10]),
  ];
  for (var band = 0; band < 2; band++) {
    final top = 96.0 + band * 270;
    _panel(c, Rect.fromLTWH(20, top, 1440, 250), band == 0 ? _day : _dusk);
    _text(c, band == 0 ? 'DAYLIGHT' : 'DUSK', Offset(36, top + 10), 12);
    for (var i = 0; i < states.length; i++) {
      final (maxHp, hits) = states[i];
      final enemy = _hurt(maxHp: maxHp, hits: hits);
      final cx = 110.0 + i * 178;
      _barAt(c, Offset(cx, top + 88), 1440, enemy);
      _barAt(c, Offset(cx, top + 170), 360, enemy);
      _barAt(c, Offset(cx, top + 206), 720, enemy);
      _text(c, '${enemy.hp} / ${enemy.maxHp}', Offset(cx - 26, top + 222), 13);
    }
  }
}

const _times = [
  -.05,
  0.0,
  .03,
  .06,
  .10,
  .15,
  .22,
  .30,
  .38,
  .46,
  .55,
  .70,
  1.0,
];

void _timeline(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(c, 'ENEMY HEALTH BAR · AFTER A HIT', const Offset(28, 20), 24);
  _text(
    c,
    'Seconds since the hit · 4× close-up with the actual size below',
    const Offset(28, 54),
    15,
  );
  const rows = [
    ('First hit 30 to 20', 30, <int>[], 10, false, _day),
    ('Second hit 20 to 10', 30, [10], 10, false, _dusk),
    ('Charged 50 to 20', 50, <int>[], 30, false, _day),
    ('50 to 40 to 30 quick', 50, [10], 10, false, _night),
    ('Reduced · first', 30, <int>[], 10, true, _dusk),
    ('Reduced · second', 30, [10], 10, true, _day),
  ];
  for (var col = 0; col < _times.length; col++) {
    final t = _times[col];
    _text(
      c,
      t < 0 ? 'before' : '${(t * 1000).round()} ms',
      Offset(196 + col * 148, 92),
      14,
    );
  }
  for (var row = 0; row < rows.length; row++) {
    final (label, maxHp, earlier, damage, reduced, sky) = rows[row];
    final top = 120.0 + row * 184;
    _panel(c, Rect.fromLTWH(20, top, 2100, 170), sky);
    _text(c, label, Offset(34, top + 16), 15);
    for (var col = 0; col < _times.length; col++) {
      final t = _times[col];
      final quick = label.contains('quick');
      final enemy = _hurt(
        maxHp: maxHp,
        hits: [...earlier, if (t >= 0) damage],
        since: t < 0 ? 2 : t,
      );
      if (quick && t >= 0) {
        // The previous hit landed only .2 s before this one.
        final again = _hurt(maxHp: maxHp, hits: [10], since: .2);
        again.takeDamage(damage);
        again.age += t;
        _barAt(c, Offset(196 + col * 148 + 50, top + 64), 1440, again);
        _barAt(c, Offset(196 + col * 148 + 50, top + 136), 360, again);
        continue;
      }
      final at = Offset(196 + col * 148 + 50, top + 64);
      _barAt(c, at, 1440, enemy, reduced: reduced);
      _barAt(c, at + const Offset(0, 72), 360, enemy, reduced: reduced);
    }
  }
}

void _overEnemies(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(c, 'HEALTH BAR OVER EACH ENEMY', const Offset(28, 20), 24);
  _text(
    c,
    '3× close-up (left) · actual size on daylight, dusk and twilight (right)',
    const Offset(28, 54),
    15,
  );
  // (label, earlier hits, since last hit)
  const moments = [
    ('first hit · 40 ms', <int>[], .04),
    ('draining · 400 ms', <int>[10], .40),
    ('20 / 30 settled', <int>[], 2.0),
    ('10 / 30 settled', <int>[10], 2.0),
  ];
  const names = ['cave bat', 'spitter beetle', 'dusk moth', 'simple bat'];
  for (var kind = 0; kind < 4; kind++) {
    final top = 92.0 + kind * 250;
    _text(c, names[kind], Offset(28, top + 4), 16);
    for (var m = 0; m < moments.length; m++) {
      final (label, earlier, since) = moments[m];
      final cell = Rect.fromLTWH(24 + m * 280, top + 28, 268, 210);
      _panel(c, cell, m.isEven ? _day : _dusk);
      _text(c, label, cell.topLeft + const Offset(12, 8), 12);
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true);
      const h = 1080.0;
      final enemy = _hurt(
        maxHp: 30,
        hits: [...earlier, 10],
        since: since,
        x: 1.5,
        y: (cell.center.dy + 34) / h,
        appearance: kind,
        flightPhase: kind * 2.399963 + m * .7,
      );
      sim.enemies.add(enemy);
      sim.birdY = enemy.y;
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(cell, const Radius.circular(14)));
      c.translate(cell.center.dx - 1.5 * h, 0);
      CombatArt.paint(c, h, sim, reducedMotion: false);
      c.restore();
    }
    for (var s = 0; s < 3; s++) {
      final cell = Rect.fromLTWH(1150 + s * 200, top + 28, 188, 210);
      _panel(c, cell, [_day, _dusk, _night][s]);
      for (var m = 0; m < moments.length; m++) {
        final (_, earlier, since) = moments[m];
        const h = 360.0;
        final sim = FlightSimulation(rules: TapFlyMode(), practice: true);
        final enemy = _hurt(
          maxHp: 30,
          hits: [...earlier, 10],
          since: since,
          x: (cell.left + 50 + (m % 2) * 90) / h,
          y: (cell.top + 62 + (m ~/ 2) * 92) / h,
          appearance: kind,
          flightPhase: kind * 2.399963 + m * .7,
        );
        sim.enemies.add(enemy);
        sim.birdY = enemy.y;
        CombatArt.paint(c, h, sim, reducedMotion: false);
      }
    }
  }
}

/// Consecutive 30 fps frames at the real 360 px scale: a first hit at 0 s and
/// a second at .7 s, drawn through the in-game combat renderer.
void _motion(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  const cols = 15, cellW = 80.0, cellH = 100.0, h = 360.0;
  for (var f = 0; f < cols * 3; f++) {
    final t = f / 30;
    final cell = Rect.fromLTWH(
      (f % cols) * cellW,
      (f ~/ cols) * cellH + 12,
      cellW - 2,
      cellH - 2,
    );
    _panel(c, cell, (f ~/ cols).isOdd ? _dusk : _day);
    final enemy = SkyEnemy(
      x: 1.5,
      y: .5,
      appearance: 2,
      flightPhase: 1.3,
      maxHp: 30,
    )..age = 1;
    enemy.takeDamage(10);
    if (t >= .7) {
      enemy.age = 1.7;
      enemy.takeDamage(10);
    }
    enemy.age = 1 + t;
    final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
      ..enemies.add(enemy)
      ..birdY = .5;
    c.save();
    c.clipRect(cell);
    c.translate(cell.center.dx - 1.5 * h, cell.center.dy + 12 - .5 * h);
    CombatArt.paint(c, h, sim, reducedMotion: false);
    c.restore();
    _text(c, '${(t * 1000).round()}', cell.topLeft + const Offset(4, 2), 9);
  }
}

void _text(
  Canvas c,
  String text,
  Offset at,
  double size, {
  Color color = SkyColors.ink,
  FontWeight weight = FontWeight.w700,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: weight,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
}
