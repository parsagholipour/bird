import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/passport_progress.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/domain/sky_passport.dart';
import 'package:push_up_bird/ui/passport_screen.dart';
import 'package:push_up_bird/ui/screen_frame.dart';
import 'package:push_up_bird/ui/theme.dart';

/// A repository that always loads [snapshot].
class _Fixed extends SqliteProgressRepository {
  _Fixed(this.snapshot) : super(ProgressDatabase(NativeDatabase.memory()));
  final ProgressSnapshot snapshot;
  @override
  Future<ProgressSnapshot> load() async => snapshot;
}

/// Some stamps without a medal, some bronze, silver and gold.
const mixed = ProgressSnapshot(
  touch: ModeRecord(runs: 70, stars: 3400, perfectPasses: 20, bestCombo: 12),
  trailTouch: ModeRecord(
    runs: 50,
    best: 640,
    stars: 1800,
    perfectPasses: 10,
    completions: 3,
  ),
  birdsFlown: {1, 2},
  birdFlights: {1: 80, 2: 40},
);

/// Pumps the passport on the reference phone and, with
/// --dart-define=CAPTURE_VISUALS=true, writes
/// build/visual-review/passport/NAME.png.
Future<void> _passport(
  WidgetTester tester,
  ProgressSnapshot snapshot,
  String name,
) async {
  tester.view.physicalSize = ScreenFrame.design * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _Fixed(snapshot);
  addTearDown(repo.close);
  // A fresh scope, so a second passport loads its own progress.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [progressRepositoryProvider.overrideWithValue(repo)],
      child: RepaintBoundary(
        key: const ValueKey('visual-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: skyTheme(),
          home: const PassportScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/visual-review/passport')
      ..createSync(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// Every medal of every stamp.
const allGold = ProgressSnapshot(
  touch: ModeRecord(runs: 470, stars: 5000, perfectPasses: 1000, bestCombo: 80),
  trailTouch: ModeRecord(best: 2000, completions: 250),
  pushUp: ModeRecord(runs: 10),
  squat: ModeRecord(runs: 10),
  jump: ModeRecord(runs: 10),
  birdsFlown: {0, 1, 2, 3},
  birdFlights: {0: 25, 1: 300, 2: 150, 3: 25},
);

StampProgress _stamp(ProgressSnapshot p, SkyStamp stamp) =>
    p.passport.singleWhere((s) => s.stamp == stamp);

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test('a new passport has eight stamps of three medals, none won', () {
    const progress = ProgressSnapshot();
    expect(progress.passport, hasLength(8));
    expect(passportMedals, 24);
    expect(progress.earnedMedals, 0);
    expect(progress.medals, isEmpty);
    expect(progress.nextStamp?.stamp, SkyStamp.frequentFlyer);
    expect(progress.nextStamp?.aim, StampMedal.bronze);
    for (final stamp in SkyStamp.values) {
      expect(stamp.targets, hasLength(3));
      expect(stamp.targets[0], lessThan(stamp.targets[1]));
      expect(stamp.targets[1], lessThan(stamp.targets[2]));
      // Endless flights are what players know; Star Trail is internal.
      for (final medal in StampMedal.values) {
        expect(stamp.goal(medal), isNot(contains('Star Trail')));
      }
    }
  });

  test('stars earn bronze at 50, silver at 500 and gold at 5,000', () {
    expect(SkyStamp.starChaser.targets, [50, 500, 5000]);
    final none = StampProgress(SkyStamp.starChaser, 17);
    expect(none.medal, isNull);
    expect(none.earned, isFalse);
    expect(none.tally, '17/50');
    expect(none.remaining, 33);
    expect(none.fraction, .34);
    final bronze = StampProgress(SkyStamp.starChaser, 499);
    expect(bronze.medal, StampMedal.bronze);
    expect(bronze.nextMedal, StampMedal.silver);
    expect(bronze.goal, 'Collect 500 stars.');
    expect(bronze.tally, '499/500');
    expect(bronze.nextTitle, 'Star chaser · Silver');
    final gold = StampProgress(SkyStamp.starChaser, 6000);
    expect(gold.medal, StampMedal.gold);
    expect(gold.complete, isTrue);
    expect(gold.nextMedal, isNull);
    expect(gold.fraction, 1);
    expect(gold.remaining, 0);
    expect(gold.tally, '6,000/5,000');
    expect(gold.medalTitle, 'Star chaser: Gold');
    expect(SkyStamp.starChaser.goal(StampMedal.gold), 'Collect 5,000 stars.');
  });

  test('the endless-flight stamps read only endless flights', () {
    const progress = ProgressSnapshot(
      pushUp: ModeRecord(runs: 2, best: 400),
      trailJump: ModeRecord(runs: 6, best: 120, completions: 5),
      campaignFlights: ModeRecord(runs: 40, best: 900, completions: 30),
    );
    final captain = _stamp(progress, SkyStamp.skyCaptain);
    expect(captain.medal, StampMedal.bronze);
    expect(captain.tally, '120/500');
    expect(captain.goal, 'Score 500 points in one endless flight.');
    expect(_stamp(progress, SkyStamp.trailblazer).medal, StampMedal.bronze);
    expect(
      _stamp(progress, SkyStamp.trailblazer).goal,
      'Fly at least 60 seconds in 50 endless flights.',
    );
    // Every scored flight counts toward flying.
    expect(_stamp(progress, SkyStamp.frequentFlyer).current, 48);
  });

  test('the flock and mini game medals each ask for more than the last', () {
    const twoBirds = ProgressSnapshot(
      birdsFlown: {1, 2},
      birdFlights: {1: 90, 2: 40},
    );
    final flock = _stamp(twoBirds, SkyStamp.flockTogether);
    expect(flock.medal, StampMedal.bronze);
    expect(flock.tally, '2/4');
    const fourBirds = ProgressSnapshot(
      birdsFlown: {0, 1, 2, 3},
      birdFlights: {0: 30, 1: 90, 2: 40, 3: 24},
    );
    final flock4 = _stamp(fourBirds, SkyStamp.flockTogether);
    expect(flock4.medal, StampMedal.silver);
    // Gold counts the flights of the least flown bird.
    expect(flock4.tally, '24/25');

    const twoGames = ProgressSnapshot(
      pushUp: ModeRecord(runs: 2),
      trailJump: ModeRecord(runs: 30),
    );
    final games = _stamp(twoGames, SkyStamp.allRounder);
    expect(games.medal, StampMedal.bronze);
    expect(games.tally, '2/3');
    const threeGames = ProgressSnapshot(
      pushUp: ModeRecord(runs: 4),
      trailPushUp: ModeRecord(runs: 6),
      squat: ModeRecord(runs: 9),
      trailJump: ModeRecord(runs: 30),
    );
    final games3 = _stamp(threeGames, SkyStamp.allRounder);
    expect(games3.medal, StampMedal.silver);
    expect(games3.tally, '9/10');
    expect(games3.goal, 'Fly 10 scored flights in each mini game.');
    expect(_stamp(allGold, SkyStamp.allRounder).complete, isTrue);
  });

  test('a flight that raises a medal is told apart from one that does not', () {
    const before = ProgressSnapshot(touch: ModeRecord(runs: 3, stars: 480));
    const after = ProgressSnapshot(touch: ModeRecord(runs: 4, stars: 510));
    expect(before.medals, {SkyStamp.starChaser: StampMedal.bronze});
    final won = after.medalsWonSince(before.medals);
    expect(won.map((p) => p.medalTitle), ['Star chaser: Silver']);
    expect(after.medalsWonSince(after.medals), isEmpty);
    expect(after.earnedMedals, 2);
  });

  test(
    'the next stamp is the closest medal still to win, never a gold one',
    () {
      const progress = ProgressSnapshot(
        touch: ModeRecord(runs: 8, stars: 5200, perfectPasses: 22),
      );
      expect(_stamp(progress, SkyStamp.starChaser).complete, isTrue);
      expect(progress.nextStamp?.stamp, SkyStamp.onTheDot);
      expect(progress.nextStamp?.remaining, 3);
      expect(allGold.earnedMedals, 24);
      expect(allGold.nextStamp, isNull);
    },
  );

  testWidgets('the passport fits the phone with mixed medals', (tester) async {
    await _passport(tester, mixed, 'mixed');
    expect(find.text('9 / 24 MEDALS'), findsOneWidget);
    expect(find.text('Frequent flyer'), findsOneWidget);
    expect(find.text('120/500'), findsOneWidget);
    expect(find.text('STAMPED'), findsOneWidget);
    expect(find.textContaining('Star Trail'), findsNothing);
  });

  testWidgets('the passport fits the phone when new and when all gold', (
    tester,
  ) async {
    await _passport(tester, const ProgressSnapshot(), 'new');
    expect(find.text('0 / 24 MEDALS'), findsOneWidget);
    expect(find.text('STAMPED'), findsNothing);
    await _passport(tester, allGold, 'gold');
    expect(find.text('24 / 24 MEDALS'), findsOneWidget);
    expect(find.text('STAMPED'), findsNWidgets(8));
  });
}
