import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/obstacle_art.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'boss_fight_test.dart' show hover;
import 'touch_combat_test.dart' show playing;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
  });

  for (final reduced in [false, true]) {
    test(
      'the rendered stone survives impact and follows its fall ($reduced)',
      () async {
        final sim = playing();
        final obstacle = Obstacle(x: 1.4, center: .65, gap: .3);
        sim.obstacles.add(obstacle);
        final rock = BirdRock(x: 1.16, y: .3, charge: .8);
        sim.rocks.add(rock);
        const times = [0.0, .12, .38, .78];
        final montage = ui.PictureRecorder();
        final canvas = Canvas(montage);
        for (var frame = 0; frame < times.length; frame++) {
          if (frame > 0) hover(sim, times[frame] - times[frame - 1]);
          expect(sim.rocks, contains(rock));
          if (frame > 0) expect(rock.rebounding, isTrue);
          final recorder = ui.PictureRecorder();
          CombatArt.paint(Canvas(recorder), 360, sim, reducedMotion: reduced);
          final picture = recorder.endRecording();
          final image = await picture.toImage(640, 360);
          final bytes = (await image.toByteData())!.buffer.asUint8List();
          final x = (rock.x * 360).round(), y = (rock.y * 360).round();
          expect(
            bytes[(y * 640 + x) * 4 + 3],
            greaterThan(0),
            reason: 'The stone must be drawn at its simulated position',
          );

          canvas.save();
          canvas.translate((frame % 2) * 640.0, (frame ~/ 2) * 390.0);
          canvas.clipRect(const Rect.fromLTWH(0, 0, 640, 390));
          canvas.drawColor(SkyColors.sky, BlendMode.srcOver);
          final label = TextPainter(
            text: TextSpan(
              text: '${(times[frame] * 1000).round()} ms',
              style: const TextStyle(
                color: SkyColors.ink,
                fontSize: 16,
                fontFamily: 'Nunito',
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(canvas, const Offset(14, 7));
          label.dispose();
          canvas.translate(0, 30);
          ObstacleArt.paint(
            canvas,
            obstacle,
            360,
            seconds: sim.elapsed,
            reducedMotion: reduced,
            cleared: false,
            perfect: false,
          );
          canvas.drawImage(image, Offset.zero, Paint());
          canvas.restore();
          image.dispose();
          picture.dispose();
        }
        final picture = montage.endRecording();
        if (const bool.fromEnvironment('CAPTURE_ROCK_BOUNCE')) {
          final image = await picture.toImage(1280, 780);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'build/visual-review/rock-bounce${reduced ? '-reduced' : ''}.png',
          );
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        }
        picture.dispose();
      },
    );
  }
}
