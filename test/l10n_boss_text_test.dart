import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/arrival_art.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/boss_stage_hud_art.dart';
import 'package:push_up_bird/game/boss_vanguard_art.dart';
import 'package:push_up_bird/game/dragon_encounter_ui.dart';
import 'package:push_up_bird/game/finish_gate_art.dart';
import 'package:push_up_bird/game/gargoyle_encounter_ui.dart';
import 'package:push_up_bird/game/gargoyle_hud_art.dart';
import 'package:push_up_bird/game/king_coo_encounter_ui.dart';
import 'package:push_up_bird/game/king_coo_hud_art.dart';
import 'package:push_up_bird/game/king_coo_squad_art.dart';
import 'package:push_up_bird/game/neferhoo_encounter_art.dart';
import 'package:push_up_bird/game/neferhoo_encounter_ui.dart';
import 'package:push_up_bird/game/neferhoo_props_art.dart';
import 'package:push_up_bird/game/neferhoo_staging_art.dart';
import 'package:push_up_bird/game/pirate_encounter_ui.dart';
import 'package:push_up_bird/game/rush_art.dart';
import 'package:push_up_bird/l10n/l10n.dart';
import 'package:push_up_bird/l10n/pseudo.dart';
import 'package:push_up_bird/l10n/text/boss_text.dart';

/// Slice S3 (bosses and the flight's canvas art): the English ARB equals
/// the domain's twins, every boss card, tag and banner paints in the
/// pseudo-locale (+40 %) and in Arabic without leaving its room, the
/// canvases stay left to right under Arabic, and a language switch never
/// leaves stale words in a cache.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, file) in [
      ('Fredoka', 'assets/fonts/Fredoka.ttf'),
      ('Nunito', 'assets/fonts/Nunito.ttf'),
      (LanguageFonts.baloo, 'assets/fonts/l10n/BalooBhaijaan2.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(file))).load();
    }
  });
  tearDown(L10n.debugReset);

  final en = lookupAppLocalizations(AppLanguage.en.locale);

  SkyBoss boss(BossKind kind, {double age = 3, bool upgraded = false}) =>
      SkyBoss(
        number: kind.index + 1,
        x: 1.62,
        kind: kind,
        cinematic: true,
        upgraded: upgraded,
      )..age = age;

  group('English ARB equals the domain twins', () {
    test('names, epithets and bar names', () {
      for (final kind in BossKind.values) {
        final b = boss(kind);
        expect(en.bossTitle(kind), b.title, reason: kind.name);
        expect(en.bossTitleOf(b), b.title, reason: kind.name);
        expect(
          en.bossBarName(kind),
          kind == BossKind.searchlightGargoyle
              ? 'GARGOYLE'
              : b.name.toUpperCase(),
          reason: kind.name,
        );
        expect(
          en.bossDefeated(kind),
          '${b.name.toUpperCase()} DEFEATED',
          reason: kind.name,
        );
        expect(
          en.bossEyebrow(b),
          b.isMiniBoss
              ? 'GUARDIAN'
              : 'ENCOUNTER ${b.number.toString().padLeft(2, '0')}',
        );
        expect(
          en.bossVictoryTitle(b),
          b.isMiniBoss ? 'GUARDIAN DOWN!' : 'SKY RECLAIMED',
        );
      }
      final returning = boss(BossKind.baronBat, upgraded: true);
      expect(en.bossTitleOf(returning), returning.title);
      expect(en.boss_neferhoo_title, Neferhoo.title);
    });

    test('every fight hint, both ways', () {
      final seen = <String>{};
      for (final hint in BossHint.values) {
        expect(en.bossHint(hint), hint.english, reason: hint.name);
        expect(seen.add(hint.english), isTrue, reason: 'twin of ${hint.name}');
        expect(BossHint.of(hint.english), hint);
        expect(en.bossHintText(hint.english), hint.english);
      }
      expect(en.bossHintText('not a hint'), 'not a hint');
      // Neferhoo's hints are his rules' constants.
      for (final english in [
        Neferhoo.mailHint,
        Neferhoo.returnHint,
        Neferhoo.fasterReturnHint,
        Neferhoo.ankhHint,
        Neferhoo.expressHint,
        Neferhoo.twoAnkhsHint,
        Neferhoo.batsHint,
        Neferhoo.tougherStageHint,
        Neferhoo.neferhooScuffHint,
        Neferhoo.warmUpHint,
        Neferhoo.calmHint,
        Neferhoo.furyHint,
      ]) {
        expect(BossHint.of(english), isNotNull, reason: english);
      }
    });

    test('the hint getters say what they said before', () {
      // A few states per getter, spelled out (the words are the contract
      // the play screen's label and the tests read).
      final moth = boss(BossKind.duskMoth, age: 9);
      expect(BossHint.of(moth.shieldHint), isNotNull);
      final pirate = boss(BossKind.pirate, age: 9);
      expect(BossHint.of(pirate.tideHint), isNotNull);
      final dragon = boss(BossKind.dragon, age: 9);
      expect(BossHint.of(dragon.breathHint), isNotNull);
      final coo = boss(BossKind.kingCoo, age: 9);
      expect(BossHint.of(coo.cooHint), isNotNull);
      final gargoyle = boss(BossKind.searchlightGargoyle, age: 9);
      expect(BossHint.of(gargoyle.gargoyleHint), isNotNull);
      final baron = boss(BossKind.baronBat, age: 9, upgraded: true);
      expect(BossHint.of(baron.screechHint), isNotNull);
      expect(
        BossHint.breathWarningMiddle.english,
        "DRAGON'S BREATH · Climb or dive! Its heart is open",
      );
      expect(BossHint.screechHoldLow.english, 'SCREECH · Hold the low gap');
    });

    test('vanguards, rushes and the story lines on the cards', () {
      for (final kind in BossKind.values) {
        expect(en.vanguardTitle(kind), BossVanguard.titleOf(kind));
      }
      expect(
        en.vanguardCall(BossKind.spitterBeetle),
        'Here they come! The Spitter King is right behind.',
      );
      expect(
        en.vanguardCall(BossKind.kingCoo, crusts: true, returns: true),
        'Duck the crusts! Miss one and it comes back!',
      );
      for (final kind in RushPathKind.values) {
        expect(en.rushWarningTitle(kind), '${kind.title.toUpperCase()}!');
        final escape = kind.escape;
        expect(
          en.rushEscapedDetail(kind),
          'You ${escape[0].toLowerCase()}${escape.substring(1)}',
        );
      }
      expect(en.bossQuotedLine('Arr!'), '“Arr!”');
      for (final level in Campaign.levels) {
        final kind = level.boss;
        if (kind == null) continue;
        final line = Campaign.bossLine(level);
        if (line != null) {
          expect(en.bossLineFor(kind, level: level), line, reason: level.id);
        }
      }
      expect(
        GargoyleEncounterUi.line,
        'Hold still! Nobody ever stays in the light.',
      );
      expect(
        KingCooEncounterUi.entranceLine,
        '“Nobody flies till the bread cart is found!”',
      );
      expect(
        NeferhooEncounterUi.line,
        '“Return to sender! This route has a courier.”',
      );
      expect(NeferhooEncounterUi.name, 'NEFERHOO');
      expect(
        GargoyleHudArt.lampWords + GargoyleHudArt.shootWords,
        'LAMP OPEN · SHOOT!',
      );
      expect(KingCooSquadArt.cancelLabel, 'SQUAD CANCELLED');
    });
  });

  group('the canvases in the pseudo-locale and in Arabic', () {
    const size = Size(792, 360);
    final u = BossHealthBarArt.unit(size);

    void pseudo() => L10n.apply(AppLanguage.en, locale: pseudoLocale);

    /// Paints every card, tag and banner of every boss at [size], through the
    /// arrival, the fight and the defeat; nothing may throw.
    void paintAll() {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      for (final kind in BossKind.values) {
        for (final age in [1.0, 2.0, 3.0, 4.0, 4.4]) {
          final b = boss(kind, age: age);
          final m = BossMotion(b, reducedMotion: false);
          BossHealthBarArt.paint(c, size, b);
          switch (kind) {
            case BossKind.kingCoo:
              KingCooEncounterUi.nameCard(c, size, b, m, birdY: .5);
            case BossKind.searchlightGargoyle:
              GargoyleEncounterUi.nameCard(c, size, b, m, birdY: .5);
            case BossKind.neferhoo:
              NeferhooEncounterUi.nameCard(c, size, b, m, birdY: .5);
            case BossKind.dragon:
              DragonEncounterUi.nameCard(c, size, b, m, birdY: .5);
            case BossKind.pirate:
              PirateEncounterUi.nameCard(c, size, b, m, birdY: .5);
            default:
          }
        }
        final fighting = boss(kind, age: 9);
        expect(fighting.phase, BossPhase.attacking);
        BossHealthBarArt.paint(c, size, fighting);
        final beaten = boss(kind, age: 9)
          ..defeatedAt = 8
          ..hp = 0;
        BossHealthBarArt.paint(c, size, beaten);
      }
      NeferhooEncounterUi.paintCard(c, size, line: NeferhooEncounterUi.line);
      NeferhooEncounterUi.paintVictory(c, size);
      // The rush and gale banners, every kind.
      final sim = FlightSimulation(
        rules: TapFlyMode(),
        practice: true,
        random: Random(1),
      )..elapsed = 10;
      for (final kind in RushPathKind.values) {
        sim.events.add(
          FlightEvent(FlightEventKind.rushWarning, 10, .5, value: kind.index),
        );
      }
      sim.events
        ..add(const FlightEvent(FlightEventKind.rushEscaped, 10, .5, value: 20))
        ..add(const FlightEvent(FlightEventKind.galeWarning, 10, .5))
        ..add(
          const FlightEvent(FlightEventKind.galeWeathered, 10, .5, value: 10),
        )
        ..add(const FlightEvent(FlightEventKind.allRings, 10, .5, value: 15));
      RushArt.banner(c, size, sim, reducedMotion: false);
      rec.endRecording().dispose();
    }

    test('everything paints, in the pseudo-locale and in Arabic', () {
      pseudo();
      paintAll();
      L10n.apply(AppLanguage.ar);
      paintAll();
    });

    test('the cards stay where they are under Arabic (left to right)', () {
      final gargoyle = boss(BossKind.searchlightGargoyle);
      final english = GargoyleEncounterUi.cardRect(size, gargoyle);
      final strip = Rect.fromLTWH(200, 7 * u, 400, 22 * u);
      final bar = Rect.fromLTWH(320, 12 * u, 260, 10 * u);
      final puffed = KingCooHudArt.tagBox(strip, bar, u);
      final neferhoo = NeferhooEncounterUi.cardRect(size);
      L10n.apply(AppLanguage.ar);
      expect(L10n.textDirection, TextDirection.rtl);
      // Arabic words have their own widths, but nothing mirrors: each card
      // keeps its top and the side of the screen it sits on, and grows or
      // shrinks from the same anchor.
      void sameSide(Rect arabic, Rect latin, Rect within) {
        expect(arabic.top, closeTo(latin.top, .01));
        expect(
          (arabic.center.dx - within.center.dx).sign,
          (latin.center.dx - within.center.dx).sign,
        );
      }

      final screen = Offset.zero & size;
      final arabicCard = GargoyleEncounterUi.cardRect(size, gargoyle);
      sameSide(arabicCard, english, screen);
      expect(arabicCard.left, closeTo(english.left, .01));
      sameSide(KingCooHudArt.tagBox(strip, bar, u), puffed, strip);
      final arabicPlate = NeferhooEncounterUi.cardRect(size);
      sameSide(arabicPlate, neferhoo, screen);
    });

    test('fixed plates and tags keep long words inside them', () {
      pseudo();
      final l = L10n.strings;
      // King Coo's PUFFED x2 tag never grows past its widest case.
      final strip = Rect.fromLTWH(200, 7 * u, 400, 22 * u);
      final bar = Rect.fromLTWH(320, 12 * u, 260, 10 * u);
      expect(
        KingCooHudArt.tagBox(strip, bar, u).width,
        lessThanOrEqualTo(KingCooHudArt.tagWidthMax * u + .01),
      );
      // Neferhoo's lane and ankh tags stay on their 124 px plaques.
      for (final (title, sub) in [
        (l.bossNeferhooExpressPost, l.bossNeferhooShootBack),
        (l.bossNeferhooTwoAnkhs, l.bossNeferhooComesBack),
      ]) {
        final r = NeferhooPropsArt.tagRect(title, sub, 120, 160, size);
        expect(r.width, lessThanOrEqualTo(124 * size.height / 360 + .01));
      }
      // His hint pill (the longest line) fits between the hearts plate and
      // the pause key.
      final room =
          neferhooHudPause(size).left - neferhooHudPlate(size).right - 12;
      expect(
        NeferhooPropsArt.hintPillSize(Neferhoo.neferhooScuffHint, 360).width,
        lessThanOrEqualTo(room),
      );
      // The papyrus cards' one-line words are set smaller to fit.
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      for (final (words, points, fit) in [
        (NeferhooEncounterUi.name, 28.0, NeferhooEncounterUi.cardW - 56),
        (NeferhooEncounterUi.epithet, 10.4, NeferhooEncounterUi.cardW - 64),
        (NeferhooEncounterUi.victoryTitle, 25.0, 282.0 - 36),
        (NeferhooEncounterUi.victoryLine, 10.4, 282.0 - 64),
      ]) {
        final s = NeferhooStaging.text(
          c,
          words,
          Offset.zero,
          points,
          const Color(0xff000000),
          center: true,
          fit: fit,
        );
        expect(s.width, lessThanOrEqualTo(fit + .5), reason: words);
      }
      rec.endRecording().dispose();
      // FINISH on the gate's sign and the arrival label.
      final finish = l.encounterFinish;
      expect(
        min(
              360 * .062,
              360 * .23 / FinishGateArt.emWidth(finish, FontWeight.w700, .06),
            ) *
            FinishGateArt.emWidth(finish, FontWeight.w700, .06),
        lessThanOrEqualTo(360 * .23 + .01),
      );
      // The Gargoyle's card stays clear of his head.
      final gargoyle = boss(BossKind.searchlightGargoyle);
      final card = GargoyleEncounterUi.cardRect(size, gargoyle);
      expect(card.right, lessThanOrEqualTo(size.width));
      expect(card.left, greaterThanOrEqualTo(0));
    });

    test('the STRONGER! card shows the part of the hint after the dot', () {
      final b = SkyBoss(number: 1, x: 1.6, staged: true)..age = 20;
      b
        ..stageReached = 1
        ..stageUpAt = 19.5;
      expect(BossStageHudArt.hintOf(b), 'Triple shots, and his bats join in!');
      pseudo();
      final words = BossStageHudArt.hintOf(b)!;
      expect(words, isNot(contains('·')));
      expect(words, isNot('Triple shots, and his bats join in!'));
      expect(L10n.strings.bossHint_strongerBaronBat, contains(words));
    });

    test('a language switch lays the words out again (no stale cache)', () {
      final before = GargoyleHudArt.lampTagSize(u).width;
      final enTag = NeferhooPropsArt.tagRect(
        'MAIL CALL',
        'Shoot them back!',
        120,
        160,
        size,
      );
      pseudo();
      expect(GargoyleHudArt.lampTagSize(u).width, greaterThan(before));
      expect(GargoyleHudArt.lampWords, L10n.strings.bossGargoyleLampOpen);
      expect(
        NeferhooPropsArt.tagRect(
          L10n.strings.bossNeferhooMailCall,
          L10n.strings.bossNeferhooShootBack,
          120,
          160,
          size,
        ).width,
        greaterThan(enTag.width),
      );
      L10n.debugReset();
      expect(GargoyleHudArt.lampTagSize(u).width, before);
    });

    test("Neferhoo's prewarm runs again for a new language", () {
      NeferhooEncounterArt.prewarmAhead();
      expect(NeferhooEncounterArt.warm, isTrue);
      pseudo();
      expect(NeferhooEncounterArt.warm, isFalse);
      NeferhooEncounterArt.prewarmAhead();
      expect(NeferhooEncounterArt.warm, isTrue);
    });

    test('the vanguard banner and the finish line paint in every language', () {
      for (final apply in [pseudo, () => L10n.apply(AppLanguage.ar)]) {
        apply();
        expect(
          BossVanguardArt.call(BossKind.kingCoo),
          L10n.strings.vanguard_kingCoo_call,
        );
        final rec = ui.PictureRecorder();
        final c = ui.Canvas(rec, Offset.zero & size);
        FinishGateArt.paint(
          c,
          size.height,
          x: 400,
          seconds: 1,
          arrived: false,
          reducedMotion: false,
        );
        ArrivalArt.seal(c, const Offset(400, 300), 10);
        rec.endRecording().dispose();
      }
    });
  });

  test('every S3 message is used and described', () {
    // The encounter art's own words (a smoke check that the shared card
    // still reads the right keys).
    expect(
      BossEncounterArt.nameCardEyebrow(boss(BossKind.kingCoo)),
      'GUARDIAN',
    );
    expect(
      BossEncounterArt.nameCardEyebrow(boss(BossKind.pirate)),
      'ENCOUNTER 04',
    );
    expect(
      BossEncounterArt.victoryTitle(boss(BossKind.neferhoo)),
      'GUARDIAN DOWN!',
    );
    expect(
      NeferhooEncounterArt.caption,
      'GET READY  ·  SHOOT HIS LETTERS BACK',
    );
  });
}
