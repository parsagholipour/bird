import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_ammo_art.dart';
import 'package:push_up_bird/game/boss_art.dart';
import 'package:push_up_bird/ui/theme.dart';

const _folder = 'build/visual-review/boss-polish/ammo';

/// Real sky palettes sampled from `SkyPalette` (top, horizon, hills).
const _skies = [
  ('day', Color(0xff8dd8eb), Color(0xffe9f5df), Color(0xff68b1a8)),
  ('dusk', Color(0xffaaa9e0), Color(0xffffdfc3), Color(0xff9e82b4)),
  ('twilight', Color(0xff485584), Color(0xffadb6da), Color(0xff626c9f)),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boss volleys in a real 800 x 360 phone frame', (tester) async {
    await tester.runAsync(() async {
      Directory(_folder).createSync(recursive: true);
      for (final kind in BossKind.values) {
        for (final enraged in [false, true]) {
          for (var sky = 0; sky < 3; sky++) {
            final recorder = ui.PictureRecorder();
            _inGame(Canvas(recorder), kind, sky, enraged: enraged);
            final picture = recorder.endRecording();
            final image = await picture.toImage(800, 360);
            final png = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List();
            File(
              '$_folder/in-game-${kind.name}-${_skies[sky].$1}'
              '${enraged ? '-fury' : ''}.png',
            ).writeAsBytesSync(png);
            image.dispose();
            picture.dispose();
          }
        }
      }
    });
  });
}

void _background(Canvas c, Rect r, int sky) {
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
  c.drawPath(
    Path()
      ..moveTo(r.left, r.bottom - r.height * .12)
      ..quadraticBezierTo(
        r.left + r.width * .4,
        r.bottom - r.height * .3,
        r.right,
        r.bottom - r.height * .1,
      )
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..close(),
    Paint()..color = land,
  );
}

/// The real phone frame: the boss drawn by the game, a live volley drawn by
/// [BossAmmoArt.shot] toward the bird's column.
void _inGame(Canvas c, BossKind kind, int sky, {required bool enraged}) {
  const size = Size(800, 360), h = 360.0;
  _background(c, Offset.zero & size, sky);
  final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
    ..phase = RunPhase.playing
    ..elapsed = 7.3
    ..birdY = .5;
  final boss = SkyBoss(
    number: 3,
    x: size.width / h - .42,
    kind: kind,
    cinematic: true,
  )..age = 7.3;
  if (enraged) {
    boss.hp = boss.maxHp ~/ 2;
    // Show the next shot charging at the muzzle as well.
    boss.fireIn = .15;
  }
  boss.volleys = 1;
  sim.boss = boss;
  BossArt.paint(c, size, sim, reducedMotion: false);
  final aim = math.atan2(sim.birdY - boss.y, FlightSimulation.birdX - boss.x);
  final speed = boss.projectileSpeed;
  for (final (i, travel) in [.35, .95].indexed) {
    for (final offset in boss.volleyOffsets) {
      final a = aim + offset;
      BossAmmoArt.shot(
        c,
        h,
        BossAmmo(
          x: boss.muzzleX + math.cos(a) * travel,
          y: boss.y + math.sin(a) * travel,
          vx: math.cos(a) * speed,
          vy: math.sin(a) * speed,
        ),
        boss,
        seconds: sim.elapsed + i * .4,
        reducedMotion: false,
      );
    }
  }
  // The bird's position and size, for scale.
  final bird = Offset(FlightSimulation.birdX * h, sim.birdY * h);
  c.drawCircle(bird, h * .035, Paint()..color = SkyColors.yellow);
  c.drawCircle(
    bird,
    h * .035,
    Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}
