import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/steam_geyser_art.dart';
import 'package:push_up_bird/game/steam_geyser_emitter_art.dart';

import 'steam_geyser_scenes.dart';

/// The Steam Geysers' design pass (rounds 1 and 2): hot against cool by value
/// as well as by hue, a sudden bang, a warning that is whole from the first
/// moments (a hazard-taped column for a scald, a dotted dome and a funnel for
/// a lift), a tall open-ink billow, and a ride vent that is cool in every
/// pixel of its burst. Through the real painter on a transparent canvas.
const _h = 360.0, _w = 800.0;

Future<Uint8List> _pixels(
  VentSpec v,
  double tau, {
  bool reduced = true,
  double clock = 3.3,
}) async {
  const route = 50.0;
  final recorder = ui.PictureRecorder();
  SteamGeyserArt.paintVent(
    ui.Canvas(recorder),
    _h,
    v.x * _h,
    makeVent((x: v.x, top: v.top, kind: v.kind, tau: tau, slot: v.slot), route),
    route,
    clock,
    reduced,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(_w.toInt(), _h.toInt());
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return Uint8List.fromList(bytes);
}

/// Mean luminance (0 to 1) and mean (red - blue) of the opaque pixels in the
/// plume's middle, inside its ink.
(double, double) _body(Uint8List px, VentSpec v) {
  var y = 0.0, rb = 0.0, n = 0;
  final cx = (v.x * _h).round();
  for (
    var row = ((v.top + .10) * _h).round();
    row < ((v.top + .20) * _h).round();
    row++
  ) {
    for (var x = cx - 30; x < cx + 30; x++) {
      final i = (row * _w.toInt() + x) * 4;
      if (px[i + 3] < 250) continue;
      y += (.2126 * px[i] + .7152 * px[i + 1] + .0722 * px[i + 2]) / 255;
      rb += px[i] - px[i + 2];
      n++;
    }
  }
  return (y / n, rb / n);
}

int _opaque(Uint8List px, int x0, int y0, int x1, int y1, [int min = 200]) {
  var n = 0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      if (px[(y * _w.toInt() + x) * 4 + 3] > min) n++;
    }
  }
  return n;
}

/// The silhouette's rows: top, and the widest row, of pixels over 128 alpha
/// above the lid.
({int top, int bottom, int widest}) _extent(Uint8List px, int cx, int lip) {
  var top = 9999, widest = 0;
  for (var y = 0; y < lip - 12; y++) {
    var lo = 9999, hi = -1;
    for (var x = cx - 150; x < cx + 150; x++) {
      if (px[(y * _w.toInt() + x) * 4 + 3] > 128) {
        if (x < lo) lo = x;
        if (x > hi) hi = x;
      }
    }
    if (hi >= 0) {
      if (y < top) top = y;
      if (hi - lo + 1 > widest) widest = hi - lo + 1;
    }
  }
  return (top: top, bottom: lip - 12, widest: widest);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final hop = spec(1.2, .52, 0, slot: 12);
  final hopMid = spec(1.2, .58, 0, slot: 12);
  final ride = spec(1.2, .56, 0, kind: SteamKind.ride, slot: 4);

  testWidgets('hot steam is brighter than cool steam, not only warmer', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final (hotY, hotRB) = _body(await _pixels(hop, .3), hop);
      final (coolY, coolRB) = _body(await _pixels(hop, 1.0), hop);
      expect(hotY - coolY, greaterThan(.05), reason: 'value, for greyscale');
      expect(hotRB - coolRB, greaterThan(40), reason: 'hue, for colour');
    });
  });

  testWidgets('a ride vent is cool in every pixel of its burst and billow', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Anything warm (red well over blue) anywhere on the canvas above the
      // coping: sparks, glow, flash, shock ring, drops, the lid, the grate.
      // The brick block and the red wheel below the coping are the roof's own.
      final roof = ((SteamEmitterArt.slab - .012) * _h).round();
      var warmest = 0;
      for (final reduced in [true, false]) {
        for (var tau = .0; tau < 1.75; tau += .03) {
          final px = await _pixels(
            ride,
            tau,
            reduced: reduced,
            clock: 3.3 + tau,
          );
          var warm = 0;
          for (var y = 0; y < roof; y++) {
            for (var x = 0; x < _w.toInt(); x++) {
              final i = (y * _w.toInt() + x) * 4;
              if (px[i + 3] > 30 && px[i] - px[i + 2] > 60) warm++;
            }
          }
          if (warm > warmest) warmest = warm;
          expect(
            warm,
            0,
            reason:
                'ride burst/billow at $tau (reduced=$reduced) has warm pixels',
          );
        }
      }
      expect(warmest, 0);
      // ...while the same test on a hop vent finds them: it has teeth.
      var hotWarm = 0;
      final px = await _pixels(hop, .2, reduced: false);
      for (var y = 0; y < roof; y++) {
        for (var x = 0; x < _w.toInt(); x++) {
          final i = (y * _w.toInt() + x) * 4;
          if (px[i + 3] > 30 && px[i] - px[i + 2] > 60) hotWarm++;
        }
      }
      expect(hotWarm, greaterThan(300));
    });
  });

  testWidgets('a ride burst and a hop burst have different silhouettes', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final cx = (hop.x * _h).round();
      final lip = (_h * .915).round();
      // Widest over narrowest row between the crown and the foot: the jet is
      // a mushroom (a head much wider than its neck); the lift a column.
      double mushroom(Uint8List px, int topY) {
        var most = 0, least = 9999;
        for (var y = topY + 14; y < lip - 40; y++) {
          var lo = 9999, hi = -1;
          for (var x = cx - 150; x < cx + 150; x++) {
            if (px[(y * _w.toInt() + x) * 4 + 3] > 128) {
              if (x < lo) lo = x;
              if (x > hi) hi = x;
            }
          }
          final w = hi - lo + 1;
          if (w > most) most = w;
          if (w < least) least = w;
        }
        return most / least;
      }

      final rideMid = spec(1.2, .58, 0, kind: SteamKind.ride, slot: 4);
      final top = (.58 * _h).round();
      final a = mushroom(await _pixels(hopMid, .30), top);
      final b = mushroom(await _pixels(rideMid, .30), top);
      expect(a, greaterThan(b + .15), reason: 'jet $a vs lift $b');
    });
  });

  testWidgets('the bang is sudden: the lid blazes on the first frame', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final cx = (hop.x * _h).round();
      final lip = (_h * .915).round();
      final before = await _pixels(hop, -.01, reduced: false);
      final px = await _pixels(hop, .01, reduced: false);
      // Mist spreads along the roof past the lid's edges at once.
      int mist(Uint8List p) {
        var n = 0;
        for (var y = lip - 24; y < lip; y++) {
          for (final side in const [-1, 1]) {
            for (var d = (.09 * _h).round(); d < (.15 * _h).round(); d++) {
              final i = (y * _w.toInt() + cx + side * d) * 4;
              if (p[i + 3] > 200 && p[i] > 205 && p[i + 1] > 200) n++;
            }
          }
        }
        return n;
      }

      expect(mist(px), greaterThan(mist(before) + 40), reason: 'mist');
      final i = ((lip - (.014 * _h).round()) * _w.toInt() + cx) * 4;
      expect(px[i], greaterThan(235));
      expect(px[i + 1], greaterThan(235));
      expect(px[i + 2], greaterThan(235), reason: 'white-hot glare');
    });
  });

  testWidgets('the warning is whole from the first tenth of the hiss', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final half = (.072 * _h).round();
      for (final v in [hop, ride]) {
        final cx = (v.x * _h).round();
        final topY = (v.top * _h).round();
        for (final tau in const [-1.38, -.8, -.05]) {
          final px = await _pixels(v, tau);
          if (v.kind == SteamKind.hop) {
            // Solid walls and the hazard cap on the hit top.
            final wall = _opaque(
              px,
              cx - half - 4,
              topY + 20,
              cx - half + 4,
              topY + 90,
            );
            expect(wall, greaterThan(100), reason: 'hop wall at $tau');
            final cap = _opaque(px, cx - half, topY - 3, cx + half, topY + 8);
            expect(cap, greaterThan(250), reason: 'hop cap at $tau');
          } else {
            // A ride vent has no outline: the dotted dome tops the reach and
            // nothing opaque runs down the sides.
            final dome = _opaque(px, cx - half, topY - 3, cx + half, topY + 24);
            expect(dome, greaterThan(150), reason: 'ride dome at $tau');
            final side = _opaque(
              px,
              cx - half - 3,
              topY + 50,
              cx - half + 3,
              topY + 110,
            );
            expect(side, lessThan(40), reason: 'no ride wall at $tau');
          }
        }
      }
    });
  });

  testWidgets('a scald has a flat hazard bar, a lift a rounded dotted dome', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final topHop = (hop.top * _h).round();
      final topRide = (ride.top * _h).round();
      final cxh = (hop.x * _h).round(), cxr = (ride.x * _h).round();
      final bar = _opaque(
        await _pixels(hop, -.4),
        cxh - 40,
        topHop - 1,
        cxh + 40,
        topHop + 5,
      );
      final dome = _opaque(
        await _pixels(ride, -.4),
        cxr - 40,
        topRide - 1,
        cxr + 40,
        topRide + 5,
      );
      expect(bar, greaterThan(dome + 120), reason: 'bar vs dome apex');
    });
  });

  testWidgets('the billow is tall, leans, and keeps its ink on the shade side', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final cx = (hopMid.x * _h).round();
      final lip = (_h * .915).round();
      final px = await _pixels(hopMid, 1.0);
      final e = _extent(px, cx, lip);
      expect(
        (e.bottom - e.top) / e.widest,
        greaterThan(1.3),
        reason: 'taller than wide',
      );
      // Ink (dark navy) is on the lower left and the base, not the upper right.
      final mid = (e.top + e.bottom) ~/ 2;
      int ink(int x0, int y0, int x1, int y1) {
        var n = 0;
        for (var y = y0; y < y1; y++) {
          for (var x = x0; x < x1; x++) {
            final i = (y * _w.toInt() + x) * 4;
            if (px[i + 3] > 200 &&
                px[i] < 70 &&
                px[i + 1] < 70 &&
                px[i + 2] < 90) {
              n++;
            }
          }
        }
        return n;
      }

      final upperRight = ink(cx, e.top - 4, cx + 90, mid);
      final lowerLeft = ink(cx - 90, mid, cx, e.bottom);
      expect(lowerLeft, greaterThan(upperRight * 2 + 20));
    });
  });

  testWidgets('the lid is lit from under when it kicks up', (tester) async {
    await tester.runAsync(() async {
      final px = await _pixels(hop, .05);
      final cx = (hop.x * _h).round();
      final y = (SteamEmitterArt.slab * _h).round() - 8;
      var warm = 0;
      for (var yy = y - 6; yy < y + 6; yy++) {
        for (var x = cx - 40; x < cx + 40; x++) {
          final i = (yy * _w.toInt() + x) * 4;
          if (px[i + 3] > 200 && px[i] > 200 && px[i] - px[i + 2] > 60) warm++;
        }
      }
      expect(warm, greaterThan(4));
    });
  });
}
