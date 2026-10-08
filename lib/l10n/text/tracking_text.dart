import '../generated/app_localizations.dart';

/// Camera coaching and tracking feedback (owner: slice S5, MASTER-PLAN.md
/// "Slices"), which the domain trackers (lib/domain/*tracking.dart), the
/// flight simulation and the native camera produce as English text, and the
/// flight HUD (S2) and the camera screens (S5) show.
///
/// The English stays the domain's twin: replays record it (a session
/// journal stores `MovementInput.feedback` as words), logs print it and the
/// trackers' tests read it. So the words are mapped back to a [TrackingCue]
/// here, by their exact English (and, for the calibration steps, the "· 1 of
/// 2" count), rather than the trackers returning an enum: that keeps every
/// rule, replay and recorded journal byte-for-byte as it was, and an old
/// journal's feedback is localized as well. test/l10n_s5_test.dart keeps
/// the cues equal to the English ARB and checks every feedback literal in
/// the trackers has a cue.
extension TrackingText on AppLocalizations {
  /// [english] in the current language: a tracker's, the simulation's or
  /// the camera's coaching line. Words that are not one of theirs (an
  /// unexpected native error) come back unchanged.
  String trackingFeedback(String english) {
    final found = TrackingCue.parse(english);
    if (found == null) return english;
    final (cue, step, total) = found;
    return cue.words(this, step: step, total: total);
  }
}

/// Every coaching line the camera modes show, with its English twin.
/// [english] is a pattern for the calibration steps: `{step}` and `{total}`
/// stand for the counts ("Lower comfortably · 1 of 2").
enum TrackingCue {
  // lib/domain/tracking.dart: push-ups.
  catchingUp('Camera is catching up'),
  stepIntoOutline('Step into the body outline'),
  keepShoulders('Keep both shoulders in view'),
  showSide('Show one shoulder, elbow, wrist and hip from the side'),
  moveCloser('Move a little closer'),
  getDown('Get down into your push-up position'),
  handsOnFloor('Put your hands on the floor and extend your body behind you'),
  extendBody('Extend your body a little farther behind your hands'),
  comfortableRange('Stay within a comfortable push-up range'),
  placeHands('Place your hands on the floor with your body behind them'),
  frontTracked('Front view tracked · keep your hands in view'),
  bodyInView('Body in view · face can look down'),
  armsTracked('Arms tracked · leg check limited'),
  findTop('Find a comfortable top position'),
  lowerMore('Lower a little more · {step} of {total}'),
  lowerComfortably('Lower comfortably · {step} of {total}'),
  pushBackUp('Push back up · {step} of {total}'),
  matchRange('Match your first comfortable range · {step} of {total}'),
  calibrated('Calibrated! Try moving your bird.'),
  freshFrame('Waiting for a fresh frame'),
  distanceChanged('Camera distance changed · recalibrate'),
  keepArm('Keep an arm in view'),

  // lib/domain/squat_tracking.dart.
  squatStepBack(
    'Step back so your shoulders, hips, knees and feet are in view',
  ),
  squatFaceCamera('Face the camera with both feet on the floor'),
  squatControls('Squat to descend · stand to rise'),
  startingDistance(
    'Face the camera at your starting distance · recalibrate if you moved',
  ),
  feetPlanted('Keep both feet planted in your starting spot'),
  squatStandTall('Stand tall and still with both feet in view'),
  standStill('Stand tall and still for a moment'),
  squatDepth('Squat to a comfortable depth and hold briefly'),
  squatHold('Squat comfortably, then hold for a moment'),
  squatHoldBriefly('Hold this comfortable squat briefly'),
  squatStandUp('Stand back up to finish calibration'),
  squatReady('Ready! Squat to descend · stand to rise'),

  // lib/domain/jump_tracking.dart.
  jumpStepBack('Step back so your shoulders, hips and both feet are in view'),
  jumpFaceCamera('Stand facing the camera with room above you to jump'),
  jumpSmall('Small jumps are enough · land before jumping again'),
  jumpStandStill('Stand still with your whole body and both feet in view'),
  jumpReady('Ready! One small jump gives one big boost.'),
  jumpBoost('Jump for a big boost'),
  jumpLand('Land to prepare your next jump'),

  // lib/domain/game_rules.dart: the simulation's line before the first
  // frame.
  findPosition('Find your position'),

  // The native camera's status messages (MainActivity.kt, TrackingIssue).
  trackingInterrupted('Tracking interrupted'),
  cameraInterrupted(
    'Camera interrupted. Check camera permission and try again.',
  ),
  cameraAway('Camera stopped while the app was away');

  const TrackingCue(this.english);

  /// The English twin; a pattern with `{step}` and `{total}` for the
  /// calibration steps.
  final String english;

  /// Whether [english] carries the calibration step's counts.
  bool get counted => english.contains('{step}');

  /// The English twin with the counts filled in.
  String englishWith({int step = 1, int total = 2}) => english
      .replaceAll('{step}', '$step')
      .replaceAll('{total}', '$total');

  static final _exact = {
    for (final cue in values)
      if (!cue.counted) cue.english: cue,
  };

  static final _counted = [
    for (final cue in values)
      if (cue.counted)
        (
          cue,
          RegExp(
            '^${RegExp.escape(cue.english).replaceAll(RegExp.escape('{step}'), r'(\d+)').replaceAll(RegExp.escape('{total}'), r'(\d+)')}\$',
          ),
        ),
  ];

  /// The cue [english] words, with its counts (0 when it has none); null
  /// for words that are not a tracker's.
  static (TrackingCue, int, int)? parse(String english) {
    final exact = _exact[english];
    if (exact != null) return (exact, 0, 0);
    for (final (cue, pattern) in _counted) {
      final match = pattern.firstMatch(english);
      if (match != null) {
        return (cue, int.parse(match[1]!), int.parse(match[2]!));
      }
    }
    return null;
  }

  /// This cue in [l]'s language.
  String words(AppLocalizations l, {int step = 0, int total = 0}) =>
      switch (this) {
        catchingUp => l.trackingCatchingUp,
        stepIntoOutline => l.trackingStepIntoOutline,
        keepShoulders => l.trackingKeepShoulders,
        showSide => l.trackingShowSide,
        moveCloser => l.trackingMoveCloser,
        getDown => l.trackingGetDown,
        handsOnFloor => l.trackingHandsOnFloor,
        extendBody => l.trackingExtendBody,
        comfortableRange => l.trackingComfortableRange,
        placeHands => l.trackingPlaceHands,
        frontTracked => l.trackingFrontTracked,
        bodyInView => l.trackingBodyInView,
        armsTracked => l.trackingArmsTracked,
        findTop => l.trackingFindTop,
        lowerMore => l.trackingLowerMore(step, total),
        lowerComfortably => l.trackingLowerComfortably(step, total),
        pushBackUp => l.trackingPushBackUp(step, total),
        matchRange => l.trackingMatchRange(step, total),
        calibrated => l.trackingCalibrated,
        freshFrame => l.trackingFreshFrame,
        distanceChanged => l.trackingDistanceChanged,
        keepArm => l.trackingKeepArm,
        squatStepBack => l.trackingSquatStepBack,
        squatFaceCamera => l.trackingSquatFaceCamera,
        squatControls => l.trackingSquatControls,
        startingDistance => l.trackingStartingDistance,
        feetPlanted => l.trackingFeetPlanted,
        squatStandTall => l.trackingSquatStandTall,
        standStill => l.trackingStandStill,
        squatDepth => l.trackingSquatDepth,
        squatHold => l.trackingSquatHold,
        squatHoldBriefly => l.trackingSquatHoldBriefly,
        squatStandUp => l.trackingSquatStandUp,
        squatReady => l.trackingSquatReady,
        jumpStepBack => l.trackingJumpStepBack,
        jumpFaceCamera => l.trackingJumpFaceCamera,
        jumpSmall => l.trackingJumpSmall,
        jumpStandStill => l.trackingJumpStandStill,
        jumpReady => l.trackingJumpReady,
        jumpBoost => l.trackingJumpBoost,
        jumpLand => l.trackingJumpLand,
        findPosition => l.trackingFindPosition,
        trackingInterrupted => l.trackingInterrupted,
        cameraInterrupted => l.trackingCameraInterrupted,
        cameraAway => l.trackingCameraAway,
      };
}
