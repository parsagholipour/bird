// Visual QA for translations: pumps the real app at the reference phone's
// 792 x 360 in chosen languages and writes one PNG per key screen or
// overlay, so a reviewer can look at every language (l10n-ws/MASTER-PLAN.md,
// "Visual QA"). Opt-in: it lives in tool/, so the suite never runs it.
//
//   flutter test tool/l10n/visual_qa_test.dart \
//     --dart-define=L10N_QA_LOCALES=en-XA,ar,de \
//     --dart-define=L10N_QA_OUT=/abs/path/l10n-ws/reports/visual
//
// L10N_QA_LOCALES: AppLanguage tags and/or `en-XA` (the pseudo-locale);
// default `en-XA,ar`. L10N_QA_OUT: the folder that gets one subfolder per
// locale (default build/l10n-visual). L10N_QA_SHOTS: a comma list of shot
// names to take only those. Each PNG is about 100-200 KB; 21 shots x 2
// locales stay under 10 MB. Extraction builders add the shots of their
// screens to [shots] (results, game over, boss cards...).
@Timeout(Duration(minutes: 20))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/builder_providers.dart';
import 'package:push_up_bird/data/play_games.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/knockout_art.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/language_providers.dart';
import 'package:push_up_bird/l10n/pseudo.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/fit_text.dart';
import 'package:push_up_bird/ui/play_screen.dart';

import '../../test/builder_ui_harness.dart' show builtLevel, editorOf;
import '../../test/built_play_flow_test.dart' show flyBuiltController;
import '../../test/built_result_stage_test.dart'
    show crash, flightController, flightGame, paintFlight, toResult;
import '../../test/campaign_save_test.dart' show levelRun, trailRun;
import '../../test/play_session_test.dart' show SessionSource, SilentAudio;
import '../../test/recorded_flight.dart' show rideTheSky;
import '../../test/replay_highlights_test.dart' show recordRoute;

const _locales = String.fromEnvironment(
  'L10N_QA_LOCALES',
  defaultValue: 'en-XA,ar',
);
const _out = String.fromEnvironment(
  'L10N_QA_OUT',
  defaultValue: 'build/l10n-visual',
);
const _only = String.fromEnvironment('L10N_QA_SHOTS');

/// What a shot needs: a save, a route, and what to do before the capture.
class Shot {
  const Shot(
    this.name,
    this.route, {
    this.save = Save.fresh,
    this.act,
    this.flight = false,
    this.session = false,
    this.playGames,
  });
  final String name, route;
  final Save save;
  final Future<void> Function(WidgetTester tester)? act;

  /// Play Games held at this state (Settings' cloud strip), at [_qaNow].
  final PlayGamesStatus? playGames;

  /// The route flies: the game is loaded and stepped, not settled.
  final bool flight;

  /// A saved endless session ([_sessionId]) is in the library.
  final bool session;
}

/// The saved session the replay shots open.
const _sessionId = 'qa-session';

/// The clock of the shots that hold Play Games still.
final _qaNow = DateTime(2026, 10, 6, 15);

/// Play Games signed in and held at [status]: nothing is fetched or saved.
class _HeldPlayGames extends PlayGamesSync {
  _HeldPlayGames(this.status);
  final PlayGamesStatus status;

  @override
  PlayGamesStatus build() => status;

  @override
  Future<void> start() async {}
}

/// Google Play Games that never answers (no plugin in a test).
class _NoPlayGames implements PlayGamesService {
  @override
  Future<bool> available() async => false;
  @override
  Future<bool> signedIn() async => false;
  @override
  Future<bool> signIn() async => false;
  @override
  Future<String?> playerId() async => null;
  @override
  Future<void> showAchievements() async {}
  @override
  Future<Map<String, PlayAchievementState>> achievements() async => {};
  @override
  Future<void> unlock(String id) async {}
  @override
  Future<void> setSteps(String id, int steps) async {}
  @override
  Future<String?> loadLogbook() async => null;
  @override
  Future<void> saveLogbook(String data, String description) async {}
}

/// The cloud strip's longest status lines: [ago] before [_qaNow].
PlayGamesStatus _cloud(
  Duration ago, {
  bool offline = false,
  bool restored = false,
}) => PlayGamesStatus(
  available: true,
  connected: true,
  offline: offline,
  restored: restored,
  savedAt: _qaNow.subtract(ago),
);

enum Save {
  /// A first launch: the prologue is unwatched, nothing is flown.
  fresh,

  /// The Canopy Route flown up to its boss, every scene watched.
  canopy,

  /// The Canopy Route beaten, its postcard not yet seen.
  postcard,

  /// Chapters 1 and 2 and New York's 3-1 to 3-3 flown, every scene and
  /// postcard seen: the courier perches on the Gargoyle's 3-4.
  lamplight,
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder.first);
  await _settle(tester);
}

/// Lets loads finish and animations end; a spinner that never ends stops
/// it after three seconds of frames rather than timing out.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  for (var i = 0; i < 30 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens [level]'s card on the map, replays its story scene and taps on to
/// line [line] (from 0).
Future<void> _storyLine(WidgetTester tester, int line) async {
  await _tap(tester, find.byKey(const ValueKey('level-intro-story')));
  for (var i = 0; i < line; i++) {
    await tester.tap(find.byKey(const ValueKey('story-advance')));
    await tester.pump();
  }
}

/// Lets a saved session's files load (several real file reads).
Future<void> _loadFiles(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

final shots = <Shot>[
  const Shot('home-first', '/'),
  const Shot('home-returning', '/', save: Save.canopy),
  const Shot('settings', '/settings'),
  // F1: the Play Games strip's status lines, "… · 59 min ago" and the like.
  Shot(
    'settings-cloud-saved',
    '/settings',
    playGames: _cloud(const Duration(minutes: 59)),
  ),
  Shot(
    'settings-cloud-offline',
    '/settings',
    playGames: _cloud(const Duration(hours: 23), offline: true),
  ),
  Shot(
    'settings-cloud-restored',
    '/settings',
    playGames: _cloud(const Duration(days: 365), restored: true),
  ),
  Shot(
    'settings-language',
    '/settings',
    act: (t) => _tap(t, find.byKey(const ValueKey('language-key'))),
  ),
  Shot(
    'settings-reset',
    '/settings',
    act: (t) => _tap(t, find.byIcon(Icons.restart_alt_rounded)),
  ),
  const Shot('story-prologue', '/campaign'),
  const Shot('campaign-map', '/campaign', save: Save.canopy),
  const Shot('intro-1-1', '/campaign?level=1-1', save: Save.canopy),
  const Shot('intro-boss-1-8', '/campaign?level=1-8', save: Save.canopy),
  const Shot('postcard-canopy', '/campaign', save: Save.postcard),
  // Slice S1: a lair scene's boss line, the story's longest line, New York's
  // map with its guardians, a guardian's card with the longest hint.
  Shot(
    'story-lair-1-8',
    '/campaign?level=1-8',
    save: Save.canopy,
    act: (t) => _storyLine(t, 4),
  ),
  Shot(
    'story-longest-3-2',
    '/campaign?level=3-2',
    save: Save.lamplight,
    act: (t) => _storyLine(t, 7),
  ),
  const Shot('campaign-map-new-york', '/campaign', save: Save.lamplight),
  const Shot('intro-guardian-3-4', '/campaign?level=3-4', save: Save.lamplight),
  const Shot('daily', '/daily', save: Save.canopy),
  const Shot('passport', '/passport', save: Save.canopy),
  const Shot('birds', '/birds', save: Save.canopy),
  const Shot('upgrades', '/upgrades', save: Save.canopy),
  const Shot('records', '/records', save: Save.canopy),
  const Shot('sessions', '/sessions', save: Save.canopy),
  const Shot('coop', '/coop', save: Save.canopy),
  const Shot('builder-home', '/builder', save: Save.canopy),
  Shot(
    'builder-new-level',
    '/builder',
    save: Save.canopy,
    act: (t) => _tap(t, find.byKey(const ValueKey('new-level'))),
  ),
  Shot(
    'coop-duel-countdown',
    '/coop',
    save: Save.canopy,
    act: (t) async {
      await _tap(t, find.byKey(const ValueKey('coop-mode-duel')));
      await _coopFlight(t);
    },
  ),
  // F1: with a keyboard, each half names its keys (P2's arrow keys may be
  // drawn as arrows).
  Shot(
    'coop-keys-countdown',
    '/coop',
    save: Save.canopy,
    act: (t) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await _tap(t, find.byKey(const ValueKey('coop-mode-duel')));
      await _coopFlight(t);
    },
  ),
  Shot(
    'coop-duel-results',
    '/coop',
    save: Save.canopy,
    act: (t) async {
      await _tap(t, find.byKey(const ValueKey('coop-mode-duel')));
      final (game, sim) = await _coopFlight(t);
      for (var i = 0; i < 151; i++) {
        game.update(.02);
      }
      // Player 2's bird falls: player 1 wins the duel.
      sim.flock[1]
        ..invulnerableUntil = 0
        ..hearts = 1
        ..shield = false
        ..y = 1;
      for (var i = 0; i < 21; i++) {
        game.update(i == 0 ? .02 : .1);
        await t.pump();
      }
    },
  ),
  const Shot('flight-endless', '/play/touch', flight: true),
  const Shot(
    'flight-level-1-2',
    '/play/touch?level=1-2',
    save: Save.canopy,
    flight: true,
  ),
  // S3: a boss lair (1-8): the vanguard's banner, the boss's name card with
  // its story line, the fight's health plate.
  Shot(
    'boss-vanguard-1-8',
    '/play/touch?level=1-8',
    save: Save.canopy,
    flight: true,
    act: (t) => _flyUntil(
      t,
      (sim) =>
          sim.boss != null ||
          (sim.vanguard != null && sim.elapsed - sim.vanguard!.startedAt > .7),
    ),
  ),
  Shot(
    'boss-card-1-8',
    '/play/touch?level=1-8',
    save: Save.canopy,
    flight: true,
    act: (t) => _flyUntil(t, (sim) => (sim.boss?.age ?? 0) > 3.2),
  ),
  Shot(
    'boss-fight-1-8',
    '/play/touch?level=1-8',
    save: Save.canopy,
    flight: true,
    act: (t) => _flyUntil(t, (sim) => (sim.boss?.age ?? 0) > 7),
  ),
  // F1: the two longest boss names on the places that set them whole. The
  // Searchlight Gargoyle's own card (3-4); the Dusk Empress (Paris is not
  // open yet) as a built level's finale: her entrance card, her health
  // plate, and the editor's note to beat her.
  Shot(
    'boss-card-3-4',
    '/play/touch?level=3-4',
    save: Save.lamplight,
    flight: true,
    act: (t) => _flyUntil(t, (sim) => (sim.boss?.age ?? 0) > 3.6),
  ),
  Shot(
    'boss-card-empress',
    '/builder',
    act: (t) => _builtBoss(t, (sim) => (sim.boss?.age ?? 0) > 3.2),
  ),
  Shot(
    'boss-fight-empress',
    '/builder',
    act: (t) => _builtBoss(t, (sim) => (sim.boss?.age ?? 0) > 7),
  ),
  Shot(
    'builder-empress-note',
    '/builder',
    act: (t) => _editBuilt(t, _empressLevel),
  ),
  // Bumped out mid-fight: the game-over plate names what is left of him.
  Shot(
    'game-over-guardian-3-4',
    '/play/touch?level=3-4',
    save: Save.lamplight,
    flight: true,
    act: (t) async {
      await _flyUntil(t, (sim) => (sim.boss?.age ?? 0) > 9);
      await _bump(t, _flight(t));
    },
  ),
  Shot(
    'game-over-empress',
    '/builder',
    act: (t) async {
      await _builtBoss(t, (sim) => (sim.boss?.age ?? 0) > 7);
      await _bump(t, flightController(t));
    },
  ),
  Shot(
    'flight-paused',
    '/play/touch',
    flight: true,
    act: (t) async {
      await t.tap(find.bySemanticsLabel(L10n.strings.hudPauseSemantics).first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    },
  ),
  // Slice S2: the countdown card and its hint, the camera mini games' setup
  // and calibration, and every flight result.
  Shot(
    'flight-countdown',
    '/play/touch',
    flight: true,
    act: (t) async {
      final flight = _flight(t)..pause();
      await t.pump();
      await flight.resume();
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    },
  ),
  const Shot('camera-setup-squat', '/play/squat'),
  Shot(
    'camera-calibration-push-up',
    '/play/push-up',
    act: (t) async {
      await t.runAsync(_flight(t).startCamera);
      await _settle(t);
    },
  ),
  Shot(
    'results-endless',
    '/play/touch',
    flight: true,
    act: (t) async {
      final flight = _flight(t);
      _flyOn(flight, until: (sim) => sim.gates >= 4);
      flight
        ..pause()
        ..endFlight();
      await _landed(t);
    },
  ),
  Shot(
    'game-over-endless',
    '/play/touch',
    flight: true,
    act: (t) async {
      final flight = _flight(t);
      _flyOn(flight, until: (sim) => sim.gates >= 4);
      await _bump(t, flight);
    },
  ),
  Shot(
    'level-result-1-1',
    '/play/touch?level=1-1',
    save: Save.canopy,
    flight: true,
    act: (t) async {
      _flyOn(_flight(t));
      await _landed(t);
    },
  ),
  Shot(
    'game-over-level-1-2',
    '/play/touch?level=1-2',
    save: Save.canopy,
    flight: true,
    act: (t) async {
      final flight = _flight(t);
      _flyOn(flight, until: (sim) => sim.gates >= 6);
      await _bump(t, flight);
    },
  ),
  // S6: menus, collection, passport, daily, records and replays.
  Shot(
    'mini-games',
    '/',
    save: Save.canopy,
    act: (t) => _tap(t, find.byKey(const ValueKey('mini-games'))),
  ),
  Shot(
    'birds-locked',
    '/birds',
    save: Save.canopy,
    act: (t) => _tap(t, find.byKey(const ValueKey('bird-card-0'))),
  ),
  Shot(
    'upgrades-magnet',
    '/upgrades',
    save: Save.canopy,
    act: (t) => _tap(t, find.byKey(const ValueKey('upgrade-card-magnet'))),
  ),
  const Shot(
    'sessions-list',
    '/sessions',
    save: Save.canopy,
    session: true,
    act: _loadFiles,
  ),
  const Shot(
    'replay',
    '/replay/$_sessionId',
    save: Save.canopy,
    session: true,
    act: _loadFiles,
  ),
  Shot(
    'replay-highlights',
    '/replay/$_sessionId',
    save: Save.canopy,
    session: true,
    act: (t) async {
      await _loadFiles(t);
      final button = find.byIcon(Icons.movie_filter_rounded);
      for (var i = 0; i < 40; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump();
        final key = t.widget<IconButton>(
          find.ancestor(of: button, matching: find.byType(IconButton)),
        );
        if (key.onPressed != null) break;
      }
      await _tap(t, button);
    },
  ),
  // Level Builder (slice S4): the editor, its sheets, built flights' results.
  const Shot('builder-starter', '/builder/edit/t-tap-boss'),
  Shot(
    'builder-editor-new',
    '/builder',
    act: (t) => _editBuilt(
      t,
      builtLevel(
        PlayMode.touch,
        id: 'u-qaemptylvl',
        name: 'Sky Hop',
      ).copyWith(items: const []),
    ),
  ),
  Shot(
    'builder-gate',
    '/builder',
    act: (t) async {
      await _editBuilt(t, builtLevel(PlayMode.touch, id: 'u-qagatelevl'));
      await _selectBuilt(t, (i) => i is BuiltGate && i.moving);
    },
  ),
  Shot(
    'builder-settings',
    '/builder',
    act: (t) async {
      await _editBuilt(t, builtLevel(PlayMode.touch, id: 'u-qasettings'));
      await _tap(t, find.byTooltip(L10n.strings.builderSettingsSemantics));
    },
  ),
  Shot(
    'builder-issues',
    '/builder',
    act: (t) async {
      final level = builtLevel(PlayMode.touch, id: 'u-qaissueslv');
      await _editBuilt(
        t,
        level.copyWith(
          items: [
            ...level.items,
            BuiltStar(x: level.finish + 100, y: 500),
            BuiltStar(x: level.gates.first.x + 20, y: 30),
          ],
        ),
      );
      await _tap(t, find.byKey(const ValueKey('editor-issues')));
    },
  ),
  Shot(
    'builder-families',
    '/builder',
    act: (t) async {
      await _editBuilt(t, builtLevel(PlayMode.touch, id: 'u-qafamilies'));
      await _selectBuilt(t, (i) => i is BuiltGate);
      await _tap(t, find.byKey(const ValueKey('gate-family')));
    },
  ),
  Shot(
    'builder-push-up',
    '/builder',
    act: (t) async {
      await _editBuilt(t, builtLevel(PlayMode.pushUp, id: 'u-qapushuplv'));
      await _selectBuilt(t, (i) => i is BuiltGate);
    },
  ),
  Shot(
    'built-test-cleared',
    '/builder',
    act: (t) => _flyBuilt(
      t,
      builtLevel(PlayMode.touch, id: 'u-qatestflt1', name: 'Sky Hop'),
      test: true,
    ),
  ),
  Shot(
    'built-bonk',
    '/builder',
    act: (t) => _flyBuilt(
      t,
      builtLevel(PlayMode.touch, id: 'u-qabumpflt1', name: 'Sky Hop'),
      bump: true,
    ),
  ),
];

PlayController _flight(WidgetTester tester) =>
    (tester.state(find.byType(PlayScreen)) as dynamic).controller
        as PlayController;

/// Flies [flight] on autopilot (never losing its last heart) to its end or
/// [until], then lets a level's celebration play out.
void _flyOn(
  PlayController flight, {
  bool Function(FlightSimulation sim)? until,
}) {
  final sim = flight.simulation!;
  for (var frame = 0; frame < 400 * 50; frame++) {
    if (sim.phase == RunPhase.ended || (until?.call(sim) ?? false)) break;
    if (sim.hearts < 2) sim.hearts = 3;
    if (rideTheSky(sim)) flight.flap();
    flight.advance(.02, 0, 2.2);
    flight.tick();
  }
  while (!flight.celebrationSettled) {
    flight.advance(.02, 0, 2.2);
  }
}

/// A fatal bump, its knockout skipped, then the game-over stage.
Future<void> _bump(WidgetTester tester, PlayController flight) async {
  final sim = flight.simulation!
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0;
  for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
    flight.advance(.02, 0, 2.2);
    flight.tick();
  }
  await _landed(tester);
  flight
    ..knockout = KnockoutArt.skipAfter + .01
    ..skipKnockout();
  await _landed(tester);
}

/// The flight's save lands and its results stage settles.
Future<void> _landed(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Starts the co-op flight chosen on the setup screen and holds it on its
/// countdown, for the test to step.
Future<(BirdGame, FlightSimulation)> _coopFlight(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('coop-start')));
  await tester.pump();
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded);
  await tester.pump();
  game.pauseEngine();
  await tester.pump();
  return (game, game.simulation);
}

/// Keeps the bird hovering mid-sky and steps the paused flight until [done]
/// (two minutes of flight at most), then lets the frame paint.
Future<void> _flyUntil(
  WidgetTester tester,
  bool Function(FlightSimulation sim) done,
) async {
  final view = find.byType(GameWidget<BirdGame>);
  final game = tester.widget<GameWidget<BirdGame>>(view).game!;
  final sim = game.simulation;
  for (var f = 0; f < 6000 && !done(sim); f++) {
    sim
      ..birdY = .5
      ..velocity = 0
      ..hearts = 3;
    game.update(.02);
  }
  // (a paused engine paints nothing new: one short frame repaints it)
  game.resumeEngine();
  await tester.pump(const Duration(milliseconds: 16));
  game.pauseEngine();
  await tester.pump();
}

Future<void> _seed(SqliteProgressRepository repo, Save save) async {
  if (save == Save.fresh) return;
  for (final scene in CampaignStory.scenes) {
    await repo.markStoryWatched(scene);
  }
  if (save == Save.lamplight) {
    final flown = [
      ...Campaign.chapters[0].levels,
      ...Campaign.chapters[1].levels,
      for (final id in ['3-1', '3-2', '3-3']) Campaign.level(id)!,
    ];
    for (final (n, level) in flown.indexed) {
      await repo.saveRun(
        levelRun(
          'qa-$n',
          level.id,
          stars: level.marks.three,
          score: 400 + n * 40,
          at: DateTime(2026, 10, 1, 12, n),
        ),
      );
    }
    for (final chapter in Campaign.chapters) {
      await repo.markPostcardSeen(chapter);
    }
    return;
  }
  final canopy = Campaign.chapters[0].levels;
  var n = 0;
  for (final level in canopy) {
    if (save == Save.canopy && level == canopy.last) break;
    await repo.saveRun(
      levelRun(
        'qa-${n++}',
        level.id,
        stars: level.marks.three,
        score: 400 + n * 40,
        at: DateTime(2026, 10, 1, 12, n),
      ),
    );
  }
}

void main() {
  final locales = [
    for (final tag in _locales.split(',').map((t) => t.trim()))
      if (tag.isNotEmpty) tag,
  ];
  final wanted = {
    for (final s in _only.split(',').map((s) => s.trim()))
      if (s.isNotEmpty) s,
  };

  setUpAll(() async {
    final families = {
      'Fredoka': ['assets/fonts/Fredoka.ttf'],
      'Nunito': ['assets/fonts/Nunito.ttf'],
      LanguageFonts.baloo: ['assets/fonts/l10n/BalooBhaijaan2.ttf'],
      LanguageFonts.mPlus: ['assets/fonts/l10n/MPLUSRounded1c-Bold.ttf'],
      LanguageFonts.jua: ['assets/fonts/l10n/Jua.ttf'],
      LanguageFonts.huninn: ['assets/fonts/l10n/Huninn.ttf'],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
    };
    for (final MapEntry(key: family, value: files) in families.entries) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    L10n.apply(AppLanguage.en);
    // A cached asset future belongs to the test that loaded it, and a later
    // test awaiting it never resumes (each test runs in its own fake-async
    // zone): the next shot's captions would stay loading.
    rootBundle.clear();
  });

  var bytes = 0;
  tearDownAll(() {
    // Words that do not fit, found in the widget tree (canvas text is
    // looked at in the PNGs): one line per finding, beside the folders.
    File('$_out/fit-report.txt')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        _fitFindings.isEmpty ? 'no findings\n' : '${_fitFindings.join('\n')}\n',
      );
    // ignore: avoid_print
    print(
      'l10n visual QA: ${(bytes / 1024 / 1024).toStringAsFixed(1)} MB '
      'written to $_out',
    );
  });

  for (final tag in locales) {
    final pseudo = tag == 'en-XA';
    final language = pseudo ? AppLanguage.en : AppLanguage.fromTag(tag);
    if (language == null) {
      test('unknown locale $tag', () => fail('not an AppLanguage tag: $tag'));
      continue;
    }
    final folder = tag.replaceAll('-', '_');
    for (final (i, shot) in shots.indexed) {
      if (wanted.isNotEmpty && !wanted.contains(shot.name)) continue;
      testWidgets('$tag ${shot.name}', (tester) async {
        tester.view.physicalSize = const Size(792, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = SqliteProgressRepository(
          ProgressDatabase(NativeDatabase.memory()),
        );
        await repo.setSetting(SettingKey.reducedMotion, true);
        await repo.setSetting(SettingKey.voices, false);
        if (!pseudo) await repo.setLanguage(language);
        await _seed(repo, shot.save);
        final sessions = Directory.systemTemp.createTempSync('l10n-qa');
        addTearDown(() => sessions.deleteSync(recursive: true));
        if (shot.session) {
          await tester.runAsync(
            () => SessionRepository(sessions).save(
              SavedSession(
                result: trailRun(_sessionId, at: DateTime(2026, 10, 1, 18, 5)),
                tape: recordRoute(FlightCourse.starTrail, seconds: 25),
                clips: const [],
              ),
            ),
          );
        }
        final container = ProviderContainer(
          overrides: [
            progressRepositoryProvider.overrideWithValue(repo),
            sessionRepositoryProvider.overrideWithValue(
              SessionRepository(sessions),
            ),
            audioFactoryProvider.overrideWithValue(() => SilentAudio()),
            // The camera mini games' shots get a camera that never sees
            // anyone; touch flights never ask for one.
            trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
            if (shot.playGames case final status?) ...[
              playGamesProvider.overrideWith(() => _HeldPlayGames(status)),
              playGamesServiceProvider.overrideWithValue(_NoPlayGames()),
              appClockProvider.overrideWithValue(() => _qaNow),
            ],
            if (pseudo) ...[
              appLocaleProvider.overrideWithValue(pseudoLocale),
              storyCaptionsProvider.overrideWith(
                (ref) async => StoryCaptions.pseudo(),
              ),
            ],
          ],
        );
        addTearDown(container.dispose);
        await container.read(progressProvider.future);
        appRouter.go(shot.route);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RepaintBoundary(
              key: ValueKey('visual-capture'),
              child: PushUpBirdApp(),
            ),
          ),
        );
        await tester.runAsync(() async {
          final context = tester.element(find.byType(PushUpBirdApp));
          for (final asset in ['pip', 'peaches', 'minty', 'orbit', 'island']) {
            await precacheImage(
              AssetImage('assets/images/$asset.png'),
              context,
            ).catchError((Object _) {});
          }
        });
        // The language's story captions load with real reads (the index,
        // then its file), each finishing between frames: let both land.
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        if (shot.flight) {
          await tester.pump();
          await tester.pump();
          final view = find.byType(GameWidget<BirdGame>);
          final game = tester.widget<GameWidget<BirdGame>>(view).game!;
          await tester.runAsync(() => game.loaded);
          await tester.pump();
          game.pauseEngine();
          for (var f = 0; f < 200; f++) {
            game.update(.02);
          }
          await tester.pump();
          expect(game.simulation.phase, isNot(RunPhase.countdown));
        } else {
          await _settle(tester);
        }
        await shot.act?.call(tester);
        if (!shot.flight) await _settle(tester);
        expect(tester.takeException(), isNull);
        _fitReport(tester, '$tag ${shot.name}');
        final name = '${(i + 1).toString().padLeft(2, '0')}-${shot.name}';
        bytes += await _capture(tester, '$_out/$folder/$name.png');
        appRouter.go('/');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

final _fitFindings = <String>[];

/// Records every widget whose words do not fit on the shot's screen: a
/// [FitText] or [FittedBox] shrunk below [FitText.minScale], a
/// [FitParagraph] cut or shrunk below it, a paragraph cut at its last line,
/// or a one-line paragraph wider than its box (faded or clipped).
void _fitReport(WidgetTester tester, String shot) {
  String words(RenderObject root) {
    final out = <String>[];
    void visit(RenderObject o) {
      if (o is RenderParagraph) out.add(o.text.toPlainText());
      o.visitChildren(visit);
    }

    visit(root);
    return out.join(' | ').replaceAll('\n', '⏎');
  }

  void visit(RenderObject o) {
    if (o is RenderFittedBox && o.hasSize && o.child != null) {
      final child = o.child!;
      if (child.hasSize && child.size.width > 0) {
        final scale = [
          o.size.width / child.size.width,
          if (child.size.height > 0) o.size.height / child.size.height,
        ].reduce((a, b) => a < b ? a : b);
        if (scale < FitText.minScale - .005) {
          _fitFindings.add(
            '$shot: shrunk to ${scale.toStringAsFixed(2)}: ${words(o)}',
          );
        }
      }
    } else if (o is RenderFitParagraph && o.hasSize) {
      if (o.cut || o.scale < FitText.minScale - .005) {
        _fitFindings.add(
          '$shot: paragraph ${o.cut ? 'cut' : 'at ${o.scale.toStringAsFixed(2)}'}: ${o.text}',
        );
      }
    } else if (o is RenderParagraph && o.hasSize) {
      final text = o.text.toPlainText();
      if (o.didExceedMaxLines) {
        _fitFindings.add('$shot: cut after ${o.maxLines} line(s): $text');
      } else if ((!o.softWrap || o.maxLines == 1) &&
          o.getMaxIntrinsicWidth(double.infinity) > o.size.width + .5) {
        _fitFindings.add(
          '$shot: one line wider than its box '
          '(${o.getMaxIntrinsicWidth(double.infinity).round()} > '
          '${o.size.width.round()}): $text',
        );
      }
    }
    o.visitChildren(visit);
  }

  visit(tester.binding.rootElement!.renderObject!);
}

Future<int> _capture(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  var written = 0;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..parent.createSync(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    written = data.lengthInBytes;
    image.dispose();
  });
  return written;
}

// Level Builder shots (slice S4).

/// Keeps [plan] as one of the player's levels and opens it in the editor.
Future<void> _editBuilt(WidgetTester tester, BuiltPlan plan) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(PushUpBirdApp)),
  );
  await tester.runAsync(() => container.read(builtStoreProvider).create(plan));
  appRouter.go('/builder/edit/${plan.id}');
  await _settle(tester);
}

/// Selects the editor's first item [where] holds, in view.
Future<void> _selectBuilt(
  WidgetTester tester,
  bool Function(BuiltItem) where,
) async {
  final c = editorOf(tester);
  final entry = c.draft.items.firstWhere((e) => where(e.item));
  c.scrollTo(entry.item.x / BuiltPlan.unit - .8);
  c.select(entry.key);
  await _settle(tester);
}

/// A built level that ends with the Dusk Empress.
final _empressLevel = builtLevel(
  PlayMode.touch,
  id: 'u-qaempress1',
  name: 'Sky Hop',
  boss: BossKind.duskMoth,
);

/// Flies [_empressLevel] until [done] (hovering, never bumped out).
Future<void> _builtBoss(
  WidgetTester tester,
  bool Function(FlightSimulation sim) done,
) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(PushUpBirdApp)),
  );
  await tester.runAsync(
    () => container.read(builtStoreProvider).create(_empressLevel),
  );
  appRouter.go('/play/touch?built=${_empressLevel.id}');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  final game = await flightGame(tester);
  for (var f = 0; f < 200; f++) {
    game.update(.02);
  }
  await _flyUntil(tester, done);
}

/// Flies [plan] (its maker's [test] flight) to its result: to the finish,
/// or into a bump on its last heart.
Future<void> _flyBuilt(
  WidgetTester tester,
  BuiltPlan plan, {
  bool test = false,
  bool bump = false,
}) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(PushUpBirdApp)),
  );
  await tester.runAsync(() => container.read(builtStoreProvider).create(plan));
  appRouter.go('/play/touch?built=${plan.id}${test ? '&test=1' : ''}');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  final game = await flightGame(tester);
  final c = flightController(tester);
  if (bump) {
    flyBuiltController(c, seconds: 8);
    crash(c);
    await tester.runAsync(c.finish);
    c.knockout = 99;
    c.skipKnockout();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  } else {
    flyBuiltController(c);
    await toResult(tester, c);
  }
  await paintFlight(tester, game);
  await tester.pump(const Duration(seconds: 2));
}
