// Run with: flutter test tool/render_launch_assets_test.dart
// Renders the production widgets; export_launch_assets.py sizes native assets.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/app_brand.dart';
import 'package:push_up_bird/ui/launch_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('render shared Beakbound launch artwork', (tester) async {
    tester.view.physicalSize = const Size(1000, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }

    Future<void> render(
      Widget child,
      Size size,
      String path, {
      double ratio = 4,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Center(
            child: RepaintBoundary(
              key: const ValueKey('launch-export'),
              child: SizedBox.fromSize(size: size, child: child),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage(AppBrand.logo),
          tester.element(find.byKey(const ValueKey('launch-export'))),
        );
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('launch-export')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: ratio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await render(
      const LaunchLockup(),
      const Size(320, 284),
      'assets/branding/launch-lockup.png',
    );
    await render(
      const Center(child: LaunchEmblem()),
      const Size(288, 288),
      'assets/branding/launch-icon.png',
    );
    await render(
      const Center(child: FittedBox(child: LaunchWordmark())),
      const Size(200, 80),
      'assets/branding/launch-wordmark.png',
    );
    await render(
      const BeakboundLaunchScreen(),
      const Size(1000, 450),
      'design/launch-rework/launch.png',
      ratio: 1,
    );
    await render(
      const BeakboundLaunchScreen(),
      const Size(640, 300),
      'design/launch-rework/launch-small.png',
      ratio: 1,
    );
  });
}
