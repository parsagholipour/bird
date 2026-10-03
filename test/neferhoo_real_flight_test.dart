// M1 (Egypt integration): level 2-6 "Return to Sender" played for real,
// end to end, through the real app: PushUpBirdApp and its router, a real
// save (an old schema-5 save migrated at open, or a fresh chapter-2 save),
// the map with 2-6's card, the `before-2-6` scene, the Fly key, the play
// screen with the real game (run-up, Neferhoo's arrival, the warm-up, the
// stage-up, the full fight with mail calls, returns and the ankh, fury, the
// defeat), the level result, the result's Next key, the `last-2-6` scene on
// the map and 2-7's card. A pilot plays it through the play controller's
// own input (the taps, the Shoot key pressed and released, Sprint), at 60
// frames a second; nothing tops the hearts up.
//
// Always: one flight at 640 x 360 on a migrated old save, with its checks.
// With `--dart-define=M1_REVIEW=<dir>`: all three widths (640 on the
// migrated save, 800 and 864 on a fresh one), frame strips and stills
// written to <dir>, and with `--dart-define=M1_VIDEO=<frames>` also an MP4
// per width (one frame in every <frames> of the flight, through ffmpeg).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'package:push_up_bird/game/neferhoo_fight_art.dart';
import 'package:push_up_bird/game/neferhoo_props_art.dart' show neferhooHudPlate;
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/main.dart' show PushUpBirdApp, appRouter;
import 'package:push_up_bird/ui/play_screen.dart';

import 'campaign_save_test.dart' show levelRun;
import 'neferhoo_pilot.dart' show NeferhooPilot, expert;
import 'play_session_test.dart' show SessionSource, SilentAudio;
import 'steam_bot.dart' show steamTapper;

const _review = String.fromEnvironment('M1_REVIEW');
const _videoEvery = int.fromEnvironment('M1_VIDEO');

/// Every sound the app asks for, with the flight's clock (or -1 off it),
/// and every in-flight voice line chosen; the combat and boss cue layers run
/// as `SkyAudio.syncCombat` runs them.
class LoggingAudio extends SilentAudio {
  LoggingAudio(this.log);
  final List<(double, String)> log;
  final _boss = BossAudioCues();
  final _combat = CombatAudioCues();
  double _t = -1;

  @override
  void syncCombat(FlightSimulation simulation, {bool silent = false}) {
    _t = simulation.elapsed;
    for (final cue in _combat.advance(simulation, silent: silent)) {
      log.add((_t, cue));
    }
    for (final cue in _boss.advance(simulation.boss, silent: silent)) {
      log.add((_t, cue));
    }
    final line = voices?.update(simulation, mute: silent);
    if (line != null) log.add((_t, 'voice:${line.clip.name}'));
  }

  @override
  void effect(String name, {int? variant}) => log.add((_t, name));

  @override
  void speak(String asset, {double duck = .35}) => log.add((_t, 'say:$asset'));
}

enum Save { migrated, fresh }

CampaignLevel _level(String id) => Campaign.level(id)!;

/// A schema-5 save as the old build wrote it (the old ids: 2-6..2-8 were
/// Arabia): every level of chapters 1 and 2 and New York finished, the old
/// Arabian records, flights and watched scenes, then opened by this build
/// (schema 6 renames them once, highest id first).
Future<void> _oldSave(File file) async {
  final db = ProgressDatabase(NativeDatabase(file));
  final played = DateTime(2026, 9, 30, 18);
  const old = [
    '1-1', '1-2', '1-3', '1-4', '1-5', '1-6', '1-7', '1-8', //
    '2-1', '2-2', '2-3', '2-4', '2-5', '2-6', '2-7', '2-8', //
    '3-1', '3-2', '3-3', '3-4',
  ];
  const stars = {'2-6': 2, '2-7': 1, '2-8': 3};
  for (final id in old) {
    await db
        .into(db.levelProgress)
        .insert(
          LevelProgressCompanion.insert(
            level: id,
            bestStars: Value(stars[id] ?? 3),
            bestCollected: const Value(30),
            bestScore: Value(100 + int.parse(id.replaceAll('-', ''))),
            plays: const Value(2),
            firstClearedAt: Value(played),
            lastPlayedAt: Value(played),
            postcardSeen: Value(id == '2-8' || id == '1-8'),
          ),
        );
  }
  for (final id in ['2-6', '2-7', '2-8']) {
    await db
        .into(db.runs)
        .insert(
          RunsCompanion.insert(
            id: 'run-old-$id',
            mode: PlayMode.touch.index,
            course: Value(FlightCourse.starTrail.name),
            practice: false,
            score: 10,
            repetitions: 0,
            flaps: 30,
            duration: 60,
            reason: EndReason.completed.name,
            finishedAt: played,
            level: Value(id),
          ),
        );
  }
  Future<void> put(String key, String value) => db
      .into(db.preferences)
      .insert(PreferencesCompanion.insert(key: key, value: value));
  // Everything a returning player had seen (the old 2-6 and 2-8 scenes are
  // Arabia's: before-2-6 becomes before-2-7 at the migration).
  await put(
    'storyWatched',
    'before-1-1,before-1-3,before-1-8,after-1,before-2-1,before-2-4,'
        'before-2-6,before-2-8,after-2,before-3-1,before-3-2,last-3-2,'
        'before-3-4,last-3-4',
  );
  await put(
    'flightVoices',
    jsonEncode({
      'said': 9,
      'flights': 3,
      'last': {'pip-cargo-2-6-01': 3},
      'lastFlight': {'pip-cargo-2-6-01': 1},
      'met': <String>[],
    }),
  );
  await put('music', 'false');
  await put('voices', 'false');
  await db.customStatement('PRAGMA user_version = 5');
  await db.close();
}

/// A fresh save at 2-6's door: chapter 1 and 2-1..2-5 finished, their
/// scenes and chapter 1's postcard seen.
Future<void> _freshSave(ProgressRepository repo) async {
  var n = 0;
  for (final level in Campaign.levels) {
    if (level.id == '2-6') break;
    await repo.saveRun(
      levelRun(
        'seed-${n++}',
        level.id,
        stars: level.marks.three,
        at: DateTime(2026, 9, 20, 12, n),
      ),
    );
    if (CampaignStory.before(level) case final scene?) {
      await repo.markStoryWatched(scene);
    }
  }
  await repo.markPostcardSeen(Campaign.chapters.first);
  await repo.markStoryWatched(CampaignStory.after(Campaign.chapters.first));
  await repo.setSetting(SettingKey.music, false);
  await repo.setSetting(SettingKey.voices, false);
}

/// What one width's run showed and wrote.
class _Run {
  _Run(this.px, this.save, this.folder, this.tag);
  final double px;
  final Save save;
  final Directory? folder;
  final stills = <(String, ui.Image)>[];
  final strip = <(String, ui.Image)>[];
  final story = <(String, ui.Image)>[];
  final audio = <(double, String)>[];
  final notes = <String>[];
  Process? video;
  int videoFrames = 0;
  final String tag;
}

Future<void> _loadFonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

const _captureKey = ValueKey('m1-capture');

Future<ui.Image> _grab(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  return (await tester.runAsync(() => boundary.toImage()))!;
}

/// Repaints the play screen (the HUD and the paused game) as it stands.
Future<void> _redraw(WidgetTester tester, PlayController controller) async {
  controller.notify();
  await tester.pump();
  for (final box in tester.allRenderObjects) {
    if (box.runtimeType.toString() == 'GameRenderBox') box.markNeedsPaint();
  }
  await tester.pump();
}

Future<void> _png(WidgetTester tester, ui.Image image, File file) async {
  await tester.runAsync(() async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Labelled frames in a contact sheet [cols] wide.
Future<void> _sheet(
  WidgetTester tester,
  File file,
  List<(String, ui.Image)> frames, {
  int cols = 3,
}) async {
  if (frames.isEmpty) return;
  final fw = frames.first.$2.width.toDouble();
  final fh = frames.first.$2.height.toDouble();
  final rows = (frames.length / cols).ceil();
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.drawRect(
    Rect.fromLTWH(0, 0, fw * cols, (fh + 18) * rows),
    Paint()..color = const Color(0xff101223),
  );
  for (var i = 0; i < frames.length; i++) {
    final (label, image) = frames[i];
    final at = Offset(i % cols * fw, (i ~/ cols) * (fh + 18));
    c.drawImage(image, at + const Offset(0, 18), Paint());
    final p = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 13,
          color: Color(0xffffffff),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: fw - 8);
    p.paint(c, at + const Offset(4, 1));
  }
  final picture = recorder.endRecording();
  await tester.runAsync(() async {
    final image = await picture.toImage(
      (fw * cols).toInt(),
      ((fh + 18) * rows).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  picture.dispose();
}

Future<void> _videoFrame(WidgetTester tester, _Run run, ui.Image image) async {
  final video = run.video;
  if (video == null) return;
  await tester.runAsync(() async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    video.stdin.add(bytes!.buffer.asUint8List());
    await video.stdin.flush();
  });
  run.videoFrames++;
}

/// Holds the current picture in the video for [seconds] (a still screen).
Future<void> _videoHold(
  WidgetTester tester,
  _Run run,
  ui.Image image,
  double seconds,
) async {
  if (run.video == null) return;
  final frames = (seconds * 60 / _videoEvery).round();
  for (var i = 0; i < frames; i++) {
    await _videoFrame(tester, run, image);
  }
}

/// Reads every line of the story scene on screen: each written out and
/// captured, then a tap for the next. Returns how many lines it showed.
Future<int> _playScene(
  WidgetTester tester,
  _Run run,
  String id, {
  int? stopAfter,
}) async {
  final key = find.byKey(ValueKey('story-scene-$id'));
  expect(key, findsOneWidget, reason: 'the scene $id plays');
  final scene = CampaignStory.scene(id)!;
  var shown = 0;
  for (var i = 0; i < scene.lines.length; i++) {
    for (var k = 0; k < 20; k++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    shown++;
    if (run.folder != null && (stopAfter == null || i < stopAfter)) {
      final image = await _grab(tester);
      run.story.add(('$id line $i', image));
      await _videoHold(tester, run, image, 1.2);
    }
    if (stopAfter != null && i + 1 >= stopAfter) break;
    await tester.tapAt(Offset(run.px / 2, 120));
    await tester.pump(const Duration(milliseconds: 50));
  }
  return shown;
}

/// The run-up's pilot, as New York's average one flies a run-up
/// (`ny_pilots.dart`): the shared steam tapper at 3.5 taps a second, a
/// tapped shot every 22 frames, a charged one every 144, Sprint when ready.
void _runUp(PlayController c, FlightSimulation sim, int frame) {
  if (steamTapper(sim, react: .6, taps: 3.5, clearance: .10)) c.flap();
  if (sim.canSprint) c.sprint();
  if (!sim.offersShoot) return;
  final at = frame % 144;
  if (at == 0) {
    c.startCharge();
  } else if (at == 48) {
    c.shoot();
  } else if (frame % 22 == 0 && !sim.charging && sim.canShoot) {
    c.startCharge();
    c.shoot();
  }
}

Future<void> _flow(
  WidgetTester tester,
  double px,
  Save save, {
  bool reduced = false,
}) async {
  final name = '${px.round()}${reduced ? '-rm' : ''}';
  final folder = _review.isEmpty ? null : Directory('$_review/flight-$name');
  folder?.createSync(recursive: true);
  final run = _Run(px, save, folder, name);
  tester.view.physicalSize = Size(px, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // ---- the save
  final temp = Directory.systemTemp.createTempSync('m1-flight');
  addTearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });
  late final SqliteProgressRepository repo;
  await tester.runAsync(() async {
    if (save == Save.migrated) {
      final file = File('${temp.path}/sky_club.sqlite');
      await _oldSave(file);
      repo = SqliteProgressRepository(ProgressDatabase(NativeDatabase(file)));
    } else {
      repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      await _freshSave(repo);
    }
    await repo.setSetting(SettingKey.reducedMotion, reduced);
  });
  final before = (await tester.runAsync(repo.load))!;
  final c0 = before.campaign;
  expect(c0.unlocked(_level('2-6')), isTrue, reason: '2-6 is open');
  expect(c0.cleared(_level('2-6')), isFalse, reason: 'the new level waits');
  if (save == Save.migrated) {
    // The old Arabia moved up by one and stays open (a finished level stays
    // open), New York too; 2-6 is the current level.
    expect(c0.stars(_level('2-7')), 2);
    expect(c0.stars(_level('2-8')), 1);
    expect(c0.stars(_level('2-9')), 3);
    expect(c0.unlocked(_level('2-7')), isTrue);
    expect(c0.unlocked(_level('3-4')), isTrue);
    run.notes.add(
      'migrated save: 2-7/2-8/2-9 stars ${c0.stars(_level('2-7'))}/'
      '${c0.stars(_level('2-8'))}/${c0.stars(_level('2-9'))}, 2-6 open and '
      'not cleared, current ${c0.current.id}',
    );
  } else {
    expect(c0.unlocked(_level('2-7')), isFalse, reason: 'locked behind 2-6');
    expect(c0.current, same(_level('2-6')));
    run.notes.add('fresh save: 2-6 current, 2-7 locked');
  }

  // ---- the app
  final sessions = Directory('${temp.path}/sessions')..createSync();
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(sessions)),
      audioFactoryProvider.overrideWithValue(() => LoggingAudio(run.audio)),
      trackingSourceFactoryProvider.overrideWithValue(SessionSource.new),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(() => tester.runAsync(repo.close));
  await tester.runAsync(() => container.read(progressProvider.future));
  appRouter.go('/campaign?level=2-6');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(key: _captureKey, child: PushUpBirdApp()),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (folder != null && _videoEvery > 0) {
    run.video = (await tester.runAsync(
      () => Process.start('ffmpeg', [
        '-y',
        '-loglevel',
        'error',
        '-f',
        'rawvideo',
        '-pix_fmt',
        'rgba',
        '-s',
        '${px.round()}x360',
        '-r',
        '${60 / _videoEvery}',
        '-i',
        '-',
        '-c:v',
        'libx264',
        '-pix_fmt',
        'yuv420p',
        '-crf',
        '24',
        '$_review/neferhoo-2-6-$name.mp4',
      ]),
    ))!;
  }

  // ---- the map: 2-6's card waits behind its scene
  await _playScene(tester, run, 'before-2-6');
  for (var k = 0; k < 15; k++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byKey(const ValueKey('level-intro-2-6')), findsOneWidget);
  if (folder != null) {
    final card = await _grab(tester);
    run.stills.add(('2-6 card', card));
    await _videoHold(tester, run, card, 2);
  }

  // ---- Fly!
  await tester.tap(find.text('Fly!'));
  for (var k = 0; k < 6; k++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final dynamic state = tester.state(find.byType(PlayScreen));
  final controller = state.controller as PlayController;
  expect(controller.stage, PlayStage.flying);
  final sim = controller.simulation!;
  expect(sim.levelId, '2-6');
  expect(sim.rulesVersion, FlightSimulation.currentRulesVersion);
  final game = tester
      .widget<GameWidget<BirdGame>>(find.byType(GameWidget<BirdGame>))
      .game!;
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  await tester.pump();

  // ---- the flight, 60 frames a second, the pilot on the controller's keys
  final width = px / 360;
  NeferhooPilot? pilot;
  SkyBoss? boss;
  final shots = <String, double>{};
  final taken = <String>{};
  void want(String name, double at) => shots.putIfAbsent(name, () => at);
  var frame = 0;
  var hurts = 0, hearts = sim.hearts;
  var shield = sim.shield;
  double? lastReturn, lastLand, lastScuff;
  var mailLocks = 0, ankhLocks = 0;
  var hintFrames = 0, plateFrames = 0, fadedSeen = 0;
  var scuffLine = false;
  double? fightAt;
  for (; frame < 60 * 400; frame++) {
    if (sim.phase == RunPhase.ended) break;
    final b = sim.boss;
    if (b != null && b.isNeferhoo) boss = b;
    if (b == null) {
      _runUp(controller, sim, frame);
    } else if (b.phase == BossPhase.attacking) {
      fightAt ??= sim.elapsed;
      // (the practised pilot: the flow must end in a win every time. From
      // rules 55 a careful family pilot loses about one fight in twenty
      // (`neferhoo_faster_pilot_test.dart`), and this seed at 640 is one.)
      pilot ??= NeferhooPilot(expert, seed: 1, careful: true);
      pilot.plan(sim);
      if (pilot.flap(sim)) controller.flap();
      if (pilot.shoot(sim)) {
        controller.startCharge();
        controller.shoot();
      }
    }
    hearts = sim.hearts;
    shield = sim.shield;
    controller.advance(1 / 60, 0, width);
    controller.tick();
    if (sim.hearts < hearts || (shield && !sim.shield)) hurts++;

    // what to capture, keyed on what the rules latched
    final t = sim.elapsed;
    if (frame == 60) want('run-up 1 s', t);
    if (frame == 60 * 12) want('run-up 12 s', t);
    if (frame == 60 * 24) want('run-up 24 s', t);
    final nb = sim.boss;
    if (nb != null && nb.isNeferhoo) {
      final age = nb.age;
      for (final (name, at) in [
        ('arrival: the omen', .4),
        ('arrival: the door, the sand devil', 1.0),
        ('arrival: the reveal', 1.75),
        ('arrival: HOO-POO-POO', 2.8),
        ('arrival: the name card', 3.4),
        ('arrival: hand-over', 4.5),
      ]) {
        if (age >= at && nb.defeatedAt == null) want(name, t);
      }
      final f = nb.neferhoo;
      if (f.mailLocks > mailLocks) {
        mailLocks = f.mailLocks;
        final stage = nb.stage;
        final kind = f.express ? 'EXPRESS POST' : 'mail call';
        want('$kind (stage $stage): the lane locks', t + .4);
        want('$kind (stage $stage): letters fly', t + 1.6);
      }
      if (f.ankhLocks > ankhLocks) {
        ankhLocks = f.ankhLocks;
        final two = f.twoAnkhs ? 'TWO ANKHS' : 'the ankh';
        want('$two: the loop locks', t + .7);
        want('$two: out', t + 1.4 + .6);
        want('$two: the turn', t + 1.4 + 1.5);
        final home = f.ankhs.last.homeAt(
          handX: nb.handX,
          turnX: Neferhoo.turnX(FlightSimulation.birdX),
        );
        want('$two: home', t + (home - nb.age) - .1);
      }
      if (f.lastReturnAt.isFinite && f.lastReturnAt != lastReturn) {
        lastReturn = f.lastReturnAt;
        want('first return: caught', t + .1);
        if (nb.enraged) want('return in fury', t + .1);
      }
      if (f.lastLandAt.isFinite && f.lastLandAt != lastLand) {
        lastLand = f.lastLandAt;
        want('first landing: -25, the stamp', t + .12);
        want('first landing: the stamp holds', t + .7);
      }
      if (f.lastScuffAt.isFinite && f.lastScuffAt != lastScuff) {
        lastScuff = f.lastScuffAt;
        want('a rock on his wraps: the scuff', t + .05);
      }
      if (nb.stageReached >= 1 && nb.stageUpAt.isFinite) {
        want('stage-up: STRONGER! (full fight)', t + .5);
      }
      if (nb.enraged && nb.enragedAt.isFinite) {
        want('fury: the roar', t + .3);
        want('fury: the wraps open', t + 1.6);
      }
      if (nb.defeatedAt case final d?) {
        for (final (name, at) in [
          ('defeat: the killing blow', .06),
          ('defeat: the wraps peel', .5),
          ('defeat: the mask pops', .95),
          ('defeat: GUARDIAN DOWN', 1.8),
          ('defeat: the lost letter', 3.0),
          ('defeat: the lost letter flares (its chime)', 3.3),
        ]) {
          want(name, t + (d + at - age));
        }
      }
    }
    if (sim.victoryGlide) want('victory glide', t + .5);
    // the fix round's evidence: the hint pill, the ankh under the faded plate
    if (nb != null && nb.isNeferhoo) {
      final pill = NeferhooFightArt.hintPill(Size(px, 360), nb);
      if (pill != null && pill.alpha >= 1) {
        hintFrames++;
        want(
          pill.text == Neferhoo.returnHint
              ? 'hint: RETURN TO SENDER! -25'
              : 'hint: the adaptive line (8 scuffs, no return)',
          t,
        );
        if (pill.text == Neferhoo.neferhooScuffHint) scuffLine = true;
      }
      final plate = NeferhooFightArt.hudPlateAlpha(Size(px, 360), nb);
      if (plate < 1) {
        plateFrames++;
        for (final a in nb.liveAnkhs) {
          final p = NeferhooFightArt.ankhCentre(a, nb, reduced: reduced);
          if (p != null && Rect.fromCircle(center: p * 360, radius: Neferhoo.ankhRadius * 360).overlaps(neferhooHudPlate(Size(px, 360)))) {
            want('the ankh under the faded hearts plate', t);
          }
        }
      }
    }

    final due = [
      for (final e in shots.entries)
        if (!taken.contains(e.key) && t >= e.value - 1e-9) e.key,
    ];
    final videoFrame = run.video != null && frame % _videoEvery == 0;
    if ((due.isNotEmpty && folder != null) || videoFrame) {
      await _redraw(tester, controller);
      final image = await _grab(tester);
      // the play screen fades its hearts plate exactly as the fight art says
      final nb2 = sim.boss;
      if (nb2 != null && nb2.isNeferhoo && sim.phase == RunPhase.playing) {
        final opacity = find.ancestor(of: find.byKey(const ValueKey('match-health')), matching: find.byType(Opacity));
        if (opacity.evaluate().isNotEmpty) {
          expect(
            tester.widget<Opacity>(opacity.first).opacity,
            closeTo(NeferhooFightArt.hudPlateAlpha(Size(px, 360), nb2), 1e-9),
          );
          if (tester.widget<Opacity>(opacity.first).opacity < 1) fadedSeen++;
        }
      }
      if (fightAt != null && !run.notes.any((n) => n.startsWith('HUD'))) {
        final plate = find.byKey(const ValueKey('match-health'));
        if (plate.evaluate().isNotEmpty) {
          final got = tester.getRect(plate);
          run.notes.add('HUD hearts plate $got');
          // the fight art's idea of it (its tags keep clear) is the real one
          final s = math.min(px / 1000, 360 / 450);
          final art = neferhooHudPlate(Size(px, 360)).deflate(4 * s);
          for (final d in [got.left - art.left, got.top - art.top, got.right - art.right, got.bottom - art.bottom]) {
            expect(d.abs(), lessThan(1.5), reason: 'HUD plate $got vs the art\'s $art');
          }
        }
      }
      if (videoFrame) await _videoFrame(tester, run, image);
      for (final name in due) {
        taken.add(name);
        final label = fightAt == null
            ? '$name · flight ${t.toStringAsFixed(1)} s'
            : '$name · fight ${(t - fightAt).toStringAsFixed(1)} s'
            '${boss != null && boss.phase == BossPhase.attacking ? ' · hp ${boss.hp}' : ''}';
        run.strip.add((label, image));
      }
      if (due.isEmpty) image.dispose();
    } else {
      taken.addAll(due);
    }
  }

  // ---- the end
  expect(sim.endReason, EndReason.completed, reason: 'the pilot finished 2-6');
  expect(boss, isNotNull);
  final fight = boss!.neferhoo;
  final fightSeconds = boss.defeatedAt! - boss.arrivalDuration;
  run.notes.add(
    'flight ${sim.elapsed.toStringAsFixed(1)} s, fight ${fightSeconds.toStringAsFixed(1)} s '
    '(stage-ups at ${boss.stageReached}), hurts $hurts, hearts ${sim.hearts}, '
    'stars ${sim.collectedStars}; mail calls ${fight.mailLocks}, letters ${fight.lettersDealt}, '
    'returned ${fight.lettersReturned}, landed ${fight.returnsLanded}, scuffs ${fight.wrapScuffs}, '
    'ankh locks ${fight.ankhLocks}, throws ${fight.ankhThrows}, catches ${fight.ankhCatches}, '
    'hits by letter/ankh ${fight.letterHits}/${fight.ankhHits}',
  );
  expect(fight.returnsLanded, greaterThan(0));
  expect(fight.ankhThrows, greaterThan(0));
  expect(boss.stageReached, 2);
  // the cues and the voices the flight played
  final heard = {for (final (_, cue) in run.audio) cue};
  for (final cue in [
    'sand_devil',
    'hoopoe_roar',
    'mail_call',
    'letter_flick',
    'letter_return',
    'postage_due',
    'ankh_raise',
    'ankh_whir',
    'ankh_catch',
    'mummy_fury',
    'mask_pop',
    'lost_letter',
  ]) {
    expect(heard, contains(cue), reason: 'the flight plays $cue');
  }
  await tester.runAsync(() => controller.finish());
  for (var k = 0; k < 30; k++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(controller.stage, PlayStage.results);
  expect(controller.levelComplete, isTrue);
  expect(controller.nextLevel, same(_level('2-7')));
  run.notes.add('result: ${controller.levelStars} stars, next ${controller.nextLevel?.id}');
  expect(controller.levelStars, greaterThanOrEqualTo(2));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  for (var k = 0; k < 20; k++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // The unlock line is news only for a player who did not have 2-7 open:
  // a returning player (the migrated save) already had it (QA M4).
  final news = find.text('2-7 Lantern Bazaar is open!');
  expect(news, save == Save.migrated ? findsNothing : findsOneWidget);
  run.notes.add(
    'unlock line ${news.evaluate().isEmpty ? 'not shown' : 'shown'}; hint pill on screen '
    '$hintFrames frames (adaptive line ${scuffLine ? 'yes' : 'no'}); hearts plate faded for the ankh '
    '$plateFrames frames ($fadedSeen captured frames checked against the play screen)',
  );
  if (folder != null) {
    final result = await _grab(tester);
    run.stills.add(('2-6 result', result));
    await _videoHold(tester, run, result, 2.5);
  }

  // ---- Next: the map, where his last word plays, then 2-7's card
  final next = find.byKey(const ValueKey('level-result-next'));
  expect(next, findsOneWidget);
  await tester.tap(next);
  for (var k = 0; k < 10; k++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final p1 = container.read(progressProvider).value!.campaign;
  expect(p1.cleared(_level('2-6')), isTrue);
  expect(p1.unlocked(_level('2-7')), isTrue, reason: '2-6 opens 2-7');
  expect(p1.sceneLast(_level('2-6'))?.id, 'last-2-6');
  final lines = await _playScene(tester, run, 'last-2-6');
  expect(lines, CampaignStory.lastWord(_level('2-6'))!.lines.length);
  for (var k = 0; k < 15; k++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (save == Save.fresh) {
    // Arabia's arrival plays before 2-7's card the first time.
    await _playScene(tester, run, 'before-2-7', stopAfter: 1);
    final skip = find.text('Skip');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip.first);
    } else {
      for (var i = 1; i < CampaignStory.before(_level('2-7'))!.lines.length; i++) {
        await tester.tapAt(Offset(px / 2, 120));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(Offset(px / 2, 120));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    for (var k = 0; k < 15; k++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  expect(find.byKey(const ValueKey('level-intro-2-7')), findsOneWidget);
  final p2 = container.read(progressProvider).value!;
  expect(p2.campaign.sceneLast(_level('2-6')), isNull, reason: 'watched once');
  if (save == Save.fresh) expect(p2.campaign.current, same(_level('2-7')));
  if (folder != null) {
    final card = await _grab(tester);
    run.stills.add(('2-7 card (open)', card));
    await _videoHold(tester, run, card, 2);
  }
  // the map itself
  appRouter.go('/campaign');
  for (var k = 0; k < 20; k++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (folder != null) {
    final map = await _grab(tester);
    run.stills.add(('the map after 2-6', map));
    await _videoHold(tester, run, map, 2);
  }
  run.notes.add(
    'after: 2-6 ${p2.campaign.stars(_level('2-6'))} stars, 2-7 unlocked '
    '${p2.campaign.unlocked(_level('2-7'))}, current ${p2.campaign.current.id}, '
    'total ${p2.campaign.totalStars}',
  );

  // ---- write it out
  if (folder != null) {
    final tag = run.tag;
    final per = 9;
    for (var i = 0; i * per < run.strip.length; i++) {
      await _sheet(
        tester,
        File('${folder.path}/strip-$tag-${(i + 1).toString().padLeft(2, '0')}.png'),
        run.strip.sublist(i * per, ((i + 1) * per).clamp(0, run.strip.length)),
      );
    }
    await _sheet(tester, File('${folder.path}/story-$tag-before-2-6.png'), [
      for (final s in run.story)
        if (s.$1.startsWith('before-2-6')) s,
    ]);
    await _sheet(tester, File('${folder.path}/story-$tag-last-2-6.png'), [
      for (final s in run.story)
        if (s.$1.startsWith('last-2-6')) s,
    ]);
    await _sheet(tester, File('${folder.path}/screens-$tag.png'), run.stills, cols: 2);
    for (final (name, image) in run.stills) {
      await _png(tester, image, File('${folder.path}/$tag-${name.replaceAll(RegExp(r'[^a-z0-9-]+'), '-')}.png'));
    }
    final log = StringBuffer()
      ..writeln('# 2-6 at ${px.round()}x360, ${save.name} save${reduced ? ', Reduced Motion' : ''}')
      ..writeAll(run.notes.map((n) => '$n\n'))
      ..writeln('## sounds and voice lines (flight seconds)');
    for (final (t, cue) in run.audio) {
      if (cue == 'flap' || cue == 'shoot') continue;
      log.writeln('${t.toStringAsFixed(2)} $cue');
    }
    File('${folder.path}/log-$tag.txt').writeAsStringSync(log.toString());
    final video = run.video;
    if (video != null) {
      await tester.runAsync(() async {
        await video.stdin.close();
        await video.exitCode;
      });
    }
    // (one frame can carry several labels: dispose each image once)
    for (final image in Set<ui.Image>.identity()
      ..addAll([for (final (_, i) in [...run.stills, ...run.strip, ...run.story]) i])) {
      image.dispose();
    }
  }
  // ignore: avoid_print
  print('${run.tag}: ${run.notes.join('\n  ')}');
}

void main() {
  setUpAll(_loadFonts);
  for (final (px, save, reduced) in [
    (640.0, Save.migrated, false),
    (800.0, Save.fresh, false),
    (864.0, Save.fresh, false),
    (640.0, Save.fresh, true),
    (792.0, Save.fresh, false),
  ]) {
    testWidgets(
      '2-6 for real at ${px.round()} x 360 (${save.name} save'
      '${reduced ? ', Reduced Motion' : ''}): map, scene, '
      'flight, defeat, result, last word, 2-7 open',
      (tester) => _flow(tester, px, save, reduced: reduced),
      // (the suite flies a returning player at 640 and a fresh one at 800)
      skip: _review.isEmpty && !(px == 640 && !reduced || px == 800),
      timeout: const Timeout(Duration(minutes: 20)),
    );
  }
}
