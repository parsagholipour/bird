import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/finish_celebration_art.dart';
import 'package:push_up_bird/game/finish_gate_art.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/game/sound_bank.dart';
import 'package:push_up_bird/ui/game_over_stage.dart' show StageBirdPainter;
import 'package:push_up_bird/ui/level_result.dart';

import 'campaign_play_test.dart'
    show
        CueAudio,
        flyController,
        launchLevel,
        level,
        levelController,
        loadFonts,
        redraw;

/// The campaign finish line's celebration: its seekable timeline, the
/// controller's stage flow round it, its calm Reduced Motion form, its
/// frame budget, its cues, and that it never touches the flight's result,
/// stars or journal.

const _screen = Size(792, 360);

CourierSeat get _seat => LevelResultStage.courierSeat(_screen, EdgeInsets.zero);

/// A level flight staged at its finish line, crossed at [birdY].
FlightSimulation _crossed({double birdY = .5, bool shield = false}) {
  final sim =
      FlightSimulation(
          rules: TapFlyMode(),
          practice: false,
          course: FlightCourse.starTrail,
          plan: level('1-1').plan,
        )
        ..started = true
        ..phase = RunPhase.playing
        ..distance = 30
        ..elapsed = 40
        ..birdY = birdY
        ..shield = shield;
  sim.finishLine = FinishLine(
    worldX: 30 + FlightSimulation.birdX,
    x: FlightSimulation.birdX,
  )..crossedAt = sim.elapsed;
  sim.end(EndReason.completed);
  return sim;
}

/// One frame of the celebration's own drawing and the gate's, as bytes.
Future<Uint8List> _frame(
  FlightSimulation sim,
  double t, {
  bool reduced = false,
  CourierSeat? seat,
  bool gate = true,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (gate) {
    FinishGateArt.paint(
      canvas,
      _screen.height,
      x: sim.finishLine!.x * _screen.height,
      seconds: sim.elapsed,
      arrived: true,
      reducedMotion: reduced,
      celebration: t,
      contact: FinishCelebrationArt.contact(sim),
    );
  }
  FinishCelebrationArt.paint(
    canvas,
    _screen,
    sim,
    bird: 0,
    seconds: t,
    reducedMotion: reduced,
    seat: seat ?? _seat,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    _screen.width.toInt(),
    _screen.height.toInt(),
  );
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

/// Flies the controller's level to the frame its bird crosses the line.
Future<PlayController> _toTheLine({
  CueAudio? audio,
  bool reducedMotion = false,
  List<RunResult>? runs,
}) async {
  final controller = PlayController(
    mode: PlayMode.touch,
    level: level('1-1'),
    source: null,
    audio: audio ?? CueAudio(),
    reducedMotion: reducedMotion,
    saveRun: (run) async => runs?.add(run),
    saveSession: (_) async {},
    clock: () => DateTime(2026, 10, 3, 12),
  );
  await controller.fly();
  flyController(controller);
  expect(controller.simulation!.finishLine!.crossed, isTrue);
  // The game loop reports the ended flight.
  controller.tick();
  await Future<void>.delayed(Duration.zero);
  return controller;
}

void _frames(PlayController controller, double seconds, [double dt = 1 / 60]) {
  for (var t = 0.0; t < seconds - 1e-9; t += dt) {
    controller.advance(dt, 0, 2.2);
  }
}

/// Counts what a frame asks of the canvas.
class _Counting implements Canvas {
  _Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);

  void _paint(String k, Paint p) {
    _n(k);
    if (p.maskFilter != null) _n('maskFilter');
  }

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  int getSaveCount() => inner.getSaveCount();
  @override
  void restoreToCount(int count) => inner.restoreToCount(count);
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    _n('saveLayer');
    inner.saveLayer(bounds, paint);
  }

  @override
  void translate(double dx, double dy) => inner.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => inner.scale(sx, sy);
  @override
  void rotate(double r) => inner.rotate(r);
  @override
  void skew(double sx, double sy) => inner.skew(sx, sy);
  @override
  void transform(Float64List m) => inner.transform(m);
  @override
  Float64List getTransform() => inner.getTransform();
  @override
  Rect getLocalClipBounds() => inner.getLocalClipBounds();
  @override
  Rect getDestinationClipBounds() => inner.getDestinationClipBounds();
  @override
  void clipPath(Path p, {bool doAntiAlias = true}) {
    _n('clipPath');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    _n('clipRRect');
    inner.clipRRect(rrect, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    _n('clipRect');
    inner.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void drawPath(Path p, Paint paint) {
    _paint('drawPath', paint);
    inner.drawPath(p, paint);
  }

  @override
  void drawCircle(Offset c, double r, Paint paint) {
    _paint('drawCircle', paint);
    inner.drawCircle(c, r, paint);
  }

  @override
  void drawRect(Rect r, Paint paint) {
    _paint('drawRect', paint);
    inner.drawRect(r, paint);
  }

  @override
  void drawRRect(RRect r, Paint paint) {
    _paint('drawRRect', paint);
    inner.drawRRect(r, paint);
  }

  @override
  void drawOval(Rect r, Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
  }

  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) {
    _paint('drawArc', paint);
    inner.drawArc(r, a, b, c, paint);
  }

  @override
  void drawLine(Offset a, Offset b, Paint paint) {
    _paint('drawLine', paint);
    inner.drawLine(a, b, paint);
  }

  @override
  void drawPicture(ui.Picture picture) {
    _n('drawPicture');
    inner.drawPicture(picture);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    _n('drawParagraph');
    inner.drawParagraph(paragraph, offset);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

/// The celebration's peak frames (confetti at full bloom, the bird
/// looping and swooping, the gate flashing) make at most this many draw
/// calls, the gate included, with no blur mask and at most two layers.
const maxPeakOps = 500;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('the timeline', () {
    test('every beat renders, and the same moment paints the same', () async {
      final sim = _crossed(shield: true);
      const beats = [
        0.0,
        FinishCelebrationArt.hitStop,
        FinishCelebrationArt.cheerAt,
        FinishCelebrationArt.fanfareAt,
        .7,
        FinishCelebrationArt.swoopAt,
        FinishCelebrationArt.seconds,
        2.6,
        FinishCelebrationArt.settled,
      ];
      for (final t in beats) {
        final a = await _frame(sim, t);
        expect(await _frame(sim, t), a, reason: 'seconds $t');
      }
      for (final t in [0.0, .4, FinishCelebrationArt.calmSeconds, 1.3]) {
        await _frame(sim, t, reduced: true);
      }
    });

    test('it hands over at 1.7 s and is still by 4.2 s', () async {
      expect(FinishCelebrationArt.duration(reducedMotion: false), 1.7);
      expect(FinishCelebrationArt.duration(reducedMotion: true), .8);
      expect(FinishCelebrationArt.stillAt(reducedMotion: false), 4.2);
      expect(FinishCelebrationArt.stillAt(reducedMotion: true), 1.3);
      // The result's keys arm 55% into its 1.9 s entrance: well inside
      // 3.2 s of the crossing.
      expect(
        FinishCelebrationArt.seconds +
            LevelResultStage.armAt *
                LevelResultStage.entrance.inMilliseconds /
                1000,
        lessThan(3.2),
      );
      final sim = _crossed();
      // Settled: the celebration is done and the loop may stop on this
      // frame; only the gate's flags would wave on.
      expect(
        await _frame(sim, FinishCelebrationArt.settled, gate: false),
        await _frame(sim, FinishCelebrationArt.settled + 1.5, gate: false),
      );
      expect(
        await _frame(sim, 1.3, reduced: true),
        await _frame(sim, 3, reduced: true),
      );
      // Still moving before.
      expect(
        await _frame(sim, 2.5, gate: false),
        isNot(equals(await _frame(sim, 2.6, gate: false))),
      );
    });

    for (final y in [.08, .5, .93]) {
      test('a crossing at height $y lands in the courier seat', () {
        final sim = _crossed(birdY: y);
        final seat = _seat;
        final start = FinishCelebrationArt.bird(
          sim,
          0,
          reducedMotion: false,
          seat: seat,
          h: _screen.height,
        );
        expect(start.center, Offset(FlightSimulation.birdX, y));
        final land = FinishCelebrationArt.bird(
          sim,
          FinishCelebrationArt.seconds - 1e-9,
          reducedMotion: false,
          seat: seat,
          h: _screen.height,
        );
        expect(
          (land.center * _screen.height - seat.center).distance,
          lessThan(.01),
        );
        expect(
          land.scale * .145 * _screen.height,
          moreOrLessEquals(seat.width, epsilon: .01),
        );
        expect(land.angle, moreOrLessEquals(StageBirdPainter.happyTilt));
        expect(land.wing, moreOrLessEquals(StageBirdPainter.happyWing));
        expect(land.alpha, 1);
        // The stage's courier takes over from here.
        expect(
          FinishCelebrationArt.bird(
            sim,
            FinishCelebrationArt.seconds,
            reducedMotion: false,
            seat: seat,
            h: _screen.height,
          ).alpha,
          0,
        );
        // The bird stays on screen throughout.
        for (var t = 0.0; t < FinishCelebrationArt.seconds; t += .02) {
          final p = FinishCelebrationArt.bird(
            sim,
            t,
            reducedMotion: false,
            seat: seat,
            h: _screen.height,
          ).center;
          expect(p.dy, inInclusiveRange(0, 1), reason: 't $t');
          expect(p.dx, inInclusiveRange(0, 2.2), reason: 't $t');
        }
      });
    }

    test('the seat is where the stage puts its courier', () {
      // 792 x 360 fits the 1000 x 450 stage at .792, centred.
      final seat = _seat;
      expect(seat.center.dx, moreOrLessEquals(162 * .792));
      expect(seat.center.dy, moreOrLessEquals(1.8 + 266 * .792));
      expect(seat.width, moreOrLessEquals(196 * .792));
      // A notch's safe area moves it with the stage.
      final notched = LevelResultStage.courierSeat(
        _screen,
        const EdgeInsets.only(left: 30),
      );
      expect(notched.center.dx, greaterThan(seat.center.dx));
    });

    test('Reduced Motion keeps the bird in place and fades it with the '
        'calm stage', () {
      final sim = _crossed(birdY: .3);
      for (final t in [0.0, .4, .8, 1.0, 1.3]) {
        final pose = FinishCelebrationArt.bird(
          sim,
          t,
          reducedMotion: true,
          seat: _seat,
        );
        expect(pose.center, Offset(FlightSimulation.birdX, .3));
        expect(pose.scale, 1);
      }
      expect(
        FinishCelebrationArt.bird(
          sim,
          .8,
          reducedMotion: true,
          seat: _seat,
        ).alpha,
        1,
      );
      expect(
        FinishCelebrationArt.bird(
          sim,
          1.3,
          reducedMotion: true,
          seat: _seat,
        ).alpha,
        0,
      );
      // No zoom, shake, or warm-up beyond a gentle grade.
      for (final t in [0.0, .05, .1, .3]) {
        expect(FinishCelebrationArt.zoom(t, reducedMotion: true), 1);
        expect(
          FinishCelebrationArt.cameraOffset(t, reducedMotion: true),
          Offset.zero,
        );
      }
    });

    test('a replay with no seat ends hovering past the gate', () {
      final sim = _crossed();
      final pose = FinishCelebrationArt.bird(
        sim,
        FinishCelebrationArt.settled,
        reducedMotion: false,
      );
      expect(pose.alpha, 1);
      expect(pose.center.dx, greaterThan(FlightSimulation.birdX + .2));
    });

    test('the gate gets excited on the way in', () {
      expect(FinishGateArt.approach(null), 0);
      expect(FinishGateArt.approach(FinishGateArt.approachSeconds + 1), 0);
      expect(FinishGateArt.approach(1.5), inExclusiveRange(0, 1));
      expect(FinishGateArt.approach(0), 1);
      // The flags quicken without a jump: what they gain grows smoothly.
      var last = 0.0;
      for (var s = 3.0; s >= 0; s -= .1) {
        final gained = FinishGateArt.gained(s);
        expect(gained - last, inInclusiveRange(0, .14));
        last = gained;
      }
    });
  });

  group('the stage flow', () {
    test(
      'crossing plays the celebration, then the result on its own',
      () async {
        final audio = CueAudio();
        final runs = <RunResult>[];
        final controller = await _toTheLine(audio: audio, runs: runs);
        expect(controller.stage, PlayStage.celebrating);
        expect(controller.celebration, 0);
        // The save starts at the crossing.
        await Future<void>.delayed(Duration.zero);
        expect(runs.single.reason, EndReason.completed);
        expect(audio.cues.last, 'finish_snap');
        expect(audio.cues, isNot(contains('complete')));
        _frames(controller, 1.0);
        expect(controller.stage, PlayStage.celebrating);
        expect(audio.cues.skipWhile((c) => c != 'finish_snap').toList(), [
          'finish_snap',
          'finish_cheer',
          'complete',
        ]);
        _frames(controller, .75);
        expect(controller.stage, PlayStage.results);
        expect(controller.handedOff, isTrue);
        expect(audio.cues.where((c) => c == 'complete'), hasLength(1));
        expect(audio.cues, contains('finish_swoop'));
        // It plays on under the result until it settles, then holds.
        expect(controller.celebrationSettled, isFalse);
        _frames(controller, 3);
        expect(controller.celebrationSettled, isTrue);
        expect(controller.celebration, FinishCelebrationArt.settled);
        controller.dispose();
      },
    );

    test('taps skip the celebration only after the guard', () async {
      final audio = CueAudio();
      final controller = await _toTheLine(audio: audio);
      _frames(controller, .3);
      controller.skipCelebration();
      expect(controller.stage, PlayStage.celebrating);
      _frames(controller, .25);
      expect(controller.canSkipCelebration, isTrue);
      controller.skipCelebration();
      expect(controller.stage, PlayStage.results);
      expect(controller.handedOff, isFalse);
      // The fanfare was due on the way; it still plays, once.
      expect(audio.cues.where((c) => c == 'complete'), hasLength(1));
      _frames(controller, 1);
      expect(audio.cues.where((c) => c == 'complete'), hasLength(1));
      controller.dispose();
    });

    test('backgrounding lands on the result over the settled finish', () async {
      final controller = await _toTheLine();
      _frames(controller, .2);
      controller.background();
      expect(controller.stage, PlayStage.results);
      expect(controller.handedOff, isFalse);
      expect(controller.celebrationSettled, isTrue);
      controller.dispose();
    });

    test(
      'pause and back land on the result and leave the journal be',
      () async {
        for (final viaBack in [false, true]) {
          final controller = await _toTheLine();
          final journal = List.of(controller.recorder!.tape.events);
          _frames(controller, .1);
          if (viaBack) {
            controller.endCelebration();
          } else {
            controller.pause();
          }
          expect(controller.stage, PlayStage.results);
          expect(controller.recorder!.tape.events, journal);
          controller.dispose();
        }
      },
    );

    test('Reduced Motion hands over after the calm length', () async {
      final controller = await _toTheLine(reducedMotion: true);
      expect(controller.celebrationSeconds, .8);
      _frames(controller, .75);
      expect(controller.stage, PlayStage.celebrating);
      _frames(controller, .1);
      expect(controller.stage, PlayStage.results);
      expect(controller.handedOff, isTrue);
      _frames(controller, .6);
      expect(controller.celebrationSettled, isTrue);
      controller.dispose();
    });

    testWidgets('the result still arrives if frames stop mid-celebration', (
      tester,
    ) async {
      // Built inside the test's fake clock so its fallback timer is too.
      final controller = levelController(level('1-1'));
      unawaited(controller.fly());
      await tester.pump();
      final sim = controller.simulation!;
      for (var i = 0; i < 200 && sim.phase != RunPhase.playing; i++) {
        controller.advance(.02, 0, 2.2);
      }
      sim.finishLine = FinishLine(
        worldX: sim.distance + FlightSimulation.birdX + .001,
        x: FlightSimulation.birdX + .001,
      );
      controller.advance(.02, 0, 2.2);
      controller.tick();
      expect(controller.stage, PlayStage.celebrating);
      _frames(controller, .2);
      await tester.pump(
        Duration(
          milliseconds: ((FinishCelebrationArt.seconds + 1.05) * 1000).round(),
        ),
      );
      expect(controller.stage, PlayStage.results);
      controller.dispose();
      await tester.pump();
    });

    test('endless, timed and failed endings never celebrate', () async {
      final endless = levelController(null);
      await endless.fly();
      endless.endFlight();
      await endless.finish();
      expect(endless.stage, PlayStage.results);
      expect(endless.celebration, isNull);
      endless.dispose();
      final quit = levelController(level('1-1'));
      await quit.fly();
      flyController(quit, until: (sim) => sim.gates >= 2);
      quit.endFlight();
      await quit.finish();
      expect(quit.stage, PlayStage.results);
      expect(quit.celebration, isNull);
      quit.dispose();
    });
  });

  test(
    'the celebration leaves the result, stars and journal as they were',
    () async {
      // The same flight, celebrated in full, skipped, and interrupted.
      final outcomes = <String>[];
      for (final ending in ['full', 'skip', 'background']) {
        final runs = <RunResult>[];
        final controller = await _toTheLine(runs: runs);
        final sim = controller.simulation!;
        final atLine = (
          sim.score,
          sim.collectedStars,
          sim.levelStars,
          sim.gates,
          sim.elapsed,
        );
        switch (ending) {
          case 'full':
            _frames(controller, 5);
          case 'skip':
            _frames(controller, .6);
            controller.skipCelebration();
            _frames(controller, 4);
          default:
            _frames(controller, .2);
            controller.background();
        }
        await Future<void>.delayed(Duration.zero);
        final r = controller.result!;
        expect((r.score, r.stars), (atLine.$1, atLine.$2));
        expect(controller.levelStars, atLine.$3);
        expect(r.gates, atLine.$4);
        expect(r.durationSeconds, atLine.$5);
        expect(runs.single.score, r.score);
        final tape = controller.recorder!.tape;
        // The journal ends at the crossing, and a replay of it lands there.
        expect(tape.events.last[1], 'end');
        final replay = ReplayPlayer(tape)..seek(tape.durationMs);
        expect(replay.simulation.endReason, EndReason.completed);
        expect(replay.simulation.score, r.score);
        expect(replay.simulation.collectedStars, r.stars);
        outcomes.add(
          '${r.score} ${r.stars} ${controller.levelStars} ${r.gates} '
          '${r.durationSeconds} ${tape.events.length} '
          '${tape.events.map((e) => e.take(2).join(':')).join(',')}',
        );
        controller.dispose();
      }
      expect(outcomes.toSet(), hasLength(1));
    },
  );

  group('the budget', () {
    for (final (t, y) in [
      (.12, .5),
      (.35, .5),
      (.7, .2),
      (1.0, .9),
      (1.3, .5),
      (1.6, .5),
    ]) {
      test('the frame at $t s stays inside the budget', () {
        final sim = _crossed(birdY: y, shield: true);
        final recorder = ui.PictureRecorder();
        final c = _Counting(Canvas(recorder))..clipRect(Offset.zero & _screen);
        FinishGateArt.paint(
          c,
          _screen.height,
          x: sim.finishLine!.x * _screen.height,
          seconds: sim.elapsed,
          arrived: true,
          reducedMotion: false,
          celebration: t,
          contact: FinishCelebrationArt.contact(sim),
        );
        FinishCelebrationArt.paint(
          c,
          _screen,
          sim,
          bird: 3,
          seconds: t,
          reducedMotion: false,
          seat: _seat,
        );
        recorder.endRecording().dispose();
        expect(
          c.counts.keys.where((k) => k.startsWith('UNFORWARDED')),
          isEmpty,
        );
        expect(c.draws, inInclusiveRange(1, maxPeakOps), reason: 't $t');
        expect(c.counts['saveLayer'] ?? 0, lessThanOrEqualTo(2));
        expect(c.counts['maskFilter'] ?? 0, 0);
      });
    }

    test('once settled the celebration itself draws nothing', () {
      final sim = _crossed();
      final recorder = ui.PictureRecorder();
      final c = _Counting(Canvas(recorder));
      FinishCelebrationArt.paint(
        c,
        _screen,
        sim,
        bird: 0,
        seconds: FinishCelebrationArt.settled,
        reducedMotion: false,
        seat: _seat,
      );
      recorder.endRecording().dispose();
      expect(c.draws, 0);
    });
  });

  test('its cues are in the sound bank, with their files', () {
    final cues = {
      'finish_near',
      'finish_snap',
      for (final (_, cue) in FinishCelebrationArt.cues) cue,
    };
    expect(cues, {
      'finish_near',
      'finish_snap',
      'finish_cheer',
      'complete',
      'finish_swoop',
    });
    for (final cue in cues) {
      final spec = soundBank[cue];
      expect(spec, isNotNull, reason: cue);
      for (var v = 0; v < spec!.variants; v++) {
        expect(File('assets/${soundAsset(cue, v)}').existsSync(), isTrue);
      }
    }
    // The music ducks under the birds' cheer.
    expect(soundBank['finish_cheer']!.duck, isNotNull);
  });

  group('on the play screen', () {
    testWidgets('the bird lands in the seat and the courier takes over', (
      tester,
    ) async {
      final (:controller, :game) = await launchLevel(
        tester,
        level('1-1'),
        reduced: false,
      );
      final sim = controller.simulation!
        ..phase = RunPhase.playing
        ..countdown = 0
        ..started = true;
      sim.finishLine = FinishLine(
        worldX: sim.distance + FlightSimulation.birdX + .001,
        x: FlightSimulation.birdX + .001,
      );
      controller.advance(.02, 0, 2.2);
      controller.tick();
      await redraw(tester, controller);
      expect(controller.stage, PlayStage.celebrating);
      expect(find.byKey(const ValueKey('celebration-skip')), findsOneWidget);
      expect(find.byType(LevelResultStage), findsNothing);
      // An early tap is ignored.
      await tester.tap(find.byKey(const ValueKey('celebration-skip')));
      expect(controller.stage, PlayStage.celebrating);
      for (var i = 0; i < 90; i++) {
        controller.advance(1 / 50, 0, 2.2);
      }
      await redraw(tester, controller);
      expect(controller.stage, PlayStage.results);
      expect(find.byKey(const ValueKey('celebration-skip')), findsNothing);
      final stage = tester.widget<LevelResultStage>(
        find.byType(LevelResultStage),
      );
      expect(stage.handoff, isTrue);
      // The bird left on its own, in the seat; the game keeps it un-hidden.
      expect(game.hideBird, isFalse);
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(controller.exit);
    });

    testWidgets('a skip hides the bird and the courier rises in', (
      tester,
    ) async {
      final (:controller, :game) = await launchLevel(tester, level('1-1'));
      final sim = controller.simulation!
        ..phase = RunPhase.playing
        ..countdown = 0
        ..started = true;
      sim.finishLine = FinishLine(
        worldX: sim.distance + FlightSimulation.birdX + .001,
        x: FlightSimulation.birdX + .001,
      );
      controller.advance(.02, 0, 2.2);
      controller.tick();
      await redraw(tester, controller);
      for (var i = 0; i < 30; i++) {
        controller.advance(1 / 50, 0, 2.2);
      }
      await redraw(tester, controller);
      await tester.tap(find.byKey(const ValueKey('celebration-skip')));
      await redraw(tester, controller);
      expect(controller.stage, PlayStage.results);
      expect(game.hideBird, isTrue);
      expect(
        tester.widget<LevelResultStage>(find.byType(LevelResultStage)).handoff,
        isFalse,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(controller.exit);
    });

    testWidgets('back during the celebration goes on to the result', (
      tester,
    ) async {
      final (:controller, game: _) = await launchLevel(tester, level('1-1'));
      final sim = controller.simulation!
        ..phase = RunPhase.playing
        ..countdown = 0
        ..started = true;
      sim.finishLine = FinishLine(
        worldX: sim.distance + FlightSimulation.birdX + .001,
        x: FlightSimulation.birdX + .001,
      );
      controller.advance(.02, 0, 2.2);
      controller.tick();
      await redraw(tester, controller);
      final dynamic navigator = tester.state(find.byType(Navigator).first);
      await navigator.maybePop();
      await redraw(tester, controller);
      expect(controller.stage, PlayStage.results);
      expect(find.byType(LevelResultStage), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(controller.exit);
    });
  });
}
