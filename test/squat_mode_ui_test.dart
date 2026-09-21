import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/play_screen.dart';
import 'experience_ui_test.dart' show capture;
import 'play_session_test.dart' show SessionSource, SilentAudio;
import 'squat_tracking_test.dart' show squatSample;

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito', 'MaterialIcons']) {
      await (FontLoader(family)..addFont(
            rootBundle.load(
              family == 'MaterialIcons'
                  ? 'fonts/MaterialIcons-Regular.otf'
                  : 'assets/fonts/$family.ttf',
            ),
          ))
          .load();
    }
  });

  testWidgets(
    'squat calibration guides standing, lowering and rising on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await repo.setSetting(SettingKey.reducedMotion, true);
      final source = SessionSource();
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          trackingSourceFactoryProvider.overrideWithValue(() => source),
          audioFactoryProvider.overrideWithValue(SilentAudio.new),
        ],
      );
      await container.read(progressProvider.future);
      appRouter.go('/play/squat?practice=true');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(
            key: ValueKey('visual-capture'),
            child: PushUpBirdApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dynamic state = tester.state(find.byType(PlayScreen));
      final controller = state.controller as PlayController;
      await controller.startCamera();
      await tester.pump();
      expect(find.text('Stand tall and still.'), findsOneWidget);
      for (var t = 1000.0; t <= 1900; t += 40) {
        source.time = t;
        source.sampleStream.add(squatSample(t));
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(find.text('Squat comfortably.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'squat-calibration-lower');
      for (var t = 1920.0; t <= 2500; t += 40) {
        source.time = t;
        source.sampleStream.add(squatSample(t, depth: .14));
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(find.text('Stand back up.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'squat-calibration-rise');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await repo.close();
    },
  );
}
