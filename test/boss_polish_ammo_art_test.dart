import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_ammo_art.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/ui/theme.dart';

const _folder = 'build/visual-review/boss-polish/ammo';

/// Real sky palettes sampled from `SkyPalette` (top, horizon, hills).
const _skies = [
  ('DAYLIGHT', Color(0xff8dd8eb), Color(0xffe9f5df), Color(0xff68b1a8)),
  ('DUSK', Color(0xffaaa9e0), Color(0xffffdfc3), Color(0xff9e82b4)),
  ('TWILIGHT', Color(0xff485584), Color(0xffadb6da), Color(0xff626c9f)),
];

const _kinds = BossKind.values;

String _label(BossKind kind) => switch (kind) {
  BossKind.baronBat => 'Baron Bat · ember shot',
  BossKind.spitterBeetle => 'Spitter King · acid globule',
  BossKind.duskMoth => 'Dusk Empress · pollen rosette',
};

double _speed(BossKind kind, bool enraged) =>
    SkyBoss(number: 3, x: 1, kind: kind).projectileSpeed * (enraged ? 1.2 : 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boss ammo review sheets', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      Directory(_folder).createSync(recursive: true);
      await _raster((c) => _sheet(c, 1.1), 'ammo-sheet', 1400, 1040);
      await _raster(
        (c) => _flightStrip(c, 1.0),
        'ammo-flight-strip',
        1400,
        700,
      );
      await _raster(
        (c) => _flightStrip(c, 1.0, reduced: true),
        'ammo-flight-strip-reduced',
        1400,
        700,
      );
      await _raster(_headings, 'ammo-headings', 1400, 760);
      await _phoneZoom();
    });
  });

  testWidgets('boss ammo is deterministic, animated, and still when reduced', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final kind in _kinds) {
        for (final enraged in [false, true]) {
          Future<List<int>> frame(double seconds, {bool reduced = false}) =>
              _raster(
                (c) => BossAmmoArt.paint(
                  c,
                  center: const Offset(120, 60),
                  radius: 7.56,
                  direction: math.pi - .2,
                  attack: EnemyAttack.none,
                  kind: kind,
                  enraged: enraged,
                  speed: _speed(kind, enraged),
                  seconds: seconds,
                  reducedMotion: reduced,
                ),
                null,
                200,
                120,
              );
          final first = await frame(2);
          expect(await frame(2), first, reason: '$kind is exact when paused');
          expect(
            await frame(2.13),
            isNot(equals(first)),
            reason: '$kind animates',
          );
          final still = await frame(2, reduced: true);
          expect(
            await frame(7.9, reduced: true),
            still,
            reason: '$kind holds one pose under Reduced Motion',
          );
        }
      }
      // The three bosses never share a look.
      final looks = <List<int>>[];
      for (final kind in _kinds) {
        looks.add(
          await _raster(
            (c) => BossAmmoArt.paint(
              c,
              center: const Offset(120, 60),
              radius: 7.56,
              direction: math.pi,
              attack: EnemyAttack.none,
              kind: kind,
              seconds: 0,
              reducedMotion: true,
            ),
            null,
            200,
            120,
          ),
        );
      }
      expect(looks[0], isNot(equals(looks[1])));
      expect(looks[1], isNot(equals(looks[2])));
      expect(looks[0], isNot(equals(looks[2])));
    });
  });

  testWidgets('solid body ends on the hit circle', (tester) async {
    await tester.runAsync(() async {
      // A shot heading straight up leaves its wake below; nothing opaque may
      // reach sideways past the hit circle plus antialiasing.
      const r = 40.0, size = 200;
      for (final kind in _kinds) {
        final pixels = await _raster(
          (c) => BossAmmoArt.paint(
            c,
            center: const Offset(100, 100),
            radius: r,
            direction: 0,
            attack: EnemyAttack.none,
            kind: kind,
            seconds: 1.3,
            reducedMotion: false,
            showTrail: false,
          ),
          null,
          size,
          size,
        );
        // Ahead of the shot (x > center + r + 2): only the translucent halo.
        for (var x = 100 + r.toInt() + 3; x < size; x++) {
          final alpha = pixels[(100 * size + x) * 4 + 3];
          expect(alpha, lessThan(200), reason: '$kind opaque at x=$x');
        }
        // Just inside the leading edge the ink rim is solid (the rosette's
        // notches between petals sit at ~.8 of the radius).
        final inset = kind == BossKind.duskMoth ? (r * .25).toInt() : 3;
        expect(
          pixels[(100 * size + 100 + r.toInt() - inset) * 4 + 3],
          255,
          reason: '$kind rim',
        );
      }
    });
  });

  test('legacy attack mapping keeps existing callers working', () {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    for (final attack in EnemyAttack.values) {
      BossAmmoArt.paint(
        c,
        center: Offset.zero,
        radius: 10,
        direction: math.pi,
        attack: attack,
        seconds: 1,
        reducedMotion: false,
      );
    }
    BossAmmoArt.paint(
      c,
      center: Offset.zero,
      radius: double.nan,
      direction: math.pi,
      attack: EnemyAttack.aimed,
      seconds: double.infinity,
      reducedMotion: false,
    );
    recorder.endRecording().dispose();
  });
}

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

Future<List<int>> _raster(
  void Function(Canvas) draw,
  String? name,
  int width,
  int height,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final pixels = (await image.toByteData())!.buffer.asUint8List();
  if (name != null) {
    final png = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    File('$_folder/$name.png').writeAsBytesSync(png);
  }
  image.dispose();
  picture.dispose();
  return pixels;
}

void _text(
  Canvas c,
  String text,
  Offset at,
  double size, {
  Color color = SkyColors.ink,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
}

void _background(Canvas c, Rect r, int sky, {bool hills = true}) {
  final (_, top, horizon, land) = _skies[sky];
  c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, horizon],
      ).createShader(r),
  );
  if (!hills) return;
  final base = r.bottom;
  c.drawPath(
    Path()
      ..moveTo(r.left, base - r.height * .18)
      ..quadraticBezierTo(
        r.left + r.width * .3,
        base - r.height * .42,
        r.left + r.width * .62,
        base - r.height * .2,
      )
      ..quadraticBezierTo(
        r.left + r.width * .82,
        base - r.height * .06,
        r.right,
        base - r.height * .25,
      )
      ..lineTo(r.right, base)
      ..lineTo(r.left, base)
      ..close(),
    Paint()..color = land,
  );
}

void _hitCircle(Canvas c, Offset center, double radius) {
  c.drawCircle(
    center,
    radius,
    Paint()
      ..color = const Color(0xffe0187a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
}

void _shot(
  Canvas c,
  BossKind kind,
  Offset at,
  double radius, {
  double direction = math.pi,
  bool enraged = false,
  double seconds = 1.1,
  bool reduced = false,
}) => BossAmmoArt.paint(
  c,
  center: at,
  radius: radius,
  direction: direction,
  attack: EnemyAttack.none,
  kind: kind,
  enraged: enraged,
  speed: _speed(kind, enraged),
  seconds: seconds,
  reducedMotion: reduced,
);

void _sheet(Canvas c, double seconds) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(c, 'BOSS AMMO', const Offset(28, 18), 28);
  _text(
    c,
    'Close-up (hit circle in magenta) · fury · small-enemy relative · '
    'gameplay size (360 px high) on real sky palettes',
    const Offset(28, 56),
    15,
  );
  for (var row = 0; row < 3; row++) {
    final kind = _kinds[row];
    final top = 92.0 + row * 316;
    final panel = Rect.fromLTWH(24, top, 820, 300);
    c.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(20)),
      Paint()..color = SkyColors.cream,
    );
    _text(c, _label(kind), Offset(44, top + 12), 20);
    const r = 30.0;
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(panel, const Radius.circular(20)));
    _shot(c, kind, Offset(90, top + 140), r, seconds: seconds);
    _shot(c, kind, Offset(350, top + 140), r, seconds: seconds);
    _hitCircle(c, Offset(350, top + 140), r);
    _shot(c, kind, Offset(610, top + 140), r, seconds: seconds, enraged: true);
    // The small-enemy sibling at the same detail scale for comparison.
    if (kind != BossKind.baronBat) {
      final detail = r / BossAmmo.radius;
      EnemyArt.ammo(
        c,
        detail,
        EnemyAmmo(
          x: 640 / detail,
          y: (top + 250) / detail,
          vx: -.4,
          vy: 0,
          attack: kind == BossKind.spitterBeetle
              ? EnemyAttack.aimed
              : EnemyAttack.fan,
        ),
        seconds: seconds,
        reducedMotion: false,
      );
      _text(c, 'SMALL', Offset(560, top + 244), 11, color: SkyColors.purple);
    }
    c.restore();
    _text(c, 'IN FLIGHT', Offset(60, top + 190), 11, color: SkyColors.purple);
    _text(c, 'HIT CIRCLE', Offset(316, top + 190), 11, color: SkyColors.purple);
    _text(c, 'FURY', Offset(592, top + 190), 11, color: SkyColors.purple);
    // Gameplay size on each sky.
    for (var sky = 0; sky < 3; sky++) {
      final tile = Rect.fromLTWH(860 + sky * 176.0, top, 168, 300);
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(tile, const Radius.circular(14)));
      _background(c, tile, sky, hills: false);
      const h = 360.0, pr = h * BossAmmo.radius;
      for (var i = 0; i < 3; i++) {
        final a = (i - 1) * .3;
        _shot(
          c,
          kind,
          tile.topLeft + Offset(70 - math.cos(a) * 10, 70 + i * 44),
          pr,
          direction: math.pi + a,
          seconds: seconds + i * .1,
        );
      }
      _shot(
        c,
        kind,
        tile.topLeft + const Offset(80, 250),
        pr,
        enraged: true,
        seconds: seconds,
      );
      _text(
        c,
        _skies[sky].$1,
        tile.topLeft + const Offset(8, 6),
        10,
        color: sky == 2 ? SkyColors.cream : SkyColors.ink,
      );
      c.restore();
    }
  }
}

void _flightStrip(Canvas c, double start, {bool reduced = false}) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'FLIGHT · 1/30 s PER FRAME${reduced ? ' · REDUCED MOTION' : ''}',
    const Offset(24, 14),
    20,
  );
  for (var row = 0; row < 3; row++) {
    final kind = _kinds[row];
    for (var f = 0; f < 8; f++) {
      final cell = Rect.fromLTWH(20 + f * 172.0, 52 + row * 214.0, 164, 204);
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(cell, const Radius.circular(10)));
      _background(c, cell, row, hills: false);
      final t = start + f / 30;
      _shot(
        c,
        kind,
        cell.topLeft + const Offset(40, 72),
        22,
        seconds: t,
        reduced: reduced,
        enraged: f >= 6,
      );
      _shot(
        c,
        kind,
        cell.topLeft + const Offset(40, 168),
        360 * BossAmmo.radius,
        seconds: t,
        reduced: reduced,
      );
      if (f >= 6) {
        _text(c, 'FURY', cell.topLeft + const Offset(8, 6), 10);
      }
      c.restore();
    }
  }
}

/// Real phone pixels, magnified ×4 without smoothing: what a player
/// actually sees of each shot on each sky.
Future<void> _phoneZoom() async {
  const cellW = 90, cellH = 40, zoom = 4;
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  for (var row = 0; row < 6; row++) {
    final kind = _kinds[row ~/ 2];
    final enraged = row.isOdd;
    for (var sky = 0; sky < 3; sky++) {
      final cell = Rect.fromLTWH(
        sky * cellW.toDouble(),
        row * cellH.toDouble(),
        cellW.toDouble(),
        cellH.toDouble(),
      );
      c.save();
      c.clipRect(cell);
      _background(c, cell, sky, hills: false);
      _shot(
        c,
        kind,
        cell.centerLeft + const Offset(22, 0),
        360 * BossAmmo.radius,
        direction: math.pi - .15,
        enraged: enraged,
        seconds: 1.37,
      );
      c.restore();
    }
  }
  final picture = recorder.endRecording();
  final small = await picture.toImage(cellW * 3, cellH * 6);
  final big = ui.PictureRecorder();
  Canvas(big).drawImageRect(
    small,
    Offset.zero & Size(small.width.toDouble(), small.height.toDouble()),
    Offset.zero & Size(small.width * zoom * 1.0, small.height * zoom * 1.0),
    Paint()..filterQuality = FilterQuality.none,
  );
  await _raster(
    (canvas) => canvas.drawPicture(big.endRecording()),
    'ammo-phone-pixels-x4',
    small.width * zoom,
    small.height * zoom,
  );
  small.dispose();
  picture.dispose();
}

/// A whole volley at gameplay size fanning out toward the bird, both
/// normal and in fury, with the real per-boss offsets and speeds.
void _headings(Canvas c) {
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'VOLLEYS AT GAMEPLAY SIZE · normal | fury',
    const Offset(24, 14),
    20,
  );
  for (var row = 0; row < 3; row++) {
    final kind = _kinds[row];
    for (var col = 0; col < 2; col++) {
      final enraged = col == 1;
      final cell = Rect.fromLTWH(20 + col * 690.0, 52 + row * 236.0, 670, 226);
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(cell, const Radius.circular(12)));
      _background(c, cell, row, hills: false);
      final boss = SkyBoss(number: 3, x: 1, kind: kind);
      if (enraged) boss.hp = boss.maxHp ~/ 2;
      boss.volleys = 1;
      final muzzle = cell.topLeft + Offset(cell.width - 40, cell.height / 2);
      for (final offset in boss.volleyOffsets) {
        final a = math.pi + offset;
        for (final d in [120.0, 300.0, 480.0]) {
          final at = muzzle + Offset(math.cos(a), math.sin(a)) * d;
          _shot(
            c,
            kind,
            at,
            360 * BossAmmo.radius,
            direction: a,
            enraged: enraged,
            seconds: 1.3 + d / 900,
          );
        }
      }
      _text(
        c,
        '${_label(kind)}${enraged ? ' · FURY' : ''}',
        cell.topLeft + const Offset(10, 6),
        11,
        color: row == 2 ? SkyColors.cream : SkyColors.ink,
      );
      c.restore();
    }
  }
}
