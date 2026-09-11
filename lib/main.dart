import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'domain/tracking.dart';
import 'ui/home_screen.dart';
import 'ui/collection_screen.dart';
import 'ui/records_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/play_screen.dart';
import 'ui/calibration_probe.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Fredoka',
    ], await rootBundle.loadString('assets/fonts/Fredoka-LICENSE.txt'));
    yield LicenseEntryWithLineBreaks([
      'Nunito',
    ], await rootBundle.loadString('assets/fonts/Nunito-LICENSE.txt'));
  });
  runApp(const ProviderScope(child: PushUpBirdApp()));
}

final appRouter = GoRouter(
  initialLocation: const bool.fromEnvironment('CAMERA_LAB') ? '/lab' : '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/birds',
      builder: (context, state) => const CollectionScreen(),
    ),
    GoRoute(
      path: '/records',
      builder: (context, state) => const RecordsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/lab',
      builder: (context, state) => const CalibrationProbe(),
    ),
    GoRoute(
      path: '/play/:mode',
      builder: (context, state) => PlayScreen(
        key: ValueKey(state.uri.toString()),
        mode: state.pathParameters['mode'] == 'smile'
            ? PlayMode.smile
            : PlayMode.pushUp,
        practice: state.uri.queryParameters['practice'] == 'true',
      ),
    ),
  ],
);

class PushUpBirdApp extends StatelessWidget {
  const PushUpBirdApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Push-Up Bird',
    debugShowCheckedModeBanner: false,
    theme: skyTheme(),
    routerConfig: appRouter,
  );
}
