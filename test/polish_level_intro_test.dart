// Polish checks and captures for the level intro card. The checks always
// run: every level's cargo shows on its tag and fits, and the story key shows
// only on a card with a story and keeps clear of everything else, at the
// three phone sizes. The captures are the real app's card over the map at
// those sizes, and a gallery of cards drawn on their own (every look, long
// names, each boss, a one-star best, the shortest and longest cargo, with
// and without the story key) with zoomed 2.5x renders.
//
// Run with `--dart-define=CAPTURE_POLISH=true` to write PNGs to
// build/visual-review/campaign/polish/level-intro/.
@Timeout(Duration(minutes: 8))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/providers.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_progress.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/main.dart';
import 'package:push_up_bird/ui/campaign_region_still.dart';
import 'package:push_up_bird/ui/components.dart';
import 'package:push_up_bird/ui/level_intro.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'campaign_save_test.dart' show levelRun;
import 'play_session_test.dart' show SilentAudio;
import 'bird_unlocks.dart';

const _capture = bool.fromEnvironment('CAPTURE_POLISH');
const _folder = 'build/visual-review/campaign/polish/level-intro';

CampaignLevel _level(String id) => Campaign.level(id)!;

/// A save where each level in [stars] was finished with that many stars, and
/// each level in [failed] was flown and lost.
Future<void> _seed(
  ProgressRepository repo,
  Map<String, int> stars,
  Set<String> failed,
) async {
  var n = 0;
  for (final MapEntry(key: id, value: rating) in stars.entries) {
    final marks = _level(id).marks;
    await repo.saveRun(
      levelRun(
        'seed-${n++}',
        id,
        stars: switch (rating) {
          3 => marks.three,
          2 => marks.two,
          _ => marks.two - 5,
        },
        score: 400 + n * 30,
        at: DateTime(2026, 9, 20, 12, n),
      ),
    );
  }
  // The first chapter's postcard has been shown, so the map is clear.
  if (stars.containsKey('1-8')) {
    await repo.markPostcardSeen(Campaign.chapters[0]);
  }
  for (final id in failed) {
    await repo.saveRun(
      levelRun(
        'lost-${n++}',
        id,
        stars: 9,
        reason: EndReason.collision,
        at: DateTime(2026, 9, 20, 13, n),
      ),
    );
  }
}

const _chapterOne = {
  '1-1': 3,
  '1-2': 2,
  '1-3': 3,
  '1-4': 1,
  '1-5': 2,
  '1-6': 3,
  '1-7': 2,
};

Future<void> _settle(WidgetTester tester, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester tester, String name, {double ratio = 1}) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// The whole app at [size], over an in-memory save.
Future<void> _open(
  WidgetTester tester,
  Size size, {
  Map<String, int> stars = const {},
  Set<String> failed = const {},
  int bird = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = SqliteProgressRepository(
    ProgressDatabase(NativeDatabase.memory()),
  );
  final folder = Directory.systemTemp.createTempSync('polish-intro');
  await tester.runAsync(() async {
    await repo.setSetting(SettingKey.reducedMotion, true);
    await unlockBirds(repo);
    await repo.equipBird(bird);
    await _seed(repo, stars, failed);
    // The story has been watched, so no scene plays over the card.
    for (final scene in CampaignStory.scenes) {
      await repo.markStoryWatched(scene);
    }
  });
  final container = ProviderContainer(
    overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(folder)),
      audioFactoryProvider.overrideWithValue(() => SilentAudio()),
      trackingSourceFactoryProvider.overrideWithValue(
        () => throw StateError('Tap & Fly never opens the camera'),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(repo.close);
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });
  await tester.runAsync(() => container.read(progressProvider.future));
  appRouter.go('/campaign');
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
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in [...birdAssets, 'island']) {
      await precacheImage(AssetImage('assets/images/$asset.png'), context);
    }
  });
  await _settle(tester);
}

/// The card on its own over its region, dimmed like the map's barrier, laid
/// out as the map lays it out. With [story] it has its story key. A null
/// [name] takes no picture.
Future<void> _alone(
  WidgetTester tester,
  String? name,
  CampaignLevel level,
  LevelRecord record, {
  Size size = const Size(800, 360),
  double ratio = 1,
  bool story = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final grow = (size.height / 360).clamp(1.0, 1.2);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: skyTheme(),
      home: RepaintBoundary(
        key: const ValueKey('visual-capture'),
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              CampaignRegionView(region: level.region),
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
                      record: record,
                      onFly: () {},
                      onClose: () {},
                      onStory: story ? () {} : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump(const Duration(milliseconds: 100));
  if (name != null) await _shot(tester, name, ratio: ratio);
  expect(tester.takeException(), isNull);
}

const _sizes = [Size(640, 360), Size(800, 360), Size(1000, 450)];

final _cargo = find.byKey(const ValueKey('level-intro-cargo'));
final _tag = find.byKey(const ValueKey('level-intro-tag'));
final _storyKey = find.byKey(const ValueKey('level-intro-story'));
final _closeKey = find.byKey(const ValueKey('level-intro-close'));

/// Every piece of lettering on the card, with where it is drawn.
Iterable<(String, Rect)> _lettering(WidgetTester tester) sync* {
  final texts = find.descendant(
    of: find.byType(LevelIntroCard),
    matching: find.byType(Text),
  );
  for (final element in texts.evaluate()) {
    final text = element.widget as Text;
    yield (text.data ?? '', tester.getRect(find.byWidget(text)));
  }
}

LevelRecord _record(
  String id, {
  int stars = 0,
  int collected = 0,
  int plays = 0,
}) => LevelRecord(
  levelId: id,
  bestStars: stars,
  bestCollected: collected,
  plays: plays,
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

  group('delivery', () {
    for (final size in _sizes) {
      final w = size.width.round();

      testWidgets('every level\'s cargo is on its tag and fits at $w', (
        tester,
      ) async {
        for (final chapter in Campaign.chapters) {
          for (final level in chapter.levels) {
            await _alone(tester, null, level, _record(level.id), size: size);
            final cargo = level.delivery.cargo;
            final reason = '${level.id} at $w';
            expect(find.text(cargo), findsOneWidget, reason: reason);
            expect(tester.widget<Text>(_cargo).data, cargo, reason: reason);
            expect(
              find.bySemanticsLabel('Special delivery: $cargo.'),
              findsOneWidget,
              reason: reason,
            );
            // All of it is written out, inside the tag.
            final written = tester.renderObject<RenderParagraph>(
              find.descendant(of: _cargo, matching: find.byType(RichText)),
            );
            expect(written.didExceedMaxLines, isFalse, reason: reason);
            final tag = tester.getRect(_tag);
            final words = tester.getRect(_cargo);
            expect(
              tag.deflate(2).contains(words.topLeft) &&
                  tag.deflate(2).contains(words.bottomRight),
              isTrue,
              reason: '$reason: $words in $tag',
            );
            // The tag stays on the card, over the top of the picture, clear
            // of the region's name and of the details beside it.
            final card = tester.getRect(find.byType(LevelIntroCard));
            expect(
              card.contains(tag.topLeft) && card.contains(tag.bottomRight),
              isTrue,
              reason: reason,
            );
            final picture = tester.getRect(
              find.descendant(
                of: find.byType(LevelIntroCard),
                matching: find.byType(CampaignRegionView),
              ),
            );
            expect(tag.right, lessThanOrEqualTo(picture.right), reason: reason);
            for (final (text, rect) in _lettering(tester)) {
              if (text == cargo || text == 'SPECIAL DELIVERY') continue;
              expect(
                rect.overlaps(tag),
                isFalse,
                reason: '$reason: "$text" under the tag',
              );
            }
            // A card without a story has no story key.
            expect(_storyKey, findsNothing, reason: reason);
          }
        }
      });

      testWidgets('the story key shows on a card with a story, clear of the '
          'close key and the details, at $w', (tester) async {
        for (final chapter in Campaign.chapters) {
          for (final level in chapter.levels) {
            if (CampaignStory.before(level) == null) continue;
            await _alone(
              tester,
              null,
              level,
              _record(level.id),
              size: size,
              story: true,
            );
            final reason = '${level.id} at $w';
            expect(_storyKey, findsOneWidget, reason: reason);
            expect(find.byTooltip('Story'), findsOneWidget, reason: reason);
            // A screen reader hears it as a key named Story, as it hears
            // Close.
            expect(
              tester.getSemantics(_storyKey),
              isSemantics(tooltip: 'Story', isButton: true, hasTapAction: true),
              reason: reason,
            );
            final key = tester.getRect(_storyKey);
            // A 48 dp touch target at every phone size.
            expect(key.width, greaterThanOrEqualTo(48), reason: reason);
            expect(key.height, greaterThanOrEqualTo(48), reason: reason);
            final close = tester.getRect(_closeKey);
            expect(key.overlaps(close), isFalse, reason: reason);
            expect(key.top, greaterThanOrEqualTo(close.bottom), reason: reason);
            expect(key.center.dx, closeTo(close.center.dx, .5), reason: reason);
            final card = tester.getRect(find.byType(LevelIntroCard));
            expect(key.right, lessThanOrEqualTo(card.right), reason: reason);
            // Nothing is written under it: not the name, the length, the
            // hint or controls, or a goal.
            for (final (text, rect) in _lettering(tester)) {
              expect(
                rect.overlaps(key),
                isFalse,
                reason: '$reason: "$text" under the story key',
              );
            }
            // The hint's note and the boss's band both stop short of it. A
            // chapter boss has the BOSS FIGHT band; a guardian (3-2 and 3-4
            // since the New York level data) the GUARDIAN ribbon instead.
            for (final box in [
              if (level.hint != null)
                find
                    .ancestor(
                      of: find.text(level.hint!),
                      matching: find.byType(Container),
                    )
                    .first,
              if (level.isChapterBoss)
                find
                    .ancestor(
                      of: find.text('BOSS FIGHT'),
                      matching: find.byType(Container),
                    )
                    .last,
              if (level.isGuardian)
                find.byKey(const ValueKey('level-intro-guardian')),
            ]) {
              expect(
                tester.getRect(box).overlaps(key),
                isFalse,
                reason: '$reason: ${tester.getRect(box)} under $key',
              );
            }
            // The hint still reads in full. One of two lines stops short of
            // the key; one of a single line keeps the goals' width under it.
            if (level.hint != null) {
              final hint = tester.renderObject<RenderParagraph>(
                find.descendant(
                  of: find.text(level.hint!),
                  matching: find.byType(RichText),
                ),
              );
              expect(hint.didExceedMaxLines, isFalse, reason: reason);
              final note = tester.getRect(
                find
                    .ancestor(
                      of: find.text(level.hint!),
                      matching: find.byType(Container),
                    )
                    .first,
              );
              final goal = tester.getRect(
                find
                    .ancestor(
                      of: find.text(LevelIntroCard.goals(level).first),
                      matching: find.byType(Container),
                    )
                    .first,
              );
              // In the card's own units a line of the hint is 17.4 high.
              if (hint.size.height > 26) {
                expect(note.right, lessThan(key.left), reason: reason);
              } else {
                expect(note.right, closeTo(goal.right, .01), reason: reason);
              }
            }
          }
        }
      });
    }

    testWidgets('the story key replays the story', (tester) async {
      var told = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: skyTheme(),
          home: Scaffold(
            body: Center(
              child: LevelIntroCard(
                level: _level('1-1'),
                record: _record('1-1'),
                onFly: () {},
                onClose: () {},
                onStory: () => told++,
              ),
            ),
          ),
        ),
      );
      await tester.tap(_storyKey);
      expect(told, 1);
    });
  });

  group('capture', skip: !_capture, () {
    for (final size in _sizes) {
      final w = size.width.round();
      testWidgets('in the app at $w', (tester) async {
        // Chapter 1 done, chapter 2 under way, a lost flight on 2-3.
        await _open(
          tester,
          size,
          stars: {..._chapterOne, '1-8': 2, '2-1': 3, '2-2': 1},
          failed: const {'2-3'},
        );
        for (final (id, name) in [
          ('1-4', 'cleared'),
          ('1-2', 'two-line-hint'),
          ('1-8', 'boss-beaten'),
          ('2-2', 'cleared-hint'),
          ('2-3', 'not-delivered'),
        ]) {
          appRouter.go('/campaign?level=$id');
          await _settle(tester, 4);
          await _shot(tester, 'app-$name-$id-$w');
        }
        await tester.pumpWidget(const SizedBox());

        // An unbeaten boss.
        await _open(tester, size, stars: {..._chapterOne}, bird: 1);
        appRouter.go('/campaign?level=1-8');
        await _settle(tester, 4);
        await _shot(tester, 'app-boss-new-1-8-$w');
        await tester.pumpWidget(const SizedBox());

        // First flights: a level with a hint, and one with the controls line.
        await _open(
          tester,
          size,
          stars: {..._chapterOne, '1-8': 2, '2-1': 3, '2-2': 2},
          bird: 3,
        );
        appRouter.go('/campaign?level=2-3');
        await _settle(tester, 4);
        await _shot(tester, 'app-first-flight-2-3-$w');
        await tester.pumpWidget(const SizedBox());
        await _open(
          tester,
          size,
          stars: const {'1-1': 3, '1-2': 3, '1-3': 3},
          bird: 2,
        );
        appRouter.go('/campaign?level=1-4');
        await _settle(tester, 4);
        await _shot(tester, 'app-controls-1-4-$w');
      });
    }

    testWidgets('gallery', (tester) async {
      // Extremes: the longest names, a tip rather than NEW, each boss, and
      // each amount earned.
      await _alone(
        tester,
        'gallery-long-name',
        _level('3-2'),
        _record('3-2', stars: 2, collected: 60, plays: 2),
      );
      await _alone(
        tester,
        'gallery-tip',
        _level('5-1'),
        _record('5-1'),
        size: const Size(640, 360),
      );
      for (final id in ['1-8', '2-8', '3-8', '4-8', '5-8']) {
        final level = _level(id);
        await _alone(
          tester,
          'gallery-boss-$id',
          level,
          _record(id, stars: id == '3-8' ? 3 : 0, collected: 30, plays: 1),
          size: const Size(640, 360),
        );
      }
      for (final stars in [0, 1, 2, 3]) {
        await _alone(
          tester,
          'gallery-earned-$stars',
          _level('2-4'),
          _record('2-4', stars: stars, collected: stars * 30, plays: 1),
          size: const Size(640, 360),
        );
      }
      // A zoomed look at the card's details.
      await _alone(
        tester,
        'zoom-new',
        _level('1-3'),
        _record('1-3', stars: 2, collected: 47, plays: 2),
        size: const Size(640, 360),
        ratio: 2.5,
      );
      await _alone(
        tester,
        'zoom-boss',
        _level('1-8'),
        _record('1-8'),
        size: const Size(640, 360),
        ratio: 2.5,
      );
    });

    testWidgets('delivery', (tester) async {
      // The shortest and the longest cargo, the widest lines, and the tags
      // of a boss and of a level in each kind of light, at each size.
      for (final size in _sizes) {
        final w = size.width.round();
        for (final (name, id) in [
          ('short', '1-7'),
          ('long', '3-3'),
          ('wide', '2-4'),
          ('boss-short', '1-8'),
          ('boss-long', '2-8'),
          ('night', '5-3'),
        ]) {
          await _alone(
            tester,
            'cargo-$name-$id-$w',
            _level(id),
            _record(id, stars: id == '3-3' ? 2 : 0, collected: 50, plays: 1),
            size: size,
          );
        }
        // The story key beside a one-line hint, a two-line hint, the
        // controls and a boss's band.
        for (final id in ['1-1', '2-1', '1-4', '5-1', '4-8']) {
          await _alone(
            tester,
            'story-$id-$w',
            _level(id),
            _record(id),
            size: size,
            story: true,
          );
        }
      }
      // The same card without its key, to compare.
      await _alone(
        tester,
        'story-none-2-1-640',
        _level('2-1'),
        _record('2-1'),
        size: const Size(640, 360),
      );
      for (final (name, id, story) in [
        ('zoom-tag', '1-1', true),
        ('zoom-tag-long', '3-3', false),
        ('zoom-tag-boss', '2-8', true),
      ]) {
        await _alone(
          tester,
          name,
          _level(id),
          _record(id),
          size: const Size(640, 360),
          ratio: 2.5,
          story: story,
        );
      }
    });
  });
}
