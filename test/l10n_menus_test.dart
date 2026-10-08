import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart'
    show birdDescriptions, birdNames;
import 'package:push_up_bird/domain/daily_adventure.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/replay_highlights.dart';
import 'package:push_up_bird/domain/sky_passport.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_trail.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/text/birds_text.dart';
import 'package:push_up_bird/l10n/text/daily_text.dart';
import 'package:push_up_bird/l10n/text/date_text.dart';
import 'package:push_up_bird/l10n/text/passport_text.dart';
import 'package:push_up_bird/l10n/text/replay_text.dart';
import 'package:push_up_bird/l10n/text/upgrades_text.dart';
import 'package:push_up_bird/ui/replay_screen.dart'
    show sessionDetail, sessionTitle;

/// Slice S6's words (menus, birds, upgrades, passport, daily Adventure,
/// records and replays): the English ARB equals the domain's English twins,
/// the passport's stamp and medal names equal the Play achievement names,
/// and dates and numbers follow each language while digits stay Western.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  tearDown(L10n.debugReset);

  // Before any language's date data is loaded (a bare MaterialApp test),
  // every language shows the English forms instead of throwing.
  test('dates fall back to English until intl has the language', () {
    final de = lookupAppLocalizations(const Locale('de'));
    expect(de.dayMonthCaps(DateTime(2026, 10, 7)), '7 OCT');
    expect(de.dayMonthDigits(DateTime(2026, 10, 7)), '7/10');
  });

  group('English ARB equals the twins', () {
    test('passport stamps, medals and goals', () {
      for (final stamp in SkyStamp.values) {
        expect(en.stampName(stamp), stamp.title, reason: stamp.name);
        for (final medal in StampMedal.values) {
          expect(en.medalName(medal), medal.label);
          expect(
            en.stampGoal(stamp, medal),
            stamp.goal(medal),
            reason: '${stamp.name} ${medal.name}',
          );
        }
        for (final count in [0, 1, 3, 120, 1200, 5000, 9999]) {
          final progress = StampProgress(stamp, count);
          expect(en.stampProgressGoal(progress), progress.goal);
          expect(en.stampMedalTitle(progress), progress.medalTitle);
          expect(en.stampNextTitle(progress), progress.nextTitle);
          expect(en.stampTally(progress), progress.tally);
        }
      }
    });

    test('daily goals and postcard titles', () {
      for (final task in DailyTask.values) {
        for (final target in [1, 2, 3, 8, 9, 18, 25]) {
          final goal = DailyGoal(task, target, 0);
          expect(en.dailyTaskTitle(task), goal.title);
          expect(en.dailyGoalText(goal), goal.description, reason: '$task');
        }
      }
      final themes = <int>{};
      for (var day = 0; day < 6; day++) {
        final adventure = DailyAdventure.forDate(
          DateTime(2026, 10, 1 + day),
          const [],
        );
        themes.add(adventure.theme);
        expect(en.dailyThemeTitle(adventure.theme), adventure.title);
      }
      expect(themes, hasLength(6));
    });

    test('upgrades: names, blurbs and every level\'s stats', () {
      for (final power in PowerUp.values) {
        expect(en.powerUpName(power), power.title);
        expect(en.powerUpBlurb(power), power.blurb);
        for (var level = 0; level <= PowerUp.maxLevel; level++) {
          expect(
            en.powerStats(power, level),
            power.stats(level),
            reason: '${power.name} $level',
          );
        }
      }
    });

    test('birds: taglines and trails', () {
      for (var bird = 0; bird < birdNames.length; bird++) {
        expect(en.birdDescription(bird), birdDescriptions[bird]);
        expect(en.birdTrailName(bird), BirdTrail.names[bird]);
      }
      expect(
        [for (var b = 0; b < 4; b++) birdGender(b)],
        ['male', 'female', 'male', 'female'],
      );
    });

    test('every flight highlight, in every variant', () {
      var checked = 0;
      for (final kind in ReplayMomentKind.values) {
        for (final value in [2, 3, 5, 10, 40]) {
          for (final rush in [null, ...RushPathKind.values]) {
            for (final end in [null, ...EndReason.values]) {
              for (final flawless in [false, true]) {
                for (final subtle in [false, true]) {
                  final moment = ReplayHighlight(
                    kind: kind,
                    atMs: 0,
                    priority: 0,
                    value: value,
                    rush: rush,
                    endReason: end,
                    flawless: flawless,
                    subtleStars: subtle,
                  );
                  expect(en.momentTitle(moment), moment.title);
                  expect(en.momentDetail(moment), moment.detail);
                  checked++;
                }
              }
            }
          }
        }
      }
      expect(checked, greaterThan(1000));
    });

    test('saved sessions are named and described as before', () {
      RunResult run(
        String id, {
        FlightCourse course = FlightCourse.starTrail,
        bool practice = false,
        String? levelId,
        String? levelName,
      }) => RunResult(
        id: id,
        mode: PlayMode.touch,
        practice: practice,
        score: 40,
        repetitions: 0,
        flaps: 12,
        durationSeconds: 29.6,
        reason: EndReason.collision,
        finishedAt: DateTime(2026, 10, 1, 18, 5),
        course: course,
        levelId: levelId,
        levelName: levelName,
      );
      expect(sessionTitle(run('a')), 'Tap & Fly · Endless');
      expect(
        sessionTitle(run('b', practice: true)),
        'Tap & Fly · Endless · Practice',
      );
      expect(sessionTitle(run('c', course: FlightCourse.classic)), 'Tap & Fly');
      expect(
        sessionTitle(run('d', course: FlightCourse.classic, practice: true)),
        'Tap & Fly · Practice',
      );
      expect(sessionTitle(run('e', levelId: '9-9')), 'Level 9-9');
      expect(
        sessionTitle(run('f', levelId: 'built-1', levelName: 'My loop')),
        'My loop · Tap & Fly',
      );
      for (final mode in CoopMode.values) {
        expect(en.flyTogetherName(mode), 'Fly Together · ${mode.title}');
      }
      expect(
        sessionDetail(run('g'), en),
        '2026-10-01 18:05 · 30 sec · 40 star points',
      );
      expect(
        sessionDetail(run('h', course: FlightCourse.classic), en),
        '2026-10-01 18:05 · 30 sec · 40 gates',
      );
    });

    test('dates keep their English forms', () {
      final day = DateTime(2026, 10, 7, 18, 30);
      expect(en.dayMonthCaps(day), '7 OCT');
      expect(en.dayMonthDigits(day), '7/10');
      expect(en.dateDigits(day), '2026-10-07');
      expect(en.dateTimeDigits(day), '2026-10-07 18:30');
      // 2026-10-05 is a Monday.
      expect(
        [
          for (var d = 0; d < 7; d++)
            en.weekdayLetter(DateTime(2026, 10, 5 + d)),
        ],
        ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      );
    });
  });

  group('Play achievements', () {
    final store = Directory('l10n/store');

    Map<String, dynamic> load(File file) =>
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    /// The 24 stamp achievements of [file]: "Frequent Flyer · Bronze" and
    /// its goal, keyed by PlayAchievement name.
    void expectStampsMatch(File file, AppLocalizations l) {
      final achievements = load(file)['achievements'] as Map<String, dynamic>;
      for (final stamp in SkyStamp.values) {
        for (final medal in StampMedal.values) {
          final id =
              '${stamp.name}${medal.name[0].toUpperCase()}'
              '${medal.name.substring(1)}';
          final entry = achievements[id] as Map<String, dynamic>?;
          expect(entry, isNotNull, reason: '${file.path}: $id');
          final name = (entry!['name'] as Map)['text'] as String;
          final description = (entry['description'] as Map)['text'] as String;
          // Play Console names are Title Case in English; the passport's are
          // sentence case. The words must be the same.
          expect(
            name.toLowerCase(),
            l
                .passportNextTitle(l.stampName(stamp), l.medalName(medal))
                .toLowerCase(),
            reason: '${file.path}: $id name',
          );
          expect(
            description,
            l.stampGoal(stamp, medal),
            reason: '${file.path}: $id description',
          );
        }
      }
    }

    test('English names and descriptions are the passport\'s', () {
      expectStampsMatch(File('${store.path}/en.json'), en);
    });

    test('every translated store file matches that language\'s ARB', () {
      for (final file in store.listSync().whereType<File>()) {
        final slug = file.uri.pathSegments.last.replaceAll('.json', '');
        if (slug == 'en') continue;
        final language = AppLanguage.fromTag(slug);
        expect(language, isNotNull, reason: file.path);
        expectStampsMatch(file, lookupAppLocalizations(language!.locale));
      }
    });
  });

  group('each language\'s dates and numbers', () {
    setUpAll(() async {
      // As the app does: Material's localizations load intl's date data.
      for (final language in AppLanguage.values) {
        await GlobalMaterialLocalizations.delegate.load(language.locale);
      }
    });

    final easternDigits = RegExp(r'[٠-٩۰-۹]');

    test('dates read in the language, digits stay Western', () {
      final day = DateTime(2026, 10, 7, 18, 30);
      String caps(AppLanguage language) =>
          lookupAppLocalizations(language.locale).dayMonthCaps(day);
      expect(caps(AppLanguage.en), '7 OCT');
      expect(caps(AppLanguage.de), '7. OKT.');
      expect(caps(AppLanguage.ja), '10月7日');
      expect(caps(AppLanguage.zhHant), '10月7日');
      expect(
        lookupAppLocalizations(AppLanguage.ja.locale).weekdayLetter(day),
        '水',
      );
      for (final language in AppLanguage.values) {
        final l = lookupAppLocalizations(language.locale);
        for (final text in [
          l.dayMonthCaps(day),
          l.dayMonthDigits(day),
          l.dateDigits(day),
          l.dateTimeDigits(day),
          l.weekdayLetter(day),
        ]) {
          expect(text, isNotEmpty, reason: language.tag);
          expect(
            easternDigits.hasMatch(text),
            isFalse,
            reason: '$language $text',
          );
        }
        expect(l.dayMonthDigits(day), contains('7'), reason: language.tag);
      }
    });

    test('upgrade stats take the language\'s decimals', () {
      final de = lookupAppLocalizations(AppLanguage.de.locale);
      expect(de.powerStatValue(PowerStat.burstLength, .95), '0,95 s');
      expect(de.powerStatValue(PowerStat.reach, 2.588), '2,6×');
      expect(de.powerStatValue(PowerStat.maxCharge, 85), '85\u00a0%');
      expect(en.powerStatValue(PowerStat.burstLength, .95), '0.95 s');
      for (final language in AppLanguage.values) {
        final l = lookupAppLocalizations(language.locale);
        for (final power in PowerUp.values) {
          for (final (_, value) in l.powerStats(power, 4)) {
            expect(easternDigits.hasMatch(value), isFalse, reason: '$language');
          }
        }
        expect(easternDigits.hasMatch(l.formatCount(12345)), isFalse);
      }
    });
  });
}
