import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'domain/tracking.dart';
import 'domain/campaign.dart';
import 'domain/flight_course.dart';
import 'ui/home_screen.dart';
import 'ui/campaign_screen.dart';
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
import 'game/audio.dart';
import 'ui/ui_sounds.dart';
import 'data/progress_repository.dart';

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
      path: '/campaign',
      builder: (context, state) => CampaignScreen(
        key: ValueKey(state.uri.toString()),
        level: state.uri.queryParameters['level'],
      ),
    ),
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
      // A campaign level (`/play/touch?level=1-3`) is a scored Tap & Fly
      // Star Trail, and only flies once the map has opened it.
      redirect: (context, state) {
        final id = state.uri.queryParameters['level'];
        if (id == null) return null;
        final level = Campaign.level(id);
        if (level == null || state.pathParameters['mode'] != 'touch') {
          return '/campaign';
        }
        final progress = ProviderScope.containerOf(
          context,
          listen: false,
        ).read(progressProvider).asData?.value;
        if (progress != null && !progress.campaign.unlocked(level)) {
          return '/campaign';
        }
        return null;
      },
      builder: (context, state) {
        final level = Campaign.level(state.uri.queryParameters['level'] ?? '');
        return PlayScreen(
          key: ValueKey(state.uri.toString()),
          mode: switch (state.pathParameters['mode']) {
            'jump' || 'smile' => PlayMode.jump,
            'touch' => PlayMode.touch,
            'squat' => PlayMode.squat,
            _ => PlayMode.pushUp,
          },
          course: level != null
              ? FlightCourse.starTrail
              : FlightCourse.named(state.uri.queryParameters['course']),
          level: level,
        );
      },
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
  late final SkyAudio _menuAudio;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _menuAudio = ref.read(audioFactoryProvider)();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    appRouter.routerDelegate.addListener(_syncMenuMusic);
    ref.listenManual(
      progressProvider,
      (_, _) => _syncMenuMusic(),
      fireImmediately: true,
    );
    // Load what the characters said in flight before the first flight.
    ref.read(flightVoiceMemoryProvider);
    _calendar = Timer.periodic(const Duration(minutes: 1), (_) => _checkDay());
  }

  void _syncMenuMusic() {
    final settings = ref.read(progressProvider).asData?.value.settings;
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    final inGame =
        path.startsWith('/play/') ||
        path.startsWith('/replay/') ||
        path == '/school' ||
        path == '/lab';
    unawaited(
      _menuAudio.configure(
        settings ?? const GameSettings(music: false),
        active: _foreground && !inGame,
        track: SkyMusic.menu,
      ),
    );
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
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(_menuAudio.stopEffects());
    _syncMenuMusic();
    if (state == AppLifecycleState.resumed) unawaited(_checkDay());
  }

  @override
  void dispose() {
    _calendar?.cancel();
    appRouter.routerDelegate.removeListener(_syncMenuMusic);
    unawaited(_menuAudio.dispose());
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
          child: UiSounds(
            play: (cue) {
              if (_foreground) _menuAudio.effect(cue);
            },
            speak: (asset) {
              if (_foreground) _menuAudio.speak(asset);
            },
            hush: _menuAudio.hush,
            child: child!,
          ),
        );
      },
    );
  }
}
