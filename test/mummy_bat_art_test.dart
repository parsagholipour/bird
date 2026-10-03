// The mummy bat's art contract (T2): the very signature of the simple bat's
// painter, the simple bat's pose envelope (x +-1.9 r, y +-1.2 r) in every
// pose, the same size class, determinism, Reduced Motion, the look of the
// eyes, the per-frame cost next to the simple bat's (no saveLayer, no blur,
// no clip), and the cache prewarm.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/enemy_designs/mummy_bat.dart';
import 'package:push_up_bird/game/enemy_designs/simple_bat.dart';

import 'neferhoo_art_support.dart' show OpCounter, measure;

typedef _Painter =
    void Function(
      Canvas c,
      double radius, {
      required double seconds,
      required bool reducedMotion,
      double lookY,
      double charge,
      double recoil,
    });

Future<Uint8List> _raster(
  void Function(Canvas) draw, {
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final pixels = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return pixels;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The one signature every enemy art shares: assignable both ways.
  const _Painter mummy = MummyBatArt.paint;
  const _Painter simple = SimpleBatArt.paint;

  // Painted bounds in hit-radius units of one pose.
  const r = 100.0, boxW = 600, boxH = 400;
  Future<Rect> bounds(
    _Painter painter,
    double seconds, {
    bool reduced = false,
    double lookY = 0,
    double charge = 0,
    double recoil = 0,
  }) async {
    final pixels = await _raster(
      (c) {
        c.translate(boxW / 2, boxH / 2);
        painter(
          c,
          r,
          seconds: seconds,
          reducedMotion: reduced,
          lookY: lookY,
          charge: charge,
          recoil: recoil,
        );
      },
      width: boxW,
      height: boxH,
    );
    var left = boxW, top = boxH, right = -1, bottom = -1;
    for (var y = 0; y < boxH; y++) {
      for (var x = 0; x < boxW; x++) {
        if (pixels[(y * boxW + x) * 4 + 3] > 8) {
          left = math.min(left, x);
          right = math.max(right, x + 1);
          top = math.min(top, y);
          bottom = math.max(bottom, y + 1);
        }
      }
    }
    return Rect.fromLTRB(
      (left - boxW / 2) / r,
      (top - boxH / 2) / r,
      (right - boxW / 2) / r,
      (bottom - boxH / 2) / r,
    );
  }

  test('stays inside the simple bat\'s pose envelope in every pose', () async {
    var union = Rect.zero;
    var minWidth = double.infinity, maxWidth = 0.0;
    for (var frame = 0; frame < 150; frame++) {
      final seconds = frame / 60;
      for (final (lookY, charge, recoil) in [
        (0.0, 0.0, 0.0),
        if (frame % 10 == 0) ...[(-1.0, 1.0, 0.0), (1.0, 0.0, 1.0)],
      ]) {
        final box = await bounds(
          mummy,
          seconds,
          lookY: lookY,
          charge: charge,
          recoil: recoil,
        );
        union = union == Rect.zero ? box : union.expandToInclude(box);
        if (charge == 0 && recoil == 0) {
          minWidth = math.min(minWidth, box.width);
          maxWidth = math.max(maxWidth, box.width);
        }
      }
    }
    final still = await bounds(mummy, 0, reduced: true);
    final report =
        'union L ${union.left} T ${union.top} R ${union.right} '
        'B ${union.bottom}; width $minWidth..$maxWidth; still ${still.width}';
    File('build/mummy-bat-bounds.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('$report\n');
    expect(union.left, greaterThanOrEqualTo(-1.9), reason: report);
    expect(union.right, lessThanOrEqualTo(1.9), reason: report);
    expect(union.top, greaterThanOrEqualTo(-1.2), reason: report);
    expect(union.bottom, lessThanOrEqualTo(1.2), reason: report);
    // The simple bat's size class: ~3.3-3.6 r wide.
    expect(maxWidth, inInclusiveRange(3.3, 3.62), reason: report);
    expect(still.width, inInclusiveRange(3.3, 3.62), reason: report);
  });

  test('is deterministic, tracks the bird and freezes', () async {
    Future<Uint8List> pose(
      double seconds, {
      bool reduced = false,
      double lookY = 0,
    }) => _raster(
      (c) {
        c.translate(100, 70);
        mummy(c, 40, seconds: seconds, reducedMotion: reduced, lookY: lookY);
      },
      width: 200,
      height: 140,
    );
    expect(await pose(1.37), await pose(1.37), reason: 'paused frame exact');
    expect(await pose(.2), isNot(equals(await pose(.45))), reason: 'flaps');
    expect(
      await pose(.2, reduced: true),
      await pose(3.9, reduced: true),
      reason: 'Reduced Motion freezes wings, bob, tail and blinks',
    );
    expect(
      await pose(0, reduced: true, lookY: -1),
      isNot(equals(await pose(0, reduced: true, lookY: 1))),
      reason: 'eyes follow the bird',
    );
  });

  test('flaps and glides on the simple bat\'s own rhythm', () async {
    expect(MummyBatArt.cycleSeconds, SimpleBatArt.cycleSeconds);
    // The wingtips (the widest point) move together: the two bats' widths
    // over a second agree frame by frame to a few percent.
    for (var i = 0; i < 40; i++) {
      final t = i / 30;
      final a = await bounds(mummy, t), b = await bounds(simple, t);
      expect(
        (a.width - b.width).abs(),
        lessThan(.08),
        reason: 'span at $t s: ${a.width} vs ${b.width}',
      );
    }
  });

  test('garbage in, nothing out (the shared painter guards)', () {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    for (final radius in [0.0, -3.0, double.nan, double.infinity]) {
      mummy(c, radius, seconds: 1, reducedMotion: false);
    }
    mummy(
      c,
      16,
      seconds: double.nan,
      reducedMotion: false,
      lookY: double.infinity,
      charge: double.nan,
      recoil: -4,
    );
    recorder.endRecording().dispose();
  });

  test('prewarm builds the caches, is pure and idempotent', () async {
    MummyBatArt.prewarm();
    MummyBatArt.prewarm();
    final first = await _raster(
      (c) => mummy(c, 40, seconds: .7, reducedMotion: false),
      width: 200,
      height: 140,
    );
    MummyBatArt.prewarm();
    final second = await _raster(
      (c) => mummy(c, 40, seconds: .7, reducedMotion: false),
      width: 200,
      height: 140,
    );
    expect(first, second, reason: 'prewarming changes nothing it paints');
    // A warm bat records in a few milliseconds.
    final sw = Stopwatch()..start();
    for (var i = 0; i < 200; i++) {
      final rec = ui.PictureRecorder();
      mummy(Canvas(rec), 16, seconds: i / 30, reducedMotion: false);
      rec.endRecording().dispose();
    }
    sw.stop();
    expect(sw.elapsedMilliseconds / 200, lessThan(2.0));
  });

  group('cost', () {
    final report = StringBuffer();
    tearDownAll(() {
      File('build/mummy-bat-budget.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(report.toString());
      // ignore: avoid_print
      print(report);
    });

    OpCounter count(_Painter painter, double t, {double charge = 0}) {
      return measure(
        (c) => painter(
          c,
          16.2,
          seconds: t,
          reducedMotion: false,
          lookY: .4,
          charge: charge,
        ),
      );
    }

    test('stays near the simple bat\'s cost; no layer, blur or clip', () {
      var worstMummy = 0, worstSimple = 0;
      for (final (label, t, charge) in const [
        ('flap', .2, 0.0),
        ('glide', 1.7, 0.0),
        ('blink', 2.17, 0.0),
        ('charge', .4, 1.0),
      ]) {
        final m = count(mummy, t, charge: charge);
        final s = count(simple, t, charge: charge);
        report.writeln(
          '$label  mummy ${m.draws} draws ${m.clips} clips '
          '${m.shaderDraws} shaders | simple ${s.draws} draws '
          '${s.clips} clips ${s.shaderDraws} shaders',
        );
        worstMummy = math.max(worstMummy, m.draws);
        worstSimple = math.max(worstSimple, s.draws);
        expect(m.layers, 0, reason: '$label: no saveLayer');
        expect(m.blurs, 0, reason: '$label: no blur');
        expect(m.clips, 0, reason: '$label: no clip');
        expect(m.pictures, 0);
        expect(
          m.counts.keys.where((k) => k.startsWith('UNFORWARDED')),
          isEmpty,
          reason: '$label: every call is counted',
        );
      }
      report.writeln('worst: mummy $worstMummy, simple $worstSimple');
      // Recording time per bat on this host (the UI-thread share), warm.
      double micros(_Painter painter) {
        for (var i = 0; i < 100; i++) {
          final rec = ui.PictureRecorder();
          painter(Canvas(rec), 16.2, seconds: i / 30, reducedMotion: false);
          rec.endRecording().dispose();
        }
        final sw = Stopwatch()..start();
        const n = 2000;
        for (var i = 0; i < n; i++) {
          final rec = ui.PictureRecorder();
          painter(
            Canvas(rec),
            16.2,
            seconds: i / 30,
            reducedMotion: false,
            lookY: .3,
          );
          rec.endRecording().dispose();
        }
        return sw.elapsedMicroseconds / n;
      }

      final mm = micros(mummy), ss = micros(simple);
      report.writeln(
        'record time per bat: mummy ${mm.toStringAsFixed(1)} us, simple ${ss.toStringAsFixed(1)} us',
      );
      expect(
        mm,
        lessThan(ss * 3 + 50),
        reason: 'recording cost stays in the simple bat\'s class',
      );
      // A trio next to Neferhoo: at most 1.5x the simple bat each.
      expect(worstMummy, lessThanOrEqualTo((worstSimple * 1.5).ceil()));
    });
  });
}
