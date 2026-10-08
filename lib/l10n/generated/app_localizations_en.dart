// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get languageKeyLabel => 'Language';

  @override
  String languageKeySemantics(String language) {
    return 'Language: $language. Change the game\'s language.';
  }

  @override
  String get languageSystemDefault => 'System default';

  @override
  String languageSystemDetail(String language) {
    return 'Follows your phone: $language';
  }

  @override
  String get languageCurrent => 'Current language';

  @override
  String get languageName_en => 'English';

  @override
  String get languageName_es_419 => 'Spanish (Latin America)';

  @override
  String get languageName_pt_br => 'Portuguese (Brazil)';

  @override
  String get languageName_id => 'Indonesian';

  @override
  String get languageName_fr => 'French';

  @override
  String get languageName_de => 'German';

  @override
  String get languageName_ja => 'Japanese';

  @override
  String get languageName_ko => 'Korean';

  @override
  String get languageName_tr => 'Turkish';

  @override
  String get languageName_zh_hant => 'Traditional Chinese';

  @override
  String get languageName_ru => 'Russian';

  @override
  String get languageName_ar => 'Arabic';

  @override
  String get voicePackReady => 'Voices ready';

  @override
  String get voicePackDownload => 'Get voices';

  @override
  String voicePackDownloading(int percent) {
    return 'Voices $percent%';
  }

  @override
  String get voicePackStarting => 'Getting voices';

  @override
  String get voicePackEnglish => 'English voices';

  @override
  String get voicePackFailed => 'Voices failed';

  @override
  String get settingsTitle => 'Make yourself at home.';

  @override
  String get settingsSectionSound => 'Sound';

  @override
  String get settingsSectionComfort => 'Comfort';

  @override
  String get settingsMusicTitle => 'Sky Club soundtrack';

  @override
  String get settingsMusicDetail => 'Menu, adventure and boss themes.';

  @override
  String get settingsEffectsTitle => 'Sound effects';

  @override
  String get settingsEffectsDetail =>
      'Flight, combat, pickups and menu feedback.';

  @override
  String get settingsVoicesTitle => 'Character voices';

  @override
  String get settingsVoicesDetail =>
      'Story scenes, thank-you notes and sprint calls.';

  @override
  String get settingsReducedMotionTitle => 'Reduced motion';

  @override
  String get settingsReducedMotionDetail =>
      'Quieter menus and fewer decorative effects.';

  @override
  String get settingsSwitchOn => 'ON';

  @override
  String get settingsSwitchOff => 'OFF';

  @override
  String get settingsUnavailable => 'Your settings need a moment.';

  @override
  String get settingsPrivacyKicker => 'ON-DEVICE. ALWAYS.';

  @override
  String get settingsPrivacyTitle => 'Your camera stays yours.';

  @override
  String get settingsPrivacyBody =>
      'Video and optional microphone audio stay on this phone. Unsaved clips are discarded. No uploads.';

  @override
  String get settingsCameraLab => 'Camera & tracking lab';

  @override
  String get settingsAbout => 'About & licenses';

  @override
  String settingsVersion(String version) {
    return 'v$version';
  }

  @override
  String settingsAboutSemantics(String version) {
    return 'About & licenses, version $version';
  }

  @override
  String get settingsReset => 'Reset local progress';

  @override
  String settingsResetDone(String bird) {
    return 'A fresh start. $bird is ready for you.';
  }

  @override
  String get settingsResetTitle => 'Start a fresh adventure?';

  @override
  String get settingsResetBody =>
      'This deletes your saved videos, replays, scores, runs, built levels and settings from this phone. It cannot be undone.';

  @override
  String get settingsResetBodyCloud =>
      'This deletes your saved videos, replays, scores, runs, built levels and settings from this phone, and your Play Games cloud save. It cannot be undone.';

  @override
  String get settingsResetConfirm => 'Reset everything';

  @override
  String get settingsResetKeep => 'Keep my progress';

  @override
  String get playGamesName => 'Play Games';

  @override
  String get playGamesConnected => 'Connected';

  @override
  String get playGamesNotConnected => 'Not connected';

  @override
  String get playGamesConnecting => 'Connecting…';

  @override
  String get playGamesConnectFailed => 'Couldn’t connect';

  @override
  String get playGamesIdle => 'Cloud save & achievements';

  @override
  String get playGamesSaving => 'Saving to cloud…';

  @override
  String get playGamesOfflineUnsaved => 'Offline · not saved yet';

  @override
  String playGamesOfflineSaved(String ago) {
    return 'Offline · saved $ago';
  }

  @override
  String get playGamesUpdateNeeded => 'Update Beakbound to sync';

  @override
  String get playGamesUnreadable => 'Cloud save can’t be read';

  @override
  String get playGamesOn => 'Cloud save is on';

  @override
  String get playGamesResetElsewhere => 'Reset on another phone';

  @override
  String playGamesRestored(String ago) {
    return 'Cloud restored · $ago';
  }

  @override
  String playGamesSaved(String ago) {
    return 'Saved to cloud · $ago';
  }

  @override
  String get playGamesAchievementsSemantics => 'Play Games achievements';

  @override
  String get playGamesConnectSemantics => 'Connect Play Games';

  @override
  String get playGamesAchievements => 'Achievements';

  @override
  String get playGamesConnect => 'Connect';

  @override
  String get timeAgoJustNow => 'just now';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours h ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days d ago',
    );
    return '$_temp0';
  }

  @override
  String get calloutLife => '+1 LIFE!';

  @override
  String calloutStarTrio(int points) {
    return 'STAR TRIO +$points!';
  }

  @override
  String get calloutNiceShot => 'NICE SHOT!';

  @override
  String calloutNiceShotPoints(int points) {
    return 'NICE SHOT +$points!';
  }

  @override
  String get calloutSmash => 'SMASH!';

  @override
  String calloutSmashPoints(int points) {
    return 'SMASH +$points!';
  }

  @override
  String calloutSmashChain(int count) {
    return 'SMASH ×$count!';
  }

  @override
  String get calloutBossDown => 'BOSS DOWN!';

  @override
  String calloutBossDownPoints(int points) {
    return 'BOSS DOWN +$points!';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '$multiplier× STAR POWER!';
  }

  @override
  String get calloutPerfect => 'PERFECT!';

  @override
  String calloutPerfectChain(int count) {
    return 'PERFECT ×$count';
  }

  @override
  String get calloutShieldReady => 'SHIELD READY';

  @override
  String get calloutShieldSave => 'SHIELD SAVE!';

  @override
  String get calloutKeepFlying => 'KEEP FLYING!';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count GATES!',
    );
    return '$_temp0';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds SECONDS LEFT',
    );
    return '$_temp0';
  }

  @override
  String get calloutStarMagnet => 'STAR MAGNET!';

  @override
  String get calloutSprintRing => 'SPRINT RING!';

  @override
  String calloutRushChain(int count) {
    return 'RUSH ×$count!';
  }

  @override
  String calloutMeteorPoints(int points) {
    return 'METEOR +$points!';
  }

  @override
  String calloutBatPoints(int points) {
    return 'BAT +$points!';
  }

  @override
  String get calloutScorched => 'SCORCHED!';

  @override
  String get region_jungle => 'Jungle';

  @override
  String get region_antarctica => 'Antarctica';

  @override
  String get region_aztec => 'Aztec';

  @override
  String get region_paris => 'Paris';

  @override
  String get region_egypt => 'Egypt';

  @override
  String get region_cyberpunk => 'Cyberpunk City';

  @override
  String get region_china => 'China';

  @override
  String get region_brazil => 'Brazil';

  @override
  String get region_newYork => 'New York';

  @override
  String get region_arabia => 'Ancient Arabia';

  @override
  String get region_rome => 'Ancient Rome';

  @override
  String get region_mexico => 'Mexico';

  @override
  String get region_sea => 'Open Sea';

  @override
  String get boss_baronBat_name => 'Baron Bat';

  @override
  String get boss_spitterBeetle_name => 'Spitter King';

  @override
  String get boss_duskMoth_name => 'Dusk Empress';

  @override
  String get boss_pirate_name => 'Pirate Captain';

  @override
  String get boss_dragon_name => 'Ember Dragon';

  @override
  String get boss_kingCoo_name => 'King Coo';

  @override
  String get boss_searchlightGargoyle_name => 'Searchlight Gargoyle';

  @override
  String get boss_neferhoo_name => 'Neferhoo';

  @override
  String get bird_0_name => 'Pip';

  @override
  String get bird_1_name => 'Peaches';

  @override
  String get bird_2_name => 'Minty';

  @override
  String get bird_3_name => 'Orbit';

  @override
  String get playMode_pushUp => 'Push-Up Flight';

  @override
  String get playMode_jump => 'Jump & Fly';

  @override
  String get playMode_touch => 'Tap & Fly';

  @override
  String get playMode_squat => 'Squat & Fly';

  @override
  String get chapter_1_route => 'The Canopy Route';

  @override
  String get chapter_1_postmark => 'CANOPY ROUTE';

  @override
  String get chapter_1_postcard =>
      'Letters are landing in the treetops again! The toucans say thank you (very loudly). Baron Bat’s crown is on our mantelpiece.';

  @override
  String get chapter_1_postscript =>
      'The ancient road smells like something is bubbling.';

  @override
  String get chapter_2_route => 'The Ancient Road';

  @override
  String get chapter_2_postmark => 'ANCIENT ROAD';

  @override
  String get chapter_2_postcard =>
      'The caravans are rolling and the only thing brewing is mint tea. We kept the King’s flask crown as a vase.';

  @override
  String get chapter_2_postscript =>
      'The city lamps went dark last night. Bring a light.';

  @override
  String get chapter_3_route => 'The Lamplight Line';

  @override
  String get chapter_3_postmark => 'LAMPLIGHT LINE';

  @override
  String get chapter_3_postcard =>
      'The lamps are lit and the night mail is wide awake! Paris sends a croissant. New York sends a pretzel.';

  @override
  String get chapter_3_postscript => 'The harbour bells have stopped ringing.';

  @override
  String get chapter_4_route => 'The Tide Route';

  @override
  String get chapter_4_postmark => 'TIDE ROUTE';

  @override
  String get chapter_4_postcard =>
      'The harbour bells ring for letters again, not cannons. The parrot stayed. He says hello.';

  @override
  String get chapter_4_postscript =>
      'They say the sky at the edge of the map is on fire.';

  @override
  String get chapter_5_route => 'The Edge of the Map';

  @override
  String get chapter_5_postmark => 'EDGE OF THE MAP';

  @override
  String get chapter_5_postcard =>
      'The sky is clear from pole to pole and every route is running. The whole Sky Club is proud of you.';

  @override
  String get chapter_5_postscript =>
      'The endless sky is still out there, whenever you are.';

  @override
  String get level_1_1_name => 'First Delivery';

  @override
  String get level_1_1_cargo => 'A birthday card for the toucan twins';

  @override
  String get level_1_1_sender => 'The toucan twins';

  @override
  String get level_1_1_hint => 'Tap to flap. Fly through the stars.';

  @override
  String get level_1_2_name => 'Star Streak';

  @override
  String get level_1_2_cargo => 'Star charts for the sloth stargazer';

  @override
  String get level_1_2_sender => 'The sloth stargazer';

  @override
  String get level_1_2_hint =>
      'Chain stars for 3×; three perfect gates earn a magnet.';

  @override
  String get level_1_3_name => 'Bat Patrol';

  @override
  String get level_1_3_cargo => 'Night-lights for the firefly nursery';

  @override
  String get level_1_3_sender => 'The firefly nursery';

  @override
  String get level_1_3_hint => 'Shoot. Tap Shoot to knock out bats.';

  @override
  String get level_1_4_name => 'Carnival Skies';

  @override
  String get level_1_4_cargo => 'Feather boas for the carnival parade';

  @override
  String get level_1_4_sender => 'The samba macaws';

  @override
  String get level_1_4_hint => 'Gale! Watch the ! and dodge the footballs.';

  @override
  String get level_1_5_name => 'Express Post';

  @override
  String get level_1_5_cargo => 'A rush invitation for the drum captain';

  @override
  String get level_1_5_sender => 'The drum captain';

  @override
  String get level_1_5_hint => 'Sprint smashes bats and surges ahead.';

  @override
  String get level_1_6_name => 'Temple Steps';

  @override
  String get level_1_6_cargo => 'Cocoa beans for the temple cooks';

  @override
  String get level_1_6_sender => 'The temple cooks';

  @override
  String get level_1_7_name => 'Sunrise Roost';

  @override
  String get level_1_7_cargo => 'A sundial for the dawn keeper';

  @override
  String get level_1_7_sender => 'The dawn keeper';

  @override
  String get level_1_8_name => 'Baron Bat';

  @override
  String get level_1_8_cargo => 'A final notice for Baron Bat';

  @override
  String get level_1_8_sender => 'Baron Bat';

  @override
  String get level_2_1_name => 'Beetle Road';

  @override
  String get level_2_1_cargo => 'Laurel wreaths for the chariot racers';

  @override
  String get level_2_1_sender => 'The chariot racers';

  @override
  String get level_2_1_hint => 'Beetles spit seeds. Shoot the seeds down.';

  @override
  String get level_2_2_name => 'Sealed Gates';

  @override
  String get level_2_2_cargo => 'A new chisel for the statue carver';

  @override
  String get level_2_2_sender => 'The statue carver';

  @override
  String get level_2_2_hint => 'Hold Shoot for a big rock that breaks stone.';

  @override
  String get level_2_3_name => 'Wildfire Run';

  @override
  String get level_2_3_cargo => 'Water buckets for the fire brigade';

  @override
  String get level_2_3_sender => 'The fire brigade';

  @override
  String get level_2_3_hint => 'Fly through the gold rings to outrun the fire!';

  @override
  String get level_2_4_name => 'Nile Switchbacks';

  @override
  String get level_2_4_cargo => 'A book of new riddles for the Sphinx';

  @override
  String get level_2_4_sender => 'The Sphinx';

  @override
  String get level_2_5_name => 'Skyfall';

  @override
  String get level_2_5_cargo => 'A telescope for the pyramid astronomer';

  @override
  String get level_2_5_sender => 'The pyramid astronomer';

  @override
  String get level_2_5_hint => 'Ring sprints smash meteors.';

  @override
  String get level_2_6_name => 'Return to Sender';

  @override
  String get level_2_6_cargo => 'A feather duster for the caretaker';

  @override
  String get level_2_6_sender => 'The pyramid caretaker';

  @override
  String get level_2_6_hint =>
      'Shoot his letters to send them back. Return to sender!';

  @override
  String get level_2_7_name => 'Lantern Bazaar';

  @override
  String get level_2_7_cargo => 'Lamp oil for the lantern sellers';

  @override
  String get level_2_7_sender => 'The lantern sellers';

  @override
  String get level_2_8_name => 'The Long Caravan';

  @override
  String get level_2_8_cargo => 'Water flasks for the long caravan';

  @override
  String get level_2_8_sender => 'The caravan leader';

  @override
  String get level_2_9_name => 'Spitter King';

  @override
  String get level_2_9_cargo => 'A stop-brewing order for the Spitter King';

  @override
  String get level_2_9_sender => 'Spitter King';

  @override
  String get level_3_1_name => 'Moth Light';

  @override
  String get level_3_1_cargo => 'Light bulbs for the theatre marquee';

  @override
  String get level_3_1_sender => 'The stage manager';

  @override
  String get level_3_1_hint => 'Moths fire fans of three. Slip between them.';

  @override
  String get level_3_2_name => 'Wheels in the Rain';

  @override
  String get level_3_2_cargo => 'Umbrellas for the newsstand pigeons';

  @override
  String get level_3_2_sender => 'The newsstand pigeons';

  @override
  String get level_3_2_hint =>
      'Alley pigeons swoop in to grab stars. Shoot them first!';

  @override
  String get level_3_3_name => 'Steam Alley';

  @override
  String get level_3_3_cargo => 'Hot pretzels for the night-shift cabbies';

  @override
  String get level_3_3_sender => 'The night cabbies';

  @override
  String get level_3_3_hint =>
      'Vents hiss, then burst. Hop the hot ones, ride the soft ones.';

  @override
  String get level_3_4_name => 'Storm Warning';

  @override
  String get level_3_4_cargo => 'A weather vane for the tallest tower';

  @override
  String get level_3_4_sender => 'The tower keeper';

  @override
  String get level_3_4_hint =>
      'Stay out of the light. Shoot the lamp when it opens! No Sprint here.';

  @override
  String get level_3_5_name => 'Crystal Rooftops';

  @override
  String get level_3_5_cargo => 'Croissants for the rooftop painters';

  @override
  String get level_3_5_sender => 'The rooftop painters';

  @override
  String get level_3_6_name => 'After the Gale';

  @override
  String get level_3_6_cargo => 'Sheet music for the accordion player';

  @override
  String get level_3_6_sender => 'The accordion player';

  @override
  String get level_3_6_hint => 'Gale! Watch the ! and take the open side.';

  @override
  String get level_3_7_name => 'Midnight Express';

  @override
  String get level_3_7_cargo => 'A midnight love letter for the baker';

  @override
  String get level_3_7_sender => 'The baker';

  @override
  String get level_3_7_hint => 'Sprint through the flocks.';

  @override
  String get level_3_8_name => 'Dusk Empress';

  @override
  String get level_3_8_cargo => 'A wake-up call for the Dusk Empress';

  @override
  String get level_3_8_sender => 'Dusk Empress';

  @override
  String get level_4_1_name => 'Harbour Lights';

  @override
  String get level_4_1_cargo => 'A new lens for the lighthouse keeper';

  @override
  String get level_4_1_sender => 'The lighthouse keeper';

  @override
  String get level_4_2_name => 'Volcano Pass';

  @override
  String get level_4_2_cargo => 'Oven mitts for the volcano baker';

  @override
  String get level_4_2_sender => 'The volcano baker';

  @override
  String get level_4_2_hint => 'Hop over the lava plumes.';

  @override
  String get level_4_3_name => 'Down the Coast';

  @override
  String get level_4_3_cargo => 'Kite string for the beach festival';

  @override
  String get level_4_3_sender => 'The kite flyers';

  @override
  String get level_4_4_name => 'Low Water';

  @override
  String get level_4_4_cargo => 'A reply for the island hermit';

  @override
  String get level_4_4_sender => 'The island hermit';

  @override
  String get level_4_4_hint => 'Don\'t touch the water.';

  @override
  String get level_4_5_name => 'Spring Tide';

  @override
  String get level_4_5_cargo => 'A tide table for the ferry crew';

  @override
  String get level_4_5_sender => 'The ferry crew';

  @override
  String get level_4_5_hint => 'When the bell rings, fly high.';

  @override
  String get level_4_6_name => 'Broadside Bay';

  @override
  String get level_4_6_cargo => 'Fish biscuits for the gull colony';

  @override
  String get level_4_6_sender => 'The gull colony';

  @override
  String get level_4_7_name => 'Stormy Crossing';

  @override
  String get level_4_7_cargo => 'Dry socks for the storm-watch sailors';

  @override
  String get level_4_7_sender => 'The storm watch';

  @override
  String get level_4_8_name => 'Pirate Captain';

  @override
  String get level_4_8_cargo => 'A return-the-mail order for the Captain';

  @override
  String get level_4_8_sender => 'Pirate Captain';

  @override
  String get level_5_1_name => 'Aurora Post';

  @override
  String get level_5_1_cargo => 'Woolly hats for the penguin choir';

  @override
  String get level_5_1_sender => 'The penguin choir';

  @override
  String get level_5_1_hint => 'Any rush can come now. Read the banner!';

  @override
  String get level_5_2_name => 'Polar Night';

  @override
  String get level_5_2_cargo => 'Hot cocoa for the polar station';

  @override
  String get level_5_2_sender => 'The polar station';

  @override
  String get level_5_3_name => 'Neon Express';

  @override
  String get level_5_3_cargo => 'Spare fuses for the noodle bar sign';

  @override
  String get level_5_3_sender => 'The noodle chef';

  @override
  String get level_5_4_name => 'Data Storm';

  @override
  String get level_5_4_cargo => 'A paper letter for a curious robot';

  @override
  String get level_5_4_sender => 'Unit 7';

  @override
  String get level_5_5_name => 'Skyline Sprint';

  @override
  String get level_5_5_cargo => 'Race tickets for the rooftop runners';

  @override
  String get level_5_5_sender => 'The rooftop runners';

  @override
  String get level_5_6_name => 'Lantern Festival';

  @override
  String get level_5_6_cargo => 'Paper lanterns for the festival';

  @override
  String get level_5_6_sender => 'The lantern makers';

  @override
  String get level_5_7_name => 'The Last Leg';

  @override
  String get level_5_7_cargo => 'Mountain tea for the monastery';

  @override
  String get level_5_7_sender => 'The mountain monks';

  @override
  String get level_5_8_name => 'Ember Dragon';

  @override
  String get level_5_8_cargo => 'The first letter ever sent to the Dragon';

  @override
  String get level_5_8_sender => 'Ember Dragon';

  @override
  String get storyPostmasterName => 'Postmaster Bill';

  @override
  String get storySkip => 'Skip';

  @override
  String get storyNextLineSemantics => 'Next line';

  @override
  String get storyFinishSemantics => 'Finish';

  @override
  String storyLineSemantics(String name, String line) {
    return '$name: $line';
  }

  @override
  String get campaignMotto => 'Every letter lands.';

  @override
  String launchSemantics(String brand, String motto) {
    return '$brand. $motto';
  }

  @override
  String get levelIntroFly => 'Fly!';

  @override
  String levelIntroRunUp(int seconds) {
    return 'A $seconds s run-up first';
  }

  @override
  String levelIntroLength(int seconds) {
    return 'About $seconds s to the finish';
  }

  @override
  String get campaignGuardian => 'GUARDIAN';

  @override
  String get levelIntroBossFight => 'BOSS FIGHT';

  @override
  String get levelIntroNew => 'NEW';

  @override
  String get levelIntroTip => 'TIP';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {'other': 'Beat $boss'});
    return '$_temp0';
  }

  @override
  String get levelIntroGoalFinish => 'Reach the finish';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Collect $count stars',
      one: 'Collect 1 star',
    );
    return '$_temp0';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'One star: $goal.',
      'two': 'Two stars: $goal.',
      'other': 'Three stars: $goal.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'One star: $goal. Earned.',
      'two': 'Two stars: $goal. Earned.',
      'other': 'Three stars: $goal. Earned.',
    });
    return '$_temp0';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Best: $count stars',
      one: 'Best: 1 star',
    );
    return '$_temp0';
  }

  @override
  String get levelIntroNotDelivered => 'Not delivered yet';

  @override
  String get levelIntroFirstFlight => 'First flight';

  @override
  String get levelIntroControlFlap => 'Flap';

  @override
  String get levelIntroControlShoot => 'Shoot';

  @override
  String get levelIntroControlSprint => 'Sprint';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Controls: Flap.',
      'shoot': 'Controls: Flap, Shoot.',
      'sprint': 'Controls: Flap, Sprint.',
      'other': 'Controls: Flap, Shoot, Sprint.',
    });
    return '$_temp0';
  }

  @override
  String get levelIntroSpecialDelivery => 'SPECIAL DELIVERY';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return 'Special delivery: $cargo.';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return 'Level $level, $name. $region.';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return 'Level $level, $name. $region. Guardian level: $boss.';
  }

  @override
  String get levelIntroStory => 'Story';

  @override
  String get commonClose => 'Close';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonHome => 'Home';

  @override
  String get commonBackHome => 'Back home';

  @override
  String get campaignComingSoon => 'Coming soon';

  @override
  String campaignStopComingSoon(String region) {
    return '$region — coming soon';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'other': 'Beat $boss to unlock',
    });
    return '$_temp0';
  }

  @override
  String campaignLockedFinish(String level) {
    return 'Finish $level to unlock';
  }

  @override
  String get campaignMapUnavailable => 'The map needs a moment.';

  @override
  String campaignCloseLevelSemantics(String name) {
    return 'Close $name';
  }

  @override
  String get campaignMapPreviousStop => 'Previous stop';

  @override
  String get campaignMapNextStop => 'Next stop';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. Chapter $chapter, $route. Coming soon.',
      'locked': '$region. Chapter $chapter, $route. Locked.',
      'other': '$region. Chapter $chapter, $route.',
    });
    return '$_temp0';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return 'CHAPTER $chapter · $route';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level, $name, boss',
      'guardian': 'Level $level, $name, guardian $boss',
      'other': 'Level $level, $name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '$node. Locked.';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '$node. Locked. $note.';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars of 3 stars',
    );
    return '$node. Next up. $_temp0.';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars of 3 stars',
    );
    return '$node. $_temp0.';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'Gargoyle',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return 'Chapter $chapter postcard';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars of $total campaign stars',
    );
    return '$_temp0';
  }

  @override
  String get campaignPostcardGreeting => 'Dear courier,';

  @override
  String get campaignPostcardPs => 'P.S.';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return 'Postcard from $route. Dear courier, $body P.S. $postscript';
  }

  @override
  String get campaignPostcardGreetingsFrom => 'Greetings from';

  @override
  String get campaignPostcardHeader => 'SKY CLUB POSTCARD';

  @override
  String campaignPostcardSignature(String route) {
    return '— $route';
  }

  @override
  String get campaignPostcardAddressName => 'The courier';

  @override
  String get campaignPostcardAddressStreet => 'Sky Club post';

  @override
  String get campaignPostcardAddressCity => 'Up in the sky';

  @override
  String get campaignPostmarkDelivered => 'DELIVERED';

  @override
  String get campaignPostmarkClub => 'SKY CLUB POST';

  @override
  String get campaignStampSkyClub => 'SKY CLUB';

  @override
  String campaignThanksQuoted(String thanks) {
    return '“$thanks”';
  }

  @override
  String campaignThanksSignature(String sender) {
    return '— $sender';
  }

  @override
  String campaignThanksSemantics(String sender, String thanks) {
    return 'Thank-you note from $sender: $thanks';
  }

  @override
  String get flightSetupTitlePushUp => 'A little setup. A lot of sky.';

  @override
  String get flightSetupTitleSquat => 'Feet planted. Wings open.';

  @override
  String get flightSetupTitleJump => 'Small jumps. Big wings.';

  @override
  String flightSetupBuiltTag(String name) {
    return 'LEVEL · $name';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '$course · SCORED';
  }

  @override
  String get flightSetupRoomPushUp => 'Make a little room to move.';

  @override
  String get flightSetupRoomBody => 'Show your whole body.';

  @override
  String get flightSetupTipsPushUp =>
      'Phone low. Show an arm and hip.\nFacing it? Keep both shoulders in view.';

  @override
  String get flightSetupTipsSquat =>
      'Squat to descend. Stand to rise.\nKeep both feet on the floor.';

  @override
  String get flightSetupTipsJump =>
      'Jump for a boost + 3s glide.\nLand before jumping again.';

  @override
  String get flightSetupHowToFly => 'HOW TO FLY';

  @override
  String get flightSetupStep1PushUp => 'Show your arm and hip';

  @override
  String get flightSetupStep1Squat => 'Make room to squat';

  @override
  String get flightSetupStep1Jump => 'Make room to jump';

  @override
  String get flightSetupStep1DetailPushUp =>
      'Facing the phone? Show both shoulders, one arm and a hip.';

  @override
  String get flightSetupStep1DetailBody =>
      'Phone in landscape. Show your body and both feet.';

  @override
  String get flightSetupStep2PushUp => 'Find your movement range';

  @override
  String get flightSetupStep2Squat => 'Find your comfortable squat';

  @override
  String get flightSetupStep2Jump => 'Stand tall and still';

  @override
  String get flightSetupStep2DetailPushUp =>
      'Find a comfortable top, then move down and up twice.';

  @override
  String get flightSetupStep2DetailSquat =>
      'Stand still, squat and hold briefly, then stand back up.';

  @override
  String get flightSetupStep2DetailJump =>
      'Hold still briefly. Then jump for a big boost.';

  @override
  String get flightSetupStep3Stars => 'Collect stars';

  @override
  String get flightSetupStep3DetailJump =>
      'Stars add 0.75s of glide, up to 5s. Collect trios for +5 points.';

  @override
  String get flightSetupLivesEndless =>
      'Three hearts + a shield. You can pause any time.';

  @override
  String get flightSetupLivesClassic =>
      'A collision or losing your position ends a scored flight. You can pause any time.';

  @override
  String get flightSetupCameraButton => 'Set up my camera';

  @override
  String get flightMicTitle => 'Record microphone';

  @override
  String get flightMicOn => 'On';

  @override
  String get flightMicOptional => 'Optional';

  @override
  String get flightMicDetail =>
      'Add your voice and room sound to replays. Uses the microphone during flight only. Saved on this phone.';

  @override
  String get flightMicSemantics => 'Record microphone for replays';

  @override
  String get flightMicSettings => 'Microphone settings';

  @override
  String get flightCalibrationTitleReady => 'You found your wings!';

  @override
  String get flightCalibrationTitleWaking => 'Waking up your camera…';

  @override
  String get flightCalibrationTitleError => 'Let’s reconnect your camera.';

  @override
  String get flightCalibrationTitleRange => 'Find your movement range.';

  @override
  String get flightCalibrationTitleStill => 'Stand tall and still.';

  @override
  String get flightCalibrationStepTry => 'Try moving your bird.';

  @override
  String get flightCalibrationStepTop => 'Find a comfortable top.';

  @override
  String get flightCalibrationStepLower => 'Lower yourself slowly.';

  @override
  String get flightCalibrationStepPushBack => 'Push back up.';

  @override
  String get flightCalibrationStepStill => 'Stand tall and still.';

  @override
  String get flightCalibrationStepSquat => 'Squat comfortably.';

  @override
  String get flightCalibrationStepStandUp => 'Stand back up.';

  @override
  String get flightCalibrationStepDone => 'You found your wings!';

  @override
  String get flightCalibrationReadyPushUp => 'Push up to rise. Lower to glide.';

  @override
  String get flightCalibrationReadySquat => 'Squat to descend. Stand to rise.';

  @override
  String get flightCalibrationReadyJump =>
      'Jump, then rest while your bird glides.';

  @override
  String get flightCalibrationKeepPushUp =>
      'Keep your shoulders, one arm and a hip in view. Move comfortably.';

  @override
  String get flightCalibrationKeepBody =>
      'Keep your shoulders, hips and both feet in view.';

  @override
  String get flightCalibrationLearning => 'Learning your range as you move.';

  @override
  String get flightCalibrationAfter => 'Your bird moves after calibration.';

  @override
  String get flightCalibrationJump => 'Jump!';

  @override
  String get flightCalibrationTagCheck => 'CONTROL CHECK';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '$count / 2 PUSH-UPS';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '$percent% CALIBRATED';
  }

  @override
  String get flightCalibrationTakeoff => 'Ready for takeoff';

  @override
  String get flightCalibrationStarting => 'Starting…';

  @override
  String get flightCalibrationRestart => 'Start calibration again';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '$rate updates/s · $p95 ms p95';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '$rate updates/s · $p95 ms p95 (processing only)';
  }

  @override
  String get flightCalibrationStatusReady => 'READY';

  @override
  String get flightCalibrationStatusStarting => 'STARTING';

  @override
  String get flightCalibrationStatusCameraOff => 'CAMERA OFF';

  @override
  String get flightCalibrationStatusCalibrating => 'CALIBRATING';

  @override
  String get flightSwitchCameraSemantics => 'Switch camera';

  @override
  String get flightCalibrationStepIntoView => 'Step into view';

  @override
  String get flightCameraTroubleTitle => 'A fresh start usually helps.';

  @override
  String get flightCameraTroubleAllow => 'Allow camera access in Settings.';

  @override
  String get flightCameraTroubleClose =>
      'Close any other camera app, then try again.';

  @override
  String get flightCameraPermissionSemantics => 'Camera permission settings';

  @override
  String get flightNoteRememberFailed =>
      'Changed for this flight. Could not remember your preference.';

  @override
  String get flightNoteMicUnavailable =>
      'Microphone unavailable. Video and gameplay still work.';

  @override
  String get flightNoteMicBlocked =>
      'Microphone blocked. You can allow it in Settings; video still works.';

  @override
  String get flightNoteMicOff =>
      'Microphone off. You can still play and save video.';

  @override
  String get flightNoteVideoUnavailable =>
      'Camera video unavailable. Gameplay can still be saved.';

  @override
  String get flightNoteMicAudioLost =>
      'Microphone audio was unavailable. Your video and gameplay can still be saved.';

  @override
  String get flightNoteVideoInterrupted =>
      'Camera video interrupted. Available footage and gameplay can still be saved.';

  @override
  String get flightNoteSessionSaveFailed =>
      'Could not save the session. Tap Save session to retry.';

  @override
  String get flightNoteWakingCamera => 'Waking up your camera…';

  @override
  String get flightNoteCameraOff =>
      'Camera access is off. Allow it in Android settings, then come back and try again.';

  @override
  String get flightNoteCameraFailed =>
      'The camera could not start. Try again or switch cameras.';

  @override
  String get flightNotePreparing => 'Preparing your session…';

  @override
  String get flightNoteSaveFailed =>
      'Could not save your flight. Tap to retry.';

  @override
  String get flightNoteWelcomeBack =>
      'Welcome back. Let’s check your position again.';

  @override
  String get flightNoteCameraInterrupted =>
      'Camera interrupted. Check camera permission and try again.';

  @override
  String get flightNoteTrackingInterrupted => 'Tracking interrupted';

  @override
  String get flightFindPosition => 'Find your position';

  @override
  String get flightTapSemantics => 'Tap to flap';

  @override
  String flightTapVanguardSemantics(String group) {
    return 'Tap to flap. $group fly in ahead of their boss';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return 'Tap to flap. $boss: $hp of $maxHp health';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return 'Tap to flap. $boss: $hp of $maxHp health. $hint';
  }

  @override
  String get flightSkipToResultsSemantics => 'Skip to results';

  @override
  String get hudPauseSemantics => 'Pause flight';

  @override
  String get flightHintTestSteerKeys => 'Test flight: Up and Down steer.';

  @override
  String get flightHintTestSteerDrag =>
      'Test flight: drag up and down to steer.';

  @override
  String get flightHintTestJumpKeys => 'Test flight: Space for a jump.';

  @override
  String get flightHintTestJumpTap => 'Test flight: tap for a jump.';

  @override
  String get flightHintKeysStars => 'Space to flap. Fly through the stars.';

  @override
  String get flightHintKeysShoot => 'Space to flap. Hold D to charge a shot.';

  @override
  String get flightHintKeysCombat =>
      'Space to flap. Hold D to charge a shot. A to sprint!';

  @override
  String get flightHintKeysPause => 'Space to flap. Esc pauses.';

  @override
  String get flightHintTapStars =>
      'Tap the sky to flap. Fly through the stars.';

  @override
  String get flightHintTapShoot => 'Tap the sky to flap. Hold Shoot to charge.';

  @override
  String get flightHintTapCombat =>
      'Tap the sky to flap. Hold Shoot to charge. Sprint to smash!';

  @override
  String get flightHintTapRelease => 'Tap to flap. Release between taps.';

  @override
  String get flightHintTrail => 'Follow the stars. Your shield is ready.';

  @override
  String get flightHintSky => 'The sky is yours.';

  @override
  String hudClockSemantics(String time) {
    return '$time remaining';
  }

  @override
  String flightSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Star magnet: $seconds seconds remaining',
    );
    return '$_temp0';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Magnet charging: $charge of $gates perfect gates',
    );
    return '$_temp0';
  }

  @override
  String get hudFindingYou => 'Finding you…';

  @override
  String get hudShoot => 'Shoot';

  @override
  String get hudSprint => 'Sprint';

  @override
  String get flightTestNothingSaved => 'nothing is saved';

  @override
  String get flightCountdownReady => 'Ready, steady…';

  @override
  String get flightPauseTitle => 'Take a breather.';

  @override
  String get flightPauseKeepFlying => 'Keep flying';

  @override
  String flightPausedLevel(String id, String name) {
    return '$id · $name. Your bird is perched and waiting.';
  }

  @override
  String flightPausedTest(String name) {
    return 'Test flight of $name. Nothing is saved.';
  }

  @override
  String flightPausedBuilt(String name) {
    return '$name. Your bird is perched and waiting.';
  }

  @override
  String get flightPausedTouch =>
      'Your bird is perched and waiting. We’ll count you back in.';

  @override
  String get flightPausedCamera =>
      'Shake it out, then get back in position. We’ll count you in.';

  @override
  String get flightPauseEdit => 'Edit';

  @override
  String get flightPauseBuilder => 'Builder';

  @override
  String get flightPauseFinish => 'Finish flight';

  @override
  String get hudShieldRecovering => 'Recovering';

  @override
  String get hudShieldReady => 'Shield ready';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Shield charging: $charge of $stars stars',
    );
    return '$_temp0';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hearts remaining',
    );
    return '$_temp0';
  }

  @override
  String get hudSprinting => 'Sprinting';

  @override
  String get hudSprintReady => 'Ready';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Recharging, $seconds seconds',
    );
    return '$_temp0';
  }

  @override
  String get hudSprintHint => 'Rush ahead to smash bats and stone panels';

  @override
  String get hudShotReloading => 'Reloading…';

  @override
  String hudShotFullCharge(int ms) {
    return 'Full charge, $ms ms left';
  }

  @override
  String hudShotCharging(int percent) {
    return 'Charging $percent%';
  }

  @override
  String hudShotAmmo(int percent) {
    return 'Ammo $percent%';
  }

  @override
  String get hudShotHint => 'Hold to charge a bigger rock';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars reached',
    );
    return '$_temp0';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars at $at',
    );
    return '$_temp0';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars stars collected',
    );
    return '$_temp0. $two. $three.';
  }

  @override
  String get hudMax => 'MAX';

  @override
  String hudRouteSemantics(int percent) {
    return 'Route $percent% flown';
  }

  @override
  String hudGlideCompact(String time) {
    return 'Glide · $time';
  }

  @override
  String get hudJumpToGlide => 'Jump to glide';

  @override
  String get hudJump => 'Jump';

  @override
  String hudGlideSemantics(String time) {
    return 'Glide, $time remaining';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return 'Glide ending, $time remaining';
  }

  @override
  String get hudJumpChargeSemantics => 'Jump to charge a 3-second glide';

  @override
  String get hudRecordNewBest => 'New best!';

  @override
  String get hudRecordMatched => 'Best matched!';

  @override
  String hudRecordBest(int best) {
    return 'Best $best';
  }

  @override
  String hudRecordBeyond(int points) {
    return '+$points beyond your best';
  }

  @override
  String get hudRecordOneMore => 'One more for a record';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to a new record',
    );
    return '$_temp0';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '$title. $detail.';
  }

  @override
  String hudScoreSemantics(int score) {
    return 'Score $score';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return 'Score $score, $multiplier times multiplier';
  }

  @override
  String get commonBusySemantics => 'Busy';

  @override
  String get flightResultBumpClouds => 'A little bump in the clouds.';

  @override
  String get flightResultPersonalBest => 'PERSONAL BEST';

  @override
  String get flightResultNewPersonalBest => 'NEW PERSONAL BEST!';

  @override
  String get flightResultStarsCollected => 'STARS COLLECTED';

  @override
  String get flightResultDailyStamped => 'Today’s postcard stamped!';

  @override
  String flightResultNextStamp(String stamp) {
    return 'Next: $stamp';
  }

  @override
  String get flightResultSavedOnPhone => 'Saved on this phone';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Saved on this phone · $total total gates',
    );
    return '$_temp0';
  }

  @override
  String get flightResultSaving => 'Saving your flight…';

  @override
  String get flightResultSessionSaved => 'Session saved · Watch in Records';

  @override
  String get flightResultWatchReplay => 'Watch replay';

  @override
  String get flightResultPreparing => 'Preparing…';

  @override
  String get flightResultSavingShort => 'Saving…';

  @override
  String get flightResultSaveSession => 'Save session';

  @override
  String get flightResultFlyAgain => 'Fly again';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonMap => 'Map';

  @override
  String get commonNext => 'Next';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'push-ups',
    );
    return '$_temp0';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squats',
    );
    return '$_temp0';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jumps',
    );
    return '$_temp0';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flaps',
    );
    return '$_temp0';
  }

  @override
  String get flightStatFlightTime => 'flight time';

  @override
  String get flightStatPerfect => 'perfect';

  @override
  String get flightStatBestStreak => 'best streak';

  @override
  String get flightStatRank => 'rank';

  @override
  String get flightRankSkyCaptain => 'Sky captain';

  @override
  String get flightRankCloudExplorer => 'Cloud explorer';

  @override
  String get flightRankFirstWings => 'First wings';

  @override
  String flightPercent(int percent) {
    return '$percent%';
  }

  @override
  String get gameOverCaptionBest => 'Bumped out on a brand-new best!';

  @override
  String get gameOverCaptionSea => 'A little splash in the sea.';

  @override
  String get gameOverSplash => 'Splash!';

  @override
  String get gameOverBonk => 'Bonk!';

  @override
  String get gameOverEveryMarkSemantics => 'Every mark reached';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more stars for $mark stars',
    );
    return '$_temp0';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '$boss: $hp of $maxHp health left';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '$percent percent of the route flown';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '$boss: $hp HP LEFT';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '$boss LEFT';
  }

  @override
  String get gameOverRouteFlown => 'ROUTE FLOWN';

  @override
  String gameOverHp(int hp) {
    return '$hp HP';
  }

  @override
  String gameOverMoreFor(int count) {
    return '$count more for';
  }

  @override
  String get gameOverBothMarks => 'Both marks reached';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'other': 'Both marks reached. Beat $boss!',
    });
    return '$_temp0';
  }

  @override
  String get miniResultTitle => 'Every flight counts.';

  @override
  String get miniResultComplete => 'FLIGHT COMPLETE';

  @override
  String get miniResultCheerBest => 'Look at you go!';

  @override
  String get miniResultCheerComplete => 'Flight complete!';

  @override
  String get miniResultCheerNice => 'Nice flying.';

  @override
  String get miniResultNew => 'NEW';

  @override
  String get flightEndTrackingLost => 'We lost sight of you for a moment.';

  @override
  String get flightEndPostureLost => 'Your position moved out of range.';

  @override
  String get flightEndBackgrounded => 'You stepped away from the sky.';

  @override
  String get flightEndBreak => 'A well-earned breather.';

  @override
  String get flightEndQuit => 'Until the next adventure.';

  @override
  String get flightEndStalled => 'The game was interrupted.';

  @override
  String get flightEndCompleted => 'A whole sky of stars. All yours.';

  @override
  String get levelResultTryAgain => 'Try again!';

  @override
  String get levelResultVictory => 'Victory!';

  @override
  String get levelResultGuardianDown => 'Guardian down!';

  @override
  String get levelResultDelivered => 'Delivered!';

  @override
  String levelResultComingSoon(String region) {
    return '$region is coming soon!';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '$earned of 3 stars';
  }

  @override
  String levelResultBest(int best) {
    return 'Best $best';
  }

  @override
  String get levelResultNoBest => 'No best yet';

  @override
  String get levelResultFirstClear => 'First clear!';

  @override
  String get levelResultNewBest => 'NEW BEST!';

  @override
  String get levelResultScore => 'SCORE';

  @override
  String get levelResultGoalBoss => 'Boss';

  @override
  String get levelResultGoalGuardian => 'Guardian';

  @override
  String get levelResultGoalFinish => 'Finish';

  @override
  String get levelResultGoalDone => 'Done';

  @override
  String get levelResultGoalNotYet => 'Not yet';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to go',
    );
    return '$_temp0';
  }

  @override
  String get levelResultGoalFinishFirst => 'Finish first';

  @override
  String levelResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '$goal. Done.';
  }

  @override
  String get levelResultPostcardWaiting => 'A postcard is waiting on the map!';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '$id $name is open!';
  }

  @override
  String get levelResultReachFinish => 'Reach the finish to earn stars.';

  @override
  String get course_classic_title => 'Classic';

  @override
  String get course_starTrail_title => 'Endless';

  @override
  String get course_classic_instructions =>
      'Find the gaps. Follow the aiming marks for a perfect pass.';

  @override
  String get course_starTrail_instructions =>
      'Collect all 3 stars in a group for +5. Chain stars for up to 3×. Stars restore your shield; perfect gates earn a star magnet. Upgrade both with stars!';

  @override
  String get course_classic_scoreLabel => 'OBSTACLES';

  @override
  String get course_starTrail_scoreLabel => 'STAR POINTS';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gates',
    );
    return '$_temp0';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'star points',
    );
    return '$_temp0';
  }

  @override
  String get course_classic_previewSemantics =>
      'Classic: fly through the gaps.';

  @override
  String get course_starTrail_previewSemantics =>
      'Endless: collect stars with three hearts and a shield.';

  @override
  String get obstacle_garden_name => 'Garden gate';

  @override
  String get obstacle_windLift_name => 'Wind lift';

  @override
  String get obstacle_petalGate_name => 'Petal shutters';

  @override
  String get obstacle_switchback_name => 'Switchback';

  @override
  String get obstacle_lanternDrift_name => 'Lantern drift';

  @override
  String get obstacle_sunWheels_name => 'Sun wheels';

  @override
  String get obstacle_crystalSteps_name => 'Crystal steps';

  @override
  String get rush_wildfire_name => 'Wildfire';

  @override
  String get rush_wildfire_escape => 'Outran the wildfire';

  @override
  String get rush_skyfall_name => 'Skyfall';

  @override
  String get rush_skyfall_escape => 'Survived the skyfall';

  @override
  String get rush_eruption_name => 'Eruption';

  @override
  String get rush_eruption_escape => 'Beat the eruption';

  @override
  String get rush_swarm_name => 'Swarm';

  @override
  String get rush_swarm_escape => 'Plowed through the swarm';

  @override
  String get boss_baronBat_title => 'LORD OF THE STORM';

  @override
  String get boss_spitterBeetle_title => 'BREWER OF THE SWARM';

  @override
  String get boss_duskMoth_title => 'KEEPER OF THE TWILIGHT VEIL';

  @override
  String get boss_pirate_title => 'TERROR OF THE HIGH TIDE';

  @override
  String get boss_dragon_title => 'SOVEREIGN OF THE BURNING SKY';

  @override
  String get boss_kingCoo_title => 'COMMISSIONER OF THE CURB';

  @override
  String get boss_searchlightGargoyle_title => 'WATCHMAN OF THE TALLEST TOWER';

  @override
  String get boss_neferhoo_title => 'KEEPER OF THE LOST LETTER';

  @override
  String get boss_baronBat_returnTitle => 'THE STORM RETURNS';

  @override
  String get boss_baronBat_barName => 'BARON BAT';

  @override
  String get boss_spitterBeetle_barName => 'SPITTER KING';

  @override
  String get boss_duskMoth_barName => 'DUSK EMPRESS';

  @override
  String get boss_pirate_barName => 'PIRATE CAPTAIN';

  @override
  String get boss_dragon_barName => 'EMBER DRAGON';

  @override
  String get boss_kingCoo_barName => 'KING COO';

  @override
  String get boss_searchlightGargoyle_barName => 'GARGOYLE';

  @override
  String get boss_neferhoo_barName => 'NEFERHOO';

  @override
  String get vanguard_baronBat_title => 'BARON BAT\'S BATS';

  @override
  String get vanguard_baronBat_call =>
      'Here they come! The Baron is right behind.';

  @override
  String get vanguard_spitterBeetle_title => 'THE SPITTER KING\'S BROOD';

  @override
  String get vanguard_spitterBeetle_call =>
      'Here they come! The Spitter King is right behind.';

  @override
  String get vanguard_duskMoth_title => 'THE DUSK EMPRESS\'S MOTHS';

  @override
  String get vanguard_duskMoth_call =>
      'Here they come! The Empress is right behind.';

  @override
  String get vanguard_kingCoo_title => 'KING COO\'S SQUADRON';

  @override
  String get vanguard_kingCoo_call =>
      'Here they come! King Coo is right behind.';

  @override
  String get vanguard_kingCoo_callCrusts => 'Here they come! Duck the crusts!';

  @override
  String get vanguard_kingCoo_callReturns =>
      'Duck the crusts! Miss one and it comes back!';

  @override
  String get bossVanguardClear => 'CLEAR!';

  @override
  String get bossVanguardLeft => 'LEFT';

  @override
  String get bossStragglersCaught => 'ALL CAUGHT!';

  @override
  String get bossHint_strongerBaronBat =>
      'STRONGER · Triple shots, and his bats join in!';

  @override
  String get bossHint_strongerSpitterBeetle =>
      'STRONGER · Full fans, and his beetles join in!';

  @override
  String get bossHint_strongerDuskMoth =>
      'STRONGER · Seven-shot fans, and her moths join in!';

  @override
  String get bossHint_strongerPirate => 'STRONGER · The tide is turning!';

  @override
  String get bossHint_strongerDragon =>
      'STRONGER · Watch for the breath and the flocks!';

  @override
  String get bossHint_strongerKingCoo =>
      'STRONGER · He whistles for his squadron!';

  @override
  String get bossHint_strongerGargoyleFierce =>
      'STRONGER · Feathers fall on the open lamp!';

  @override
  String get bossHint_strongerGargoyle => 'STRONGER · Stone feathers fall!';

  @override
  String get bossHint_strongerNeferhooTougher =>
      'STRONGER · The ankh, and his mummy bats!';

  @override
  String get bossHint_strongerNeferhoo =>
      'STRONGER · The golden ankh comes back!';

  @override
  String get bossHint_tideRising => 'TIDE RISING · Fly high!';

  @override
  String get bossHint_highTide => 'HIGH TIDE · Stay above the water';

  @override
  String get bossHint_tideFury => 'FURY · Broadsides between the surges';

  @override
  String get bossHint_tideCalm =>
      'Dodge the cannonballs · Keep out of the water';

  @override
  String get bossHint_dragonSwarm =>
      'SWARM · Dodge the bats or sprint through them';

  @override
  String get bossHint_dragonFuryDebut => 'FURY · Faster fireballs';

  @override
  String get bossHint_dragonFury => 'FURY · Fireballs burst into embers';

  @override
  String get bossHint_dragonCalm =>
      'Dodge the fireballs · Watch for the breath';

  @override
  String get bossHint_screechFury => 'FURY · Faster fireballs, more bats';

  @override
  String get bossHint_screechCalm =>
      'Dodge the fireballs and bats · Watch for the screech';

  @override
  String get bossHint_cooPopped => 'POP! · No squadron';

  @override
  String get bossHint_cooSquadron => 'SQUADRON · Follow the open lane!';

  @override
  String get bossHint_cooPuffed => 'PUFFED · Shoot his chest (x2)!';

  @override
  String get bossHint_cooCrumbBomb => 'CRUMB BOMB · Leave the ring!';

  @override
  String get bossHint_cooFury => 'FURY · Stay between the rings';

  @override
  String get bossHint_cooCalm =>
      'Dodge the crumb bombs · Shoot his chest when it puffs';

  @override
  String get bossHint_beamOn => 'BEAM · Stay in the dark';

  @override
  String get bossHint_beamFury => 'FURY · Slip between the beams';

  @override
  String get bossHint_beamIncomingHigh => 'BEAM INCOMING · Fly low!';

  @override
  String get bossHint_beamIncomingLow => 'BEAM INCOMING · Fly high!';

  @override
  String get bossHint_lampOpen => 'LAMP OPEN · Shoot the lamp!';

  @override
  String get bossHint_shuttersClosed => 'SHUTTERS CLOSED · Save your shots';

  @override
  String get bossHint_mothFuryNoVeil => 'FURY · Seven-shot fans. No veil yet!';

  @override
  String get bossHint_mothNoVeil => 'No veil yet · Fire between the fans!';

  @override
  String get bossHint_mothShielded => 'SHIELDED · Dodge until the veil drops';

  @override
  String get bossHint_mothShieldForming =>
      'SHIELD FORMING · Get ready to dodge';

  @override
  String get bossHint_mothFury => 'FURY · Seven-shot fans. Veil is down!';

  @override
  String get bossHint_mothCalm => 'Veil is down · Fire between the fans!';

  @override
  String get bossHint_neferhooMailCall => 'MAIL CALL · Shoot them back!';

  @override
  String get bossHint_neferhooReturn => 'RETURN TO SENDER! · −25';

  @override
  String get bossHint_neferhooReturnFaster => 'RETURN TO SENDER! · −18';

  @override
  String get bossHint_neferhooAnkh => 'THE ANKH · It comes back!';

  @override
  String get bossHint_neferhooExpress => 'EXPRESS POST · Five letters, faster';

  @override
  String get bossHint_neferhooTwoAnkhs => 'TWO ANKHS · Keep off both lanes';

  @override
  String get bossHint_neferhooBats => 'MUMMY BATS · Shoot them down!';

  @override
  String get bossHint_neferhooScuff =>
      'Rocks only scuff his wraps. Shoot his LETTERS back!';

  @override
  String get bossHint_neferhooWarmUp =>
      'Shoot his letters back · Return to sender';

  @override
  String get bossHint_neferhooCalm =>
      'Shoot his letters back · Dodge the golden ankh';

  @override
  String get bossHint_neferhooFury => 'FURY · Express post and two ankhs';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'DRAGON\'S BREATH · Fly low! Its heart is open',
      'middle': 'DRAGON\'S BREATH · Climb or dive! Its heart is open',
      'other': 'DRAGON\'S BREATH · Fly high! Its heart is open',
    });
    return '$_temp0';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'FIRE · Fly low! Strike the glowing heart',
      'middle': 'FIRE · Climb or dive! Strike the glowing heart',
      'other': 'FIRE · Fly high! Strike the glowing heart',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'SONIC SCREECH · Fly to the high gap!',
      'middle': 'SONIC SCREECH · Fly to the middle gap!',
      'other': 'SONIC SCREECH · Fly to the low gap!',
    });
    return '$_temp0';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'SCREECH · Hold the high gap',
      'middle': 'SCREECH · Hold the middle gap',
      'other': 'SCREECH · Hold the low gap',
    });
    return '$_temp0';
  }

  @override
  String get encounterCaption_duskMoth =>
      'DODGE THE FANS  ·  FIRE WHEN THE VEIL DROPS';

  @override
  String get encounterCaption_pirate =>
      'DODGE THE CANNON  ·  STAY OUT OF THE WATER';

  @override
  String get encounterCaption_dragon =>
      'DODGE THE FIREBALLS  ·  ESCAPE THE BREATH';

  @override
  String get encounterCaption_kingCoo =>
      'LEAVE THE RINGS  ·  SHOOT HIS CHEST WHEN IT PUFFS';

  @override
  String get encounterCaption_searchlightGargoyle =>
      'STAY OUT OF THE LIGHT  ·  SHOOT THE LAMP WHEN IT OPENS';

  @override
  String get encounterCaption_neferhoo =>
      'GET READY  ·  SHOOT HIS LETTERS BACK';

  @override
  String get encounterCaption_screech => 'WHEN HE SCREECHES  ·  FLY TO THE GAP';

  @override
  String get encounterCaption_default => 'GET READY  ·  FLAP, DODGE, FIRE';

  @override
  String get encounterCoasting => 'Your bird is coasting safely';

  @override
  String get encounterOpenSky => 'Back to the open sky';

  @override
  String get encounterOmenTitle_duskMoth => 'TWILIGHT TAKES WING';

  @override
  String get encounterOmenLine_duskMoth => 'A silken veil gathers in the dusk…';

  @override
  String get encounterOmenTitle_spitterBeetle => 'SOMETHING IS BREWING';

  @override
  String get encounterOmenLine_spitterBeetle => 'The air is starting to fizz…';

  @override
  String get encounterOmenTitle_dragon => 'THE SKY CATCHES FIRE';

  @override
  String get encounterOmenLine_dragon => 'Great wings beat above the clouds…';

  @override
  String get encounterOmenTitle_kingCoo => 'THE CURB IS CLOSED';

  @override
  String get encounterOmenLine_kingCoo =>
      'Somebody is very cross about the bread cart…';

  @override
  String get encounterOmenTitle_searchlightGargoyle => 'STORM WARNING';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      'Something on the ledge is watching…';

  @override
  String get encounterOmenTitle_neferhoo => 'THE PYRAMID STIRS';

  @override
  String get encounterOmenLine_neferhoo => 'The pyramid’s dust is stirring…';

  @override
  String get encounterOmenTitle_baronReturns => 'THE BARON RETURNS';

  @override
  String get encounterOmenLine_baronReturns =>
      'He is back, and he is much louder…';

  @override
  String get encounterOmenTitle_default => 'A SHADOW APPROACHES';

  @override
  String get encounterOmenLine_default => 'The sky belongs to someone else…';

  @override
  String get encounterOmenTitle_pirate => 'SAIL HO!';

  @override
  String get encounterOmenLine_pirate => 'A ship rides in on the rising tide…';

  @override
  String get bossGuardianEyebrow => 'GUARDIAN';

  @override
  String bossEncounterEyebrow(String number) {
    return 'ENCOUNTER $number';
  }

  @override
  String get bossGuardianDown => 'GUARDIAN DOWN!';

  @override
  String get bossSkyReclaimed => 'SKY RECLAIMED';

  @override
  String bossVictoryPoints(int points) {
    return '+$points POINTS   ·   SHIELD RESTORED';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'BARON BAT DEFEATED',
      'spitterBeetle': 'SPITTER KING DEFEATED',
      'duskMoth': 'DUSK EMPRESS DEFEATED',
      'pirate': 'PIRATE CAPTAIN DEFEATED',
      'dragon': 'EMBER DRAGON DEFEATED',
      'kingCoo': 'KING COO DEFEATED',
      'searchlightGargoyle': 'SEARCHLIGHT GARGOYLE DEFEATED',
      'other': 'NEFERHOO DEFEATED',
    });
    return '$_temp0';
  }

  @override
  String bossQuotedLine(String line) {
    return '“$line”';
  }

  @override
  String get bossPirateRoar => 'ARRR!';

  @override
  String get bossGargoyleCardSmall => 'THE SEARCHLIGHT';

  @override
  String get bossGargoyleCardBig => 'GARGOYLE';

  @override
  String get bossGargoyleCardOrder => 'small-big';

  @override
  String get bossDodgeFlyLow => 'FLY LOW';

  @override
  String get bossDodgeFlyHigh => 'FLY HIGH';

  @override
  String get bossDodgeClimbOrDive => 'CLIMB OR DIVE';

  @override
  String get bossDodgeSlipBetween => 'SLIP BETWEEN\nTHE BEAMS';

  @override
  String get bossSpotted => 'SPOTTED!';

  @override
  String get bossShieldLost => 'SHIELD LOST';

  @override
  String get bossHeartLost => '-1 HEART';

  @override
  String get bossGargoyleLampOpen => 'LAMP OPEN';

  @override
  String get bossGargoyleShoot => 'SHOOT!';

  @override
  String get bossScreechFlyToGap => 'FLY TO THE GAP';

  @override
  String get bossScreechHoldGap => 'HOLD THE GAP';

  @override
  String get bossPirateHighTide => 'HIGH TIDE';

  @override
  String get bossBarDefeated => 'DEFEATED';

  @override
  String get bossBarIncoming => 'INCOMING';

  @override
  String get bossBarFury => 'FURY';

  @override
  String get bossBarHeartDouble => 'HEART ×2';

  @override
  String get bossStronger => 'STRONGER!';

  @override
  String get bossKingCooPuffed => 'PUFFED';

  @override
  String get bossKingCooShout => 'COO!';

  @override
  String get bossKingCooPop => 'POP!';

  @override
  String get bossKingCooPoof => 'POOF!';

  @override
  String get bossSquadOpenLane => 'OPEN LANE = GO';

  @override
  String get bossSquadUseGap => 'USE THE GAP';

  @override
  String get bossSquadThenV => 'THEN: V';

  @override
  String get bossSquadThenGap => 'THEN: GAP';

  @override
  String get bossSquadCancelled => 'SQUAD CANCELLED';

  @override
  String get bossNeferhooFound => 'THE LOST LETTER IS FOUND';

  @override
  String get bossNeferhooHoo => 'HOO';

  @override
  String get bossNeferhooPoo => 'POO';

  @override
  String get bossNeferhooMailCall => 'MAIL CALL';

  @override
  String get bossNeferhooExpressPost => 'EXPRESS POST';

  @override
  String get bossNeferhooShootBack => 'Shoot them back!';

  @override
  String get bossNeferhooAnkh => 'THE ANKH';

  @override
  String get bossNeferhooTwoAnkhs => 'TWO ANKHS';

  @override
  String get bossNeferhooComesBack => 'It comes back!';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'WILDFIRE!',
      'skyfall': 'SKYFALL!',
      'eruption': 'ERUPTION!',
      'other': 'SWARM!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Grab the sprint rings and outrun it!',
      'skyfall': 'Grab the sprint rings and race the meteors!',
      'eruption': 'Grab the sprint rings and beat the blasts!',
      'other': 'Grab the sprint rings and plow through!',
    });
    return '$_temp0';
  }

  @override
  String encounterRushEscaped(int points) {
    return 'ESCAPED! +$points';
  }

  @override
  String encounterFlawless(int points) {
    return 'FLAWLESS! +$points';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'You outran the wildfire',
      'skyfall': 'You survived the skyfall',
      'eruption': 'You beat the eruption',
      'other': 'You plowed through the swarm',
    });
    return '$_temp0';
  }

  @override
  String get encounterGale => 'GALE!';

  @override
  String encounterGaleDetail(String mark) {
    return 'Dodge the debris where the $mark flashes!';
  }

  @override
  String encounterGaleWeathered(int points) {
    return 'WEATHERED! +$points';
  }

  @override
  String get encounterGaleWeatheredDetail => 'You rode out the gale';

  @override
  String get encounterAllRings => 'ALL RINGS!';

  @override
  String encounterAllRingsDetail(String seconds) {
    return 'Turbo boost +${seconds}s';
  }

  @override
  String get encounterFinish => 'FINISH';

  @override
  String get builderMode_pushUp => 'Push-ups';

  @override
  String get builderMode_squat => 'Squats';

  @override
  String get builderMode_jump => 'Jumps';

  @override
  String builderSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count push-ups',
      one: '1 push-up',
    );
    return '$_temp0';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count squats',
      one: '1 squat',
    );
    return '$_temp0';
  }

  @override
  String get builderNewLevel_touch => 'My tap level';

  @override
  String get builderNewLevel_pushUp => 'My push-up level';

  @override
  String get builderNewLevel_squat => 'My squat level';

  @override
  String get builderNewLevel_jump => 'My jump level';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '$name $number';
  }

  @override
  String get builderFallbackName => 'My level';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return 'Fly my Beakbound level “$name” ($mode): $code';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '$earned of $total stars';
  }

  @override
  String get builderBackSemantics => 'Back';

  @override
  String get builderKeepIt => 'Keep it';

  @override
  String builderLessSemantics(String name) {
    return 'Less $name';
  }

  @override
  String builderMoreSemantics(String name) {
    return 'More $name';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '$name $value';
  }

  @override
  String get builderDuplicateSemantics => 'Duplicate';

  @override
  String get builderCopy => 'Copy';

  @override
  String get builderDeleteSemantics => 'Delete';

  @override
  String get builderDelete => 'Delete';

  @override
  String get builderMoreBelow => 'More below';

  @override
  String builderStepSemantics(String caption, String value) {
    return '$caption $value';
  }

  @override
  String builderStepHintSemantics(String caption, String value, String hint) {
    return '$caption $value, $hint';
  }

  @override
  String builderPercent(int percent) {
    return '$percent %';
  }

  @override
  String get builderLane => 'Lane';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'top or bottom of the squat',
      'other': 'top or bottom of the push-up',
    });
    return '$_temp0';
  }

  @override
  String get builderLaneTop => 'Top';

  @override
  String get builderLaneBottom => 'Bottom';

  @override
  String get builderHeight => 'Height';

  @override
  String get builderHeightHint => 'of the sky';

  @override
  String get builderLowerSemantics => 'Lower';

  @override
  String get builderHigherSemantics => 'Higher';

  @override
  String get builderOpening => 'Opening';

  @override
  String builderOpeningHint(int percent) {
    return 'at least $percent %';
  }

  @override
  String get builderNarrowerSemantics => 'Narrower';

  @override
  String get builderWiderSemantics => 'Wider';

  @override
  String get builderMotion => 'Motion';

  @override
  String get builderMotionGardenHint => 'garden gates stand still';

  @override
  String get builderMotionStill => 'Still';

  @override
  String get builderMotionGentle => 'Gentle';

  @override
  String get builderMotionLively => 'Lively';

  @override
  String get builderMotionGardenToast =>
      'Garden gates stand still: pick another family to make it move.';

  @override
  String get builderSway => 'Sway';

  @override
  String builderSwayHint(String seconds) {
    return 'one sway: $seconds';
  }

  @override
  String get builderSwayFast => 'Fast';

  @override
  String get builderSwayMedium => 'Medium';

  @override
  String get builderSwaySlow => 'Slow';

  @override
  String get builderPhase => 'As you arrive';

  @override
  String builderPhaseValue(int position, int count) {
    return '$position of $count';
  }

  @override
  String get builderPhaseHint => 'where it is in its sway';

  @override
  String get builderPhaseEarlierSemantics => 'Earlier in its sway';

  @override
  String get builderPhaseLaterSemantics => 'Later in its sway';

  @override
  String get builderLook => 'Look';

  @override
  String builderLookSemantics(int number) {
    return 'Look $number';
  }

  @override
  String get builderDoor => 'Stone door';

  @override
  String get builderDoorHint => 'shoot it open';

  @override
  String get builderDoorNone => 'No door';

  @override
  String get builderDoorNeedsShootToast =>
      'Turn Shoot on in the level’s settings to use doors.';

  @override
  String get builderPlace => 'Place';

  @override
  String get builderPlaceHint => 'from the start';

  @override
  String get builderEarlierSemantics => 'Earlier';

  @override
  String get builderLaterSemantics => 'Later';

  @override
  String builderFamilySemantics(String family) {
    return 'Gate family: $family. Change';
  }

  @override
  String get builderChangeFamily => 'Change family';

  @override
  String get builderItemStar => 'Star';

  @override
  String get builderItemTrio => 'Star trio';

  @override
  String get builderItemHeart => 'Heart';

  @override
  String get builderItemEnemy => 'Enemy';

  @override
  String get builderItemGate => 'Gate';

  @override
  String get builderItemStarDetail => 'One star to collect';

  @override
  String get builderItemTrioDetail => 'All three pay a bonus';

  @override
  String get builderItemHeartDetail => 'One heart back';

  @override
  String get builderEnemyKind => 'Kind';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'The bird flies the top and bottom of each squat: put pickups on or between the yellow lines.',
      'other':
          'The bird flies the top and bottom of each push-up: put pickups on or between the yellow lines.',
    });
    return '$_temp0';
  }

  @override
  String get builderEnemy_simpleBat => 'Purple bat';

  @override
  String get builderEnemy_caveBat => 'Cave bat';

  @override
  String get builderEnemy_spitterBeetle => 'Spitter beetle';

  @override
  String get builderEnemy_duskMoth => 'Dusk moth';

  @override
  String get builderEnemy_alleyPigeon => 'Alley pigeon';

  @override
  String get builderEnemy_mummyBat => 'Mummy bat';

  @override
  String get builderSummaryTitle => 'This level';

  @override
  String builderModeRegion(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderFactLength => 'Length';

  @override
  String get builderFactStars => 'Stars';

  @override
  String get builderFactMarks => 'Marks';

  @override
  String get builderFactWorkout => 'Workout';

  @override
  String get builderFactPace => 'Pace';

  @override
  String get builderFactBoss => 'Boss';

  @override
  String get builderPace_relaxed => 'Relaxed';

  @override
  String get builderPace_steady => 'Steady';

  @override
  String get builderPace_brisk => 'Brisk';

  @override
  String get builderSummaryStarterNote =>
      'A starter level to fly as it is, or remix into a level of your own.';

  @override
  String get builderSummaryClearedNote =>
      'Cleared by you: you flew it to the end.';

  @override
  String get builderSummaryClearNote =>
      'Test fly it all the way to the finish to mark it cleared.';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'other': 'Test fly it, beat $boss and cross the line to mark it cleared.',
    });
    return '$_temp0';
  }

  @override
  String get builderSummaryHowTo =>
      'Pick a tool on the left, then tap the sky. Tap a thing to change it; drag it to move it.';

  @override
  String get builderFamily_garden_detail =>
      'Stands still. Can hold a stone door.';

  @override
  String get builderFamily_windLift_detail => 'The opening rises and falls.';

  @override
  String get builderFamily_petalGate_detail =>
      'The opening narrows and widens.';

  @override
  String get builderFamily_switchback_detail =>
      'Two openings that slide apart.';

  @override
  String get builderFamily_lanternDrift_detail => 'Hanging lanterns that bob.';

  @override
  String get builderFamily_sunWheels_detail => 'Wheels that close in and back.';

  @override
  String get builderFamily_crystalSteps_detail => 'Three steps in a ripple.';

  @override
  String get builderFamiliesCloseSemantics => 'Close gate families';

  @override
  String get builderFamiliesTitle => 'Gate family';

  @override
  String get builderFamiliesSubtitle => 'How the gate looks and moves.';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '$family. $detail';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Give the level a name of up to $count letters.',
    );
    return '$_temp0';
  }

  @override
  String get reach_tooShort =>
      'Move the finish line further on: the level is too short.';

  @override
  String get reach_tooLong =>
      'Bring the finish line closer: the level is too long.';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Too many things: a level holds up to $count.',
    );
    return '$_temp0';
  }

  @override
  String get reach_bossNeedsTap => 'Only Tap & Fly levels end with a boss.';

  @override
  String get reach_noGates => 'Add gates for the bird to fly through.';

  @override
  String get reach_startZone =>
      'Too close to the start: move it past the start zone.';

  @override
  String get reach_finishRoom =>
      'Leave room before the finish line after this gate.';

  @override
  String get reach_overlap => 'Two gates overlap: move them apart.';

  @override
  String get reach_gateHeight => 'This gate is too high or too low.';

  @override
  String get reach_gateMotion => 'This gate cannot move that way.';

  @override
  String get reach_gateLook => 'This gate has an unknown look.';

  @override
  String get reach_gateNarrow => 'Open this gate wider: the bird cannot fit.';

  @override
  String get reach_gateWide => 'This gate is open too wide.';

  @override
  String get reach_doorNeedsShoot =>
      'A stone door needs Tap & Fly with Shoot on.';

  @override
  String get reach_doorNeedsGarden =>
      'Only a garden gate can hold a stone door.';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Tight switch: a steady squat may not make it in time.',
      'other': 'Tight switch: a steady push-up may not make it in time.',
    });
    return '$_temp0';
  }

  @override
  String get reach_steepClimb =>
      'Steep climb: leave more room to jump up to this gate.';

  @override
  String get reach_enemyNeedsTap => 'Enemies only fly in Tap & Fly levels.';

  @override
  String get reach_outsideSky => 'Keep it inside the sky.';

  @override
  String get reach_pastFinish => 'Place it before the finish line.';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Out of a squat\'s reach: move it nearer the lanes.',
      'other': 'Out of a push-up\'s reach: move it nearer the lanes.',
    });
    return '$_temp0';
  }

  @override
  String get reach_inWall => 'Inside a wall: move it into the opening.';

  @override
  String get reach_noStars => 'Place at least one star.';

  @override
  String get reach_marks =>
      'The star marks ask for more stars than the level has.';

  @override
  String reach_cannotFly(String problem) {
    return 'This level cannot fly yet ($problem).';
  }

  @override
  String get builderSaveFailedFlyToast =>
      'The level didn’t save, so it can’t fly yet. Tap its name to retry.';

  @override
  String get builderShareBlockedToast =>
      'Fix the red flags first: then the level can be shared.';

  @override
  String get builderEditorBackSemantics => 'Back to the builder';

  @override
  String get builderSettingsSemantics => 'Level settings';

  @override
  String get builderFly => 'FLY';

  @override
  String get builderTestFly => 'TEST FLY';

  @override
  String get builderFlySemantics => 'Fly this level';

  @override
  String get builderTestFlySemantics => 'Test fly the whole level';

  @override
  String get builderUndoSemantics => 'Undo';

  @override
  String get builderRedoSemantics => 'Redo';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice tips',
    );
    return '$blocking to fix, $_temp0';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice tips',
    );
    return '$_temp0';
  }

  @override
  String get builderReadySemantics => 'Ready to fly';

  @override
  String get builderShareSemantics => 'Share code';

  @override
  String get builderFromHereSemantics => 'Test fly from here';

  @override
  String get builderFromHere => 'From here';

  @override
  String get builderStatusStarter => 'Starter level · look, fly or remix';

  @override
  String get builderStatusSaveFailed => 'Couldn’t save · tap to retry';

  @override
  String get builderStatusSaving => 'Saving…';

  @override
  String get builderStatusSaved => 'All changes saved';

  @override
  String builderNamePlateSemantics(String name, String mode, String status) {
    return '$name. $mode. $status.';
  }

  @override
  String builderNamePlateRenameSemantics(
    String name,
    String mode,
    String status,
  ) {
    return '$name. $mode. $status. Tap to rename.';
  }

  @override
  String get builderStarterBanner => 'Remix it to make it yours';

  @override
  String get builderRemix => 'Remix';

  @override
  String get builderRemixSemantics => 'Remix';

  @override
  String get builderIssuesCloseSemantics => 'Close problems and tips';

  @override
  String get builderIssuesReadyTitle => 'Ready to fly!';

  @override
  String get builderIssuesFixTitle => 'To fix before it flies';

  @override
  String get builderIssuesTipsTitle => 'Ready, with a few tips';

  @override
  String get builderIssuesReadyDetail =>
      'Nothing to fix. Test fly it to the finish to clear it.';

  @override
  String get builderIssuesDetail => 'Tap one to go to its place on the route.';

  @override
  String get builderSettingsCloseSemantics => 'Close settings';

  @override
  String get builderSettingsTitle => 'Level settings';

  @override
  String builderSettingsSubtitle(String mode) {
    return '$mode · changes save as you make them';
  }

  @override
  String get builderSettingsName => 'Name';

  @override
  String get builderRename => 'Rename';

  @override
  String get builderRenameSemantics => 'Rename';

  @override
  String get builderSettingsRegion => 'Region';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places · swipe for more',
    );
    return '$_temp0';
  }

  @override
  String get builderSettingsPace => 'Pace';

  @override
  String get builderSettingsPaceHint => 'how fast the sky scrolls';

  @override
  String get builderSettingsMarks => 'Star marks';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars placed',
      one: '1 star placed',
    );
    return '$_temp0';
  }

  @override
  String get builderMarkTwoSemantics => 'two-star mark';

  @override
  String get builderMarkThreeSemantics => 'three-star mark';

  @override
  String get builderMarksAuto => 'Auto: follow the stars';

  @override
  String get builderMarksByHand => 'Set by hand';

  @override
  String get builderSettingsControls => 'Controls';

  @override
  String get builderShootOn => 'Shoot on';

  @override
  String get builderShootOff => 'Shoot off';

  @override
  String get builderSprintOn => 'Sprint on';

  @override
  String get builderSprintOff => 'Sprint off';

  @override
  String get builderSettingsBoss => 'Boss finale';

  @override
  String get builderSettingsBossHint => 'waits at the end';

  @override
  String get builderNoBossSemantics => 'No boss: a finish line';

  @override
  String get builderNoBoss => 'None';

  @override
  String get builderBossShort_baronBat => 'Baron';

  @override
  String get builderBossShort_spitterBeetle => 'Spitter';

  @override
  String get builderBossShort_duskMoth => 'Empress';

  @override
  String get builderBossShort_pirate => 'Pirate';

  @override
  String get builderBossShort_dragon => 'Dragon';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'The bird flies two lanes: the top and the bottom of each squat. A slower player meets the same level at a gentler speed. No shooting, sprinting or bosses here.',
      'other':
          'The bird flies two lanes: the top and the bottom of each push-up. A slower player meets the same level at a gentler speed. No shooting, sprinting or bosses here.',
    });
    return '$_temp0';
  }

  @override
  String get builderSettingsJumpNote =>
      'Each jump lifts the bird; it glides in between. No shooting, sprinting or bosses here.';

  @override
  String get builderStartZoneToast =>
      'Keep the start zone clear: place things right of the dashed line.';

  @override
  String get builderSkySemantics =>
      'Level sky. Tap to place, drag to move or to scroll.';

  @override
  String get builderSkyReadOnlySemantics =>
      'Level sky. Tap something to look at it.';

  @override
  String get builderCoachTitle => 'Build your level';

  @override
  String get builderCoachPickTool => 'Pick a tool on the left';

  @override
  String get builderCoachTapSky => 'Tap the sky to place it';

  @override
  String get builderCoachTestFly => 'Test fly it!';

  @override
  String get builderCoachDrag =>
      'Drag a thing to move it · drag the sky to scroll';

  @override
  String get builderTipDrag => 'Drag it to move it · drag the sky to scroll';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'TOP OF THE SQUAT',
      'other': 'TOP OF THE PUSH-UP',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasTop => 'TOP';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'BOTTOM OF THE SQUAT',
      'other': 'BOTTOM OF THE PUSH-UP',
    });
    return '$_temp0';
  }

  @override
  String get builderCanvasBottom => 'BOTTOM';

  @override
  String get builderCanvasStartZoneFull => 'START ZONE · KEEP CLEAR';

  @override
  String get builderCanvasStartZone => 'START ZONE';

  @override
  String get builderCanvasFinishHere => 'FINISH HERE';

  @override
  String get builderTool_select => 'Select';

  @override
  String get builderToolHint_select =>
      'Select: tap something to change it, drag to move it';

  @override
  String get builderTool_gate => 'Gate';

  @override
  String get builderToolHint_gate => 'Gate: tap the sky to place a gate';

  @override
  String get builderTool_star => 'Star';

  @override
  String get builderToolHint_star => 'Star: tap the sky to place a star';

  @override
  String get builderTool_trio => 'Trio';

  @override
  String get builderToolHint_trio =>
      'Star trio: tap the sky to place three stars';

  @override
  String get builderTool_heart => 'Heart';

  @override
  String get builderToolHint_heart => 'Heart: tap the sky to place a heart';

  @override
  String get builderTool_enemy => 'Enemy';

  @override
  String get builderToolHint_enemy => 'Enemy: tap the sky to place an enemy';

  @override
  String get builderTool_finish => 'Finish';

  @override
  String get builderToolHint_finish =>
      'Finish: tap the sky to move the finish line';

  @override
  String get builderTool_boss => 'Boss';

  @override
  String get builderToolHint_boss =>
      'Boss mark: tap the sky to move where the boss waits';

  @override
  String get builderStarterToolsToast =>
      'Starter levels stay as they are: remix it to change it.';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Route overview. $length to the boss. Drag to move along the route.',
      'other':
          'Route overview. $length to the finish. Drag to move along the route.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Route overview. $length to the boss. $reps. Drag to move along the route.',
      'other':
          'Route overview. $length to the finish. $reps. Drag to move along the route.',
    });
    return '$_temp0';
  }

  @override
  String builderRouteToBoss(String length) {
    return '$length to the boss';
  }

  @override
  String get builtResultTestFlight => 'TEST FLIGHT';

  @override
  String get builtResultCleared => 'Cleared!';

  @override
  String get builtResultBonk => 'Bonk!';

  @override
  String get builtResultLanded => 'Landed';

  @override
  String get builtResultTestTab => 'TEST';

  @override
  String get builtResultGoalFinish => 'Finish';

  @override
  String get builtResultGoalBoss => 'Boss';

  @override
  String builtResultGoalSemantics(String goal) {
    return '$goal.';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '$goal. Done.';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Collect $count stars.',
    );
    return '$_temp0';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Collect $count stars. Done.',
    );
    return '$_temp0';
  }

  @override
  String get builtResultDone => 'Done';

  @override
  String get builtResultNotYet => 'Not yet';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to go',
    );
    return '$_temp0';
  }

  @override
  String get builtResultFinishFirst => 'Finish first';

  @override
  String get builtResultClearedByYou => 'CLEARED BY YOU';

  @override
  String get builtResultNewBest => 'NEW BEST!';

  @override
  String get builtResultPractice => 'Practice';

  @override
  String builtResultBest(int count) {
    return 'Best $count';
  }

  @override
  String get builtResultFirstClear => 'First clear!';

  @override
  String get builtResultStarsCollected => 'STARS COLLECTED';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of 3 level stars',
    );
    return '$_temp0';
  }

  @override
  String get builtResultAsksFor => 'ASKS FOR';

  @override
  String get builtResultWorkout => 'WORKOUT';

  @override
  String get builtResultGotTo => 'GOT TO';

  @override
  String get builtResultScore => 'SCORE';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'push-ups',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squats',
    );
    return '$_temp0';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jumps',
    );
    return '$_temp0';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'push-ups on camera',
    );
    return '$_temp0';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squats on camera',
    );
    return '$_temp0';
  }

  @override
  String builtResultOfLength(String length) {
    return 'of $length';
  }

  @override
  String get builtResultNotKept => 'Not kept';

  @override
  String get builtResultNoBest => 'No best yet';

  @override
  String get builtResultClearedStrip => 'Cleared by you · ready to share!';

  @override
  String builtResultFlownFrom(String from) {
    return 'Flown from $from. Fly it all to clear it.';
  }

  @override
  String get builtResultTestNothingSaved => 'Test flight · nothing is saved';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return 'Test flight · got to $reached of $length';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return 'Got to $reached of $length. Reach the finish for stars.';
  }

  @override
  String get builtResultReachFinish => 'Reach the finish to earn stars.';

  @override
  String get builtResultSaved => 'Saved on this phone';

  @override
  String get builtResultSaving => 'Saving your flight…';

  @override
  String get builtResultBuilder => 'Builder';

  @override
  String get builtResultEditLevel => 'Edit level';

  @override
  String get builtResultEdit => 'Edit';

  @override
  String get builtResultFlyAgain => 'Fly again';

  @override
  String get builtResultWatchReplay => 'Watch replay';

  @override
  String get builtResultPreparing => 'Preparing…';

  @override
  String get builtResultSessionSaving => 'Saving…';

  @override
  String get builtResultSaveSession => 'Save session';

  @override
  String get builderShelfTitle => 'Level Builder';

  @override
  String get builderShelfPasteCode => 'Paste code';

  @override
  String get builderShelfNewLevel => 'New level';

  @override
  String get builderShelfSaveFailed => 'That didn’t save. Please try again.';

  @override
  String builderShelfDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get builderShelfDeleteBody =>
      'Its bests go with it. Push-ups, squats and jumps you flew on it still count.';

  @override
  String get builderShelfDelete => 'Delete';

  @override
  String builderShelfDeleted(String name) {
    return 'Deleted “$name”.';
  }

  @override
  String get builderShelfFixFirst =>
      'Fix what’s marked in red before sharing: tap Fix it.';

  @override
  String get builderShelfCodeCopied => 'Code copied! Paste it to a friend.';

  @override
  String get builderShelfCodeCopiedUncleared =>
      'Code copied! Fly it to the finish too, so friends know it can be done.';

  @override
  String get builderShelfNotReady =>
      'This level isn’t ready to fly yet: tap Fix it.';

  @override
  String get builderShelfPasteMissingTitle => 'No level code to paste';

  @override
  String get builderShelfPasteNewerTitle => 'A level from a newer Beakbound';

  @override
  String get builderShelfPasteDamagedTitle => 'That code got scrambled';

  @override
  String get builderShelfPasteMissingBody =>
      'Copy a friend’s level code (it starts with BEAK1.) and tap Paste code again.';

  @override
  String get builderShelfPasteNewerBody =>
      'Update Beakbound to fly it, then paste the code again.';

  @override
  String get builderShelfPasteDamagedBody =>
      'Part of it is missing or mistyped. Ask your friend to copy the whole code again.';

  @override
  String builderShelfImported(String name) {
    return '“$name” is on your shelf!';
  }

  @override
  String get builderShelfUnavailable => 'Your levels need a moment.';

  @override
  String get builderShelfMine => 'My levels';

  @override
  String get builderShelfStarters => 'Starter levels';

  @override
  String get builderShelfStartersHint =>
      'Fly one, or remix it into a level of your own';

  @override
  String get builderShelfEmptyTitle => 'Build your first level';

  @override
  String get builderShelfEmptyBody =>
      'Place gates, stars and hearts by hand, set the finish line and test fly it.';

  @override
  String get builderShelfPasteFriend => 'Paste a friend’s code';

  @override
  String get builderShelfNeedsWork => 'Needs work';

  @override
  String get builderShelfClearedByYou => 'Cleared by you';

  @override
  String get builderShelfFromFriend => 'From a friend';

  @override
  String get builderShelfFly => 'Fly';

  @override
  String builderShelfFlySemantics(String name) {
    return 'Fly $name';
  }

  @override
  String get builderShelfFixIt => 'Fix it';

  @override
  String builderShelfFixSemantics(String name) {
    return 'Fix $name';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return 'Edit $name';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return 'Share $name';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return 'Share $name: you cleared it';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return 'More for $name';
  }

  @override
  String get builderShelfRemix => 'Remix';

  @override
  String builderShelfRemixSemantics(String name) {
    return 'Remix $name';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things to fix in the editor',
      one: '1 thing to fix in the editor',
    );
    return '$_temp0';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
    );
    return '$_temp0';
  }

  @override
  String builderShelfLevelSemantics(
    String name,
    String mode,
    String region,
    String length,
  ) {
    return '$name. $mode in $region. $length.';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Best $stars of 3 stars.',
    );
    return '$_temp0';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Needs work: $count things to fix.',
      one: 'Needs work: 1 thing to fix.',
    );
    return '$_temp0';
  }

  @override
  String get builderShelfClearedSemantics => 'Cleared by you.';

  @override
  String get builderShelfFromFriendSemantics => 'From a friend.';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return 'Look at $name. $mode, $length, $fact.';
  }

  @override
  String get builderShelfRemixSuffix => 'remix';

  @override
  String get builderShelfCopySuffix => 'copy';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get starter_t_tap_1_name => 'Garden Hop';

  @override
  String get starter_t_push_1_name => 'Ten Push-Ups';

  @override
  String get starter_t_squat_1_name => 'Stair Squats';

  @override
  String get starter_t_jump_1_name => 'Bounce Bay';

  @override
  String get starter_t_tap_boss_name => 'Baron’s Bridge';

  @override
  String get builderPickCloseNewLevel => 'Close new level';

  @override
  String get builderPickModeTitle => 'What will it be?';

  @override
  String get builderPickRegionTitle => 'Where does it fly?';

  @override
  String get builderPickModeSubtitle =>
      'Pick how it’s flown (you can’t change it later). You test fly every level by touch.';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '$mode · pick where it flies. You can change this later.';
  }

  @override
  String get builderPickTouchLine =>
      'Tap to flap. Gates, stars, enemies and a boss.';

  @override
  String get builderPickPushUpLine =>
      'A high lane and a low one: every dip is a push-up.';

  @override
  String get builderPickSquatLine =>
      'A high lane and a low one: every dip is a squat.';

  @override
  String get builderPickJumpLine => 'Jump for lift. Gates anywhere in the sky.';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '$mode. $line';
  }

  @override
  String get builderPickCamera => 'Camera';

  @override
  String get builderPickSuggested => 'Suggested';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '$region, suggested';
  }

  @override
  String get builderPickClose => 'Close';

  @override
  String get builderPickNotYet => 'Not yet: fix what’s marked in red first.';

  @override
  String get builderPickShare => 'Share code';

  @override
  String get builderPickShareLine =>
      'Copy a code a friend can paste into their Beakbound.';

  @override
  String get builderPickDuplicate => 'Duplicate';

  @override
  String get builderPickDuplicateLine => 'Make a copy to try another idea.';

  @override
  String get builderPickDeleteLine =>
      'Throw the level away. You’ll be asked first.';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '$mode · $region';
  }

  @override
  String get builderPickCancelImport => 'Cancel import';

  @override
  String get builderPickImportTitle => 'A level to fly!';

  @override
  String get builderPickImportSubtitle => 'Someone shared this level with you.';

  @override
  String get builderPickClearedByMaker => 'Cleared by its maker';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars to collect',
    );
    return '$_temp0';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {'other': 'Ends with $boss'});
    return '$_temp0';
  }

  @override
  String get builderPickNotFlown => 'Its maker hasn’t flown it to the end yet.';

  @override
  String get builderPickRoute => 'The route';

  @override
  String builderPickAlreadyHave(String name) {
    return 'You already have this level: “$name”.';
  }

  @override
  String get builderPickImportCopy => 'Import a copy';

  @override
  String get builderPickOpenYours => 'Open yours';

  @override
  String get builderPickImport => 'Import';

  @override
  String get builderShelfRenameCancelSemantics => 'Cancel rename';

  @override
  String get builderShelfRenameTitle => 'Name your level';

  @override
  String get builderShelfRenameEmpty => 'A name needs a letter or two';

  @override
  String get builderShelfRenameSaveSemantics => 'Save name';

  @override
  String get builderShelfRenameSave => 'Save';

  @override
  String get coopMode_roped => 'Roped';

  @override
  String get coopMode_free => 'No rope';

  @override
  String get coopMode_duel => '1 v 1';

  @override
  String get coopTitle => 'Fly Together';

  @override
  String get coopPlayersTag => 'TWO PLAYERS · ONE PHONE';

  @override
  String coopBestTag(String mode, int best) {
    return '$mode BEST $best';
  }

  @override
  String coopNoBestTag(String mode) {
    return '$mode: NO BEST YET';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count DUELS',
    );
    return '$_temp0';
  }

  @override
  String duelFirstTag(String mode) {
    return '$mode: FIRST DUEL';
  }

  @override
  String get coopRopedLead => 'Your birds share one rope.';

  @override
  String get coopRopedBody =>
      'Flap together to climb high: a bird flapping alone lifts both, but only a little. Sprint to drag your partner along.';

  @override
  String get coopFreeLead => 'No rope:';

  @override
  String get coopFreeBody =>
      'each bird flies on its own and only bumps into the other. Hearts, shield and score are still shared.';

  @override
  String get duelLead => 'Fight!';

  @override
  String get duelBody =>
      'Each bird has its own hearts. Grab mystery boxes: some send bats, a spitter or meteors at your rival, others bring a heart, a shield or star power. Last bird flying wins.';

  @override
  String get coopStart => 'Fly together';

  @override
  String get duelStart => 'Fight!';

  @override
  String get coopFlightSemantics =>
      'Player 1 taps the left half to flap, player 2 the right half';

  @override
  String get coopPauseSemantics => 'Pause flight';

  @override
  String coopShootSemantics(int player) {
    return 'Player $player shoot';
  }

  @override
  String coopSprintSemantics(int player) {
    return 'Player $player sprint';
  }

  @override
  String coopPlayerShort(int player) {
    return 'P$player';
  }

  @override
  String coopPlayerCaps(int player) {
    return 'PLAYER $player';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Star magnet: $seconds seconds remaining',
    );
    return '$_temp0';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Magnet charging: $charge of $gates perfect gates',
    );
    return '$_temp0';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '${seconds}s',
    );
    return '$_temp0';
  }

  @override
  String get coopCountdownRoped => 'Rope on. Ready, steady…';

  @override
  String get coopCountdownFree => 'Ready, steady…';

  @override
  String get duelCountdown => 'Ready to duel…';

  @override
  String get coopCountdownRopedHint =>
      'Flap together to climb high.\nSprint to drag your partner along!';

  @override
  String get coopCountdownFreeHint =>
      'Each bird flies on its own.\nShare the hearts, beat the gates!';

  @override
  String get duelCountdownHint =>
      'Grab the mystery boxes!\nLast bird flying wins.';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Player $player star power: $seconds seconds left',
    );
    return '$_temp0';
  }

  @override
  String get coopHome => 'Home';

  @override
  String get coopChangeBirds => 'Change birds';

  @override
  String get coopSaved => 'Saved';

  @override
  String get coopSaving => 'Saving…';

  @override
  String get coopSaveSession => 'Save session';

  @override
  String get duelRematch => 'Rematch';

  @override
  String get coopFlyAgain => 'Fly again';

  @override
  String duelWinner(int player) {
    return 'Player $player wins!';
  }

  @override
  String get duelDraw => 'A draw!';

  @override
  String get duelStopped => 'Duel stopped';

  @override
  String duelVersusCaption(String first, String second) {
    return '$first vs $second';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '$winner beat $loser';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '$prize at P$rival!';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '$prize!';
  }

  @override
  String get duelPrize_batSwarm => 'Bat swarm';

  @override
  String get duelPrize_spitter => 'Spitter beetle';

  @override
  String get duelPrize_meteorShower => 'Meteor shower';

  @override
  String get duelPrize_heart => 'Heart';

  @override
  String get duelPrize_shield => 'Shield';

  @override
  String get duelPrize_starPower => 'Star power';

  @override
  String get coopTapLeftHalf => 'Tap the left half';

  @override
  String get coopTapRightHalf => 'Tap the right half';

  @override
  String coopPickSemantics(int player, String bird) {
    return 'Player $player: $bird';
  }

  @override
  String coopSideHint(int player) {
    return 'P$player · tap this side';
  }

  @override
  String get coopKeysP1 => 'P1 · W flap · D shoot · A sprint';

  @override
  String get coopKeysP2 => 'P2 · Up flap · Right shoot · Left sprint';

  @override
  String get coopRopedSemantics => 'Roped: the birds share a rope';

  @override
  String get coopFreeSemantics => 'No rope: each bird flies on its own';

  @override
  String get duelModeSemantics => '1 v 1: the birds fight each other';

  @override
  String get duelVersus => 'VS';

  @override
  String get coopSessionSaved => 'Session saved · Watch in Records';

  @override
  String get coopNewTeamBest => 'New team best!';

  @override
  String get coopWhatATeam => 'What a team.';

  @override
  String coopPairCaption(String first, String second) {
    return '$first & $second';
  }

  @override
  String get coopTeamScore => 'TEAM SCORE';

  @override
  String get coopTeamBest => 'TEAM BEST';

  @override
  String get coopNewTeamBestRibbon => 'NEW TEAM BEST!';

  @override
  String get coopStatFlightTime => 'flight time';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'stars',
    );
    return '$_temp0';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gates',
    );
    return '$_temp0';
  }

  @override
  String get coopFlapShare => 'FLAP SHARE';

  @override
  String coopPercent(int percent) {
    return '$percent%';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'P$player flaps',
    );
    return '$_temp0';
  }

  @override
  String duelTime(String time) {
    return 'Duel time $time';
  }

  @override
  String get duelSeries => 'SERIES';

  @override
  String get duelHeartsLeft => 'hearts left';

  @override
  String get duelBoxesOpened => 'boxes opened';

  @override
  String get duelHitsLanded => 'hits landed';

  @override
  String get coopPauseSubtitle =>
      'You’re both perched and waiting. We’ll count you both in.';

  @override
  String get coopFinishFlight => 'Finish flight';

  @override
  String get cameraLabIntro =>
      'Prop your phone low in landscape, facing you or beside you.';

  @override
  String cameraLabAlmostThere(String parts) {
    return 'Almost there · need a clearer $parts';
  }

  @override
  String get cameraLabJointShoulder => 'shoulder';

  @override
  String get cameraLabJointElbow => 'elbow';

  @override
  String get cameraLabJointWrist => 'wrist';

  @override
  String get cameraLabJointHip => 'hip';

  @override
  String cameraLabJointList(String first, String rest) {
    return '$first, $rest';
  }

  @override
  String get cameraLabStarting => 'Starting camera…';

  @override
  String get cameraLabDenied =>
      'Camera access is off. Allow it in app settings, then try again.';

  @override
  String cameraLabFailed(String error) {
    return 'Camera could not start: $error';
  }

  @override
  String get cameraLabStopped => 'Camera stopped. Tap Start to recalibrate.';

  @override
  String get cameraLabBack => 'CAMERA LAB · Back to home';

  @override
  String get cameraLabStepShow => '1. Show your arms & hip';

  @override
  String get cameraLabStepPushUps => '2. Do two push-ups';

  @override
  String get cameraLabStepMove => '3. Move your bird!';

  @override
  String get cameraLabStepSquat => 'Find your squat range';

  @override
  String get cameraLabStepJump => 'Find your standing position';

  @override
  String get cameraLabPushUpHelp =>
      'Phone low, facing you or beside you.\nFacing it? Show both shoulders, an arm and hip.\nMove down and up twice at your own pace.';

  @override
  String get cameraLabSquatHelp =>
      'Stand still, squat comfortably and hold briefly, then stand back up. Squat to descend; stand to rise.';

  @override
  String get cameraLabJumpHelp =>
      'Stand facing the phone with your whole body and feet visible. Hold still, then make small jumps. One jump = one big boost.';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'CALIBRATION\n$done / $total calibrated',
    );
    return '$_temp0';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return 'CALIBRATION\n$percent% calibrated';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'CONTROL TEST\n$count push-ups',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'CONTROL TEST\n$count squats',
    );
    return '$_temp0';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'CONTROL TEST\n$count jumps',
    );
    return '$_temp0';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '$hz Hz · $ms ms p95';
  }

  @override
  String get cameraLabStartingButton => 'Starting…';

  @override
  String get cameraLabRecalibrate => 'Recalibrate';

  @override
  String get cameraLabStartCamera => 'Start camera';

  @override
  String get cameraLabTapStart => 'Tap Start camera';

  @override
  String cameraLabTry(String mode) {
    return 'Try $mode';
  }

  @override
  String get cameraBadgeWaking => 'WAKING';

  @override
  String get cameraBadgeLive => 'LIVE';

  @override
  String get cameraBadgeLockedOn => 'LOCKED ON';

  @override
  String get cameraBadgeOffline => 'OFFLINE';

  @override
  String get trackingCatchingUp => 'Camera is catching up';

  @override
  String get trackingStepIntoOutline => 'Step into the body outline';

  @override
  String get trackingKeepShoulders => 'Keep both shoulders in view';

  @override
  String get trackingShowSide =>
      'Show one shoulder, elbow, wrist and hip from the side';

  @override
  String get trackingMoveCloser => 'Move a little closer';

  @override
  String get trackingGetDown => 'Get down into your push-up position';

  @override
  String get trackingHandsOnFloor =>
      'Put your hands on the floor and extend your body behind you';

  @override
  String get trackingExtendBody =>
      'Extend your body a little farther behind your hands';

  @override
  String get trackingComfortableRange =>
      'Stay within a comfortable push-up range';

  @override
  String get trackingPlaceHands =>
      'Place your hands on the floor with your body behind them';

  @override
  String get trackingFrontTracked =>
      'Front view tracked · keep your hands in view';

  @override
  String get trackingBodyInView => 'Body in view · face can look down';

  @override
  String get trackingArmsTracked => 'Arms tracked · leg check limited';

  @override
  String get trackingFindTop => 'Find a comfortable top position';

  @override
  String get trackingCalibrated => 'Calibrated! Try moving your bird.';

  @override
  String get trackingFreshFrame => 'Waiting for a fresh frame';

  @override
  String get trackingDistanceChanged => 'Camera distance changed · recalibrate';

  @override
  String get trackingKeepArm => 'Keep an arm in view';

  @override
  String get trackingSquatStepBack =>
      'Step back so your shoulders, hips, knees and feet are in view';

  @override
  String get trackingSquatFaceCamera =>
      'Face the camera with both feet on the floor';

  @override
  String get trackingSquatControls => 'Squat to descend · stand to rise';

  @override
  String get trackingStartingDistance =>
      'Face the camera at your starting distance · recalibrate if you moved';

  @override
  String get trackingFeetPlanted =>
      'Keep both feet planted in your starting spot';

  @override
  String get trackingSquatStandTall =>
      'Stand tall and still with both feet in view';

  @override
  String get trackingStandStill => 'Stand tall and still for a moment';

  @override
  String get trackingSquatDepth =>
      'Squat to a comfortable depth and hold briefly';

  @override
  String get trackingSquatHold => 'Squat comfortably, then hold for a moment';

  @override
  String get trackingSquatHoldBriefly => 'Hold this comfortable squat briefly';

  @override
  String get trackingSquatStandUp => 'Stand back up to finish calibration';

  @override
  String get trackingSquatReady => 'Ready! Squat to descend · stand to rise';

  @override
  String get trackingJumpStepBack =>
      'Step back so your shoulders, hips and both feet are in view';

  @override
  String get trackingJumpFaceCamera =>
      'Stand facing the camera with room above you to jump';

  @override
  String get trackingJumpSmall =>
      'Small jumps are enough · land before jumping again';

  @override
  String get trackingJumpStandStill =>
      'Stand still with your whole body and both feet in view';

  @override
  String get trackingJumpReady => 'Ready! One small jump gives one big boost.';

  @override
  String get trackingFindPosition => 'Find your position';

  @override
  String get trackingInterrupted => 'Tracking interrupted';

  @override
  String get trackingCameraInterrupted =>
      'Camera interrupted. Check camera permission and try again.';

  @override
  String get trackingCameraAway => 'Camera stopped while the app was away';

  @override
  String get trackingJumpBoost => 'Jump for a big boost';

  @override
  String get trackingJumpLand => 'Land to prepare your next jump';

  @override
  String trackingLowerMore(int step, int total) {
    return 'Lower a little more · $step of $total';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return 'Lower comfortably · $step of $total';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return 'Push back up · $step of $total';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return 'Match your first comfortable range · $step of $total';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Could not save this change. Please try again. ($error)';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more to go',
    );
    return '$_temp0';
  }

  @override
  String get homeUnavailable => 'Your nest needs a moment.';

  @override
  String get homeSettings => 'Settings';

  @override
  String homeGreetingFirst(String bird) {
    return 'Hi, I’m $bird! Ready to fly?';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Adventure done! $bird is proud.',
      'female': 'Adventure done! $bird is proud.',
      'other': 'Adventure done! $bird is proud.',
    });
    return '$_temp0';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird is ready. Are you?',
      'female': '$bird is ready. Are you?',
      'other': '$bird is ready. Are you?',
    });
    return '$_temp0';
  }

  @override
  String get homeEndlessTitle => 'ENDLESS';

  @override
  String get homeEndlessDetail => 'Fly as far as you can';

  @override
  String get homeEndlessSemantics => 'Endless. Fly as far as you can.';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: 'Endless. Fly as far as you can. Best: $best stars.',
    );
    return '$_temp0';
  }

  @override
  String get homeBest => 'Best';

  @override
  String get homeBestNone => 'Set your first best';

  @override
  String get homeCampaignTitle => 'CAMPAIGN';

  @override
  String get homeCampaignDone => 'Every letter delivered';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Campaign. Next: $level. $stars of $total stars.',
    );
    return '$_temp0';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Campaign. Every letter delivered. $stars of $total stars.',
    );
    return '$_temp0';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '$id · $name';
  }

  @override
  String get homeMiniGamesTitle => 'MINI GAMES';

  @override
  String get homeMiniGamesDetail => 'Workouts · 2 players';

  @override
  String get homeMiniGamesSemantics =>
      'Mini games. Push-ups, squats, jumps, or two players.';

  @override
  String get homeBuilderTitle => 'LEVEL BUILDER';

  @override
  String get homeBuilderDetail => 'Make · fly · share';

  @override
  String get homeBuilderSemantics =>
      'Level Builder. Make your own levels, fly them and share them.';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Unlocks in $count flights',
      one: 'Unlocks in 1 flight',
    );
    return '$_temp0';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Level Builder. Locked. Unlocks in $count flights.',
      one: 'Level Builder. Locked. Unlocks in 1 flight.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockAdventure => 'Adventure';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Today’s adventure. $done of 3 goals complete.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockBirds => 'Birds';

  @override
  String homeDockBirdsSemantics(String bird) {
    return 'Birds. Flying with $bird.';
  }

  @override
  String get homeDockUpgrades => 'Upgrades';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Upgrades. $stars stars to spend.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockPassport => 'Passport';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Passport. $earned of $total medals.',
    );
    return '$_temp0';
  }

  @override
  String get homeDockRecords => 'Records';

  @override
  String get homeMiniGamesPickerTitle => 'Mini games';

  @override
  String get homeMiniGamesPickerIntro =>
      'Move to fly, or share the phone with a friend.';

  @override
  String get homeMiniGamesCloseSemantics => 'Close mini games';

  @override
  String get homeMiniGamesPushUpCard => 'Lower to dip.\nPush up to soar.';

  @override
  String get homeMiniGamesSquatCard => 'Squat low.\nStand to soar.';

  @override
  String get homeMiniGamesJumpCard => 'Jump for lift.\nGlide for stars.';

  @override
  String get homeMiniGamesCoopCard =>
      'Two players, one phone.\nTeam up or duel.';

  @override
  String get homeMiniGamesCamera => 'Camera';

  @override
  String get homeMiniGamesPlayers => '2 players';

  @override
  String get homeMiniGamesCoop => 'Fly Together';

  @override
  String get birdsTitle => 'Meet your flight crew.';

  @override
  String birdsFlownTag(int flown, int total) {
    return '$flown OF $total FLOWN';
  }

  @override
  String get birdsStatusCopilot => 'YOUR CO-PILOT';

  @override
  String get birdsStatusReady => 'READY TO FLY';

  @override
  String get birdsStatusLocked => 'LOCKED';

  @override
  String get birdsNotFlown => 'Not flown yet';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flights',
      one: '1 flight',
    );
    return '$_temp0';
  }

  @override
  String birdsFlyWith(String bird) {
    return 'Fly with $bird';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return 'Fly with $bird instead of $current';
  }

  @override
  String birdsUnlock(String bird) {
    return 'Unlock $bird';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Unlock $bird for $price stars',
    );
    return '$_temp0';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'Unlock $bird for $price stars, not enough stars yet',
    );
    return '$_temp0';
  }

  @override
  String get birdsFlyingWithYou => 'Flying with you';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '$bird, flying with you';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '$bird, flying with you, new';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, locked, $price stars',
    );
    return '$_temp0';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '$bird, new';
  }

  @override
  String get birdsTagFlying => 'FLYING';

  @override
  String get birdsTagNew => 'NEW';

  @override
  String get bird_0_description => 'Small bird. Big sky.';

  @override
  String get bird_0_trail => 'Sunshine bubbles';

  @override
  String get bird_1_description => 'Rosy cheeks, curly crest, all heart.';

  @override
  String get bird_1_trail => 'Peach hearts';

  @override
  String get bird_2_description => 'Tiny hummer. Fresh sprig. Full speed.';

  @override
  String get bird_2_trail => 'Mint leaves';

  @override
  String get bird_3_description => 'A dreamy owl who flies by starlight.';

  @override
  String get bird_3_trail => 'Stardust sparkles';

  @override
  String get upgradesWalletLabel => 'YOUR\nSTARS';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars stars to spend',
    );
    return '$_temp0';
  }

  @override
  String get upgradesTitle => 'Power up your bird.';

  @override
  String get upgradesIntro =>
      'Tap a gear to see what it does. Every star you pick up in flight is one to spend.';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, level $level of $max. Next level $cost stars',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketLockedSemantics(
    int cost,
    String power,
    int level,
    int max,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other:
          '$power, level $level of $max. Next level $cost stars, not enough yet',
    );
    return '$_temp0';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '$power, level $level of $max. Maxed';
  }

  @override
  String get upgradesMax => 'MAX';

  @override
  String upgradesLevel(int level) {
    return 'Level $level';
  }

  @override
  String upgradesLevelTop(int level) {
    return 'Level $level, the top';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '$label $now';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '$label $now, next level $next';
  }

  @override
  String upgradesStatPercent(String value) {
    return '$value%';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '$value s';
  }

  @override
  String upgradesStatTimes(String value) {
    return '$value×';
  }

  @override
  String upgradesStarsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You will have $count stars left.',
    );
    return '$_temp0';
  }

  @override
  String get upgradesButton => 'Upgrade';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Upgrade for $cost stars',
    );
    return '$_temp0';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Upgrade for $cost stars, not enough stars yet',
    );
    return '$_temp0';
  }

  @override
  String get upgradesMaxedOut => 'Maxed out';

  @override
  String get power_shot_name => 'Shot power';

  @override
  String get power_shot_blurb => 'Hold Shoot to charge a bigger, harder rock.';

  @override
  String get power_sprint_name => 'Sprint';

  @override
  String get power_sprint_blurb =>
      'A speed burst that smashes enemies in your way.';

  @override
  String get power_shield_name => 'Shield';

  @override
  String get power_shield_blurb =>
      'Blocks one hit for you. Collect stars in flight to refill it.';

  @override
  String get power_magnet_name => 'Magnet';

  @override
  String get power_magnet_blurb =>
      'Fly perfectly through gates to earn it. It pulls stars to you.';

  @override
  String get power_stat_maxCharge => 'Max charge';

  @override
  String get power_stat_burstLength => 'Burst length';

  @override
  String get power_stat_cooldown => 'Cooldown';

  @override
  String get power_stat_starsToRefill => 'Stars to refill';

  @override
  String get power_stat_safeTime => 'Safe time after it breaks';

  @override
  String get power_stat_perfectGates => 'Perfect gates needed';

  @override
  String get power_stat_lasts => 'Lasts';

  @override
  String get power_stat_reach => 'Reach';

  @override
  String get passportTitle => 'Your sky passport.';

  @override
  String get passportDailyCard => 'Daily card';

  @override
  String passportMedalsTag(int earned, int total) {
    return '$earned / $total MEDALS';
  }

  @override
  String get passportIntro =>
      'Small adventures. Lasting souvenirs. Bronze, silver and gold for every stamp.';

  @override
  String get passportNoMedal => 'No medal yet';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Bronze medal',
      'silver': 'Silver medal',
      'other': 'Gold medal',
    });
    return '$_temp0';
  }

  @override
  String passportStampSemantics(
    String stamp,
    String held,
    String next,
    String goal,
    int current,
    int target,
  ) {
    return '$stamp. $held. Next, $next: $goal $current of $target.';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '$stamp. Gold medal. $goal';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'TO BRONZE',
      'silver': 'TO SILVER',
      'other': 'TO GOLD',
    });
    return '$_temp0';
  }

  @override
  String get passportStamped => 'STAMPED';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '$stamp: $medal';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '$stamp: none yet';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '$stamp · $medal';
  }

  @override
  String get passportMedal_bronze => 'Bronze';

  @override
  String get passportMedal_silver => 'Silver';

  @override
  String get passportMedal_gold => 'Gold';

  @override
  String get stamp_frequentFlyer_name => 'Frequent flyer';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Finish $n scored flights.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_onTheDot_name => 'On the dot';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fly $n perfect passes along the aiming marks.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_starChaser_name => 'Star chaser';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Collect $n stars.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_constellation_name => 'Constellation';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Collect $n stars in one unbroken streak.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_skyCaptain_name => 'Sky captain';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Score $n points in one endless flight.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_trailblazer_name => 'Trailblazer';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fly at least 60 seconds in $n endless flights.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_flockTogether_name => 'Flock together';

  @override
  String get stamp_allRounder_name => 'All-rounder';

  @override
  String get stamp_flockTogether_goalBronze =>
      'Take two different birds on scored flights.';

  @override
  String get stamp_flockTogether_goalSilver =>
      'Take all four birds on scored flights.';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fly $n scored flights with every bird.',
    );
    return '$_temp0';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      'Fly a push-up, squat or jump mini game.';

  @override
  String get stamp_allRounder_goalSilver =>
      'Fly all three mini games: push-up, squat, jump.';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fly $n scored flights in each mini game.',
    );
    return '$_temp0';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals medals · at $level',
    );
    return '$_temp0';
  }

  @override
  String get dailyUnavailable => 'Your adventure needs a moment.';

  @override
  String get dailyTitle => 'Today’s little adventure.';

  @override
  String dailyDateTag(String date, int done) {
    return '$date · $done/3 GOALS';
  }

  @override
  String get dailyIntro =>
      'Three goals. Any control. One endless flight works on all three.';

  @override
  String get dailyLaunchEndless => 'Endless';

  @override
  String get dailyPostcardKicker => 'SKY CLUB POSTCARD';

  @override
  String get dailyStamped => 'POSTCARD STAMPED!';

  @override
  String dailyGoalsComplete(int done) {
    return '$done / 3 GOALS COMPLETE';
  }

  @override
  String get dailyDoneNote => 'A small adventure, all yours.';

  @override
  String get dailyOpenNote => 'Finish all three to stamp this card.';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '$goal Complete';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '$goal $current of $target';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '$date: Postcard stamped';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '$date: $done/3 goals';
  }

  @override
  String get dailyNoStreak => 'Fresh goals. No streak to lose.';

  @override
  String get dailyTheme_0 => 'Sunrise delivery';

  @override
  String get dailyTheme_1 => 'Peach picnic';

  @override
  String get dailyTheme_2 => 'Moonlit mail';

  @override
  String get dailyTheme_3 => 'Cloud parade';

  @override
  String get dailyTheme_4 => 'Twilight treasure';

  @override
  String get dailyTheme_5 => 'Garden party';

  @override
  String get task_flights_title => 'Spread your wings';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Finish $count scored flights today.',
    );
    return '$_temp0';
  }

  @override
  String get task_gates_title => 'Open horizons';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clear $count gates across today’s scored flights.',
    );
    return '$_temp0';
  }

  @override
  String get task_stars_title => 'Pocketful of stars';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Collect $count stars across today’s flights.',
    );
    return '$_temp0';
  }

  @override
  String get task_streak_title => 'Keep the sparkle';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Collect $count stars in one unbroken streak.',
    );
    return '$_temp0';
  }

  @override
  String get task_perfects_title => 'Right on the mark';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fly $count perfect passes today.',
    );
    return '$_temp0';
  }

  @override
  String get task_finishTrail_title => 'The whole journey';

  @override
  String get task_finishTrail_goal =>
      'Fly for at least 60 seconds in one endless flight.';

  @override
  String get recordsTitle => 'Your little victories.';

  @override
  String get recordsBestsTitle => 'Your star points to beat';

  @override
  String get recordsSectionMain => 'MAIN GAME';

  @override
  String get recordsSectionMini => 'MINI GAMES';

  @override
  String get recordsEndless => 'Endless · Tap & Fly';

  @override
  String get recordsCampaignStars => 'Campaign stars';

  @override
  String recordsCoopName(String mode) {
    return 'Fly Together · $mode';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'scored flights',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gates',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'together',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'duels',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'push-ups',
    );
    return '$_temp0';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'squats',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentTitle => 'Recent flights';

  @override
  String get recordsEmptyTitle => 'A big sky. A clean slate.';

  @override
  String get recordsEmptyBody => 'Your first scored flight starts the story.';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '$date · $seconds sec';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return 'Classic · $date · $seconds sec';
  }

  @override
  String get replaySavedSessions => 'Saved sessions';

  @override
  String get replayBackToRecordsSemantics => 'Back to Records';

  @override
  String get replaySessionsLoadFailed => 'Could not load sessions. Retry';

  @override
  String get replayEmptyTitle => 'Your flights belong here';

  @override
  String get replayEmptyBody =>
      'Save a session after a flight to watch it here.';

  @override
  String get replayEmptyButton => 'Choose a flight';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds sec · $score star points',
    );
    return '$_temp0';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds sec · $score gates',
    );
    return '$_temp0';
  }

  @override
  String get replayDeleteSemantics => 'Delete session';

  @override
  String get replayDeleteTitle => 'Delete this session?';

  @override
  String get replayDeleteBody =>
      'The camera video and replay will be removed. Your scores stay in Records.';

  @override
  String get replayDeleteFailed => 'Could not delete session. Try again.';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '$name · $mode';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return 'Level $id';
  }

  @override
  String replaySessionEndless(String mode) {
    return '$mode · Endless';
  }

  @override
  String replaySessionPractice(String mode) {
    return '$mode · Practice';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '$mode · Endless · Practice';
  }

  @override
  String get replayOpenFailed => 'This session could not be opened.';

  @override
  String get replayBackToSessions => 'Back to sessions';

  @override
  String get replayCameraPaused =>
      'Camera was paused during this part of the session';

  @override
  String get replayCameraUnavailable =>
      'Camera clip unavailable · Gameplay still plays';

  @override
  String get replayCameraLoading => 'Loading camera…';

  @override
  String get replayPaused => 'Taking a breather';

  @override
  String get replayHideControlsSemantics => 'Hide replay controls';

  @override
  String get replayShowControlsSemantics => 'Show replay controls';

  @override
  String get replayBackToSavedSemantics => 'Back to saved sessions';

  @override
  String get replayTitle => 'REPLAY';

  @override
  String replayTitleSession(String session) {
    return 'REPLAY · $session';
  }

  @override
  String replayScoreSemantics(int score) {
    return 'Score: $score';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts hearts',
    );
    return '$_temp0 · $clock';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return 'P1 $p1 · P2 $p2 hearts · $clock';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String replayMagnet(int seconds) {
    return 'Magnet · ${seconds}s';
  }

  @override
  String get replayPauseSemantics => 'Pause replay';

  @override
  String get replayPlaySemantics => 'Play replay';

  @override
  String get replayRestartSemantics => 'Restart replay';

  @override
  String get replayBack5Semantics => 'Back 5 seconds';

  @override
  String get replayForward5Semantics => 'Forward 5 seconds';

  @override
  String get replayHighlightsFinding => 'Finding flight highlights';

  @override
  String get replayHighlightsNone => 'No flight highlights available';

  @override
  String get replayHighlights => 'Flight highlights';

  @override
  String get replayHighlightsCloseSemantics => 'Close highlights';

  @override
  String get replayHighlightsHint =>
      'Pick a moment. Watch from just before it happened.';

  @override
  String get replayViewCorner => 'Corner camera';

  @override
  String get replayViewBackground => 'Camera background';

  @override
  String get replayViewGameplay => 'Gameplay only';

  @override
  String get replayMoveCornerSemantics => 'Move camera corner';

  @override
  String get replayMuteRecordedSemantics => 'Mute recorded audio';

  @override
  String get replayUnmuteRecordedSemantics => 'Enable recorded audio';

  @override
  String get replayMuteGameSemantics => 'Mute game sound';

  @override
  String get replayUnmuteGameSemantics => 'Enable game sound';

  @override
  String get replayFullScreenSemantics => 'Hide controls / full screen';

  @override
  String get replayMomentTakeoff => 'Takeoff';

  @override
  String get replayMomentTakeoffDetail => 'The sky is yours.';

  @override
  String get replayMomentMagnet => 'Star magnet';

  @override
  String get replayMomentMagnetDetail =>
      'Three perfect passes bring the stars closer.';

  @override
  String get replayMomentStarTrio => 'First star trio';

  @override
  String get replayMomentStarTrioDetail =>
      'Three stars become a constellation. +5 points!';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      'Every star in the group collected. +5 points!';

  @override
  String replayMomentStreak(int multiplier) {
    return '$multiplier× star power';
  }

  @override
  String get replayMomentStreakDetail => 'A sparkling streak of stars.';

  @override
  String get replayMomentShield => 'Shield save';

  @override
  String get replayMomentShieldDetail => 'A close call, and another chance.';

  @override
  String get replayMomentPerfect => 'First perfect pass';

  @override
  String get replayMomentPerfectDetail => 'Right through the aiming mark.';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gates cleared',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGatesDetail => 'A little farther into the sky.';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Not a scratch. +$points points!',
    );
    return '$_temp0';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Sprint rings to safety. +$points points!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentGale => 'Weathered the gale';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Dodged the flying debris. +$points points!',
    );
    return '$_temp0';
  }

  @override
  String get replayMomentRouteComplete => 'Route complete';

  @override
  String get replayMomentFinal => 'Final moment';

  @override
  String get replayMomentCompleteDetail => 'You reached the end of the route.';

  @override
  String get replayMomentCollisionDetail => 'Watch the final approach.';

  @override
  String get replayMomentEndDetail => 'The end of this flight.';

  @override
  String get welcomeTitle => 'Choose your language';

  @override
  String get welcomeContinue => 'Let’s fly!';

  @override
  String get welcomeHint => 'You can change it any time in Settings.';

  @override
  String get welcomeDevice => 'Your phone’s language';

  @override
  String get tutorialTitle => 'Flight school';

  @override
  String get tutorialSkip => 'Skip lesson';

  @override
  String get tutorialSkipTitle => 'Skip flight school?';

  @override
  String get tutorialSkipBody =>
      'You can take the lesson again any time from Settings.';

  @override
  String get tutorialSkipConfirm => 'Skip';

  @override
  String get tutorialSkipCancel => 'Keep learning';

  @override
  String get tutorialRestart => 'Start over';

  @override
  String get tutorialGoalFlaps => 'Flap';

  @override
  String get tutorialGoalStars => 'Collect stars';

  @override
  String get tutorialGoalGates => 'Fly through gates';

  @override
  String get tutorialGoalBats => 'Knock out bats';

  @override
  String get tutorialGoalDoor => 'Smash the door';

  @override
  String get tutorialGoalSprint => 'Sprint';

  @override
  String get tutorialGoalBoss => 'Beat the Captain';

  @override
  String get tutorialPromptTap => 'Tap!';

  @override
  String get tutorialPromptShoot => 'Tap Shoot';

  @override
  String get tutorialPromptHoldShoot => 'Hold Shoot';

  @override
  String get tutorialPromptSprint => 'Tap Sprint';

  @override
  String get tutorialPraiseNice => 'Nice!';

  @override
  String get tutorialPraiseGreat => 'Great!';

  @override
  String get tutorialPraiseSuper => 'Brilliant!';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return 'The lesson is waiting: $prompt';
  }

  @override
  String get licenceTitle => 'Courier licence';

  @override
  String get licenceIssuer => 'Sky Club post';

  @override
  String get licenceHolder => 'Courier';

  @override
  String get licenceRank => 'Rank';

  @override
  String get licenceRankRookie => 'Rookie courier';

  @override
  String get licenceSkills => 'Skills';

  @override
  String get licenceStamp => 'Certified';

  @override
  String licenceSignedBy(String name) {
    return 'Signed: $name';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get licenceStart => 'Start my first route';

  @override
  String get licenceAgain => 'Fly it again';

  @override
  String get settingsTutorial => 'Flight school';

  @override
  String get settingsTutorialDetail => 'Take the first lesson again';
}

/// The translations for English (`en_XA`).
class AppLocalizationsEnXa extends AppLocalizationsEn {
  AppLocalizationsEnXa() : super('en_XA');

  @override
  String get commonTryAgain => '[Trý áágáííñ~~]';

  @override
  String get languageKeyLabel => '[Łááñgüáágé~~]';

  @override
  String languageKeySemantics(String language) {
    return '[Łááñgüáágé: $language. Çhááñgé théé gáméé\'š łáñgüüágéé.~~~~~~~]';
  }

  @override
  String get languageSystemDefault => '[Šýštéém ðéƒááüłt~~~~]';

  @override
  String languageSystemDetail(String language) {
    return '[Fööłłöwš ýööür þhööñé: $language~~~~~]';
  }

  @override
  String get languageCurrent => '[Çüürréñt łááñgüáágé~~~]';

  @override
  String get languageName_en => '[ÉÉñgłíšh~~]';

  @override
  String get languageName_es_419 => '[Šþááñíšh (Łáátíñ ÅÅmérííçá)~~~~]';

  @override
  String get languageName_pt_br => '[Þöörtügüüéšéé (Brážííł)~~~]';

  @override
  String get languageName_id => '[ÎÎñðöñééšíááñ~]';

  @override
  String get languageName_fr => '[Frééñçh~~]';

  @override
  String get languageName_de => '[Géérmáñ~~]';

  @override
  String get languageName_ja => '[Jááþáñééšé~~]';

  @override
  String get languageName_ko => '[Kööréááñ~]';

  @override
  String get languageName_tr => '[Tüürkíšh~~]';

  @override
  String get languageName_zh_hant => '[Trááðítííöñááł Çhíñééšé~~~~]';

  @override
  String get languageName_ru => '[Rüüššíááñ~]';

  @override
  String get languageName_ar => '[ÅÅrábííç~]';

  @override
  String get voicePackReady => '[Vööíçééš réááðý~~]';

  @override
  String get voicePackDownload => '[Géét vöííçéš~~]';

  @override
  String voicePackDownloading(int percent) {
    return '[Vööíçééš $percent%~~]';
  }

  @override
  String get voicePackStarting => '[Gééttíñg vööíçééš~~~]';

  @override
  String get voicePackEnglish => '[ÉÉñgłíšh vööíçééš~~~]';

  @override
  String get voicePackFailed => '[Vööíçééš ƒáííłéð~~]';

  @override
  String get settingsTitle => '[Mááké ýööüršééłƒ át höömé.~~~~]';

  @override
  String get settingsSectionSound => '[Šööüñð~]';

  @override
  String get settingsSectionComfort => '[Çöömƒört~~]';

  @override
  String get settingsMusicTitle => '[Šký Çłüüb šöüüñðtráçk~~~~~]';

  @override
  String get settingsMusicDetail =>
      '[Mééñü, ááðvéñtüüré ááñð böšš thééméš.~~~~~~]';

  @override
  String get settingsEffectsTitle => '[Šööüñð ééƒƒéçtš~~~]';

  @override
  String get settingsEffectsDetail =>
      '[Fłííght, çömbáát, þíçküüþš áñð mééñü ƒéééðbááçk.~~~~~~~~]';

  @override
  String get settingsVoicesTitle => '[Çhááráçtéér vöííçéš~~~]';

  @override
  String get settingsVoicesDetail =>
      '[Štöörý šçéñééš, tháñk-ýööü ñöötéš ááñð šþríñt çááłłš.~~~~~~~~~~]';

  @override
  String get settingsReducedMotionTitle => '[Rééðüçééð mötííöñ~~~]';

  @override
  String get settingsReducedMotionDetail =>
      '[Qüüíéétér mééñüš ááñð ƒéwéér ðéçöörátíívé ééƒƒéçtš.~~~~~~~]';

  @override
  String get settingsSwitchOn => '[ØØÑ]';

  @override
  String get settingsSwitchOff => '[ØØFF~]';

  @override
  String get settingsUnavailable => '[Ýööür šééttíñgš ñéééð áá mömééñt.~~~~~]';

  @override
  String get settingsPrivacyKicker => '[ØØÑ-ÐÉVÎÎÇÉ. ÅÅŁWÅÝŠ.~~~]';

  @override
  String get settingsPrivacyTitle => '[Ýööür çááméráá štáýš ýööürš.~~~~]';

  @override
  String get settingsPrivacyBody =>
      '[Vííðéöö áñð ööþtíööñáł mííçröþhööñé ááüðííö štááý öñ thííš þhöñéé. Ûñšáávéð çłííþš áréé ðíšçáárðéð. Ñöö üþłööáðš.~~~~~~~~~~~~~~~]';

  @override
  String get settingsCameraLab => '[Çááméráá & tráçkííñg łáb~~~~]';

  @override
  String get settingsAbout => '[ÅÅböüüt & łíçééñšéš~~~]';

  @override
  String settingsVersion(String version) {
    return '[v$version~~]';
  }

  @override
  String settingsAboutSemantics(String version) {
    return '[ÅÅböüüt & łíçééñšéš, vééršíööñ $version~~~~~]';
  }

  @override
  String get settingsReset => '[Rééšét łööçáł þröögréšš~~~~~]';

  @override
  String settingsResetDone(String bird) {
    return '[ÅÅ ƒréšh štáárt. $bird íš rééáðý ƒöör ýöüü.~~~~~~~]';
  }

  @override
  String get settingsResetTitle => '[Štáárt á ƒrééšh áðvééñtüréé?~~~~]';

  @override
  String get settingsResetBody =>
      '[Thííš ðéłéétéš ýööür šáávéð vííðéööš, réþłááýš, šçörééš, rüñš, büüíłt łéévéłš ááñð šéttííñgš ƒröm thííš þhöñéé. Ît çááññöt béé üñðööñé.~~~~~~~~~~~~~~~~~~~~~]';

  @override
  String get settingsResetBodyCloud =>
      '[Thííš ðéłéétéš ýööür šáávéð vííðéööš, réþłááýš, šçörééš, rüñš, büüíłt łéévéłš ááñð šéttííñgš ƒröm thííš þhöñéé, áñð ýööür Þłááý Gámééš çłöüüð šávéé. Ît çááññöt béé üñðööñé.~~~~~~~~~~~~~~~~~~~~~~~~~~]';

  @override
  String get settingsResetConfirm => '[Rééšét éévérýthííñg~~~]';

  @override
  String get settingsResetKeep => '[Kéééþ mý þröögréšš~~~~]';

  @override
  String get playGamesName => '[Þłááý Gámééš~~]';

  @override
  String get playGamesConnected => '[Çööññéçtééð~~]';

  @override
  String get playGamesNotConnected => '[Ñööt çöññééçtéð~~~]';

  @override
  String get playGamesConnecting => '[Çööññéçtííñg…~~]';

  @override
  String get playGamesConnectFailed => '[Çööüłðñ’t çööññéçt~~~~]';

  @override
  String get playGamesIdle => '[Çłööüð šáávé & ááçhíéévémééñtš~~~~]';

  @override
  String get playGamesSaving => '[Šáávíñg töö çłöüüð…~~~]';

  @override
  String get playGamesOfflineUnsaved => '[ØØƒƒłíñéé · ñöt šáávéð ýéét~~~~]';

  @override
  String playGamesOfflineSaved(String ago) {
    return '[ØØƒƒłíñéé · šávééð $ago~~~~]';
  }

  @override
  String get playGamesUpdateNeeded => '[ÛÛþðátéé Béáákböüüñð tö šýñç~~~~~]';

  @override
  String get playGamesUnreadable => '[Çłööüð šáávé çááñ’t bé rééáð~~~~]';

  @override
  String get playGamesOn => '[Çłööüð šáávé ííš öñ~~~]';

  @override
  String get playGamesResetElsewhere => '[Rééšét ööñ áñööthér þhööñé~~~~]';

  @override
  String playGamesRestored(String ago) {
    return '[Çłööüð rééštörééð · $ago~~~~]';
  }

  @override
  String playGamesSaved(String ago) {
    return '[Šáávéð töö çłöüüð · $ago~~~~]';
  }

  @override
  String get playGamesAchievementsSemantics =>
      '[Þłááý Gámééš áçhííévééméñtš~~~~~]';

  @override
  String get playGamesConnectSemantics => '[Çööññéçt Þłááý Gámééš~~~~]';

  @override
  String get playGamesAchievements => '[ÅÅçhíéévémééñtš~~]';

  @override
  String get playGamesConnect => '[Çööññéçt~~]';

  @override
  String get timeAgoJustNow => '[jüüšt ñöw~~]';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes mííñ ágöö',
    );
    return '[$_temp0~~]';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours h áágö',
    );
    return '[$_temp0~~~]';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ð áágö',
    );
    return '[$_temp0~~~]';
  }

  @override
  String get calloutLife => '[+1 ŁÎÎFÉ!~]';

  @override
  String calloutStarTrio(int points) {
    return '[ŠTÅÅR TRÎØØ +$points!~~~]';
  }

  @override
  String get calloutNiceShot => '[ÑÎÎÇÉ ŠHØØT!~~]';

  @override
  String calloutNiceShotPoints(int points) {
    return '[ÑÎÎÇÉ ŠHØØT +$points!~~~]';
  }

  @override
  String get calloutSmash => '[ŠMÅÅŠH!~]';

  @override
  String calloutSmashPoints(int points) {
    return '[ŠMÅÅŠH +$points!~~~]';
  }

  @override
  String calloutSmashChain(int count) {
    return '[ŠMÅÅŠH ×$count!~~~]';
  }

  @override
  String get calloutBossDown => '[BØØŠŠ ÐØWÑ!~~~]';

  @override
  String calloutBossDownPoints(int points) {
    return '[BØØŠŠ ÐØWÑ +$points!~~~~]';
  }

  @override
  String calloutStarPower(int multiplier) {
    return '[$multiplier× ŠTÅÅR ÞØWÉÉR!~~~~]';
  }

  @override
  String get calloutPerfect => '[ÞÉÉRFÉÇT!~~]';

  @override
  String calloutPerfectChain(int count) {
    return '[ÞÉÉRFÉÇT ×$count~~~~]';
  }

  @override
  String get calloutShieldReady => '[ŠHÎÎÉŁÐ RÉÉÅÐÝ~~~]';

  @override
  String get calloutShieldSave => '[ŠHÎÎÉŁÐ ŠÅÅVÉ!~~]';

  @override
  String get calloutKeepFlying => '[KÉÉÉÞ FŁÝÎÎÑG!~~]';

  @override
  String calloutGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count GÅÅTÉŠ!',
    );
    return '[$_temp0~~~]';
  }

  @override
  String calloutFinalStretch(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds ŠÉÉÇØÑÐŠ ŁÉÉFT',
    );
    return '[$_temp0~~~~]';
  }

  @override
  String get calloutStarMagnet => '[ŠTÅÅR MÅGÑÉÉT!~~]';

  @override
  String get calloutSprintRing => '[ŠÞRÎÎÑT RÎÑG!~~~]';

  @override
  String calloutRushChain(int count) {
    return '[RÛÛŠH ×$count!~~~]';
  }

  @override
  String calloutMeteorPoints(int points) {
    return '[MÉÉTÉØØR +$points!~~]';
  }

  @override
  String calloutBatPoints(int points) {
    return '[BÅÅT +$points!~~]';
  }

  @override
  String get calloutScorched => '[ŠÇØØRÇHÉÐ!~~~]';

  @override
  String get region_jungle => '[Jüüñgłé~~]';

  @override
  String get region_antarctica => '[ÅÅñtárçtííçá~~]';

  @override
  String get region_aztec => '[ÅÅžtéç~]';

  @override
  String get region_paris => '[Þááríš~]';

  @override
  String get region_egypt => '[ÉÉgýþt~]';

  @override
  String get region_cyberpunk => '[Çýbéérþüñk Çíítý~~~~]';

  @override
  String get region_china => '[Çhííñá~]';

  @override
  String get region_brazil => '[Bráážíł~~]';

  @override
  String get region_newYork => '[Ñééw Ýörk~~]';

  @override
  String get region_arabia => '[ÅÅñçíééñt Åráábíáá~~]';

  @override
  String get region_rome => '[ÅÅñçíééñt Röméé~~]';

  @override
  String get region_mexico => '[Mééxíçöö~]';

  @override
  String get region_sea => '[ØØþéñ Šééá~]';

  @override
  String get boss_baronBat_name => '[Bááröñ Báát~~]';

  @override
  String get boss_spitterBeetle_name => '[Šþííttér Kííñg~~~]';

  @override
  String get boss_duskMoth_name => '[Ðüüšk Émþrééšš~~~]';

  @override
  String get boss_pirate_name => '[Þíírátéé Çáþtááíñ~~~]';

  @override
  String get boss_dragon_name => '[ÉÉmbér Ðráágöñ~~~]';

  @override
  String get boss_kingCoo_name => '[Kííñg Çööö~]';

  @override
  String get boss_searchlightGargoyle_name => '[Šééárçhłííght Gárgööýłé~~~~~]';

  @override
  String get boss_neferhoo_name => '[Ñééƒérhööö~~]';

  @override
  String get bird_0_name => '[Þííþ~]';

  @override
  String get bird_1_name => '[Þééáçhééš~]';

  @override
  String get bird_2_name => '[Mííñtý~]';

  @override
  String get bird_3_name => '[ØØrbít~]';

  @override
  String get playMode_pushUp => '[Þüüšh-Ûþ Fłííght~~~]';

  @override
  String get playMode_jump => '[Jüümþ & Fłý~~]';

  @override
  String get playMode_touch => '[Tááþ & Fłý~~]';

  @override
  String get playMode_squat => '[Šqüüát & Fłý~~~]';

  @override
  String get chapter_1_route => '[Théé Çáñööþý Röüüté~~~]';

  @override
  String get chapter_1_postmark => '[ÇÅÅÑØÞÝ RØØÛTÉÉ~~]';

  @override
  String get chapter_1_postcard =>
      '[Łééttérš ááré łááñðíñg ííñ thé trééétööþš ágááíñ! Théé töüüçáñš šááý tháñk ýööü (véérý łöüüðłý). Bárööñ Bát’š çrööwñ íš ööñ öüür máñtééłþíééçé.~~~~~~~~~~~~~~~~~~~~~]';

  @override
  String get chapter_1_postscript =>
      '[Théé áñçííéñt rööáð šmééłłš łíkéé šömééthíñg ííš bübbłííñg.~~~~~~~~~~]';

  @override
  String get chapter_2_route => '[Théé Åñçííéñt Rööáð~~~]';

  @override
  String get chapter_2_postmark => '[ÅÅÑÇÎÉÉÑT RØÅÅÐ~~]';

  @override
  String get chapter_2_postcard =>
      '[Théé çárááváñš ááré rööłłíñg ááñð thé ööñłý thíñg brééwíñg ííš míñt tééá. Wéé kéþt théé Kíñg’š ƒłáášk çröwñ ááš á váášé.~~~~~~~~~~~~~~~~~~~~]';

  @override
  String get chapter_2_postscript =>
      '[Théé çítý łáámþš wéñt ðáárk łášt ñííght. Bríñg áá łíght.~~~~~~~~~~~]';

  @override
  String get chapter_3_route => '[Théé Łámþłííght Łíñéé~~~~]';

  @override
  String get chapter_3_postmark => '[ŁÅÅMÞŁÎGHT ŁÎÎÑÉ~~~~]';

  @override
  String get chapter_3_postcard =>
      '[Théé łámþš ááré łíít áñð théé ñíght mááíł ííš wíðéé áwááké! Þááríš šééñðš á çrööíššááñt. Ñéw Ýöörk šéñðš áá þrétžééł.~~~~~~~~~~~~~~~~~]';

  @override
  String get chapter_3_postscript =>
      '[Théé hárbööür bééłłš hávéé štöþþééð ríñgííñg.~~~~~~~~]';

  @override
  String get chapter_4_route => '[Théé Tíðéé Röüüté~~]';

  @override
  String get chapter_4_postmark => '[TÎÎÐÉ RØØÛTÉÉ~]';

  @override
  String get chapter_4_postcard =>
      '[Théé hárbööür bééłłš ríñg ƒöör łéttéérš ágááíñ, ñööt çáññööñš. Thé þáárröt štááýéð. Héé šáýš hééłłö.~~~~~~~~~~~~~~~~]';

  @override
  String get chapter_4_postscript =>
      '[Thééý šáý théé šký át théé éðgéé öƒ théé máþ ííš öñ ƒííré.~~~~~~~~~]';

  @override
  String get chapter_5_route => '[Théé Éðgéé öƒ théé Máþ~~~]';

  @override
  String get chapter_5_postmark => '[ÉÉÐGÉ ØØF THÉ MÅÅÞ~~]';

  @override
  String get chapter_5_postcard =>
      '[Théé šký íš çłééár ƒrööm þöłéé tö þööłé ááñð évéérý röüüté ííš rüññííñg. Thé whööłé Šký Çłüüb íš þrööüð ööƒ ýöüü.~~~~~~~~~~~~~~~~]';

  @override
  String get chapter_5_postscript =>
      '[Théé éñðłééšš šký íš štííłł öüüt théréé, whéñéévér ýööü ááré.~~~~~~~~~]';

  @override
  String get level_1_1_name => '[Fííršt Ðéłíívérý~~~~]';

  @override
  String get level_1_1_cargo =>
      '[ÅÅ bírthðááý çárð ƒöör thé tööüçááñ twíñš~~~~~~~]';

  @override
  String get level_1_1_sender => '[Théé töüüçáñ twííñš~~~]';

  @override
  String get level_1_1_hint =>
      '[Tááþ tö ƒłááþ. Fłý thröüügh thé štáárš.~~~~~~~]';

  @override
  String get level_1_2_name => '[Štáár Štréáák~~]';

  @override
  String get level_1_2_cargo =>
      '[Štáár çhártš ƒöör thé šłööth štárgáážér~~~~~~~~]';

  @override
  String get level_1_2_sender => '[Théé šłöth štáárgážéér~~~~]';

  @override
  String get level_1_2_hint =>
      '[Çhááíñ štáárš ƒör 3×; thrééé þéérƒéçt gáátéš ééárñ áá mágñéét.~~~~~~~~~]';

  @override
  String get level_1_3_name => '[Báát Þátrööł~~]';

  @override
  String get level_1_3_cargo =>
      '[Ñííght-łíghtš ƒöör thé ƒííréƒłý ñüüršérý~~~~~~~~~]';

  @override
  String get level_1_3_sender => '[Théé ƒírééƒłý ñüršéérý~~~~]';

  @override
  String get level_1_3_hint =>
      '[Šhöööt. Tááþ Šhöööt tö kñööçk öüüt bátš.~~~~~~]';

  @override
  String get level_1_4_name => '[Çáárñívááł Škíééš~~~]';

  @override
  String get level_1_4_cargo =>
      '[Fééáthéér böááš ƒör théé çárñííváł þááráðéé~~~~~~]';

  @override
  String get level_1_4_sender => '[Théé šámbáá máçááwš~~~]';

  @override
  String get level_1_4_hint =>
      '[Gááłé! Wáátçh thé ! ááñð ðöðgéé thé ƒööötbááłłš.~~~~~~~]';

  @override
  String get level_1_5_name => '[ÉÉxþréšš Þööšt~~~]';

  @override
  String get level_1_5_cargo =>
      '[ÅÅ rüšh ííñvítáátíööñ ƒör théé ðrüm çááþtáííñ~~~~~~]';

  @override
  String get level_1_5_sender => '[Théé ðrüm çááþtáííñ~~~]';

  @override
  String get level_1_5_hint =>
      '[Šþrííñt šmášhééš bátš ááñð šürgééš áhééáð.~~~~~~~~]';

  @override
  String get level_1_6_name => '[Téémþłé Štééþš~~~]';

  @override
  String get level_1_6_cargo => '[Çööçöáá béááñš ƒör théé témþłéé çööökš~~~~~]';

  @override
  String get level_1_6_sender => '[Théé témþłéé çööökš~~~]';

  @override
  String get level_1_7_name => '[Šüüñríšéé Röööšt~~]';

  @override
  String get level_1_7_cargo => '[ÅÅ šüñðííáł ƒöör thé ðááwñ kéééþér~~~~~]';

  @override
  String get level_1_7_sender => '[Théé ðáwñ kéééþéér~~~]';

  @override
  String get level_1_8_name => '[Bááröñ Báát~~]';

  @override
  String get level_1_8_cargo => '[ÅÅ ƒíñááł ñötííçé ƒöör Bárööñ Bát~~~~~]';

  @override
  String get level_1_8_sender => '[Bááröñ Báát~~]';

  @override
  String get level_2_1_name => '[Bééétłéé Röááð~]';

  @override
  String get level_2_1_cargo =>
      '[Łááürééł wréááthš ƒör théé çhárííöt rááçérš~~~~~~~]';

  @override
  String get level_2_1_sender => '[Théé çhárííöt rááçérš~~~~]';

  @override
  String get level_2_1_hint =>
      '[Bééétłééš šþít šéééðš. Šhöööt théé šéééðš ðöwñ.~~~~~~~~]';

  @override
  String get level_2_2_name => '[Šééáłééð Gátééš~~]';

  @override
  String get level_2_2_cargo =>
      '[ÅÅ ñéw çhííšéł ƒöör thé štáátüéé çárvéér~~~~~~]';

  @override
  String get level_2_2_sender => '[Théé štátüüé çáárvér~~~]';

  @override
  String get level_2_2_hint =>
      '[Hööłð Šhöööt ƒör áá bíg rööçk thát brééákš štööñé.~~~~~~~~]';

  @override
  String get level_2_3_name => '[Wííłðƒíréé Rüñ~~~]';

  @override
  String get level_2_3_cargo =>
      '[Wáátér büüçkétš ƒöör thé ƒííré bríígáðéé~~~~~~]';

  @override
  String get level_2_3_sender => '[Théé ƒíréé brígááðé~~~]';

  @override
  String get level_2_3_hint =>
      '[Fłý thrööügh théé göłð rííñgš tö ööütrüüñ thé ƒííré!~~~~~~~~~]';

  @override
  String get level_2_4_name => '[Ñííłé Šwíítçhbáçkš~~~~]';

  @override
  String get level_2_4_cargo =>
      '[ÅÅ bööök öƒ ñééw ríððłééš ƒör théé Šþhíñx~~~~~~~]';

  @override
  String get level_2_4_sender => '[Théé Šþhíñx~~~]';

  @override
  String get level_2_5_name => '[Škýƒááłł~~]';

  @override
  String get level_2_5_cargo =>
      '[ÅÅ téłééšçöþéé ƒör théé þýrámííð áštrööñöméér~~~~~~~]';

  @override
  String get level_2_5_sender => '[Théé þýrámííð áštrööñöméér~~~~]';

  @override
  String get level_2_5_hint => '[Rííñg šþríñtš šmáášh métééörš.~~~~~~~]';

  @override
  String get level_2_6_name => '[Réétürñ töö Šéñðéér~~~]';

  @override
  String get level_2_6_cargo =>
      '[ÅÅ ƒéááthér ðüüštér ƒöör thé çáárétáákér~~~~~~]';

  @override
  String get level_2_6_sender => '[Théé þýrámííð çáréétákéér~~~~]';

  @override
  String get level_2_6_hint =>
      '[Šhöööt hííš łéttéérš tö šééñð thém bááçk. Rétüürñ tö šééñðér!~~~~~~~~~~~]';

  @override
  String get level_2_7_name => '[Łááñtérñ Báážááár~~~]';

  @override
  String get level_2_7_cargo => '[Łáámþ öííł ƒör théé łáñtéérñ šéłłéérš~~~~~~]';

  @override
  String get level_2_7_sender => '[Théé łáñtéérñ šéłłéérš~~~~]';

  @override
  String get level_2_8_name => '[Théé Łöñg Çáárávááñ~~~]';

  @override
  String get level_2_8_cargo =>
      '[Wáátér ƒłááškš ƒör théé łöñg çáárávááñ~~~~~~~]';

  @override
  String get level_2_8_sender => '[Théé çárááváñ łééáðéér~~~]';

  @override
  String get level_2_9_name => '[Šþííttér Kííñg~~~]';

  @override
  String get level_2_9_cargo =>
      '[ÅÅ štöþ-brééwíñg öörðér ƒöör thé Šþííttér Kííñg~~~~~~~~]';

  @override
  String get level_2_9_sender => '[Šþííttér Kííñg~~~]';

  @override
  String get level_3_1_name => '[Mööth Łíght~~~]';

  @override
  String get level_3_1_cargo =>
      '[Łííght büłbš ƒöör thé thééátréé márqüüééé~~~~~~]';

  @override
  String get level_3_1_sender => '[Théé štágéé máñáágér~~~]';

  @override
  String get level_3_1_hint =>
      '[Mööthš ƒíréé ƒáñš ööƒ thrééé. Šłíþ béétwéééñ thém.~~~~~~~~]';

  @override
  String get level_3_2_name => '[Whéééłš ííñ thé Rááíñ~~~]';

  @override
  String get level_3_2_cargo =>
      '[ÛÛmbréłłááš ƒör théé ñéwšštááñð þígééöñš~~~~~~~~]';

  @override
  String get level_3_2_sender => '[Théé ñéwšštááñð þígééöñš~~~~~]';

  @override
  String get level_3_2_hint =>
      '[ÅÅłłéý þíígéööñš šwöööþ íñ töö gráb štáárš. Šhöööt thém ƒííršt!~~~~~~~~~~]';

  @override
  String get level_3_3_name => '[Štééám ÅÅłłéý~~]';

  @override
  String get level_3_3_cargo =>
      '[Hööt þrétžééłš ƒör théé ñíght-šhííƒt çábbííéš~~~~~~~~~]';

  @override
  String get level_3_3_sender => '[Théé ñíght çáábbíééš~~~]';

  @override
  String get level_3_3_hint =>
      '[Vééñtš híšš, thééñ büršt. Hööþ thé hööt öñééš, ríðéé thé šööƒt öñééš.~~~~~~~~~~~]';

  @override
  String get level_3_4_name => '[Štöörm Wárñííñg~~~]';

  @override
  String get level_3_4_cargo =>
      '[ÅÅ wéááthér vááñé ƒöör thé tááłłéšt tööwér~~~~~~]';

  @override
  String get level_3_4_sender => '[Théé töwéér kéééþér~~~]';

  @override
  String get level_3_4_hint =>
      '[Štááý öüüt öƒ théé łíght. Šhöööt théé łámþ whééñ ít ööþéñš! Ñöö Šþríñt hééré.~~~~~~~~~~~~]';

  @override
  String get level_3_5_name => '[Çrýštááł Röööƒtöþš~~~~]';

  @override
  String get level_3_5_cargo =>
      '[Çrööíššááñtš ƒör théé röööƒtöþ þááíñtéérš~~~~~~~]';

  @override
  String get level_3_5_sender => '[Théé röööƒtöþ þááíñtéérš~~~~]';

  @override
  String get level_3_6_name => '[ÅÅƒtér théé Gáłéé~~]';

  @override
  String get level_3_6_cargo =>
      '[Šhééét müüšíç ƒöör thé ááççörðííöñ þłááýér~~~~~~~]';

  @override
  String get level_3_6_sender => '[Théé áççöörðíööñ þłáýéér~~~~]';

  @override
  String get level_3_6_hint =>
      '[Gááłé! Wáátçh thé ! ááñð tákéé thé ööþéñ šííðé.~~~~~~]';

  @override
  String get level_3_7_name => '[Mííðñíght ÉÉxþréšš~~~~]';

  @override
  String get level_3_7_cargo =>
      '[ÅÅ míðñííght łövéé łéttéér ƒör théé bákéér~~~~~~]';

  @override
  String get level_3_7_sender => '[Théé bákéér~~]';

  @override
  String get level_3_7_hint => '[Šþrííñt thröüügh thé ƒłööçkš.~~~~~~]';

  @override
  String get level_3_8_name => '[Ðüüšk Émþrééšš~~~]';

  @override
  String get level_3_8_cargo =>
      '[ÅÅ wákéé-üþ çááłł ƒör théé Ðüšk ÉÉmþréšš~~~~~~~]';

  @override
  String get level_3_8_sender => '[Ðüüšk Émþrééšš~~~]';

  @override
  String get level_4_1_name => '[Háárböüür Łíghtš~~~~]';

  @override
  String get level_4_1_cargo =>
      '[ÅÅ ñéw łééñš ƒör théé łíghthööüšéé kéééþér~~~~~~]';

  @override
  String get level_4_1_sender => '[Théé łíghthööüšéé kéééþér~~~~]';

  @override
  String get level_4_2_name => '[Vööłçáñöö Þášš~~~]';

  @override
  String get level_4_2_cargo => '[ØØvéñ mííttš ƒör théé vöłçááñö báákér~~~~~~]';

  @override
  String get level_4_2_sender => '[Théé vöłçááñö báákér~~~]';

  @override
  String get level_4_2_hint => '[Hööþ övéér thé łáává þłüüméš.~~~~]';

  @override
  String get level_4_3_name => '[Ðööwñ thé Çööášt~~~]';

  @override
  String get level_4_3_cargo =>
      '[Kííté štrííñg ƒör théé béááçh ƒéštííváł~~~~~~~]';

  @override
  String get level_4_3_sender => '[Théé kítéé ƒłýérš~~~~]';

  @override
  String get level_4_4_name => '[Łööw Wátéér~~]';

  @override
  String get level_4_4_cargo => '[ÅÅ réþłý ƒöör thé ííšłáñð héérmít~~~~~~]';

  @override
  String get level_4_4_sender => '[Théé íšłááñð hérmíít~~~]';

  @override
  String get level_4_4_hint => '[Ðööñ\'t töüüçh thé wáátér.~~~~]';

  @override
  String get level_4_5_name => '[Šþrííñg Tíðéé~~]';

  @override
  String get level_4_5_cargo => '[ÅÅ tíðéé tábłéé ƒör théé ƒérrý çrééw~~~~~]';

  @override
  String get level_4_5_sender => '[Théé ƒérrý çrééw~~~]';

  @override
  String get level_4_5_hint => '[Whééñ thé bééłł ríñgš, ƒłý híígh.~~~~~~~]';

  @override
  String get level_4_6_name => '[Brööáðšííðé Bááý~~]';

  @override
  String get level_4_6_cargo =>
      '[Fííšh bíšçüüítš ƒöör thé güüłł çöłööñý~~~~~~~]';

  @override
  String get level_4_6_sender => '[Théé güłł çööłöñý~~~~]';

  @override
  String get level_4_7_name => '[Štöörmý Çröššííñg~~~~]';

  @override
  String get level_4_7_cargo =>
      '[Ðrý šööçkš ƒör théé štörm-wáátçh šáííłörš~~~~~~~~~]';

  @override
  String get level_4_7_sender => '[Théé štörm wáátçh~~~~]';

  @override
  String get level_4_8_name => '[Þíírátéé Çáþtááíñ~~~]';

  @override
  String get level_4_8_cargo =>
      '[ÅÅ rétüürñ-thé-mááíł öörðér ƒöör thé Çááþtáííñ~~~~~~]';

  @override
  String get level_4_8_sender => '[Þíírátéé Çáþtááíñ~~~]';

  @override
  String get level_5_1_name => '[ÅÅüröörá Þööšt~]';

  @override
  String get level_5_1_cargo =>
      '[Wöööłłý háátš ƒör théé þéñgüüíñ çhööír~~~~~~~]';

  @override
  String get level_5_1_sender => '[Théé þéñgüüíñ çhööír~~~]';

  @override
  String get level_5_1_hint =>
      '[ÅÅñý rüšh çááñ çöméé ñöw. Rééáð théé báññéér!~~~~~~]';

  @override
  String get level_5_2_name => '[Þööłár Ñííght~~]';

  @override
  String get level_5_2_cargo => '[Hööt çöçööá ƒöör thé þööłár štáátíööñ~~~~~]';

  @override
  String get level_5_2_sender => '[Théé þöłáár štátííöñ~~~]';

  @override
  String get level_5_3_name => '[Ñééöñ ÉÉxþréšš~~~]';

  @override
  String get level_5_3_cargo =>
      '[Šþááré ƒüüšéš ƒöör thé ñöööðłéé bár šíígñ~~~~~~]';

  @override
  String get level_5_3_sender => '[Théé ñöööðłé çhééƒ~~~]';

  @override
  String get level_5_4_name => '[Ðáátá Štöörm~~]';

  @override
  String get level_5_4_cargo =>
      '[ÅÅ þáþéér łéttéér ƒör áá çürííöüüš röbööt~~~~~]';

  @override
  String get level_5_4_sender => '[ÛÛñít 7~]';

  @override
  String get level_5_5_name => '[Škýłííñé Šþrííñt~~~~]';

  @override
  String get level_5_5_cargo =>
      '[Rááçé tííçkétš ƒöör thé röööƒtööþ rüññéérš~~~~~~~]';

  @override
  String get level_5_5_sender => '[Théé röööƒtöþ rüüññérš~~~~]';

  @override
  String get level_5_6_name => '[Łááñtérñ Fééštívááł~~~]';

  @override
  String get level_5_6_cargo => '[Þááþér łááñtérñš ƒöör thé ƒééštívááł~~~~~~]';

  @override
  String get level_5_6_sender => '[Théé łáñtéérñ mákéérš~~~~]';

  @override
  String get level_5_7_name => '[Théé Łášt Łéég~~]';

  @override
  String get level_5_7_cargo => '[Mööüñtááíñ tééá ƒöör thé mööñáštéérý~~~~~]';

  @override
  String get level_5_7_sender => '[Théé möüüñtáííñ möñkš~~~~]';

  @override
  String get level_5_8_name => '[ÉÉmbér Ðráágöñ~~~]';

  @override
  String get level_5_8_cargo =>
      '[Théé ƒíršt łééttér éévér šééñt tö théé Ðrágööñ~~~~~~~~]';

  @override
  String get level_5_8_sender => '[ÉÉmbér Ðráágöñ~~~]';

  @override
  String get storyPostmasterName => '[Þööštmáštéér Bíłł~~~~]';

  @override
  String get storySkip => '[Škííþ~]';

  @override
  String get storyNextLineSemantics => '[Ñééxt łíñéé~~]';

  @override
  String get storyFinishSemantics => '[Fííñíšh~~]';

  @override
  String storyLineSemantics(String name, String line) {
    return '[$name: $line~~~~]';
  }

  @override
  String get campaignMotto => '[ÉÉvérý łééttér łááñðš.~~~~]';

  @override
  String launchSemantics(String brand, String motto) {
    return '[$brand. $motto~~~~]';
  }

  @override
  String get levelIntroFly => '[Fłý!~~]';

  @override
  String levelIntroRunUp(int seconds) {
    return '[ÅÅ $seconds š rüñ-üüþ ƒíršt~~~~~]';
  }

  @override
  String levelIntroLength(int seconds) {
    return '[ÅÅböüüt $seconds š tö théé ƒíñííšh~~~~~]';
  }

  @override
  String get campaignGuardian => '[GÛÛÅRÐÎÎÅÑ~~]';

  @override
  String get levelIntroBossFight => '[BØØŠŠ FÎGHT~~~]';

  @override
  String get levelIntroNew => '[ÑÉÉW~]';

  @override
  String get levelIntroTip => '[TÎÎÞ~]';

  @override
  String levelIntroGoalBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {'other': 'Bééát $boss'});
    return '[$_temp0~~~]';
  }

  @override
  String get levelIntroGoalFinish => '[Rééáçh théé ƒíñííšh~~~]';

  @override
  String levelIntroGoalCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çöłłééçt $count štárš',
      one: 'Çööłłéçt 1 štáár',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String levelIntroGoalSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'ØØñé štáár: $goal.',
      'two': 'Twö štáárš: $goal.',
      'other': 'Thrééé štárš: $goal.',
    });
    return '[$_temp0~~~~~]';
  }

  @override
  String levelIntroGoalEarnedSemantics(String stars, String goal) {
    String _temp0 = intl.Intl.selectLogic(stars, {
      'one': 'ØØñé štáár: $goal. Éáárñéð.',
      'two': 'Twöö štárš: $goal. ÉÉárñééð.',
      'other': 'Thrééé štárš: $goal. ÉÉárñééð.',
    });
    return '[$_temp0~~~~~]';
  }

  @override
  String levelIntroBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bééšt: $count štárš',
      one: 'Bééšt: 1 štár',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String get levelIntroNotDelivered => '[Ñööt ðéłíívérééð ýét~~~]';

  @override
  String get levelIntroFirstFlight => '[Fííršt ƒłíght~~~~]';

  @override
  String get levelIntroControlFlap => '[Fłááþ~]';

  @override
  String get levelIntroControlShoot => '[Šhöööt~]';

  @override
  String get levelIntroControlSprint => '[Šþrííñt~~]';

  @override
  String levelIntroControlsSemantics(String controls) {
    String _temp0 = intl.Intl.selectLogic(controls, {
      'flap': 'Çööñtröłš: Fłááþ.',
      'shoot': 'Çöñtrööłš: Fłáþ, Šhöööt.',
      'sprint': 'Çööñtröłš: Fłááþ, Šþríñt.',
      'other': 'Çööñtröłš: Fłááþ, Šhöööt, Šþríñt.',
    });
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String get levelIntroSpecialDelivery => '[ŠÞÉÉÇÎÅÅŁ ÐÉŁÎÎVÉRÝ~~~]';

  @override
  String levelIntroCargoSemantics(String cargo) {
    return '[Šþééçíááł ðéłíívérý: $cargo.~~~~~]';
  }

  @override
  String levelIntroSemantics(String level, String name, String region) {
    return '[Łéévéł $level, $name. $region.~~~~~~]';
  }

  @override
  String levelIntroGuardianSemantics(
    String level,
    String name,
    String region,
    String boss,
  ) {
    return '[Łéévéł $level, $name. $region. Güüárðííáñ łéévéł: $boss.~~~~~~~~~~]';
  }

  @override
  String get levelIntroStory => '[Štöörý~]';

  @override
  String get commonClose => '[Çłööšé~]';

  @override
  String get commonContinue => '[Çööñtíñüüé~~]';

  @override
  String get commonHome => '[Höömé~]';

  @override
  String get commonBackHome => '[Bááçk höméé~~]';

  @override
  String get campaignComingSoon => '[Çöömíñg šöööñ~~]';

  @override
  String campaignStopComingSoon(String region) {
    return '[$region — çöömíñg šöööñ~~~~]';
  }

  @override
  String campaignLockedBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'other': 'Bééát $boss töö üñłööçk',
    });
    return '[$_temp0~~~~]';
  }

  @override
  String campaignLockedFinish(String level) {
    return '[Fííñíšh $level töö üñłööçk~~~~~]';
  }

  @override
  String get campaignMapUnavailable => '[Théé máþ ñéééðš áá mömééñt.~~~~]';

  @override
  String campaignCloseLevelSemantics(String name) {
    return '[Çłööšé $name~~~]';
  }

  @override
  String get campaignMapPreviousStop => '[Þréévíööüš štööþ~~]';

  @override
  String get campaignMapNextStop => '[Ñééxt štöþ~~~]';

  @override
  String campaignMapStopSemantics(
    String state,
    String region,
    int chapter,
    String route,
  ) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'soon': '$region. Çhááþtér $chapter, $route. Çöömíñg šöööñ.',
      'locked': '$region. Çhááþtér $chapter, $route. Łööçkéð.',
      'other': '$region. Çhááþtér $chapter, $route.',
    });
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String campaignMapChapterBanner(int chapter, String route) {
    return '[ÇHÅÅÞTÉR $chapter · $route~~~~~]';
  }

  @override
  String campaignMapNodeSemantics(
    String kind,
    String level,
    String name,
    String boss,
  ) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boss': '$level, $name, bööšš',
      'guardian': 'Łévééł $level, $name, güáárðíááñ $boss',
      'other': 'Łévééł $level, $name',
    });
    return '[$_temp0~~~~~~~~~]';
  }

  @override
  String campaignMapNodeLocked(String node) {
    return '[$node. Łööçkéð.~~~]';
  }

  @override
  String campaignMapNodeLockedNote(String node, String note) {
    return '[$node. Łööçkéð. $note.~~~~~]';
  }

  @override
  String campaignMapNodeNext(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars ööƒ 3 štárš',
    );
    return '[$node. Ñééxt üþ. $_temp0.~~~~~~~]';
  }

  @override
  String campaignMapNodeStars(String node, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars ööƒ 3 štárš',
    );
    return '[$node. $_temp0.~~~~~]';
  }

  @override
  String campaignMapGuardianShort(String boss, String name) {
    String _temp0 = intl.Intl.selectLogic(boss, {
      'searchlightGargoyle': 'Gáárgöýłéé',
      'other': '$name',
    });
    return '[$_temp0~~~]';
  }

  @override
  String campaignMapPostcardSemantics(int chapter) {
    return '[Çhááþtér $chapter þööštçárð~~~~~~]';
  }

  @override
  String campaignStarTotalSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$stars ööƒ $total çámþááígñ štáárš',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get campaignPostcardGreeting => '[Ðééár çööürííér,~~]';

  @override
  String get campaignPostcardPs => '[Þ.Š.~]';

  @override
  String campaignPostcardSemantics(
    String route,
    String body,
    String postscript,
  ) {
    return '[Þööštçárð ƒrööm $route. Ðéáár çöüüríéér, $body Þ.Š. $postscript~~~~~~~~~~]';
  }

  @override
  String get campaignPostcardGreetingsFrom => '[Grééétííñgš ƒröm~~~~]';

  @override
  String get campaignPostcardHeader => '[ŠKÝ ÇŁÛÛB ÞØŠTÇÅÅRÐ~~~~]';

  @override
  String campaignPostcardSignature(String route) {
    return '[— $route~~]';
  }

  @override
  String get campaignPostcardAddressName => '[Théé çöüüríéér~]';

  @override
  String get campaignPostcardAddressStreet => '[Šký Çłüüb þöšt~~~~]';

  @override
  String get campaignPostcardAddressCity => '[ÛÛþ íñ théé šký~~]';

  @override
  String get campaignPostmarkDelivered => '[ÐÉÉŁÎVÉÉRÉÐ~~]';

  @override
  String get campaignPostmarkClub => '[ŠKÝ ÇŁÛÛB ÞØŠT~~~~]';

  @override
  String get campaignStampSkyClub => '[ŠKÝ ÇŁÛÛB~~]';

  @override
  String campaignThanksQuoted(String thanks) {
    return '[“$thanks”~~]';
  }

  @override
  String campaignThanksSignature(String sender) {
    return '[— $sender~~]';
  }

  @override
  String campaignThanksSemantics(String sender, String thanks) {
    return '[Thááñk-ýöüü ñötéé ƒröm $sender: $thanks~~~~~~~]';
  }

  @override
  String get flightSetupTitlePushUp =>
      '[ÅÅ łíttłéé šétüüþ. Å łööt öƒ šký.~~~~~]';

  @override
  String get flightSetupTitleSquat => '[Fééét þłááñtéð. Wííñgš öþééñ.~~~~]';

  @override
  String get flightSetupTitleJump => '[Šmááłł jümþš. Bííg wíñgš.~~~~~~]';

  @override
  String flightSetupBuiltTag(String name) {
    return '[ŁÉÉVÉŁ · $name~~~]';
  }

  @override
  String flightSetupScoredTag(String course) {
    return '[$course · ŠÇØØRÉÐ~~~]';
  }

  @override
  String get flightSetupRoomPushUp => '[Mááké áá łíttłéé röööm tö möövé.~~~~]';

  @override
  String get flightSetupRoomBody => '[Šhööw ýöüür whöłéé böðý.~~~~]';

  @override
  String get flightSetupTipsPushUp =>
      '[Þhööñé łööw. Šhöw ááñ árm ááñð híþ.\nFááçíñg íít? Kéééþ böth šhööüłðéérš íñ vííéw.~~~~~~~~~~~~]';

  @override
  String get flightSetupTipsSquat =>
      '[Šqüüát töö ðéšçééñð. Štáñð töö ríšéé.\nKéééþ böth ƒééét ööñ thé ƒłööör.~~~~~~~~~~]';

  @override
  String get flightSetupTipsJump =>
      '[Jüümþ ƒör áá böööšt + 3š głíðéé.\nŁáñð bééƒöréé jümþííñg ágááíñ.~~~~~~~~~]';

  @override
  String get flightSetupHowToFly => '[HØØW TØ FŁÝ~~~]';

  @override
  String get flightSetupStep1PushUp => '[Šhööw ýöüür árm ááñð híþ~~~~]';

  @override
  String get flightSetupStep1Squat => '[Mááké röööm töö šqüáát~~]';

  @override
  String get flightSetupStep1Jump => '[Mááké röööm töö jümþ~~~]';

  @override
  String get flightSetupStep1DetailPushUp =>
      '[Fááçíñg théé þhöñéé? Šhöw bööth šhöüüłðérš, ööñé áárm áñð áá híþ.~~~~~~~~~~]';

  @override
  String get flightSetupStep1DetailBody =>
      '[Þhööñé ííñ łáñðšçááþé. Šhööw ýöüür böðý ááñð böth ƒééét.~~~~~~~~~]';

  @override
  String get flightSetupStep2PushUp => '[Fííñð ýöüür mövééméñt rááñgé~~~~~]';

  @override
  String get flightSetupStep2Squat => '[Fííñð ýöüür çömƒöörtábłéé šqüáát~~~~~]';

  @override
  String get flightSetupStep2Jump => '[Štááñð táłł ááñð štíłł~~~~~]';

  @override
  String get flightSetupStep2DetailPushUp =>
      '[Fííñð á çöömƒörtáábłé tööþ, théñ möövé ðööwñ áñð üüþ twíçéé.~~~~~~~~~]';

  @override
  String get flightSetupStep2DetailSquat =>
      '[Štááñð štíłł, šqüüát ááñð höłð brííéƒłý, thééñ štáñð bááçk üþ.~~~~~~~~~~~~]';

  @override
  String get flightSetupStep2DetailJump =>
      '[Hööłð štíłł brííéƒłý. Thééñ jümþ ƒöör á bííg böööšt.~~~~~~~~~]';

  @override
  String get flightSetupStep3Stars => '[Çööłłéçt štáárš~~~]';

  @override
  String get flightSetupStep3DetailJump =>
      '[Štáárš áðð 0.75š ööƒ głíðéé, üþ töö 5š. Çöłłééçt tríööš ƒör +5 þööíñtš.~~~~~~~~~~]';

  @override
  String get flightSetupLivesEndless =>
      '[Thrééé hééártš + áá šhíééłð. Ýöüü çáñ þááüšéé áñý tíímé.~~~~~~~]';

  @override
  String get flightSetupLivesClassic =>
      '[ÅÅ çöłłííšíööñ ör łööšíñg ýööür þööšítííöñ ééñðš á šçööréð ƒłííght. Ýöüü çáñ þááüšéé áñý tíímé.~~~~~~~~~~~~]';

  @override
  String get flightSetupCameraButton => '[Šéét üþ mý çááméráá~~~]';

  @override
  String get flightMicTitle => '[Rééçörð mííçröþhööñé~~~~]';

  @override
  String get flightMicOn => '[ØØñ]';

  @override
  String get flightMicOptional => '[ØØþtíööñáł~~]';

  @override
  String get flightMicDetail =>
      '[ÅÅðð ýöüür vöííçé ááñð röööm šöüüñð tö rééþłáýš. ÛÛšéš théé míçrööþhöñéé ðürííñg ƒłíght ööñłý. Šávééð öñ thííš þhöñéé.~~~~~~~~~~~~~~~~~]';

  @override
  String get flightMicSemantics => '[Rééçörð mííçröþhööñé ƒöör réþłááýš~~~~~~]';

  @override
  String get flightMicSettings => '[Mííçröþhööñé šééttíñgš~~~~~]';

  @override
  String get flightCalibrationTitleReady => '[Ýööü ƒööüñð ýööür wííñgš!~~~]';

  @override
  String get flightCalibrationTitleWaking => '[Wáákíñg üüþ ýöüür çáméérá…~~~~]';

  @override
  String get flightCalibrationTitleError =>
      '[Łéét’š réçööññéçt ýööür çááméráá.~~~~~]';

  @override
  String get flightCalibrationTitleRange =>
      '[Fííñð ýöüür mövééméñt rááñgé.~~~~~]';

  @override
  String get flightCalibrationTitleStill => '[Štááñð táłł ááñð štíłł.~~~~~]';

  @override
  String get flightCalibrationStepTry => '[Trý möövíñg ýööür bíírð.~~~~]';

  @override
  String get flightCalibrationStepTop => '[Fííñð á çöömƒörtáábłé tööþ.~~~~]';

  @override
  String get flightCalibrationStepLower => '[Łööwér ýööüršééłƒ šłöwłý.~~~~~]';

  @override
  String get flightCalibrationStepPushBack => '[Þüüšh báçk üüþ.~~]';

  @override
  String get flightCalibrationStepStill => '[Štááñð táłł ááñð štíłł.~~~~~]';

  @override
  String get flightCalibrationStepSquat => '[Šqüüát çöömƒörtáábłý.~~~~]';

  @override
  String get flightCalibrationStepStandUp => '[Štááñð báçk üüþ.~~~]';

  @override
  String get flightCalibrationStepDone => '[Ýööü ƒööüñð ýööür wííñgš!~~~]';

  @override
  String get flightCalibrationReadyPushUp =>
      '[Þüüšh üþ töö ríšéé. Łöwéér tö głííðé.~~~~~]';

  @override
  String get flightCalibrationReadySquat =>
      '[Šqüüát töö ðéšçééñð. Štáñð töö ríšéé.~~~~~]';

  @override
  String get flightCalibrationReadyJump =>
      '[Jüümþ, théñ rééšt whíłéé ýöüür bírð głííðéš.~~~~~~~~]';

  @override
  String get flightCalibrationKeepPushUp =>
      '[Kéééþ ýööür šhööüłðéérš, öñéé árm ááñð á hííþ íñ vííéw. Möövé çöömƒörtáábłý.~~~~~~~~~~]';

  @override
  String get flightCalibrationKeepBody =>
      '[Kéééþ ýööür šhööüłðéérš, híþš ááñð böth ƒééét ííñ víééw.~~~~~~~~]';

  @override
  String get flightCalibrationLearning =>
      '[Łééárñííñg ýöüür ráñgéé áš ýööü möövé.~~~~~]';

  @override
  String get flightCalibrationAfter =>
      '[Ýööür bíírð mövééš áƒtéér çáłííbrátííöñ.~~~~~~]';

  @override
  String get flightCalibrationJump => '[Jüümþ!~]';

  @override
  String get flightCalibrationTagCheck => '[ÇØØÑTRØŁ ÇHÉÉÇK~~~]';

  @override
  String flightCalibrationTagPushUps(int count) {
    return '[$count / 2 ÞÛÛŠH-ÛÞŠ~~~~]';
  }

  @override
  String flightCalibrationTagPercent(int percent) {
    return '[$percent% ÇÅÅŁÎBRÅÅTÉÐ~~~~]';
  }

  @override
  String get flightCalibrationTakeoff => '[Rééáðý ƒöör tákééöƒƒ~~~]';

  @override
  String get flightCalibrationStarting => '[Štáártíñg…~~~]';

  @override
  String get flightCalibrationRestart => '[Štáárt çáłííbrátííöñ áágáííñ~~~~]';

  @override
  String flightCalibrationMetrics(String rate, String p95) {
    return '[$rate üüþðátééš/š · $p95 mš þ95~~~~~~]';
  }

  @override
  String flightCalibrationMetricsProcessing(String rate, String p95) {
    return '[$rate üüþðátééš/š · $p95 mš þ95 (þröçééššíñg ööñłý)~~~~~~~~~~]';
  }

  @override
  String get flightCalibrationStatusReady => '[RÉÉÅÐÝ~]';

  @override
  String get flightCalibrationStatusStarting => '[ŠTÅÅRTÎÑG~~~]';

  @override
  String get flightCalibrationStatusCameraOff => '[ÇÅÅMÉRÅÅ ØFF~~]';

  @override
  String get flightCalibrationStatusCalibrating => '[ÇÅÅŁÎBRÅÅTÎÑG~~~]';

  @override
  String get flightSwitchCameraSemantics => '[Šwíítçh çáméérá~~~]';

  @override
  String get flightCalibrationStepIntoView => '[Štééþ íñtöö víééw~~]';

  @override
  String get flightCameraTroubleTitle =>
      '[ÅÅ ƒréšh štáárt üšüüáłłý hééłþš.~~~~~~]';

  @override
  String get flightCameraTroubleAllow =>
      '[ÅÅłłöw çááméráá áççééšš íñ Šééttíñgš.~~~~~~]';

  @override
  String get flightCameraTroubleClose =>
      '[Çłööšé ááñý öthéér çáméérá ááþþ, théñ trý áágáííñ.~~~~~~~]';

  @override
  String get flightCameraPermissionSemantics =>
      '[Çááméráá þérmííššíööñ šéttííñgš~~~~~]';

  @override
  String get flightNoteRememberFailed =>
      '[Çhááñgéð ƒöör thíš ƒłííght. Çöüüłð ñöt réémémbéér ýöüür þréƒééréñçéé.~~~~~~~~~~~]';

  @override
  String get flightNoteMicUnavailable =>
      '[Mííçröþhööñé üüñávááíłáábłé. Vííðéöö áñð gááméþłááý štíłł wöörk.~~~~~~~~~]';

  @override
  String get flightNoteMicBlocked =>
      '[Mííçröþhööñé błööçkéð. Ýööü çááñ áłłööw ít ííñ Šéttííñgš; víðééö štííłł wörkš.~~~~~~~~~~~~]';

  @override
  String get flightNoteMicOff =>
      '[Mííçröþhööñé ööƒƒ. Ýöüü çáñ štííłł þłáý ááñð šávéé víðééö.~~~~~~~~]';

  @override
  String get flightNoteVideoUnavailable =>
      '[Çááméráá víðééö üüñávááíłáábłé. Gááméþłááý çáñ štííłł bé šáávéð.~~~~~~~~]';

  @override
  String get flightNoteMicAudioLost =>
      '[Mííçröþhööñé ááüðííö wááš üñááváííłábłéé. Ýöüür víðééö ááñð gámééþłáý çááñ štíłł béé šávééð.~~~~~~~~~~~]';

  @override
  String get flightNoteVideoInterrupted =>
      '[Çááméráá víðééö ííñtérrüüþtéð. ÅÅváííłábłéé ƒööötágéé áñð gááméþłááý çáñ štííłł bé šáávéð.~~~~~~~~~~~~]';

  @override
  String get flightNoteSessionSaveFailed =>
      '[Çööüłð ñööt šávéé thé šééššíööñ. Táþ Šáávé šééššíööñ tö réétrý.~~~~~~~~~]';

  @override
  String get flightNoteWakingCamera => '[Wáákíñg üüþ ýöüür çáméérá…~~~~]';

  @override
  String get flightNoteCameraOff =>
      '[Çááméráá áççééšš íš ööƒƒ. Åłłööw ít ííñ Åñðrööíð šééttíñgš, thééñ çöméé báçk ááñð trý ágááíñ.~~~~~~~~~~~~~~]';

  @override
  String get flightNoteCameraFailed =>
      '[Théé çáméérá çööüłð ñööt štárt. Trý áágáííñ ör šwíítçh çámééráš.~~~~~~~~~~]';

  @override
  String get flightNotePreparing => '[Þrééþárííñg ýöüür šéššííöñ…~~~~]';

  @override
  String get flightNoteSaveFailed =>
      '[Çööüłð ñööt šávéé ýöüür ƒłíght. Tááþ tö réétrý.~~~~~~~]';

  @override
  String get flightNoteWelcomeBack =>
      '[Wééłçöméé báçk. Łéét’š çhéçk ýööür þööšítííöñ áágáííñ.~~~~~~~]';

  @override
  String get flightNoteCameraInterrupted =>
      '[Çááméráá íñtéérrüþtééð. Çhéçk çááméráá þérmííššíööñ áñð trý áágáííñ.~~~~~~~~~~]';

  @override
  String get flightNoteTrackingInterrupted => '[Trááçkíñg ííñtérrüüþtéð~~~~~]';

  @override
  String get flightFindPosition => '[Fííñð ýöüür þöšíítíööñ~~~]';

  @override
  String get flightTapSemantics => '[Tááþ tö ƒłááþ~~]';

  @override
  String flightTapVanguardSemantics(String group) {
    return '[Tááþ tö ƒłááþ. $group ƒłý íñ ááhéááð öƒ thééír bööšš~~~~~~~~]';
  }

  @override
  String flightTapBossSemantics(String boss, int hp, int maxHp) {
    return '[Tááþ tö ƒłááþ. $boss: $hp öƒ $maxHp hééáłth~~~~~~~~~]';
  }

  @override
  String flightTapBossHintSemantics(
    String boss,
    int hp,
    int maxHp,
    String hint,
  ) {
    return '[Tááþ tö ƒłááþ. $boss: $hp öƒ $maxHp hééáłth. $hint~~~~~~~~~~~]';
  }

  @override
  String get flightSkipToResultsSemantics => '[Škííþ tö rééšüłtš~~~~]';

  @override
  String get hudPauseSemantics => '[Þááüšéé ƒłíght~~~]';

  @override
  String get flightHintTestSteerKeys =>
      '[Tééšt ƒłíght: ÛÛþ áñð Ðööwñ štééér.~~~~~~]';

  @override
  String get flightHintTestSteerDrag =>
      '[Tééšt ƒłíght: ðráág üþ ááñð ðöwñ töö štééér.~~~~~~~]';

  @override
  String get flightHintTestJumpKeys =>
      '[Tééšt ƒłíght: Šþááçé ƒöör á jüümþ.~~~~~~]';

  @override
  String get flightHintTestJumpTap => '[Tééšt ƒłíght: tááþ ƒör áá jümþ.~~~~~~]';

  @override
  String get flightHintKeysStars =>
      '[Šþááçé töö ƒłáþ. Fłý thrööügh théé štárš.~~~~~~~~]';

  @override
  String get flightHintKeysShoot =>
      '[Šþááçé töö ƒłáþ. Hööłð Ð tö çháárgé áá šhöt.~~~~~~~]';

  @override
  String get flightHintKeysCombat =>
      '[Šþááçé töö ƒłáþ. Hööłð Ð tö çháárgé áá šhöt. ÅÅ tö šþrííñt!~~~~~~~~~]';

  @override
  String get flightHintKeysPause => '[Šþááçé töö ƒłáþ. ÉÉšç þáüüšéš.~~~~]';

  @override
  String get flightHintTapStars =>
      '[Tááþ thé šký töö ƒłáþ. Fłý thrööügh théé štárš.~~~~~~~~~~]';

  @override
  String get flightHintTapShoot =>
      '[Tááþ thé šký töö ƒłáþ. Hööłð Šhöööt tö çháárgé.~~~~~~~~]';

  @override
  String get flightHintTapCombat =>
      '[Tááþ thé šký töö ƒłáþ. Hööłð Šhöööt tö çháárgé. Šþrííñt tö šmáášh!~~~~~~~~~~~]';

  @override
  String get flightHintTapRelease =>
      '[Tááþ tö ƒłááþ. Réłééášéé bétwéééñ tááþš.~~~~~]';

  @override
  String get flightHintTrail =>
      '[Fööłłöw théé štárš. Ýööür šhííéłð ííš réááðý.~~~~~~~]';

  @override
  String get flightHintSky => '[Théé šký íš ýööürš.~~~~]';

  @override
  String hudClockSemantics(String time) {
    return '[$time réémáííñíñg~~~~]';
  }

  @override
  String flightSeconds(String seconds) {
    return '[$secondsš~~]';
  }

  @override
  String hudMagnetActiveSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Štáár mágñéét: $seconds šéçööñðš rémááíñííñg',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String hudMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Máágñét çháárgíñg: $charge ööƒ $gates þérƒééçt gátééš',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get hudFindingYou => '[Fííñðíñg ýööü…~~]';

  @override
  String get hudShoot => '[Šhöööt~]';

  @override
  String get hudSprint => '[Šþrííñt~~]';

  @override
  String get flightTestNothingSaved => '[ñööthíñg ííš šávééð~~~]';

  @override
  String get flightCountdownReady => '[Rééáðý, štééáðý…~~~]';

  @override
  String get flightPauseTitle => '[Tááké áá bréááthér.~~~]';

  @override
  String get flightPauseKeepFlying => '[Kéééþ ƒłýííñg~~]';

  @override
  String flightPausedLevel(String id, String name) {
    return '[$id · $name. Ýööür bíírð íš þéérçhéð ááñð wáíítíñg.~~~~~~~~~]';
  }

  @override
  String flightPausedTest(String name) {
    return '[Tééšt ƒłíght ööƒ $name. Ñöthííñg íš šáávéð.~~~~~~~~]';
  }

  @override
  String flightPausedBuilt(String name) {
    return '[$name. Ýööür bíírð íš þéérçhéð ááñð wáíítíñg.~~~~~~~~]';
  }

  @override
  String get flightPausedTouch =>
      '[Ýööür bíírð íš þéérçhéð ááñð wáíítíñg. Wéé’łł çöüüñt ýöüü báçk ííñ.~~~~~~~~~]';

  @override
  String get flightPausedCamera =>
      '[Šhááké íít öüüt, théñ géét báçk ííñ þöšíítíööñ. Wé’łł çööüñt ýööü ííñ.~~~~~~~~]';

  @override
  String get flightPauseEdit => '[ÉÉðít~]';

  @override
  String get flightPauseBuilder => '[Büüíłðéér~]';

  @override
  String get flightPauseFinish => '[Fííñíšh ƒłííght~~~]';

  @override
  String get hudShieldRecovering => '[Rééçövééríñg~~]';

  @override
  String get hudShieldReady => '[Šhííéłð rééáðý~~~]';

  @override
  String hudShieldChargingSemantics(int charge, int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Šhííéłð çháárgíñg: $charge ööƒ $stars štárš',
    );
    return '[$_temp0~~~~~~~~~]';
  }

  @override
  String hudHeartsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hééártš réémáííñíñg',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String get hudSprinting => '[Šþrííñtíñg~~~]';

  @override
  String get hudSprintReady => '[Rééáðý~]';

  @override
  String hudSprintRecharging(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Rééçhárgííñg, $seconds šéçööñðš',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String get hudSprintHint =>
      '[Rüüšh áhééáð töö šmášh báátš áñð štööñé þááñéłš~~~~~~~~]';

  @override
  String get hudShotReloading => '[Rééłöááðíñg…~~]';

  @override
  String hudShotFullCharge(int ms) {
    return '[Füüłł çhárgéé, $ms mš łéƒt~~~~~~]';
  }

  @override
  String hudShotCharging(int percent) {
    return '[Çháárgíñg $percent%~~~~]';
  }

  @override
  String hudShotAmmo(int percent) {
    return '[ÅÅmmö $percent%~~~]';
  }

  @override
  String get hudShotHint => '[Hööłð tö çháárgé áá bíggéér röçk~~~~~~]';

  @override
  String hudMarkReachedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count štáárš réááçhéð',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String hudMarkAtSemantics(int count, int at) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count štáárš át $at',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String hudLevelStarsSemantics(int stars, String two, String three) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars štáárš çöłłééçtéð',
    );
    return '[$_temp0. $two. $three.~~~~~~~~~]';
  }

  @override
  String get hudMax => '[MÅÅX~]';

  @override
  String hudRouteSemantics(int percent) {
    return '[Rööütéé $percent% ƒłöwñ~~~~]';
  }

  @override
  String hudGlideCompact(String time) {
    return '[Głííðé · $time~~~]';
  }

  @override
  String get hudJumpToGlide => '[Jüümþ tö głííðé~~~]';

  @override
  String get hudJump => '[Jüümþ~]';

  @override
  String hudGlideSemantics(String time) {
    return '[Głííðé, $time réémáííñíñg~~~~~]';
  }

  @override
  String hudGlideEndingSemantics(String time) {
    return '[Głííðé ééñðíñg, $time réémáííñíñg~~~~~~]';
  }

  @override
  String get hudJumpChargeSemantics =>
      '[Jüümþ tö çháárgé áá 3-šéçööñð głíðéé~~~~~]';

  @override
  String get hudRecordNewBest => '[Ñééw béšt!~~]';

  @override
  String get hudRecordMatched => '[Bééšt mátçhééð!~~~]';

  @override
  String hudRecordBest(int best) {
    return '[Bééšt $best~~~]';
  }

  @override
  String hudRecordBeyond(int points) {
    return '[+$points bééýöñð ýööür bééšt~~~~~]';
  }

  @override
  String get hudRecordOneMore => '[ØØñé mööré ƒöör á rééçörð~~~]';

  @override
  String hudRecordToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count töö á ñééw réçöörð',
    );
    return '[$_temp0~~~~]';
  }

  @override
  String hudRecordSemantics(String title, String detail) {
    return '[$title. $detail.~~~~]';
  }

  @override
  String hudScoreSemantics(int score) {
    return '[Šçööré $score~~~]';
  }

  @override
  String hudScoreMultiplierSemantics(int score, int multiplier) {
    return '[Šçööré $score, $multiplier tííméš müüłtíþłííér~~~~~~~~]';
  }

  @override
  String get commonBusySemantics => '[Büüšý~]';

  @override
  String get flightResultBumpClouds =>
      '[ÅÅ łíttłéé bümþ ííñ thé çłööüðš.~~~~~]';

  @override
  String get flightResultPersonalBest => '[ÞÉÉRŠØÑÅÅŁ BÉŠT~~~]';

  @override
  String get flightResultNewPersonalBest => '[ÑÉÉW ÞÉRŠØØÑÅŁ BÉÉŠT!~~~]';

  @override
  String get flightResultStarsCollected => '[ŠTÅÅRŠ ÇØŁŁÉÉÇTÉÐ~~~~]';

  @override
  String get flightResultDailyStamped => '[Tööðáý’š þööštçárð štáámþéð!~~~~~~]';

  @override
  String flightResultNextStamp(String stamp) {
    return '[Ñééxt: $stamp~~~]';
  }

  @override
  String get flightResultSavedOnPhone => '[Šáávéð ööñ thíš þhööñé~~~~]';

  @override
  String flightResultSavedGates(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Šáávéð ööñ thíš þhööñé · $total töötáł gáátéš',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get flightResultSaving => '[Šáávíñg ýööür ƒłííght…~~~~]';

  @override
  String get flightResultSessionSaved =>
      '[Šééššíööñ šávééð · Wátçh ííñ Réçöörðš~~~~~~]';

  @override
  String get flightResultWatchReplay => '[Wáátçh réþłááý~~~]';

  @override
  String get flightResultPreparing => '[Þrééþárííñg…~~]';

  @override
  String get flightResultSavingShort => '[Šáávíñg…~~]';

  @override
  String get flightResultSaveSession => '[Šáávé šééššíööñ~~]';

  @override
  String get flightResultFlyAgain => '[Fłý áágáííñ~~]';

  @override
  String get commonRetry => '[Réétrý~]';

  @override
  String get commonMap => '[Mááþ~]';

  @override
  String get commonNext => '[Ñééxt~]';

  @override
  String flightStatPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'þüüšh-üþš',
    );
    return '[$_temp0~~]';
  }

  @override
  String flightStatSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'šqüüátš',
    );
    return '[$_temp0~~]';
  }

  @override
  String flightStatJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jüümþš',
    );
    return '[$_temp0~]';
  }

  @override
  String flightStatFlaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ƒłááþš',
    );
    return '[$_temp0~]';
  }

  @override
  String get flightStatFlightTime => '[ƒłííght tíméé~~]';

  @override
  String get flightStatPerfect => '[þéérƒéçt~~]';

  @override
  String get flightStatBestStreak => '[bééšt štréáák~~]';

  @override
  String get flightStatRank => '[rááñk~]';

  @override
  String get flightRankSkyCaptain => '[Šký çááþtáííñ~~]';

  @override
  String get flightRankCloudExplorer => '[Çłööüð ééxþłöréér~~~]';

  @override
  String get flightRankFirstWings => '[Fííršt wíñgš~~~]';

  @override
  String flightPercent(int percent) {
    return '[$percent%~~]';
  }

  @override
  String get gameOverCaptionBest =>
      '[Büümþéð ööüt ööñ á brááñð-ñéw bééšt!~~~~~]';

  @override
  String get gameOverCaptionSea => '[ÅÅ łíttłéé šþłášh ííñ thé šééá.~~~~~]';

  @override
  String get gameOverSplash => '[Šþłáášh!~~]';

  @override
  String get gameOverBonk => '[Bööñk!~]';

  @override
  String get gameOverEveryMarkSemantics => '[ÉÉvérý máárk réááçhéð~~~~]';

  @override
  String gameOverMoreStarsSemantics(int count, int mark) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mööré štáárš ƒör $mark štáárš',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String gameOverBossHealthSemantics(String boss, int hp, int maxHp) {
    return '[$boss: $hp ööƒ $maxHp héááłth łéƒt~~~~~~~~]';
  }

  @override
  String gameOverRouteSemantics(int percent) {
    return '[$percent þéérçéñt ööƒ thé rööütéé ƒłöwñ~~~~~~~]';
  }

  @override
  String gameOverGuardianHpLeft(String boss, int hp) {
    return '[$boss: $hp HÞ ŁÉÉFT~~~~~]';
  }

  @override
  String gameOverBossLeft(String boss) {
    return '[$boss ŁÉÉFT~~~]';
  }

  @override
  String get gameOverRouteFlown => '[RØØÛTÉÉ FŁØWÑ~~]';

  @override
  String gameOverHp(int hp) {
    return '[$hp HÞ~~~]';
  }

  @override
  String gameOverMoreFor(int count) {
    return '[$count mööré ƒöör~~~]';
  }

  @override
  String get gameOverBothMarks => '[Bööth márkš rééáçhééð~~~~]';

  @override
  String gameOverBothMarksBeat(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'other': 'Bööth márkš rééáçhééð. Béáát $boss!',
    });
    return '[$_temp0~~~~~~]';
  }

  @override
  String get miniResultTitle => '[ÉÉvérý ƒłííght çöüüñtš.~~~~]';

  @override
  String get miniResultComplete => '[FŁÎÎGHT ÇØMÞŁÉÉTÉ~~~~]';

  @override
  String get miniResultCheerBest => '[Łööök áát ýöüü gö!~~]';

  @override
  String get miniResultCheerComplete => '[Fłííght çömþłéété!~~~~]';

  @override
  String get miniResultCheerNice => '[Ñííçé ƒłýííñg.~~]';

  @override
  String get miniResultNew => '[ÑÉÉW~]';

  @override
  String get flightEndTrackingLost =>
      '[Wéé łöšt šííght öƒ ýööü ƒöör á mööméñt.~~~~~~]';

  @override
  String get flightEndPostureLost =>
      '[Ýööür þööšítííöñ möövéð ööüt ööƒ ráñgéé.~~~~]';

  @override
  String get flightEndBackgrounded =>
      '[Ýööü štééþþéð ááwáý ƒrööm thé šký.~~~~~~]';

  @override
  String get flightEndBreak => '[ÅÅ wéłł-ééárñééð bréááthér.~~~~]';

  @override
  String get flightEndQuit => '[ÛÛñtíł théé ñéxt ááðvéñtüüré.~~~~~]';

  @override
  String get flightEndStalled => '[Théé gáméé wáš ííñtérrüüþtéð.~~~~~]';

  @override
  String get flightEndCompleted =>
      '[ÅÅ whöłéé šký öƒ štáárš. Åłł ýööürš.~~~~~~]';

  @override
  String get levelResultTryAgain => '[Trý áágáííñ!~~]';

  @override
  String get levelResultVictory => '[Vííçtörý!~~]';

  @override
  String get levelResultGuardianDown => '[Güüárðííáñ ðööwñ!~~]';

  @override
  String get levelResultDelivered => '[Ðééłívééréð!~~]';

  @override
  String levelResultComingSoon(String region) {
    return '[$region ííš çömííñg šöööñ!~~~~]';
  }

  @override
  String levelResultStarsSemantics(int earned) {
    return '[$earned ööƒ 3 štárš~~~~]';
  }

  @override
  String levelResultBest(int best) {
    return '[Bééšt $best~~~]';
  }

  @override
  String get levelResultNoBest => '[Ñöö béšt ýéét~~]';

  @override
  String get levelResultFirstClear => '[Fííršt çłéáár!~~]';

  @override
  String get levelResultNewBest => '[ÑÉÉW BÉŠT!~~]';

  @override
  String get levelResultScore => '[ŠÇØØRÉ~]';

  @override
  String get levelResultGoalBoss => '[Bööšš~]';

  @override
  String get levelResultGoalGuardian => '[Güüárðííáñ~~]';

  @override
  String get levelResultGoalFinish => '[Fííñíšh~~]';

  @override
  String get levelResultGoalDone => '[Ðööñé~]';

  @override
  String get levelResultGoalNotYet => '[Ñööt ýét~~]';

  @override
  String levelResultGoalToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count töö gö',
    );
    return '[$_temp0~~~]';
  }

  @override
  String get levelResultGoalFinishFirst => '[Fííñíšh ƒííršt~~~]';

  @override
  String levelResultGoalSemantics(String goal) {
    return '[$goal.~~]';
  }

  @override
  String levelResultGoalDoneSemantics(String goal) {
    return '[$goal. Ðööñé.~~~]';
  }

  @override
  String get levelResultPostcardWaiting =>
      '[ÅÅ þöštçáárð íš wááítííñg öñ théé máþ!~~~~~~]';

  @override
  String levelResultLevelOpen(String id, String name) {
    return '[$id $name ííš öþééñ!~~~~]';
  }

  @override
  String get levelResultReachFinish =>
      '[Rééáçh théé ƒíñííšh tö ééárñ štáárš.~~~~~]';

  @override
  String get course_classic_title => '[Çłááššíç~~]';

  @override
  String get course_starTrail_title => '[ÉÉñðłéšš~~]';

  @override
  String get course_classic_instructions =>
      '[Fííñð thé gááþš. Föłłööw thé ááímííñg márkš ƒöör á þéérƒéçt þáášš.~~~~~~~~~~~]';

  @override
  String get course_starTrail_instructions =>
      '[Çööłłéçt ááłł 3 štárš ííñ á grööüþ ƒöör +5. Çháííñ štárš ƒöör üþ töö 3×. Štárš rééštöréé ýöüür šhíééłð; þérƒééçt gátééš éáárñ á štáár mágñéét. Ûþgrááðé bööth wíth štáárš!~~~~~~~~~~~~~~~~~~~~~~~~~]';

  @override
  String get course_classic_scoreLabel => '[ØØBŠTÅÇŁÉÉŠ~~]';

  @override
  String get course_starTrail_scoreLabel => '[ŠTÅÅR ÞØÎÎÑTŠ~~]';

  @override
  String course_classic_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gáátéš',
    );
    return '[$_temp0~]';
  }

  @override
  String course_starTrail_scoreUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'štáár þöííñtš',
    );
    return '[$_temp0~~]';
  }

  @override
  String get course_classic_previewSemantics =>
      '[Çłááššíç: ƒłý thrööügh théé gáþš.~~~~~~~]';

  @override
  String get course_starTrail_previewSemantics =>
      '[ÉÉñðłéšš: çööłłéçt štáárš wíth thrééé hééártš ááñð á šhííéłð.~~~~~~~~~~~]';

  @override
  String get obstacle_garden_name => '[Gáárðéñ gááté~~]';

  @override
  String get obstacle_windLift_name => '[Wííñð łíƒt~~~]';

  @override
  String get obstacle_petalGate_name => '[Þéétáł šhüüttérš~~~~]';

  @override
  String get obstacle_switchback_name => '[Šwíítçhbáçk~~~]';

  @override
  String get obstacle_lanternDrift_name => '[Łááñtérñ ðrííƒt~~~]';

  @override
  String get obstacle_sunWheels_name => '[Šüüñ whéééłš~~]';

  @override
  String get obstacle_crystalSteps_name => '[Çrýštááł štéþš~~~~]';

  @override
  String get rush_wildfire_name => '[Wííłðƒíréé~~]';

  @override
  String get rush_wildfire_escape => '[ØØütrááñ thé wííłðƒíréé~~~]';

  @override
  String get rush_skyfall_name => '[Škýƒááłł~~]';

  @override
  String get rush_skyfall_escape => '[Šüürvívééð thé škýƒááłł~~~~~]';

  @override
  String get rush_eruption_name => '[ÉÉrüþtííöñ~~]';

  @override
  String get rush_eruption_escape => '[Bééát théé érüüþtíööñ~~]';

  @override
  String get rush_swarm_name => '[Šwáárm~]';

  @override
  String get rush_swarm_escape => '[Þłööwéð thrööügh théé šwárm~~~~~~]';

  @override
  String get boss_baronBat_title => '[ŁØØRÐ ØF THÉÉ ŠTØRM~~~~]';

  @override
  String get boss_spitterBeetle_title => '[BRÉÉWÉR ØØF THÉ ŠWÅÅRM~~~~]';

  @override
  String get boss_duskMoth_title => '[KÉÉÉÞÉÉR ØF THÉÉ TWÎŁÎÎGHT VÉÎÎŁ~~~~~]';

  @override
  String get boss_pirate_title => '[TÉÉRRØR ØØF THÉ HÎÎGH TÎÐÉÉ~~~~]';

  @override
  String get boss_dragon_title => '[ŠØØVÉRÉÉÎGÑ ØØF THÉ BÛÛRÑÎÑG ŠKÝ~~~~~~]';

  @override
  String get boss_kingCoo_title => '[ÇØØMMÎŠŠÎÎØÑÉÉR ØF THÉÉ ÇÛRB~~~~~]';

  @override
  String get boss_searchlightGargoyle_title =>
      '[WÅÅTÇHMÅÑ ØØF THÉ TÅÅŁŁÉŠT TØØWÉR~~~~~~]';

  @override
  String get boss_neferhoo_title => '[KÉÉÉÞÉÉR ØF THÉÉ ŁØŠT ŁÉÉTTÉR~~~~~]';

  @override
  String get boss_baronBat_returnTitle => '[THÉÉ ŠTØRM RÉÉTÛRÑŠ~~~~]';

  @override
  String get boss_baronBat_barName => '[BÅÅRØÑ BÅÅT~~]';

  @override
  String get boss_spitterBeetle_barName => '[ŠÞÎÎTTÉR KÎÎÑG~~~]';

  @override
  String get boss_duskMoth_barName => '[ÐÛÛŠK ÉMÞRÉÉŠŠ~~~]';

  @override
  String get boss_pirate_barName => '[ÞÎÎRÅTÉÉ ÇÅÞTÅÅÎÑ~~~]';

  @override
  String get boss_dragon_barName => '[ÉÉMBÉR ÐRÅÅGØÑ~~~]';

  @override
  String get boss_kingCoo_barName => '[KÎÎÑG ÇØØØ~]';

  @override
  String get boss_searchlightGargoyle_barName => '[GÅÅRGØÝŁÉÉ~~]';

  @override
  String get boss_neferhoo_barName => '[ÑÉÉFÉRHØØØ~~]';

  @override
  String get vanguard_baronBat_title => '[BÅÅRØÑ BÅÅT\'Š BÅTŠ~~~~]';

  @override
  String get vanguard_baronBat_call =>
      '[Hééré thééý çöméé! Thé Bááröñ ííš ríght bééhíñð.~~~~~~~~]';

  @override
  String get vanguard_spitterBeetle_title =>
      '[THÉÉ ŠÞÎTTÉÉR KÎÑG\'Š BRØØØÐ~~~~~]';

  @override
  String get vanguard_spitterBeetle_call =>
      '[Hééré thééý çöméé! Thé Šþííttér Kííñg íš rííght béhííñð.~~~~~~~~~]';

  @override
  String get vanguard_duskMoth_title => '[THÉÉ ÐÛŠK ÉÉMÞRÉŠŠ\'Š MØØTHŠ~~~~~]';

  @override
  String get vanguard_duskMoth_call =>
      '[Hééré thééý çöméé! Thé ÉÉmþréšš ííš ríght bééhíñð.~~~~~~~~]';

  @override
  String get vanguard_kingCoo_title => '[KÎÎÑG ÇØØØ\'Š ŠQÛÅÅÐRØÑ~~~~]';

  @override
  String get vanguard_kingCoo_call =>
      '[Hééré thééý çöméé! Kíñg Çööö ííš ríght bééhíñð.~~~~~~~]';

  @override
  String get vanguard_kingCoo_callCrusts =>
      '[Hééré thééý çöméé! Ðüçk théé çrüštš!~~~~~~]';

  @override
  String get vanguard_kingCoo_callReturns =>
      '[Ðüüçk thé çrüüštš! Míšš ööñé ááñð ít çööméš bááçk!~~~~~~~~]';

  @override
  String get bossVanguardClear => '[ÇŁÉÉÅR!~]';

  @override
  String get bossVanguardLeft => '[ŁÉÉFT~]';

  @override
  String get bossStragglersCaught => '[ÅÅŁŁ ÇÅÛÛGHT!~~]';

  @override
  String get bossHint_strongerBaronBat =>
      '[ŠTRØØÑGÉR · Trííþłé šhöötš, áñð hííš bátš jööíñ ííñ!~~~~~~~~]';

  @override
  String get bossHint_strongerSpitterBeetle =>
      '[ŠTRØØÑGÉR · Füüłł ƒáñš, ááñð híš bééétłééš jöííñ íñ!~~~~~~~~]';

  @override
  String get bossHint_strongerDuskMoth =>
      '[ŠTRØØÑGÉR · Šéévéñ-šhööt ƒáñš, ááñð hér mööthš jöííñ íñ!~~~~~~~~~~]';

  @override
  String get bossHint_strongerPirate =>
      '[ŠTRØØÑGÉR · Théé tíðéé íš tüürñíñg!~~~~~~]';

  @override
  String get bossHint_strongerDragon =>
      '[ŠTRØØÑGÉR · Wáátçh ƒör théé bréááth áñð théé ƒłöçkš!~~~~~~~~~~]';

  @override
  String get bossHint_strongerKingCoo =>
      '[ŠTRØØÑGÉR · Héé whíštłééš ƒör hííš šqüááðröñ!~~~~~~~~]';

  @override
  String get bossHint_strongerGargoyleFierce =>
      '[ŠTRØØÑGÉR · Fééáthéérš ƒáłł ööñ thé ööþéñ łáámþ!~~~~~~~~]';

  @override
  String get bossHint_strongerGargoyle =>
      '[ŠTRØØÑGÉR · Štööñé ƒééáthéérš ƒáłł!~~~~~~]';

  @override
  String get bossHint_strongerNeferhooTougher =>
      '[ŠTRØØÑGÉR · Théé áñkh, ááñð híš müümmý bátš!~~~~~~~~]';

  @override
  String get bossHint_strongerNeferhoo =>
      '[ŠTRØØÑGÉR · Théé göłðééñ áñkh çööméš bááçk!~~~~~~~]';

  @override
  String get bossHint_tideRising => '[TÎÎÐÉ RÎÎŠÎÑG · Fłý híígh!~~~~]';

  @override
  String get bossHint_highTide =>
      '[HÎÎGH TÎÐÉÉ · Štáý áábövéé thé wáátér~~~~~]';

  @override
  String get bossHint_tideFury =>
      '[FÛÛRÝ · Bröááðšíðééš bétwéééñ théé šürgééš~~~~~~]';

  @override
  String get bossHint_tideCalm =>
      '[Ðööðgé théé çáññööñbáłłš · Kéééþ ööüt ööƒ thé wáátér~~~~~~~~]';

  @override
  String get bossHint_dragonSwarm =>
      '[ŠWÅÅRM · Ðöðgéé thé báátš ör šþrííñt thröüügh thém~~~~~~~~~~]';

  @override
  String get bossHint_dragonFuryDebut => '[FÛÛRÝ · Fáštéér ƒíréébáłłš~~~~~]';

  @override
  String get bossHint_dragonFury =>
      '[FÛÛRÝ · Fíréébáłłš büüršt íñtöö émbéérš~~~~~~~]';

  @override
  String get bossHint_dragonCalm =>
      '[Ðööðgé théé ƒíréébáłłš · Wáátçh ƒör théé bréááth~~~~~~~~]';

  @override
  String get bossHint_screechFury =>
      '[FÛÛRÝ · Fáštéér ƒíréébáłłš, mööré báátš~~~~~~]';

  @override
  String get bossHint_screechCalm =>
      '[Ðööðgé théé ƒíréébáłłš ááñð bátš · Wáátçh ƒör théé šçréééçh~~~~~~~~~~]';

  @override
  String get bossHint_cooPopped => '[ÞØØÞ! · Ñö šqüüáðrööñ~~~]';

  @override
  String get bossHint_cooSquadron =>
      '[ŠQÛÛÅÐRØØÑ · Föłłööw thé ööþéñ łááñé!~~~~~]';

  @override
  String get bossHint_cooPuffed => '[ÞÛÛFFÉÐ · Šhöööt hííš çhéšt (x2)!~~~~~]';

  @override
  String get bossHint_cooCrumbBomb => '[ÇRÛÛMB BØMB · Łééávéé thé rííñg!~~~~~]';

  @override
  String get bossHint_cooFury => '[FÛÛRÝ · Štáý béétwéééñ thé rííñgš~~~~~~]';

  @override
  String get bossHint_cooCalm =>
      '[Ðööðgé théé çrümb böömbš · Šhöööt híš çhééšt whéñ íít þüƒƒš~~~~~~~~~~~]';

  @override
  String get bossHint_beamOn => '[BÉÉÅM · Štááý íñ théé ðárk~~~~]';

  @override
  String get bossHint_beamFury => '[FÛÛRÝ · Šłíþ béétwéééñ thé bééámš~~~~~~]';

  @override
  String get bossHint_beamIncomingHigh => '[BÉÉÅM ÎÎÑÇØMÎÎÑG · Fłý łöw!~~~~~]';

  @override
  String get bossHint_beamIncomingLow => '[BÉÉÅM ÎÎÑÇØMÎÎÑG · Fłý hígh!~~~~~]';

  @override
  String get bossHint_lampOpen => '[ŁÅÅMÞ ØÞÉÉÑ · Šhöööt thé łáámþ!~~~~]';

  @override
  String get bossHint_shuttersClosed =>
      '[ŠHÛÛTTÉRŠ ÇŁØØŠÉÐ · Šáávé ýööür šhöötš~~~~~~]';

  @override
  String get bossHint_mothFuryNoVeil =>
      '[FÛÛRÝ · Šévééñ-šhöt ƒááñš. Ñö vééíł ýéét!~~~~~~]';

  @override
  String get bossHint_mothNoVeil =>
      '[Ñöö véííł ýét · Fííré béétwéééñ thé ƒááñš!~~~~~]';

  @override
  String get bossHint_mothShielded =>
      '[ŠHÎÎÉŁÐÉÉÐ · Ðöðgéé üñtííł thé vééíł ðrööþš~~~~~~]';

  @override
  String get bossHint_mothShieldForming =>
      '[ŠHÎÎÉŁÐ FØØRMÎÑG · Géét réááðý tö ðööðgé~~~~~~~]';

  @override
  String get bossHint_mothFury =>
      '[FÛÛRÝ · Šévééñ-šhöt ƒááñš. Véííł íš ðööwñ!~~~~~~]';

  @override
  String get bossHint_mothCalm =>
      '[Vééíł ííš ðöwñ · Fííré béétwéééñ thé ƒááñš!~~~~~~]';

  @override
  String get bossHint_neferhooMailCall =>
      '[MÅÅÎŁ ÇÅÅŁŁ · Šhöööt thém bááçk!~~~~~]';

  @override
  String get bossHint_neferhooReturn => '[RÉÉTÛRÑ TØØ ŠÉÑÐÉÉR! · −25~~~]';

  @override
  String get bossHint_neferhooReturnFaster => '[RÉÉTÛRÑ TØØ ŠÉÑÐÉÉR! · −18~~~]';

  @override
  String get bossHint_neferhooAnkh => '[THÉÉ ÅÑKH · ÎÎt çömééš báçk!~~~~~]';

  @override
  String get bossHint_neferhooExpress =>
      '[ÉÉXÞRÉŠŠ ÞØØŠT · Fívéé łéttéérš, ƒáštéér~~~~~~~]';

  @override
  String get bossHint_neferhooTwoAnkhs =>
      '[TWØØ ÅÑKHŠ · Kéééþ ööƒƒ böth łááñéš~~~~~~]';

  @override
  String get bossHint_neferhooBats =>
      '[MÛÛMMÝ BÅTŠ · Šhöööt théém ðöwñ!~~~~~~]';

  @override
  String get bossHint_neferhooScuff =>
      '[Rööçkš öñłý šçüüƒƒ híš wrááþš. Šhöööt híš ŁÉÉTTÉRŠ bááçk!~~~~~~~~~~~]';

  @override
  String get bossHint_neferhooWarmUp =>
      '[Šhöööt hííš łéttéérš báçk · Réétürñ töö šéñðéér~~~~~~~~]';

  @override
  String get bossHint_neferhooCalm =>
      '[Šhöööt hííš łéttéérš báçk · Ðööðgé théé göłðééñ áñkh~~~~~~~~~]';

  @override
  String get bossHint_neferhooFury =>
      '[FÛÛRÝ · Éxþrééšš þöšt ááñð twö ááñkhš~~~~~~~]';

  @override
  String bossHint_breathWarning(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'ÐRÅÅGØÑ\'Š BRÉÉÅTH · Fłý łööw! Îtš hééárt ííš öþééñ',
      'middle': 'ÐRÅGØØÑ\'Š BRÉÅÅTH · Çłímb öör ðívéé! Îtš hééárt ííš öþééñ',
      'other': 'ÐRÅGØØÑ\'Š BRÉÅÅTH · Fłý hígh! ÎÎtš héáárt íš ööþéñ',
    });
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String bossHint_breathFire(String lane) {
    String _temp0 = intl.Intl.selectLogic(lane, {
      'high': 'FÎÎRÉ · Fłý łööw! Štríkéé thé głööwíñg hééárt',
      'middle': 'FÎÎRÉ · Çłíímb ör ðíívé! Štrííké théé głöwííñg héáárt',
      'other': 'FÎRÉÉ · Fłý hígh! Štrííké théé głöwííñg héáárt',
    });
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String bossHint_screechWarning(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'ŠØØÑÎÇ ŠÇRÉÉÉÇH · Fłý töö thé híígh gáþ!',
      'middle': 'ŠØØÑÎÇ ŠÇRÉÉÉÇH · Fłý töö thé mííððłé gááþ!',
      'other': 'ŠØÑÎÎÇ ŠÇRÉÉÉÇH · Fłý tö théé łöw gááþ!',
    });
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String bossHint_screechHold(String gap) {
    String _temp0 = intl.Intl.selectLogic(gap, {
      'high': 'ŠÇRÉÉÉÇH · Hööłð thé híígh gáþ',
      'middle': 'ŠÇRÉÉÉÇH · Hööłð thé mííððłé gááþ',
      'other': 'ŠÇRÉÉÉÇH · Höłð théé łöw gááþ',
    });
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get encounterCaption_duskMoth =>
      '[ÐØØÐGÉ THÉÉ FÅÑŠ  ·  FÎÎRÉ WHÉÉÑ THÉ VÉÉÎŁ ÐRØØÞŠ~~~~~~~]';

  @override
  String get encounterCaption_pirate =>
      '[ÐØØÐGÉ THÉÉ ÇÅÑÑØØÑ  ·  ŠTÅÝ ØØÛT ØØF THÉ WÅÅTÉR~~~~~~~]';

  @override
  String get encounterCaption_dragon =>
      '[ÐØØÐGÉ THÉÉ FÎRÉÉBÅŁŁŠ  ·  ÉÉŠÇÅÞÉÉ THÉ BRÉÉÅTH~~~~~~~]';

  @override
  String get encounterCaption_kingCoo =>
      '[ŁÉÉÅVÉÉ THÉ RÎÎÑGŠ  ·  ŠHØØØT HÎŠ ÇHÉÉŠT WHÉÑ ÎÎT ÞÛFFŠ~~~~~~~~~]';

  @override
  String get encounterCaption_searchlightGargoyle =>
      '[ŠTÅÅÝ ØÛÛT ØF THÉÉ ŁÎGHT  ·  ŠHØØØT THÉÉ ŁÅMÞ WHÉÉÑ ÎT ØØÞÉÑŠ~~~~~~~~~]';

  @override
  String get encounterCaption_neferhoo =>
      '[GÉÉT RÉÅÅÐÝ  ·  ŠHØØØT HÎŠ ŁÉÉTTÉRŠ BÅÅÇK~~~~~~]';

  @override
  String get encounterCaption_screech =>
      '[WHÉÉÑ HÉ ŠÇRÉÉÉÇHÉÉŠ  ·  FŁÝ TØ THÉÉ GÅÞ~~~~~~~]';

  @override
  String get encounterCaption_default =>
      '[GÉÉT RÉÅÅÐÝ  ·  FŁÅÞ, ÐØØÐGÉ, FÎÎRÉ~~~~~]';

  @override
  String get encounterCoasting => '[Ýööür bíírð íš çööáštííñg šáƒééłý~~~~~]';

  @override
  String get encounterOpenSky => '[Bááçk tö théé öþééñ šký~~~~]';

  @override
  String get encounterOmenTitle_duskMoth => '[TWÎÎŁÎGHT TÅÅKÉŠ WÎÎÑG~~~~]';

  @override
  String get encounterOmenLine_duskMoth =>
      '[ÅÅ šíłkééñ véííł gáthéérš íñ théé ðüšk…~~~~~~]';

  @override
  String get encounterOmenTitle_spitterBeetle =>
      '[ŠØØMÉTHÎÎÑG ÎŠ BRÉÉWÎÑG~~~~~]';

  @override
  String get encounterOmenLine_spitterBeetle =>
      '[Théé áíír íš štáártíñg töö ƒížž…~~~~~]';

  @override
  String get encounterOmenTitle_dragon => '[THÉÉ ŠKÝ ÇÅTÇHÉÉŠ FÎRÉÉ~~~~]';

  @override
  String get encounterOmenLine_dragon =>
      '[Grééát wííñgš béáát áböövé théé çłöüüðš…~~~~~~]';

  @override
  String get encounterOmenTitle_kingCoo => '[THÉÉ ÇÛRB ÎÎŠ ÇŁØŠÉÉÐ~~~]';

  @override
  String get encounterOmenLine_kingCoo =>
      '[Šöömébööðý íš véérý çröšš ááböüüt thé brééáð çáárt…~~~~~~~~]';

  @override
  String get encounterOmenTitle_searchlightGargoyle => '[ŠTØØRM WÅRÑÎÎÑG~~~]';

  @override
  String get encounterOmenLine_searchlightGargoyle =>
      '[Šööméthííñg öñ théé łéðgéé íš wáátçhíñg…~~~~~~~]';

  @override
  String get encounterOmenTitle_neferhoo => '[THÉÉ ÞÝRÅMÎÎÐ ŠTÎRŠ~~~~]';

  @override
  String get encounterOmenLine_neferhoo =>
      '[Théé þýrámííð’š ðüšt ííš štírrííñg…~~~~~~]';

  @override
  String get encounterOmenTitle_baronReturns => '[THÉÉ BÅRØØÑ RÉTÛÛRÑŠ~~~]';

  @override
  String get encounterOmenLine_baronReturns =>
      '[Héé íš bááçk, áñð héé íš müüçh łöüüðér…~~~~~]';

  @override
  String get encounterOmenTitle_default => '[ÅÅ ŠHÅÐØØW ÅÞÞRØØÅÇHÉÉŠ~~~]';

  @override
  String get encounterOmenLine_default =>
      '[Théé šký béłööñgš tö šööméööñé ééłšé…~~~~~~]';

  @override
  String get encounterOmenTitle_pirate => '[ŠÅÅÎŁ HØØ!~]';

  @override
  String get encounterOmenLine_pirate =>
      '[ÅÅ šhíþ rííðéš ííñ öñ théé ríšííñg tíðéé…~~~~~]';

  @override
  String get bossGuardianEyebrow => '[GÛÛÅRÐÎÎÅÑ~~]';

  @override
  String bossEncounterEyebrow(String number) {
    return '[ÉÉÑÇØÛÛÑTÉR $number~~~~]';
  }

  @override
  String get bossGuardianDown => '[GÛÛÅRÐÎÎÅÑ ÐØØWÑ!~~]';

  @override
  String get bossSkyReclaimed => '[ŠKÝ RÉÉÇŁÅÎÎMÉÐ~~~]';

  @override
  String bossVictoryPoints(int points) {
    return '[+$points ÞØØÎÑTŠ   ·   ŠHÎÎÉŁÐ RÉÉŠTØRÉÉÐ~~~~~~]';
  }

  @override
  String bossDefeatedBanner(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'baronBat': 'BÅÅRØÑ BÅÅT ÐÉFÉÉÅTÉÉÐ',
      'spitterBeetle': 'ŠÞÎTTÉÉR KÎÑG ÐÉÉFÉÅÅTÉÐ',
      'duskMoth': 'ÐÛÛŠK ÉMÞRÉÉŠŠ ÐÉFÉÉÅTÉÉÐ',
      'pirate': 'ÞÎRÅÅTÉ ÇÅÅÞTÅÎÎÑ ÐÉFÉÉÅTÉÉÐ',
      'dragon': 'ÉMBÉÉR ÐRÅGØØÑ ÐÉFÉÉÅTÉÉÐ',
      'kingCoo': 'KÎÑG ÇØØØ ÐÉÉFÉÅÅTÉÐ',
      'searchlightGargoyle': 'ŠÉÉÅRÇHŁÎÎGHT GÅRGØØÝŁÉ ÐÉÉFÉÅÅTÉÐ',
      'other': 'ÑÉÉFÉRHØØØ ÐÉÉFÉÅÅTÉÐ',
    });
    return '[$_temp0~~~~~~~]';
  }

  @override
  String bossQuotedLine(String line) {
    return '[“$line”~~]';
  }

  @override
  String get bossPirateRoar => '[ÅÅRRR!~]';

  @override
  String get bossGargoyleCardSmall => '[THÉÉ ŠÉÅÅRÇHŁÎGHT~~~~]';

  @override
  String get bossGargoyleCardBig => '[GÅÅRGØÝŁÉÉ~~]';

  @override
  String get bossGargoyleCardOrder => 'small-big';

  @override
  String get bossDodgeFlyLow => '[FŁÝ ŁØØW~~]';

  @override
  String get bossDodgeFlyHigh => '[FŁÝ HÎÎGH~~]';

  @override
  String get bossDodgeClimbOrDive => '[ÇŁÎÎMB ØR ÐÎÎVÉ~~~]';

  @override
  String get bossDodgeSlipBetween => '[ŠŁÎÎÞ BÉTWÉÉÉÑ\nTHÉÉ BÉÅÅMŠ~~~~]';

  @override
  String get bossSpotted => '[ŠÞØØTTÉÐ!~~]';

  @override
  String get bossShieldLost => '[ŠHÎÎÉŁÐ ŁØØŠT~~]';

  @override
  String get bossHeartLost => '[-1 HÉÉÅRT~]';

  @override
  String get bossGargoyleLampOpen => '[ŁÅÅMÞ ØÞÉÉÑ~~]';

  @override
  String get bossGargoyleShoot => '[ŠHØØØT!~]';

  @override
  String get bossScreechFlyToGap => '[FŁÝ TØØ THÉ GÅÅÞ~~~]';

  @override
  String get bossScreechHoldGap => '[HØØŁÐ THÉ GÅÅÞ~~]';

  @override
  String get bossPirateHighTide => '[HÎÎGH TÎÐÉÉ~~]';

  @override
  String get bossBarDefeated => '[ÐÉÉFÉÅÅTÉÐ~~]';

  @override
  String get bossBarIncoming => '[ÎÎÑÇØMÎÎÑG~~]';

  @override
  String get bossBarFury => '[FÛÛRÝ~]';

  @override
  String get bossBarHeartDouble => '[HÉÉÅRT ×2~]';

  @override
  String get bossStronger => '[ŠTRØØÑGÉR!~~~]';

  @override
  String get bossKingCooPuffed => '[ÞÛÛFFÉÐ~~]';

  @override
  String get bossKingCooShout => '[ÇØØØ!~]';

  @override
  String get bossKingCooPop => '[ÞØØÞ!~]';

  @override
  String get bossKingCooPoof => '[ÞØØØF!~]';

  @override
  String get bossSquadOpenLane => '[ØØÞÉÑ ŁÅÅÑÉ = GØØ~]';

  @override
  String get bossSquadUseGap => '[ÛÛŠÉ THÉÉ GÅÞ~~]';

  @override
  String get bossSquadThenV => '[THÉÉÑ: V~]';

  @override
  String get bossSquadThenGap => '[THÉÉÑ: GÅÞ~~]';

  @override
  String get bossSquadCancelled => '[ŠQÛÛÅÐ ÇÅÅÑÇÉŁŁÉÉÐ~~~]';

  @override
  String get bossNeferhooFound => '[THÉÉ ŁØŠT ŁÉÉTTÉR ÎÎŠ FØÛÛÑÐ~~~~]';

  @override
  String get bossNeferhooHoo => '[HØØØ~]';

  @override
  String get bossNeferhooPoo => '[ÞØØØ~]';

  @override
  String get bossNeferhooMailCall => '[MÅÅÎŁ ÇÅÅŁŁ~~]';

  @override
  String get bossNeferhooExpressPost => '[ÉÉXÞRÉŠŠ ÞØØŠT~~~]';

  @override
  String get bossNeferhooShootBack => '[Šhöööt théém báçk!~~~~]';

  @override
  String get bossNeferhooAnkh => '[THÉÉ ÅÑKH~~]';

  @override
  String get bossNeferhooTwoAnkhs => '[TWØØ ÅÑKHŠ~~~]';

  @override
  String get bossNeferhooComesBack => '[ÎÎt çömééš báçk!~~~]';

  @override
  String encounterRushWarning(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'WÎÎŁÐFÎRÉÉ!',
      'skyfall': 'ŠKÝFÅŁŁ!',
      'eruption': 'ÉÉRÛÞTÎÎØÑ!',
      'other': 'ŠWÅÅRM!',
    });
    return '[$_temp0~~~]';
  }

  @override
  String encounterRushDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Grááb thé šþrííñt ríñgš ááñð öüütrüñ íít!',
      'skyfall': 'Gráb théé šþríñt rííñgš áñð rááçé théé métééörš!',
      'eruption': 'Grááb thé šþrííñt ríñgš ááñð béáát thé błááštš!',
      'other': 'Gráb théé šþríñt rííñgš áñð þłööw thröüügh!',
    });
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String encounterRushEscaped(int points) {
    return '[ÉÉŠÇÅÞÉÉÐ! +$points~~~]';
  }

  @override
  String encounterFlawless(int points) {
    return '[FŁÅÅWŁÉŠŠ! +$points~~~~]';
  }

  @override
  String encounterRushEscapedDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'wildfire': 'Ýööü ööütrááñ thé wííłðƒíréé',
      'skyfall': 'Ýöüü šürvíívéð théé škýƒáłł',
      'eruption': 'Ýööü bééát théé érüüþtíööñ',
      'other': 'Ýöüü þłöwééð thröüügh thé šwáárm',
    });
    return '[$_temp0~~~~~~]';
  }

  @override
  String get encounterGale => '[GÅÅŁÉ!~]';

  @override
  String encounterGaleDetail(String mark) {
    return '[Ðööðgé théé ðébrííš whéréé thé $mark ƒłáášhéš!~~~~~~~~~]';
  }

  @override
  String encounterGaleWeathered(int points) {
    return '[WÉÉÅTHÉÉRÉÐ! +$points~~~~]';
  }

  @override
  String get encounterGaleWeatheredDetail => '[Ýööü rööðé ööüt théé gáłéé~~]';

  @override
  String get encounterAllRings => '[ÅÅŁŁ RÎÑGŠ!~~~]';

  @override
  String encounterAllRingsDetail(String seconds) {
    return '[Tüürbö böööšt +$secondsš~~~~]';
  }

  @override
  String get encounterFinish => '[FÎÎÑÎŠH~~]';

  @override
  String get builderMode_pushUp => '[Þüüšh-üþš~~]';

  @override
  String get builderMode_squat => '[Šqüüátš~~]';

  @override
  String get builderMode_jump => '[Jüümþš~]';

  @override
  String builderSeconds(String seconds) {
    return '[$seconds š~~]';
  }

  @override
  String builderMinutesSeconds(int minutes, String seconds) {
    return '[$minutes mííñ $seconds š~~~~]';
  }

  @override
  String builderRepsPushUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count þüüšh-üþš',
      one: '1 þüüšh-üþ',
    );
    return '[$_temp0~~~~]';
  }

  @override
  String builderRepsSquat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šqüüátš',
      one: '1 šqüüát',
    );
    return '[$_temp0~~~]';
  }

  @override
  String get builderNewLevel_touch => '[Mý tááþ łévééł~~]';

  @override
  String get builderNewLevel_pushUp => '[Mý þüüšh-üþ łéévéł~~~~]';

  @override
  String get builderNewLevel_squat => '[Mý šqüüát łéévéł~~~]';

  @override
  String get builderNewLevel_jump => '[Mý jüümþ łévééł~~~]';

  @override
  String builderNewLevelNumbered(String name, int number) {
    return '[$name $number~~~~]';
  }

  @override
  String get builderFallbackName => '[Mý łéévéł~~]';

  @override
  String builderShareMessage(String name, String mode, String code) {
    return '[Fłý mý Bééákbööüñð łéévéł “$name” ($mode): $code~~~~~~~~~~]';
  }

  @override
  String builderStarsSemantics(int earned, int total) {
    return '[$earned ööƒ $total štárš~~~~~]';
  }

  @override
  String get builderBackSemantics => '[Bááçk~]';

  @override
  String get builderKeepIt => '[Kéééþ íít~]';

  @override
  String builderLessSemantics(String name) {
    return '[Łééšš $name~~~]';
  }

  @override
  String builderMoreSemantics(String name) {
    return '[Mööré $name~~~]';
  }

  @override
  String builderValueSemantics(String name, String value) {
    return '[$name $value~~~~]';
  }

  @override
  String get builderDuplicateSemantics => '[Ðüüþłíçááté~~]';

  @override
  String get builderCopy => '[Çööþý~]';

  @override
  String get builderDeleteSemantics => '[Ðééłétéé~]';

  @override
  String get builderDelete => '[Ðééłétéé~]';

  @override
  String get builderMoreBelow => '[Mööré bééłöw~~]';

  @override
  String builderStepSemantics(String caption, String value) {
    return '[$caption $value~~~~]';
  }

  @override
  String builderStepHintSemantics(String caption, String value, String hint) {
    return '[$caption $value, $hint~~~~~]';
  }

  @override
  String builderPercent(int percent) {
    return '[$percent %~~]';
  }

  @override
  String get builderLane => '[Łááñé~]';

  @override
  String builderLaneHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'tööþ ör bööttöm ööƒ thé šqüüát',
      'other': 'tööþ ör bööttöm ööƒ thé þüüšh-üþ',
    });
    return '[$_temp0~~~~~]';
  }

  @override
  String get builderLaneTop => '[Tööþ~]';

  @override
  String get builderLaneBottom => '[Bööttöm~~]';

  @override
  String get builderHeight => '[Hééíght~~]';

  @override
  String get builderHeightHint => '[ööƒ thé šký~~~]';

  @override
  String get builderLowerSemantics => '[Łööwér~]';

  @override
  String get builderHigherSemantics => '[Hííghér~~]';

  @override
  String get builderOpening => '[ØØþéñííñg~]';

  @override
  String builderOpeningHint(int percent) {
    return '[áát łéáášt $percent %~~~]';
  }

  @override
  String get builderNarrowerSemantics => '[Ñáárröwéér~~]';

  @override
  String get builderWiderSemantics => '[Wííðér~]';

  @override
  String get builderMotion => '[Möötíööñ~]';

  @override
  String get builderMotionGardenHint => '[gáárðéñ gáátéš štááñð štíłł~~~~~~]';

  @override
  String get builderMotionStill => '[Štííłł~]';

  @override
  String get builderMotionGentle => '[Gééñtłé~~]';

  @override
  String get builderMotionLively => '[Łíívéłý~~]';

  @override
  String get builderMotionGardenToast =>
      '[Gáárðéñ gáátéš štááñð štíłł: þííçk áñööthér ƒáámíłý töö mákéé ít möövé.~~~~~~~~~~~]';

  @override
  String get builderSway => '[Šwááý~]';

  @override
  String builderSwayHint(String seconds) {
    return '[ööñé šwááý: $seconds~~~]';
  }

  @override
  String get builderSwayFast => '[Fáášt~]';

  @override
  String get builderSwayMedium => '[Mééðíüüm~]';

  @override
  String get builderSwaySlow => '[Šłööw~]';

  @override
  String get builderPhase => '[ÅÅš ýöüü árríívé~~]';

  @override
  String builderPhaseValue(int position, int count) {
    return '[$position ööƒ $count~~~]';
  }

  @override
  String get builderPhaseHint => '[whééré íít íš ííñ ítš šwááý~~~~]';

  @override
  String get builderPhaseEarlierSemantics => '[ÉÉárłííér ííñ ítš šwááý~~~]';

  @override
  String get builderPhaseLaterSemantics => '[Łáátér ííñ ítš šwááý~~~]';

  @override
  String get builderLook => '[Łööök~]';

  @override
  String builderLookSemantics(int number) {
    return '[Łööök $number~~~]';
  }

  @override
  String get builderDoor => '[Štööñé ðööör~~]';

  @override
  String get builderDoorHint => '[šhöööt íít öþééñ~~]';

  @override
  String get builderDoorNone => '[Ñöö ðööör~]';

  @override
  String get builderDoorNeedsShootToast =>
      '[Tüürñ Šhöööt öñ ííñ thé łéévéł’š šééttíñgš töö üšéé ðööörš.~~~~~~~~]';

  @override
  String get builderPlace => '[Þłááçé~]';

  @override
  String get builderPlaceHint => '[ƒrööm thé štáárt~~~]';

  @override
  String get builderEarlierSemantics => '[ÉÉárłííér~]';

  @override
  String get builderLaterSemantics => '[Łáátér~]';

  @override
  String builderFamilySemantics(String family) {
    return '[Gááté ƒáámíłý: $family. Çhááñgé~~~~~]';
  }

  @override
  String get builderChangeFamily => '[Çhááñgé ƒáámíłý~~~]';

  @override
  String get builderItemStar => '[Štáár~]';

  @override
  String get builderItemTrio => '[Štáár tríöö~~]';

  @override
  String get builderItemHeart => '[Hééárt~]';

  @override
  String get builderItemEnemy => '[ÉÉñémý~]';

  @override
  String get builderItemGate => '[Gááté~]';

  @override
  String get builderItemStarDetail => '[ØØñé štáár tö çööłłéçt~~~~]';

  @override
  String get builderItemTrioDetail => '[ÅÅłł thrééé þáý áá böñüüš~~~]';

  @override
  String get builderItemHeartDetail => '[ØØñé hééárt bááçk~~]';

  @override
  String get builderEnemyKind => '[Kííñð~]';

  @override
  String builderPickupLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Théé bírð ƒłííéš théé töþ ááñð böttööm öƒ ééáçh šqüüát: þüüt þíçküüþš öñ öör bétwéééñ théé ýéłłööw łíñééš.',
      'other':
          'Thé bíírð ƒłíééš thé tööþ áñð bööttöm ööƒ éááçh þüšh-üüþ: þüt þííçküþš ööñ ör béétwéééñ thé ýééłłöw łííñéš.',
    });
    return '[$_temp0~~~~~~~~~~~~~~~~~]';
  }

  @override
  String get builderEnemy_simpleBat => '[Þüürþłé báát~~]';

  @override
  String get builderEnemy_caveBat => '[Çáávé báát~]';

  @override
  String get builderEnemy_spitterBeetle => '[Šþííttér bééétłéé~~~]';

  @override
  String get builderEnemy_duskMoth => '[Ðüüšk möth~~~]';

  @override
  String get builderEnemy_alleyPigeon => '[ÅÅłłéý þíígéööñ~~]';

  @override
  String get builderEnemy_mummyBat => '[Müümmý bát~~~]';

  @override
  String get builderSummaryTitle => '[Thííš łévééł~~]';

  @override
  String builderModeRegion(String mode, String region) {
    return '[$mode · $region~~~~]';
  }

  @override
  String get builderFactLength => '[Łééñgth~~]';

  @override
  String get builderFactStars => '[Štáárš~]';

  @override
  String get builderFactMarks => '[Máárkš~]';

  @override
  String get builderFactWorkout => '[Wöörköüüt~]';

  @override
  String get builderFactPace => '[Þááçé~]';

  @override
  String get builderFactBoss => '[Bööšš~]';

  @override
  String get builderPace_relaxed => '[Rééłáxééð~]';

  @override
  String get builderPace_steady => '[Štééáðý~~]';

  @override
  String get builderPace_brisk => '[Brííšk~]';

  @override
  String get builderSummaryStarterNote =>
      '[ÅÅ štártéér łévééł tö ƒłý ááš ít ííš, ör réémíx ííñtö áá łévééł öƒ ýööür ööwñ.~~~~~~~~~]';

  @override
  String get builderSummaryClearedNote =>
      '[Çłééárééð bý ýöüü: ýöüü ƒłéw íít tö théé éñð.~~~~~~]';

  @override
  String get builderSummaryClearNote =>
      '[Tééšt ƒłý ít ááłł thé wááý tö théé ƒíñííšh tö máárk ít çłééárééð.~~~~~~~~~~]';

  @override
  String builderSummaryClearBossNote(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'other':
          'Tééšt ƒłý ít, bééát $boss ááñð çröšš théé łíñéé tö máárk ít çłééárééð.',
    });
    return '[$_temp0~~~~~~~~~~~]';
  }

  @override
  String get builderSummaryHowTo =>
      '[Þííçk á töööł ööñ thé łééƒt, théñ tááþ thé šký. Tááþ á thííñg tö çhááñgé íít; ðrág íít tö möövé íít.~~~~~~~~~~~~~~]';

  @override
  String get builderFamily_garden_detail =>
      '[Štááñðš štíłł. Çááñ höłð áá štöñéé ðööör.~~~~~~~]';

  @override
  String get builderFamily_windLift_detail =>
      '[Théé öþééñíñg rííšéš ááñð ƒáłłš.~~~~~~]';

  @override
  String get builderFamily_petalGate_detail =>
      '[Théé öþééñíñg ñáárröwš ááñð wíðééñš.~~~~~~]';

  @override
  String get builderFamily_switchback_detail =>
      '[Twöö öþééñíñgš tháát šłíðéé áþáárt.~~~~~]';

  @override
  String get builderFamily_lanternDrift_detail =>
      '[Hááñgíñg łááñtérñš tháát böb.~~~~~~]';

  @override
  String get builderFamily_sunWheels_detail =>
      '[Whéééłš tháát çłöšéé íñ ááñð báçk.~~~~~~]';

  @override
  String get builderFamily_crystalSteps_detail =>
      '[Thrééé štééþš íñ áá ríþþłéé.~~~~]';

  @override
  String get builderFamiliesCloseSemantics => '[Çłööšé gááté ƒáámíłííéš~~~]';

  @override
  String get builderFamiliesTitle => '[Gááté ƒáámíłý~~]';

  @override
  String get builderFamiliesSubtitle =>
      '[Hööw thé gááté łööökš ááñð mövééš.~~~~~]';

  @override
  String builderFamilyCardSemantics(String family, String detail) {
    return '[$family. $detail~~~~]';
  }

  @override
  String reach_name(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gíívé théé łévééł á ñáámé ööƒ üþ töö $count łéttéérš.',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get reach_tooShort =>
      '[Möövé théé ƒíñííšh łíñéé ƒürthéér öñ: théé łévééł íš tööö šhöört.~~~~~~~~~]';

  @override
  String get reach_tooLong =>
      '[Brííñg thé ƒííñíšh łííñé çłööšér: théé łévééł íš tööö łööñg.~~~~~~~~~]';

  @override
  String reach_tooMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tööö mááñý thíñgš: áá łévééł höłðš üüþ tö $count.',
    );
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String get reach_bossNeedsTap =>
      '[ØØñłý Táþ & Fłý łéévéłš ééñð wíth áá böšš.~~~~~~~~]';

  @override
  String get reach_noGates =>
      '[ÅÅðð gátééš ƒör théé bírð töö ƒłý thröüügh.~~~~~~~]';

  @override
  String get reach_startZone =>
      '[Tööö çłööšé töö thé štáárt: mövéé ít þáášt thé štáárt žöñéé.~~~~~~~~]';

  @override
  String get reach_finishRoom =>
      '[Łééávéé röööm béƒööré théé ƒíñííšh łíñéé áƒtéér thíš gááté.~~~~~~~~]';

  @override
  String get reach_overlap =>
      '[Twöö gátééš övéérłáþ: möövé théém áþáárt.~~~~~~]';

  @override
  String get reach_gateHeight =>
      '[Thííš gátéé íš tööö híígh ör tööö łööw.~~~~]';

  @override
  String get reach_gateMotion => '[Thííš gátéé çáññööt mövéé thát wááý.~~~~~]';

  @override
  String get reach_gateLook => '[Thííš gátéé háš ááñ üñkñööwñ łööök.~~~~~]';

  @override
  String get reach_gateNarrow =>
      '[ØØþéñ thííš gátéé wíðéér: thé bíírð çáññööt ƒít.~~~~~~~~]';

  @override
  String get reach_gateWide => '[Thííš gátéé íš ööþéñ tööö wííðé.~~~~]';

  @override
  String get reach_doorNeedsShoot =>
      '[ÅÅ štöñéé ðööör ñéééðš Táþ & Fłý wííth Šhöööt öñ.~~~~~~~]';

  @override
  String get reach_doorNeedsGarden =>
      '[ØØñłý á gáárðéñ gááté çááñ höłð áá štöñéé ðööör.~~~~~~]';

  @override
  String reach_tightSwitch(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'Tííght šwítçh: áá štéááðý šqüáát máý ñööt mákéé ít ííñ tíméé.',
      'other': 'Tíght šwíítçh: á štééáðý þüüšh-üþ mááý ñöt mááké íít íñ tíímé.',
    });
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get reach_steepClimb =>
      '[Štéééþ çłíímb: łéáávé mööré röööm töö jümþ üüþ tö thííš gátéé.~~~~~~~~]';

  @override
  String get reach_enemyNeedsTap =>
      '[ÉÉñémííéš ööñłý ƒłý íñ Tááþ & Fłý łévééłš.~~~~~~~]';

  @override
  String get reach_outsideSky => '[Kéééþ íít íñšííðé théé šký.~~~~]';

  @override
  String get reach_pastFinish =>
      '[Þłááçé íít béƒööré théé ƒíñííšh łíñéé.~~~~~]';

  @override
  String reach_outOfReach(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'ØØüt ööƒ á šqüüát\'š rééáçh: möövé íít ñéáárér théé łáñééš.',
      'other': 'Øüüt öƒ áá þüšh-üüþ\'š réááçh: mövéé ít ñééáréér thé łááñéš.',
    });
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String get reach_inWall =>
      '[ÎÎñšíðéé á wááłł: mövéé ít ííñtö théé öþééñíñg.~~~~~~]';

  @override
  String get reach_noStars => '[Þłááçé áát łéáášt öñéé štár.~~~~]';

  @override
  String get reach_marks =>
      '[Théé štár máárkš ášk ƒöör möréé štárš thááñ thé łéévéł hááš.~~~~~~~~~~]';

  @override
  String reach_cannotFly(String problem) {
    return '[Thííš łévééł çáññööt ƒłý ýét ($problem).~~~~~~~]';
  }

  @override
  String get builderSaveFailedFlyToast =>
      '[Théé łévééł ðíðñ’t šáávé, šöö ít çááñ’t ƒłý ýét. Tááþ ítš ñáámé töö rétrý.~~~~~~~~~~~~]';

  @override
  String get builderShareBlockedToast =>
      '[Fííx thé rééð ƒłágš ƒííršt: théñ théé łévééł çáñ béé šhárééð.~~~~~~~~~~]';

  @override
  String get builderEditorBackSemantics => '[Bááçk tö théé büííłðér~~~~]';

  @override
  String get builderSettingsSemantics => '[Łéévéł šééttíñgš~~~~]';

  @override
  String get builderFly => '[FŁÝ~~]';

  @override
  String get builderTestFly => '[TÉÉŠT FŁÝ~~]';

  @override
  String get builderFlySemantics => '[Fłý thííš łévééł~~~]';

  @override
  String get builderTestFlySemantics => '[Tééšt ƒłý thé whööłé łéévéł~~~~~]';

  @override
  String get builderUndoSemantics => '[ÛÛñðö~]';

  @override
  String get builderRedoSemantics => '[Rééðö~]';

  @override
  String builderIssuesSemantics(int blocking, int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice tííþš',
    );
    return '[$blocking töö ƒíx, $_temp0~~~~~]';
  }

  @override
  String builderTipsSemantics(int advice) {
    String _temp0 = intl.Intl.pluralLogic(
      advice,
      locale: localeName,
      other: '$advice tííþš',
    );
    return '[$_temp0~~~]';
  }

  @override
  String get builderReadySemantics => '[Rééáðý töö ƒłý~~]';

  @override
  String get builderShareSemantics => '[Šhááré çööðé~~]';

  @override
  String get builderFromHereSemantics => '[Tééšt ƒłý ƒröm hééré~~~~]';

  @override
  String get builderFromHere => '[Frööm héréé~~]';

  @override
  String get builderStatusStarter =>
      '[Štáártér łéévéł · łööök, ƒłý öör rémííx~~~~~~]';

  @override
  String get builderStatusSaveFailed =>
      '[Çööüłðñ’t šáávé · tááþ tö réétrý~~~~~]';

  @override
  String get builderStatusSaving => '[Šáávíñg…~~]';

  @override
  String get builderStatusSaved => '[ÅÅłł çháñgééš šávééð~~~]';

  @override
  String builderNamePlateSemantics(String name, String mode, String status) {
    return '[$name. $mode. $status.~~~~~]';
  }

  @override
  String builderNamePlateRenameSemantics(
    String name,
    String mode,
    String status,
  ) {
    return '[$name. $mode. $status. Tááþ tö rééñáméé.~~~~~~~]';
  }

  @override
  String get builderStarterBanner => '[Réémíx íít tö mááké íít ýöüürš~~~]';

  @override
  String get builderRemix => '[Réémíx~]';

  @override
  String get builderRemixSemantics => '[Réémíx~]';

  @override
  String get builderIssuesCloseSemantics => '[Çłööšé þrööbłémš ááñð tíþš~~~~~]';

  @override
  String get builderIssuesReadyTitle => '[Rééáðý töö ƒłý!~~]';

  @override
  String get builderIssuesFixTitle => '[Töö ƒíx bééƒöréé ít ƒłííéš~~~~]';

  @override
  String get builderIssuesTipsTitle => '[Rééáðý, wííth á ƒééw tíþš~~~~]';

  @override
  String get builderIssuesReadyDetail =>
      '[Ñööthíñg töö ƒíx. Tééšt ƒłý ít töö thé ƒííñíšh töö çłéáár ít.~~~~~~~~~~]';

  @override
  String get builderIssuesDetail =>
      '[Tááþ öñéé tö göö tö íítš þłáçéé öñ théé röüüté.~~~~~]';

  @override
  String get builderSettingsCloseSemantics => '[Çłööšé šééttíñgš~~~~]';

  @override
  String get builderSettingsTitle => '[Łéévéł šééttíñgš~~~~]';

  @override
  String builderSettingsSubtitle(String mode) {
    return '[$mode · çhááñgéš šáávé ááš ýöüü mákéé thém~~~~~~~]';
  }

  @override
  String get builderSettingsName => '[Ñáámé~]';

  @override
  String get builderRename => '[Rééñáméé~]';

  @override
  String get builderRenameSemantics => '[Rééñáméé~]';

  @override
  String get builderSettingsRegion => '[Réégíööñ~]';

  @override
  String builderSettingsRegionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count þłááçéš · šwííþé ƒöör möréé',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String get builderSettingsPace => '[Þááçé~]';

  @override
  String get builderSettingsPaceHint => '[hööw ƒášt théé šký šçröłłš~~~~~~]';

  @override
  String get builderSettingsMarks => '[Štáár márkš~~~]';

  @override
  String builderSettingsMarksHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count štárš þłááçéð',
      one: '1 štáár þłáçééð',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String get builderMarkTwoSemantics => '[twöö-štár máárk~~~]';

  @override
  String get builderMarkThreeSemantics => '[thrééé-štáár márk~~~~]';

  @override
  String get builderMarksAuto => '[ÅÅütöö: ƒöłłööw thé štáárš~~~~]';

  @override
  String get builderMarksByHand => '[Šéét bý háñð~~~]';

  @override
  String get builderSettingsControls => '[Çööñtröłš~~~]';

  @override
  String get builderShootOn => '[Šhöööt ööñ~]';

  @override
  String get builderShootOff => '[Šhöööt ööƒƒ~~]';

  @override
  String get builderSprintOn => '[Šþrííñt öñ~~~]';

  @override
  String get builderSprintOff => '[Šþrííñt öƒƒ~~~]';

  @override
  String get builderSettingsBoss => '[Bööšš ƒíñááłé~~]';

  @override
  String get builderSettingsBossHint => '[wááítš áát thé ééñð~~~]';

  @override
  String get builderNoBossSemantics => '[Ñöö böšš: áá ƒíñííšh łíñéé~~~]';

  @override
  String get builderNoBoss => '[Ñööñé~]';

  @override
  String get builderBossShort_baronBat => '[Bááröñ~]';

  @override
  String get builderBossShort_spitterBeetle => '[Šþííttér~~]';

  @override
  String get builderBossShort_duskMoth => '[ÉÉmþréšš~~]';

  @override
  String get builderBossShort_pirate => '[Þíírátéé~]';

  @override
  String get builderBossShort_dragon => '[Ðráágöñ~~]';

  @override
  String builderSettingsLanesNote(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat':
          'Théé bírð ƒłííéš twöö łáñééš: thé tööþ áñð théé böttööm öƒ ééáçh šqüüát. ÅÅ šłöwéér þłáýéér mééétš thé šáámé łéévéł áát á gééñtłér šþéééð. Ñöö šhööötíñg, šþrííñtíñg öör böššééš héréé.',
      'other':
          'Thé bíírð ƒłíééš twö łááñéš: théé töþ ááñð thé bööttöm ööƒ éááçh þüšh-üüþ. Å šłööwér þłááýér mééétš théé šáméé łévééł át áá géñtłéér šþéééð. Ñö šhööötííñg, šþríñtííñg ör bööššéš hééré.',
    });
    return '[$_temp0~~~~~~~~~~~~~~~~~~~~~~~~~~~~]';
  }

  @override
  String get builderSettingsJumpNote =>
      '[ÉÉáçh jüümþ łíƒtš théé bírð; íít głíðééš íñ béétwéééñ. Ñö šhööötííñg, šþríñtííñg ör bööššéš hééré.~~~~~~~~~~~~~~~~]';

  @override
  String get builderStartZoneToast =>
      '[Kéééþ théé štárt žööñé çłééár: þłááçé thííñgš ríght ööƒ thé ðáášhéð łííñé.~~~~~~~~~~~~]';

  @override
  String get builderSkySemantics =>
      '[Łéévéł šký. Tááþ tö þłááçé, ðráág tö möövé öör tö šçrööłł.~~~~~~~~~]';

  @override
  String get builderSkyReadOnlySemantics =>
      '[Łéévéł šký. Tááþ šömééthíñg töö łööök át íít.~~~~~~]';

  @override
  String get builderCoachTitle => '[Büüíłð ýööür łéévéł~~~]';

  @override
  String get builderCoachPickTool => '[Þííçk á töööł ööñ thé łééƒt~~~~]';

  @override
  String get builderCoachTapSky => '[Tááþ thé šký töö þłáçéé ít~~~~~]';

  @override
  String get builderCoachTestFly => '[Tééšt ƒłý ít!~~~]';

  @override
  String get builderCoachDrag =>
      '[Ðráág á thííñg tö möövé íít · ðrág théé šký tö šçrööłł~~~~~~~~~]';

  @override
  String get builderTipDrag =>
      '[Ðráág ít töö mövéé ít · ðráág thé šký töö šçröłł~~~~~~~~]';

  @override
  String builderCanvasTopOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'TØØÞ ØF THÉÉ ŠQÛÅÅT',
      'other': 'TØÞ ØØF THÉ ÞÛÛŠH-ÛÞ',
    });
    return '[$_temp0~~~~]';
  }

  @override
  String get builderCanvasTop => '[TØØÞ~]';

  @override
  String builderCanvasBottomOf(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'squat': 'BØØTTØM ØØF THÉ ŠQÛÛÅT',
      'other': 'BØØTTØM ØØF THÉ ÞÛÛŠH-ÛÞ',
    });
    return '[$_temp0~~~~]';
  }

  @override
  String get builderCanvasBottom => '[BØØTTØM~~]';

  @override
  String get builderCanvasStartZoneFull => '[ŠTÅÅRT ŽØÑÉÉ · KÉÉÉÞ ÇŁÉÅÅR~~~~]';

  @override
  String get builderCanvasStartZone => '[ŠTÅÅRT ŽØÑÉÉ~~]';

  @override
  String get builderCanvasFinishHere => '[FÎÎÑÎŠH HÉÉRÉ~~]';

  @override
  String get builderTool_select => '[Šééłéçt~~]';

  @override
  String get builderToolHint_select =>
      '[Šééłéçt: tááþ šömééthíñg töö çháñgéé ít, ðráág tö möövé íít~~~~~~~~]';

  @override
  String get builderTool_gate => '[Gááté~]';

  @override
  String get builderToolHint_gate =>
      '[Gááté: tááþ thé šký töö þłáçéé á gááté~~~~~]';

  @override
  String get builderTool_star => '[Štáár~]';

  @override
  String get builderToolHint_star =>
      '[Štáár: táþ théé šký tö þłááçé áá štár~~~~~~]';

  @override
  String get builderTool_trio => '[Trííö~]';

  @override
  String get builderToolHint_trio =>
      '[Štáár tríöö: táþ théé šký tö þłááçé thrééé štáárš~~~~~~~~]';

  @override
  String get builderTool_heart => '[Hééárt~]';

  @override
  String get builderToolHint_heart =>
      '[Hééárt: tááþ thé šký töö þłáçéé á hééárt~~~~~~]';

  @override
  String get builderTool_enemy => '[ÉÉñémý~]';

  @override
  String get builderToolHint_enemy =>
      '[ÉÉñémý: tááþ thé šký töö þłáçéé áñ ééñémý~~~~~~~]';

  @override
  String get builderTool_finish => '[Fííñíšh~~]';

  @override
  String get builderToolHint_finish =>
      '[Fííñíšh: tááþ thé šký töö mövéé thé ƒííñíšh łííñé~~~~~~~~]';

  @override
  String get builderTool_boss => '[Bööšš~]';

  @override
  String get builderToolHint_boss =>
      '[Bööšš márk: tááþ thé šký töö mövéé whéréé thé bööšš wáíítš~~~~~~~~~]';

  @override
  String get builderStarterToolsToast =>
      '[Štáártér łéévéłš štááý áš thééý áréé: rémííx ít töö çháñgéé ít.~~~~~~~~~~]';

  @override
  String builderRouteSemantics(String target, String length) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Rööütéé övéérvíééw. $length tö théé böšš. Ðráág tö möövé ááłöñg théé röüüté.',
      'other':
          'Rööütéé övéérvíééw. $length tö théé ƒíñííšh. Ðrág töö mövéé áłööñg thé rööütéé.',
    });
    return '[$_temp0~~~~~~~~~~~]';
  }

  @override
  String builderRouteRepsSemantics(String target, String length, String reps) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'boss':
          'Rööütéé övéérvíééw. $length tö théé böšš. $reps. Ðráág tö möövé ááłöñg théé röüüté.',
      'other':
          'Rööütéé övéérvíééw. $length tö théé ƒíñííšh. $reps. Ðrág töö mövéé áłööñg thé rööütéé.',
    });
    return '[$_temp0~~~~~~~~~~~~]';
  }

  @override
  String builderRouteToBoss(String length) {
    return '[$length töö thé bööšš~~~~]';
  }

  @override
  String get builtResultTestFlight => '[TÉÉŠT FŁÎGHT~~~]';

  @override
  String get builtResultCleared => '[Çłééárééð!~]';

  @override
  String get builtResultBonk => '[Bööñk!~]';

  @override
  String get builtResultLanded => '[Łááñðéð~~]';

  @override
  String get builtResultTestTab => '[TÉÉŠT~]';

  @override
  String get builtResultGoalFinish => '[Fííñíšh~~]';

  @override
  String get builtResultGoalBoss => '[Bööšš~]';

  @override
  String builtResultGoalSemantics(String goal) {
    return '[$goal.~~]';
  }

  @override
  String builtResultGoalDoneSemantics(String goal) {
    return '[$goal. Ðööñé.~~~]';
  }

  @override
  String builtResultMarkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çööłłéçt $count štáárš.',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String builtResultMarkDoneSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çööłłéçt $count štáárš. Ðöñéé.',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String get builtResultDone => '[Ðööñé~]';

  @override
  String get builtResultNotYet => '[Ñööt ýét~~]';

  @override
  String builtResultToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count töö gö',
    );
    return '[$_temp0~~~]';
  }

  @override
  String get builtResultFinishFirst => '[Fííñíšh ƒííršt~~~]';

  @override
  String get builtResultClearedByYou => '[ÇŁÉÉÅRÉÉÐ BÝ ÝØÛÛ~~]';

  @override
  String get builtResultNewBest => '[ÑÉÉW BÉŠT!~~]';

  @override
  String get builtResultPractice => '[Þrááçtíçéé~~]';

  @override
  String builtResultBest(int count) {
    return '[Bééšt $count~~~]';
  }

  @override
  String get builtResultFirstClear => '[Fííršt çłéáár!~~]';

  @override
  String get builtResultStarsCollected => '[ŠTÅÅRŠ ÇØŁŁÉÉÇTÉÐ~~~~]';

  @override
  String builtResultRatingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ööƒ 3 łévééł štárš',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String get builtResultAsksFor => '[ÅÅŠKŠ FØR~~]';

  @override
  String get builtResultWorkout => '[WØØRKØÛÛT~]';

  @override
  String get builtResultGotTo => '[GØØT TØ~]';

  @override
  String get builtResultScore => '[ŠÇØØRÉ~]';

  @override
  String builtResultPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'þüüšh-üþš',
    );
    return '[$_temp0~~]';
  }

  @override
  String builtResultSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'šqüüátš',
    );
    return '[$_temp0~~]';
  }

  @override
  String builtResultJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jüümþš',
    );
    return '[$_temp0~]';
  }

  @override
  String builtResultPushUpsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'þüüšh-üþš ööñ çáméérá',
    );
    return '[$_temp0~~~]';
  }

  @override
  String builtResultSquatsOnCamera(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'šqüüátš ööñ çáméérá',
    );
    return '[$_temp0~~~]';
  }

  @override
  String builtResultOfLength(String length) {
    return '[ööƒ $length~~]';
  }

  @override
  String get builtResultNotKept => '[Ñööt kéþt~~]';

  @override
  String get builtResultNoBest => '[Ñöö béšt ýéét~~]';

  @override
  String get builtResultClearedStrip =>
      '[Çłééárééð bý ýöüü · réááðý tö šhááré!~~~~~]';

  @override
  String builtResultFlownFrom(String from) {
    return '[Fłööwñ ƒröm $from. Fłý íít áłł töö çłéáár ít.~~~~~~~~]';
  }

  @override
  String get builtResultTestNothingSaved =>
      '[Tééšt ƒłíght · ñööthíñg ííš šávééð~~~~~~]';

  @override
  String builtResultTestGotTo(String reached, String length) {
    return '[Tééšt ƒłíght · gööt tö $reached ööƒ $length~~~~~~~]';
  }

  @override
  String builtResultGotToFinish(String reached, String length) {
    return '[Gööt tö $reached ööƒ $length. Réááçh thé ƒííñíšh ƒöör štárš.~~~~~~~~~~]';
  }

  @override
  String get builtResultReachFinish =>
      '[Rééáçh théé ƒíñííšh tö ééárñ štáárš.~~~~~]';

  @override
  String get builtResultSaved => '[Šáávéð ööñ thíš þhööñé~~~~]';

  @override
  String get builtResultSaving => '[Šáávíñg ýööür ƒłííght…~~~~]';

  @override
  String get builtResultBuilder => '[Büüíłðéér~]';

  @override
  String get builtResultEditLevel => '[ÉÉðít łéévéł~~]';

  @override
  String get builtResultEdit => '[ÉÉðít~]';

  @override
  String get builtResultFlyAgain => '[Fłý áágáííñ~~]';

  @override
  String get builtResultWatchReplay => '[Wáátçh réþłááý~~~]';

  @override
  String get builtResultPreparing => '[Þrééþárííñg…~~]';

  @override
  String get builtResultSessionSaving => '[Šáávíñg…~~]';

  @override
  String get builtResultSaveSession => '[Šáávé šééššíööñ~~]';

  @override
  String get builderShelfTitle => '[Łéévéł Büüíłðéér~~]';

  @override
  String get builderShelfPasteCode => '[Þáášté çööðé~~]';

  @override
  String get builderShelfNewLevel => '[Ñééw łévééł~~]';

  @override
  String get builderShelfSaveFailed =>
      '[Tháát ðíðñ’t šáávé. Þłééášéé trý ágááíñ.~~~~~~]';

  @override
  String builderShelfDeleteTitle(String name) {
    return '[Ðééłétéé “$name”?~~]';
  }

  @override
  String get builderShelfDeleteBody =>
      '[ÎÎtš béštš göö wíth íít. Þüšh-üüþš, šqüáátš áñð jüümþš ýöüü ƒłéw ööñ ít štííłł çöüüñt.~~~~~~~~~~~~~~]';

  @override
  String get builderShelfDelete => '[Ðééłétéé~]';

  @override
  String builderShelfDeleted(String name) {
    return '[Ðééłétééð “$name”.~~~]';
  }

  @override
  String get builderShelfFixFirst =>
      '[Fííx whát’š máárkéð ííñ réð bééƒöréé šhárííñg: táþ Fííx ít.~~~~~~~~~]';

  @override
  String get builderShelfCodeCopied =>
      '[Çööðé çööþíééð! Þáštéé ít töö á ƒrííéñð.~~~~~]';

  @override
  String get builderShelfCodeCopiedUncleared =>
      '[Çööðé çööþíééð! Fłý ít töö thé ƒííñíšh tööö, šöö ƒríééñðš kñöw íít çáñ béé ðöñéé.~~~~~~~~~~~]';

  @override
  String get builderShelfNotReady =>
      '[Thííš łévééł íšñ’t rééáðý töö ƒłý ýét: tááþ Fíx íít.~~~~~~~~]';

  @override
  String get builderShelfPasteMissingTitle =>
      '[Ñöö łévééł çöðéé tö þáášté~~~~]';

  @override
  String get builderShelfPasteNewerTitle =>
      '[ÅÅ łévééł ƒröm áá ñéwéér Béáákböüüñð~~~~]';

  @override
  String get builderShelfPasteDamagedTitle =>
      '[Tháát çöðéé göt šçráámbłéð~~~~~]';

  @override
  String get builderShelfPasteMissingBody =>
      '[Çööþý á ƒrííéñð’š łéévéł çööðé (íít štártš wííth BÉÅÅK1.) áñð tááþ Þáštéé çöðéé ágááíñ.~~~~~~~~~~~~]';

  @override
  String get builderShelfPasteNewerBody =>
      '[ÛÛþðátéé Béáákböüüñð tö ƒłý íít, théñ þáášté théé çöðéé ágááíñ.~~~~~~~~~]';

  @override
  String get builderShelfPasteDamagedBody =>
      '[Þáárt öƒ íít íš mííššíñg öör míštýþééð. Åšk ýööür ƒrííéñð töö çöþý théé whöłéé çöðéé ágááíñ.~~~~~~~~~~~~~~]';

  @override
  String builderShelfImported(String name) {
    return '[“$name” ííš öñ ýööür šhééłƒ!~~~~]';
  }

  @override
  String get builderShelfUnavailable => '[Ýööür łéévéłš ñéééð áá mömééñt.~~~~]';

  @override
  String get builderShelfMine => '[Mý łéévéłš~~~]';

  @override
  String get builderShelfStarters => '[Štáártér łéévéłš~~~~]';

  @override
  String get builderShelfStartersHint =>
      '[Fłý ööñé, öör rémííx ít ííñtö áá łévééł öƒ ýööür ööwñ~~~~~~]';

  @override
  String get builderShelfEmptyTitle => '[Büüíłð ýööür ƒííršt łévééł~~~~]';

  @override
  String get builderShelfEmptyBody =>
      '[Þłááçé gáátéš, štáárš áñð hééártš bý hááñð, šét théé ƒíñííšh łíñéé áñð tééšt ƒłý ít.~~~~~~~~~~~~~~~]';

  @override
  String get builderShelfPasteFriend => '[Þáášté áá ƒríééñð’š çöðéé~~~]';

  @override
  String get builderShelfNeedsWork => '[Ñéééðš wöörk~~]';

  @override
  String get builderShelfClearedByYou => '[Çłééárééð bý ýöüü~~]';

  @override
  String get builderShelfFromFriend => '[Frööm á ƒrííéñð~~~]';

  @override
  String get builderShelfFly => '[Fłý~~]';

  @override
  String builderShelfFlySemantics(String name) {
    return '[Fłý $name~~~]';
  }

  @override
  String get builderShelfFixIt => '[Fííx ít~]';

  @override
  String builderShelfFixSemantics(String name) {
    return '[Fííx $name~~]';
  }

  @override
  String builderShelfEditSemantics(String name) {
    return '[ÉÉðít $name~~~]';
  }

  @override
  String builderShelfShareSemantics(String name) {
    return '[Šhááré $name~~~]';
  }

  @override
  String builderShelfShareClearedSemantics(String name) {
    return '[Šhááré $name: ýööü çłééárééð ít~~~~~]';
  }

  @override
  String builderShelfMoreSemantics(String name) {
    return '[Mööré ƒöör $name~~~]';
  }

  @override
  String get builderShelfRemix => '[Réémíx~]';

  @override
  String builderShelfRemixSemantics(String name) {
    return '[Réémíx $name~~~]';
  }

  @override
  String builderShelfToFixInEditor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thííñgš tö ƒííx íñ théé éðíítör',
      one: '1 thííñg tö ƒííx íñ théé éðíítör',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String builderShelfStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count štáárš',
    );
    return '[$_temp0~~~]';
  }

  @override
  String builderShelfLevelSemantics(
    String name,
    String mode,
    String region,
    String length,
  ) {
    return '[$name. $mode ííñ $region. $length.~~~~~~~]';
  }

  @override
  String builderShelfBestSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Bééšt $stars öƒ 3 štáárš.',
    );
    return '[$_temp0~~~~]';
  }

  @override
  String builderShelfNeedsWorkSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ñéééðš wöörk: $count thíñgš töö ƒíx.',
      one: 'Ñéééðš wöörk: 1 thíñg töö ƒíx.',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get builderShelfClearedSemantics => '[Çłééárééð bý ýöüü.~~]';

  @override
  String get builderShelfFromFriendSemantics => '[Frööm á ƒrííéñð.~~~]';

  @override
  String builderShelfStarterSemantics(
    String name,
    String mode,
    String length,
    String fact,
  ) {
    return '[Łööök áát $name. $mode, $length, $fact.~~~~~~~]';
  }

  @override
  String get builderShelfRemixSuffix => '[réémíx~]';

  @override
  String get builderShelfCopySuffix => '[çööþý~]';

  @override
  String get commonOk => '[ØØK]';

  @override
  String get commonCancel => '[Çááñçéł~~]';

  @override
  String get starter_t_tap_1_name => '[Gáárðéñ Hööþ~~]';

  @override
  String get starter_t_push_1_name => '[Tééñ Þüšh-ÛÛþš~~]';

  @override
  String get starter_t_squat_1_name => '[Štááír Šqüüátš~~~]';

  @override
  String get starter_t_jump_1_name => '[Bööüñçéé Báý~~]';

  @override
  String get starter_t_tap_boss_name => '[Bááröñ’š Brííðgé~~~]';

  @override
  String get builderPickCloseNewLevel => '[Çłööšé ñééw łévééł~~~]';

  @override
  String get builderPickModeTitle => '[Wháát wíłł íít bé?~~~]';

  @override
  String get builderPickRegionTitle => '[Whééré ðööéš íít ƒłý?~~~]';

  @override
  String get builderPickModeSubtitle =>
      '[Þííçk höw íít’š ƒłöwñ (ýööü çááñ’t çháñgéé ít łáátér). Ýööü tééšt ƒłý évéérý łévééł bý töüüçh.~~~~~~~~~~~~~~]';

  @override
  String builderPickRegionSubtitle(String mode) {
    return '[$mode · þííçk whéréé ít ƒłííéš. Ýööü çááñ çháñgéé thíš łáátér.~~~~~~~~~~]';
  }

  @override
  String get builderPickTouchLine =>
      '[Tááþ tö ƒłááþ. Gátééš, štárš, ééñémííéš ááñð á bööšš.~~~~~~~]';

  @override
  String get builderPickPushUpLine =>
      '[ÅÅ hígh łááñé ááñð á łööw öñéé: évéérý ðíþ ííš á þüüšh-üþ.~~~~~~~]';

  @override
  String get builderPickSquatLine =>
      '[ÅÅ hígh łááñé ááñð á łööw öñéé: évéérý ðíþ ííš á šqüüát.~~~~~~]';

  @override
  String get builderPickJumpLine =>
      '[Jüümþ ƒör łííƒt. Gátééš áñýwhééré ííñ thé šký.~~~~~~~~]';

  @override
  String builderPickModeSemantics(String mode, String line) {
    return '[$mode. $line~~~~]';
  }

  @override
  String get builderPickCamera => '[Çááméráá~]';

  @override
  String get builderPickSuggested => '[Šüüggéštééð~~]';

  @override
  String builderPickSuggestedSemantics(String region) {
    return '[$region, šüüggéštééð~~~~]';
  }

  @override
  String get builderPickClose => '[Çłööšé~]';

  @override
  String get builderPickNotYet =>
      '[Ñööt ýét: ƒííx whát’š máárkéð ííñ réð ƒííršt.~~~~~~~]';

  @override
  String get builderPickShare => '[Šhááré çööðé~~]';

  @override
  String get builderPickShareLine =>
      '[Çööþý á çööðé áá ƒríééñð çáñ þáášté ííñtö thééír Bééákbööüñð.~~~~~~~~]';

  @override
  String get builderPickDuplicate => '[Ðüüþłíçááté~~]';

  @override
  String get builderPickDuplicateLine =>
      '[Mááké áá çöþý töö trý áñööthér ííðéáá.~~~~]';

  @override
  String get builderPickDeleteLine =>
      '[Thrööw thé łéévéł ááwáý. Ýööü’łł béé áškééð ƒíršt.~~~~~~~~]';

  @override
  String builderPickLevelSubtitle(String mode, String region) {
    return '[$mode · $region~~~~]';
  }

  @override
  String get builderPickCancelImport => '[Çááñçéł íímþört~~~]';

  @override
  String get builderPickImportTitle => '[ÅÅ łévééł tö ƒłý!~~~]';

  @override
  String get builderPickImportSubtitle =>
      '[Šööméööñé šhááréð thííš łévééł wíth ýööü.~~~~~~]';

  @override
  String get builderPickClearedByMaker => '[Çłééárééð bý ítš máákér~~~~]';

  @override
  String builderPickStarsToCollect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count štáárš tö çööłłéçt',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String builderPickEndsWith(String boss, String bossId) {
    String _temp0 = intl.Intl.selectLogic(bossId, {
      'other': 'ÉÉñðš wíth $boss',
    });
    return '[$_temp0~~~~]';
  }

  @override
  String get builderPickNotFlown =>
      '[ÎÎtš mákéér hášñ’t ƒłööwñ ít töö thé ééñð ýét.~~~~~~~~]';

  @override
  String get builderPickRoute => '[Théé röüüté~~]';

  @override
  String builderPickAlreadyHave(String name) {
    return '[Ýööü ááłréááðý hávéé thíš łéévéł: “$name”.~~~~~~]';
  }

  @override
  String get builderPickImportCopy => '[ÎÎmþört áá çöþý~~~]';

  @override
  String get builderPickOpenYours => '[ØØþéñ ýööürš~~]';

  @override
  String get builderPickImport => '[ÎÎmþört~~]';

  @override
  String get builderShelfRenameCancelSemantics => '[Çááñçéł rééñáméé~~]';

  @override
  String get builderShelfRenameTitle => '[Ñáámé ýööür łéévéł~~~]';

  @override
  String get builderShelfRenameEmpty =>
      '[ÅÅ ñáméé ñéééðš á łééttér öör twö~~~~]';

  @override
  String get builderShelfRenameSaveSemantics => '[Šáávé ñáámé~~]';

  @override
  String get builderShelfRenameSave => '[Šáávé~]';

  @override
  String get coopMode_roped => '[Rööþéð~]';

  @override
  String get coopMode_free => '[Ñöö röþéé~]';

  @override
  String get coopMode_duel => '[1 v 1~]';

  @override
  String get coopTitle => '[Fłý Töögéthéér~~~]';

  @override
  String get coopPlayersTag => '[TWØØ ÞŁÅÝÉÉRŠ · ØÑÉÉ ÞHØÑÉÉ~~~~]';

  @override
  String coopBestTag(String mode, int best) {
    return '[$mode BÉÉŠT $best~~~~]';
  }

  @override
  String coopNoBestTag(String mode) {
    return '[$mode: ÑØØ BÉŠT ÝÉÉT~~~~]';
  }

  @override
  String duelCountTag(String mode, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mode · $count ÐÛÛÉŁŠ',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String duelFirstTag(String mode) {
    return '[$mode: FÎÎRŠT ÐÛÉÉŁ~~~~]';
  }

  @override
  String get coopRopedLead => '[Ýööür bíírðš šháréé öñéé röþéé.~~~~]';

  @override
  String get coopRopedBody =>
      '[Fłááþ tögééthér töö çłímb híígh: á bíírð ƒłáþþííñg áłööñé łííƒtš böth, büüt öñłý áá łíttłéé. Šþríñt töö ðrág ýööür þáártñér ááłöñg.~~~~~~~~~~~~~~~~~~~~~~]';

  @override
  String get coopFreeLead => '[Ñöö röþéé:~]';

  @override
  String get coopFreeBody =>
      '[ééáçh bíírð ƒłíééš öñ íítš öwñ ááñð öñłý büümþš íñtöö thé ööthér. Hééártš, šhííéłð ááñð šçöréé áréé štíłł šhááréð.~~~~~~~~~~~~~~~~~~]';

  @override
  String get duelLead => '[Fííght!~]';

  @override
  String get duelBody =>
      '[ÉÉáçh bíírð háš íítš öwñ hééártš. Grááb mýštérý bööxéš: šöömé šééñð bátš, áá šþíttéér ör méétéöörš át ýööür rííváł, ööthérš brííñg á hééárt, áá šhíééłð ör štáár þöwéér. Łášt bíírð ƒłýíñg wííñš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]';

  @override
  String get coopStart => '[Fłý töögéthéér~~~]';

  @override
  String get duelStart => '[Fííght!~]';

  @override
  String get coopFlightSemantics =>
      '[Þłááýér 1 tááþš thé łééƒt háłƒ töö ƒłáþ, þłááýér 2 théé ríght hááłƒ~~~~~~~~~~~]';

  @override
  String get coopPauseSemantics => '[Þááüšéé ƒłíght~~~]';

  @override
  String coopShootSemantics(int player) {
    return '[Þłááýér $player šhöööt~~~~]';
  }

  @override
  String coopSprintSemantics(int player) {
    return '[Þłááýér $player šþrííñt~~~~~]';
  }

  @override
  String coopPlayerShort(int player) {
    return '[Þ$player~~]';
  }

  @override
  String coopPlayerCaps(int player) {
    return '[ÞŁÅÅÝÉR $player~~~]';
  }

  @override
  String coopMagnetSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Štáár mágñéét: $seconds šéçööñðš rémááíñííñg',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String coopMagnetChargingSemantics(int charge, int gates) {
    String _temp0 = intl.Intl.pluralLogic(
      gates,
      locale: localeName,
      other: 'Máágñét çháárgíñg: $charge ööƒ $gates þérƒééçt gátééš',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String coopSecondsShort(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$secondsš',
    );
    return '[$_temp0~~]';
  }

  @override
  String get coopCountdownRoped => '[Rööþé ööñ. Réááðý, štéááðý…~~~]';

  @override
  String get coopCountdownFree => '[Rééáðý, štééáðý…~~~]';

  @override
  String get duelCountdown => '[Rééáðý töö ðüééł…~~]';

  @override
  String get coopCountdownRopedHint =>
      '[Fłááþ tögééthér töö çłímb híígh.\nŠþríñt töö ðrág ýööür þáártñér ááłöñg!~~~~~~~~~~~~~]';

  @override
  String get coopCountdownFreeHint =>
      '[ÉÉáçh bíírð ƒłíééš öñ íítš öwñ.\nŠhááré théé héáártš, béáát thé gáátéš!~~~~~~~~~~]';

  @override
  String get duelCountdownHint =>
      '[Grááb thé mýštéérý böxééš!\nŁášt bíírð ƒłýíñg wííñš.~~~~~~~~~~]';

  @override
  String duelStarPowerSemantics(int player, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Þłááýér $player štáár þöwéér: $seconds šéçööñðš łéƒt',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get coopHome => '[Höömé~]';

  @override
  String get coopChangeBirds => '[Çhááñgé bíírðš~~~]';

  @override
  String get coopSaved => '[Šáávéð~]';

  @override
  String get coopSaving => '[Šáávíñg…~~]';

  @override
  String get coopSaveSession => '[Šáávé šééššíööñ~~]';

  @override
  String get duelRematch => '[Réémátçh~~]';

  @override
  String get coopFlyAgain => '[Fłý áágáííñ~~]';

  @override
  String duelWinner(int player) {
    return '[Þłááýér $player wííñš!~~~~]';
  }

  @override
  String get duelDraw => '[ÅÅ ðráw!~]';

  @override
  String get duelStopped => '[Ðüüéł štööþþéð~~~]';

  @override
  String duelVersusCaption(String first, String second) {
    return '[$first vš $second~~~~]';
  }

  @override
  String duelBeatCaption(String winner, String loser) {
    return '[$winner bééát $loser~~~~]';
  }

  @override
  String duelPrizeAttack(String prize, int rival) {
    return '[$prize áát Þ$rival!~~~~]';
  }

  @override
  String duelPrizeHelp(String prize) {
    return '[$prize!~~]';
  }

  @override
  String get duelPrize_batSwarm => '[Báát šwárm~~~]';

  @override
  String get duelPrize_spitter => '[Šþííttér bééétłéé~~~]';

  @override
  String get duelPrize_meteorShower => '[Méétéöör šhöwéér~~]';

  @override
  String get duelPrize_heart => '[Hééárt~]';

  @override
  String get duelPrize_shield => '[Šhííéłð~~]';

  @override
  String get duelPrize_starPower => '[Štáár þöwéér~~]';

  @override
  String get coopTapLeftHalf => '[Tááþ thé łééƒt háłƒ~~~~]';

  @override
  String get coopTapRightHalf => '[Tááþ thé rííght háłƒ~~~~]';

  @override
  String coopPickSemantics(int player, String bird) {
    return '[Þłááýér $player: $bird~~~~~]';
  }

  @override
  String coopSideHint(int player) {
    return '[Þ$player · tááþ thíš šííðé~~~~~]';
  }

  @override
  String get coopKeysP1 => '[Þ1 · W ƒłááþ · Ð šhöööt · Å šþrííñt~~~~~]';

  @override
  String get coopKeysP2 =>
      '[Þ2 · ÛÛþ ƒłáþ · Rííght šhöööt · Łéƒt šþrííñt~~~~~~~]';

  @override
  String get coopRopedSemantics => '[Rööþéð: théé bírðš šhááré áá röþéé~~~~~]';

  @override
  String get coopFreeSemantics =>
      '[Ñöö röþéé: éááçh bírð ƒłííéš ööñ ítš ööwñ~~~~~]';

  @override
  String get duelModeSemantics =>
      '[1 v 1: théé bírðš ƒííght éááçh öthéér~~~~~~]';

  @override
  String get duelVersus => '[VŠ~]';

  @override
  String get coopSessionSaved =>
      '[Šééššíööñ šávééð · Wátçh ííñ Réçöörðš~~~~~~]';

  @override
  String get coopNewTeamBest => '[Ñééw téáám béšt!~~~]';

  @override
  String get coopWhatATeam => '[Wháát á tééám.~~]';

  @override
  String coopPairCaption(String first, String second) {
    return '[$first & $second~~~~]';
  }

  @override
  String get coopTeamScore => '[TÉÉÅM ŠÇØØRÉ~~]';

  @override
  String get coopTeamBest => '[TÉÉÅM BÉÉŠT~~]';

  @override
  String get coopNewTeamBestRibbon => '[ÑÉÉW TÉÅÅM BÉŠT!~~~]';

  @override
  String get coopStatFlightTime => '[ƒłííght tíméé~~]';

  @override
  String coopStatStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'štáárš',
    );
    return '[$_temp0~]';
  }

  @override
  String coopStatGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gáátéš',
    );
    return '[$_temp0~]';
  }

  @override
  String get coopFlapShare => '[FŁÅÅÞ ŠHÅRÉÉ~~]';

  @override
  String coopPercent(int percent) {
    return '[$percent%~~]';
  }

  @override
  String coopPlayerFlaps(int count, int player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Þ$player ƒłááþš',
    );
    return '[$_temp0~~~]';
  }

  @override
  String duelTime(String time) {
    return '[Ðüüéł tíímé $time~~~]';
  }

  @override
  String get duelSeries => '[ŠÉÉRÎÉÉŠ~]';

  @override
  String get duelHeartsLeft => '[hééártš łééƒt~~]';

  @override
  String get duelBoxesOpened => '[bööxéš ööþéñééð~~]';

  @override
  String get duelHitsLanded => '[híítš łáñðééð~~]';

  @override
  String get coopPauseSubtitle =>
      '[Ýööü’réé böth þéérçhéð ááñð wáíítíñg. Wéé’łł çöüüñt ýöüü böth ííñ.~~~~~~~~~]';

  @override
  String get coopFinishFlight => '[Fííñíšh ƒłííght~~~]';

  @override
  String get cameraLabIntro =>
      '[Þrööþ ýöüür þhöñéé łöw ííñ łáñðšçááþé, ƒááçíñg ýööü öör béšííðé ýööü.~~~~~~~~~]';

  @override
  String cameraLabAlmostThere(String parts) {
    return '[ÅÅłmöšt thééré · ñéééð áá çłéáárér $parts~~~~~~]';
  }

  @override
  String get cameraLabJointShoulder => '[šhööüłðéér~~]';

  @override
  String get cameraLabJointElbow => '[ééłböw~]';

  @override
  String get cameraLabJointWrist => '[wrííšt~]';

  @override
  String get cameraLabJointHip => '[hííþ~]';

  @override
  String cameraLabJointList(String first, String rest) {
    return '[$first, $rest~~~~]';
  }

  @override
  String get cameraLabStarting => '[Štáártíñg çááméráá…~~~]';

  @override
  String get cameraLabDenied =>
      '[Çááméráá áççééšš íš ööƒƒ. Åłłööw ít ííñ áþþ šééttíñgš, thééñ trý ágááíñ.~~~~~~~~~~~]';

  @override
  String cameraLabFailed(String error) {
    return '[Çááméráá çöüüłð ñöt štáárt: $error~~~~~~]';
  }

  @override
  String get cameraLabStopped =>
      '[Çááméráá štöþþééð. Táþ Štáárt tö rééçáłííbrátéé.~~~~~~~]';

  @override
  String get cameraLabBack => '[ÇÅÅMÉRÅÅ ŁÅB · Bááçk tö höömé~~~~]';

  @override
  String get cameraLabStepShow => '[1. Šhööw ýöüür ármš & hííþ~~~]';

  @override
  String get cameraLabStepPushUps => '[2. Ðöö twö þüüšh-üþš~~~]';

  @override
  String get cameraLabStepMove => '[3. Möövé ýööür bíírð!~~]';

  @override
  String get cameraLabStepSquat => '[Fííñð ýöüür šqüáát ráñgéé~~~~]';

  @override
  String get cameraLabStepJump => '[Fííñð ýöüür štáñðííñg þöšíítíööñ~~~~~]';

  @override
  String get cameraLabPushUpHelp =>
      '[Þhööñé łööw, ƒáçííñg ýöüü ör bééšíðéé ýöüü.\nFáçííñg ít? Šhööw böth šhööüłðéérš, áñ áárm áñð hííþ.\nMövéé ðöwñ ááñð üþ twííçé áát ýöüür öwñ þááçé.~~~~~~~~~~~~~~~~~~~]';

  @override
  String get cameraLabSquatHelp =>
      '[Štááñð štíłł, šqüüát çöömƒörtáábłý áñð hööłð bríééƒłý, théñ štááñð báçk üüþ. Šqüáát tö ðééšçéñð; štááñð tö rííšé.~~~~~~~~~~~~~~~~~~~~]';

  @override
  String get cameraLabJumpHelp =>
      '[Štááñð ƒáçííñg thé þhööñé wííth ýöüür whöłéé böðý ááñð ƒééét víšííbłé. Hööłð štíłł, thééñ mákéé šmáłł jüümþš. Øñéé jümþ = ööñé bííg böööšt.~~~~~~~~~~~~~~~~~~~~~]';

  @override
  String cameraLabCalibrationCount(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'ÇÅÅŁÎBRÅÅTÎØØÑ\n$done / $total çáłííbrátééð',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String cameraLabCalibrationPercent(int percent) {
    return '[ÇÅÅŁÎBRÅÅTÎØØÑ\n$percent% çáłííbrátééð~~~~~]';
  }

  @override
  String cameraLabTestPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ÇØØÑTRØŁ TÉÉŠT\n$count þüšh-üüþš',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String cameraLabTestSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ÇØØÑTRØŁ TÉÉŠT\n$count šqüáátš',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String cameraLabTestJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ÇØØÑTRØŁ TÉÉŠT\n$count jümþš',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String cameraLabRate(String hz, String ms) {
    return '[$hz Hž · $ms mš þ95~~~~~~]';
  }

  @override
  String get cameraLabStartingButton => '[Štáártíñg…~~~]';

  @override
  String get cameraLabRecalibrate => '[Rééçáłííbrátéé~~]';

  @override
  String get cameraLabStartCamera => '[Štáárt çáméérá~~~]';

  @override
  String get cameraLabTapStart => '[Tááþ Štárt çááméráá~~~]';

  @override
  String cameraLabTry(String mode) {
    return '[Trý $mode~~~]';
  }

  @override
  String get cameraBadgeWaking => '[WÅÅKÎÑG~~]';

  @override
  String get cameraBadgeLive => '[ŁÎÎVÉ~]';

  @override
  String get cameraBadgeLockedOn => '[ŁØØÇKÉÐ ØØÑ~~]';

  @override
  String get cameraBadgeOffline => '[ØØFFŁÎÑÉÉ~]';

  @override
  String get trackingCatchingUp => '[Çááméráá íš çáátçhíñg üüþ~~~~]';

  @override
  String get trackingStepIntoOutline => '[Štééþ íñtöö thé bööðý öüütłíñéé~~~~]';

  @override
  String get trackingKeepShoulders => '[Kéééþ bööth šhöüüłðérš ííñ víééw~~~~~]';

  @override
  String get trackingShowSide =>
      '[Šhööw öñéé šhöüüłðér, ééłböw, wrííšt áñð hííþ ƒröm théé šíðéé~~~~~~~~~]';

  @override
  String get trackingMoveCloser => '[Möövé áá łíttłéé çłöšéér~~~]';

  @override
  String get trackingGetDown =>
      '[Géét ðöwñ ííñtö ýööür þüüšh-üþ þööšítííöñ~~~~~~]';

  @override
  String get trackingHandsOnFloor =>
      '[Þüüt ýöüür háñðš ööñ thé ƒłööör ááñð éxtééñð ýöüür böðý bééhíñð ýööü~~~~~~~~~~~]';

  @override
  String get trackingExtendBody =>
      '[ÉÉxtéñð ýööür bööðý á łííttłé ƒáárthér bééhíñð ýööür hááñðš~~~~~~~~~~]';

  @override
  String get trackingComfortableRange =>
      '[Štááý wíthííñ á çöömƒörtáábłé þüüšh-üþ rááñgé~~~~~~~~]';

  @override
  String get trackingPlaceHands =>
      '[Þłááçé ýööür hááñðš öñ théé ƒłööör wíth ýööür bööðý béhííñð thém~~~~~~~~~~~]';

  @override
  String get trackingFrontTracked =>
      '[Frööñt víééw tráçkééð · kéééþ ýöüür háñðš ííñ víééw~~~~~~~]';

  @override
  String get trackingBodyInView =>
      '[Bööðý íñ vííéw · ƒááçé çááñ łööök ðöwñ~~~~~]';

  @override
  String get trackingArmsTracked =>
      '[ÅÅrmš tráçkééð · łég çhééçk łímíítéð~~~~~~~]';

  @override
  String get trackingFindTop => '[Fííñð á çöömƒörtáábłé tööþ þöšíítíööñ~~~~~]';

  @override
  String get trackingCalibrated =>
      '[Çááłíbráátéð! Trý möövíñg ýööür bíírð.~~~~~~]';

  @override
  String get trackingFreshFrame => '[Wááítííñg ƒör áá ƒréšh ƒráámé~~~~~]';

  @override
  String get trackingDistanceChanged =>
      '[Çááméráá ðíštááñçé çhááñgéð · rééçáłííbrátéé~~~~~~]';

  @override
  String get trackingKeepArm => '[Kéééþ ááñ árm ííñ víééw~~]';

  @override
  String get trackingSquatStepBack =>
      '[Štééþ báçk šöö ýöüür šhöüüłðérš, hííþš, kñéééš áñð ƒééét ááré ííñ víééw~~~~~~~~~~]';

  @override
  String get trackingSquatFaceCamera =>
      '[Fááçé théé çáméérá wííth böth ƒééét ööñ thé ƒłööör~~~~~~~]';

  @override
  String get trackingSquatControls =>
      '[Šqüüát töö ðéšçééñð · štáñð töö ríšéé~~~~~]';

  @override
  String get trackingStartingDistance =>
      '[Fááçé théé çáméérá áát ýöüür štártííñg ðíštááñçé · rééçáłííbrátéé íƒ ýööü möövéð~~~~~~~~~~~]';

  @override
  String get trackingFeetPlanted =>
      '[Kéééþ bööth ƒééét þłáñtééð íñ ýööür štáártíñg šþööt~~~~~~~~]';

  @override
  String get trackingSquatStandTall =>
      '[Štááñð táłł ááñð štíłł wííth böth ƒééét ííñ víééw~~~~~~~~]';

  @override
  String get trackingStandStill =>
      '[Štááñð táłł ááñð štíłł ƒöör á mööméñt~~~~~~~]';

  @override
  String get trackingSquatDepth =>
      '[Šqüüát töö á çöömƒörtáábłé ðééþth áñð hööłð bríééƒłý~~~~~~~~~]';

  @override
  String get trackingSquatHold =>
      '[Šqüüát çöömƒörtáábłý, théñ hööłð ƒör áá mömééñt~~~~~~~~]';

  @override
  String get trackingSquatHoldBriefly =>
      '[Hööłð thíš çöömƒörtáábłé šqüüát brííéƒłý~~~~~~~~]';

  @override
  String get trackingSquatStandUp =>
      '[Štááñð báçk üüþ tö ƒííñíšh çááłíbráátíööñ~~~~~~]';

  @override
  String get trackingSquatReady =>
      '[Rééáðý! Šqüüát töö ðéšçééñð · štáñð töö ríšéé~~~~~~]';

  @override
  String get trackingJumpStepBack =>
      '[Štééþ báçk šöö ýöüür šhöüüłðérš, hííþš áñð bööth ƒééét áréé íñ vííéw~~~~~~~~~~]';

  @override
  String get trackingJumpFaceCamera =>
      '[Štááñð ƒáçííñg thé çááméráá wíth röööm áábövéé ýöüü tö jüümþ~~~~~~~~]';

  @override
  String get trackingJumpSmall =>
      '[Šmááłł jümþš ááré ééñöüügh · łáñð bééƒöréé jümþííñg ágááíñ~~~~~~~~~]';

  @override
  String get trackingJumpStandStill =>
      '[Štááñð štíłł wííth ýöüür whöłéé böðý ááñð böth ƒééét ííñ víééw~~~~~~~~~~]';

  @override
  String get trackingJumpReady =>
      '[Rééáðý! ØØñé šmááłł jümþ gíívéš ööñé bííg böööšt.~~~~~~~]';

  @override
  String get trackingFindPosition => '[Fííñð ýöüür þöšíítíööñ~~~]';

  @override
  String get trackingInterrupted => '[Trááçkíñg ííñtérrüüþtéð~~~~~]';

  @override
  String get trackingCameraInterrupted =>
      '[Çááméráá íñtéérrüþtééð. Çhéçk çááméráá þérmííššíööñ áñð trý áágáííñ.~~~~~~~~~~]';

  @override
  String get trackingCameraAway =>
      '[Çááméráá štöþþééð whíłéé thé ááþþ wáš ááwáý~~~~~~~]';

  @override
  String get trackingJumpBoost => '[Jüümþ ƒör áá bíg böööšt~~~~]';

  @override
  String get trackingJumpLand => '[Łááñð tö þrééþáréé ýöüür ñéxt jüümþ~~~~~]';

  @override
  String trackingLowerMore(int step, int total) {
    return '[Łööwér áá łíttłéé möréé · $step öƒ $total~~~~~~~]';
  }

  @override
  String trackingLowerComfortably(int step, int total) {
    return '[Łööwér çöömƒörtáábłý · $step öƒ $total~~~~~~~~]';
  }

  @override
  String trackingPushBackUp(int step, int total) {
    return '[Þüüšh báçk üüþ · $step öƒ $total~~~~~~]';
  }

  @override
  String trackingMatchRange(int step, int total) {
    return '[Máátçh ýöüür ƒíršt çöömƒörtáábłé rááñgé · $step ööƒ $total~~~~~~~~~~]';
  }

  @override
  String commonSaveFailed(String error) {
    return '[Çööüłð ñööt šávéé thíš çhááñgé. Þłééášéé trý ágááíñ. ($error)~~~~~~~~~]';
  }

  @override
  String get commonDelete => '[Ðééłétéé~]';

  @override
  String commonMoreToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mööré töö gö',
    );
    return '[$_temp0~~~]';
  }

  @override
  String get homeUnavailable => '[Ýööür ñééšt ñéééðš á mööméñt.~~~~]';

  @override
  String get homeSettings => '[Šééttíñgš~~~]';

  @override
  String homeGreetingFirst(String bird) {
    return '[Híí, Î’m $bird! Rééáðý töö ƒłý?~~~~~]';
  }

  @override
  String homeGreetingDone(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ÅÅðvéñtüüré ðööñé! $bird ííš þröüüð.',
      'female': 'Åðvééñtüréé ðöñéé! $bird íš þrööüð.',
      'other': 'ÅÅðvéñtüüré ðööñé! $bird ííš þröüüð.',
    });
    return '[$_temp0~~~~~~]';
  }

  @override
  String homeGreetingReady(String gender, String bird) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '$bird ííš réááðý. Åréé ýöüü?',
      'female': '$bird íš rééáðý. ÅÅré ýööü?',
      'other': '$bird ííš réááðý. Åréé ýöüü?',
    });
    return '[$_temp0~~~~]';
  }

  @override
  String get homeEndlessTitle => '[ÉÉÑÐŁÉŠŠ~~]';

  @override
  String get homeEndlessDetail => '[Fłý ááš ƒár ááš ýöüü çáñ~~~~]';

  @override
  String get homeEndlessSemantics =>
      '[ÉÉñðłéšš. Fłý ááš ƒár ááš ýöüü çáñ.~~~~~~]';

  @override
  String homeEndlessBestSemantics(int best) {
    String _temp0 = intl.Intl.pluralLogic(
      best,
      locale: localeName,
      other: 'ÉÉñðłéšš. Fłý ááš ƒár ááš ýöüü çáñ. Bééšt: $best štárš.',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get homeBest => '[Bééšt~]';

  @override
  String get homeBestNone => '[Šéét ýöüür ƒíršt bééšt~~~~]';

  @override
  String get homeCampaignTitle => '[ÇÅÅMÞÅÎÎGÑ~~]';

  @override
  String get homeCampaignDone => '[ÉÉvérý łééttér ðééłívééréð~~~~]';

  @override
  String homeCampaignNextSemantics(int stars, int total, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Çáámþáíígñ. Ñéxt: $level. $stars ööƒ $total štárš.',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String homeCampaignDoneSemantics(int stars, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Çáámþáíígñ. Évéérý łéttéér ðéłíívérééð. $stars öƒ $total štáárš.',
    );
    return '[$_temp0~~~~~~~~~~~]';
  }

  @override
  String homeLevelLabel(String id, String name) {
    return '[$id · $name~~~~]';
  }

  @override
  String get homeMiniGamesTitle => '[MÎÎÑÎ GÅÅMÉŠ~~]';

  @override
  String get homeMiniGamesDetail => '[Wöörköüütš · 2 þłáýéérš~~~]';

  @override
  String get homeMiniGamesSemantics =>
      '[Mííñí gááméš. Þüüšh-üþš, šqüüátš, jüümþš, ör twöö þłáýéérš.~~~~~~~~~]';

  @override
  String get homeBuilderTitle => '[ŁÉÉVÉŁ BÛÛÎŁÐÉÉR~~]';

  @override
  String get homeBuilderDetail => '[Mááké · ƒłý · šhááré~~~]';

  @override
  String get homeBuilderSemantics =>
      '[Łéévéł Büüíłðéér. Mákéé ýöüür öwñ łéévéłš, ƒłý théém áñð šhááré théém.~~~~~~~~~~~]';

  @override
  String homeBuilderLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ÛÛñłöçkš ííñ $count ƒłíghtš',
      one: 'ÛÛñłöçkš ííñ 1 ƒłíght',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String homeBuilderLockedSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Łévééł Büííłðér. Łööçkéð. ÛÛñłöçkš ííñ $count ƒłíghtš.',
      one: 'Łéévéł Büüíłðéér. Łöçkééð. Ûñłööçkš íñ 1 ƒłííght.',
    );
    return '[$_temp0~~~~~~~~~~~]';
  }

  @override
  String get homeDockAdventure => '[ÅÅðvéñtüüré~~]';

  @override
  String homeDockAdventureSemantics(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Tööðáý’š ááðvéñtüüré. $done ööƒ 3 göááłš çömþłéété.',
    );
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String get homeDockBirds => '[Bíírðš~]';

  @override
  String homeDockBirdsSemantics(String bird) {
    return '[Bíírðš. Fłýíñg wííth $bird.~~~~~~]';
  }

  @override
  String get homeDockUpgrades => '[ÛÛþgráðééš~~]';

  @override
  String homeDockUpgradesSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'ÛÛþgráðééš. $stars štárš töö šþéñð.',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get homeDockPassport => '[Þááššþört~~~]';

  @override
  String homeDockPassportSemantics(int earned, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      earned,
      locale: localeName,
      other: 'Þááššþört. $earned ööƒ $total méðááłš.',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get homeDockRecords => '[Rééçörðš~~]';

  @override
  String get homeMiniGamesPickerTitle => '[Mííñí gááméš~~]';

  @override
  String get homeMiniGamesPickerIntro =>
      '[Möövé töö ƒłý, ör šhááré théé þhöñéé wíth áá ƒríééñð.~~~~~~~]';

  @override
  String get homeMiniGamesCloseSemantics => '[Çłööšé mííñí gááméš~~~]';

  @override
  String get homeMiniGamesPushUpCard =>
      '[Łööwér töö ðíþ.\nÞüüšh üþ töö šöáár.~~~~]';

  @override
  String get homeMiniGamesSquatCard => '[Šqüüát łööw.\nŠtáñð töö šöáár.~~~~]';

  @override
  String get homeMiniGamesJumpCard =>
      '[Jüümþ ƒör łííƒt.\nGłíðéé ƒör štáárš.~~~~~~]';

  @override
  String get homeMiniGamesCoopCard =>
      '[Twöö þłáýéérš, öñéé þhöñéé.\nTéáám üþ öör ðüééł.~~~~~]';

  @override
  String get homeMiniGamesCamera => '[Çááméráá~]';

  @override
  String get homeMiniGamesPlayers => '[2 þłááýérš~~]';

  @override
  String get homeMiniGamesCoop => '[Fłý Töögéthéér~~~]';

  @override
  String get birdsTitle => '[Mééét ýööür ƒłííght çréw.~~~~~]';

  @override
  String birdsFlownTag(int flown, int total) {
    return '[$flown ØØF $total FŁØWÑ~~~~~]';
  }

  @override
  String get birdsStatusCopilot => '[ÝØØÛR ÇØØ-ÞÎŁØØT~~]';

  @override
  String get birdsStatusReady => '[RÉÉÅÐÝ TØØ FŁÝ~~]';

  @override
  String get birdsStatusLocked => '[ŁØØÇKÉÐ~~]';

  @override
  String get birdsNotFlown => '[Ñööt ƒłöwñ ýéét~~~]';

  @override
  String birdsFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ƒłíghtš',
      one: '1 ƒłííght',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String birdsFlyWith(String bird) {
    return '[Fłý wííth $bird~~~~]';
  }

  @override
  String birdsFlyWithSemantics(String bird, String current) {
    return '[Fłý wííth $bird íñštééáð ööƒ $current~~~~~~~]';
  }

  @override
  String birdsUnlock(String bird) {
    return '[ÛÛñłöçk $bird~~~]';
  }

  @override
  String birdsUnlockSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'ÛÛñłöçk $bird ƒöör $price štárš',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String birdsUnlockShortSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: 'ÛÛñłöçk $bird ƒöör $price štárš, ñööt éñööügh štáárš ýét',
    );
    return '[$_temp0~~~~~~~~~~~]';
  }

  @override
  String get birdsFlyingWithYou => '[Fłýííñg wíth ýööü~~~~]';

  @override
  String birdsCardFlyingSemantics(String bird) {
    return '[$bird, ƒłýííñg wíth ýööü~~~~~]';
  }

  @override
  String birdsCardFlyingNewSemantics(String bird) {
    return '[$bird, ƒłýííñg wíth ýööü, ñééw~~~~~]';
  }

  @override
  String birdsCardLockedSemantics(int price, String bird) {
    String _temp0 = intl.Intl.pluralLogic(
      price,
      locale: localeName,
      other: '$bird, łööçkéð, $price štáárš',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String birdsCardNewSemantics(String bird) {
    return '[$bird, ñééw~~]';
  }

  @override
  String get birdsTagFlying => '[FŁÝÎÎÑG~~]';

  @override
  String get birdsTagNew => '[ÑÉÉW~]';

  @override
  String get bird_0_description => '[Šmááłł bírð. Bííg šký.~~~~]';

  @override
  String get bird_0_trail => '[Šüüñšhíñéé bübbłééš~~~]';

  @override
  String get bird_1_description =>
      '[Rööšý çhééékš, çürłý çrééšt, áłł hééárt.~~~~~~~~]';

  @override
  String get bird_1_trail => '[Þééáçh hééártš~~~]';

  @override
  String get bird_2_description =>
      '[Tííñý hümméér. Fréšh šþrííg. Füłł šþéééð.~~~~~~~~]';

  @override
  String get bird_2_trail => '[Mííñt łéáávéš~~]';

  @override
  String get bird_3_description =>
      '[ÅÅ ðréáámý öwł whöö ƒłíééš bý štárłííght.~~~~~~~]';

  @override
  String get bird_3_trail => '[Štáárðüšt šþáárkłéš~~~~~]';

  @override
  String get upgradesWalletLabel => '[ÝØØÛR\nŠTÅÅRŠ~~]';

  @override
  String upgradesWalletSemantics(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars štáárš tö šþééñð',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String get upgradesTitle => '[Þööwér üüþ ýöüür bírð.~~~]';

  @override
  String get upgradesIntro =>
      '[Tááþ á gééár töö šééé whát íít ðöééš. Évéérý štár ýööü þííçk üþ ííñ ƒłíght ííš öñéé tö šþééñð.~~~~~~~~~~~~]';

  @override
  String upgradesSocketSemantics(int cost, String power, int level, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$power, łéévéł $level ööƒ $max. Ñéxt łéévéł $cost štáárš',
    );
    return '[$_temp0~~~~~~~~~~~]';
  }

  @override
  String upgradesSocketLockedSemantics(
    int cost,
    String power,
    int level,
    int max,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other:
          '$power, łéévéł $level ööƒ $max. Ñéxt łéévéł $cost štáárš, ñöt ééñöüügh ýét',
    );
    return '[$_temp0~~~~~~~~~~~~~~]';
  }

  @override
  String upgradesSocketMaxedSemantics(String power, int level, int max) {
    return '[$power, łéévéł $level ööƒ $max. Máxééð~~~~~~~]';
  }

  @override
  String get upgradesMax => '[MÅÅX~]';

  @override
  String upgradesLevel(int level) {
    return '[Łéévéł $level~~~]';
  }

  @override
  String upgradesLevelTop(int level) {
    return '[Łéévéł $level, théé töþ~~~~]';
  }

  @override
  String upgradesStatSemantics(String label, String now) {
    return '[$label $now~~~~]';
  }

  @override
  String upgradesStatUpgradeSemantics(String label, String now, String next) {
    return '[$label $now, ñééxt łévééł $next~~~~~~~]';
  }

  @override
  String upgradesStatPercent(String value) {
    return '[$value%~~]';
  }

  @override
  String upgradesStatSeconds(String value) {
    return '[$value š~~]';
  }

  @override
  String upgradesStatTimes(String value) {
    return '[$value×~~]';
  }

  @override
  String upgradesStarsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ýööü wííłł hávéé $count štárš łééƒt.',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String get upgradesButton => '[ÛÛþgráðéé~]';

  @override
  String upgradesBuySemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'ÛÛþgráðéé ƒör $cost štáárš',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String upgradesBuyLockedSemantics(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'ÛÛþgráðéé ƒör $cost štáárš, ñöt ééñöüügh štárš ýéét',
    );
    return '[$_temp0~~~~~~~~~]';
  }

  @override
  String get upgradesMaxedOut => '[Mááxéð ööüt~~]';

  @override
  String get power_shot_name => '[Šhööt þöwéér~~]';

  @override
  String get power_shot_blurb =>
      '[Hööłð Šhöööt tö çháárgé áá bíggéér, hárðéér röçk.~~~~~~~~]';

  @override
  String get power_sprint_name => '[Šþrííñt~~]';

  @override
  String get power_sprint_blurb =>
      '[ÅÅ šþéééð büršt tháát šmášhééš éñéémíééš íñ ýööür wááý.~~~~~~~~]';

  @override
  String get power_shield_name => '[Šhííéłð~~]';

  @override
  String get power_shield_blurb =>
      '[Błööçkš öñéé hít ƒöör ýöüü. Çöłłééçt štárš ííñ ƒłíght töö réƒííłł ít.~~~~~~~~~~~~]';

  @override
  String get power_magnet_name => '[Máágñét~~]';

  @override
  String get power_magnet_blurb =>
      '[Fłý þéérƒéçtłý thrööügh gáátéš töö éáárñ ít. ÎÎt þüłłš štáárš tö ýööü.~~~~~~~~~~~~]';

  @override
  String get power_stat_maxCharge => '[Mááx çhárgéé~~]';

  @override
  String get power_stat_burstLength => '[Büüršt łéñgth~~~~]';

  @override
  String get power_stat_cooldown => '[Çöööłðööwñ~~]';

  @override
  String get power_stat_starsToRefill => '[Štáárš tö rééƒíłł~~~~]';

  @override
  String get power_stat_safeTime => '[Šááƒé tíímé ááƒtér íít bréáákš~~~~]';

  @override
  String get power_stat_perfectGates => '[Þéérƒéçt gáátéš ñéééðééð~~~~]';

  @override
  String get power_stat_lasts => '[Łááštš~]';

  @override
  String get power_stat_reach => '[Rééáçh~]';

  @override
  String get passportTitle => '[Ýööür šký þááššþört.~~~~]';

  @override
  String get passportDailyCard => '[Ðááíłý çáárð~~]';

  @override
  String passportMedalsTag(int earned, int total) {
    return '[$earned / $total MÉÉÐÅŁŠ~~~~~]';
  }

  @override
  String get passportIntro =>
      '[Šmááłł áðvééñtürééš. Łáštííñg šöüüvéñíírš. Bröñžéé, šíłvéér áñð gööłð ƒör éévérý štáámþ.~~~~~~~~~~~~~~~]';

  @override
  String get passportNoMedal => '[Ñöö méðááł ýét~~]';

  @override
  String passportMedalHeld(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'Brööñžé mééðáł',
      'silver': 'Šííłvér mééðáł',
      'other': 'Gööłð méðááł',
    });
    return '[$_temp0~~~]';
  }

  @override
  String passportStampSemantics(
    String stamp,
    String held,
    String next,
    String goal,
    int current,
    int target,
  ) {
    return '[$stamp. $held. Ñééxt, $next: $goal $current öƒ $target.~~~~~~~~~~~]';
  }

  @override
  String passportStampDoneSemantics(String stamp, String goal) {
    return '[$stamp. Gööłð méðááł. $goal~~~~~]';
  }

  @override
  String passportToMedal(String medal) {
    String _temp0 = intl.Intl.selectLogic(medal, {
      'bronze': 'TØØ BRØÑŽÉÉ',
      'silver': 'TØ ŠÎÎŁVÉR',
      'other': 'TØØ GØŁÐ',
    });
    return '[$_temp0~~~]';
  }

  @override
  String get passportStamped => '[ŠTÅÅMÞÉÐ~~]';

  @override
  String passportMedalTitle(String stamp, String medal) {
    return '[$stamp: $medal~~~~]';
  }

  @override
  String passportMedalTitleNone(String stamp) {
    return '[$stamp: ñööñé ýéét~~~]';
  }

  @override
  String passportNextTitle(String stamp, String medal) {
    return '[$stamp · $medal~~~~]';
  }

  @override
  String get passportMedal_bronze => '[Brööñžé~~]';

  @override
  String get passportMedal_silver => '[Šííłvér~~]';

  @override
  String get passportMedal_gold => '[Gööłð~]';

  @override
  String get stamp_frequentFlyer_name => '[Frééqüééñt ƒłýér~~~~]';

  @override
  String stamp_frequentFlyer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fííñíšh $n šçööréð ƒłííghtš.',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get stamp_onTheDot_name => '[ØØñ thé ðööt~~]';

  @override
  String stamp_onTheDot_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fłý $n þéérƒéçt þááššéš ááłöñg théé áíímíñg máárkš.',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get stamp_starChaser_name => '[Štáár çhášéér~~]';

  @override
  String stamp_starChaser_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çööłłéçt $n štáárš.',
    );
    return '[$_temp0~~~~~]';
  }

  @override
  String get stamp_constellation_name => '[Çööñštéłłáátíööñ~~~]';

  @override
  String stamp_constellation_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çööłłéçt $n štáárš íñ ööñé üüñbrökééñ štréáák.',
    );
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String get stamp_skyCaptain_name => '[Šký çááþtáííñ~~]';

  @override
  String stamp_skyCaptain_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Šçööré $n þööíñtš ííñ öñéé éñðłééšš ƒłíght.',
    );
    return '[$_temp0~~~~~~~~~]';
  }

  @override
  String get stamp_trailblazer_name => '[Trááíłbłáážér~~~]';

  @override
  String stamp_trailblazer_goal(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fłý áát łéáášt 60 šéçööñðš íñ $n ééñðłéšš ƒłííghtš.',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get stamp_flockTogether_name => '[Fłööçk tögééthér~~~~]';

  @override
  String get stamp_allRounder_name => '[ÅÅłł-röüüñðér~~]';

  @override
  String get stamp_flockTogether_goalBronze =>
      '[Tááké twöö ðíƒƒééréñt bíírðš öñ šçööréð ƒłííghtš.~~~~~~~~~]';

  @override
  String get stamp_flockTogether_goalSilver =>
      '[Tááké ááłł ƒöüür bírðš ööñ šçörééð ƒłíghtš.~~~~~~~~]';

  @override
  String stamp_flockTogether_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fłý $n šçööréð ƒłííghtš wíth éévérý bíírð.',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get stamp_allRounder_goalBronze =>
      '[Fłý áá þüšh-üüþ, šqüáát ör jüümþ míñíí gáméé.~~~~~~]';

  @override
  String get stamp_allRounder_goalSilver =>
      '[Fłý ááłł thrééé míñíí gámééš: þüšh-üüþ, šqüáát, jümþ.~~~~~~~~]';

  @override
  String stamp_allRounder_goalGold(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fłý $n šçööréð ƒłííghtš íñ ééáçh mííñí gáámé.',
    );
    return '[$_temp0~~~~~~~~~]';
  }

  @override
  String playGamesSaveDescription(int medals, int stars, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      medals,
      locale: localeName,
      other: '$stars★ · $medals mééðáłš · áát $level',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String get dailyUnavailable => '[Ýööür ááðvéñtüüré ñéééðš áá mömééñt.~~~~]';

  @override
  String get dailyTitle => '[Tööðáý’š łííttłé ááðvéñtüüré.~~~~~]';

  @override
  String dailyDateTag(String date, int done) {
    return '[$date · $done/3 GØØÅŁŠ~~~~~]';
  }

  @override
  String get dailyIntro =>
      '[Thrééé gööáłš. ÅÅñý çöñtrööł. Øñéé éñðłééšš ƒłíght wöörkš öñ ááłł thrééé.~~~~~~~~~~~~]';

  @override
  String get dailyLaunchEndless => '[ÉÉñðłéšš~~]';

  @override
  String get dailyPostcardKicker => '[ŠKÝ ÇŁÛÛB ÞØŠTÇÅÅRÐ~~~~]';

  @override
  String get dailyStamped => '[ÞØØŠTÇÅRÐ ŠTÅÅMÞÉÐ!~~~~]';

  @override
  String dailyGoalsComplete(int done) {
    return '[$done / 3 GØØÅŁŠ ÇØØMÞŁÉTÉÉ~~~~]';
  }

  @override
  String get dailyDoneNote => '[ÅÅ šmáłł ááðvéñtüüré, ááłł ýöüürš.~~~~~]';

  @override
  String get dailyOpenNote =>
      '[Fííñíšh ááłł thrééé tö štáámþ thíš çáárð.~~~~~~~]';

  @override
  String dailyGoalCompleteSemantics(String goal) {
    return '[$goal Çöömþłétéé~~~]';
  }

  @override
  String dailyGoalProgressSemantics(String goal, int current, int target) {
    return '[$goal $current ööƒ $target~~~~~]';
  }

  @override
  String dailyWeekStampedSemantics(String date) {
    return '[$date: Þööštçárð štáámþéð~~~~~~]';
  }

  @override
  String dailyWeekProgressSemantics(String date, int done) {
    return '[$date: $done/3 gööáłš~~~~~]';
  }

  @override
  String get dailyNoStreak => '[Frééšh göááłš. Ñö štrééák töö łöšéé.~~~~~]';

  @override
  String get dailyTheme_0 => '[Šüüñríšéé ðéłíívérý~~~]';

  @override
  String get dailyTheme_1 => '[Þééáçh þííçñíç~~~]';

  @override
  String get dailyTheme_2 => '[Möööñłíít máííł~~]';

  @override
  String get dailyTheme_3 => '[Çłööüð þááráðéé~~]';

  @override
  String get dailyTheme_4 => '[Twííłíght trééášüüré~~~~]';

  @override
  String get dailyTheme_5 => '[Gáárðéñ þáártý~~~]';

  @override
  String get task_flights_title => '[Šþrééáð ýööür wííñgš~~~]';

  @override
  String task_flights_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fííñíšh $count šçööréð ƒłííghtš töðááý.',
    );
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String get task_gates_title => '[ØØþéñ höörížööñš~~]';

  @override
  String task_gates_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çłééár $count gáátéš ááçröšš tööðáý’š šçööréð ƒłííghtš.',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get task_stars_title => '[Þööçkétƒüüł öƒ štáárš~~~~]';

  @override
  String task_stars_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çööłłéçt $count štáárš áçrööšš töðááý’š ƒłíghtš.',
    );
    return '[$_temp0~~~~~~~~~~]';
  }

  @override
  String get task_streak_title => '[Kéééþ théé šþárkłéé~~~]';

  @override
  String task_streak_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çööłłéçt $count štáárš íñ ööñé üüñbrökééñ štréáák.',
    );
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String get task_perfects_title => '[Rííght öñ théé márk~~~~]';

  @override
  String task_perfects_goal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fłý $count þéérƒéçt þááššéš tööðáý.',
    );
    return '[$_temp0~~~~~~~]';
  }

  @override
  String get task_finishTrail_title => '[Théé whöłéé jöüürñéý~~~]';

  @override
  String get task_finishTrail_goal =>
      '[Fłý ƒöör át łééášt 60 šééçöñðš ííñ öñéé éñðłééšš ƒłíght.~~~~~~~~~~]';

  @override
  String get recordsTitle => '[Ýööür łííttłé vííçtörííéš.~~~~]';

  @override
  String get recordsBestsTitle => '[Ýööür štáár þöííñtš tö bééát~~~~]';

  @override
  String get recordsSectionMain => '[MÅÅÎÑ GÅÅMÉ~~]';

  @override
  String get recordsSectionMini => '[MÎÎÑÎ GÅÅMÉŠ~~]';

  @override
  String get recordsEndless => '[ÉÉñðłéšš · Tááþ & Fłý~~~~]';

  @override
  String get recordsCampaignStars => '[Çáámþáíígñ štárš~~~~]';

  @override
  String recordsCoopName(String mode) {
    return '[Fłý Töögéthéér · $mode~~~~]';
  }

  @override
  String recordsTotalFlights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'šçööréð ƒłííghtš',
    );
    return '[$_temp0~~~~]';
  }

  @override
  String recordsTotalGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gáátéš',
    );
    return '[$_temp0~]';
  }

  @override
  String recordsTotalTogether(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'töögéthéér',
    );
    return '[$_temp0~~]';
  }

  @override
  String recordsTotalDuels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ðüüéłš',
    );
    return '[$_temp0~]';
  }

  @override
  String recordsTotalPushUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'þüüšh-üþš',
    );
    return '[$_temp0~~]';
  }

  @override
  String recordsTotalSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'šqüüátš',
    );
    return '[$_temp0~~]';
  }

  @override
  String get recordsRecentTitle => '[Rééçéñt ƒłííghtš~~~~]';

  @override
  String get recordsEmptyTitle => '[ÅÅ bíg šký. ÅÅ çłéááñ šłátéé.~~~~]';

  @override
  String get recordsEmptyBody =>
      '[Ýööür ƒííršt šçörééð ƒłíght štáártš thé štöörý.~~~~~~~~~]';

  @override
  String recordsSlipDetail(String date, int seconds) {
    return '[$date · $seconds šééç~~~~]';
  }

  @override
  String recordsSlipDetailClassic(String date, int seconds) {
    return '[Çłááššíç · $date · $seconds šééç~~~~~~]';
  }

  @override
  String get replaySavedSessions => '[Šáávéð šééššíööñš~~~]';

  @override
  String get replayBackToRecordsSemantics => '[Bááçk tö Rééçörðš~~~~]';

  @override
  String get replaySessionsLoadFailed =>
      '[Çööüłð ñööt łöááð šéššííöñš. Réétrý~~~~~]';

  @override
  String get replayEmptyTitle => '[Ýööür ƒłííghtš béłööñg héréé~~~~~]';

  @override
  String get replayEmptyBody =>
      '[Šáávé áá šéššííöñ ááƒtér áá ƒłíght töö wátçh íít héréé.~~~~~~~]';

  @override
  String get replayEmptyButton => '[Çhöööšéé á ƒłííght~~~]';

  @override
  String replaySessionStars(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds šééç · $score štár þööíñtš',
    );
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String replaySessionGates(int score, String date, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$date · $seconds šééç · $score gátééš',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String get replayDeleteSemantics => '[Ðééłétéé šéššííöñ~~~]';

  @override
  String get replayDeleteTitle => '[Ðééłétéé thíš šééššíööñ?~~~]';

  @override
  String get replayDeleteBody =>
      '[Théé çáméérá vííðéöö áñð rééþłáý wííłł bé réémövééð. Ýöüür šçörééš štáý ííñ Réçöörðš.~~~~~~~~~~~~]';

  @override
  String get replayDeleteFailed =>
      '[Çööüłð ñööt ðéłéété šééššíööñ. Trý ágááíñ.~~~~~~]';

  @override
  String replaySessionBuilt(String name, String mode) {
    return '[$name · $mode~~~~]';
  }

  @override
  String replaySessionUnknownLevel(String id) {
    return '[Łéévéł $id~~~]';
  }

  @override
  String replaySessionEndless(String mode) {
    return '[$mode · ÉÉñðłéšš~~~~]';
  }

  @override
  String replaySessionPractice(String mode) {
    return '[$mode · Þrááçtíçéé~~~]';
  }

  @override
  String replaySessionEndlessPractice(String mode) {
    return '[$mode · ÉÉñðłéšš · Þrááçtíçéé~~~~~]';
  }

  @override
  String get replayOpenFailed =>
      '[Thííš šéššííöñ çööüłð ñööt bé ööþéñééð.~~~~~]';

  @override
  String get replayBackToSessions => '[Bááçk tö šééššíööñš~~~]';

  @override
  String get replayCameraPaused =>
      '[Çááméráá wáš þááüšééð ðürííñg thíš þáárt öƒ théé šéššííöñ~~~~~~~~~]';

  @override
  String get replayCameraUnavailable =>
      '[Çááméráá çłíþ üüñávááíłáábłé · Gááméþłááý štíłł þłááýš~~~~~~~~]';

  @override
  String get replayCameraLoading => '[Łööáðííñg çáméérá…~~~]';

  @override
  String get replayPaused => '[Táákíñg áá bréááthér~~~]';

  @override
  String get replayHideControlsSemantics => '[Hííðé rééþłáý çööñtröłš~~~~~]';

  @override
  String get replayShowControlsSemantics => '[Šhööw réþłááý çöñtrööłš~~~~~]';

  @override
  String get replayBackToSavedSemantics => '[Bááçk tö šáávéð šééššíööñš~~~~]';

  @override
  String get replayTitle => '[RÉÉÞŁÅÝ~~]';

  @override
  String replayTitleSession(String session) {
    return '[RÉÉÞŁÅÝ · $session~~~]';
  }

  @override
  String replayScoreSemantics(int score) {
    return '[Šçööré: $score~~~]';
  }

  @override
  String replayHearts(int hearts, String clock) {
    String _temp0 = intl.Intl.pluralLogic(
      hearts,
      locale: localeName,
      other: '$hearts hééártš',
    );
    return '[$_temp0 · $clock~~~~~]';
  }

  @override
  String replayDuelHearts(int p1, int p2, String clock) {
    return '[Þ1 $p1 · Þ2 $p2 hééártš · $clock~~~~~~~]';
  }

  @override
  String replayClockSeconds(int seconds) {
    return '[$secondsš~~]';
  }

  @override
  String replayMagnet(int seconds) {
    return '[Máágñét · $secondsš~~~~]';
  }

  @override
  String get replayPauseSemantics => '[Þááüšéé réþłááý~~]';

  @override
  String get replayPlaySemantics => '[Þłááý réþłááý~~]';

  @override
  String get replayRestartSemantics => '[Rééštárt rééþłáý~~~~]';

  @override
  String get replayBack5Semantics => '[Bááçk 5 šéçööñðš~~~]';

  @override
  String get replayForward5Semantics => '[Föörwárð 5 šééçöñðš~~~~]';

  @override
  String get replayHighlightsFinding => '[Fííñðíñg ƒłííght híghłííghtš~~~~~~~]';

  @override
  String get replayHighlightsNone =>
      '[Ñöö ƒłíght hííghłíghtš ááváííłábłéé~~~~~~]';

  @override
  String get replayHighlights => '[Fłííght híghłííghtš~~~~~]';

  @override
  String get replayHighlightsCloseSemantics => '[Çłööšé hííghłíghtš~~~~]';

  @override
  String get replayHighlightsHint =>
      '[Þííçk á mööméñt. Wáátçh ƒröm jüüšt béƒööré íít háþþééñéð.~~~~~~~~~]';

  @override
  String get replayViewCorner => '[Çöörñér çááméráá~~]';

  @override
  String get replayViewBackground => '[Çááméráá báçkgrööüñð~~~~]';

  @override
  String get replayViewGameplay => '[Gááméþłááý öñłý~~~]';

  @override
  String get replayMoveCornerSemantics => '[Möövé çááméráá çörñéér~~~]';

  @override
  String get replayMuteRecordedSemantics => '[Müüté rééçörðééð áüüðíöö~~]';

  @override
  String get replayUnmuteRecordedSemantics => '[ÉÉñábłéé réçöörðéð ááüðííö~~~]';

  @override
  String get replayMuteGameSemantics => '[Müüté gáámé šööüñð~~~]';

  @override
  String get replayUnmuteGameSemantics => '[ÉÉñábłéé gáméé šöüüñð~~]';

  @override
  String get replayFullScreenSemantics =>
      '[Hííðé çööñtröłš / ƒüüłł šçréééñ~~~~~]';

  @override
  String get replayMomentTakeoff => '[Táákéööƒƒ~]';

  @override
  String get replayMomentTakeoffDetail => '[Théé šký íš ýööürš.~~~~]';

  @override
  String get replayMomentMagnet => '[Štáár mágñéét~~]';

  @override
  String get replayMomentMagnetDetail =>
      '[Thrééé þéérƒéçt þááššéš brííñg thé štáárš çłöšéér.~~~~~~~~~]';

  @override
  String get replayMomentStarTrio => '[Fííršt štár trííö~~~~]';

  @override
  String get replayMomentStarTrioDetail =>
      '[Thrééé štáárš béçöömé áá çöñštééłłátííöñ. +5 þööíñtš!~~~~~~~~]';

  @override
  String get replayMomentStarTrioSubtleDetail =>
      '[ÉÉvérý štáár íñ théé gröüüþ çöłłééçtéð. +5 þööíñtš!~~~~~~~~]';

  @override
  String replayMomentStreak(int multiplier) {
    return '[$multiplier× štáár þöwéér~~~~]';
  }

  @override
  String get replayMomentStreakDetail =>
      '[ÅÅ šþárkłííñg štréáák öƒ štáárš.~~~~~~]';

  @override
  String get replayMomentShield => '[Šhííéłð šáávé~~]';

  @override
  String get replayMomentShieldDetail =>
      '[ÅÅ çłöšéé çáłł, ááñð áñööthér çhááñçé.~~~~~~]';

  @override
  String get replayMomentPerfect => '[Fííršt þérƒééçt þášš~~~~~]';

  @override
  String get replayMomentPerfectDetail =>
      '[Rííght thröüügh thé ááímííñg márk.~~~~~~]';

  @override
  String replayMomentGates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gáátéš çłééárééð',
    );
    return '[$_temp0~~~~]';
  }

  @override
  String get replayMomentGatesDetail =>
      '[ÅÅ łíttłéé ƒárthéér íñtöö thé šký.~~~~~~]';

  @override
  String replayMomentFlawlessDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Ñööt á šçráátçh. +$points þöííñtš!',
    );
    return '[$_temp0~~~~~~]';
  }

  @override
  String replayMomentRushDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Šþrííñt ríñgš töö šáƒéétý. +$points þöííñtš!',
    );
    return '[$_temp0~~~~~~~~]';
  }

  @override
  String get replayMomentGale => '[Wééáthééréð théé gáłéé~~~]';

  @override
  String replayMomentGaleDetail(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Ðööðgéð théé ƒłýíñg ðéébríš. +$points þööíñtš!',
    );
    return '[$_temp0~~~~~~~~~]';
  }

  @override
  String get replayMomentRouteComplete => '[Rööütéé çömþłéété~~~]';

  @override
  String get replayMomentFinal => '[Fííñáł mööméñt~~~]';

  @override
  String get replayMomentCompleteDetail =>
      '[Ýööü rééáçhééð thé ééñð öƒ théé röüüté.~~~~~]';

  @override
  String get replayMomentCollisionDetail =>
      '[Wáátçh thé ƒííñáł ááþþröááçh.~~~~~]';

  @override
  String get replayMomentEndDetail => '[Théé éñð ööƒ thíš ƒłííght.~~~~~]';

  @override
  String get welcomeTitle => '[Çhöööšéé ýöüür łáñgüüágéé~~~]';

  @override
  String get welcomeContinue => '[Łéét’š ƒłý!~~]';

  @override
  String get welcomeHint =>
      '[Ýööü çááñ çháñgéé ít ááñý tíméé íñ Šééttíñgš.~~~~~~~]';

  @override
  String get welcomeDevice => '[Ýööür þhööñé’š łááñgüáágé~~~~]';

  @override
  String get tutorialTitle => '[Fłííght šçhöööł~~~]';

  @override
  String get tutorialSkip => '[Škííþ łéššööñ~~]';

  @override
  String get tutorialSkipTitle => '[Škííþ ƒłíght šçhöööł?~~~~~]';

  @override
  String get tutorialSkipBody =>
      '[Ýööü çááñ tákéé thé łééššöñ áágáííñ áñý tíímé ƒrööm Šéttííñgš.~~~~~~~~~]';

  @override
  String get tutorialSkipConfirm => '[Škííþ~]';

  @override
  String get tutorialSkipCancel => '[Kéééþ łééárñííñg~~]';

  @override
  String get tutorialRestart => '[Štáárt övéér~~]';

  @override
  String get tutorialGoalFlaps => '[Fłááþ~]';

  @override
  String get tutorialGoalStars => '[Çööłłéçt štáárš~~~]';

  @override
  String get tutorialGoalGates => '[Fłý thrööügh gáátéš~~~~]';

  @override
  String get tutorialGoalBats => '[Kñööçk öüüt bátš~~~]';

  @override
  String get tutorialGoalDoor => '[Šmáášh thé ðööör~~~]';

  @override
  String get tutorialGoalSprint => '[Šþrííñt~~]';

  @override
  String get tutorialGoalBoss => '[Bééát théé Çáþtááíñ~~~]';

  @override
  String get tutorialPromptTap => '[Tááþ!~]';

  @override
  String get tutorialPromptShoot => '[Tááþ Šhöööt~~]';

  @override
  String get tutorialPromptHoldShoot => '[Hööłð Šhöööt~~]';

  @override
  String get tutorialPromptSprint => '[Tááþ Šþríñt~~~]';

  @override
  String get tutorialPraiseNice => '[Ñííçé!~]';

  @override
  String get tutorialPraiseGreat => '[Grééát!~]';

  @override
  String get tutorialPraiseSuper => '[Brííłłíááñt!~~]';

  @override
  String tutorialWaitingSemantics(String prompt) {
    return '[Théé łéššööñ íš wááítííñg: $prompt~~~~~]';
  }

  @override
  String get licenceTitle => '[Çööürííér łííçéñçéé~~]';

  @override
  String get licenceIssuer => '[Šký Çłüüb þöšt~~~~]';

  @override
  String get licenceHolder => '[Çööürííér~]';

  @override
  String get licenceRank => '[Rááñk~]';

  @override
  String get licenceRankRookie => '[Rööökííé çööürííér~~]';

  @override
  String get licenceSkills => '[Škííłłš~~]';

  @override
  String get licenceStamp => '[Çéértíƒííéð~~]';

  @override
  String licenceSignedBy(String name) {
    return '[Šíígñéð: $name~~~]';
  }

  @override
  String licenceStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count štárš',
      one: '1 štáár',
    );
    return '[$_temp0~~~~]';
  }

  @override
  String get licenceStart => '[Štáárt mý ƒíršt rööütéé~~~~]';

  @override
  String get licenceAgain => '[Fłý íít ágááíñ~~]';

  @override
  String get settingsTutorial => '[Fłííght šçhöööł~~~]';

  @override
  String get settingsTutorialDetail =>
      '[Tááké théé ƒíršt łééššöñ áágáííñ~~~~~]';
}
