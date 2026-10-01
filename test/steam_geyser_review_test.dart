@Timeout(Duration(minutes: 5))
library;

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'steam_geyser_scenes.dart';

/// Review renders of the steam geysers over the real New York backdrop (and
/// a bright one), written to `build/visual-review/steam-geyser/`:
///
///   flutter test test/steam_geyser_review_test.dart \
///     --dart-define=CAPTURE_STEAM_ART=true
const _capture = bool.fromEnvironment('CAPTURE_STEAM_ART');
const _dir = 'build/visual-review/steam-geyser';

/// A steam street: a soft ride in progress, a hop about to burst, a hot burst
/// and gates between, as levels 3-3 and 3-4 lay them.
FlightSimulation street(String level, {double width = 2.22}) {
  final sim = scene(level, [
    spec(.47, .56, 1.0, kind: SteamKind.ride, slot: 4),
    spec(1.27, .42, -.55, slot: 8),
    spec(width > 2 ? 1.98 : 1.80, .52, .26, slot: 12),
  ], y: .55);
  gate(sim, .88, .58);
  gate(sim, 1.62, .40, look: 1);
  arcStars(sim, 1.27, .42);
  if (width > 2) arcStars(sim, 1.98, .52);
  return sim;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('streets at real size', skip: !_capture, (tester) async {
    for (final (level, tag) in [('3-3', 'night'), ('1-1', 'light')]) {
      for (final (size, px) in [(wide, '800'), (narrow, '640')]) {
        for (final reduced in [false, true]) {
          final sim = street(level, width: size.width / size.height);
          final game = await mountGame(tester, sim, size, reduced: reduced);
          await tester.runAsync(() async {
            final image = await shoot(game, size);
            await savePng(
              image,
              '$_dir/street-$tag-$px${reduced ? '-rm' : ''}.png',
            );
          });
        }
      }
    }
  });

  testWidgets('phase sheets', skip: !_capture, (tester) async {
    const taus = [-1.3, -.7, -.15, .05, .3, .62, 1.0, 1.6, 2.3];
    for (final (name, top, kind, slot) in [
      ('cover', .52, SteamKind.hop, 12),
      ('stack', .40, SteamKind.hop, 4),
      ('grate', .56, SteamKind.ride, 4),
    ]) {
      for (final reduced in [false, true]) {
        final sim = scene('3-3', [
          spec(1.0, top, 0, kind: kind, slot: slot),
        ], y: .2);
        final game = await mountGame(tester, sim, wide, reduced: reduced);
        await tester.runAsync(() async {
          final tiles = <ui.Image>[];
          for (final tau in taus) {
            retime(sim, [spec(1.0, top, tau, kind: kind, slot: slot)]);
            tiles.add(
              await shoot(
                game,
                wide,
                crop: const ui.Rect.fromLTWH(360 - 100, 0, 200, 360),
              ),
            );
          }
          await savePng(
            await sheetOf(tiles),
            '$_dir/sheet-$name${reduced ? '-rm' : ''}.png',
          );
        });
      }
    }
  });

  testWidgets('close-ups at 3x', skip: !_capture, (tester) async {
    for (final (name, top, tau, kind, y) in [
      ('stack-hiss', .42, -.5, SteamKind.hop, .22),
      ('stack-burst', .42, .28, SteamKind.hop, .22),
      ('cover-hiss', .52, -.5, SteamKind.hop, .22),
      ('cover-burst', .52, .28, SteamKind.hop, .22),
      ('grate-hiss', .56, -.5, SteamKind.ride, .3),
      ('grate-billow', .56, 1.0, SteamKind.ride, .66),
      ('cover-billow', .52, .9, SteamKind.hop, .64),
    ]) {
      final sim = scene('3-3', [spec(.47, top, tau, kind: kind)], y: y);
      arcStars(sim, .47, top);
      final game = await mountGame(tester, sim, wide);
      await tester.runAsync(() async {
        final image = await shoot(
          game,
          wide,
          scale: 3,
          crop: ui.Rect.fromLTWH(.47 * 360 - 110, 60, 220, 300),
        );
        await savePng(image, '$_dir/close-$name.png');
      });
    }
  });

  testWidgets('bird feedback', skip: !_capture, (tester) async {
    // A scald 0.12 s ago, a bird riding a billow, and the burst's first beats.
    final tiles = <ui.Image>[];
    for (final (tau, y, since, kind, top) in [
      (.22, .55, .12, SteamKind.hop, .44),
      (.3, .55, .30, SteamKind.hop, .44),
      (1.0, .55, -1.0, SteamKind.ride, .52),
      (.02, .7, -1.0, SteamKind.hop, .44),
      (.05, .7, -1.0, SteamKind.hop, .44),
      (.1, .7, -1.0, SteamKind.hop, .44),
    ]) {
      final sim = scene('3-3', [spec(.47, top, tau, kind: kind)], y: y);
      if (since >= 0) sim.invulnerableUntil = sim.elapsed + 1.5 - since;
      arcStars(sim, .47, top);
      final game = await mountGame(tester, sim, wide);
      await tester.runAsync(() async {
        tiles.add(
          await shoot(
            game,
            wide,
            scale: 2,
            crop: ui.Rect.fromLTWH(.47 * 360 - 100, 100, 200, 260),
          ),
        );
      });
    }
    await tester.runAsync(() async {
      await savePng(await sheetOf(tiles), '$_dir/feedback.png');
    });
  });

  testWidgets('decor: the near roofs of a New York level', skip: !_capture, (
    tester,
  ) async {
    final tiles = <ui.Image>[];
    for (final seconds in [4.0, 8.0, 12.0, 16.0, 20.0, 24.0]) {
      final sim = scene('3-3', const [], seconds: seconds, y: .3);
      final game = await mountGame(tester, sim, wide);
      await tester.runAsync(() async {
        tiles.add(
          await shoot(
            game,
            wide,
            crop: const ui.Rect.fromLTWH(0, 180, 800, 180),
          ),
        );
      });
    }
    await tester.runAsync(() async {
      await savePng(await sheetOf(tiles, columns: 2), '$_dir/decor-roofs.png');
    });
  });

  testWidgets('decor close-up', skip: !_capture, (tester) async {
    final sim = scene('3-3', const [], seconds: 4, y: .3);
    final game = await mountGame(tester, sim, wide);
    await tester.runAsync(() async {
      await savePng(
        await shoot(
          game,
          wide,
          scale: 5,
          crop: const ui.Rect.fromLTWH(70, 225, 160, 80),
        ),
        '$_dir/decor-close.png',
      );
    });
  });

  testWidgets('roosting pigeon', skip: !_capture, (tester) async {
    final tiles = <ui.Image>[];
    for (final tau in [2.6, -1.2, -.95, -.8, 1.9, 2.15]) {
      final sim = scene('3-3', [spec(.47, .52, tau, slot: 12)], y: .2);
      final game = await mountGame(tester, sim, wide);
      await tester.runAsync(() async {
        tiles.add(
          await shoot(
            game,
            wide,
            scale: 4,
            crop: ui.Rect.fromLTWH(.47 * 360 - 50, 290, 120, 70),
          ),
        );
      });
    }
    await tester.runAsync(() async {
      await savePng(await sheetOf(tiles, columns: 3), '$_dir/pigeon.png');
    });
  });
}
