// Polish captures for the chapter postcards: all five at the three phone
// sizes, a 2x look at the message side, and the stamp and postmark up close.
//
// Run with `--dart-define=CAPTURE_POLISH=true` to write PNGs to
// build/visual-review/campaign/polish/postcard/.
@Timeout(Duration(minutes: 6))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/campaign_postcard.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/theme.dart';

const _capture = bool.fromEnvironment('CAPTURE_POLISH');
const _folder = 'build/visual-review/campaign/polish/postcard';

Widget _harness(Widget child, Size size) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: skyTheme(),
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: RepaintBoundary(
      key: const ValueKey('polish-capture'),
      child: Scaffold(body: child),
    ),
  ),
);

Future<void> _save(WidgetTester tester, String name) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('polish-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_folder/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _card(
  WidgetTester tester,
  Size size,
  int chapter, {
  int bird = 0,
  bool action = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _harness(
      SkyBackdrop(
        child: SafeArea(
          minimum: const EdgeInsets.all(12),
          child: Center(
            child: CampaignPostcard(
              chapter: chapter,
              bird: bird,
              action: action
                  ? SkyButton(label: 'Continue', onPressed: () {})
                  : null,
            ),
          ),
        ),
      ),
      size,
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test('each postmark names its route without the leading "The"', () {
    expect(
      [for (final l in CampaignPostcard.letters) l.postmarkName],
      [
        'CANOPY ROUTE',
        'ANCIENT ROAD',
        'LAMPLIGHT LINE',
        'TIDE ROUTE',
        'EDGE OF THE MAP',
      ],
    );
  });

  group('capture', skip: !_capture, () {
    for (final size in const [
      Size(640, 360),
      Size(800, 360),
      Size(1000, 450),
    ]) {
      final w = size.width.round();
      testWidgets('every chapter at $w', (tester) async {
        for (var chapter = 1; chapter <= 5; chapter++) {
          await _card(tester, size, chapter, bird: (chapter + 1) % 4);
          await _save(tester, 'chapter-$chapter-$w');
        }
      });
    }

    testWidgets('every chapter at 2x', (tester) async {
      for (var chapter = 1; chapter <= 5; chapter++) {
        await _card(
          tester,
          const Size(1560, 690),
          chapter,
          bird: chapter % 4,
          action: false,
        );
        await _save(tester, 'detail-$chapter');
      }
    });

    testWidgets('stamps up close', (tester) async {
      tester.view.physicalSize = const Size(1500, 520);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _harness(
          Container(
            color: SkyColors.cream,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final chapter in Campaign.chapters)
                  SizedBox(
                    width: 264,
                    height: 318,
                    child: CustomPaint(
                      painter: CampaignStampPainter(
                        chapter.boss,
                        chapter: chapter.number,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Size(1500, 520),
        ),
      );
      await _save(tester, 'stamps');
    });

    testWidgets('postmarks up close', (tester) async {
      tester.view.physicalSize = const Size(1500, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _harness(
          Container(
            color: const Color(0xfffffaef),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final letter in CampaignPostcard.letters)
                  SizedBox(
                    width: 268,
                    height: 168,
                    child: CustomPaint(
                      painter: CampaignPostmarkPainter(
                        top: letter.postmarkName,
                        middle: 'DELIVERED',
                        bottom: 'SKY CLUB POST',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Size(1500, 300),
        ),
      );
      await _save(tester, 'postmarks');
    });
  });
}
