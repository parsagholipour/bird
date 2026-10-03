// The accessibility pass on New York's campaign screens (review 24): the text
// size is honoured up to 1.3x on the map, the level card, the result and the
// end card, the guardian plaque keeps 4.5:1 locked and unlocked, a locked
// shield wears a padlock, and a screen reader hears what unlocks a level.
// Pictures are built from data (`nyStops`, `nyWheels`, `nyStorm`), so these do
// not wait for the catalog's guardians.
@Timeout(Duration(minutes: 5))
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/game_rules.dart' show BossKind;
import 'package:push_up_bird/ui/campaign_chrome.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/campaign_map.dart';
import 'package:push_up_bird/ui/campaign_map_art.dart';
import 'package:push_up_bird/ui/campaign_screen.dart' show campaignStops;
import 'package:push_up_bird/ui/campaign_text_scale.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/level_intro.dart';
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/story_to_be_continued.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'ny_ui_support.dart';

const _sizes = [Size(640, 360), Size(800, 360)];

Future<void> _map(
  WidgetTester tester,
  Size size,
  List<CampaignMapStop> stops, {
  double textScale = 1,
  int focusStop = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    nyHarness(
      CampaignMap(
        key: UniqueKey(),
        stops: stops,
        bird: 0,
        reducedMotion: true,
        focusStop: focusStop,
        onLevel: (_) {},
        onLockedLevel: (_) {},
        leading: MapKey(
          glyph: MapGlyph.back,
          label: 'Back',
          reducedMotion: true,
          onPressed: () {},
        ),
        trailing: const CampaignStarTotal(stars: 5, of: 60),
      ),
      size,
      textScale: textScale,
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

Future<void> _card(
  WidgetTester tester,
  Size size,
  CampaignLevel level, {
  double textScale = 1,
  LevelRecord? record,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final grow = (size.height / 360).clamp(1.0, 1.2);
  await tester.pumpWidget(
    nyHarness(
      SafeArea(
        minimum: const EdgeInsets.all(10),
        child: Center(
          child: Builder(
            builder: (context) {
              final design = LevelIntroCard.sizeFor(
                CampaignTextScale.of(context),
              );
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: design.width * grow,
                  maxHeight: design.height * grow,
                ),
                child: LevelIntroCard(
                  level: level,
                  record: record ?? LevelRecord(levelId: level.id),
                  onFly: () {},
                  onClose: () {},
                  onStory: () {},
                ),
              );
            },
          ),
        ),
      ),
      size,
      textScale: textScale,
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

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
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  group('text size', () {
    test('the campaign follows the system size from 1x to 1.3x', () {
      expect(CampaignTextScale.max, 1.3);
      expect(LevelIntroCard.sizeFor(1), LevelIntroCard.size);
      expect(
        LevelIntroCard.sizeFor(1.3).height,
        greaterThan(LevelIntroCard.size.height),
      );
      expect(LevelIntroCard.sizeFor(1.3).width, LevelIntroCard.size.width);
    });

    for (final size in _sizes) {
      final w = size.width.round();

      testWidgets('the map\'s lettering grows with it and stops at 1.3x at '
          '$w', (tester) async {
        final stops = nyStops(stars: const {'3-1': 3, '3-2': 2});
        Future<Map<String, Size>> measure(double scale) async {
          await _map(tester, size, stops, textScale: scale);
          expect(tester.takeException(), isNull, reason: 'text $scale');
          return {
            for (final text in [
              'New York',
              'GUARDIAN',
              'King Coo',
              'Steam Alley',
            ])
              text: tester.getSize(find.text(text).first),
            'total': tester.getSize(
              find.descendant(
                of: find.byKey(const ValueKey('campaign-star-total')),
                matching: find.text('5'),
              ),
            ),
          };
        }

        final normal = await measure(1);
        final large = await measure(1.3);
        final huge = await measure(2);
        for (final key in normal.keys) {
          expect(
            large[key]!.height,
            greaterThan(normal[key]!.height),
            reason: '$key at 1.3x is bigger than at 1x',
          );
          // 2x is held to 1.3x: the same picture.
          expect(huge[key], large[key], reason: '$key at 2x is held to 1.3x');
        }
        // Never smaller than its design size on a small text size.
        await _map(tester, size, stops, textScale: .8);
        expect(tester.getSize(find.text('New York').first), normal['New York']);
      });

      testWidgets('the plaques and nodes stay clear of each other at 1.3x at '
          '$w', (tester) async {
        await _map(
          tester,
          size,
          nyStops(stars: const {'3-1': 3, '3-2': 2, '3-3': 1, '3-4': 3}),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        final screen = Offset.zero & size;
        final plaques = {
          for (final name in ['King Coo', 'Searchlight Gargoyle'])
            name: tester.getRect(
              find.byKey(ValueKey('campaign-guardian-$name')),
            ),
        };
        for (final MapEntry(:key, :value) in plaques.entries) {
          expect(screen.contains(value.topLeft), isTrue, reason: key);
          expect(screen.contains(value.bottomRight), isTrue, reason: key);
          expect(value.width, lessThanOrEqualTo(176 * size.height / 360 + 1));
        }
        for (final id in ['3-1', '3-3']) {
          final node = tester.getRect(
            find.byKey(ValueKey('campaign-node-$id')),
          );
          for (final MapEntry(:key, :value) in plaques.entries) {
            expect(
              value.overlaps(node.deflate(8)),
              isFalse,
              reason: '$key over $id',
            );
          }
        }
        // The stars hang under the plaque, not behind it.
        final stars = tester.getRect(
          find
              .descendant(
                of: find.byKey(const ValueKey('campaign-node-3-2')),
                matching: find.byType(CustomPaint),
              )
              .last,
        );
        expect(stars.top, greaterThanOrEqualTo(0));
      });

      testWidgets('the level card makes room for larger text without '
          'overflowing, at $w', (tester) async {
        Future<double> effective(CampaignLevel level, double scale) async {
          await _card(tester, size, level, textScale: scale);
          expect(tester.takeException(), isNull, reason: '${level.id} $scale');
          // Text height on screen: the card is scaled to fit its box.
          return tester.getSize(find.text('Collect 20 stars')).height;
        }

        for (final level in [nyWheels, nyStorm, Campaign.level('3-8')!]) {
          final normal = await effective(level, 1);
          final large = await effective(level, 1.3);
          final huge = await effective(level, 2);
          expect(
            large,
            greaterThan(normal),
            reason: '${level.id}: 1.3x reads bigger',
          );
          expect(huge, large, reason: '${level.id}: 2x is held to 1.3x');
        }
        // The card stays on the screen at 1.3x, with its Fly key.
        await _card(tester, size, nyWheels, textScale: 1.3);
        final screen = Offset.zero & size;
        final card = tester.getRect(find.byType(LevelIntroCard));
        expect(screen.contains(card.topLeft), isTrue);
        expect(screen.contains(card.bottomRight), isTrue);
        final fly = tester.getRect(
          find.byKey(const ValueKey('level-intro-fly')),
        );
        expect(fly.height, greaterThanOrEqualTo(48));
        expect(fly.bottom, lessThanOrEqualTo(size.height));
        // Its words are all there.
        for (final text in [
          'Wheels in the Rain',
          'GUARDIAN',
          'Beat King Coo',
          'Collect 30 stars',
          'First flight',
          'Alley pigeons swoop in to grab stars. Shoot them first!',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
      });
    }

    testWidgets('every level\'s card fits at 1.3x and 2x text at both sizes', (
      tester,
    ) async {
      Campaign.openedForTest = true;
      for (final size in _sizes) {
        for (final level in Campaign.levels) {
          if (!Campaign.playable(level)) continue;
          for (final record in [
            null,
            LevelRecord(
              levelId: level.id,
              bestStars: 3,
              bestCollected: level.marks.three,
              bestScore: 900,
              plays: 3,
            ),
          ]) {
            await _card(tester, size, level, textScale: 2, record: record);
            expect(
              tester.takeException(),
              isNull,
              reason:
                  '${level.id} at ${size.width.round()} '
                  '${record == null ? 'new' : 'beaten'}',
            );
          }
        }
      }
    });

    testWidgets('a long hint takes a third line at 1.3x instead of an '
        'ellipsis', (tester) async {
      const hint =
          'Vents hiss, then burst. Fly over them. Soft puffs lift you up.';
      final level = CampaignLevel(
        name: nyWheels.name,
        delivery: nyWheels.delivery,
        hint: hint,
        plan: nyWheels.plan,
      );
      await _card(tester, _sizes[1], level, textScale: 1.3);
      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(hint));
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    for (final size in _sizes) {
      testWidgets('the end card sets larger text where the plate has room, at '
          '${size.width.round()}', (tester) async {
        Future<double> sizeAt(double scale) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            nyHarness(
              StoryScenePlayer(
                key: UniqueKey(),
                scene: nyLastWord,
                bird: 0,
                reducedMotion: true,
                onDone: () {},
              ),
              size,
              textScale: scale,
            ),
          );
          await tester.pump();
          for (var i = 0; i < nyLastWord.lines.length - 1; i++) {
            await tester.tap(find.byKey(const ValueKey('story-advance')));
            await tester.pump();
          }
          expect(find.byType(ToBeContinued), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'text $scale');
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byKey(const ValueKey('story-line')),
              matching: find.byType(RichText),
            ),
          );
          // The words stay on the plate, clear of its edge.
          final speech = tester.getRect(
            find.byKey(const ValueKey('story-speech')),
          );
          final words = tester.getRect(
            find.byKey(const ValueKey('story-line')),
          );
          expect(speech.contains(words.topLeft), isTrue, reason: 'text $scale');
          expect(
            speech.contains(words.bottomRight),
            isTrue,
            reason: 'text $scale',
          );
          return paragraph.text.style!.fontSize!;
        }

        final normal = await sizeAt(1);
        final large = await sizeAt(1.3);
        final huge = await sizeAt(2);
        expect(large, greaterThanOrEqualTo(normal));
        expect(huge, large);
        // A wide screen has the room to grow it; a narrow one never shrinks it.
        if (size.width >= 800) expect(large, greaterThan(normal));
      });
    }
  });

  group('the locked guardian', () {
    test('the plaque keeps 4.5:1 for every line, locked or not', () {
      const ink = SkyColors.ink;
      // Locked: cream on slate.
      expect(
        GuardianPlaqueLook.contrast(
          SkyColors.cream,
          GuardianPlaqueLook.lockedFill,
        ),
        greaterThanOrEqualTo(4.5),
      );
      // Unlocked: the GUARDIAN line in its accent, the name in cream, on ink.
      for (final boss in [BossKind.kingCoo, BossKind.searchlightGargoyle]) {
        expect(
          GuardianPlaqueLook.contrast(GuardianPlaqueLook.accent(boss), ink),
          greaterThanOrEqualTo(4.5),
          reason: boss.name,
        );
        expect(
          GuardianPlaqueLook.contrast(SkyColors.cream, ink),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        GuardianPlaqueLook.contrast(
          const Color(0xffffffff),
          const Color(0xff000000),
        ),
        closeTo(21, .01),
      );
    });

    test(
      'the Gargoyle\'s field is indigo and every boss field is distinct',
      () {
        expect(
          CampaignHeadwear.field(BossKind.searchlightGargoyle),
          const Color(0xff2f3a6b),
        );
        final fields = [
          for (final boss in BossKind.values) CampaignHeadwear.field(boss),
        ];
        expect(fields.toSet().length, fields.length);
      },
    );

    /// Paints [painter] and counts the pixels of [color] in [region].
    Future<int> count(
      WidgetTester tester,
      CustomPainter painter,
      Size size,
      Color color,
      Rect region,
    ) async {
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), size);
      late ui.Image image;
      late ByteData bytes;
      await tester.runAsync(() async {
        image = await recorder.endRecording().toImage(
          size.width.round(),
          size.height.round(),
        );
        bytes = (await image.toByteData())!;
      });
      var n = 0;
      for (var y = region.top.floor(); y < region.bottom.ceil(); y++) {
        for (var x = region.left.floor(); x < region.right.ceil(); x++) {
          final i = (y * image.width + x) * 4;
          if (bytes.getUint8(i) == (color.r * 255).round() &&
              bytes.getUint8(i + 1) == (color.g * 255).round() &&
              bytes.getUint8(i + 2) == (color.b * 255).round() &&
              bytes.getUint8(i + 3) > 250) {
            n++;
          }
        }
      }
      image.dispose();
      return n;
    }

    testWidgets('a locked shield wears the padlock coin on its corner; an open '
        'one does not', (tester) async {
      const size = Size(66, 74);
      const corner = Rect.fromLTRB(36, 2, 66, 30);
      Future<int> yellow(MapNodeLook look, BossKind boss) => count(
        tester,
        MapGuardianPainter(look: look, radius: 29, boss: boss),
        size,
        SkyColors.yellow,
        corner,
      );
      for (final boss in [BossKind.kingCoo, BossKind.searchlightGargoyle]) {
        expect(await yellow(MapNodeLook.locked, boss), greaterThan(20));
        expect(await yellow(MapNodeLook.open, boss), 0, reason: boss.name);
        expect(await yellow(MapNodeLook.cleared, boss), 0);
      }
    });

    testWidgets('on the map the locked plaque is slate with cream lettering '
        'and the padlock is there', (tester) async {
      await _map(tester, _sizes[1], nyStops(stars: const {'3-1': 3}));
      final plaque = tester.widget<Container>(
        find.byKey(const ValueKey('campaign-guardian-Searchlight Gargoyle')),
      );
      expect(
        (plaque.decoration! as BoxDecoration).color,
        GuardianPlaqueLook.lockedFill,
      );
      final eyebrow = tester.widget<Text>(
        find.descendant(
          of: find.byKey(
            const ValueKey('campaign-guardian-Searchlight Gargoyle'),
          ),
          matching: find.text('GUARDIAN'),
        ),
      );
      expect(eyebrow.style!.color, SkyColors.cream);
      expect(eyebrow.style!.fontSize, greaterThanOrEqualTo(11));
      // The next level's plaque is ink with its accent.
      final open = tester.widget<Container>(
        find.byKey(const ValueKey('campaign-guardian-King Coo')),
      );
      expect((open.decoration! as BoxDecoration).color, SkyColors.ink);
    });

    testWidgets('a narrow stop sets the long name short on its plaque', (
      tester,
    ) async {
      const narrow = Size(480, 270);
      await _map(tester, narrow, nyStops(stars: const {'3-1': 3, '3-2': 2}));
      expect(find.text('Gargoyle'), findsOneWidget);
      expect(find.text('Searchlight Gargoyle'), findsNothing);
      expect(find.text('King Coo'), findsOneWidget);
      // Nothing covers the 3-3 coin.
      final plaque = tester.getRect(
        find.byKey(const ValueKey('campaign-guardian-Searchlight Gargoyle')),
      );
      final coin = tester.getRect(
        find.byKey(const ValueKey('campaign-node-3-3')),
      );
      expect(plaque.overlaps(coin.deflate(8)), isFalse);
      // A phone of the game's own size keeps the whole name.
      await _map(tester, _sizes[0], nyStops(stars: const {'3-1': 3, '3-2': 2}));
      expect(find.text('Searchlight Gargoyle'), findsOneWidget);
    });
  });

  group('what a screen reader hears', () {
    testWidgets('a locked level says what unlocks it', (tester) async {
      final handle = tester.ensureSemantics();
      final stops = [
        CampaignMapStop(
          region: nyStops().first.region,
          chapter: 3,
          route: 'The Lamplight Line',
          nodes: const [
            CampaignMapNode(
              id: '3-1',
              name: 'Moth Light',
              state: CampaignNodeState.cleared,
              stars: 3,
            ),
            CampaignMapNode(
              id: '3-2',
              name: 'Wheels in the Rain',
              state: CampaignNodeState.open,
              boss: BossKind.kingCoo,
              guardian: true,
            ),
            CampaignMapNode(
              id: '3-3',
              name: 'Steam Alley',
              lockNote: 'Beat King Coo to unlock',
            ),
            CampaignMapNode(
              id: '3-4',
              name: 'Storm Warning',
              boss: BossKind.searchlightGargoyle,
              guardian: true,
              lockNote: 'Finish 3-3 to unlock',
            ),
          ],
        ),
      ];
      await _map(tester, _sizes[1], stops);
      expect(
        find.bySemanticsLabel(
          'Level 3-3, Steam Alley. Locked. Beat King Coo to unlock.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Level 3-4, Storm Warning, guardian Searchlight Gargoyle. Locked. '
          'Finish 3-3 to unlock.',
        ),
        findsOneWidget,
      );
      // A node with no note (a stop not in this build) says only Locked.
      await _map(tester, _sizes[1], nyStops(open: false));
      expect(
        find.bySemanticsLabel('Level 3-3, Steam Alley. Locked.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    test('the catalog\'s stops carry the lock note for levels in the build', () {
      Campaign.openedForTest = true;
      final stops = campaignStops(
        CampaignProgress([
          for (final level in Campaign.levels.where((l) => l.chapter <= 2))
            LevelRecord(levelId: level.id, bestStars: 1),
        ]),
      );
      final nodes = {
        for (final stop in stops)
          for (final node in stop.nodes) node.id: node,
      };
      // New York: 3-1 is next, so 3-2 waits on it; 3-3 on King Coo's level.
      expect(nodes['3-1']!.lockNote, isNull);
      expect(nodes['3-2']!.lockNote, 'Finish 3-1 to unlock');
      expect(
        nodes['3-3']!.lockNote,
        Campaign.level('3-2')!.isBoss
            ? 'Beat ${CampaignHeadwear.name(Campaign.level('3-2')!.boss!)} to unlock'
            : 'Finish 3-2 to unlock',
      );
      // Paris is not in the build: its Coming soon ribbon says so, and a note
      // would say "Finish 3-4".
      for (final id in ['3-5', '3-6', '3-7', '3-8']) {
        expect(nodes[id]!.lockNote, isNull, reason: id);
      }
      // Chapters 4 and 5 are not in the build either.
      expect(nodes['4-1']!.lockNote, isNull);
      // Beaten and open levels have none.
      expect(nodes['1-1']!.lockNote, isNull);
      expect(nodes['2-9']!.lockNote, isNull);
    });

    test('a closed build gives chapter 1 and 2 notes and chapter 3 none', () {
      Campaign.closedForTest = true;
      final stops = campaignStops(CampaignProgress(const []));
      final nodes = {
        for (final stop in stops)
          for (final node in stop.nodes) node.id: node,
      };
      expect(nodes['1-1']!.lockNote, isNull);
      expect(nodes['1-2']!.lockNote, 'Finish 1-1 to unlock');
      expect(nodes['1-8']!.lockNote, 'Finish 1-7 to unlock');
      expect(nodes['2-1']!.lockNote, 'Beat Baron Bat to unlock');
      for (final id in ['3-1', '3-2', '3-3', '3-4', '3-8']) {
        expect(nodes[id]!.lockNote, isNull, reason: id);
      }
    });
  });
}
