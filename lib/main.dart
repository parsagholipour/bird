import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_brand.dart';
import 'domain/tracking.dart';
import 'domain/campaign.dart';
import 'domain/flight_course.dart';
import 'ui/home_screen.dart';
import 'ui/campaign_screen.dart';
import 'ui/collection_screen.dart';
import 'ui/records_screen.dart';
import 'ui/upgrades_screen.dart';
import 'ui/replay_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/play_screen.dart';
import 'ui/builder/built_flight_screen.dart';
import 'ui/builder/builder_editor_screen.dart';
import 'ui/builder/builder_home_screen.dart';
import 'ui/coop_screen.dart';
import 'ui/calibration_probe.dart';
import 'ui/theme.dart';
import 'ui/screen_frame.dart';
import 'ui/passport_screen.dart';
import 'ui/daily_adventure_screen.dart';
import 'data/play_games.dart';
import 'data/providers.dart';
import 'domain/daily_adventure.dart';
import 'game/audio.dart';
import 'game/voice_pack_seam_runtime.dart';
import 'game/voice_packs.dart';
import 'ui/ui_sounds.dart';
import 'ui/keyboard.dart';
import 'data/progress_repository.dart';
import 'l10n/l10n.dart';
import 'l10n/language_providers.dart';

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
    // The localization's script fonts (assets/fonts/l10n/).
    for (final (family, file) in const [
      ('Baloo Bhaijaan 2', 'BalooBhaijaan2'), // l10n-ignore
      ('M PLUS Rounded 1c', 'MPLUSRounded1c'), // l10n-ignore
      ('Jua', 'Jua'), // l10n-ignore
      ('Huninn', 'Huninn'), // l10n-ignore
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/l10n/$file-LICENSE.txt'));
    }
  });
  // The voices follow the game's language: its voice pack is installed when
  // it becomes active (l10n-ws/VOICE-PLAN.md).
  VoicePacks.instance.follow(L10n.language);
  runApp(
    ProviderScope(
      overrides: voicePackSeamOverrides,
      child: const PushUpBirdApp(),
    ),
  );
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
      path: '/upgrades',
      builder: (context, state) => const UpgradesScreen(),
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
    GoRoute(path: '/coop', builder: (context, state) => const CoopScreen()),
    // The Level Builder: its shelf, and the editor of one level (`at` is a
    // place on the route to show, such as where a test flight stopped).
    GoRoute(
      path: '/builder',
      builder: (context, state) => const BuilderHomeScreen(),
    ),
    GoRoute(
      path: '/builder/edit/:id',
      builder: (context, state) => BuilderEditorScreen(
        key: ValueKey(state.uri.toString()),
        id: state.pathParameters['id']!,
        at: int.tryParse(state.uri.queryParameters['at'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/lab',
      builder: (context, state) => const CalibrationProbe(),
    ),
    GoRoute(
      path: '/play/:mode',
      // A campaign level (`/play/touch?level=1-3`) is a scored Tap & Fly
      // flight, and only flies once the map has opened it.
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
        // A built level (`/play/push-up?built=u-…`, with `&test=1` for its
        // creator's test flight) is loaded before it flies.
        if (state.uri.queryParameters['built'] case final built?) {
          final query = state.uri.queryParameters;
          return BuiltFlightScreen(
            key: ValueKey(state.uri.toString()),
            id: built,
            test: query['test'] == '1',
            from: int.tryParse(query['from'] ?? ''),
          );
        }
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
    appRouter.routerDelegate.addListener(_calmMoment);
    ref.listenManual(
      progressProvider,
      (_, _) => _syncMenuMusic(),
      fireImmediately: true,
    );
    // Load what the characters said in flight before the first flight.
    ref.read(flightVoiceMemoryProvider);
    // Canvas and Flame code read the language from a global (L10n); keep it
    // in step with the player's choice and the device, and keep the story
    // captions of the current language loaded.
    void syncLanguage() => L10n.apply(
      ref.read(appLanguageProvider),
      locale: ref.read(appLocaleProvider),
    );
    ref.listenManual(appLanguageProvider, (_, _) => syncLanguage());
    ref.listenManual(
      appLocaleProvider,
      (_, _) => syncLanguage(),
      fireImmediately: true,
    );
    ref.listenManual(storyCaptionsProvider, (_, captions) {
      if (captions.value case final loaded?) L10n.applyCaptions(loaded);
    }, fireImmediately: true);
    _calendar = Timer.periodic(const Duration(minutes: 1), (_) => _checkDay());
    // Play Games: silent, and only when configured (play_games_ids.dart).
    unawaited(ref.read(playGamesProvider.notifier).start());
  }

  /// Home and Settings are calm moments for Play Games: no flight, boss,
  /// story scene or camera runs there. Any other screen ends the moment.
  void _calmMoment() {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    final sync = ref.read(playGamesProvider.notifier);
    sync.calm = path == '/' || path == '/settings';
    if (sync.calm) unawaited(sync.calmMoment());
  }

  /// Whether a flight, a co-op flight or the camera lab is on screen. A
  /// settled results stage is calm, not flying.
  bool get _inFlight {
    if (ref.read(playGamesProvider.notifier).calm) return false;
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    return path.startsWith('/play/') || path == '/coop' || path == '/lab';
  }

  void _syncMenuMusic() {
    final settings = ref.read(progressProvider).asData?.value.settings;
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    final inGame =
        path.startsWith('/play/') ||
        path.startsWith('/replay/') ||
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

  /// Android's language list changed (only matters under "System default").
  @override
  void didChangeLocales(List<Locale>? locales) {
    ref.read(deviceLocalesProvider.notifier).update(locales);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(_menuAudio.stopEffects());
    _syncMenuMusic();
    if (state == AppLifecycleState.paused && !_inFlight) {
      unawaited(ref.read(playGamesProvider.notifier).paused());
    }
    if (state == AppLifecycleState.resumed) {
      ref.read(playGamesProvider.notifier).resumed();
    }
    if (state == AppLifecycleState.resumed) unawaited(_checkDay());
  }

  @override
  void dispose() {
    _calendar?.cancel();
    appRouter.routerDelegate.removeListener(_syncMenuMusic);
    appRouter.routerDelegate.removeListener(_calmMoment);
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
    final language = ref.watch(appLanguageProvider);
    return MaterialApp.router(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: skyTheme(language),
      // The game picks its own language (lib/l10n/language_providers.dart);
      // Material's widgets and Directionality follow it (Arabic mirrors the
      // menus; flights stay left to right, see FlightDirection).
      locale: ref.watch(appLocaleProvider),
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: appRouter,
      scrollBehavior: const _AnyPointerDrags(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations: reducedMotion || mediaQuery.disableAnimations,
          ),
          // Every display shows the reference phone's picture, scaled.
          child: ScreenFrame(
            child: UiSounds(
              play: (cue) {
                if (_foreground) _menuAudio.effect(cue);
              },
              speak: (asset) {
                if (_foreground) _menuAudio.speak(asset);
              },
              hush: _menuAudio.hush,
              child: EscapeBack(
                popRoute: appRouter.routerDelegate.popRoute,
                child: child!,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A mouse drags lists and the map the way a finger does. Flutter leaves
/// mouse drags out by default, which leaves a sideways list to Shift and
/// the wheel.
class _AnyPointerDrags extends MaterialScrollBehavior {
  const _AnyPointerDrags();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}
