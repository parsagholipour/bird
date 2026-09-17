import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/courier_art.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/ui/theme.dart';

FlightSimulation handoffFlight(FlightEventKind kind, double age) =>
    FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: true,
        course: FlightCourse.skyCourier,
      )
      ..started = true
      ..phase = RunPhase.playing
      ..birdY = .5
      ..carryingLetter = kind == FlightEventKind.letter
      ..elapsed = 10 + age
      ..distance = 5 + age * .27
      ..events.add(FlightEvent(kind, 10, .5, gateWorldX: 5.36, gateY: .5));

Future<List<int>> pixels(FlightSimulation sim, {bool reduced = false}) async {
  final recorder = ui.PictureRecorder();
  CourierArt.handoff(Canvas(recorder), 360, sim, reducedMotion: reduced);
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 360);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'handoffs are finite, deterministic and suppressed in Reduced Motion',
    () async {
      final empty = await pixels(handoffFlight(FlightEventKind.delivery, 2));
      for (final kind in [FlightEventKind.letter, FlightEventKind.delivery]) {
        final middle = await pixels(handoffFlight(kind, .3));
        expect(middle, isNot(equals(empty)));
        expect(await pixels(handoffFlight(kind, .3)), middle);
        expect(await pixels(handoffFlight(kind, .5)), isNot(equals(middle)));
        expect(await pixels(handoffFlight(kind, .3), reduced: true), empty);
        expect(await pixels(handoffFlight(kind, 1.4)), empty);
      }
      expect(
        await pixels(handoffFlight(FlightEventKind.delivery, 1)),
        isNot(equals(empty)),
      );
      expect(await pixels(handoffFlight(FlightEventKind.letter, 1)), empty);
    },
  );

  test(
    'pickup hides the carried letter only while it arrives; drops cancel it',
    () async {
      final sim = handoffFlight(FlightEventKind.letter, .3);
      expect(CourierArt.collecting(sim, reducedMotion: false), isTrue);
      expect(CourierArt.collecting(sim, reducedMotion: true), isFalse);
      final before = await pixels(sim);
      sim.takeBreak();
      sim.tick(.2, 11000);
      expect(await pixels(sim), before);
      sim.events.add(
        FlightEvent(FlightEventKind.letterLost, sim.elapsed, sim.birdY),
      );
      expect(CourierArt.collecting(sim, reducedMotion: false), isFalse);
      expect(
        await pixels(sim),
        await pixels(handoffFlight(FlightEventKind.letter, 2)),
      );
      expect(
        CourierArt.collecting(
          handoffFlight(FlightEventKind.letter, .7),
          reducedMotion: false,
        ),
        isFalse,
      );
    },
  );

  test('a completed postbox looks different from an empty pass', () async {
    Future<List<int>> station(bool handled) async {
      final recorder = ui.PictureRecorder();
      CourierArt.station(
        Canvas(recorder),
        const Offset(100, 100),
        500,
        CourierStop.postbox,
        carrying: false,
        handled: handled,
        showLabel: false,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 200);
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
      return bytes;
    }

    expect(await station(true), isNot(equals(await station(false))));
    if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(SkyColors.sky, BlendMode.src);
    for (final (column, age) in [.10, .36, .90].indexed) {
      canvas.save();
      canvas.translate(column * 300, 0);
      final sim = handoffFlight(FlightEventKind.delivery, age);
      const h = 440.0;
      CourierArt.station(
        canvas,
        Offset((5.36 - sim.distance) * h, .5 * h),
        h,
        CourierStop.postbox,
        carrying: true,
        handled: age >= .65,
        showLabel: false,
      );
      BirdPuppet.paint(
        canvas,
        const Rect.fromLTWH(179, 194, 64, 56),
        bird: 1,
        wing: .1,
      );
      CourierArt.handoff(canvas, h, sim, reducedMotion: false);
      final text = TextPainter(
        text: TextSpan(
          text: ['Letter away', 'On its way', 'Delivered with love'][column],
          style: bodyText(17),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset((300 - text.width) / 2, 305));
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(900, 360);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/visual-review').create(recursive: true);
    await File(
      'build/visual-review/courier-handoffs.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
