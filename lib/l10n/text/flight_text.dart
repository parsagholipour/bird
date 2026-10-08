import 'package:flutter/widgets.dart' show StringCharacters;

import '../../domain/flight_course.dart';
import '../../domain/game_rules.dart' show EndReason;
import '../../domain/obstacle.dart';
import '../../domain/rush_path.dart';
import '../../domain/tracking.dart' show PlayMode;
import '../../game/play_controller.dart' show FlightNote;
import '../generated/app_localizations.dart';
import '../l10n.dart' show L10n;
import 'tracking_text.dart';

/// The flight's words (slice S2, MASTER-PLAN.md "Slices"): the flight
/// screen's notes, the courses, gate families and rush paths (co-op mode
/// names are `CoopText.coopModeName`, lib/l10n/text/coop_text.dart).
/// The domain keeps each id with its English twin ([FlightCourse.title],
/// [ObstacleKind.title], [RushPathKind.title], [FlightNote.english]);
/// screens show these. test/l10n_flight_test.dart
/// keeps the English ARB equal to the twins.
extension FlightText on AppLocalizations {
  /// A message the flight screen shows ([PlayController.message],
  /// `microphoneMessage`, `saveError`, `sessionError`,
  /// `cameraRecordingError`, [FlightSimulation.trackingFeedback]): the
  /// controller's own notes ([FlightNote]) by their key, anything else as a
  /// tracker's feedback ([TrackingText.trackingFeedback]), which leaves
  /// words it does not know (an error's own text) as they are.
  String flightNote(String text) => switch (FlightNote.of(text)) {
    null => trackingFeedback(text),
    FlightNote.rememberFailed => flightNoteRememberFailed,
    FlightNote.micUnavailable => flightNoteMicUnavailable,
    FlightNote.micBlocked => flightNoteMicBlocked,
    FlightNote.micOff => flightNoteMicOff,
    FlightNote.videoUnavailable => flightNoteVideoUnavailable,
    FlightNote.micAudioLost => flightNoteMicAudioLost,
    FlightNote.videoInterrupted => flightNoteVideoInterrupted,
    FlightNote.sessionSaveFailed => flightNoteSessionSaveFailed,
    FlightNote.wakingCamera => flightNoteWakingCamera,
    FlightNote.cameraOff => flightNoteCameraOff,
    FlightNote.cameraFailed => flightNoteCameraFailed,
    FlightNote.preparing => flightNotePreparing,
    FlightNote.saveFailed => flightNoteSaveFailed,
    FlightNote.welcomeBack => flightNoteWelcomeBack,
    FlightNote.cameraInterrupted => flightNoteCameraInterrupted,
    FlightNote.trackingInterrupted => flightNoteTrackingInterrupted,
    FlightNote.findPosition => flightFindPosition,
  };

  /// "Endless", "Classic" ([FlightCourse.title]).
  String courseTitle(FlightCourse course) => switch (course) {
    FlightCourse.classic => course_classic_title,
    FlightCourse.starTrail => course_starTrail_title,
  };

  /// [FlightCourse.instructions].
  String courseInstructions(FlightCourse course) => switch (course) {
    FlightCourse.classic => course_classic_instructions,
    FlightCourse.starTrail => course_starTrail_instructions,
  };

  /// "STAR POINTS", "OBSTACLES" ([FlightCourse.scoreLabel]).
  String courseScoreLabel(FlightCourse course) => switch (course) {
    FlightCourse.classic => course_classic_scoreLabel,
    FlightCourse.starTrail => course_starTrail_scoreLabel,
  };

  /// The word after a score of [count] ([FlightCourse.scoreUnit]).
  String courseScoreUnit(FlightCourse course, int count) => switch (course) {
    FlightCourse.classic => course_classic_scoreUnit(count),
    FlightCourse.starTrail => course_starTrail_scoreUnit(count),
  };

  /// The home picture of [course], for screen readers.
  String coursePreviewSemantics(FlightCourse course) => switch (course) {
    FlightCourse.classic => course_classic_previewSemantics,
    FlightCourse.starTrail => course_starTrail_previewSemantics,
  };

  /// A gate family's name ([ObstacleKind.title]).
  String obstacleName(ObstacleKind kind) => switch (kind) {
    ObstacleKind.garden => obstacle_garden_name,
    ObstacleKind.windLift => obstacle_windLift_name,
    ObstacleKind.petalGate => obstacle_petalGate_name,
    ObstacleKind.switchback => obstacle_switchback_name,
    ObstacleKind.lanternDrift => obstacle_lanternDrift_name,
    ObstacleKind.sunWheels => obstacle_sunWheels_name,
    ObstacleKind.crystalSteps => obstacle_crystalSteps_name,
  };

  /// A rush path's name ([RushPathKind.title]); its banner shows it in
  /// capitals ([L10n.upper]) with "!".
  String rushName(RushPathKind kind) => switch (kind) {
    RushPathKind.wildfire => rush_wildfire_name,
    RushPathKind.skyfall => rush_skyfall_name,
    RushPathKind.eruption => rush_eruption_name,
    RushPathKind.swarm => rush_swarm_name,
  };

  /// "Outran the wildfire" ([RushPathKind.escape]).
  String rushEscape(RushPathKind kind) => switch (kind) {
    RushPathKind.wildfire => rush_wildfire_escape,
    RushPathKind.skyfall => rush_skyfall_escape,
    RushPathKind.eruption => rush_eruption_escape,
    RushPathKind.swarm => rush_swarm_escape,
  };

  /// Why an endless flight ended, under its results' cheer.
  String flightEndReason(EndReason reason) => switch (reason) {
    EndReason.collision => flightResultBumpClouds,
    EndReason.trackingLost => flightEndTrackingLost,
    EndReason.postureLost => flightEndPostureLost,
    EndReason.backgrounded => flightEndBackgrounded,
    EndReason.breakTaken => flightEndBreak,
    EndReason.quit => flightEndQuit,
    EndReason.stalled => flightEndStalled,
    EndReason.completed => flightEndCompleted,
  };

  /// The word under a flight's count of moves: push-ups, squats, jumps or
  /// flaps, agreeing with [count].
  String flightMoves(PlayMode mode, int count) => switch (mode) {
    PlayMode.pushUp => flightStatPushUps(count),
    PlayMode.squat => flightStatSquats(count),
    PlayMode.jump => flightStatJumps(count),
    PlayMode.touch => flightStatFlaps(count),
  };

  /// The rank an old Classic flight's [score] earns (5 and up).
  String flightRank(int score) => score >= 25
      ? flightRankSkyCaptain
      : score >= 10
      ? flightRankCloudExplorer
      : flightRankFirstWings;
}

/// The words the flight HUD sets on every frame, made once per language and
/// value: a counted (plural) message costs more than the string it used to
/// be, and the HUD rebuilds each frame. Emptied when the language changes,
/// and kept small.
abstract final class HudWords {
  static final _words = L10n.cache(<Object, String>{});

  /// [make]'s words for [key] in [l]'s language.
  static String of(AppLocalizations l, Object key, String Function() make) {
    final at = (l.localeName, key);
    final known = _words[at];
    if (known != null) return known;
    if (_words.length >= 256) _words.clear();
    return _words[at] = make();
  }
}

/// The pieces a title that drops in letter by letter animates: its letters
/// (whole characters, accents and all), or the whole word at once in a
/// script whose letters join (Arabic), which only shapes as one word.
List<String> dropLetters(String word) =>
    _joining.hasMatch(word) ? [word] : word.characters.toList();

final _joining = RegExp('[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]');
