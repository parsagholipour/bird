import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/ui/mode_picker.dart';
import 'package:push_up_bird/ui/theme.dart';

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  // The connected OnePlus reports a 40 logical-pixel cutout on one edge.
  for (final cutoutOnLeft in [true, false]) {
    testWidgets(
      'mode picker stays centered with cutout on ${cutoutOnLeft ? 'left' : 'right'}',
      (tester) async {
        tester.view.physicalSize = const Size(792, 360);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(
          left: cutoutOnLeft ? 40 : 0,
          right: cutoutOnLeft ? 0 : 40,
        );
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        await tester.pumpWidget(
          MaterialApp(
            theme: skyTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => showModePicker(context),
                    child: const Text('Open picker'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open picker'));
        await tester.pumpAndSettle();
        final cards = [
          'pushUp',
          'touch',
          'jump',
          'squat',
        ].map((mode) => tester.getRect(find.byKey(ValueKey('mode-$mode'))));
        final bounds = cards.reduce((a, b) => a.expandToInclude(b));
        expect(
          bounds.center.dx,
          closeTo(396, .5),
          reason:
              'The card row must be centered on the physical display, even with a cutout on one side.',
        );
        expect(
          tester.getCenter(find.text('Choose your mode')).dx,
          closeTo(396, .5),
        );
        expect(bounds.left, greaterThanOrEqualTo(40));
        expect(bounds.right, lessThanOrEqualTo(752));
        expect(bounds.bottom, lessThanOrEqualTo(360));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
