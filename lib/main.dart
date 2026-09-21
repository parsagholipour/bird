import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'domain/tracking.dart';
import 'domain/flight_course.dart';
import 'ui/home_screen.dart';
import 'ui/collection_screen.dart';
import 'ui/records_screen.dart';
import 'ui/replay_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/play_screen.dart';
import 'ui/calibration_probe.dart';
import 'ui/theme.dart';
import 'ui/passport_screen.dart';
import 'ui/daily_adventure_screen.dart';
import 'ui/flight_school_screen.dart';
import 'data/providers.dart';
import 'domain/daily_adventure.dart';

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
      path: '/school',
      builder: (context, state) => const FlightSchoolScreen(),
    ),
    GoRoute(
      path: '/daily',
      builder: (context, state) => const DailyAdventureScreen(),
    ),
    GoRoute(
      path: '/passport',
      builder: (context, state) => const PassportScreen(),
    ),
    GoRoute(
      path: '/birds',
      builder: (context, state) => const CollectionScreen(),
    ),
    GoRoute(
      path: '/records',
      builder: (context, state) => const RecordsScreen(),
    ),
    GoRoute(
      path: '/sessions',
      builder: (context, state) => const SessionLibraryScreen(),
    ),
    GoRoute(
      path: '/replay/:id',
      builder: (context, state) => ReplayScreen(
        key: ValueKey(state.pathParameters['id']),
        id: state.pathParameters['id']!,
      ),
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
        mode: switch (state.pathParameters['mode']) {
          'jump' || 'smile' => PlayMode.jump,
          'touch' => PlayMode.touch,
          'squat' => PlayMode.squat,
          _ => PlayMode.pushUp,
        },
        practice: state.uri.queryParameters['practice'] == 'true',
        // Retire the crash-free jump diagnostic link in favor of the regular
        // obstacle course. Saved replays retain their recorded course.
        course: switch ((
          state.pathParameters['mode'],
          state.uri.queryParameters['course'],
        )) {
          ('jump' || 'smile', 'cloudCruise') => FlightCourse.starTrail,
          (_, final course) => FlightCourse.named(course),
        },
      ),
    ),
  ],
);

class PushUpBirdApp extends ConsumerStatefulWidget {
  const PushUpBirdApp({super.key});
  @override
  ConsumerState<PushUpBirdApp> createState() => _PushUpBirdAppState();
}

class _PushUpBirdAppState extends ConsumerState<PushUpBirdApp>
    with WidgetsBindingObserver {
  Timer? _calendar;
  bool _refreshingDay = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calendar = Timer.periodic(const Duration(minutes: 1), (_) => _checkDay());
  }

  Future<void> _checkDay() async {
    if (!mounted || _refreshingDay) return;
    final today = ref.read(progressProvider).asData?.value.today;
    if (today == null ||
        today.dayKey == localDayKey(ref.read(appClockProvider)())) {
      return;
    }
    _refreshingDay = true;
    try {
      await ref.read(progressProvider.notifier).refresh();
    } catch (error) {
      debugPrint('Daily adventure refresh: $error');
    } finally {
      _refreshingDay = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_checkDay());
  }

  @override
  void dispose() {
    _calendar?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = ref.watch(
      progressProvider.select(
        (p) => p.asData?.value.settings.reducedMotion ?? false,
      ),
    );
    return MaterialApp.router(
      title: 'Push-Up Bird',
      debugShowCheckedModeBanner: false,
      theme: skyTheme(),
      routerConfig: appRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations: reducedMotion || mediaQuery.disableAnimations,
          ),
          child: child!,
        );
      },
    );
  }
}
