// What a result says when a level ends: the word over the courier and the
// news strip for the stop's end. The whole stage is exercised through the
// app in `ny_ui_flow_test.dart`; these are the decisions it makes, on levels
// built here and on the catalog's, with New York open and closed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/ui/level_result.dart';

import 'ny_ui_support.dart';

void main() {
  // New York is open in the build as it ships; tests force a state with the
  // hooks, so they pass under either `NEW_YORK_OPEN` define.
  tearDown(() {
    Campaign.openedForTest = false;
    Campaign.closedForTest = false;
  });

  CampaignLevel level(String id) => Campaign.level(id)!;

  group('the word over the courier', () {
    test('a guardian is down, a chapter boss is a victory', () {
      expect(
        LevelResultStage.wordFor(nyWheels, complete: true),
        'Guardian down!',
      );
      expect(
        LevelResultStage.wordFor(nyStorm, complete: true),
        'Guardian down!',
      );
      for (final id in ['1-8', '2-8', '3-8', '4-8', '5-8']) {
        expect(
          LevelResultStage.wordFor(level(id), complete: true),
          'Victory!',
          reason: id,
        );
      }
    });

    test('every other finish is a delivery and a miss is a try again', () {
      for (final id in ['1-1', '1-7', '2-3', '3-1', '3-3', '3-7']) {
        expect(
          LevelResultStage.wordFor(level(id), complete: true),
          'Delivered!',
          reason: id,
        );
      }
      for (final l in [nyWheels, nyStorm, level('1-8'), level('1-1')]) {
        expect(
          LevelResultStage.wordFor(l, complete: false),
          'Try again!',
          reason: l.id,
        );
      }
    });
  });

  group('Paris is coming soon', () {
    test('after 3-4 when New York is open, and only then', () {
      Campaign.openedForTest = true;
      expect(
        LevelResultStage.comingSoonNews(level('3-4')),
        'Paris is coming soon!',
      );
      // 3-1 to 3-3 have a next level to fly; it says so itself.
      for (final id in ['3-1', '3-2', '3-3']) {
        expect(LevelResultStage.comingSoonNews(level(id)), isNull, reason: id);
      }
    });

    test('never when New York is closed, and never after another chapter', () {
      // Closed (NEW_YORK_OPEN=false): no level of chapter 3 can be flown, so
      // none has news.
      Campaign.closedForTest = true;
      for (final l in Campaign.levels) {
        expect(LevelResultStage.comingSoonNews(l), isNull, reason: l.id);
      }
      Campaign.closedForTest = false;
      Campaign.openedForTest = true;
      for (final l in Campaign.levels) {
        if (l.id == '3-4') continue;
        expect(LevelResultStage.comingSoonNews(l), isNull, reason: l.id);
      }
    });

    test('the chapter boss\'s stop and the end of the trip stay quiet', () {
      Campaign.openedForTest = true;
      // 2-8 leads into 3-1, which is playable now; 3-8 into chapter 4.
      expect(LevelResultStage.comingSoonNews(level('2-8')), isNull);
      expect(LevelResultStage.comingSoonNews(level('3-8')), isNull);
      expect(LevelResultStage.comingSoonNews(level('5-8')), isNull);
    });
  });
}
