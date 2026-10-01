// The level route in the flight HUD marks where a boss waits. A guardian
// (King Coo, the Searchlight Gargoyle) gets a little shield on the line; a
// chapter's boss keeps its round lair post.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart' show BossKind;
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/level_hud.dart' show MatchRoute;

import 'ny_ui_support.dart';

/// The route of a flight at [progress] meeting [boss], as pixels.
Future<List<int>> _pixels(
  WidgetTester tester,
  BossKind? boss, {
  double progress = .45,
}) async {
  tester.view.physicalSize = const Size(400, 120);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    nyHarness(
      Center(
        child: MatchRoute(progress: progress, bird: 1, boss: boss),
      ),
      const Size(400, 120),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MatchRoute));
    for (final asset in birdAssets) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await tester.pump();
  final render = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('ny-capture')),
  );
  late List<int> bytes;
  await tester.runAsync(() async {
    final image = await render.toImage();
    bytes = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    image.dispose();
  });
  return bytes;
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  testWidgets('each boss marks the route in its own way', (tester) async {
    final none = await _pixels(tester, null);
    final baron = await _pixels(tester, BossKind.baronBat);
    final coo = await _pixels(tester, BossKind.kingCoo);
    final gargoyle = await _pixels(tester, BossKind.searchlightGargoyle);
    expect(tester.takeException(), isNull);
    // Every boss changes the route, and no two bosses look alike.
    final all = [none, baron, coo, gargoyle];
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        expect(all[i], isNot(all[j]), reason: '$i and $j look alike');
      }
    }
  });

  testWidgets('the route reads the same at any progress', (tester) async {
    for (final progress in [0.0, .3, .6, 1.0]) {
      await _pixels(tester, BossKind.kingCoo, progress: progress);
      await _pixels(tester, BossKind.searchlightGargoyle, progress: progress);
      expect(tester.takeException(), isNull, reason: '$progress');
    }
  });
}
