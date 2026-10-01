// The level card of a guardian's level: a GUARDIAN ribbon in the guardian's
// colour in place of the chapter boss's crown band, the level's own number on
// its coin, the NEW (or TIP) hint from the level data, the run-up and the
// goals. The card of a chapter's boss and of an ordinary level do not change.
// Levels are built here (`nyWheels`, `nyStorm`), so these tests do not depend
// on the catalog's 3-2 and 3-4 having bosses yet.
@Timeout(Duration(minutes: 4))
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/ui/campaign_map.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/level_intro.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'ny_plans.dart';
import 'ny_ui_support.dart';

Future<void> _pump(
  WidgetTester tester,
  Size size,
  CampaignLevel level, {
  LevelRecord? record,
  bool story = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final grow = (size.height / 360).clamp(1.0, 1.2);
  await tester.pumpWidget(
    nyHarness(
      Stack(
        fit: StackFit.expand,
        children: [
          CampaignMap(
            stops: nyStops(stars: const {'3-1': 3}),
            bird: 0,
            reducedMotion: true,
            chromeHidden: true,
            focusStop: 0,
            onLevel: (_) {},
          ),
          ColoredBox(color: SkyColors.ink.withValues(alpha: .4)),
          SafeArea(
            minimum: const EdgeInsets.all(10),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: LevelIntroCard.size.width * grow,
                  maxHeight: LevelIntroCard.size.height * grow,
                ),
                child: LevelIntroCard(
                  level: level,
                  record: record ?? LevelRecord(levelId: level.id),
                  onFly: () {},
                  onClose: () {},
                  onStory: story ? () {} : null,
                ),
              ),
            ),
          ),
        ],
      ),
      size,
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(CampaignMap));
    for (final asset in birdAssets) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await tester.pump(const Duration(milliseconds: 400));
}

const _sizes = [Size(640, 360), Size(800, 360)];

/// A guardian level without a hint, which shows the controls instead.
final _noHint = CampaignLevel(
  name: nyWheels.name,
  delivery: nyWheels.delivery,
  plan: nyPlan(id: '3-2', boss: BossKind.kingCoo),
);

/// The same level with a TIP (a hint that is not new).
final _tip = CampaignLevel(
  name: nyStorm.name,
  delivery: nyStorm.delivery,
  hint: 'Stay out of the light. Shoot the lamp when it opens!',
  hintIsNew: false,
  bossLine: nyStorm.bossLine,
  plan: nyStorm.plan,
);

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

  test('the two levels are guardians, not chapter bosses', () {
    for (final level in [nyWheels, nyStorm]) {
      expect(level.isBoss, isTrue);
      expect(level.isGuardian, isTrue, reason: level.id);
      expect(level.isChapterBoss, isFalse, reason: level.id);
    }
    expect(Campaign.level('1-8')!.isChapterBoss, isTrue);
    expect(Campaign.level('1-8')!.isGuardian, isFalse);
  });

  test('the goals name the guardian and keep the two marks', () {
    expect(LevelIntroCard.goals(nyWheels), [
      'Beat King Coo',
      'Collect 20 stars',
      'Collect 30 stars',
    ]);
    expect(LevelIntroCard.goals(nyStorm).first, 'Beat Searchlight Gargoyle');
    // A chapter's boss and an ordinary level read as before.
    expect(
      LevelIntroCard.goals(Campaign.level('1-8')!).first,
      'Beat Baron Bat',
    );
    expect(
      LevelIntroCard.goals(Campaign.level('1-1')!).first,
      'Reach the finish',
    );
  });

  for (final size in _sizes) {
    final w = size.width.round();

    group('at $w', () {
      testWidgets('King Coo\'s card: ribbon, number, hint, run-up, goals', (
        tester,
      ) async {
        await _pump(tester, size, nyWheels);
        expect(tester.takeException(), isNull);
        final ribbon = find.byKey(const ValueKey('level-intro-guardian'));
        expect(ribbon, findsOneWidget);
        expect(
          find.descendant(of: ribbon, matching: find.text('GUARDIAN')),
          findsOneWidget,
        );
        // The pinned shield wears the guardian's headwear.
        expect(
          find.byKey(const ValueKey('level-intro-shield')),
          findsOneWidget,
        );
        // Not the chapter boss's crown band.
        expect(find.text('BOSS FIGHT'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(LevelIntroCard),
            matching: find.text('3-2'),
          ),
          findsOneWidget,
        );
        expect(find.text('Wheels in the Rain'), findsOneWidget);
        expect(find.text('A 30 s run-up first'), findsOneWidget);
        expect(find.text('NEW'), findsOneWidget);
        expect(
          find.text('Alley pigeons swoop in to grab stars. Shoot them first!'),
          findsOneWidget,
        );
        expect(find.text('Beat King Coo'), findsOneWidget);
        expect(find.text('Collect 20 stars'), findsOneWidget);
        expect(find.text('Collect 30 stars'), findsOneWidget);
        expect(find.text('First flight'), findsOneWidget);
        // The parcel tag is an ordinary one.
        expect(
          find.text('Umbrellas for the newsstand pigeons'),
          findsOneWidget,
        );
      });

      testWidgets('the Gargoyle\'s card wears its own colour', (tester) async {
        await _pump(tester, size, nyStorm);
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('level-intro-guardian')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(LevelIntroCard),
            matching: find.text('3-4'),
          ),
          findsOneWidget,
        );
        expect(find.text('Beat Searchlight Gargoyle'), findsOneWidget);
        expect(
          find.text('Stay out of the light. Shoot the lamp when it opens!'),
          findsOneWidget,
        );
      });

      testWidgets('nothing on the card touches the close and story keys, and '
          'the hint clears the story key', (tester) async {
        await _pump(tester, size, nyWheels);
        final card = tester.getRect(find.byType(LevelIntroCard));
        final close = tester.getRect(
          find.byKey(const ValueKey('level-intro-close')),
        );
        final story = tester.getRect(
          find.byKey(const ValueKey('level-intro-story')),
        );
        for (final (name, finder) in [
          ('name', find.text('Wheels in the Rain')),
          ('ribbon', find.byKey(const ValueKey('level-intro-guardian'))),
          ('run-up', find.text('A 30 s run-up first')),
          (
            'hint',
            find.text(
              'Alley pigeons swoop in to grab stars. Shoot them first!',
            ),
          ),
          ('goal', find.text('Beat King Coo')),
        ]) {
          final rect = tester.getRect(finder);
          expect(card.contains(rect.topLeft), isTrue, reason: name);
          expect(card.contains(rect.bottomRight), isTrue, reason: name);
          expect(rect.overlaps(close.deflate(4)), isFalse, reason: name);
          expect(rect.overlaps(story.deflate(4)), isFalse, reason: name);
        }
        // The Fly key and the goals keep apart.
        final fly = tester.getRect(
          find.byKey(const ValueKey('level-intro-fly')),
        );
        expect(
          tester.getRect(find.text('Collect 30 stars')).overlaps(fly),
          isFalse,
        );
      });

      testWidgets('a level with no hint shows the controls, a TIP is teal', (
        tester,
      ) async {
        await _pump(tester, size, _noHint);
        expect(tester.takeException(), isNull);
        expect(find.text('NEW'), findsNothing);
        expect(find.text('Flap'), findsOneWidget);
        expect(find.text('Shoot'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('level-intro-guardian')),
          findsOneWidget,
        );
        await _pump(tester, size, _tip);
        expect(tester.takeException(), isNull);
        expect(find.text('TIP'), findsOneWidget);
        expect(find.text('NEW'), findsNothing);
      });

      testWidgets('a beaten guardian ticks its goals and shows the best', (
        tester,
      ) async {
        await _pump(
          tester,
          size,
          nyWheels,
          record: LevelRecord(
            levelId: '3-2',
            bestStars: 2,
            bestCollected: 24,
            bestScore: 480,
            plays: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Best: 24 stars'), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      });

      testWidgets('a chapter boss keeps its crown band and no ribbon; an '
          'ordinary level keeps its header', (tester) async {
        Finder inCard(Finder finder) =>
            find.descendant(of: find.byType(LevelIntroCard), matching: finder);
        await _pump(tester, size, Campaign.level('3-8')!);
        expect(find.text('BOSS FIGHT'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('level-intro-guardian')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('level-intro-shield')), findsNothing);
        expect(inCard(find.text('3-8')), findsNothing);
        await _pump(tester, size, Campaign.level('3-1')!);
        expect(find.text('BOSS FIGHT'), findsNothing);
        expect(
          find.byKey(const ValueKey('level-intro-guardian')),
          findsNothing,
        );
        expect(inCard(find.text('3-1')), findsOneWidget);
        // 60 s since the fix round (it was 70 s).
        expect(find.text('About 60 s to the finish'), findsOneWidget);
      });
    });
  }

  testWidgets('the card reads aloud as a guardian\'s level', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _sizes[1], nyWheels);
    expect(
      find.bySemanticsLabel(
        'Level 3-2, Wheels in the Rain. New York. Guardian level: King Coo.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Special delivery: Umbrellas for the newsstand pigeons.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('One star: Beat King Coo.'), findsOneWidget);
    // A chapter's boss and an ordinary level keep their plain labels.
    await _pump(tester, _sizes[1], Campaign.level('3-1')!);
    expect(
      find.bySemanticsLabel('Level 3-1, Moth Light. New York.'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
