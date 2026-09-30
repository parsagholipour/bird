import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/ui/components.dart';

/// Regenerates the UI portraits in assets/images/ from the vector puppets, so
/// menus show exactly the bird that flies:
///
///     flutter test test/bird_portrait_export_test.dart \
///       --dart-define=EXPORT_BIRD_PORTRAITS=true
///
/// Pip's portrait is the original raster artwork and is never rewritten.
const _export = bool.fromEnvironment('EXPORT_BIRD_PORTRAITS');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'export bird portraits',
    () async {
      for (var bird = 1; bird < birdAssets.length; bird++) {
        final recorder = ui.PictureRecorder();
        BirdPuppet.paint(
          Canvas(recorder),
          const Rect.fromLTWH(0, 0, 512, 448),
          bird: bird,
          wing: 0,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(512, 448);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'assets/images/${birdAssets[bird]}.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    },
    skip: _export ? false : 'Pass --dart-define=EXPORT_BIRD_PORTRAITS=true',
  );
}
