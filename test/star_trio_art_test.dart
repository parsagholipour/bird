import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/star_trio_art.dart';

Future<List<int>> pixels(
  StarTrio trio,
  double seconds, {
  bool reduced = false,
}) async {
  final recorder = ui.PictureRecorder();
  StarTrioArt.paint(
    Canvas(recorder),
    360,
    trio,
    seconds: seconds,
    reducedMotion: reduced,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(360, 220);
  final bytes = await image.toByteData();
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'trio art distinguishes approach, partial, missed and complete sets',
    () async {
      final trio = StarTrio(x: .5, y: .35);
      final waiting = await pixels(trio, 0);
      expect(await pixels(trio, 20), waiting);
      trio.collectedMask = 1;
      final partial = await pixels(trio, 0);
      expect(partial, isNot(equals(waiting)));
      trio.missed = true;
      expect(await pixels(trio, 0), isNot(equals(partial)));
      trio.missed = false;
      trio.collectedMask = 7;
      trio.completedAt = 10;
      expect(await pixels(trio, 10.3), isNot(equals(partial)));
    },
  );

  test(
    'constellations replay exactly, settle, expire and honor Reduced Motion',
    () async {
      final trio = StarTrio(x: .5, y: .35)..completedAt = 10;
      final first = await pixels(trio, 10.05);
      final middle = await pixels(trio, 10.4);
      expect(middle, isNot(equals(first)));
      expect(
        await pixels(trio, 10.05),
        first,
        reason: 'A backwards seek must reconstruct the same pose',
      );
      expect(
        await pixels(trio, 10.05, reduced: true),
        await pixels(trio, 10.8, reduced: true),
      );
      for (final reduced in [true, false]) {
        final ended = await pixels(trio, 12, reduced: reduced);
        expect(ended.every((b) => b == 0), isTrue);
        expect(await pixels(trio, 20, reduced: reduced), ended);
        expect(await pixels(trio, 9, reduced: reduced), ended);
      }
    },
  );
}
